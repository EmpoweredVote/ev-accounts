import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// ---------------------------------------------------------------------------
// WHY THIS FILE EXISTS.
//
// Essentials only needs to know WHICH politicians have a compass, but it used
// to fetch GET /compass/politicians for that: 4,227 rows, 3.3 MB, 0.5–1.8 s,
// and the profile's compass chart waited on it (measured 2026-10-23).
// GET /compass/politicians/ids serves just the ids. These tests pin:
//   - the route is not swallowed by a /politicians/:id route,
//   - it answers a plain array of id strings with a short public cache,
//   - the service query keeps the same published-season gate as the full list
//     (a draft season's answers must not make a person listable),
//   - the in-memory cache serves repeats and forgets failures.
// ---------------------------------------------------------------------------

const poolQueryMock = vi.hoisted(() => vi.fn());
vi.mock('../lib/db.js', () => ({ pool: { query: poolQueryMock, connect: vi.fn() } }));

vi.mock('../lib/supabase.js', () => ({
  adminRpc: vi.fn(),
  supabaseAdmin: {},
  supabaseAnon: { schema: () => ({ from: () => ({ select: () => ({}) }) }) },
  createUserClient: vi.fn(),
  requestDb: vi.fn(),
}));

vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: express.Request, _res: express.Response, next: express.NextFunction) => next(),
  requireAuth: (_req: express.Request, _res: express.Response, next: express.NextFunction) => next(),
}));

import compassRouter from './compass.js';
import { getCompassPoliticianIds, resetCompassPoliticianIdsCache } from '../lib/compassService.js';

const A = '11111111-1111-4111-8111-111111111111';
const B = '22222222-2222-4222-8222-222222222222';

const app = express();
app.use(express.json());
app.use('/api/compass', compassRouter);

beforeEach(() => {
  vi.clearAllMocks();
  resetCompassPoliticianIdsCache();
});

describe('GET /api/compass/politicians/ids', () => {
  it('returns a plain array of id strings', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ id: A }, { id: B }] });

    const res = await request(app).get('/api/compass/politicians/ids');

    expect(res.status).toBe(200);
    expect(res.body).toEqual([A, B]);
  });

  it('sets a short public cache', async () => {
    poolQueryMock.mockResolvedValue({ rows: [] });

    const res = await request(app).get('/api/compass/politicians/ids');

    expect(res.headers['cache-control']).toBe('public, max-age=300');
  });

  it('answers 500 without a cache header when the query fails', async () => {
    poolQueryMock.mockRejectedValue(new Error('db down'));
    vi.spyOn(console, 'error').mockImplementation(() => {});

    const res = await request(app).get('/api/compass/politicians/ids');

    expect(res.status).toBe(500);
    expect(res.body.code).toBe('INTERNAL_ERROR');
    expect(res.headers['cache-control']).toBeUndefined();
  });
});

describe('getCompassPoliticianIds', () => {
  it('uses the same active + published-season gate as the full list, and no heavy fields', async () => {
    poolQueryMock.mockResolvedValue({ rows: [] });

    await getCompassPoliticianIds();

    const sql = String(poolQueryMock.mock.calls[0][0]);
    expect(sql).toContain('p.is_active = true');
    expect(sql).toContain('inform.politician_answers');
    expect(sql).toMatch(/JOIN inform\.seasons s ON s\.id = a\.season_id AND s\.status <> 'draft'/);
    expect(sql).not.toContain('answered_topic_ids');
    expect(sql).not.toContain('politician_images');
  });

  it('serves repeats inside the TTL from memory', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ id: A }] });

    await getCompassPoliticianIds(1_000);
    const again = await getCompassPoliticianIds(30_000);

    expect(again).toEqual([A]);
    expect(poolQueryMock).toHaveBeenCalledTimes(1);
  });

  it('re-queries after the TTL', async () => {
    poolQueryMock.mockResolvedValueOnce({ rows: [{ id: A }] }).mockResolvedValueOnce({ rows: [{ id: B }] });

    await getCompassPoliticianIds(1_000);
    const later = await getCompassPoliticianIds(62_000);

    expect(later).toEqual([B]);
    expect(poolQueryMock).toHaveBeenCalledTimes(2);
  });

  it('does not cache a failure', async () => {
    poolQueryMock.mockRejectedValueOnce(new Error('db down')).mockResolvedValueOnce({ rows: [{ id: A }] });

    await expect(getCompassPoliticianIds(1_000)).rejects.toThrow('db down');
    await expect(getCompassPoliticianIds(2_000)).resolves.toEqual([A]);
  });
});
