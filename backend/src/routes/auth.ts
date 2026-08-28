import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';
import { signUpWithEmail, signInWithEmail, signOutUser, recordLogout } from '../lib/authService.js';
import { requireAuth, verifyWorkosAccessToken, type AuthenticatedRequest } from '../middleware/auth.js';
import { classifyToken } from '../lib/tokenIdentity.js';
import { provisionWorkosUser, signUpWorkosFirst } from '../lib/workosProvisionService.js';
import { completeOnboarding } from '../lib/enrollService.js';
import { adminRpc, supabaseAdmin } from '../lib/supabase.js';
import { insertAccessRequest } from '../lib/adminService.js';
import { sendEmail } from '../lib/emailService.js';
import { pool } from '../lib/db.js';
import type { Request, Response, NextFunction } from 'express';
import { env } from '../lib/env.js';

const router = Router();

/** Shared cookie options — used for both set and clear to ensure domain/path match */
function evSessionCookieOptions() {
  return {
    httpOnly: true,
    secure: env.NODE_ENV === 'production',
    sameSite: 'lax' as const,
    domain: env.COOKIE_DOMAIN ? env.COOKIE_DOMAIN : undefined,
    path: '/',
  };
}

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
  display_name: z.string().min(1).max(100),
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
 * Two credential paths, selected by env.AUTHKIT_PRIMARY (decision 0002):
 *
 * - 'false' (default): creates a Supabase auth user holding the password. When
 *   email confirmation is enabled (the Supabase default), data.session will be
 *   null — this is success, not failure. We check data.user, not data.session.
 *
 * - 'true' (post-cutover): the password goes to WorkOS and the internal
 *   auth.users row is created WITHOUT one, so new accounts never hold a
 *   Supabase credential. AuthKit owns email verification, so no confirmation
 *   mail is sent from here and the success message changes accordingly.
 *
 * Everything after the branch is identical: display_name, the invite-code
 * Connected path, and guest-state migration all key off the resolved `userId`.
 * That is why the invite flow survives the cutover — AuthKit's hosted sign-up
 * cannot collect an invite code, so this endpoint stays the Connected path.
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

  const { email, password, display_name, guest_state, legal_name, invite_code } = parsed.data;

  // Phase 24: Pre-validate invite code BEFORE creating the auth user.
  // If the code is absent or invalid, bail out early — this prevents orphaned
  // auth users that receive confirmation emails but have no connected_profiles.
  // Note: we only check, not claim. The atomic claim happens in signup_with_invite.
  // There is a small TOCTOU window between this check and the RPC claim, but
  // concurrent claims on the same code during alpha are negligible.
  if (invite_code && legal_name) {
    const normalizedCode = invite_code.toUpperCase().trim();
    const { rows } = await pool.query<{ is_claimed: boolean; expires_at: string | null }>(
      `SELECT is_claimed, expires_at FROM connect.invite_codes WHERE code = $1`,
      [normalizedCode]
    );
    const codeRow = rows[0];

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

  // Where the new credential is created is the cutover switch. AUTHKIT_PRIMARY
  // moves it to WorkOS and leaves the internal row passwordless; until then the
  // Supabase path below is unchanged. Both branches converge on `userId`.
  let userId: string;
  let signupMessage = 'Check your email to confirm your account';

  if (env.AUTHKIT_PRIMARY === 'true') {
    const result = await signUpWorkosFirst(email, password);
    if (!result.ok) {
      const failures = {
        NOT_CONFIGURED: [503, 'NOT_CONFIGURED', 'Signup is temporarily unavailable'],
        EMAIL_EXISTS: [409, 'EMAIL_EXISTS', 'An account with this email already exists'],
        WEAK_PASSWORD: [422, 'VALIDATION_ERROR', 'Password is too weak'],
        WORKOS_ERROR: [502, 'INTERNAL_ERROR', 'An unexpected error occurred'],
        INTERNAL_ERROR: [500, 'INTERNAL_ERROR', 'An unexpected error occurred'],
      } as const;
      const [status, code, message] = failures[result.code];
      res.status(status).json({ code, message });
      return;
    }
    userId = result.userId;
    // signUpWorkosFirst sends a WorkOS verification email at this point, so the
    // user gets one immediately (like the old confirm-email flow). They enter
    // the code when they sign in through AuthKit.
    signupMessage = 'Account created — check your email to verify, then sign in';
  } else {
    const { data, error } = await signUpWithEmail(
      email,
      password,
      `${env.LOGIN_URL}/email-confirmed`,
    );

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

      // SMTP misconfiguration or delivery failure
      if (error.code === 'unexpected_failure') {
        console.error('[auth/signup] SMTP delivery failure:', error.message);
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

    // Supabase returns status 200 (no error) for repeated signups when email confirmation
    // is enabled — identities is an empty array in this case. Detect and surface as 409
    // so the frontend can direct the user to sign in or reset their password.
    if (!data.user.identities || data.user.identities.length === 0) {
      res.status(409).json({
        code: 'EMAIL_EXISTS',
        message: 'An account with this email already exists',
      });
      return;
    }
    userId = data.user.id;
  }

  // Phase 67: Inform signup path persists display_name onto public.users.
  // The on_auth_user_created trigger inserts public.users(id) with display_name = NULL.
  // The Connected path (below) writes display_name through signup_with_invite RPC, so
  // we ONLY do this UPDATE when no invite_code is present (Inform path).
  // Non-fatal: if the UPDATE fails, the user is already created — they can update
  // display_name from the profile page later. We log and continue.
  if (!invite_code) {
    try {
      await pool.query(
        `UPDATE public.users
           SET display_name = $2,
               updated_at = now()
         WHERE id = $1`,
        [userId, display_name]
      );
    } catch (updateErr) {
      console.error('[auth/signup] Failed to persist display_name for Inform user:', userId, updateErr);
      // Intentionally non-fatal — proceed to 201 below.
    }
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
          p_user_id: userId,
          p_legal_name: legal_name,
          p_invite_code: invite_code,
          p_display_name: display_name,
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
        p_user_id: userId,
        p_answers: guest_state.answers ?? [],
        p_selected_topics: guest_state.selected_topics?.length ? guest_state.selected_topics : null,
      });
    } catch (migrationErr) {
      console.error('[auth/signup] Guest state migration failed:', migrationErr);
    }
  }

  res.status(201).json({
    id: userId,
    message: signupMessage,
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

  // SSO: set shared session cookie with refresh token
  res.cookie('ev_session', data.session.refresh_token, {
    ...evSessionCookieOptions(),
    maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days in ms
  });

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
 * GET /api/auth/session
 *
 * SSO silent session check. Reads the ev_session httpOnly cookie,
 * exchanges the refresh token for fresh Supabase tokens, rotates the
 * cookie with the new refresh token, and returns the token pair.
 *
 * No rate limiter -- apps call this on every page load. The endpoint
 * does one Supabase refreshSession call and returns quickly.
 *
 * Returns 200 with { access_token, refresh_token } on success.
 * Returns 401 with no body if cookie is missing or token is invalid.
 */
router.get('/session', async (req: Request, res: Response): Promise<void> => {
  const refreshToken = req.cookies?.ev_session;
  if (!refreshToken) {
    res.status(401).end();
    return;
  }

  try {
    const { data, error } = await supabaseAdmin.auth.refreshSession({
      refresh_token: refreshToken,
    });

    if (error || !data.session) {
      // Cookie present but token invalid/expired/revoked -- clear the stale cookie
      res.clearCookie('ev_session', evSessionCookieOptions());
      res.status(401).end();
      return;
    }

    // CRITICAL: Supabase rotates refresh tokens on each use. The old token
    // is immediately invalidated. We MUST write the new refresh_token back
    // into the cookie or the next /session call will 401.
    res.cookie('ev_session', data.session.refresh_token, {
      ...evSessionCookieOptions(),
      maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days in ms
    });

    res.status(200).json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
    });
  } catch (err) {
    // refreshSession can throw (transient Supabase Auth error, or a malformed
    // cookie value) rather than returning { error }. Without this guard the
    // request became an unhandled 500 on the auth path; treat it like an
    // invalid session -- clear the stale cookie and return 401.
    console.error('[auth/session] refreshSession threw:', err);
    res.clearCookie('ev_session', evSessionCookieOptions());
    res.status(401).end();
  }
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
  // SSO: clear session cookie unconditionally BEFORE auth check.
  // If JWT is expired, requireAuth returns 401 but cookie is already cleared.
  (req: Request, res: Response, next: NextFunction) => {
    res.clearCookie('ev_session', evSessionCookieOptions());
    next();
  },
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    const { userId, accessToken, tokenExp } = req as AuthenticatedRequest;

    // Supabase-issued tokens get a server-side session revocation. WorkOS
    // sessions end client-side via the AuthKit SDK's signOut() — passing a
    // WorkOS token to Supabase would just log a spurious error here.
    if (classifyToken(accessToken) === 'supabase') {
      const { error } = await signOutUser(accessToken);

      if (error) {
        // Log but do not block — revocation record below still covers the token
        console.error('[auth/logout] Supabase signOut error:', error.message);
      }
    }

    // Record logout time so requireAuth can reject this token immediately,
    // even before its cryptographic expiry (~1h window closed).
    await recordLogout(userId, tokenExp);

    res.status(200).json({ message: 'Logged out successfully' });
  }
);

/**
 * POST /api/auth/workos/provision
 *
 * Migration transition (decision 0002): a user who signed UP through WorkOS
 * AuthKit has no external_id claim, so their token cannot resolve to an
 * internal user id and every authenticated call 401s. This endpoint accepts
 * that not-yet-linked token, verifies it against the WorkOS JWKS, and links
 * the account: find-or-create the internal user, write its UUID back to
 * WorkOS as external_id (see workosProvisionService). Idempotent — an
 * already-linked user gets their existing id back.
 *
 * The client MUST refresh its access token after a 200 — the external_id
 * claim only appears in tokens minted after the link.
 */
router.post('/workos/provision', authLimiter, async (req: Request, res: Response): Promise<void> => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ code: 'UNAUTHORIZED', message: 'Missing authorization header' });
    return;
  }

  const payload = await verifyWorkosAccessToken(authHeader.slice(7));
  if (!payload || typeof payload.sub !== 'string') {
    res.status(401).json({ code: 'UNAUTHORIZED', message: 'Invalid or expired token' });
    return;
  }

  try {
    const result = await provisionWorkosUser(payload.sub);
    if (!result.ok) {
      if (result.code === 'NOT_CONFIGURED') {
        res.status(503).json({ code: 'NOT_CONFIGURED', message: 'Account linking is not available' });
      } else if (result.code === 'EMAIL_UNVERIFIED') {
        res.status(403).json({ code: 'EMAIL_NOT_VERIFIED', message: 'Please verify your email before continuing' });
      } else {
        res.status(502).json({ code: 'PROVISION_FAILED', message: 'Account linking failed, please try again' });
      }
      return;
    }
    res.status(200).json({ user_id: result.userId, created: result.created });
  } catch (err) {
    console.error('[auth/workos/provision] unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

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

    // Fire-and-forget admin notification — sendEmail never throws
    const adminEmail = process.env.ADMIN_EMAIL;
    if (adminEmail) {
      sendEmail({
        to: adminEmail,
        subject: 'New Access Request — Empowered Vote',
        html: `<p>Someone just requested access to Empowered Vote.</p>
               <p><strong>Email:</strong> ${parsed.data.email}</p>
               <p><strong>Time:</strong> ${new Date().toISOString()}</p>
               <p>Review in the <a href="https://login.empowered.vote/admin/access-requests">admin panel</a>.</p>`,
      });
    }

    res.status(201).json({ message: 'Access request submitted' });
  } catch (err) {
    console.error('[auth/request-access] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

/**
 * POST /api/auth/forgot-password
 *
 * Sends a password reset email via Supabase. Always returns 200 regardless
 * of whether the email is registered — prevents user enumeration (OWASP).
 */
const forgotPasswordSchema = z.object({
  email: z.string().email(),
});

router.post('/forgot-password', authLimiter, async (req: Request, res: Response): Promise<void> => {
  const parsed = forgotPasswordSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Valid email required' });
    return;
  }

  try {
    await supabaseAdmin.auth.resetPasswordForEmail(parsed.data.email, {
      redirectTo: `${env.LOGIN_URL}/reset-password`,
    });
  } catch (err) {
    console.error('[auth/forgot-password] error:', err);
    // Never surface this — always 200 to prevent enumeration
  }

  res.status(200).json({ message: 'If that email is registered, a password reset link has been sent.' });
});

/**
 * POST /api/auth/reset-password
 *
 * Exchanges a Supabase recovery token_hash for a session, then updates
 * the user's password. The token_hash comes from the ?token_hash= param
 * in the reset email link.
 */
const resetPasswordSchema = z.object({
  token_hash: z.string().min(1),
  password: z.string().min(8),
});

router.post('/reset-password', authLimiter, async (req: Request, res: Response): Promise<void> => {
  const parsed = resetPasswordSchema.safeParse(req.body);
  if (!parsed.success) {
    const firstIssue = parsed.error.issues[0];
    res.status(422).json({ code: 'VALIDATION_ERROR', message: firstIssue?.message ?? 'Invalid request' });
    return;
  }

  const { token_hash, password } = parsed.data;

  const { data: verifyData, error: verifyError } = await supabaseAdmin.auth.verifyOtp({
    token_hash,
    type: 'recovery',
  });

  if (verifyError || !verifyData.user) {
    res.status(422).json({ code: 'INVALID_RESET_TOKEN', message: 'Reset link is invalid or has expired' });
    return;
  }

  const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(verifyData.user.id, { password });

  if (updateError) {
    if (updateError.code === 'weak_password') {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Password is too weak' });
      return;
    }
    console.error('[auth/reset-password] updateUserById error:', updateError.message);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    return;
  }

  res.status(200).json({ message: 'Password updated successfully' });
});

/**
 * POST /api/auth/resend-confirmation
 *
 * Resends the signup confirmation email. Always returns 200 regardless of
 * whether the email is registered or already confirmed (OWASP enumeration).
 */
const resendConfirmationSchema = z.object({
  email: z.string().email(),
});

router.post('/resend-confirmation', authLimiter, async (req: Request, res: Response): Promise<void> => {
  const parsed = resendConfirmationSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Valid email required' });
    return;
  }

  try {
    await supabaseAdmin.auth.resend({ type: 'signup', email: parsed.data.email });
  } catch (err) {
    console.error('[auth/resend-confirmation] error:', err);
    // Always 200 — never reveal account state
  }

  res.status(200).json({ message: 'Confirmation email resent' });
});

export default router;
