#!/usr/bin/env node
/**
 * Rehearse SEVERAL migrations in ONE transaction against prod, and always roll back.
 *
 * ── WHY THIS EXISTS BESIDE dry-run-migration.mjs ────────────────────────────────────────────
 *
 * `dry-run-migration.mjs` rehearses one file. That was enough while a wave was one file. The
 * state seating pass made a wave THREE: a dates file, a people file, and a seating file — and
 * the third one's pre-checks are computed over what the first two write.
 *
 * 🔴 REHEARSING THEM SEPARATELY PROVES NOTHING ABOUT THE CHAIN, AND IT FAILS IN THE DIRECTION
 *    THAT READS AS SUCCESS. CC_0467's P4 reads dates CC_0465 writes, so on its own it aborts at
 *    P4 — which looks like a broken file rather than a missing predecessor. Worse the other way
 *    round: CC_0467's selection digest is taken over the politician ids CC_0466 creates, so a
 *    solo rehearsal of CC_0467 measures the digest of a world that will not exist when it runs.
 *
 * This file cannot commit. There is no COMMIT in it; the ROLLBACK is in the finally block and
 * runs on success, on failure, and on an assertion firing inside a migration's own DO block.
 *
 * ⚠ A CLEAN RUN MEANS THE SQL EXECUTED IN ORDER, NOT THAT THE DATA IS WHAT YOU MEANT. Pass
 * --verify with a read-back query to see the end state from inside the transaction, before it
 * is thrown away. That is the whole value of rehearsing against real data.
 *
 * Usage (from backend/):
 *   node scripts/rehearse-migration-chain.mjs migrations/CC_0465_*.sql migrations/CC_0466_*.sql \
 *                                             migrations/CC_0467_*.sql
 *   node scripts/rehearse-migration-chain.mjs migrations/CC_0465_*.sql --verify scripts/x.sql
 *   node scripts/rehearse-migration-chain.mjs migrations/CC_0465_*.sql --verify - <<'SQL'
 *     SELECT count(*) FROM essentials.office_swearing_in;
 *   SQL
 */
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import { Pool } from 'pg';

import { assertSingleTransaction, stripOwnTransaction } from './lib/migration-file-guards.mjs';

const argv = process.argv.slice(2);
const vi = argv.indexOf('--verify');
const verifyArg = vi === -1 ? null : argv[vi + 1];
const files = argv.filter((a, i) => a !== '--verify' && (vi === -1 || i !== vi + 1));

if (!files.length) {
  console.error('usage: node scripts/rehearse-migration-chain.mjs <a.sql> [<b.sql> …] [--verify <query.sql>|-]');
  process.exit(2);
}
if (vi !== -1 && !verifyArg) { console.error('--verify needs a path, or - to read the query from stdin'); process.exit(2); }
if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }

const verifySql = verifyArg === '-' ? readFileSync(0, 'utf8') : verifyArg ? readFileSync(verifyArg, 'utf8') : null;

// 🔴 Refuse any file carrying more than one transaction BEFORE touching the database. This tool
// strips only the first BEGIN;/COMMIT; of each file, so a later COMMIT; would commit for real
// while the run still printed "ROLLED BACK". Checked for EVERY file up front, not as each one
// is reached — a refusal discovered halfway through has already run the files before it.
const prepared = [];
for (const f of files) {
  const raw = readFileSync(f, 'utf8');
  try {
    assertSingleTransaction(raw, f);
  } catch (err) {
    console.error(`REFUSED — ${f}`);
    console.error(`  ${err.message}`);
    process.exit(2);
  }
  prepared.push({ file: f, sql: stripOwnTransaction(raw) });
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const client = await pool.connect();
client.on('notice', (n) => console.log(`  NOTICE: ${String(n.message).trim()}`));
let failed = null;
try {
  await client.query('BEGIN');
  for (const { file, sql } of prepared) {
    console.log(`\n── ${file}`);
    await client.query(sql);
    console.log('   OK — every assertion in this file passed, against the state its predecessors left');
  }
  console.log(`\nCHAIN OK — ${prepared.length} file(s), in order, against real data.`);
  if (verifySql) {
    const v = await client.query(verifySql);
    for (const r of Array.isArray(v) ? v : [v]) {
      if (!r.rows || !r.rows.length) continue;
      console.log('  VERIFY:');
      console.table(r.rows);
    }
  }
} catch (err) {
  failed = err;
  console.error(`\nFAILED — ${err.message}`);
  if (err.where) console.error(`  where: ${err.where}`);
} finally {
  await client.query('ROLLBACK');
  console.log('ROLLED BACK — nothing was written.');
  client.release();
  await pool.end();
}
process.exit(failed ? 1 : 0);
