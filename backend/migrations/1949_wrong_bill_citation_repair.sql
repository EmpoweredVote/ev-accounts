-- Migration 1949 — the wrong-bill citation repair pass.
--
-- 🔴🔴 A CITATION PASS MUST NOT MOVE A CHAIR. Every row here keeps the value it had, on the rung
-- revision it had, and GUARD 6 plus the post-flight block assert it before and after. Nothing in
-- this file adjudicates anything; it repairs pointers whose correct target is known and fetched.
--
-- 21 serving rows are written: 19 Season 2 context rows updated in place, and 2 Season 1-serving
-- rows carried forward as Season 2 inserts at the same value on the SAME ladder revision.
--
--   rows  defect                                                  remedy                   mode
--   ----  ------------------------------------------------------  -----------------------  ------
--     13  2021 MA Climate Act cited as H.4933 (prose and link)     link -> /192/S9          UPDATE
--      1  the same, plus a second bad pointer (H.2983)             link -> /192/S9          UPDATE
--      2  prose says H.4933; the only link was H.2983              /192/S9 ADDED            UPDATE
--      1  no Act link at all; the only link was H.2983             /192/S9 ADDED            UPDATE
--      2  Safe Communities Act linked at /194/H2288                link -> /193/H2288       UPDATE
--      2  MBTA Communities Act cited as H.4933                     link -> Chapter 358      INSERT
--
-- 4 further VOTER-FACING rows carry a wrong citation and are NOT written, plus 3 already-withdrawn
-- ones with nothing to repair. They are listed in section D with the reason, which in every case is
-- that repairing them would require this pass to decide something.
-- Full record: backend/data/stance-research/2026-10-26-wrong-bill-citations/LEDGER.md
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- A. WHAT THE DEFECT IS, AND WHY NOTHING CATCHES IT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- The row's prose names the right Act and the citation points at a different bill. It was found by
-- hand four times in four adjudication passes (migrations 1945, 1947, 1948) and never by a check:
-- a real bill on the right legislature's site satisfies check-stance-sources, and prose naming an
-- act satisfies audit-chair-evidence. Only opening the cited page catches it.
--
-- 🔴🔴 AND A NUMBER-CONSISTENCY DETECTOR CANNOT CATCH IT EITHER — measured, not assumed. Across
-- the 812 serving voter-facing rows that cite a malegislature.gov bill page, comparing the bill
-- numbers named in prose against the bill numbers in the cited URLs leaves exactly 5 rows with no
-- number in common. The reason is structural: when a row is miscited, the prose and the link carry
-- THE SAME wrong number. H.4933 appears in both halves of all 14 climate rows. The two halves
-- agree with each other and both disagree with reality, so any check that compares them is blind
-- by construction. ▶ The detector has to fetch the cited page and compare its TITLE with the act
-- named in the prose. That sweep was started for this pass and got through 388 of the 726 distinct
-- bill pages before malegislature.gov degraded under it; it is recorded in the ledger. 🔴 A further
-- 92 paths answered 404 during that window and are NOT treated as evidence — a later spot-check
-- returned HTTP 500 for /Bills/192/S9, a page verified as 200 the same day.
--
-- 🔴🔴 THAT PARTIAL SWEEP FOUND THREE MORE COHORTS, ALL BIGGER THAN ANYTHING REPAIRED HERE, AND
-- ALL BLOCKED. 34 `immigration` rows cite a RECOVERY HIGH SCHOOLS bill (/192/S2745, 20 rows) and a
-- MUNICIPAL UTILITY POLE bill (/192/H3256, 14 rows, described as "the Work and Family Mobility
-- Act"). They are beyond a CITATION pass: Season 1 is closed and `immigration` is not in Season 2.
-- ⚖ That absence is DELIBERATE, not a gap — CA_0066_immigration_freeze_remove_s2.sql removed the
-- topic on 2026-08-31 because THREE Season 2 topics already own its dimensions (deportation q9,
-- border-security q46, local-immigration q28) and it overlapped deportation 72% (1212/1678). So the
-- subject was carried forward; moving these members onto a successor topic is a RE-SEAT ON A
-- DIFFERENT LADDER, which is adjudication. 🔑 "No Season 2 question" is a fact about one
-- season_questions row, never about whether the subject survived — look for successors first. And:
-- 18 voter-facing voting-rights rows say the member "voted for the 2022 VOTES Act" and cite
-- /Bills/192/S2977 — which is ORDER S.2977, "Order relative to authorizing the joint committee on
-- Mental Health, Substance Use and Recovery to make an investigation and study of ... a model
-- school policy on suicide prevention". A study order cited as a landmark act, exactly like H.4933.
-- Migration 1900 already recorded the VOTES Act's vehicle (S.2545 -> S.2554 -> S.2924, Chapter 92
-- of the Acts of 2022), so the target is known — but all 18 serve from the closed Season 1 and the
-- VOTING-RIGHTS LADDER WAS WHOLLY REPLACED between seasons (Season 1 ranks ballot access, Season 2
-- ranks voter ID), so a repair would move every one of them onto a different question.
-- ▶ Adjudication, not citation repair. NOT touched by this file.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- B. THE PAGES, OPENED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- All fetched 26 October 2026; the h1 gives the document kind and the General Court, the first h2
-- the official title.
--
--   /Bills/192/S9      Bill  192nd   An Act creating a next-generation roadmap for Massachusetts
--                                    climate policy            <- THE 2021 CLIMATE ACT, Chapter 8
--                                    of the Acts of 2021, signed 26 March 2021.
--   /Bills/192/H4933   ORDER 192nd   certain matters concerning municipal governance
--                                    🔑 NOT AN ACT AT ALL. It is an Order of the Joint Committee
--                                    on Municipalities and Regional Government, referred to House
--                                    Rules — the vehicle by which a batch of municipal petitions
--                                    is sent to study. Migration 1948 called it "An Act relative
--                                    to certain matters concerning municipal governance"; the page
--                                    says Order, and the distinction is the point.
--   /Bills/193/H2288   Bill  193rd   An Act to protect the civil rights and safety of all
--                                    Massachusetts residents   <- THE SAFE COMMUNITIES ACT
--   /Bills/194/H2288   Bill  194th   An Act relative to MBTA communities   <- a housing bill
--   /Bills/191/H5250   Bill  191st   An Act enabling partnerships for growth. Signed in part as
--                                    CHAPTER 358 OF THE ACTS OF 2020, approved 14 January 2021.
--                                    SECTION 18 inserts section 3A into chapter 40A of the General
--                                    Laws: every "MBTA community shall have a zoning ordinance or
--                                    by-law that provides for at least 1 district of reasonable
--                                    size in which multi-family housing is permitted as of right".
--                                    🔑 THAT IS THE MBTA COMMUNITIES ACT. The Governor pocket
--                                    vetoed sections 48, 50, 55, 62, 63, 83, 85, 95, 102, 106 and
--                                    113; section 18 is not among them.
--   /Bills/194/H2983   Bill  194th   An Act concerning investments of the Massachusetts Pension
--                                    Reserve Investment Management (PRIM)
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- C. 🔴🔴 H.2983 IS A DIFFERENT AND WORSE DEFECT, AND IT IS NOT REPAIRED HERE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Five serving rows describe "H.2983 (100% Clean Energy by 2045)" and link to /Bills/194/H2983,
-- the PRIM pension-investment bill. The other wrong citations in this corpus have all been ONE
-- COURT OFF — the same number in a neighbouring General Court is the act the prose names, which is
-- what makes them repairable. This one is not. H.2983 was opened in all five courts this corpus
-- touches:
--     190th  An Act regarding Massachusetts drug price relief
--     191st  An Act establishing transit improvement districts
--     192nd  An Act extending a property tax exemption to the surviving spouse of blind persons
--     193rd  An Act relative to the enhanced disposition of surplus motor vehicles ...
--     194th  An Act concerning investments of the Massachusetts PRIM
-- None is a clean-energy bill. There is no correct target to point at, so THE CITATION IS LEFT
-- EXACTLY AS IT WAS and recorded in each row's own notice — replacing evidence with a guess is not
-- a citation pass's job, and deleting it would erase the only trace of the defect while the
-- sentence that rests on it stays in the prose. ▶ Owed to an adjudication pass.
-- ⚠ Four of the five rows are repaired here for their OTHER citation and keep their chair on the
-- Act, which migration 1948 read. The fifth is Adrian C. Madaro on fossil-fuels, and that row
-- rests on H.2983 and nothing else — see section D.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- D. THE 4 VOTER-FACING ROWS LEFT ALONE, AND WHY EACH IS NOT THIS FILE'S BUSINESS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔑 THE TEST THAT DECIDED EVERY ONE OF THEM: a Season 1-serving row can only be repaired by
-- INSERTING a Season 2 row (Season 1 is closed), and carrying the value across preserves the chair
-- ONLY IF the Season 2 rung at that value says the same thing. Two of the five topics here share
-- the SAME topic_revision_id across both seasons, so the chair cannot move and the repair is safe
-- (that is the Honan pair, written below). The rest fail the test or have no target.
--
--   2  Michael J. Moran, Rob Consalvo — climate-change, Season 1 chair 3, citing /192/H4933.
--      🔴 THE CLIMATE LADDER WAS REWRITTEN BETWEEN SEASONS, from ambition to instrument. Season 1
--      chair 3 is "invest in clean energy while gradually reducing reliance on fossil fuels";
--      Season 2 chair 3 is "Speed up clean energy by cutting permitting red tape and upgrading the
--      grid". Carrying the 3 across would publish a different position, so repairing the citation
--      would move the chair. Migration 1948 deliberately left these two seated on their own
--      recorded caution. ▶ An adjudication pass has to take them, not this one.
--   1  Adrian C. Madaro — fossil-fuels, Season 1 chair 2. The whole row is "co-sponsored 100%
--      Clean Energy legislation (H.2983)". Per section C no such bill exists under that number in
--      any court, so there is nothing to point the citation at. ⚠ This is a VOTER-FACING CHAIR
--      RESTING ENTIRELY ON A BILL THAT CANNOT BE FOUND, which is a stronger finding than a bad
--      link and belongs to an adjudication pass. ▶ Recorded, not repaired.
--   1  Dr. Joaquin Arambula — campaign-finance, Season 1 chair 2: "Voted Aye on SB-42 (Fair
--      Elections Act Assembly Appropriations 8/15/24)". The cited bill_id 202320240SB42 is the
--      CARE Court Program Act and the vote is real; the Fair Elections Act is SB 42 of 2025-26 and
--      cannot have been voted on in 2024. The description is wrong, not the link, so swapping the
--      link would manufacture a false claim. Migration 1945 withdrew 15 rows in exactly this
--      position; this row was not among them because it serves from Season 1. ▶ It needs 1945's
--      ruling applied, which is a chair move.
--   3  Avelino Valencia, Cottie Petrie-Norris, Laurie Davies — campaign-finance, already withdrawn
--      to 0 by migration 1945, whose notice names the collision. Not voter-facing; nothing to fix.
--      (Listed for completeness; the 4 above are the voter-facing ones.)
--
-- ⚠ The two Kevin G. Honan rows, on transportation-priorities and residential-zoning, were in this
-- list until the revision check was run. They are Season 1-serving and cite H.4933 as the MBTA
-- Communities Act — but BOTH TOPICS CARRY THE SAME topic_revision_id IN BOTH SEASONS, so the
-- Season 2 insert lands on the same rung by identity and the chair cannot move. They are written.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- E. WHAT IS AND IS NOT TOUCHED IN A REPAIRED ROW
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- The notice is PREPENDED and the row's existing text is kept byte for byte below it, exactly as
-- migrations 1947 and 1948 did. That leaves the wrong number standing inside the original prose,
-- which is deliberate: the published wording stays readable as the record of what was published,
-- and the correction is read first. Each notice says so in as many words, which is what separates
-- this from the stale-prose-after-a-fix defect of migration 1730 — there the fixed row's own words
-- silently contradicted its citation with nothing to explain the gap.
-- 🔑 Migration 1899 already repaired H.4264 -> S.9 for the against-side climate rows, so S.9 is the
-- established target in this corpus and 7 of the 42 rows migration 1948 wrote cite it correctly
-- already. The corpus demonstrably knows the right number, which is what makes these repairable.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE TARGETS, FROZEN. wrong_url is the pointer to replace (NULL where there was none to replace
-- and the correct one is simply missing); correct_url must be present when the row is written.
-- Nothing below hard-codes a value or a revision: both are read from the row as it stands.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE mig1949_upd ON COMMIT DROP AS
SELECT t.politician_id, t.topic_id, t.op, t.wrong_url, t.correct_url,
       pa.value               AS value_before,
       pa.topic_revision_id   AS rev_before,
       pc.reasoning           AS reasoning_before,
       pc.sources             AS sources_before,
       CASE WHEN t.correct_url = ANY(sw.arr) THEN sw.arr
            ELSE array_prepend(t.correct_url, sw.arr) END AS sources_after
  FROM (VALUES
  -- 13 rows: the 2021 Climate Act cited as H.4933 in both the prose and the link.
  ('9cf147de-64e0-4116-b461-95933e18c423'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-link','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Bills/192/S9'),  -- Aaron Michlewitz
  ('5c497509-7a9d-492b-ac35-ff37f8fcfb82'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-link','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Bills/192/S9'),  -- Brandy Fluker-Reid
  ('bca54df2-f059-44ce-81c3-f208f1e20752'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-link','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Bills/192/S9'),  -- Christopher J. Worrell
  ('fd3bf15c-265b-46a9-aa72-c9097749d762'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-link','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Bills/192/S9'),  -- Chynah Tyler
  ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-link','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Bills/192/S9'),  -- Daniel J. Ryan
  ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-link','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Bills/192/S9'),  -- David Biele
  ('c539c9fa-a531-456f-9125-8d30f1fcedfe'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-link','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Bills/192/S9'),  -- Jeffrey R. Turco
  ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-link','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Bills/192/S9'),  -- Jessica A. Giannino
  ('7cc9694b-3bca-44ec-ab75-762c1f6d5136'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-link','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Bills/192/S9'),  -- John F. Moran
  ('c4c3ed02-2592-4505-a26c-0195d0b5314e'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-link','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Bills/192/S9'),  -- Judith A. Garcia
  ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-link','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Bills/192/S9'),  -- Kevin G. Honan
  ('e96b35eb-dad1-4a29-b416-d9b10838840f'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-link','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Bills/192/S9'),  -- Russell E. Holmes
  ('194b9b91-6986-423e-89a0-ee9750f275d8'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-link','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Bills/192/S9'),  -- William F. MacGregor
  -- 1 row: the same, and it carries the H.2983 pointer as well.
  ('852e4a21-5750-4ac8-ba06-0376c5a31685'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-link-and-h2983','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Bills/192/S9'),  -- Jay Livingstone
  -- 2 rows: the prose says H.4933, and the only bill link was the PRIM bill. Nothing to replace.
  ('5c36a94c-9006-4550-a37e-978a65d2725c'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-prose-only',NULL,'https://malegislature.gov/Bills/192/S9'),  -- Daniel J. Hunt
  ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'h4933-prose-only',NULL,'https://malegislature.gov/Bills/192/S9'),  -- Samantha Montaño
  -- 1 row: no H.4933 anywhere; the Act it was seated on was simply never cited.
  ('290ee018-6e9e-4a8c-9561-385cf5ef3d73'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'act-uncited',NULL,'https://malegislature.gov/Bills/192/S9'),  -- Adrian C. Madaro
  -- 2 rows: the Safe Communities Act, linked one General Court late.
  ('2ada2d01-a77a-44f6-a569-916d9639fbdc'::uuid,'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid,'safe-communities','https://malegislature.gov/Bills/194/H2288','https://malegislature.gov/Bills/193/H2288'),  -- Priscila S. Sousa
  ('c70bd1f2-6ba2-446e-a40c-d07f446db214'::uuid,'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid,'safe-communities','https://malegislature.gov/Bills/194/H2288','https://malegislature.gov/Bills/193/H2288')   -- Thomas M. Stanley
  ) AS t(politician_id, topic_id, op, wrong_url, correct_url)
  JOIN inform.politician_answers pa
    ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
   AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
  JOIN inform.politician_context pc
    ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
  CROSS JOIN LATERAL (
    SELECT array_agg(u ORDER BY ord) AS arr
      FROM (SELECT CASE WHEN t.wrong_url IS NOT NULL AND s = t.wrong_url THEN t.correct_url ELSE s END AS u,
                   min(ord) AS ord
              FROM unnest(pc.sources) WITH ORDINALITY AS e(s, ord)
             GROUP BY 1) z
  ) sw;

-- The two Season 1-serving rows. Both topics carry THE SAME topic_revision_id in both seasons, so
-- the Season 2 insert is a forward copy onto an identical ladder and the chair cannot move.
CREATE TEMP TABLE mig1949_ins ON COMMIT DROP AS
SELECT t.politician_id, t.topic_id, t.op, t.wrong_url, t.correct_url,
       pa.value             AS value_before,
       pa.topic_revision_id AS rev_before,
       pa.updated_at        AS s1_updated_at,
       pc.reasoning         AS reasoning_before,
       pc.sources           AS sources_before,
       sq.topic_revision_id AS s2_revision,
       CASE WHEN t.correct_url = ANY(sw.arr) THEN sw.arr
            ELSE array_prepend(t.correct_url, sw.arr) END AS sources_after
  FROM (VALUES
  ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4'::uuid,'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid,'mbta-communities','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Laws/SessionLaws/Acts/2020/Chapter358'),  -- Kevin G. Honan, transportation-priorities
  ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4'::uuid,'d4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid,'mbta-communities','https://malegislature.gov/Bills/192/H4933','https://malegislature.gov/Laws/SessionLaws/Acts/2020/Chapter358')   -- Kevin G. Honan, residential-zoning
  ) AS t(politician_id, topic_id, op, wrong_url, correct_url)
  JOIN inform.politician_answers pa
    ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
   AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.politician_context pc
    ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   AND pc.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.season_questions sq
    ON sq.topic_id = t.topic_id AND sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
  CROSS JOIN LATERAL (
    SELECT array_agg(u ORDER BY ord) AS arr
      FROM (SELECT CASE WHEN s = t.wrong_url THEN t.correct_url ELSE s END AS u, min(ord) AS ord
              FROM unnest(pc.sources) WITH ORDINALITY AS e(s, ord)
             GROUP BY 1) z
  ) sw;

-- GUARD 1 — the target set is exactly what was read.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1949_upd;
  IF n <> 19 THEN RAISE EXCEPTION 'migration 1949: expected 19 update targets, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1949_ins;
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1949: expected 2 insert targets, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1949_upd WHERE op = 'h4933-link';
  IF n <> 13 THEN RAISE EXCEPTION 'migration 1949: h4933-link expected 13, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1949_upd WHERE op = 'h4933-link-and-h2983';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1949: h4933-link-and-h2983 expected 1, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1949_upd WHERE op = 'h4933-prose-only';
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1949: h4933-prose-only expected 2, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1949_upd WHERE op = 'act-uncited';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1949: act-uncited expected 1, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1949_upd WHERE op = 'safe-communities';
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1949: safe-communities expected 2, found %', n; END IF;
  SELECT count(*) INTO n FROM (SELECT DISTINCT politician_id, topic_id FROM mig1949_upd) q;
  IF n <> 19 THEN RAISE EXCEPTION 'migration 1949: duplicate update targets; % distinct of 19', n; END IF;
  SELECT count(*) INTO n FROM (SELECT DISTINCT politician_id, topic_id FROM mig1949_ins) q;
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1949: duplicate insert targets; % distinct of 2', n; END IF;
END $$;

-- GUARD 2 — every target still has the text and citations this pass read, and none has been
-- repaired already.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM (SELECT reasoning_before r, sources_before s FROM mig1949_upd
                               UNION ALL SELECT reasoning_before, sources_before FROM mig1949_ins) q
   WHERE r IS NULL OR btrim(r) = '' OR s IS NULL OR cardinality(s) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % target(s) have no reasoning or citation', n; END IF;
  SELECT count(*) INTO n FROM (SELECT reasoning_before r FROM mig1949_upd
                               UNION ALL SELECT reasoning_before FROM mig1949_ins) q
   WHERE r LIKE '%migration 1949%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % target(s) already carry a 1949 notice', n; END IF;
  -- the 17 climate rows are the Season 2 rows migration 1948 wrote; the 2 immigration rows are 1947's.
  SELECT count(*) INTO n FROM mig1949_upd
   WHERE topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND reasoning_before NOT LIKE '%migration 1948%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % climate target(s) are not the rows migration 1948 wrote', n; END IF;
  SELECT count(*) INTO n FROM mig1949_upd
   WHERE topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND reasoning_before NOT LIKE '%migration 1947%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % immigration target(s) are not the rows migration 1947 wrote', n; END IF;
END $$;

-- GUARD 3 — the defect is really present on every target, and really is what each op says it is.
DO $$
DECLARE n int;
BEGIN
  -- where a wrong_url is named, the row must actually carry it
  SELECT count(*) INTO n FROM (SELECT wrong_url w, sources_before s FROM mig1949_upd
                               UNION ALL SELECT wrong_url, sources_before FROM mig1949_ins) q
   WHERE w IS NOT NULL AND NOT (w = ANY(s));
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % target(s) do not carry the wrong URL named for them', n; END IF;
  -- and must not already carry the correct one in its place
  SELECT count(*) INTO n FROM mig1949_upd WHERE wrong_url IS NULL AND correct_url = ANY(sources_before);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % target(s) already cite the correct URL', n; END IF;
  -- the prose-level claim each op asserts
  SELECT count(*) INTO n FROM mig1949_upd
   WHERE op IN ('h4933-link','h4933-link-and-h2983','h4933-prose-only') AND reasoning_before !~ 'H\.? ?4933';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % row(s) typed as naming H.4933 do not name it', n; END IF;
  SELECT count(*) INTO n FROM mig1949_upd WHERE op = 'act-uncited' AND reasoning_before ~ 'H\.? ?4933';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: the act-uncited row names H.4933 after all'; END IF;
  SELECT count(*) INTO n FROM mig1949_upd
   WHERE op IN ('h4933-link-and-h2983','h4933-prose-only','act-uncited')
     AND NOT ('https://malegislature.gov/Bills/194/H2983' = ANY(sources_before));
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % row(s) typed as citing H.2983 do not cite it', n; END IF;
  SELECT count(*) INTO n FROM mig1949_upd WHERE op = 'safe-communities' AND reasoning_before NOT LIKE '%193rd General Court%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % safe-communities row(s) do not name the 193rd in prose', n; END IF;
END $$;

-- GUARD 4 — seasons, and the ladder identity the Season 2 inserts depend on.
DO $$
DECLARE n int; t1 text; t2 text;
BEGIN
  SELECT count(*) INTO n FROM inform.seasons WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND status = 'open';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1949: Season 2 is not the open season'; END IF;
  SELECT count(*) INTO n FROM inform.seasons WHERE id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND status <> 'open';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1949: Season 1 is not closed'; END IF;

  -- 🔴 THE LOAD-BEARING ASSERTION FOR THE TWO INSERTS: the Season 1 answer and the Season 2
  -- question are on the SAME revision, so carrying the value across is the same rung by identity,
  -- not by a rung_map's say-so. A rung_map can lie; this cannot.
  SELECT count(*) INTO n FROM mig1949_ins WHERE rev_before <> s2_revision;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % insert target(s) would change ladder revision — STOP, the chair could move', n; END IF;
  -- and belt and braces: the rung text at that value is byte-identical in both seasons
  SELECT count(*) INTO n FROM mig1949_ins i
   WHERE (SELECT r.text FROM inform.compass_stance_revisions r
           WHERE r.topic_revision_id = i.rev_before AND r.value = i.value_before)
      IS DISTINCT FROM
         (SELECT r.text FROM inform.compass_stance_revisions r
           WHERE r.topic_revision_id = i.s2_revision AND r.value = i.value_before);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % insert target(s) sit on a rung whose text differs between seasons', n; END IF;

  -- the inserts must not collide with an existing Season 2 row
  SELECT count(*) INTO n FROM mig1949_ins i
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers pa
                  WHERE pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id
                    AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid)
      OR EXISTS (SELECT 1 FROM inform.politician_context pc
                  WHERE pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id
                    AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % insert target(s) ALREADY have a Season 2 row', n; END IF;

  -- nobody inactive
  SELECT count(*) INTO n FROM (SELECT politician_id FROM mig1949_upd UNION ALL SELECT politician_id FROM mig1949_ins) q
    JOIN essentials.politicians p ON p.id = q.politician_id WHERE NOT p.is_active;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % target(s) are on inactive people', n; END IF;
END $$;

-- GUARD 5 — the repaired arrays are well formed: the wrong pointer is gone, the right one is
-- present, nothing else moved, and no row lost a citation.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM (SELECT wrong_url w, correct_url c, sources_before b, sources_after a FROM mig1949_upd
                               UNION ALL SELECT wrong_url, correct_url, sources_before, sources_after FROM mig1949_ins) q
   WHERE a IS NULL OR NOT (c = ANY(a)) OR (w IS NOT NULL AND w = ANY(a))
      OR cardinality(a) < cardinality(b) OR cardinality(a) > cardinality(b) + 1;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % repaired citation array(s) are malformed', n; END IF;
  -- every source that was not the wrong one survives
  SELECT count(*) INTO n FROM (SELECT wrong_url w, correct_url c, sources_before b, sources_after a FROM mig1949_upd
                               UNION ALL SELECT wrong_url, correct_url, sources_before, sources_after FROM mig1949_ins) q,
       LATERAL unnest(q.b) AS kept
   WHERE kept IS DISTINCT FROM w AND NOT (kept = ANY(a));
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % citation(s) other than the wrong one were dropped', n; END IF;
  -- 🔴 H.2983 IS DELIBERATELY NOT REMOVED (section C). Assert that, so a later edit cannot quietly
  -- start deleting evidence under cover of a citation pass.
  SELECT count(*) INTO n FROM mig1949_upd
   WHERE 'https://malegislature.gov/Bills/194/H2983' = ANY(sources_before)
     AND NOT ('https://malegislature.gov/Bills/194/H2983' = ANY(sources_after));
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % row(s) would silently drop the H.2983 pointer', n; END IF;
END $$;

-- GUARD 6 — POPULATIONS. Every serving, voter-facing row citing one of these wrong pages is either
-- a target or one of the 6 recorded in section D. Measured 26 October 2026 against the live corpus.
DO $$
DECLARE n int;
BEGIN
  CREATE TEMP TABLE mig1949_serving ON COMMIT DROP AS
  SELECT DISTINCT ON (pa.politician_id, pa.topic_id)
         pa.politician_id, pa.topic_id, pa.season_id, pa.value, pc.sources
    FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE p.is_active AND pa.season_id <> '7b3a066c-815d-43b2-a6a0-6a3029778075'::uuid
   ORDER BY pa.politician_id, pa.topic_id, (pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid) DESC;

  SELECT count(*) INTO n FROM mig1949_serving
   WHERE value <> 0 AND 'https://malegislature.gov/Bills/192/H4933' = ANY(sources);
  IF n <> 18 THEN RAISE EXCEPTION 'migration 1949: expected 18 voter-facing rows citing H.4933, found % — re-read before writing', n; END IF;
  SELECT count(*) INTO n FROM mig1949_serving
   WHERE value <> 0 AND 'https://malegislature.gov/Bills/194/H2288' = ANY(sources);
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1949: expected 2 voter-facing rows citing /194/H2288, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1949_serving
   WHERE value <> 0 AND 'https://malegislature.gov/Bills/194/H2983' = ANY(sources);
  IF n <> 5 THEN RAISE EXCEPTION 'migration 1949: expected 5 voter-facing rows citing H.2983, found %', n; END IF;

  -- Of the 18, this file takes 16: 14 by update and the 2 Honan rows by insert. The 2 it does not
  -- take are the climate chair-3 rows of section D, which the rewritten climate ladder blocks.
  SELECT count(*) INTO n FROM mig1949_serving s
   WHERE s.value <> 0 AND 'https://malegislature.gov/Bills/192/H4933' = ANY(s.sources)
     AND NOT EXISTS (SELECT 1 FROM mig1949_upd u WHERE u.politician_id = s.politician_id AND u.topic_id = s.topic_id)
     AND NOT EXISTS (SELECT 1 FROM mig1949_ins i WHERE i.politician_id = s.politician_id AND i.topic_id = s.topic_id);
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1949: expected 2 untargeted H.4933 rows (the climate chair-3 pair), found %', n; END IF;
END $$;

-- GUARD 7 — 🔴🔴 THE CHAIR GUARD. Not one target may be seated at 0, and none is being moved: the
-- value is read from the row and written back unchanged. The post-flight block proves it held.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM (SELECT value_before v FROM mig1949_upd UNION ALL SELECT value_before FROM mig1949_ins) q
   WHERE v IS NULL OR v = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % target(s) are blank — a citation pass has nothing to repair on a withdrawn row', n; END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE WRITE. The notice is prepended; the row's own text follows byte for byte.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
UPDATE inform.politician_context pc
   SET reasoning = CASE u.op

  WHEN 'h4933-link' THEN '[migration 1949, 2026-10-26] CITATION REPAIRED; THE CHAIR IS UNCHANGED. This row cited the 2021 Massachusetts Climate Act as "H.4933" and linked to malegislature.gov/Bills/192/H4933. That page is not that Act, and it is not an Act at all: it is ORDER H.4933 of the 192nd General Court, "certain matters concerning municipal governance", sponsored by the Joint Committee on Municipalities and Regional Government and referred to the House Committee on Rules — the vehicle by which a batch of municipal petitions is sent to study. The Act is SENATE BILL 9 of the same General Court, "An Act creating a next-generation roadmap for Massachusetts climate policy", signed 26 March 2021 as Chapter 8 of the Acts of 2021, and the citation now points there (https://malegislature.gov/Bills/192/S9, opened 26 October 2026). 🔑 A BAD CITATION IS NOT A FALSE CLAIM. What this row says the member did is not doubted here, migration 1948 read the Act itself before seating this chair, and the value is untouched. ⚠ The wording below is the row''s ORIGINAL text and still says "H.4933". It is left exactly as it was, because it is the record of what was published; read this notice first — the number in the sentence below is wrong and the bill is S.9.

'
  WHEN 'h4933-link-and-h2983' THEN '[migration 1949, 2026-10-26] CITATION REPAIRED; THE CHAIR IS UNCHANGED. This row cited the 2021 Massachusetts Climate Act as "H.4933" and linked to malegislature.gov/Bills/192/H4933. That page is not that Act, and it is not an Act at all: it is ORDER H.4933 of the 192nd General Court, "certain matters concerning municipal governance", referred to the House Committee on Rules. The Act is SENATE BILL 9 of the same General Court, "An Act creating a next-generation roadmap for Massachusetts climate policy", signed 26 March 2021 as Chapter 8 of the Acts of 2021, and the citation now points there (https://malegislature.gov/Bills/192/S9, opened 26 October 2026). 🔑 A BAD CITATION IS NOT A FALSE CLAIM: migration 1948 read the Act itself before seating this chair, and the value is untouched. ⚠ AND THIS ROW CITES A SECOND BILL THAT IS NOT WHAT IT SAYS, which is NOT repaired. It describes "H.2983 (100% Clean Energy by 2045)" and links to malegislature.gov/Bills/194/H2983, which is "An Act concerning investments of the Massachusetts Pension Reserve Investment Management (PRIM)". H.2983 was opened in all five General Courts this corpus touches — 190th, a drug pricing bill; 191st, transit improvement districts; 192nd, a property tax exemption; 193rd, surplus motor vehicles; 194th, the PRIM bill — and NONE is a clean-energy bill, so unlike the H.4933 error this is not a court mix-up and there is no correct target to point at. The link is therefore left exactly as it was and the defect recorded here, because replacing evidence with a guess is not a citation pass''s job. ▶ Whether the sentence resting on it survives is for an adjudication pass; this chair does not rest on it. ⚠ The wording below is the row''s ORIGINAL text and still says "H.4933" — read this notice first.

'
  WHEN 'h4933-prose-only' THEN '[migration 1949, 2026-10-26] CITATION REPAIRED; THE CHAIR IS UNCHANGED. This row names the 2021 Massachusetts Climate Act as "H.4933" and cited no page for it at all: its only bill link was malegislature.gov/Bills/194/H2983. The Act is SENATE BILL 9 of the 192nd General Court, "An Act creating a next-generation roadmap for Massachusetts climate policy", signed 26 March 2021 as Chapter 8 of the Acts of 2021, and that citation has now been ADDED (https://malegislature.gov/Bills/192/S9, opened 26 October 2026). H.4933 of the 192nd is not that Act and is not an Act at all — it is an ORDER, "certain matters concerning municipal governance". 🔑 A BAD CITATION IS NOT A FALSE CLAIM: migration 1948 read the Act itself before seating this chair, and the value is untouched. ⚠ THE H.2983 LINK IS KEPT AND IS NOT WHAT THE ROW SAYS IT IS. It is described as "H.2983 (100% Clean Energy by 2045)"; the page is "An Act concerning investments of the Massachusetts Pension Reserve Investment Management (PRIM)". H.2983 was opened in all five General Courts this corpus touches — 190th, a drug pricing bill; 191st, transit improvement districts; 192nd, a property tax exemption; 193rd, surplus motor vehicles; 194th, the PRIM bill — and none is a clean-energy bill, so there is no correct target to swap in. It is left as it was and recorded here rather than guessed at or deleted. ▶ For an adjudication pass. ⚠ The wording below is the row''s ORIGINAL text and still says "H.4933" — read this notice first.

'
  WHEN 'act-uncited' THEN '[migration 1949, 2026-10-26] CITATION REPAIRED; THE CHAIR IS UNCHANGED. The Act this row is seated on was never cited: its only bill link was malegislature.gov/Bills/194/H2983. The citation for the 2021 Massachusetts Climate Act has now been ADDED — SENATE BILL 9 of the 192nd General Court, "An Act creating a next-generation roadmap for Massachusetts climate policy", signed 26 March 2021 as Chapter 8 of the Acts of 2021 (https://malegislature.gov/Bills/192/S9, opened 26 October 2026). Migration 1948 read that Act before seating this chair, and the value is untouched. ⚠ THE H.2983 LINK IS KEPT AND IS NOT WHAT THE ROW SAYS IT IS. The row describes "H.2983 (100% Clean Energy by 2045)"; the page is "An Act concerning investments of the Massachusetts Pension Reserve Investment Management (PRIM)". H.2983 was opened in all five General Courts this corpus touches — 190th, a drug pricing bill; 191st, transit improvement districts; 192nd, a property tax exemption; 193rd, surplus motor vehicles; 194th, the PRIM bill — and none is a clean-energy bill, so there is no correct target to swap in; it is left as it was and recorded here. ▶ For an adjudication pass. ⚖ The other number in the prose below, H.4264 for environmental justice legislation, is RIGHT and must not be "corrected": H.4264 of the 191st General Court is "An Act relative to environmental justice in the commonwealth" (opened 26 October 2026). It is only in the 192nd that H.4264 is the Truro rental housing trust bill that migration 1899 found miscited elsewhere.

'
  WHEN 'safe-communities' THEN '[migration 1949, 2026-10-26] CITATION REPAIRED; THE CHAIR IS UNCHANGED. This row''s own words name the Massachusetts Safe Communities Act correctly — H.2288 / S.1510 of the 193rd GENERAL COURT — but the link pointed at malegislature.gov/Bills/194/H2288, which in the 194th General Court is "An Act relative to MBTA communities", a housing bill. The link now points at the 193rd General Court''s H.2288, "An Act to protect the civil rights and safety of all Massachusetts residents" (https://malegislature.gov/Bills/193/H2288, opened 26 October 2026). The co-sponsorship this row rests on was re-checked on that bill''s own Cosponsor page, which lists 17 petitioners and includes both Thomas M. Stanley and Priscila S. Sousa (opened 26 October 2026). In the 194th General Court the Act is H.2580 / S.1681. 🔑 A BILL NUMBER IS ONLY AN ADDRESS WHEN THE GENERAL COURT IS GIVEN WITH IT — Massachusetts renumbers every court, and this is the third time one number has pointed at two unrelated bills in this corpus.

'
       END || u.reasoning_before,
       sources = u.sources_after
  FROM mig1949_upd u
 WHERE pc.politician_id = u.politician_id
   AND pc.topic_id = u.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- The two Season 2 inserts. Same value, same revision, repaired citation.
INSERT INTO inform.politician_answers (politician_id, topic_id, season_id, topic_revision_id, value)
SELECT i.politician_id, i.topic_id, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, i.s2_revision, i.value_before
  FROM mig1949_ins i;

INSERT INTO inform.politician_context (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
SELECT i.politician_id, i.topic_id, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, i.s2_revision,
       '[migration 1949, 2026-10-26] CITATION REPAIRED; THE CHAIR IS UNCHANGED. This row cites the MBTA Communities Act as "H.4933" and linked to malegislature.gov/Bills/192/H4933. That page is ORDER H.4933 of the 192nd General Court, "certain matters concerning municipal governance" — an order referring a batch of municipal petitions to the House Committee on Rules, not a law and not about housing. The MBTA Communities requirement is SECTION 18 OF CHAPTER 358 OF THE ACTS OF 2020, "An Act enabling partnerships for growth", approved 14 January 2021, which inserts section 3A into chapter 40A of the General Laws: an "MBTA community shall have a zoning ordinance or by-law that provides for at least 1 district of reasonable size in which multi-family housing is permitted as of right". The citation now points at that enacted text (https://malegislature.gov/Laws/SessionLaws/Acts/2020/Chapter358, opened 26 October 2026); the bill was H.5250 of the 191st General Court, and the Governor''s partial veto struck sections 48, 50, 55, 62, 63, 83, 85, 95, 102, 106 and 113 — section 18 is not among them, so the requirement is law. 🔑 So the row''s SECTION reference, 3A, was right all along and only its bill number was wrong; "2021" is right too, because the act was signed in January 2021 although it is a 2020 session law. ⚠ WHAT THIS NOTICE DOES NOT DO: it does not check what the member did. This row claims authorship, and no pass has yet tested that claim against the record — pointing a citation at the right instrument makes the row checkable, not verified. ▶ For an adjudication pass. 🔴 This row served from the CLOSED Season 1 and could only be repaired forward, so this is a Season 2 row carrying the Season 1 value unchanged. That is safe here and only here because this topic''s Season 1 answer and Season 2 question are ON THE SAME LADDER REVISION — the rung is the same rung by identity, not by a rung_map''s say-so — which the migration asserts before writing. The Season 1 row is untouched. The original reasoning and citations follow.

' || i.reasoning_before,
       i.sources_after
  FROM mig1949_ins i;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- POST-FLIGHT.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  -- 🔴🔴 NOT ONE CHAIR MOVED. This is the assertion the whole file exists under.
  SELECT count(*) INTO n FROM mig1949_upd u
    JOIN inform.politician_answers pa
      ON pa.politician_id = u.politician_id AND pa.topic_id = u.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value IS DISTINCT FROM u.value_before OR pa.topic_revision_id IS DISTINCT FROM u.rev_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % repaired row(s) MOVED A CHAIR', n; END IF;
  SELECT count(*) INTO n FROM mig1949_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value IS DISTINCT FROM i.value_before OR pa.topic_revision_id IS DISTINCT FROM i.s2_revision;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % inserted row(s) do not carry the Season 1 value', n; END IF;

  -- the repairs landed
  SELECT count(*) INTO n FROM mig1949_upd u
    JOIN inform.politician_context pc
      ON pc.politician_id = u.politician_id AND pc.topic_id = u.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.sources IS DISTINCT FROM u.sources_after
      OR strpos(pc.reasoning, u.reasoning_before) = 0
      OR pc.reasoning NOT LIKE '%migration 1949%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % updated row(s) lost prose, citations or notice', n; END IF;
  SELECT count(*) INTO n FROM mig1949_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.sources IS DISTINCT FROM i.sources_after
      OR strpos(pc.reasoning, i.reasoning_before) = 0
      OR pc.reasoning NOT LIKE '%migration 1949%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % inserted row(s) lost prose, citations or notice', n; END IF;

  -- 🔴 SEASON 1 IS CLOSED AND UNTOUCHED.
  SELECT count(*) INTO n FROM mig1949_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id
     AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
   WHERE pa.value <> i.value_before OR pa.topic_revision_id <> i.rev_before
      OR pa.updated_at IS DISTINCT FROM i.s1_updated_at;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % Season 1 answer(s) MOVED', n; END IF;
  SELECT count(*) INTO n FROM mig1949_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id
     AND pc.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
   WHERE pc.reasoning IS DISTINCT FROM i.reasoning_before OR pc.sources IS DISTINCT FROM i.sources_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % Season 1 context row(s) were rewritten', n; END IF;

  -- and the corpus-level result: only the 2 rows section D names still cite H.4933, none cites
  -- /194/H2288, and the 5 H.2983 rows are all still there because none of them was repairable.
  CREATE TEMP TABLE mig1949_after ON COMMIT DROP AS
  SELECT DISTINCT ON (pa.politician_id, pa.topic_id) pa.politician_id, pa.topic_id, pa.value, pc.sources
    FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE p.is_active AND pa.season_id <> '7b3a066c-815d-43b2-a6a0-6a3029778075'::uuid
   ORDER BY pa.politician_id, pa.topic_id, (pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid) DESC;

  SELECT count(*) INTO n FROM mig1949_after
   WHERE value <> 0 AND 'https://malegislature.gov/Bills/192/H4933' = ANY(sources);
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1949: % voter-facing rows still cite H.4933, expected the 2 left in section D', n; END IF;
  SELECT count(*) INTO n FROM mig1949_after
   WHERE value <> 0 AND 'https://malegislature.gov/Bills/194/H2288' = ANY(sources);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1949: % voter-facing rows still cite /194/H2288', n; END IF;
  -- 24 voter-facing rows cited S.9 before this pass (migrations 1899 and 1948 between them); the
  -- 17 climate repairs above take it to 41.
  SELECT count(*) INTO n FROM mig1949_after
   WHERE value <> 0 AND 'https://malegislature.gov/Bills/192/S9' = ANY(sources);
  IF n <> 41 THEN RAISE EXCEPTION 'migration 1949: % voter-facing rows cite S.9, expected 41', n; END IF;
END $$;

COMMIT;
