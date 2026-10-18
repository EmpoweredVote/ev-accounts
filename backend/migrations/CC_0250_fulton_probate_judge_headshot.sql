-- CC_0250_fulton_probate_judge_headshot.sql
--
-- Atlanta / Fulton / DeKalb wave — recovers the SECOND of the six seats CC_0246 left blank.
--
-- Kenya M. Johnson, Chief Judge, Fulton County Probate Court.
-- CC_0246 recorded her as blank because "county probate paths 404". The paths were fine; the
-- court's site is CivicPlus and renders its roster in JS, so the portrait is absent from the
-- server HTML and invisible to curl. A RENDERED fetch finds it:
--   https://fultonprobatega.org/226/Meet-our-Executive-Team
--
-- 🔴🔴 IDENTITY WAS THE HARD PART, AND THE OBVIOUS GRAB WOULD HAVE BEEN WRONG.
-- The page carries 14 portraits whose alt attributes name NOBODY — "Fulton COnty Probate-(27 of
-- 45)", "image0", "otwy". Hers is the SMALLEST of them. Taking the largest, or the nearest by DOM
-- ancestry, would have published MARIAN PARKER'S FACE as Kenya M. Johnson:
--
--   column x   image                       native       person
--   330        documentID=198 alt "JJohn"  250x334      Kenya M. Johnson, Chief Judge
--   522        documentID=344              2080x2600    Marian Parker, Associate Judge
--   714        documentID=333              2080x2600    Myles Braxton, Chief Clerk of Court
--
-- The binding is confirmed three independent ways: a screenshot of the rendered row (names sit
-- directly beneath their portraits), column geometry (name text at x=366/531/721 against images
-- at x=330/522/714, same order, names 253px below), and the alt stem "JJohn". The lapel pin in
-- frame is the Fulton County seal, which corroborates the office.
--
-- ⚠ THREE DOM BINDERS FAILED BEFORE THE SCREENSHOT SETTLED IT, and each failed LOUDLY enough to
-- notice only because a uniform answer is never trusted here:
--   1. ancestry walk        -> bound ALL 14 images to the first name on the page, including the
--                              2200x430 page banner. It climbs into a container holding the whole
--                              team, whose innerText begins with her name.
--   2. TreeWalker over      -> returned []. querySelector('.pageContent') matched a DIFFERENT,
--      '.pageContent'          EMPTY element; the real grid is a later node with the same class.
--   3. geometric pairing    -> returned 0 names; the element filter was too strict.
-- The house rule — LOOK AT THE FRAMES — is what actually resolved it.
--
-- ⚠ UPSCALE, ACCEPTED DELIBERATELY. The 250x334 PNG is the only version served: five query-string
-- variants (&maxWidth, &width, &size, &w) all return the identical 40,624 bytes, so the
-- SC-5 "resize is in the query string" trick does not apply. Reaching the house 600x750 is a
-- 2.4x enlargement. ATL-4 refused four Fulton commissioners at 3.75x, so this sits well inside
-- that precedent; the render was inspected and reads as a real portrait, not an artifact.
-- Ruled publishable by the operator, 2026-10-18. Re-source if Fulton Probate republishes.
--
-- Geometry: 4:5 crop 250x313 at +0+11 (keeps essentially the whole frame), Lanczos3 to 600x750,
-- q90. Uploaded and VERIFIED SERVED: public URL returns HTTP 200, image/jpeg, 62,072 bytes,
-- sha256 byte-identical to the local render.
--
-- Checks re-run by hand, because framecheck.mjs is on no ref (see ROSTERS.md):
--   corner agreement 224.6 (threshold 24; a disc on flat matte scores 0)   PASS
--   colour spread     24.1 (monochrome scores ~0)                          PASS
--   eye-band skin centroid 52.4% of width (target ~50%)                    PASS
-- 🔴 The corner check first reported NaN on this file: it is a 4-channel PNG and the reader
-- strided by 3. Visible rather than silent, unlike the .stats()/.extract() bug in CC_0249.
-- Call .removeAlpha() before .raw().
--
-- 🔴 BOTH SIDES ARE WRITTEN ON PURPOSE, as in CC_0246 and CC_0249.
-- Idempotent: re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _kjohnson_headshot (
  politician_id uuid PRIMARY KEY,
  url           text NOT NULL,
  origin_url    text NOT NULL,
  photo_license text NOT NULL
) ON COMMIT DROP;

INSERT INTO _kjohnson_headshot (politician_id, url, origin_url, photo_license) VALUES
  ('460576bf-a205-4ccf-b236-320be64c9e72'::uuid,
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/460576bf-a205-4ccf-b236-320be64c9e72-headshot.jpg',
   'https://fultonprobatega.org/226/Meet-our-Executive-Team',
   'press_use');

-- Guard: the id must resolve to Kenya M. Johnson specifically. Given that the live page offers
-- two other judges' portraits at 8x the resolution, a mis-keyed row is the failure to fear.
DO $$
DECLARE v_name text;
BEGIN
  SELECT p.full_name INTO v_name
    FROM essentials.politicians p
    JOIN _kjohnson_headshot h ON h.politician_id = p.id;
  IF v_name IS NULL THEN
    RAISE EXCEPTION 'CC_0250: politician_id matches no politician row';
  END IF;
  IF v_name NOT LIKE 'Kenya%Johnson%' THEN
    RAISE EXCEPTION 'CC_0250: politician_id resolves to %, not Kenya M. Johnson', v_name;
  END IF;
END $$;

-- 1. the images[] row the grid reads
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT h.politician_id, h.url, 'default', h.photo_license
FROM _kjohnson_headshot h
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
  WHERE pi.politician_id = h.politician_id AND pi.type = 'default'
);

-- 2. the scalar the backend reads, plus provenance
UPDATE essentials.politicians p
SET photo_custom_url = h.url,
    photo_origin_url = h.origin_url
FROM _kjohnson_headshot h
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
    FROM _kjohnson_headshot h
    JOIN essentials.politician_images pi
      ON pi.politician_id = h.politician_id AND pi.type = 'default' AND pi.url = h.url;
  IF n_images <> 1 THEN
    RAISE EXCEPTION 'CC_0250: expected 1 default politician_images row, found %', n_images;
  END IF;

  SELECT count(*) INTO n_scalar
    FROM _kjohnson_headshot h
    JOIN essentials.politicians p
      ON p.id = h.politician_id AND p.photo_custom_url = h.url;
  IF n_scalar <> 1 THEN
    RAISE EXCEPTION 'CC_0250: expected 1 politicians.photo_custom_url, found %', n_scalar;
  END IF;

  SELECT count(*) INTO n_mismatch
    FROM essentials.politicians p
    JOIN essentials.politician_images pi ON pi.politician_id = p.id AND pi.type = 'default'
    JOIN _kjohnson_headshot h ON h.politician_id = p.id
   WHERE p.photo_custom_url IS DISTINCT FROM pi.url;
  IF n_mismatch <> 0 THEN
    RAISE EXCEPTION 'CC_0250: the scalar and the images[] row disagree';
  END IF;

  -- The wave's blank count must fall from 5 to exactly 4.
  SELECT count(*) INTO n_blank
    FROM essentials.governments g
    JOIN essentials.chambers ch ON ch.government_id = g.id
    JOIN essentials.offices o   ON o.chamber_id = ch.id
    JOIN essentials.office_terms t ON t.office_id = o.id AND t.term_end IS NULL
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE g.geo_id IN ('1304000','13121','13089')
     AND p.photo_custom_url IS NULL;
  IF n_blank <> 4 THEN
    RAISE EXCEPTION 'CC_0250: expected 4 blank headshots left in the wave, found %', n_blank;
  END IF;

  RAISE NOTICE 'CC_0250 OK — Kenya M. Johnson seated on both sides, 4 blanks remain';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- THE 4 STILL BLANK:
--   Fulton  - Ché Alexander (Clerk): only a circular-framed portrait and a 1920x350 banner;
--             every 4:5 cut clips her hair. A blank beats a clipped frame.
--           - Arthur E. Ferdinand (Tax): the department page answers fine with a browser UA and
--             carries NO portrait — its only hero is a 1920x350 photograph of an office SIGN.
--           - District 4 is VACANT, so it has no occupant to picture.
--   DeKalb  - Debra DeBerry (Clerk): no reachable standalone clerk site; the county path 404s.
-- ▶ Ché Alexander is now the best remaining candidate for a RENDERED fetch, which is what
--   unblocked both Probate Judges. Her site was only ever read through curl.
-- Do not fill any of these with a placeholder.
-- ───────────────────────────────────────────────────────────────────────────────────────────
