-- Migration 1094: North Las Vegas City Council headshots (politician_images)
-- Phase 164 Plan 02 — CLARK-04 (headshot portion).
--
-- AUDIT-ONLY: NOT registered in the migration ledger; the structural ledger stays
-- at 1093. There is no ledger-registration INSERT in this file.
--
-- Columns are exactly (id, politician_id, url, type, photo_license). The removed
-- image-origin column is intentionally absent. type='default' on all rows.
-- politician_id resolved by stable external_id (minted by mig 1093). Idempotent
-- via NOT EXISTS. photo_license per member from the headshot manifest.
--
-- Sources (all clean head-and-shoulders portraits, no overlay, verified at execution;
-- cityofnorthlasvegas.com skipped — Akamai WAF-403):
--   Goynes-Brown    — Wikimedia Commons (Sen. Rosen office photo)   (public_domain)
--   Barrón          — Ballotpedia infobox portrait                  (press_use)
--   Garcia-Anderson — Ballotpedia infobox portrait                  (press_use)
--   Black           — Ballotpedia official headshot                 (press_use)
--   Cherchio        — Ballotpedia infobox portrait                  (press_use)
-- 5/5 sourced; 0 gaps.

BEGIN;

-- -3207001 Pamela Goynes-Brown (Mayor)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3207001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bc59a9f6-e308-4c1c-af96-0aebb8ac72c6-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3207001)
);

-- -3207002 Isaac E. Barrón (Ward 1)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3207002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/59c8b352-1ffb-44fc-89c2-68627ade8a8c-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3207002)
);

-- -3207003 Ruth Garcia-Anderson (Ward 2)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3207003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cefd942b-7c4f-4d7b-9726-95d8c5a42c9f-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3207003)
);

-- -3207004 Scott Black (Ward 3)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3207004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/80a3329f-c338-4991-afb3-b1670996ef7b-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3207004)
);

-- -3207005 Richard Cherchio (Ward 4)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3207005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/806dbfb2-3e81-4d76-bd04-085bc523b76a-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3207005)
);

COMMIT;
-- AUDIT-ONLY: no schema_migrations INSERT (structural ledger stays at 1093).
