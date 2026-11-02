/**
 * igaAdapter — source-specific verification tier for the Indiana General Assembly (iga.in.gov).
 *
 * iga.in.gov is a JavaScript app: to a plain fetch every page, PDF and JSON file is a 691-byte "enable
 * JavaScript" shell. Spoofing a browser is forbidden (decision 0003 rung 0). The sanctioned channel is
 * the MyIGA public API (docs.api.iga.in.gov/usage.html), which asks every client to send its token in
 * the `x-api-key` header AND as `User-Agent: iga-api-client-<token>`. That identity is the state's own
 * rule, not a disguise. With it, the API serves bill and legislator records as JSON, and its
 * `?format=pdf` links redirect to the same iga.in.gov/pdf-documents files a reader opens.
 *
 * This adapter turns a cited iga.in.gov URL into the text the verifier matches against:
 *   - a roll-call PDF        → the fixed, party-free render of igaRollCallEvidence.ts (members by vote);
 *   - any other PDF document → its extracted text (bill versions, amendments, fiscal notes);
 *   - a bill page            → title, digest, authors and sponsors, actions and roll-call totals;
 *   - a legislator page      → name, chamber, district and the bills they authored or sponsored.
 * It returns null — a clean fall-through to the generic ladder — for anything else, and when
 * IGA_API_KEY is unset.
 *
 * 🔴 The token travels in two headers, so: requests go only to iga.in.gov and api.iga.in.gov, over
 * https; redirects are followed by hand and only to those hosts; no error message, log line or
 * returned text ever carries a URL with the token or the headers.
 *
 * 🔴 Antipartisan rule: API person records carry `party` / `partyid`. Nothing here prints one: names are
 * built from first and last name fields, never copied from a whole record.
 *
 * Rate limits: the API answers HTTP 429 when pressed. Calls are spaced (MIN_INTERVAL_MS) and a 429 is
 * retried after Retry-After (capped), up to MAX_TRIES.
 */
import { extractPdfItems, extractPdfText, looksLikePdfBytes } from '../pdfText.js';
import { parseIgaRollCallUrl, readIgaRollCall, renderIgaRollCall } from '../igaRollCallEvidence.js';

export type IgaRef =
  | { kind: 'pdf'; url: string }
  | { kind: 'bill'; session: string; bill: string }
  | { kind: 'legislator'; session: string; slug: string };

const HOSTS = new Set(['iga.in.gov', 'api.iga.in.gov']);
export const API_BASE = 'https://api.iga.in.gov';
const API = API_BASE;
const CHAMBER_PREFIX: Record<string, string> = { house: 'H', senate: 'S' };
const KIND_LETTER: Record<string, string> = { bills: 'B', resolutions: 'R', 'concurrent-resolutions': 'C', 'joint-resolutions': 'J' };

/**
 * Parse an iga.in.gov URL a researcher cited. Null for out-of-scope pages (video, calendars) and for
 * api.iga.in.gov addresses: a citation must be a page a reader can open without a token.
 */
export function parseIgaUrl(url: string): IgaRef | null {
  let u: URL;
  try { u = new URL(url.trim()); } catch { return null; }
  if (u.protocol !== 'https:' || u.hostname.toLowerCase() !== 'iga.in.gov') return null;
  const seg = u.pathname.split('/').filter(Boolean);
  if (seg[0] === 'pdf-documents' && /\.pdf$/i.test(u.pathname)) return { kind: 'pdf', url: `https://iga.in.gov${u.pathname}` };
  if (seg[0] !== 'legislative' || !/^\d{4}(ss\d)?$/i.test(seg[1] ?? '')) return null;
  const session = seg[1].toLowerCase();
  // /legislative/2025/bills/senate/10[/details]
  if (KIND_LETTER[seg[2]] && CHAMBER_PREFIX[seg[3]] && /^\d+$/.test(seg[4] ?? '')) {
    return { kind: 'bill', session, bill: `${CHAMBER_PREFIX[seg[3]]}${KIND_LETTER[seg[2]]}${seg[4].padStart(4, '0')}` };
  }
  // /legislative/2025/legislators/legislator_scott_alexander_1
  if (seg[2] === 'legislators' && /^legislator_[a-z0-9_]+$/i.test(seg[3] ?? '')) {
    return { kind: 'legislator', session, slug: seg[3].replace(/^legislator_/i, '').toLowerCase() };
  }
  return null;
}

export type FetchLike = (url: string, init?: RequestInit) => Promise<Response>;
export interface IgaDeps {
  fetchImpl?: FetchLike;
  apiKey?: string;
  /** Test hook: replaces the wait between calls and before a 429 retry. */
  sleep?: (ms: number) => Promise<void>;
}

const HTTP_TIMEOUT_MS = 12_000;
const MIN_INTERVAL_MS = 250;
const MAX_TRIES = 3;
const MAX_RETRY_AFTER_MS = 30_000;
const MAX_REDIRECTS = 3;
let lastCall = 0;

const defaultSleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

/** The two headers the MyIGA API asks for. Never log the result. */
export function igaHeaders(apiKey: string): Record<string, string> {
  return { 'x-api-key': apiKey, 'User-Agent': `iga-api-client-${apiKey}` };
}

/** True for an https URL on iga.in.gov or api.iga.in.gov: the only places the token may go. */
export function isIgaHost(url: string): boolean {
  try { const u = new URL(url); return u.protocol === 'https:' && HOSTS.has(u.hostname.toLowerCase()); } catch { return false; }
}

/**
 * GET with the token, spaced and retried on 429, following redirects by hand and only between the two
 * IGA hosts. Null on any failure; never throws, never reports the URL.
 */
export async function igaGet(url: string, accept: string, deps: IgaDeps = {}): Promise<Response | null> {
  const apiKey = deps.apiKey ?? process.env.IGA_API_KEY;
  if (!apiKey) return null;
  const fetchImpl = deps.fetchImpl ?? fetch;
  const sleep = deps.sleep ?? defaultSleep;
  let target = url;
  for (let hop = 0; hop <= MAX_REDIRECTS; hop++) {
    if (!isIgaHost(target)) return null;
    let res: Response | null = null;
    for (let attempt = 1; attempt <= MAX_TRIES; attempt++) {
      const wait = lastCall + MIN_INTERVAL_MS - Date.now();
      if (wait > 0) await sleep(wait);
      lastCall = Date.now();
      try {
        res = await fetchImpl(target, {
          headers: { ...igaHeaders(apiKey), Accept: accept },
          redirect: 'manual',
          signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
        });
      } catch {
        return null;
      }
      if (res.status !== 429) break;
      const ra = Number(res.headers.get('retry-after'));
      if (attempt < MAX_TRIES) await sleep(Math.min(Number.isFinite(ra) && ra > 0 ? ra * 1000 : 2000 * attempt, MAX_RETRY_AFTER_MS));
    }
    if (!res) return null;
    if (res.status >= 300 && res.status < 400) {
      const loc = res.headers.get('location');
      if (!loc) return null;
      try { target = new URL(loc, target).toString(); } catch { return null; }
      continue;
    }
    return res.ok ? res : null;
  }
  return null;
}

/**
 * Where an API link redirects, without reading the body: the documented way from an API record
 * (`…?format=pdf`) to the public iga.in.gov file a reader opens. Null unless it redirects to an IGA host.
 */
export async function igaRedirectTarget(url: string, deps: IgaDeps = {}): Promise<string | null> {
  const apiKey = deps.apiKey ?? process.env.IGA_API_KEY;
  if (!apiKey || !isIgaHost(url)) return null;
  const sleep = deps.sleep ?? defaultSleep;
  const wait = lastCall + MIN_INTERVAL_MS - Date.now();
  if (wait > 0) await sleep(wait);
  lastCall = Date.now();
  try {
    const res = await (deps.fetchImpl ?? fetch)(url, { headers: igaHeaders(apiKey), redirect: 'manual', signal: AbortSignal.timeout(HTTP_TIMEOUT_MS) });
    await res.body?.cancel().catch(() => {});
    const loc = res.status >= 300 && res.status < 400 ? res.headers.get('location') : null;
    if (!loc) return null;
    const target = new URL(loc, url).toString();
    return isIgaHost(target) ? target : null;
  } catch {
    return null;
  }
}

async function getJson(path: string, deps: IgaDeps): Promise<any | null> {
  const res = await igaGet(`${API}${path}`, 'application/json', deps);
  if (!res) return null;
  try { return await res.json(); } catch { return null; }
}

/** "Senator Blake Doriot" from the name fields only (the record also holds a party, never printed). */
function personName(p: any): string | null {
  const first = String(p?.firstName ?? p?.firstname ?? '').trim();
  const last = String(p?.lastName ?? p?.lastname ?? '').trim();
  if (!last) return null;
  const title = String(p?.position_title ?? '').trim();
  return [title, first, last].filter(Boolean).join(' ');
}
const names = (list: any): string[] => (Array.isArray(list) ? list.map(personName).filter((n): n is string => !!n) : []);
/** "SB0010" → "SB 10". */
const displayBill = (b: string): string => b.replace(/^([A-Z]{2})0*(\d+)$/, '$1 $2');

async function buildPdfText(url: string, deps: IgaDeps): Promise<string | null> {
  const res = await igaGet(url, 'application/pdf', deps);
  if (!res) return null;
  let buf: Uint8Array;
  try { buf = new Uint8Array(await res.arrayBuffer()); } catch { return null; }
  if (!looksLikePdfBytes(buf)) return null;
  try {
    const rc = parseIgaRollCallUrl(url);
    if (rc) {
      const r = readIgaRollCall(await extractPdfItems(buf), rc.session);
      // A roll call that does not read cleanly falls back to its plain text: it still serves an
      // ordinary snippet, but no vote line can verify against it.
      if (r && r.chamber === rc.chamber && r.rollNum === rc.rollNum) return renderIgaRollCall(r);
    }
    return (await extractPdfText(buf)) || null;
  } catch {
    return null;
  }
}

async function buildBillText(ref: Extract<IgaRef, { kind: 'bill' }>, deps: IgaDeps): Promise<string | null> {
  const base = `/${ref.session}/bills/${ref.bill.toLowerCase()}`;
  const b = await getJson(base, deps);
  if (!b?.billName) return null;
  const v = b.latestVersion ?? {};
  const parts: string[] = [`${displayBill(String(b.billName))} (${ref.session}): ${v.shortDescription || b.description || ''}`.trim()];
  if (b.title) parts.push(String(b.title));
  if (v.digest) parts.push(`Digest: ${String(v.digest).replace(/\s+/g, ' ').trim()}`);
  for (const [label, key] of [['Authors', 'authors'], ['Coauthors', 'coauthors'], ['Sponsors', 'sponsors'], ['Cosponsors', 'cosponsors']] as const) {
    const n = names(b[key]);
    if (n.length) parts.push(`${label}: ${n.join(', ')}`);
  }
  const acts = await getJson(`${base}/actions`, deps);
  const items: any[] = Array.isArray(acts?.items) ? acts.items : [];
  const lines = items
    .filter((a) => a?.description)
    .sort((a, c) => String(a.date ?? '').localeCompare(String(c.date ?? '')))
    .map((a) => `${String(a.date ?? '').slice(0, 10)} ${a.chamber?.name ?? ''}: ${String(a.description).trim()}`.replace(/\s+/g, ' ').trim());
  if (lines.length) parts.push('Actions:\n' + lines.join('\n'));
  const rcs: any[] = Array.isArray(b.all_rollcalls) ? b.all_rollcalls : [];
  const rcLines = rcs
    .filter((r) => r?.rollcall_number && r?.results)
    .map((r) => `${r.chamber?.name ?? ''} roll call ${r.rollcall_number}: ${r.target ?? ''} yea ${r.results.yea ?? '?'}, nay ${r.results.nay ?? '?'}`.trim());
  if (rcLines.length) parts.push('Roll calls:\n' + rcLines.join('\n'));
  return parts.join('\n\n').trim() || null;
}

async function buildLegislatorText(ref: Extract<IgaRef, { kind: 'legislator' }>, deps: IgaDeps): Promise<string | null> {
  const base = `/${ref.session}/legislators/${ref.slug}`;
  const m = await getJson(base, deps);
  const name = personName(m);
  if (!m || !name) return null; // the API answers an unknown slug with an all-empty record
  const parts: string[] = [name];
  if (m.chamber?.name) parts.push(`Chamber: ${m.chamber.name}`);
  if (m.district) parts.push(String(m.district));
  for (const [label, which] of [['Authored', 'authored'], ['Coauthored', 'coauthored'], ['Sponsored', 'sponsored'], ['Cosponsored', 'cosponsored']] as const) {
    const list = await getJson(`${base}/bills/${which}`, deps);
    const items: any[] = Array.isArray(list?.items) ? list.items : [];
    const bills = items.filter((x) => x?.billName).map((x) => `${displayBill(String(x.billName))}: ${String(x.description ?? '').trim()}`.trim());
    if (bills.length) parts.push(`${label} bills (${ref.session}):\n` + bills.join('\n'));
  }
  return parts.join('\n\n').trim() || null;
}

/**
 * Text for a cited iga.in.gov URL, from the official API, or null when it cannot (not an IGA page we
 * handle, no key, or no API match). Null is the ladder's signal to fall through to the generic tiers.
 */
export async function fetchIgaPageText(url: string, deps: IgaDeps = {}): Promise<string | null> {
  const ref = parseIgaUrl(url);
  if (!ref) return null;
  if (!(deps.apiKey ?? process.env.IGA_API_KEY)) return null;
  if (ref.kind === 'pdf') return buildPdfText(ref.url, deps);
  if (ref.kind === 'bill') return buildBillText(ref, deps);
  return buildLegislatorText(ref, deps);
}
