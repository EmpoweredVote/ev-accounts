/**
 * ingest-la-metro-batch.ts — Phase 3: Targeted batch-ingest CLI for LA-metro Cal-Access sources.
 *
 * Reads the seed-results CSV produced by seed-la-metro-from-discovery.ts, filters to a
 * caller-specified city subset, and runs runAdapterForSources for those source row IDs only.
 *
 * This avoids re-processing all 7k+ confirmed Cal-Access sources — only newly-seeded rows
 * for the requested cities are ingested.
 *
 * Usage:
 *   npx tsx scripts/ingest-la-metro-batch.ts --cities "El Monte,West Covina" [--dry-run]
 *   npx tsx scripts/ingest-la-metro-batch.ts --csv scripts/seed-results-2026-04-30T03-47-57.csv --cities "Glendora" --dry-run
 *
 * Flags:
 *   --csv <path>       Path to seed-results CSV (default: scripts/seed-results-2026-04-30T03-47-57.csv)
 *   --cities "A,B,C"  REQUIRED — comma-separated city names, case-insensitive, exact match
 *   --dry-run          Print which source_row_ids would be ingested, then exit 0 without DB writes
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { parse as parseCsv } from 'csv-parse/sync';
import { runAdapterForSources } from '../src/lib/campaignFinanceScheduler.js';

const LOG_PREFIX = '[ingest-la-metro-batch]';

// ─── Arg parsing ──────────────────────────────────────────────────────────────

const args = process.argv.slice(2);

function getArgValue(flag: string): string | null {
  const idx = args.indexOf(flag);
  if (idx === -1 || !args[idx + 1]) return null;
  return args[idx + 1];
}

const csvRelPath = getArgValue('--csv') ?? 'scripts/seed-results-2026-04-30T03-47-57.csv';
const csvPath = path.resolve(process.cwd(), csvRelPath);

const citiesRaw = getArgValue('--cities');
if (!citiesRaw) {
  console.error(`${LOG_PREFIX} ERROR: --cities "City A,City B" is required`);
  console.error(
    'Usage: npx tsx scripts/ingest-la-metro-batch.ts --cities "El Monte,West Covina" [--dry-run]'
  );
  process.exit(1);
}

const requestedCities = new Set(
  citiesRaw
    .split(',')
    .map(c => c.trim().toLowerCase())
    .filter(Boolean)
);

const isDryRun = args.includes('--dry-run');

// ─── Types ────────────────────────────────────────────────────────────────────

interface SeedResultRow {
  city: string;
  full_name: string;
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
    city: r['city'] ?? '',
    full_name: r['full_name'] ?? '',
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
  console.log(`${LOG_PREFIX} Cities: ${[...requestedCities].join(', ')}`);
  console.log('');

  // Load and filter CSV
  const allRows = loadSeedResults(csvPath);

  const matchingRows = allRows.filter(
    r =>
      requestedCities.has(r.city.trim().toLowerCase()) &&
      r.outcome === 'inserted'
  );

  if (matchingRows.length === 0) {
    console.warn(
      `${LOG_PREFIX} WARNING: No matching rows found for requested cities ` +
      `(checked outcome='inserted' only). Check city names and CSV path.`
    );
    process.exit(0);
  }

  // Collect unique source_row_ids and per-city stats
  const seenIds = new Set<string>();
  const byCityStats = new Map<string, { sources: number; politicians: Set<string> }>();

  for (const row of matchingRows) {
    if (!row.source_row_id) continue;

    const cityKey = row.city;
    if (!byCityStats.has(cityKey)) {
      byCityStats.set(cityKey, { sources: 0, politicians: new Set() });
    }
    const stat = byCityStats.get(cityKey)!;

    if (!seenIds.has(row.source_row_id)) {
      seenIds.add(row.source_row_id);
      stat.sources++;
    }
    stat.politicians.add(row.politician_id);
  }

  const uniqueSourceIds = [...seenIds];
  const distinctPoliticians = new Set(matchingRows.map(r => r.politician_id));

  // Pre-flight summary
  console.log('=== PRE-FLIGHT SUMMARY ===');
  const colW = [26, 10, 12];
  const hdr =
    '  ' +
    'CITY'.padEnd(colW[0]) +
    '| ' +
    'SOURCES'.padEnd(colW[1]) +
    '| POLITICIANS';
  console.log(hdr);
  console.log('-'.repeat(hdr.length));

  for (const [city, stat] of [...byCityStats.entries()].sort()) {
    console.log(
      '  ' +
      city.padEnd(colW[0]) +
      '| ' +
      String(stat.sources).padEnd(colW[1]) +
      '| ' +
      String(stat.politicians.size)
    );
  }
  console.log('-'.repeat(hdr.length));
  console.log(
    `  TOTAL`.padEnd(colW[0] + 2) +
    '| ' +
    String(uniqueSourceIds.length).padEnd(colW[1]) +
    '| ' +
    String(distinctPoliticians.size)
  );
  console.log('');
  console.log(`  source_row_ids to ingest: ${uniqueSourceIds.join(', ')}`);
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
  console.log(`${LOG_PREFIX} Completed in ${elapsed}s — ${uniqueSourceIds.length} sources processed for ${distinctPoliticians.size} politicians.`);
  process.exit(0);
}

main().catch(err => {
  console.error(`${LOG_PREFIX} Fatal error:`, err instanceof Error ? err.stack : String(err));
  process.exit(1);
});
