import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';

// Source-pattern guards for the browse / elections "full overlapping stack"
// resolution. The behavior itself is PostGIS-against-the-DB (verified manually
// against prod), so these lock in the structural decisions that make the area
// and government-list browse paths return the same county/school/legislative
// stack the address path does — and prevent silent regressions.

const read = (rel: string) =>
  fs.readFileSync(path.resolve(__dirname, rel), 'utf-8');
const stripComments = (s: string) =>
  s
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/^\s*\/\/.*$/gm, '')
    .replace(/--.*$/gm, '');

const BROWSE = stripComments(read('./essentialsBrowseService.ts'));
const ELECTIONS = stripComments(read('./electionService.ts'));

describe('overlap resolution captures county + school, not just legislative', () => {
  it('resolveOverlappingGeoPairs full-intersect branch includes county (G4020) and school (G54xx)', () => {
    // The genuine-interior-overlap branch must cover county + school MTFCCs, so an
    // area straddling two counties / school districts surfaces ALL of them (not
    // just the one whose center it contains). Guard is order-independent: the WHERE
    // conjuncts (mtfcc IN / ST_Intersects / NOT ST_Touches) may be written in any
    // order — the branch is anchored by G5200, which is unique to this MTFCC list.
    const m = BROWSE.match(/mtfcc\s+IN\s*\(([^)]*\bG5200\b[^)]*)\)/);
    expect(m).not.toBeNull();
    const list = m![1];
    for (const code of ['G5200', 'G5210', 'G5220', 'G4020', 'G5400', 'G5410', 'G5420']) {
      expect(list).toContain(code);
    }
    // ...and that branch resolves by real interior overlap, not a boundary touch.
    expect(BROWSE).toMatch(/ST_Intersects/);
    expect(BROWSE).toMatch(/AND\s+NOT\s+ST_Touches/);
  });

  it('exposes a multi-seed resolver and a government-geofence resolver', () => {
    expect(BROWSE).toMatch(/export async function resolveOverlappingGeoPairs/);
    expect(BROWSE).toMatch(/export async function getOverlappingGeoIdsForGovernments/);
  });
});

describe('government-list browse resolves the full district stack', () => {
  it('getPoliticiansByGovernmentList resolves overlapping districts via the geofence resolver', () => {
    expect(BROWSE).toMatch(/getOverlappingGeoIdsForGovernments\(governmentGeoIds, countyGeoId\)/);
    expect(BROWSE).toMatch(/fetchDistrictPoliticianRows/);
  });

  it('district-politician fetch applies the MTFCC guard (handles GEOID collisions / empty districts.mtfcc)', () => {
    expect(BROWSE).toMatch(/fetchDistrictPoliticianRows[\s\S]*?MTFCC_DISTRICT_TYPE_GUARD/);
  });
});

describe('government-list elections resolve district races (not just government-linked)', () => {
  it('getElectionsByGovernmentGeoIds uses the geofence resolver + district race fetch', () => {
    expect(ELECTIONS).toMatch(/getOverlappingGeoIdsForGovernments\(governmentGeoIds\)/);
    expect(ELECTIONS).toMatch(/fetchDistrictRaceRows\(geoPairs\)/);
  });

  it('district race fetch applies the MTFCC guard', () => {
    expect(ELECTIONS).toMatch(/fetchDistrictRaceRows[\s\S]*?MTFCC_DISTRICT_TYPE_GUARD/);
  });
});
