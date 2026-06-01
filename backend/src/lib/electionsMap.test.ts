import { describe, it, expect } from 'vitest';
import { raceCoverage, resolveRaceCountyFips, classifyCounty, toSlug, PLACE_STRIP, type RaceRow } from './electionsMap.js';

const race = (over: Partial<RaceRow> = {}): RaceRow => ({
  race_id: 'r', position_name: 'X', seats: 1, candidate_count: 0, ocd_id: null, ...over,
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
