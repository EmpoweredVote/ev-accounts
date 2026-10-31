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

const claims = await import('./routes/claims.js');
const { claimsRouter, isShareable, cacheNodeIfShareable } = claims;
const app = express();
app.use('/fc/api', claimsRouter);

const rows = (r: unknown[]) => ({ rows: r, rowCount: r.length });
const TS = '2026-04-17T12:00:00.123456+00:00';
const COMMUNITY = 'comm-1';

/** A syntactically valid uuid — parseColumnCursor rejects anything else as a cursor id. */
const uuid = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const cursorFor = (t: string, id: string) =>
  Buffer.from(JSON.stringify({ t, id })).toString('base64url');
const decode = (c: string) => JSON.parse(Buffer.from(c, 'base64url').toString('utf8'));

/** A claims row as the DB hands it back (snake_case, ts() text timestamps). */
const row = (over: Record<string, unknown> = {}) => ({
  id: 'c-root',
  side: null,
  body: 'Root claim',
  author_display_name: null,
  moderation_status: 'visible',
  child_supports_count: 0,
  child_opposes_count: 0,
  merged_into_claim_id: null,
  created_at: TS,
  updated_at: TS,
  path: [],
  community_id: COMMUNITY,
  ...over,
});

const child = (id: string, side: 'supports' | 'opposes', over: Record<string, unknown> = {}) =>
  row({ id, side, body: `${id} body`, author_display_name: 'Demo Finch', parent_claim_id: 'c-root', ...over });

/**
 * Queue one request's worth of queries. Order is fixed by the route: the claim lookup, then the
 * breadcrumb (only when the path is non-empty), then the supports column, then the opposes column.
 */
function mockNode(opts: {
  claim: Record<string, unknown> | null;
  breadcrumb?: Record<string, unknown>[];
  supports?: Record<string, unknown>[];
  opposes?: Record<string, unknown>[];
}) {
  query.mockResolvedValueOnce(rows(opts.claim ? [opts.claim] : []));
  if (!opts.claim) return;
  const path = (opts.claim.path as string[] | null) ?? [];
  if (path.length > 0) query.mockResolvedValueOnce(rows(opts.breadcrumb ?? []));
  query.mockResolvedValueOnce(rows(opts.supports ?? []));
  query.mockResolvedValueOnce(rows(opts.opposes ?? []));
}

const sqlOf = (i: number) => String(query.mock.calls[i][0]);
const allSql = () => query.mock.calls.map((c) => String(c[0]));
/** The call for one column, found by the side it bound. */
const columnCall = (side: 'supports' | 'opposes') =>
  query.mock.calls.filter((c) => Array.isArray(c[1]) && c[1][2] === side).pop()!;

/** A node body shaped like the route's, for testing the cache guard directly. */
const nodeBody = (myRating: number | null, where: 'claim' | 'supports' = 'claim') => {
  const claim = {
    id: 'c-root', side: null, body: 'b', authorPseudonym: null, impact: null, ratingCount: 0,
    childSupports: 0, childOpposes: 0, isHidden: false, mergedInto: null,
    createdAt: TS, updatedAt: TS, myRating: where === 'claim' ? myRating : null,
  };
  const supporter = { ...claim, id: 'c-s1', myRating: where === 'supports' ? myRating : null };
  return {
    data: { claim, breadcrumb: [], supports: [supporter], opposes: [] },
    meta: { supports: { cursor: null, hasMore: false }, opposes: { cursor: null, hasMore: false } },
  };
};

beforeEach(() => {
  query.mockReset();
  store.clear();
});

describe('GET /communities/:id/claims/root', () => {
  it('returns the root with its two columns', async () => {
    mockNode({
      claim: row({ child_supports_count: 2, child_opposes_count: 1 }),
      supports: [child('c-s1', 'supports'), child('c-s2', 'supports')],
      opposes: [child('c-o1', 'opposes')],
    });

    const res = await request(app).get('/fc/api/communities/comm-1/claims/root');

    expect(res.status).toBe(200);
    expect(res.body.data.claim).toEqual({
      id: 'c-root',
      side: null,
      body: 'Root claim',
      authorPseudonym: null,
      impact: null,
      ratingCount: 0,
      childSupports: 2,
      childOpposes: 1,
      isHidden: false,
      mergedInto: null,
      createdAt: TS,
      updatedAt: TS,
      myRating: null,
    });
    expect(res.body.data.breadcrumb).toEqual([]);
    expect(res.body.data.supports.map((c: { id: string }) => c.id)).toEqual(['c-s1', 'c-s2']);
    expect(res.body.data.opposes.map((c: { id: string }) => c.id)).toEqual(['c-o1']);
    expect(res.body.meta).toEqual({
      supports: { cursor: null, hasMore: false },
      opposes: { cursor: null, hasMore: false },
    });

    // The root is found by the one-root-per-community index, not by guessing an id.
    expect(sqlOf(0)).toContain('c.parent_claim_id IS NULL');
    expect(query.mock.calls[0][1]).toEqual(['comm-1']);
  });

  it('404s a community with no root claim', async () => {
    mockNode({ claim: null });
    const res = await request(app).get('/fc/api/communities/comm-nope/claims/root');
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('CLAIM_NOT_FOUND');
  });
});

describe('GET /claims/:claimId', () => {
  it('builds the breadcrumb from path in a single query', async () => {
    // A 40-deep claim. Ancestry must cost one query, not forty.
    const path = Array.from({ length: 40 }, (_, i) => `anc-${i}`);
    mockNode({
      claim: row({ id: 'c-deep', side: 'supports', body: 'Deep claim', path }),
      breadcrumb: path.map((id, i) => ({
        id, body: `${id} body`, side: i === 0 ? null : 'supports', moderation_status: 'visible',
      })),
    });

    const res = await request(app).get('/fc/api/claims/c-deep');

    expect(res.status).toBe(200);
    expect(res.body.data.breadcrumb).toHaveLength(40);
    expect(res.body.data.breadcrumb[0]).toEqual({ id: 'anc-0', body: 'anc-0 body', side: null });
    expect(res.body.data.breadcrumb[39].id).toBe('anc-39');

    const ancestry = allSql().filter((s) => s.includes('array_position'));
    expect(ancestry).toHaveLength(1);
    expect(ancestry[0]).toContain('c.id = ANY($1::uuid[])');
    // Four queries in total at any depth: the claim, the ancestry, and one per column.
    expect(query.mock.calls).toHaveLength(4);
  });

  it('skips the ancestry query entirely for a root', async () => {
    mockNode({ claim: row({ path: [] }) });
    await request(app).get('/fc/api/claims/c-root');
    expect(allSql().filter((s) => s.includes('array_position'))).toHaveLength(0);
    expect(query.mock.calls).toHaveLength(3);
  });

  it('orders each column by impact descending', async () => {
    // Impact is the Task 5 rating aggregate and does not exist yet, so the column order currently
    // resolves to its documented fallback: recency, then id. Task 5 changes the ORDER BY, the
    // keyset predicate and the cursor payload together — see the note in claims.ts.
    mockNode({
      claim: row(),
      supports: [child('c-s1', 'supports'), child('c-s2', 'supports')],
      opposes: [child('c-o1', 'opposes'), child('c-o2', 'opposes')],
    });

    const res = await request(app).get('/fc/api/claims/c-root');

    const columns = allSql().filter((s) => s.includes('c.parent_claim_id = $2'));
    expect(columns).toHaveLength(2);
    for (const sql of columns) expect(sql).toContain('ORDER BY c.created_at DESC, c.id DESC');
    // Row order out of the database is the order the reader sees — no re-sorting in JS.
    expect(res.body.data.supports.map((c: { id: string }) => c.id)).toEqual(['c-s1', 'c-s2']);
    expect(res.body.data.opposes.map((c: { id: string }) => c.id)).toEqual(['c-o1', 'c-o2']);
    // Every column query is bounded.
    for (const sql of columns) expect(sql).toContain('LIMIT $');
  });

  it('leads the column query with community_id so the index applies', async () => {
    // claims_community_parent_idx is on (community_id, parent_claim_id). Without community_id in
    // the WHERE, Postgres cannot use it and sequentially scans every community's claims — twice
    // per request, on the hottest read in the feature.
    mockNode({ claim: row(), supports: [child('c-s1', 'supports')] });
    await request(app).get('/fc/api/claims/c-root');

    for (const side of ['supports', 'opposes'] as const) {
      const call = columnCall(side);
      expect(String(call[0])).toContain('c.community_id = $1');
      expect(call[1]).toEqual([COMMUNITY, 'c-root', side, 21]);
    }
    // The community id is used, never served.
    expect(JSON.stringify((await request(app).get('/fc/api/claims/c-root')).body))
      .not.toContain(COMMUNITY);
  });

  it('renders a hidden claim as a tombstone with its children intact', async () => {
    mockNode({
      claim: row({
        id: 'c-hidden',
        side: 'opposes',
        body: 'something a moderator hid',
        author_display_name: 'Demo Finch',
        moderation_status: 'hidden',
        child_supports_count: 1,
        child_opposes_count: 1,
        path: ['c-root'],
      }),
      breadcrumb: [{ id: 'c-root', body: 'Root claim', side: null, moderation_status: 'visible' }],
      supports: [child('c-s1', 'supports')],
      opposes: [child('c-o1', 'opposes')],
    });

    const res = await request(app).get('/fc/api/claims/c-hidden');

    expect(res.status).toBe(200);
    expect(res.body.data.claim.isHidden).toBe(true);
    expect(res.body.data.claim.body).toBeFalsy();
    expect(JSON.stringify(res.body)).not.toContain('something a moderator hid');
    expect(res.body.data.claim.authorPseudonym).toBeNull();
    // The subtree is still reachable: counts, side, timestamps and both columns survive.
    expect(res.body.data.claim.side).toBe('opposes');
    expect(res.body.data.claim.childSupports).toBe(1);
    expect(res.body.data.claim.childOpposes).toBe(1);
    expect(res.body.data.supports.map((c: { id: string }) => c.id)).toEqual(['c-s1']);
    expect(res.body.data.opposes.map((c: { id: string }) => c.id)).toEqual(['c-o1']);
  });

  it('tombstones a hidden child inside a column rather than dropping it', async () => {
    mockNode({
      claim: row({ child_supports_count: 2 }),
      supports: [
        child('c-s1', 'supports'),
        child('c-s2', 'supports', { moderation_status: 'hidden', body: 'hidden child body' }),
      ],
    });

    const res = await request(app).get('/fc/api/claims/c-root');

    expect(res.body.data.supports.map((c: { id: string }) => c.id)).toEqual(['c-s1', 'c-s2']);
    expect(res.body.data.supports[1].isHidden).toBe(true);
    expect(res.body.data.supports[1].body).toBeFalsy();
    expect(res.body.data.supports[1].authorPseudonym).toBeNull();
    expect(JSON.stringify(res.body)).not.toContain('hidden child body');
    // No moderation filter on a column: dropping hidden rows would contradict the parent's counts.
    expect(String(columnCall('supports')[0])).not.toContain('moderation_status =');
  });

  it('withholds a hidden ancestor body from the breadcrumb', async () => {
    mockNode({
      claim: row({ id: 'c-kid', side: 'supports', path: ['c-root', 'c-mid'] }),
      breadcrumb: [
        { id: 'c-root', body: 'Root claim', side: null, moderation_status: 'visible' },
        { id: 'c-mid', body: 'hidden ancestor body', side: 'opposes', moderation_status: 'hidden' },
      ],
    });

    const res = await request(app).get('/fc/api/claims/c-kid');

    expect(res.body.data.breadcrumb).toEqual([
      { id: 'c-root', body: 'Root claim', side: null },
      { id: 'c-mid', body: '', side: 'opposes' },
    ]);
    expect(JSON.stringify(res.body)).not.toContain('hidden ancestor body');
  });

  it('404s an unknown claim id', async () => {
    mockNode({ claim: null });
    const unknown = await request(app).get('/fc/api/claims/c-missing');
    expect(unknown.status).toBe(404);
    expect(unknown.body).toEqual({
      error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' },
    });

    // A malformed uuid throws 22P02 in the lookup; it is not found either, and never a 403.
    query.mockRejectedValueOnce(Object.assign(new Error('invalid input syntax'), { code: '22P02' }));
    const malformed = await request(app).get('/fc/api/claims/not-a-uuid');
    expect(malformed.status).toBe(404);
    expect(malformed.body.error.code).toBe('CLAIM_NOT_FOUND');
  });

  it('500s when a column query fails, without inventing an empty column', async () => {
    query.mockResolvedValueOnce(rows([row()]));
    query.mockRejectedValueOnce(new Error('connection terminated'));
    query.mockResolvedValueOnce(rows([]));

    const res = await request(app).get('/fc/api/claims/c-root');

    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe('CLAIM_FETCH_FAILED');
  });

  it('never serializes internal columns under any name', async () => {
    mockNode({
      claim: row({
        author_id: 'user-9',
        depth: 2,
        path: ['c-root', 'c-mid'],
        merged_into_claim_id: 'c-other',
      }),
      breadcrumb: [
        { id: 'c-root', body: 'Root claim', side: null, moderation_status: 'visible' },
        { id: 'c-mid', body: 'Mid claim', side: 'supports', moderation_status: 'visible' },
      ],
      supports: [child('c-s1', 'supports', { author_id: 'user-9' })],
    });

    const res = await request(app).get('/fc/api/claims/c-root');
    const text = JSON.stringify(res.body);

    for (const forbidden of ['author_id', 'community_id', 'moderation_status', 'depth', 'path',
      'child_supports_count', 'child_opposes_count', 'user-9', COMMUNITY]) {
      expect(text).not.toContain(forbidden);
    }
    // The one merge field the Claim type does carry, under its own name.
    expect(res.body.data.claim.mergedInto).toBe('c-other');
  });
});

describe('column pagination', () => {
  it('paginates a column past the page size', async () => {
    // 500 children exist; the route asks for one more than a page and serves a page.
    const many = Array.from({ length: 21 }, (_, i) =>
      child(uuid(i), 'supports', { created_at: `2026-04-17T12:00:0${i % 10}.000000+00:00` })
    );
    mockNode({ claim: row({ child_supports_count: 500 }), supports: many });

    const res = await request(app).get('/fc/api/claims/c-root');

    expect(res.body.data.supports).toHaveLength(20);
    expect(res.body.meta.supports.hasMore).toBe(true);
    expect(res.body.meta.supports.cursor).toBeTruthy();
    expect(res.body.meta.opposes).toEqual({ cursor: null, hasMore: false });

    // LIMIT is page size + 1, never the full 500.
    expect(columnCall('supports')[1].at(-1)).toBe(21);
  });

  it('feeds the cursor it issued straight back into the keyset predicate', async () => {
    // The guard against the ORDER BY, the predicate and the cursor payload drifting apart: the
    // values the route WRITES into a cursor are the values it later READS out and compares. A
    // cursor built from any other column, or a predicate comparing any other column, fails here.
    const many = Array.from({ length: 21 }, (_, i) =>
      child(uuid(i), 'supports', {
        created_at: `2026-04-17T12:00:${String(i).padStart(2, '0')}.000000+00:00`,
        updated_at: `2026-05-01T09:00:${String(i).padStart(2, '0')}.000000+00:00`,
      })
    );
    mockNode({ claim: row(), supports: many });
    const first = await request(app).get('/fc/api/claims/c-root');
    const last = first.body.data.supports[19];
    const cursor = first.body.meta.supports.cursor as string;
    expect(decode(cursor)).toEqual({ t: last.createdAt, id: last.id });

    mockNode({ claim: row(), supports: [child(uuid(20), 'supports')] });
    const second = await request(app).get(`/fc/api/claims/c-root?supportsCursor=${cursor}`);

    expect(second.status).toBe(200);
    const call = columnCall('supports');
    expect(String(call[0])).toContain('c.created_at < $4::timestamptz');
    expect(String(call[0])).toContain('c.id < $5::uuid');
    expect(call[1]).toEqual([COMMUNITY, 'c-root', 'supports', last.createdAt, last.id, 21]);
  });

  it('numbers the keyset placeholders after the filter parameters', async () => {
    const cursor = cursorFor(TS, uuid(19));
    mockNode({ claim: row(), supports: [child(uuid(20), 'supports')] });

    const res = await request(app).get(`/fc/api/claims/c-root?supportsCursor=${cursor}&limit=5`);

    expect(res.status).toBe(200);
    expect(columnCall('supports')[1]).toEqual([COMMUNITY, 'c-root', 'supports', TS, uuid(19), 6]);
    // The opposes column is untouched by the supports cursor.
    expect(columnCall('opposes')[1]).toEqual([COMMUNITY, 'c-root', 'opposes', 6]);
  });

  it('treats a well-formed cursor with unusable contents as absent, not as a 500', async () => {
    // decodeCursor only checks that t and id are strings. A string is not a timestamptz and not a
    // uuid: handing one to Postgres turns a crafted query string into an anonymous 500 with a raw
    // database message in the body.
    for (const bad of [cursorFor('nope', 'nope'), cursorFor(TS, 'not-a-uuid'), cursorFor('nope', uuid(1))]) {
      query.mockReset();
      store.clear(); // each unusable cursor collapses onto the same page-one key
      mockNode({ claim: row(), supports: [child(uuid(1), 'supports')] });
      const res = await request(app).get(`/fc/api/claims/c-root?supportsCursor=${bad}`);
      expect(res.status).toBe(200);
      const call = columnCall('supports');
      expect(String(call[0])).not.toContain('::timestamptz');
      expect(call[1]).toEqual([COMMUNITY, 'c-root', 'supports', 21]);
    }
  });
});

describe('caching', () => {
  const keyFor = (id: string, limit = 20, supports: unknown = null, opposes: unknown = null) =>
    `fc:claim:${id}:${JSON.stringify({ limit, supports, opposes })}`;

  it('serves a second anonymous reader from the shared cache', async () => {
    mockNode({ claim: row(), supports: [child('c-s1', 'supports')] });
    const first = await request(app).get('/fc/api/claims/c-root');
    expect(first.status).toBe(200);
    expect([...store.keys()]).toEqual([keyFor('c-root')]);

    const callsAfterFirst = query.mock.calls.length;
    const second = await request(app).get('/fc/api/claims/c-root');
    expect(second.body).toEqual(first.body);
    expect(query.mock.calls).toHaveLength(callsAfterFirst);
    expect(second.headers['cache-control']).toBe('public, max-age=0, s-maxage=30');
  });

  it('keys the cache on the decoded cursors, so no two requests can collide on one key', async () => {
    // Raw cursor strings joined with a delimiter let `?supportsCursor=a:b&opposesCursor=X` and
    // `?supportsCursor=a&opposesCursor=b:X` mint the same key for different bodies.
    const a = cursorFor(TS, uuid(1));
    const b = cursorFor(TS, uuid(2));
    mockNode({ claim: row(), supports: [child(uuid(9), 'supports')] });
    await request(app).get(`/fc/api/claims/c-root?supportsCursor=${a}&opposesCursor=${b}`);
    mockNode({ claim: row(), supports: [child(uuid(9), 'supports')] });
    await request(app).get(`/fc/api/claims/c-root?supportsCursor=${b}&opposesCursor=${a}`);

    expect([...store.keys()].sort()).toEqual([
      keyFor('c-root', 20, { t: TS, id: uuid(1) }, { t: TS, id: uuid(2) }),
      keyFor('c-root', 20, { t: TS, id: uuid(2) }, { t: TS, id: uuid(1) }),
    ].sort());
  });

  it('collapses every unusable cursor onto the page-one key', async () => {
    mockNode({ claim: row(), supports: [child(uuid(1), 'supports')] });
    await request(app).get('/fc/api/claims/c-root?supportsCursor=%%%not-base64%%%');
    mockNode({ claim: row(), supports: [child(uuid(1), 'supports')] });
    await request(app).get(`/fc/api/claims/c-root?supportsCursor=${cursorFor('nope', 'nope')}`);
    // Both serve page one, so both belong on page one's key rather than minting garbage entries.
    expect([...store.keys()]).toEqual([keyFor('c-root')]);
  });

  it('keys the cache on the page size the reader asked for', async () => {
    mockNode({ claim: row(), supports: [child('c-s1', 'supports')] });
    await request(app).get('/fc/api/claims/c-root?limit=5');
    mockNode({ claim: row(), supports: [child('c-s1', 'supports')] });
    await request(app).get('/fc/api/claims/c-root');
    expect([...store.keys()].sort()).toEqual([keyFor('c-root', 20), keyFor('c-root', 5)].sort());
  });

  it('never reads or writes the shared cache for a request that carries credentials', async () => {
    mockNode({ claim: row(), supports: [child('c-s1', 'supports')] });
    const res = await request(app).get('/fc/api/claims/c-root').set('Authorization', 'Bearer user');
    expect(res.status).toBe(200);
    expect(res.headers['cache-control']).toBe('private, no-store');
    expect(store.size).toBe(0);
  });

  it('declares that the response varies on Authorization', async () => {
    mockNode({ claim: row() });
    expect((await request(app).get('/fc/api/claims/c-root')).headers.vary).toBe('Authorization');
    mockNode({ claim: row() });
    const auth = await request(app).get('/fc/api/claims/c-root').set('Authorization', 'Bearer user');
    expect(auth.headers.vary).toBe('Authorization');
    // Errors too — they are served from the same branch and must not be filed under one key.
    mockNode({ claim: null });
    expect((await request(app).get('/fc/api/claims/c-missing')).headers.vary).toBe('Authorization');
  });

  it('does not cache an error', async () => {
    mockNode({ claim: null });
    expect((await request(app).get('/fc/api/claims/c-missing')).status).toBe(404);
    expect(store.size).toBe(0);
  });
});

describe('isShareable — the one guard between Task 5 and a leaked rating', () => {
  // myRating is hardcoded null today, so no route response can exercise this guard. It is the
  // entire justification for hand-rolling the cache, so it is tested directly rather than left
  // to be discovered when Task 5 lands.
  it('passes a body in which nothing depends on who asked', () => {
    expect(isShareable(nodeBody(null).data)).toBe(true);
  });

  it('rejects a body carrying a caller-specific rating, wherever it sits', () => {
    expect(isShareable(nodeBody(4).data)).toBe(false);
    expect(isShareable(nodeBody(2, 'supports').data)).toBe(false);
  });

  it('is the only door to the shared cache, and it stays shut for a personalized body', async () => {
    await cacheNodeIfShareable('fc:claim:test:personalized', nodeBody(4));
    expect(store.size).toBe(0);
    await cacheNodeIfShareable('fc:claim:test:anonymous', nodeBody(null));
    expect([...store.keys()]).toEqual(['fc:claim:test:anonymous']);
  });
});
