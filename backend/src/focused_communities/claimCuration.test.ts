import { describe, it, expect, vi, beforeEach } from 'vitest';
import { readFileSync } from 'node:fs';
import express from 'express';
import request from 'supertest';
import { MAX_CLAIM_DEPTH } from './lib/utils.js';

// ── Mocks ────────────────────────────────────────────────────────────────────────────────
// The pool is a queue of canned results and every test asserts the SQL it expects to run.
// Curation is the one part of the module that rewrites rows OTHER than the one being acted on,
// so most of what these tests check is the exact statement text and its parameters: a sweep
// that splices a path wrongly, or that names a column it must not, produces perfectly
// plausible-looking rows and no error at all.
const query = vi.fn();
/**
 * All three routes check a client OUT of the pool, because connect.log_claim_edit reads
 * current_setting('fc.actor_id') and RAISES when it is unset — so set_config and the writes
 * have to share one transaction. The client's `query` is the SAME spy as the pool's, so every
 * assertion reads one ordered list of statements. `release` is its own spy, because releasing
 * on every path — commit, refusal, thrown statement — is what a max: 3 pool depends on.
 */
const release = vi.fn();
vi.mock('./config/database.js', () => ({
  pool: {
    query: (...a: unknown[]) => query(...a),
    connect: async () => ({ query: (...a: unknown[]) => query(...a), release }),
  },
}));

/** A canonical uuid. The routes refuse anything else before it reaches the database. */
const uuid = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;

const MAVEN = uuid(7);
const ADMIN = uuid(8);
const PLAIN = uuid(9);

// The engine's requireAuth, reduced to the outcomes these routes depend on.
vi.mock('../middleware/auth.js', () => ({
  requireAuth: async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const h = req.headers.authorization;
    if (!h) {
      res.status(401).json({ error: 'Missing authorization header' });
      return;
    }
    const id = { 'Bearer maven': MAVEN, 'Bearer admin': ADMIN, 'Bearer user': PLAIN }[h as string];
    Object.assign(req, { userId: id ?? PLAIN, accessToken: 'tok' });
    next();
  },
}));
vi.mock('../lib/accountMeService.js', () => ({
  getAccountMe: async (_t: string, userId: string) => ({
    id: 'should-be-overwritten',
    // 🔴 INFORM TIER ON PURPOSE for the admin. Curation is authorised by ROLE, not by tier —
    // see the guard's header — and an admin who never upgraded past Inform must still be able
    // to withdraw a claim. A requireConnected slipped in front of these routes fails here.
    tier: userId === ADMIN ? 'inform' : 'connected',
    account_standing: 'active',
    completed_onboarding: true,
    display_name: 'Abraham Lincoln',
  }),
}));

// roleService's own dependency on supabase.js process.exit()s without env vars, so stub it,
// and stub the cache it reaches for so nothing pulls lib/env.ts into this run.
vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, adminRpc: async () => ({ data: [], error: null }) }));
vi.mock('../lib/cache.js', () => ({
  cache: { get: async () => null, set: async () => {}, del: async () => {} },
}));

/** A role grant shaped like UserRoleGrant, so the REAL checkRole runs against it. */
const grant = (slug: string) => ({
  id: 'g1', role_id: 'r1', slug, name: slug, granted_at: '2026-01-01T00:00:00+00:00',
  feature_scope: 'connect', jurisdiction_geoid: null, resource_id: null, granted_by_display_name: null,
});
let rolesThrow = false;
vi.mock('../lib/roleService.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../lib/roleService.js')>()),
  getCachedUserRoles: async (userId: string) => {
    if (rolesThrow) throw new Error('upstash unreachable');
    return userId === MAVEN ? [grant('maven')] : [];
  },
}));

// requireAdmin, reduced to its two outcomes. The real one queries public.admin_users through
// supabaseAdmin, which a route file may not import (tests/integration/architecture.test.ts) —
// which is exactly why the guard reuses this middleware instead of repeating its query.
let adminThrows = false;
vi.mock('../middleware/requireAdmin.js', () => ({
  requireAdmin: async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    if (adminThrows) throw new Error('supabase unreachable');
    if ((req as express.Request & { userId?: string }).userId === ADMIN) {
      next();
      return;
    }
    res.status(403).json({ error: 'Admin access required' });
  },
}));

const { claimCurationRouter } = await import('./routes/claimCuration.js');
const app = express();
app.use(express.json());
app.use('/fc/api', claimCurationRouter);

const rows = (r: unknown[]) => ({ rows: r, rowCount: r.length });
const TS = '2026-04-17T12:00:00.123456+00:00';

const COMMUNITY = uuid(900);
const OTHER_COMMUNITY = uuid(901);
const ROOT = uuid(1);
const GRANDPARENT = uuid(50);
const OLD_PARENT = uuid(100);
const CLAIM = uuid(200);
const CHILD = uuid(210);
const NEW_PARENT = uuid(300);
const NP_PARENT = uuid(60);
const TARGET = uuid(400);

const BODY = 'The budget already covers the first two years.';

/**
 * The claim being curated, as the locking pre-read hands it back.
 *
 * depth 3 under OLD_PARENT, with a subtree two levels deeper (deepest_descendant 5). Those
 * numbers are not decoration: every splice and every depth-cap assertion below is computed
 * from them, so a route that reads the wrong column gets arithmetic that does not line up.
 */
const subject = (over: Record<string, unknown> = {}) => ({
  id: CLAIM,
  parent_claim_id: OLD_PARENT,
  side: 'supports',
  community_id: COMMUNITY,
  depth: 3,
  moderation_status: 'visible',
  merged_into_claim_id: null,
  under_moving_claim: false,
  has_hidden_ancestor: false,
  deepest_descendant: 5,
  ...over,
});

/** The destination — a new parent for a move, a target for a merge. Depth 2, so a move is -1. */
const destination = (id: string, over: Record<string, unknown> = {}) => ({
  id,
  parent_claim_id: NP_PARENT,
  side: 'opposes',
  community_id: COMMUNITY,
  depth: 2,
  moderation_status: 'visible',
  merged_into_claim_id: null,
  under_moving_claim: false,
  has_hidden_ancestor: false,
  deepest_descendant: 5,
  ...over,
});

/** A claims row as RETURNING hands it back (snake_case, ts() text timestamps). */
const returned = (over: Record<string, unknown> = {}) => ({
  id: CLAIM,
  side: 'supports',
  body: BODY,
  author_display_name: 'Demo Finch',
  moderation_status: 'visible',
  impact: '5.0000',
  rating_count: 0,
  child_supports_count: 2,
  child_opposes_count: 1,
  merged_into_claim_id: null,
  created_at: TS,
  updated_at: TS,
  // Internal, never serialized — the sweep needs the claim's NEW path to splice with.
  path: [ROOT, NEW_PARENT],
  depth: 2,
  my_rating: null,
  ...over,
});

type Caller = readonly [string, string];
const AS_MAVEN: Caller = ['Authorization', 'Bearer maven'];
const AS_ADMIN: Caller = ['Authorization', 'Bearer admin'];
const AS_CONTRIBUTOR: Caller = ['Authorization', 'Bearer user'];

const move = (claimId = CLAIM, body: unknown = { newParentId: NEW_PARENT, side: 'supports' }, auth: Caller = AS_MAVEN) =>
  request(app).post(`/fc/api/claims/${claimId}/move`).set(...auth).send(body as object);
const merge = (claimId = CLAIM, body: unknown = { targetClaimId: TARGET }, auth: Caller = AS_MAVEN) =>
  request(app).post(`/fc/api/claims/${claimId}/merge`).set(...auth).send(body as object);
const hide = (claimId = CLAIM, auth: Caller = AS_MAVEN) =>
  request(app).post(`/fc/api/claims/${claimId}/hide`).set(...auth).send({});

/**
 * The descendant sweep, as a fragment no other statement carries. `path @> ARRAY` will not do:
 * the locking pre-read uses the same predicate to find the deepest row in the subtree, and a
 * test that matched on it would assert against the wrong statement.
 */
const SWEEP = 'UPDATE connect.claims d';

/** Every statement this request sent, in order. */
const sent = () => query.mock.calls.map((c) => String(c[0]));
const find = (fragment: string | RegExp) =>
  query.mock.calls.find((c) =>
    typeof fragment === 'string' ? String(c[0]).includes(fragment) : fragment.test(String(c[0]))
  );
const sql = (fragment: string | RegExp) => String(find(fragment)![0]);
/** The left-hand side of every assignment in a SET list — what the statement actually writes. */
const setTargets = (statement: string): string[] =>
  [...(/\bSET\b([\s\S]*?)\bWHERE\b/.exec(statement)?.[1] ?? '').matchAll(/(?:^|,)\s*([a-z_]+)\s*=/g)].map(
    (m) => m[1] as string
  );
/**
 * Did this request actually write? Anchored at the START of a statement on purpose: the locking
 * pre-read ends in `FOR UPDATE OF c`, so an unanchored /\bUPDATE\b/ calls every refusal a write.
 */
const wrote = () => sent().some((s) => /^\s*(INSERT|UPDATE|DELETE)\b/i.test(s));

/** Queue BEGIN + set_config, which every one of the three transactions opens with. */
function openTransaction() {
  query.mockResolvedValueOnce(rows([])); // BEGIN
  query.mockResolvedValueOnce(rows([{ set_config: MAVEN }])); // set_config('fc.actor_id', …, true)
}

/** The happy path for a move: open, lock both rows, update the claim, sweep, commit. */
function mockMove(
  claim: Record<string, unknown> | null = subject(),
  parent: Record<string, unknown> | null = destination(NEW_PARENT),
  updated: Record<string, unknown> = {}
) {
  openTransaction();
  query.mockResolvedValueOnce(rows([claim, parent].filter(Boolean) as unknown[]));
  if (claim && parent) {
    query.mockResolvedValueOnce(rows([returned(updated)])); // the claim's own UPDATE
    query.mockResolvedValueOnce(rows([])); // the descendant sweep
  }
  query.mockResolvedValueOnce(rows([])); // COMMIT or ROLLBACK
}

/** The happy path for a merge: open, lock both rows, walk the merge chain, move the children,
 *  sweep what is below them, set merged_into_claim_id, commit. */
function mockMerge(opts: {
  claim?: Record<string, unknown> | null;
  target?: Record<string, unknown> | null;
  chain?: { reaches_claim: boolean | null; hops: number | null };
  children?: Record<string, unknown>[];
  updated?: Record<string, unknown>;
} = {}) {
  const claim = opts.claim === undefined ? subject() : opts.claim;
  const target = opts.target === undefined ? destination(TARGET) : opts.target;
  openTransaction();
  query.mockResolvedValueOnce(rows([claim, target].filter(Boolean) as unknown[]));
  if (claim && target) {
    query.mockResolvedValueOnce(rows([opts.chain ?? { reaches_claim: false, hops: 1 }]));
    const children = opts.children ?? [{ id: CHILD, path: [ROOT, NP_PARENT, TARGET], depth: 3 }];
    query.mockResolvedValueOnce(rows(children));
    if (children.length > 0) query.mockResolvedValueOnce(rows([])); // the sweep
    query.mockResolvedValueOnce(
      rows([
        returned({
          merged_into_claim_id: TARGET,
          child_supports_count: 0,
          child_opposes_count: 0,
          ...(opts.updated ?? {}),
        }),
      ])
    );
  }
  query.mockResolvedValueOnce(rows([])); // COMMIT or ROLLBACK
}

/** The happy path for a hide: open, lock the claim, update it, commit. */
function mockHide(claim: Record<string, unknown> | null = { id: CLAIM, parent_claim_id: OLD_PARENT, moderation_status: 'visible' }) {
  openTransaction();
  query.mockResolvedValueOnce(rows(claim ? [claim] : []));
  if (claim) {
    query.mockResolvedValueOnce(rows([returned({ moderation_status: 'hidden' })]));
  }
  query.mockResolvedValueOnce(rows([])); // COMMIT or ROLLBACK
}

beforeEach(() => {
  query.mockReset();
  release.mockReset();
  rolesThrow = false;
  adminThrows = false;
});

// ── The guard: Maven OR Admin, which is not a chain of two middlewares ─────────────────────

describe('requireMavenOrAdmin', () => {
  it('rejects a move, a merge and a hide from a non-maven', async () => {
    for (const res of [await move(CLAIM, undefined, AS_CONTRIBUTOR),
                       await merge(CLAIM, undefined, AS_CONTRIBUTOR),
                       await hide(CLAIM, AS_CONTRIBUTOR)]) {
      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe('MAVEN_REQUIRED');
    }
    // Never a client, never a statement: the refusal happens before the database is touched,
    // so a stranger cannot use these endpoints to learn which uuids name real claims.
    expect(query).not.toHaveBeenCalled();
    expect(release).not.toHaveBeenCalled();
  });

  it('rejects a caller with no session at all', async () => {
    for (const res of [
      await request(app).post(`/fc/api/claims/${CLAIM}/move`).send({ newParentId: NEW_PARENT, side: 'supports' }),
      await request(app).post(`/fc/api/claims/${CLAIM}/merge`).send({ targetClaimId: TARGET }),
      await request(app).post(`/fc/api/claims/${CLAIM}/hide`).send({}),
    ]) {
      expect(res.status).toBe(401);
    }
    expect(query).not.toHaveBeenCalled();
  });

  it('admits a maven who is not an admin, and an admin who is not a maven', async () => {
    // 🔴 THE WHOLE POINT OF THE LOCAL GUARD. requireRole('maven') 403s the admin and
    // requireAdmin 403s the maven, so chaining the two shared middlewares means AND in either
    // order. Both of these callers hold exactly one of the two.
    mockHide();
    const maven = await hide();
    expect(maven.status).toBe(200);

    query.mockReset();
    mockHide();
    const admin = await hide(CLAIM, AS_ADMIN);
    expect(admin.status).toBe(200);
  });

  it('asks about admin only when the caller is not already a maven', async () => {
    // Ordering is a cost decision, not a correctness one: the role grants are cached in Redis,
    // the admin_users lookup is a round trip to Supabase. Proven by making the admin lookup
    // throw — a maven must sail past it.
    adminThrows = true;
    mockHide();
    const res = await hide();
    expect(res.status).toBe(200);
  });

  it('500s rather than 403s when the role lookup itself fails', async () => {
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});
    rolesThrow = true;
    const res = await hide();
    // A database or cache that cannot answer is not a caller without the role. 403 here would
    // tell a maven they are not one, which is a different and much worse thing to be wrong
    // about — and would send them to ask for a role they already hold.
    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe('CLAIM_CURATION_FAILED');
    expect(query).not.toHaveBeenCalled();
    warn.mockRestore();
  });

  it('pins the root refusal in every write WHERE, not only in the pre-flight check', () => {
    const source = readFileSync(new URL('./routes/claimCuration.ts', import.meta.url), 'utf8');
    // The pre-flight check is what produces the 409 and the sentence; this is the belt behind
    // it. claims_root_or_child_shape would catch a moved root, but nothing in the schema stops
    // a root being HIDDEN or MERGED — so a day when the pre-flight check is refactored away,
    // these three predicates are what is left between a maven and a blanked community question.
    const updates = source
      .split(/UPDATE connect\.claims\b/)
      .slice(1)
      .map((chunk) => chunk.split('RETURNING')[0]!.split('`')[0]!);
    // Five write statements in the file: the sweep, the move, the merge's child re-parent,
    // the merge flag, the hide. If that number changes, this test is the place to think about
    // which side of the line the new one falls on.
    expect(updates).toHaveLength(5);

    const onTheCuratedClaim = updates.filter((chunk) => chunk.includes('WHERE id = $1'));
    expect(onTheCuratedClaim).toHaveLength(3);
    for (const statement of onTheCuratedClaim) {
      expect(statement).toContain('parent_claim_id IS NOT NULL');
    }
    // The other two write rows that are NOT the curated claim and must not carry it: the
    // sweep touches descendants, and the re-parent touches children — both of which have a
    // parent by definition, so the predicate would be noise there rather than a guard.
    for (const statement of updates.filter((c) => !c.includes('WHERE id = $1'))) {
      expect(statement).not.toContain('parent_claim_id IS NOT NULL');
    }
  });

  it('does not reach the service-role client, and reuses requireAdmin instead of repeating it', () => {
    const source = readFileSync(new URL('./routes/claimCuration.ts', import.meta.url), 'utf8');

    // tests/integration/architecture.test.ts scans every file under backend/src for the
    // service-role client and fails on any not on its ALLOWED list. It reads them through
    // readCode, which STRIPS COMMENTS, precisely so a file may document the rule it obeys —
    // so the assertions here are about CODE: no import of the client's module and no use of
    // the client itself. A raw `not.toContain` over the whole file would be a stricter rule
    // than the one being enforced, and would forbid the guard's own paragraph from naming
    // what it avoids.
    expect(source).not.toMatch(/from '[^']*lib\/supabase\.js'/);
    expect(source).not.toMatch(/supabaseAdmin\s*[.(]/);
    // The table as a QUERY would name it — a quoted literal — not as prose naming it.
    expect(source).not.toMatch(/['"`]admin_users['"`]/);
    // And the admin half is the shared middleware, called rather than reimplemented.
    expect(source).toContain("from '../../middleware/requireAdmin.js'");
  });
});

// ── POST /claims/:claimId/move ─────────────────────────────────────────────────────────────

describe('POST /claims/:claimId/move', () => {
  it('moves the claim, then sweeps its subtree, in that order', async () => {
    mockMove();

    const res = await move();

    expect(res.status).toBe(200);
    expect(res.body.data.id).toBe(CLAIM);

    // 🔴 ORDER IS THE CONTRACT. connect.derive_claim_position is BEFORE UPDATE OF
    // parent_claim_id, so the claim's own UPDATE is what gives it a correct path, depth and
    // community_id. The sweep splices the descendants onto THAT. Run the other way round, the
    // sweep reads a path the claim has not been given yet.
    const statements = sent();
    const own = statements.findIndex((s) => s.includes('SET parent_claim_id'));
    const sweep = statements.findIndex((s) => s.includes(SWEEP));
    expect(own).toBeGreaterThan(-1);
    expect(sweep).toBeGreaterThan(own);
    expect(statements[0]).toBe('BEGIN');
    expect(statements[statements.length - 1]).toBe('COMMIT');
    expect(release).toHaveBeenCalledTimes(1);
  });

  it('sets fc.actor_id to the acting maven inside the same transaction', async () => {
    mockMove();
    await move();

    const [statement, params] = query.mock.calls[1]!;
    expect(String(statement)).toContain("set_config('fc.actor_id'");
    // is_local = true: the setting dies with this transaction and cannot reach the next
    // request that checks out this connection and attribute that person's edit to this one.
    expect(String(statement)).toContain('true');
    expect(params).toEqual([MAVEN]);
    expect(query.mock.calls[0]![0]).toBe('BEGIN');
  });

  it('writes only parent_claim_id, side and updated_at on the moved claim', async () => {
    mockMove();
    await move();

    // 🔴 path, depth AND community_id BELONG TO THE TRIGGER. A route that sent them would be
    // claiming to decide something it does not decide. impact is GENERATED ALWAYS and an
    // UPDATE naming it is an error; rating_count, rating_sum and the two child counts belong
    // to connect.bump_claim_rating_aggregate and connect.bump_claim_child_counts.
    expect(setTargets(sql('SET parent_claim_id')).sort()).toEqual(['parent_claim_id', 'side', 'updated_at']);
    for (const owned of ['path', 'depth', 'community_id', 'impact', 'rating_count', 'rating_sum',
      'child_supports_count', 'child_opposes_count', 'moderation_status', 'merged_into_claim_id']) {
      expect(setTargets(sql('SET parent_claim_id')), owned).not.toContain(owned);
    }
  });

  it('never names parent_claim_id in the descendant sweep', async () => {
    mockMove();
    await move();

    // 🔴 THE ONE THAT LOOKS LIKE A HARMLESS OMISSION. trg_claims_derive_position has NO WHEN
    // clause: any UPDATE whose SET list merely NAMES parent_claim_id fires it, even assigning
    // the identical value, and the trigger then recomputes path, depth and community_id from
    // the parent as that parent reads AT THAT INSTANT — mid-sweep, from rows that are
    // themselves half-rewritten. A descendant's parent has not changed, so the sweep must say
    // nothing about it.
    const sweep = sql(SWEEP);
    expect(setTargets(sweep).sort()).toEqual(['depth', 'path']);
    // updated_at is absent too, and for the trigger's own reason: trg_log_claim_edit does not
    // fire for a path or depth change, so a descendant gets no history row — and a timestamp
    // that says "changed" with nothing behind it is the thing PATCH /claims/:claimId refuses.
    expect(sweep).not.toContain('updated_at');
    expect(sweep).not.toContain('parent_claim_id');
    expect(sweep).not.toContain('community_id');
    expect(sweep).not.toContain('side');
  });

  it('splices each descendant path rather than recomputing it, three levels deep', async () => {
    // The claim sits at depth 3 (path ROOT/GRANDPARENT/OLD_PARENT) and moves under NEW_PARENT
    // at depth 2, so its new path is ROOT/NEW_PARENT and its new depth is 2 — one level
    // SHALLOWER than before. A bug that recomputed from a stale parent, or that only handled
    // the first generation, survives a two-level tree and dies here.
    mockMove();
    await move();

    const [, params] = find(SWEEP)!;
    const [claimId, prefix, sliceFrom, delta] = params as unknown as [string, string[], number, number];
    expect(claimId).toBe(CLAIM);
    // The claim's NEW path, read back from its own UPDATE, with the claim itself appended.
    expect(prefix).toEqual([ROOT, NEW_PARENT, CLAIM]);
    // Postgres array slices are 1-indexed: the first `oldDepth + 1` elements of a descendant's
    // path are the claim's old ancestors plus the claim, and the tail starts after them.
    expect(sliceFrom).toBe(5); // oldDepth 3 + 2
    expect(delta).toBe(-1); // newDepth 2 − oldDepth 3

    // Apply those parameters the way Postgres would, to a three-level subtree.
    const splice = (path: string[], depth: number) => ({
      path: [...prefix, ...path.slice(sliceFrom - 1)],
      depth: depth + delta,
    });
    expect(splice([ROOT, GRANDPARENT, OLD_PARENT, CLAIM], 4)).toEqual({
      path: [ROOT, NEW_PARENT, CLAIM],
      depth: 3,
    });
    expect(splice([ROOT, GRANDPARENT, OLD_PARENT, CLAIM, CHILD], 5)).toEqual({
      path: [ROOT, NEW_PARENT, CLAIM, CHILD],
      depth: 4,
    });
    // cardinality(path) = depth is a CHECK constraint (claims_root_or_child_shape). If the
    // splice and the arithmetic ever disagree, the database refuses the whole sweep.
    const subtree: [string[], number][] = [
      [[ROOT, GRANDPARENT, OLD_PARENT, CLAIM], 4],
      [[ROOT, GRANDPARENT, OLD_PARENT, CLAIM, CHILD], 5],
    ];
    for (const [path, depth] of subtree) {
      const out = splice(path, depth);
      expect(out.path).toHaveLength(out.depth);
    }
  });

  it('rejects moving a claim under itself', async () => {
    openTransaction();
    query.mockResolvedValueOnce(rows([subject()]));
    query.mockResolvedValueOnce(rows([])); // ROLLBACK

    const res = await move(CLAIM, { newParentId: CLAIM, side: 'supports' });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('MOVE_WOULD_CYCLE');
    expect(wrote()).toBe(false);
  });

  it('rejects moving a claim under its own descendant', async () => {
    // claims_not_own_ancestor is the backstop; this is the sentence a maven gets instead of a
    // constraint violation. A ring is unreachable from the root and every recursive walk over
    // it either hangs or recurses, so it has to be refused BEFORE any write.
    mockMove(subject(), destination(NEW_PARENT, { under_moving_claim: true }));

    const res = await move();

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('MOVE_WOULD_CYCLE');
    expect(wrote()).toBe(false);
    expect(sent()).toContain('ROLLBACK');
    expect(release).toHaveBeenCalledTimes(1);
  });

  it('rejects a move into another community', async () => {
    // derive_claim_position copies community_id from the parent, so this would silently
    // relocate the claim AND its whole subtree into a question it was never written about.
    mockMove(subject(), destination(NEW_PARENT, { community_id: OTHER_COMMUNITY }));

    const res = await move();

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CROSS_COMMUNITY');
    expect(wrote()).toBe(false);
  });

  it('refuses to move a root claim', async () => {
    // A root is the community's question, seeded by trg_communities_seed_root_claim, not
    // anyone's contribution — and moving one violates claims_root_or_child_shape outright.
    mockMove(subject({ parent_claim_id: null, side: null, depth: 0 }));

    const res = await move();

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('ROOT_NOT_CURATABLE');
    expect(wrote()).toBe(false);
  });

  it('422s a move that would push the subtree past the depth cap', async () => {
    // newParent.depth + 1 + (deepest − claim.depth) must stay within the cap. The subject's
    // subtree reaches two levels below it, so a parent at the cap − 2 is the first refusal.
    mockMove(
      subject({ depth: 3, deepest_descendant: 5 }),
      destination(NEW_PARENT, { depth: MAX_CLAIM_DEPTH - 2 })
    );

    const res = await move();

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('MAX_DEPTH_REACHED');
    // No number the reader cannot act on, matching routes/claimWrites.ts.
    expect(res.body.error.message).toBe('This discussion has reached its maximum depth');
    expect(res.body.error.message).not.toMatch(/\d/);
    expect(wrote()).toBe(false);
  });

  it('422s a childless claim moved under a parent already at the cap', async () => {
    // 🔴 THE FLOOR IN THE CAP CHECK, WHICH NOTHING ELSE EXERCISES. `deepest_descendant` is
    // COALESCE(MAX(depth), 0), so a claim with no subtree reports 0 — and a check that used
    // that number raw would measure this claim as if it sat at the root and wave through a
    // move that puts it at depth 51. Floored at the claim's own depth, it refuses.
    mockMove(
      subject({ depth: 3, deepest_descendant: 0 }),
      destination(NEW_PARENT, { depth: MAX_CLAIM_DEPTH })
    );

    const res = await move();

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('MAX_DEPTH_REACHED');
    expect(wrote()).toBe(false);
  });

  it('moves updated_at only when the parent or side actually changed', async () => {
    mockMove();
    await move();

    // trg_log_claim_edit is AFTER UPDATE … WHEN (… OR OLD.parent_claim_id IS DISTINCT FROM
    // NEW.parent_claim_id OR OLD.side IS DISTINCT FROM NEW.side), so restating a claim's
    // current parent and side writes no history row. connect.claims has no touch trigger, so
    // an unconditional now() here would move the one timestamp a reader uses to tell a
    // changed claim from an untouched one, with nothing behind it. In SET, the unqualified
    // column on the right-hand side is the OLD value, which is what makes the test work.
    const update = sql('SET parent_claim_id');
    expect(update).toMatch(/updated_at = CASE WHEN parent_claim_id IS DISTINCT FROM/);
    expect(update).toMatch(/OR side IS DISTINCT FROM/);
  });

  it('allows a move that lands exactly on the depth cap', async () => {
    // The boundary, from the other side: deepest descendant lands on MAX_CLAIM_DEPTH itself.
    mockMove(
      subject({ depth: 3, deepest_descendant: 5 }),
      destination(NEW_PARENT, { depth: MAX_CLAIM_DEPTH - 3 })
    );

    const res = await move();

    expect(res.status).toBe(200);
    expect(wrote()).toBe(true);
  });

  it('404s an absent claim and an absent new parent, and tells them apart', async () => {
    mockMove(null, null);
    let res = await move();
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('CLAIM_NOT_FOUND');
    expect(wrote()).toBe(false);

    query.mockReset();
    mockMove(subject(), null);
    res = await move();
    expect(res.status).toBe(404);
    // A maven is a trusted role, so the two are told apart: "which of the two ids was wrong?"
    // is the first question they will ask, and there is nothing to withhold from them.
    expect(res.body.error.code).toBe('NEW_PARENT_NOT_FOUND');
    expect(wrote()).toBe(false);
  });

  it('refuses a withdrawn, unreachable or superseded new parent', async () => {
    for (const [over, code] of [
      [{ moderation_status: 'hidden' }, 'NEW_PARENT_NOT_VISIBLE'],
      [{ has_hidden_ancestor: true }, 'NEW_PARENT_NOT_VISIBLE'],
      [{ merged_into_claim_id: uuid(555) }, 'NEW_PARENT_MERGED'],
    ] as const) {
      query.mockReset();
      mockMove(subject(), destination(NEW_PARENT, over));
      const res = await move();
      // The same three states POST /claims/:parentId/children refuses a new child under, for
      // the same reason: a claim beneath a withdrawn or unreachable parent is text no reader
      // will ever meet, and here it would be a whole subtree rather than one claim.
      expect(res.status, code).toBe(409);
      expect(res.body.error.code).toBe(code);
      expect(wrote()).toBe(false);
    }
  });

  it('rejects a malformed id, side or new parent before opening a transaction', async () => {
    for (const [claimId, body] of [
      ['not-a-uuid', { newParentId: NEW_PARENT, side: 'supports' }],
      [CLAIM, { newParentId: 'nope', side: 'supports' }],
      [CLAIM, { side: 'supports' }],
      [CLAIM, { newParentId: NEW_PARENT, side: 'Supports' }],
      [CLAIM, { newParentId: NEW_PARENT, side: 'neutral' }],
      [CLAIM, { newParentId: NEW_PARENT }],
    ] as const) {
      query.mockReset();
      release.mockReset();
      const res = await move(claimId as string, body);
      expect([400, 404], JSON.stringify(body)).toContain(res.status);
      expect(query).not.toHaveBeenCalled();
      expect(release).not.toHaveBeenCalled();
    }
  });

  it('locks both rows in id order, under one FOR UPDATE', async () => {
    mockMove();
    await move();

    const lock = sql('FOR UPDATE');
    // Two mavens curating the same corner of a tree at once take the same two row locks; a
    // deterministic order is what keeps that from deadlocking.
    expect(lock).toContain('ORDER BY c.id');
    expect(lock).toContain('FOR UPDATE OF c');
  });

  it('serializes the Claim shape and no internal field', async () => {
    mockMove();
    const res = await move();

    expect(res.body).toEqual({
      data: {
        id: CLAIM,
        side: 'supports',
        body: BODY,
        authorPseudonym: 'Demo Finch',
        impact: 5,
        ratingCount: 0,
        childSupports: 2,
        childOpposes: 1,
        isHidden: false,
        mergedInto: null,
        createdAt: TS,
        updatedAt: TS,
        myRating: null,
      },
    });
    const serialized = JSON.stringify(res.body);
    for (const leaked of ['author_id', 'community_id', '"path"', 'depth', 'moderation_status',
      'child_supports_count', 'merged_into_claim_id', MAVEN, 'Abraham Lincoln']) {
      expect(serialized, leaked).not.toContain(leaked);
    }
  });

  it('serves the curator their own rating back rather than nulling it', async () => {
    // myRating is the one per-caller field in a Claim. A maven who rated a claim and then
    // moved it must not get a body back saying they never rated it — a client that replaces
    // its local copy with this response would wipe the rating from the UI.
    mockMove(subject(), destination(NEW_PARENT), { my_rating: 8 });

    const res = await move();

    expect(res.body.data.myRating).toBe(8);
    const update = sql('SET parent_claim_id');
    expect(update).toContain('connect.claim_ratings');
    expect(update).toContain('AS my_rating');
    // Scoped to the CALLER's row, never to whoever happens to come back first.
    expect(update).toMatch(/r\.user_id = \$\d+::uuid/);
  });

  it('500s with a fixed message when a statement fails, and still releases the client', async () => {
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});
    openTransaction();
    query.mockResolvedValueOnce(rows([subject(), destination(NEW_PARENT)]));
    query.mockRejectedValueOnce(
      new Error('new row for relation "claims" violates check constraint "claims_depth_within_cap"')
    );
    query.mockResolvedValueOnce(rows([])); // ROLLBACK

    const res = await move();

    expect(res.status).toBe(500);
    expect(res.body).toEqual({
      error: { code: 'CLAIM_MOVE_FAILED', message: 'Could not move the claim' },
    });
    expect(JSON.stringify(res.body)).not.toContain('constraint');
    expect(sent()).toContain('ROLLBACK');
    expect(release).toHaveBeenCalledTimes(1);
    warn.mockRestore();
  });
});

// ── POST /claims/:claimId/merge ────────────────────────────────────────────────────────────

describe('POST /claims/:claimId/merge', () => {
  it('re-parents the merged claim children onto the target', async () => {
    mockMerge();

    const res = await merge();

    expect(res.status).toBe(200);
    const reparent = find('WHERE parent_claim_id = $1')!;
    expect(String(reparent[0])).toContain('SET parent_claim_id');
    expect(reparent[1]).toEqual([CLAIM, TARGET]);
    // `side` is NOT in the SET list: a child that opposed the merged claim opposes the target.
    // The merge says the two claims are the same point, so the arguments against it still are.
    expect(setTargets(String(reparent[0])).sort()).toEqual(['parent_claim_id', 'updated_at']);
  });

  it('sweeps what is below the re-parented children, and not the children themselves', async () => {
    // 🔴 THE SUBTLE ONE. The re-parent above fires trg_claims_derive_position for each child,
    // which gives it the target's path — so by the time the sweep runs, a child's path no
    // longer contains the merged claim and `path @> ARRAY[claim]` passes straight over it.
    // Sweeping them again with the same prefix would splice their already-correct path a
    // second time. A grandchild's path DOES still contain the merged claim, and that is
    // exactly the set this statement is for.
    mockMerge();
    await merge();

    const [, params] = find(SWEEP)!;
    const [claimId, prefix, sliceFrom, delta] = params as unknown as [string, string[], number, number];
    expect(claimId).toBe(CLAIM);
    // The children's NEW path, read back from the re-parent — target.path || target.
    expect(prefix).toEqual([ROOT, NP_PARENT, TARGET]);
    expect(sliceFrom).toBe(5); // claim.depth 3 + 2
    expect(delta).toBe(-1); // target.depth 2 − claim.depth 3

    const splice = (path: string[], depth: number) => ({
      path: [...prefix, ...path.slice(sliceFrom - 1)],
      depth: depth + delta,
    });
    // A grandchild of the merged claim, three levels in.
    expect(splice([ROOT, GRANDPARENT, OLD_PARENT, CLAIM, CHILD], 5)).toEqual({
      path: [ROOT, NP_PARENT, TARGET, CHILD],
      depth: 4,
    });
    expect(setTargets(sql(SWEEP)).sort()).toEqual(['depth', 'path']);
    expect(sql(SWEEP)).not.toContain('parent_claim_id');
  });

  it('runs no sweep at all when the merged claim is childless', async () => {
    mockMerge({ children: [] });
    const res = await merge();
    expect(res.status).toBe(200);
    expect(find(SWEEP)).toBeUndefined();
  });

  it('discards the merged claim ratings by leaving them exactly where they are', async () => {
    mockMerge();
    await merge();

    // 🔴 THIS REQUIRES NO CODE, AND THAT IS THE TEST. connect.bump_claim_rating_aggregate keys
    // on claim_ratings.claim_id, which a merge does not touch, so the ratings stay on the
    // merged claim and the target's aggregate does not move. "Discards" describes the ABSENCE
    // of a transfer. Writing rating_count or rating_sum here would fight the trigger and trip
    // claims_rating_totals_coherent; writing impact is an error outright, since it is
    // GENERATED ALWAYS … STORED.
    const all = sent().join('\n');
    // READING them is fine and necessary — RETURNING serves rating_count back, and the
    // correlated subselect reads this curator's own rating out of connect.claim_ratings.
    // WRITING either table or either column is the bug, so each assertion is about an
    // assignment rather than a mention.
    expect(all).not.toMatch(/(INSERT INTO|UPDATE)\s+connect\.claim_ratings/i);
    expect(all).not.toMatch(/\brating_count\s*=/);
    expect(all).not.toMatch(/\brating_sum\b/);
    expect(all).not.toMatch(/\bimpact\s*=/);
    expect(all).not.toMatch(/\bchild_(supports|opposes)_count\s*=/);
  });

  it('sets merged_into_claim_id and deletes nothing', async () => {
    mockMerge();
    const res = await merge();

    const flag = find('SET merged_into_claim_id')!;
    expect(flag[1]).toEqual([CLAIM, TARGET, MAVEN]);
    expect(setTargets(String(flag[0])).sort()).toEqual(['merged_into_claim_id', 'updated_at']);
    // Nothing in the argument tree is ever deleted — connect.claims carries no DELETE grant
    // for any role this process can be. A merged claim keeps its id, its URL, its body and
    // its history, and the client is handed the target so it can offer the reader the claim
    // that now carries this argument.
    expect(sent().join('\n')).not.toMatch(/\bDELETE\b/i);
    expect(res.body.data.mergedInto).toBe(TARGET);
    expect(res.body.data.body).toBe(BODY);
  });

  it('rejects merging a claim into its own descendant', async () => {
    mockMerge({ target: destination(TARGET, { under_moving_claim: true }) });

    const res = await merge();

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('MERGE_WOULD_CYCLE');
    expect(wrote()).toBe(false);
  });

  it('rejects merging a claim into itself', async () => {
    openTransaction();
    query.mockResolvedValueOnce(rows([subject()]));
    query.mockResolvedValueOnce(rows([])); // ROLLBACK

    const res = await merge(CLAIM, { targetClaimId: CLAIM });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('MERGE_WOULD_CYCLE');
    expect(wrote()).toBe(false);
  });

  it('rejects a merge that closes a loop through merged_into_claim_id', async () => {
    // 🔴 A SECOND, SEPARATE CHECK. claims_not_own_ancestor constrains PARENTAGE only. Nothing
    // in the schema constrains merged_into_claim_id, so A→B→A is schema-possible today and
    // every read that follows the chain hangs or recurses once it exists.
    mockMerge({ chain: { reaches_claim: true, hops: 2 } });

    const res = await merge();

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('MERGE_WOULD_CYCLE');
    expect(wrote()).toBe(false);
  });

  it('bounds the merge-chain walk and refuses rather than hanging on one that already exists', async () => {
    mockMerge({ chain: { reaches_claim: false, hops: MAX_CLAIM_DEPTH } });

    const res = await merge();

    // Hitting the ceiling means the walk could not prove the chain terminates. An unbounded
    // walk over a cycle that is already there is a hung request, so the ceiling is a refusal.
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('MERGE_CHAIN_TOO_LONG');
    expect(wrote()).toBe(false);

    const walk = sql('WITH RECURSIVE');
    expect(walk).toContain('merged_into_claim_id');
    expect(find('WITH RECURSIVE')![1]).toEqual([CLAIM, TARGET, MAX_CLAIM_DEPTH]);
    // 🔴 THE BOUND IS IN THE RECURSION, NOT ONLY IN THE PARAMETER LIST. Passing the ceiling
    // and not applying it is a statement that loops forever inside Postgres against an
    // existing cycle, which is a hung connection out of a max: 3 pool rather than a 409.
    expect(walk).toContain('WHERE chain.hops < $3::int');
  });

  it('allows a target that is itself merged into something else', async () => {
    // Task 3 ruled that the merge target may be absent from the payload, so a chain is a
    // supported shape: the client follows it a hop at a time. Only a LOOP is refused.
    mockMerge({ target: destination(TARGET, { merged_into_claim_id: uuid(777) }),
                chain: { reaches_claim: false, hops: 2 } });

    const res = await merge();

    expect(res.status).toBe(200);
    expect(res.body.data.mergedInto).toBe(TARGET);
  });

  it('rejects a merge across communities', async () => {
    mockMerge({ target: destination(TARGET, { community_id: OTHER_COMMUNITY }) });

    const res = await merge();

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CROSS_COMMUNITY');
    expect(wrote()).toBe(false);
  });

  it('refuses to merge a root claim, or to merge anything into one', async () => {
    mockMerge({ claim: subject({ parent_claim_id: null, side: null, depth: 0 }) });
    let res = await merge();
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('ROOT_NOT_CURATABLE');
    expect(wrote()).toBe(false);

    query.mockReset();
    // A merge says "this point is already made, better, over there". The root is the
    // community's QUESTION, not a point anyone made, so it cannot carry someone else's.
    mockMerge({ target: destination(TARGET, { parent_claim_id: null, side: null, depth: 0 }) });
    res = await merge();
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('ROOT_NOT_CURATABLE');
    expect(wrote()).toBe(false);
  });

  it('refuses a withdrawn or unreachable target', async () => {
    for (const over of [{ moderation_status: 'hidden' }, { has_hidden_ancestor: true }]) {
      query.mockReset();
      mockMerge({ target: destination(TARGET, over) });
      const res = await merge();
      // The merge would redirect every reader of this claim to a tombstone, and would hang
      // the re-parented children under an ancestor nobody can read past.
      expect(res.status, JSON.stringify(over)).toBe(409);
      expect(res.body.error.code).toBe('MERGE_TARGET_NOT_VISIBLE');
      expect(wrote()).toBe(false);
    }
  });

  it('refuses to merge a claim that is already merged', async () => {
    mockMerge({ claim: subject({ merged_into_claim_id: uuid(888) }) });

    const res = await merge();

    // Re-pointing an existing merge is not a merge: the children were re-parented onto the
    // first target when it happened, so a second one would move nothing and would quietly
    // strand readers mid-chain. Undo it first — connect.claim_edits records an `unmerge` kind
    // for exactly that — and the 409 names where this claim currently points.
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CLAIM_ALREADY_MERGED');
    expect(res.body.error.mergedInto).toBe(uuid(888));
    expect(wrote()).toBe(false);
  });

  it('422s a merge whose transplant would breach the depth cap', async () => {
    // A merge lifts the subtree one level MORE than the equivalent move does: a child of the
    // merged claim becomes a child of the target, so the shift is target.depth − claim.depth
    // rather than (newParent.depth + 1) − claim.depth. The subject reaches two levels below
    // itself, so a target at the cap − 1 puts its deepest grandchild one past.
    mockMerge({
      claim: subject({ depth: 3, deepest_descendant: 5 }),
      target: destination(TARGET, { depth: MAX_CLAIM_DEPTH - 1 }),
    });

    const res = await merge();

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('MAX_DEPTH_REACHED');
    expect(wrote()).toBe(false);
  });

  it('allows a merge that lands exactly on the depth cap', async () => {
    // The boundary from the other side, and the reason the two routes cannot share a number:
    // the same target depth that refuses a move accepts a merge.
    mockMerge({
      claim: subject({ depth: 3, deepest_descendant: 5 }),
      target: destination(TARGET, { depth: MAX_CLAIM_DEPTH - 2 }),
    });

    const res = await merge();

    expect(res.status).toBe(200);
    expect(wrote()).toBe(true);
  });

  it('404s an absent claim and an absent target, and tells them apart', async () => {
    mockMerge({ claim: null, target: null });
    let res = await merge();
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('CLAIM_NOT_FOUND');

    query.mockReset();
    mockMerge({ target: null });
    res = await merge();
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('MERGE_TARGET_NOT_FOUND');
    expect(wrote()).toBe(false);
  });

  it('rejects a malformed id or target before opening a transaction', async () => {
    for (const [claimId, body] of [
      ['not-a-uuid', { targetClaimId: TARGET }],
      [CLAIM, { targetClaimId: 'nope' }],
      [CLAIM, {}],
      [CLAIM, { targetClaimId: 42 }],
    ] as const) {
      query.mockReset();
      const res = await merge(claimId as string, body);
      expect([400, 404], JSON.stringify(body)).toContain(res.status);
      expect(query).not.toHaveBeenCalled();
    }
  });

  it('500s with a fixed message when a statement fails, and still releases the client', async () => {
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});
    openTransaction();
    query.mockResolvedValueOnce(rows([subject(), destination(TARGET)]));
    query.mockRejectedValueOnce(new Error('deadlock detected'));
    query.mockResolvedValueOnce(rows([])); // ROLLBACK

    const res = await merge();

    expect(res.status).toBe(500);
    expect(res.body).toEqual({
      error: { code: 'CLAIM_MERGE_FAILED', message: 'Could not merge the claim' },
    });
    expect(JSON.stringify(res.body)).not.toContain('deadlock');
    expect(release).toHaveBeenCalledTimes(1);
    warn.mockRestore();
  });
});

// ── POST /claims/:claimId/hide ─────────────────────────────────────────────────────────────

describe('POST /claims/:claimId/hide', () => {
  it('hides a claim without touching its children', async () => {
    mockHide();

    const res = await hide();

    expect(res.status).toBe(200);
    // 🔴 THE ASYMMETRY IS DELIBERATE AND BOTH HALVES ARE RIGHT. An EXISTING child of a hidden
    // claim stays in the tree and stays readable — the hidden claim renders as a tombstone, so
    // the structure survives and only the removed text is withheld. A NEW child may not be
    // added beneath it (routes/claimWrites.ts), because a claim nobody can read is not
    // something anyone can argue with. Do not "fix" this into symmetry in either direction.
    const all = sent().join('\n');
    expect(all).not.toContain('path @>');
    expect(all).not.toContain('parent_claim_id =');
    const update = sql('SET moderation_status');
    expect(setTargets(update).sort()).toEqual(['moderation_status', 'updated_at']);
    expect(update).toMatch(/WHERE[\s\S]*id = \$1/);
  });

  it('takes FOR UPDATE on the claim being hidden', async () => {
    mockHide();
    await hide();

    // What hide owes R33: POST /claims/:parentId/children locks the PARENT, not the ancestors,
    // so a child inserted under a descendant in the instant before this commits still lands.
    // This lock closes the common case — a child inserted directly under the claim being
    // hidden — and the residual window is deliberately left open rather than closed by
    // locking the subtree, which would serialize every write in the community.
    expect(sql('FOR UPDATE')).toContain('FOR UPDATE OF c');
    const statements = sent();
    expect(statements.indexOf(sql('FOR UPDATE'))).toBeLessThan(statements.indexOf(sql('SET moderation_status')));
  });

  it('refuses to hide a root claim', async () => {
    // Hiding a root would blank the question the whole page is about.
    mockHide({ id: CLAIM, parent_claim_id: null, moderation_status: 'visible' });

    const res = await hide();

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('ROOT_NOT_CURATABLE');
    expect(wrote()).toBe(false);
  });

  it('is idempotent, and manufactures no history on a second hide', async () => {
    // trg_log_claim_edit is AFTER UPDATE … WHEN (… OR OLD.moderation_status IS DISTINCT FROM
    // NEW.moderation_status), so re-hiding writes no history row. The route agrees with the
    // trigger rather than 409ing: a client retrying a request it is not sure landed gets the
    // tombstone back, and cannot manufacture a moderation record by sending it twice. The CASE
    // on updated_at is the other half of that agreement — connect.claims has no touch trigger.
    mockHide({ id: CLAIM, parent_claim_id: OLD_PARENT, moderation_status: 'hidden' });

    const res = await hide();

    expect(res.status).toBe(200);
    expect(res.body.data.isHidden).toBe(true);
    expect(sql('SET moderation_status')).toMatch(
      /updated_at\s*=\s*CASE WHEN moderation_status IS DISTINCT FROM/
    );
  });

  it('serves the tombstone: no body, no pseudonym, counts intact', async () => {
    mockHide();
    const res = await hide();

    expect(res.body.data).toMatchObject({
      id: CLAIM,
      body: '',
      authorPseudonym: null,
      isHidden: true,
      childSupports: 2,
      childOpposes: 1,
    });
    expect(JSON.stringify(res.body)).not.toContain(BODY);
  });

  it('404s an absent claim, and a non-uuid id without opening a transaction', async () => {
    mockHide(null);
    const res = await hide();
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('CLAIM_NOT_FOUND');

    for (const bad of ['not-a-uuid', '123', `${CLAIM}x`]) {
      query.mockReset();
      release.mockReset();
      const bogus = await hide(bad);
      expect(bogus.status, bad).toBe(404);
      expect(query).not.toHaveBeenCalled();
      expect(release).not.toHaveBeenCalled();
    }
  });

  it('500s with a fixed message when the UPDATE fails, and still releases the client', async () => {
    const warn = vi.spyOn(console, 'error').mockImplementation(() => {});
    openTransaction();
    query.mockResolvedValueOnce(rows([{ id: CLAIM, parent_claim_id: OLD_PARENT, moderation_status: 'visible' }]));
    query.mockRejectedValueOnce(new Error('relation "connect.claims" does not exist'));
    query.mockResolvedValueOnce(rows([])); // ROLLBACK

    const res = await hide();

    expect(res.status).toBe(500);
    expect(res.body).toEqual({
      error: { code: 'CLAIM_HIDE_FAILED', message: 'Could not hide the claim' },
    });
    expect(JSON.stringify(res.body)).not.toContain('relation');
    expect(release).toHaveBeenCalledTimes(1);
    warn.mockRestore();
  });
});

// ── History ────────────────────────────────────────────────────────────────────────────────

describe('curation history', () => {
  it('records move, merge and hide against the acting maven, and writes no history row itself', async () => {
    for (const [name, setup, run] of [
      ['move', mockMove, move],
      ['merge', mockMerge, merge],
      ['hide', mockHide, hide],
    ] as const) {
      query.mockReset();
      (setup as () => void)();
      const res = await (run as () => Promise<{ status: number }>)();
      expect(res.status, name).toBe(200);

      // connect.log_claim_edit writes the row — kinds move, merge and hide — reading the actor
      // out of fc.actor_id and RAISING when it is unset. The route's whole contribution is
      // naming the actor in the same transaction as the write.
      const [statement, params] = query.mock.calls[1]!;
      expect(String(statement), name).toContain("set_config('fc.actor_id'");
      expect(params, name).toEqual([MAVEN]);
      expect(sent().join('\n'), name).not.toContain('claim_edits');
      // And it lands BEFORE the first write, not after it.
      const firstWrite = sent().findIndex((s) => /^\s*UPDATE\b/i.test(s));
      expect(firstWrite, name).toBeGreaterThan(1);
    }
  });

  it('attributes the write to an admin curator when that is who called', async () => {
    mockHide();
    await hide(CLAIM, AS_ADMIN);
    expect(query.mock.calls[1]![1]).toEqual([ADMIN]);
  });
});
