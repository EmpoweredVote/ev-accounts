/**
 * vqService — Validation Quest confirmation operations.
 *
 * WHY THIS FILE EXISTS:
 * confirm_vq_stance is a SECURITY DEFINER RPC that atomically:
 *   - Awards Red Gems to correct users
 *   - Adjusts verification_rating for all participants
 *   - Upserts the confirmed politician stance
 *   - Caches the result for idempotent replay
 *
 * adjustVerificationRating handles Yellow quest immediate grading:
 *   - Adjusts verification_rating by a delta (no gems, no politician stance)
 *   - Clamps VR to [0, 150] (matches DB CHECK constraint)
 *   - Sets vq_hold_until when VR hits 0
 *   - Idempotent via vq_confirmation_results table
 *
 * No chained JS awaits for multi-table writes — all atomicity is at the
 * Postgres layer (transaction). This file wraps the RPC call and maps error
 * codes to typed exceptions for the route layer.
 */

import { adminRpc } from './supabase.js';
import { pool } from './db.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface ConfirmVqStanceParams {
  politicianId: string;
  topicId: string;
  confirmedValue: number;
  correctUserIds: string[];
  incorrectUserIds: string[];
  idempotencyKey: string;
  gemsAmount: number;
}

export interface VqUserResult {
  user_id: string;
  result: 'correct' | 'incorrect';
  gems_awarded: number;
  rating_delta: number;
  new_rating: number;
}

export interface ConfirmVqStanceResult {
  politician_id: string;
  topic_id: string;
  confirmed_value: number;
  correct_count: number;
  incorrect_count: number;
  users: VqUserResult[];
  unresolved_users: string[];
  replayed?: boolean;
}

// ---------------------------------------------------------------------------
// confirmVqStance
// ---------------------------------------------------------------------------

/**
 * Confirm a Validation Quest stance via the confirm_vq_stance SECURITY DEFINER RPC.
 *
 * Idempotent: duplicate idempotency_key returns the cached result with
 * replayed: true and no side effects.
 *
 * Called exclusively by POST /api/vq/confirm-stance.
 *
 * Error codes thrown:
 *   QUESTION_NOT_FOUND — politician_id / topic_id pair does not exist
 *   INVALID_VALUE      — confirmed_value is outside the 1–5 range
 */
export async function confirmVqStance(
  params: ConfirmVqStanceParams
): Promise<ConfirmVqStanceResult> {
  const { data, error } = await adminRpc(
    'confirm_vq_stance',
    {
      p_politician_id:   params.politicianId,
      p_topic_id:        params.topicId,
      p_confirmed_value: params.confirmedValue,
      p_correct_users:   params.correctUserIds,
      p_incorrect_users: params.incorrectUserIds,
      p_idempotency_key: params.idempotencyKey,
      p_gems_amount:     params.gemsAmount,
    },
    'connect'
  );

  if (error) {
    if (error.message?.includes('QUESTION_NOT_FOUND')) {
      throw Object.assign(
        new Error('Politician/topic pair not found'),
        { code: 'QUESTION_NOT_FOUND' }
      );
    }
    if (error.message?.includes('INVALID_VALUE')) {
      throw Object.assign(
        new Error('confirmed_value must be between 1 and 5'),
        { code: 'INVALID_VALUE' }
      );
    }
    throw new Error(error.message ?? 'confirm_vq_stance RPC failed');
  }

  // confirm_vq_stance RETURNS JSONB (scalar) — data is the object directly
  return data as ConfirmVqStanceResult;
}

// ---------------------------------------------------------------------------
// Types — adjustVerificationRating
// ---------------------------------------------------------------------------

export interface AdjustVrParams {
  userId: string;
  delta: number;          // positive or negative integer
  idempotencyKey: string;
  reason?: string;        // optional context (e.g., "yellow_quest_correct", "yellow_quest_incorrect")
}

export interface AdjustVrResult {
  user_id: string;
  old_rating: number;
  new_rating: number;
  delta_applied: number;  // actual delta after clamping (may differ from requested)
  vq_hold_set: boolean;   // true if vq_hold_until was set/reset because rating hit 0
  replayed?: boolean;
}

// ---------------------------------------------------------------------------
// adjustVerificationRating
// ---------------------------------------------------------------------------

/**
 * Adjust a user's verification_rating by delta for Yellow quest grading.
 *
 * Lighter than confirmVqStance — no gems, no politician stance upsert.
 * VR is clamped to [0, 100] (Yellow quest range, not the 0–150 Red range).
 * Sets vq_hold_until when VR hits 0.
 *
 * Idempotent: duplicate idempotency_key returns the cached result with
 * replayed: true and no side effects.
 *
 * All writes use pool.query (direct postgres) — PostgREST writes to
 * non-public schemas fail silently (see MEMORY.md critical production pattern).
 *
 * Error codes thrown:
 *   USER_NOT_FOUND — no connect.connected_profiles row for this user_id
 */
export async function adjustVerificationRating(
  params: AdjustVrParams
): Promise<AdjustVrResult> {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // ------------------------------------------------------------------
    // 1. Idempotency pre-check (before lock acquisition — cheapest path)
    // ------------------------------------------------------------------
    const cacheCheck = await client.query<{ result_json: AdjustVrResult }>(
      'SELECT result_json FROM connect.vq_confirmation_results WHERE idempotency_key = $1',
      [params.idempotencyKey]
    );

    if (cacheCheck.rows.length > 0) {
      await client.query('COMMIT');
      return { ...cacheCheck.rows[0].result_json, replayed: true };
    }

    // ------------------------------------------------------------------
    // 2. Read current VR with row-level lock
    // ------------------------------------------------------------------
    const profileResult = await client.query<{
      verification_rating: number;
      vq_hold_until: string | null;
    }>(
      // deleted_at IS NULL: /adjust-vr is a service-key route that names an
      // arbitrary user_id in the body, so requireAuth's deleted-account refusal
      // never runs. A deleted account falls out here as USER_NOT_FOUND, which is
      // the refusal we want — unlike the tier check in gemService, dropping the
      // row here cannot reclassify anyone, it only stops the write.
      `SELECT verification_rating, vq_hold_until
         FROM connect.connected_profiles
        WHERE user_id = $1 AND deleted_at IS NULL
          FOR UPDATE`,
      [params.userId]
    );

    if (profileResult.rows.length === 0) {
      await client.query('ROLLBACK');
      throw Object.assign(new Error('No connected_profile for this user_id'), {
        code: 'USER_NOT_FOUND',
      });
    }

    const currentRating = profileResult.rows[0].verification_rating;

    // ------------------------------------------------------------------
    // 3. Compute new rating (clamped to [0, 150] — matches DB CHECK constraint)
    // ------------------------------------------------------------------
    const newRating = Math.max(0, Math.min(150, currentRating + params.delta));
    const deltaApplied = newRating - currentRating;
    const vqHoldSet = newRating === 0;

    // ------------------------------------------------------------------
    // 4. Update connected_profiles
    // ------------------------------------------------------------------
    await client.query(
      `UPDATE connect.connected_profiles
       SET verification_rating = $1,
           vq_hold_until = CASE WHEN $2::int = 0 THEN NOW() + INTERVAL '30 days' ELSE vq_hold_until END
       WHERE user_id = $3`,
      [newRating, newRating, params.userId]
    );

    // ------------------------------------------------------------------
    // 5. Cache result for idempotency
    // ------------------------------------------------------------------
    const result: AdjustVrResult = {
      user_id: params.userId,
      old_rating: currentRating,
      new_rating: newRating,
      delta_applied: deltaApplied,
      vq_hold_set: vqHoldSet,
    };

    await client.query(
      'INSERT INTO connect.vq_confirmation_results (idempotency_key, result_json) VALUES ($1, $2)',
      [params.idempotencyKey, JSON.stringify(result)]
    );

    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
