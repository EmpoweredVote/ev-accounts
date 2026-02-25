import { jwtVerify, createRemoteJWKSet } from 'jose';
import { Request, Response, NextFunction } from 'express';
import { env } from '../lib/env.js';
import { supabaseAdmin } from '../lib/supabase.js';

// Supabase projects created after May 2025 use ES256 (asymmetric) by default.
// This middleware uses JWKS-based verification which works for ES256 and RS256.
// If the project uses HS256 (legacy symmetric), replace createRemoteJWKSet with:
//   new TextEncoder().encode(env.SUPABASE_JWT_SECRET)
// Check: Supabase Dashboard > Auth > JWT Configuration

// JWKS is fetched once and cached — no network call per request
const JWKS = createRemoteJWKSet(
  new URL(`${env.SUPABASE_URL}/auth/v1/.well-known/jwks.json`)
);

export interface AuthenticatedRequest extends Request {
  userId: string;
  accessToken: string;
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
    const { payload } = await jwtVerify(token, JWKS, {
      issuer: `${env.SUPABASE_URL}/auth/v1`,
      audience: 'authenticated',
    });

    const userId = payload.sub;
    if (!userId) {
      res.status(401).json({ error: 'Invalid token: missing sub' });
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
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}
