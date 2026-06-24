-- Migration 1056: Clark County Commission headshots (AUDIT-ONLY)
--
-- Phase 161 (CLARK-01). AUDIT-ONLY: applied via the SQL exec path AFTER the
-- gitignored headshot pipeline (_tmp-clark-county-commission-headshots.py)
-- downloads each clarkcountynv.gov portrait, crops to 4:5, resizes to 600x750,
-- and uploads to the politician_photos Storage bucket. NOT registered in the
-- migration ledger; the structural ledger stays at 1055.
--
-- One politician_images row per commissioner (7/7 uploaded, 0 gaps). Columns are
-- exactly (id, politician_id, url, type, photo_license). The removed image-origin
-- column is intentionally absent. type='default'. politician_id resolved by the
-- stable external_id (UUIDs minted by mig 1055). Idempotent via NOT EXISTS on
-- politician_id. photo_license = 'us_government_work' (clarkcountynv.gov portraits).

-- Michael Naft (District A)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3200301),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/033cf882-aa31-4f1f-b9e0-3b601da1703a-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3200301)
);

-- Marilyn Kirkpatrick (District B)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3200302),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/61cac872-e8f3-4396-aacd-cf1be6509a92-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3200302)
);

-- April Becker (District C)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3200303),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ef0d7745-8530-4588-aab5-80f6ba175725-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3200303)
);

-- William McCurdy II (District D)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3200304),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6cdeb125-85fa-4e9c-80d3-7528a890fd0b-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3200304)
);

-- Tick Segerblom (District E)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3200305),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5ffa5251-9255-44ef-a5d5-8e158f29c6e5-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3200305)
);

-- Justin Jones (District F)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3200306),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8b40944d-30a6-42f4-b4d0-bfa9427e36a6-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3200306)
);

-- James B. Gibson (District G)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3200307),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b9411246-f74d-4502-9f6b-ed5facc37fa6-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3200307)
);
