#!/usr/bin/env node
/**
 * Retire Brian M. Crosby / Climate Change and Environmental Protection (operator instruction 2026-08-11).
 *
 * This is the one GENUINE CONTRADICTION pass 5 found: the stance says he "has supported the Climate
 * Solutions Now Act" and the roll call shows he voted NAY on 2022RS SB0528 at Third Reading. The claim is
 * not merely unsourced, it is contradicted by the primary record.
 *
 * 🔴 Retirement is irreversible: the rollback JSON is written BEFORE the delete and is the only surviving
 *    copy of the reasoning, sources and value.
 * 🔴 Retire = DELETE from BOTH inform.politician_answers AND inform.politician_context, or the orphan
 *    answer trips ANSWER_WITHOUT_CONTEXT (must be 0).
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const NUM = flag('--num'), SQL_OUT = flag('--sql'), ROLLBACK = flag('--rollback');
if (!NUM || !SQL_OUT || !ROLLBACK) { console.error('need --num --sql --rollback'); process.exit(2); }

const PID = '898845f9-cb93-4162-b0ed-6842eacda5d6';
const TID = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
const EVIDENCE = 'https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf';

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const { rows: doomed } = await pool.query(`
  SELECT p.full_name, c.politician_id, c.topic_id, t.title AS topic,
         a.value, a.write_in_text, c.reasoning, c.sources
  FROM inform.politician_context c
  JOIN essentials.politicians p ON p.id = c.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
  LEFT JOIN inform.politician_answers a ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
  WHERE c.politician_id = $1::uuid AND c.topic_id = $2::uuid`, [PID, TID]);
if (doomed.length !== 1) { console.error(`ABORT expected 1 row, got ${doomed.length}`); await pool.end(); process.exit(1); }

const { rows: tot } = await pool.query(
  `SELECT (SELECT count(*) FROM inform.politician_context WHERE politician_id=$1::uuid) ctx,
          (SELECT count(*) FROM inform.politician_answers  WHERE politician_id=$1::uuid) ans`, [PID]);
await pool.end();

fs.writeFileSync(ROLLBACK, JSON.stringify({
  migration: `${NUM}_retire_crosby_climate_contradicted`,
  retired_on: '2026-08-11',
  authorised_by: 'operator instruction 2026-08-11 ("Retire Crosby Climate change stance for now")',
  rule: 'The stance asserts Crosby "has supported the Climate Solutions Now Act". The House roll call for 2022RS SB0528 (Third Reading Passed with Amendments, 95-42) records him in the Nay list. Contradicted by the primary record, not merely unsourced.',
  evidence: EVIDENCE,
  restore_note: 'Retirement DELETED the answer and the context row; restoring is an INSERT into inform.politician_answers and inform.politician_context from the values below.',
  politician_row_counts_before: { context: Number(tot[0].ctx), answers: Number(tot[0].ans) },
  expected_after: { context: Number(tot[0].ctx) - 1, answers: Number(tot[0].ans) - 1, emptied: false },
  row_count: 1, rows: doomed,
}, null, 2));

const sql = `-- ${NUM}_retire_crosby_climate_contradicted.sql
--
-- Retire Brian M. Crosby / Climate Change and Environmental Protection. Operator instruction 2026-08-11.
--
-- WHY: the stance reads "Crosby has supported the Climate Solutions Now Act and clean energy investment
-- while balancing concerns about economic impacts…". The primary record contradicts it — the House vote on
-- 2022RS SB0528 (Third Reading Passed with Amendments, 95-42) lists him among the 42 Nays:
--   ${EVIDENCE}
-- This is the ONE genuine contradiction in the 157-row roll-call pass; the other 12 Nay verdicts were rows
-- that CORRECTLY described the member as opposing the bill.
--
-- ⚠ Distinguish this from the pre-tenure class (migs 1692, and the 29 rows still queued): those claims are
-- IMPOSSIBLE because the member was not in office. This one was possible and is simply FALSE.
--
-- 🔴 Retire = delete the ANSWER and the CONTEXT row; context alone leaves an orphan answer and trips
--    ANSWER_WITHOUT_CONTEXT (must be 0).
-- 🔴 He is NOT emptied: ${tot[0].ctx} rows -> ${Number(tot[0].ctx) - 1}, so \`last_stances_researched_at\` is left alone.
--
-- Rollback — the only surviving copy of the reasoning, sources and value:
--   backend/data/stance-retirement/2026-08-11-md-crosby-climate-${NUM}-rollback.json
--
BEGIN
;

-- Snapshot inside the transaction: never assert an absolute corpus total (three sessions write this DB).
CREATE TEMP TABLE _${NUM}_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_total,
       (SELECT count(*) FROM inform.politician_answers)  AS ans_total,
       (SELECT count(*) FROM inform.politician_context WHERE politician_id = '${PID}'::uuid) AS his_ctx
;

DELETE FROM inform.politician_answers  WHERE politician_id = '${PID}'::uuid AND topic_id = '${TID}'::uuid
;
DELETE FROM inform.politician_context  WHERE politician_id = '${PID}'::uuid AND topic_id = '${TID}'::uuid
;

DO $$
DECLARE b record; bad int;
BEGIN
  SELECT * INTO b FROM _${NUM}_before;
  IF (SELECT count(*) FROM inform.politician_context) <> b.ctx_total - 1 THEN
    RAISE EXCEPTION 'guard failed: context delta is not exactly -1'; END IF;
  IF (SELECT count(*) FROM inform.politician_answers) <> b.ans_total - 1 THEN
    RAISE EXCEPTION 'guard failed: answers delta is not exactly -1'; END IF;

  SELECT count(*) INTO bad FROM inform.politician_context
  WHERE politician_id = '${PID}'::uuid AND topic_id = '${TID}'::uuid;
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: context row survives'; END IF;
  SELECT count(*) INTO bad FROM inform.politician_answers
  WHERE politician_id = '${PID}'::uuid AND topic_id = '${TID}'::uuid;
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: answer row survives'; END IF;

  IF (SELECT count(*) FROM inform.politician_context WHERE politician_id = '${PID}'::uuid) <> b.his_ctx - 1 THEN
    RAISE EXCEPTION 'guard failed: he lost more than the one retired row'; END IF;
  IF (SELECT count(*) FROM inform.politician_context WHERE politician_id = '${PID}'::uuid) = 0 THEN
    RAISE EXCEPTION 'guard failed: politician emptied -- not intended'; END IF;

  SELECT count(*) INTO bad FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id);
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % orphan answer(s) corpus-wide', bad; END IF;
END
$$;

COMMIT
;
`;
fs.writeFileSync(SQL_OUT, sql);
console.log(`retiring: ${doomed[0].full_name} / ${doomed[0].topic} (value ${doomed[0].value})`);
console.log(`his rows: ${tot[0].ctx} -> ${Number(tot[0].ctx) - 1} (not emptied)`);
