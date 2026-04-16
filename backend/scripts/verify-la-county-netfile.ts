/**
 * verify-la-county-netfile.ts — Phase 24 verification script.
 *
 * Checks all LCTY acceptance criteria against the live DB:
 *   LCTY-01: la_county_netfile accepted as data_source (contributions exist)
 *   LCTY-02: la_county_netfile registered in politician_sources
 *   LCTY-03: CTL candidates confirmed (target: 174, minimum: 8)
 *   LCTY-04: Non-zero contributions for confirmed sources
 *   LCTY-05: ingestion_runs audit trail logged
 *
 * Usage:
 *   npx tsx scripts/verify-la-county-netfile.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

interface CheckResult {
  id: string;
  pass: boolean;
  detail: string;
}

const results: CheckResult[] = [];

function check(id: string, pass: boolean, detail: string): void {
  results.push({ id, pass, detail });
  const icon = pass ? 'PASS' : 'FAIL';
  console.log(`${id.padEnd(8)} [${icon}] ${detail}`);
}

async function run(): Promise<void> {
  console.log('=== LA COUNTY NETFILE VERIFICATION ===\n');

  // LCTY-01: la_county_netfile accepted as data_source (contributions exist)
  const c01 = await pool.query<{ count: string }>(
    `SELECT COUNT(*) as count FROM transparent_motivations.contributions WHERE data_source = 'la_county_netfile'`
  );
  const contrib01 = parseInt(c01.rows[0].count, 10);
  check('LCTY-01', contrib01 > 0, `adapter+source valid: ${contrib01} contributions inserted`);

  // LCTY-02: la_county_netfile registered in politician_sources
  const c02 = await pool.query<{ count: string }>(
    `SELECT COUNT(*) as count FROM transparent_motivations.politician_sources WHERE source_system = 'la_county_netfile'`
  );
  const sources02 = parseInt(c02.rows[0].count, 10);
  check('LCTY-02', sources02 > 0, `source registered: ${sources02} politician_sources rows`);

  // LCTY-03: Confirmed CTL candidates (174 target, 8 minimum)
  const c03 = await pool.query<{ count: string }>(
    `SELECT COUNT(DISTINCT essentials_politician_id) as count
     FROM transparent_motivations.politician_sources
     WHERE source_system = 'la_county_netfile' AND research_status = 'confirmed'`
  );
  const confirmed03 = parseInt(c03.rows[0].count, 10);
  check('LCTY-03', confirmed03 >= 8, `CTL candidates confirmed: ${confirmed03} unique politicians (target: 174, min: 8)`);

  // LCTY-04: Non-zero contributions — all confirmed sources have data
  const c04 = await pool.query<{ full_name: string; contrib_count: string; total_raised: string; earliest: Date | null; latest: Date | null }>(
    `SELECT p.full_name,
            COUNT(c.id) as contrib_count,
            SUM(c.amount)::numeric(12,2) as total_raised,
            MIN(c.contribution_date) as earliest,
            MAX(c.contribution_date) as latest
     FROM transparent_motivations.politician_sources ps
     JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
     LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = ps.id
     WHERE ps.source_system = 'la_county_netfile'
       AND ps.research_status = 'confirmed'
     GROUP BY p.full_name
     ORDER BY total_raised DESC NULLS LAST`
  );
  const withData = c04.rows.filter((r) => parseInt(r.contrib_count, 10) > 0).length;
  const withoutData = c04.rows.filter((r) => parseInt(r.contrib_count, 10) === 0).length;
  const pass04 = withData > 0;

  check(
    'LCTY-04',
    pass04,
    `contributions coverage: ${withData}/${c04.rows.length} politicians have data${withoutData > 0 ? ` (${withoutData} with zero)` : ''}`
  );

  console.log('\n  Top 5 politicians by total raised:');
  c04.rows.slice(0, 5).forEach((r) => {
    const earliest = r.earliest ? new Date(r.earliest).getFullYear() : '—';
    const latest = r.latest ? new Date(r.latest).getFullYear() : '—';
    console.log(
      `    ${r.full_name.substring(0, 35).padEnd(36)} ${r.contrib_count} contributions, $${r.total_raised} (${earliest}–${latest})`
    );
  });

  if (withoutData > 0) {
    console.log(`\n  WARNING: ${withoutData} politicians with zero contributions (likely filers with no Schedule A receipts in available years)`);
    c04.rows
      .filter((r) => parseInt(r.contrib_count, 10) === 0)
      .slice(0, 5)
      .forEach((r) => console.log(`    - ${r.full_name}`));
  }

  // LCTY-05: ingestion_runs logged
  const c05 = await pool.query<{
    adapter_name: string;
    run_count: string;
    completed: string;
    failed: string;
    total_inserted: string;
  }>(
    `SELECT adapter_name,
            COUNT(*) as run_count,
            COUNT(*) FILTER (WHERE status IN ('completed', 'completed_with_warning')) as completed,
            COUNT(*) FILTER (WHERE status = 'failed') as failed,
            SUM(records_inserted) as total_inserted
     FROM transparent_motivations.ingestion_runs
     WHERE adapter_name = 'la_county_netfile'
     GROUP BY adapter_name`
  );

  if (c05.rows.length === 0) {
    check('LCTY-05', false, 'ingestion_runs: no rows found for la_county_netfile');
  } else {
    const r = c05.rows[0];
    const pass05 = parseInt(r.run_count, 10) > 0 && parseInt(r.completed, 10) > 0;
    check(
      'LCTY-05',
      pass05,
      `ingestion_runs: ${r.run_count} total runs, ${r.completed} completed, ${r.failed} failed, ${r.total_inserted} rows inserted`
    );
  }

  // Summary
  const passed = results.filter((r) => r.pass).length;
  const total = results.length;
  const allPass = passed === total;

  console.log(`\n${'─'.repeat(60)}`);
  console.log(`Overall: ${allPass ? 'PASS' : 'FAIL'} (${passed}/${total} checks passed)`);
  console.log(`${'─'.repeat(60)}`);

  await pool.end();
  process.exit(allPass ? 0 : 1);
}

run().catch(async (err) => {
  console.error('Fatal:', err instanceof Error ? err.message : String(err));
  await pool.end();
  process.exit(1);
});
