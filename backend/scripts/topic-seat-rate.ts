/**
 * topic-seat-rate.ts — seat-rate report for one compass topic (read-only).
 *
 *   npm run topic:seat-rate --prefix backend -- --topic <key> [--season open|draft|<uuid>] [--research <stage0a dir>] [--json]
 *
 * Default: counts live `inform.politician_answers` for the season. With `--research <dir>` the rows
 * come from `<dir>/rows.tsv` instead (a planned or pre-write reading) and the report adds the
 * affirmative rate. Never writes.
 */
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pool } from '../src/lib/db.js';
import { resolveSeasonTarget, seasonSpecFromArgv, SeasonTargetError } from './lib/seasonTarget.js';
import { loadDbRows, parseRowsTsv, summarise, formatReport } from './lib/seatRate.js';

function flag(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  if (i === -1) return undefined;
  const v = process.argv[i + 1];
  if (!v || v.startsWith('--')) throw new Error(`${name} needs a value`);
  return v;
}

async function main() {
  const topic = flag('--topic');
  if (!topic) throw new Error('usage: topic-seat-rate --topic <key> [--season open|draft|<uuid>] [--research <dir>] [--json]');
  const research = flag('--research');
  const json = process.argv.includes('--json');
  const q = (sql: string, params?: unknown[]) => pool.query(sql, params as any[]);

  let report;
  let header: string;
  if (research) {
    const file = join(research, 'rows.tsv');
    report = summarise(parseRowsTsv(readFileSync(file, 'utf8'), file));
    header = `topic ${topic} — research rows from ${file}`;
  } else {
    const season = await resolveSeasonTarget(seasonSpecFromArgv(process.argv), q);
    const skipped: string[] = [];
    const rows = await loadDbRows(q, topic, season.id, (id) => skipped.push(id));
    // The database path carries no record kind, so the affirmative rate is left out.
    report = summarise(rows.map(({ record_kind: _k, ...r }) => r));
    header = `topic ${topic} — season ${season.number} (${season.status})`
      + (skipped.length ? `; ${skipped.length} answer(s) skipped: office level unknown` : '');
  }
  console.log(json ? JSON.stringify({ header, ...report }, null, 2) : `${header}\n\n${formatReport(report)}`);
}

main()
  .catch((e) => {
    console.error(e instanceof SeasonTargetError ? e.message : e);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
