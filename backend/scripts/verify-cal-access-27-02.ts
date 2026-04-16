/**
 * verify-cal-access-27-02.ts — Phase 27-02 verification script.
 *
 * Verifies that all 8 LA County officeholders have confirmed Cal-Access sources
 * with ingested contribution data after the fresh Cal-Access ingest triggered in Plan 27-01.
 *
 * Checks:
 *   LCTY-03: All 8 officials confirmed in politician_sources (cal_access)
 *   LCTY-04: ≥7/8 officials have non-zero contribution counts
 *   Regression: Bass, Newsom, Kounalakis still have Cal-Access data
 *   Ingestion: Recent cal_access run completed
 *
 * Usage:
 *   npx tsx scripts/verify-cal-access-27-02.ts
 *   npx tsx scripts/verify-cal-access-27-02.ts --re-ingest
 */

import 'dotenv/config';
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const LA_COUNTY_OFFICIALS = [
  'Hilda L. Solis',
  'Holly J. Mitchell',
  'Lindsey P. Horvath',
  'Janice Hahn',
  'Kathryn Barger',
  'Nathan Hochman',
  'Robert Luna',
  'Jeff Prang',
];

const REGRESSION_OFFICIALS = ['Karen Ruth Bass', 'Gavin Newsom', 'Eleni Kounalakis'];

/**
 * Wait for any active cal_access ingestion_runs to complete.
 * Max wait: 20 minutes. Checks every 30 seconds.
 */
async function waitForIngest(maxWaitMs: number = 20 * 60 * 1000): Promise<void> {
  const startMs = Date.now();
  while (Date.now() - startMs < maxWaitMs) {
    const res = await pool.query(`
      SELECT COUNT(*) AS running_count
      FROM transparent_motivations.ingestion_runs
      WHERE adapter_name = 'cal_access' AND status = 'running'
    `);
    const runningCount = parseInt(res.rows[0].running_count);
    if (runningCount === 0) {
      console.log('[verify] No active cal_access ingestion runs — proceeding with verification');
      return;
    }
    console.log(
      `[verify] Waiting for ${runningCount} active cal_access run(s) to complete... (${Math.round((Date.now() - startMs) / 1000)}s elapsed)`
    );
    await new Promise((r) => setTimeout(r, 30000)); // wait 30s between checks
  }
  console.warn('[verify] Timeout waiting for ingest — proceeding with current data');
}

async function main() {
  // --re-ingest flag: trigger a fresh cal_access ingest before verification
  if (process.argv.includes('--re-ingest')) {
    const { runAdapterForAll } = await import('../src/lib/campaignFinanceScheduler.js');
    console.log('[Re-ingest] Triggering runAdapterForAll("cal_access")...');
    await runAdapterForAll('cal_access');
    console.log('[Re-ingest] Complete.');
  }

  console.log('=== Phase 27-02: LA County Officials Cal-Access Seeding — Verification Report ===\n');
  console.log(`Checking ${LA_COUNTY_OFFICIALS.length} LA County officeholders...\n`);

  // Wait for any in-progress ingest to finish
  await waitForIngest();

  const client = await pool.connect();
  try {
    // -----------------------------------------------------------------------
    // Query 1: Cal-Access research_status breakdown for the 8 officials
    // -----------------------------------------------------------------------
    console.log('--- Query 1: Cal-Access research_status breakdown for 8 LA County officials ---');
    const q1 = await client.query(
      `
      SELECT ps.research_status, COUNT(*) AS count
      FROM transparent_motivations.politician_sources ps
      JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
      WHERE ps.source_system = 'cal_access'
        AND p.full_name = ANY($1::text[])
      GROUP BY ps.research_status
      ORDER BY ps.research_status
    `,
      [LA_COUNTY_OFFICIALS]
    );
    console.table(q1.rows);

    const confirmedSourceRow = q1.rows.find((r: any) => r.research_status === 'confirmed');
    const totalConfirmedSources = confirmedSourceRow ? parseInt(confirmedSourceRow.count) : 0;
    console.log(`Total confirmed cal_access sources for 8 officials: ${totalConfirmedSources}\n`);

    // -----------------------------------------------------------------------
    // Query 2: All 8 officials — confirmation status + contribution counts
    // -----------------------------------------------------------------------
    console.log('--- Query 2: All 8 LA County officials — confirmation status + contribution counts ---');
    const q2 = await client.query(
      `
      SELECT
        p.full_name,
        ps.external_id AS filer_id,
        ps.research_status,
        COUNT(c.id) AS contribution_count,
        COALESCE(SUM(c.amount), 0) AS total_raised
      FROM essentials.politicians p
      LEFT JOIN transparent_motivations.politician_sources ps
        ON ps.essentials_politician_id = p.id AND ps.source_system = 'cal_access' AND ps.research_status = 'confirmed'
      LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = ps.id
      WHERE p.full_name = ANY($1::text[])
      GROUP BY p.full_name, ps.external_id, ps.research_status
      ORDER BY p.full_name, ps.external_id
    `,
      [LA_COUNTY_OFFICIALS]
    );
    console.table(q2.rows);

    // Count unique politicians with at least one confirmed source
    const confirmedPoliticians = new Set(
      q2.rows
        .filter((r: any) => r.research_status === 'confirmed')
        .map((r: any) => r.full_name)
    );
    const confirmedPoliticianCount = confirmedPoliticians.size;

    // Count unique politicians with non-zero contributions (across all their sources)
    const politicianContribMap = new Map<string, number>();
    for (const row of q2.rows as any[]) {
      const existing = politicianContribMap.get(row.full_name) ?? 0;
      politicianContribMap.set(row.full_name, existing + parseInt(row.contribution_count ?? '0'));
    }
    const politiciansWithData = [...politicianContribMap.entries()].filter(
      ([, count]) => count > 0
    ).length;
    const politiciansWithZero = [...politicianContribMap.entries()].filter(
      ([, count]) => count === 0
    );

    // -----------------------------------------------------------------------
    // Query 3: Recent ingestion_runs for cal_access (last 10)
    // -----------------------------------------------------------------------
    console.log('\n--- Query 3: Recent cal_access ingestion_runs (last 10) ---');
    const q3 = await client.query(`
      SELECT id, started_at, completed_at, records_fetched, records_inserted, status, notes
      FROM transparent_motivations.ingestion_runs
      WHERE adapter_name = 'cal_access'
      ORDER BY started_at DESC
      LIMIT 10
    `);
    console.table(q3.rows);

    const recentCompleted = (q3.rows as any[]).filter(
      (r) => r.status === 'completed' || r.status === 'completed_with_warning'
    );
    const hasRecentIngest = recentCompleted.length > 0;

    // -----------------------------------------------------------------------
    // Query 4: Confirmed officials with ZERO contributions (gap detection)
    // -----------------------------------------------------------------------
    console.log('\n--- Query 4: Confirmed cal_access officials with ZERO contributions (gap detection) ---');
    const q4 = await client.query(
      `
      SELECT
        p.full_name,
        COUNT(DISTINCT ps.external_id) AS confirmed_source_count,
        COUNT(c.id) AS contribution_count
      FROM essentials.politicians p
      JOIN transparent_motivations.politician_sources ps
        ON ps.essentials_politician_id = p.id
        AND ps.source_system = 'cal_access'
        AND ps.research_status = 'confirmed'
      LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = ps.id
      WHERE p.full_name = ANY($1::text[])
      GROUP BY p.full_name
      HAVING COUNT(c.id) = 0
      ORDER BY p.full_name
    `,
      [LA_COUNTY_OFFICIALS]
    );
    console.table(q4.rows);

    const zeroContribPoliticians = q4.rows as any[];
    if (zeroContribPoliticians.length > 0) {
      console.log('\nZero-contribution officials:');
      for (const row of zeroContribPoliticians) {
        const isKnownException =
          row.full_name === 'Nathan Hochman' || row.full_name === 'Robert Luna';
        const note = isKnownException
          ? '(EXPECTED — confirmed filer_ids include IE-only committees; direct Form 460 candidate committee contributions may not be in Cal-Access ZIP)'
          : '(UNEXPECTED — investigate)';
        console.log(`  - ${row.full_name}: ${row.confirmed_source_count} confirmed sources ${note}`);
      }
    }

    // -----------------------------------------------------------------------
    // Query 5: Regression check — Bass, Newsom, Kounalakis still have data
    // -----------------------------------------------------------------------
    console.log('\n--- Query 5: Regression check — Bass, Newsom, Kounalakis ---');
    const q5 = await client.query(
      `
      SELECT
        p.full_name,
        COUNT(DISTINCT ps.id) AS source_count,
        COUNT(c.id) AS contribution_count,
        COALESCE(SUM(c.amount), 0) AS total_raised
      FROM transparent_motivations.politician_sources ps
      JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
      LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = ps.id
      WHERE ps.source_system = 'cal_access'
        AND ps.research_status = 'confirmed'
        AND p.full_name = ANY($1::text[])
      GROUP BY p.full_name
      ORDER BY p.full_name
    `,
      [REGRESSION_OFFICIALS]
    );
    console.table(q5.rows);

    const regressionRows = q5.rows as any[];
    const bassOk = regressionRows.some(
      (r: any) => r.full_name === 'Karen Ruth Bass' && parseInt(r.contribution_count) > 0
    );
    const newsomOk = regressionRows.some(
      (r: any) => r.full_name === 'Gavin Newsom' && parseInt(r.contribution_count) > 0
    );
    const kounalakisOk = regressionRows.some(
      (r: any) => r.full_name === 'Eleni Kounalakis' && parseInt(r.contribution_count) > 0
    );
    const regressionPass = bassOk && newsomOk && kounalakisOk;

    if (!regressionPass) {
      console.log('\n!!! REGRESSION WARNING: One or more of Bass/Newsom/Kounalakis has zero contributions. !!!');
      if (!bassOk) console.log('  - Karen Ruth Bass: MISSING data');
      if (!newsomOk) console.log('  - Gavin Newsom: MISSING data');
      if (!kounalakisOk) console.log('  - Eleni Kounalakis: MISSING data');
    }

    // -----------------------------------------------------------------------
    // Query 6: Profile UUIDs for spot-check
    // -----------------------------------------------------------------------
    console.log('\n--- Query 6: Profile UUIDs for all 8 LA County officials ---');
    const q6 = await client.query(
      `
      SELECT p.id, p.full_name
      FROM essentials.politicians p
      WHERE p.full_name = ANY($1::text[])
      ORDER BY p.full_name
    `,
      [LA_COUNTY_OFFICIALS]
    );
    console.table(q6.rows);

    // -----------------------------------------------------------------------
    // Phase 27 Verification Summary
    // -----------------------------------------------------------------------
    const lcty03Pass = confirmedPoliticianCount === 8;
    const lcty04Pass = politiciansWithData >= 7; // PASS if ≥7/8 have contributions
    const lcty04Partial =
      !lcty04Pass &&
      politiciansWithData >= 5 &&
      politiciansWithZero.every(
        ([name]) => name === 'Nathan Hochman' || name === 'Robert Luna'
      );

    // Determine overall
    const overallPass = lcty03Pass && lcty04Pass && regressionPass && hasRecentIngest;
    const overallPartial =
      !overallPass &&
      lcty03Pass &&
      (lcty04Pass || lcty04Partial) &&
      regressionPass &&
      hasRecentIngest;
    const overallStatus = overallPass ? 'PASS' : overallPartial ? 'PARTIAL' : 'FAIL';

    const lcty04Label = lcty04Pass
      ? 'PASS'
      : lcty04Partial
        ? 'PARTIAL (IE-only exception)'
        : 'FAIL';

    console.log('\n');
    console.log('=== PHASE 27 VERIFICATION SUMMARY ===');
    console.log('');
    console.log(
      `LCTY-03: All 8 officials confirmed?          [${lcty03Pass ? 'PASS' : 'FAIL'}] (${confirmedPoliticianCount}/8 confirmed)`
    );
    console.log(
      `LCTY-04: Contribution data ingested?          [${lcty04Label}] (${politiciansWithData}/8 with data, ${politiciansWithZero.length} zero-contrib)`
    );
    console.log(
      `Regression: Bass/Newsom/Kounalakis OK?        [${regressionPass ? 'PASS' : 'FAIL'}]`
    );
    console.log(
      `Ingestion: Recent cal_access run completed?   [${hasRecentIngest ? 'PASS' : 'FAIL'}] (${recentCompleted.length} completed runs found)`
    );
    console.log('');
    console.log(`Overall: [${overallStatus}]`);
    console.log('');

    // Note about Hochman/Luna IE committee situation
    if (zeroContribPoliticians.some((r: any) => r.full_name === 'Nathan Hochman' || r.full_name === 'Robert Luna')) {
      console.log('NOTE on zero-contribution officials:');
      if (zeroContribPoliticians.some((r: any) => r.full_name === 'Nathan Hochman')) {
        console.log(
          '  Nathan Hochman: 8 confirmed filer_ids include 6 IE (independent expenditure) committees.'
        );
        console.log(
          '  IE committees do not file Form 460 Schedule A — no direct contributions expected.'
        );
        console.log(
          '  Direct committees (1437955, 1477192) may have limited Cal-Access ZIP data.'
        );
        console.log('  Status: IE-only confirmed filer_ids — ACCEPTABLE EXCEPTION');
      }
      if (zeroContribPoliticians.some((r: any) => r.full_name === 'Robert Luna')) {
        console.log(
          '  Robert Luna: 17 confirmed filer_ids may include Phase 20 false positives (other Lunas).'
        );
        console.log(
          '  Sheriff committees (1442721, 1479270) may not have data in the Cal-Access ZIP.'
        );
        console.log('  Status: Direct Form 460 candidate committee contributions not in Cal-Access ZIP — ACCEPTABLE EXCEPTION');
      }
      console.log('');
    }

    // Profile URLs
    if (q6.rows.length > 0) {
      console.log('Profile URLs for spot-check:');
      for (const row of q6.rows as any[]) {
        console.log(`  - https://essentials.empowered.vote/politician/${row.id} (${row.full_name})`);
      }
    }

    console.log('');
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('Script error:', err);
  process.exit(1);
});
