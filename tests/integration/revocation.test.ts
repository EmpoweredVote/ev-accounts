// IMPORTANT: Env vars must be set before any imports that read process.env.
// The auth middleware reads SUPABASE_JWT_SECRET at module evaluation time (line 11 of
// auth.ts) to decide between HS256 and JWKS. If set after import, the middleware
// will have already chosen the JWKS path and the test JWT will not verify.
process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] = 'test-service-role-key';
process.env['DATABASE_URL'] = 'postgresql://postgres:password@localhost:5432/postgres';
// Activates the HS256 path in auth.ts — without this, requireAuth uses JWKS
// (network call to test.supabase.co which fails and returns 401 for the wrong reason).
process.env['SUPABASE_JWT_SECRET'] = 'test-secret-32-chars-minimum-for-hs256';

import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import { SignJWT } from 'jose';
import type { Express } from 'express';

const TEST_JWT_SECRET = 'test-secret-32-chars-minimum-for-hs256';
const TEST_USER_ID = '00000000-0000-0000-0000-000000000001';

async function signTestJwt(): Promise<string> {
  const secretKey = new TextEncoder().encode(TEST_JWT_SECRET);
  return new SignJWT({
    sub: TEST_USER_ID,
    role: 'authenticated',
  })
    .setProtectedHeader({ alg: 'HS256' })
    // 1 second in the past — avoids iat == lastLogout collision.
    // isTokenRevoked uses strict less-than (tokenIat < lastLogout). If iat equals
    // the logout timestamp (same second), the check returns false (not revoked)
    // and the test would fail. Setting iat to -1s guarantees iat < lastLogout.
    .setIssuedAt(Math.floor(Date.now() / 1000) - 1)
    .setIssuer('https://test.supabase.co/auth/v1')
    .setAudience('authenticated')
    .setExpirationTime('1h')
    .sign(secretKey);
}

let app: Express;

beforeAll(async () => {
  // Dynamic import allows env setup above to complete before module evaluation
  const mod = await import('../../backend/src/index.js');
  app = mod.app;
});

// ---------------------------------------------------------------------------
// JWT revocation via Redis blocklist (HARD-03)
//
// Proves the security guarantee: a token used to call /logout is immediately
// rejected on the next request, even though it is still cryptographically valid.
//
// How this works without live Supabase:
// 1. requireAuth verifies the JWT using HS256 (SUPABASE_JWT_SECRET is set) — passes
// 2. recordLogout writes last_logout:{userId} to the in-memory cache (Redis fallback)
//    signOutUser fails against the test URL but the error is swallowed — logout returns 200
// 3. On the next request, requireAuth verifies the JWT (still valid) — passes
// 4. isTokenRevoked reads last_logout:{userId} from cache — tokenIat < lastLogout — returns true
// 5. requireAuth returns 401 with "Token has been revoked" before the standing check
// ---------------------------------------------------------------------------

describe('JWT revocation via Redis blocklist', () => {
  it('rejects a token on the next request after logout', async () => {
    const token = await signTestJwt();

    // Step 1: Logout — signOutUser fails silently against test Supabase URL,
    // then recordLogout writes last_logout:{userId} to the in-memory cache.
    const logoutRes = await request(app)
      .post('/api/auth/logout')
      .set('Authorization', `Bearer ${token}`);
    expect(logoutRes.status).toBe(200);

    // Step 2: Immediate request with the same token.
    // requireAuth verifies the JWT (HS256 — still valid), then calls isTokenRevoked
    // which reads last_logout:{userId} from cache and finds tokenIat < lastLogout.
    const meRes = await request(app)
      .get('/api/account/me')
      .set('Authorization', `Bearer ${token}`);
    expect(meRes.status).toBe(401);
    expect(meRes.body.error).toBe('Token has been revoked');
  });
});
