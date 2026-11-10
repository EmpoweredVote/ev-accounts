// resolve-la-psc.mjs — settle, against the pages themselves, the ten people CC_0371 seeds.
// Same two jobs as resolve-al-sboe.mjs, and the same reasons:
//   1. SOURCE. 🔴 A departed official's URL can serve their successor with no redirect and no
//      error, and a DISAMBIGUATION page returns HTTP 200 and contains the person's name —
//      /Allen_Long did exactly that in CC_0370. So each page must name the person, mention the
//      Louisiana Public Service Commission, and not be a disambiguation page.
//   2. COLLISION. "John Atkins", "James Green", "Chris Justin" and "Connie Norris" are the kind
//      of name production already holds, so the sweep runs on full name AND on (first, last).
//
// Usage (from backend/):  node data/state-exec-2026-results/resolve-la-psc.mjs
import fs from 'node:fs';
import { createRequire } from 'node:module';
const req = createRequire('C:/EV-Accounts/backend/package.json');
const pg = req('pg');
const dotenv = req('dotenv');
dotenv.config({ path: 'C:/EV-Accounts/backend/.env' });

const DIR = 'C:/ev-accounts-stateexec/backend/data/state-exec-2026-results';
const BP = JSON.parse(fs.readFileSync(`${DIR}/ballotpedia-all-states-2026-11-06.json`, 'utf8'));

// The sitting commissioners, from lpsc.louisiana.gov/District1..5 (read 2026-11-07), which gives
// each one's district and term end. Ballotpedia's infobox for the commission independently lists
// the same five names. Where the two differ it is only in form — the commission prints middle
// initials ("Jean-Paul P. Coussan", "Foster L. Campbell") — so Ballotpedia's plain form is used,
// because the Ballotpedia page is the source each politician row cites.
const HOLDERS = [
  [1, 'Eric Skrmetta', 'Eric_Skrmetta'],
  [2, 'Jean-Paul Coussan', 'Jean-Paul_Coussan'],
  [3, 'Davante Lewis', 'Davante_Lewis'],
  // 🔴 /Mike_Francis is a DISAMBIGUATION page listing an Arizona and a Louisiana Mike Francis.
  [4, 'Mike Francis', 'Mike_Francis_(Louisiana)'],
  [5, 'Foster Campbell', 'Foster_Campbell'],
];

const races = BP.filter(r => r.st === 'LA' && /^Public Service Commission District \d$/.test(r.office));
if (races.length !== 2) throw new Error(`expected 2 Louisiana PSC races in the capture, found ${races.length}`);

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
  const t = text(await r.text());
  const namesThem = t.includes(name);
  const board = /Louisiana Public Service Commission/i.test(t);
  const disambig = /\bmay refer to\b/i.test(t) || /All disambiguation pages/i.test(t);
  const redirected = r.url !== url;
  verified.push({ name, url, http: r.status, namesThem, board, disambig, finalUrl: r.url });
  console.log(`${r.status} ${namesThem ? 'NAMES' : '🔴 does NOT name'} ${board ? 'PSC' : '🔴 no PSC mention'}` +
    `${disambig ? ' 🔴 DISAMBIGUATION PAGE' : ''}${redirected ? ' ↪ ' + r.url : ''}  ${name.padEnd(20)} ${url}`);
}
const badSrc = verified.filter(v => v.http !== 200 || !v.namesThem || !v.board || v.disambig);
console.log(badSrc.length ? `🔴 ${badSrc.length} source(s) did not verify` : `🟢 all ${verified.length} sources name the person and the commission`);

console.log('\n── COLLISIONS ──');
const split = n => { const i = n.lastIndexOf(' '); return [n.slice(0, i), n.slice(i + 1)]; };
const people = [...urls.keys()].map(n => { const [f, l] = split(n); return { full: n, first: f, last: l }; });
for (const p of people) if (p.full !== `${p.first} ${p.last}`) throw new Error(`${p.full} does not match its own split`);

const c = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await c.connect();
const ctl = await c.query(`SELECT count(*)::int n FROM essentials.politicians WHERE full_name = 'Jeff Landry'`);
if (ctl.rows[0].n < 1) throw new Error('the politicians table cannot see a name known to exist — the sweep would be blind');
const total = await c.query(`SELECT count(*)::int n FROM essentials.politicians`);
console.log(`(sweeping ${total.rows[0].n} politicians; positive control found Jeff Landry)`);

for (const p of people) {
  const r = await c.query(
    `SELECT id, full_name, first_name, last_name, is_active, is_incumbent, source
       FROM essentials.politicians
      WHERE lower(full_name) = lower($1)
         OR (lower(first_name) = lower($2) AND lower(last_name) = lower($3))
      ORDER BY is_active DESC, full_name`, [p.full, p.first, p.last]);
  if (!r.rowCount) { console.log(`   ${p.full.padEnd(20)} — clear`); continue; }
  console.log(`🔴 ${p.full.padEnd(20)} — ${r.rowCount} existing row(s):`);
  for (const x of r.rows) {
    console.log(`      ${x.id}  ${x.full_name} (${x.first_name}|${x.last_name}) active=${x.is_active} incumbent=${x.is_incumbent}`);
    console.log(`         source: ${(x.source ?? '—').slice(0, 150)}`);
  }
}
await c.end();

fs.writeFileSync(`${DIR}/la-psc-sources-2026-11-07.json`, JSON.stringify({
  measured: '2026-11-07',
  note: 'Ballotpedia page per person, each fetched and asserted to name the person and the Louisiana Public Service Commission, and not to be a disambiguation page.',
  sources: verified,
}, null, 1));
console.log(`\nwrote ${DIR}/la-psc-sources-2026-11-07.json`);
