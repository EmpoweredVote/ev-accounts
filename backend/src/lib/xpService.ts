/**
 * xpService — XP ledger operations (award XP via the award_xp RPC).
 *
 * WHY THIS FILE EXISTS:
 * The architecture test enforces that no file in src/routes/ may reference
 * supabaseAdmin directly. XP award operations require calling the award_xp
 * SECURITY DEFINER RPC function — which must bypass RLS and use the service
 * role key. That call lives here in src/lib/, not in src/routes/.
 *
 * ATOMICITY:
 * awardXp is entirely handled by the Postgres award_xp RPC function. It
 * maintains total_xp on connected_profiles atomically with the xp_transactions
 * ledger insert, checks idempotency, and returns current level state. No
 * chained JS awaits for multi-table writes.
 */

import { adminRpc } from './supabase.js';

// ---------------------------------------------------------------------------
// Constants and Types
// ---------------------------------------------------------------------------

export const XP_SOURCES = [
  'validation_quest_completion',
  'civic_trivia_championship_score',
  'admin_gift',
] as const;

export type XpSource = typeof XP_SOURCES[number];

export interface AwardXpParams {
  userId: string;
  source: string;
  amount: number;
  idempotencyKey: string;
  metadata?: Record<string, unknown>;
}

export interface AwardXpResult {
  transaction_id: string;
  user_id: string;
  source: string;
  amount: number;
  created_at: string;
  level: number;
  total_xp: number;
  xp_in_level: number;
  xp_to_next_level: number;
  is_duplicate: boolean;
}

// ---------------------------------------------------------------------------
// awardXp
// ---------------------------------------------------------------------------

/**
 * Award XP to a user via the award_xp SECURITY DEFINER RPC.
 *
 * Delegates idempotency enforcement to Postgres: a duplicate idempotency_key
 * returns is_duplicate: true with current profile state — no second ledger row.
 *
 * Throws with error.code set for known failure modes:
 *   NOT_CONNECTED — user has no connected_profiles row
 *   INVALID_AMOUNT — amount was not a positive integer
 */
export async function awardXp(params: AwardXpParams): Promise<AwardXpResult> {
  const { userId, source, amount, idempotencyKey, metadata } = params;

  const { data, error } = await adminRpc('award_xp', {
    p_user_id: userId,
    p_source: source,
    p_amount: amount,
    p_idempotency_key: idempotencyKey,
    p_metadata: metadata ?? null,
  });

  if (error) {
    if (error.message?.includes('no connected_profiles row')) {
      throw Object.assign(new Error('User has no connected profile'), { code: 'NOT_CONNECTED' });
    }
    if (error.message?.includes('must be positive')) {
      throw Object.assign(new Error('Amount must be positive'), { code: 'INVALID_AMOUNT' });
    }
    throw new Error(error.message ?? 'award_xp RPC failed');
  }

  // award_xp uses RETURNS TABLE — data is an array. Access the first row.
  const row = Array.isArray(data) ? data[0] : data;
  if (!row) {
    throw new Error('[xpService] award_xp returned no rows — unexpected internal error');
  }

  return {
    transaction_id: row.id,
    user_id: row.user_id,
    source: row.source,
    amount: row.amount,
    created_at: row.created_at,
    level: row.current_level,
    total_xp: row.total_xp,
    xp_in_level: row.xp_in_level,
    xp_to_next_level: row.xp_to_next_level,
    is_duplicate: row.is_duplicate,
  };
}
