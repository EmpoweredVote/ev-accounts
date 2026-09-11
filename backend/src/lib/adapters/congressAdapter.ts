/**
 * congressAdapter — source-specific verification tier for congress.gov.
 *
 * congress.gov 403s a plain fetch (fingerprint-based; spoofing is forbidden by
 * decision 0003 rung 0). Instead of scraping the HTML, this adapter parses a
 * congress.gov bill/member URL and rebuilds the human-visible text from the
 * official api.congress.gov JSON so the deterministic snippet matcher
 * (researchVerifier) can run. It returns null — a clean fall-through to the
 * generic ladder — for anything it does not handle (non-congress host,
 * unparseable path, missing key, or no API match).
 */

import { htmlToText } from '../verificationFetch.js';
import { acquireApiDataGovSlot } from './apiDataGovRateLimiter.js';

export type CongressRef =
  | { kind: 'bill'; congress: number; billType: string; number: number }
  | { kind: 'member'; bioguideId: string };

/** congress.gov bill-type URL slug → api.congress.gov bill-type code. */
const BILL_TYPE_MAP: Map<string, string> = new Map([
  ['house-bill', 'hr'],
  ['senate-bill', 's'],
  ['house-resolution', 'hres'],
  ['senate-resolution', 'sres'],
  ['house-joint-resolution', 'hjres'],
  ['senate-joint-resolution', 'sjres'],
  ['house-concurrent-resolution', 'hconres'],
  ['senate-concurrent-resolution', 'sconres'],
]);

const BIOGUIDE_RE = /^[A-Z]\d{6}$/;

/**
 * Parse a congress.gov URL into an API reference, or null when it is not a
 * bill/member page we can serve from the API. Bill sub-paths (/cosponsors,
 * /text, /all-actions, /all-info) resolve to the same bill ref — the adapter
 * builds one rich composite regardless of which sub-page was cited.
 */
export function parseCongressUrl(url: string): CongressRef | null {
  let u: URL;
  try {
    u = new URL(url);
  } catch {
    return null;
  }
  const host = u.hostname.toLowerCase();
  if (host !== 'congress.gov' && host !== 'www.congress.gov') return null;

  const seg = u.pathname.split('/').filter(Boolean);

  // /bill/<congress-slug>/<type-slug>/<number>[/<subpath>...]
  if (seg[0] === 'bill' && seg.length >= 4) {
    const congress = parseInt(seg[1], 10); // "119th-congress" → 119
    const billType = BILL_TYPE_MAP.get(seg[2]);
    const number = parseInt(seg[3], 10);
    if (Number.isFinite(congress) && billType && Number.isFinite(number)) {
      return { kind: 'bill', congress, billType, number };
    }
    return null;
  }

  // /member/<name-slug>/<bioguideId> or /member/<bioguideId>
  if (seg[0] === 'member' && seg.length >= 2) {
    const last = seg[seg.length - 1];
    if (BIOGUIDE_RE.test(last)) return { kind: 'member', bioguideId: last };
    return null;
  }

  return null; // /event, /congressional-record, /committee, /amendment, /nomination, …
}

export type FetchLike = (url: string, init?: RequestInit) => Promise<Response>;

export interface CongressDeps {
  fetchImpl?: FetchLike;
  apiKey?: string;
}

const API_BASE = 'https://api.congress.gov/v3';
/** How many of the newest actions to include (latest action is already shown). */
const MAX_ACTIONS = 15;

/**
 * GET a v3 JSON resource with the key + format appended. Acquires a rate-limit
 * slot first. Returns parsed JSON, or null on any non-2xx / error (best-effort:
 * a missing sub-resource must not fail the whole composite).
 */
async function getJson(path: string, apiKey: string, fetchImpl: FetchLike): Promise<any | null> {
  const sep = path.includes('?') ? '&' : '?';
  const url = `${API_BASE}${path}${sep}format=json&api_key=${encodeURIComponent(apiKey)}`;
  try {
    await acquireApiDataGovSlot('congress');
    const res = await fetchImpl(url);
    if (!res.ok) return null;
    return await res.json();
  } catch {
    return null;
  }
}

/** Fetch and strip a bill's newest text version (best-effort). */
async function fetchBillText(
  base: string, apiKey: string, fetchImpl: FetchLike,
): Promise<string | null> {
  // Wrapped end-to-end: a 200 response with an unexpected shape (e.g.
  // textVersions not an array) must degrade to "no bill text", never throw
  // out of the composite.
  try {
    const data = await getJson(`${base}/text`, apiKey, fetchImpl);
    const versions: any[] = Array.isArray(data?.textVersions) ? data.textVersions : [];
    // Prefer a "Formatted Text" (HTML) format; else the first format with a URL.
    let target: string | undefined;
    for (const v of versions) {
      const formats: any[] = Array.isArray(v?.formats) ? v.formats : [];
      const html = formats.find((f) => /formatted text/i.test(f?.type ?? '') && f?.url);
      if (html) { target = html.url; break; }
      if (!target && formats[0]?.url) target = formats[0].url;
    }
    if (!target) return null;
    await acquireApiDataGovSlot('congress');
    const res = await fetchImpl(target);
    if (!res.ok) return null;
    const body = await res.text();
    const text = htmlToText(body);
    return text || null;
  } catch {
    return null;
  }
}

async function buildBillText(
  ref: Extract<CongressRef, { kind: 'bill' }>, apiKey: string, fetchImpl: FetchLike,
): Promise<string | null> {
  const base = `/bill/${ref.congress}/${ref.billType}/${ref.number}`;
  const main = await getJson(base, apiKey, fetchImpl);
  const bill = main?.bill;
  if (!bill) return null; // no overview → nothing to verify against; fall through

  const parts: string[] = [];
  if (bill.title) parts.push(String(bill.title));
  if (bill.policyArea?.name) parts.push(`Policy area: ${bill.policyArea.name}`);
  const sponsors: any[] = Array.isArray(bill.sponsors) ? bill.sponsors : [];
  if (sponsors.length) parts.push('Sponsor: ' + sponsors.map((s) => s?.fullName).filter(Boolean).join(', '));
  if (bill.latestAction?.text) parts.push('Latest action: ' + bill.latestAction.text);

  const summaries = await getJson(`${base}/summaries`, apiKey, fetchImpl);
  const summaryList: any[] = Array.isArray(summaries?.summaries) ? summaries.summaries : [];
  for (const s of summaryList) {
    if (s?.text) parts.push(htmlToText(String(s.text)));
  }

  const cosponsors = await getJson(`${base}/cosponsors`, apiKey, fetchImpl);
  const cosponsorList: any[] = Array.isArray(cosponsors?.cosponsors) ? cosponsors.cosponsors : [];
  const coNames = cosponsorList.map((c: any) => c?.fullName).filter(Boolean);
  if (coNames.length) parts.push('Cosponsors: ' + coNames.join(', '));

  const actions = await getJson(`${base}/actions`, apiKey, fetchImpl);
  const actionList: any[] = Array.isArray(actions?.actions) ? actions.actions : [];
  const actionTexts = actionList.slice(0, MAX_ACTIONS).map((a: any) => a?.text).filter(Boolean);
  if (actionTexts.length) parts.push('Actions: ' + actionTexts.join(' '));

  const billText = await fetchBillText(base, apiKey, fetchImpl); // best-effort
  if (billText) parts.push(billText);

  const out = parts.join('\n\n').trim();
  return out || null;
}

async function buildMemberText(
  ref: Extract<CongressRef, { kind: 'member' }>, apiKey: string, fetchImpl: FetchLike,
): Promise<string | null> {
  const main = await getJson(`/member/${ref.bioguideId}`, apiKey, fetchImpl);
  const m = main?.member;
  if (!m) return null;
  const parts: string[] = [];
  const name = m.directOrderName ?? m.invertedOrderName ?? m.name;
  if (name) parts.push(String(name));
  const partyHistory: any[] = Array.isArray(m.partyHistory) ? m.partyHistory : [];
  const party = partyHistory.map((p: any) => p?.partyName).filter(Boolean).join(', ');
  if (party) parts.push(`Party: ${party}`);
  if (m.state) parts.push(`State: ${m.state}`);
  const terms: any[] = Array.isArray(m.terms) ? m.terms : [];
  const chambers = terms.map((t: any) => t?.chamber).filter(Boolean);
  if (chambers.length) parts.push(`Chamber: ${[...new Set(chambers)].join(', ')}`);
  const out = parts.join('\n\n').trim();
  return out || null;
}

/**
 * Build plain-text for a congress.gov URL from the official API, or null when it
 * cannot (not a congress.gov bill/member, no key, or no API match). A null
 * result is the ladder's signal to fall through to the generic tiers.
 */
export async function fetchCongressPageText(url: string, deps: CongressDeps = {}): Promise<string | null> {
  const ref = parseCongressUrl(url);
  if (!ref) return null;
  const apiKey = deps.apiKey ?? process.env.CONGRESS_GOV_API_KEY;
  if (!apiKey) return null; // no-op: adapter degrades, URL falls through to the ladder
  const fetchImpl = deps.fetchImpl ?? fetch;
  return ref.kind === 'bill'
    ? buildBillText(ref, apiKey, fetchImpl)
    : buildMemberText(ref, apiKey, fetchImpl);
}
