/**
 * GET /api/treasury/coverage — the public coverage catalog.
 *
 * ⚠⚠ The load-bearing assertion here is `Access-Control-Allow-Credentials`
 * being ABSENT. A browser rejects that header alongside
 * `Access-Control-Allow-Origin: *`, so if the route ever picks it up (by being
 * mounted after the app-wide credentialed CORS allowlist) this endpoint breaks
 * in exactly the cross-origin consumers it exists for — and every server-side
 * test still passes, because the contradiction is enforced by the browser.
 * That is why it is asserted explicitly rather than assumed.
 */

import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const { mockGetCoverageCatalog } = vi.hoisted(() => ({
  mockGetCoverageCatalog: vi.fn(),
}));

// Full mock (no importActual): the real module pulls in ./db.js, which
// validates DATABASE_URL/SUPABASE_* at import time and process.exits when they
// are absent, as they are in this unit-test environment.
vi.mock('../lib/treasuryService.js', () => ({
  getCoverageCatalog: mockGetCoverageCatalog,
}));

const CATALOG = {
  generatedAt: '2026-09-14T00:00:00.000Z',
  cities: [{ label: 'Bloomington', geoids: ['1805860'], state: 'IN', slug: 'bloomington-in' }],
  counties: [{ label: 'Monroe County', geoids: ['18105'], state: 'IN', slug: 'monroe-county-in' }],
  states: [{ label: 'Indiana', abbrev: 'IN', slug: 'indiana-in' }],
  federal: { label: 'United States', slug: 'united-states-us' },
};

async function makeApp() {
  const { default: router } = await import('./publicCoverage.js');
  const app = express();
  app.use('/api/treasury/coverage', router);
  return app;
}

describe('GET /api/treasury/coverage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockGetCoverageCatalog.mockResolvedValue(CATALOG);
  });

  it('returns 200 and the catalog', async () => {
    const app = await makeApp();
    const res = await request(app).get('/api/treasury/coverage');
    expect(res.status).toBe(200);
    expect(res.body.cities[0].slug).toBe('bloomington-in');
    expect(res.body.counties[0].geoids).toEqual(['18105']);
    expect(res.body.states[0].abbrev).toBe('IN');
    expect(res.body.federal.slug).toBe('united-states-us');
    expect(res.body.generatedAt).toBeTruthy();
  });

  it('is readable from any origin', async () => {
    const app = await makeApp();
    const res = await request(app)
      .get('/api/treasury/coverage')
      .set('Origin', 'https://civicspaces.example');
    expect(res.headers['access-control-allow-origin']).toBe('*');
  });

  // ⚠⚠ THE ONE THAT MATTERS. See the file header.
  it('does NOT send Access-Control-Allow-Credentials', async () => {
    const app = await makeApp();
    const res = await request(app)
      .get('/api/treasury/coverage')
      .set('Origin', 'https://civicspaces.example');
    expect(res.headers['access-control-allow-credentials']).toBeUndefined();
  });

  it('is cacheable', async () => {
    const app = await makeApp();
    const res = await request(app).get('/api/treasury/coverage');
    expect(res.headers['cache-control']).toMatch(/max-age=3600/);
  });

  it('500s without leaking the error', async () => {
    mockGetCoverageCatalog.mockRejectedValue(new Error('pool exploded'));
    const app = await makeApp();
    const res = await request(app).get('/api/treasury/coverage');
    expect(res.status).toBe(500);
    expect(JSON.stringify(res.body)).not.toContain('pool exploded');
  });
});
