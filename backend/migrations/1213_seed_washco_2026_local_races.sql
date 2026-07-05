-- Migration 1213: Seed 25 west-metro OR 2026 General race rows (Washington County + 7 cities)
--
-- Phase 185-01 (v20.0 Beaverton & Washington County OR — WashCo 2026 Elections & Discovery, Plan 01).
-- Prerequisite: the 'OR 2026 General' election row already exists (id de10e3a7-f5c2-47e6-acd7-ee87be9413db,
--   name 'OR 2026 General', state 'OR', 2026-11-03 — verified live at Wave-0). All race INSERTs resolve
--   election_id via a JOIN on that name literal (ILIKE 'or' as a defensive guard).
--
-- Seeds exactly 25 office-anchored races — ONLY seats actually on the Nov 3 2026 ballot (D-03):
--   WashCo Commission (2) : County Chair (41067), Commissioner District 4 (washco-or-commissioner-district-4)
--   Beaverton         (1) : Council Member (Position 1)
--   Hillsboro         (3) : Councilor Ward 1/2/3 Position A
--   Tigard            (4) : Mayor + 3 at-large Councilor seats (Anderson/Ghoddusi/Robbins)
--   Tualatin          (4) : Mayor + Positions 1/3/5
--   Forest Grove      (4) : Mayor + 3 at-large Councilor seats (Marshall/Martinez/Valenzuela)
--   Sherwood          (4) : Mayor + 3 at-large Councilor seats (Giles/Mays/Scott)
--   Cornelius         (3) : Mayor + 2 at-large Councilor seats (Baker/López)
--
-- OMITTED (D-03 "only seats up in NOV 2026"): the 3 seats already decided outright in the May 19 2026
--   primary — WashCo District 2 (Monteblanco), Beaverton Position 2 (Teater), Beaverton Position 5 (Dugger).
--   These have NO Nov 3 2026 ballot item, so no race row (RESEARCH Pitfall 1).
--
-- OFFICE RESOLUTION (critical): the plain-title at-large councils (Tigard, Forest Grove, Sherwood,
--   Cornelius) have MULTIPLE offices all titled 'Councilor' sharing one LOCAL district. Resolving by
--   o.title alone would collapse them. Each seat is therefore resolved via its CURRENT incumbent's office
--   linkage (pol.full_name = v.incumbent -> o.politician_id = pol.id -> d.geo_id = v.geo_id). Every
--   incumbent below was confirmed live 2026-07-04 to resolve to exactly one office.
--
-- POSITION_NAME uniqueness: essentials.races has TWO unique indexes forcing position_name to be distinct
--   within an election (races_election_position_party_unique on (election_id, position_name, primary_party)
--   AND idx_races_election_position_no_party on (election_id, position_name) WHERE primary_party IS NULL).
--   Since all 25 races share the OR 2026 General election, every position_name is made unique with a
--   "{City} {Body} {Seat}" label (house convention, e.g. Fairview OR / Salt Lake County / Utah County).
--   The at-large plain-'Councilor' seats get lettered "Seat A/B/C" assigned by alphabetical incumbent
--   surname (display-only; Plan 02 attaches candidates by office_id, not by this label).
--
-- OR casing trap: essentials.districts.state is LOWERCASE 'or' (matches 1120/1178/1187/1196);
--   essentials.elections.state is UPPERCASE 'OR'. Two different tables, two different conventions.
--
-- Idempotent: NOT EXISTS guards on (election_id, office_id) for each race.
-- NEVER use ON CONFLICT on essentials.races (the unique indexes are on position_name, not office_id;
--   the correct dedupe key per D-10 is (election_id, office_id) via NOT EXISTS).
-- primary_party stays NULL (antipartisan invariant).
-- No schema_migrations ledger INSERT — pure data-seed (1109/1112 family), on-disk counter is authoritative.

BEGIN;

-- ────────────────────────────────────────────────────────────────────────────
-- 25 west-metro race rows. office resolved via the incumbent -> office linkage;
-- position_name is an explicit unique display label per seat.
-- ────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
SELECT gen_random_uuid(), el.id, o.id, v.pos, NULL, 1
FROM (VALUES
  -- Washington County Commission (2)
  ('41067',                             'Kathryn Harrington',     'Washington County Chair'),
  ('washco-or-commissioner-district-4', 'Jerry Willey',           'Washington County Commissioner District 4'),
  -- Beaverton (1) — numbered positions
  ('4105350',                           'Ashley Hartmeier-Prigg', 'Beaverton City Council Position 1'),
  -- Hillsboro (3) — Ward/Position labels
  ('4134100',                           'Cristian Salgado',       'Hillsboro City Council Ward 1 Position A'),
  ('4134100',                           'Kipperlyn Sinclair',     'Hillsboro City Council Ward 2 Position A'),
  ('4134100',                           'Olivia Alcaire',         'Hillsboro City Council Ward 3 Position A'),
  -- Tigard (4) — Mayor + at-large lettered seats (Anderson=A, Ghoddusi=B, Robbins=C)
  ('4173650',                           'Yi-Kang Hu',             'Tigard Mayor'),
  ('4173650',                           'Tom Anderson',           'Tigard City Council Seat A'),
  ('4173650',                           'Faraz Ghoddusi',         'Tigard City Council Seat B'),
  ('4173650',                           'Heather Robbins',        'Tigard City Council Seat C'),
  -- Tualatin (4) — Mayor + numbered positions
  ('4174950',                           'Frank Bubenik',          'Tualatin Mayor'),
  ('4174950',                           'María Reyes',            'Tualatin City Council Position 1'),
  ('4174950',                           'Bridget Brooks',         'Tualatin City Council Position 3'),
  ('4174950',                           'Octavio Gonzalez',       'Tualatin City Council Position 5'),
  -- Forest Grove (4) — Mayor + at-large lettered seats (Marshall=A, Martinez=B, Valenzuela=C)
  ('4126200',                           'Malynda Wenzl',          'Forest Grove Mayor'),
  ('4126200',                           'Michael Marshall',       'Forest Grove City Council Seat A'),
  ('4126200',                           'Karen Martinez',         'Forest Grove City Council Seat B'),
  ('4126200',                           'Mariana Valenzuela',     'Forest Grove City Council Seat C'),
  -- Sherwood (4) — Mayor + at-large lettered seats (Giles=A, Mays=B, Scott=C)
  ('4167100',                           'Tim Rosener',            'Sherwood Mayor'),
  ('4167100',                           'Taylor Giles',           'Sherwood City Council Seat A'),
  ('4167100',                           'Keith Mays',             'Sherwood City Council Seat B'),
  ('4167100',                           'Doug Scott',             'Sherwood City Council Seat C'),
  -- Cornelius (3) — Mayor + at-large lettered seats (Baker=A, López=B)
  ('4115550',                           'Jeffrey C. Dalin',       'Cornelius Mayor'),
  ('4115550',                           'Edgar Baker',            'Cornelius City Council Seat A'),
  ('4115550',                           'Edén López',             'Cornelius City Council Seat B')
) v(geo_id, incumbent, pos)
JOIN essentials.elections el    ON el.name = 'OR 2026 General' AND el.state ILIKE 'or'
JOIN essentials.politicians pol ON pol.full_name = v.incumbent
JOIN essentials.offices o       ON o.politician_id = pol.id
JOIN essentials.districts d     ON d.id = o.district_id AND d.geo_id = v.geo_id AND d.state = 'or'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
);

-- ────────────────────────────────────────────────────────────────────────────
-- Post-write assertions — abort the whole transaction if any invariant fails.
-- Scoped to the 9 west-metro geo_ids: 123 OTHER OR-2026-General races (statewide/
-- legislative shells) already exist, so a broad el.name-only count would be wrong.
-- ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  n_westmetro   int;
  n_party       int;
  n_schoolboard int;
BEGIN
  SELECT count(*) INTO n_westmetro
    FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
    JOIN essentials.offices o    ON o.id = r.office_id
    JOIN essentials.districts d  ON d.id = o.district_id
   WHERE el.name = 'OR 2026 General' AND el.state ILIKE 'or'
     AND d.geo_id IN ('41067','washco-or-commissioner-district-4','4105350','4134100',
                      '4173650','4174950','4126200','4167100','4115550');
  IF n_westmetro <> 25 THEN
    RAISE EXCEPTION 'Expected 25 west-metro OR 2026 races, found %', n_westmetro;
  END IF;

  -- All 25 resolve via the office join, so office_id is structurally non-NULL; the
  -- geo_id-scoped count above already proves that. Antipartisan invariant:
  SELECT count(*) INTO n_party
    FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
    JOIN essentials.offices o    ON o.id = r.office_id
    JOIN essentials.districts d  ON d.id = o.district_id
   WHERE el.name = 'OR 2026 General' AND el.state ILIKE 'or'
     AND d.geo_id IN ('41067','washco-or-commissioner-district-4','4105350','4134100',
                      '4173650','4174950','4126200','4167100','4115550')
     AND r.primary_party IS NOT NULL;
  IF n_party <> 0 THEN
    RAISE EXCEPTION 'Found % west-metro OR 2026 races with non-NULL primary_party (antipartisan violation)', n_party;
  END IF;

  -- Negative school-board assertion (D-04): 0 OR-2026-General races resolve to any SCHOOL district.
  SELECT count(*) INTO n_schoolboard
    FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
    JOIN essentials.offices o    ON o.id = r.office_id
    JOIN essentials.districts d  ON d.id = o.district_id
   WHERE el.name = 'OR 2026 General' AND el.state ILIKE 'or'
     AND d.district_type = 'SCHOOL';
  IF n_schoolboard <> 0 THEN
    RAISE EXCEPTION 'Found % unexpected school-board OR 2026 races', n_schoolboard;
  END IF;

  RAISE NOTICE 'OK: 25 west-metro OR 2026 races, 0 non-NULL primary_party, 0 school-board races';
END $$;

COMMIT;
