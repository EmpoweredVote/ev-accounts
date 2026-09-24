/**
 * fecGetJson — one GET against the FEC API for scripts: through the shared limiter, with retry.
 *
 * 🔴 The FEC key is SHARED — the scheduled ingest, the auto-match queue and every session's
 * scripts spend the same budget. On 2026-09-23 run-fec-finance-summary.ts paced itself with a
 * private 1500ms sleep (up to 40 calls/min), ignored acquireFecSlot, and threw on the first 429:
 * a --candidates-only rerun lost 13 of 50 people to HTTP 429 while other sessions were calling
 * FEC. This is the same contract fecAdapter's fetchWithRetry keeps (which is module-private and
 * typed for Schedule A pages, so it cannot be reused here):
 *
 *   - acquireFecSlot() before EVERY attempt, retries included — the one chokepoint (FEC-03).
 *   - 429 and 5xx back off exponentially (2s, 4s, 8s ... capped at 120s). Five retries add up
 *     to ~62s, which outlasts a per-minute window.
 *   - A server Retry-After wins when present, clamped to 120s — never sleep on an unclamped
 *     header value.
 *   - A timeout or network failure is retried like a 429: near the ceiling FEC hangs the
 *     connection instead of answering.
 *   - Any other 4xx fails at once.
 *
 * Errors name `label`, never the URL: the URL carries the api_key.
 */

import { acquireFecSlot } from '../../src/lib/fecRateLimiter.js';

export interface FecGetOptions {
  /** Retries after the first attempt. Default 5. */
  maxRetries?: number;
  /** Per-attempt socket timeout. Default 30s. */
  timeoutMs?: number;
  /** Injected for tests. */
  sleep?: (_ms: number) => Promise<void>;
}

const FIRST_DELAY_MS = 2_000;
const MAX_DELAY_MS = 120_000;

const realSleep = (ms: number): Promise<void> => new Promise(resolve => setTimeout(resolve, ms));

/**
 * Parses a Retry-After header (seconds or HTTP date) to milliseconds. Returns null when absent
 * or unparseable. The caller clamps.
 */
export function parseRetryAfterMs(value: string | null): number | null {
  if (!value) return null;
  const seconds = Number(value);
  if (!Number.isNaN(seconds)) return seconds * 1000;
  const date = Date.parse(value);
  return Number.isNaN(date) ? null : Math.max(0, date - Date.now());
}

export async function fecGetJson<T>(url: string, label: string, opts: FecGetOptions = {}): Promise<T> {
  const maxRetries = opts.maxRetries ?? 5;
  const timeoutMs = opts.timeoutMs ?? 30_000;
  const sleep = opts.sleep ?? realSleep;
  let delayMs = FIRST_DELAY_MS;

  for (let attempt = 0; ; attempt++) {
    await acquireFecSlot();

    let response: Response;
    try {
      response = await fetch(url, { signal: AbortSignal.timeout(timeoutMs) });
    } catch (err) {
      // Name the failure kind only — a fetch error can echo the URL, and the URL carries the
      // api_key. That is also why the caught error is NOT attached as `cause`: the fatal handler
      // prints an error with its cause chain.
      const kind = err instanceof Error ? err.name : 'error';
      if (attempt >= maxRetries) {
        // eslint-disable-next-line preserve-caught-error -- the cause can carry the api_key (see above)
        throw new Error(`FEC ${label}: request failed (${kind}) after ${maxRetries} retries`);
      }
      console.warn(`  [retry] FEC ${label}: request failed (${kind}) — waiting ${delayMs}ms (${attempt + 1}/${maxRetries})`);
      await sleep(delayMs);
      delayMs = Math.min(delayMs * 2, MAX_DELAY_MS);
      continue;
    }

    if (response.status === 429 || response.status >= 500) {
      if (attempt >= maxRetries) {
        throw new Error(`FEC ${label} HTTP ${response.status} after ${maxRetries} retries`);
      }
      const serverDelay = response.status === 429 ? parseRetryAfterMs(response.headers.get('retry-after')) : null;
      const wait = Math.min(serverDelay ?? delayMs, MAX_DELAY_MS);
      console.warn(`  [retry] FEC ${label} HTTP ${response.status} — waiting ${wait}ms (${attempt + 1}/${maxRetries})`);
      await sleep(wait);
      delayMs = Math.min(delayMs * 2, MAX_DELAY_MS);
      continue;
    }

    if (!response.ok) {
      throw new Error(`FEC ${label} HTTP ${response.status}`);
    }
    return (await response.json()) as T;
  }
}
