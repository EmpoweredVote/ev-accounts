import { jwtVerify, createRemoteJWKSet, type JWTPayload } from 'jose';
import { Request, Response, NextFunction } from 'express';
import { env } from '../lib/env.js';
import { pool } from '../lib/db.js';
import { isTokenRevoked } from '../lib/authService.js';
import {
  SUPABASE_ISSUER,
  WORKOS_ISSUER,
  WORKOS_JWKS_URL,
  classifyToken,
  resolveInternalUserId,
} from '../lib/tokenIdentity.js';

// Projects created before May 2025 use HS256 (symmetric key).
// Projects created after May 2025 use ES256 (asymmetric, JWKS).
// SUPABASE_JWT_SECRET is set → use symmetric HS256 verification.
// Otherwise fall back to JWKS for ES256/RS256.
const SECRET_KEY = env.SUPABASE_JWT_SECRET
  ? new TextEncoder().encode(env.SUPABASE_JWT_SECRET)
  : null;
const SUPABASE_JWKS = SECRET_KEY
  ? null
  : createRemoteJWKSet(new URL(`${env.SUPABASE_URL}/auth/v1/.well-known/jwks.json`));

// Second accepted issuer during the Supabase → WorkOS migration window
// (decision 0002). Absent WORKOS_CLIENT_ID = WorkOS tokens are rejected.
const WORKOS_JWKS = WORKOS_JWKS_URL ? createRemoteJWKSet(new URL(WORKOS_JWKS_URL)) : null;

async function verifySupabaseJwt(token: string) {
  const options = { issuer: SUPABASE_ISSUER, audience: 'authenticated' };
  if (SECRET_KEY) return jwtVerify(token, SECRET_KEY, options);
  return jwtVerify(token, SUPABASE_JWKS!, options);
}

async function verifyWorkosJwt(token: string) {
  // WorkOS access tokens carry no aud claim. The dashboard JWT template must
  // set "role": "authenticated" (Supabase third-party auth contract) — its
  // absence means the template is not applied, so reject.
  const result = await jwtVerify(token, WORKOS_JWKS!, { issuer: WORKOS_ISSUER! });
  if (result.payload.role !== 'authenticated') {
    throw new Error('WorkOS token missing role=authenticated (JWT template not applied)');
  }
  return result;
}

/**
 * verifyWorkosAccessToken — verifies a WorkOS token WITHOUT requiring it to
 * resolve to an internal user id. Only the provisioning endpoint may use this:
 * a fresh AuthKit signup has no external_id claim yet, which is precisely the
 * state provisioning exists to fix. Everything else goes through requireAuth.
 * Returns the verified payload, or null.
 */
export async function verifyWorkosAccessToken(token: string): Promise<JWTPayload | null> {
  if (classifyToken(token) !== 'workos' || WORKOS_JWKS === null) return null;
  try {
    const { payload } = await verifyWorkosJwt(token);
    return payload;
  } catch {
    return null;
  }
}

/**
 * verifyAccessToken — accepts a token from either issuer during the migration
 * window and resolves the internal user id via tokenIdentity (the one place
 * allowed to interpret token subjects). Returns null for anything invalid.
 */
async function verifyAccessToken(
  token: string
): Promise<{ payload: JWTPayload; userId: string } | null> {
  const issuer = classifyToken(token);
  if (issuer === null) return null;
  if (issuer === 'workos' && WORKOS_JWKS === null) return null;
  try {
    const { payload } =
      issuer === 'supabase' ? await verifySupabaseJwt(token) : await verifyWorkosJwt(token);
    const userId = resolveInternalUserId(issuer, payload);
    if (userId === null) return null;
    return { payload, userId };
  } catch {
    return null;
  }
}

export interface AuthenticatedRequest extends Request {
  userId: string;
  accessToken: string;
  tokenIat: number; // issued-at (Unix seconds) — used for logout revocation check
  tokenExp: number; // expiry (Unix seconds) — used to set revocation TTL on logout
}

export async function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing authorization header' });
    return;
  }

  const token = authHeader.slice(7);

  const verified = await verifyAccessToken(token);
  if (!verified) {
    res.status(401).json({ error: 'Invalid or expired token' });
    return;
  }
  const { payload, userId } = verified;

  const tokenIat = typeof payload.iat === 'number' ? payload.iat : 0;
  const tokenExp = typeof payload.exp === 'number' ? payload.exp : 0;

  // Revocation check — rejects tokens issued before the user's last logout.
  // Closes the ~1h window where a signed-out JWT remains cryptographically valid.
  if (await isTokenRevoked(userId, tokenIat)) {
    res.status(401).json({ error: 'Token has been revoked' });
    return;
  }

  // Account check — enforces deletion and suspension within the JWT validity
  // window, i.e. for up to an hour after either happens.
  //
  // One query, not two. This runs on every authenticated request, so the account
  // state and the standing come back together rather than costing a second round
  // trip. pool.query rather than PostgREST because it spans two schemas; it is a
  // trusted server-side check, not a user-facing data read.
  const { rows } = await pool.query<{
    user_deleted_at: Date | null;
    account_standing: string | null;
  }>(
    `SELECT u.deleted_at AS user_deleted_at, cp.account_standing
       FROM public.users u
       LEFT JOIN connect.connected_profiles cp ON cp.user_id = u.id
      WHERE u.id = $1`,
    [userId]
  );
  const account = rows[0];

  // 🔴 A DELETED ACCOUNT MUST NOT AUTHENTICATE. This is the check that makes
  // deletion mean something: without it, a valid JWT issued before the deletion
  // kept working, and each tier guard was left to re-litigate the question from
  // the profile row — which is how a soft-deleted user could hold on to Connected
  // access (fixed at the guard level in #231) and, once that was closed, still
  // reach Inform-tier routes because their profile no longer "existed".
  //
  // Refusing at the door settles it for every route at once: deleted is deleted.
  //
  // No row at all means the user was HARD-deleted while holding a live token.
  // Same answer, and it must stay 401 rather than falling through as an
  // Inform-tier user, which is exactly what the previous PostgREST read did.
  if (!account || account.user_deleted_at !== null) {
    res.status(401).json({ error: 'Account no longer exists' });
    return;
  }

  // Suspension. account_standing is NULL for an Inform-tier user (no
  // connected_profiles row via the LEFT JOIN) — absence is not suspension, so
  // only a present-and-non-active standing refuses.
  //
  // ⚠ DELIBERATELY IGNORES connected_profiles.deleted_at, unlike the tier guards.
  // This clause REFUSES, so ignoring the column fails closed: a suspension
  // survives even if the profile row is soft-deleted. Honouring it here would
  // turn soft-delete into a way to lift a suspension.
  if (account.account_standing !== null && account.account_standing !== 'active') {
    res.status(403).json({ error: 'Account suspended' });
    return;
  }

  (req as AuthenticatedRequest).userId = userId;
  (req as AuthenticatedRequest).accessToken = token;
  (req as AuthenticatedRequest).tokenIat = tokenIat;
  (req as AuthenticatedRequest).tokenExp = tokenExp;
  next();
}

/**
 * Optional auth middleware — attaches user identity if a valid JWT is present,
 * but does NOT reject the request if no token or an invalid token is provided.
 * Used for routes that serve both authenticated and unauthenticated users
 * (e.g., GET /api/compass/topics supports guest compass usage).
 *
 * Design note: optionalAuth does NOT perform a standing check. Standing checks
 * are unnecessary for unauthenticated-compatible routes. If the user is
 * authenticated but suspended, they can still view public reference data
 * (topics, politicians). Standing enforcement only applies to routes that
 * write or read personal data — those routes use requireAuth.
 */
export async function optionalAuth(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    next(); // No token — proceed as unauthenticated
    return;
  }

  const token = authHeader.slice(7);

  // Invalid token — proceed as unauthenticated (do NOT return 401)
  const verified = await verifyAccessToken(token);
  if (verified) {
    (req as AuthenticatedRequest).userId = verified.userId;
    (req as AuthenticatedRequest).accessToken = token;
  }

  next();
}
