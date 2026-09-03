/**
 * rewards.ts
 * Two-phase gem delivery service for the Validation Quests system.
 *
 * Phase 1 (threshold_met_at): Yellow gem awarded when consensus threshold is first reached.
 * Phase 2 (finalized_at):     Red gem awarded after 48h contestation window expires.
 *                              Early bonus (5 Red gems) for submissions predating threshold.
 *
 * All gem awards are:
 *   - Routed through the platform credit_gems RPC (never direct gem inserts)
 *   - Idempotent via UNIQUE constraint on gem_reward_events (user_id, quest_id, gem_type, reason)
 *   - Non-fatal: failures are logged but do NOT throw (reward failures must not abort batch job)
 *
 * AI agents are excluded from gem awards (callers must check submitter_type before calling).
 *
 * XP award: wired in consensusBatchJob.ts behind ENABLE_XP_AWARDS env var (Phase 11 coordination)
 */

import { supabaseService } from '../lib/supabase.js';
import { logger } from '../lib/logger.js';
import type { GemType, RewardReason, ConfidenceLevel } from '../types/custom.js';

// ============================================================
// TYPES
// ============================================================

export interface AwardYellowGemParams {
  userId: string;
  questId: string;
  gemAmount: number;
  confidenceLevel: ConfidenceLevel;
  submissionCreatedAt: string;
  thresholdMetAt: string;
  consensusRecordId: string; // UUID of consensus_records row for credit_gems p_source_ref
}

export interface AwardRedGemParams {
  userId: string;
  questId: string;
  gemAmount: number;
  confidenceLevel: ConfidenceLevel;
  consensusRecordId: string; // UUID of consensus_records row for credit_gems p_source_ref
}

export interface AwardEarlyBonusParams {
  userId: string;
  questId: string;
  confidenceLevel: ConfidenceLevel;
  consensusRecordId: string; // UUID of consensus_records row for credit_gems p_source_ref
}

const EARLY_BONUS_AMOUNT = 5;

// ============================================================
// HELPERS
// ============================================================

/**
 * Returns true if the submission was created before the threshold was met.
 * Used to determine eligibility for the early bonus.
 */
export function isEarlySubmission(submissionCreatedAt: string, thresholdMetAt: string): boolean {
  return new Date(submissionCreatedAt).getTime() < new Date(thresholdMetAt).getTime();
}

// ============================================================
// INTERNAL: write idempotent gem_reward_events record
// ============================================================

async function recordGemRewardEvent(params: {
  userId: string;
  questId: string;
  gemType: GemType;
  amount: number;
  reason: RewardReason;
  confidenceLevel: ConfidenceLevel;
}): Promise<void> {
  const { error } = await supabaseService
    .schema('validation_quests')
    .from('gem_reward_events')
    .insert({
      user_id: params.userId,
      quest_id: params.questId,
      gem_type: params.gemType,
      amount: params.amount,
      reason: params.reason,
      confidence_level_at_reward: params.confidenceLevel,
      timestamp: new Date().toISOString(),
    });

  if (error) {
    // PostgreSQL error code 23505 = unique_violation — idempotency guard working as intended
    if (error.code === '23505') {
      logger.info('Reward already recorded — idempotency guard', {
        userId: params.userId,
        questId: params.questId,
        gemType: params.gemType,
        reason: params.reason,
      });
    } else {
      logger.error('Failed to record gem_reward_event', {
        userId: params.userId,
        questId: params.questId,
        gemType: params.gemType,
        reason: params.reason,
        error: error.message,
      });
    }
  }
}

// ============================================================
// EXPORTED: awardYellowGem — fires at threshold_met_at
// ============================================================

/**
 * Awards Yellow gems to a correct submitter when consensus threshold is first reached.
 * Called inside insertConsensusRecord (at threshold_met_at).
 *
 * Two separate credit_gems calls: 1 gem (correct answer) + 2 gems (valid source) = 3 total.
 * Distinct transaction_types provide per-reason visibility in the gem ledger.
 *
 * Note: gemAmount param is no longer used (hardcoded to 1+2=3). Retained for API compatibility.
 *
 * Non-fatal: logs errors but does NOT throw.
 */
export async function awardYellowGem(params: AwardYellowGemParams): Promise<void> {
  const { userId, questId, confidenceLevel, consensusRecordId } = params;

  // First call: 1 gem for knowing the correct answer
  const { error: answerRpcError } = await supabaseService
    .schema('connect')
    .rpc('credit_gems', {
      p_user_id: userId,
      p_gem_type: 'yellow' as GemType,
      p_amount: 1,
      p_transaction_type: 'yellow_quest_correct_answer',
      p_source_ref: consensusRecordId,
    });

  if (answerRpcError) {
    logger.error('awardYellowGem: credit_gems RPC failed (answer)', {
      userId,
      questId,
      error: answerRpcError.message,
    });
    // Non-fatal — do not throw; gem failures must not abort the batch job
    return;
  }

  await recordGemRewardEvent({
    userId,
    questId,
    gemType: 'yellow',
    amount: 1,
    reason: 'correct_answer',
    confidenceLevel,
  });

  // Second call: 2 gems for citing a valid source
  const { error: sourceRpcError } = await supabaseService
    .schema('connect')
    .rpc('credit_gems', {
      p_user_id: userId,
      p_gem_type: 'yellow' as GemType,
      p_amount: 2,
      p_transaction_type: 'yellow_quest_valid_source',
      p_source_ref: consensusRecordId,
    });

  if (sourceRpcError) {
    logger.error('awardYellowGem: credit_gems RPC failed (source)', {
      userId,
      questId,
      error: sourceRpcError.message,
    });
    // Non-fatal — do not throw; continue after partial award
    return;
  }

  await recordGemRewardEvent({
    userId,
    questId,
    gemType: 'yellow',
    amount: 2,
    reason: 'valid_source',
    confidenceLevel,
  });

  logger.info('awardYellowGem: Yellow gems awarded (1+2=3)', {
    userId,
    questId,
    confidenceLevel,
  });
}

// ============================================================
// EXPORTED: awardRedGem — fires at finalized_at
// ============================================================

/**
 * Awards Red gems to a correct submitter when consensus is finalized (after 48h window).
 * Called inside finalizeConsensus (at finalized_at) for non-stance quests.
 *
 * Two separate credit_gems calls: 1 gem (correct answer) + 2 gems (valid source) = 3 total.
 * Distinct transaction_types provide per-reason visibility in the gem ledger.
 *
 * Note: gemAmount param is no longer used (hardcoded to 1+2=3). Retained for API compatibility.
 *
 * Non-fatal: logs errors but does NOT throw.
 */
export async function awardRedGem(params: AwardRedGemParams): Promise<void> {
  const { userId, questId, confidenceLevel, consensusRecordId } = params;

  // First call: 1 gem for knowing the correct answer
  const { error: answerRpcError } = await supabaseService
    .schema('connect')
    .rpc('credit_gems', {
      p_user_id: userId,
      p_gem_type: 'red' as GemType,
      p_amount: 1,
      p_transaction_type: 'red_quest_correct_answer',
      p_source_ref: consensusRecordId,
    });

  if (answerRpcError) {
    logger.error('awardRedGem: credit_gems RPC failed (answer)', {
      userId,
      questId,
      error: answerRpcError.message,
    });
    // Non-fatal — do not throw
    return;
  }

  await recordGemRewardEvent({
    userId,
    questId,
    gemType: 'red',
    amount: 1,
    reason: 'correct_answer',
    confidenceLevel,
  });

  // Second call: 2 gems for citing a valid source
  const { error: sourceRpcError } = await supabaseService
    .schema('connect')
    .rpc('credit_gems', {
      p_user_id: userId,
      p_gem_type: 'red' as GemType,
      p_amount: 2,
      p_transaction_type: 'red_quest_valid_source',
      p_source_ref: consensusRecordId,
    });

  if (sourceRpcError) {
    logger.error('awardRedGem: credit_gems RPC failed (source)', {
      userId,
      questId,
      error: sourceRpcError.message,
    });
    // Non-fatal — do not throw; continue after partial award
    return;
  }

  await recordGemRewardEvent({
    userId,
    questId,
    gemType: 'red',
    amount: 2,
    reason: 'valid_source',
    confidenceLevel,
  });

  logger.info('awardRedGem: Red gems awarded (1+2=3)', {
    userId,
    questId,
    confidenceLevel,
  });
}

// ============================================================
// EXPORTED: awardEarlyBonus — fires at finalized_at for early submitters
// ============================================================

/**
 * Awards 5 bonus Red gems to submitters who submitted before the consensus threshold was met.
 * Called inside finalizeConsensus, gated by isEarlySubmission check.
 *
 * The fixed amount (5 Red gems) is per REWARD-02 design.
 * Non-fatal: logs errors but does NOT throw.
 */
export async function awardEarlyBonus(params: AwardEarlyBonusParams): Promise<void> {
  const { userId, questId, confidenceLevel, consensusRecordId } = params;

  const { error: rpcError } = await supabaseService
    .schema('connect')
    .rpc('credit_gems', {
      p_user_id: userId,
      p_gem_type: 'red' as GemType,
      p_amount: EARLY_BONUS_AMOUNT,
      p_transaction_type: 'quest_reward',
      p_source_ref: consensusRecordId,
    });

  if (rpcError) {
    logger.error('awardEarlyBonus: credit_gems RPC failed', {
      userId,
      questId,
      error: rpcError.message,
    });
    // Non-fatal — do not throw
    return;
  }

  await recordGemRewardEvent({
    userId,
    questId,
    gemType: 'red',
    amount: EARLY_BONUS_AMOUNT,
    reason: 'early_bonus',
    confidenceLevel,
  });

  logger.info('awardEarlyBonus: Early bonus awarded', {
    userId,
    questId,
    bonusAmount: EARLY_BONUS_AMOUNT,
    confidenceLevel,
  });
}
