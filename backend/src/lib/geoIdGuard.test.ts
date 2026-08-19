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
    // here those officials arrived from BOTH queries, and the results are
    // concatenated without dedup — one Bloomington address returned 139
    // politicians with 28 DUPLICATED in prod (both IN senators and four justices
    // twice each). Now 111 with 0 duplicates.
    expect(FALLBACK_EXCLUDED_MTFCCS).toContain('G4000');
  });

  it('keeps check-address-reachability.mjs modelling the statewide path', () => {
    // Excluding G4000 above makes 13 occupied state-level court districts
    // (12 IN + 1 WI) unreachable IN THAT SCRIPT'S MODEL, because their only
    // guard-satisfying polygon is the state outline. Excluding it without the
    // script's STATEWIDE_RESOLVED predicate turned master CI red on the
    // zero-tolerance ST_COVERS_ROUNDTRIP check on 2026-08-19. These two must
    // never drift apart again.
    const script = read('../../scripts/check-address-reachability.mjs');
    expect(script).toContain('STATEWIDE_RESOLVED');
    // The predicate must be the "has no geography of its own" test, NOT the old
    // `length(geo_id) <> 5` proxy — see the X0029 tests below for why.
    expect(script).toContain("gsw.geo_id = d.geo_id AND gsw.mtfcc <> 'G4000'");
    expect(script).not.toContain('length(d.geo_id) <> 5');
  });

  it('defines "statewide court" identically in the script and in buildStatewideQuery', () => {
    // Two copies of one rule. When they disagreed, a seat could be reported reachable
    // by the gate while the read path resolved it differently (or not at all).
    const script = read('../../scripts/check-address-reachability.mjs');
    const queries = read('./districtQueries.ts');
    const predicate = "gsw.geo_id = d.geo_id AND gsw.mtfcc <> 'G4000'";
    expect(script).toContain(predicate);
    expect(queries).toContain(predicate);
    // NULL geo_id must stay excluded in BOTH, or ~504 CA judges surface on every CA address.
    expect(script).toContain('d.geo_id IS NOT NULL');
    expect(queries).toContain('d.geo_id IS NOT NULL');
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

describe('X0029 — appellate districts derived as unions of counties', () => {
  it('admits X0029 for JUDICIAL explicitly, not via the X catch-all', () => {
    // Indiana Court of Appeals Districts 1-3 retain BY DISTRICT, and their polygons are
    // unions of whole counties, so they have no TIGER layer of their own (migration 1832).
    // The X catch-all in this guard admits only LOCAL/COUNTY, so without an explicit
    // clause every one of these seats would be UNREACHABLE by address.
    expect(MTFCC_DISTRICT_TYPE_GUARD).toContain(
      "(gp.mtfcc = 'X0029' AND d.district_type = 'JUDICIAL')",
    );
  });

  it('does NOT let the X catch-all admit JUDICIAL in this guard', () => {
    // districtQueries.ts's own catch-all DOES include JUDICIAL; this one must not,
    // otherwise the explicit clause above is untested cover for a silent divergence.
    const catchAll = MTFCC_DISTRICT_TYPE_GUARD.split('\n').find(
      (l) => l.includes("LIKE 'X%'") && l.includes('NOT IN'),
    );
    expect(catchAll).toBeDefined();
    expect(catchAll).not.toContain('JUDICIAL');
  });

  it('admits X0029 for JUDICIAL in the geofence district join too', () => {
    const queries = read('./districtQueries.ts');
    expect(queries).toContain("(gb.mtfcc = 'X0029' AND d.district_type = 'JUDICIAL')");
  });

  it('keeps X0029 out of the fallback exclusion list', () => {
    // X-codes never reach the fallback (it excludes `LIKE 'X%'`), so listing X0029
    // there would be misleading noise rather than protection.
    expect(FALLBACK_EXCLUDED_MTFCCS).not.toContain('X0029');
  });
});
