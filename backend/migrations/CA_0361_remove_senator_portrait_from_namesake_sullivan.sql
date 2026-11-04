-- CA_0361_remove_senator_portrait_from_namesake_sullivan.sql
--
-- Take the sitting senator's portrait off his namesake challenger. DANIEL J. SULLIVAN JR.
-- (f0a46feb-…), a 2026 U.S. Senate candidate in Alaska, showed the official portrait of SENATOR
-- DAN S. SULLIVAN (a97678bc-…, bioguide S001198). They are two different people.
--
-- ============================================================================================
-- WHY THEY ARE DIFFERENT PEOPLE
-- ============================================================================================
--   * Separate FEC candidate ids: the challenger is S6AK00326, the senator S4AK00214.
--   * Both are on the 2026 Alaska primary and general ballots as separate candidates (CA_0231,
--     CA_0233). The duplicate-people baseline records the pair as different_people (CA_0360).
--   * The Alaska Division of Elections' 2026 Official Election Pamphlet page for the challenger
--     (elections.alaska.gov/doc/oep/2026/SULLIVAN,%20DANIEL%20J.%20JR%20_US%20Sen_Eng_v1.pdf,
--     read 2026-11-04) describes a 69-year-old retired elementary school teacher from Petersburg.
--
-- ============================================================================================
-- WHY THE PHOTOGRAPH IS THE SENATOR'S
-- ============================================================================================
-- Opened both on 2026-11-04. The challenger's stored 600x750 JPEG is the same photograph as the
-- senator's 225x275 congressional portrait (unitedstates.github.io/images/congress/225x275/
-- S001198.jpg, byte-identical to the senator's own stored default.jpg): the same pose, the same
-- suit and striped tie, the U.S. flag at the left and the Alaska flag at the right. It is a larger
-- copy of the senator's official portrait, not a different picture of a similar man.
--
-- 🔴 HOW IT GOT THERE: photo_origin_url is the Ballotpedia RACE page, not a page about the
-- challenger. A race page carries both men's names next to one photograph, so a name match there
-- picked the senator. Ballotpedia's own page for the challenger shows only its "submit a photo"
-- placeholder. Same defect class as Bell CA's Ali Saleh (CLAUDE.md, "NAMESAKES REACH PRODUCTION").
--
-- ============================================================================================
-- 🔴 VALUES THIS MIGRATION DESTROYS, RECORDED HERE BECAUSE NOTHING ELSE RECORDS THEM
-- ============================================================================================
-- The challenger has EXACTLY ONE politician_images row, his 'default'. It is deleted, and both
-- photo scalars on essentials.politicians are set to NULL.
--
--   essentials.politician_images
--     id            = 226c1cb2-9998-4b29-9389-780f3f3b604a
--     politician_id = f0a46feb-43bc-4620-a81f-3bbf7e3cec9c
--     type          = 'default'
--     photo_license = 'press_use'
--     focal_point   = NULL
--     url           =
--     https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f0a46feb-43bc-4620-a81f-3bbf7e3cec9c-headshot.jpg
--
--   essentials.politicians (id f0a46feb-43bc-4620-a81f-3bbf7e3cec9c)
--     photo_custom_url = the same URL as the image row above
--     photo_origin_url = https://ballotpedia.org/United_States_Senate_election_in_Alaska,_2026
--     photo_custom_url_manual_override = false (not touched)
--
-- 🟢 NOTHING IN STORAGE IS DELETED, matching CC_0336. The object stays where it is, unreferenced,
-- so a revert is re-inserting the image row and restoring the two scalars from the values above.
--
-- 🟢 THE SENATOR IS NOT TOUCHED. His own image row (eeabfb79-…) and scalars stay as they are.
--
-- ============================================================================================
-- NO REPLACEMENT IN THIS MIGRATION
-- ============================================================================================
-- The record is left with no photograph. Sources read 2026-11-04:
--   * Ballotpedia, Daniel_J._Sullivan_Jr._(Alaska_U.S._Senate_candidate): placeholder only.
--   * The Division of Elections pamphlet above: a real head-and-shoulders portrait, but in black
--     and white. No-monochrome is the house rule, so it is not used.
--   * His campaign site, sullivanforsenate.com: colour photographs captioned with his name, all
--     outdoor or banner shots. Choosing and cropping one is separate work.
--
-- Idempotent: a second run finds nothing to remove and passes the same post-verify.
--
-- Run: node backend/scripts/apply-migration-file.mjs backend/migrations/CA_0361_remove_senator_portrait_from_namesake_sullivan.sql

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- Pre-flight
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id = 'f0a46feb-43bc-4620-a81f-3bbf7e3cec9c' AND full_name = 'Daniel J. Sullivan Jr.';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-flight: challenger row not found by id AND name'; END IF;

  -- 🔴 EXACTLY THE ONE RECORDED IMAGE, OR NONE (already applied). A second row would be promoted
  -- into the default's place by this delete, showing an unexamined photograph instead.
  SELECT count(*) INTO n FROM essentials.politician_images
   WHERE politician_id = 'f0a46feb-43bc-4620-a81f-3bbf7e3cec9c'
     AND id <> '226c1cb2-9998-4b29-9389-780f3f3b604a';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-flight: % unexpected image row(s) on the challenger', n; END IF;

  -- If the recorded row still exists it must match the header exactly, or the record of what is
  -- being destroyed is already wrong.
  SELECT count(*) INTO n FROM essentials.politician_images
   WHERE id = '226c1cb2-9998-4b29-9389-780f3f3b604a'
     AND NOT (politician_id = 'f0a46feb-43bc-4620-a81f-3bbf7e3cec9c'
              AND type = 'default'
              AND photo_license = 'press_use'
              AND url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f0a46feb-43bc-4620-a81f-3bbf7e3cec9c-headshot.jpg');
  IF n <> 0 THEN RAISE EXCEPTION 'pre-flight: image row no longer matches the header'; END IF;

  -- The scalars must be either the recorded values or already cleared.
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id = 'f0a46feb-43bc-4620-a81f-3bbf7e3cec9c'
     AND coalesce(photo_custom_url, '') NOT IN ('',
           'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f0a46feb-43bc-4620-a81f-3bbf7e3cec9c-headshot.jpg')
      OR id = 'f0a46feb-43bc-4620-a81f-3bbf7e3cec9c'
     AND coalesce(photo_origin_url, '') NOT IN ('',
           'https://ballotpedia.org/United_States_Senate_election_in_Alaska,_2026');
  IF n <> 0 THEN RAISE EXCEPTION 'pre-flight: a photo scalar holds a value the header does not record'; END IF;
END $$;

CREATE TEMP TABLE senator_before ON COMMIT DROP AS
  SELECT p.photo_custom_url, p.photo_origin_url,
         (SELECT count(*) FROM essentials.politician_images
           WHERE politician_id = 'a97678bc-8844-4560-87b1-5ef4f8013d96') AS n_images
    FROM essentials.politicians p WHERE p.id = 'a97678bc-8844-4560-87b1-5ef4f8013d96';

-- ---------------------------------------------------------------------------------------------
DELETE FROM essentials.politician_images
 WHERE id = '226c1cb2-9998-4b29-9389-780f3f3b604a'
   AND politician_id = 'f0a46feb-43bc-4620-a81f-3bbf7e3cec9c';

UPDATE essentials.politicians SET photo_custom_url = NULL, photo_origin_url = NULL
 WHERE id = 'f0a46feb-43bc-4620-a81f-3bbf7e3cec9c'
   AND (photo_custom_url IS NOT NULL OR photo_origin_url IS NOT NULL);

-- ---------------------------------------------------------------------------------------------
-- Post-verify
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  -- 🔴 THE POINT: unreachable by EITHER read path. The grid reads images[] and the backend reads
  -- the scalar, so clearing only one still shows the senator.
  SELECT count(*) INTO n
    FROM essentials.politicians p
    LEFT JOIN essentials.politician_images pi ON pi.politician_id = p.id
   WHERE p.id = 'f0a46feb-43bc-4620-a81f-3bbf7e3cec9c'
     AND (pi.id IS NOT NULL
          OR coalesce(p.photo_custom_url, '') <> ''
          OR coalesce(p.photo_origin_url, '') <> '');
  IF n <> 0 THEN RAISE EXCEPTION 'post-verify: the challenger still has a photograph'; END IF;

  -- No other row anywhere may still point at the removed object (match the PATH, not the host).
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE photo_custom_url LIKE '%/storage/v1/object/public/politician_photos/f0a46feb-43bc-4620-a81f-3bbf7e3cec9c-headshot.jpg';
  SELECT n + count(*) INTO n FROM essentials.politician_images
   WHERE url LIKE '%/storage/v1/object/public/politician_photos/f0a46feb-43bc-4620-a81f-3bbf7e3cec9c-headshot.jpg';
  IF n <> 0 THEN RAISE EXCEPTION 'post-verify: % row(s) still reference the removed object', n; END IF;

  -- This removes a photograph, never a person.
  SELECT count(*) INTO n FROM essentials.politicians WHERE id = 'f0a46feb-43bc-4620-a81f-3bbf7e3cec9c';
  IF n <> 1 THEN RAISE EXCEPTION 'post-verify: the challenger row disappeared'; END IF;

  -- The senator keeps his own portrait, unchanged.
  SELECT count(*) INTO n
    FROM essentials.politicians p, senator_before b
   WHERE p.id = 'a97678bc-8844-4560-87b1-5ef4f8013d96'
     AND p.photo_custom_url IS NOT DISTINCT FROM b.photo_custom_url
     AND p.photo_origin_url IS NOT DISTINCT FROM b.photo_origin_url
     AND (SELECT count(*) FROM essentials.politician_images
           WHERE politician_id = 'a97678bc-8844-4560-87b1-5ef4f8013d96') = b.n_images
     AND b.n_images = 1;
  IF n <> 1 THEN RAISE EXCEPTION 'post-verify: the senator''s portrait changed'; END IF;
END $$;

COMMIT;
