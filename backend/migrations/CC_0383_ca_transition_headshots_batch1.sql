-- CC_0383 — AUDIT ONLY. 14 California transition headshots, imported 2026-11-09.
--
-- The script did the live writes (scripts/import-headshot-candidates.py); this file is the
-- record, in the house audit-only style used by every headshot migration since 314. It writes
-- nothing that is not already true in production, and its post-verify asserts the END STATE.
--
-- WHO, AND WHY THESE 14. They are California winners of 2026-11-03 who had no photograph in
-- ANY of the three places one can live, drawn from the two nearest handovers:
--   * 5 special-district directors seating 2026-12-04 (Cal. Water Code 71253 / Elec. Code
--     10554 / Water Code 35057 / Water Code 21101 — data/ca-special-districts-2026-results/NOTES.md)
--   * 9 school-board members seating 2026-12-11 (Educ. Code 5017 commencement, per the
--     2026-11-08 ruling in data/ca-2026-swearing-in/RULES.md)
--
-- EVERY ROW WRITES BOTH SIDES. politicians.photo_custom_url is what the backend read paths
-- render; the politician_images row of type='default' is what the browse grid reads. Writing
-- one without the other renders on one surface and blanks on the other (CC_0195/CC_0196).
-- Verified post-import: 14 of 14 carry the scalar, exactly ONE default row, and the two agree.
--
-- SOURCE AND LICENCE, read per site and never inferred from the host:
--   Adam Carranza          press_use  https://files.smartsites.parentsquare.com/5230/img_pd_184420_d7376c.jpg
--   Alicia Mignano         press_use  https://resources.finalsite.net/images/v1752612565/smmusdorg/p6obm4ic9itiixvsxd6t/Alicia_Mignano.png
--   Andy Coradeschi        press_use  https://streamline.imgix.net/e0390b07-d426-44e1-91fe-5172ec63d313/df1158dc-e95d-4d69-8fa5-2362ff9ce76c/image.png
--   Brian Guerrero         press_use  https://3.files.edl.io/a245/23/01/19/060453-3f78bc73-eee2-4faf-8505-fa80c940b6f3.jpg
--   Cindy Wu               press_use  https://files.smartsites.parentsquare.com/5230/img_pd_184901_27b7b9.jpeg
--   James D. Bodnar        unknown    https://www.cvwd.com/wp-content/uploads/d24367453e3078b42db3eb4857d5a2eafd30746b.webp
--   Jeffery W. Johnson     unknown    https://www.cvwd.com/wp-content/uploads/384ffd19f522ee66fe81ba82e484dd653dd6f583.webp
--   Laurie Lieberman       press_use  https://resources.finalsite.net/images/v1752611613/smmusdorg/erqcwvjtgmaicu6khn4w/Laurie_Lieberman.png
--   Stacy Rouse            press_use  https://resources.finalsite.net/images/v1752939759/smmusdorg/aqdqrtqo8fzvfajcv6ih/Stacy-Rouse-rev.png
--   Stephanie Loredo       press_use  https://3.files.edl.io/8a19/25/01/06/222546-d48dca17-b4d5-4187-8f6c-8842ccf6398a.jpg
--   Theresa Lee            press_use  https://walnutvalleywater.gov/wp-content/uploads/2022/12/2019-Lee-Director-3-16x20-1.jpg
--   Tommy Faavae           press_use  https://www.westbasinca.gov/home/showpublishedimage/2044/638765991608270000
--   Triston Ezidore        press_use  https://3.files.edl.io/5f6f/23/01/12/220932-66cb7693-8d06-46e2-9078-2f225e38835c.jpg
--   Veronica Sifuentes     press_use  https://files.smartsites.parentsquare.com/5230/img_pd_184706_7e9dd9.jpg
--
-- Two licence findings this wave paid for, recorded because they change what may be sourced:
--
--   1. BALLOTREADY IS A REFUSAL, NOT A SOURCE. Its terms define "Services Content" to include
--      "images" explicitly and then forbid reproducing or publishing any of it, with no press
--      carve-out. Our notes called it "the source that keeps working for local candidates",
--      and 21 active politicians already cite it as their photo origin — 19 of them recorded
--      press_use, all mirrored into our bucket. That claim is not supported by the source.
--      It cost this wave three people (Vrsalovich, Worthington, Blades-Snell). The existing
--      Ballotpedia rule applies unchanged: AN AGGREGATOR IS A POINTER, NOT A GRANTOR — the
--      photographs are candidate-submitted, so re-source each from the candidate's own site.
--      NOT fixed here; it is its own piece.
--
--   2. A GOVERNMENT SITE IS NOT AUTOMATICALLY A PERMISSIVE ONE, AGAIN. cvwd.com's footer
--      asserts "All Rights Reserved" — a positive reservation, not the silence case — so
--      Bodnar and Johnson are recorded 'unknown' rather than press_use. An unknown is findable
--      by the query that looks for missing provenance; a guessed licence is not.
--
-- WHAT IS DELIBERATELY NOT HERE. 11 of the 25 in this cohort stay BLANK, each for a stated
-- reason, because a blank beats a wrong or unusable image and keeps the person in the backlog:
--   * Santa Monica College publishes its trustees in BLACK AND WHITE (chroma 0.00, neutral
--     share 1.000 — pure greyscale, measured, not borderline), refusing Roy, Peters and
--     Barrera Castanon under the standing no-monochrome rule. All four SMC seats are blocked.
--   * Foothill MWD publishes NO member portraits at all — text bios only. That is the body's
--     practice and the answer to the question, not a search failure.
--   * La Canada Irrigation District has no website that resolves.
--   * Carla D. Dillon is not yet on her district's roster; she takes office 2026-12-04.
--   * Robbie Staenberg's BallotReady image is the grey placeholder silhouette, caught by
--     reading the src — the alt said "Headshot of Robbie".
--   * "Amy Chen" was refused on IDENTITY, not licence: a BallotReady page of that name names
--     no office, so nothing ties it to our Foothill Division 4 winner.
--   * Patrick W. Atwater carries a live namesake risk — a RICHARD Atwater retired from that
--     same board in February 2026.
--
-- ONE DEFECT THE GATES MISSED AND THE EYE CAUGHT. Walnut Valley's published portrait of
-- Theresa Lee is 4800x6000 with a PURE-BLACK BORDER — 505px left, 504px right, 161px top,
-- 160px bottom, measured; all four corners read exactly 15.0, which is the disc-on-matte
-- signature. check-portrait-framing.mjs returned FRAMED: none with its own controls passing.
-- The border was cropped off before import (corners now 18.4-22.4, the real studio backdrop),
-- so the stored file is the de-bordered crop. WHY THE GATE PASSED IT IS UNDIAGNOSED and is
-- worth a look: it prints only its flagged list, not per-row numbers for rows that pass.
--
-- A FIRST BORDER DETECTOR OF MINE REPORTED 13 OF 14 FRAMES BORDERED AND WAS WRONG. It
-- measured "distance inward to the first brightness change", which on any graduated studio
-- backdrop fires well inside the frame; the near-uniform answer was the tell. The replacement
-- asks whether a ring is FLAT ALONG ITS LENGTH, AGREES ON ALL FOUR SIDES and CONTRASTS with
-- the interior, and it was watched going red on Lee's bordered file (flatness 0.0) and green
-- on the de-bordered copy of THE SAME PHOTOGRAPH (17.3) before any result was believed.
--
-- CROP. All 14 use the shared 4:5 crop (scripts/headshot_crop.py), measured not eyeballed:
-- face centre 47.5-54.1% of frame width, face-box centre and eye midpoint agreeing within
-- 0-25px. Bodnar and Johnson carry anchor_y=0 because the default centre crop took their
-- crowns to 0.12 and 0.03 ear-lengths of headroom; at anchor_y=0 they sit at 0.31 and 0.37.
-- NOTHING IS ENLARGED: six are stored at NATIVE size (400x500, 576x720, and 300x375 three
-- times) rather than upscaled to 600x750, because inventing pixels is worse than a small
-- honest frame. The three 300x375 are SMMUSD's published ceiling, not a crop choice.
--
-- VERIFIED AGAINST THE PUBLIC CDN, NOT THE UPLOAD'S OWN 200. All 14 target paths returned
-- NoSuchKey before the run, with a known-good object returning 200 as the control, so these
-- are fresh objects and need no ?v= cache key. After the run all 14 were re-fetched from the
-- public URL and re-gated: 14 real colour faces, correct rotation, 0 failures. The live
-- rendered <img> was read for Triston Ezidore — 600x750 from our bucket, credit line shown.

BEGIN;

-- Both sides are already true in production; these statements are guarded so a re-run is a
-- no-op and the post-verify proves the END STATE rather than this file's own row counts.
CREATE TEMP TABLE cc_0383_imported (politician_id uuid, url text, photo_license text) ON COMMIT DROP;
INSERT INTO cc_0383_imported (politician_id, url, photo_license) VALUES
  ('c3f6a27c-8462-5ddf-bbea-9000e33a3ce2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c3f6a27c-8462-5ddf-bbea-9000e33a3ce2-headshot.jpg', 'press_use'),
  ('665372e8-49fe-4c6e-9930-fca6ed3430f0'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/665372e8-49fe-4c6e-9930-fca6ed3430f0-headshot.jpg', 'press_use'),
  ('87d51b68-0018-5721-9c96-ec9393b3bff7'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/87d51b68-0018-5721-9c96-ec9393b3bff7-headshot.jpg', 'press_use'),
  ('40df5b12-202f-4f06-917d-5b9883441046'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/40df5b12-202f-4f06-917d-5b9883441046-headshot.jpg', 'press_use'),
  ('be76a99b-a702-4318-9efd-a9e9e4790193'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/be76a99b-a702-4318-9efd-a9e9e4790193-headshot.jpg', 'press_use'),
  ('c950eeaa-9fb9-589b-85ab-0b712388d308'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c950eeaa-9fb9-589b-85ab-0b712388d308-headshot.jpg', 'unknown'),
  ('eba3e605-1284-58a0-b082-72ffccb63778'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eba3e605-1284-58a0-b082-72ffccb63778-headshot.jpg', 'unknown'),
  ('0952f897-7414-4ad3-af88-022de9e4971c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0952f897-7414-4ad3-af88-022de9e4971c-headshot.jpg', 'press_use'),
  ('3cf22d9d-f6fd-404c-b6ba-a1e4b7fb830d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3cf22d9d-f6fd-404c-b6ba-a1e4b7fb830d-headshot.jpg', 'press_use'),
  ('a73ad2b6-dedd-4186-b451-cf8b7898c098'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a73ad2b6-dedd-4186-b451-cf8b7898c098-headshot.jpg', 'press_use'),
  ('2091d942-0d57-5843-9da0-9fcaa2293e0e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2091d942-0d57-5843-9da0-9fcaa2293e0e-headshot.jpg', 'press_use'),
  ('939c52a4-660b-5e99-96f5-fae35e94ed01'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/939c52a4-660b-5e99-96f5-fae35e94ed01-headshot.jpg', 'press_use'),
  ('38aa3e5d-2824-4810-af6d-ad4d8f2bd359'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/38aa3e5d-2824-4810-af6d-ad4d8f2bd359-headshot.jpg', 'press_use'),
  ('71ba46a1-2bb4-5864-94d6-4547969b7fe3'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/71ba46a1-2bb4-5864-94d6-4547969b7fe3-headshot.jpg', 'press_use');

UPDATE essentials.politicians p
   SET photo_custom_url = i.url
  FROM cc_0383_imported i
 WHERE p.id = i.politician_id
   AND p.photo_custom_url IS DISTINCT FROM i.url;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT i.politician_id, i.url, 'default', i.photo_license
  FROM cc_0383_imported i
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                    WHERE pi.politician_id = i.politician_id AND pi.type = 'default');

DO $$
DECLARE
  missing_scalar int;
  wrong_default  int;
  disagreeing    int;
BEGIN
  -- 1. every one of the 14 renders from the scalar the backend read paths use
  SELECT count(*) INTO missing_scalar
    FROM cc_0383_imported i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE btrim(coalesce(p.photo_custom_url, '')) = '';
  IF missing_scalar <> 0 THEN
    RAISE EXCEPTION 'CC_0383: % of 14 carry no photo_custom_url - they would render blank on address search', missing_scalar;
  END IF;

  -- 2. EXACTLY ONE default row each. Two make the grid's find() pick an arbitrary one.
  SELECT count(*) INTO wrong_default FROM (
    SELECT i.politician_id FROM cc_0383_imported i
      LEFT JOIN essentials.politician_images pi
        ON pi.politician_id = i.politician_id AND pi.type = 'default'
     GROUP BY i.politician_id HAVING count(pi.*) <> 1) x;
  IF wrong_default <> 0 THEN
    RAISE EXCEPTION 'CC_0383: % of 14 do not have exactly one type=default image row', wrong_default;
  END IF;

  -- 3. THE TWO SIDES AGREE. This is the CC_0195/CC_0196 defect: the scalar and the grid's row
  --    pointing at different objects renders one picture on one surface and another, or
  --    nothing at all, on the other.
  SELECT count(*) INTO disagreeing
    FROM cc_0383_imported i
    JOIN essentials.politicians p ON p.id = i.politician_id
    JOIN essentials.politician_images pi
      ON pi.politician_id = i.politician_id AND pi.type = 'default'
   WHERE pi.url IS DISTINCT FROM p.photo_custom_url;
  IF disagreeing <> 0 THEN
    RAISE EXCEPTION 'CC_0383: % of 14 have a default image row that disagrees with photo_custom_url', disagreeing;
  END IF;

  RAISE NOTICE 'CC_0383 ok: 14 headshots, scalar set, exactly one default row each, both sides agree';
END
$$;

COMMIT;
