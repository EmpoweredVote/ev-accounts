-- CC_0312_boise_id_structure_and_seating.sql
-- City of Boise, Idaho — full greenfield seed: government, two chambers, six council districts,
-- seven offices, seven officeholders.
--
-- Roster, sources, charter rulings and source defects:
--   backend/data/seed-boise-2026/ROSTERS.md
--
-- ═══ SEVEN SEATS IS THE WHOLE ELECTED CITY GOVERNMENT ═══
--
-- A Mayor elected citywide and six council members elected by single-member district. Boise
-- elects nobody else — there is no elected clerk, attorney, treasurer or auditor. Idaho Const.
-- Art. XVIII §6 reserves the elected row offices (sheriff, assessor, coroner, treasurer, clerk)
-- to the COUNTY, which is CC_0313's business, not the city's.
--
-- ═══ 🔴 THE CITY KEYS ON THE PLACE CODE, AND ITS TIGER NAME IS "BOISE CITY" ═══
--
--   geo_id '1608830', mtfcc 'G4110'
--
-- ⚠ TIGER's BASENAME for this polygon is "Boise City", not "Boise" — the city's legal name is
--   *City of Boise City*. A name search for 'Boise' alone is a false-absence trap. Every
--   predicate below matches the GEOID.
--
-- ═══ 🔴 BOISE PUBLISHES TWO COUNCIL-DISTRICT MAPS AND THE SUPERSEDED ONE IS EASIER TO FIND ═══
--
-- The six X0083 polygons are loaded first by `scripts/load-idaho-local-districts.mjs` from
-- `BoiseCityCouncilDistricts` — the layer behind the city's own published Zone Lookup app, i.e.
-- the operative 2023 redraw. An ArcGIS Hub search returns `Boise_City_Council_Districts_2021`
-- first; that is Boise's FIRST districting plan, used only for the 2021 election.
--
-- 🔴 NO CHEAP CHECK TELLS THEM APART. Both have 6 districts numbered 1..6; their geodesic areas
--    are 225.8 and 227.4 km², both matching Boise's ~87 sq mi; both correctly exclude Garden
--    City, Meridian and Eagle; and City Hall, Boise State and the airport resolve IDENTICALLY
--    under both. They disagree about where people live — the North End moves 3→6, Bown Crossing
--    4→5, Collister 3→6 — so loading the wrong one mis-assigns real addresses to the wrong
--    council member while every count and area check stays green.
--
-- This migration REFUSES TO RUN without the six polygons: an office on a district with no
-- polygon is unreachable by any address and NOTHING ERRORS.
--
-- ═══ 🔴 THE COUNCIL LANDING PAGE CARRIES TWO LEGACY AT-LARGE SEAT NUMBERS ═══
--
-- Colin Nash's card is headed "Council Seat 5" while its body reads "Council District 2", and
-- Jimmy Hallyburton's is headed "Council Seat 3" while its body reads "Council District 6".
-- Those headings are the at-large seats they held BEFORE Boise districted. A parser keying on
-- the heading seats Nash in District 5 — which is Meredith Stead's — and Hallyburton in
-- District 3, which is Kathy Corless's: two double-seated districts, two empty ones, and every
-- name a real Boise council member.
--
-- ▶ The district assignments below are overruled by FOUR independent signals that all agree:
--   the city's per-district page URLs, those pages' body text, Ballotpedia's officeholder table,
--   and the `CouncilMember` attribute on the city's own GIS layer (which the loader re-reads and
--   fails on if it has moved).
--
-- ═══ 🔴 "SERVING SINCE YYYY" ON THE CITY SITE MEANS THREE DIFFERENT THINGS ═══
--
-- Measured against Ballotpedia: for Willits, Corless and Morales it is the seating year; for
-- Nash and Stead it is the ELECTION year (2023) for a seat they took in January 2024; and for
-- Hallyburton it is 2020, which is his prior AT-LARGE service — a different office from
-- District 6. It is therefore not usable for `term_start`, and is not used.
--
-- `office_terms.term_start` is the start of CONTINUOUS OCCUPANCY of THIS office. All six
-- district seats were on the 2023 ballot and began 2024-01-09; Luci Willits alone runs from
-- 2022-01-11, having won District 1 in 2021 and been re-elected in 2023 without a break. Nash,
-- Morales and Hallyburton were re-elected on 2025-11-04 — re-election does not end an
-- occupancy, so their dates do not move.
--
-- ═══ ⚠ WHAT THIS MIGRATION DELIBERATELY DOES NOT WRITE ═══
--
--  1. NO `term_end`. A future term_end makes a seat silently self-vacate.
--  2. NO party. Boise's municipal elections are NONPARTISAN; `offices.partisan_type` records
--     that and `politicians.party` stays NULL. The gate asserts it.
--  3. NO 2027 terms. The Mayor and districts 1, 3 and 5 are next on the ballot in November 2027.
--     Nothing in this file is affected by the 2026-11-03 general election.

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_poly int; v_stray int; v_place int; v_gov int; v_people int;
BEGIN
  SELECT count(*) INTO v_poly FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0083' AND geo_id LIKE 'boise-id-council-district-%';
  IF v_poly <> 6 THEN
    RAISE EXCEPTION 'CC_0312 pre-flight: expected 6 X0083 Boise council polygons, found % — run '
                    'scripts/load-idaho-local-districts.mjs first. An office on a district with no '
                    'polygon is unreachable by any address and nothing errors.', v_poly;
  END IF;

  SELECT count(*) INTO v_stray FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0083' AND geo_id NOT LIKE 'boise-id-council-district-%';
  IF v_stray <> 0 THEN
    RAISE EXCEPTION 'CC_0312 pre-flight: % X0083 polygon(s) are not Boise council districts — '
                    'somebody else took this code', v_stray;
  END IF;

  -- (geo_id, mtfcc, state): geo_id alone is not a key anywhere in this database.
  SELECT count(*) INTO v_place FROM essentials.geofence_boundaries
   WHERE geo_id = '1608830' AND mtfcc = 'G4110' AND state = '16';
  IF v_place <> 1 THEN
    RAISE EXCEPTION 'CC_0312 pre-flight: expected the TIGER place polygon 1608830/G4110 in state 16 '
                    'for the citywide Mayor, found %', v_place;
  END IF;

  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE geo_id = '1608830' OR (name ILIKE '%boise%' AND type <> 'STATE');
  IF v_gov <> 0 THEN
    RAISE EXCEPTION 'CC_0312 pre-flight: % government row(s) already mention Boise — this is meant '
                    'to be a greenfield seed, so read them before going further', v_gov;
  END IF;

  SELECT count(*) INTO v_people FROM essentials.politicians p
   WHERE p.is_active AND (lower(btrim(p.last_name)), lower(btrim(p.first_name))) IN (
     ('mclean','lauren'), ('willits','luci'), ('nash','colin'),
     ('corless','kathy'), ('morales','jordan'), ('stead','meredith'), ('hallyburton','jimmy'));
  IF v_people <> 0 THEN
    RAISE EXCEPTION 'CC_0312 pre-flight: % active politician(s) already match a Boise official on '
                    'first+last name — re-read the identity scan in ROSTERS.md', v_people;
  END IF;
END $$;

-- ── Government ────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT 'City of Boise, Idaho, US', 'City', 'ID', 'Boise', '1608830', 'G4110'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'City of Boise, Idaho, US');

-- ── Chambers ──────────────────────────────────────────────────────────────────
-- 🔴 `chambers.slug` is GENERATED ALWAYS from `name_formal`, NOT from `name`. Leaving
--    name_formal NULL silently generates an EMPTY slug, and the slug is what the app routes on.
INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term,
   election_method, election_rules, inauguration_rules, website_url)
SELECT g.id, v.name, v.name, v.n, '4', v.stag, 'nonpartisan', v.rules, v.inaug, v.url
FROM essentials.governments g
JOIN (VALUES
  ('Boise City Council', 6::bigint, true,
   'Nonpartisan, six single-member districts. Idaho law has required cities over 100,000 '
   || 'residents to elect council members by district since 2020; Boise first did so in 2021. '
   || 'All six districts were on the 2023 ballot, where the ODD-numbered districts drew '
   || 'four-year terms and the EVEN-numbered ones two-year terms — that is what staggered them. '
   || 'Districts 2, 4 and 6 next ran on 2025-11-04 and run again in 2029; districts 1, 3 and 5 '
   || 'run in November 2027.',
   'Members take office in January following their election; the 2023-elected members were '
   || 'seated on 2024-01-09.',
   'https://www.cityofboise.org/departments/city-council/'),
  ('Office of the Mayor', 1::bigint, false,
   'Nonpartisan, elected citywide to a four-year term. Next on the ballot in November 2027.',
   'Takes office in January following the election; Mayor McLean was seated on 2020-01-07.',
   'https://www.cityofboise.org/departments/mayor/')
) AS v(name, n, stag, rules, inaug, url) ON true
WHERE g.name = 'City of Boise, Idaho, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ── Districts ─────────────────────────────────────────────────────────────────
-- Six council districts on the X0083 polygons. The Mayor hangs on the existing TIGER place row.
CREATE TEMP TABLE boi_districts(geo_id text, label text, num int) ON COMMIT DROP;
INSERT INTO boi_districts(geo_id, label, num) VALUES
  ('boise-id-council-district-1', 'Boise City Council District 1', 1),
  ('boise-id-council-district-2', 'Boise City Council District 2', 2),
  ('boise-id-council-district-3', 'Boise City Council District 3', 3),
  ('boise-id-council-district-4', 'Boise City Council District 4', 4),
  ('boise-id-council-district-5', 'Boise City Council District 5', 5),
  ('boise-id-council-district-6', 'Boise City Council District 6', 6);

INSERT INTO essentials.districts (geo_id, label, district_type, state, city, mtfcc, num_officials)
SELECT n.geo_id, n.label, 'LOCAL', 'id', 'Boise', 'X0083', 1
FROM boi_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
   WHERE d.geo_id = n.geo_id AND d.mtfcc = 'X0083' AND d.district_type = 'LOCAL');

-- The citywide district for the Mayor, on the TIGER place code.
INSERT INTO essentials.districts (geo_id, label, district_type, state, city, mtfcc, num_officials)
SELECT '1608830', 'City of Boise', 'LOCAL', 'id', 'Boise', 'G4110', 1
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
   WHERE d.geo_id = '1608830' AND d.mtfcc = 'G4110' AND d.district_type = 'LOCAL');

-- ── Offices ───────────────────────────────────────────────────────────────────
CREATE TEMP TABLE boi_offices(geo_id text, mtfcc text, chamber_name text, title text, descr text)
  ON COMMIT DROP;
INSERT INTO boi_offices(geo_id, mtfcc, chamber_name, title, descr) VALUES
  ('boise-id-council-district-1','X0083','Boise City Council','Council Member, District 1', NULL),
  ('boise-id-council-district-2','X0083','Boise City Council','Council Member, District 2', NULL),
  ('boise-id-council-district-3','X0083','Boise City Council','Council Member, District 3', NULL),
  ('boise-id-council-district-4','X0083','Boise City Council','Council Member, District 4', NULL),
  ('boise-id-council-district-5','X0083','Boise City Council','Council Member, District 5', NULL),
  ('boise-id-council-district-6','X0083','Boise City Council','Council Member, District 6', NULL),
  ('1608830','G4110','Office of the Mayor','Mayor',
     'Chief executive of the City of Boise, elected citywide to a four-year term on a nonpartisan '
     || 'ballot. Boise is a strong-mayor city: the Mayor is not a member of the Council, presides '
     || 'over its meetings without a vote except to break a tie, may veto its ordinances, and '
     || 'appoints the city''s department directors.');

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant,
   voting_powers, partisan_type, description)
SELECT c.id, d.id, n.title, 'ID', 'Boise', 1, false, 'full', 'nonpartisan', n.descr
FROM boi_offices n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'LOCAL'
JOIN essentials.governments g ON g.name = 'City of Boise, Idaho, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = n.title);

-- ── People ────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE boi_roster(
  title       text PRIMARY KEY,
  full_name   text NOT NULL,
  first_name  text NOT NULL,
  last_name   text NOT NULL,
  term_start  date NOT NULL,
  precision   text NOT NULL,
  source      text NOT NULL,
  office_id     uuid,
  politician_id uuid
) ON COMMIT DROP;

INSERT INTO boi_roster(title, full_name, first_name, last_name, term_start, precision, source) VALUES
  ('Mayor', 'Lauren McLean', 'Lauren', 'McLean', DATE '2020-01-07', 'day',
   'cityofboise.org/departments/mayor/ and ballotpedia.org/Lauren_McLean, both read 2026-10-30 '
   || '(CC_0312): Ballotpedia states she "assumed office on January 7, 2020". Next on the ballot in '
   || 'November 2027.'),
  ('Council Member, District 1', 'Luci Willits', 'Luci', 'Willits', DATE '2022-01-11', 'day',
   'cityofboise.org council-district-1 page and ballotpedia.org/Boise,_Idaho officeholder table, '
   || 'both read 2026-10-30 (CC_0312): Ballotpedia gives 11 January 2022 — she won District 1 at the '
   || '2021 election and was re-elected in 2023, so occupancy is continuous from 2022 and does not '
   || 'reset to the other five members'' 2024-01-09. The city page''s "Serving since 2022" agrees.'),
  ('Council Member, District 2', 'Colin Nash', 'Colin', 'Nash', DATE '2024-01-09', 'day',
   'cityofboise.org council-district-2 page, ballotpedia.org officeholder table and the city GIS '
   || 'layer''s CouncilMember attribute, all read 2026-10-30 (CC_0312), and all three say DISTRICT 2. '
   || 'The council landing page heads his card "Council Seat 5", which is the AT-LARGE seat he held '
   || 'before Boise districted and is not a district number. Assumed office 2024-01-09; re-elected '
   || '2025-11-04, which does not end the occupancy.'),
  ('Council Member, District 3', 'Kathy Corless', 'Kathy', 'Corless', DATE '2024-01-09', 'day',
   'cityofboise.org council-district-3 page and ballotpedia.org officeholder table, read 2026-10-30 '
   || '(CC_0312): assumed office 2024-01-09. Currently Council Pro Tem. Next on the ballot in 2027.'),
  ('Council Member, District 4', 'Jordan Morales', 'Jordan', 'Morales', DATE '2024-01-09', 'day',
   'cityofboise.org council-district-4 page and ballotpedia.org officeholder table, read 2026-10-30 '
   || '(CC_0312): assumed office 2024-01-09. Re-elected 2025-11-04.'),
  ('Council Member, District 5', 'Meredith Stead', 'Meredith', 'Stead', DATE '2024-01-09', 'day',
   'cityofboise.org council-district-5 page and ballotpedia.org officeholder table, read 2026-10-30 '
   || '(CC_0312): assumed office 2024-01-09. Currently Council President. Boise City Hall itself sits '
   || 'in District 5 — verified by point-in-polygon against the city''s own operative GIS layer.'),
  ('Council Member, District 6', 'Jimmy Hallyburton', 'Jimmy', 'Hallyburton', DATE '2024-01-09', 'day',
   'cityofboise.org council-district-6 page, ballotpedia.org officeholder table and the city GIS '
   || 'layer''s CouncilMember attribute, all read 2026-10-30 (CC_0312), and all three say DISTRICT 6. '
   || 'The council landing page heads his card "Council Seat 3" and says "Serving since 2020"; both '
   || 'refer to his prior AT-LARGE seat, which is a different office from District 6. His occupancy '
   || 'of District 6 starts 2024-01-09. Re-elected 2025-11-04.');

UPDATE boi_roster r SET office_id = o.id
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
 WHERE g.name = 'City of Boise, Idaho, US' AND o.title = r.title;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM boi_roster WHERE office_id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0312: % roster row(s) did not resolve to a Boise office', n; END IF;
  SELECT count(*) INTO n FROM boi_roster r
   WHERE EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = r.office_id);
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0312: % Boise office(s) already carry a term', n; END IF;
END $$;

-- 🔴 is_incumbent EXPLICITLY true. It defaults to false, and a seated person inserted without it
--    is HIDDEN from address search; check:occupancy fails an INSERT that omits it.
--    party stays NULL: Boise's elections are nonpartisan.
INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, source)
SELECT r.full_name, r.first_name, r.last_name, true, true, r.source
  FROM boi_roster r
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
      AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
      AND p.is_active);

UPDATE boi_roster r SET politician_id = p.id
  FROM essentials.politicians p
 WHERE p.is_active
   AND lower(btrim(p.first_name)) = lower(btrim(r.first_name))
   AND lower(btrim(p.last_name))  = lower(btrim(r.last_name));

-- ── Seating ───────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; n int := 0;
BEGIN
  FOR r IN SELECT * FROM boi_roster ORDER BY title LOOP
    IF r.politician_id IS NULL THEN RAISE EXCEPTION 'CC_0312: % did not resolve to a person', r.title; END IF;
    INSERT INTO essentials.office_terms
      (office_id, politician_id, term_start, start_precision, how_started, source)
    VALUES (r.office_id, r.politician_id, r.term_start, r.precision, 'elected', r.source);
    n := n + 1;
  END LOOP;
  IF n <> 7 THEN RAISE EXCEPTION 'CC_0312: expected 7 seatings, got %', n; END IF;
END $$;

-- ── Post-verify gate ──────────────────────────────────────────────────────────
DO $$
DECLARE
  v_gov int; v_ch int; v_slug int; v_dist int; v_off int; v_council int; v_mayor int;
  v_held int; v_party int; v_notinc int; v_nogeom int; v_termend int; v_dupe int; v_d5 int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'City of Boise, Idaho, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'CC_0312 gate: expected 1 Boise government row, found %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Boise, Idaho, US';
  IF v_ch <> 2 THEN RAISE EXCEPTION 'CC_0312 gate: expected 2 chambers, found %', v_ch; END IF;

  SELECT count(*) INTO v_slug FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Boise, Idaho, US' AND coalesce(btrim(c.slug),'') = '';
  IF v_slug <> 0 THEN
    RAISE EXCEPTION 'CC_0312 gate: % Boise chamber(s) generated an EMPTY slug — name_formal was not set', v_slug;
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE mtfcc = 'X0083' AND district_type = 'LOCAL' AND lower(state) = 'id';
  IF v_dist <> 6 THEN RAISE EXCEPTION 'CC_0312 gate: expected 6 council districts, found %', v_dist; END IF;

  SELECT count(*),
         count(*) FILTER (WHERE c.name = 'Boise City Council'),
         count(*) FILTER (WHERE c.name = 'Office of the Mayor')
    INTO v_off, v_council, v_mayor
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Boise, Idaho, US';
  IF v_off <> 7 OR v_council <> 6 OR v_mayor <> 1 THEN
    RAISE EXCEPTION 'CC_0312 gate: expected 7 offices (6 council + 1 mayor), found % (% + %)', v_off, v_council, v_mayor;
  END IF;

  -- 🔴 count(och.politician_id), never count(*): office_current_holder LEFT JOINs from offices,
  --    so a vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_held
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Boise, Idaho, US';
  IF v_held <> 7 THEN RAISE EXCEPTION 'CC_0312 gate: expected 7 held offices, found %', v_held; END IF;

  -- 🔴 The defect this migration exists to survive: Stead must hold District 5, not Nash.
  --    If the card headings had been believed, District 5 would carry Colin Nash.
  SELECT count(*) INTO v_d5 FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.title = 'Council Member, District 5' AND p.full_name = 'Meredith Stead';
  IF v_d5 <> 1 THEN
    RAISE EXCEPTION 'CC_0312 gate: District 5 is not held by Meredith Stead (found %). The council '
                    'landing page heads Colin Nash''s card "Council Seat 5"; that is a legacy '
                    'at-large seat number, not a district.', v_d5;
  END IF;

  SELECT count(*) INTO v_party FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'City of Boise, Idaho, US' AND coalesce(btrim(p.party),'') <> '';
  IF v_party <> 0 THEN
    RAISE EXCEPTION 'CC_0312 gate: % Boise officeholder(s) carry a party — these are nonpartisan offices', v_party;
  END IF;

  SELECT count(*) INTO v_notinc FROM essentials.politicians
   WHERE source LIKE '%(CC_0312)%' AND (NOT is_incumbent OR NOT is_active);
  IF v_notinc <> 0 THEN
    RAISE EXCEPTION 'CC_0312 gate: % seated Boise official(s) are not active incumbents — they would '
                    'be HIDDEN from address search', v_notinc;
  END IF;

  SELECT count(*) INTO v_nogeom FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'City of Boise, Idaho, US'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'CC_0312 gate: % Boise office(s) sit on a district with no polygon and are '
                    'unreachable by address', v_nogeom;
  END IF;

  SELECT count(*) INTO v_termend FROM essentials.office_terms t
    JOIN boi_roster r ON r.office_id = t.office_id
   WHERE t.term_end IS NOT NULL;
  IF v_termend <> 0 THEN
    RAISE EXCEPTION 'CC_0312 gate: % Boise term(s) carry a term_end; a future term_end makes a seat '
                    'silently self-vacate', v_termend;
  END IF;

  SELECT count(*) INTO v_dupe FROM (
    SELECT och.politician_id FROM essentials.office_current_holder och
      JOIN essentials.offices o ON o.id = och.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'City of Boise, Idaho, US' AND och.politician_id IS NOT NULL
     GROUP BY och.politician_id HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'CC_0312 gate: % person(s) hold more than one Boise seat', v_dupe; END IF;

  RAISE NOTICE 'CC_0312 OK: Boise government, 2 chambers, 6 council districts, 7 offices, 7 held, District 5 = Meredith Stead.';
END $$;
