/**
 * Wikimedia Commons API client for county banner sourcing.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 */

/**
 * 🔴 A generic client name with NO personal contact details.
 *
 * Wikimedia 429s a fully anonymous User-Agent, so the client is named -- but naming a
 * PERSON here sends their address to every host this pipeline touches. 56 scripts in
 * this directory did exactly that until 2026-11-19. If a host ever demands a real
 * contact address, ask the operator which to use; do not read one out of the repo.
 */
export const USER_AGENT = 'EmpoweredVote-county-banners/1.0 (+https://empowered.vote)';

const API = 'https://commons.wikimedia.org/w/api.php';
const MAX_ATTEMPTS = 4;

/** Commons answered, but with a challenge or a block page rather than data. */
export class CommonsBlockedError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'CommonsBlockedError';
  }
}

export interface CommonsApiOptions {
  /** Base backoff; attempt N waits backoffMs * N. Tests pass 0. */
  backoffMs?: number;
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

/**
 * One Commons API call, with backoff.
 *
 * 🔴 A WAF REJECTION CAN BE HTTP 200, so this never judges a response by `r.ok` alone.
 * A 200 whose body does not parse as JSON is a challenge page, and returning `{}` for it
 * would read downstream as "this category is empty" -- a wrong answer that looks like a
 * right one. It throws instead.
 */
export async function commonsApi(
  params: Record<string, string | number>,
  opts: CommonsApiOptions = {},
): Promise<unknown> {
  const backoffMs = opts.backoffMs ?? 2000;
  const qs = new URLSearchParams({ ...Object.fromEntries(Object.entries(params).map(([k, v]) => [k, String(v)])), format: 'json', formatversion: '2' });
  let lastStatus = 0;
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    const res = await fetch(`${API}?${qs}`, { headers: { 'User-Agent': USER_AGENT } });
    lastStatus = res.status;
    if (res.status >= 200 && res.status < 300) {
      const body = await res.text();
      let parsed: unknown;
      try {
        parsed = JSON.parse(body);
      } catch {
        throw new CommonsBlockedError(`Commons answered ${res.status} with a non-JSON body (${body.slice(0, 80)})`);
      }
      // 🔴 MediaWiki answers 200 with {"error":{...}} for a rate limit, a bad parameter
      // or readapidenied. That parses, and the caller would read it as an empty result --
      // the same 'no files' misreading the challenge check exists to prevent.
      const err = (parsed as { error?: { code?: string; info?: string } }).error;
      if (err) throw new CommonsBlockedError(`Commons API error ${err.code ?? 'unknown'}: ${err.info ?? ''}`);
      return parsed;
    }
    if (attempt < MAX_ATTEMPTS) await sleep(backoffMs * attempt);
  }
  throw new Error(`Commons failed after ${MAX_ATTEMPTS} attempts (last status ${lastStatus})`);
}
