-- CC_0520_fremont_headshot_provenance.sql
-- CC_0520: Fremont, CA -- headshot provenance for the 7 city officials and the 5 Fremont Unified trustees, and a
-- sharp re-render of Dianne Jones.
--
-- WHAT WAS CHECKED (2026-11-27). All 12 stored files were downloaded and looked at: every one is a colour,
-- 600x750, head-and-shoulders portrait of the named person; none is a disc crop or a framed/letterboxed image.
--   CITY (7): one matching official set (same location, same photographer's style) from fremont.gov, loaded by
--     migration 212 / scripts/_tmp-fremont-headshots.ts. fremont.gov now answers Akamai "Access Denied" to curl
--     with a full browser header set AND to headless Chrome, so the page's rights statement could not be read.
--   FUSD (5): compared side by side with the photos on FUSD's own roster
--     (fremontunified.org/about/board/board-of-education-members/): the same photograph of the same person in
--     every case. The district publishes Coco, Sweeney, Nair and Prasad at 125x156 ONLY (the WordPress media API
--     requires login), so our 600x750 copies are ~4.8x enlargements -- the body's own practice, recorded as REPLACE.
--     Jones is published at 240x300 on the roster, but the unsized original Dianne-Jones.jpg is 1183x1479.
--   ⚠ check-portrait-framing.mjs could NOT run here (no ffmpeg on this machine; it refuses a verdict without its
--     controls, correctly). check-headshot-faces.py could not run either (no Python). The by-eye review above is
--     the only framing check these 12 have had in this pass.
--
-- WHAT CHANGES.
--   1. Dianne Jones: re-rendered from the 1183x1479 original (already 4:5; downscaled x0.507 to 600x750, two-step,
--      no crop, nothing composited), uploaded as a NEW object b1f99ff3-...-headshot-v2.jpg (sha256
--      13ac5cb0bf57ac3b65b863fca1a99dc96a3dc784e9d8f005a16f30bbe0ecf9db, 69,074 bytes; the public URL returned
--      byte-identical). A new name, not an overwrite, because storage overwrites in place behind a CDN.
--   2. FUSD trustees: photo_origin_url set to the district roster page (was NULL on all five).
--   3. All 12: politician_images.photo_license rewritten from 'public_domain' to a statement of what is known.
--      'public_domain' was unsupported: neither body publishes a dedication, and a California city or school
--      district photo is not a U.S. federal work.
--
-- 🔴 OVERWRITTEN VALUES.
--   politician_images.photo_license = 'public_domain' on all 12 image rows:
--     3f80b830-4e7e-4b02-ad31-a6dcd80bf72e Raj Salwan        d0d63a41-dd2a-407b-b1d3-791f44ad3d79 Teresa Keng
--     acfd9592-52ca-47ba-a0c9-6af371379b97 Desrie Campbell   e5b4c61e-d1f4-40bb-8bb5-2c45c4ad1f86 Kathy Kimberlin
--     e5f0d33b-ce2d-4681-b848-92b83a5200cc Yang Shao         b8102f54-e6b3-4bd9-9dce-f3e85ea86a1b Yajing Zhang
--     88587074-aede-4372-baee-b7316a90f6c9 Raymond Liu       2035db5e-bc31-4a58-8350-9fda535ee063 Sharon Coco
--     48e930f6-7c36-4225-8440-ab5f55bf1db9 Larry Sweeney     6095869d-2d51-4830-a9e4-ba07124051b7 Dianne Jones
--     cbb7ffda-bc23-4b26-84d8-96691351a19c Rinu Nair         b478bb93-9bcb-45b2-928a-a8021c977004 Vivek Prasad
--   politicians.photo_origin_url = NULL for Coco, Sweeney, Jones, Nair, Prasad.
--   Jones (politician b1f99ff3-8232-4da8-b240-fa36206d37ad): politician_images.url AND politicians.photo_custom_url
--     were .../politician_photos/b1f99ff3-8232-4da8-b240-fa36206d37ad-headshot.jpg (the old object is left in place).
BEGIN;

-- 1. Jones -> the re-rendered file
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b1f99ff3-8232-4da8-b240-fa36206d37ad-headshot-v2.jpg'
 WHERE id = '6095869d-2d51-4830-a9e4-ba07124051b7'
   AND url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b1f99ff3-8232-4da8-b240-fa36206d37ad-headshot.jpg';
UPDATE essentials.politicians
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b1f99ff3-8232-4da8-b240-fa36206d37ad-headshot-v2.jpg'
 WHERE id = 'b1f99ff3-8232-4da8-b240-fa36206d37ad'
   AND photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b1f99ff3-8232-4da8-b240-fa36206d37ad-headshot.jpg';

-- 2. FUSD origin page
UPDATE essentials.politicians
   SET photo_origin_url = 'https://fremontunified.org/about/board/board-of-education-members/'
 WHERE id IN ('cff2ea49-6906-428e-b34f-d4082c5a68d1', 'd2d867ac-746e-44bc-b93b-022fe0d28718',
              'b1f99ff3-8232-4da8-b240-fa36206d37ad', 'c5bafda7-20a1-49c6-9b80-e66a8d5ab5e4',
              'b6b167d5-0762-4913-b61a-c45c61f303ad')
   AND photo_origin_url IS NULL;

-- 3. Licence statements
UPDATE essentials.politician_images i
   SET photo_license = v.lic
  FROM (VALUES
    ('3f80b830-4e7e-4b02-ad31-a6dcd80bf72e'::uuid, 'city'), ('d0d63a41-dd2a-407b-b1d3-791f44ad3d79'::uuid, 'city'),
    ('acfd9592-52ca-47ba-a0c9-6af371379b97'::uuid, 'city'), ('e5b4c61e-d1f4-40bb-8bb5-2c45c4ad1f86'::uuid, 'city'),
    ('e5f0d33b-ce2d-4681-b848-92b83a5200cc'::uuid, 'city'), ('b8102f54-e6b3-4bd9-9dce-f3e85ea86a1b'::uuid, 'city'),
    ('88587074-aede-4372-baee-b7316a90f6c9'::uuid, 'city'),
    ('2035db5e-bc31-4a58-8350-9fda535ee063'::uuid, 'fusd_small'), ('48e930f6-7c36-4225-8440-ab5f55bf1db9'::uuid, 'fusd_small'),
    ('cbb7ffda-bc23-4b26-84d8-96691351a19c'::uuid, 'fusd_small'), ('b478bb93-9bcb-45b2-928a-a8021c977004'::uuid, 'fusd_small'),
    ('6095869d-2d51-4830-a9e4-ba07124051b7'::uuid, 'fusd_jones')
  ) AS k(id, kind)
  JOIN (VALUES
    ('city', 'City of Fremont official portrait (fremont.gov Mayor & City Council page, loaded by migration 212). The city''s rights statement could not be read: fremont.gov answers Akamai Access Denied to automated reads (2026-11-27). Replaces an unsupported ''public_domain'' claim (CC_0520).'),
    ('fusd_small', 'Fremont Unified School District official board portrait (fremontunified.org Board of Education Members page, read 2026-11-27); the district publishes it at 125x156 only, so this 600x750 file is a ~x4.8 upscale, REPLACE. Rights statement not checked. Replaces an unsupported ''public_domain'' claim (CC_0520).'),
    ('fusd_jones', 'Fremont Unified School District official board portrait, from the unsized original fremontunified.org/wp-content/uploads/2023/07/Dianne-Jones.jpg (1183x1479), downscaled x0.507 to 600x750, no crop, nothing composited. Rights statement not checked. Replaces an upscale of the 240x300 roster thumbnail and an unsupported ''public_domain'' claim (CC_0520).')
  ) AS v(kind, lic) ON v.kind = k.kind
 WHERE i.id = k.id AND i.photo_license = 'public_domain';

-- 4. Post-verify
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.politician_images
   WHERE id IN ('3f80b830-4e7e-4b02-ad31-a6dcd80bf72e','d0d63a41-dd2a-407b-b1d3-791f44ad3d79','acfd9592-52ca-47ba-a0c9-6af371379b97',
                'e5b4c61e-d1f4-40bb-8bb5-2c45c4ad1f86','e5f0d33b-ce2d-4681-b848-92b83a5200cc','b8102f54-e6b3-4bd9-9dce-f3e85ea86a1b',
                '88587074-aede-4372-baee-b7316a90f6c9','2035db5e-bc31-4a58-8350-9fda535ee063','48e930f6-7c36-4225-8440-ab5f55bf1db9',
                '6095869d-2d51-4830-a9e4-ba07124051b7','cbb7ffda-bc23-4b26-84d8-96691351a19c','b478bb93-9bcb-45b2-928a-a8021c977004')
     AND photo_license LIKE '%(CC_0520).';
  IF n <> 12 THEN RAISE EXCEPTION 'CC_0520: expected 12 rewritten licence statements, found %', n; END IF;

  -- each image row belongs to the person it is listed for (a crossed id would give someone another's licence)
  SELECT count(*) INTO n FROM essentials.politician_images i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE (i.id, p.full_name) IN (
     ('3f80b830-4e7e-4b02-ad31-a6dcd80bf72e'::uuid,'Raj Salwan'), ('d0d63a41-dd2a-407b-b1d3-791f44ad3d79'::uuid,'Teresa Keng'),
     ('acfd9592-52ca-47ba-a0c9-6af371379b97'::uuid,'Desrie Campbell'), ('e5b4c61e-d1f4-40bb-8bb5-2c45c4ad1f86'::uuid,'Kathy Kimberlin'),
     ('e5f0d33b-ce2d-4681-b848-92b83a5200cc'::uuid,'Yang Shao'), ('b8102f54-e6b3-4bd9-9dce-f3e85ea86a1b'::uuid,'Yajing Zhang'),
     ('88587074-aede-4372-baee-b7316a90f6c9'::uuid,'Raymond Liu'), ('2035db5e-bc31-4a58-8350-9fda535ee063'::uuid,'Sharon Coco'),
     ('48e930f6-7c36-4225-8440-ab5f55bf1db9'::uuid,'Larry Sweeney'), ('6095869d-2d51-4830-a9e4-ba07124051b7'::uuid,'Dianne Jones'),
     ('cbb7ffda-bc23-4b26-84d8-96691351a19c'::uuid,'Rinu Nair'), ('b478bb93-9bcb-45b2-928a-a8021c977004'::uuid,'Vivek Prasad'));
  IF n <> 12 THEN RAISE EXCEPTION 'CC_0520: image-row/person pairing check found % of 12', n; END IF;

  -- the city/FUSD split is on the right rows: the 5 FUSD licences sit on the 5 people seated on FUSD offices
  SELECT count(*) INTO n FROM essentials.politician_images i
    JOIN essentials.office_current_holder och ON och.politician_id = i.politician_id
    JOIN essentials.offices o ON o.id = och.office_id JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = '793fba63-a300-41fb-8833-5838cd8d2d83' AND i.photo_license LIKE 'Fremont Unified School District%';
  IF n <> 5 THEN RAISE EXCEPTION 'CC_0520: expected the FUSD licence on the 5 seated trustees, found %', n; END IF;

  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id IN ('cff2ea49-6906-428e-b34f-d4082c5a68d1','d2d867ac-746e-44bc-b93b-022fe0d28718','b1f99ff3-8232-4da8-b240-fa36206d37ad',
                'c5bafda7-20a1-49c6-9b80-e66a8d5ab5e4','b6b167d5-0762-4913-b61a-c45c61f303ad')
     AND photo_origin_url = 'https://fremontunified.org/about/board/board-of-education-members/';
  IF n <> 5 THEN RAISE EXCEPTION 'CC_0520: expected 5 FUSD origin URLs, found %', n; END IF;

  SELECT count(*) INTO n FROM essentials.politicians p JOIN essentials.politician_images i ON i.politician_id = p.id
   WHERE p.id = 'b1f99ff3-8232-4da8-b240-fa36206d37ad'
     AND p.photo_custom_url LIKE '%-headshot-v2.jpg' AND i.url = p.photo_custom_url;
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0520: Jones url / photo_custom_url not both on the v2 file (%)', n; END IF;

  RAISE NOTICE 'CC_0520 OK: 12 licence statements, 5 FUSD origins, Jones on v2';
END $$;

COMMIT;
