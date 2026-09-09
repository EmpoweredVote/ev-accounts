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

// Supabase issues asymmetric (ES256/RS256) JWTs; verify via JWKS (public-key
// rotation safe). The legacy symmetric HS256 / SUPABASE_JWT_SECRET path was
// removed: it verified EXCLUSIVELY when the secret was set, so a stray env var
// could silently disable JWKS and reject every current token. JWKS is now the
// only Supabase verification path (mirrors vq/middleware/auth.ts).
const SUPABASE_JWKS = createRemoteJWKSet(
  new URL(`${env.SUPABASE_URL}/auth/v1/.well-known/jwks.json`)
);

// Second accepted issuer during the Supabase → WorkOS migration window
// (decision 0002). Absent WORKOS_CLIENT_ID = WorkOS tokens are rejected.
const WORKOS_JWKS = WORKOS_JWKS_URL ? createRemoteJWKSet(new URL(WORKOS_JWKS_URL)) : null;

async function verifySupabaseJwt(token: string) {
  return jwtVerify(token, SUPABASE_JWKS, {
    issuer: SUPABASE_ISSUER,
    audience: 'authenticated',
  });
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

// ---------------------------------------------------------------------------
// Account state
// ---------------------------------------------------------------------------

interface AccountState {
  deleted: boolean;
  /** NULL for an Inform-tier user — no connected_profiles row via the LEFT JOIN. */
  standing: string | null;
}

/**
 * Process-local memo for the account lookup.
 *
 * WHY CACHE AT ALL. optionalAuth guards the busiest routes in the product (every
 * compass read and write) and used to do NO network I/O whatsoever. Giving it a
 * database round trip per request to catch a rare admin action would be paying a
 * lot, constantly, for something that almost never happens.
 *
 * WHY 30 SECONDS IS ENOUGH. The alternative is not "instant" — it is the status
 * quo, where a deleted user is accepted until their JWT expires: about an hour on
 * requireAuth routes, and until expiry on optionalAuth ones because nothing
 * checked at all. 30s is a ~120x improvement, and deletion/suspension are
 * deliberate admin actions rather than things a user triggers.
 *
 * 🔴 BOUNDED ON PURPOSE. cache.ts documents a resource-exhaustion P1 on
 * 2026-07-22 caused by an unbounded process-local Map on this very dyno. userId
 * is high-cardinality by definition, so this one gets a hard cap and drops the
 * whole map when it hits it — crude, but a memo cache losing its contents costs
 * one query per user, and that is the correct thing to be cheap about.
 *
 * ⚠ REVOCATION IS DELIBERATELY NOT CACHED. Logout must take effect immediately;
 * a window where a signed-out token still works is a real weakening. isTokenRevoked
 * stays a live read on both paths.
 */
const ACCOUNT_TTL_MS = 30_000;
const MAX_ACCOUNT_ENTRIES = 5_000;
const accountCache = new Map<string, { state: AccountState | null; expiresAt: number }>();

/** Exported for tests — lets a case start from a known-cold cache. */
export function __clearAccountCache(): void {
  accountCache.clear();
}

/**
 * The user's account state, or null when there is no public.users row at all
 * (hard-deleted while holding a live token).
 *
 * One query, not two: deletion state and standing come back together rather than
 * costing separate round trips on a path that runs for every request.
 * pool.query rather than PostgREST because it spans two schemas; it is a trusted
 * server-side check, not a user-facing data read.
 */
async function loadAccountState(userId: string): Promise<AccountState | null> {
  const hit = accountCache.get(userId);
  if (hit && hit.expiresAt > Date.now()) return hit.state;

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

  const row = rows[0];
  const state: AccountState | null = row
    ? { deleted: row.user_deleted_at !== null, standing: row.account_standing }
    : null;

  if (accountCache.size >= MAX_ACCOUNT_ENTRIES) accountCache.clear();
  accountCache.set(userId, { state, expiresAt: Date.now() + ACCOUNT_TTL_MS });
  return state;
}

/** True when this account may act at all. Absence of a profile is Inform tier, not a fault. */
function accountIsUsable(state: AccountState | null): boolean {
  if (!state || state.deleted) return false;
  return state.standing === null || state.standing === 'active';
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
  // window, i.e. for up to an hour after either happens. Memoized; see
  // loadAccountState.
  const account = await loadAccountState(userId);

  // 🔴 A DELETED ACCOUNT MUST NOT AUTHENTICATE. This is the check that makes
  // deletion mean something: without it, a valid JWT issued before the deletion
  // kept working, and each tier guard was left to re-litigate the question from
  // the profile row — which is how a soft-deleted user could hold on to Connected
  // access (fixed at the guard level in #231) and, once that was closed, still
  // reach Inform-tier routes because their profile no longer "existed".
  //
  // No row at all means the user was HARD-deleted while holding a live token.
  // Same answer, and it must stay 401 rather than falling through as an
  // Inform-tier user.
  if (!account || account.deleted) {
    res.status(401).json({ error: 'Account no longer exists' });
    return;
  }

  // Suspension. account_standing is NULL for an Inform-tier user (no
  // connected_profiles row via the LEFT JOIN) — absence is not suspension.
  //
  // ⚠ DELIBERATELY IGNORES connected_profiles.deleted_at, unlike the tier guards.
  // This clause REFUSES, so ignoring the column fails closed: a suspension
  // survives even if the profile row is soft-deleted. Honouring it here would
  // turn soft-delete into a way to lift a suspension.
  if (account.standing !== null && account.standing !== 'active') {
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
  if (!verified) {
    next();
    return;
  }

  // 🔴 A VALID SIGNATURE IS NOT A USABLE ACCOUNT, AND THIS USED TO STOP AT THE
  // SIGNATURE. optionalAuth decoded the token, set userId and called next() — no
  // deletion check, no suspension check, not even the revocation check that
  // requireAuth does. That is most of the compass: GET/POST /answers,
  // /answers/batch, /selected-topics both ways, /my-lenses both ways. A deleted,
  // suspended or signed-OUT user kept full read and write access to their compass
  // until the JWT expired, because nothing ever asked.
  //
  // Confirmed against production on 2026-08-30: with the account soft-deleted,
  // requireAuth routes correctly answered 401 while /compass/answers and
  // /compass/my-lenses both still answered 200.
  //
  // ⚠ THE FAILURE MODE IS "GUEST", NOT 401. That is what optional auth means: we
  // take credentials when they are good and ignore them when they are not. These
  // routes already handle an unauthenticated caller — they return [] and touch no
  // database — so dropping to guest degrades cleanly instead of breaking a page.
  if (await isTokenRevoked(verified.userId, typeof verified.payload.iat === 'number' ? verified.payload.iat : 0)) {
    next();
    return;
  }

  if (!accountIsUsable(await loadAccountState(verified.userId))) {
    next();
    return;
  }

  (req as AuthenticatedRequest).userId = verified.userId;
  (req as AuthenticatedRequest).accessToken = token;

  next();
}
