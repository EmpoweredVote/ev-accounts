-- CC_0512 — make the two read surfaces agree for the politicians who carry a photo scalar and
-- no image row.
--
-- A photo can live in three places and two of them are read by different surfaces:
-- `politicians.photo_custom_url` is the scalar the backend reads, and a
-- `essentials.politician_images` row of `type = 'default'` is what the grid reads out of
-- `images[]`. Writing one without the other gives a person who renders on one surface and blanks
-- on the other, and **no gate in this repo sees it**. The headshot queue builder
-- (`backend/data/transition-headshots-2026/build-list.mjs`) is the only thing that reports it,
-- as a side note, and it has named the same defect at every run: two rows on 2026-11-08, three
-- on 2026-11-25.
--
-- This file repairs **two** of those three. The third is not a repair and is the reason this
-- header is long.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 MARK TEIXEIRA IS DELIBERATELY NOT REPAIRED, AND HE IS NOT A WRONG-PERSON ERROR
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `c7699355-885b-475d-834a-1a945618e711` won **TX-21** on 2026-11-03 and carries a
-- `photo_custom_url` on our own storage. Looked at, that photograph is **a baseball action shot
-- in a New York Yankees uniform** — helmet on, batting gloves, mid-game, shot from the thigh up.
--
-- ⚠ **The first reading of that was "the photo is of the wrong person" and it was WRONG.** It is
-- the right man: Mark Teixeira, the former Rangers and Yankees first baseman, ran for and won
-- Texas's 21st district. A famous namesake is the shape that makes a correct photograph look
-- like an identity error, and the opposite mistake — assuming a celebrity match must be a
-- mis-link — would have been just as confident.
--
-- It is still unusable as an officeholder's portrait, for two reasons that have nothing to do
-- with identity:
--
--   * **It is not a headshot.** A uniformed action frame fails the composition rules this repo
--     already carries (4:5 at 600×750, roughly an ear's length of space above the hair).
--   * **The licence cannot be stated.** `photo_origin_url` is NULL, so there is no provenance to
--     read a credit line from, and a mid-game frame of a professional athlete is the shape that
--     belongs to a wire agency. The credit line is the licence test and there is no credit line.
--
-- ▶ **So propagating it to a second surface is the one thing this file must not do.** Writing
-- his `default` row would double the exposure of a photograph we cannot licence and would not
-- publish if we were sourcing it today. His scalar is **left exactly as it is** — removing a
-- live portrait is a separate, visible act and belongs to whoever sources the replacement.
--
-- ⚠ **He is invisible to the sourcing queue**, because that queue asks who has NO photo anywhere
-- and he has one. A person with an unusable photo and a person with no photo need the same work
-- and only one of them is counted. Nothing in this repo measures the first class.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE TWO ROWS THIS FILE WRITES, AND THE LICENCE VALUE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   6b0a5417-9094-447f-8df7-d868aab762eb  Jessica Forsythe  origin redmond.gov documentId=21593
--   21a8e1cc-f52d-439e-a0d0-50c5f6720bed  Vanessa Kritzer   origin redmond.gov documentId=11885
--
-- Both were fetched and **looked at** before this file was written: each is a real 600×750
-- portrait of a person, already at the house crop, head whole, no matte corners, not a seal and
-- not a map. Nothing we run asks whether an image contains a face, so the eye is the check.
--
-- 🔴 **`photo_license` is `unknown`, not `press_use`, and that is a decision rather than a
-- default.** The origin is the City of Redmond's own image repository, which is an official
-- municipal source and in policy — but **redmond.gov publishes no terms-of-use page** (HTTP 404
-- at two candidate paths on 2026-11-25) and its home page carries no copyright or rights
-- footer to read. Silence is not permission. `unknown` is findable by the query that looks for
-- missing provenance; a guessed `press_use` tells the public they may reuse a photograph nobody
-- cleared, and is not findable at all.
--
-- ⚠ **This file does NOT change `photo_custom_url` for anybody.** Both scalars are already live
-- and have been; the only change is that the grid now sees what the backend already saw.
--
-- APPLIED to prod (kxsdzaojfaibhuzmclfq) 2026-11-25, after the identical statements were run
-- inside BEGIN ... ROLLBACK and seen to insert 2 rows with every assertion green, and after the
-- Teixeira guard was WATCHED GOING RED: a tamper adding his id to the INSERT list, asserted
-- present in the file before the run, produced check (c) naming him and nothing else.
-- Verified in production afterwards: Forsythe 1 default row, Kritzer 1, each url equal to the
-- scalar, licence unknown; Teixeira 0.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 1. The two rows.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The url is read from `photo_custom_url` rather than retyped, so the two surfaces cannot
-- disagree by a transcription error — which is the whole defect being repaired. The NOT EXISTS
-- makes a re-run write nothing rather than a second default row; a person with two 'default'
-- rows is a worse state than the one this file is fixing.

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT p.id, p.photo_custom_url, 'default', 'unknown'
  FROM essentials.politicians p
 WHERE p.id IN (
         '6b0a5417-9094-447f-8df7-d868aab762eb',  -- Jessica Forsythe
         '21a8e1cc-f52d-439e-a0d0-50c5f6720bed'   -- Vanessa Kritzer
       )
   AND p.photo_custom_url IS NOT NULL
   AND NOT EXISTS (
         SELECT 1 FROM essentials.politician_images pi
          WHERE pi.politician_id = p.id AND pi.type = 'default'
       );

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 2. Post-verify.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_rows   int;
  v_bad    text;
  v_tex    int;
  v_others int;
BEGIN
  -- (a) Exactly two people now hold exactly one 'default' row each, and its url IS the scalar.
  SELECT count(*) INTO v_rows
    FROM essentials.politicians p
    JOIN essentials.politician_images pi
      ON pi.politician_id = p.id AND pi.type = 'default'
   WHERE p.id IN ('6b0a5417-9094-447f-8df7-d868aab762eb',
                  '21a8e1cc-f52d-439e-a0d0-50c5f6720bed')
     AND pi.url = p.photo_custom_url
     AND pi.photo_license = 'unknown';
  IF v_rows <> 2 THEN
    RAISE EXCEPTION
      'CC_0512: expected 2 default image rows whose url equals photo_custom_url and whose '
      'licence is unknown, and found %. The point of this file is that the two surfaces agree, '
      'so a row that does not match the scalar is the defect re-created, not a repair', v_rows;
  END IF;

  -- (b) Neither of them has gained a SECOND default row. A re-run writing a duplicate would
  --     leave the grid picking one of two arbitrarily, which is worse than the blank.
  SELECT string_agg(x.id::text || ' has ' || x.n, ', ') INTO v_bad
    FROM (SELECT p.id, count(*) AS n
            FROM essentials.politicians p
            JOIN essentials.politician_images pi
              ON pi.politician_id = p.id AND pi.type = 'default'
           WHERE p.id IN ('6b0a5417-9094-447f-8df7-d868aab762eb',
                          '21a8e1cc-f52d-439e-a0d0-50c5f6720bed')
           GROUP BY p.id HAVING count(*) <> 1) x;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0512: a repaired politician does not hold exactly one default row (%)', v_bad;
  END IF;

  -- (c) 🔴 MARK TEIXEIRA STILL HAS NO IMAGE ROW, ASSERTED RATHER THAN ASSUMED. The exclusion
  --     above is two literal ids; if somebody later widens this file into "repair every
  --     mismatch", that edit must trip here and read the header before it publishes a Yankees
  --     action frame to the grid.
  SELECT count(*) INTO v_tex
    FROM essentials.politician_images
   WHERE politician_id = 'c7699355-885b-475d-834a-1a945618e711';
  IF v_tex <> 0 THEN
    RAISE EXCEPTION
      'CC_0512: Mark Teixeira (c7699355) gained % image row(s). He is excluded ON PURPOSE: his '
      'photo is a baseball action frame with no recorded provenance. It is the RIGHT PERSON and '
      'the WRONG PHOTOGRAPH. Read this file''s header before changing that', v_tex;
  END IF;

  -- (d) Nobody else gained anything. The INSERT names two ids, so a third row would mean the
  --     predicate did something other than what it reads as.
  SELECT count(*) INTO v_others
    FROM essentials.politician_images pi
   WHERE pi.type = 'default'
     AND pi.photo_license = 'unknown'
     AND pi.politician_id NOT IN ('6b0a5417-9094-447f-8df7-d868aab762eb',
                                  '21a8e1cc-f52d-439e-a0d0-50c5f6720bed')
     AND pi.politician_id IN (
           SELECT p.id FROM essentials.politicians p
            WHERE p.photo_custom_url IS NOT NULL
              AND p.id = 'c7699355-885b-475d-834a-1a945618e711');
  IF v_others <> 0 THEN
    RAISE EXCEPTION 'CC_0512: % unexpected row(s) outside the two named politicians', v_others;
  END IF;

  RAISE NOTICE 'CC_0512 OK — 2 default image rows written, url matches the scalar on both, '
               'licence unknown, Teixeira untouched at 0 image rows.';
END $$;

COMMIT;
