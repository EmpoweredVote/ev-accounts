import { describe, it, expect, vi, beforeEach } from 'vitest';
import { readFileSync } from 'node:fs';
import express from 'express';
import request from 'supertest';
import { MAX_CLAIM_DEPTH } from './lib/utils.js';

// ── Mocks ────────────────────────────────────────────────────────────────────────────────
// The pool is a queue of canned results; every test asserts the SQL it expects to run. No test
// in here needs a live database — the route's contract with Postgres is "what it sends and what
// it does with what comes back", and both are visible in these calls.
const query = vi.fn();
/**
 * PATCH /claims/:claimId is the one route in the module that checks a client OUT of the pool,
 * because set_config('fc.actor_id', …, true) and the UPDATE have to share a transaction.
 *
 * The client's `query` is the SAME spy as the pool's, so every assertion in this file still
 * reads one ordered list of statements whether they were sent on a pooled connection or inside
 * the transaction. `release` is a spy of its own, because releasing it on EVERY path — commit,
 * zero rows, thrown statement — is the thing the transaction has to get right.
 */
const release = vi.fn();
vi.mock('./config/database.js', () => ({
  pool: {
    query: (...a: unknown[]) => query(...a),
    connect: async () => ({ query: (...a: unknown[]) => query(...a), release }),
  },
}));

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
    // What PUT /claims/:claimId/rating snapshots onto the rating row. Both come straight off
    // this composite, so the route runs no extra query for them. Settable per test: an
    // account composite missing either one is a real case the route must write NULL for.
    created_at: raterCreatedAt,
    ...(raterVerification === null ? {} : { connected_profile: { verification_status: raterVerification } }),
  }),
}));

/** 100 days before whatever `now` is when a test runs, to the millisecond. */
const ACCOUNT_AGE_DAYS = 100;
const ACCOUNT_CREATED_AT = new Date(Date.now() - ACCOUNT_AGE_DAYS * 86_400_000).toISOString();
let raterCreatedAt: string | null = ACCOUNT_CREATED_AT;
let raterVerification: string | null = 'verified';

const limit = vi.fn(async (_id: string) => ({ success: true, reset: Date.now() + 1000 }));
const ratingLimit = vi.fn(async (_id: string) => ({ success: true, reset: Date.now() + 1000 }));
vi.mock('./lib/rateLimit.js', () => ({
  postRateLimiter: { limit: (id: string) => limit(id) },
  ratingRateLimiter: { limit: (id: string) => ratingLimit(id) },
}));

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
  // GENERATED ALWAYS, so RETURNING already carries it: 5.0000 is what the formula gives a
  // row with no ratings. NUMERIC arrives from node-postgres as a string.
  impact: '5.0000',
  rating_count: 0,
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
  release.mockReset();
  limit.mockReset();
  limit.mockResolvedValue({ success: true, reset: Date.now() + 1000 });
  ratingLimit.mockReset();
  ratingLimit.mockResolvedValue({ success: true, reset: Date.now() + 1000 });
  raterCreatedAt = ACCOUNT_CREATED_AT;
  raterVerification = 'verified';
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
        // The neutral midpoint, read back off the generated column rather than stated here.
        // A brand new claim is unrated, and unrated is 5 — not null.
        impact: 5,
        ratingCount: 0,
        childSupports: 0,
        childOpposes: 0,
        isHidden: false,
        mergedInto: null,
        createdAt: TS,
        updatedAt: TS,
        myRating: null, // nobody has rated it, least of all its author
      },
    });

    // The envelope is the whole response, so this is exhaustive: nothing internal rode along.
    const serialized = JSON.stringify(res.body);
    for (const leaked of ['author_id', 'community_id', 'path', 'depth', 'moderation_status',
      'child_supports_count', 'child_opposes_count', 'merged_into_claim_id', AUTHOR, 'Abraham Lincoln']) {
      expect(serialized, leaked).not.toContain(leaked);
    }
  });

  it('reads impact and ratingCount off the row rather than stating them', async () => {
    // 🔴 A new claim is unrated, so the neutral 5 and the count 0 are what the generated
    // column will actually say - which makes a route that HARDCODED them indistinguishable
    // from one that reads them, until the formula changes and only one of the two follows.
    // CA_0345 owns the arithmetic; this file must own none of it. So: a row carrying numbers
    // the route could not have guessed.
    mockCreate({ impact: '6.6000', rating_count: 20 });

    const res = await post();

    expect(res.body.data.impact).toBe(6.6);
    expect(res.body.data.ratingCount).toBe(20);
    // And RETURNING asks for both, so there is something to read.
    expect(insertSql()).toContain('impact');
    expect(insertSql()).toContain('rating_count');
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

// ── PUT /claims/:claimId/rating ────────────────────────────────────────────────────────────

const RATED = uuid(200);

/** The two queries a successful rating runs: the upsert, then the aggregate read-back. */
function mockRate(aggregate: { impact: string; rating_count: number } = { impact: '5.0000', rating_count: 1 }) {
  query.mockResolvedValueOnce(rows([{ claim_id: RATED }]));
  query.mockResolvedValueOnce(rows([aggregate]));
}

/** The upsert matched nothing; the route then asks why. */
function mockRateRefused(state: Record<string, unknown> | null) {
  query.mockResolvedValueOnce(rows([]));
  query.mockResolvedValueOnce(rows(state ? [state] : []));
}

/** The request, body and all — so a test can send one with no `value` key at all. */
const rateWith = (body: object, claimId = RATED) =>
  request(app).put(`/fc/api/claims/${claimId}/rating`).set(...AUTH).send(body);
const rate = (value: unknown = 7, claimId = RATED) => rateWith({ value } as object, claimId);

const upsertCall = () => query.mock.calls.find((c) => String(c[0]).includes('ON CONFLICT'))!;
const upsertSql = () => String(upsertCall()[0]);

describe('PUT /claims/:claimId/rating', () => {
  it('returns the updated aggregate, and nothing else', async () => {
    mockRate({ impact: '6.6000', rating_count: 20 });

    const res = await rate(7);

    expect(res.status).toBe(200);
    // The whole envelope, so this is exhaustive. impact is a NUMERIC string on the wire and a
    // number in the response; ratingCount is how many people, not who.
    expect(res.body).toEqual({ data: { impact: 6.6, ratingCount: 20 } });
  });

  it('upserts rather than inserting a second row for the same rater', async () => {
    mockRate();
    await rate(7);

    // claim_ratings_one_per_user is UNIQUE (claim_id, user_id), and the statement says what to
    // do about it rather than reading first and branching — which would race the same person's
    // other tab. A re-rate REPLACES; it never adds.
    const sql = upsertSql();
    expect(sql).toContain('INSERT INTO connect.claim_ratings');
    expect(sql).toContain('ON CONFLICT (claim_id, user_id) DO UPDATE');
    expect(sql).toMatch(/SET\s+value\s+=\s+EXCLUDED\.value/);
    // No read-then-write anywhere: the upsert is the first statement the route runs.
    expect(String(query.mock.calls[0][0])).toContain('ON CONFLICT');
    expect(query.mock.calls).toHaveLength(2);
  });

  it('rejects a value outside 1..9, and anything that is not a whole number', async () => {
    // Bodies rather than values, so the missing-key case is really missing rather than a
    // defaulted one. NaN and Infinity reach the route as JSON null; Number.isInteger is what
    // rules them out on the day a client sends them some other way.
    const bodies: object[] = [
      {},
      { value: null },
      { value: 0 },
      { value: 10 },
      { value: -1 },
      { value: 4.5 },
      { value: NaN },
      { value: Infinity },
      { value: '7' },
      { value: '' },
      { value: true },
      { value: [7] },
      { value: { value: 7 } },
      { value: 9.000001 },
    ];
    for (const body of bodies) {
      query.mockReset();
      ratingLimit.mockReset();
      ratingLimit.mockResolvedValue({ success: true, reset: Date.now() + 1000 });
      const res = await rateWith(body);
      expect(res.status, `body=${JSON.stringify(body)}`).toBe(400);
      expect(res.body.error.code).toBe('INVALID_RATING');
      expect(res.body.error.message).toBe('value must be a whole number from 1 to 9');
      // Validation precedes the limiter and the database alike.
      expect(query).not.toHaveBeenCalled();
      expect(ratingLimit).not.toHaveBeenCalled();
    }
  });

  it('accepts every one of the nine positions, including the neutral middle', async () => {
    for (const value of [1, 2, 3, 4, 5, 6, 7, 8, 9]) {
      query.mockReset();
      mockRate();
      const res = await rate(value);
      expect(res.status, `value=${value}`).toBe(200);
      expect(upsertCall()[1][2]).toBe(value);
    }
  });

  it('never exposes an individual rating', async () => {
    // Not the caller's own (they just sent it), and least of all anyone else's. The response is
    // an aggregate over people, which is the only form a rating is ever readable in here —
    // apart from `myRating` on the claim's own node, served only to the person who cast it.
    mockRate({ impact: '7.0000', rating_count: 3 });

    const res = await rate(9);

    const body = JSON.stringify(res.body);
    expect(Object.keys(res.body.data).sort()).toEqual(['impact', 'ratingCount']);
    expect(body).not.toContain('myRating');
    expect(body).not.toContain('value');
    expect(body).not.toContain(AUTHOR);
    expect(body).not.toContain('"9"');
    expect(res.body.data).not.toHaveProperty('myRating');
    // And nothing the route SENT comes back either: no echo of the value, no rater id.
    expect(res.body.data.impact).toBe(7);
  });

  it('keeps a single 9 below a well-supported 7', async () => {
    // 🔴 THE LOW-n STABILITY CASE, AND WHY IT IS ASSERTED LIKE THIS.
    //
    // The route does no arithmetic — connect.claims.impact is a generated column and CA_0345
    // owns the formula, which is the whole point of ruling R38. So a unit test against a mocked
    // pool cannot observe the aggregation by running it. What it CAN do is two things that
    // together pin the decision:
    //
    //   1. State the arithmetic the chosen weight produces, so a reader of this file can see
    //      why 5 and not 1 without opening the migration.
    //   2. Prove the migration still declares that weight, so changing it in SQL alone fails
    //      HERE as well as in the migration's own probe.
    //
    // At weight 1 a single 9 scores 7.00 against 6.90 for twenty 7s and the single enthusiast
    // wins, which is the failure this case exists to forbid.
    const IMPACT_PRIOR_WEIGHT = 5;
    const IMPACT_NEUTRAL = 5;
    const impact = (count: number, sum: number) =>
      (IMPACT_PRIOR_WEIGHT * IMPACT_NEUTRAL + sum) / (IMPACT_PRIOR_WEIGHT + count);

    const oneNine = impact(1, 9);
    const twentySevens = impact(20, 7 * 20);
    const unrated = impact(0, 0);

    expect(Number(oneNine.toFixed(4))).toBe(5.6667);
    expect(Number(twentySevens.toFixed(4))).toBe(6.6);
    expect(oneNine).toBeLessThan(twentySevens);
    expect(twentySevens - oneNine).toBeGreaterThan(0.5); // margin, not a photo finish

    // An unrated claim is NEUTRAL, which is what lets the ordering place it at all, and one
    // disapproving rating puts a claim below it.
    expect(unrated).toBe(IMPACT_NEUTRAL);
    expect(impact(1, 1)).toBeLessThan(unrated);

    // And weight 1 — the value this case rules out — really does fail it.
    const atWeightOne = (count: number, sum: number) => (1 * IMPACT_NEUTRAL + sum) / (1 + count);
    expect(atWeightOne(1, 9)).toBeGreaterThan(atWeightOne(20, 140));

    // The migration must still say 5. Read from the file rather than trusted, because the
    // formula lives there and nothing else in this test suite can see it.
    const migration = readFileSync(
      new URL('../../migrations/CA_0345_claim_impact.sql', import.meta.url),
      'utf8'
    );
    expect(migration).toContain('round((5 * 5 + rating_sum)::numeric / (5 + rating_count), 4)');

    // 🔴 And TypeScript must hold no second copy of it. The constants above are a local
    // restatement for this one assertion; the route divides nothing.
    const route = readFileSync(new URL('./routes/claimWrites.ts', import.meta.url), 'utf8');
    expect(route).not.toMatch(/rating_sum\s*[/+]/);
    expect(route).not.toContain('IMPACT_PRIOR_WEIGHT');
  });

  it('makes the visibility and merge checks part of the write, under the claim row lock', async () => {
    mockRate();
    await rate();

    // Same mechanism as the child insert: the predicates are re-evaluated under FOR UPDATE when
    // a concurrent hide or merge commits, so the upsert writes nothing instead of rating a claim
    // that has just been withdrawn. A mock cannot see the semantics; it can see the statement.
    const sql = upsertSql();
    expect(sql).toContain("c.moderation_status = 'visible'");
    expect(sql).toContain('c.merged_into_claim_id IS NULL');
    expect(sql).toContain('FOR UPDATE OF c');
    expect(sql.indexOf('INSERT')).toBeLessThan(sql.indexOf("moderation_status = 'visible'"));
  });

  it('does not ask about hidden ancestors, unlike the child route', async () => {
    mockRate();
    await rate();

    // 🔴 A DELIBERATE ASYMMETRY. A child claim under a hidden ancestor is unreachable text that
    // still moves its parent's visible child counts, which is why POST /children refuses it. A
    // rating adds no text, creates no node and moves no count on another claim — it annotates a
    // row that already exists. The scan over c.path would buy nothing. Do not "fix" this into
    // symmetry with the child route.
    for (const sql of query.mock.calls.map((c) => String(c[0]))) {
      expect(sql).not.toContain('ANY (c.path)');
      expect(sql).not.toContain('ANY (p.path)');
    }
  });

  it('404s a hidden claim, byte-identical to an absent one', async () => {
    mockRateRefused({ moderation_status: 'hidden', merged_into_claim_id: null });
    const hidden = await rate();

    query.mockReset();
    mockRateRefused(null);
    const absent = await rate();

    expect(hidden.status).toBe(404);
    expect(absent.status).toBe(404);
    expect(hidden.body).toEqual({ error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' } });
    expect(hidden.body).toEqual(absent.body);
  });

  // A root is the community's question — no author, no side, nobody advanced it — so "how much
  // weight does this deserve" has no meaning for it. An impact on a root is not inert either: it
  // is served on the root node body and drawn as the depth-0 dot on the minimap, where it reads
  // as a rating of the topic itself. The id is one public GET away, so this was reachable by any
  // connected account until the write statement grew its parent_claim_id predicate.
  it('refuses to rate a root claim, and the predicate is in the writing statement', async () => {
    mockRateRefused({ moderation_status: 'visible', merged_into_claim_id: null });
    const res = await rate();

    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' } });

    // The guard has to be in the statement that WRITES, under the same lock as the other two —
    // a pre-flight check would let a root rated concurrently with its own creation through.
    const insert = String(query.mock.calls[0][0]);
    expect(insert).toContain('INSERT INTO connect.claim_ratings');
    expect(insert).toContain('c.parent_claim_id IS NOT NULL');
    expect(insert.indexOf('c.parent_claim_id IS NOT NULL')).toBeLessThan(
      insert.indexOf('FOR UPDATE OF c')
    );
  });

  it('409s a merged claim and names the one that supersedes it', async () => {
    const TARGET = uuid(500);
    mockRateRefused({ moderation_status: 'visible', merged_into_claim_id: TARGET });

    const res = await rate();

    // Readers follow the merge, so a rating left on the superseded copy splits one argument's
    // signal across two rows. 409 with somewhere to send it instead.
    expect(res.status).toBe(409);
    expect(res.body).toEqual({
      error: {
        code: 'CLAIM_MERGED',
        message: 'This point has been merged into another claim',
        mergedInto: TARGET,
      },
    });
  });

  it('keeps a hidden claim hidden even when it also carries a merge target', async () => {
    const TARGET = uuid(500);
    mockRateRefused({ moderation_status: 'hidden', merged_into_claim_id: TARGET });

    const res = await rate();

    // Hidden withholds more than merged discloses: a withdrawn claim's merge target is not
    // something this route should volunteer, and the 404 must stay indistinguishable from the
    // absent case whatever else is true of the row.
    expect(res.status).toBe(404);
    expect(JSON.stringify(res.body)).not.toContain(TARGET);
  });

  it('classifies only after the write, so a successful rating costs two round trips', async () => {
    mockRate();
    await rate();
    expect(query.mock.calls).toHaveLength(2);

    // A refusal is the only path that pays for a third. The ordering loses nothing: the state
    // that matters is the one the locked write saw, not the one a pre-flight read did.
    query.mockReset();
    mockRateRefused({ moderation_status: 'hidden', merged_into_claim_id: null });
    await rate();
    expect(query.mock.calls).toHaveLength(2);
  });

  it('reads the aggregate back in a second statement, never from the upsert', async () => {
    mockRate({ impact: '5.6667', rating_count: 1 });
    const res = await rate(9);

    // 🔴 connect.bump_claim_rating_aggregate is an AFTER trigger, so it has not run when the
    // upsert's output is produced. RETURNING impact — or a CTE wrapping the upsert in a SELECT —
    // would hand back the aggregate from BEFORE this rating, and would look right in every test
    // that did not check the number.
    expect(upsertSql()).toContain('RETURNING claim_id');
    expect(upsertSql()).not.toContain('impact');
    expect(upsertSql()).not.toContain('WITH ');

    const readBack = String(query.mock.calls[1][0]);
    expect(readBack).toContain('SELECT c.impact, c.rating_count');
    expect(readBack).toContain('FROM connect.claims c');
    expect(query.mock.calls[1][1]).toEqual([RATED]);
    expect(res.body.data).toEqual({ impact: 5.6667, ratingCount: 1 });
  });

  it('snapshots the rater as they are at this moment', async () => {
    mockRate();
    await rate(7);

    // 🔴 These cannot be reconstructed later: an account that verifies next month must not
    // retroactively reweight what it said today. The aggregate ignores both for now; they are
    // written because now is the only time they can be.
    const [, params] = upsertCall();
    expect(params).toEqual([RATED, AUTHOR, 7, ACCOUNT_AGE_DAYS, 'verified']);
    // Both come off the composite requireAuth already loaded, so no extra query ran for them.
    expect(query.mock.calls).toHaveLength(2);
  });

  it('refreshes the snapshot on a re-rate, because a replaced value is a new rating', async () => {
    mockRate();
    await rate(3);

    const sql = upsertSql();
    expect(sql).toMatch(/rater_account_age_days\s+=\s+EXCLUDED\.rater_account_age_days/);
    expect(sql).toMatch(/rater_verification_status\s+=\s+EXCLUDED\.rater_verification_status/);
    expect(sql).toMatch(/updated_at\s+=\s+now\(\)/);
  });

  it('writes NULL rather than inventing a snapshot it does not have', async () => {
    raterCreatedAt = null;
    raterVerification = null;
    mockRate();
    await rate(7);

    const [, params] = upsertCall();
    expect(params[3]).toBeNull();
    expect(params[4]).toBeNull();
    // Not 0 and not 'unverified'. A guessed snapshot is worse than a missing one, because
    // nothing downstream could ever tell the two apart.
    expect(params[3]).not.toBe(0);
    expect(params[4]).not.toBe('unverified');
  });

  it('writes NULL for an unparseable created_at too', async () => {
    raterCreatedAt = 'not a date';
    mockRate();
    await rate(7);
    expect(upsertCall()[1][3]).toBeNull();
  });

  it('requires a connected account, and a signed-in caller at all', async () => {
    const inform = await request(app)
      .put(`/fc/api/claims/${RATED}/rating`)
      .set('Authorization', 'Bearer inform')
      .send({ value: 7 });
    expect(inform.status).toBe(403);
    expect(inform.body.reason).toBe('tier');

    const anonymous = await request(app).put(`/fc/api/claims/${RATED}/rating`).send({ value: 7 });
    expect(anonymous.status).toBe(401);

    expect(query).not.toHaveBeenCalled();
    expect(ratingLimit).not.toHaveBeenCalled();
  });

  it('404s a claimId that is not a uuid, without touching the database', async () => {
    for (const bad of ['not-a-uuid', '123', `${RATED}x`, `{${RATED}}`]) {
      query.mockReset();
      const res = await rate(7, bad);
      expect(res.status, bad).toBe(404);
      expect(res.body.error.code).toBe('CLAIM_NOT_FOUND');
      expect(query).not.toHaveBeenCalled();
    }
  });

  it('canonicalises an uppercase claim id before it reaches the database', async () => {
    mockRate();
    const res = await rate(7, RATED.toUpperCase());
    expect(res.status).toBe(200);
    expect(upsertCall()[1][0]).toBe(RATED);
    expect(query.mock.calls[1][1]).toEqual([RATED]);
  });

  it('rate limits on its own limiter and its own bucket', async () => {
    mockRate();
    await rate();

    // 🔴 A DIFFERENT LIMITER, not merely a different counter. postRateLimiter's 5 an hour is
    // priced for permanent, moderatable text; five ratings an hour would refuse a reader
    // part-way down their first column of twenty children.
    expect(ratingLimit).toHaveBeenCalledTimes(1);
    expect(limit).not.toHaveBeenCalled();
    const identifier = ratingLimit.mock.calls[0][0];
    expect(identifier).toContain(AUTHOR);
    expect(identifier).not.toBe(AUTHOR);
    expect(identifier).not.toContain('claim:');
  });

  it('answers 429 with Retry-After, and never touches the database', async () => {
    ratingLimit.mockResolvedValueOnce({ success: false, reset: Date.now() + 90_000 });

    const res = await rate();

    expect(res.status).toBe(429);
    expect(res.body).toEqual({ reason: 'rate_limited' });
    expect(Number(res.headers['retry-after'])).toBeGreaterThan(0);
    // The limiter precedes every lookup, so a rate-limited caller learns nothing about whether
    // the id names a real claim. Without that ordering this is a free existence oracle — and a
    // better one than the child route, because the budget here is twelve times as large.
    expect(query).not.toHaveBeenCalled();
  });

  it('refuses the write when the rate limiter itself fails', async () => {
    ratingLimit.mockRejectedValueOnce(new Error('ECONNREFUSED upstash'));
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});

    const res = await rate();

    expect(res.status).toBe(500);
    expect(res.body).toEqual({
      error: { code: 'CLAIM_RATING_FAILED', message: 'Could not save the rating' },
    });
    expect(query).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalled();
    warn.mockRestore();
  });

  it('500s with a message about the rating, not about creating a claim', async () => {
    query.mockRejectedValueOnce(
      new Error('new row for relation "claim_ratings" violates check constraint "claim_ratings_value_range"')
    );
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});

    const res = await rate();

    // "Could not create the claim" would be a lie here, and a client retrying on one failure
    // and not the other has no way to tell them apart from a shared code.
    expect(res.status).toBe(500);
    expect(res.body).toEqual({
      error: { code: 'CLAIM_RATING_FAILED', message: 'Could not save the rating' },
    });
    expect(JSON.stringify(res.body)).not.toContain('constraint');
    expect(JSON.stringify(res.body)).not.toContain('claim_ratings');
    warn.mockRestore();
  });

  it('does not report a stored rating as a failure when the read-back ERRORS', async () => {
    // 🔴 THE UPSERT COMMITTED IN ITS OWN TRANSACTION BEFORE THIS STATEMENT RAN. A dropped
    // connection, the max: 3 pool timing out at connectionTimeoutMillis under load, a
    // transient pooler error — any of them used to produce
    // `500 { CLAIM_RATING_FAILED, 'Could not save the rating' }` about a rating that is in the
    // table. That is false twice: the rater is told their own action did not happen, and the
    // non-2xx skips middleware/claimInvalidation.ts, so the PRE-rating impact survives the
    // full 30s TTL. They retry, see the old number, and have no way to tell the write landed.
    query.mockResolvedValueOnce(rows([{ claim_id: RATED }]));
    query.mockRejectedValueOnce(new Error('Connection terminated unexpectedly'));
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});

    const res = await rate();

    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      data: { impact: null, ratingCount: null, aggregateUnavailable: true },
    });
    // No invented number in place of the one that could not be read. 0, the old value, or the
    // caller's own value dressed up as the mean would each be a plausible falsehood about how
    // much the argument moved — the one kind of wrong this platform cannot afford.
    expect(res.body.data.impact).toBeNull();
    // It still reaches the log, with the real message, which the body never carries.
    expect(warn).toHaveBeenCalled();
    expect(JSON.stringify(res.body)).not.toContain('Connection terminated');
    warn.mockRestore();
  });

  it('does not report a stored rating as a failure when the read-back finds NOTHING either', async () => {
    // Previously a 500 "Could not save the rating", directly beneath a comment that had just
    // established the rating WAS stored. The row cannot ordinarily vanish — the upsert matched
    // it a moment ago and connect.claims has no DELETE grant — so this is the same degraded
    // success as the error above, not a 404 and not a failure.
    query.mockResolvedValueOnce(rows([{ claim_id: RATED }]));
    query.mockResolvedValueOnce(rows([]));
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});

    const res = await rate();

    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      data: { impact: null, ratingCount: null, aggregateUnavailable: true },
    });
    expect(warn).toHaveBeenCalled();
    warn.mockRestore();
  });

  it('still 500s when the UPSERT itself fails, which is a rating that was NOT stored', async () => {
    // The line the degraded 200 must not cross. Everything before the upsert commits is a
    // genuine failure and keeps "Could not save the rating", because there is nothing in the
    // table to be honest about — and a 2xx here would invalidate a cache that is still correct.
    query.mockRejectedValueOnce(new Error('could not serialize access'));
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});

    const res = await rate();

    expect(res.status).toBe(500);
    expect(res.body).toEqual({
      error: { code: 'CLAIM_RATING_FAILED', message: 'Could not save the rating' },
    });
    warn.mockRestore();
  });

  it('500s rather than 404s when the classifying lookup itself fails', async () => {
    query.mockResolvedValueOnce(rows([]));
    query.mockRejectedValueOnce(new Error('connection terminated'));
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});

    const res = await rate();

    // A database that cannot answer is not a missing claim. 404 would tell the rater their
    // claim is gone, which is a different and much worse thing to be wrong about.
    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe('CLAIM_RATING_FAILED');
    warn.mockRestore();
  });

  it('never deletes anything, and never writes the aggregate itself', async () => {
    mockRate();
    await rate();

    const all = query.mock.calls.map((c) => String(c[0])).join(' ');
    expect(all).not.toMatch(/\bDELETE\b/i);
    // rating_count and rating_sum belong to connect.bump_claim_rating_aggregate. A route that
    // moved them too would double every rating, and a stale count reads as a legitimate number.
    expect(all).not.toMatch(/rating_(count|sum)\s*=/);
    expect(all).not.toContain('UPDATE connect.claims');
  });
});

// ── PATCH /claims/:claimId ─────────────────────────────────────────────────────────────────

const EDITED = uuid(300);
const NEW_BODY = 'The budget covers the first three years, not the first two.';

/** The row the UPDATE hands back: the insert's columns plus the caller's own rating. */
const editedRow = (over: Record<string, unknown> = {}) => ({
  ...inserted({ id: EDITED, body: NEW_BODY }),
  my_rating: null,
  ...over,
});

/**
 * The four statements a successful edit sends: BEGIN, set_config, the UPDATE, COMMIT.
 * They all land on the same spy, so a test can read them in order.
 */
function mockEdit(over: Record<string, unknown> = {}) {
  query.mockResolvedValueOnce(rows([])); // BEGIN
  query.mockResolvedValueOnce(rows([{ set_config: AUTHOR }])); // set_config
  query.mockResolvedValueOnce(rows([editedRow(over)])); // the UPDATE
  query.mockResolvedValueOnce(rows([])); // COMMIT
}

/** The UPDATE matched nothing; the route then asks why, on a pooled connection. */
function mockEditRefused(state: Record<string, unknown> | null) {
  query.mockResolvedValueOnce(rows([])); // BEGIN
  query.mockResolvedValueOnce(rows([{ set_config: AUTHOR }])); // set_config
  query.mockResolvedValueOnce(rows([])); // the UPDATE, matching nothing
  query.mockResolvedValueOnce(rows([])); // COMMIT
  query.mockResolvedValueOnce(rows(state ? [state] : [])); // the classifying lookup
}

const patch = (claimId: string = EDITED, body: unknown = { body: NEW_BODY }) =>
  request(app).patch(`/fc/api/claims/${claimId}`).set(...AUTH).send(body as object);

const updateCall = () => query.mock.calls.find((c) => String(c[0]).startsWith('UPDATE'))!;
const updateSql = () => String(updateCall()[0]);
const actorCall = () => query.mock.calls.find((c) => String(c[0]).includes('set_config'))!;

describe('PATCH /claims/:claimId', () => {
  it('lets the author edit after the claim has ratings and children', async () => {
    // 🔴 The case the brief names, and the one with a consequence worth stating: ratings cast
    // against the OLD wording carry over to the new one verbatim, and the children argue with
    // text that has changed under them. The edit is allowed anyway — withholding it would mean
    // the first rating freezes a typo forever — so the statement must not touch either.
    mockEdit({ impact: '6.6000', rating_count: 20, child_supports_count: 4, child_opposes_count: 2 });

    const res = await patch();

    expect(res.status).toBe(200);
    expect(res.body.data.body).toBe(NEW_BODY);
    expect(res.body.data.ratingCount).toBe(20);
    expect(res.body.data.impact).toBe(6.6);
    expect(res.body.data.childSupports).toBe(4);
    expect(res.body.data.childOpposes).toBe(2);
  });

  it('writes body and updated_at and nothing else', async () => {
    mockEdit();
    await patch();

    const sql = updateSql();
    // The SET list, exactly. rating_count, rating_sum and impact belong to CA_0345's triggers
    // and its generated column; path, depth and community_id belong to trg_claims_derive_position
    // (BEFORE INSERT OR UPDATE OF parent_claim_id, which a body edit does not fire); the child
    // counts belong to trg_claims_bump_child_counts_move. An edit that moved any of them would
    // be silently rewriting somebody else's arithmetic.
    const setList = /SET\s+([\s\S]*?)\s+WHERE/.exec(sql)![1];
    for (const forbidden of ['rating_count', 'rating_sum', 'impact', 'path', 'depth',
      'community_id', 'child_supports_count', 'child_opposes_count', 'parent_claim_id',
      'side', 'author_id', 'author_display_name', 'moderation_status', 'merged_into_claim_id']) {
      expect(setList, forbidden).not.toContain(forbidden);
    }
    expect(setList).toContain('body');
    expect(setList).toContain('updated_at');
    expect(query.mock.calls.map((c) => String(c[0])).join(' ')).not.toMatch(/\bDELETE\b/i);
  });

  it('records the edit in history with the actor', async () => {
    mockEdit();
    await patch();

    // 🔴 The route writes NO claim_edits row. connect.log_claim_edit does, and it refuses to —
    // it RAISES — unless fc.actor_id is set, so the only thing this route owes the audit trail
    // is the actor, set with is_local = true in the SAME transaction as the UPDATE.
    const statements = query.mock.calls.map((c) => String(c[0]));
    expect(statements[0]).toBe('BEGIN');
    expect(statements[1]).toContain("set_config('fc.actor_id'");
    expect(statements[1]).toContain('true'); // is_local: dies with the transaction
    expect(statements[2]).toMatch(/^UPDATE/);
    expect(statements[3]).toBe('COMMIT');
    expect(actorCall()[1]).toEqual([AUTHOR]);
    expect(statements.join(' ')).not.toContain('claim_edits');

    // And the trigger really is what the route is relying on. Read from the migration rather
    // than trusted, because nothing else in this suite can see it: the setting's name, the
    // RAISE when it is unset, and the AFTER UPDATE trigger that calls the function.
    const migration = readFileSync(
      new URL('../../migrations/CA_0341_focused_communities_claims.sql', import.meta.url),
      'utf8'
    );
    expect(migration).toContain("current_setting('fc.actor_id', true)");
    expect(migration).toContain('AFTER UPDATE ON connect.claims');
    expect(migration).toContain('EXECUTE FUNCTION connect.log_claim_edit()');
  });

  it('releases the client on every path, and only ever holds one', async () => {
    mockEdit();
    await patch();
    expect(release).toHaveBeenCalledTimes(1);

    // Zero rows: the transaction still ends and the client still goes back.
    query.mockReset();
    release.mockReset();
    mockEditRefused(null);
    await patch();
    expect(release).toHaveBeenCalledTimes(1);

    // A thrown statement: ROLLBACK, release, and only then a response.
    query.mockReset();
    release.mockReset();
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});
    query.mockResolvedValueOnce(rows([])); // BEGIN
    query.mockResolvedValueOnce(rows([{ set_config: AUTHOR }]));
    query.mockRejectedValueOnce(new Error('canceling statement due to statement timeout'));
    query.mockResolvedValueOnce(rows([])); // ROLLBACK
    const res = await patch();
    expect(res.status).toBe(500);
    expect(release).toHaveBeenCalledTimes(1);
    expect(query.mock.calls.map((c) => String(c[0]))).toContain('ROLLBACK');
    warn.mockRestore();
  });

  it('404s a non-author editor, and never 403', async () => {
    mockEditRefused(null);

    const res = await patch();

    // 🔴 403 would confirm two things at once: that this uuid names a claim, and that somebody
    // else wrote it. 404 says neither. The ownership predicate is in the UPDATE itself, so a
    // non-author's statement matches no row rather than being refused after a read.
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' } });

    // The predicate itself, because a mocked pool cannot show a stranger being refused — only
    // the statement that refuses them. EQUALITY against the caller's own parameter: `author_id
    // IS NOT NULL` would satisfy a looser assertion and let anybody edit anybody's claim.
    const where = /WHERE([\s\S]*?)RETURNING/.exec(updateSql())![1];
    const owner = /AND author_id = \$(\d)::uuid/.exec(where);
    expect(owner, 'the UPDATE must test author_id against a parameter').not.toBeNull();
    expect(updateCall()[1][Number(owner![1]) - 1]).toBe(AUTHOR);
  });

  it('cannot edit a root claim, because a root has no author', async () => {
    // All 61 roots are seeded by trg_communities_seed_root_claim with author_id NULL — they are
    // the community's question, not anyone's contribution. `author_id = $caller` is NULL, and
    // therefore false, for every caller, so a root is uneditable with no special case. This pins
    // it so a later reader does not "fix" the NULL comparison into something that admits one.
    mockEditRefused({ merged_into_claim_id: null });

    const res = await patch();

    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('CLAIM_NOT_FOUND');
    expect(updateSql()).not.toContain('IS NULL OR');
    expect(updateSql()).not.toContain('COALESCE');
  });

  it('404s a hidden claim, byte-identical to an absent one', async () => {
    mockEditRefused(null); // the classifying lookup is scoped to visible rows, so hidden reads empty
    const hidden = await patch();

    query.mockReset();
    release.mockReset();
    mockEditRefused(null);
    const absent = await patch();

    expect(hidden.status).toBe(404);
    expect(hidden.body).toEqual(absent.body);
    expect(updateSql()).toContain("moderation_status = 'visible'");
  });

  it('409s a merged claim and names the one that supersedes it', async () => {
    const TARGET = uuid(500);
    mockEditRefused({ merged_into_claim_id: TARGET });

    const res = await patch();

    // Readers follow the merge to the target, so a rewrite of the superseded copy is text
    // nobody will meet — the same reason POST /children refuses a merged parent. 409 with
    // somewhere to go, rather than a 404 that loses the draft. The classifying lookup is
    // scoped to the caller's OWN visible claims, so nobody else learns the target exists.
    expect(res.status).toBe(409);
    expect(res.body).toEqual({
      error: {
        code: 'CLAIM_MERGED',
        message: 'This point has been merged into another claim',
        mergedInto: TARGET,
      },
    });
    const classify = String(query.mock.calls[4][0]);
    expect(classify).toContain('author_id');
    expect(classify).toContain("moderation_status = 'visible'");
    expect(updateSql()).toContain('merged_into_claim_id IS NULL');
  });

  it('accepts an unchanged body: 200, and no history is manufactured', async () => {
    // trg_log_claim_edit has a WHEN clause gating on OLD.body IS DISTINCT FROM NEW.body, so
    // resending the same text writes no history row. The route agrees rather than 422ing, and
    // — the part that is actually ours — it does not bump updated_at either, so a client
    // retrying cannot make an unedited claim LOOK edited with nothing behind it.
    mockEdit({ body: BODY, updated_at: TS });

    const res = await patch(EDITED, { body: BODY });

    expect(res.status).toBe(200);
    expect(res.body.data.updatedAt).toBe(TS);
    const setList = /SET\s+([\s\S]*?)\s+WHERE/.exec(updateSql())![1];
    expect(setList).toMatch(/updated_at\s*=\s*CASE WHEN body IS DISTINCT FROM/);
  });

  it('reuses the create route bounds rather than declaring its own', async () => {
    for (const body of [undefined, '', '   ', 'x', 'No.', '+1', 'nine char', 42, 'y'.repeat(501)]) {
      query.mockReset();
      const res = await patch(EDITED, { body });
      expect(res.status, `body=${JSON.stringify(body)?.slice(0, 20)}`).toBe(400);
      expect(res.body.error.code).toBe('INVALID_BODY');
      // 🔴 The same sentence the create route sends. An edit that could produce a body POST
      // /children would have refused is a hole, not a feature.
      expect(res.body.error.message).toBe('body must be 10-500 characters');
      expect(query).not.toHaveBeenCalled();
    }

    // And the constants are declared exactly once in the route file.
    const route = readFileSync(new URL('./routes/claimWrites.ts', import.meta.url), 'utf8');
    expect(route.match(/const BODY_MIN/g)).toHaveLength(1);
    expect(route.match(/const BODY_MAX/g)).toHaveLength(1);
  });

  it('accepts a body at both bounds, measured after trimming', async () => {
    for (const body of ['y'.repeat(10), `  ${'y'.repeat(10)}  `, 'y'.repeat(500)]) {
      query.mockReset();
      release.mockReset();
      mockEdit({ body: body.trim() });
      const res = await patch(EDITED, { body });
      expect(res.status, `len=${body.trim().length}`).toBe(200);
      expect(updateCall()[1]).toContain(body.trim());
    }
  });

  it('404s a claimId that is not a uuid, without touching the database', async () => {
    for (const bad of ['not-a-uuid', '123', `${EDITED}x`, `{${EDITED}}`]) {
      query.mockReset();
      const res = await patch(bad);
      expect(res.status, bad).toBe(404);
      expect(res.body.error.code).toBe('CLAIM_NOT_FOUND');
      expect(query).not.toHaveBeenCalled();
      expect(release).not.toHaveBeenCalled();
    }
  });

  it('canonicalises an uppercase claim id before it reaches the database', async () => {
    mockEdit();
    const res = await patch(EDITED.toUpperCase());
    expect(res.status).toBe(200);
    expect(updateCall()[1][0]).toBe(EDITED);
  });

  it('is not rate limited, matching posts', async () => {
    mockEdit();
    await patch();
    // An edit creates no row a maven has to moderate and adds nothing to the tree — it replaces
    // text the author already got through the limiter once. PATCH /posts/:id is unmetered for
    // the same reason, and metering an edit would leave a contributor stuck with a typo.
    expect(limit).not.toHaveBeenCalled();
    expect(ratingLimit).not.toHaveBeenCalled();
  });

  it('requires a connected account, and a signed-in caller at all', async () => {
    const inform = await request(app)
      .patch(`/fc/api/claims/${EDITED}`)
      .set('Authorization', 'Bearer inform')
      .send({ body: NEW_BODY });
    expect(inform.status).toBe(403);
    expect(inform.body.reason).toBe('tier');

    const anonymous = await request(app).patch(`/fc/api/claims/${EDITED}`).send({ body: NEW_BODY });
    expect(anonymous.status).toBe(401);

    expect(query).not.toHaveBeenCalled();
    expect(release).not.toHaveBeenCalled();
  });

  it('500s with a fixed message when the UPDATE fails, leaking no Postgres text', async () => {
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});
    query.mockResolvedValueOnce(rows([])); // BEGIN
    query.mockResolvedValueOnce(rows([{ set_config: AUTHOR }]));
    query.mockRejectedValueOnce(
      new Error('new row for relation "claims" violates check constraint "claims_body_not_blank"')
    );
    query.mockResolvedValueOnce(rows([])); // ROLLBACK
    query.mockResolvedValueOnce(rows([])); // a classifying lookup, which must NOT happen

    const res = await patch();

    expect(res.status).toBe(500);
    expect(res.body).toEqual({
      error: { code: 'CLAIM_EDIT_FAILED', message: 'Could not save the edit' },
    });
    // 🔴 A statement that THREW is not the same as one that matched no row, and the route must
    // not fall through into the refusal path and answer 404 — telling an author their claim is
    // gone because the database hiccuped. Four statements: BEGIN, set_config, the UPDATE,
    // ROLLBACK. The fifth mock above is deliberately left unconsumed.
    expect(query.mock.calls).toHaveLength(4);
    // Not the create route's code: a client retrying on one and not the other needs to tell
    // them apart, and "Could not create the claim" is a lie here.
    expect(JSON.stringify(res.body)).not.toContain('constraint');
    expect(JSON.stringify(res.body)).not.toContain('CLAIM_CREATE_FAILED');
    expect(warn).toHaveBeenCalled();
    warn.mockRestore();
  });

  it('500s rather than 404s when the classifying lookup itself fails', async () => {
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});
    query.mockResolvedValueOnce(rows([])); // BEGIN
    query.mockResolvedValueOnce(rows([{ set_config: AUTHOR }]));
    query.mockResolvedValueOnce(rows([])); // the UPDATE matched nothing
    query.mockResolvedValueOnce(rows([])); // COMMIT
    query.mockRejectedValueOnce(new Error('connection terminated'));

    const res = await patch();

    // A database that cannot answer is not a missing claim. 404 would tell an author their
    // own claim is gone, which is a different and much worse thing to be wrong about.
    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe('CLAIM_EDIT_FAILED');
    warn.mockRestore();
  });

  it('serves the author their own rating back rather than nulling it', async () => {
    // 🔴 myRating is the one per-caller field in a Claim. An author who rated their own claim
    // and then fixed a typo must not get a body back that says they never rated it — a client
    // that replaces its local claim with this response would wipe the rating from the UI.
    mockEdit({ my_rating: 8 });

    const res = await patch();

    expect(res.body.data.myRating).toBe(8);
    expect(updateSql()).toContain('connect.claim_ratings');
    expect(updateSql()).toContain('AS my_rating');
  });

  it('serializes the Claim shape and no internal field', async () => {
    mockEdit();
    const res = await patch();

    expect(res.body).toEqual({
      data: {
        id: EDITED,
        side: 'supports',
        body: NEW_BODY,
        authorPseudonym: 'Demo Finch',
        impact: 5,
        ratingCount: 0,
        childSupports: 0,
        childOpposes: 0,
        isHidden: false,
        mergedInto: null,
        createdAt: TS,
        updatedAt: TS,
        myRating: null,
      },
    });
    const serialized = JSON.stringify(res.body);
    for (const leaked of ['author_id', 'community_id', 'path', 'depth', 'moderation_status',
      'child_supports_count', 'merged_into_claim_id', AUTHOR, 'Abraham Lincoln']) {
      expect(serialized, leaked).not.toContain(leaked);
    }
  });
});

// ── DELETE /claims/:claimId ────────────────────────────────────────────────────────────────

describe('DELETE /claims/:claimId', () => {
  it('answers DELETE with 405 and an Allow header', async () => {
    const res = await request(app).delete(`/fc/api/claims/${EDITED}`).set(...AUTH);

    // Memory over Moderation, as for threads and posts: a claim is withdrawn, not removed, and
    // connect.claims carries no DELETE grant for any role this process can be. 405 names the
    // methods that DO work rather than pretending the route is missing.
    expect(res.status).toBe(405);
    expect(res.headers.allow).toBe('GET, PATCH');
    expect(res.body).toEqual({
      error: { code: 'DELETE_NOT_ALLOWED', message: 'Claims cannot be deleted' },
    });
    expect(query).not.toHaveBeenCalled();
  });

  it('refuses the method before it asks who is calling', async () => {
    // No Authorization header at all. 405 is a fact about the resource, not about the caller,
    // so answering 401 first would make "can this be deleted?" an authenticated question.
    const res = await request(app).delete(`/fc/api/claims/${EDITED}`);
    expect(res.status).toBe(405);
    expect(query).not.toHaveBeenCalled();
  });
});

// ── GET /claims/:claimId/edits ─────────────────────────────────────────────────────────────

const editRow = (over: Record<string, unknown> = {}) => ({
  id: uuid(900),
  old_body: 'The budget covers the first two years.',
  by_author: true,
  edited_at: TS,
  ...over,
});

/** The two statements the history read runs: the visibility lookup, then the history. */
function mockHistory(history: Record<string, unknown>[], status: string | null = 'visible') {
  query.mockResolvedValueOnce(rows(status ? [{ moderation_status: status }] : []));
  if (status) query.mockResolvedValueOnce(rows(history));
}

const getEdits = (claimId: string = EDITED) => request(app).get(`/fc/api/claims/${claimId}/edits`);

describe('GET /claims/:claimId/edits', () => {
  it('serves edit history without authentication', async () => {
    mockHistory([editRow()]);

    const res = await getEdits();

    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      data: [{ id: uuid(900), oldBody: 'The budget covers the first two years.', byAuthor: true, editedAt: TS }],
    });
  });

  it('never serves actor_id or any other account identifier', async () => {
    // 🔴 connect.claim_edits.actor_id is a raw account uuid and this endpoint is anonymous, so
    // returning it would publish a stable identifier for every editor to every reader. The
    // column is not even SELECTed: the comparison against the claim's author happens in SQL, so
    // no account uuid reaches this process, let alone the response.
    mockHistory([editRow()]);
    const res = await getEdits();

    expect(JSON.stringify(res.body)).not.toContain(AUTHOR);
    expect(Object.keys(res.body.data[0]).sort()).toEqual(['byAuthor', 'editedAt', 'id', 'oldBody']);
    const sql = String(query.mock.calls[1][0]);
    expect(sql).toContain('(e.actor_id IS NOT DISTINCT FROM c.author_id) AS by_author');
    // The column may appear ONLY inside that comparison. `e.actor_id AS by_author` would pass
    // every assertion above — the mock decides what comes back, not the SQL — and would ship a
    // raw account uuid to anonymous readers.
    expect(sql).not.toMatch(/e\.actor_id(?!\s+IS NOT DISTINCT FROM)/);
    expect(sql).not.toContain('author_display_name');
  });

  it('serves kind = edit only, and never a curation row', async () => {
    // move, merge, unmerge and hide are Task 7's Maven actions. A `hide` row carries old_body,
    // so serving it here would hand back the exact text the tombstone exists to withhold — and
    // publishing who moved or merged what is a product decision nobody has made.
    mockHistory([editRow()]);
    const res = await getEdits();

    const sql = String(query.mock.calls[1][0]);
    expect(sql).toContain("kind = 'edit'");
    for (const curation of ['move', 'merge', 'unmerge', 'hide']) {
      expect(sql, curation).not.toContain(`'${curation}'`);
    }
    // And the kind is a filter, not a field: there is only one kind in the response, so
    // naming it on every entry would only invite the other four to be added beside it.
    expect(res.body.data[0]).not.toHaveProperty('kind');
  });

  it('serves no history at all for a hidden claim, and never its old body', async () => {
    const SECRET = 'the text the tombstone exists to withhold';
    mockHistory([editRow({ old_body: SECRET })], 'hidden');

    const res = await getEdits();

    // Like GET /claims/:id, a hidden claim is a tombstone rather than a 404: it is already
    // visible as one in its parent's column, so 404 here would hide nothing. What it must not
    // do is serve the body. The history query never runs.
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ data: [] });
    expect(JSON.stringify(res.body)).not.toContain(SECRET);
    expect(query.mock.calls).toHaveLength(1);
  });

  it('404s an absent claim, and a non-uuid id without touching the database', async () => {
    mockHistory([], null);
    const absent = await getEdits();
    expect(absent.status).toBe(404);
    expect(absent.body).toEqual({ error: { code: 'CLAIM_NOT_FOUND', message: 'Claim not found' } });

    for (const bad of ['not-a-uuid', '123', `${EDITED}x`]) {
      query.mockReset();
      const res = await getEdits(bad);
      expect(res.status, bad).toBe(404);
      expect(query).not.toHaveBeenCalled();
    }
  });

  it('orders newest first, so each entry after-text is the entry above it', async () => {
    // 🔴 connect.claim_edits HAS NO new_body. One row records the text BEFORE one edit, so the
    // text AFTER an entry is the oldBody of the entry above it — and, for the newest entry, the
    // claim's current body. Newest-first is what makes that reading work, and it is the same
    // order GET /posts/:id/edits serves.
    const older = editRow({ id: uuid(901), old_body: 'first draft of the claim', edited_at: '2026-04-16T12:00:00.000000+00:00' });
    const newer = editRow({ id: uuid(902), old_body: 'second draft of the claim' });
    mockHistory([newer, older]);

    const res = await getEdits();

    expect(res.body.data.map((e: { oldBody: string }) => e.oldBody)).toEqual([
      'second draft of the claim',
      'first draft of the claim',
    ]);
    expect(String(query.mock.calls[1][0])).toContain('ORDER BY e.edited_at DESC');
  });

  it('selects edited_at in the PostgREST text form, not as a Date', async () => {
    mockHistory([editRow()]);
    await getEdits();
    expect(String(query.mock.calls[1][0])).toContain("to_json(e.edited_at) #>> '{}' AS edited_at");
  });

  it('serves an empty history for a claim nobody has edited', async () => {
    mockHistory([]);
    const res = await getEdits();
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ data: [] });
  });

  it('500s with a fixed message when the history query fails, leaking no Postgres text', async () => {
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});
    query.mockResolvedValueOnce(rows([{ moderation_status: 'visible' }]));
    query.mockRejectedValueOnce(new Error('relation "connect.claim_edits" does not exist'));

    const res = await getEdits();

    // 🔴 Unlike GET /posts/:id/edits, which echoes err.message back, this is an ANONYMOUS
    // endpoint: a raw Postgres message names tables, columns and types, which turns a failed
    // read into a schema probe.
    expect(res.status).toBe(500);
    expect(res.body).toEqual({
      error: { code: 'CLAIM_EDITS_FETCH_FAILED', message: 'Could not read the edit history' },
    });
    expect(JSON.stringify(res.body)).not.toContain('relation');
    warn.mockRestore();
  });

  it('500s rather than 404s when the visibility lookup itself fails', async () => {
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});
    query.mockRejectedValueOnce(new Error('connection terminated'));

    const res = await getEdits();

    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe('CLAIM_EDITS_FETCH_FAILED');
    warn.mockRestore();
  });

  it('never writes anything', async () => {
    mockHistory([editRow()]);
    await getEdits();
    const all = query.mock.calls.map((c) => String(c[0])).join(' ');
    expect(all).not.toMatch(/\b(INSERT|UPDATE|DELETE)\b/i);
    expect(release).not.toHaveBeenCalled();
  });
});

function insertSqlWasRun(): boolean {
  return query.mock.calls.some((c) => String(c[0]).includes('INSERT'));
}
