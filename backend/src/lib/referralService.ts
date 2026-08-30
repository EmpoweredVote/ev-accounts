import { pool } from './db.js';

export interface ReferralState {
  unlocked: boolean;
  code: string | null;
  inviteeJoined: boolean;
  inviteeLevel: number | null;
}

/**
 * Read the referral state for a Connected user.
 * Returns null if the user has no connected_profiles row.
 */
export async function getReferralState(userId: string): Promise<ReferralState | null> {
  const result = await pool.query<{
    referral_unlocked: boolean;
    referral_code: string | null;
    claimed_by: string | null;
    invitee_level: number | null;
  }>(
    `SELECT
       cp.referral_unlocked,
       cp.referral_code,
       ic.claimed_by,
       invitee.current_level AS invitee_level
     FROM connect.connected_profiles cp
     LEFT JOIN connect.invite_codes ic          ON ic.id = cp.referral_invite_id
     -- The invitee is somebody else, so no guard has vetted them. In the ON
     -- clause, not the WHERE: a deleted invitee must read as invitee_level NULL
     -- (the same as an unclaimed code), never remove the caller's own row.
     LEFT JOIN connect.connected_profiles invitee
            ON invitee.user_id = ic.claimed_by AND invitee.deleted_at IS NULL
     WHERE cp.user_id = $1`,
    [userId]
  );

  const row = result.rows[0];
  if (!row) return null;

  return {
    unlocked: row.referral_unlocked,
    code: row.referral_code,
    inviteeJoined: row.claimed_by != null,
    inviteeLevel: row.invitee_level,
  };
}

/**
 * Unlock a referral code for a user who just reached level 2.
 * Idempotent — safe to call repeatedly.
 */
export async function unlockReferralCode(userId: string): Promise<void> {
  await pool.query('SELECT connect.unlock_referral_code($1)', [userId]);
}

/**
 * Refresh the referrer's code if this invitee just hit level 2.
 * Idempotent — safe to call repeatedly.
 */
export async function maybeRefreshReferralForInvitee(inviteeId: string): Promise<void> {
  await pool.query('SELECT connect.maybe_refresh_referral_for_invitee($1)', [inviteeId]);
}
