-- Migration 1073: Challenger headshots for 2026 statewide general races (AUDIT-ONLY)
--
-- Applied directly via the find-headshots flow (Supabase storage upload +
-- essentials.politicians / politician_images / race_candidates writes), NOT
-- re-runnable from this file (new records use random UUIDs; image bytes live in
-- the politician_photos bucket). Recorded here for traceability alongside the
-- race/candidate work in 1071-1072. Idempotent verification query only.
--
-- 9 challenger candidates seeded in 1072 now have headshots + linked politician
-- records. 7 NEW politician records created; 2 linked to EXISTING records:
--   Dan Cox            4a876d03  (new)  cc_by_sa  wikipedia
--   Andy Ellis         48593795  (new)  press_use gogreen2026.com  [head+shoulders crop of full-body shot]
--   James B. Rutledge  579020c7  (new)  press_use electjim.com
--   Sonya Dunn         47977cc4  (new)  press_use votesonyadunn.com [transparent PNG -> white composite]
--   Hannah Pingree     ac09c6dc  (new)  cc_by_sa  wikipedia
--   Bobby Charles      8aad9681  (new)  press_use ballotpedia
--   Rick Bennett       f64c1364  (new)  cc_by_sa  wikipedia
--   Christine Drazan   402a00be  (EXISTING — already had photo+stances; race_candidate linked only)
--   David Brock Smith  ae7e8d67  (EXISTING canonical, 27 stances, 0 img — headshot imported) press_use ballotpedia/OR-Leg
--
-- NOTE: a duplicate David Brock Smith record exists (5350c0ba, 3 stances) — the
-- race_candidate was linked to the richer 27-stance record (ae7e8d67). The
-- duplicate is left for a future merge/cleanup pass.

-- Verify: all 9 challenger race_candidates are linked and resolve a photo.
SELECT r.position_name, rc.full_name,
       (rc.politician_id IS NOT NULL) AS linked,
       (COALESCE(rc.photo_url, (SELECT url FROM essentials.politician_images pi
          WHERE pi.politician_id = rc.politician_id AND pi.type='default' LIMIT 1)) IS NOT NULL) AS has_photo
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
WHERE rc.id IN (
  '0ba4ed07-3200-4456-8c1f-ba75ad547369','19fb07c2-1153-4912-8246-c001803d7241',
  '3e3245ac-949b-452d-803c-6f049c989fc2','c4b5aa3a-077d-402e-9beb-a0fb91ac5bdf',
  'c0ba9c13-bf0d-476b-be14-6c4ef305a30c','6187ca39-39e1-4700-8d71-cc1df55da34e',
  '53bcb464-b212-4935-b1ea-96a960475f85','389f1f05-40db-42c3-8e62-239561ea0aed',
  '80fa97df-d096-4185-898f-c3594f3c5ef4'
)
ORDER BY r.position_name, rc.full_name;
