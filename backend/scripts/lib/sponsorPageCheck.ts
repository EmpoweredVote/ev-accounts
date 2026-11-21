/**
 * Does the page a state's sponsorships are cited on prove a sponsorship? (Stage 5 reader session; any topic.)
 *
 * A sponsorship from Open States data is cited on the legislature's own bill page (`legiscan/sponsor-own-page.json`,
 * written by state_legiscan.py). Two later checks read that page: the gate wants the bill's number in the cited
 * snippet, and the verifier wants the sponsor's name on the page. Neither ran before a real batch, so Nevada, Oregon
 * and Hawaii each met a page that prints no sponsor at recipe step 9 of a live run (2026-11-21: three runner stops,
 * three tool edits mid-run, 13 extra gate runs), and Colorado a page that prints no bill number. The reader session's
 * dry batch had listed those pages every time (81, 428 and 1,266 of them) and nothing read one.
 *
 * This reads a small sample the way the verifier will, and says which page does not carry what the two checks need.
 * It proves nothing about a page it did not sample: the sample is spread over every session and both chambers,
 * because a legislature's old pages are the ones that differ.
 */
import { lastNameOf, normalizeText } from '../../src/lib/researchVerifier.js';
import { canonicalizeInstrumentId, extractInstrumentIdentifiers, officialBillPageIdentifiers } from './stanceGate.js';

/** One line of sponsor-own-page.json: [full name, cited page, instrument id "XX-HB-25-2019", act]. */
export type SponsorRow = [name: string, url: string, instrument: string, act: string];
export interface SponsorPageFault { name: string; url: string; instrument: string; why: 'no-name' | 'no-bill' | 'unreadable'; detail: string }

const parts = (instrument: string) => {
  const m = instrument.match(/^[A-Z]{2}-([A-Z]+)-(\w+?)-(\d{4})$/);
  return m ? { type: m[1], number: m[2], year: m[3] } : { type: '', number: '', year: '' };
};

/**
 * Up to `n` rows, one per page, in an order that does not depend on the input's: sessions and chambers take turns
 * (oldest session first, then newest, then the ones between), and a primary sponsor is preferred, since a page
 * that prints only the first name on the bill fails for everyone else.
 */
export function sampleSponsorPages(rows: SponsorRow[], n: number): SponsorRow[] {
  const byUrl = new Map<string, SponsorRow>();
  for (const r of [...rows].sort((a, b) => (a[3] === 'sponsor' ? 0 : 1) - (b[3] === 'sponsor' ? 0 : 1) || a[1].localeCompare(b[1]) || a[0].localeCompare(b[0]))) {
    if (!byUrl.has(r[1])) byUrl.set(r[1], r);
  }
  const groups = new Map<string, SponsorRow[]>();
  for (const r of byUrl.values()) {
    const p = parts(r[2]); const key = `${p.year} ${p.type}`;
    groups.set(key, [...(groups.get(key) ?? []), r]);
  }
  const keys = [...groups.keys()].sort();
  // oldest, newest, then inward: an old site and the current one are the two most likely to differ
  const order: string[] = [];
  for (let lo = 0, hi = keys.length - 1; lo <= hi; lo++, hi--) { order.push(keys[lo]); if (hi !== lo) order.push(keys[hi]); }
  const out: SponsorRow[] = [];
  for (let round = 0; out.length < n; round++) {
    let took = false;
    for (const k of order) {
      const r = groups.get(k)![round];
      if (r && out.length < n) { out.push(r); took = true; }
    }
    if (!took) break;
  }
  return out;
}

/** What the gate and the verifier will miss on this page, as read. Empty when the page proves the sponsorship. */
export function checkSponsorPage(row: SponsorRow, text: string): SponsorPageFault[] {
  const [name, url, instrument] = row; const out: SponsorPageFault[] = [];
  const page = normalizeText(text);
  const last = normalizeText(lastNameOf(name));
  const esc = last.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  if (!new RegExp(`(^|[^a-z])${esc}([^a-z]|$)`).test(page)) {
    out.push({ name, url, instrument, why: 'no-name', detail: `the page does not print "${lastNameOf(name)}": the verifier will send this sponsorship back for research` });
  }
  const p = parts(instrument);
  const want = canonicalizeInstrumentId(`${p.type} ${p.number}`);
  const printed = new Set([...extractInstrumentIdentifiers(text), ...officialBillPageIdentifiers(url)].map(canonicalizeInstrumentId));
  if (!p.type || !printed.has(want)) {
    out.push({ name, url, instrument, why: 'no-bill', detail: `the page does not print the bill as the gate reads it ("${p.type} ${p.number}"): instrument-not-cited on every row that names it` });
  }
  return out;
}
