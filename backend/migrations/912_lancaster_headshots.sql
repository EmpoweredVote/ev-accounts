-- 912_lancaster_headshots.sql — Phase 145 Wave 3 — AUDIT-ONLY (not registered)
-- Headshots for current Lancaster members sourced from NON-WAF fallbacks (cityoflancasterca.org is Akamai-403).
-- Uploaded to Storage politician_photos/{uuid}/default.jpeg (600x750, 4:5 Lanczos q90), verified correct person + framing.
-- Parris (-200795) already had an image. Mann (-201281) = documented GAP (only a 130x162 AVAQMD source — too small
--   for a quality 600x750; no other non-WAF portrait found). Hughes-Leslie/White/Castellanos added here.
BEGIN;
-- politician_images rows (one type='default' per member; guarded)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id, v.url, 'default', 'press_use'
FROM (VALUES
  (-201279, 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/007074c6-6fbe-429f-9e06-8d7251198d8a/default.jpeg'),
  (-700655, 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/bb0cad08-e4da-4e44-b624-b7470dbb591e/default.jpeg'),
  (-700656, 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/d13670a9-cd1d-4771-9483-1dd3ad848dc8/default.jpeg')
) AS v(ext_id, url)
JOIN essentials.politicians p ON p.external_id = v.ext_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id AND pi.type='default');

-- photo_origin_url backfill
UPDATE essentials.politicians SET photo_origin_url='https://www.avaqmd.ca.gov/avaqmd-governing-board-member-bac3cf5' WHERE external_id=-201279 AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://whiteforlancasterca.net/' WHERE external_id=-700655 AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.avdailynews.com/single-post/meet-rocio-castellanos-a-hopeful-candidate-for-the-lancaster-city-council-2026' WHERE external_id=-700656 AND photo_origin_url IS NULL;
COMMIT;
