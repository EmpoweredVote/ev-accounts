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
 * 🔴 A CLEAN RUN MEANS THE SQL EXECUTED, NOT THAT THE DATA IS WHAT YOU MEANT. The counts and the
 * migration's own assertions can all pass while the rows say something you did not intend. Pass
 * --verify with a read-back query to see the end state from inside the transaction, before it is
 * thrown away. That is the whole value of rehearsing against real data.
 *
 * NOTICEs raised by the migration are forwarded, so a post-verify gate that ends in
 * `RAISE NOTICE '... % rows'` reports here too.
 *
 * Usage (from backend/):
 *   node scripts/dry-run-migration.mjs migrations/1512_repoint_primary_site_citations.sql
 *   node scripts/dry-run-migration.mjs migrations/1842_foo.sql --verify scripts/1842-verify.sql
 *   node scripts/dry-run-migration.mjs migrations/1842_foo.sql --verify - <<'SQL'
 *     SELECT result, count(*) FROM essentials.race_candidates GROUP BY 1;
 *   SQL
 */
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import { Pool } from 'pg';

import { stripOwnTransaction } from './lib/migration-file-guards.mjs';

const argv = process.argv.slice(2);
const vi = argv.indexOf('--verify');
const verifyArg = vi === -1 ? null : argv[vi + 1];
// Guard the vi === -1 case: without it, `vi + 1` is 0 and the migration path itself is filtered out.
const file = argv.filter((a, i) => a !== '--verify' && (vi === -1 || i !== vi + 1))[0];
if (!file) { console.error('usage: node scripts/dry-run-migration.mjs <migration.sql> [--verify <query.sql>|-]'); process.exit(2); }
if (vi !== -1 && !verifyArg) { console.error('--verify needs a path, or - to read the query from stdin'); process.exit(2); }
if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }

const verifySql = verifyArg === '-' ? readFileSync(0, 'utf8') : verifyArg ? readFileSync(verifyArg, 'utf8') : null;

// The migration manages its own transaction; we need to manage it instead so the rollback is ours.
// Shared with apply-migration-file.mjs so a file is rehearsed and applied by the same rule — the
// two had this regex pair duplicated inline until 2026-09-09.
const sql = stripOwnTransaction(readFileSync(file, 'utf8'));

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const client = await pool.connect();
client.on('notice', (n) => console.log(`  NOTICE: ${String(n.message).trim()}`));
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
  if (verifySql) {
    const v = await client.query(verifySql);
    for (const r of Array.isArray(v) ? v : [v]) {
      if (!r.rows || !r.rows.length) continue;
      console.log('  VERIFY:');
      console.table(r.rows);
    }
  }
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
