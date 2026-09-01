import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

const poolQueryMock = vi.hoisted(() => vi.fn());
vi.mock('./db.js', () => ({ pool: { query: poolQueryMock } }));

const adminRpcMock = vi.hoisted(() => vi.fn());
vi.mock('./supabase.js', () => ({ adminRpc: adminRpcMock }));

import { runDistrictStalenessCheck } from './districtStalenessService.js';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/** A profile carrying all five district assignments — the shape the job must protect. */
const SEATED_PROFILE = {
  user_id: 'user-1',
  congressional_geo_id: 'ocd-division/country:us/state:or/cd:5',
  state_senate_geo_id: 'geo-senate-11',
  state_house_geo_id: 'geo-house-22',
  county_geo_id: 'geo-county-deschutes',
  school_district_geo_id: 'geo-school-bend',
};

/** What resolve_user_jurisdiction returns when no boundary covers the point. */
const RESOLVED_NOTHING = {
  congressional: null,
  congressional_name: null,
  state_senate: null,
  state_senate_name: null,
  state_house: null,
  state_house_name: null,
  county: null,
  county_name: null,
  school_district: null,
  school_district_name: null,
};

/** Pull every UPDATE statement the job issued. */
function updateStatements(): string[] {
  return poolQueryMock.mock.calls
    .map((c) => (typeof c[0] === 'string' ? c[0] : ''))
    .filter((sql) => sql.includes('UPDATE connect.connected_profiles'));
}

beforeEach(() => {
  poolQueryMock.mockReset();
  adminRpcMock.mockReset();
  // The job's first query is the profile SELECT; every later call is an UPDATE.
  poolQueryMock.mockResolvedValue({ rows: [], rowCount: 0 });
});

/** Arrange: one profile in scope, and one RPC payload for it. */
function withProfile(profile: Record<string, unknown>, rpcPayload: unknown) {
  poolQueryMock.mockResolvedValueOnce({ rows: [profile], rowCount: 1 });
  adminRpcMock.mockResolvedValueOnce({ data: rpcPayload, error: null });
}

// ---------------------------------------------------------------------------
// The guard
// ---------------------------------------------------------------------------

describe('district staleness — an unresolved point must not erase stored districts', () => {
  // 🔴 resolve_user_jurisdiction aggregates with no GROUP BY, so it returns exactly ONE
  // row even when zero boundaries cover the point — an all-NULL payload and NO error.
  // Treating that as "the districts changed" wrote NULL over all five geo_ids and names,
  // then stamped districts_last_verified_at so the wiped row looked freshly verified.

  it('issues no UPDATE when the RPC resolves no districts at all', async () => {
    withProfile(SEATED_PROFILE, RESOLVED_NOTHING);

    await runDistrictStalenessCheck();

    expect(updateStatements()).toEqual([]);
  });

  it('does not stamp districts_last_verified_at for an unresolved point', async () => {
    withProfile(SEATED_PROFILE, RESOLVED_NOTHING);

    await runDistrictStalenessCheck();

    const stamped = updateStatements().some((sql) =>
      sql.includes('districts_last_verified_at')
    );
    expect(stamped).toBe(false);
  });

  it('treats a null RPC payload the same as an all-NULL one', async () => {
    // adminRpc can hand back data: null with no error. `?? {}` made this read as
    // "every district is now NULL".
    withProfile(SEATED_PROFILE, null);

    await runDistrictStalenessCheck();

    expect(updateStatements()).toEqual([]);
  });

  it('counts an unresolved profile as unresolved, not as unchanged or updated', async () => {
    withProfile(SEATED_PROFILE, RESOLVED_NOTHING);

    const result = await runDistrictStalenessCheck();

    expect(result).toMatchObject({
      total: 1,
      unresolved: 1,
      updated: 0,
      unchanged: 0,
      failed: 0,
    });
  });
});

// ---------------------------------------------------------------------------
// Positive control — the guard must not break the job it protects
// ---------------------------------------------------------------------------

describe('district staleness — a resolved point still updates', () => {
  it('writes the new geo_ids when the RPC resolves a changed district', async () => {
    withProfile(SEATED_PROFILE, {
      ...RESOLVED_NOTHING,
      congressional: 'ocd-division/country:us/state:or/cd:2',
      congressional_name: 'Oregon 2nd',
      state_senate: SEATED_PROFILE.state_senate_geo_id,
      state_house: SEATED_PROFILE.state_house_geo_id,
      county: SEATED_PROFILE.county_geo_id,
      school_district: SEATED_PROFILE.school_district_geo_id,
    });

    const result = await runDistrictStalenessCheck();

    expect(updateStatements()).toHaveLength(1);
    expect(updateStatements()[0]).toContain('congressional_geo_id');
    expect(result).toMatchObject({ updated: 1, unresolved: 0 });
  });

  it('stamps the verified timestamp when nothing changed', async () => {
    withProfile(SEATED_PROFILE, {
      ...RESOLVED_NOTHING,
      congressional: SEATED_PROFILE.congressional_geo_id,
      state_senate: SEATED_PROFILE.state_senate_geo_id,
      state_house: SEATED_PROFILE.state_house_geo_id,
      county: SEATED_PROFILE.county_geo_id,
      school_district: SEATED_PROFILE.school_district_geo_id,
    });

    const result = await runDistrictStalenessCheck();

    expect(updateStatements()).toHaveLength(1);
    expect(updateStatements()[0]).toContain('districts_last_verified_at');
    expect(result).toMatchObject({ unchanged: 1, unresolved: 0 });
  });

  it('writes a place geoid that moved while every district stayed put', async () => {
    // Annexation moves a point inside city limits without touching a district line.
    // The five district comparisons cannot see that, so place needs its own.
    withProfile(
      { ...SEATED_PROFILE, city_geo_id: null, state_geo_id: '41', nation_geo_id: 'US' },
      {
        ...RESOLVED_NOTHING,
        congressional: SEATED_PROFILE.congressional_geo_id,
        state_senate: SEATED_PROFILE.state_senate_geo_id,
        state_house: SEATED_PROFILE.state_house_geo_id,
        county: SEATED_PROFILE.county_geo_id,
        school_district: SEATED_PROFILE.school_district_geo_id,
        city: '4105800',
        state: '41',
        nation: 'US',
      }
    );

    const result = await runDistrictStalenessCheck();

    expect(updateStatements()[0]).toContain('city_geo_id');
    expect(result).toMatchObject({ updated: 1, unchanged: 0, unresolved: 0 });
  });

  it('still resolves a profile that legitimately holds no districts', async () => {
    // Nothing stored and nothing resolved: there is nothing to protect, but the point
    // is genuinely unresolved, so it must be reported as such rather than as verified.
    withProfile(
      {
        user_id: 'user-2',
        congressional_geo_id: null,
        state_senate_geo_id: null,
        state_house_geo_id: null,
        county_geo_id: null,
        school_district_geo_id: null,
      },
      RESOLVED_NOTHING
    );

    const result = await runDistrictStalenessCheck();

    expect(updateStatements()).toEqual([]);
    expect(result).toMatchObject({ unresolved: 1, unchanged: 0 });
  });
});

// ---------------------------------------------------------------------------
// A partial drop is real signal, not a wipe — it must be written AND visible
// ---------------------------------------------------------------------------

describe('district staleness — a partial drop is written but reported', () => {
  it('writes a genuine single-district removal and names the dropped field', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {});
    withProfile(SEATED_PROFILE, {
      ...RESOLVED_NOTHING,
      congressional: SEATED_PROFILE.congressional_geo_id,
      state_senate: SEATED_PROFILE.state_senate_geo_id,
      state_house: SEATED_PROFILE.state_house_geo_id,
      county: SEATED_PROFILE.county_geo_id,
      school_district: null, // the one real removal
    });

    const result = await runDistrictStalenessCheck();

    expect(updateStatements()).toHaveLength(1);
    expect(result).toMatchObject({ updated: 1, unresolved: 0 });
    expect(warn.mock.calls.flat().join(' ')).toContain('school_district');
    warn.mockRestore();
  });
});

// ---------------------------------------------------------------------------
// An RPC error is still a failure, not an unresolved point
// ---------------------------------------------------------------------------

describe('district staleness — an RPC error stays a failure', () => {
  it('counts an RPC error as failed and writes nothing', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    poolQueryMock.mockResolvedValueOnce({ rows: [SEATED_PROFILE], rowCount: 1 });
    adminRpcMock.mockResolvedValueOnce({
      data: null,
      error: { message: 'no location on file for user user-1' },
    });

    const result = await runDistrictStalenessCheck();

    expect(updateStatements()).toEqual([]);
    expect(result).toMatchObject({ failed: 1, unresolved: 0 });
  });
});
