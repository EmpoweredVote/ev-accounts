import { parse } from 'csv-parse/sync';
import { readFileSync } from 'fs';
import { pool } from '../../../src/lib/db.js';

const PID: Record<string, string> = {
  'Alexandria Ocasio-Cortez': '86533db6-cfb8-49bf-a265-74a3b3845575',
  'Ritchie Torres': '606e50d6-7c2d-424e-86f3-e7da3c2d37f7',
  'George Latimer': '147f2883-d8c0-4a56-9adb-6b8c7990264b',
  'Michael Lawler': 'cd4e9f29-d1b0-40c1-9e4a-5024cdc7b028', 'Mike Lawler': 'cd4e9f29-d1b0-40c1-9e4a-5024cdc7b028',
  'Patrick Ryan': '8a42070d-5aaf-49f2-bdcd-5086adab496c', 'Pat Ryan': '8a42070d-5aaf-49f2-bdcd-5086adab496c',
  'Josh Riley': 'a6a6d7b2-88d4-441b-8191-d5baa0db6987',
  'Paul Tonko': '52bbba11-e099-457b-a05b-aa8f4f5a5b13',
  'Elise M. Stefanik': '963af970-08b4-4880-abf2-eab8afe78e67', 'Elise Stefanik': '963af970-08b4-4880-abf2-eab8afe78e67',
  'John W. Mannion': '09a47b4e-566f-46dc-b14b-547b93282f09', 'John Mannion': '09a47b4e-566f-46dc-b14b-547b93282f09',
  'Nicholas A. Langworthy': '556dded4-bd76-4e22-863f-60fa5e1d4d56', 'Nick Langworthy': '556dded4-bd76-4e22-863f-60fa5e1d4d56',
  'Claudia Tenney': 'e1d8c7bb-cde0-4ec5-8863-0b8ce838cb57',
  'Joseph D. Morelle': 'c02d8232-aa7a-429a-9abe-dccb409c1c6f', 'Joseph Morelle': 'c02d8232-aa7a-429a-9abe-dccb409c1c6f', 'Joe Morelle': 'c02d8232-aa7a-429a-9abe-dccb409c1c6f',
  'Timothy M. Kennedy': '7e37b0b1-d311-4cf3-8f19-f861626d5d98', 'Tim Kennedy': '7e37b0b1-d311-4cf3-8f19-f861626d5d98',
};

const csvPath = process.argv[2];
const recs: any[] = parse(readFileSync(csvPath, 'utf8'), { columns: true, skip_empty_lines: true });
const quotes = recs
  .filter((r) => (r.quote_text || '').trim())
  .map((r) => ({
    politician_id: PID[r.full_name],
    topic_key: r.topic_key.toLowerCase(),
    quote_text: r.quote_text.trim(),
    quote_deidentified: (r.quote_deidentified || '').trim(),
    source_url: [r.source_url_1, r.source_url_2, r.source_url_3].find((s) => s && s.trim()) || null,
    full_name: r.full_name,
    make_selected: !!(r.quote_deidentified || '').trim(),
  }));

let inserted = 0, dupes = 0, selected = 0;
const leaks: string[] = [];
const unresolved = quotes.filter((q) => !q.politician_id);
if (unresolved.length) {
  console.error('UNRESOLVED names: ' + [...new Set(unresolved.map((q) => q.full_name))].join(', '));
  process.exit(1);
}

await pool.query('BEGIN');
try {
  for (const x of quotes) {
    const tk = x.topic_key;
    const { rows: dup } = await pool.query(
      'SELECT id FROM essentials.quotes WHERE politician_id=$1 AND lower(topic_key)=$2 AND quote_text=$3',
      [x.politician_id, tk, x.quote_text]
    );
    let quoteId;
    if (dup.length) { quoteId = dup[0].id; dupes++; }
    else {
      const sourceName = x.source_url ? (() => { try { return new URL(x.source_url).hostname; } catch { return null; } })() : null;
      const { rows: ins } = await pool.query(
        'INSERT INTO essentials.quotes (politician_id,topic_key,quote_text,deidentified_text,source_url,source_name) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id',
        [x.politician_id, tk, x.quote_text, x.quote_deidentified || null, x.source_url || null, sourceName]
      );
      quoteId = ins[0].id; inserted++;
    }
    if (x.make_selected) {
      if (!x.quote_deidentified) { leaks.push(x.politician_id + '/' + tk + ': no de-id'); continue; }
      const surname = (x.full_name || '').trim().split(/\s+/).pop()!;
      const escaped = surname.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      if (surname && new RegExp('\\b' + escaped + '\\b', 'i').test(x.quote_deidentified)) {
        leaks.push(x.politician_id + '/' + tk + ': surname leak'); continue;
      }
      await pool.query('UPDATE essentials.quotes SET readrank_selected=false WHERE politician_id=$1 AND lower(topic_key)=$2', [x.politician_id, tk]);
      await pool.query('UPDATE essentials.quotes SET readrank_selected=true WHERE id=$1', [quoteId]);
      selected++;
    }
  }
  await pool.query('COMMIT');
  console.log(JSON.stringify({ inserted, dupes, selected, leaks }, null, 2));
} catch (e: any) {
  await pool.query('ROLLBACK');
  console.error('ROLLBACK', e.message);
  process.exit(1);
}
await pool.end();
