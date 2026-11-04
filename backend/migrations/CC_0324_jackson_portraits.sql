-- CC_0324_jackson_portraits.sql
-- Jackson, Mississippi deep seed — bind the 8 approved portraits. Slot RESERVED from the allocator.
--
-- Operator-approved on a contact sheet, 2026-10-31. The objects are already uploaded to Supabase
-- Storage and byte-verified (sha256 of the re-fetched public object against the local file, with a
-- never-uploaded key as the control, which answered HTTP 400 and not an image).
-- Record: backend/data/seed-jackson-ms-2026/portraits/README.md
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 BOTH FIELDS ARE WRITTEN, AND ONLY TOGETHER DO THEY WORK.
--   * `politicians.photo_custom_url` is the scalar the backend reads;
--   * the `type='default'` row in `essentials.politician_images` is what the GRID reads, because
--     the frontend reads `images[]` FIRST.
-- A `politician_images` row on its own changes nothing a voter sees, and a scalar on its own
-- leaves the grid blank. The gate below asserts BOTH for all eight.
--
-- 🔴 BOUND BY SEAT, NEVER BY FILENAME. Ward 1's source file is named `Ashby-M-Forte.jpg` — the
-- wrong surname. The binding is the ward page the image appears on, and the join below is on the
-- POLITICIAN UUID, resolved from the office title, not on anything in the file's name.
--
-- ── SOURCE AND LICENCE ────────────────────────────────────────────────────────────────────────
-- Every image is published by the City of Jackson on its own site, so `photo_license` is
-- `press_use`, matching MS-3's Biloxi rows.
--   * the seven council portraits are ONE official sitting, uploaded 2025-11-21 at 720x780;
--   * the mayor's is `Jhorhn.jpg`, the studio headshot his own page uses.
-- ⚠ THE CUT-OUTS WERE REFUSED. Each council page renders a background-removed PNG
--   (`*-remove.bg_.png`, 552x599). The original sitting is still in the city's media library, so
--   the originals are bound instead — MS-5's Minnesota House lesson, tried FIRST this time.
--
-- ── WHAT WAS MEASURED BEFORE THE OPERATOR SAW THEM ───────────────────────────────────────────
-- 🔴 NOTHING ELSE THIS REPO RUNS ASKS WHETHER A HEADSHOT CONTAINS A FACE — a seal, a map, a blank
-- or a torso all pass. A face was detected in all eight, and the detector was first run on flat
-- grey and found none, so it can report absence. No image is monochrome (per-pixel colour spread
-- 25.8 .. 54.1). Only the mayor is enlarged (x1.245), because his is the one source smaller than
-- 600x750; the seven council portraits are downscaled. Crops are placed from the measured face
-- box, not centred.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int;
  v_photo  int;
  v_img    int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2767000 AND -2766993;
  IF v_people <> 8 THEN
    RAISE EXCEPTION 'Jackson portraits pre-flight: expected the 8 Jackson officials, found %', v_people;
  END IF;

  -- 🔴 This migration must not overwrite a photo somebody else set. There is no history table for
  -- this column, so an UPDATE is final and the previous value exists nowhere the moment it commits.
  SELECT count(*) INTO v_photo FROM essentials.politicians
   WHERE external_id BETWEEN -2767000 AND -2766993 AND coalesce(photo_custom_url, '') <> '';
  IF v_photo <> 0 THEN
    RAISE EXCEPTION 'Jackson portraits pre-flight: % official(s) already carry a photo_custom_url — read them before overwriting', v_photo;
  END IF;

  SELECT count(*) INTO v_img FROM essentials.politician_images i
    JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE p.external_id BETWEEN -2767000 AND -2766993;
  IF v_img <> 0 THEN
    RAISE EXCEPTION 'Jackson portraits pre-flight: % politician_images row(s) already exist for these eight', v_img;
  END IF;
END $$;

-- ─── The binding set ─────────────────────────────────────────────────────────
-- Keyed on external_id, which this wave reserved and the gate re-asserts.

CREATE TEMP TABLE jx_photos(external_id bigint, object text, source_url text) ON COMMIT DROP;
INSERT INTO jx_photos(external_id, object, source_url) VALUES
  (-2767000, 'f6784ca0-54d6-4286-97ee-5ea7f7735d7c-headshot.jpg', 'https://jacksonms.gov/wp-content/uploads/2025/10/Jhorhn.jpg'),
  (-2766999, '82f30af3-7ad4-4fcc-9117-cb45bbe58343-headshot.jpg', 'https://jacksonms.gov/wp-content/uploads/2025/11/Ashby-M-Forte.jpg'),
  (-2766998, '82c06258-02e0-4921-a1b8-bb8376a63226-headshot.jpg', 'https://jacksonms.gov/wp-content/uploads/2025/11/Tina-Clay.jpg'),
  (-2766997, '5c6283a1-ce05-4c48-9020-3523c76a0867-headshot.jpg', 'https://jacksonms.gov/wp-content/uploads/2025/11/Kenneth-Stokes.jpg'),
  (-2766996, 'a8eba8fc-9bc1-4820-95a9-6e7969c20c14-headshot.jpg', 'https://jacksonms.gov/wp-content/uploads/2025/11/Brian-C-Grizzell.jpg'),
  (-2766995, '41c02c13-2e1f-403d-9125-96d4b60b372c-headshot.jpg', 'https://jacksonms.gov/wp-content/uploads/2025/11/Vernon-Hartley.jpg'),
  (-2766994, '6b0c7f1a-c4ba-4be5-96f3-d58565974f65-headshot.jpg', 'https://jacksonms.gov/wp-content/uploads/2025/11/Lashia-Brown-Thomas.jpg'),
  (-2766993, '686f9d17-591d-4a5d-b2a9-f1d3026566a8-headshot.jpg', 'https://jacksonms.gov/wp-content/uploads/2025/11/Kevin-Parkinson.jpg');

-- 🔴 The object name IS the politician's own uuid. Assert that before writing, so a mis-paired row
-- cannot bind one person's face to another's record — the dominant failure mode in headshot work.
DO $$
DECLARE v_bad int;
BEGIN
  SELECT count(*) INTO v_bad
    FROM jx_photos n
    JOIN essentials.politicians p ON p.external_id = n.external_id
   WHERE n.object <> p.id::text || '-headshot.jpg';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'Jackson portraits: % row(s) name an object that is not that politician''s own uuid', v_bad;
  END IF;
END $$;

-- ─── 1. The scalar the backend reads ─────────────────────────────────────────

UPDATE essentials.politicians p
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' || n.object,
       photo_origin_url = n.source_url
  FROM jx_photos n
 WHERE p.external_id = n.external_id
   AND coalesce(p.photo_custom_url, '') = '';

-- ─── 2. The row the GRID reads ───────────────────────────────────────────────

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' || n.object,
       'default', 'press_use'
FROM jx_photos n
JOIN essentials.politicians p ON p.external_id = n.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images i
   WHERE i.politician_id = p.id AND i.type = 'default');

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_scalar int;
  v_img    int;
  v_pair   int;
  v_origin int;
  v_lic    int;
  v_bil    int;
BEGIN
  SELECT count(*) INTO v_scalar FROM essentials.politicians
   WHERE external_id BETWEEN -2767000 AND -2766993
     AND photo_custom_url LIKE 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/%-headshot.jpg';
  IF v_scalar <> 8 THEN
    RAISE EXCEPTION 'Jackson portraits gate: expected 8 photo_custom_url values, found %', v_scalar;
  END IF;

  SELECT count(*) INTO v_img FROM essentials.politician_images i
    JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE p.external_id BETWEEN -2767000 AND -2766993 AND i.type = 'default';
  IF v_img <> 8 THEN
    RAISE EXCEPTION 'Jackson portraits gate: expected 8 default politician_images rows, found % — the GRID reads images[] first', v_img;
  END IF;

  -- 🔴🔴 THE TWO MUST AGREE. A scalar and a row that point at different objects is worse than
  -- either alone: the grid and the profile would show different faces for one person.
  SELECT count(*) INTO v_pair
    FROM essentials.politicians p
    JOIN essentials.politician_images i ON i.politician_id = p.id AND i.type = 'default'
   WHERE p.external_id BETWEEN -2767000 AND -2766993
     AND i.url IS DISTINCT FROM p.photo_custom_url;
  IF v_pair <> 0 THEN
    RAISE EXCEPTION 'Jackson portraits gate: % official(s) have a default image row that disagrees with photo_custom_url', v_pair;
  END IF;

  -- The object must still be that person's own uuid, re-asserted after the write.
  SELECT count(*) INTO v_pair FROM essentials.politicians p
   WHERE p.external_id BETWEEN -2767000 AND -2766993
     AND p.photo_custom_url NOT LIKE '%' || p.id::text || '-headshot.jpg';
  IF v_pair <> 0 THEN
    RAISE EXCEPTION 'Jackson portraits gate: % photo(s) are bound to a uuid that is not the holder''s', v_pair;
  END IF;

  SELECT count(*) INTO v_origin FROM essentials.politicians
   WHERE external_id BETWEEN -2767000 AND -2766993
     AND photo_origin_url LIKE 'https://jacksonms.gov/wp-content/uploads/%';
  IF v_origin <> 8 THEN
    RAISE EXCEPTION 'Jackson portraits gate: expected 8 photo_origin_url values on jacksonms.gov, found % — the provenance must survive', v_origin;
  END IF;

  SELECT count(*) INTO v_lic FROM essentials.politician_images i
    JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE p.external_id BETWEEN -2767000 AND -2766993 AND i.photo_license IS DISTINCT FROM 'press_use';
  IF v_lic <> 0 THEN
    RAISE EXCEPTION 'Jackson portraits gate: % image row(s) carry no press_use licence', v_lic;
  END IF;

  -- 🔴 CONTROL: Biloxi's 18 portraits from CC_0175 must be untouched.
  SELECT count(*) INTO v_bil FROM essentials.politicians
   WHERE external_id BETWEEN -2766408 AND -2766401 AND coalesce(photo_custom_url, '') <> '';
  IF v_bil <> 8 THEN
    RAISE EXCEPTION 'Jackson portraits gate CONTROL: expected Biloxi to still carry 8 portraits, found %', v_bil;
  END IF;

  RAISE NOTICE 'Jackson portraits gate PASSED: 8 photo_custom_url, 8 default politician_images rows, the two agree on every row, every object is the holder''s own uuid, 8 origin URLs on jacksonms.gov, all press_use; Biloxi 8 unmoved.';
END $$;

COMMIT;
