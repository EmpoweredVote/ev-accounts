-- CA_0189_link_ca_courts_to_address_geography.sql
--
-- Give California's three modelled courts the geography their voters actually live in, so the judges
-- CA_0183 seated can be reached by address. Fixes master CI job "address-search reachability"
-- (run 35909681880: `UNREACHABLE ca|JUDICIAL observed 421 (NEW bucket)`), by linking, not by baselining.
--
-- WHY
-- ---
-- All 504 California JUDICIAL districts (one district per judge: LA Superior Court 473, Second District
-- Court of Appeal 24, Supreme Court 7) carry geo_id NULL. Before CA_0183 none of them was held, so the gate
-- never counted them; CA_0183 seated 421 judges on them and CA_0187 one more (Roy G. Delgado), and every
-- one is UNREACHABLE: nothing a resident types can surface a district with no geography.
-- (LA Superior Court labels come in two shapes, "LA County Superior Court - <full name>" (425) and
-- "LA County Superior Court Seat (<surname>)" (48); the patterns below match both, and the pre-flight counts
-- every label so a third shape aborts instead of being skipped.)
-- districtQueries.ts buildStatewideQuery keeps NULL-geo JUDICIAL rows out ON PURPOSE (`d.geo_id IS NOT
-- NULL` is load-bearing), so today no California address returns any judge at all.
--
-- HOUSE PATTERN (read off Indiana / Wisconsin, not invented)
-- ------------------------------------------------------------
--   * state court    -> the 2-char state FIPS, resolved STATEWIDE by buildStatewideQuery (IN '18', WI '55').
--                       A JUDICIAL district is statewide iff it has no geofence below the G4000 outline.
--   * county court   -> the 5-digit county FIPS, resolved SPATIALLY through the G4020 county polygon
--                       (IN '18105' Monroe, mtfcc G4020). geoIdGuard.ts admits G4020 for COUNTY and JUDICIAL.
--   * multi-county appellate district -> its own polygon, the ST_Union of its member counties' G4020
--                       geofences, mtfcc X0029 (migration 1832, Indiana Court of Appeals Districts 1-3).
--
-- So:
--   1. California Supreme Court, all 7 seats          -> geo_id '06'       (G4000 'California'; statewide).
--   2. LA Superior Court, the 408 HELD seats           -> geo_id '06037'    (G4020 'Los Angeles County').
--   3. Second District Court of Appeal, the 8 HELD seats -> geo_id '06-appellate-district-2', a NEW X0029
--      polygon = union of the four member counties.
--
-- THE SECOND APPELLATE DISTRICT IS FOUR WHOLE COUNTIES, and all eight divisions serve that one district:
--   appellate.courts.ca.gov/district-courts/2dca/about, fetched 2026-09-23: "It is now made up of four
--   counties, Los Angeles, Ventura, Santa Barbara, and San Luis Obispo." Divisions 1-5, 7 and 8 sit in Los
--   Angeles and Division 6 in Ventura, but that is where the court SITS, not whom it serves: a Court of
--   Appeal justice stands for retention before the voters of the whole appellate district.
--   Counties: 06037 Los Angeles, 06111 Ventura, 06083 Santa Barbara, 06079 San Luis Obispo.
--
-- X0029 IS REUSED, NOT A NEW CODE. geoIdGuard.ts defines X0029 as "appellate districts whose geometry is a
-- union of whole counties and so has no TIGER layer of its own" -- exactly this polygon. It is already
-- admitted explicitly for JUDICIAL in BOTH geoIdGuard.ts and districtQueries.ts (the X catch-all in
-- geoIdGuard.ts admits only LOCAL/COUNTY), so reusing it needs no guard change and cannot open the drift
-- between those two copies that check-address-reachability.mjs documents. 1832's own post-verify counts
-- X0029 rows WHERE state = '18', so a California row does not disturb a re-run of it.
--
-- geo_id '06-appellate-district-2': FIPS-prefixed like X0002 ('0600001-ta-1'), and deliberately NOT numeric.
-- The 7-digit '06000NN' band that 1832's pattern would suggest is California's live school-district band
-- (G5420 '0600001' Acton-Agua Dulce, '0600009', ...), the same hazard 1832 flagged for Indiana.
--
-- 🔴 THE UNHELD SEATS STAY UNLINKED, AND THAT IS DELIBERATE (the DEAD_GEOGRAPHY trap)
-- -----------------------------------------------------------------------------------
-- The gate fails a district that has a guard-satisfying polygon and offices but NO active holder and is not
-- flagged vacant. 82 seats have no holder: LA Superior Court 65, Court of Appeal 16, Supreme Court 1.
--   * The Supreme Court seat is a REAL VACANCY. The court has exactly seven seats; its justices page
--     (supreme.courts.ca.gov/about-court/justices-court, fetched 2026-09-23) lists six justices and a
--     "Vacant Seat". The court's own release of 2025-10-09 says Justice Martin J. Jenkins "will retire from
--     the California Supreme Court at the end of October" (supreme.courts.ca.gov/news-and-events/
--     california-supreme-court-associate-justice-martin-jenkins-retire); Ballotpedia records the date as
--     2025-10-31. First vacant day 2025-11-01. That seat is flagged with essentials.vacate_office, and linked.
--     No vacancy SPAN is written: vacate_office writes none when no term is open, and the office has never
--     had a term row (Jenkins was a seatless incumbent until CA_0183 cleared him).
--   * The other 81 are STALE PER-JUDGE SLOTS, not vacancies. Each district is labelled with the judge it was
--     created for ("LA County Superior Court - Juan Carlos Dominguez", "CA 2nd DCA Division 3 - Presiding
--     Justice (Edmon)"), and those judges are no longer on the courts' rosters (CA_0183 cleared 78 of them;
--     Dominguez was cleared by CA_0187). Their judgeships have mostly been filled -- the LA directory lists 483
--     judges against 408 held here -- but, as CA_0183 records, "the courts do not map judges to these
--     per-judge slots", so no successor can be put on one. Flagging them vacant would assert 81 vacancies
--     that do not exist; linking them unflagged would be 81 DEAD_GEOGRAPHY polygons that resolve nobody. So
--     they keep geo_id NULL and stay invisible, which is their state today.
--   ⚠ CONSEQUENCE: SEATING SOMEONE ON ONE OF THOSE 81 SLOTS MUST ALSO SET ITS DISTRICT'S geo_id (same values
--     as below), in the same migration. Otherwise the gate fires `UNREACHABLE ca|JUDICIAL` again -- which is
--     the gate doing its job.
--
-- NOT CHANGED
-- -----------
--   * No politician, office_terms or race row. Roy G. Delgado (seated by CA_0187) and Juan Carlos Dominguez
--     (cleared by CA_0187) are another session's work; only Delgado's DISTRICT row is touched, by the same
--     held-seat rule as every other LA Superior Court seat.
--   * The offices carry no chamber (chamber_id NULL on all 504), so the essentials frontend files every one of
--     these judges -- Supreme Court included -- under "Local › Courts" (groupHierarchy.js keys tier and section
--     on chamber_name). That is a presentation follow-up, not a geography one.
--
-- READ-PATH CHANGE IN THE SAME PR: getRepresentativesByJurisdiction (GET /representatives/me) still used the
-- old `LENGTH(d.geo_id) != 5` statewide rule, under which '06-appellate-district-2' (23 chars) would have been
-- returned to EVERY California user. It now calls buildStatewideQuery(), the one statewide rule.
--
-- No migration runner exists; this file records SQL applied by hand. No DELETE.
-- STATUS: APPLIED to prod 2026-09-23 (operator approval: Chris Andrews). Dry run x2 (identical output, rollback
--   confirmed reverted), repeated right before the apply; re-run inside BEGIN/ROLLBACK after it: 0 districts changed,
--   every gate passed. check:reachability on prod after the apply: UNREACHABLE ca|JUDICIAL 0, OK. Live
--   POST /api/essentials/candidates/search: 200 S Spring St, Los Angeles -> LASC 408 + 2DCA 8 + Supreme Court 7
--   (1 vacant); 800 S Victoria Ave, Ventura -> 2DCA 8 + Supreme Court 7; SF City Hall -> Supreme Court 7 only.
--   offices_missing_terms unflagged 240 -> 239 (the Jenkins seat is now flagged).
--
-- ROLLBACK:
--   UPDATE essentials.districts SET geo_id = NULL, mtfcc = NULL
--    WHERE state = 'CA' AND district_type = 'JUDICIAL' AND geo_id IN ('06', '06037', '06-appellate-district-2');
--   UPDATE essentials.offices SET is_vacant = false, vacant_since = NULL
--    WHERE id = 'c4fad7bd-7935-4436-87a1-4eee556e5c3c' AND vacant_since = DATE '2025-11-01';
--   DELETE FROM essentials.geofence_boundaries WHERE geo_id = '06-appellate-district-2' AND mtfcc = 'X0029';
-- IDEMPOTENT: the polygon upserts to the same geometry, vacate_office keeps the first vacant_since, and every
-- district UPDATE is guarded on geo_id IS NULL. A re-run changes nothing and every gate still passes.

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Pre-flight. Refuse to run against a state this file was not written for.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  n_lasc int; n_coa int; n_sup int; n_other int; n_basis int; n_foreign int;
  n_counties int; n_bad_counties int; n_state_outline int; n_06_other int;
  n_jenkins int; n_jenkins_terms int;
BEGIN
  SELECT count(*) FILTER (WHERE label LIKE 'LA County Superior Court %'),
         count(*) FILTER (WHERE label LIKE 'CA 2nd DCA Division %'),
         count(*) FILTER (WHERE label LIKE 'California Supreme Court %'),
         count(*) FILTER (WHERE label NOT LIKE 'LA County Superior Court %'
                            AND label NOT LIKE 'CA 2nd DCA Division %'
                            AND label NOT LIKE 'California Supreme Court %'),
         count(*) FILTER (WHERE representation_basis <> 'residency'),
         -- pre-image: every row is either still unlinked or already on its target (re-run)
         count(*) FILTER (WHERE geo_id IS NOT NULL AND geo_id NOT IN ('06', '06037', '06-appellate-district-2'))
    INTO n_lasc, n_coa, n_sup, n_other, n_basis, n_foreign
    FROM essentials.districts
   WHERE state = 'CA' AND district_type = 'JUDICIAL';
  IF (n_lasc, n_coa, n_sup, n_other) IS DISTINCT FROM (473, 24, 7, 0) THEN
    RAISE EXCEPTION 'CA JUDICIAL districts are LASC=% COA=% SUP=% other=% (want 473/24/7/0)', n_lasc, n_coa, n_sup, n_other;
  END IF;
  IF n_basis > 0 THEN
    RAISE EXCEPTION '% CA JUDICIAL district(s) are not residency-basis; a membership seat must never get a geo_id (ADR 0003)', n_basis;
  END IF;
  IF n_foreign > 0 THEN
    RAISE EXCEPTION '% CA JUDICIAL district(s) already carry a geo_id this file does not write; someone else linked them', n_foreign;
  END IF;

  -- The four member counties exist once each as valid, non-empty G4020 polygons.
  SELECT count(*), count(*) FILTER (WHERE geometry IS NULL OR NOT public.ST_IsValid(geometry) OR public.ST_IsEmpty(geometry))
    INTO n_counties, n_bad_counties
    FROM essentials.geofence_boundaries
   WHERE mtfcc = 'G4020' AND geo_id IN ('06037', '06111', '06083', '06079');
  IF n_counties <> 4 OR n_bad_counties > 0 THEN
    RAISE EXCEPTION 'member counties: % G4020 row(s), % bad (want 4, 0)', n_counties, n_bad_counties;
  END IF;

  -- '06' must be the state outline ONLY. A second layer on '06' would make the Supreme Court "have its own
  -- geography" and drop it out of buildStatewideQuery.
  SELECT count(*) FILTER (WHERE mtfcc = 'G4000' AND public.ST_IsValid(geometry) AND NOT public.ST_IsEmpty(geometry)),
         count(*) FILTER (WHERE mtfcc <> 'G4000')
    INTO n_state_outline, n_06_other
    FROM essentials.geofence_boundaries WHERE geo_id = '06';
  IF n_state_outline <> 1 OR n_06_other > 0 THEN
    RAISE EXCEPTION 'geo_id 06: % valid G4000 row(s), % other layer(s) (want 1, 0)', n_state_outline, n_06_other;
  END IF;

  -- The new geo_id must belong to no other layer.
  IF EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '06-appellate-district-2' AND mtfcc <> 'X0029') THEN
    RAISE EXCEPTION 'geo_id 06-appellate-district-2 is already used by another layer';
  END IF;

  -- The vacant Supreme Court seat is the one this file was written for, and it has never had a term.
  SELECT count(*), coalesce(sum((SELECT count(*) FROM essentials.office_terms t WHERE t.office_id = o.id)), 0)
    INTO n_jenkins, n_jenkins_terms
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.id = 'c4fad7bd-7935-4436-87a1-4eee556e5c3c'
     AND d.label = 'California Supreme Court Justice (Jenkins)'
     AND o.title = 'Associate Justice of the California Supreme Court';
  IF n_jenkins <> 1 OR n_jenkins_terms <> 0 THEN
    RAISE EXCEPTION 'Jenkins seat: % office(s), % term row(s) (want 1, 0) -- someone has seated or changed it; re-check the court roster',
      n_jenkins, n_jenkins_terms;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. The Second Appellate District polygon: the union of its four member counties.
--    No geometry is sourced or approximated; the boundary is exactly the county polygons we already hold.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
SELECT '06-appellate-district-2',
       'California Court of Appeal, Second Appellate District',
       '06',
       'X0029',
       public.ST_Multi(public.ST_MakeValid(public.ST_Union(g.geometry))),
       'derived: union of member county G4020 geofences 06037 Los Angeles, 06111 Ventura, 06083 Santa Barbara, '
         || '06079 San Luis Obispo; composition per appellate.courts.ca.gov/district-courts/2dca/about '
         || '(fetched 2026-09-23); migration CA_0189',
       now()
  FROM essentials.geofence_boundaries g
 WHERE g.mtfcc = 'G4020' AND g.geo_id IN ('06037', '06111', '06083', '06079')
ON CONFLICT (geo_id, mtfcc) DO UPDATE
  SET geometry = EXCLUDED.geometry,
      name     = EXCLUDED.name,
      source   = EXCLUDED.source;

-- ---------------------------------------------------------------------------
-- 2. Flag the one genuinely vacant seat. First vacant day 2025-11-01 (Jenkins retired at the end of October
--    2025). vacate_office sets is_vacant and vacant_since (COALESCE: a re-run keeps the first date) and, as
--    no term is open on this office, writes no span.
-- ---------------------------------------------------------------------------
SELECT essentials.vacate_office(
  'c4fad7bd-7935-4436-87a1-4eee556e5c3c'::uuid,
  DATE '2025-11-01',
  'CA_0189 (2026-09-23): seat vacant since Justice Martin J. Jenkins retired at the end of October 2025 '
    || '(supreme.courts.ca.gov release 2025-10-09); the justices page lists six justices and a "Vacant Seat", '
    || 'fetched 2026-09-23',
  'retired');

-- ---------------------------------------------------------------------------
-- 3. Link the seats.
--    Supreme Court: all seven (six held, one flagged vacant above). Statewide, so no district mtfcc -- the
--    same as Indiana's and Wisconsin's supreme court rows.
-- ---------------------------------------------------------------------------
UPDATE essentials.districts
   SET geo_id = '06'
 WHERE state = 'CA' AND district_type = 'JUDICIAL'
   AND label LIKE 'California Supreme Court %'
   AND geo_id IS NULL;

-- LA Superior Court and the Court of Appeal: HELD seats only (see the header on the 81 stale slots).
-- "Held" is the gate's own definition: an office whose current holder is an active politician.
UPDATE essentials.districts d
   SET geo_id = v.geo_id,
       mtfcc  = v.mtfcc
  FROM (VALUES ('LA County Superior Court %', '06037',                   'G4020'),
               ('CA 2nd DCA Division %',        '06-appellate-district-2', 'X0029')) AS v(label_like, geo_id, mtfcc)
 WHERE d.state = 'CA' AND d.district_type = 'JUDICIAL'
   AND d.label LIKE v.label_like
   AND d.geo_id IS NULL
   AND EXISTS (SELECT 1
                 FROM essentials.offices o
                 JOIN essentials.office_current_holder och ON och.office_id = o.id
                 JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active
                WHERE o.district_id = d.id);

-- ---------------------------------------------------------------------------
-- 4. Post-verify. Any wrong count aborts.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  n_fence int; n_bad int; n_covered int; area_gap numeric; n_in_x0029 int;
  n_sup int; n_lasc int; n_coa int; n_lasc_null int; n_coa_null int; n_sup_null int;
  n_unreachable int; n_dead int; n_vacant int; n_vacant_since date; n_span int;
  n_06037_layers text; n_06_layers text; n_new_layers text; n_statewide_wrong int;
BEGIN
  -- 4a. Exactly one CA X0029 polygon, valid and non-empty.
  SELECT count(*), count(*) FILTER (WHERE geometry IS NULL OR NOT public.ST_IsValid(geometry) OR public.ST_IsEmpty(geometry))
    INTO n_fence, n_bad
    FROM essentials.geofence_boundaries WHERE mtfcc = 'X0029' AND state = '06';
  IF n_fence <> 1 OR n_bad > 0 THEN
    RAISE EXCEPTION 'expected 1 valid CA X0029 geofence, found % (% bad)', n_fence, n_bad;
  END IF;

  -- 4b. It must contain exactly its four member counties and no other California county. A union that
  --     silently dropped a county still passes ST_IsValid, so count what the polygon actually covers.
  SELECT count(*) INTO n_covered
    FROM essentials.geofence_boundaries c, essentials.geofence_boundaries x
   WHERE c.mtfcc = 'G4020' AND c.state = '06'
     AND x.geo_id = '06-appellate-district-2' AND x.mtfcc = 'X0029'
     AND public.ST_Covers(x.geometry, public.ST_PointOnSurface(c.geometry));
  IF n_covered <> 4 THEN
    RAISE EXCEPTION 'appellate polygon covers % CA county interior point(s), want 4', n_covered;
  END IF;

  -- 4c. Its area must equal the sum of the four counties (they do not overlap; measured union = sum).
  SELECT abs(public.ST_Area(x.geometry) - c.total) / c.total INTO area_gap
    FROM essentials.geofence_boundaries x,
         (SELECT sum(public.ST_Area(geometry)) AS total FROM essentials.geofence_boundaries
           WHERE mtfcc = 'G4020' AND geo_id IN ('06037', '06111', '06083', '06079')) c
   WHERE x.geo_id = '06-appellate-district-2' AND x.mtfcc = 'X0029';
  IF area_gap IS NULL OR area_gap > 0.0001 THEN
    RAISE EXCEPTION 'appellate polygon does not reconstruct its four counties: relative area gap %', area_gap;
  END IF;

  -- 4d. Indiana's three X0029 polygons (migration 1832) are untouched.
  SELECT count(*) INTO n_in_x0029 FROM essentials.geofence_boundaries WHERE mtfcc = 'X0029' AND state = '18';
  IF n_in_x0029 <> 3 THEN
    RAISE EXCEPTION 'Indiana X0029 polygons: % (want 3)', n_in_x0029;
  END IF;

  -- 4e. Linked and unlinked counts, per court.
  SELECT count(*) FILTER (WHERE label LIKE 'California Supreme Court %' AND geo_id = '06' AND mtfcc IS NULL),
         count(*) FILTER (WHERE label LIKE 'LA County Superior Court %' AND geo_id = '06037' AND mtfcc = 'G4020'),
         count(*) FILTER (WHERE label LIKE 'CA 2nd DCA Division %' AND geo_id = '06-appellate-district-2' AND mtfcc = 'X0029'),
         count(*) FILTER (WHERE label LIKE 'LA County Superior Court %' AND geo_id IS NULL),
         count(*) FILTER (WHERE label LIKE 'CA 2nd DCA Division %' AND geo_id IS NULL),
         count(*) FILTER (WHERE label LIKE 'California Supreme Court %' AND geo_id IS NULL)
    INTO n_sup, n_lasc, n_coa, n_lasc_null, n_coa_null, n_sup_null
    FROM essentials.districts WHERE state = 'CA' AND district_type = 'JUDICIAL';
  IF (n_sup, n_lasc, n_coa, n_lasc_null, n_coa_null, n_sup_null) IS DISTINCT FROM (7, 408, 8, 65, 16, 0) THEN
    RAISE EXCEPTION 'linked SUP=% LASC=% COA=%, unlinked LASC=% COA=% SUP=% (want 7/408/8, 65/16/0)',
      n_sup, n_lasc, n_coa, n_lasc_null, n_coa_null, n_sup_null;
  END IF;

  -- 4f. The gate's two conditions, restated for these courts. UNREACHABLE: an active holder on an unlinked
  --     district. DEAD_GEOGRAPHY: a linked district with neither an active holder nor a vacant-flagged office.
  SELECT count(*) INTO n_unreachable
    FROM essentials.districts d
   WHERE d.state = 'CA' AND d.district_type = 'JUDICIAL' AND d.geo_id IS NULL
     AND EXISTS (SELECT 1 FROM essentials.offices o
                   JOIN essentials.office_current_holder och ON och.office_id = o.id
                   JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active
                  WHERE o.district_id = d.id);
  SELECT count(*) INTO n_dead
    FROM essentials.districts d
   WHERE d.state = 'CA' AND d.district_type = 'JUDICIAL' AND d.geo_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                       LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
                       LEFT JOIN essentials.politicians p ON p.id = och.politician_id
                      WHERE o.district_id = d.id AND (p.is_active OR o.is_vacant));
  IF n_unreachable > 0 OR n_dead > 0 THEN
    RAISE EXCEPTION 'CA JUDICIAL: % held-but-unlinked, % linked-but-dead district(s) (want 0, 0)', n_unreachable, n_dead;
  END IF;

  -- 4g. The vacancy is a flag with its date, and no span was invented.
  SELECT count(*) FILTER (WHERE is_vacant), max(vacant_since) INTO n_vacant, n_vacant_since
    FROM essentials.offices WHERE id = 'c4fad7bd-7935-4436-87a1-4eee556e5c3c';
  SELECT count(*) INTO n_span FROM essentials.office_terms WHERE office_id = 'c4fad7bd-7935-4436-87a1-4eee556e5c3c';
  IF n_vacant <> 1 OR n_vacant_since IS DISTINCT FROM DATE '2025-11-01' OR n_span <> 0 THEN
    RAISE EXCEPTION 'Jenkins seat: vacant=% since=% spans=% (want 1, 2025-11-01, 0)', n_vacant, n_vacant_since, n_span;
  END IF;

  -- 4h. Each target geo_id carries only the layers the guard is known to resolve correctly for JUDICIAL.
  --     06037: G4020 matches JUDICIAL; G5210/G5220 match only STATE_UPPER/STATE_LOWER; G6350 (a Connecticut
  --     ZIP that happens to read 06037) is excluded from the catch-all. Any OTHER layer landing on one of
  --     these ids could reach the fallback clause and match a judge by bare geo_id.
  SELECT string_agg(mtfcc, ',' ORDER BY mtfcc) INTO n_06037_layers FROM essentials.geofence_boundaries WHERE geo_id = '06037';
  SELECT string_agg(mtfcc, ',' ORDER BY mtfcc) INTO n_06_layers    FROM essentials.geofence_boundaries WHERE geo_id = '06';
  SELECT string_agg(mtfcc, ',' ORDER BY mtfcc) INTO n_new_layers   FROM essentials.geofence_boundaries WHERE geo_id = '06-appellate-district-2';
  IF n_06037_layers IS DISTINCT FROM 'G4020,G5210,G5220,G6350' OR n_06_layers IS DISTINCT FROM 'G4000'
     OR n_new_layers IS DISTINCT FROM 'X0029' THEN
    RAISE EXCEPTION 'layers on target geo_ids: 06037=% 06=% new=% (want G4020,G5210,G5220,G6350 / G4000 / X0029)',
      n_06037_layers, n_06_layers, n_new_layers;
  END IF;

  -- 4i. buildStatewideQuery's rule: statewide iff no geofence below the state outline. The Supreme Court must
  --     be statewide; the Superior Court and the Court of Appeal must NOT be (else every CA address gets them).
  SELECT count(*) INTO n_statewide_wrong
    FROM essentials.districts d
   WHERE d.state = 'CA' AND d.district_type = 'JUDICIAL' AND d.geo_id IS NOT NULL
     AND (d.geo_id = '06') IS DISTINCT FROM
         NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gsw WHERE gsw.geo_id = d.geo_id AND gsw.mtfcc <> 'G4000');
  IF n_statewide_wrong > 0 THEN
    RAISE EXCEPTION '% CA court district(s) resolve through the wrong path (statewide vs spatial)', n_statewide_wrong;
  END IF;

  RAISE NOTICE 'OK: 2nd Appellate District polygon (4 counties); linked SUP 7 / LASC 408 / COA 8; 81 stale slots unlinked; Jenkins seat vacant since 2025-11-01';
END $$;

COMMIT;
