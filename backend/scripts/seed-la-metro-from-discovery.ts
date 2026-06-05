/**
 * seed-la-metro-from-discovery.ts — Phase 2: Seed confirmed Cal-Access source rows
 * for all LA-metro politicians identified in Phase 1 discovery.
 *
 * Reads the CSV produced by discover-la-metro-cal-access.ts and inserts confirmed
 * politician_sources rows. Does NOT trigger ingest — that's Phase 3 (batched by city).
 *
 * Usage:
 *   npx tsx scripts/seed-la-metro-from-discovery.ts --csv scripts/discover-la-metro-TIMESTAMP.csv --dry-run
 *   npx tsx scripts/seed-la-metro-from-discovery.ts --csv scripts/discover-la-metro-TIMESTAMP.csv
 *
 * Output: prints inserted/skipped counts by city, writes a seed-results-TIMESTAMP.csv
 * with source row IDs grouped by city — used by Phase 3 batch ingest scripts.
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';
import { parse as parseCsv } from 'csv-parse/sync';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

// ─── Args ─────────────────────────────────────────────────────────────────────

const csvArgIdx = process.argv.indexOf('--csv');
if (csvArgIdx === -1 || !process.argv[csvArgIdx + 1]) {
  console.error('ERROR: --csv <path> is required');
  console.error('Usage: npx tsx scripts/seed-la-metro-from-discovery.ts --csv scripts/discover-la-metro-TIMESTAMP.csv [--dry-run]');
  process.exit(1);
}
const csvPath = process.argv[csvArgIdx + 1];
if (!fs.existsSync(csvPath)) {
  console.error(`ERROR: CSV file not found: ${csvPath}`);
  process.exit(1);
}
const isDryRun = process.argv.includes('--dry-run');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Types ────────────────────────────────────────────────────────────────────

interface DiscoveryRow {
  politician_id: string;
  full_name: string;
  city: string;
  office: string;
  match_count: number;
  filer_ids: string[];
  committee_names: string[];
  status: string;
}

interface SeedResult {
  politician_id: string;
  full_name: string;
  city: string;
  filer_id: string;
  committee_name: string;
  source_row_id: string | null;
  outcome: 'inserted' | 'promoted' | 'already_confirmed' | 'skipped_dry_run';
}

// ─── CSV parsing ──────────────────────────────────────────────────────────────

function loadDiscoveryCSV(filePath: string): DiscoveryRow[] {
  const content = fs.readFileSync(filePath, 'utf8');
  const records = parseCsv(content, { columns: true, skip_empty_lines: true }) as Record<string, string>[];

  return records
    .filter(r => r.status === 'matched' && parseInt(r.match_count) > 0)
    .map(r => ({
      politician_id: r.politician_id,
      full_name: r.full_name,
      city: r.city,
      office: r.office,
      match_count: parseInt(r.match_count),
      filer_ids: r.filer_ids.split(' | ').map(s => s.trim()).filter(Boolean),
      committee_names: r.committee_names.split(' | ').map(s => s.trim()).filter(Boolean),
      status: r.status,
    }));
}

// ─── DB helpers ───────────────────────────────────────────────────────────────

async function seedRow(
  politicianId: string,
  filerId: string,
  committeeName: string
): Promise<{ outcome: 'inserted' | 'promoted' | 'already_confirmed'; sourceRowId: string | null }> {
  const insertRes = await pool.query<{ id: string }>(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes)
     VALUES ($1, 'cal_access', $2, 'confirmed', $3)
     ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING
     RETURNING id`,
    [
      politicianId,
      filerId,
      JSON.stringify({ committee_name: committeeName, confirmed_by: 'seed-la-metro-from-discovery.ts' }),
    ]
  );

  if (insertRes.rows[0]) {
    return { outcome: 'inserted', sourceRowId: insertRes.rows[0].id };
  }

  // Row existed — try to promote needs_research → confirmed
  const updateRes = await pool.query<{ id: string }>(
    `UPDATE transparent_motivations.politician_sources
     SET research_status = 'confirmed',
         notes = $3,
         updated_at = NOW()
     WHERE essentials_politician_id = $1
       AND source_system = 'cal_access'
       AND external_id = $2
       AND research_status != 'confirmed'
     RETURNING id`,
    [
      politicianId,
      filerId,
      JSON.stringify({ committee_name: committeeName, confirmed_by: 'seed-la-metro-from-discovery.ts' }),
    ]
  );

  if (updateRes.rows[0]) {
    return { outcome: 'promoted', sourceRowId: updateRes.rows[0].id };
  }

  // Already confirmed — fetch the existing row ID
  const existingRes = await pool.query<{ id: string }>(
    `SELECT id FROM transparent_motivations.politician_sources
     WHERE essentials_politician_id = $1
       AND source_system = 'cal_access'
       AND external_id = $2`,
    [politicianId, filerId]
  );

  return {
    outcome: 'already_confirmed',
    sourceRowId: existingRes.rows[0]?.id ?? null,
  };
}

// ─── Results CSV writer ───────────────────────────────────────────────────────

function writeResultsCSV(results: SeedResult[], outputPath: string): void {
  const header = 'city,full_name,politician_id,filer_id,committee_name,source_row_id,outcome';
  const rows = results.map(r => [
    r.city,
    `"${r.full_name.replace(/"/g, '""')}"`,
    r.politician_id,
    r.filer_id,
    `"${r.committee_name.replace(/"/g, '""')}"`,
    r.source_row_id ?? '',
    r.outcome,
  ].join(','));
  fs.writeFileSync(outputPath, [header, ...rows].join('\n'), 'utf8');
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const startMs = Date.now();
  console.log(`[seed-la-metro-from-discovery] Mode: ${isDryRun ? 'DRY-RUN' : 'LIVE'}`);
  console.log(`[seed-la-metro-from-discovery] CSV: ${csvPath}`);

  // Load discovery results
  const discoveryRows = loadDiscoveryCSV(csvPath);
  const totalFilerIds = discoveryRows.reduce((n, r) => n + r.filer_ids.length, 0);
  console.log(`\nLoaded ${discoveryRows.length} matched politicians, ${totalFilerIds} total filer IDs to seed\n`);

  // Process each politician
  const allResults: SeedResult[] = [];
  const byCityTotals = new Map<string, { inserted: number; promoted: number; already: number }>();

  for (const row of discoveryRows) {
    const cityTotals = byCityTotals.get(row.city) ?? { inserted: 0, promoted: 0, already: 0 };

    for (let i = 0; i < row.filer_ids.length; i++) {
      const filerId = row.filer_ids[i];
      const committeeName = row.committee_names[i] ?? filerId;

      if (isDryRun) {
        allResults.push({
          politician_id: row.politician_id,
          full_name: row.full_name,
          city: row.city,
          filer_id: filerId,
          committee_name: committeeName,
          source_row_id: null,
          outcome: 'skipped_dry_run',
        });
        cityTotals.inserted++;
      } else {
        const { outcome, sourceRowId } = await seedRow(row.politician_id, filerId, committeeName);
        allResults.push({
          politician_id: row.politician_id,
          full_name: row.full_name,
          city: row.city,
          filer_id: filerId,
          committee_name: committeeName,
          source_row_id: sourceRowId,
          outcome,
        });
        if (outcome === 'inserted') cityTotals.inserted++;
        else if (outcome === 'promoted') cityTotals.promoted++;
        else cityTotals.already++;
      }
    }

    byCityTotals.set(row.city, cityTotals);
  }

  // Print by-city summary
  console.log('=== RESULTS BY CITY ===\n');
  const colW = [22, 10, 10, 10];
  const hdr = '  ' +
    'CITY'.padEnd(colW[0]) + '| ' +
    'INSERTED'.padEnd(colW[1]) + '| ' +
    'PROMOTED'.padEnd(colW[2]) + '| ' +
    'EXISTING';
  console.log(hdr);
  console.log('-'.repeat(hdr.length));

  for (const [city, t] of [...byCityTotals.entries()].sort()) {
    console.log(
      '  ' +
      city.padEnd(colW[0]) + '| ' +
      String(t.inserted).padEnd(colW[1]) + '| ' +
      String(t.promoted).padEnd(colW[2]) + '| ' +
      String(t.already)
    );
  }
  console.log('-'.repeat(hdr.length));

  const totalInserted = allResults.filter(r => r.outcome === 'inserted' || r.outcome === 'skipped_dry_run').length;
  const totalPromoted = allResults.filter(r => r.outcome === 'promoted').length;
  const totalAlready = allResults.filter(r => r.outcome === 'already_confirmed').length;
  console.log(`\nTotal: ${totalInserted} inserted, ${totalPromoted} promoted, ${totalAlready} already confirmed`);

  // Write results CSV (used by Phase 3 batch ingests)
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const outputPath = path.join(
    path.dirname(csvPath),
    `seed-results-${timestamp}.csv`
  );
  writeResultsCSV(allResults, outputPath);
  console.log(`\nResults (with source_row_ids for Phase 3) written to:\n  ${outputPath}`);

  if (isDryRun) {
    console.log('\n[DRY-RUN] No DB writes — run without --dry-run to seed.');
  } else {
    console.log('\nNext step — Phase 3: run batch ingests using the source_row_ids in the results CSV.');
    console.log('Example: npx tsx scripts/ingest-la-metro-batch.ts --csv ' + outputPath + ' --cities "El Monte,West Covina,Norwalk"');
  }

  const durationMs = Date.now() - startMs;
  console.log(`\n[seed-la-metro-from-discovery] Completed in ${(durationMs / 1000).toFixed(1)}s`);
}

main()
  .then(async () => { await pool.end(); process.exit(0); })
  .catch(async err => {
    console.error('[seed-la-metro-from-discovery] Fatal error:', err);
    await pool.end();
    process.exit(1);
  });
