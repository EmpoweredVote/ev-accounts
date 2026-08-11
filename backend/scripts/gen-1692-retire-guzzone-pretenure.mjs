#!/usr/bin/env node
/**
 * Retire Pam Lanman Guzzone's two PRE-TENURE stances (operator instruction 2026-08-11).
 *
 * Both rest solely on the Blueprint for Maryland's Future (2019/2020). She became a Delegate on
 * 2023-01-11, so she cannot have supported it -- the claim is IMPOSSIBLE, not merely unsourced. She
 * sponsors none of the 23 in-tenure voucher/BOOST bills and none of the 14 in-tenure progressive-tax
 * bills, so there is no honest substitute (contrast her Climate row, re-sourced by mig 1690 to three
 * real in-tenure sponsorships).
 *
 * 🔴 RETIREMENT IS THE ONE IRREVERSIBLE STEP. The rollback JSON written here is the ONLY surviving copy
 *    of the reasoning, sources and values, and it is written BEFORE the delete.
 * 🔴 Retire = DELETE from BOTH inform.politician_answers AND inform.politician_context. Deleting only
 *    the context row would leave an orphan answer and trip ANSWER_WITHOUT_CONTEXT (must be 0).
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const NUM = flag('--num'), SQL_OUT = flag('--sql'), ROLLBACK = flag('--rollback');
if (!NUM || !SQL_OUT || !ROLLBACK) { console.error('need --num --sql --rollback'); process.exit(2); }

const PID = '589ed7af-602a-4ec9-8072-448b05446772';
const TARGETS = [
  { topic: 'School Vouchers & Public Education Funding', topic_id: '00b95a6a-75db-4521-b523-3326bba938de' },
  { topic: 'Taxation and Public Spending', topic_id: 'f7e5678d-dadd-4556-a2fc-446e24642ceb' },
];

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

// FULL text, straight from the DB, before anything is deleted.
const { rows: doomed } = await pool.query(`
  SELECT p.full_name, c.politician_id, c.topic_id, t.title AS topic,
         a.value, a.write_in_text, c.reasoning, c.sources
  FROM inform.politician_context c
  JOIN essentials.politicians p ON p.id = c.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
  LEFT JOIN inform.politician_answers a ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
  WHERE c.politician_id = $1::uuid AND c.topic_id = ANY($2::uuid[])`,
  [PID, TARGETS.map((t) => t.topic_id)]);

if (doomed.length !== 2) { console.error(`ABORT expected 2 rows, got ${doomed.length}`); await pool.end(); process.exit(1); }

const { rows: totals } = await pool.query(
  `SELECT (SELECT count(*) FROM inform.politician_context WHERE politician_id=$1::uuid) AS ctx,
          (SELECT count(*) FROM inform.politician_answers  WHERE politician_id=$1::uuid) AS ans`, [PID]);
await pool.end();

fs.writeFileSync(ROLLBACK, JSON.stringify({
  migration: `${NUM}_retire_guzzone_pretenure_stances`,
  retired_on: '2026-08-11',
  authorised_by: 'operator instruction, 2026-08-11 ("retire both")',
  rule: 'Both stances rest solely on the Blueprint for Maryland\'s Future (2019/2020). Pam Lanman Guzzone became a Delegate 2023-01-11, so she cannot have supported it -- the claim is impossible, not merely unsourced. No in-tenure substitute exists: she sponsors none of the 23 voucher/BOOST bills and none of the 14 progressive-tax bills from 2023 onward.',
  restore_note: 'Retirement DELETED both the answer and the context row, so restoring is an INSERT into inform.politician_answers and inform.politician_context using the values below.',
  politician_row_counts_before: { context: Number(totals[0].ctx), answers: Number(totals[0].ans) },
  expected_after: { context: Number(totals[0].ctx) - 2, answers: Number(totals[0].ans) - 2, emptied: false },
  row_count: doomed.length,
  rows: doomed,
}, null, 2));

const sql = `-- ${NUM}_retire_guzzone_pretenure_stances.sql
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
-- 🔴 She is NOT emptied: 7 rows -> 5. So \`last_stances_researched_at\` is deliberately left alone; the
--    NULL-vs-SET distinction ("nobody looked" vs "we looked and found nothing") only bites at zero rows.
--
-- Rollback -- the ONLY surviving copy of the reasoning, sources and values:
--   backend/data/stance-retirement/2026-08-11-md-guzzone-pretenure-${NUM}-rollback.json
--
BEGIN
;

-- Snapshot first: never hard-code an absolute corpus total in a guard (three sessions write this DB).
CREATE TEMP TABLE _${NUM}_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_total,
       (SELECT count(*) FROM inform.politician_answers)  AS ans_total,
       (SELECT count(*) FROM inform.politician_context WHERE politician_id = '${PID}'::uuid) AS her_ctx,
       (SELECT count(*) FROM inform.politician_answers  WHERE politician_id = '${PID}'::uuid) AS her_ans
;

DELETE FROM inform.politician_answers
WHERE politician_id = '${PID}'::uuid
  AND topic_id IN (${TARGETS.map((t) => `'${t.topic_id}'::uuid`).join(', ')})
;

DELETE FROM inform.politician_context
WHERE politician_id = '${PID}'::uuid
  AND topic_id IN (${TARGETS.map((t) => `'${t.topic_id}'::uuid`).join(', ')})
;

DO $$
DECLARE b record; bad int;
BEGIN
  SELECT * INTO b FROM _${NUM}_before;

  -- Exactly 2 rows gone from each table, no collateral damage anywhere in the corpus.
  IF (SELECT count(*) FROM inform.politician_context) <> b.ctx_total - 2 THEN
    RAISE EXCEPTION 'guard failed: context delta is not exactly -2';
  END IF;
  IF (SELECT count(*) FROM inform.politician_answers) <> b.ans_total - 2 THEN
    RAISE EXCEPTION 'guard failed: answers delta is not exactly -2';
  END IF;

  -- Both target rows really are gone, from both tables.
  SELECT count(*) INTO bad FROM inform.politician_context
  WHERE politician_id = '${PID}'::uuid AND topic_id IN (${TARGETS.map((t) => `'${t.topic_id}'::uuid`).join(', ')});
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % context row(s) survive', bad; END IF;
  SELECT count(*) INTO bad FROM inform.politician_answers
  WHERE politician_id = '${PID}'::uuid AND topic_id IN (${TARGETS.map((t) => `'${t.topic_id}'::uuid`).join(', ')});
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % answer row(s) survive', bad; END IF;

  -- She keeps everything else and is NOT emptied.
  IF (SELECT count(*) FROM inform.politician_context WHERE politician_id = '${PID}'::uuid) <> b.her_ctx - 2 THEN
    RAISE EXCEPTION 'guard failed: she lost more than the 2 retired context rows';
  END IF;
  IF (SELECT count(*) FROM inform.politician_context WHERE politician_id = '${PID}'::uuid) = 0 THEN
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
`;
fs.writeFileSync(SQL_OUT, sql);
console.log(`rows to retire: ${doomed.length}`);
for (const d of doomed) console.log(`  ${d.topic} (value ${d.value})`);
console.log(`her rows: ${totals[0].ctx} -> ${Number(totals[0].ctx) - 2} (not emptied)`);
console.log(`rollback: ${ROLLBACK}`);
