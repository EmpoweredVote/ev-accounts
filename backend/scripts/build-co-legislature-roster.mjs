#!/usr/bin/env node
/**
 * build-co-legislature-roster.mjs
 *
 * Reconciles the Colorado General Assembly roster across THREE independent
 * sources and writes data/co-legislature-roster.json for the seeding migration.
 * Reads nothing from the database and writes nothing to it.
 *
 * WHY THREE. Open States is a detector, not an oracle — it lagged our TX SD-22
 * fix and dropped a sitting TX HD-93 member. Ballotpedia is the only one of the
 * three carrying an assumed-office DATE, which office_terms needs and which
 * neither of the others has. The chamber's own roster is the tiebreaker on
 * identity. A seat is only emitted when all three name the same person.
 *
 *   1. leg.colorado.gov/legislators  — the chamber's own table. AUTHORITATIVE for
 *      identity, district, party and the canonical spelling of the name.
 *   2. data.openstates.org           — independent cross-check; also supplies the
 *      official leg.colorado.gov portrait URL used by the headshot pass.
 *   3. ballotpedia.org               — the ONLY source of "Date assumed office",
 *      which is what office_terms.term_start actually means: the day this person
 *      began holding THIS seat, not the start of the current two-year term.
 *
 * ⚠ DO NOT SUBSTITUTE WIKIPEDIA'S "Start" COLUMN FOR THE ASSUMED-OFFICE DATE.
 * Measured 2026-08-21: that column is the ELECTION year for elected members and
 * the APPOINTMENT year for appointees, in the same column. Marc Snyder shows
 * 2024 but took the SD-12 seat on 2025-01-08. Using it directly puts a wrong
 * year on most of the chamber, and start_precision='year' does not excuse a
 * wrong year. Ballotpedia gives the actual day; Wikipedia is used here only to
 * cross-check the Senate's next-election year.
 *
 * ⚠ THE CHAMBER'S OWN TABLE CARRIES 101 ROWS, NOT 100. Senate District 21 is
 * listed twice: once for Dafna Michaelson Jenet annotated "resigned as of
 * 2/13/26" and once for her successor. A naive count reads as an extra member;
 * a naive per-district join fans out. The resigned row is dropped by
 * RESIGNED_MARKER below, and the drop is asserted, not assumed — if the page
 * stops annotating resignations this script fails rather than seating a
 * predecessor.
 *
 * Name-form variance between sources is expected and is NOT a mismatch
 * (Andrew/Andy Boesenecker, Anthony/Tony Hartsook, Larry Don/Larry Suckla,
 * Matthew/Matt Martinez). Comparison is on normalized names; the emitted
 * full_name is the chamber's own spelling, with the short form kept as
 * preferred_name when the two differ.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   node scripts/build-co-legislature-roster.mjs
 *   node scripts/build-co-legislature-roster.mjs --out data/co-legislature-roster.json
 */

import fs from 'node:fs';
import path from 'node:path';

const OUT = (() => {
  const i = process.argv.indexOf('--out');
  return i > -1 ? process.argv[i + 1] : 'data/co-legislature-roster.json';
})();

const UA = { 'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' };
const RESIGNED_MARKER = /resigned as of/i;

const strip = (s) =>
  String(s)
    .replace(/<[^>]+>/g, ' ')
    .replace(/&#\d+;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

/**
 * 🔴 ORDER IS LOAD-BEARING — same rule as roster-diff.mjs. NFD decomposes "ñ"
 * into "n" + U+0303, so the combining marks must be DELETED, not replaced with a
 * space: replacing turns Muñoz into "mun oz", which then fails to match the
 * already-ASCII spelling on another source.
 */
function normName(s) {
  return String(s || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/\b(jr|sr|ii|iii|iv|v|md|phd|dds|esq)\b/g, '')
    .replace(/[^a-z ]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** "Amabile, Judy" -> "Judy Amabile"; passes through anything without a comma. */
const flipName = (n) =>
  n.includes(',') ? n.split(',').map((s) => s.trim()).filter(Boolean).reverse().join(' ') : n.trim();

const seatKey = (chamber, district) => `${chamber === 'upper' ? 'S' : 'H'}${parseInt(district, 10)}`;

function parseCSV(text) {
  const rows = [];
  let row = [], cur = '', q = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (q) {
      if (c === '"') { if (text[i + 1] === '"') { cur += '"'; i++; } else q = false; }
      else cur += c;
    } else if (c === '"') q = true;
    else if (c === ',') { row.push(cur); cur = ''; }
    else if (c === '\n') { row.push(cur); rows.push(row); row = []; cur = ''; }
    else if (c !== '\r') cur += c;
  }
  if (cur || row.length) { row.push(cur); rows.push(row); }
  return rows;
}

async function get(url) {
  const r = await fetch(url, { headers: UA });
  if (!r.ok) throw new Error(`${url} -> HTTP ${r.status}`);
  return r.text();
}

// ─── 1. leg.colorado.gov — the chamber's own roster ──────────────────────────
async function fetchOfficial() {
  const html = await get('https://leg.colorado.gov/legislators');
  const body = html.slice(html.indexOf('leg-data'));
  const out = [];
  let dropped = 0;
  for (const m of body.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/g)) {
    const cells = [...m[1].matchAll(/data-label="([^"]+)"[^>]*>([\s\S]*?)<\/(?:td|th)>/g)];
    const o = Object.fromEntries(cells.map((c) => [c[1], strip(c[2])]));
    if (!o.Name || !o.Title) continue;
    if (RESIGNED_MARKER.test(o.Name)) { dropped++; continue; }
    out.push({
      chamber: /senator/i.test(o.Title) ? 'upper' : 'lower',
      district: String(parseInt(o.District, 10)),
      name: flipName(o.Name),
      party: /republican/i.test(o.Party) ? 'Republican' : /democrat/i.test(o.Party) ? 'Democratic' : o.Party,
      email: (o.Email || '').toLowerCase(),
    });
  }
  return { rows: out, dropped };
}

// ─── 2. Open States ──────────────────────────────────────────────────────────
async function fetchOpenStates() {
  const csv = parseCSV((await get('https://data.openstates.org/people/current/co.csv')).trim());
  const h = csv[0];
  const ix = (n) => h.indexOf(n);
  return csv.slice(1).map((r) => ({
    chamber: r[ix('current_chamber')],
    district: String(parseInt(r[ix('current_district')], 10)),
    name: r[ix('name')],
    party: r[ix('current_party')],
    email: (r[ix('email')] || '').toLowerCase(),
    image: r[ix('image')] || null,
  }));
}

// ─── 3. Ballotpedia — the assumed-office date ────────────────────────────────
async function fetchBallotpedia(url, chamber, expected) {
  const t = await get(url);
  for (const tbl of [...t.matchAll(/<table[\s\S]*?<\/table>/g)].map((m) => m[0])) {
    if (!/date assumed office/i.test(tbl)) continue;
    const rows = [...tbl.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/g)]
      .slice(1)
      .map((r) => [...r[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/g)].map((c) => strip(c[1])))
      .filter((c) => c.length >= 4);
    if (rows.length !== expected) continue;
    return rows.map((c) => {
      const d = c[0].match(/District\s+(\d+)/i);
      return {
        chamber,
        district: d ? d[1] : null,
        name: c[1],
        party: c[2],
        assumedOffice: c[3],
      };
    });
  }
  throw new Error(`${url}: no "Date assumed office" table with ${expected} rows`);
}

const MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December'];

/**
 * "January 8, 2025" -> { date: '2025-01-08', precision: 'day' }
 * "2019"            -> { date: '2019-01-01', precision: 'year' }
 *
 * The year-only form is NOT a parse failure and must not be padded to a guessed
 * day: CLAUDE.md's honesty rule is that a source saying only "2019" becomes
 * 2019-01-01 at YEAR precision. Exactly one seat needs this as of 2026-08-21
 * (SD 26, Jeff Bridges), and the count is asserted below so that a future
 * scrape silently degrading to bare years fails loudly instead of quietly
 * publishing a chamber full of January-1sts.
 *
 * Anything else returns null and blocks the emit — a date we cannot read is not
 * a date we may invent.
 */
function toISODate(s) {
  const raw = String(s).trim();
  const full = raw.match(/^([A-Z][a-z]+)\s+(\d{1,2}),\s*(\d{4})$/);
  if (full) {
    const mi = MONTHS.indexOf(full[1]);
    if (mi < 0) return null;
    return { date: `${full[3]}-${String(mi + 1).padStart(2, '0')}-${String(full[2]).padStart(2, '0')}`, precision: 'day' };
  }
  const monthOnly = raw.match(/^([A-Z][a-z]+)\s+(\d{4})$/);
  if (monthOnly) {
    const mi = MONTHS.indexOf(monthOnly[1]);
    if (mi >= 0) return { date: `${monthOnly[2]}-${String(mi + 1).padStart(2, '0')}-01`, precision: 'month' };
  }
  const yearOnly = raw.match(/^(\d{4})$/);
  if (yearOnly) return { date: `${yearOnly[1]}-01-01`, precision: 'year' };
  return null;
}

/**
 * How many seats are allowed to arrive at less than day precision. Measured
 * 2026-08-21: 1 (SD 26). Raising this is a decision that more of the chamber
 * carries a date we did not actually read, not a formality.
 */
const MAX_IMPRECISE_SEATS = 1;

async function main() {
  const [{ rows: official, dropped }, os, bpH, bpS] = await Promise.all([
    fetchOfficial(),
    fetchOpenStates(),
    fetchBallotpedia('https://ballotpedia.org/Colorado_House_of_Representatives', 'lower', 65),
    fetchBallotpedia('https://ballotpedia.org/Colorado_State_Senate', 'upper', 35),
  ]);
  const bp = [...bpH, ...bpS];

  console.log(`official  ${official.length} rows (${dropped} resigned row(s) dropped)`);
  console.log(`openstates ${os.length} rows`);
  console.log(`ballotpedia ${bp.length} rows`);

  // The resigned-row drop is asserted, not assumed.
  if (dropped < 1) {
    throw new Error(
      'Expected at least one "resigned as of" row on leg.colorado.gov (SD 21 as of 2026-08-21). ' +
      'None found — the page may have stopped annotating resignations, in which case a duplicate ' +
      'district row would silently seat a predecessor. Re-verify before seeding.',
    );
  }

  const byKey = (arr) => {
    const m = new Map();
    for (const r of arr) {
      const k = seatKey(r.chamber, r.district);
      if (m.has(k)) throw new Error(`duplicate seat ${k} after dropping resigned rows`);
      m.set(k, r);
    }
    return m;
  };
  const O = byKey(official), S = byKey(os), B = byKey(bp);

  const expected = [
    ...Array.from({ length: 35 }, (_, i) => `S${i + 1}`),
    ...Array.from({ length: 65 }, (_, i) => `H${i + 1}`),
  ];

  const seats = [];
  const problems = [];
  for (const k of expected) {
    const o = O.get(k), s = S.get(k), b = B.get(k);
    if (!o || !s || !b) {
      problems.push(`${k}: missing from ${[!o && 'official', !s && 'openstates', !b && 'ballotpedia'].filter(Boolean).join(', ')}`);
      continue;
    }
    const names = [o.name, s.name, b.name].map(normName);
    if (new Set(names).size !== 1) {
      // Name-form variance is fine as long as the FAMILY name agrees; a different
      // family name means the sources disagree about the PERSON.
      const fam = new Set(names.map((n) => n.split(' ').slice(-1)[0]));
      if (fam.size !== 1) {
        problems.push(`${k}: sources name different people — official "${o.name}", openstates "${s.name}", ballotpedia "${b.name}"`);
        continue;
      }
    }
    const parties = new Set([o.party, s.party, b.party].map((p) => (/^R/i.test(p) ? 'R' : /^D/i.test(p) ? 'D' : p)));
    if (parties.size !== 1) {
      problems.push(`${k}: party disagreement — official "${o.party}", openstates "${s.party}", ballotpedia "${b.party}"`);
      continue;
    }
    const iso = toISODate(b.assumedOffice);
    if (!iso) {
      problems.push(`${k}: unparseable assumed-office date "${b.assumedOffice}" — refusing to guess`);
      continue;
    }
    const preferred = normName(o.name) !== normName(s.name) ? s.name : null;
    seats.push({
      seat: k,
      chamber: o.chamber,
      district: Number(o.district),
      full_name: o.name,
      preferred_name: preferred,
      party: o.party,
      email: o.email || s.email || null,
      photo_origin_url: s.image || null,
      term_start: iso.date,
      start_precision: iso.precision,
      assumed_office_raw: b.assumedOffice,
      openstates_name: s.name,
      ballotpedia_name: b.name,
    });
  }

  console.log(`\nreconciled seats: ${seats.length}/100`);
  const withPhoto = seats.filter((x) => x.photo_origin_url).length;
  console.log(`  with a portrait URL: ${withPhoto}  (headshot backlog: ${seats.length - withPhoto})`);
  const nameVariants = seats.filter((x) => x.preferred_name);
  console.log(`  benign name-form differences: ${nameVariants.length}`);
  for (const v of nameVariants) console.log(`    ${v.seat}: "${v.full_name}" / "${v.preferred_name}"`);
  const years = {};
  for (const s of seats) years[s.term_start.slice(0, 4)] = (years[s.term_start.slice(0, 4)] || 0) + 1;
  console.log(`  assumed-office years: ${JSON.stringify(years)}`);

  const imprecise = seats.filter((s) => s.start_precision !== 'day');
  console.log(`  below day precision: ${imprecise.length} (allowance ${MAX_IMPRECISE_SEATS})`);
  for (const s of imprecise) console.log(`    ${s.seat} ${s.full_name}: "${s.assumed_office_raw}" -> ${s.term_start} (${s.start_precision})`);
  if (imprecise.length > MAX_IMPRECISE_SEATS) {
    problems.push(
      `${imprecise.length} seats carry an assumed-office date below day precision, above the ` +
      `allowance of ${MAX_IMPRECISE_SEATS}. That usually means the scrape degraded, not that the ` +
      `chamber changed — a wall of January-1sts is a broken parse wearing a valid date.`,
    );
  }

  if (problems.length) {
    console.error(`\n${problems.length} unresolved seat(s) — NOT emitting a partial roster:`);
    for (const p of problems) console.error(`  ${p}`);
    process.exit(1);
  }

  const payload = {
    generated_for: 'Colorado General Assembly seeding (Colorado Springs deep seed)',
    sources: {
      official: 'https://leg.colorado.gov/legislators',
      openstates: 'https://data.openstates.org/people/current/co.csv',
      ballotpedia_house: 'https://ballotpedia.org/Colorado_House_of_Representatives',
      ballotpedia_senate: 'https://ballotpedia.org/Colorado_State_Senate',
    },
    note: 'term_start is Ballotpedia\'s "Date assumed office" — the day this person began holding THIS seat, not the start of the current two-year term. Identity, district, party and name spelling are the chamber\'s own; a seat is emitted only when all three sources name the same person.',
    seats,
  };
  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  fs.writeFileSync(OUT, JSON.stringify(payload, null, 2) + '\n');
  console.log(`\nwrote ${OUT}`);
}

main().catch((e) => { console.error('FATAL:', e.message); process.exit(1); });
