/**
 * Redirect-target validation for the `?redirect=` parameter on /login and /signup.
 *
 * SECURITY: on a successful login the caller appends the member's access token
 * to this value as a URL fragment. Any host accepted here therefore receives a
 * working bearer token for that member. The allowlist is the only thing standing
 * between a clicked link and a hijacked session, so it checks the parsed
 * hostname AND the protocol — never a string prefix.
 *
 * Keep in sync with admin/src/lib/redirect.ts. The two apps are separate npm
 * projects with no shared package, so the core function is duplicated on
 * purpose; do not let the copies drift.
 */

const TRUSTED_HOST = 'empowered.vote';

/**
 * Returns `raw` when it is an https URL on empowered.vote or a subdomain of it.
 * Returns null for anything else: missing, malformed, non-https, or off-domain.
 *
 * Pure and side-effect free so it can be unit tested without a DOM.
 */
export function validateRedirectUrl(raw: string | null | undefined): string | null {
  if (!raw) return null;

  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    return null; // malformed, or relative with no base
  }

  // https only. A hostname check alone would accept http:// and downgrade the
  // token handoff to plaintext.
  if (url.protocol !== 'https:') return null;

  // Exact host, or a subdomain. `endsWith` is safe only with the leading dot:
  // without it, `empowered.vote.example.com` would pass.
  if (url.hostname !== TRUSTED_HOST && !url.hostname.endsWith(`.${TRUSTED_HOST}`)) {
    return null;
  }

  return raw;
}

/** Reads and validates the `redirect` query parameter from the current URL. */
export function getValidRedirect(): string | null {
  const raw = new URLSearchParams(window.location.search).get('redirect');
  return validateRedirectUrl(raw);
}
