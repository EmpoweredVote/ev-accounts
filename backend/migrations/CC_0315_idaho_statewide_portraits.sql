-- CC_0315_idaho_statewide_portraits.sql
-- Portraits for the two statewide officers seated by CC_0311, closing the Idaho wave's
-- portrait coverage at 122 of 123 seats.
--
-- Record: backend/data/seed-id-legislature-2026/ROSTERS.md
--
--   State Controller                       Brandon D. Woolf     sco.idaho.gov
--   Superintendent of Public Instruction   Debbie Critchfield   sde.idaho.gov
--
-- The one seat still without a portrait is the Ada County SHERIFF, and that is deliberate —
-- his office publishes a departmental logo and no photograph. CC_0314's gate asserts he stays
-- blank, and this migration does not touch him.
--
-- ═══ ALL THREE FIELDS, AND WHY ═══
--
--   politicians.photo_custom_url   THE FIELD THAT RENDERS. The address-search read path builds
--                                  its photo from COALESCE(photo_custom_url, photo_origin_url)
--                                  and never reads politician_images.
--   essentials.politician_images   carries photo_license, which the API returns to the frontend,
--                                  and the grid reads images[] FIRST.
--   politicians.photo_origin_url   provenance: the page the photograph came from.
--
-- ═══ 🔴 BOUND BY SEAT, NEVER BY NAME ═══
--
-- Both rows resolve through (government, chamber, office title) -> office ->
-- office_current_holder, and the gate asserts the resolved name is the one this file was
-- written against. The Idaho wave already contains a live name collision — production holds a
-- second Mark Harris who is the U.S. Representative for North Carolina's 8th district — so
-- name-bound photo writes are not used anywhere in this wave.
--
-- ═══ 🔴 BOTH WERE LOOKED AT, AND BOTH ALTS NAME THEIR SUBJECT ═══
--
-- Nothing in this repo asks whether a headshot contains a face. Both were rendered in the
-- production 4:5 frame and inspected before this file was written; both are genuine, distinct
-- individual headshots. Neither filename is positional, and each page's own alt attribute names
-- the person AND the office:
--   alt="State Controller Brandon D Woolf Photo"      -> BrandonWoolf-2391-web-cropped.png
--   alt="Superintendent Debbie Critchfield headshot"  -> Debbie-Critchfield-HP.webp
--
-- ⚠ THE CONTROLLER'S PORTRAIT IS 135x133 AND THAT IS NOT A SCRAPING ERROR. It is the ONLY size
--   any Idaho state source publishes: the SCO home page serves exactly one image of him, the
--   un-cropped and un-suffixed variants of that filename all 404, the office has no bio page,
--   Ballotpedia has no page for him under any of four name forms (all soft-404s served as HTTP
--   200), and Wikimedia Commons has nothing — its two hits for "Brandon Woolf" are a 1910s
--   genealogy book and an unrelated military exercise photograph. It upscales softly in the 4:5
--   frame but the face is centred and unmistakably his. ▶ Worth replacing if the office ever
--   publishes a larger one; it is not worth leaving the seat blank over.
--
-- ⚠ FORMATS ARE NATIVE, NOT RE-ENCODED. One PNG and one WebP, stored as published — converting
--   to JPEG would be a generational loss for nothing. Both are already precedented in this
--   column: production carries 87 png and 22 webp default images alongside the jpgs.
--
-- ═══ LICENCE ═══
--
-- press_use for both: these are the officeholders' own agencies' official photographs of their
-- own elected principals. Not federal works, no free licence.
--
-- ⚠ Mirrored into Supabase storage, not hotlinked.

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_seated int; v_already int;
BEGIN
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'State of Idaho'
     AND c.name IN ('State Controller', 'Superintendent of Public Instruction');
  IF v_seated <> 2 THEN
    RAISE EXCEPTION 'CC_0315 pre-flight: expected 2 seated statewide offices from CC_0311, found % — apply CC_0311 first', v_seated;
  END IF;

  SELECT count(*) INTO v_already FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE p.source LIKE '%(CC_0311)%' AND pi.type = 'default';
  IF v_already <> 0 THEN
    RAISE EXCEPTION 'CC_0315 pre-flight: % statewide officer(s) already carry a default image', v_already;
  END IF;
END $$;

-- ── Portraits, bound by seat ──────────────────────────────────────────────────
CREATE TEMP TABLE id_exec_photos(
  chamber text NOT NULL,
  title   text NOT NULL,
  expect  text NOT NULL,
  file    text NOT NULL,
  origin  text NOT NULL,
  politician_id uuid
) ON COMMIT DROP;

INSERT INTO id_exec_photos(chamber, title, expect, file, origin) VALUES
  ('State Controller', 'State Controller', 'Brandon D. Woolf',
   'id-statewide-2026/controller.png', 'https://www.sco.idaho.gov/'),
  ('Superintendent of Public Instruction', 'Superintendent of Public Instruction', 'Debbie Critchfield',
   'id-statewide-2026/superintendent.webp', 'https://www.sde.idaho.gov/');

UPDATE id_exec_photos h SET politician_id = och.politician_id
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE g.name = 'State of Idaho' AND c.name = h.chamber AND o.title = h.title;

-- 🔴 Every row must have resolved, and the resolved NAME must be the one this file was written
--    against. That second test is what makes the seat-binding meaningful rather than decorative.
DO $$
DECLARE v_null int; v_wrong int; r record;
BEGIN
  SELECT count(*) INTO v_null FROM id_exec_photos WHERE politician_id IS NULL;
  IF v_null <> 0 THEN RAISE EXCEPTION 'CC_0315: % portrait row(s) did not resolve to a seated person', v_null; END IF;

  v_wrong := 0;
  FOR r IN SELECT h.expect, p.full_name, h.file FROM id_exec_photos h
             JOIN essentials.politicians p ON p.id = h.politician_id
            WHERE p.full_name <> h.expect LOOP
    RAISE WARNING 'CC_0315: % resolves to % — the seat has turned over since this file was written', r.file, r.full_name;
    v_wrong := v_wrong + 1;
  END LOOP;
  IF v_wrong <> 0 THEN
    RAISE EXCEPTION 'CC_0315: % portrait(s) resolve to a different person than this file was '
                    'written against. Re-read the roster before writing faces.', v_wrong;
  END IF;
END $$;

-- 1. THE FIELD THAT RENDERS.
UPDATE essentials.politicians p
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/' || h.file
  FROM id_exec_photos h WHERE p.id = h.politician_id;

-- 2. The images row the grid reads FIRST, carrying the licence the API returns.
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT h.politician_id,
       'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/' || h.file,
       'default', 'press_use'
  FROM id_exec_photos h
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                    WHERE pi.politician_id = h.politician_id AND pi.type = 'default');

-- 3. Provenance. Written last, never into the render position.
UPDATE essentials.politicians p SET photo_origin_url = h.origin
  FROM id_exec_photos h WHERE p.id = h.politician_id;

-- ── Post-verify gate ──────────────────────────────────────────────────────────
DO $$
DECLARE v_custom int; v_img int; v_disagree int; v_lic int; v_wave int; v_sheriff int;
BEGIN
  SELECT count(*) INTO v_custom FROM essentials.politicians p
   WHERE p.photo_custom_url LIKE '%/politician_photos/id-statewide-2026/%';
  IF v_custom <> 2 THEN RAISE EXCEPTION 'CC_0315 gate: expected 2 photo_custom_url on the CDN, found %', v_custom; END IF;

  SELECT count(*) INTO v_img FROM essentials.politician_images pi
   WHERE pi.type = 'default' AND pi.url LIKE '%/politician_photos/id-statewide-2026/%';
  IF v_img <> 2 THEN RAISE EXCEPTION 'CC_0315 gate: expected 2 default politician_images rows, found %', v_img; END IF;

  -- 🔴 BOTH fields must agree, SCOPED TO THIS MIGRATION'S PREFIX. A whole-bucket predicate here
  --    sweeps every earlier wave: CC_0314's first draft did exactly that and failed on 26
  --    pre-existing rows with UUID filenames that had nothing to do with Idaho.
  SELECT count(*) INTO v_disagree FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE pi.type = 'default' AND pi.url LIKE '%/politician_photos/id-statewide-2026/%'
     AND coalesce(p.photo_custom_url,'') <> pi.url;
  IF v_disagree <> 0 THEN
    RAISE EXCEPTION 'CC_0315 gate: % row(s) have photo_custom_url disagreeing with their default '
                    'politician_images url — the grid and the API would show different faces', v_disagree;
  END IF;

  SELECT count(*) INTO v_lic FROM essentials.politician_images pi
   WHERE pi.url LIKE '%/politician_photos/id-statewide-2026/%' AND coalesce(pi.photo_license,'') <> 'press_use';
  IF v_lic <> 0 THEN RAISE EXCEPTION 'CC_0315 gate: % statewide image(s) carry the wrong licence', v_lic; END IF;

  -- The whole Idaho wave: 123 seats, 122 now carrying a portrait.
  SELECT count(p.photo_custom_url) INTO v_wave
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE (g.name = 'State of Idaho'
          AND c.name IN ('Idaho Senate','Idaho House of Representatives',
                         'State Controller','Superintendent of Public Instruction'))
      OR g.name IN ('City of Boise, Idaho, US', 'Ada County, Idaho, US');
  IF v_wave <> 122 THEN
    RAISE EXCEPTION 'CC_0315 gate: expected 122 of the Idaho wave''s 123 seats to carry a portrait, found %', v_wave;
  END IF;

  -- 🔴 The Ada County Sheriff must STILL be the one blank, and blank on purpose. If this ever
  --    becomes 1 it was a deliberate act — his office publishes a departmental logo, not a face.
  SELECT count(p.photo_custom_url) INTO v_sheriff FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'Ada County, Idaho, US' AND o.title = 'Sheriff';
  IF v_sheriff <> 0 THEN
    RAISE EXCEPTION 'CC_0315 gate: the Ada County Sheriff now carries a photo_custom_url. His '
                    'office publishes a departmental logo and no portrait — check it is a face, '
                    'not a badge.';
  END IF;

  RAISE NOTICE 'CC_0315 OK: 2 statewide portraits written; the Idaho wave is 122 of 123, the one blank being the Ada County Sheriff, deliberately.';
END $$;
