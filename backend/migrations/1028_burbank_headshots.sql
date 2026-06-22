-- 1028_burbank_headshots.sql
-- Phase 154 (Burbank deep-seed) Wave 3 — AUDIT-ONLY (raw SQL, NOT registered in
-- schema_migrations; ledger stays 1027). Idempotent.
--
-- 3 existing images (Perez, Anthony, Mullins) verified-and-fixed: old la_county/cities/burbank/
--   path + scraped_no_license replaced with canonical {uuid}-headshot.jpg + press_use.
-- 2 greenfield INSERTs (Rizzotti, Takahashi — 0 images in DB).
-- Source: burbankca.gov Liferay adaptive-media system (Chrome UA required; HTTP 200 confirmed).
-- URL pattern: https://www.burbankca.gov/o/adaptive-media/image/{fileEntryId}/Preview-1000x0/{filename}.jpg?t={ts}
-- WRONG-PERSON GUARD (West Covina lesson): each portrait was visually verified as the actual
-- Burbank official before upload. Mullins special check: confirmed Dec 2024 portrait is a
-- council-member portrait (NOT stale City-Clerk headshot).
-- Canonical CDN host: kxsdzaojfaibhuzmclfq.storage.supabase.co
-- photo_origin_url is set on essentials.politicians (NOT on politician_images -- no such column there).
--
-- fileEntryId reference table:
--   Takahashi  ea6f7109  fileEntryId 3949213  (Dec 8 2025 portrait;  GREENFIELD INSERT)
--   Rizzotti   a83a63a8  fileEntryId 3940848  (Dec 15 2025 portrait; GREENFIELD INSERT)
--   Mullins    f933bd87  fileEntryId 3176813  (Dec 23 2024 portrait; UPDATE — council-member portrait CONFIRMED)
--   Anthony    6c4c7919  fileEntryId 2161825  (Dec 19 2022 portrait; UPDATE)
--   Perez      96f91743  fileEntryId 2168721  (Dec 22 2022 portrait; UPDATE)

BEGIN;

-- ---- Perez 663414 pol 96f91743: verify + re-upload (existing 1 image — old la_county path) ----
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/96f91743-def6-436c-9537-a4b836c1b3eb-headshot.jpg',
       type = 'default', photo_license = 'press_use'
 WHERE politician_id = '96f91743-def6-436c-9537-a4b836c1b3eb' AND type = 'default';

-- ---- Anthony -201161 pol 6c4c7919: verify + re-upload (existing 1 image — old la_county path) ----
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7-headshot.jpg',
       type = 'default', photo_license = 'press_use'
 WHERE politician_id = '6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7' AND type = 'default';

-- ---- Mullins -201162 pol f933bd87: verify + re-upload (existing 1 image — old la_county path)
--   MULLINS SPECIAL CHECK: Dec 2024 portrait (fileEntryId 3176813) confirmed council-member portrait,
--   NOT stale City-Clerk headshot. Visual inspection passed. ----
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f933bd87-d397-4ef1-873b-57559b629000-headshot.jpg',
       type = 'default', photo_license = 'press_use'
 WHERE politician_id = 'f933bd87-d397-4ef1-873b-57559b629000' AND type = 'default';

-- ---- Rizzotti 663419 pol a83a63a8: greenfield INSERT (0 images; guarded NOT EXISTS) ----
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), 'a83a63a8-3e0f-4a2e-9226-8c0cd26a1349',
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a83a63a8-3e0f-4a2e-9226-8c0cd26a1349-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
   WHERE politician_id = 'a83a63a8-3e0f-4a2e-9226-8c0cd26a1349' AND type = 'default');

-- ---- Takahashi 663418 pol ea6f7109: greenfield INSERT (0 images; guarded NOT EXISTS) ----
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), 'ea6f7109-6067-4a48-bbdf-2a8b9cffe05f',
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ea6f7109-6067-4a48-bbdf-2a8b9cffe05f-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
   WHERE politician_id = 'ea6f7109-6067-4a48-bbdf-2a8b9cffe05f' AND type = 'default');

-- ---- photo_origin_url backfill on essentials.politicians (guarded IS DISTINCT FROM) ----
-- Perez 663414 — Dec 22 2022 portrait (fileEntryId 2168721)
UPDATE essentials.politicians
   SET photo_origin_url = 'https://www.burbankca.gov/o/adaptive-media/image/2168721/Preview-1000x0/20221222-nikki-perez-portrait-001.jpg?t=1671722858156'
 WHERE external_id = 663414
   AND photo_origin_url IS DISTINCT FROM 'https://www.burbankca.gov/o/adaptive-media/image/2168721/Preview-1000x0/20221222-nikki-perez-portrait-001.jpg?t=1671722858156';

-- Takahashi 663418 — Dec 8 2025 portrait (fileEntryId 3949213)
UPDATE essentials.politicians
   SET photo_origin_url = 'https://www.burbankca.gov/o/adaptive-media/image/3949213/Preview-1000x0/20251208-portrait-Tamala-Takahashi-001.jpg?t=1766442190215'
 WHERE external_id = 663418
   AND photo_origin_url IS DISTINCT FROM 'https://www.burbankca.gov/o/adaptive-media/image/3949213/Preview-1000x0/20251208-portrait-Tamala-Takahashi-001.jpg?t=1766442190215';

-- Rizzotti 663419 — Dec 15 2025 portrait (fileEntryId 3940848)
UPDATE essentials.politicians
   SET photo_origin_url = 'https://www.burbankca.gov/o/adaptive-media/image/3940848/Preview-1000x0/20251215-portrait-Rizzotti-final.jpg?t=1765923026167'
 WHERE external_id = 663419
   AND photo_origin_url IS DISTINCT FROM 'https://www.burbankca.gov/o/adaptive-media/image/3940848/Preview-1000x0/20251215-portrait-Rizzotti-final.jpg?t=1765923026167';

-- Anthony -201161 — Dec 19 2022 portrait (fileEntryId 2161825)
UPDATE essentials.politicians
   SET photo_origin_url = 'https://www.burbankca.gov/o/adaptive-media/image/2161825/Preview-1000x0/20221219-konstantine-anthony-portrait-001+%281%29.jpg?t=1671524088528'
 WHERE external_id = -201161
   AND photo_origin_url IS DISTINCT FROM 'https://www.burbankca.gov/o/adaptive-media/image/2161825/Preview-1000x0/20221219-konstantine-anthony-portrait-001+%281%29.jpg?t=1671524088528';

-- Mullins -201162 — Dec 23 2024 portrait (fileEntryId 3176813)
UPDATE essentials.politicians
   SET photo_origin_url = 'https://www.burbankca.gov/o/adaptive-media/image/3176813/Preview-1000x0/20241223-zizette-mullins-portrait-002.jpg?t=1734997758573'
 WHERE external_id = -201162
   AND photo_origin_url IS DISTINCT FROM 'https://www.burbankca.gov/o/adaptive-media/image/3176813/Preview-1000x0/20241223-zizette-mullins-portrait-002.jpg?t=1734997758573';

COMMIT;

-- ============================ POST-VERIFICATION (audit-only) =============================
-- 1. each of the 5 officials has exactly 1 type='default' image
--    SELECT p.external_id, COUNT(pi.*) FILTER (WHERE pi.type='default') n
--      FROM essentials.politicians p
--      LEFT JOIN essentials.politician_images pi ON pi.politician_id=p.id
--      WHERE p.external_id IN (663414,663418,663419,-201161,-201162)
--      GROUP BY p.external_id;  -> every n=1
-- 2. all 5 urls = politician_photos/{their_uuid}-headshot.jpg (canonical host .storage.supabase.co), all HTTP 200, all 600x750
-- 3. photo_origin_url set on all 5 politicians (burbankca.gov adaptive-media URLs)
-- 4. all portraits visually verified correct person + no superimposed text (human-verify checkpoint)
--    Mullins: council-member portrait (Dec 2024) confirmed — NOT stale City-Clerk headshot
-- 5. schema_migrations MAX UNCHANGED at 1027 (audit-only; this file is NOT registered)
