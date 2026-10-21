/**
 * topic-seat-rate.ts — seat-rate report for one compass topic (read-only).
 *
 *   npm run topic:seat-rate --prefix backend -- --topic <key> [--season open|draft|<uuid>]
 *        [--research <dir> | --research-only <dir>] [--rows-out <absolute file>] [--json]
 *
 * Default: counts live `inform.politician_answers` for the season.
 * `--research <dir>`: the database rows stay the base; `<dir>/rows.tsv` supplies blank_class,
 * record_kind and gate by politician_id, and the report adds the affirmative rate. Rows only in the
 * file are counted in the header.
 * `--research-only <dir>`: the old behaviour — rows come from rows.tsv alone (frozen test sets).
 * `--rows-out <absolute file>`: also write a starter rows.tsv for Stage 0a (formatRowsTsv): one row per
 * database answer, record_kind `none`, gate empty. Refuses an existing file, so a classified rows.tsv is
 * never overwritten. Not with --research-only.
 * Exit 2 on an unknown topic key. Never writes.
 *
 * Opens its own pg Pool from DATABASE_URL, loaded by lib/cliEnv.ts (backend/.env, or the main
 * checkout's .env in a worktree); it does not import db.js. A flag with no value is an error.
 */
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { isAbsolute, join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { CliFlagError, flag as readFlag, hasFlag, loadBackendEnv } from './lib/cliEnv.js';
import { resolveSeasonTarget, seasonSpecFromArgv, SeasonTargetError } from './lib/seasonTarget.js';
import { formatRowsTsv, loadDbRows, parseRowsTsv, summarise, formatReport, mergeResearch, topicExists } from './lib/seatRate.js';

const backendDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
loadBackendEnv(backendDir);
const argv = process.argv;
const flag = (name: string) => readFlag(argv, name);

async function main(): Promise<number> {
  const topic = flag('--topic');
  if (!topic) throw new Error('usage: topic-seat-rate --topic <key> [--season open|draft|<uuid>] [--research <dir> | --research-only <dir>] [--rows-out <absolute file>] [--json]');
  const research = flag('--research');
  const researchOnly = flag('--research-only');
  if (research && researchOnly) throw new Error('--research and --research-only cannot be combined');
  const rowsOut = flag('--rows-out');
  if (rowsOut && researchOnly) throw new Error('--rows-out reads the database rows, so it cannot be combined with --research-only');
  if (rowsOut && !isAbsolute(rowsOut)) throw new Error(`--rows-out must be an absolute path (npm runs this from backend/): ${rowsOut}`);
  if (rowsOut && existsSync(rowsOut)) throw new Error(`--rows-out ${rowsOut} already exists; refusing to overwrite it`);
  const json = hasFlag(argv, '--json');
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
      if (rowsOut) {
        writeFileSync(rowsOut, formatRowsTsv(dbRows), { flag: 'wx' });
        console.error(`wrote ${dbRows.length} starter rows to ${rowsOut}`);
      }
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
    console.error(e instanceof SeasonTargetError || e instanceof CliFlagError ? e.message : e);
    process.exitCode = 1;
  });
