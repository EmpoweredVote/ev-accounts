-- 1284_az_house_headshots.sql
-- Phase 191 Plan 02 (AZ-STATE-02): AUDIT-ONLY — politician_images rows for 8 of the 9
-- Arizona US House reps. NOT registered in the migration ledger; the ledger stays unchanged.
-- Applied via psql -f (not apply_migration) AFTER the script
--   (_tmp-az-house-headshots.py) uploads all 8 images to Storage.
-- Source: https://unitedstates.github.io/images/congress/450x550/{bioguide}.jpg (4:5, public_domain).
-- Already 4:5 — resize-only to 600x750 Lanczos q90 (no crop step needed).
-- Storage path: politician_photos/{politician_uuid}-headshot.jpg
-- Columns: exactly (id, politician_id, url, type, photo_license) — no photo_origin_url (removed).
--
-- CD-7 Adelita S. Grijalva (external_id=-4007, bioguide G000606) already has a headshot —
-- intentionally EXCLUDED from this migration (Threat T-191-09).
--
-- Bioguide IDs:
--   CD-1 David Schweikert     S001183  uuid 17e59190-17e2-4a90-8353-b5ea8d083480  (-4001)
--   CD-2 Elijah Crane         C001132  uuid 8bb653bd-9cfb-4c1e-a2a0-76b5258c1e61  (-4002)
--   CD-3 Yassamin Ansari      A000381  uuid dde8a67d-a16a-4442-9732-3e620f4f561b  (-4003)
--   CD-4 Greg Stanton         S001211  uuid df1dff40-54c1-47a8-bd36-d3d0bd4e820b  (-4004)
--   CD-5 Andy Biggs           B001302  uuid 8118811a-aadd-4eb9-9208-de0f5d3b29ad  (-4005)
--   CD-6 Juan Ciscomani       C001133  uuid c84bc9f3-6398-4d58-92b8-bbe6f6d1cdd3  (-4006)
--   CD-8 Abraham J. Hamadeh   H001098  uuid ed20dd3f-a463-43c0-b08c-23cbf2a5e387  (-4008)
--   CD-9 Paul A. Gosar        G000565  uuid efd863c6-df64-4b40-9b49-73ddd003dc5d  (-4009)

-- David Schweikert (CD-1, external_id=-4001)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/17e59190-17e2-4a90-8353-b5ea8d083480-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4001)
);

-- Elijah Crane (CD-2, external_id=-4002)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8bb653bd-9cfb-4c1e-a2a0-76b5258c1e61-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4002)
);

-- Yassamin Ansari (CD-3, external_id=-4003)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dde8a67d-a16a-4442-9732-3e620f4f561b-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4003)
);

-- Greg Stanton (CD-4, external_id=-4004)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/df1dff40-54c1-47a8-bd36-d3d0bd4e820b-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4004)
);

-- Andy Biggs (CD-5, external_id=-4005)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8118811a-aadd-4eb9-9208-de0f5d3b29ad-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4005)
);

-- Juan Ciscomani (CD-6, external_id=-4006)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c84bc9f3-6398-4d58-92b8-bbe6f6d1cdd3-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4006)
);

-- Abraham J. Hamadeh (CD-8, external_id=-4008)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ed20dd3f-a463-43c0-b08c-23cbf2a5e387-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4008)
);

-- Paul A. Gosar (CD-9, external_id=-4009)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4009),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/efd863c6-df64-4b40-9b49-73ddd003dc5d-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4009)
);
