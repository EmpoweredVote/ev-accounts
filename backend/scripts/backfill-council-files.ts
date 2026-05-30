/**
 * backfill-council-files.ts — Enrich all distinct council file numbers from meetings.la_council_votes
 * by calling councilFilesService.enrichCouncilFile() for each one.
 *
 * Usage:
 *   npx tsx scripts/backfill-council-files.ts
 *   npx tsx scripts/backfill-council-files.ts --dry-run
 *   npx tsx scripts/backfill-council-files.ts --limit 10
 *   npx tsx scripts/backfill-council-files.ts --force --concurrency 3
 */
import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { enrichCouncilFile } from '../src/lib/councilFilesService.js';

// ─── CLI args ─────────────────────────────────────────────────────────────────

const args: Record<string, string | boolean> = {};
for (let i = 2; i < process.argv.length; i++) {
  const arg = process.argv[i];
  if (arg.startsWith('--')) {
    const key = arg.slice(2);
    const next = process.argv[i + 1];
    if (next && !next.startsWith('--')) {
      args[key] = next;
      i++;
    } else {
      args[key] = true;
    }
  }
}

const force = args['force'] === true;
const dryRun = args['dry-run'] === true;
const limitArg = args['limit'] ? parseInt(args['limit'] as string, 10) : null;
const CONCURRENCY = args['concurrency'] ? parseInt(args['concurrency'] as string, 10) : 5;

// ─── Main ─────────────────────────────────────────────────────────────────────

const startTime = Date.now();

// Enumerate CFNs from la_council_votes, left-joining council_file_details to
// skip already-enriched rows (unless --force).
const { rows: allRows } = await pool.query<{ council_file_number: string; description: string | null }>(
  `SELECT DISTINCT lv.council_file_number, MIN(lv.agenda_description) AS description
   FROM meetings.la_council_votes lv
   LEFT JOIN meetings.council_file_details cfd
     ON cfd.council_file_number = lv.council_file_number
   WHERE lv.council_file_number IS NOT NULL
     AND (cfd.council_file_number IS NULL OR $1::boolean = true)
   GROUP BY lv.council_file_number
   ORDER BY lv.council_file_number;`,
  [force]
);

// Apply --limit slicing after query
const cfnRows = limitArg !== null ? allRows.slice(0, limitArg) : allRows;

if (dryRun) {
  console.log(`[dry-run] Would enrich ${cfnRows.length} council files (force=${force})`);
  console.log('First 10 CFNs:');
  cfnRows.slice(0, 10).forEach(r => console.log(' -', r.council_file_number, r.description ? `(${r.description.slice(0, 60)})` : ''));
  await pool.end();
  process.exit(0);
}

// ─── Concurrency-controlled worker pool ──────────────────────────────────────

const queue = [...cfnRows];
let done = 0;
let failed = 0;
const total = queue.length;
const firstFiveFailures: string[] = [];

console.log(`Enriching ${total} council files (force=${force}, concurrency=${CONCURRENCY})`);

async function worker() {
  while (queue.length > 0) {
    const row = queue.shift()!;
    try {
      await enrichCouncilFile(row.council_file_number, { description: row.description ?? '' });
      done++;
    } catch (err) {
      failed++;
      const msg = `${row.council_file_number}: ${err instanceof Error ? err.message : String(err)}`;
      if (firstFiveFailures.length < 5) firstFiveFailures.push(msg);
      console.error(`[FAIL] ${msg}`);
    } finally {
      if ((done + failed) % 25 === 0 && (done + failed) > 0) {
        console.log(`progress: ${done + failed}/${total} done (${failed} failed)`);
      }
    }
  }
}

await Promise.all(Array.from({ length: CONCURRENCY }, () => worker()));

// ─── Final summary ────────────────────────────────────────────────────────────

const elapsed = Math.round((Date.now() - startTime) / 1000);
console.log(`Done. enriched=${done}, failed=${failed}, total=${total}, elapsed=${elapsed}s`);
if (firstFiveFailures.length > 0) {
  console.log('First failures:');
  firstFiveFailures.forEach(f => console.log(' -', f));
}

await pool.end();
process.exit(failed > 0 ? 1 : 0);
