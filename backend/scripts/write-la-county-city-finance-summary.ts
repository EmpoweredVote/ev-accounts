/**
 * write-la-county-city-finance-summary.ts
 *
 * Phase 109 Wave 2 — LAFI-02
 *
 * Aggregates LA County city Netfile contributions (source_system='la_county_netfile')
 * from transparent_motivations.contributions into essentials.politicians.finance_summary
 * JSONB for all officials with confirmed la_county_netfile politician_sources rows.
 *
 * Officials with zero positive-amount contributions have finance_summary left as NULL
 * (or unchanged), and the run log emits a [SKIP] message.
 *
 * Idempotent: re-running replaces the JSONB value entirely — safe to run after
 * any new Netfile ingest.
 *
 * Run: cd C:/EV-Accounts/backend && npx tsx scripts/write-la-county-city-finance-summary.ts
 *
 * Requires environment variables:
 *   DATABASE_URL — PostgreSQL connection string (in .env)
 */

import 'dotenv/config';
import { pool } from '../src/lib/db.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface FinanceSummary {
  total_raised: number;
  total_spent?: number;
  top_donors: Array<{ employer: string; amount: number; count: number }>;
  cycle: string;
  source: 'LA_COUNTY_NETFILE';
}

interface PoliticianWithNetfileSource {
  id: string;
  full_name: string;
}

// ---------------------------------------------------------------------------
// DB helpers
// ---------------------------------------------------------------------------

/**
 * getLACountyCityPoliticiansWithNetfileSources returns politicians who have at
 * least one confirmed la_county_netfile politician_sources row.
 */
async function getLACountyCityPoliticiansWithNetfileSources(): Promise<PoliticianWithNetfileSource[]> {
  const sql = `
    SELECT DISTINCT p.id, p.full_name
    FROM essentials.politicians p
    JOIN transparent_motivations.politician_sources ps
      ON ps.essentials_politician_id = p.id
    WHERE ps.source_system = 'la_county_netfile'
      AND ps.research_status = 'confirmed'
    ORDER BY p.full_name
  `;
  const result = await pool.query<PoliticianWithNetfileSource>(sql);
  return result.rows;
}

/**
 * buildFinanceSummaryFromNetfile aggregates positive contributions for a
 * politician from the transparent_motivations.contributions table via their
 * confirmed la_county_netfile politician_sources rows.
 *
 * Returns null when total_raised is 0 (no contributions ingested yet).
 * This is expected — the Netfile REST API only covers data from approx 2025+.
 */
async function buildFinanceSummaryFromNetfile(
  politicianId: string
): Promise<FinanceSummary | null> {
  const result = await pool.query<{
    total_raised: string;
    total_spent: string;
    contribution_count: string;
  }>(
    `SELECT
       COALESCE(SUM(CASE WHEN c.amount > 0 THEN c.amount ELSE 0 END), 0) AS total_raised,
       COALESCE(ABS(SUM(CASE WHEN c.amount < 0 THEN c.amount ELSE 0 END)), 0) AS total_spent,
       COUNT(*) FILTER (WHERE c.amount > 0) AS contribution_count
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
     WHERE ps.essentials_politician_id = $1
       AND ps.source_system = 'la_county_netfile'
       AND ps.research_status = 'confirmed'`,
    [politicianId]
  );

  const row = result.rows[0];
  if (!row || Number(row.total_raised) === 0) return null;

  const summary: FinanceSummary = {
    total_raised: Number(row.total_raised),
    top_donors: [],  // Netfile data — donor detail not yet aggregated
    cycle: 'all',    // Netfile covers all available data (approx 2025+)
    source: 'LA_COUNTY_NETFILE',
  };

  const totalSpent = Number(row.total_spent);
  if (totalSpent > 0) {
    summary.total_spent = totalSpent;
  }

  return summary;
}

/**
 * updateFinanceSummary writes the JSONB finance_summary for a politician.
 * The ::jsonb cast is required — do not omit.
 */
async function updateFinanceSummary(politicianId: string, summary: FinanceSummary): Promise<void> {
  await pool.query(
    `UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2`,
    [JSON.stringify(summary), politicianId]
  );
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  if (!process.env.DATABASE_URL) {
    console.error('[write-la-county-city-finance-summary] ERROR: DATABASE_URL is not set');
    process.exit(1);
  }

  console.log('[write-la-county-city-finance-summary] Starting...\n');

  const politicians = await getLACountyCityPoliticiansWithNetfileSources();
  console.log(`[write-la-county-city-finance-summary] Found ${politicians.length} politician(s) with confirmed la_county_netfile sources\n`);

  let processed = 0;
  let succeeded = 0;
  let skipped_no_data = 0;
  let errors = 0;
  const skippedNames: string[] = [];

  for (const p of politicians) {
    processed++;
    console.log(`\n[${processed}/${politicians.length}] ${p.full_name}`);

    try {
      const summary = await buildFinanceSummaryFromNetfile(p.id);

      if (!summary) {
        console.log(`  [SKIP] ${p.full_name} — no Netfile contributions found (finance_summary = NULL)`);
        skipped_no_data++;
        skippedNames.push(p.full_name);
        continue;
      }

      await updateFinanceSummary(p.id, summary);
      console.log(
        `  [OK] finance_summary written. total_raised=$${summary.total_raised.toLocaleString()} cycle=${summary.cycle}`
      );
      succeeded++;
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : String(err);
      console.error(`  [ERROR] ${p.full_name}: ${errMsg}`);
      errors++;
    }
  }

  // Print summary
  console.log('\n[write-la-county-city-finance-summary] ══════════════════════════════════════════');
  console.log('[write-la-county-city-finance-summary] SUMMARY');
  console.log('[write-la-county-city-finance-summary] ══════════════════════════════════════════');
  console.log(`  Politicians processed:     ${processed}`);
  console.log(`  Finance summary written:   ${succeeded}`);
  console.log(`  Skipped (no data / NULL):  ${skipped_no_data}`);
  console.log(`  Errors:                    ${errors}`);

  if (skippedNames.length > 0) {
    console.log(`\n  Skipped politicians (zero Netfile contributions — finance_summary = NULL):`);
    for (const name of skippedNames) {
      console.log(`    - ${name}`);
    }
    console.log(`\n  NOTE: Zero contributions is expected for Netfile data. The REST API only`);
    console.log(`  covers filings from approx 2025+. Officials who haven't filed yet will`);
    console.log(`  get finance_summary populated on a subsequent run after new filings appear.`);
  }

  console.log('\n[write-la-county-city-finance-summary] Done.');

  await pool.end();
  process.exit(0);
}

main().catch(async (err) => {
  console.error('[write-la-county-city-finance-summary] Fatal error:', err instanceof Error ? err.message : String(err));
  try { await pool.end(); } catch { /* ignore pool close errors on fatal path */ }
  process.exit(1);
});
