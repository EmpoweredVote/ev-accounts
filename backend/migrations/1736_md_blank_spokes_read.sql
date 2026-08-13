-- 1736_md_blank_spokes_read.sql
-- The rows the RANKER found nothing in, read to the end of every candidate list anyway.
--
-- 🔴🔴 WHY THIS PASS EXISTS AT ALL. `md-chair-candidates.mjs` put these rows in a "no
-- chair-discriminating candidate" bucket. **That bucket is not a blank list, and mig 1731 proved it**
-- — reading Cheryl Kagan's full 171 candidates there turned up prepaid-postage and drop-box bills
-- the shortlist never showed. So all ~2,765 candidates behind these rows were read. The measured
-- yield is low but not zero: **3 of 42**.
--
-- ⚠ THREE OF THE 45 WERE NEVER OWED. Rosapepe/Voting was blanked by 1731, Smith/Prosecution by 1735,
-- and **Watson/Voting had already been re-sourced by 1732**. Testing "does the row still have an
-- answer" is NOT testing "is the row owed" — the test is whether its REASONING names an instrument.
--
-- ── 3 RE-SOURCED ─────────────────────────────────────────────────────────────────────────────
--  · Harris / Voting Rights ch2 — HB0253 (2025), he LEADS: boards must send an absentee ballot
--    automatically to every voter in pretrial detention, with no application. 🔑 Mig 1732 seated Ron
--    Watson on this same chair for the Senate crossfile SB0991, so accepting this is consistency,
--    not a new standard. ⚠ 2025 has exactly ONE Harris in the House, so "Delegate Harris" is not a
--    surname guess.
--  · Smith / Econ Dev ch3 — SB0807 (2017), he LEADS, ENACTED Ch.180: a veteran-wage credit that
--    **prohibits claiming it for a veteran hired to replace a laid-off or striking employee**. That
--    anti-displacement clause is a job-quality requirement attached to a targeted incentive — the
--    same shape as Benson's SB0064 in mig 1734. With HB1047 (2015, LEADS).
--  · Kramer / Econ Dev ch3 — HB0473 (2015), he LEADS, ENACTED Ch.423: credit for wages and for child
--    care or transport tied to employees with disabilities. ⚠ 2015 has exactly ONE Kramer.
--
-- ── 38 BLANKED (answer deleted, context kept) ────────────────────────────────────────────────
-- 🔴🔴 **ALL 13 TAXATION ROWS FAIL FOR ONE STRUCTURAL REASON, WHICH CLAUDE.md STATES VERBATIM.**
-- Every one sits at chair 2 — "MODERATELY raise taxes on wealthy people and large companies to fund
-- EXISTING services" — and its only difference from chair 1 is MAGNITUDE. Alonzo Washington LEADS
-- the **Digital Advertising Gross Revenues tax (HB0695, 2020)**, a genuine tax on large companies;
-- Kagan co-sponsored carried-interest and the Corporate Tax Fairness Act. Every one of them proves
-- DIRECTION and not one can prove "moderately". CLAUDE.md: "A bill citation proves direction. It
-- does not automatically prove magnitude." **Do not re-litigate these row by row.**
-- Other groups and why they fail: Econ Dev 7 (targeted-industry incentives with no job-quality or
-- community-benefit clause — the same test Washington failed in 1734); Immigration 5 (the ladder is
-- about public-service access, but the MD record is enforcement cooperation — sanctuary, detention,
-- sensitive locations — which the ladder never mentions); Transgender Athletes 3 (never legislated
-- in this corpus); AI Oversight 2; Campaign Finance 2; Voting Rights 2; and one each for
-- Medicare/Medicaid, Ukraine, Redistricting, Environment.
--
-- ⚠ RE-SEAT CANDIDATES, blanked here rather than re-seated silently. Each row's own record points at
-- a DIFFERENT chair, and moving a chair is a decision, not a re-sourcing (see mig 1734's guard 4):
--   · **Hester / AI ch4 → ch3.** She LEADS SB0936 (high-risk AI duties), SB0978 (synthetic-media
--     disclosure) and SB0827 (chatbot product liability) — and **not one of them is a ban**. That is
--     chair 3's "disclose risks and be held responsible", not chair 4's "ban high-risk AI uses".
--   · Kramer / Medicare-Medicaid ch2 → ch3 · Kagan / Campaign Finance ch2 → ch3
--   · Love / Redistricting ch2 → ch3/4 (HB1431 Fair Maps sets district STANDARDS and leaves the
--     General Assembly in charge; it creates no commission).
--
-- ── 1 HELD — deliberately NOT blanked ────────────────────────────────────────────────────────
-- **Jeff Waldstreicher / Same-Sex Marriage (chair 1.0)**: Maryland settled this with the 2012 Civil Marriage
-- Protection Act, which is OUTSIDE the 2013+ corpus. A miss here is a corpus-period artefact, never
-- an absence, so blanking it would manufacture exactly the defect this workstream removes. It is
-- owed the 2012 roll call instead. Guard 5 proves it survived.
--
-- 🔑 NO CHAIR IS CHANGED. Rollback: data/stance-retirement/2026-08-12-md-chairs-1736-rollback.json
BEGIN;

CREATE TEMP TABLE bs_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

CREATE TEMP TABLE bs_intent (pid uuid, tid uuid, reasoning text, sources text[]) ON COMMIT DROP;
INSERT INTO bs_intent (pid, tid, reasoning, sources) VALUES
-- Benjamin F. Kramer / Economic Development Incentives (chair 3.0) — HB0473 2015RS
('7a2d1548-3268-4767-97a8-bb8b142d5a33','eb3d1247-0de1-4b7f-baec-7259861efd53',
 'Kramer was lead sponsor of HB0473 (2015), enacted as Chapter 423, altering the credit against State taxes for wages and for child care or transportation expenses tied to qualified employees with disabilities.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0473?ys=2015RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer%20b?ys=2015RS']::text[]),
-- Kevin M. Harris / Voting Rights and Electoral Integrity (chair 2.0) — HB0253 2025RS
('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 'Harris was lead sponsor of HB0253 (2025), requiring the boards of elections to send an absentee ballot automatically to every registered voter in pretrial detention, without the voter having to submit an application. Mig 1732 seated Ron Watson on this same chair for its Senate crossfile, SB0991.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0253?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris02?ys=2025RS']::text[]),
-- William C. Smith, Jr. / Economic Development Incentives (chair 3.0) — SB0807 2017RS
('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','eb3d1247-0de1-4b7f-baec-7259861efd53',
 'Smith was lead sponsor of SB0807 (2017), enacted as Chapter 180, allowing small businesses a credit for wages paid to qualified veteran employees while PROHIBITING the credit where the veteran was hired to replace a laid-off or striking employee, and capping the certificates issued. He also led HB1047 (2015), extending the enterprise-zone hiring credit to ex-felons within the definition of economically disadvantaged individual.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0807?ys=2017RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1047?ys=2015RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith01?ys=2015RS']::text[]);

CREATE TEMP TABLE bs_chair_before ON COMMIT DROP AS
SELECT a.politician_id, a.topic_id, a.value
  FROM inform.politician_answers a JOIN bs_intent i ON i.pid=a.politician_id AND i.tid=a.topic_id;

UPDATE inform.politician_context c SET reasoning = i.reasoning, sources = i.sources
FROM bs_intent i WHERE c.politician_id = i.pid AND c.topic_id = i.tid;

CREATE TEMP TABLE bs_blank (pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO bs_blank VALUES
('8c8b0896-dfd0-4d3c-8492-e594d93b78ca','f7e5678d-dadd-4556-a2fc-446e24642ceb'), -- Alonzo T. Washington / Taxation and Public Spending (183 read; MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately")
('4754dede-4a3b-4280-a8b1-7497530107f7','eb3d1247-0de1-4b7f-baec-7259861efd53'), -- Arthur Ellis / Economic Development Incentives (42 read; targeted-industry incentives without the job-quality/CBA clause)
('4754dede-4a3b-4280-a8b1-7497530107f7','f7e5678d-dadd-4556-a2fc-446e24642ceb'), -- Arthur Ellis / Taxation and Public Spending (39 read; MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately")
('7a2d1548-3268-4767-97a8-bb8b142d5a33','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'), -- Benjamin F. Kramer / Medicare / Medicaid (36 read; long-term-care and nursing-home quality, not Medicaid expansion)
('7a2d1548-3268-4767-97a8-bb8b142d5a33','f7e5678d-dadd-4556-a2fc-446e24642ceb'), -- Benjamin F. Kramer / Taxation and Public Spending (81 read; MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately")
('47823046-7dea-4a4f-a11b-0c5890539891','f7e5678d-dadd-4556-a2fc-446e24642ceb'), -- C. Anthony Muse / Taxation and Public Spending (76 read; MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately")
('e35d5990-55c7-42e2-94bc-27cb1c49b5f1','92730f69-ae57-401c-8ad1-2d07834a895d'), -- Cheryl C. Kagan / Campaign Finance Reform (24 read; disclosure/anti-fraud, not limits on corporate or dark money)
('e35d5990-55c7-42e2-94bc-27cb1c49b5f1','eb3d1247-0de1-4b7f-baec-7259861efd53'), -- Cheryl C. Kagan / Economic Development Incentives (39 read; targeted-industry incentives without the job-quality/CBA clause)
('e35d5990-55c7-42e2-94bc-27cb1c49b5f1','4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Cheryl C. Kagan / Immigration and Treatment of Immigrants (9 read; ladder is public-service access; the record is enforcement cooperation)
('e35d5990-55c7-42e2-94bc-27cb1c49b5f1','f7e5678d-dadd-4556-a2fc-446e24642ceb'), -- Cheryl C. Kagan / Taxation and Public Spending (74 read; MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately")
('da75c207-bb23-477e-b3c0-7c462394b570','4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Jeff Waldstreicher / Immigration and Treatment of Immigrants (10 read; ladder is public-service access; the record is enforcement cooperation)
('da75c207-bb23-477e-b3c0-7c462394b570','f7e5678d-dadd-4556-a2fc-446e24642ceb'), -- Jeff Waldstreicher / Taxation and Public Spending (92 read; MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately")
('da75c207-bb23-477e-b3c0-7c462394b570','d1618b9c-0b9e-45af-b986-bb33d270b8e4'), -- Jeff Waldstreicher / Transgender Athletes (4 read; never legislated in the MD corpus)
('da75c207-bb23-477e-b3c0-7c462394b570','92730f69-ae57-401c-8ad1-2d07834a895d'), -- Jeff Waldstreicher / Campaign Finance Reform (13 read; disclosure/anti-fraud, not limits on corporate or dark money)
('da75c207-bb23-477e-b3c0-7c462394b570','eb3d1247-0de1-4b7f-baec-7259861efd53'), -- Jeff Waldstreicher / Economic Development Incentives (49 read; targeted-industry incentives without the job-quality/CBA clause)
('9c400214-f007-4a8d-92fe-5f5d23b3838e','24e9212c-b011-422a-865c-093e35050901'), -- Jim Rosapepe / Ukraine - Russia Conflict (3 read; a federal question a state record cannot reach)
('9c400214-f007-4a8d-92fe-5f5d23b3838e','f7e5678d-dadd-4556-a2fc-446e24642ceb'), -- Jim Rosapepe / Taxation and Public Spending (194 read; MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately")
('4a7dc8a6-2138-4472-8197-8b878034f029','f7e5678d-dadd-4556-a2fc-446e24642ceb'), -- Joanne C. Benson / Taxation and Public Spending (150 read; MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately")
('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1','eb3d1247-0de1-4b7f-baec-7259861efd53'), -- Kevin M. Harris / Economic Development Incentives (21 read; targeted-industry incentives without the job-quality/CBA clause)
('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1','4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Kevin M. Harris / Immigration and Treatment of Immigrants (3 read; ladder is public-service access; the record is enforcement cooperation)
('cf190bac-9369-4175-bd4b-8ba776697d9c','eb3d1247-0de1-4b7f-baec-7259861efd53'), -- Nick Charles / Economic Development Incentives (34 read; targeted-industry incentives without the job-quality/CBA clause)
('cf190bac-9369-4175-bd4b-8ba776697d9c','f7e5678d-dadd-4556-a2fc-446e24642ceb'), -- Nick Charles / Taxation and Public Spending (40 read; MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately")
('9aef8bfb-8e0c-4f00-9898-c738abe4970c','eb3d1247-0de1-4b7f-baec-7259861efd53'), -- Ron Watson / Economic Development Incentives (14 read; targeted-industry incentives without the job-quality/CBA clause)
('9aef8bfb-8e0c-4f00-9898-c738abe4970c','f7e5678d-dadd-4556-a2fc-446e24642ceb'), -- Ron Watson / Taxation and Public Spending (26 read; MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately")
('c5d2cd24-170a-4f87-8fde-84216fe62806','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), -- Sara Love / Voting Rights and Electoral Integrity (23 read; no early-voting or no-excuse-mail instrument)
('c5d2cd24-170a-4f87-8fde-84216fe62806','eb3d1247-0de1-4b7f-baec-7259861efd53'), -- Sara Love / Economic Development Incentives (12 read; targeted-industry incentives without the job-quality/CBA clause)
('c5d2cd24-170a-4f87-8fde-84216fe62806','4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- Sara Love / Immigration and Treatment of Immigrants (10 read; ladder is public-service access; the record is enforcement cooperation)
('c5d2cd24-170a-4f87-8fde-84216fe62806','48cc9585-ec22-4f53-8d42-6839828dd36f'), -- Sara Love / State Redistricting and Gerrymandering (3 read; district STANDARDS, not an independent commission)
('c5d2cd24-170a-4f87-8fde-84216fe62806','f7e5678d-dadd-4556-a2fc-446e24642ceb'), -- Sara Love / Taxation and Public Spending (28 read; MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately")
('c5d2cd24-170a-4f87-8fde-84216fe62806','d1618b9c-0b9e-45af-b986-bb33d270b8e4'), -- Sara Love / Transgender Athletes (10 read; never legislated in the MD corpus)
('05c9b5b9-cb2b-4387-ab6b-350b69553fac','1935979c-b290-42e4-baa5-8cb0138b4ffa'), -- Shaneka Henson / Environmental Protection vs. Development (15 read; no tree-canopy or developer-offset instrument)
('05c9b5b9-cb2b-4387-ab6b-350b69553fac','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), -- Shaneka Henson / Voting Rights and Electoral Integrity (13 read; no early-voting or no-excuse-mail instrument)
('05c9b5b9-cb2b-4387-ab6b-350b69553fac','f7e5678d-dadd-4556-a2fc-446e24642ceb'), -- Shaneka Henson / Taxation and Public Spending (46 read; MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately")
('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','4e2c69ce-591e-4197-9cd5-7aceff79d390'), -- William C. Smith, Jr. / Immigration and Treatment of Immigrants (17 read; ladder is public-service access; the record is enforcement cooperation)
('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','f7e5678d-dadd-4556-a2fc-446e24642ceb'), -- William C. Smith, Jr. / Taxation and Public Spending (119 read; MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately")
('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','d1618b9c-0b9e-45af-b986-bb33d270b8e4'), -- William C. Smith, Jr. / Transgender Athletes (5 read; never legislated in the MD corpus)
('6da20195-1b0c-43f2-b1b3-7a3954326fe6','666bf03d-81fc-4138-ab15-69ae734c9023'), -- Katie Fry Hester / Artificial Intelligence Oversight (22 read; record shows disclosure and liability, no bans)
('d423151e-8477-470d-8f73-ba7d2092f714','666bf03d-81fc-4138-ab15-69ae734c9023'); -- Brian J. Feldman / Artificial Intelligence Oversight (9 read; record shows disclosure and liability, no bans)

DELETE FROM inform.politician_answers a USING bs_blank b
WHERE a.politician_id = b.pid AND a.topic_id = b.tid;

-- Guard 1: the 3 hold the intended text, name an instrument, cite an mgaleg bill page.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM bs_intent i
  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid
  WHERE c.reasoning IS DISTINCT FROM i.reasoning
     OR c.sources IS DISTINCT FROM i.sources
     OR c.reasoning !~ '(\mSB\d|\mHB\d)'
     OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%mgaleg.maryland.gov/mgawebsite/Legislation/Details/%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % re-sourced row(s) wrong', bad; END IF;
END $$;

-- Guard 2: the 38 have NO answer and DO still have context.
DO $$
DECLARE still_answered int; lost_context int;
BEGIN
  SELECT count(*) INTO still_answered FROM bs_blank b
  JOIN inform.politician_answers a ON a.politician_id=b.pid AND a.topic_id=b.tid;
  IF still_answered > 0 THEN RAISE EXCEPTION 'guard 2 failed: % spoke(s) still answered', still_answered; END IF;
  SELECT count(*) INTO lost_context FROM bs_blank b
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=b.pid AND c.topic_id=b.tid);
  IF lost_context > 0 THEN RAISE EXCEPTION 'guard 2 failed: % blanked row(s) lost context', lost_context; END IF;
END $$;

-- Guard 3: exactly 38 answers removed, context untouched, no orphans.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; s record;
BEGIN
  SELECT * INTO s FROM bs_snap;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  IF ctx_after <> s.ctx_before THEN RAISE EXCEPTION 'guard 3 failed: context moved % -> %', s.ctx_before, ctx_after; END IF;
  IF ans_after <> s.ans_before - 38 THEN RAISE EXCEPTION 'guard 3 failed: answers % -> %, expected -38', s.ans_before, ans_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 3 failed: % orphan answer(s)', orphans; END IF;
END $$;

-- Guard 4: NO CHAIR MOVED, and the 3 kept their answers.
DO $$
DECLARE moved int; unanswered int;
BEGIN
  SELECT count(*) INTO moved FROM bs_chair_before b
  JOIN inform.politician_answers a ON a.politician_id=b.politician_id AND a.topic_id=b.topic_id
  WHERE a.value IS DISTINCT FROM b.value;
  IF moved > 0 THEN RAISE EXCEPTION 'guard 4 failed: % chair(s) changed value', moved; END IF;
  SELECT count(*) INTO unanswered FROM bs_intent i
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                    WHERE a.politician_id=i.pid AND a.topic_id=i.tid);
  IF unanswered > 0 THEN RAISE EXCEPTION 'guard 4 failed: % re-sourced row(s) lost their answer', unanswered; END IF;
END $$;

-- Guard 5: THE HELD ROW SURVIVED. Its evidence is outside the corpus period, so blanking it would be
-- the manufactured-absence defect, not a finding.
DO $$
DECLARE held_gone int;
BEGIN
  SELECT count(*) INTO held_gone FROM (VALUES ('da75c207-bb23-477e-b3c0-7c462394b570'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid)) v(pid,tid)
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                    WHERE a.politician_id=v.pid AND a.topic_id=v.tid);
  IF held_gone > 0 THEN RAISE EXCEPTION 'guard 5 failed: the HELD row was blanked'; END IF;
  RAISE NOTICE 'MD blank spokes: 3 re-sourced, 38 blanked, 1 held, 0 chairs moved';
END $$;

COMMIT;
