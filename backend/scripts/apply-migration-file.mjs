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
import fs from 'node:fs';
import pg from 'pg';

const file = process.argv[2];
if (!file) { console.error('usage: node scripts/apply-migration-file.mjs <migration.sql>'); process.exit(2); }

const raw = fs.readFileSync(file, 'utf8');
const sql = raw.replace(/^\s*BEGIN\s*;/im, '').replace(/^\s*COMMIT\s*;/im, '');
if (/\bDROP\s+(TABLE|SCHEMA|DATABASE)\b/i.test(sql)) { console.error('refusing: migration contains a DROP TABLE/SCHEMA/DATABASE'); process.exit(2); }

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
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
