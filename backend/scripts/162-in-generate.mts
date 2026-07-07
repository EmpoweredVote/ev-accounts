import { writeFileSync, mkdirSync } from 'fs';

// ---- IN field (validated against 160-field-table-p162.csv IN rows + LIVE prod dedup 2026-07-04) ----
// Phase 162-07 Task 2: IN end-to-end seed (vanilla new-election, 1-election, DECIDED field —
//   May-5 primary done, NOT PROVISIONAL). MN/MO ran ahead; IN+MD run last (small, decided).
//
// DEVIATION FROM PLAN (dedup): the plan assumed all 12 general challengers are new. LIVE prod
//   shows 7 already exist (created 2026-05-22 by indiana_discovery / federal_2026_bulk_seed),
//   several under formal names. Per operator decision (2026-07-04): REUSE the 7 existing records
//   (assign them -180xxx external_ids), CREATE 5 genuinely-absent ones, and deactivate the 2 junk
//   duplicate "Brad Meyer" orphans. This satisfies the 0-duplicate criterion.
//   Reuse mappings (ballot name -> existing pid, existing DB name):
//     William Henry   -> cfca3142-... (William Henry, indiana_discovery)
//     Kelly Thompson  -> e976e2c2-... (Kelly Thompson, indiana_discovery)
//     J.D. Ford       -> ad47de71-... (Jonathan Ford, indiana_discovery; J.D.=Jonathan David Ford, IN state senator)
//     Cinde Wirth     -> 90342c06-... (Cynthia Wirth, indiana_discovery; Cinde=Cynthia)
//     Patrick McAuley -> cda9e16f-... (Patrick Mcauley, federal_2026_bulk_seed, exact name)
//     Brad Meyer      -> 926943ad-... (Bradley Meyer, federal_2026_bulk_seed; rc-linked to IN-9 Dem primary — confirmed IN)
//     Tonya Hudson    -> 8f08a551-... (Tonya Hudson, indiana_discovery)
//   Junk Brad Meyer orphans to deactivate: 32d8cc05-... (active dup), 9d124770-... (already inactive).
//
// Incumbents keep existing external_ids — MIXED schemes: legacy -18nnn for 1/2/3/5/6, POSITIVE
//   SoS ids for Baird 499386, Carson 499408, Messmer 499413, Houchin 499417.

type Disp = 'NEW' | 'REUSE_PID' | 'INC';
type Cand = { cd: number; name: string; party: string; role: string; disp: Disp; pid?: string; ext?: number };

const FIELD: Cand[] = [
  // IN-1 (1801): Frank Mrvan (D) renominated
  { cd:1, name:'Frank Mrvan', party:'D', role:'D', disp:'INC', ext:-18001 },
  { cd:1, name:'Barb Regnitz', party:'R', role:'R', disp:'NEW' },
  // IN-2 (1802): Rudy Yakym III (R) renominated
  { cd:2, name:'Rudy Yakym III', party:'R', role:'R', disp:'INC', ext:-18002 },
  { cd:2, name:'Jamee Decio', party:'D', role:'D', disp:'NEW' },
  { cd:2, name:'William Henry', party:'L', role:'L', disp:'REUSE_PID', pid:'cfca3142-3f46-4ff3-a77f-cbb2438929d8' },
  // IN-3 (1803): Marlin Stutzman (R) renominated
  { cd:3, name:'Marlin Stutzman', party:'R', role:'R', disp:'INC', ext:-18003 },
  { cd:3, name:'Kelly Thompson', party:'D', role:'D', disp:'REUSE_PID', pid:'e976e2c2-52c1-48c9-a5a6-4337d6740f71' },
  // IN-4 (1804): Jim Baird (R) renominated — POSITIVE SoS id
  { cd:4, name:'Jim Baird', party:'R', role:'R', disp:'INC', ext:499386 },
  { cd:4, name:'Drew Cox', party:'D', role:'D', disp:'NEW' },
  // IN-5 (1805): Victoria Spartz (R) renominated
  { cd:5, name:'Victoria Spartz', party:'R', role:'R', disp:'INC', ext:-18005 },
  { cd:5, name:'J.D. Ford', party:'D', role:'D', disp:'REUSE_PID', pid:'ad47de71-253c-4710-976e-1d57b7787cae' },
  // IN-6 (1806): Jefferson Shreve (R) renominated
  { cd:6, name:'Jefferson Shreve', party:'R', role:'R', disp:'INC', ext:-18006 },
  { cd:6, name:'Cinde Wirth', party:'D', role:'D', disp:'REUSE_PID', pid:'90342c06-b82a-4e86-8d89-152ab07a4c66' },
  // IN-7 (1807): André Carson (D) renominated — POSITIVE SoS id
  { cd:7, name:'André Carson', party:'D', role:'D', disp:'INC', ext:499408 },
  { cd:7, name:'Patrick McAuley', party:'R', role:'R', disp:'REUSE_PID', pid:'cda9e16f-b175-42ee-bc16-a8f110512392' },
  { cd:7, name:'James Sceniak', party:'L', role:'L', disp:'NEW' },
  // IN-8 (1808): Mark Messmer (R) renominated — POSITIVE SoS id
  { cd:8, name:'Mark Messmer', party:'R', role:'R', disp:'INC', ext:499413 },
  { cd:8, name:'Mary Allen', party:'D', role:'D', disp:'NEW' },
  // IN-9 (1809): Erin Houchin (R) renominated — POSITIVE SoS id (flag-fix 1212 applied first)
  { cd:9, name:'Erin Houchin', party:'R', role:'R', disp:'INC', ext:499417 },
  { cd:9, name:'Brad Meyer', party:'D', role:'D', disp:'REUSE_PID', pid:'926943ad-ee64-4ddb-b9e7-6475a6a2d087' },
  { cd:9, name:'Tonya Hudson', party:'L', role:'L', disp:'REUSE_PID', pid:'8f08a551-71c8-43c4-9bcc-b18fd3ac0abc' },
];

// junk duplicate "Brad Meyer" orphans to deactivate (no source, rc_ct=0, dup of Bradley Meyer)
const JUNK_DUP_PIDS = ['32d8cc05-7780-455a-8771-d3024c00522c', '9d124770-3beb-468f-89de-a56f2267b16e'];

const SRC_MAJOR = 'IN SoS 2026 filings + Wikipedia/GreenPapers 2026 IN US House (decided field, May-5 primary)';
const SRC_OTHER = 'IN SoS 2026 filings, declared minor-party/independent (decided field, May-5 primary)';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- assign external_ids for NEW + REUSE_PID (per-district seq in FIELD order); INC keep theirs ----
// IN fips = 18; formula: -(18*10000 + cd*100 + seq). REUSE_PID records get a band external_id via UPDATE.
const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; is_incumbent: boolean; source: string; decision: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '18' + String(c.cd).padStart(2, '0');
  const source = c.role === 'D' || c.role === 'R' ? SRC_MAJOR : SRC_OTHER;
  if (c.disp === 'INC') {
    rows.push({ ...c, geo, ext: c.ext!, is_incumbent: true, source, decision: 'REUSE-INC' });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(18 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, is_incumbent: false, source, decision: c.disp === 'NEW' ? 'NEW' : 'REUSE-PID' });
  }
}

// ---- CSV reconciliation ----
mkdirSync('data/seed-in-2026-house', { recursive: true });
const header = 'cd,geo_id,ballot_name,party_from_field,role,decision,assign_external_id,existing_pid,is_incumbent,source';
const csvLines = rows.map(r => [r.cd, r.geo, `"${r.name}"`, r.party, r.role, r.decision, r.ext, r.pid || '', r.is_incumbent, `"${r.source}"`].join(','));
writeFileSync('data/seed-in-2026-house/162-07-in-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration 1213: election + 9 races (decided-field wording) ----
const mElections = `-- 1213_seed_in_2026_house_elections_races.sql
-- Phase 162-07 Task 2: IN 2026 Statewide General election + 9 U.S. House races.
-- Field source: 160-field-table-p162.csv (IN rows) + GreenPapers/Wikipedia 2026 IN US House.
-- DECIDED field (May-5 primary done) -> NOT PROVISIONAL-marked. ANTIPARTISAN INVARIANT: party
--   never stored on race_candidates; races.primary_party stays NULL. All 9 district offices
--   already exist -- NO office/district insert. (IN-9 primary incumbent flags corrected first
--   in migration 1212.)
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'IN 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'IN'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'IN 2026 Statewide General');

-- 9 races on the EXISTING IN NATIONAL_LOWER US Rep offices (geo 1801..1809)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'Confirmed nominee + declared-so-far minor-party field (primary decided May-5)'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '18'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'IN 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
`;
writeFileSync('migrations/1213_seed_in_2026_house_elections_races.sql', mElections);

// ---- Migration 1214: reuse-assign external_ids + deactivate junk dups + insert new + race_candidates ----
const newRows = rows.filter(r => r.decision === 'NEW');
const reusePidRows = rows.filter(r => r.decision === 'REUSE-PID');
const activeRows = rows; // all 21 (12 challengers + 9 incumbents) get an active general rc row

// (a) assign band external_ids to the 7 reused records (guarded: only if still NULL)
let reuseUpdates = '';
for (const r of reusePidRows) {
  reuseUpdates += `UPDATE essentials.politicians SET external_id = ${r.ext}, is_active = true
WHERE id = '${r.pid}' AND external_id IS NULL;
`;
}

// (b) deactivate junk duplicate Brad Meyer orphans (guarded)
let junkUpdates = '';
for (const pid of JUNK_DUP_PIDS) {
  junkUpdates += `UPDATE essentials.politicians SET is_active = false WHERE id = '${pid}' AND is_active = true;
`;
}

// (c) insert the 5 genuinely-new challenger records (idempotent on external_id)
let polInserts = '';
for (const r of newRows) {
  const { first, last } = nameParts(r.name);
  polInserts += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}

// (d) race_candidates for all 21 (join politicians by external_id; full_name = ballot name)
let rcInserts = '';
for (const r of activeRows) {
  const { first, last } = nameParts(r.name);
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, ${r.is_incumbent}, 'active', ${sqlStr(r.source)}
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = ${r.ext}
WHERE el.name = 'IN 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}

const mCandidates = `-- 1214_seed_in_2026_house_candidates.sql
-- Phase 162-07 Task 2: IN 2026 general field wiring. Per operator dedup decision (2026-07-04):
--   ${reusePidRows.length} REUSE existing records (assign -180xxx external_ids), ${newRows.length} NEW records, deactivate
--   2 junk duplicate "Brad Meyer" orphans. 9 incumbents reused by existing external_id (mixed
--   -18nnn + positive SoS ids). ${activeRows.length} active race_candidates total. ANTIPARTISAN: party never stored.
--   All statements guarded for idempotent 0-row re-apply.
BEGIN;

-- (a) assign band external_ids to the ${reusePidRows.length} reused discovery/bulk-seed records
${reuseUpdates}
-- (b) deactivate ${JUNK_DUP_PIDS.length} junk duplicate "Brad Meyer" orphans
${junkUpdates}
-- (c) ${newRows.length} genuinely-new challenger records (idempotent on external_id)
${polInserts}
-- (d) ${activeRows.length} active race_candidates (12 challengers + 9 incumbents; join by external_id)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1214_seed_in_2026_house_candidates.sql', mCandidates);

console.log(`rows: ${rows.length} (challengers=${newRows.length + reusePidRows.length}, incumbents=${rows.filter(r=>r.decision==='REUSE-INC').length})`);
console.log(`  NEW=${newRows.length}, REUSE-PID=${reusePidRows.length}, REUSE-INC=${rows.filter(r=>r.decision==='REUSE-INC').length}`);
const challExt = [...newRows, ...reusePidRows].map(r=>r.ext);
console.log(`challenger external_id range: ${Math.min(...challExt)} .. ${Math.max(...challExt)}`);
const dupExt = challExt.filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup ballot_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district active counts:');
for (let cd=1; cd<=9; cd++) console.log(`  IN-${cd}: ${activeRows.filter(r=>r.cd===cd).length} active`);
console.log('\nWrote: migrations/1213_..., migrations/1214_..., data/seed-in-2026-house/162-07-in-reconciliation.csv');
