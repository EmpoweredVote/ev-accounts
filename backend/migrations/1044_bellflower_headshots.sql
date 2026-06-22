-- 1044_bellflower_headshots.sql
-- Phase 156 Wave 3 (BLFL-01): Bellflower council headshots.
-- AUDIT-ONLY (raw SQL; NOT registered in supabase_migrations.schema_migrations). Idempotent.
--
-- All 5 portraits sourced from bellflower.ca.gov /photo_gallery/Government/City Council/ (NO-WAF
-- Revize CMS, RESEARCH-verified HTTP 200), processed 4:5 crop FIRST -> 600x750 Lanczos q90, uploaded
-- to Supabase Storage bucket politician_photos at {politician_id}-headshot.jpg (x-upsert, HTTP 200).
-- First-pass visual check (orchestrator, via image render): all 5 are clean official council
-- portraits — correct head framing, neutral backdrop, City of Bellflower lapel pins, NO superimposed
-- text/graphics. Koops's pin reads 'Council Member' (corroborates he is NOT Mayor — stale bio URL).
-- Santa Ines (D3, new -701003) sourced from /photo_gallery/ (the /revize_photo_gallery/ variant 404s).
--
-- This migration only sets DB rows: ensures each of the 5 current officials has exactly one
-- type='default' politician_images row pointing at the new headshot.jpg, and records the real
-- bellflower.ca.gov source on politicians.photo_origin_url.
-- politician_images columns: id, politician_id, url, type, photo_license, focal_point.
-- photo_origin_url lives on essentials.politicians (NOT politician_images).
-- OUT OF SCOPE: Bellflower Unified gov f85ca154.

BEGIN;

-- Ray Dunton (D5) pol 31c35458
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/31c35458-6cc0-43ad-b431-841846e81875-headshot.jpg',
       photo_license = 'City of Bellflower official council portrait (government work) — bellflower.ca.gov'
 WHERE politician_id = '31c35458-6cc0-43ad-b431-841846e81875' AND type = 'default';
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '31c35458-6cc0-43ad-b431-841846e81875',
       'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/31c35458-6cc0-43ad-b431-841846e81875-headshot.jpg',
       'default', 'City of Bellflower official council portrait (government work) — bellflower.ca.gov'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='31c35458-6cc0-43ad-b431-841846e81875' AND type='default');
UPDATE essentials.politicians SET photo_origin_url = 'https://bellflower.ca.gov/photo_gallery/Government/City Council/dunton web.jpg'
 WHERE id = '31c35458-6cc0-43ad-b431-841846e81875' AND photo_origin_url IS DISTINCT FROM 'https://bellflower.ca.gov/photo_gallery/Government/City Council/dunton web.jpg';

-- Dan Koops (D2) pol dd2c2cfd
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/dd2c2cfd-401f-4b35-916f-caba8ca9b722-headshot.jpg',
       photo_license = 'City of Bellflower official council portrait (government work) — bellflower.ca.gov'
 WHERE politician_id = 'dd2c2cfd-401f-4b35-916f-caba8ca9b722' AND type = 'default';
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'dd2c2cfd-401f-4b35-916f-caba8ca9b722',
       'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/dd2c2cfd-401f-4b35-916f-caba8ca9b722-headshot.jpg',
       'default', 'City of Bellflower official council portrait (government work) — bellflower.ca.gov'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='dd2c2cfd-401f-4b35-916f-caba8ca9b722' AND type='default');
UPDATE essentials.politicians SET photo_origin_url = 'https://bellflower.ca.gov/photo_gallery/Government/City Council/koops web.jpg'
 WHERE id = 'dd2c2cfd-401f-4b35-916f-caba8ca9b722' AND photo_origin_url IS DISTINCT FROM 'https://bellflower.ca.gov/photo_gallery/Government/City Council/koops web.jpg';

-- Wendi Morse (D1) pol d18dcb81
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/d18dcb81-ad41-468f-9b12-a70ed21fd3a7-headshot.jpg',
       photo_license = 'City of Bellflower official council portrait (government work) — bellflower.ca.gov'
 WHERE politician_id = 'd18dcb81-ad41-468f-9b12-a70ed21fd3a7' AND type = 'default';
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd18dcb81-ad41-468f-9b12-a70ed21fd3a7',
       'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/d18dcb81-ad41-468f-9b12-a70ed21fd3a7-headshot.jpg',
       'default', 'City of Bellflower official council portrait (government work) — bellflower.ca.gov'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='d18dcb81-ad41-468f-9b12-a70ed21fd3a7' AND type='default');
UPDATE essentials.politicians SET photo_origin_url = 'https://bellflower.ca.gov/photo_gallery/Government/City Council/morse web.jpg'
 WHERE id = 'd18dcb81-ad41-468f-9b12-a70ed21fd3a7' AND photo_origin_url IS DISTINCT FROM 'https://bellflower.ca.gov/photo_gallery/Government/City Council/morse web.jpg';

-- Victor A. Sanchez (D4, Mayor Pro Tem) pol 4384a5d8
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/4384a5d8-68b2-4e24-81e2-5208f5c61a34-headshot.jpg',
       photo_license = 'City of Bellflower official council portrait (government work) — bellflower.ca.gov'
 WHERE politician_id = '4384a5d8-68b2-4e24-81e2-5208f5c61a34' AND type = 'default';
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '4384a5d8-68b2-4e24-81e2-5208f5c61a34',
       'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/4384a5d8-68b2-4e24-81e2-5208f5c61a34-headshot.jpg',
       'default', 'City of Bellflower official council portrait (government work) — bellflower.ca.gov'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='4384a5d8-68b2-4e24-81e2-5208f5c61a34' AND type='default');
UPDATE essentials.politicians SET photo_origin_url = 'https://bellflower.ca.gov/photo_gallery/Government/City Council/sanchez web.jpg'
 WHERE id = '4384a5d8-68b2-4e24-81e2-5208f5c61a34' AND photo_origin_url IS DISTINCT FROM 'https://bellflower.ca.gov/photo_gallery/Government/City Council/sanchez web.jpg';

-- Sonny R. Santa Ines (D3, Mayor) pol a4ff4532 — NEW image (no prior row)
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/a4ff4532-57d7-49e1-8eea-9313ce347d53-headshot.jpg',
       photo_license = 'City of Bellflower official council portrait (government work) — bellflower.ca.gov'
 WHERE politician_id = 'a4ff4532-57d7-49e1-8eea-9313ce347d53' AND type = 'default';
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'a4ff4532-57d7-49e1-8eea-9313ce347d53',
       'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/a4ff4532-57d7-49e1-8eea-9313ce347d53-headshot.jpg',
       'default', 'City of Bellflower official council portrait (government work) — bellflower.ca.gov'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='a4ff4532-57d7-49e1-8eea-9313ce347d53' AND type='default');
UPDATE essentials.politicians SET photo_origin_url = 'https://bellflower.ca.gov/photo_gallery/Government/City Council/Santa Ines web.jpg'
 WHERE id = 'a4ff4532-57d7-49e1-8eea-9313ce347d53' AND photo_origin_url IS DISTINCT FROM 'https://bellflower.ca.gov/photo_gallery/Government/City Council/Santa Ines web.jpg';

COMMIT;

-- ============================ POST-VERIFICATION =============================
-- Each of the 5 has exactly one type='default' image at the {uuid}-headshot.jpg path + photo_origin_url set:
--   SELECT p.external_id, p.full_name, p.photo_origin_url, COUNT(pi.id) FILTER (WHERE pi.type='default') img_ct,
--          MAX(pi.url) FILTER (WHERE pi.type='default') url
--   FROM essentials.politicians p LEFT JOIN essentials.politician_images pi ON pi.politician_id=p.id
--   WHERE p.external_id IN (-200583,-201149,-201150,-201151,-701003)
--   GROUP BY p.external_id, p.full_name, p.photo_origin_url ORDER BY p.external_id;
-- Expect: 5 rows, each img_ct=1, url ends in {uuid}-headshot.jpg, photo_origin_url = bellflower.ca.gov source.
