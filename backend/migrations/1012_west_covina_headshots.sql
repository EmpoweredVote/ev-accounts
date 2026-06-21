-- 1012_west_covina_headshots.sql
-- Phase 152 Wave 3 (WCOV-01): West Covina headshots — verify-and-fix the 5 current members.
-- AUDIT-ONLY raw SQL: does NOT register in supabase_migrations.schema_migrations (ledger stays 1011).
-- DB-verified + images processed/uploaded 2026-06-21 (152-03 Tasks 1-2). Committed to EV-Accounts.
--
-- All 5 pre-existing images were re-sourced/re-cropped to 600x750 (4:5) and uploaded to the canonical
-- Storage path politician_photos/{uuid}-headshot.jpg (x-upsert). Findings:
--   D1 Gutierrez  -- STORED IMAGE WAS THE WRONG PERSON (Brian Gutierrez the Chicago Fire soccer
--                    player, a name collision). Replaced with the real councilman from the official
--                    city portrait (documentID=1053). press_use.
--   D2 Lopez-Viado (Mayor) -- official city portrait (documentID=1054), re-cropped 600x750. press_use.
--   D3 Diaz       -- official city portrait (documentID=1056), re-cropped 600x750. press_use.
--   D4 Cantos (Mayor Pro Tem) -- city only had a low-res FULL-BODY shot (unusable as a headshot);
--                    operator supplied a head-and-shoulders portrait, processed 600x750. fair_use,
--                    no canonical source URL (photo_origin_url cleared).
--   D5 Wu         -- official city portrait (documentID=1055), re-cropped 600x750. press_use.
-- NOTE: the 4 city portraits are upscaled from ~150x190 CMS thumbnails (West Covina CivicEngage only
--   serves low-res) -- correct identity + clean 4:5 framing, acceptably soft. Operator-approved 2026-06-21.

BEGIN;

-- Canonical Storage path per member: politician_photos/{uuid}-headshot.jpg
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/22fc2cdc-2f51-4d81-8814-4b54b2bc6582-headshot.jpg',
       photo_license = 'press_use'
 WHERE politician_id = '22fc2cdc-2f51-4d81-8814-4b54b2bc6582' AND type = 'default'; -- Gutierrez D1
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/2872d7a4-612b-4d9d-9531-699e3c344002-headshot.jpg',
       photo_license = 'press_use'
 WHERE politician_id = '2872d7a4-612b-4d9d-9531-699e3c344002' AND type = 'default'; -- Lopez-Viado D2
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/f5bf4ec4-7d1b-460e-b4e2-539826c59596-headshot.jpg',
       photo_license = 'press_use'
 WHERE politician_id = 'f5bf4ec4-7d1b-460e-b4e2-539826c59596' AND type = 'default'; -- Diaz D3
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ecc57cd4-aebc-49b7-b324-e28a0aaf05df-headshot.jpg',
       photo_license = 'fair_use'
 WHERE politician_id = 'ecc57cd4-aebc-49b7-b324-e28a0aaf05df' AND type = 'default'; -- Cantos D4 (operator-supplied)
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/1bb5c062-9b9d-44de-820b-c3efe0d08222-headshot.jpg',
       photo_license = 'press_use'
 WHERE politician_id = '1bb5c062-9b9d-44de-820b-c3efe0d08222' AND type = 'default'; -- Wu D5

-- photo_origin_url backfill (official city documentID URLs for the 4 city-sourced; clear Cantos' stale 1052).
UPDATE essentials.politicians SET photo_origin_url = 'https://www.westcovina.gov/ImageRepository/Document?documentID=1053'
 WHERE external_id = -201108 AND photo_origin_url IS DISTINCT FROM 'https://www.westcovina.gov/ImageRepository/Document?documentID=1053'; -- Gutierrez
UPDATE essentials.politicians SET photo_origin_url = 'https://www.westcovina.gov/ImageRepository/Document?documentID=1054'
 WHERE external_id = 687361 AND photo_origin_url IS DISTINCT FROM 'https://www.westcovina.gov/ImageRepository/Document?documentID=1054'; -- Lopez-Viado
UPDATE essentials.politicians SET photo_origin_url = 'https://www.westcovina.gov/ImageRepository/Document?documentID=1056'
 WHERE external_id = -201107 AND photo_origin_url IS DISTINCT FROM 'https://www.westcovina.gov/ImageRepository/Document?documentID=1056'; -- Diaz
UPDATE essentials.politicians SET photo_origin_url = NULL
 WHERE external_id = 687365 AND photo_origin_url IS NOT NULL; -- Cantos (operator-supplied; no canonical URL)
UPDATE essentials.politicians SET photo_origin_url = 'https://www.westcovina.gov/ImageRepository/Document?documentID=1055'
 WHERE external_id = 687367 AND photo_origin_url IS DISTINCT FROM 'https://www.westcovina.gov/ImageRepository/Document?documentID=1055'; -- Wu

COMMIT;

-- ============================ POST-VERIFICATION (audit-only; ledger UNCHANGED at 1011) =============================
-- 1. each of the 5 current members has exactly one type='default' row at {uuid}-headshot.jpg
--    SELECT p.external_id, COUNT(pi.*) FROM essentials.politicians p
--      LEFT JOIN essentials.politician_images pi ON pi.politician_id=p.id AND pi.type='default'
--      WHERE p.external_id IN (-201108,687361,-201107,687365,687367) GROUP BY p.external_id;  -> all 1
-- 2. SELECT MAX(version::int) FROM supabase_migrations.schema_migrations;  -> unchanged (1011)
