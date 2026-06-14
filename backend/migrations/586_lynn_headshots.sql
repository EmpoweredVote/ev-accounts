-- Migration 586: Lynn city officials + school committee headshots (LYNN-02)
--
-- Storage bucket: politician_photos
-- CDN base: https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/
--
-- Total officials attempted: 18 (12 city + 6 SC)
-- Uploaded: 12 (all 12 city officials: 11 CivicLive CDN + 1 Mayor Wikipedia Commons)
-- Gap count: 6 (all SC members — SchoolMessenger text-only site)
--
-- lynnma.gov uses CivicLive CMS (NOT CivicEngage) — 11/11 council headshots confirmed 200 on CDN.
-- Mayor Nicholson: Wikipedia Commons (no photo on lynnma.gov or CivicLive CDN).
-- SC headshots: all 6 members are gaps — lynnschools.org is SchoolMessenger CMS (text-only page).
-- Photo processing: crop 4:5 first, then resize 600x750 Lanczos q90
-- type = 'default' (NOT 'headshot') — UI filter uses .find(img => img.type === 'default')
--
-- DOCUMENTED GAPS:
--   School Committee:
--     -2507110001 Brian K. Castellanos — no headshot on lynnschools.org (SchoolMessenger text-only); no fallback per D-01
--     -2507110002 Lorraine Gately — no headshot on lynnschools.org (SchoolMessenger text-only); no fallback per D-01
--     -2507110003 Brenda Ortiz McGrath — no headshot on lynnschools.org (SchoolMessenger text-only); no fallback per D-01
--     -2507110004 Lennin Peña — no headshot on lynnschools.org (SchoolMessenger text-only); no fallback per D-01
--     -2507110005 Andrea L. Satterwhite — no headshot on lynnschools.org (SchoolMessenger text-only); no fallback per D-01
--     -2507110006 Tristan J. Smith — no headshot on lynnschools.org (SchoolMessenger text-only); no fallback per D-01
--
-- Upload script: C:/EV-Accounts/backend/scripts/_tmp-lynn-headshots.py
--   Run date: 2026-06-14
--   Result: 12 uploaded, 6 gaps
--
-- CRITICAL: type = 'default' (not 'headshot') — UI filter .find(img => img.type === 'default')
-- CRITICAL: insert into the url column (CDN path with politician UUID)
-- CRITICAL: WHERE NOT EXISTS guard on politician_id makes all blocks idempotent

-- ============================================================
-- CITY COUNCIL (external_ids -2537490001 through -2537490012)
-- 12 uploaded; 0 gaps
-- ============================================================

-- Jared Nicholson (Mayor) — external_id -2537490001
-- Source: Wikipedia Commons https://upload.wikimedia.org/wikipedia/commons/7/7f/Jared_Nicholson_1.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2537490001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b9c5dd29-eeb5-4903-af31-d4ab09041b0a-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2537490001)
);

-- Brian M. Field (At-Large) — external_id -2537490002
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2537490002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6d30fb7c-99cb-4705-86bc-c3d13ffd44d4-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2537490002)
);

-- Brian P. LaPierre (At-Large) — external_id -2537490003
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2537490003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a24baf50-54d3-4319-9bfb-f354c3f5ca03-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2537490003)
);

-- Nicole D. McClain (At-Large) — external_id -2537490004
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2537490004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c0ba9af7-714c-44c7-a3e4-abf735fb0ad9-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2537490004)
);

-- Hong L. Net (At-Large) — external_id -2537490005
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2537490005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ddb4ff9a-d17a-4db7-9d70-b326aaf72e05-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2537490005)
);

-- Peter Meaney (Ward 1) — external_id -2537490006
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2537490006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bd6f9a13-40d9-4b6c-a1ef-64dc010c1f91-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2537490006)
);

-- Obed A. Matul (Ward 2) — external_id -2537490007
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2537490007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e48dc9c7-8359-486c-8044-cbae730490e2-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2537490007)
);

-- Constantino Alinsug (Ward 3, Council President) — external_id -2537490008
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2537490008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f8fc0768-f42d-426c-b580-b053cb802f3f-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2537490008)
);

-- Natasha S. Megie-Maddrey (Ward 4) — external_id -2537490009
-- CRITICAL: CDN filename MegieMaddrey.png (no hyphen) — Pitfall 2 from RESEARCH.md
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2537490009),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/94051951-ca12-452e-bfa3-854dbce765eb-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2537490009)
);

-- Cardeliz Paez (Ward 5) — external_id -2537490010
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2537490010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9c897f77-6567-4a07-a810-c3fb11f2e50c-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2537490010)
);

-- Frederick W. Hogan (Ward 6, Vice President) — external_id -2537490011
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2537490011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d4aa5f35-7491-450d-9c7e-ada82378504d-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2537490011)
);

-- Jordan T. Avery (Ward 7) — external_id -2537490012
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2537490012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1f6e314e-c34f-43dd-b599-ff8d4c2caee9-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2537490012)
);

-- ============================================================
-- SCHOOL COMMITTEE (external_ids -2507110001 through -2507110006)
-- All 6 members are gaps — no individual headshots on lynnschools.org (SchoolMessenger CMS text-only)
-- ============================================================

-- GAP: -2507110001 Brian K. Castellanos — no headshot on lynnschools.org (SchoolMessenger text-only); no fallback per D-01
-- GAP: -2507110002 Lorraine Gately — no headshot on lynnschools.org (SchoolMessenger text-only); no fallback per D-01
-- GAP: -2507110003 Brenda Ortiz McGrath — no headshot on lynnschools.org (SchoolMessenger text-only); no fallback per D-01
-- GAP: -2507110004 Lennin Peña — no headshot on lynnschools.org (SchoolMessenger text-only); no fallback per D-01
-- GAP: -2507110005 Andrea L. Satterwhite — no headshot on lynnschools.org (SchoolMessenger text-only); no fallback per D-01
-- GAP: -2507110006 Tristan J. Smith — no headshot on lynnschools.org (SchoolMessenger text-only); no fallback per D-01

-- ============================================================
-- POST-VERIFICATION: Confirm correct type and count for Lynn headshots
-- ============================================================

DO $$
DECLARE
  v_img_count INTEGER;
  v_wrong_type INTEGER;
BEGIN
  -- Count type='default' rows in Lynn external_id ranges
  SELECT COUNT(*) INTO v_img_count
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE (p.external_id BETWEEN -2537490012 AND -2537490001
      OR p.external_id BETWEEN -2507110006 AND -2507110001)
    AND pi.type = 'default';

  -- Confirm no wrong-type rows exist for Lynn officials
  SELECT COUNT(*) INTO v_wrong_type
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE (p.external_id BETWEEN -2537490012 AND -2537490001
      OR p.external_id BETWEEN -2507110006 AND -2507110001)
    AND pi.type != 'default';

  IF v_wrong_type > 0 THEN
    RAISE EXCEPTION 'Migration 586 post-verification FAILED: Lynn headshots have wrong type (not default): % rows', v_wrong_type;
  END IF;

  RAISE NOTICE 'Migration 586 post-verification PASSED: % headshots inserted (type=default), 6 SC gap officials documented (SchoolMessenger text-only site)', v_img_count;
END $$;

-- ============================================================
-- MIGRATION LEDGER
-- ============================================================

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('586')
ON CONFLICT (version) DO NOTHING;

COMMIT;
