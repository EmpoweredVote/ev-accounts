import { Router, json } from 'express';
import type { Request, Response } from 'express';
import rateLimit, { ipKeyGenerator } from 'express-rate-limit';
import { createSharedRateLimitStore } from '../lib/rateLimitStore.js';
import { z } from 'zod';
import { submitFeedback, type FeedbackScreenshot } from '../lib/feedbackService.js';

const router = Router();

const ALLOWED_SCREENSHOT_MIME = ['image/png', 'image/jpeg', 'image/webp', 'image/gif'] as const;
const MAX_SCREENSHOT_BYTES = 5 * 1024 * 1024; // 5 MB raw

// Data URL regex: data:<mime>;base64,<payload>
const DATA_URL_RE = /^data:(image\/(?:png|jpeg|webp|gif));base64,([A-Za-z0-9+/]+=*)$/;

const FeedbackBody = z.object({
  body: z.string().min(1).max(5000),
  feature: z.enum(['compass', 'essentials', 'readrank', 'treasury', 'badges', 'trivia', 'landing', 'other']),
  email: z.string().email().optional().or(z.literal('')),
  url: z.string().url().optional().or(z.literal('')),
  // Honeypot — must be absent or empty
  website: z.string().max(0).optional(),
  // Optional screenshot as data URL (data:image/png;base64,…). Hard-capped client-side
  // to keep JSON payloads sane; backend re-validates size after decoding.
  screenshot: z.string().regex(DATA_URL_RE, 'screenshot must be a data:image/* URL').optional(),
});

/**
 * Rate limit: 5 submissions per IP per hour.
 * Honeypot catches naive bots; rate limit catches everything else.
 * Keyed on IP since this endpoint is unauthenticated.
 */
const feedbackRateLimitStore = createSharedRateLimitStore('feedback');
const feedbackLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5,
  keyGenerator: (req) => (req.ip ? ipKeyGenerator(req.ip) : 'unknown'),
  ...(feedbackRateLimitStore ? { store: feedbackRateLimitStore } : {}),
  message: { code: 'RATE_LIMIT_EXCEEDED', message: 'Too many submissions. Please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Local 8 MB JSON parser ONLY for this route. Most API endpoints use
 * the global parser (default 100 KB). Screenshots base64-inflate by ~33%,
 * so an 8 MB cap covers the 5 MB raw image limit with headroom.
 */
const localJson = json({ limit: '8mb' });

/**
 * Decode a base64 data URL to {buffer, contentType, filename}.
 * Returns null if the data URL is malformed or the decoded size is over the cap.
 */
function decodeScreenshot(dataUrl: string): FeedbackScreenshot | null {
  const match = dataUrl.match(DATA_URL_RE);
  if (!match) return null;

  const contentType = match[1];
  const base64 = match[2];
  const buffer = Buffer.from(base64, 'base64');

  if (buffer.length === 0 || buffer.length > MAX_SCREENSHOT_BYTES) return null;
  if (!(ALLOWED_SCREENSHOT_MIME as readonly string[]).includes(contentType)) return null;

  const ext = contentType.split('/')[1] === 'jpeg' ? 'jpg' : contentType.split('/')[1];
  const filename = `screenshot-${Date.now()}.${ext}`;

  return { buffer, contentType, filename };
}

// POST /api/feedback
// Auth: none (public endpoint — spam protection via honeypot + IP rate limit)
// CORS: inherits global CORS policy. Ensure feedback origins are in CORS_ORIGIN.
router.post('/', localJson, feedbackLimiter, async (req: Request, res: Response): Promise<void> => {
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

  // Decode optional screenshot. Reject 413 if too large; soft-skip if malformed.
  let screenshot: FeedbackScreenshot | undefined;
  if (data.screenshot) {
    const decoded = decodeScreenshot(data.screenshot);
    if (!decoded) {
      res.status(413).json({
        code: 'SCREENSHOT_INVALID',
        message: 'Screenshot must be a PNG/JPEG/WebP/GIF under 5 MB.',
      });
      return;
    }
    screenshot = decoded;
  }

  const ip = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ?? req.ip;

  await submitFeedback({
    body: data.body,
    feature: data.feature,
    email: data.email || undefined,
    url: data.url || undefined,
    ip,
    timestamp: new Date().toISOString(),
    screenshot,
  });

  res.status(201).json({ ok: true });
});

export default router;
