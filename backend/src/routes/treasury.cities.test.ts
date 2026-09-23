import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

/**
 * Route-layer coverage for GET /api/treasury/cities — src/routes/treasury.ts.
 *
 * Before this file NOTHING tested the route layer: the 422 contract
 * (INVALID_ENTITY_TYPE / INVALID_COUNTY_ID), the entity_type/state/county_id/
 * fields=index passthroughs, and the Cache-Control header all had zero
 * coverage. treasuryService.cities.test.ts only proves getCities() builds the
 * right SQL — it says nothing about whether the route actually calls it with
 * the right arguments, or whether a 422 ever ships as a 400, or whether
 * `?fields=index` still reaches getCities after some future refactor.
 *
 * ⚠ treasury.ts pulls in treasuryService.js at module scope, which imports
 * db.js — and the auth/requireAdmin middleware, which pull in supabase.js/
 * env.js — all of which validate env and process.exit(1) when it is absent,
 * as it is in this unit-test environment (no .env in this worktree, by
 * design). No importActual is possible here, so all three are fully mocked,
 * following publicCoverage.test.ts's and connect.setLocation.test.ts's
 * convention.
 */

const { mockGetCities, mockParseEntityTypes } = vi.hoisted(() => ({
  mockGetCities: vi.fn(),
  mockParseEntityTypes: vi.fn(),
}));

vi.mock('../lib/treasuryService.js', () => ({
  getCities: mockGetCities,
  parseEntityTypes: mockParseEntityTypes,
  // Everything else treasury.ts imports — unused by /cities but must exist
  // as functions or the route module fails to load them off the mock.
  getEntityAliases: vi.fn(),
  getCityById: vi.fn(),
  getBudgetsByCityId: vi.fn(),
  getBudgetById: vi.fn(),
  getLineItemsByBudgetId: vi.fn(),
  getLinkedTransactions: vi.fn(),
  searchCategories: vi.fn(),
  createCity: vi.fn(),
  createBudget: vi.fn(),
  createBudgetCategory: vi.fn(),
  createBudgetLineItem: vi.fn(),
  getEnrichmentQueueStatus: vi.fn(),
  getFederalContext: vi.fn(),
  getOrgFinancialSummary: vi.fn(),
}));

vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
  requireAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

vi.mock('../middleware/requireAdmin.js', () => ({
  requireAdmin: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

/**
 * A route test, not a retest of parseEntityTypes' own logic — that belongs to
 * (and is covered by) treasuryService.entityTypes.test.ts. This mirrors its
 * contract (mirrors KNOWN_ENTITY_TYPES / municipalities_entity_type_check) so
 * the route-level assertions below exercise the real branch behaviour instead
 * of an opaque stub.
 */
const KNOWN_ENTITY_TYPES = new Set([
  'city', 'county', 'township', 'village', 'borough',
  'nonprofit', 'state', 'municipality', 'special_district',
  'school_district', 'conservancy', 'library', 'town', 'federal',
]);
function realParseEntityTypes(raw: unknown): { values: string[] } | { invalid: string } {
  if (typeof raw !== 'string' || raw.trim() === '') return { values: [] };
  const values = raw.split(',').map((s) => s.trim()).filter((s) => s !== '');
  const invalid = values.find((v) => !KNOWN_ENTITY_TYPES.has(v));
  if (invalid !== undefined) return { invalid };
  return { values };
}

import treasuryRouter from './treasury.js';

async function makeApp() {
  const app = express();
  app.use('/api/treasury', treasuryRouter);
  return app;
}

const VALID_COUNTY_ID = '391bf791-1c1f-424f-a7a5-1b698c79093f';

beforeEach(() => {
  vi.clearAllMocks();
  mockParseEntityTypes.mockImplementation(realParseEntityTypes);
  mockGetCities.mockResolvedValue([]);
});

describe('GET /api/treasury/cities', () => {
  it('422s on an unknown entity_type, naming it in the message', async () => {
    const app = await makeApp();
    const res = await request(app).get('/api/treasury/cities?entity_type=citty');
    expect(res.status).toBe(422);
    expect(res.body.code).toBe('INVALID_ENTITY_TYPE');
    expect(res.body.message).toContain('citty');
    expect(mockGetCities).not.toHaveBeenCalled();
  });

  it('422s on a non-uuid county_id', async () => {
    const app = await makeApp();
    const res = await request(app).get('/api/treasury/cities?county_id=not-a-uuid');
    expect(res.status).toBe(422);
    expect(res.body.code).toBe('INVALID_COUNTY_ID');
    expect(mockGetCities).not.toHaveBeenCalled();
  });

  it('passes entity_type/state/county_id through to getCities exactly', async () => {
    const app = await makeApp();
    const res = await request(app).get(
      `/api/treasury/cities?entity_type=city,town&state=CA&county_id=${VALID_COUNTY_ID}`
    );
    expect(res.status).toBe(200);
    expect(mockGetCities).toHaveBeenCalledTimes(1);
    const [, , filters] = mockGetCities.mock.calls[0];
    expect(filters).toEqual({
      entityTypes: ['city', 'town'],
      state: 'CA',
      countyId: VALID_COUNTY_ID,
      fields: undefined,
    });
  });

  it('passes fields=index through to getCities', async () => {
    const app = await makeApp();
    const res = await request(app).get('/api/treasury/cities?fields=index');
    expect(res.status).toBe(200);
    expect(mockGetCities).toHaveBeenCalledTimes(1);
    const [, , filters] = mockGetCities.mock.calls[0];
    expect(filters.fields).toBe('index');
  });

  it('with no parameters, passes no filters and sets the cross-app Cache-Control contract', async () => {
    const app = await makeApp();
    const res = await request(app).get('/api/treasury/cities');
    expect(res.status).toBe(200);
    expect(mockGetCities).toHaveBeenCalledTimes(1);
    const [, , filters] = mockGetCities.mock.calls[0];
    expect(filters).toEqual({
      entityTypes: [],
      state: undefined,
      countyId: undefined,
      fields: undefined,
    });
    expect(res.headers['cache-control']).toBe(
      'public, max-age=300, stale-while-revalidate=3600'
    );
  });
});
