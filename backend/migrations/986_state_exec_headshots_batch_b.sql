-- 986_state_exec_headshots_batch_b.sql
-- Phase 141 (v2.18 State Leaders), plan 141-09. AUDIT-ONLY (mirrors migration 271).
-- Actual headshot uploads to the politician_photos bucket + politician_images INSERTs happened LIVE via
-- backend/scripts/seed-state-exec-headshots.py (Wikipedia pageimages -> PIL crop 4:5 -> 600x750 LANCZOS q90).
-- These INSERTs reproduce that record idempotently (column `url`, WHERE NOT EXISTS). Re-apply = no-op.
-- Batch B: 35 headshots recorded.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/migrations/986_state_exec_headshots_batch_b.sql

BEGIN;

-- John Thurston (AR, ext -500005) — cc0
--   source: https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/2024_Arkansas_state_treasurer_special_election_results_map_by_county.svg/960px-2024_Arkansas_state_treasurer_special_election_results_map_by_county.svg.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-500005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e9af5fde-e1cd-4a54-9594-ec9e42353d55-headshot.jpg', 'default', 'cc0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-500005));

-- Cole Jester (AR, ext -500004) — public_domain
--   source: https://www.sos.arkansas.gov/uploads/aboutOffice/Cole-Jester-123124.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-500004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0ee2a01a-3cf1-428e-b8ed-943d2e3c29f5-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-500004));

-- Tim Griffin (AR, ext -500003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/a/a0/Rep_Tim_Griffin_Official_Photo.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-500003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9298415e-b8e5-4ccf-9f2a-b9366dd8ca1a-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-500003));

-- Leslie Rutledge (AR, ext -500002) — cc_by-sa_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/c/c6/Leslie_Rutledge_%2825475720912%29_%281%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-500002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e8d0cb0c-a145-4483-860e-4e6af68f0a8b-headshot.jpg', 'default', 'cc_by-sa_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-500002));

-- Sarah Huckabee Sanders (AR, ext -500001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/4/49/Governor_Sarah_Huckabee_Sanders_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-500001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b4f849ef-ce62-45ad-b5af-be0a54e3fa95-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-500001));

-- Brad Raffensperger (GA, ext -1300004) — cc_by-sa_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/a/aa/Brad_Raffensperger_2022.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1300004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b5c0a945-8e4f-4617-895d-a75be0e3b48c-headshot.jpg', 'default', 'cc_by-sa_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1300004));

-- Chris Carr (GA, ext -1300003) — cc_by-sa_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/e/ea/Christopher_M._Carr_by_Gage_Skidmore_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1300003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d90f754e-c3c6-44f9-890d-a8f2a9a00d22-headshot.jpg', 'default', 'cc_by-sa_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1300003));

-- Burt Jones (GA, ext -1300002) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/f/f5/Burt_Jones_-_Turning_Point_USA_tour_at_University_of_Georgia%2C_April_14%2C_2026_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1300002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/14acb49e-85a6-4367-87fa-0a087d085912-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1300002));

-- Brian Kemp (GA, ext -1300001) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/4/46/Brian_Kemp_2025_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1300001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d76a1a8b-5316-4e84-b64b-e66843c4763b-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1300001));

-- Sylvia Luke (HI, ext -1500002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/0/04/Lt._Governor_Sylvia_Luke_Portrait_2023.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1500002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bb3cfd1d-42a2-41c2-978d-c1d1734be93f-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1500002));

-- Josh Green (HI, ext -1500001) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/0/0e/Josh_Green_Official_Photo_2022_%28cropped%29_1cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1500001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/76307cf7-47dd-4b0a-ac4b-ed218095bf47-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1500001));

-- Roby Smith (IA, ext -1900005) — copyrighted_free_use
--   source: https://upload.wikimedia.org/wikipedia/commons/3/31/Roby_Smith.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1900005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e13dabd3-ccff-4164-96a7-ecf2444d62c7-headshot.jpg', 'default', 'copyrighted_free_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1900005));

-- Paul Pate (IA, ext -1900004) — copyrighted_free_use
--   source: https://upload.wikimedia.org/wikipedia/commons/0/0a/Paul_Pate.jpeg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1900004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e9d4ee27-3f0d-487e-b68f-3c5510999834-headshot.jpg', 'default', 'copyrighted_free_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1900004));

-- Brenna Bird (IA, ext -1900003) — cc_by-sa_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/e/e3/Brenna_Bird_by_Gage_Skidmore_2.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1900003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1b52da57-06f3-4841-aa1d-8bbbb82f96ea-headshot.jpg', 'default', 'cc_by-sa_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1900003));

-- Chris Cournoyer (IA, ext -1900002) — copyrighted_free_use
--   source: https://upload.wikimedia.org/wikipedia/commons/3/3a/Iowa_State_Senator_Chris_Cournoyer.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1900002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f022e15b-25dc-44fd-873d-a0027e898110-headshot.jpg', 'default', 'copyrighted_free_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1900002));

-- Kim Reynolds (IA, ext -1900001) — cc_by-sa_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/5/5d/Kim_Reynolds_by_Gage_Skidmore_2.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1900001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/108874f4-314b-44fc-83df-31eea167064b-headshot.jpg', 'default', 'cc_by-sa_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1900001));

-- Vivek Malek (MO, ext -2900005) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/1/1f/MO_Treasurers_-_48_Vivek_Malek_%282023-%29_%2853220004803%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2900005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/013eb0a9-805c-4f6a-9ee1-19ffadb01beb-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2900005));

-- Denny Hoskins (MO, ext -2900004) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/9/9c/Secretary_of_State_of_Missouri_Denny_L._Hoskins.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2900004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b7318128-42e4-4285-989d-11a849f76e95-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2900004));

-- Catherine Hanaway (MO, ext -2900003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/9/95/Attorney_General_of_Missouri_Catherine_Lucille_Hanaway.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2900003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e2bb39a3-b83c-44a8-8d3e-9b850952a0f1-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2900003));

-- David Wasinger (MO, ext -2900002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/b/be/Lieutenant_Governor_of_Missouri_David_G._Wasinger_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2900002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e5aa41c9-af47-4c55-8f98-32232c682748-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2900002));

-- Mike Kehoe (MO, ext -2900001) — cc0
--   source: https://upload.wikimedia.org/wikipedia/commons/4/48/Mike_Kehoe_2025_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2900001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/48b91703-7fda-4995-9ebb-de3146d24e1d-headshot.jpg', 'default', 'cc0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2900001));

-- Thomas Beadle (ND, ext -3800005) — cc0
--   source: https://upload.wikimedia.org/wikipedia/commons/d/df/Tom_Beadle_ND_Blue_Book_2023.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3800005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2ef82de4-b4fa-4014-8278-da2460618668-headshot.jpg', 'default', 'cc0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3800005));

-- Michael Howe (ND, ext -3800004) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/thumb/8/8b/Great_Seal_of_North_Dakota.svg/960px-Great_Seal_of_North_Dakota.svg.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3800004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d7cc7826-afd2-43fb-85b4-76c9aeccd1db-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3800004));

-- Drew Wrigley (ND, ext -3800003) — public_domain
--   source: https://attorneygeneral.nd.gov/wp-content/uploads/2023/02/Attorney-General-Wrigley-683x1024.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3800003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/86a3a804-41ea-49c9-badd-0b48582df08e-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3800003));

-- Michelle Strinden (ND, ext -3800002) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/9/9c/Michelle_Strinden.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3800002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ee6be9e8-0441-4be8-a71f-f01f7032bcb0-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3800002));

-- Kelly Armstrong (ND, ext -3800001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/d/d3/Kelly_Armstrong_%283x4_cropped%29_%282%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3800001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7544a9ec-53aa-4ed1-86a3-5f5f4d399544-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3800001));

-- Todd Russ (OK, ext -4000004) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/c/cd/Russ%2C_Todd.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4000004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e6f8e7fa-04fd-432a-8985-b8fc5ab908fc-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4000004));

-- Gentner Drummond (OK, ext -4000003) — cc0
--   source: https://upload.wikimedia.org/wikipedia/commons/a/a4/Gentner_Drummond_2024_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4000003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/45dc1b5e-3ba7-4262-a05c-50d36747fcb9-headshot.jpg', 'default', 'cc0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4000003));

-- Matt Pinnell (OK, ext -4000002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/a/a8/Lieutenant_Governor_of_Oklahoma_Matt_Pinnell.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4000002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6fc3e9ea-c13b-4222-ab06-5fd62f8cea4d-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4000002));

-- Kevin Stitt (OK, ext -4000001) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/9/96/Kevin_Stitt_%2855103789989%29_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4000001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7044cbb7-0669-4ecc-80a5-058a52472e4b-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4000001));

-- Mike Pieciak (VT, ext -5000005) — cc_by_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/9/97/Mike_Pieciak_on_All_Things_LGBTQ_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5000005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/20bcd3a8-ccef-4fe3-8897-9333d7e79eb8-headshot.jpg', 'default', 'cc_by_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5000005));

-- Sarah Copeland-Hanzas (VT, ext -5000004) — cc_by_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/2/2a/Sarah_Copeland-Hanzas_at_Secretary_of_State_Democratic_Party_Primary_Forum_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5000004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fc2b0e86-3e94-4e0b-9812-a154065b5bad-headshot.jpg', 'default', 'cc_by_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5000004));

-- Charity Clark (VT, ext -5000003) — cc_by_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/c/c0/Charity_Clark.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5000003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7b2dfaca-3f6e-4d71-893f-28a278049eda-headshot.jpg', 'default', 'cc_by_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5000003));

-- John S. Rodgers (VT, ext -5000002) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/9/90/JohnRodgers.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5000002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/aa4040bf-4468-460e-8cb4-5a1e2a53c34f-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5000002));

-- Phil Scott (VT, ext -5000001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/c/cc/Phil_Scott_2019.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5000001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/963f2c91-9563-444e-9487-91822cd3e6cf-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5000001));

-- No honest-skips in this batch.

COMMIT;
