-- 989_state_exec_headshots_batch_e.sql
-- Phase 141 (v2.18 State Leaders), plan 141-12. AUDIT-ONLY (mirrors migration 271).
-- Actual headshot uploads to the politician_photos bucket + politician_images INSERTs happened LIVE via
-- backend/scripts/seed-state-exec-headshots.py (Wikipedia pageimages -> PIL crop 4:5 -> 600x750 LANCZOS q90).
-- These INSERTs reproduce that record idempotently (column `url`, WHERE NOT EXISTS). Re-apply = no-op.
-- Batch E: 35 headshots recorded.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/migrations/989_state_exec_headshots_batch_e.sql

BEGIN;

-- Kimberly Yee (AZ, ext -400094) — cc_by-sa_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/8/87/Kimberly_Yee_by_Gage_Skidmore_3.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-400094),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ad8c25f3-538c-48f3-b8db-1d72d7d6d4ca-headshot.jpg', 'default', 'cc_by-sa_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-400094));

-- Adrian Fontes (AZ, ext -400093) — cc_by-sa_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/3/39/Adrian_Fontes_2025.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-400093),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/352876f0-02b4-4eba-b979-c99079ab368a-headshot.jpg', 'default', 'cc_by-sa_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-400093));

-- Kris Mayes (AZ, ext -400092) — cc_by-sa_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/f/f2/Kris_Mayes_%2852365525231%29_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-400092),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e947c3c1-41f5-48d8-b105-5a0c39aa21ae-headshot.jpg', 'default', 'cc_by-sa_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-400092));

-- Katie Hobbs (AZ, ext -400091) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/0/02/Katie_Hobbs_2026.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-400091),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ca092ddd-8ce5-4521-bbbe-38f453650b04-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-400091));

-- Colleen Davis (DE, ext -1000004) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/2/2e/Colleen_Davis_%2852834741300%29_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1000004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bfbe44f7-8fd9-470d-8212-5d5443698be0-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1000004));

-- Kathy Jennings (DE, ext -1000003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/8/86/Kathy_Jennings_CFPB.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1000003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/811bd5cb-8c0f-41a5-b78b-18d76151b994-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1000003));

-- Kyle Evans Gay (DE, ext -1000002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/e/e5/%2802-19-2025%29_Kyle_Evans_Gay.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1000002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1b28d09f-baec-4d7b-ad75-2a07d09f5a56-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1000002));

-- Matt Meyer (DE, ext -1000001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/a/a6/%2802-19-2025%29_Matt_Meyer.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1000001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8c54630e-3054-468b-a686-96da6b9ba814-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1000001));

-- Julie Ellsworth (ID, ext -1600005) — public_domain
--   source: https://sto.idaho.gov/portals/0/About/Ellsworth_About.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1600005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ae007cc6-29f6-4b29-8f42-1770ed9f2d8a-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1600005));

-- Phil McGrane (ID, ext -1600004) — public_domain
--   source: C:/tmp/phil-mcgrane-id-sos.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1600004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ade5ce47-25a7-4332-848f-877404875f0e-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1600004));

-- Raul Labrador (ID, ext -1600003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/5/5b/Raul_Labrador_115th.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1600003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e0bab0e6-dc32-4d68-a479-0f59a79c0cf4-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1600003));

-- Scott Bedke (ID, ext -1600002) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/8/8b/Scott_Bedke_in_2022_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1600002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8cb018dc-a962-47b1-813c-6d1322b36037-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1600002));

-- Brad Little (ID, ext -1600001) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/b/bc/Brad_Little_official_photo.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-1600001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d36ab4ef-dbf4-4b60-9f8b-db497dfb5de4-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-1600001));

-- John Fleming (LA, ext -2200005) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/c/cb/John_Fleming_official_photo_%28alt_crop%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2200005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a750bce8-a3ec-45fb-9812-5bb6f726e32f-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2200005));

-- Nancy Landry (LA, ext -2200004) — public_domain
--   source: https://www.sos.la.gov/OurOffice/LearnAboutNancyLandry/Documents/NancyLandry.png
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2200004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0ed76bd2-273d-4057-9c4e-4259d6cb9ebc-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2200004));

-- Liz Murrill (LA, ext -2200003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/2/2f/Liz_Murrill_2024_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2200003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c64d9edb-e0e4-4c88-ad33-e403cd3357e8-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2200003));

-- Billy Nungesser (LA, ext -2200002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/5/5c/Billy_Nungesser_2019.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2200002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/966929f1-e57f-4250-a847-88ca35c9b99e-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2200002));

-- Jeff Landry (LA, ext -2200001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/d/d2/Jeff_Landry_2025.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-2200001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c2a6cf9d-deb7-4ec7-9f97-cf300da8da6c-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-2200001));

-- Christi Jacobsen (MT, ext -3000004) — public_domain
--   source: https://sosmt.gov/wp-content/uploads/SecretaryChristiJacobsenFlag.webp
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3000004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/02d7fc27-36ed-43c3-9c7b-c68b9012527c-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3000004));

-- Austin Knudsen (MT, ext -3000003) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/3/3a/Austin_Knudsen.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3000003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3b4ba5e3-226c-4b36-9613-81865f982437-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3000003));

-- Kristen Juras (MT, ext -3000002) — cc_by_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/d/dd/Kristen_Juras.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3000002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cd97be85-d6cf-4d08-ab0b-415a06d69d8c-headshot.jpg', 'default', 'cc_by_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3000002));

-- Greg Gianforte (MT, ext -3000001) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/5/5c/Greg_Gianforte_in_2025_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3000001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1021e185-125e-4004-91bb-436a9727e4a9-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3000001));

-- Laura Montoya (NM, ext -3500005) — cc_by_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/1/1a/Laura_Montoya_54596229497_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3500005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9d8e3a1a-dd68-433e-8f5c-6056317845d5-headshot.jpg', 'default', 'cc_by_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3500005));

-- Maggie Toulouse Oliver (NM, ext -3500004) — cc_by_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/b/b3/Maggie_Toulouse_Oliver.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3500004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6b1f2035-1e85-4fca-a5e8-b34e0600a473-headshot.jpg', 'default', 'cc_by_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3500004));

-- Raul Torrez (NM, ext -3500003) — cc0
--   source: https://upload.wikimedia.org/wikipedia/commons/0/05/Ra%C3%BAl_Torrez_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3500003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e61e062d-cde2-424b-b384-ae4eb4bfc6bf-headshot.jpg', 'default', 'cc0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3500003));

-- Howie Morales (NM, ext -3500002) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/4/40/Lt._Governor_Presiding_in_the_Senate_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3500002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f6456243-9b0e-4c5c-87b2-3740bf833b4b-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3500002));

-- Michelle Lujan Grisham (NM, ext -3500001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/b/b9/Michelle_Lujan_Grisham_2026.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-3500001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d23c3cc7-61e8-4dc3-8a5a-9347546dc0f2-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-3500001));

-- Curtis Loftis (SC, ext -4500005) — cc_by-sa_3.0
--   source: https://upload.wikimedia.org/wikipedia/commons/7/78/Cutris_Loftis_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4500005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0a0736c2-3e12-4296-9abe-d2b7a793c8b8-headshot.jpg', 'default', 'cc_by-sa_3.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4500005));

-- Mark Hammond (SC, ext -4500004) — public_domain
--   source: https://sos.sc.gov/sites/sos/files/Documents/Images/SAM_6321_600.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4500004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/559e7f33-2285-4cc8-bf8b-4cb88839157e-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4500004));

-- Alan Wilson (SC, ext -4500003) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/e/ee/JAG_Passing_Alan_Wilson.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4500003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/36120b17-6913-4ac0-bbc2-deaba73e8cf7-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4500003));

-- Pamela Evette (SC, ext -4500002) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/5/59/Pamela_Evette_2019.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4500002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d16c6510-340c-485a-aa90-04ddb2f6ca24-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4500002));

-- Henry McMaster (SC, ext -4500001) — cc_by-sa_4.0
--   source: https://upload.wikimedia.org/wikipedia/commons/7/78/Henry_McMaster_in_2026_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-4500001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3043a446-7107-4532-bd90-9f1a5a2f58a1-headshot.jpg', 'default', 'cc_by-sa_4.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-4500001));

-- Curt Meier (WY, ext -5600003) — wtfpl
--   source: https://upload.wikimedia.org/wikipedia/commons/5/56/Curt_Meier_at_Campbell_County_League_of_Women_Voters%27_General_Election_Candidates%27_Forum_in_Gillette%2C_Wyoming_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5600003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2fd0ec31-7193-451a-90aa-1754aba860cb-headshot.jpg', 'default', 'wtfpl'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5600003));

-- Chuck Gray (WY, ext -5600002) — cc_by-sa_2.0
--   source: https://upload.wikimedia.org/wikipedia/commons/9/9c/Chuck_Gray_in_2025_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5600002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b503b679-773a-4eee-9c16-e73bff1a723f-headshot.jpg', 'default', 'cc_by-sa_2.0'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5600002));

-- Mark Gordon (WY, ext -5600001) — public_domain
--   source: https://upload.wikimedia.org/wikipedia/commons/8/8b/Wyoming_Governor_Mark_Gordon_expands_partnership_with_Tunisia_to_enhance_agriculture_and_civil_protection_%284%29_%28cropped%29.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), (SELECT id FROM essentials.politicians WHERE external_id=-5600001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/163b9f2f-8170-4d5a-947d-ef5a3c8fb4c8-headshot.jpg', 'default', 'public_domain'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
  WHERE politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5600001));

-- No honest-skips in this batch.

COMMIT;
