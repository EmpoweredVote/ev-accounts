// Ladder-first search: for each ladder the sweep has not used, find SENATE bills with a REPUBLICAN
// prime sponsor, ranked by how many still-uncovered legislators they reach. The generic picker ranks
// by reach and keeps surfacing procedural bills that reach no chair; this starts from the ladder.
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
    SELECT DISTINCT ON (p.id) p.id::text AS pid
    FROM essentials.office_terms ot
    JOIN essentials.offices o  ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.politicians p ON p.id = ot.politician_id
    WHERE c.id IN ($1,$2) AND (ot.term_end IS NULL OR ot.term_end > CURRENT_DATE) AND p.is_incumbent
    ORDER BY p.id, ot.term_start DESC)
  SELECT leg.pid, (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = leg.pid::uuid) AS n
  FROM leg`, [SENATE, HOUSE]);
await pool.end();
const uncovered = new Set(cov.filter((r) => Number(r.n) === 0).map((r) => r.pid));

// anchored, because every first cut over-fires
const LADDERS = {
  'school-vouchers': /\bvoucher|school choice|charter school|education savings account|open enrollment|homeschool/i,
  childcare: /child care|childcare|early learning|\bpreschool|day care/i,
  healthcare: /health care|healthcare|health insurance|\bmedicaid\b|apple health|health plan|prescription drug/i,
  homelessness: /\bhomeless|encampment|\bcamping\b|shelter capacity|right to sleep/i,
  'jail-capacity': /\bjail\b|\bjails\b|incarcerat|correctional facilit|\bdetention\b|pretrial|\bdiversion\b/i,
  'voting-rights': /\bvoter\b|\bvoters\b|voter registration|\bballot\b|election security|election integrity|citizenship/i,
  'growth-and-development': /growth management|comprehensive plan|urban growth area|\bpermitting\b|impact fee/i,
  'ai-regulation': /artificial intelligence|automated decision/i,
  'data-centers': /data center/i,
  'campaign-finance': /campaign finance|political contribution|public financing of campaigns/i,
  redistricting: /redistrict/i,
  'religious-freedom': /religious freedom|religious exercise|clergy/i,
  'economic-development': /economic development|business retention|job creation/i,
  'local-environment': /water quality|\bpollution\b|\bsalmon\b|\bwildfire\b|state park/i,
};

const PROC = /^(HCR|SCR|HR|SR|HJM|SJM)/;
const bills = new Map();
for (const [mid, v] of Object.entries(IDX.members)) {
  if (!BY[mid]) continue;
  for (const role of ['primary', 'secondary']) {
    for (const b of v[role]) {
      if (PROC.test(b.billId) || !/^(SB|ESB|SSB|ESSB|SJR)/.test(b.billId)) continue;
      if (!bills.has(b.billId)) bills.set(b.billId, { long: b.long, enacted: b.enacted, m: new Set(), prime: null });
      const e = bills.get(b.billId);
      e.m.add(mid);
      if (role === 'primary') e.prime = mid;
    }
  }
}

for (const [ladder, pat] of Object.entries(LADDERS)) {
  const hits = [];
  for (const [billId, e] of bills) {
    if (!pat.test(e.long)) continue;
    if (!e.prime || !BY[e.prime] || BY[e.prime].party !== 'R') continue;
    const unc = [...e.m].map((m) => BY[m].pid).filter((p) => uncovered.has(p)).length;
    if (unc >= 3) hits.push({ billId, unc, tot: e.m.size, ...e });
  }
  if (!hits.length) continue;
  hits.sort((a, b) => b.unc - a.unc || b.tot - a.tot);
  console.log(`\n### ${ladder}`);
  for (const h of hits.slice(0, 5)) {
    console.log(`  +${String(h.unc).padEnd(2)}/${String(h.tot).padStart(3)} ${h.billId.padEnd(9)} ${h.enacted ? 'ENACT' : 'died '} ${BY[h.prime].name.padEnd(20)} ${h.long.slice(0, 74)}`);
  }
}
