/**
 * importCambridge.ts — Fetch Cambridge, MA budget data from Socrata API and import
 * into the treasury schema.
 *
 * Datasets (all from data.cambridgema.gov):
 *   - Operating Expenditures (5bn4-5wey): budget line items by dept/division/category
 *   - Operating Revenues (ixyv-mje6): revenue line items
 *   - Salaries (ixg8-tyau): budgeted positions with job titles
 *
 * Hierarchy mapping:
 *   Expenditures: service → department_name → division_name → category → (line items by description)
 *   Revenue:      service → category → (line items by description)
 *
 * Usage:
 *   DATABASE_URL="postgresql://..." npx tsx backend/scripts/importCambridge.ts \
 *     [--year 2026] \
 *     [--dataset operating|revenue|salary|all] \
 *     [--dry-run]
 *
 * Default: imports all datasets for FY2021-2026.
 */

import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';
import crypto from 'crypto';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const { Pool } = pg;

// ---------------------------------------------------------------------------
// Socrata dataset IDs
// ---------------------------------------------------------------------------

const DATASETS = {
  expenditures: '5bn4-5wey',
  revenues: 'ixyv-mje6',
  salaries: 'ixg8-tyau',
} as const;

const SOCRATA_BASE = 'https://data.cambridgema.gov/resource';

// Cambridge uses "FY26" format for fiscal_year
const FY_YEARS = [2021, 2022, 2023, 2024, 2025, 2026];

// ---------------------------------------------------------------------------
// Color palettes
// ---------------------------------------------------------------------------

const EXPENDITURE_COLORS = [
  '#4476ca', '#616bd9', '#7965d3', '#b957a8', '#c75586',
  '#ce5659', '#c05d43', '#b0633a', '#6e744e', '#417d8a',
  '#5999da', '#798fe4', '#938ae0', '#cf7cc0', '#da7aa5',
  '#e07a7e', '#d68067', '#ca865d', '#8d9575', '#589dac',
];

const REVENUE_COLORS = [
  '#6e744e', '#585937', '#8d9575', '#43432b', '#bcbda4', '#e0dfd0',
  '#4476ca', '#616bd9', '#7965d3', '#b957a8',
];

const SALARY_COLORS = [
  '#417d8a', '#5999da', '#798fe4', '#4476ca', '#616bd9',
  '#7965d3', '#938ae0', '#cf7cc0', '#b957a8', '#c75586',
];

// ---------------------------------------------------------------------------
// Socrata API fetch
// ---------------------------------------------------------------------------

interface SocrataRow {
  [key: string]: string | number | undefined;
}

async function fetchSocrataDataset(
  datasetId: string,
  fiscalYear: number,
): Promise<SocrataRow[]> {
  const url = `${SOCRATA_BASE}/${datasetId}.json?$where=fiscal_year='${fiscalYear}'&$limit=50000`;

  console.log(`  Fetching ${url}`);
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`Socrata API error ${response.status}: ${await response.text()}`);
  }

  const data = await response.json() as SocrataRow[];
  console.log(`  Received ${data.length} rows`);
  return data;
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface CategoryNode {
  name: string;
  depth: number;
  amount: number;
  itemCount: number;
  children: Map<string, CategoryNode>;
  lineItems: SocrataRow[];
  linkKeyParts: string[];
}

interface FlatCategory {
  node: CategoryNode;
  parentPath: string;
  selfPath: string;
  color: string;
  sortOrder: number;
  percentage: number;
  linkKey: string | null;
}

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------

function parseArgs() {
  const args = process.argv.slice(2);

  function getFlag(name: string): string | null {
    const idx = args.indexOf(`--${name}`);
    return idx !== -1 && idx + 1 < args.length ? args[idx + 1] : null;
  }

  const dataset = getFlag('dataset') || 'all';
  const year = getFlag('year');
  const dryRun = args.includes('--dry-run');

  const validDatasets = ['operating', 'revenue', 'salary', 'all'];
  if (!validDatasets.includes(dataset)) {
    console.error(`--dataset must be one of: ${validDatasets.join(', ')}`);
    process.exit(1);
  }

  const years = year ? [parseInt(year)] : FY_YEARS;

  let datasets: string[];
  if (dataset === 'all') {
    datasets = ['operating', 'revenue', 'salary'];
  } else {
    datasets = [dataset];
  }

  return { datasets, years, dryRun };
}

// ---------------------------------------------------------------------------
// Hierarchy building
// ---------------------------------------------------------------------------

function buildHierarchy(
  rows: SocrataRow[],
  hierarchyColumns: string[],
  amountField: string,
): CategoryNode {
  const root: CategoryNode = {
    name: '__root__',
    depth: -1,
    amount: 0,
    itemCount: 0,
    children: new Map(),
    lineItems: [],
    linkKeyParts: [],
  };

  for (const row of rows) {
    let current = root;
    const amt = parseFloat(String(row[amountField] ?? '0')) || 0;
    const keyParts: string[] = [];

    for (let depth = 0; depth < hierarchyColumns.length; depth++) {
      const colName = hierarchyColumns[depth];
      const value = String(row[colName] ?? '').trim();

      if (!value) break;

      keyParts.push(value);

      if (!current.children.has(value)) {
        current.children.set(value, {
          name: value,
          depth,
          amount: 0,
          itemCount: 0,
          children: new Map(),
          lineItems: [],
          linkKeyParts: [...keyParts],
        });
      }

      const child = current.children.get(value)!;
      child.amount += amt;
      child.itemCount++;
      current = child;
    }

    current.lineItems.push(row);
    root.amount += amt;
    root.itemCount++;
  }

  return root;
}

// ---------------------------------------------------------------------------
// Flatten tree
// ---------------------------------------------------------------------------

function flattenTree(
  root: CategoryNode,
  colorPalette: string[],
  datasetType: string,
): FlatCategory[] {
  const result: FlatCategory[] = [];
  const totalAmount = root.amount;
  let colorIdx = 0;

  function walk(node: CategoryNode, parentPath: string, siblingIndex: number) {
    const selfPath = parentPath ? `${parentPath}/${node.name}` : node.name;
    const percentage = totalAmount > 0 ? (node.amount / totalAmount) * 100 : 0;

    const color = node.depth === 0
      ? colorPalette[colorIdx++ % colorPalette.length]
      : colorPalette[0];

    // Generate link_key for operating expenditures (skip first hierarchy level)
    let linkKey: string | null = null;
    if (datasetType === 'operating' && node.linkKeyParts.length > 0) {
      linkKey = node.linkKeyParts.map(p => p.toLowerCase().trim()).join('|');
    }

    result.push({
      node,
      parentPath,
      selfPath,
      color,
      sortOrder: siblingIndex,
      percentage,
      linkKey,
    });

    const sortedChildren = [...node.children.entries()]
      .sort((a, b) => b[1].amount - a[1].amount);

    sortedChildren.forEach(([, child], idx) => {
      walk(child, selfPath, idx);
    });
  }

  const sortedTopLevel = [...root.children.entries()]
    .sort((a, b) => b[1].amount - a[1].amount);

  sortedTopLevel.forEach(([, child], idx) => {
    walk(child, '', idx);
  });

  return result;
}

// ---------------------------------------------------------------------------
// Ensure municipality exists
// ---------------------------------------------------------------------------

async function ensureMunicipality(pool: pg.Pool): Promise<string> {
  const { rows } = await pool.query(
    `SELECT id FROM treasury.municipalities WHERE LOWER(name) = 'cambridge' AND LOWER(state) = 'ma'`,
  );

  if (rows.length > 0) {
    console.log(`Municipality exists: ${rows[0].id}`);
    return rows[0].id;
  }

  // Resolve the TIGER geo_id at insert time so the row links to the geofence backbone
  // (coverage join). Dynamic import keeps src/lib out of module-load (dotenv runs first).
  const { resolveTreasuryGeoId } = await import('../src/lib/treasuryService.js');
  const geoId = await resolveTreasuryGeoId('Cambridge', 'MA', 'city');

  const id = crypto.randomUUID();
  await pool.query(
    `INSERT INTO treasury.municipalities (id, name, state, entity_type, population, geo_id)
     VALUES ($1, 'Cambridge', 'MA', 'city', 118403, $2)`,
    [id, geoId],
  );
  console.log(`Created municipality: ${id}${geoId ? ` (geo_id ${geoId})` : ''}`);
  return id;
}

// ---------------------------------------------------------------------------
// Ensure data source exists
// ---------------------------------------------------------------------------

async function ensureDataSource(pool: pg.Pool): Promise<string> {
  const { rows } = await pool.query(
    `SELECT id FROM treasury.source_registry WHERE name = 'cambridge-open-data'`,
  );

  if (rows.length > 0) return rows[0].id;

  const id = crypto.randomUUID();
  await pool.query(
    `INSERT INTO treasury.source_registry (id, name, display_name, url)
     VALUES ($1, 'cambridge-open-data', 'City of Cambridge Open Data', 'https://data.cambridgema.gov')`,
    [id],
  );
  console.log(`Created data source: cambridge-open-data`);
  return id;
}

// ---------------------------------------------------------------------------
// Insert budget hierarchy
// ---------------------------------------------------------------------------

async function insertBudgetHierarchy(
  pool: pg.Pool,
  municipalityId: string,
  dataSourceId: string,
  fiscalYear: number,
  datasetType: string,
  hierarchy: string[],
  flatCategories: FlatCategory[],
  root: CategoryNode,
  dryRun: boolean,
) {
  const totalLineItems = flatCategories.reduce((s, fc) => s + fc.node.lineItems.length, 0);

  console.log(`  Source rows:      ${root.itemCount.toLocaleString()}`);
  console.log(`  Total budget:     $${root.amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`);
  console.log(`  Categories:       ${flatCategories.length}`);
  console.log(`  Line items:       ${totalLineItems.toLocaleString()}`);

  if (dryRun) {
    console.log('  [DRY RUN] — skipping DB writes');
    const topLevel = flatCategories.filter(fc => fc.node.depth === 0).slice(0, 8);
    console.log('  Top categories:');
    for (const fc of topLevel) {
      console.log(`    ${fc.node.name}: $${fc.node.amount.toLocaleString(undefined, { maximumFractionDigits: 0 })} (${fc.percentage.toFixed(1)}%)`);
    }
    return;
  }

  // Look up existing budget
  const existingBudget = await pool.query(
    `SELECT id FROM treasury.budgets WHERE municipality_id = $1 AND fiscal_year = $2 AND dataset_type = $3`,
    [municipalityId, fiscalYear, datasetType],
  );

  const budgetId = existingBudget.rows.length > 0
    ? existingBudget.rows[0].id
    : crypto.randomUUID();
  const isUpdate = existingBudget.rows.length > 0;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    if (isUpdate) {
      await client.query('DELETE FROM treasury.budgets WHERE id = $1', [budgetId]);
      console.log('  Deleted old budget (cascade)');
    }

    // Insert budget row
    await client.query(
      `INSERT INTO treasury.budgets (id, municipality_id, fiscal_year, dataset_type, total_budget, data_source, data_source_id, hierarchy, generated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())`,
      [budgetId, municipalityId, fiscalYear, datasetType, root.amount, 'cambridge-open-data', dataSourceId, hierarchy],
    );

    // Insert categories depth-by-depth
    const pathToDbId = new Map<string, string>();
    const maxDepth = Math.max(...flatCategories.map(fc => fc.node.depth));

    for (let depth = 0; depth <= maxDepth; depth++) {
      const catsAtDepth = flatCategories.filter(fc => fc.node.depth === depth);
      if (catsAtDepth.length === 0) continue;

      const catRows: any[][] = [];

      for (const fc of catsAtDepth) {
        const catId = crypto.randomUUID();
        const parentDbId = fc.parentPath ? pathToDbId.get(fc.parentPath) || null : null;

        catRows.push([
          catId, budgetId, parentDbId, fc.node.name, fc.node.amount,
          fc.percentage, fc.color, null, null, null,
          fc.node.lineItems.length, fc.sortOrder, fc.node.depth, fc.linkKey, null,
        ]);

        pathToDbId.set(fc.selfPath, catId);
      }

      // Batch insert
      const BATCH = 500;
      for (let i = 0; i < catRows.length; i += BATCH) {
        const batch = catRows.slice(i, i + BATCH);
        const values: string[] = [];
        const params: any[] = [];
        let paramIdx = 1;

        for (const row of batch) {
          const placeholders = row.map(() => `$${paramIdx++}`);
          values.push(`(${placeholders.join(', ')})`);
          params.push(...row);
        }

        await client.query(
          `INSERT INTO treasury.budget_categories
           (id, budget_id, parent_id, name, amount, percentage, color, description, why_matters, historical_change, item_count, sort_order, depth, link_key, actual_amount)
           VALUES ${values.join(', ')}`,
          params,
        );
      }

      console.log(`    Categories depth ${depth}: ${catsAtDepth.length} inserted`);
    }

    // Insert line items
    const lineItemBatches: any[][] = [];

    for (const fc of flatCategories) {
      if (fc.node.lineItems.length === 0) continue;
      const catDbId = pathToDbId.get(fc.selfPath);
      if (!catDbId) continue;

      for (const row of fc.node.lineItems) {
        const desc = String(row['description'] || row['category'] || row['job_title'] || 'No description').trim();
        const approved = parseFloat(String(row['amount'] || row['total_salary'] || '0')) || 0;
        const fund = String(row['fund'] || '').trim() || null;
        const expCat = String(row['category'] || '').trim() || null;

        // Salary-specific fields
        const basePay = row['total_salary'] ? approved : null;

        lineItemBatches.push([
          catDbId, desc, approved, null, basePay, null, null, null,
          null, null, null, null, null, fund, expCat,
        ]);
      }
    }

    const LI_BATCH = 500;
    for (let i = 0; i < lineItemBatches.length; i += LI_BATCH) {
      const batch = lineItemBatches.slice(i, i + LI_BATCH);
      const values: string[] = [];
      const params: any[] = [];
      let paramIdx = 1;

      for (const row of batch) {
        const placeholders = row.map(() => `$${paramIdx++}`);
        values.push(`(${placeholders.join(', ')})`);
        params.push(...row);
      }

      await client.query(
        `INSERT INTO treasury.budget_line_items
         (category_id, description, approved_amount, actual_amount, base_pay, benefits, overtime, other,
          start_date, vendor, date, payment_method, invoice_number, fund, expense_category)
         VALUES ${values.join(', ')}`,
        params,
      );
    }

    await client.query('COMMIT');

    // Verification
    const verifyBudget = await pool.query('SELECT total_budget FROM treasury.budgets WHERE id = $1', [budgetId]);
    const verifyCats = await pool.query('SELECT count(*) as cnt FROM treasury.budget_categories WHERE budget_id = $1', [budgetId]);
    const verifyLIs = await pool.query(
      `SELECT count(*) as cnt FROM treasury.budget_line_items li
       JOIN treasury.budget_categories bc ON li.category_id = bc.id
       WHERE bc.budget_id = $1`,
      [budgetId],
    );

    const dbTotal = parseFloat(verifyBudget.rows[0]?.total_budget ?? '0');
    const match = Math.abs(dbTotal - root.amount) < 0.01;

    console.log(`  ✅ Budget:     $${dbTotal.toLocaleString(undefined, { minimumFractionDigits: 2 })} ${match ? '✓' : '✗ MISMATCH!'}`);
    console.log(`  ✅ Categories: ${verifyCats.rows[0].cnt}`);
    console.log(`  ✅ Line items: ${verifyLIs.rows[0].cnt}`);

  } catch (err) {
    await client.query('ROLLBACK');
    console.error(`  ❌ ROLLBACK:`, err);
  } finally {
    client.release();
  }
}

// ---------------------------------------------------------------------------
// Process expenditures
// ---------------------------------------------------------------------------

async function processExpenditures(
  pool: pg.Pool,
  municipalityId: string,
  dataSourceId: string,
  fiscalYear: number,
  dryRun: boolean,
) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`  FY${fiscalYear} Operating Expenditures`);
  console.log(`${'='.repeat(60)}`);

  const rows = await fetchSocrataDataset(DATASETS.expenditures, fiscalYear);
  if (rows.length === 0) {
    console.log('  No data — skipping');
    return;
  }

  // Cambridge hierarchy: service → department_name → division_name → category → fund (5 levels, matches Bloomington depth)
  // Line item description comes from the 'description' field
  const hierarchyColumns = ['service', 'department_name', 'division_name', 'category', 'fund'];
  const root = buildHierarchy(rows, hierarchyColumns, 'amount');
  const flatCategories = flattenTree(root, EXPENDITURE_COLORS, 'operating');

  await insertBudgetHierarchy(
    pool, municipalityId, dataSourceId, fiscalYear,
    'operating', hierarchyColumns, flatCategories, root, dryRun,
  );
}

// ---------------------------------------------------------------------------
// Process revenues
// ---------------------------------------------------------------------------

async function processRevenues(
  pool: pg.Pool,
  municipalityId: string,
  dataSourceId: string,
  fiscalYear: number,
  dryRun: boolean,
) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`  FY${fiscalYear} Operating Revenues`);
  console.log(`${'='.repeat(60)}`);

  const rows = await fetchSocrataDataset(DATASETS.revenues, fiscalYear);
  if (rows.length === 0) {
    console.log('  No data — skipping');
    return;
  }

  // Revenue hierarchy: category (revenue type) → service → department_name → fund
  // Leading with category gives "where it's from" (Taxes, Charges, etc.) vs expenditure's "how it's spent"
  const hierarchyColumns = ['category', 'service', 'department_name', 'fund'];
  const root = buildHierarchy(rows, hierarchyColumns, 'amount');
  const flatCategories = flattenTree(root, REVENUE_COLORS, 'revenue');

  await insertBudgetHierarchy(
    pool, municipalityId, dataSourceId, fiscalYear,
    'revenue', hierarchyColumns, flatCategories, root, dryRun,
  );
}

// ---------------------------------------------------------------------------
// Process salaries
// ---------------------------------------------------------------------------

async function processSalaries(
  pool: pg.Pool,
  municipalityId: string,
  dataSourceId: string,
  fiscalYear: number,
  dryRun: boolean,
) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`  FY${fiscalYear} Salaries`);
  console.log(`${'='.repeat(60)}`);

  const rows = await fetchSocrataDataset(DATASETS.salaries, fiscalYear);
  if (rows.length === 0) {
    console.log('  No data — skipping');
    return;
  }

  // Salary hierarchy: service → department → division → (line items by job_title)
  const hierarchyColumns = ['service', 'department', 'division'];
  const root = buildHierarchy(rows, hierarchyColumns, 'total_salary');
  const flatCategories = flattenTree(root, SALARY_COLORS, 'salary');

  await insertBudgetHierarchy(
    pool, municipalityId, dataSourceId, fiscalYear,
    'salary', hierarchyColumns, flatCategories, root, dryRun,
  );
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const args = parseArgs();

  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    console.error('DATABASE_URL environment variable is required');
    process.exit(1);
  }

  console.log('Cambridge, MA Budget Data Import');
  console.log(`Datasets: ${args.datasets.join(', ')}`);
  console.log(`Years:    FY${args.years.join(', FY')}`);
  console.log(`Dry run:  ${args.dryRun}`);

  const pool = new Pool({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false },
  });

  try {
    const municipalityId = await ensureMunicipality(pool);
    const dataSourceId = await ensureDataSource(pool);

    for (const year of args.years) {
      for (const dataset of args.datasets) {
        switch (dataset) {
          case 'operating':
            await processExpenditures(pool, municipalityId, dataSourceId, year, args.dryRun);
            break;
          case 'revenue':
            await processRevenues(pool, municipalityId, dataSourceId, year, args.dryRun);
            break;
          case 'salary':
            await processSalaries(pool, municipalityId, dataSourceId, year, args.dryRun);
            break;
        }
      }
    }

    console.log('\n✅ Cambridge import complete!');

  } finally {
    await pool.end();
  }
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
