/**
 * notificationPreferences.ts
 * GET /api/notifications/preferences  — Get current notification preference
 * PATCH /api/notifications/preferences — Toggle notification preference on/off
 *
 * Flow (GET /):
 *   1. Auth: requireAuth + requireConnected
 *   2. Query user_notification_preferences WHERE user_id=userId
 *   3. If no row: return { enabled: false } (default off)
 *   4. If row: return { enabled: pref.enabled }
 *
 * Flow (PATCH /):
 *   1. Auth: requireAuth + requireConnected
 *   2. Validate body: { enabled: boolean }
 *   3. Upsert into user_notification_preferences (onConflict: 'user_id')
 *   4. Return { enabled: parsed.data.enabled }
 *
 * Auth: requireAuth + requireConnected
 * Requirements: NOTIF-02
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

const updatePreferenceSchema = z.object({
  enabled: z.boolean(),
});

// ============================================================
// GET / — Get current notification preference
// ============================================================

router.get('/', requireAuth, requireConnected, async (req: any, res: any) => {
  const userId = req.userId as string;

  try {
    const result = await supabaseService
      .schema('validation_quests')
      .from('user_notification_preferences')
      .select('enabled, updated_at')
      .eq('user_id', userId)
      .maybeSingle() as {
        data: { enabled: boolean; updated_at: string } | null;
        error: unknown;
      };

    if ((result as any).error) {
      logger.error('Failed to fetch notification preference', {
        userId,
        error: String((result as any).error),
      });
      return res.status(500).json({ error: 'Failed to fetch notification preference' });
    }

    // Default off — no row means notifications are disabled
    if (result.data == null) {
      return res.status(200).json({ enabled: false });
    }

    return res.status(200).json({ enabled: result.data.enabled });
  } catch (err) {
    logger.error('Unexpected error in GET /notifications/preferences', { userId, error: String(err) });
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================================
// PATCH / — Toggle notification preference
// ============================================================

router.patch('/', requireAuth, requireConnected, async (req: any, res: any) => {
  const userId = req.userId as string;

  const parseResult = updatePreferenceSchema.safeParse(req.body);
  if (!parseResult.success) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: parseResult.error.issues[0]?.message ?? 'Invalid request body',
      },
    });
  }

  const { enabled } = parseResult.data;

  try {
    const upsertResult = await supabaseService
      .schema('validation_quests')
      .from('user_notification_preferences')
      .upsert(
        { user_id: userId, enabled, updated_at: new Date().toISOString() },
        { onConflict: 'user_id' }
      ) as { error: unknown };

    if ((upsertResult as any).error) {
      logger.error('Failed to update notification preference', {
        userId,
        enabled,
        error: String((upsertResult as any).error),
      });
      return res.status(500).json({ error: 'Failed to update notification preference' });
    }

    return res.status(200).json({ enabled });
  } catch (err) {
    logger.error('Unexpected error in PATCH /notifications/preferences', { userId, error: String(err) });
    return res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
