/**
 * veracityTracking.ts
 * Post-consensus veracity profile updates, restriction state machine,
 * educational feedback generation, and time-decayed accuracy metrics.
 *
 * Architecture:
 *   Pure functions (no I/O) — directly unit-testable:
 *     computeScoreDelta, computeVeracityWithDecay, generateEducationalFeedback,
 *     checkDailySpikeGuard, determineRestrictionState
 *
 *   Database functions (use supabaseService):
 *     processConsensusOutcome, updateAccuracyMetrics
 */

import { CREDIBILITY_DELTAS } from './consensus.js';
import { supabaseService } from '../lib/supabase.js';
import { logger } from '../lib/logger.js';
import type { RestrictionState, Source, UserAction } from '../types/custom.js';
import { invalidateFeedCache, getAllowedTiers } from '../services/feedScoring.js';

// Re-export the type for consumers
export type { RestrictionState };

// ============================================================
// TYPES
// ============================================================

export interface EducationalFeedback {
  correct_answer: string;
  sources: Source[];
  research_tips?: string; // Only present for incorrect submitters
}

export interface SpikeGuardResult {
  triggered: boolean;
  newCount: number;
  newResetAt: string | null;
  shouldReset: boolean;
}

export interface AccuracyTimeframes {
  last7d: number;
  last30d: number;
  allTime: number;
}

// ============================================================
// HELPERS
// ============================================================

/**
 * Clamp a number between min and max (inclusive).
 */
function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

const SCORE_MIN = -100;
const SCORE_MAX = 200;

// ============================================================
// PURE FUNCTIONS (no I/O)
// ============================================================

/**
 * computeScoreDelta — returns the credibility delta for a given consensus outcome.
 *
 * Asymmetric by design per CONTEXT.md:
 *   Correct:                   +5
 *   Incorrect + ignored:       -15 (harshest; user did nothing with feedback)
 *   Incorrect + acknowledged:  -8  (~50% penalty; user engaged with feedback)
 *   Incorrect + contested:      0  (outcome uncertain; no penalty until resolved)
 */
export function computeScoreDelta(
  outcome: 'correct' | 'incorrect',
  userAction: 'acknowledged' | 'contested_with_evidence' | 'ignored'
): number {
  if (outcome === 'correct') {
    return CREDIBILITY_DELTAS.CORRECT;
  }
  // incorrect
  if (userAction === 'ignored') {
    return CREDIBILITY_DELTAS.INCORRECT_IGNORED;
  }
  if (userAction === 'acknowledged') {
    return CREDIBILITY_DELTAS.INCORRECT_ACKNOWLEDGED;
  }
  // contested_with_evidence
  return CREDIBILITY_DELTAS.INCORRECT_CONTESTED;
}

/**
 * computeVeracityWithDecay — computes accuracy rates by timeframe with time decay.
 *
 * allTime decay weights:
 *   < 30 days ago:    100% weight
 *   30–60 days ago:    50% weight
 *   > 60 days ago:     25% weight
 *
 * last30d and last7d: no decay applied within their windows (all submissions count equally).
 *
 * Returns percentages as 0-100 numbers. Returns 0 for any timeframe with no submissions.
 */
export function computeVeracityWithDecay(
  submissions: Array<{ outcome: 'correct' | 'incorrect'; createdAt: string }>,
  now: Date
): AccuracyTimeframes {
  if (submissions.length === 0) {
    return { last7d: 0, last30d: 0, allTime: 0 };
  }

  const MS_PER_DAY = 24 * 60 * 60 * 1000;
  const nowMs = now.getTime();

  let weightedCorrect = 0;
  let weightedTotal = 0;
  let correct30d = 0;
  let total30d = 0;
  let correct7d = 0;
  let total7d = 0;

  for (const sub of submissions) {
    const ageMs = nowMs - new Date(sub.createdAt).getTime();
    const ageDays = ageMs / MS_PER_DAY;
    const isCorrect = sub.outcome === 'correct';

    // allTime with decay
    let weight: number;
    if (ageDays > 60) {
      weight = 0.25;
    } else if (ageDays > 30) {
      weight = 0.5;
    } else {
      weight = 1.0;
    }
    weightedTotal += weight;
    if (isCorrect) weightedCorrect += weight;

    // last30d (no decay, only submissions within 30 days)
    if (ageDays <= 30) {
      total30d += 1;
      if (isCorrect) correct30d += 1;

      // last7d (subset of 30d window)
      if (ageDays <= 7) {
        total7d += 1;
        if (isCorrect) correct7d += 1;
      }
    }
  }

  return {
    last7d: total7d === 0 ? 0 : (correct7d / total7d) * 100,
    last30d: total30d === 0 ? 0 : (correct30d / total30d) * 100,
    allTime: weightedTotal === 0 ? 0 : (weightedCorrect / weightedTotal) * 100,
  };
}

/**
 * generateEducationalFeedback — builds the feedback object for a submitter.
 *
 * All submitters (correct and incorrect) receive correct_answer and sources.
 * Incorrect submitters additionally receive quest-type-specific research_tips.
 *
 * Note: Callers decide whether to include research_tips. This function always
 * returns research_tips in the result; callers strip it for correct submitters.
 */
export function generateEducationalFeedback(
  questType: 'official' | 'fact' | 'policy',
  correctAnswer: string,
  correctSources: Array<{ url: string; source_type: string; retrieved_date: string; description: string }>
): Required<EducationalFeedback> {
  const tips: Record<'official' | 'fact' | 'policy', string> = {
    official:
      'For verifying public officials: check the jurisdiction\'s official government website for current rosters, cross-reference with Ballotpedia, and verify against the official election results page.',
    fact:
      'For verifying civic facts: use official government databases and primary source documents. Check publication dates to ensure timeliness. Cross-reference at least two independent sources.',
    policy:
      'For verifying policy information: read the actual bill or ordinance text on the legislature\'s website. Check legislative tracking sites for current status. Verify against the jurisdiction\'s official legislative record.',
  };

  return {
    correct_answer: correctAnswer,
    sources: correctSources as Source[],
    research_tips: tips[questType],
  };
}

/**
 * checkDailySpikeGuard — rolling 24h window check for rapid-fire incorrect submissions.
 *
 * Three or more incorrect submissions within 24 hours triggers review_required.
 * If the 24h window has expired, resets the counter.
 *
 * Returns a result object with:
 *   triggered:    whether 3+ incorrects have been reached
 *   newCount:     updated daily_incorrect_count
 *   newResetAt:   updated daily_incorrect_reset_at
 *   shouldReset:  whether the window was reset (expired or first time)
 */
export function checkDailySpikeGuard(
  dailyIncorrectCount: number,
  dailyIncorrectResetAt: string | null,
  now: Date
): SpikeGuardResult {
  const WINDOW_MS = 24 * 60 * 60 * 1000;
  const nowMs = now.getTime();

  const shouldReset =
    dailyIncorrectResetAt === null ||
    nowMs - new Date(dailyIncorrectResetAt).getTime() > WINDOW_MS;

  const newCount = shouldReset ? 1 : dailyIncorrectCount + 1;
  const newResetAt = shouldReset ? now.toISOString() : dailyIncorrectResetAt;

  return {
    triggered: newCount >= 3,
    newCount,
    newResetAt,
    shouldReset,
  };
}

/**
 * determineRestrictionState — pure state machine for restriction levels.
 *
 * Priority (highest → lowest):
 *   1. suspended:       credibilityScore < 0  (lockout — cannot submit at all)
 *   2. review_required: spikeGuard triggered, OR current state is review_required
 *                       and spike not cleared (sticky until admin clears)
 *   3. limited:         credibilityScore < 40 (quarantine — stored but excluded from consensus)
 *   4. warning:         credibilityScore < 70 (gentle prompt)
 *   5. none:            everything healthy
 */
export function determineRestrictionState(
  credibilityScore: number,
  spikeGuardTriggered: boolean,
  currentRestriction: RestrictionState
): RestrictionState {
  // Highest priority: lockout
  if (credibilityScore < 0) {
    return 'suspended';
  }

  // Spike guard triggers review_required (unless already suspended above)
  if (spikeGuardTriggered) {
    return 'review_required';
  }

  // Sticky: once review_required, stays until admin clears
  if (currentRestriction === 'review_required') {
    return 'review_required';
  }

  // Quarantine
  if (credibilityScore < 40) {
    return 'limited';
  }

  // Warning
  if (credibilityScore < 70) {
    return 'warning';
  }

  return 'none';
}

// ============================================================
// DATABASE FUNCTIONS
// ============================================================

/**
 * processConsensusOutcome — orchestrates all post-consensus updates for a single user.
 *
 * Steps:
 *   a. Compute score delta
 *   b. Read current veracity profile
 *   c. Check daily spike guard (if incorrect)
 *   d. Clamp new credibility score
 *   e. Determine new restriction state
 *   f. Update veracity profile
 *   g. Write veracity event log
 *   h. Write feedback JSONB to submission
 *   i. Log restriction_changed event (if state changed)
 */
export async function processConsensusOutcome(params: {
  userId: string;
  questId: string;
  submissionId: string;
  outcome: 'correct' | 'incorrect';
  userAction?: 'acknowledged' | 'contested_with_evidence' | 'ignored';
  correctAnswer: string;
  correctSources: Source[];
  questType: 'official' | 'fact' | 'policy';
}): Promise<void> {
  const {
    userId,
    questId,
    submissionId,
    outcome,
    userAction,
    correctAnswer,
    correctSources,
    questType,
  } = params;

  const resolvedUserAction: UserAction = userAction ?? 'ignored';

  // a. Compute score delta
  const delta = computeScoreDelta(outcome, resolvedUserAction);

  // b. Read current veracity profile
  const { data: profile, error: profileError } = await supabaseService
    .schema('validation_quests')
    .from('user_veracity_profiles')
    .select(
      'credibility_score, daily_incorrect_count, daily_incorrect_reset_at, restriction_state, total_submissions, correct_submissions, incorrect_submissions, pending_submissions, restriction_reason'
    )
    .eq('user_id', userId)
    .single();

  if (profileError || !profile) {
    logger.error('Failed to read veracity profile for consensus outcome', {
      userId,
      questId,
      error: profileError?.message,
    });
    throw new Error(`Failed to read veracity profile for user ${userId}`);
  }

  const currentScore: number = profile.credibility_score;
  const currentRestriction: RestrictionState = profile.restriction_state as RestrictionState;

  // c. Check daily spike guard for incorrect submissions
  let spikeGuardTriggered = false;
  let newDailyCount = profile.daily_incorrect_count;
  let newDailyResetAt: string | null = profile.daily_incorrect_reset_at;

  if (outcome === 'incorrect') {
    const spikeResult = checkDailySpikeGuard(
      profile.daily_incorrect_count,
      profile.daily_incorrect_reset_at,
      new Date()
    );
    spikeGuardTriggered = spikeResult.triggered;
    newDailyCount = spikeResult.newCount;
    newDailyResetAt = spikeResult.newResetAt;
  }

  // d. Compute new credibility score
  const newScore = clamp(currentScore + delta, SCORE_MIN, SCORE_MAX);

  // e. Determine new restriction state
  const newRestriction = determineRestrictionState(newScore, spikeGuardTriggered, currentRestriction);

  // f. Update veracity profile
  const profileUpdate: Record<string, unknown> = {
    credibility_score: newScore,
    updated_at: new Date().toISOString(),
  };

  if (outcome === 'correct') {
    profileUpdate.correct_submissions = (profile.correct_submissions as number) + 1;
  } else {
    profileUpdate.incorrect_submissions = (profile.incorrect_submissions as number) + 1;
    profileUpdate.daily_incorrect_count = newDailyCount;
    profileUpdate.daily_incorrect_reset_at = newDailyResetAt;
  }

  // Decrement pending (this submission has been resolved)
  profileUpdate.pending_submissions = Math.max(0, (profile.pending_submissions as number) - 1);

  if (newRestriction !== currentRestriction) {
    profileUpdate.restriction_state = newRestriction;
    profileUpdate.restriction_reason =
      newRestriction === 'none'
        ? null
        : buildRestrictionReason(newRestriction, newScore, spikeGuardTriggered);
  }

  const { error: updateError } = await supabaseService
    .schema('validation_quests')
    .from('user_veracity_profiles')
    .update(profileUpdate)
    .eq('user_id', userId);

  if (updateError) {
    logger.error('Failed to update veracity profile', {
      userId,
      questId,
      error: updateError.message,
    });
    throw new Error(`Failed to update veracity profile for user ${userId}`);
  }

  // g. Write veracity event log
  const eventType = outcome === 'correct' ? 'consensus_correct' : 'consensus_incorrect';

  const { error: logError } = await supabaseService
    .schema('validation_quests')
    .from('veracity_event_logs')
    .insert({
      user_id: userId,
      event_type: eventType,
      quest_id: questId,
      previous_weight: currentScore,
      new_weight: newScore,
      delta,
      user_action: resolvedUserAction,
    });

  if (logError) {
    logger.warn('Failed to write veracity event log', {
      userId,
      questId,
      eventType,
      error: logError.message,
    });
  }

  // h. Write feedback JSONB to submission
  let feedbackPayload: EducationalFeedback;

  if (outcome === 'correct') {
    // Correct submitters: answer + sources only (no research_tips)
    feedbackPayload = {
      correct_answer: correctAnswer,
      sources: correctSources,
    };
  } else {
    // Incorrect submitters: answer + sources + research_tips
    const fullFeedback = generateEducationalFeedback(questType, correctAnswer, correctSources);
    feedbackPayload = fullFeedback;
  }

  const { error: feedbackError } = await supabaseService
    .schema('validation_quests')
    .from('verification_submissions')
    .update({ feedback: feedbackPayload })
    .eq('id', submissionId);

  if (feedbackError) {
    logger.warn('Failed to write feedback to submission', {
      userId,
      questId,
      submissionId,
      error: feedbackError.message,
    });
  }

  // i. Log restriction_changed event if state changed
  if (newRestriction !== currentRestriction) {
    const { error: restrictionLogError } = await supabaseService
      .schema('validation_quests')
      .from('veracity_event_logs')
      .insert({
        user_id: userId,
        event_type: 'restriction_changed',
        quest_id: questId,
        previous_weight: null,
        new_weight: null,
        delta: null,
        user_action: null,
      });

    if (restrictionLogError) {
      logger.warn('Failed to write restriction_changed event log', {
        userId,
        questId,
        previousRestriction: currentRestriction,
        newRestriction,
        error: restrictionLogError.message,
      });
    }
  }

  logger.info('Processed consensus outcome', {
    userId,
    questId,
    submissionId,
    outcome,
    previousScore: currentScore,
    newScore,
    delta,
    previousRestriction: currentRestriction,
    newRestriction,
    spikeGuardTriggered,
  });
}

/**
 * updateAccuracyMetrics — recomputes time-decayed accuracy metrics for a user.
 *
 * Fetches all resolved submissions (outcome = 'correct' | 'incorrect'),
 * calls computeVeracityWithDecay, and updates:
 *   - accuracy_by_timeframe (last7d, last30d, allTime)
 *   - accuracy_rate (allTime percentage)
 *   - accuracy_by_difficulty_tier (per-tier accuracy by joining with quests)
 */
export async function updateAccuracyMetrics(userId: string, previousAccuracyRate?: number | null): Promise<void> {
  // Fetch all resolved submissions for this user with quest difficulty tier
  const { data: submissions, error: subsError } = await supabaseService
    .schema('validation_quests')
    .from('verification_submissions')
    .select('outcome, created_at, quest_id')
    .eq('user_id', userId)
    .in('outcome', ['correct', 'incorrect']);

  if (subsError) {
    logger.error('Failed to fetch submissions for accuracy metrics', {
      userId,
      error: subsError.message,
    });
    throw new Error(`Failed to fetch submissions for accuracy metrics for user ${userId}`);
  }

  if (!submissions || submissions.length === 0) {
    return;
  }

  // Map submissions for computeVeracityWithDecay
  const mappedSubmissions = submissions.map((s) => ({
    outcome: s.outcome as 'correct' | 'incorrect',
    createdAt: s.created_at as string,
  }));

  const timeframes = computeVeracityWithDecay(mappedSubmissions, new Date());

  // Compute accuracy_by_difficulty_tier
  // Fetch quest difficulty tiers for the submission quest IDs
  const questIds = [...new Set(submissions.map((s) => s.quest_id as string))];
  const { data: quests, error: questsError } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .select('id, difficulty_tier')
    .in('id', questIds);

  const accuracyByTier: Record<string, number> = {};

  if (!questsError && quests && quests.length > 0) {
    // Build a map of quest_id → difficulty_tier
    const tierMap: Record<string, number> = {};
    for (const q of quests) {
      tierMap[q.id as string] = q.difficulty_tier as number;
    }

    // Group submissions by tier
    const tierBuckets: Record<string, { correct: number; total: number }> = {};
    for (const sub of submissions) {
      const tier = String(tierMap[sub.quest_id as string] ?? 'unknown');
      if (!tierBuckets[tier]) {
        tierBuckets[tier] = { correct: 0, total: 0 };
      }
      tierBuckets[tier].total += 1;
      if (sub.outcome === 'correct') {
        tierBuckets[tier].correct += 1;
      }
    }

    for (const [tier, { correct, total }] of Object.entries(tierBuckets)) {
      accuracyByTier[tier] = total === 0 ? 0 : (correct / total) * 100;
    }
  }

  // Update the profile
  const { error: updateError } = await supabaseService
    .schema('validation_quests')
    .from('user_veracity_profiles')
    .update({
      accuracy_by_timeframe: timeframes,
      accuracy_rate: timeframes.allTime,
      accuracy_by_difficulty_tier: accuracyByTier,
      updated_at: new Date().toISOString(),
    })
    .eq('user_id', userId);

  if (updateError) {
    logger.error('Failed to update accuracy metrics', {
      userId,
      error: updateError.message,
    });
    throw new Error(`Failed to update accuracy metrics for user ${userId}`);
  }

  // Check if accuracy_rate crossed a feed tier boundary (75% or 85%).
  // previousAccuracyRate: the old rate before this update (from SubmissionRow.accuracy_rate
  // snapshot in consensusBatchJob — already pre-update). Undefined callers default to null.
  const oldTiers = getAllowedTiers(previousAccuracyRate ?? null);
  const newTiers = getAllowedTiers(timeframes.allTime);
  if (oldTiers.length !== newTiers.length) {
    try {
      await invalidateFeedCache(userId);
    } catch (cacheErr) {
      logger.warn('Failed to invalidate feed cache on tier crossing', {
        userId,
        error: String(cacheErr),
      });
    }
  }

  logger.info('Updated accuracy metrics', {
    userId,
    timeframes,
    tierCount: Object.keys(accuracyByTier).length,
  });
}

// ============================================================
// INTERNAL HELPERS
// ============================================================

function buildRestrictionReason(
  state: RestrictionState,
  score: number,
  spikeGuard: boolean
): string {
  switch (state) {
    case 'suspended':
      return `Credibility score ${score} below lockout threshold (0)`;
    case 'review_required':
      if (spikeGuard) {
        return '3 or more incorrect submissions in 24 hours — account flagged for review';
      }
      return 'Account flagged for review';
    case 'limited':
      return `Credibility score ${score} below quarantine threshold (40)`;
    case 'warning':
      return `Credibility score ${score} below warning threshold (70)`;
    default:
      return '';
  }
}
