-- 1752_seattle_headshots.sql
-- Headshots for the 11 City of Seattle officials.
--
-- MIXED SOURCES, chosen per person on MEASURED resolution rather than assumed:
-- seattle.gov publishes its official headshots at only 300x300, below the
-- 600x750 standard, so 9 of 11 come from Wikimedia instead. But the rule is not
-- 'Wikimedia is better' -- for Rob Saka the Wikimedia image is SMALLER
-- (244x308) than the official one, so he keeps the official photo. Joy
-- Hollingsworth has a confirmed Wikipedia article that carries no image, so she
-- does too. License therefore varies per row: cc_by_sa for Wikimedia, press_use
-- for seattle.gov.
--
-- IDENTITY WAS GATED, NOT TRUSTED. A Wikipedia article was only accepted when
-- its own extract named Seattle AND the office held. That test rejected a King
-- County Council election article that merely mentioned Joy Hollingsworth --
-- exactly the near-miss that produces a wrong face.
--
-- seattle.gov filename traps avoided by using the literal published paths rather
-- than deriving them from last_name: Dionne Foster's file has an encoded space,
-- and Dan Strauss's is misspelled 'Struass'. Anything computed from the surname
-- would 404. The council pages also carry STAFF photos with mismatched alt text
-- (alt='Logan Duling' on a file named Brendan-Kolding.jpg), so member portraits
-- were taken only from the SquareHeadshots paths, never from bio-page images.
--
-- Cropped to 4:5 first, then resized to 600x750 q90, crop biased upward.
-- All 11 reviewed against the official version side by side and approved.

-- Erika Evans (wikimedia)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1018a81d-652c-46bb-9e18-3adf91d1f474', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1018a81d-652c-46bb-9e18-3adf91d1f474-headshot.jpg', 'default', 'cc_by_sa'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '1018a81d-652c-46bb-9e18-3adf91d1f474');
UPDATE essentials.politicians SET photo_origin_url = 'https://en.wikipedia.org/wiki/Erika_Evans'
WHERE id = '1018a81d-652c-46bb-9e18-3adf91d1f474' AND photo_origin_url IS NULL;

-- Dionne Foster (wikimedia)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '675e3f43-73e9-4de8-b514-d63b146a8fc7', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/675e3f43-73e9-4de8-b514-d63b146a8fc7-headshot.jpg', 'default', 'cc_by_sa'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '675e3f43-73e9-4de8-b514-d63b146a8fc7');
UPDATE essentials.politicians SET photo_origin_url = 'https://en.wikipedia.org/wiki/Dionne_Foster'
WHERE id = '675e3f43-73e9-4de8-b514-d63b146a8fc7' AND photo_origin_url IS NULL;

-- Alexis Mercedes Rinck (wikimedia)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '5c98f25c-4d32-450c-8428-4e3647cbde4d', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5c98f25c-4d32-450c-8428-4e3647cbde4d-headshot.jpg', 'default', 'cc_by_sa'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '5c98f25c-4d32-450c-8428-4e3647cbde4d');
UPDATE essentials.politicians SET photo_origin_url = 'https://en.wikipedia.org/wiki/Alexis_Mercedes_Rinck'
WHERE id = '5c98f25c-4d32-450c-8428-4e3647cbde4d' AND photo_origin_url IS NULL;

-- Robert Kettle (wikimedia)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '8c15f6a8-2c28-4b34-a736-ca4d6340f615', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8c15f6a8-2c28-4b34-a736-ca4d6340f615-headshot.jpg', 'default', 'cc_by_sa'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '8c15f6a8-2c28-4b34-a736-ca4d6340f615');
UPDATE essentials.politicians SET photo_origin_url = 'https://en.wikipedia.org/wiki/Robert_Kettle'
WHERE id = '8c15f6a8-2c28-4b34-a736-ca4d6340f615' AND photo_origin_url IS NULL;

-- Dan Strauss (wikimedia)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '2e4714c6-feb4-443f-9cc0-08d866a0a99f', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2e4714c6-feb4-443f-9cc0-08d866a0a99f-headshot.jpg', 'default', 'cc_by_sa'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '2e4714c6-feb4-443f-9cc0-08d866a0a99f');
UPDATE essentials.politicians SET photo_origin_url = 'https://en.wikipedia.org/wiki/Dan_Strauss'
WHERE id = '2e4714c6-feb4-443f-9cc0-08d866a0a99f' AND photo_origin_url IS NULL;

-- Debora Juarez (wikimedia)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'b510823d-e54b-40a5-92c0-09a6636359d5', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b510823d-e54b-40a5-92c0-09a6636359d5-headshot.jpg', 'default', 'cc_by_sa'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'b510823d-e54b-40a5-92c0-09a6636359d5');
UPDATE essentials.politicians SET photo_origin_url = 'https://en.wikipedia.org/wiki/Debora_Juarez'
WHERE id = 'b510823d-e54b-40a5-92c0-09a6636359d5' AND photo_origin_url IS NULL;

-- Maritza Rivera (wikimedia)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '81057c65-d128-4712-8ded-52c4534b0d9b', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/81057c65-d128-4712-8ded-52c4534b0d9b-headshot.jpg', 'default', 'cc_by_sa'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '81057c65-d128-4712-8ded-52c4534b0d9b');
UPDATE essentials.politicians SET photo_origin_url = 'https://en.wikipedia.org/wiki/Maritza_Rivera'
WHERE id = '81057c65-d128-4712-8ded-52c4534b0d9b' AND photo_origin_url IS NULL;

-- Joy Hollingsworth (seattle.gov)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1187a22d-1064-4ff4-8193-189c34b4b6e8', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1187a22d-1064-4ff4-8193-189c34b4b6e8-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '1187a22d-1064-4ff4-8193-189c34b4b6e8');
UPDATE essentials.politicians SET photo_origin_url = 'https://www.seattle.gov/council/members'
WHERE id = '1187a22d-1064-4ff4-8193-189c34b4b6e8' AND photo_origin_url IS NULL;

-- Eddie Lin (wikimedia)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '9e33c647-967a-4dce-a900-ad7d066cc57f', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9e33c647-967a-4dce-a900-ad7d066cc57f-headshot.jpg', 'default', 'cc_by_sa'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '9e33c647-967a-4dce-a900-ad7d066cc57f');
UPDATE essentials.politicians SET photo_origin_url = 'https://en.wikipedia.org/wiki/Eddie_Lin'
WHERE id = '9e33c647-967a-4dce-a900-ad7d066cc57f' AND photo_origin_url IS NULL;

-- Rob Saka (seattle.gov)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '215f2142-c0a1-46fb-b78e-3204843ae3e5', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/215f2142-c0a1-46fb-b78e-3204843ae3e5-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '215f2142-c0a1-46fb-b78e-3204843ae3e5');
UPDATE essentials.politicians SET photo_origin_url = 'https://www.seattle.gov/council/members'
WHERE id = '215f2142-c0a1-46fb-b78e-3204843ae3e5' AND photo_origin_url IS NULL;

-- Katie Wilson (wikimedia)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '90d1ac0b-efa6-42fc-abb2-34767380d607', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/90d1ac0b-efa6-42fc-abb2-34767380d607-headshot.jpg', 'default', 'cc_by_sa'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '90d1ac0b-efa6-42fc-abb2-34767380d607');
UPDATE essentials.politicians SET photo_origin_url = 'https://en.wikipedia.org/wiki/Katie_Wilson'
WHERE id = '90d1ac0b-efa6-42fc-abb2-34767380d607' AND photo_origin_url IS NULL;
