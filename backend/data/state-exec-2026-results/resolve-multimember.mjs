// Resolve every holder and candidate in the seven multi-member bodies against production.
// Prints each name with every politician row that matches it and what that row already holds or seeks,
// so a match can be judged on evidence instead of on the name. A NAME MATCH IS A HYPOTHESIS.
import fs from 'node:fs';
import { createRequire } from 'node:module';
const req = createRequire('C:/EV-Accounts/backend/package.json');
const pg = req('pg');
const dotenv = req('dotenv');
dotenv.config({ path: 'C:/EV-Accounts/backend/.env' });

const SP = 'C:/Users/Chris/AppData/Local/Temp/claude/eef8bd18862e071c/72fa756c-fa21-4c9f-b307-b54d41a5fa4e/scratchpad';
const WT = 'C:/ev-accounts-stateexec/backend/data/state-exec-2026-results';
const bodies = JSON.parse(fs.readFileSync(`${SP}/bodies.json`, 'utf8')).bodies;
const bp = JSON.parse(fs.readFileSync(`${WT}/ballotpedia-all-states-2026-11-06.json`, 'utf8'));

const want = new Map(); // name -> {roles:Set, st}
const add = (st, name, role) => {
  const k = `${st}|${name}`;
  if (!want.has(k)) want.set(k, { st, name, roles: new Set() });
  want.get(k).roles.add(role);
};
for (const b of bodies) {
  for (const s of b.seats) add(b.st, s.holder, `holder:${b.key}:${s.title}${s.upIn2026 ? ' [UP 2026]' : ''}`);
  const vb = bp.find(x => x.st === b.st && x.office === b.ballotpediaOffice);
  if (!vb) throw new Error(`no Ballotpedia votebox for ${b.key} / ${b.ballotpediaOffice}`);
  if (vb.candidates.length === 0) throw new Error(`${b.key}: zero candidates`);
  for (const c of vb.candidates) add(b.st, c.name, `candidate:${b.key}:${c.party}:${c.won ? 'WON' : 'lost'}`);
}
console.log(`# ${want.size} distinct (state, name) pairs across the seven bodies\n`);

const norm = s => (s || '').toLowerCase()
  .replace(/[\u02BB\u2018\u2019']/g, "'")
  .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
  .replace(/[^a-z' ]/g, ' ').replace(/\s+/g, ' ').trim();

const names = [...new Set([...want.values()].map(v => v.name))];
const keys = names.map(norm);

const c = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await c.connect();

// positive control: a name we know exists must come back, or this whole sweep is blind
const ctl = await c.query(
  `SELECT count(*)::int n FROM essentials.politicians WHERE full_name = 'Carmen Hulu Lindsey'`);
if (ctl.rows[0].n < 1) throw new Error('CONTROL FAILED: a politician known to exist was not found — the sweep is blind');
console.log(`# control: Carmen Hulu Lindsey found ${ctl.rows[0].n} time(s)\n`);

const sql = `
WITH k AS (SELECT unnest($1::text[]) AS raw, unnest($2::text[]) AS key),
pn AS (
  SELECT p.id, p.full_name, p.first_name, p.last_name, p.is_active, p.is_incumbent, p.source,
         regexp_replace(lower(translate(p.full_name,
           'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇçʻ‘’',
           'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc''''''')), '[^a-z'' ]', ' ', 'g') AS k
    FROM essentials.politicians p)
SELECT k.raw, pn.id, pn.full_name, pn.is_active, pn.is_incumbent, pn.source,
       (SELECT string_agg(DISTINCT o.title || ' @' || coalesce(upper(d.state),'?') || ' ' || coalesce(d.district_type,'?'), ' // ')
          FROM essentials.office_current_holder och
          JOIN essentials.offices o ON o.id = och.office_id
          LEFT JOIN essentials.districts d ON d.id = o.district_id
         WHERE och.politician_id = pn.id) AS holds,
       (SELECT string_agg(DISTINCT r.position_name || ' @' || coalesce(upper(d2.state),'?') || ' ' || to_char(e.election_date,'YYYY'), ' // ')
          FROM essentials.race_candidates rc
          JOIN essentials.races r ON r.id = rc.race_id
          JOIN essentials.elections e ON e.id = r.election_id
          LEFT JOIN essentials.offices o2 ON o2.id = r.office_id
          LEFT JOIN essentials.districts d2 ON d2.id = o2.district_id
         WHERE rc.politician_id = pn.id) AS ran_for
  FROM k JOIN pn ON regexp_replace(pn.k, '\\s+', ' ', 'g') = k.key
 ORDER BY k.raw, pn.full_name`;
const r = await c.query(sql, [names, keys]);
await c.end();

const byName = new Map();
for (const row of r.rows) {
  if (!byName.has(row.raw)) byName.set(row.raw, []);
  byName.get(row.raw).push(row);
}
let nNew = 0, nMatch = 0;
for (const v of want.values()) {
  const hits = byName.get(v.name) || [];
  const tag = hits.length === 0 ? 'NEW ' : `MATCH(${hits.length})`;
  if (hits.length === 0) nNew++; else nMatch++;
  console.log(`${tag} ${v.st} ${v.name}  <<${[...v.roles].join(' + ')}>>`);
  for (const h of hits) {
    console.log(`        ${h.id} "${h.full_name}" active=${h.is_active} inc=${h.is_incumbent} src=${(h.source || '').slice(0, 60)}`);
    console.log(`          holds:   ${h.holds || '(none)'}`);
    console.log(`          ran for: ${(h.ran_for || '(none)').slice(0, 300)}`);
  }
}
console.log(`\n# ${nMatch} name(s) matched an existing row, ${nNew} are new`);
