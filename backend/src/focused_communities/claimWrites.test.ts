import { describe, it, expect, vi, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// ── Mocks ────────────────────────────────────────────────────────────────────────────────
// The pool is a queue of canned results; every test asserts the SQL it expects to run. No test
// in here needs a live database — the route's contract with Postgres is "what it sends and what
// it does with what comes back", and both are visible in these calls.
const query = vi.fn();
vi.mock('./config/database.js', () => ({ pool: { query: (...a: unknown[]) => query(...a) } }));

// The engine's requireAuth, reduced to the outcomes this route depends on (as app.test.ts does).
vi.mock('../middleware/auth.js', () => ({
  requireAuth: async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const h = req.headers.authorization;
    if (!h) { res.status(401).json({ error: 'Missing authorization header' }); return; }
    Object.assign(req, { userId: h === 'Bearer inform' ? 'u-inform' : AUTHOR, accessToken: 'tok' });
    next();
  },
}));
vi.mock('../lib/accountMeService.js', () => ({
  getAccountMe: async (_t: string, userId: string) => ({
    id: 'should-be-overwritten',
    tier: userId === 'u-inform' ? 'inform' : 'connected',
    account_standing: 'active',
    completed_onboarding: true,
    // The legal name is never in play: author_display_name is snapshotted by a BEFORE INSERT
    // trigger from author_id, so nothing the route can see reaches the row.
    display_name: 'Abraham Lincoln',
  }),
}));

const limit = vi.fn(async (_id: string) => ({ success: true, reset: Date.now() + 1000 }));
vi.mock('./lib/rateLimit.js', () => ({ postRateLimiter: { limit: (id: string) => limit(id) } }));

const { claimWritesRouter } = await import('./routes/claimWrites.js');
const app = express();
app.use(express.json());
app.use('/fc/api', claimWritesRouter);

const rows = (r: unknown[]) => ({ rows: r, rowCount: r.length });
const TS = '2026-04-17T12:00:00.123456+00:00';

/** A canonical uuid. The route refuses anything else before it reaches the database. */
const uuid = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const PARENT = uuid(100);
const CHILD = uuid(101);
const AUTHOR = uuid(7);

const AUTH = ['Authorization', 'Bearer connected'] as const;
const BODY = 'The budget already covers the first two years.';

/** A claims row as RETURNING hands it back (snake_case, ts() text timestamps). */
const inserted = (over: Record<string, unknown> = {}) => ({
  id: CHILD,
  side: 'supports',
  body: BODY,
  author_display_name: 'Demo Finch',
  moderation_status: 'visible',
  child_supports_count: 0,
  child_opposes_count: 0,
  merged_into_claim_id: null,
  created_at: TS,
  updated_at: TS,
  ...over,
});

/** Queue the two queries a successful create runs: the parent lookup, then the insert. */
function mockCreate(over: Record<string, unknown> = {}, parent: Record<string, unknown> | null = { id: PARENT, moderation_status: 'visible' }) {
  query.mockResolvedValueOnce(rows(parent ? [parent] : []));
  if (parent) query.mockResolvedValueOnce(rows([inserted(over)]));
}

const post = (parentId = PARENT, body: unknown = { side: 'supports', body: BODY }) =>
  request(app).post(`/fc/api/claims/${parentId}/children`).set(...AUTH).send(body as object);

const insertCall = () => query.mock.calls.find((c) => String(c[0]).includes('INSERT'))!;
const insertSql = () => String(insertCall()[0]);

beforeEach(() => {
  query.mockReset();
  limit.mockReset();
  limit.mockResolvedValue({ success: true, reset: Date.now() + 1000 });
});

describe('POST /claims/:parentId/children', () => {
  it('creates a child and derives path and depth from the parent', async () => {
    mockCreate();

    const res = await post();

    expect(res.status).toBe(201);
    expect(res.body.data.id).toBe(CHILD);

    // 🔴 The whole point of this test: path, depth and community_id are NOT inputs. The
    // BEFORE INSERT trigger connect.derive_claim_position reads them off the parent under
    // FOR UPDATE and discards whatever the caller supplied. A route that sent them would be
    // lying about what decides them — and would race a concurrent curation move of the parent.
    const [sql, params] = insertCall();
    expect(String(sql)).not.toMatch(/\bpath\b/);
    expect(String(sql)).not.toMatch(/\bdepth\b/);
    expect(String(sql)).not.toMatch(/community_id/);
    expect(String(sql)).toContain('INSERT INTO connect.claims (parent_claim_id, side, body, author_id)');
    expect(params).toEqual([PARENT, 'supports', BODY, AUTHOR]);
  });

  it('requires a connected account', async () => {
    const res = await request(app)
      .post(`/fc/api/claims/${PARENT}/children`)
      .set('Authorization', 'Bearer inform')
      .send({ side: 'supports', body: BODY });

    expect(res.status).toBe(403);
    expect(res.body.reason).toBe('tier');
    expect(query).not.toHaveBeenCalled();
    expect(limit).not.toHaveBeenCalled();
  });

  it('requires a signed-in caller at all', async () => {
    const res = await request(app)
      .post(`/fc/api/claims/${PARENT}/children`)
      .send({ side: 'supports', body: BODY });

    expect(res.status).toBe(401);
    expect(query).not.toHaveBeenCalled();
  });

  it('rejects a missing or invalid side', async () => {
    for (const side of [undefined, null, '', 'Supports', 'SUPPORTS', ' supports', 'neutral', 1, true, ['supports']]) {
      query.mockReset();
      const res = await post(PARENT, { side, body: BODY });
      expect(res.status, `side=${JSON.stringify(side)}`).toBe(400);
      expect(res.body.error.code).toBe('INVALID_SIDE');
      expect(query).not.toHaveBeenCalled();
    }
  });

  it('accepts exactly the two sides and nothing else', async () => {
    for (const side of ['supports', 'opposes'] as const) {
      query.mockReset();
      mockCreate({ side });
      const res = await post(PARENT, { side, body: BODY });
      expect(res.status).toBe(201);
      expect(res.body.data.side).toBe(side);
    }
  });

  it('rejects a blank or oversized body', async () => {
    for (const body of [undefined, '', '   ', 'x', 42, 'y'.repeat(1001)]) {
      query.mockReset();
      const res = await post(PARENT, { side: 'supports', body });
      expect(res.status, `body=${JSON.stringify(body)?.slice(0, 20)}`).toBe(400);
      expect(res.body.error.code).toBe('INVALID_BODY');
      expect(query).not.toHaveBeenCalled();
    }
  });

  it('validates before consuming rate limit quota', async () => {
    await post(PARENT, { side: 'nonsense', body: BODY });
    expect(limit).not.toHaveBeenCalled();

    await post(PARENT, { side: 'supports', body: '' });
    expect(limit).not.toHaveBeenCalled();

    await post('not-a-uuid');
    expect(limit).not.toHaveBeenCalled();
  });

  it('404s when the parent is hidden or absent', async () => {
    // Absent.
    query.mockResolvedValueOnce(rows([]));
    let res = await post();
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' } });
    expect(insertSqlWasRun()).toBe(false);

    // Hidden — indistinguishable from absent. Never 403: which claims exist, and which have
    // been withdrawn, is not something a status code should teach.
    query.mockReset();
    query.mockResolvedValueOnce(rows([{ id: PARENT, moderation_status: 'hidden' }]));
    res = await post();
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' } });
    expect(insertSqlWasRun()).toBe(false);
  });

  it('404s a parentId that is not a uuid, without touching the database', async () => {
    for (const bad of ['not-a-uuid', '123', 'root%3A' + PARENT, `${PARENT}x`]) {
      query.mockReset();
      const res = await post(bad);
      expect(res.status, bad).toBe(404);
      expect(res.body.error.code).toBe('CLAIM_NOT_FOUND');
      expect(query).not.toHaveBeenCalled();
    }
  });

  it('canonicalises an uppercase parent id before it reaches the database', async () => {
    mockCreate();
    const res = await post(PARENT.toUpperCase());
    expect(res.status).toBe(201);
    expect(query.mock.calls[0][1]).toEqual([PARENT]);
    expect(insertCall()[1][0]).toBe(PARENT);
  });

  it('bumps the parent child count for the right side', async () => {
    mockCreate({ side: 'opposes' });

    const res = await post(PARENT, { side: 'opposes', body: BODY });
    expect(res.status).toBe(201);

    // The count lives on the PARENT and is moved by connect.bump_claim_child_counts, an AFTER
    // INSERT trigger that reads NEW.side. So the only thing the route owes is sending `side`
    // through verbatim — and NOT writing a count itself, which would double it.
    expect(insertCall()[1][1]).toBe('opposes');
    // No count is ASSIGNED anywhere (RETURNING reading them back is fine), and no UPDATE runs.
    expect(query.mock.calls.map((c) => String(c[0]))).not.toContainEqual(
      expect.stringMatching(/child_(supports|opposes)_count\s*=/)
    );
    expect(query.mock.calls.every((c) => !String(c[0]).startsWith('UPDATE'))).toBe(true);
  });

  it('never deletes anything', async () => {
    mockCreate();
    await post();
    expect(query.mock.calls.map((c) => String(c[0])).join(' ')).not.toMatch(/\bDELETE\b/i);
  });

  it('rate limits on a bucket of its own, so claims and forum posts do not starve each other', async () => {
    mockCreate();
    await post();
    expect(limit).toHaveBeenCalledTimes(1);
    const identifier = limit.mock.calls[0][0];
    expect(identifier).toContain(AUTHOR);
    expect(identifier).not.toBe(AUTHOR); // namespaced away from the thread/reply bucket
  });

  it('answers 429 with Retry-After when the bucket is empty, and writes nothing', async () => {
    limit.mockResolvedValueOnce({ success: false, reset: Date.now() + 90_000 });
    query.mockResolvedValueOnce(rows([{ id: PARENT, moderation_status: 'visible' }]));

    const res = await post();

    expect(res.status).toBe(429);
    expect(res.body).toEqual({ reason: 'rate_limited' });
    expect(Number(res.headers['retry-after'])).toBeGreaterThan(0);
    expect(insertSqlWasRun()).toBe(false);
  });

  it('serializes the Claim shape and no internal field', async () => {
    mockCreate();
    const res = await post();

    expect(res.body).toEqual({
      data: {
        id: CHILD,
        side: 'supports',
        body: BODY,
        authorPseudonym: 'Demo Finch',
        impact: null,
        ratingCount: 0,
        childSupports: 0,
        childOpposes: 0,
        isHidden: false,
        mergedInto: null,
        createdAt: TS,
        updatedAt: TS,
        myRating: null, // Task 5 fills it
      },
    });

    // The envelope is the whole response, so this is exhaustive: nothing internal rode along.
    const serialized = JSON.stringify(res.body);
    for (const leaked of ['author_id', 'community_id', 'path', 'depth', 'moderation_status',
      'child_supports_count', 'child_opposes_count', 'merged_into_claim_id', AUTHOR, 'Abraham Lincoln']) {
      expect(serialized, leaked).not.toContain(leaked);
    }
  });

  it('selects the timestamps in the PostgREST text form, not as Dates', async () => {
    mockCreate();
    await post();
    expect(insertSql()).toContain("to_json(created_at) #>> '{}' AS created_at");
    expect(insertSql()).toContain("to_json(updated_at) #>> '{}' AS updated_at");
  });

  it('500s with a fixed message when the insert fails, leaking no Postgres text', async () => {
    query.mockResolvedValueOnce(rows([{ id: PARENT, moderation_status: 'visible' }]));
    query.mockRejectedValueOnce(new Error('new row for relation "claims" violates check constraint "claims_body_not_blank"'));
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});

    const res = await post();

    expect(res.status).toBe(500);
    expect(res.body).toEqual({
      error: { code: 'CLAIM_CREATE_FAILED', message: 'Could not create the claim' },
    });
    expect(JSON.stringify(res.body)).not.toContain('constraint');
    expect(warn).toHaveBeenCalled();
    warn.mockRestore();
  });

  it('500s rather than 404s when the parent lookup itself fails', async () => {
    query.mockRejectedValueOnce(new Error('connection terminated'));
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});

    const res = await post();

    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe('CLAIM_CREATE_FAILED');
    expect(insertSqlWasRun()).toBe(false);
    warn.mockRestore();
  });

  it('never sets author_display_name itself', async () => {
    mockCreate();
    await post();
    expect(insertSql()).not.toContain('author_display_name (');
    const [, params] = insertCall();
    expect(params).not.toContain('Abraham Lincoln');
    // It is read back out of RETURNING, where the trigger put it.
    expect(insertSql()).toContain('RETURNING');
    expect(insertSql()).toContain('author_display_name');
  });
});

function insertSqlWasRun(): boolean {
  return query.mock.calls.some((c) => String(c[0]).includes('INSERT'));
}
