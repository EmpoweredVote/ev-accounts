-- CC_0240_fulton_county_structure.sql
--
-- Atlanta full seed, stage 4a, FULTON COUNTY STRUCTURE half.
--   * 1 government, 2 chambers
--   * 6 new districts (X0078); the countywide seats reuse the EXISTING COUNTY district 13121/G4020
--   * 11 offices -- Chairperson (at-large) + 6 district commissioners + 4 county officers
--
-- Roster: backend/data/seed-atlanta-2026/ROSTERS.md
-- Boundaries: scripts/load-fulton-commission-districts.mjs MUST RUN FIRST (X0078).
-- Slot CC_0240 was RESERVED FROM THE ALLOCATOR before this file was named.
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 SEVEN SEATS, SIX DISTRICTS. The Chairperson is elected AT LARGE and hangs on the county
--    polygon. Do not look for a seventh polygon; a count gate expecting seven fails on correct
--    data. ⚠ DeKalb (CC_0242) is the OPPOSITE: no at-large chair, but an elected CEO and two
--    SUPER districts. Do not standardise the two counties.
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 DISTRICT 4 IS CREATED **VACANT**, WITH NO office_terms ROW AND NO VACANCY SPAN.
--
-- Mo Ivory won District 4 unopposed in 2024 (74,873 votes, SOS certified). Her District 4 term
-- runs to 2028 and the Chair term begins January 2027, so Georgia's resign-to-run rule required
-- her to resign before qualifying for Chair. She did, and then beat the sitting Chairman
-- 65.96%-34.04% in the 2026-06-16 Democratic runoff.
--
-- The PRIMARY evidence of the vacancy is the county's own CALL FOR ELECTION under
-- O.C.G.A. § 21-2-540, signed by the Director of Registration & Elections: a special election
-- for Fulton County Commission District 4 on 2026-11-03, runoff 2026-12-01.
--
-- ⚠ THE COUNTY'S OWN COMMISSIONERS PAGE SIMPLY OMITS DISTRICT 4 AND SAYS NOTHING. A roster
--   built from that page alone would have created SIX commission seats, and the seventh would
--   have been an office with no term row — invisible, with nothing erroring.
--
-- 🔴 vacant_since IS LEFT NULL ON PURPOSE. CLAUDE.md: "do not write a vacancy span whose start
--    date you don't know — set offices.is_vacant and leave the span unwritten." Press reports
--    the resignation as 2026-03-06 and the notice filename encodes a 2026-03-17 notice date;
--    neither is a primary statement of the vacancy date. Owed, as ROSTERS.md open item 4.
--
-- ---------------------------------------------------------------------------
-- 🔴 FOUR COUNTY OFFICERS, READ OFF THE CERTIFIED BALLOT, NOT INHERITED.
--
-- Sheriff, Clerk of Superior Court, Tax Commissioner and Surveyor are all on Fulton's 2024
-- certified general. Excluded, each for a stated reason:
--
--   Solicitor General, District Attorney (Atlanta Judicial Circuit)
--       prosecutors — the FL-5 rule, carried into the Georgia county-officer template (ga.md,
--       ruled 2026-09-01). ⚠ ONE LEG OF THAT RULE DOES NOT APPLY HERE and is recorded rather
--       than dropped: Baldwin's DA was excluded partly for sitting on a MULTI-COUNTY circuit,
--       and the Atlanta Judicial Circuit is Fulton alone. They stay out on the prosecutor rule
--       only.
--   Chief Magistrate, State Court and Superior Court judges
--       judicial branch, Ga. Const. Art. VI, as Florida excluded its county judges.
--   County Board of Education       spec §11.
--   Soil and Water District Supervisor  not a county office.
--
-- 🔴 NO PROBATE JUDGE IS CREATED, AND THAT IS DELIBERATE.
--    Fulton operates a Probate Court, but NO Probate Judge contest appears in ANY certified
--    return 2020-2026. Under Georgia's nonpartisan election law an unopposed candidate is
--    declared elected and never reaches a ballot, so A CERTIFIED RETURN ENUMERATES CONTESTS,
--    NOT OFFICES. The detector is sound — the Baldwin control returns Surveyor and Coroner on
--    the same scan — so the absence is real, and no county source names the sitting judge.
--    Creating the office without a term row would make it INVISIBLE and raise
--    essentials.offices_missing_terms. It is recorded as owed (ROSTERS.md open item 1) instead.
--
-- 🔴 NO CORONER. Fulton runs a medical examiner system and elects no coroner; no Coroner
--    contest appears in any return either. ⚠ Inferred from the same absence — ROSTERS.md
--    open item 2.
--
-- ---------------------------------------------------------------------------
-- Idempotent. Dry-run with BEGIN; ... ROLLBACK; and confirm the rollback reverted.

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_comm  int;
  v_dup   int;
  v_cty   int;
BEGIN
  SELECT count(*) INTO v_comm FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0078' AND state = '13' AND geo_id LIKE 'fulton-county-ga-commission-%';
  IF v_comm <> 6 THEN
    RAISE EXCEPTION 'ATL-3 pre-flight: expected 6 X0078 Fulton commission polygons, found % — run scripts/load-fulton-commission-districts.mjs first. An office on a district with no polygon is unreachable by any address and nothing errors.', v_comm;
  END IF;

  SELECT count(*) INTO v_dup FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0078' AND geo_id NOT LIKE 'fulton-county-ga-commission-%';
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'ATL-3 pre-flight: % X0078 polygon(s) are not Fulton commission districts — somebody else took this code', v_dup;
  END IF;

  -- 🔴 geo_id '13121' is BOTH Fulton County (G4020) AND State House District 121 (G5220) in
  --    this very database, and the G5220 row already carries an office. The pair is the key.
  SELECT count(*) INTO v_cty FROM essentials.districts
   WHERE geo_id = '13121' AND mtfcc = 'G4020' AND district_type = 'COUNTY' AND lower(state) = 'ga';
  IF v_cty <> 1 THEN
    RAISE EXCEPTION 'ATL-3 pre-flight: expected exactly 1 Fulton COUNTY district 13121/G4020, found %', v_cty;
  END IF;
END $$;

-- ─── 1. The government ───────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT 'Fulton County, Georgia, US', 'County', 'GA', NULL, '13121', 'G4020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'Fulton County, Georgia, US');

-- ─── 2. Two chambers ─────────────────────────────────────────────────────────
-- official_count 7 for the board: the Chairperson SITS ON IT and votes, unlike Atlanta's
-- Council President and unlike Macon-Bibb's mayor. Four-year terms, staggered: Districts 2, 4
-- and 6 were on the 2024 ballot; the Chair and Districts 1, 3 and 5 are on the 2026 one.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT g.id, v.name, v.name, v.official_count, '4'
FROM essentials.governments g
JOIN (VALUES
  ('Board of Commissioners',         7),
  ('Fulton County Elected Officials', 4)
) AS v(name, official_count) ON true
WHERE g.name = 'Fulton County, Georgia, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Six commission districts (the countywide row already exists) ─────────

CREATE TEMP TABLE ful_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO ful_districts(geo_id, label, mtfcc) VALUES
  ('fulton-county-ga-commission-1', 'Fulton County Commission District 1', 'X0078'),
  ('fulton-county-ga-commission-2', 'Fulton County Commission District 2', 'X0078'),
  ('fulton-county-ga-commission-3', 'Fulton County Commission District 3', 'X0078'),
  ('fulton-county-ga-commission-4', 'Fulton County Commission District 4', 'X0078'),
  ('fulton-county-ga-commission-5', 'Fulton County Commission District 5', 'X0078'),
  ('fulton-county-ga-commission-6', 'Fulton County Commission District 6', 'X0078');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT n.geo_id, n.label, 'COUNTY', 'ga', n.mtfcc, 1
FROM ful_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'COUNTY');

-- The countywide row is GA-1's and already exists; only its num_officials is set here.
-- 5 = the at-large Chairperson plus the four county officers.
UPDATE essentials.districts
   SET num_officials = 5
 WHERE geo_id = '13121' AND mtfcc = 'G4020' AND district_type = 'COUNTY' AND lower(state) = 'ga'
   AND num_officials IS DISTINCT FROM 5;

-- ─── 4. Eleven offices ───────────────────────────────────────────────────────
-- 🔴 Every join pairs geo_id WITH mtfcc AND district_type. '13121' alone resolves to TWO rows
--    in this database.

CREATE TEMP TABLE ful_offices(geo_id text, mtfcc text, chamber_name text, title text, is_vacant boolean) ON COMMIT DROP;
INSERT INTO ful_offices(geo_id, mtfcc, chamber_name, title, is_vacant) VALUES
  ('13121',                        'G4020', 'Board of Commissioners', 'Commission Chairperson',   false),
  ('fulton-county-ga-commission-1','X0078', 'Board of Commissioners', 'Commissioner, District 1', false),
  ('fulton-county-ga-commission-2','X0078', 'Board of Commissioners', 'Commissioner, District 2', false),
  ('fulton-county-ga-commission-3','X0078', 'Board of Commissioners', 'Commissioner, District 3', false),
  -- 🔴 VACANT. Special election 2026-11-03 under O.C.G.A. § 21-2-540.
  ('fulton-county-ga-commission-4','X0078', 'Board of Commissioners', 'Commissioner, District 4', true),
  ('fulton-county-ga-commission-5','X0078', 'Board of Commissioners', 'Commissioner, District 5', false),
  ('fulton-county-ga-commission-6','X0078', 'Board of Commissioners', 'Commissioner, District 6', false),
  ('13121',                        'G4020', 'Fulton County Elected Officials', 'Sheriff',                  false),
  ('13121',                        'G4020', 'Fulton County Elected Officials', 'Clerk of Superior Court',  false),
  ('13121',                        'G4020', 'Fulton County Elected Officials', 'Tax Commissioner',         false),
  ('13121',                        'G4020', 'Fulton County Elected Officials', 'Surveyor',                 false);

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, 'GA', NULL, 1, n.is_vacant, 'full'
FROM ful_offices n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'COUNTY' AND lower(d.state) = 'ga'
JOIN essentials.governments g ON g.name = 'Fulton County, Georgia, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = n.title);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov    int;
  v_ch     int;
  v_dist   int;
  v_off    int;
  v_comm   int;
  v_offs   int;
  v_vacant int;
  v_d4     int;
  v_nogeom int;
  v_titles int;
  v_leg    int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'Fulton County, Georgia, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'ATL-3 gate: expected 1 Fulton government row, found %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Fulton County, Georgia, US';
  IF v_ch <> 2 THEN RAISE EXCEPTION 'ATL-3 gate: expected 2 Fulton chambers, found %', v_ch; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE mtfcc = 'X0078' AND district_type = 'COUNTY' AND lower(state) = 'ga';
  IF v_dist <> 6 THEN RAISE EXCEPTION 'ATL-3 gate: expected 6 Fulton commission districts, found %', v_dist; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Fulton County, Georgia, US';
  IF v_off <> 11 THEN RAISE EXCEPTION 'ATL-3 gate: expected 11 Fulton offices, found %', v_off; END IF;

  SELECT
    count(*) FILTER (WHERE c.name = 'Board of Commissioners'),
    count(*) FILTER (WHERE c.name = 'Fulton County Elected Officials')
    INTO v_comm, v_offs
  FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Fulton County, Georgia, US';
  IF v_comm <> 7 OR v_offs <> 4 THEN
    RAISE EXCEPTION 'ATL-3 gate: expected 7 board + 4 county officers, found % and %', v_comm, v_offs;
  END IF;

  -- 🔴 EXACTLY ONE vacancy, and it must be District 4 — not merely "a" vacancy.
  SELECT count(*) INTO v_vacant FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Fulton County, Georgia, US' AND o.is_vacant;
  IF v_vacant <> 1 THEN
    RAISE EXCEPTION 'ATL-3 gate: expected exactly 1 vacant Fulton office, found %', v_vacant;
  END IF;

  SELECT count(*) INTO v_d4 FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Fulton County, Georgia, US' AND o.is_vacant
     AND o.title = 'Commissioner, District 4';
  IF v_d4 <> 1 THEN
    RAISE EXCEPTION 'ATL-3 gate: the vacant Fulton office is not District 4 — the Call for Election names District 4 and nothing else';
  END IF;

  SELECT count(DISTINCT o.title) INTO v_titles FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Fulton County, Georgia, US';
  IF v_titles <> 11 THEN
    RAISE EXCEPTION 'ATL-3 gate: expected 11 DISTINCT Fulton office titles, found %', v_titles;
  END IF;

  SELECT count(*) INTO v_nogeom FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'Fulton County, Georgia, US'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'ATL-3 gate: % Fulton office(s) sit on a district with NO polygon — unreachable by any address', v_nogeom;
  END IF;

  -- 🔴 CONTROL.
  SELECT count(*) INTO v_leg FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Georgia'
     AND c.name IN ('Georgia House of Representatives', 'Georgia State Senate');
  IF v_leg <> 236 THEN
    RAISE EXCEPTION 'ATL-3 gate CONTROL: expected 236 Georgia legislative offices, found % — wrong database', v_leg;
  END IF;

  RAISE NOTICE 'ATL-3 OK: 1 government, 2 chambers, 6 commission districts, 11 offices (7 board + 4 officers), exactly 1 vacancy and it is District 4, control 236 legislative offices present';
END $$;
