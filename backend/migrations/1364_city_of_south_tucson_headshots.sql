-- Migration 1364: City of South Tucson Council Headshots — AUDIT-ONLY (not registered in the ledger)
--
-- Records the essentials.politician_images rows for the 7 City of South Tucson officials
-- (Mayor + Vice Mayor + Acting Mayor titles + 4 at-large Council Members — Mayor/Vice
-- Mayor/Acting Mayor are council-CHOSEN TITLES, not separately-elected offices) whose
-- 600x750 portraits were uploaded to Supabase Storage
-- (politician_photos/{uuid}-headshot.jpg) by _tmp-south-tucson-headshots.py. One INSERT
-- per official, guarded by WHERE NOT EXISTS on politician_id (idempotent). type='default'.
--
-- SOURCE NOTE (RESEARCH § Common Pitfall 4 — a DIFFERENT block signature than every
-- prior AZ phase): the official host southtucsonaz.gov (Cloudflare, NOT Akamai, NOT the
-- Sahuarita CivicPlus soft-block) returns HTTP 403 with a genuine Cloudflare "Just a
-- moment..." managed-JS-challenge page to a direct curl/WebFetch of its HTML pages
-- (/citycouncil, /directory), confirmed live 2026-07-17. Per D-06 the direct fetch was
-- attempted first; the HTML challenge was cleared via the /find-headshots skill's
-- Playwright browser-navigation flow (a real browser context solves/waits out the
-- managed challenge), which surfaced the /citycouncil lazy-loaded council carousel
-- exposing the 7 official municipal portraits under
-- /files/media/citycouncil/image/{id}/{file}. Those static image ASSETS are NOT
-- challenge-gated — a byte-count-verified curl of each full-size original returned an
-- HTTP 200 real image — so all 7 authentic municipal portraits were sourced from the
-- official site (no Ballotpedia/Wikimedia fallback was needed). No header-spoofing /
-- evasive-request logic was used to defeat the Cloudflare challenge (T-198-CF).
--
-- ROSTER-CURRENCY NOTE (Plan 01 Task 2, execute-time verified 2026-07-17): the 7 UUIDs
-- below bind to the CONFIRMED current sitting roster seeded in Plan 01 (re-confirmed
-- 2026-07-17 against the live southtucsonaz.gov /citycouncil roster: Valenzuela Mayor,
-- Brown-Dominguez Vice Mayor, Robles Acting Mayor, + Aguirre/Diaz/Flagg/Jimenez). The
-- July 21, 2026 primary had NOT occurred / been certified at seed time; 3 seats
-- (Valenzuela, Flagg, Aguirre — TERMS THRU 2026) are up, and a post-July-21 reconcile of
-- both membership and the council-chosen title holders is flagged in 198-01-SUMMARY.md.
-- This migration binds ONLY the Task-2-confirmed roster at seed time (T-198-BIND).
--
-- photo_license (T-198-LIC): recorded PER IMAGE. All 7 portraits genuinely share ONE
-- source — the official southtucsonaz.gov council carousel — so a single honest license
-- value is correct here (the per-image rule guards against defaulting when sources
-- DIFFER, which is not the case for this council). No honest blanks: an authentic
-- municipal portrait was found for all 7 officials. NOTE: Aguirre's official upload is
-- only 103x130 (the city uploaded a thumbnail); it is his authentic portrait, processed
-- and bound as such, but is low-resolution — a future higher-res re-source is optional.
--
-- AUDIT-ONLY: this migration intentionally does NOT write a ledger row (supabase_migrations).

BEGIN;

-- Roxanna Valenzuela (Mayor, -4015001) — 94fd53ed-f05a-4e65-a600-0fb5076f2109
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4015001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/94fd53ed-f05a-4e65-a600-0fb5076f2109-headshot.jpg',
       'default', 'City of South Tucson official municipal portrait (southtucsonaz.gov, press use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4015001)
);

-- Melissa Brown-Dominguez (Vice Mayor, -4015002) — cbee242a-e992-46e6-a7ea-5aad11816c50
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4015002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cbee242a-e992-46e6-a7ea-5aad11816c50-headshot.jpg',
       'default', 'City of South Tucson official municipal portrait (southtucsonaz.gov, press use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4015002)
);

-- Pablo Robles (Acting Mayor, -4015003) — a6888435-018b-448c-8272-163a330fd5e3
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4015003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a6888435-018b-448c-8272-163a330fd5e3-headshot.jpg',
       'default', 'City of South Tucson official municipal portrait (southtucsonaz.gov, press use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4015003)
);

-- Dulce Jimenez (Council Member, -4015004) — 0a258242-d8c2-43ca-89ae-b891db3e21d8
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4015004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0a258242-d8c2-43ca-89ae-b891db3e21d8-headshot.jpg',
       'default', 'City of South Tucson official municipal portrait (southtucsonaz.gov, press use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4015004)
);

-- Paul Diaz (Council Member, -4015005) — 1ce510bf-2eed-4335-83a8-54fa2079b8a3
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4015005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1ce510bf-2eed-4335-83a8-54fa2079b8a3-headshot.jpg',
       'default', 'City of South Tucson official municipal portrait (southtucsonaz.gov, press use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4015005)
);

-- Brian Flagg (Council Member, -4015006) — 932bed88-cb72-4611-8394-05f6f476d307
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4015006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/932bed88-cb72-4611-8394-05f6f476d307-headshot.jpg',
       'default', 'City of South Tucson official municipal portrait (southtucsonaz.gov, press use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4015006)
);

-- Cesar Aguirre (Council Member, -4015007) — aec8b558-0a8b-4ee1-bc26-1cb9369f6ed5
-- (authentic official portrait; low-resolution 103x130 source upload — see header note)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4015007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/aec8b558-0a8b-4ee1-bc26-1cb9369f6ed5-headshot.jpg',
       'default', 'City of South Tucson official municipal portrait (southtucsonaz.gov, press use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4015007)
);

COMMIT;
