/**
 * write-la-city-finance-summary.ts — Aggregate LA City Socrata contributions into
 * essentials.politicians.finance_summary for all officials with confirmed la_socrata sources.
 *
 * Purpose: Closes LAFI-01 — every LA City official with Socrata contributions gets a
 * populated finance_summary JSONB; officials with zero contributions (Lattimore, possibly
 * Jurado) remain NULL with a documented log entry.
 *
 * Usage:
 *   cd backend && npx tsx scripts/write-la-city-finance-summary.ts
 *
 * Requires:
 *   DATABASE_URL — in backend/.env
 *
 * Idempotent: re-running replaces (not appends) the JSONB value.
 *
 * IMPORTANT: The socrataAdapter writes contributions with committee_id = null and
 * politician_source_id directly on the contributions row. Aggregation joins
 * contributions → politician_sources directly (NOT via committees table).
 */

import 'dotenv/config';
import { pool } from '../src/lib/db.js';

// ─── Env guard ────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

// ─── Types ────────────────────────────────────────────────────────────────────

interface FinanceSummary {
  total_raised: number;
  total_spent?: number;
  top_donors: Array<{ employer: string; amount: number; count: number }>;
  cycle: string;
  source: 'LA_SOCRATA';
}

// ─── DB helpers ───────────────────────────────────────────────────────────────

/**
 * Returns all active politicians with at least one confirmed la_socrata source.
 * Ordered by full_name for deterministic log output.
 */
async function getLACityPoliticiansWithSocrataSources(): Promise<
  Array<{ id: string; full_name: string }>
> {
  const sql = `
    SELECT DISTINCT p.id, p.full_name
    FROM essentials.politicians p
    JOIN transparent_motivations.politician_sources ps
      ON ps.essentials_politician_id = p.id
    WHERE ps.source_system = 'la_socrata'
      AND ps.research_status = 'confirmed'
    ORDER BY p.full_name
  `;
  const result = await pool.query<{ id: string; full_name: string }>(sql);
  return result.rows;
}

/**
 * Aggregates total_raised and total_spent for a politician from
 * transparent_motivations.contributions via their confirmed la_socrata
 * politician_sources rows.
 *
 * NOTE: socrataAdapter stores contributions with committee_id = null and
 * politician_source_id directly on the contributions row — join on
 * politician_source_id, NOT via the committees table.
 *
 * Returns null when total_raised is 0 (no positive-amount contributions found).
 */
async function buildFinanceSummaryFromSocrata(
  politicianId: string
): Promise<FinanceSummary | null> {
  // Total raised: SUM of positive-amount contributions
  const raisedResult = await pool.query<{
    total_raised: string;
    contribution_count: string;
  }>(
    `SELECT
       COALESCE(SUM(c.amount), 0) AS total_raised,
       COUNT(*) AS contribution_count
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
     WHERE ps.essentials_politician_id = $1
       AND ps.source_system = 'la_socrata'
       AND ps.research_status = 'confirmed'
       AND c.amount > 0`,
    [politicianId]
  );

  const raisedRow = raisedResult.rows[0];
  if (!raisedRow || Number(raisedRow.total_raised) === 0) {
    return null;
  }

  // Total spent: SUM of ABS(negative-amount contributions)
  const spentResult = await pool.query<{ total_spent: string }>(
    `SELECT
       COALESCE(ABS(SUM(c.amount)), 0) AS total_spent
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
     WHERE ps.essentials_politician_id = $1
       AND ps.source_system = 'la_socrata'
       AND ps.research_status = 'confirmed'
       AND c.amount < 0`,
    [politicianId]
  );

  const totalSpent = Number(spentResult.rows[0]?.total_spent ?? 0);

  return {
    total_raised: Number(raisedRow.total_raised),
    total_spent: totalSpent,
    top_donors: [],  // Socrata has donor data — future enhancement
    cycle: 'all',    // Socrata is all-time (no per-cycle filtering)
    source: 'LA_SOCRATA',
  };
}

/**
 * Writes the finance_summary JSONB to essentials.politicians.
 * The ::jsonb cast is mandatory — do not omit it.
 */
async function updateFinanceSummary(
  politicianId: string,
  summary: FinanceSummary
): Promise<void> {
  await pool.query(
    `UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2`,
    [JSON.stringify(summary), politicianId]
  );
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const startMs = Date.now();

  console.log('[write-la-city-finance-summary] Starting LA City Socrata finance summary ingestion...');

  const politicians = await getLACityPoliticiansWithSocrataSources();
  console.log(`[write-la-city-finance-summary] Found ${politicians.length} politicians with confirmed la_socrata sources.`);

  // Counters
  let processed = 0;
  let succeeded = 0;
  let skipped_no_data = 0;
  let errors = 0;
  const skippedNames: string[] = [];
  const errorDetails: Array<{ name: string; error: string }> = [];

  for (const p of politicians) {
    processed++;
    console.log(`\n[${processed}/${politicians.length}] ${p.full_name}`);

    try {
      const summary = await buildFinanceSummaryFromSocrata(p.id);

      if (!summary) {
        console.log(`  [SKIP] ${p.full_name} — no contributions found; leaving finance_summary = NULL`);
        skipped_no_data++;
        skippedNames.push(p.full_name);
        continue;
      }

      await updateFinanceSummary(p.id, summary);
      console.log(
        `  [OK] finance_summary written. total_raised=$${summary.total_raised.toLocaleString()} total_spent=$${(summary.total_spent ?? 0).toLocaleString()}`
      );
      succeeded++;
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : String(err);
      console.error(`  [ERROR] ${p.full_name}: ${errMsg}`);
      errors++;
      errorDetails.push({ name: p.full_name, error: errMsg });
    }
  }

  const durationSec = ((Date.now() - startMs) / 1000).toFixed(1);

  console.log('\n=== LA CITY SOCRATA FINANCE SUMMARY RUN COMPLETE ===');
  console.log(
    JSON.stringify({ processed, succeeded, skipped_no_data, errors, durationSec: Number(durationSec) })
  );

  if (skippedNames.length > 0) {
    console.log('\n--- Skipped officials (no contributions in Socrata) ---');
    for (const name of skippedNames) {
      console.log(`  - ${name}`);
    }
  }

  if (errorDetails.length > 0) {
    console.log('\n--- Errored officials ---');
    for (const e of errorDetails) {
      console.log(`  - ${e.name}: ${e.error}`);
    }
  }

  // Pool shutdown
  await pool.end();
  process.exit(0);
}

main().catch(async (err) => {
  console.error('[write-la-city-finance-summary] Fatal error:', err);
  try { await pool.end(); } catch { /* ignore pool close errors on fatal path */ }
  process.exit(1);
});
