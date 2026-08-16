// Rank instruments by how many of the STILL-UNCOVERED SENATE REPUBLICANS they reach — the biggest
// remaining bucket. Prime-sponsor party is irrelevant: the cohort rule seats every sponsor alike.
import { readFileSync } from 'node:fs';
import pg from 'pg';

const CACHE = process.env.TEMP + '/ev-stance-cache/wa-leg';
const IDX = JSON.parse(readFileSync(CACHE + '/sponsorship-index-full.json', 'utf8'));
const LINK = JSON.parse(readFileSync(CACHE + '/member-link.json', 'utf8')).link;
const BY = Object.fromEntries(Object.values(LINK).map((v) => [v.memberId, v]));
const BYPID = Object.fromEntries(Object.values(LINK).map((v) => [v.pid, v]));

const HOUSE = '2aace933-2073-4522-8a5b-210ed55aaaef';
const SENATE = '12baf2b5-e627-4e4c-ac21-34331c8b185d';
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows: cov } = await pool.query(`
  WITH leg AS (
    SELECT DISTINCT ON (p.id) p.id::text AS pid, c.name AS chamber
    FROM essentials.office_terms ot
    JOIN essentials.offices o  ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.politicians p ON p.id = ot.politician_id
    WHERE c.id IN ($1,$2) AND (ot.term_end IS NULL OR ot.term_end > CURRENT_DATE) AND p.is_incumbent
    ORDER BY p.id, ot.term_start DESC)
  SELECT leg.pid, leg.chamber, (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = leg.pid::uuid) AS n
  FROM leg`, [SENATE, HOUSE]);
await pool.end();

const uncovered = cov.filter((r) => Number(r.n) === 0).map((r) => r.pid);
const target = new Set(uncovered.filter((p) => BYPID[p] && BYPID[p].party === (process.env.TP||'R') && new RegExp(process.env.TC||'Senate').test(cov.find((c) => c.pid === p).chamber)));
console.log('TARGET (uncovered target):', [...target].map((p) => BYPID[p].name).join(', '), `\n`);

const USED = /rent|tenant|landlord|climate|carbon|greenhouse|emission|interscholastic|transgender|hate crime|immigra|detainer|sanctuary|abortion|reproductive|millionaire|law enforcement hiring/i;
const PROC = /^(HCR|SCR|HR|SR|HJM|SJM)/;
const bills = new Map();
for (const [mid, v] of Object.entries(IDX.members)) {
  if (!BY[mid]) continue;
  for (const role of ['primary', 'secondary']) {
    for (const b of v[role]) {
      if (PROC.test(b.billId)) continue;
      if (!bills.has(b.billId)) bills.set(b.billId, { long: b.long, enacted: b.enacted, m: new Set(), prime: null });
      const e = bills.get(b.billId);
      e.m.add(mid);
      if (role === 'primary') e.prime = mid;
    }
  }
}

const ranked = [];
for (const [billId, e] of bills) {
  if (USED.test(e.long)) continue;
  const pids = [...e.m].map((m) => BY[m].pid);
  const hitT = pids.filter((p) => target.has(p)).length;
  const hitAll = pids.filter((p) => uncovered.includes(p)).length;
  if (hitT >= 2) ranked.push({ billId, hitT, hitAll, tot: pids.length, ...e });
}
ranked.sort((a, b) => b.hitT - a.hitT || b.hitAll - a.hitAll);

console.log('senateR / allUncovered / total');
for (const r of ranked.slice(0, 25)) {
  const prime = r.prime && BY[r.prime] ? `${BY[r.prime].name} (${BY[r.prime].party})` : '?';
  console.log(`  ${String(r.hitT).padStart(2)}/${String(r.hitAll).padStart(2)}/${String(r.tot).padStart(3)} ${r.billId.padEnd(9)} ${r.enacted ? 'ENACT' : 'died '} ${prime.padEnd(22)} ${r.long.slice(0, 72)}`);
}
