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
// Contract test for GET /api/treasury/cities
//
// Purpose: Lock in the response shape that Essentials Results.jsx depends on
// for the INTG-03 Treasury CTA feature. If the shape changes silently, this
// test fails before the frontend breaks.
//
// Required fields per INTG-03 implementation (122-RESEARCH.md §INTG-03):
//   id, name, state, available_datasets
// ---------------------------------------------------------------------------

const REQUIRED_CITY_KEYS = ['id', 'name', 'state', 'available_datasets'] as const;

// Every assertion here reads real rows through the route, so the suite needs a
// live database. Without one, skip rather than fail: see tests/helpers/liveDb.ts.
describe.skipIf(!hasLiveDb)('GET /api/treasury/cities — contract', () => {
  it('returns 200 with an array', async () => {
    const res = await request(app).get('/api/treasury/cities');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('each city entry has the required INTG-03 shape keys', async () => {
    const res = await request(app).get('/api/treasury/cities');
    expect(res.status).toBe(200);

    const cities: unknown[] = res.body as unknown[];

    // Shape test applies only when there is at least one city
    if (cities.length === 0) return;

    for (const city of cities) {
      expect(typeof city).toBe('object');
      expect(city).not.toBeNull();
      for (const key of REQUIRED_CITY_KEYS) {
        expect(city, `city entry is missing required key: ${key}`).toHaveProperty(key);
      }
      // available_datasets must be an array (Essentials uses .length > 0 to gate CTA)
      expect(
        Array.isArray((city as Record<string, unknown>)['available_datasets']),
        'available_datasets must be an array'
      ).toBe(true);
    }
  });

  // Phase 50: available_datasets entries expose period_label (null for normal
  // annual rows; the FY1976 Transition Quarter row carries the TQ string). The
  // frontend uses this to disambiguate FY1976 from the Transition Quarter.
  it('available_datasets entries expose a period_label key', async () => {
    const res = await request(app).get('/api/treasury/cities');
    expect(res.status).toBe(200);
    const cities = res.body as Array<Record<string, unknown>>;
    if (cities.length === 0) return;
    for (const city of cities) {
      const datasets = (city['available_datasets'] as Array<Record<string, unknown>>) ?? [];
      for (const ds of datasets) {
        expect(ds, 'each dataset entry must carry period_label (may be null)').toHaveProperty('period_label');
      }
    }
  });

  // SCOPE-01: available_datasets entries expose fund_scope -- which funds the row's
  // total covers. Exposed at the dataset level, not just on the budget, so the
  // frontend can label scope and hold `unknown` rows out of cross-entity comparison
  // while building the year/dataset picker, without fetching every budget first.
  //
  // `unknown` is a LEGAL, EXPECTED value, not a failure: as of 2026-08-17 it covers
  // 26,523 of 79,927 rows. A source is only classified against an independent
  // document, so an unreconciled source stays honestly unclassified. This test must
  // never be "fixed" by asserting that unknown is absent.
  it('available_datasets entries expose a fund_scope key with a legal value', async () => {
    const LEGAL_SCOPES = ['general_fund', 'total_governmental', 'all_funds', 'unknown'];
    const res = await request(app).get('/api/treasury/cities');
    expect(res.status).toBe(200);
    const cities = res.body as Array<Record<string, unknown>>;
    if (cities.length === 0) return;
    for (const city of cities) {
      const datasets = (city['available_datasets'] as Array<Record<string, unknown>>) ?? [];
      for (const ds of datasets) {
        expect(ds, 'each dataset entry must carry fund_scope').toHaveProperty('fund_scope');
        expect(
          LEGAL_SCOPES,
          `fund_scope "${String(ds['fund_scope'])}" is outside the CHECK constraint on treasury.budgets`
        ).toContain(ds['fund_scope']);
      }
    }
  });

  // SCOPE-04: available_datasets entries expose `derivation` -- did a government
  // PUBLISH this figure, or did Treasury Tracker compute it from published
  // components? It rides on the dataset entry, not only the budget, so the series
  // pill can say "derived" at FIRST PAINT; a pill that renders unmarked until a
  // budget row loads is the mislabel window SCOPE-04 exists to close.
  //
  // ⚠ fund_scope alone cannot carry this. `total_governmental` holds BOTH published
  // rows (MN OSA, Ohio AOS) and CA rows Treasury Tracker derived, so without this
  // key a reader sees one label over two epistemically different things.
  it('available_datasets entries expose a derivation key with a legal value', async () => {
    const LEGAL_DERIVATIONS = ['published', 'derived'];
    const res = await request(app).get('/api/treasury/cities');
    expect(res.status).toBe(200);
    const cities = res.body as Array<Record<string, unknown>>;
    if (cities.length === 0) return;
    for (const city of cities) {
      const datasets = (city['available_datasets'] as Array<Record<string, unknown>>) ?? [];
      for (const ds of datasets) {
        expect(ds, 'each dataset entry must carry derivation').toHaveProperty('derivation');
        expect(
          LEGAL_DERIVATIONS,
          `derivation "${String(ds['derivation'])}" is outside the CHECK constraint on treasury.budgets`
        ).toContain(ds['derivation']);
      }
    }
  });

  // AUDIT-GRADE: available_datasets entries expose `audit_grade` -- what level of
  // independent assurance stands behind the figure. Treasury Tracker has graded
  // 88,820 rows across eight loading sessions and, until this key existed, a reader
  // could see NONE of them.
  //
  // ⚠ `unknown` is the MAJORITY value (60,368 of 88,820 rows as of 2026-08-31) and
  // is LEGAL and EXPECTED. It means nobody has looked yet -- an honesty marker, never
  // a guess and never a judgement about the government. This test must never be
  // "fixed" by asserting that unknown is absent.
  //
  // ⚠ The five values are NOT a ranked ladder. `audited_ocboa` carries the SAME
  // independent-opinion assurance as `audited_gaap` on a different measurement
  // basis, so the list order below is the CHECK-constraint order and nothing more.
  it('available_datasets entries expose an audit_grade key with a legal value', async () => {
    const LEGAL_GRADES = [
      'audited_gaap', 'audited_ocboa', 'compiled_from_audited',
      'self_reported_unaudited', 'unknown',
    ];
    const res = await request(app).get('/api/treasury/cities');
    expect(res.status).toBe(200);
    const cities = res.body as Array<Record<string, unknown>>;
    if (cities.length === 0) return;
    for (const city of cities) {
      const datasets = (city['available_datasets'] as Array<Record<string, unknown>>) ?? [];
      for (const ds of datasets) {
        expect(ds, 'each dataset entry must carry audit_grade').toHaveProperty('audit_grade');
        expect(
          LEGAL_GRADES,
          `audit_grade "${String(ds['audit_grade'])}" is outside the CHECK constraint on treasury.budgets`
        ).toContain(ds['audit_grade']);
      }
    }
  });
});

// ---------------------------------------------------------------------------
// ?datasets=summary — the payload projection.
//
// ⚠⚠ WHY THIS MODE EXISTS. `available_datasets` carries ONE ENTRY PER BUDGET ROW
// and is 97.1% of a 23.5 MB response that the Treasury Tracker frontend fetches
// on every page load — to look up ONE id. It grows with every load: the Michigan
// statewide sweep alone took it from 18.4 MB to 23.5 MB, and Michigan's
// townships and villages would roughly double it again.
//
// The full per-(year, dataset_type, scope, basis, derivation, audit_grade)
// detail is only needed for the ONE entity being viewed, which the frontend
// fetches from /treasury/cities/:id. The list needs "does this entity have
// data", which years, and which dataset types — for search, the browse grids and
// the entity switcher.
//
// ⚠ OPT-IN, and the default response is UNCHANGED. Trimming by default would be
// a silent breaking change for any consumer not in this repo.
// ---------------------------------------------------------------------------
describe.skipIf(!hasLiveDb)('GET /api/treasury/cities?datasets=summary — contract', () => {
  it('replaces available_datasets with a compact dataset_summary', async () => {
    const res = await request(app).get('/api/treasury/cities?datasets=summary');
    expect(res.status).toBe(200);
    const cities = res.body as Array<Record<string, unknown>>;
    expect(Array.isArray(cities)).toBe(true);
    if (cities.length === 0) return;

    for (const city of cities) {
      expect(city, 'summary mode must not ship the per-row array').not.toHaveProperty('available_datasets');
      expect(city, 'every entity must carry dataset_summary').toHaveProperty('dataset_summary');
      const s = city['dataset_summary'] as Record<string, unknown>;
      expect(Array.isArray(s['years']), 'years must be an array').toBe(true);
      expect(Array.isArray(s['dataset_types']), 'dataset_types must be an array').toBe(true);
    }
  });

  // ⚠ The list is what decides whether an entity is offered at all. If summary
  // mode disagreed with the full mode about WHICH entities have data, the browse
  // grids and the search would quietly start hiding places that do.
  it('agrees with the full response about which entities have data', async () => {
    const [full, summary] = await Promise.all([
      request(app).get('/api/treasury/cities'),
      request(app).get('/api/treasury/cities?datasets=summary'),
    ]);
    expect(full.status).toBe(200);
    expect(summary.status).toBe(200);
    const a = full.body as Array<Record<string, unknown>>;
    const b = summary.body as Array<Record<string, unknown>>;
    expect(b.length).toBe(a.length);

    const withDataFull = new Set(a
      .filter((c) => ((c['available_datasets'] as unknown[]) ?? []).length > 0)
      .map((c) => c['id'] as string));
    const withDataSummary = new Set(b
      .filter((c) => (((c['dataset_summary'] as Record<string, unknown>)?.['years'] as unknown[]) ?? []).length > 0)
      .map((c) => c['id'] as string));
    expect(withDataSummary.size).toBe(withDataFull.size);
    expect([...withDataSummary].every((id) => withDataFull.has(id))).toBe(true);
  });

  // ⚠⚠ The years drive the year picker and the "FY2010-FY2025" ranges the browse
  // grids print. A summary that lost a year would silently make a series look
  // shorter than it is.
  it('reproduces exactly the distinct years and dataset types of the full response', async () => {
    const [full, summary] = await Promise.all([
      request(app).get('/api/treasury/cities'),
      request(app).get('/api/treasury/cities?datasets=summary'),
    ]);
    const byId = new Map((summary.body as Array<Record<string, unknown>>)
      .map((c) => [c['id'] as string, c['dataset_summary'] as Record<string, unknown>]));

    let checked = 0;
    for (const city of full.body as Array<Record<string, unknown>>) {
      const ds = (city['available_datasets'] as Array<Record<string, unknown>>) ?? [];
      if (ds.length === 0) continue;
      checked += 1;
      const s = byId.get(city['id'] as string);
      expect(s, `no summary for ${String(city['name'])}`).toBeDefined();
      expect(new Set(s!['years'] as number[]))
        .toEqual(new Set(ds.map((d) => d['fiscal_year'])));
      expect(new Set(s!['dataset_types'] as string[]))
        .toEqual(new Set(ds.map((d) => d['dataset_type'])));
    }
    // ⚠ A gate that can measure nothing must FAIL, not pass.
    expect(checked, 'no entity with data was compared').toBeGreaterThan(0);
  });

  // The whole point: it has to actually be smaller.
  it('is dramatically smaller than the full response', async () => {
    const [full, summary] = await Promise.all([
      request(app).get('/api/treasury/cities'),
      request(app).get('/api/treasury/cities?datasets=summary'),
    ]);
    const a = JSON.stringify(full.body).length;
    const b = JSON.stringify(summary.body).length;
    expect(b, `summary ${b} vs full ${a}`).toBeLessThan(a / 5);
  });

  // ⚠ Any other value, including none, must behave exactly as before.
  it('leaves the default response untouched', async () => {
    for (const q of ['', '?datasets=full', '?datasets=nonsense']) {
      const res = await request(app).get(`/api/treasury/cities${q}`);
      expect(res.status, q).toBe(200);
      const cities = res.body as Array<Record<string, unknown>>;
      if (cities.length === 0) continue;
      expect(cities[0], q).toHaveProperty('available_datasets');
      expect(cities[0], q).not.toHaveProperty('dataset_summary');
    }
  });
});
