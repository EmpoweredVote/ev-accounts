import { describe, it, expect } from 'vitest';
import { buildDistrictQuery, buildStatewideQuery } from './districtQueries.js';

// Structural guards for the shared district-query builders. The behavior itself
// is PostGIS-against-the-DB (verified against prod), so these lock in the
// decisions that keep the point path and the area path from drifting — same
// idiom as browseResolution.test.ts.

describe('buildDistrictQuery', () => {
  const base = { spatialPredicate: 'ST_Covers(gb.geometry, $1)' };

  it('places the spatial predicate in the WHERE clause', () => {
    expect(buildDistrictQuery(base)).toContain('WHERE ST_Covers(gb.geometry, $1)');
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
    // Match the row filter on THIS row's office (`o.title`), not the bare phrase: the is_incumbent
    // SELECT item (incumbency.ts) carries the same placeholder test on its own alias `o_inc`.
    const rowFilter = "COALESCE(o.title, '') NOT ILIKE 'Candidate for%'";
    expect(buildDistrictQuery(base)).toContain(rowFilter);
    expect(buildDistrictQuery({ ...base, includeChallengers: true }))
      .not.toContain(rowFilter);
  });

  it('appends orderByTail after the DISTINCT ON key', () => {
    const sql = buildDistrictQuery({ ...base, orderByTail: ', share DESC NULLS LAST' });
    expect(sql).toContain('ORDER BY o.id, share DESC NULLS LAST');
  });

  // 🔴 The key is the OFFICE, never the politician. Keyed on the person (the old
  // `COALESCE(p.id, o.id)`), someone holding two seats reachable from one address collapsed to
  // one row and the voter never saw the second — a state representative who also sits on the
  // city council showed as one or the other. 27 active people hold 2+ current seats.
  it('keys DISTINCT ON the office, so one person holding two seats returns two rows', () => {
    const sql = buildDistrictQuery(base);
    expect(sql).toContain('DISTINCT ON (o.id)');
    expect(sql).not.toContain('DISTINCT ON (COALESCE(p.id, o.id))');
  });

  // 🟢 ...but a DISTINCT must still be there. Several geofence rows can share a geo_id and map
  // to the same district type, so the join really does return an office more than once:
  // measured against prod 2026-10-26, Indianapolis returned 129 rows for 89 offices.
  it('still de-duplicates, because the geofence join fans the same office out', () => {
    expect(buildDistrictQuery(base)).toContain('DISTINCT ON (');
  });

  // The ORDER BY must lead with the DISTINCT ON key or Postgres rejects the query outright.
  it('orders by the same key it de-duplicates on', () => {
    expect(buildDistrictQuery(base)).toContain('ORDER BY o.id');
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

describe('every politician row carries its office id', () => {
  // The mapper tests in essentialsService.vacantRows.test.ts mock the query, so they cannot
  // see whether the column is actually selected. This is the half that can.
  const base = { spatialPredicate: 'ST_Covers(gb.geometry, $1)' };

  it('selects o.id AS office_id — the only key a VACANT row has', () => {
    // A seat with no current term comes back with every p.* column NULL. Without this column
    // such a row carries no identifier at all and a client cannot key, link or dedupe it.
    expect(buildDistrictQuery(base)).toContain('o.id AS office_id');
  });

  it('selects it on the statewide query too, which is where most vacancies surface', () => {
    expect(buildStatewideQuery()).toContain('o.id AS office_id');
  });

  it('🔴 selects o.description AS office_description — the mapper reads it and the SQL did not', () => {
    // This is the exact shape of the defect this guard exists for: the mapper has always done
    // `office_description: row.office_description ?? ''`, so a missing column is not a crash and
    // not a type error — it is a silently empty field on every address lookup. Only the SQL text
    // can show it. Found in production by writing a description and reading "" back from the API.
    expect(buildDistrictQuery(base)).toContain('o.description AS office_description');
  });

  it('selects the description on the statewide query too', () => {
    expect(buildStatewideQuery()).toContain('o.description AS office_description');
  });
});

describe('CC_0458 pending winner and seat group', () => {
  const base = { spatialPredicate: 'ST_Covers(gb.geometry, $1)' };

  it('selects the pending-winner columns on both builders', () => {
    for (const sql of [buildDistrictQuery(base), buildStatewideQuery()]) {
      // 🔴 to_char, NOT the raw date column. node-postgres parses OID 1082 into a JS Date at
      // LOCAL midnight, and String(that).slice(0, 10) is "Tue Nov 3" — a weekday and no year.
      // That is what incoming_on served live before CC_0391. Same rule, same reason.
      expect(sql).toContain("to_char(opw.election_date, 'YYYY-MM-DD') AS pending_election_date");
      expect(sql).toContain('opw.winners AS pending_winners');
      expect(sql).toContain('dsg.group_id');
    }
  });

  // 🔴 An inner join here would EMPTY EVERY ADDRESS RESULT: 1,334 offices of 11,155 have a
  // pending winner, and far fewer have one at any given address.
  it('joins both new views as LEFT JOINs', () => {
    const sql = buildDistrictQuery(base);
    expect(sql).toContain('LEFT JOIN essentials.office_pending_winner opw ON opw.office_id = o.id');
    expect(sql).toMatch(/LEFT JOIN essentials\.district_seat_group dsg/);
  });

  // Review Focus 1. A plain `=` on chamber_id drops the group for every seat whose chamber is
  // NULL, because NULL = NULL is not a match — the multi-seat cases would silently vanish for
  // them, which looks exactly like "this body has nothing coming".
  it('matches the seat group on a null chamber_id', () => {
    expect(buildDistrictQuery(base)).toContain(
      'dsg.chamber_id IS NOT DISTINCT FROM o.chamber_id'
    );
  });

  // Review Focus 1. Neither new join may multiply rows: office_pending_winner is one row per
  // office and district_seat_group is one row per group, so the DISTINCT ON must still be the
  // thing that guarantees one row per office rather than a thing papering over a fan-out.
  it('still de-duplicates on the office', () => {
    expect(buildDistrictQuery(base)).toContain('DISTINCT ON (o.id)');
    expect(buildDistrictQuery(base)).toContain('ORDER BY o.id');
  });

  it('selects all four group columns, so the render can apply the three-numbers rule', () => {
    const sql = buildDistrictQuery(base);
    for (const col of ['group_id', 'group_offices', 'group_winners', 'group_seated']) {
      expect(sql).toContain(col);
    }
  });
});
