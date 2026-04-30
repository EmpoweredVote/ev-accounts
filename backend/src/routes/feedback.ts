import { Router } from 'express';
import type { Request, Response } from 'express';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';
import { submitFeedback } from '../lib/feedbackService.js';

const router = Router();

const FeedbackBody = z.object({
  body: z.string().min(1).max(5000),
  feature: z.enum(['compass', 'essentials', 'readrank', 'treasury', 'badges', 'trivia', 'landing', 'other']),
  email: z.string().email().optional().or(z.literal('')),
  url: z.string().url().optional().or(z.literal('')),
  // Honeypot — must be absent or empty
  website: z.string().max(0).optional(),
});

/**
 * Rate limit: 5 submissions per IP per hour.
 * Honeypot catches naive bots; rate limit catches everything else.
 * Keyed on IP since this endpoint is unauthenticated.
 */
const feedbackLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5,
  keyGenerator: (req) => req.ip ?? 'unknown',
  message: { code: 'RATE_LIMIT_EXCEEDED', message: 'Too many submissions. Please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// POST /api/feedback
// Auth: none (public endpoint — spam protection via honeypot + IP rate limit)
// CORS: inherits global CORS policy. Ensure ev-landing.empowered.vote is in CORS_ORIGIN.
router.post('/', feedbackLimiter, async (req: Request, res: Response): Promise<void> => {
  const parsed = FeedbackBody.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ code: 'VALIDATION_ERROR', errors: parsed.error.flatten().fieldErrors });
    return;
  }

  const data = parsed.data;

  // Honeypot check — filled = bot, return silent 200 (don't tip them off)
  if (data.website && data.website.length > 0) {
    res.status(200).json({ ok: true });
    return;
  }

  const ip = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ?? req.ip;

  await submitFeedback({
    body: data.body,
    feature: data.feature,
    email: data.email || undefined,
    url: data.url || undefined,
    ip,
    timestamp: new Date().toISOString(),
  });

  res.status(201).json({ ok: true });
});

export default router;
