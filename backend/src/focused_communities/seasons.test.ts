import { describe, it, expect, vi, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const query = vi.fn();
vi.mock('./config/database.js', () => ({ pool: { query: (...a: unknown[]) => query(...a) } }));

const store = new Map<string, unknown>();
vi.mock('../lib/cache.js', () => ({
  cache: {
    get: async (k: string) => (store.has(k) ? store.get(k) : null),
    set: async (k: string, v: unknown) => { store.set(k, v); },
    del: async (k: string) => { store.delete(k); },
  },
}));

// optionalAuth reduced to its outcomes: a valid token sets userId, anything else is a guest.
vi.mock('../middleware/auth.js', () => ({
  optionalAuth: async (req: express.Request, _res: express.Response, next: express.NextFunction) => {
    const h = req.headers.authorization;
    if (h === 'Bearer maven') Object.assign(req, { userId: 'u-maven' });
    else if (h === 'Bearer user') Object.assign(req, { userId: 'u1' });
    next();
  },
}));
// roleService's own dependency on supabase.js process.exit()s without env vars, so stub it.
vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, adminRpc: async () => ({ data: [], error: null }) }));
// Only the role lookup is mocked; the real checkRole runs against grants shaped like UserRoleGrant.
const grant = (slug: string) => ({
  id: 'g1', role_id: 'r1', slug, name: slug, granted_at: '2026-01-01T00:00:00+00:00',
  feature_scope: 'compass', jurisdiction_geoid: null, resource_id: null, granted_by_display_name: null,
});
vi.mock('../lib/roleService.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../lib/roleService.js')>()),
  getCachedUserRoles: async (userId: string) => (userId === 'u-maven' ? [grant('maven')] : []),
}));

const { seasonsRouter } = await import('./routes/seasons.js');
const app = express();
app.use('/fc/api', seasonsRouter);

const rows = (r: unknown[]) => ({ rows: r, rowCount: r.length });
const TS = '2026-04-17T12:00:00.123456+00:00';
const s = (n: number, status: string) => ({
  season_number: n, season_name: `S${n}`, status, opened_at: status === 'draft' ? null : TS, closed_at: status === 'closed' ? TS : null,
});
const community = rows([{ topic_id: 't1' }]);
const PATH = '/fc/api/communities/c1/seasons';

beforeEach(() => {
  query.mockReset();
  store.clear();
});

describe('GET /communities/:id/seasons', () => {
  it('lists only the seasons this topic appears in', async () => {
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(rows([s(2, 'open'), s(1, 'closed')]));
    const res = await request(app).get(PATH);
    expect(res.status).toBe(200);
    expect(res.body.data.map((d: { number: number }) => d.number)).toEqual([1, 2]);
    expect(res.body.data[0]).toEqual({ number: 1, name: 'S1', status: 'closed', openedAt: TS, closedAt: TS });
    expect(query.mock.calls[1][0]).toContain('connect.get_season_list($1, $2)');
    expect(query.mock.calls[1][1]).toEqual(['t1', false]);
  });

  it('omits draft seasons for an anonymous caller', async () => {
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(rows([s(1, 'closed'), s(2, 'open')]));
    const res = await request(app).get(PATH);
    expect(res.body.data.some((d: { status: string }) => d.status === 'draft')).toBe(false);
    expect(query.mock.calls[1][1]).toEqual(['t1', false]);
  });

  it('includes draft seasons for a maven', async () => {
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(rows([s(1, 'closed'), s(2, 'open'), s(3, 'draft')]));
    const res = await request(app).get(PATH).set('Authorization', 'Bearer maven');
    expect(res.body.data.map((d: { number: number }) => d.number)).toEqual([1, 2, 3]);
    expect(query.mock.calls[1][1]).toEqual(['t1', true]);
    expect(res.headers['cache-control']).toBe('private, no-store');
  });

  it('reports the open season as defaultSeason', async () => {
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(rows([s(1, 'closed'), s(2, 'open'), s(3, 'draft')]));
    const res = await request(app).get(PATH).set('Authorization', 'Bearer maven');
    expect(res.body.meta.defaultSeason).toBe(2);
  });

  it('falls back to the latest season when none is open', async () => {
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(rows([s(2, 'closed'), s(1, 'closed')]));
    const res = await request(app).get(PATH);
    expect(res.body.meta.defaultSeason).toBe(2);
    expect(res.body.data.map((d: { number: number }) => d.number)).toEqual([1, 2]);
  });

  it('never writes a maven response to the shared cache, so a later guest sees no drafts', async () => {
    query
      .mockResolvedValueOnce(community).mockResolvedValueOnce(rows([s(1, 'closed'), s(2, 'open'), s(3, 'draft')]))
      .mockResolvedValueOnce(community).mockResolvedValueOnce(rows([s(1, 'closed'), s(2, 'open')]));
    await request(app).get(PATH).set('Authorization', 'Bearer maven');
    expect(store.size).toBe(0);
    const guest = await request(app).get(PATH);
    expect(guest.body.data.map((d: { number: number }) => d.number)).toEqual([1, 2]);
    expect(query.mock.calls[3][1]).toEqual(['t1', false]);
    expect([...store.keys()]).toEqual(['fc:seasons:t1:false']);
  });

  it('answers 200 with an empty list and a null default when the topic has no seasons', async () => {
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(rows([]));
    const res = await request(app).get(PATH);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ data: [], meta: { defaultSeason: null } });
  });

  it('does not serve a cached guest body to a maven', async () => {
    const pinned = { data: [{ number: 99 }], meta: { defaultSeason: 99 } };
    store.set('fc:seasons:t1:false', pinned);
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(rows([s(1, 'closed'), s(3, 'draft')]));
    const res = await request(app).get(PATH).set('Authorization', 'Bearer maven');
    expect(res.body).not.toEqual(pinned);
    expect(res.body.data.map((d: { number: number }) => d.number)).toEqual([1, 3]);
    expect(store.get('fc:seasons:t1:false')).toBe(pinned);
  });

  it('404s for an unknown, malformed, or topic-less community', async () => {
    query.mockResolvedValueOnce(rows([]));
    expect((await request(app).get(PATH)).status).toBe(404);
    query.mockRejectedValueOnce(Object.assign(new Error('bad uuid'), { code: '22P02' }));
    expect((await request(app).get(PATH)).status).toBe(404);
    query.mockResolvedValueOnce(rows([{ topic_id: null }]));
    expect((await request(app).get(PATH)).status).toBe(404);
  });
});
