import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';
import { signUpWithEmail, signInWithEmail, signOutUser } from '../lib/authService.js';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { supabaseAdmin } from '../lib/supabase.js';
import type { Request, Response } from 'express';

const router = Router();

/**
 * Rate limiter for auth endpoints.
 * 10 attempts per 15-minute window per IP.
 * Applied to signup and login only — logout is authenticated and already
 * rate-limited by JWT overhead.
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // 10 attempts per window per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { code: 'RATE_LIMIT_EXCEEDED', message: 'Too many requests, please try again later' },
});

/**
 * Zod schema for auth request body.
 * Used for both signup and login — same fields, same validation.
 */
const authBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

/**
 * POST /api/auth/signup
 *
 * Creates a new Supabase auth user. When email confirmation is enabled
 * (the Supabase default), data.session will be null — this is success,
 * not failure. We check data.user for success, not data.session.
 *
 * A trigger in Phase 1 automatically creates the public.users record
 * when a new auth user is created.
 */
router.post('/signup', authLimiter, async (req: Request, res: Response): Promise<void> => {
  const parsed = authBodySchema.safeParse(req.body);
  if (!parsed.success) {
    const firstIssue = parsed.error.issues[0];
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: firstIssue?.message ?? 'Invalid request body',
    });
    return;
  }

  const { email, password } = parsed.data;
  const { data, error } = await signUpWithEmail(email, password);

  if (error) {
    // Email already registered
    if (
      error.code === 'email_exists' ||
      (error.message && error.message.toLowerCase().includes('already registered'))
    ) {
      res.status(409).json({
        code: 'EMAIL_EXISTS',
        message: 'An account with this email already exists',
      });
      return;
    }

    // Password too weak (Supabase policy)
    if (error.code === 'weak_password') {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: 'Password is too weak',
      });
      return;
    }

    console.error('[auth/signup] Supabase error:', error.code, error.message);
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    });
    return;
  }

  // data.user must exist for success. data.session may be null when email
  // confirmation is enabled — that is expected and not an error.
  if (!data.user) {
    console.error('[auth/signup] No user returned and no error — unexpected Supabase response');
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    });
    return;
  }

  res.status(201).json({
    id: data.user.id,
    message: 'Check your email to confirm your account',
  });
});

/**
 * POST /api/auth/login
 *
 * Authenticates with email and password. Returns access_token, refresh_token,
 * and a minimal profile stub on success.
 *
 * The profile stub is always tier: 'inform' and account_standing: 'active'.
 * This is accurate for any freshly-authenticated user — the client should
 * call GET /api/account/me for authoritative tier and standing data.
 *
 * OWASP enumeration protection: both wrong email and wrong password return
 * the same INVALID_CREDENTIALS code with the same message. Never distinguish.
 */
router.post('/login', authLimiter, async (req: Request, res: Response): Promise<void> => {
  const parsed = authBodySchema.safeParse(req.body);
  if (!parsed.success) {
    const firstIssue = parsed.error.issues[0];
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: firstIssue?.message ?? 'Invalid request body',
    });
    return;
  }

  const { email, password } = parsed.data;
  const { data, error } = await signInWithEmail(email, password);

  if (error) {
    // Wrong credentials — do not distinguish email vs password (OWASP)
    if (error.code === 'invalid_credentials') {
      res.status(401).json({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
      });
      return;
    }

    // Unverified email
    if (error.code === 'email_not_confirmed') {
      res.status(403).json({
        code: 'EMAIL_NOT_VERIFIED',
        message: 'Please verify your email before logging in',
      });
      return;
    }

    console.error('[auth/login] Supabase error:', error.code, error.message);
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    });
    return;
  }

  if (!data.session || !data.user) {
    console.error('[auth/login] No session returned and no error — unexpected Supabase response');
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    });
    return;
  }

  res.status(200).json({
    access_token: data.session.access_token,
    refresh_token: data.session.refresh_token,
    expires_in: data.session.expires_in,
    expires_at: data.session.expires_at,
    token_type: 'bearer',
    user: {
      id: data.user.id,
      email: data.user.email,
      display_name: null,
      tier: 'inform',
      account_standing: 'active',
    },
  });
});

/**
 * POST /api/auth/logout
 *
 * Invalidates the session server-side using scope 'global', revoking all
 * active sessions across all devices. Requires a valid JWT (requireAuth).
 *
 * Always returns 200 even if the Supabase signOut call fails. The access
 * token has a short TTL and will expire naturally — a failed signOut is
 * not worth blocking the client over. Errors are logged for ops visibility.
 */
router.post(
  '/logout',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    const { accessToken } = req as AuthenticatedRequest;

    const { error } = await signOutUser(accessToken);

    if (error) {
      // Log but do not block — client's token will expire naturally
      console.error('[auth/logout] Supabase signOut error:', error.message);
    }

    res.status(200).json({ message: 'Logged out successfully' });
  }
);

/**
 * POST /api/auth/complete-onboarding
 *
 * Sets completed_onboarding = true on the user's connected_profiles row.
 * Requires a Connected profile to exist (user must have completed the Connect flow).
 * This is a one-way flag — once set to true, it cannot be unset via this endpoint.
 *
 * Returns 200 with { completed_onboarding: true } in both the success case
 * and the already-completed case (idempotent).
 * Returns 403 with NOT_CONNECTED if no connected_profiles row exists.
 */
router.post(
  '/complete-onboarding',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    const { userId } = req as AuthenticatedRequest;

    try {
      // Attempt to update — only updates rows where completed_onboarding is false
      const { data: updatedRows, error: updateError } = await supabaseAdmin
        .schema('connect')
        .from('connected_profiles')
        .update({ completed_onboarding: true, updated_at: new Date().toISOString() })
        .eq('user_id', userId)
        .eq('completed_onboarding', false)
        .select('id');

      if (updateError) {
        console.error('[auth/complete-onboarding] Update error:', updateError);
        res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
        return;
      }

      if (!updatedRows || updatedRows.length === 0) {
        // Either no connected_profiles row, or completed_onboarding is already true.
        // Check which case it is to give the correct response.
        const { data: profile, error: selectError } = await supabaseAdmin
          .schema('connect')
          .from('connected_profiles')
          .select('completed_onboarding')
          .eq('user_id', userId)
          .maybeSingle();

        if (selectError) {
          console.error('[auth/complete-onboarding] Select error:', selectError);
          res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
          return;
        }

        if (!profile) {
          // No connected_profiles row — user has not completed the Connect flow.
          res.status(403).json({
            code: 'NOT_CONNECTED',
            message: 'Complete the Connect flow first',
          });
          return;
        }

        // completed_onboarding is already true — idempotent success.
        res.status(200).json({ completed_onboarding: true });
        return;
      }

      res.status(200).json({ completed_onboarding: true });
    } catch (err) {
      console.error('[auth/complete-onboarding] Unexpected error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

export default router;
