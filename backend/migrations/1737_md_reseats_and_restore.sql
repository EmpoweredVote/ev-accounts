-- 1737_md_reseats_and_restore.sql
-- The four re-seat candidates flagged by mig 1736, resolved by reading the rest of each record.
-- Two are re-seats, one is a RESTORE of the chair that was right all along, and one is not seatable.
--
-- 🔴🔴 THE CORRECTION THAT MATTERS: **HESTER'S CHAIR 4 WAS RIGHT, AND MY OWN "RE-SEAT TO 3"
-- RECOMMENDATION WAS THE DEFECT THIS WORKSTREAM EXISTS TO REMOVE.** I concluded "not one of her
-- bills is a ban" — chair 3's "disclose risks and be held responsible" rather than chair 4's "ban
-- high-risk AI uses" — after reading SB0936, SB0978 and SB0827. The two bills I had NOT fetched are
-- exactly the bans:
--   · **SB0905 (2025, LEADS)** — "prohibiting a person from using certain artificial intelligence or
--     certain deepfake representations for certain purposes", with a civil action for victims.
--   · **SB0141 (2026, LEADS, ENACTED Ch.444)** — "prohibiting a person from knowingly or with
--     reckless disregard creating, using, or disseminating a deepfake to produce materially false
--     information."
-- An absence built on an unread part of the record is not a finding. It is the same error as mig
-- 1731's blanks, which mig 1732 had to undo. Chair 4 is restored, now evidenced on BOTH of its
-- clauses: safety testing (SB0936's impact assessments and developer/deployer duties for high-risk
-- systems) and banning high-risk uses (SB0905, SB0141).
--
-- ── 1 RESTORED ───────────────────────────────────────────────────────────────────────────────
--  · Katie Fry Hester / Artificial Intelligence Oversight — back to chair 4, the value mig 1736
--    deleted. ⚠ AI Oversight is a REVERSED ladder (chair 1 = "allow AI companies to develop freely",
--    chair 5 = "ban AI systems that could cause serious harm"), so chair 4 is its ACTION side and
--    sponsorship may evidence it. See [[ladder_orientation]].
--
-- ── 2 RE-SEATED (chair CHANGED — this is the one migration in the series that moves a chair) ──
--  · Cheryl C. Kagan / Campaign Finance Reform **2 → 3**. Chair 2 is "strictly limit corporate
--    donations and dark money groups"; nothing in her record does that. What she LEADS is
--    disclosure: **SB0633 (2025, ENACTED Ch.313)** requires political organizations to carry
--    disclaimers and disclosures on solicitations, with investigation and a civil penalty, and
--    SB0458 (2024) adds disclosures plus a bar on paying entities the organization's own principals
--    control. ⚠ Checked against her prohibitions before moving her: SB0374 (2021) bans fundraising
--    during a special session — a TIMING restriction on legislators, not a limit on corporate or
--    dark money — and SB0950 is administrative. Chair 3 beats chair 2 on her own instruments.
--  · Benjamin F. Kramer / Medicare / Medicaid **2 → 3**. Chair 2 requires "lower Medicare age to 55
--    AND expand Medicaid significantly"; the Medicare half is absent from his record entirely and
--    the Medicaid half is targeted, not significant. What he LEADS is chair 3's "improve current
--    programs while controlling costs": **SB0600 (2024, ENACTED Ch.903)** studies adding dentures to
--    the Maryland Healthy Smiles Dental Program AND setting adequate provider reimbursement rates,
--    and SB1057 (2024) adjusts the financial eligibility criteria of the existing home- and
--    community-based services waiver. Both improve an existing programme rather than expand
--    entitlement.
--
-- ── 1 NOT SEATABLE — mig 1736's blank STANDS ─────────────────────────────────────────────────
--  · Sara Love / State Redistricting and Gerrymandering. I flagged this "ch2 → ch3/4", which is an
--    unresolved call, not a decision. Reading the bills settles it the other way: **the ladder asks
--    WHO draws the maps, and every one of her bills is about WHAT RULES apply.** HB0463 (2019) and
--    HB1431 (2020) propose constitutional standards for districts plus an open hearing process, and
--    leave the General Assembly drawing them. No commission (ch1/ch2), no bipartisan committee with
--    supermajority (ch3), no court-oversight mechanism (ch4). Nothing describes any chair, so the
--    honest state is the blank spoke it already has.
--
-- 🔑 Every citation was verified by FETCHING the bill. Rollback:
-- data/stance-retirement/2026-08-12-md-reseats-1737-rollback.json
BEGIN;

CREATE TEMP TABLE rs_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

CREATE TEMP TABLE rs_intent (pid uuid, tid uuid, chair numeric, reasoning text, sources text[]) ON COMMIT DROP;
INSERT INTO rs_intent (pid, tid, chair, reasoning, sources) VALUES
-- Katie Fry Hester / Artificial Intelligence Oversight — RESTORE chair 4
('6da20195-1b0c-43f2-b1b3-7a3954326fe6','666bf03d-81fc-4138-ab15-69ae734c9023', 4,
 'Hester was lead sponsor of SB0936 (2025), requiring developers and deployers of high-risk artificial intelligence systems to use reasonable care against algorithmic discrimination and to carry out impact assessments and disclosures, and of two prohibitions on high-risk uses: SB0905 (2025), barring the use of artificial intelligence or deepfake representations to cause harm, and SB0141 (2026), enacted as Chapter 444, barring the creation or dissemination of a deepfake to produce materially false information in an election.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0936?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0905?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0141?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hester01']::text[]),
-- Cheryl C. Kagan / Campaign Finance Reform — RE-SEAT 2 -> 3
('e35d5990-55c7-42e2-94bc-27cb1c49b5f1','92730f69-ae57-401c-8ad1-2d07834a895d', 3,
 'Kagan was lead sponsor of SB0633 (2025), enacted as Chapter 313, requiring political organizations to include disclaimers and disclosures on solicitations and authorizing the State Board to bar further solicitations or impose a civil penalty, and of SB0458 (2024), requiring disclosures by political organizations and prohibiting them from paying entities owned or controlled by certain individuals.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0633?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0458?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01']::text[]),
-- Benjamin F. Kramer / Medicare / Medicaid — RE-SEAT 2 -> 3
('7a2d1548-3268-4767-97a8-bb8b142d5a33','cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 3,
 'Kramer was lead sponsor of SB0600 (2024), enacted as Chapter 903, requiring the Maryland Department of Health to study including removable dentures in the Maryland Healthy Smiles Dental Program and setting adequate per-patient reimbursement rates for providers, and of SB1057 (2024), altering the financial eligibility criteria of the existing home- and community-based services waiver.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0600?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1057?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02']::text[]);

-- these three currently have NO answer (mig 1736 deleted it), so this is an INSERT
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pid, tid, chair FROM rs_intent;

UPDATE inform.politician_context c SET reasoning = i.reasoning, sources = i.sources
FROM rs_intent i WHERE c.politician_id = i.pid AND c.topic_id = i.tid;

-- Guard 1: all three are answered at the intended chair.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM rs_intent i
  LEFT JOIN inform.politician_answers a ON a.politician_id=i.pid AND a.topic_id=i.tid
  WHERE a.value IS DISTINCT FROM i.chair;
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) not seated at the intended chair', bad; END IF;
END $$;

-- Guard 2: reasoning holds the intended text, names an instrument, cites an mgaleg bill page — the
-- same test scripts/audit-chair-evidence.mjs --check applies.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM rs_intent i
  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid
  WHERE c.reasoning IS DISTINCT FROM i.reasoning
     OR c.sources IS DISTINCT FROM i.sources
     OR c.reasoning !~ '(\mSB\d|\mHB\d)'
     OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%mgaleg.maryland.gov/mgawebsite/Legislation/Details/%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard 2 failed: % re-sourced row(s) wrong', bad; END IF;
END $$;

-- Guard 3: exactly 3 answers added, context untouched, no orphans.
DO $$
DECLARE ans_after int; ctx_after int; orphans int; s record;
BEGIN
  SELECT * INTO s FROM rs_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 3 THEN
    RAISE EXCEPTION 'guard 3 failed: answers % -> %, expected +3', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before THEN
    RAISE EXCEPTION 'guard 3 failed: context moved % -> %', s.ctx_before, ctx_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 3 failed: % orphan answer(s)', orphans; END IF;
END $$;

-- Guard 4: Sara Love / Redistricting is STILL BLANK. Her bills describe no chair on this ladder, and
-- a migration that quietly restored her would be the guess this pass refuses to make.
DO $$
DECLARE love_seated int;
BEGIN
  SELECT count(*) INTO love_seated FROM inform.politician_answers
   WHERE politician_id='c5d2cd24-170a-4f87-8fde-84216fe62806'
     AND topic_id='48cc9585-ec22-4f53-8d42-6839828dd36f';
  IF love_seated > 0 THEN RAISE EXCEPTION 'guard 4 failed: Love/Redistricting was re-seated'; END IF;
  RAISE NOTICE 'MD re-seats: 1 restored (Hester ch4), 2 re-seated to ch3, 1 left blank';
END $$;

COMMIT;
