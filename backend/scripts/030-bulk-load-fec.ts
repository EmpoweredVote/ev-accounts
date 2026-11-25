/**
 * 030-bulk-load-fec.ts — CLI for the FEC bulk-data loader (quick-031).
 *
 * Loads a cycle's itemized individual contributions from FEC's free bulk downloads
 * (no API key, no rate limit) into transparent_motivations.contributions, deduped
 * against API-ingested rows via SUB_ID.
 *
 * Usage (run as a Render one-off Job, or locally):
 *   tsx scripts/030-bulk-load-fec.ts <cycle> [flags]
 *     --dry                 parse + filter + count, write nothing (safe validation)
 *     --sample N            print first N raw ccl+indiv lines (verify column positions)
 *     --committees C1,C2    restrict to these committee IDs (for a scoped dry/test load)
 *     --limit N             stop after N matched rows (bounded test)
 *     --all-committees      include all authorized committees (default: principal only)
 *     --new-only            only sources with no successful FEC run for this cycle yet
 *                           (first-time backfills); leaves sources the burst keeps current alone
 *     --insert-only         write only rows whose SUB_ID is not stored; never rewrite an existing row
 *                           (use this to fill gaps in sources that already hold most of their rows)
 *     --sources ID,ID|@file restrict to these politician_source ids (@file: one id per line, or a JSON array)
 *
 * A load cut short by --limit writes no run rows: a run row moves the API cursor to the file date.
 * A complete real load also clears each finished source's fec_fetch_checkpoints (CA_0410).
 *
 * Examples:
 *   tsx scripts/030-bulk-load-fec.ts 2022 --dry --sample 3            # verify format/columns, no writes
 *   tsx scripts/030-bulk-load-fec.ts 2022 --dry --committees C00736876 # count Warnock's 2022 rows, no writes
 *   tsx scripts/030-bulk-load-fec.ts 2022 --committees C00736876 --limit 20000  # small real load
 *   tsx scripts/030-bulk-load-fec.ts 2022                             # full-cycle real load
 *   tsx scripts/030-bulk-load-fec.ts 2026 --new-only --dry            # count new people's rows, no writes
 *   tsx scripts/030-bulk-load-fec.ts 2026 --insert-only --sources @ids.txt --dry  # count the missing rows, no writes
 */

import 'dotenv/config';
import fs from 'node:fs';
import { pool } from '../src/lib/db.js';
import { loadFecBulkCycle, type BulkLoadOptions } from '../src/lib/adapters/fecBulkLoader.js';

const cycle = process.argv[2];
if (!cycle || !/^\d{4}$/.test(cycle)) {
  console.error('usage: tsx scripts/030-bulk-load-fec.ts <cycle> [--dry] [--sample N] [--committees C1,C2] [--limit N] [--all-committees] [--new-only] [--insert-only] [--sources ID,ID|@file]');
  process.exit(1);
}

const argv = process.argv.slice(3);
const flagVal = (name: string): string | undefined => {
  const i = argv.indexOf(name);
  return i >= 0 ? argv[i + 1] : undefined;
};

const readSources = (v: string | undefined): string[] | undefined => {
  if (!v) return undefined;
  if (!v.startsWith('@')) return v.split(',').map((s) => s.trim()).filter(Boolean);
  const text = fs.readFileSync(v.slice(1), 'utf8').trim();
  const list: unknown = text.startsWith('[') ? JSON.parse(text) : text.split(/\s+/);
  return (list as unknown[]).map(String).map((s) => s.trim()).filter(Boolean);
};

const opts: BulkLoadOptions = {
  dry: argv.includes('--dry'),
  committees: flagVal('--committees')?.split(',').map((s) => s.trim()).filter(Boolean),
  limit: flagVal('--limit') ? parseInt(flagVal('--limit')!, 10) : undefined,
  sample: flagVal('--sample') ? parseInt(flagVal('--sample')!, 10) : undefined,
  designation: argv.includes('--all-committees') ? 'all' : 'P',
  newOnly: argv.includes('--new-only'),
  insertOnly: argv.includes('--insert-only'),
  sources: readSources(flagVal('--sources')),
};

async function main(): Promise<void> {
  if (!process.env.DATABASE_URL) { console.error('ERROR: DATABASE_URL not set'); process.exit(1); }
  await loadFecBulkCycle(cycle, opts);
  await pool.end();
  process.exit(0);
}

main().catch((err) => { console.error('[030-bulk] Fatal:', err); process.exit(1); });
