-- CC_0253_headshots_with_no_face.sql
--
-- Replaces NINE live headshots that are not photographs of the person they label.
--
-- The operator found two by eye: "Michael Watson and Lynn Fitch in mississippi need better
-- headshots." Watson was the Mississippi Secretary of State SEAL. Fitch was a real photograph
-- of her, stored on its side. A sweep of all 7,779 active headshots on our own storage found
-- seven more of the same class.
--
-- 🔴 EVERY GATE WE OWN PASSED ALL NINE. Each file was exactly 600x750, exactly 4:5, in colour,
-- carried a licence, sat on our CDN, and had photo_custom_url agreeing with its type='default'
-- politician_images row. Nothing in the pipeline asked whether the frame contained a FACE.
--
--   Michael Watson    (MS Secretary of State)  office seal
--   Michael Howe      (ND Secretary of State)  Great Seal of North Dakota
--   Dave Sunday       (PA Attorney General)    Seal of Pennsylvania
--   Andy Wilson       (OH Attorney General)    Seal of the Attorney General of Ohio
--   John Thurston     (AR Treasurer)           2024 Arkansas election results map, by county
--   Steven Johnson    (KS Treasurer)           2022 Kansas election results map, by county
--   Anna M. Caballero (CA State Senate)        a blank white frame, every pixel identical
--   Marie L Kern      (IN Superior Court)      a torso from the neck down; no face in frame
--   Lynn Fitch        (MS Attorney General)    a real portrait, rotated 90 degrees
--
-- ROOT CAUSE, for the six state executives: backend/scripts/seed-state-exec-headshots.py took
-- the Wikipedia ARTICLE's lead image (prop=pageimages), which for these officials is the office
-- seal or an election map, and opened it with Image.open().convert('RGB') -- which does not
-- apply EXIF orientation, which is why Fitch came out sideways. Caballero (ca-sos-2026) and
-- Kern (ballotready) came from different imports, so this is a CLASS, not one script's bug.
-- Both defects are now refused by scripts/lib/headshot_image.py, wired into that importer, and
-- the whole corpus can be re-checked with scripts/check-headshot-faces.py.
--
-- ⚠ Hobbs (WA) and Jeff Jackson (NC) also shipped seals in migration 985 and have since been
-- re-sourced by someone else. They are NOT in this migration. The migration file is a record of
-- what was written; only the data says what is live.
--
-- SOURCES. Official government sites and Wikimedia Commons only, per the standing press/official
-- policy. Every file was downloaded, face-checked at four rotations, cropped from the MEASURED
-- face box (face centred at 47-51% of frame width on all nine), rendered at 600x750 q90, and
-- looked at by both the author and the operator on a contact sheet before import.
--
--   Watson     sos.ms.gov MSSecretaryMichaelWatsonOfficialHeadshot.jpeg  3930x4644  0.23x
--   Fitch      commons Lynn_Fitch.jpg (Ktkvtsh, CC BY 4.0)                905x1265  0.66x
--   Howe       sos.nd.gov howe-headshot.png                              1280x1440  0.94x
--   Sunday     attorneygeneral.gov sunday-in-office-image-scaled.jpg     2166x2560  0.47x
--   Wilson     ohioattorneygeneral.gov Andy_Wilson_Large.aspx             997x1496  0.66x
--   Thurston   commons AR SoS John Thurston (cropped) (CC BY-SA 4.0)     1073x1254  0.61x
--   Johnson    treasurer.ks.gov Steven_home_20230613.png                  500x488   1.57x  <-- UPSCALED
--   Caballero  sd14.senate.ca.gov caballero_anna_0002.jpg                2843x3980  0.25x
--   Kern       indyjudges.org m.kern.jud.vac.headshot.jpg                2100x1500  0.66x
--
-- ⚠ JOHNSON IS THE ONE UPSCALE, at 1.57x. 500x488 is the largest portrait the Kansas Treasurer
-- publishes; Ballotpedia has only a disambiguation page and Commons has nothing. The alternative
-- was leaving an election map live, so the upscale was accepted deliberately.
--
-- ⚠ FITCH IS THE SAME COMMONS FILE AS BEFORE. The source was never sideways -- our importer did
-- not apply EXIF orientation. Her own office site serves ONLY the office seal, and the two
-- alternatives were a full-body profile shot and a Supreme Court rally framed by protest
-- placards. Opened correctly, the original file is upright.
--
-- ⚠ KERN'S LIVE FILE WAS CROPPED BY A URL PARAMETER. indyjudges.org serves her portrait through
-- an iSteam transform (/:/cr=t:0%25,l:23.21%...) that cut her head off above the chin. This is
-- the same photograph with the transform removed.
--
-- 🔴 LICENCES ARE CORRECTED DOWNWARD HERE, AND THAT IS DELIBERATE. Six rows previously read
-- 'public_domain'. That was true of the Wikipedia seal files they labelled; it is NOT true of an
-- official state-agency portrait, because state government works -- unlike federal ones -- carry
-- no automatic public-domain status. Where a site states no licence, the honest label for an
-- official portrait published for public and press use is 'press_use'. Only the two Commons
-- files carry an explicit licence, and they keep it.
--
-- 🔴 THE URLs GAIN A ?v= CACHE KEY, AND THEY MUST. The storage path is unchanged, so overwriting
-- the object with x-upsert does NOT change what the public CDN serves: measured after upload,
-- the authenticated read returned the new bytes while the public URL returned the OLD file with
-- cf-cache-status: HIT. A request-side 'Cache-Control: no-cache' did not bust it; a distinct
-- query string did (cf-cache-status: MISS, new bytes). 10 active rows already carry a query
-- string and nothing in backend/src or backend/scripts parses an object path out of these
-- columns, so this shape is safe.
--
-- All nine objects were uploaded with x-upsert and VERIFIED SERVED: HTTP 200, image/jpeg,
-- sha256 of the served bytes byte-identical to the local file.
--
-- 🔴 BOTH SIDES ARE WRITTEN, as in CC_0246 and CC_0249-CC_0251: the backend profile reads
-- politicians.photo_custom_url and the browse grid reads the politician_images row, and a
-- replacement that writes only one of them moves nothing a voter sees.
-- Idempotent: re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _noface_headshots (
  politician_id uuid PRIMARY KEY,
  name_like     text NOT NULL,
  url           text NOT NULL,
  origin_url    text NOT NULL,
  photo_license text NOT NULL
) ON COMMIT DROP;

INSERT INTO _noface_headshots (politician_id, name_like, url, origin_url, photo_license) VALUES
 ('b7e0d181-ca77-4bf0-a9b0-c1e8e747e484'::uuid, 'Michael Watson',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b7e0d181-ca77-4bf0-a9b0-c1e8e747e484-headshot.jpg?v=20261019',
  'https://www.sos.ms.gov/sites/default/files/2025-10/MSSecretaryMichaelWatsonOfficialHeadshot.jpeg', 'press_use'),
 ('9dc9d9a7-4963-4752-b38f-88c29ae03491'::uuid, 'Lynn Fitch',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9dc9d9a7-4963-4752-b38f-88c29ae03491-headshot.jpg?v=20261019',
  'https://upload.wikimedia.org/wikipedia/commons/1/17/Lynn_Fitch.jpg', 'cc_by_4.0'),
 ('d7cc7826-afd2-43fb-85b4-76c9aeccd1db'::uuid, 'Michael Howe',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d7cc7826-afd2-43fb-85b4-76c9aeccd1db-headshot.jpg?v=20261019',
  'https://www.sos.nd.gov/sites/www/files/documents/about/howe-headshot.png', 'press_use'),
 ('c1a8e812-2851-4c1b-b5c5-cf2997ee2ed2'::uuid, 'Dave Sunday',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c1a8e812-2851-4c1b-b5c5-cf2997ee2ed2-headshot.jpg?v=20261019',
  'https://www.attorneygeneral.gov/wp-content/uploads/sunday-in-office-image-scaled.jpg', 'press_use'),
 ('ef91fbe1-2a1d-459d-a5cd-772025423c7b'::uuid, 'Andy Wilson',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ef91fbe1-2a1d-459d-a5cd-772025423c7b-headshot.jpg?v=20261019',
  'https://www.ohioattorneygeneral.gov/Images/Media/Andy_Wilson_Large.aspx', 'press_use'),
 ('e9af5fde-e1cd-4a54-9594-ec9e42353d55'::uuid, 'John Thurston',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e9af5fde-e1cd-4a54-9594-ec9e42353d55-headshot.jpg?v=20261019',
  'https://commons.wikimedia.org/wiki/File:Arkansas_Secretary_of_State_John_Thurston_(cropped).jpg', 'cc_by-sa_4.0'),
 ('6dada0fd-8e21-4899-819d-26ba69a75b37'::uuid, 'Steven Johnson',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6dada0fd-8e21-4899-819d-26ba69a75b37-headshot.jpg?v=20261019',
  'https://treasurer.ks.gov/assets/images/Steven_home_20230613.png', 'press_use'),
 ('cb370677-36db-44b0-ae74-ebb6ae4a3d33'::uuid, 'Anna M. Caballero',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cb370677-36db-44b0-ae74-ebb6ae4a3d33-headshot.jpg?v=20261019',
  'https://sd14.senate.ca.gov/sites/sd12.senate.ca.gov/files/images/caballero_anna_0002.jpg', 'press_use'),
 ('46629f4a-7860-4d00-804b-bb268a835de3'::uuid, 'Marie L Kern',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/46629f4a-7860-4d00-804b-bb268a835de3-headshot.jpg?v=20261019',
  'https://img1.wsimg.com/isteam/ip/3ebd4bd2-3aa2-45a7-a8bd-2d7f8659c5d2/m.kern.jud.vac.headshot.jpg', 'press_use');

-- Guard: every id must still resolve to the person this migration believes it is. An
-- external_id collision seats the wrong face silently, and a face is the one field where that
-- is invisible to every other check.
DO $$
DECLARE r record; v_name text;
BEGIN
  FOR r IN SELECT * FROM _noface_headshots LOOP
    SELECT p.full_name INTO v_name FROM essentials.politicians p WHERE p.id = r.politician_id;
    IF v_name IS NULL THEN
      RAISE EXCEPTION 'CC_0253: % matches no politician row', r.politician_id;
    END IF;
    IF v_name <> r.name_like THEN
      RAISE EXCEPTION 'CC_0253: % resolves to "%", expected "%"', r.politician_id, v_name, r.name_like;
    END IF;
  END LOOP;
END $$;

-- 1. the images[] row the browse grid reads
UPDATE essentials.politician_images pi
SET url = h.url, photo_license = h.photo_license
FROM _noface_headshots h
WHERE pi.politician_id = h.politician_id
  AND pi.type = 'default'
  AND (pi.url IS DISTINCT FROM h.url OR pi.photo_license IS DISTINCT FROM h.photo_license);

-- a default row should already exist for all nine, but do not assume it
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT h.politician_id, h.url, 'default', h.photo_license
FROM _noface_headshots h
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
  WHERE pi.politician_id = h.politician_id AND pi.type = 'default');

-- 2. the scalar the backend profile reads, plus provenance
UPDATE essentials.politicians p
SET photo_custom_url = h.url,
    photo_origin_url = h.origin_url
FROM _noface_headshots h
WHERE p.id = h.politician_id
  AND (p.photo_custom_url IS DISTINCT FROM h.url
    OR p.photo_origin_url IS DISTINCT FROM h.origin_url);

-- post-verify: all nine present on BOTH sides, agreeing, with exactly one default row each.
DO $$
DECLARE n_images int; n_scalar int; n_mismatch int; n_multi int; n_old int;
BEGIN
  SELECT count(*) INTO n_images
    FROM _noface_headshots h
    JOIN essentials.politician_images pi
      ON pi.politician_id = h.politician_id AND pi.type = 'default'
     AND pi.url = h.url AND pi.photo_license = h.photo_license;
  IF n_images <> 9 THEN
    RAISE EXCEPTION 'CC_0253: expected 9 default politician_images rows, found %', n_images;
  END IF;

  SELECT count(*) INTO n_scalar
    FROM _noface_headshots h
    JOIN essentials.politicians p
      ON p.id = h.politician_id AND p.photo_custom_url = h.url AND p.photo_origin_url = h.origin_url;
  IF n_scalar <> 9 THEN
    RAISE EXCEPTION 'CC_0253: expected 9 politicians.photo_custom_url, found %', n_scalar;
  END IF;

  SELECT count(*) INTO n_mismatch
    FROM _noface_headshots h
    JOIN essentials.politicians p ON p.id = h.politician_id
    JOIN essentials.politician_images pi ON pi.politician_id = p.id AND pi.type = 'default'
   WHERE p.photo_custom_url IS DISTINCT FROM pi.url;
  IF n_mismatch <> 0 THEN
    RAISE EXCEPTION 'CC_0253: scalar and images[] disagree for % row(s)', n_mismatch;
  END IF;

  -- two default rows make the grid's find() pick an arbitrary one
  SELECT count(*) INTO n_multi FROM (
    SELECT pi.politician_id FROM essentials.politician_images pi
    JOIN _noface_headshots h ON h.politician_id = pi.politician_id
    WHERE pi.type = 'default'
    GROUP BY pi.politician_id HAVING count(*) > 1) x;
  IF n_multi <> 0 THEN
    RAISE EXCEPTION 'CC_0253: % politician(s) carry more than one default image row', n_multi;
  END IF;

  -- nothing may still point at the un-versioned URL, which the CDN serves from cache
  SELECT count(*) INTO n_old
    FROM _noface_headshots h
    JOIN essentials.politicians p ON p.id = h.politician_id
   WHERE p.photo_custom_url NOT LIKE '%?v=20261019';
  IF n_old <> 0 THEN
    RAISE EXCEPTION 'CC_0253: % row(s) still on the cached un-versioned URL', n_old;
  END IF;

  RAISE NOTICE 'CC_0253 OK - 9 headshots replaced, both sides written and agreeing';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS DOES NOT FIX
--
-- 1. THE WRONG PERSON'S FACE. A face detector confirms a face is present, never whose. That
--    remains the dominant failure mode in headshot work and is invisible to this sweep.
-- 2. 1,381 ACTIVE HEADSHOTS HOSTED OFF OUR CDN were not swept; only the 7,779 on our own
--    storage were. Run: python backend/scripts/check-headshot-faces.py --all-hosts
-- 3. ~60 IMPORTERS STILL CARRY A COPY-PASTED crop_to_4_5 AND NONE APPLIES EXIF ORIENTATION.
--    Only seed-state-exec-headshots.py was rewired onto scripts/lib/headshot_image.py. The rest
--    are one-shot scripts that have already run, so they were left alone deliberately rather
--    than retro-edited; a NEW importer should import the shared module.
-- 4. A SEPARATE FINDING, not a headshot defect: Isaac E. Barrón and Isaac Barron are two active
--    politician rows sharing byte-identical images -- almost certainly one person twice. The
--    duplicate-name guard keys on (first_name, last_name), so the accent hides the pair.
-- ───────────────────────────────────────────────────────────────────────────────────────────
