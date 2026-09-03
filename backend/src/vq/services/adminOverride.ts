/**
 * adminOverride.ts
 * Admin override cascade service for Validation Quests.
 *
 * Exported:
 *   executeAdminOverride — ADMIN-03: Override a conflicting consensus with admin-chosen answer.
 *                          Mirrors finalizeConsensus from consensusBatchJob but admin-driven.
 *   resolveContestation  — ADMIN-05: Approve (re-open quest) or reject (restore consensus)
 *                          a user-filed contestation.
 *
 * Both operations write to admin_override_log BEFORE any mutations (write-ahead audit log)
 * and to veracity_event_logs after the operation completes.
 *
 * Error handling: per-user operations are wrapped in try/catch (non-fatal pattern from batch
 * job). A single user failure does not abort processing of other users.
 */

import { supabaseService } from '../lib/supabase.js';
import {
  processConsensusOutcome,
  updateAccuracyMetrics,
} from './veracityTracking.js';
import { writeNotification } from './notificationService.js';
import { invalidateAllFeedCaches } from './feedScoring.js';
import { getOrCreateProfile } from './credibility.js';
import { logger } from '../lib/logger.js';

// ============================================================
// CONSTANTS
// ============================================================

const CREDIBILITY_QUARANTINE_THRESHOLD = 40;

// ============================================================
// TYPES
// ============================================================

interface SubmissionRow {
  id: string;
  user_id: string;
  submitter_type: 'human_connected' | 'human_empowered' | 'ai_agent';
  normalized_answer: string | null;
  credibility_score: number;
  veracity_suspended: boolean;
  created_at: string;
}

// ============================================================
// executeAdminOverride — ADMIN-03
// ============================================================

/**
 * Executes a full admin override cascade for a conflicting quest.
 *
 * Sequence:
 *   1. Write-ahead audit log to admin_override_log
 *   2. Fetch all submissions for the quest
 *   3. Classify submissions as correct/incorrect against canonicalAnswer
 *   4. Update submission outcomes in DB
 *   5. Upsert consensus_records with finalized_at + bridging_waived = true
 *   6. Update quest status to consensus_reached
 *   7. Process veracity for each eligible human submitter
 *   8. Write notifications for each eligible human submitter
 *   9. Invalidate all feed caches
 */
export async function executeAdminOverride(params: {
  questId: string;
  adminUserId: string;
  canonicalAnswer: string;
  reasoning: string;
}): Promise<void> {
  const { questId, adminUserId, canonicalAnswer, reasoning } = params;
  const now = new Date().toISOString();

  // ----------------------------------------------------------
  // Step 1: Write-ahead audit log (BEFORE any mutations)
  // ----------------------------------------------------------
  const { error: auditError } = await supabaseService
    .schema('validation_quests')
    .from('admin_override_log')
    .insert({
      admin_user_id: adminUserId,
      action_type: 'quest_override',
      target_type: 'quest',
      target_id: questId,
      reasoning,
      metadata: {},
    });

  if (auditError) {
    logger.error('executeAdminOverride: failed to write audit log', {
      questId,
      error: auditError.message,
    });
    // Non-fatal for audit log; continue with override
  }

  // ----------------------------------------------------------
  // Step 2: Fetch all submissions for the quest
  // ----------------------------------------------------------
  const { data: submissionsData, error: subsError } = await supabaseService
    .schema('validation_quests')
    .from('verification_submissions')
    .select('id, user_id, submitter_type, normalized_answer, credibility_score, veracity_suspended, created_at')
    .eq('quest_id', questId);

  if (subsError) {
    logger.error('executeAdminOverride: failed to fetch submissions', {
      questId,
      error: subsError.message,
    });
    throw new Error(`executeAdminOverride: failed to fetch submissions for quest ${questId}`);
  }

  const submissions = (submissionsData ?? []) as SubmissionRow[];

  // ----------------------------------------------------------
  // Step 3: Classify submissions
  // Eligible = credibility_score >= quarantine threshold AND normalized_answer is not null
  // Match against canonicalAnswer via exact normalized string comparison
  // (same fallback pattern as consensusBatchJob.ts ~line 591)
  // ----------------------------------------------------------
  const correctIds: string[] = [];
  const incorrectIds: string[] = [];

  for (const sub of submissions) {
    const isEligible =
      sub.credibility_score >= CREDIBILITY_QUARANTINE_THRESHOLD &&
      sub.normalized_answer !== null;

    if (!isEligible) continue;

    if (sub.normalized_answer === canonicalAnswer) {
      correctIds.push(sub.id);
    } else {
      incorrectIds.push(sub.id);
    }
  }

  const allEligibleIds = [...correctIds, ...incorrectIds];

  // ----------------------------------------------------------
  // Step 4: Update submission outcomes
  // ----------------------------------------------------------
  for (const sub of submissions) {
    const isEligible = sub.credibility_score >= CREDIBILITY_QUARANTINE_THRESHOLD;
    const isCorrect = correctIds.includes(sub.id);
    const isIncorrect = incorrectIds.includes(sub.id);
    const isIncluded = allEligibleIds.includes(sub.id);

    const outcomeValue = isCorrect ? 'correct' : isIncorrect ? 'incorrect' : 'pending';

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
      logger.warn('executeAdminOverride: failed to update submission outcome', {
        questId,
        submissionId: sub.id,
        error: subUpdateError.message,
      });
    }
  }

  // ----------------------------------------------------------
  // Step 5: Upsert consensus_records
  // finalized_at and bridging_waived=true prevent batch job from re-processing.
  // ----------------------------------------------------------
  const totalSubmissions = submissions.length;
  const humanCount = submissions.filter(
    (s) => s.submitter_type === 'human_connected' || s.submitter_type === 'human_empowered',
  ).length;
  const aiCount = submissions.filter((s) => s.submitter_type === 'ai_agent').length;
  const humanPercentage = totalSubmissions > 0 ? (humanCount / totalSubmissions) * 100 : 0;

  const alignmentPercentage =
    allEligibleIds.length > 0 ? (correctIds.length / allEligibleIds.length) * 100 : 100;

  // Build answer_distribution from eligible submissions
  const answerDistribution: Record<string, number> = {};
  for (const sub of submissions) {
    const answer = sub.normalized_answer ?? '__no_answer__';
    answerDistribution[answer] = (answerDistribution[answer] ?? 0) + 1;
  }

  const { error: upsertError } = await supabaseService
    .schema('validation_quests')
    .from('consensus_records')
    .upsert(
      {
        quest_id: questId,
        consensus_answer: canonicalAnswer,
        confidence_level: 'high', // admin override is authoritative
        finalized_at: now,        // CRITICAL: prevents batch job from re-processing
        bridging_waived: true,    // CRITICAL: prevents bridging check from reverting
        threshold_met_at: now,
        total_submissions: totalSubmissions,
        alignment_percentage: alignmentPercentage,
        human_count: humanCount,
        ai_count: aiCount,
        human_percentage: humanPercentage,
        answer_distribution: answerDistribution,
        authoritative_sources: [],
        consensus_date: now,
        last_verified_date: now,
      },
      { onConflict: 'quest_id' },
    );

  if (upsertError) {
    logger.error('executeAdminOverride: failed to upsert consensus_records', {
      questId,
      error: upsertError.message,
    });
    throw new Error(`executeAdminOverride: failed to upsert consensus record for quest ${questId}`);
  }

  // ----------------------------------------------------------
  // Step 6: Update quest status to consensus_reached
  // ----------------------------------------------------------
  const { error: questError } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .update({ status: 'consensus_reached', updated_at: now })
    .eq('id', questId);

  if (questError) {
    logger.error('executeAdminOverride: failed to update quest status', {
      questId,
      error: questError.message,
    });
    // Non-fatal: continue with veracity + notifications
  }

  // ----------------------------------------------------------
  // Step 7: Process veracity for eligible human submitters
  // Per-user try/catch (non-fatal pattern from batch job).
  // getOrCreateProfile called first (defensive — prevents processConsensusOutcome failing).
  // ----------------------------------------------------------
  const humanSubmissions = submissions.filter((s) => s.submitter_type !== 'ai_agent');
  const processedUserIds = new Set<string>();

  for (const sub of humanSubmissions) {
    if (sub.veracity_suspended) continue; // skip suspended

    const isCorrect = correctIds.includes(sub.id);
    const isIncorrect = incorrectIds.includes(sub.id);
    if (!isCorrect && !isIncorrect) continue; // quarantined or no normalized_answer

    const outcome: 'correct' | 'incorrect' = isCorrect ? 'correct' : 'incorrect';

    try {
      // Defensive: ensure profile exists before processConsensusOutcome
      await getOrCreateProfile(sub.user_id);

      await processConsensusOutcome({
        userId: sub.user_id,
        questId,
        submissionId: sub.id,
        outcome,
        correctAnswer: canonicalAnswer,
        correctSources: [], // admin override has reasoning, not authoritative sources
        questType: 'official', // fallback; quest type not fetched to keep override lightweight
      });

      if (!processedUserIds.has(sub.user_id)) {
        processedUserIds.add(sub.user_id);
        await updateAccuracyMetrics(sub.user_id);
      }
    } catch (err) {
      logger.error('executeAdminOverride: failed to process veracity outcome', {
        questId,
        userId: sub.user_id,
        submissionId: sub.id,
        outcome,
        error: String(err),
      });
    }
  }

  // ----------------------------------------------------------
  // Step 8: Write notifications for eligible human submitters
  // Non-fatal: notification failure must not abort override.
  // ----------------------------------------------------------
  for (const sub of humanSubmissions) {
    if (sub.veracity_suspended) continue;

    const isCorrect = correctIds.includes(sub.id);
    const isIncorrect = incorrectIds.includes(sub.id);
    if (!isCorrect && !isIncorrect) continue; // quarantined

    const outcome: 'correct' | 'incorrect' = isCorrect ? 'correct' : 'incorrect';

    try {
      await writeNotification({
        userId: sub.user_id,
        questId,
        outcome,
        correctAnswer: canonicalAnswer,
        authoritativeSources: [],
        isEarly: false,
        questData: { gemReward: 0 }, // admin override does not award gems
      });
    } catch (err) {
      logger.error('executeAdminOverride: failed to write notification', {
        questId,
        userId: sub.user_id,
        error: String(err),
      });
    }
  }

  // ----------------------------------------------------------
  // Step 9: Invalidate all feed caches
  // ----------------------------------------------------------
  try {
    await invalidateAllFeedCaches();
  } catch (err) {
    logger.error('executeAdminOverride: failed to invalidate feed caches', {
      questId,
      error: String(err),
    });
  }

  logger.info('executeAdminOverride: override complete', {
    questId,
    canonicalAnswer,
    correctCount: correctIds.length,
    incorrectCount: incorrectIds.length,
    humanProcessed: processedUserIds.size,
  });
}

// ============================================================
// resolveContestation — ADMIN-05
// ============================================================

/**
 * Resolves a user-filed contestation.
 *
 * Approve path: quest re-opens for a new submission round.
 * Reject path: original consensus is restored; veracity_suspended reset to false.
 *
 * Both paths:
 *   - Write-ahead audit log to admin_override_log
 *   - Write to veracity_event_logs
 */
export async function resolveContestation(params: {
  contestId: string;
  adminUserId: string;
  decision: 'approve' | 'reject';
  reasoning: string;
}): Promise<void> {
  const { contestId, adminUserId, decision, reasoning } = params;
  const now = new Date().toISOString();

  const actionType = decision === 'approve' ? 'contest_approved' : 'contest_rejected';

  // ----------------------------------------------------------
  // Step 1: Write-ahead audit log (BEFORE any mutations)
  // ----------------------------------------------------------
  const { error: auditError } = await supabaseService
    .schema('validation_quests')
    .from('admin_override_log')
    .insert({
      admin_user_id: adminUserId,
      action_type: actionType,
      target_type: 'contest',
      target_id: contestId,
      reasoning,
      metadata: {},
    });

  if (auditError) {
    logger.error('resolveContestation: failed to write audit log', {
      contestId,
      decision,
      error: auditError.message,
    });
    // Non-fatal for audit log; continue
  }

  // ----------------------------------------------------------
  // Step 2: Fetch the contest record (need quest_id and filed_by for downstream ops)
  // ----------------------------------------------------------
  const { data: contestData, error: contestFetchError } = await supabaseService
    .schema('validation_quests')
    .from('quest_contests')
    .select('id, quest_id, filed_by, status')
    .eq('id', contestId)
    .maybeSingle();

  if (contestFetchError || !contestData) {
    logger.error('resolveContestation: failed to fetch contest', {
      contestId,
      error: contestFetchError?.message,
    });
    throw new Error(`resolveContestation: contest ${contestId} not found`);
  }

  const contest = contestData as { id: string; quest_id: string; filed_by: string; status: string };

  if (decision === 'approve') {
    // ----------------------------------------------------------
    // Approve path: quest re-opens for new submission round
    // ----------------------------------------------------------

    // Update contest status to resolved_overturned
    const { error: contestUpdateError } = await supabaseService
      .schema('validation_quests')
      .from('quest_contests')
      .update({
        status: 'resolved_overturned',
        admin_resolution: reasoning,
        resolved_by: adminUserId,
        resolved_at: now,
        updated_at: now,
      })
      .eq('id', contestId);

    if (contestUpdateError) {
      logger.error('resolveContestation: failed to update contest status (approve)', {
        contestId,
        error: contestUpdateError.message,
      });
      throw new Error(`resolveContestation: failed to update contest ${contestId}`);
    }

    // Re-open quest to active status
    const { error: questUpdateError } = await supabaseService
      .schema('validation_quests')
      .from('verification_quests')
      .update({ status: 'active', updated_at: now })
      .eq('id', contest.quest_id);

    if (questUpdateError) {
      logger.error('resolveContestation: failed to re-open quest', {
        contestId,
        questId: contest.quest_id,
        error: questUpdateError.message,
      });
      // Non-fatal: audit log and veracity_event_logs still proceed
    }

    // Invalidate feed caches (quest re-appeared as active)
    try {
      await invalidateAllFeedCaches();
    } catch (err) {
      logger.error('resolveContestation: failed to invalidate feed caches', {
        contestId,
        error: String(err),
      });
    }
  } else {
    // ----------------------------------------------------------
    // Reject path: original consensus restored
    // ----------------------------------------------------------

    // Update contest status to resolved_upheld
    const { error: contestUpdateError } = await supabaseService
      .schema('validation_quests')
      .from('quest_contests')
      .update({
        status: 'resolved_upheld',
        admin_resolution: reasoning,
        resolved_by: adminUserId,
        resolved_at: now,
        updated_at: now,
      })
      .eq('id', contestId);

    if (contestUpdateError) {
      logger.error('resolveContestation: failed to update contest status (reject)', {
        contestId,
        error: contestUpdateError.message,
      });
      throw new Error(`resolveContestation: failed to update contest ${contestId}`);
    }

    // CRITICAL: Reset veracity_suspended=false on the contesting user's submission.
    // Without this, the batch job forever skips veracity processing for that submission.
    const { error: subUpdateError } = await supabaseService
      .schema('validation_quests')
      .from('verification_submissions')
      .update({ veracity_suspended: false, updated_at: now })
      .eq('user_id', contest.filed_by)
      .eq('quest_id', contest.quest_id);

    if (subUpdateError) {
      logger.error('resolveContestation: failed to reset veracity_suspended', {
        contestId,
        questId: contest.quest_id,
        userId: contest.filed_by,
        error: subUpdateError.message,
      });
      // Non-fatal: log and continue; quest status already resolved
    }

    // Restore quest status to consensus_reached
    // (was moved to under_review when contest was filed; reject = uphold original consensus)
    const { error: questRestoreError } = await supabaseService
      .schema('validation_quests')
      .from('verification_quests')
      .update({ status: 'consensus_reached', updated_at: now })
      .eq('id', contest.quest_id);

    if (questRestoreError) {
      logger.error('resolveContestation: failed to restore quest status after reject', {
        contestId,
        questId: contest.quest_id,
        error: questRestoreError.message,
      });
      // Non-fatal: veracity_event_logs still proceeds
    }
    // Do NOT call invalidateAllFeedCaches — reject = uphold consensus_reached;
    // quest was already in feeds; no visibility change.
  }

  // ----------------------------------------------------------
  // Step 3: Write veracity_event_logs entry for both paths
  // ----------------------------------------------------------
  const { error: eventLogError } = await supabaseService
    .schema('validation_quests')
    .from('veracity_event_logs')
    .insert({
      user_id: contest.filed_by,
      event_type: actionType, // 'contest_approved' or 'contest_rejected'
      quest_id: contest.quest_id,
      previous_weight: null,
      new_weight: null,
      delta: null,
      user_action: null,
    });

  if (eventLogError) {
    logger.warn('resolveContestation: failed to write veracity_event_logs', {
      contestId,
      decision,
      error: eventLogError.message,
    });
  }

  logger.info('resolveContestation: complete', {
    contestId,
    questId: contest.quest_id,
    decision,
    adminUserId,
  });
}
