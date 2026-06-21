-- 985_state_exec_headshots_batch_a.sql
-- Phase 141 (v2.18 State Leaders), plan 141-08. AUDIT-ONLY (mirrors migration 271).
-- Actual headshot uploads to the politician_photos bucket + politician_images INSERTs happened LIVE via
-- backend/scripts/seed-state-exec-headshots.py (Wikipedia pageimages -> PIL crop 4:5 -> 600x750 LANCZOS q90).
-- These INSERTs reproduce that record idempotently (column `url`, WHERE NOT EXISTS). Re-apply = no-op.
-- Batch A: 34 headshots recorded, 1 honest-skip.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/migrations/985_state_exec_headshots_batch_a.sql

BEGIN;

-- Nancy Dahlstrom (AK, ext -200009) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/4/40/Nancy_Dahlstrom%2C_2024.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-200009),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4532233c-277a-41fa-886f-1b71d6a12883-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-200009));

-- Mike Dunleavy (AK, ext -200008) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/9/9f/Governor_Mike_J._Dunleavy_-_Official_Portrait.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-200008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/33a51039-958f-40c2-974f-e04ea064b419-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-200008));

-- Young Boozer (AL, ext -100005) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/9/9a/Young_Boozer_2023.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-100005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7a0a5ed5-2a17-4fa8-8197-a589a4f5e2ab-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-100005));

-- Wes Allen (AL, ext -100004) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/3/39/Jerry_Carl_with_Wes_Allen_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-100004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1a2da915-ec61-4935-8936-9919264e8765-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-100004));

-- Steve Marshall (AL, ext -100003) — cc_by-sa_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/8/87/Steve_Marshall_%2841773693585%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-100003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d33b1fb5-bac7-48b9-9628-8169e28f4e16-headshot.jpg', 'default', 'cc_by-sa_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-100003));

-- Will Ainsworth (AL, ext -100002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/3/3c/Alabama_Lieutenant_Governor_visits_Lyster_Army_Health_Clinic_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-100002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6f1ae594-1041-42aa-8378-94fd5fde04c2-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-100002));

-- Kay Ivey (AL, ext -100001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/2/2c/Governor_Kay_Ivey_2017_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-100001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fd26d6ce-979e-4485-9e35-7d4c179c3c4c-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-100001));

-- Blaise Ingoglia (FL, ext -1200004) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/2/2c/Official_portrait_of_Chief_Financial_Officer_Blaise_Ingoglia_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1200004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8c7b61e3-709d-42f5-acf1-0c6a7e328f0a-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1200004));

-- James Uthmeier (FL, ext -1200003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/d/df/Official_portrait_of_Attorney_General_James_Uthmeier%2C_2025_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1200003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2e0915c5-45d7-48de-ae59-04bcd6bda1f7-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1200003));

-- Jay Collins (FL, ext -1200002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/d/d5/Official_portrait_of_Lieutenant_Governor_of_Florida_Jay_Collins_%28cropped_5%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1200002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ee966041-d44a-4c05-b7ae-d8d22bfb93a7-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1200002));

-- Ron DeSantis (FL, ext -1200001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/4/4f/Ron_DeSantis_official_photo.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1200001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/358d0829-8d2b-46ea-9af2-251f48960014-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1200001));

-- Mike Frerichs (IL, ext -1700005) — cc_by_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/6/6a/Frerichs_at_Conflict_of_Interest_Rule_Discussion_with_Sec_Perez_in_Chicago_June_30_2016.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1700005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/84f33004-e145-4ea7-8c73-c68e2a1048c2-headshot.jpg', 'default', 'cc_by_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1700005));

-- Alexi Giannoulias (IL, ext -1700004) — cc_by-sa_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/0/06/Alexi_Giannoulias_2.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1700004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/65df6ce5-a824-4b24-a0a9-d031e3631272-headshot.jpg', 'default', 'cc_by-sa_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1700004));

-- Kwame Raoul (IL, ext -1700003) — cc_by_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/a/a7/Kwame_Raoul_RFCG.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1700003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dcf335bf-ca4f-4878-8ef6-616380ff19db-headshot.jpg', 'default', 'cc_by_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1700003));

-- Juliana Stratton (IL, ext -1700002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/a/a8/Juliana_Stratton_2023_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1700002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/40373be4-5a51-48d7-8afc-e6be734653ce-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1700002));

-- JB Pritzker (IL, ext -1700001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/5/53/Governor_JB_Pritzker_official_portrait_2019_%28crop%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1700001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/557dc739-3701-443c-ab97-7d9c5c3d40db-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1700001));

-- David McRae (MS, ext -2800005) — public_domain
--   source: https://treasury.ms.gov/wp-content/uploads/2020/05/mcrae_photo@2x.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2800005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/91d6f83e-b11d-4acc-929a-fdbddc4cbca4-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2800005));

-- Michael Watson (MS, ext -2800004) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/f/f4/Seal_of_the_Secretary_of_State_of_Mississippi.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2800004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b7e0d181-ca77-4bf0-a9b0-c1e8e747e484-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2800004));

-- Lynn Fitch (MS, ext -2800003) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/1/17/Lynn_Fitch.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2800003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9dc9d9a7-4963-4752-b38f-88c29ae03491-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2800003));

-- Delbert Hosemann (MS, ext -2800002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/c/c6/Delbert_Hosemann.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2800002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bebc168c-8e2e-4ad8-9d84-848d583e92a7-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2800002));

-- Tate Reeves (MS, ext -2800001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/9/92/Gov._Tate_Reeves_Signs_House_Bill_1486_%28cropped%29_%282%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2800001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a0ae5161-c204-47ab-a858-4a685ec51613-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2800001));

-- Brad Briner (NC, ext -3700005) — cc0
--   source: https://upload.wikimedia.org/wikipedia/commons/2/20/Treasurer_Brad_Briner_Visit_Student_Money_Management_Press_Conference-16_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3700005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8eb34112-c00a-445e-a0ce-2ba47916dace-headshot.jpg', 'default', 'cc0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3700005));

-- Elaine Marshall (NC, ext -3700004) — cc_by-sa_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/8/88/Elaine_Marshall_IACA_2018.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3700004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e7f351cf-d668-4d09-b8ff-0f8dbd85b33a-headshot.jpg', 'default', 'cc_by-sa_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3700004));

-- Jeff Jackson (NC, ext -3700003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Seal_of_North_Carolina.svg/960px-Seal_of_North_Carolina.svg.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3700003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8e0122c2-8bcb-4114-87e6-faa72d5d5125-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3700003));

-- Rachel Hunt (NC, ext -3700002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/6/6a/Senator_Rachel_Hunt_2023-25_Legislative_Portrait.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3700002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f46a2bfc-628f-4991-9522-e8b75889cc6f-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3700002));

-- Josh Stein (NC, ext -3700001) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/b/bc/Josh_Stein_SelectUSA_%2855252715239%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3700001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/05889a4f-f4e5-4fb3-87a4-984bc9c23131-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3700001));

-- Thomas DiNapoli (NY, ext -3600004) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/3/38/TPD%27s_Headshot_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3600004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8f5b07af-7932-49d4-9164-6277781a541e-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3600004));

-- Letitia James (NY, ext -3600003) — cc_by_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/7/75/Letitia_James_Interview_Feb_2020.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3600003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/406dd9be-a751-4685-a946-44806bd01548-headshot.jpg', 'default', 'cc_by_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3600003));

-- Antonio Delgado (NY, ext -3600002) — cc0
--   source: https://upload.wikimedia.org/wikipedia/commons/0/0a/LG_Antonio_Delgado_Portrait.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3600002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ff090074-25d8-4db5-96e8-c60de6893e6d-headshot.jpg', 'default', 'cc0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3600002));

-- Kathy Hochul (NY, ext -3600001) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/8/8f/Governor_Kathy_Hochul_Press_Conference_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3600001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/90369b67-99c3-4e29-9f6c-8529350cf1eb-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3600001));

-- Monae Johnson (SD, ext -4600004) — public_domain
--   source: https://sdsos.gov/general-information/assets/Secretary%20Johnson_Pic2024.5.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4600004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ce92e755-b019-42b5-be4e-8a8e432cbe0b-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4600004));

-- Marty Jackley (SD, ext -4600003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/6/69/US_District_Attorney_Marty_Jackley.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4600003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2537050a-cd40-460e-9751-1d982dd73c25-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4600003));

-- Tony Venhuizen (SD, ext -4600002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/8/80/Tony_Venhuizen_speaks_at_Joe_Foss_Field_2025_Cropped.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4600002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e9bdb9ac-9680-4a32-8da8-3a3f84f742c2-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4600002));

-- Larry Rhoden (SD, ext -4600001) — cc_by_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/e/e3/Larry_Rhoden_2025_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4600001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0a283b10-918c-4251-899b-5385c9174b6d-headshot.jpg', 'default', 'cc_by_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4600001));

-- HONEST-SKIPS (no free-licensed portrait found; McDowell precedent):
--   ext -4600005 Josh Haeder (SD): no-lead-image

COMMIT;
