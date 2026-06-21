-- 920_palmdale_headshots.sql — Phase 146 Wave 3 — AUDIT-ONLY (NOT registered in schema_migrations)
-- Only image GAP among the 5 current Palmdale members is Laura Bettencourt (-700657, created in Plan 02).
-- cityofpalmdaleca.gov is NOT WAF-blocked (HTTP 200, CivicEngage CMS) — her official portrait was downloaded
-- directly from documentID=13184 (216x288 PNG, clean professional portrait, US-flag bg, no superimposed text
-- over the face), cropped 4:5 FIRST then resized 600x750 Lanczos q90 JPEG, and uploaded to Storage
-- politician_photos/{uuid}-headshot.jpg (the canonical convention the other 4 rows use). type='default',
-- photo_license='press_use'. Verified correct person + clean framing (eyes ~1/3 from top) before upload.
--
-- Existing images (RESEARCH §4): Bishop/Loa = scraped_no_license but functional (left as-is, acceptable);
-- Alarcón = press_use canonical (left as-is). Ohlsen had TWO type='default' rows (an old-path scraped
-- duplicate + the canonical press_use row) — the old-path duplicate is removed here by its exact URL so every
-- current member has exactly one type='default' image.
--
-- AUDIT-ONLY: apply via raw SQL; do NOT register in schema_migrations (ledger stays at 919).
BEGIN;

-- Bettencourt (-700657): single type='default' press_use row, guarded NOT EXISTS
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/362f1ec5-20aa-4e7a-a00d-7f626ae70138-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -700657
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id AND pi.type='default');

-- Bettencourt photo_origin_url backfill (the official city ImageRepository source page)
UPDATE essentials.politicians
   SET photo_origin_url = 'https://www.cityofpalmdaleca.gov/ImageRepository/Document?documentID=13184'
 WHERE external_id = -700657 AND photo_origin_url IS NULL;

-- Ohlsen (692516): remove the stale old-path scraped duplicate, keeping the canonical press_use row,
-- so he has exactly one type='default' image. Targeted by exact URL only.
DELETE FROM essentials.politician_images pi
 USING essentials.politicians p
 WHERE pi.politician_id = p.id
   AND p.external_id = 692516
   AND pi.url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/cities/palmdale/eric-ohlsen.jpg';

COMMIT;

-- ============================================================
-- Post-apply full-roster image-coverage audit (run after COMMIT; expect 5 rows, each count=1):
-- ============================================================
-- SELECT p.external_id, p.full_name, COUNT(pi.*) AS default_images
-- FROM essentials.politicians p
-- LEFT JOIN essentials.politician_images pi ON pi.politician_id=p.id AND pi.type='default'
-- WHERE p.external_id IN (-201331,692504,-700657,692516,692518)
-- GROUP BY p.external_id, p.full_name ORDER BY p.external_id;
--
-- Ledger unchanged check (expect MAX still 919):
-- SELECT MAX(version) FROM supabase_migrations.schema_migrations;
