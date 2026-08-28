import { Router } from 'express';
import type { Request, Response } from 'express';
import rateLimit, { ipKeyGenerator } from 'express-rate-limit';
import { z } from 'zod';
import { pool } from '../lib/db.js';
import { optionalAuth, type AuthenticatedRequest } from '../middleware/auth.js';

const router = Router();

const KNOWN_EVENTS = ['connect_account_cta_click'] as const;

const TrackBody = z.object({
  event: z.enum(KNOWN_EVENTS),
});

const trackLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  keyGenerator: (req) =>
    (req as AuthenticatedRequest).userId ?? (req.ip ? ipKeyGenerator(req.ip) : 'unknown'),
  standardHeaders: true,
  legacyHeaders: false,
});

// POST /api/events/track
// Auth: optional — user_id recorded when authenticated, null otherwise.
router.post('/track', optionalAuth, trackLimiter, async (req: Request, res: Response): Promise<void> => {
  const parsed = TrackBody.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ code: 'VALIDATION_ERROR' });
    return;
  }
  const userId = (req as AuthenticatedRequest).userId ?? null;
  try {
    await pool.query(
      'INSERT INTO public.cta_events (event_name, user_id) VALUES ($1, $2)',
      [parsed.data.event, userId],
    );
  } catch {
    // Tracking failure must never surface to the user — swallow silently.
  }
  res.status(201).json({ ok: true });
});

export default router;
