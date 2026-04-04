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
// getMatchingGrant unit tests
// ---------------------------------------------------------------------------

let getMatchingGrant: (
  grants: UserRoleGrant[],
  politicianId: string,
  politicianGeoid: string | null
) => UserRoleGrant | null;

beforeAll(async () => {
  // Dynamic import after env setup to avoid module hoisting issue
  const mod = await import('../../backend/src/lib/stanceService.js');
  getMatchingGrant = mod.getMatchingGrant;
});

describe('getMatchingGrant', () => {
  // -------------------------------------------------------------------------
  // compass_stance_editor jurisdiction tests
  // -------------------------------------------------------------------------

  it('returns grant when editor jurisdiction matches politician jurisdiction', () => {
    const g = grant('compass_stance_editor', '18105');
    const result = getMatchingGrant([g], 'pol-A', '18105');
    expect(result).not.toBeNull();
    expect(result!.id).toBe('grant-1');
  });

  it('returns null when editor jurisdiction does NOT match politician jurisdiction', () => {
    const g = grant('compass_stance_editor', '18105');
    const result = getMatchingGrant([g], 'pol-A', '06037');
    expect(result).toBeNull();
  });

  it('returns grant (fail-open) when politician has null home_jurisdiction_geoid', () => {
    const g = grant('compass_stance_editor', '18105');
    const result = getMatchingGrant([g], 'pol-A', null);
    expect(result).not.toBeNull();
    expect(result!.id).toBe('grant-1');
  });

  it('returns grant when editor has null jurisdiction (unrestricted)', () => {
    const g = grant('compass_stance_editor', null);
    const result = getMatchingGrant([g], 'pol-A', '06037');
    expect(result).not.toBeNull();
    expect(result!.id).toBe('grant-1');
  });

  it('two-jurisdiction scenario: editor scoped to A writes A (match) then B (reject)', () => {
    const g = grant('compass_stance_editor', '18105');
    // Same grant, same editor — first politician is in matching jurisdiction
    const resultA = getMatchingGrant([g], 'pol-A', '18105');
    expect(resultA).not.toBeNull();
    expect(resultA!.id).toBe('grant-1');
    // Second politician is in a different jurisdiction — must reject
    const resultB = getMatchingGrant([g], 'pol-B', '06037');
    expect(resultB).toBeNull();
  });

  // -------------------------------------------------------------------------
  // campaign_manager resource tests
  // -------------------------------------------------------------------------

  it('returns grant when resource_id matches politicianId', () => {
    const g = grant('campaign_manager', null, 'pol-A', 'cm-grant-1');
    const result = getMatchingGrant([g], 'pol-A', '18105');
    expect(result).not.toBeNull();
    expect(result!.id).toBe('cm-grant-1');
  });

  it('returns null when resource_id does NOT match politicianId', () => {
    const g = grant('campaign_manager', null, 'pol-A');
    const result = getMatchingGrant([g], 'pol-B', '18105');
    expect(result).toBeNull();
  });

  it('campaign_manager ignores jurisdiction — only checks resource_id', () => {
    // Grant has geoid '18105' but politician geoid is '06037' (mismatch)
    // For campaign_manager, only resource_id matters — geoid is irrelevant
    const g = grant('campaign_manager', '18105', 'pol-A', 'cm-grant-2');
    const result = getMatchingGrant([g], 'pol-A', '06037');
    expect(result).not.toBeNull();
    expect(result!.id).toBe('cm-grant-2');
  });

  // -------------------------------------------------------------------------
  // Mixed grant array tests
  // -------------------------------------------------------------------------

  it('finds correct grant from mixed array', () => {
    const cmGrant = grant('campaign_manager', null, 'pol-B', 'cm-grant-3');
    const editorGrant = grant('compass_stance_editor', '18105', null, 'editor-grant-1');
    // politicianId 'pol-X' (not pol-B) with geoid '18105' — should match editor grant
    const result = getMatchingGrant([cmGrant, editorGrant], 'pol-X', '18105');
    expect(result).not.toBeNull();
    expect(result!.id).toBe('editor-grant-1');
  });

  it('returns null when no grants match', () => {
    const cmGrant = grant('campaign_manager', null, 'pol-B', 'cm-grant-4');
    const editorGrant = grant('compass_stance_editor', '06037', null, 'editor-grant-2');
    // politicianId 'pol-X' (not pol-B) with geoid '18105' (not 06037) — no match
    const result = getMatchingGrant([cmGrant, editorGrant], 'pol-X', '18105');
    expect(result).toBeNull();
  });
});
