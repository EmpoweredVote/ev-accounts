import { writeFileSync, mkdirSync } from 'fs';

// ---- MA field (validated against 160-field-table-p161.csv MA rows, cross-checked
//      MA SoS dem-state-primary-candidates2026.htm + declared-independent news coverage) ----
// Phase 161-08 Task 1: MA CANDIDATES-ONLY seed onto the 9 PRE-EXISTING MA races
//   (existing_race_id from 160-race-preexistence-audit.csv). NO elections/races INSERT here.
//   Clark (MA-5) and Pressley (MA-7) already have race_candidates rows (160-race-preexistence-audit.csv
//   rows 29/31) -- NEVER re-inserted. Moulton (MA-6, retired) gets NO incumbent row.
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean };

const EXISTING_RACE_ID: Record<number, string> = {
  1: '3bfd0d89-cbb0-4bd4-952b-798214c29f84',
  2: 'e871b833-3601-48a6-8c1c-b3f9f2b5d5ca',
  3: 'f883b821-4648-4b97-85ee-167fc2542fa5',
  4: '421a301b-eebb-4749-bd65-c3b5a056d687',
  5: 'df10ccfe-8841-41b5-a0de-f5ce182c7b21',
  6: '4a97bcde-4c8b-46b7-816e-9778b8ed17b5',
  7: 'cc751102-b794-4484-88a3-37ca5c515307',
  8: 'e466ea3a-3b67-4fe5-8db4-688825793214',
  9: 'e9b035af-0037-45f5-95bf-6d4940b014b7',
};

// Incumbents renominated and NOT yet wired (per interfaces block); MA-5 Clark and MA-7 Pressley
// are ALREADY wired (skip them entirely -- no politician row, no race_candidates row authored here).
// MA-6 Moulton retired -- no incumbent row at all.
const INC_PID: Record<number, string> = {
  1: 'a0cb697c-3158-4680-8e70-c154c3a15cc4', // Richard Neal
  2: 'ee4081d5-fc3e-4a8c-b39e-481ae20135d5', // Jim McGovern
  3: 'b96758c6-2ea0-4698-8886-d574d34e366d', // Lori Trahan
  4: '41945b74-325e-4fa2-9cc9-edd11ead9ed3', // Jake Auchincloss
  8: '62b453da-3dea-4177-82ba-9e4b78eb7691', // Stephen Lynch
  9: '0d97085c-eca6-4530-9fc7-512ca05487b9', // Bill Keating
};
const INC_NAME: Record<number, string> = {
  1: 'Richard Neal', 2: 'Jim McGovern', 3: 'Lori Trahan', 4: 'Jake Auchincloss',
  8: 'Stephen Lynch', 9: 'Bill Keating',
};

// New challenger/open-seat/declared-independent field (declared-so-far only; MA independent filing
// stays open to 2026-08-25 -- Phase 167 reconciles late filers per Pitfall 3).
const FIELD: Cand[] = [
  // MA-1: Richard Neal renominated
  { cd: 1, name: 'Jeromie Whalen', party: 'D', role: 'D' },
  { cd: 1, name: 'Nadia Milleron', party: 'IND', role: 'IND' },
  // MA-2: Jim McGovern renominated, no new challengers declared so far
  // MA-3: Lori Trahan renominated
  { cd: 3, name: 'Gary J. Grossi', party: 'R', role: 'R' },
  // MA-4: Jake Auchincloss renominated
  { cd: 4, name: 'Jason Poulos', party: 'D', role: 'D' },
  { cd: 4, name: 'Thomas Stalcup', party: 'R', role: 'R' },
  // MA-5: Katherine Clark renominated -- ALREADY WIRED, new challengers only
  { cd: 5, name: 'Tarik Samman', party: 'D', role: 'D' },
  { cd: 5, name: 'Jonathan Paz', party: 'D', role: 'D' },
  // MA-6: Seth Moulton RETIRED -- open seat, full field is new
  { cd: 6, name: 'Bethany Andres-Beck', party: 'D', role: 'D' },
  { cd: 6, name: 'John A. Beccia III', party: 'D', role: 'D' },
  { cd: 6, name: 'Jamie Belsito', party: 'D', role: 'D' },
  { cd: 6, name: 'Dan Koh', party: 'D', role: 'D' },
  { cd: 6, name: 'Mariah Lancaster', party: 'D', role: 'D' },
  { cd: 6, name: 'Tram Nguyen', party: 'D', role: 'D' },
  { cd: 6, name: 'Micah Quinney Jones', party: 'R', role: 'R' },
  // MA-7: Ayanna Pressley renominated -- ALREADY WIRED, no new challengers declared so far
  // MA-8: Stephen Lynch renominated
  { cd: 8, name: 'Patrick Roath', party: 'D', role: 'D' },
  { cd: 8, name: 'Robert Gerald Burke', party: 'R', role: 'R' },
  // MA-9: Bill Keating renominated
  { cd: 9, name: 'Craig Swallow', party: 'D', role: 'D' },
  { cd: 9, name: 'R. Tyler MacAllister', party: 'R', role: 'R' },
];

const SRC_MAJOR = 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections';
const SRC_INDEP = 'Declared independent (news-evidenced, e.g. Milleron MA-1); provisional -- MA independent filing deadline 2026-08-25';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- assign external_ids: MA fips=25; formula -(25*10000 + cd*100 + seq), seq starts at 1 per CD ----
// Live collision re-check (Phase 161-08 Task 1): 0 collisions confirmed against prod for the full
// -250101..-250902 band before authoring (SELECT external_id FROM essentials.politicians WHERE
// external_id BETWEEN -250999 AND -250001).
const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '25' + String(c.cd).padStart(2, '0');
  seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
  const ext = -(25 * 10000 + c.cd * 100 + seqByCd[c.cd]);
  const source = c.role === 'IND' ? SRC_INDEP : SRC_MAJOR;
  rows.push({ ...c, geo, ext, source });
}

// ---- CSV (161-08-ma-reconciliation.csv) ----
mkdirSync('data/seed-ma-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,source';
const csvLines: string[] = [];
for (const r of rows) {
  csvLines.push([r.cd, r.geo, `"${r.name}"`, r.party, r.role, 'NEW', r.ext, false, `"${r.source}"`].join(','));
}
for (const cd of Object.keys(INC_PID).map(Number).sort((a, b) => a - b)) {
  csvLines.push([cd, '25' + String(cd).padStart(2, '0'), `"${INC_NAME[cd]}"`, '', 'INC', 'REUSE-ADD-ROW', '', true, `"${SRC_MAJOR}"`].join(','));
}
csvLines.push([5, '2505', '"Katherine Clark"', '', 'INC', 'ALREADY-WIRED-SKIP', '', true, '"160-race-preexistence-audit.csv row 29"'].join(','));
csvLines.push([7, '2507', '"Ayanna Pressley"', '', 'INC', 'ALREADY-WIRED-SKIP', '', true, '"160-race-preexistence-audit.csv row 31"'].join(','));
csvLines.push([6, '2506', '"Seth Moulton"', '', 'INC', 'RETIRED-NO-ROW', '', false, '"open seat -- retired, no incumbent row"'].join(','));
writeFileSync('data/seed-ma-2026-house/161-08-ma-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration 1202: PROVISIONAL description update + 18 new politicians + race_candidates ----
// (candidates-only; NO essentials.races or essentials.elections INSERT in this file)
const raceIdList = Object.values(EXISTING_RACE_ID).map(id => `'${id}'::uuid`).join(',');

let polInserts = '';
for (const r of rows) {
  const { first, last } = nameParts(r.name);
  polInserts += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}

let rcInserts = '';
// 18 new challengers, guarded on (race_id, politician_id)
for (const r of rows) {
  const { first, last } = nameParts(r.name);
  const raceId = EXISTING_RACE_ID[r.cd];
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '${raceId}'::uuid, p.id, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, false, 'active', ${sqlStr(r.source)}
FROM essentials.politicians p
WHERE p.external_id = ${r.ext}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '${raceId}'::uuid AND rc.politician_id = p.id);
`;
}
// 6 renominated incumbents not yet wired, guarded on (race_id, politician_id) -- reuse pid, no new politician row
for (const cd of Object.keys(INC_PID).map(Number).sort((a, b) => a - b)) {
  const { first, last } = nameParts(INC_NAME[cd]);
  const raceId = EXISTING_RACE_ID[cd];
  const pid = INC_PID[cd];
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '${raceId}'::uuid, p.id, ${sqlStr(INC_NAME[cd])}, ${sqlStr(first)}, ${sqlStr(last)}, true, 'active', ${sqlStr(SRC_MAJOR)}
FROM essentials.politicians p
WHERE p.id = '${pid}'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '${raceId}'::uuid AND rc.politician_id = p.id);
`;
}

const migration = `-- 1202_seed_ma_2026_house_candidates.sql
-- Phase 161-08: MA CANDIDATES-ONLY seed onto the 9 PRE-EXISTING MA U.S. House races
--   (2026 Massachusetts General Election; races NOT created here -- reuse existing_race_id per
--   160-race-preexistence-audit.csv). ${rows.length} new MA politicians + ${rows.length} new active
--   race_candidates + 6 renominated-incumbent race_candidates rows (Neal/McGovern/Trahan/
--   Auchincloss/Lynch/Keating, reusing existing pids -- no new politician row for incumbents).
--   Clark (MA-5, pid 7bf73fb2-1b31-412e-913d-835bfd3e326d) and Pressley (MA-7, pid
--   c61baf45-dc2a-4d78-b4b7-21b1e9d79464) already have race_candidates rows -- NEVER re-inserted;
--   every race_candidates INSERT is guarded by NOT EXISTS on (race_id, politician_id).
--   MA-6 (Seth Moulton, retired) gets NO incumbent row -- open seat, full field is new.
--   Field source: 160-field-table-p161.csv MA rows (MA SoS dem-state-primary-candidates2026.htm),
--   declared-so-far independents only (Milleron MA-1 news-evidenced); MA independent filing stays
--   open to 2026-08-25 -- Phase 167 reconciles late filers.
--   ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party untouched.
BEGIN;

-- Mark the 9 existing MA races PROVISIONAL (description-only; office_id/election_id untouched)
UPDATE essentials.races
SET description = 'PROVISIONAL: pre-primary field, cull >= 2026-09-02'
WHERE id IN (${raceIdList})
  AND (description IS NULL OR description NOT LIKE 'PROVISIONAL:%');

-- ${rows.length} new challenger/open-seat/declared-independent records (idempotent on external_id)
${polInserts}
-- ${rows.length} new active race_candidates + 6 renominated-incumbent race_candidates
--   (NOT EXISTS on (race_id, politician_id) protects Clark/Pressley from duplication)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1202_seed_ma_2026_house_candidates.sql', migration);

// ---- self-check ----
console.log(`New MA politicians: ${rows.length}`);
console.log(`New MA race_candidates: ${rows.length}; reused-incumbent race_candidates: ${Object.keys(INC_PID).length}`);
console.log(`external_id range: ${Math.min(...rows.map(r => r.ext))} .. ${Math.max(...rows.map(r => r.ext))}`);
const dupExt = rows.map(r => r.ext).filter((v, i, a) => a.indexOf(v) !== i);
const dupName = rows.map(r => r.name.toLowerCase()).filter((v, i, a) => a.indexOf(v) !== i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district new-candidate counts:');
for (let cd = 1; cd <= 9; cd++) console.log(`  MA-${cd}: ${rows.filter(r => r.cd === cd).length} new`);
const incTargetsClarkOrPressley = Object.keys(INC_PID).map(Number).some(cd => cd === 5 || cd === 7);
console.log(`Clark/Pressley (MA-5/MA-7) incumbent-reinsert attempted: ${incTargetsClarkOrPressley ? 'FAIL -- must be false' : 'false (correct, already wired)'}`);
console.log('\nWrote: migrations/1202_seed_ma_2026_house_candidates.sql, data/seed-ma-2026-house/161-08-ma-reconciliation.csv');
