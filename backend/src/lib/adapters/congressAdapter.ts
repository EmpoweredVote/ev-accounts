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
