// Resolve every holder and candidate in CC_0366's four bodies against production, twice:
// once on the whole name and once on surname + first initial, because full-name equality cannot
// see a middle initial or a suffix. A NAME MATCH IS A HYPOTHESIS — each hit is printed with what
// that row already holds so it can be judged on evidence.
import fs from 'node:fs';
import { createRequire } from 'node:module';
const req = createRequire('C:/EV-Accounts/backend/package.json');
const pg = req('pg');
const dotenv = req('dotenv');
dotenv.config({ path: 'C:/EV-Accounts/backend/.env' });

const WT = 'C:/ev-accounts-stateexec/backend/data/state-exec-2026-results';
const DATA = JSON.parse(fs.readFileSync(`${WT}/board-bodies-no-new-polygon-2026-11-07.json`, 'utf8'));
const BP = JSON.parse(fs.readFileSync(`${WT}/ballotpedia-all-states-2026-11-06.json`, 'utf8'));

const roles = new Map();
const note = (name, r) => { if (!roles.has(name)) roles.set(name, new Set()); roles.get(name).add(r); };
for (const b of DATA.bodies) {
  for (const s of b.seats) {
    note(s.holder, `holder:${b.key}:${s.title}`);
    if (!s.raceRecorded) continue;
    const vb = BP.find(x => x.st === b.st && x.office === s.ballotpediaOffice);
    if (!vb) throw new Error(`no Ballotpedia votebox for ${b.key} / ${s.ballotpediaOffice}`);
    if (!vb.candidates.length) throw new Error(`${b.key} ${s.ballotpediaOffice}: zero candidates`);
    for (const c of vb.candidates) note(c.name, `candidate:${b.key}:${s.title}:${c.party}:${c.won ? 'WON' : 'lost'}`);
  }
}
const names = [...roles.keys()];
console.log(`# ${names.length} distinct people across the four bodies\n`);

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
if (ctl.rows[0].n < 1) throw new Error('CONTROL FAILED: a politician known to exist was not found — the sweep is blind');
console.log(`# control: Jon Rosenthal found ${ctl.rows[0].n} time(s)\n`);

const SQL = `
WITH k AS (SELECT unnest($1::text[]) AS raw, unnest($2::text[]) AS kfull, unnest($3::text[]) AS klast, unnest($4::text[]) AS kinit),
pn AS (
  SELECT p.id, p.full_name, p.is_active, p.source,
         regexp_replace(lower(translate(p.full_name,
           'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇçʻ‘’',
           'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc''''''')), '[^a-z'' ]', ' ', 'g') AS kf,
         regexp_replace(lower(translate(p.last_name,
           'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇçʻ‘’',
           'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc   ')), '[^a-z]', '', 'g') AS kl,
         lower(left(p.first_name, 1)) AS ki
    FROM essentials.politicians p WHERE p.full_name !~ '[A-Z]{4}')
SELECT k.raw,
       (regexp_replace(pn.kf, '\\s+', ' ', 'g') = k.kfull) AS exact,
       pn.id, pn.full_name, pn.is_active, pn.source,
       (SELECT string_agg(DISTINCT o.title || ' @' || coalesce(upper(d.state),'?'), ' // ')
          FROM essentials.office_current_holder och JOIN essentials.offices o ON o.id = och.office_id
          LEFT JOIN essentials.districts d ON d.id = o.district_id WHERE och.politician_id = pn.id) AS holds,
       (SELECT string_agg(DISTINCT r.position_name || ' @' || coalesce(upper(d2.state),'?') || ' ' || to_char(e.election_date,'YYYY'), ' // ')
          FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
          JOIN essentials.elections e ON e.id = r.election_id
          LEFT JOIN essentials.offices o2 ON o2.id = r.office_id
          LEFT JOIN essentials.districts d2 ON d2.id = o2.district_id
         WHERE rc.politician_id = pn.id) AS ran_for
  FROM k JOIN pn ON regexp_replace(pn.kf, '\\s+', ' ', 'g') = k.kfull
                 OR (pn.kl = k.klast AND pn.ki = k.kinit)
 ORDER BY k.raw, exact DESC, pn.full_name`;
const r = await c.query(SQL, [names, names.map(normFull), names.map(n => parts(n).last), names.map(n => parts(n).first.slice(0, 1))]);
await c.end();

const by = new Map();
for (const row of r.rows) { if (!by.has(row.raw)) by.set(row.raw, []); by.get(row.raw).push(row); }
let exact = 0, near = 0, none = 0;
for (const n of names) {
  const hits = by.get(n) || [];
  const ex = hits.filter(h => h.exact);
  const tag = ex.length ? `EXACT(${ex.length})` : hits.length ? `near(${hits.length})` : 'NEW  ';
  if (ex.length) exact++; else if (hits.length) near++; else none++;
  console.log(`${tag} ${n}  <<${[...roles.get(n)].join(' + ')}>>`);
  for (const h of hits) {
    console.log(`        ${h.exact ? '== ' : '~~ '}${h.id} "${h.full_name}" active=${h.is_active} src=${(h.source || '').slice(0, 50)}`);
    console.log(`            holds:   ${h.holds || '(none)'}`);
    console.log(`            ran for: ${(h.ran_for || '(none)').slice(0, 220)}`);
  }
}
console.log(`\n# ${exact} exact, ${near} near-miss only, ${none} new`);
