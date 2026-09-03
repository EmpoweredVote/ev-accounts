/**
 * history.ts
 * GET /api/history               — Own submission history (paginated, newest first)
 * GET /api/history/users/:userId — Other user's history (tier-gated)
 *
 * Privacy rules:
 *   - Own history: full HistoryCard list with outcomes, gems, correct answers, sources
 *   - Empowered target: full history visible to anyone (publicly visible)
 *   - Connected target: only accuracy_percentage + total_submissions
 *
 * Auth:
 *   - GET /        : requireAuth + requireNotSuspended + requireConnected
 *   - GET /users/:id: requireAuth only (tier check performed inline)
 */

import { Router } from 'express';
import { supabaseService } from '../lib/supabase.js';
import { requireAuth } from '../middleware/auth.js';
import { requireConnected, requireNotSuspended } from '../middleware/tierGuards.js';
import { logger } from '../lib/logger.js';
import type { HistoryCard, HistoryResponse, UserSummaryResponse } from '../types/api.js';
import type { Source } from '../types/custom.js';

const router = Router();

const PAGE_SIZE = 20;

// ============================================================
// GET / — Own submission history (paginated)
// ============================================================

router.get(
  '/',
  requireAuth,
  requireNotSuspended,
  requireConnected,
  async (req: any, res: any) => {
    const userId = req.userId as string;

    // Parse page param — default 1, must be integer >= 1
    const rawPage = parseInt(String(req.query.page ?? '1'), 10);
    const page = isNaN(rawPage) || rawPage < 1 ? 1 : rawPage;
    const offset = (page - 1) * PAGE_SIZE;

    try {
      // Step 1: Fetch total count
      const countResult = await supabaseService
        .schema('validation_quests')
        .from('verification_submissions')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId) as { count: number | null; error: unknown };

      const total = (countResult as any).count ?? 0;

      // Step 2: Fetch paginated submissions
      const subsResult = await supabaseService
        .schema('validation_quests')
        .from('verification_submissions')
        .select('id, quest_id, answer_text, outcome, feedback, created_at')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .range(offset, offset + PAGE_SIZE - 1) as {
          data: Array<{
            id: string;
            quest_id: string;
            answer_text: string;
            outcome: string | null;
            feedback: { correct_answer?: string; sources?: Source[]; research_tips?: string } | null;
            created_at: string;
          }> | null;
          error: unknown;
        };

      if ((subsResult as any).error) {
        logger.error('Failed to fetch own history', {
          userId,
          error: String((subsResult as any).error),
        });
        return res.status(500).json({ error: 'Failed to fetch history' });
      }

      const submissions = subsResult.data ?? [];

      if (submissions.length === 0) {
        const response: HistoryResponse = {
          submissions: [],
          page,
          page_size: PAGE_SIZE,
          total,
        };
        return res.status(200).json(response);
      }

      const questIds = [...new Set(submissions.map((s) => s.quest_id))];

      // Step 3: Fetch quest metadata
      const questsResult = await supabaseService
        .schema('validation_quests')
        .from('verification_quests')
        .select('id, question_text')
        .in('id', questIds) as {
          data: Array<{ id: string; question_text: string }> | null;
          error: unknown;
        };

      const questMap = new Map<string, string>();
      for (const q of questsResult.data ?? []) {
        questMap.set(q.id, q.question_text);
      }

      // Step 4: Fetch gem reward events
      const gemsResult = await supabaseService
        .schema('validation_quests')
        .from('gem_reward_events')
        .select('quest_id, gem_type, amount, reason')
        .eq('user_id', userId)
        .in('quest_id', questIds) as {
          data: Array<{
            quest_id: string;
            gem_type: 'yellow' | 'red';
            amount: number;
            reason: 'correct_submission' | 'early_bonus';
          }> | null;
          error: unknown;
        };

      // Group gems by quest_id
      const gemsMap = new Map<
        string,
        Array<{ gem_type: 'yellow' | 'red'; amount: number; reason: 'correct_submission' | 'early_bonus' }>
      >();
      for (const gem of gemsResult.data ?? []) {
        const existing = gemsMap.get(gem.quest_id) ?? [];
        existing.push({ gem_type: gem.gem_type, amount: gem.amount, reason: gem.reason });
        gemsMap.set(gem.quest_id, existing);
      }

      // Step 5: Fetch consensus records (includes authoritative_sources)
      const consensusResult = await supabaseService
        .schema('validation_quests')
        .from('consensus_records')
        .select('quest_id, confidence_level, finalized_at, consensus_answer, authoritative_sources')
        .in('quest_id', questIds) as {
          data: Array<{
            quest_id: string;
            confidence_level: string;
            finalized_at: string | null;
            consensus_answer: string;
            authoritative_sources: Source[];
          }> | null;
          error: unknown;
        };

      const consensusMap = new Map<
        string,
        {
          confidence_level: string;
          consensus_answer: string;
          authoritative_sources: Source[];
        }
      >();
      for (const cr of consensusResult.data ?? []) {
        consensusMap.set(cr.quest_id, {
          confidence_level: cr.confidence_level,
          consensus_answer: cr.consensus_answer,
          authoritative_sources: cr.authoritative_sources ?? [],
        });
      }

      // Step 6: Build HistoryCard array
      const historyCards: HistoryCard[] = submissions.map((sub) => {
        const consensus = consensusMap.get(sub.quest_id);
        const gems = gemsMap.get(sub.quest_id) ?? [];

        // correct_answer: only present when user was incorrect (and consensus is available)
        const isIncorrect = sub.outcome === 'incorrect';
        const correctAnswer =
          isIncorrect && consensus ? consensus.consensus_answer : null;

        // authoritative_source: first source from consensus record
        const authoritativeSource =
          consensus && consensus.authoritative_sources.length > 0
            ? consensus.authoritative_sources[0]
            : null;

        const outcome =
          sub.outcome === 'correct' || sub.outcome === 'incorrect' || sub.outcome === 'pending'
            ? sub.outcome
            : 'pending';

        return {
          quest_id: sub.quest_id,
          question_text: questMap.get(sub.quest_id) ?? '',
          user_answer: sub.answer_text,
          outcome,
          gems_earned: gems,
          correct_answer: correctAnswer,
          authoritative_source: authoritativeSource,
          confidence_level: consensus?.confidence_level ?? null,
          submitted_at: sub.created_at,
        };
      });

      const response: HistoryResponse = {
        submissions: historyCards,
        page,
        page_size: PAGE_SIZE,
        total,
      };

      return res.status(200).json(response);
    } catch (err) {
      logger.error('Error in own history route', { userId, error: String(err) });
      return res.status(500).json({ error: 'Failed to fetch history' });
    }
  }
);

// ============================================================
// GET /users/:userId — Another user's history (tier-gated)
// ============================================================

router.get('/users/:userId', requireAuth, async (req: any, res: any) => {
  const requestingUserId = req.userId as string;
  const targetUserId = req.params.userId as string;

  try {
    // If requesting own history — return full history (same path as own)
    if (requestingUserId === targetUserId) {
      return fullHistoryForUser(targetUserId, req, res);
    }

    // Check if target is an Empowered user (empowered_profiles.is_active = true)
    const empoweredResult = await supabaseService
      .schema('empower')
      .from('empowered_profiles')
      .select('is_active')
      .eq('user_id', targetUserId)
      .maybeSingle() as {
        data: { is_active: boolean } | null;
        error: unknown;
      };

    const isEmpowered =
      empoweredResult.data != null && empoweredResult.data.is_active === true;

    if (isEmpowered) {
      // Empowered users are fully public — return full history
      return fullHistoryForUser(targetUserId, req, res);
    }

    // Connected (non-Empowered) target — return summary only
    return userSummaryForUser(targetUserId, res);
  } catch (err) {
    logger.error('Error in other-user history route', {
      requestingUserId,
      targetUserId,
      error: String(err),
    });
    return res.status(500).json({ error: 'Failed to fetch user history' });
  }
});

// ============================================================
// HELPER: full history for a given userId
// ============================================================

async function fullHistoryForUser(userId: string, req: any, res: any) {
  const rawPage = parseInt(String(req.query.page ?? '1'), 10);
  const page = isNaN(rawPage) || rawPage < 1 ? 1 : rawPage;
  const offset = (page - 1) * PAGE_SIZE;

  const countResult = await supabaseService
    .schema('validation_quests')
    .from('verification_submissions')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId) as { count: number | null; error: unknown };

  const total = (countResult as any).count ?? 0;

  const subsResult = await supabaseService
    .schema('validation_quests')
    .from('verification_submissions')
    .select('id, quest_id, answer_text, outcome, feedback, created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .range(offset, offset + PAGE_SIZE - 1) as {
      data: Array<{
        id: string;
        quest_id: string;
        answer_text: string;
        outcome: string | null;
        feedback: { correct_answer?: string; sources?: Source[]; research_tips?: string } | null;
        created_at: string;
      }> | null;
      error: unknown;
    };

  if ((subsResult as any).error) {
    return res.status(500).json({ error: 'Failed to fetch history' });
  }

  const submissions = subsResult.data ?? [];

  if (submissions.length === 0) {
    const response: HistoryResponse = {
      submissions: [],
      page,
      page_size: PAGE_SIZE,
      total,
    };
    return res.status(200).json(response);
  }

  const questIds = [...new Set(submissions.map((s) => s.quest_id))];

  const questsResult = await supabaseService
    .schema('validation_quests')
    .from('verification_quests')
    .select('id, question_text')
    .in('id', questIds) as {
      data: Array<{ id: string; question_text: string }> | null;
      error: unknown;
    };

  const questMap = new Map<string, string>();
  for (const q of questsResult.data ?? []) {
    questMap.set(q.id, q.question_text);
  }

  const gemsResult = await supabaseService
    .schema('validation_quests')
    .from('gem_reward_events')
    .select('quest_id, gem_type, amount, reason')
    .eq('user_id', userId)
    .in('quest_id', questIds) as {
      data: Array<{
        quest_id: string;
        gem_type: 'yellow' | 'red';
        amount: number;
        reason: 'correct_submission' | 'early_bonus';
      }> | null;
      error: unknown;
    };

  const gemsMap = new Map<
    string,
    Array<{ gem_type: 'yellow' | 'red'; amount: number; reason: 'correct_submission' | 'early_bonus' }>
  >();
  for (const gem of gemsResult.data ?? []) {
    const existing = gemsMap.get(gem.quest_id) ?? [];
    existing.push({ gem_type: gem.gem_type, amount: gem.amount, reason: gem.reason });
    gemsMap.set(gem.quest_id, existing);
  }

  const consensusResult = await supabaseService
    .schema('validation_quests')
    .from('consensus_records')
    .select('quest_id, confidence_level, finalized_at, consensus_answer, authoritative_sources')
    .in('quest_id', questIds) as {
      data: Array<{
        quest_id: string;
        confidence_level: string;
        finalized_at: string | null;
        consensus_answer: string;
        authoritative_sources: Source[];
      }> | null;
      error: unknown;
    };

  const consensusMap = new Map<
    string,
    {
      confidence_level: string;
      consensus_answer: string;
      authoritative_sources: Source[];
    }
  >();
  for (const cr of consensusResult.data ?? []) {
    consensusMap.set(cr.quest_id, {
      confidence_level: cr.confidence_level,
      consensus_answer: cr.consensus_answer,
      authoritative_sources: cr.authoritative_sources ?? [],
    });
  }

  const historyCards: HistoryCard[] = submissions.map((sub) => {
    const consensus = consensusMap.get(sub.quest_id);
    const gems = gemsMap.get(sub.quest_id) ?? [];

    const isIncorrect = sub.outcome === 'incorrect';
    const correctAnswer =
      isIncorrect && consensus ? consensus.consensus_answer : null;

    const authoritativeSource =
      consensus && consensus.authoritative_sources.length > 0
        ? consensus.authoritative_sources[0]
        : null;

    const outcome =
      sub.outcome === 'correct' || sub.outcome === 'incorrect' || sub.outcome === 'pending'
        ? sub.outcome
        : 'pending';

    return {
      quest_id: sub.quest_id,
      question_text: questMap.get(sub.quest_id) ?? '',
      user_answer: sub.answer_text,
      outcome,
      gems_earned: gems,
      correct_answer: correctAnswer,
      authoritative_source: authoritativeSource,
      confidence_level: consensus?.confidence_level ?? null,
      submitted_at: sub.created_at,
    };
  });

  const response: HistoryResponse = {
    submissions: historyCards,
    page,
    page_size: PAGE_SIZE,
    total,
  };
  return res.status(200).json(response);
}

// ============================================================
// HELPER: summary-only response for Connected (non-Empowered) user
// ============================================================

async function userSummaryForUser(targetUserId: string, res: any) {
  // Fetch veracity profile for accuracy_percentage and total_submissions
  const profileResult = await supabaseService
    .schema('validation_quests')
    .from('user_veracity_profiles')
    .select('total_submissions, accuracy_rate')
    .eq('user_id', targetUserId)
    .maybeSingle() as {
      data: { total_submissions: number; accuracy_rate: number | null } | null;
      error: unknown;
    };

  if (profileResult.data == null) {
    // No profile — new user with no submissions
    const summary: UserSummaryResponse = {
      accuracy_percentage: null,
      total_submissions: 0,
    };
    return res.status(200).json(summary);
  }

  const summary: UserSummaryResponse = {
    accuracy_percentage: profileResult.data.accuracy_rate,
    total_submissions: profileResult.data.total_submissions,
  };
  return res.status(200).json(summary);
}

export default router;
