import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import type { Express } from 'express';
// Static import — evaluated before the assignments below, so it sees the real
// DATABASE_URL rather than the placeholder this file installs for itself.
import { hasLiveDb } from '../helpers/liveDb.js';

// Set up test environment before any imports that read process.env.
// Real values win where supplied, so `DATABASE_URL=... npm test` hits a live DB.
process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = process.env['SUPABASE_URL'] || 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = process.env['SUPABASE_ANON_KEY'] || 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] =
  process.env['SUPABASE_SERVICE_ROLE_KEY'] || 'test-service-role-key';
process.env['DATABASE_URL'] =
  process.env['DATABASE_URL'] || 'postgresql://postgres:password@localhost:5432/postgres';
process.env['ADMIN_INGEST_TOKEN'] = process.env['ADMIN_INGEST_TOKEN'] || 'test-ingest-token';

let app: Express;

beforeAll(async () => {
  const mod = await import('../../backend/src/index.js');
  app = mod.app;
});

// ---------------------------------------------------------------------------
// Contract test for the BUDGET routes.
//
// ⚠ These were uncovered until 2026-08-31. `/cities` had a contract test, but the
// budget payload -- the one carrying the figure a reader actually looks at, and
// the axis labels printed beside it -- did not. mapBudget() and three SELECT
// lists could drop a column with nothing failing.
//
// Purpose: lock the four provenance axes onto the budget payload. Each says
// something different about the same number, and a reader shown the number
// without them is being told less than Treasury Tracker knows.
// ---------------------------------------------------------------------------

const LEGAL = {
  fund_scope: ['general_fund', 'total_governmental', 'all_funds', 'unknown'],
  basis: ['actual', 'adopted', 'unknown'],
  reporting_entity: ['primary_government', 'incl_component_units', 'unknown'],
  derivation: ['published', 'derived'],
  // AUDIT-GRADE. ⚠⚠ NOT a ranked ladder: `audited_ocboa` carries the SAME
  // independent-opinion assurance as `audited_gaap` on a non-GAAP measurement
  // basis. This array is the CHECK-constraint order and nothing more.
  audit_grade: [
    'audited_gaap', 'audited_ocboa', 'compiled_from_audited',
    'self_reported_unaudited', 'unknown',
  ],
} as const;

type Ds = Record<string, unknown>;

async function cities(): Promise<Array<Record<string, unknown>>> {
  const res = await request(app).get('/api/treasury/cities');
  if (res.status !== 200) return [];
  return res.body as Array<Record<string, unknown>>;
}

/** A city that has budget rows at all — for the broad "every axis is present" sweep. */
async function firstCityWithBudgets(): Promise<string | null> {
  for (const c of await cities()) {
    if (((c['available_datasets'] as unknown[]) ?? []).length > 0) return c['id'] as string;
  }
  return null;
}

/**
 * ⚠⚠ A city holding at least one row graded something OTHER than `unknown`.
 *
 * The first draft of this file used firstCityWithBudgets() throughout and landed
 * on Abingdon, whose four rows are all `unknown` — so the "graded rows need a
 * source" assertion below skipped every row and the test passed having measured
 * NOTHING. `unknown` is 68% of the table, so picking the alphabetically-first
 * city is very likely to pick a blind one.
 *
 * Any gate that can measure nothing must fail, not pass. Callers assert on the
 * `checked` count for that reason.
 */
async function firstCityWithGradedBudgets(): Promise<string | null> {
  for (const c of await cities()) {
    const ds = ((c['available_datasets'] as Ds[]) ?? []);
    if (ds.some((d) => d['audit_grade'] !== undefined && d['audit_grade'] !== 'unknown')) {
      return c['id'] as string;
    }
  }
  return null;
}

describe.skipIf(!hasLiveDb)('GET /api/treasury/cities/:cityId/budgets — contract', () => {
  it('every budget row carries all four provenance axes with legal values', async () => {
    const cityId = await firstCityWithBudgets();
    if (!cityId) return;

    const res = await request(app).get(`/api/treasury/cities/${cityId}/budgets`);
    expect(res.status).toBe(200);
    const budgets = res.body as Array<Record<string, unknown>>;
    expect(Array.isArray(budgets)).toBe(true);
    expect(budgets.length).toBeGreaterThan(0);

    for (const b of budgets) {
      for (const [axis, legal] of Object.entries(LEGAL)) {
        expect(b, `every budget row must carry ${axis}`).toHaveProperty(axis);
        expect(
          legal as readonly string[],
          `${axis} "${String(b[axis])}" is outside the CHECK constraint on treasury.budgets`
        ).toContain(b[axis]);
      }
    }
  });

  // ⚠ The whole point of the axis. A budget row that reports a grade but names no
  // document is an unsupported public claim about a government's books -- which is
  // why treasury.budgets carries `budgets_graded_rows_need_a_source_url`. This
  // asserts the API cannot serve one, since the constraint is invisible to callers.
  it('never serves a graded row without an attributable source', async () => {
    const cityId = await firstCityWithGradedBudgets();
    expect(cityId, 'no city exposes a graded row — the API is not surfacing audit_grade').not.toBeNull();

    const res = await request(app).get(`/api/treasury/cities/${cityId}/budgets`);
    expect(res.status).toBe(200);

    let checked = 0;
    for (const b of res.body as Array<Record<string, unknown>>) {
      if (b['audit_grade'] === 'unknown') continue;
      checked += 1;
      const info = b['data_source_info'] as Record<string, unknown> | null;
      expect(
        (info && typeof info['url'] === 'string' && info['url'] !== '') || Boolean(b['data_source']),
        `a row graded "${String(b['audit_grade'])}" must be attributable to a source`
      ).toBe(true);
    }
    // ⚠ Without this the test passes vacuously on an all-`unknown` city. It did.
    expect(checked, 'this gate measured no graded rows, so it proved nothing').toBeGreaterThan(0);
  });
});

describe.skipIf(!hasLiveDb)('GET /api/treasury/budgets/:id — contract', () => {
  it('carries a REAL grade, not just the column default', async () => {
    const cityId = await firstCityWithGradedBudgets();
    expect(cityId, 'no city exposes a graded row — the API is not surfacing audit_grade').not.toBeNull();

    const list = await request(app).get(`/api/treasury/cities/${cityId}/budgets`);
    expect(list.status).toBe(200);
    // ⚠ Deliberately a GRADED row, not `[0]`. audit_grade is NOT NULL DEFAULT
    // 'unknown', so a payload showing 'unknown' is consistent with the column
    // having been dropped from the SELECT list entirely — the default and the
    // failure mode are indistinguishable. Only a non-default value proves the
    // read. (Treasury Tracker has been bitten by a lying NOT NULL DEFAULT before:
    // fiscal_year_start_month DEFAULT 1 misreported ~18,700 rows.)
    const first = (list.body as Array<Record<string, unknown>>)
      .find((b) => b['audit_grade'] !== 'unknown');
    expect(first, 'expected at least one graded row on this city').toBeDefined();
    if (!first) return;

    // ⚠ getBudgetById() has its OWN SELECT list. It is the route the icicle detail
    // view reads, so a column dropped only here would surface as a figure whose
    // provenance silently vanishes on drill-down.
    const res = await request(app).get(`/api/treasury/budgets/${String(first['id'])}`);
    expect(res.status).toBe(200);
    const budget = res.body as Record<string, unknown>;
    expect(budget, 'the single-budget payload must carry audit_grade').toHaveProperty('audit_grade');
    expect(
      LEGAL.audit_grade as readonly string[],
      `audit_grade "${String(budget['audit_grade'])}" is outside the CHECK constraint`
    ).toContain(budget['audit_grade']);
    expect(budget['audit_grade'], 'the graded value must survive the drill-down read')
      .toBe(first['audit_grade']);
    expect(budget['audit_grade'], 'a defaulted `unknown` here would hide a dropped column')
      .not.toBe('unknown');
  });
});
