import { describe, it, expect } from 'vitest';
import {
  GEO_FIELDS,
  PLACE_FIELDS,
  resolvedDistrictCount,
  droppedDistricts,
} from './jurisdictionPayload.js';

// ---------------------------------------------------------------------------
// resolvedDistrictCount
// ---------------------------------------------------------------------------

describe('resolvedDistrictCount — how many districts a payload actually names', () => {
  // 🔴 connect.resolve_user_jurisdiction aggregates with no GROUP BY, so it returns exactly
  // ONE row even when zero boundaries cover the point: every key NULL, and no error. Four
  // call sites read that payload; each needs the same answer to "did this resolve anything".

  it('returns 0 for the all-NULL payload an unresolved point produces', () => {
    const payload = Object.fromEntries(GEO_FIELDS.map((f) => [f.rpcKey, null]));
    expect(resolvedDistrictCount(payload)).toBe(0);
  });

  it('returns 0 for a null payload', () => {
    expect(resolvedDistrictCount(null)).toBe(0);
  });

  it('returns 0 for an empty object', () => {
    expect(resolvedDistrictCount({})).toBe(0);
  });

  it('counts only the five district keys, not the name keys beside them', () => {
    // A payload carrying names but no geo_ids has resolved nothing. Names are labels.
    expect(
      resolvedDistrictCount({
        congressional: null,
        congressional_name: 'Oregon 5th',
        county: null,
        county_name: 'Deschutes',
      })
    ).toBe(0);
  });

  it('counts each resolved district once', () => {
    expect(
      resolvedDistrictCount({ congressional: 'cd-5', county: 'county-1', state_house: null })
    ).toBe(2);
  });

  it('ignores an empty string, which is not a resolved geo_id', () => {
    expect(resolvedDistrictCount({ congressional: '', county: 'county-1' })).toBe(1);
  });
});

// ---------------------------------------------------------------------------
// droppedDistricts
// ---------------------------------------------------------------------------

describe('droppedDistricts — which stored districts a payload would erase', () => {
  const STORED = {
    congressional_geo_id: 'cd-5',
    state_senate_geo_id: 'sen-11',
    state_house_geo_id: null,
    county_geo_id: 'county-1',
    school_district_geo_id: 'school-1',
  };

  it('names a stored district the payload no longer resolves', () => {
    const dropped = droppedDistricts(STORED, {
      congressional: 'cd-5',
      state_senate: 'sen-11',
      county: 'county-1',
      school_district: null,
    });
    expect(dropped).toEqual(['school_district_geo_id']);
  });

  it('does not name a column that was already empty', () => {
    // state_house_geo_id is null in STORED, so a null payload value erases nothing.
    const dropped = droppedDistricts(STORED, {
      congressional: 'cd-5',
      state_senate: 'sen-11',
      county: 'county-1',
      school_district: 'school-1',
    });
    expect(dropped).toEqual([]);
  });

  it('names every stored district when the payload resolves nothing', () => {
    expect(droppedDistricts(STORED, {})).toEqual([
      'congressional_geo_id',
      'state_senate_geo_id',
      'county_geo_id',
      'school_district_geo_id',
    ]);
  });
});

// ---------------------------------------------------------------------------
// PLACE_FIELDS
// ---------------------------------------------------------------------------

describe('PLACE_FIELDS — the place geoids a slice is keyed on', () => {
  it('carries city, state and nation', () => {
    const keys = PLACE_FIELDS.map((c) => c.rpcKey);
    expect(keys).toContain('city');
    expect(keys).toContain('state');
    expect(keys).toContain('nation');
  });

  it('maps each key to its own column', () => {
    const byKey = Object.fromEntries(PLACE_FIELDS.map((c) => [c.rpcKey, c.column]));
    expect(byKey['city']).toBe('city_geo_id');
    expect(byKey['state']).toBe('state_geo_id');
    expect(byKey['nation']).toBe('nation_geo_id');
  });

  it('is disjoint from GEO_FIELDS', () => {
    // 🔴 The whole point of the split. resolvedDistrictCount() counts GEO_FIELDS to
    // answer "did the RPC resolve anything", and that question is really "is the
    // essentials.districts join healthy". city/state/nation are read straight off
    // geofence_boundaries and never touch that join, so they cannot witness its
    // health: a broken join still resolves a state and a nation, and a count of 2
    // would read as success and let districtStalenessService write NULLs over
    // districts that are still correct. That is the defect that already shipped.
    const geo = new Set<string>(GEO_FIELDS.map((f) => f.rpcKey));
    for (const f of PLACE_FIELDS) {
      expect(geo.has(f.rpcKey)).toBe(false);
    }
  });

  it('leaves resolvedDistrictCount at zero for a payload that resolved only place', () => {
    // The exact shape of a broken districts join: every district null, but the
    // point is still in a state and in the US.
    expect(resolvedDistrictCount({ city: '3702140', state: '37', nation: 'US' })).toBe(0);
  });

  it('leaves droppedDistricts blind to place columns', () => {
    const stored = { congressional_geo_id: 'cd-5' } as Record<string, string | null>;
    expect(droppedDistricts(stored, { congressional: 'cd-5', city: null })).toEqual([]);
  });
});
