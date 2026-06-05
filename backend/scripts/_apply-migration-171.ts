import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const sql = readFileSync(path.join(process.cwd(), 'migrations', '171_la_council_votes.sql'), 'utf8');

try {
  await pool.query(sql);
  console.log('Migration 171 applied successfully');
  const r = await pool.query(
    "SELECT table_name FROM information_schema.tables WHERE table_schema='meetings' AND table_name IN ('la_council_agenda_items','la_council_votes') ORDER BY table_name"
  );
  console.log('Tables found:', r.rows.map((x: any) => x.table_name));
} catch (e: any) {
  console.error('Error:', e.message);
  process.exit(1);
} finally {
  await pool.end();
}
