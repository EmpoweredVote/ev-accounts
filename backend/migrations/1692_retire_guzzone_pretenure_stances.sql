-- 1692_retire_guzzone_pretenure_stances.sql
--
-- Retire Pam Lanman Guzzone / School Vouchers & Public Education Funding, and / Taxation and Public
-- Spending. Operator instruction 2026-08-11.
--
-- WHY: both rested solely on the Blueprint for Maryland's Future (2019 SB1030/HB1413, 2020 SB1000/HB1300).
-- She became a Delegate on 2023-01-11 (mgaleg: "Member of the House of Delegates since January 11, 2023"),
-- so she cannot have supported it. This is the PRE-TENURE class -- the claim is IMPOSSIBLE, not merely
-- unsourced -- and precedent mig 1537 retires it.
-- No honest substitute exists: she sponsors NONE of the 23 in-tenure voucher/BOOST bills and NONE of the
-- 14 in-tenure progressive-tax bills. Contrast her Climate row, which mig 1690 re-sourced to three real
-- in-tenure sponsorships rather than retiring.
--
-- 🔴 Retire = delete the ANSWER and the CONTEXT row. Deleting context alone leaves an orphan answer and
--    trips ANSWER_WITHOUT_CONTEXT (must be 0).
-- 🔴 She is NOT emptied: 7 rows -> 5. So `last_stances_researched_at` is deliberately left alone; the
--    NULL-vs-SET distinction ("nobody looked" vs "we looked and found nothing") only bites at zero rows.
--
-- Rollback -- the ONLY surviving copy of the reasoning, sources and values:
--   backend/data/stance-retirement/2026-08-11-md-guzzone-pretenure-1692-rollback.json
--
BEGIN
;

-- Snapshot first: never hard-code an absolute corpus total in a guard (three sessions write this DB).
CREATE TEMP TABLE _1692_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_total,
       (SELECT count(*) FROM inform.politician_answers)  AS ans_total,
       (SELECT count(*) FROM inform.politician_context WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid) AS her_ctx,
       (SELECT count(*) FROM inform.politician_answers  WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid) AS her_ans
;

DELETE FROM inform.politician_answers
WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid
  AND topic_id IN ('00b95a6a-75db-4521-b523-3326bba938de'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid)
;

DELETE FROM inform.politician_context
WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid
  AND topic_id IN ('00b95a6a-75db-4521-b523-3326bba938de'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid)
;

DO $$
DECLARE b record; bad int;
BEGIN
  SELECT * INTO b FROM _1692_before;

  -- Exactly 2 rows gone from each table, no collateral damage anywhere in the corpus.
  IF (SELECT count(*) FROM inform.politician_context) <> b.ctx_total - 2 THEN
    RAISE EXCEPTION 'guard failed: context delta is not exactly -2';
  END IF;
  IF (SELECT count(*) FROM inform.politician_answers) <> b.ans_total - 2 THEN
    RAISE EXCEPTION 'guard failed: answers delta is not exactly -2';
  END IF;

  -- Both target rows really are gone, from both tables.
  SELECT count(*) INTO bad FROM inform.politician_context
  WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid AND topic_id IN ('00b95a6a-75db-4521-b523-3326bba938de'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid);
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % context row(s) survive', bad; END IF;
  SELECT count(*) INTO bad FROM inform.politician_answers
  WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid AND topic_id IN ('00b95a6a-75db-4521-b523-3326bba938de'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid);
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % answer row(s) survive', bad; END IF;

  -- She keeps everything else and is NOT emptied.
  IF (SELECT count(*) FROM inform.politician_context WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid) <> b.her_ctx - 2 THEN
    RAISE EXCEPTION 'guard failed: she lost more than the 2 retired context rows';
  END IF;
  IF (SELECT count(*) FROM inform.politician_context WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid) = 0 THEN
    RAISE EXCEPTION 'guard failed: politician emptied -- not intended, and it changes what the timestamp means';
  END IF;

  -- No orphan answers anywhere (ANSWER_WITHOUT_CONTEXT must stay 0).
  SELECT count(*) INTO bad FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id);
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % orphan answer(s) corpus-wide', bad; END IF;
END
$$;

COMMIT
;
