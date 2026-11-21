/**
 * results-scope-data.ts — the two read-only database reads results_scope.py needs (card A, step A1; any state).
 *
 *   npx tsx scripts/stage5/results-scope-data.ts --state XX --state-name "<Name>" --roster <fresh roster.tsv>
 *        --out <stage5>/<xx>/results [--year 2026]
 *
 * Writes <out>/db-cands.json: every candidate row of the state's elections dated in --year (election, race, office,
 * position, district type, politician id, name, result). And <out>/db-offices.json: office -> district for every
 * office on the state's roster rows and every race office. Prints the elections it found.
 *
 * This was db_cands_<xx>.cjs and db_offices_<xx>.cjs, copied from the state before in every state. Read-only: both
 * queries run inside BEGIN READ ONLY and the transaction is rolled back. Party is never read.
 */
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { flag as readFlag, loadBackendEnv } from '../lib/cliEnv.js';

loadBackendEnv(resolve(dirname(fileURLToPath(import.meta.url)), '..', '..'));
const flag = (name: string) => readFlag(process.argv, name);
const usage = 'results-scope-data.ts --state XX --state-name "<Name>" --roster <roster.tsv> --out <dir> [--year 2026]';
const st = (flag('--state') ?? '').toUpperCase(); const name = flag('--state-name'); const roster = flag('--roster'); const out = flag('--out');
const year = Number(flag('--year') ?? new Date().getUTCFullYear());
if (!/^[A-Z]{2}$/.test(st) || !name || !roster || !out || !Number.isInteger(year)) { console.error(`usage: ${usage}`); process.exit(2); }
if (!process.env.DATABASE_URL) { console.error('DATABASE_URL is not set (expected in backend/.env)'); process.exit(2); }

const c = new pg.Client({ connectionString: process.env.DATABASE_URL });
await c.connect();
try {
  await c.query('BEGIN READ ONLY');
  const el = await c.query(
    `SELECT e.id, e.name, e.election_date::text d FROM essentials.elections e
      WHERE e.election_date >= $1::date AND e.election_date < $2::date AND (e.name ILIKE $3 OR e.name ILIKE $4) ORDER BY 3`,
    [`${year}-01-01`, `${year + 1}-01-01`, `${st} %`, `%${name}%`]);
  const cands = await c.query(
    `SELECT e.name election, r.id::text race_id, r.office_id::text office_id, r.position_name, d.district_type,
            rc.politician_id::text politician_id, rc.full_name, rc.result, rc.result_certainty, rc.candidate_status
       FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id JOIN essentials.elections e ON e.id = r.election_id
       LEFT JOIN essentials.offices o ON o.id = r.office_id LEFT JOIN essentials.districts d ON d.id = o.district_id
      WHERE e.id = ANY($1::uuid[]) ORDER BY 1, 4, 7`, [el.rows.map((x) => x.id)]);
  const ids = new Set<string>();
  for (const line of readFileSync(roster, 'utf8').split('\n').slice(1)) { const f = line.split('\t'); if (f[4] === st && f[2]) ids.add(f[2]); }
  for (const row of cands.rows) if (row.office_id) ids.add(row.office_id);
  const offices = await c.query(
    `SELECT o.id::text office_id, o.district_id::text district_id, d.district_type, d.label FROM essentials.offices o
       LEFT JOIN essentials.districts d ON d.id = o.district_id WHERE o.id = ANY($1::uuid[])`, [[...ids]]);
  mkdirSync(out, { recursive: true });
  writeFileSync(join(out, 'db-cands.json'), JSON.stringify(cands.rows, null, 1));
  writeFileSync(join(out, 'db-offices.json'), JSON.stringify(offices.rows, null, 1));
  console.log(`${st} ${year}: ${el.rows.length} election(s), ${cands.rows.length} candidate row(s), ${offices.rows.length} office(s) -> ${out}`);
  for (const e of el.rows) console.log(`  ${e.d} ${e.name}: ${cands.rows.filter((r) => r.election === e.name).length} candidate row(s)`);
  if (!cands.rows.length) { console.log('NO VERDICT: no candidate row for this state and year (is --state-name the name the elections carry?)'); process.exitCode = 2; }
} finally {
  await c.query('ROLLBACK').catch(() => undefined);
  await c.end();
}
