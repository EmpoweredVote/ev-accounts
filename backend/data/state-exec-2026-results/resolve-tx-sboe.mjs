// Resolve every Texas SBOE holder and candidate against production: full name, and surname +
// first initial. Each hit is printed with what that row already holds.
import fs from 'node:fs';
import { createRequire } from 'node:module';
const req = createRequire('C:/EV-Accounts/backend/package.json');
const pg = req('pg');
const dotenv = req('dotenv');
dotenv.config({ path: 'C:/EV-Accounts/backend/.env' });

const WT = 'C:/ev-accounts-stateexec/backend/data/state-exec-2026-results';
const DATA = JSON.parse(fs.readFileSync(`${WT}/tx-sboe-2026-11-07.json`, 'utf8'));
const BP = JSON.parse(fs.readFileSync(`${WT}/ballotpedia-all-states-2026-11-06.json`, 'utf8'));

const roles = new Map();
const note = (n, r) => { if (!roles.has(n)) roles.set(n, new Set()); roles.get(n).add(r); };
for (const s of DATA.seats) {
  note(s.holder, `holder:D${s.district}`);
  if (!s.raceRecorded) continue;
  const vb = BP.find(x => x.st === 'TX' && x.office === `State Board of Education District ${s.district}`);
  if (!vb) throw new Error(`no votebox for District ${s.district}`);
  if (!vb.candidates.length) throw new Error(`zero candidates for District ${s.district}`);
  for (const c of vb.candidates) note(c.name, `candidate:D${s.district}:${c.party}:${c.won ? 'WON' : 'lost'}`);
}
const names = [...roles.keys()];
console.log(`# ${names.length} distinct people\n`);

const normFull = s => (s || '').toLowerCase().replace(/[\u02BB\u2018\u2019']/g, "'")
  .normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z' ]/g, ' ').replace(/\s+/g, ' ').trim();
const SUFFIX = new Set(['jr', 'sr', 'ii', 'iii', 'iv', 'v']);
const parts = n => {
  const w = normFull(n).replace(/'/g, '').split(' ').filter(x => x && !SUFFIX.has(x));
  return { first: w[0] || '', last: w[w.length - 1] || '' };
};

const c = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await c.connect();
const ctl = await c.query(`SELECT count(*)::int n FROM essentials.politicians WHERE full_name = 'Jon Rosenthal'`);
if (ctl.rows[0].n < 1) throw new Error('CONTROL FAILED: a politician known to exist was not found');
const tx = await c.query(`SELECT count(DISTINCT och.politician_id)::int n
  FROM essentials.office_current_holder och JOIN essentials.offices o ON o.id=och.office_id
  JOIN essentials.districts d ON d.id=o.district_id
 WHERE upper(d.state)='TX' AND d.district_type IN ('STATE_UPPER','STATE_LOWER')`);
console.log(`# control: production holds ${tx.rows[0].n} sitting Texas state legislators, so the sweep can see Texas\n`);

const r = await c.query(`
WITH k AS (SELECT unnest($1::text[]) raw, unnest($2::text[]) kfull, unnest($3::text[]) klast, unnest($4::text[]) kinit),
pn AS (SELECT p.id, p.full_name, p.is_active, p.source,
         regexp_replace(lower(translate(p.full_name,'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇç','AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc')),'[^a-z'' ]',' ','g') kf,
         regexp_replace(lower(translate(p.last_name,'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇç','AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc')),'[^a-z]','','g') kl,
         lower(left(p.first_name,1)) ki
    FROM essentials.politicians p WHERE p.full_name !~ '[A-Z]{4}')
SELECT k.raw, (regexp_replace(pn.kf,'\\s+',' ','g') = k.kfull) exact, pn.id, pn.full_name, pn.is_active, pn.source,
       (SELECT string_agg(DISTINCT o.title || ' @' || coalesce(upper(d.state),'?'), ' // ')
          FROM essentials.office_current_holder och JOIN essentials.offices o ON o.id=och.office_id
          LEFT JOIN essentials.districts d ON d.id=o.district_id WHERE och.politician_id=pn.id) holds,
       (SELECT string_agg(DISTINCT r2.position_name || ' @' || coalesce(upper(d2.state),'?') || ' ' || to_char(e.election_date,'YYYY'), ' // ')
          FROM essentials.race_candidates rc JOIN essentials.races r2 ON r2.id=rc.race_id
          JOIN essentials.elections e ON e.id=r2.election_id
          LEFT JOIN essentials.offices o2 ON o2.id=r2.office_id
          LEFT JOIN essentials.districts d2 ON d2.id=o2.district_id WHERE rc.politician_id=pn.id) ran_for
  FROM k JOIN pn ON regexp_replace(pn.kf,'\\s+',' ','g') = k.kfull OR (pn.kl = k.klast AND pn.ki = k.kinit)
 ORDER BY k.raw, exact DESC, pn.full_name`,
  [names, names.map(normFull), names.map(n => parts(n).last), names.map(n => parts(n).first.slice(0, 1))]);
await c.end();

const by = new Map();
for (const row of r.rows) { if (!by.has(row.raw)) by.set(row.raw, []); by.get(row.raw).push(row); }
let ex = 0, near = 0, none = 0;
for (const n of names) {
  const hits = by.get(n) || [];
  const e = hits.filter(h => h.exact);
  if (e.length) ex++; else if (hits.length) near++; else none++;
  console.log(`${e.length ? `EXACT(${e.length})` : hits.length ? `near(${hits.length})` : 'NEW  '} ${n}  <<${[...roles.get(n)].join(' + ')}>>`);
  for (const h of hits) {
    console.log(`        ${h.exact ? '== ' : '~~ '}${h.id} "${h.full_name}" active=${h.is_active} src=${(h.source || '').slice(0, 45)}`);
    console.log(`            holds:   ${h.holds || '(none)'}`);
    console.log(`            ran for: ${(h.ran_for || '(none)').slice(0, 200)}`);
  }
}
console.log(`\n# ${ex} exact, ${near} near-miss only, ${none} new`);
