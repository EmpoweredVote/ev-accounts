/**
 * backfill-netfile-historical.ts — Historical backfill for LA County Netfile contributions.
 *
 * Downloads year-by-year Netfile LACO Excel exports, runs the adapter pipeline
 * for all confirmed politician_sources with source_system='la_county_netfile',
 * and inserts contributions into the DB.
 *
 * The adapter uses a lazy singleton: one Excel download per year, shared across
 * all 174+ politicians. So N years = N downloads, not N × politicians downloads.
 *
 * NOTE: Only 2024 Netfile data is reliably available via the current portal
 * mechanism. Older years (2020, 2022, etc.) return HTML or 0-byte ZIP from the
 * GetExcel postback. The script handles this gracefully — if a year's download
 * fails or returns HTML, it logs the failure and continues to the next year.
 *
 * Usage:
 *   npx tsx scripts/backfill-netfile-historical.ts --dry-run       # preview plan, no ingestion
 *   npx tsx scripts/backfill-netfile-historical.ts --year 2024     # single year (test)
 *   npx tsx scripts/backfill-netfile-historical.ts                 # all years 2016-current
 *   npx tsx scripts/backfill-netfile-historical.ts --start-year 2022  # start from 2022
 */

import 'dotenv/config';
import { Pool } from 'pg';
import { createNetfileAdapter } from '../src/lib/adapters/netfileAdapter.js';
import { runIngestion } from '../src/lib/adapters/runIngestion.js';
import type { PoliticianSource } from '../src/lib/campaignFinanceService.js';

// ---------------------------------------------------------------------------
// Args + env
// ---------------------------------------------------------------------------

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const isDryRun = process.argv.includes('--dry-run');

const yearIdx = process.argv.indexOf('--year');
const singleYear = yearIdx !== -1 ? parseInt(process.argv[yearIdx + 1] ?? '0', 10) : null;

const startYearIdx = process.argv.indexOf('--start-year');
const startYear = startYearIdx !== -1 ? parseInt(process.argv[startYearIdx + 1] ?? '2016', 10) : 2016;

const currentYear = new Date().getFullYear();
const years = singleYear ? [singleYear] : Array.from({ length: currentYear - startYear + 1 }, (_, i) => startYear + i);

// ---------------------------------------------------------------------------
// DB pool (separate from adapter pool to avoid conflicts)
// ---------------------------------------------------------------------------

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ---------------------------------------------------------------------------
// Query confirmed politician_sources
// ---------------------------------------------------------------------------

async function getConfirmedSources(): Promise<PoliticianSource[]> {
  const res = await pool.query<PoliticianSource>(
    `SELECT id, essentials_politician_id, source_system, external_id,
            research_status, notes, created_at, updated_at
     FROM transparent_motivations.politician_sources
     WHERE source_system = 'la_county_netfile'
       AND research_status = 'confirmed'
     ORDER BY id`
  );
  return res.rows;
}

// ---------------------------------------------------------------------------
// Sleep helper
// ---------------------------------------------------------------------------

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const overallStart = Date.now();

  const sources = await getConfirmedSources();
  console.log(`[backfill] Found ${sources.length} confirmed la_county_netfile politician_sources`);

  if (isDryRun) {
    console.log(`\n[DRY-RUN] Would process ${years.length} year(s) × ${sources.length} sources`);
    console.log(`Years: ${years[0]}–${years[years.length - 1]}`);
    console.log(`Sources (first 10):`);
    sources.slice(0, 10).forEach((s) => console.log(`  id=${s.id} external_id=${s.external_id}`));
    if (sources.length > 10) console.log(`  ... and ${sources.length - 10} more`);
    await pool.end();
    return;
  }

  let totalRunsAttempted = 0;
  let totalRunsSucceeded = 0;
  let totalInserted = 0;
  const yearResults: Array<{ year: number; status: 'ok' | 'failed'; inserted: number; error?: string }> = [];

  for (const year of years) {
    console.log(`\n${'─'.repeat(60)}`);
    console.log(`[backfill] Year ${year}: creating adapter for ${sources.length} sources...`);

    const adapter = createNetfileAdapter(year);
    let yearInserted = 0;
    let yearFailed = 0;

    // Test adapter with first source — if it fails, skip the entire year
    // (all sources share the same lazy download, so if one fails, all will fail)
    let yearOk = true;
    for (const ps of sources) {
      totalRunsAttempted++;
      try {
        await runIngestion(adapter, ps, String(year));
        totalRunsSucceeded++;
        yearInserted++; // approximate — runIngestion doesn't return insert count
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        // If this is an Excel download failure, skip remaining sources for this year
        if (msg.includes('HTML') || msg.includes('0 bytes') || msg.includes('ZIP') || msg.includes('sheet')) {
          console.warn(`  [YEAR-SKIP] Year ${year} download failed (${msg}). Skipping remaining sources.`);
          yearFailed = sources.length - yearInserted;
          yearOk = false;
          break;
        }
        console.error(`  [SOURCE-ERR] year=${year} source_id=${ps.id} external_id=${ps.external_id}: ${msg}`);
        yearFailed++;
      }
    }

    const yearStatus = yearOk ? 'ok' : 'failed';
    yearResults.push({ year, status: yearStatus, inserted: yearInserted });
    totalInserted += yearInserted;

    console.log(`[backfill] Year ${year}: ${yearStatus} — ${yearInserted} sources ingested, ${yearFailed} failed/skipped`);

    // Pause between years to be polite to the Netfile server
    if (years.indexOf(year) < years.length - 1) {
      console.log(`[backfill] Sleeping 5s before next year...`);
      await sleep(5000);
    }
  }

  // Summary
  const durationSec = ((Date.now() - overallStart) / 1000).toFixed(0);
  console.log(`\n${'='.repeat(60)}`);
  console.log(`NETFILE HISTORICAL BACKFILL COMPLETE`);
  console.log(`${'='.repeat(60)}`);
  console.log(`Years processed:       ${years[0]}–${years[years.length - 1]}`);
  console.log(`Politicians (sources): ${sources.length}`);
  console.log(`Ingestion runs:        ${totalRunsAttempted} attempted, ${totalRunsSucceeded} succeeded`);
  console.log(`Total duration:        ${durationSec}s`);
  console.log(`\nPer-year results:`);
  yearResults.forEach((r) => {
    const icon = r.status === 'ok' ? '✓' : '✗';
    console.log(`  ${icon} ${r.year}: ${r.status} (${r.inserted} ingested)`);
  });
  console.log(`${'='.repeat(60)}`);

  await pool.end();
}

main().catch(async (err) => {
  console.error('[backfill] Fatal error:', err instanceof Error ? err.message : String(err));
  await pool.end();
  process.exit(1);
});
