/**
 * tokenIdentity — the single place that maps a verified access token to the
 * internal user id.
 *
 * WHY THIS FILE EXISTS:
 * During the Supabase Auth → WorkOS AuthKit migration (decision 0002) the API
 * accepts tokens from two issuers. The two issuers identify the same person
 * with different subjects: Supabase `sub` is the internal UUID; WorkOS `sub`
 * is a WorkOS id (`user_01…`). PRIVACY-ARCHITECTURE property A requires the
 * join between an external identity and internal data to live in exactly one
 * place — this module. Nothing outside it may read `external_id` or interpret
 * a token's `sub`.
 *
 * The WorkOS → internal mapping works because the migration import creates
 * every WorkOS user with `external_id` set to the user's original Supabase
 * auth.users UUID, and the WorkOS dashboard JWT template copies it into the
 * access token:
 *
 *   { "role": "authenticated", "external_id": {{user.external_id}} }
 *
 * A WorkOS token without `external_id` is an unlinked account (created
 * outside the import) and does not resolve. New-user provisioning must set
 * `external_id` at creation time.
 */

import type { JWTPayload } from 'jose';
import { decodeJwt } from 'jose';
import { env } from './env.js';

export const SUPABASE_ISSUER = `${env.SUPABASE_URL}/auth/v1`;

// Defaults follow the WorkOS docs; the overrides exist for custom auth domains.
export const WORKOS_ISSUER: string | null =
  env.WORKOS_ISSUER ??
  (env.WORKOS_CLIENT_ID
    ? `https://api.workos.com/user_management/${env.WORKOS_CLIENT_ID}`
    : null);

export const WORKOS_JWKS_URL: string | null =
  env.WORKOS_JWKS_URL ??
  (env.WORKOS_CLIENT_ID
    ? `https://api.workos.com/sso/jwks/${env.WORKOS_CLIENT_ID}`
    : null);

export type TokenIssuer = 'supabase' | 'workos';

/**
 * Reads the (unverified) `iss` claim to pick a verification path. The caller
 * must still verify the token cryptographically against that issuer — this
 * function only dispatches; it grants nothing.
 */
export function classifyToken(token: string): TokenIssuer | null {
  let iss: string | undefined;
  try {
    iss = decodeJwt(token).iss;
  } catch {
    return null;
  }
  if (iss === SUPABASE_ISSUER) return 'supabase';
  if (WORKOS_ISSUER !== null && iss === WORKOS_ISSUER) return 'workos';
  return null;
}

/**
 * Maps a VERIFIED payload to the internal user id, or null if the token does
 * not identify a linked account.
 */
export function resolveInternalUserId(
  issuer: TokenIssuer,
  payload: JWTPayload
): string | null {
  if (issuer === 'supabase') {
    return typeof payload.sub === 'string' && payload.sub !== '' ? payload.sub : null;
  }
  const externalId = payload.external_id;
  return typeof externalId === 'string' && externalId !== '' ? externalId : null;
}
