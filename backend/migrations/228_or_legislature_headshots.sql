-- Migration 228: OR State Legislature Headshots (AUDIT-ONLY)
-- Writes already happened via Plan 75-03 Tasks 1 and 2 (2026-05-29)
-- NOT applied via mcp__supabase-local__apply_migration
-- Source: oregonlegislature.gov MemberPhotos (senate + house)
-- All images: 600x750 LANCZOS q90, cropped to 4:5 ratio first
-- type='default', photo_license='public_domain'

BEGIN;

-- ===== SENATORS (30) — SD-01 through SD-30 =====

-- SD-01: David Brock Smith (Republican) — source: smithdb.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '5350c0ba-0ef4-4021-a620-90820df859b7'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5350c0ba-0ef4-4021-a620-90820df859b7-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '5350c0ba-0ef4-4021-a620-90820df859b7' AND type = 'default'
);

-- SD-02: Noah Robinson (Republican) — source: robinsonn.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '13ce589f-756e-4968-881f-c8cc95dae404'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/13ce589f-756e-4968-881f-c8cc95dae404-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '13ce589f-756e-4968-881f-c8cc95dae404' AND type = 'default'
);

-- SD-03: Jeff Golden (Democratic) — source: golden.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '21b454d4-e6a5-48fe-9bd1-0da84f2a1a39'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/21b454d4-e6a5-48fe-9bd1-0da84f2a1a39-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '21b454d4-e6a5-48fe-9bd1-0da84f2a1a39' AND type = 'default'
);

-- SD-04: Floyd Prozanski (Democratic) — source: prozanski.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'b6f5cd9e-a9d2-44ff-9027-0d931765f378'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b6f5cd9e-a9d2-44ff-9027-0d931765f378-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'b6f5cd9e-a9d2-44ff-9027-0d931765f378' AND type = 'default'
);

-- SD-05: Dick Anderson (Republican) — source: andersond.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd9803822-6bf8-437d-aa4b-d7e6b4a67b7c'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d9803822-6bf8-437d-aa4b-d7e6b4a67b7c-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'd9803822-6bf8-437d-aa4b-d7e6b4a67b7c' AND type = 'default'
);

-- SD-06: Cedric Hayden (Republican) — source: hayden.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd3dedaa7-bda5-4e3d-af18-6214719d6e1e'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d3dedaa7-bda5-4e3d-af18-6214719d6e1e-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'd3dedaa7-bda5-4e3d-af18-6214719d6e1e' AND type = 'default'
);

-- SD-07: James I. Manning Jr. (Democratic) — source: manning.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e' AND type = 'default'
);

-- SD-08: Sara Gelser Blouin (Democratic) — source: gelser.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1ca1abf1-9523-499c-b644-0b32c61257c6'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1ca1abf1-9523-499c-b644-0b32c61257c6-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '1ca1abf1-9523-499c-b644-0b32c61257c6' AND type = 'default'
);

-- SD-09: Fred Girod (Republican) — source: girod.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '6b107b84-afbe-4141-8951-bafb65543dda'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6b107b84-afbe-4141-8951-bafb65543dda-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '6b107b84-afbe-4141-8951-bafb65543dda' AND type = 'default'
);

-- SD-10: Deb Patterson (Democratic) — source: patterson.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '631cc414-8793-42ec-b883-594ed7f0b249'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/631cc414-8793-42ec-b883-594ed7f0b249-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '631cc414-8793-42ec-b883-594ed7f0b249' AND type = 'default'
);

-- SD-11: Kim Thatcher (Republican) — source: thatcher.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'b548a0f7-5086-4124-a510-49ef8f60f515'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b548a0f7-5086-4124-a510-49ef8f60f515-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'b548a0f7-5086-4124-a510-49ef8f60f515' AND type = 'default'
);

-- SD-12: Bruce Starr (Republican) — source: starrb.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0c228d44-a876-4371-bdfd-13fdfd8ea9b6'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0c228d44-a876-4371-bdfd-13fdfd8ea9b6-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '0c228d44-a876-4371-bdfd-13fdfd8ea9b6' AND type = 'default'
);

-- SD-13: Courtney Neron Misslin (Democratic) — source: neron.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'dcdc002c-8fd6-415a-a30a-8fc70c83d9ff'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dcdc002c-8fd6-415a-a30a-8fc70c83d9ff-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'dcdc002c-8fd6-415a-a30a-8fc70c83d9ff' AND type = 'default'
);

-- SD-14: Kate Lieber (Democratic) — source: lieber.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '529ea93b-c234-4df5-ae22-6ba32d0ae9a4'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/529ea93b-c234-4df5-ae22-6ba32d0ae9a4-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '529ea93b-c234-4df5-ae22-6ba32d0ae9a4' AND type = 'default'
);

-- SD-15: Janeen Sollman (Democratic) — source: sollman.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'fa9d50e7-7e9b-4eed-b105-bf8277b51f95'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fa9d50e7-7e9b-4eed-b105-bf8277b51f95-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'fa9d50e7-7e9b-4eed-b105-bf8277b51f95' AND type = 'default'
);

-- SD-16: Suzanne Weber (Republican) — source: weber.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd34df5c8-9534-4472-814d-971adff16f50'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d34df5c8-9534-4472-814d-971adff16f50-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'd34df5c8-9534-4472-814d-971adff16f50' AND type = 'default'
);

-- SD-17: Lisa Reynolds (Democratic) — source: Reynolds.jpg (sentinel)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd910cf6e-7d70-4b0c-b883-2fe2dcb185b6'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d910cf6e-7d70-4b0c-b883-2fe2dcb185b6-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'd910cf6e-7d70-4b0c-b883-2fe2dcb185b6' AND type = 'default'
);

-- SD-18: Wlnsvey Campos (Democratic) — source: campos.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '95300e6e-ea4e-47f9-8a24-5f6f762d5c73'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/95300e6e-ea4e-47f9-8a24-5f6f762d5c73-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '95300e6e-ea4e-47f9-8a24-5f6f762d5c73' AND type = 'default'
);

-- SD-19: Rob Wagner (Democratic) — source: wagner.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '14faa864-de9f-497f-a78a-db41f42ee5e0'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/14faa864-de9f-497f-a78a-db41f42ee5e0-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '14faa864-de9f-497f-a78a-db41f42ee5e0' AND type = 'default'
);

-- SD-20: Mark Meek (Democratic) — source: meek.jpg (derived, not on scrape list)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'be46ed6d-363e-46f4-89d4-c95d9af67db1'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/be46ed6d-363e-46f4-89d4-c95d9af67db1-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'be46ed6d-363e-46f4-89d4-c95d9af67db1' AND type = 'default'
);

-- SD-21: Kathleen Taylor (Democratic) — source: taylor.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '4b4702e0-3b88-4fd0-aa17-aa379be0dbac'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4b4702e0-3b88-4fd0-aa17-aa379be0dbac-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '4b4702e0-3b88-4fd0-aa17-aa379be0dbac' AND type = 'default'
);

-- SD-22: Lew Frederick (Democratic) — source: frederick.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'ae4b1163-e9a7-4529-a8f2-5610f6c93cbd'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ae4b1163-e9a7-4529-a8f2-5610f6c93cbd-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'ae4b1163-e9a7-4529-a8f2-5610f6c93cbd' AND type = 'default'
);

-- SD-23: Khanh Pham (Democratic) — source: pham.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e' AND type = 'default'
);

-- SD-24: Kayse Jama (Democratic) — source: jama.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'a703adb5-1086-471b-ba8b-2dbeddd8102b'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a703adb5-1086-471b-ba8b-2dbeddd8102b-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'a703adb5-1086-471b-ba8b-2dbeddd8102b' AND type = 'default'
);

-- SD-25: Chris Gorsek (Democratic) — source: gorsek.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '22a1e980-4f15-435d-a0c4-1a08202d6bb5'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/22a1e980-4f15-435d-a0c4-1a08202d6bb5-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '22a1e980-4f15-435d-a0c4-1a08202d6bb5' AND type = 'default'
);

-- SD-26: Christine Drazan (Republican) — source: drazan.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '402a00be-71c3-4584-b29f-bf493365bffb'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/402a00be-71c3-4584-b29f-bf493365bffb-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '402a00be-71c3-4584-b29f-bf493365bffb' AND type = 'default'
);

-- SD-27: Anthony Broadman (Democratic) — source: broadman.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '3af0dfad-d1a1-4c91-a859-6f17c5e238b9'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3af0dfad-d1a1-4c91-a859-6f17c5e238b9-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '3af0dfad-d1a1-4c91-a859-6f17c5e238b9' AND type = 'default'
);

-- SD-28: Diane Linthicum (Republican) — source: linthicumd.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '50eab431-7b51-4a56-acaa-61af3509c298'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/50eab431-7b51-4a56-acaa-61af3509c298-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '50eab431-7b51-4a56-acaa-61af3509c298' AND type = 'default'
);

-- SD-29: Todd Nash (Republican) — source: nash.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '86d23630-36ff-48a7-b2ac-6071a0cabd64'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/86d23630-36ff-48a7-b2ac-6071a0cabd64-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '86d23630-36ff-48a7-b2ac-6071a0cabd64' AND type = 'default'
);

-- SD-30: Mike McLane (Republican) — source: mclane.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '252a2adf-68a5-4b5a-9024-d5635e2fbd88'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/252a2adf-68a5-4b5a-9024-d5635e2fbd88-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '252a2adf-68a5-4b5a-9024-d5635e2fbd88' AND type = 'default'
);


-- ===== HOUSE REPRESENTATIVES (60) — HD-01 through HD-60 =====

-- HD-01: Court Boice (Republican) — source: boice.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0e3b9216-cfb9-411f-b80e-684ccaae593f'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0e3b9216-cfb9-411f-b80e-684ccaae593f-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '0e3b9216-cfb9-411f-b80e-684ccaae593f' AND type = 'default'
);

-- HD-02: Virgle Osborne (Republican) — source: osborne.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '558e9c8c-5e52-4685-9e24-1367810f8030'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/558e9c8c-5e52-4685-9e24-1367810f8030-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '558e9c8c-5e52-4685-9e24-1367810f8030' AND type = 'default'
);

-- HD-03: Dwayne Yunker (Republican) — source: yunker.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f74bb46f-4e4a-47c0-a3d7-285e57cf8d4d'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f74bb46f-4e4a-47c0-a3d7-285e57cf8d4d-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'f74bb46f-4e4a-47c0-a3d7-285e57cf8d4d' AND type = 'default'
);

-- HD-04: Alek Skarlatos (Republican) — source: skarlatos.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '35d2729c-b754-4fad-b124-10ee437a116f'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/35d2729c-b754-4fad-b124-10ee437a116f-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '35d2729c-b754-4fad-b124-10ee437a116f' AND type = 'default'
);

-- HD-05: Pam Marsh (Democratic) — source: marsh.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '03af5908-a069-4ab7-91db-2f388a885bf9'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/03af5908-a069-4ab7-91db-2f388a885bf9-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '03af5908-a069-4ab7-91db-2f388a885bf9' AND type = 'default'
);

-- HD-06: Kim Wallan (Republican) — source: wallan.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '3778353d-cbc9-43cf-866a-a7c01397503a'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3778353d-cbc9-43cf-866a-a7c01397503a-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '3778353d-cbc9-43cf-866a-a7c01397503a' AND type = 'default'
);

-- HD-07: John Lively (Democratic) — source: lively.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d' AND type = 'default'
);

-- HD-08: Lisa Fragala (Democratic) — source: fragala.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac' AND type = 'default'
);

-- HD-09: Boomer Wright (Republican) — source: wright.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd5386673-4244-44ca-8e54-e1af61803f6e'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d5386673-4244-44ca-8e54-e1af61803f6e-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'd5386673-4244-44ca-8e54-e1af61803f6e' AND type = 'default'
);

-- HD-10: David Gomberg (Democratic) — source: gomberg.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '00ddecfd-648a-4118-82e6-a60327068b32'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/00ddecfd-648a-4118-82e6-a60327068b32-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '00ddecfd-648a-4118-82e6-a60327068b32' AND type = 'default'
);

-- HD-11: Jami Cate (Republican) — source: cate.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'c854f51f-0ab0-4b46-9397-596501e3ee67'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c854f51f-0ab0-4b46-9397-596501e3ee67-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'c854f51f-0ab0-4b46-9397-596501e3ee67' AND type = 'default'
);

-- HD-12: Darin Harbick (Republican) — source: harbick.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f3fb09eb-adb0-4543-b6a2-32f90003569b'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f3fb09eb-adb0-4543-b6a2-32f90003569b-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'f3fb09eb-adb0-4543-b6a2-32f90003569b' AND type = 'default'
);

-- HD-13: Nancy Nathanson (Democratic) — source: nathanson.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'ca404c61-11af-43d9-9563-07dde3f7b8e7'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ca404c61-11af-43d9-9563-07dde3f7b8e7-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'ca404c61-11af-43d9-9563-07dde3f7b8e7' AND type = 'default'
);

-- HD-14: Julie Fahey (Democratic) — source: fahey.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '24398310-8e0c-487e-a11c-253e3060f77c'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/24398310-8e0c-487e-a11c-253e3060f77c-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '24398310-8e0c-487e-a11c-253e3060f77c' AND type = 'default'
);

-- HD-15: Shelly Boshart Davis (Republican) — source: davis.jpg (last word of compound surname)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '4919fd6a-c250-47b2-a37d-37b1eec8c63d'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4919fd6a-c250-47b2-a37d-37b1eec8c63d-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '4919fd6a-c250-47b2-a37d-37b1eec8c63d' AND type = 'default'
);

-- HD-16: Sarah Finger McDonald (Democratic) — source: mcdonald.jpg (last word of compound surname)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '2a116530-8d06-41b5-b965-50d943eae8c2'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2a116530-8d06-41b5-b965-50d943eae8c2-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '2a116530-8d06-41b5-b965-50d943eae8c2' AND type = 'default'
);

-- HD-17: Ed Diehl (Republican) — source: diehl.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'ea9746ba-9fd2-4622-b781-b3ed35d18d17'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ea9746ba-9fd2-4622-b781-b3ed35d18d17-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'ea9746ba-9fd2-4622-b781-b3ed35d18d17' AND type = 'default'
);

-- HD-18: Rick Lewis (Republican) — source: lewis.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'aa57168d-58b8-4f70-a937-09fdaf18b325'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/aa57168d-58b8-4f70-a937-09fdaf18b325-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'aa57168d-58b8-4f70-a937-09fdaf18b325' AND type = 'default'
);

-- HD-19: Tom Andersen (Democratic) — source: andersen.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '5b81e68c-3ec3-4c81-9f1b-010db86da9c0'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5b81e68c-3ec3-4c81-9f1b-010db86da9c0-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '5b81e68c-3ec3-4c81-9f1b-010db86da9c0' AND type = 'default'
);

-- HD-20: Paul Evans (Democratic) — source: evans.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'e5c0549e-4454-4cea-b7dc-67eb17d28b49'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e5c0549e-4454-4cea-b7dc-67eb17d28b49-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'e5c0549e-4454-4cea-b7dc-67eb17d28b49' AND type = 'default'
);

-- HD-21: Kevin Mannix (Republican) — source: mannix.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '2edbb7a5-a798-4088-8939-7b44b51e682c'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2edbb7a5-a798-4088-8939-7b44b51e682c-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '2edbb7a5-a798-4088-8939-7b44b51e682c' AND type = 'default'
);

-- HD-22: Lesly Munoz (Democratic) — source: munoz.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7360da53-a6df-42d9-89b4-fff76af23de6'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7360da53-a6df-42d9-89b4-fff76af23de6-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '7360da53-a6df-42d9-89b4-fff76af23de6' AND type = 'default'
);

-- HD-23: Anna Scharf (Republican) — source: scharf.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0cd6ccff-e02d-4cbe-a1df-381226292840'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0cd6ccff-e02d-4cbe-a1df-381226292840-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '0cd6ccff-e02d-4cbe-a1df-381226292840' AND type = 'default'
);

-- HD-24: Lucetta Elmer (Republican) — source: elmer.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7bba19f8-0a1f-4ee2-852f-63bb38ffef6e'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7bba19f8-0a1f-4ee2-852f-63bb38ffef6e-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '7bba19f8-0a1f-4ee2-852f-63bb38ffef6e' AND type = 'default'
);

-- HD-25: Ben Bowman (Democratic) — source: bowman.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '5e29b685-1f2e-4963-83a8-a7bde5b5250e'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5e29b685-1f2e-4963-83a8-a7bde5b5250e-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '5e29b685-1f2e-4963-83a8-a7bde5b5250e' AND type = 'default'
);

-- HD-26: Sue Rieke Smith (Democratic) — source: riekesmith.jpg (compound surname concatenated)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0d5a4aeb-121f-461c-b379-a8a00c3b1ba1'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0d5a4aeb-121f-461c-b379-a8a00c3b1ba1-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '0d5a4aeb-121f-461c-b379-a8a00c3b1ba1' AND type = 'default'
);

-- HD-27: Ken Helm (Democratic) — source: helm.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '40ecc3a4-ca59-48c4-8b17-634cc385bc9a'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/40ecc3a4-ca59-48c4-8b17-634cc385bc9a-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '40ecc3a4-ca59-48c4-8b17-634cc385bc9a' AND type = 'default'
);

-- HD-28: Dacia Grayber (Democratic) — source: grayber.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'c5640f05-239a-47fd-97f3-e284859c1cc9'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c5640f05-239a-47fd-97f3-e284859c1cc9-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'c5640f05-239a-47fd-97f3-e284859c1cc9' AND type = 'default'
);

-- HD-29: Susan McLain (Democratic) — source: mclain.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '3fbaa80c-be2d-411f-a3ab-95add9ae6c84'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3fbaa80c-be2d-411f-a3ab-95add9ae6c84-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '3fbaa80c-be2d-411f-a3ab-95add9ae6c84' AND type = 'default'
);

-- HD-30: Nathan Sosa (Democratic) — source: sosa.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f2bc3bbf-0d29-4ad9-b675-9c53cf081969'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f2bc3bbf-0d29-4ad9-b675-9c53cf081969-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'f2bc3bbf-0d29-4ad9-b675-9c53cf081969' AND type = 'default'
);

-- HD-31: Darcey Edwards (Republican) — source: edwardsda.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'eab1011b-0cf3-4538-8842-292e7ab22291'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eab1011b-0cf3-4538-8842-292e7ab22291-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'eab1011b-0cf3-4538-8842-292e7ab22291' AND type = 'default'
);

-- HD-32: Cyrus Javadi (Democratic) — source: javadi.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e' AND type = 'default'
);

-- HD-33: Shannon Isadore (Democratic) — source: isadore.jpg (sentinel)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '2b9da845-9fab-406f-97c3-1afe895c254b'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2b9da845-9fab-406f-97c3-1afe895c254b-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '2b9da845-9fab-406f-97c3-1afe895c254b' AND type = 'default'
);

-- HD-34: Mari Watanabe (Democratic) — source: watanabe.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'bcc608a3-abf0-4a30-9c4b-0721dcf04be5'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bcc608a3-abf0-4a30-9c4b-0721dcf04be5-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'bcc608a3-abf0-4a30-9c4b-0721dcf04be5' AND type = 'default'
);

-- HD-35: Farrah Chaichi (Democratic) — source: chaichi.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '62decede-7149-40a1-a68a-16e2d3eb62a6'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/62decede-7149-40a1-a68a-16e2d3eb62a6-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '62decede-7149-40a1-a68a-16e2d3eb62a6' AND type = 'default'
);

-- HD-36: Hai Pham (Democratic) — source: phamh.jpg (disambiguated from senate pham.jpg)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '2e668344-f025-489a-b870-1803269c11fc'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2e668344-f025-489a-b870-1803269c11fc-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '2e668344-f025-489a-b870-1803269c11fc' AND type = 'default'
);

-- HD-37: Jules Walters (Democratic) — source: walters.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'b5d3a442-3229-412a-8da4-e8eb8b9fdb3a'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b5d3a442-3229-412a-8da4-e8eb8b9fdb3a-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'b5d3a442-3229-412a-8da4-e8eb8b9fdb3a' AND type = 'default'
);

-- HD-38: Daniel Nguyen (Democratic) — source: nguyend.jpg (scraped; 'd' suffix)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '73519742-09c3-4204-871b-076ff1397a14'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/73519742-09c3-4204-871b-076ff1397a14-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '73519742-09c3-4204-871b-076ff1397a14' AND type = 'default'
);

-- HD-39: April Dobson (Democratic) — source: dobson.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0bffa985-c83b-41c3-8901-19b7dac86cd7'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0bffa985-c83b-41c3-8901-19b7dac86cd7-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '0bffa985-c83b-41c3-8901-19b7dac86cd7' AND type = 'default'
);

-- HD-40: Annessa Hartman (Democratic) — source: hartman.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '14896652-e36b-4823-afb0-e92e3338929c'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/14896652-e36b-4823-afb0-e92e3338929c-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '14896652-e36b-4823-afb0-e92e3338929c' AND type = 'default'
);

-- HD-41: Mark Gamba (Democratic) — source: gamba.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '36db8c55-4b20-408c-bd99-b8488d0ef344'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/36db8c55-4b20-408c-bd99-b8488d0ef344-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '36db8c55-4b20-408c-bd99-b8488d0ef344' AND type = 'default'
);

-- HD-42: Rob Nosse (Democratic) — source: nosse.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'c5c49832-aa2d-477e-b44e-d6059a98d426'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c5c49832-aa2d-477e-b44e-d6059a98d426-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'c5c49832-aa2d-477e-b44e-d6059a98d426' AND type = 'default'
);

-- HD-43: Tawna D. Sanchez (Democratic) — source: sanchez.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '051b4e9a-6966-45b3-9b65-e23ad4672364'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/051b4e9a-6966-45b3-9b65-e23ad4672364-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '051b4e9a-6966-45b3-9b65-e23ad4672364' AND type = 'default'
);

-- HD-44: Travis Nelson (Democratic) — source: nelson.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0f7439ad-5832-42e9-a1c5-75f1720e14d3'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0f7439ad-5832-42e9-a1c5-75f1720e14d3-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '0f7439ad-5832-42e9-a1c5-75f1720e14d3' AND type = 'default'
);

-- HD-45: Thuy Tran (Democratic) — source: tran.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '9ada0539-e66c-444f-b220-86a8138b5277'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9ada0539-e66c-444f-b220-86a8138b5277-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '9ada0539-e66c-444f-b220-86a8138b5277' AND type = 'default'
);

-- HD-46: Willy Chotzen (Democratic) — source: chotzen.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd3371858-924e-4f76-b756-f2d7bb3c9b8d'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d3371858-924e-4f76-b756-f2d7bb3c9b8d-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'd3371858-924e-4f76-b756-f2d7bb3c9b8d' AND type = 'default'
);

-- HD-47: Andrea Valderrama (Democratic) — source: valderrama.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'a5a3918c-3e24-44fa-9573-440436a05b04'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a5a3918c-3e24-44fa-9573-440436a05b04-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'a5a3918c-3e24-44fa-9573-440436a05b04' AND type = 'default'
);

-- HD-48: Lamar Wise (Democratic) — source: wise.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'e0b21a1d-8c55-4aa9-a58a-d6b69db9f716'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e0b21a1d-8c55-4aa9-a58a-d6b69db9f716-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'e0b21a1d-8c55-4aa9-a58a-d6b69db9f716' AND type = 'default'
);

-- HD-49: Zach Hudson (Democratic) — source: hudson.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '37247ac1-5444-4fdd-b58e-123b5db4d0fe'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/37247ac1-5444-4fdd-b58e-123b5db4d0fe-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '37247ac1-5444-4fdd-b58e-123b5db4d0fe' AND type = 'default'
);

-- HD-50: Ricki Ruiz (Democratic) — source: ruiz.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '5e5e267a-808e-4a57-9f80-7c3e47fcb5f6'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5e5e267a-808e-4a57-9f80-7c3e47fcb5f6-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '5e5e267a-808e-4a57-9f80-7c3e47fcb5f6' AND type = 'default'
);

-- HD-51: Matt Bunch (Republican) — source: bunch.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'ce386a55-7cc5-4006-89db-97e06e0e0279'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ce386a55-7cc5-4006-89db-97e06e0e0279-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'ce386a55-7cc5-4006-89db-97e06e0e0279' AND type = 'default'
);

-- HD-52: Jeff Helfrich (Republican) — source: helfrich.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c' AND type = 'default'
);

-- HD-53: Emerson Levy (Democratic) — source: levye.jpg (DISAMBIGUATION: 'e' suffix vs Bobby Levy's levy.jpg)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86' AND type = 'default'
);

-- HD-54: Jason Kropf (Democratic) — source: kropf.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'bbc19752-8675-48ef-87fb-480e3f8bf3f6'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bbc19752-8675-48ef-87fb-480e3f8bf3f6-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'bbc19752-8675-48ef-87fb-480e3f8bf3f6' AND type = 'default'
);

-- HD-55: E. Werner Reschke (Republican) — source: reschke.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '3c7c9b46-a054-41a7-8752-f0d8706f754d'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3c7c9b46-a054-41a7-8752-f0d8706f754d-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '3c7c9b46-a054-41a7-8752-f0d8706f754d' AND type = 'default'
);

-- HD-56: Emily McIntire (Republican) — source: mcintire.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '9f9b60c1-483c-4a8e-8221-145098204ced'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9f9b60c1-483c-4a8e-8221-145098204ced-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '9f9b60c1-483c-4a8e-8221-145098204ced' AND type = 'default'
);

-- HD-57: Gregory Smith (Republican) — source: smithg.jpg (disambiguated from SD-01 smithdb.jpg)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '81cda574-d820-4ac3-b7fe-0ac3d2638c28'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/81cda574-d820-4ac3-b7fe-0ac3d2638c28-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '81cda574-d820-4ac3-b7fe-0ac3d2638c28' AND type = 'default'
);

-- HD-58: Bobby Levy (Republican) — source: levy.jpg (DISAMBIGUATION: plain levy.jpg vs Emerson's levye.jpg)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '05152597-fd40-49bb-bcd3-9e21945ae8b0'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/05152597-fd40-49bb-bcd3-9e21945ae8b0-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '05152597-fd40-49bb-bcd3-9e21945ae8b0' AND type = 'default'
);

-- HD-59: Vikki Breese-Iverson (Republican) — source: breeseiverson.jpg (hyphen dropped)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7f460988-c9a6-4452-a872-441e7c4ac071'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7f460988-c9a6-4452-a872-441e7c4ac071-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = '7f460988-c9a6-4452-a872-441e7c4ac071' AND type = 'default'
);

-- HD-60: Mark Owens (Republican) — source: owens.jpg
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'ca7c06f8-d4cf-4bec-947f-fb39a00e2cb1'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ca7c06f8-d4cf-4bec-947f-fb39a00e2cb1-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = 'ca7c06f8-d4cf-4bec-947f-fb39a00e2cb1' AND type = 'default'
);

COMMIT;
