/**
 * source-store.ts — CLI for the season-topic-prep source store.
 *
 * Usage: npx tsx scripts/source-store.ts validate [--root <dir>]
 *
 * Checks every file in the store against its schema. Exits 1 and prints each problem if any
 * file is broken, so a bad hand edit is caught before it is committed.
 */
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { flag } from './lib/cliEnv.js';
import { validateStore } from './lib/sourceStore.js';

const here = dirname(fileURLToPath(import.meta.url));
const argv = process.argv.slice(2);
const cmd = argv[0];
let rootArg: string | undefined;
try {
  rootArg = flag(argv, '--root');
} catch (e) {
  console.error(`ERROR: ${(e as Error).message}`);
  process.exit(2);
}
const root = rootArg ? resolve(rootArg) : join(here, '..', 'data', 'source-store');

if (cmd !== 'validate') {
  console.error('Usage: source-store.ts validate [--root <dir>]');
  process.exit(2);
}
const problems = validateStore(root);
if (problems.length) {
  for (const p of problems) console.error(`${p.file}: ${p.error}`);
  console.error(`${problems.length} problem(s) in ${root}`);
  process.exit(1);
}
console.log(`source store OK (${root})`);
