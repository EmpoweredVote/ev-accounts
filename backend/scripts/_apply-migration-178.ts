import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const sql = readFileSync(path.join(process.cwd(), 'migrations', '178_council_file_details.sql'), 'utf8');

try {
  await pool.query(sql);
  console.log('Migration 178 applied successfully');
  const r = await pool.query(
    "SELECT column_name, data_type FROM information_schema.columns WHERE table_schema='meetings' AND table_name='council_file_details' ORDER BY ordinal_position"
  );
  console.log('Columns found:');
  r.rows.forEach((x: any) => console.log(' ', x.column_name, '—', x.data_type));
  const count = await pool.query("SELECT COUNT(*) FROM meetings.council_file_details");
  console.log('Row count:', count.rows[0].count);
} catch (e: any) {
  console.error('Error:', e.message);
  process.exit(1);
} finally {
  await pool.end();
}
