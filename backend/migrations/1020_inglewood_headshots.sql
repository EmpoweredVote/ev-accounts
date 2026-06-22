-- 1020_inglewood_headshots.sql
-- Phase 153 (Inglewood deep-seed) Wave 3 — AUDIT-ONLY (raw SQL, NOT registered in
-- schema_migrations; ledger stays 1019). Idempotent.
--
-- 5 current officials each get exactly one type='default' headshot at the canonical Storage path
-- politician_photos/{pol_uuid}-headshot.jpg, sourced from cityofinglewood.org ImageRepository
-- (NO-WAF, HTTP 200), cropped 4:5 -> 600x750 Lanczos q90, uploaded x-upsert. WRONG-PERSON GUARD
-- (West Covina lesson): each portrait was visually verified as the actual Inglewood official
-- (no name-collision -- e.g. NOT Eloy Morales the painter / unrelated James Butts) with no
-- superimposed text/graphics, before upload.
--
-- Source documentIDs (cityofinglewood.org/ImageRepository/Document?documentID=NNNN), all press_use:
--   Butts  -200740  pol f5775ca1  <- 20637  (UPDATE old {uuid}/default.jpeg cc_by_sa row -> canonical)
--   Gray    666261  pol 7a04bf87  <- 21642  (UPDATE existing press_use row -> current portrait)
--   Padilla -701002 pol 123c9a42  <- 21957  (greenfield INSERT -- created in Wave 2, 0 images)
--   Eloy    666263  pol 6ed19c10  <- 21958  (UPDATE the Wave-1 migrated row -> current D3 portrait; Pitfall 3: UPDATE not INSERT)
--   Faulk   666264  pol 729bc539  <- 21989  (DEDUP: delete scraped row aa6601a7, UPDATE kept row 7db1ca7c -> current portrait)
--
-- Canonical CDN host: kxsdzaojfaibhuzmclfq.storage.supabase.co (matches find-headshots skill + existing rows).
-- photo_origin_url is set on essentials.politicians (NOT on politician_images -- the image table has no such column).

BEGIN;

-- ---- Faulk DEDUP (2 -> 1): delete the older scraped row, keep + refresh the canonical row ----
DELETE FROM essentials.politician_images
 WHERE id = 'aa6601a7-d5e9-4f54-9cc3-d4ae8ed75c8f'
   AND politician_id = '729bc539-3175-4e5d-96ba-c18768890e1e'
   AND type = 'default';
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/729bc539-3175-4e5d-96ba-c18768890e1e-headshot.jpg',
       type = 'default', photo_license = 'press_use'
 WHERE id = '7db1ca7c-1f3b-4a98-ae90-1f1024d0f674';

-- ---- Eloy 666263: UPDATE the Wave-1 migrated row to the current D3 portrait (do NOT insert a 2nd) ----
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6ed19c10-7b34-47f0-8705-0d154271e362-headshot.jpg',
       type = 'default', photo_license = 'press_use'
 WHERE id = '95919ace-43ba-4d09-bd29-5d9ed45e33f3';

-- ---- Butts -200740: UPDATE old {uuid}/default.jpeg cc_by_sa row -> canonical press_use ----
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f5775ca1-99f4-4cc2-acf2-5afaacdd94b3-headshot.jpg',
       type = 'default', photo_license = 'press_use'
 WHERE id = '851d5605-4a05-4fe9-8cba-410389449310';

-- ---- Gray 666261: UPDATE existing press_use row -> current portrait (21642) ----
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7a04bf87-ab95-4ae7-a142-9899662637b1-headshot.jpg',
       type = 'default', photo_license = 'press_use'
 WHERE id = '00495e7a-6e2c-4af5-9725-89b777c77baf';

-- ---- Padilla -701002: greenfield INSERT (0 images; guarded NOT EXISTS on type='default') ----
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), '123c9a42-5715-4ab2-a8bd-76e7adbca27b',
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/123c9a42-5715-4ab2-a8bd-76e7adbca27b-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
   WHERE politician_id = '123c9a42-5715-4ab2-a8bd-76e7adbca27b' AND type = 'default');

-- ---- photo_origin_url backfill on essentials.politicians (guarded IS DISTINCT FROM) ----
UPDATE essentials.politicians SET photo_origin_url = 'https://www.cityofinglewood.org/ImageRepository/Document?documentID=20637'
 WHERE external_id = -200740 AND photo_origin_url IS DISTINCT FROM 'https://www.cityofinglewood.org/ImageRepository/Document?documentID=20637'; -- Butts
UPDATE essentials.politicians SET photo_origin_url = 'https://www.cityofinglewood.org/ImageRepository/Document?documentID=21642'
 WHERE external_id = 666261 AND photo_origin_url IS DISTINCT FROM 'https://www.cityofinglewood.org/ImageRepository/Document?documentID=21642'; -- Gray
UPDATE essentials.politicians SET photo_origin_url = 'https://www.cityofinglewood.org/ImageRepository/Document?documentID=21957'
 WHERE external_id = -701002 AND photo_origin_url IS DISTINCT FROM 'https://www.cityofinglewood.org/ImageRepository/Document?documentID=21957'; -- Padilla
UPDATE essentials.politicians SET photo_origin_url = 'https://www.cityofinglewood.org/ImageRepository/Document?documentID=21958'
 WHERE external_id = 666263 AND photo_origin_url IS DISTINCT FROM 'https://www.cityofinglewood.org/ImageRepository/Document?documentID=21958'; -- Eloy
UPDATE essentials.politicians SET photo_origin_url = 'https://www.cityofinglewood.org/ImageRepository/Document?documentID=21989'
 WHERE external_id = 666264 AND photo_origin_url IS DISTINCT FROM 'https://www.cityofinglewood.org/ImageRepository/Document?documentID=21989'; -- Faulk

COMMIT;

-- ============================ POST-VERIFICATION (audit-only) =============================
-- 1. each of the 5 officials has exactly 1 type='default' image (Faulk deduped; Eloy single — no Pitfall 3)
-- 2. all 5 urls = politician_photos/{their_uuid}-headshot.jpg (canonical host), all HTTP 200, all 600x750
-- 3. photo_origin_url set on all 5 politicians (cityofinglewood.org documentIDs)
-- 4. all portraits visually verified correct person + no superimposed text (Wave-3 human-verify checkpoint)
-- 5. schema_migrations MAX UNCHANGED at 1019 (audit-only; this file is NOT registered)
