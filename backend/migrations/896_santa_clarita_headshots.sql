-- 896_santa_clarita_headshots.sql
-- Phase 143 / Plan 03 — Santa Clarita headshots (AUDIT-ONLY: apply via raw SQL, does NOT register
-- in supabase_migrations.schema_migrations; ledger MAX stays 895).
--
-- RESEAT context: McLean (-201394) & Miranda (-200980) already had scraped_no_license images at the
-- OLD storage path ({uuid}/default.png). Re-sourced fresh 600x750 press_use portraits from
-- santaclarita.gov, uploaded to the canonical politician_photos/{uuid}-headshot.jpg path. This file
-- UPDATEs their existing single image row (no INSERT — avoids duplicate rows).
-- Also: Weste (665693) image had an EMPTY license + old path -> re-sourced to press_use canonical.
--       Ayala (665689) image was already canonical+santaclarita.gov origin -> license upgraded to press_use.
--       Gibbs (665692) already clean press_use canonical (Plan 01 dedupe) -> untouched.
-- All processed: crop to 4:5 then resize 600x750 Lanczos q90; no superimposed text/graphics.

BEGIN;

-- McLean -> canonical url + press_use
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9476ec1c-9e60-4dae-b398-c81c63f6f670-headshot.jpg',
       photo_license = 'press_use', type = 'default'
 WHERE politician_id = '9476ec1c-9e60-4dae-b398-c81c63f6f670';
UPDATE essentials.politicians
   SET photo_origin_url = 'https://santaclarita.gov/city-council/wp-content/uploads/sites/39/2023/09/MarshaMclean.png'
 WHERE external_id = -201394 AND photo_origin_url IS NULL;

-- Miranda -> canonical url + press_use
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/069fc0f2-d1eb-4fac-828a-3d9030d4f2a9-headshot.jpg',
       photo_license = 'press_use', type = 'default'
 WHERE politician_id = '069fc0f2-d1eb-4fac-828a-3d9030d4f2a9';
UPDATE essentials.politicians
   SET photo_origin_url = 'https://santaclarita.gov/city-council/wp-content/uploads/sites/39/2023/09/BillMiranda.png'
 WHERE external_id = -200980 AND photo_origin_url IS NULL;

-- Weste -> re-sourced canonical url + press_use (was empty license + old path)
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6854ec39-d6e2-44c4-8c60-0d809234f935-headshot.jpg',
       photo_license = 'press_use', type = 'default'
 WHERE politician_id = '6854ec39-d6e2-44c4-8c60-0d809234f935';

-- Ayala -> license upgrade only (already canonical path + santaclarita.gov origin)
UPDATE essentials.politician_images
   SET photo_license = 'press_use'
 WHERE politician_id = '3dab8dca-2ce0-403b-8f4f-d6137e11731d'
   AND photo_license = 'scraped_no_license';

COMMIT;
