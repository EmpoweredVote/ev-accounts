#!/usr/bin/env node
/**
 * Verify a named member's vote on a named federal roll call — House Clerk EVS XML and Senate LIS XML.
 *
 * 🔑 RESOLVE THE ROLL FROM THE CLERK'S OWN INDEX, never from a remembered number. H.R.7691's passage
 * vote is 2022 roll 145; the remembered guess was 209 — 64 away, outside any window one would think
 * to set. The year index (ROLL_000.asp, ROLL_100.asp, …) lists every roll with its bill and question.
 *
 * 🔴 THE BILL NUMBER ALONE IS NOT ENOUGH — a chamber takes many roll calls on one bill. Matching only
 * the number picked an AMENDMENT to H.R.8035 (105-319) and reported it as the Ukraine aid vote
 * (311-112). The question must be passage-shaped too.
 *
 * 🔑 AND EVEN THAT IS NOT UNIQUE: H.R.8404 was passed 267-157 in July 2022 AND concurred 258-169 in
 * December; H.R.3684 passed 221-201 as the INVEST Act before the 228-206 vote that enacted the IIJA.
 * Taking the first hit silently swapped one for the other between two runs of this script, so every
 * matching roll is evaluated and reported.
 *
 * 🔑 SELF-CHECK, free and mandatory: the sheet declares its own totals. Parsed yea/nay must equal
 * <yea-total>/<nay-total> (House) or <yeas>/<nays> (Senate) or the parse is VOID.
 *
 * ⚠ IDENTITY: where a surname is shared the Clerk prints it disambiguated — "Johnson (SD)",
 * "Torres (CA)" — so a bare-surname compare finds NOTHING and reports the member absent from a
 * sheet they actually voted on. Strip the parenthetical, then require the state.
 *
 * 🔴 Reads only. Emits a verdict file.
 *   node scripts/fed-rollcall-verify.mjs --targets <targets.json> --cache <dir> --out <out.json>
 */
import fs from 'node:fs';
import path from 'node:path';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const TARGETS = flag('--targets'), OUT = flag('--out');
const CACHE = flag('--cache', 'C:/Users/Chris/AppData/Local/Temp/ev-stance-cache/fed-vote-cache');
if (!TARGETS || !OUT) { console.error('need --targets --out'); process.exit(2); }
fs.mkdirSync(CACHE, { recursive: true });

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const norm = (s) => (s || '').toUpperCase().replace(/[^A-Z0-9]/g, '');

async function get(url) {
  const f = path.join(CACHE, encodeURIComponent(url).replace(/[^A-Za-z0-9%._-]/g, '_').slice(-180));
  if (fs.existsSync(f) && fs.statSync(f).size > 500) return fs.readFileSync(f, 'utf8');
  const res = await fetch(url, { headers: { 'User-Agent': UA } });
  const body = await res.text();
  if (!res.ok || body.length < 500) return null;
  fs.writeFileSync(f, body);
  await sleep(700);
  return body;
}

function parseHouse(xml) {
  const g = (t) => (xml.match(new RegExp(`<${t}>([^<]*)`)) || [])[1] || '';
  const votes = [];
  for (const m of xml.matchAll(/<recorded-vote>\s*<legislator([^>]*)>([^<]*)<\/legislator>\s*<vote>([^<]*)</g)) {
    const at = (k) => (m[1].match(new RegExp(`${k}="([^"]*)"`)) || [])[1] || '';
    votes.push({ id: at('name-id'), surname: at('sort-field') || m[2], state: at('state'), party: at('party'), vote: m[3].trim() });
  }
  const totals = {};
  for (const m of xml.matchAll(/<totals-by-vote>([\s\S]*?)<\/totals-by-vote>/g)) {
    for (const t of ['yea-total', 'nay-total', 'present-total', 'not-voting-total']) {
      const v = (m[1].match(new RegExp(`<${t}>([^<]*)`)) || [])[1];
      if (v !== undefined) totals[t] = Number(v);
    }
  }
  return { chamber: 'house', legis: g('legis-num'), desc: g('vote-desc'), question: g('vote-question'),
    result: g('vote-result'), date: g('action-date'), votes, totals };
}

function parseSenate(xml) {
  const g = (t) => (xml.match(new RegExp(`<${t}>([^<]*)`)) || [])[1] || '';
  const votes = [];
  for (const m of xml.matchAll(/<member>([\s\S]*?)<\/member>/g)) {
    const b = m[1], f = (t) => (b.match(new RegExp(`<${t}>([^<]*)`)) || [])[1] || '';
    votes.push({ id: f('lis_member_id'), surname: f('last_name'), state: f('state'), party: f('party'), vote: f('vote_cast') });
  }
  return { chamber: 'senate', legis: g('document_name'), desc: g('vote_title'), question: g('question'),
    result: g('vote_result'), date: g('vote_date'), votes,
    totals: { 'yea-total': Number(g('yeas')), 'nay-total': Number(g('nays')) } };
}

const indexCache = new Map();
async function houseIndex(year) {
  if (indexCache.has(year)) return indexCache.get(year);
  const rolls = [];
  for (let p = 0; p <= 1200; p += 100) {
    const h = await get(`https://clerk.house.gov/evs/${year}/ROLL_${String(p).padStart(3, '0')}.asp`);
    if (!h) continue;
    // ⚠ Legacy UPPERCASE HTML (<TR>, <TD>, <A HREF>) — match case-insensitively and split into CELLS
    // on <TD> boundaries. An earlier cut anchored on a lowercase `</a>` and did `.split('')`, which
    // shreds each row into single characters, so every bill lookup silently found nothing.
    for (const row of h.split(/<tr\b/i).slice(1)) {
      const rn = row.match(/rollnumber=(\d+)/i);
      if (!rn) continue;
      const cells = [...row.matchAll(/<td\b[^>]*>([\s\S]*?)<\/td>/gi)]
        .map((c) => c[1].replace(/<[^>]*>/g, ' ').replace(/&nbsp;/gi, ' ').replace(/\s+/g, ' ').trim())
        .filter(Boolean);
      rolls.push({ roll: Number(rn[1]), cells, text: cells.join(' | ') });
    }
  }
  indexCache.set(year, rolls);
  return rolls;
}

const results = [];
for (const t of JSON.parse(fs.readFileSync(TARGETS, 'utf8'))) {
  let window = t.scan ? Array.from({ length: t.scan * 2 + 1 }, (_, i) => t.roll - t.scan + i) : [t.roll];
  if (t.chamber === 'house') {
    const idx = await houseIndex(t.year);
    const wantB = norm(t.expect_bill);
    const hits = idx.filter((r) => r.cells.some((c) => norm(c) === wantB));
    if (hits.length) {
      window = hits.map((r) => r.roll);
      console.log(`   . index: ${t.expect_bill} in ${t.year} -> roll(s) ${window.join(', ')}`);
    }
  }

  const sheets = [];
  for (const roll of window) {
    if (roll < 1) continue;
    const url = t.chamber === 'house'
      ? `https://clerk.house.gov/evs/${t.year}/roll${String(roll).padStart(3, '0')}.xml`
      : `https://www.senate.gov/legislative/LIS/roll_call_votes/vote${t.congress}${t.sess}/vote_${t.congress}_${t.sess}_${String(roll).padStart(5, '0')}.xml`;
    const xml = await get(url);
    if (!xml) continue;
    const s = t.chamber === 'house' ? parseHouse(xml) : parseSenate(xml);
    if (norm(s.legis) !== norm(t.expect_bill)) continue;
    const q = `${s.question || ''} ${s.desc || ''}`;
    const wantQ = t.expect_question ? new RegExp(t.expect_question, 'i')
      : /passage|concur|suspend the rules and (pass|agree)|agree(ing)? to the (concurrent )?resolution|adopt(ing)? the (resolution|conference)/i;
    if (!wantQ.test(q)) continue;
    s.roll = roll; s.url = url;
    sheets.push(s);
  }
  if (!sheets.length) {
    results.push({ ...t, status: 'ROLL_NOT_FOUND' });
    console.log(`NOT-FOUND ${t.label}: no passage-shaped roll matching ${t.expect_bill}`);
    continue;
  }
  if (sheets.length > 1) console.log(`   ! ${t.label}: ${sheets.length} passage-shaped rolls on ${t.expect_bill} - reporting each`);

  for (const sheet of sheets) {
    const yea = sheet.votes.filter((v) => /^(Yea|Aye|Yes)$/i.test(v.vote)).length;
    const nay = sheet.votes.filter((v) => /^(Nay|No)$/i.test(v.vote)).length;
    if (yea !== sheet.totals['yea-total'] || nay !== sheet.totals['nay-total']) {
      results.push({ ...t, roll: sheet.roll, status: 'PARSE_VOID', parsed: { yea, nay }, declared: sheet.totals });
      console.log(`VOID ${t.label} roll ${sheet.roll}: parsed ${yea}/${nay} vs declared ${sheet.totals['yea-total']}/${sheet.totals['nay-total']}`);
      continue;
    }
    const base = (x) => norm(String(x).replace(/\s*\([^)]*\)\s*$/, ''));
    const sameName = sheet.votes.filter((v) => base(v.surname) === base(t.surname));
    const disambiguated = sameName.some((v) => /\(/.test(v.surname)) || sameName.length > 1;
    if (disambiguated && !t.state) {
      results.push({ ...t, roll: sheet.roll, status: 'STATE_REQUIRED', sameName });
      console.log(`AMBIG ${t.label}: surname shared on this sheet and no state given`);
      continue;
    }
    const cands = disambiguated ? sameName.filter((v) => v.state === t.state) : sameName;
    const status = cands.length === 1 ? 'FOUND' : cands.length ? 'AMBIGUOUS' : 'MEMBER_ABSENT_FROM_SHEET';
    results.push({ ...t, status, url: sheet.url, roll: sheet.roll, bill: sheet.legis, desc: sheet.desc,
      question: sheet.question, result: sheet.result, date: sheet.date,
      tally: `${yea}-${nay}`, member: cands.length === 1 ? cands[0] : cands });
    const v = cands.length === 1 ? cands[0].vote : `(${cands.length} matches)`;
    console.log(`${status === 'FOUND' ? 'OK  ' : 'WARN'} ${t.label} [roll ${sheet.roll}, ${sheet.date}] ${sheet.legis} "${sheet.desc}" | ${sheet.question} | ${yea}-${nay} -> ${t.surname} = ${v}`);
  }
}

fs.writeFileSync(OUT, JSON.stringify({ pass: 'federal roll-call verification', results }, null, 1));
console.log(`\nwrote ${OUT}`);
