-- 1732_md_chairs_unreadable_session_correction.sql
-- CORRECTS MIGRATION 1731. Two of its three blanks were decided on an incomplete record.
--
-- 🔴🔴 A BLANK IS A FINDING OF ABSENCE, AND AN ABSENCE IS ONLY REAL IF THE RECORD WAS READABLE.
-- 1731 blanked three Voting Rights spokes after reading each row's complete CANDIDATE list. But a
-- candidate list is only as complete as the sessions behind it, and `md-member-legislation.mjs`
-- records sessions it could not read — mgaleg returns a page with ZERO bills, not an error, when a
-- member's record is asked for a session from before they switched chambers.
--
--   Alonzo T. Washington — 10 unreadable sessions (2013RS-2022RS: his ENTIRE House career), 4 read
--   C. Anthony Muse      —  7 unreadable sessions (2013RS-2019RS),                           4 read
--   Arthur Ellis         —  0 unreadable, 8 read
--
-- So Washington's 8 candidates and Muse's 22 were never their records; they were the tail of them.
-- Blanking on that is a manufactured absence — the exact defect this workstream exists to remove,
-- and the one the md-member-legislation header warns about in as many words. **Both answers are
-- restored to the chair they held (2), and both rows go back to OWED.**
--
-- ✅ Arthur Ellis's blank STANDS: 0 unreadable sessions, all 32 candidates read, and none of them
-- expands early voting or makes mail-in voting available without an excuse.
--
-- 🔑 THE RULE THIS ESTABLISHES: **never blank a row whose member has unreadable sessions.** Only
-- these four Maryland members currently qualify to be blanked at all — Ellis, Kagan, Rosapepe and
-- Benson, each with 0 unreadable sessions. Everyone else is owed a bill-crawl fallback first.
--
-- ── Also in this migration ───────────────────────────────────────────────────────────────────
-- · Jim Rosapepe / Voting Rights → BLANKED. 0 unreadable, 50 candidates read to the end. He has a
--   deep election-law record — public campaign financing, election observers, digital scanners,
--   the Universal Voter Registration Act — but nothing that expands early voting or makes mail
--   voting available without an excuse, which is what chair 2 says. ⚠ His Universal Voter
--   Registration Act is chair 1's language, not chair 2's; that is a re-seat to consider later, on
--   evidence, not a reason to keep an unevidenced chair 2 now.
-- · Ron Watson / Voting Rights chair 2 → RE-SOURCED to SB0991 (2025), "Election Law - Pretrial
--   Detainees - Absentee Ballots", which extends absentee voting to a class of voters who could
--   not otherwise use it. Watson has 3 unreadable sessions, but POSITIVE evidence is unaffected by
--   an unread session — only an absence claim is.
--
-- Rollback: data/stance-retirement/2026-08-12-md-chairs-1732-rollback.json
BEGIN;

CREATE TEMP TABLE fx_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',2),
       ('47823046-7dea-4a4f-a11b-0c5890539891','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',2);

DELETE FROM inform.politician_answers
WHERE politician_id='9c400214-f007-4a8d-92fe-5f5d23b3838e'
  AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';

UPDATE inform.politician_context
SET reasoning = 'Watson sponsored SB0991 (2025), "Election Law - Pretrial Detainees - Absentee Ballots".',
    sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0991?ys=2025RS',
                    'https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson01']::text[]
WHERE politician_id='9aef8bfb-8e0c-4f00-9898-c738abe4970c'
  AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';

DO $$
DECLARE restored int; blanked int; sourced int; ctx_after int; ans_after int; orphans int; snap record;
BEGIN
  SELECT count(*) INTO restored FROM inform.politician_answers
   WHERE topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid AND value=2
     AND politician_id IN ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca','47823046-7dea-4a4f-a11b-0c5890539891');
  IF restored <> 2 THEN RAISE EXCEPTION 'guard failed: % of 2 restored', restored; END IF;
  SELECT count(*) INTO blanked FROM inform.politician_answers
   WHERE politician_id='9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid
     AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid;
  IF blanked <> 0 THEN RAISE EXCEPTION 'guard failed: Rosapepe still answered'; END IF;
  SELECT count(*) INTO sourced FROM inform.politician_context
   WHERE politician_id='9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid
     AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
     AND reasoning LIKE '%SB0991%';
  IF sourced <> 1 THEN RAISE EXCEPTION 'guard failed: Watson not re-sourced'; END IF;
  SELECT * INTO snap FROM fx_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard failed: context moved'; END IF;
  IF ans_after <> snap.ans_before + 1 THEN RAISE EXCEPTION 'guard failed: answers moved % -> %, expected +1', snap.ans_before, ans_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                     WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard failed: % orphan answer(s)', orphans; END IF;
  RAISE NOTICE 'MD unreadable-session correction ok: 2 restored, 1 blanked, 1 re-sourced';
END $$;

COMMIT;
