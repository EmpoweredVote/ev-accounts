import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// WHY THIS FILE EXISTS.
//
// GET /api/account/profile/:userId is unauthenticated and takes an ARBITRARY
// userId. For an Empowered user it returns compass_answers read from
// inform.compass_responses_effective through supabaseAdmin (service role), which
// BYPASSES RLS — so the service, not the database, is what confines what a
// stranger sees.
//
// compass_responses_effective.visibility defaults to 'private' and is flipped to
// 'public' only by the empowerment RPC. An answer written AFTER empowerment is
// therefore private. The public read must filter visibility='public' — exactly
// as the voter-facing candidate page does (candidateService) — or a stranger
// reading any :userId would see that user's private-visibility stances.
//
// The owner path (GET /me, requireAuth) is different: the caller IS the owner,
// so it returns every one of the owner's own answers regardless of visibility.
//
// These tests pin both halves: the public read sends .eq('visibility','public');
// the owner read does not.
// ---------------------------------------------------------------------------

const USER = '11111111-1111-4111-8111-111111111111';

// Records the eq filters (column=value) applied per table read, so the tests
// assert on the QUERY the service built rather than on returned rows.
const calls = vi.hoisted(
  () => [] as Array<{ table: string; filters: string[] }>
);

// Per-table single-row payloads. An active empowered_profiles row is what drives
// fetchInternalProfile into the compass block under test.
const rows: Record<string, unknown> = {
  users: { id: USER, display_name: 'Ada', created_at: '2020-01-01' },
  connected_profiles: {
    user_id: USER,
    display_name: 'Ada',
    total_xp: 10,
    gem_balance_yellow: 0,
    gem_balance_blue: 0,
    gem_balance_red: 0,
    location_consent: true,
  },
  empowered_profiles: {
    user_id: USER,
    legal_name: 'Ada Lovelace',
    candidate_page_slug: 'ada',
    is_active: true,
    empowered_at: '2021-01-01',
    demoted_at: null,
    politician_id: null,
  },
};

vi.mock('./db.js', () => ({ pool: { query: vi.fn(async () => ({ rows: [] })) } }));
vi.mock('./compassService.js', () => ({
  getSelectedTopics: vi.fn(async () => [] as string[]),
}));

vi.mock('./supabase.js', () => {
  // A chainable builder that is also awaitable. maybeSingle()/single() return the
  // per-table row; awaiting the builder itself (the list read the compass block
  // does) resolves to an empty data set — the tests care about the filters, not
  // the rows.
  const build = (table: string) => {
    const record = { table, filters: [] as string[] };
    calls.push(record);
    const single = { data: (rows[table] ?? null) as unknown, error: null };
    const builder: Record<string, unknown> = {};
    const passthrough = () => builder;
    builder.select = passthrough;
    builder.in = passthrough;
    builder.order = passthrough;
    builder.limit = passthrough;
    builder.eq = (col: string, val: unknown) => {
      record.filters.push(`eq:${col}=${String(val)}`);
      return builder;
    };
    builder.is = passthrough;
    builder.maybeSingle = async () => single;
    builder.single = async () => single;
    // Awaiting the builder (list read) resolves to an empty page.
    builder.then = (resolve: (v: { data: unknown[]; error: null }) => unknown) =>
      resolve({ data: [], error: null });
    return builder;
  };

  const client = {
    from: (table: string) => build(table),
    schema: () => ({ from: (table: string) => build(table) }),
  };

  return {
    supabaseAdmin: client,
    adminRpc: vi.fn(async () => ({ data: { level: 1 }, error: null })),
  };
});

import { getPublicProfile, getOwnerProfile } from './profileService.js';

const VIEW = 'compass_responses_effective';

beforeEach(() => {
  calls.length = 0;
});

describe('getPublicProfile — compass answers are visibility-gated', () => {
  it('sends .eq(visibility, public) on the arbitrary-user public read', async () => {
    await getPublicProfile(USER);

    const read = calls.find((c) => c.table === VIEW);
    expect(read).toBeDefined();
    expect(read?.filters).toContain(`eq:user_id=${USER}`);
    // The gate: a stranger must not receive private-visibility answers.
    expect(read?.filters).toContain('eq:visibility=public');
  });
});

describe('getOwnerProfile — owner sees their own answers regardless of visibility', () => {
  it('does NOT constrain visibility on the owner read', async () => {
    await getOwnerProfile(USER, 'ada@example.com');

    const read = calls.find((c) => c.table === VIEW);
    expect(read).toBeDefined();
    expect(read?.filters).toContain(`eq:user_id=${USER}`);
    // The caller is the owner, so no visibility filter is applied.
    expect(read?.filters.some((f) => f.startsWith('eq:visibility='))).toBe(false);
  });
});
