-- 1218_washco_2026_challenger_headshots.sql
-- Phase 185-02 Task 3 (follow-up via /find-headshots): headshots for 2 of the 4 new west-metro
-- 2026 challengers. AUDIT-ONLY — applied via raw SQL / storage upload, NOT registered in
-- supabase_migrations.schema_migrations. Idempotent.
--
-- Sourced from each candidate's official campaign site (press_use), operator-approved per photo,
-- identity-verified visually. Each processed: crop to 4:5 (center-horizontal, no vertical auto-crop) ->
-- 600x750 Lanczos q90 JPEG -> uploaded to Supabase Storage politician_photos/{politician_id}-headshot.jpg
-- (x-upsert, HTTP 200). Public URL served 200 image/jpeg.
--
--   Rachel Philip   (9030070b-...) Beaverton City Council Position 1 — rachelforbeaverton.com portrait (2500x2500)
--   Steve Callaway  (007eaf5b-...) Washington County Commissioner District 4 — electstevecallaway.com (1000x1000)
--
-- The other 2 new challengers (Evelyn Kocher -4850003, Beth Dittman -4850004) were SKIPPED by operator
-- decision: their campaign sites have only group/event/family photos, no clean solo headshot. They remain
-- headshot-less pending a proper portrait (discovery pipeline / later pass).
--
-- On-disk counter note: 1213=races, 1215=candidates, 1216=discovery for this phase; 1217 taken by a
-- parallel MD workstream, so this headshot mig is 1218. No schema_migrations ledger INSERT.

-- Rachel Philip
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '9030070b-13e6-4a3b-867c-546418b8c9a8',
  'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/9030070b-13e6-4a3b-867c-546418b8c9a8-headshot.jpg',
  'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
  WHERE pi.politician_id='9030070b-13e6-4a3b-867c-546418b8c9a8' AND pi.type='default');
UPDATE essentials.politicians SET photo_origin_url='https://www.rachelforbeaverton.com/'
  WHERE id='9030070b-13e6-4a3b-867c-546418b8c9a8'
    AND photo_origin_url IS DISTINCT FROM 'https://www.rachelforbeaverton.com/';

-- Steve Callaway
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '007eaf5b-bacc-4510-900d-dd7675fbdb8e',
  'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/007eaf5b-bacc-4510-900d-dd7675fbdb8e-headshot.jpg',
  'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
  WHERE pi.politician_id='007eaf5b-bacc-4510-900d-dd7675fbdb8e' AND pi.type='default');
UPDATE essentials.politicians SET photo_origin_url='https://electstevecallaway.com/about/'
  WHERE id='007eaf5b-bacc-4510-900d-dd7675fbdb8e'
    AND photo_origin_url IS DISTINCT FROM 'https://electstevecallaway.com/about/';

-- POST-VERIFICATION (audit): both should have n_default=1.
-- SELECT p.full_name, COUNT(pi.id) FILTER (WHERE pi.type='default') AS n_default
--   FROM essentials.politicians p LEFT JOIN essentials.politician_images pi ON pi.politician_id=p.id
--  WHERE p.id IN ('9030070b-13e6-4a3b-867c-546418b8c9a8','007eaf5b-bacc-4510-900d-dd7675fbdb8e')
--  GROUP BY p.full_name;
