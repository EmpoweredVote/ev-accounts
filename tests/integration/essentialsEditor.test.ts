// Set up test environment before any imports that read process.env
process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] = 'test-service-role-key';
process.env['DATABASE_URL'] = 'postgresql://postgres:password@localhost:5432/postgres';
process.env['ADMIN_INGEST_TOKEN'] = 'test-ingest-token';

import { describe, it, expect, beforeAll } from 'vitest';
import type { UserRoleGrant } from '../../backend/src/lib/roleService.js';

// ---------------------------------------------------------------------------
// Test helper
// ---------------------------------------------------------------------------

function grant(
  slug: string,
  geoid: string | null = null,
  resourceId: string | null = null,
  id: string = 'grant-1'
): UserRoleGrant {
  return {
    id,
    role_id: 'r1',
    slug,
    name: slug,
    granted_at: '2026-01-01',
    feature_scope: 'platform',
    jurisdiction_geoid: geoid,
    resource_id: resourceId,
  };
}

// ---------------------------------------------------------------------------
// getEditorMatchingGrant unit tests
// ---------------------------------------------------------------------------

let getEditorMatchingGrant: (
  grants: UserRoleGrant[],
  politicianGeoid: string | null
) => UserRoleGrant | null;

beforeAll(async () => {
  // Dynamic import after env setup to avoid module hoisting issue
  const mod = await import('../../backend/src/lib/stanceService.js');
  getEditorMatchingGrant = mod.getEditorMatchingGrant;
});

describe('getEditorMatchingGrant', () => {
  // Test 1: empty grants array
  it('returns null for empty grants array', () => {
    expect(getEditorMatchingGrant([], '06037')).toBeNull();
  });

  // Test 2: wrong slug — compass_stance_editor with matching geoid should not match
  it('returns null when no essentials_data_editor grant exists (wrong slug)', () => {
    const g = grant('compass_stance_editor', '06037');
    expect(getEditorMatchingGrant([g], '06037')).toBeNull();
  });

  // Test 3: exact jurisdiction match returns grant
  it('returns grant when editor jurisdiction matches politician jurisdiction', () => {
    const g = grant('essentials_data_editor', '06037');
    const result = getEditorMatchingGrant([g], '06037');
    expect(result).not.toBeNull();
    expect(result!.id).toBe('grant-1');
  });

  // Test 4: jurisdiction mismatch returns null
  it('returns null when editor jurisdiction does NOT match politician jurisdiction', () => {
    const g = grant('essentials_data_editor', '18105');
    expect(getEditorMatchingGrant([g], '06037')).toBeNull();
  });

  // Test 5: NULL grant jurisdiction = global access
  it('returns grant when grant jurisdiction is null (global access)', () => {
    const g = grant('essentials_data_editor', null);
    const result = getEditorMatchingGrant([g], '06037');
    expect(result).not.toBeNull();
    expect(result!.id).toBe('grant-1');
  });

  // Test 6: NULL politician geoid = fail-CLOSED (security-critical)
  it('returns null when politician geoid is null (fail-closed, unlike compass_stance_editor)', () => {
    const g = grant('essentials_data_editor', '06037');
    // compass_stance_editor fails open here; essentials_data_editor must fail closed
    expect(getEditorMatchingGrant([g], null)).toBeNull();
  });

  // Test 7: NULL grant jurisdiction + NULL politician geoid = global grant matches everything
  it('returns grant when grant jurisdiction is null and politician geoid is null (global access)', () => {
    const g = grant('essentials_data_editor', null);
    const result = getEditorMatchingGrant([g], null);
    expect(result).not.toBeNull();
    expect(result!.id).toBe('grant-1');
  });

  // Test 8: multiple grants — first matching grant wins
  it('multiple grants: first matching grant wins', () => {
    const grants = [
      grant('essentials_data_editor', '18105', null, 'g1'),
      grant('essentials_data_editor', '06037', null, 'g2'),
    ];
    const result = getEditorMatchingGrant(grants, '06037');
    expect(result).not.toBeNull();
    expect(result!.id).toBe('g2');
  });

  // Test 9: skips non-matching slugs, finds matching grant later in array
  it('skips non-essentials_data_editor grants, finds matching grant later', () => {
    const grants = [
      grant('compass_stance_editor', '06037', null, 'g1'),
      grant('essentials_data_editor', '06037', null, 'g2'),
    ];
    const result = getEditorMatchingGrant(grants, '06037');
    expect(result).not.toBeNull();
    expect(result!.id).toBe('g2');
  });

  // Test 10: two-jurisdiction scenario — same grant, different politician geoids
  it('two-jurisdiction scenario: grant scoped to A matches A, rejects B', () => {
    const grants = [grant('essentials_data_editor', '06037', null, 'g1')];
    // Politician in matching jurisdiction
    const resultA = getEditorMatchingGrant(grants, '06037');
    expect(resultA).not.toBeNull();
    expect(resultA!.id).toBe('g1');
    // Politician in different jurisdiction — must reject
    const resultB = getEditorMatchingGrant(grants, '18105');
    expect(resultB).toBeNull();
  });
});
