import { writeFileSync, mkdirSync } from 'fs';

// ---- NE field (validated against staging/p165-NE.csv + LIVE prod checks 2026-07-07) ----
// Phase 165-04: NE vanilla create-election-first seed (162-mn pattern).
//   1 election 'NE 2026 Statewide General' + 3 races on existing NATIONAL_LOWER offices (3101-3103).
//   DECIDED field -> NOT PROVISIONAL. NE-1 Flood (-31001) + NE-3 Smith (-31003) renominated reuse;
//   NE-2 OPEN (Bacon 0cc444a0 retired Jun-30-2025, endorsed Harding) -> REUSE-NO-ROW, all-new field.
//   Pitfall 5 EXCLUDE (NOT SoS-certified; NRS 32-617(1) petition window open to 2026-08-01 ->
//   Phase 167): NE-1 Austin Ahlman (I), NE-3 Macey Budke (I) + Mark Cohen (I).
//   D-04: NE-3 safe_start_seq=60 (band top -310359); NE-1/NE-2 start 1 (bands empty).
const ELECTION = 'NE 2026 Statewide General';
const FIPS = 31;
const RACE_DESC = 'Confirmed general field; NE independent-petition window open to 2026-08-01 -> Phase 167';
const SRC = 'NE SoS/electionresults.nebraska.gov 2026 general field (decided; petition window to 2026-08-01 -> Phase 167)';

const INC_EXT: Record<number, number> = { 1: -31001, 3: -31003 };   // NE-2 Bacon: REUSE-NO-ROW
const INC_NAME: Record<number, string> = { 1: 'Mike Flood', 3: 'Adrian Smith' };
const SEQ_START: Record<number, number> = { 1: 1, 2: 1, 3: 60 };

type Cand = { cd: number; name: string; party: string };
const FIELD: Cand[] = [
  { cd: 1, name: 'Chris Backemeyer', party: 'Democratic' },
  { cd: 1, name: 'Nik Sandman',      party: 'Libertarian' },
  // NE-1 Austin Ahlman (I): EXCLUDED — not SoS-certified (petition window open to 2026-08-01; Phase 167)
  { cd: 2, name: 'Brinker Harding',  party: 'Republican' },
  { cd: 2, name: 'Denise Powell',    party: 'Democratic' },
  { cd: 2, name: 'Eric Foreman',     party: 'Libertarian' },
  { cd: 3, name: 'Becky Stille',     party: 'Democratic' },
  { cd: 3, name: 'David Else',       party: 'Legal Marijuana NOW' },
  // NE-3 Macey Budke (I) + Mark Cohen (I): EXCLUDED — not SoS-certified (Phase 167)
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
  rows.push({ ...c, geo: '31' + String(c.cd).padStart(2, '0'), ext: -(FIPS * 10000 + c.cd * 100 + seqByCd[c.cd]) });
}

// ---- Migration A (1258): election + 3 races ----
let raceInserts = '';
for (let cd = 1; cd <= 3; cd++) {
  const geo = '31' + String(cd).padStart(2, '0');
  raceInserts += `INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, ${sqlStr(RACE_DESC)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = '${ELECTION}'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
`;
}
const migA = `-- 1258_seed_ne_2026_house_election_races.sql
-- Phase 165-04: 'NE 2026 Statewide General' + 3 U.S. House races on existing NATIONAL_LOWER
--   offices (geo 3101-3103). DECIDED field -> NOT PROVISIONAL (NE petition window open to
--   2026-08-01 -> Phase 167 reconciles late independents). office_id never NULL.
--   ANTIPARTISAN: party never stored.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${ELECTION}', '2026-11-03'::date, 'general', 'state', 'NE'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${ELECTION}');

${raceInserts}
COMMIT;
`;
writeFileSync('migrations/1258_seed_ne_2026_house_election_races.sql', migA);

// ---- Migration B (1259): 7 new + 2 incumbent reuse; Bacon NO-ROW ----
let polInserts = '';
for (const r of rows) {
  const { first, last } = nameParts(r.name);
  polInserts += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}
let rcInserts = '';
for (const r of rows) {
  const { first, last } = nameParts(r.name);
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, false, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = ${sqlStr(r.geo)}
JOIN essentials.politicians p ON p.external_id = ${r.ext}
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
`;
}
for (const cd of [1, 3]) {
  const { first, last } = nameParts(INC_NAME[cd]);
  const geo = '31' + String(cd).padStart(2, '0');
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(INC_NAME[cd])}, ${sqlStr(first)}, ${sqlStr(last)}, true, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.politicians p ON p.external_id = ${INC_EXT[cd]}
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
`;
}
const migB = `-- 1259_seed_ne_2026_house_candidates.sql
-- Phase 165-04: 7 new NE candidates (NE-1 Backemeyer -310101 / Sandman -310102; NE-2 OPEN field
--   Harding -310201 / Powell -310202 / Foreman -310203; NE-3 Stille -310360 / Else -310361, D-04
--   safe_start_seq=60) + Flood (-31001) and Smith (-31003) renominated reuse (is_incumbent=true).
--   NE-2 Bacon (0cc444a0, retired Jun-30-2025) gets NO row. EXCLUDED (not SoS-certified, petition
--   window to 2026-08-01 -> Phase 167): Ahlman (NE-1), Budke + Cohen (NE-3).
--   NOT EXISTS on (race_id, politician_id); sqlStr()-escaped. ANTIPARTISAN: party never stored.
BEGIN;

${polInserts}
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1259_seed_ne_2026_house_candidates.sql', migB);

const dupName = [...rows.map(r=>r.name.toLowerCase()), ...Object.values(INC_NAME).map(n=>n.toLowerCase())].filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`NE new: ${rows.length} (${rows.map(r=>r.ext).join(', ')}); incumbents reused: 2 (Bacon NO-ROW); dup full_name: ${dupName.length ? dupName : 'none'}`);

// ---- combined reconciliation CSV (NM + NE, written by the NE generator which runs second) ----
mkdirSync('data/seed-nm-2026-house', { recursive: true });
const notes = '# NM + NE 165-04 reconciliation. DECIDED fields, NOT PROVISIONAL. NE-2 OPEN (Bacon retired -> NO-ROW). ' +
  'EXCLUDED pending-independents (Pitfall 5, NE petition window to 2026-08-01 -> Phase 167): NE-1 Austin Ahlman, NE-3 Macey Budke, NE-3 Mark Cohen.';
const header = 'state,cd,geo_id,full_name,party_from_field,decision,pid_or_external_id,is_incumbent,source';
const csv: string[] = [
  ['NM',1,3501,'"Melanie A. Stansbury"','Democratic','REUSE-INCUMBENT',-35001,true,'"NM SoS"'].join(','),
  ['NM',1,3501,'"Didi Okpareke"','Republican','NEW',-350126,false,'"NM SoS"'].join(','),
  ['NM',2,3502,'"Gabe Vasquez"','Democratic','REUSE-INCUMBENT',-35002,true,'"NM SoS"'].join(','),
  ['NM',2,3502,'"Greg Cunningham"','Republican','NEW',-350251,false,'"NM SoS"'].join(','),
  ['NM',3,3503,'"Teresa Leger Fernandez"','Democratic','REUSE-INCUMBENT',-35003,true,'"NM SoS"'].join(','),
  ['NM',3,3503,'"Martin Zamora"','Republican','NEW',-350382,false,'"NM SoS"'].join(','),
  ['NE',1,3101,'"Mike Flood"','Republican','REUSE-INCUMBENT',-31001,true,'"NE SoS"'].join(','),
  ['NE',1,3101,'"Chris Backemeyer"','Democratic','NEW',-310101,false,'"NE SoS"'].join(','),
  ['NE',1,3101,'"Nik Sandman"','Libertarian','NEW',-310102,false,'"NE SoS"'].join(','),
  ['NE',1,3101,'"Austin Ahlman"','Independent','EXCLUDE-PENDING-PETITION (167)','',false,'"NE petition window to 2026-08-01"'].join(','),
  ['NE',2,3102,'"Don Bacon"','Republican','RETIRED-NO-ROW','0cc444a0-2ae6-48c3-ac8c-a99f45f1e14c',false,'"retired 2025-06-30"'].join(','),
  ['NE',2,3102,'"Brinker Harding"','Republican','NEW',-310201,false,'"NE SoS"'].join(','),
  ['NE',2,3102,'"Denise Powell"','Democratic','NEW',-310202,false,'"NE SoS"'].join(','),
  ['NE',2,3102,'"Eric Foreman"','Libertarian','NEW',-310203,false,'"NE SoS"'].join(','),
  ['NE',3,3103,'"Adrian Smith"','Republican','REUSE-INCUMBENT',-31003,true,'"NE SoS"'].join(','),
  ['NE',3,3103,'"Becky Stille"','Democratic','NEW',-310360,false,'"NE SoS"'].join(','),
  ['NE',3,3103,'"David Else"','Legal Marijuana NOW','NEW',-310361,false,'"NE SoS"'].join(','),
  ['NE',3,3103,'"Macey Budke"','Independent','EXCLUDE-PENDING-PETITION (167)','',false,'"NE petition window to 2026-08-01"'].join(','),
  ['NE',3,3103,'"Mark Cohen"','Independent','EXCLUDE-PENDING-PETITION (167)','',false,'"NE petition window to 2026-08-01"'].join(','),
];
writeFileSync('data/seed-nm-2026-house/165-04-nm-ne-reconciliation.csv', [notes, header, ...csv].join('\n') + '\n');
console.log('Wrote: migrations/1258_..., migrations/1259_..., data/seed-nm-2026-house/165-04-nm-ne-reconciliation.csv');
