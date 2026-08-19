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

  it('does NOT exclude G4000 — pinned deliberately, with a debt attached', () => {
    // Excluding it here is arguably correct (it makes every address lookup return
    // statewide officials twice — 28 duplicates on one Bloomington address), and
    // it was tried and reverted on 2026-08-19: check-address-reachability.mjs
    // treats a statewide seat's G4000 polygon as its ONLY proof of reachability,
    // so the exclusion flipped ~105 baseline buckets and tripped the
    // zero-tolerance ST_COVERS_ROUNDTRIP check.
    //
    // This assertion exists so the next person to add it must read that note and
    // fix the script in the same change, rather than rediscovering it in red CI
    // on master. The ZIP/area path excludes G4000 in its own predicate instead.
    expect(FALLBACK_EXCLUDED_MTFCCS).not.toContain('G4000');
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
