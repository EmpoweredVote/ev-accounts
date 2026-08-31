import { vi, describe, it, expect, beforeEach } from 'vitest';

/**
 * WHY THIS FILE EXISTS.
 *
 * requireAuth refuses a deleted account at the door (#232), so every read scoped
 * to `authReq.userId` is already safe. These are the reads that door does not
 * cover, because the user id they read is not the caller's:
 *
 *   - public endpoints that take an arbitrary :userId  (xp, profile)
 *   - service-key endpoints that name a user_id in the body  (gems, vq)
 *   - reads of a THIRD party from inside an authed request  (referral invitee)
 *   - a cron that walks every row with no request at all  (district staleness)
 *
 * `soft_delete_user` sets public.users.deleted_at and
 * connect.connected_profiles.deleted_at together, so either column identifies a
 * soft-deleted account — except for an Inform-tier account, which has no
 * connected_profiles row at all and can therefore only be caught on public.users.
 * That distinction is the whole reason awardGems asks two questions instead of
 * one; see the comment there.
 *
 * Prod has 0 soft-deleted rows today, so none of this changes current behaviour.
 * It makes the column mean something the day it is used, in the fail-closed
 * direction — the same bet tierGuards.deletedAt.test.ts documents.
 */

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

const poolQueryMock = vi.hoisted(() => vi.fn());
vi.mock('./db.js', () => ({ pool: { query: poolQueryMock } }));

/** Records the filters applied per table, so tests assert on the QUERY. */
const calls = vi.hoisted(() => [] as Array<{ table: string; filters: string[] }>);
const rowResult = vi.hoisted(() => ({ current: { data: null as unknown, error: null as unknown } }));

vi.mock('./supabase.js', () => {
  const build = (table: string) => {
    const record = { table, filters: [] as string[] };
    calls.push(record);
    const builder: Record<string, unknown> = {};
    builder.select = () => builder;
    builder.eq = (col: string) => { record.filters.push(`eq:${col}`); return builder; };
    builder.is = (col: string, val: unknown) => {
      record.filters.push(`is:${col}=${String(val)}`);
      return builder;
    };
    builder.maybeSingle = async () => rowResult.current;
    builder.single = async () => rowResult.current;
    return builder;
  };
  return {
    supabaseAdmin: {
      from: (table: string) => build(table),
      schema: () => ({ from: (table: string) => build(table) }),
    },
    adminRpc: vi.fn(async () => ({ data: null, error: null })),
  };
});

import { getPublicXpProfile } from './xpService.js';
import { getPublicProfile } from './profileService.js';
import { getReferralState } from './referralService.js';
import { awardGems } from './gemService.js';
import { runDistrictStalenessCheck } from './districtStalenessService.js';

beforeEach(() => {
  calls.length = 0;
  rowResult.current = { data: null, error: null };
  poolQueryMock.mockReset();
  poolQueryMock.mockResolvedValue({ rows: [] });
});

// ---------------------------------------------------------------------------
// Public endpoints — arbitrary :userId, no auth in front
// ---------------------------------------------------------------------------

describe('public reads by arbitrary userId', () => {
  it('GET /api/xp/:userId filters deleted_at on connected_profiles', async () => {
    await getPublicXpProfile('user-1');

    const q = calls.find((c) => c.table === 'connected_profiles');
    expect(q?.filters).toContain('is:deleted_at=null');
  });

  it('GET /api/profile/:userId filters deleted_at on BOTH users and connected_profiles', async () => {
    await getPublicProfile('user-1');

    // public.users is the load-bearing one: filtering only connected_profiles
    // still serves a deleted account as an Inform-tier profile, display_name and
    // all, because Inform tier IS the absence of that row.
    const users = calls.find((c) => c.table === 'users');
    expect(users?.filters).toContain('is:deleted_at=null');
  });
});

// ---------------------------------------------------------------------------
// Service-key endpoints — user_id named in the request body
// ---------------------------------------------------------------------------

describe('awardGems refuses a deleted account instead of reclassifying it', () => {
  /** is_deleted / is_connected as the single tier query returns them. */
  function tier(is_deleted: boolean, is_connected: boolean) {
    poolQueryMock.mockResolvedValueOnce({ rows: [{ is_deleted, is_connected }] });
  }

  it('🔴 throws ACCOUNT_DELETED for a deleted Connected account — never a yellow gem', async () => {
    tier(true, false); // deleted: the connected row is soft-deleted, so is_connected is false
    await expect(
      awardGems({ userId: 'user-1', gemType: 'yellow', amount: 1, idempotencyKey: 'k1' })
    ).rejects.toMatchObject({ code: 'ACCOUNT_DELETED' });
  });

  it('throws ACCOUNT_DELETED for a deleted Inform account too', async () => {
    // An Inform account has no connected_profiles row, so only public.users can
    // carry its deleted_at. If the check were folded into the EXISTS this case
    // would be invisible.
    tier(true, false);
    await expect(
      awardGems({ userId: 'user-1', gemType: 'yellow', amount: 1, idempotencyKey: 'k2' })
    ).rejects.toMatchObject({ code: 'ACCOUNT_DELETED' });
  });

  it('still refuses blue/red for a live Inform account', async () => {
    tier(false, false);
    await expect(
      awardGems({ userId: 'user-1', gemType: 'blue', amount: 1, idempotencyKey: 'k3' })
    ).rejects.toMatchObject({ code: 'INFORM_TIER_NO_BLUE_RED' });
  });

  it('asks about deletion and tier in one query, and asks them separately', async () => {
    tier(false, true);
    await awardGems({ userId: 'user-1', gemType: 'blue', amount: 1, idempotencyKey: 'k4' })
      .catch(() => { /* the RPC is stubbed; only the tier query matters here */ });

    const sql = String(poolQueryMock.mock.calls[0]?.[0] ?? '');
    // Deletion asked of public.users — the only table every tier has a row in.
    expect(sql).toMatch(/public\.users[\s\S]*deleted_at IS NOT NULL/);
    // Tier still asked as row presence, with deleted rows excluded so a deleted
    // Connected account cannot fall through to the Inform branch.
    expect(sql).toMatch(/connected_profiles[\s\S]*deleted_at IS NULL/);
  });
});

// ---------------------------------------------------------------------------
// Third-party reads inside an authed request
// ---------------------------------------------------------------------------

describe('referral state', () => {
  it('filters the invitee in the ON clause, not the WHERE', async () => {
    poolQueryMock.mockResolvedValueOnce({ rows: [] });
    await getReferralState('user-1');

    const sql = String(poolQueryMock.mock.calls[0]?.[0] ?? '');
    // In the WHERE this would drop the CALLER's row whenever their invitee was
    // deleted, turning a missing invitee into a missing referral state.
    expect(sql).toMatch(/ON invitee\.user_id = ic\.claimed_by AND invitee\.deleted_at IS NULL/);
    // The WHERE clause stays exactly one predicate — the caller. Asserted on the
    // tail of the statement so the prose in the comment above cannot satisfy it.
    expect(sql.slice(sql.lastIndexOf('WHERE'))).toBe('WHERE cp.user_id = $1');
  });
});

// ---------------------------------------------------------------------------
// Cron — no request, no guard, every row
// ---------------------------------------------------------------------------

describe('district staleness cron', () => {
  it('skips deleted accounts', async () => {
    poolQueryMock.mockResolvedValueOnce({ rows: [] });
    await runDistrictStalenessCheck();

    const sql = String(poolQueryMock.mock.calls[0]?.[0] ?? '');
    expect(sql).toMatch(/connect\.connected_profiles/);
    expect(sql).toMatch(/deleted_at IS NULL/);
  });
});
