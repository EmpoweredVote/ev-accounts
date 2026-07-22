import { describe, it, expect, vi, beforeEach } from 'vitest';

// Stub the env vars src/lib/env.ts requires at module-load time (it calls
// process.exit(1) on missing/invalid vars). Real values are never needed —
// pg is mocked below, so no actual connection is ever attempted.
process.env.SUPABASE_URL ??= 'https://example.supabase.co';
process.env.SUPABASE_ANON_KEY ??= 'test-anon-key';
process.env.SUPABASE_SERVICE_ROLE_KEY ??= 'test-service-role-key';
process.env.DATABASE_URL ??= 'postgres://test:test@localhost:5432/test';
process.env.ADMIN_INGEST_TOKEN ??= 'test-admin-ingest-token';

// Mock pg before importing the service so the pool is intercepted (mirrors
// essentialsService-tribal-land.test.ts's pattern).
const mockQuery = vi.fn();
vi.mock('pg', () => {
  class MockPool {
    query = mockQuery;
    end = vi.fn();
    on = vi.fn();
    removeListener = vi.fn();
  }
  return { default: { Pool: MockPool }, Pool: MockPool };
});

describe('buildLocality (Phase 216, LOC-01/02)', () => {
  beforeEach(() => {
    mockQuery.mockReset();
  });

  it('AZ + place hit -> incorporated:true, place_name populated, county_name populated', async () => {
    const { buildLocality } = await import('../src/lib/essentialsService');
    expect(buildLocality('AZ', [{ name: 'Tucson' }], { name: 'Pima County' })).toEqual({
      incorporated: true,
      place_name: 'Tucson',
      county_name: 'Pima County',
    });
  });

  it('AZ + no place hit -> incorporated:false, place_name null, county_name populated', async () => {
    const { buildLocality } = await import('../src/lib/essentialsService');
    expect(buildLocality('AZ', [], { name: 'Pima County' })).toEqual({
      incorporated: false,
      place_name: null,
      county_name: 'Pima County',
    });
  });

  it('MO (not in gate, only 1 incidental place loaded) -> incorporated:null', async () => {
    const { buildLocality } = await import('../src/lib/essentialsService');
    expect(buildLocality('MO', [], { name: 'X County' })).toEqual({
      incorporated: null,
      place_name: null,
      county_name: 'X County',
    });
  });

  it('null state -> incorporated:null, county_name still populated', async () => {
    const { buildLocality } = await import('../src/lib/essentialsService');
    expect(buildLocality(null, [], { name: 'X County' })).toEqual({
      incorporated: null,
      place_name: null,
      county_name: 'X County',
    });
  });

  it('lowercase state matches case-insensitively', async () => {
    const { buildLocality } = await import('../src/lib/essentialsService');
    expect(buildLocality('az', [], { name: 'Pima County' })).toEqual({
      incorporated: false,
      place_name: null,
      county_name: 'Pima County',
    });
  });

  it('AZ + no county row -> county_name null (never throws on a null countyRow)', async () => {
    const { buildLocality } = await import('../src/lib/essentialsService');
    expect(buildLocality('AZ', [], null)).toEqual({
      incorporated: false,
      place_name: null,
      county_name: null,
    });
  });

  it('PLACE_LOADED_STATES contains exactly the 11 expected states and excludes MO', async () => {
    const { PLACE_LOADED_STATES } = await import('../src/lib/essentialsService');
    const expected = ['AZ', 'CA', 'IN', 'ME', 'MD', 'MA', 'NV', 'OR', 'TX', 'UT', 'VA'];
    expect([...PLACE_LOADED_STATES].sort()).toEqual([...expected].sort());
    expect(PLACE_LOADED_STATES.has('MO')).toBe(false);
  });

  it('never returns county_name:null when a non-null countyRow.name is supplied (MO + null-state cases)', async () => {
    const { buildLocality } = await import('../src/lib/essentialsService');
    expect(buildLocality('MO', [], { name: 'X County' }).county_name).toBe('X County');
    expect(buildLocality(null, [], { name: 'X County' }).county_name).toBe('X County');
  });
});
