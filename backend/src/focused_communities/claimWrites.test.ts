import { describe, it, expect, vi, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';
import { MAX_CLAIM_DEPTH } from './lib/utils.js';

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

/**
 * The parent-state row the pre-flight reads. Everything the route branches on before writing:
 * withdrawn, unreachable (hidden ancestor), superseded (merged), or already at the depth cap.
 */
const parentState = (over: Record<string, unknown> = {}) => ({
  moderation_status: 'visible',
  merged_into_claim_id: null,
  depth: 3,
  has_hidden_ancestor: false,
  ...over,
});

/** Queue the two queries a successful create runs: the parent lookup, then the insert. */
function mockCreate(over: Record<string, unknown> = {}, parent: Record<string, unknown> | null = parentState()) {
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
    //
    // Asserted against the INSERT's COLUMN LIST rather than the whole statement, because the
    // statement legitimately READS p.path now (to check the ancestors for a hidden one).
    // Reading the parent's ancestry and supplying a position are different things; only the
    // second is forbidden, and only the column list can tell them apart.
    const [sql, params] = insertCall();
    const columns = /INSERT INTO connect\.claims \(([^)]*)\)/.exec(String(sql))![1];
    expect(columns).toBe('parent_claim_id, side, body, author_id');
    for (const derived of ['path', 'depth', 'community_id']) {
      expect(columns, derived).not.toContain(derived);
    }
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

  it('rejects a blank, too-short or oversized body', async () => {
    // Under 10 rules out "Yes", "No." and "+1" — votes rather than claims. Over 500 is several
    // claims written as one, which is what the tree exists to split up.
    for (const body of [undefined, '', '   ', 'x', 'No.', '+1', 'nine char', '  nine chr  ', 42, 'y'.repeat(501)]) {
      query.mockReset();
      const res = await post(PARENT, { side: 'supports', body });
      expect(res.status, `body=${JSON.stringify(body)?.slice(0, 20)}`).toBe(400);
      expect(res.body.error.code).toBe('INVALID_BODY');
      expect(res.body.error.message).toBe('body must be 10-500 characters');
      expect(query).not.toHaveBeenCalled();
    }
  });

  it('accepts a body at both bounds, measured after trimming', async () => {
    for (const body of ['y'.repeat(10), `  ${'y'.repeat(10)}  `, 'y'.repeat(500)]) {
      query.mockReset();
      mockCreate({ body: body.trim() });
      const res = await post(PARENT, { side: 'supports', body });
      expect(res.status, `len=${body.trim().length}`).toBe(201);
      expect(insertCall()[1][2]).toBe(body.trim());
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
    query.mockResolvedValueOnce(rows([parentState({ moderation_status: 'hidden' })]));
    res = await post();
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' } });
    expect(insertSqlWasRun()).toBe(false);
  });

  // ── The hide race ──────────────────────────────────────────────────────────────────────
  // A parent can be hidden (or moved, or merged) between the quota-guard read and the write.
  // The guarantee is in the writing statement: the visibility predicate sits under FOR UPDATE,
  // so READ COMMITTED re-evaluates it against the post-hide row and the INSERT inserts nothing.
  // pool.query is mocked here, so these pin the two halves a mock CAN see — the shape of the
  // statement that carries the guarantee, and what the route does with the zero rows it returns.
  // The semantics in between belong to Postgres, and EXPLAIN was used to confirm the filter sits
  // beneath the LockRows node rather than above it.

  it('makes the visibility check part of the write, under the parent row lock', async () => {
    mockCreate();
    await post();

    const sql = insertSql();
    expect(sql).toContain("p.moderation_status = 'visible'");
    expect(sql).toContain('FOR UPDATE OF p');
    // The predicate must be in the statement that WRITES, not only in the read before it.
    expect(sql.indexOf('INSERT')).toBeLessThan(sql.indexOf("moderation_status = 'visible'"));
  });

  it('cannot attach a child to a parent hidden while the write is in flight', async () => {
    // The guard read saw a visible parent; by the time the locked INSERT ran, it was hidden,
    // so the statement affected no rows.
    query.mockResolvedValueOnce(rows([parentState()]));
    query.mockResolvedValueOnce(rows([]));

    const res = await post();

    // 404 and not 500: zero rows is the race being caught, not a failure. And the same body a
    // parent hidden an hour ago gets, so the writer cannot tell the two apart.
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' } });
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

  it('answers 429 with Retry-After when the bucket is empty, and never touches the database', async () => {
    limit.mockResolvedValueOnce({ success: false, reset: Date.now() + 90_000 });

    const res = await post();

    expect(res.status).toBe(429);
    expect(res.body).toEqual({ reason: 'rate_limited' });
    expect(Number(res.headers['retry-after'])).toBeGreaterThan(0);
    // 🔴 The limiter runs BEFORE the parent lookup, so a rate-limited caller learns nothing
    // about whether the id names a real claim. Without that ordering, an unlimited stream of
    // failed lookups is a free existence oracle over claim ids. Not one query ran.
    expect(query).not.toHaveBeenCalled();
  });

  it('refuses the write when the rate limiter itself fails, rather than waving it through', async () => {
    limit.mockRejectedValueOnce(new Error('ECONNREFUSED upstash'));
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});

    const res = await post();

    // Fail CLOSED. connect.claims has no DELETE grant, so anything written is permanent and
    // has to be hidden one claim at a time; an unbounded flood during a Redis outage is the
    // unrecoverable failure, and a contributor retrying in a minute is the recoverable one.
    expect(res.status).toBe(500);
    expect(res.body).toEqual({
      error: { code: 'CLAIM_CREATE_FAILED', message: 'Could not create the claim' },
    });
    expect(query).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalled();
    warn.mockRestore();
  });

  // ── Unreachable, superseded and too deep ───────────────────────────────────────────────

  it('404s distinctly when an ANCESTOR is hidden, so the subtree cannot gain a child', async () => {
    query.mockResolvedValueOnce(rows([parentState({ has_hidden_ancestor: true })]));

    const res = await post();

    // A claim under a hidden ancestor is unreachable — no reader can walk to it — yet it would
    // still bump its parent's child count, corrupting the balance readers DO see.
    expect(res.status).toBe(404);
    expect(res.body).toEqual({
      error: {
        code: 'ANCESTOR_NOT_VISIBLE',
        message: 'The discussion above this point was removed',
      },
    });
    expect(insertSqlWasRun()).toBe(false);
  });

  it('tells a withdrawn point apart from a withdrawn discussion above it', async () => {
    query.mockResolvedValueOnce(rows([parentState({ moderation_status: 'hidden' })]));
    const hiddenParent = await post();

    query.mockReset();
    query.mockResolvedValueOnce(rows([parentState({ has_hidden_ancestor: true })]));
    const hiddenAncestor = await post();

    // Both 404 — there is nothing to attach to either way — but a contributor who just typed a
    // paragraph can tell which happened, and only one suggests arguing somewhere else.
    expect(hiddenParent.status).toBe(404);
    expect(hiddenAncestor.status).toBe(404);
    expect(hiddenParent.body).not.toEqual(hiddenAncestor.body);
    // And the hidden PARENT stays byte-identical to an absent one, which is untouched.
    query.mockReset();
    query.mockResolvedValueOnce(rows([]));
    expect((await post()).body).toEqual(hiddenParent.body);
  });

  it('409s a merged parent and names the claim that supersedes it', async () => {
    const TARGET = uuid(500);
    query.mockResolvedValueOnce(rows([parentState({ merged_into_claim_id: TARGET })]));

    const res = await post();

    // 409, not 404: the claim is there and readable, and the write is refused because of its
    // state. The target rides along so the client can redirect rather than lose the draft.
    expect(res.status).toBe(409);
    expect(res.body).toEqual({
      error: {
        code: 'CLAIM_MERGED',
        message: 'This point has been merged into another claim',
        mergedInto: TARGET,
      },
    });
    expect(insertSqlWasRun()).toBe(false);
  });

  it('asks about a merged PARENT but never a merged ancestor', async () => {
    mockCreate();
    await post();

    // Hiding removes; merging redirects. A merged ancestor leaves the subtree readable and
    // correctly counted, so it must NOT be rejected — the asymmetry with the hidden-ancestor
    // rule is deliberate, and this pins it so a later reader cannot "fix" it into symmetry.
    // Only the SQL can carry this: both statements scope the ancestor question to visibility.
    for (const sql of query.mock.calls.map((c) => String(c[0]))) {
      const ancestorSubquery = /a\.id = ANY \(p\.path\)[^)]*/.exec(sql)?.[0];
      if (!ancestorSubquery) continue;
      expect(ancestorSubquery).toContain('moderation_status');
      expect(ancestorSubquery).not.toContain('merged_into_claim_id');
    }
    // The parent's own merge state is asked about in both.
    expect(String(query.mock.calls[0][0])).toContain('p.merged_into_claim_id');
    expect(insertSql()).toContain('p.merged_into_claim_id IS NULL');
  });

  it('422s when the parent is already at the maximum depth', async () => {
    query.mockResolvedValueOnce(rows([parentState({ depth: MAX_CLAIM_DEPTH })]));

    const res = await post();

    expect(res.status).toBe(422);
    expect(res.body).toEqual({
      error: {
        code: 'MAX_DEPTH_REACHED',
        message: 'This discussion has reached its maximum depth',
      },
    });
    // The message names no number: the reader can do nothing with "50", and the cap may move.
    expect(JSON.stringify(res.body)).not.toContain(String(MAX_CLAIM_DEPTH));
    expect(insertSqlWasRun()).toBe(false);
  });

  it('allows a child one level short of the cap, and refuses one at it', async () => {
    mockCreate({}, parentState({ depth: MAX_CLAIM_DEPTH - 1 }));
    expect((await post()).status).toBe(201);

    query.mockReset();
    query.mockResolvedValueOnce(rows([parentState({ depth: MAX_CLAIM_DEPTH })]));
    expect((await post()).status).toBe(422);
  });

  it('checks the whole ancestor line inside the writing statement, not only before it', async () => {
    mockCreate();
    await post();

    // The concurrency guarantee can only be carried by the SQL text, as with the parent's own
    // visibility: these predicates are re-evaluated under FOR UPDATE, which a mock cannot see.
    const sql = insertSql();
    expect(sql).toContain('NOT EXISTS');
    expect(sql).toContain('a.id = ANY (p.path)');
    expect(sql).toContain("a.moderation_status <> 'visible'");
    expect(sql.indexOf('INSERT')).toBeLessThan(sql.indexOf('NOT EXISTS'));
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
    query.mockResolvedValueOnce(rows([parentState()]));
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
