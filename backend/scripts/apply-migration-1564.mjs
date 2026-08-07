#!/usr/bin/env node
/**
 * Apply migration 1564 to production. Operator-approved 2026-08-06.
 *
 * The file carries its own BEGIN/COMMIT and every guard raises, so a failed guard aborts the whole
 * transaction and changes nothing. This wrapper exists to capture the before/after state around it,
 * because "it ran" is not the same claim as "it did what it said".
 */
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const sql = readFileSync(path.join(HERE, '..', 'migrations', '1564_retire_fabricated_source_stances.sql'), 'utf8');

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const c = await pool.connect();
const counts = async () => ({
  answers: Number((await c.query('SELECT count(*) n FROM inform.politician_answers')).rows[0].n),
  context: Number((await c.query('SELECT count(*) n FROM inform.politician_context')).rows[0].n),
});

try {
  const before = await counts();
  console.log(`before: answers ${before.answers}, context ${before.context}`);
  c.on('notice', (m) => console.log(`  NOTICE: ${m.message}`));
  await c.query(sql);
  const after = await counts();
  console.log(`\nafter:  answers ${after.answers}, context ${after.context}`);
  console.log(`delta:  answers ${after.answers - before.answers}, context ${after.context - before.context}`);
  console.log('\n✅ MIGRATION 1564 APPLIED AND COMMITTED');
} catch (e) {
  console.log(`\n🔴 APPLY FAILED (transaction aborted, nothing changed): ${e.message}`);
  process.exitCode = 1;
} finally {
  c.release();
  await pool.end();
}
