import { describe, it, expect, vi, beforeEach } from 'vitest';

const query = vi.hoisted(() => vi.fn());
vi.mock('./db.js', () => ({ pool: { query } }));

import { getBudgetById } from './treasuryService.js';

/**
 * A NULL money column must survive as null, not become 0.
 *
 * ── ⚠⚠ WHY: WE PUBLISHED A $0 BUDGET FOR GOVERNMENTS THAT NEVER ADOPTED ONE ──
 *
 * `treasury.budget_line_items.approved_amount` is nullable and NULL is the
 * honest value for a source that publishes no adopted budget. The WA SAO
 * loader writes it deliberately — `waSaoLoad.mjs` emits `aa: null` on every
 * item, because a BARS or GAAP statement reports what was SPENT and never what
 * was budgeted.
 *
 * The reader then coerced that NULL to 0, and Treasury Tracker rendered
 * "Budgeted $0 / Actual $140,249,393" with a red −100% variance for the City
 * of Redmond. The database held the truth and this mapper threw it away.
 *
 * ⚠ The repo has seen the symptom before and fixed a DIFFERENT cause:
 * `buildBudgetTree.mjs` once had `a`/`aa` inverted, leaving approved_amount
 * NULL for San Francisco — "19,299 line items rendering as Budgeted $0 /
 * Actual $15.9B with a nonsense variance, and a sort key that was uniformly
 * zero". That was a BUG and was fixed by populating the column. Washington's
 * NULLs are not a bug; they are the fact. Only preserving NULL tells the two
 * cases apart.
 *
 * ⚠ SYMMETRIC. An adopted-budget-only source has NULL actuals, and coercing
 * those to 0 says the government SPENT nothing — the same lie, mirrored.
 *
 * ⚠ Every neighbouring nullable field in this same object literal — basePay,
 * benefits, overtime, other — already preserves null. The write path stores
 * `data.approvedAmount ?? null` and the route schema declares both
 * `.optional().nullable()`. The schema, the writer and the validator all agreed
 * NULL was legal; the reader was the only place that disagreed.
 */

const BUDGET = '22222222-2222-2222-2222-222222222222';
const CAT = '33333333-3333-3333-3333-333333333333';

const budgetRow = {
  id: BUDGET,
  municipality_id: '11111111-1111-1111-1111-111111111111',
  fiscal_year: '2024',
  dataset_type: 'operating',
  period_label: null,
  total_budget: '140249393',
  fund_scope: 'general_fund',
  basis: 'actual',
  reporting_entity: 'primary_government',
  derivation: 'published',
  audit_grade: 'audited_gaap',
  accounting_basis: 'gaap',
  data_source: 'WA State Auditor — Redmond Annual Financial Report FY2024',
  source_url: null,
  source_date: null,
  ds_display_name: null,
  ds_url: null,
  ds_base_url: null,
  ds_last_synced_at: null,
  hierarchy: null,
  generated_at: null,
  created_at: '2026-10-07T00:00:00.000Z',
  updated_at: '2026-10-07T00:00:00.000Z',
};

const categoryRow = {
  id: CAT,
  budget_id: BUDGET,
  parent_id: null,
  depth: 0,
  sort_order: 0,
  name: 'Current',
  amount: '136809979',
  actual_amount: null,
  percentage: '97.5',
  color: '',
  description: null,
  why_matters: null,
  historical_change: null,
  item_count: '6',
  link_key: 'current',
  enrich_plain_name: null,
  origin_program_name: null,
};

/** As pg returns it: a NULL numeric column is JS null. */
const lineItemRow = (over: Record<string, unknown> = {}) => ({
  id: '44444444-4444-4444-4444-444444444444',
  category_id: CAT,
  description: 'Public safety',
  approved_amount: null,
  actual_amount: '66240230',
  base_pay: null,
  benefits: null,
  overtime: null,
  other: null,
  start_date: null,
  vendor: null,
  date: null,
  payment_method: null,
  invoice_number: null,
  fund: null,
  expense_category: null,
  ...over,
});

/** getBudgetById queries in order: budget, categories, line items. */
const mockThree = (items: unknown[]) => {
  query.mockReset();
  query
    .mockResolvedValueOnce({ rows: [budgetRow] })
    .mockResolvedValueOnce({ rows: [categoryRow] })
    .mockResolvedValueOnce({ rows: items });
};

const firstItem = async () => {
  const budget = await getBudgetById(BUDGET);
  return budget!.categories[0].lineItems![0];
};

beforeEach(() => {
  query.mockReset();
  query.mockResolvedValue({ rows: [] });
});

describe('a NULL money column survives as null', () => {
  it('keeps a NULL approved_amount as null, not 0', async () => {
    // ⚠⚠ The claim itself. `0` here is Treasury Tracker telling a reader the
    // City of Redmond adopted a budget of nothing.
    mockThree([lineItemRow()]);
    expect((await firstItem()).approvedAmount).toBeNull();
  });

  it('keeps a NULL actual_amount as null, not 0', async () => {
    // The mirrored lie: an adopted-budget-only source saying $0 was spent.
    mockThree([lineItemRow({ approved_amount: '5000000', actual_amount: null })]);
    expect((await firstItem()).actualAmount).toBeNull();
  });

  it('still returns a real figure as a number', async () => {
    mockThree([lineItemRow()]);
    const li = await firstItem();
    expect(li.actualAmount).toBe(66_240_230);
    expect(typeof li.actualAmount).toBe('number');
  });

  it('preserves a REAL ZERO, which is not the same as absence', async () => {
    // ⚠⚠ THE WHOLE POINT OF THE CHANGE. A source that genuinely budgeted $0
    // for a line must still say 0 — otherwise this fix trades one wrong
    // answer for another, and no reader can tell "nothing" from "not stated".
    mockThree([lineItemRow({ approved_amount: '0', actual_amount: '0' })]);
    const li = await firstItem();
    expect(li.approvedAmount).toBe(0);
    expect(li.actualAmount).toBe(0);
  });

  it('does not disturb the other nullable money fields', async () => {
    mockThree([lineItemRow({ base_pay: '1000', benefits: null })]);
    const li = await firstItem();
    expect(li.basePay).toBe(1000);
    expect(li.benefits).toBeNull();
  });

  it('carries the description and non-money fields through unchanged', async () => {
    mockThree([lineItemRow({ vendor: 'Acme', fund: 'General' })]);
    const li = await firstItem();
    expect(li.description).toBe('Public safety');
    expect(li.vendor).toBe('Acme');
    expect(li.fund).toBe('General');
  });
});
