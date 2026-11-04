-- CC_0325_hinds_portraits.sql
-- Hinds County, Mississippi — bind the 4 approved portraits. Slot RESERVED from the allocator.
--
-- Operator-approved on a contact sheet, 2026-10-31:
--   https://claude.ai/artifact/CMzCFoPS6oNxbp2HxVFbba
-- The objects are already uploaded to Supabase Storage and byte-verified (sha256 of the re-fetched
-- PUBLIC object against the local file), with a never-uploaded key as the control — it answered
-- HTTP 400 and not an image, so a match means something.
-- Record: backend/data/seed-hinds-county-2026/portraits/README.md
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 BOTH FIELDS ARE WRITTEN, AND ONLY TOGETHER DO THEY WORK.
--   * `politicians.photo_custom_url` is the scalar the backend reads;
--   * the `type='default'` row in `essentials.politician_images` is what the GRID reads, because
--     the frontend reads `images[]` FIRST.
-- A `politician_images` row on its own changes nothing a voter sees, and a scalar on its own
-- leaves the grid blank. The gate below asserts BOTH for all four.
--
-- ── 4 OF 28, AND THE OTHER 24 ARE A DELIBERATE BLANK ─────────────────────────────────────────
-- 🔴 A BLANK IS THE CORRECT ANSWER HERE, NOT A GAP TO BE FILLED LATER FROM A WORSE SOURCE.
-- Hinds has 28 seated officeholders. This migration seats FOUR portraits. The other 24:
--
--   16 — the county publishes NO portrait for the office, read office by office: all five
--        Justice Court Judge pages carry a courthouse address and phone and no image; all five
--        Constable pages name the officer and his district and carry no image; the Election
--        Commission is ONE contact table of name/district/email; and the County Surveyor has no
--        page at all ("surveyor" returns zero hits across the whole site).
--    5 — the Supervisors. Their portraits are a single studio sitting with the photographer's
--        signature "Jay D. Johnson" WATERMARKED INTO THE FRAME. 🔴 THE CREDIT LINE IS THE LICENCE
--        TEST AND HERE IT NAMES A THIRD PARTY: the county's permission to publish is not a
--        sublicence to us. Operator's ruling 2026-10-31: blank them.
--        🔴 THE SIGNATURE WAS NOT CROPPED OFF. Removing an author's attribution in order to reuse
--        the work is worse than declining it, and it drags the crop away from the face.
--        ⚠ It sits bottom-RIGHT on two and bottom-LEFT on three, white on four and gold on one —
--        a fixed-corner check would have passed three of the five. Looking found them.
--    1 — Chancery Clerk. The only copy published is 149x204 (x4.0 to reach 600x750). The
--        separately-named EddieJeanCarr.jpg is the SAME 149x204, so no larger original exists.
--    1 — Circuit Clerk. Not a photograph: the subject cut out over the office seal and the
--        courthouse with "Circuit Clerk" set across it, at 437x400.
--    1 — Coroner. Only swearing-in photographs exist — three people in a courtroom. The
--        Mississippi Today portrait is separately refused: their CC licence excludes photographs
--        and the image is credited "Courtesy of Jeramiah Howard".
--
-- ── SOURCE AND LICENCE ───────────────────────────────────────────────────────────────────────
-- Every image is published by Hinds County on its own site, so `photo_license` is `press_use`,
-- matching Jackson's rows in CC_0324 and MS-3's Biloxi rows.
-- ⚠ `photo_origin_url` POINTS AT AN ARCHIVE CAPTURE ON PURPOSE. hindscountyms.com now returns a
-- vendor "Website Coming Soon" placeholder and 404s /sites/default/files/*, so the live URL would
-- be a dead link that names nothing. The capture URL carries the county's own page AND the date
-- it was read, and every capture is from 2026 — after these officers took office in 2024-01.
--
-- 🔴 BOUND BY SEAT, NEVER BY FILENAME. Each image is whatever the county's page FOR THAT OFFICE
-- shows, and the officeholder's name was asserted present in that page's own text. The county
-- disagrees with our records about the NAME on three seats while agreeing on the seat ("Tony
-- Smith" for Anthony, "Butler-Dixon" for Butler Dixon, "Beverly Green" for Beverly Wade-Green),
-- so a name match would have been the wrong key. The join below is on the POLITICIAN UUID,
-- resolved from external_id, not on anything in a file's name.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int;
  v_photo  int;
  v_img    int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id IN (-2767097, -2767095, -2767094, -2767093);
  IF v_people <> 4 THEN
    RAISE EXCEPTION 'Hinds portraits pre-flight: expected the 4 officials, found %', v_people;
  END IF;

  -- 🔴 This migration must not overwrite a photo somebody else set. There is no history table for
  -- this column, so an UPDATE is final and the previous value exists nowhere the moment it commits.
  SELECT count(*) INTO v_photo FROM essentials.politicians
   WHERE external_id IN (-2767097, -2767095, -2767094, -2767093)
     AND coalesce(photo_custom_url, '') <> '';
  IF v_photo <> 0 THEN
    RAISE EXCEPTION 'Hinds portraits pre-flight: % official(s) already carry a photo_custom_url — read them before overwriting', v_photo;
  END IF;

  SELECT count(*) INTO v_img FROM essentials.politician_images i
    JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE p.external_id IN (-2767097, -2767095, -2767094, -2767093);
  IF v_img <> 0 THEN
    RAISE EXCEPTION 'Hinds portraits pre-flight: % politician_images row(s) already exist for these four', v_img;
  END IF;
END $$;

-- ─── The binding set ─────────────────────────────────────────────────────────

CREATE TEMP TABLE hc_photos(external_id bigint, object text, source_url text) ON COMMIT DROP;
INSERT INTO hc_photos(external_id, object, source_url) VALUES
  (-2767097, '0a15aa05-ecfe-4f15-9c59-432591ffddbc-headshot.jpg',
   'https://web.archive.org/web/20260617153845/https://www.hindscountyms.com/elected-offices/county-attorney'),
  (-2767095, 'd0697130-c722-4401-9a5e-098b2ae1059d-headshot.jpg',
   'https://web.archive.org/web/20260924154244/https://www.hindscountyms.com/elected-offices/sheriff'),
  (-2767094, '96f6bee3-c4ce-4795-92ed-6939adb12ea3-headshot.jpg',
   'https://web.archive.org/web/20260711150439/https://www.hindscountyms.com/elected-offices/tax-assessor'),
  (-2767093, 'b90bf116-89af-4451-951e-88fa6ea3342c-headshot.jpg',
   'https://web.archive.org/web/20260805140040/https://www.hindscountyms.com/elected-offices/tax-collector');

-- 🔴 The object name IS the politician's own uuid. Assert that BEFORE writing, so a mis-paired row
-- cannot bind one person's face to another's record — the dominant failure mode in headshot work.
DO $$
DECLARE v_bad int;
BEGIN
  SELECT count(*) INTO v_bad
    FROM hc_photos n
    JOIN essentials.politicians p ON p.external_id = n.external_id
   WHERE n.object <> p.id::text || '-headshot.jpg';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'Hinds portraits: % row(s) name an object that is not that politician''s own uuid', v_bad;
  END IF;
END $$;

-- 🔴 And assert each external_id is the office we think it is, so a renumbering upstream cannot
-- silently point this set at four other people.
DO $$
DECLARE v_bad int;
BEGIN
  SELECT count(*) INTO v_bad FROM (
    VALUES (-2767097, 'County Attorney'), (-2767095, 'Sheriff'),
           (-2767094, 'Tax Assessor'),    (-2767093, 'Tax Collector')
  ) AS want(external_id, title)
  JOIN essentials.politicians p ON p.external_id = want.external_id
  LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
  LEFT JOIN essentials.offices o ON o.id = och.office_id
  WHERE o.title IS DISTINCT FROM want.title;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'Hinds portraits: % external_id(s) do not hold the office this migration expects', v_bad;
  END IF;
END $$;

-- ─── 1. The scalar the backend reads ─────────────────────────────────────────

UPDATE essentials.politicians p
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' || n.object,
       photo_origin_url = n.source_url
  FROM hc_photos n
 WHERE p.external_id = n.external_id
   AND coalesce(p.photo_custom_url, '') = '';

-- ─── 2. The row the GRID reads ───────────────────────────────────────────────

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' || n.object,
       'default', 'press_use'
FROM hc_photos n
JOIN essentials.politicians p ON p.external_id = n.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images i
   WHERE i.politician_id = p.id AND i.type = 'default');

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_scalar int;
  v_img    int;
  v_pair   int;
  v_origin int;
  v_lic    int;
  v_blank  int;
BEGIN
  SELECT count(*) INTO v_scalar FROM essentials.politicians
   WHERE external_id IN (-2767097, -2767095, -2767094, -2767093)
     AND photo_custom_url LIKE 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/%-headshot.jpg';
  IF v_scalar <> 4 THEN
    RAISE EXCEPTION 'Hinds portraits gate: expected 4 photo_custom_url values, found %', v_scalar;
  END IF;

  SELECT count(*) INTO v_img FROM essentials.politician_images i
    JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE p.external_id IN (-2767097, -2767095, -2767094, -2767093) AND i.type = 'default';
  IF v_img <> 4 THEN
    RAISE EXCEPTION 'Hinds portraits gate: expected 4 default politician_images rows, found %', v_img;
  END IF;

  -- 🔴 THE TWO MUST AGREE. A scalar and an images[] row pointing at different objects is the
  -- shape where the grid and the profile show two different faces.
  SELECT count(*) INTO v_pair FROM essentials.politicians p
    JOIN essentials.politician_images i ON i.politician_id = p.id AND i.type = 'default'
   WHERE p.external_id IN (-2767097, -2767095, -2767094, -2767093)
     AND i.url = p.photo_custom_url;
  IF v_pair <> 4 THEN
    RAISE EXCEPTION 'Hinds portraits gate: only % of 4 have the scalar and the images[] row agreeing', v_pair;
  END IF;

  SELECT count(*) INTO v_origin FROM essentials.politicians
   WHERE external_id IN (-2767097, -2767095, -2767094, -2767093)
     AND photo_origin_url LIKE 'https://web.archive.org/web/%hindscountyms.com/elected-offices/%';
  IF v_origin <> 4 THEN
    RAISE EXCEPTION 'Hinds portraits gate: expected 4 archived county-page origins, found %', v_origin;
  END IF;

  SELECT count(*) INTO v_lic FROM essentials.politician_images i
    JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE p.external_id IN (-2767097, -2767095, -2767094, -2767093)
     AND i.type = 'default' AND i.photo_license = 'press_use';
  IF v_lic <> 4 THEN
    RAISE EXCEPTION 'Hinds portraits gate: expected 4 press_use licences, found %', v_lic;
  END IF;

  -- 🔴 THE BLANKS ARE PART OF THE DELIVERABLE, SO GATE THEM. The other 24 Hinds officeholders
  -- must still carry NO photo after this runs. If a later pass fills one from a watermarked or
  -- composite source, this number moves and the next session sees it.
  SELECT count(*) INTO v_blank FROM essentials.politicians p
   WHERE p.external_id BETWEEN -2767100 AND -2767073
     AND p.external_id NOT IN (-2767097, -2767095, -2767094, -2767093)
     AND coalesce(p.photo_custom_url, '') = ''
     AND NOT EXISTS (SELECT 1 FROM essentials.politician_images i
                      WHERE i.politician_id = p.id AND i.type = 'default');
  IF v_blank <> 24 THEN
    RAISE EXCEPTION 'Hinds portraits gate: expected the other 24 officeholders to stay blank, found % blank', v_blank;
  END IF;

  RAISE NOTICE 'Hinds portraits: 4 bound (scalar + images[] agreeing, press_use, archived origins); 24 deliberately blank';
END $$;

COMMIT;
