-- CC_0327_mn_portrait_licences.sql
--
-- Two Minnesota legislators were the only portrait rows in their chambers carrying a Creative
-- Commons licence. 132 of 133 House rows and 66 of 67 Senate rows agree with each other; these two
-- disagreed. Both were SKIPPED by the MN-6 headshot wave, and the manifests say why -- each carries
-- "_already": {"has_custom": true, "has_image_row": true}, so the wave left the photograph that was
-- already there and never wrote its own licence over it.
--
-- 🔴 THE TWO TURNED OUT TO BE DIFFERENT PROBLEMS, AND ONLY ONE IS AN OVER-CLAIM. A first pass
-- called both "licence over-claimed" from the manifest disagreement alone. Looking at the actual
-- photographs settled it, and the manifest was NOT describing the stored image in one of the cases.
--
-- ERIC PRATT (fa8d5cfb-…, external_id -270201, Minnesota Senate District 54)
--   The stored file IS the Senate's own portrait: same sitting, same suit, same tie, same studio
--   background as https://www.senate.mn/graphics/55Pratt.jpg, ours a slightly tighter crop.
--   So `cc_by_2.0` asserts a Creative Commons licence over a photograph the Minnesota Senate
--   publishes and has granted nobody CC terms on. 🔴 That is a statement to the public that they
--   may reuse it, and it is wrong. His 66 colleagues all carry `press_use` from the same source.
--   FIXED HERE: licence -> press_use, origin -> his Senate bio page. The image does not change.
--
-- KAELA BERG (a89ba4b9-…, external_id -270203, Minnesota House District 55B)
--   ⚠ NOT an over-claim, and this migration does not treat it as one. Her stored file is a
--   DIFFERENT PHOTOGRAPH from the House portrait -- a candid, near-profile, background out of
--   focus -- so `cc_by-sa_4.0` may well be correct FOR THAT IMAGE. The problem is that nothing
--   records where it came from, so the licence is unverifiable, and the attribution CC BY-SA
--   requires is recorded nowhere.
--   FIXED HERE BY REPLACING THE PHOTOGRAPH, not by relabelling it. She is a House member, and the
--   House granted us its member portraits by name on 2026-09-17 (Mike Cook; the grantor offered the
--   blanket credit "Minnesota House of Representatives"). Her portrait is the one the wave would
--   have imported had she not already had a photo. 🔴 THE GRANT IS TO US, NOT TO THE FILES --
--   another publisher serving the same images is not covered.
--
-- VALUES BEING OVERWRITTEN, recorded here because nothing else records them:
--   Pratt  photo_license     'cc_by_2.0'                      -> 'press_use'
--          photo_origin_url  NULL                             -> senate.mn bio page
--   Berg   photo_license     'cc_by-sa_4.0'                   -> the House permission string
--          photo_origin_url  NULL                             -> house.mn.gov profile 15550
--          photo_custom_url  '…/politician_photos/a89ba4b9-a684-40a6-b5ec-db0876a65b8d-headshot.jpg'
--                            -> '…/politician_photos/mn-house-2026/a89ba4b9-…-headshot.jpg'
--          politician_images.url  same change as photo_custom_url
--   🟢 HER PRIOR IMAGE IS NOT DESTROYED. The new file was uploaded under a NEW key, so the old
--   object is still served at the old URL (verified: HTTP 200, 99,420 bytes). Reverting means
--   pointing the two columns back at it; nothing has to be re-fetched.
--
-- HOW THE NEW PHOTOGRAPH WAS ESTABLISHED AS HERS:
--   * profile 15550 names "Rep. Kaela Berg (55B)" and references the 55B image; a control profile
--     (15538, John Burkel) does not name her.
--   * 🔴 THE 1050x1350 JPEG IS UNLINKED -- the page links only a 525x675 GIF, so nothing on the
--     page asserts the JPEG depicts the same person. Downscaled to the GIF's size the mean absolute
--     difference is 4.03, against 53.14 for ANOTHER MEMBER'S GIF as a negative control: a
--     separation of 49. MN-6 measured a median of 3.15 across the 132 it did import.
--   * The crop is measured, not centred: face box detected at 548x548, 4:5 crop 1050x1312,
--     downscaled x0.571 to 600x750 -- nothing enlarged. The face detector was first shown a flat
--     grey frame and found 0 faces, so its finding here means something.
--   * Uploaded, re-fetched from the public CDN and sha256-compared; a never-uploaded key in the
--     same prefix returns HTTP 400 and no image.
--
-- Run: node backend/scripts/apply-migration-file.mjs backend/migrations/CC_0327_mn_portrait_licences.sql

BEGIN;

CREATE TEMP TABLE mn_fix (
  politician_id uuid PRIMARY KEY,
  who           text NOT NULL,
  old_licence   text NOT NULL,
  new_licence   text NOT NULL,
  new_origin    text NOT NULL,
  old_object    text NOT NULL,
  new_object    text          -- NULL where the photograph does not change
) ON COMMIT DROP;

INSERT INTO mn_fix VALUES
 ('fa8d5cfb-5feb-4112-b68b-f1c2de963dc3'::uuid, 'Eric Pratt',
  'cc_by_2.0', 'press_use',
  'https://www.senate.mn/members/member_bio.html?mem_id=1210',
  'fa8d5cfb-5feb-4112-b68b-f1c2de963dc3-headshot.jpg', NULL),
 ('a89ba4b9-a684-40a6-b5ec-db0876a65b8d'::uuid, 'Kaela Berg',
  'cc_by-sa_4.0', 'Minnesota House of Representatives (used by permission, 2026-09-17)',
  'https://www.house.mn.gov/members/profile/15550',
  'a89ba4b9-a684-40a6-b5ec-db0876a65b8d-headshot.jpg',
  'mn-house-2026/a89ba4b9-a684-40a6-b5ec-db0876a65b8d-headshot.jpg');

-- ---------------------------------------------------------------------------------------------
-- Pre-flight
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mn_fix f JOIN essentials.politicians p ON p.id = f.politician_id;
  IF n <> 2 THEN RAISE EXCEPTION 'pre-flight: expected both politicians to exist, found %', n; END IF;

  -- Each must still carry EXACTLY the licence this migration says it is replacing. If one has
  -- moved, the header's record of the old value is already wrong and must not be trusted.
  SELECT count(*) INTO n
    FROM mn_fix f
    JOIN essentials.politician_images pi ON pi.politician_id = f.politician_id AND pi.type = 'default'
   WHERE pi.photo_license = f.old_licence;
  IF n <> 2 THEN RAISE EXCEPTION 'pre-flight: expected 2 rows carrying their recorded old licence, found %', n; END IF;

  -- …and must still point at the object this migration measured.
  SELECT count(*) INTO n
    FROM mn_fix f
    JOIN essentials.politician_images pi ON pi.politician_id = f.politician_id AND pi.type = 'default'
   WHERE substring(pi.url from 'politician_photos/(.*)$') = f.old_object;
  IF n <> 2 THEN RAISE EXCEPTION 'pre-flight: expected 2 rows on their recorded old object, found %', n; END IF;

  -- 🔴 SEAT CHECK. The licence being written is chamber-specific: the House grant does not reach
  -- the Senate, and press_use here is the Senate's publication. Writing either onto someone in the
  -- other chamber would be a false licence statement, so assert the seat, not just the person.
  SELECT count(*) INTO n
    FROM mn_fix f
    JOIN essentials.office_current_holder och ON och.politician_id = f.politician_id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE (f.who = 'Eric Pratt' AND c.name = 'Minnesota Senate')
      OR (f.who = 'Kaela Berg' AND c.name = 'Minnesota House of Representatives');
  IF n <> 2 THEN RAISE EXCEPTION 'pre-flight: expected both to hold the seat their licence assumes, found %', n; END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
UPDATE essentials.politician_images pi
   SET photo_license = f.new_licence,
       url = CASE WHEN f.new_object IS NULL THEN pi.url
                  ELSE 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/'
                       || f.new_object END
  FROM mn_fix f
 WHERE pi.politician_id = f.politician_id
   AND pi.type = 'default'
   AND pi.photo_license = f.old_licence;

UPDATE essentials.politicians p
   SET photo_origin_url = f.new_origin,
       photo_custom_url = CASE WHEN f.new_object IS NULL THEN p.photo_custom_url
                               ELSE 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/'
                                    || f.new_object END
  FROM mn_fix f
 WHERE p.id = f.politician_id;

-- ---------------------------------------------------------------------------------------------
-- Post-verify
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE n int; cc int;
BEGIN
  SELECT count(*) INTO n
    FROM mn_fix f
    JOIN essentials.politician_images pi ON pi.politician_id = f.politician_id AND pi.type = 'default'
    JOIN essentials.politicians p ON p.id = f.politician_id
   WHERE pi.photo_license = f.new_licence
     AND p.photo_origin_url = f.new_origin;
  IF n <> 2 THEN RAISE EXCEPTION 'post-verify: expected 2 corrected rows, found %', n; END IF;

  -- 🔴 THE SCALAR AND THE IMAGE ROW MUST AGREE. The grid reads images[] and the backend reads the
  -- scalar; a split leaves a voter looking at one photograph while the record describes another.
  SELECT count(*) INTO n
    FROM mn_fix f
    JOIN essentials.politician_images pi ON pi.politician_id = f.politician_id AND pi.type = 'default'
    JOIN essentials.politicians p ON p.id = f.politician_id
   WHERE p.photo_custom_url = pi.url;
  IF n <> 2 THEN RAISE EXCEPTION 'post-verify: expected scalar and images row to agree on both, found %', n; END IF;

  -- Berg must now be on the new object, Pratt must still be on his old one.
  SELECT count(*) INTO n FROM essentials.politician_images
   WHERE politician_id = 'a89ba4b9-a684-40a6-b5ec-db0876a65b8d'::uuid AND type = 'default'
     AND url LIKE '%politician_photos/mn-house-2026/%';
  IF n <> 1 THEN RAISE EXCEPTION 'post-verify: Berg is not on the new object'; END IF;
  SELECT count(*) INTO n FROM essentials.politician_images
   WHERE politician_id = 'fa8d5cfb-5feb-4112-b68b-f1c2de963dc3'::uuid AND type = 'default'
     AND url LIKE '%politician_photos/fa8d5cfb-5feb-4112-b68b-f1c2de963dc3-headshot.jpg';
  IF n <> 1 THEN RAISE EXCEPTION 'post-verify: Pratt''s image URL changed and it should not have'; END IF;

  -- 🟢 THE WHOLE POINT, STATED AS A NUMBER: no Minnesota legislative portrait may now claim a
  -- Creative Commons licence. Both chambers publish their own and neither has granted CC terms.
  SELECT count(*) INTO cc
    FROM essentials.politician_images pi
    JOIN essentials.office_current_holder och ON och.politician_id = pi.politician_id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE pi.type = 'default'
     AND c.name IN ('Minnesota House of Representatives', 'Minnesota Senate')
     AND pi.photo_license ILIKE 'cc%';
  IF cc <> 0 THEN
    RAISE EXCEPTION 'post-verify: expected 0 CC-licensed MN legislative portraits, found %', cc;
  END IF;

  -- And each chamber is now internally uniform: 133 House on the grant, 67 Senate on press_use.
  SELECT count(*) INTO n
    FROM essentials.politician_images pi
    JOIN essentials.office_current_holder och ON och.politician_id = pi.politician_id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE pi.type = 'default' AND c.name = 'Minnesota House of Representatives'
     AND pi.photo_license = 'Minnesota House of Representatives (used by permission, 2026-09-17)';
  IF n <> 133 THEN RAISE EXCEPTION 'post-verify: expected 133 House portraits on the grant, found %', n; END IF;

  SELECT count(*) INTO n
    FROM essentials.politician_images pi
    JOIN essentials.office_current_holder och ON och.politician_id = pi.politician_id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE pi.type = 'default' AND c.name = 'Minnesota Senate' AND pi.photo_license = 'press_use';
  IF n <> 67 THEN RAISE EXCEPTION 'post-verify: expected 67 Senate portraits on press_use, found %', n; END IF;
END $$;

COMMIT;
