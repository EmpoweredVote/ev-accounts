-- 993_downey_headshots.sql
-- Phase 150 Wave 3 (DWNY-01): Downey headshots. AUDIT-ONLY — applied via raw SQL, NOT registered in
-- supabase_migrations.schema_migrations (ledger MAX stays 992). Idempotent.
--
-- All 5 current members' official portraits sourced by OPERATOR in-browser download from downeyca.org
-- (the site is WAF-403 to all curl — CivicPlus/CivicEngage behind Cloudflare WAF; RESEARCH §D-04).
-- Files staged at C:\tmp\govheadshots\Downey\ and identity-verified by operator against official site.
-- Each processed: crop to 4:5 FIRST (from top, preserving eyes ~1/3 from top) -> 600x750 Lanczos q90 JPEG
-- -> uploaded to Supabase Storage politician_photos/{uuid}-headshot.jpg (x-upsert, all HTTP 200).
--
-- Roster note: Migration 992 (STRUCTURAL, registered) corrected the rotational Mayor:
--   Claudia Frometa (D4, ext_id 675361) IS the current Mayor (not Sosa as originally researched).
--   Sosa (D2, ext_id 675353) is Councilmember; Ortiz (D1, ext_id -700991) is Mayor Pro Tem.
--   This affects titles only, not headshot identity — operator-verified filenames match per-person.
--
-- Source quality:
--   Frometa  (4967617f) 900x1145  → good quality
--   Pemberton(71c35909) 900x1146  → good quality
--   Sosa     (92d68971) 1920x2443 → excellent high-res source
--   Ortiz    (13dc32dd) 900x1146  → good quality (confirmed NOT Timothy Horn, prior D1 occupant)
--   Trujillo (06b1dae6) 151x189   → low-res (smallest available official source; upscaled Lanczos)
--
-- All are the correct verified person, no superimposed text/graphics.
-- photo_license='press_use' for all — sourced from official city council pages (downeyca.org),
-- which are government-produced press portraits.
--
-- On-disk counter stays 992 (this file does NOT register in schema_migrations).

-- Ortiz (D1, ext_id -700991, NEW member from Plan 02): INSERT (was 0 images).
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT p.id,
  'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/13dc32dd-fac5-440d-9f10-f1f1892acf68-headshot.jpg',
  'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -700991
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id=p.id AND pi.type='default');

-- Sosa (D2/Councilmember, ext_id 675353): INSERT (was 0 images).
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT p.id,
  'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/92d68971-8cc2-480b-8e29-9938f7a280f1-headshot.jpg',
  'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = 675353
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id=p.id AND pi.type='default');

-- Pemberton (D3, ext_id 675360): INSERT (was 0 images).
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT p.id,
  'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/71c35909-e5b5-40ca-883f-21af5c287b5e-headshot.jpg',
  'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = 675360
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id=p.id AND pi.type='default');

-- Frometa (D4/Mayor, ext_id 675361): INSERT (was 0 images).
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT p.id,
  'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/4967617f-5919-4816-8661-a675f05e8b66-headshot.jpg',
  'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = 675361
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id=p.id AND pi.type='default');

-- Trujillo (D5, ext_id -201200): INSERT (was 0 images).
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT p.id,
  'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/06b1dae6-5fcf-4a1f-ba89-d06cbae5c19d-headshot.jpg',
  'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id = -201200
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id=p.id AND pi.type='default');

-- photo_origin_url -> official downeyca.org council page for each member.
UPDATE essentials.politicians SET photo_origin_url='https://www.downeyca.org/our-city/mayor-city-council/horacio-ortiz-district-1'
  WHERE external_id = -700991 AND photo_origin_url IS DISTINCT FROM 'https://www.downeyca.org/our-city/mayor-city-council/horacio-ortiz-district-1';
UPDATE essentials.politicians SET photo_origin_url='https://www.downeyca.org/our-city/mayor-city-council/hector-sosa-district-2'
  WHERE external_id = 675353 AND photo_origin_url IS DISTINCT FROM 'https://www.downeyca.org/our-city/mayor-city-council/hector-sosa-district-2';
UPDATE essentials.politicians SET photo_origin_url='https://www.downeyca.org/our-city/mayor-city-council/dorothy-pemberton-district-3'
  WHERE external_id = 675360 AND photo_origin_url IS DISTINCT FROM 'https://www.downeyca.org/our-city/mayor-city-council/dorothy-pemberton-district-3';
UPDATE essentials.politicians SET photo_origin_url='https://www.downeyca.org/our-city/mayor-city-council/claudia-frometa-district-4'
  WHERE external_id = 675361 AND photo_origin_url IS DISTINCT FROM 'https://www.downeyca.org/our-city/mayor-city-council/claudia-frometa-district-4';
UPDATE essentials.politicians SET photo_origin_url='https://www.downeyca.org/our-city/mayor-city-council/mario-trujillo-district-5'
  WHERE external_id = -201200 AND photo_origin_url IS DISTINCT FROM 'https://www.downeyca.org/our-city/mayor-city-council/mario-trujillo-district-5';

-- ============================ POST-VERIFICATION (audit) =============================
-- Full-roster image coverage: each of the 5 current members should have n_default=1.
-- SELECT p.external_id, p.full_name, COUNT(pi.id) FILTER (WHERE pi.type='default') AS n_default,
--        MAX(pi.url) AS url
--   FROM essentials.politicians p
--   LEFT JOIN essentials.politician_images pi ON pi.politician_id=p.id
--  WHERE p.external_id IN (-700991, 675353, 675360, 675361, -201200)
--  GROUP BY p.external_id, p.full_name ORDER BY p.external_id;
-- -- each n_default = 1
--
-- SELECT MAX(version) FROM supabase_migrations.schema_migrations;  -- unchanged, stays 992
