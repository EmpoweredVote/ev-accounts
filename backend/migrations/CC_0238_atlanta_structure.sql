-- CC_0238_atlanta_structure.sql
--
-- Atlanta full seed, stage 3, CITY STRUCTURE half.
--   * 1 government, 3 chambers
--   * 13 districts -- 12 council districts (X0077) + 1 citywide (TIGER place 1304000/G4110)
--   * 17 offices   -- 12 district + 3 at-large posts + Council President + Mayor
--
-- Roster: backend/data/seed-atlanta-2026/ROSTERS.md
-- Slice:  .planning/knight-foundation/ga.md
-- Boundaries: scripts/load-atlanta-council-districts.mjs MUST RUN FIRST (X0077).
--
-- Slot CC_0238 was RESERVED FROM THE ALLOCATOR before this file was named
-- (npm run steward --prefix backend -- slot CC). It was not counted.
--
-- ---------------------------------------------------------------------------
-- 🔴 ATLANTA IS NOT A KNIGHT JURISDICTION, BUT IT REUSES THE GEORGIA SLICE.
--
-- GA-1 (geography) and GA-2 (the 180+56 legislature) are already applied, so this wave is
-- stage 3+4+5 only. The citywide district keys on the TIGER place polygon that GA-1 loaded.
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 ATLANTA SPANS TWO COUNTIES. MEASURED, NOT ASSUMED.
--
-- PostGIS intersection against the Georgia county layer, 2026-10-17:
--   Fulton 13121  330.09 km²  93.45% of Atlanta
--   DeKalb 13089   23.14 km²   6.55% of Atlanta
--
-- The council-district layer carries BOTH halves -- proved by an address probe at 1660 Memorial
-- Dr SE (an Atlanta address in DeKalb, which resolves to District 5) and again, independently,
-- by the certified 2025 return, in which districts 1, 5, 6 and 7 drew DeKalb precincts.
-- CC_0240 and CC_0242 seat the two county boards so those addresses get four answers.
--
-- ---------------------------------------------------------------------------
-- 🔴 RULING: FIFTEEN COUNCILMEMBERS PLUS A SEPARATELY ELECTED PRESIDENT.
--
-- 12 single-member districts + 3 at-large Posts = 15 councilmembers. The Council President is
-- elected citywide as a SEPARATE office and is the presiding officer. The city's own Municipal
-- Clerk record ("2026 City of Atlanta Elected Officials") groups them exactly this way:
-- MAYOR, then COUNCIL PRESIDENT, then COUNCILMEMBERS (Posts 1-3 At Large and Districts 1-12).
--
-- So essentials.chambers.official_count for 'Atlanta City Council' is 15, not 16.
--
-- 🔴 RULING: THE COUNCIL PRESIDENT IS voting_powers 'non_voting', WITH A MANDATORY NOTE.
--
-- Atlanta Code of Ordinances § 2-36(b): "The council president shall vote only if a tie vote of
-- the council occurs." § 2-36(a) makes the president the presiding officer with "all the powers
-- ... normally incumbent upon a presiding officer".
--
-- That is Nashville's Vice Mayor ruling and Macon-Bibb's M2 in a third dress. ADR 0003 makes
-- representation_note MANDATORY whenever voting_powers <> 'full' (a CHECK), and the read path
-- must not render the seat without it.
--
-- ⚠ The MAYOR is 'full'. Atlanta is a strong-mayor city; the mayor does not sit on the council
--   at all, so there is no vote to qualify. This is Biloxi's shape, not Macon-Bibb's -- do not
--   copy the consolidated-government mayor here.
--
-- ---------------------------------------------------------------------------
-- 🔴 WHAT THIS MIGRATION DELIBERATELY DOES NOT CREATE
--
-- * The 9 elected ATLANTA MUNICIPAL COURT JUDGES. Excluded by operator ruling 2026-10-17 on two
--   grounds: the programme excludes judicial-branch offices (Ga. Const. Art. VI, as Georgia's
--   Chief Magistrate and Florida's county judges were), and the ONLY seat designation any source
--   publishes is the sitting judge's own surname -- the certified ballot reads "Atlanta Municipal
--   Court Judge (Baker)", "(Bey)", "(Gaines)" and so on. Seeding that repeats the open LASC
--   defect of 364 seats named after their holder. A SEAT MUST OUTLIVE ITS HOLDER.
-- * The 9-member ATLANTA BOARD OF EDUCATION. Spec §11, school boards are out of scope.
--
-- ---------------------------------------------------------------------------
-- Idempotent: every insert is guarded, a re-run writes 0 rows.
-- Dry-run against production by wrapping the body in BEGIN; ... ROLLBACK; and confirm the
-- rollback actually reverted before trusting it.

-- ─── Pre-flight ──────────────────────────────────────────────────────────────
-- 🔴 AN OFFICE ON A DISTRICT WITH NO POLYGON IS UNREACHABLE BY ANY ADDRESS, AND NOTHING ERRORS.
--    This is the one failure mode CI cannot catch, so it is caught here instead.

DO $$
DECLARE
  v_council int;
  v_dup     int;
  v_place   int;
BEGIN
  SELECT count(*) INTO v_council FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0077' AND state = '13' AND geo_id LIKE 'atlanta-ga-council-%';
  IF v_council <> 12 THEN
    RAISE EXCEPTION 'ATL-1 pre-flight: expected 12 X0077 Atlanta council polygons, found % — run scripts/load-atlanta-council-districts.mjs first. An office on a district with no polygon is unreachable by any address and nothing errors.', v_council;
  END IF;

  SELECT count(*) INTO v_dup FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0077' AND geo_id NOT LIKE 'atlanta-ga-council-%';
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'ATL-1 pre-flight: % X0077 polygon(s) are not Atlanta council districts — somebody else took this code', v_dup;
  END IF;

  SELECT count(*) INTO v_place FROM essentials.geofence_boundaries
   WHERE geo_id = '1304000' AND mtfcc = 'G4110' AND state = '13';
  IF v_place <> 1 THEN
    RAISE EXCEPTION 'ATL-1 pre-flight: expected the TIGER place polygon 1304000/G4110 for the citywide offices, found %', v_place;
  END IF;
END $$;

-- ─── 1. The government ───────────────────────────────────────────────────────
-- 🔴 geo_id AND mtfcc are BOTH set. The essentials landing chip is keyed on the PAIR
--    (CC_0187); geo_id alone collides across layers.

INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT 'City of Atlanta, Georgia, US', 'City', 'GA', 'Atlanta', '1304000', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Atlanta, Georgia, US');

-- ─── 2. Three chambers ───────────────────────────────────────────────────────
-- term_length FOUR years for all three. Atlanta's municipal elections run in odd years on a
-- four-year cycle, which the certified returns themselves establish: the SOS carries an Atlanta
-- Municipal General on 2021-11-02 and again on 2025-11-04, and the city's own inauguration page
-- records oaths on 2022-01-03 and 2026-01-05.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT g.id, v.name, v.name, v.official_count, '4'
FROM essentials.governments g
JOIN (VALUES
  ('Atlanta City Council',            15),
  ('Office of the Council President',  1),
  ('Office of the Mayor',              1)
) AS v(name, official_count) ON true
WHERE g.name = 'City of Atlanta, Georgia, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Thirteen districts — twelve council plus one citywide ────────────────
-- 🔴 The citywide row carries num_officials 5: three at-large Posts, the Council President and
--    the Mayor all represent the whole city. Macon-Bibb's citywide carries 1 and Columbus's
--    carries 3 — do not copy either.

CREATE TEMP TABLE atl_districts(geo_id text, label text, mtfcc text, num_officials bigint) ON COMMIT DROP;
INSERT INTO atl_districts(geo_id, label, mtfcc, num_officials) VALUES
  ('atlanta-ga-council-1',  'Atlanta City Council District 1',  'X0077', 1),
  ('atlanta-ga-council-2',  'Atlanta City Council District 2',  'X0077', 1),
  ('atlanta-ga-council-3',  'Atlanta City Council District 3',  'X0077', 1),
  ('atlanta-ga-council-4',  'Atlanta City Council District 4',  'X0077', 1),
  ('atlanta-ga-council-5',  'Atlanta City Council District 5',  'X0077', 1),
  ('atlanta-ga-council-6',  'Atlanta City Council District 6',  'X0077', 1),
  ('atlanta-ga-council-7',  'Atlanta City Council District 7',  'X0077', 1),
  ('atlanta-ga-council-8',  'Atlanta City Council District 8',  'X0077', 1),
  ('atlanta-ga-council-9',  'Atlanta City Council District 9',  'X0077', 1),
  ('atlanta-ga-council-10', 'Atlanta City Council District 10', 'X0077', 1),
  ('atlanta-ga-council-11', 'Atlanta City Council District 11', 'X0077', 1),
  ('atlanta-ga-council-12', 'Atlanta City Council District 12', 'X0077', 1),
  ('1304000',               'Atlanta Citywide',                 'G4110', 5);

INSERT INTO essentials.districts (geo_id, label, district_type, state, city, mtfcc, num_officials)
SELECT n.geo_id, n.label, 'LOCAL', 'ga', 'Atlanta', n.mtfcc, n.num_officials
FROM atl_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'LOCAL');

-- ─── 4. Seventeen offices ────────────────────────────────────────────────────
-- 🔴 Every join pairs geo_id WITH mtfcc. Georgia holds 1,159 geo_id collisions across 13 states
--    and '13089' alone is BOTH DeKalb County (G4020) and State House District 89 (G5220).

CREATE TEMP TABLE atl_offices(geo_id text, mtfcc text, chamber_name text, title text, voting_powers text, note text) ON COMMIT DROP;
INSERT INTO atl_offices(geo_id, mtfcc, chamber_name, title, voting_powers, note) VALUES
  ('atlanta-ga-council-1',  'X0077', 'Atlanta City Council', 'Council Member, District 1',  'full', NULL),
  ('atlanta-ga-council-2',  'X0077', 'Atlanta City Council', 'Council Member, District 2',  'full', NULL),
  ('atlanta-ga-council-3',  'X0077', 'Atlanta City Council', 'Council Member, District 3',  'full', NULL),
  ('atlanta-ga-council-4',  'X0077', 'Atlanta City Council', 'Council Member, District 4',  'full', NULL),
  ('atlanta-ga-council-5',  'X0077', 'Atlanta City Council', 'Council Member, District 5',  'full', NULL),
  ('atlanta-ga-council-6',  'X0077', 'Atlanta City Council', 'Council Member, District 6',  'full', NULL),
  ('atlanta-ga-council-7',  'X0077', 'Atlanta City Council', 'Council Member, District 7',  'full', NULL),
  ('atlanta-ga-council-8',  'X0077', 'Atlanta City Council', 'Council Member, District 8',  'full', NULL),
  ('atlanta-ga-council-9',  'X0077', 'Atlanta City Council', 'Council Member, District 9',  'full', NULL),
  ('atlanta-ga-council-10', 'X0077', 'Atlanta City Council', 'Council Member, District 10', 'full', NULL),
  ('atlanta-ga-council-11', 'X0077', 'Atlanta City Council', 'Council Member, District 11', 'full', NULL),
  ('atlanta-ga-council-12', 'X0077', 'Atlanta City Council', 'Council Member, District 12', 'full', NULL),
  ('1304000',               'G4110', 'Atlanta City Council', 'Council Member, Post 1 (At Large)', 'full', NULL),
  ('1304000',               'G4110', 'Atlanta City Council', 'Council Member, Post 2 (At Large)', 'full', NULL),
  ('1304000',               'G4110', 'Atlanta City Council', 'Council Member, Post 3 (At Large)', 'full', NULL),
  ('1304000',               'G4110', 'Office of the Council President', 'Council President', 'non_voting',
     'Elected citywide and presides over the Atlanta City Council. Atlanta Code of Ordinances § 2-36(b): "The council president shall vote only if a tie vote of the council occurs." § 2-36(a) gives the president "all the powers ... normally incumbent upon a presiding officer". The president is not one of the 15 councilmembers.'),
  ('1304000',               'G4110', 'Office of the Mayor', 'Mayor', 'full', NULL);

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers, representation_note)
SELECT c.id, d.id, n.title, 'GA', 'Atlanta', 1, false, n.voting_powers, n.note
FROM atl_offices n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'LOCAL' AND lower(d.state) = 'ga'
JOIN essentials.governments g ON g.name = 'City of Atlanta, Georgia, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = n.title);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov      int;
  v_ch       int;
  v_dist     int;
  v_off      int;
  v_district int;
  v_atlarge  int;
  v_pres     int;
  v_mayor    int;
  v_wrong    int;
  v_titles   int;
  v_vacant   int;
  v_nogeom   int;
  v_note     int;
  v_leg      int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'City of Atlanta, Georgia, US';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'ATL-1 gate: expected exactly 1 Atlanta government row, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US';
  IF v_ch <> 3 THEN
    RAISE EXCEPTION 'ATL-1 gate: expected 3 Atlanta chambers, found %', v_ch;
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts d
   WHERE d.district_type = 'LOCAL' AND lower(d.state) = 'ga'
     AND (d.mtfcc = 'X0077' OR (d.geo_id = '1304000' AND d.mtfcc = 'G4110'));
  IF v_dist <> 13 THEN
    RAISE EXCEPTION 'ATL-1 gate: expected 13 Atlanta LOCAL districts (12 council + 1 citywide), found %', v_dist;
  END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US';
  IF v_off <> 17 THEN
    RAISE EXCEPTION 'ATL-1 gate: expected 17 Atlanta offices, found %', v_off;
  END IF;

  -- The shape, not just the total: 12 district + 3 at-large + 1 president + 1 mayor.
  SELECT
    count(*) FILTER (WHERE o.title LIKE 'Council Member, District %'),
    count(*) FILTER (WHERE o.title LIKE 'Council Member, Post % (At Large)'),
    count(*) FILTER (WHERE o.title = 'Council President'),
    count(*) FILTER (WHERE o.title = 'Mayor')
    INTO v_district, v_atlarge, v_pres, v_mayor
  FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US';
  IF v_district <> 12 OR v_atlarge <> 3 OR v_pres <> 1 OR v_mayor <> 1 THEN
    RAISE EXCEPTION 'ATL-1 gate: expected 12 district / 3 at-large / 1 president / 1 mayor, found % / % / % / %',
      v_district, v_atlarge, v_pres, v_mayor;
  END IF;

  -- Each council district holds exactly one office.
  SELECT count(*) INTO v_wrong FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
   WHERE d.mtfcc = 'X0077' AND d.district_type = 'LOCAL' AND lower(d.state) = 'ga'
   GROUP BY d.id HAVING count(o.id) <> 1;
  IF v_wrong IS NOT NULL THEN
    RAISE EXCEPTION 'ATL-1 gate: at least one Atlanta council district does not hold exactly 1 office';
  END IF;

  SELECT count(DISTINCT o.title) INTO v_titles FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US';
  IF v_titles <> 17 THEN
    RAISE EXCEPTION 'ATL-1 gate: expected 17 DISTINCT Atlanta office titles, found % — a duplicate title would make two seats indistinguishable', v_titles;
  END IF;

  SELECT count(*) INTO v_vacant FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US' AND o.is_vacant;
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'ATL-1 gate: expected 0 vacant Atlanta offices, found %', v_vacant;
  END IF;

  -- 🔴 ADR 0003: representation_note is REQUIRED whenever voting_powers <> 'full', and the read
  --    path must not render such a seat without it.
  SELECT count(*) INTO v_note FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US'
     AND o.voting_powers <> 'full'
     AND (o.representation_note IS NULL OR btrim(o.representation_note) = '');
  IF v_note <> 0 THEN
    RAISE EXCEPTION 'ATL-1 gate: % Atlanta office(s) are not voting_powers=full and carry NO representation_note', v_note;
  END IF;

  -- 🔴 The failure mode CI cannot catch.
  SELECT count(*) INTO v_nogeom FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'City of Atlanta, Georgia, US'
     AND NOT EXISTS (
       SELECT 1 FROM essentials.geofence_boundaries b
        WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'ATL-1 gate: % Atlanta office(s) sit on a district with NO polygon — unreachable by any address', v_nogeom;
  END IF;

  -- 🔴 CONTROL. A gate that only counts what this migration wrote cannot tell "it worked" from
  --    "I am looking at the wrong database". GA-2 seated 236 legislative offices; if they are not
  --    here, these counts mean nothing.
  SELECT count(*) INTO v_leg FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Georgia'
     AND c.name IN ('Georgia House of Representatives', 'Georgia State Senate');
  IF v_leg <> 236 THEN
    RAISE EXCEPTION 'ATL-1 gate CONTROL: expected 236 Georgia legislative offices from GA-2, found % — wrong database, or GA-2 has regressed', v_leg;
  END IF;

  RAISE NOTICE 'ATL-1 OK: 1 government, 3 chambers, 13 districts, 17 offices (12 district + 3 at-large + president + mayor), 0 vacant, control 236 legislative offices present';
END $$;
