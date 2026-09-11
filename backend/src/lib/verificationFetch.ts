/**
 * verificationFetch — a tiered, LLM-free page-fetch ladder for the stance
 * verifier. The goal is to recover the real, human-visible text of a cited page
 * so the deterministic snippet matcher (researchVerifier) can run, WITHOUT
 * falling back to an expensive re-research LLM agent just because a site is
 * unfriendly to a naive fetch.
 *
 * Ladder (cheap → expensive; stop at the first tier that returns a "real" page):
 *   1. Plain HTTP fetch + HTML→text  — static / server-rendered pages (.gov,
 *      most newspapers). No browser cost.
 *   3. Wayback Machine snapshot      — archive.org serves clean static HTML that
 *      is immune to the live site's bot protection / paywall. Rescues the case
 *      where the live page is a challenge page or an empty shell.
 *
 * The numbering keeps a gap at 2: a headless-browser rung once sat there. It was
 * removed (knowledge/decisions/0003-scraping-toolchain.md) — it could not run on
 * the Alpine/musl deployment and was unexercised. The Wayback rung keeps its
 * historical "tier 3" name so log lines and outcome codes do not shift meaning.
 * Restoring a middle rung — an anti-bot fetch for pages a plain fetch cannot
 * reach (e.g. congress.gov, ballotpedia) — is decision 0003 rung 2, tracked
 * separately.
 *
 * No LLM anywhere. The only "cost" is HTTP latency, and the net effect is FEWER
 * re-research dispatches (the only token-expensive path), so this lowers overall
 * token usage rather than raising it.
 *
 * The verifier consumes this through researchVerifier.createPageFetcher, which
 * adds per-URL caching and the {ok|reason} envelope. createVerificationFetchSession
 * is a thin batch wrapper; close() remains for callers but is now a no-op.
 */

import { Readability } from '@mozilla/readability';
import { parseHTML } from 'linkedom';
import { fetchCongressPageText } from './adapters/congressAdapter.js';

/**
 * Honest user-agent. Names Empowered Vote, links a public policy page, and
 * gives a contact address so a publisher can reach us or ask to be excluded.
 *
 * The product token `EmpoweredVoteBot` is what a site's robots.txt matches on
 * (see the robots parser below), so it must stay stable — do not reword it.
 *
 * Rationale: decision knowledge/decisions/0003-scraping-toolchain.md (rung 0).
 * From 15 Sep 2026 Cloudflare's defaults classify an unlabelled fetcher that
 * pretends to be a desktop browser as "evasive". An honest, contactable UA is
 * both more defensible and more likely to be allowed.
 *
 * Contact address confirmed by the founders (Chris, 2026-09-01): info@empowered.vote.
 *
 * Also re-exported by fetchPageContent.js so existing importers (backend/scripts/*,
 * tests) that pull it from there keep working.
 */
export const EMPOWERED_VOTE_UA =
  'EmpoweredVoteBot/1.0 (+https://empowered.vote/crawler; nonprofit civic citation verification; contact info@empowered.vote)';

/**
 * The robots.txt product token for {@link EMPOWERED_VOTE_UA}. Matching is
 * case-insensitive; kept as a named constant so the fetcher and the UA cannot
 * drift apart.
 */
export const EMPOWERED_VOTE_UA_TOKEN = 'EmpoweredVoteBot';

/**
 * DEPRECATED — a spoofed desktop Chrome user-agent. Kept, exported and UNUSED
 * only so its removal is a deliberate, reviewed act rather than a silent one.
 *
 * 🔴 Do NOT reintroduce this into any live fetch path without a founder
 * decision. Pretending to be a browser is exactly the profile Cloudflare's
 * 15 Sep 2026 defaults target, and it is indefensible for a civic-trust
 * nonprofit bound by a radical-transparency clause. Use {@link EMPOWERED_VOTE_UA}.
 */
export const LEGACY_BROWSER_UA =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36';

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

/** How many of the newest CDX captures to consider (we pick the most recent). */
const CDX_LOOKUP_LIMIT = 5;

/** A `fetch`-shaped seam. Global `fetch` satisfies it; tests pass a fake. */
type FetchLike = (url: string, init?: RequestInit) => Promise<Response>;

/**
 * Injectable seam for the Wayback tier. The default is the real global `fetch`;
 * tests pass a fake so they can assert the id_ raw-snapshot URL is built and
 * that /available is a genuine fallback — without touching the live network.
 */
export interface WaybackDeps {
  fetchImpl?: FetchLike;
}

/**
 * CDX lookup — ask archive.org's index for the MOST RECENT HTTP-200 capture of
 * `url`. This is more complete than the /available endpoint, which
 * intermittently reports "no snapshot" for a URL that is in fact archived
 * (measured on congress.gov bill pages). Returns `{timestamp, original}` of the
 * newest 200 capture, or null when the index has none.
 *
 * `limit=-N` returns the N newest captures (verified against web.archive.org);
 * we still take the max timestamp so an ordering quirk can never pick a stale
 * row. `collapse=digest` drops consecutive byte-identical captures.
 */
async function cdxLatest200(
  url: string,
  fetchImpl: FetchLike,
): Promise<{ timestamp: string; original: string } | null> {
  const noProto = url.replace(/^https?:\/\//, '');
  const cdxUrl =
    'https://web.archive.org/cdx/search/cdx?url=' +
    encodeURIComponent(noProto) +
    '&output=json&filter=statuscode:200&collapse=digest&limit=-' +
    CDX_LOOKUP_LIMIT;
  const res = await fetchImpl(cdxUrl, { signal: AbortSignal.timeout(HTTP_TIMEOUT_MS) });
  if (!res.ok) return null;
  const rows: unknown = await res.json();
  // CDX json is [header, ...rows]; the header names the columns. Fewer than two
  // rows means "no captures".
  if (!Array.isArray(rows) || rows.length < 2 || !Array.isArray(rows[0])) return null;
  const header = (rows[0] as unknown[]).map(String);
  const tsIdx = header.indexOf('timestamp');
  const origIdx = header.indexOf('original');
  if (tsIdx === -1 || origIdx === -1) return null;
  let best: { timestamp: string; original: string } | null = null;
  for (const row of rows.slice(1)) {
    if (!Array.isArray(row)) continue;
    const timestamp = String(row[tsIdx] ?? '');
    const original = String(row[origIdx] ?? '');
    if (!/^\d{14}$/.test(timestamp) || !original) continue;
    if (!best || timestamp > best.timestamp) best = { timestamp, original };
  }
  return best;
}

/**
 * CDX path — find the newest 200 capture, then fetch its RAW archived response.
 * The `id_` suffix on the timestamp returns the original bytes without the
 * archive.org toolbar/rewrite wrapper, so the extractor sees the real document.
 * Returns null on any miss or failure (the caller has already tried /available).
 */
async function fetchViaWaybackCdx(url: string, fetchImpl: FetchLike): Promise<string | null> {
  const hit = await cdxLatest200(url, fetchImpl);
  if (!hit) return null;
  const snapUrl = 'https://web.archive.org/web/' + hit.timestamp + 'id_/' + hit.original;
  const res = await fetchImpl(snapUrl, {
    signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
    headers: { 'user-agent': EMPOWERED_VOTE_UA },
  });
  if (!res.ok) return null;
  // Pass the ORIGINAL url (not the archive wrapper) so the non-article guard in
  // the extractor reasons about the real document.
  const text = htmlToArticleOrText(await res.text(), url);
  return text || null;
}

/**
 * The /available lookup — tier 3's first, cheap attempt (this is exactly the
 * pre-CDX production behaviour). CDX runs only when this does not return a real
 * page, so /available stays the fast common path.
 */
async function fetchViaWaybackAvailable(url: string, fetchImpl: FetchLike): Promise<string | null> {
  const noProto = url.replace(/^https?:\/\//, '');
  let snapUrl: string | undefined;
  try {
    const avail = await fetchImpl(
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
    const res = await fetchImpl(snapUrl!, {
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

/**
 * Tier 3 — closest Wayback Machine snapshot, or null if none/usable.
 *
 * Order: the /available endpoint FIRST (fast — median ~3s on a live sample),
 * then the CDX index only when /available did not yield a real page. This keeps
 * the common recovery path at its old cost while still closing the gap where
 * /available intermittently reports "no snapshot" for a URL that IS archived:
 * a flaky /available miss is still a miss, and CDX catches it (measured to
 * recover archived ballotpedia / congress.gov pages /available dropped). It only
 * ever ADDS recoveries and never removes one. Same 12s timeout, no extra
 * concurrency — one /available call, then at most one CDX index + one raw-
 * snapshot fetch.
 *
 * (Order chosen from a 200-URL before/after measurement: CDX-first added ~9s of
 * latency on the tier-1-miss path when archive.org's CDX server was slow, for
 * the identical recovery. See ev-cto task 2026-09-11-wayback-cdx-tier3.)
 */
export async function fetchViaWayback(url: string, deps: WaybackDeps = {}): Promise<string | null> {
  const fetchImpl: FetchLike = deps.fetchImpl ?? fetch;
  // /available first — cheap, and enough for most archived pages.
  const viaAvailable = await fetchViaWaybackAvailable(url, fetchImpl);
  if (viaAvailable && looksLikeRealPage(viaAvailable)) return viaAvailable;
  // /available missed or returned a non-real page (the flaky endpoint, or an
  // archived challenge shell) — give the more complete CDX index its chance.
  let viaCdx: string | null = null;
  try {
    viaCdx = await fetchViaWaybackCdx(url, fetchImpl);
  } catch {
    /* CDX unreachable / malformed — fall through to /available's best effort. */
  }
  // Prefer a CDX recovery; else return /available's best-effort text (may be thin —
  // the ladder's looksLikeRealPage gate decides whether to keep it), or null.
  return viaCdx ?? viaAvailable ?? null;
}

export interface VerificationFetchSession {
  /** Fetch the best available text for a URL via the ladder. Throws only when every tier fails. */
  fetch(url: string): Promise<string>;
  /** No-op, retained for API compatibility (there is no browser to close). */
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
  /** Tier 3 — Wayback snapshot (archive, not a live-site fetch). */
  wayback?: (url: string) => Promise<string | null>;
  /** Source-specific tier — congress.gov official API. Runs before the generic tiers. */
  congressAdapter?: (url: string) => Promise<string | null>;
}

/**
 * Create a fetch session over the browser-free ladder (tier 1 plain fetch →
 * tier 3 Wayback). Pass `session.fetch` to researchVerifier.createPageFetcher.
 *
 * `close()` is retained for callers (createPageFetcher / fetchForVerification
 * call it) but is now a no-op — there is no browser to tear down.
 */
export function createVerificationFetchSession(
  deps: VerificationFetchDeps = {},
): VerificationFetchSession {
  const allowed = deps.robotsAllows ?? robotsAllows;
  const httpFetch = deps.httpFetch ?? fetchViaHttp;
  const wayback = deps.wayback ?? fetchViaWayback;
  const congressAdapter = deps.congressAdapter ?? fetchCongressPageText;

  return {
    async fetch(url: string): Promise<string> {
      // Source-specific tier — congress.gov official API (before the generic
      // tiers). It calls api.congress.gov under our own key: an authorized
      // official API, not a fetch of the live congress.gov site, so it precedes
      // the robots gate. A null result (not congress.gov, unparseable, no key, or
      // no API match) falls through to today's ladder unchanged.
      try {
        const t = await congressAdapter(url);
        if (t && looksLikeRealPage(t)) return t;
      } catch {
        /* fall through to the generic ladder */
      }

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

      // Tier 3 — Wayback snapshot (the headless-browser rung that once sat
      // between tier 1 and tier 3 was removed; see the module header + decision 0003).
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

    // Retained for API compatibility; there is no browser to close.
    async close() {},
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
