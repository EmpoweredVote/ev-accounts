-- CC_0285_husk_photo_scalar.sql
--
-- Sets the two photo scalars that migration 1937 left NULL on the merge survivor, Joseph G Husk
-- (85194f5e-6574-4371-97da-f1cc89568870), Monroe County / Benton Township Board, Indiana.
--
-- No new image is published. His portrait is already in our bucket and already attached to him.
-- Nothing renders it, and no gate can see it.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- WHY. Found while fixing CC_0284 (Joy Langford). The query that looked for "active politician,
-- photo_custom_url NULL, but a default politician_images row exists" returned exactly two rows.
-- Langford was one. This is the other, and it fails the opposite way: BOTH of his scalars are
-- NULL, so he renders BLANK rather than broken.
--
-- 🔴 WHICH IS WHY NOTHING EVER FLAGGED HIM. The nightly `headshot faces` job selects on
-- COALESCE(photo_custom_url, photo_origin_url). With both NULL that COALESCE is NULL, the row
-- is not selected, and the job is silent. Run against him by id before this migration:
--
--   $ check-headshot-faces.py --only 85194f5e-...
--   checking 0 distinct images  (profile 0  ballot 0 rows before de-duplication)
--   no rows matched - nothing was checked
--
-- A blank is invisible to the one detector that opens the bytes, because that detector never
-- gets a URL to open. Langford was LOUD for three nights; Husk has been silent.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- HOW HE GOT HERE: MIGRATION 1937 DID ITS JOB AND STOPPED ONE COLUMN SHORT.
--
-- 1937 merged his two person rows -- 85194f5e held the office, 04d2e529 held the 2026 candidacy,
-- and they are one man (identical geo_id 1810504816, Benton Township in Monroe County; a
-- re-election, not a move). It moved the image:
--
--   UPDATE essentials.politician_images SET politician_id = m.survivor ... WHERE pi.politician_id = m.dup
--
-- and its post-check asked whether every survivor now HAS an image row:
--
--   IF n <> 0 THEN RAISE EXCEPTION '... % survivor(s) have no image' ...
--
-- ⚠ THAT IS THE WRONG QUESTION FOR A RENDER PATH, and it passed green. The grid reads images[]
-- first, but the BACKEND READS THE SCALAR, and the scalars were never moved. They are still
-- sitting on the retired row. So 1937 is applied and correct as far as it goes; this is the
-- column it did not carry across, not work it will redo.
--
-- 1937 is confirmed applied in prod before this migration touches anything: the guard below
-- refuses unless 04d2e529 is already retired.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- THE IMAGE IS HIS, AND THAT IS PROVED BY BYTES, NOT BY A FILENAME.
--
-- The object we hold is named for the RETIRED row (04d2e529-...-headshot.png) because that is
-- the row it was imported to, before 1937 moved it. That mismatch is what made this look like a
-- merge in the first place.
--
-- 🟢 sha256 OF OUR OBJECT AND OF THE CAMPAIGN SITE'S FILE ARE THE SAME: dde5827d1f06b0b64b664a65,
-- both 943,570 bytes, both 640x640 PNG. Our copy is not a lookalike or a re-encode; it is that
-- file. Source: https://demsforbenton.com/joehusk.png, the single portrait on his own campaign
-- page https://demsforbenton.com/about-joe/ ("About Joe Husk" -- Benton Township, Monroe County,
-- Indiana, in his own words "I am running for re-election"). The only other image on that page
-- is the site's 90x90 avatar. Candidate publishing his own photograph, which is the press_use
-- convention already recorded on the image row.
--
-- 🟢 AND IT SCORES, MEASURED WITH THE GATE'S OWN LIBRARY rather than eyeballed:
--     verdict=OK  best=0.943  upright=0.943   (FACE_BAR is 0.80)
-- The same run scored Langford 0.937 and, as a negative control, the WRD HTML page that CC_0284
-- removed came back UNDECODABLE -- reproducing CI's verdict locally, so the two passes are not
-- a detector that says OK to everything.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- WHAT CHANGES, ON THE SURVIVOR ONLY.
--
--   photo_custom_url  NULL  ->  the bucket object his politician_images row already points at
--   photo_origin_url  NULL  ->  https://demsforbenton.com/joehusk.png
--
-- 🔴 THE PROVENANCE URL IS THE IMAGE FILE, NOT THE PAGE. The retired row carries
-- photo_origin_url = 'https://demsforbenton.com/about-joe/', which is an HTML page. Copying that
-- across is exactly the defect CC_0284 had just finished removing from Joy Langford -- a page URL
-- in a column every read path treats as an image. The /joehusk.png file is what goes in.
--
-- NOT TOUCHED, each for a reason:
-- ▶ THE RETIRED ROW 04d2e529 KEEPS ITS SCALARS. is_active = false, so no read path and no gate
--   reaches them, and they are the provenance of where this image came from. Blanking an
--   archived row to tidy it would destroy the record 1937 deliberately kept.
-- ▶ THE STORAGE OBJECT IS NOT RENAMED to match the survivor's uuid. A copy-and-repoint buys
--   nothing a voter can see, risks the CDN serving the old bytes, and would erase the one signal
--   that says this image arrived through a merge. The mismatch is documented here instead.
-- ▶ politician_images.url and photo_license ('press_use') are already correct.
-- ▶ race_candidates.photo_url -- both of his candidacy rows have it NULL (verified), so the
--   column that outranks everything on ballot pages is empty. Nothing to clear.
--
-- ⚠ EXPECTED SIDE EFFECT, AND IT IS THE POINT: this makes him VISIBLE to the nightly full-corpus
-- face sweep for the first time, because that sweep also selects on the scalar. He will be
-- fetched and scored from Sunday on. He scores 0.943, measured above, so he should pass -- but
-- being checked at all is the improvement here, not the score.
--
-- Idempotent: re-running changes nothing.

BEGIN;

-- Guard: the survivor is who this migration researched, 1937 has actually run, and the image
-- row is the one whose bytes were verified.
DO $$
DECLARE v_name text; v_active bool; v_incumbent bool; v_imgs int; v_url text;
        v_custom text; v_origin text; n_rc int; v_dup_active bool;
  c_obj CONSTANT text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/04d2e529-5456-44bb-a20f-b1ec676c2c22-headshot.png';
  c_src CONSTANT text := 'https://demsforbenton.com/joehusk.png';
BEGIN
  SELECT p.full_name, p.is_active, p.is_incumbent, p.photo_custom_url, p.photo_origin_url
    INTO v_name, v_active, v_incumbent, v_custom, v_origin
    FROM essentials.politicians p WHERE p.id = '85194f5e-6574-4371-97da-f1cc89568870'::uuid;

  IF v_name IS NULL THEN
    RAISE EXCEPTION 'CC_0285: the survivor row does not exist';
  END IF;
  IF v_name <> 'Joseph G Husk' THEN
    RAISE EXCEPTION 'CC_0285: survivor resolves to "%", expected "Joseph G Husk"', v_name;
  END IF;
  IF NOT v_active THEN
    RAISE EXCEPTION 'CC_0285: the survivor is not active - publishing a photo for a retired '
                    'row is not what this migration is for, REFUSING';
  END IF;

  -- 🔴 THIS MIGRATION ASSUMES 1937 HAS RUN. If the merge has not happened, the image row it
  -- relies on is still on the other person row and this would write a scalar pointing at an
  -- image the survivor does not own.
  SELECT p.is_active INTO v_dup_active
    FROM essentials.politicians p WHERE p.id = '04d2e529-5456-44bb-a20f-b1ec676c2c22'::uuid;
  IF v_dup_active IS NULL THEN
    RAISE EXCEPTION 'CC_0285: the duplicate row 04d2e529 does not exist - the merge this '
                    'migration builds on is not the one that ran, REFUSING';
  END IF;
  IF v_dup_active THEN
    RAISE EXCEPTION 'CC_0285: the duplicate row 04d2e529 is still ACTIVE, so migration 1937 '
                    'has not been applied. Apply the merge first, REFUSING';
  END IF;

  SELECT count(*) INTO v_imgs FROM essentials.politician_images pi
   WHERE pi.politician_id = '85194f5e-6574-4371-97da-f1cc89568870'::uuid AND pi.type = 'default';
  IF v_imgs <> 1 THEN
    RAISE EXCEPTION 'CC_0285: he has % default images, expected exactly 1', v_imgs;
  END IF;

  -- The scalar must point at the frame whose bytes were checked, not at whatever is there now.
  SELECT pi.url INTO v_url FROM essentials.politician_images pi
   WHERE pi.politician_id = '85194f5e-6574-4371-97da-f1cc89568870'::uuid AND pi.type = 'default';
  IF v_url IS DISTINCT FROM c_obj THEN
    RAISE EXCEPTION 'CC_0285: his default image is "%", not the object this migration verified '
                    'by sha256 - REFUSING to point the scalar at an unexamined image', v_url;
  END IF;

  IF v_custom IS NOT NULL AND v_custom IS DISTINCT FROM c_obj THEN
    RAISE EXCEPTION 'CC_0285: photo_custom_url is already "%", neither NULL nor the bucket '
                    'object - somebody else has set it, REFUSING', v_custom;
  END IF;
  IF v_origin IS NOT NULL AND v_origin IS DISTINCT FROM c_src THEN
    RAISE EXCEPTION 'CC_0285: photo_origin_url is already "%", neither NULL nor the campaign '
                    'image - REFUSING', v_origin;
  END IF;

  SELECT count(*) INTO n_rc FROM essentials.race_candidates rc
   WHERE rc.politician_id = '85194f5e-6574-4371-97da-f1cc89568870'::uuid
     AND rc.photo_url IS NOT NULL;
  IF n_rc <> 0 THEN
    RAISE EXCEPTION 'CC_0285: % candidacy row(s) carry their own photo_url, which would '
                    'OUTRANK this image on ballot pages - unexpected, REFUSING', n_rc;
  END IF;
END $$;

-- The survivor only. The retired row keeps its scalars as provenance.
UPDATE essentials.politicians p
SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/04d2e529-5456-44bb-a20f-b1ec676c2c22-headshot.png',
    photo_origin_url = 'https://demsforbenton.com/joehusk.png'
WHERE p.id = '85194f5e-6574-4371-97da-f1cc89568870'::uuid;

-- post-verify
DO $$
DECLARE v_custom text; v_origin text; v_served text; n_seen int; v_dup_custom text;
  c_obj CONSTANT text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/04d2e529-5456-44bb-a20f-b1ec676c2c22-headshot.png';
  c_src CONSTANT text := 'https://demsforbenton.com/joehusk.png';
BEGIN
  SELECT p.photo_custom_url, p.photo_origin_url,
         NULLIF(COALESCE(p.photo_custom_url, p.photo_origin_url), '')
    INTO v_custom, v_origin, v_served
    FROM essentials.politicians p WHERE p.id = '85194f5e-6574-4371-97da-f1cc89568870'::uuid;

  IF v_custom IS DISTINCT FROM c_obj THEN
    RAISE EXCEPTION 'CC_0285: photo_custom_url is "%", expected the bucket object', v_custom;
  END IF;
  IF v_origin IS DISTINCT FROM c_src THEN
    RAISE EXCEPTION 'CC_0285: photo_origin_url is "%", expected the campaign image', v_origin;
  END IF;

  -- 🔴 THE END STATE THAT MATTERS, asserted in the GATE'S OWN SHAPE. The full-corpus sweep
  -- selects COALESCE(photo_custom_url, photo_origin_url) LIKE the bucket path. Before this
  -- migration he matched NOTHING and was never checked; now he must be selected. This is the
  -- defect being fixed, so it is asserted rather than assumed.
  SELECT count(*) INTO n_seen FROM essentials.politicians p
   WHERE p.id = '85194f5e-6574-4371-97da-f1cc89568870'::uuid
     AND p.is_active = true
     AND NULLIF(COALESCE(p.photo_custom_url, p.photo_origin_url), '')
         LIKE '%supabase.co/storage/v1/object/public/%';
  IF n_seen <> 1 THEN
    RAISE EXCEPTION 'CC_0285: the full-corpus face sweep still does not select him '
                    '(% rows) - he would stay invisible, which is the whole defect', n_seen;
  END IF;

  -- He must NOT enter the off-site slice: the scalar resolves inside our bucket.
  IF v_served NOT LIKE '%supabase.co/storage/v1/object/public/%' THEN
    RAISE EXCEPTION 'CC_0285: the scalar serves "%", which the nightly would flag as an '
                    'off-site link', v_served;
  END IF;

  -- The retired row is left exactly as 1937 left it.
  SELECT p.photo_custom_url INTO v_dup_custom
    FROM essentials.politicians p WHERE p.id = '04d2e529-5456-44bb-a20f-b1ec676c2c22'::uuid;
  IF v_dup_custom IS NULL THEN
    RAISE EXCEPTION 'CC_0285: the retired row lost its photo_custom_url - this migration must '
                    'not touch the archived provenance';
  END IF;

  RAISE NOTICE 'CC_0285 OK - Husk renders his campaign portrait and the face gate can now see him';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE THIS ROW PAID FOR: A MERGE THAT MOVES images[] AND NOT THE SCALAR LEAVES A PERSON
-- BLANK, AND BLANK IS THE STATE NO DETECTOR LOOKS AT. 1937's post-check asked "does the survivor
-- have an image row?" and got yes. The render path asks a different question and got NULL. Both
-- were true at once for two days and the only symptom was an empty square.
-- ⚠ A LOUD DEFECT GETS FIXED; A SILENT ONE WAITS. Langford served an HTML page and the gate
-- screamed for three nights. Husk served nothing, and the same gate could not select him at all.
-- The quieter failure is the one that needs a query to find, not a nightly.
-- ▶ WHEN A MERGE MOVES AN IMAGE, MOVE photo_custom_url AND photo_origin_url WITH IT, and assert
-- the survivor is SELECTED by the face sweep afterwards -- not merely that a row exists.
-- ───────────────────────────────────────────────────────────────────────────────────────────
