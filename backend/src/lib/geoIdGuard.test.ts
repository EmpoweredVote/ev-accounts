import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import {
  FALLBACK_EXCLUDED_MTFCCS,
  FALLBACK_EXCLUDED_MTFCC_SQL_LIST,
  MTFCC_DISTRICT_TYPE_GUARD,
} from './geoIdGuard.js';

// Source-pattern guards for the district-join catch-all clause, in the same
// idiom as browseResolution.test.ts: the behavior itself is PostGIS-against-the-DB,
// so these lock in the structural decision that keeps a ZIP polygon out of the
// district join.

const read = (rel: string) => fs.readFileSync(path.resolve(__dirname, rel), 'utf-8');

describe('fallback MTFCC exclusion list', () => {
  it('excludes G6350 so a ZCTA can never join to a district by bare geo_id', () => {
    // A ZIP polygon has no districts of its own. The catch-all clause means
    // "match any district_type for this geo_id", so without this exclusion
    // geo_id '46220' would match any district row that happens to carry '46220'.
    expect(FALLBACK_EXCLUDED_MTFCCS).toContain('G6350');
  });

  it('excludes G4000 so statewide seats come from ONE query, not two', () => {
    // A Governor/Senator/state-supreme-court seat has no polygon; it is resolved
    // by district_type + state in buildStatewideQuery. While G4000 was admitted
    // here, those officials arrived from both queries and the results are
    // concatenated without dedup — a single Bloomington address returned 28
    // duplicated politicians in prod (both IN senators, 4 justices, twice each).
    // For an AREA query it also smuggled a neighbouring state's whole executive
    // branch past the 1% multi-state floor (ZIP 46360 clips MI by 0.013%).
    expect(FALLBACK_EXCLUDED_MTFCCS).toContain('G4000');
  });

  it('renders the list as a single-quoted SQL IN list', () => {
    expect(FALLBACK_EXCLUDED_MTFCC_SQL_LIST).toContain("'G6350'");
    expect(FALLBACK_EXCLUDED_MTFCC_SQL_LIST).toContain("'G5200V26'");
    expect(FALLBACK_EXCLUDED_MTFCC_SQL_LIST.startsWith("'")).toBe(true);
  });

  it('keeps every previously-excluded MTFCC — this list may only grow', () => {
    // Dropping one of these would silently re-admit a whole layer to the
    // catch-all clause. G5200V26 in particular must stay out: only the
    // elections opt-in join may resolve against 2026-vintage boundaries.
    for (const code of [
      'G5210', 'G5220', 'G5200', 'G4020', 'G4040', 'G4110', 'G4120',
      'G5400', 'G5410', 'G5420', 'G5200V26',
    ]) {
      expect(FALLBACK_EXCLUDED_MTFCCS).toContain(code);
    }
  });

  it('builds the guard SQL from the shared list so the copies cannot drift', () => {
    expect(MTFCC_DISTRICT_TYPE_GUARD).toContain(FALLBACK_EXCLUDED_MTFCC_SQL_LIST);
  });

  it('leaves no hard-coded duplicate of the list in districtQueries.ts', () => {
    // Drift guard: the second copy of this list used to live inline in
    // essentialsService.ts's districtQueryText. That clause now lives in
    // districtQueries.ts and must interpolate the constant, so adding an MTFCC
    // in geoIdGuard.ts cannot leave the address path behind.
    const src = read('./districtQueries.ts');
    expect(src).not.toContain("'G5400','G5410','G5420','G5200V26'");
    expect(src).toContain('FALLBACK_EXCLUDED_MTFCC_SQL_LIST');
  });

  it('leaves no copy of the fallback clause behind in essentialsService.ts', () => {
    // The whole point of the extraction: essentialsService must not carry its
    // own geofence->districts join any more.
    const src = read('./essentialsService.ts');
    expect(src).not.toContain("'G5400','G5410','G5420','G5200V26'");
    expect(src).toContain('buildDistrictQuery(');
  });
});
