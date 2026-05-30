/**
 * importBudgetHierarchy.ts — Rebuild treasury budget hierarchy from flat tables.
 *
 * Reads from treasury.operating_budgets / treasury.revenue_budgets (flat, correct data)
 * and rebuilds treasury.budgets + treasury.budget_categories + treasury.budget_line_items
 * with the correct hierarchy, amounts, and link_keys.
 *
 * Prerequisites: migration 041_treasury_cascade_deletes.sql must be applied first
 * so that deleting a budget row cascades through categories → line_items → enrichment_queue.
 *
 * Usage:
 *   DATABASE_URL="postgresql://..." npx tsx backend/scripts/importBudgetHierarchy.ts \
 *     --municipality "Bloomington" --state "IN" \
 *     [--dataset operating|revenue|both] \
 *     [--year 2023] \
 *     [--dry-run]
 *
 * Options:
 *   --municipality <name>  Municipality name (required)
 *   --state <ST>           State abbreviation (required)
 *   --dataset <type>       operating, revenue, or both (default: both)
 *   --year <YYYY>          Only process this fiscal year (default: all available years)
 *   --dry-run              Print stats without writing to DB
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
// Dataset configs (from treasuryConfig.json — embedded for standalone use)
// ---------------------------------------------------------------------------

interface DatasetConfig {
  sourceTable: string;
  hierarchy: string[];
  amountColumn: string;
  colorPalette: string[];
  dataSource: string;
}

const DATASET_CONFIGS: Record<string, DatasetConfig> = {
  operating: {
    sourceTable: 'treasury.operating_budgets',
    hierarchy: ['primary_function', 'priority', 'service', 'fund', 'item_category'],
    amountColumn: 'approved_amount',
    colorPalette: [
      '#4476ca', '#616bd9', '#7965d3', '#b957a8', '#c75586',
      '#ce5659', '#c05d43', '#b0633a', '#6e744e', '#417d8a',
      '#5999da', '#798fe4', '#938ae0', '#cf7cc0', '#da7aa5',
      '#e07a7e', '#d68067', '#ca865d', '#8d9575', '#589dac',
      '#8bbeeb', '#a0b7f0', '#b2b4ed', '#daaada', '#e3a9c9',
      '#e8a9aa', '#e4ae97', '#deb28d', '#bcbda4', '#92c2cf',
    ],
    dataSource: 'bloomington-open-data',
  },
  revenue: {
    sourceTable: 'treasury.revenue_budgets',
    hierarchy: ['primary_function', 'item_category', 'fund'],
    amountColumn: 'approved_amount',
    colorPalette: [
      '#6e744e', '#585937', '#8d9575', '#43432b', '#bcbda4', '#e0dfd0',
    ],
    dataSource: 'bloomington-open-data',
  },
};

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface FlatRow {
  [key: string]: string | number | null;
}

interface CategoryNode {
  name: string;
  depth: number;
  amount: number; // sum of amountColumn for all rows in this subtree
  actualAmount: number; // sum of actual_amount for comparison
  itemCount: number;
  children: Map<string, CategoryNode>;
  lineItems: FlatRow[];
  linkKeyParts: string[]; // for generating link_key on operating categories
}

interface InsertedCategory {
  dbId: string;
  node: CategoryNode;
  parentDbId: string | null;
}

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------

function parseArgs() {
  const args = process.argv.slice(2);

  function getFlag(name: string): string | null {
    const idx = args.indexOf(`--${name}`);
    return idx !== -1 && idx + 1 < args.length ? args[idx + 1] : null;
  }

  const municipality = getFlag('municipality');
  const state = getFlag('state');
  const dataset = getFlag('dataset') || 'both';
  const year = getFlag('year');
  const dryRun = args.includes('--dry-run');

  if (!municipality || !state) {
    console.error('Usage: npx tsx backend/scripts/importBudgetHierarchy.ts --municipality "Bloomington" --state "IN" [--dataset operating|revenue|both] [--year YYYY] [--dry-run]');
    process.exit(1);
  }

  if (!['operating', 'revenue', 'both'].includes(dataset)) {
    console.error('--dataset must be operating, revenue, or both');
    process.exit(1);
  }

  return {
    municipality,
    state: state.toUpperCase(),
    datasets: dataset === 'both' ? ['operating', 'revenue'] : [dataset],
    year: year ? parseInt(year) : null,
    dryRun,
  };
}

// ---------------------------------------------------------------------------
// Hierarchy tree building
// ---------------------------------------------------------------------------

function buildHierarchy(rows: FlatRow[], config: DatasetConfig): CategoryNode {
  const root: CategoryNode = {
    name: '__root__',
    depth: -1,
    amount: 0,
    actualAmount: 0,
    itemCount: 0,
    children: new Map(),
    lineItems: [],
    linkKeyParts: [],
  };

  for (const row of rows) {
    let current = root;
    const approvedAmt = parseFloat(String(row[config.amountColumn] ?? '0')) || 0;
    const actualAmt = parseFloat(String(row['actual_amount'] ?? '0')) || 0;

    // Walk hierarchy levels
    let reachedLeaf = false;
    const keyParts: string[] = [];

    for (let depth = 0; depth < config.hierarchy.length; depth++) {
      const colName = config.hierarchy[depth];
      const value = String(row[colName] ?? '').trim();

      if (!value) {
        // Empty hierarchy value — attach as line item at current depth
        reachedLeaf = true;
        break;
      }

      keyParts.push(value);

      if (!current.children.has(value)) {
        current.children.set(value, {
          name: value,
          depth,
          amount: 0,
          actualAmount: 0,
          itemCount: 0,
          children: new Map(),
          lineItems: [],
          linkKeyParts: [...keyParts],
        });
      }

      const child = current.children.get(value)!;
      child.amount += approvedAmt;
      child.actualAmount += actualAmt;
      child.itemCount++;
      current = child;

      // If this is the deepest level, it's a leaf
      if (depth === config.hierarchy.length - 1) {
        reachedLeaf = true;
      }
    }

    // Attach line item at the deepest category reached
    current.lineItems.push(row);

    // Accumulate into root
    root.amount += approvedAmt;
    root.actualAmount += actualAmt;
    root.itemCount++;
  }

  return root;
}

// ---------------------------------------------------------------------------
// Generate link_key for operating categories (matches importTransactions.ts)
// ---------------------------------------------------------------------------

function generateLinkKey(node: CategoryNode, datasetType: string): string | null {
  if (datasetType !== 'operating') return null;

  // Link key uses: priority|service|fund|item_category (all lowercase)
  // These correspond to hierarchy indices 1,2,3,4 in operating config
  // But we build from whatever parts are available
  const parts = node.linkKeyParts.slice(1); // skip primary_function (index 0)
  if (parts.length === 0) return null;
  return parts.map(p => p.toLowerCase().trim()).join('|');
}

// ---------------------------------------------------------------------------
// Flatten tree into depth-ordered arrays for insertion
// ---------------------------------------------------------------------------

interface FlatCategory {
  node: CategoryNode;
  parentPath: string; // unique key for finding parent's DB id
  selfPath: string;   // unique key for this category
  color: string;
  sortOrder: number;
  percentage: number;
  linkKey: string | null;
}

function flattenTree(
  root: CategoryNode,
  config: DatasetConfig,
  datasetType: string,
): FlatCategory[] {
  const result: FlatCategory[] = [];
  const totalAmount = root.amount;
  let colorIdx = 0;

  function walk(node: CategoryNode, parentPath: string, siblingIndex: number) {
    const selfPath = parentPath ? `${parentPath}/${node.name}` : node.name;
    const percentage = totalAmount > 0 ? (node.amount / totalAmount) * 100 : 0;

    // Top-level categories get palette colors; children inherit (tracked by frontend)
    const color = node.depth === 0
      ? config.colorPalette[colorIdx++ % config.colorPalette.length]
      : config.colorPalette[0]; // children get a default; frontend uses parent color

    result.push({
      node,
      parentPath,
      selfPath,
      color,
      sortOrder: siblingIndex,
      percentage,
      linkKey: generateLinkKey(node, datasetType),
    });

    // Sort children by amount descending before recursing
    const sortedChildren = [...node.children.entries()]
      .sort((a, b) => b[1].amount - a[1].amount);

    sortedChildren.forEach(([, child], idx) => {
      walk(child, selfPath, idx);
    });
  }

  // Sort root's children by amount descending
  const sortedTopLevel = [...root.children.entries()]
    .sort((a, b) => b[1].amount - a[1].amount);

  sortedTopLevel.forEach(([, child], idx) => {
    walk(child, '', idx);
  });

  return result;
}

// ---------------------------------------------------------------------------
// Batch insert helper
// ---------------------------------------------------------------------------

async function batchInsert(
  client: pg.PoolClient,
  sql: string,
  batches: any[][],
  colCount: number,
  label: string,
): Promise<pg.QueryResult[]> {
  const BATCH_SIZE = 500;
  const results: pg.QueryResult[] = [];

  for (let i = 0; i < batches.length; i += BATCH_SIZE) {
    const batch = batches.slice(i, i + BATCH_SIZE);
    const values: string[] = [];
    const params: any[] = [];
    let paramIdx = 1;

    for (const row of batch) {
      const placeholders = row.map(() => `$${paramIdx++}`);
      values.push(`(${placeholders.join(', ')})`);
      params.push(...row);
    }

    const fullSql = `${sql} VALUES ${values.join(', ')} RETURNING id`;
    const result = await client.query(fullSql, params);
    results.push(result);

    if ((i + BATCH_SIZE) % 2000 === 0 || i + BATCH_SIZE >= batches.length) {
      console.log(`    ${label}: ${Math.min(i + BATCH_SIZE, batches.length)}/${batches.length}`);
    }
  }

  return results;
}

// ---------------------------------------------------------------------------
// Process one dataset_type + fiscal_year
// ---------------------------------------------------------------------------

async function processDataset(
  pool: pg.Pool,
  municipalityId: string,
  fiscalYear: number,
  datasetType: string,
  config: DatasetConfig,
  dryRun: boolean,
) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`  FY${fiscalYear} ${datasetType}`);
  console.log(`${'='.repeat(60)}`);

  // 1. Read flat rows
  const { rows } = await pool.query(
    `SELECT * FROM ${config.sourceTable} WHERE municipality_id = $1 AND fiscal_year = $2`,
    [municipalityId, fiscalYear],
  );

  if (rows.length === 0) {
    console.log('  No source rows found — skipping');
    return;
  }

  // 2. Build hierarchy
  const root = buildHierarchy(rows, config);
  const flatCategories = flattenTree(root, config, datasetType);

  // 3. Summary
  const depthCounts: Record<number, number> = {};
  for (const fc of flatCategories) {
    depthCounts[fc.node.depth] = (depthCounts[fc.node.depth] || 0) + 1;
  }
  const totalLineItems = flatCategories.reduce((s, fc) => s + fc.node.lineItems.length, 0);

  console.log(`  Source rows:      ${rows.length.toLocaleString()}`);
  console.log(`  Total approved:   $${root.amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`);
  console.log(`  Total actual:     $${root.actualAmount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`);
  console.log(`  Categories:       ${flatCategories.length} (depths: ${Object.entries(depthCounts).map(([d, c]) => `${d}:${c}`).join(', ')})`);
  console.log(`  Line items:       ${totalLineItems.toLocaleString()}`);

  if (dryRun) {
    console.log('  [DRY RUN] — skipping DB writes');
    // Print top-level preview
    const topLevel = flatCategories.filter(fc => fc.node.depth === 0).slice(0, 8);
    console.log('  Top categories:');
    for (const fc of topLevel) {
      console.log(`    ${fc.node.name}: $${fc.node.amount.toLocaleString(undefined, { maximumFractionDigits: 0 })} (${fc.percentage.toFixed(1)}%)`);
    }
    return;
  }

  // 4. Look up existing budget row
  const existingBudget = await pool.query(
    `SELECT id FROM treasury.budgets WHERE municipality_id = $1 AND fiscal_year = $2 AND dataset_type = $3`,
    [municipalityId, fiscalYear, datasetType],
  );

  const budgetId = existingBudget.rows.length > 0
    ? existingBudget.rows[0].id
    : crypto.randomUUID();

  const isUpdate = existingBudget.rows.length > 0;

  // 5. Execute within a transaction
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 5a. Handle existing budget — defer FK check, delete + re-insert with same UUID
    if (isUpdate) {
      // Defer the transactions FK so we can delete & re-insert the budget row
      // within the same transaction. The FK is DEFERRABLE INITIALLY IMMEDIATE
      // (set by migration), so we defer it just for this transaction.
      await client.query('SET CONSTRAINTS treasury.transactions_budget_id_fkey DEFERRED');

      // CASCADE deletes categories → line_items → enrichment_queue
      // Transactions stay intact (their FK check is deferred until COMMIT)
      await client.query('DELETE FROM treasury.budgets WHERE id = $1', [budgetId]);
      console.log('  Deleted old budget (cascade cleared categories/line_items)');
    }

    // 5b. Insert budget row (reuse old ID so transaction FKs remain valid at COMMIT)
    await client.query(
      `INSERT INTO treasury.budgets (id, municipality_id, fiscal_year, dataset_type, total_budget, data_source, hierarchy, generated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())`,
      [budgetId, municipalityId, fiscalYear, datasetType, root.amount, config.dataSource, config.hierarchy],
    );

    // 5c. Insert categories depth-by-depth
    // Build a map from selfPath → dbId so children can reference parents
    const pathToDbId = new Map<string, string>();
    const maxDepth = Math.max(...flatCategories.map(fc => fc.node.depth));

    let totalCatsInserted = 0;

    for (let depth = 0; depth <= maxDepth; depth++) {
      const catsAtDepth = flatCategories.filter(fc => fc.node.depth === depth);
      if (catsAtDepth.length === 0) continue;

      const catRows: any[][] = [];
      const catIds: string[] = []; // pre-generate UUIDs so we can map them

      for (const fc of catsAtDepth) {
        const catId = crypto.randomUUID();
        catIds.push(catId);
        const parentDbId = fc.parentPath ? pathToDbId.get(fc.parentPath) || null : null;

        catRows.push([
          catId,
          budgetId,
          parentDbId,
          fc.node.name,
          fc.node.amount,
          fc.percentage,
          fc.color,
          null, // description (filled by enrichment)
          null, // why_matters (filled by enrichment)
          null, // historical_change
          fc.node.lineItems.length, // item_count — line items at THIS level
          fc.sortOrder,
          fc.node.depth,
          fc.linkKey,
          fc.node.actualAmount,
        ]);

        pathToDbId.set(fc.selfPath, catId);
      }

      // Batch insert
      const CAT_BATCH = 500;
      for (let i = 0; i < catRows.length; i += CAT_BATCH) {
        const batch = catRows.slice(i, i + CAT_BATCH);
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

      totalCatsInserted += catsAtDepth.length;
      console.log(`    Categories depth ${depth}: ${catsAtDepth.length} inserted`);
    }

    // 5d. Insert line items for leaf categories (categories that have lineItems)
    let totalLineItemsInserted = 0;
    const lineItemBatches: any[][] = [];

    for (const fc of flatCategories) {
      if (fc.node.lineItems.length === 0) continue;
      const catDbId = pathToDbId.get(fc.selfPath);
      if (!catDbId) continue;

      for (const row of fc.node.lineItems) {
        const desc = String(row['description'] || row['item_category'] || 'No description').trim();
        const approved = parseFloat(String(row['approved_amount'] ?? '0')) || 0;
        const actual = parseFloat(String(row['actual_amount'] ?? '0')) || 0;
        const fund = String(row['fund'] || '').trim() || null;
        const expCat = String(row['item_category'] || '').trim() || null;

        lineItemBatches.push([
          catDbId,
          desc,
          approved,
          actual !== 0 ? actual : null,
          fund,
          expCat,
        ]);
      }
    }

    // Batch insert line items
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
         (category_id, description, approved_amount, actual_amount, fund, expense_category)
         VALUES ${values.join(', ')}`,
        params,
      );

      totalLineItemsInserted += batch.length;

      if ((i + LI_BATCH) % 5000 === 0 || i + LI_BATCH >= lineItemBatches.length) {
        console.log(`    Line items: ${Math.min(i + LI_BATCH, lineItemBatches.length).toLocaleString()}/${lineItemBatches.length.toLocaleString()}`);
      }
    }

    await client.query('COMMIT');

    // 6. Verification
    const verifyBudget = await pool.query(
      'SELECT total_budget FROM treasury.budgets WHERE id = $1',
      [budgetId],
    );
    const verifyCategories = await pool.query(
      'SELECT count(*) as cnt FROM treasury.budget_categories WHERE budget_id = $1',
      [budgetId],
    );
    const verifyLineItems = await pool.query(
      `SELECT count(*) as cnt FROM treasury.budget_line_items li
       JOIN treasury.budget_categories bc ON li.category_id = bc.id
       WHERE bc.budget_id = $1`,
      [budgetId],
    );

    const dbTotal = parseFloat(verifyBudget.rows[0]?.total_budget ?? '0');
    const match = Math.abs(dbTotal - root.amount) < 0.01;

    console.log(`\n  ✅ Budget:     $${dbTotal.toLocaleString(undefined, { minimumFractionDigits: 2 })} ${match ? '✓' : '✗ MISMATCH!'}`);
    console.log(`  ✅ Categories: ${verifyCategories.rows[0].cnt}`);
    console.log(`  ✅ Line items: ${verifyLineItems.rows[0].cnt}`);

    if (!match) {
      console.error(`  ⚠️  total_budget ($${dbTotal}) does not match computed ($${root.amount})!`);
    }

  } catch (err) {
    await client.query('ROLLBACK');
    console.error(`  ❌ ROLLBACK — error processing FY${fiscalYear} ${datasetType}:`, err);
  } finally {
    client.release();
  }
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

  const pool = new Pool({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false },
  });

  try {
    // 1. Look up municipality
    const { rows: muniRows } = await pool.query(
      `SELECT id, name, state, entity_type, geo_id FROM treasury.municipalities
       WHERE LOWER(name) = LOWER($1) AND LOWER(state) = LOWER($2)`,
      [args.municipality, args.state],
    );

    if (muniRows.length === 0) {
      console.error(`Municipality not found: ${args.municipality}, ${args.state}`);
      process.exit(1);
    }

    // Filter out townships/special districts — only process cities/counties
    const validTypes = ['city', 'county'];
    const cityRow = muniRows.find((r: any) => validTypes.includes(r.entity_type));
    if (!cityRow) {
      console.error(`No city/county found for "${args.municipality}, ${args.state}". Found: ${muniRows.map((r: any) => `${r.name} (${r.entity_type})`).join(', ')}`);
      console.error('This script only processes city/county data, not townships or special districts.');
      process.exit(1);
    }

    const municipalityId = cityRow.id;
    console.log(`\nMunicipality: ${cityRow.name}, ${cityRow.state} (${cityRow.entity_type})`);
    console.log(`ID:           ${municipalityId}`);

    // Ensure the municipality is linked to the TIGER geofence backbone. Future data
    // pulls flow through this rebuild, so resolve+set geo_id here if it's missing
    // (self-healing; never overwrites an existing geo_id). Skipped on --dry-run.
    if (!cityRow.geo_id && !args.dryRun) {
      const { resolveTreasuryGeoId } = await import('../src/lib/treasuryService.js');
      const geoId = await resolveTreasuryGeoId(cityRow.name, cityRow.state, cityRow.entity_type);
      if (geoId) {
        await pool.query(
          `UPDATE treasury.municipalities SET geo_id = $1, updated_at = now() WHERE id = $2 AND geo_id IS NULL`,
          [geoId, municipalityId],
        );
        console.log(`geo_id:       ${geoId} (resolved + set)`);
      } else {
        console.log(`geo_id:       (unresolved — no TIGER geofence match)`);
      }
    } else if (cityRow.geo_id) {
      console.log(`geo_id:       ${cityRow.geo_id}`);
    }
    console.log(`Datasets:     ${args.datasets.join(', ')}`);
    console.log(`Year filter:  ${args.year || 'all'}`);
    console.log(`Dry run:      ${args.dryRun}`);

    // 2. Discover available fiscal years
    for (const datasetType of args.datasets) {
      const config = DATASET_CONFIGS[datasetType];
      if (!config) {
        console.error(`Unknown dataset type: ${datasetType}`);
        continue;
      }

      const { rows: yearRows } = await pool.query(
        `SELECT DISTINCT fiscal_year FROM ${config.sourceTable}
         WHERE municipality_id = $1
         ${args.year ? 'AND fiscal_year = $2' : ''}
         ORDER BY fiscal_year`,
        args.year ? [municipalityId, args.year] : [municipalityId],
      );

      const years = yearRows.map((r: any) => Number(r.fiscal_year));
      console.log(`\n${datasetType}: found years ${years.join(', ')}`);

      for (const fy of years) {
        await processDataset(pool, municipalityId, fy, datasetType, config, args.dryRun);
      }
    }

    console.log('\n✅ Done!');

  } finally {
    await pool.end();
  }
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
