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
import { Readability } from '@mozilla/readability';
import { parseHTML } from 'linkedom';
import { renderPage, EMPOWERED_VOTE_UA, EMPOWERED_VOTE_UA_TOKEN } from './fetchPageContent.js';

const HTTP_TIMEOUT_MS = 12_000;
const ROBOTS_TIMEOUT_MS = 8_000;
/** How long a parsed robots.txt is trusted before we re-fetch it. */
const ROBOTS_TTL_MS = 30 * 60 * 1000; // 30 minutes

/** Below this many chars a page is almost certainly a stub/challenge, not content. */
export const MIN_REAL_PAGE_CHARS = 500;

/**
 * Below this many chars, Readability's result is too thin to trust (a title-only
 * parse, or a page it could not find an article in) — fall back to the legacy
 * stripper so a hard-to-parse page is never worse off than before.
 */
export const MIN_ARTICLE_CHARS = 200;

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
 * Extract the main article text from raw HTML with Mozilla Readability — the
 * same algorithm Firefox's Reader View uses — running on linkedom, a small,
 * pure-JS DOM. No jsdom (heavy, Alpine-hostile) and no native build.
 *
 * Readability drops navigation, cookie/consent banners, "related stories",
 * comment threads and footers that the legacy regex stripper leaves in, so the
 * deterministic snippet matcher sees the real article instead of boilerplate.
 *
 * Fails SAFE: if Readability throws, or returns less than {@link MIN_ARTICLE_CHARS}
 * of text (a title-only or unparseable page), fall back to {@link htmlToText}.
 * htmlToText therefore stays the floor — this can only add article text, never
 * remove the old behaviour.
 *
 * @param url only used to skip non-article documents (PDF/spreadsheet URLs that
 *   slipped past the caller's content-type check); Readability derives the text
 *   from the HTML itself.
 */
export function extractArticleText(html: string, url: string): string {
  // A direct PDF / office-doc URL has no article DOM to grab — don't waste a
  // parse; the legacy stripper's whitespace collapse is the right handling.
  if (/\.(pdf|docx?|xlsx?|pptx?|csv|json|xml)(?:$|[?#])/i.test(url)) return htmlToText(html);
  try {
    const { document } = parseHTML(html);
    const article = new Readability(document as unknown as Document).parse();
    const text = (article?.textContent ?? '').replace(/\s+/g, ' ').trim();
    if (text.length >= MIN_ARTICLE_CHARS) return text;
  } catch {
    // Malformed / unparseable DOM — fall through to the legacy stripper.
  }
  return htmlToText(html);
}

/**
 * Choose the HTML→text extractor by the EXTRACTOR env var, read at CALL TIME so
 * it can be flipped by a redeploy env change (or a test) without touching code:
 *   EXTRACTOR=readability → {@link extractArticleText} (article body only)
 *   anything else / unset (default) → the legacy {@link htmlToText} stripper
 */
function htmlToArticleOrText(html: string, url: string): string {
  return (process.env.EXTRACTOR ?? 'legacy').toLowerCase() === 'readability'
    ? extractArticleText(html, url)
    : htmlToText(html);
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

// ─────────────────────────────────────────────────────────────────────────────
// robots.txt — we fetch honestly (see EMPOWERED_VOTE_UA), so we also obey the
// site's stated wishes. Before hitting a live page we check whether
// EmpoweredVoteBot is disallowed for that path; if it is, we skip the live tiers
// and fall back to an archived Wayback snapshot (which is not a fetch of the
// live site), or record a distinct `robots_disallowed` outcome.
//
// This is a deliberately small parser, not a full RFC 9309 implementation. It
// supports: per-user-agent groups, `*` groups, longest-match wins, Allow beats
// Disallow on an equal-length tie, and the `*` / `$` path wildcards. That covers
// what real newsroom robots.txt files use.
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Thrown by a fetch session when robots.txt disallows the path AND no archived
 * snapshot is available. Distinct from a generic fetch failure so the two can be
 * COUNTED SEPARATELY — a policy "no" is not a broken URL. Callers detect it by
 * the stable `code`, without importing this class.
 */
export class RobotsDisallowedError extends Error {
  readonly code = 'robots_disallowed';
  constructor(url: string) {
    super('robots_disallowed: ' + url);
    this.name = 'RobotsDisallowedError';
  }
}

interface RobotsRule {
  allow: boolean;
  /** Length of the rule path excluding `*`/`$`, used as match specificity. */
  specificity: number;
  test: (path: string) => boolean;
}

/** Compile one Allow/Disallow value into a prefix matcher with `*`/`$` support. */
function compileRule(allow: boolean, value: string): RobotsRule | null {
  // An empty Disallow means "allow everything" — it contributes no constraint.
  if (value === '') return null;
  const specificity = value.replace(/[*$]/g, '').length;
  // A trailing `$` anchors the match to the end of the path.
  const anchored = value.endsWith('$');
  const body = anchored ? value.slice(0, -1) : value;
  const pattern = body
    .replace(/[.+?^${}()|[\]\\]/g, '\\$&') // escape regex metachars, EXCEPT `*`…
    .replace(/\*/g, '.*'); // …which is the robots wildcard → `.*`.
  const rx = new RegExp('^' + pattern + (anchored ? '$' : ''));
  return { allow, specificity, test: (path) => rx.test(path) };
}

/**
 * Parse robots.txt and return the rule set that applies to `token`. Picks the
 * most specific matching user-agent group (an exact/prefix token match beats the
 * `*` group); returns `[]` when no group applies, i.e. fully allowed.
 */
export function parseRobotsForAgent(txt: string, token: string): RobotsRule[] {
  const tok = token.toLowerCase();
  // Group lines by their governing user-agent(s). Consecutive User-agent lines
  // share the following rules.
  const groups: { agents: string[]; rules: RobotsRule[] }[] = [];
  let current: { agents: string[]; rules: RobotsRule[] } | null = null;
  let expectingAgent = false;

  for (const raw of txt.split(/\r?\n/)) {
    const line = raw.replace(/#.*$/, '').trim();
    if (!line) continue;
    const idx = line.indexOf(':');
    if (idx === -1) continue;
    const field = line.slice(0, idx).trim().toLowerCase();
    const value = line.slice(idx + 1).trim();

    if (field === 'user-agent') {
      if (!current || !expectingAgent) {
        current = { agents: [], rules: [] };
        groups.push(current);
        expectingAgent = true;
      }
      current.agents.push(value.toLowerCase());
    } else if (field === 'allow' || field === 'disallow') {
      if (!current) continue; // rule before any user-agent — ignore
      expectingAgent = false;
      const rule = compileRule(field === 'allow', value);
      if (rule) current.rules.push(rule);
    }
    // Other fields (Sitemap, Crawl-delay, …) are ignored.
  }

  // A group matches our token if any of its agents is `*` or a prefix of the
  // token (case-insensitive), e.g. `empoweredvotebot` or `empoweredvote`.
  const specific = groups.filter((g) =>
    g.agents.some((a) => a !== '*' && (tok === a || tok.startsWith(a))),
  );
  if (specific.length) return specific.flatMap((g) => g.rules);
  const star = groups.filter((g) => g.agents.includes('*'));
  return star.flatMap((g) => g.rules);
}

/** Apply parsed rules to a path. Longest match wins; Allow breaks an even tie. */
export function isPathAllowed(rules: RobotsRule[], path: string): boolean {
  let best: RobotsRule | null = null;
  for (const rule of rules) {
    if (!rule.test(path)) continue;
    if (
      !best ||
      rule.specificity > best.specificity ||
      (rule.specificity === best.specificity && rule.allow && !best.allow)
    ) {
      best = rule;
    }
  }
  return best ? best.allow : true; // no rule matched → allowed
}

interface RobotsCacheEntry {
  rules: RobotsRule[];
  expires: number;
}
const robotsCache = new Map<string, RobotsCacheEntry>();

/** Test seam: drop the in-memory robots cache. */
export function clearRobotsCache(): void {
  robotsCache.clear();
}

/**
 * Is EmpoweredVoteBot allowed to fetch `url`? Fetches and caches robots.txt per
 * origin with a short TTL.
 *
 * Fail-open: if robots.txt is missing (404), unreachable, or errors, we treat
 * the path as ALLOWED — we only ever honour an EXPLICIT Disallow we actually
 * read. This keeps a flaky robots endpoint from silently blocking verification,
 * and matches the RFC's "unavailable → no restrictions" for 4xx.
 */
export async function robotsAllows(url: string): Promise<boolean> {
  let origin: string;
  let path: string;
  try {
    const u = new URL(url);
    if (u.protocol !== 'http:' && u.protocol !== 'https:') return true;
    origin = u.origin;
    path = u.pathname + u.search;
  } catch {
    return true; // not a URL we can reason about — don't block
  }

  const now = Date.now();
  let entry = robotsCache.get(origin);
  if (!entry || entry.expires <= now) {
    const rules = await fetchRobotsRules(origin);
    entry = { rules, expires: now + ROBOTS_TTL_MS };
    robotsCache.set(origin, entry);
  }
  return isPathAllowed(entry.rules, path);
}

async function fetchRobotsRules(origin: string): Promise<RobotsRule[]> {
  try {
    const res = await fetch(origin + '/robots.txt', {
      redirect: 'follow',
      signal: AbortSignal.timeout(ROBOTS_TIMEOUT_MS),
      headers: { 'user-agent': EMPOWERED_VOTE_UA },
    });
    // 4xx/404 → no robots file → no restrictions. Anything non-2xx → fail open.
    if (!res.ok) return [];
    const body = await res.text();
    return parseRobotsForAgent(body, EMPOWERED_VOTE_UA_TOKEN);
  } catch {
    return []; // unreachable / timeout → fail open (allowed)
  }
}

/** Tier 1 — plain HTTP fetch + strip. Throws on network error / non-2xx. */
export async function fetchViaHttp(url: string): Promise<string> {
  const res = await fetch(url, {
    redirect: 'follow',
    signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
    headers: {
      'user-agent': EMPOWERED_VOTE_UA,
      accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'accept-language': 'en-US,en;q=0.9',
    },
  });
  if (!res.ok) throw new Error('HTTP ' + res.status);
  const body = await res.text();
  const ctype = res.headers.get('content-type') ?? '';
  return ctype.includes('html') ? htmlToArticleOrText(body, url) : body.replace(/\s+/g, ' ').trim();
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
      headers: { 'user-agent': EMPOWERED_VOTE_UA },
    });
    if (!res.ok) return null;
    // Pass the ORIGINAL url (not the archive.org wrapper) so the non-article
    // guard in extractArticleText reasons about the real document.
    return htmlToArticleOrText(await res.text(), url);
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
 * Injectable tiers. Defaults are the real network paths; tests override them to
 * assert that a robots-disallowed URL never touches the live tiers.
 */
export interface VerificationFetchDeps {
  /** robots.txt gate — is EmpoweredVoteBot allowed to fetch this URL live? */
  robotsAllows?: (url: string) => Promise<boolean>;
  /** Tier 1 — plain HTTP fetch. */
  httpFetch?: (url: string) => Promise<string>;
  /** Tier 2 — headless render. */
  render?: (url: string) => Promise<string>;
  /** Tier 3 — Wayback snapshot (archive, not a live-site fetch). */
  wayback?: (url: string) => Promise<string | null>;
}

/**
 * Create a fetch session that reuses ONE headless browser across the batch.
 * Pass `session.fetch` to researchVerifier.createPageFetcher.
 */
export function createVerificationFetchSession(
  deps: VerificationFetchDeps = {},
): VerificationFetchSession {
  let browser: Browser | null = null;
  const getBrowser = async () => (browser ??= await chromium.launch({ headless: true }));

  const allowed = deps.robotsAllows ?? robotsAllows;
  const httpFetch = deps.httpFetch ?? fetchViaHttp;
  const render = deps.render ?? ((url: string) => getBrowser().then((b) => renderPage(b, url)));
  const wayback = deps.wayback ?? fetchViaWayback;

  return {
    async fetch(url: string): Promise<string> {
      // Tier 0 — respect robots.txt. If EmpoweredVoteBot is disallowed we do NOT
      // fetch the live site: go straight to the archived snapshot, and if there
      // is none, surface a distinct robots_disallowed outcome (not url_broken).
      if (!(await allowed(url))) {
        try {
          const t = await wayback(url);
          if (t) return t; // an archive.org copy is fair game even when the live site says no
        } catch {
          /* fall through to the distinct signal */
        }
        throw new RobotsDisallowedError(url);
      }

      const candidates: string[] = [];

      // Tier 1 — plain HTTP
      try {
        const t = await httpFetch(url);
        if (looksLikeRealPage(t)) return t;
        if (t) candidates.push(t);
      } catch {
        /* fall through */
      }

      // Tier 2 — headless Chromium (shared browser)
      try {
        const t = await render(url);
        if (looksLikeRealPage(t)) return t;
        if (t) candidates.push(t);
      } catch {
        /* fall through */
      }

      // Tier 3 — Wayback snapshot
      try {
        const t = await wayback(url);
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
