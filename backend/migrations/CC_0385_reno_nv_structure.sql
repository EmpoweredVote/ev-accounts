-- CC_0385_reno_nv_structure.sql
-- City of Reno, Nevada — greenfield seed, STRUCTURE ONLY: government, three chambers,
-- seven districts, twelve offices. NO PEOPLE ARE SEATED BY THIS MIGRATION.
--
-- ═══ 🔴 WHY NOBODY IS SEATED HERE: RENO'S ENTIRE ELECTED ROSTER TURNS OVER ON 2026-11-13 ═══
--
-- The general election was held 2026-11-03, six days before this migration was written. Reno
-- City Charter § 5.100(3) provides that officers elected "shall qualify and enter upon the
-- discharge of their respective duties at the first regular City Council meeting following
-- their election", and the City announced a special meeting on **2026-11-13** to declare the
-- results and administer the oaths. On that date four of Reno's ten elected offices change
-- hands:
--
--   Mayor          Hillary Schieve (ineligible for a 4th term) → Kate Marshall
--   Ward 2         Naomi Duerr                                 → Matt Johnson
--   Ward 4         Meghan Ebert                                → UNDECIDED on 2026-11-09:
--                  challenger Eddie Gomez led by 61 votes, signature curing ran to 5pm that
--                  day, and the count is not official until 2026-11-13
--   City Attorney  Karl Hall (retiring)                        → Zee Bogale (unopposed)
--
-- Seating today would therefore write four rows with a 96-hour shelf life and one of them
-- would be a guess. The structure below is election-independent and is correct whoever wins,
-- so it lands now; the roster lands in a follow-up migration once the canvass is official.
-- `essentials.office_swearing_in` (CC_0344) is where the 2026-11-13 date belongs, with
-- basis 'published' — the City published the meeting, the Charter supplies only "the first
-- meeting following", which is not a date.
--
-- ⚠ WASHOE COUNTY IS A DIFFERENT DATE and is seeded separately by CC_0386. Its three changed
--   commission seats are not sworn until JANUARY, so its current commissioners stay correct
--   for another two months. Do not fold the two rosters into one pass.
--
-- ═══ THIS IS A TRUE GREENFIELD, VERIFIED NOT ASSUMED ═══
--
-- The Wave-2 rule (`project_v170_wave2_not_greenfield`) is that a city the roadmap calls
-- greenfield is usually a reconcile. Reno was pre-checked against production on 2026-11-09 by
-- NAME and by geo_id:
--
--   essentials.governments WHERE name ILIKE '%reno%' OR name ILIKE '%washoe%'  → 0 rows
--   essentials.governments WHERE geo_id IN ('3260600','32031')                 → 0 rows
--   duplicate same-slug chambers to merge                                      → none
--   office-unlinked people to reseat rather than recreate                      → none
--
-- Nevada's local tier before this migration was CLARK COUNTY ONLY — Las Vegas, Henderson,
-- North Las Vegas, Boulder City, Clark County and CCSD. Reno is northern Nevada's first local
-- tier of any kind. Nevada's STATE tier, by contrast, is already complete (6 constitutional
-- officers, 21 Senate, 42 Assembly all seated), so a Reno voter lands on a full state tier.
--
-- ═══ 🔴 SIX WARDS, NOT FIVE, AND THE OBVIOUS GIS LAYER SERVES FIVE ═══
--
-- Reno moved from five wards to six under Nevada AB36 (2017); the sixth ward replaced the
-- at-large council seat at the 2024 general election. Reno City Charter § 1.050(1) now
-- requires six wards and § 2.010(1) sets the Council at six Council Members plus a Mayor.
-- THERE IS NO AT-LARGE COUNCIL SEAT.
--
-- The City still publishes the superseded FIVE-ward map at
-- citymaps.reno.gov/AdminAreas/Reno_Wards (layers 8-12), whose name and folder look more
-- authoritative than the live one. `scripts/load-reno-washoe-districts.mjs` takes the current
-- map from pwmaps.reno.gov/PublicWorks/City_Wards/0 and proves the vintage BOTH ways against
-- the Washoe County Registrar's precinct layer — the body that prints Reno's ballots:
--
--   current six-ward map    vs Registrar RWARDS  → 161 of 161 Reno precincts agree
--   superseded five-ward map vs the same arbiter → contradicted on 47 of the 135 precincts
--                                                  both maps place (34.8%)
--
-- ═══ WHAT RENO ELECTS (Charter § 1.060(1)) ═══
--   (a) Mayor                  at large, 4-year term  (§ 2.010(3))
--   (b) six Council Members    one per ward, 4-year terms
--   (c) Municipal Judges       4 departments, 6-year terms (§ 4.010, § 5.010)
--   (d) City Attorney          at large, 4-year term  (§ 3.060(1), § 5.010(2))
--
-- The City Manager and City Clerk are APPOINTED (§ 1.090, § 3.020) and get no office row.
-- The Vice Mayor is a role the Council confers on one of its own members, not a seat —
-- modelling one would invent an election and consume a real ward seat (the defect CC_0292
-- found in six Maine cities).
--
-- 🔴 FOUR municipal court departments is from the STATE OF NEVADA JUDICIAL DIRECTORY (AOC,
--    rev. 2026-03-17), which lists "Reno Municipal Court (Dept. 1)" through "(Dept. 4)" and
--    no others. The Charter only says the Council fixes the number by resolution, so the count
--    had to come from a roster rather than from the Charter. ⚠ That same directory places
--    Shelly O'Neill at FALLON Municipal Court and Dept. 2 with Randall Soderquist, while
--    Ballotpedia puts O'Neill in Reno Dept. 2 — an aggregator disagreeing with the state's own
--    directory. No judge is seated here, and that conflict must be resolved from the court
--    before any of the four offices below is filled.
--
-- ═══ GEOGRAPHY ═══
-- The six ward polygons load first, as X0086 / reno-nv-council-ward-1..6. This migration
-- REFUSES TO RUN without them: an office on a district with no polygon is unreachable by any
-- address and NOTHING ERRORS.
--
-- The wards cover 99.900% of TIGER place 3260600 (289.3 of 289.6 km²), against a census land
-- area of 282.3 km² — so they cover 7 km² MORE than all of Reno's land, and the 0.29 km²
-- shortfall is water and edge, not neighbourhoods.

BEGIN;

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_wards int; v_stray int; v_place int; v_gov int;
BEGIN
  SELECT count(*) INTO v_wards FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0086' AND geo_id LIKE 'reno-nv-council-ward-%';
  IF v_wards <> 6 THEN
    RAISE EXCEPTION 'CC_0385 pre-flight: expected 6 X0086 Reno ward polygons, found % — run '
                    'scripts/load-reno-washoe-districts.mjs first. An office on a district with '
                    'no polygon is unreachable by any address and nothing errors.', v_wards;
  END IF;

  SELECT count(*) INTO v_stray FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0086' AND geo_id NOT LIKE 'reno-nv-council-ward-%';
  IF v_stray <> 0 THEN
    RAISE EXCEPTION 'CC_0385 pre-flight: % X0086 polygon(s) are not Reno council wards — '
                    'somebody else took this mtfcc code', v_stray;
  END IF;

  SELECT count(*) INTO v_place FROM essentials.geofence_boundaries
   WHERE geo_id = '3260600' AND mtfcc = 'G4110' AND state = '32';
  IF v_place <> 1 THEN
    RAISE EXCEPTION 'CC_0385 pre-flight: expected the TIGER place polygon 3260600/G4110 for the '
                    'citywide offices, found %', v_place;
  END IF;

  -- 🔴 "Reno" IS NOT A UNIQUE PLACE NAME. Texas has TWO Reno cities (4861592 Parker County and
  -- 4861604 Lamar County), Ohio has a Reno CDP, Kansas a Reno County. Scope by geo_id, and
  -- never key a banner or a browse entry on the bare name.
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE geo_id = '3260600' OR name = 'City of Reno, Nevada, US';
  IF v_gov <> 0 THEN
    RAISE EXCEPTION 'CC_0385 pre-flight: City of Reno already exists (% row(s)). This migration '
                    'is written as a greenfield seed; re-check before re-running.', v_gov;
  END IF;
END $$;

-- ── Government ────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT 'City of Reno, Nevada, US', 'City', 'NV', 'Reno', '3260600', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Reno, Nevada, US');

-- ── Chambers ──────────────────────────────────────────────────────────────────
-- 🔴 `chambers.slug` is GENERATED ALWAYS from `name_formal`, NOT from `name`. Leaving
--    name_formal NULL silently generates an EMPTY slug, and the slug is what the app routes on.
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT g.id, v.name, v.name, v.official_count, v.term_length
FROM essentials.governments g
JOIN (VALUES
  ('Reno City Council',    7, '4'),
  ('Reno City Attorney',   1, '4'),
  ('Reno Municipal Court', 4, '6')
) AS v(name, official_count, term_length) ON true
WHERE g.name = 'City of Reno, Nevada, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ── Districts ─────────────────────────────────────────────────────────────────
-- One citywide row carries the Mayor, the City Attorney and all four municipal judges; the
-- six ward rows carry one council seat each. This is the Anchorage shape (CC_0303).
CREATE TEMP TABLE reno_districts(geo_id text, label text, mtfcc text, num_officials bigint) ON COMMIT DROP;
INSERT INTO reno_districts(geo_id, label, mtfcc, num_officials) VALUES
  ('reno-nv-council-ward-1', 'Reno City Council Ward 1', 'X0086', 1),
  ('reno-nv-council-ward-2', 'Reno City Council Ward 2', 'X0086', 1),
  ('reno-nv-council-ward-3', 'Reno City Council Ward 3', 'X0086', 1),
  ('reno-nv-council-ward-4', 'Reno City Council Ward 4', 'X0086', 1),
  ('reno-nv-council-ward-5', 'Reno City Council Ward 5', 'X0086', 1),
  ('reno-nv-council-ward-6', 'Reno City Council Ward 6', 'X0086', 1),
  ('3260600',                'Reno Citywide',            'G4110', 6);

INSERT INTO essentials.districts (geo_id, label, district_type, state, city, mtfcc, num_officials, representation_basis)
SELECT n.geo_id, n.label, 'LOCAL', 'nv', 'Reno', n.mtfcc, n.num_officials, 'residency'
FROM reno_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'LOCAL');

-- ── Offices ───────────────────────────────────────────────────────────────────
-- Titles follow the City Clerk's own 2026 ballot wording: "Council Member, Ward 2",
-- "City Attorney", "Municipal Court Judge, Department 1".
CREATE TEMP TABLE reno_offices(geo_id text, mtfcc text, chamber_name text, title text, note text) ON COMMIT DROP;
INSERT INTO reno_offices(geo_id, mtfcc, chamber_name, title, note) VALUES
  ('3260600','G4110','Reno City Council','Mayor',
     'Elected at large to a four-year term (Reno City Charter s 2.010(3)). Reno is a '
     || 'council-manager city: the Mayor presides over the Council and votes as one of its '
     || 'seven members, while the appointed City Manager is the chief executive (s 3.020).'),
  ('reno-nv-council-ward-1','X0086','Reno City Council','Council Member, Ward 1', NULL),
  ('reno-nv-council-ward-2','X0086','Reno City Council','Council Member, Ward 2', NULL),
  ('reno-nv-council-ward-3','X0086','Reno City Council','Council Member, Ward 3', NULL),
  ('reno-nv-council-ward-4','X0086','Reno City Council','Council Member, Ward 4', NULL),
  ('reno-nv-council-ward-5','X0086','Reno City Council','Council Member, Ward 5', NULL),
  ('reno-nv-council-ward-6','X0086','Reno City Council','Council Member, Ward 6',
     'Ward 6 was created by Nevada AB36 (2017) and first elected at the 2024 general election, '
     || 'replacing the at-large Council seat Reno elected until then.'),
  ('3260600','G4110','Reno City Attorney','City Attorney',
     'ELECTED at large to a four-year term (Reno City Charter s 1.060(1)(d), s 3.060(1), '
     || 's 5.010(2)) — not appointed, unlike most council-manager cities.'),
  ('3260600','G4110','Reno Municipal Court','Municipal Court Judge, Department 1', NULL),
  ('3260600','G4110','Reno Municipal Court','Municipal Court Judge, Department 2', NULL),
  ('3260600','G4110','Reno Municipal Court','Municipal Court Judge, Department 3', NULL),
  ('3260600','G4110','Reno Municipal Court','Municipal Court Judge, Department 4', NULL);

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city,
                                seats, is_vacant, is_appointed_position, voting_powers, representation_note)
SELECT c.id, d.id, n.title, 'NV', 'Reno', 1, true, false, 'full', n.note
FROM reno_offices n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'LOCAL' AND lower(d.state) = 'nv'
JOIN essentials.governments g ON g.name = 'City of Reno, Nevada, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = n.title);

-- ── Post-conditions ───────────────────────────────────────────────────────────
-- 🔴 VERIFY ON ROW COUNTS AND ON THE SLUG, not on "the inserts did not error". An empty slug
--    is the silent failure mode here, and it does not raise.
DO $$
DECLARE v_gov uuid; v_ch int; v_off int; v_dist int; v_badslug int; v_seated int; v_ward_off int;
BEGIN
  SELECT id INTO v_gov FROM essentials.governments WHERE name = 'City of Reno, Nevada, US';
  IF v_gov IS NULL THEN RAISE EXCEPTION 'CC_0385 post: the government row is missing'; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers WHERE government_id = v_gov;
  IF v_ch <> 3 THEN RAISE EXCEPTION 'CC_0385 post: expected 3 chambers, found %', v_ch; END IF;

  SELECT count(*) INTO v_badslug FROM essentials.chambers
   WHERE government_id = v_gov AND (slug IS NULL OR slug = '');
  IF v_badslug <> 0 THEN
    RAISE EXCEPTION 'CC_0385 post: % Reno chamber(s) have an empty slug — name_formal was not '
                    'set and the app routes on the slug', v_badslug;
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE district_type = 'LOCAL' AND lower(state) = 'nv' AND city = 'Reno';
  IF v_dist <> 7 THEN RAISE EXCEPTION 'CC_0385 post: expected 7 Reno districts, found %', v_dist; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id WHERE c.government_id = v_gov;
  IF v_off <> 12 THEN RAISE EXCEPTION 'CC_0385 post: expected 12 offices, found %', v_off; END IF;

  -- exactly one council seat per ward, and no ward left without one
  SELECT count(*) INTO v_ward_off FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0086';
  IF v_ward_off <> 6 THEN
    RAISE EXCEPTION 'CC_0385 post: expected 6 ward offices (one per ward), found %', v_ward_off;
  END IF;

  -- 🔴 THIS MIGRATION MUST NOT SEAT ANYBODY. Reno's roster turns over on 2026-11-13 and the
  --    Ward 4 result is not decided; a person seated here would be a guess with a 96-hour life.
  SELECT count(*) INTO v_seated FROM essentials.politicians p
    JOIN essentials.offices o ON o.id = p.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;
  IF v_seated <> 0 THEN
    RAISE EXCEPTION 'CC_0385 post: % politician(s) are attached to Reno offices. This migration '
                    'seeds STRUCTURE ONLY; seating belongs in the post-canvass pass.', v_seated;
  END IF;

  RAISE NOTICE 'CC_0385 OK: City of Reno — 3 chambers, 7 districts, 12 offices, 0 seated (by design).';
END $$;

COMMIT;
