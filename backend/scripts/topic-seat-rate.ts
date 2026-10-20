/**
 * topic-seat-rate.ts — seat-rate report for one compass topic (read-only).
 *
 *   npm run topic:seat-rate --prefix backend -- --topic <key> [--season open|draft|<uuid>]
 *        [--research <dir> | --research-only <dir>] [--json]
 *
 * Default: counts live `inform.politician_answers` for the season.
 * `--research <dir>`: the database rows stay the base; `<dir>/rows.tsv` supplies blank_class,
 * record_kind and gate by politician_id, and the report adds the affirmative rate. Rows only in the
 * file are counted in the header.
 * `--research-only <dir>`: the old behaviour — rows come from rows.tsv alone (frozen test sets).
 * Exit 2 on an unknown topic key. Never writes.
 *
 * Opens its own pg Pool from DATABASE_URL (backend/.env, or the main checkout's .env in a worktree);
 * it does not import db.js, which demands every server variable at import time.
 */
import { readFileSync, existsSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import dotenv from 'dotenv';
import pg from 'pg';
import { resolveSeasonTarget, seasonSpecFromArgv, SeasonTargetError } from './lib/seasonTarget.js';
import { loadDbRows, parseRowsTsv, summarise, formatReport, mergeResearch, topicExists } from './lib/seatRate.js';

const backendDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
dotenv.config({ path: join(backendDir, '.env'), quiet: true });
if (!process.env.DATABASE_URL) {
  // A linked worktree has no .env of its own: borrow the main checkout's (variables already set win).
  try {
    const common = execFileSync('git', ['rev-parse', '--path-format=absolute', '--git-common-dir'],
      { cwd: backendDir, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
    const mainEnv = join(dirname(common), 'backend', '.env');
    if (existsSync(mainEnv)) dotenv.config({ path: mainEnv, quiet: true });
  } catch { /* no git: fall through to the missing-variable message */ }
}

function flag(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  if (i === -1) return undefined;
  const v = process.argv[i + 1];
  if (!v || v.startsWith('--')) throw new Error(`${name} needs a value`);
  return v;
}

async function main(): Promise<number> {
  const topic = flag('--topic');
  if (!topic) throw new Error('usage: topic-seat-rate --topic <key> [--season open|draft|<uuid>] [--research <dir> | --research-only <dir>] [--json]');
  const research = flag('--research');
  const researchOnly = flag('--research-only');
  if (research && researchOnly) throw new Error('--research and --research-only cannot be combined');
  const json = process.argv.includes('--json');
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is not set (expected in backend/.env)');
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
  const q = (sql: string, params?: unknown[]) => pool.query(sql, params as any[]);
  try {
    if (!(await topicExists(q, topic))) { console.error(`unknown topic: ${topic}`); return 2; }

    let report;
    let header: string;
    if (researchOnly) {
      const file = join(researchOnly, 'rows.tsv');
      report = summarise(parseRowsTsv(readFileSync(file, 'utf8'), file));
      header = `topic ${topic} — research rows only, from ${file}`;
    } else {
      const season = await resolveSeasonTarget(seasonSpecFromArgv(process.argv), q);
      const noOffice: string[] = [];
      const unknownLevel: string[] = [];
      const dbRows = await loadDbRows(q, topic, season.id, (id, why) => (why === 'no-office' ? noOffice : unknownLevel).push(id));
      let rows: Array<Omit<(typeof dbRows)[number], 'record_kind'> & { record_kind?: (typeof dbRows)[number]['record_kind'] }> = dbRows;
      const notes: string[] = [];
      if (research) {
        const file = join(research, 'rows.tsv');
        const m = mergeResearch(dbRows, parseRowsTsv(readFileSync(file, 'utf8'), file));
        rows = m.rows;
        notes.push(`in research file only: ${m.researchOnly}`);
      } else {
        // The database path carries no record kind, so the affirmative rate is left out.
        rows = dbRows.map(({ record_kind: _k, ...r }) => r);
      }
      if (noOffice.length) notes.push(`no current office: ${noOffice.length}`);
      if (unknownLevel.length) notes.push(`office level unknown: ${unknownLevel.length}`);
      report = summarise(rows as any);
      header = `topic ${topic} — season ${season.number} (${season.status})` + (notes.length ? `; ${notes.join('; ')}` : '');
    }
    console.log(json ? JSON.stringify({ header, ...report }, null, 2) : `${header}\n\n${formatReport(report)}`);
    return 0;
  } finally {
    await pool.end();
  }
}

main()
  .then((code) => { process.exitCode = code; })
  .catch((e) => {
    console.error(e instanceof SeasonTargetError ? e.message : e);
    process.exitCode = 1;
  });
