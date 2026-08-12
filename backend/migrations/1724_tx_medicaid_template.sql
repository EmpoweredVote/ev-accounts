-- 1724_tx_medicaid_template.sql
-- THE TEXAS SLICE of the "backed Medicaid expansion" template.
--
-- 🔴 TEXAS NEVER EXPANDED MEDICAID, so the sentence cannot mean a vote for an enacted expansion.
-- It CAN mean authorship of an expansion BILL, and those exist and are unmistakable. 20 of these
-- 24 rows are exactly that — the member authored or co-authored a real expansion bill, so the
-- claim was TRUE and merely unevidenced. The rest cite the member's strongest coverage bill.
--
-- 🔑 SCOPE: Texas rows at chair 1-2 on a health topic. Of the 55 Texas rows carrying the phrase,
-- 20 sit at chair 4-5 and NINE OF THOSE SAY THE MEMBER OPPOSED EXPANSION — correct, aligned with
-- an anti-pole chair, not a defect. The phrase is not the defect; PRO wording with no evidence is.
--
-- 🔴🔴 AN IDENTITY TRAP THAT NEARLY SHIPPED: Cassandra Garcia Hernandez's row CITES member code
-- A3155, which is ANA Hernandez — a different member. Sourcing from the stored code would have
-- described another woman's record as hers. Identity is the TLO roster matched on the FULL name
-- (A4495 = "Garcia Hernandez, Cassandra"), and the report header is checked against surname AND
-- first name — a surname-only check passed "Rep. Ana Hernandez" happily. The wrong-person link is
-- removed from her sources here.
--
-- 🔑 CHAIRS ARE NOT TOUCHED. Citations quote the bill's official caption rather than paraphrasing.
--
-- Left owed:
--   · Ana-Maria Ramos / Healthcare Access: not found in H roster
--
-- Rollback: data/stance-retirement/2026-08-12-tx-medicaid-1724-rollback.json
BEGIN;

CREATE TEMP TABLE tx_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT coalesce(sum(value), 0) FROM inform.politician_answers) AS chair_sum_before;

CREATE TEMP TABLE tx_intent (pid uuid, tid uuid, reasoning text, sources text[]) ON COMMIT DROP;
INSERT INTO tx_intent (pid, tid, reasoning, sources) VALUES
-- Ann Johnson / Healthcare Access (chair 2.0) — author on 89R HB475
('136fc01b-f061-4e30-9aa7-d5735e0a4659', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Johnson authored HB 475 in the 89(R) session, "Relating to Medicaid coverage and reimbursement for multisystemic therapy services."', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB475','https://en.wikipedia.org/wiki/Ann_Johnson_(politician)']::text[]),
-- Borris Miles / Healthcare Access (chair 2.0) — author on 89R SB255
('67a35228-1353-4044-90b2-cd8fcf48de7b', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Miles authored SB 255 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB255','https://senate.texas.gov/member.php?d=13']::text[]),
-- Carol Alvarado / Medicare / Medicaid (chair 2.0) — author on 89R SB255
('6ed2b57e-4930-4099-8567-d5a6bf7b999f', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'Alvarado authored SB 255 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB255','https://senate.texas.gov/member.php?d=6']::text[]),
-- Cassandra Garcia Hernandez / Healthcare Access (chair 2.0) — author on 89R HB2119
('dd4cb2d3-41c7-498d-8a0c-94f988deb0eb', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Hernandez authored HB 2119 in the 89(R) session, "Relating to preauthorization of certain benefits by certain health benefit plan issuers."', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB2119','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB5','https://en.wikipedia.org/wiki/Cassandra_Garcia_Hernandez']::text[]),
-- César Blanco / Medicare / Medicaid (chair 2.0) — author on 89R SB255
('32608fd7-5038-4474-bfa9-7392b5e0eb80', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'Blanco authored SB 255 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB255','https://senate.texas.gov/member.php?d=29']::text[]),
-- César Blanco / Healthcare Access (chair 2.0) — author on 89R SB255
('32608fd7-5038-4474-bfa9-7392b5e0eb80', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Blanco authored SB 255 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB255','https://senate.texas.gov/member.php?d=29']::text[]),
-- Claudia Ordaz / Medicare / Medicaid (chair 2.0) — coauthor on 87R HB389
('d45bbf56-7e43-4932-b536-fd73173eb295', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'Ordaz co-authored HB 389 in the 87(R) session, "Relating to the expansion of eligibility for Medicaid to certain persons under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=87R&Bill=HB389','https://en.wikipedia.org/wiki/Claudia_Ordaz']::text[]),
-- Claudia Ordaz / Healthcare Access (chair 2.0) — coauthor on 87R HB389
('d45bbf56-7e43-4932-b536-fd73173eb295', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Ordaz co-authored HB 389 in the 87(R) session, "Relating to the expansion of eligibility for Medicaid to certain persons under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=87R&Bill=HB389','https://en.wikipedia.org/wiki/Claudia_Ordaz']::text[]),
-- John Bucy III / Healthcare Access (chair 2.0) — author on 89R HB197
('2be64a58-ae2c-4eee-b80d-6e673ef774bd', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Bucy authored HB 197 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB197','https://en.wikipedia.org/wiki/John_Bucy_III']::text[]),
-- José Menéndez / Medicare / Medicaid (chair 2.0) — author on 89R SB255
('ada67d5b-b7d5-4ab9-a751-59355715c3e1', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'Menéndez authored SB 255 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB255','https://senate.texas.gov/member.php?d=26']::text[]),
-- Judith Zaffirini / Healthcare Access (chair 2.0) — author on 89R SB45
('1d0b1e50-5bd7-46f6-b9a9-6ca7cdfcebe6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Zaffirini authored SB 45 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB45','https://www.senate.texas.gov/member.php?d=21','https://en.wikipedia.org/wiki/Judith_Zaffirini']::text[]),
-- Judith Zaffirini / Medicare / Medicaid (chair 2.0) — author on 89R SB45
('1d0b1e50-5bd7-46f6-b9a9-6ca7cdfcebe6', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'Zaffirini authored SB 45 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB45','https://www.senate.texas.gov/member.php?d=21']::text[]),
-- Mary Ann Perez / Healthcare Access (chair 2.0) — author on 88R HB4713
('50d759c2-05cc-4769-a1d9-69b282745d0d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Perez authored HB 4713 in the 88(R) session, "Relating to group health benefit plan coverage for early treatment of first episode psychosis."', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB4713','https://en.wikipedia.org/wiki/Mary_Ann_Perez','http://house.texas.gov/members/member-page?district=144']::text[]),
-- Mary Gonzalez / Healthcare Access (chair 2.0) — author on 89R HB2938
('619ad301-d993-40b3-94fe-0eb956932dae', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Gonzalez authored HB 2938 in the 89(R) session, "Relating to attendant care services under Medicaid and other programs administered by the Health and Human Services Commission, including establishing a minimum base wage for certain personal attendants providing those services and allowing family members to provide those services."', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB2938','https://en.wikipedia.org/wiki/Mary_Gonzalez','http://house.texas.gov/members/member-page?district=75']::text[]),
-- Nathan Johnson / Medicare / Medicaid (chair 2.0) — author on 89R SB637
('7d100649-77bc-4dd1-8845-d379ca466fa2', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'Johnson authored SB 637 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB637','https://senate.texas.gov/member.php?d=16','https://en.wikipedia.org/wiki/Nathan_Johnson_(Texas_politician)']::text[]),
-- Nathan Johnson / Healthcare Access (chair 2.0) — author on 89R SB637
('7d100649-77bc-4dd1-8845-d379ca466fa2', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Johnson authored SB 637 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB637','https://en.wikipedia.org/wiki/Nathan_Johnson_(Texas_politician)','https://senate.texas.gov/member.php?d=16']::text[]),
-- Roland Gutierrez / Medicare / Medicaid (chair 2.0) — author on 89R SB255
('3aee54f8-89eb-425d-b850-19fff9f2c8ea', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'Gutierrez authored SB 255 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB255','https://senate.texas.gov/member.php?d=19']::text[]),
-- Roland Gutierrez / Healthcare Access (chair 2.0) — author on 89R SB255
('3aee54f8-89eb-425d-b850-19fff9f2c8ea', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Gutierrez authored SB 255 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB255','http://www.rolandfortexas.com/','https://senate.texas.gov/member.php?d=19']::text[]),
-- Royce West / Medicare / Medicaid (chair 2.0) — author on 88R SB671
('1ff93be4-a2d0-432b-af59-ef6ace1eb77b', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'West authored SB 671 in the 88(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=SB671','https://senate.texas.gov/member.php?d=23']::text[]),
-- Royce West / Healthcare Access (chair 2.0) — author on 88R SB671
('1ff93be4-a2d0-432b-af59-ef6ace1eb77b', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'West authored SB 671 in the 88(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=SB671','https://senate.texas.gov/member.php?d=23']::text[]),
-- Sarah Eckhardt / Healthcare Access (chair 2.0) — author on 89R SB255
('2775a1c4-d7e5-45ce-9633-f1ad137c546a', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Eckhardt authored SB 255 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB255','https://www.saraheckhardt.com/issues','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB361']::text[]),
-- Sarah Eckhardt / Medicare / Medicaid (chair 2.0) — author on 89R SB255
('2775a1c4-d7e5-45ce-9633-f1ad137c546a', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'Eckhardt authored SB 255 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB255','https://www.saraheckhardt.com/issues','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=SB11']::text[]),
-- Terry Meza / Healthcare Access (chair 2.0) — author on 89R HB1920
('b9cb31c9-15e0-405d-a8a0-d64850bf0955', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Meza authored HB 1920 in the 89(R) session, "Relating to the expansion of eligibility for Medicaid to certain individuals diagnosed with certain mental health disorders." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB1920','https://www.terrymeza.com/','https://capitol.texas.gov/Members/MemberInfo.aspx?Leg=89&Chamber=H&Code=A3455']::text[]),
-- Toni Rose / Healthcare Access (chair 2.0) — author on 87R HB389
('43567dd1-db59-40af-928e-03708237eb98', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Rose authored HB 389 in the 87(R) session, "Relating to the expansion of eligibility for Medicaid to certain persons under the federal Patient Protection and Affordable Care Act." Texas has not adopted the expansion, so the bill did not become law.', ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=87R&Bill=HB389','https://capitol.texas.gov/Members/MemberInfo.aspx?Leg=89&Chamber=H&Code=A2555','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB457']::text[]);

UPDATE inform.politician_context c SET reasoning = i.reasoning, sources = i.sources
FROM tx_intent i WHERE c.politician_id = i.pid AND c.topic_id = i.tid;

-- Guard 1: intended text landed, a TLO bill page is cited, and the template phrase is GONE.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM tx_intent i
  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid
  WHERE c.reasoning IS DISTINCT FROM i.reasoning OR c.sources IS DISTINCT FROM i.sources
     OR c.reasoning ILIKE '%Medicaid expansion%'
     OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%capitol.texas.gov/BillLookup/%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) wrong', bad; END IF;
END $$;

-- Guard 2: exactly 24 rows touched, nothing created or deleted, NO CHAIR MOVED, no orphans.
DO $$
DECLARE n int; ctx_after int; ans_after int; chair_sum_after numeric; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM tx_snapshot;
  SELECT count(*) INTO n FROM tx_intent i
  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid;
  IF n <> 24 THEN RAISE EXCEPTION 'guard 2 failed: matched % rows, expected 24', n; END IF;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT coalesce(sum(value), 0) INTO chair_sum_after FROM inform.politician_answers;
  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 2 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;
  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 2 failed: answers moved % -> %', snap.ans_before, ans_after; END IF;
  IF chair_sum_after <> snap.chair_sum_before THEN RAISE EXCEPTION 'guard 2 failed: a chair moved (% -> %)', snap.chair_sum_before, chair_sum_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 2 failed: % orphan answer(s)', orphans; END IF;
  RAISE NOTICE 'tx medicaid template ok: % rows', n;
END $$;

COMMIT;
