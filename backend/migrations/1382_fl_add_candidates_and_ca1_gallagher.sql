-- 1382: FL missing ballot-qualified candidates + CA-1 Gallagher flag removal (Phase 164.2-04 Task 3)
--
-- WHY: The 2026-07-21 FL field audit found seven ballot-qualified candidates missing from
--   /elections, and CA-1 (geo_id 0601) wrongly flags James Gallagher (external_id -6002003)
--   as incumbent -- the seat is open/redrawn and he is not the seated member there.
--
-- EFFECT: adds 7 FL politicians + active race_candidates rows (NON-NULL politician_id,
--   collision-free external_ids in each district band, dedup-checked against live names),
--   and clears the CA-1 Gallagher is_incumbent flag.
--     FL-10 (1210): Stuart Farber (R), Willie Montague (R),
--                   Angela Marie Walls-Windhauser (R), Vibert White (R)
--     FL-6  (1206): Michael Gist (NPA = Florida no-party-affiliation)
--     FL-11 (1211): Mike Wilnau (R), Barbie Harden Hall (D)
--   Party recorded on politicians.party only; NEVER on the candidate card (races.primary_party).
--
-- external_id scheme (FL challenger band, empirical): -(1210000 + district*100 + seq).
--   FL-10 seq 01-04 -> -1211001..-1211004 ; FL-6 next seq 11 -> -1210611 ;
--   FL-11 next seqs 10,11 -> -1211110,-1211111 (Royal Webster took seq 09 in mig 1381).
--
-- Idempotent: NOT EXISTS guards on every insert; guarded UPDATE on the CA-1 flag.

BEGIN;

-- 1) Insert the 7 new politicians (challengers: is_incumbent=false explicitly -- the column
--    defaults TRUE). Guarded by external_id NOT EXISTS.
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, party, is_incumbent, is_active, source)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, v.party, false, true, v.source
FROM (VALUES
  (-1211001, 'Stuart Farber', 'Stuart', 'Farber', 'Republican',
     'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_10'),
  (-1211002, 'Willie Montague', 'Willie', 'Montague', 'Republican',
     'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_10'),
  (-1211003, 'Angela Marie Walls-Windhauser', 'Angela Marie', 'Walls-Windhauser', 'Republican',
     'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_10'),
  (-1211004, 'Vibert White', 'Vibert', 'White', 'Republican',
     'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_10'),
  (-1210611, 'Michael Gist', 'Michael', 'Gist', 'NPA',
     'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_6'),
  (-1211110, 'Mike Wilnau', 'Mike', 'Wilnau', 'Republican',
     'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_11'),
  (-1211111, 'Barbie Harden Hall', 'Barbie', 'Harden Hall', 'Democratic',
     'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_11')
) AS v(external_id, full_name, first_name, last_name, party, source)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);

-- 2) Link each new politician to its district's FL 2026 Statewide General race.
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source, external_id)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active', p.source, p.external_id::text
FROM essentials.politicians p
JOIN (VALUES
  (-1211001, '1210'), (-1211002, '1210'), (-1211003, '1210'), (-1211004, '1210'),
  (-1210611, '1206'),
  (-1211110, '1211'), (-1211111, '1211')
) AS m(external_id, geo_id) ON m.external_id = p.external_id
JOIN essentials.districts d ON d.geo_id = m.geo_id AND d.district_type = 'NATIONAL_LOWER'
JOIN essentials.offices   o ON o.district_id = d.id
JOIN essentials.races     r ON r.office_id = o.id
JOIN essentials.elections e ON e.id = r.election_id AND e.name = 'FL 2026 Statewide General'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

-- 3) CA-1 (geo_id 0601): remove the incorrect incumbent flag on James Gallagher (-6002003).
UPDATE essentials.race_candidates rc
SET is_incumbent = false, updated_at = now()
FROM essentials.races r
JOIN essentials.offices   o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
WHERE rc.race_id = r.id
  AND d.geo_id = '0601' AND d.district_type = 'NATIONAL_LOWER'
  AND rc.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -6002003)
  AND rc.is_incumbent = true;

COMMIT;
