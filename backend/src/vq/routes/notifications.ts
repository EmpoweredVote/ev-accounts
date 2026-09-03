/**
 * notifications.ts
 * GET /api/notifications        — Fetch unread notifications for authenticated user
 * PATCH /api/notifications/read — Mark specific or all notifications as read
 *
 * Flow (GET /):
 *   1. Auth: requireAuth + requireConnected
 *   2. Query user_notifications WHERE user_id=userId AND is_read=false
 *   3. Return { notifications: [...] }, capped at 50, ordered by created_at DESC
 *
 * Flow (PATCH /read):
 *   1. Auth: requireAuth + requireConnected
 *   2. Validate body: { notification_ids?: string[] }
 *   3. If notification_ids provided and non-empty: mark specific IDs read
 *   4. If notification_ids absent or empty: mark ALL unread as read
 *   5. Return { success: true }
 *
 * Auth: requireAuth + requireConnected
 * Requirements: NOTIF-03, NOTIF-04
 */

import { Router } from 'express';
import { z } from 'zod';
import { supabaseService } from '../lib/supabase.js';
import { requireAuth } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import { logger } from '../lib/logger.js';

const router = Router();

// ============================================================
// VALIDATION SCHEMAS
// ============================================================

const markReadSchema = z.object({
  notification_ids: z.array(z.string().uuid()).optional(),
});

// ============================================================
// GET / — Fetch unread notifications
// ============================================================

router.get('/', requireAuth, requireConnected, async (req: any, res: any) => {
  const userId = req.userId as string;

  try {
    const result = await supabaseService
      .schema('validation_quests')
      .from('user_notifications')
      .select('id, quest_id, payload, created_at, is_read')
      .eq('user_id', userId)
      .eq('is_read', false)
      .order('created_at', { ascending: false })
      .limit(50) as {
        data: Array<{
          id: string;
          quest_id: string;
          payload: unknown;
          created_at: string;
          is_read: boolean;
        }> | null;
        error: unknown;
      };

    if ((result as any).error) {
      logger.error('Failed to fetch notifications', {
        userId,
        error: String((result as any).error),
      });
      return res.status(500).json({ error: 'Failed to fetch notifications' });
    }

    return res.status(200).json({ notifications: result.data ?? [] });
  } catch (err) {
    logger.error('Unexpected error in GET /notifications', { userId, error: String(err) });
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================================
// PATCH /read — Mark notifications as read
// ============================================================

router.patch('/read', requireAuth, requireConnected, async (req: any, res: any) => {
  const userId = req.userId as string;

  const parseResult = markReadSchema.safeParse(req.body);
  if (!parseResult.success) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: parseResult.error.issues[0]?.message ?? 'Invalid request body',
      },
    });
  }

  const { notification_ids } = parseResult.data;

  try {
    if (notification_ids && notification_ids.length > 0) {
      // Mark specific notifications as read
      const updateResult = await supabaseService
        .schema('validation_quests')
        .from('user_notifications')
        .update({ is_read: true })
        .eq('user_id', userId)
        .in('id', notification_ids) as { error: unknown };

      if ((updateResult as any).error) {
        logger.error('Failed to mark notifications as read', {
          userId,
          notification_ids,
          error: String((updateResult as any).error),
        });
        return res.status(500).json({ error: 'Failed to mark notifications as read' });
      }
    } else {
      // Mark ALL unread notifications as read
      const updateResult = await supabaseService
        .schema('validation_quests')
        .from('user_notifications')
        .update({ is_read: true })
        .eq('user_id', userId)
        .eq('is_read', false) as { error: unknown };

      if ((updateResult as any).error) {
        logger.error('Failed to mark all notifications as read', {
          userId,
          error: String((updateResult as any).error),
        });
        return res.status(500).json({ error: 'Failed to mark notifications as read' });
      }
    }

    return res.status(200).json({ success: true });
  } catch (err) {
    logger.error('Unexpected error in PATCH /notifications/read', { userId, error: String(err) });
    return res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
