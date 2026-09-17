import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// WHY THIS FILE EXISTS.
//
// ADR 0007 §4 says a member's stances are readable only by that member, with
// Empowered accounts the deliberate carve-out. §5 records that the audit is what
// makes the floor verifiable — but an audit tells you afterwards. This is the
// part that says no beforehand, and until it existed §4 had NOTHING standing
// behind it.
//
// The exposure is not hypothetical and it is not guarded by the database.
// `inform.compass_responses` has RLS with an owner-only policy, but production
// authenticates as `ev_api`, which holds rolbypassrls — and these reads go
// through `supabaseAdmin` (service role), which bypasses RLS too. So on this
// path the ROUTE is the enforcement, exactly as compass.answers.scope.test.ts
// documents for the answers endpoints.
//
// `visibility` defaults to 'private'. getPublicProfile is served UNAUTHENTICATED
// for an arbitrary :userId. If that read ever loses its
// `.eq('visibility','public')`, an anonymous caller reads that user's private
// stances — political opinions, GDPR Art. 9 special-category data — and nothing
// underneath it says no.
//
// Three reads carry the filter today (profileService, and two in
// candidateService). These tests pin all three, and pin that the OWNER path
// deliberately does not filter, so a future "simplification" that unifies the
// two paths has to fail here rather than in production.
// ---------------------------------------------------------------------------

const USER = '11111111-1111-4111-8111-111111111111';
const SLUG = 'a-candidate';

/** Every `.eq(column, value)` any builder received, in order. */
const eqCalls = vi.hoisted(() => [] as Array<{ table: string; col: string; val: unknown }>);

/**
 * A chainable stub matching the supabase-js surface these services use.
 *
 * One mutable object, like the precedent: the services await each query before
 * starting the next, so `table` is always the one currently being built. The
 * stance read is the exception worth noting — profileService stores the builder,
 * applies `.eq('visibility','public')` to it in a LATER statement, then awaits
 * it. Nothing calls `.from()` in between, so the recorded table is still right,
 * and `then` is what makes the stored builder awaitable.
 */
const makeClient = vi.hoisted(() => () => {
  const state = { table: '' };
  const rows: Record<string, unknown> = {
    users: { id: '11111111-1111-4111-8111-111111111111', display_name: 'A User', created_at: '2026-01-01T00:00:00Z' },
    connected_profiles: { user_id: '11111111-1111-4111-8111-111111111111', display_name: 'A User', total_xp: 0, gem_balance_yellow: 0, gem_balance_blue: 0, gem_balance_red: 0, location_consent: false },
    // is_active true so the tier derives to `empowered` and the stance read is reached.
    empowered_profiles: { user_id: '11111111-1111-4111-8111-111111111111', legal_name: 'A Candidate', candidate_page_slug: 'a-candidate', is_active: true, empowered_at: '2026-01-01T00:00:00Z', demoted_at: null, politician_id: null },
  };

  const builder: Record<string, unknown> = {};
  const pass = () => builder;
  builder.schema = pass;
  builder.from = (t: string) => { state.table = t; return builder; };
  builder.select = pass;
  builder.in = pass;
  builder.is = pass;
  builder.order = pass;
  builder.limit = pass;
  builder.eq = (col: string, val: unknown) => { eqCalls.push({ table: state.table, col, val }); return builder; };
  builder.maybeSingle = () => Promise.resolve({ data: rows[state.table] ?? null, error: null });
  builder.single = () => Promise.resolve({ data: rows[state.table] ?? null, error: null });
  // Awaiting the builder itself — how the stance read terminates.
  builder.then = (res: (v: unknown) => unknown, rej?: (e: unknown) => unknown) =>
    Promise.resolve({ data: [], error: null }).then(res, rej);
  return builder;
});

vi.mock('./supabase.js', () => ({
  supabaseAdmin: makeClient(),
  adminRpc: vi.fn().mockResolvedValue({ data: { level: 1 }, error: null }),
  supabaseAnon: {},
  createUserClient: vi.fn(),
  requestDb: vi.fn(),
}));

vi.mock('./db.js', () => ({ pool: { query: vi.fn().mockResolvedValue({ rows: [] }) } }));

// Must be NON-EMPTY: candidateService guards its stance read with
// `if (selectedTopicIds.length > 0)`, so an empty list skips the very read this
// file exists to pin. An earlier draft returned [] and the candidate test passed
// without ever reaching a stance query.
vi.mock('./compassService.js', () => ({
  getSelectedTopics: vi.fn().mockResolvedValue(['22222222-2222-4222-8222-222222222222']),
}));

vi.mock('./cache.js', () => ({
  // MUST resolve null, not undefined: getCandidateBySlug does
  // `if (cached !== null) return cached`, so undefined is treated as a cache HIT
  // and the function returns before any stance read. That made the test pass
  // while exercising nothing.
  cache: { get: vi.fn().mockResolvedValue(null), set: vi.fn(), del: vi.fn(), clear: vi.fn() },
}));

const STANCE_TABLES = ['compass_responses', 'compass_responses_current', 'compass_responses_effective'];

/** Did any read of a stance relation carry the public-visibility predicate? */
function stanceReadFilteredToPublic() {
  return eqCalls.some((c) => STANCE_TABLES.includes(c.table) && c.col === 'visibility' && c.val === 'public');
}

/** Was a stance relation read at all? Guards against a vacuous pass. */
function stanceRelationWasRead() {
  return eqCalls.some((c) => STANCE_TABLES.includes(c.table));
}

beforeEach(() => { eqCalls.length = 0; });

describe('stance visibility gate — ADR 0007 §4', () => {
  it('getPublicProfile filters stances to visibility=public', async () => {
    const { getPublicProfile } = await import('./profileService.js');
    await getPublicProfile(USER);

    // A vacuous pass would be worse than a failure: if the stance read is never
    // reached, "no unfiltered read happened" is true and meaningless.
    expect(stanceRelationWasRead()).toBe(true);
    expect(stanceReadFilteredToPublic()).toBe(true);
  });

  it('getOwnerProfile does NOT filter — the owner sees their own private stances', async () => {
    const { getOwnerProfile } = await import('./profileService.js');
    await getOwnerProfile(USER, 'someone@example.com');

    expect(stanceRelationWasRead()).toBe(true);
    // This is the asymmetry the gate protects. Unifying the two paths to remove
    // a conditional would break this test, which is the point of pinning it.
    expect(stanceReadFilteredToPublic()).toBe(false);
  });

  it('getCandidateBySlug filters stances to visibility=public', async () => {
    const { getCandidateBySlug } = await import('./candidateService.js');
    await getCandidateBySlug(SLUG);

    expect(stanceRelationWasRead()).toBe(true);
    expect(stanceReadFilteredToPublic()).toBe(true);
  });

  it('getCandidateAnswers filters stances to visibility=public', async () => {
    const { getCandidateAnswers } = await import('./candidateService.js');
    await getCandidateAnswers(SLUG, ['22222222-2222-4222-8222-222222222222'], new Set());

    expect(stanceRelationWasRead()).toBe(true);
    expect(stanceReadFilteredToPublic()).toBe(true);
  });
});
