-- Migration 349: Boston headshots (MA-DEEP-02)
--
-- Storage bucket: politician_photos
-- CDN base: https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/
--
-- Counts: 1 Mayor + 13 City Councillors = 14 council rows (all mandatory, all uploaded)
--         0 School Committee rows (all 7 are documented GAPs — see below)
--
-- Photo processing: crop to 4:5 ratio FIRST, then resize 600x750 Lanczos q90 (D-22).
-- politician_images.type = 'default' (UI filter: .find(img => img.type === 'default')) (D-17).
-- politician_images.url column (NOT storage_url).
-- No BEGIN/COMMIT — each INSERT is autocommit (matching migration 315 pattern).
-- photo_license = 'public_domain' for all boston.gov official photos.
--
-- Sources:
--   Mayor Wu + 13 City Councillors: boston.gov/departments/city-council (D-21)
--   School Committee: bostonpublicschools.org / boston.gov press releases (D-21, D-23)
--
-- Upload script: C:/EV-Accounts/backend/scripts/_boston-headshots-upload.py
--   Run date: 2026-06-10
--
-- Council headshot URL patterns:
--   Mayor Wu: boston.gov/sites/default/files/img/library/photos/2021/11/wu-headshot-portrait.jpg
--   Councillors (2026): boston.gov/sites/default/files/styles/person_photo_profile_large_360x360_/public/img/library/photos/2026/02/{name}-headshot.{ext}
--   Flynn (2018): boston.gov/sites/default/files/styles/person_photo_profile_large_360x360_/public/img/person_profile/photos/2018/01/flynn-headshot.jpg
--   Louijeune + Coletta Zapata: patterns-stg.boston.gov returned 403; corrected to www.boston.gov (Rule 1 auto-fix)
--
-- SCHOOL COMMITTEE DOCUMENTED GAPS (D-23 — acceptable, not blocking):
--   All 7 SC members have no available photo URL at time of execution (2026-06-10).
--   BPS member profile pages are JavaScript-rendered; Boston.gov appointment press release
--   photos at the expected paths returned HTTP 404 (photos not published at those paths).
--   Gaps: Jeri Robinson (-2502790001), Rachel Skerritt (-2502790002),
--          Dr. Stephen Alkins (-2502790003), Rafaela Polanco Garcia (-2502790004),
--          Franklin Peralta (-2502790005), Lydia Torres (-2502790006),
--          Quoc Tran (-2502790007).
--   These SC members intentionally omitted from INSERT blocks below.
--   Future: Re-run _boston-headshots-upload.py when SC photos become available.
--
-- CRITICAL: type = 'default' (D-17; not the headshot type) — UI filter .find(img => img.type === 'default')
-- CRITICAL: url column (NOT storage_url)
-- CRITICAL: WHERE NOT EXISTS guard on politician_id makes all blocks idempotent

-- ============================================================
-- BOSTON CITY COUNCIL — 14 officials (Mayor + 4 at-large + 9 district)
-- external_id range: -2507000001..-2507000014
-- ============================================================

-- Michelle Wu (Mayor) — external_id -2507000001
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2507000001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d63def16-7510-4745-83d8-01901e450429-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2507000001)
);

-- Ruthzee Louijeune (At-Large) — external_id -2507000002
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2507000002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1e3a621a-2424-469e-8c1a-7a0dd635d3a2-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2507000002)
);

-- Julia M. Mejia (At-Large) — external_id -2507000003
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2507000003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cd9d9fd5-c20f-4b57-9065-f52516adca84-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2507000003)
);

-- Erin J. Murphy (At-Large) — external_id -2507000004
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2507000004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c9419f85-8e38-4b64-a816-7b3caba5c674-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2507000004)
);

-- Henry Santana (At-Large) — external_id -2507000005
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2507000005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3bd4af01-0ce8-415f-87fa-09dc248ca6cc-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2507000005)
);

-- Gabriela Coletta Zapata (District 1) — external_id -2507000006
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2507000006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c3007368-5c5d-4933-8bb3-048d9df6a411-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2507000006)
);

-- Edward M. Flynn (District 2) — external_id -2507000007
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2507000007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b8c7510c-20d7-4bd7-a765-07b77d3a5b6c-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2507000007)
);

-- John FitzGerald (District 3) — external_id -2507000008
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2507000008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3b546ec5-a7fe-4f64-9537-a19c58809631-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2507000008)
);

-- Brian Worrell (District 4) — external_id -2507000009
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2507000009),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9f94a985-cb9d-497b-bd36-fffa48931ab2-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2507000009)
);

-- Enrique J. Pepén (District 5) — external_id -2507000010
-- Name preserved with accent per project conventions (Pitfall 6 / project_unicode_search_normalization.md)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2507000010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ce971c69-7b28-49f2-b530-783291a08863-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2507000010)
);

-- Benjamin J. Weber (District 6) — external_id -2507000011
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2507000011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/703f9005-8767-4c2b-97c1-155b3fc36fee-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2507000011)
);

-- Miniard Culpepper (District 7) — external_id -2507000012
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2507000012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/10a52f8b-bd19-4076-9a8f-46ae2e8552ce-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2507000012)
);

-- Sharon Durkan (District 8) — external_id -2507000013
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2507000013),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/161c754c-2161-49aa-9722-f0e5dbc07cef-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2507000013)
);

-- Liz Breadon (District 9, Council President) — external_id -2507000014
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2507000014),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6e63a642-91f7-4c2b-949d-b3a936e6343e-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2507000014)
);

-- ============================================================
-- SCHOOL COMMITTEE — 0 rows inserted (all 7 members are documented GAPs per D-23)
-- GAPs listed in header comment above.
-- No INSERT blocks for external_ids -2502790001 through -2502790007.
-- ============================================================

-- ============================================================
-- POST-VERIFICATION: Count check
-- ============================================================

DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE p.external_id BETWEEN -2507000014 AND -2507000001
     OR p.external_id BETWEEN -2502790007 AND -2502790001;
  RAISE NOTICE 'Migration 349: % politician_images rows for Boston officials (14 council expected + 0 SC GAPs)', v_count;
END $$;

-- ============================================================
-- MIGRATION LEDGER
-- ============================================================

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('349')
ON CONFLICT (version) DO NOTHING;
