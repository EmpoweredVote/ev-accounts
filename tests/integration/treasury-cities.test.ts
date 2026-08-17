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
});
