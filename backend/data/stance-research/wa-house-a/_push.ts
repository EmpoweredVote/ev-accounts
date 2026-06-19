import { parse } from 'csv-parse/sync';
import { readFileSync } from 'fs';
import { pool } from '../../../src/lib/db.js';

const csvPath = process.argv[2];
const recs: any[] = parse(readFileSync(csvPath, 'utf8'), { columns: true, skip_empty_lines: true });

// Resolve external_id -> politician_id
const extIds = [...new Set(recs.map((r) => parseInt(r.external_id)))];
const { rows: pidRows } = await pool.query(
  'SELECT id, external_id, full_name FROM essentials.politicians WHERE external_id = ANY($1::int[])',
  [extIds]
);
const PID: Record<number, string> = {};
const NAME: Record<number, string> = {};
for (const r of pidRows) { PID[r.external_id] = r.id; NAME[r.external_id] = r.full_name; }

// Resolve topic_key -> topic_id
const { rows: topicRows } = await pool.query(
  "SELECT id, topic_key FROM inform.compass_topics WHERE is_live = true"
);
const TID: Record<string, string> = {};
for (const r of topicRows) TID[r.topic_key.toLowerCase()] = r.id;

// Validate resolution
const unresolved: string[] = [];
for (const r of recs) {
  const ext = parseInt(r.external_id);
  if (!PID[ext]) unresolved.push('external_id ' + ext);
  if (!TID[r.topic_key.toLowerCase()]) unresolved.push('topic_key ' + r.topic_key);
}
if (unresolved.length) { console.error('UNRESOLVED: ' + [...new Set(unresolved)].join(', ')); process.exit(1); }

let answers = 0, contexts = 0, quotesIns = 0, quotesDup = 0, selected = 0;
const leaks: string[] = [];

await pool.query('BEGIN');
try {
  for (const r of recs) {
    const ext = parseInt(r.external_id);
    const pid = PID[ext];
    const tid = TID[r.topic_key.toLowerCase()];
    const value = parseInt(r.value);
    const sources = [r.source_url_1, r.source_url_2, r.source_url_3].map((s) => (s || '').trim()).filter(Boolean);

    await pool.query(
      `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
       VALUES ($1,$2,$3) ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`,
      [pid, tid, value]
    );
    answers++;
    await pool.query(
      `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
       VALUES ($1,$2,$3,$4) ON CONFLICT (politician_id, topic_id)
       DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
      [pid, tid, r.reasoning, sources]
    );
    contexts++;

    // Quotes
    const qtext = (r.quote_text || '').trim();
    if (!qtext) continue;
    const qdeid = (r.quote_deidentified || '').trim();
    const tk = r.topic_key.toLowerCase();
    const source_url = sources[0] || null;
    const { rows: dup } = await pool.query(
      'SELECT id FROM essentials.quotes WHERE politician_id=$1 AND lower(topic_key)=$2 AND quote_text=$3',
      [pid, tk, qtext]
    );
    let quoteId;
    if (dup.length) { quoteId = dup[0].id; quotesDup++; }
    else {
      const sourceName = source_url ? (() => { try { return new URL(source_url).hostname; } catch { return null; } })() : null;
      const { rows: ins } = await pool.query(
        'INSERT INTO essentials.quotes (politician_id,topic_key,quote_text,deidentified_text,source_url,source_name) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id',
        [pid, tk, qtext, qdeid || null, source_url, sourceName]
      );
      quoteId = ins[0].id; quotesIns++;
    }
    // Read & Rank selection: select if de-id present and no surname leak
    if (qdeid) {
      const surname = (NAME[ext] || '').replace(/,?\s*(Jr\.?|Sr\.?|III|II|IV)$/i, '').trim().split(/\s+/).pop()!;
      const escaped = surname.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      if (surname && new RegExp('\\b' + escaped + '\\b', 'i').test(qdeid)) {
        leaks.push(NAME[ext] + '/' + tk + ': surname leak'); continue;
      }
      await pool.query('UPDATE essentials.quotes SET readrank_selected=false WHERE politician_id=$1 AND lower(topic_key)=$2', [pid, tk]);
      await pool.query('UPDATE essentials.quotes SET readrank_selected=true WHERE id=$1', [quoteId]);
      selected++;
    }
  }
  await pool.query('COMMIT');
  console.log(JSON.stringify({ answers, contexts, quotesIns, quotesDup, selected, leaks }, null, 2));
} catch (e: any) {
  await pool.query('ROLLBACK');
  console.error('ROLLBACK', e.message);
  process.exit(1);
}
await pool.end();
