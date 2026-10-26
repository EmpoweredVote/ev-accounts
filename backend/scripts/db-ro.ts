/**
 * db-ro.ts — run one SQL file against the database, read-only.
 *
 *   npm run db:ro --prefix backend -- --file <absolute .sql> [--json]
 *
 * Why: a runner or a blind drafter sometimes needs one SELECT, and handing it a writable
 * connection is the wrong tool. The file runs inside `BEGIN READ ONLY` and is always rolled back
 * (lib/readOnlyQuery.ts), so Postgres refuses any write and nothing the file does survives. A file
 * that ends the transaction itself (COMMIT, ROLLBACK, BEGIN, END ...) is refused before it is sent.
 *
 * Prints the last statement's rows as an aligned table, or as JSON with `--json`. `--file` must be
 * absolute, because npm runs this from backend/. Exit 1 on any error, with the message only; the
 * connection string is never printed.
 *
 * Opens its own pg Pool from DATABASE_URL, loaded by lib/cliEnv.ts (backend/.env, or the main
 * checkout's .env in a worktree); it does not import db.js. A flag with no value is an error.
 */
import { readFileSync } from 'node:fs';
import { isAbsolute, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { flag as readFlag, hasFlag, loadBackendEnv } from './lib/cliEnv.js';
import { formatTable, runReadOnly } from './lib/readOnlyQuery.js';

const backendDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
loadBackendEnv(backendDir);
const argv = process.argv;

async function main(): Promise<number> {
  const file = readFlag(argv, '--file');
  if (!file) throw new Error('usage: db-ro --file <absolute .sql> [--json]');
  if (!isAbsolute(file)) throw new Error(`--file must be an absolute path (npm runs this from backend/): ${file}`);
  const sql = readFileSync(file, 'utf8');
  if (!sql.trim()) throw new Error(`--file ${file} is empty`);
  const json = hasFlag(argv, '--json');
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is not set (expected in backend/.env)');
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
  const client = await pool.connect();
  try {
    const { fields, rows } = await runReadOnly(client as any, sql);
    console.log(json ? JSON.stringify(rows, null, 2) : formatTable(fields, rows));
    return 0;
  } finally {
    client.release();
    await pool.end();
  }
}

main()
  .then((code) => { process.exitCode = code; })
  .catch((e) => {
    console.error(e instanceof Error ? e.message : String(e));
    process.exitCode = 1;
  });
