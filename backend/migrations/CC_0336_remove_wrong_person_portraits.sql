-- CC_0336_remove_wrong_person_portraits.sql
--
-- Take down three portraits: TWO ARE A DIFFERENT HUMAN BEING, one cannot be shown to be the right
-- one. Found by sweeping all 40 remaining no-origin Creative Commons rows for IDENTITY rather than
-- for attribution, the follow-up `CC_0335` asked for.
--
-- 🟢 THE POPULATION IS NOT ROTTEN: 37 OF 40 ARE THE RIGHT PERSON. `CC_0335` found 2 wrong in the
-- first 3 it opened, but those three were selected precisely BECAUSE their licence contradicted a
-- seed manifest, which selects for this defect. 2-in-3 was a property of that sample; the bucket's
-- real rate is 2 in 40. ⚠ Do not quote the sample rate as the population rate.
--
-- ============================================================================================
-- THE TWO WRONG PEOPLE
-- ============================================================================================
--   ALICIA ROMERO (0226381e-…) — we record her as a Council Member for the City of Bell,
--   California. The stored photograph is ALÍCIA ROMERO LLANO, of the Socialists' Party of
--   Catalonia: a member of the Parliament of Catalonia since 2012 and, from 2024, Catalonia's
--   Minister of Economy and Finance. The red-and-yellow stripes behind her are the senyera, the
--   Catalan flag. ⚠ Separately, Bell's own council roster (read 2026-11-02) lists Quintana,
--   Saleh, Arroyo, Sifuentes and Flores — no Alicia Romero at all.
--
--   DAN SCHWARTZ (70226cbc-…) — we record the Democratic nominee in MARYLAND's 1st congressional
--   district, who is 37. The stored photograph is DANIEL MARK SCHWARTZ, NEVADA State Treasurer
--   from January 2015 to January 2019, a Republican born in 1950. The banner behind him reads
--   "Republican M… Northern". 🔴 His election is 2026-11-03, the day after this migration.
--
-- 🔴 THE LICENCE WAS TRUE ABOUT THE FILE AND FALSE ABOUT THE ROW. Each of these really is a
-- namesake's Wikipedia lead image, and that image really does carry the CC licence we recorded.
-- The bogus licence and the bogus face have ONE cause, which is why `cc_<anything>` with no
-- recorded origin works as a namesake detector.
--
-- ============================================================================================
-- THE ONE THAT COULD NOT BE SETTLED
-- ============================================================================================
--   MATTHEW DUNLAP (f1681124-…), Maine. Ours shows a man with a full head of dark hair and a
--   narrower face than BOTH Wikipedia's portrait of him AND Maine's own official photograph of its
--   State Auditor (maine.gov/audit/images/MDunlap-photo.jpg, 1995x2545) — which agree with each
--   other. It could be the same man fifteen years earlier; it could be someone else. ⚠ NOT
--   ASSERTED EITHER WAY. With the identity unverifiable AND the licence unsupported, the
--   photograph should not stand in for a real person, so it comes down too (operator's ruling,
--   2026-11-02). ▶ Maine publishes a large official portrait; replacing it is clean follow-up work
--   once maine.gov's use policy has been read.
--
-- ============================================================================================
-- 🔴 VALUES THIS MIGRATION DESTROYS, RECORDED HERE BECAUSE NOTHING ELSE RECORDS THEM
-- ============================================================================================
-- Each person has EXACTLY ONE politician_images row and it is their 'default'. For each, the row
-- is deleted and politicians.photo_custom_url is set to NULL. photo_origin_url is already NULL on
-- all three and is not touched.
--
--   Alicia Romero   image 4cf3237f-e724-4b52-b746-a769160765f8  licence 'cc_by-sa_4.0'
--     url = photo_custom_url =
--     https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/0226381e-8146-44c6-a1e0-d7ac1a15b79f/default.png
--   Dan Schwartz    image 3def84c6-ba05-44f3-a206-0ff4826385e7  licence 'cc_by_3.0'
--     url = photo_custom_url =
--     https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/70226cbc-2707-4962-835e-175a2864d3d4-headshot.jpg
--   Matthew Dunlap  image c15684b2-5d81-4197-a4b1-bab8663bf5eb  licence 'cc_by-sa_3.0'
--     url = photo_custom_url =
--     https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f1681124-18d0-42c9-857c-7eecad4c7cd0-headshot.jpg
--
-- 🟢 NOTHING IN STORAGE IS DELETED. All three objects stay where they are, so a revert is
-- re-inserting the image row and restoring the scalar from the URLs above. ⚠ Note the two
-- hostnames: Romero's object is on `<ref>.supabase.co` and the other two on
-- `<ref>.storage.supabase.co`. Both serve; match on the PATH, never the host.
--
-- ============================================================================================
-- HOW IDENTITY WAS ESTABLISHED FOR ALL 40, INCLUDING THE 37 LEFT ALONE
-- ============================================================================================
-- 🟢 ASK WHETHER THE *ARTICLE* IS THE RIGHT PERSON, NOT WHETHER THE FACE LOOKS RIGHT. Nearly every
--   one of these files IS some Wikipedia article's lead image, so identity reduces to reading that
--   article's one-line description against the state and office we hold. BOTH failures were caught
--   by a description mismatch ("Spanish politician"; "born 1950" against a 37-year-old), not by
--   looking at a face. A namesake looks entirely plausible — that is the whole problem.
-- 🔴 MEAN ABSOLUTE DIFFERENCE WAS USELESS HERE. Pairs that were visibly the SAME photograph scored
--   1.4 to 38.2, because ours are 4:5 crops of the originals. Any threshold in that range would
--   have been arbitrary. Use MAD only for same-aspect pairs.
-- 🔴 "THESE LOOK LIKE DIFFERENT PEOPLE" WAS WRONG TWICE — Lacey Beaty and Matt Little, both judged
--   different against a single Wikipedia portrait, both then found as the SAME FILE inside Commons'
--   curated Category:<name>, beside other photographs of them at other ages. ▶ Pull the curated
--   CATEGORY before calling a face wrong. Where no category existed (Dunlap, Villegas, Kirkland) a
--   Commons FILE SEARCH found files that NAME the subject — "Randy Villegas at Vota Palooza in
--   2024.jpg" and "Kyle Kirkland, 2018.jpg" both match ours exactly, confirming both.
-- ⚠ Ballotpedia holds NO photo for Kirkland or Dunlap, only a "submit a photo" placeholder. An
--   aggregator's silence is not evidence of anything.
--
-- 🔴 A CORRECTION TO THIS HEADER, AND THE REASON IT IS WORTH READING. An earlier draft of this
-- comment reported, as an out-of-scope finding, that "Kyle Kirkland is a CA-21 candidate and Randy
-- Villegas a CA-22 candidate; we file both under California Congressional District 2".
-- 🟢 THAT WAS FALSE. Both are mapped correctly — Kirkland to `Congressional District 21`
-- (ocd-division/country:us/state:ca/cd:21) and Villegas to `Congressional District 22`
-- (…/cd:22). Re-read from production 2026-11-02.
--
-- 🔴🔴 THE DEFECT WAS IN MY OWN DISPLAY, NOT IN THE DATA: a throwaway report column formatted the
-- label with `.slice(0, 24)`, and "Congressional District " is exactly 23 characters — so EVERY
-- two-digit district printed as its first digit alone, and 21 and 22 both rendered as "2". Two
-- different candidates appearing in one implausible district is what made it look systemic.
-- ▶ **A TRUNCATED DISPLAY MANUFACTURES FINDINGS, AND IT BIASES THEM TOWARDS LOOKING LIKE
-- DUPLICATES** — distinct values collapse onto one another, which reads as exactly the kind of
-- collision worth reporting. Before believing a pattern, print the field at FULL WIDTH, or read
-- the stable key beside it: `ocd_id` carried the right answer the whole time and was never shown.
-- ⚠ Nothing else in this migration depended on it. The two wrong-person findings rest on the
-- Wikipedia articles' own text and on what is visible in the photographs, not on district numbers.
--
-- Run: node backend/scripts/apply-migration-file.mjs backend/migrations/CC_0336_remove_wrong_person_portraits.sql

BEGIN;

CREATE TEMP TABLE lic_before AS
  SELECT coalesce(photo_license, '<null>') AS lic, count(*) AS n
    FROM essentials.politician_images GROUP BY 1;

CREATE TEMP TABLE gone (
  politician_id uuid PRIMARY KEY,
  who           text NOT NULL,
  image_id      uuid NOT NULL,
  old_licence   text NOT NULL,
  reason        text NOT NULL
) ON COMMIT DROP;

INSERT INTO gone VALUES
 ('0226381e-8146-44c6-a1e0-d7ac1a15b79f'::uuid, 'Alicia Romero',
  '4cf3237f-e724-4b52-b746-a769160765f8'::uuid, 'cc_by-sa_4.0',
  'photograph is Alicia Romero Llano, Minister of Economy and Finance of Catalonia'),
 ('70226cbc-2707-4962-835e-175a2864d3d4'::uuid, 'Dan Schwartz',
  '3def84c6-ba05-44f3-a206-0ff4826385e7'::uuid, 'cc_by_3.0',
  'photograph is Daniel Mark Schwartz, Nevada State Treasurer 2015-2019, b.1950'),
 ('f1681124-18d0-42c9-857c-7eecad4c7cd0'::uuid, 'Matthew Dunlap',
  'c15684b2-5d81-4197-a4b1-bab8663bf5eb'::uuid, 'cc_by-sa_3.0',
  'identity unverifiable against Maine''s own official portrait; licence unsupported');

-- ---------------------------------------------------------------------------------------------
-- Pre-flight
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM gone g JOIN essentials.politicians p ON p.id = g.politician_id;
  IF n <> 3 THEN RAISE EXCEPTION 'pre-flight: expected 3 politicians, found %', n; END IF;

  -- Each must still be on the exact image row and licence the header records, or the record of
  -- what is being destroyed is already wrong and must not be trusted.
  SELECT count(*) INTO n
    FROM gone g
    JOIN essentials.politician_images pi ON pi.id = g.image_id
   WHERE pi.politician_id = g.politician_id
     AND pi.type = 'default'
     AND pi.photo_license = g.old_licence;
  IF n <> 3 THEN
    RAISE EXCEPTION 'pre-flight: expected 3 rows on their recorded image id AND licence, found %', n;
  END IF;

  -- 🔴 EXACTLY ONE IMAGE EACH. If a second row existed, deleting the default would promote an
  -- unexamined photograph into its place rather than clearing the face.
  SELECT count(*) INTO n
    FROM essentials.politician_images pi
    JOIN gone g ON g.politician_id = pi.politician_id
   WHERE pi.id <> g.image_id;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-flight: % extra image row(s) exist for these three', n; END IF;

  -- The scalar must still agree with the row, so one DELETE plus one UPDATE really does clear
  -- both read paths.
  SELECT count(*) INTO n
    FROM gone g
    JOIN essentials.politician_images pi ON pi.id = g.image_id
    JOIN essentials.politicians p ON p.id = g.politician_id
   WHERE p.photo_custom_url = pi.url;
  IF n <> 3 THEN RAISE EXCEPTION 'pre-flight: scalar and image row disagree on % of 3', 3 - n; END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
DELETE FROM essentials.politician_images pi USING gone g WHERE pi.id = g.image_id;

UPDATE essentials.politicians p SET photo_custom_url = NULL
  FROM gone g WHERE p.id = g.politician_id;

-- ---------------------------------------------------------------------------------------------
-- Post-verify. Meaning first; the arithmetic census last (CC_0328).
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE n int; v_before int; v_after int;
BEGIN
  -- 🔴 THE POINT: unreachable by EITHER path. The grid reads images[] and the backend reads the
  -- scalar, so clearing only one of them still shows the wrong man.
  SELECT count(*) INTO n
    FROM gone g
    LEFT JOIN essentials.politician_images pi ON pi.politician_id = g.politician_id
    LEFT JOIN essentials.politicians p ON p.id = g.politician_id
   WHERE pi.id IS NOT NULL
      OR coalesce(p.photo_custom_url, '') <> ''
      OR coalesce(p.photo_origin_url, '') <> '';
  IF n <> 0 THEN
    RAISE EXCEPTION 'post-verify: a removed photograph is still reachable on % row(s)', n;
  END IF;

  -- The three people themselves must survive. This removes a photograph, never a person.
  SELECT count(*) INTO n FROM gone g JOIN essentials.politicians p ON p.id = g.politician_id;
  IF n <> 3 THEN RAISE EXCEPTION 'post-verify: a politician row disappeared'; END IF;

  -- ⚠ DELTA, NOT TOTAL — another session can move the absolute number while this file is written.
  -- The no-origin CC population must fall by exactly these three, 40 -> 37.
  SELECT count(*) INTO v_after
    FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE pi.type = 'default'
     AND pi.photo_license ~* '^\s*cc[-_ ]?(by|zero)'
     AND lower(trim(pi.photo_license)) NOT LIKE 'cc0%'
     AND coalesce(p.photo_origin_url, '') = '';
  IF v_after <> 37 THEN
    RAISE EXCEPTION 'post-verify: expected the no-origin CC population to fall 40 -> 37, found %', v_after;
  END IF;

  -- Each licence value loses exactly one row, and nothing else moves at all.
  FOR v_before, n IN
    SELECT b.n, (SELECT count(*) FROM essentials.politician_images x WHERE x.photo_license = g2.old_licence)
      FROM (SELECT DISTINCT old_licence FROM gone) g2
      JOIN lic_before b ON b.lic = g2.old_licence
  LOOP
    IF n <> v_before - 1 THEN
      RAISE EXCEPTION 'post-verify: a touched licence moved % -> %, expected a fall of exactly 1', v_before, n;
    END IF;
  END LOOP;

  SELECT count(*) INTO n
    FROM (SELECT coalesce(photo_license, '<null>') AS lic, count(*) AS n
            FROM essentials.politician_images GROUP BY 1) a
    FULL JOIN lic_before b ON b.lic = a.lic
   WHERE coalesce(a.n, 0) <> coalesce(b.n, 0)
     AND coalesce(a.lic, b.lic) NOT IN ('cc_by-sa_4.0', 'cc_by_3.0', 'cc_by-sa_3.0');
  IF n <> 0 THEN
    RAISE EXCEPTION 'post-verify: % licence value(s) outside the three changed count', n;
  END IF;
END $$;

COMMIT;
