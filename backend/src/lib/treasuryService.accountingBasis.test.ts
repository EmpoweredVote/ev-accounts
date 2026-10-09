import { describe, it, expect, vi, beforeEach } from 'vitest';

const query = vi.hoisted(() => vi.fn());
vi.mock('./db.js', () => ({ pool: { query } }));

import { getBudgetsByCityId, getBudgetById } from './treasuryService.js';

/**
 * `accounting_basis` on the budget row.
 *
 * ⚠⚠ WHY THIS EXISTS. Treasury Tracker shipped the whole axis — a NOT NULL
 * column with a CHECK constraint, an evidenced registry, a stamper, a
 * vocabulary and a reader-facing chip — and the value never reached a reader,
 * because this service selects budget columns ONE BY ONE and nobody added it
 * here. Duvall, WA's rows said `cash` in the database and said nothing at all
 * on the page. The frontend prop was dead code for want of one column.
 *
 * ⚠ It is a SEPARATE QUESTION from `audit_grade`, and the pair is the whole
 * point: Duvall's figures are AUDITED (unmodified opinion on the BARS
 * regulatory basis) and NOT GAAP (adverse opinion on U.S. GAAP), both stated
 * in the same auditor's report. No single axis can carry both facts.
 *
 * ⚠⚠ Lives under `src/` deliberately: CI runs `npm run test:unit`
 * (`vitest run src scripts`), so a contract asserted in `tests/integration/`
 * is asserted NOWHERE. Same reasoning as treasuryService.cities.test.ts.
 */

const CITY = '11111111-1111-1111-1111-111111111111';
const BUDGET = '22222222-2222-2222-2222-222222222222';

/** A row as pg returns it — numerics and bigints as strings. */
const row = (accounting_basis: string) => ({
  id: BUDGET,
  municipality_id: CITY,
  fiscal_year: '2024',
  dataset_type: 'revenue',
  period_label: null,
  total_budget: '7074922',
  fund_scope: 'general_fund',
  basis: 'actual',
  reporting_entity: 'primary_government',
  derivation: 'published',
  audit_grade: 'audited_ocboa',
  accounting_basis,
  data_source: 'WA State Auditor — Duvall Annual Financial Report FY2024 (General Fund, Revenue by Source)',
  source_url: 'https://portal.sao.wa.gov/x',
  source_date: '2024-12-31',
  ds_display_name: null,
  ds_url: null,
  ds_base_url: null,
  ds_last_synced_at: null,
  hierarchy: null,
  generated_at: null,
  created_at: '2026-10-07T00:00:00.000Z',
  updated_at: '2026-10-07T00:00:00.000Z',
});

beforeEach(() => {
  query.mockReset();
  query.mockResolvedValue({ rows: [] });
});

/** The SQL text of the single call made. */
const sql = () => String(query.mock.calls[0][0]);

describe('accounting_basis reaches the API payload', () => {
  it('is SELECTed when a fiscal year is given', async () => {
    await getBudgetsByCityId(CITY, 2024);
    expect(sql()).toMatch(/\bb\.accounting_basis\b/);
  });

  it('is SELECTed when no fiscal year is given', async () => {
    // ⚠ A second, separately-written query. The two drifted apart before —
    // asserting only one would leave the other able to drop the column.
    await getBudgetsByCityId(CITY);
    expect(sql()).toMatch(/\bb\.accounting_basis\b/);
  });

  it('is SELECTed by the single-budget lookup', async () => {
    await getBudgetById(BUDGET);
    expect(sql()).toMatch(/\bb\.accounting_basis\b/);
  });

  it('is mapped onto the returned budget, not dropped by the mapper', async () => {
    // ⚠ Selecting the column and forgetting it in mapBudget would pass every
    // SQL assertion above and still return nothing to the reader.
    query.mockResolvedValue({ rows: [row('cash')] });
    const [budget] = await getBudgetsByCityId(CITY, 2024);
    expect(budget.accounting_basis).toBe('cash');
  });

  it('carries every legal value through verbatim', async () => {
    for (const v of ['gaap', 'modified_cash', 'cash', 'unknown']) {
      query.mockResolvedValue({ rows: [row(v)] });
      const [budget] = await getBudgetsByCityId(CITY, 2024);
      expect(budget.accounting_basis, v).toBe(v);
    }
  });

  it('does not disturb the four axes already carried', async () => {
    query.mockResolvedValue({ rows: [row('cash')] });
    const [budget] = await getBudgetsByCityId(CITY, 2024);
    expect(budget.fund_scope).toBe('general_fund');
    expect(budget.basis).toBe('actual');
    expect(budget.reporting_entity).toBe('primary_government');
    expect(budget.derivation).toBe('published');
    expect(budget.audit_grade).toBe('audited_ocboa');
  });
});
