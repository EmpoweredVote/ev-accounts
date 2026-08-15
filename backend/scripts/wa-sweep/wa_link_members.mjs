// Link the DB's 147 seated WA legislators to WA Legislature member IDs.
//
// Matching is on NAME ONLY, deliberately. Chamber cannot be part of the key: Emily Alvarado
// sponsored EHB 1217 as a House member in 2025 and sits in the State Senate today, so a
// name+chamber key silently drops her. Collisions are reported, never auto-resolved.
import { readFileSync, writeFileSync } from 'node:fs';
import pg from 'pg';

const ROSTER_XML = process.argv[2];
const OUT = process.argv[3];

const HOUSE = '2aace933-2073-4522-8a5b-210ed55aaaef';
const SENATE = '12baf2b5-e627-4e4c-ac21-34331c8b185d';

const norm = (s) =>
  s.normalize('NFD').replace(/[̀-ͯ]/g, '')   // strip accents (Saldaña)
   .toLowerCase().replace(/[.'`’-]/g, '').replace(/\s+/g, ' ').trim();

// --- roster from the web service ---
const xml = readFileSync(ROSTER_XML, 'utf8');
const members = [];
for (const block of xml.split('<Member>').slice(1)) {
  const pick = (t) => {
    const m = block.match(new RegExp(`<${t}>([\\s\\S]*?)</${t}>`));
    return m ? m[1].trim() : '';
  };
  const id = pick('Id');
  const name = pick('Name');
  if (id && name) {
    members.push({ id, name, agency: pick('Agency'), district: pick('District'), party: pick('Party') });
  }
}

// a member can appear once per chamber served; keep every (id,name) pair
const byNorm = new Map();
for (const m of members) {
  const k = norm(m.name);
  if (!byNorm.has(k)) byNorm.set(k, []);
  if (!byNorm.get(k).some((x) => x.id === m.id)) byNorm.get(k).push(m);
}

// --- the DB's seated 147 ---
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows } = await pool.query(`
  SELECT DISTINCT ON (p.id) p.id::text AS pid, p.full_name, c.name AS chamber
  FROM essentials.office_terms ot
  JOIN essentials.offices o  ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.politicians p ON p.id = ot.politician_id
  WHERE c.id IN ($1, $2)
    AND (ot.term_end IS NULL OR ot.term_end > CURRENT_DATE)
    AND p.is_incumbent
  ORDER BY p.id, ot.term_start DESC
`, [SENATE, HOUSE]);
await pool.end();

const link = {};
const unmatched = [];
const ambiguous = [];

for (const r of rows) {
  const cands = byNorm.get(norm(r.full_name)) || [];
  if (cands.length === 1) {
    link[r.pid] = { pid: r.pid, name: r.full_name, chamber: r.chamber, memberId: cands[0].id,
                    legName: cands[0].name, district: cands[0].district, party: cands[0].party };
  } else if (cands.length === 0) {
    unmatched.push({ pid: r.pid, name: r.full_name, chamber: r.chamber });
  } else {
    ambiguous.push({ pid: r.pid, name: r.full_name, chamber: r.chamber, candidates: cands });
  }
}

// reverse direction: roster members with no DB row (departed mid-biennium, or a seeding gap)
const linkedIds = new Set(Object.values(link).map((l) => l.memberId));
const rosterOnly = members.filter((m) => !linkedIds.has(m.id))
  .map((m) => ({ id: m.id, name: m.name, agency: m.agency, district: m.district, party: m.party }));

writeFileSync(OUT, JSON.stringify({ link, unmatched, ambiguous, rosterOnly }, null, 2), 'utf8');

console.log(`db legislators:      ${rows.length}`);
console.log(`roster members:      ${members.length}`);
console.log(`linked:              ${Object.keys(link).length}`);
console.log(`unmatched (db side): ${unmatched.length}`);
unmatched.forEach((u) => console.log(`   ! ${u.name} (${u.chamber})`));
console.log(`ambiguous:           ${ambiguous.length}`);
ambiguous.forEach((a) => console.log(`   ? ${a.name} -> ${a.candidates.map((c) => `${c.id}/${c.agency}`).join(', ')}`));
console.log(`roster-only:         ${rosterOnly.length}`);
rosterOnly.slice(0, 15).forEach((m) => console.log(`   - ${m.name} (${m.agency} ${m.district} ${m.party})`));
console.log(`wrote ${OUT}`);
