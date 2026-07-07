-- 1250_seed_nv_2026_house_candidates.sql
-- Phase 165-01: NV CANDIDATES-ONLY seed onto the 4 PRE-EXISTING NV U.S. House races
--   ('NV 2026 Statewide General'; NO elections/races INSERT — reuse existing race UUIDs).
--   5 new NV politicians (-320174/-320175/-320301/-320479/-320480, D-04 floors live-confirmed)
--   + 5 challenger race_candidates + the Lynn Chapman NULL-pid FIX: politician created at
--   -320251 (NV-2 seq 51; no live Chapman record 2026-07-07), then UPDATE of the existing
--   race_candidates row 08dfb911-9ddc-4c0d-85a2-fb14884a9160 — never a second Chapman row.
--   DECIDED field -> NOT PROVISIONAL. NOT EXISTS guards; sqlStr()-escaped. ANTIPARTISAN: party never stored.
BEGIN;

-- (a) 5 new NV politicians + Chapman (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -320174, 'Bobby Khan', 'Bobby', 'Khan', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -320174);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -320175, 'Steven St John', 'Steven', 'St John', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -320175);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -320301, 'Jon Kamerath', 'Jon', 'Kamerath', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -320301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -320479, 'Russell Best', 'Russell', 'Best', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -320479);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -320480, 'William Johnson', 'William', 'Johnson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -320480);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -320251, 'Lynn Chapman', 'Lynn', 'Chapman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -320251);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'a5295941-38b1-4c7f-8edf-39097ad3fb0a'::uuid, p.id, 'Bobby Khan', 'Bobby', 'Khan', false, 'active', 'NV SoS 2026 general candidate list (decided; nvsos.gov/home/showpublisheddocument/20105)'
FROM essentials.politicians p
WHERE p.external_id = -320174
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'a5295941-38b1-4c7f-8edf-39097ad3fb0a'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'a5295941-38b1-4c7f-8edf-39097ad3fb0a'::uuid, p.id, 'Steven St John', 'Steven', 'St John', false, 'active', 'NV SoS 2026 general candidate list (decided; nvsos.gov/home/showpublisheddocument/20105)'
FROM essentials.politicians p
WHERE p.external_id = -320175
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'a5295941-38b1-4c7f-8edf-39097ad3fb0a'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '79e7fb35-a73a-478c-847d-553e9ad11e7c'::uuid, p.id, 'Jon Kamerath', 'Jon', 'Kamerath', false, 'active', 'NV SoS 2026 general candidate list (decided; nvsos.gov/home/showpublisheddocument/20105)'
FROM essentials.politicians p
WHERE p.external_id = -320301
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '79e7fb35-a73a-478c-847d-553e9ad11e7c'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '81eb1a27-b710-42c3-a27c-a2c0153c2820'::uuid, p.id, 'Russell Best', 'Russell', 'Best', false, 'active', 'NV SoS 2026 general candidate list (decided; nvsos.gov/home/showpublisheddocument/20105)'
FROM essentials.politicians p
WHERE p.external_id = -320479
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '81eb1a27-b710-42c3-a27c-a2c0153c2820'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '81eb1a27-b710-42c3-a27c-a2c0153c2820'::uuid, p.id, 'William Johnson', 'William', 'Johnson', false, 'active', 'NV SoS 2026 general candidate list (decided; nvsos.gov/home/showpublisheddocument/20105)'
FROM essentials.politicians p
WHERE p.external_id = -320480
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '81eb1a27-b710-42c3-a27c-a2c0153c2820'::uuid AND rc.politician_id = p.id);

-- (b) Chapman NULL-pid FIX (UPDATE existing row; no new race_candidates row)
UPDATE essentials.race_candidates
SET politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -320251)
WHERE id = '08dfb911-9ddc-4c0d-85a2-fb14884a9160'::uuid
  AND politician_id IS NULL;

COMMIT;
