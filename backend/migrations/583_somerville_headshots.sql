-- Migration 583: Somerville city government + school committee headshots (SOMERVILLE-02)
--
-- Storage bucket: politician_photos
-- CDN base: https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/
--
-- Total officials attempted: 19 (12 city + 7 SC; Mayor Wilson and Davis counted once each under city)
-- Uploaded: 9
-- Gap count: 10
--
-- somervillema.gov accessible (no 403 block) — 9 city officials confirmed 200
-- 3 city gap officials: Jon Link, Ben Wheeler, Emily Hardt (newly elected Nov 2025; no city site photo yet)
-- SC headshots: all 7 members are gaps (no individual headshots on somervillema.gov or somerville.k12.ma.us)
-- Photo processing: crop 4:5 first, then resize 600x750 Lanczos q90
-- type = 'default' (NOT 'headshot') — UI filter uses .find(img => img.type === 'default')
--
-- DOCUMENTED GAPS:
--   City Council:
--     -2562535002 Jon Link (At-Large) — newly elected Nov 2025; no photo on somervillema.gov yet; fallback: jonforsomerville.com
--     -2562535005 Ben Wheeler (At-Large) — newly elected Nov 2025; no photo on somervillema.gov yet; fallback: benwheelerforsomerville.com
--     -2562535012 Emily Hardt (Ward 7) — newly elected Nov 2025; Ward 7 page shows stale Judy Pineda Neufeld; /councilor-emily-hardt-2022.jpg returns 403; fallback: emilyhardtforsomerville.com
--   School Committee:
--     -2510890001 Emily Ackman (Ward 1, Chair) — no individual headshots on SPS site; fallback: emilyackmanforward1 Facebook / Ballotpedia
--     -2510890002 Elizabeth Eldridge (Ward 2) — no individual headshots on SPS site; fallback: Somerville SEPAC sources
--     -2510890003 Michele Lippens (Ward 3) — no individual headshots on SPS site; fallback: local news election coverage
--     -2510890004 Andre L. Green (Ward 4) — no individual headshots on SPS site; fallback: local news election coverage
--     -2510890005 Laura Pitone (Ward 5) — no individual headshots on SPS site; fallback: local news election coverage
--     -2510890006 Emma Stellman (Ward 6) — no individual headshots on SPS site; fallback: local news election coverage
--     -2510890007 Leiran Biton (Ward 7, Vice Chair) — no individual headshots on SPS site; fallback: leiran4somerville Facebook / thesomervilletimes.com
--
-- Upload script: C:/EV-Accounts/backend/scripts/_tmp-somerville-headshots.py
--   Run date: 2026-06-14
--   Result: 9 uploaded, 10 gaps
--
-- CRITICAL: type = 'default' (not 'headshot') — UI filter .find(img => img.type === 'default')
-- CRITICAL: insert into the url column (CDN path)
-- CRITICAL: WHERE NOT EXISTS guard on politician_id makes all blocks idempotent

-- ============================================================
-- CITY COUNCIL (external_ids -2562535001 through -2562535012)
-- 9 uploaded; 3 gaps (Link -2562535002, Wheeler -2562535005, Hardt -2562535012)
-- ============================================================

-- Jake Wilson (Mayor) — external_id -2562535001
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2562535001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/41ced04d-7403-4170-a267-c339191e6fcd-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2562535001)
);

-- GAP: -2562535002 Jon Link (At-Large) — newly elected Nov 2025; no photo on somervillema.gov; fallback: jonforsomerville.com

-- Wilfred N. Mbah (At-Large) — external_id -2562535003
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2562535003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9b11117c-d064-404b-8c89-0042f417c576-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2562535003)
);

-- Kristen E. Strezo (At-Large) — external_id -2562535004
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2562535004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1e5429d3-c4b2-4a1f-913f-483833565e93-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2562535004)
);

-- GAP: -2562535005 Ben Wheeler (At-Large) — newly elected Nov 2025; no photo on somervillema.gov; fallback: benwheelerforsomerville.com

-- Matthew McLaughlin (Ward 1) — external_id -2562535006
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2562535006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5b2a514f-ea4b-4476-bf45-0d221a138d3a-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2562535006)
);

-- Jefferson Thomas Scott (Ward 2) — external_id -2562535007
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2562535007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a79ac715-57a6-4a18-82a0-0b8a5ed60464-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2562535007)
);

-- Ben Ewen-Campen (Ward 3) — external_id -2562535008
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2562535008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/073a3e12-55bb-4c88-9bd9-3333b93f40cd-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2562535008)
);

-- Jesse Clingan (Ward 4) — external_id -2562535009
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2562535009),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/13f3e9dc-67fc-4115-99a5-77c4647f1b3c-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2562535009)
);

-- Naima Sait (Ward 5) — external_id -2562535010
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2562535010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cb506153-5bd5-4b43-b982-58d07c9611e4-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2562535010)
);

-- Lance L. Davis (Ward 6, Council President) — external_id -2562535011
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2562535011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3c43a3fa-9c89-4278-8d36-f5e4e5000d64-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2562535011)
);

-- GAP: -2562535012 Emily Hardt (Ward 7) — newly elected Nov 2025; Ward 7 page shows stale Judy Pineda Neufeld; /councilor-emily-hardt-2022.jpg returns 403; fallback: emilyhardtforsomerville.com

-- ============================================================
-- SCHOOL COMMITTEE (external_ids -2510890001 through -2510890007)
-- All 7 members are gaps — no individual headshots on somervillema.gov or somerville.k12.ma.us
-- ============================================================

-- GAP: -2510890001 Emily Ackman (Ward 1, Chair) — no individual headshots on SPS site; fallback: emilyackmanforward1 Facebook / Ballotpedia
-- GAP: -2510890002 Elizabeth Eldridge (Ward 2) — no individual headshots on SPS site; fallback: Somerville SEPAC sources
-- GAP: -2510890003 Michele Lippens (Ward 3) — no individual headshots on SPS site; fallback: local news election coverage
-- GAP: -2510890004 Andre L. Green (Ward 4) — no individual headshots on SPS site; fallback: local news election coverage
-- GAP: -2510890005 Laura Pitone (Ward 5) — no individual headshots on SPS site; fallback: local news election coverage
-- GAP: -2510890006 Emma Stellman (Ward 6) — no individual headshots on SPS site; fallback: local news election coverage
-- GAP: -2510890007 Leiran Biton (Ward 7, Vice Chair) — no individual headshots on SPS site; fallback: leiran4somerville Facebook / thesomervilletimes.com

-- ============================================================
-- POST-VERIFICATION: Confirm correct type and count for Somerville headshots
-- ============================================================

DO $$
DECLARE
  v_img_count INTEGER;
  v_wrong_type INTEGER;
BEGIN
  -- Count type='default' rows in Somerville external_id ranges
  SELECT COUNT(*) INTO v_img_count
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE (p.external_id BETWEEN -2562535012 AND -2562535001
      OR p.external_id BETWEEN -2510890007 AND -2510890001)
    AND pi.type = 'default';

  -- Confirm no wrong-type rows exist for Somerville officials
  SELECT COUNT(*) INTO v_wrong_type
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE (p.external_id BETWEEN -2562535012 AND -2562535001
      OR p.external_id BETWEEN -2510890007 AND -2510890001)
    AND pi.type != 'default';

  IF v_wrong_type > 0 THEN
    RAISE EXCEPTION 'Migration 583 post-verification FAILED: Somerville headshots have wrong type (not default): % rows', v_wrong_type;
  END IF;

  RAISE NOTICE 'Migration 583 post-verification PASSED: % headshots inserted (type=default), 10 gap officials documented (3 city newly-elected Nov 2025 + 7 SC no online source)', v_img_count;
END $$;

-- ============================================================
-- MIGRATION LEDGER
-- ============================================================

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('583')
ON CONFLICT (version) DO NOTHING;
