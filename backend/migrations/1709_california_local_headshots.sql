-- 1709_california_local_headshots.sql
--
-- Portraits for 47 California county, city and appellate officials. Top governments:
-- California Courts 14, Alameda County 5, Riverside County 4, San Diego County 4, La Habra Heights 3, La Puente 3, San Joaquin County 3, Placer County 2, San Fernando 2, South Pasadena 2, Walnut 2, Merced County 1.
--
-- CALIFORNIA'S 1,060 BACKLOG ROWS ARE NOT 1,060 HEADSHOTS.
--   468 (44%) are LA County Superior Court judges. The court publishes a judicial-officer SEARCH
--       FORM — assignments, courtrooms, phone numbers — and no portraits; its directory endpoint
--       answers 503, and Ballotpedia either has no page or serves the "Submit Photo" placeholder.
--       Each also carries a self-named district row ("LA County Superior Court - <their name>"),
--       which is why they inflate the count so heavily. Ruled out on evidence, not skipped.
--   377 are school-board members spread across ~120 separate districts — a long tail, deferred.
--   215 county, city and appellate officials are the tractable block; 47 of them are here.
-- APPELLATE justices are the opposite of Superior Court judges: the CA Supreme Court and 2nd
-- District DO publish portraits, and 20 of those 31 are in this batch (one at 3511x4469).
--
-- Seeds cost nothing: 48 of the 51 governments already had verified official URLs stored from
-- the earlier CA URL-rot work (migrations 1670-1684).
--
-- 🔴 THE CONTACT SHEET CAUGHT A WRONG PERSON. Steve Croft (Lakewood) resolved to a pencil
-- sketch whose filename is john-sanford-todd.jpg — a different man. It passed the name, size and
-- aspect checks because the match came from surrounding card text. Also rejected: an empty
-- courtroom bench (Kelli M. Evans), a palm-tree sunset (Shaunna Elias), and a casual snapshot of
-- a man holding a dog (John P. Wiley Jr.).
--
-- Chris's calls on review: SKIP the 4 monochrome judicial portraits (Rothschild, Willhite,
-- Tangeman, Grimes) per the standing no-B&W rule, and zoom the 3 circle-cropped La Puente
-- councillors so the ring falls outside the frame. That zoom is geometric, not eyeballed: a 4:5
-- box inscribed in a circle of radius R is at most 2R/sqrt(1+1.25^2) wide, and it is taken at
-- 0.90 of that — at 1.00 the corners touch the circle exactly and antialiasing leaves a sliver
-- that no corner threshold reliably catches. Steve J. Bestolarides was re-cropped tighter from a
-- wide office shot.
--
-- Sets BOTH photo_custom_url and photo_origin_url: the read path is
-- COALESCE(photo_custom_url, photo_origin_url, ''), so writing only the origin renders broken.
--
-- Idempotent: re-running inserts nothing and updates nothing.

BEGIN;

CREATE TEMP TABLE _ca_headshots (
  politician_id uuid PRIMARY KEY,
  bucket_url    text NOT NULL,
  source_page   text NOT NULL,
  license       text NOT NULL
) ON COMMIT DROP;

INSERT INTO _ca_headshots (politician_id, bucket_url, source_page, license) VALUES
  ('3334084d-8053-48c8-b446-0bf48084215d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3334084d-8053-48c8-b446-0bf48084215d-headshot.jpg', 'https://www.alamedacountyca.gov/government/elected.htm', 'press_use'),
  ('ae8275ba-b5cd-49ac-befd-23f7100859b0'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ae8275ba-b5cd-49ac-befd-23f7100859b0-headshot.jpg', 'https://www.alamedacountyca.gov/government/elected.htm', 'press_use'),
  ('b84f889b-e312-4b3e-9fb8-e8fcebfb4ef3'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b84f889b-e312-4b3e-9fb8-e8fcebfb4ef3-headshot.jpg', 'https://www.alamedacountyca.gov/government/elected.htm', 'press_use'),
  ('9473be9b-4065-4539-88ce-56d94199cdf5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9473be9b-4065-4539-88ce-56d94199cdf5-headshot.jpg', 'https://www.alamedacountyca.gov/government/elected.htm', 'press_use'),
  ('bc838ffd-2a3a-4e16-afa5-e7e0a9d1c1ab'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bc838ffd-2a3a-4e16-afa5-e7e0a9d1c1ab-headshot.jpg', 'https://www.alamedacountyca.gov/government/elected.htm', 'press_use'),
  ('c80e1343-70e4-4371-ade4-40f276dd3e25'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c80e1343-70e4-4371-ade4-40f276dd3e25-headshot.jpg', 'https://www.lhhcity.org/155', 'press_use'),
  ('aa4fea2e-80a3-42e9-b94f-e9fc5e0b966f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/aa4fea2e-80a3-42e9-b94f-e9fc5e0b966f-headshot.jpg', 'https://www.lhhcity.org/155', 'press_use'),
  ('8d820dc7-0935-44ee-a14d-fb4e3502eba1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8d820dc7-0935-44ee-a14d-fb4e3502eba1-headshot.jpg', 'https://www.lhhcity.org/155', 'press_use'),
  ('dc7f4747-abc2-4a1a-8d65-c1d4d5b609d2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dc7f4747-abc2-4a1a-8d65-c1d4d5b609d2-headshot.jpg', 'https://lapuente.org/city-council/', 'press_use'),
  ('52de992a-feb1-4162-bbf2-378affd2d375'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/52de992a-feb1-4162-bbf2-378affd2d375-headshot.jpg', 'https://lapuente.org/city-council/', 'press_use'),
  ('280bf705-d019-4a3f-97e6-88921486faf2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/280bf705-d019-4a3f-97e6-88921486faf2-headshot.jpg', 'https://lapuente.org/city-council/', 'press_use'),
  ('f36862c8-4675-4bf5-97b1-23984e7a8f0a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f36862c8-4675-4bf5-97b1-23984e7a8f0a-headshot.jpg', 'https://www.countyofmerced.com/directory.aspx', 'press_use'),
  ('06bf52a6-c8c0-4237-94c6-c160842e1154'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/06bf52a6-c8c0-4237-94c6-c160842e1154-headshot.jpg', 'https://www.placer.ca.gov/Sheriff', 'press_use'),
  ('1115f169-c094-4538-a1f4-2e775b6c5174'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1115f169-c094-4538-a1f4-2e775b6c5174-headshot.jpg', 'https://www.placer.ca.gov/2119/Auditor-Controller', 'press_use'),
  ('c9bb3f1c-378f-4c21-bf98-05694703993d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c9bb3f1c-378f-4c21-bf98-05694703993d-headshot.jpg', 'https://rivco.gov/elected-officials-compensation', 'press_use'),
  ('039d466c-2a58-4c33-b514-f84c58e18bfa'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/039d466c-2a58-4c33-b514-f84c58e18bfa-headshot.jpg', 'https://rivco.gov/elected-officials-compensation', 'press_use'),
  ('27ab7173-ce29-43f7-a58b-0fc3353257ac'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/27ab7173-ce29-43f7-a58b-0fc3353257ac-headshot.jpg', 'https://rivco.gov/elected-officials-compensation', 'press_use'),
  ('4f7f4ace-fd33-4dca-82c6-7eb6712541e9'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4f7f4ace-fd33-4dca-82c6-7eb6712541e9-headshot.jpg', 'https://rivco.gov/elected-officials-compensation', 'press_use'),
  ('a1a0c923-ac2c-4e7e-a64e-43fc94837a80'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a1a0c923-ac2c-4e7e-a64e-43fc94837a80-headshot.jpg', 'https://www.sandiegocounty.gov/', 'press_use'),
  ('4377517a-9030-4e9a-bb57-703c6e300834'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4377517a-9030-4e9a-bb57-703c6e300834-headshot.jpg', 'https://www.sandiegocounty.gov/', 'press_use'),
  ('0cd39846-7134-42cc-906f-f07719803a79'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0cd39846-7134-42cc-906f-f07719803a79-headshot.jpg', 'https://www.sandiegocounty.gov/', 'press_use'),
  ('dafebf34-3dc5-40cf-ad4c-bc38bd3d18f4'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dafebf34-3dc5-40cf-ad4c-bc38bd3d18f4-headshot.jpg', 'https://www.sandiegocounty.gov/', 'press_use'),
  ('31f96a2e-1719-40dd-a1e1-c60d42f437f5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/31f96a2e-1719-40dd-a1e1-c60d42f437f5-headshot.jpg', 'https://www.sanjoaquin.gov/department/assessor', 'press_use'),
  ('5a579f53-65f9-4307-b4fc-800fb865eab3'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5a579f53-65f9-4307-b4fc-800fb865eab3-headshot.jpg', 'https://www.sanjoaquin.gov/department/aud', 'press_use'),
  ('beb26f1f-b291-4622-a39c-34cc1139dcd7'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/beb26f1f-b291-4622-a39c-34cc1139dcd7-headshot.jpg', 'https://www.sanjoaquin.gov/department/da', 'press_use'),
  ('25251ac1-2336-417e-bde4-f870cb0ca727'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/25251ac1-2336-417e-bde4-f870cb0ca727-headshot.jpg', 'https://supreme.courts.ca.gov/about-court/justices-court', 'press_use'),
  ('852fc897-7f9a-414d-8605-91c2ff339c4d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/852fc897-7f9a-414d-8605-91c2ff339c4d-headshot.jpg', 'https://supreme.courts.ca.gov/about-court/justices-court/associate-justice-goodwin-h-liu', 'press_use'),
  ('ab53c057-c484-401d-8d04-30fcbfdd2760'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ab53c057-c484-401d-8d04-30fcbfdd2760-headshot.jpg', 'https://supreme.courts.ca.gov/about-court/justices-court/associate-justice-leondra-r-kruger', 'press_use'),
  ('66141f16-e092-4872-9ed5-25cc72a07f06'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/66141f16-e092-4872-9ed5-25cc72a07f06-headshot.jpg', 'https://appellate.courts.ca.gov/district-courts/2dca/justices', 'press_use'),
  ('3db44ae0-70c3-40a9-ab5e-07806d3b178f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3db44ae0-70c3-40a9-ab5e-07806d3b178f-headshot.jpg', 'https://appellate.courts.ca.gov/district-courts/2dca/justices', 'press_use'),
  ('75a5db19-7c54-4293-a9ef-7627fbf9b87c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/75a5db19-7c54-4293-a9ef-7627fbf9b87c-headshot.jpg', 'https://appellate.courts.ca.gov/district-courts/2dca/justices', 'press_use'),
  ('c1587106-2ebb-4760-afc7-07e910c58128'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c1587106-2ebb-4760-afc7-07e910c58128-headshot.jpg', 'https://appellate.courts.ca.gov/district-courts/2dca/justices', 'press_use'),
  ('49492962-6351-400a-9ea2-53a8f045d77b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/49492962-6351-400a-9ea2-53a8f045d77b-headshot.jpg', 'https://appellate.courts.ca.gov/district-courts/2dca/justices', 'press_use'),
  ('8517ecf3-1173-48e1-a340-f07eaf0a6896'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8517ecf3-1173-48e1-a340-f07eaf0a6896-headshot.jpg', 'https://appellate.courts.ca.gov/district-courts/2dca/justices', 'press_use'),
  ('1791ad7d-a813-49af-8c50-1711b5b738bd'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1791ad7d-a813-49af-8c50-1711b5b738bd-headshot.jpg', 'https://appellate.courts.ca.gov/district-courts/2dca/justices/former-justices', 'press_use'),
  ('92784a99-8fce-41ea-aaf1-1e9918fa6f29'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/92784a99-8fce-41ea-aaf1-1e9918fa6f29-headshot.jpg', 'https://appellate.courts.ca.gov/district-courts/2dca/justices/former-justices', 'press_use'),
  ('0614ab86-746f-4d22-91b5-71bf7292de6c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0614ab86-746f-4d22-91b5-71bf7292de6c-headshot.jpg', 'https://appellate.courts.ca.gov/district-courts/2dca/justices/former-justices', 'press_use'),
  ('4826be20-f57c-47cb-b78b-29d014b07846'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4826be20-f57c-47cb-b78b-29d014b07846-headshot.jpg', 'https://appellate.courts.ca.gov/district-courts/2dca/justices/former-justices', 'press_use'),
  ('a1d5b21b-31af-4aa3-82a4-fa46f9ae048b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a1d5b21b-31af-4aa3-82a4-fa46f9ae048b-headshot.jpg', 'https://appellate.courts.ca.gov/district-courts/2dca/justices/former-justices', 'press_use'),
  ('3aedc075-d219-40f9-932b-c92d000c5d9a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3aedc075-d219-40f9-932b-c92d000c5d9a-headshot.jpg', 'https://www.claremontca.gov/Government/City-Council', 'press_use'),
  ('6454b303-add3-4ab6-8ca8-42e60109bdb3'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6454b303-add3-4ab6-8ca8-42e60109bdb3-headshot.jpg', 'https://www.sanfernando.gov/Your-Government/City-Council', 'press_use'),
  ('334f0762-24ed-49bb-b305-90edd8b4b38b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/334f0762-24ed-49bb-b305-90edd8b4b38b-headshot.jpg', 'https://www.sanfernando.gov/Your-Government/City-Council', 'press_use'),
  ('01317eb5-e154-4d54-b7f4-fc87c8be935d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/01317eb5-e154-4d54-b7f4-fc87c8be935d-headshot.jpg', 'https://www.southpasadenaca.gov/How-Do-I/Find/My-City-Council-Member-District', 'press_use'),
  ('7e14a7c0-50dc-43ee-81b6-b86ae1ed10dc'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7e14a7c0-50dc-43ee-81b6-b86ae1ed10dc-headshot.jpg', 'https://www.southpasadenaca.gov/How-Do-I/Find/My-City-Council-Member-District', 'press_use'),
  ('805427db-0028-42f3-8ccd-11886c74938d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/805427db-0028-42f3-8ccd-11886c74938d-headshot.jpg', 'https://www.walnutca.gov/My-Government/Walnut-City-Council/Nancy-Tragarz', 'press_use'),
  ('eb23af50-1ab2-4681-92a2-bc6c2ad633d4'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eb23af50-1ab2-4681-92a2-bc6c2ad633d4-headshot.jpg', 'https://www.walnutca.gov/My-Government/Walnut-City-Council/Kaylee-May-Law', 'press_use'),
  ('0e7ae37a-69b0-4874-8b01-f00d3a77d452'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0e7ae37a-69b0-4874-8b01-f00d3a77d452-headshot.jpg', 'https://www.fresnocountyca.gov/Departments/Assessor', 'press_use');

DO $$
DECLARE n_missing int; n_override int; n_placeholder int;
BEGIN
  SELECT count(*) INTO n_missing FROM _ca_headshots t
  LEFT JOIN essentials.politicians p ON p.id = t.politician_id WHERE p.id IS NULL;
  IF n_missing <> 0 THEN
    RAISE EXCEPTION 'aborting: % target politicians no longer exist', n_missing;
  END IF;

  SELECT count(*) INTO n_override FROM _ca_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_custom_url_manual_override IS TRUE;
  IF n_override <> 0 THEN
    RAISE EXCEPTION 'aborting: % target(s) carry photo_custom_url_manual_override', n_override;
  END IF;

  SELECT count(DISTINCT t.politician_id) INTO n_placeholder
  FROM _ca_headshots t
  JOIN essentials.politician_occupancy_evidence e ON e.politician_id = t.politician_id
  WHERE e.is_placeholder_occupancy;
  IF n_placeholder <> 0 THEN
    RAISE EXCEPTION 'aborting: % target(s) are placeholder occupancies, not officeholders',
      n_placeholder;
  END IF;
END $$;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT t.politician_id, t.bucket_url, 'default', t.license
FROM _ca_headshots t
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                  WHERE pi.politician_id = t.politician_id AND pi.url = t.bucket_url);

UPDATE essentials.politicians p
SET photo_custom_url = t.bucket_url,
    photo_origin_url = t.source_page
FROM _ca_headshots t
WHERE p.id = t.politician_id
  AND p.photo_custom_url_manual_override IS NOT TRUE
  AND (p.photo_custom_url IS DISTINCT FROM t.bucket_url
    OR p.photo_origin_url IS DISTINCT FROM t.source_page);

DO $$
DECLARE n_img int; n_custom int; n_render int;
BEGIN
  SELECT count(*) INTO n_img FROM _ca_headshots t
  JOIN essentials.politician_images pi
    ON pi.politician_id = t.politician_id AND pi.url = t.bucket_url;
  IF n_img <> 47 THEN RAISE EXCEPTION 'expected 47 image rows, found %', n_img; END IF;

  SELECT count(*) INTO n_custom FROM _ca_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_custom_url = t.bucket_url
    AND p.photo_custom_url LIKE '%storage.supabase.co%';
  IF n_custom <> 47 THEN
    RAISE EXCEPTION 'expected 47 rows with photo_custom_url on the bucket, found %', n_custom;
  END IF;

  -- HAS_RENDERABLE_PHOTO_SQL, copied from backend/src/lib/photoCoverage.ts verbatim
  SELECT count(*) INTO n_render FROM _ca_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
  WHERE ( img.politician_id IS NOT NULL
       OR btrim(coalesce(p.photo_custom_url, '')) <> ''
       OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%') );
  IF n_render < 47 THEN
    RAISE EXCEPTION 'only % of 47 satisfy HAS_RENDERABLE_PHOTO_SQL', n_render;
  END IF;

  RAISE NOTICE 'ok: 47 California officials renderable';
END $$;

COMMIT;
