-- CC_0305_honolulu_hi_headshots.sql
-- Portraits for the eleven City and County of Honolulu officeholders seeded by CC_0304.
--
-- ═══ ALL THREE FIELDS, AND WHY ═══
--
--   politicians.photo_custom_url   THE FIELD THAT RENDERS. The address-search read path builds
--                                  its photo from COALESCE(photo_custom_url, photo_origin_url)
--                                  and never reads politician_images. An importer that wrote only
--                                  an image row has reported "imported N, failed 0" while
--                                  changing nothing a voter could see.
--   essentials.politician_images   carries photo_license, which the API returns to the frontend,
--                                  so attribution travels with the record. The grid reads
--                                  images[] FIRST, so a row here that disagreed with the scalar
--                                  would win in one surface and lose in the other.
--   politicians.photo_origin_url   provenance: the page the photograph was found on. Written
--                                  AFTER the render field, never instead of it — a source page in
--                                  the render position hands an HTML document to an <img src>.
--
-- ═══ THE IMAGES ARE MIRRORED, NOT HOTLINKED ═══
--
-- All eleven live in Supabase storage under politician_photos/honolulu-2026/, uploaded and read
-- back over their public URLs by scripts/upload-honolulu-headshots.mjs.
--
-- 🔴 MIRRORING IS NOT CEREMONY HERE — ONE SOURCE URL WAS ALREADY DEAD. HoLIS, the city's own GIS,
--    publishes a PhotoURL for District I that returns 404 at every size offered. Andria Tupola's
--    portrait had to come from the second photo field in the same layer. Had these been hotlinked,
--    her photo would have been a broken image on day one.
--
-- ═══ 🔴 LICENCE ═══
--
-- `press_use` for all eleven. Each is the officeholder's own government publishing its own
-- official: the nine councilmembers from HoLIS and the council's own member pages, the Mayor from
-- honolulu.gov/mayor, the Prosecuting Attorney from his department's own biography page. None is
-- a federal work and none carries a free licence, so none is public domain.
--
-- ═══ 🔴 EVERY ONE OF THESE WAS LOOKED AT, AND THAT CAUGHT A FAILURE ═══
--
-- Nothing in this repo asks whether a headshot contains a face — a seal, a map, a blank or a
-- torso passes every automated check. So all eleven were rendered to a contact sheet and
-- inspected before this file was written, and the inspection earned its keep:
--
--   🔴 THE FIRST IMAGE TAKEN FOR THE PROSECUTING ATTORNEY WAS THE DEPARTMENT SEAL. The
--      prosecutor's landing page offers `fotor_2023-3-17_14_11_23.png`, whose filename says
--      nothing, alongside several files actually named `seal`. The fotor file IS the seal. It
--      would have shipped as Steven Alm's face. The real portrait is `alm.jpg`, on the
--      department's own "The Prosecutor" page.
--
-- ⚠ TWO SHAPE NOTES, both deliberate:
--   - Alm's source is a 1200x628 letterboxed banner, not a portrait. It was cropped with
--     scripts/headshot-smartcrop.py (subject-aware, crop-then-resize) to 600x750 at x@405, and the
--     result was looked at again. A centred crop would have been off-subject.
--   - Tupola's only live image is a transparent cut-out. It is flattened onto white, because a
--     transparent PNG over a dark page reads as a silhouette.
--
-- ⚠ Two portraits are small at source — Augie Tulba 425x425 and Tommy Waters 543x543. They are
--   mirrored at the largest size their publisher offers. Upscaling was not done and should not be.

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_people int; v_already int;
BEGIN
  SELECT count(*) INTO v_people
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City and County of Honolulu, Hawaii, US';
  IF v_people <> 11 THEN
    RAISE EXCEPTION 'CC_0305 pre-flight: expected 11 seated Honolulu officeholders from CC_0304, '
                    'found % — run CC_0304 first', v_people;
  END IF;

  SELECT count(*) INTO v_already
    FROM essentials.politician_images pi
    JOIN essentials.office_current_holder och ON och.politician_id = pi.politician_id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City and County of Honolulu, Hawaii, US';
  IF v_already <> 0 THEN
    RAISE EXCEPTION 'CC_0305 pre-flight: % Honolulu officeholder(s) already carry an image row — '
                    'read them before overwriting', v_already;
  END IF;
END $$;

CREATE TEMP TABLE hnl_photos(
  politician_id uuid PRIMARY KEY,
  who           text NOT NULL,
  file          text NOT NULL,
  origin        text NOT NULL
) ON COMMIT DROP;

INSERT INTO hnl_photos(politician_id, who, file, origin) VALUES
  ('b27e2c51-799a-45f8-ac0d-77d9668a0d6c', 'Andria Tupola',        'andria-tupola.jpg',
   'https://www.honolulucitycouncil.org/district-1-tupola'),
  ('ec8a37c8-079f-4ea1-be92-219f5729c67d', 'Matt Weyer',           'matt-weyer.jpg',
   'https://www.honolulucitycouncil.org/district-2-weyer'),
  ('c6d07dcb-28e7-4a7f-8524-5de58a75e16a', E'Esther Kiaʻāina', 'esther-kiaaina.jpg',
   'https://www.honolulucitycouncil.org/district-3-kiaaina'),
  ('2109d801-2f06-4239-bf3f-4c7557da3c46', 'Thomas Waters',        'tommy-waters.jpg',
   'https://www.honolulucitycouncil.org/district4'),
  ('6ab2c8fb-0e15-4273-af14-e3272f869440', 'Scott Y. Nishimoto',   'scott-nishimoto.jpg',
   'https://www.honolulucitycouncil.org/district-5-scott-nishimoto'),
  ('16bb0f57-1951-480d-9497-e42b272e8d54', 'Tyler Dos Santos-Tam', 'tyler-dos-santos-tam.jpg',
   'https://www.honolulucitycouncil.org/district-6-dos-santos-tam'),
  ('d5fb6752-965c-4c37-a240-2ac383de5f0d', 'Radiant Cordero',      'radiant-cordero.jpg',
   'https://www.honolulucitycouncil.org/district-7-cordero'),
  ('668002be-eac2-411a-97b9-ecfc5afc748d', 'Val Aquino Okimoto',   'val-aquino-okimoto.jpg',
   'https://www.honolulucitycouncil.org/district-8-okimoto-1'),
  ('d6a94dac-32af-4bb8-b130-dbfcff6a4de7', 'Augusto E. Tulba',     'augie-tulba.jpg',
   'https://www.honolulucitycouncil.org/district-9-tulba'),
  ('72847666-abf3-40f0-89bf-4625d34a4d1a', 'Rick Blangiardi',      'rick-blangiardi.jpg',
   'https://www.honolulu.gov/mayor/'),
  ('7c5cdd65-7464-4db1-9e6a-852f708bb586', 'Steven S. Alm',        'steven-alm.jpg',
   'https://honoluluprosecutor.org/department/the-prosecutor/');

-- Guard the join before writing anything: an id that does not resolve, or resolves to somebody
-- whose name has moved, means this file is stale.
DO $$
DECLARE v_miss int; v_mismatch text;
BEGIN
  SELECT count(*) INTO v_miss FROM hnl_photos h
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = h.politician_id);
  IF v_miss <> 0 THEN
    RAISE EXCEPTION 'CC_0305: % politician id(s) in this file do not exist', v_miss;
  END IF;

  SELECT string_agg(format('%s is now %L', h.who, p.full_name), '; ') INTO v_mismatch
    FROM hnl_photos h JOIN essentials.politicians p ON p.id = h.politician_id
   WHERE p.full_name <> h.who;
  IF v_mismatch IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0305: a photo is bound to an id whose name has changed — %', v_mismatch;
  END IF;
END $$;

-- 1. The field that renders.
UPDATE essentials.politicians p
   SET photo_custom_url =
       'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/honolulu-2026/'
       || h.file
  FROM hnl_photos h
 WHERE p.id = h.politician_id;

-- 2. The image row, which carries the licence to the frontend.
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT h.politician_id,
       'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/honolulu-2026/'
       || h.file,
       'default',
       'press_use'
  FROM hnl_photos h
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politician_images pi
    WHERE pi.politician_id = h.politician_id AND pi.type = 'default');

-- 3. Provenance. Written last, and never into the render position.
UPDATE essentials.politicians p
   SET photo_origin_url = h.origin
  FROM hnl_photos h
 WHERE p.id = h.politician_id;

-- ── Post-verify gate ──────────────────────────────────────────────────────────
DO $$
DECLARE
  v_custom int; v_images int; v_origin int; v_lic int; v_disagree int; v_htmlish int;
BEGIN
  SELECT count(*) INTO v_custom FROM hnl_photos h
    JOIN essentials.politicians p ON p.id = h.politician_id
   WHERE p.photo_custom_url LIKE 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/honolulu-2026/%';
  IF v_custom <> 11 THEN
    RAISE EXCEPTION 'CC_0305 gate: expected 11 photo_custom_url values on the CDN, found %', v_custom;
  END IF;

  SELECT count(*) INTO v_images FROM hnl_photos h
    JOIN essentials.politician_images pi ON pi.politician_id = h.politician_id AND pi.type = 'default';
  IF v_images <> 11 THEN
    RAISE EXCEPTION 'CC_0305 gate: expected 11 default image rows, found %', v_images;
  END IF;

  -- 🔴 The grid reads images[] first and the backend reads the scalar. If they disagree, one
  --    surface shows a different face from the other and nothing errors.
  SELECT count(*) INTO v_disagree FROM hnl_photos h
    JOIN essentials.politicians p ON p.id = h.politician_id
    JOIN essentials.politician_images pi ON pi.politician_id = h.politician_id AND pi.type = 'default'
   WHERE pi.url IS DISTINCT FROM p.photo_custom_url;
  IF v_disagree <> 0 THEN
    RAISE EXCEPTION 'CC_0305 gate: % row(s) have politician_images.url disagreeing with '
                    'photo_custom_url — the grid and the API would show different photos', v_disagree;
  END IF;

  SELECT count(*) INTO v_lic FROM hnl_photos h
    JOIN essentials.politician_images pi ON pi.politician_id = h.politician_id AND pi.type = 'default'
   WHERE pi.photo_license <> 'press_use';
  IF v_lic <> 0 THEN
    RAISE EXCEPTION 'CC_0305 gate: % image row(s) are missing the press_use licence', v_lic;
  END IF;

  SELECT count(*) INTO v_origin FROM hnl_photos h
    JOIN essentials.politicians p ON p.id = h.politician_id
   WHERE p.photo_origin_url = h.origin;
  IF v_origin <> 11 THEN
    RAISE EXCEPTION 'CC_0305 gate: expected 11 photo_origin_url values, found %', v_origin;
  END IF;

  -- A source PAGE in the render position hands an HTML document to an <img src>.
  SELECT count(*) INTO v_htmlish FROM hnl_photos h
    JOIN essentials.politicians p ON p.id = h.politician_id
   WHERE p.photo_custom_url NOT LIKE '%.jpg';
  IF v_htmlish <> 0 THEN
    RAISE EXCEPTION 'CC_0305 gate: % photo_custom_url value(s) are not image files', v_htmlish;
  END IF;

  RAISE NOTICE 'CC_0305 OK: 11 portraits — scalar, image row and provenance all agree.';
END $$;
