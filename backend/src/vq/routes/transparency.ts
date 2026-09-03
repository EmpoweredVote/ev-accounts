/**
 * transparency.ts
 * GET /api/quests/:id/transparency — Post-consensus transparency drill-down
 *
 * Pre-consensus: returns { status: 'verifying', submission_count: N }
 *   - NO answer distribution, NO named verifiers, NO alignment data
 *
 * Post-consensus: returns TransparencyBreakdown with:
 *   - total_submissions, alignment_percentage, human_count, ai_count
 *   - authoritative_sources from consensus_records
 *   - named_verifiers: Empowered users who submitted correctly (by display name)
 *   - connected_verifier_count: Connected correct submitters as aggregate count
 *   - user_submission: requesting user's own submission (answer + outcome), or null
 *
 * Auth: requireAuth + requireNotSuspended + requireConnected
 */

import { Router } from 'express';
import { supabaseService } from '../lib/supabase.js';
import { requireAuth } from '../middleware/auth.js';
import { requireConnected, requireNotSuspended } from '../middleware/tierGuards.js';
import { logger } from '../lib/logger.js';
import type { TransparencyResponse, TransparencyBreakdown, TransparencyVerifying, NamedVerifier } from '../types/api.js';
import type { Source } from '../types/custom.js';

const router = Router();

// ============================================================
// GET /:id/transparency
// ============================================================

router.get('/:id/transparency', requireAuth, requireNotSuspended, requireConnected, async (req: any, res: any) => {
  const questId = req.params.id as string;
  const requestingUserId = req.userId as string;

  try {
    // Step 1: Fetch the quest to check status
    const questResult = await supabaseService
      .schema('validation_quests')
      .from('verification_quests')
      .select('id, status, submission_count')
      .eq('id', questId)
      .single() as {
        data: { id: string; status: string; submission_count: number } | null;
        error: { code?: string; message?: string } | null;
      };

    if (questResult.error) {
      if (questResult.error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Quest not found' });
      }
      logger.error('Failed to fetch quest for transparency', {
        questId,
        error: questResult.error.message,
      });
      return res.status(500).json({ error: 'Failed to fetch quest' });
    }

    const quest = questResult.data!;

    // Step 2: Pre-consensus — return verifying status with submission count only
    if (quest.status !== 'consensus_reached') {
      const response: TransparencyVerifying = {
        status: 'verifying',
        submission_count: quest.submission_count,
      };
      return res.status(200).json(response);
    }

    // Step 3: Post-consensus — fetch consensus record
    const consensusResult = await supabaseService
      .schema('validation_quests')
      .from('consensus_records')
      .select(
        'id, quest_id, consensus_answer, confidence_level, total_submissions, alignment_percentage, human_count, ai_count, authoritative_sources, finalized_at'
      )
      .eq('quest_id', questId)
      .single() as {
        data: {
          id: string;
          quest_id: string;
          consensus_answer: string;
          confidence_level: string;
          total_submissions: number;
          alignment_percentage: number;
          human_count: number;
          ai_count: number;
          authoritative_sources: Source[];
          finalized_at: string | null;
        } | null;
        error: { code?: string; message?: string } | null;
      };

    if (consensusResult.error || !consensusResult.data) {
      logger.error('Failed to fetch consensus record for transparency', {
        questId,
        error: consensusResult.error?.message,
      });
      return res.status(500).json({ error: 'Failed to fetch consensus data' });
    }

    const consensus = consensusResult.data;

    // Step 4: Fetch all submissions for the quest
    const allSubsResult = await supabaseService
      .schema('validation_quests')
      .from('verification_submissions')
      .select('id, user_id, submitter_type, outcome, answer_text, included_in_consensus')
      .eq('quest_id', questId) as {
        data: Array<{
          id: string;
          user_id: string;
          submitter_type: 'human_connected' | 'human_empowered' | 'ai_agent';
          outcome: string | null;
          answer_text: string;
          included_in_consensus: boolean;
        }> | null;
        error: unknown;
      };

    const allSubmissions = allSubsResult.data ?? [];

    // Step 5: Identify correct human submitters
    const correctHumanSubmissions = allSubmissions.filter(
      (s) =>
        s.outcome === 'correct' &&
        (s.submitter_type === 'human_connected' || s.submitter_type === 'human_empowered')
    );

    const correctHumanUserIds = correctHumanSubmissions.map((s) => s.user_id);

    // Step 6: Identify Empowered users among correct human submitters
    // Use separate IN query — per STATE.md decision: Supabase JS !left JOIN unreliable
    let empoweredUserIds = new Set<string>();

    if (correctHumanUserIds.length > 0) {
      const empoweredResult = await supabaseService
        .schema('empower')
        .from('empowered_profiles')
        .select('user_id, is_active')
        .in('user_id', correctHumanUserIds) as {
          data: Array<{ user_id: string; is_active: boolean }> | null;
          error: unknown;
        };

      for (const ep of empoweredResult.data ?? []) {
        if (ep.is_active) {
          empoweredUserIds.add(ep.user_id);
        }
      }
    }

    // Step 7: Fetch display names for Empowered verifiers in bulk
    // Source: connect.connected_profiles.display_name
    // CRITICAL: Do NOT use empowered_profiles.legal_name — private field, owner-only per integration guide
    const displayNameMap = new Map<string, string>();

    if (empoweredUserIds.size > 0) {
      const nameResult = await supabaseService
        .schema('connect')
        .from('connected_profiles')
        .select('user_id, display_name')
        .in('user_id', [...empoweredUserIds]) as {
          data: Array<{ user_id: string; display_name: string | null }> | null;
          error: unknown;
        };

      for (const row of (nameResult.data ?? []) as Array<{ user_id: string; display_name: string | null }>) {
        if (row.display_name) {
          displayNameMap.set(row.user_id, row.display_name);
        }
      }
    }

    // Step 8: Build named verifiers (Empowered) and aggregate Connected count
    const namedVerifiers: NamedVerifier[] = [];
    let connectedVerifierCount = 0;

    for (const userId of correctHumanUserIds) {
      if (empoweredUserIds.has(userId)) {
        // Fallback: 'Anonymous Verifier' when display_name is null, user deleted, or fetch error
        // Never expose partial UUID
        namedVerifiers.push({ user_id: userId, display_name: displayNameMap.get(userId) ?? 'Anonymous Verifier' });
      } else {
        connectedVerifierCount++;
      }
    }

    // Step 9: Find requesting user's own submission (if any)
    const userSub = allSubmissions.find((s) => s.user_id === requestingUserId);
    const userSubmission = userSub
      ? { answer: userSub.answer_text, outcome: userSub.outcome ?? 'pending' }
      : null;

    // Step 10: Check if requesting user has already contested this quest
    let userHasContested = false;
    if (requestingUserId) {
      const contestResult = await supabaseService
        .schema('validation_quests')
        .from('quest_contests')
        .select('id')
        .eq('quest_id', questId)
        .eq('filed_by', requestingUserId)
        .limit(1) as {
          data: Array<{ id: string }> | null;
          error: unknown;
        };
      userHasContested = (contestResult.data?.length ?? 0) > 0;
    }

    const response: TransparencyBreakdown = {
      status: 'consensus_reached',
      total_submissions: consensus.total_submissions,
      alignment_percentage: consensus.alignment_percentage,
      human_count: consensus.human_count,
      ai_count: consensus.ai_count,
      authoritative_sources: consensus.authoritative_sources ?? [],
      named_verifiers: namedVerifiers,
      connected_verifier_count: connectedVerifierCount,
      user_submission: userSubmission,
      consensus_answer: consensus.consensus_answer,
      user_has_contested: userHasContested,
    };

    return res.status(200).json(response);
  } catch (err) {
    logger.error('Error in transparency route', { questId, error: String(err) });
    return res.status(500).json({ error: 'Failed to fetch transparency data' });
  }
});

export default router;
