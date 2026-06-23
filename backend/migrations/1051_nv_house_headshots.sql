-- 1051_nv_house_headshots.sql
-- Phase 159 (NV-STATE-02): AUDIT-ONLY — politician_images rows for 4 NV US House reps.
-- NOT registered in the migration ledger; the ledger stays at 1050.
-- Applied via mcp__supabase-local__execute_sql (not apply_migration) AFTER the script
--   (_tmp-nv-house-headshots.py) uploads all 4 images to Storage.
-- Source: https://unitedstates.github.io/images/congress/450x550/{bioguide}.jpg (4:5, public_domain).
-- Already 4:5 — resize-only to 600x750 Lanczos q90 (no crop step needed).
-- Storage path: politician_photos/{politician_uuid}-headshot.jpg
-- Columns: exactly (id, politician_id, url, type, photo_license) — the origin-url column was removed.
--
-- Bioguide IDs:
--   CD-1 Dina Titus        T000468  uuid 786af5d2-9502-401c-a3ed-61de88e589e9  (-32001)
--   CD-2 Mark E. Amodei    A000369  uuid 030b5074-8335-48b3-8d6b-0ea7c09814a5  (-32002)
--   CD-3 Susie Lee         L000602  uuid 325c7cae-aae6-4d7b-9c03-e707c7423d3c  (-32003)
--   CD-4 Steven Horsford   H001066  uuid 7644cd40-b5c1-494a-8e65-f3126fc7f9ee  (-32004)

-- Dina Titus (CD-1, external_id=-32001)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -32001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/786af5d2-9502-401c-a3ed-61de88e589e9-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -32001)
);

-- Mark E. Amodei (CD-2, external_id=-32002)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -32002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/030b5074-8335-48b3-8d6b-0ea7c09814a5-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -32002)
);

-- Susie Lee (CD-3, external_id=-32003)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -32003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/325c7cae-aae6-4d7b-9c03-e707c7423d3c-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -32003)
);

-- Steven Horsford (CD-4, external_id=-32004)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -32004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7644cd40-b5c1-494a-8e65-f3126fc7f9ee-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -32004)
);
