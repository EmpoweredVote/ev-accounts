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
 * No chained JS awaits for multi-table writes — all atomicity is at the
 * Postgres layer. This file wraps the RPC call and maps error codes to
 * typed exceptions for the route layer.
 */

import { adminRpc } from './supabase.js';

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
