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

  it('500s rather than 404s when the read-back finds nothing, because the rating was stored', async () => {
    query.mockResolvedValueOnce(rows([{ claim_id: RATED }]));
    query.mockResolvedValueOnce(rows([]));
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});

    const res = await rate();

    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe('CLAIM_RATING_FAILED');
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

function insertSqlWasRun(): boolean {
  return query.mock.calls.some((c) => String(c[0]).includes('INSERT'));
}
