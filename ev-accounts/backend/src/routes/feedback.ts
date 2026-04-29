import { Router } from 'express';
import type { Request, Response } from 'express';
import { z } from 'zod';
import { env } from '../lib/env.js';
import { submitFeedback } from '../lib/feedbackService.js';

const router = Router();

const FeedbackBody = z.object({
  body: z.string().min(1).max(5000),
  feature: z.enum(['compass', 'essentials', 'readrank', 'treasury', 'badges', 'trivia', 'landing', 'other']),
  email: z.string().email().optional().or(z.literal('')),
  url: z.string().url().optional().or(z.literal('')),
  // Honeypot — must be absent or empty
  website: z.string().max(0).optional(),
  // Cloudflare Turnstile token
  'cf-turnstile-response': z.string().min(1),
});

async function verifyTurnstile(token: string, remoteip?: string): Promise<boolean> {
  const { TURNSTILE_SECRET_KEY } = env;
  if (!TURNSTILE_SECRET_KEY) {
    // In dev/test without the key set, skip verification
    console.warn('[feedback] TURNSTILE_SECRET_KEY not set — skipping Turnstile verification');
    return true;
  }

  const body = new URLSearchParams({
    secret: TURNSTILE_SECRET_KEY,
    response: token,
    ...(remoteip ? { remoteip } : {}),
  });

  const res = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
    method: 'POST',
    body,
  });

  const data = (await res.json()) as { success: boolean };
  return data.success === true;
}

// POST /api/feedback
// Auth: none (public endpoint — spam protection via Turnstile + honeypot)
// CORS: inherits global CORS policy (*.empowered.vote origins allowed)
// Note: ensure ev-landing.empowered.vote is included in the CORS_ORIGIN Render env var.
router.post('/', async (req: Request, res: Response): Promise<void> => {
  const parsed = FeedbackBody.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ code: 'VALIDATION_ERROR', errors: parsed.error.flatten().fieldErrors });
    return;
  }

  const data = parsed.data;

  // Honeypot check — filled = bot, return silent 200
  if (data.website && data.website.length > 0) {
    res.status(200).json({ ok: true });
    return;
  }

  // Turnstile verification
  const ip = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim();
  const turnstileValid = await verifyTurnstile(data['cf-turnstile-response'], ip);
  if (!turnstileValid) {
    res.status(400).json({ code: 'TURNSTILE_INVALID', message: 'Spam check failed. Please try again.' });
    return;
  }

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
