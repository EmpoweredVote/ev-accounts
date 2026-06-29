-- Migration 1112: Seed 63 NV 2026 race rows for the NV 2026 Statewide General election
--
-- Phase 167-02 (v18.0 NV 2026 Elections & Discovery, Plan 02).
-- Prerequisite: migration 1111 must already have inserted the 'NV 2026 Statewide General'
-- election row (Plan 01). All race INSERTs resolve election_id via a JOIN on that name literal.
--
-- Creates exactly 63 races:
--   6 STATE_EXEC  : Governor, Lt. Governor, Attorney General, Sec of State, Treasurer, Controller
--  11 STATE_UPPER : Senate districts 2,8,9,10,12,13,14,16,17,20,21 (odd-year cycle up in 2026)
--  42 STATE_LOWER : Assembly districts 1–42 (all up every 2 years)
--   4 NATIONAL_LOWER: US House districts 1–4
--
-- NV's 2 US Senators (Cortez Masto 2028, Rosen 2030) are intentionally absent.
--
-- geo_id formats verified live 2026-06-29 (Task 0 pre-check):
--   STATE_EXEC    : geo_id='32', all 6 offices share a single STATE_EXEC district
--   STATE_UPPER   : geo_id='32001'..'32021' (5-char: '32' + 3-digit zero-padded district)
--   STATE_LOWER   : geo_id='32001'..'32042' (same format, different district_type)
--   NATIONAL_LOWER: geo_id='3201'..'3204'   (4-char: '32' + 2-digit district)
--
-- Office titles (verbatim from DB): 'Governor', 'Lieutenant Governor', 'Attorney General',
--   'Secretary of State', 'Treasurer', 'Controller'
--
-- ILIKE 'nv' guard is MANDATORY on every districts JOIN (mixed-casing: both 'nv' and 'NV'
-- exist in production — D-09 verified live).
--
-- Idempotent: NOT EXISTS guards on (election_id, office_id) for each race.
-- NEVER use ON CONFLICT on essentials.races — no unique constraint exists (D-07).
-- No schema_migrations ledger INSERT — on-disk counter is authoritative (D-08, matches 1109).

BEGIN;

-- ────────────────────────────────────────────────────────────────────────────
-- 1. STATE_EXEC races (6): Governor + 5 constitutional officers
--    Resolve each office by title on the single STATE_EXEC district (geo_id='32').
-- ────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
SELECT gen_random_uuid(), el.id, o.id, v.pos, NULL, 1
FROM (VALUES
  ('Governor',            'Governor of Nevada'),
  ('Lieutenant Governor', 'Lieutenant Governor of Nevada'),
  ('Attorney General',    'Attorney General of Nevada'),
  ('Secretary of State',  'Secretary of State of Nevada'),
  ('Treasurer',           'State Treasurer of Nevada'),
  ('Controller',          'State Controller of Nevada')
) v(title, pos)
JOIN essentials.elections el ON el.name = 'NV 2026 Statewide General'
JOIN essentials.districts d  ON d.geo_id = '32' AND d.district_type = 'STATE_EXEC' AND d.state ILIKE 'nv'
JOIN essentials.offices o    ON o.district_id = d.id AND o.title = v.title
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
);

-- ────────────────────────────────────────────────────────────────────────────
-- 2. STATE_UPPER races (11): Senate districts up in 2026
--    Districts verified: 2,8,9,10,12,13,14,16,17,20,21 (district 16 NOT 15)
--    geo_id format: '3200N' zero-padded to 5 chars (e.g. district 2 → '32002')
-- ────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
SELECT gen_random_uuid(), el.id, o.id,
       'Nevada State Senate District ' || lpad(v.dn::text, 2, '0'), NULL, 1
FROM (VALUES (2),(8),(9),(10),(12),(13),(14),(16),(17),(20),(21)) v(dn)
JOIN essentials.elections el ON el.name = 'NV 2026 Statewide General'
JOIN essentials.districts d
  ON d.geo_id = '320' || lpad(v.dn::text, 2, '0')
  AND d.district_type = 'STATE_UPPER'
  AND d.state ILIKE 'nv'
JOIN essentials.offices o ON o.district_id = d.id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
);

-- ────────────────────────────────────────────────────────────────────────────
-- 3. STATE_LOWER races (42): Assembly districts 1–42 (all up in 2026)
--    geo_id format: '3200N' zero-padded to 5 chars (e.g. district 1 → '32001')
-- ────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
SELECT gen_random_uuid(), el.id, o.id,
       'Nevada State Assembly District ' || lpad(v.dn::text, 2, '0'), NULL, 1
FROM (VALUES
  (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
  (11),(12),(13),(14),(15),(16),(17),(18),(19),(20),
  (21),(22),(23),(24),(25),(26),(27),(28),(29),(30),
  (31),(32),(33),(34),(35),(36),(37),(38),(39),(40),
  (41),(42)
) v(dn)
JOIN essentials.elections el ON el.name = 'NV 2026 Statewide General'
JOIN essentials.districts d
  ON d.geo_id = '320' || lpad(v.dn::text, 2, '0')
  AND d.district_type = 'STATE_LOWER'
  AND d.state ILIKE 'nv'
JOIN essentials.offices o ON o.district_id = d.id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
);

-- ────────────────────────────────────────────────────────────────────────────
-- 4. NATIONAL_LOWER races (4): US House districts 1–4
--    geo_id format: '320N' (4-char: '32' + 2-digit, e.g. district 1 → '3201')
-- ────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
SELECT gen_random_uuid(), el.id, o.id, 'U.S. Representative District ' || v.cd, NULL, 1
FROM (VALUES
  ('3201',1),('3202',2),('3203',3),('3204',4)
) v(geo_id, cd)
JOIN essentials.elections el ON el.name = 'NV 2026 Statewide General'
JOIN essentials.districts d
  ON d.geo_id = v.geo_id
  AND d.district_type = 'NATIONAL_LOWER'
  AND d.state ILIKE 'nv'
JOIN essentials.offices o ON o.district_id = d.id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
);

-- ────────────────────────────────────────────────────────────────────────────
-- 5. Post-write assertions — abort transaction if any invariant fails
-- ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  n_exec    int;
  n_upper   int;
  n_lower   int;
  n_house   int;
  n_nulloff int;
  n_party   int;
BEGIN
  SELECT count(*) INTO n_exec
    FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE el.name = 'NV 2026 Statewide General' AND d.district_type = 'STATE_EXEC';
  IF n_exec <> 6 THEN
    RAISE EXCEPTION 'Expected 6 NV STATE_EXEC races, found %', n_exec;
  END IF;

  SELECT count(*) INTO n_upper
    FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE el.name = 'NV 2026 Statewide General' AND d.district_type = 'STATE_UPPER';
  IF n_upper <> 11 THEN
    RAISE EXCEPTION 'Expected 11 NV STATE_UPPER (Senate) races, found %', n_upper;
  END IF;

  SELECT count(*) INTO n_lower
    FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE el.name = 'NV 2026 Statewide General' AND d.district_type = 'STATE_LOWER';
  IF n_lower <> 42 THEN
    RAISE EXCEPTION 'Expected 42 NV STATE_LOWER (Assembly) races, found %', n_lower;
  END IF;

  SELECT count(*) INTO n_house
    FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE el.name = 'NV 2026 Statewide General' AND d.district_type = 'NATIONAL_LOWER';
  IF n_house <> 4 THEN
    RAISE EXCEPTION 'Expected 4 NV NATIONAL_LOWER (House) races, found %', n_house;
  END IF;

  SELECT count(*) INTO n_nulloff
    FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
   WHERE el.name = 'NV 2026 Statewide General' AND r.office_id IS NULL;
  IF n_nulloff <> 0 THEN
    RAISE EXCEPTION 'Found % NV 2026 races with NULL office_id', n_nulloff;
  END IF;

  SELECT count(*) INTO n_party
    FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
   WHERE el.name = 'NV 2026 Statewide General' AND r.primary_party IS NOT NULL;
  IF n_party <> 0 THEN
    RAISE EXCEPTION 'Found % NV 2026 races with non-NULL primary_party (antipartisan violation)', n_party;
  END IF;

  RAISE NOTICE 'OK: NV 2026 races 6+11+42+4=63, 0 NULL office_id, 0 non-NULL primary_party';
END $$;

COMMIT;
