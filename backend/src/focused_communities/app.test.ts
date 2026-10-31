import { describe, it, expect, vi, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// ── Mocks ────────────────────────────────────────────────────────────────────────────────
// The pool is a queue of canned results; every test asserts the SQL it expects to run.
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

// The engine's requireAuth, reduced to the three outcomes the module depends on.
vi.mock('../middleware/auth.js', () => ({
  requireAuth: async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const h = req.headers.authorization;
    if (!h) { res.status(401).json({ error: 'Missing authorization header' }); return; }
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
vi.mock('./lib/rateLimit.js', () => ({ postRateLimiter: { limit: (id: string) => limit(id) } }));

const { focusedCommunitiesRouter } = await import('./app.js');
const app = express();
app.use(express.json());
app.use(['/fc/api', '/api/fc'], focusedCommunitiesRouter);

const rows = (r: unknown[]) => ({ rows: r, rowCount: r.length });
const TS = '2026-04-17T12:00:00.123456+00:00';
const TS2 = '2026-04-18T12:00:00.654321+00:00';

beforeEach(() => {
  query.mockReset();
  store.clear();
  limit.mockReset();
  limit.mockResolvedValue({ success: true, reset: Date.now() + 1000 });
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

describe('health', () => {
  it('answers on both mounts', async () => {
    for (const p of ['/fc/api/health', '/api/fc/health']) {
      const res = await request(app).get(p);
      expect(res.body.status).toBe('ok');
    }
  });
});
