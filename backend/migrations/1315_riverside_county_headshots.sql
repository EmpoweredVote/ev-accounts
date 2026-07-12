-- 1315_riverside_county_headshots.sql
-- Phase 201 Plan 03 (CV-01): AUDIT-ONLY -- politician_images rows for all 5
-- sitting Riverside County (California) Board of Supervisors members. NOT
-- registered in the migration ledger; the ledger table stays unchanged
-- (audit-only, no ledger footer). Applied via `psql -f` (NOT apply_migration)
-- AFTER the script (_tmp-riverside-supervisors-headshots.py) uploads all 5
-- processed images to Storage.
--
-- Sources (per-member, hardcoded -- rivco.gov + rivcocob.org are WAF-403;
-- confirmed live during recon that all 5 individual district-site HTML PAGES
-- are ALSO WAF-403 (Cloudflare Managed Challenge), but each site's underlying
-- CMS asset host is not gated the same way):
--   -4010001 Jose Medina           -- rivcodistrict1.org asset host (us_government_work)
--   -4010002 Karen Spiegel (Chair) -- rivcodistrict2.org asset host (us_government_work)
--   -4010003 Chuck Washington      -- Ballotpedia (his own site's only photo was an
--                                     off-center full-body crop; Ballotpedia's
--                                     already-centered portrait used instead) (press_use)
--   -4010004 V. Manuel "Manny" Perez -- rivco4.org asset host (us_government_work)
--   -4010005 Dr. Yxstian Gutierrez -- rivcodistrict5.org asset host (us_government_work)
--
-- Images are crop-first 4:5 -> 600x750 Lanczos q90 (re-encoded JPEG); any
-- source with transparency was white-composited before crop (never a black
-- backdrop from a naive RGBA->RGB convert -- T-201-IMG adjacent fix).
-- Storage path (the `url` below): politician_photos/{politician_uuid}-headshot.jpg
-- Columns: exactly (id, politician_id, url, type, photo_license) -- no extra origin-url column.
--
-- politician UUIDs below are captured from Plan 02's migration 1314 output
-- (gen_random_uuid() at write time, recorded in 201-02-SUMMARY.md's "5
-- Politician UUID Manifest") -- NOT invented ahead of time. politician_id is
-- still resolved by external_id at apply time (the UUID appears only in the
-- CDN Storage path).

-- ============================================================
-- Board of Supervisors (5 rows)
-- ============================================================

-- Jose Medina (District 1, external_id=-4010001)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4010001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ea521b54-7b19-459a-9993-4ce70a84d592-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4010001)
);

-- Karen Spiegel (District 2, Chair, external_id=-4010002)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4010002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9c4ae0c3-81fe-4034-8f64-e5cd6f815f6f-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4010002)
);

-- Chuck Washington (District 3, external_id=-4010003)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4010003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8770fed4-7595-46e2-9103-246f3904a96b-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4010003)
);

-- V. Manuel "Manny" Perez (District 4, external_id=-4010004)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4010004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c986a6af-f09f-4934-83ed-1d9cd26a84f1-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4010004)
);

-- Dr. Yxstian Gutierrez (District 5, external_id=-4010005)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4010005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/26d3fdd0-7fd3-4e41-bd1c-88fb6e2dabae-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4010005)
);
