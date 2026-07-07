import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({
  connectionString: process.env['DATABASE_URL'],
  ssl: { rejectUnauthorized: false },
});

const sql = readFileSync(
  path.join(process.cwd(), 'migrations', '1230_quotes_editor_note.sql'),
  'utf8',
);

try {
  await pool.query(sql);
  console.log('Migration 1230 applied.');

  const r = await pool.query(
    `SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'essentials' AND table_name = 'quotes'
        AND column_name = 'editor_note'`,
  );
  console.log(`editor_note column present: ${r.rowCount === 1}`);
  if (r.rowCount !== 1) process.exitCode = 1;
} catch (e) {
  console.error('Migration 1230 failed:', e);
  process.exitCode = 1;
} finally {
  await pool.end();
}
