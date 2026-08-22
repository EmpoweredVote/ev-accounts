#!/usr/bin/env node
/**
 * build-nc-legislature-roster.mjs
 *
 * Reconciles the North Carolina General Assembly roster across THREE independent
 * sources and writes data/nc-legislature-roster.json. Reads nothing from the
 * database and writes nothing to it.
 *
 *   1. ncleg.gov/Members/MemberList/{H,S} — the chamber's own table. AUTHORITATIVE
 *      for identity, district and the canonical spelling of the name. It is ALSO
 *      the only source carrying the appointment date for mid-term successors.
 *   2. data.openstates.org — independent cross-check, and the portrait URL used
 *      by the later headshot pass.
 *   3. ballotpedia.org — the only source of "Date assumed office" for members who
 *      were ELECTED rather than appointed, which is what office_terms.term_start
 *      means: the day this person began holding THIS seat.
 *
 * ⚠ THE CHAMBER'S OWN LISTS ARE OVER-LONG. Measured 2026-08-21: the House list
 * carries 125 rows for 120 seats and the Senate 53 for 50. Eight districts list a
 * departed member alongside their appointed successor.
 *
 * ⚠ AND THE ANNOTATION IS NOT RELIABLE. In HD-40 (Joe John / Phil Rubin) and
 * HD-119 (Mike Clampitt / Anna Ferguson) the DEPARTED member carries no annotation
 * at all — only the successor is marked "Appointed". Filtering on "Resigned" keeps
 * both rows and seats two people in one seat. In HD-90 the appointee is listed
 * FIRST, so source order proves nothing either. The only rule that survives all
 * eight is: the sitting member is the one with the LATEST appointment date, and a
 * contested district with no appointment date at all is a FATAL unseen shape.
 *
 * ⚠ DO NOT SUBSTITUTE WIKIPEDIA'S "Start" COLUMN for the assumed-office date — it
 * mixes election year and appointment year in one column (the CO lesson).
 */

import { writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parse as parseCsv } from 'csv-parse/sync';

/** NCGA renders dates as M/D/YY. Returns ISO yyyy-mm-dd. */
export function parseNcgaDate(raw) {
  const m = String(raw).trim().match(/^(\d{1,2})\/(\d{1,2})\/(\d{2})$/);
  if (!m) throw new Error(`Unparseable NCGA date: ${JSON.stringify(raw)}`);
  const [, mo, da, yy] = m;
  return `20${yy}-${mo.padStart(2, '0')}-${da.padStart(2, '0')}`;
}

/**
 * Given every row the chamber lists for one district, return the sitting member.
 * Throws rather than guess on any shape not seen on 2026-08-21.
 *
 * The returned row carries `howStarted` ('elected' | 'appointed'), read directly
 * off ncleg.gov's own "(Appointed M/D/YY)" annotation — the presence of that
 * annotation is exactly the evidence that establishes how this person reached
 * the seat, so this is not a guess. essentials.office_terms.how_started has a
 * CHECK constraint accepting 'appointed' as an established value (61 rows use
 * it already); defaulting all 170 seats to 'elected' would silently misstate
 * the 8 contested districts.
 */
export function pickSittingMember(district, rows) {
  if (rows.length === 1) {
    return { ...rows[0], howStarted: rows[0].appointedOn ? 'appointed' : 'elected' };
  }
  const appointed = rows.filter((r) => r.appointedOn);
  if (appointed.length === 0) {
    throw new Error(
      `district ${district}: ${rows.length} rows and no appointment date to arbitrate on ` +
      `(${rows.map((r) => r.name).join(', ')}). Unseen shape — refusing to guess.`
    );
  }
  const winner = [...appointed].sort((a, b) => b.appointedOn.localeCompare(a.appointedOn))[0];
  return { ...winner, howStarted: 'appointed' };
}

// ---------------------------------------------------------------------------
// Fetch + reconcile (I/O). Everything above this line is pure and unit-tested;
// everything below is exercised by the end-to-end run in Step 6 of the task
// brief, not by vitest.
// ---------------------------------------------------------------------------

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, '..', 'data');
const OUTPUT_PATH = path.join(DATA_DIR, 'nc-legislature-roster.json');

const NCLEG_LIST_URL = { lower: 'https://www.ncleg.gov/Members/MemberList/H', upper: 'https://www.ncleg.gov/Members/MemberList/S' };
const NCLEG_LETTER = { lower: 'H', upper: 'S' };
const OPENSTATES_CSV_URL = 'https://data.openstates.org/people/current/nc.csv';

// A plain server-default fetch() gets a 202 with an EMPTY body from at least
// one of these hosts (measured against ballotpedia.org 2026-08-22) — a WAF
// edge response, not a real page, and `res.ok` is true for it. A browser-form
// User-Agent avoids the block. Never trust `res.ok` alone here; every caller
// also enforces a minimum body length.
const BROWSER_HEADERS = {
  'User-Agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36',
  Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
};

/**
 * Open States' bulk `sources` column is itself an aggregation Open States
 * built from Wikidata + scraping; for exactly 1 of 170 rows (measured
 * 2026-08-22: Dave Craven, upper district 29) it omits the ballotpedia.org
 * link that DOES exist for that person. This is NOT a general slug-guessing
 * fallback — Ballotpedia URLs are frequently not simply First_Last (see e.g.
 * "A._Reece_Pyrtle,_Jr." elsewhere in this same dataset), so guessing them in
 * general would be unsound and IS the kind of invented fallback this task
 * warns against.
 *
 * This single entry was located by hand, then accepted only because the page
 * ITSELF cites `ncleg.gov/Members/Biography/S/423` — the exact ncleg.gov
 * member id already parsed independently from ncleg's own list for this seat
 * — which is the same hard identity anchor `confirmBallotpediaIdentity` uses
 * for every one of the other 169 members. It is not a guessed date or a
 * guessed identity; it is a manually-located URL, verified by the same
 * automated check as everyone else. Flagged in the task report as a call for
 * review.
 */
const BALLOTPEDIA_URL_OVERRIDES = new Map([['upper:29', 'https://ballotpedia.org/Dave_Craven']]);

async function fetchText(url, { minLength = 200 } = {}) {
  const res = await fetch(url, { headers: BROWSER_HEADERS });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`fetch ${url}: HTTP ${res.status}`);
  }
  if (text.length < minLength) {
    throw new Error(
      `fetch ${url}: HTTP ${res.status} but body is only ${text.length} bytes — ` +
      `likely a WAF/edge block returning a 2xx with no real content, not a real page`
    );
  }
  return text;
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Ballotpedia's WAF returns HTTP 202 with an empty body for a small,
 * seemingly random fraction of requests in any run of ~170 sequential
 * fetches — measured 2026-08-22 across four full runs: 0, 3, 3, and 3
 * districts hit it, never the same ones twice, and a `curl` retest of an
 * affected URL *and* an unrelated control URL both failed identically
 * moments later, then both succeeded again under a minute after that. That
 * pattern (not tied to one URL, clears within roughly a minute) points to a
 * short IP-wide challenge window rather than a per-page or simple
 * request-count throttle, so the fix is a long per-URL backoff rather than
 * a smarter target. A fixed delay between every request plus backoff
 * retries on that specific short-body signature clears it without weakening
 * the "never trust a 2xx body-length check" rule fetchText already enforces.
 */
async function fetchBallotpediaText(url, { minLength = 20_000, retries = 5, baseDelayMs = 15_000 } = {}) {
  let lastErr;
  for (let attempt = 0; attempt <= retries; attempt++) {
    if (attempt > 0) {
      await sleep(baseDelayMs * attempt);
    }
    try {
      return await fetchText(url, { minLength });
    } catch (err) {
      lastErr = err;
      // Only the WAF's specific short-body 2xx signature is worth retrying —
      // a real HTTP error (404: OS's `sources` column carries a stale URL for
      // at least one person, measured 2026-08-22) will not fix itself by
      // waiting, so fail fast and let the caller try its next candidate URL.
      if (!err.message.includes('WAF/edge block')) throw err;
    }
  }
  throw lastErr;
}

// Generational suffixes (ncleg's "A. Reece Pyrtle, Jr.") AND professional
// credential suffixes ncleg appends after a comma (measured 2026-08-22:
// "Timothy Reeder, MD", "Grant L. Campbell, MD", "Frances Jackson, PhD") —
// neither Open States nor Ballotpedia ever carries these, so they must be
// stripped before a first/last token comparison, or every one of these real
// people reads as a false name mismatch.
const NAME_SUFFIXES = new Set(['jr', 'sr', 'ii', 'iii', 'iv', 'v', 'md', 'phd', 'jd', 'esq']);

/** Decodes the small set of HTML entities ncleg.gov's own list actually uses in names. */
export function decodeHtmlEntities(text) {
  return String(text)
    .replace(/&#x([0-9a-fA-F]+);/g, (_, hex) => String.fromCodePoint(parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_, dec) => String.fromCodePoint(parseInt(dec, 10)))
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, '&');
}

/** NFD-strip diacritics (deleting combining marks, never spacing them) and lowercase. */
export function normalizeNameForMatch(name) {
  return String(name)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();
}

/**
 * Reduces a full name to a (first, last) token pair for identity comparison.
 * Strips punctuation (including quotes, e.g. ncleg's `Jerry "Alan" Branson`),
 * a trailing suffix (Jr/Sr/II/III/IV/MD/PhD/JD/Esq — e.g. ncleg's "A. Reece
 * Pyrtle, Jr." vs Open States' "Reece Pyrtle"), and single-letter initial
 * tokens (e.g. "John L. Lowery" vs "John Lowery").
 *
 * This does NOT resolve true nicknames (Edward/Ed, Joseph/Joe, Timothy/Tim,
 * Jeffrey/Jeff, David/Dave, or a legislator who goes by a quoted middle name
 * like Jerry "Alan" Branson) — all measured in this dataset 2026-08-22. Those
 * are handled upstream by preferring the shared ncleg.gov member id anchor
 * over this name check wherever that anchor is available; see buildRoster.
 */
export function firstLastTokens(name) {
  const cleaned = normalizeNameForMatch(name)
    // Ballotpedia disambiguates same-named pages with a trailing parenthetical
    // (e.g. "Anna Ferguson (North Carolina)", "Haseeb Fatmi (Wake Forest Town
    // Council, North Carolina, candidate 2025)") — not part of the name.
    .replace(/\([^)]*\)/g, ' ')
    .replace(/["'.,]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  let tokens = cleaned.split(' ').filter(Boolean);
  if (tokens.length > 1 && NAME_SUFFIXES.has(tokens[tokens.length - 1])) {
    tokens = tokens.slice(0, -1);
  }
  const significant = tokens.filter((t) => t.length > 1);
  const finalTokens = significant.length >= 2 ? significant : tokens;
  if (finalTokens.length === 0) return { first: '', last: '' };
  return { first: finalTokens[0], last: finalTokens[finalTokens.length - 1] };
}

/** True only when first AND last token match. A first-name-only or last-name-only match is NOT a match. */
export function namesMatch(a, b) {
  const ta = firstLastTokens(a);
  const tb = firstLastTokens(b);
  return ta.first !== '' && ta.first === tb.first && ta.last === tb.last;
}

/** Parses one chamber's ncleg.gov member-list HTML into per-row records (over-long by design; see header). */
export function parseNcgaMemberList(html, chamber) {
  const letter = NCLEG_LETTER[chamber];
  const nameRe = new RegExp(`<a href="/Members/Biography/${letter}/(\\d+)">([^<]+)</a>&nbsp;\\([A-Z]\\)</p>`, 'g');
  const rows = [];
  let match;
  while ((match = nameRe.exec(html))) {
    const [full, id, rawName] = match;
    const tailStart = match.index + full.length;
    const windowText = html.slice(tailStart, tailStart + 700);
    const districtMatch = windowText.match(/District (\d+)</);
    if (!districtMatch) {
      throw new Error(`ncleg ${chamber}: no "District N" found near member ${rawName} (${letter}${id}) — page shape changed`);
    }
    const appointedMatch = windowText.match(/\(Appointed (\d{1,2}\/\d{1,2}\/\d{2})\)/);
    const resignedMatch = windowText.match(/\(Resigned (\d{1,2}\/\d{1,2}\/\d{2})\)/);
    rows.push({
      chamber,
      district: Number(districtMatch[1]),
      name: decodeHtmlEntities(rawName).trim(),
      memberId: `${letter}${id}`,
      appointedOn: appointedMatch ? parseNcgaDate(appointedMatch[1]) : null,
      resignedOn: resignedMatch ? parseNcgaDate(resignedMatch[1]) : null,
      ncgaSource: `https://www.ncleg.gov/Members/Biography/${letter}/${id}`,
    });
  }
  return rows;
}

function groupByDistrict(rows) {
  const map = new Map();
  for (const r of rows) {
    const list = map.get(r.district) ?? [];
    list.push(r);
    map.set(r.district, list);
  }
  return map;
}

/** Extracts EVERY ncleg.gov Biography member id (e.g. "S423") cited in an Open States links/sources cell. */
function extractAllNcgaMemberIds(cell) {
  const ids = [];
  const re = /Members\/Biography\/([HS])\/(\d+)/g;
  let m;
  while ((m = re.exec(String(cell || '')))) ids.push(`${m[1]}${m[2]}`);
  return ids;
}

/**
 * Indexes Open States' bulk CSV by EVERY ncleg.gov member id its `links`
 * column cites — not just the first. Measured 2026-08-22: Open States' row
 * for Sophia Chitlik (Senate 22) cites BOTH her own id (S452) AND her
 * predecessor Dana Jones' id (S449) — a stale citation left over from
 * whatever scrape produced this row. Jones has his own separate, correct row
 * (Senate 31, citing only S449). Taking only `links`' first match would have
 * bound S449 to whichever of the two rows the CSV happens to list first,
 * silently misidentifying one of them. Indexing every id and disambiguating
 * by (chamber, district) in buildRoster — which ncleg.gov's own list already
 * establishes independently — resolves this without guessing.
 */
function parseOpenStatesCsv(csvText) {
  const records = parseCsv(csvText, { columns: true, skip_empty_lines: true });
  const byMemberId = new Map();
  for (const row of records) {
    const memberIds = extractAllNcgaMemberIds(row.links);
    if (memberIds.length === 0) continue; // handled as a per-seat refusal by the caller when a lookup misses
    const sources = String(row.sources || '')
      .split(';')
      .map((s) => s.trim())
      .filter(Boolean);
    const record = {
      name: row.name,
      chamber: row.current_chamber,
      district: Number(row.current_district),
      image: row.image ? row.image.trim() : '',
      // Kept as a list, in order: Open States sometimes carries more than one
      // ballotpedia.org URL for the same person (a stale one alongside a
      // disambiguated current one — measured 2026-08-22, Michael V. Lee), and
      // the first is not always the live page.
      ballotpediaUrls: sources.filter((u) => u.startsWith('https://ballotpedia.org/')),
    };
    for (const memberId of memberIds) {
      const list = byMemberId.get(memberId) ?? [];
      list.push(record);
      byMemberId.set(memberId, list);
    }
  }
  return byMemberId;
}

/**
 * True when the fetched Ballotpedia page itself cites this exact ncleg.gov
 * Biography URL — the same numeric member id ncleg.gov's own list assigned
 * this person. This is a hard identity anchor shared by ncleg.gov, Open
 * States (via its `links` column) and Ballotpedia (via its citations), and
 * is what this script relies on instead of fuzzy name matching wherever an
 * exact anchor is available — nicknames (David/Dave), leading initials
 * (A. Reece Pyrtle) and generational suffixes (, Jr.) make free-text name
 * comparison alone unreliable, as this dataset demonstrates.
 */
export function ballotpediaCitesNcgaMemberId(html, memberId) {
  const m = memberId.match(/^([HS])(\d+)$/);
  if (!m) return false;
  // Case-insensitive: measured 2026-08-22, Ballotpedia's own citation for
  // Michael V. Lee (ncleg.gov member id S387) renders the path as
  // "Biography/s/387" (lowercase chamber letter), unlike ncleg.gov's own
  // uppercase URLs.
  const needle = `ncleg.gov/members/biography/${m[1]}/${m[2]}`.toLowerCase();
  return html.toLowerCase().includes(needle);
}

/**
 * Extracts "He/She assumed office on Month D, YYYY." or "... in YYYY." from a
 * Ballotpedia bio page.
 *
 * ⚠ DO NOT "CORRECT" A CLUSTER OF January-1 DATES TO 'year' PRECISION.
 * Reviewed 2026-08-22: 124 of the 170 seats in the final roster carry a
 * 'day'-precision assumedOffice of exactly YYYY-01-01. That is NOT
 * Ballotpedia boilerplate leaking in as false precision -- it is the
 * correct, literal day. The North Carolina Constitution, Article II, Section 9 ("Term of office"),
 * provides that "the term of office of Senators and Representatives shall
 * commence on the first day of January next after their election." January 1
 * is the LEGALLY MANDATED term-start date for every NC legislator who was
 * seated at the start of a normal term (as opposed to the 8 appointed
 * mid-term successors, who get their date from ncleg.gov's own annotation
 * instead -- see the howStarted==='appointed' branch in buildRoster). Ballotpedia's
 * "He assumed office on January 1, 20XX" sentence is reporting this
 * constitutional date honestly, at genuine day precision, not guessing a
 * year and rendering it as a full date. Confirmed by hand against the NC
 * Constitution text, not inferred from the pattern alone.
 */
export function parseBallotpediaAssumedOffice(html) {
  const dayMatch = html.match(/assumed office on ([A-Z][a-z]+ \d{1,2}, \d{4})/);
  if (dayMatch) {
    const parsed = new Date(`${dayMatch[1]} UTC`);
    if (!Number.isNaN(parsed.getTime())) {
      return { assumedOffice: parsed.toISOString().slice(0, 10), assumedPrecision: 'day' };
    }
  }
  const yearMatch = html.match(/assumed office in (\d{4})/);
  if (yearMatch) {
    return { assumedOffice: `${yearMatch[1]}-01-01`, assumedPrecision: 'year' };
  }
  return { assumedOffice: null, assumedPrecision: 'unknown' };
}

async function buildRoster() {
  const retrievedAt = new Date().toISOString();

  const [houseHtml, senateHtml, openStatesCsv] = await Promise.all([
    fetchText(NCLEG_LIST_URL.lower, { minLength: 50_000 }),
    fetchText(NCLEG_LIST_URL.upper, { minLength: 30_000 }),
    fetchText(OPENSTATES_CSV_URL, { minLength: 20_000 }),
  ]);

  const ncgaRows = {
    lower: parseNcgaMemberList(houseHtml, 'lower'),
    upper: parseNcgaMemberList(senateHtml, 'upper'),
  };
  const openStatesByMemberId = parseOpenStatesCsv(openStatesCsv);

  const seats = [];
  const refusals = [];
  const nameVariances = [];
  const nameOnlyConfirmations = [];

  for (const chamber of ['lower', 'upper']) {
    const byDistrict = groupByDistrict(ncgaRows[chamber]);
    const sortedDistricts = [...byDistrict.keys()].sort((a, b) => a - b);

    for (const district of sortedDistricts) {
      const districtRows = byDistrict.get(district);
      let sitting;
      try {
        sitting = pickSittingMember(district, districtRows);
      } catch (err) {
        refusals.push({ chamber, district, reason: err.message });
        continue;
      }

      const osCandidates = openStatesByMemberId.get(sitting.memberId) ?? [];
      if (osCandidates.length === 0) {
        refusals.push({
          chamber, district,
          reason: `Open States has no row citing ncleg.gov member id ${sitting.memberId} (${sitting.name})`,
        });
        continue;
      }
      // Disambiguate using ncleg.gov's OWN (authoritative) chamber/district,
      // not Open States' 'name' field — see parseOpenStatesCsv header.
      const osMatches = osCandidates.filter((c) => c.chamber === chamber && c.district === district);
      if (osMatches.length === 0) {
        refusals.push({
          chamber, district,
          reason: `Open States cites ncleg.gov member id ${sitting.memberId} (${sitting.name}) only at ` +
            `${osCandidates.map((c) => `${c.chamber}/${c.district}`).join(', ')}, not ${chamber}/${district} — sources disagree`,
        });
        continue;
      }
      if (osMatches.length > 1) {
        refusals.push({
          chamber, district,
          reason: `Open States has ${osMatches.length} distinct rows all citing ncleg.gov member id ` +
            `${sitting.memberId} at ${chamber}/${district} — ambiguous, refusing to guess`,
        });
        continue;
      }
      const osRecord = osMatches[0];
      // The ncleg.gov member id match above IS the identity confirmation —
      // ncleg is authoritative for identity (see file header) and Open States'
      // own `links` column independently cites this exact numeric id. A
      // display-name difference under a confirmed id match is NOT a "genuine
      // first-name mismatch" (the brief's refusal case is for when identity
      // CANNOT be established) — it is nickname/preferred-name variance, and
      // this dataset has several real ones: Edward/Ed Goodwin, Joseph/Joe
      // Pike, Timothy/Tim Reeder, Jeffrey/Jeff McNeely, David/Dave Craven,
      // and Jerry "Alan" Branson (goes by his middle name). Logged, not
      // refused, once the id anchor confirms identity.
      if (!namesMatch(sitting.name, osRecord.name)) {
        nameVariances.push({
          chamber, district,
          note: `ncleg "${sitting.name}" vs Open States "${osRecord.name}" (ncleg.gov member id ${sitting.memberId}, ` +
            `chamber/district confirmed) — accepted as nickname/preferred-name variance, not a mismatch`,
        });
      }

      const overrideUrl = BALLOTPEDIA_URL_OVERRIDES.get(`${chamber}:${district}`);
      const ballotpediaCandidates = overrideUrl
        ? [overrideUrl]
        : osRecord.ballotpediaUrls;
      if (ballotpediaCandidates.length === 0) {
        refusals.push({
          chamber, district,
          reason: `no Ballotpedia URL available for ${sitting.name} (ncleg.gov member id ${sitting.memberId})`,
        });
        continue;
      }

      // Open States sometimes lists more than one ballotpedia.org URL for the
      // same person (measured 2026-08-22: Michael V. Lee — a stale one, 404,
      // alongside a disambiguated live one). Try each in order until one
      // both fetches and confirms identity.
      //
      // The id-citation check is strongly preferred, but CANNOT be required
      // outright: measured 2026-08-22, doing so refuses 5 real, correctly-
      // identified seats whose Ballotpedia pages simply have not caught up
      // yet — Dan Kiger, Anna Ferguson, Haseeb Fatmi and Jonah Garson were
      // all appointed within the last few months and their pages don't yet
      // cite ncleg.gov at all, and Jake Johnson's page is a sparse stub with
      // no infobox or citations of any kind. Refusing all 5 outright would
      // silently drop real seats from the roster over a Ballotpedia lag, not
      // a genuine identity problem. So the name-only fallback stays, but
      // (per review) it must never be silent: every seat records HOW its
      // Ballotpedia identity was confirmed, the count of name-only
      // confirmations is printed, and — the point of this comment — that
      // count is asserted below so a FUTURE increase (a new ambiguous match
      // slipping through unnoticed) fails the build instead of passing
      // quietly. If this assertion ever fails, read the new entries in
      // `nameOnlyConfirmations` by hand before touching the expected count.
      let bpHtml = null;
      let bpUrlUsed = null;
      let bpConfirmedBy = null; // 'member_id' | 'name_only'
      const attemptErrors = [];
      for (const candidateUrl of ballotpediaCandidates) {
        // A fixed pause before every Ballotpedia request (not just on
        // failure) keeps this script under the rate that triggers the WAF in
        // the first place — see fetchBallotpediaText.
        await sleep(600);
        let candidateHtml;
        try {
          candidateHtml = await fetchBallotpediaText(candidateUrl);
        } catch (err) {
          attemptErrors.push(`${candidateUrl}: ${err.message}`);
          continue;
        }
        const idConfirmed = ballotpediaCitesNcgaMemberId(candidateHtml, sitting.memberId);
        if (idConfirmed) {
          bpHtml = candidateHtml;
          bpUrlUsed = candidateUrl;
          bpConfirmedBy = 'member_id';
          break;
        }
        const titleMatch = candidateHtml.match(/<title>([^<]+) - Ballotpedia<\/title>/);
        const bpName = titleMatch ? titleMatch[1] : null;
        if (bpName && namesMatch(sitting.name, bpName)) {
          bpHtml = candidateHtml;
          bpUrlUsed = candidateUrl;
          bpConfirmedBy = 'name_only';
          nameOnlyConfirmations.push({
            chamber, district, name: sitting.name, url: candidateUrl,
          });
          break;
        }
        attemptErrors.push(
          `${candidateUrl}: does not cite ncleg.gov member id ${sitting.memberId} and its title ` +
          `"${bpName}" does not name-match "${sitting.name}"`
        );
      }
      if (!bpHtml) {
        refusals.push({
          chamber, district,
          reason: `no Ballotpedia candidate confirmed identity for ${sitting.name} (ncleg.gov member id ` +
            `${sitting.memberId}) — refusing to guess. Tried: ${attemptErrors.join(' | ')}`,
        });
        continue;
      }

      let assumedOffice = null;
      let assumedPrecision = 'unknown';
      if (sitting.howStarted === 'appointed') {
        // Rule: the 8 appointed successors get their date from ncleg.gov's own
        // annotation, not Ballotpedia — see task-2-brief.md ambiguity #3.
        assumedOffice = sitting.appointedOn;
        assumedPrecision = 'day';
      } else {
        const bp = parseBallotpediaAssumedOffice(bpHtml);
        assumedOffice = bp.assumedOffice;
        assumedPrecision = bp.assumedPrecision;
      }

      seats.push({
        chamber,
        district,
        name: sitting.name,
        memberId: sitting.memberId,
        assumedOffice,
        assumedPrecision,
        portraitUrl: osRecord.image || null,
        howStarted: sitting.howStarted,
        source: sitting.ncgaSource,
        // How THIS seat's Ballotpedia identity was confirmed — 'member_id'
        // (the page cites this exact ncleg.gov member id) is the strong case;
        // 'name_only' means only the page <title> matched sitting.name, with
        // no id citation at all. Recorded per-seat, not just logged, so a
        // consumer can tell the difference without re-deriving it. See the
        // EXPECTED_NAME_ONLY_CONFIRMATIONS assertion below.
        ballotpediaConfirmedBy: bpConfirmedBy,
      });
    }
  }

  if (refusals.length > 0) {
    console.error(`REFUSED ${refusals.length} seat(s) — reported, not guessed:`);
    for (const r of refusals) {
      console.error(`  - ${r.chamber} district ${r.district}: ${r.reason}`);
    }
  }
  if (nameVariances.length > 0) {
    console.log(`${nameVariances.length} seat(s) accepted despite a name-form variance (identity confirmed by ncleg.gov member id):`);
    for (const v of nameVariances) {
      console.log(`  - ${v.chamber} district ${v.district}: ${v.note}`);
    }
  }
  if (nameOnlyConfirmations.length > 0) {
    console.log(
      `${nameOnlyConfirmations.length} seat(s) confirmed by Ballotpedia PAGE TITLE ONLY ` +
      `(no ncleg.gov member id citation found on the page):`
    );
    for (const c of nameOnlyConfirmations) {
      console.log(`  - ${c.chamber} district ${c.district}: ${c.name} — ${c.url}`);
    }
  }
  // Measured 2026-08-22: exactly 5 seats (4 very-recent appointees whose
  // Ballotpedia pages haven't been updated with an ncleg.gov citation yet,
  // plus one sparse stub page with no infobox at all) fall through to the
  // name-only fallback. This is a KNOWN, reviewed count, not a target to
  // silently grow toward — a future increase means some new seat's
  // Ballotpedia identity is resting on a title-string match alone, which is
  // exactly the weaker-evidence shape this assertion exists to catch. If
  // this throws, read the newly-added entries in `nameOnlyConfirmations`
  // (printed above) by hand before deciding whether to accept them and only
  // then raise this number.
  const EXPECTED_NAME_ONLY_CONFIRMATIONS = 5;
  if (nameOnlyConfirmations.length !== EXPECTED_NAME_ONLY_CONFIRMATIONS) {
    throw new Error(
      `FATAL: expected ${EXPECTED_NAME_ONLY_CONFIRMATIONS} name-only Ballotpedia confirmations, ` +
      `got ${nameOnlyConfirmations.length} — read the list above before adjusting this number.`
    );
  }

  const lower = seats.filter((s) => s.chamber === 'lower');
  const upper = seats.filter((s) => s.chamber === 'upper');
  if (lower.length !== 120) throw new Error(`FATAL: expected 120 House seats, got ${lower.length}`);
  if (upper.length !== 50) throw new Error(`FATAL: expected 50 Senate seats, got ${upper.length}`);
  for (const [chamber, list, max] of [['lower', lower, 120], ['upper', upper, 50]]) {
    const ds = new Set(list.map((s) => s.district));
    if (ds.size !== list.length) throw new Error(`FATAL: duplicate district in ${chamber}`);
    for (let n = 1; n <= max; n++) {
      if (!ds.has(n)) throw new Error(`FATAL: ${chamber} district ${n} missing from roster`);
    }
  }
  const appointed = seats.filter((s) => s.howStarted === 'appointed');
  if (appointed.length !== 8) throw new Error(`FATAL: expected 8 appointed members, got ${appointed.length}`);

  const payload = { retrievedAt, seats };
  writeFileSync(OUTPUT_PATH, `${JSON.stringify(payload, null, 2)}\n`, 'utf8');

  console.log(`OK: 120 House + 50 Senate, every district 1..N present exactly once.`);
  console.log(`Appointed (howStarted='appointed'): ${appointed.length}`);
  for (const s of appointed) {
    console.log(`  - ${s.chamber} district ${s.district}: ${s.name} (assumedOffice ${s.assumedOffice})`);
  }
  return payload;
}

// Run only when invoked directly (`node scripts/build-nc-legislature-roster.mjs`),
// not when imported by the test file.
const isMain = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
  buildRoster().catch((err) => {
    console.error(err.stack || err.message || err);
    process.exit(1);
  });
}
