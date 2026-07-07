-- Migration 1205: Beaverton SD 48J + Hillsboro SD 1J School Board Headshots — AUDIT-ONLY
-- (not registered in the ledger)
--
-- NUMBERING NOTE (deviation from the plan's literal "1204" filename): at execution time,
-- migration number 1204 was already claimed on-disk by a concurrent workstream
-- (1204_az_ballot_ineligible_reconciliation.sql, untracked in git but present on disk before
-- this file was authored). Per the on-disk-MAX-authoritative convention (the same convention
-- that renumbered this phase's structural migration from the plan's original guess to 1203 —
-- see 183-01-SUMMARY.md), this headshot migration is numbered 1205 instead of the plan's
-- literal 1204 to avoid a filename collision. Next migration after this one: 1206.
--
-- Phase 183 Plan 03 — WSCH-01 + WSCH-02 (headshot portion).
--
-- Records the essentials.politician_images rows for the 14 directors (7 Beaverton SD 48J +
-- 7 Hillsboro SD 1J) whose 600x750 portraits were uploaded to Supabase Storage
-- (politician_photos/{uuid}-headshot.jpg) by _tmp-westmetro-school-wave1-headshots.py. One
-- INSERT per SOURCED director, guarded by WHERE NOT EXISTS on politician_id (idempotent).
-- type='default'. photo_license='press_use' for all 14 — official district-hosted portraits
-- served from each district's own finalsite CMS media library (government-hosted), matching
-- the string used by the freshest headshot migration (1197_cornelius_headshots.sql).
--
-- SOURCING NOTE: all 14 sources are plain opaque RGB JPEGs on resources.finalsite.net (the
-- districts' own finalsite CDN) — HTTP 200, no WAF, no fallback chain needed (the cleanest
-- sourcing outcome in the milestone). Beaverton's 7 sources are genuinely high-resolution
-- native originals (well above 600x750) — direct crop-4:5 (no-op, already 4:5) -> resize, no
-- upscale needed. Hillsboro's 7 sources are genuine originals BELOW 600x750 but already
-- exactly 4:5 (256x320 / 320x400 / 172x215) — Lanczos-upscaled to 600x750 from the genuine
-- UNTRANSFORMED original (never the CDN's interpolated t_image_size_6 upscale rendition, which
-- would fabricate detail). This is an honest, documented partial-quality upscale of a REAL
-- source image for all 7 Hillsboro directors, not a fabrication (D-R5).
--
-- AUDIT-ONLY: this migration intentionally does NOT write a ledger row (matches the freshest
-- headshot migration 1197_cornelius_headshots.sql — no migration-ledger registration INSERT
-- anywhere in this file).
--
-- columns: essentials.politician_images is exactly (id, politician_id, url, type,
-- photo_license) — there is no image-origin-url column, no auto-generated-path column.
--
-- ORCHESTRATOR NOTE (expected-count kept in sync with the post-verify gate below):
--   The 14 blocks below are pre-filled with the politician UUIDs minted by structural
--   migration 1203 (see 183-02-SUMMARY.md) — the same UUIDs the pipeline resolves at runtime
--   by external_id and embeds in each Storage path. Before applying:
--     1. DELETE the entire INSERT block for any director the pipeline manifest does NOT
--        report SUCCESS for (honest gap — no fabrication; not expected here given confirmed
--        14/14 sourcing).
--     2. Confirm each remaining block's photo_license is 'press_use' (should be uniform since
--        all 14 sources are each district's own finalsite CDN).
--     3. If any block is deleted in step 1, edit the post-verification DO block's expected
--        uuid VALUES list below to match the ACTUAL directors remaining.

BEGIN;

-- ================= Beaverton School District 48J — School Board (Zone 1-7) =================

-- Van Truong (Zone 1, -4101921) — SOURCE: beaverton.k12.or.us / resources.finalsite.net (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4101921),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/152ef0c5-5eef-4edb-9704-065c1fb398fc-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101921)
);

-- Karen Pérez (Zone 2, -4101922) — SOURCE: beaverton.k12.or.us / resources.finalsite.net (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4101922),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6a6c94b1-4c69-4c85-b270-0004fcfe47ee-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101922)
);

-- Melissa Potter (Zone 3, Vice Chair, -4101923) — SOURCE: beaverton.k12.or.us / resources.finalsite.net (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4101923),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/60f85f8b-cade-443f-96a2-f818b29f034f-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101923)
);

-- Sunita Garg (Zone 4, -4101924) — SOURCE: beaverton.k12.or.us / resources.finalsite.net (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4101924),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ae9e41ea-2220-4b0c-a9dc-c4ee498f8c65-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101924)
);

-- Syed Qasim (Zone 5, -4101925) — SOURCE: beaverton.k12.or.us / resources.finalsite.net (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4101925),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f473703c-14ac-4279-8a6f-674b5a994ebb-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101925)
);

-- Justice Rajee (Zone 6, Chair, -4101926) — SOURCE: beaverton.k12.or.us / resources.finalsite.net (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4101926),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/66d83b18-fba9-4a4e-82aa-fd23db5964e5-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101926)
);

-- Tammy Carpenter (Zone 7, -4101927) — SOURCE: beaverton.k12.or.us / resources.finalsite.net (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4101927),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b77caa26-b55a-4d98-a74c-cb210542b16e-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4101927)
);

-- ================= Hillsboro School District 1J — Board of Directors (Position 1-7) =================
-- All 7 sources below are genuine finalsite originals BELOW 600x750 (256x320/320x400/172x215)
-- but already exactly 4:5 — Lanczos-upscaled to 600x750, never the CDN's interpolated
-- t_image_size_6 rendition. Honest partial-quality upscale of a real source, not fabrication.

-- Yessica Hardin Mercado (Position 1, -4100024) — SOURCE: hsd.k12.or.us / resources.finalsite.net genuine original ~256x320 (upscaled)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4100024),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/84569649-054b-4e50-89c7-9ec858d83fd6-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4100024)
);

-- Mark Watson (Position 2, -4100025) — SOURCE: hsd.k12.or.us / resources.finalsite.net genuine original ~256x320 (upscaled)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4100025),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dffd7327-21fc-4934-8e93-c1814964097d-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4100025)
);

-- Nancy Thomas (Position 3, -4100026) — SOURCE: hsd.k12.or.us / resources.finalsite.net genuine original ~256x320 (upscaled)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4100026),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e9c1abfe-d70f-4f92-81df-cbb22a6f859a-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4100026)
);

-- See Eun Kim (Position 4, Vice Chair, -4100027) — SOURCE: hsd.k12.or.us / resources.finalsite.net genuine original ~320x400 (upscaled)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4100027),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/35cd5b91-858e-4da2-b31e-e05a9f27ac73-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4100027)
);

-- Ivette Pantoja (Position 5, Chair, -4100028) — SOURCE: hsd.k12.or.us / resources.finalsite.net genuine original ~320x400 (upscaled)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4100028),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1da5bc5c-a083-44b1-b9e2-6053814b2dab-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4100028)
);

-- Katie Rhyne (Position 6, -4100029) — SOURCE: hsd.k12.or.us / resources.finalsite.net genuine original ~172x215 (upscaled; softest of the 14)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4100029),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/32e4adbb-4faf-4c25-bb90-6ceb521e4401-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4100029)
);

-- Patrick Maguire (Position 7, -4100030) — SOURCE: hsd.k12.or.us / resources.finalsite.net genuine original ~320x400 (upscaled)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4100030),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/553ad874-7ebe-43e0-aab9-2ee3434a6956-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4100030)
);

-- Post-verification gate (url-embeds-uuid): asserts EVERY politician uuid this migration's
-- INSERTs target has a politician_images row whose url embeds that same uuid. The gate derives
-- its identity set from the SAME uuid literals the INSERTs use (the VALUES list below) rather
-- than a hardcoded external_id range — a clone that edits the INSERT uuids but forgets the gate
-- now fails loudly instead of passing vacuously against a previous city's/district's rows.
-- Catches: (a) a missing/orphaned insert for any targeted uuid, and (b) a url uuid segment that
-- does not match the politician the row points at (would 404).
-- WHEN CLONING FOR A NEW DISTRICT/CITY: replace the uuid VALUES list below with the new
-- roster's uuids — it is the same list as the INSERT blocks above; keep them in sync.
DO $$
DECLARE missing INTEGER;
BEGIN
  SELECT COUNT(*) INTO missing
  FROM (VALUES
    ('152ef0c5-5eef-4edb-9704-065c1fb398fc'::uuid),  -- Van Truong
    ('6a6c94b1-4c69-4c85-b270-0004fcfe47ee'::uuid),  -- Karen Pérez
    ('60f85f8b-cade-443f-96a2-f818b29f034f'::uuid),  -- Melissa Potter
    ('ae9e41ea-2220-4b0c-a9dc-c4ee498f8c65'::uuid),  -- Sunita Garg
    ('f473703c-14ac-4279-8a6f-674b5a994ebb'::uuid),  -- Syed Qasim
    ('66d83b18-fba9-4a4e-82aa-fd23db5964e5'::uuid),  -- Justice Rajee
    ('b77caa26-b55a-4d98-a74c-cb210542b16e'::uuid),  -- Tammy Carpenter
    ('84569649-054b-4e50-89c7-9ec858d83fd6'::uuid),  -- Yessica Hardin Mercado
    ('dffd7327-21fc-4934-8e93-c1814964097d'::uuid),  -- Mark Watson
    ('e9c1abfe-d70f-4f92-81df-cbb22a6f859a'::uuid),  -- Nancy Thomas
    ('35cd5b91-858e-4da2-b31e-e05a9f27ac73'::uuid),  -- See Eun Kim
    ('1da5bc5c-a083-44b1-b9e2-6053814b2dab'::uuid),  -- Ivette Pantoja
    ('32e4adbb-4faf-4c25-bb90-6ceb521e4401'::uuid),  -- Katie Rhyne
    ('553ad874-7ebe-43e0-aab9-2ee3434a6956'::uuid)   -- Patrick Maguire
  ) AS expected(pid)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.politician_images pi
    WHERE pi.politician_id = expected.pid
      AND pi.url LIKE '%' || expected.pid::text || '%'
  );
  IF missing <> 0 THEN
    RAISE EXCEPTION 'Westmetro school boards wave-1 headshot gate: % targeted politician uuid(s) lack a politician_images row with a uuid-embedding url', missing;
  END IF;
END $$;

COMMIT;
