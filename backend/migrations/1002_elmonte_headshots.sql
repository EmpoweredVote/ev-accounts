-- 1002_elmonte_headshots.sql
-- Phase 151 Wave 3 (ELMN-01): El Monte headshots. AUDIT-ONLY — applied via raw SQL, NOT registered in
-- supabase_migrations.schema_migrations (ledger MAX stays 1001). Idempotent.
--
-- All 7 current members' official portraits sourced by DIRECT curl from ci.el-monte.ca.us (NO-WAF; all
-- documentIds HTTP 200). Each processed: 4:5 crop FIRST (288x366 official portrait -> 288x360) -> 600x750
-- Lanczos q90 JPEG -> uploaded to Supabase Storage politician_photos/{uuid}-headshot.jpg (x-upsert, public 200).
-- Each visually verified: correct single-person professional portrait, NO superimposed text/graphics over the
-- face, eyes ~1/3 from top. Cortez (D6, NEW from Plan 02) was greenfield -> INSERT; the other 6 had a
-- pre-existing scraped_no_license row at a non-canonical path -> re-sourced + re-cropped + UPDATEd to the
-- canonical {uuid}-headshot.jpg path with press_use (matching the Pasadena 948 standardization).
--
-- documentId sources (https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=NNNN):
--   7431 Crippen-Thomas(D1) · 7432 Herrera(D2) · 7433 Ruedas(D3) · 7430 Longoria(D4) ·
--   7429 Galvan(D5) · 7435 Cortez(D6) · 7434 Ancona(Mayor)
--
-- Each member ends with exactly ONE type='default' press_use row at canonical {uuid}-headshot.jpg.

-- Cortez (-701001): NEW (was 0 images) — guarded INSERT.
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT p.id,
  'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/aecc3037-963f-428a-b7cf-fe0cde67142e-headshot.jpg',
  'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -701001
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id=p.id AND pi.type='default');

-- The other 6: point their existing type='default' row at the canonical path + press_use license.
UPDATE essentials.politician_images pi
   SET url='https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/bb21e688-3264-4237-beda-e748db65384a-headshot.jpg',
       photo_license='press_use'
 WHERE pi.type='default' AND pi.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-201202); -- Crippen-Thomas D1
UPDATE essentials.politician_images pi
   SET url='https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/e39b0a67-2447-4d25-b207-6a6c20307d94-headshot.jpg',
       photo_license='press_use'
 WHERE pi.type='default' AND pi.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-201204); -- Herrera D2
UPDATE essentials.politician_images pi
   SET url='https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/0738714b-e2e0-42d6-b594-2edfa28736b5-headshot.jpg',
       photo_license='press_use'
 WHERE pi.type='default' AND pi.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=657390);  -- Ruedas D3
UPDATE essentials.politician_images pi
   SET url='https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/18dbc5bc-999e-4e75-b602-80c0ca8202ee-headshot.jpg',
       photo_license='press_use'
 WHERE pi.type='default' AND pi.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=657386);  -- Longoria D4
UPDATE essentials.politician_images pi
   SET url='https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/f034f7ef-2aef-43fa-8d06-1f6902705dc4-headshot.jpg',
       photo_license='press_use'
 WHERE pi.type='default' AND pi.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-201203); -- Galvan D5
UPDATE essentials.politician_images pi
   SET url='https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/c7f76380-249c-436b-824c-ba44ff496c40-headshot.jpg',
       photo_license='press_use'
 WHERE pi.type='default' AND pi.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-200669); -- Ancona Mayor

-- photo_origin_url -> the documentId source URL for each member (the source actually used; guarded).
UPDATE essentials.politicians SET photo_origin_url='https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=7431' WHERE external_id=-201202 AND photo_origin_url IS DISTINCT FROM 'https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=7431';
UPDATE essentials.politicians SET photo_origin_url='https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=7432' WHERE external_id=-201204 AND photo_origin_url IS DISTINCT FROM 'https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=7432';
UPDATE essentials.politicians SET photo_origin_url='https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=7433' WHERE external_id=657390  AND photo_origin_url IS DISTINCT FROM 'https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=7433';
UPDATE essentials.politicians SET photo_origin_url='https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=7430' WHERE external_id=657386  AND photo_origin_url IS DISTINCT FROM 'https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=7430';
UPDATE essentials.politicians SET photo_origin_url='https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=7429' WHERE external_id=-201203 AND photo_origin_url IS DISTINCT FROM 'https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=7429';
UPDATE essentials.politicians SET photo_origin_url='https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=7435' WHERE external_id=-701001 AND photo_origin_url IS DISTINCT FROM 'https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=7435';
UPDATE essentials.politicians SET photo_origin_url='https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=7434' WHERE external_id=-200669 AND photo_origin_url IS DISTINCT FROM 'https://www.ci.el-monte.ca.us/ImageRepository/Document?documentId=7434';

-- ============================ POST-VERIFICATION (audit) =============================
-- SELECT p.external_id, p.last_name, COUNT(pi.*) FILTER (WHERE pi.type='default') AS n_default
--   FROM essentials.politicians p LEFT JOIN essentials.politician_images pi ON pi.politician_id=p.id
--  WHERE p.external_id IN (-201202,-201204,657390,657386,-201203,-701001,-200669)
--  GROUP BY p.external_id, p.last_name;  -- each n_default = 1
-- SELECT MAX(version) FROM supabase_migrations.schema_migrations;  -- unchanged, stays 1001
