// resolve-al-sboe.mjs — settle, against the pages themselves, the thirteen people CC_0370 seeds.
//
// Two jobs, and they are different questions:
//   1. SOURCE. Every politician row gets a Ballotpedia page as its source. The seven 2026
//      candidates come with their URL in the committed capture; the six sitting members who were
//      not on the 2026 ballot do not, so a slug is proposed and then TESTED. 🔴 A departed
//      official's URL can serve their successor with no redirect and no error, so the page must
//      NAME the person and say they are on the Alabama State Board of Education before the URL
//      is recorded as their source.
//   2. COLLISION. Production holds tens of thousands of politicians. This prints every existing
//      row that shares a full name, or a (first, last) split, with anyone this file seeds, so a
//      namesake is decided before the migration runs rather than excused by it.
//      ⚠ "Emily Jones" and "Angela Morgan" are exactly the kind of name that already exists.
//
// Usage (from backend/):  node data/state-exec-2026-results/resolve-al-sboe.mjs
import fs from 'node:fs';
import { createRequire } from 'node:module';
const req = createRequire('C:/EV-Accounts/backend/package.json');
const pg = req('pg');
const dotenv = req('dotenv');
dotenv.config({ path: 'C:/EV-Accounts/backend/.env' });

const DIR = 'C:/ev-accounts-stateexec/backend/data/state-exec-2026-results';
const BP = JSON.parse(fs.readFileSync(`${DIR}/ballotpedia-all-states-2026-11-06.json`, 'utf8'));

// The sitting members, from the board's own page (alabamaachieves.org/state-board-of-education,
// read 2026-11-07) cross-checked against Ballotpedia's officeholder table. Where the two differ
// it is only in form — the board page prints degrees and maiden names ("Yvette M. Richardson,
// Ed.D.", "Kelly McCarthy Mooney", "Tonya S. Chestnut, Ed.D.") — so Ballotpedia's plain form is
// used, because the Ballotpedia page is the source each row cites.
const HOLDERS = [
  [1, 'Jackie Zeigler', 'Jackie_Zeigler'],
  [2, 'Tracie West', null],
  [3, 'Kelly Mooney', 'Kelly_Mooney'],
  [4, 'Yvette Richardson', null],
  [5, 'Tonya Smith Chestnut', 'Tonya_Smith_Chestnut'],
  [6, 'Marie Manning', 'Marie_Manning'],
  [7, 'Allen Long', 'Allen_Long_(Alabama)'],
  [8, 'Wayne Reynolds', 'Wayne_Reynolds'],
];

const races = BP.filter(r => r.st === 'AL' && /^State Board of Education District \d$/.test(r.office));
if (races.length !== 4) throw new Error(`expected 4 Alabama SBOE races in the capture, found ${races.length}`);

const urls = new Map();
for (const r of races) for (const c of r.candidates) urls.set(c.name, c.url);
for (const [, name, slug] of HOLDERS) {
  if (urls.has(name)) continue;
  if (!slug) throw new Error(`${name} is not in the capture and has no proposed slug`);
  urls.set(name, `https://ballotpedia.org/${slug}`);
}

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';
const text = h => h.replace(/<script[\s\S]*?<\/script>/g, ' ').replace(/<style[\s\S]*?<\/style>/g, ' ')
  .replace(/<[^>]+>/g, ' ').replace(/&#(\d+);/g, (_, d) => String.fromCharCode(+d))
  .replace(/&amp;/g, '&').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ');

console.log('── SOURCES ──');
const verified = [];
for (const [name, url] of urls) {
  const r = await fetch(url, { headers: { 'User-Agent': UA } });
  const body = await r.text();
  const t = text(body);
  // ⚠ a clean 200 is not a confirmation: assert the page is ABOUT this person and this board.
  const namesThem = t.includes(name);
  const board = /Alabama State Board of Education/i.test(t);
  // 🔴 A DISAMBIGUATION PAGE NAMES THE PERSON AND IS NOT THEIR PAGE. /Allen_Long returned HTTP
  //   200 and the words "Allen Long", and is a list of two different men — "Allen Long may
  //   refer to: Allen Long (Alabama), Allen Long (California)". Only the board test caught it,
  //   and a board test would not catch the same thing for a name whose other bearer is also on
  //   a school board, so it is named directly.
  const disambig = /\bmay refer to\b/i.test(t) || /All disambiguation pages/i.test(t);
  const redirected = r.url !== url;
  verified.push({ name, url, http: r.status, namesThem, board, disambig, finalUrl: r.url });
  console.log(`${r.status} ${namesThem ? 'NAMES' : '🔴 does NOT name'} ${board ? 'BOARD' : '🔴 no board mention'}` +
    `${disambig ? ' 🔴 DISAMBIGUATION PAGE' : ''}${redirected ? ' ↪ ' + r.url : ''}  ${name.padEnd(22)} ${url}`);
}
const badSrc = verified.filter(v => v.http !== 200 || !v.namesThem || !v.board || v.disambig);
console.log(badSrc.length ? `🔴 ${badSrc.length} source(s) did not verify` : `🟢 all ${verified.length} sources name the person and the board`);

console.log('\n── COLLISIONS ──');
const split = n => { const i = n.lastIndexOf(' '); return [n.slice(0, i), n.slice(i + 1)]; };
const people = [...urls.keys()].map(n => { const [f, l] = split(n); return { full: n, first: f, last: l }; });
for (const p of people) if (p.full !== `${p.first} ${p.last}`) throw new Error(`${p.full} does not match its own split`);

const c = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await c.connect();
// positive control: the index must be able to see somebody who is certainly there
const ctl = await c.query(`SELECT count(*)::int n FROM essentials.politicians WHERE full_name = 'Tommy Tuberville'`);
if (ctl.rows[0].n < 1) throw new Error('the politicians table cannot see a name known to exist — the sweep would be blind');
const total = await c.query(`SELECT count(*)::int n FROM essentials.politicians`);
console.log(`(sweeping ${total.rows[0].n} politicians; positive control found Tommy Tuberville)`);

for (const p of people) {
  const r = await c.query(
    `SELECT id, full_name, first_name, last_name, is_active, is_incumbent, source
       FROM essentials.politicians
      WHERE lower(full_name) = lower($1)
         OR (lower(first_name) = lower($2) AND lower(last_name) = lower($3))
      ORDER BY is_active DESC, full_name`, [p.full, p.first, p.last]);
  if (!r.rowCount) { console.log(`   ${p.full.padEnd(22)} — clear`); continue; }
  console.log(`🔴 ${p.full.padEnd(22)} — ${r.rowCount} existing row(s):`);
  for (const x of r.rows) {
    console.log(`      ${x.id}  ${x.full_name} (${x.first_name}|${x.last_name}) active=${x.is_active} incumbent=${x.is_incumbent}`);
    console.log(`         source: ${(x.source ?? '—').slice(0, 150)}`);
  }
}
await c.end();

fs.writeFileSync(`${DIR}/al-sboe-sources-2026-11-07.json`, JSON.stringify({
  measured: '2026-11-07',
  note: 'Ballotpedia page per person, each fetched and asserted to name the person and the Alabama State Board of Education.',
  sources: verified,
}, null, 1));
console.log(`\nwrote ${DIR}/al-sboe-sources-2026-11-07.json`);
