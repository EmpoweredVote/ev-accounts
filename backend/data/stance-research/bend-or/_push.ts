/**
 * Push Bend, OR wave-1 stances into inform.politician_answers / inform.politician_context
 * and the verbatim quotes into essentials.quotes.
 *
 * Input: wave1-stances.json — keyed by politician external_id + topic_key (resolved here, so no
 * UUIDs are ever hardcoded). Validates that (a) every external_id resolves to exactly one
 * politician, (b) every topic_key is a LIVE compass topic, (c) every value is 1-5, and
 * (d) every stance carries at least one source URL. Aborts the whole transaction otherwise.
 *
 * Run: node --import tsx data/stance-research/bend-or/_push.ts [payload.json]
 *      (payload defaults to wave1-stances.json; pass a filename for later waves)
 */
import 'dotenv/config';
import { readFileSync } from 'fs';
import { Pool } from 'pg';

const DIR = 'data/stance-research/bend-or';
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

type Stance = {
  external_id: number;
  name: string;
  topic_key: string;
  value: number;
  reasoning: string;
  sources: string[];
  quote_text?: string;
};

(async () => {
  const file = process.argv[2] || 'wave1-stances.json';
  const payload: Stance[] = JSON.parse(readFileSync(`${DIR}/${file}`, 'utf8'));
  console.log(`Payload: ${file}`);

  // ---- validate ----
  const bad = payload.filter(
    (s) => !(s.value >= 1 && s.value <= 5) || !s.sources?.length || !s.reasoning?.trim(),
  );
  if (bad.length) {
    console.error('Invalid rows (value out of 1-5, no source, or no reasoning):',
      bad.map((b) => `${b.name}/${b.topic_key}`));
    process.exit(1);
  }

  const exts = [...new Set(payload.map((s) => s.external_id))];
  const keys = [...new Set(payload.map((s) => s.topic_key))];

  const pr = await pool.query(
    `SELECT external_id, id, full_name FROM essentials.politicians WHERE external_id = ANY($1::bigint[])`,
    [exts],
  );
  const polId = new Map<number, string>(pr.rows.map((r: any) => [parseInt(r.external_id, 10), r.id]));
  const missingPol = exts.filter((e) => !polId.has(e));
  if (missingPol.length) {
    console.error('Unresolved external_ids:', missingPol);
    process.exit(1);
  }

  const tr = await pool.query(
    `SELECT topic_key, id FROM inform.compass_topics WHERE topic_key = ANY($1::text[]) AND is_live AND is_active`,
    [keys],
  );
  const topicId = new Map<string, string>(tr.rows.map((r: any) => [r.topic_key, r.id]));
  const missingTopic = keys.filter((k) => !topicId.has(k));
  if (missingTopic.length) {
    console.error('Unknown or non-live topic_keys:', missingTopic);
    process.exit(1);
  }

  console.log(`Validated ${payload.length} stances over ${exts.length} politicians and ${keys.length} topics.`);

  // ---- answers + context ----
  await pool.query('BEGIN');
  try {
    let n = 0;
    for (const s of payload) {
      const pid = polId.get(s.external_id)!;
      const tid = topicId.get(s.topic_key)!;
      await pool.query(
        `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
         VALUES ($1,$2,$3)
         ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`,
        [pid, tid, s.value],
      );
      await pool.query(
        `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
         VALUES ($1,$2,$3,$4)
         ON CONFLICT (politician_id, topic_id) DO UPDATE
           SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
        [pid, tid, s.reasoning, s.sources],
      );
      n++;
    }
    await pool.query(
      `UPDATE essentials.politicians SET last_stances_researched_at = NOW()
       WHERE external_id = ANY($1::bigint[])`,
      [exts],
    );
    await pool.query('COMMIT');
    console.log(`COMMIT: ${n} answers + ${n} context rows upserted.`);
  } catch (e: any) {
    await pool.query('ROLLBACK');
    console.error('ROLLBACK:', e.message);
    process.exit(1);
  }

  // ---- quotes (Read & Rank pick intentionally NOT auto-set) ----
  const withQuote = payload.filter((s) => s.quote_text?.trim());
  let ins = 0;
  let dup = 0;
  for (const s of withQuote) {
    const pid = polId.get(s.external_id)!;
    const tk = s.topic_key.toLowerCase();
    const { rows } = await pool.query(
      `SELECT id FROM essentials.quotes WHERE politician_id=$1 AND lower(topic_key)=$2 AND quote_text=$3`,
      [pid, tk, s.quote_text],
    );
    if (rows.length) { dup++; continue; }
    const src = s.sources[0];
    let host: string | null = null;
    try { host = new URL(src).hostname; } catch {}
    await pool.query(
      `INSERT INTO essentials.quotes (politician_id, topic_key, quote_text, source_url, source_name)
       VALUES ($1,$2,$3,$4,$5)`,
      [pid, tk, s.quote_text, src, host],
    );
    ins++;
  }
  console.log(`Quotes: ${ins} inserted, ${dup} already present.`);
  await pool.end();
})();
