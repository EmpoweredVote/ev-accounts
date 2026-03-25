/**
 * importTransactions.ts — Import transaction CSV into treasury.transactions + treasury.vendors.
 *
 * Reads a Bloomington-format payroll/transaction CSV and bulk-inserts into Supabase.
 * Vendors are upserted first, then transactions reference vendor UUIDs.
 *
 * The link_key is generated from: priority|service|fund|expense_category (all lowercase)
 * to match the existing budget_categories.link_key convention.
 *
 * Usage:
 *   DATABASE_URL="postgresql://..." npx tsx backend/scripts/importTransactions.ts <csv_path> [--year 2025]
 *
 * Options:
 *   --year <YYYY>   Only import rows for this fiscal year (default: all years)
 *   --dry-run       Print stats without inserting
 */

import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const { Pool } = pg;

// ---------------------------------------------------------------------------
// CSV parser (handles quoted fields with commas)
// ---------------------------------------------------------------------------
function parseCSVLine(line: string): string[] {
  const values: string[] = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === ',' && !inQuotes) {
      values.push(current.trim());
      current = '';
    } else {
      current += char;
    }
  }
  values.push(current.trim());
  return values;
}

function parseCSV(content: string): Record<string, string>[] {
  const lines = content.split('\n').filter(l => l.trim());
  const headers = parseCSVLine(lines[0]);
  const rows: Record<string, string>[] = [];

  for (let i = 1; i < lines.length; i++) {
    const values = parseCSVLine(lines[i]);
    if (values.length === headers.length) {
      const row: Record<string, string> = {};
      headers.forEach((h, idx) => { row[h] = values[idx]; });
      rows.push(row);
    }
  }
  return rows;
}

// ---------------------------------------------------------------------------
// Link key generation (matches processTransactions.js convention)
// ---------------------------------------------------------------------------
function generateLinkKey(row: Record<string, string>): string | null {
  const priority = (row['Priority'] || '').toLowerCase().trim();
  const service = (row['Service'] || '').toLowerCase().trim();
  const fund = (row['Fund'] || '').toLowerCase().trim();
  const expCat = (row['Expense Category'] || '').toLowerCase().trim();

  // Build the most specific key available
  const parts = [priority, service, fund, expCat].filter(Boolean);
  return parts.length > 0 ? parts.join('|') : null;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  const args = process.argv.slice(2);
  const csvPath = args.find(a => !a.startsWith('--'));
  const yearFlag = args.indexOf('--year');
  const filterYear = yearFlag !== -1 ? args[yearFlag + 1] : null;
  const dryRun = args.includes('--dry-run');

  if (!csvPath) {
    console.error('Usage: npx tsx backend/scripts/importTransactions.ts <csv_path> [--year YYYY] [--dry-run]');
    process.exit(1);
  }

  if (!fs.existsSync(csvPath)) {
    console.error(`File not found: ${csvPath}`);
    process.exit(1);
  }

  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    console.error('DATABASE_URL environment variable is required');
    process.exit(1);
  }

  console.log(`Reading ${csvPath}...`);
  const content = fs.readFileSync(csvPath, 'utf-8');
  let rows = parseCSV(content);
  console.log(`Parsed ${rows.length} total rows`);

  if (filterYear) {
    rows = rows.filter(r => r['Fiscal_Year'] === filterYear);
    console.log(`Filtered to ${rows.length} rows for FY${filterYear}`);
  }

  if (rows.length === 0) {
    console.log('No rows to import.');
    return;
  }

  // Summarize
  const years = [...new Set(rows.map(r => r['Fiscal_Year']))].sort();
  const vendors = [...new Set(rows.map(r => r['Vendor']).filter(Boolean))];
  console.log(`\nYears: ${years.join(', ')}`);
  console.log(`Unique vendors: ${vendors.length}`);
  console.log(`Transactions: ${rows.length}`);

  if (dryRun) {
    console.log('\n--dry-run: skipping database insert');
    return;
  }

  const pool = new Pool({ connectionString: databaseUrl });

  try {
    // Step 1: Find Bloomington municipality
    const { rows: muniRows } = await pool.query(
      `SELECT id FROM treasury.municipalities WHERE LOWER(name) = 'bloomington' AND LOWER(state) = 'in'`
    );
    if (muniRows.length === 0) {
      console.error('Bloomington, IN not found in treasury.municipalities');
      process.exit(1);
    }
    const municipalityId = muniRows[0].id;
    console.log(`\nMunicipality ID: ${municipalityId}`);

    // Step 2: Find budget IDs for each fiscal year (operating dataset)
    const budgetMap = new Map<string, string>();
    for (const year of years) {
      const { rows: budgetRows } = await pool.query(
        `SELECT id FROM treasury.budgets
         WHERE municipality_id = $1 AND fiscal_year = $2 AND dataset_type = 'operating'`,
        [municipalityId, parseInt(year)]
      );
      if (budgetRows.length > 0) {
        budgetMap.set(year, budgetRows[0].id);
        console.log(`Budget for FY${year}: ${budgetRows[0].id}`);
      } else {
        console.warn(`No operating budget found for FY${year} — transactions for this year will be skipped`);
      }
    }

    // Step 3: Upsert vendors in batches
    console.log(`\nUpserting ${vendors.length} vendors...`);

    // Build vendor external ID map
    const vendorExtIds = new Map<string, string>();
    for (const row of rows) {
      if (row['Vendor'] && row['Vendor_Id']) {
        vendorExtIds.set(row['Vendor'], row['Vendor_Id']);
      }
    }

    const VENDOR_BATCH = 500;
    const vendorIdMap = new Map<string, string>(); // vendor name → UUID

    for (let i = 0; i < vendors.length; i += VENDOR_BATCH) {
      const batch = vendors.slice(i, i + VENDOR_BATCH);
      const values: string[] = [];
      const params: any[] = [];
      let paramIdx = 1;

      for (const name of batch) {
        values.push(`($${paramIdx}, $${paramIdx + 1}, $${paramIdx + 2})`);
        params.push(municipalityId, name, vendorExtIds.get(name) || null);
        paramIdx += 3;
      }

      const result = await pool.query(
        `INSERT INTO treasury.vendors (municipality_id, name, external_id)
         VALUES ${values.join(', ')}
         ON CONFLICT (municipality_id, name) DO UPDATE SET external_id = COALESCE(EXCLUDED.external_id, treasury.vendors.external_id)
         RETURNING id, name`,
        params
      );

      for (const row of result.rows) {
        vendorIdMap.set(row.name, row.id);
      }

      if ((i + VENDOR_BATCH) % 2000 === 0 || i + VENDOR_BATCH >= vendors.length) {
        console.log(`  Vendors: ${Math.min(i + VENDOR_BATCH, vendors.length)}/${vendors.length}`);
      }
    }
    console.log(`Upserted ${vendorIdMap.size} vendors`);

    // Step 4: Insert transactions in batches
    console.log(`\nInserting ${rows.length} transactions...`);

    const TX_BATCH = 500;
    let inserted = 0;
    let skipped = 0;

    for (let i = 0; i < rows.length; i += TX_BATCH) {
      const batch = rows.slice(i, i + TX_BATCH);
      const values: string[] = [];
      const params: any[] = [];
      let paramIdx = 1;

      for (const row of batch) {
        const budgetId = budgetMap.get(row['Fiscal_Year']);
        if (!budgetId) {
          skipped++;
          continue;
        }

        const vendorName = row['Vendor'] || null;
        const vendorUuid = vendorName ? vendorIdMap.get(vendorName) || null : null;
        const linkKey = generateLinkKey(row);
        const amount = parseFloat(row['Amount']) || 0;
        const paymentDate = row['Payment Date'] ? row['Payment Date'].split('T')[0] : null;
        const fiscalPeriod = row['Fiscal_Period'] ? parseInt(row['Fiscal_Period']) : null;

        values.push(`($${paramIdx}, $${paramIdx + 1}, $${paramIdx + 2}, $${paramIdx + 3}, $${paramIdx + 4}, $${paramIdx + 5}, $${paramIdx + 6}, $${paramIdx + 7}, $${paramIdx + 8}, $${paramIdx + 9}, $${paramIdx + 10}, $${paramIdx + 11}, $${paramIdx + 12}, $${paramIdx + 13}, $${paramIdx + 14}, $${paramIdx + 15})`);
        params.push(
          budgetId,
          vendorUuid,
          linkKey,
          amount,
          row['Description'] || null,
          paymentDate,
          fiscalPeriod,
          row['Payment_Method'] || null,
          row['Payment Number'] || null,
          row['InvoiceNumber'] || null,
          row['Fund'] || null,
          row['Expense Category'] || null,
          row['Expense Account'] || null,
          row['Priority'] || null,
          row['Service'] || null,
          row['Department'] || null
        );
        paramIdx += 16;
      }

      if (values.length > 0) {
        await pool.query(
          `INSERT INTO treasury.transactions
           (budget_id, vendor_id, link_key, amount, description, payment_date, fiscal_period,
            payment_method, payment_number, invoice_number, fund, expense_category, expense_account,
            priority, service, department)
           VALUES ${values.join(', ')}`,
          params
        );
        inserted += values.length;
      }

      if ((i + TX_BATCH) % 10000 === 0 || i + TX_BATCH >= rows.length) {
        console.log(`  Progress: ${Math.min(i + TX_BATCH, rows.length)}/${rows.length} (inserted: ${inserted}, skipped: ${skipped})`);
      }
    }

    console.log(`\nDone! Inserted ${inserted} transactions, skipped ${skipped} (no matching budget)`);

  } finally {
    await pool.end();
  }
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
