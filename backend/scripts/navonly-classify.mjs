#!/usr/bin/env node
/**
 * Classify each surviving citation as coverage or not, and recompute the remedy split.
 *
 * THE RULE BEING APPLIED is the 2026-08-04 operator ruling, stated properly: a surviving citation counts
 * as coverage only if the page STATES A POSITION ATTRIBUTABLE TO THAT POLITICIAN. Two halves, and the
 * second is the one a URL cannot answer:
 *   1. is it substantive (not an index, agenda list, or search query), and
 *   2. does it actually concern that person?
 *
 * 🔴 WHY NOT A SCORER. Every rule here was derived by reading the fetched pages, not by pattern-guessing,
 * because pattern-guessing on this corpus has over-fired sixteen times. Where a page could not be read
 * it is marked UNVERIFIED and the row is KEPT — the conservative direction. We retire on demonstrated
 * absence, never on a failure to confirm.
 *
 * Verdicts per surviving URL:
 *   COVERAGE      — substantive and about this person. The row survives; strip only the fabricated cite.
 *   NOT_COVERAGE  — index / agenda / minutes / search-result / bill-or-issue page that never names them.
 *   GONE          — 404 or dead domain. Cannot support anything as it stands.
 *   UNVERIFIED    — bot-walled (403) or unreadable. NOT evidence of absence; row kept.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'data', 'stance-retirement');
const argv = process.argv.slice(2);
const PREFIX = (argv.indexOf('--prefix') !== -1 && argv[argv.indexOf('--prefix') + 1]) || 'navonly';
const pages = JSON.parse(readFileSync(path.join(DIR, `${PREFIX}-pages.json`), 'utf8'));
const ws = JSON.parse(readFileSync(path.join(DIR, `${PREFIX}-workset.json`), 'utf8'));

/** A query string is not a source: its content is whatever the index returns today. */
const isSearchUrl = (u) => /[?&](s|q|search|query)=/i.test(u) || /\/search\b/i.test(u);

/**
 * Index pages, detected from the fetched TITLE — but anchored, not searched.
 *
 * 🔴 A BARE /agenda/ SEARCH OVER-FIRES. The first version matched the word anywhere in the title and so
 * killed a real 1,789-word interview with AG Bonta headlined "…Plots a Progressive Health Care Agenda".
 * "Agenda" in the editorial sense is not an agenda page. Require the index word at the START or END of
 * the title, where a CMS puts it ("City Council Agendas and Minutes", "Search Results for …").
 */
const INDEX_TITLE = /^(agendas?|minutes|archives?|calendar|search results|you searched for|directory|index)\b|\b(agendas?( and minutes)?|minutes|archives?|calendar|directory)\s*(\||-|–|$)/i;

/** Soft-404: HTTP 200 with a not-found page. mgaleg.maryland.gov serves these with the title "NotFound". */
const SOFT_404_TITLE = /^(notfound|not found|404|page not found|error)\b/i;

/**
 * Substantive-but-not-about-this-person. Verified by hand: the actonmass.org topic pages carry real prose
 * about a BILL (provisions, history, who killed it) and never name the legislators who cite them —
 * "Chan" appeared to hit until it turned out to be the word "channel". A bill page cannot attribute a
 * position to an individual. Same class as reasoning from a faculty profile or a party platform.
 */
const BILL_OR_ISSUE_PAGE_NOT_NAMING = new Set([
  'https://actonmass.org/safe-communities/',
  'https://actonmass.org/healthy-youth/',
  'https://actonmass.org/medicare-for-all/',
  'https://actonmass.org/prison-moratorium/',
  'https://actonmass.org/abortion-access-act/',
  'https://actonmass.org/stop-wage-theft/',
]);

function classifyUrl(p) {
  if (!p) return { verdict: 'UNVERIFIED', why: 'never fetched' };
  if (p.status === 403 || p.status === 401 || p.status === 429 || p.status === 503) {
    return { verdict: 'UNVERIFIED', why: `HTTP ${p.status} bot wall / throttle — a real server answered; absence NOT shown` };
  }
  if (p.status === 0)   return { verdict: 'GONE', why: 'nothing answered (dead domain)' };
  if (p.status >= 400)  return { verdict: 'GONE', why: `HTTP ${p.status}` };

  if (SOFT_404_TITLE.test(p.title)) return { verdict: 'GONE', why: `soft-404: HTTP 200 with title "${p.title.slice(0, 40)}"` };

  // Search URLs are checked BEFORE the homepage rule: a "?s=" query has an empty pathname, so the
  // homepage rule would swallow it and record the wrong reason for the same verdict. The verdict is not
  // the only output that matters — a wrong reason is what a later reader inherits.
  if (isSearchUrl(p.url))          return { verdict: 'NOT_COVERAGE', why: 'search-result URL — a query, not a source' };

  // A site ROOT is a landing page by definition — this is the 2026-08-04 ruling applied literally
  // (Portland's /mayor, Lowell's /council). oag.ca.gov's homepage names Bonta three times in banner
  // copy ("Taking on Big Oil", "Suing Meta") and states no position attributable to a specific claim.
  // Keep this AFTER the dead/soft-404 checks so a dead root is reported as dead, not as a landing page.
  try {
    const pth = new URL(p.url).pathname.replace(/\/+$/, '');
    if (pth === '') return { verdict: 'NOT_COVERAGE', why: 'site homepage / landing page, not a position statement' };
  } catch { /* unparseable, fall through */ }
  if (INDEX_TITLE.test(p.title))   return { verdict: 'NOT_COVERAGE', why: `index/listing page (title: "${p.title.slice(0, 60)}")` };
  if (BILL_OR_ISSUE_PAGE_NOT_NAMING.has(p.url))
    return { verdict: 'NOT_COVERAGE', why: 'substantive bill page that never names the citing legislator (hand-verified)' };

  // Unreadable but alive: do not guess. A big page that extracts to nothing is an extractor failure.
  if (p.extraction_suspect) return { verdict: 'UNVERIFIED', why: `unreadable (${p.raw_bytes}b raw, ${p.body_words}w extracted) — needs eyes` };

  const hits = Object.values(p.name_hits_in_body ?? {}).reduce((a, b) => a + b, 0);
  if (p.body_words < 120)  return { verdict: 'UNVERIFIED', why: `only ${p.body_words} words extracted — too thin to judge` };
  if (hits === 0)          return { verdict: 'NOT_COVERAGE', why: `substantive (${p.body_words}w) but never names the politician` };
  return { verdict: 'COVERAGE', why: `${p.body_words}w, names the politician ${hits}×` };
}

const urlVerdict = new Map();
for (const w of ws.workset) urlVerdict.set(w.url, { ...classifyUrl(pages[w.url]), url: w.url, rows: w.rows });

const tally = {};
for (const v of urlVerdict.values()) tally[v.verdict] = (tally[v.verdict] ?? 0) + 1;
console.log('=== survivor URLs by verdict ===');
for (const [k, n] of Object.entries(tally).sort((a, b) => b[1] - a[1])) console.log(`  ${k.padEnd(13)} ${n}`);

// ---- recompute the row-level split ----
const split = { SOLE_SOURCED: [], NAV_ONLY: [], HAS_COSOURCE: [], KEPT_UNVERIFIED: [] };
for (const r of ws.rows) {
  if (!r.survivors.length) { split.SOLE_SOURCED.push(r); continue; }
  const vs = r.survivors.map((s) => urlVerdict.get(s)?.verdict ?? 'UNVERIFIED');
  if (vs.includes('COVERAGE'))        split.HAS_COSOURCE.push(r);
  else if (vs.includes('UNVERIFIED')) split.KEPT_UNVERIFIED.push(r);
  else                                split.NAV_ONLY.push(r);
}

console.log('\n=== rows, re-classified BY READING ===');
console.log(`  SOLE_SOURCED     ${String(split.SOLE_SOURCED.length).padStart(4)}  retire — no surviving citation at all`);
console.log(`  NAV_ONLY         ${String(split.NAV_ONLY.length).padStart(4)}  retire — every survivor is an index/search/dead/not-about-them page`);
console.log(`  KEPT_UNVERIFIED  ${String(split.KEPT_UNVERIFIED.length).padStart(4)}  KEEP — a survivor could not be read (bot wall); absence not shown`);
console.log(`  HAS_COSOURCE     ${String(split.HAS_COSOURCE.length).padStart(4)}  keep the row, strip the fabricated citation`);
console.log(`  ---------------- ${String(ws.rows.length).padStart(4)}  total`);

console.log('\n=== NOT_COVERAGE survivors, by rows depending on them ===');
for (const v of [...urlVerdict.values()].filter((x) => x.verdict === 'NOT_COVERAGE').sort((a, b) => b.rows - a.rows).slice(0, 20)) {
  console.log(`  ${String(v.rows).padStart(3)}  ${v.url.slice(0, 76)}\n        ${v.why}`);
}
console.log('\n=== UNVERIFIED survivors (rows kept on these) ===');
for (const v of [...urlVerdict.values()].filter((x) => x.verdict === 'UNVERIFIED').sort((a, b) => b.rows - a.rows).slice(0, 15)) {
  console.log(`  ${String(v.rows).padStart(3)}  ${v.url.slice(0, 76)}\n        ${v.why}`);
}

writeFileSync(path.join(DIR, `${PREFIX}-classification.json`),
  `${JSON.stringify({ generated_by: 'scripts/navonly-classify.mjs',
                      url_verdicts: [...urlVerdict.values()],
                      split: Object.fromEntries(Object.entries(split).map(([k, v]) => [k, v.length])),
                      rows: Object.fromEntries(Object.entries(split).map(([k, v]) =>
                        [k, v.map((r) => ({ politician: r.name, government: r.government, topic_id: r.topic_id, survivors: r.survivors }))])) }, null, 2)}\n`);
console.log(`\nwrote data/stance-retirement/${PREFIX}-classification.json`);
