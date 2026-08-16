import { readFileSync } from 'node:fs';
import pg from 'pg';
const C = process.env.TEMP + '/ev-stance-cache/wa-leg';
const IDX = JSON.parse(readFileSync(C + '/sponsorship-index-full.json', 'utf8'));
const LINK = JSON.parse(readFileSync(C + '/member-link.json', 'utf8')).link;
const BY = Object.fromEntries(Object.values(LINK).map((v) => [v.memberId, v]));
const HOUSE='2aace933-2073-4522-8a5b-210ed55aaaef', SENATE='12baf2b5-e627-4e4c-ac21-34331c8b185d';
const pool = new pg.Pool({connectionString: process.env.DATABASE_URL, ssl:{rejectUnauthorized:false}});
const {rows} = await pool.query(`WITH leg AS (SELECT DISTINCT ON (p.id) p.id::text AS pid, c.name AS ch FROM essentials.office_terms ot JOIN essentials.offices o ON o.id=ot.office_id JOIN essentials.chambers c ON c.id=o.chamber_id JOIN essentials.politicians p ON p.id=ot.politician_id WHERE c.id IN ($1,$2) AND (ot.term_end IS NULL OR ot.term_end > CURRENT_DATE) AND p.is_incumbent ORDER BY p.id, ot.term_start DESC) SELECT pid, ch, (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id=leg.pid::uuid) AS n FROM leg`, [SENATE,HOUSE]);
await pool.end();
const unc = new Set(rows.filter(r=>Number(r.n)===0).map(r=>r.pid));
const senate = new Set(rows.filter(r=>/Senate/.test(r.ch)).map(r=>r.pid));
const bills = new Map();
for (const [mid,v] of Object.entries(IDX.members)) { if(!BY[mid]) continue;
  for (const role of ['primary','secondary']) for (const b of v[role]) {
    if(!bills.has(b.billId)) bills.set(b.billId,{long:b.long,enacted:b.enacted,m:new Set()});
    bills.get(b.billId).m.add(mid); } }
for (const id of process.argv.slice(2)) {
  const e = bills.get(id);
  if(!e){ console.log(`${id}  NOT IN INDEX`); continue; }
  const pids=[...e.m].map(m=>BY[m].pid);
  const u=pids.filter(p=>unc.has(p));
  const usr=u.filter(p=>senate.has(p) && Object.values(LINK).find(v=>v.pid===p).party==='R');
  console.log(`${id.padEnd(9)} tot=${String(pids.length).padStart(3)} unc=${String(u.length).padStart(2)} uncSenR=${String(usr.length).padStart(2)}  ${e.enacted?'ENACT':'died '} ${e.long.slice(0,66)}`);
}
