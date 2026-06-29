-- Migration 1108: CCSD Board of School Trustees headshots (politician_images)
--
-- Phase 166 Plan 02 — CCSD-01 (headshot portion).
-- AUDIT-ONLY: NOT registered in the structural ledger (structural ledger stays at 1107).
--
-- One INSERT block per SUCCESS trustee (7 of 11). Source: Ballotpedia infobox
-- portraits (ccsd.net + BoardDocs skipped — Akamai WAF-403). 600x750 4:5 crops
-- mirrored to Storage politician_photos/{uuid}-headshot.jpg. photo_license='press_use'.
--
-- DOCUMENTED GAPS (no fabrication — honest blanks, no row):
--   -3209003 Tameka Henry (elected, District C)        — no clean portrait found
--   -3209009 Ramona Esparza-Stoffregan (appointed, Henderson)  — no clean correct-person source
--   -3209010 Adam Johnson (appointed, Las Vegas)       — Ballotpedia 'Adam Johnson' is a different person (common-name), rejected
--   -3209011 Lisa Satory (appointed, Clark County)     — no clean correct-person source
--
-- columns: (id, politician_id, url, type, photo_license); the removed image-origin
-- column is intentionally absent. type='default'. Idempotent via NOT EXISTS.
-- All correct-person visually spot-checked before insert (no text/graphic overlays).

BEGIN;

-- Emily Stevens (District A) -3209001
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3209001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/76b03835-5935-4aa5-a407-e9e05f2a06e9-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3209001)
);

-- Lydia Dominguez (District B) -3209002
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3209002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/96ba9a30-bf00-4d6e-aebb-7a6cac741d39-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3209002)
);

-- Brenda Zamora (District D) -3209004
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3209004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e59931c3-7474-41f9-a4a9-bf9ea7317830-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3209004)
);

-- Lorena Biassotti (District E) -3209005
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3209005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/df815b44-10fb-43d1-b329-7730bd08a3d0-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3209005)
);

-- Irene Bustamante Adams (District F) -3209006
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3209006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/97a70e4a-8f53-4816-bc4d-15d5d0ce3a14-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3209006)
);

-- Linda P. Cavazos (District G) -3209007
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3209007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9ba19701-6b5f-413e-8d7e-99b98824d25f-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3209007)
);

-- Isaac Barron (Appointed - City of North Las Vegas) -3209008
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -3209008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f297e12a-2fac-4de4-b2d1-0ee1c769f93d-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -3209008)
);

COMMIT;
