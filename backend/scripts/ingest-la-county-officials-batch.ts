/**
 * ingest-la-county-officials-batch.ts — Phase 3: Targeted Cal-Access ingest for the 8 LA County
 * officeholders (5 Supervisors, DA, Sheriff, Assessor).
 *
 * Reads the seed-results CSV produced by seed-la-county-officials-from-discovery.ts and calls
 * runAdapterForSources for newly-seeded source row IDs. By default only ingests rows where
 * outcome IN ('inserted', 'promoted') — skips already_confirmed to avoid re-ingesting old data.
 *
 * Pass --include-existing to also include already_confirmed rows (force reingest).
 *
 * Usage:
 *   npx tsx scripts/ingest-la-county-officials-batch.ts --csv scripts/seed-results-la-county-officials-TIMESTAMP.csv --dry-run
 *   npx tsx scripts/ingest-la-county-officials-batch.ts --csv scripts/seed-results-la-county-officials-TIMESTAMP.csv
 *   npx tsx scripts/ingest-la-county-officials-batch.ts --csv ... --include-existing
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { parse as parseCsv } from 'csv-parse/sync';
import { runAdapterForSources } from '../src/lib/campaignFinanceScheduler.js';

const LOG_PREFIX = '[ingest-la-county-officials-batch]';

// ─── Arg parsing ──────────────────────────────────────────────────────────────

const args = process.argv.slice(2);

function getArgValue(flag: string): string | null {
  const idx = args.indexOf(flag);
  if (idx === -1 || !args[idx + 1]) return null;
  return args[idx + 1];
}

const csvRelPath = getArgValue('--csv');
if (!csvRelPath) {
  console.error(`${LOG_PREFIX} ERROR: --csv <path> is required`);
  console.error('Usage: npx tsx scripts/ingest-la-county-officials-batch.ts --csv scripts/seed-results-la-county-officials-TIMESTAMP.csv [--dry-run] [--include-existing]');
  process.exit(1);
}
const csvPath = path.resolve(process.cwd(), csvRelPath);

const isDryRun = args.includes('--dry-run');
const includeExisting = args.includes('--include-existing');

// ─── Types ────────────────────────────────────────────────────────────────────

interface SeedResultRow {
  full_name: string;
  office: string;
  politician_id: string;
  filer_id: string;
  committee_name: string;
  source_row_id: string;
  outcome: string;
}

// ─── CSV loading ──────────────────────────────────────────────────────────────

function loadSeedResults(filePath: string): SeedResultRow[] {
  if (!fs.existsSync(filePath)) {
    console.error(`${LOG_PREFIX} ERROR: CSV file not found: ${filePath}`);
    process.exit(1);
  }

  const content = fs.readFileSync(filePath, 'utf8');
  const records = parseCsv(content, {
    columns: true,
    skip_empty_lines: true,
    trim: true,
  }) as Record<string, string>[];

  return records.map(r => ({
    full_name: r['full_name'] ?? '',
    office: r['office'] ?? '',
    politician_id: r['politician_id'] ?? '',
    filer_id: r['filer_id'] ?? '',
    committee_name: r['committee_name'] ?? '',
    source_row_id: r['source_row_id'] ?? '',
    outcome: r['outcome'] ?? '',
  }));
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const startMs = Date.now();

  console.log(`${LOG_PREFIX} Mode: ${isDryRun ? 'DRY-RUN' : 'LIVE'}`);
  console.log(`${LOG_PREFIX} CSV: ${csvPath}`);
  console.log(`${LOG_PREFIX} Include existing (already_confirmed): ${includeExisting}`);
  console.log('');

  // Load CSV
  const allRows = loadSeedResults(csvPath);

  // Filter to rows we should ingest
  const eligibleOutcomes = new Set(['inserted', 'promoted']);
  if (includeExisting) eligibleOutcomes.add('already_confirmed');

  const eligibleRows = allRows.filter(
    r => eligibleOutcomes.has(r.outcome) && r.source_row_id
  );

  if (eligibleRows.length === 0) {
    console.warn(
      `${LOG_PREFIX} WARNING: No eligible rows found (outcomes: ${[...eligibleOutcomes].join(', ')}).`
    );
    console.warn('Check CSV path and outcomes. Use --include-existing to force-reingest already_confirmed rows.');
    process.exit(0);
  }

  // Collect unique source_row_ids and per-official stats
  const seenIds = new Set<string>();
  const byOfficialStats = new Map<string, { name: string; office: string; sources: number; filerIds: string[] }>();

  for (const row of eligibleRows) {
    if (!row.source_row_id) continue;

    const key = row.full_name;
    if (!byOfficialStats.has(key)) {
      byOfficialStats.set(key, { name: row.full_name, office: row.office, sources: 0, filerIds: [] });
    }
    const stat = byOfficialStats.get(key)!;

    if (!seenIds.has(row.source_row_id)) {
      seenIds.add(row.source_row_id);
      stat.sources++;
      stat.filerIds.push(row.filer_id);
    }
  }

  const uniqueSourceIds = [...seenIds];
  const distinctPoliticians = new Set(eligibleRows.map(r => r.politician_id));

  // Pre-flight summary
  console.log('=== PRE-FLIGHT SUMMARY ===');
  const colW = [26, 24, 10, 10];
  const hdr =
    '  ' + 'OFFICIAL'.padEnd(colW[0]) +
    '| ' + 'OFFICE'.padEnd(colW[1]) +
    '| ' + 'SOURCES'.padEnd(colW[2]) +
    '| FILER IDs';
  console.log(hdr);
  console.log('-'.repeat(70));

  for (const [, stat] of [...byOfficialStats.entries()]) {
    console.log(
      '  ' + stat.name.padEnd(colW[0]) +
      '| ' + stat.office.padEnd(colW[1]) +
      '| ' + String(stat.sources).padEnd(colW[2]) +
      '| ' + stat.filerIds.join(', ')
    );
  }
  console.log('-'.repeat(70));
  console.log(
    '  ' + 'TOTAL'.padEnd(colW[0]) +
    '| '.padEnd(colW[1] + 2) +
    '| ' + String(uniqueSourceIds.length).padEnd(colW[2]) +
    '| ' + String(distinctPoliticians.size) + ' officials'
  );
  console.log('');
  console.log(`  source_row_ids: ${uniqueSourceIds.join(', ')}`);
  console.log('');

  if (isDryRun) {
    console.log(`${LOG_PREFIX} [DRY-RUN] Exiting without DB writes.`);
    process.exit(0);
  }

  // Live ingest
  console.log(`${LOG_PREFIX} Starting runAdapterForSources for ${uniqueSourceIds.length} sources...`);
  console.log('');

  try {
    await runAdapterForSources(uniqueSourceIds);
  } catch (err) {
    const elapsed = ((Date.now() - startMs) / 1000).toFixed(1);
    console.error(`${LOG_PREFIX} ERROR: runAdapterForSources threw after ${elapsed}s`);
    console.error(err instanceof Error ? err.stack : String(err));
    process.exit(1);
  }

  const elapsed = ((Date.now() - startMs) / 1000).toFixed(1);
  console.log('');
  console.log(`${LOG_PREFIX} Completed in ${elapsed}s — ${uniqueSourceIds.length} sources processed for ${distinctPoliticians.size} officials.`);
  process.exit(0);
}

main().catch(err => {
  console.error(`${LOG_PREFIX} Fatal error:`, err instanceof Error ? err.stack : String(err));
  process.exit(1);
});
