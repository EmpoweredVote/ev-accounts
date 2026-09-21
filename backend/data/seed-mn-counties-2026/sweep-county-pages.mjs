/**
 * MN-4 change-check: read each of the 19 county officers' own page.
 *
 * Two signals, because MN-2 and MN-3 each found a different one:
 *   WORDS  a resignation or vacancy banner        -- what caught Joe Schomacker (MN-2)
 *   DATES  a "Term Expires" already in the past   -- what the word scanner was BLIND to (MN-3)
 *
 * Neither alone is enough, so both run over every page, and every zero is controlled.
 *
 *   node sweep-county-pages.mjs
 *   node sweep-county-pages.mjs --control
 */
import fs from 'fs';

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36';
const TODAY = new Date('2026-09-15T00:00:00Z');
const RAM = 'https://www.ramseycountymn.gov/your-government/leadership/board-commissioners';
const SLC = 'https://www.stlouiscountymn.gov';

const SEATS = [
  // ── St. Louis County. Its board page carries all seven inline, with term expiries, and
  //    publishes NO per-commissioner page -- so that one page is the source for all seven.
  ['St. Louis', 'District 1', 'Annie Harala', `${SLC}/our-county/board-of-commissioners/current-commissioners`],
  ['St. Louis', 'District 2', 'Patrick Boyle', `${SLC}/our-county/board-of-commissioners/current-commissioners`],
  ['St. Louis', 'District 3', 'Ashley Grimm', `${SLC}/our-county/board-of-commissioners/current-commissioners`],
  ['St. Louis', 'District 4', 'Paul McDonald', `${SLC}/our-county/board-of-commissioners/current-commissioners`],
  ['St. Louis', 'District 5', 'Keith Musolf', `${SLC}/our-county/board-of-commissioners/current-commissioners`],
  ['St. Louis', 'District 6', 'Keith Nelson', `${SLC}/our-county/board-of-commissioners/current-commissioners`],
  ['St. Louis', 'District 7', 'Mike Jugovich', `${SLC}/our-county/board-of-commissioners/current-commissioners`],
  ['St. Louis', 'Sheriff', 'Gordon Ramsay', `${SLC}/departments-a-z/sheriff`],
  ['St. Louis', 'County Attorney', 'Kimberly Maki', `${SLC}/departments-a-z/attorney/about-the-county-attorney`],
  ['St. Louis', 'Auditor', 'Nancy Nilsen', `${SLC}/departments-a-z/auditor`],
  // ── Ramsey County. Seven per-commissioner pages.
  // ⚠ THE SLUGS EMBED BOTH THE NAME AND A ROTATING LEADERSHIP ROLE
  // ('mai-chong-xiong-district-6-board-vice-chair'). The vice-chair rotates annually, so that URL
  // breaks every year -- Saint Paul's ward-7 lesson again. These are re-derived from the board
  // index at run time, never hard-coded.
  ['Ramsey', 'District 1', 'Tara Jebens-Singh', null],
  ['Ramsey', 'District 2', 'Mary Jo McGuire', null],
  ['Ramsey', 'District 3', 'Garrison McMurtrey', null],
  ['Ramsey', 'District 4', 'Rena Moran', null],
  ['Ramsey', 'District 5', 'Rafael E. Ortega', null],
  ['Ramsey', 'District 6', 'Mai Chong Xiong', null],
  ['Ramsey', 'District 7', 'Kelly Miller', null],
  ['Ramsey', 'Sheriff', 'Bob Fletcher', 'https://www.ramseycountymn.gov/your-government/leadership/sheriffs-office'],
  ['Ramsey', 'County Attorney', 'John Choi', 'https://www.ramseycountymn.gov/your-government/leadership/county-attorneys-office'],
];

const strip = (h) =>
  h
    .replace(/<script[\s\S]*?<\/script>/g, ' ')
    .replace(/<style[\s\S]*?<\/style>/g, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
    .replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ');

const WORD_PATTERNS = [
  /\bresign\w*[^.]{0,130}/gi,
  /\bvacan\w*[^.]{0,110}/gi,
  /\bstepp?(?:ed|ing) down[^.]{0,110}/gi,
  /\b(?:deceased|passed away)[^.]{0,90}/gi,
  /\bwas appointed[^.]{0,110}/gi,
  /\bappointed to (?:the |fill)[^.]{0,110}/gi,
  /\bsworn in[^.]{0,110}/gi,
  /\bspecial election[^.]{0,110}/gi,
  /\b(?:interim|acting) (?:commissioner|sheriff|county attorney|auditor)[^.]{0,90}/gi,
  /\bformer (?:commissioner|sheriff|county attorney|auditor)[^.]{0,90}/gi,
];
const scanWords = (t) => {
  const out = [];
  for (const re of WORD_PATTERNS) { const m = t.match(re); if (m) out.push(...m); }
  return [...new Set(out.map((s) => s.trim().replace(/\s+/g, ' ').slice(0, 150)))];
};

/** 🔴 The MN-3 signal: a stated term-expiry date that has already passed. */
const DATE_RE = /Term Expires:\s*(\d{1,2}\/\d{1,2}\/\d{4})/g;
const scanDates = (t) => {
  const out = [];
  let m;
  DATE_RE.lastIndex = 0;
  while ((m = DATE_RE.exec(t))) {
    const [mm, dd, yy] = m[1].split('/').map(Number);
    const iso = `${yy}-${String(mm).padStart(2, '0')}-${String(dd).padStart(2, '0')}`;
    out.push({ stated: m[1], iso, past: new Date(iso + 'T00:00:00Z') < TODAY });
  }
  return out;
};

// ── Resolve Ramsey's per-commissioner URLs from the board index, never from memory.
const boardHtml = await (await fetch(RAM, { headers: { 'User-Agent': UA } })).text();
const ramLinks = [...new Set((boardHtml.match(/\/your-government\/leadership\/board-commissioners\/[a-z0-9-]+/g) || []))]
  .filter((u) => /-district-\d/.test(u));
console.log(`Ramsey board index publishes ${ramLinks.length} per-commissioner link(s)`);
for (const s of SEATS) {
  if (s[0] !== 'Ramsey' || s[3] !== null) continue;
  const n = s[1].replace('District ', '');
  const hit = ramLinks.find((u) => u.includes(`-district-${n}`));
  if (!hit) { console.log(`  ✗ no link found for Ramsey District ${n}`); continue; }
  s[3] = `https://www.ramseycountymn.gov${hit}`;
}

fs.mkdirSync('_county-pages', { recursive: true });
const rows = [];
let i = 0;
async function worker() {
  while (i < SEATS.length) {
    const [county, seat, name, url] = SEATS[i++];
    if (!url) { rows.push({ county, seat, name, url, status: 'NO URL', len: 0, file: null }); continue; }
    const file = `_county-pages/${county.replace(/\W/g, '')}-${seat.replace(/\W/g, '')}.html`;
    try {
      const r = await fetch(url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
      const body = await r.text();
      fs.writeFileSync(file, body);
      rows.push({ county, seat, name, url, status: r.status, len: body.length, file });
    } catch (e) {
      rows.push({ county, seat, name, url, status: 'ERR', err: e.message, len: 0, file: null });
    }
  }
}
await Promise.all(Array.from({ length: 4 }, worker));
rows.sort((a, b) => SEATS.findIndex((s) => s[0] === a.county && s[1] === a.seat) - SEATS.findIndex((s) => s[0] === b.county && s[1] === b.seat));
fs.writeFileSync('_county-pages-index.json', JSON.stringify(rows, null, 1));

const bad = rows.filter((r) => r.status !== 200);
console.log(`\npages fetched: ${rows.length}; non-200: ${bad.length}`);
for (const b of bad) console.log(`  ✗ ${b.county} ${b.seat}: ${b.status}`);

console.log('\n-- IDENTITY + DATES ------------------------------------------------------------');
let idFail = 0;
const notes = [];
for (const r of rows) {
  if (r.status !== 200 || !r.file) { idFail++; continue; }
  const t = strip(fs.readFileSync(r.file, 'utf8'));
  r.text = t;
  const last = r.name.split(/\s+/).slice(-1)[0];
  const hasFull = t.toLowerCase().includes(r.name.toLowerCase());
  const hasLast = new RegExp(`\\b${last}\\b`, 'i').test(t);
  if (!hasFull && !hasLast) { idFail++; console.log(`  ✗ ${r.county} ${r.seat}: page never names ${r.name}`); continue; }

  // A shared page (St. Louis's board page) states every commissioner's date; pick this seat's.
  const dates = scanDates(t);
  let mine = null;
  if (dates.length) {
    const idx = t.indexOf(r.name);
    if (idx >= 0) {
      DATE_RE.lastIndex = 0; let m, best = null;
      while ((m = DATE_RE.exec(t))) if (m.index > idx && (best === null || m.index < best.index)) best = m;
      if (best) {
        const [mm, dd, yy] = best[1].split('/').map(Number);
        const iso = `${yy}-${String(mm).padStart(2, '0')}-${String(dd).padStart(2, '0')}`;
        mine = { stated: best[1], iso, past: new Date(iso + 'T00:00:00Z') < TODAY };
      }
    }
  }
  r.expires = mine;
  const flag = mine ? (mine.past ? `🔴 EXPIRED ${mine.iso}` : `expires ${mine.iso}`) : 'no date on page';
  console.log(`  ${hasFull ? '✓' : '~'} ${r.county.padEnd(10)} ${r.seat.padEnd(16)} ${r.name.padEnd(20)} ${flag}`);
  for (const n of scanWords(t)) notes.push({ ...r, text: undefined, note: n });
}
console.log(`identity failures: ${idFail}`);
const expired = rows.filter((r) => r.expires && r.expires.past);
console.log(`stated terms ALREADY EXPIRED as at ${TODAY.toISOString().slice(0, 10)}: ${expired.length}`);

console.log(`\n-- WORD-SCANNER HITS: ${notes.length} (a reading queue, not a verdict) ------`);
for (const n of notes) console.log(`  ${n.county} ${String(n.seat).padEnd(16)} ${String(n.name).padEnd(20)} :: ${n.note}`);

if (process.argv.includes('--control')) {
  console.log('\n-- CONTROLS --------------------------------------------------------------------');
  const base = rows.find((r) => r.text);
  for (const [label, planted] of [
    ['resignation', 'Commissioner Control resigned effective March 3, 2026'],
    ['vacancy', 'This seat is currently vacant'],
    ['appointment', 'was appointed to fill the vacancy in July 2026'],
    ['interim', 'serving as interim sheriff until the special election'],
  ]) {
    const n = scanWords(base.text + ' ' + planted).length - scanWords(base.text).length;
    console.log(`  words  ${label.padEnd(14)} -> ${n > 0 ? `+${n} OK` : 'NOT REPORTED -- blind to this shape'}`);
  }
  for (const [label, planted, wantPast] of [
    ['a past expiry', 'Term Expires: 1/5/2026', true],
    ['a future expiry', 'Term Expires: 1/4/2027', false],
  ]) {
    const d = scanDates(planted);
    const ok = d.length === 1 && d[0].past === wantPast;
    console.log(`  dates  ${label.padEnd(14)} -> ${ok ? `OK (past=${d[0].past})` : 'FAILED'}`);
  }
}
