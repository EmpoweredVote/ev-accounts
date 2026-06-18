import { parse } from 'csv-parse/sync';
import { readFileSync } from 'fs';
import { pool } from '../../../src/lib/db.js';

const PID: Record<string, string> = {
  'Nick LaLota': '4c5a2401-4b0c-4a48-9225-11c2ad768a12',
  'Andrew R. Garbarino': '587df016-35d9-43af-b839-db4899c384fc', 'Andrew Garbarino': '587df016-35d9-43af-b839-db4899c384fc',
  'Thomas R. Suozzi': 'a1c608d4-3feb-4bb0-b797-00453d08a0e8', 'Thomas Suozzi': 'a1c608d4-3feb-4bb0-b797-00453d08a0e8', 'Tom Suozzi': 'a1c608d4-3feb-4bb0-b797-00453d08a0e8',
  'Laura Gillen': '643cde96-6b12-4fce-a404-0191a5c7f9bd',
  'Gregory W. Meeks': 'b2f09c72-ceda-4942-a7db-9f0c5f229713', 'Gregory Meeks': 'b2f09c72-ceda-4942-a7db-9f0c5f229713',
  'Grace Meng': 'a49af796-7961-4b82-8327-989691880a39',
  'Nydia M. Velázquez': '8fad496d-d92d-4f68-bc25-93102a4612e8', 'Nydia Velázquez': '8fad496d-d92d-4f68-bc25-93102a4612e8', 'Nydia Velazquez': '8fad496d-d92d-4f68-bc25-93102a4612e8',
  'Hakeem S. Jeffries': '42f9ff9e-b15d-4b0a-9f73-23015121069c', 'Hakeem Jeffries': '42f9ff9e-b15d-4b0a-9f73-23015121069c',
  'Yvette D. Clarke': 'efa0cb88-6ae0-47dc-abe1-b1388983addf', 'Yvette Clarke': 'efa0cb88-6ae0-47dc-abe1-b1388983addf',
  'Daniel S. Goldman': 'c7f357ce-2fa0-4760-921b-905ff6a63944', 'Daniel Goldman': 'c7f357ce-2fa0-4760-921b-905ff6a63944', 'Dan Goldman': 'c7f357ce-2fa0-4760-921b-905ff6a63944',
  'Nicole Malliotakis': '56dfd8dd-ac7a-482a-848a-7c1d0e979606',
  'Jerrold Nadler': '49a6832a-d736-4cfc-abd3-8ee9bf424ab0', 'Jerry Nadler': '49a6832a-d736-4cfc-abd3-8ee9bf424ab0',
  'Adriano Espaillat': '26636234-c292-4a02-8205-6b84f6864f82',
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
