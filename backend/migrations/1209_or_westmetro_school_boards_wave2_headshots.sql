-- Migration 1209: Tigard-Tualatin SD 23J + Forest Grove SD 15 + Sherwood SD 88J
-- School Board Headshots — AUDIT-ONLY (not registered in the ledger)
--
-- NUMBERING NOTE: planned as 1207 in the phase docs, but a concurrent Missouri 2026-House
-- workstream claimed 1206 AND 1207 (1206_seed_mo_2026_house_elections_races.sql /
-- 1207_seed_mo_2026_house_candidates.sql). Per the on-disk-MAX-authoritative convention, the
-- structural migration became 1208 and this headshot (audit-only) migration is 1209.
--
-- Phase 184 Plan 03 — WSCH-03 + WSCH-04 + WSCH-05 (headshot portion).
--
-- Records the essentials.politician_images rows for the 14 directors whose 600x750 portraits
-- were uploaded to Supabase Storage (politician_photos/{uuid}-headshot.jpg) by
-- _tmp-westmetro-school-wave2-headshots.py. One INSERT per SOURCED director.
--
-- WR-03 FIX (baked in from authoring, not cloned-then-patched): each INSERT uses
--   INSERT ... SELECT gen_random_uuid(), p.id, '<url>', 'default', '<license>'
--   FROM essentials.politicians p WHERE p.external_id = -N
--     AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id)
-- so a missing politician skips the block entirely instead of degrading to a NULL politician_id
-- attempt (the 1205 scalar-subquery-in-SELECT-list shape was vacuously guarded).
--
-- THREE SOURCING TECHNIQUES this wave:
--   TTSD (5): finalsite untransformed originals — small circular photos (3.3-27KB),
--     Lanczos-upscaled to 600x750 with a documented partial-quality note (A5), same class as
--     Hillsboro in Wave 1.
--   FGSD (4): Edlio direct JPEGs (200-292KB genuine photos).
--   SSD (5): WordPress + Fly Dynamic Image Resizer originals recovered via
--     wp-json/wp/v2/media/{id} -> media_details.sizes.large.source_url (NOT the on-page
--     fly-images pre-cropped URL — a transform-output trap). 4/5 native 2400x3000 exact-4:5
--     (no upscale); 1/5 (Matt Kaufman) near-square 1831x1694 center-cropped.
--
-- DOCUMENTED GAP (no fabrication — honest blank, NO row inserted):
--   -4105164 Linda Harrington (FGSD Position 4) — the district's on-page image is a "Coming
--     Soon" placeholder (4.3KB); the only local-news photo found (Forest Grove News-Times,
--     June 25 2026) is a two-person scene shot, not a usable single-face portrait. Recent
--     June 23 2026 mid-term appointee; the district has not yet published her portrait (D-R5).
--
-- AUDIT-ONLY: this migration intentionally does NOT write a ledger row (matches the freshest
-- headshot migration convention — 1197_cornelius / 1205_wave1 — no schema_migrations INSERT).
--
-- columns: essentials.politician_images is exactly (id, politician_id, url, type, photo_license)
-- — there is no image-origin-url column, no auto-generated-path column.
-- photo_license='press_use' for all 14 (official district-hosted portraits).
--
-- ORCHESTRATOR NOTE (kept in sync with the post-verify gate below): the 14 blocks are pre-filled
-- with the UUIDs minted by structural migration 1208 (184-02-SUMMARY.md), the same UUIDs the
-- pipeline resolved at runtime and embedded in each Storage path (manifest: 14/14 SUCCESS).
-- If any director's upload had failed, DELETE that block AND its uuid VALUES-list row below.

BEGIN;

-- ================= Tigard-Tualatin SD 23J — School Board (Position 1-5) =================
-- finalsite untransformed originals; small circular sources Lanczos-upscaled to 600x750 (A5).

-- David Jaimes (Position 1, -4112241) — SOURCE: ttsdschools.org / resources.finalsite.net (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/38449e1d-d7b6-42ba-a276-23f8eb7577c9-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -4112241
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

-- Kristen Miles (Position 2, -4112242) — SOURCE: ttsdschools.org / resources.finalsite.net (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cf4a4d49-6c3c-4301-854c-5ca675bc7637-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -4112242
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

-- Tristan Irvin (Position 3, Vice Chair, -4112243) — SOURCE: ttsdschools.org / resources.finalsite.net (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/641306e7-77fe-4b51-be95-a2523c89838f-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -4112243
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

-- Jill Zurschmeide (Position 4, Chair, -4112244) — SOURCE: ttsdschools.org / resources.finalsite.net (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c9a660c1-7056-4986-92dd-05e8dae75ffb-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -4112244
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

-- Crystal Weston (Position 5, -4112245) — SOURCE: ttsdschools.org / resources.finalsite.net (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8a480326-0f2d-4b19-b32b-566f5415152e-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -4112245
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

-- ================= Forest Grove SD 15 — School Board (Position 1-5; P4 Harrington = documented gap) =================
-- Edlio direct JPEGs. Position 4 (Linda Harrington, -4105164) intentionally has NO row — see gap note above.

-- Brisa Franco (Position 1, -4105161) — SOURCE: fgsdk12.org / 3.files.edl.io (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9b4ff67f-41d4-489f-8425-4c3373bc1bdd-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -4105161
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

-- Pete Truax (Position 2, -4105162) — SOURCE: fgsdk12.org / 3.files.edl.io (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7f1e8356-75a4-4ce5-8410-efefa0277f2f-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -4105162
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

-- Alma Lozano (Position 3, Vice Chair, -4105163) — SOURCE: fgsdk12.org / 3.files.edl.io (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6e7c4b85-7aec-45f1-9c3f-8994e0d29738-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -4105163
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

-- Kristy Kottkey (Position 5, Chair, -4105165) — SOURCE: fgsdk12.org / 3.files.edl.io (direct, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/81000b71-a70a-421c-a957-b4abf3459ec5-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -4105165
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

-- ================= Sherwood SD 88J — Board of Directors (Position 1-5) =================
-- WP REST media_details.sizes.large originals. 4/5 native 2400x3000; Kaufman near-square center-cropped.

-- Harmony Carson (Position 1, Board Chair, -4111291) — SOURCE: sherwood.k12.or.us WP REST large rendition
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b890e3ea-5c9c-46bc-9de2-162a4bba682f-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -4111291
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

-- Matt Kaufman (Position 2, -4111292) — SOURCE: sherwood.k12.or.us WP REST large rendition (near-square, center-cropped)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/80d8161b-176a-417c-894b-9ce87e0ee469-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -4111292
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

-- Abby Hawkins (Position 3, Board Vice Chair, -4111293) — SOURCE: sherwood.k12.or.us WP REST large rendition
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/db661550-a3ce-454d-a2ca-7f48fcd5c635-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -4111293
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

-- Hans Moller (Position 4, -4111294) — SOURCE: sherwood.k12.or.us WP REST large rendition
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7da7aada-692c-4a8f-8b12-7ca10806aa65-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -4111294
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

-- Matt Thornton (Position 5, -4111295) — SOURCE: sherwood.k12.or.us WP REST large rendition
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/18bb831c-13b2-4b8a-978f-53593539a772-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -4111295
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

-- Post-verification gate (url-embeds-uuid): asserts EVERY politician uuid this migration's
-- INSERTs target has a politician_images row whose url embeds that same uuid. The gate derives
-- its identity set from the SAME uuid literals the INSERTs use (below), so a clone that edits the
-- INSERT uuids but forgets the gate fails loudly instead of passing vacuously. The 14 uuids match
-- the 14 SUCCESS uploads (Harrington -4105164 is a documented gap — intentionally absent).
DO $$
DECLARE missing INTEGER;
BEGIN
  SELECT COUNT(*) INTO missing
  FROM (VALUES
    ('38449e1d-d7b6-42ba-a276-23f8eb7577c9'::uuid),  -- David Jaimes (TTSD P1)
    ('cf4a4d49-6c3c-4301-854c-5ca675bc7637'::uuid),  -- Kristen Miles (TTSD P2)
    ('641306e7-77fe-4b51-be95-a2523c89838f'::uuid),  -- Tristan Irvin (TTSD P3, VC)
    ('c9a660c1-7056-4986-92dd-05e8dae75ffb'::uuid),  -- Jill Zurschmeide (TTSD P4, Chair)
    ('8a480326-0f2d-4b19-b32b-566f5415152e'::uuid),  -- Crystal Weston (TTSD P5)
    ('9b4ff67f-41d4-489f-8425-4c3373bc1bdd'::uuid),  -- Brisa Franco (FGSD P1)
    ('7f1e8356-75a4-4ce5-8410-efefa0277f2f'::uuid),  -- Pete Truax (FGSD P2)
    ('6e7c4b85-7aec-45f1-9c3f-8994e0d29738'::uuid),  -- Alma Lozano (FGSD P3, VC)
    ('81000b71-a70a-421c-a957-b4abf3459ec5'::uuid),  -- Kristy Kottkey (FGSD P5, Chair)
    ('b890e3ea-5c9c-46bc-9de2-162a4bba682f'::uuid),  -- Harmony Carson (SSD P1, Board Chair)
    ('80d8161b-176a-417c-894b-9ce87e0ee469'::uuid),  -- Matt Kaufman (SSD P2)
    ('db661550-a3ce-454d-a2ca-7f48fcd5c635'::uuid),  -- Abby Hawkins (SSD P3, Board Vice Chair)
    ('7da7aada-692c-4a8f-8b12-7ca10806aa65'::uuid),  -- Hans Moller (SSD P4)
    ('18bb831c-13b2-4b8a-978f-53593539a772'::uuid)   -- Matt Thornton (SSD P5)
  ) AS expected(pid)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.politician_images pi
    WHERE pi.politician_id = expected.pid
      AND pi.url LIKE '%' || expected.pid::text || '%'
  );
  IF missing <> 0 THEN
    RAISE EXCEPTION 'Westmetro school boards wave-2 headshot gate: % targeted politician uuid(s) lack a politician_images row with a uuid-embedding url', missing;
  END IF;
END $$;

COMMIT;
