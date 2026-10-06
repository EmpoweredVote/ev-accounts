// Trim the method paragraph out of published voter-facing reasoning, and bring research.csv back
// into step with the database.
//
// 🔴 `reasoning` publishes verbatim as "Why this position?". On a SCORED row the sweep paragraph —
// which outlets were searched, how many articles came back, which could not be searched at all — is
// method, not position. On a BLANK row it is the justification and must stay; no blank is touched
// here, because only scored rows reach the queue.
//
// Two things are kept in step: `inform.politician_context.reasoning` for the five rows already
// published, and `research.csv` for all seven rows edited today. The removed method text is moved
// into the CSV's editor_note so the record survives.
//
// Usage: npx tsx scripts/_trim_voter_prose.mjs [--apply]
import fs from 'node:fs';
import { parse } from 'csv-parse/sync';
import { stringify } from 'csv-stringify/sync';
import pg from 'pg';

const APPLY = process.argv.includes('--apply');
const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

const START = /A sweep of the three Duluth outlets|A name-only sweep/;
const ENDS = ['so no outlet count here covers them.', 'returns the same results for any query including a nonsense one.'];
const NAMES_INSTRUMENT = /(\bAct\b|\bOrdinance\b|Chapter \d|Resolution No\.|\broll call\b|resolution \d|\b\d{2}-\d{3,4}R\b|\b\d{2}-\d{3}-O\b)/;

/** Remove the method span. Returns {text, removed} or throws. */
function strip(text, who) {
  // A duplicated opening sentence is its own defect; drop the second copy first.
  const firstSentence = text.slice(0, (text.indexOf('. ') + 1) || 0).trim();
  if (firstSentence.length > 30) {
    const dup = text.indexOf(firstSentence, firstSentence.length);
    if (dup > -1) text = (text.slice(0, dup) + text.slice(dup + firstSentence.length)).replace(/\s{2,}/g, ' ');
  }
  const m = START.exec(text);
  if (!m) throw new Error(who + ': no method span found');
  if (START.exec(text.slice(m.index + 1))) throw new Error(who + ': more than one method span');
  let end = -1;
  for (const e of ENDS) { const i = text.indexOf(e, m.index); if (i > -1) end = Math.max(end, i + e.length); }
  if (end < 0) throw new Error(who + ': method span has no end marker');
  const removed = text.slice(m.index, end);
  const out = (text.slice(0, m.index) + text.slice(end)).replace(/\s{2,}/g, ' ').trim();
  return { text: out, removed };
}

function check(before, after, who, isRecord) {
  const bad = [];
  if (after.length >= before.length) bad.push('did not get shorter');
  if (after.length < 300) bad.push('suspiciously short: ' + after.length);
  if (!/\bchair\b/i.test(after)) bad.push('no longer names a chair');
  if (isRecord && !NAMES_INSTRUMENT.test(after)) bad.push('record row no longer names an instrument');
  if ((before.match(/["“”]/g) || []).length !== (after.match(/["“”]/g) || []).length) bad.push('quotation marks changed');
  if (/^[a-z]/.test(after)) bad.push('starts mid-sentence');
  if (START.test(after)) bad.push('method text survives');
  if (bad.length) throw new Error(who + ': ' + bad.join('; '));
}

// ---- 1. the five published rows -------------------------------------------------
const live = await pool.query(`
  SELECT c.politician_id::text AS pid, c.topic_id::text AS tid, pl.full_name AS name, ct.topic_key, c.reasoning
    FROM inform.politician_context c
    JOIN essentials.politicians pl ON pl.id = c.politician_id
    JOIN inform.compass_topics ct ON ct.id = c.topic_id
   WHERE (c.created_at::date = current_date OR c.updated_at::date = current_date)
     AND c.reasoning ~* 'A sweep of the three|name-only sweep|returned [0-9]+ unique articles'
   ORDER BY length(c.reasoning) DESC`);
if (live.rows.length !== 5) { console.error(`REFUSED: expected 5 published rows, found ${live.rows.length}`); process.exit(1); }

const csvRows = parse(fs.readFileSync(B + '/research.csv'), { columns: true, skip_empty_lines: true });
const findCsv = (n, t) => csvRows.find((r) => r.full_name === n && r.topic_key === t);

const edits = [];
for (const r of live.rows) {
  const src = findCsv(r.name, r.topic_key);
  if (!src) { console.error(`REFUSED: no research.csv row for ${r.name}/${r.topic_key}`); process.exit(1); }
  const { text, removed } = strip(r.reasoning, r.name + '/' + r.topic_key);
  check(r.reasoning, text, r.name + '/' + r.topic_key, src.evidence_type === 'record');
  edits.push({ ...r, newText: text, removed, csv: src });
  console.log(`${(r.name + ' / ' + r.topic_key).padEnd(44)} ${r.reasoning.length} -> ${text.length}`);
}

// ---- 2. the two already trimmed in the queue -------------------------------------
const pending = await pool.query(`
  SELECT full_name_raw AS name, topic_key, proposed_reasoning AS reasoning
    FROM inform.stance_research_review
   WHERE status = 'pending' AND full_name_raw IN ('Janet Kennedy','Saura Jost')`);
if (pending.rows.length !== 2) { console.error(`REFUSED: expected 2 trimmed pending rows, found ${pending.rows.length}`); process.exit(1); }
for (const r of pending.rows) {
  const src = findCsv(r.name, r.topic_key);
  if (!src) { console.error(`REFUSED: no research.csv row for ${r.name}/${r.topic_key}`); process.exit(1); }
  if (src.reasoning === r.reasoning) { console.log(`${r.name} / ${r.topic_key}: already in step`); continue; }
  console.log(`${(r.name + ' / ' + r.topic_key).padEnd(44)} csv ${src.reasoning.length} -> ${r.reasoning.length} (match the queue)`);
  edits.push({ name: r.name, topic_key: r.topic_key, newText: r.reasoning, removed: '', csv: src, pendingOnly: true });
}

if (!APPLY) { console.log('\n(dry run — pass --apply)'); await pool.end(); process.exit(0); }

// ---- 3. write ---------------------------------------------------------------------
let dbUpdated = 0;
for (const e of edits) {
  if (!e.pendingOnly) {
    const res = await pool.query('UPDATE inform.politician_context SET reasoning = $3 WHERE politician_id = $1::uuid AND topic_id = $2::uuid', [e.pid, e.tid, e.newText]);
    dbUpdated += res.rowCount;
  }
  e.csv.reasoning = e.newText;
  if (e.removed) {
    e.csv.editor_note = (e.csv.editor_note ? e.csv.editor_note + ' ' : '')
      + 'Search method moved out of the voter-facing reasoning on 2026-10-06, verbatim: ' + e.removed;
  }
}
const HEAD = ['full_name', 'topic_key', 'value', 'evidence_type', 'reasoning', 'source_url_1', 'source_url_2', 'source_url_3', 'quote_text', 'quote_deidentified', 'editor_note'];
fs.writeFileSync(B + '/research.csv', stringify(csvRows.map((r) => Object.fromEntries(HEAD.map((h) => [h, r[h] ?? '']))), { header: true, columns: HEAD }));
console.log(`\npolitician_context rows updated: ${dbUpdated} | research.csv rows synced: ${edits.length}`);
await pool.end();
