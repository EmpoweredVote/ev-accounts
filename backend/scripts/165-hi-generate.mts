import { writeFileSync } from 'fs';

// ---- HI field (validated against staging/p165-HI.csv + LIVE prod checks 2026-07-07) ----
// Phase 165-06: HI vanilla create-election-first seed (162-mn pattern), LATE-PRIMARY -> PROVISIONAL.
//   1 election 'HI 2026 Statewide General' + 2 races on existing NATIONAL_LOWER offices (1501-1502).
//   HI 2026 primary: 2026-08-08 (verified elections.hawaii.gov 2026-07-07) -> cull >= 2026-08-08.
//   Authoritative field = olvr.hawaii.gov status='In Primary' (fully filed) ONLY.
//   EXCLUDED (status='Issued', papers never returned — NOT on ballot): Della Au Belatti, Zachary B.
//   Burd, Ku Lono "Bobby" Cuadra, Maxwell T. Frazier, Joshua Pule Kimo Gisa (HI-1); Cuadra, Ron
//   Curtis, George T.T.T. Lucas-Tadeo, Austin Martin (HI-2).
//   Incumbents renominated on-ballot (crowded same-party primaries): Case -15001, Tokuda -15002.
//   Band -150299..-150101 confirmed EMPTY live -> seq starts 1.
const ELECTION = 'HI 2026 Statewide General';
const FIPS = 15;
const RACE_DESC = 'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-08';
const SRC = 'HI Office of Elections candidate filing grid (olvr.hawaii.gov elid=94, status=In Primary; pre-primary qualified field, cull >= 2026-08-08)';

const INC_EXT: Record<number, number> = { 1: -15001, 2: -15002 };
const INC_NAME: Record<number, string> = { 1: 'Ed Case', 2: 'Jill N. Tokuda' };
const SEQ_START: Record<number, number> = { 1: 1, 2: 1 };

type Cand = { cd: number; name: string; party: string };
const FIELD: Cand[] = [
  { cd: 1, name: 'Jennifer Booker',     party: 'Democratic' },
  { cd: 1, name: 'Ben Fatula',          party: 'Democratic' },
  { cd: 1, name: 'Jarrett Keohokalole', party: 'Democratic' },
  { cd: 1, name: 'Nicholas Kiswanto',   party: 'Democratic' },
  { cd: 1, name: 'Nathan Berning',      party: 'Nonpartisan' },
  { cd: 1, name: 'Jordan Conley',       party: 'Green' },
  { cd: 1, name: 'Adriel Lam',          party: 'Republican' },
  { cd: 2, name: 'Kirill Basin',        party: 'Democratic' },
  { cd: 2, name: 'Greg Guithues',       party: 'Democratic' },
  { cd: 2, name: 'Steven King',         party: 'Democratic' },
  { cd: 2, name: 'Brenton Awa',         party: 'Republican' },
  { cd: 2, name: 'Edward Codelia',      party: 'Nonpartisan' },
  { cd: 2, name: 'Randall Terry',       party: 'Nonpartisan' },
];

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number };
const rows: Row[] = [];
for (const c of FIELD) {
  seqByCd[c.cd] = (c.cd in seqByCd) ? seqByCd[c.cd] + 1 : SEQ_START[c.cd];
  rows.push({ ...c, geo: '15' + String(c.cd).padStart(2, '0'), ext: -(FIPS * 10000 + c.cd * 100 + seqByCd[c.cd]) });
}

let raceInserts = '';
for (let cd = 1; cd <= 2; cd++) {
  const geo = '15' + String(cd).padStart(2, '0');
  raceInserts += `INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, ${sqlStr(RACE_DESC)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = '${ELECTION}'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
`;
}
const migA = `-- 1264_seed_hi_2026_house_election_races.sql
-- Phase 165-06: 'HI 2026 Statewide General' + 2 U.S. House races on existing NATIONAL_LOWER
--   offices (geo 1501-1502). LATE-PRIMARY -> PROVISIONAL (HI primary 2026-08-08, verified).
--   office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${ELECTION}', '2026-11-03'::date, 'general', 'state', 'HI'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${ELECTION}');

${raceInserts}
COMMIT;
`;
writeFileSync('migrations/1264_seed_hi_2026_house_election_races.sql', migA);

let polInserts = '';
for (const r of rows) {
  const { first, last } = nameParts(r.name);
  polInserts += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}
let rcInserts = '';
const rcFor = (name: string, ext: number, geo: string, inc: boolean) => {
  const { first, last } = nameParts(name);
  return `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(name)}, ${sqlStr(first)}, ${sqlStr(last)}, ${inc}, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.politicians p ON p.external_id = ${ext}
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
`;
};
for (const r of rows) rcInserts += rcFor(r.name, r.ext, r.geo, false);
for (const cd of [1, 2]) rcInserts += rcFor(INC_NAME[cd], INC_EXT[cd], '15' + String(cd).padStart(2, '0'), true);

const migB = `-- 1265_seed_hi_2026_house_candidates.sql
-- Phase 165-06: 13 new HI candidates (In-Primary qualified field ONLY; -150101..-150107 HI-1,
--   -150201..-150206 HI-2, seq from 1, band empty live) + Case (-15001) and Tokuda (-15002)
--   renominated reuse on their crowded primaries (is_incumbent=true). PROVISIONAL, cull >=
--   2026-08-08. EXCLUDED status='Issued' non-filers: Belatti, Burd, Cuadra, Frazier, Gisa,
--   Curtis, Lucas-Tadeo, Martin. NOT EXISTS on (race_id, politician_id); sqlStr()-escaped.
BEGIN;

${polInserts}
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1265_seed_hi_2026_house_candidates.sql', migB);

const dupName = [...rows.map(r=>r.name.toLowerCase()), ...Object.values(INC_NAME).map(n=>n.toLowerCase())].filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`HI new: ${rows.length} (${rows.map(r=>r.ext).join(', ')}); incumbents reused: 2; dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('Wrote: migrations/1264_..., migrations/1265_...');
