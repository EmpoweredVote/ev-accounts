-- Migration 356: MA Tier 2 headshots (MA-TIER2-01, MA-TIER2-02)
--
-- Storage bucket: politician_photos
-- CDN base: https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/
--
-- Counts: best-effort across 59 officials (11 Worcester + 14 Springfield + 12 Lowell + 12 Brockton + 10 Quincy)
--         Uploaded: 47/59 (Worcester 11/11 + Springfield 14/14 + Lowell 11/12 + Brockton 11/12 + Quincy 0/10)
--         Gaps: 12 documented below
--
-- Photo processing: crop to 4:5 ratio FIRST, then resize 600x750 Lanczos q90.
-- politician_images.type = 'default' (UI filter: .find(img => img.type === 'default')).
-- politician_images uses the 'url' column for the CDN path.
-- No BEGIN/COMMIT — each INSERT is autocommit (matching migration 349 pattern).
-- photo_license = 'public_domain' for official city website photos.
--
-- Sources:
--   Worcester: worcesterma.gov/media/council/{lastname}-headshot.jpg (verified)
--   Springfield: springfield-ma.gov/cos/fileadmin/_processed_/ (TYPO3 CMS, verified)
--   Lowell: lowellma.gov CivicPlus ImageRepository doc IDs (verified)
--   Brockton: brockton.ma.us WordPress wp-content uploads (verified)
--   Quincy: NO photos on quincyma.gov — all 10 are documented GAPs
--
-- Upload script: C:/EV-Accounts/backend/scripts/_tmp-ma-tier2-headshots.py
--   Run date: 2026-06-10
--
-- DOCUMENTED GAPS (12 officials, best-effort — not blocking):
--   -253700001 Thomas A. Golden, Jr. (Lowell) — no photo on lowellma.gov City Manager page
--   -250900007 John Lally (Brockton) — HTTP 403 from brockton.ma.us (photo not publicly accessible)
--   -255574501 Thomas P. Koch (Quincy) — quincyma.gov text-only, no headshot photos posted
--   -255574502 David Jacobs (Quincy) — quincyma.gov text-only
--   -255574503 Richard Ash (Quincy) — quincyma.gov text-only
--   -255574504 Walter Hubley (Quincy) — quincyma.gov text-only
--   -255574505 Virginia Ryan (Quincy) — quincyma.gov text-only
--   -255574506 Maggie McKee (Quincy) — quincyma.gov text-only
--   -255574507 Deborah Riley (Quincy) — quincyma.gov text-only
--   -255574508 Noel DiBona (Quincy) — quincyma.gov text-only
--   -255574509 Anne Mahoney (Quincy) — quincyma.gov text-only
--   -255574510 Ziqiang Yuan (Quincy) — quincyma.gov text-only (new Jan 2026 council)
--
-- CRITICAL: type = 'default' (not 'headshot') — UI filter .find(img => img.type === 'default')
-- CRITICAL: insert into the url column (CDN path)
-- CRITICAL: WHERE NOT EXISTS guard on politician_id makes all blocks idempotent

-- ============================================================
-- WORCESTER — 11 officials (all uploaded)
-- external_id range: -258200001..-258200011
-- ============================================================

-- Joseph M. Petty (Mayor) — external_id -258200001
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -258200001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a25f862d-26f5-41f0-a32b-c4d59c7769c8-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -258200001)
);

-- Khrystian E. King (Councillor At-Large) — external_id -258200002
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -258200002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/802f48ea-e397-4e72-9589-23aa5cee5a39-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -258200002)
);

-- Satya B. Mitra (Councillor At-Large) — external_id -258200003
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -258200003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/22310534-2476-4338-986c-e0e349af29d1-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -258200003)
);

-- Kathleen M. Toomey (Councillor At-Large) — external_id -258200004
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -258200004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/319d1e77-b214-4485-ab8b-b0ebd2703f22-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -258200004)
);

-- Morris A. Bergman (Councillor At-Large) — external_id -258200005
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -258200005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/022ec1b6-59e5-4227-95fc-45f2b7102a15-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -258200005)
);

-- Gary Rosen (Councillor At-Large) — external_id -258200006
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -258200006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/23052e57-ce98-439a-a6fe-c538f26ec959-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -258200006)
);

-- Tony Economou (District 1) — external_id -258200007
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -258200007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2a77e3dc-24e2-40c9-a6fa-d134d59ede82-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -258200007)
);

-- Robert A. Bilotta (District 2) — external_id -258200008
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -258200008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9e10d315-a792-4d22-9bcb-cd16247e2fa4-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -258200008)
);

-- John P. Fresolo (District 3) — external_id -258200009
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -258200009),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bef00532-3286-456f-9668-ef5efe285270-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -258200009)
);

-- Luis A. Ojeda (District 4) — external_id -258200010
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -258200010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8b47525c-5efe-45ec-ba37-c6e15f038b65-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -258200010)
);

-- Jose A. Rivera (District 5) — external_id -258200011
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -258200011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d18a85ec-abec-4a77-8d13-5b43059b6698-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -258200011)
);

-- ============================================================
-- SPRINGFIELD — 14 officials (all uploaded)
-- external_id range: -256700001..-256700014
-- ============================================================

-- Domenic J. Sarno (Mayor) — external_id -256700001
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -256700001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d8449201-38b4-4851-b8a7-40b1bcf40161-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -256700001)
);

-- Michael A. Fenton (Ward 2, Council President) — external_id -256700002
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -256700002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fc17d6ea-c967-4d0d-a636-41b1d136765f-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -256700002)
);

-- Melvin A. Edwards (At-Large) — external_id -256700003
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -256700003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7d024231-0fa3-4787-8cc0-92fa6903711c-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -256700003)
);

-- Maria Perez (At-Large) — external_id -256700004
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -256700004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f9dfe8ab-8b7e-427f-933f-be4ecbb1168d-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -256700004)
);

-- Malo L. Brown (At-Large) — external_id -256700005
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -256700005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3da0fc8c-35d5-4c14-a53b-89f7c6a7bdd2-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -256700005)
);

-- Lavar Click-Bruce (At-Large) — external_id -256700006
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -256700006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b0df471c-db3a-4f10-8817-f14c7e611593-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -256700006)
);

-- Victor G. Davila (At-Large) — external_id -256700007
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -256700007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f55836a5-4525-4142-9773-1bc08b21cc63-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -256700007)
);

-- Gerry Martin (Ward 1) — external_id -256700008
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -256700008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/de39ab94-3663-4b2e-be14-222e79a87638-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -256700008)
);

-- Zaida Govan (Ward 3) — external_id -256700009
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -256700009),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1b987aa5-fba6-4ce5-a926-8cb957b43410-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -256700009)
);

-- Justin Hurst (Ward 4) — external_id -256700010
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -256700010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/91e24565-79b3-4473-9d7b-3ca72beceed2-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -256700010)
);

-- Jose Delgado (Ward 5) — external_id -256700011
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -256700011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a265eb66-0b1e-45e5-9d55-f5565e0540f8-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -256700011)
);

-- Kateri Walsh (Ward 6) — external_id -256700012
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -256700012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6db2abd4-86ce-414a-ba80-6565e6e3b23d-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -256700012)
);

-- Tracye Whitfield (Ward 7) — external_id -256700013
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -256700013),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8f7f44a0-2580-4e32-97a1-e8341c6b155f-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -256700013)
);

-- Brian Santaniello (Ward 8) — external_id -256700014
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -256700014),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d19a9e26-2ba1-4ea0-8bfe-ab69447ed769-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -256700014)
);

-- ============================================================
-- LOWELL — 11 of 12 uploaded (Golden = GAP)
-- external_id range: -253700001..-253700012
-- ============================================================

-- GAP: Thomas A. Golden, Jr. (City Manager) — external_id -253700001
-- No photo on lowellma.gov/198/City-Manager page (text-only content)

-- Erik R. Gitschier (Mayor, council-elected) — external_id -253700002
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -253700002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c2eac407-10ce-4f4e-8796-1acb3feb42ac-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -253700002)
);

-- Rita Mercier (At-Large) — external_id -253700003
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -253700003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ef52f3fd-dc4d-4a4a-8320-fbae613a4baa-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -253700003)
);

-- Vesna Nuon (At-Large) — external_id -253700004
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -253700004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/31f0c2f8-bf7c-4162-a429-0176494ef6a6-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -253700004)
);

-- Daniel Rourke (District 1) — external_id -253700005
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -253700005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a94eb034-80bf-414f-af20-4148c74f0d46-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -253700005)
);

-- Corey Robinson (District 2) — external_id -253700006
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -253700006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/246e6b71-e8ad-44bb-aa5c-10228d2c056a-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -253700006)
);

-- Belinda M. Juran (District 3) — external_id -253700007
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -253700007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/65ad46fc-841a-44c2-bd50-11bf92c00cb9-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -253700007)
);

-- Sean McDonough (District 4) — external_id -253700008
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -253700008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d39c02eb-11c7-478b-b098-e9b1c858142d-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -253700008)
);

-- Kimberly Scott (District 5) — external_id -253700009
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -253700009),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/235db44a-7d67-455d-93d9-ab0c58eb0170-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -253700009)
);

-- Sokhary Chau (District 6) — external_id -253700010
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -253700010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a9576877-4145-4d02-a91c-c3e351d26187-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -253700010)
);

-- Sidney L. Liang (District 7) — external_id -253700011
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -253700011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fef9fd15-a5de-4e04-b402-ead530301f29-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -253700011)
);

-- John Descoteaux (District 8) — external_id -253700012
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -253700012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b7015fbc-6173-48bc-99ba-d0363b771048-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -253700012)
);

-- ============================================================
-- BROCKTON — 11 of 12 uploaded (Lally = GAP)
-- external_id range: -250900001..-250900012
-- ============================================================

-- Moises M. Rodrigues (Mayor) — external_id -250900001
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -250900001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/13673e69-91df-4d5b-a6af-36cc577f2487-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -250900001)
);

-- Marlon D. Green (At-Large) — external_id -250900002
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -250900002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d7e6d328-d2d1-4482-9d0a-e4ad18ce1a7e-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -250900002)
);

-- Maria T. Tavares (At-Large) — external_id -250900003
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -250900003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6b58e9c7-dc9e-4e63-93d3-c63f358e58a1-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -250900003)
);

-- Philip E. Griffin (At-Large) — external_id -250900004
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -250900004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fb09afc5-bbc2-4321-8bb4-5829ca55347f-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -250900004)
);

-- Susan Nicastro (At-Large) — external_id -250900005
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -250900005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c504b068-cf7f-4feb-94cf-5dac02c77a87-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -250900005)
);

-- Jeffrey A. Thompson (Ward 1) — external_id -250900006
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -250900006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2ac58cbd-f5ac-4c45-93da-dec32b26f437-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -250900006)
);

-- GAP: John Lally (Ward 2) — external_id -250900007
-- HTTP 403 from brockton.ma.us/wp-content/uploads/2018/07/Jack-Lally-200x200-1.png

-- Shirley Asack (Ward 3) — external_id -250900008
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -250900008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1b2851c7-a1cf-44ce-9453-a658332eeafc-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -250900008)
);

-- Carla Darosa (Ward 4) — external_id -250900009
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -250900009),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/47c58f36-a2a2-4966-84e5-1ebd57e7684c-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -250900009)
);

-- Jeff Charnel (Ward 5) — external_id -250900010
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -250900010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9fbef309-1daf-4ddf-a7f2-0432bfffa6c1-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -250900010)
);

-- Winthrop Farwell Jr. (Ward 6) — external_id -250900011
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -250900011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/47db15ed-9023-4363-a694-18b043830b0b-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -250900011)
);

-- David C. Teixeira (Ward 7) — external_id -250900012
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -250900012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/81fb773b-1510-48f7-b1db-527eb0aedd5a-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -250900012)
);

-- ============================================================
-- QUINCY — 0 of 10 uploaded (all 10 are documented GAPs)
-- external_id range: -255574501..-255574510
-- quincyma.gov does not post headshot photos for any council members
-- New Jan 2026 council (7 new members) has no official photos posted
-- ============================================================

-- GAP: Thomas P. Koch (Mayor) — external_id -255574501 — no photo on quincyma.gov
-- GAP: David Jacobs (Ward 1) — external_id -255574502 — no photo on quincyma.gov
-- GAP: Richard Ash (Ward 2) — external_id -255574503 — no photo on quincyma.gov
-- GAP: Walter Hubley (Ward 3) — external_id -255574504 — no photo on quincyma.gov
-- GAP: Virginia Ryan (Ward 4) — external_id -255574505 — no photo on quincyma.gov
-- GAP: Maggie McKee (Ward 5) — external_id -255574506 — no photo on quincyma.gov
-- GAP: Deborah Riley (Ward 6) — external_id -255574507 — no photo on quincyma.gov
-- GAP: Noel DiBona (At-Large) — external_id -255574508 — no photo on quincyma.gov
-- GAP: Anne Mahoney (At-Large) — external_id -255574509 — no photo on quincyma.gov
-- GAP: Ziqiang Yuan (At-Large) — external_id -255574510 — no photo on quincyma.gov

-- ============================================================
-- POST-VERIFICATION: Count check (best-effort — no hard gate)
-- ============================================================

DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE p.external_id BETWEEN -258200011 AND -258200001
     OR p.external_id BETWEEN -256700014 AND -256700001
     OR p.external_id BETWEEN -253700012 AND -253700001
     OR p.external_id BETWEEN -250900012 AND -250900001
     OR p.external_id BETWEEN -255574510 AND -255574501;
  RAISE NOTICE 'Migration 356: % politician_images rows for MA Tier 2 officials (47 expected — best-effort)', v_count;
END $$;

-- ============================================================
-- MIGRATION LEDGER
-- ============================================================

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('356')
ON CONFLICT (version) DO NOTHING;
