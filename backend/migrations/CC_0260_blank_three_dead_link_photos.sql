-- CC_0260_blank_three_dead_link_photos.sql
--
-- Blanks THREE published photographs whose source URL is DEAD. Each one renders as a broken
-- image on a live ballot page today.
--
--   Sean Lee            404  seanlee4california.com/wp-content/uploads/2026/03/New-Project-53.webp
--   Keith W. Davis      401  gokeithdavis.com/wp-content/uploads/2026/02/Keith-Davis-Portrait-NO-BG-edited.png
--   Terry Hutchinson    403  lh3.googleusercontent.com/sitesv/AA5AbUBwH0Scz...=w1280
--
-- 🔴 FOUND ONLY BECAUSE THE GATE NOW READS race_candidates.photo_url (CC_0259 + the sweep
-- change in the same commit). All three are hotlinks to an outside host held in the ballot
-- column; `check-headshot-faces.py --external-only` could not see that column before, so
-- nothing in this repo had ever fetched these URLs. Two of the three rows carry NO
-- politician_id at all, so no politician-rooted query could have reached them either.
--
-- ⚠ A DEAD LINK WAS PROVED DEAD, NOT ASSUMED. A 403 is what a WAF returns to a robot, and a
-- previous sweep in this repo turned "you are being blocked" into "this file does not exist".
-- Each URL was re-fetched with a real browser User-Agent and with a same-origin Referer, and
-- a known-good URL was fetched alongside as a control (200). The codes did not move:
--   403 / 404 / 401 under every header combination; control 200.
-- gokeithdavis.com returns 401 for its ROOT as well - the whole site is behind auth, not just
-- the image. seanlee4california.com was REBUILT: the site is 200 and serves its portrait from
-- /assets/img/ now, so the old /wp-content/ path is genuinely gone.
-- ⚠ The first probe returned 000 for all three, which is a BROKEN PROBE and not a finding -
-- the URL list was written by python on Windows and every line carried a trailing CR.
--
-- WHY BLANK RATHER THAN RE-SOURCE. All three LOST their primaries in June 2026
-- (result='lost'), and they still render because 'lost' is not 'not_nominated'. Every
-- candidate source found is out of policy, and the numbers are stated rather than hidden:
--
--   Sean Lee     seanlee4california.com/assets/img/sean-portrait.png   500x498   x1.50
--                NOT A HEADSHOT - a cut-out of him behind a lectern with two microphones;
--                face box 85x106 in a 500px frame. Rejected on composition, not resolution.
--   Keith Davis  assets.civicengine.com/.../485075/485075.jpg          150x150   x5.00
--                Licence is fine (BallotReady/civicengine is press_use here, CC_0255/CC_0257)
--                but a 52x70 face box is a FIVE-FOLD enlargement.
--   Hutchinson   images.ivoterguide.com/candidates/092069.jpg          155x155   x4.84
--                AND iVoterGuide is an advocacy organisation's image library - not an
--                established press/official/public-domain source in this corpus.
--
-- 🔴 BOTH REJECTED UPSCALES EXCEED THE 4.69x THAT CC_0258 TREATED AS A DEFECT EARLIER TODAY.
-- Seating them would re-create, in the same session, the class of defect that migration
-- removed. A blank beats a broken link and it beats a five-fold enlargement.
-- ⚠ HONEST CAVEAT: normalised face-box sharpness did NOT condemn them - Davis 129 and
-- Hutchinson 97 both score ABOVE the portrait CC_0258 shipped for Bowles (82). That metric is
-- a WITHIN-SUBJECT before/after comparison and does not carry across subjects; a small clean
-- thumbnail has high local contrast. The rejection rests on the face-box size and the licence,
-- and the renders were looked at before deciding. Operator ruling 2026-10-19.
--
-- 🔴 BALLOTREADY SHOWED A PLACEHOLDER UNDER A CONVINCING alt. Its page for Hutchinson serves
-- www.ballotready.org/assets/headshot-placeholder.png with alt="Headshot of Terry". Reading
-- the alt would have seated a grey silhouette. READ THE src.
--
-- Nothing is deleted from storage: all three URLs point at outside hosts; we never held a copy.
-- ▶ OWED: a real portrait for each, if one ever appears. A blank is findable by every "who
-- still needs a headshot" query; a broken link reads as coverage and hides them.
-- Idempotent: re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _dead (
  rc_id     uuid PRIMARY KEY,
  name_like text NOT NULL,
  http      text NOT NULL,
  url_like  text NOT NULL
) ON COMMIT DROP;

INSERT INTO _dead (rc_id, name_like, http, url_like) VALUES
  ('17ab0959-f78f-4b3f-90e5-9c778283fa16'::uuid, 'Sean Lee',         '404', '%seanlee4california.com%'),
  ('998fb6e4-2d65-4ecd-921f-6f6d5cf3b7a3'::uuid, 'Keith W. Davis',   '401', '%gokeithdavis.com%'),
  ('3480628a-2afe-44ca-9aee-61fb136462fd'::uuid, 'Terry Hutchinson', '403', '%lh3.googleusercontent.com%');

-- Guard: each row must still be the person and the dead host this migration measured. If a
-- photo has since been replaced with something live, REFUSE -- do not blank a working image.
DO $$
DECLARE r record; v_name text; v_url text;
BEGIN
  FOR r IN SELECT * FROM _dead LOOP
    SELECT rc.full_name, rc.photo_url INTO v_name, v_url
      FROM essentials.race_candidates rc WHERE rc.id = r.rc_id;

    IF v_name IS NULL THEN
      RAISE EXCEPTION 'CC_0260: race_candidates row % does not exist', r.rc_id;
    END IF;
    IF v_name <> r.name_like THEN
      RAISE EXCEPTION 'CC_0260: % resolves to "%", expected "%"', r.rc_id, v_name, r.name_like;
    END IF;
    -- Already blank is fine (idempotent). Pointing somewhere ELSE is not.
    IF v_url IS NOT NULL AND v_url NOT LIKE r.url_like THEN
      RAISE EXCEPTION 'CC_0260: % now serves % - not the dead % host, REFUSING to blank',
        r.name_like, v_url, r.http;
    END IF;
  END LOOP;
END $$;

-- 1. the ballot column, for all three
UPDATE essentials.race_candidates rc
SET photo_url = NULL
FROM _dead d
WHERE rc.id = d.rc_id AND rc.photo_url IS NOT NULL;

-- 2. Hutchinson only: the SAME dead googleusercontent URL is in all three of his columns, so
--    his profile page is broken too. He is the only one of the three with a politician row.
UPDATE essentials.politicians p
SET photo_custom_url = NULL
WHERE p.id = 'b1314791-0f03-4a4d-8433-613072eadc66'::uuid
  AND p.photo_custom_url LIKE '%lh3.googleusercontent.com%';

-- 3. and his images[] row, which exists only to carry that dead URL. DELETE rather than
--    blank: nothing references politician_images (checked - no inbound foreign keys), and a
--    row whose url is dead is worse than no row, because the grid reads images[] FIRST.
DELETE FROM essentials.politician_images pi
WHERE pi.politician_id = 'b1314791-0f03-4a4d-8433-613072eadc66'::uuid
  AND pi.url LIKE '%lh3.googleusercontent.com%';

-- post-verify: no trace of any of the three dead hosts anywhere a reader looks.
DO $$
DECLARE n_ballot int; n_profile int; n_images int; n_left int;
BEGIN
  SELECT count(*) INTO n_ballot
    FROM essentials.race_candidates rc JOIN _dead d ON d.rc_id = rc.id
   WHERE rc.photo_url IS NOT NULL;
  IF n_ballot <> 0 THEN
    RAISE EXCEPTION 'CC_0260: % ballot row(s) still carry a photo', n_ballot;
  END IF;

  SELECT count(*) INTO n_profile FROM essentials.politicians p
   WHERE p.id = 'b1314791-0f03-4a4d-8433-613072eadc66'::uuid
     AND (p.photo_custom_url IS NOT NULL OR p.photo_origin_url IS NOT NULL);
  IF n_profile <> 0 THEN
    RAISE EXCEPTION 'CC_0260: Hutchinson still carries a profile photo reference';
  END IF;

  SELECT count(*) INTO n_images FROM essentials.politician_images pi
   WHERE pi.politician_id = 'b1314791-0f03-4a4d-8433-613072eadc66'::uuid;
  IF n_images <> 0 THEN
    RAISE EXCEPTION 'CC_0260: Hutchinson still has % politician_images row(s)', n_images;
  END IF;

  -- and nothing ELSE in the corpus points at these three dead hosts
  SELECT count(*) INTO n_left FROM (
    SELECT 1 FROM essentials.race_candidates rc
      WHERE rc.photo_url LIKE '%seanlee4california.com%'
         OR rc.photo_url LIKE '%gokeithdavis.com%'
         OR rc.photo_url LIKE '%lh3.googleusercontent.com%'
    UNION ALL
    SELECT 1 FROM essentials.politicians p
      WHERE p.photo_custom_url LIKE '%lh3.googleusercontent.com%'
         OR p.photo_origin_url LIKE '%lh3.googleusercontent.com%'
    UNION ALL
    SELECT 1 FROM essentials.politician_images pi
      WHERE pi.url LIKE '%lh3.googleusercontent.com%') x;
  IF n_left <> 0 THEN
    RAISE EXCEPTION 'CC_0260: % row(s) elsewhere still point at a dead host', n_left;
  END IF;

  RAISE NOTICE 'CC_0260 OK - three dead links blanked; no reader path serves a broken image';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE THIS PAID FOR: A LINK ROTS, AND NOTHING TOLD US.
-- Every one of these was a live, correct photograph when it was imported. No migration broke
-- them; the web did. A hotlink is not a photograph we have, it is a promise somebody else can
-- withdraw - which is the whole argument CC_0254 made for mirroring, applied to the column
-- CC_0254 could not see. 🟢 THE FIX THAT SCALES IS NOT THIS MIGRATION, it is that the gate now
-- fetches every published URL in both columns, so the next rot is caught by a sweep instead of
-- by a reader.
-- ⚠ UNREACHABLE IS NOT A FACE DEFECT and the gate reports it separately - but it is still a
-- broken image on a page, so do not let the separate bucket make it invisible.
-- ───────────────────────────────────────────────────────────────────────────────────────────
