-- 1695_retire_crosby_climate_contradicted.sql
--
-- Retire Brian M. Crosby / Climate Change and Environmental Protection. Operator instruction 2026-08-11.
--
-- WHY: the stance reads "Crosby has supported the Climate Solutions Now Act and clean energy investment
-- while balancing concerns about economic impacts…". The primary record contradicts it — the House vote on
-- 2022RS SB0528 (Third Reading Passed with Amendments, 95-42) lists him among the 42 Nays:
--   https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf
-- This is the ONE genuine contradiction in the 157-row roll-call pass; the other 12 Nay verdicts were rows
-- that CORRECTLY described the member as opposing the bill.
--
-- ⚠ Distinguish this from the pre-tenure class (migs 1692, and the 29 rows still queued): those claims are
-- IMPOSSIBLE because the member was not in office. This one was possible and is simply FALSE.
--
-- 🔴 Retire = delete the ANSWER and the CONTEXT row; context alone leaves an orphan answer and trips
--    ANSWER_WITHOUT_CONTEXT (must be 0).
-- 🔴 He is NOT emptied: 8 rows -> 7, so `last_stances_researched_at` is left alone.
--
-- Rollback — the only surviving copy of the reasoning, sources and value:
--   backend/data/stance-retirement/2026-08-11-md-crosby-climate-1695-rollback.json
--
BEGIN
;

-- Snapshot inside the transaction: never assert an absolute corpus total (three sessions write this DB).
CREATE TEMP TABLE _1695_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_total,
       (SELECT count(*) FROM inform.politician_answers)  AS ans_total,
       (SELECT count(*) FROM inform.politician_context WHERE politician_id = '898845f9-cb93-4162-b0ed-6842eacda5d6'::uuid) AS his_ctx
;

DELETE FROM inform.politician_answers  WHERE politician_id = '898845f9-cb93-4162-b0ed-6842eacda5d6'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;
DELETE FROM inform.politician_context  WHERE politician_id = '898845f9-cb93-4162-b0ed-6842eacda5d6'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;

DO $$
DECLARE b record; bad int;
BEGIN
  SELECT * INTO b FROM _1695_before;
  IF (SELECT count(*) FROM inform.politician_context) <> b.ctx_total - 1 THEN
    RAISE EXCEPTION 'guard failed: context delta is not exactly -1'; END IF;
  IF (SELECT count(*) FROM inform.politician_answers) <> b.ans_total - 1 THEN
    RAISE EXCEPTION 'guard failed: answers delta is not exactly -1'; END IF;

  SELECT count(*) INTO bad FROM inform.politician_context
  WHERE politician_id = '898845f9-cb93-4162-b0ed-6842eacda5d6'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid;
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: context row survives'; END IF;
  SELECT count(*) INTO bad FROM inform.politician_answers
  WHERE politician_id = '898845f9-cb93-4162-b0ed-6842eacda5d6'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid;
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: answer row survives'; END IF;

  IF (SELECT count(*) FROM inform.politician_context WHERE politician_id = '898845f9-cb93-4162-b0ed-6842eacda5d6'::uuid) <> b.his_ctx - 1 THEN
    RAISE EXCEPTION 'guard failed: he lost more than the one retired row'; END IF;
  IF (SELECT count(*) FROM inform.politician_context WHERE politician_id = '898845f9-cb93-4162-b0ed-6842eacda5d6'::uuid) = 0 THEN
    RAISE EXCEPTION 'guard failed: politician emptied -- not intended'; END IF;

  SELECT count(*) INTO bad FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id);
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % orphan answer(s) corpus-wide', bad; END IF;
END
$$;

COMMIT
;
