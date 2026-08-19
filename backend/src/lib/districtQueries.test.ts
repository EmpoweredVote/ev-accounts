import { describe, it, expect } from 'vitest';
import { buildDistrictQuery, buildStatewideQuery } from './districtQueries.js';

// Structural guards for the shared district-query builders. The behavior itself
// is PostGIS-against-the-DB (verified against prod), so these lock in the
// decisions that keep the point path and the area path from drifting — same
// idiom as browseResolution.test.ts.

describe('buildDistrictQuery', () => {
  const base = { spatialPredicate: 'public.ST_Covers(gb.geometry, $1)' };

  it('places the spatial predicate in the WHERE clause', () => {
    expect(buildDistrictQuery(base)).toContain('WHERE public.ST_Covers(gb.geometry, $1)');
  });

  it('keeps G6350 excluded from the catch-all clause', () => {
    // A ZIP polygon must never join to a district on a bare geo_id match —
    // in the AREA path or the ADDRESS path, since both build from this text.
    expect(buildDistrictQuery(base)).toContain("'G6350'");
  });

  it('joins geofence_boundaries to districts with the MTFCC mapping', () => {
    const sql = buildDistrictQuery(base);
    expect(sql).toContain('FROM essentials.geofence_boundaries gb');
    expect(sql).toContain('JOIN essentials.districts d ON d.geo_id = gb.geo_id');
    // The mapping is what stops SLDU matching SLDL on a shared GEOID.
    expect(sql).toContain("(gb.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER')");
    expect(sql).toContain("OR (gb.mtfcc = 'G5220' AND d.district_type = 'STATE_LOWER')");
  });

  it('resolves occupancy through office_current_holder, admitting vacant seats', () => {
    const sql = buildDistrictQuery(base);
    expect(sql).toContain('LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id');
    expect(sql).toContain('AND (p.is_active = true OR o.is_vacant = true)');
  });

  it('prepends a CTE when withPrefix is given', () => {
    const sql = buildDistrictQuery({ ...base, withPrefix: 'WITH zcta AS (SELECT 1)' });
    expect(sql.trimStart().startsWith('WITH zcta AS (SELECT 1)')).toBe(true);
  });

  it('emits no CTE keyword when withPrefix is absent', () => {
    expect(buildDistrictQuery(base)).not.toContain('WITH zcta');
  });

  it('appends extraSelect columns', () => {
    expect(buildDistrictQuery({ ...base, extraSelect: ', 1 AS share' })).toContain(', 1 AS share');
  });

  it('excludes challengers by default and admits them on request', () => {
    expect(buildDistrictQuery(base)).toContain("NOT ILIKE 'Candidate for%'");
    expect(buildDistrictQuery({ ...base, includeChallengers: true }))
      .not.toContain("NOT ILIKE 'Candidate for%'");
  });

  it('appends orderByTail after the DISTINCT ON key', () => {
    const sql = buildDistrictQuery({ ...base, orderByTail: ', share DESC NULLS LAST' });
    expect(sql).toContain('ORDER BY COALESCE(p.id, o.id), share DESC NULLS LAST');
  });

  it('keeps DISTINCT ON keyed on COALESCE(p.id, o.id) so a vacant seat still dedupes', () => {
    expect(buildDistrictQuery(base)).toContain('DISTINCT ON (COALESCE(p.id, o.id))');
  });
});

describe('buildStatewideQuery', () => {
  it('admits a JUDICIAL seat only when it has no geography of its own', () => {
    // Was `LENGTH(d.geo_id) != 5` — a proxy for "county courts resolve by geofence,
    // everything else is statewide". It misclassified Indiana's Court of Appeals:
    // Districts 1-3 retain BY DISTRICT but carry 7-char geo_ids, so every Indiana
    // address got all of them. The rule now asks the real question — does this court
    // own a polygon below the state outline?
    const sql = buildStatewideQuery();
    expect(sql).toContain("'JUDICIAL'");
    expect(sql).toContain("gsw.geo_id = d.geo_id AND gsw.mtfcc <> 'G4000'");
    expect(sql).not.toContain('LENGTH(d.geo_id) != 5');
  });

  it('keeps NULL-geo_id judicial rows OUT of the statewide path', () => {
    // ~504 California JUDICIAL rows carry a NULL geo_id. Under the old rule
    // LENGTH(NULL) != 5 evaluated to NULL and excluded them. A bare NOT EXISTS is
    // vacuously TRUE for them, so without this clause all 504 would surface on
    // every California address. Measured against prod: CA 0 -> 504.
    expect(buildStatewideQuery()).toContain('d.geo_id IS NOT NULL');
  });

  it('admits DC citywide seats by geo_id, never by district_type', () => {
    // Keying on CITY_COUNCIL would return all 8 ward members for every DC address.
    const sql = buildStatewideQuery();
    expect(sql).toContain("d.geo_id IN ('dc-council-at-large', 'dc-sboe-at-large')");
    expect(sql).not.toContain("d.district_type IN ('CITY_COUNCIL'");
  });

  it('never MATCHES a statewide seat against a polygon', () => {
    // The original assertion was "does not reference geofence_boundaries at all". That
    // held while statewide-ness was inferred from geo_id length. It now needs the table
    // to ask whether a court owns geography — but ONLY as an anti-join discriminator.
    // What must stay true is the design itself: a statewide seat is admitted by
    // district_type + state, never by intersecting its polygon. So the table may appear
    // exactly once, inside the NOT EXISTS, and never in FROM/JOIN position.
    const sql = buildStatewideQuery();
    expect(sql).not.toMatch(/(FROM|JOIN)\s+essentials\.geofence_boundaries\s+gbo?\b/);
    expect(sql).not.toContain('ST_Covers');
    expect(sql).not.toContain('ST_Intersects');
    const refs = sql.match(/geofence_boundaries/g) ?? [];
    expect(refs).toHaveLength(1);
    expect(sql).toMatch(/NOT EXISTS \(SELECT 1 FROM essentials\.geofence_boundaries gsw/);
  });

  it('scopes to the bound state while letting federal offices through', () => {
    expect(buildStatewideQuery())
      .toContain("AND (d.state = $1 OR d.district_type IN ('NATIONAL_EXEC', 'NATIONAL_JUDICIAL'))");
  });
});
