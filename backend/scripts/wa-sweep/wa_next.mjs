// Rank WA instruments by how many STILL-UNCOVERED seated legislators they would unlock.
// Queries coverage live so it never goes stale, and reports per-topic coverage alongside.
import { readFileSync } from 'node:fs';
import pg from 'pg';

const CACHE = process.env.TEMP + '/ev-stance-cache/wa-leg';
const IDX = JSON.parse(readFileSync(CACHE + '/sponsorship-index-full.json', 'utf8'));
const LINK = JSON.parse(readFileSync(CACHE + '/member-link.json', 'utf8')).link;
const BY = Object.fromEntries(Object.values(LINK).map((v) => [v.memberId, v]));

const HOUSE = '2aace933-2073-4522-8a5b-210ed55aaaef';
const SENATE = '12baf2b5-e627-4e4c-ac21-34331c8b185d';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const { rows: cov } = await pool.query(`
  WITH leg AS (
    SELECT DISTINCT ON (p.id) p.id::text AS pid, p.full_name, c.name AS chamber
    FROM essentials.office_terms ot
    JOIN essentials.offices o  ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.politicians p ON p.id = ot.politician_id
    WHERE c.id IN ($1,$2) AND (ot.term_end IS NULL OR ot.term_end > CURRENT_DATE) AND p.is_incumbent
    ORDER BY p.id, ot.term_start DESC
  )
  SELECT leg.pid, leg.full_name, leg.chamber,
         (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = leg.pid::uuid) AS n
  FROM leg`, [SENATE, HOUSE]);

const { rows: topics } = await pool.query(`
  SELECT t.topic_key, count(*) AS n
  FROM inform.politician_answers a
  JOIN inform.compass_topics t ON t.id = a.topic_id
  WHERE a.politician_id IN (
    SELECT DISTINCT ot.politician_id FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    WHERE o.chamber_id IN ($1,$2) AND (ot.term_end IS NULL OR ot.term_end > CURRENT_DATE))
  GROUP BY t.topic_key ORDER BY n DESC`, [SENATE, HOUSE]);
await pool.end();

const uncovered = new Set(cov.filter((r) => Number(r.n) === 0).map((r) => r.pid));
console.log(`seated legislators: ${cov.length}   covered: ${cov.length - uncovered.size}   UNCOVERED: ${uncovered.size}`);
console.log('topics already used: ' + topics.map((t) => `${t.topic_key}(${t.n})`).join(', ') + '\n');

// keywords for topics already worked, so the ranking surfaces NEW ground
const USED = /rent|tenant|landlord|climate|carbon|greenhouse|emission|interscholastic|transgender|hate crime|immigra|detainer|sanctuary|abortion|reproductive/i;
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
  const unc = pids.filter((p) => uncovered.has(p)).length;
  if (unc >= 8) ranked.push({ billId, unc, tot: pids.length, ...e });
}
ranked.sort((a, b) => b.unc - a.unc || b.tot - a.tot);

console.log('instruments ranked by UNCOVERED legislators unlocked (new topic ground only):');
for (const r of ranked.slice(0, 18)) {
  const prime = r.prime && BY[r.prime] ? `${BY[r.prime].name} (${BY[r.prime].party})` : '?';
  console.log(`  +${String(r.unc).padEnd(3)}/${String(r.tot).padStart(3)}  ${r.billId.padEnd(9)} ${r.enacted ? 'ENACT' : 'died '} ${prime.padEnd(26)} ${r.long.slice(0, 66)}`);
}
