/**
 * topic-stage5-prefill.ts — Stage 5 step 2: findings from roll calls already in the source store (no database).
 *
 *   npm run topic:stage5-prefill --prefix backend -- --topic <key> --research <abs topic folder>
 *        --subjects <abs json> [--store <abs store root>] [--dry-run] [--from-table] [--units state:mo,federal]
 *
 * Reads `<research>/stage0/gates.tsv` (the votes the census reviewed) and `<research>/stage5/roster.tsv`, and
 * the store's instruments. `--subjects` maps each instrument id to its subject tags in plain words
 * (`{ "IN-SB-483-2011": ["voter ID at the polls"] }`); an instrument without one is refused. Writes one
 * findings file per person into the store (merging, so a re-run adds nothing new) and, in
 * `<research>/stage5/prefill/`, `unmatched.json` (members with no politician id, for census:identity) and
 * `skipped.json` (census votes it could not find in the store). `--dry-run` writes nothing and prints the counts.
 * `--from-table` also reads the roster's federal roll calls from essentials.legislative_votes (read only), takes
 * findings from the table, and checks the hand lists against it. It always writes `prefill/table-crosscheck.json`
 * (unless `--dry-run`); on any disagreement it prints each one, writes no findings and exits 1.
 * `--units` writes findings only for roster people in those units (`federal`, `state:xx`, `<level>:xx`). Without it
 * every roster person with a vote on file is merged again, which rewrote other states' files in WI, AZ and GA, each
 * reverted by hand (process-efficiency review 2026-11-12, change 7).
 */
import 'dotenv/config';
import { mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, isAbsolute, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { CliFlagError, flag as readFlag, hasFlag } from './lib/cliEnv.js';
import { InstrumentSchema, upsertFindings, type Instrument } from './lib/sourceStore.js';
import { parseRosterTsv } from './lib/stage5Roster.js';
import { parseGatesTsv, prefillFindings } from './lib/stage5Prefill.js';
import { instrumentBill, type TableRollCall } from './lib/federalTableVotes.js';
import { keepBioguideIds, readTableRollCalls } from './lib/federalTableRead.js';

const here = dirname(fileURLToPath(import.meta.url));
const flag = (name: string) => readFlag(process.argv, name);

function walk(dir: string): string[] {
  return readdirSync(dir).flatMap((n) => {
    const p = join(dir, n);
    return statSync(p).isDirectory() ? walk(p) : n.endsWith('.json') ? [p] : [];
  });
}

async function main(): Promise<number> {
  const topic = flag('--topic');
  const research = flag('--research');
  const subjectsFile = flag('--subjects');
  const store = flag('--store') ?? join(here, '..', 'data', 'source-store');
  const dry = hasFlag(process.argv, '--dry-run');
  const fromTable = hasFlag(process.argv, '--from-table');
  if (!topic || !research || !subjectsFile) throw new Error('usage: topic-stage5-prefill --topic <key> --research <abs dir> --subjects <abs json> [--store <abs dir>] [--dry-run] [--from-table]');
  for (const [name, p] of [['--research', research], ['--subjects', subjectsFile], ['--store', store]] as const) {
    if (!isAbsolute(p)) throw new Error(`${name} must be an absolute path (npm runs this from backend/): ${p}`);
  }

  const gates = parseGatesTsv(readFileSync(join(research, 'stage0', 'gates.tsv'), 'utf8'));
  const roster = parseRosterTsv(readFileSync(join(research, 'stage5', 'roster.tsv'), 'utf8'));
  const subjects = JSON.parse(readFileSync(subjectsFile, 'utf8')) as Record<string, string[]>;
  const wanted = new Set(gates.map((g) => g.instrument_id));
  const instruments: Instrument[] = walk(join(store, 'instruments'))
    .map((f) => InstrumentSchema.parse(JSON.parse(readFileSync(f, 'utf8'))))
    .filter((i) => wanted.has(i.id));

  let table: TableRollCall[] | undefined;
  if (fromTable) {
    const bills = [...new Map(instruments.map((i) => instrumentBill(i.id)).filter((b) => b !== null).map((b) => [`${b.congress}|${b.bill_number}`, b])).values()];
    if (bills.length === 0) {
      console.log('table: no US- instruments in gates.tsv, so the table read is skipped');
    } else {
      const { pool } = await import('../src/lib/db.js');
      try {
        const rosterIds = [...new Set(roster.map((r) => r.politician_id))];
        const pids = await keepBioguideIds(pool, rosterIds);
        console.log(`table: ${pids.length} of ${rosterIds.length} roster ids have a bioguide id; reading those`);
        table = await readTableRollCalls(pool, pids, bills);
      } finally {
        await pool.end();
      }
    }
  }
  const all = prefillFindings(instruments, gates, roster, topic, subjects, table);
  const { unmatched, skipped, crosscheck } = all;
  const unitsFlag = flag('--units');
  const units = unitsFlag ? new Set(unitsFlag.split(',').map((u) => u.trim().toLowerCase()).filter(Boolean)) : null;
  const unitOf = new Map(roster.map((r) => [r.politician_id, r.level === 'federal' ? 'federal' : `${r.level}:${(r.state ?? '').toLowerCase()}`]));
  const inUnit = (pid: string) => !units || units.has(unitOf.get(pid) ?? '');
  const findings = all.findings.filter((pf) => inUnit(pf.politician_id));
  if (units) console.log(`--units ${[...units].join(',')}: writing ${findings.length} of ${all.findings.length} people with a vote on file`);
  const out = join(research, 'stage5', 'prefill');
  if (table && !dry) {
    mkdirSync(out, { recursive: true });
    writeFileSync(join(out, 'table-crosscheck.json'), JSON.stringify(crosscheck, null, 2) + '\n');
  }
  if (table && crosscheck.disagree.length > 0) {
    console.error(`table: ${crosscheck.disagree.length} DISAGREEMENTS between the hand lists and the table. No findings written.`);
    for (const d of crosscheck.disagree) console.error(`  ${d.instrument_id} ${d.date} "${d.motion}" politician ${d.politician_id}: hand ${d.hand}, table ${d.table ?? 'no act'}`);
    return 1;
  }
  const level = new Map(roster.map((r) => [r.politician_id, r.level]));
  const perLevel: Record<string, number> = {};
  for (const pf of findings) perLevel[level.get(pf.politician_id)!] = (perLevel[level.get(pf.politician_id)!] ?? 0) + 1;

  let created = 0;
  if (!dry) {
    for (const pf of findings) if (upsertFindings(store, pf) === 'created') created++;
    mkdirSync(out, { recursive: true });
    writeFileSync(join(out, 'unmatched.json'), JSON.stringify(unmatched, null, 2) + '\n');
    writeFileSync(join(out, 'skipped.json'), JSON.stringify(skipped, null, 2) + '\n');
  }
  console.log(`topic ${topic}${dry ? ' (dry run, nothing written)' : ''}`);
  console.log(`instruments read: ${instruments.length} of ${wanted.size} in gates.tsv`);
  console.log(`roster people with a vote on file: ${findings.length} (${Object.entries(perLevel).map(([k, n]) => `${k} ${n}`).join(', ') || 'none'}); findings: ${findings.reduce((n, p) => n + p.findings.length, 0)}`);
  if (!dry) console.log(`findings files created: ${created}, merged: ${findings.length - created}`);
  console.log(`unmatched member votes (for census:identity): ${unmatched.length}`);
  console.log(`census votes not found in the store: ${skipped.length}`);
  if (table) {
    console.log(`table: matched ${crosscheck.matched} roll calls, ${crosscheck.unmatchedRollCalls.length} not matched; findings from table ${crosscheck.tableOnly}, hand only ${crosscheck.handOnly.length}, disagree ${crosscheck.disagree.length}`);
    for (const m of crosscheck.unmatchedRollCalls) console.log(`  not matched: ${m.instrument_id} ${m.vote_date} "${m.motion}" (${m.reason})`);
  }
  return 0;
}

try {
  process.exitCode = await main();
} catch (e) {
  console.error(e instanceof CliFlagError ? e.message : e);
  process.exitCode = 1;
}
