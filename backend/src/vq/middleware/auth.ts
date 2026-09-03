// Source: empowered-accounts-integration-guide.md (v1.0, 2026-02-28)
// Updated 2026-03-31: Supabase migrated project to new asymmetric JWT Signing Keys.
// Legacy HS256/SUPABASE_JWT_SECRET path no longer valid — switched to JWKS verification.
// Updated 2026-08-27: Supabase → WorkOS AuthKit migration (ev-accounts decision 0002).
// Accepts BOTH issuers during the transition window. A WorkOS token carries the
// internal user id in its external_id claim (set at import/provision time) — the
// WorkOS sub (user_01…) must never be used as userId. WorkOS tokens have no aud
// claim; the dashboard JWT template's role=authenticated stands in for it.
// WORKOS_CLIENT_ID absent = Supabase-only, exactly the old behavior.
import { createRemoteJWKSet, jwtVerify, decodeJwt } from 'jose';

const SUPABASE_ISSUER = `${process.env.SUPABASE_URL}/auth/v1`;
const SUPABASE_JWKS = createRemoteJWKSet(
  new URL(`${process.env.SUPABASE_URL}/auth/v1/.well-known/jwks.json`),
);

const WORKOS_CLIENT_ID = process.env.WORKOS_CLIENT_ID;
const WORKOS_ISSUER =
  process.env.WORKOS_ISSUER ??
  (WORKOS_CLIENT_ID ? `https://api.workos.com/user_management/${WORKOS_CLIENT_ID}` : null);
const WORKOS_JWKS_URL =
  process.env.WORKOS_JWKS_URL ??
  (WORKOS_CLIENT_ID ? `https://api.workos.com/sso/jwks/${WORKOS_CLIENT_ID}` : null);
const WORKOS_JWKS = WORKOS_JWKS_URL ? createRemoteJWKSet(new URL(WORKOS_JWKS_URL)) : null;

export async function requireAuth(req: any, res: any, next: any) {
  const token = req.headers.authorization?.slice(7); // strip "Bearer "
  if (!token) return res.status(401).json({ error: 'Missing token' });

  try {
    // Unverified issuer read picks the verification path; the jwtVerify below
    // still enforces signature + issuer, so this grants nothing by itself.
    const iss = decodeJwt(token).iss;

    let userId: unknown;
    let payload;
    if (iss === SUPABASE_ISSUER) {
      ({ payload } = await jwtVerify(token, SUPABASE_JWKS, {
        issuer: SUPABASE_ISSUER,
        audience: 'authenticated',
      }));
      userId = payload.sub;
    } else if (WORKOS_JWKS !== null && iss === WORKOS_ISSUER) {
      ({ payload } = await jwtVerify(token, WORKOS_JWKS, { issuer: WORKOS_ISSUER }));
      if (payload.role !== 'authenticated') {
        throw new Error('WorkOS token missing role=authenticated (JWT template not applied)');
      }
      userId = payload.external_id; // unlinked (never-provisioned) accounts don't resolve
    } else {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    if (typeof userId !== 'string' || userId === '') {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    req.userId = userId;
    req.accessToken = token;
    req.jwtPayload = payload;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
