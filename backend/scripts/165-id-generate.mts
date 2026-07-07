import { writeFileSync, mkdirSync } from 'fs';

// ---- ID field (validated against staging/p165-ID.csv + LIVE prod checks 2026-07-07) ----
// Phase 165-05: ID vanilla create-election-first seed (162-mn pattern).
//   1 election 'ID 2026 Statewide General' + 2 races on existing NATIONAL_LOWER offices (1601-1602).
//   DECIDED -> NOT PROVISIONAL. Both incumbents renominated (reuse -16001 Fulcher / -16002 Simpson).
//   MULTI-PARTY challenger field (Constitution/Libertarian/Independent as well as D) — parties
//   normalized in the reconciliation CSV only, never on the card.
//   Band -160299..-160101 confirmed EMPTY live -> seq starts 1.
const ELECTION = 'ID 2026 Statewide General';
const FIPS = 16;
const RACE_DESC = 'Confirmed general field (ID SoS certified 2026 candidate list)';
const SRC = 'ID 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Idaho)';

const INC_EXT: Record<number, number> = { 1: -16001, 2: -16002 };
const INC_NAME: Record<number, string> = { 1: 'Russ Fulcher', 2: 'Michael K. Simpson' };
const SEQ_START: Record<number, number> = { 1: 1, 2: 1 };

type Cand = { cd: number; name: string; party: string };
const FIELD: Cand[] = [
  { cd: 1, name: 'Kaylee Peterson',  party: 'Democratic' },
  { cd: 1, name: 'Brendan Gomez',    party: 'Constitution' },
  { cd: 1, name: 'Sarah Zabel',      party: 'Independent' },
  { cd: 2, name: 'Elinor Gilbreath', party: 'Democratic' },
  { cd: 2, name: 'Will Johanson',    party: 'Libertarian' },
  { cd: 2, name: 'Carta Sierra',     party: 'Constitution' },
  { cd: 2, name: 'Emre Houser',      party: 'Independent' },
  { cd: 2, name: 'Tripp Hutchinson', party: 'Independent' },
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
  rows.push({ ...c, geo: '16' + String(c.cd).padStart(2, '0'), ext: -(FIPS * 10000 + c.cd * 100 + seqByCd[c.cd]) });
}

let raceInserts = '';
for (let cd = 1; cd <= 2; cd++) {
  const geo = '16' + String(cd).padStart(2, '0');
  raceInserts += `INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, ${sqlStr(RACE_DESC)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = '${ELECTION}'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
`;
}
const migA = `-- 1262_seed_id_2026_house_election_races.sql
-- Phase 165-05: 'ID 2026 Statewide General' + 2 U.S. House races on existing NATIONAL_LOWER
--   offices (geo 1601-1602). DECIDED -> NOT PROVISIONAL. office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${ELECTION}', '2026-11-03'::date, 'general', 'state', 'ID'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${ELECTION}');

${raceInserts}
COMMIT;
`;
writeFileSync('migrations/1262_seed_id_2026_house_election_races.sql', migA);

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
for (const cd of [1, 2]) rcInserts += rcFor(INC_NAME[cd], INC_EXT[cd], '16' + String(cd).padStart(2, '0'), true);

const migB = `-- 1263_seed_id_2026_house_candidates.sql
-- Phase 165-05: 8 new ID challengers (multi-party: D/Constitution/Libertarian/Independent;
--   -160101..-160103 ID-1, -160201..-160205 ID-2, seq from 1, band empty live) + Fulcher (-16001)
--   and Simpson (-16002) renominated reuse (is_incumbent=true). DECIDED.
--   NOT EXISTS on (race_id, politician_id); sqlStr()-escaped. ANTIPARTISAN.
BEGIN;

${polInserts}
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1263_seed_id_2026_house_candidates.sql', migB);

const dupName = [...rows.map(r=>r.name.toLowerCase()), ...Object.values(INC_NAME).map(n=>n.toLowerCase())].filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`ID new: ${rows.length} (${rows.map(r=>r.ext).join(', ')}); incumbents reused: 2; dup full_name: ${dupName.length ? dupName : 'none'}`);

// ---- combined WV+ID reconciliation CSV ----
mkdirSync('data/seed-wv-2026-house', { recursive: true });
const notes = '# WV + ID 165-05 reconciliation. DECIDED fields, NOT PROVISIONAL. WV independent window to 2026-08-03 -> Phase 167. ID multi-party challengers.';
const header = 'state,cd,geo_id,full_name,party_from_field,decision,external_id,is_incumbent';
const wv = [
  ['WV',1,5401,'"Carol D. Miller"','Republican','REUSE-INCUMBENT',-54001,true],
  ['WV',1,5401,'"Vince George"','Democratic','NEW',-540101,false],
  ['WV',1,5401,'"Isaiah Rucker"','Independent','NEW',-540102,false],
  ['WV',2,5402,'"Riley M. Moore"','Republican','REUSE-INCUMBENT',-54002,true],
  ['WV',2,5402,'"Ace Parsi"','Democratic','NEW',-540201,false],
  ['WV',2,5402,'"Pat Carney"','Independent','NEW',-540202,false],
  ['WV',2,5402,'"Chris Whitcomb"','Independent','NEW',-540203,false],
];
const idr = [
  ['ID',1,1601,'"Russ Fulcher"','Republican','REUSE-INCUMBENT',-16001,true],
  ['ID',1,1601,'"Kaylee Peterson"','Democratic','NEW',-160101,false],
  ['ID',1,1601,'"Brendan Gomez"','Constitution','NEW',-160102,false],
  ['ID',1,1601,'"Sarah Zabel"','Independent','NEW',-160103,false],
  ['ID',2,1602,'"Michael K. Simpson"','Republican','REUSE-INCUMBENT',-16002,true],
  ['ID',2,1602,'"Elinor Gilbreath"','Democratic','NEW',-160201,false],
  ['ID',2,1602,'"Will Johanson"','Libertarian','NEW',-160202,false],
  ['ID',2,1602,'"Carta Sierra"','Constitution','NEW',-160203,false],
  ['ID',2,1602,'"Emre Houser"','Independent','NEW',-160204,false],
  ['ID',2,1602,'"Tripp Hutchinson"','Independent','NEW',-160205,false],
];
writeFileSync('data/seed-wv-2026-house/165-05-wv-id-reconciliation.csv',
  [notes, header, ...wv.map(r=>r.join(',')), ...idr.map(r=>r.join(','))].join('\n') + '\n');
console.log('Wrote: migrations/1262_..., migrations/1263_..., data/seed-wv-2026-house/165-05-wv-id-reconciliation.csv');
