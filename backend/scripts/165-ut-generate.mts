import { writeFileSync, mkdirSync } from 'fs';

// ---- UT field (validated against 160-field-table-p165.csv UT rows + LIVE prod checks 2026-07-07) ----
// Phase 165-02: UT court-ordered re-key seed, executing the BINDING 164.1-ut-wiring-contract VERBATIM.
//   LWV v. Utah Legislature remedial map (effective 2025-11-10): geo_ids 4901-4904 PERSIST; only the
//   polygons changed (G5200V26, imported in 164.1-03). Wiring RULE: races go on the EXISTING
//   NATIONAL_LOWER offices; incumbents run on their NEW district's race as race_candidates
//   (candidacy != office): Moore old-D1 -> NEW 4902; Maloy old-D2 -> NEW 4903; Kennedy old-D3 -> NEW
//   4904; Owens (old D4) RETIRED -> 0 rows; NEW 4901 (compact SLC district) is OPEN (McAdams D field).
//   essentials.offices / essentials.geo_districts / connect.user_districts are NEVER written — the
//   reps feed intentionally stays old-map-keyed until the Jan-2027 promotion phase (164.1-06 spec).
//   DECIDED field (Jun-23 primary done) -> NOT PROVISIONAL. Primary-losers get 0 rows.
//   Reuse pids (live-confirmed 2026-07-07): Moore e365a1d4, Maloy a7983eb6, Kennedy 9e3164d5,
//   McAdams b78f058c, Crosby e3cbc264, Udell a7e29796, Larsen 6708ceaa. Riley Owen absent live -> NEW.
//   UT new-challenger band -490499..-490101 confirmed EMPTY live -> seq starts 1 per district.
const ELECTION = 'UT 2026 Statewide General';
const SRC = 'UT vote.utah.gov 2026 candidate filings (decided; court-ordered 2026 map, LWV v. Utah Legislature)';
const RACE_DESC = 'Confirmed general field on the court-ordered 2026 map (LWV v. Utah Legislature; geo_ids persist, polygons G5200V26)';

// Reused pids (race_candidates INSERT keyed by known UUID literal; NO politicians INSERT for these).
type Reuse = { geo: string; name: string; pid: string; inc: boolean; party: string };
const REUSE: Reuse[] = [
  { geo: '4901', name: 'Ben McAdams',   pid: 'b78f058c-94de-4081-91fb-86ab7badb2fb', inc: false, party: 'Democratic' },
  { geo: '4902', name: 'Blake Moore',   pid: 'e365a1d4-2de3-4fb6-b416-d78227836553', inc: true,  party: 'Republican' },
  { geo: '4902', name: 'Peter Crosby',  pid: 'e3cbc264-534e-4e47-a288-8ac389bf78f4', inc: false, party: 'Democratic' },
  { geo: '4903', name: 'Celeste Maloy', pid: 'a7983eb6-bae0-4269-856b-f4554fb5ce29', inc: true,  party: 'Republican' },
  { geo: '4903', name: 'Kent Udell',    pid: 'a7e29796-a928-49cc-b795-973a4f69fafe', inc: false, party: 'Democratic' },
  { geo: '4904', name: 'Mike Kennedy',  pid: '9e3164d5-ce71-4c50-9220-b969265ce551', inc: true,  party: 'Republican' },
  { geo: '4904', name: 'Jonny Larsen',  pid: '6708ceaa-ae51-4eee-93a3-d4a3be16254d', inc: false, party: 'Democratic' },
];
// Burgess Owens cb87ddbb-5a83-45b7-b67a-789e63f0e58b: RETIRED -> 0 race_candidates rows anywhere.

// New challengers: external_id = -(49*10000+cd*100+seq), seq starts 1 (band empty live).
type Cand = { cd: number; name: string; party: string };
const NEW_FIELD: Cand[] = [
  { cd: 1, name: 'Riley Owen',             party: 'Republican' },
  { cd: 1, name: 'Jesse West',             party: 'Libertarian' },
  { cd: 1, name: 'Elias Henry Montgomery', party: 'Unaffiliated' },
  { cd: 2, name: 'Daniel Cottam',          party: 'Libertarian' },
  { cd: 2, name: 'Carlton E. Bowen',       party: 'Independent American' },
  { cd: 2, name: 'Robert M. Moesinger',    party: 'Unaffiliated' },
  { cd: 3, name: 'Cassie Easley',          party: 'Constitution' },
  { cd: 3, name: 'Adonis Hooslyn',         party: 'Unaffiliated' },
  { cd: 3, name: 'Ayden Scott',            party: 'Unaffiliated' },
  { cd: 3, name: 'Michael R. Stoddard',    party: 'Libertarian' },
  { cd: 4, name: 'Taylor Wright',          party: 'Libertarian' },
  { cd: 4, name: 'Steven Burt',            party: 'Unaffiliated' },
];

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number };
const rows: Row[] = [];
for (const c of NEW_FIELD) {
  seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
  rows.push({ ...c, geo: '49' + String(c.cd).padStart(2, '0'), ext: -(49 * 10000 + c.cd * 100 + seqByCd[c.cd]) });
}

// ---- CSV reconciliation ----
mkdirSync('data/seed-ut-2026-house', { recursive: true });
const notes = '# UT court-ordered re-key (164.1-ut-wiring-contract): races on EXISTING offices 4901-4904; incumbents ' +
  're-linked onto NEW district races (Moore->4902, Maloy->4903, Kennedy->4904); 4901 OPEN (McAdams field); ' +
  'Owens retired -> NO-ROW; offices/geo_districts/user_districts NEVER written (Jan-2027 promotion re-keys offices).';
const header = 'geo_id,full_name,party_from_field,decision,pid_or_external_id,is_incumbent,source';
const csvLines: string[] = [];
for (const r of REUSE) csvLines.push([r.geo, `"${r.name}"`, r.party, r.inc ? 'RE-LINK-INCUMBENT' : 'REUSE-PRIMARY-PID', r.pid, r.inc, `"${SRC}"`].join(','));
csvLines.push(['-', '"Burgess Owens"', 'Republican', 'RETIRED-NO-ROW', 'cb87ddbb-5a83-45b7-b67a-789e63f0e58b', false, `"${SRC}"`].join(','));
for (const r of rows) csvLines.push([r.geo, `"${r.name.replace(/"/g, '""')}"`, r.party, 'NEW', r.ext, false, `"${SRC}"`].join(','));
writeFileSync('data/seed-ut-2026-house/165-02-ut-reconciliation.csv', [notes, header, ...csvLines].join('\n') + '\n');

// ---- Migration A (1252): election + 4 races on EXISTING offices ----
let raceInserts = '';
for (let cd = 1; cd <= 4; cd++) {
  const geo = '49' + String(cd).padStart(2, '0');
  raceInserts += `INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, ${sqlStr(RACE_DESC)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = ${sqlStr(ELECTION)}
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
`;
}

const migA = `-- 1252_seed_ut_2026_house_election_races.sql
-- Phase 165-02: 'UT 2026 Statewide General' election + 4 U.S. House races on UT's EXISTING
--   NATIONAL_LOWER offices (geo_ids 4901-4904 persist; polygons already G5200V26 per 164.1-03).
--   BINDING 164.1-ut-wiring-contract: offices stay keyed to OLD incumbents until the Jan-2027
--   promotion phase — this migration contains NO writes to the offices / geo-districts /
--   user-districts tables (forbidden strings intentionally not spelled out). office_id is never NULL.
--   DECIDED field (Jun-23 primary done) -> NOT PROVISIONAL. ANTIPARTISAN: party never stored.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${ELECTION}', '2026-11-03'::date, 'general', 'state', 'UT'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${ELECTION}');

-- 4 races on the EXISTING offices (NOT EXISTS on (election_id, office_id))
${raceInserts}
COMMIT;
`;
writeFileSync('migrations/1252_seed_ut_2026_house_election_races.sql', migA);

// ---- Migration B (1253): candidates — re-link incumbents + reuse primary pids + new challengers ----
let polInserts = '';
for (const r of rows) {
  const { first, last } = nameParts(r.name);
  polInserts += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}

// (i) reused pids by known UUID literal (incumbent re-link + primary winners)
let reuseInserts = '';
for (const r of REUSE) {
  const { first, last } = nameParts(r.name);
  reuseInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, '${r.pid}'::uuid, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, ${r.inc}, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = ${sqlStr(ELECTION)}
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = ${sqlStr(r.geo)}
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = '${r.pid}'::uuid);
`;
}

// (ii) new challengers by external_id
let newInserts = '';
for (const r of rows) {
  const { first, last } = nameParts(r.name);
  newInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, false, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = ${sqlStr(ELECTION)}
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = ${sqlStr(r.geo)}
JOIN essentials.politicians p ON p.external_id = ${r.ext}
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
`;
}

const migB = `-- 1253_seed_ut_2026_house_candidates.sql
-- Phase 165-02: UT candidate wiring per the BINDING 164.1-ut-wiring-contract.
--   Incumbent RE-LINK onto NEW district races (candidacy != office): Moore e365a1d4 -> 4902,
--   Maloy a7983eb6 -> 4903, Kennedy 9e3164d5 -> 4904 (is_incumbent=true, existing pids — NO new
--   politician records). 4901 (new compact SLC district) OPEN: McAdams b78f058c (reuse) + Riley
--   Owen/Jesse West/Elias Henry Montgomery (new). Primary-winner pid reuse: Crosby e3cbc264,
--   Udell a7e29796, Larsen 6708ceaa. Burgess Owens (retired) + all Jun-23 primary-losers: 0 rows.
--   ${rows.length} new challengers at -(49*10000+cd*100+seq), seq from 1 (band empty live 2026-07-07).
--   NO writes to the offices / geo-districts / user-districts tables (dual-map design preserved).
--   NOT EXISTS guards on (race_id, politician_id); sqlStr()-escaped. ANTIPARTISAN: party never stored.
BEGIN;

-- (a) ${rows.length} new challenger records (idempotent on external_id)
${polInserts}
-- (b) reused pids re-linked onto their NEW district's race
${reuseInserts}
-- (c) ${rows.length} new challenger race_candidates
${newInserts}
COMMIT;
`;
writeFileSync('migrations/1253_seed_ut_2026_house_candidates.sql', migB);

const allNames = [...REUSE.map(r=>r.name.toLowerCase()), ...rows.map(r=>r.name.toLowerCase())];
const dupName = allNames.filter((v,i,a)=>a.indexOf(v)!==i);
const dupExt = rows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const forbidden = /UPDATE\s+essentials\.offices|essentials\.geo_districts|connect\.user_districts/i;
console.log(`reuse rows: ${REUSE.length} (3 incumbent re-links + 4 primary winners); new: ${rows.length}`);
console.log(`new external_id range: ${Math.min(...rows.map(r=>r.ext))} .. ${Math.max(...rows.map(r=>r.ext))}`);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}; dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log(`forbidden-write self-check: ${forbidden.test(migA) || forbidden.test(migB) ? 'FOUND — ABORT' : 'clean'}`);
for (let cd=1; cd<=4; cd++) console.log(`  UT-${cd} (49${String(cd).padStart(2,'0')}): ${REUSE.filter(r=>r.geo==='490'+cd).length + rows.filter(r=>r.cd===cd).length} active, new ext: ${rows.filter(r=>r.cd===cd).map(r=>r.ext).join(',')}`);
console.log('\nWrote: migrations/1252_seed_ut_2026_house_election_races.sql, migrations/1253_seed_ut_2026_house_candidates.sql, data/seed-ut-2026-house/165-02-ut-reconciliation.csv');
