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
    season_note: 'sn', topic_note: 'tn', rationale: 'why', rung_map: null, ...over,
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

  const IDENT = { 1: 1, 2: 2, 3: 3, 4: 4, 5: 5 };
  const markers = (res: { body: { data: { chairs: { changeSince: unknown }[] } } }) => res.body.data.chairs.map((c) => c.changeSince);
  // Season 2 (open) with the given rung_map; previous season 1 chairs are fed to get_season_chairs.
  const markFlow = (rung_map: unknown, prev: string[] = ['chair 0', 'chair 1', 'chair 2']) => query
    .mockResolvedValueOnce(community).mockResolvedValueOnce(list).mockResolvedValueOnce(detail({ rung_map }))
    .mockResolvedValueOnce(openChairs())
    .mockResolvedValueOnce(rows(prev.map((text, i) => ({ ordinal: i + 1, text }))));

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
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(list).mockResolvedValueOnce(detail({ rung_map: IDENT }))
      .mockResolvedValueOnce(openChairs()).mockResolvedValueOnce(closedChairs());
    const res = await request(app).get(`${SP}/2`).set('Authorization', 'Bearer maven');
    expect(res.status).toBe(200);
    expect(JSON.stringify(res.body)).not.toContain('rung_map');
    expect(JSON.stringify(res.body)).not.toContain('rungMap');
  });

  it('asks the database for chairs in explicit ladder order (SQL)', async () => {
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

  it('treats a draft season requested by a non-maven exactly like an unknown one: 200 fallback to the default', async () => {
    // The database omits drafts for a guest, so the list never contains season 3.
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(rows([s(1, 'closed'), s(2, 'open')]))
      .mockResolvedValueOnce(detail()).mockResolvedValueOnce(openChairs());
    const res = await request(app).get(`${SP}/3`);
    expect(res.status).toBe(200);
    expect(res.body.data.isFallback).toBe(true);
    expect(res.body.data.season.number).toBe(2);
    expect(res.body.data.questionText).toBe('Q?');
    expect(query.mock.calls[1][1]).toEqual(['t1', false]);
  });

  it('falls back to the closed season, not a draft, for a guest on a topic with both', async () => {
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(rows([s(1, 'closed')]))
      .mockResolvedValueOnce(detail({ season_number: 1, season_name: 'S1', status: 'closed' })).mockResolvedValueOnce(closedChairs());
    const res = await request(app).get(`${SP}/9`);
    expect(res.status).toBe(200);
    expect(res.body.data.isFallback).toBe(true);
    expect(res.body.data.season.number).toBe(1);
    expect(query.mock.calls[1][1]).toEqual(['t1', false]);
    expect(query.mock.calls[2][1]).toEqual(['t1', 1, false]);
  });

  it('serves a draft season to a maven with its chairs, passing includeDrafts to both calls', async () => {
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(list)
      .mockResolvedValueOnce(detail({ season_number: 3, status: 'draft' })).mockResolvedValueOnce(closedChairs());
    const res = await request(app).get(`${SP}/3`).set('Authorization', 'Bearer maven');
    expect(res.status).toBe(200);
    expect(res.body.data.season.number).toBe(3);
    expect(res.body.data.chairs.map((c: { text: string }) => c.text)).toEqual(['old 0', 'old 1', 'old 2']);
    expect(query.mock.calls[2][1]).toEqual(['t1', 3, true]);
    expect(query.mock.calls[3][1]).toEqual(['t1', 3, true]);
  });

  it('passes includeDrafts=false to the detail and chairs calls for a guest', async () => {
    closedFlow();
    await request(app).get(`${SP}/1`);
    expect(query.mock.calls[2][1]).toEqual(['t1', 1, false]);
    expect(query.mock.calls[3][1]).toEqual(['t1', 1, false]);
  });

  it('returns open-season chairs in ladder order when the rows arrive shuffled', async () => {
    const shuffled = rows([3, 1, 2].map((p) => ({ position: p, text: `p${p}`, description: null, supporting_points: [], example_perspectives: [] })));
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(list).mockResolvedValueOnce(detail()).mockResolvedValueOnce(shuffled);
    const res = await request(app).get(`${SP}/2`);
    expect(res.body.data.chairs.map((c: { text: string }) => c.text)).toEqual(['p1', 'p2', 'p3']);
  });

  it('returns closed-season chairs in ladder order when the rows arrive shuffled', async () => {
    const shuffled = rows([2, 3, 1].map((o) => ({ ordinal: o, text: `o${o}`, description: null, supporting_points: [], example_perspectives: [] })));
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(list)
      .mockResolvedValueOnce(detail({ season_number: 1, status: 'closed' })).mockResolvedValueOnce(shuffled);
    const res = await request(app).get(`${SP}/1`);
    expect(res.body.data.chairs.map((c: { text: string }) => c.text)).toEqual(['o1', 'o2', 'o3']);
  });

  it('passes a null description through as null on the closed path', async () => {
    closedFlow();
    const res = await request(app).get(`${SP}/1`);
    expect(res.body.data.chairs[0].description).toBeNull();
  });

  it('bounds the cache keyspace by the resolved season, not the requested number', async () => {
    openFlow();
    await request(app).get(`${SP}/9`);
    for (const n of ['99', '999', 'abc']) {
      query.mockResolvedValueOnce(community).mockResolvedValueOnce(rows([s(1, 'closed'), s(2, 'open')]));
      await request(app).get(`${SP}/${n}`);
    }
    expect([...store.keys()]).toEqual(['fc:season:c1:2:true:false']);
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

  it('404s when the only season is a draft and the caller is a guest', async () => {
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(rows([]));
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
    expect([...store.keys()]).toEqual(['fc:season:c1:2:false:false']);
    query.mockResolvedValueOnce(community).mockResolvedValueOnce(rows([s(1, 'closed'), s(2, 'open')]));
    const again = await request(app).get(`${SP}/2`);
    expect(again.body.data.questionText).toBe('Q?');
    expect(query).toHaveBeenCalledTimes(6);
  });

  describe('changeSince', () => {
    it('marks a chair carried when rung_map is identity and the text is unchanged', async () => {
      markFlow(IDENT);
      const res = await request(app).get(`${SP}/2`);
      expect(markers(res)).toEqual(['carried', 'carried', 'carried']);
    });

    it('marks a chair reworded when rung_map is identity and the text differs', async () => {
      markFlow(IDENT, ['chair 0', 'other', 'chair 2']);
      const res = await request(app).get(`${SP}/2`);
      expect(markers(res)).toEqual(['carried', 'reworded', 'carried']);
      expect(query.mock.calls[4][1]).toEqual(['t1', 1, false]);
      expect(sql(4)).toContain('connect.get_season_chairs($1, $2, $3)');
    });

    it('derives the previous season from the list, not n - 1', async () => {
      const gap = rows([s(1, 'closed'), s(4, 'closed'), s(7, 'open')]);
      query.mockResolvedValueOnce(community).mockResolvedValueOnce(gap)
        .mockResolvedValueOnce(detail({ season_number: 7, rung_map: IDENT })).mockResolvedValueOnce(openChairs())
        .mockResolvedValueOnce(rows([{ ordinal: 1, text: 'chair 0' }]));
      const res = await request(app).get(`${SP}/7`);
      expect(query.mock.calls[4][1]).toEqual(['t1', 4, false]);
      expect(markers(res)).toEqual(['carried', null, null]);
    });

    it('suppresses the marker when rung_map is null', async () => {
      markFlow(null);
      const res = await request(app).get(`${SP}/2`);
      expect(markers(res)).toEqual([null, null, null]);
      expect(query).toHaveBeenCalledTimes(4);
    });

    it('suppresses the marker when rung_map collapses two chairs into one', async () => {
      markFlow({ 1: 1, 2: 1, 3: 3, 4: 4, 5: 5 });
      expect(markers(await request(app).get(`${SP}/2`))).toEqual([null, null, null]);
    });

    it('suppresses the marker when rung_map contains the "invalidated" sentinel', async () => {
      markFlow({ 1: 1, 2: 'invalidated', 3: 3, 4: 4, 5: 5 });
      const res = await request(app).get(`${SP}/2`);
      expect(res.status).toBe(200);
      expect(markers(res)).toEqual([null, null, null]);
    });

    it('suppresses the marker when rung_map is a non-identity permutation', async () => {
      markFlow({ 1: 2, 2: 1, 3: 3, 4: 4, 5: 5 });
      expect(markers(await request(app).get(`${SP}/2`))).toEqual([null, null, null]);
    });

    it('suppresses the marker for the earliest season of a topic', async () => {
      query.mockResolvedValueOnce(community).mockResolvedValueOnce(list)
        .mockResolvedValueOnce(detail({ season_number: 1, status: 'closed', rung_map: IDENT })).mockResolvedValueOnce(closedChairs());
      const res = await request(app).get(`${SP}/1`);
      expect(markers(res)).toEqual([null, null, null]);
      expect(query).toHaveBeenCalledTimes(4);
    });

    it('does not serialize rung_map or its values with markers on', async () => {
      const distinct = { 1: 1, 2: 2, 3: 3, 4: 4, 5: 5 };
      markFlow(distinct);
      const res = await request(app).get(`${SP}/2`);
      const body = JSON.stringify(res.body);
      expect(body).not.toMatch(/rung|"ordinal"|"position"/);
      // Nothing but the chair fields: no stray key could be carrying the map's values.
      expect(Object.keys(res.body.data).sort()).toEqual(
        ['chairs', 'changeClass', 'isFallback', 'questionText', 'rationale', 'season', 'seasonNote', 'topicNote'].sort());
      expect(Object.keys(res.body.data.chairs[0]).sort()).toEqual(
        ['changeSince', 'description', 'examplePerspectives', 'supportingPoints', 'text']);
      expect(body).not.toMatch(/{"1":1|"1":1,"2":2/);
    });

    it.each([
      ['an extra sixth key', { 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6 }],
      ['numeric strings instead of numbers', { 1: '1', 2: '2', 3: '3', 4: '4', 5: '5' }],
      ['a missing key', { 1: 1, 2: 2, 3: 3, 4: 4 }],
      ['an array', [1, 2, 3, 4, 5]],
    ])('suppresses the marker for %s', async (_n, map) => {
      markFlow(map);
      const res = await request(app).get(`${SP}/2`);
      expect(res.status).toBe(200);
      expect(markers(res)).toEqual([null, null, null]);
    });

    it('passes includeDrafts=true to the previous-season fetch for a maven', async () => {
      const l = rows([s(1, 'closed'), s(2, 'closed'), s(3, 'draft')]);
      query.mockResolvedValueOnce(community).mockResolvedValueOnce(l)
        .mockResolvedValueOnce(detail({ season_number: 3, status: 'draft', rung_map: IDENT })).mockResolvedValueOnce(closedChairs())
        .mockResolvedValueOnce(rows(['old 0', 'x', 'old 2'].map((text, i) => ({ ordinal: i + 1, text }))));
      const res = await request(app).get(`${SP}/3`).set('Authorization', 'Bearer maven');
      expect(sql(4)).toContain('get_season_chairs');
      expect(query.mock.calls[4][1]).toEqual(['t1', 2, true]);
      expect(markers(res)).toEqual(['carried', 'reworded', 'carried']);
    });

    it('reads the predecessor from the live stances when the previous season is the open one', async () => {
      // A draft follows the open season; its predecessor is open, whose chairs live in compass_stances.
      query.mockResolvedValueOnce(community).mockResolvedValueOnce(list)
        .mockResolvedValueOnce(detail({ season_number: 3, status: 'draft', rung_map: IDENT })).mockResolvedValueOnce(closedChairs())
        .mockResolvedValueOnce(rows(['old 0', 'changed', 'old 2'].map((text, i) => ({ position: i + 1, text }))));
      const res = await request(app).get(`${SP}/3`).set('Authorization', 'Bearer maven');
      expect(sql(4)).toContain('connect.get_stances_for_community($1)');
      expect(sql(4)).not.toContain('get_season_chairs');
      expect(query.mock.calls[4][1]).toEqual(['c1']);
      expect(markers(res)).toEqual(['carried', 'reworded', 'carried']);
    });

    it('returns null markers, not a 500, when the previous-season lookup fails', async () => {
      query.mockResolvedValueOnce(community).mockResolvedValueOnce(list).mockResolvedValueOnce(detail({ rung_map: IDENT }))
        .mockResolvedValueOnce(openChairs()).mockRejectedValueOnce(new Error('boom'));
      const res = await request(app).get(`${SP}/2`);
      expect(res.status).toBe(200);
      expect(markers(res)).toEqual([null, null, null]);
    });
  });

  it('404s an unknown community', async () => {
    query.mockResolvedValueOnce(rows([]));
    expect((await request(app).get(`${SP}/1`)).status).toBe(404);
  });
});
