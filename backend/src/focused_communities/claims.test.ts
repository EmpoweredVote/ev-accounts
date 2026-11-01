import { describe, it, expect, vi, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';
import { readdirSync, readFileSync } from 'node:fs';
import { MAX_CLAIM_DEPTH } from './lib/utils.js';

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

// optionalAuth, reduced to the one outcome these routes depend on: a Bearer token the engine
// verified leaves req.userId behind, and anything else leaves the request anonymous. The real
// one also refuses revoked, deleted and suspended accounts, none of which this route branches
// on: by the time it runs the question is only whether there is a userId.
vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (req: express.Request, _res: express.Response, next: express.NextFunction) => {
    if (req.headers.authorization === `Bearer ${VIEWER_TOKEN}`) Object.assign(req, { userId: VIEWER });
    // A token that verified but resolved to something that is not a uuid. The real middleware
    // should never produce one; viewerId refuses it anyway, and this is how that is observed.
    if (req.headers.authorization === `Bearer ${MALFORMED_TOKEN}`) Object.assign(req, { userId: 'not-a-uuid' });
    next();
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
/** A signed-in reader, and the token the optionalAuth mock recognises. */
const VIEWER = uuid(777);
const VIEWER_TOKEN = 'a-reader';
/** A reader whose verified identity is not uuid-shaped. */
const MALFORMED_TOKEN = 'a-reader-with-a-broken-id';
const asViewer = (url: string) => request(app).get(url).set('Authorization', `Bearer ${VIEWER_TOKEN}`);

/** A cursor as the route issues one: impact first, then the recency tie-breaks. */
const cursorFor = (t: string, id: string, i = 5) =>
  Buffer.from(JSON.stringify({ i, t, id })).toString('base64url');
const decode = (c: string) => JSON.parse(Buffer.from(c, 'base64url').toString('utf8'));

/** A claims row as the DB hands it back (snake_case, ts() text timestamps). */
const row = (over: Record<string, unknown> = {}) => ({
  id: ROOT,
  side: null,
  body: 'Root claim',
  author_display_name: null,
  moderation_status: 'visible',
  // NUMERIC comes off node-postgres as a string; 5.0000 is what CA_0345's generated column
  // reads for a claim nobody has rated - the neutral midpoint, never null.
  impact: '5.0000',
  rating_count: 0,
  my_rating: null,
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
    id: ROOT, side: null, body: 'b', authorPseudonym: null, impact: 5, ratingCount: 0,
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
      // 5, not null. An unrated claim sits at the neutral midpoint so the ordering can place
      // it; 'nobody has rated this' is ratingCount === 0, a different question.
      impact: 5,
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
    // $2 is the viewer, null for this anonymous read — the parameter that fills `myRating`.
    expect(query.mock.calls[0][1]).toEqual([COMMUNITY, null]);
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

  it('bounds the ancestry query by the depth cap', async () => {
    // One query is not the same as a bounded response. The write route and CA_0344's CHECK both
    // cap depth, but this read must not depend on either holding — a pre-cap row, or any future
    // way of deepening the tree, would otherwise turn one claim into an unbounded breadcrumb,
    // served to anonymous readers as `public, s-maxage=30` and so cached and re-served.
    const path = Array.from({ length: 10 }, (_, i) => `anc-${i}`);
    mockNode({
      claim: row({ id: uuid(41), side: 'supports', body: 'Deep claim', path }),
      breadcrumb: path.map((id) => ({ id, body: `${id} body`, side: 'supports', moderation_status: 'visible' })),
    });

    await request(app).get(`/fc/api/claims/${uuid(41)}`);

    // One past the cap, so an over-cap claim is detectable rather than silently trimmed to
    // look legal.
    const ancestry = allSql().filter((s) => s.includes('array_position'));
    expect(ancestry[0]).toContain(`LIMIT ${MAX_CLAIM_DEPTH + 1}`);
  });

  it('warns distinctly for a claim deeper than the cap and for a damaged path', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {});

    // Deeper than the cap: the shortfall is the LIMIT working, not damage.
    const deep = Array.from({ length: MAX_CLAIM_DEPTH + 5 }, (_, i) => `anc-${i}`);
    mockNode({
      claim: row({ id: uuid(42), side: 'supports', body: 'Over-cap claim', path: deep }),
      breadcrumb: deep.slice(0, MAX_CLAIM_DEPTH + 1).map((id) => ({
        id, body: `${id} body`, side: 'supports', moderation_status: 'visible',
      })),
    });
    await request(app).get(`/fc/api/claims/${uuid(42)}`);
    expect(warn.mock.calls.flat().join(' ')).toContain('deeper than MAX_CLAIM_DEPTH');

    // Within the cap but short of its path: that is a damaged tree, and says so differently.
    warn.mockClear();
    query.mockReset();
    const shallow = ['anc-0', 'anc-1', 'anc-2'];
    mockNode({
      claim: row({ id: uuid(43), side: 'supports', body: 'Damaged claim', path: shallow }),
      breadcrumb: [{ id: 'anc-0', body: 'a', side: null, moderation_status: 'visible' }],
    });
    await request(app).get(`/fc/api/claims/${uuid(43)}`);
    const damaged = warn.mock.calls.flat().join(' ');
    expect(damaged).toContain('breadcrumb resolved 1 of 3 ancestors');
    expect(damaged).not.toContain('deeper than MAX_CLAIM_DEPTH');

    warn.mockRestore();
  });

  it('skips the ancestry query entirely for a root', async () => {
    mockNode({ claim: row({ path: [] }) });
    await request(app).get(`/fc/api/claims/${ROOT}`);
    expect(allSql().filter((s) => s.includes('array_position'))).toHaveLength(0);
    expect(query.mock.calls).toHaveLength(3);
  });

  it('orders each column by impact descending', async () => {
    // The ORDER BY, the keyset predicate and the cursor payload are one unit; this pins the
    // first of the three, and 'feeds the cursor it issued straight back' pins that they agree.
    // NULLS LAST is written although connect.claims.impact is NOT NULL: claims_column_order_idx
    // is declared to match it, and the planner will not use an index whose nulls ordering
    // differs to deliver a sort.
    mockNode({
      claim: row(),
      supports: [child(uuid(1), 'supports'), child(uuid(2), 'supports')],
      opposes: [child(uuid(3), 'opposes'), child(uuid(4), 'opposes')],
    });

    const res = await request(app).get(`/fc/api/claims/${ROOT}`);

    const columns = allSql().filter((s) => s.includes('c.parent_claim_id = $2'));
    expect(columns).toHaveLength(2);
    for (const sql of columns)
      expect(sql).toContain('ORDER BY c.impact DESC NULLS LAST, c.created_at DESC, c.id DESC');
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
      // $4 is the viewer, null for this anonymous read. It sits before any cursor values so
      // its placeholder number does not move with the presence of a cursor.
      expect(call[1]).toEqual([COMMUNITY, ROOT, side, null, 21]);
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
    expect(decode(cursor)).toEqual({ i: last.impact, t: last.createdAt, id: last.id });

    mockNode({ claim: row(), supports: [child(uuid(20), 'supports')] });
    const second = await request(app).get(`/fc/api/claims/${ROOT}?supportsCursor=${cursor}`);

    expect(second.status).toBe(200);
    const call = columnCall('supports');
    // 🔴 THE WHOLE PREDICATE, not three substrings of it. Asserting that each term APPEARS
    // passes happily for `(TRUE OR c.impact < $5 OR ...)`, which serves every row of every
    // page forever. The shape is what has to hold: three descending keys, compared in the
    // ORDER BY's own order, with impact as ::numeric and nothing widening the match.
    expect(String(call[0])).toMatch(
      /\(c\.impact < \$5::numeric OR \(c\.impact = \$5::numeric AND c\.created_at < \$6::timestamptz\) OR \(c\.impact = \$5::numeric AND c\.created_at = \$6::timestamptz AND c\.id < \$7::uuid\)\)/
    );
    expect(String(call[0])).not.toMatch(/\bTRUE\b/i);
    expect(call[1]).toEqual([
      COMMUNITY, ROOT, 'supports', null, last.impact, last.createdAt, last.id, 21,
    ]);
  });

  it('carries an impact through the cursor without losing a digit', async () => {
    // 🔴 The keyset is only correct if the number the cursor CARRIES is the number the
    // predicate SENDS. A cursor value makes the round trip NUMERIC -> string (node-postgres)
    // -> Number -> JSON -> Number -> string -> ::numeric, and CA_0345 rounds impact to four
    // decimals precisely so that trip is lossless. Unrounded numeric division gives sixteen
    // fractional digits, which a float64 cannot hold, and the cursor would land between two
    // rows — re-serving some children forever and dropping others.
    const many = Array.from({ length: 21 }, (_, i) =>
      child(uuid(i), 'supports', { impact: '5.6667', created_at: `2026-04-17T12:00:${String(i).padStart(2, '0')}.000000+00:00` })
    );
    mockNode({ claim: row(), supports: many });
    const first = await request(app).get(`/fc/api/claims/${ROOT}`);
    expect(first.body.data.supports[19].impact).toBe(5.6667);

    const cursor = first.body.meta.supports.cursor as string;
    expect(decode(cursor).i).toBe(5.6667);

    mockNode({ claim: row(), supports: [child(uuid(20), 'supports')] });
    await request(app).get(`/fc/api/claims/${ROOT}?supportsCursor=${cursor}`);

    // The value handed to Postgres, and the text node-postgres will send for it.
    const sent = columnCall('supports')[1][4];
    expect(sent).toBe(5.6667);
    expect(String(sent)).toBe('5.6667');
  });

  it('numbers the keyset placeholders after the filter parameters', async () => {
    const cursor = cursorFor(TS, uuid(19));
    mockNode({ claim: row(), supports: [child(uuid(20), 'supports')] });

    const res = await request(app).get(`/fc/api/claims/${ROOT}?supportsCursor=${cursor}&limit=5`);

    expect(res.status).toBe(200);
    expect(columnCall('supports')[1]).toEqual([
      COMMUNITY, ROOT, 'supports', null, 5, TS, uuid(19), 6,
    ]);
    // The opposes column is untouched by the supports cursor.
    expect(columnCall('opposes')[1]).toEqual([COMMUNITY, ROOT, 'opposes', null, 6]);
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
      expect(columnCall('supports')[1]).toEqual([
        COMMUNITY, ROOT, 'supports', null, 5, t, uuid(19), 21,
      ]);
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
      // The impact leg, which `$n::numeric` would otherwise be handed raw. Postgres accepts
      // 'NaN' as a numeric and would then compare it against every row; 'Infinity' likewise.
      Buffer.from(JSON.stringify({ t: TS, id: uuid(19) })).toString('base64url'), // no impact
      Buffer.from(JSON.stringify({ i: '5', t: TS, id: uuid(19) })).toString('base64url'),
      Buffer.from(JSON.stringify({ i: null, t: TS, id: uuid(19) })).toString('base64url'),
      cursorFor(TS, uuid(19), 0),   // below the 1 a rating can be
      cursorFor(TS, uuid(19), 9.5), // above the 9
      cursorFor(TS, uuid(19), -1),
      Buffer.from('{"i":NaN,"t":"' + TS + '","id":"' + uuid(19) + '"}').toString('base64url'),
      Buffer.from('{"i":1e999,"t":"' + TS + '","id":"' + uuid(19) + '"}').toString('base64url'),
      Buffer.from(JSON.stringify([5, TS, uuid(19)])).toString('base64url'), // not an object
      Buffer.from(JSON.stringify(null)).toString('base64url'),
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
      keyFor('id', ROOT, 20, { i: 5, t: TS, id: uuid(1) }, { i: 5, t: TS, id: uuid(2) }),
      keyFor('id', ROOT, 20, { i: 5, t: TS, id: uuid(2) }, { i: 5, t: TS, id: uuid(1) }),
    ].sort());
  });

  it('keeps a smuggled field out of the key', async () => {
    // The decoded JSON is whatever the caller encoded. parseColumnCursor rebuilds {i, t, id}
    // field by field, so an extra one cannot reach JSON.stringify and fragment one page's
    // cache across as many entries as an attacker cares to mint.
    const padded = Buffer.from(
      JSON.stringify({ i: 5, t: TS, id: uuid(1), junk: 'x'.repeat(50) })
    ).toString('base64url');
    mockNode({ claim: row(), supports: [child(uuid(9), 'supports')] });
    await request(app).get(`/fc/api/claims/${ROOT}?supportsCursor=${padded}`);
    expect([...store.keys()]).toEqual([keyFor('id', ROOT, 20, { i: 5, t: TS, id: uuid(1) })]);
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

describe('isShareable — the one guard between a reader and a leaked rating', () => {
  // The entire justification for hand-rolling the cache. It is tested directly as well as
  // through the route, because the route only ever reaches it on the ANONYMOUS branch — so a
  // direct call is the only way to watch it refuse a body that carries somebody's rating.
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

describe('myRating — the one field that depends on who asked', () => {
  /** Every call that selected claim columns, i.e. everything but the breadcrumb. */
  const claimCalls = () =>
    query.mock.calls.filter((c) => String(c[0]).includes('AS my_rating'));

  it('fills the reader own rating from the row, and leaves it null where there is none', async () => {
    mockNode({
      claim: row({ my_rating: 7, impact: '6.6000', rating_count: 20 }),
      supports: [child(uuid(1), 'supports', { my_rating: 2 }), child(uuid(2), 'supports')],
      opposes: [child(uuid(3), 'opposes')],
    });

    const res = await asViewer(`/fc/api/claims/${ROOT}`);

    expect(res.status).toBe(200);
    expect(res.body.data.claim.myRating).toBe(7);
    expect(res.body.data.supports.map((c: { myRating: number | null }) => c.myRating)).toEqual([2, null]);
    expect(res.body.data.opposes[0].myRating).toBeNull();
    // The aggregate is the same number for everybody; only myRating varies.
    expect(res.body.data.claim.impact).toBe(6.6);
    expect(res.body.data.claim.ratingCount).toBe(20);
  });

  it('asks for it in the statement that reads the claim, not in a query of its own', async () => {
    mockNode({ claim: row(), supports: [child(uuid(1), 'supports')] });
    await asViewer(`/fc/api/claims/${ROOT}`);

    // Three queries for a root: the claim and the two columns. A fourth would mean the rating
    // was fetched separately — a round trip per request on a pool that is max: 3.
    expect(query.mock.calls).toHaveLength(3);
    expect(claimCalls()).toHaveLength(3);
    for (const call of claimCalls()) {
      expect(String(call[0])).toContain('FROM connect.claim_ratings r');
      // 🔴 BOTH halves of the subquery's WHERE. `r.claim_id = c.id` alone would return SOME
      // person's rating of this claim - whichever row the scan reached first - and serve it
      // to everybody as their own. That is the leak this whole field is fenced against, and
      // it would pass a test that only checked the claim half.
      expect(String(call[0])).toMatch(/r\.claim_id = c\.id AND r\.user_id = \$\d+::uuid/);
      expect(call[1]).toContain(VIEWER);
    }
  });

  it('asks the same question of an anonymous reader, with a null answer', async () => {
    // One SQL text serves both readers. `r.user_id = NULL` is never true, so the subquery yields
    // NULL and an anonymous body carries no rating — rather than there being a second query
    // shape that could drift from this one.
    mockNode({ claim: row(), supports: [child(uuid(1), 'supports')] });
    const res = await request(app).get(`/fc/api/claims/${ROOT}`);

    expect(res.body.data.claim.myRating).toBeNull();
    for (const call of claimCalls()) {
      expect(String(call[0])).toContain('AS my_rating');
      expect(call[1]).toContain(null);
      expect(call[1]).not.toContain(VIEWER);
    }
  });

  it('reads as anonymous when the userId is not a uuid, rather than letting it reach ::uuid', async () => {
    // A userId that is not uuid-shaped would be a 22P02 out of the claim lookup — a signed-in
    // reader's page turning into an anonymous 500. Reading as a guest is the safe way to be
    // wrong about an identity.
    mockNode({ claim: row({ my_rating: 4 }), supports: [] });
    const res = await request(app)
      .get(`/fc/api/claims/${ROOT}`)
      .set('Authorization', `Bearer ${MALFORMED_TOKEN}`);

    expect(res.status).toBe(200);
    for (const call of claimCalls()) {
      expect(call[1]).toContain(null);
      expect(call[1]).not.toContain('not-a-uuid');
    }
    // Still treated as credentialed, so nothing is cached for it either - carriesCredentials
    // asks about the header, not about whether the id turned out to be usable.
    expect(store.size).toBe(0);
  });

  // ── The dangerous line ─────────────────────────────────────────────────────────────────
  // A body carrying one reader's rating must never be handed to another. Two independent
  // guards stand in the way and each gets its own test, because either one alone would make
  // the other's failure invisible.

  it('never writes a body carrying a rating into the shared cache', async () => {
    mockNode({
      claim: row({ my_rating: 9 }),
      supports: [child(uuid(1), 'supports', { my_rating: 1 })],
    });

    const res = await asViewer(`/fc/api/claims/${ROOT}`);

    expect(res.status).toBe(200);
    expect(res.body.data.claim.myRating).toBe(9);
    // 🔴 Nothing was stored. Guard one: the request carries credentials, so the cache branch is
    // never taken at all.
    expect(store.size).toBe(0);
    expect(res.headers['cache-control']).toBe('private, no-store');
    expect(res.headers.vary).toBe('Authorization');
  });

  it('never serves one reader a body another reader is in', async () => {
    // End to end, because the two guards are only worth what they are worth together: a
    // personalized read must leave nothing behind for the anonymous read that follows it.
    mockNode({ claim: row({ my_rating: 9 }), supports: [] });
    const mine = await asViewer(`/fc/api/claims/${ROOT}`);
    expect(mine.body.data.claim.myRating).toBe(9);

    mockNode({ claim: row(), supports: [] });
    const theirs = await request(app).get(`/fc/api/claims/${ROOT}`);
    expect(theirs.body.data.claim.myRating).toBeNull();

    // And the one body that DID reach the store is the anonymous one, with nothing in it.
    expect(store.size).toBe(1);
    const stored = [...store.values()][0] as { data: { claim: { myRating: number | null } } };
    expect(stored.data.claim.myRating).toBeNull();
  });

  it('refuses the body at the cache door too, even if it ever reached it', async () => {
    // Guard two, exercised directly: cacheNodeIfShareable is the only writer, and it asks
    // isShareable first. Deleting the credentials branch above would leave THIS between a
    // reader's rating and the shared cache. Deleting both is what the two tests together catch.
    await cacheNodeIfShareable('fc:claim:test:rated', nodeBody(9));
    expect(store.size).toBe(0);
  });
});

describe('GET /communities/:id/claims/shape', () => {
  /** A community id with hex LETTERS in it, so case actually differs. */
  const MIXED = '0a0eebc9-9c0b-4ef8-bb6d-6bb9bd380a11';

  /** A shape row as the DB hands it back. The route selects these seven columns and no others. */
  const shapeRow = (
    id: string,
    parentId: string | null,
    side: 'supports' | 'opposes' | null,
    depth: number,
    over: Record<string, unknown> = {}
  ) => ({
    id,
    parent_claim_id: parentId,
    side,
    depth,
    moderation_status: 'visible',
    merged_into_claim_id: null,
    impact: '5.0000',
    ...over,
  });

  /** A whole tree's worth of rows, already in the route's order (depth, then id). */
  const tree = () => [
    shapeRow('c-root', null, null, 0),
    shapeRow('c-o1', 'c-root', 'opposes', 1, { impact: '3.2500' }),
    // Two nodes away from the neutral default, so a serializer that hardcoded 5 - or dropped
    // the column - would be visible here rather than agreeing with the fixture by accident.
    shapeRow('c-s1', 'c-root', 'supports', 1, { impact: '7.8000' }),
    shapeRow('c-s1a', 'c-s1', 'supports', 2),
  ];

  /**
   * A tree one node larger than the cap, with `depths` giving each row's level. The route fetches
   * SHAPE_NODE_LIMIT + 1 rows, so the last one here is the first node that did NOT fit.
   */
  const oversized = (depthAt: (i: number) => number) =>
    Array.from({ length: SHAPE_NODE_LIMIT + 1 }, (_, i) =>
      shapeRow(uuid(i), i === 0 ? null : 'c-root', i === 0 ? null : 'supports', depthAt(i))
    );

  /** Every key appearing anywhere in a parsed body, however deeply nested. */
  const keysIn = (v: unknown): string[] =>
    v !== null && typeof v === 'object'
      ? Object.entries(v as Record<string, unknown>).flatMap(([k, val]) => [k, ...keysIn(val)])
      : [];

  const shapeSql = () => allSql().filter((s) => s.includes('c.parent_claim_id,'));
  const shapeUrl = (id: string = COMMUNITY) => `/fc/api/communities/${id}/claims/shape`;

  it('returns the whole tree as position only, shallowest first', async () => {
    query.mockResolvedValueOnce(rows(tree()));

    const res = await request(app).get(shapeUrl());

    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      data: [
        { id: 'c-root', parentId: null, side: null, depth: 0, impact: 5, isHidden: false, mergedInto: null },
        { id: 'c-o1', parentId: 'c-root', side: 'opposes', depth: 1, impact: 3.25, isHidden: false, mergedInto: null },
        { id: 'c-s1', parentId: 'c-root', side: 'supports', depth: 1, impact: 7.8, isHidden: false, mergedInto: null },
        { id: 'c-s1a', parentId: 'c-s1', side: 'supports', depth: 2, impact: 5, isHidden: false, mergedInto: null },
      ],
      // Nothing was cut, so there is no boundary to report: read the two fields together.
      meta: { truncated: false, completeThroughDepth: null },
    });

    // One query, the whole community, in the brief's order.
    expect(query.mock.calls).toHaveLength(1);
    expect(sqlOf(0)).toContain('ORDER BY c.depth, c.id');
    // community_id leads the WHERE and is the leading column of claims_community_parent_idx:
    // without it this is a sequential scan of every community's claims on every page view.
    expect(sqlOf(0)).toContain('c.community_id = $1');
    // impact is SELECTED, not defaulted: the serializer reads a column, and a payload that
    // stopped fetching it would colour every node neutral while still looking well-formed.
    expect(sqlOf(0)).toContain('c.impact');
    expect(query.mock.calls[0][1]).toEqual([COMMUNITY, 2001]);
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

    const res = await request(app).get(shapeUrl());

    expect(res.status).toBe(200);
    expect(keysIn(res.body)).not.toContain('body');
    expect(JSON.stringify(res.body)).not.toContain('wording that must not travel');
    // Body is never SELECTed either, so there is no row in flight to leak by accident.
    expect(shapeSql()).toHaveLength(1);
    expect(shapeSql()[0]).not.toContain('c.body');

    // Nothing else internal travels under any name: a ShapeNode is exactly seven fields, and the
    // moderation one is the derived boolean, never the raw column.
    expect([...new Set(keysIn(res.body.data[0]))].sort()).toEqual([
      'depth', 'id', 'impact', 'isHidden', 'mergedInto', 'parentId', 'side',
    ]);
    const text = JSON.stringify(res.body);
    for (const forbidden of ['author_id', 'author_display_name', 'community_id', COMMUNITY,
      'moderation_status', 'merged_into_claim_id', 'path', 'parent_claim_id', 'Demo Finch']) {
      expect(text).not.toContain(forbidden);
    }
  });

  it('caps the payload and flags truncation on a large tree', async () => {
    // The route asks for one more than the cap so "there is more" is observed, not guessed.
    query.mockResolvedValueOnce(rows(oversized((i) => (i === 0 ? 0 : 1))));

    const res = await request(app).get(shapeUrl());

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(SHAPE_NODE_LIMIT);
    expect(res.body.meta.truncated).toBe(true);
    expect(query.mock.calls[0][1]).toEqual([COMMUNITY, SHAPE_NODE_LIMIT + 1]);
    expect(sqlOf(0)).toContain('LIMIT $2');
    // ORDER BY depth, id means the cut falls on the DEEPEST nodes — the right end to lose.
    expect(res.body.data.at(-1).id).toBe(uuid(SHAPE_NODE_LIMIT - 1));
  });

  it('names the deepest level it holds whole, because the cut lands inside a level', async () => {
    // The hazard `truncated` cannot express. The tie-break is `id`, a random uuid, so the siblings
    // that survive at the boundary depth are an arbitrary sample: a level of 400 supports and 390
    // opposes cut part-way through renders as "3 supports, 1 oppose" and looks finished. Per-depth
    // pro/con balance is the entire purpose of a minimap, so meta has to say where it stops being
    // true. Here depths 0..2 are whole and depth 3 is cut mid-level.
    const depthAt = (i: number) => (i === 0 ? 0 : i <= 500 ? 1 : i <= 1500 ? 2 : 3);
    query.mockResolvedValueOnce(rows(oversized(depthAt)));

    const res = await request(app).get(shapeUrl());

    expect(res.body.meta).toEqual({ truncated: true, completeThroughDepth: 2 });
    // The partial level is still SERVED — trimming it would hide the reader's own claim and break
    // the parent links — it is merely declared untrustworthy to count.
    const atBoundary = res.body.data.filter((n: { depth: number }) => n.depth === 3);
    expect(atBoundary.length).toBeGreaterThan(0);
    expect(atBoundary.length).toBeLessThan(500); // an arbitrary subset of that level, not all of it
    // Every level at or above the declared one is entire.
    expect(res.body.data.filter((n: { depth: number }) => n.depth === 1)).toHaveLength(500);
    expect(res.body.data.filter((n: { depth: number }) => n.depth === 2)).toHaveLength(1000);
  });

  it('reports the boundary from the first row that did not fit, not from the last that did', async () => {
    // The cut falls exactly on a level boundary: rows 0..1999 are depths 0..2 and the first row
    // past the cap is the first node of depth 3. Depth 2 IS whole, so it must be reported whole —
    // deriving the answer from the last row served would have said 2 here and 3 in the mid-level
    // case above, which is the bug this phrasing avoids.
    const depthAt = (i: number) => (i === 0 ? 0 : i <= 1000 ? 1 : i <= 1999 ? 2 : 3);
    query.mockResolvedValueOnce(rows(oversized(depthAt)));

    const res = await request(app).get(shapeUrl());

    expect(res.body.meta).toEqual({ truncated: true, completeThroughDepth: 2 });
    expect(res.body.data.at(-1).depth).toBe(2);
  });

  it('does not flag truncation on a tree that exactly fills the cap', async () => {
    const exact = Array.from({ length: SHAPE_NODE_LIMIT }, (_, i) =>
      shapeRow(uuid(i), i === 0 ? null : 'c-root', i === 0 ? null : 'supports', i === 0 ? 0 : 1)
    );
    query.mockResolvedValueOnce(rows(exact));

    const res = await request(app).get(shapeUrl());

    expect(res.body.data).toHaveLength(SHAPE_NODE_LIMIT);
    expect(res.body.meta).toEqual({ truncated: false, completeThroughDepth: null });
  });

  it('includes hidden claims so the shape stays honest', async () => {
    // A hidden claim is a tombstone in its parent's column, not a hole. A map that dropped it
    // would disagree with what the reader can plainly see beside it.
    query.mockResolvedValueOnce(
      rows([
        shapeRow('c-root', null, null, 0),
        shapeRow('c-hidden', 'c-root', 'opposes', 1, { moderation_status: 'hidden' }),
        shapeRow('c-under', 'c-hidden', 'supports', 2),
      ])
    );

    const res = await request(app).get(shapeUrl());

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
        shapeRow('c-hidden', 'c-root', 'opposes', 1, { moderation_status: 'hidden' }),
        shapeRow('c-under', 'c-hidden', 'supports', 2),
      ])
    );

    const res = await request(app).get(shapeUrl());

    expect(res.body.data.map((n: { isHidden: boolean }) => n.isHidden)).toEqual([
      false, true, false,
    ]);
    // Derived exactly as toClaim derives it, and from a column that is read but never served.
    expect(shapeSql()[0]).toContain('c.moderation_status');
    const keys = keysIn(res.body);
    expect(keys).not.toContain('moderation_status');
    expect(keys).not.toContain('body');
  });

  it('marks a merged claim, which is a duplicate of another claim', async () => {
    // A merged-away claim is the same argument as the one it was folded into. Without the flag
    // the map inflates that side by exactly the number of merges: one argument, two dots.
    query.mockResolvedValueOnce(
      rows([
        shapeRow('c-root', null, null, 0),
        shapeRow('c-keep', 'c-root', 'supports', 1),
        shapeRow('c-dupe', 'c-root', 'supports', 1, { merged_into_claim_id: 'c-keep' }),
      ])
    );

    const res = await request(app).get(shapeUrl());

    expect(res.body.data.map((n: { mergedInto: string | null }) => n.mergedInto)).toEqual([
      null, null, 'c-keep',
    ]);
    // Here the target happens to be in the payload, so a client can fold the duplicate onto it.
    // That is a property of THIS tree, not a guarantee — see the next test.
    expect(res.body.data.map((n: { id: string }) => n.id)).toContain('c-keep');
    // An id, under ClaimNode's name for it. No wording, and not the raw column.
    expect(shapeSql()[0]).toContain('c.merged_into_claim_id');
    expect(keysIn(res.body)).not.toContain('merged_into_claim_id');
    expect(keysIn(res.body)).not.toContain('body');
  });

  it('serves a merge target that is not in the payload, rather than hiding the edge', async () => {
    // The schema guarantees only that the target is a real claim and is not this one
    // (claims_merged_into_claim_id_fkey, claims_no_self_merge). Nothing pins it to the same
    // community and nothing makes it shallower, so it can sit below the cut, in the partial
    // boundary level, or outside this tree entirely. The route reports the edge it was given: a
    // client that cannot find the id draws an ordinary node, because a visible duplicate beats a
    // node that vanishes into nothing, and must not read the absence as bad data.
    query.mockResolvedValueOnce(
      rows([
        shapeRow('c-root', null, null, 0),
        shapeRow('c-dupe', 'c-root', 'supports', 1, { merged_into_claim_id: 'c-elsewhere' }),
        // A chain: the target of this one is itself merged. One hop is not enough to fold.
        shapeRow('c-a', 'c-root', 'supports', 1, { merged_into_claim_id: 'c-b' }),
        shapeRow('c-b', 'c-root', 'supports', 1, { merged_into_claim_id: 'c-elsewhere' }),
      ])
    );

    const res = await request(app).get(shapeUrl());

    const ids = res.body.data.map((n: { id: string }) => n.id);
    expect(ids).not.toContain('c-elsewhere');
    // The node is still served, in place, with the edge intact — not dropped, not nulled out.
    expect(res.body.data[1]).toEqual({
      id: 'c-dupe', parentId: 'c-root', side: 'supports', depth: 1,
      impact: 5, isHidden: false, mergedInto: 'c-elsewhere',
    });
    // And a chain survives as a chain: following one hop from c-a lands on another merged node.
    expect(res.body.data[2].mergedInto).toBe('c-b');
    expect(res.body.data[3].mergedInto).toBe('c-elsewhere');
  });

  it('404s a community with no claims', async () => {
    query.mockResolvedValueOnce(rows([]));

    const empty = await request(app).get(shapeUrl(MISSING));

    expect(empty.status).toBe(404);
    expect(empty.body).toEqual({ error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' } });
    expect(store.size).toBe(0);
  });

  it('refuses an id that is not a uuid before it reaches a cache key or the database', async () => {
    // An unconstrained id in a key is a way to reach another route's entries, and a spelling
    // Postgres would reject is not worth a round trip.
    // The last two are spellings Postgres WOULD accept as a uuid — braced and hyphenless —
    // which is exactly why they must not be allowed to mint a second key for one community.
    const bad = ['not-a-uuid', 'comm-1', '00000000-0000-4000-8000-00000000090',
      encodeURIComponent('{' + COMMUNITY + '}'), COMMUNITY.replace(/-/g, '')];
    for (const id of bad) {
      const res = await request(app).get(shapeUrl(id));
      expect(res.status).toBe(404);
      expect(res.body.error.code).toBe('CLAIM_NOT_FOUND');
    }
    expect(query.mock.calls).toHaveLength(0); // no query ran
    expect(store.size).toBe(0); // and no key was minted
  });

  it('serves every spelling of one community id from one cache entry', async () => {
    // Postgres reads an upper-case uuid as the same row, so an upper-case URL is the same tree.
    // A key built from the raw spelling would mint a second ~380 KB entry on the shared Upstash
    // instance — the quota exhaustion src/lib/cache.ts records as a P1 — and Task 8's `del` of
    // the lower-case key would never reach it, leaving a stale map behind the alias.
    query.mockResolvedValueOnce(rows(tree()));
    const upper = await request(app).get(shapeUrl(MIXED.toUpperCase()));
    expect(upper.status).toBe(200);

    expect([...store.keys()]).toEqual([`fc:claims:shape:${MIXED}`]);
    // The canonical id is what the database is asked about, too.
    expect(query.mock.calls[0][1]).toEqual([MIXED, SHAPE_NODE_LIMIT + 1]);

    const lower = await request(app).get(shapeUrl(MIXED));
    expect(lower.body).toEqual(upper.body);
    expect(query.mock.calls).toHaveLength(1); // the second spelling hit the one entry
    expect(store.size).toBe(1);
  });

  it('500s a failed query rather than serving an empty map', async () => {
    // An empty map is a claim about the tree. A route that cannot read the tree makes no claim.
    query.mockRejectedValueOnce(new Error('connection terminated'));

    const res = await request(app).get(shapeUrl());

    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe('CLAIM_FETCH_FAILED');
    // The raw Postgres message stays in the logs, never in an anonymous response.
    expect(JSON.stringify(res.body)).not.toContain('connection terminated');
    expect(store.size).toBe(0);
  });

  it('caches one entry per community, under the key Task 8 deletes', async () => {
    query.mockResolvedValueOnce(rows(tree()));
    const first = await request(app).get(shapeUrl());
    expect(first.status).toBe(200);
    // Exactly the key a claim write invalidates. If this string moves, Task 8 stops working and
    // readers keep a stale map until the TTL expires.
    expect([...store.keys()]).toEqual([`fc:claims:shape:${COMMUNITY}`]);

    const second = await request(app).get(shapeUrl());
    expect(second.body).toEqual(first.body);
    expect(query.mock.calls).toHaveLength(1); // served from the cache, no second query
    expect(second.headers['cache-control']).toBe('public, max-age=0, s-maxage=30');
  });

  it('shares one cached body with a credentialed reader, since none of it depends on who asked', async () => {
    // The node routes refuse the shared cache for a credentialed request because a ClaimNode will
    // carry the caller's own rating. A ShapeNode has no caller-specific field, so there is one
    // body and one entry for everybody.
    query.mockResolvedValueOnce(rows(tree()));
    const anon = await request(app).get(shapeUrl());

    const auth = await request(app).get(shapeUrl()).set('Authorization', 'Bearer user');

    expect(auth.status).toBe(200);
    expect(auth.body).toEqual(anon.body);
    expect(query.mock.calls).toHaveLength(1);
    expect([...store.keys()]).toEqual([`fc:claims:shape:${COMMUNITY}`]);
  });

  it('does not collide with the node routes on a path or a cache key', async () => {
    // /communities/:id/claims/root and /communities/:id/claims/shape differ by a literal segment,
    // and `fc:claim:root:x` is not `fc:claims:shape:x` — neither route can serve the other's body.
    mockNode({ claim: row() });
    const root = await request(app).get(`/fc/api/communities/${COMMUNITY}/claims/root`);
    expect(root.body.data.claim.id).toBe(ROOT);

    query.mockResolvedValueOnce(rows(tree()));
    const shape = await request(app).get(shapeUrl());
    expect(shape.body.data).toHaveLength(4);
    expect([...store.keys()].sort()).toEqual(
      [
        `fc:claim:root:${COMMUNITY}:{"limit":20,"supports":null,"opposes":null}`,
        `fc:claims:shape:${COMMUNITY}`,
      ].sort()
    );
  });
});

// ── The privacy wall's table list ──────────────────────────────────────────────────────────

describe('config/database.ts privacy wall', () => {
  it('names every connect table the module actually reads or writes', () => {
    // 🔴 THAT PARAGRAPH IS THE ONE A REVIEWER READS TO DECIDE WHETHER A NEW QUERY IS IN SCOPE.
    // It said "ONLY the five connect tables" and listed them long after CA_0341 added three
    // more with real grants — so the wall a future reader was measuring against had three
    // holes in it that were not holes at all, and the next genuine widening would have looked
    // exactly the same. A list that is wrong is worse than no list, because it is trusted.
    //
    // The scan reads the tables out of the SQL rather than out of a second list: anything
    // after FROM, JOIN, INTO or UPDATE, minus the `connect.fn(...)` calls, which a following
    // `(` tells apart from a relation.
    const dir = new URL('./', import.meta.url);
    const walk = (d: URL): URL[] =>
      readdirSync(d, { withFileTypes: true }).flatMap((e) =>
        e.isDirectory()
          ? walk(new URL(`${e.name}/`, d))
          : e.name.endsWith('.ts') && !e.name.endsWith('.test.ts')
            ? [new URL(e.name, d)]
            : []
      );

    const tables = new Set<string>();
    for (const file of walk(dir)) {
      const source = readFileSync(file, 'utf8');
      for (const m of source.matchAll(/\b(?:FROM|JOIN|INTO|UPDATE)\s+connect\.([a-z_]+)(?![a-z_(])/gi)) {
        tables.add((m[1] as string).toLowerCase());
      }
    }

    // A guard on the scan itself: if the regex ever stops matching, an empty set would make
    // the assertion below pass by accident.
    expect(tables.size).toBeGreaterThanOrEqual(8);
    expect(tables).toContain('claims');
    expect(tables).toContain('claim_ratings');
    expect(tables).toContain('claim_edits');

    const config = readFileSync(new URL('./config/database.ts', import.meta.url), 'utf8');
    const wall = config.slice(config.indexOf('PRIVACY WALL'), config.indexOf('const { Pool }'));
    expect(wall.length).toBeGreaterThan(0);
    for (const table of tables) {
      expect(wall, `the privacy wall paragraph does not name connect.${table}`).toContain(table);
    }
  });
});
