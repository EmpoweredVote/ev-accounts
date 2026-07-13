-- 1330_palm_springs_headshots.sql
-- Phase 202 Plan 03 (CV-02): AUDIT-ONLY -- politician_images rows for all 5
-- sitting City of Palm Springs (California) City Council members. NOT registered
-- in the migration ledger; the ledger table stays unchanged (audit-only, no
-- ledger footer). Applied via `psql -f` (NOT apply_migration) AFTER the script
-- (_tmp-palmsprings-headshots.py) uploads all 5 processed images to Storage.
--
-- Sources (per-member, campaign/press portraits -- palmspringsca.gov is Akamai
-- WAF-403 to bots and was avoided). All processed 4:5 crop-first -> 600x750
-- Lanczos q90; deHarte's transparent PNG was white-composited before crop.
-- All 5 are publicly-distributed campaign/press promotional portraits (none .gov,
-- none Wikimedia) -> photo_license='press_use' on every row.
--   -4011001 Grace Elena Garner  -- wewinwithgrace.com campaign portrait (press_use)
--   -4011002 Jeffrey Bernstein    -- jeffreyforps.com campaign portrait (press_use)
--   -4011003 Ron deHarte          -- rondeharte.com campaign portrait (press_use)
--   -4011004 Naomi Soto (Mayor)   -- naomisoto.com campaign portrait (press_use)
--   -4011005 David H. Ready (MPT) -- KESQ candidate photo (press_use)
--
-- Columns: exactly (id, politician_id, url, type, photo_license). type='default'
-- (the UI filters on it). politician UUIDs below are from 202-02-SUMMARY.md's
-- manifest (they appear only in the CDN Storage path); politician_id is resolved
-- by external_id at apply time. WHERE NOT EXISTS on politician_id for idempotency.

-- ============================================================
-- City Council (5 rows)
-- ============================================================

-- Grace Elena Garner (District 1, external_id=-4011001)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4011001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/13979c8e-df26-4d07-918e-e064fce6dc53-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4011001)
);

-- Jeffrey Bernstein (District 2, external_id=-4011002)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4011002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/befbbea4-9e33-4f37-9745-c7184e824d48-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4011002)
);

-- Ron deHarte (District 3, external_id=-4011003)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4011003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/24ba9d44-a972-4125-b370-380b457a226c-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4011003)
);

-- Naomi Soto (District 4, Mayor, external_id=-4011004)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4011004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d76aaa6c-b6a1-42f4-8b12-67cd523c4cf7-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4011004)
);

-- David H. Ready (District 5, Mayor Pro Tem, external_id=-4011005)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4011005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/59c2f45b-5369-4db0-936b-df94a57527c9-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4011005)
);
