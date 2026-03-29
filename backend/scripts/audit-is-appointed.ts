/**
 * audit-is-appointed.ts — is_appointed data quality audit
 *
 * Runs a two-tier audit against the production database to identify offices and
 * politicians with NULL or potentially misclassified is_appointed_position values.
 *
 * Purpose: Phase 100 (Elected/Appointed Filter) depends on accurate is_appointed data.
 * This audit identifies misclassifications before the filter UI ships.
 *
 * Design: READ-ONLY — no UPDATE, INSERT, DELETE, or ALTER statements.
 * Per D-09: report-then-fix approach. No automatic fixes applied.
 *
 * Usage:
 *   cd ev-accounts/backend && npx tsx scripts/audit-is-appointed.ts
 *
 * Output: Structured text report to stdout. Pipe to file for archiving:
 *   npx tsx scripts/audit-is-appointed.ts > /tmp/is-appointed-audit.txt
 */

import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const { Pool } = pg;

// ---------------------------------------------------------------------------
// Database connection
// ---------------------------------------------------------------------------

const DATABASE_URL = process.env['DATABASE_URL'];
if (!DATABASE_URL) {
  console.error('ERROR: DATABASE_URL environment variable is not set.');
  console.error('Set it in ev-accounts/backend/.env or pass it directly:');
  console.error('  DATABASE_URL="postgresql://..." npx tsx scripts/audit-is-appointed.ts');
  process.exit(1);
}

// Mask the URL for display (hide password)
function maskDatabaseUrl(url: string): string {
  try {
    const parsed = new URL(url);
    parsed.password = '***';
    return parsed.toString();
  } catch {
    return url.replace(/:[^:@]*@/, ':***@');
  }
}

const pool = new Pool({
  connectionString: DATABASE_URL,
  max: 3,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 10_000,
  ssl: { rejectUnauthorized: false },
});

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

function printHeader(title: string): void {
  const line = '='.repeat(72);
  console.log(`\n${line}`);
  console.log(` ${title}`);
  console.log(line);
}

function printSubHeader(title: string): void {
  const line = '-'.repeat(60);
  console.log(`\n${line}`);
  console.log(` ${title}`);
  console.log(line);
}

function formatTable(rows: Record<string, unknown>[], columns: string[]): void {
  if (rows.length === 0) {
    console.log('  (no results)');
    return;
  }

  // Calculate column widths
  const widths: Record<string, number> = {};
  for (const col of columns) {
    widths[col] = col.length;
    for (const row of rows) {
      const val = String(row[col] ?? 'NULL');
      if (val.length > widths[col]) widths[col] = Math.min(val.length, 40);
    }
  }

  // Print header row
  const header = columns.map(col => col.padEnd(widths[col]).slice(0, widths[col])).join(' | ');
  const separator = columns.map(col => '-'.repeat(widths[col])).join('-+-');
  console.log(`  ${header}`);
  console.log(`  ${separator}`);

  // Print data rows
  for (const row of rows) {
    const line = columns.map(col => {
      const val = String(row[col] ?? 'NULL');
      return val.padEnd(widths[col]).slice(0, widths[col]);
    }).join(' | ');
    console.log(`  ${line}`);
  }
}

// ---------------------------------------------------------------------------
// Audit queries — READ ONLY, no data modifications per D-09
// ---------------------------------------------------------------------------

async function runSummaryCounts(client: pg.PoolClient): Promise<{
  null_offices: number;
  appointed_offices: number;
  elected_offices: number;
  total_active_politicians: number;
}> {
  const officeCountRes = await client.query<{
    null_offices: string;
    appointed_offices: string;
    elected_offices: string;
  }>(`
    SELECT
      COUNT(*) FILTER (WHERE o.is_appointed_position IS NULL) AS null_offices,
      COUNT(*) FILTER (WHERE o.is_appointed_position = true) AS appointed_offices,
      COUNT(*) FILTER (WHERE o.is_appointed_position = false) AS elected_offices
    FROM essentials.offices o
  `);

  const politicianCountRes = await client.query<{ total_active_politicians: string }>(`
    SELECT COUNT(*) AS total_active_politicians
    FROM essentials.politicians WHERE is_active = true
  `);

  const row = officeCountRes.rows[0];
  const pRow = politicianCountRes.rows[0];
  return {
    null_offices: parseInt(row.null_offices, 10),
    appointed_offices: parseInt(row.appointed_offices, 10),
    elected_offices: parseInt(row.elected_offices, 10),
    total_active_politicians: parseInt(pRow.total_active_politicians, 10),
  };
}

async function runTier1OfficesAudit(client: pg.PoolClient): Promise<Record<string, unknown>[]> {
  // Find offices where is_appointed_position is NULL (these default to "elected" in current code
  // via: is_elected = NOT COALESCE(o.is_appointed_position, false))
  // OR offices classified as not-appointed in LOCAL-type districts (potential misclassification
  // since many LOCAL officials are appointed, not elected)
  const res = await client.query(`
    SELECT
      o.id AS office_id,
      o.title,
      o.is_appointed_position,
      d.district_type,
      ch.name AS chamber_name,
      g.name AS government_name,
      g.state,
      COUNT(p.id) AS politician_count
    FROM essentials.offices o
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.politicians p ON p.office_id = o.id AND p.is_active = true
    WHERE o.is_appointed_position IS NULL
       OR (o.is_appointed_position = false AND d.district_type IN ('LOCAL_EXEC','LOCAL','COUNTY'))
    GROUP BY o.id, o.title, o.is_appointed_position, d.district_type, ch.name, g.name, g.state
    ORDER BY g.state, g.name, o.title
  `);
  return res.rows;
}

async function runTier1NullOnly(client: pg.PoolClient): Promise<Record<string, unknown>[]> {
  // Separate query: ONLY offices with NULL is_appointed_position (the high-priority finding)
  const res = await client.query(`
    SELECT
      o.id AS office_id,
      o.title,
      o.is_appointed_position,
      d.district_type,
      ch.name AS chamber_name,
      g.name AS government_name,
      g.state,
      COUNT(p.id) AS politician_count
    FROM essentials.offices o
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.politicians p ON p.office_id = o.id AND p.is_active = true
    WHERE o.is_appointed_position IS NULL
    GROUP BY o.id, o.title, o.is_appointed_position, d.district_type, ch.name, g.name, g.state
    ORDER BY g.state, g.name, o.title
  `);
  return res.rows;
}

async function runTier2PoliticiansAudit(client: pg.PoolClient): Promise<Record<string, unknown>[]> {
  // Find active politicians where:
  // 1. politicians.is_appointed disagrees with offices.is_appointed_position (mismatch), OR
  // 2. office classification is NULL (unclassified)
  const res = await client.query(`
    SELECT
      p.id AS politician_id,
      p.full_name,
      p.is_appointed AS politician_is_appointed,
      o.is_appointed_position AS office_is_appointed,
      p.data_source,
      p.last_synced,
      o.title AS office_title,
      ch.name AS chamber_name,
      g.name AS government_name
    FROM essentials.politicians p
    LEFT JOIN essentials.offices o ON o.politician_id = p.id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    WHERE p.is_active = true
      AND (
        (p.is_appointed = true AND o.is_appointed_position = false)
        OR (p.is_appointed = false AND o.is_appointed_position = true)
        OR o.is_appointed_position IS NULL
      )
    ORDER BY g.state, g.name, p.full_name
  `);
  return res.rows;
}

async function runTier2MismatchOnly(client: pg.PoolClient): Promise<Record<string, unknown>[]> {
  // Only direct mismatches (politician says appointed but office says elected, or vice versa)
  const res = await client.query(`
    SELECT
      p.id AS politician_id,
      p.full_name,
      p.is_appointed AS politician_is_appointed,
      o.is_appointed_position AS office_is_appointed,
      p.data_source,
      o.title AS office_title,
      g.name AS government_name
    FROM essentials.politicians p
    LEFT JOIN essentials.offices o ON o.politician_id = p.id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    WHERE p.is_active = true
      AND (
        (p.is_appointed = true AND o.is_appointed_position = false)
        OR (p.is_appointed = false AND o.is_appointed_position = true)
      )
    ORDER BY g.state, g.name, p.full_name
  `);
  return res.rows;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const timestamp = new Date().toISOString();

  printHeader('is_appointed Data Quality Audit');
  console.log(`\n  Run date:  ${timestamp}`);
  console.log(`  Database:  ${maskDatabaseUrl(DATABASE_URL!)}`);
  console.log(`  Purpose:   Identify offices/politicians with NULL or misclassified`);
  console.log(`             is_appointed_position before Phase 100 (Filter UI) ships`);
  console.log(`\n  IMPORTANT: READ-ONLY audit. No data modifications per D-09.`);
  console.log(`             is_elected is derived as NOT COALESCE(o.is_appointed_position, false)`);
  console.log(`             NULL is_appointed_position defaults to FALSE = treated as "elected"`);

  const client = await pool.connect();

  try {
    // -------------------------------------------------------------------------
    // Summary counts
    // -------------------------------------------------------------------------
    printHeader('Summary Counts');

    const summary = await runSummaryCounts(client);
    console.log(`\n  Total active politicians:              ${summary.total_active_politicians}`);
    console.log(`  Total offices:`);
    console.log(`    - NULL is_appointed_position:        ${summary.null_offices}  ← THESE DEFAULT TO "ELECTED"`);
    console.log(`    - Classified as APPOINTED (true):    ${summary.appointed_offices}`);
    console.log(`    - Classified as ELECTED (false):     ${summary.elected_offices}`);
    console.log(`    - TOTAL offices:                     ${summary.null_offices + summary.appointed_offices + summary.elected_offices}`);

    // -------------------------------------------------------------------------
    // Tier 1: Office-level audit
    // -------------------------------------------------------------------------
    printHeader('TIER 1: Office-Level Audit');

    // 1a: NULL-only offices (highest priority)
    printSubHeader('1a: Offices with NULL is_appointed_position (default to "elected")');
    console.log(`  NOTE: These ${summary.null_offices} offices are treated as "elected" via COALESCE(is_appointed_position, false)`);
    console.log(`  If any are actually appointed positions, Phase 100 filter will misclassify them.\n`);

    const tier1NullRows = await runTier1NullOnly(client);
    formatTable(tier1NullRows, [
      'office_id', 'title', 'district_type', 'government_name', 'state', 'politician_count'
    ]);

    // 1b: All tier 1 (NULL + potentially misclassified local)
    printSubHeader('1b: All Tier 1 findings (NULL + potentially-wrong local offices)');
    console.log(`  Includes offices with is_appointed_position = false in LOCAL/COUNTY district types.`);
    console.log(`  These may be legitimately elected, but warrant spot-check review.\n`);

    const tier1AllRows = await runTier1OfficesAudit(client);
    formatTable(tier1AllRows, [
      'office_id', 'title', 'is_appointed_position', 'district_type', 'government_name', 'state', 'politician_count'
    ]);

    // -------------------------------------------------------------------------
    // Tier 2: Politician-level audit
    // -------------------------------------------------------------------------
    printHeader('TIER 2: Politician-Level Audit');

    // 2a: Direct mismatches only
    printSubHeader('2a: Direct mismatches (politician.is_appointed ≠ office.is_appointed_position)');
    console.log(`  These are edge cases: e.g., an interim appointment to a normally-elected seat.\n`);

    const tier2MismatchRows = await runTier2MismatchOnly(client);
    formatTable(tier2MismatchRows, [
      'politician_id', 'full_name', 'politician_is_appointed', 'office_is_appointed',
      'office_title', 'government_name', 'data_source'
    ]);

    // 2b: All tier 2 (mismatches + NULL office)
    printSubHeader('2b: All active politicians with NULL or mismatched office classification');
    console.log(`  Includes politicians whose office has NULL is_appointed_position.\n`);

    const tier2AllRows = await runTier2PoliticiansAudit(client);
    formatTable(tier2AllRows, [
      'politician_id', 'full_name', 'politician_is_appointed', 'office_is_appointed',
      'office_title', 'government_name', 'data_source'
    ]);

    // -------------------------------------------------------------------------
    // Final summary
    // -------------------------------------------------------------------------
    printHeader('Audit Complete');
    console.log(`\n  Summary:`);
    console.log(`    NULL offices (default to elected):   ${summary.null_offices}`);
    console.log(`    Direct politician/office mismatches: ${tier2MismatchRows.length}`);
    console.log(`    Total politicians affected:          ${tier2AllRows.length}`);
    console.log(`    Total active politicians:            ${summary.total_active_politicians}`);
    console.log(`\n  Next steps:`);
    console.log(`    1. Review IS_APPOINTED_AUDIT.md for backfill plan`);
    console.log(`    2. Fix Priority 1 offices before Phase 100 ships`);
    console.log(`    3. Direct mismatches need case-by-case review`);
    console.log(`\n  No data was modified. This was a read-only audit per D-09.\n`);

  } finally {
    client.release();
    await pool.end();
  }

  process.exit(0);
}

main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error(`\nAUDIT FAILED: ${message}`);
  if (err instanceof Error && err.stack) {
    console.error(err.stack);
  }
  process.exit(1);
});
