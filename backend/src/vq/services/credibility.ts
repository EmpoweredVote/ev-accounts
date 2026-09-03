/**
 * credibility.ts
 * Manages the credibility score lifecycle for users in the validation quests system.
 *
 * Score range:  [-100, 200]
 * Starting:     100
 * Quarantine:   score < 40 (submissions stored but excluded from consensus)
 * Lockout:      score < 0  (cannot submit)
 *
 * Gains:
 *   source_accepted: +1
 *
 * Losses (source_rejected):
 *   First offense  (infraction_count === 0 before hit): delta = -1
 *   Repeat offenses: delta = -min(10, 2 + infraction_count) — escalating cap at -10
 *
 * Note: server_error and timeout results from sourceValidator do NOT trigger
 * applyCredibilityChange — caller is responsible for skipping those cases.
 */

import { supabaseService } from '../lib/supabase.js';
import { logger } from '../lib/logger.js';

// ============================================================
// TYPES
// ============================================================

export interface CredibilityChangeResult {
  current_score: number;
  change: number;
  reason: string;
  quarantined: boolean;
  locked_out: boolean;
}

interface VeracityProfile {
  credibility_score: number;
  credibility_infraction_count: number;
  restriction_state: string;
}

// ============================================================
// SCORE CONSTANTS
// ============================================================

const SCORE_MIN = -100;
const SCORE_MAX = 200;
const QUARANTINE_THRESHOLD = 40;
const LOCKOUT_THRESHOLD = 0;

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

// ============================================================
// PUBLIC API
// ============================================================

/**
 * getOrCreateProfile — get (or lazily create) the veracity profile for a user.
 *
 * Uses upsert with ignoreDuplicates: true to avoid race conditions on first submission.
 * Returns the profile with credibility columns.
 */
export async function getOrCreateProfile(userId: string): Promise<VeracityProfile> {
  // Upsert a row for this user — if it already exists, do nothing (ignoreDuplicates)
  const { error: upsertError } = await supabaseService
    .schema('validation_quests')
    .from('user_veracity_profiles')
    .upsert({ user_id: userId }, { onConflict: 'user_id', ignoreDuplicates: true });

  if (upsertError) {
    logger.error('Failed to upsert veracity profile', { userId, error: upsertError.message });
    throw new Error(`Failed to get or create veracity profile for user ${userId}`);
  }

  // Read back the current profile
  const { data, error: selectError } = await supabaseService
    .schema('validation_quests')
    .from('user_veracity_profiles')
    .select('credibility_score, credibility_infraction_count, restriction_state')
    .eq('user_id', userId)
    .single();

  if (selectError || !data) {
    logger.error('Failed to read veracity profile', { userId, error: selectError?.message });
    throw new Error(`Failed to read veracity profile for user ${userId}`);
  }

  return data as VeracityProfile;
}

/**
 * checkSubmissionEligibility — determine whether a user can submit.
 *
 * @returns
 *   { eligible: false, reason: 'locked_out', score }  — user is locked out (score < 0)
 *   { eligible: true, quarantined: boolean, score }    — user can submit; quarantined if score < 40
 */
export async function checkSubmissionEligibility(userId: string): Promise<
  | { eligible: false; reason: 'locked_out'; score: number }
  | { eligible: true; quarantined: boolean; score: number }
> {
  const profile = await getOrCreateProfile(userId);
  const score = profile.credibility_score;

  if (score < LOCKOUT_THRESHOLD) {
    return { eligible: false, reason: 'locked_out', score };
  }

  return {
    eligible: true,
    quarantined: score < QUARANTINE_THRESHOLD,
    score,
  };
}

/**
 * applyCredibilityChange — update the user's credibility score for a submission event.
 *
 * Events:
 *   'source_accepted' → +1 (credibility_gain)
 *   'source_rejected' → -1 first offense (credibility_warning), escalating on repeats (credibility_loss)
 *
 * Logs the event to veracity_event_logs.
 * Returns the CredibilityChangeResult for inclusion in API responses.
 */
export async function applyCredibilityChange(
  userId: string,
  questId: string,
  event: 'source_accepted' | 'source_rejected'
): Promise<CredibilityChangeResult> {
  const profile = await getOrCreateProfile(userId);
  const previousScore = profile.credibility_score;
  const previousInfractionCount = profile.credibility_infraction_count;

  let delta: number;
  let eventType: string;
  let reason: string;
  let newInfractionCount = previousInfractionCount;

  if (event === 'source_accepted') {
    delta = 1;
    eventType = 'credibility_gain';
    reason = 'Source validated successfully';
  } else {
    // source_rejected
    if (previousInfractionCount === 0) {
      // First offense — soft warning
      delta = -1;
      eventType = 'credibility_warning';
      reason = 'First source validation failure — educational warning';
    } else {
      // Repeat offense — escalating penalty, capped at -10
      delta = -Math.min(10, 2 + previousInfractionCount);
      eventType = 'credibility_loss';
      reason = `Repeat source validation failure (offense ${previousInfractionCount + 1})`;
    }
    newInfractionCount = previousInfractionCount + 1;
  }

  const newScore = clamp(previousScore + delta, SCORE_MIN, SCORE_MAX);

  // Update the profile
  const updatePayload: Record<string, unknown> = {
    credibility_score: newScore,
    credibility_infraction_count: newInfractionCount,
    updated_at: new Date().toISOString(),
  };

  const { error: updateError } = await supabaseService
    .schema('validation_quests')
    .from('user_veracity_profiles')
    .update(updatePayload)
    .eq('user_id', userId);

  if (updateError) {
    logger.error('Failed to update credibility score', {
      userId,
      event,
      delta,
      error: updateError.message,
    });
    throw new Error(`Failed to update credibility score for user ${userId}`);
  }

  // Log event to veracity_event_logs
  const { error: logError } = await supabaseService
    .schema('validation_quests')
    .from('veracity_event_logs')
    .insert({
      user_id: userId,
      event_type: eventType,
      quest_id: questId,
      previous_weight: previousScore,  // repurposing weight columns for credibility score
      new_weight: newScore,
      delta,
    });

  if (logError) {
    // Non-fatal: log the failure but don't fail the request over audit log issues
    logger.warn('Failed to write veracity event log', {
      userId,
      questId,
      eventType,
      error: logError.message,
    });
  }

  const quarantined = newScore < QUARANTINE_THRESHOLD && newScore >= LOCKOUT_THRESHOLD;
  const locked_out = newScore < LOCKOUT_THRESHOLD;

  logger.info('Credibility score updated', {
    userId,
    event,
    previousScore,
    newScore,
    delta,
    quarantined,
    locked_out,
  });

  return {
    current_score: newScore,
    change: delta,
    reason,
    quarantined,
    locked_out,
  };
}
