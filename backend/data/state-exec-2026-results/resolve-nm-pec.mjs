// resolve-nm-pec.mjs — settle, against the pages themselves, the twelve people CC_0372 seeds.
// Same two jobs as resolve-al-sboe.mjs and resolve-la-psc.mjs:
//   1. SOURCE — each Ballotpedia page must name the person, mention the New Mexico Public
//      Education Commission, and NOT be a disambiguation page. Two of those have already been
//      caught in this series: /Allen_Long (CC_0370) and /Mike_Francis (CC_0371).
//   2. COLLISION — full name AND (first, last), against every politician production holds.
//
// Usage (from backend/):  node data/state-exec-2026-results/resolve-nm-pec.mjs
import fs from 'node:fs';
import { createRequire } from 'node:module';
const req = createRequire('C:/EV-Accounts/backend/package.json');
const pg = req('pg');
const dotenv = req('dotenv');
dotenv.config({ path: 'C:/EV-Accounts/backend/.env' });

const DIR = 'C:/ev-accounts-stateexec/backend/data/state-exec-2026-results';
const BP = JSON.parse(fs.readFileSync(`${DIR}/ballotpedia-all-states-2026-11-06.json`, 'utf8'));

// The sitting commissioners, from Ballotpedia's officeholder table for the commission, read
// 2026-11-07. The Legislative Council Service's 2025 handbook page agrees on nine of the ten and
// on every district's county list; it gives District 3 as Alan Lee Brauer Jr., who has since
// been replaced by Jacob Trujillo — Ballotpedia's 2026 District 3 votebox calls Trujillo the
// incumbent, so the handbook is simply older there. ⚠ A roster can be right about the body and
// out of date about one seat.
const HOLDERS = [
  [1, 'Sam S. Obenshain', 'Sam_Obenshain'],
  [2, 'Timothy Beck', 'Timothy_Beck'],
  [3, 'Jacob Trujillo', null],
  [4, 'Rebekka Burt', 'Rebekka_Burt'],
  [5, 'Sharon E. Clahchischilliage', null],
  [6, 'Stewart Ingham', null],
  [7, 'Patricia Gipson', 'Patricia_Gipson'],
  [8, 'Michael Taylor', 'Michael_Taylor_(New_Mexico)'],
  [9, 'K.T. Manis', 'K.T._Manis'],
  [10, 'Steven Carrillo', 'Steven_Carrillo'],
];
// Districts 2, 3, 5 and 6 are the four 2026 races Ballotpedia has called. District 7 was also on
// the ballot and has NO winner called, so it records no race and its candidates are not seeded.
const RECORDED = [2, 3, 5, 6];

const races = BP.filter(r => r.st === 'NM' && /^Public Education Commission District \d+$/.test(r.office));
if (races.length !== 5) throw new Error(`expected 5 New Mexico PEC races in the capture, found ${races.length}`);

const urls = new Map();
for (const r of races) {
  const d = Number(r.office.replace(/\D+/g, ''));
  if (!RECORDED.includes(d)) continue;
  for (const c of r.candidates) urls.set(c.name, c.url);
}
for (const [, name, slug] of HOLDERS) {
  if (urls.has(name)) continue;
  if (!slug) throw new Error(`${name} is not in a recorded race and has no proposed slug`);
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
  const t = text(await r.text());
  const namesThem = t.includes(name);
  const board = /New Mexico Public Education Commission/i.test(t);
  const disambig = /\bmay refer to\b/i.test(t) || /All disambiguation pages/i.test(t);
  const redirected = r.url !== url;
  verified.push({ name, url, http: r.status, namesThem, board, disambig, finalUrl: r.url });
  console.log(`${r.status} ${namesThem ? 'NAMES' : '🔴 does NOT name'} ${board ? 'PEC' : '🔴 no PEC mention'}` +
    `${disambig ? ' 🔴 DISAMBIGUATION PAGE' : ''}${redirected ? ' ↪ ' + r.url : ''}  ${name.padEnd(28)} ${url}`);
}
const badSrc = verified.filter(v => v.http !== 200 || !v.namesThem || !v.board || v.disambig);
console.log(badSrc.length ? `🔴 ${badSrc.length} source(s) did not verify` : `🟢 all ${verified.length} sources name the person and the commission`);

console.log('\n── COLLISIONS ──');
const split = n => { const i = n.lastIndexOf(' '); return [n.slice(0, i), n.slice(i + 1)]; };
const people = [...urls.keys()].map(n => { const [f, l] = split(n); return { full: n, first: f, last: l }; });
for (const p of people) if (p.full !== `${p.first} ${p.last}`) throw new Error(`${p.full} does not match its own split`);

const c = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await c.connect();
const ctl = await c.query(`SELECT count(*)::int n FROM essentials.politicians WHERE full_name = 'Michelle Lujan Grisham'`);
if (ctl.rows[0].n < 1) throw new Error('the politicians table cannot see a name known to exist — the sweep would be blind');
const total = await c.query(`SELECT count(*)::int n FROM essentials.politicians`);
console.log(`(sweeping ${total.rows[0].n} politicians; positive control found Michelle Lujan Grisham)`);

for (const p of people) {
  const r = await c.query(
    `SELECT id, full_name, first_name, last_name, is_active, is_incumbent, source
       FROM essentials.politicians
      WHERE lower(full_name) = lower($1)
         OR (lower(first_name) = lower($2) AND lower(last_name) = lower($3))
      ORDER BY is_active DESC, full_name`, [p.full, p.first, p.last]);
  if (!r.rowCount) { console.log(`   ${p.full.padEnd(28)} — clear`); continue; }
  console.log(`🔴 ${p.full.padEnd(28)} — ${r.rowCount} existing row(s):`);
  for (const x of r.rows) {
    console.log(`      ${x.id}  ${x.full_name} (${x.first_name}|${x.last_name}) active=${x.is_active} incumbent=${x.is_incumbent}`);
    console.log(`         source: ${(x.source ?? '—').slice(0, 150)}`);
  }
}
await c.end();

fs.writeFileSync(`${DIR}/nm-pec-sources-2026-11-07.json`, JSON.stringify({
  measured: '2026-11-07',
  note: 'Ballotpedia page per person, each fetched and asserted to name the person and the New Mexico Public Education Commission, and not to be a disambiguation page.',
  sources: verified,
}, null, 1));
console.log(`\nwrote ${DIR}/nm-pec-sources-2026-11-07.json`);
