-- 1140_seed_nj_2026_house_elections_races.sql
-- Phase 157 Wave 1 (157-01): author the NJ 2026 Statewide General election and the 12 NJ US House
-- race scaffold. Like TX/NY (mig 1109), FL (1115), PA/IL (1117), OH/GA/NC (1127), NJ had ZERO 2026
-- elections/races (all 12 rows in 154-field-table.csv carry a BLANK existing_race_id). This is the
-- create-races-first structural step; Wave 2 (157-03) wires race_candidates onto these races.
--
-- NJ HAS NO TRUE VACANCY (contrast GA-13 in mig 1127): NJ-12 (Watson Coleman) is a RETIREMENT — the
-- NJ-12 office AND her politician record already exist; NJ-11 (Mejia) is special-seated but already in
-- DB with its office. There is NO office-creation step in this phase. All 12 NJ NATIONAL_LOWER offices
-- already exist (live-verified: exactly 1 'U.S. House of Representatives' office per geo_id 3401..3412).
--
-- FIELD SOURCE: 154-FIELD-TABLE.md + 154-field-table.csv (Wikipedia
-- https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_Jersey +
-- newjerseyglobe "final list of who's running", human-reviewed in Phase 154). NJ primary already held
-- -> field is DECIDED.
--
-- ANTIPARTISAN INVARIANT (D-06): party is NOT stored on the race card; races.primary_party stays NULL
-- (a multi-candidate general has no single primary party). Party reads from the candidate's record
-- context downstream, never from race_candidates.
--
-- Schema notes (live-verified): elections.election_date is DATE; chamber resolved by EXACT name
-- 'U.S. House of Representatives'. office_id resolved by district geo_id join; NEVER NULL.
--
-- Idempotent: NOT EXISTS guards on (election name), (election_id, office_id). Re-run inserts 0 rows.

BEGIN;

-- 1) NJ 2026 Statewide General election (mirror the live OH/GA/NC/PA/IL rows; description NULL).
INSERT INTO essentials.elections (id, name, election_date, election_type, jurisdiction_level, state)
SELECT gen_random_uuid(), 'NJ 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'NJ'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections e WHERE e.name = 'NJ 2026 Statewide General');

-- 2) 12 NJ races (geo 3401..3412) on each district's existing U.S. House office.
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.elections WHERE name = 'NJ 2026 Statewide General'),
       o.id,
       'U.S. Representative District ' || v.cd,
       NULL, 1, NULL
FROM (VALUES
    ('3401','1'),('3402','2'),('3403','3'),('3404','4'),('3405','5'),
    ('3406','6'),('3407','7'),('3408','8'),('3409','9'),('3410','10'),
    ('3411','11'),('3412','12')
  ) AS v(geo_id, cd)
JOIN essentials.districts d
  ON d.geo_id = v.geo_id AND d.district_type = 'NATIONAL_LOWER'
JOIN essentials.offices o
  ON o.district_id = d.id
 AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id = (SELECT id FROM essentials.elections WHERE name = 'NJ 2026 Statewide General')
    AND r.office_id = o.id
);

COMMIT;
