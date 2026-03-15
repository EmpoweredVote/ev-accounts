/**
 * Validates and returns a ?redirect= URL param if it points to a trusted domain.
 * Trusted: *.empowered.vote (wildcard) and empowered.vote (root).
 * Returns null for missing, malformed, or untrusted URLs.
 */
export function getValidRedirect(): string | null {
  const params = new URLSearchParams(window.location.search);
  const raw = params.get('redirect');
  if (!raw) return null;
  try {
    const url = new URL(raw);
    if (url.hostname === 'empowered.vote' || url.hostname.endsWith('.empowered.vote')) {
      return raw;
    }
  } catch {
    // malformed URL
  }
  return null;
}

/**
 * Extract a human-readable app name from a redirect URL for the callout.
 */
export function getAppNameFromRedirect(redirectUrl: string): string {
  try {
    const hostname = new URL(redirectUrl).hostname;
    const subdomain = hostname.replace('.empowered.vote', '');
    if (subdomain === 'empowered.vote' || subdomain === hostname) return 'Empowered Vote';
    return subdomain.charAt(0).toUpperCase() + subdomain.slice(1);
  } catch {
    return 'Empowered Vote';
  }
}
