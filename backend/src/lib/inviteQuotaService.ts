/**
 * inviteQuotaService.ts — invite quota management for Phase 59 referral code system.
 *
 * Provides quota-aware invite code generation, invitee listing, slot locking,
 * TR adjustment on suspension, and admin cap override operations.
 *
 * All queries use pool.query() — NEVER PostgREST — per critical production pattern.
 */

import { pool } from './db.js';

interface GenerateResult {
  ok: boolean;
  code: string | null;
  error: string | null;
  active_count: number;
  cap: number;
}

interface InviteeEntry {
  status: 'claimed' | 'pending';
  code: string;
  label: string | null;
  invitee_id: string | null;
  display_name: string | null;
  account_standing: string | null;
  current_level: number | null;
  graduated: boolean | null;
  slot_locked_until: string | null;
  claimed_at: string | null;
  xp_in_level: number | null;
  xp_to_next_level: number | null;
}

interface MyInviteesResponse {
  active_count: number;
  cap: number;
  can_generate: boolean;
  invitees: InviteeEntry[];
}

interface InviteOverride {
  user_id: string;
  display_name: string;
  email: string;
  current_level: number;
  level_cap: number;
  invite_cap_override: number;
  effective_cap: number;
}

/**
 * Call the generate_invite_code_if_allowed RPC to produce a quota-aware invite code.
 * Returns ok=false with error='CAP_REACHED' when user is at their limit.
 */
export async function generateInviteCodeIfAllowed(userId: string, label: string | null = null): Promise<GenerateResult> {
  const { rows } = await pool.query(
    'SELECT ok, code, error, active_count, cap FROM connect.generate_invite_code_if_allowed($1, $2)',
    [userId, label],
  );
  const row = rows[0];
  return {
    ok: row.ok,
    code: row.code ?? null,
    error: row.error ?? null,
    active_count: row.active_count,
    cap: row.cap,
  };
}

/**
 * Fetch the caller's invitee list with quota summary.
 *
 * If the user has no invitees, the RPC returns no rows — we fall back to
 * a direct cap query so we can still return accurate active_count/cap values.
 */
export async function getMyInvitees(userId: string): Promise<MyInviteesResponse> {
  const { rows } = await pool.query('SELECT * FROM connect.get_my_invitees($1)', [userId]);

  let active_count: number;
  let effective_cap: number;

  if (rows.length > 0) {
    active_count = rows[0].active_count;
    effective_cap = rows[0].effective_cap;
  } else {
    // No invitees — compute cap separately so can_generate reflects true quota
    const capRes = await pool.query(
      `SELECT connect.get_invite_cap_for_level(cp.current_level) as level_cap, cp.invite_cap_override
       FROM connect.connected_profiles cp WHERE cp.user_id = $1`,
      [userId],
    );
    const capRow = capRes.rows[0];
    if (!capRow) {
      return { active_count: 0, cap: 0, can_generate: false, invitees: [] };
    }
    const override = capRow.invite_cap_override;
    if (override === -1) {
      // -1 = unlimited sentinel — use max int as effective cap
      effective_cap = 2147483647;
    } else {
      effective_cap = Math.max(capRow.level_cap, override ?? 0);
    }
    active_count = 0;
  }

  return {
    active_count,
    cap: effective_cap,
    can_generate: active_count < effective_cap,
    invitees: rows.map(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      (r: any): InviteeEntry => ({
        status: r.status,
        code: r.code,
        label: r.label ?? null,
        invitee_id: r.invitee_id ?? null,
        display_name: r.display_name ?? null,
        account_standing: r.account_standing ?? null,
        current_level: r.current_level ?? null,
        graduated: r.graduated ?? null,
        slot_locked_until: r.slot_locked_until ?? null,
        claimed_at: r.claimed_at ?? null,
        xp_in_level: r.xp_in_level ?? null,
        xp_to_next_level: r.xp_to_next_level ?? null,
      }),
    ),
  };
}

/**
 * Call the sanction_invitee RPC to lock the inviter's slot and adjust their TR.
 * Called non-blockingly from the suspend route — failure is logged but not fatal.
 */
export async function sanctionInvitee(
  inviteeId: string,
  trDelta: number = -0.25,
): Promise<void> {
  await pool.query('SELECT connect.sanction_invitee($1, $2)', [inviteeId, trDelta]);
}

/**
 * Clear slot_locked_until for a reinstated invitee.
 * Called non-blockingly from the unsuspend route — failure is logged but not fatal.
 */
export async function clearSlotLock(inviteeId: string): Promise<void> {
  await pool.query(
    'UPDATE connect.invite_chains SET slot_locked_until = NULL WHERE invitee_id = $1',
    [inviteeId],
  );
}

/**
 * Set (or clear, when cap=null) the invite_cap_override on connected_profiles.
 * -1 = unlimited; positive int = explicit cap; null = remove override (revert to level cap).
 */
export async function setInviteCapOverride(
  userId: string,
  cap: number | null,
): Promise<void> {
  await pool.query(
    'UPDATE connect.connected_profiles SET invite_cap_override = $2 WHERE user_id = $1',
    [userId, cap],
  );
}

/**
 * Return all users who have an active invite_cap_override, with computed effective_cap.
 */
export async function getInviteOverrides(): Promise<InviteOverride[]> {
  const { rows } = await pool.query(`
    SELECT cp.user_id,
           u.display_name,
           u.email,
           cp.current_level,
           connect.get_invite_cap_for_level(cp.current_level) AS level_cap,
           cp.invite_cap_override,
           CASE WHEN cp.invite_cap_override = -1 THEN 2147483647
                ELSE GREATEST(connect.get_invite_cap_for_level(cp.current_level), COALESCE(cp.invite_cap_override, 0))
           END AS effective_cap
    FROM connect.connected_profiles cp
    JOIN public.users u ON u.id = cp.user_id
    WHERE cp.invite_cap_override IS NOT NULL
    ORDER BY u.display_name
  `);
  return rows;
}
