/**
 * verificationFetch — a tiered, LLM-free page-fetch ladder for the stance
 * verifier. The goal is to recover the real, human-visible text of a cited page
 * so the deterministic snippet matcher (researchVerifier) can run, WITHOUT
 * falling back to an expensive re-research LLM agent just because a site is
 * unfriendly to a naive headless fetch.
 *
 * Ladder (cheap → expensive; stop at the first tier that returns a "real" page):
 *   1. Plain HTTP fetch + HTML→text  — static / server-rendered pages (.gov,
 *      congress.gov, most newspapers). No browser cost.
 *   2. Headless Chromium (shared browser, reused across the batch) — JS-rendered
 *      pages and basic bot checks.
 *   3. Wayback Machine snapshot       — archive.org serves clean static HTML that
 *      is immune to the live site's bot protection / paywall. Rescues the case
 *      where the live page is a Cloudflare challenge or empty shell.
 *
 * No LLM anywhere. The only "cost" is HTTP/browser latency, and the net effect
 * is FEWER re-research dispatches (the only token-expensive path), so this
 * lowers overall token usage rather than raising it.
 *
 * The verifier consumes this through researchVerifier.createPageFetcher, which
 * adds per-URL caching and the {ok|reason} envelope. createVerificationFetchSession
 * owns the shared browser; close() it when the batch is done.
 */

import { chromium, type Browser } from 'playwright';
import { renderPage, REALISTIC_UA } from './fetchPageContent.js';

const HTTP_TIMEOUT_MS = 12_000;

/** Below this many chars a page is almost certainly a stub/challenge, not content. */
export const MIN_REAL_PAGE_CHARS = 500;

/** Substrings that betray a bot-challenge / JS-required interstitial. */
const CHALLENGE_MARKERS = [
  'just a moment',
  'enable javascript',
  'please enable js',
  'cf-browser-verification',
  'checking your browser',
  'verifying you are human',
  'attention required',
  'access denied',
  'request unsuccessful',
];

const HTML_ENTITIES: Record<string, string> = {
  '&nbsp;': ' ',
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&apos;': "'",
  '&#39;': "'",
};

/** Strip tags/scripts/styles from raw HTML and collapse to readable text. */
export function htmlToText(html: string): string {
  let out = html
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<!--[\s\S]*?-->/g, ' ')
    .replace(/<[^>]+>/g, ' ');
  for (const [entity, replacement] of Object.entries(HTML_ENTITIES)) {
    out = out.split(entity).join(replacement);
  }
  return out.replace(/\s+/g, ' ').trim();
}

/**
 * Heuristic: does this text look like a real article page (vs. a challenge
 * interstitial or empty shell)? Used to decide whether to escalate to the next
 * tier. Long pages are trusted even if they happen to contain a marker phrase.
 */
export function looksLikeRealPage(text: string): boolean {
  if (!text || text.length < MIN_REAL_PAGE_CHARS) return false;
  const low = text.toLowerCase();
  if (text.length < 2000 && CHALLENGE_MARKERS.some((m) => low.includes(m))) return false;
  return true;
}

/** Tier 1 — plain HTTP fetch + strip. Throws on network error / non-2xx. */
export async function fetchViaHttp(url: string): Promise<string> {
  const res = await fetch(url, {
    redirect: 'follow',
    signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
    headers: {
      'user-agent': REALISTIC_UA,
      accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'accept-language': 'en-US,en;q=0.9',
    },
  });
  if (!res.ok) throw new Error('HTTP ' + res.status);
  const body = await res.text();
  const ctype = res.headers.get('content-type') ?? '';
  return ctype.includes('html') ? htmlToText(body) : body.replace(/\s+/g, ' ').trim();
}

/** Tier 3 — closest Wayback Machine snapshot, or null if none/usable. */
export async function fetchViaWayback(url: string): Promise<string | null> {
  const noProto = url.replace(/^https?:\/\//, '');
  let snapUrl: string | undefined;
  try {
    const avail = await fetch(
      'https://archive.org/wayback/available?url=' + encodeURIComponent(noProto),
      { signal: AbortSignal.timeout(HTTP_TIMEOUT_MS) },
    );
    if (!avail.ok) return null;
    const json: any = await avail.json();
    const snap = json?.archived_snapshots?.closest;
    if (!snap?.url || String(snap.status) !== '200') return null;
    snapUrl = snap.url;
  } catch {
    return null;
  }
  try {
    const res = await fetch(snapUrl!, {
      signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
      headers: { 'user-agent': REALISTIC_UA },
    });
    if (!res.ok) return null;
    return htmlToText(await res.text());
  } catch {
    return null;
  }
}

export interface VerificationFetchSession {
  /** Fetch the best available text for a URL via the ladder. Throws only when every tier fails. */
  fetch(url: string): Promise<string>;
  /** Close the shared browser (call once the batch is done). */
  close(): Promise<void>;
}

/**
 * Create a fetch session that reuses ONE headless browser across the batch.
 * Pass `session.fetch` to researchVerifier.createPageFetcher.
 */
export function createVerificationFetchSession(): VerificationFetchSession {
  let browser: Browser | null = null;
  const getBrowser = async () => (browser ??= await chromium.launch({ headless: true }));

  return {
    async fetch(url: string): Promise<string> {
      const candidates: string[] = [];

      // Tier 1 — plain HTTP
      try {
        const t = await fetchViaHttp(url);
        if (looksLikeRealPage(t)) return t;
        if (t) candidates.push(t);
      } catch {
        /* fall through */
      }

      // Tier 2 — headless Chromium (shared browser)
      try {
        const t = await renderPage(await getBrowser(), url);
        if (looksLikeRealPage(t)) return t;
        if (t) candidates.push(t);
      } catch {
        /* fall through */
      }

      // Tier 3 — Wayback snapshot
      try {
        const t = await fetchViaWayback(url);
        if (t && looksLikeRealPage(t)) return t;
        if (t) candidates.push(t);
      } catch {
        /* fall through */
      }

      // Best-effort: longest thing we found (the snippet may still be in it),
      // else signal a hard failure → url_broken.
      if (candidates.length) return candidates.sort((a, b) => b.length - a.length)[0];
      throw new Error('all fetch tiers failed for ' + url);
    },

    async close() {
      if (browser) {
        await browser.close();
        browser = null;
      }
    },
  };
}

/** One-shot ladder fetch (opens + closes its own session). For single-URL callers. */
export async function fetchForVerification(url: string): Promise<string> {
  const session = createVerificationFetchSession();
  try {
    return await session.fetch(url);
  } finally {
    await session.close();
  }
}
