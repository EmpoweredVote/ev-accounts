/**
 * import-pilot-sources.ts — fill the source store from finished pilot folders.
 *
 * Usage: npx tsx scripts/import-pilot-sources.ts --research <root> [--dry-run] [--root <store dir>]
 *
 * Looks in <root> and one level below it for folders an adapter recognises (see lib/pilotImport.ts),
 * reads them and merges the records into the store (default backend/data/source-store). Safe to
 * re-run: instruments, people and jurisdictions merge by the store's rules and a dead end already in
 * dead-ends.jsonl is not appended twice. --dry-run prints the counts and writes nothing.
 */
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { flag, hasFlag } from './lib/cliEnv.js';
import { ADAPTERS, importNotes, resetImportNotes, type PilotOutput } from './lib/pilotImport.js';
import { appendDeadEnd, storePaths, upsertInstrument, upsertJurisdiction, upsertPerson } from './lib/sourceStore.js';

const here = dirname(fileURLToPath(import.meta.url));
const argv = process.argv.slice(2);
let researchArg: string | undefined;
let rootArg: string | undefined;
try {
  researchArg = flag(argv, '--research');
  rootArg = flag(argv, '--root');
} catch (e) {
  console.error(`ERROR: ${(e as Error).message}`);
  process.exit(2);
}
if (!researchArg) {
  console.error('Usage: import-pilot-sources.ts --research <root> [--dry-run] [--root <store dir>]');
  process.exit(2);
}
const research = resolve(researchArg.replace(/^~/, process.env.HOME ?? '~'));
const storeRoot = rootArg ? resolve(rootArg) : join(here, '..', 'data', 'source-store');
const dryRun = hasFlag(argv, '--dry-run');

const subdirs = (d: string) => (existsSync(d) ? readdirSync(d).map((n) => join(d, n)).filter((p) => statSync(p).isDirectory()) : []);
const candidates = [research, ...subdirs(research).flatMap((d) => [d, ...subdirs(d)])];

resetImportNotes();
const total = { instruments: 0, people: 0, jurisdictions: 0, deadEnds: 0, deadEndsAlreadyThere: 0 };
const lines: string[] = [];
const seenDirs = new Set<string>();
const existingDead = new Set(
  existsSync(storePaths(storeRoot).deadEnds) ? readFileSync(storePaths(storeRoot).deadEnds, 'utf8').split('\n').filter(Boolean) : [],
);

for (const adapter of ADAPTERS) {
  for (const dir of candidates) {
    if (seenDirs.has(`${adapter.name}|${dir}`) || !adapter.matches(dir)) continue;
    seenDirs.add(`${adapter.name}|${dir}`);
    const out: PilotOutput = adapter.read(dir, research);
    let dead = 0;
    if (!dryRun) {
      for (const i of out.instruments) upsertInstrument(storeRoot, i);
      for (const p of out.people) upsertPerson(storeRoot, p);
      for (const j of out.jurisdictions) upsertJurisdiction(storeRoot, j);
    }
    for (const d of out.deadEnds) {
      const line = JSON.stringify(d);
      if (existingDead.has(line)) { total.deadEndsAlreadyThere++; continue; }
      existingDead.add(line);
      dead++;
      if (!dryRun) appendDeadEnd(storeRoot, d);
    }
    total.instruments += out.instruments.length;
    total.people += out.people.length;
    total.jurisdictions += out.jurisdictions.length;
    total.deadEnds += dead;
    const votes = out.instruments.reduce((n, i) => n + i.votes.length, 0);
    lines.push(`${adapter.name} (${dir}): ${out.instruments.length} instruments (${votes} votes), ${out.people.length} people, ${out.jurisdictions.length} jurisdictions, ${dead} dead ends`);
  }
}

console.log(dryRun ? 'DRY RUN, nothing written' : `Wrote to ${storeRoot}`);
for (const l of lines) console.log(l);
console.log(`Total: ${total.instruments} instruments, ${total.people} people, ${total.jurisdictions} jurisdictions, ${total.deadEnds} dead ends (${total.deadEndsAlreadyThere} already in the store)`);
const built = [...new Set(importNotes.constructedIds)];
const noRuling = [...new Set(importNotes.noRuling)];
if (built.length) console.log(`Ids built (${built.length}):\n  ${built.join('\n  ')}`);
if (noRuling.length) console.log(`No single-subject ruling written (${noRuling.length}):\n  ${noRuling.join('\n  ')}`);
const unknownMotions = [...new Set(importNotes.unknownMotions)];
if (unknownMotions.length) console.log(`Motion unknown (${unknownMotions.length}):\n  ${unknownMotions.join('\n  ')}`);
if (importNotes.skipped.length) console.log(`Skipped (${importNotes.skipped.length}):\n  ${importNotes.skipped.join('\n  ')}`);
if (!lines.length) { console.error('No pilot folder recognised under ' + research); process.exit(1); }
