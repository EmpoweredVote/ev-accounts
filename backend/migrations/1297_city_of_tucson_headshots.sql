-- 1297_city_of_tucson_headshots.sql
-- Phase 194 Plan 03 (TUC-03): AUDIT-ONLY — politician_images rows for all 7
-- sitting City of Tucson (Arizona) officials (Mayor + 6 ward members). NOT
-- registered in the migration ledger (audit-only, no ledger footer). Applied via
-- `psql -f` (NOT apply_migration) AFTER the script (_tmp-tucson-headshots.py)
-- uploads all 7 processed images to Storage.
--
-- Source: NON-WAF hosts (Wikipedia / campaign sites) resolved via the
--   /find-headshots Playwright flow — the official city host is Akamai-WAF-blocked
--   (403), so it is NEVER fetched (Pitfall 3 / T-194-WAF).
-- Images are crop-first 4:5 -> 600x750 Lanczos q90 (re-encoded JPEG).
-- Storage path (the `url` below): politician_photos/{politician_uuid}-headshot.jpg
-- Columns: exactly (id, politician_id, url, type, photo_license) — no origin-url column.
-- photo_license VARIES PER IMAGE (Wikimedia/CC terms, campaign press_use, or
--   operator_supplied) — NOT a uniform value. The per-row licenses below are
--   finalized from the actual sourced provenance (Task 3 manifest).
--
-- politician UUIDs below are from Plan 02's migration 1296 output
-- (194-02-SUMMARY.md UUID manifest) — appear only in the CDN Storage path;
-- politician_id is still resolved by external_id at apply time.
--
-- City Council (7, external_id -4008001..-4008007):
--   -4008001 Regina Romero    (Mayor)
--   -4008002 Lane Santa Cruz  (Ward 1, Vice Mayor)
--   -4008003 Paul Cunningham  (Ward 2)
--   -4008004 Kevin Dahl       (Ward 3)
--   -4008005 Nikki Lee        (Ward 4)
--   -4008006 Selina Barajas   (Ward 5)
--   -4008007 Miranda Schubert (Ward 6)

-- ============================================================
-- City Council (7 rows)
-- ============================================================

-- Regina Romero (Mayor, external_id=-4008001)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4008001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5-headshot.jpg',
       'default', 'wikimedia_public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4008001)
);

-- Lane Santa Cruz (Ward 1, Vice Mayor, external_id=-4008002)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4008002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4c8cda02-3918-4593-b225-b22651b194d0-headshot.jpg',
       'default', 'ballotpedia_portrait'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4008002)
);

-- Paul Cunningham (Ward 2, external_id=-4008003)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4008003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/29c8d055-b661-4940-a052-20eece394d6f-headshot.jpg',
       'default', 'ballotpedia_portrait'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4008003)
);

-- Kevin Dahl (Ward 3, external_id=-4008004)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4008004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3265b939-5585-4edc-a524-2841c7fe6f3d-headshot.jpg',
       'default', 'ballotpedia_portrait'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4008004)
);

-- Nikki Lee (Ward 4, external_id=-4008005)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4008005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a289a080-4a6c-4a46-8772-84c02c2d4903-headshot.jpg',
       'default', 'ballotpedia_portrait'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4008005)
);

-- Selina Barajas (Ward 5, external_id=-4008006)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4008006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/01feb7ad-df57-42bd-9533-073a9edf8c52-headshot.jpg',
       'default', 'ucla_luskin_feature'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4008006)
);

-- Miranda Schubert (Ward 6, external_id=-4008007)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4008007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bf1901df-040d-4005-86e9-ef3e975295b7-headshot.jpg',
       'default', 'ballotpedia_portrait'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4008007)
);
