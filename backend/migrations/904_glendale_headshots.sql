-- 904_glendale_headshots.sql
-- Phase 144 / Plan 03 — Glendale headshots (AUDIT-ONLY: apply via raw SQL, does NOT register in
-- supabase_migrations.schema_migrations; ledger MAX stays 903).
--
-- Image state pre-wave (DB-verified 2026-06-19):
--   Kassakhian (686339) 1 cc_by_sa_4.0 canonical {uuid}-headshot.jpg            -> AUDIT only (kept)
--   Asatryan   (686337) 1 cc_by_sa_4.0 canonical {uuid}/default.jpeg           -> AUDIT only (kept)
--   Bartrosouf (-700101 / 66cd60ba) 1 press_use canonical 66cd60ba-headshot.jpg -> already covered (kept)
--   Gharpetian (686336 / a223d51d) 1 scraped_no_license, OLD la_county/cities/glendale path -> RE-SOURCE
--   Brotman    (686340 / 9db24324) 0 images                                     -> SOURCE (new)
--   Najarian   (-700100) 0 images, retired                                      -> SKIPPED (not active)
--
-- glendaleca.gov is Akamai/WAF-blocked (403 to curl + WebFetch). Sourcing resolved WITHOUT the blocked
-- HTML pages:
--   * Gharpetian: the official city studio portrait was already in our Storage (old scraped path,
--     1280x1600). Re-processed in place (crop 4:5 -> 600x750 Lanczos q90) to the canonical
--     {uuid}-headshot.jpg path; license upgraded scraped_no_license -> press_use (official city portrait).
--   * Brotman: sourced from gaor.org candidate-interview headshot (same source family as Bartrosouf's
--     existing press_use image), processed to 600x750. Visually verified correct person, no overlays.
-- All processed: crop to 4:5 FIRST then resize 600x750 Lanczos q90; no superimposed text/graphics; not stretched.

BEGIN;

-- Brotman (686340 / 9db24324) — NEW image (0 before). Guarded NOT EXISTS so re-apply is a no-op.
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '9db24324-3d82-4c2b-8404-078a53708447',
       'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/9db24324-3d82-4c2b-8404-078a53708447-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
   WHERE politician_id = '9db24324-3d82-4c2b-8404-078a53708447' AND type = 'default'
);
UPDATE essentials.politicians
   SET photo_origin_url = 'https://www.gaor.org/glendales-2026-city-council-candidate-interviews/'
 WHERE external_id = 686340 AND (photo_origin_url IS NULL OR photo_origin_url = 'searched:no_results');

-- Gharpetian (686336 / a223d51d) — RE-SOURCE in place off scraped_no_license / old la_county path.
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/a223d51d-7077-4d9d-98b0-bcfafabbbc71-headshot.jpg',
       photo_license = 'press_use', type = 'default'
 WHERE politician_id = 'a223d51d-7077-4d9d-98b0-bcfafabbbc71';
UPDATE essentials.politicians
   SET photo_origin_url = 'https://www.glendaleca.gov/government/city-council/councilmember-vartan-gharpetian'
 WHERE external_id = 686336;

COMMIT;

-- ============================================================================
-- POST-VERIFICATION (run after apply) — AUDIT-ONLY, ledger MUST stay 903
-- ============================================================================
-- Brotman + Gharpetian each exactly one type='default' press_use row:
--   SELECT p.external_id, COUNT(*) FILTER (WHERE pi.type='default') FROM essentials.politicians p
--     LEFT JOIN essentials.politician_images pi ON pi.politician_id=p.id
--     WHERE p.external_id IN (686336,686340) GROUP BY p.external_id;
-- Full-roster coverage (5 current officials) — only documented gaps may be imageless:
--   SELECT p.external_id, p.full_name, COUNT(pi.id) FILTER (WHERE pi.type='default') AS imgs
--     FROM essentials.politicians p LEFT JOIN essentials.politician_images pi ON pi.politician_id=p.id
--     WHERE p.external_id IN (686339,686337,686336,686340,-700101) GROUP BY 1,2;
-- No scraped_no_license remaining for current Glendale roster.
-- MAX(version) in schema_migrations unchanged (903).
