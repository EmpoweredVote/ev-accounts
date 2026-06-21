-- 987_state_exec_headshots_batch_c.sql
-- Phase 141 (v2.18 State Leaders), plan 141-10. AUDIT-ONLY (mirrors migration 271).
-- Actual headshot uploads to the politician_photos bucket + politician_images INSERTs happened LIVE via
-- backend/scripts/seed-state-exec-headshots.py (Wikipedia pageimages -> PIL crop 4:5 -> 600x750 LANCZOS q90).
-- These INSERTs reproduce that record idempotently (column `url`, WHERE NOT EXISTS). Re-apply = no-op.
-- Batch C: 35 headshots recorded.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/migrations/987_state_exec_headshots_batch_c.sql

BEGIN;

-- Dave Young (CO, ext -800005) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/3/3e/Dave_Young_%28Colorado_politician%29_2022_%28cropped%29.JPG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-800005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8868cae5-a50a-483b-be2e-b581894c1b6b-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-800005));

-- Jena Griswold (CO, ext -800004) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/a/a1/Jena_Griswold.JPG
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-800004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/31667cca-d1c9-43f5-bc82-45312793aad0-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-800004));

-- Phil Weiser (CO, ext -800003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/6/6c/AG_Phil_Weiser.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-800003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5bad420d-17de-48ec-94ef-14b901c0ed1d-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-800003));

-- Dianne Primavera (CO, ext -800002) — cc_by_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/d/db/Dianne_Primavera_2022.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-800002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1b1a74c3-a6af-4de5-a026-b9564ac7ed41-headshot.jpg', 'default', 'cc_by_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-800002));

-- Jared Polis (CO, ext -800001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/4/46/Jared_Polis_in_2026.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-800001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ea2ea8af-7b16-48da-a70f-9752b0ca0db8-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-800001));

-- Steven Johnson (KS, ext -2000005) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/2022_Kansas_state_treasurer_election_results_map_by_county.svg/960px-2022_Kansas_state_treasurer_election_results_map_by_county.svg.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2000005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6dada0fd-8e21-4899-819d-26ba69a75b37-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2000005));

-- Scott Schwab (KS, ext -2000004) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/8/86/Scott_Schwab_official_photo_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2000004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e752a957-c776-4942-9aae-63ebf23174ac-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2000004));

-- Kris Kobach (KS, ext -2000003) — cc0
--   source: https://upload.wikimedia.org/wikipedia/commons/e/e1/Kris_Kobach_official_portrait%2C_2024.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2000003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dab70f86-523b-4271-b183-0dc578c2b0fa-headshot.jpg', 'default', 'cc0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2000003));

-- David Toland (KS, ext -2000002) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/a/a2/David_Toland_official_photo.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2000002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/14d42486-4ffc-4305-a998-b5d4d47aaace-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2000002));

-- Laura Kelly (KS, ext -2000001) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/0/0f/Laura_Kelly_official_photo.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2000001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d01a39ea-94bf-4064-b3dd-56d3878aab6b-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2000001));

-- Jocelyn Benson (MI, ext -2600004) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/5/57/SOS_Jocelyn_Benson_web.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2600004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5d59648a-be0a-4a19-bb3d-344754a559ef-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2600004));

-- Dana Nessel (MI, ext -2600003) — cc_by_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/5/52/Dana_Nessel_Michigan_Is_Preparing_for_%27Every_Scenario%27_on_Election_Day_THE_CIRCUS_SHOWTIME_0-25_screenshot_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2600003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1ce5f060-da97-4d82-8441-e09994095c76-headshot.jpg', 'default', 'cc_by_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2600003));

-- Garlin Gilchrist (MI, ext -2600002) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/6/6f/Garlin_Gilchrist_in_Grand_Rapids.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2600002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/312e77d1-8fc7-4a75-8731-2f252d72e2a4-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2600002));

-- Gretchen Whitmer (MI, ext -2600001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/2/2e/2025_Gretchen_Whitmer_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2600001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a4a239ad-98ab-4fa9-9d56-7781f46821a4-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2600001));

-- Joey Spellerberg (NE, ext -3100005) — public_domain
--   source: https://treasurer.nebraska.gov/images/JoeySpellerberg_drkbkg_sq2.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3100005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dfdd834a-3ea9-46d0-921a-190d2cac9acb-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3100005));

-- Bob Evnen (NE, ext -3100004) — cc_by_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/1/1e/Bob_Evnen_1.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3100004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b9854782-7b24-4b4a-ba90-22e9ecf9a3ca-headshot.jpg', 'default', 'cc_by_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3100004));

-- Mike Hilgers (NE, ext -3100003) — cc_by_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/1/16/Mike_Hilgers.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3100003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e32910d5-50f2-4ab9-afc0-a5dd605c429b-headshot.jpg', 'default', 'cc_by_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3100003));

-- Joe Kelly (NE, ext -3100002) — public_domain
--   source: https://ltgov.nebraska.gov/sites/default/files/img/Lt%20Governor%20Kelly-1.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3100002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/97895d72-42e7-4c6c-aa0f-95afcbcc9a11-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3100002));

-- Jim Pillen (NE, ext -3100001) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/2/22/Jim_Pillen_SelectUSA_%2855251574792%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3100001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5751ccd5-8b7a-4ce4-9247-e308c703a809-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3100001));

-- Dale Caldwell (NJ, ext -3400002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/e/e2/Lt._Governor_Dr._Dale_G._Caldwell.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3400002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9d0a755d-b98b-4290-b3c7-6646664914b6-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3400002));

-- Mikie Sherrill (NJ, ext -3400001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/2/22/Governor_of_New_Jersey_Rebecca_Michelle_%22Mikie%22_Sherrill.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3400001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6609f174-6c1e-4fe9-afe6-2ed20f5f2463-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3400001));

-- Robert Sprague (OH, ext -3900005) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/5/57/Rob_Portman_and_Robert_Sprague_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3900005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/171effdf-cf2b-49aa-ab26-29f26c2be755-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3900005));

-- Frank LaRose (OH, ext -3900004) — cc_by-sa_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/6/62/Frank_LaRose_by_Gage_Skidmore.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3900004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/79276956-dfa1-4bca-9820-ab7c78dd57c8-headshot.jpg', 'default', 'cc_by-sa_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3900004));

-- Andy Wilson (OH, ext -3900003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/thumb/b/b0/Seal_of_the_Attorney_General_of_Ohio.svg/960px-Seal_of_the_Attorney_General_of_Ohio.svg.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3900003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ef91fbe1-2a1d-459d-a5cd-772025423c7b-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3900003));

-- Jim Tressel (OH, ext -3900002) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/a/af/Jim_Tressel_2025_portrait_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3900002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8638e7a7-ee89-4687-8e93-b31a73872086-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3900002));

-- Mike DeWine (OH, ext -3900001) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/3/3c/Gov-Mike-DeWine.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3900001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9739fb00-209f-4ed0-ad06-b9d97d74ced1-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3900001));

-- Stacy Garrity (PA, ext -4200004) — cc_by_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/4/45/Stacy_Garrity%2C_2024.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4200004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/066f7bc5-6e3d-4d17-9878-73d896a2369e-headshot.jpg', 'default', 'cc_by_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4200004));

-- Dave Sunday (PA, ext -4200003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/Seal_of_Pennsylvania.svg/960px-Seal_of_Pennsylvania.svg.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4200003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c1a8e812-2851-4c1b-b5c5-cf2997ee2ed2-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4200003));

-- Austin Davis (PA, ext -4200002) — cc_by_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/a/a5/AustinDavis.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4200002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fc75d0fc-a205-43e2-ab13-80a1caecdff5-headshot.jpg', 'default', 'cc_by_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4200002));

-- Josh Shapiro (PA, ext -4200001) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/2/26/Josh_Shapiro_December_2025.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4200001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c3956e15-01f6-46cf-95bd-edd43f0ae8f3-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4200001));

-- Mike Pellicciotti (WA, ext -5300005) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/f/fa/Washington_State_Treasurer_Mike_Pellicciotti_portrait.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5300005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cb4548a9-9d24-4696-8f88-8cc140ae88ac-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5300005));

-- Steve Hobbs (WA, ext -5300004) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/thumb/3/3d/Seal_of_Washington.svg/960px-Seal_of_Washington.svg.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5300004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/87f17e16-15dc-47d7-889a-40ee329f17b7-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5300004));

-- Nick Brown (WA, ext -5300003) — cc_by_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/9/90/Official_portrait_of_Rt_Hon_Nicholas_Brown_MP_crop_2.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5300003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/99762b4d-d69f-4b43-a7fc-3984babb1942-headshot.jpg', 'default', 'cc_by_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5300003));

-- Denny Heck (WA, ext -5300002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/b/b5/Denny_Heck_official_photo.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5300002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/57b3e9b1-1df0-4bc1-b10b-7005eca4593a-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5300002));

-- Bob Ferguson (WA, ext -5300001) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/8/8e/Bob_Ferguson_at_his_2023_Shrimp_Feed_02_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5300001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b8427e5d-f570-45bd-945f-c192e78b4d12-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5300001));

-- No honest-skips in this batch.

COMMIT;
