-- 1893_federal_generic_sourcing_three_rows_season2.sql
-- The three federal rows that survived the generic-sourcing triage (ev-accounts #897). All three
-- are Season 1 only; all three are written FORWARD into Season 2. 3 context rows + 3 answer rows
-- INSERTED. Nothing updated, nothing deleted. SEASON 1 IS NOT TOUCHED.
--
-- 🔴 WHY A FORWARD WRITE AND NOT A FIX. Season 1 is CLOSED and IMMUTABLE --
-- `inform.closed_season_is_immutable()` rejects any UPDATE there, and its own error text names the
-- remedy: write a row in the OPEN season, which shadows the old one on read without destroying
-- history. Same shape as migration 1870. Season 2 is frozen for topics and chairs but stances
-- remain open, so these writes are in bounds.
--
-- 🔑 THE LADDER IS THE SAME REVISION IN BOTH SEASONS FOR ALL THREE TOPICS, so nothing is being
-- carried across a re-scale: tariffs pins 9f094155 in S1 and S2, taxes 87f8c011, ukraine-support
-- 107d180d. The guard below asserts each one rather than trusting this comment.
--
-- ── HOW THESE THREE WERE FOUND, because the number matters for how much to trust them ───────────
-- The national generic-sourcing queue was re-measured on 2026-10-06 at 3,266 keys. Its federal
-- slice is 578 keys / 216 politicians. Joining that slice to the 2026-08-11 Tier B record left 92
-- keys in the two defect-SHAPED cells (TOPIC_ABSENT). Re-testing those 92 keys (110 rows across
-- seasons) against each ROW'S OWN WORDS rather than a topic lexicon returned 79 PAGE_NOT_SILENT,
-- 28 WEAK_ONLY and 3 PAGE_SILENT. **A ~97% over-fire on the first cut.** These are the 3.
-- 🔴 They are not one class and are not dispositioned alike. Two are blanks; one is a citation
-- repair that leaves the chair exactly where it was.
--
-- ⚠ A SECOND SOURCE WAS CHECKED ON EACH, AND IT MATTERED. Every one of these rows cites TWO
-- Wikipedia URLs -- the member's own article AND an article about a BILL. The claim-on-page guard
-- tests the article ABOUT THE PERSON, so the bill articles were fetched and read separately before
-- any disposition was written. That check is what separates row 3 from rows 1 and 2.
--
-- ── 1. Lisa C. McClain / United States Tariff Policy -- BLANK (S1 chair 4) ──────────────────────
-- Reasoning argues from "a close Trump ally", her Republican Conference Chair role, and "consistent
-- Trump alignment". A leadership role is not a position and an alignment score is not a position.
-- Her own article is silent on every distinctive phrase in the row. The other cited source, the
-- One Big Beautiful Bill Act article, **does not mention McClain at all** (0 occurrences), and its
-- six "tariff" mentions are about Trump's tariff policy generally and a de-minimis repeal -- none
-- is a tariff position held by her. Neither cited page supports the chair.
--
-- ── 2. Kim Schrier / Ukraine-Russia Conflict -- BLANK (S1 chair 2) ──────────────────────────────
-- Reasoning: "Schrier voted 100% with President Biden's positions as of mid-2023 per Wikipedia,
-- which included major Ukraine aid packages", plus "The Lend-Lease Act for Ukraine passed 417-10".
-- Two independent problems. A presidential-alignment percentage is not a position -- it is an
-- aggregate someone else computed. And **417-10 cannot establish a DISTINCTIVE position**: being in
-- a 417-member majority says nothing a ladder can seat (the Lehman 130-1 rule). The cited
-- Lend-Lease article does not mention Schrier (0 occurrences); her own article is silent on the
-- row's words. The row never claims she cast a particular vote.
--
-- ── 3. David J. Taylor / Taxation and Public Spending -- CITATION REPAIR, CHAIR UNCHANGED AT 4 ──
-- 🔑 A BAD CITATION IS NOT A FALSE CLAIM. The row says Taylor "voted YES on the One Big Beautiful
-- Bill Act (OBBBA, H.R. 1, passed 215-214 on May 22 2025 and 218-214 on July 3 2025)". The cited
-- OBBBA article carries the bill and both totals but **does not record how Taylor voted** -- its two
-- "Taylor" hits are Marjorie Taylor GREENE and a journalist named Taylor Hatmaker. His own article
-- is silent. So the personal claim was unsourced by its own citations.
-- ✅ IT IS ALSO TRUE, and now verified from the primary record rather than from an encyclopaedia:
--   roll 145, 22-May-2025, H R 1, "On Passage", 215-214-1-2  -> Taylor: Yea
--   roll 190,  3-Jul-2025, H R 1, "On Motion to Concur in the Senate Amendment", 218-214 -> Aye
-- Both rolls were resolved from GovTrack's bill page rather than guessed, and BOTH were evaluated
-- rather than the first match taken. Self-checks taken: the parsed per-member tallies equal the
-- declared overall totals exactly (215/214/1/2 and 218/214).
-- ⚠ Read the OVERALL totals, not the first ones in the file: the Clerk XML puts `totals-by-party`
-- BEFORE `totals-by-vote`, so a first-match regex returns the Republican nay count (2), not 214.
-- ⚠ IDENTITY: the sheet carries exactly ONE Taylor -- `name-id="T000490" party="R" state="OH"`,
-- David Taylor of Ohio. The Clerk disambiguates shared surnames when it must (`Biggs (AZ)` vs
-- `Biggs (SC)` are both on this sheet), so a bare "Taylor" is unambiguous here rather than unchecked.
-- Both citation URLs were fetched: each returns 200, names "One Big Beautiful", carries "Taylor",
-- and carries its own total (215 on /2025145, 218 on /2025190).
--
-- ⚖ A BLANK IS NOT A REVERSAL. value 0 says the question has not been answered on this person. It
-- does not assert the opposite chair, and both blanks are re-researchable: McClain and Schrier may
-- well hold the positions they were seated at. What is missing is evidence, not plausibility.
-- 🔑 Both blanks CARRY THE SOURCES THEY EXAMINED (migration 1887's rule) rather than an empty
-- array, so the next reader can see what was looked at and need not repeat it.
--
-- No migration runner exists; this file records SQL applied by hand via scripts/apply-migration-file.mjs.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  -- Season 1 must hold exactly these three chairs, or the cohort has moved under us.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND (politician_id, topic_id) IN (
       ('e04094d1-247c-40c8-8829-c7cb8654d0ed','683c8084-2281-4920-a07c-18439b2dd413'),
       ('9625b961-5455-4fcc-8da7-5995ef3b9924','24e9212c-b011-422a-865c-093e35050901'),
       ('1938e59f-bd7c-45fb-8dd1-2f7591a0fc3d','f7e5678d-dadd-4556-a2fc-446e24642ceb'));
  IF n <> 3 THEN
    RAISE EXCEPTION 'migration 1893: expected 3 Season 1 rows for this cohort, found %', n;
  END IF;

  -- Season 2 must hold none of them yet, or this is a re-run and would duplicate.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (politician_id, topic_id) IN (
       ('e04094d1-247c-40c8-8829-c7cb8654d0ed','683c8084-2281-4920-a07c-18439b2dd413'),
       ('9625b961-5455-4fcc-8da7-5995ef3b9924','24e9212c-b011-422a-865c-093e35050901'),
       ('1938e59f-bd7c-45fb-8dd1-2f7591a0fc3d','f7e5678d-dadd-4556-a2fc-446e24642ceb'));
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1893: Season 2 already holds % row(s) for this cohort', n;
  END IF;

  -- Each topic's Season 2 pin, asserted rather than assumed. All three match their Season 1 pin,
  -- which is why chair 4 can be carried forward unchanged for Taylor.
  SELECT count(*) INTO n FROM inform.season_questions
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (topic_id, topic_revision_id) IN (
       ('683c8084-2281-4920-a07c-18439b2dd413','9f094155-f604-47e8-93db-54a3142420ca'),
       ('24e9212c-b011-422a-865c-093e35050901','107d180d-a949-4a42-a250-54f0a7683be0'),
       ('f7e5678d-dadd-4556-a2fc-446e24642ceb','87f8c011-5c70-4f39-a1ea-5cc53c010c60'));
  IF n <> 3 THEN
    RAISE EXCEPTION 'migration 1893: Season 2 does not pin the expected revision for all 3 topics (found %)', n;
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
VALUES
  -- 1. Lisa C. McClain / Tariffs — blank
  ('e04094d1-247c-40c8-8829-c7cb8654d0ed','683c8084-2281-4920-a07c-18439b2dd413',
   '86d893a1-c1a2-4bbf-b4e5-69ec43221194','9f094155-f604-47e8-93db-54a3142420ca', NULL,
   $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats McClain at chair 4 on inference rather than on anything she said or did about tariffs: it argues from her being "a close Trump ally", from her Republican Conference Chair role, and from "consistent Trump alignment". A leadership role is not a position and an alignment score is not a position — both are facts about where someone sits, not about what they hold. Both cited pages were read. Her own Wikipedia article is silent on every distinctive phrase in the row. The other source, the One Big Beautiful Bill Act article, does not mention McClain at all, and its references to tariffs concern Trump's tariff policy generally and the repeal of the de minimis entry privilege — neither is a tariff position held by her. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here. Season 1 keeps the original row unchanged as the historical record of what was once claimed.$r$,
   ARRAY['https://en.wikipedia.org/wiki/Lisa_McClain','https://en.wikipedia.org/wiki/One_Big_Beautiful_Bill_Act']),

  -- 2. Kim Schrier / Ukraine — blank
  ('9625b961-5455-4fcc-8da7-5995ef3b9924','24e9212c-b011-422a-865c-093e35050901',
   '86d893a1-c1a2-4bbf-b4e5-69ec43221194','107d180d-a949-4a42-a250-54f0a7683be0', NULL,
   $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Schrier at chair 2 on two things, neither of which can carry a chair. The first is that she "voted 100% with President Biden's positions as of mid-2023" — a presidential-alignment percentage is an aggregate someone else computed, not a position she stated. The second is that the Ukraine Democracy Defense Lend-Lease Act "passed 417-10": a vote that lopsided cannot establish a DISTINCTIVE position, because being one of 417 is not a choice a ladder can seat, and the row does not in fact claim she cast that vote. Both cited pages were read. Her own Wikipedia article is silent on the row's distinctive wording, and the Lend-Lease article does not mention Schrier at all. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here — a recorded vote of hers on a divided Ukraine measure would settle it. Season 1 keeps the original row unchanged as the historical record of what was once claimed.$r$,
   ARRAY['https://en.wikipedia.org/wiki/Kim_Schrier','https://en.wikipedia.org/wiki/Ukraine_Democracy_Defense_Lend-Lease_Act_of_2022']),

  -- 3. David J. Taylor / Taxation — citation repair, chair unchanged at 4
  ('1938e59f-bd7c-45fb-8dd1-2f7591a0fc3d','f7e5678d-dadd-4556-a2fc-446e24642ceb',
   '86d893a1-c1a2-4bbf-b4e5-69ec43221194','87f8c011-5c70-4f39-a1ea-5cc53c010c60', NULL,
   $r$Taylor voted for the One Big Beautiful Bill Act (H.R. 1, 119th Congress) at both of its House votes: Yea on roll call 145 of 22 May 2025, "On Passage", which carried 215-214; and Aye on roll call 190 of 3 July 2025, "On Motion to Concur in the Senate Amendment", which carried 218-214. The Act permanently extends the 2017 individual and corporate rate cuts, adds deductions for tips and overtime, and offsets part of the cost through reductions in federal spending. Voting twice for a statute that locks in lower rates and pays for them with spending reductions is chair 4 — cut taxes and scale back public services to match — rather than chair 3's hold-the-structure-as-it-is. The chair is unchanged from Season 1; what changed is the evidence under it. The Season 1 row rested on the Act's Wikipedia article, which carries the bill and both totals but does not record how any individual member voted, so his vote was asserted rather than cited. It is now cited to the Clerk of the House's own roll-call record for each vote.$r$,
   ARRAY['https://clerk.house.gov/Votes/2025145','https://clerk.house.gov/Votes/2025190','https://en.wikipedia.org/wiki/One_Big_Beautiful_Bill_Act']);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
VALUES
  -- McClain, tariffs: S1 chair 4 -> blank
  ('e04094d1-247c-40c8-8829-c7cb8654d0ed','683c8084-2281-4920-a07c-18439b2dd413',
   '86d893a1-c1a2-4bbf-b4e5-69ec43221194','9f094155-f604-47e8-93db-54a3142420ca', NULL, 0),
  -- Schrier, ukraine-support: S1 chair 2 -> blank
  ('9625b961-5455-4fcc-8da7-5995ef3b9924','24e9212c-b011-422a-865c-093e35050901',
   '86d893a1-c1a2-4bbf-b4e5-69ec43221194','107d180d-a949-4a42-a250-54f0a7683be0', NULL, 0),
  -- Taylor, taxes: chair 4 carried forward UNCHANGED, with the roll-call citation
  ('1938e59f-bd7c-45fb-8dd1-2f7591a0fc3d','f7e5678d-dadd-4556-a2fc-446e24642ceb',
   '86d893a1-c1a2-4bbf-b4e5-69ec43221194','87f8c011-5c70-4f39-a1ea-5cc53c010c60', NULL, 4);

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (politician_id, topic_id) IN (
       ('e04094d1-247c-40c8-8829-c7cb8654d0ed','683c8084-2281-4920-a07c-18439b2dd413'),
       ('9625b961-5455-4fcc-8da7-5995ef3b9924','24e9212c-b011-422a-865c-093e35050901'),
       ('1938e59f-bd7c-45fb-8dd1-2f7591a0fc3d','f7e5678d-dadd-4556-a2fc-446e24642ceb'));
  IF n <> 3 THEN
    RAISE EXCEPTION 'migration 1893: expected 3 Season 2 answer rows after insert, found %', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND value = 0
     AND (politician_id, topic_id) IN (
       ('e04094d1-247c-40c8-8829-c7cb8654d0ed','683c8084-2281-4920-a07c-18439b2dd413'),
       ('9625b961-5455-4fcc-8da7-5995ef3b9924','24e9212c-b011-422a-865c-093e35050901'));
  IF n <> 2 THEN
    RAISE EXCEPTION 'migration 1893: expected 2 blanks, found %', n;
  END IF;

  -- Season 1 must be exactly as it was, PER ROW. A forward write that moved history is a failed one.
  -- ⚠ Asserting `value IN (4,2)` across the cohort would pass if two rows swapped chairs, so each
  -- (politician, topic, value) triple is named.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND (politician_id, topic_id, value) IN (
       ('e04094d1-247c-40c8-8829-c7cb8654d0ed','683c8084-2281-4920-a07c-18439b2dd413', 4),
       ('9625b961-5455-4fcc-8da7-5995ef3b9924','24e9212c-b011-422a-865c-093e35050901', 2),
       ('1938e59f-bd7c-45fb-8dd1-2f7591a0fc3d','f7e5678d-dadd-4556-a2fc-446e24642ceb', 4));
  IF n <> 3 THEN
    RAISE EXCEPTION 'migration 1893: Season 1 no longer holds its original 3 chairs unchanged (found %)', n;
  END IF;
END $$;

COMMIT;
