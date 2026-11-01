import { describe, it, expect, vi, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// ── Mocks ────────────────────────────────────────────────────────────────────────────────
// The pool is a queue of canned results; every test asserts the SQL it expects to run.
const query = vi.fn();
/**
 * The claim edit and the three curation routes check a client OUT of the pool (set_config and
 * the writes have to share one transaction). Its `query` is the SAME spy, so every assertion
 * below reads one ordered list of statements — including the invalidation middleware's own
 * read-back, which runs on the pool after the transaction has closed.
 */
const release = vi.fn();
vi.mock('./config/database.js', () => ({
  pool: {
    query: (...a: unknown[]) => query(...a),
    connect: async () => ({ query: (...a: unknown[]) => query(...a), release }),
  },
}));

const store = new Map<string, unknown>();
/** Flipped by the one test that proves a cache that cannot be reached does not fail a write. */
let delThrows = false;
vi.mock('../lib/cache.js', () => ({
  cache: {
    get: async (k: string) => (store.has(k) ? store.get(k) : null),
    set: async (k: string, v: unknown) => { store.set(k, v); },
    // Synchronous on purpose: cacheDel attaches its own .catch to each del, so a rejected
    // promise is swallowed there and never reaches the caller. A throw is how a failure gets
    // past it, which is the failure the middleware's own catch has to survive.
    del: (k: string) => {
      if (delThrows) throw new Error('upstash unreachable');
      store.delete(k);
      return Promise.resolve();
    },
  },
}));

// The engine's optionalAuth, reduced to a guest: the seasons route only needs a predicate here.
// roleService's own dependency on supabase.js process.exit()s without env vars, so stub it.
vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, adminRpc: async () => ({ data: [], error: null }) }));
/** A role grant shaped like UserRoleGrant, so the REAL checkRole runs against it. */
const grant = (slug: string) => ({
  id: 'g1', role_id: 'r1', slug, name: slug, granted_at: '2026-01-01T00:00:00+00:00',
  feature_scope: 'connect', jurisdiction_geoid: null, resource_id: null, granted_by_display_name: null,
});
/** Curation is authorised by role; the tests that curate turn this on. */
let callerIsMaven = false;
vi.mock('../lib/roleService.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../lib/roleService.js')>()),
  getCachedUserRoles: async () => (callerIsMaven ? [grant('maven')] : []),
}));

// The admin half of the curation guard. Never reached by a maven (the guard short-circuits),
// but the real one reads public.admin_users through supabaseAdmin, which is stubbed to {}.
vi.mock('../middleware/requireAdmin.js', () => ({
  requireAdmin: async (_req: express.Request, res: express.Response, _next: express.NextFunction) => {
    res.status(403).json({ error: 'Admin access required' });
  },
}));

// The engine's requireAuth, reduced to the three outcomes the module depends on.
vi.mock('../middleware/auth.js', () => ({
  optionalAuth: async (_req: express.Request, _res: express.Response, next: express.NextFunction) => { next(); },
  requireAuth: async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const h = req.headers.authorization;
    if (!h) { res.status(401).json({ error: 'Missing authorization header' }); return; }
    // The one way to get an UNCAUGHT error out of a mounted router: every handler in the module
    // catches its own. The error-handler-is-last test needs one. See that test.
    if (h === 'Bearer boom') { throw new Error('verifier exploded'); }
    if (h === 'Bearer suspended') { res.status(403).json({ error: 'Account suspended' }); return; }
    Object.assign(req, { userId: h === 'Bearer inform' ? 'u-inform' : 'u1', accessToken: 'tok' });
    next();
  },
}));
vi.mock('../lib/accountMeService.js', () => ({
  getAccountMe: async (_t: string, userId: string) => ({
    id: 'should-be-overwritten',
    tier: userId === 'u-inform' ? 'inform' : 'connected',
    account_standing: 'active',
    completed_onboarding: true,
    display_name: 'Pseudonym',
  }),
}));

const limit = vi.fn(async (_id: string) => ({ success: true, reset: Date.now() + 1000 }));
vi.mock('./lib/rateLimit.js', () => ({
  postRateLimiter: { limit: (id: string) => limit(id) },
  ratingRateLimiter: { limit: (id: string) => limit(id) },
}));

const { focusedCommunitiesRouter } = await import('./app.js');
const { claimsRouter } = await import('./routes/claims.js');
const { claimWritesRouter } = await import('./routes/claimWrites.js');
const { claimCurationRouter } = await import('./routes/claimCuration.js');
const app = express();
app.use(express.json());
app.use(['/fc/api', '/api/fc'], focusedCommunitiesRouter);

const rows = (r: unknown[]) => ({ rows: r, rowCount: r.length });
const TS = '2026-04-17T12:00:00.123456+00:00';
const TS2 = '2026-04-18T12:00:00.654321+00:00';

beforeEach(() => {
  query.mockReset();
  release.mockReset();
  store.clear();
  limit.mockReset();
  limit.mockResolvedValue({ success: true, reset: Date.now() + 1000 });
  delThrows = false;
  callerIsMaven = false;
});

// ── Reads ────────────────────────────────────────────────────────────────────────────────
describe('GET /communities', () => {
  it('returns the { data, meta } envelope with camelCase fields and a cursor', async () => {
    query.mockResolvedValueOnce(rows([
      { id: 'c2', slug: 's2', name: 'B', description: null, member_count: 3, thread_count: 0, topic_id: null, slice_label: null, created_at: TS2 },
      { id: 'c1', slug: 's1', name: 'A', description: 'd', member_count: 1, thread_count: 1, topic_id: 't', slice_label: 'x', created_at: TS },
    ]));
    const res = await request(app).get('/fc/api/communities?limit=1');
    expect(res.status).toBe(200);
    expect(res.body.data).toEqual([{
      id: 'c2', slug: 's2', name: 'B', description: null, memberCount: 3, threadCount: 0,
      topicId: null, sliceLabel: null, createdAt: TS2,
    }]);
    expect(res.body.meta.hasMore).toBe(true);
    // Cursor carries the full-precision PostgREST timestamp, not a millisecond Date.
    const decoded = JSON.parse(Buffer.from(res.body.meta.cursor, 'base64url').toString('utf8'));
    expect(decoded).toEqual({ t: TS2, id: 'c2' });
    const [sql, params] = query.mock.calls[0];
    expect(sql).toContain("to_json(created_at) #>> '{}' AS created_at");
    expect(sql).toContain('ORDER BY created_at DESC, id DESC');
    expect(params).toEqual([2]);
  });

  it('passes search text and cursor as parameters, never into the SQL', async () => {
    query.mockResolvedValueOnce(rows([]));
    const cursor = Buffer.from(JSON.stringify({ t: '5', id: 'c9' })).toString('base64url');
    await request(app).get(`/fc/api/communities?sort=popular&q=${encodeURIComponent("x'; drop")}&cursor=${cursor}`);
    const [sql, params] = query.mock.calls[0];
    expect(sql).not.toContain('drop');
    expect(sql).toContain('member_count < $2::int');
    expect(sql).toContain('ORDER BY member_count DESC, id DESC');
    expect(params).toEqual(["x'; drop", '5', 'c9', 41]);
  });
});

describe('GET /communities/:id and /by-slug/:slug', () => {
  it('returns 404 envelope when not found, and when the id is malformed', async () => {
    query.mockResolvedValueOnce(rows([]));
    let res = await request(app).get('/fc/api/communities/missing-a');
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: { code: 'COMMUNITY_NOT_FOUND', message: 'Community not found' } });

    query.mockRejectedValueOnce(Object.assign(new Error('invalid input syntax for type uuid'), { code: '22P02' }));
    res = await request(app).get('/fc/api/communities/missing-b');
    expect(res.status).toBe(404);
  });

  it('falls back to slug history when the slug was renamed', async () => {
    query
      .mockResolvedValueOnce(rows([]))
      .mockResolvedValueOnce(rows([{ id: 'c1', slug: 'new', name: 'A', description: null, member_count: 0, thread_count: 0, topic_id: null, slice_label: null, created_at: TS }]));
    const res = await request(app).get('/api/fc/communities/by-slug/old');
    expect(res.status).toBe(200);
    expect(res.body.data.slug).toBe('new');
    expect(query.mock.calls[1][0]).toContain('slug_history @> ARRAY[$1]::text[]');
    expect(query.mock.calls[1][1]).toEqual(['old']);
  });
});

describe('GET /communities/:id/stances', () => {
  it('maps stance rows and defaults null fields', async () => {
    query
      .mockResolvedValueOnce(rows([{ '?column?': 1 }]))
      .mockResolvedValueOnce(rows([{ position: 1, text: 'T', supporting_points: null, description: null, example_perspectives: null }]));
    const res = await request(app).get('/fc/api/communities/c1/stances');
    expect(res.body).toEqual({ data: [{ text: 'T', supportingPoints: [], description: '', examplePerspectives: [] }] });
    expect(query.mock.calls[1][0]).toContain('connect.get_stances_for_community($1)');
    expect(query.mock.calls[1][0]).toContain('ORDER BY position ASC');
  });

  it('never serializes position in the response body', async () => {
    query
      .mockResolvedValueOnce(rows([{ '?column?': 1 }]))
      .mockResolvedValueOnce(rows([
        { position: 1, text: 'A', supporting_points: null, description: null, example_perspectives: null },
        { position: 2, text: 'B', supporting_points: null, description: null, example_perspectives: null },
      ]));
    const res = await request(app).get('/fc/api/communities/c1/stances');
    expect(res.text).not.toContain('"position"');
    for (const s of res.body.data) expect(Object.keys(s)).not.toContain('position');
    expect(res.body.data.map((s: { text: string }) => s.text)).toEqual(['A', 'B']);
  });

  it('returns 404 when the community does not exist', async () => {
    query.mockResolvedValueOnce(rows([]));
    const res = await request(app).get('/fc/api/communities/c404/stances');
    expect(res.status).toBe(404);
    expect(query).toHaveBeenCalledTimes(1);
  });
});

describe('threads and posts (reads)', () => {
  it('lists threads with an excerpt, not the body', async () => {
    query.mockResolvedValueOnce(rows([{ id: 't1', title: 'Title', body: '**Bold** body', author_display_name: 'P', reply_count: 2, created_at: TS, last_activity_at: TS2 }]));
    const res = await request(app).get('/fc/api/communities/c1/threads');
    expect(res.body.data[0]).toEqual({ id: 't1', title: 'Title', excerpt: 'Bold body', authorPseudonym: 'P', replyCount: 2, createdAt: TS, lastActivityAt: TS2 });
    expect(res.body.meta).toEqual({ cursor: null, hasMore: false });
    expect(query.mock.calls[0][0]).toContain("moderation_status = 'visible'");
  });

  it('hides a thread that is not visible (404, existence not revealed)', async () => {
    query.mockResolvedValueOnce(rows([{ id: 't1', title: 'x', body: 'y', author_display_name: 'P', reply_count: 0, created_at: TS, last_activity_at: TS, updated_at: TS, moderation_status: 'hidden' }]));
    const res = await request(app).get('/fc/api/threads/t-hidden');
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('THREAD_NOT_FOUND');
  });

  it('returns full thread body with isEdited from the timestamps', async () => {
    query.mockResolvedValueOnce(rows([{ id: 't1', title: 'x', body: '# raw', author_display_name: 'P', reply_count: 0, created_at: TS, last_activity_at: TS, updated_at: TS2, moderation_status: 'visible' }]));
    const res = await request(app).get('/fc/api/threads/t-edited');
    expect(res.body.data.body).toBe('# raw');
    expect(res.body.data.isEdited).toBe(true);
    expect(res.body.data).not.toHaveProperty('moderationStatus');
  });

  it('lists visible posts in order', async () => {
    query
      .mockResolvedValueOnce(rows([{ moderation_status: 'visible' }]))
      .mockResolvedValueOnce(rows([{ id: 'p1', author_display_name: 'P', body: 'hello', created_at: TS, updated_at: TS }]));
    const res = await request(app).get('/fc/api/threads/t-posts/posts');
    expect(res.body).toEqual({ data: [{ id: 'p1', authorPseudonym: 'P', body: 'hello', createdAt: TS, updatedAt: TS, isEdited: false }] });
    expect(query.mock.calls[1][0]).toContain('ORDER BY created_at ASC');
  });

  it('serves public edit history', async () => {
    query
      .mockResolvedValueOnce(rows([{ moderation_status: 'visible' }]))
      .mockResolvedValueOnce(rows([{ id: 'e1', old_title: 'old', old_body: 'b', edited_at: TS }]));
    const res = await request(app).get('/fc/api/threads/t1/edits');
    expect(res.body).toEqual({ data: [{ id: 'e1', oldTitle: 'old', oldBody: 'b', editedAt: TS }] });
  });
});

// ── Writes ───────────────────────────────────────────────────────────────────────────────
const created = { id: 't9', title: 'Hello world', body: 'A body of text', author_display_name: 'Pseudonym', reply_count: 0, created_at: TS, last_activity_at: TS, updated_at: TS };

describe('POST /communities/:id/threads', () => {
  it('creates a thread as the verified user and returns 201', async () => {
    query.mockResolvedValueOnce(rows([created]));
    const res = await request(app).post('/fc/api/communities/c1/threads')
      .set('Authorization', 'Bearer good').send({ title: '  Hello world ', body: 'A body of text' });
    expect(res.status).toBe(201);
    expect(res.body.data).toEqual({
      id: 't9', title: 'Hello world', body: 'A body of text', authorPseudonym: 'Pseudonym',
      replyCount: 0, createdAt: TS, lastActivityAt: TS, updatedAt: TS, isEdited: false,
    });
    expect(query.mock.calls[0][1]).toEqual(['c1', 'u1', 'Hello world', 'A body of text']);
    expect(limit).toHaveBeenCalledWith('u1');
    expect(res.headers['cache-control']).toBe('private, no-store');
  });

  it('rejects short fields with 422 before touching the database', async () => {
    const res = await request(app).post('/fc/api/communities/c1/threads')
      .set('Authorization', 'Bearer good').send({ title: 'Hi', body: 'short' });
    expect(res.status).toBe(422);
    expect(Object.keys(res.body.errors).sort()).toEqual(['body', 'title']);
    expect(query).not.toHaveBeenCalled();
  });

  it('401 without a token', async () => {
    const res = await request(app).post('/fc/api/communities/c1/threads').send({ title: 'Hello world', body: 'A body of text' });
    expect(res.status).toBe(401);
  });

  it('403 with reason "suspended" for a suspended account (the frontend keys on reason)', async () => {
    const res = await request(app).post('/fc/api/communities/c1/threads')
      .set('Authorization', 'Bearer suspended').send({ title: 'Hello world', body: 'A body of text' });
    expect(res.status).toBe(403);
    expect(res.body).toEqual({ error: 'Account suspended', reason: 'suspended' });
  });

  it('403 with reason "tier" for an Inform account', async () => {
    const res = await request(app).post('/fc/api/communities/c1/threads')
      .set('Authorization', 'Bearer inform').send({ title: 'Hello world', body: 'A body of text' });
    expect(res.status).toBe(403);
    expect(res.body.reason).toBe('tier');
  });

  it('429 with Retry-After when rate limited', async () => {
    limit.mockResolvedValueOnce({ success: false, reset: Date.now() + 30_000 });
    const res = await request(app).post('/fc/api/communities/c1/threads')
      .set('Authorization', 'Bearer good').send({ title: 'Hello world', body: 'A body of text' });
    expect(res.status).toBe(429);
    expect(res.body).toEqual({ reason: 'rate_limited' });
    expect(Number(res.headers['retry-after'])).toBeGreaterThan(0);
  });
});

describe('POST /threads/:id/posts', () => {
  it('creates a reply, bumps reply_count atomically, and invalidates the caches', async () => {
    store.set(`fc:/threads/t1:${JSON.stringify({})}`, 'stale');
    store.set(`fc:/threads/t1/posts:${JSON.stringify({})}`, 'stale');
    query
      .mockResolvedValueOnce(rows([{ moderation_status: 'visible' }]))
      .mockResolvedValueOnce(rows([{ id: 'p9', body: 'a reply', author_display_name: 'Pseudonym', created_at: TS, updated_at: TS }]))
      .mockResolvedValueOnce(rows([]));
    const res = await request(app).post('/fc/api/threads/t1/posts')
      .set('Authorization', 'Bearer good').send({ body: 'a reply' });
    expect(res.status).toBe(201);
    expect(res.body.data).toEqual({ id: 'p9', body: 'a reply', authorPseudonym: 'Pseudonym', createdAt: TS, updatedAt: TS, isEdited: false });
    expect(query.mock.calls[2][0]).toContain('reply_count = reply_count + 1');
    expect(store.size).toBe(0);
  });

  it('404 when the thread is missing', async () => {
    query.mockResolvedValueOnce(rows([]));
    const res = await request(app).post('/fc/api/threads/t404/posts')
      .set('Authorization', 'Bearer good').send({ body: 'a reply' });
    expect(res.status).toBe(404);
  });
});

describe('PATCH ownership', () => {
  it('returns 404, not 403, when a non-author edits a thread', async () => {
    query.mockResolvedValueOnce(rows([{ author_id: 'someone-else', moderation_status: 'visible' }]));
    const res = await request(app).patch('/fc/api/threads/t1')
      .set('Authorization', 'Bearer good').send({ title: 'New title here' });
    expect(res.status).toBe(404);
    expect(query).toHaveBeenCalledTimes(1);
  });

  it('updates only the fields provided', async () => {
    query
      .mockResolvedValueOnce(rows([{ author_id: 'u1', moderation_status: 'visible' }]))
      .mockResolvedValueOnce(rows([{ ...created, title: 'New title here', updated_at: TS2 }]));
    const res = await request(app).patch('/fc/api/threads/t1')
      .set('Authorization', 'Bearer good').send({ title: 'New title here' });
    expect(res.status).toBe(200);
    expect(res.body.data.isEdited).toBe(true);
    const [sql, params] = query.mock.calls[1];
    expect(sql).toMatch(/SET title = \$1, updated_at = \$2 WHERE id = \$3/);
    expect(params[0]).toBe('New title here');
    expect(params[2]).toBe('t1');
  });

  it('edits a post body for its author', async () => {
    query
      .mockResolvedValueOnce(rows([{ author_id: 'u1', thread_id: 't1', moderation_status: 'visible' }]))
      .mockResolvedValueOnce(rows([{ id: 'p1', body: 'new body', author_display_name: 'P', created_at: TS, updated_at: TS2 }]));
    const res = await request(app).patch('/fc/api/posts/p1')
      .set('Authorization', 'Bearer good').send({ body: 'new body' });
    expect(res.status).toBe(200);
    expect(res.body.data).toEqual({ id: 'p1', body: 'new body', authorPseudonym: 'P', createdAt: TS, updatedAt: TS2, isEdited: true });
  });
});

describe('deletes are refused (Memory over Moderation)', () => {
  it('405 on threads and posts', async () => {
    for (const path of ['/fc/api/threads/t1', '/fc/api/posts/p1']) {
      const res = await request(app).delete(path);
      expect(res.status).toBe(405);
      expect(res.headers.allow).toBe('GET, PATCH');
    }
    expect(query).not.toHaveBeenCalled();
  });
});

describe('GET /users/:id/posts', () => {
  it('is self-only', async () => {
    const res = await request(app).get('/fc/api/users/someone-else/posts').set('Authorization', 'Bearer good');
    expect(res.status).toBe(403);
    expect(query).not.toHaveBeenCalled();
  });

  it('returns post history joined to thread and community', async () => {
    query.mockResolvedValueOnce(rows([{
      id: 'p1', body: 'hello there', author_display_name: 'P', created_at: TS, updated_at: TS,
      thread_id: 't1', thread_title: 'T', community_id: 'c1', community_name: 'C', community_slug: 'c',
    }]));
    const res = await request(app).get('/fc/api/users/u1/posts').set('Authorization', 'Bearer good');
    expect(res.body.data).toEqual([{
      postId: 'p1', threadId: 't1', threadTitle: 'T', communityId: 'c1', communityName: 'C', communitySlug: 'c',
      postExcerpt: 'hello there', createdAt: TS, isEdited: false, authorPseudonym: 'P',
    }]);
    expect(query.mock.calls[0][1]).toEqual(['u1', 21]);
  });
});

describe('seasons router is mounted', () => {
  it('serves GET /communities/:id/seasons as a 200 on the /fc/api mount', async () => {
    query
      .mockResolvedValueOnce(rows([{ topic_id: 't1' }]))
      .mockResolvedValueOnce(rows([{ season_number: 1, season_name: 'S1', status: 'open', opened_at: TS, closed_at: null }]));
    const res = await request(app).get('/fc/api/communities/c1/seasons');
    expect(res.status).toBe(200);
    expect(res.body.data).toEqual([{ number: 1, name: 'S1', status: 'open', openedAt: TS, closedAt: null }]);
    expect(res.body.meta.defaultSeason).toBe(1);
    expect(query.mock.calls[0][1]).toEqual(['c1']);
    expect(query.mock.calls[1][1]).toEqual(['t1', false]);
  });
});

describe('health', () => {
  it('answers on both mounts', async () => {
    for (const p of ['/fc/api/health', '/api/fc/health']) {
      const res = await request(app).get(p);
      expect(res.body.status).toBe('ok');
    }
  });
});

// ── The argument tree ────────────────────────────────────────────────────────────────────
//
// Task 8 mounted claimsRouter, claimWritesRouter and claimCurationRouter and wired the cache
// invalidation the hand-rolled entries in routes/claims.ts need. What follows pins the WIRING,
// not the routes: each of the three has its own suite, and duplicating those here would mean
// three copies of the same SQL assertions ageing at different rates.
//
// 🔴 NO CACHE KEY IS SPELLED OUT IN THIS FILE. Every test warms the entries by READING them
// through the routes that write them, then asserts they are gone. A hand-written expected key
// would agree with the delete and could still disagree with what the reader mints — which is
// the one failure the whole canonicalisation argument in routes/claims.ts is about.

/** Hex letters on purpose: a uuid of digits alone cannot catch a missing toLowerCase(). */
const COMMUNITY = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
const ROOT_CLAIM = 'b1f0cd88-8d1a-4fe7-ab5c-5cc8ac270b22';
const PARENT = 'c2f1de77-7e2b-4df6-9b4d-4dd7bd160c33';
const CLAIM = 'd3f2ef66-6f3c-4cf5-8c3e-3ee6ce050d44';
const DESCENDANT = 'e4f3f055-5a4d-4bf4-bd2f-2ff5df940e55';
const GRANDCHILD = '17a6b344-4d7a-4ae1-9c18-18c2eb610188';
const NEW_PARENT = 'f5f4f144-4b5e-4af3-ae1a-1aa4ef830f66';
const TARGET = '06f5f233-3c6f-49f2-bf09-09b3fa720077';

const CLAIM_BODY = 'The budget already covers the first two years.';

const shapeRow = (over: Record<string, unknown> = {}) => ({
  id: ROOT_CLAIM, parent_claim_id: null, side: 'supports', depth: 0,
  moderation_status: 'visible', merged_into_claim_id: null, impact: '5.0000', ...over,
});

/** A row as the node routes read it: the Claim columns plus path and community_id. */
const nodeRow = (id: string, path: string[]) => ({
  id, side: 'supports', body: CLAIM_BODY, author_display_name: 'Demo Finch',
  moderation_status: 'visible', impact: '5.0000', rating_count: 0,
  child_supports_count: 0, child_opposes_count: 0, merged_into_claim_id: null,
  created_at: TS, updated_at: TS, my_rating: null, path, community_id: COMMUNITY,
});

/** A row as a write's RETURNING hands it back. `path` and `depth` are for the curation sweep. */
const writtenRow = (id: string, over: Record<string, unknown> = {}) => ({
  id, side: 'supports', body: CLAIM_BODY, author_display_name: 'Demo Finch',
  moderation_status: 'visible', impact: '5.0000', rating_count: 0,
  child_supports_count: 0, child_opposes_count: 0, merged_into_claim_id: null,
  created_at: TS, updated_at: TS, my_rating: null, path: [ROOT_CLAIM, NEW_PARENT], depth: 2,
  ...over,
});

/** A row as the curation pre-read locks it. Depth 3 under PARENT, subtree two levels deeper. */
const lockedRow = (id: string, over: Record<string, unknown> = {}) => ({
  id, parent_claim_id: PARENT, community_id: COMMUNITY, depth: 3,
  moderation_status: 'visible', merged_into_claim_id: null,
  under_moving_claim: false, has_hidden_ancestor: false, deepest_descendant: 5, ...over,
});

/** What the invalidation middleware reads back after the write has committed. */
const lookedUp = (parent: string | null = PARENT) =>
  rows([{ community_id: COMMUNITY, parent_claim_id: parent }]);

/**
 * Fill the entries a claim write has to drop, by reading them through the routes that write
 * them: the community's shape map, its root node page, and one node page per id.
 */
async function warmTree(ids: readonly string[] = [CLAIM]): Promise<void> {
  query.mockResolvedValueOnce(rows([shapeRow()]));
  expect((await request(app).get(`/fc/api/communities/${COMMUNITY}/claims/shape`)).status).toBe(200);

  query
    .mockResolvedValueOnce(rows([nodeRow(ROOT_CLAIM, [])]))
    .mockResolvedValueOnce(rows([]))
    .mockResolvedValueOnce(rows([]));
  expect((await request(app).get(`/fc/api/communities/${COMMUNITY}/claims/root`)).status).toBe(200);

  for (const id of ids) {
    const ancestry = id === PARENT ? [ROOT_CLAIM] : [ROOT_CLAIM, PARENT];
    query
      .mockResolvedValueOnce(rows([nodeRow(id, ancestry)]))
      .mockResolvedValueOnce(rows(ancestry.map((a) => ({
        id: a, body: 'An ancestor.', side: a === ROOT_CLAIM ? null : 'supports',
        moderation_status: 'visible',
      }))))
      .mockResolvedValueOnce(rows([]))
      .mockResolvedValueOnce(rows([]));
    expect((await request(app).get(`/fc/api/claims/${id}`)).status).toBe(200);
  }

  expect(store.size).toBe(2 + ids.length);
  expect([...store.keys()].some((k) => k.startsWith('fc:claims:shape:'))).toBe(true);
  query.mockReset();
}

const shapeKeys = () => [...store.keys()].filter((k) => k.startsWith('fc:claims:shape:'));

// --- Mounting ---------------------------------------------------------------------------

describe('the claim routers are mounted', () => {
  it('serves reads, writes and curation on both mount points', async () => {
    query.mockResolvedValueOnce(rows([shapeRow()]));
    let res = await request(app).get(`/fc/api/communities/${COMMUNITY}/claims/shape`);
    expect(res.status).toBe(200);
    expect(res.body.data).toEqual([
      { id: ROOT_CLAIM, parentId: null, side: 'supports', depth: 0, impact: 5, isHidden: false, mergedInto: null },
    ]);

    query
      .mockResolvedValueOnce(rows([nodeRow(ROOT_CLAIM, [])]))
      .mockResolvedValueOnce(rows([]))
      .mockResolvedValueOnce(rows([]));
    res = await request(app).get(`/api/fc/claims/${ROOT_CLAIM}`);
    expect(res.status).toBe(200);
    expect(res.body.data.claim.id).toBe(ROOT_CLAIM);

    // claimWritesRouter: its own 405, not a 404 from a path nothing serves.
    res = await request(app).delete(`/api/fc/claims/${CLAIM}`);
    expect(res.status).toBe(405);
    expect(res.body.error.code).toBe('DELETE_NOT_ALLOWED');

    // claimCurationRouter: its guard answering, not a 404.
    res = await request(app).post(`/fc/api/claims/${CLAIM}/hide`).send({});
    expect(res.status).toBe(401);
    expect(query).toHaveBeenCalledTimes(4);
  });
});

describe('the module error handler stays last', () => {
  it('sits below every router in the stack, and is the only one', () => {
    const stack = (focusedCommunitiesRouter as unknown as { stack: { handle: unknown }[] }).stack;
    const handles = stack.map((l) => l.handle);
    const errorHandlers = handles.filter(
      (h): h is (...a: unknown[]) => unknown => typeof h === 'function' && h.length === 4
    );
    expect(errorHandlers).toHaveLength(1);
    expect(handles.indexOf(errorHandlers[0]!)).toBe(handles.length - 1);

    // ...and the three claim routers are above it, in read-then-write-then-curate order.
    const at = (r: unknown) => handles.indexOf(r);
    expect(at(claimsRouter)).toBeGreaterThan(-1);
    expect(at(claimsRouter)).toBeLessThan(at(claimWritesRouter));
    expect(at(claimWritesRouter)).toBeLessThan(at(claimCurationRouter));
    expect(at(claimCurationRouter)).toBeLessThan(handles.length - 1);
  });

  it('answers an error thrown inside the LAST router with the JSON envelope', async () => {
    // A router mounted below the error handler would get Express's own HTML default instead.
    const res = await request(app)
      .post(`/fc/api/claims/${CLAIM}/hide`)
      .set('Authorization', 'Bearer boom')
      .send({});
    expect(res.status).toBe(500);
    expect(res.body).toEqual({
      error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' },
    });
  });
});

// --- Invalidation -----------------------------------------------------------------------

describe('a claim write drops what it made stale', () => {
  it('on create: the shape map, the root page and the parent page', async () => {
    await warmTree();
    query
      .mockResolvedValueOnce(rows([{ moderation_status: 'visible', merged_into_claim_id: null, depth: 3, has_hidden_ancestor: false }]))
      .mockResolvedValueOnce(rows([writtenRow(DESCENDANT)]))
      .mockResolvedValueOnce(lookedUp());
    const res = await request(app).post(`/fc/api/claims/${CLAIM}/children`)
      .set('Authorization', 'Bearer good').send({ side: 'supports', body: CLAIM_BODY });
    expect(res.status).toBe(201);
    expect(shapeKeys()).toEqual([]);
    expect(store.size).toBe(0);
  });

  it('on rate — the rated claim AND the parent whose column orders by impact', async () => {
    await warmTree([CLAIM, PARENT]);
    query
      .mockResolvedValueOnce(rows([{ claim_id: CLAIM }]))
      .mockResolvedValueOnce(rows([{ impact: '6.2000', rating_count: 3 }]))
      .mockResolvedValueOnce(lookedUp());
    const res = await request(app).put(`/fc/api/claims/${CLAIM}/rating`)
      .set('Authorization', 'Bearer good').send({ value: 7 });
    expect(res.status).toBe(200);
    expect(shapeKeys()).toEqual([]);
    // PARENT's page was never named in the URL: it is dropped only because the read-back found
    // it. A new impact reorders its column, so a surviving entry would show the old order.
    expect(store.size).toBe(0);
  });

  it('on edit', async () => {
    await warmTree();
    query
      .mockResolvedValueOnce(rows([]))                        // BEGIN
      .mockResolvedValueOnce(rows([{ set_config: 'u1' }]))    // set_config
      .mockResolvedValueOnce(rows([writtenRow(CLAIM)]))       // the UPDATE
      .mockResolvedValueOnce(rows([]))                        // COMMIT
      .mockResolvedValueOnce(lookedUp());
    const res = await request(app).patch(`/fc/api/claims/${CLAIM}`)
      .set('Authorization', 'Bearer good').send({ body: 'A different sentence entirely.' });
    expect(res.status).toBe(200);
    expect(shapeKeys()).toEqual([]);
    expect(store.size).toBe(0);
  });

  it('on move — including every descendant the sweep re-pathed', async () => {
    callerIsMaven = true;
    await warmTree([CLAIM, DESCENDANT]);
    query
      .mockResolvedValueOnce(rows([]))                                      // BEGIN
      .mockResolvedValueOnce(rows([{ set_config: 'u1' }]))                  // set_config
      .mockResolvedValueOnce(rows([lockedRow(CLAIM), lockedRow(NEW_PARENT, { parent_claim_id: ROOT_CLAIM, depth: 2 })]))
      .mockResolvedValueOnce(rows([writtenRow(CLAIM)]))                     // the claim's own UPDATE
      .mockResolvedValueOnce(rows([{ id: DESCENDANT }]))                    // the sweep, RETURNING id
      .mockResolvedValueOnce(rows([]))                                      // COMMIT
      .mockResolvedValueOnce(lookedUp(NEW_PARENT));
    const res = await request(app).post(`/fc/api/claims/${CLAIM}/move`)
      .set('Authorization', 'Bearer maven').send({ newParentId: NEW_PARENT, side: 'supports' });
    expect(res.status).toBe(200);
    // The sweep's RETURNING is READ: without it DESCENDANT's page would survive with a
    // breadcrumb naming ancestors it no longer has.
    const sweep = query.mock.calls.map((c) => String(c[0])).find((s) => /^\s*UPDATE connect\.claims d/.test(s));
    expect(sweep).toMatch(/RETURNING\s+d\.id/);
    expect(store.size).toBe(0);
  });

  it('on merge — the re-parented children AND what the sweep moved beneath them', async () => {
    callerIsMaven = true;
    await warmTree([CLAIM, DESCENDANT, GRANDCHILD]);
    query
      .mockResolvedValueOnce(rows([]))                                      // BEGIN
      .mockResolvedValueOnce(rows([{ set_config: 'u1' }]))                  // set_config
      .mockResolvedValueOnce(rows([lockedRow(CLAIM), lockedRow(TARGET, { parent_claim_id: ROOT_CLAIM, depth: 2 })]))
      .mockResolvedValueOnce(rows([{ reaches_claim: false, hops: 1 }]))     // the merge-chain walk
      .mockResolvedValueOnce(rows([{ id: DESCENDANT, path: [ROOT_CLAIM, TARGET], depth: 3 }]))
      .mockResolvedValueOnce(rows([{ id: GRANDCHILD }]))                    // the sweep, RETURNING id
      .mockResolvedValueOnce(rows([writtenRow(CLAIM, { merged_into_claim_id: TARGET })]))
      .mockResolvedValueOnce(rows([]))                                      // COMMIT
      .mockResolvedValueOnce(lookedUp());
    const res = await request(app).post(`/fc/api/claims/${CLAIM}/merge`)
      .set('Authorization', 'Bearer maven').send({ targetClaimId: TARGET });
    expect(res.status).toBe(200);
    // The children came back from their own UPDATE; everything below them came back from the
    // sweep. Both lists are read, and both pages are dropped.
    expect(store.size).toBe(0);
  });

  it('on hide', async () => {
    callerIsMaven = true;
    await warmTree();
    query
      .mockResolvedValueOnce(rows([]))                                      // BEGIN
      .mockResolvedValueOnce(rows([{ set_config: 'u1' }]))                  // set_config
      .mockResolvedValueOnce(rows([{ id: CLAIM, parent_claim_id: PARENT, moderation_status: 'visible' }]))
      .mockResolvedValueOnce(rows([writtenRow(CLAIM, { moderation_status: 'hidden' })]))
      .mockResolvedValueOnce(rows([]))                                      // COMMIT
      .mockResolvedValueOnce(lookedUp());
    const res = await request(app).post(`/fc/api/claims/${CLAIM}/hide`)
      .set('Authorization', 'Bearer maven').send({});
    expect(res.status).toBe(200);
    expect(shapeKeys()).toEqual([]);
    expect(store.size).toBe(0);
  });
});

describe('invalidation keeps the read side honest', () => {
  it('deletes the lower-case key when the route param arrives in mixed case', async () => {
    callerIsMaven = true;
    await warmTree();                       // warmed through a lower-case read
    const mixed = CLAIM.toUpperCase();
    expect(mixed).not.toBe(CLAIM);          // the ids carry hex letters, so this is a real test
    query
      .mockResolvedValueOnce(rows([]))
      .mockResolvedValueOnce(rows([{ set_config: 'u1' }]))
      .mockResolvedValueOnce(rows([{ id: CLAIM, parent_claim_id: PARENT, moderation_status: 'visible' }]))
      .mockResolvedValueOnce(rows([writtenRow(CLAIM, { moderation_status: 'hidden' })]))
      .mockResolvedValueOnce(rows([]))
      .mockResolvedValueOnce(lookedUp());
    const res = await request(app).post(`/fc/api/claims/${mixed}/hide`)
      .set('Authorization', 'Bearer maven').send({});
    expect(res.status).toBe(200);
    // The claim lookup was made with the canonical id too, not the spelling the URL carried.
    expect(query.mock.calls[2]![1]).toEqual([CLAIM]);
    expect(store.size).toBe(0);
  });

  it('survives a cache that cannot be reached, and says so', async () => {
    callerIsMaven = true;
    await warmTree();
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {});
    delThrows = true;
    query
      .mockResolvedValueOnce(rows([]))
      .mockResolvedValueOnce(rows([{ set_config: 'u1' }]))
      .mockResolvedValueOnce(rows([{ id: CLAIM, parent_claim_id: PARENT, moderation_status: 'visible' }]))
      .mockResolvedValueOnce(rows([writtenRow(CLAIM, { moderation_status: 'hidden' })]))
      .mockResolvedValueOnce(rows([]))
      .mockResolvedValueOnce(lookedUp());
    const res = await request(app).post(`/fc/api/claims/${CLAIM}/hide`)
      .set('Authorization', 'Bearer maven').send({});
    // The write COMMITTED. A cache that is down may not turn that into a 500.
    expect(res.status).toBe(200);
    expect(res.body.data.isHidden).toBe(true);
    expect(store.size).toBe(3);             // nothing was dropped, and nothing pretended it was
    expect(warn.mock.calls.flat().join(' ')).toContain('claim cache invalidation');
    warn.mockRestore();
  });

  it('leaves the cache alone for a read, and for a write that was refused', async () => {
    await warmTree();
    const before = [...store.keys()].sort();

    query
      .mockResolvedValueOnce(rows([nodeRow(CLAIM, [])]))
      .mockResolvedValueOnce(rows([]))
      .mockResolvedValueOnce(rows([]));
    expect((await request(app).get(`/fc/api/claims/${CLAIM}`)).status).toBe(200);

    // 404: the parent is gone, so nothing was written and nothing may be dropped.
    query.mockResolvedValueOnce(rows([]));
    const res = await request(app).post(`/fc/api/claims/${CLAIM}/children`)
      .set('Authorization', 'Bearer good').send({ side: 'supports', body: CLAIM_BODY });
    expect(res.status).toBe(404);
    expect([...store.keys()].sort()).toEqual(before);
  });
});
