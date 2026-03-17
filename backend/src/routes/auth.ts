import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';
import { signUpWithEmail, signInWithEmail, signOutUser, recordLogout } from '../lib/authService.js';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { completeOnboarding } from '../lib/enrollService.js';
import { adminRpc, supabaseAdmin } from '../lib/supabase.js';
import { insertAccessRequest } from '../lib/adminService.js';
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
 * Used for login — email + password only.
 */
const authBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

/**
 * Zod schema for signup request body.
 * Extends authBodySchema with:
 *   - optional guest_state: migrate anonymous compass usage into the new account.
 *   - optional legal_name + invite_code (Phase 24): when both are provided,
 *     the signup_with_invite RPC atomically creates a Connected profile.
 *     invite_code without legal_name returns 422 (validated below).
 * Migration and invite failures are handled independently — see handler below.
 */
const signUpBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  legal_name: z.string().min(1).max(200).optional(),
  invite_code: z.string().min(9).max(9).optional(),
  guest_state: z.object({
    answers: z.array(z.object({
      topic_id: z.string().uuid(),
      value: z.number().multipleOf(0.5).min(0.5).max(5.5),
      write_in_text: z.string().max(500).optional(),
    })).optional().default([]),
    selected_topics: z.array(z.string().uuid()).optional().default([]),
  }).optional(),
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
  const parsed = signUpBodySchema.safeParse(req.body);
  if (!parsed.success) {
    const firstIssue = parsed.error.issues[0];
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: firstIssue?.message ?? 'Invalid request body',
    });
    return;
  }

  const { email, password, guest_state, legal_name, invite_code } = parsed.data;

  // Phase 24: Pre-validate invite code BEFORE creating the auth user.
  // If the code is absent or invalid, bail out early — this prevents orphaned
  // auth users that receive confirmation emails but have no connected_profiles.
  // Note: we only check, not claim. The atomic claim happens in signup_with_invite.
  // There is a small TOCTOU window between this check and the RPC claim, but
  // concurrent claims on the same code during alpha are negligible.
  if (invite_code && legal_name) {
    const normalizedCode = invite_code.toUpperCase().trim();
    const { data: codeRow } = await supabaseAdmin
      .schema('connect')
      .from('invite_codes')
      .select('id, is_claimed, expires_at')
      .eq('code', normalizedCode)
      .maybeSingle();

    if (
      !codeRow ||
      codeRow.is_claimed ||
      (codeRow.expires_at && new Date(codeRow.expires_at) < new Date())
    ) {
      res.status(422).json({
        code: 'INVALID_INVITE_CODE',
        message: 'Invalid or already claimed invite code',
      });
      return;
    }
  }

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

    // Supabase email send rate limit (free tier: ~3 confirmation emails/hour)
    if (error.code === 'over_email_send_rate_limit') {
      res.status(429).json({
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Too many requests, please try again later',
      });
      return;
    }

    // SMTP misconfiguration or delivery failure — surface as 503 so the client
    // knows to retry later rather than treating it as a permanent failure.
    if (error.code === 'unexpected_failure' && error.message?.includes('confirmation email')) {
      console.error('[auth/signup] SMTP delivery failure — check SMTP configuration');
      res.status(503).json({
        code: 'EMAIL_DELIVERY_FAILED',
        message: 'Unable to send confirmation email. Please try again later.',
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

  // Phase 24: If invite_code provided without legal_name, return 422 immediately.
  // Both fields are required together — invite_code alone cannot create a Connected profile.
  if (invite_code && !legal_name) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: 'legal_name is required when invite_code is provided',
    });
    return;
  }

  // Phase 24: If both invite_code and legal_name are provided, create Connected profile atomically.
  // Runs BEFORE guest_state migration — invite profile creation is the higher-priority operation.
  // On RPC error: specific errors (INVALID_OR_CLAIMED_CODE, SELF_INVITE_BLOCKED) surface to client.
  // Unknown RPC errors are logged but do not fail the response — auth user was already created.
  if (invite_code && legal_name) {
    try {
      const { data: rpcResult, error: rpcError } = await adminRpc(
        'signup_with_invite',
        {
          p_user_id: data.user.id,
          p_legal_name: legal_name,
          p_invite_code: invite_code,
        },
        'connect'
      );

      if (rpcError) {
        console.error('[auth/signup] signup_with_invite RPC error:', rpcError.message);

        if (rpcError.message.includes('INVALID_OR_CLAIMED_CODE')) {
          res.status(422).json({
            code: 'INVALID_INVITE_CODE',
            message: 'Invalid or already claimed invite code',
          });
          return;
        }
        if (rpcError.message.includes('SELF_INVITE_BLOCKED')) {
          res.status(422).json({
            code: 'SELF_INVITE_BLOCKED',
            message: 'Cannot use your own invite code',
          });
          return;
        }
        // Unknown RPC error — still return 201 since auth user was created.
        // User can claim an invite through the Connect flow later.
      } else {
        // Log successful invite claim for ops visibility
        const result = rpcResult as { ok: boolean; inviter_id: string | null } | null;
        console.info('[auth/signup] Connected profile created via invite. inviter_id:', result?.inviter_id ?? 'admin-code');
      }
    } catch (err) {
      console.error('[auth/signup] signup_with_invite unexpected error:', err);
      // Non-fatal: auth user was created; Connected profile can be set up later.
    }
  }

  // Migrate guest compass state if provided.
  // Non-fatal: migration errors are logged but never fail the signup response.
  // p_selected_topics is null when absent/empty so the RPC's null guard skips the UPDATE.
  if (guest_state) {
    try {
      await adminRpc('migrate_guest_compass_state', {
        p_user_id: data.user.id,
        p_answers: guest_state.answers ?? [],
        p_selected_topics: guest_state.selected_topics?.length ? guest_state.selected_topics : null,
      });
    } catch (migrationErr) {
      console.error('[auth/signup] Guest state migration failed:', migrationErr);
    }
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
    const { userId, accessToken, tokenExp } = req as AuthenticatedRequest;

    const { error } = await signOutUser(accessToken);

    if (error) {
      // Log but do not block — revocation record below still covers the token
      console.error('[auth/logout] Supabase signOut error:', error.message);
    }

    // Record logout time so requireAuth can reject this token immediately,
    // even before its cryptographic expiry (~1h window closed).
    await recordLogout(userId, tokenExp);

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
      const result = await completeOnboarding(userId);

      if (result === 'not_connected') {
        res.status(403).json({
          code: 'NOT_CONNECTED',
          message: 'Complete the Connect flow first',
        });
        return;
      }

      res.status(200).json({ completed_onboarding: true });
    } catch (err) {
      console.error('[auth/complete-onboarding] Unexpected error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

/**
 * POST /api/auth/request-access
 *
 * Captures email from users who don't have an invite code.
 * Stores in public.access_requests for admin review.
 * No authentication required — intentionally public.
 *
 * Architecture: insertAccessRequest helper in adminService.ts owns the
 * service-role write (architecture test: no admin client in routes/).
 */
const requestAccessSchema = z.object({
  email: z.string().email(),
});

router.post('/request-access', authLimiter, async (req: Request, res: Response): Promise<void> => {
  const parsed = requestAccessSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: parsed.error.issues[0]?.message ?? 'Invalid email',
    });
    return;
  }

  try {
    await insertAccessRequest(parsed.data.email);
    res.status(201).json({ message: 'Access request submitted' });
  } catch (err) {
    console.error('[auth/request-access] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
