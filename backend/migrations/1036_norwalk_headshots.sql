-- 1036_norwalk_headshots.sql
-- Phase 155 Wave 3 (NRWK-01): verify-and-fix all 5 Norwalk official headshots.
-- AUDIT-ONLY migration — raw SQL, NOT registered in supabase_migrations.schema_migrations.
-- Ledger stays at 1035. Idempotent (IS DISTINCT FROM guards).
--
-- Source: norwalkca.gov Revize CMS — NO WAF (standard curl -L, HTTP 200, no special UA).
-- All 5 had exactly 1 existing default image entering this wave -> all 5 are UPDATEs (0 greenfield INSERT).
--   - Ayala (5e8bcf17) + Perez (3ed36508): already canonical {uuid}-headshot.jpg path (press_use); photo_origin_url
--     pointed at norwalk.org -> re-pointed to norwalkca.gov canonical (Pitfall 6).
--   - Valencia (ba647863), Rios (bd64253b), Ramirez (e3b9af1b): were on the OLD scraped path
--     (politician_photos/la_county/cities/norwalk/{name}.jpg, scraped_no_license, NULL origin) -> migrated to
--     canonical {uuid}-headshot.jpg + press_use.
-- GOTCHAS handled (RESEARCH §Headshots / §Common Pitfalls):
--   - Ramirez: old DB image used 638169002126970000.jpg which 404s -> REPLACED with corrected
--     'RR - Digital Images - Copy.jpg' portrait (verified HTTP 200).
--   - Rios: folder name has a DOUBLE SPACE ('Margarita  Rios') -> photo_origin_url uses %20%20.
-- All 5 processed: 4:5 crop FIRST -> 600x750 Lanczos q90; uploaded to
--   politician_photos/{uuid}-headshot.jpg (x-upsert). Wrong-person + no-graphics guard passed
--   (each sourced from its own named norwalkca.gov folder; visually inspected).
-- OUT OF SCOPE (untouched): Norwalk-La Mirada Unified School District gov d4f9a7fa.

BEGIN;

-- Canonical image rows (all 5 UPDATE the existing default row).
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3ed36508-9ae9-41af-aaba-e5e39bb87aa7-headshot.jpg',
       photo_license = 'press_use'
 WHERE politician_id = '3ed36508-9ae9-41af-aaba-e5e39bb87aa7' AND type = 'default'; -- Jennifer Perez

UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bd64253b-0bd1-4b9f-85b1-76180c760d07-headshot.jpg',
       photo_license = 'press_use'
 WHERE politician_id = 'bd64253b-0bd1-4b9f-85b1-76180c760d07' AND type = 'default'; -- Margarita L. Rios

UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5e8bcf17-3a4d-4614-a71c-c4ea8396f7cb-headshot.jpg',
       photo_license = 'press_use'
 WHERE politician_id = '5e8bcf17-3a4d-4614-a71c-c4ea8396f7cb' AND type = 'default'; -- Tony Ayala

UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e3b9af1b-3704-4bc5-a6ef-ab1f814bd29d-headshot.jpg',
       photo_license = 'press_use'
 WHERE politician_id = 'e3b9af1b-3704-4bc5-a6ef-ab1f814bd29d' AND type = 'default'; -- Rick Ramirez (REPLACED broken 638169... URL)

UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ba647863-25fb-4ccf-9cb0-5a1c912d1b27-headshot.jpg',
       photo_license = 'press_use'
 WHERE politician_id = 'ba647863-25fb-4ccf-9cb0-5a1c912d1b27' AND type = 'default'; -- Ana Valencia

-- photo_origin_url backfill on essentials.politicians (canonical norwalkca.gov source URLs).
UPDATE essentials.politicians SET photo_origin_url = 'https://www.norwalkca.gov/Image/Government/Mayor%20And%20City%20Council/Jennifer%20Perez/JP%20-%20Digital%20Images%20-%20Copy.jpg?t=202512101807300'
 WHERE external_id = 666845  AND photo_origin_url IS DISTINCT FROM 'https://www.norwalkca.gov/Image/Government/Mayor%20And%20City%20Council/Jennifer%20Perez/JP%20-%20Digital%20Images%20-%20Copy.jpg?t=202512101807300';

UPDATE essentials.politicians SET photo_origin_url = 'https://www.norwalkca.gov/Image/Government/Mayor%20And%20City%20Council/Margarita%20%20Rios/MR%20-%20Digital%20Images%20-%20Copy.jpg?t=202512101808020'
 WHERE external_id = -201328 AND photo_origin_url IS DISTINCT FROM 'https://www.norwalkca.gov/Image/Government/Mayor%20And%20City%20Council/Margarita%20%20Rios/MR%20-%20Digital%20Images%20-%20Copy.jpg?t=202512101808020'; -- %20%20 double-space

UPDATE essentials.politicians SET photo_origin_url = 'https://www.norwalkca.gov/Image/Government/Mayor%20And%20City%20Council/Tony%20Ayala/TA%20-%20Digital%20Images%20-%20Copy.jpg?t=202508201329270'
 WHERE external_id = -200876 AND photo_origin_url IS DISTINCT FROM 'https://www.norwalkca.gov/Image/Government/Mayor%20And%20City%20Council/Tony%20Ayala/TA%20-%20Digital%20Images%20-%20Copy.jpg?t=202508201329270';

UPDATE essentials.politicians SET photo_origin_url = 'https://www.norwalkca.gov/Image/Government/Mayor%20And%20City%20Council/Rick%20Ramirez/RR%20-%20Digital%20Images%20-%20Copy.jpg?t=202508201332230'
 WHERE external_id = -201327 AND photo_origin_url IS DISTINCT FROM 'https://www.norwalkca.gov/Image/Government/Mayor%20And%20City%20Council/Rick%20Ramirez/RR%20-%20Digital%20Images%20-%20Copy.jpg?t=202508201332230'; -- corrected (old 638169... 404s)

UPDATE essentials.politicians SET photo_origin_url = 'https://www.norwalkca.gov/Image/Government/Mayor%20And%20City%20Council/Ana%20Valencia/AV%20-%20Digital%20Images%20-%20Copy.jpg?t=202508201340330'
 WHERE external_id = -201329 AND photo_origin_url IS DISTINCT FROM 'https://www.norwalkca.gov/Image/Government/Mayor%20And%20City%20Council/Ana%20Valencia/AV%20-%20Digital%20Images%20-%20Copy.jpg?t=202508201340330';

COMMIT;

-- ============================ POST-VERIFICATION (audit-only; ledger UNCHANGED at 1035) =============================
-- 1. each official exactly one type='default' image at canonical {uuid}-headshot.jpg path:
--    SELECT p.external_id, COUNT(pi.*) FILTER (WHERE pi.type='default') n
--      FROM essentials.politicians p LEFT JOIN essentials.politician_images pi ON pi.politician_id=p.id
--      WHERE p.external_id IN (666845,-201328,-200876,-201327,-201329) GROUP BY p.external_id;  -> each 1
-- 2. photo_origin_url set on all 5; Rios contains %20%20; Ramirez references RR%20-%20Digital (not 638169):
--    SELECT external_id, photo_origin_url FROM essentials.politicians WHERE external_id IN (666845,-201328,-200876,-201327,-201329);
-- 3. all 5 images press_use + canonical host:
--    SELECT p.external_id, pi.url, pi.photo_license FROM essentials.politician_images pi
--      JOIN essentials.politicians p ON p.id=pi.politician_id WHERE p.external_id IN (666845,-201328,-200876,-201327,-201329);
-- 4. ledger unchanged: SELECT MAX(version::int) FROM supabase_migrations.schema_migrations;  -> 1035
