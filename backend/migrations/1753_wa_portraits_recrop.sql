-- 1753_wa_portraits_recrop.sql
-- King County portraits (11 new) + Seattle licence/origin correction (11 updated).
--
-- WHY THIS EXISTS. Two defects were caught in review, both process failures:
--
-- 1. The King County crop was CENTRED, validated against a single image whose
--    subject happened to be centred, then applied to all 14. Most of the
--    county's 1600x700 studio shots place the subject well off to one side, so
--    the window sliced faces at the edge. Cropping is now subject-aware:
--    column gradient energy locates the subject and the window centres on it.
--    Resulting offsets ranged x@299..x@863 -- the subjects really were
--    scattered across the frame.
--
-- 2. Seattle images had been chosen on RESOLUTION ALONE with nobody looking at
--    them. Several Wikimedia "originals" were not portraits: Alexis Rinck's was
--    a wide shot of her at the council dais. All 9 councilmembers are now on the
--    official seattle.gov studio headshots -- only 300x300, but correctly framed.
--    Correct framing beats resolution. Every image was rendered and inspected
--    before import this time.
--
-- Seattle rows are UPDATEd rather than inserted: the file is mirrored to our own
-- bucket at the same {politician_id}-headshot.jpg path, so re-uploading replaces
-- the image and the stored URL is unchanged. What changes is licence and origin,
-- as 9 moved from Wikimedia (cc_by_sa) back to seattle.gov (press_use).
--
-- NOT IMPORTED, no usable portrait exists:
--   Steffanie Fain  -- her county page serves her SIGNATURE, not a photograph
--   John Wilson     -- only a 195x195 thumbnail
--   Julie Wise      -- no portrait on any county page; no article under her name
-- Katie Wilson is imported but remains framed at a distance: she has no official
-- photo and her Wikimedia source is a standing shot.

-- Girmay Zahilay (kingcounty.gov)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1f63b667-7da3-4d75-b3ae-24529393741e', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1f63b667-7da3-4d75-b3ae-24529393741e-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '1f63b667-7da3-4d75-b3ae-24529393741e');
UPDATE essentials.politicians SET photo_origin_url = 'https://kingcounty.gov/en/dept/executive' WHERE id = '1f63b667-7da3-4d75-b3ae-24529393741e' AND photo_origin_url IS NULL;

-- Rod Dembowski (kingcounty.gov)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1c6c1a17-f235-4ccb-9201-5cbc35bfbf8a', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1c6c1a17-f235-4ccb-9201-5cbc35bfbf8a-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '1c6c1a17-f235-4ccb-9201-5cbc35bfbf8a');
UPDATE essentials.politicians SET photo_origin_url = 'https://kingcounty.gov/en/dept/council/governance-leadership/county-council/councilmembers-districts/rod-dembowski' WHERE id = '1c6c1a17-f235-4ccb-9201-5cbc35bfbf8a' AND photo_origin_url IS NULL;

-- Rhonda Lewis (kingcounty.gov)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '84286288-6160-4fd9-9c67-6c00d7fc533a', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/84286288-6160-4fd9-9c67-6c00d7fc533a-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '84286288-6160-4fd9-9c67-6c00d7fc533a');
UPDATE essentials.politicians SET photo_origin_url = 'https://kingcounty.gov/en/dept/council/governance-leadership/county-council/councilmembers-districts/rhonda-lewis' WHERE id = '84286288-6160-4fd9-9c67-6c00d7fc533a' AND photo_origin_url IS NULL;

-- Sarah Perry (kingcounty.gov)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '165df2f6-84e7-4f40-9f4b-ff00c766cbfb', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/165df2f6-84e7-4f40-9f4b-ff00c766cbfb-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '165df2f6-84e7-4f40-9f4b-ff00c766cbfb');
UPDATE essentials.politicians SET photo_origin_url = 'https://kingcounty.gov/en/dept/council/governance-leadership/county-council/councilmembers-districts/sarah-perry' WHERE id = '165df2f6-84e7-4f40-9f4b-ff00c766cbfb' AND photo_origin_url IS NULL;

-- Jorge L. Barón (kingcounty.gov)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd167607d-f8fd-442e-9397-8fd677d2deb7', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d167607d-f8fd-442e-9397-8fd677d2deb7-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'd167607d-f8fd-442e-9397-8fd677d2deb7');
UPDATE essentials.politicians SET photo_origin_url = 'https://kingcounty.gov/en/dept/council/governance-leadership/county-council/councilmembers-districts/jorge-l-baron' WHERE id = 'd167607d-f8fd-442e-9397-8fd677d2deb7' AND photo_origin_url IS NULL;

-- Claudia Balducci (kingcounty.gov)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'cd772ac3-d63b-4767-9198-ec4f1fb36f4d', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cd772ac3-d63b-4767-9198-ec4f1fb36f4d-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'cd772ac3-d63b-4767-9198-ec4f1fb36f4d');
UPDATE essentials.politicians SET photo_origin_url = 'https://kingcounty.gov/en/dept/council/governance-leadership/county-council/councilmembers-districts/claudia-balducci' WHERE id = 'cd772ac3-d63b-4767-9198-ec4f1fb36f4d' AND photo_origin_url IS NULL;

-- Pete von Reichbauer (kingcounty.gov)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '5d2c2935-5de1-4abc-b8e6-01ed595b16c0', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5d2c2935-5de1-4abc-b8e6-01ed595b16c0-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '5d2c2935-5de1-4abc-b8e6-01ed595b16c0');
UPDATE essentials.politicians SET photo_origin_url = 'https://kingcounty.gov/en/dept/council/governance-leadership/county-council/councilmembers-districts/pete-von-reichbauer' WHERE id = '5d2c2935-5de1-4abc-b8e6-01ed595b16c0' AND photo_origin_url IS NULL;

-- Teresa Mosqueda (kingcounty.gov)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '341e2bc1-37ef-4b18-9f64-8dae8f7e6079', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/341e2bc1-37ef-4b18-9f64-8dae8f7e6079-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '341e2bc1-37ef-4b18-9f64-8dae8f7e6079');
UPDATE essentials.politicians SET photo_origin_url = 'https://kingcounty.gov/en/dept/council/governance-leadership/county-council/councilmembers-districts/teresa-mosqueda' WHERE id = '341e2bc1-37ef-4b18-9f64-8dae8f7e6079' AND photo_origin_url IS NULL;

-- Reagan Dunn (kingcounty.gov)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '5ed0cfd6-c7d1-4597-9855-34d7643edc6f', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5ed0cfd6-c7d1-4597-9855-34d7643edc6f-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '5ed0cfd6-c7d1-4597-9855-34d7643edc6f');
UPDATE essentials.politicians SET photo_origin_url = 'https://kingcounty.gov/en/dept/council/governance-leadership/county-council/councilmembers-districts/reagan-dunn' WHERE id = '5ed0cfd6-c7d1-4597-9855-34d7643edc6f' AND photo_origin_url IS NULL;

-- Leesa Manion (kingcounty.gov)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '39544d21-7c0d-46fb-a3d0-a46302afa0f2', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/39544d21-7c0d-46fb-a3d0-a46302afa0f2-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '39544d21-7c0d-46fb-a3d0-a46302afa0f2');
UPDATE essentials.politicians SET photo_origin_url = 'https://kingcounty.gov/en/dept/pao' WHERE id = '39544d21-7c0d-46fb-a3d0-a46302afa0f2' AND photo_origin_url IS NULL;

-- Patti Cole-Tindall (kingcounty.gov)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '2e43aca9-1b7e-4df8-8b9f-b686ecb90f03', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2e43aca9-1b7e-4df8-8b9f-b686ecb90f03-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '2e43aca9-1b7e-4df8-8b9f-b686ecb90f03');
UPDATE essentials.politicians SET photo_origin_url = 'https://kingcounty.gov/en/dept/sheriff/about-king-county/about-sheriff-office/about-leadership-team/patti-cole-tindall' WHERE id = '2e43aca9-1b7e-4df8-8b9f-b686ecb90f03' AND photo_origin_url IS NULL;

-- Katie Wilson (wikimedia) -- corrected source
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/90d1ac0b-efa6-42fc-abb2-34767380d607-headshot.jpg', photo_license = 'cc_by_sa' WHERE politician_id = '90d1ac0b-efa6-42fc-abb2-34767380d607';
UPDATE essentials.politicians SET photo_origin_url = 'https://en.wikipedia.org/wiki/Katie_Wilson' WHERE id = '90d1ac0b-efa6-42fc-abb2-34767380d607';

-- Rob Saka (seattle.gov) -- corrected source
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/215f2142-c0a1-46fb-b78e-3204843ae3e5-headshot.jpg', photo_license = 'press_use' WHERE politician_id = '215f2142-c0a1-46fb-b78e-3204843ae3e5';
UPDATE essentials.politicians SET photo_origin_url = 'https://www.seattle.gov/council/members' WHERE id = '215f2142-c0a1-46fb-b78e-3204843ae3e5';

-- Eddie Lin (seattle.gov) -- corrected source
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9e33c647-967a-4dce-a900-ad7d066cc57f-headshot.jpg', photo_license = 'press_use' WHERE politician_id = '9e33c647-967a-4dce-a900-ad7d066cc57f';
UPDATE essentials.politicians SET photo_origin_url = 'https://www.seattle.gov/council/members' WHERE id = '9e33c647-967a-4dce-a900-ad7d066cc57f';

-- Joy Hollingsworth (seattle.gov) -- corrected source
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1187a22d-1064-4ff4-8193-189c34b4b6e8-headshot.jpg', photo_license = 'press_use' WHERE politician_id = '1187a22d-1064-4ff4-8193-189c34b4b6e8';
UPDATE essentials.politicians SET photo_origin_url = 'https://www.seattle.gov/council/members' WHERE id = '1187a22d-1064-4ff4-8193-189c34b4b6e8';

-- Maritza Rivera (seattle.gov) -- corrected source
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/81057c65-d128-4712-8ded-52c4534b0d9b-headshot.jpg', photo_license = 'press_use' WHERE politician_id = '81057c65-d128-4712-8ded-52c4534b0d9b';
UPDATE essentials.politicians SET photo_origin_url = 'https://www.seattle.gov/council/members' WHERE id = '81057c65-d128-4712-8ded-52c4534b0d9b';

-- Debora Juarez (seattle.gov) -- corrected source
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b510823d-e54b-40a5-92c0-09a6636359d5-headshot.jpg', photo_license = 'press_use' WHERE politician_id = 'b510823d-e54b-40a5-92c0-09a6636359d5';
UPDATE essentials.politicians SET photo_origin_url = 'https://www.seattle.gov/council/members' WHERE id = 'b510823d-e54b-40a5-92c0-09a6636359d5';

-- Dan Strauss (seattle.gov) -- corrected source
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2e4714c6-feb4-443f-9cc0-08d866a0a99f-headshot.jpg', photo_license = 'press_use' WHERE politician_id = '2e4714c6-feb4-443f-9cc0-08d866a0a99f';
UPDATE essentials.politicians SET photo_origin_url = 'https://www.seattle.gov/council/members' WHERE id = '2e4714c6-feb4-443f-9cc0-08d866a0a99f';

-- Robert Kettle (seattle.gov) -- corrected source
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8c15f6a8-2c28-4b34-a736-ca4d6340f615-headshot.jpg', photo_license = 'press_use' WHERE politician_id = '8c15f6a8-2c28-4b34-a736-ca4d6340f615';
UPDATE essentials.politicians SET photo_origin_url = 'https://www.seattle.gov/council/members' WHERE id = '8c15f6a8-2c28-4b34-a736-ca4d6340f615';

-- Alexis Mercedes Rinck (seattle.gov) -- corrected source
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5c98f25c-4d32-450c-8428-4e3647cbde4d-headshot.jpg', photo_license = 'press_use' WHERE politician_id = '5c98f25c-4d32-450c-8428-4e3647cbde4d';
UPDATE essentials.politicians SET photo_origin_url = 'https://www.seattle.gov/council/members' WHERE id = '5c98f25c-4d32-450c-8428-4e3647cbde4d';

-- Dionne Foster (seattle.gov) -- corrected source
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/675e3f43-73e9-4de8-b514-d63b146a8fc7-headshot.jpg', photo_license = 'press_use' WHERE politician_id = '675e3f43-73e9-4de8-b514-d63b146a8fc7';
UPDATE essentials.politicians SET photo_origin_url = 'https://www.seattle.gov/council/members' WHERE id = '675e3f43-73e9-4de8-b514-d63b146a8fc7';

-- Erika Evans (wikimedia) -- corrected source
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1018a81d-652c-46bb-9e18-3adf91d1f474-headshot.jpg', photo_license = 'cc_by_sa' WHERE politician_id = '1018a81d-652c-46bb-9e18-3adf91d1f474';
UPDATE essentials.politicians SET photo_origin_url = 'https://en.wikipedia.org/wiki/Erika_Evans' WHERE id = '1018a81d-652c-46bb-9e18-3adf91d1f474';
