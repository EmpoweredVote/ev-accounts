/**
 * submissions.ts
 * POST /api/submissions    — Submit or update an answer to a verification quest (human).
 * POST /api/submissions/ai — Submit or update an answer to a verification quest (AI agent).
 *
 * Human auth chain: requireAuth → requireNotSuspended → requireConnected
 * AI auth:          requireAiApiKey (x-api-key header → SHA-256 → ai_agent_credentials)
 *
 * Human flow:
 *   1. Validate request body (Zod)
 *   2. Check submission eligibility (credibility lockout check)
 *   3. Verify quest exists and is active
 *   4. Validate all source URLs in parallel
 *   5. Normalize answer text (normalizeAnswer)
 *   6. Upsert submission (archive old answer if answer text changed)
 *   7. Apply credibility gain (+1 for accepted source)
 *   8. Return rich SubmissionSuccessResponse
 *
 * AI flow (same except):
 *   - requireAiApiKey instead of JWT chain
 *   - Minimum 2 sources (createAiSubmissionSchema)
 *   - No credibility tracking (AI agents do not have profiles)
 *   - submitter_type: 'ai_agent'
 *
 * Blind submission enforcement: pre-submission reads use supabaseService
 * scoped to the requesting user's own record only. RLS on supabaseAnon
 * prevents seeing other users' submissions before submitting.
 */

import { Router } from 'express';
import { supabaseService } from '../lib/supabase.js';
import { requireAuth } from '../middleware/auth.js';
import { requireConnected, requireNotSuspended } from '../middleware/tierGuards.js';
import { requireAiApiKey } from '../middleware/aiAuth.js';
import { createSubmissionSchema, createAiSubmissionSchema } from '../types/api.js';
import type {
  SubmissionSuccessResponse,
  SubmissionErrorResponse,
  AiSubmissionSuccessResponse,
  YellowQuestResult,
} from '../types/api.js';
import { validateSourceUrl } from '../services/sourceValidator.js';
import {
  getOrCreateProfile,
  applyCredibilityChange,
  checkSubmissionEligibility,
} from '../services/credibility.js';
import { normalizeAnswer, answersMatch } from '../services/normalization.js';
// DIFFICULTY_REWARDS import removed — XP is now a flat amount per quest type, not difficulty-based
import type { VerificationQuest } from '../types/database.types.js';
import { logger } from '../lib/logger.js';
import { invalidateFeedCache } from '../services/feedScoring.js';
// Engine consolidation, Phase 4: now that VQ runs inside the engine, call the engine's
// verification-rating service in-process instead of looping back over HTTP to
// /api/vq/adjust-vr with a service key. Same logic and idempotency, no key.
import { adjustVerificationRating } from '../../lib/vqService.js';

const router = Router();

const ACCOUNTS_URL = process.env.ACCOUNTS_URL ?? 'https://ev-accounts-api.onrender.com';

// ============================================================
// POST / — Submit or update an answer
// ============================================================

router.post(
  '/',
  requireAuth,
  requireNotSuspended,
  requireConnected,
  async (req: any, res: any) => {
    const userId = req.userId as string;

    // --------------------------------------------------------
    // VQ hold check — fetch /account/me to enforce VR-based hold.
    // Fail open on errors (hold is a protection, not a security gate).
    // --------------------------------------------------------
    try {
      const meRes = await fetch(`${ACCOUNTS_URL}/api/account/me`, {
        headers: { Authorization: req.headers.authorization ?? '' },
      });
      if (meRes.ok) {
        const meData = await meRes.json() as {
          vq_hold_active?: boolean;
          vq_hold_until?: string | null;
        };
        if (meData.vq_hold_active === true) {
          return res.status(403).json({
            error: 'Verification hold active',
            code: 'VQ_HOLD_ACTIVE',
            hold_until: meData.vq_hold_until ?? null,
          });
        }
      }
    } catch (err) {
      logger.warn('Failed to fetch /api/account/me for VQ hold check — proceeding', {
        userId,
        error: String(err),
      });
    }

    // --------------------------------------------------------
    // Step 1: Validate request body
    // --------------------------------------------------------
    const parsed = createSubmissionSchema.safeParse(req.body);
    if (!parsed.success) {
      const response: SubmissionErrorResponse = {
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid submission data',
          action: 'Fix the highlighted fields and resubmit.',
        },
      };
      return res.status(422).json({
        ...response,
        details: parsed.error.issues,
      });
    }

    const { quest_id, answer_text, sources } = parsed.data;

    // --------------------------------------------------------
    // Step 2: Check submission eligibility (credibility lockout)
    // --------------------------------------------------------
    let eligibility: Awaited<ReturnType<typeof checkSubmissionEligibility>>;
    try {
      eligibility = await checkSubmissionEligibility(userId);
    } catch (err) {
      logger.error('Failed to check submission eligibility', { userId, error: String(err) });
      return res.status(500).json({ error: 'Failed to verify submission eligibility' });
    }

    if (!eligibility.eligible) {
      const response: SubmissionErrorResponse = {
        error: {
          code: 'CREDIBILITY_LOCKOUT',
          message: `Your submission access is temporarily suspended (credibility score: ${eligibility.score}). This happens when sources repeatedly fail validation.`,
          action:
            'To restore access: review your previous submissions, ensure all sources are publicly accessible, and contact support if you believe this is an error. Recovery is possible.',
        },
      };
      return res.status(403).json(response);
    }

    // --------------------------------------------------------
    // Step 2b: Check restriction state (review_required / daily limit)
    // --------------------------------------------------------
    let veracityProfile: { restriction_state: string } | null = null;
    try {
      const profileResult = await supabaseService
        .schema('validation_quests')
        .from('user_veracity_profiles')
        .select('restriction_state')
        .eq('user_id', userId)
        .maybeSingle();
      if (profileResult && typeof profileResult === 'object' && 'data' in profileResult) {
        veracityProfile = (profileResult as { data: unknown; error: unknown }).data as { restriction_state: string } | null;
      }
    } catch (err) {
      logger.warn('Failed to fetch veracity profile for restriction check', {
        userId,
        error: String(err),
      });
      // Non-fatal: proceed without restriction check if profile unavailable
    }

    if (veracityProfile) {
      // review_required blocks all submissions
      if (veracityProfile.restriction_state === 'review_required') {
        return res.status(403).json({
          error: {
            code: 'REVIEW_REQUIRED',
            message:
              'Your submissions are under review due to multiple recent incorrect answers. An administrator will review your account.',
            action:
              'Wait for admin review. Review the educational feedback on your recent submissions to improve accuracy.',
          },
        });
      }

      // limited: enforce daily submission limit (5 per 24h)
      if (veracityProfile.restriction_state === 'limited') {
        const limitResult = await supabaseService
          .schema('validation_quests')
          .from('verification_submissions')
          .select('id', { count: 'exact', head: true })
          .eq('user_id', userId)
          .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

        const dailyCount = limitResult && typeof limitResult === 'object' && 'count' in limitResult
          ? (limitResult as { count: number | null }).count ?? 0
          : 0;

        if (dailyCount >= 5) {
          return res.status(429).json({
            error: {
              code: 'DAILY_LIMIT_REACHED',
              message:
                'You have reached your daily submission limit (5 per day) while your account accuracy is being monitored.',
              action:
                'Try again tomorrow. Focus on research quality over quantity.',
            },
          });
        }
      }
    }

    // --------------------------------------------------------
    // Step 3: Verify quest exists and is active
    // --------------------------------------------------------
    const { data: quest, error: questError } = await supabaseService
      .schema('validation_quests')
      .from('verification_quests')
      .select('id, question_text, difficulty_tier, status, gem_quest_type, correct_answer, politician_id, topic_id')
      .eq('id', quest_id)
      .single();

    if (questError) {
      if (questError.code === 'PGRST116') {
        return res.status(404).json({
          error: {
            code: 'QUEST_NOT_FOUND',
            message: 'This quest does not exist.',
            action: 'Check the quest ID and try again.',
          },
        });
      }
      logger.error('Failed to fetch quest for submission', { questId: quest_id, error: questError.message });
      return res.status(500).json({ error: 'Failed to verify quest' });
    }

    const questRow = quest as Pick<VerificationQuest, 'id' | 'question_text' | 'difficulty_tier' | 'status'> & {
      gem_quest_type: 'yellow' | 'red';
      correct_answer: string | null;
      politician_id: string | null;
      topic_id: string | null;
    };

    if (questRow.status !== 'active') {
      return res.status(404).json({
        error: {
          code: 'QUEST_NOT_ACTIVE',
          message: `This quest is no longer accepting submissions (status: ${questRow.status}).`,
          action: 'Browse the quest feed to find active quests.',
        },
      });
    }

    // --------------------------------------------------------
    // Step 3b: Yellow quest re-submission block
    // Yellow quests are graded immediately on first submission — no updates allowed.
    // --------------------------------------------------------
    if (questRow.gem_quest_type === 'yellow' && questRow.correct_answer) {
      const { data: priorSub } = await supabaseService
        .schema('validation_quests')
        .from('verification_submissions')
        .select('id')
        .eq('user_id', userId)
        .eq('quest_id', quest_id)
        .maybeSingle();

      if (priorSub) {
        return res.status(409).json({
          error: {
            code: 'YELLOW_QUEST_ALREADY_SUBMITTED',
            message: 'You have already submitted an answer to this Yellow quest. Yellow quests can only be answered once.',
            action: 'Browse the quest feed to find new quests.',
          },
        });
      }
    }

    // --------------------------------------------------------
    // Step 4: Validate all source URLs in parallel
    // --------------------------------------------------------
    const validationResults = await Promise.all(
      sources.map((source) => validateSourceUrl(source.url))
    );

    // Find first failing source (process in order for deterministic error messages)
    for (let i = 0; i < validationResults.length; i++) {
      const result = validationResults[i];
      const source = sources[i];

      if (!result.valid) {
        // Determine whether this counts as a credibility hit
        const isUserFault =
          result.reason === 'paywall_suspected' ||
          result.reason === 'not_found' ||
          result.reason === 'unreachable';

        let credibilityResult: Awaited<ReturnType<typeof applyCredibilityChange>> | undefined;
        if (isUserFault) {
          try {
            credibilityResult = await applyCredibilityChange(userId, quest_id, 'source_rejected');
          } catch (err) {
            logger.error('Failed to apply credibility change on source rejection', {
              userId,
              error: String(err),
            });
            // Non-fatal: continue returning the source error
          }
        }

        let code: string;
        let message: string;
        let action: string;

        switch (result.reason) {
          case 'paywall_suspected':
            code = 'SOURCE_PAYWALL';
            message = `We couldn't verify source #${i + 1} (${source.url}) — it appears to be behind a paywall or requires login. Paywalled sources aren't accepted here — sources must be widely accessible.`;
            action =
              'Try Wikipedia, an official .gov website, or a major news outlet instead. Publicly accessible sources work best.';
            break;
          case 'not_found':
            code = 'SOURCE_NOT_FOUND';
            message = `We couldn't find source #${i + 1} (${source.url}) — the page returned a 404 Not Found error.`;
            action =
              'Double-check the URL for typos. If the page moved, search for the content on the original site or find an archived version via web.archive.org.';
            break;
          case 'unreachable':
            code = 'SOURCE_UNREACHABLE';
            message = `We couldn't reach source #${i + 1} (${source.url}) — the site didn't respond.`;
            action =
              'Check the URL for typos. If the site is consistently unreachable, try a different source from a major news outlet, Wikipedia, or an official government website.';
            break;
          case 'timeout':
            code = 'SOURCE_TEMPORARILY_UNAVAILABLE';
            message = `Source #${i + 1} (${source.url}) didn't respond in time — the site appears temporarily unavailable.`;
            action =
              'No credibility impact. Wait a few minutes and try again, or use a different source if the site is consistently slow.';
            break;
          case 'server_error':
            code = 'SOURCE_TEMPORARILY_UNAVAILABLE';
            message = `Source #${i + 1} (${source.url}) returned a server error — this is a temporary issue on the source site, not your submission.`;
            action =
              'No credibility impact. Try again in a few minutes, or use a different source in the meantime.';
            break;
        }

        const response: SubmissionErrorResponse = {
          error: { code: code!, message: message!, action: action! },
        };

        if (credibilityResult) {
          response.credibility = {
            current_score: credibilityResult.current_score,
            change: credibilityResult.change,
            reason: credibilityResult.reason,
          };
        } else if (!isUserFault) {
          // Temporary failure — include current score without change
          try {
            const profile = await getOrCreateProfile(userId);
            response.credibility = {
              current_score: profile.credibility_score,
              change: 0,
              reason: 'Temporary source error — no credibility impact',
            };
          } catch {
            // Best-effort; don't block the error response
          }
        }

        return res.status(422).json(response);
      }
    }

    // --------------------------------------------------------
    // Step 4b: Stance quest detection and numeric validation
    // Stance quests bypass JaroWinkler normalization — the answer
    // is a numeric value (integer or decimal) stored directly.
    // --------------------------------------------------------
    const isStanceQuest = Boolean(questRow.politician_id) && Boolean(questRow.topic_id);

    if (isStanceQuest) {
      const numericValue = Number(answer_text);
      if (isNaN(numericValue) || numericValue < 1 || numericValue > 5) {
        return res.status(422).json({
          error: {
            code: 'INVALID_STANCE_VALUE',
            message: 'Stance quest answers must be a numeric value between 1 and 5.',
            action: 'Select a valid stance option and resubmit.',
          },
        });
      }
    }

    // --------------------------------------------------------
    // Step 5: Normalize answer text (bypassed for stance quests)
    // Stance quests store the numeric value as-is — JaroWinkler
    // normalization would corrupt numeric strings.
    // --------------------------------------------------------
    const normalized = isStanceQuest ? answer_text : normalizeAnswer(answer_text);

    // --------------------------------------------------------
    // Step 6: Upsert submission (with answer archiving)
    // --------------------------------------------------------
    const now = new Date().toISOString();
    let isUpdate = false;
    let submissionId: string;
    let submittedAt: string;

    // Check for existing submission (read-before-write for archive logic)
    const { data: existing } = await supabaseService
      .schema('validation_quests')
      .from('verification_submissions')
      .select('id, answer_text, normalized_answer, answer_history, created_at')
      .eq('quest_id', quest_id)
      .eq('user_id', userId)
      .maybeSingle();

    if (existing) {
      isUpdate = true;
      submissionId = existing.id;
      submittedAt = existing.created_at;

      const existingRecord = existing as {
        id: string;
        answer_text: string;
        normalized_answer: string | null;
        answer_history: Array<{ answer_text: string; normalized_answer: string | null; archived_at: string }>;
        created_at: string;
      };

      if (existingRecord.answer_text !== answer_text) {
        // Answer text changed — archive the old answer before overwriting
        const archiveEntry = {
          answer_text: existingRecord.answer_text,
          normalized_answer: existingRecord.normalized_answer,
          archived_at: now,
        };
        const updatedHistory = [...(existingRecord.answer_history || []), archiveEntry];

        const { error: updateError } = await supabaseService
          .schema('validation_quests')
          .from('verification_submissions')
          .update({
            answer_text,
            normalized_answer: normalized,
            sources,
            answer_history: updatedHistory,
            updated_at: now,
          })
          .eq('id', submissionId);

        if (updateError) {
          logger.error('Failed to update submission with new answer', {
            submissionId,
            error: updateError.message,
          });
          return res.status(500).json({ error: 'Failed to update submission' });
        }
      } else {
        // Same answer text — source-only addition or re-submission; update sources only
        const { error: updateError } = await supabaseService
          .schema('validation_quests')
          .from('verification_submissions')
          .update({
            sources,
            updated_at: now,
          })
          .eq('id', submissionId);

        if (updateError) {
          logger.error('Failed to update submission sources', {
            submissionId,
            error: updateError.message,
          });
          return res.status(500).json({ error: 'Failed to update submission sources' });
        }
      }
    } else {
      // New submission — insert
      const { data: inserted, error: insertError } = await supabaseService
        .schema('validation_quests')
        .from('verification_submissions')
        .insert({
          quest_id,
          user_id: userId,
          submitter_type: 'human_connected',
          answer_text,
          normalized_answer: normalized,
          sources,
          submission_weight: 1.0,
          status: 'pending',
          answer_history: [],
        })
        .select('id, created_at')
        .single();

      if (insertError || !inserted) {
        logger.error('Failed to insert submission', {
          userId,
          questId: quest_id,
          error: insertError?.message,
        });
        return res.status(500).json({ error: 'Failed to create submission' });
      }

      submissionId = (inserted as { id: string; created_at: string }).id;
      submittedAt = (inserted as { id: string; created_at: string }).created_at;

      // For red quests: increment total + pending now. Yellow quests handle their
      // own counts in the grading block below (after outcome is known).
      if (questRow.gem_quest_type !== 'yellow') {
        await supabaseService
          .schema('validation_quests')
          .rpc('record_submission_counts', { p_user_id: userId, p_outcome: null });
      }
    }

    // --------------------------------------------------------
    // Step 7: Apply credibility gain (+1 for accepted source)
    // --------------------------------------------------------
    let credibilityResult: Awaited<ReturnType<typeof applyCredibilityChange>>;
    try {
      credibilityResult = await applyCredibilityChange(userId, quest_id, 'source_accepted');
    } catch (err) {
      logger.error('Failed to apply credibility gain', { userId, error: String(err) });
      // Non-fatal: fall back to current profile for response
      const profile = await getOrCreateProfile(userId);
      credibilityResult = {
        current_score: profile.credibility_score,
        change: 0,
        reason: 'Credibility gain recording failed — score unchanged',
        quarantined: profile.credibility_score < 40 && profile.credibility_score >= 0,
        locked_out: profile.credibility_score < 0,
      };
    }

    // --------------------------------------------------------
    // Step 8: Build and return SubmissionSuccessResponse
    // --------------------------------------------------------
    // XP is awarded per quest type: 50 XP for correct yellow quests (below), 75 XP for correct red quests (at consensus).
    let xpAwarded = 0;

    // Yellow quest immediate grading — POST /api/vq/adjust-vr via Accounts API
    let yellowQuestResult: YellowQuestResult | undefined;
    if (questRow.gem_quest_type === 'yellow' && questRow.correct_answer) {
      const isCorrect = answersMatch(answer_text, questRow.correct_answer);
      const outcomeValue = isCorrect ? 'correct' : 'incorrect';

      // Persist outcome to DB immediately — consensus engine skips yellow quests,
      // so this is the only place outcome gets written.
      await supabaseService
        .schema('validation_quests')
        .from('verification_submissions')
        .update({ outcome: outcomeValue })
        .eq('id', submissionId!);

      // Update veracity profile counts (total + outcome; no pending for yellow quests).
      if (!isUpdate) {
        await supabaseService
          .schema('validation_quests')
          .rpc('record_submission_counts', { p_user_id: userId, p_outcome: outcomeValue });
      }

      const delta = isCorrect ? 3 : -10;
      // In-process VR adjustment (Phase 4). Idempotency key and non-fatal semantics
      // are preserved: a failure logs and leaves new_vr unset, exactly as the old
      // HTTP path did on a non-2xx or a throw.
      try {
        const vrData = await adjustVerificationRating({
          userId,
          delta,
          idempotencyKey: `vq-yellow-${submissionId}-${userId}`,
          reason: isCorrect ? 'yellow_quest_correct' : 'yellow_quest_incorrect',
        });
        yellowQuestResult = {
          outcome: isCorrect ? 'correct' : 'incorrect',
          correct_answer: questRow.correct_answer,
          vr_delta: delta,
          new_vr: vrData.new_rating,
        };
      } catch (err) {
        logger.warn('adjust-vr for Yellow quest failed — non-fatal', {
          userId,
          questId: quest_id,
          error: String(err),
        });
        yellowQuestResult = {
          outcome: isCorrect ? 'correct' : 'incorrect',
          correct_answer: questRow.correct_answer,
          vr_delta: delta,
        };
      }

      // XP Award for correct yellow quest — POST /api/xp/award via Accounts API
      if (isCorrect) {
        xpAwarded = 50;
        if (process.env.ENABLE_XP_AWARDS === 'true') {
          try {
            const xpRes = await fetch(`${ACCOUNTS_URL}/api/xp/award`, {
              method: 'POST',
              headers: {
                'X-Service-Key': process.env.QUEST_SERVICE_KEY!,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                user_id: userId,
                source: 'validation_quest_completion',
                amount: 50,
                idempotency_key: `vq-submit-${submissionId}-${userId}`,
                metadata: { questId: quest_id, submissionId },
              }),
            });
            if (!xpRes.ok) {
              logger.warn('XP award at submission failed — non-fatal', {
                userId,
                questId: quest_id,
                status: xpRes.status,
              });
            }
          } catch (err) {
            logger.warn('XP award at submission threw — non-fatal', { userId, error: String(err) });
          }
        }
      }

      // Award Yellow gems for correct answer: 1 gem (answer) + 2 gems (source) = 3 total.
      // Two separate calls with distinct transaction_types so the gem ledger shows WHY each gem was earned.
      // Non-fatal: failures are logged but do NOT block the submission response.
      if (isCorrect) {
        try {
          const { error: gemAnswerError } = await supabaseService
            .schema('connect')
            .rpc('credit_gems', {
              p_user_id: userId,
              p_gem_type: 'yellow',
              p_amount: 1,
              p_transaction_type: 'yellow_quest_correct_answer',
              p_source_ref: submissionId,
            });
          if (gemAnswerError) {
            logger.warn('Yellow gem award (answer) failed — non-fatal', {
              userId,
              questId: quest_id,
              error: gemAnswerError.message,
            });
          }
        } catch (err) {
          logger.warn('Yellow gem award (answer) threw — non-fatal', { userId, error: String(err) });
        }

        try {
          const { error: gemSourceError } = await supabaseService
            .schema('connect')
            .rpc('credit_gems', {
              p_user_id: userId,
              p_gem_type: 'yellow',
              p_amount: 2,
              p_transaction_type: 'yellow_quest_valid_source',
              p_source_ref: submissionId,
            });
          if (gemSourceError) {
            logger.warn('Yellow gem award (source) failed — non-fatal', {
              userId,
              questId: quest_id,
              error: gemSourceError.message,
            });
          }
        } catch (err) {
          logger.warn('Yellow gem award (source) threw — non-fatal', { userId, error: String(err) });
        }

        if (yellowQuestResult) {
          yellowQuestResult.gems_awarded = 3;
        }
      }
    }

    const isQuarantined = eligibility.quarantined || credibilityResult.quarantined;

    const response: SubmissionSuccessResponse = {
      submission_id: submissionId!,
      quest_name: questRow.question_text,
      answer_text,
      sources: sources.map((s) => ({
        url: s.url,
        source_type: s.source_type,
        retrieved_date: s.retrieved_date,
        description: s.description,
      })),
      xp_awarded: xpAwarded,
      submitted_at: submittedAt!,
      is_update: isUpdate,
      ...(isQuarantined && { quarantined: true }),
      credibility: credibilityResult,
      ...(yellowQuestResult && { yellow_quest_result: yellowQuestResult }),
    };

    // Invalidate feed cache — user has submitted, their feed should refresh on next request
    try {
      await invalidateFeedCache(userId);
    } catch (cacheErr) {
      logger.warn('Failed to invalidate feed cache after submission', {
        userId,
        error: String(cacheErr),
      });
    }

    const statusCode = isUpdate ? 200 : 201;
    return res.status(statusCode).json(response);
  }
);

// ============================================================
// POST /ai — AI agent submission
// ============================================================
// Auth: requireAiApiKey (x-api-key header → SHA-256 → ai_agent_credentials)
// No credibility tracking — AI agents do not have credibility profiles.
// Requires minimum 2 sources (createAiSubmissionSchema).
// ============================================================

router.post('/ai', requireAiApiKey, async (req: any, res: any) => {
  const agentId = req.agentId as string;

  // --------------------------------------------------------
  // Step 1: Validate request body (min 2 sources for AI)
  // --------------------------------------------------------
  const parsed = createAiSubmissionSchema.safeParse(req.body);
  if (!parsed.success) {
    const response: SubmissionErrorResponse = {
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid AI submission data',
        action: 'AI agents must provide at least 2 source URLs. Fix the highlighted fields and resubmit.',
      },
    };
    return res.status(422).json({
      ...response,
      details: parsed.error.issues,
    });
  }

  const { quest_id, answer_text, sources } = parsed.data;

  // --------------------------------------------------------
  // Step 2: Verify quest exists and is active
  // --------------------------------------------------------
  const { data: quest, error: questError } = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .select('id, question_text, difficulty_tier, status, politician_id, topic_id')
    .eq('id', quest_id)
    .single();

  if (questError) {
    if (questError.code === 'PGRST116') {
      return res.status(404).json({
        error: {
          code: 'QUEST_NOT_FOUND',
          message: 'This quest does not exist.',
          action: 'Check the quest ID and try again.',
        },
      });
    }
    logger.error('AI: Failed to fetch quest for submission', {
      questId: quest_id,
      error: questError.message,
    });
    return res.status(500).json({ error: 'Failed to verify quest' });
  }

  const questRow = quest as Pick<VerificationQuest, 'id' | 'question_text' | 'difficulty_tier' | 'status'> & {
    politician_id: string | null;
    topic_id: string | null;
  };

  if (questRow.status !== 'active') {
    return res.status(404).json({
      error: {
        code: 'QUEST_NOT_ACTIVE',
        message: `This quest is no longer accepting submissions (status: ${questRow.status}).`,
        action: 'Browse the quest feed to find active quests.',
      },
    });
  }

  // --------------------------------------------------------
  // Step 3: Validate all source URLs in parallel
  // No credibility changes for AI agents — skip applyCredibilityChange entirely.
  // --------------------------------------------------------
  const validationResults = await Promise.all(
    sources.map((source) => validateSourceUrl(source.url))
  );

  for (let i = 0; i < validationResults.length; i++) {
    const result = validationResults[i];
    const source = sources[i];

    if (!result.valid) {
      let code: string;
      let message: string;
      let action: string;

      switch (result.reason) {
        case 'paywall_suspected':
          code = 'SOURCE_PAYWALL';
          message = `We couldn't verify source #${i + 1} (${source.url}) — it appears to be behind a paywall or requires login.`;
          action =
            'Try Wikipedia, an official .gov website, or a major news outlet instead. Publicly accessible sources work best.';
          break;
        case 'not_found':
          code = 'SOURCE_NOT_FOUND';
          message = `We couldn't find source #${i + 1} (${source.url}) — the page returned a 404 Not Found error.`;
          action =
            'Double-check the URL. If the page moved, find an archived version via web.archive.org.';
          break;
        case 'unreachable':
          code = 'SOURCE_UNREACHABLE';
          message = `We couldn't reach source #${i + 1} (${source.url}) — the site didn't respond.`;
          action =
            'Check the URL for typos. Try a different source from a major news outlet, Wikipedia, or an official government website.';
          break;
        case 'timeout':
          code = 'SOURCE_TEMPORARILY_UNAVAILABLE';
          message = `Source #${i + 1} (${source.url}) didn't respond in time — the site appears temporarily unavailable.`;
          action = 'Wait a few minutes and try again, or use a different source.';
          break;
        case 'server_error':
          code = 'SOURCE_TEMPORARILY_UNAVAILABLE';
          message = `Source #${i + 1} (${source.url}) returned a server error — this is a temporary issue on the source site.`;
          action = 'Try again in a few minutes, or use a different source in the meantime.';
          break;
      }

      return res.status(422).json({
        error: { code: code!, message: message!, action: action! },
      });
    }
  }

  // Stance quest detection and numeric validation (same logic as human flow)
  const isStanceQuest = Boolean(questRow.politician_id) && Boolean(questRow.topic_id);

  if (isStanceQuest) {
    const numericValue = Number(answer_text);
    if (isNaN(numericValue) || numericValue < 1 || numericValue > 5) {
      return res.status(422).json({
        error: {
          code: 'INVALID_STANCE_VALUE',
          message: 'Stance quest answers must be a numeric value between 1 and 5.',
          action: 'Select a valid stance option and resubmit.',
        },
      });
    }
  }

  // --------------------------------------------------------
  // Step 4: Normalize answer text (bypassed for stance quests)
  // --------------------------------------------------------
  const normalized = isStanceQuest ? answer_text : normalizeAnswer(answer_text);

  // --------------------------------------------------------
  // Step 5: Upsert submission (with answer archiving)
  // --------------------------------------------------------
  const now = new Date().toISOString();
  let isUpdate = false;
  let submissionId: string;
  let submittedAt: string;

  // Check for existing submission from this agent for this quest
  const { data: existing } = await supabaseService
    .schema('validation_quests')
    .from('verification_submissions')
    .select('id, answer_text, normalized_answer, answer_history, created_at')
    .eq('quest_id', quest_id)
    .eq('user_id', agentId)
    .maybeSingle();

  if (existing) {
    isUpdate = true;
    submissionId = existing.id;
    submittedAt = existing.created_at;

    const existingRecord = existing as {
      id: string;
      answer_text: string;
      normalized_answer: string | null;
      answer_history: Array<{ answer_text: string; normalized_answer: string | null; archived_at: string }>;
      created_at: string;
    };

    if (existingRecord.answer_text !== answer_text) {
      // Answer changed — archive old answer
      const archiveEntry = {
        answer_text: existingRecord.answer_text,
        normalized_answer: existingRecord.normalized_answer,
        archived_at: now,
      };
      const updatedHistory = [...(existingRecord.answer_history || []), archiveEntry];

      const { error: updateError } = await supabaseService
        .schema('validation_quests')
        .from('verification_submissions')
        .update({
          answer_text,
          normalized_answer: normalized,
          sources,
          answer_history: updatedHistory,
          updated_at: now,
        })
        .eq('id', submissionId);

      if (updateError) {
        logger.error('AI: Failed to update submission with new answer', {
          submissionId,
          error: updateError.message,
        });
        return res.status(500).json({ error: 'Failed to update submission' });
      }
    } else {
      // Same answer — source-only update
      const { error: updateError } = await supabaseService
        .schema('validation_quests')
        .from('verification_submissions')
        .update({ sources, updated_at: now })
        .eq('id', submissionId);

      if (updateError) {
        logger.error('AI: Failed to update submission sources', {
          submissionId,
          error: updateError.message,
        });
        return res.status(500).json({ error: 'Failed to update submission sources' });
      }
    }
  } else {
    // New submission — insert
    const { data: inserted, error: insertError } = await supabaseService
      .schema('validation_quests')
      .from('verification_submissions')
      .insert({
        quest_id,
        user_id: agentId,
        submitter_type: 'ai_agent',
        answer_text,
        normalized_answer: normalized,
        sources,
        submission_weight: 1.0,
        status: 'pending',
        answer_history: [],
      })
      .select('id, created_at')
      .single();

    if (insertError || !inserted) {
      logger.error('AI: Failed to insert submission', {
        agentId,
        questId: quest_id,
        error: insertError?.message,
      });
      return res.status(500).json({ error: 'Failed to create submission' });
    }

    submissionId = (inserted as { id: string; created_at: string }).id;
    submittedAt = (inserted as { id: string; created_at: string }).created_at;
  }

  // --------------------------------------------------------
  // Step 6: Return AiSubmissionSuccessResponse
  // --------------------------------------------------------
  const response: AiSubmissionSuccessResponse = {
    submission_id: submissionId!,
    quest_name: questRow.question_text,
    answer_text,
    sources: sources.map((s) => ({
      url: s.url,
      source_type: s.source_type,
      retrieved_date: s.retrieved_date,
      description: s.description,
    })),
    submitted_at: submittedAt!,
    submitter_type: 'ai_agent',
    is_update: isUpdate,
  };

  const statusCode = isUpdate ? 200 : 201;
  return res.status(statusCode).json(response);
});

export default router;
