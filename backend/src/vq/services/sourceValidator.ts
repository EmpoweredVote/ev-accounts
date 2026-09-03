/**
 * sourceValidator.ts
 * Validates source URLs by performing an HTTP HEAD (falling back to GET) request.
 *
 * Timeout:  10 seconds, single attempt, no retries.
 * Redirects: followed automatically (redirect: 'follow').
 * User-Agent: 'EmpoweredValidationQuests/1.0 (source-validator)'.
 *
 * Status mapping:
 *   200-299   → valid
 *   403       → valid  (many public sites block bots with 403; content is still publicly accessible)
 *   402       → paywall_suspected  (credibility hit)
 *   404 / 410 → not_found          (credibility hit)
 *   5xx       → server_error       (NO credibility hit — not user's fault)
 *   Timeout   → timeout            (NO credibility hit — not user's fault)
 *   Network   → unreachable        (credibility hit)
 */

export type SourceValidationResult =
  | { valid: true }
  | {
      valid: false;
      reason:
        | 'timeout'
        | 'unreachable'
        | 'not_found'
        | 'paywall_suspected'
        | 'server_error';
    };

const USER_AGENT = 'EmpoweredValidationQuests/1.0 (source-validator)';
const TIMEOUT_MS = 10_000;

/**
 * Map an HTTP status code to a SourceValidationResult.
 */
function classifyStatus(status: number): SourceValidationResult {
  if (status >= 200 && status <= 299) {
    return { valid: true };
  }
  if (status === 403) {
    // Many legitimate public sites (government, news, academic) block automated
    // requests with 403 while remaining freely accessible to humans. Treat as valid.
    return { valid: true };
  }
  if (status === 402) {
    return { valid: false, reason: 'paywall_suspected' };
  }
  if (status === 404 || status === 410) {
    return { valid: false, reason: 'not_found' };
  }
  if (status >= 500) {
    return { valid: false, reason: 'server_error' };
  }
  // 3xx should be auto-followed (redirect: 'follow'), so reaching here for 3xx
  // means the redirect chain ended somewhere unexpected — treat as unreachable.
  return { valid: false, reason: 'unreachable' };
}

/**
 * Validate a single source URL.
 *
 * Attempts HEAD first; falls back to GET on 405 Method Not Allowed.
 * Uses AbortSignal.timeout() for a 10-second hard deadline on each attempt.
 *
 * @param url - The URL to validate (must be a fully qualified HTTP/HTTPS URL)
 * @returns SourceValidationResult
 */
export async function validateSourceUrl(url: string): Promise<SourceValidationResult> {
  const headers = { 'User-Agent': USER_AGENT };

  try {
    // Attempt 1: HEAD request
    const headResponse = await fetch(url, {
      method: 'HEAD',
      headers,
      redirect: 'follow',
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });

    // 405 = Method Not Allowed — server doesn't support HEAD, retry with GET
    if (headResponse.status === 405) {
      try {
        const getResponse = await fetch(url, {
          method: 'GET',
          headers,
          redirect: 'follow',
          signal: AbortSignal.timeout(TIMEOUT_MS),
        });
        return classifyStatus(getResponse.status);
      } catch (getErr) {
        return classifyStatusFromError(getErr);
      }
    }

    return classifyStatus(headResponse.status);
  } catch (err) {
    return classifyStatusFromError(err);
  }
}

/**
 * Classify a caught fetch error as timeout or unreachable.
 */
function classifyStatusFromError(err: unknown): SourceValidationResult {
  if (err instanceof DOMException && err.name === 'TimeoutError') {
    return { valid: false, reason: 'timeout' };
  }
  if (err instanceof Error && err.name === 'AbortError') {
    return { valid: false, reason: 'timeout' };
  }
  // DNS failure, connection refused, network unreachable, etc.
  return { valid: false, reason: 'unreachable' };
}
