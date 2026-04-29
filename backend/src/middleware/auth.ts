import { jwtVerify, createRemoteJWKSet } from 'jose';
import { Request, Response, NextFunction } from 'express';
import { env } from '../lib/env.js';
import { supabaseAdmin } from '../lib/supabase.js';
import { isTokenRevoked } from '../lib/authService.js';

// Projects created before May 2025 use HS256 (symmetric key).
// Projects created after May 2025 use ES256 (asymmetric, JWKS).
// SUPABASE_JWT_SECRET is set → use symmetric HS256 verification.
// Otherwise fall back to JWKS for ES256/RS256.
const SECRET_KEY = env.SUPABASE_JWT_SECRET
  ? new TextEncoder().encode(env.SUPABASE_JWT_SECRET)
  : null;
const JWKS = SECRET_KEY
  ? null
  : createRemoteJWKSet(new URL(`${env.SUPABASE_URL}/auth/v1/.well-known/jwks.json`));

async function verifyJwt(token: string, options: Parameters<typeof jwtVerify>[2]) {
  if (SECRET_KEY) return jwtVerify(token, SECRET_KEY, options);
  return jwtVerify(token, JWKS!, options);
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

  try {
    const expectedIssuer = `${env.SUPABASE_URL}/auth/v1`;
    const { payload } = await verifyJwt(token, {
      issuer: expectedIssuer,
      audience: 'authenticated',
    });

    const userId = payload.sub;
    if (!userId) {
      res.status(401).json({ error: 'Invalid token: missing sub' });
      return;
    }

    const tokenIat = typeof payload.iat === 'number' ? payload.iat : 0;
    const tokenExp = typeof payload.exp === 'number' ? payload.exp : 0;

    // Revocation check — rejects tokens issued before the user's last logout.
    // Closes the ~1h window where a signed-out JWT remains cryptographically valid.
    if (await isTokenRevoked(userId, tokenIat)) {
      res.status(401).json({ error: 'Token has been revoked' });
      return;
    }

    // Standing check — enforces suspension within JWT validity window.
    // Uses supabaseAdmin for a trusted server-side internal check (not user-facing data).
    const { data: profile } = await supabaseAdmin
      .schema('connect')
      .from('connected_profiles')
      .select('account_standing')
      .eq('user_id', userId)
      .maybeSingle();

    // Profile absence = Inform tier (no connected_profiles row) — allow through
    if (profile && profile.account_standing !== 'active') {
      res.status(403).json({ error: 'Account suspended' });
      return;
    }

    (req as AuthenticatedRequest).userId = userId;
    (req as AuthenticatedRequest).accessToken = token;
    (req as AuthenticatedRequest).tokenIat = tokenIat;
    (req as AuthenticatedRequest).tokenExp = tokenExp;
    next();
  } catch (err) {
    // Decode the token payload without verification to log the actual issuer
    try {
      const [, b64] = token.split('.');
      const decoded = JSON.parse(Buffer.from(b64, 'base64url').toString('utf8')) as Record<string, unknown>;
      console.error('[requireAuth] JWT verification failed. expected_issuer=%s token_iss=%s token_aud=%s err=%s',
        `${env.SUPABASE_URL}/auth/v1`,
        decoded.iss,
        decoded.aud,
        err instanceof Error ? err.message : String(err),
      );
    } catch {
      console.error('[requireAuth] JWT verification failed (could not decode token):', err instanceof Error ? err.message : String(err));
    }
    res.status(401).json({ error: 'Invalid or expired token' });
  }
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

  try {
    const { payload } = await verifyJwt(token, {
      issuer: `${env.SUPABASE_URL}/auth/v1`,
      audience: 'authenticated',
    });

    const userId = payload.sub;
    if (userId) {
      (req as AuthenticatedRequest).userId = userId;
      (req as AuthenticatedRequest).accessToken = token;
    }
  } catch {
    // Invalid token — proceed as unauthenticated (do NOT return 401)
  }

  next();
}
