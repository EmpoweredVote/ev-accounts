-- CC_0249_dekalb_probate_judge_headshot.sql
--
-- Atlanta / Fulton / DeKalb wave — recovers ONE of the six seats CC_0246 left deliberately blank.
--
-- Bedelia C. Hargrove, Chief Probate Court Judge, DeKalb County.
-- CC_0246's header recorded her as blank because "county probate paths 404". That was true of the
-- paths tried; the court's own WordPress site serves a portrait under a different path, reachable
-- with an ordinary browser User-Agent.
--
-- Source: https://dekalbprobatega.com/wp-content/uploads/2020/07/Bedelia-2.jpg  (800x800)
-- Identity is established by the page itself, not by the filename: the image sits immediately
-- beside her own first-person text — "I am Bedelia C Hargrove, the Chief Probate Court Judge in
-- DeKalb County, Georgia" — on the court's own site. An alt attribute is absent, so the page
-- context is what carries the identity.
--
-- Rendered to the house geometry: centre 4:5 crop (640x800 from the 800x800 original, so nothing
-- of the subject is discarded), Lanczos3 to 600x750, quality 90. Uploaded to the politician_photos
-- bucket as <politician_id>-headshot.jpg and VERIFIED SERVED: the public URL returns HTTP 200,
-- image/jpeg, 103,845 bytes, sha256 byte-identical to the local render.
--
-- 🔴 THE CIRCULAR-SOURCE DEFECT WAS CHECKED FOR EXPLICITLY, because the gate that is supposed to
-- catch it does not exist. ROSTERS.md describes `framecheck.mjs` as a committed gate with two
-- fixtures; no such file is tracked on any ref. The checks were re-run by hand:
--   corner agreement 151.1  (a disc on flat matte scores 0; the threshold is 24)   PASS
--   colour spread     34.5  (monochrome scores ~0)                                 PASS
-- Both were run against planted controls FIRST — a synthetic disc-on-matte scored 0.0 and
-- correctly failed, a gradient scored 185.4 and correctly passed — because the first attempt at
-- this check reported all four corners byte-identical, which reads exactly like the disc defect.
-- That was a BROKEN DETECTOR: sharp's .stats() silently ignores a preceding .extract() and returns
-- whole-image statistics. Extract to a raw buffer first.
--
-- 🔴 BOTH SIDES ARE WRITTEN ON PURPOSE, as in CC_0246. The grid reads images[] first and the
-- backend reads the politicians scalar, so writing one alone is invisible on the other side.
--
-- Idempotent: re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _hargrove_headshot (
  politician_id uuid PRIMARY KEY,
  url           text NOT NULL,
  origin_url    text NOT NULL,
  photo_license text NOT NULL
) ON COMMIT DROP;

INSERT INTO _hargrove_headshot (politician_id, url, origin_url, photo_license) VALUES
  ('b43ce299-612c-44a2-8873-34106acaad86'::uuid,
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b43ce299-612c-44a2-8873-34106acaad86-headshot.jpg',
   'https://dekalbprobatega.com/',
   'press_use');

-- Guard: the id must be a live politician, and must be the DeKalb Probate Judge specifically.
DO $$
DECLARE v_name text;
BEGIN
  SELECT p.full_name INTO v_name
    FROM essentials.politicians p
    JOIN _hargrove_headshot h ON h.politician_id = p.id;
  IF v_name IS NULL THEN
    RAISE EXCEPTION 'CC_0249: politician_id matches no politician row';
  END IF;
  IF v_name NOT LIKE 'Bedelia%' THEN
    RAISE EXCEPTION 'CC_0249: politician_id resolves to %, not Bedelia C. Hargrove', v_name;
  END IF;
END $$;

-- 1. the images[] row the grid reads
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT h.politician_id, h.url, 'default', h.photo_license
FROM _hargrove_headshot h
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
  WHERE pi.politician_id = h.politician_id AND pi.type = 'default'
);

-- 2. the scalar the backend reads, plus provenance
UPDATE essentials.politicians p
SET photo_custom_url = h.url,
    photo_origin_url = h.origin_url
FROM _hargrove_headshot h
WHERE p.id = h.politician_id
  AND (p.photo_custom_url IS DISTINCT FROM h.url
    OR p.photo_origin_url IS DISTINCT FROM h.origin_url);

-- post-verify: both sides present AND agreeing with each other, or roll back.
DO $$
DECLARE
  n_images   int;
  n_scalar   int;
  n_mismatch int;
  n_blank    int;
BEGIN
  SELECT count(*) INTO n_images
    FROM _hargrove_headshot h
    JOIN essentials.politician_images pi
      ON pi.politician_id = h.politician_id AND pi.type = 'default' AND pi.url = h.url;
  IF n_images <> 1 THEN
    RAISE EXCEPTION 'CC_0249: expected 1 default politician_images row, found %', n_images;
  END IF;

  SELECT count(*) INTO n_scalar
    FROM _hargrove_headshot h
    JOIN essentials.politicians p
      ON p.id = h.politician_id AND p.photo_custom_url = h.url;
  IF n_scalar <> 1 THEN
    RAISE EXCEPTION 'CC_0249: expected 1 politicians.photo_custom_url, found %', n_scalar;
  END IF;

  SELECT count(*) INTO n_mismatch
    FROM essentials.politicians p
    JOIN essentials.politician_images pi ON pi.politician_id = p.id AND pi.type = 'default'
    JOIN _hargrove_headshot h ON h.politician_id = p.id
   WHERE p.photo_custom_url IS DISTINCT FROM pi.url;
  IF n_mismatch <> 0 THEN
    RAISE EXCEPTION 'CC_0249: the scalar and the images[] row disagree';
  END IF;

  -- The wave's blank count must fall from 6 to exactly 5.
  SELECT count(*) INTO n_blank
    FROM essentials.governments g
    JOIN essentials.chambers ch ON ch.government_id = g.id
    JOIN essentials.offices o   ON o.chamber_id = ch.id
    JOIN essentials.office_terms t ON t.office_id = o.id AND t.term_end IS NULL
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE g.geo_id IN ('1304000','13121','13089')
     AND p.photo_custom_url IS NULL;
  IF n_blank <> 5 THEN
    RAISE EXCEPTION 'CC_0249: expected 5 blank headshots left in the wave, found %', n_blank;
  END IF;

  RAISE NOTICE 'CC_0249 OK — Hargrove seated on both sides, 5 blanks remain';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- THE 5 STILL BLANK, with the reason sharpened from CC_0246's header:
--   Fulton  - Ché Alexander (Clerk): only a circular-framed portrait and a 1920x350 banner;
--             every 4:5 cut clips her hair. Unchanged — a blank beats a clipped frame.
--           - Arthur E. Ferdinand (Tax): the department page is reachable with a browser UA, but
--             carries NO portrait — its only hero is a 1920x350 photograph of an office SIGN.
--             CC_0246 recorded "site refuses automated requests"; the site answers fine, there is
--             simply no portrait on it.
--           - Kenya M. Johnson (Probate): fultonprobatega.org answers 200, but renders its content
--             in JS — neither her name nor any portrait is in the server HTML. Needs a rendered
--             fetch, which is how the DeKalb one was eventually found.
--   DeKalb  - Debra DeBerry (Clerk): no reachable standalone clerk site; the county path 404s.
--   Fulton  - District 4 is VACANT, so it has no occupant to picture.
-- Do not fill any of these with a placeholder.
-- ───────────────────────────────────────────────────────────────────────────────────────────
