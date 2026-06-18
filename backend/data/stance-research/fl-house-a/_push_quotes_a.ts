import { parse } from 'csv-parse/sync';
import { readFileSync } from 'fs';
import { pool } from '../../../src/lib/db.js';

const PID: Record<string, string> = {
  'Jimmy Patronis': '2d222946-7125-4c9e-ab59-9ebab94f8301',
  'Neal P. Dunn': '66dd6633-ef79-46d1-87b6-5b52203de64c',
  'Kat Cammack': 'c45b3872-ec1d-4758-bf9d-f12a0a5c2a3f',
  'Aaron Bean': '34042ebd-71f0-4a8c-abd8-7389da45b754',
  'John Rutherford': '8561df96-52fd-42de-b6ad-e15dfc748c52',
  'Randy Fine': 'a5a58bc3-e654-4a35-8418-84e1ba57506f',
  'Cory Mills': '6862f5a4-4de8-41c8-ac4d-427cc3aa56de',
  'Mike Haridopolos': 'bdb92754-d3e8-4255-9c10-244ebea4380a',
  'Darren Soto': 'f0b782ce-1d2a-4c62-9773-c6a36b5ef291',
  'Maxwell Frost': 'eeeab0bd-ce73-4152-8e80-679d3d031ad7',
  'Daniel Webster': '7119c7db-6909-4d05-8613-95d5dc9818de',
  'Gus Bilirakis': '2ccd34d7-ca08-45d1-bfe0-f64c63349e18',
  'Anna Paulina Luna': 'ef7d314c-bc47-4ed6-954c-77eb3d53eb69',
  'Kathy Castor': '12623f00-b182-4511-a5a1-c715113b96cc',
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
