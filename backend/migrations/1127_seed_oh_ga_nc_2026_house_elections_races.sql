-- 1127_seed_oh_ga_nc_2026_house_elections_races.sql
-- Phase 156 Wave 1 (156-01): author the OH + GA + NC 2026 Statewide General elections and the
-- 15 OH + 14 GA + 14 NC US House race scaffold. Like TX/NY (mig 1109), FL (1115), PA/IL (1117),
-- OH/GA/NC had ZERO 2026 elections/races (all 43 rows in 154-field-table.csv carry a BLANK
-- existing_race_id). This is the create-races-first structural step; Wave 2 (156-03/04/05) wires
-- race_candidates onto these races.
--
-- GA-13 TRUE VACANCY (David Scott died Apr 2026): the geo-1313 NATIONAL_LOWER *district* exists but has
-- NO essentials.offices row (live-verified 0). Its office is CREATED HERE, FIRST, before the GA-13 race
-- (the FL-20 / mig-1115 vacancy pattern): politician_id NULL, is_vacant=true, NO ghost incumbent, NO
-- incumbent race_candidates row. All other 42 OH/GA/NC House offices already exist (live-verified: exactly
-- 1 'U.S. House of Representatives' office per geo_id 39NN/37NN and 13NN except 1313).
--
-- FIELD SOURCE: 154-FIELD-TABLE.md + 154-field-table.csv (Wikipedia/SoS-sourced, human-reviewed in
-- Phase 154). OH/GA/NC primaries already held -> field is DECIDED.
--
-- ANTIPARTISAN INVARIANT (D-06): party is NOT stored on the race card; races.primary_party stays NULL
-- (a multi-candidate general has no single primary party). Party reads from the candidate's record
-- context downstream, never from race_candidates.
--
-- Schema notes (live-verified): elections.election_date is DATE; chamber resolved by EXACT name
-- 'U.S. House of Representatives' (ILIKE 'U.S. House%' is AMBIGUOUS — also matches
-- 'U.S. House of Representatives - Indiana Nth ...'). office_id resolved by district geo_id join; NEVER NULL.
--
-- Idempotent: NOT EXISTS guards on (election name), (GA-13 geo office), (election_id, office_id).
-- Re-run inserts 0 rows.

BEGIN;

-- 1) GA-13 (geo 1313) vacant-seat office — CREATED BEFORE its race (FL-20 / mig-1115 pattern).
--    politician_id NULL, is_vacant=true. Chamber resolved by exact name. NO ghost incumbent.
INSERT INTO essentials.offices
  (id, politician_id, chamber_id, district_id, title, representing_state,
   is_appointed_position, is_vacant, faces_retention_vote)
SELECT gen_random_uuid(),
       NULL,
       (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives'),
       d.id,
       'U.S. Representative',
       'GA',
       false,
       true,
       false
FROM essentials.districts d
WHERE d.geo_id = '1313' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.districts dd ON dd.id = o.district_id
    WHERE dd.geo_id = '1313' AND dd.district_type = 'NATIONAL_LOWER'
  );

-- 2) OH + GA + NC 2026 Statewide General elections (mirror the live CA/TX/NY/FL/PA/IL rows; description NULL).
INSERT INTO essentials.elections (id, name, election_date, election_type, jurisdiction_level, state)
SELECT gen_random_uuid(), 'OH 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'OH'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections e WHERE e.name = 'OH 2026 Statewide General');

INSERT INTO essentials.elections (id, name, election_date, election_type, jurisdiction_level, state)
SELECT gen_random_uuid(), 'GA 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'GA'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections e WHERE e.name = 'GA 2026 Statewide General');

INSERT INTO essentials.elections (id, name, election_date, election_type, jurisdiction_level, state)
SELECT gen_random_uuid(), 'NC 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'NC'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections e WHERE e.name = 'NC 2026 Statewide General');

-- 3) 15 OH races (geo 3901..3915) on each district's existing U.S. House office.
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.elections WHERE name = 'OH 2026 Statewide General'),
       o.id,
       'U.S. Representative District ' || v.cd,
       NULL, 1, NULL
FROM (VALUES
    ('3901','1'),('3902','2'),('3903','3'),('3904','4'),('3905','5'),
    ('3906','6'),('3907','7'),('3908','8'),('3909','9'),('3910','10'),
    ('3911','11'),('3912','12'),('3913','13'),('3914','14'),('3915','15')
  ) AS v(geo_id, cd)
JOIN essentials.districts d
  ON d.geo_id = v.geo_id AND d.district_type = 'NATIONAL_LOWER'
JOIN essentials.offices o
  ON o.district_id = d.id
 AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id = (SELECT id FROM essentials.elections WHERE name = 'OH 2026 Statewide General')
    AND r.office_id = o.id
);

-- 4) 14 GA races (geo 1301..1314, incl. the just-created GA-13/1313 vacancy office).
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.elections WHERE name = 'GA 2026 Statewide General'),
       o.id,
       'U.S. Representative District ' || v.cd,
       NULL, 1, NULL
FROM (VALUES
    ('1301','1'),('1302','2'),('1303','3'),('1304','4'),('1305','5'),
    ('1306','6'),('1307','7'),('1308','8'),('1309','9'),('1310','10'),
    ('1311','11'),('1312','12'),('1313','13'),('1314','14')
  ) AS v(geo_id, cd)
JOIN essentials.districts d
  ON d.geo_id = v.geo_id AND d.district_type = 'NATIONAL_LOWER'
JOIN essentials.offices o
  ON o.district_id = d.id
 AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id = (SELECT id FROM essentials.elections WHERE name = 'GA 2026 Statewide General')
    AND r.office_id = o.id
);

-- 5) 14 NC races (geo 3701..3714) on each district's existing U.S. House office.
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.elections WHERE name = 'NC 2026 Statewide General'),
       o.id,
       'U.S. Representative District ' || v.cd,
       NULL, 1, NULL
FROM (VALUES
    ('3701','1'),('3702','2'),('3703','3'),('3704','4'),('3705','5'),
    ('3706','6'),('3707','7'),('3708','8'),('3709','9'),('3710','10'),
    ('3711','11'),('3712','12'),('3713','13'),('3714','14')
  ) AS v(geo_id, cd)
JOIN essentials.districts d
  ON d.geo_id = v.geo_id AND d.district_type = 'NATIONAL_LOWER'
JOIN essentials.offices o
  ON o.district_id = d.id
 AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id = (SELECT id FROM essentials.elections WHERE name = 'NC 2026 Statewide General')
    AND r.office_id = o.id
);

COMMIT;
