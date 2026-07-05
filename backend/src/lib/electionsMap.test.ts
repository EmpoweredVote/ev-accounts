import { describe, it, expect } from 'vitest';
import {
  raceCoverage,
  resolveRaceCountyFips,
  classifyCounty,
  classifyRaces,
  classifyRaceTier,
  weightedDepthScore,
  toSlug,
  PLACE_STRIP,
  type RaceRow,
} from './electionsMap.js';

const race = (over: Partial<RaceRow> = {}): RaceRow => ({
  race_id: 'r', position_name: 'X', seats: 1, candidate_count: 0, ocd_id: null,
  active_count: 0, stanced_count: 0, motivated_count: 0, ...over,
});

describe('raceCoverage', () => {
  it('is covered ÷ total, rounded to 1 decimal, 0..100', () => {
    expect(raceCoverage([race({ candidate_count: 1 }), race({ candidate_count: 0 })])).toBe(50);
    expect(raceCoverage([race({ candidate_count: 2 }), race({ candidate_count: 3 })])).toBe(100);
    expect(raceCoverage([race(), race()])).toBe(0);
  });
  it('returns 0 for an empty set', () => {
    expect(raceCoverage([])).toBe(0);
  });
});

describe('resolveRaceCountyFips', () => {
  const countyOcdToFips = new Map([['ocd-division/country:us/state:ut/county:salt_lake', '49035']]);
  const placeSlugToFips = new Map([['provo', '49049']]);
  it('resolves a county-level race directly', () => {
    expect(resolveRaceCountyFips('ocd-division/country:us/state:ut/county:salt_lake', countyOcdToFips, placeSlugToFips)).toBe('49035');
  });
  it('resolves a place-level race via its slug', () => {
    expect(resolveRaceCountyFips('ocd-division/country:us/state:ut/place:provo', countyOcdToFips, placeSlugToFips)).toBe('49049');
  });
  it('resolves nested sub-district races to their parent county/place', () => {
    expect(resolveRaceCountyFips('ocd-division/country:us/state:ut/county:salt_lake/council_district:5', countyOcdToFips, placeSlugToFips)).toBe('49035');
    expect(resolveRaceCountyFips('ocd-division/country:us/state:ut/place:provo/ward:3', countyOcdToFips, placeSlugToFips)).toBe('49049');
  });
  it('returns null for state/federal/legislative races', () => {
    expect(resolveRaceCountyFips('ocd-division/country:us/state:ut', countyOcdToFips, placeSlugToFips)).toBeNull();
    expect(resolveRaceCountyFips('ocd-division/country:us/state:ut/cd:1', countyOcdToFips, placeSlugToFips)).toBeNull();
    expect(resolveRaceCountyFips('ocd-division/country:us/state:ut/sldu:5', countyOcdToFips, placeSlugToFips)).toBeNull();
    expect(resolveRaceCountyFips('ocd-division/country:us/state:ut/sldl:5', countyOcdToFips, placeSlugToFips)).toBeNull();
    expect(resolveRaceCountyFips(null, countyOcdToFips, placeSlugToFips)).toBeNull();
  });
});

describe('toSlug', () => {
  it('strips the place suffix and slugifies', () => {
    expect(toSlug('Salt Lake City', PLACE_STRIP)).toBe('salt_lake');
    expect(toSlug('St. George city', PLACE_STRIP)).toBe('st_george');
  });
});

describe('classifyCounty', () => {
  it('is unknown when no races resolve to the county', () => {
    expect(classifyCounty([]).status).toBe('unknown');
  });
  it('is scored with coverage when races resolve', () => {
    const c = classifyCounty([race({ candidate_count: 1 }), race({ candidate_count: 0 })]);
    expect(c.status).toBe('scored');
    expect(c.coverage).toBe(50);
  });
});

describe('classifyRaces', () => {
  const countyOcdToFips = new Map([['ocd-division/country:us/state:ut/county:salt_lake', '49035']]);
  const placeSlugToFips = new Map([['provo', '49049']]);

  it('returns both buckets empty for an empty race set', () => {
    const { statewide, countyPinnable } = classifyRaces([], countyOcdToFips, placeSlugToFips);
    expect(statewide).toEqual([]);
    expect(countyPinnable).toEqual([]);
  });

  it('puts an all-statewide set (cd/sldu/sldl/bare-state/null) entirely into statewide', () => {
    const races = [
      race({ race_id: 'cd', ocd_id: 'ocd-division/country:us/state:ut/cd:1' }),
      race({ race_id: 'sldu', ocd_id: 'ocd-division/country:us/state:ut/sldu:5' }),
      race({ race_id: 'sldl', ocd_id: 'ocd-division/country:us/state:ut/sldl:5' }),
      race({ race_id: 'bare', ocd_id: 'ocd-division/country:us/state:ut' }),
      race({ race_id: 'nullocd', ocd_id: null }),
    ];
    const { statewide, countyPinnable } = classifyRaces(races, countyOcdToFips, placeSlugToFips);
    expect(statewide).toHaveLength(5);
    expect(countyPinnable).toHaveLength(0);
  });

  it('partitions a mixed set with no overlap and no loss', () => {
    const races = [
      race({ race_id: 'cd', ocd_id: 'ocd-division/country:us/state:ut/cd:1' }),
      race({ race_id: 'county', ocd_id: 'ocd-division/country:us/state:ut/county:salt_lake' }),
      race({ race_id: 'place', ocd_id: 'ocd-division/country:us/state:ut/place:provo' }),
      race({ race_id: 'bare', ocd_id: 'ocd-division/country:us/state:ut' }),
    ];
    const { statewide, countyPinnable } = classifyRaces(races, countyOcdToFips, placeSlugToFips);
    expect(statewide.map((r) => r.race_id).sort()).toEqual(['bare', 'cd']);
    expect(countyPinnable.map((r) => r.race_id).sort()).toEqual(['county', 'place']);
    expect(statewide.length + countyPinnable.length).toBe(races.length);
  });

  it('resolves a place-resolvable race and a nested county sub-district race to countyPinnable', () => {
    const races = [
      race({ race_id: 'place', ocd_id: 'ocd-division/country:us/state:ut/place:provo' }),
      race({ race_id: 'nested-county', ocd_id: 'ocd-division/country:us/state:ut/county:salt_lake/council_district:5' }),
    ];
    const { statewide, countyPinnable } = classifyRaces(races, countyOcdToFips, placeSlugToFips);
    expect(statewide).toHaveLength(0);
    expect(countyPinnable.map((r) => r.race_id).sort()).toEqual(['nested-county', 'place']);
  });

  it('puts cd/sldu/sldl/bare-state races into statewide', () => {
    const races = [
      race({ race_id: 'cd', ocd_id: 'ocd-division/country:us/state:ut/cd:1' }),
      race({ race_id: 'sldu', ocd_id: 'ocd-division/country:us/state:ut/sldu:5' }),
      race({ race_id: 'sldl', ocd_id: 'ocd-division/country:us/state:ut/sldl:5' }),
      race({ race_id: 'bare', ocd_id: 'ocd-division/country:us/state:ut' }),
    ];
    const { statewide, countyPinnable } = classifyRaces(races, countyOcdToFips, placeSlugToFips);
    expect(statewide.map((r) => r.race_id).sort()).toEqual(['bare', 'cd', 'sldl', 'sldu']);
    expect(countyPinnable).toHaveLength(0);
  });
});

describe('classifyRaceTier', () => {
  it('is Tier 0 when there are no active candidates', () => {
    expect(classifyRaceTier({ active: 0, stanced: 0, motivated: 0 })).toBe(0);
  });
  it('is Tier 1 when active but the weakest candidate has neither signal (name-only / null-politician / withdrawn-only capping)', () => {
    expect(classifyRaceTier({ active: 2, stanced: 0, motivated: 0 })).toBe(1);
  });
  it('is Tier 1 when neither signal reaches ALL, even if both are partially present (partial-both case)', () => {
    expect(classifyRaceTier({ active: 3, stanced: 2, motivated: 2 })).toBe(1);
  });
  it('is Tier 2 when stance reaches ALL but motivation does not (stance-only)', () => {
    expect(classifyRaceTier({ active: 3, stanced: 3, motivated: 1 })).toBe(2);
  });
  it('is Tier 2 when motivation reaches ALL but stance does not (motivation-only)', () => {
    expect(classifyRaceTier({ active: 3, stanced: 1, motivated: 3 })).toBe(2);
  });
  it('is Tier 3 when both stance and motivation reach ALL active candidates', () => {
    expect(classifyRaceTier({ active: 3, stanced: 3, motivated: 3 })).toBe(3);
  });
});

describe('weightedDepthScore', () => {
  it('maps a single Tier 0 race to 0', () => {
    expect(weightedDepthScore([0])).toBe(0);
  });
  it('maps a single Tier 1 race to 33.3 (1/3 scaled)', () => {
    expect(weightedDepthScore([1])).toBe(33.3);
  });
  it('maps a single Tier 2 race to 66.7 (2/3 scaled)', () => {
    expect(weightedDepthScore([2])).toBe(66.7);
  });
  it('maps a single Tier 3 race to 100', () => {
    expect(weightedDepthScore([3])).toBe(100);
  });
  it('averages multiple Tier 3 races to 100', () => {
    expect(weightedDepthScore([3, 3])).toBe(100);
  });
  it('averages a Tier 1 and Tier 3 race to 66.7 (avg of 1/3 and 1 = 2/3)', () => {
    expect(weightedDepthScore([1, 3])).toBe(66.7);
  });
  it('averages a full T0/T1/T2/T3 spread to 50', () => {
    expect(weightedDepthScore([0, 1, 2, 3])).toBe(50);
  });
  it('returns 0 for an empty array (N/A is the caller\'s concern per D-05)', () => {
    expect(weightedDepthScore([])).toBe(0);
  });
});
