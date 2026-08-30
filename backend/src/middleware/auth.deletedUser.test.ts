import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

const poolQueryMock = vi.hoisted(() => vi.fn());
vi.mock('../lib/db.js', () => ({ pool: { query: poolQueryMock } }));

// requireAuth verifies the JWT and checks the logout-revocation list before it
// ever looks at the account. Both are stubbed to "fine" so each test below is
// about the account state and nothing else.
//
// verifyAccessToken is private to auth.ts, so the stub goes one level down: jose
// returns a valid payload, and tokenIdentity resolves it to a user id.
vi.mock('jose', () => ({
  jwtVerify: vi.fn(async () => ({ payload: { iat: 1_000, exp: 9_999_999_999, sub: 'user-1' } })),
  createRemoteJWKSet: vi.fn(() => ({})),
}));
vi.mock('../lib/tokenIdentity.js', () => ({
  SUPABASE_ISSUER: 'supabase',
  WORKOS_ISSUER: 'workos',
  WORKOS_JWKS_URL: null,
  classifyToken: vi.fn(() => 'supabase'),
  resolveInternalUserId: vi.fn(() => 'user-1'),
}));
vi.mock('../lib/authService.js', () => ({ isTokenRevoked: vi.fn(async () => false) }));
vi.mock('../lib/env.js', () => ({
  env: { SUPABASE_URL: 'http://localhost', SUPABASE_JWT_SECRET: 'x', SUPABASE_ANON_KEY: 'x' },
}));

import { requireAuth } from './auth.js';

function makeRes() {
  const out: { code?: number; body?: { error?: string } } = {};
  const res = {
    status(c: number) { out.code = c; return res; },
    json(b: unknown) { out.body = b as { error?: string }; return res; },
  };
  return { res: res as never, out };
}

const req = () => ({ headers: { authorization: 'Bearer token' } }) as never;

beforeEach(() => vi.clearAllMocks());

/**
 * WHY THIS FILE EXISTS.
 *
 * Deletion has to be settled at the door, or every tier guard re-litigates it
 * from the profile row and they disagree.
 *
 * That is not hypothetical. `soft_delete_user` sets
 * connect.connected_profiles.deleted_at. Before #231 requireConnected ignored the
 * column, so a deleted user kept full Connected access. #231 closed that — and
 * opened a smaller hole, because requireInform then saw no live profile and let
 * the same user through Inform-tier routes.
 *
 * Neither guard was ever the right place to decide it. This is.
 */
describe('requireAuth — a deleted account cannot authenticate', () => {
  it('401s a soft-deleted user holding a still-valid token', async () => {
    poolQueryMock.mockResolvedValue({
      rows: [{ user_deleted_at: new Date(), account_standing: 'active' }],
    });
    const { res, out } = makeRes();
    let passed = false;

    await requireAuth(req(), res, () => { passed = true; });

    expect(passed).toBe(false);
    expect(out.code).toBe(401);
  });

  it('401s a hard-deleted user rather than treating them as Inform tier', async () => {
    // No public.users row. The previous PostgREST read returned null here and
    // fell through as "no connected profile" — i.e. a perfectly good Inform user.
    poolQueryMock.mockResolvedValue({ rows: [] });
    const { res, out } = makeRes();
    let passed = false;

    await requireAuth(req(), res, () => { passed = true; });

    expect(passed).toBe(false);
    expect(out.code).toBe(401);
  });

  it('lets a live Inform-tier user through — no profile is not deletion', async () => {
    // LEFT JOIN gives account_standing = null for an Inform user. Absence of a
    // connected profile is the normal state for most accounts now, not a fault.
    poolQueryMock.mockResolvedValue({
      rows: [{ user_deleted_at: null, account_standing: null }],
    });
    const { res } = makeRes();
    let passed = false;

    await requireAuth(req(), res, () => { passed = true; });

    expect(passed).toBe(true);
  });

  it('lets a live Connected user through', async () => {
    poolQueryMock.mockResolvedValue({
      rows: [{ user_deleted_at: null, account_standing: 'active' }],
    });
    const { res } = makeRes();
    let passed = false;

    await requireAuth(req(), res, () => { passed = true; });

    expect(passed).toBe(true);
  });

  it('403s a suspended user, distinctly from a deleted one', async () => {
    poolQueryMock.mockResolvedValue({
      rows: [{ user_deleted_at: null, account_standing: 'suspended' }],
    });
    const { res, out } = makeRes();
    let passed = false;

    await requireAuth(req(), res, () => { passed = true; });

    expect(passed).toBe(false);
    expect(out.code).toBe(403);
    expect(out.body?.error).toBe('Account suspended');
  });

  it('asks for deletion and standing in ONE query', async () => {
    // This runs on every authenticated request. Two round trips here would be
    // paid by every call in the product.
    poolQueryMock.mockResolvedValue({
      rows: [{ user_deleted_at: null, account_standing: 'active' }],
    });
    const { res } = makeRes();

    await requireAuth(req(), res, () => {});

    expect(poolQueryMock).toHaveBeenCalledTimes(1);
    const sql = String(poolQueryMock.mock.calls[0][0]);
    expect(sql).toContain('public.users');
    expect(sql).toContain('connected_profiles');
  });
});
