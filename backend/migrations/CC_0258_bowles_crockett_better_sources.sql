-- CC_0258_bowles_crockett_better_sources.sql
--
-- Replaces the last two soft upscales left open by CC_0253-CC_0257, both with portraits from
-- the candidate's OWN campaign website. Neither new file is enlarged at all.
--
--                     was                      now                                  sharpness*
--   Brent Bowles      136x160   4.69x UP       2560x1440  crop 972x1215   0.62x DOWN   45 -> 102
--   Traci Crockett    250x250   3.00x UP       1500x2000  crop 1303x1628  0.46x DOWN  114 -> 319
--
--   * variance of the Laplacian over the face box, with every face first normalised to the
--     same 400px height -- otherwise the number just restates the file size.
--
-- SOURCES
--   Bowles    https://brentbowles4ut.com/assets/images/bbbackground.png   (site hero)
--   Crockett  https://traci4countycouncil.com/images/traci_portrait.jpeg
--
-- 🔴 "NO PORTRAIT ON THE CAMPAIGN SITE" WAS A BYTE COUNT, NOT A READING. CC_0254 recorded that
-- Bowles' site is "a 3KB stub with no portrait". The INDEX is 3,276 bytes; the site has four
-- more pages, a hero image and nine photographs. The portrait was there the whole time. Fetch
-- the pages, not just the root, and list the images before concluding a source is empty.
-- CC_0255 likewise recorded "no campaign site was found" for Crockett. She has two live
-- domains -- traci4countycouncil.com AND .org -- and the .com serves a clean studio portrait.
--
-- 🔴 A FILE NAMED "HEADSHOT" IS NOT EVIDENCE OF WHOSE HEADSHOT IT IS. Bowles' site serves
-- assets/images/bb-fireman-headshot.jpg at 2848x3274 -- the largest, sharpest single face on
-- the whole site, portrait-shaped, one detected face, 0.92 confidence. It passes every check
-- we have. IT IS A STOCK PHOTOGRAPH OF A FIREFIGHTER and not Brent Bowles: dark hair, no
-- glasses, thirty years younger, dramatic studio lighting, used decoratively beside a
-- "support first responders" plank. Bowles is white-haired and wears rimless glasses.
-- Only looking at it caught this. The same site also carries three AdobeStock files under
-- their original adobestock_* names, so the pattern is the site's, not an accident.
--
-- IDENTITY, checked on something other than the filename, for each:
--   Bowles    the hero portrait matches the independently-sourced utelection.info photograph
--             this migration replaces -- same hairline, same rimless glasses, same ear shape
--             (the goatee is shaved in the newer frame); the site's <title> and meta
--             description name "Brent Bowles for Utah County Commissioner", and our
--             race_candidates row reads 'Utah County Commission Seat A'
--   Crockett  the .com names her 14 times, names "Salt Lake County Council" 7 times, names
--             "District 5" 8 times and names Bluffdale -- matching our race row exactly.
--             The BallotReady portrait being replaced is her 2019 BLUFFDALE CITY COUNCIL
--             profile (Keller Williams realtor, former Jordan School District teacher), which
--             is the same person seven years earlier -- that is why it looked like a younger
--             woman. Same person, older file, quarter the resolution.
--
-- ⚠ CROCKETT'S HEADROOM IS TIGHT. Measured against the uniform studio ground, her hair tops
-- out 93px from the frame edge = 0.39 ear lengths, against the ~1.0 the house crop wants. Her
-- source is framed that way and the crown is NOT cut. Padding the canvas would invent image
-- content, so the frame is left honest and short rather than extended.
-- ⚠ Bowles' mobile hero (bbmobile.png, 1024x1536) has a BIGGER face box but zero headroom --
-- the crown is flush with the source edge. The desktop hero is used instead: slightly smaller
-- face, measurably sharper (102 vs 93), and one full ear length above the hair.
--
-- 🔴 THIS MIGRATION ALSO WRITES race_candidates.photo_url -- A THIRD PHOTO COLUMN NOTHING
-- SWEEPS. backend/src/lib/electionService.ts selects COALESCE(rc.photo_url, pi.url), so on
-- every election and ballot page the race_candidates column WINS over the one CC_0253-CC_0257
-- fixed. check-headshot-faces.py reads only COALESCE(politicians.photo_custom_url,
-- photo_origin_url) and has never looked at it. Crockett's row still held the YARD SIGN that
-- CC_0255 replaced, so for her that migration was only half applied.
-- Measured 2026-10-19: 135 rows carry rc.photo_url, 30 of them DISAGREE with the fixed
-- scalar. Face-swept those 30 (controls: the yard sign must fail, a real portrait must pass):
-- 3 are graphics -- Crockett, Mike Bird, Stephen Otterstrom, all three of CC_0255's yard
-- signs. ▶ STILL OWED, NOT FIXED HERE: Bird and Otterstrom (yard signs) and Tayler Khater,
-- whose row still holds the five-person FAMILY PHOTOGRAPH that CC_0256 removed -- it passes
-- the face gate because a group photo has faces in it.
--
-- Both files face-checked after cropping (0.94/0.95 at rotation 0) and byte-verified served:
-- HTTP 200, image/jpeg, sha256 identical to the local file.
-- 🔴 ?v=20261019d, because overwriting a storage object does not change what the CDN serves.
-- BOTH SIDES written, plus the race column. Idempotent.

BEGIN;

CREATE TEMP TABLE _resource (
  politician_id uuid PRIMARY KEY,
  name_like     text NOT NULL,
  url           text NOT NULL,
  origin_url    text NOT NULL,
  photo_license text NOT NULL,
  rc_id         uuid NOT NULL          -- the ONE race_candidates row holding a stale photo
) ON COMMIT DROP;

INSERT INTO _resource (politician_id, name_like, url, origin_url, photo_license, rc_id) VALUES
  ('b71ec1b6-7d9e-406b-a30a-8c0710278d5e'::uuid, 'Brent Bowles',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b71ec1b6-7d9e-406b-a30a-8c0710278d5e-headshot.jpg?v=20261019d',
   'https://brentbowles4ut.com/assets/images/bbbackground.png', 'press_use',
   '0c20f588-2ec2-489a-b390-7c4ea9e7fe2b'::uuid),
  ('0919efe0-5abc-401f-88cb-7a3e13788ff4'::uuid, 'Traci Crockett',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0919efe0-5abc-401f-88cb-7a3e13788ff4-headshot.jpg?v=20261019d',
   'https://traci4countycouncil.com/images/traci_portrait.jpeg', 'press_use',
   '90d85026-ad89-42d1-b340-7236935f3681'::uuid);

-- Guard: every id must still resolve to the person this migration believes it is, and must
-- still carry exactly one default image. If the shape moved, REFUSE rather than overwrite.
DO $$
DECLARE r record; v_name text; v_images int;
BEGIN
  FOR r IN SELECT * FROM _resource LOOP
    SELECT p.full_name,
           (SELECT count(*) FROM essentials.politician_images pi
             WHERE pi.politician_id = p.id AND pi.type = 'default')
      INTO v_name, v_images
      FROM essentials.politicians p WHERE p.id = r.politician_id;

    IF v_name IS NULL THEN
      RAISE EXCEPTION 'CC_0258: % matches no politician row', r.politician_id;
    END IF;
    IF v_name <> r.name_like THEN
      RAISE EXCEPTION 'CC_0258: % resolves to "%", expected "%"', r.politician_id, v_name, r.name_like;
    END IF;
    IF v_images <> 1 THEN
      RAISE EXCEPTION 'CC_0258: % has % default image rows, expected exactly 1', r.name_like, v_images;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                    WHERE rc.id = r.rc_id AND rc.politician_id = r.politician_id) THEN
      RAISE EXCEPTION 'CC_0258: race_candidates row % is not %', r.rc_id, r.name_like;
    END IF;
  END LOOP;
END $$;

-- 1. the scalar the profile page reads, and the provenance URL beside it
UPDATE essentials.politicians p
SET photo_custom_url = r.url,
    photo_origin_url = r.origin_url
FROM _resource r
WHERE p.id = r.politician_id
  AND (p.photo_custom_url IS DISTINCT FROM r.url OR p.photo_origin_url IS DISTINCT FROM r.origin_url);

-- 2. the images[] row the browse grid reads FIRST
UPDATE essentials.politician_images pi
SET url = r.url, photo_license = r.photo_license
FROM _resource r
WHERE pi.politician_id = r.politician_id AND pi.type = 'default'
  AND (pi.url IS DISTINCT FROM r.url OR pi.photo_license IS DISTINCT FROM r.photo_license);

-- 3. the race column electionService.ts COALESCEs AHEAD of both of the above
UPDATE essentials.race_candidates rc
SET photo_url = r.url
FROM _resource r
WHERE rc.id = r.rc_id AND rc.photo_url IS DISTINCT FROM r.url;

-- post-verify: all three sites agree, for both people, and no stale yard sign survives.
DO $$
DECLARE n_all int; n_multi int; n_stale int;
BEGIN
  SELECT count(*) INTO n_all
    FROM _resource r
    JOIN essentials.politicians p ON p.id = r.politician_id
     AND p.photo_custom_url = r.url AND p.photo_origin_url = r.origin_url
    JOIN essentials.politician_images pi ON pi.politician_id = r.politician_id
     AND pi.type = 'default' AND pi.url = r.url AND pi.photo_license = r.photo_license
    JOIN essentials.race_candidates rc ON rc.id = r.rc_id AND rc.photo_url = r.url;
  IF n_all <> 2 THEN
    RAISE EXCEPTION 'CC_0258: expected 2 rows written on ALL THREE sites, found %', n_all;
  END IF;

  SELECT count(*) INTO n_multi FROM (
    SELECT pi.politician_id FROM essentials.politician_images pi
    JOIN _resource r ON r.politician_id = pi.politician_id
    WHERE pi.type = 'default' GROUP BY pi.politician_id HAVING count(*) > 1) x;
  IF n_multi <> 0 THEN
    RAISE EXCEPTION 'CC_0258: more than one default image row for a subject';
  END IF;

  -- neither person may still point anywhere at the /ut/candidates/ clerk objects they came from
  SELECT count(*) INTO n_stale
    FROM essentials.race_candidates rc
    JOIN _resource r ON r.politician_id = rc.politician_id
   WHERE rc.photo_url LIKE '%/ut/candidates/%';
  IF n_stale <> 0 THEN
    RAISE EXCEPTION 'CC_0258: % race_candidates row(s) still serve the old clerk object', n_stale;
  END IF;

  RAISE NOTICE 'CC_0258 OK - Bowles and Crockett re-sourced; profile, grid and ballot all agree';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE THESE TWO PAID FOR: A SOURCE IS NOT EXHAUSTED UNTIL YOU HAVE READ IT.
-- Both "there is no better source" findings in CC_0254 and CC_0255 were wrong, and both were
-- wrong the same way -- a root URL was fetched, its size or its search result was read, and
-- the conclusion was recorded as fact. Bowles' portrait was one click away on /about.html's
-- sibling; Crockett's was on a second domain. The cost of being wrong here is not a missing
-- photograph, it is a PUBLISHED 4.69x upscale of a civic portrait.
--
-- 🔴 AND: THE FACE GATE HAS A THIRD BLIND SPOT. It cannot see a group photo (CC_0256), it
-- cannot see the wrong person (CC_0257), and -- this one -- IT CANNOT SEE A COLUMN IT DOES
-- NOT READ. race_candidates.photo_url outranks the column the gate sweeps.
--
-- STILL OWED after this migration
--   race_candidates.photo_url, 3 known defects rendering on ballot pages today:
--     Tayler Khater       five-person family photograph (passes the face gate)
--     Mike Bird           campaign yard sign
--     Stephen Otterstrom  campaign yard sign
--   ▶ The structural fix is to make the gate read this column, and to decide whether
--     rc.photo_url should be NULLed so COALESCE always falls through to the fixed image.
--     27 of the 30 divergent rows are real portraits, so this is a design call, not a cleanup.
-- ───────────────────────────────────────────────────────────────────────────────────────────
