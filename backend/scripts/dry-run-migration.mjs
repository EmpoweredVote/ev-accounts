#!/usr/bin/env node
/**
 * Run a migration against prod inside a transaction and ALWAYS roll back.
 *
 * The stance retirements were each "dry-run against prod with the rollback confirmed before applying",
 * but that was done by hand each time. Doing it by hand is how a COMMIT eventually slips through, so
 * it is a script: this file cannot commit. It strips the migration's own BEGIN/COMMIT, wraps the rest
 * in a transaction it controls, reports what changed, and rolls back unconditionally -- including on
 * success, and including if the migration's own assertions pass.
 *
 * A migration that RAISEs inside its DO block fails here exactly as it would in production, which is
 * the point: the assertions are tested against real data before anything is written.
 *
 * Usage (from backend/):
 *   node scripts/dry-run-migration.mjs migrations/1512_repoint_primary_site_citations.sql
 */
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import { Pool } from 'pg';

const file = process.argv[2];
if (!file) { console.error('usage: node scripts/dry-run-migration.mjs <migration.sql>'); process.exit(2); }
if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }

// The migration manages its own transaction; we need to manage it instead so the rollback is ours.
const sql = readFileSync(file, 'utf8')
  .replace(/^\s*BEGIN\s*;/im, '')
  .replace(/^\s*COMMIT\s*;/im, '');

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const client = await pool.connect();
let failed = false;
try {
  await client.query('BEGIN');
  const res = await client.query(sql);
  const counts = (Array.isArray(res) ? res : [res])
    .map((r, i) => (r.rowCount == null ? null : `stmt${i}:${r.command ?? '?'}=${r.rowCount}`))
    .filter(Boolean);
  console.log(`DRY RUN OK — ${file}`);
  if (counts.length) console.log(`  ${counts.join('  ')}`);
  console.log('  all assertions inside the migration passed against real data');
} catch (e) {
  failed = true;
  console.error(`DRY RUN FAILED — ${file}`);
  console.error(`  ${e.message}`);
} finally {
  await client.query('ROLLBACK');
  console.log('  ROLLED BACK — prod is unchanged.');
  client.release();
  await pool.end();
}
process.exit(failed ? 1 : 0);
