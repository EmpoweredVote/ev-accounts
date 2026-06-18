import { parse } from 'csv-parse/sync';
import { readFileSync } from 'fs';
import { pool } from '../../../src/lib/db.js';

const PID: Record<string, string> = {
  'Laurel M. Lee': '96cc507d-bb3a-4e25-ae6c-4b937f68f9f4', 'Laurel Lee': '96cc507d-bb3a-4e25-ae6c-4b937f68f9f4',
  'Vern Buchanan': '8ee77a4f-4653-45d4-ab9c-15061ff4ecbb',
  'W. Gregory Steube': '9325e98f-db12-4214-bae0-9898e9438fac', 'Greg Steube': '9325e98f-db12-4214-bae0-9898e9438fac',
  'Scott Franklin': '23f38835-0bf7-43c7-88fa-229004eb9c3d',
  'Byron Donalds': '13972902-fa8a-4ebc-91f6-b451db77c7d1',
  'Brian J. Mast': '1b776971-4c34-4453-ba38-6772f6783b1c', 'Brian Mast': '1b776971-4c34-4453-ba38-6772f6783b1c',
  'Lois Frankel': 'b4040115-b3ea-4500-89cf-1ddaecafc94e',
  'Jared Moskowitz': '1cb8827c-6ae0-4fcf-884c-94ad2246f15d',
  'Frederica S. Wilson': '3fc35d7d-a121-4b5e-b243-b150daf6e628', 'Frederica Wilson': '3fc35d7d-a121-4b5e-b243-b150daf6e628',
  'Debbie Wasserman Schultz': '097623b0-3063-4943-a13c-89d213ca5829',
  'Mario Diaz-Balart': 'f529c1d6-7a48-4607-b3aa-a96bea7f0d26',
  'Maria Elvira Salazar': '7fba1fee-9053-4a51-9f02-2f72997eafa6',
  'Carlos A. Gimenez': '3030383b-2aaf-40fd-9dfb-8867d1d02f99', 'Carlos Gimenez': '3030383b-2aaf-40fd-9dfb-8867d1d02f99',
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
