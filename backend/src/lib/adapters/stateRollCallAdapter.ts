/**
 * stateRollCallAdapter — source-specific verification tier for a legislature's own roll-call page
 * (stateRollCallEvidence.ts lists the page layouts it knows; Utah's le.utah.gov/DynaBill/svotes.jsp so far).
 *
 * The plain tier would flatten the page to text, where the members' labels run together and nothing ties a
 * label to a vote. This tier reads the page's markup and returns the fixed, party-free render of
 * stateRollCallEvidence.ts, against which a canonical vote line verifies.
 *
 * It returns null (a clean fall-through to the generic ladder) for any other URL and when the page cannot be
 * fetched. A page that was fetched but does not read cleanly fails closed in the reader: the caller gets its
 * plain text, against which no vote line can verify.
 *
 * The site is public; there is no key. The fetch uses the caller's honest user-agent and is placed AFTER the
 * robots.txt gate in verificationFetch.ts, like any live fetch of a public site.
 */
import { isStateRollCallUrl, readStateRollCallHtml, renderStateRollCall, stateRollCallMinGapMs } from '../stateRollCallEvidence.js';

export type FetchLike = (url: string, init?: RequestInit) => Promise<Response>;
export interface StateRollCallDeps {
  fetchImpl?: FetchLike;
  userAgent?: string;
  /** Decode the body by its declared charset (verificationFetch.decodeHtmlBytes); UTF-8 when not given. */
  decode?: (buf: Uint8Array, contentType: string) => string;
  /**
   * Markup -> plain text (verificationFetch.htmlToText). When given, a page that was fetched but did not read as
   * a roll call is returned as its plain text, so the caller does not ask the site for the same page a second
   * time inside its crawl delay. No vote line verifies against plain text.
   */
  toText?: (html: string) => string;
  /** Injectable clock and wait, for tests. */
  now?: () => number;
  sleep?: (ms: number) => Promise<void>;
}

/** When each host was last asked, so two requests to one site are never closer than its Crawl-delay. */
const lastAsked = new Map<string, number>();
/** How often a "429 Too Many Requests" (or a 503) is waited out before giving up, and the longest single wait. */
const MAX_RETRIES = 2;
const MAX_BACKOFF_MS = 60_000;

/** Forget the pacing state (tests). */
export function resetStateRollCallPacing(): void {
  lastAsked.clear();
}

const HTTP_TIMEOUT_MS = 20_000;

/** The render of a legislature's roll-call page, or null (not one, unreachable, or unreadable). */
export async function fetchStateRollCallText(url: string, deps: StateRollCallDeps = {}): Promise<string | null> {
  if (!isStateRollCallUrl(url)) return null;
  const now = deps.now ?? Date.now;
  const sleep = deps.sleep ?? ((ms: number) => new Promise<void>((r) => setTimeout(r, ms)));
  const host = new URL(url.trim()).host;
  const gap = stateRollCallMinGapMs(url);
  let html: string;
  try {
    let res: Response;
    for (let attempt = 0; ; attempt++) {
      // Pace by the site's Crawl-delay. Utah, 2026-11-15: 25 pages asked for without a pause drew
      // "429 Too Many Requests" on 10 of them, and a refused page falls through to plain text, which
      // verifies no vote: a real vote would have read as unverifiable.
      const wait = (lastAsked.get(host) ?? -Infinity) + gap - now();
      if (wait > 0) await sleep(wait);
      lastAsked.set(host, now());
      res = await (deps.fetchImpl ?? fetch)(url.trim(), {
        redirect: 'follow',
        signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
        headers: { ...(deps.userAgent ? { 'user-agent': deps.userAgent } : {}), accept: 'text/html' },
      });
      if ((res.status !== 429 && res.status !== 503) || attempt >= MAX_RETRIES) break;
      const asked = Number(res.headers.get('retry-after'));
      await sleep(Math.min(MAX_BACKOFF_MS, Math.max(gap, Number.isFinite(asked) && asked > 0 ? asked * 1000 : 30_000)));
    }
    if (!res.ok) return null;
    const buf = new Uint8Array(await res.arrayBuffer());
    html = deps.decode ? deps.decode(buf, res.headers.get('content-type') ?? '') : new TextDecoder('utf-8').decode(buf);
  } catch {
    return null;
  }
  const render = renderStateRollCallHtml(html, url);
  if (render) return render;
  const plain = deps.toText?.(html).trim();
  return plain || null;
}

/** Render markup already in hand (a batch tool reads a saved copy through this). */
export function renderStateRollCallHtml(html: string, url: string): string | null {
  const r = readStateRollCallHtml(html, url);
  return r ? renderStateRollCall(r) : null;
}
