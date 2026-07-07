import { writeFileSync, mkdirSync } from 'fs';

// ---- MO field (validated against 160-field-table-p162.csv MO rows) ----
// Phase 162-02 Task 2: MO end-to-end seed, this phase's heaviest slice (8 districts, 58 new records).
// MO is late-primary -> seed the FULL qualified field, PROVISIONAL, cull >= 2026-08-05 (day after the
// Aug-4 primary). MO-6 Sam Graves RETIRED (Withdrawn on the official roster) -> REUSE-NO-ROW; MO-6's
// full qualified field is all-new (no renominated incumbent running). MO-1 Cori Bush is a NEW row (no
// prior essentials.politicians record -- she lost the 2024 primary to Bell and was never seeded;
// confirmed by the 162-02 Task 1 lookup, 0 rows), so she takes a normal challenger external_id.
//
// SEVERE-DISTRICT WITHHOLDING (D-01b / 162-RESEARCH Pitfall 1): per the 162-01 correspondence audit
// (162-mo-correspondence-audit.md, "Severe geo_id list: 2902, 2903, 2904, 2905, 2906"), 5 of MO's 8
// districts shifted so severely under the 2025 mid-decade redistricting (KC split three ways among
// MO-4/5/6; St. Charles/Columbia domino recomposing MO-2/3) that showing the new-map candidate slate
// against the OLD-map polygon (essentials.districts/geofence_boundaries, unchanged until Phase 164.1)
// would actively mislead a voter. Severe races are wired to a dedicated, deliberately NON-GENERAL,
// past-dated "Polygon Pending" election row so electionService.ts's ELECTION_VISIBILITY_WINDOW
// evaluates FALSE for them (election_type != 'general' AND election_date >= CURRENT_DATE - 30 days) --
// NEVER office_id NULL; office_id is ALWAYS the existing old-CD NATIONAL_LOWER office (D-01: races wire
// to the EXISTING old-numbered district rows regardless of severity). essentials.offices is NEVER
// touched (keeps the reps feed on the true old-map incumbent).
type Cand = { cd: number; name: string; party: string; inc?: boolean; vacate?: boolean };

const SEVERE_GEO_IDS = new Set([2902, 2903, 2904, 2905, 2906]);
const INC_EXT: Record<number, number> = {
  1: -29001, 2: -29002, 3: -29003, 4: -29004, 5: -29005, 6: -29006, 7: -29007, 8: -29008,
};

const FIELD: Cand[] = [
  // MO-1: Wesley Bell renominated (NOT-SEVERE); Cori Bush is a NEW filer (no prior record)
  { cd: 1, name: 'Wesley Bell', party: 'D', inc: true },
  { cd: 1, name: 'Cori Bush', party: 'D' },
  { cd: 1, name: 'Carl Harris', party: 'D' },
  { cd: 1, name: 'Carl E. Henderson', party: 'D' },
  { cd: 1, name: 'Alissa Murphy', party: 'D' },
  { cd: 1, name: 'Paul Berry', party: 'R' },
  { cd: 1, name: 'Andrew Jones', party: 'R' },
  { cd: 1, name: 'Tom Schmitz', party: 'L' },
  // MO-2: Ann Wagner renominated (SEVERE -- shed all of St. Charles County to MO-3, took 4 redder counties)
  { cd: 2, name: 'Ann Wagner', party: 'R', inc: true },
  { cd: 2, name: 'Elizabeth Sparks-Holmes', party: 'R' },
  { cd: 2, name: 'Peter Pfeifer', party: 'R' },
  { cd: 2, name: 'Ryan Sheridan', party: 'R' },
  { cd: 2, name: 'Brandon Wilkinson', party: 'R' },
  { cd: 2, name: 'Tim Bilash', party: 'D' },
  { cd: 2, name: 'Chuck Summers', party: 'D' },
  { cd: 2, name: 'Nick Vivio', party: 'D' },
  { cd: 2, name: 'Joan VonDras', party: 'D' },
  { cd: 2, name: 'Fred Wellman', party: 'D' },
  { cd: 2, name: 'Brandon Coulter Daugherty', party: 'L' },
  // MO-3: Robert F. Onder, Jr. renominated (SEVERE -- gained all of St. Charles + Columbia, "fairly different")
  { cd: 3, name: 'Robert F. Onder, Jr.', party: 'R', inc: true },
  { cd: 3, name: 'John Fraser', party: 'R' },
  { cd: 3, name: 'Mike Conner', party: 'D' },
  { cd: 3, name: 'Tommy Holstein', party: 'D' },
  { cd: 3, name: 'Bethany Mann', party: 'D' },
  { cd: 3, name: 'Paul Wilson', party: 'D' },
  { cd: 3, name: 'Jim Higgins', party: 'L' },
  // MO-4: Mark Alford renominated (SEVERE -- gained ~25% of Kansas City, a new metro anchor)
  { cd: 4, name: 'Mark Alford', party: 'R', inc: true },
  { cd: 4, name: 'Heather Shelton', party: 'R' },
  { cd: 4, name: 'Scott Vera', party: 'R' },
  { cd: 4, name: 'Jeanette Cass', party: 'D' },
  { cd: 4, name: 'Hartzell Gray', party: 'D' },
  { cd: 4, name: 'Jordan Herrera', party: 'D' },
  { cd: 4, name: 'Randy Miller', party: 'D' },
  { cd: 4, name: 'G Rick', party: 'D' },
  { cd: 4, name: 'Ashleigh Rogers', party: 'D' },
  { cd: 4, name: 'Wayne Russell', party: 'D' },
  { cd: 4, name: 'Thomas Holbrook', party: 'L' },
  // MO-5: Emanuel Cleaver renominated (SEVERE -- Kansas City anchor dismantled, full partisan flip)
  { cd: 5, name: 'Emanuel Cleaver', party: 'D', inc: true },
  { cd: 5, name: 'Micah Beebe', party: 'R' },
  { cd: 5, name: 'Rick Brattin', party: 'R' },
  { cd: 5, name: 'Taylor Burks', party: 'R' },
  { cd: 5, name: 'Brett Hueffmeier', party: 'R' },
  { cd: 5, name: 'Berton A. Knox', party: 'R' },
  { cd: 5, name: 'Brad Patty', party: 'R' },
  { cd: 5, name: 'Randall Langkraehr', party: 'L' },
  // MO-6: Sam Graves RETIRED -> REUSE-NO-ROW (SEVERE -- gained ~35% of Kansas City); field all-new
  { cd: 6, name: 'Sam Graves', party: 'R', inc: true, vacate: true },
  { cd: 6, name: 'James Ingram', party: 'R' },
  { cd: 6, name: 'Cody J. Oshel', party: 'R' },
  { cd: 6, name: 'Nathanael Schultz', party: 'R' },
  { cd: 6, name: 'Chris Stigall', party: 'R' },
  { cd: 6, name: 'Nathan Willett', party: 'R' },
  { cd: 6, name: 'Matt Levine', party: 'D' },
  { cd: 6, name: 'Scot Pondelick', party: 'D' },
  { cd: 6, name: 'Josh Smead', party: 'D' },
  { cd: 6, name: 'Andy Maidment', party: 'L' },
  // MO-7: Eric Burlison renominated (NOT-SEVERE -- Springfield/SW-Missouri anchor unchanged)
  { cd: 7, name: 'Eric Burlison', party: 'R', inc: true },
  { cd: 7, name: 'John Casey', party: 'R' },
  { cd: 7, name: 'Grayson Hunt', party: 'R' },
  { cd: 7, name: 'Missi Hesketh', party: 'D' },
  { cd: 7, name: 'Kevin Craig', party: 'L' },
  // MO-8: Jason Smith renominated (NOT-SEVERE -- Bootheel/SE-Missouri anchor unchanged)
  { cd: 8, name: 'Jason Smith', party: 'R', inc: true },
  { cd: 8, name: 'Gordon Heslop', party: 'R' },
  { cd: 8, name: 'Frank Barnitz', party: 'D' },
  { cd: 8, name: 'Clayton Harbison', party: 'D' },
  { cd: 8, name: 'Christopher Reichard', party: 'D' },
  { cd: 8, name: 'Rebecca Sharpe Lombard', party: 'L' },
];

const SRC_MAJOR =
  'Wikipedia 2026 MO US House elections (qualified pre-primary field, per MO SOS candidate filing list; ' +
  'MO SOS ASPX unfetchable -> Wikipedia raw wikitext cites the SOS list), cross-checked Ballotpedia; ' +
  'provisional -- pre-primary field, cull >= 2026-08-05';
const SRC_OTHER =
  'Declared minor-party candidate (Wikipedia 2026 MO US House / MO SOS candidate filing list); ' +
  'provisional -- pre-primary field, cull >= 2026-08-05';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) {
  return "'" + s.replace(/'/g, "''") + "'";
}

const GENERAL_ELECTION = 'MO 2026 Statewide General';
const WITHHELD_ELECTION = 'MO 2026 Congressional Redistricting - Polygon Pending';

// ---- assign external_ids per district (seq in FIELD order, incumbents skipped) ----
// MO fips = 29; formula: -(29 * 10000 + cd * 100 + seq), seq starts at 1 per CD.
// Live collision re-check (Phase 162-02 Task 1, prod query 2026-07-04): 0 collisions confirmed
// against prod for the full -290101..-290899 band before authoring.
const seqByCd: Record<number, number> = {};
type Row = Cand & {
  geo: string;
  geoNum: number;
  ext: number;
  decision: string;
  is_incumbent: boolean;
  source: string;
  severe: boolean;
  election: string;
};
const rows: Row[] = [];
for (const c of FIELD) {
  const geoNum = 2900 + c.cd;
  const geo = String(geoNum);
  const severe = SEVERE_GEO_IDS.has(geoNum);
  const election = severe ? WITHHELD_ELECTION : GENERAL_ELECTION;
  const source = c.party === 'D' || c.party === 'R' ? SRC_MAJOR : SRC_OTHER;
  if (c.inc) {
    rows.push({
      ...c, geo, geoNum, ext: INC_EXT[c.cd], decision: c.vacate ? 'REUSE-NO-ROW' : 'REUSE',
      is_incumbent: true, source, severe, election,
    });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(29 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, geoNum, ext, decision: 'NEW', is_incumbent: false, source, severe, election });
  }
}

// ---- CSV (162-02-mo-reconciliation.csv) ----
mkdirSync('data/seed-mo-2026-house', { recursive: true });
const header =
  'cd,geo_id,full_name,party_from_field,decision,assign_external_id,is_incumbent,severity,election,source';
const csvLines = rows.map((r) =>
  [
    r.cd, r.geo, `"${r.name.replace(/"/g, '""')}"`, r.party, r.decision, r.ext, r.is_incumbent,
    r.severe ? 'SEVERE' : 'NOT-SEVERE', `"${r.election}"`, `"${r.source}"`,
  ].join(',')
);
writeFileSync('data/seed-mo-2026-house/162-02-mo-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration 1206: 2 elections + 8 severity-routed races ----
const severeGeoList = [...SEVERE_GEO_IDS].sort().map((g) => String(g));
const nonSevereGeoList = Array.from({ length: 8 }, (_, i) => 2901 + i)
  .filter((g) => !SEVERE_GEO_IDS.has(g))
  .map((g) => String(g));

const m1206 = `-- 1206_seed_mo_2026_house_elections_races.sql
-- Phase 162-02 Task 2: MO 2026 Statewide General election + a dedicated, deliberately-NON-GENERAL
-- "MO 2026 Congressional Redistricting - Polygon Pending" election, + 8 provisional U.S. House races
-- (severity-routed per the 162-01 correspondence audit). Field source: 160-field-table-p162.csv (MO
-- rows), cross-checked Wikipedia "2026 United States House of Representatives elections in Missouri"
-- (raw wikitext cites the MO SOS candidate filing list; the MO SOS ASPX pages are unfetchable).
-- Provisional pre-primary field (FL-151 D-04 pattern), culled >= 2026-08-05 (day after MO's Aug-4 primary).
-- ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays NULL.
--
-- D-01b / SEVERE-DISTRICT WITHHOLDING (162-RESEARCH Pitfall 1): 5 of MO's 8 districts (geo_id
-- ${severeGeoList.join(', ')}) shifted so severely under the 2025 mid-decade redistricting that the
-- new-map candidate slate against the OLD-map polygon (essentials.districts, unchanged until Phase
-- 164.1) would actively mislead a voter. Their races are wired to the withheld "Polygon Pending"
-- election (election_type='special', election_date='2026-03-24' = the MO Supreme Court 4-3 upholding
-- date, well over 30 days in the past) so electionService.ts's ELECTION_VISIBILITY_WINDOW evaluates
-- FALSE for them across all 3 query paths.
-- office_id is NEVER null for ANY MO race (severe or not) -- it is ALWAYS the district's EXISTING
-- old-CD NATIONAL_LOWER office (D-01). essentials.offices is NEVER touched by this migration -- the
-- reps feed continues to show the true old-map incumbent for every MO district, severe or not.
-- Non-severe districts (geo_id ${nonSevereGeoList.join(', ')}) wire normally to the general election.
-- NOTE (162-01 freshness flag): MO's general-election map is unsettled pending the veto referendum
-- (SoS signature certification ~2026-07-27); if it freezes/reverts, Phase 167 re-pulls MO. The D-01b
-- withholding hedges correctly either way.
BEGIN;

-- 2 elections (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${GENERAL_ELECTION}', '2026-11-03'::date, 'general', 'state', 'MO'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${GENERAL_ELECTION}');

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${WITHHELD_ELECTION}', '2026-03-24'::date, 'special', 'state', 'MO'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${WITHHELD_ELECTION}');

-- 3 NOT-SEVERE races on the EXISTING MO NATIONAL_LOWER US Rep offices, wired to the general election
-- (geo ${nonSevereGeoList.join(', ')})
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '29'
  AND d.geo_id = ANY(ARRAY[${nonSevereGeoList.map((g) => sqlStr(g)).join(', ')}])
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = '${GENERAL_ELECTION}'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

-- 5 SEVERE races -- office_id STILL the normal old-CD office (NEVER null); election_id points at the
-- withheld "Polygon Pending" election so the race never surfaces on /elections (D-01b)
-- (geo ${severeGeoList.join(', ')})
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05 -- SEEDED-BUT-WITHHELD (D-01b): ' ||
       'new-map field vs. old-map polygon, see 162-mo-correspondence-audit.md'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '29'
  AND d.geo_id = ANY(ARRAY[${severeGeoList.map((g) => sqlStr(g)).join(', ')}])
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = '${WITHHELD_ELECTION}'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
`;
writeFileSync('migrations/1206_seed_mo_2026_house_elections_races.sql', m1206);

// ---- Migration 1207: 58 new politicians + race_candidates ----
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

// race_candidates joins by district geo_id directly (NOT by election name) -- each MO district has
// exactly one race regardless of which election it's wired to (general vs withheld), so this single
// block correctly reaches both severe and non-severe races without duplicating the insert logic.
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

const m1207 = `-- 1207_seed_mo_2026_house_candidates.sql
-- Phase 162-02 Task 2: ${newRows.length} new MO politicians + ${activeRows.length} active race_candidates
--   onto the 8 MO 2026 House races (3 general + 5 withheld "Polygon Pending", per 162-01 severity
--   routing). Reuse 7 renominated incumbents by external_id; MO-6 Sam Graves (-29006, RETIRED) -> NO
--   active row (open-seat convention, mirrors TN-6/TN-9 and AZ-1/AZ-5). MO-1 Cori Bush is a NEW record
--   (no prior essentials.politicians row -- 162-02 Task 1 lookup returned 0). race_candidates inserts
--   join by district geo_id (not election name), so severe-district candidates are wired identically
--   regardless of the election-visibility substitution -- seeding is complete for severe districts even
--   though the race itself does not surface on /elections.
--   ANTIPARTISAN: party never stored; races untouched. Field: 160-field-table-p162.csv MO rows,
--   cross-checked Wikipedia "2026 US House elections in Missouri" (cites the MO SOS candidate filing list).
BEGIN;

-- ${newRows.length} new challenger/open-seat records (idempotent on external_id)
${polInserts}
-- ${activeRows.length} active race_candidates (7 incumbents reused + ${newRows.length} new; Graves excluded)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1207_seed_mo_2026_house_candidates.sql', m1207);

console.log(
  `CSV rows: ${rows.length} (active=${activeRows.length}, REUSE-NO-ROW=${
    rows.filter((r) => r.decision === 'REUSE-NO-ROW').length
  })`
);
console.log(`NEW records: ${newRows.length}`);
console.log(`external_id range: ${Math.min(...newRows.map((r) => r.ext))} .. ${Math.max(...newRows.map((r) => r.ext))}`);
const dupExt = newRows.map((r) => r.ext).filter((v, i, a) => a.indexOf(v) !== i);
const dupName = rows.map((r) => r.name.toLowerCase()).filter((v, i, a) => a.indexOf(v) !== i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district active counts (severity routing summary):');
for (let cd = 1; cd <= 8; cd++) {
  const geoNum = 2900 + cd;
  const severe = SEVERE_GEO_IDS.has(geoNum);
  const active = activeRows.filter((r) => r.cd === cd).length;
  console.log(`  MO-${cd} (geo ${geoNum}): ${active} active -> ${severe ? 'WITHHELD (Polygon Pending)' : 'GENERAL'}`);
}
console.log(`\nSeverity routing: SEVERE=[${severeGeoList.join(', ')}] -> ${WITHHELD_ELECTION}`);
console.log(`                  NOT-SEVERE=[${nonSevereGeoList.join(', ')}] -> ${GENERAL_ELECTION}`);
console.log('\nWrote: migrations/1206_..., migrations/1207_..., data/seed-mo-2026-house/162-02-mo-reconciliation.csv');
