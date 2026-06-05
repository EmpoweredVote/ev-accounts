-- Migration 200: SF Official Headshots
-- Audit-only: captures the live politician_images INSERTs and photo_origin_url UPDATEs
-- performed during Phase 63-03 execution on 2026-05-22.
-- DO NOT apply via Supabase ledger -- actual DB writes happened live.
-- Next migration is 207.
--
-- 20 SF officials: external_ids -630001..-630011 (supervisors) and -630020..-630028 (citywide+appointed)
-- Sources: media.api.sf.gov (public domain), sftreasurer.org (public domain),
--          Wikimedia Commons (public domain for Miyamoto)
-- Supervisors note: sf.gov circular _profile.png files have transparent corners (alpha=0).
--   After 4:5 center crop the transparent corners are outside the crop region -- no artifacts.
--   Both sf.gov and sfbos.org only expose the circular PNG; no rectangular alternative exists.

BEGIN;

-- ============================================================
-- BOARD OF SUPERVISORS (11)
-- ============================================================

-- Connie Chan (-630001)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f3f21e38-d8e6-41d2-9d74-0360a5f679b9-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630001)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/D01-Connie_Chan_2025_profile.png' WHERE external_id = -630001 AND photo_origin_url IS NULL;

-- Stephen Sherrill (-630002)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/54e564e7-4788-4913-b75e-95382896d509-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630002)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/D02-Stephen_Sherrill_2025_profile.png' WHERE external_id = -630002 AND photo_origin_url IS NULL;

-- Danny Sauter (-630003)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d1a320a9-39e9-4152-85a0-11cab602fdc9-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630003)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/D03-Danny_Sauter_2025_profile.png' WHERE external_id = -630003 AND photo_origin_url IS NULL;

-- Alan Wong (-630004)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6273727a-26e0-495d-9fda-f827b88029b3-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630004)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/D04-Alan_Wong_2026_profile.png' WHERE external_id = -630004 AND photo_origin_url IS NULL;

-- Bilal Mahmood (-630005)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d3c5004c-9ca0-444e-96d9-107d4315abcb-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630005)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/D05-Bilal_Mahmood_2025_profile.png' WHERE external_id = -630005 AND photo_origin_url IS NULL;

-- Matt Dorsey (-630006)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/68845df3-7103-45d9-8429-7ef51ee6ada3-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630006)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/D06-Matt_Dorsey_2025_profile.png' WHERE external_id = -630006 AND photo_origin_url IS NULL;

-- Myrna Melgar (-630007)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/72621ac9-bcdb-4ea3-aeec-1b1f50c9f996-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630007)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/D07-Myrna_Melgar_2025_profile.png' WHERE external_id = -630007 AND photo_origin_url IS NULL;

-- Rafael Mandelman (-630008)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d2596e4d-f491-449e-b112-40be13418112-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630008)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/D08-Rafael_Mandelman_2025_profile.png' WHERE external_id = -630008 AND photo_origin_url IS NULL;

-- Jackie Fielder (-630009)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630009),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/02f88a57-ccf5-4fe1-a693-7fc949321fb1-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630009)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/D09-Jackie-Fielder_2025_profile.png' WHERE external_id = -630009 AND photo_origin_url IS NULL;

-- Shamann Walton (-630010)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eab7b830-c831-45f9-bca8-11b079f42680-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630010)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/D10-Shamann_Walton_2025_profile.png' WHERE external_id = -630010 AND photo_origin_url IS NULL;

-- Chyanne Chen (-630011)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8f59c9fd-03f9-4652-bc4a-418bd8764a1f-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630011)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/D11-Chyanne_Chen_2025_profile.png' WHERE external_id = -630011 AND photo_origin_url IS NULL;

-- ============================================================
-- MAYOR
-- ============================================================

-- Daniel Lurie (-630020)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630020),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/708db738-2bf1-4a6f-b8a5-7ac23d171b33-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630020)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/daniel_lurie_KeVK6TD.jpg' WHERE external_id = -630020 AND photo_origin_url IS NULL;

-- ============================================================
-- CITYWIDE ELECTED OFFICIALS
-- ============================================================

-- David Chiu (-630021, City Attorney)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630021),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/86c12b33-cb76-41da-bdf0-6b58a0cbbed6-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630021)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/DC_Headshot.jpg' WHERE external_id = -630021 AND photo_origin_url IS NULL;

-- Brooke Jenkins (-630022, DA)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630022),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/969f1ca4-4766-44fd-8638-ef813b1835e7-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630022)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/Brooke_Jenkins_-_cropped_m2XGRTD.jpg' WHERE external_id = -630022 AND photo_origin_url IS NULL;

-- Paul Miyamoto (-630023, Sheriff)
-- Source: Wikimedia Commons - official SFSO portrait, public domain (PD California)
-- Original source credit: m.sfsheriff.com/executives.html (no longer live)
-- Commons page: https://commons.wikimedia.org/wiki/File:Paul_Miyamoto,_2020.jpg
-- Note: www.sfsheriff.com had no individual headshot page; "ewww" subdomain in original research was a typo
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630023),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630023)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://commons.wikimedia.org/wiki/File:Paul_Miyamoto,_2020.jpg' WHERE external_id = -630023 AND photo_origin_url IS NULL;

-- Joaquin Torres (-630024, Assessor-Recorder)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630024),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630024)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/Joaquin_Torres_-_spotlight_image.jpeg' WHERE external_id = -630024 AND photo_origin_url IS NULL;

-- Jose Cisneros (-630025, Treasurer)
-- Source: sftreasurer.org official headshot (public domain)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630025),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/94035c6d-d6b2-4223-bdeb-e93e2ec26198-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630025)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://sftreasurer.org/sites/default/files/inline-images/IMG_8134b_0.jpg' WHERE external_id = -630025 AND photo_origin_url IS NULL;

-- Manohar Raju (-630026, Public Defender)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630026),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/aa35ed62-a5a7-47fd-99d3-0ceb3336e405-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630026)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/Manohar_Raju_-_cropped.png' WHERE external_id = -630026 AND photo_origin_url IS NULL;

-- ============================================================
-- APPOINTED OFFICIALS
-- ============================================================

-- Greg Wagner (-630027, Controller)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630027),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c3627dfd-6f20-40e8-b9af-55c4af048d92-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630027)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/Greg_Wagner_for_SF.GOV__0_6ERJ9o4.jpg' WHERE external_id = -630027 AND photo_origin_url IS NULL;

-- Carmen Chu (-630028, City Administrator)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -630028),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f82edba8-5f6b-4c00-af78-b782426f05a2-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -630028)
);
-- UPDATE essentials.politicians SET photo_origin_url = 'https://media.api.sf.gov/original_images/carmen_chu_hero_two_ts2GlAY.png' WHERE external_id = -630028 AND photo_origin_url IS NULL;

COMMIT;
