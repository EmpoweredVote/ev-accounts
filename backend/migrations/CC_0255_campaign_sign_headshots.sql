-- CC_0255_campaign_sign_headshots.sql
--
-- Replaces THREE headshots that are campaign yard-sign GRAPHICS, not photographs of a person.
--
--   Traci Crockett     "TRACI CROCKETT / SALT LAKE COUNTY COUNCIL"  text on navy
--   Mike Bird          "MIKE BIRD / COUNTY COUNCIL"                 wordmark + mountain logo
--   Stephen Otterstrom "Stephen Otterstrom / HOUSE DISTRICT 21"     wordmark, 313x145
--
-- Same class as the office seals and election maps of CC_0253 -- a graphic standing in for a
-- face -- but a NEW variant: a candidate's own campaign artwork. All three are Utah candidates
-- in the 2026-11-03 general election, source='manual', photo_origin_url NULL.
--
-- 🔴 THESE WERE MISSED BY THE FIRST SWEEP, AND THE REASON IS WORTH KEEPING. All three sit on
-- the <ref>.supabase.co hostname rather than <ref>.storage.supabase.co. The sweep's predicate
-- was LIKE '%storage.supabase.co%', so 1,279 of our own files -- these among them -- were
-- classed as "hotlinked to an outside host" and never checked. Fixed in CC_0254's commit by
-- matching the PATH both hostnames share. Re-swept: 9,058 checked, 19 flagged, 3 real.
--
-- ▶ CONFIDENCE SORTS THE TRIAGE LIST. Measured across those 9,058: a frame that is genuinely
-- not a photograph of a person scores 0.00 at EVERY rotation, while a real face the detector
-- merely missed scores 0.68-0.78. All three of these scored 0.00 everywhere; the sixteen false
-- positives beside them scored 0.68 or better. It is a sort order and not a verdict -- one
-- office seal in CC_0253 did reach 0.62 -- but it puts the real defects at the top of the list.
--
-- SOURCES: BallotReady candidate pages, whose portraits are served from assets.civicengine.com.
-- BallotReady is already an established source in this corpus (politicians.source='ballotready').
-- Each file is the one THAT PERSON'S OWN PAGE DISPLAYS, never a name-derived guess -- a guessed
-- filename 403'd during this very pass, which is the cheap version of the Ballotpedia
-- wrong-person trap.
--
--   Crockett    assets.civicengine.com/uploads/candidate/headshot/325671/325671.jpg    250x250
--   Bird        .../818022/mike-bird-e9f1126c-d3e9-4df9-be77-eb708a35d59a.png        1547x1600
--   Otterstrom  .../904808/904808.jpg                                                1600x1585
--
-- ⚠ CROCKETT IS A 3.00x UPSCALE from 250x250 -- visibly soft. It is the only portrait of her in
-- policy: she did not answer the Salt Lake Tribune's candidate questionnaire, and no campaign
-- site was found on 2026-10-19. A soft photograph of the right person beats her yard sign.
--
-- All three were face-checked at four rotations after cropping (0.94-0.95 at rotation 0),
-- looked at on a contact sheet, and byte-verified served after upload.
-- 🔴 URLs carry ?v=20261019b -- overwriting a storage object does not change what the CDN
-- serves. BOTH SIDES written. Idempotent.

BEGIN;

CREATE TEMP TABLE _sign_headshots (
  politician_id uuid PRIMARY KEY,
  name_like     text NOT NULL,
  url           text NOT NULL,
  origin_url    text NOT NULL,
  photo_license text NOT NULL
) ON COMMIT DROP;

INSERT INTO _sign_headshots (politician_id, name_like, url, origin_url, photo_license) VALUES
  ('0919efe0-5abc-401f-88cb-7a3e13788ff4'::uuid, 'Traci Crockett',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0919efe0-5abc-401f-88cb-7a3e13788ff4-headshot.jpg?v=20261019b',
   'https://www.ballotready.org/people/traci-crockett', 'press_use'),
  ('5d9c347b-d310-4586-b236-68b95c5e50cb'::uuid, 'Mike Bird',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5d9c347b-d310-4586-b236-68b95c5e50cb-headshot.jpg?v=20261019b',
   'https://www.ballotready.org/people/mike-bird-e9f1126c-d3e9-4df9-be77-eb708a35d59a', 'press_use'),
  ('e74bafed-c882-48dc-9dcc-36e8fa4adf23'::uuid, 'Stephen Otterstrom',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e74bafed-c882-48dc-9dcc-36e8fa4adf23-headshot.jpg?v=20261019b',
   'https://www.ballotready.org/people/stephen-otterstrom', 'press_use');

-- Guard: every id must still resolve to the person this migration believes it is.
DO $$
DECLARE r record; v_name text;
BEGIN
  FOR r IN SELECT * FROM _sign_headshots LOOP
    SELECT p.full_name INTO v_name FROM essentials.politicians p WHERE p.id = r.politician_id;
    IF v_name IS NULL THEN
      RAISE EXCEPTION 'CC_0255: % matches no politician row', r.politician_id;
    END IF;
    IF v_name <> r.name_like THEN
      RAISE EXCEPTION 'CC_0255: % resolves to "%", expected "%"', r.politician_id, v_name, r.name_like;
    END IF;
  END LOOP;
END $$;

UPDATE essentials.politician_images pi
SET url = s.url, photo_license = s.photo_license
FROM _sign_headshots s
WHERE pi.politician_id = s.politician_id AND pi.type = 'default'
  AND (pi.url IS DISTINCT FROM s.url OR pi.photo_license IS DISTINCT FROM s.photo_license);

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT s.politician_id, s.url, 'default', s.photo_license
FROM _sign_headshots s
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
  WHERE pi.politician_id = s.politician_id AND pi.type = 'default');

UPDATE essentials.politicians p
SET photo_custom_url = s.url,
    photo_origin_url = s.origin_url
FROM _sign_headshots s
WHERE p.id = s.politician_id
  AND (p.photo_custom_url IS DISTINCT FROM s.url
    OR p.photo_origin_url IS DISTINCT FROM s.origin_url);

DO $$
DECLARE n_both int; n_mismatch int; n_multi int;
BEGIN
  SELECT count(*) INTO n_both
    FROM _sign_headshots s
    JOIN essentials.politicians p ON p.id = s.politician_id
     AND p.photo_custom_url = s.url AND p.photo_origin_url = s.origin_url
    JOIN essentials.politician_images pi ON pi.politician_id = s.politician_id
     AND pi.type = 'default' AND pi.url = s.url AND pi.photo_license = s.photo_license;
  IF n_both <> 3 THEN
    RAISE EXCEPTION 'CC_0255: expected 3 rows written on both sides, found %', n_both;
  END IF;

  SELECT count(*) INTO n_mismatch
    FROM _sign_headshots s
    JOIN essentials.politicians p ON p.id = s.politician_id
    JOIN essentials.politician_images pi ON pi.politician_id = p.id AND pi.type = 'default'
   WHERE p.photo_custom_url IS DISTINCT FROM pi.url;
  IF n_mismatch <> 0 THEN
    RAISE EXCEPTION 'CC_0255: scalar and images[] disagree for % row(s)', n_mismatch;
  END IF;

  SELECT count(*) INTO n_multi FROM (
    SELECT pi.politician_id FROM essentials.politician_images pi
    JOIN _sign_headshots s ON s.politician_id = pi.politician_id
    WHERE pi.type = 'default'
    GROUP BY pi.politician_id HAVING count(*) > 1) x;
  IF n_multi <> 0 THEN
    RAISE EXCEPTION 'CC_0255: % politician(s) carry more than one default image row', n_multi;
  END IF;

  RAISE NOTICE 'CC_0255 OK - 3 campaign-sign graphics replaced with portraits';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- STILL OWED after CC_0253 / CC_0254 / CC_0255
--   Tayler Khater -- her headshot is a FAMILY HOLIDAY PHOTOGRAPH and it is not possible to tell
--     which adult she is. Needs a real portrait, or photo_origin_url CLEARED. Left untouched.
--   Brent Bowles -- mirrored at 4.69x from 136x160 (CC_0254). Replace when a better source exists.
--   Traci Crockett -- 3.00x from 250x250, above. Same.
--   🔴 THE FACE GATE CANNOT TELL A GROUP PHOTO FROM A PORTRAIT, nor the WRONG PERSON from the
--     right one. Both still need an eye.
-- ───────────────────────────────────────────────────────────────────────────────────────────
