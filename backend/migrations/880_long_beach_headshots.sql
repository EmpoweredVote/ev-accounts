-- Migration 880: Long Beach headshots (AUDIT-ONLY — NOT registered in schema_migrations)
-- Phase 142 (v17.0 LA County City Coverage — Wave 2). Applied: 2026-06-19
--
-- Adds 600x750 portraits for the 4 new officials seated in migration 879, and upgrades
-- two pre-existing images whose only copy was scraped_no_license but whose origin is the
-- official longbeach.gov CDN. Source portraits downloaded from longbeach.gov globalassets,
-- cropped 4:5, resized 600x750 Lanczos q90, uploaded to Supabase Storage politician_photos.
-- Human-verified (correct person, clean crop, no overlays) before apply.
--
-- AUDIT-ONLY: applied via raw SQL (mcp__supabase-local / psql). Does NOT advance the
-- schema_migrations ledger (same convention as 200/209/212). Idempotent.
--
-- UUIDs (by external_id): -700050 Thrash-Ntuk 61aa19c9 · -700051 McIntosh 769374f9 ·
--                         -700052 Haubert 2c36a446 · -700053 Doud fe801750

BEGIN;

-- 1. New headshot rows (type='default', press_use) — guarded WHERE NOT EXISTS on politician_id
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT v.uuid::uuid, v.url, 'default', 'press_use'
FROM (VALUES
  ('61aa19c9-4896-49f2-b68b-3192372cf001','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/61aa19c9-4896-49f2-b68b-3192372cf001-headshot.jpg'),
  ('769374f9-6f4a-428f-ac54-6e1f996ee487','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/769374f9-6f4a-428f-ac54-6e1f996ee487-headshot.jpg'),
  ('2c36a446-6766-483c-b043-73bb5244eabb','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2c36a446-6766-483c-b043-73bb5244eabb-headshot.jpg'),
  ('fe801750-dcb3-41c3-a1cc-8886011d2392','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fe801750-dcb3-41c3-a1cc-8886011d2392-headshot.jpg')
) AS v(uuid, url)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = v.uuid::uuid);

-- 2. Backfill photo_origin_url for the 4 new officials (the longbeach.gov source image)
UPDATE essentials.politicians SET photo_origin_url = v.origin
FROM (VALUES
  (-700050,'https://www.longbeach.gov/globalassets/officials/media-library/images/tunua185x200.jpg'),
  (-700051,'https://www.longbeach.gov/globalassets/city-attorney/media-library/images/dawnmcintosh_06-20-23_003.jpg'),
  (-700052,'https://www.longbeach.gov/globalassets/officials/media-library/images/haubert185x200.jpg'),
  (-700053,'https://www.longbeach.gov/globalassets/officials/media-library/images/doud185x200.jpg')
) AS v(ext, origin)
WHERE essentials.politicians.external_id = v.ext
  AND (essentials.politicians.photo_origin_url IS NULL OR essentials.politicians.photo_origin_url = '');

-- 3. License upgrade for Kerr + Uranga — their kept image's origin is the official longbeach.gov
--    CDN (district-5 / district-7 media libraries), so press_use is accurate.
UPDATE essentials.politician_images SET photo_license = 'press_use'
WHERE id IN (
  'f8f0a103-53ee-48b2-85ef-85d269718a24',  -- Megan Kerr 665835
  '20666df2-f574-428f-b6a6-e3a570e0dcbf'   -- Roberto Uranga 665839
) AND photo_license <> 'press_use';

-- 3b. Audit-driven license upgrade for 4 more existing officials whose image origin is
--     verified longbeach.gov (district media libraries) — same justification as Kerr/Uranga.
--     Rex Richardson (-200813) intentionally EXCLUDED: photo_origin_url is NULL, so the
--     source is unverified and press_use cannot be honestly claimed (left scraped_no_license).
UPDATE essentials.politician_images SET photo_license = 'press_use'
WHERE id IN (
  '09aaea53-1849-4a53-a907-f446728d3ed6',  -- Mary Zendejas 665830 (district-? media library)
  '8a972b44-8f3b-4ccf-9f2e-8cb92ca75cd3',  -- Kristina Duggan 665833
  'ca24169c-b7ad-41ed-ba73-aee940caa994',  -- Suely Saro 665838
  '253ccc94-8eae-4dbd-bb7d-1841d37d6aa6'   -- Joni Ricks-Oddie 665842
) AND photo_license <> 'press_use';

COMMIT;

-- ── Post-verification ───────────────────────────────────────────────────────────
-- 1. 4 new officials each have exactly one type='default' image
-- 2. all 13 LB officials have >=1 image (LEFT JOIN missing = 0)
-- 3. no LB official has >1 type='default' image
-- 4. schema_migrations MAX(version) unchanged (still 879)
