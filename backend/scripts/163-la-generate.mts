import { writeFileSync, mkdirSync } from 'fs';

// ---- LA field (validated against 160-field-table-p163.csv LA rows; source = Wikipedia
//      2026 US House elections in Louisiana) ----
// Phase 163-06 Task 2: LA end-to-end seed (6 districts, 27 new records), JUNGLE/OPEN-PRIMARY model.
//   LA Critical Question 2: each district = EXACTLY ONE race with primary_party=NULL, and ALL qualified
//   candidates (incumbent + every party) go on that single race (clone the CA convention in
//   ingest-ca-sos-2026-challengers.ts / seed-la-citywide-races-2026.sql; the schema's
//   idx_races_election_position_no_party unique index supports this exact shape). Do NOT create
//   per-party primary races. Do NOT create any December-2026 runoff election/race (Pitfall 2 — which
//   districts need a Dec-12 runoff is unknowable until Nov-3 results; deferred to Phase 167).
//   All 6 districts are late-primary: qualifying closes 2026-08-07, so the field is declared-so-far
//   and must be re-pulled in Phase 167. Incumbents RUN ON the jungle ballot (is_incumbent=true).
//   LA-5 Julia Letlow RETIRED (running for Senate) -> REUSE-NO-ROW; open seat, 13 declared candidates.
//
// SEVERE-DISTRICT WITHHOLDING (D-01b / 163-01 LA correspondence audit): the audit scored
//   "Severe geo_id list: 2202, 2206" -- LA-6 (dissolved CD-6 corridor) and LA-2 (gains a new Baton
//   Rouge anchor, loses Assumption Parish; evidence overturned RESEARCH's prediction). Their races are
//   wired to a dedicated NON-GENERAL, past-dated "Polygon Pending" election so electionService.ts's
//   ELECTION_VISIBILITY_WINDOW evaluates FALSE. office_id is NEVER null; essentials.offices is NEVER
//   touched. 164.1 un-withholds LA-2/LA-6 on polygon refresh.
type Cand = { cd: number; name: string; party: string; inc?: boolean; vacate?: boolean };

const SEVERE_GEO_IDS = new Set([2202, 2206]);   // from 163-la-correspondence-audit.md "Severe geo_id list: 2202, 2206"
const LATE_PRIMARY_GEO_IDS = new Set([2201, 2202, 2203, 2204, 2205, 2206]); // all 6 (jungle, qualifying closes Aug-7)
const INC_EXT: Record<number, number> = { 1: -22001, 2: -22002, 3: -22003, 4: -22004, 5: -22005, 6: -22006 };

const FIELD: Cand[] = [
  // LA-1 (2201): Steve Scalise renominated (R, reuse -22001), on the jungle ballot; 2 new
  { cd: 1, name: 'Steve Scalise', party: 'R', inc: true },
  { cd: 1, name: 'Randall Arrington', party: 'R' },
  { cd: 1, name: 'Jim Long', party: 'D' },
  // LA-2 (2202): Troy Carter renominated (D, reuse -22002); SEVERE; 1 new
  { cd: 2, name: 'Troy Carter', party: 'D', inc: true },
  { cd: 2, name: 'Renada Collins', party: 'D' },
  // LA-3 (2203): Clay Higgins renominated (R, reuse -22003); 3 new
  { cd: 3, name: 'Clay Higgins', party: 'R', inc: true },
  { cd: 3, name: 'John Day', party: 'D' },
  { cd: 3, name: 'Tia LeBrun', party: 'D' },
  { cd: 3, name: 'Caleb Walker', party: 'D' },
  // LA-4 (2204): Mike Johnson renominated (R, reuse -22004); 4 new
  { cd: 4, name: 'Mike Johnson', party: 'R', inc: true },
  { cd: 4, name: 'Josh Morott', party: 'R' },
  { cd: 4, name: 'Mike Nichols', party: 'R' },
  { cd: 4, name: 'Conrad Cable', party: 'D' },
  { cd: 4, name: 'Matt Gromlich', party: 'D' },
  // LA-5 (2205): Julia Letlow RETIRED (Senate) -> REUSE-NO-ROW; open seat, 13 declared
  { cd: 5, name: 'Julia Letlow', party: 'R', inc: true, vacate: true },
  { cd: 5, name: 'Misti Cordell', party: 'R' },
  { cd: 5, name: 'Michael Echols', party: 'R' },
  { cd: 5, name: 'Rick Edmonds', party: 'R' },
  { cd: 5, name: 'Austin Magee', party: 'R' },
  { cd: 5, name: 'Michael Mebruer', party: 'R' },
  { cd: 5, name: 'Blake Miguez', party: 'R' },
  { cd: 5, name: 'Sammy Wyatt', party: 'R' },
  { cd: 5, name: 'Gabe Firment', party: 'R' },
  { cd: 5, name: 'Jessee Fleenor', party: 'D' },
  { cd: 5, name: 'Larry Foy', party: 'D' },
  { cd: 5, name: 'Lindsay Garcia', party: 'D' },
  { cd: 5, name: 'Dan McKay', party: 'D' },
  { cd: 5, name: 'Tania Nyman', party: 'D' },
  // LA-6 (2206): Cleo Fields renominated (D, reuse -22006); SEVERE; 4 new
  { cd: 6, name: 'Cleo Fields', party: 'D', inc: true },
  { cd: 6, name: 'Monique Appeaning', party: 'R' },
  { cd: 6, name: 'Larry Davis', party: 'R' },
  { cd: 6, name: 'Chris Johnson', party: 'R' },
  { cd: 6, name: 'Peter Williams', party: 'R' },
];

const SRC_MAJOR =
  '160-field-table-p163.csv (LA rows), sourced from Wikipedia 2026 US House elections in Louisiana; ' +
  'LA jungle/open primary (all parties on one 2026-11-03 ballot); provisional declared-so-far field, ' +
  're-pull after 2026-08-07 qualifying close';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

const GENERAL_ELECTION = 'LA 2026 Statewide General';
const WITHHELD_ELECTION = 'LA 2026 Congressional Redistricting - Polygon Pending';
// SB121 (Act 2) signing, 2026-05-29 -- validated >30 days before execution (2026-07-05) so
// ELECTION_VISIBILITY_WINDOW (special_visible) evaluates FALSE.
const WITHHELD_DATE = '2026-05-29';

// ---- assign external_ids per district (seq in FIELD order, incumbents skipped) ----
// LA fips = 22; formula: -(22 * 10000 + cd * 100 + seq), seq starts at 1 per CD.
// Live collision re-check (163-06 Task 1, prod 2026-07-05): 0 collisions in -220699..-220101.
// Incumbents reuse -22001..-22006.
const seqByCd: Record<number, number> = {};
type Row = Cand & {
  geo: string; geoNum: number; ext: number; decision: string; is_incumbent: boolean;
  source: string; severe: boolean; late: boolean; election: string;
};
const rows: Row[] = [];
for (const c of FIELD) {
  const geoNum = 2200 + c.cd;
  const geo = String(geoNum);
  const severe = SEVERE_GEO_IDS.has(geoNum);
  const late = LATE_PRIMARY_GEO_IDS.has(geoNum);
  const election = severe ? WITHHELD_ELECTION : GENERAL_ELECTION;
  const source = SRC_MAJOR;
  if (c.inc) {
    rows.push({
      ...c, geo, geoNum, ext: INC_EXT[c.cd], decision: c.vacate ? 'REUSE-NO-ROW' : 'REUSE',
      is_incumbent: true, source, severe, late, election,
    });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(22 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, geoNum, ext, decision: 'NEW', is_incumbent: false, source, severe, late, election });
  }
}

// ---- CSV (163-06-la-reconciliation.csv) ----
mkdirSync('data/seed-la-2026-house', { recursive: true });
const notes = '# LA jungle/open-primary model: 1 race per district, primary_party=NULL, all parties + incumbent on it. ' +
  'No per-party races; NO Dec-2026 runoff (deferred to Phase 167). Severe (withheld) geo_ids per ' +
  '163-la-correspondence-audit.md: 2202 (LA-2), 2206 (LA-6). All 6 late-primary (qualifying closes ' +
  '2026-08-07 -> declared-so-far, Phase-167 re-pull). Withheld election date 2026-05-29 (SB121/Act 2 ' +
  'signing), validated invisible (>30d past). SB121 confirmed operative by 163-01 audit re-verify (2026-07-05).';
const header = 'cd,geo_id,full_name,party_from_field,decision,assign_external_id,is_incumbent,primary_timing,severity,election,source';
const csvLines = rows.map((r) =>
  [
    r.cd, r.geo, `"${r.name.replace(/"/g, '""')}"`, r.party, r.decision, r.ext, r.is_incumbent,
    r.late ? 'LATE-PRIMARY' : 'DECIDED', r.severe ? 'SEVERE' : 'NOT-SEVERE', `"${r.election}"`, `"${r.source}"`,
  ].join(',')
);
writeFileSync('data/seed-la-2026-house/163-06-la-reconciliation.csv', [notes, header, ...csvLines].join('\n') + '\n');

// ---- Migration 1228: 2 elections + 6 jungle races (one per district, primary_party NULL) ----
const RACE_DESC = 'PROVISIONAL: declared-so-far field, re-pull after 2026-08-07 qualifying close';
const WITHHELD_NOTE = ' -- SEEDED-BUT-WITHHELD (D-01b): new-map field vs. old-map polygon, see 163-la-correspondence-audit.md';

let raceInserts = '';
for (let cd = 1; cd <= 6; cd++) {
  const geoNum = 2200 + cd;
  const geo = String(geoNum);
  const severe = SEVERE_GEO_IDS.has(geoNum);
  const election = severe ? WITHHELD_ELECTION : GENERAL_ELECTION;
  const desc = RACE_DESC + (severe ? WITHHELD_NOTE : '');
  raceInserts += `INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, ${sqlStr(desc)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = ${sqlStr(election)}
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
`;
}

const m1228 = `-- 1228_seed_la_2026_house_elections_races.sql
-- Phase 163-06 Task 2: LA 2026 Statewide General election + a dedicated NON-GENERAL
-- "LA 2026 Congressional Redistricting - Polygon Pending" election, + 6 JUNGLE U.S. House races.
-- JUNGLE MODEL: each district = EXACTLY ONE race with primary_party=NULL; ALL qualified candidates
-- (incumbent + every party) are wired to that single race (CA convention). NO per-party primary races.
-- NO December-2026 runoff election/race (deferred to Phase 167 -- unknowable until Nov-3 results).
-- Field source: 160-field-table-p163.csv (LA rows), Wikipedia 2026 US House elections in Louisiana.
-- ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays NULL.
-- All 6 districts late-primary (qualifying closes 2026-08-07) -> PROVISIONAL declared-so-far.
--
-- D-01b SEVERE-DISTRICT WITHHOLDING: per 163-la-correspondence-audit.md ("Severe geo_id list: 2202,
-- 2206"), LA-2 (2202) and LA-6 (2206) shifted severely under SB121/Act 2 (dissolved CD-6); their races
-- are wired to the withheld "Polygon Pending" election (election_type='special', election_date=
-- '${WITHHELD_DATE}' = the SB121 signing date, >30 days past at execution) so electionService.ts's
-- ELECTION_VISIBILITY_WINDOW evaluates FALSE. office_id is NEVER null for ANY LA race -- it is ALWAYS
-- the district's EXISTING NATIONAL_LOWER office (D-01). essentials.offices is NEVER touched. 164.1
-- un-withholds LA-2/LA-6 on polygon refresh.
BEGIN;

-- 2 elections (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${GENERAL_ELECTION}', '2026-11-03'::date, 'general', 'state', 'LA'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${GENERAL_ELECTION}');

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${WITHHELD_ELECTION}', '${WITHHELD_DATE}'::date, 'special', 'state', 'LA'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${WITHHELD_ELECTION}');

-- 6 jungle races (one per district, primary_party NULL; 4 general + 2 withheld LA-2/LA-6)
${raceInserts}
COMMIT;
`;
writeFileSync('migrations/1228_seed_la_2026_house_elections_races.sql', m1228);

// ---- Migration 1229: 27 new politicians + race_candidates ----
const newRows = rows.filter((r) => r.decision === 'NEW');
const activeRows = rows.filter((r) => r.decision === 'NEW' || r.decision === 'REUSE'); // excludes REUSE-NO-ROW

let polInserts = '';
for (const r of newRows) {
  const { first, last } = nameParts(r.name);
  polInserts += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}

// race_candidates joins by district geo_id -- each LA district has exactly one jungle race regardless
// of which election it is wired to, so this single block reaches severe + non-severe uniformly.
let rcInserts = '';
for (const r of activeRows) {
  const { first, last } = nameParts(r.name);
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, ${r.is_incumbent}, 'active', ${sqlStr(r.source)}
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = ${r.ext}
WHERE d.geo_id = ${sqlStr(r.geo)} AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}

const m1229 = `-- 1229_seed_la_2026_house_candidates.sql
-- Phase 163-06 Task 2: ${newRows.length} new LA politicians + ${activeRows.length} active race_candidates
--   onto the 6 LA 2026 jungle races (4 general + 2 withheld "Polygon Pending" LA-2/LA-6, per 163-01
--   routing). Reuse 5 renominated incumbents by external_id ON the jungle ballot (is_incumbent=true);
--   LA-5 Julia Letlow (-22005, retired->Senate) -> NO row (open seat, 13 declared). race_candidates
--   join by district geo_id, so severe-district candidates are wired identically regardless of the
--   election-visibility substitution. ANTIPARTISAN: party never stored; offices untouched.
--   Field: 160-field-table-p163.csv LA rows, Wikipedia 2026 US House elections in Louisiana.
BEGIN;

-- ${newRows.length} new challenger/open-seat records (idempotent on external_id)
${polInserts}
-- ${activeRows.length} active race_candidates (5 incumbents reused on jungle ballot + ${newRows.length} new; Letlow excluded)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1229_seed_la_2026_house_candidates.sql', m1229);

console.log(`CSV rows: ${rows.length} (active=${activeRows.length}, REUSE-NO-ROW=${rows.filter((r) => r.decision === 'REUSE-NO-ROW').length})`);
console.log(`NEW records: ${newRows.length}`);
console.log(`external_id range: ${Math.min(...newRows.map((r) => r.ext))} .. ${Math.max(...newRows.map((r) => r.ext))}`);
const dupExt = newRows.map((r) => r.ext).filter((v, i, a) => a.indexOf(v) !== i);
const dupName = rows.map((r) => r.name.toLowerCase()).filter((v, i, a) => a.indexOf(v) !== i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district active counts (severity routing):');
for (let cd = 1; cd <= 6; cd++) {
  const geoNum = 2200 + cd;
  const severe = SEVERE_GEO_IDS.has(geoNum);
  const active = activeRows.filter((r) => r.cd === cd).length;
  const nu = newRows.filter((r) => r.cd === cd).length;
  console.log(`  LA-${cd} (geo ${geoNum}): ${active} active (${nu} new) -> ${severe ? 'WITHHELD' : 'GENERAL'} / PROVISIONAL`);
}
console.log(`\nSeverity routing: SEVERE=[2202, 2206] -> ${WITHHELD_ELECTION}`);
console.log('\nWrote: migrations/1228_..., migrations/1229_..., data/seed-la-2026-house/163-06-la-reconciliation.csv');
