import 'dotenv/config';
import { parse } from 'csv-parse/sync';
import { readFileSync } from 'fs';
import pg from 'pg';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

function extractSource(notes: string): string | null {
  const match = notes.match(/https?:\/\/\S+/);
  return match ? match[0] : null;
}

async function main() {
  const csvPath = path.join(__dirname, '..', 'data', 'stance-research', '2026-05-31-jeff-helfrich.csv');
  const csv = readFileSync(csvPath, 'utf8');
  const rows = parse(csv, { columns: true, skip_empty_lines: true }) as Array<Record<string, string>>;

  let upserted = 0, skipped = 0;
  for (const r of rows) {
    if (!r.value || r.value === 'null' || r.value === '') { skipped++; continue; }
    await pool.query(
      `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
       VALUES ($1, $2, $3)
       ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`,
      [r.politician_id, r.topic_id, parseInt(r.value)]
    );
    const source = extractSource(r.notes);
    const sources = source ? [source] : [];
    await pool.query(
      `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
      [r.politician_id, r.topic_id, r.notes, sources]
    );
    upserted++;
  }
  console.log(`Done — Upserted: ${upserted}, Skipped: ${skipped}`);
  await pool.end();
}

main().catch(err => { console.error(err); process.exit(1); });
