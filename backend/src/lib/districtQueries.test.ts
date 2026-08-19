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
  it('admits JUDICIAL but excludes 5-digit county-court geo_ids', () => {
    // State supreme/appellate courts are statewide; circuit and superior courts
    // carry 5-digit county FIPS geo_ids and resolve by geofence instead.
    const sql = buildStatewideQuery();
    expect(sql).toContain("'JUDICIAL'");
    expect(sql).toContain("AND (d.district_type != 'JUDICIAL' OR LENGTH(d.geo_id) != 5)");
  });

  it('admits DC citywide seats by geo_id, never by district_type', () => {
    // Keying on CITY_COUNCIL would return all 8 ward members for every DC address.
    const sql = buildStatewideQuery();
    expect(sql).toContain("d.geo_id IN ('dc-council-at-large', 'dc-sboe-at-large')");
    expect(sql).not.toContain("d.district_type IN ('CITY_COUNCIL'");
  });

  it('does not reference the geofence table — a statewide seat has no polygon', () => {
    expect(buildStatewideQuery()).not.toContain('geofence_boundaries');
  });

  it('scopes to the bound state while letting federal offices through', () => {
    expect(buildStatewideQuery())
      .toContain("AND (d.state = $1 OR d.district_type IN ('NATIONAL_EXEC', 'NATIONAL_JUDICIAL'))");
  });
});
