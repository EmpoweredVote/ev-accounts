-- 1117_seed_pa_il_2026_house_elections_races.sql
-- Phase 155 Wave 1 (155-01): author the PA + IL 2026 Statewide General elections and the 17 PA + 17 IL
-- US House race scaffold. Like TX/NY (mig 1109) and FL (mig 1115), PA/IL had ZERO 2026 elections/races
-- (all 34 rows in 154-field-table.csv carry a BLANK existing_race_id). UNLIKE FL-20, PA/IL have NO
-- vacant seats needing an office row — all 17 PA + 17 IL NATIONAL_LOWER offices already exist
-- (live-verified: exactly 1 'U.S. House of Representatives' office per geo_id 42NN / 17NN). This is the
-- create-races-first structural step; Wave 2 (155-03/04) wires race_candidates onto these races.
--
-- FIELD SOURCE: 154-FIELD-TABLE.md + 154-field-table.csv (Wikipedia/SoS-sourced, human-reviewed in
-- Phase 154). PA/IL primaries already held -> field is DECIDED (not provisional like FL).
--
-- ANTIPARTISAN INVARIANT (D-06): party is NOT stored on the race card; races.primary_party stays NULL
-- (a multi-candidate general has no single primary party). Party reads from the candidate's record
-- context downstream, never from race_candidates.
--
-- Schema notes (live-verified): elections.election_date is DATE; the single US House chamber all PA/IL
-- House offices share = 'U.S. House of Representatives' (resolved by exact name). office_id resolved by
-- district geo_id join; NEVER NULL.
--
-- Idempotent: NOT EXISTS guards on (election name) and (election_id, office_id). Re-run inserts 0 rows.

BEGIN;

-- 1) PA + IL 2026 Statewide General elections (mirror the live CA/TX/NY/FL rows; description left NULL).
INSERT INTO essentials.elections (id, name, election_date, election_type, jurisdiction_level, state)
SELECT gen_random_uuid(), 'PA 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'PA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.elections e WHERE e.name = 'PA 2026 Statewide General'
);

INSERT INTO essentials.elections (id, name, election_date, election_type, jurisdiction_level, state)
SELECT gen_random_uuid(), 'IL 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'IL'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.elections e WHERE e.name = 'IL 2026 Statewide General'
);

-- 2) 17 PA races (geo 4201..4217) on each district's existing U.S. House office.
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.elections WHERE name = 'PA 2026 Statewide General'),
       o.id,
       'U.S. Representative District ' || v.cd,
       NULL,
       1,
       NULL
FROM (VALUES
    ('4201','1'),('4202','2'),('4203','3'),('4204','4'),('4205','5'),
    ('4206','6'),('4207','7'),('4208','8'),('4209','9'),('4210','10'),
    ('4211','11'),('4212','12'),('4213','13'),('4214','14'),('4215','15'),
    ('4216','16'),('4217','17')
  ) AS v(geo_id, cd)
JOIN essentials.districts d
  ON d.geo_id = v.geo_id AND d.district_type = 'NATIONAL_LOWER'
JOIN essentials.offices o
  ON o.district_id = d.id
 AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id = (SELECT id FROM essentials.elections WHERE name = 'PA 2026 Statewide General')
    AND r.office_id = o.id
);

-- 3) 17 IL races (geo 1701..1717) on each district's existing U.S. House office.
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.elections WHERE name = 'IL 2026 Statewide General'),
       o.id,
       'U.S. Representative District ' || v.cd,
       NULL,
       1,
       NULL
FROM (VALUES
    ('1701','1'),('1702','2'),('1703','3'),('1704','4'),('1705','5'),
    ('1706','6'),('1707','7'),('1708','8'),('1709','9'),('1710','10'),
    ('1711','11'),('1712','12'),('1713','13'),('1714','14'),('1715','15'),
    ('1716','16'),('1717','17')
  ) AS v(geo_id, cd)
JOIN essentials.districts d
  ON d.geo_id = v.geo_id AND d.district_type = 'NATIONAL_LOWER'
JOIN essentials.offices o
  ON o.district_id = d.id
 AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id = (SELECT id FROM essentials.elections WHERE name = 'IL 2026 Statewide General')
    AND r.office_id = o.id
);

COMMIT;
