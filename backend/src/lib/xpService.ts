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

import { supabaseAdmin, adminRpc } from './supabase.js';

// ---------------------------------------------------------------------------
// Constants and Types
// ---------------------------------------------------------------------------

export const XP_SOURCES = [
  'validation_quest_completion',
  'civic_trivia_championship_score',
  'admin_gift',
  'essentials-rep-lookup',
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
  }, 'connect');

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

// ---------------------------------------------------------------------------
// getXpHistory
// ---------------------------------------------------------------------------

/**
 * Fetch paginated XP transaction history for a user.
 *
 * Returns transactions in reverse chronological order (newest first).
 * Used by GET /api/xp/me/history — requires auth + Connected tier.
 */
export async function getXpHistory(
  userId: string,
  options?: { limit?: number; offset?: number }
): Promise<{ transactions: unknown[]; total: number }> {
  const limit = Math.min(options?.limit ?? 50, 100);
  const offset = options?.offset ?? 0;

  const { data, count, error } = await supabaseAdmin
    .schema('connect')
    .from('xp_transactions')
    .select('id, source, amount, metadata, created_at', { count: 'exact' })
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) throw new Error(error.message);
  return { transactions: data ?? [], total: count ?? 0 };
}

// ---------------------------------------------------------------------------
// getXpLeaderboard
// ---------------------------------------------------------------------------

export type LeaderboardWindow = 'alltime' | 'week';

export interface LeaderboardEntry {
  rank: number;
  userId: string;
  username: string;
  level: number;
  totalXp: number;
  weeklyXp: number;
}

export interface MyRankEntry extends LeaderboardEntry {
  xpToNextRank: number;
}

/**
 * Fetch the top N CTC XP leaderboard entries.
 * Only Connected users who have earned civic_trivia_championship_score XP appear.
 * window='week' ranks by rolling 168-hour XP; 'alltime' ranks by total CTC XP.
 */
export async function getXpLeaderboard(
  window: LeaderboardWindow = 'alltime',
  limit = 25
): Promise<LeaderboardEntry[]> {
  const { data, error } = await adminRpc(
    'get_xp_leaderboard',
    { p_window: window, p_limit: limit },
    'connect'
  );

  if (error) throw new Error(error.message);

  const rows = Array.isArray(data) ? data : [];
  return rows.map((row: Record<string, unknown>) => ({
    rank:      Number(row['rank']),
    userId:    row['user_id'] as string,
    username:  row['username'] as string,
    level:     Number(row['level']),
    totalXp:   Number(row['total_xp']),
    weeklyXp:  Number(row['weekly_xp']),
  }));
}

/**
 * Fetch the calling user's rank on the CTC leaderboard.
 * Returns null if the user has never earned CTC XP (unranked).
 */
export async function getMyXpRank(
  userId: string,
  window: LeaderboardWindow = 'alltime'
): Promise<MyRankEntry | null> {
  const { data, error } = await adminRpc(
    'get_my_xp_rank',
    { p_user_id: userId, p_window: window },
    'connect'
  );

  if (error) throw new Error(error.message);

  const rows = Array.isArray(data) ? data : [];
  if (rows.length === 0) return null;

  const row = rows[0] as Record<string, unknown>;
  return {
    rank:           Number(row['rank']),
    userId:         row['user_id'] as string,
    username:       row['username'] as string,
    level:          Number(row['level']),
    totalXp:        Number(row['total_xp']),
    weeklyXp:       Number(row['weekly_xp']),
    xpToNextRank:   Number(row['xp_to_next_rank']),
  };
}

// ---------------------------------------------------------------------------
// getPublicXpProfile
// ---------------------------------------------------------------------------

/**
 * Fetch the public XP profile for a user: level, total_xp, xp_in_level,
 * xp_to_next_level.
 *
 * Returns null if the user does not exist or is not Connected tier (no
 * connected_profiles row). Used by GET /api/xp/:userId — no auth required.
 */
export async function getPublicXpProfile(
  userId: string
): Promise<{ level: number; total_xp: number; xp_in_level: number; xp_to_next_level: number } | null> {
  // Read denormalized total_xp from connected_profiles.
  const { data: profile, error: profileError } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .select('total_xp')
    .eq('user_id', userId)
    // This endpoint takes an arbitrary userId and needs no auth, so requireAuth's
    // deleted-account refusal never runs for it. Without this filter a deleted
    // account stays publicly readable by id forever.
    .is('deleted_at', null)
    .maybeSingle();

  if (profileError) throw new Error(profileError.message);
  if (!profile) return null; // user not found, deleted, or not Connected

  // Compute level fields via calculate_level RPC (IMMUTABLE, cached by Postgres)
  const { data: levelData, error: levelError } = await adminRpc('calculate_level', {
    p_total_xp: profile.total_xp,
  }, 'connect');
  if (levelError) throw new Error(levelError.message);

  // calculate_level uses RETURNS TABLE — data is array
  const levelRow = Array.isArray(levelData) ? levelData[0] : levelData;
  if (!levelRow) throw new Error('calculate_level returned no rows');

  return {
    level: levelRow.level,
    total_xp: profile.total_xp,
    xp_in_level: levelRow.xp_in_level,
    xp_to_next_level: levelRow.xp_to_next_level,
  };
}
