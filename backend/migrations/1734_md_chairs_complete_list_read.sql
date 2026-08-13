-- 1734_md_chairs_complete_list_read.sql
-- MARYLAND: the 26 chair-discriminating rows, read to the END of every candidate list.
--
-- 🔑 THE STANDARD (CLAUDE.md): to sit in a chair you need evidence describing THAT chair. Direction
-- is not a chair, and a title that shares vocabulary with the chair text is not evidence at all.
--
-- 🔴🔴 WHAT MADE THIS POSSIBLE, AND WHY IT COULD NOT BE DONE BEFORE. Mig 1732 established the rule
-- that a row whose member has UNREADABLE SESSIONS may never be blanked, because mgaleg returns a
-- page with zero bills — not an error — for a session before a member switched chambers, and an
-- absence built on that is manufactured. `scripts/md-session-rosters.mjs` has since resolved every
-- one of those: 54 unreadable (member, session) pairs went to 0, the two survivors being proven
-- absences at year-granular tenure boundaries (Smith elected Nov 2014 and seated Jan 2015; Muse's
-- Senate service ended as the 2019 session convened). Alonzo Washington went from 230 to 1,606
-- bills visible; Sara Love from 186 to 955. **Only now is a Maryland blank a finding rather than a
-- gap.**
--
-- 🔴🔴 THE RANKER DID NOT DECIDE ANY OF THIS. `md-chair-candidates.mjs` flags candidates whose title
-- shares tokens with the seated chair; that flag is a reading queue, never a verdict. Its top-5 for
-- these rows was dominated by vocabulary collisions — "Commission on Kidney Disease – End-Stage
-- Renal Disease Quality INCENTIVE Program" scoring against *Economic Development Incentives*,
-- "SWAT Teams" against "crisis response TEAMS", "Mold Inspections – Standards" against
-- environmental *standards*, "Hometown Heroes" retirement income against *Criminal Justice*.
-- **Every row below was decided by reading its COMPLETE candidate list — 1,471 unique titles across
-- the 20 non-judicial rows — and every citation was decided by FETCHING the bill, never its title.**
-- Four of the eight below were found only in the complete list; the top-5 never showed them.
--
-- 🔑 IDENTITY. Candidates come from each member's own per-session mgaleg sponsored-legislation page,
-- under the SESSION-CORRECT slug, so nothing here rests on a surname match. Two of those slugs
-- contain a space (`washington a`, `kramer b`) and are cited URL-encoded.
--
-- ── 8 RE-SOURCED — the bill's SUBSTANCE describes the seated chair ────────────────────────────
--  · Charles / Voting Rights ch2 — HB0616 (2023) moves early voting's opening from the second
--    Thursday to the second SUNDAY: an expansion. ⚠ the title "Early Voting – Number of Days" is
--    directionless; only the synopsis says which way it moves. Mig 1731 blanked Muse on the same
--    ambiguity in SB0018 and said so.
--  · Smith / Redistricting ch2 — SB1023 (2017): 2 majority + 2 minority leader appointees plus an
--    independently chosen chair, and no officeholder may serve. That is chair 2's "equal
--    representation from both major parties", NOT chair 1's "no elected officials involved at any
--    level" — elected officials do the appointing. **Only the bill TEXT separates 1 from 2 here**,
--    so the PDF is cited alongside the page.
--  · Washington + Love / Public Safety ch3 — HB1210 (2019) Crisis Intervention Team Technical
--    Assistance Center. CIT is officer-based, which is why it picks ch3 ("adding crisis response
--    teams") over ch2 ("unarmed mental health co-responders").
--  · Kagan / Public Safety ch3 — SB0036 (2025), she LEADS, ENACTED Ch.14: the 9-1-1 Trust Fund may
--    now fund the 9-8-8 hotline and joint training. Keep the existing funding structure, add
--    mental-health crisis response — chair 3 exactly. **The only crisis instrument in all eight
--    Public Safety rows, 808 titles.**
--  · Love / Environment ch2 — HB0723 (2023), she LEADS, ENACTED Ch.541: forest mitigation banking
--    and afforestation/reforestation/preservation requirements, plus HB0120 (2019) raising
--    no-net-loss to mean 40% forest cover. Developer offset + protect existing canopy.
--  · Benson / Econ Dev ch3 — SB0064 (2024), she LEADS: a tax credit available ONLY to employers who
--    provide parental engagement leave, with SB1138 (2024, LEADS) requiring apprentices on public
--    works and repealing payment-in-lieu. The conditionality is what beats chairs 1, 2, 4 and 5.
--  · Washington / Criminal Justice ch2 — HB1287 (2017), he LEADS, ENACTED Ch.762, the Commission on
--    the School-to-Prison Pipeline and Restorative Practices. ⚠ the context is school discipline,
--    not adult sentencing; recorded because he also led HB1466 (2016) and HB1208 (2019) on
--    restorative practices, and "making things right" is chair 2's own idea.
--
-- ── 18 BLANKED — answer row deleted, context row kept ─────────────────────────────────────────
-- A blank spoke is the honest state when nothing describes the chair. Counts of candidates read are
-- recorded per row below and in the rollback JSON.
-- 🔴 COUNTER-EVIDENCE, not merely absence: **Arthur Ellis / Environment ch2** had a plausible
-- co-sponsored candidate (SB0203 (2019), no-net-loss at 40%), but his OWN LEAD bill SB0663 (2021)
-- EXEMPTS Charles County cemeteries from sediment control, stormwater management AND forest
-- conservation — the opposite of "require developers to fully offset any environmental impact".
-- Citing the flattering half would have seated him against his own record.
-- ⚠ Two rows fail the "must beat every rival" test rather than lacking evidence:
--   · Smith / Criminal Justice ch2 — his lead restorative bill SB0766 (2019) states discipline's
--     purpose is "rehabilitative, restorative, AND educational", so it cannot pick ch2 over ch1.
--   · Washington / Econ Dev ch3 — "targeted incentives for specific industries" is richly evidenced
--     (One Maryland credits, RISE zones, Aerospace Commission, all LEAD), but nothing evidences the
--     community-benefit/job-quality clause, leaving ch3 and ch4 tied.
-- 🔴 A SEPARATE DEFECT, NOT FIXED HERE: **`Bail and Pretrial Decisions` is judicial_role = 'judge'**
-- — its ladder is a judge's posture toward prosecutors ("judges shouldn't second-guess that
-- judgment"). Waldstreicher and Smith are STATE SENATORS. No legislative sponsorship can ever
-- evidence it, so blanking is right, but the real bug is that the topic was offered to a legislator
-- at all. Left for a topic-scope fix.
--
-- 🔑 NO CHAIR IS CHANGED. The 8 keep the chair they held; what changes is that it is now evidenced.
-- ⚠ Chair gate: none of the 8 sits at its ladder's anti pole, so sponsorship can evidence each.
--
-- Rollback: data/stance-retirement/2026-08-12-md-chairs-1734-rollback.json
BEGIN;

CREATE TEMP TABLE ce_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

CREATE TEMP TABLE ce_intent (pid uuid, tid uuid, reasoning text, sources text[]) ON COMMIT DROP;
INSERT INTO ce_intent (pid, tid, reasoning, sources) VALUES
-- Nick Charles / Voting Rights and Electoral Integrity (chair 2) — HB0616 2023RS
('cf190bac-9369-4175-bd4b-8ba776697d9c','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 'Charles sponsored HB0616 (2023), "Election Law - Early Voting - Number of Days", which moves the opening of early voting centers from the second Thursday to the second Sunday before an election — an expansion of the early voting period.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0616?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles01?ys=2023RS']::text[]),
-- William C. Smith, Jr. / State Redistricting and Gerrymandering (chair 2) — SB1023 2017RS
('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','48cc9585-ec22-4f53-8d42-6839828dd36f',
 'Smith sponsored SB1023 (2017), which creates a temporary redistricting commission of five members — two appointed by the Senate President and House Speaker and two by the minority leaders, with the fifth chosen by the other four — and bars anyone holding elective, appointive or party office from serving. That is a commission with equal representation from both major parties.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1023?ys=2017RS','https://mgaleg.maryland.gov/2017RS/bills/sb/sb1023f.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02']::text[]),
-- Alonzo T. Washington / Public Safety Approach (chair 3) — HB1210 2019RS
('8c8b0896-dfd0-4d3c-8492-e594d93b78ca','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 'Washington sponsored HB1210 (2019), "Public Safety - Crisis Intervention Team Technical Assistance Center", establishing a Crisis Intervention Team Technical Assistance Center in the Governor''s Office of Crime Control and Prevention to support crisis response for mental health calls.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1210?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington%20a?ys=2019RS']::text[]),
-- Sara Love / Public Safety Approach (chair 3) — HB1210 2019RS
('c5d2cd24-170a-4f87-8fde-84216fe62806','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 'Love sponsored HB1210 (2019), "Public Safety - Crisis Intervention Team Technical Assistance Center", establishing a Crisis Intervention Team Technical Assistance Center in the Governor''s Office of Crime Control and Prevention to support crisis response for mental health calls.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1210?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/love01?ys=2019RS']::text[]),
-- Cheryl C. Kagan / Public Safety Approach (chair 3) — SB0036 2025RS
('e35d5990-55c7-42e2-94bc-27cb1c49b5f1','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 'Kagan was lead sponsor of SB0036 (2025), enacted as Chapter 14, which authorises the 9-1-1 Trust Fund to pay for operating the 9-8-8 suicide prevention hotline, including software interfaces and joint training — adding mental-health crisis response within the existing public safety funding structure.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0036?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01']::text[]),
-- Sara Love / Environmental Protection vs. Development (chair 2) — HB0723 2023RS
('c5d2cd24-170a-4f87-8fde-84216fe62806','1935979c-b290-42e4-baa5-8cb0138b4ffa',
 'Love was lead sponsor of HB0723 (2023), enacted as Chapter 541, "Natural Resources - Forest Preservation and Retention", which alters how forest afforestation, reforestation and preservation requirements are calculated and tightens the definition of qualified conservation for forest mitigation banks. She also led HB0120 (2019), raising the no-net-loss-of-forest standard to mean 40% forest cover.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0723?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0120?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/love01?ys=2023RS']::text[]),
-- Joanne C. Benson / Economic Development Incentives (chair 3) — SB0064 2024RS
('4a7dc8a6-2138-4472-8197-8b878034f029','eb3d1247-0de1-4b7f-baec-7259861efd53',
 'Benson was lead sponsor of SB0064 (2024), a State income tax credit available only to employers who provide parental engagement leave, and of SB1138 (2024), which requires contractors on public works to employ a set percentage of apprentices and repeals the option to pay in lieu of doing so — incentives and contracts conditioned on job quality requirements.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0064?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1138?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson']::text[]),
-- Alonzo T. Washington / Criminal Justice Approach (chair 2) — HB1287 2017RS
('8c8b0896-dfd0-4d3c-8492-e594d93b78ca','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 'Washington was lead sponsor of HB1287 (2017), enacted as Chapter 762, establishing the Commission on the School-to-Prison Pipeline and Restorative Practices to examine best practices in restorative practices. He also led HB1466 (2016) and HB1208 (2019) on restorative practices.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1287?ys=2017RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington%20a?ys=2017RS']::text[]);

-- the answers the 8 already hold, so guard 4 can prove no chair moved
CREATE TEMP TABLE ce_chair_before ON COMMIT DROP AS
SELECT a.politician_id, a.topic_id, a.value
  FROM inform.politician_answers a JOIN ce_intent i ON i.pid=a.politician_id AND i.tid=a.topic_id;

UPDATE inform.politician_context c SET reasoning = i.reasoning, sources = i.sources
FROM ce_intent i WHERE c.politician_id = i.pid AND c.topic_id = i.tid;

-- The 18 blanks: delete the ANSWER, keep the CONTEXT — the corpus's established shape for an
-- unevidenced spoke.
CREATE TEMP TABLE ce_blank (pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO ce_blank VALUES
('4754dede-4a3b-4280-a8b1-7497530107f7','e9ebefcd-c496-45e8-b816-a79f8442ba85'), -- Arthur Ellis / Public Safety Approach (31 candidates read)
('47823046-7dea-4a4f-a11b-0c5890539891','e9ebefcd-c496-45e8-b816-a79f8442ba85'), -- C. Anthony Muse / Public Safety Approach (154 candidates read)
('da75c207-bb23-477e-b3c0-7c462394b570','e9ebefcd-c496-45e8-b816-a79f8442ba85'), -- Jeff Waldstreicher / Public Safety Approach (242 candidates read)
('9c400214-f007-4a8d-92fe-5f5d23b3838e','e9ebefcd-c496-45e8-b816-a79f8442ba85'), -- Jim Rosapepe / Public Safety Approach (113 candidates read)
('cf190bac-9369-4175-bd4b-8ba776697d9c','e9ebefcd-c496-45e8-b816-a79f8442ba85'), -- Nick Charles / Public Safety Approach (55 candidates read)
('9aef8bfb-8e0c-4f00-9898-c738abe4970c','e9ebefcd-c496-45e8-b816-a79f8442ba85'), -- Ron Watson / Public Safety Approach (64 candidates read)
('05c9b5b9-cb2b-4387-ab6b-350b69553fac','e9ebefcd-c496-45e8-b816-a79f8442ba85'), -- Shaneka Henson / Public Safety Approach (49 candidates read)
('8c8b0896-dfd0-4d3c-8492-e594d93b78ca','1935979c-b290-42e4-baa5-8cb0138b4ffa'), -- Alonzo T. Washington / Environmental Protection vs. Development (21 candidates read)
('4754dede-4a3b-4280-a8b1-7497530107f7','1935979c-b290-42e4-baa5-8cb0138b4ffa'), -- Arthur Ellis / Environmental Protection vs. Development (14 candidates read)
('7a2d1548-3268-4767-97a8-bb8b142d5a33','1935979c-b290-42e4-baa5-8cb0138b4ffa'), -- Benjamin F. Kramer / Environmental Protection vs. Development (25 candidates read)
('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1','1935979c-b290-42e4-baa5-8cb0138b4ffa'), -- Kevin M. Harris / Environmental Protection vs. Development (12 candidates read)
('8c8b0896-dfd0-4d3c-8492-e594d93b78ca','eb3d1247-0de1-4b7f-baec-7259861efd53'), -- Alonzo T. Washington / Economic Development Incentives (94 candidates read)
('47823046-7dea-4a4f-a11b-0c5890539891','eb3d1247-0de1-4b7f-baec-7259861efd53'), -- C. Anthony Muse / Economic Development Incentives (48 candidates read)
('05c9b5b9-cb2b-4387-ab6b-350b69553fac','eb3d1247-0de1-4b7f-baec-7259861efd53'), -- Shaneka Henson / Economic Development Incentives (24 candidates read)
('da75c207-bb23-477e-b3c0-7c462394b570','9db07b16-1076-4b7d-ad89-ebe7b51f4336'), -- Jeff Waldstreicher / Criminal Justice Approach (64 candidates read)
('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','9db07b16-1076-4b7d-ad89-ebe7b51f4336'), -- William C. Smith, Jr. / Criminal Justice Approach (106 candidates read)
('da75c207-bb23-477e-b3c0-7c462394b570','1fab5edf-6151-4da0-9704-a7f2113ba54c'), -- Jeff Waldstreicher / Bail and Pretrial Decisions (19 candidates read)
('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','1fab5edf-6151-4da0-9704-a7f2113ba54c'); -- William C. Smith, Jr. / Bail and Pretrial Decisions (28 candidates read)

DELETE FROM inform.politician_answers a USING ce_blank b
WHERE a.politician_id = b.pid AND a.topic_id = b.tid;

-- Guard 1: the 8 hold the intended text, name an instrument, and cite an mgaleg bill page — the
-- same test scripts/audit-chair-evidence.mjs --check applies.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM ce_intent i
  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid
  WHERE c.reasoning IS DISTINCT FROM i.reasoning
     OR c.sources IS DISTINCT FROM i.sources
     OR c.reasoning !~ '(\mSB\d|\mHB\d)'
     OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%mgaleg.maryland.gov/mgawebsite/Legislation/Details/%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % re-sourced row(s) wrong', bad; END IF;
END $$;

-- Guard 2: the 18 blanked spokes have NO answer and DO still have their context.
DO $$
DECLARE still_answered int; lost_context int;
BEGIN
  SELECT count(*) INTO still_answered FROM ce_blank b
  JOIN inform.politician_answers a ON a.politician_id=b.pid AND a.topic_id=b.tid;
  IF still_answered > 0 THEN RAISE EXCEPTION 'guard 2 failed: % spoke(s) still answered', still_answered; END IF;
  SELECT count(*) INTO lost_context FROM ce_blank b
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=b.pid AND c.topic_id=b.tid);
  IF lost_context > 0 THEN RAISE EXCEPTION 'guard 2 failed: % blanked row(s) lost their context', lost_context; END IF;
END $$;

-- Guard 3: exactly 18 answers removed, no context created or destroyed, no orphans.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM ce_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 3 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;
  IF ans_after <> snap.ans_before - 18 THEN RAISE EXCEPTION 'guard 3 failed: answers moved % -> %, expected -18', snap.ans_before, ans_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 3 failed: % orphan answer(s)', orphans; END IF;
END $$;

-- Guard 4: NO CHAIR MOVED. This migration re-sources; it does not re-seat. Each of the 8 must still
-- hold the exact value it held before, and must still be answered at all.
DO $$
DECLARE moved int; unanswered int;
BEGIN
  SELECT count(*) INTO moved FROM ce_chair_before b
  JOIN inform.politician_answers a ON a.politician_id=b.politician_id AND a.topic_id=b.topic_id
  WHERE a.value IS DISTINCT FROM b.value;
  IF moved > 0 THEN RAISE EXCEPTION 'guard 4 failed: % re-sourced chair(s) changed value', moved; END IF;
  SELECT count(*) INTO unanswered FROM ce_intent i
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                    WHERE a.politician_id=i.pid AND a.topic_id=i.tid);
  IF unanswered > 0 THEN RAISE EXCEPTION 'guard 4 failed: % re-sourced row(s) lost their answer', unanswered; END IF;
  RAISE NOTICE 'MD chairs: 8 re-sourced, 18 blanked, 0 chairs moved';
END $$;

COMMIT;
