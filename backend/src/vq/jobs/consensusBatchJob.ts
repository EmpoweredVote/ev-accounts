/**
 * consensusBatchJob.ts
 * Consensus batch job orchestration with built-in overlap guard.
 *
 * Exported:
 *   runConsensusPass — fetches eligible quests, runs the algorithm,
 *                      writes results, and triggers veracity updates.
 *   _resetIsRunning  — test-only: resets the overlap guard flag.
 *
 * Quests processed sequentially (NOT Promise.all) to avoid connection
 * pool exhaustion under high submission volumes.
 *
 * 48-hour contestation window:
 *   - threshold_met_at is set on the first resolved pass.
 *   - finalized_at is set 48h later; quest status → consensus_reached only then.
 *   - Veracity outcomes are processed only on finalization.
 */

import { supabaseService } from '../lib/supabase.js';
import { computeConsensus } from '../services/consensus.js';
import { writeToEssentials } from '../services/essentialsPipeline.js';
import type { ConsensusSubmission, ConsensusInput, ConsensusResultType } from '../services/consensus.js';
import {
  processConsensusOutcome,
  updateAccuracyMetrics,
} from '../services/veracityTracking.js';
import {
  awardYellowGem,
  awardRedGem,
  awardEarlyBonus,
  isEarlySubmission,
} from '../services/rewards.js';
import { writeNotification } from '../services/notificationService.js';
import { logger } from '../lib/logger.js';
import type { Source } from '../types/custom.js';
// Engine consolidation (VQ consensus fold-in): the finalization callbacks now run in-process
// against the engine's own services instead of HTTP loopbacks to /api/vq/* and /api/xp/award
// carrying VQ_SERVICE_KEY / QUEST_SERVICE_KEY. Same RPCs, same idempotency keys, no keys.
import { confirmVqStance, adjustVerificationRating } from '../../lib/vqService.js';
import { awardXp } from '../../lib/xpService.js';
import { unlockReferralCode, maybeRefreshReferralForInvitee } from '../../lib/referralService.js';

// ============================================================
// OVERLAP GUARD
// A module-level flag prevents concurrent batch runs.
// If the previous cycle is still running when the cron fires,
// the new invocation returns immediately as a no-op.
// ============================================================
let isRunning = false;

/**
 * @internal — for test cleanup only. Do not call in production code.
 */
export function _resetIsRunning(): void {
  isRunning = false;
}

// ============================================================
// CONSTANTS
// ============================================================
const CONTESTATION_WINDOW_MS = 48 * 60 * 60 * 1000; // 48 hours
const CREDIBILITY_QUARANTINE_THRESHOLD = 40;

// ============================================================
// INTERNAL TYPES
// ============================================================

interface QuestRow {
  id: string;
  type: 'official' | 'fact' | 'policy';
  bridging_waived: boolean;
  gem_quest_type: string;
  // Stance quest fields — all three required for confirm-stance at finalization
  politician_id: string | null;
  topic_id: string | null;
  confirmed_value: number | null;
}

interface SubmissionRow {
  id: string;
  user_id: string;
  normalized_answer: string | null;
  submitter_type: 'human_connected' | 'human_empowered' | 'ai_agent';
  created_at: string;
  sources: Source[];
  credibility_score: number;
  accuracy_rate: number | null;
  veracity_suspended: boolean;
}

interface ConsensusRecordRow {
  id: string;
  threshold_met_at: string | null;
  finalized_at: string | null;
  consensus_answer: string;
  authoritative_sources: Source[];
}

// ============================================================
// MAIN EXPORT
// ============================================================

/**
 * runConsensusPass — processes all eligible quests in a single batch cycle.
 *
 * If a previous call is still running (isRunning = true), this call
 * returns immediately as a no-op.
 */
export async function runConsensusPass(): Promise<void> {
  if (isRunning) {
    logger.warn('Consensus batch job still running — skipping this cycle');
    return;
  }
  isRunning = true;

  let processedCount = 0;
  let resolvedCount = 0;
  let conflictingCount = 0;
  let pendingCount = 0;
  let finalizedCount = 0;

  try {
    // ----------------------------------------------------------
    // Step 1: Fetch eligible quests (active or under_review)
    // ----------------------------------------------------------
    const { data: quests, error: questsError } = await supabaseService
      .schema('validation_quests')
      .from('verification_quests')
      .select('id, type, bridging_waived, gem_quest_type, politician_id, topic_id, confirmed_value')
      .in('status', ['active', 'under_review']);

    if (questsError) {
      logger.error('Consensus batch: failed to fetch eligible quests', {
        error: questsError.message,
      });
      return;
    }

    if (!quests || quests.length === 0) {
      logger.info('Consensus batch: no eligible quests to process');
      return;
    }

    // ----------------------------------------------------------
    // Step 2: Process quests sequentially (no Promise.all)
    // ----------------------------------------------------------
    for (const quest of quests as QuestRow[]) {
      try {
        const result = await processQuest(quest);
        processedCount++;
        switch (result) {
          case 'resolved':
            resolvedCount++;
            break;
          case 'conflicting':
            conflictingCount++;
            break;
          case 'finalized':
            finalizedCount++;
            break;
          default:
            pendingCount++;
        }
      } catch (err) {
        logger.error('Consensus batch: error processing quest', {
          questId: quest.id,
          error: String(err),
        });
      }
    }
  } finally {
    isRunning = false;
  }

  logger.info('Consensus batch complete', {
    processedCount,
    resolvedCount,
    conflictingCount,
    pendingCount,
    finalizedCount,
  });
}

// ============================================================
// INTERNAL: process a single quest
// ============================================================

async function processQuest(
  quest: QuestRow
): Promise<'resolved' | 'conflicting' | 'pending' | 'finalized' | 'skipped'> {
  const questId = quest.id;

  // ----------------------------------------------------------
  // a. Fetch all submissions for this quest
  // ----------------------------------------------------------
  const { data: submissionRows, error: subsError } = await supabaseService
    .schema('validation_quests')
    .from('verification_submissions')
    .select('id, user_id, normalized_answer, submitter_type, created_at, sources, veracity_suspended')
    .eq('quest_id', questId);

  if (subsError) {
    logger.error('Consensus batch: failed to fetch submissions', {
      questId,
      error: subsError.message,
    });
    return 'skipped';
  }

  const rawSubmissions = (submissionRows as unknown[]) ?? [];

  // Collect unique human user IDs to fetch veracity profiles in one query
  const humanUserIds = [
    ...new Set(
      rawSubmissions
        .map((r) => (r as Record<string, unknown>)['user_id'] as string)
    ),
  ];

  // Fetch veracity profiles for all submitters (AI agents have no profiles — COALESCE default used)
  const profileMap = new Map<string, { credibility_score: number; accuracy_rate: number | null }>();

  if (humanUserIds.length > 0) {
    const { data: profiles } = await supabaseService
      .schema('validation_quests')
      .from('user_veracity_profiles')
      .select('user_id, credibility_score, accuracy_rate')
      .in('user_id', humanUserIds);

    for (const p of (profiles as unknown[]) ?? []) {
      const profile = p as { user_id: string; credibility_score: number; accuracy_rate: number | null };
      profileMap.set(profile.user_id, {
        credibility_score: profile.credibility_score,
        accuracy_rate: profile.accuracy_rate,
      });
    }
  }

  const submissions: SubmissionRow[] = rawSubmissions.map((row: unknown) => {
    const r = row as Record<string, unknown>;
    const userId = r['user_id'] as string;
    const profile = profileMap.get(userId);

    return {
      id: r['id'] as string,
      user_id: userId,
      normalized_answer: r['normalized_answer'] as string | null,
      submitter_type: r['submitter_type'] as 'human_connected' | 'human_empowered' | 'ai_agent',
      created_at: r['created_at'] as string,
      sources: (r['sources'] as Source[]) ?? [],
      // COALESCE default 100 per plan spec
      credibility_score: profile?.credibility_score ?? 100,
      accuracy_rate: profile?.accuracy_rate ?? null,
      veracity_suspended: (r['veracity_suspended'] as boolean) ?? false,
    };
  });

  // ----------------------------------------------------------
  // b. Check for existing consensus record
  // ----------------------------------------------------------
  const { data: existingRecord, error: recordError } = await supabaseService
    .schema('validation_quests')
    .from('consensus_records')
    .select('id, threshold_met_at, finalized_at, consensus_answer, authoritative_sources')
    .eq('quest_id', questId)
    .maybeSingle();

  if (recordError) {
    logger.error('Consensus batch: failed to fetch consensus record', {
      questId,
      error: recordError.message,
    });
    return 'skipped';
  }

  const record = existingRecord as ConsensusRecordRow | null;

  // ----------------------------------------------------------
  // c. If already finalized — skip
  // ----------------------------------------------------------
  if (record && record.finalized_at !== null) {
    return 'skipped';
  }

  // ----------------------------------------------------------
  // d. If threshold was already reached — check 48h window
  // ----------------------------------------------------------
  if (record && record.threshold_met_at !== null) {
    const thresholdMetMs = new Date(record.threshold_met_at).getTime();
    const now = Date.now();
    const elapsed = now - thresholdMetMs;

    if (elapsed >= CONTESTATION_WINDOW_MS) {
      // 48 hours have passed — finalize
      await finalizeConsensus(questId, record, submissions, quest);
      return 'finalized';
    }

    // Not yet 48h — re-run algorithm to update record if result changed, but don't
    // reset threshold_met_at and don't change quest to consensus_reached yet
    const consensusInput = buildConsensusInput(quest, submissions);
    const result = computeConsensus(consensusInput);

    if (result.status === 'resolved') {
      await updateConsensusRecord(questId, record.id, result, submissions);
    }

    return 'pending';
  }

  // ----------------------------------------------------------
  // e/f. No existing record — run algorithm
  // ----------------------------------------------------------
  const consensusInput = buildConsensusInput(quest, submissions);
  const result = computeConsensus(consensusInput);

  switch (result.status) {
    case 'pending':
      return 'pending';

    case 'needs_more_human_verification':
      logger.info('Consensus batch: quest needs more human verification', {
        questId,
        humanCount: result.humanCount,
        totalCount: result.totalCount,
        humanPercentage: result.humanPercentage.toFixed(1),
      });
      // Quest stays active — no status change
      return 'pending';

    case 'bridging_failed':
      logger.info('Consensus batch: bridging diversity check failed', {
        questId,
        reason: result.reason,
      });
      // Quest stays active — no status change
      return 'pending';

    case 'conflicting':
      // Set quest status to under_review — flag for admin
      await supabaseService
        .schema('validation_quests')
        .from('verification_quests')
        .update({ status: 'under_review', updated_at: new Date().toISOString() })
        .eq('id', questId);

      logger.warn('Consensus batch: conflicting quest flagged for admin review', {
        questId,
        totalSubmissions: result.totalSubmissions,
        alignmentPercentage: result.alignmentPercentage.toFixed(1),
      });
      return 'conflicting';

    case 'resolved': {
      // INSERT consensus_records with threshold_met_at = NOW()
      // Do NOT set finalized_at yet; do NOT change quest to consensus_reached yet
      await insertConsensusRecord(questId, result, submissions, quest);
      return 'resolved';
    }
  }
}

// ============================================================
// INTERNAL: build ConsensusInput from SubmissionRow[]
// ============================================================

function buildConsensusInput(quest: QuestRow, submissions: SubmissionRow[]): ConsensusInput {
  const consensusSubmissions: ConsensusSubmission[] = submissions
    .filter((s) => s.normalized_answer !== null)
    .map((s) => ({
      id: s.id,
      userId: s.user_id,
      normalizedAnswer: s.normalized_answer!,
      submitterType: s.submitter_type,
      credibilityScore: s.credibility_score,
      accuracyRate: s.accuracy_rate,
      createdAt: s.created_at,
    }));

  return {
    questId: quest.id,
    questType: quest.type,
    bridgingWaived: quest.bridging_waived,
    submissions: consensusSubmissions,
  };
}

// ============================================================
// INTERNAL: collect authoritative sources from correct submitters
// ============================================================

function collectAuthoritativeSources(
  correctSubmissionIds: string[],
  submissions: SubmissionRow[]
): Source[] {
  const seen = new Set<string>();
  const sources: Source[] = [];

  for (const sub of submissions) {
    if (!correctSubmissionIds.includes(sub.id)) continue;
    for (const source of sub.sources) {
      if (!seen.has(source.url)) {
        seen.add(source.url);
        sources.push(source);
      }
    }
  }

  return sources;
}

// ============================================================
// INTERNAL: insert a new consensus record (first resolved pass)
// ============================================================

async function insertConsensusRecord(
  questId: string,
  result: Extract<ConsensusResultType, { status: 'resolved' }>,
  submissions: SubmissionRow[],
  quest: QuestRow
): Promise<void> {
  const now = new Date().toISOString();
  const authoritativeSources = collectAuthoritativeSources(result.correctSubmissionIds, submissions);

  const { data: insertedRecord, error } = await supabaseService
    .schema('validation_quests')
    .from('consensus_records')
    .insert({
      quest_id: questId,
      consensus_answer: result.consensusAnswer,
      confidence_level: result.confidenceLevel,
      total_submissions: result.totalSubmissions,
      alignment_percentage: result.alignmentPercentage,
      human_count: result.humanCount,
      ai_count: result.aiCount,
      human_percentage: result.humanPercentage,
      answer_distribution: result.answerDistribution,
      authoritative_sources: authoritativeSources,
      consensus_date: now,
      last_verified_date: now,
      threshold_met_at: now,
      finalized_at: null,
      bridging_waived: quest.bridging_waived,
    })
    .select('id')
    .single() as { data: { id: string } | null; error: { message: string } | null };

  if (error) {
    logger.error('Consensus batch: failed to insert consensus record', {
      questId,
      error: error.message,
    });
    throw new Error(`Failed to insert consensus record for quest ${questId}`);
  }

  const consensusRecordId = insertedRecord?.id ?? '';

  logger.info('Consensus batch: consensus record inserted, contestation window open', {
    questId,
    confidenceLevel: result.confidenceLevel,
    alignmentPercentage: result.alignmentPercentage,
    totalSubmissions: result.totalSubmissions,
  });

  // ----------------------------------------------------------
  // Award Yellow gems to correct human submitters (REWARD-01)
  // Fetches quest gem_reward as the authoritative gem amount
  // (includes any bounty overrides, per design)
  // ----------------------------------------------------------
  const { data: questData } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .select('gem_reward')
    .eq('id', questId)
    .maybeSingle();

  const gemReward = (questData as { gem_reward: number } | null)?.gem_reward ?? 0;

  let yellowGemCount = 0;
  for (const sub of submissions) {
    if (!result.correctSubmissionIds.includes(sub.id)) continue;
    if (sub.submitter_type === 'ai_agent') continue; // AI agents do not receive gems

    await awardYellowGem({
      userId: sub.user_id,
      questId,
      gemAmount: 3, // 1 (correct answer) + 2 (valid source); gem_reward column no longer the source of truth
      confidenceLevel: result.confidenceLevel,
      submissionCreatedAt: sub.created_at,
      thresholdMetAt: now,
      consensusRecordId,
    });
    yellowGemCount++;
  }

  if (yellowGemCount > 0) {
    logger.info('Consensus batch: Yellow gems awarded at threshold', {
      questId,
      yellowGemCount,
      gemReward,
    });
  }
}

// ============================================================
// INTERNAL: update an existing consensus record (re-run during contestation window)
// ============================================================

async function updateConsensusRecord(
  questId: string,
  recordId: string,
  result: Extract<ConsensusResultType, { status: 'resolved' }>,
  submissions: SubmissionRow[]
): Promise<void> {
  const authoritativeSources = collectAuthoritativeSources(result.correctSubmissionIds, submissions);

  const { error } = await supabaseService
    .schema('validation_quests')
    .from('consensus_records')
    .update({
      consensus_answer: result.consensusAnswer,
      confidence_level: result.confidenceLevel,
      total_submissions: result.totalSubmissions,
      alignment_percentage: result.alignmentPercentage,
      human_count: result.humanCount,
      ai_count: result.aiCount,
      human_percentage: result.humanPercentage,
      answer_distribution: result.answerDistribution,
      authoritative_sources: authoritativeSources,
      last_verified_date: new Date().toISOString(),
      // threshold_met_at is intentionally NOT reset — preserves original timestamp
    })
    .eq('id', recordId);

  if (error) {
    logger.error('Consensus batch: failed to update consensus record', {
      questId,
      recordId,
      error: error.message,
    });
  }
}

// ============================================================
// INTERNAL: compute modal stance value from correct submissions
// ============================================================

/**
 * Compute the modal (most frequent) stance value from correct submissions.
 * Tie-break: lower value wins. Returns null if no valid numeric submissions.
 */
function computeModalStance(
  correctSubmissionIds: string[],
  submissions: SubmissionRow[]
): number | null {
  const frequencyMap = new Map<number, number>();

  for (const sub of submissions) {
    if (!correctSubmissionIds.includes(sub.id)) continue;
    if (sub.normalized_answer === null) continue;

    const numVal = Number(sub.normalized_answer);
    if (isNaN(numVal)) continue;

    frequencyMap.set(numVal, (frequencyMap.get(numVal) ?? 0) + 1);
  }

  if (frequencyMap.size === 0) return null;

  let maxFreq = 0;
  let modalValue: number | null = null;

  for (const [value, freq] of frequencyMap) {
    if (freq > maxFreq || (freq === maxFreq && (modalValue === null || value < modalValue))) {
      maxFreq = freq;
      modalValue = value;
    }
  }

  // Log warning on tie
  const tiedValues = [...frequencyMap.entries()]
    .filter(([, freq]) => freq === maxFreq)
    .map(([val]) => val);

  if (tiedValues.length > 1) {
    logger.warn('Consensus batch: stance modal tie — lower value wins', {
      tiedValues,
      selectedValue: modalValue,
    });
  }

  return modalValue;
}

// ============================================================
// INTERNAL: finalize after 48h contestation window
// ============================================================

async function finalizeConsensus(
  questId: string,
  record: ConsensusRecordRow,
  submissions: SubmissionRow[],
  quest: QuestRow
): Promise<void> {
  const questType = quest.type;
  const now = new Date().toISOString();

  // Mark consensus record as finalized
  const { error: recordError } = await supabaseService
    .schema('validation_quests')
    .from('consensus_records')
    .update({ finalized_at: now })
    .eq('id', record.id);

  if (recordError) {
    logger.error('Consensus batch: failed to set finalized_at', {
      questId,
      recordId: record.id,
      error: recordError.message,
    });
    throw new Error(`Failed to finalize consensus record for quest ${questId}`);
  }

  // Set quest status to consensus_reached
  const { error: questError } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .update({ status: 'consensus_reached', updated_at: now })
    .eq('id', questId);

  if (questError) {
    logger.error('Consensus batch: failed to update quest status to consensus_reached', {
      questId,
      error: questError.message,
    });
  }

  // Re-run algorithm to get current correct/incorrect split
  // (submissions may have changed since the contestation window opened)
  const consensusInput = buildConsensusInput(quest, submissions);
  const freshResult = computeConsensus(consensusInput);

  // Determine correct/incorrect submission IDs from fresh result (or fall back to stored record)
  let correctIds: string[] = [];
  let incorrectIds: string[] = [];

  if (freshResult.status === 'resolved') {
    correctIds = freshResult.correctSubmissionIds;
    incorrectIds = freshResult.incorrectSubmissionIds;
  } else {
    // Algorithm state changed — use all non-quarantined submissions as "correct" based on stored answer
    // This is a fallback; log a warning
    logger.warn('Consensus batch: algorithm did not resolve on finalization re-run', {
      questId,
      freshStatus: freshResult.status,
    });
    // Use the stored consensus_answer to determine which submissions match
    const consensusAnswer = record.consensus_answer;
    for (const sub of submissions) {
      if (sub.credibility_score >= CREDIBILITY_QUARANTINE_THRESHOLD && sub.normalized_answer !== null) {
        if (sub.normalized_answer === consensusAnswer) {
          correctIds.push(sub.id);
        } else {
          incorrectIds.push(sub.id);
        }
      }
    }
  }

  // ----------------------------------------------------------
  // Stance modal computation (STANCE-05)
  // If this is a stance quest (politician_id + topic_id present) and
  // confirmed_value is still NULL, compute the modal from submissions
  // and write it to the quest before the isStanceQuest check.
  // ----------------------------------------------------------
  if (
    quest.politician_id !== null &&
    quest.topic_id !== null &&
    quest.confirmed_value === null
  ) {
    const modalValue = computeModalStance(correctIds, submissions);

    if (modalValue !== null) {
      const { error: modalError } = await supabaseService
        .schema('validation_quests')
        .from('verification_quests')
        .update({ confirmed_value: modalValue, updated_at: now })
        .eq('id', questId);

      if (modalError) {
        logger.error('Consensus batch: failed to write modal stance to confirmed_value', {
          questId,
          modalValue,
          error: modalError.message,
        });
      } else {
        // Update local quest object so isStanceQuest check passes
        quest.confirmed_value = modalValue;
        logger.info('Consensus batch: stance modal value computed and written', {
          questId,
          modalValue,
        });
      }
    } else {
      logger.warn('Consensus batch: stance quest has no valid numeric submissions for modal', {
        questId,
      });
    }
  }

  const isStanceQuest =
    quest.politician_id !== null &&
    quest.topic_id !== null &&
    quest.confirmed_value !== null;

  // ----------------------------------------------------------
  // Auto-promote Red quest to Yellow at high confidence (PROMO-01)
  // Guard: gem_quest_type must be 'red' to prevent double-promotion.
  // Stance quests are NOT auto-promoted — they are Red quests whose value
  // lies in ongoing consensus, not in converting to Yellow for onboarding.
  // ----------------------------------------------------------
  if (!isStanceQuest && freshResult.status === 'resolved' && freshResult.confidenceLevel === 'high') {
    const { data: currentQuest } = await supabaseService
      .schema('validation_quests')
      .from('verification_quests')
      .select('gem_quest_type')
      .eq('id', questId)
      .maybeSingle();

    if ((currentQuest as any)?.gem_quest_type === 'red') {
      const { error: promoError } = await supabaseService
        .schema('validation_quests')
        .from('verification_quests')
        .update({
          gem_quest_type: 'yellow',
          correct_answer: record.consensus_answer,
          promoted_to_yellow_at: now,
          updated_at: now,
        })
        .eq('id', questId);

      if (promoError) {
        logger.error('Consensus batch: auto-promotion failed — non-fatal', {
          questId,
          error: promoError.message,
        });
      } else {
        logger.info('Consensus batch: Red quest auto-promoted to Yellow', {
          questId,
          consensusAnswer: record.consensus_answer,
          promoted_to_yellow_at: now,
        });
      }
    }
  }

  // ----------------------------------------------------------
  // Essentials pipeline write (PIPE-01, PIPE-02)
  // Non-fatal. Runs after auto-promotion. Feature-flagged.
  // ----------------------------------------------------------
  if (freshResult.status === 'resolved' && freshResult.confidenceLevel === 'high') {
    const { data: questDetails } = await supabaseService
      .schema('validation_quests')
      .from('verification_quests')
      .select('question_text, jurisdiction_name')
      .eq('id', questId)
      .maybeSingle();

    await writeToEssentials({
      questId,
      questType: quest.type,
      questionText: (questDetails as any)?.question_text ?? '',
      consensusAnswer: record.consensus_answer,
      confidenceLevel: freshResult.confidenceLevel,
      totalSubmissions: submissions.length,
      consensusRecordId: record.id,
      jurisdictionName: (questDetails as any)?.jurisdiction_name ?? null,
      politicianId: quest.politician_id ?? undefined,
    });
  }

  // Update submission outcome and included_in_consensus for all submissions
  const allEligibleIds = [...correctIds, ...incorrectIds];

  for (const sub of submissions) {
    const isEligible = sub.credibility_score >= CREDIBILITY_QUARANTINE_THRESHOLD;
    const isCorrect = correctIds.includes(sub.id);
    const isIncorrect = incorrectIds.includes(sub.id);
    const isIncluded = allEligibleIds.includes(sub.id);

    const outcomeValue: string = isCorrect ? 'correct' : isIncorrect ? 'incorrect' : 'pending';

    const { error: subUpdateError } = await supabaseService
      .schema('validation_quests')
      .from('verification_submissions')
      .update({
        outcome: outcomeValue,
        included_in_consensus: isEligible && isIncluded,
        updated_at: now,
      })
      .eq('id', sub.id);

    if (subUpdateError) {
      logger.warn('Consensus batch: failed to update submission outcome', {
        questId,
        submissionId: sub.id,
        error: subUpdateError.message,
      });
    }
  }

  // ----------------------------------------------------------
  // Award Red gems + VR adjustments at finalization (REWARD-01, REWARD-02)
  //
  // Two paths depending on whether the quest is a politician stance quest:
  //
  //   Stance quest (politician_id + topic_id + confirmed_value all present):
  //     → confirmVqStance() in-process (lib/vqService.ts)
  //       Atomically: awards Red gems, adjusts VR for all, writes politician stance to compass.
  //       awardRedGem / credit_gems MUST NOT run alongside this — double-award risk.
  //
  //   Non-stance quest (any of the three fields absent):
  //     → adjustVerificationRating() in-process, per human submitter (lib/vqService.ts)
  //       VR adjustment only. Red gems are not awarded for non-stance quests at consensus.
  //
  // Early bonus (5 Red gems for early submitters) runs as a supplemental award
  // via credit_gems in both cases — it is a VQ-internal reward separate from stance confirmation.
  // ----------------------------------------------------------
  const { data: questDataForGems } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .select('gem_reward')
    .eq('id', questId)
    .maybeSingle();

  const finalGemReward = (questDataForGems as { gem_reward: number } | null)?.gem_reward ?? 0;
  const thresholdMetAt = record.threshold_met_at ?? now;
  const confidenceLevel = freshResult.status === 'resolved' ? freshResult.confidenceLevel : 'low';

  // Separate human submitters by outcome for confirm-stance / adjust-vr
  const humanCorrectUserIds = submissions
    .filter((s) => s.submitter_type !== 'ai_agent' && correctIds.includes(s.id))
    .map((s) => s.user_id);
  const humanIncorrectUserIds = submissions
    .filter((s) => s.submitter_type !== 'ai_agent' && incorrectIds.includes(s.id))
    .map((s) => s.user_id);

  if (isStanceQuest) {
    // ----------------------------------------------------------
    // Stance quest: confirm-stance handles Red gems + VR atomically
    // ----------------------------------------------------------
    // TODO: confirmVqStance (lib/vqService.ts) awards gems as a flat gems_amount, not the
    // 1+2 split (1 gem for correct_answer + 2 gems for valid_source) used elsewhere. Moving
    // it to the split is a follow-up in that in-process service; the stance path cannot
    // control the split until then.
    try {
      const stanceData = await confirmVqStance({
        // isStanceQuest (above) guarantees these three are non-null; TS just can't
        // narrow through the stored boolean.
        politicianId: quest.politician_id!,
        topicId: quest.topic_id!,
        confirmedValue: quest.confirmed_value!,
        correctUserIds: humanCorrectUserIds,
        incorrectUserIds: humanIncorrectUserIds,
        idempotencyKey: `vq-resolution-${record.id}`,
        gemsAmount: finalGemReward,
      });
      logger.info('Consensus batch: confirm-stance succeeded', {
        questId,
        politicianId: quest.politician_id,
        correctCount: stanceData.correct_count,
        incorrectCount: stanceData.incorrect_count,
        replayed: stanceData.replayed ?? false,
      });
    } catch (err) {
      logger.error('Consensus batch: confirm-stance failed — non-fatal, VR/gems not applied', {
        questId,
        error: String(err),
      });
    }
  } else {
    // ----------------------------------------------------------
    // Non-stance quest: adjust-vr per submitter + award Red gems to correct submitters.
    // Red gems: 1 (correct answer) + 2 (valid source) = 3 total via two credit_gems calls.
    // ----------------------------------------------------------
    for (const sub of submissions) {
      if (sub.submitter_type === 'ai_agent') continue;
      const isCorrect = correctIds.includes(sub.id);
      const isIncorrect = incorrectIds.includes(sub.id);
      if (!isCorrect && !isIncorrect) continue;

      const delta = isCorrect ? 3 : -10;
      const reason = isCorrect ? 'red_quest_correct' : 'red_quest_incorrect';

      try {
        await adjustVerificationRating({
          userId: sub.user_id,
          delta,
          idempotencyKey: `vq-red-${record.id}-${sub.user_id}`,
          reason,
        });
      } catch (err) {
        logger.warn('Consensus batch: adjust-vr failed — non-fatal', {
          userId: sub.user_id,
          questId,
          error: String(err),
        });
      }

      // Award Red gems to correct submitters (non-stance path)
      if (isCorrect) {
        await awardRedGem({
          userId: sub.user_id,
          questId,
          gemAmount: 3, // 1 (correct answer) + 2 (valid source); internal to awardRedGem
          confidenceLevel,
          consensusRecordId: record.id,
        });
      }
    }
  }

  // ----------------------------------------------------------
  // Early bonus + XP: correct human submitters only
  // ----------------------------------------------------------
  let earlyBonusCount = 0;
  for (const sub of submissions) {
    if (!correctIds.includes(sub.id)) continue;
    if (sub.submitter_type === 'ai_agent') continue;

    if (isEarlySubmission(sub.created_at, thresholdMetAt)) {
      await awardEarlyBonus({
        userId: sub.user_id,
        questId,
        confidenceLevel,
        consensusRecordId: record.id,
      });
      earlyBonusCount++;
    }

    // XP Award (SUBMIT-07) — POST /api/xp/award via Accounts API
    if (process.env.ENABLE_XP_AWARDS === 'true') {
      try {
        const xpResult = await awardXp({
          userId: sub.user_id,
          source: 'validation_quest_completion',
          amount: 75,
          idempotencyKey: `vq-consensus-${record.id}-${sub.user_id}`,
          metadata: { questId, consensusRecordId: record.id },
        });
        if (xpResult.is_duplicate) {
          logger.info('XP award: already awarded (idempotency key matched)', {
            userId: sub.user_id,
            consensusRecordId: record.id,
          });
        } else if (xpResult.level >= 2) {
          // Preserve the /api/xp/award endpoint's post-award referral side-effects.
          void unlockReferralCode(sub.user_id).catch((e) =>
            logger.warn('referral unlock after consensus XP failed — non-fatal', { userId: sub.user_id, error: String(e) })
          );
          void maybeRefreshReferralForInvitee(sub.user_id).catch((e) =>
            logger.warn('referral refresh after consensus XP failed — non-fatal', { userId: sub.user_id, error: String(e) })
          );
        }
      } catch (err) {
        logger.warn('XP award failed — non-fatal', {
          userId: sub.user_id,
          questId,
          error: String(err),
        });
      }
    }
  }

  logger.info('Consensus batch: finalization rewards complete', {
    questId,
    isStanceQuest,
    correctCount: humanCorrectUserIds.length,
    incorrectCount: humanIncorrectUserIds.length,
    earlyBonusCount,
    finalGemReward,
  });

  // Process veracity outcomes for human submitters only
  // AI agents do not have veracity profiles
  const humanSubmissions = submissions.filter((s) => s.submitter_type !== 'ai_agent');
  const processedUserIds = new Set<string>();

  for (const sub of humanSubmissions) {
    // Skip veracity processing for suspended submissions (active contest in progress)
    if (sub.veracity_suspended) {
      logger.info('Skipping veracity processing for suspended submission', {
        questId,
        userId: sub.user_id,
      });
      continue;
    }

    const isCorrect = correctIds.includes(sub.id);
    const isIncorrect = incorrectIds.includes(sub.id);

    if (!isCorrect && !isIncorrect) continue; // quarantined or no normalized_answer

    const outcome: 'correct' | 'incorrect' = isCorrect ? 'correct' : 'incorrect';

    try {
      await processConsensusOutcome({
        userId: sub.user_id,
        questId,
        submissionId: sub.id,
        outcome,
        correctAnswer: record.consensus_answer,
        correctSources: record.authoritative_sources,
        questType,
      });

      if (!processedUserIds.has(sub.user_id)) {
        processedUserIds.add(sub.user_id);
        // Pass the pre-update accuracy_rate snapshot (already captured from profileMap
        // before any DB writes in this finalization cycle) so updateAccuracyMetrics can
        // detect tier boundary crossings for feed cache invalidation.
        await updateAccuracyMetrics(sub.user_id, sub.accuracy_rate ?? null);
      }
    } catch (err) {
      logger.error('Consensus batch: failed to process veracity outcome', {
        questId,
        userId: sub.user_id,
        submissionId: sub.id,
        outcome,
        error: String(err),
      });
    }
  }

  logger.info('Consensus batch: finalized quest', {
    questId,
    correctCount: correctIds.length,
    incorrectCount: incorrectIds.length,
    humanProcessed: processedUserIds.size,
  });

  // ----------------------------------------------------------
  // Write notifications for human submitters (NOTIF-01, NOTIF-03, NOTIF-04)
  // Runs AFTER veracity processing so feedback.research_tips is populated.
  // Non-fatal: notification failure must not abort the batch job.
  // ----------------------------------------------------------
  for (const sub of humanSubmissions) {
    if (sub.veracity_suspended) continue;      // skip suspended
    if (sub.submitter_type === 'ai_agent') continue; // redundant (humanSubmissions filtered) but defensive

    const isCorrect = correctIds.includes(sub.id);
    const isIncorrect = incorrectIds.includes(sub.id);
    if (!isCorrect && !isIncorrect) continue;  // quarantined

    const outcome: 'correct' | 'incorrect' = isCorrect ? 'correct' : 'incorrect';

    try {
      await writeNotification({
        userId: sub.user_id,
        questId,
        outcome,
        correctAnswer: record.consensus_answer,
        authoritativeSources: record.authoritative_sources,
        isEarly: isEarlySubmission(sub.created_at, thresholdMetAt),
        questData: { gemReward: finalGemReward },
      });
    } catch (err) {
      logger.error('Consensus batch: failed to write notification', {
        questId,
        userId: sub.user_id,
        error: String(err),
      });
    }
  }
}

