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

describe('GET /communities/:id/seasons/:number', () => {
  const SP = '/fc/api/communities/c1/seasons';
  const list = rows([s(1, 'closed'), s(2, 'open'), s(3, 'draft')]);
  const detail = (over: Record<string, unknown> = {}) => rows([{
    season_number: 2, season_name: 'S2', status: 'open', question_text: 'Q?', change_class: 'substantive',
    season_note: 'sn', topic_note: 'tn', rationale: 'why', rung_map: { 1: 1, 2: 2, 3: 3, 4: 4, 5: 5 }, ...over,
  }]);
  const openChairs = (n = 3) => rows(Array.from({ length: n }, (_, i) => ({
    position: i + 1, text: `chair ${i}`, description: i === 0 ? null : 'd', supporting_points: ['p'], example_perspectives: ['e'],
  })));
  const closedChairs = (n = 3) => rows(Array.from({ length: n }, (_, i) => ({
    ordinal: i + 1, text: `old ${i}`, description: i === 0 ? null : 'd', supporting_points: ['p'], example_perspectives: ['e'],
  })));
  const sql = (i: number) => String(query.mock.calls[i][0]);
  const openFlow = () => query.mockResolvedValueOnce(community).mockResolvedValueOnce(list)
    .mockResolvedValueOnce(detail()).mockResolvedValueOnce(openChairs());
  const closedFlow = () => query.mockResolvedValueOnce(community).mockResolvedValueOnce(list)
    .mockResolvedValueOnce(detail({ season_number: 1, status: 'closed' })).mockResolvedValueOnce(closedChairs());

  it('returns the question, chairs and notes for a season', async () => {
    openFlow();
    const res = await request(app).get(`${SP}/2`);
    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({
      season: { number: 2, name: 'S2', status: 'open', openedAt: TS, closedAt: null },
      questionText: 'Q?', changeClass: 'substantive', seasonNote: 'sn', topicNote: 'tn', isFallback: false,
    });
    expect(res.body.data.chairs.map((c: { text: string }) => c.text)).toEqual(['chair 0', 'chair 1', 'chair 2']);
    expect(res.body.data.chairs[0]).toEqual({
      text: 'chair 0', description: null, supportingPoints: ['p'], examplePerspectives: ['e'], changeSince: null,
    });
  });

  it('reads chairs from compass_stances for the open season', async () => {
    openFlow();
    await request(app).get(`${SP}/2`);
    expect(sql(3)).toContain('connect.get_stances_for_community($1)');
    expect(query.mock.calls[3][1]).toEqual(['c1']);
    expect(query.mock.calls.some((c) => String(c[0]).includes('get_season_chairs'))).toBe(false);
  });

  it('reads chairs from revisions for a closed season', async () => {
    closedFlow();
    const res = await request(app).get(`${SP}/1`);
    expect(sql(3)).toContain('connect.get_season_chairs($1, $2, $3)');
    expect(query.mock.calls[3][1]).toEqual(['t1', 1, false]);
    expect(res.body.data.chairs.map((c: { text: string }) => c.text)).toEqual(['old 0', 'old 1', 'old 2']);
    expect(query.mock.calls.some((c) => String(c[0]).includes('get_stances_for_community'))).toBe(false);
  });

  it('never includes a position or ordinal number in the body (open season path)', async () => {
    openFlow();
    const res = await request(app).get(`${SP}/2`);
    const body = JSON.stringify(res.body);
    expect(body).not.toMatch(/"position"/);
    expect(body).not.toMatch(/"ordinal"/);
    expect(body).not.toMatch(/"value"/);
  });

  it('never includes ordinal in the body (closed season path)', async () => {
    closedFlow();
    const res = await request(app).get(`${SP}/1`);
    expect(JSON.stringify(res.body)).not.toMatch(/"ordinal"|"position"/);
  });

  it('never includes rung_map in the body, even for a maven', async () => {
    openFlow();
    const res = await request(app).get(`${SP}/2`).set('Authorization', 'Bearer maven');
    expect(res.status).toBe(200);
    expect(JSON.stringify(res.body)).not.toContain('rung_map');
    expect(JSON.stringify(res.body)).not.toContain('rungMap');
  });

  it('asks the database for chairs in explicit ladder order', async () => {
    openFlow();
    await request(app).get(`${SP}/2`);
    expect(sql(3)).toMatch(/ORDER BY position ASC/);
    closedFlow();
    await request(app).get(`${SP}/1`);
    expect(sql(7)).toMatch(/ORDER BY ordinal ASC/);
  });

  it('omits rationale for a non-maven caller', async () => {
    openFlow();
    const res = await request(app).get(`${SP}/2`).set('Authorization', 'Bearer user');
    expect(res.body.data.rationale).toBeNull();
  });

  it('includes rationale for a maven and bypasses the cache', async () => {
    openFlow();
    const res = await request(app).get(`${SP}/2`).set('Authorization', 'Bearer maven');
    expect(res.body.data.rationale).toBe('why');
    expect(res.headers['cache-control']).toBe('private, no-store');
    expect(store.size).toBe(0);
    expect(query.mock.calls[2][1]).toEqual(['t1', 2, true]);
  });

  it('404s a draft season for a non-maven, never 403', async () => {
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(list);
    const res = await request(app).get(`${SP}/3`);
    expect(res.status).toBe(404);
    expect(query).toHaveBeenCalledTimes(2);
  });

  it('serves a draft season to a maven', async () => {
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(list)
      .mockResolvedValueOnce(detail({ season_number: 3, status: 'draft' })).mockResolvedValueOnce(closedChairs());
    const res = await request(app).get(`${SP}/3`).set('Authorization', 'Bearer maven');
    expect(res.status).toBe(200);
    expect(res.body.data.season.number).toBe(3);
  });

  it('falls back to the default season when the topic is absent from the requested one', async () => {
    openFlow();
    const res = await request(app).get(`${SP}/9`);
    expect(res.status).toBe(200);
    expect(res.body.data.isFallback).toBe(true);
    expect(res.body.data.season.number).toBe(2);
  });

  it('resolves a non-numeric :number to the default season', async () => {
    openFlow();
    const res = await request(app).get(`${SP}/abc`);
    expect(res.status).toBe(200);
    expect(res.body.data.season.number).toBe(2);
    expect(res.body.data.isFallback).toBe(true);
  });

  it('404s when there is no season to fall back to', async () => {
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(rows([]));
    const res = await request(app).get(`${SP}/1`);
    expect(res.status).toBe(404);
  });

  it('does not fall back to a draft for a non-maven', async () => {
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(rows([s(3, 'draft')]));
    expect((await request(app).get(`${SP}/9`)).status).toBe(404);
  });

  it('renders a chair whose description is null as null', async () => {
    openFlow();
    const res = await request(app).get(`${SP}/2`);
    expect(res.body.data.chairs[0].description).toBeNull();
    expect(res.body.data.chairs[1].description).toBe('d');
  });

  it('passes an editorial changeClass and null notes through', async () => {
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(list)
      .mockResolvedValueOnce(detail({ change_class: 'editorial', season_note: null, topic_note: null })).mockResolvedValueOnce(openChairs());
    const res = await request(app).get(`${SP}/2`);
    expect(res.body.data).toMatchObject({ changeClass: 'editorial', seasonNote: null, topicNote: null });
  });

  it('caches guest responses per season and drafts flag', async () => {
    openFlow();
    await request(app).get(`${SP}/2`);
    expect([...store.keys()]).toEqual(['fc:season:t1:2:false']);
    query.mockResolvedValueOnce(community);
    const again = await request(app).get(`${SP}/2`);
    expect(again.body.data.questionText).toBe('Q?');
    expect(query).toHaveBeenCalledTimes(5);
  });

  it('404s an unknown community', async () => {
    query.mockResolvedValueOnce(rows([]));
    expect((await request(app).get(`${SP}/1`)).status).toBe(404);
  });
});
