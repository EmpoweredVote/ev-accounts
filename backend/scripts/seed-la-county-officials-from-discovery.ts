/**
 * seed-la-county-officials-from-discovery.ts — Phase 2: Seed confirmed Cal-Access source rows
 * for the 8 LA County officeholders (5 Supervisors, DA, Sheriff, Assessor).
 *
 * Reads the CSV produced by discover-la-county-officials-cal-access.ts and inserts/promotes
 * confirmed politician_sources rows. Does NOT trigger ingest — that's Phase 3
 * (ingest-la-county-officials-batch.ts).
 *
 * Usage:
 *   npx tsx scripts/seed-la-county-officials-from-discovery.ts --csv scripts/discover-la-county-officials-TIMESTAMP.csv --dry-run
 *   npx tsx scripts/seed-la-county-officials-from-discovery.ts --csv scripts/discover-la-county-officials-TIMESTAMP.csv
 *   npx tsx scripts/seed-la-county-officials-from-discovery.ts --csv ... --exclude "politician_id:filer_id,..."
 *
 * Output: prints inserted/promoted/existing counts per official, writes a
 *   seed-results-la-county-officials-TIMESTAMP.csv with source_row_ids — used by Phase 3 ingest.
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

const args = process.argv.slice(2);

function getArgValue(flag: string): string | null {
  const idx = args.indexOf(flag);
  if (idx === -1 || !args[idx + 1]) return null;
  return args[idx + 1];
}

const csvRelPath = getArgValue('--csv');
if (!csvRelPath) {
  console.error('ERROR: --csv <path> is required');
  console.error('Usage: npx tsx scripts/seed-la-county-officials-from-discovery.ts --csv scripts/discover-la-county-officials-TIMESTAMP.csv [--dry-run] [--exclude "pid:fid,..."]');
  process.exit(1);
}
const csvPath = path.resolve(process.cwd(), csvRelPath);
if (!fs.existsSync(csvPath)) {
  console.error(`ERROR: CSV file not found: ${csvPath}`);
  process.exit(1);
}

const isDryRun = args.includes('--dry-run');

// Parse exclude list: "politician_id:filer_id,politician_id:filer_id"
const excludeRaw = getArgValue('--exclude');
const excludeSet = new Set<string>();
if (excludeRaw) {
  for (const pair of excludeRaw.split(',')) {
    const trimmed = pair.trim();
    if (trimmed) excludeSet.add(trimmed); // format: "pid:fid"
  }
  console.log(`Excluding ${excludeSet.size} (politician_id:filer_id) pairs from seeding.`);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Types ────────────────────────────────────────────────────────────────────

interface DiscoveryRow {
  politician_id: string;
  full_name: string;
  office: string;
  match_count: number;
  filer_ids: string[];
  committee_names: string[];
  status: string;
}

interface SeedResult {
  full_name: string;
  office: string;
  politician_id: string;
  filer_id: string;
  committee_name: string;
  source_row_id: string | null;
  outcome: 'inserted' | 'promoted' | 'already_confirmed' | 'excluded' | 'skipped_dry_run';
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
      office: r.office,
      match_count: parseInt(r.match_count),
      filer_ids: r.filer_ids.split(' | ').map((s: string) => s.trim()).filter(Boolean),
      committee_names: r.committee_names.split(' | ').map((s: string) => s.trim()).filter(Boolean),
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
      JSON.stringify({ committee_name: committeeName, confirmed_by: 'seed-la-county-officials-from-discovery.ts' }),
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
      JSON.stringify({ committee_name: committeeName, confirmed_by: 'seed-la-county-officials-from-discovery.ts' }),
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

function escapeCsv(s: string): string {
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

function writeResultsCSV(results: SeedResult[], outputPath: string): void {
  const header = 'full_name,office,politician_id,filer_id,committee_name,source_row_id,outcome';
  const rows = results.map(r => [
    escapeCsv(r.full_name),
    escapeCsv(r.office),
    r.politician_id,
    r.filer_id,
    escapeCsv(r.committee_name),
    r.source_row_id ?? '',
    r.outcome,
  ].join(','));
  fs.writeFileSync(outputPath, [header, ...rows].join('\n'), 'utf8');
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const startMs = Date.now();
  console.log(`[seed-la-county-officials-from-discovery] Mode: ${isDryRun ? 'DRY-RUN' : 'LIVE'}`);
  console.log(`[seed-la-county-officials-from-discovery] CSV: ${csvPath}`);

  // Load discovery results
  const discoveryRows = loadDiscoveryCSV(csvPath);
  const totalFilerIds = discoveryRows.reduce((n, r) => n + r.filer_ids.length, 0);
  console.log(`\nLoaded ${discoveryRows.length} matched officials, ${totalFilerIds} total filer IDs to process\n`);

  // Process each official
  const allResults: SeedResult[] = [];
  const byOfficialTotals = new Map<string, { inserted: number; promoted: number; already: number; excluded: number }>();

  for (const row of discoveryRows) {
    const totals = byOfficialTotals.get(row.full_name) ?? { inserted: 0, promoted: 0, already: 0, excluded: 0 };

    for (let i = 0; i < row.filer_ids.length; i++) {
      const filerId = row.filer_ids[i];
      const committeeName = row.committee_names[i] ?? filerId;
      const excludeKey = `${row.politician_id}:${filerId}`;

      if (excludeSet.has(excludeKey)) {
        allResults.push({
          full_name: row.full_name,
          office: row.office,
          politician_id: row.politician_id,
          filer_id: filerId,
          committee_name: committeeName,
          source_row_id: null,
          outcome: 'excluded',
        });
        totals.excluded++;
        continue;
      }

      if (isDryRun) {
        allResults.push({
          full_name: row.full_name,
          office: row.office,
          politician_id: row.politician_id,
          filer_id: filerId,
          committee_name: committeeName,
          source_row_id: null,
          outcome: 'skipped_dry_run',
        });
        totals.inserted++; // dry-run counts as "would insert"
      } else {
        const { outcome, sourceRowId } = await seedRow(row.politician_id, filerId, committeeName);
        allResults.push({
          full_name: row.full_name,
          office: row.office,
          politician_id: row.politician_id,
          filer_id: filerId,
          committee_name: committeeName,
          source_row_id: sourceRowId,
          outcome,
        });
        if (outcome === 'inserted') totals.inserted++;
        else if (outcome === 'promoted') totals.promoted++;
        else totals.already++;
      }
    }

    byOfficialTotals.set(row.full_name, totals);
  }

  // Print per-official summary
  console.log('=== RESULTS BY OFFICIAL ===\n');
  const colW = [26, 24, 10, 10, 10, 10];
  const hdr =
    '  ' + 'OFFICIAL'.padEnd(colW[0]) +
    '| ' + 'OFFICE'.padEnd(colW[1]) +
    '| ' + 'INSERTED'.padEnd(colW[2]) +
    '| ' + 'PROMOTED'.padEnd(colW[3]) +
    '| ' + 'EXISTING'.padEnd(colW[4]) +
    '| EXCLUDED';
  console.log(hdr);
  console.log('-'.repeat(hdr.length));

  for (const [name, t] of [...byOfficialTotals.entries()]) {
    console.log(
      '  ' + name.padEnd(colW[0]) +
      '| ' + (discoveryRows.find(r => r.full_name === name)?.office ?? '').padEnd(colW[1]) +
      '| ' + String(t.inserted).padEnd(colW[2]) +
      '| ' + String(t.promoted).padEnd(colW[3]) +
      '| ' + String(t.already).padEnd(colW[4]) +
      '| ' + String(t.excluded)
    );
  }
  console.log('-'.repeat(hdr.length));

  const totalInserted = allResults.filter(r => r.outcome === 'inserted' || r.outcome === 'skipped_dry_run').length;
  const totalPromoted = allResults.filter(r => r.outcome === 'promoted').length;
  const totalAlready = allResults.filter(r => r.outcome === 'already_confirmed').length;
  const totalExcluded = allResults.filter(r => r.outcome === 'excluded').length;
  console.log(`\nTotal: ${totalInserted} inserted, ${totalPromoted} promoted, ${totalAlready} already confirmed, ${totalExcluded} excluded`);

  // Write results CSV
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const outputPath = path.join(
    path.dirname(path.resolve(process.cwd(), csvRelPath!)),
    `seed-results-la-county-officials-${timestamp}.csv`
  );
  writeResultsCSV(allResults, outputPath);
  console.log(`\nResults (with source_row_ids for Phase 3) written to:\n  ${outputPath}`);

  if (isDryRun) {
    console.log('\n[DRY-RUN] No DB writes — run without --dry-run to seed.');
  } else {
    console.log('\nNext step — Phase 3: ingest using the source_row_ids in the results CSV.');
    console.log('Example: npx tsx scripts/ingest-la-county-officials-batch.ts --csv ' + outputPath);
  }

  const durationMs = Date.now() - startMs;
  console.log(`\n[seed-la-county-officials-from-discovery] Completed in ${(durationMs / 1000).toFixed(1)}s`);
}

main()
  .then(async () => { await pool.end(); process.exit(0); })
  .catch(async err => {
    console.error('[seed-la-county-officials-from-discovery] Fatal error:', err);
    await pool.end();
    process.exit(1);
  });
