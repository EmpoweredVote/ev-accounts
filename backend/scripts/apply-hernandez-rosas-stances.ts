import 'dotenv/config';
import { parse } from 'csv-parse/sync';
import { readFileSync } from 'fs';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const csv = readFileSync('data/stance-research/2026-05-08-jorge-hernandez-rosas.csv', 'utf8');
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
  upserted++;
}
console.log(`Done — Upserted: ${upserted}, Skipped: ${skipped}`);
await pool.end();
