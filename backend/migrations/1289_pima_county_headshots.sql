-- 1289_pima_county_headshots.sql
-- Phase 193 Plan 03 (PIMA-01): AUDIT-ONLY — politician_images rows for all 5
-- sitting Pima County (Arizona) Board of Supervisors members. NOT registered in
-- the migration ledger; the ledger table stays unchanged (audit-only, no ledger
-- footer). Applied via `psql -f` (NOT apply_migration) AFTER the script
--   (_tmp-pima-supervisors-headshots.py) uploads all 5 processed images to
-- Storage.
-- Source: pima.gov CivicPlus CMS asset host
--   https://content.civicplus.com/api/assets/az-pimacounty/{asset_uuid}?cache=1800
--   (per-supervisor uuid-keyed, no WAF, HTTP 200 — RESEARCH § Code Examples).
-- Images are crop-first 4:5 -> 600x750 Lanczos q90 (re-encoded JPEG).
-- Storage path (the `url` below): politician_photos/{politician_uuid}-headshot.jpg
-- Columns: exactly (id, politician_id, url, type, photo_license) — no extra origin-url column.
-- photo_license='us_government_work' for every county-hosted official portrait.
--
-- politician UUIDs below are captured from Plan 02's migration 1288 output
-- (gen_random_uuid() at write time, recorded in 193-02-SUMMARY.md's "Politician
-- UUID Manifest") — NOT invented ahead of time. politician_id is still resolved
-- by external_id at apply time (the UUID appears only in the CDN Storage path).
--
-- Board of Supervisors (5, external_id -4007001..-4007005):
--   -4007001 Rex Scott (District 1)
--   -4007002 Dr. Matt Heinz (District 2)
--   -4007003 Jennifer Allen (District 3, Chair)
--   -4007004 Steve Christy (District 4)
--   -4007005 Andrés Cano (District 5, appointed)

-- ============================================================
-- Board of Supervisors (5 rows)
-- ============================================================

-- Rex Scott (District 1, external_id=-4007001)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4007001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b33f37df-5537-4eee-bb5b-b401a135bc1b-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4007001)
);

-- Dr. Matt Heinz (District 2, external_id=-4007002)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4007002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/be550e00-b04c-4717-99bc-75bd4e8d6608-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4007002)
);

-- Jennifer Allen (District 3, Chair, external_id=-4007003)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4007003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f928a8f0-07fc-47c4-98b2-9801e6adf3dd-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4007003)
);

-- Steve Christy (District 4, external_id=-4007004)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4007004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/41c2b862-78c8-4a27-96c5-50dcdb3a254e-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4007004)
);

-- Andrés Cano (District 5, appointed, external_id=-4007005)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4007005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0e4bebcf-76b4-49df-9197-c114e84d3bd1-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4007005)
);
