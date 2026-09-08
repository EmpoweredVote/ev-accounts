#!/usr/bin/env node
/**
 * push-stance-csv.mjs — write an approved stance-research CSV into the OPEN season.
 *
 * Replaces the copy-paste `node --import tsx -e "..."` block in the
 * research-stances skill, which is long enough that it gets retyped wrong.
 *
 * 🔴 A STANCE IS WRITTEN INTO A SEASON. The SQL comes from seasonService, which
 * resolves the open season and that season's pinned ladder revision in the SAME
 * statement — so the season cannot close between reading it and writing. Do not
 * hand-roll it: `politician_answers` carries a NOT NULL season_id and
 * topic_revision_id, and its primary key is (politician_id, topic_id, season_id).
 *
 * 🔴 `assertWritten` IS NOT OPTIONAL. The upsert SELECTs from season_questions
 * joined to the open season. With no open season the SELECT yields no rows,
 * NOTHING is written, and NOTHING raises — a push would report success having
 * saved nothing. assertWritten turns that silence into a named error.
 *
 * 🔴 THE ANSWER AND THE CONTEXT ARE WRITTEN TOGETHER, IN ONE TRANSACTION.
 * `reasoning` is the public "here's why" on the Essentials profile and the
 * Compass, so it must never lag the value it explains.
 *
 * ⚠ This does NOT re-run the value-change guard. Diff the proposed values against
 * the open season BEFORE calling it, and push only NEW rows and changes a human
 * signed off on. --dry-run rolls back so you can see the row counts first.
 *
 * RUN: node scripts/push-stance-csv.mjs --csv=data/stance-research/FILE.csv --dry-run
 *      node scripts/push-stance-csv.mjs --csv=data/stance-research/FILE.csv
 */
import 'dotenv/config';
import { readFileSync } from 'fs';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';
import { UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL, assertWritten } from '../src/lib/seasonService.js';

const args = process.argv.slice(2);
const flag = (n) => { const h = args.find((a) => a.startsWith(`--${n}=`)); return h ? h.slice(n.length + 3) : null; };
const csvPath = flag('csv');
const DRY = args.includes('--dry-run');
if (!csvPath) { console.error('need --csv=<path>'); process.exit(1); }

// Parsed with a real RFC-4180 parser, never by splitting on commas — reasoning
// carries commas, quotes and dollar amounts.
const rows = parse(readFileSync(csvPath, 'utf8'), { columns: true, skip_empty_lines: true, bom: true });
console.log(`${rows.length} row(s) in ${csvPath}${DRY ? '  (DRY RUN — will roll back)' : ''}`);

const editorId = process.env.EV_EDITOR_ID ?? null;
if (!editorId) console.warn('⚠ EV_EDITOR_ID is unset — these rows will carry no attributable editor');

await pool.query('BEGIN');
try {
  for (const r of rows) {
    const { rows: [who] } = await pool.query(
      `SELECT id::text FROM essentials.politicians WHERE lower(full_name) = lower($1)`, [r.full_name]);
    if (!who) throw new Error(`politician not found: ${r.full_name}`);
    const { rows: [topic] } = await pool.query(
      `SELECT id::text FROM inform.compass_topics WHERE topic_key = $1`, [r.topic_key]);
    if (!topic) throw new Error(`topic_key not found: ${r.topic_key}`);
    if (!r.reasoning?.trim()) throw new Error(`${r.full_name}/${r.topic_key}: reasoning is blank, and it is voter-facing`);

    const ans = await pool.query(UPSERT_ANSWER_SQL, [who.id, topic.id, Number(r.value), editorId]);
    await assertWritten(ans.rowCount ?? 0, topic.id);

    const sources = [r.source_url_1, r.source_url_2, r.source_url_3].filter((s) => s && s.trim());
    const ctx = await pool.query(UPSERT_CONTEXT_SQL, [who.id, topic.id, r.reasoning, sources, editorId]);
    await assertWritten(ctx.rowCount ?? 0, topic.id);

    console.log(`  ✓ ${r.full_name} / ${r.topic_key} = ${r.value}  (${sources.length} source(s))`);
  }
  await pool.query(DRY ? 'ROLLBACK' : 'COMMIT');
  console.log(DRY ? 'ROLLED BACK — nothing written' : `COMMITTED ${rows.length} stance(s)`);
} catch (e) {
  await pool.query('ROLLBACK');
  console.error('ROLLED BACK:', e.message);
  process.exitCode = 1;
}
await pool.end();
