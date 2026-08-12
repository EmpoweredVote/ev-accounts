-- 1726_medicaid_class_chair_misalignment.sql
-- CHAIR CORRECTION — the MISALIGNED slice of the "backed Medicaid expansion" template class.
--
-- Follows 1722 (MD sourcing) and 1724 (TX sourcing), which fixed the SOURCING half of this class
-- and explicitly left the chairs alone. This migration fixes the other half: rows where the stored
-- chair contradicts the row's own reasoning. 🔑 SOURCING IS NOT TOUCHED HERE — the two Maryland
-- rows are still carrying the unsourced template sentence and remain on 1722's owed list.
--
-- 🔴🔴 THE "18 MISALIGNED ROWS" WAS A REGEX ESTIMATE. THE TRUE COUNT IS 3.
-- The 18 came from matching pro/anti wording over whole reasoning strings and comparing to the
-- pole. That detector over-fires the way every first cut in this workstream has: "Nikema Williams
-- voted against a limited Medicaid expansion ... because she favored full expansion" is anti-worded
-- at chair 1 and CORRECT; "Marty Jackley touts that states stopped ObamaCare's forced Medicaid
-- expansion" is support-worded at chair 4 and CORRECT. So the class was not filtered, it was READ:
-- all 222 rows at a pole (140 at chair 4-5, 82 at chair 1-2 — every row that could possibly be
-- misaligned) plus all 32 rows at chair 3, one at a time. Three survived.
--
-- ✅ Not one row at chair 1-2 was anti-worded. The anti-at-the-pro-pole direction is EMPTY in this
-- class. Every one of the 82 Medicare/Medicaid rows at chair 4-5 was a genuine opponent of
-- expansion (Abbott, Paxton, McConnell, Reeves, Tillis, Stitt...) correctly at the anti pole.
--
-- THE THREE ROWS
--
-- 1. Benjamin F. Kramer / Healthcare Access: 5 -> 2
-- 2. Jeff Waldstreicher / Healthcare Access: 5 -> 2
--    Both Maryland Senate Democrats sitting at chair 5, "stay out of healthcare entirely and let
--    private markets handle all coverage decisions", on reasoning that says the opposite:
--    "Kramer consistently votes for healthcare access expansion including Medicaid expansion";
--    "Waldstreicher is a strong advocate for universal healthcare access. He backed Medicaid
--    expansion". This is the migration-1714 defect — the chair written as an INTENSITY rating
--    ("5 = strongly holds this view") rather than one of five discrete options — surviving in rows
--    the 1714 cohort never covered. 1722's header predicted exactly these two and refused to
--    re-source them for this reason; this is that prediction discharged.
-- 🔑 TARGET = THE LEAST EXTREME PRO-SIDE OPTION THE REASONING SUPPORTS, so 2 and not 1. Chair 1 is
--    "make healthcare free and available to everyone, paid for and run by the public sector" —
--    single payer, which neither row claims. Waldstreicher's "universal healthcare access" is
--    access, not public provision. Chair 2, "everyone has affordable coverage through a mix of
--    public programs and regulated private insurance", is what coverage-expansion plus drug-cost
--    legislation evidences, and it is where 1714 put thirteen other Marylanders on this same topic.
--
-- 3. Pete Aguilar / Medicare / Medicaid: 1 -> 2
--    A DIFFERENT DEFECT IN THE SAME FAMILY — not a pole inversion but a self-contradiction. The
--    row's own last sentence reads: "His record aligns with stance 2 (lower Medicare age,
--    significant Medicaid expansion) rather than stance 1 (Medicare for all regardless of age); no
--    evidence of co-sponsoring Medicare for All legislation." The reasoning names its own target
--    chair and the stored value is the one it rules out. His Healthcare Access row already sits at
--    2 citing the State Public Option Act, which is the same reading.
-- ⚠ Two other rows named a stance number that differed from the stored chair and were REJECTED on
--    reading: Vern Buchanan ("preventing a pure value 5 assignment" — 4 is the conclusion, not the
--    rejected alternative) and Dianne Hesselbein (her reasoning carries an explicit 2026-07-27
--    orchestrator note recording the deliberate 2 -> 3 correction and why; the "chair 2" phrase it
--    quotes is superseded inside the same paragraph).
--
-- 🔴 FOUND WHILE READING, NOT FIXED HERE — THE COHORT IS AGAIN THE DEFECT. Kramer and Waldstreicher
-- are inverted far beyond this class. Reading all of their rows: Kramer also sits at chair 5 on
-- Voting Rights, Abortion and Medicare/Medicaid with plainly pro-worded reasoning ("a reliable
-- pro-choice vote", "opposes voter ID restrictions", "supports expanding Medicaid"), and
-- Waldstreicher at chair 5 on Immigration, Trans Athletes, Same-Sex Marriage, Taxes, Abortion and
-- Voting Rights. Those topics are four of the ones [[chair_reasoning_inversion]] records as
-- UNCALIBRATED — never tested — which is why the 1714 re-scan reported the batch signature gone.
-- It is not gone; it is hiding in untested topics. Recorded in
-- .planning/todos/2026-08-12-medicaid-misaligned-disposition.md, deliberately NOT swept into this
-- migration: each of those topics needs its pro pole established from compass_stances first, and a
-- mechanical 5 -> 1 flip is exactly the error 1714 warns about.
--
-- Rollback: data/stance-retirement/2026-08-12-medicaid-misaligned-1726-rollback.json
BEGIN;

CREATE TEMP TABLE mis_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

-- Benjamin F. Kramer / Healthcare Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid
  AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 5;

-- Jeff Waldstreicher / Healthcare Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'da75c207-bb23-477e-b3c0-7c462394b570'::uuid
  AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 5;

-- Pete Aguilar / Medicare / Medicaid: chair 1 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '822966a7-5f09-4151-ba43-630afbd676c2'::uuid
  AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid AND value = 1;

-- Guard 1: all three rows hold exactly the intended chair.
DO $$
DECLARE bad int; n int;
BEGIN
  SELECT count(*) FILTER (WHERE a.value <> w.want), count(*) INTO bad, n
  FROM (VALUES
    ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric),
    ('da75c207-bb23-477e-b3c0-7c462394b570'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric),
    ('822966a7-5f09-4151-ba43-630afbd676c2'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 2::numeric)
  ) AS w(pid, tid, want)
  JOIN inform.politician_answers a ON a.politician_id=w.pid AND a.topic_id=w.tid;
  IF n <> 3 THEN RAISE EXCEPTION 'guard 1 failed: matched % rows, expected 3', n; END IF;
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) do not hold the intended chair', bad; END IF;
END $$;

-- Guard 2: the reasoning is untouched — this migration changes chairs only, and the two Maryland
-- rows must still be carrying the template sentence they are owed sourcing for.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE ((c.politician_id = '7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid
       OR c.politician_id = 'da75c207-bb23-477e-b3c0-7c462394b570'::uuid)
     AND c.topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
     AND c.reasoning NOT ILIKE '%Medicaid expansion%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard 2 failed: % MD row(s) lost their reasoning', bad; END IF;
END $$;

-- Guard 3: nothing created or deleted, no orphans, and no row in the class is left pro-worded at
-- the anti pole. The check is chair-value based and topic-agnostic, per the mig-1712 lesson.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; inverted int; snap record;
BEGIN
  SELECT * INTO snap FROM mis_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 3 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;
  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 3 failed: answers moved % -> %', snap.ans_before, ans_after; END IF;

  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 3 failed: % orphan answer(s)', orphans; END IF;

  -- The two hand-read signatures of a pro-worded row at the anti pole, restricted to this class.
  SELECT count(*) INTO inverted FROM inform.politician_context c
  JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
  WHERE c.reasoning ILIKE '%Medicaid expansion%' AND a.value >= 4
    AND c.reasoning ~* '(consistently votes for healthcare|strong advocate for universal)';
  IF inverted > 0 THEN RAISE EXCEPTION 'guard 3 failed: % row(s) still pro-worded at the anti pole', inverted; END IF;

  RAISE NOTICE 'medicaid chair misalignment ok: 3 rows, context=% answers=% orphans=%', ctx_after, ans_after, orphans;
END $$;

COMMIT;
