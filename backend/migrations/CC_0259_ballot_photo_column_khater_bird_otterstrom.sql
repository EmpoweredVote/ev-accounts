-- CC_0259_ballot_photo_column_khater_bird_otterstrom.sql
--
-- Closes the BALLOT-PAGE half of CC_0255 and CC_0257. Three people whose headshots were
-- already replaced were still rendering the ORIGINAL defect on every election and ballot
-- page, because the fix was written to the wrong columns.
--
--   Tayler Khater       five-person FAMILY PHOTOGRAPH   (CC_0256 removed it; CC_0257 seated a portrait)
--   Mike Bird           campaign YARD SIGN              (CC_0255 replaced it)
--   Stephen Otterstrom  campaign YARD SIGN              (CC_0255 replaced it)
--
-- 🔴 THERE ARE THREE PHOTO COLUMNS, AND THE ONE NOTHING SWEEPS WINS.
-- backend/src/lib/electionService.ts selects COALESCE(rc.photo_url, pi.url), so
-- essentials.race_candidates.photo_url OUTRANKS BOTH politicians.photo_custom_url (the
-- profile page) and the politician_images 'default' row (the browse grid).
-- check-headshot-faces.py reads only COALESCE(politicians.photo_custom_url,
-- photo_origin_url) and has never looked at this column. "Both sides written" -- the rule
-- CC_0253 onwards followed -- counted two of three sides.
--
-- 🔴 AND THE FACE GATE CANNOT SEE THE DIFFERENCE. Measured 2026-10-19 on the live objects:
--   Khater's ballot image   419x501   FIVE detected faces   -- PASSES the gate
--   Khater's fixed portrait 600x750   ONE detected face
-- A group photograph has faces in it, so the gate calls it a headshot. Counting faces is
-- what separates them, and it is cheap -- but a crowd of one is also what a WRONG person's
-- portrait looks like, so it is necessary and never sufficient.
-- Bird's and Otterstrom's yard signs score 0.00 at every rotation and WOULD have been caught,
-- had anything swept this column. Nothing does.
--
-- SCOPE, measured before writing: 135 race_candidates rows carry photo_url; 30 DISAGREE with
-- the politician's fixed scalar. A face sweep of those 30 -- run with two controls, a yard
-- sign that must FAIL and a real portrait that must PASS -- found exactly 3 graphics, all
-- three of CC_0255's yard signs. CC_0258 fixed Bowles and Crockett. This migration fixes the
-- remaining three. The other 25 divergent rows are REAL PORTRAITS, merely different crops,
-- and are deliberately left alone -- see the design note at the foot of this file.
--
-- 🔴 THE NEW URL IS DERIVED, NOT RETYPED. Each row is set to that politician's OWN
-- photo_custom_url rather than to a literal, so this migration CANNOT seat a URL that
-- disagrees with the profile page, and cannot go stale against a future ?v= bump. The guard
-- asserts identity by name and asserts that the scalar and the images[] row already agree
-- before anything is copied from them.
--
-- Nothing is uploaded and no image changes: all three portraits are already live and were
-- re-verified through the face gate at their current ?v= keys (0.90-0.95, one face each).
-- Idempotent: re-running changes nothing.
--
-- ⚠ Khater's race_candidates row is candidate_status='withdrawn' (Utah State Senate District
-- 14). The politician row is still is_active so it still renders, which is exactly why the
-- ballot photograph still matters. Whether withdrawn candidates should stay active is a
-- separate question and is NOT touched here.

BEGIN;

CREATE TEMP TABLE _ballot_fix (
  politician_id uuid PRIMARY KEY,
  name_like     text NOT NULL,
  rc_id         uuid NOT NULL          -- the ONE race_candidates row holding the defect
) ON COMMIT DROP;

-- No "it must still hold the yard sign" guard on purpose: that would make a second run FAIL
-- rather than do nothing, and idempotency is the house rule. The UPDATE is already a no-op
-- once the row agrees, and the post-verify proves the end state either way.
INSERT INTO _ballot_fix (politician_id, name_like, rc_id) VALUES
  ('28df85e8-73c8-4def-bdd1-6929ff083590'::uuid, 'Tayler Khater',
   'b2c821dc-d587-4057-a091-45a2c3f46f4e'::uuid),
  ('5d9c347b-d310-4586-b236-68b95c5e50cb'::uuid, 'Mike Bird',
   '1fe0eeed-567f-466b-945f-d1e49c30b36c'::uuid),
  ('e74bafed-c882-48dc-9dcc-36e8fa4adf23'::uuid, 'Stephen Otterstrom',
   'e231df12-8b9f-4f98-bc84-212e74db3b50'::uuid);

-- Guard: each id must resolve to the expected person; that person must already carry a fixed
-- photo on BOTH of the other two sites, agreeing with each other; and the race row must still
-- be theirs. If any of that moved, REFUSE -- do not copy a URL we have not checked.
DO $$
DECLARE r record; v_name text; v_scalar text; v_img text; v_rc_owner uuid;
BEGIN
  FOR r IN SELECT * FROM _ballot_fix LOOP
    SELECT p.full_name, p.photo_custom_url,
           (SELECT pi.url FROM essentials.politician_images pi
             WHERE pi.politician_id = p.id AND pi.type = 'default')
      INTO v_name, v_scalar, v_img
      FROM essentials.politicians p WHERE p.id = r.politician_id;

    IF v_name IS NULL THEN
      RAISE EXCEPTION 'CC_0259: % matches no politician row', r.politician_id;
    END IF;
    IF v_name <> r.name_like THEN
      RAISE EXCEPTION 'CC_0259: % resolves to "%", expected "%"', r.politician_id, v_name, r.name_like;
    END IF;
    IF v_scalar IS NULL OR v_scalar = '' THEN
      RAISE EXCEPTION 'CC_0259: % has no photo_custom_url - there is nothing fixed to copy', r.name_like;
    END IF;
    IF v_img IS DISTINCT FROM v_scalar THEN
      RAISE EXCEPTION 'CC_0259: % profile and grid disagree (scalar=%, images=%) - fix those first',
        r.name_like, v_scalar, v_img;
    END IF;
    IF v_scalar NOT LIKE '%supabase.co/storage/v1/object/public/%' THEN
      RAISE EXCEPTION 'CC_0259: % has a fixed photo outside our bucket (%)', r.name_like, v_scalar;
    END IF;

    SELECT rc.politician_id INTO v_rc_owner
      FROM essentials.race_candidates rc WHERE rc.id = r.rc_id;
    IF v_rc_owner IS NULL THEN
      RAISE EXCEPTION 'CC_0259: race_candidates row % does not exist', r.rc_id;
    END IF;
    IF v_rc_owner <> r.politician_id THEN
      RAISE EXCEPTION 'CC_0259: race_candidates row % belongs to %, not %', r.rc_id, v_rc_owner, r.name_like;
    END IF;
  END LOOP;
END $$;

-- The write: each ballot row takes that person's OWN fixed photo. Derived, never retyped.
UPDATE essentials.race_candidates rc
SET photo_url = p.photo_custom_url
FROM _ballot_fix b
JOIN essentials.politicians p ON p.id = b.politician_id
WHERE rc.id = b.rc_id
  AND rc.photo_url IS DISTINCT FROM p.photo_custom_url;

-- post-verify: all three ballot rows now serve the fixed portrait, no clerk object survives
-- for these three, and the wider defect set is empty.
DO $$
DECLARE n_fixed int; n_stale int; n_graphics int;
BEGIN
  SELECT count(*) INTO n_fixed
    FROM _ballot_fix b
    JOIN essentials.politicians p ON p.id = b.politician_id
    JOIN essentials.race_candidates rc ON rc.id = b.rc_id AND rc.photo_url = p.photo_custom_url;
  IF n_fixed <> 3 THEN
    RAISE EXCEPTION 'CC_0259: expected 3 ballot rows pointing at the fixed portrait, found %', n_fixed;
  END IF;

  SELECT count(*) INTO n_stale
    FROM essentials.race_candidates rc
    JOIN _ballot_fix b ON b.politician_id = rc.politician_id
   WHERE rc.photo_url LIKE '%/ut/candidates/%';
  IF n_stale <> 0 THEN
    RAISE EXCEPTION 'CC_0259: % row(s) for these three still serve the old clerk object', n_stale;
  END IF;

  -- The whole known defect set across CC_0255/CC_0257/CC_0258: every person whose headshot
  -- those migrations replaced must now agree on the ballot too.
  SELECT count(*) INTO n_graphics
    FROM essentials.race_candidates rc
    JOIN essentials.politicians p ON p.id = rc.politician_id
   WHERE rc.photo_url IS NOT NULL AND rc.photo_url <> ''
     AND p.id IN ('28df85e8-73c8-4def-bdd1-6929ff083590'::uuid,  -- Khater
                  '5d9c347b-d310-4586-b236-68b95c5e50cb'::uuid,  -- Bird
                  'e74bafed-c882-48dc-9dcc-36e8fa4adf23'::uuid,  -- Otterstrom
                  '0919efe0-5abc-401f-88cb-7a3e13788ff4'::uuid,  -- Crockett  (CC_0258)
                  'b71ec1b6-7d9e-406b-a30a-8c0710278d5e'::uuid)  -- Bowles    (CC_0258)
     AND rc.photo_url IS DISTINCT FROM p.photo_custom_url;
  IF n_graphics <> 0 THEN
    RAISE EXCEPTION 'CC_0259: % re-sourced person(s) still disagree on the ballot column', n_graphics;
  END IF;

  RAISE NOTICE 'CC_0259 OK - Khater, Bird and Otterstrom now serve their fixed portrait on ballot pages';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE THIS PAID FOR: ASK WHICH COLUMN THE PAGE ACTUALLY READS BEFORE CALLING A PHOTO
-- FIXED. project_photo_custom_url_is_what_renders says "write BOTH photo_custom_url and the
-- type='default' politician_images row, because the grid reads images[] first". That was
-- right and it was incomplete -- there is a THIRD reader, it is on the election path, and it
-- wins over both. A correct API response is not evidence either; read the rendered <img> on
-- each distinct page type.
--
-- ▶ OPEN DESIGN QUESTION, deliberately NOT decided here.
-- 25 race_candidates rows still hold a photo that differs from the politician's fixed one.
-- All 25 are real portraits -- a different crop, a different sitting -- not defects. Two
-- defensible answers, and they point opposite ways:
--   (a) NULL the column and let COALESCE always fall through. One source of truth; every
--       future headshot fix propagates to ballot pages for free; the divergence class cannot
--       recur. Costs 25 deliberately-chosen ballot photographs.
--   (b) Keep per-race photographs, and teach check-headshot-faces.py to sweep this column so
--       a graphic here is caught like any other. Costs a permanent second place to look.
-- Whichever is chosen, THE GATE SHOULD READ THIS COLUMN -- that part is not a trade-off.
--
-- ▶ RESOLVED THE SAME DAY, option (b): check-headshot-faces.py now sweeps BOTH columns and
--   each flagged row names the SITE that publishes it. The column is KEPT, so the 25
--   deliberately-chosen ballot photographs survive and a graphic there is caught like any
--   other. Recorded here rather than rewritten above, because the trade-off is the useful
--   part. Coverage went from 9,159 to 9,190 distinct images in the default scope (+31), and
--   9,160 to 9,199 with --all-hosts (+39); eleven of those ballot rows carry NO politician_id
--   at all, so no politician-rooted query could ever have reached them.
-- ───────────────────────────────────────────────────────────────────────────────────────────
