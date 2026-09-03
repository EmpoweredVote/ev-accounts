/**
 * notificationService.ts
 * Notification persistence layer for the Validation Quests system.
 *
 * When consensus finalizes, writeNotification is called once per eligible
 * human submitter. It checks whether the user has opted in, builds the
 * appropriate payload, and upserts a row into user_notifications.
 *
 * Supabase Realtime delivers the INSERT event to subscribed clients
 * automatically — this service only writes the row.
 *
 * Design notes:
 *   - Default-off: if no preference row exists, or enabled = false, no row is written.
 *   - Idempotent: upsert with onConflict:'user_id,quest_id' prevents duplicates.
 *   - Non-fatal pattern: errors are logged and re-thrown; caller (consensusBatchJob)
 *     wraps each call in try/catch so notification failure cannot abort the batch job.
 *   - Gem breakdown is read from gem_reward_events (source of truth) rather than
 *     re-computing from quest data, so the payload reflects actual awards.
 *   - research_tip is only present for incorrect submissions (Phase 3 decision).
 */

import { supabaseService } from '../lib/supabase.js';
import { logger } from '../lib/logger.js';
import type {
  Source,
  NotificationPayload,
  CorrectNotificationPayload,
  IncorrectNotificationPayload,
} from '../types/custom.js';

// ============================================================
// TYPES
// ============================================================

export interface WriteNotificationParams {
  userId: string;
  questId: string;
  outcome: 'correct' | 'incorrect';
  correctAnswer: string;
  authoritativeSources: Source[];
  isEarly: boolean;
  questData: { gemReward: number };
}

// ============================================================
// EXPORTED: buildNotificationPayload
// ============================================================

/**
 * Constructs the JSONB payload for a notification row.
 *
 * For 'correct' outcome: reads gem_reward_events to get actual yellow/red/early_bonus amounts.
 * For 'incorrect' outcome: reads verification_submissions.feedback for research_tip.
 *
 * IMPORTANT: research_tips key is only present for incorrect submitters (Phase 3 decision).
 * Do NOT access it for correct submissions.
 */
export async function buildNotificationPayload(
  params: WriteNotificationParams
): Promise<NotificationPayload> {
  const { userId, questId, outcome, correctAnswer, authoritativeSources } = params;

  if (outcome === 'correct') {
    // Fetch gem breakdown from gem_reward_events (authoritative source)
    const { data: events } = await supabaseService
      .schema('validation_quests')
      .from('gem_reward_events')
      .select('gem_type, amount, reason')
      .eq('user_id', userId)
      .eq('quest_id', questId);

    const rows = (events as Array<{ gem_type: string; amount: number; reason: string }> | null) ?? [];

    const yellow =
      rows.find((e) => e.gem_type === 'yellow')?.amount ?? 0;
    const red =
      rows.find((e) => e.gem_type === 'red' && e.reason === 'correct_submission')?.amount ?? 0;
    const early_bonus =
      rows.find((e) => e.reason === 'early_bonus')?.amount ?? 0;

    const payload: CorrectNotificationPayload = {
      outcome: 'correct',
      correct_answer: correctAnswer,
      gems: { yellow, red, early_bonus },
    };
    return payload;
  }

  // outcome === 'incorrect'
  const { data: sub } = await supabaseService
    .schema('validation_quests')
    .from('verification_submissions')
    .select('feedback')
    .eq('user_id', userId)
    .eq('quest_id', questId)
    .maybeSingle();

  const research_tip =
    (sub?.feedback as { research_tips?: string } | null)?.research_tips ?? '';

  const payload: IncorrectNotificationPayload = {
    outcome: 'incorrect',
    correct_answer: correctAnswer,
    authoritative_sources: authoritativeSources,
    research_tip,
  };
  return payload;
}

// ============================================================
// EXPORTED: writeNotification
// ============================================================

/**
 * Writes a notification row for a single user+quest combination.
 *
 * Steps:
 *   1. Check user_notification_preferences — if no row or enabled=false, return immediately.
 *   2. Build the JSONB payload via buildNotificationPayload.
 *   3. Upsert into user_notifications (idempotent via UNIQUE constraint).
 *
 * On DB error: logs and re-throws. Caller is responsible for catching
 * (consensusBatchJob wraps each call in try/catch — non-fatal pattern).
 */
export async function writeNotification(params: WriteNotificationParams): Promise<void> {
  const { userId, questId } = params;

  // Step 1: Check preference (default off — no row means no notification)
  const { data: pref } = await supabaseService
    .schema('validation_quests')
    .from('user_notification_preferences')
    .select('enabled')
    .eq('user_id', userId)
    .maybeSingle();

  const enabled = (pref as { enabled: boolean } | null)?.enabled ?? false;
  if (!enabled) {
    return;
  }

  // Step 2: Build payload
  const payload = await buildNotificationPayload(params);

  // Step 3: Upsert into user_notifications
  const { error } = await supabaseService
    .schema('validation_quests')
    .from('user_notifications')
    .upsert(
      { user_id: userId, quest_id: questId, payload, is_read: false },
      { onConflict: 'user_id,quest_id' }
    );

  if (error) {
    logger.error('writeNotification: failed to upsert user_notifications', {
      userId,
      questId,
      error: error.message,
    });
    throw new Error(`writeNotification failed for user ${userId} quest ${questId}: ${error.message}`);
  }
}
