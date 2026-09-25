-- CA_0290_az_legislature_november_headshots_web.sql
--
-- Slot CA_0290 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Four more headshots for CA_0282 people that CA_0289 could not cover (no SOS photo, or the SOS photo
-- was rejected). find-headshots convention; each photo reviewed and approved by the operator 2026-09-24.
--
--   Nick Fierro (SD10)               Ballotpedia https://ballotpedia.org/Nick_Fierro — full-size original
--                                    s3.amazonaws.com/ballotpedia-api4/files/Nick_Fierro_20250805_032105.jpg (2735x2735);
--                                    4:5 crop moved to the left edge (face is left of centre)
--   Jacob D. Martinez (HD9)          Ballotpedia https://ballotpedia.org/Jacob_Martinez — original
--                                    jacob-headshot-close_20260618_011600_41443_1.jpeg (1796x2048); tighter head-and-
--                                    shoulders crop (the source is three-quarter length)
--   Jackie O'Donnell Anderson (HD19) Ballotpedia https://ballotpedia.org/Jackie_Anderson — original
--                                    Headshot_20260727_230545_31953_1.jpg (1100x1080); centre 4:5 crop
--   Jonathan McKenna (HD26)          campaign site https://mckenna.vote/ — wp-content/uploads/2026/09/new-head2.jpg
--                                    (667x866); centre 4:5 crop
-- Each page ties the person to the Arizona race and district. All resized to 600x750 (Lanczos, JPEG q90),
-- uploaded to politician_photos as <politician_id>-headshot.jpg, re-fetched and byte-compared (4/4).
-- Licence 'press_use' (Ballotpedia / campaign site, per the find-headshots convention).
--
-- STILL NO PHOTO (no usable non-social-media source): Mike Montiel (SD7), Charlie Eakins (HD1), Royce
-- "RJ" Mark Jenkins (HD6), Sam Martin (HD7), Hector Gomez (HD26).
--
-- IDEMPOTENT: image row only when the person has none; photo_origin_url only when NULL.
-- ROLLBACK: DELETE the four politician_images rows below; set photo_origin_url NULL on the same people.

BEGIN;

CREATE TEMP TABLE ca0290_img ON COMMIT DROP AS
SELECT v.ext, v.full_name, v.origin, p.id AS pid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' || p.id::text || '-headshot.jpg' AS url
  FROM (VALUES
    (-66000346::bigint, 'Nick Fierro',               'https://ballotpedia.org/Nick_Fierro'),
    (-66000384::bigint, 'Jacob D. Martinez',         'https://ballotpedia.org/Jacob_Martinez'),
    (-66000403::bigint, 'Jackie O''Donnell Anderson', 'https://ballotpedia.org/Jackie_Anderson'),
    (-66000414::bigint, 'Jonathan McKenna',          'https://mckenna.vote/')
  ) AS v(ext, full_name, origin)
  LEFT JOIN essentials.politicians p ON p.external_id = v.ext AND p.full_name = v.full_name
   AND p.source LIKE 'CA_0282 (2026-09-24):%';

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0290_img WHERE pid IS NOT NULL;
  IF n <> 4 THEN RAISE EXCEPTION 'PRE: resolved % of 4 CA_0282 people', n; END IF;
  SELECT count(*) INTO n FROM ca0290_img c JOIN essentials.politician_images i ON i.politician_id = c.pid
   WHERE i.url <> c.url;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of the 4 already have a different image', n; END IF;
  RAISE NOTICE 'CA_0290 pre-flight OK';
END $$;

INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), c.pid, c.url, 'default', 'press_use'
  FROM ca0290_img c
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = c.pid);

UPDATE essentials.politicians p
   SET photo_origin_url = c.origin
  FROM ca0290_img c
 WHERE p.id = c.pid AND p.photo_origin_url IS NULL;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0290_img c
   WHERE (SELECT count(*) FROM essentials.politician_images i
           WHERE i.politician_id = c.pid AND i.url = c.url AND i.type = 'default' AND i.photo_license = 'press_use') = 1
     AND (SELECT count(*) FROM essentials.politician_images i WHERE i.politician_id = c.pid) = 1
     AND (SELECT photo_origin_url FROM essentials.politicians WHERE id = c.pid) = c.origin;
  IF n <> 4 THEN RAISE EXCEPTION 'POST: % of 4 people carry exactly their one headshot', n; END IF;

  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.source LIKE 'CA_0282 (2026-09-24):%'
     AND NOT EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = p.id);
  IF n <> 5 THEN RAISE EXCEPTION 'POST: % CA_0282 people without a headshot, expected 5', n; END IF;

  RAISE NOTICE 'CA_0290 applied: 4 more AZ legislature candidate headshots';
END $$;

COMMIT;
