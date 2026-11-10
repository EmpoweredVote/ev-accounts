#!/usr/bin/env node
/**
 * CC_0376-parse-nh-council-returns.mjs — the 2026-11-03 Executive Council returns, from the
 * New Hampshire Secretary of State's own per-district workbooks.
 *
 * SOURCE. https://www.sos.nh.gov/2026-general-election-results — "Executive Council District N",
 *   one .xlsx per district, each a town-by-town return with a TOTALS row. These are the clerks'
 *   returns as filed, which is what the Secretary of State publishes and is a long way better
 *   than any aggregator: every town is named and every number is the one the town reported.
 *
 * 🔴 THESE ARE RETURNS, NOT A CERTIFIED CANVASS. The Secretary of State's own page says:
 *   "Tallies accurately reflect the returns of votes reported by clerks but are subject to
 *   change if clerks submit amendments." A call is not a canvass; this file records a RESULT
 *   STATUS of `called` and the migration says so. The Ballot Law Commission certifies later.
 *
 * ⚠ THE WAF BLOCKS BOTH THE PAGES AND THE FILES. www.sos.nh.gov sits behind an Akamai edge that
 *   answers Node's fetch and curl with HTTP 403 "Access Denied" even with a browser User-Agent —
 *   on the .xlsx files as well as the HTML, so the usual "the challenge covers pages but leaves
 *   files open" escape does not apply here. The workbooks were pulled through Playwright and are
 *   committed beside this script; this parser reads them from disk and never fetches.
 *
 * 🟢 THE RETURN SHEETS ARE A THIRD, INDEPENDENT STATEMENT OF THE DISTRICT COMPOSITION, AND THIS
 *   FILE USES THEM AS ONE. Each workbook lists exactly the towns that voted in that district's
 *   race. That is neither the NHGRANIT map nor RSA 662:2 — it is what actually happened at the
 *   polls — so agreeing with the statute is real corroboration and not a restatement. Every town
 *   must match, in both directions, or this refuses to emit.
 *
 * 🔴 THE SHEETS ABBREVIATE. "At.& Gil. Ac. Gt." is Atkinson and Gilmanton Academy Grant, and
 *   there are others. Every abbreviation is DECLARED in ALIASES below, never guessed by a fuzzy
 *   matcher, and an unmatched name is a hard error — the whole value of this cross-check is that
 *   it can disagree.
 *
 * 🔴 THE WINNER IS READ OFF THE VOTES, NOT OFF A CALL, AND THE LOSERS ARE NOT INFERRED. Every
 *   candidate on the sheet gets an explicit status. The TOTALS row is checked against the sum of
 *   the town rows, so a truncated or partially-parsed sheet cannot pass as a complete one.
 *
 * Usage (from backend/):
 *   node scripts/CC_0376-parse-nh-council-returns.mjs <resultsdir> <composition.json> <out.json>
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const XLSX = require('xlsx');

const [RESDIR, COMP_PATH, OUT] = process.argv.slice(2);
if (!RESDIR || !COMP_PATH || !OUT) {
  throw new Error('usage: CC_0376-parse-nh-council-returns.mjs <resultsdir> <composition.json> <out.json>');
}

const ELECTION_DATE = '2026-11-03';
const PAGE = 'https://www.sos.nh.gov/2026-general-election-results';

// 🔴 DECLARED, REVIEWABLE ABBREVIATIONS. Keys are already lowercased, apostrophe-stripped and
//    &-expanded — the same shape norm() produces — so that a key cannot silently fail to match
//    because of the order the replacements run in. The first version of this table was written
//    in the sheets' own spelling ("at.& gil. ac. gt.") and never matched anything, because
//    norm() had already turned "&" into "and" before the lookup.
const ALIASES = new Map([
  ['at.and gil. ac. gt.', 'atkinson and gilmanton academy grant'],
  ['at. and gil. ac. gt.', 'atkinson and gilmanton academy grant'],
  ['thompson and meserves', 'thompson and meserves purchase'],
  ['thompson and meserves pur.', 'thompson and meserves purchase'],
  ['low and burbanks gt.', 'low and burbanks grant'],
  ['second college gt.', 'second college grant'],
  ['waterville val.', 'waterville valley'],
]);

// 🟢 NEW HAMPSHIRE CITIES VOTE BY WARD, AND THE RETURN SHEETS REPORT THEM THAT WAY. Dover,
//    Franklin, Laconia, Rochester and Somersworth each appear as six or so "X Ward N" rows in
//    District 1 alone, while RSA 662:2 names the whole city. Berlin, also a city, reports as one
//    row — so this is each city's own practice, not a rule, and an exclusion list would go stale.
//    ▶ Wards are folded into their city for the SET comparison only. Vote totals are summed from
//    every row either way, and the count of rows folded is printed, so the folding is visible
//    rather than silent.
//    ⚠ This is safe for the councilor map precisely because RSA 662:2 assigns whole cities. It
//    would NOT be safe for RSA 662:1, where the congressional districts do split wards.
let wardRowsFolded = 0;
function norm(s) {
  let k = String(s).toLowerCase()
    .replace(/&/g, 'and')
    .replace(/['‘’]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
  const unwarded = k.replace(/\s+ward\s+\d+$/, '');
  if (unwarded !== k) { wardRowsFolded++; k = unwarded; }
  if (ALIASES.has(k)) return ALIASES.get(k);
  k = k
    .replace(/\bgt\.$/, 'grant')
    .replace(/\bpur\.$/, 'purchase')
    .replace(/\bloc\.$/, 'location')
    .replace(/\btwp\.$/, '')
    .replace(/\s+(town|city|township)$/, '')
    .replace(/\s+/g, ' ')
    .trim();
  return ALIASES.get(k) ?? k;
}

const comp = JSON.parse(fs.readFileSync(COMP_PATH, 'utf8'));
const statuteByDistrict = new Map();
for (const t of comp.towns) {
  if (!statuteByDistrict.has(t.district)) statuteByDistrict.set(t.district, new Map());
  statuteByDistrict.get(t.district).set(norm(t.statuteName), t.statuteName);
}

const districts = [];
for (let d = 1; d <= 5; d++) {
  const file = path.join(RESDIR, `d${d}.xlsx`);
  if (!fs.existsSync(file)) throw new Error(`${file} does not exist`);
  const buf = fs.readFileSync(file);
  if (buf.slice(0, 2).toString('latin1') !== 'PK') {
    throw new Error(`${file} is not a workbook — it starts "${buf.slice(0, 40).toString('latin1')}". ` +
      `The Secretary of State's WAF answers 403 with an HTML body; this is probably that.`);
  }
  const sha = crypto.createHash('sha256').update(buf).digest('hex');
  const wb = XLSX.read(buf, { type: 'buffer' });
  const rows = XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]], { header: 1, blankrows: false, defval: '' });

  // The sheet identifies itself; assert it before reading a single number.
  const banner = rows.slice(0, 4).map(r => String(r[0] ?? '')).join(' | ');
  if (!/Executive Council\s*[-–]\s*District No\.\s*(\d+)/i.test(banner)) {
    throw new Error(`d${d}: the sheet does not identify itself as an Executive Council district return: "${banner}"`);
  }
  const said = Number(banner.match(/District No\.\s*(\d+)/i)[1]);
  if (said !== d) throw new Error(`d${d}.xlsx is the return for District ${said}`);

  // The header row is the one whose first cell is the election date and whose other cells name
  // the candidates. Find it rather than assuming an index.
  const hi = rows.findIndex(r => /NOVEMBER\s+0?3,\s*2026/i.test(String(r[0] ?? '')));
  if (hi < 0) throw new Error(`d${d}: no row carries the election date — the sheet layout has changed`);
  const header = rows[hi];
  const cands = [];
  for (let c = 1; c < header.length; c++) {
    const label = String(header[c] ?? '').trim();
    if (!label || /^write-?ins?$/i.test(label)) continue;
    const m = label.match(/^(.*?),\s*([a-z]+)$/i);
    if (!m) throw new Error(`d${d}: cannot read a candidate from "${label}" — expected "Name, party"`);
    cands.push({ col: c, name: m[1].trim(), partyLetter: m[2].toLowerCase() });
  }
  if (cands.length < 1) throw new Error(`d${d}: no candidates found on the header row`);
  const writeInCol = header.findIndex(h => /^write-?ins?$/i.test(String(h ?? '').trim()));

  const totalsIdx = rows.findIndex(r => /^totals?$/i.test(String(r[0] ?? '').trim()));
  if (totalsIdx < 0) throw new Error(`d${d}: no TOTALS row — the sheet may be truncated`);

  const townRows = rows.slice(hi + 1, totalsIdx).filter(r => String(r[0] ?? '').trim());
  if (!townRows.length) throw new Error(`d${d}: no town rows between the header and TOTALS`);

  const sums = {};
  for (const c of cands) sums[c.name] = 0;
  let writeIns = 0;
  const sheetTowns = new Map();
  for (const r of townRows) {
    const raw = String(r[0]).trim();
    sheetTowns.set(norm(raw), raw);
    for (const c of cands) {
      const v = r[c.col];
      const n = v === '' || v == null ? 0 : Number(v);
      if (!Number.isFinite(n)) throw new Error(`d${d}: ${raw} has a non-numeric vote "${v}" for ${c.name}`);
      sums[c.name] += n;
    }
    if (writeInCol > -1) {
      const v = r[writeInCol];
      const n = v === '' || v == null ? 0 : Number(v);
      if (!Number.isFinite(n)) throw new Error(`d${d}: ${raw} has a non-numeric write-in count "${v}"`);
      writeIns += n;
    }
  }

  // 🔴 The TOTALS row the state printed must equal the town rows this parser read. A sheet that
  //    was truncated, or a column read off by one, fails here instead of producing a plausible
  //    number.
  const totalsRow = rows[totalsIdx];
  for (const c of cands) {
    const printed = Number(totalsRow[c.col] ?? 0);
    if (printed !== sums[c.name]) {
      throw new Error(`d${d}: ${c.name} — the sheet's TOTALS says ${printed}, the ${townRows.length} ` +
        `town rows sum to ${sums[c.name]}`);
    }
  }

  // 🟢 THE CROSS-CHECK: the towns that voted, against the towns RSA 662:2 assigns.
  const statute = statuteByDistrict.get(d);
  const onlySheet = [...sheetTowns.keys()].filter(k => !statute.has(k)).map(k => sheetTowns.get(k));
  const onlyStatute = [...statute.keys()].filter(k => !sheetTowns.has(k)).map(k => statute.get(k));
  if (onlySheet.length || onlyStatute.length) {
    throw new Error(`d${d}: the Secretary of State's return and RSA 662:2 disagree about which towns ` +
      `are in this district. On the return only: ${onlySheet.join(', ') || '(none)'}. ` +
      `In the statute only: ${onlyStatute.join(', ') || '(none)'}.`);
  }

  const ranked = cands.map(c => ({ ...c, votes: sums[c.name] })).sort((a, b) => b.votes - a.votes);
  const cast = ranked.reduce((s, c) => s + c.votes, 0) + writeIns;
  if (ranked.length > 1 && ranked[0].votes === ranked[1].votes) {
    throw new Error(`d${d}: ${ranked[0].name} and ${ranked[1].name} are tied on ${ranked[0].votes} — stop and read the canvass`);
  }
  const margin = ranked[0].votes - (ranked[1]?.votes ?? 0);

  districts.push({
    district: d,
    electionDate: ELECTION_DATE,
    towns: townRows.length,
    ballotsCounted: cast,
    writeIns,
    // Every candidate carries an EXPLICIT status. Nothing is inferred from "not the winner".
    candidates: ranked.map((c, i) => ({
      name: c.name,
      party: { d: 'Democratic', r: 'Republican', l: 'Libertarian', i: 'Independent' }[c.partyLetter] ?? c.partyLetter,
      partyLetter: c.partyLetter,
      votes: c.votes,
      pct: Number((c.votes / cast * 100).toFixed(2)),
      status: i === 0 ? 'won' : 'lost',
    })),
    winner: ranked[0].name,
    margin,
    marginPct: Number((margin / cast * 100).toFixed(2)),
    resultStatus: 'called',
    sha256: sha,
  });

  const w = districts[d - 1];
  w.distinctPlaces = sheetTowns.size;
  console.log(`District ${d}: ${w.towns} reporting rows -> ${sheetTowns.size} places · ${w.ballotsCounted} ballots · ` +
    w.candidates.map(c => `${c.name} (${c.partyLetter}) ${c.votes} ${c.pct}%`).join(' · ') +
    ` · write-ins ${writeIns} → ${w.winner} by ${margin} (${w.marginPct}%)`);
}

if (districts.length !== 5) throw new Error(`parsed ${districts.length} districts, expected 5`);
console.log(`\nall 5 districts: the places that voted match RSA 662:2 exactly, in both directions ` +
  `(${wardRowsFolded} city-ward rows folded into their city for the set comparison; every ward's ` +
  `votes are counted either way)`);

fs.writeFileSync(OUT, JSON.stringify({
  body: 'New Hampshire Executive Council',
  electionDate: ELECTION_DATE,
  source: `New Hampshire Secretary of State, 2026 General Election Results, "Executive Council District N" ` +
    `workbooks (${PAGE}), retrieved 2026-11-08`,
  caveat: `The Secretary of State states that these tallies reflect the returns reported by clerks and ` +
    `are subject to change if clerks submit amendments. They are returns, not a certified canvass.`,
  crossCheck: 'the towns listed on each return sheet equal the towns RSA 662:2 assigns to that district, both directions',
  districts,
}, null, 1));
console.log(`wrote ${OUT}`);
