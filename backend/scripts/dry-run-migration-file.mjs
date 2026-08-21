#!/usr/bin/env node
/**
 * DRY-RUN a migration against prod: run the body, show what it touched, then ROLLBACK.
 *
 * The sibling of `apply-migration-file.mjs`, and the step that should come before it.
 * CLAUDE.md asks for a `BEGIN; … ROLLBACK;` rehearsal against prod before applying; this
 * does it from the file, so there is no hand-copied SQL between the reviewed migration and
 * the rehearsal, and the migration's own post-verify gate runs for real.
 *
 * 🔴 THIS IS THE ONLY WAY TO GET REAL BEGIN/ROLLBACK SEMANTICS. The Supabase MCP wraps each
 * call in its own transaction, so a "dry run" through it commits. This connects as `ev_api`
 * over the pooler in backend/.env and owns the transaction itself.
 *
 * 🔴 A CLEAN RUN MEANS THE SQL EXECUTED, NOT THAT THE DATA IS WHAT YOU MEANT. Pass --verify
 * with a read-back query to see the end state from inside the transaction, before it is
 * thrown away — that is the point of the rehearsal.
 *
 *   node scripts/dry-run-migration-file.mjs migrations/1842_foo.sql
 *   node scripts/dry-run-migration-file.mjs migrations/1842_foo.sql --verify scripts/1842-verify.sql
 *   node scripts/dry-run-migration-file.mjs migrations/1842_foo.sql --verify - <<'SQL'
 *     SELECT result, count(*) FROM essentials.race_candidates GROUP BY 1;
 *   SQL
 *
 * Exit 0 = the migration ran and every guard inside it passed. Exit 1 = it raised; the
 * message is printed and nothing was written either way.
 */
import fs from 'node:fs';
import pg from 'pg';
import { fileURLToPath } from 'node:url';

const local = (rel) => fileURLToPath(new URL(rel, import.meta.url));

const args = process.argv.slice(2);
const file = args.find((a) => !a.startsWith('--') && args[args.indexOf(a) - 1] !== '--verify');
const vi = args.indexOf('--verify');
const verifyArg = vi === -1 ? null : args[vi + 1];

if (!file) {
  console.error('usage: node scripts/dry-run-migration-file.mjs <migration.sql> [--verify <query.sql>|-]');
  process.exit(2);
}

const raw = fs.readFileSync(file, 'utf8');
// The migration manages its own BEGIN/COMMIT; strip them so this script owns the transaction.
const sql = raw.replace(/^\s*BEGIN\s*;/im, '').replace(/^\s*COMMIT\s*;/im, '');

const verifySql = verifyArg === '-' ? fs.readFileSync(0, 'utf8')
  : verifyArg ? fs.readFileSync(verifyArg, 'utf8')
  : null;

const env = fs.readFileSync(local('../.env'), 'utf8');
const line = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l));
if (!line) { console.error('no DATABASE_URL in backend/.env'); process.exit(2); }
const pool = new pg.Pool({ connectionString: line.replace(/^DATABASE_URL=/, '').trim(), ssl: { rejectUnauthorized: false } });
const client = await pool.connect();
client.on('notice', (n) => console.log('NOTICE:', n.message.trim()));

let ok = false;
try {
  await client.query('BEGIN');
  const res = await client.query(sql);
  const counts = (Array.isArray(res) ? res : [res])
    .map((r, i) => (r.rowCount != null ? `stmt${i}:${r.command}=${r.rowCount}` : `stmt${i}:${r.command}`))
    .join('  ');
  console.log(counts);

  if (verifySql) {
    const v = await client.query(verifySql);
    for (const r of Array.isArray(v) ? v : [v]) {
      if (!r.rows || !r.rows.length) continue;
      console.log('\nVERIFY:');
      console.table(r.rows);
    }
  }
  ok = true;
} catch (e) {
  console.error('FAILED:', e.message);
  if (e.where) console.error('  at:', e.where.split('\n')[0]);
} finally {
  // Roll back on success AND on failure — this script never commits.
  await client.query('ROLLBACK').catch(() => {});
  client.release();
  await pool.end();
}

console.log(ok ? '\nROLLED BACK — dry run passed, nothing written.' : '\nROLLED BACK — dry run FAILED, nothing written.');
process.exit(ok ? 0 : 1);
