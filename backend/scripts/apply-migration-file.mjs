#!/usr/bin/env node
/**
 * Apply a migration FROM THE FILE, in one transaction, committing only if every guard inside it
 * passes.
 *
 * 🔑 WHY THIS EXISTS. Migrations 1710 and 1711 were applied by pasting their bodies through a
 * separate channel and then proved equal to the file afterwards. That works, but it puts a
 * hand-copied 14k-character string between the reviewed file and production — and 1712 is 32k.
 * Reading the file is strictly safer: there is no transcription step to get wrong.
 *
 * The migration manages its own BEGIN/COMMIT; this strips them and owns the transaction, so a guard
 * that RAISEs rolls the whole thing back exactly as it would in production.
 *
 * ⚠ Verify AFTER anyway. A clean exit means the SQL ran, not that the data is what you meant.
 *
 *   node scripts/apply-migration-file.mjs migrations/1712_....sql
 */
// dotenv, not a hardcoded path. This script previously read the connection string from
// 'C:/EV-Accounts/backend/.env', which exists on exactly one machine and throws ENOENT on every
// other — so the safe applier was unusable precisely where someone would reach for the unsafe
// hand-pasted alternative. Same loading as scripts/dry-run-migration.mjs, so a migration is
// rehearsed and applied against the same database by the same rule.
import 'dotenv/config';
import fs from 'node:fs';
import pg from 'pg';

import { stripOwnTransaction, unsafeDropTargets } from './lib/migration-file-guards.mjs';

const file = process.argv[2];
if (!file) { console.error('usage: node scripts/apply-migration-file.mjs <migration.sql>'); process.exit(2); }

const raw = fs.readFileSync(file, 'utf8');
const sql = stripOwnTransaction(raw);

// 🔴 THE DROP GUARD USED TO REFUSE THE HOUSE STYLE, AND THAT SENT PEOPLE BACK TO HAND-PASTING.
//
// It was /DROP\s+(TABLE|SCHEMA|DATABASE)/ over the whole file. A post-verify gate takes its
// before-snapshot in a CREATE TEMP TABLE and drops it at the end, so the guard refused 15 of this
// repo's migrations — 13 of them wrongly, including CC_0081..CC_0084. This script exists so nobody
// pastes a migration body through another channel; refusing a correct file is the same failure with
// extra steps, and it is what happened on 2026-09-09.
//
// The line it now draws is TEMP vs REAL: a DROP TABLE is allowed only when every name is
// unqualified and the file creates it as a TEMP table. DROP SCHEMA/DATABASE is never allowed.
// Measured against the corpus, that refuses exactly 1818 and 1819 — the two that drop
// app_auth.sessions and app_auth.users. See scripts/lib/migration-file-guards.mjs.
const unsafe = unsafeDropTargets(raw);
if (unsafe.length) {
  console.error(`refusing: ${file} drops ${unsafe.length} object(s) that are not its own temp tables`);
  for (const u of unsafe) console.error(`  DROP ${u.kind} ${u.target} — ${u.reason}`);
  process.exit(2);
}

const url = process.env.DATABASE_URL;
if (!url) { console.error('refusing: DATABASE_URL is not set (backend/.env)'); process.exit(2); }
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });
const client = await pool.connect();

let notices = [];
client.on('notice', (n) => notices.push(n.message));
try {
  await client.query('BEGIN');
  const res = await client.query(sql);
  const counts = (Array.isArray(res) ? res : [res])
    .map((r, i) => (r.rowCount != null ? `stmt${i}:${r.command}=${r.rowCount}` : null))
    .filter(Boolean).join('  ');
  await client.query('COMMIT');
  console.log(`APPLIED — ${file}`);
  console.log(`  ${counts}`);
  for (const n of notices) console.log(`  NOTICE: ${n}`);
} catch (e) {
  await client.query('ROLLBACK');
  console.error(`FAILED — ${file}\n  ${e.message}\n  ROLLED BACK, prod unchanged.`);
  process.exitCode = 1;
} finally {
  client.release();
  await pool.end();
}
