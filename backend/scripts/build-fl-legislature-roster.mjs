#!/usr/bin/env node
/**
 * build-fl-legislature-roster.mjs
 *
 * Reconciles the Florida Legislature roster and writes data/fl-legislature-roster.json.
 * Reads nothing from the database and writes nothing to it.
 *
 * SOURCES — both chambers' own, plus each member's own page:
 *   1. flhouse.gov/Representatives — the House roster. Member links are
 *      /Sections/Representatives/details.aspx?MemberId=<id>. Carries the member's
 *      CURRENT TERM WINDOW, which is how a departed member is identified.
 *   2. flsenate.gov/Senators/ — the Senate roster table. Member links are
 *      /Senators/2024-2026/S<district>. Measured 2026-08-28: exactly 40, districts
 *      1-40 complete, href and district cell always agree.
 *   3. Each member's own page, for the assumed-office date and the
 *      change-since-source check.
 *
 * ⚠ THE HOUSE LIST IS OVER-LONG. Measured 2026-08-28: 127 records for 120 seats.
 * Seven districts (3, 32, 40, 51, 52, 87, 90) list a departed member alongside the
 * sitting one. Florida annotates BOTH sides through the term window: the sitting
 * member's term runs to 11/03/26, the departed member's ends early. That is a
 * cleaner discriminator than NC had, where two departed members carried no
 * annotation at all — but the rule implemented in pickSittingMember is still the
 * conservative one (drop departed, then latest assumed date, then THROW). Do not
 * weaken it to get a clean run.
 *
 * ⚠ THE ROSTER'S START DATE IS THE CURRENT TERM, NOT CONTINUOUS OCCUPANCY.
 * 120 of the 127 House records read 11/06/24 — the 2024 general election. Writing
 * that as term_start would misstate every re-elected member, because term_start is
 * the start of continuous occupancy by that person and re-election does not end an
 * occupancy. So the date comes from the member's own page instead:
 *   - House: the "Legislative Service" line, "Elected to the Florida House of
 *     Representatives in YYYY" -> YYYY-01-01 with start_precision 'year', because a
 *     year is all the source states. A member with no such block is serving a first
 *     term, so the roster's own full date is correct for them, at 'day' precision.
 *   - Senate: the SAME "Legislative Service" line. It states the CURRENT tenure and
 *     pushes earlier, non-contiguous service into a 'prior service YYYY-YYYY' tail,
 *     so its leading date already IS continuous occupancy. 6 of the 39 give a full
 *     day. Where the page also carries a compact 'Elected M/D/YYYY' line (4 of 40,
 *     all special-election arrivals) that INDEPENDENT second statement confirms it.
 *     The 'Florida Senate Service' block is a TERM SELECTOR and cannot answer this
 *     question at all - see the deleted-function note further down before reaching
 *     for it.
 *
 * ⚠ THE SENATE PATH IS SESSION-SCOPED (/2024-2026/). A session roster is not a
 * statement about current occupancy -- a senator who resigned mid-session can still
 * be listed under their session. This is the OLIS lesson, and it is why every
 * member page is fetched rather than trusting the roster alone.
 *
 * ⚠ NEITHER A STATUS CODE NOR A NON-EMPTY BODY PROVES A FLORIDA FETCH SUCCEEDED.
 * Measured 2026-08-28: myfloridahouse.gov returned the full 74,830-byte roster page
 * for a .pdf path that cannot exist, and flhouse.gov returned a 244-byte stub with
 * HTTP 200 for MemberId=5063 on one call and 32,365 bytes on the next, seconds
 * apart, same URL. fetchValidated() therefore asserts a minimum size AND a required
 * marker, and retries.
 *
 * ⚠ DO NOT SUBSTITUTE WIKIPEDIA'S "Assumed office" COLUMN -- it mixes election year
 * and appointment year in one column (the CO lesson). The chambers' own pages are
 * both more authoritative and easier to parse.
 *
 * Florida fills LEGISLATIVE vacancies by SPECIAL ELECTION, not by appointment
 * (Fla. Const. art. III, s. 15(d) / s. 11 and ch. 100, F.S.), so howStarted is
 * 'elected' for every seat including the seven successors. This is stated in
 * ROSTERS.md with its basis rather than left implicit, because seat_officeholder()
 * defaults p_how_started to 'elected' and a silent default is not evidence.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   node scripts/build-fl-legislature-roster.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

// ─── Pure functions (what the unit test imports) ─────────────────────────────

/**
 * Normalise a name for CROSS-SOURCE MATCHING ONLY. Never call this on a value
 * headed for politicians.full_name -- that is a byte-for-byte pass of the source's
 * own spelling.
 *
 * 🔴 Combining marks are DELETED, not replaced with a space. Replacing them
 * spaces out every accented name and turns 'María' into 'mari a', which then
 * fails to match itself.
 */
export function normalizeForMatch(s) {
  return String(s)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
    .replace(/\s+/g, ' ');
}

/**
 * Extract the district number from a Senate roster href.
 * Accepts only the bare seat path; a member-detail sub-path is refused rather
 * than silently truncated to the seat.
 */
export function splitDistrict(href) {
  const s = String(href);
  const m = s.match(/^\/Senators\/\d{4}-\d{4}\/S(\d{1,2})$/);
  if (m) return Number(m[1]);
  if (/^\/Senators\/\d{4}-\d{4}\/S\d{1,2}\/\d+$/.test(s)) {
    throw new Error(`Refusing a member-detail sub-path: ${JSON.stringify(href)}`);
  }
  throw new Error(`Unparseable Senate roster href: ${JSON.stringify(href)}`);
}

/**
 * Given every row a chamber lists for one district, return the sitting member.
 * Throws rather than guess on any shape not seen while planning.
 */
export function pickSittingMember(district, rows) {
  const surviving = rows.filter((r) => !r.departedOn);
  if (surviving.length === 0) {
    throw new Error(
      `district ${district}: every listed member is marked departed — this seat is vacant. ` +
      `A vacancy is a fact about a span, not a member; record it on the office, not here.`
    );
  }
  if (surviving.length === 1) return surviving[0];

  const dated = surviving.filter((r) => r.assumedOn);
  if (dated.length === 0) {
    throw new Error(
      `district ${district}: ${surviving.length} surviving rows and no assumed-office date ` +
      `to arbitrate on (${surviving.map((r) => r.name).join(', ')}). Unseen shape — refusing to guess.`
    );
  }
  const sorted = [...dated].sort((a, b) => b.assumedOn.localeCompare(a.assumedOn));
  if (sorted.length > 1 && sorted[0].assumedOn === sorted[1].assumedOn) {
    throw new Error(
      `district ${district}: ${sorted[0].name} and ${sorted[1].name} share assumed-office date ` +
      `${sorted[0].assumedOn}. Cannot arbitrate — refusing to guess.`
    );
  }
  return sorted[0];
}

/** Roster renders MM/DD/YY. Returns ISO yyyy-mm-dd. Two-digit years are 20xx. */
export function parseFlShortDate(raw) {
  const m = String(raw).trim().match(/^(\d{2})\/(\d{2})\/(\d{2})$/);
  if (!m) throw new Error(`Unparseable FL roster date: ${JSON.stringify(raw)}`);
  const [, mo, da, yy] = m;
  return `20${yy}-${mo}-${da}`;
}

/**
 * The day after an ISO date, as ISO. Used to turn a departed member's last day in
 * office into the FIRST VACANT DAY, which is what offices.vacant_since means and
 * what essentials.vacate_office() takes.
 *
 * Uses UTC arithmetic deliberately: a local-time Date on a machine behind UTC can
 * roll the wrong way and silently shift the vacancy by a day.
 */
export function dayAfter(iso) {
  const m = String(iso).match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (!m) throw new Error(`dayAfter needs an ISO yyyy-mm-dd, got ${JSON.stringify(iso)}`);
  const d = new Date(Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3])));
  d.setUTCDate(d.getUTCDate() + 1);
  return d.toISOString().slice(0, 10);
}

/**
 * "Last, First M." -> structured parts, preserving the source's exact spelling.
 *
 * Both chambers render names surname-first with a comma, which is a CLEANER split
 * than NC's "First Last": a two-word surname like 'Bracy Davis, LaVon' is
 * unambiguous here, where a space-split would have guessed wrong.
 *
 * A leading '*' is a roster marker (seen on a deceased member), not part of the name.
 */
export function parseSurnameFirst(raw) {
  const s = tidy(raw).replace(/^\*\s*/, '');
  const i = s.indexOf(',');
  if (i < 0) throw new Error(`Name is not surname-first: ${JSON.stringify(raw)}`);
  let lastPart = tidy(s.slice(0, i));
  let rest = tidy(s.slice(i + 1));
  if (!lastPart || !rest) throw new Error(`Name splits to an empty half: ${JSON.stringify(raw)}`);

  // A generational suffix can sit on EITHER side of the comma in this roster:
  //   'Brannan III, Robert Charles "Chuck"'  -> surname side
  //   'Massullo, Ralph E., Jr.'              -> given side, after a SECOND comma
  // Both are real, measured 2026-08-28 (4 on the surname side, 1 on the given side).
  let suffix = null;
  const surnameSuffix = lastPart.match(/^(.*?)[,\s]+(Jr\.?|Sr\.?|II|III|IV|V)$/i);
  if (surnameSuffix) {
    lastPart = tidy(surnameSuffix[1]);
    suffix = surnameSuffix[2];
  }
  const j = rest.lastIndexOf(',');
  if (j >= 0) {
    const tail = tidy(rest.slice(j + 1));
    if (!/^(Jr\.?|Sr\.?|II|III|IV|V|MD|M\.D\.|DO|D\.O\.|Ph\.?D\.?|Esq\.?)$/i.test(tail)) {
      throw new Error(`Unrecognised trailing name part ${JSON.stringify(tail)} in ${JSON.stringify(raw)}`);
    }
    if (suffix) {
      throw new Error(`Name carries a suffix on BOTH sides of the comma: ${JSON.stringify(raw)}`);
    }
    suffix = tail;
    rest = tidy(rest.slice(0, j));
  }

  // A leading honorific is a TITLE, not a name. It is stripped from full_name because
  // full_name is a MATCHING KEY downstream (the headshot import guard joins on it), and
  // 'Dr. Anna V. Eskamani' would fail to match 'Anna V. Eskamani' everywhere else.
  // Measured 2026-08-28: 2 cases. Note the regex is anchored at the START, so the
  // quoted nickname in 'Hart-Lowman, Dianne "Ms Dee"' is untouched.
  let honorific = null;
  const hon = rest.match(/^(Dr|Mr|Mrs|Ms|Rev|Hon)\.\s+(.+)$/);
  if (hon) {
    honorific = `${hon[1]}.`;
    rest = tidy(hon[2]);
  }

  // A quoted nickname STAYS in full_name — that is the NC precedent (full_name kept
  // 'Jerry "Alan" Branson') — and is additionally surfaced as a preferred name for
  // alternate_names. 22 of the 160 carry one.
  const nick = rest.match(/"([^"]+)"/);
  const preferred = nick ? tidy(nick[1]) : null;

  if (!lastPart || !rest) throw new Error(`Name reduces to an empty half: ${JSON.stringify(raw)}`);
  const full = `${rest} ${lastPart}` + (suffix ? `, ${suffix}` : '');
  return { last: lastPart, given: rest, suffix, honorific, preferred, full };
}

/**
 * Parse the compact "Elected M/D/YYYY" line that sits under a senator's name.
 *
 * Present on only 4 of the 40 Senate pages and 0 of the 116 House pages, measured
 * 2026-08-28 — it appears for members who arrived at a SPECIAL election (S11, S14,
 * S15, S19). Where it exists it is an independent second statement of the same fact
 * as the "Legislative Service" prose, so it is used to CROSS-CHECK, and as the value
 * if the prose is missing.
 */
export function parseElectedShort(line) {
  const m = String(line).match(/^Elected\s+(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (!m) return null;
  return `${m[3]}-${String(Number(m[1])).padStart(2, '0')}-${String(Number(m[2])).padStart(2, '0')}`;
}

/*
 * ⚠ THERE WAS A continuousRunStart() HERE. IT IS DELETED ON PURPOSE — DO NOT RE-ADD IT.
 *
 * It walked the "Florida Senate Service" list of YYYY-YYYY ranges back through
 * contiguous terms, on the assumption that the list records CONTINUOUS SERVICE. That
 * assumption is FALSE, proven against the real pages on 2026-08-28:
 *
 *   - The block is a TERM SELECTOR dropdown. It repeats the current term as the
 *     selected value, so SD-19 renders '2024-2026, 2022-2024, 2020-2022, 2018-2020,
 *     2016-2018, 2024-2026'.
 *   - It lists every term the member served ANY part of, not when they took the seat.
 *     Lori Berman (SD-26) won a special election on 2018-04-10, inside the 2016-2018
 *     term, so the list reaches back to 2016 while her occupancy began in 2018.
 *     Rosalind Osgood (SD-32) is the same shape (2022-03-08 inside 2020-2022).
 *   - It does NOT show a gap. Debbie Mayfield (SD-19) served 2016-2024, left, and
 *     returned on 2025-06-10; the list still runs unbroken from 2016-2018 to
 *     2024-2026 because she served part of the 2024-2026 term.
 *
 * So the list could not answer the only question asked of it, and using it produced
 * three wrong dates that its own cross-check then flagged. The "Legislative Service"
 * prose line is authoritative instead: it states the CURRENT tenure and segregates
 * earlier, non-contiguous service into a 'prior service YYYY-YYYY' tail.
 */

// ─── Text helpers ────────────────────────────────────────────────────────────

/** Collapse NBSP and runs of whitespace. Source pages use U+00A0 inside names. */
function tidy(s) {
  return String(s).replace(/\u00a0/g, ' ').replace(/\s+/g, ' ').trim();
}

/** Minimal HTML entity decode for the fields read here. */
function unent(s) {
  return String(s)
    .replace(/&mdash;/g, '\u2014').replace(/&ndash;/g, '\u2013')
    .replace(/&nbsp;/g, ' ').replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'").replace(/&apos;/g, "'")
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
    .replace(/&amp;/g, '&');
}

function stripTags(s) {
  const noScript = String(s).replace(/<(script|style)[\s\S]*?<\/\1>/gi, ' ');
  return unent(noScript.replace(/<[^>]+>/g, '\n'))
    .split('\n').map(tidy).filter(Boolean);
}

// ─── Fetch with content validation ───────────────────────────────────────────

const DIR = 'data/seed-fl-legislature-2026';
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';

/** The normal end of the 2024-2026 House term, as the roster renders it. */
const HOUSE_NORMAL_TERM_END = '11/03/26';

async function fetchValidated(url, { minBytes, mustInclude, cache, tries = 4 }) {
  if (cache && fs.existsSync(cache)) {
    const cached = fs.readFileSync(cache, 'utf8');
    if (cached.length >= minBytes && mustInclude.every((m) => cached.includes(m))) return cached;
  }
  let last = '';
  for (let attempt = 1; attempt <= tries; attempt++) {
    try {
      const res = await fetch(url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
      const body = await res.text();
      const bigEnough = body.length >= minBytes;
      const hasMarkers = mustInclude.every((m) => body.includes(m));
      last = `HTTP ${res.status}, ${body.length} bytes` +
        (bigEnough ? (hasMarkers ? '' : ' (missing marker)') : ' (too small - the stub)');
      if (bigEnough && hasMarkers) {
        if (cache) fs.writeFileSync(cache, body, 'utf8');
        return body;
      }
    } catch (e) {
      last = `threw: ${e.message}`;
    }
    await new Promise((r) => setTimeout(r, 500 * attempt));
  }
  throw new Error(`fetchValidated FAILED after ${tries} tries: ${url} - last: ${last}`);
}

const MONTHS = {
  january: 1, february: 2, march: 3, april: 4, may: 5, june: 6,
  july: 7, august: 8, september: 9, october: 10, november: 11, december: 12,
};

/**
 * Parse a member page's "Legislative Service" opening line.
 *
 * ELEVEN distinct phrasings exist. Enumerated 2026-08-28 by scanning all 156 cached
 * member pages rather than guessing, because an unrecognised form silently degrades a
 * known date to 'unknown' — which is exactly what happened to SD-11, SD-14 and SD-15
 * on the first run, all three of which publish a FULL DATE:
 *
 *   64  Elected to the Florida House of Representatives in YYYY, reelected subsequently
 *   20  Elected to the Senate in YYYY, reelected subsequently
 *   19  Elected to the Florida House of Representatives in YYYY
 *   12  Elected to the Senate in YYYY
 *    7  Elected to the Florida House of Representatives on MONTH D, YYYY, reelected subsequently
 *    5  Elected to the Florida House of Representatives on MONTH D, YYYY
 *    3  Elected to the Senate on MONTH D, YYYY
 *    2  Elected to the Senate MONTH D, YYYY, reelected subsequently     <- no "on"
 *    1  Elected to the Senate in YYYY, prior Senate YYYY-YYYY
 *    1  Elected to the Senate on MONTH D, YYYY, prior service YYYY-YYYY
 *   22  (no Legislative Service block at all — a first-term member)
 *
 * 🔴 THE "prior Senate" / "prior service" TAIL IS WHY THE PROSE LINE LEADS. The chamber
 * states the CURRENT tenure first and segregates earlier, non-contiguous service into
 * that tail. So the leading date already IS continuous occupancy, which is what
 * office_terms.term_start means. The "Florida Senate Service" term list is kept only as
 * a term SELECTOR and cannot answer this question - see the deleted-function note.
 *
 * Returns { date, precision, line } — precision 'day' when the source gives a full
 * date, 'year' when it gives only a year (stored YYYY-01-01, so month and day are
 * explicitly NOT claimed), or null when the line is absent or unrecognised.
 */
function electedFrom(lines) {
  const idx = lines.indexOf('Legislative Service');
  if (idx < 0) return null;
  const block = lines.slice(idx + 1, idx + 4);
  for (const l of block) {
    const m = l.match(
      /^Elected to the (?:Florida )?(?:House of Representatives|Senate)\s+(?:in\s+(?:a special election in\s+)?(\d{4})\b|(?:on\s+)?([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})\b)/i
    );
    if (!m) continue;
    if (m[1]) {
      return { date: `${m[1]}-01-01`, precision: 'year', line: l };
    }
    const mon = MONTHS[m[2].toLowerCase()];
    if (!mon) {
      // A month name we do not recognise must NOT become a guessed date.
      return { date: null, precision: null, line: l };
    }
    const iso = `${m[4]}-${String(mon).padStart(2, '0')}-${String(Number(m[3])).padStart(2, '0')}`;
    return { date: iso, precision: 'day', line: l };
  }
  return { date: null, precision: null, line: block[0] ?? null };
}

/**
 * The "Florida Senate Service" term-selector values, kept as EVIDENCE ONLY.
 *
 * Deliberately never used to decide a date — see the deleted-function note above for
 * why. Recorded in the roster JSON as _senateTermSelector so a future reader can see
 * what the page showed without being tempted to compute occupancy from it.
 */
function senateTermSelector(lines) {
  const idx = lines.indexOf('Florida Senate Service');
  if (idx < 0) return [];
  const out = [];
  for (const l of lines.slice(idx + 1, idx + 24)) {
    if (/^\d{4}-\d{4}$/.test(l)) out.push(l);
    else if (out.length) break;
  }
  return out;
}

/** The compact "Elected M/D/YYYY" line, if the page carries one. */
function electedShortFrom(lines) {
  for (const l of lines) {
    const iso = parseElectedShort(l);
    if (iso) return { date: iso, line: l };
  }
  return null;
}

// ─── House ───────────────────────────────────────────────────────────────────

async function buildHouse(report) {
  const html = await fetchValidated('https://www.flhouse.gov/Representatives', {
    minBytes: 200000,
    mustInclude: ['team-box', 'MemberId='],
    cache: path.join(DIR, '_house.html'),
  });

  const boxes = html.split('<div class="team-box">').slice(1);
  const raw = [];
  const pendingDistricts = [];
  for (const b of boxes) {
    const mid = b.match(/MemberId=(\d+)/);
    const ds = b.match(/District:\s*(\d{1,3})/);

    // 🔴 A "Pending Election" card is a VACANT SEAT, not a member. The chamber says so
    // in the card's own alt text: 'District 113 is currently vacant.' These cards carry
    // NO MemberId and no <h5> name, so a parser that requires both skips them SILENTLY
    // and the seat count looks like 120 members when it is 116 members + 4 vacancies.
    // Measured 2026-08-28: 131 team-box cards = 127 member records + 4 pending.
    if (!mid && /Pending Election/.test(b)) {
      if (!ds) throw new Error('House Pending Election card carries no district - parser assumption broken.');
      pendingDistricts.push(Number(ds[1]));
      continue;
    }

    const nm = b.match(/<h5>([\s\S]*?)<\/h5>/);
    if (!(mid && nm && ds)) continue;
    const tr = b.match(/(\d{2}\/\d{2}\/\d{2})\s*-\s*(\d{2}\/\d{2}\/\d{2})/);
    if (!tr) throw new Error(`House box for MemberId=${mid[1]} has no term window - parser assumption broken.`);
    raw.push({
      memberId: mid[1],
      rosterName: tidy(unent(nm[1])),
      district: Number(ds[1]),
      termStart: tr[1],
      termEnd: tr[2],
    });
  }
  report.push(`House team-box cards: ${boxes.length} = ${raw.length} member record(s) + ${pendingDistricts.length} Pending Election card(s)`);
  report.push('  (measured 2026-08-28: 131 = 127 + 4)');

  const normalEnd = raw.filter((r) => r.termEnd === HOUSE_NORMAL_TERM_END).length;
  report.push(`House records whose term runs to ${HOUSE_NORMAL_TERM_END}: ${normalEnd}`);
  if (normalEnd + pendingDistricts.length !== 120) {
    throw new Error(
      `FATAL: ${normalEnd} sitting House records + ${pendingDistricts.length} pending = ` +
      `${normalEnd + pendingDistricts.length}, expected 120. Either the departed-member ` +
      'discriminator (an EARLY term end) no longer holds, or a Pending Election card was missed.'
    );
  }

  const byDistrict = new Map();
  for (const r of raw) {
    if (!byDistrict.has(r.district)) byDistrict.set(r.district, []);
    byDistrict.get(r.district).push({
      ...r,
      name: r.rosterName,
      assumedOn: parseFlShortDate(r.termStart),
      departedOn: r.termEnd === HOUSE_NORMAL_TERM_END ? null : parseFlShortDate(r.termEnd),
    });
  }

  const vacantSet = new Set(pendingDistricts);

  // Every vacant district must also carry the departed member's record, because that
  // record's term END is the only place the FIRST VACANT DAY can come from. If a
  // Pending Election card ever appears without one, the vacancy start is unknown and
  // must NOT be invented — CLAUDE.md: set is_vacant and leave the span unwritten.
  const vacancies = [];
  for (const district of [...vacantSet].sort((a, b) => a - b)) {
    const rows = byDistrict.get(district) ?? [];
    const departed = rows.filter((r) => r.departedOn).sort((a, b) => b.departedOn.localeCompare(a.departedOn));
    if (departed.length === 0) {
      report.push(`  VACANT D${district}: Pending Election with NO departed record - vacant_since UNKNOWN, not invented`);
      vacancies.push({ chamber: 'lower', district, vacantSince: null, predecessor: null, source: 'flhouse.gov/Representatives "Pending Election" card' });
      continue;
    }
    const last = departed[0];
    const parts = parseSurnameFirst(last.name);
    vacancies.push({
      chamber: 'lower',
      district,
      vacantSince: dayAfter(last.departedOn),
      predecessor: parts.full,
      source: `flhouse.gov/Representatives "Pending Election - District: ${district}" card ` +
        `(alt text: "District ${district} is currently vacant."); predecessor ${parts.full} ` +
        `term window ${last.termStart}-${last.termEnd}`,
    });
    report.push(`  VACANT D${district}: ${parts.full} left ${last.departedOn}, vacant since ${dayAfter(last.departedOn)}`);
  }

  const contested = [...byDistrict.entries()].filter(([, v]) => v.length > 1);
  report.push(`House districts listing more than one member: ${contested.length}` +
    (contested.length ? ` - ${contested.map(([d]) => d).sort((a, b) => a - b).join(', ')}` : ''));
  for (const [d, rows] of contested.sort((a, b) => a[0] - b[0])) {
    const kept = pickSittingMember(String(d), rows);
    for (const r of rows) {
      report.push(`  D${d}: ${r === kept ? 'KEPT   ' : 'dropped'} ${r.name} ` +
        `(${r.termStart} - ${r.termEnd}${r.departedOn ? ', departed' : ''})`);
    }
  }

  const seats = [];
  for (const [district, rows] of [...byDistrict.entries()].sort((a, b) => a[0] - b[0])) {
    if (vacantSet.has(district)) continue; // handled above; no member to seat
    const m = pickSittingMember(String(district), rows);
    const page = await fetchValidated(
      `https://www.flhouse.gov/Sections/Representatives/details.aspx?MemberId=${m.memberId}&LegislativeTermId=91`,
      { minBytes: 20000, mustInclude: ['FLHouse.gov'], cache: path.join(DIR, `_h-${m.memberId}.html`) }
    );
    const lines = stripTags(page);
    const svc = electedFrom(lines);
    const parts = parseSurnameFirst(m.name);

    // Change-since-source check: the member's own page must name them.
    const pageNamesThem = lines.some((l) =>
      normalizeForMatch(l).includes(normalizeForMatch(parts.last)));
    if (!pageNamesThem) {
      report.push(`  WARNING HD${district}: ${parts.full} - own page does not mention the surname`);
    }

    let assumedOffice, assumedPrecision, source;
    if (svc && svc.date) {
      assumedOffice = svc.date;
      assumedPrecision = svc.precision;
      source = `flhouse.gov details.aspx?MemberId=${m.memberId} "Legislative Service": ${svc.line}`;
    } else if (svc && svc.line) {
      // A block exists but the phrasing is unrecognised. Do NOT fall back to the roster
      // window, which is the CURRENT TERM and would misstate a re-elected member.
      assumedOffice = null;
      assumedPrecision = 'unknown';
      source = `flhouse.gov details.aspx?MemberId=${m.memberId} "Legislative Service" line not recognised: ${svc.line}`;
      report.push(`  UNRECOGNISED HD${district} ${parts.full}: ${svc.line}`);
    } else {
      assumedOffice = m.assumedOn;
      assumedPrecision = 'day';
      source = `flhouse.gov/Representatives roster term window ${m.termStart}-${m.termEnd} ` +
        `(no Legislative Service block on details.aspx?MemberId=${m.memberId}: first term)`;
    }

    seats.push({
      chamber: 'lower',
      district,
      name: parts.full,
      lastName: parts.last,
      givenNames: parts.given,
      nameSuffix: parts.suffix,
      honorific: parts.honorific,
      preferredName: parts.preferred,
      memberId: m.memberId,
      assumedOffice,
      assumedPrecision,
      howStarted: 'elected',
      portraitUrl: `https://www.flhouse.gov/FileStores/Web/Imaging/Member/${m.memberId}.jpg`,
      source,
      _rosterName: m.name,
      _serviceLine: svc ? svc.line : null,
      _rosterTermWindow: `${m.termStart}-${m.termEnd}`,
      _ownPageNamesThem: pageNamesThem,
    });
    process.stderr.write(`\r  house ${seats.length}/${120 - vacantSet.size}  `);
  }
  process.stderr.write('\n');

  // Every district is accounted for exactly once, as a seat or as a vacancy.
  const covered = new Set([...seats.map((s) => s.district), ...vacancies.map((v) => v.district)]);
  if (covered.size !== 120) {
    throw new Error(`FATAL: House districts covered = ${covered.size}, expected 120 ` +
      `(${seats.length} seated + ${vacancies.length} vacant)`);
  }
  return { seats, vacancies };
}

// ─── Senate ──────────────────────────────────────────────────────────────────

async function buildSenate(report) {
  const html = await fetchValidated('https://www.flsenate.gov/Senators/', {
    minBytes: 60000,
    mustInclude: ['<table id="Senators"', 'senatorLink'],
    cache: path.join(DIR, '_senate.html'),
  });

  const body = html.match(/<table id="Senators"[\s\S]*?<tbody>([\s\S]*?)<\/tbody>/);
  if (!body) throw new Error('Senate roster table not found - parser assumption broken.');
  const rows = body[1].split(/<tr\b/).slice(1);

  const parsed = [];
  const senateVacancies = [];
  for (const r of rows) {
    const a = r.match(/<a class="senatorLink" href="(\/Senators\/\d{4}-\d{4}\/S\d{1,2})"[^>]*>(?:<img[^>]*>)?([\s\S]*?)<\/a>/);
    if (!a) continue;
    const cell = r.match(/<td class="middle">\s*(\d{1,2})\s*<\/td>/);
    const photo = r.match(/src="([^"]*\/Photos\/[^"]+)"/);
    const district = splitDistrict(a[1]);
    if (cell && Number(cell[1]) !== district) {
      throw new Error(`Senate row disagrees with itself: href says S${district}, cell says ${cell[1]}`);
    }
    const name = tidy(unent(a[2]));

    // 🔴 THE SENATE MARKS A VACANCY DIFFERENTLY FROM THE HOUSE. There is no
    // "Pending Election" card here: the roster row's NAME is literally 'Vacant'.
    // Measured 2026-08-28: SD-39 (Miami-Dade). A parser that only knew the House's
    // form would have tried to split 'Vacant' as a surname-first name and, without
    // parseSurnameFirst throwing, would have seated a politician called "Vacant".
    //
    // The Senate states NO date and NO reason - its S39 page contains only the word
    // 'Vacant' - so vacant_since is genuinely UNKNOWN. CLAUDE.md: do not write a
    // vacancy span whose start you do not know; set is_vacant and leave it unwritten.
    if (/^vacant$/i.test(name)) {
      senateVacancies.push({
        chamber: 'upper',
        district,
        vacantSince: null,
        predecessor: null,
        source: `flsenate.gov${a[1]} - roster row and member page both read only "Vacant"; ` +
          'no date or reason published, so vacant_since is unknown rather than invented',
      });
      report.push(`  VACANT SD${district}: roster reads "Vacant"; no date published, vacant_since UNKNOWN`);
      continue;
    }
    parsed.push({ href: a[1], district, name, photo: photo ? photo[1] : null });
  }
  report.push(`Senate rows: ${parsed.length} seated + ${senateVacancies.length} vacant (expect 40 total)`);
  if (parsed.length + senateVacancies.length !== 40) {
    throw new Error(`FATAL: Senate rows = ${parsed.length} seated + ${senateVacancies.length} vacant, expected 40`);
  }

  const byDistrict = new Map();
  for (const p of parsed) {
    if (!byDistrict.has(p.district)) byDistrict.set(p.district, []);
    byDistrict.get(p.district).push({ ...p, assumedOn: null, departedOn: null });
  }
  const contested = [...byDistrict.entries()].filter(([, v]) => v.length > 1);
  report.push(`Senate districts listing more than one member: ${contested.length}`);

  const seats = [];
  for (const [district, rows] of [...byDistrict.entries()].sort((a, b) => a[0] - b[0])) {
    const m = rows.length === 1 ? rows[0] : pickSittingMember(String(district), rows);
    const page = await fetchValidated(`https://www.flsenate.gov${m.href}`, {
      minBytes: 20000,
      mustInclude: ['Florida Senate'],
      cache: path.join(DIR, `_s-${district}.html`),
    });
    const lines = stripTags(page);
    const svc = electedFrom(lines);
    const selector = senateTermSelector(lines);
    const shortLine = electedShortFrom(lines);
    const parts = parseSurnameFirst(m.name);

    const pageNamesThem = lines.some((l) =>
      normalizeForMatch(l).includes(normalizeForMatch(parts.last)));
    if (!pageNamesThem) {
      report.push(`  WARNING SD${district}: ${parts.full} - own page does not mention the surname`);
    }

    // THE "Legislative Service" PROSE LINE LEADS. It states the CURRENT tenure and
    // segregates earlier, non-contiguous service into a 'prior service YYYY-YYYY'
    // tail, so its leading date already IS continuous occupancy. The compact
    // "Elected M/D/YYYY" line, where the page carries one, is an INDEPENDENT second
    // statement of the same fact and is used to confirm it.
    let assumedOffice, assumedPrecision, source, crossCheck = null;
    if (svc && svc.date) {
      assumedOffice = svc.date;
      assumedPrecision = svc.precision;
      source = `flsenate.gov${m.href} "Legislative Service": ${svc.line}`;
      if (shortLine) {
        if (shortLine.date === svc.date) {
          crossCheck = `confirmed by the page's own "${shortLine.line}"`;
          source += ` [confirmed by "${shortLine.line}"]`;
        } else {
          crossCheck = `DISAGREES: prose gives ${svc.date}, "${shortLine.line}" gives ${shortLine.date}`;
          report.push(`  CONFLICT SD${district} ${parts.full}: ${crossCheck} - a human must settle this`);
        }
      }
    } else if (shortLine) {
      assumedOffice = shortLine.date;
      assumedPrecision = 'day';
      source = `flsenate.gov${m.href} "${shortLine.line}" (no recognised Legislative Service prose line)`;
      report.push(`  FALLBACK SD${district} ${parts.full}: used "${shortLine.line}"`);
    } else {
      assumedOffice = null;
      assumedPrecision = 'unknown';
      source = `flsenate.gov${m.href} - neither a recognised "Elected to the Senate" line nor an "Elected M/D/YYYY" line`;
      report.push(`  UNKNOWN SD${district} ${parts.full}: START DATE UNKNOWN - recorded as unknown, not guessed` +
        (svc && svc.line ? ` (unrecognised line: ${svc.line})` : ''));
    }

    const midFromPhoto = m.photo ? (m.photo.match(/S\d+_(\d+)_/) || [])[1] : null;
    seats.push({
      chamber: 'upper',
      district,
      name: parts.full,
      lastName: parts.last,
      givenNames: parts.given,
      nameSuffix: parts.suffix,
      honorific: parts.honorific,
      preferredName: parts.preferred,
      memberId: midFromPhoto || `S${district}`,
      assumedOffice,
      assumedPrecision,
      howStarted: 'elected',
      portraitUrl: m.photo ? `https://www.flsenate.gov${m.photo}` : null,
      source,
      _rosterName: m.name,
      _serviceLine: svc ? svc.line : null,
      _senateTermSelector: selector,   // EVIDENCE ONLY - never used to decide a date
      _crossCheck: crossCheck,
      _ownPageNamesThem: pageNamesThem,
    });
    process.stderr.write(`\r  senate ${seats.length}/${40 - senateVacancies.length}  `);
  }
  process.stderr.write('\n');

  const covered = new Set([...seats.map((s) => s.district), ...senateVacancies.map((v) => v.district)]);
  if (covered.size !== 40) {
    throw new Error(`FATAL: Senate districts covered = ${covered.size}, expected 40 ` +
      `(${seats.length} seated + ${senateVacancies.length} vacant)`);
  }
  return { seats, vacancies: senateVacancies };
}

// ─── Main ────────────────────────────────────────────────────────────────────

async function main() {
  fs.mkdirSync(DIR, { recursive: true });
  const report = [];
  const house = await buildHouse(report);
  const senate = await buildSenate(report);
  const lower = house.seats;
  const upper = senate.seats;
  const vacancies = [...house.vacancies, ...senate.vacancies];
  const seats = [...lower, ...upper];

  // 🔴 NEITHER CHAMBER IS FULL. Measured 2026-08-28: 116 sitting Representatives with
  // 4 seats awaiting a special election (HD-55, 78, 113, 116), and 39 sitting Senators
  // with 1 vacancy (SD-39). So there are 160 OFFICES but only 155 PEOPLE. Assert the
  // identity rather than a hardcoded count, so a future run with a different number of
  // vacancies still has to add up.
  const lowerVac = vacancies.filter((v) => v.chamber === 'lower');
  const upperVac = vacancies.filter((v) => v.chamber === 'upper');
  if (lower.length + lowerVac.length !== 120) {
    throw new Error(`FATAL: ${lower.length} House seats + ${lowerVac.length} vacancies != 120`);
  }
  if (upper.length + upperVac.length !== 40) {
    throw new Error(`FATAL: ${upper.length} Senate seats + ${upperVac.length} vacancies != 40`);
  }

  const lowerDs = new Set([...lower.map((s) => s.district), ...lowerVac.map((v) => v.district)]);
  if (lowerDs.size !== 120) throw new Error(`FATAL: House covers ${lowerDs.size} distinct districts, expected 120`);
  for (let n = 1; n <= 120; n++) {
    if (!lowerDs.has(n)) throw new Error(`FATAL: House district ${n} is neither seated nor recorded vacant`);
  }
  const upperDs = new Set([...upper.map((s) => s.district), ...upperVac.map((v) => v.district)]);
  if (upperDs.size !== 40) throw new Error(`FATAL: Senate covers ${upperDs.size} distinct districts, expected 40`);
  for (let n = 1; n <= 40; n++) {
    if (!upperDs.has(n)) throw new Error(`FATAL: Senate district ${n} is neither seated nor recorded vacant`);
  }
  // A vacancy and a seated member must never claim the same (chamber, district).
  const clash = vacancies.filter((v) => seats.some((s) => s.chamber === v.chamber && s.district === v.district));
  if (clash.length) {
    throw new Error(`FATAL: ${clash.map((v) => `${v.chamber} ${v.district}`).join(', ')} are BOTH seated and vacant`);
  }
  // A vacancy with no date must say so consistently.
  const badVac = vacancies.filter((v) => v.vacantSince !== null && !/^\d{4}-\d{2}-\d{2}$/.test(v.vacantSince));
  if (badVac.length) throw new Error(`FATAL: ${badVac.length} vacancy/ies with a malformed vacantSince`);
  const badStarted = seats.filter((s) => !['elected', 'appointed', 'unknown'].includes(s.howStarted));
  if (badStarted.length) throw new Error(`FATAL: ${badStarted.length} seat(s) with an invalid howStarted`);
  const badPrec = seats.filter((s) => !['day', 'month', 'year', 'unknown'].includes(s.assumedPrecision));
  if (badPrec.length) throw new Error(`FATAL: ${badPrec.length} seat(s) with an invalid assumedPrecision`);
  const inconsistent = seats.filter((s) => (s.assumedOffice === null) !== (s.assumedPrecision === 'unknown'));
  if (inconsistent.length) {
    throw new Error(`FATAL: ${inconsistent.length} seat(s) where a null date and 'unknown' precision disagree`);
  }
  // A name must never carry a roster marker, a stray comma or an NBSP into full_name.
  // full_name may carry ONE trailing generational suffix (', Jr.' / ', III'), which is
  // the NC precedent. It must never carry a roster marker, a non-breaking space, a
  // doubled space, a leading honorific, or a comma anywhere else.
  const SUFFIX_TAIL = /,\s(Jr\.?|Sr\.?|II|III|IV|V|MD|M\.D\.|DO|D\.O\.|Ph\.?D\.?|Esq\.?)$/i;
  const dirty = seats.filter((s) => {
    const n = s.name;
    if (/\*|\u00a0|\s{2,}/.test(n)) return true;
    if (/^(Dr|Mr|Mrs|Ms|Rev|Hon)\./.test(n)) return true;
    const commas = (n.match(/,/g) || []).length;
    if (commas === 0) return false;
    if (commas > 1) return true;
    return !SUFFIX_TAIL.test(n);
  });
  if (dirty.length) {
    throw new Error(`FATAL: ${dirty.length} name(s) carry a marker: ${dirty.map((s) => JSON.stringify(s.name)).join(' | ')}`);
  }

  const out = { retrievedAt: new Date().toISOString(), seats, vacancies };
  fs.writeFileSync('data/fl-legislature-roster.json', JSON.stringify(out, null, 2), 'utf8');

  console.log(report.join('\n'));
  console.log(`\nOK: House ${lower.length} seated + ${lowerVac.length} vacant = 120; ` +
    `Senate ${upper.length} seated + ${upperVac.length} vacant = 40.`);
  console.log(`  => 160 OFFICES, ${seats.length} PEOPLE, ${vacancies.length} VACANCY/IES. ` +
    'Every district accounted for exactly once.');
  console.log(`  vacancies: ${vacancies.map((v) => `${v.chamber === 'lower' ? 'HD' : 'SD'}-${v.district}` +
    ` (since ${v.vacantSince ?? 'UNKNOWN'})`).join(', ')}`);
  const cnt = (f, v) => seats.filter((s) => s[f] === v).length;
  console.log(`  precision: day ${cnt('assumedPrecision', 'day')}, year ${cnt('assumedPrecision', 'year')}, unknown ${cnt('assumedPrecision', 'unknown')}`);
  console.log(`  howStarted: elected ${cnt('howStarted', 'elected')}, appointed ${cnt('howStarted', 'appointed')}, unknown ${cnt('howStarted', 'unknown')}`);
  console.log(`  own page names them: ${seats.filter((s) => s._ownPageNamesThem).length}/${seats.length}`);
  console.log(`  senate dates confirmed by a second line on the same page: ` +
    `${upper.filter((s) => s._crossCheck && s._crossCheck.startsWith('confirmed')).length}` +
    `; conflicts: ${upper.filter((s) => s._crossCheck && s._crossCheck.startsWith('DISAGREES')).length}`);
  const nonAscii = seats.filter((s) => /[^\u0000-\u007F]/.test(s.name)).map((s) => s.name);
  console.log(`  non-ASCII names (${nonAscii.length}): ${nonAscii.join(', ') || '(none)'}`);
  console.log('  wrote data/fl-legislature-roster.json');
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url) {
  main().catch((e) => { console.error(`\nFATAL: ${e.message}`); process.exit(1); });
}
