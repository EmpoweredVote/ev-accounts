import 'dotenv/config';
import { readFileSync } from 'fs';
import { Pool } from 'pg';

const DIR = 'data/stance-research/springfield-mo';
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

(async () => {
  const payload: any[] = JSON.parse(readFileSync(`${DIR}/_resolved.json`, 'utf8'));
  const withQuote = payload.filter(p => p.quote_text && p.quote_text.trim());
  console.log(`Pushing ${payload.length} stances; ${withQuote.length} have a quote.`);

  await pool.query('BEGIN');
  try {
    let ans = 0, ctx = 0;
    for (const s of payload) {
      await pool.query(`
        INSERT INTO inform.politician_answers (politician_id, topic_id, value)
        VALUES ($1,$2,$3)
        ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`,
        [s.politician_id, s.topic_id, s.value]);
      ans++;
      await pool.query(`
        INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
        VALUES ($1,$2,$3,$4)
        ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
        [s.politician_id, s.topic_id, s.reasoning, s.sources]);
      ctx++;
    }
    await pool.query('COMMIT');
    console.log(`COMMIT ok: ${ans} answers, ${ctx} context rows upserted.`);
  } catch (e:any) {
    await pool.query('ROLLBACK');
    console.error('ROLLBACK:', e.message);
    process.exit(1);
  }

  // Quotes (Read & Rank) — insert if quote_text present; do not auto-select RR pick.
  if (withQuote.length) {
    await pool.query('BEGIN');
    try {
      let ins = 0, dup = 0;
      for (const x of withQuote) {
        const tk = x.topic_key.toLowerCase();
        const { rows: d } = await pool.query(
          `SELECT id FROM essentials.quotes WHERE politician_id=$1 AND lower(topic_key)=$2 AND quote_text=$3`,
          [x.politician_id, tk, x.quote_text]);
        if (d.length) { dup++; continue; }
        const src = x.sources[0] || null;
        let sourceName: string | null = null;
        if (src) { try { sourceName = new URL(src).hostname; } catch {} }
        await pool.query(
          `INSERT INTO essentials.quotes (politician_id, topic_key, quote_text, deidentified_text, source_url, source_name)
           VALUES ($1,$2,$3,$4,$5,$6)`,
          [x.politician_id, tk, x.quote_text, x.quote_deidentified || null, src, sourceName]);
        ins++;
      }
      await pool.query('COMMIT');
      console.log(`Quotes: ${ins} inserted, ${dup} already present (RR pick NOT auto-set).`);
    } catch (e:any) { await pool.query('ROLLBACK'); console.error('Quote ROLLBACK:', e.message); }
  }
  await pool.end();
})();
