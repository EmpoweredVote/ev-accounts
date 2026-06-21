-- 948_pasadena_headshots.sql
-- Phase 149 Wave 3 (PASA-01): Pasadena headshots. AUDIT-ONLY — applied via raw SQL, NOT registered in
-- supabase_migrations.schema_migrations (ledger MAX stays 947). Idempotent.
--
-- All 8 current members' official portraits sourced by DIRECT curl from cityofpasadena.net (NO-WAF via curl;
-- urllib was 403). Each processed: 4:5 crop FIRST (upper-third anchored) -> 600x750 Lanczos q90 JPEG ->
-- uploaded to Supabase Storage politician_photos/{uuid}-headshot.jpg (x-upsert). Storage objects verified 200.
--
-- Source resolution / quality (see 149-03-SUMMARY for the checkpoint quality notes):
--   GOOD source res: Gordo (682x1024), Cole (1025x990, confirms Rick Cole not Williams), Rivas (650x850, NEW).
--   LOW-RES city max (city publishes only thumbnails; upscaled to 600x750): Hampton 240x320, Jones 150x200,
--     Madison 150x200, Lyon 280x400, Masuda 150x200 (city source). Accepted as the authoritative official
--     portrait per prior-phase precedent (Layton/Ogden low-res official accepted); flagged at the checkpoint.
--
-- Each member ends with exactly ONE type='default' press_use row at canonical {uuid}-headshot.jpg.

-- Rivas (-700150): NEW (was 0 images).
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT p.id,
  'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/07147263-4b98-415e-828d-70b5916946a9-headshot.jpg',
  'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -700150
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id=p.id AND pi.type='default');

-- The other 7: point their existing type='default' row at the canonical path + press_use license.
UPDATE essentials.politician_images pi
   SET url='https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/447ef220-cb9e-4ade-aba8-9dea87ed9931-headshot.jpg',
       photo_license='press_use'
 WHERE pi.type='default' AND pi.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-200901); -- Gordo
UPDATE essentials.politician_images pi
   SET url='https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/f7826942-64bb-41bf-9588-407a2bc11e31-headshot.jpg',
       photo_license='press_use'
 WHERE pi.type='default' AND pi.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-201094); -- Hampton
UPDATE essentials.politician_images pi
   SET url='https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/9f07a6d3-ecce-4105-be1d-23fb69d288c8-headshot.jpg',
       photo_license='press_use'
 WHERE pi.type='default' AND pi.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=657577);  -- Cole
UPDATE essentials.politician_images pi
   SET url='https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/59b781ad-22f8-46c9-b536-e19971e47fc1-headshot.jpg',
       photo_license='press_use'
 WHERE pi.type='default' AND pi.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=657578);  -- Jones
UPDATE essentials.politician_images pi
   SET url='https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/39426238-e6c2-47d3-bc54-93b8559c9f6b-headshot.jpg',
       photo_license='press_use'
 WHERE pi.type='default' AND pi.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=657579);  -- Masuda
UPDATE essentials.politician_images pi
   SET url='https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/e2ce84d2-ee0b-4851-b1d8-168a2f54a82b-headshot.jpg',
       photo_license='press_use'
 WHERE pi.type='default' AND pi.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=657581);  -- Madison
UPDATE essentials.politician_images pi
   SET url='https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/0d3f6eaf-8f8e-4ec3-a2e7-a8e67487450e-headshot.jpg',
       photo_license='press_use'
 WHERE pi.type='default' AND pi.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=657582);  -- Lyon

-- photo_origin_url -> the official district/mayor source page for each member.
UPDATE essentials.politicians SET photo_origin_url='https://www.cityofpasadena.net/mayor/'     WHERE external_id=-200901 AND photo_origin_url IS DISTINCT FROM 'https://www.cityofpasadena.net/mayor/';
UPDATE essentials.politicians SET photo_origin_url='https://www.cityofpasadena.net/district1/' WHERE external_id=-201094 AND photo_origin_url IS DISTINCT FROM 'https://www.cityofpasadena.net/district1/';
UPDATE essentials.politicians SET photo_origin_url='https://www.cityofpasadena.net/district2/' WHERE external_id=657577  AND photo_origin_url IS DISTINCT FROM 'https://www.cityofpasadena.net/district2/';
UPDATE essentials.politicians SET photo_origin_url='https://www.cityofpasadena.net/district3/' WHERE external_id=657578  AND photo_origin_url IS DISTINCT FROM 'https://www.cityofpasadena.net/district3/';
UPDATE essentials.politicians SET photo_origin_url='https://www.cityofpasadena.net/district4/' WHERE external_id=657579  AND photo_origin_url IS DISTINCT FROM 'https://www.cityofpasadena.net/district4/';
UPDATE essentials.politicians SET photo_origin_url='https://www.cityofpasadena.net/district5/' WHERE external_id=-700150 AND photo_origin_url IS DISTINCT FROM 'https://www.cityofpasadena.net/district5/';
UPDATE essentials.politicians SET photo_origin_url='https://www.cityofpasadena.net/district6/' WHERE external_id=657581  AND photo_origin_url IS DISTINCT FROM 'https://www.cityofpasadena.net/district6/';
UPDATE essentials.politicians SET photo_origin_url='https://www.cityofpasadena.net/district7/' WHERE external_id=657582  AND photo_origin_url IS DISTINCT FROM 'https://www.cityofpasadena.net/district7/';

-- ============================ POST-VERIFICATION (audit) =============================
-- SELECT p.external_id, p.last_name, COUNT(pi.*) FILTER (WHERE pi.type='default') AS n_default, MAX(pi.url)
--   FROM essentials.politicians p LEFT JOIN essentials.politician_images pi ON pi.politician_id=p.id
--  WHERE p.external_id IN (-200901,-201094,657577,657578,657579,-700150,657581,657582)
--  GROUP BY p.external_id, p.last_name ORDER BY p.external_id;  -- each n_default = 1
-- SELECT MAX(version) FROM supabase_migrations.schema_migrations;  -- unchanged, stays 947
