import { writeFileSync, mkdirSync } from 'fs';

// ---- NH field (validated against staging/p165-NH.csv + LIVE prod checks 2026-07-07) ----
// Phase 165-06: NH vanilla create-election-first seed (162-mn pattern), LATE-PRIMARY -> PROVISIONAL.
//   1 election 'NH 2026 Statewide General' + 2 races on existing NATIONAL_LOWER offices (3301-3302).
//   NH 2026 primary: 2026-09-08 (verified 2026-07-07) -> cull >= 2026-09-08.
//   NH-1 OPEN: Pappas (pid 36c07696, -33001) filed for U.S. Senate (NH SoS cumulative filing
//   6/29/26) -> REUSE-NO-ROW; full 14-candidate declared field (9D+5R), no incumbent row.
//   D-04 NH-1 safe_start_seq=33 (band occupied to -330132 by 5 NH local officials, live-confirmed).
//   NH-2: Goodlander (-33002) renominated reuse + 5 new (seq from 1, -3302xx band empty).
//   EXCLUDED (Pitfall 5, declarations-of-intent not yet qualified; NH nomination-paper window to
//   2026-09-02 -> Phase 167): Scott Matthew Black, Robbie Mahrou, Sterling Thomas Sykes (all NH-2).
const ELECTION = 'NH 2026 Statewide General';
const FIPS = 33;
const RACE_DESC = 'PROVISIONAL: pre-primary qualified field, cull >= 2026-09-08';
const SRC = 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)';

const INC_EXT: Record<number, number> = { 2: -33002 };   // NH-1 Pappas: REUSE-NO-ROW (Senate run)
const INC_NAME: Record<number, string> = { 2: 'Maggie Goodlander' };
const SEQ_START: Record<number, number> = { 1: 33, 2: 1 };

type Cand = { cd: number; name: string; party: string };
const FIELD: Cand[] = [
  // NH-1 OPEN field (9D + 5R), seq from 33
  { cd: 1, name: 'Carleigh Beriont',    party: 'Democratic' },
  { cd: 1, name: 'Sarah Chadzynski',    party: 'Democratic' },
  { cd: 1, name: 'Bill Conlin',         party: 'Democratic' },
  { cd: 1, name: 'Matthew Emerson',     party: 'Democratic' },
  { cd: 1, name: 'Heath Howard',        party: 'Democratic' },
  { cd: 1, name: 'Stefany Shaheen',     party: 'Democratic' },
  { cd: 1, name: 'Sarah Bella Spinosa', party: 'Democratic' },
  { cd: 1, name: 'Maura Sullivan',      party: 'Democratic' },
  { cd: 1, name: 'Christian Urrutia',   party: 'Democratic' },
  { cd: 1, name: 'Lindsey Anderson',    party: 'Republican' },
  { cd: 1, name: 'Melissa Bailey',      party: 'Republican' },
  { cd: 1, name: 'Brian Cole',          party: 'Republican' },
  { cd: 1, name: 'Anthony DiLorenzo',   party: 'Republican' },
  { cd: 1, name: 'Hollie Noveletsky',   party: 'Republican' },
  // NH-2 challengers, seq from 1
  { cd: 2, name: 'Paige Beauchemin',    party: 'Democratic' },
  { cd: 2, name: 'Michael Callis',      party: 'Republican' },
  { cd: 2, name: 'Dan Nicholson',       party: 'Republican' },
  { cd: 2, name: 'Victor Orlando',      party: 'Republican' },
  { cd: 2, name: 'Lily Tang Williams',  party: 'Republican' },
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
  rows.push({ ...c, geo: '33' + String(c.cd).padStart(2, '0'), ext: -(FIPS * 10000 + c.cd * 100 + seqByCd[c.cd]) });
}

let raceInserts = '';
for (let cd = 1; cd <= 2; cd++) {
  const geo = '33' + String(cd).padStart(2, '0');
  raceInserts += `INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, ${sqlStr(RACE_DESC)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = '${ELECTION}'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
`;
}
const migA = `-- 1266_seed_nh_2026_house_election_races.sql
-- Phase 165-06: 'NH 2026 Statewide General' + 2 U.S. House races on existing NATIONAL_LOWER
--   offices (geo 3301-3302). LATE-PRIMARY -> PROVISIONAL (NH primary 2026-09-08, verified).
--   office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${ELECTION}', '2026-11-03'::date, 'general', 'state', 'NH'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${ELECTION}');

${raceInserts}
COMMIT;
`;
writeFileSync('migrations/1266_seed_nh_2026_house_election_races.sql', migA);

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
rcInserts += rcFor(INC_NAME[2], INC_EXT[2], '3302', true);

const migB = `-- 1267_seed_nh_2026_house_candidates.sql
-- Phase 165-06: 19 new NH candidates — NH-1 OPEN 14-candidate field (9D+5R, seq from 33:
--   -330133..-330146; Pappas 36c07696 -> Senate, NO row) + NH-2 5 new (-330201..-330205) +
--   Goodlander (-33002) renominated reuse (is_incumbent=true). PROVISIONAL, cull >= 2026-09-08.
--   EXCLUDED pending-independents (window to 2026-09-02 -> Phase 167): Black, Mahrou, Sykes.
--   NOT EXISTS on (race_id, politician_id); sqlStr()-escaped. ANTIPARTISAN.
BEGIN;

${polInserts}
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1267_seed_nh_2026_house_candidates.sql', migB);

const dupName = [...rows.map(r=>r.name.toLowerCase()), ...Object.values(INC_NAME).map(n=>n.toLowerCase())].filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`NH new: ${rows.length} (NH-1 ${rows.filter(r=>r.cd===1).length} seq33+, NH-2 ${rows.filter(r=>r.cd===2).length}); Goodlander reused; dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log(`NH-1 ext: ${rows.filter(r=>r.cd===1).map(r=>r.ext).join(',')}`);
console.log(`NH-2 ext: ${rows.filter(r=>r.cd===2).map(r=>r.ext).join(',')}`);

// ---- combined HI+NH reconciliation CSV ----
mkdirSync('data/seed-hi-2026-house', { recursive: true });
const notes = '# HI + NH 165-06 reconciliation. LATE-PRIMARY -> PROVISIONAL (HI cull >= 2026-08-08; NH cull >= 2026-09-08). ' +
  'HI field = olvr.hawaii.gov In-Primary ONLY (excluded Issued: Belatti/Burd/Cuadra/Frazier/Gisa/Curtis/Lucas-Tadeo/Martin). ' +
  'NH-1 OPEN (Pappas -> Senate, NO-ROW). EXCLUDED NH-2 pending-independents (window to 2026-09-02 -> 167): Black/Mahrou/Sykes.';
const header = 'state,cd,full_name,party_from_field,decision,external_id,is_incumbent';
const HI_NEW: Array<[number, string, string, number]> = [
  [1,'Jennifer Booker','Democratic',-150101],[1,'Ben Fatula','Democratic',-150102],
  [1,'Jarrett Keohokalole','Democratic',-150103],[1,'Nicholas Kiswanto','Democratic',-150104],
  [1,'Nathan Berning','Nonpartisan',-150105],[1,'Jordan Conley','Green',-150106],
  [1,'Adriel Lam','Republican',-150107],
  [2,'Kirill Basin','Democratic',-150201],[2,'Greg Guithues','Democratic',-150202],
  [2,'Steven King','Democratic',-150203],[2,'Brenton Awa','Republican',-150204],
  [2,'Edward Codelia','Nonpartisan',-150205],[2,'Randall Terry','Nonpartisan',-150206],
];
const lines: string[] = [];
lines.push(['HI',1,'"Ed Case"','Democratic','REUSE-INCUMBENT',-15001,true].join(','));
lines.push(['HI',2,'"Jill N. Tokuda"','Democratic','REUSE-INCUMBENT',-15002,true].join(','));
for (const [cd,n,p,e] of HI_NEW) lines.push(['HI',cd,`"${n}"`,p,'NEW',e,false].join(','));
lines.push(['NH',1,'"Chris Pappas"','Democratic','RETIRED-NO-ROW (US Senate run)',-33001,false].join(','));
lines.push(['NH',2,'"Maggie Goodlander"','Democratic','REUSE-INCUMBENT',-33002,true].join(','));
for (const r of rows) lines.push(['NH',r.cd,`"${r.name}"`,r.party,'NEW',r.ext,false].join(','));
for (const n of ['Scott Matthew Black','Robbie Mahrou','Sterling Thomas Sykes']) lines.push(['NH',2,`"${n}"`,'Independent','EXCLUDE-PENDING-PETITION (167; window to 2026-09-02)','',false].join(','));
writeFileSync('data/seed-hi-2026-house/165-06-hi-nh-reconciliation.csv',
  [notes, header, ...lines].join('\n') + '\n');
console.log('Wrote: migrations/1266_..., migrations/1267_..., data/seed-hi-2026-house/165-06-hi-nh-reconciliation.csv');
