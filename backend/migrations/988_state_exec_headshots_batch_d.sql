-- 988_state_exec_headshots_batch_d.sql
-- Phase 141 (v2.18 State Leaders), plan 141-11. AUDIT-ONLY (mirrors migration 271).
-- Actual headshot uploads to the politician_photos bucket + politician_images INSERTs happened LIVE via
-- backend/scripts/seed-state-exec-headshots.py (Wikipedia pageimages -> PIL crop 4:5 -> 600x750 LANCZOS q90).
-- These INSERTs reproduce that record idempotently (column `url`, WHERE NOT EXISTS). Re-apply = no-op.
-- Batch D: 35 headshots recorded.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/migrations/988_state_exec_headshots_batch_d.sql

BEGIN;

-- Erick Russell (CT, ext -900005) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/5/52/Erick_Russell_at_ONeill_Armory_2023_Cropped.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-900005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/674a492b-43f5-45c5-85e8-c302d4a3fd91-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-900005));

-- Stephanie Thomas (CT, ext -900004) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/c/c3/Stephanie_Thomas_2023_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-900004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1d62bc74-ec47-43cd-9dbf-4d73467ea8a5-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-900004));

-- William Tong (CT, ext -900003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/1/1a/Richard_Blumenthal_and_William_Tong_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-900003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/134c2bfa-eb1f-4e67-beb6-505624707a2f-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-900003));

-- Susan Bysiewicz (CT, ext -900002) — cc_by-sa_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/b/b3/Bysiewicz_Sworn_In_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-900002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f22b744c-6857-4c75-bce0-3b58d592259c-headshot.jpg', 'default', 'cc_by-sa_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-900002));

-- Ned Lamont (CT, ext -900001) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/b/b8/Governor_Ned_Lamont_of_Connecticut%2C_official_portrait.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-900001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eca2c4af-c882-42f6-bcb9-e656e1264758-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-900001));

-- Mark Metcalf (KY, ext -2100005) — cc_by_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/4/49/Mark_Metcalf.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2100005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a5752370-3b1b-4eaa-aced-91e786379b2f-headshot.jpg', 'default', 'cc_by_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2100005));

-- Michael Adams (KY, ext -2100004) — cc_by_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/b/bd/Michael_Adams.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2100004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e4f4c7bc-9f03-42dc-bac1-bf137ece3d35-headshot.jpg', 'default', 'cc_by_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2100004));

-- Russell Coleman (KY, ext -2100003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/c/ca/Russell_Coleman_official_photo.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2100003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f84802e8-1b8b-4748-9276-8aa3e8b591a9-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2100003));

-- Jacqueline Coleman (KY, ext -2100002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/b/b2/Jacqueline_Coleman_speaks_to_an_audience_from_the_Capitol_steps_in_Frankfort_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2100002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7c0a855e-1b95-4f9f-976a-24fbe41a7352-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2100002));

-- Andy Beshear (KY, ext -2100001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/5/5e/Andy_Beshear_in_April_2026_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2100001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2a6ca553-2e25-450c-a819-c515c7544dad-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2100001));

-- Steve Simon (MN, ext -2700004) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/5/5c/2026SteveSimon.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2700004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d95b4426-cd5e-4970-a46e-ae9b7ee16012-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2700004));

-- Keith Ellison (MN, ext -2700003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/6/62/Keith_Ellison_portrait.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2700003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9b7310b5-d12f-419d-af87-6ad834a1055a-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2700003));

-- Peggy Flanagan (MN, ext -2700002) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/c/c6/2026PeggyFlanagan.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2700002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c788d228-1757-4069-bca4-6a9586819dc8-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2700002));

-- Tim Walz (MN, ext -2700001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/3/3a/Governor_Tim_Walz_2026.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2700001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d9b4d757-aa43-458d-9ecc-973338bceee4-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2700001));

-- Kelly Ayotte (NH, ext -3300001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/9/98/Governor_Kelly_Ayotte_receives_a_briefing_from_National_Guard_cyber_operators_%28cropped%29_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3300001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/13d45047-8183-46bd-a04a-5f5420b710cc-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3300001));

-- Zach Conine (NV, ext -3200005) — cc_by_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/3/31/Zach_Conine%2C_Nevada_State_Treasurer%2C_USA_-_cropped.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3200005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0e1c737b-223a-4008-8389-1307c00567e9-headshot.jpg', 'default', 'cc_by_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3200005));

-- Cisco Aguilar (NV, ext -3200004) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/7/7d/Francisco_Aguilar%2C_Secretary_of_State_of_Nevada%2C_2024.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3200004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dbf13dfe-703f-420a-8073-5ac2b564d80c-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3200004));

-- Aaron Ford (NV, ext -3200003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/5/5c/Nevada_Attorney_General_Aaron_Ford_addresses_the_United_Nations_Human_Rights_Committee%2C_October_17-18%2C_2023_1_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3200003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b71cb940-9a37-4935-8340-bf878c0ad288-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3200003));

-- Stavros Anthony (NV, ext -3200002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/1/10/Stavros_Anthony%2C_2023.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3200002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1997a34f-1aba-4832-be59-37a8074fc26a-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3200002));

-- Joe Lombardo (NV, ext -3200001) — cc_by-sa_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/2/2e/Joe_Lombardo_by_Gage_Skidmore.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3200001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f8e66045-33cc-4f0e-ae31-58f58e148f94-headshot.jpg', 'default', 'cc_by-sa_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3200001));

-- James Diossa (RI, ext -4400005) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/8/8d/James_Diossa%2C_Rhode_Island_General_Treasurer.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4400005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/95ee890b-81c3-4376-972c-ac474e5a95fe-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4400005));

-- Gregg Amore (RI, ext -4400004) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/1/1d/Rhode_Island_Secretary_Of_State_Gregg_M._Amore.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4400004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8df7ff47-c5f1-4ba1-82dc-1e8f6abdc753-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4400004));

-- Peter Neronha (RI, ext -4400003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/e/eb/Neronha3.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4400003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/62e2f297-b1b6-46f2-8106-46d3184f1a2d-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4400003));

-- Sabina Matos (RI, ext -4400002) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/d/d1/Rhode_Island_Lieutenant_governor_Sabina_Matos.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4400002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8dfb13d5-f590-4afb-a00d-58c477f39b94-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4400002));

-- Dan McKee (RI, ext -4400001) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/1/1b/RI_Governor_Daniel_McKee.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4400001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/125d1783-6548-496c-9499-fbd79a0e4a4e-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4400001));

-- Bill Lee (TN, ext -4700001) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/2/21/Hob_Nob_on_the_State_Line_with_Tennessee_Governor_Bill_Lee%2C_Bristol_%28cropped%29.2.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4700001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f5b283b7-8415-47cd-9bbe-e909760a67a3-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4700001));

-- John Leiber (WI, ext -5500005) — public_domain
--   source: https://statetreasurer.wi.gov/PublishingImages/Pages/About/Treasurer/State%20Treasurer%20John%20Leiber%20x%20small.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5500005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c8e496a6-58d6-475a-b6b7-4bf2f15d657b-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5500005));

-- Sarah Godlewski (WI, ext -5500004) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/e/ee/Sarah_Godlewski_Photo.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5500004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9547b530-f40b-4802-b621-fb64571670e4-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5500004));

-- Josh Kaul (WI, ext -5500003) — cc_by_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/e/ef/Josh_Kaul-13_-_44610449305_%283x4b%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5500003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9dc798c5-09b7-4d9d-bf8f-e79b0f8c0f74-headshot.jpg', 'default', 'cc_by_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5500003));

-- Sara Rodriguez (WI, ext -5500002) — cc0
--   source: https://upload.wikimedia.org/wikipedia/commons/a/a4/Sarah_Rodriguez_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5500002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5f79c703-135e-4292-8198-bf113358a8d9-headshot.jpg', 'default', 'cc0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5500002));

-- Tony Evers (WI, ext -5500001) — cc_by_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/0/08/Tony_Evers_-_2022_%28a%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5500001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0ef0cb58-09c9-4c21-b81e-5b676cae23f8-headshot.jpg', 'default', 'cc_by_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5500001));

-- Larry Pack (WV, ext -5400004) — public_domain
--   source: https://wvtreasury.gov/portals/wvtreasury/Images/2025_Pack-headshot.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5400004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e7f1ef44-c496-40b1-b6b3-246d154aa974-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5400004));

-- Kris Warner (WV, ext -5400003) — public_domain
--   source: https://sos.wv.gov/sites/default/files/2026-06/KrisWarnerHeadshot_2026.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5400003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/83f6877f-0fb4-4a85-b9db-837dce345c00-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5400003));

-- JB McCuskey (WV, ext -5400002) — cc_by-sa_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/4/4f/John_McCuskey_by_Gage_Skidmore.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5400002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a9c5e442-1358-43e6-87d2-a4673a811bda-headshot.jpg', 'default', 'cc_by-sa_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5400002));

-- Patrick Morrisey (WV, ext -5400001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/b/b5/Patrick_Morrisey_2026_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5400001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/af0e81ec-b2dd-42eb-80b9-aa73c62c2741-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5400001));

-- No honest-skips in this batch.

COMMIT;
