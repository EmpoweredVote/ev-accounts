-- Migration 1085: Henderson City Council headshots (politician_images)
-- Phase 163 Plan 02 — CLARK-03 (headshot portion).
--
-- AUDIT-ONLY: NOT registered in the migration ledger; the structural ledger stays
-- at 1084. There is no ledger-registration INSERT in this file.
--
-- Columns are exactly (id, politician_id, url, type, photo_license). The removed
-- image-origin column is intentionally absent. type='default' on all rows.
-- politician_id resolved by stable external_id (minted by mig 1084). Idempotent
-- via NOT EXISTS. photo_license per member from the headshot manifest.
--
-- Sources (all clean head-and-shoulders portraits, no overlay, verified at execution;
-- cityofhenderson.com skipped — Akamai WAF-403):
--   Romero  — Nevada Business Magazine editorial portrait        (press_use)
--   Seebock — votejimseebock.com campaign portrait               (press_use)
--   Larson  — Ballotpedia clean headshot                         (press_use)
--   Cox     — Ballotpedia clean headshot                         (press_use)
--   Stewart — Ballotpedia clean headshot                         (press_use)
-- 5/5 sourced; 0 gaps.

BEGIN;

-- -3206001 Michelle Romero (Mayor)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3206001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/494202b1-2cf0-4780-b164-7ae84a1c5185-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3206001)
);

-- -3206002 Jim Seebock (Ward I)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3206002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/99d43f01-4b07-471f-bacf-e89d2a1c36b2-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3206002)
);

-- -3206003 Monica Larson (Ward II)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3206003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e0d8ef1b-26b6-4e3d-add7-0ff35bc9a486-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3206003)
);

-- -3206004 Carrie Cox (Ward III)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3206004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/64f92bb3-0d32-44bf-bbb6-2191060a93f7-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3206004)
);

-- -3206005 Dan H. Stewart (Ward IV)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3206005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/50682ef1-360a-4597-9e1a-eaf43c50673d-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3206005)
);

COMMIT;
-- AUDIT-ONLY: no schema_migrations INSERT (structural ledger stays at 1084).
