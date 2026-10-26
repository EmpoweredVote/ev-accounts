/**
 * topic-stage5-prefill.ts — Stage 5 step 2: findings from roll calls already in the source store (no database).
 *
 *   npm run topic:stage5-prefill --prefix backend -- --topic <key> --research <abs topic folder>
 *        --subjects <abs json> [--store <abs store root>] [--dry-run]
 *
 * Reads `<research>/stage0/gates.tsv` (the votes the census reviewed) and `<research>/stage5/roster.tsv`, and
 * the store's instruments. `--subjects` maps each instrument id to its subject tags in plain words
 * (`{ "IN-SB-483-2011": ["voter ID at the polls"] }`); an instrument without one is refused. Writes one
 * findings file per person into the store (merging, so a re-run adds nothing new) and, in
 * `<research>/stage5/prefill/`, `unmatched.json` (members with no politician id, for census:identity) and
 * `skipped.json` (census votes it could not find in the store). `--dry-run` writes nothing and prints the counts.
 */
import { mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, isAbsolute, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { CliFlagError, flag as readFlag, hasFlag } from './lib/cliEnv.js';
import { InstrumentSchema, upsertFindings, type Instrument } from './lib/sourceStore.js';
import { parseRosterTsv } from './lib/stage5Roster.js';
import { parseGatesTsv, prefillFindings } from './lib/stage5Prefill.js';

const here = dirname(fileURLToPath(import.meta.url));
const flag = (name: string) => readFlag(process.argv, name);

function walk(dir: string): string[] {
  return readdirSync(dir).flatMap((n) => {
    const p = join(dir, n);
    return statSync(p).isDirectory() ? walk(p) : n.endsWith('.json') ? [p] : [];
  });
}

function main(): number {
  const topic = flag('--topic');
  const research = flag('--research');
  const subjectsFile = flag('--subjects');
  const store = flag('--store') ?? join(here, '..', 'data', 'source-store');
  const dry = hasFlag(process.argv, '--dry-run');
  if (!topic || !research || !subjectsFile) throw new Error('usage: topic-stage5-prefill --topic <key> --research <abs dir> --subjects <abs json> [--store <abs dir>] [--dry-run]');
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

  const { findings, unmatched, skipped } = prefillFindings(instruments, gates, roster, topic, subjects);
  const level = new Map(roster.map((r) => [r.politician_id, r.level]));
  const perLevel: Record<string, number> = {};
  for (const pf of findings) perLevel[level.get(pf.politician_id)!] = (perLevel[level.get(pf.politician_id)!] ?? 0) + 1;

  let created = 0;
  if (!dry) {
    for (const pf of findings) if (upsertFindings(store, pf) === 'created') created++;
    const out = join(research, 'stage5', 'prefill');
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
  return 0;
}

try {
  process.exitCode = main();
} catch (e) {
  console.error(e instanceof CliFlagError ? e.message : e);
  process.exitCode = 1;
}
