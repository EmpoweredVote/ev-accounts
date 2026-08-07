#!/usr/bin/env node
/**
 * Dry-run migration 1565: execute it for real inside a transaction that is ALWAYS rolled back.
 *
 * Every guard, every DELETE and UPDATE runs against production data exactly as it would on apply, and
 * then the transaction is discarded. This is the only way to know the guards pass and the row counts
 * land where the classification says — a migration that has only been read is a migration nobody has
 * tested.
 *
 * ⚠ It strips the BEGIN/COMMIT from the file and supplies its own, so the rollback cannot be defeated
 * by the script's own COMMIT.
 */
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const sqlRaw = readFileSync(path.join(HERE, '..', 'migrations', '1565_retire_somervillejournal_fabricated_citations.sql'), 'utf8');
const body = sqlRaw.replace(/^\s*BEGIN;\s*$/m, '').replace(/^\s*COMMIT;\s*$/m, '');

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const c = await pool.connect();
const before = {};
try {
  for (const t of ['inform.politician_answers', 'inform.politician_context']) {
    before[t] = Number((await c.query(`SELECT count(*) n FROM ${t}`)).rows[0].n);
  }
  await c.query('BEGIN');
  c.on('notice', (m) => console.log(`  NOTICE: ${m.message}`));
  await c.query(body);

  const after = {};
  for (const t of ['inform.politician_answers', 'inform.politician_context']) {
    after[t] = Number((await c.query(`SELECT count(*) n FROM ${t}`)).rows[0].n);
  }
  console.log('\n✅ ALL GUARDS PASSED — migration executed cleanly inside the transaction\n');
  for (const t of Object.keys(before)) {
    console.log(`  ${t.padEnd(30)} ${before[t]} -> ${after[t]}  (${after[t] - before[t]})`);
  }
  const zeroed = await c.query(`
    SELECT g.name AS government, count(*)::int AS remaining
      FROM inform.politician_answers pa
      JOIN essentials.office_current_holder och ON och.politician_id = pa.politician_id
      JOIN essentials.offices o ON o.id = och.office_id
      JOIN essentials.chambers ch ON ch.id = o.chamber_id
      JOIN essentials.governments g ON g.id = ch.government_id
     WHERE g.name IN ('City of Carson','City of Lynn, Massachusetts, US','City of Alhambra',
                      'City of Waltham, Massachusetts, US','City of Somerville, Massachusetts, US')
     GROUP BY g.name ORDER BY g.name`);
  console.log('\n  answers REMAINING after the migration, for the chip-critical governments:');
  const seen = new Set(zeroed.rows.map((r) => r.government));
  for (const r of zeroed.rows) console.log(`    ${String(r.remaining).padStart(4)}  ${r.government}`);
  for (const g of ['City of Carson', 'City of Lynn, Massachusetts, US', 'City of Alhambra', 'City of Waltham, Massachusetts, US']) {
    if (!seen.has(g)) console.log(`       0  ${g}   🔴 ZERO -> flip hasContext`);
  }
} catch (e) {
  console.log(`\n🔴 DRY RUN FAILED: ${e.message}\n`);
  process.exitCode = 1;
} finally {
  await c.query('ROLLBACK');
  console.log('\n↩  ROLLED BACK — production is untouched.');
  c.release();
  await pool.end();
}
