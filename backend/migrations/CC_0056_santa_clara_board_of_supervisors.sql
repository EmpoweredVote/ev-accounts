-- CC_0056_santa_clara_board_of_supervisors.sql
--
-- Santa Clara County, CA — seat the Board of Supervisors. Five districts, five offices,
-- five people, five dated terms. Wave CA-2 of the Knight Foundation cities program.
--
-- APPLY AFTER scripts/load-santa-clara-supervisor-boundaries.ts. This migration REFUSES to
-- run without the five X0047 boundaries, because a district row pointing at a geo_id with no
-- polygon is invisible to address resolution and nothing errors.
--
-- Spec:    docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
-- Roster:  backend/data/seed-santa-clara-2026/ROSTERS.md
-- Tracker: .planning/knight-foundation/PROGRAM.md
--
-- ── WHAT IS MISSING ──────────────────────────────────────────────────────────────────────
-- Santa Clara County holds THREE offices in production — Assessor, Sheriff, District
-- Attorney — all on the countywide district 06085/G4020. The Board of Supervisors, the
-- county's actual legislative body, has ZERO offices. Measured 2026-09-03.
--
-- So an address in Santa Clara County today returns a San José councilmember and three
-- countywide officers, and NO supervisor. The seat a resident is most likely to want is the
-- one that is absent.
--
-- ── STRUCTURE, AND WHY IT IS district_type 'COUNTY' ──────────────────────────────────────
-- The structural analogue already in production is RACINE COUNTY, WISCONSIN (X-RC-SUP): a
-- county board with single-member supervisorial districts, written as district_type 'COUNTY'
-- with ocd_id '.../county:racine/council_district:N'. This follows it exactly.
--
-- ⚠ NOT 'LOCAL'. LOCAL is what X0045 (Macon-Bibb) and X0021 use, and both are CITY bodies —
--   Macon-Bibb only because it is a consolidated city-county. Santa Clara County is not
--   consolidated: the City of San José is a separate government with its own eleven seats,
--   already in production. Writing these as LOCAL would put county supervisors in the same
--   tier as city councillors over the same ground.
--
-- ── THE GEOMETRY WAS ARBITRATED, AND THE COUNTY PUBLISHES FIVE COMPETING LAYERS ──────────
-- 🔴🔴 THE LAYER WITH THE FRESHEST EDIT DATE CARRIES THE OLDEST MAP. The county Planning
--    layer has the most recent edit date in the county's entire GIS estate and the correct
--    five names, and its boundaries are IDENTICAL to the superseded 2011 map.
--
-- 🟢 The arbiter is the Board's own resident-facing "Find My Supervisor" app, re-verified
--    2026-09-03 by walking appid -> webmap -> layer. The loader's GATE 5 asserts every
--    district differs substantially from the 2011 map, which is what a load of the trap
--    layer would fail.
--
-- ── OCCUPANCY: THE DAY RULE IS PUBLISHED, THE YEAR IS NOT ALWAYS SOURCED ─────────────────
-- The Registrar states on EVERY county office page, verbatim:
--
--     "Term Begins: First Monday after January 1 at Noon"
--     "Term of Office: 4 Years with a 3-Term Limit"   (supervisors)
--
-- That is an instrument stating the commencement rule in terms, so the DAY is sound wherever
-- the YEAR is sourced. Three of the five have a directly sourced start; two do not, and they
-- are written at 'year' rather than given a day the sources do not support:
--
--   D2 Betty Duong        2025-01-06  day   directly sourced — succeeded Chavez, who ended
--                                           2025-01-06
--   D3 Otto Lee           2021-01-04  day   directly sourced — "assumed office January 4,
--                                           2021", which is the rule's own answer for 2021
--   D5 Margaret Abe-Koga  2025-01-06  day   directly sourced — succeeded Simitian
--   D1 Sylvia Arenas      2023-01-01  YEAR  the year is cycle arithmetic (D1's next election
--                                           is 2026, terms are 4 years), not a source
--   D4 Susan Ellenberg    2019-01-01  YEAR  same, and the research pass flagged it as the
--                                           weakest of the five
--
-- ⚠ ELLENBERG AND ARENAS WERE CHASED BEFORE BEING DOWNGRADED, and the negative result is
--   the point: the Registrar's own office pages publish NO assumed-office date, the county's
--   D4 site carries no tenure prose on its home page or its Bio page, and no certified 2018
--   Statement of Vote could be reached. The research record said "confirm against the
--   Registrar's 2018 certified results before writing, or drop her to `year`". It could not
--   be confirmed, so she is dropped to 'year'. Writing 2019-01-07 would have asserted a day
--   derived from a year nobody published.
--
-- ── THE CHANGE-CHECK, RE-RUN LIVE ON THE DAY OF APPLY ───────────────────────────────────
-- 🔴 A CHANGE-CHECK ASKS "HAS THIS PERSON LEFT?", NOT "DO MY SOURCES AGREE?" Re-read
--    2026-09-03 from the Registrar's five district pages AND the layer's own roster field:
--    all five present, all five matching. Nobody has left.
--
-- ⚠ FIVE OF THE COUNTY'S EIGHT SEATS TURN OVER IN JANUARY 2027 — D1 (Arenas) and D4
--   (Ellenberg) are on the 2026 ballot, as are the Assessor, Sheriff and District Attorney.
--   NO 2026 WINNER IS WRITTEN HERE. A certified result is not a fact about who holds a seat;
--   Columbus taught that, where 4 of 6 winners were not yet seated.
--
-- ⚠ THE REGISTRAR NAMES TWO BOARD PRESIDENTS — Lee (D3) and Ellenberg (D4) both carry the
--   label, so one page is stale. It does not matter and is deliberately not modelled: a
--   rotating role is a parenthetical on a seat title, never its own office.
--
-- ── external_id ─────────────────────────────────────────────────────────────────────────
-- 🔴 THE BAND WAS MEASURED, NOT ASSUMED. The county's three existing officers occupy
--    -6085001..-6085003 (county FIPS 06085). The rest of -6085xxx is empty, so the
--    supervisors take -6085011..-6085015 — a gap above the officers so the two blocks stay
--    legible. An external_id collision seats the WRONG person silently, and
--    ON CONFLICT DO NOTHING would absorb it without a word.
--
-- ⚠ FIVE CAL-ACCESS COMMITTEE ROWS LOOK LIKE THESE PEOPLE AND ARE NOT THEM.
--   'ARENAS FOR SUPERVISOR 2022; SYLVIA', 'ELLENBERG FOR SANTA CLARA SUPERVISOR 2018; SUSAN'
--   and ~40 more are campaign-committee names ingested as politicians. All are
--   is_active = false with no photo and no compass answers. NOTHING here touches them, and
--   none is reused as the officeholder: a committee is not a person. Verified 2026-09-03
--   that no person-shaped row exists for any of the five.
--
-- ⚠ POPULATION IS NOT WRITTEN. Layer E carries no population field and nothing else was
--   sourced, so districts.population stays NULL rather than carrying a guess.
--
-- Idempotent throughout: every INSERT is guarded on a natural key, so a re-run is a no-op.

BEGIN;

-- ── 0. PRE-FLIGHT: the polygons must already be loaded ──────────────────────────────────
DO $$
DECLARE v_n integer;
BEGIN
  SELECT count(*) INTO v_n
    FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0047'
     AND geo_id LIKE 'santa-clara-ca-supervisor-district-%';
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'pre-flight: expected 5 X0047 boundaries, found %. Run scripts/load-santa-clara-supervisor-boundaries.ts first — a district pointing at a geo_id with no polygon is invisible to address resolution and NOTHING ERRORS.', v_n;
  END IF;
END $$;

-- ── 1. The chamber ──────────────────────────────────────────────────────────────────────
-- ⚠ `slug` is a GENERATED column — inserting into it is an error, not a no-op.
INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, term_limit,
   inauguration_rules, election_rules, election_method)
SELECT g.id,
       'Board of Supervisors',
       'Board of Supervisors of the County of Santa Clara',
       5, 4, 3,
       'Term begins the first Monday after January 1 at noon (Santa Clara County Registrar of Voters, county office pages, read 2026-09-03)',
       'Primary and General (runoff)',
       'single-member district'
  FROM essentials.governments g
 WHERE g.geo_id = '06085' AND g.type = 'County'
   AND NOT EXISTS (
     SELECT 1 FROM essentials.chambers c
      WHERE c.government_id = g.id AND c.name = 'Board of Supervisors');

-- ── 2. The five districts ───────────────────────────────────────────────────────────────
INSERT INTO essentials.districts
  (label, district_type, state, geo_id, mtfcc, ocd_id, num_officials,
   representation_basis, government_id, official_web_url, last_update_date)
SELECT 'Santa Clara County Supervisorial District ' || d.n,
       'COUNTY',
       'ca',
       'santa-clara-ca-supervisor-district-' || d.n,
       'X0047',
       'ocd-division/country:us/state:ca/county:santa_clara/council_district:' || d.n,
       1,
       'residency',
       g.id,
       'https://d' || d.n || '.santaclaracounty.gov/home',
       CURRENT_DATE
  FROM (VALUES ('1'),('2'),('3'),('4'),('5')) AS d(n)
 CROSS JOIN essentials.governments g
 WHERE g.geo_id = '06085' AND g.type = 'County'
   AND NOT EXISTS (
     SELECT 1 FROM essentials.districts x
      WHERE x.geo_id = 'santa-clara-ca-supervisor-district-' || d.n
        AND x.mtfcc = 'X0047');

-- ── 3. The five offices ─────────────────────────────────────────────────────────────────
INSERT INTO essentials.offices
  (chamber_id, district_id, title, seats, partisan_type, voting_powers, is_vacant, description)
SELECT c.id, d.id,
       'Supervisor, District ' || right(d.geo_id, 1),
       1,
       'nonpartisan',   -- the Registrar prints "(nonpartisan)" on every county office page
       'full',
       false,
       'Member of the Santa Clara County Board of Supervisors, elected from a single-member supervisorial district to a 4-year term with a 3-term limit.'
  FROM essentials.districts d
  JOIN essentials.governments g ON g.id = d.government_id
  JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Board of Supervisors'
 WHERE d.mtfcc = 'X0047'
   AND NOT EXISTS (
     SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id);

-- ── 4. The five people ──────────────────────────────────────────────────────────────────
-- ⚠ Guarded on external_id, which is the natural key here. Names are NOT the key: forty-odd
--   Cal-Access committee rows contain these surnames and none of them is the person.
INSERT INTO essentials.politicians
  (full_name, first_name, last_name, external_id, is_active, is_incumbent, data_source)
SELECT v.full_name, v.first_name, v.last_name, v.external_id, true, true,
       'sccgov-elected-officials + scc-registrar-county-offices-2026-09-03 (Knight CA-2)'
  FROM (VALUES
      ('Sylvia Arenas',     'Sylvia',   'Arenas',   -6085011),
      ('Betty Duong',       'Betty',    'Duong',    -6085012),
      ('Otto Lee',          'Otto',     'Lee',      -6085013),
      ('Susan Ellenberg',   'Susan',    'Ellenberg',-6085014),
      ('Margaret Abe-Koga', 'Margaret', 'Abe-Koga', -6085015)
  ) AS v(full_name, first_name, last_name, external_id)
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);

-- ── 5. The five terms ───────────────────────────────────────────────────────────────────
-- Uses essentials.seat_officeholder rather than hand-rolling the two-step (CLAUDE.md). It is
-- idempotent, and it closes a predecessor's open-ended term — there is none here, since these
-- offices are new.
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('1', -6085011, DATE '2023-01-01', 'year',
       'scc-registrar-board-supervisors-district-1-2026-09-03 (roster + "Term Begins: First Monday after January 1 at Noon", 4-year term, next election 2026). ⚠ YEAR PRECISION: the 2022 election year is derived from the Registrar''s own cycle, not stated by any source read; no certified result was reached. The day the rule computes (2023-01-02) is deliberately NOT written.'),
      ('2', -6085012, DATE '2025-01-06', 'day',
       'scc-registrar-board-supervisors-district-2-2026-09-03 + directly sourced succession: took office 2025-01-06, the day Cindy Chavez''s term ended. The Registrar''s rule ("First Monday after January 1 at Noon") computes the same date for 2025.'),
      ('3', -6085013, DATE '2021-01-04', 'day',
       'scc-registrar-board-supervisors-district-3-2026-09-03 + directly sourced: "assumed office January 4, 2021", which is exactly what the Registrar''s rule computes for 2021.'),
      ('4', -6085014, DATE '2019-01-01', 'year',
       'scc-registrar-board-supervisors-district-4-2026-09-03 (roster + commencement rule, next election 2026). ⚠ YEAR PRECISION: the 2018 first-election year rests on cycle arithmetic. Chased and NOT confirmed on 2026-09-03 — the Registrar publishes no assumed-office date, and d4.santaclaracounty.gov carries no tenure prose on its home or Bio page. The day the rule computes (2019-01-07) is deliberately NOT written.'),
      ('5', -6085015, DATE '2025-01-06', 'day',
       'scc-registrar-board-supervisors-district-5-2026-09-03 + directly sourced succession: took office 2025-01-06, succeeding Joe Simitian. The Registrar''s rule computes the same date for 2025.')
    ) AS t(dist, ext_id, term_start, prec, source)
  LOOP
    PERFORM essentials.seat_officeholder(
      (SELECT o.id
         FROM essentials.offices o
         JOIN essentials.districts d ON d.id = o.district_id
        WHERE d.mtfcc = 'X0047' AND d.geo_id = 'santa-clara-ca-supervisor-district-' || r.dist),
      (SELECT p.id FROM essentials.politicians p WHERE p.external_id = r.ext_id),
      r.term_start,
      r.source,
      'elected',
      r.prec,
      NULL
    );
  END LOOP;
END $$;

-- ── POST-VERIFY ─────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n    integer;
  v_bad  text;
BEGIN
  -- 1. One chamber, five districts, five offices, five seated, none vacant.
  SELECT count(*) INTO v_n FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '06085' AND c.name = 'Board of Supervisors';
  IF v_n <> 1 THEN RAISE EXCEPTION 'scc supervisors: expected 1 chamber, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.districts WHERE mtfcc = 'X0047';
  IF v_n <> 5 THEN RAISE EXCEPTION 'scc supervisors: expected 5 districts, found %', v_n; END IF;

  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0047';
  IF v_n <> 5 THEN RAISE EXCEPTION 'scc supervisors: expected 5 offices, found %', v_n; END IF;

  -- ⚠ COUNT THE HOLDER, NOT THE ROW. office_current_holder LEFT JOINs from offices, so a
  --   vacancy is a NULL politician_id rather than an absent row, and count(*) passes
  --   vacuously.
  SELECT count(och.politician_id) INTO v_n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.mtfcc = 'X0047';
  IF v_n <> 5 THEN RAISE EXCEPTION 'scc supervisors: expected 5 seated holders, found %', v_n; END IF;

  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0047' AND o.is_vacant;
  IF v_n <> 0 THEN RAISE EXCEPTION 'scc supervisors: % office(s) flagged vacant, expected 0', v_n; END IF;

  -- 2. The right person in the right seat, with the right precision. This is the roster
  --    assertion: it fails if the wave is re-run after a January 2027 turnover.
  SELECT string_agg(d.label || ' = ' || coalesce(p.full_name, '(vacant)') ||
                    ' @ ' || coalesce(ot.term_start::text, 'NULL') ||
                    '/' || ot.start_precision, '; ' ORDER BY d.geo_id)
    INTO v_bad
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_terms ot ON ot.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE d.mtfcc = 'X0047'
     AND (d.geo_id, coalesce(p.full_name,''), coalesce(ot.term_start::text,''), ot.start_precision) NOT IN (
       ('santa-clara-ca-supervisor-district-1','Sylvia Arenas',    '2023-01-01','year'),
       ('santa-clara-ca-supervisor-district-2','Betty Duong',      '2025-01-06','day'),
       ('santa-clara-ca-supervisor-district-3','Otto Lee',         '2021-01-04','day'),
       ('santa-clara-ca-supervisor-district-4','Susan Ellenberg',  '2019-01-01','year'),
       ('santa-clara-ca-supervisor-district-5','Margaret Abe-Koga','2025-01-06','day'));
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'scc supervisors: seat/date mismatch -- %. D1 and D4 turn over in January 2027; re-run the change-check in backend/data/seed-santa-clara-2026/ROSTERS.md before changing this list.', v_bad;
  END IF;

  -- 3. No term_end on any of the five. A future term_end makes a seat silently self-vacate
  --    on the day it arrives, and five of the county's eight seats turn over in Jan 2027.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0047' AND ot.term_end IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION 'scc supervisors: % term row(s) carry a term_end; none should', v_n; END IF;

  -- 4. EVERY DISTRICT RESOLVES FROM ITS OWN POLYGON, AND RESOLVES TO EXACTLY ONE SEAT.
  --    This is the only detector that is end-to-end: it is the Long Beach failure inverted,
  --    where nine districts shared one polygon and every address returned all nine.
  --    ⚠ Pair geo_id with mtfcc AND district_type. A bare geo_id join is what returned
  --      officials from other counties in Florida.
  SELECT string_agg(t.geo_id || ' -> ' || t.hits::text, '; ' ORDER BY t.geo_id) INTO v_bad
    FROM (
      SELECT gb.geo_id, count(*) AS hits
        FROM essentials.geofence_boundaries gb
        JOIN essentials.districts d
          ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc AND d.district_type = 'COUNTY'
        JOIN essentials.offices o ON o.district_id = d.id
        JOIN essentials.geofence_boundaries probe
          ON probe.mtfcc = 'X0047'
         AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(probe.geometry))
       WHERE gb.mtfcc = 'X0047'
       GROUP BY gb.geo_id
    ) t
   WHERE t.hits <> 1;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'scc supervisors: a district interior point resolves to the wrong number of supervisor seats -- %', v_bad;
  END IF;

  RAISE NOTICE 'scc supervisors: 1 chamber, 5 districts, 5 offices, 5 seated, 0 vacant; 3 day-precision starts and 2 year-precision (Arenas D1, Ellenberg D4); every district interior point resolves to exactly one supervisor';
END $$;

COMMIT;
