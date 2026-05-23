-- sj_headshots.sql -- AUDIT ONLY -- not in numbered migration ledger
-- San Jose official headshots uploaded to Supabase Storage + politician_images rows
-- Executed: 2026-05-23
-- All images: 600x750 pixels, 4:5 aspect ratio, JPEG quality 90
-- type='default' (NOT 'headshot') -- UI filters by type='default'

BEGIN;

-- Mayor Matt Mahan (-640001)
-- Source: Wikimedia Commons CC-BY-SA 4.0 (Matt_Mahan_portrait_2025.jpg)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
VALUES (
  gen_random_uuid(),
  '41949a2b-563a-4608-91c6-951c63252a91',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/41949a2b-563a-4608-91c6-951c63252a91-headshot.jpg',
  'default',
  'cc-by-sa-4.0',
  NULL
)
ON CONFLICT DO NOTHING;

-- D1 Rosemary Kamei (-640010)
-- Source: sanjoseca.gov showpublishedimage/18393 (public domain)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
VALUES (
  gen_random_uuid(),
  '7921e8f3-2e6f-47f8-bc2b-95b81bab6516',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7921e8f3-2e6f-47f8-bc2b-95b81bab6516-headshot.jpg',
  'default',
  'public_domain',
  NULL
)
ON CONFLICT DO NOTHING;

-- D2 Pamela Campos (-640011)
-- Source: sjdistrict2.org Official Portrait (public domain)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
VALUES (
  gen_random_uuid(),
  '104cca89-3420-457b-a35d-b446be2d72ab',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/104cca89-3420-457b-a35d-b446be2d72ab-headshot.jpg',
  'default',
  'public_domain',
  NULL
)
ON CONFLICT DO NOTHING;

-- D3 Anthony Tordillos (-640012)
-- Source: sjdistrict3.org CM Tordillos First Day (public domain)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
VALUES (
  gen_random_uuid(),
  '7b527446-d801-42c6-9233-053c2b02e128',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7b527446-d801-42c6-9233-053c2b02e128-headshot.jpg',
  'default',
  'public_domain',
  NULL
)
ON CONFLICT DO NOTHING;

-- D4 David Cohen (-640013)
-- Source: sanjosedistrict4.com (public domain)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
VALUES (
  gen_random_uuid(),
  '83292881-92b3-4257-b291-4b02509a167c',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/83292881-92b3-4257-b291-4b02509a167c-headshot.jpg',
  'default',
  'public_domain',
  NULL
)
ON CONFLICT DO NOTHING;

-- D5 Peter Ortiz (-640014)
-- Source: Wikimedia Commons public domain (Peter_Ortiz,_San_Jose_City_Councilman.png)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
VALUES (
  gen_random_uuid(),
  'a464cef9-de7f-45a3-8ff3-9bab20275db4',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a464cef9-de7f-45a3-8ff3-9bab20275db4-headshot.jpg',
  'default',
  'public_domain',
  NULL
)
ON CONFLICT DO NOTHING;

-- D6 Michael Mulcahy (-640015)
-- Source: sanjoseca.gov showpublishedimage/23362 (public domain)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
VALUES (
  gen_random_uuid(),
  'a05e1faa-c780-4a65-b01f-cca7e6f0210b',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a05e1faa-c780-4a65-b01f-cca7e6f0210b-headshot.jpg',
  'default',
  'public_domain',
  NULL
)
ON CONFLICT DO NOTHING;

-- D7 Bien Doan (-640016)
-- Source: Wikimedia Commons public domain (Bien_Doan,_San_Jose_City_Councilman.png)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
VALUES (
  gen_random_uuid(),
  'e4ac6674-1fa3-422a-857f-570873b86da3',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e4ac6674-1fa3-422a-857f-570873b86da3-headshot.jpg',
  'default',
  'public_domain',
  NULL
)
ON CONFLICT DO NOTHING;

-- D8 Domingo Candelas (-640017)
-- Source: Wikimedia Commons public domain (Domingo_Candelas,_San_Jose_City_Councilman.png)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
VALUES (
  gen_random_uuid(),
  'ab7cf49d-73af-4391-9a15-ebe0522e5bc5',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ab7cf49d-73af-4391-9a15-ebe0522e5bc5-headshot.jpg',
  'default',
  'public_domain',
  NULL
)
ON CONFLICT DO NOTHING;

-- D9 Pam Foley (-640018)
-- Source: Wikimedia Commons public domain (Foley_Pam_-_San_Jose_City_Councilwoman.jpg)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
VALUES (
  gen_random_uuid(),
  '3c9b607b-5dd6-43ab-ac4f-cab553adb7ab',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3c9b607b-5dd6-43ab-ac4f-cab553adb7ab-headshot.jpg',
  'default',
  'public_domain',
  NULL
)
ON CONFLICT DO NOTHING;

-- D10 George Casey (-640019)
-- Source: sjdistrict10.org (public domain)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license, focal_point)
VALUES (
  gen_random_uuid(),
  'f0d4ce8b-4ed7-45ec-b08e-439dded83313',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f0d4ce8b-4ed7-45ec-b08e-439dded83313-headshot.jpg',
  'default',
  'public_domain',
  NULL
)
ON CONFLICT DO NOTHING;

COMMIT;
