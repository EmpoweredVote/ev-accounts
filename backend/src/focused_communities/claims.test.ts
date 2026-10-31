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
const { claimsRouter, isShareable, cacheNodeIfShareable, SHAPE_NODE_LIMIT } = claims;
const app = express();
app.use('/fc/api', claimsRouter);

const rows = (r: unknown[]) => ({ rows: r, rowCount: r.length });
const TS = '2026-04-17T12:00:00.123456+00:00';

/** A canonical uuid. Both routes refuse anything else before it reaches a key or the database. */
const uuid = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const COMMUNITY = uuid(900);
const ROOT = uuid(100);
const MISSING = uuid(999);

const cursorFor = (t: string, id: string) =>
  Buffer.from(JSON.stringify({ t, id })).toString('base64url');
const decode = (c: string) => JSON.parse(Buffer.from(c, 'base64url').toString('utf8'));

/** A claims row as the DB hands it back (snake_case, ts() text timestamps). */
const row = (over: Record<string, unknown> = {}) => ({
  id: ROOT,
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
  row({ id, side, body: `${id} body`, author_display_name: 'Demo Finch', parent_claim_id: ROOT, ...over });

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
    id: ROOT, side: null, body: 'b', authorPseudonym: null, impact: null, ratingCount: 0,
    childSupports: 0, childOpposes: 0, isHidden: false, mergedInto: null,
    createdAt: TS, updatedAt: TS, myRating: where === 'claim' ? myRating : null,
  };
  const supporter = { ...claim, id: uuid(1), myRating: where === 'supports' ? myRating : null };
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
      supports: [child(uuid(1), 'supports'), child(uuid(2), 'supports')],
      opposes: [child(uuid(3), 'opposes')],
    });

    const res = await request(app).get(`/fc/api/communities/${COMMUNITY}/claims/root`);

    expect(res.status).toBe(200);
    expect(res.body.data.claim).toEqual({
      id: ROOT,
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
    expect(res.body.data.supports.map((c: { id: string }) => c.id)).toEqual([uuid(1), uuid(2)]);
    expect(res.body.data.opposes.map((c: { id: string }) => c.id)).toEqual([uuid(3)]);
    expect(res.body.meta).toEqual({
      supports: { cursor: null, hasMore: false },
      opposes: { cursor: null, hasMore: false },
    });

    // The root is found by the one-root-per-community index, not by guessing an id.
    expect(sqlOf(0)).toContain('c.parent_claim_id IS NULL');
    expect(query.mock.calls[0][1]).toEqual([COMMUNITY]);
  });

  it('404s a community with no root claim', async () => {
    mockNode({ claim: null });
    const res = await request(app).get(`/fc/api/communities/${uuid(777)}/claims/root`);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('CLAIM_NOT_FOUND');
  });
});

describe('GET /claims/:claimId', () => {
  it('builds the breadcrumb from path in a single query', async () => {
    // A 40-deep claim. Ancestry must cost one query, not forty.
    const path = Array.from({ length: 40 }, (_, i) => `anc-${i}`);
    mockNode({
      claim: row({ id: uuid(40), side: 'supports', body: 'Deep claim', path }),
      breadcrumb: path.map((id, i) => ({
        id, body: `${id} body`, side: i === 0 ? null : 'supports', moderation_status: 'visible',
      })),
    });

    const res = await request(app).get(`/fc/api/claims/${uuid(40)}`);

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
    await request(app).get(`/fc/api/claims/${ROOT}`);
    expect(allSql().filter((s) => s.includes('array_position'))).toHaveLength(0);
    expect(query.mock.calls).toHaveLength(3);
  });

  it('orders each column by impact descending', async () => {
    // Impact is the Task 5 rating aggregate and does not exist yet, so the column order currently
    // resolves to its documented fallback: recency, then id. Task 5 changes the ORDER BY, the
    // keyset predicate and the cursor payload together — see the note in claims.ts.
    mockNode({
      claim: row(),
      supports: [child(uuid(1), 'supports'), child(uuid(2), 'supports')],
      opposes: [child(uuid(3), 'opposes'), child(uuid(4), 'opposes')],
    });

    const res = await request(app).get(`/fc/api/claims/${ROOT}`);

    const columns = allSql().filter((s) => s.includes('c.parent_claim_id = $2'));
    expect(columns).toHaveLength(2);
    for (const sql of columns) expect(sql).toContain('ORDER BY c.created_at DESC, c.id DESC');
    // Row order out of the database is the order the reader sees — no re-sorting in JS.
    expect(res.body.data.supports.map((c: { id: string }) => c.id)).toEqual([uuid(1), uuid(2)]);
    expect(res.body.data.opposes.map((c: { id: string }) => c.id)).toEqual([uuid(3), uuid(4)]);
    // Every column query is bounded.
    for (const sql of columns) expect(sql).toContain('LIMIT $');
  });

  it('leads the column query with community_id so the index applies', async () => {
    // claims_community_parent_idx is on (community_id, parent_claim_id). Without community_id in
    // the WHERE, Postgres cannot use it and sequentially scans every community's claims — twice
    // per request, on the hottest read in the feature.
    mockNode({ claim: row(), supports: [child(uuid(1), 'supports')] });
    await request(app).get(`/fc/api/claims/${ROOT}`);

    for (const side of ['supports', 'opposes'] as const) {
      const call = columnCall(side);
      expect(String(call[0])).toContain('c.community_id = $1');
      expect(call[1]).toEqual([COMMUNITY, ROOT, side, 21]);
    }
    // The community id is used, never served.
    expect(JSON.stringify((await request(app).get(`/fc/api/claims/${ROOT}`)).body))
      .not.toContain(COMMUNITY);
  });

  it('renders a hidden claim as a tombstone with its children intact', async () => {
    mockNode({
      claim: row({
        id: uuid(50),
        side: 'opposes',
        body: 'something a moderator hid',
        author_display_name: 'Demo Finch',
        moderation_status: 'hidden',
        child_supports_count: 1,
        child_opposes_count: 1,
        path: [ROOT],
      }),
      breadcrumb: [{ id: ROOT, body: 'Root claim', side: null, moderation_status: 'visible' }],
      supports: [child(uuid(1), 'supports')],
      opposes: [child(uuid(3), 'opposes')],
    });

    const res = await request(app).get(`/fc/api/claims/${uuid(50)}`);

    expect(res.status).toBe(200);
    expect(res.body.data.claim.isHidden).toBe(true);
    expect(res.body.data.claim.body).toBeFalsy();
    expect(JSON.stringify(res.body)).not.toContain('something a moderator hid');
    expect(res.body.data.claim.authorPseudonym).toBeNull();
    // The subtree is still reachable: counts, side, timestamps and both columns survive.
    expect(res.body.data.claim.side).toBe('opposes');
    expect(res.body.data.claim.childSupports).toBe(1);
    expect(res.body.data.claim.childOpposes).toBe(1);
    expect(res.body.data.supports.map((c: { id: string }) => c.id)).toEqual([uuid(1)]);
    expect(res.body.data.opposes.map((c: { id: string }) => c.id)).toEqual([uuid(3)]);
  });

  it('tombstones a hidden child inside a column rather than dropping it', async () => {
    mockNode({
      claim: row({ child_supports_count: 2 }),
      supports: [
        child(uuid(1), 'supports'),
        child(uuid(2), 'supports', { moderation_status: 'hidden', body: 'hidden child body' }),
      ],
    });

    const res = await request(app).get(`/fc/api/claims/${ROOT}`);

    expect(res.body.data.supports.map((c: { id: string }) => c.id)).toEqual([uuid(1), uuid(2)]);
    expect(res.body.data.supports[1].isHidden).toBe(true);
    expect(res.body.data.supports[1].body).toBeFalsy();
    expect(res.body.data.supports[1].authorPseudonym).toBeNull();
    expect(JSON.stringify(res.body)).not.toContain('hidden child body');
    // No moderation filter on a column: dropping hidden rows would contradict the parent's counts.
    expect(String(columnCall('supports')[0])).not.toContain('moderation_status =');
  });

  it('withholds a hidden ancestor body from the breadcrumb', async () => {
    mockNode({
      claim: row({ id: uuid(60), side: 'supports', path: [ROOT, uuid(61)] }),
      breadcrumb: [
        { id: ROOT, body: 'Root claim', side: null, moderation_status: 'visible' },
        { id: uuid(61), body: 'hidden ancestor body', side: 'opposes', moderation_status: 'hidden' },
      ],
    });

    const res = await request(app).get(`/fc/api/claims/${uuid(60)}`);

    expect(res.body.data.breadcrumb).toEqual([
      { id: ROOT, body: 'Root claim', side: null },
      { id: uuid(61), body: '', side: 'opposes' },
    ]);
    expect(JSON.stringify(res.body)).not.toContain('hidden ancestor body');
  });

  it('404s an unknown claim id', async () => {
    mockNode({ claim: null });
    const unknown = await request(app).get(`/fc/api/claims/${MISSING}`);
    expect(unknown.status).toBe(404);
    expect(unknown.body).toEqual({
      error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' },
    });
  });

  it('refuses an id that is not a canonical uuid before touching the key or the database', async () => {
    // Not merely "a non-uuid 404s": it must 404 WITHOUT minting a cache key, because an
    // unconstrained id in a key is a way to reach another route's entries — and without a query,
    // because the uuid is the only thing standing between a path segment and ::uuid.
    for (const bad of [
      'not-a-uuid',
      `root:${COMMUNITY}`,                      // the shape of the old root cache id
      `{${ROOT}}`,                              // brace-wrapped, which ::uuid would have accepted
      ROOT.replace(/-/g, ''),                   // hyphen-less, likewise
    ]) {
      query.mockReset();
      store.clear();
      const res = await request(app).get(`/fc/api/claims/${encodeURIComponent(bad)}`);
      expect(res.status).toBe(404);
      expect(res.body.error.code).toBe('CLAIM_NOT_FOUND');
      expect(query.mock.calls).toHaveLength(0);
      expect(store.size).toBe(0);
    }
  });

  it('never serves a root body to /claims/root:<community id>', async () => {
    // The two routes used to share one key namespace, so once a community's root was cached,
    // GET /claims/root:<community-uuid> built the identical key and answered 200 with the root's
    // body — for an id that is not a claim id and owes a 404, before any lookup ran.
    mockNode({ claim: row() });
    const root = await request(app).get(`/fc/api/communities/${COMMUNITY}/claims/root`);
    expect(root.status).toBe(200);
    expect(store.size).toBe(1);

    const impostor = await request(app).get(`/fc/api/claims/${encodeURIComponent(`root:${COMMUNITY}`)}`);
    expect(impostor.status).toBe(404);
    expect(impostor.body).not.toHaveProperty('data');
  });

  it('404s a malformed id that still reaches the database', async () => {
    // A uuid-shaped id can still be rejected by Postgres in some other query; 22P02 anywhere in
    // the lookup is not-found, never a 403 and never a 500.
    query.mockRejectedValueOnce(Object.assign(new Error('invalid input syntax'), { code: '22P02' }));
    const res = await request(app).get(`/fc/api/claims/${MISSING}`);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('CLAIM_NOT_FOUND');
  });

  it('500s when a column query fails, without inventing an empty column', async () => {
    query.mockResolvedValueOnce(rows([row()]));
    query.mockRejectedValueOnce(new Error('connection terminated'));
    query.mockResolvedValueOnce(rows([]));

    const res = await request(app).get(`/fc/api/claims/${ROOT}`);

    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe('CLAIM_FETCH_FAILED');
  });

  it('never echoes the database message to the caller', async () => {
    // A raw Postgres message names columns, types and sometimes values. It is the difference
    // between a bad request costing an attacker a dull 500 and handing them a schema probe.
    const secret = 'invalid input syntax for type timestamp with time zone: "connect.claims.foo"';
    query.mockResolvedValueOnce(rows([row()]));
    query.mockRejectedValueOnce(new Error(secret));
    query.mockResolvedValueOnce(rows([]));

    const res = await request(app).get(`/fc/api/claims/${ROOT}`);

    expect(res.status).toBe(500);
    expect(JSON.stringify(res.body)).not.toContain(secret);
    expect(JSON.stringify(res.body)).not.toContain('timestamp with time zone');
    expect(res.body.error).toEqual({
      code: 'CLAIM_FETCH_FAILED',
      message: 'Could not read the claim',
    });
    expect(res.headers['cache-control']).toBe('no-store');
  });

  it('never serializes internal columns under any name', async () => {
    mockNode({
      claim: row({
        author_id: 'user-9',
        depth: 2,
        path: [ROOT, uuid(61)],
        merged_into_claim_id: uuid(70),
      }),
      breadcrumb: [
        { id: ROOT, body: 'Root claim', side: null, moderation_status: 'visible' },
        { id: uuid(61), body: 'Mid claim', side: 'supports', moderation_status: 'visible' },
      ],
      supports: [child(uuid(1), 'supports', { author_id: 'user-9' })],
    });

    const res = await request(app).get(`/fc/api/claims/${ROOT}`);
    const text = JSON.stringify(res.body);

    for (const forbidden of ['author_id', 'community_id', 'moderation_status', 'depth', 'path',
      'child_supports_count', 'child_opposes_count', 'user-9', COMMUNITY]) {
      expect(text).not.toContain(forbidden);
    }
    // The one merge field the Claim type does carry, under its own name.
    expect(res.body.data.claim.mergedInto).toBe(uuid(70));
  });
});

describe('column pagination', () => {
  it('paginates a column past the page size', async () => {
    // 500 children exist; the route asks for one more than a page and serves a page.
    const many = Array.from({ length: 21 }, (_, i) =>
      child(uuid(i), 'supports', { created_at: `2026-04-17T12:00:0${i % 10}.000000+00:00` })
    );
    mockNode({ claim: row({ child_supports_count: 500 }), supports: many });

    const res = await request(app).get(`/fc/api/claims/${ROOT}`);

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
    const first = await request(app).get(`/fc/api/claims/${ROOT}`);
    const last = first.body.data.supports[19];
    const cursor = first.body.meta.supports.cursor as string;
    expect(decode(cursor)).toEqual({ t: last.createdAt, id: last.id });

    mockNode({ claim: row(), supports: [child(uuid(20), 'supports')] });
    const second = await request(app).get(`/fc/api/claims/${ROOT}?supportsCursor=${cursor}`);

    expect(second.status).toBe(200);
    const call = columnCall('supports');
    expect(String(call[0])).toContain('c.created_at < $4::timestamptz');
    expect(String(call[0])).toContain('c.id < $5::uuid');
    expect(call[1]).toEqual([COMMUNITY, ROOT, 'supports', last.createdAt, last.id, 21]);
  });

  it('numbers the keyset placeholders after the filter parameters', async () => {
    const cursor = cursorFor(TS, uuid(19));
    mockNode({ claim: row(), supports: [child(uuid(20), 'supports')] });

    const res = await request(app).get(`/fc/api/claims/${ROOT}?supportsCursor=${cursor}&limit=5`);

    expect(res.status).toBe(200);
    expect(columnCall('supports')[1]).toEqual([COMMUNITY, ROOT, 'supports', TS, uuid(19), 6]);
    // The opposes column is untouched by the supports cursor.
    expect(columnCall('opposes')[1]).toEqual([COMMUNITY, ROOT, 'opposes', 6]);
  });

  it('accepts every timestamp ts() can emit', async () => {
    // The validator must not be stricter than the route's own output either: whole seconds and
    // one-to-six fractional digits are all shapes `to_json(col) #>> '{}'` produces.
    for (const t of [
      '2026-04-17T12:00:00+00:00',
      '2026-04-17T12:00:00.1+00:00',
      '2026-04-17T12:00:00.123456+00:00',
      '2024-02-29T23:59:59+00:00', // a real leap day
      '2026-04-17T12:00:00Z',
      '2026-04-17T12:00:00-07:00',
    ]) {
      query.mockReset();
      store.clear();
      mockNode({ claim: row(), supports: [child(uuid(1), 'supports')] });
      const res = await request(app).get(`/fc/api/claims/${ROOT}?supportsCursor=${cursorFor(t, uuid(19))}`);
      expect(res.status).toBe(200);
      expect(columnCall('supports')[1]).toEqual([COMMUNITY, ROOT, 'supports', t, uuid(19), 21]);
    }
  });

  it('400s a cursor whose timestamp Postgres would reject, rather than letting it 500', async () => {
    // Date.parse is a far weaker check than ::timestamptz. Every value below passes Date.parse —
    // "1" and "x 1" become the year 2001, "2026-02-31" rolls into March, year 0000 parses fine —
    // and every one of them is a hard 22007 in Postgres. Verified against the live database with
    // pg_input_is_valid: all five are rejected there.
    // These five sail past Date.parse and die in Postgres — the exact gap this closes.
    const passesDateParse = ['1', '12', 'x 1', '2026-02-31', '0000-01-01T00:00:00Z'];
    for (const t of passesDateParse) expect(Number.isNaN(Date.parse(t))).toBe(false);

    for (const t of [...passesDateParse,
      '2026-02-31T00:00:00Z', '2026-13-01T00:00:00Z', '2026-04-17T25:00:00Z', 'nope']) {
      query.mockReset();
      store.clear();
      const res = await request(app).get(`/fc/api/claims/${ROOT}?supportsCursor=${cursorFor(t, uuid(19))}`);
      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_CURSOR');
      expect(query.mock.calls).toHaveLength(0);
      expect(store.size).toBe(0);
    }
  });

  it('400s a present cursor it could not have issued, rather than silently serving page one', async () => {
    // A cursor is never typed by a human — it is only ever echoed back from a previous response.
    // An unusable one means the client is broken or the link was mangled, and quietly answering
    // with page one gives a reader on page three duplicates forever, since the same bad cursor
    // keeps coming back. One rule covers all of it, including a cursor that does not decode.
    for (const bad of [
      '%%%not-base64%%%',
      cursorFor(TS, 'not-a-uuid'),
      Buffer.from(JSON.stringify({ t: TS })).toString('base64url'), // no id at all
      Buffer.from('not json at all').toString('base64url'),
      '',
    ]) {
      query.mockReset();
      store.clear();
      const res = await request(app).get(`/fc/api/claims/${ROOT}?supportsCursor=${encodeURIComponent(bad)}`);
      expect(res.status).toBe(400);
      expect(res.body.error).toEqual({
        code: 'INVALID_CURSOR',
        message: 'supportsCursor is not a cursor this API issued',
      });
      expect(res.headers['cache-control']).toBe('no-store');
      expect(query.mock.calls).toHaveLength(0);
    }
  });

  it('names the column whose cursor was bad', async () => {
    const res = await request(app).get(`/fc/api/claims/${ROOT}?opposesCursor=rubbish`);
    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain('opposesCursor');
  });

  it('is not tripped by an absent cursor', async () => {
    mockNode({ claim: row(), supports: [child(uuid(1), 'supports')] });
    expect((await request(app).get(`/fc/api/claims/${ROOT}?limit=5`)).status).toBe(200);
  });
});

describe('caching', () => {
  const keyFor = (
    ns: 'id' | 'root',
    id: string,
    limit = 20,
    supports: unknown = null,
    opposes: unknown = null
  ) => `fc:claim:${ns}:${id}:${JSON.stringify({ limit, supports, opposes })}`;

  it('serves a second anonymous reader from the shared cache', async () => {
    mockNode({ claim: row(), supports: [child(uuid(1), 'supports')] });
    const first = await request(app).get(`/fc/api/claims/${ROOT}`);
    expect(first.status).toBe(200);
    expect([...store.keys()]).toEqual([keyFor('id', ROOT)]);

    const callsAfterFirst = query.mock.calls.length;
    const second = await request(app).get(`/fc/api/claims/${ROOT}`);
    expect(second.body).toEqual(first.body);
    expect(query.mock.calls).toHaveLength(callsAfterFirst);
    expect(second.headers['cache-control']).toBe('public, max-age=0, s-maxage=30');
  });

  it('gives each route its own key namespace', async () => {
    // fc:claim:root:<id> and fc:claim:id:<id> are different keys even for the same string, which
    // is what stops one route answering with the other's body.
    mockNode({ claim: row() });
    await request(app).get(`/fc/api/communities/${COMMUNITY}/claims/root`);
    mockNode({ claim: row() });
    await request(app).get(`/fc/api/claims/${COMMUNITY}`);
    expect([...store.keys()].sort()).toEqual(
      [keyFor('root', COMMUNITY), keyFor('id', COMMUNITY)].sort()
    );
  });

  it('files one row under one key however the id was spelled', async () => {
    mockNode({ claim: row(), supports: [child(uuid(1), 'supports')] });
    await request(app).get(`/fc/api/claims/${ROOT.toUpperCase()}`);
    expect([...store.keys()]).toEqual([keyFor('id', ROOT)]);
    // And the uppercase spelling now reads that same entry rather than minting a second.
    const again = await request(app).get(`/fc/api/claims/${ROOT}`);
    expect(again.status).toBe(200);
    expect(store.size).toBe(1);
  });

  it('keys the cache on the decoded cursors, so no two requests can collide on one key', async () => {
    // Raw cursor strings joined with a delimiter let `?supportsCursor=a:b&opposesCursor=X` and
    // `?supportsCursor=a&opposesCursor=b:X` mint the same key for different bodies.
    const a = cursorFor(TS, uuid(1));
    const b = cursorFor(TS, uuid(2));
    mockNode({ claim: row(), supports: [child(uuid(9), 'supports')] });
    await request(app).get(`/fc/api/claims/${ROOT}?supportsCursor=${a}&opposesCursor=${b}`);
    mockNode({ claim: row(), supports: [child(uuid(9), 'supports')] });
    await request(app).get(`/fc/api/claims/${ROOT}?supportsCursor=${b}&opposesCursor=${a}`);

    expect([...store.keys()].sort()).toEqual([
      keyFor('id', ROOT, 20, { t: TS, id: uuid(1) }, { t: TS, id: uuid(2) }),
      keyFor('id', ROOT, 20, { t: TS, id: uuid(2) }, { t: TS, id: uuid(1) }),
    ].sort());
  });

  it('keeps a smuggled field out of the key', async () => {
    // decodeCursor hands back whatever JSON it found. parseColumnCursor rebuilds {t, id}, so an
    // extra field cannot reach JSON.stringify and fragment one page's cache across many entries.
    const padded = Buffer.from(JSON.stringify({ t: TS, id: uuid(1), junk: 'x'.repeat(50) }))
      .toString('base64url');
    mockNode({ claim: row(), supports: [child(uuid(9), 'supports')] });
    await request(app).get(`/fc/api/claims/${ROOT}?supportsCursor=${padded}`);
    expect([...store.keys()]).toEqual([keyFor('id', ROOT, 20, { t: TS, id: uuid(1) })]);
  });

  it('keys the cache on the page size the reader asked for', async () => {
    mockNode({ claim: row(), supports: [child(uuid(1), 'supports')] });
    await request(app).get(`/fc/api/claims/${ROOT}?limit=5`);
    mockNode({ claim: row(), supports: [child(uuid(1), 'supports')] });
    await request(app).get(`/fc/api/claims/${ROOT}`);
    expect([...store.keys()].sort()).toEqual(
      [keyFor('id', ROOT, 20), keyFor('id', ROOT, 5)].sort()
    );
  });

  it('never reads or writes the shared cache for a request that carries credentials', async () => {
    mockNode({ claim: row(), supports: [child(uuid(1), 'supports')] });
    const res = await request(app).get(`/fc/api/claims/${ROOT}`).set('Authorization', 'Bearer user');
    expect(res.status).toBe(200);
    expect(res.headers['cache-control']).toBe('private, no-store');
    expect(store.size).toBe(0);
  });

  it('declares that the response varies on Authorization', async () => {
    mockNode({ claim: row() });
    expect((await request(app).get(`/fc/api/claims/${ROOT}`)).headers.vary).toBe('Authorization');
    mockNode({ claim: row() });
    const auth = await request(app).get(`/fc/api/claims/${ROOT}`).set('Authorization', 'Bearer user');
    expect(auth.headers.vary).toBe('Authorization');
    // Errors too — they are served from the same branch and must not be filed under one key.
    mockNode({ claim: null });
    expect((await request(app).get(`/fc/api/claims/${MISSING}`)).headers.vary).toBe('Authorization');
  });

  it('tells a shared cache not to keep an error', async () => {
    // A 404 is a fact about this instant. Left without a header, a CDN may heuristically hold a
    // transient one for minutes and keep serving it after the claim appears.
    mockNode({ claim: null });
    const missing = await request(app).get(`/fc/api/claims/${MISSING}`);
    expect(missing.status).toBe(404);
    expect(missing.headers['cache-control']).toBe('no-store');
    expect(store.size).toBe(0);

    query.mockReset();
    query.mockResolvedValueOnce(rows([row()]));
    query.mockRejectedValueOnce(new Error('connection terminated'));
    query.mockResolvedValueOnce(rows([]));
    const failed = await request(app).get(`/fc/api/claims/${ROOT}`);
    expect(failed.status).toBe(500);
    expect(failed.headers['cache-control']).toBe('no-store');
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

  it('is the door serveNode actually uses', async () => {
    // Not merely that the guard works: that the route goes through it. Deleting the call from
    // serveNode leaves nothing in the store on an anonymous read.
    mockNode({ claim: row(), supports: [child(uuid(1), 'supports')] });
    const res = await request(app).get(`/fc/api/claims/${ROOT}`);
    expect(res.status).toBe(200);
    expect(store.size).toBe(1);
    expect([...store.values()][0]).toEqual(res.body);
  });
});

describe('GET /communities/:id/claims/shape', () => {
  /** A shape row as the DB hands it back. The route selects these five columns and no others. */
  const shapeRow = (
    id: string,
    parentId: string | null,
    side: 'supports' | 'opposes' | null,
    depth: number,
    moderationStatus = 'visible'
  ) => ({ id, parent_claim_id: parentId, side, depth, moderation_status: moderationStatus });

  /** A whole tree's worth of rows, already in the route's order (depth, then id). */
  const tree = () => [
    shapeRow('c-root', null, null, 0),
    shapeRow('c-o1', 'c-root', 'opposes', 1),
    shapeRow('c-s1', 'c-root', 'supports', 1),
    shapeRow('c-s1a', 'c-s1', 'supports', 2),
  ];

  /** Every key appearing anywhere in a parsed body, however deeply nested. */
  const keysIn = (v: unknown): string[] =>
    v !== null && typeof v === 'object'
      ? Object.entries(v as Record<string, unknown>).flatMap(([k, val]) => [k, ...keysIn(val)])
      : [];

  const shapeSql = () => allSql().filter((s) => s.includes('c.parent_claim_id,'));

  it('returns the whole tree as position only, shallowest first', async () => {
    query.mockResolvedValueOnce(rows(tree()));

    const res = await request(app).get('/fc/api/communities/comm-1/claims/shape');

    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      data: [
        { id: 'c-root', parentId: null, side: null, depth: 0, impact: null, isHidden: false },
        { id: 'c-o1', parentId: 'c-root', side: 'opposes', depth: 1, impact: null, isHidden: false },
        { id: 'c-s1', parentId: 'c-root', side: 'supports', depth: 1, impact: null, isHidden: false },
        { id: 'c-s1a', parentId: 'c-s1', side: 'supports', depth: 2, impact: null, isHidden: false },
      ],
      meta: { truncated: false },
    });

    // One query, the whole community, in the brief's order.
    expect(query.mock.calls).toHaveLength(1);
    expect(sqlOf(0)).toContain('ORDER BY c.depth, c.id');
    // community_id leads the WHERE and is the leading column of claims_community_parent_idx:
    // without it this is a sequential scan of every community's claims on every page view.
    expect(sqlOf(0)).toContain('c.community_id = $1');
    expect(query.mock.calls[0][1]).toEqual(['comm-1', 2001]);
  });

  it('omits claim bodies entirely', async () => {
    // The point of this endpoint: a whole-tree payload that cannot leak a hidden claim's wording
    // however large the tree gets. Not "this node has no body" — no body anywhere, ever.
    query.mockResolvedValueOnce(
      rows(
        tree().map((r) => ({
          ...r,
          body: 'wording that must not travel',
          author_display_name: 'Demo Finch',
        }))
      )
    );

    const res = await request(app).get('/fc/api/communities/comm-1/claims/shape');

    expect(res.status).toBe(200);
    expect(keysIn(res.body)).not.toContain('body');
    expect(JSON.stringify(res.body)).not.toContain('wording that must not travel');
    // Body is never SELECTed either, so there is no row in flight to leak by accident.
    expect(shapeSql()).toHaveLength(1);
    expect(shapeSql()[0]).not.toContain('c.body');

    // Nothing else internal travels under any name: a ShapeNode is exactly six fields, and the
    // moderation one is the derived boolean, never the raw column.
    expect([...new Set(keysIn(res.body.data[0]))].sort()).toEqual([
      'depth', 'id', 'impact', 'isHidden', 'parentId', 'side',
    ]);
    const text = JSON.stringify(res.body);
    for (const forbidden of ['author_id', 'author_display_name', 'community_id', COMMUNITY,
      'moderation_status', 'path', 'parent_claim_id', 'Demo Finch']) {
      expect(text).not.toContain(forbidden);
    }
  });

  it('caps the payload and flags truncation on a large tree', async () => {
    // The route asks for one more than the cap so "there is more" is observed, not guessed.
    const many = Array.from({ length: SHAPE_NODE_LIMIT + 1 }, (_, i) =>
      shapeRow(uuid(i), i === 0 ? null : 'c-root', i === 0 ? null : 'supports', i === 0 ? 0 : 1)
    );
    query.mockResolvedValueOnce(rows(many));

    const res = await request(app).get('/fc/api/communities/comm-big/claims/shape');

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(SHAPE_NODE_LIMIT);
    expect(res.body.meta.truncated).toBe(true);
    expect(query.mock.calls[0][1]).toEqual(['comm-big', SHAPE_NODE_LIMIT + 1]);
    expect(sqlOf(0)).toContain('LIMIT $2');
    // ORDER BY depth, id means the cut falls on the DEEPEST nodes — the right end to lose.
    expect(res.body.data.at(-1).id).toBe(uuid(SHAPE_NODE_LIMIT - 1));
  });

  it('does not flag truncation on a tree that exactly fills the cap', async () => {
    const exact = Array.from({ length: SHAPE_NODE_LIMIT }, (_, i) =>
      shapeRow(uuid(i), i === 0 ? null : 'c-root', i === 0 ? null : 'supports', i === 0 ? 0 : 1)
    );
    query.mockResolvedValueOnce(rows(exact));

    const res = await request(app).get('/fc/api/communities/comm-big/claims/shape');

    expect(res.body.data).toHaveLength(SHAPE_NODE_LIMIT);
    expect(res.body.meta.truncated).toBe(false);
  });

  it('includes hidden claims so the shape stays honest', async () => {
    // A hidden claim is a tombstone in its parent's column, not a hole. A map that dropped it
    // would disagree with what the reader can plainly see beside it.
    query.mockResolvedValueOnce(
      rows([
        shapeRow('c-root', null, null, 0),
        { ...shapeRow('c-hidden', 'c-root', 'opposes', 1), moderation_status: 'hidden' },
        { ...shapeRow('c-under', 'c-hidden', 'supports', 2), moderation_status: 'visible' },
      ])
    );

    const res = await request(app).get('/fc/api/communities/comm-1/claims/shape');

    expect(res.body.data.map((n: { id: string }) => n.id)).toEqual([
      'c-root', 'c-hidden', 'c-under',
    ]);
    // The subtree under a hidden claim keeps its parent, so the map stays connected.
    expect(res.body.data[2].parentId).toBe('c-hidden');
    // No moderation FILTER in the SQL — that is what keeps the map and the columns agreeing.
    expect(shapeSql()[0]).not.toContain("moderation_status = ");
    expect(shapeSql()[0]).not.toContain('WHERE c.moderation_status');
  });

  it('marks a hidden claim rather than drawing it as a live one', async () => {
    // Including a hidden claim is only half of agreeing with the columns, which tombstone it. A
    // minimap exists to show the pro/con balance at each depth, and counting a withdrawn claim as
    // a live one misstates exactly that. isHidden leaks nothing: it is already on every ClaimNode
    // the same reader can fetch, and the payload still carries no text.
    query.mockResolvedValueOnce(
      rows([
        shapeRow('c-root', null, null, 0),
        shapeRow('c-hidden', 'c-root', 'opposes', 1, 'hidden'),
        shapeRow('c-under', 'c-hidden', 'supports', 2),
      ])
    );

    const res = await request(app).get('/fc/api/communities/comm-1/claims/shape');

    expect(res.body.data.map((n: { isHidden: boolean }) => n.isHidden)).toEqual([
      false, true, false,
    ]);
    // Derived exactly as toClaim derives it, and from a column that is read but never served.
    expect(shapeSql()[0]).toContain('c.moderation_status');
    const keys = keysIn(res.body);
    expect(keys).not.toContain('moderation_status');
    expect(keys).not.toContain('body');
  });

  it('404s a community with no claims, and an id that is not a uuid', async () => {
    query.mockResolvedValueOnce(rows([]));
    const empty = await request(app).get('/fc/api/communities/comm-empty/claims/shape');
    expect(empty.status).toBe(404);
    expect(empty.body).toEqual({ error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' } });

    query.mockRejectedValueOnce(Object.assign(new Error('invalid input syntax'), { code: '22P02' }));
    const malformed = await request(app).get('/fc/api/communities/not-a-uuid/claims/shape');
    expect(malformed.status).toBe(404);
    expect(malformed.body.error.code).toBe('CLAIM_NOT_FOUND');

    expect(store.size).toBe(0); // neither is cached
  });

  it('500s a failed query rather than serving an empty map', async () => {
    // An empty map is a claim about the tree. A route that cannot read the tree makes no claim.
    query.mockRejectedValueOnce(new Error('connection terminated'));

    const res = await request(app).get('/fc/api/communities/comm-1/claims/shape');

    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe('CLAIM_FETCH_FAILED');
    expect(store.size).toBe(0);
  });

  it('caches one entry per community, under the key Task 8 deletes', async () => {
    query.mockResolvedValueOnce(rows(tree()));
    const first = await request(app).get('/fc/api/communities/comm-1/claims/shape');
    expect(first.status).toBe(200);
    // Exactly the key a claim write invalidates. If this string moves, Task 8 stops working and
    // readers keep a stale map until the TTL expires.
    expect([...store.keys()]).toEqual(['fc:claims:shape:comm-1']);

    const second = await request(app).get('/fc/api/communities/comm-1/claims/shape');
    expect(second.body).toEqual(first.body);
    expect(query.mock.calls).toHaveLength(1); // served from the cache, no second query
    expect(second.headers['cache-control']).toBe('public, max-age=0, s-maxage=30');
  });

  it('shares one cached body with a credentialed reader, since none of it depends on who asked', async () => {
    // The node routes refuse the shared cache for a credentialed request because a ClaimNode will
    // carry the caller's own rating. A ShapeNode has no caller-specific field, so there is one
    // body and one entry for everybody.
    query.mockResolvedValueOnce(rows(tree()));
    const anon = await request(app).get('/fc/api/communities/comm-1/claims/shape');

    const auth = await request(app)
      .get('/fc/api/communities/comm-1/claims/shape')
      .set('Authorization', 'Bearer user');

    expect(auth.status).toBe(200);
    expect(auth.body).toEqual(anon.body);
    expect(query.mock.calls).toHaveLength(1);
    expect([...store.keys()]).toEqual(['fc:claims:shape:comm-1']);
  });

  it('does not collide with the node routes on a path or a cache key', async () => {
    // /communities/:id/claims/root and /communities/:id/claims/shape differ by a literal segment,
    // and `fc:claim:root:x` is not `fc:claims:shape:x` — neither route can serve the other's body.
    mockNode({ claim: row() });
    const root = await request(app).get(`/fc/api/communities/${COMMUNITY}/claims/root`);
    expect(root.body.data.claim.id).toBe(ROOT);

    query.mockResolvedValueOnce(rows(tree()));
    const shape = await request(app).get('/fc/api/communities/comm-1/claims/shape');
    expect(shape.body.data).toHaveLength(4);
    expect([...store.keys()].sort()).toEqual(
      [
        `fc:claim:root:${COMMUNITY}:{"limit":20,"supports":null,"opposes":null}`,
        'fc:claims:shape:comm-1',
      ].sort()
    );
  });
});
