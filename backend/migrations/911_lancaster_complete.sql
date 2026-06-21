-- 911_lancaster_complete.sql
-- Phase 145 (Lancaster deep-seed) Wave 2 — STRUCTURAL (registers in schema_migrations)
-- Roster turnover from the April 2026 election:
--   Part A: RETIRE Raj Malhi (-201280, lost) + Marvin Crist (686320, did not file) — preserve rows,
--           free their offices (03a0dae7 ex-Malhi, afd045ec ex-Crist).
--   Part B: CREATE Cedric White (-700655) + Rocio Castellanos (-700656) — April 2026 winners.
--   Part C: SEAT each into a freed office, syncing BOTH offices.politician_id AND politicians.office_id.
-- End roster = Mayor Parris + Council Hughes-Leslie/Mann/White/Castellanos (5), all bidirectionally linked.
-- DB-verified pre-flight 2026-06-20. Idempotent.

BEGIN;

-- Part A: retire the two departing members (preserve rows; NEVER delete) + free their offices
UPDATE essentials.politicians
SET is_active = false, office_id = NULL
WHERE external_id IN (-201280, 686320) AND (is_active OR office_id IS NOT NULL);

UPDATE essentials.offices
SET politician_id = NULL
WHERE id IN ('03a0dae7-4cce-41ca-a077-8f064b648ed5','afd045ec-357f-4061-838e-81e414781569')
  AND politician_id IS NOT NULL;

-- Part B: create the two new members (guarded; ext_id unique)
INSERT INTO essentials.politicians
  (id, external_id, full_name, first_name, last_name, party, source, is_active, is_appointed, is_incumbent, is_vacant)
VALUES
  (gen_random_uuid(), -700655, 'Cedric White', 'Cedric', 'White', '', 'cityoflancasterca.org', true, false, true, false)
ON CONFLICT (external_id) DO NOTHING;

INSERT INTO essentials.politicians
  (id, external_id, full_name, first_name, last_name, party, source, is_active, is_appointed, is_incumbent, is_vacant)
VALUES
  (gen_random_uuid(), -700656, 'Rocio Castellanos', 'Rocio', 'Castellanos', '', 'cityoflancasterca.org', true, false, true, false)
ON CONFLICT (external_id) DO NOTHING;

-- Part C: seat each into a freed at-large council office; sync BOTH pointers (D-03b)
-- White -> 03a0dae7 (ex-Malhi); Castellanos -> afd045ec (ex-Crist)
UPDATE essentials.offices SET politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -700655)
WHERE id = '03a0dae7-4cce-41ca-a077-8f064b648ed5';
UPDATE essentials.politicians SET office_id = '03a0dae7-4cce-41ca-a077-8f064b648ed5' WHERE external_id = -700655;

UPDATE essentials.offices SET politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -700656)
WHERE id = 'afd045ec-357f-4061-838e-81e414781569';
UPDATE essentials.politicians SET office_id = 'afd045ec-357f-4061-838e-81e414781569' WHERE external_id = -700656;

-- confirm official_count (already 5 from Plan 01)
UPDATE essentials.chambers SET official_count = 5
WHERE id = '9b9014b4-0106-417f-a104-ac2055fc8134' AND official_count IS DISTINCT FROM 5;

COMMIT;
