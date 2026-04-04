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
  resourceId: string | null = null
): UserRoleGrant {
  return {
    id: 'test-grant-id',
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
// checkRole unit tests — all NULL-scope and scope-match combinations
// ---------------------------------------------------------------------------

let checkRole: (
  grants: UserRoleGrant[],
  roleSlug: string | string[],
  scope?: { geoid?: string; resourceId?: string }
) => boolean;

beforeAll(async () => {
  // Dynamic import after env setup to avoid module hoisting issue
  const mod = await import('../../backend/src/lib/roleService.js');
  checkRole = mod.checkRole;
});

describe('checkRole', () => {
  it('returns false when grants array is empty', () => {
    expect(checkRole([], 'volunteer')).toBe(false);
  });

  it('returns false for wrong role slug', () => {
    expect(checkRole([grant('editor')], 'volunteer')).toBe(false);
  });

  it('returns true for matching slug, no scope requirement (scope-blind)', () => {
    expect(checkRole([grant('volunteer')], 'volunteer')).toBe(true);
  });

  it('returns true when NULL-geoid grant checked against specific geoid (NULL = unrestricted)', () => {
    expect(checkRole([grant('volunteer', null)], 'volunteer', { geoid: '18105' })).toBe(true);
  });

  it('returns true for exact geoid match', () => {
    expect(checkRole([grant('volunteer', '18105')], 'volunteer', { geoid: '18105' })).toBe(true);
  });

  it('returns false for wrong jurisdiction', () => {
    expect(checkRole([grant('volunteer', '06037')], 'volunteer', { geoid: '18105' })).toBe(false);
  });

  it('returns true when NULL-resourceId grant checked against specific resourceId (NULL = unrestricted)', () => {
    expect(
      checkRole([grant('campaign_manager', null, null)], 'campaign_manager', { resourceId: 'pol-123' })
    ).toBe(true);
  });

  it('returns false for wrong resourceId', () => {
    expect(
      checkRole([grant('campaign_manager', null, 'pol-456')], 'campaign_manager', { resourceId: 'pol-123' })
    ).toBe(false);
  });

  it('returns true when any grant matches (OR across grants)', () => {
    expect(
      checkRole(
        [grant('editor', '06037'), grant('editor', '18105')],
        'editor',
        { geoid: '18105' }
      )
    ).toBe(true);
  });

  it('supports array of role slugs (OR logic)', () => {
    expect(checkRole([grant('volunteer')], ['editor', 'volunteer'])).toBe(true);
  });

  it('returns false when array of slugs has no match', () => {
    expect(checkRole([grant('admin')], ['editor', 'volunteer'])).toBe(false);
  });

  it('scope-blind check with scoped grant still passes (no scope requirement = any grant passes)', () => {
    // No scope passed — the caller does not require a specific jurisdiction.
    // The grant has a geoid set, but since no scope is required, the grant still matches.
    expect(checkRole([grant('volunteer', '18105')], 'volunteer')).toBe(true);
  });
});
