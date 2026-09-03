/**
 * contests.ts
 * POST /api/contests — File a contestation against a confirmed consensus
 *
 * Flow:
 *   1. Validate request body (createContestSchema)
 *   2. Check active contest limit (max 3)
 *   3. Verify quest exists and status === 'consensus_reached'
 *   4. Verify requesting user has a submission on the quest
 *   5. Write quest_contests row (status: 'pending')
 *   6. Set quest status to under_review
 *   7. Set veracity_suspended = true on user's submission
 *   8. Return 201 ContestSuccessResponse
 *
 * Auth: requireAuth + requireNotSuspended + requireConnected
 * Requirements: CONTEST-01, CONTEST-02, CONTEST-03, CONTEST-04, CONTEST-06
 */

import { Router } from 'express';
import { supabaseService } from '../lib/supabase.js';
import { requireAuth } from '../middleware/auth.js';
import { requireConnected, requireNotSuspended } from '../middleware/tierGuards.js';
import { logger } from '../lib/logger.js';
import { createContestSchema } from '../types/api.js';
import type { ContestSuccessResponse } from '../types/api.js';

const router = Router();

// ============================================================
// POST / — File a contestation
// ============================================================

router.post('/', requireAuth, requireNotSuspended, requireConnected, async (req: any, res: any) => {
  const userId = req.userId as string;

  // Step 1: Validate request body
  const parseResult = createContestSchema.safeParse(req.body);
  if (!parseResult.success) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: parseResult.error.issues[0]?.message ?? 'Invalid request body',
      },
    });
  }

  const { quest_id: questId, source_url, explanation, proposed_answer } = parseResult.data;

  try {
    // Step 2: Check active contest limit (max 3)
    const contestCountResult = await supabaseService
      .schema('validation_quests')
      .from('quest_contests')
      .select('id', { count: 'exact', head: true })
      .eq('filed_by', userId)
      .in('status', ['pending', 'under_review']) as { count: number | null; error: unknown };

    const activeContestCount = (contestCountResult as any).count ?? 0;

    if (activeContestCount >= 3) {
      return res.status(422).json({
        error: {
          code: 'CONTEST_LIMIT_REACHED',
          message: 'You have 3 active contests',
        },
      });
    }

    // Step 3: Verify quest exists and status === 'consensus_reached'
    const questResult = await supabaseService
      .schema('validation_quests')
      .from('verification_quests')
      .select('id, status')
      .eq('id', questId)
      .maybeSingle() as {
        data: { id: string; status: string } | null;
        error: unknown;
      };

    if ((questResult as any).error) {
      logger.error('Failed to fetch quest for contestation', {
        questId,
        error: String((questResult as any).error),
      });
      return res.status(500).json({ error: 'Failed to fetch quest' });
    }

    if (questResult.data == null) {
      return res.status(404).json({
        error: { code: 'QUEST_NOT_FOUND' },
      });
    }

    if (questResult.data.status !== 'consensus_reached') {
      return res.status(409).json({
        error: { code: 'QUEST_NOT_CONTESTABLE' },
      });
    }

    // Step 4: Verify user has a submission on this quest
    const submissionResult = await supabaseService
      .schema('validation_quests')
      .from('verification_submissions')
      .select('id')
      .eq('quest_id', questId)
      .eq('user_id', userId)
      .maybeSingle() as {
        data: { id: string } | null;
        error: unknown;
      };

    if (submissionResult.data == null) {
      return res.status(403).json({
        error: { code: 'NO_SUBMISSION' },
      });
    }

    const submissionId = submissionResult.data.id;

    // Step 5: Write quest_contests row
    const insertResult = await supabaseService
      .schema('validation_quests')
      .from('quest_contests')
      .insert({
        quest_id: questId,
        filed_by: userId,
        source_url,
        explanation,
        proposed_answer,
        status: 'pending',
      })
      .select('id')
      .single() as {
        data: { id: string } | null;
        error: unknown;
      };

    if ((insertResult as any).error || insertResult.data == null) {
      logger.error('Failed to insert quest_contests row', {
        questId,
        userId,
        error: String((insertResult as any).error),
      });
      return res.status(500).json({ error: 'Failed to file contestation' });
    }

    const contestId = insertResult.data.id;

    // Step 6: Set quest status to under_review
    await supabaseService
      .schema('validation_quests')
      .from('verification_quests')
      .update({ status: 'under_review' })
      .eq('id', questId);

    // Step 7: Set veracity_suspended = true on user's submission
    await supabaseService
      .schema('validation_quests')
      .from('verification_submissions')
      .update({ veracity_suspended: true })
      .eq('id', submissionId);

    // Step 8: Return 201 ContestSuccessResponse
    const response: ContestSuccessResponse = {
      contest_id: contestId,
      quest_id: questId,
      status: 'pending',
      message:
        'Your contestation has been filed. The quest is now under review and your submission veracity is suspended pending resolution.',
    };

    return res.status(201).json(response);
  } catch (err) {
    logger.error('Unexpected error in contests route', {
      questId,
      userId,
      error: String(err),
    });
    return res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
