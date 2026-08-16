// List the still-uncovered seated WA legislators with chamber + party, and their sponsorship volume.
import { readFileSync } from 'node:fs';
import pg from 'pg';

const CACHE = process.env.TEMP + '/ev-stance-cache/wa-leg';
const IDX = JSON.parse(readFileSync(CACHE + '/sponsorship-index-full.json', 'utf8'));
const LINK = JSON.parse(readFileSync(CACHE + '/member-link.json', 'utf8')).link;
const BYPID = Object.fromEntries(Object.values(LINK).map((v) => [v.pid, v]));

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
await pool.end();

const unc = cov.filter((r) => Number(r.n) === 0);
const tally = {};
for (const r of unc) {
  const v = BYPID[r.pid];
  const party = v ? v.party : '?';
  const key = `${r.chamber} ${party}`;
  tally[key] = (tally[key] || 0) + 1;
}
console.log(`UNCOVERED: ${unc.length}`);
console.log(tally);
console.log('');
for (const r of unc.sort((a, b) => a.chamber.localeCompare(b.chamber) || a.full_name.localeCompare(b.full_name))) {
  const v = BYPID[r.pid];
  const mid = v ? v.memberId : null;
  const m = mid && IDX.members[mid] ? IDX.members[mid] : { primary: [], secondary: [] };
  console.log(`${r.chamber.padEnd(7)} ${(v ? v.party : '?').padEnd(2)} ${r.full_name.padEnd(24)} prime=${String(m.primary.length).padStart(3)} co=${String(m.secondary.length).padStart(4)}`);
}
