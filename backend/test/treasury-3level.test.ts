/**
 * treasury-3level.test.ts
 *
 * Integration + regression test for Phase 34: 3-Level Tree Infrastructure (TREE-01/02/03).
 *
 * Day-1 Inspections (run on 2026-06-08 before writing this file):
 *   (a) SELECT depth, count(*) FROM treasury.budget_categories GROUP BY depth ORDER BY depth
 *       Result: {"depth":"0","cnt":"20667"}, {"depth":"1","cnt":"115339"},
 *               {"depth":"2","cnt":"7112"}, {"depth":"3","cnt":"6394"}, {"depth":"4","cnt":"9992"}
 *       → Depth-2+ rows already exist. Infrastructure supports N-level trees.
 *
 *   (b) SELECT column_name FROM information_schema.columns WHERE table_schema='treasury'
 *       AND table_name='budget_line_items' ORDER BY ordinal_position
 *       Result: id, category_id, description, approved_amount, actual_amount,
 *               base_pay, benefits, overtime, other, start_date, vendor, date,
 *               payment_method, invoice_number, fund, expense_category, external_id, source
 *       → No department/category/subcategory column exists. Hierarchy lives in
 *         budget_categories.parent_id only. Do NOT assert these columns on budget_line_items.
 *
 *   (c) treasury_sync_budget_tree RPC confirmed by successful submit in TREE-01 test below.
 *       No .sql source file exists — this is a live Postgres function only.
 *
 * TREE-01: A 3-level tree (c→c→i) submitted via treasury_sync_budget_tree lands as
 *          budget_categories rows at depths 0, 1, and 2.
 * TREE-02: The tree builder (mirroring getBudgetById) returns a 3-level shape
 *          (subcategories → subcategories → lineItems) for the inserted test budget.
 *          NOTE: getBudgetById is NOT imported directly because env.ts calls process.exit(1)
 *          at module init if env vars are not set. Instead, the tree is built inline via
 *          direct SQL — this is the explicitly sanctioned fallback in the plan.
 * TREE-03: Three existing 2-level city budgets (Portland OR, San Jose CA, Dallas TX) still
 *          return a 2-level tree with no depth-2 subcategories.
 *
 * Threat mitigations:
 *   T-34-01: afterAll deletes the test budget (FK cascade removes categories + line items).
 *            Sentinel FY=9999 makes any leaked row identifiable.
 *   T-34-02: TREE-03 tests are SELECT-only — no INSERT/UPDATE/DELETE against city budgets.
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';
import { createClient } from '@supabase/supabase-js';

// ── Env loading ───────────────────────────────────────────────────────────────
// The test file is at C:/EV-Accounts/backend/test/ — ../.env reaches C:/EV-Accounts/backend/.env
function loadEnv() {
  for (const f of ['../.env.local', '../.env']) {
    try {
      const lines = fs.readFileSync(path.resolve(__dirname, f), 'utf8').split('\n');
      for (const line of lines) {
        const [k, ...v] = line.split('=');
        const rawVal = v.join('=').trim().replace(/\s+#.*$/, '');  // strip inline # comments
        if (k && v.length && !process.env[k.trim()]) process.env[k.trim()] = rawVal;
      }
    } catch {
      // file not found — skip silently
    }
  }
}
loadEnv();

// ── Inline tree builder (mirrors getBudgetById's buildTree — see treasuryService.ts lines 644-664)
// This implements the same recursive parent_id → nested-subcategories logic without importing
// the service module (which would trigger env.ts process.exit if vars are missing).
interface SimpleNode {
  id: string;
  parent_id: string | null;
  name: string;
  depth: number;
}
interface TreeNode {
  name: string;
  depth: number;
  subcategories?: TreeNode[];
  lineItems?: Array<{ description: string; approved_amount: number }>;
}
function buildTreeFromRows(rows: SimpleNode[], lineItemsByCategory: Map<string, Array<{ description: string; approved_amount: number }>>): TreeNode[] {
  const nodeMap = new Map<string, SimpleNode>();
  const childrenMap = new Map<string, string[]>();
  const rootIds: string[] = [];

  for (const row of rows) {
    nodeMap.set(row.id, row);
    if (row.parent_id === null) {
      rootIds.push(row.id);
    } else {
      const siblings = childrenMap.get(row.parent_id) ?? [];
      siblings.push(row.id);
      childrenMap.set(row.parent_id, siblings);
    }
  }

  function buildNode(id: string): TreeNode {
    const node = nodeMap.get(id);
    if (!node) throw new Error(`buildNode: id "${id}" not found in nodeMap — possible data inconsistency`);
    const childIds = childrenMap.get(id) ?? [];
    const subcategories = childIds.map(buildNode);
    const result: TreeNode = { name: node.name, depth: node.depth };
    if (subcategories.length > 0) result.subcategories = subcategories;
    const items = lineItemsByCategory.get(id);
    if (items && items.length > 0) result.lineItems = items;
    return result;
  }

  return rootIds.map(buildNode);
}

// ── Test suite ────────────────────────────────────────────────────────────────
describe('treasury 3-level tree infrastructure (TREE-01/02/03)', () => {
  let pool: pg.Pool;
  let supabase: ReturnType<typeof createClient>;
  let testBudgetId: string | null = null;

  beforeAll(() => {
    const DATABASE_URL = process.env.DATABASE_URL;
    const SUPABASE_URL = process.env.SUPABASE_URL || 'https://kxsdzaojfaibhuzmclfq.supabase.co';
    const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!DATABASE_URL) throw new Error('DATABASE_URL is not set — check C:/EV-Accounts/backend/.env');
    if (!SUPABASE_SERVICE_KEY) throw new Error('SUPABASE_SERVICE_KEY / SUPABASE_SERVICE_ROLE_KEY is not set');

    pool = new pg.Pool({ connectionString: DATABASE_URL, ssl: { rejectUnauthorized: false } });
    supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
  });

  afterAll(async () => {
    // T-34-01 mitigation: delete test budget — FK cascade removes categories + line items
    if (testBudgetId && pool) {
      const res = await pool.query('DELETE FROM treasury.budgets WHERE id = $1', [testBudgetId]);
      if (res.rowCount === 0) {
        console.warn(`[afterAll] FY=9999 test budget ${testBudgetId} was NOT deleted — manual cleanup required`);
      }
    }
    if (pool) await pool.end();
  });

  // ── TREE-01: 3-level RPC submit ─────────────────────────────────────────────
  it('TREE-01: 3-level tree c→c→i submits and creates depth 0/1/2 budget_categories', async () => {
    // Resolve a valid data_source_id at runtime (do not hardcode a UUID)
    const { rows: dsSources } = await pool.query<{ id: string }>(
      `SELECT id FROM treasury.data_sources WHERE dataset_type = 'operating' LIMIT 1`
    );
    expect(dsSources.length, 'Expected at least one operating data_source row').toBeGreaterThan(0);
    const dataSourceId = dsSources[0].id;

    // 3-level tree shape: Health and Human Services → Dept of Health Care Services → Medi-Cal
    // (from 34-PATTERNS.md RPC call pattern section)
    const threeLevel = [
      {
        n: 'Health and Human Services',         // Level 1 — depth=0
        a: 87_139_490_000,
        c: [
          {
            n: 'Dept of Health Care Services',  // Level 2 — depth=1
            a: 50_000_000_000,
            c: [
              {
                n: 'Medi-Cal',                  // Level 3 — depth=2 (the new level)
                a: 40_000_000_000,
                i: [{ d: 'Medi-Cal Managed Care', a: 40_000_000_000, aa: null, f: null, e: null }],
              },
            ],
          },
        ],
      },
    ];

    // Sentinel FY=9999 — unlikely to collide; makes test data identifiable if cleanup fails
    const { data: rpc, error: rpcErr } = await supabase.rpc('treasury_sync_budget_tree', {
      p_data_source_id: dataSourceId,
      p_fiscal_year:    9999,
      p_dataset_type:   'operating',
      p_total:          87_139_490_000,
      p_tree:           threeLevel,
      p_row_count:      1,
      p_triggered_by:   'bulk_load',
    });

    expect(rpcErr, `RPC transport error: ${rpcErr?.message}`).toBeNull();
    expect(rpc?.error, `RPC returned application error: ${rpc?.error}`).toBeFalsy();
    expect(rpc?.status, 'RPC status must be "success"').toBe('success');
    expect(rpc?.budget_id, 'RPC must return a budget_id UUID').toBeTruthy();

    testBudgetId = rpc.budget_id as string;

    // Verify depths 0, 1, and 2 each have exactly one budget_categories row
    const { rows: depthRows } = await pool.query<{ depth: string; cnt: string }>(
      `SELECT depth::text, count(*)::text AS cnt
       FROM treasury.budget_categories
       WHERE budget_id = $1
       GROUP BY depth
       ORDER BY depth`,
      [testBudgetId]
    );

    const depthMap = new Map(depthRows.map((r) => [Number(r.depth), Number(r.cnt)]));
    expect(depthMap.get(0), 'Expected exactly 1 depth-0 row (root category)').toBe(1);
    expect(depthMap.get(1), 'Expected exactly 1 depth-1 row (sub-category)').toBe(1);
    expect(depthMap.get(2), 'Expected exactly 1 depth-2 row (sub-sub-category — the new level)').toBe(1);
    expect(depthMap.has(3), 'Expected NO depth-3 rows for a 3-level tree').toBe(false);
  });

  // ── TREE-02: 3-level API response shape ─────────────────────────────────────
  it('TREE-02: tree builder returns a 3-level BudgetCategory[] for depth-2 data', async () => {
    expect(testBudgetId, 'TREE-01 must pass before TREE-02 — no testBudgetId').toBeTruthy();

    // Fetch all budget_categories for the test budget
    const { rows: catRows } = await pool.query<SimpleNode>(
      `SELECT id, parent_id, name, depth::int AS depth
       FROM treasury.budget_categories
       WHERE budget_id = $1
       ORDER BY depth, sort_order`,
      [testBudgetId]
    );

    // Fetch all line items for the test budget
    const { rows: liRows } = await pool.query<{ category_id: string; description: string; approved_amount: number }>(
      `SELECT category_id, description, approved_amount
       FROM treasury.budget_line_items
       WHERE category_id IN (
         SELECT id FROM treasury.budget_categories WHERE budget_id = $1
       )`,
      [testBudgetId]
    );

    // Group line items by category_id
    const lineItemsByCategory = new Map<string, Array<{ description: string; approved_amount: number }>>();
    for (const li of liRows) {
      const arr = lineItemsByCategory.get(li.category_id) ?? [];
      arr.push({ description: li.description, approved_amount: Number(li.approved_amount) });
      lineItemsByCategory.set(li.category_id, arr);
    }

    // Build tree inline (mirrors getBudgetById's buildTree)
    const tree = buildTreeFromRows(catRows, lineItemsByCategory);

    // Assert 3-level shape: root → subcategories[0] → subcategories[0] → lineItems
    expect(tree.length, 'Expected exactly 1 root category').toBe(1);

    const root = tree[0];
    expect(root.name, 'Root should be "Health and Human Services"').toBe('Health and Human Services');
    expect(root.subcategories, 'Root must have subcategories (Level 2 exists)').toBeDefined();
    expect(root.subcategories!.length, 'Root must have exactly 1 subcategory').toBe(1);

    const level2 = root.subcategories![0];
    expect(level2.name, 'Level-2 node should be "Dept of Health Care Services"').toBe('Dept of Health Care Services');
    expect(level2.subcategories, 'Level-2 node must have subcategories (Level 3 exists)').toBeDefined();
    expect(level2.subcategories!.length, 'Level-2 node must have exactly 1 subcategory').toBe(1);

    const level3 = level2.subcategories![0];
    expect(level3.name, 'Level-3 leaf should be "Medi-Cal"').toBe('Medi-Cal');
    expect(level3.subcategories, 'Leaf node must NOT have subcategories').toBeUndefined();
    expect(level3.lineItems, 'Leaf node must have lineItems').toBeDefined();
    expect(level3.lineItems!.length, 'Leaf node must have at least 1 line item').toBeGreaterThanOrEqual(1);
  });

  // ── TREE-03: backward-compat regression for existing 2-level city budgets ───
  // These are READ-ONLY queries — no INSERT/UPDATE/DELETE (T-34-02 mitigation).
  //
  // SUBSTITUTION NOTE: The plan originally targeted Portland OR, San Jose CA, Dallas TX.
  // Live data inspection revealed these cities do NOT have the expected 2-level structure:
  //   - Portland OR: all budgets are depth-0 only (1-level flat list, no parent_id hierarchy)
  //   - San Jose CA: all budgets are depth-0 only (1-level flat list, no parent_id hierarchy)
  //   - Dallas TX: all budgets already have depth 0/1/2 ("Unknown" at each level — 3-level data)
  // Per the plan's substitution guidance: "If a city has no operating budget row [or wrong shape],
  // substitute another confirmed 2-level city from STATE.md's seeded list."
  // Substitutions (all confirmed max_depth=1 via live query before writing):
  //   Portland OR → Sacramento CA (depth 0+1, max_depth=1, 132 cats in FY2026)
  //   San Jose CA → Plano TX    (depth 0+1, max_depth=1, 116 cats in FY2025)
  //   Dallas TX   → Allen TX    (depth 0+1, max_depth=1, 16 cats in FY2025)

  it('TREE-03: Sacramento CA operating budget returns a 2-level tree (no depth-2 subcategories)', async () => {
    // budgets.municipality_id links directly to municipalities.id
    // (data_source_id is NULL for many budgets — join through municipalities directly)
    // Substitution: Sacramento CA confirmed max_depth=1 (true 2-level city)
    const { rows } = await pool.query<{ id: string }>(
      `SELECT b.id
       FROM treasury.budgets b
       JOIN treasury.municipalities m ON m.id = b.municipality_id
       WHERE m.name = $1 AND m.state = 'CA' AND b.dataset_type = 'operating'
       ORDER BY b.fiscal_year DESC LIMIT 1`,
      ['Sacramento']
    );
    expect(rows.length, 'Expected a Sacramento CA operating budget in the DB').toBeGreaterThan(0);
    const budgetId = rows[0].id;

    const { rows: catRows } = await pool.query<SimpleNode>(
      `SELECT id, parent_id, name, depth::int AS depth
       FROM treasury.budget_categories WHERE budget_id = $1 ORDER BY depth, sort_order`,
      [budgetId]
    );
    const tree = buildTreeFromRows(catRows, new Map());

    expect(tree.length, 'Sacramento tree must have at least 1 root category').toBeGreaterThan(0);
    const root = tree[0];
    expect(root.subcategories, 'Sacramento root must have subcategories (Level 2 exists — confirmed max_depth=1)').toBeDefined();
    // Assert the entire category set stays within depth 1 (covers all roots, not just tree[0])
    const maxDepth = catRows.reduce((m, r) => Math.max(m, r.depth), 0);
    expect(maxDepth, 'No category should reach depth 2 in a 2-level city (backward compat)').toBeLessThanOrEqual(1);
  });

  it('TREE-03: Plano TX operating budget returns a 2-level tree (no depth-2 subcategories)', async () => {
    // Substitution: Plano TX confirmed max_depth=1 (true 2-level city)
    const { rows } = await pool.query<{ id: string }>(
      `SELECT b.id
       FROM treasury.budgets b
       JOIN treasury.municipalities m ON m.id = b.municipality_id
       WHERE m.name = $1 AND m.state = 'TX' AND b.dataset_type = 'operating'
       ORDER BY b.fiscal_year DESC LIMIT 1`,
      ['Plano']
    );
    expect(rows.length, 'Expected a Plano TX operating budget in the DB').toBeGreaterThan(0);
    const budgetId = rows[0].id;

    const { rows: catRows } = await pool.query<SimpleNode>(
      `SELECT id, parent_id, name, depth::int AS depth
       FROM treasury.budget_categories WHERE budget_id = $1 ORDER BY depth, sort_order`,
      [budgetId]
    );
    const tree = buildTreeFromRows(catRows, new Map());

    expect(tree.length, 'Plano tree must have at least 1 root category').toBeGreaterThan(0);
    const root = tree[0];
    expect(root.subcategories, 'Plano root must have subcategories (Level 2 exists — confirmed max_depth=1)').toBeDefined();
    // Assert the entire category set stays within depth 1 (covers all roots, not just tree[0])
    const maxDepth = catRows.reduce((m, r) => Math.max(m, r.depth), 0);
    expect(maxDepth, 'No category should reach depth 2 in a 2-level city (backward compat)').toBeLessThanOrEqual(1);
  });

  it('TREE-03: Allen TX operating budget returns a 2-level tree (no depth-2 subcategories)', async () => {
    // Substitution: Allen TX confirmed max_depth=1 (true 2-level city)
    const { rows } = await pool.query<{ id: string }>(
      `SELECT b.id
       FROM treasury.budgets b
       JOIN treasury.municipalities m ON m.id = b.municipality_id
       WHERE m.name = $1 AND m.state = 'TX' AND b.dataset_type = 'operating'
       ORDER BY b.fiscal_year DESC LIMIT 1`,
      ['Allen']
    );
    expect(rows.length, 'Expected an Allen TX operating budget in the DB').toBeGreaterThan(0);
    const budgetId = rows[0].id;

    const { rows: catRows } = await pool.query<SimpleNode>(
      `SELECT id, parent_id, name, depth::int AS depth
       FROM treasury.budget_categories WHERE budget_id = $1 ORDER BY depth, sort_order`,
      [budgetId]
    );
    const tree = buildTreeFromRows(catRows, new Map());

    expect(tree.length, 'Allen tree must have at least 1 root category').toBeGreaterThan(0);
    const root = tree[0];
    expect(root.subcategories, 'Allen root must have subcategories (Level 2 exists — confirmed max_depth=1)').toBeDefined();
    // Assert the entire category set stays within depth 1 (covers all roots, not just tree[0])
    const maxDepth = catRows.reduce((m, r) => Math.max(m, r.depth), 0);
    expect(maxDepth, 'No category should reach depth 2 in a 2-level city (backward compat)').toBeLessThanOrEqual(1);
  });
});
