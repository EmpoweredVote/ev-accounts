-- CC_0251_fulton_clerk_headshot.sql
--
-- Atlanta / Fulton / DeKalb wave — recovers the THIRD of the six seats CC_0246 left blank.
--
-- Ché Alexander, Clerk of Superior Court, Fulton County.
--
-- 🔴🔴 THIS REVERSES A DELIBERATE DECISION, BECAUSE THAT DECISION RESTED ON A MEASUREMENT BUG.
-- ATL-4 recorded: "the clerk site serves only the disc on GREEN MATTE", and left her blank.
-- There is no green matte. The file is a PNG with an ALPHA CHANNEL, and the RGB stored beneath
-- fully transparent pixels is (71,112,76) — a green placeholder. Any reader that drops alpha
-- without compositing measures that green and concludes "flat coloured matte in all four
-- corners", which is exactly the disc-on-matte signature. Composite onto white instead
-- (sharp: .flatten({background:'#ffffff'}), NOT .removeAlpha()) and it is an ordinary
-- white-background studio portrait.
-- ▶ The same bug bit this migration's own author twice in one session — see CC_0250's note on
--   .stats()/.extract(), and the NaN from striding a 4-channel PNG by 3. ALPHA IS THE RECURRING
--   TRAP IN THIS WAVE'S IMAGE CHECKS.
-- ⚠ ATL-4's other finding stands and is unrelated: the 1920x350 BANNER really does clip her hair
--   at every 4:5 anchor. That was a different asset.
--
-- Source: https://fultonclerk.org/ImageRepository/Document?documentId=1979  (PNG, 1250x1250)
--   reached only by a RENDERED fetch of https://fultonclerk.org/338/Meet-Clerk-Ch-Alexander —
--   the site is CivicPlus and renders its roster in JS, as Fulton Probate's does (CC_0250).
-- Identity: the same portrait appears on /101/About-Us carrying the explicit per-image alt
--   "Clerk Alexanders Headshot", and the page text reads "Led by the Honorable Ché Alexander".
--
-- Three candidates were compared, not just the first one found:
--   documentId=1979  1250x1250  CHOSEN — subject bbox measured at x 246..1111, y 161..1102
--   documentId=4137   625x625   rejected: over-cropped, only 7px above her hair (1.1% of frame)
--                               against the house rule of ~one ear, and would need a 1.2x upscale
--   documentId=1980  2048x1366  rejected: an EVENT photo in a crowded room, and the prominent
--                               woman in it is NOT Ché Alexander. alt "528847941(1)" names nobody.
--
-- Geometry, measured rather than anchored by guesswork: subject bbox gives centre x=679 and hair
-- top y=161; crop 900x1125 (4:5) at +229+71 leaves ~90px of headroom (about one ear), then
-- Lanczos3 DOWN to 600x750 — a 0.67x downscale, so no enlargement at all. q90.
-- Uploaded and VERIFIED SERVED: HTTP 200, image/jpeg, 46,802 bytes, sha256 byte-identical.
--
-- Checks (framecheck re-implemented by hand; the committed gate is on no ref — see ROSTERS.md),
-- with alpha composited this time:
--   corner agreement — NOT APPLICABLE and deliberately not gated on. A legitimate
--     white-background cutout scores 0.0, identically to a disc on a coloured matte, because
--     every corner is the same white. ⚠ THE GATE CANNOT SEPARATE THOSE TWO CASES. This one was
--     settled by LOOKING at the frame, which is what the house rule says to do.
--   monochrome spread 27.6                                                        PASS
-- Ruled publishable by the operator, 2026-10-18, on the rendered 600x750 crop.
--
-- 🔴 BOTH SIDES ARE WRITTEN ON PURPOSE, as in CC_0246, CC_0249 and CC_0250.
-- Idempotent: re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _alexander_headshot (
  politician_id uuid PRIMARY KEY,
  url           text NOT NULL,
  origin_url    text NOT NULL,
  photo_license text NOT NULL
) ON COMMIT DROP;

INSERT INTO _alexander_headshot (politician_id, url, origin_url, photo_license) VALUES
  ('4a806638-f957-4d31-add3-d775f346a9d7'::uuid,
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4a806638-f957-4d31-add3-d775f346a9d7-headshot.jpg',
   'https://fultonclerk.org/338/Meet-Clerk-Ch-Alexander',
   'press_use');

-- Guard: the id must resolve to Ché Alexander. Her name is stored without the accent
-- ("Che' Alexander"), so match on the surname and a leading Che.
DO $$
DECLARE v_name text;
BEGIN
  SELECT p.full_name INTO v_name
    FROM essentials.politicians p
    JOIN _alexander_headshot h ON h.politician_id = p.id;
  IF v_name IS NULL THEN
    RAISE EXCEPTION 'CC_0251: politician_id matches no politician row';
  END IF;
  IF v_name NOT LIKE 'Che%Alexander%' THEN
    RAISE EXCEPTION 'CC_0251: politician_id resolves to %, not Ché Alexander', v_name;
  END IF;
END $$;

-- 1. the images[] row the grid reads
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT h.politician_id, h.url, 'default', h.photo_license
FROM _alexander_headshot h
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
  WHERE pi.politician_id = h.politician_id AND pi.type = 'default'
);

-- 2. the scalar the backend reads, plus provenance
UPDATE essentials.politicians p
SET photo_custom_url = h.url,
    photo_origin_url = h.origin_url
FROM _alexander_headshot h
WHERE p.id = h.politician_id
  AND (p.photo_custom_url IS DISTINCT FROM h.url
    OR p.photo_origin_url IS DISTINCT FROM h.origin_url);

-- post-verify: both sides present AND agreeing, or roll back.
DO $$
DECLARE
  n_images   int;
  n_scalar   int;
  n_mismatch int;
  n_blank    int;
BEGIN
  SELECT count(*) INTO n_images
    FROM _alexander_headshot h
    JOIN essentials.politician_images pi
      ON pi.politician_id = h.politician_id AND pi.type = 'default' AND pi.url = h.url;
  IF n_images <> 1 THEN
    RAISE EXCEPTION 'CC_0251: expected 1 default politician_images row, found %', n_images;
  END IF;

  SELECT count(*) INTO n_scalar
    FROM _alexander_headshot h
    JOIN essentials.politicians p
      ON p.id = h.politician_id AND p.photo_custom_url = h.url;
  IF n_scalar <> 1 THEN
    RAISE EXCEPTION 'CC_0251: expected 1 politicians.photo_custom_url, found %', n_scalar;
  END IF;

  SELECT count(*) INTO n_mismatch
    FROM essentials.politicians p
    JOIN essentials.politician_images pi ON pi.politician_id = p.id AND pi.type = 'default'
    JOIN _alexander_headshot h ON h.politician_id = p.id
   WHERE p.photo_custom_url IS DISTINCT FROM pi.url;
  IF n_mismatch <> 0 THEN
    RAISE EXCEPTION 'CC_0251: the scalar and the images[] row disagree';
  END IF;

  -- The wave's blank count must fall from 4 to exactly 3 (seated people with no photo).
  SELECT count(*) INTO n_blank
    FROM essentials.governments g
    JOIN essentials.chambers ch ON ch.government_id = g.id
    JOIN essentials.offices o   ON o.chamber_id = ch.id
    JOIN essentials.office_terms t ON t.office_id = o.id AND t.term_end IS NULL
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE g.geo_id IN ('1304000','13121','13089')
     AND p.photo_custom_url IS NULL;
  IF n_blank <> 3 THEN
    RAISE EXCEPTION 'CC_0251: expected 3 blank headshots left in the wave, found %', n_blank;
  END IF;

  RAISE NOTICE 'CC_0251 OK — Ché Alexander seated on both sides, 3 blanks remain';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- THE 3 STILL BLANK — all SEATED people with no photo (the vacant Fulton D4 is not counted,
-- because the measure joins through office_terms.politician_id):
--   Fulton  - Arthur E. Ferdinand (Tax): the department page answers fine with a browser UA and
--             carries NO portrait — its only hero is a 1920x350 photograph of an office SIGN.
--             ▶ A rendered fetch of the Tax Commissioner site has NOT been tried; it is the
--               obvious next move, since that is what recovered the other three.
--           - Fred Quinn, Jr. (Surveyor): Fulton publishes no Surveyor page at all.
--   DeKalb  - Debra DeBerry (Clerk): no reachable standalone clerk site; the county path 404s.
--             ▶ Also worth a rendered fetch before accepting.
-- Do not fill any of these with a placeholder.
-- ───────────────────────────────────────────────────────────────────────────────────────────
