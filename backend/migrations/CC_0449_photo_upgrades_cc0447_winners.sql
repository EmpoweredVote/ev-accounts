-- CC_0449 — replace the stored portraits for two CC_0447 winners
--
-- WHAT THIS DOES
--   Points Eric Jones and Jay Obernolte at new 600x750 files, already uploaded and verified
--   serving anonymously, and corrects Jones's licence and origin to the publisher of the new
--   photograph. It writes BOTH `politician_images.url` AND `politicians.photo_custom_url`,
--   because the grid reads `images[]` and the backend reads the scalar — writing one and not
--   the other leaves the two surfaces disagreeing and nothing errors.
--
--     Eric Jones     a DIFFERENT photograph: his campaign's own portrait
--     Jay Obernolte  the SAME photograph, re-mirrored from the original at 1536x1920
--                    (the stored file was 175x219, far below the 600x750 house standard)
--
-- 🔴 WHAT IT OVERWRITES — recorded here and in backend/data/house-2026-late-calls/
--    photo-upgrades-before.json, because these columns have no history table.
--
--     Eric Jones     politician 9e28793b-bb53-433c-be6f-44db5bf2e780
--                    image      586acbbe-5b78-4f26-9db7-2d62cc1d5172
--       url / photo_custom_url
--         '…/politician_photos/9e28793b-bb53-433c-be6f-44db5bf2e780-headshot.jpg'
--         -> '…/politician_photos/portraits-2026-11-17/9e28793b-…-headshot.jpg'
--       photo_license    'unknown'   -> 'press_use'
--       photo_origin_url 'https://ballotpedia.org/Eric_Jones_(California)'
--                        -> 'https://www.ericjones.us/'
--     Jay Obernolte  politician 18db5d61-6bce-4f55-ad45-bed01f329548
--                    image      b432a95d-dfbc-4a24-8b35-534f918aa1de
--       url / photo_custom_url
--         '…/politician_photos/18db5d61-…/default.jpeg'
--         -> '…/politician_photos/portraits-2026-11-17/18db5d61-…-headshot.jpg'
--       photo_license and photo_origin_url are UNCHANGED — CC_0448 set them correctly and the
--       photograph is the same one, so only the resolution changes.
--
-- WHY JONES'S LICENCE IMPROVES
--   CC_0448 set him to `unknown`, which was the honest record for a candidate-submitted
--   Ballotpedia photo with no author or terms published anywhere. The new file is his
--   CAMPAIGN'S OWN portrait from ericjones.us, whose footer carries a press contact
--   (press@ericjones.us) and publishes no copyright notice and no restriction. That is a
--   licence actually read from the publisher, so `press_use` is now supportable where it
--   was not before. ▶ The route out of `unknown` is a better SOURCE, not a better guess.
--
-- 🔴 LAUBACHER IS DELIBERATELY NOT HERE, AND THE REASON IS A FINDING
--   She was going to be re-mirrored too, from the 2400x3000 navy.mil original. Rendering that
--   original to 600x750 produced a file BYTE-IDENTICAL to the one already stored — same
--   SHA256, f7de5334dc1149203174db03374ecd1b33a07807cb77a4164f088a57c8869ef8. Her stored copy
--   was already made from the federal original at full size; the Ballotpedia entry recorded in
--   her old origin was the route by which the photo was FOUND, not the pixels it came from.
--   ▶ A WORSE-LOOKING PROVENANCE DOES NOT IMPLY WORSE PIXELS. There was no upgrade to make,
--   so nothing is written for her and the redundant upload was deleted again.
--
-- VERIFICATION DONE BEFORE THIS FILE WAS WRITTEN
--   Both new objects were fetched ANONYMOUSLY from the public CDN — no credentials, exactly
--   what a visitor's browser gets — and both returned HTTP 200, image/jpeg, 600x750, byte-for-
--   byte identical to what was uploaded. A correct API response is not evidence that an image
--   landed; the anonymous read is.
--
-- WHAT IT DELIBERATELY DOES NOT DO
--   It does not touch `race_candidates.photo_url`, which is the third photo column and the one
--   nothing sweeps — it beats the fixed image on ballot pages. Both men carry NULL there, and
--   the gate asserts they still do, so no ballot page can be showing something else.

BEGIN;

CREATE TEMP TABLE cc0449_pix (
  politician_id uuid PRIMARY KEY,
  image_id      uuid NOT NULL,
  full_name     text NOT NULL,
  old_url       text NOT NULL,
  new_url       text NOT NULL,
  new_license   text NOT NULL,
  new_origin    text NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0449_pix VALUES
 ('9e28793b-bb53-433c-be6f-44db5bf2e780','586acbbe-5b78-4f26-9db7-2d62cc1d5172','Eric Jones',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9e28793b-bb53-433c-be6f-44db5bf2e780-headshot.jpg',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11-17/9e28793b-bb53-433c-be6f-44db5bf2e780-headshot.jpg',
  'press_use','https://www.ericjones.us/'),
 ('18db5d61-6bce-4f55-ad45-bed01f329548','b432a95d-dfbc-4a24-8b35-534f918aa1de','Jay Obernolte',
  'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/18db5d61-6bce-4f55-ad45-bed01f329548/default.jpeg',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11-17/18db5d61-6bce-4f55-ad45-bed01f329548-headshot.jpg',
  'public_domain','https://unitedstates.github.io/images/congress/original/O000019.jpg');

DO $$
DECLARE v_n bigint; v_names text;
BEGIN
  SELECT count(*) INTO v_n
    FROM cc0449_pix x
    JOIN essentials.politician_images pi ON pi.id = x.image_id AND pi.politician_id = x.politician_id
    JOIN essentials.politicians p        ON p.id = x.politician_id AND p.full_name = x.full_name
   WHERE pi.url = x.old_url AND p.photo_custom_url = x.old_url;
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CC_0449 pre-check: % of 2 rows match the person, the image row, and the OLD url in both places this migration says it is replacing', v_n;
  END IF;

  -- The two photo surfaces must agree BEFORE the change, or writing both is papering over a
  -- disagreement this migration did not cause and cannot see.
  SELECT count(*) INTO v_n
    FROM cc0449_pix x
    JOIN essentials.politicians p        ON p.id = x.politician_id
    JOIN essentials.politician_images pi ON pi.id = x.image_id
   WHERE p.photo_custom_url IS DISTINCT FROM pi.url;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0449 pre-check: % row(s) already disagree between photo_custom_url and the image row', v_n;
  END IF;

  -- 🔴 LAUBACHER MUST NOT BE TOUCHED, AND HER FILE MUST STILL BE THE ONE ALREADY STORED.
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id = '09a94867-ea68-4a53-89cb-c89485119a9c'
     AND p.photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/09a94867-ea68-4a53-89cb-c89485119a9c-headshot.jpg';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0449 pre-check: Laubacher is not on the file this migration expects to leave alone';
  END IF;

  -- Nobody may already be pointing at this batch's folder.
  SELECT count(*) INTO v_n FROM essentials.politician_images
   WHERE url LIKE '%portraits-2026-11-17%';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0449 pre-check: % image row(s) already point at this batch folder', v_n;
  END IF;
END $$;

UPDATE essentials.politician_images pi
   SET url           = x.new_url,
       photo_license = x.new_license
  FROM cc0449_pix x
 WHERE pi.id = x.image_id;

UPDATE essentials.politicians p
   SET photo_custom_url = x.new_url,
       photo_origin_url = x.new_origin
  FROM cc0449_pix x
 WHERE p.id = x.politician_id;

-- Post-verify.
DO $$
DECLARE v_n bigint; v_names text;
BEGIN
  -- 1. both surfaces moved, per person, to that person's own new url
  SELECT count(*) INTO v_n
    FROM cc0449_pix x
    JOIN essentials.politician_images pi ON pi.id = x.image_id
    JOIN essentials.politicians p        ON p.id = x.politician_id
   WHERE pi.url = x.new_url AND p.photo_custom_url = x.new_url;
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CC_0449: only % of 2 people have BOTH photo_custom_url and the image row on their new file', v_n;
  END IF;

  -- 2. 🔴 THE FILE MUST BE THE ONE NAMED FOR THAT PERSON. The expectation is written here,
  --    from each politician_id, not read from the pin table — a pin edited consistently
  --    agrees with itself, which is how CC_0447 and CC_0448 each lost a control.
  SELECT count(*), string_agg(p.full_name || ' -> ' || pi.url, ' | ') INTO v_n, v_names
    FROM cc0449_pix x
    JOIN essentials.politician_images pi ON pi.id = x.image_id
    JOIN essentials.politicians p        ON p.id = x.politician_id
   WHERE pi.url NOT LIKE '%portraits-2026-11-17/' || p.id::text || '-headshot.jpg';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0449: % row(s) point at a file not named for that person: %', v_n, v_names;
  END IF;

  -- 3. Jones's licence is now supportable; Obernolte's is unchanged
  SELECT count(*) INTO v_n
    FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE (p.id = '9e28793b-bb53-433c-be6f-44db5bf2e780'
            AND pi.photo_license = 'press_use' AND p.photo_origin_url = 'https://www.ericjones.us/')
      OR (p.id = '18db5d61-6bce-4f55-ad45-bed01f329548'
            AND pi.photo_license = 'public_domain'
            AND p.photo_origin_url = 'https://unitedstates.github.io/images/congress/original/O000019.jpg');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CC_0449: expected 2 rows with their stated licence and origin, found %', v_n;
  END IF;

  -- 4. 🔴 NO ROW MAY CLAIM A LICENCE ON A BALLOTPEDIA ORIGIN (the CC_0448 rule, still true)
  SELECT count(*) INTO v_n
    FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE p.id IN (SELECT politician_id FROM cc0449_pix)
     AND p.photo_origin_url LIKE '%ballotpedia.org%'
     AND pi.photo_license NOT IN ('unknown', '');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0449: % row(s) claim a licence on the authority of a Ballotpedia page', v_n;
  END IF;

  -- 5. 🔴 LAUBACHER IS UNTOUCHED. Her bytes were already the best render available.
  SELECT count(*) INTO v_n FROM essentials.politicians p
    JOIN essentials.politician_images pi ON pi.politician_id = p.id
   WHERE p.id = '09a94867-ea68-4a53-89cb-c89485119a9c'
     AND p.photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/09a94867-ea68-4a53-89cb-c89485119a9c-headshot.jpg'
     AND pi.url = p.photo_custom_url
     AND pi.photo_license = 'us_government_work';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0449: Laubacher was modified; this migration must leave her alone';
  END IF;

  -- 6. the third photo column stays NULL, or a ballot page shows something else entirely
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc
   WHERE rc.politician_id IN (SELECT politician_id FROM cc0449_pix)
     AND coalesce(rc.photo_url, '') <> '';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0449: % race_candidates row(s) carry their own photo_url, which beats the fixed image on ballot pages', v_n;
  END IF;

  -- 7. NO SCOPE LEAK: exactly two rows repo-wide point at this batch folder
  SELECT count(*) INTO v_n FROM essentials.politician_images
   WHERE url LIKE '%portraits-2026-11-17%';
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CC_0449: % image row(s) repo-wide point at this batch folder, expected exactly 2', v_n;
  END IF;

  -- 8. each person still has exactly one image row
  SELECT count(*) INTO v_n FROM (
    SELECT x.politician_id FROM cc0449_pix x
      JOIN essentials.politician_images pi ON pi.politician_id = x.politician_id
     GROUP BY x.politician_id HAVING count(*) <> 1) z;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0449: % of the two people no longer have exactly one image row', v_n;
  END IF;

  RAISE NOTICE 'CC_0449 OK: 2 portraits replaced (Jones, Obernolte); Laubacher untouched';
END $$;

COMMIT;
