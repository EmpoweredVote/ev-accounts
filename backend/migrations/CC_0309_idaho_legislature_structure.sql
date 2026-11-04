-- CC_0309_idaho_legislature_structure.sql
-- Idaho Legislature — structure only: two chambers and 105 offices.
-- Occupancy is CC_0310. Portraits are CC_0314.
--
-- Roster, sources, structural rulings and source defects:
--   backend/data/seed-id-legislature-2026/ROSTERS.md
--
-- ═══ 🔴 THE HOUSE IS MULTI-MEMBER: 35 POLYGONS, 70 SEATS ═══
--
-- Idaho Const. Art. III §2 and §4: each of the 35 legislative districts elects ONE senator and
-- TWO representatives, and the two representatives are chosen for SEPARATE SEATS — "Seat A" and
-- "Seat B" — over the SAME boundary. This is the Arizona/Washington shape.
--
--   essentials.districts G5210 for Idaho: 35 rows  -> 35 Senate offices   (1 per district)
--   essentials.districts G5220 for Idaho: 35 rows  -> 70 House offices    (2 per district)
--
-- 🔴 SO THE SLDL POLYGON COUNT IS NOT THE HOUSE SEAT COUNT. A seeder that writes one office per
--    G5220 row builds 35 of 70 seats; the other 35 members have nowhere to sit, address search
--    quietly returns one representative where Idaho law gives a voter two, and NOTHING ERRORS.
--    The post-verify gate below asserts 70 as 35 x 2 rather than as a bare total, so the
--    arithmetic is visible in the failure message rather than looking arbitrary.
--
-- 🔴 THE TWO SEATS ARE DISTINGUISHED BY OFFICE TITLE, NEVER BY DISTRICT CODE. Idaho has no
--    lettered district codes — there is no '16A'. Both seats hang on the SAME district row, and
--    `offices.title` is the only thing separating them. The TIGER loader's ID pre-flight asserts
--    the absence of lettered codes, so a future TIGER that split them would abort rather than
--    load silently; the pre-flight below asserts the same absence against what actually landed.
--
-- ⚠ G5210 AND G5220 SHARE A geo_id IN IDAHO. Senate District 19 and House District 19 are BOTH
--   geo_id '16019'. Every predicate below pairs geo_id/mtfcc with district_type and filters on
--   lower(state) = 'id' — `essentials.districts.state` is mixed case.
--
-- ═══ PARTY IS NOT WRITTEN ═══
--
-- These are partisan offices and the Legislature's roster prints a party letter for all 105, but
-- `politicians.party` stays NULL — party lives on `races.primary_party`. That is what MN, SC, FL
-- and HI carry for their legislators. `offices.partisan_type` records that the contest is
-- partisan. CC_0310's gate asserts no Idaho legislator carries a party.
--
-- ⚠ The five EXISTING Idaho statewide rows (Governor, Lt. Governor, Secretary of State, Attorney
--   General, Treasurer) DO carry 'Republican'. They predate this convention. They are deliberately
--   NOT touched here — rewriting them is its own decision with its own migration.
--
-- ═══ ⚠ WHAT THIS MIGRATION DELIBERATELY DOES NOT WRITE ═══
--
--  1. NO `term_end`. A future term_end makes a seat silently self-vacate.
--  2. NO occupancy. An office with no `office_terms` row is INVISIBLE — no holder, so the member
--     never appears anywhere and nothing errors. That is why CC_0310 ships in the same session.
--  3. NO geography. The 70 district rows were loaded by
--     `scripts/load-state-tiger-boundaries.ts --state ID --fips 16 --layers sldu,sldl,place`,
--     whose ID pre-flight proved the vintage is the adopted 2021 L03 plan and not the superseded
--     2011 L87 plan. A count cannot tell those apart — both are 35/35 — so only the six
--     discriminating anchors can, and `--vintage 2020` was run as a live control and failed
--     correctly with "THIS FILE IS THE SUPERSEDED 2011 L87 PLAN".

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_gov int; v_sldu int; v_sldl int; v_ch int; v_lettered int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE name = 'State of Idaho' AND geo_id = '16' AND mtfcc = 'G4000';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'CC_0309 pre-flight: expected exactly 1 "State of Idaho" government on 16/G4000, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_sldu FROM essentials.districts
   WHERE mtfcc = 'G5210' AND district_type = 'STATE_UPPER' AND lower(state) = 'id';
  IF v_sldu <> 35 THEN
    RAISE EXCEPTION 'CC_0309 pre-flight: expected 35 Idaho G5210 districts, found % — run '
                    'load-state-tiger-boundaries.ts --state ID --fips 16 --layers sldu,sldl,place first', v_sldu;
  END IF;

  SELECT count(*) INTO v_sldl FROM essentials.districts
   WHERE mtfcc = 'G5220' AND district_type = 'STATE_LOWER' AND lower(state) = 'id';
  IF v_sldl <> 35 THEN
    RAISE EXCEPTION 'CC_0309 pre-flight: expected 35 Idaho G5220 districts (NOT 70 — the House is '
                    'multi-member and its two seats share one boundary), found %', v_sldl;
  END IF;

  -- Asserted as an ABSENCE: a lettered code would mean TIGER had begun modelling Seat A and
  -- Seat B as separate geography, which changes how this whole slice must be seeded.
  SELECT count(*) INTO v_lettered FROM essentials.districts
   WHERE mtfcc IN ('G5210','G5220') AND lower(state) = 'id' AND geo_id ~ '[A-Za-z]';
  IF v_lettered <> 0 THEN
    RAISE EXCEPTION 'CC_0309 pre-flight: % Idaho legislative district(s) carry a lettered geo_id. '
                    'Idaho does not split districts; stop and re-measure the slice', v_lettered;
  END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Idaho' AND c.name IN ('Idaho Senate', 'Idaho House of Representatives');
  IF v_ch <> 0 THEN
    RAISE EXCEPTION 'CC_0309 pre-flight: % Idaho legislative chamber(s) already exist — this is '
                    'meant to be a greenfield seed, so read them before going further', v_ch;
  END IF;
END $$;

-- ── Chambers ──────────────────────────────────────────────────────────────────
-- 🔴 `chambers.slug` is GENERATED ALWAYS from `name_formal`, NOT from `name`. Leaving
--    name_formal NULL silently generates an EMPTY slug, and the slug is what the app routes on.
INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term,
   election_method, election_rules, inauguration_rules, vacancy_rules, website_url)
SELECT g.id, v.name, v.name, v.n, '2', false, 'partisan', v.rules, v.inaug, v.vac, v.url
FROM essentials.governments g
JOIN (VALUES
  ('Idaho Senate', 35::bigint,
   'Partisan. Two-year terms, so ALL 35 seats are on the ballot at every even-year general '
   || 'election. One senator per legislative district.',
   'A term runs for two years "from and after the first day of December next following the '
   || 'general election" (Idaho Const. Art. III sec. 3). Terms therefore begin on DECEMBER 1, '
   || 'not in January.',
   'A vacancy is filled by gubernatorial appointment from three names submitted by the departing '
   || 'member''s district central committee (Idaho Code sec. 59-904A), never by special election.',
   'https://legislature.idaho.gov/senate/membership/'),
  ('Idaho House of Representatives', 70::bigint,
   'Partisan. Two-year terms, so ALL 70 seats are on the ballot at every even-year general '
   || 'election. TWO representatives per legislative district, elected to SEPARATE SEATS — '
   || 'Seat A and Seat B — over the same boundary, each in its own head-to-head contest. There '
   || 'are therefore 35 House district polygons and 70 House seats.',
   'A term runs for two years "from and after the first day of December next following the '
   || 'general election" (Idaho Const. Art. III sec. 3). Terms therefore begin on DECEMBER 1, '
   || 'not in January.',
   'A vacancy is filled by gubernatorial appointment from three names submitted by the departing '
   || 'member''s district central committee (Idaho Code sec. 59-904A), never by special election.',
   'https://legislature.idaho.gov/house/membership/')
) AS v(name, n, rules, inaug, vac, url) ON true
WHERE g.name = 'State of Idaho'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ── Offices ───────────────────────────────────────────────────────────────────
-- The title is the bare role and the district comes from districts.label — the convention MN,
-- SC, FL, MS and HI all carry. The House is the exception that needs more than the bare role,
-- because two offices sit on ONE district row and the title is all that separates them.
--
-- Senate: 35 offices, one per G5210 district.
INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers, partisan_type)
SELECT c.id, d.id, 'Senator', 'ID', 1, false, 'full', 'partisan'
FROM essentials.districts d
JOIN essentials.governments g ON g.name = 'State of Idaho'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Idaho Senate'
WHERE d.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER' AND lower(d.state) = 'id'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
     WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = 'Senator');

-- House: 70 offices, TWO per G5220 district. The cross join against (A, B) is what doubles them.
INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers,
   partisan_type, description)
SELECT c.id, d.id, 'Representative, Seat ' || s.seat, 'ID', 1, false, 'full', 'partisan',
       'One of two representatives elected from this legislative district. Idaho elects its two '
       || 'House members per district to separate seats, Seat A and Seat B, each in its own '
       || 'head-to-head contest over the same boundary.'
FROM essentials.districts d
CROSS JOIN (VALUES ('A'), ('B')) AS s(seat)
JOIN essentials.governments g ON g.name = 'State of Idaho'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Idaho House of Representatives'
WHERE d.mtfcc = 'G5220' AND d.district_type = 'STATE_LOWER' AND lower(d.state) = 'id'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
     WHERE o.district_id = d.id AND o.chamber_id = c.id
       AND o.title = 'Representative, Seat ' || s.seat);

-- ── Post-verify gate ──────────────────────────────────────────────────────────
DO $$
DECLARE
  v_ch int; v_slug int; v_sen int; v_sen_d int; v_hse int; v_hse_d int; v_a int; v_b int;
  v_nogeom int; v_dupe int;
BEGIN
  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Idaho' AND c.name IN ('Idaho Senate','Idaho House of Representatives');
  IF v_ch <> 2 THEN RAISE EXCEPTION 'CC_0309 gate: expected 2 chambers, found %', v_ch; END IF;

  SELECT count(*) INTO v_slug FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Idaho' AND c.name IN ('Idaho Senate','Idaho House of Representatives')
     AND coalesce(btrim(c.slug),'') = '';
  IF v_slug <> 0 THEN
    RAISE EXCEPTION 'CC_0309 gate: % Idaho chamber(s) generated an EMPTY slug — name_formal was not set', v_slug;
  END IF;

  SELECT count(*), count(DISTINCT o.district_id) INTO v_sen, v_sen_d
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Idaho' AND c.name = 'Idaho Senate';
  IF v_sen <> 35 OR v_sen_d <> 35 THEN
    RAISE EXCEPTION 'CC_0309 gate: Senate must be 35 districts x 1 seat = 35 offices; found % offices over % districts',
                    v_sen, v_sen_d;
  END IF;

  -- 🔴 Asserted as 35 districts x 2 seats, not as a bare 70, so the multi-member arithmetic is
  --    visible in the failure message rather than hidden behind a total that looks arbitrary.
  SELECT count(*), count(DISTINCT o.district_id),
         count(*) FILTER (WHERE o.title = 'Representative, Seat A'),
         count(*) FILTER (WHERE o.title = 'Representative, Seat B')
    INTO v_hse, v_hse_d, v_a, v_b
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Idaho' AND c.name = 'Idaho House of Representatives';
  IF v_hse_d <> 35 OR v_a <> 35 OR v_b <> 35 OR v_hse <> 70 THEN
    RAISE EXCEPTION 'CC_0309 gate: House must be 35 districts x (Seat A + Seat B) = 70 offices; '
                    'found % districts, % Seat A, % Seat B, % offices total', v_hse_d, v_a, v_b, v_hse;
  END IF;

  -- An office on a district with no polygon is unreachable by any address and nothing errors.
  SELECT count(*) INTO v_nogeom FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'State of Idaho' AND c.name IN ('Idaho Senate','Idaho House of Representatives')
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'CC_0309 gate: % Idaho legislative office(s) sit on a district with no polygon '
                    'and are unreachable by address', v_nogeom;
  END IF;

  -- No district may carry two offices of the SAME title — that would be a duplicated seat.
  SELECT count(*) INTO v_dupe FROM (
    SELECT o.district_id, o.title FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'State of Idaho' AND c.name IN ('Idaho Senate','Idaho House of Representatives')
     GROUP BY o.district_id, o.title HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'CC_0309 gate: % (district, title) pair(s) are duplicated', v_dupe;
  END IF;

  RAISE NOTICE 'CC_0309 OK: 2 chambers, 35 Senate + 70 House (35 districts x Seat A/B) = 105 offices, 0 without geometry.';
END $$;
