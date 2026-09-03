/**
 * profile.ts
 * GET /api/profile — Verification stats for the authenticated user
 *
 * Returns aggregated stats from user_veracity_profiles:
 *   total_submissions, correct_submissions, accuracy_rate
 *
 * New users with no submissions get zeroed defaults (no profile row yet).
 *
 * Auth: requireAuth + requireNotSuspended + requireConnected
 */

import { Router } from 'express';
import { supabaseService } from '../lib/supabase.js';
import { requireAuth } from '../middleware/auth.js';
import { requireConnected, requireNotSuspended } from '../middleware/tierGuards.js';
import { logger } from '../lib/logger.js';

const router = Router();

// ============================================================
// GET / — Own verification stats
// ============================================================

router.get(
  '/',
  requireAuth,
  requireNotSuspended,
  requireConnected,
  async (req: any, res: any) => {
    const userId = req.userId as string;

    try {
      const result = await supabaseService
        .schema('validation_quests')
        .from('user_veracity_profiles')
        .select('total_submissions, correct_submissions, accuracy_rate')
        .eq('user_id', userId)
        .maybeSingle() as {
          data: {
            total_submissions: number;
            correct_submissions: number;
            accuracy_rate: number | null;
          } | null;
          error: unknown;
        };

      if ((result as any).error) {
        logger.error('Failed to fetch user veracity profile', {
          userId,
          error: String((result as any).error),
        });
        return res.status(500).json({ error: 'Failed to fetch profile stats' });
      }

      if (result.data == null) {
        // New user — no submissions yet
        return res.status(200).json({
          total_submissions: 0,
          correct_submissions: 0,
          accuracy_rate: null,
        });
      }

      return res.status(200).json({
        total_submissions: result.data.total_submissions,
        correct_submissions: result.data.correct_submissions,
        accuracy_rate: result.data.accuracy_rate,
      });
    } catch (err) {
      logger.error('Error in profile stats route', { userId, error: String(err) });
      return res.status(500).json({ error: 'Failed to fetch profile stats' });
    }
  }
);

export default router;
