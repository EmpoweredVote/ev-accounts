// Second sweep, WIDER than resolve-mm.mjs: match on SURNAME + FIRST INITIAL, not on the whole
// string. The first sweep compares full names, so "Tiffany D. Tilley" cannot see "Tiffany Tilley"
// and "Marshall Bullock II" cannot see "Marshall Bullock" — the same blindness CLAUDE.md records
// for the duplicate-name guard. Anything this finds that the first sweep did not is a near miss
// that has to be judged by hand.
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

const names = new Set();
for (const b of bodies) {
  for (const s of b.seats) names.add(s.holder);
  const vb = bp.find(x => x.st === b.st && x.office === b.ballotpediaOffice);
  for (const c of vb.candidates) names.add(c.name);
}
const norm = s => (s || '').toLowerCase().replace(/[\u02BB\u2018\u2019']/g, '')
  .normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z ]/g, ' ').replace(/\s+/g, ' ').trim();
const SUFFIX = new Set(['jr', 'sr', 'ii', 'iii', 'iv', 'v']);
const parts = n => {
  const w = norm(n).split(' ').filter(x => x && !SUFFIX.has(x));
  return { first: w[0] || '', last: w[w.length - 1] || '' };
};
const list = [...names];
const lasts = list.map(n => parts(n).last);
const inits = list.map(n => parts(n).first.slice(0, 1));

const c = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await c.connect();
const ctl = await c.query(`SELECT count(*)::int n FROM essentials.politicians WHERE lower(last_name) = 'lindsey'`);
if (ctl.rows[0].n < 1) throw new Error('CONTROL FAILED: no politician has last_name Lindsey — the surname sweep is blind');
console.log(`# control: ${ctl.rows[0].n} politician(s) have last_name Lindsey\n`);

const r = await c.query(`
WITH k AS (SELECT unnest($1::text[]) AS raw, unnest($2::text[]) AS last, unnest($3::text[]) AS init)
SELECT k.raw, p.id, p.full_name, p.is_active, p.source,
       (SELECT string_agg(DISTINCT o.title || ' @' || coalesce(upper(d.state),'?'), ' // ')
          FROM essentials.office_current_holder och JOIN essentials.offices o ON o.id = och.office_id
          LEFT JOIN essentials.districts d ON d.id = o.district_id WHERE och.politician_id = p.id) AS holds
  FROM k JOIN essentials.politicians p
    ON regexp_replace(lower(translate(p.last_name, 'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇçʻ‘’',
                                                  'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc   ')), '[^a-z]', '', 'g') = k.last
   AND lower(left(p.first_name, 1)) = k.init
 WHERE p.full_name !~ '[A-Z]{4}'
 ORDER BY k.raw, p.full_name`, [list, lasts, inits]);
await c.end();

const seen = new Map();
for (const row of r.rows) {
  if (!seen.has(row.raw)) seen.set(row.raw, []);
  seen.get(row.raw).push(row);
}
for (const n of list) {
  const hits = seen.get(n) || [];
  if (!hits.length) continue;
  console.log(`${n}`);
  for (const h of hits) console.log(`    ${h.id} "${h.full_name}" active=${h.is_active} holds=${h.holds || '(none)'} src=${(h.source || '').slice(0, 55)}`);
}
console.log(`\n# ${seen.size} of ${list.length} names have a surname+initial neighbour`);
