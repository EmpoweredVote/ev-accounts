/**
 * topic-stage5-roster.ts — Stage 5 step 1: everyone in scope for one topic (read-only).
 *
 *   npm run topic:stage5-roster --prefix backend -- --topic <key> --out <absolute roster.tsv> [--as-of YYYY-MM-DD]
 *        [--before YYYY-MM-DD]
 *
 * Writes `roster.tsv` (stage5Roster.ROSTER_COLUMNS) and `<name>.gaps.tsv` beside it (active candidates with no
 * politician record, offices with no known level, levels the topic is not asked at), then prints the counts
 * per level, state, scope and leaving. Refuses an existing file. Runs inside BEGIN READ ONLY … ROLLBACK.
 * `--as-of` (default today) is the first election date that still counts as upcoming; `--before` (default
 * 2027-01-01) the first that no longer does, so only this cycle's races count.
 *
 * Opens its own pg Pool from DATABASE_URL, loaded by lib/cliEnv.ts; never prints it.
 */
import { existsSync, writeFileSync } from 'node:fs';
import { isAbsolute, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { CliFlagError, flag as readFlag, loadBackendEnv } from './lib/cliEnv.js';
import { topicExists } from './lib/seatRate.js';
import { formatRosterTsv, loadRoster, rosterCounts, type RosterGap } from './lib/stage5Roster.js';

const backendDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
loadBackendEnv(backendDir);
const flag = (name: string) => readFlag(process.argv, name);

export const gapsPath = (out: string) => out.replace(/(\.tsv)?$/, '.gaps.tsv');

async function main(): Promise<number> {
  const topic = flag('--topic');
  const out = flag('--out');
  const asOf = flag('--as-of');
  const before = flag('--before');
  if (!topic || !out) throw new Error('usage: topic-stage5-roster --topic <key> --out <absolute roster.tsv> [--as-of YYYY-MM-DD]');
  if (!isAbsolute(out)) throw new Error(`--out must be an absolute path (npm runs this from backend/): ${out}`);
  for (const [n, v] of [['--as-of', asOf], ['--before', before]] as const) {
    if (v && !/^\d{4}-\d{2}-\d{2}$/.test(v)) throw new Error(`${n} must be YYYY-MM-DD: ${v}`);
  }
  for (const f of [out, gapsPath(out)]) if (existsSync(f)) throw new Error(`${f} already exists; refusing to overwrite it`);
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is not set (expected in backend/.env)');

  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
  const client = await pool.connect();
  try {
    await client.query('BEGIN READ ONLY');
    const q = (sql: string, params?: unknown[]) => client.query(sql, params as any[]);
    if (!(await topicExists(q, topic))) { console.error(`unknown topic: ${topic}`); return 2; }
    const gaps: RosterGap[] = [];
    const rows = await loadRoster(q, topic, (g) => gaps.push(g), { ...(asOf ? { asOf } : {}), ...(before ? { before } : {}) });
    writeFileSync(out, formatRosterTsv(rows), { flag: 'wx' });
    writeFileSync(gapsPath(out), ['kind\tid\tnote', ...gaps.map((g) => `${g.kind}\t${g.id}\t${g.note.replace(/\s+/g, ' ')}`)].join('\n') + '\n', { flag: 'wx' });

    const c = rosterCounts(rows);
    const gapCounts = gaps.reduce<Record<string, number>>((m, g) => ({ ...m, [g.kind]: (m[g.kind] ?? 0) + 1 }), {});
    console.log(`topic ${topic} — ${rows.length} people in scope (wrote ${out})`);
    console.log(`by level:   ${Object.entries(c.byLevel).filter(([, n]) => n).map(([k, n]) => `${k} ${n}`).join(', ')}`);
    console.log(`by scope:   sitting ${c.byScope.sitting}, candidate ${c.byScope.candidate}, both ${c.byScope.both}`);
    console.log(`leaving:    yes ${c.leaving.yes}, no ${c.leaving.no}, unknown ${c.leaving.unknown}`);
    console.log(`gaps:       ${Object.entries(gapCounts).map(([k, n]) => `${k} ${n}`).join(', ') || 'none'} (see ${gapsPath(out)})`);
    console.log('by state:');
    for (const [s, n] of Object.entries(c.byState).sort(([a], [b]) => a.localeCompare(b))) console.log(`  ${s}\t${n}`);
    return 0;
  } finally {
    await client.query('ROLLBACK').catch(() => undefined);
    client.release();
    await pool.end();
  }
}

main()
  .then((code) => { process.exitCode = code; })
  .catch((e) => {
    console.error(e instanceof CliFlagError ? e.message : e);
    process.exitCode = 1;
  });
