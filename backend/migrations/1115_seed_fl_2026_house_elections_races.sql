-- 1115_seed_fl_2026_house_elections_races.sql
-- Phase 151 Wave 1 (151-01): author the FL 2026 election + the vacant FL-20 office + 28 PROVISIONAL
-- US House races scaffold. Like TX/NY (mig 1109), FL had ZERO 2026 elections/races; unlike TX/NY,
-- FL-20 (geo 1220) is a VACANT seat with NO essentials.offices row -> it is created HERE, FIRST,
-- before its race insert (RESEARCH Pitfall 4).
--
-- FIELD SOURCE: 148-field-table.csv (Wikipedia-sourced, human-reviewed in Phase 148). The official
-- FL DoE extractCanList.asp federal extract is fetchable but EMPTY for 2026 today (RESEARCH Q1), so
-- the 148 CSV is the documented source-of-truth for this provisional seed; DoE reconciliation defers
-- to Phase 153 (post-Aug-18 prune).
--
-- ANTIPARTISAN INVARIANT (D-05): party is NOT stored on the race card; races.primary_party stays NULL
-- (a crowded multi-candidate provisional general has no single primary party). D-04: every FL race is
-- marked PROVISIONAL via the description sentinel; Phase 153 flips it to nominee-final.
--
-- Schema notes (live-verified): elections.election_date is DATE (not timestamptz); chamber resolved by
-- EXACT name 'U.S. House of Representatives' (ILIKE 'U.S. House%%' is AMBIGUOUS — also matches
-- 'U.S. House of Representatives - Indiana Nth ...' rows). The single US House chamber all 27 FL House
-- offices share = c2facc31-7b13-428c-b7b9-32d0d3b95f76.
--
-- Idempotent: NOT EXISTS guards on (election name), (FL-20 geo office), (election_id, office_id).
-- Re-run inserts 0 rows.

BEGIN;

-- 1) FL 2026 Statewide General election (mirror CA 728d0074 row exactly; description left NULL).
INSERT INTO essentials.elections (id, name, election_date, election_type, jurisdiction_level, state)
SELECT gen_random_uuid(), 'FL 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'FL'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.elections e WHERE e.name = 'FL 2026 Statewide General'
);

-- 2) FL-20 (geo 1220) vacant-seat office — CREATED BEFORE its race (Pitfall 4). politician_id NULL,
--    is_vacant=true. Chamber resolved by exact name.
INSERT INTO essentials.offices
  (id, politician_id, chamber_id, district_id, title, representing_state,
   is_appointed_position, is_vacant, faces_retention_vote)
SELECT gen_random_uuid(),
       NULL,
       (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives'),
       d.id,
       'U.S. Representative',
       'FL',
       false,
       true,
       false
FROM essentials.districts d
WHERE d.geo_id = '1220' AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.districts dd ON dd.id = o.district_id
    WHERE dd.geo_id = '1220' AND dd.district_type = 'NATIONAL_LOWER'
  );

-- 3) 28 PROVISIONAL races (geo 1201..1228), each on its district's U.S. House office (incl. new FL-20).
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.elections WHERE name = 'FL 2026 Statewide General'),
       o.id,
       'U.S. Representative District ' || v.cd,
       NULL,
       1,
       'PROVISIONAL: pre-Aug-18-2026-primary qualified field; pruned to nominees in Phase 153'
FROM (VALUES
    ('1201','1'),
    ('1202','2'),
    ('1203','3'),
    ('1204','4'),
    ('1205','5'),
    ('1206','6'),
    ('1207','7'),
    ('1208','8'),
    ('1209','9'),
    ('1210','10'),
    ('1211','11'),
    ('1212','12'),
    ('1213','13'),
    ('1214','14'),
    ('1215','15'),
    ('1216','16'),
    ('1217','17'),
    ('1218','18'),
    ('1219','19'),
    ('1220','20'),
    ('1221','21'),
    ('1222','22'),
    ('1223','23'),
    ('1224','24'),
    ('1225','25'),
    ('1226','26'),
    ('1227','27'),
    ('1228','28')
  ) AS v(geo_id, cd)
JOIN essentials.districts d
  ON d.geo_id = v.geo_id AND d.district_type = 'NATIONAL_LOWER'
JOIN essentials.offices o
  ON o.district_id = d.id
 AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id = (SELECT id FROM essentials.elections WHERE name = 'FL 2026 Statewide General')
    AND r.office_id = o.id
);

COMMIT;
