-- Migration 1355: Town of Sahuarita Council Headshots — AUDIT-ONLY (not registered in the ledger)
--
-- Records the essentials.politician_images rows for the 7 Sahuarita officials (Mayor +
-- Vice Mayor + 5 at-large council members — Mayor/Vice Mayor are council-CHOSEN TITLES,
-- not separately-elected offices, per Town Code 2.10.010) whose 600x750 portraits were
-- uploaded to Supabase Storage (politician_photos/{uuid}-headshot.jpg) by
-- _tmp-sahuarita-headshots.py. One INSERT per official, guarded by WHERE NOT EXISTS on
-- politician_id (idempotent). type='default'.
--
-- SOURCE NOTE (RESEARCH § Common Pitfall 4 — a DIFFERENT block signature than every
-- prior AZ phase): the official host sahuaritaaz.gov (CivicPlus) is NOT WAF-blocked —
-- a direct fetch of the roster/staff HTML pages returns a clean HTTP 200. BUT its
-- discovered /ImageRepository/Document?documentID=N image endpoint SOFT-blocks
-- non-browser clients: it returns HTTP 200 with an EMPTY body (Content-Length: 0, no
-- Content-Type), even with a cookie jar + Referer set. This is a soft block, not a hard
-- 403 — a downloaded 0-byte file is the failure signature here. Per D-05: the direct
-- sahuaritaaz.gov fetch was attempted FIRST with a byte-count > 0 guard; where that came
-- back empty, the portrait was retrieved via the /find-headshots skill's Playwright
-- browser-navigation flow (a real browser context correctly retrieves the image bytes,
-- as already proven for this exact CivicPlus /ImageRepository/Document pattern in the
-- Palmdale CA phase); Ballotpedia/Wikimedia are the secondary fallback. No header-
-- spoofing / evasive-request logic was used to defeat the soft block (T-197-SOFT).
--
-- ROSTER-CURRENCY NOTE (Plan 01 Task 2, execute-time verified 2026-07-16): the 7 UUIDs
-- below bind to the CONFIRMED current sitting roster seeded in Plan 01. The July 21,
-- 2026 primary had NOT occurred at Plan 01 apply time; Kara Egbert's seat (Vice Mayor)
-- is a confirmed OPEN seat for that primary, and per Town Code 2.10.010 the Mayor/Vice
-- Mayor titles are re-chosen by the newly-seated council after the canvass — a
-- post-July-21 reconcile is flagged in 197-01-SUMMARY.md to re-verify both membership
-- and title holders. This migration binds ONLY the Task-2-confirmed roster at seed time
-- (T-197-BIND).
--
-- photo_license (finalized by the orchestrator at Task 3): recorded PER IMAGE — varies
-- by actual source (municipal government portrait / public-press use if sourced from
-- sahuaritaaz.gov via the Playwright flow, Wikimedia/CC terms, Ballotpedia press_use, or
-- operator_supplied) — NOT a uniform value (T-197-LIC). The placeholder text below
-- ('municipal_press_use — Task 3 to finalize per-image license') documents each row's
-- provisional value; the orchestrator MUST replace it with the actual per-image
-- provenance string before this file is applied.
--
-- AUDIT-ONLY: this migration intentionally does NOT write a ledger row (supabase_migrations).

BEGIN;

-- Tom Murphy (Mayor, -4014001) — f32cba1e-d672-440a-9a18-41a312119f40
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4014001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f32cba1e-d672-440a-9a18-41a312119f40-headshot.jpg',
       'default', 'Town of Sahuarita official municipal portrait (sahuaritaaz.gov, press use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4014001)
);

-- Kara Egbert (Vice Mayor, -4014002) — 071e2a28-2fef-489a-97e3-15fb5caaee51
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4014002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/071e2a28-2fef-489a-97e3-15fb5caaee51-headshot.jpg',
       'default', 'Town of Sahuarita official municipal portrait (sahuaritaaz.gov, press use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4014002)
);

-- Deborah Morales (Council Member, -4014003) — c2553fba-f62f-4d58-8a9e-c183f9e8f15d
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4014003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c2553fba-f62f-4d58-8a9e-c183f9e8f15d-headshot.jpg',
       'default', 'Town of Sahuarita official municipal portrait (sahuaritaaz.gov, press use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4014003)
);

-- Steven Gillespie (Council Member, -4014004) — 9f846d00-9bcd-43cd-b57f-628d031d531c
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4014004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9f846d00-9bcd-43cd-b57f-628d031d531c-headshot.jpg',
       'default', 'Town of Sahuarita official municipal portrait (sahuaritaaz.gov, press use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4014004)
);

-- Diane Priolo (Council Member, -4014005) — b9ea3ef0-d4cf-4231-956d-376b6e626ae4
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4014005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b9ea3ef0-d4cf-4231-956d-376b6e626ae4-headshot.jpg',
       'default', 'Town of Sahuarita official municipal portrait (sahuaritaaz.gov, press use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4014005)
);

-- Kim Lisk (Council Member, -4014006) — 866f1db3-4614-4d4f-a68b-96a2b7767091
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4014006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/866f1db3-4614-4d4f-a68b-96a2b7767091-headshot.jpg',
       'default', 'Town of Sahuarita official municipal portrait (sahuaritaaz.gov, press use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4014006)
);

-- Edgar Lytle (Council Member, -4014007) — bbfcbd5f-ff32-40d4-af9f-f5c755869571
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4014007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bbfcbd5f-ff32-40d4-af9f-f5c755869571-headshot.jpg',
       'default', 'Town of Sahuarita official municipal portrait (sahuaritaaz.gov, press use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4014007)
);

COMMIT;
