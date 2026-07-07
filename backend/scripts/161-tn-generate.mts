import { writeFileSync, mkdirSync } from 'fs';

// ---- TN field (validated against 160-field-table-p161.csv TN rows) ----
// Phase 161-06 Task 1: TN end-to-end seed, the heaviest slice (9 districts, 73 new records).
// TN is late-primary -> seed the FULL qualified field, PROVISIONAL, cull >= 2026-08-07 (day after
// the Aug-6 primary). TN-6 John W. Rose RETIRED and TN-9 Steve Cohen REDISTRICTED (withdrew) ->
// REUSE-NO-ROW; both districts' full qualified field is all-new (no renominated incumbent running).
//
// SEVERE-DISTRICT WITHHOLDING (D-01b / 161-RESEARCH Pitfall 1): per the 161-01 correspondence audit
// (161-tn-correspondence-audit.md, "Severe geo_id list: 4704, 4705, 4706, 4708, 4709"), 5 of TN's 9
// districts shifted so severely under the May 2026 mid-cycle redistricting that showing the new-map
// candidate slate against the OLD-map polygon (essentials.districts/geofence_boundaries, unchanged
// until Phase 164.1) would actively mislead a voter. Severe races are wired to a dedicated, deliberately
// NON-GENERAL, past-dated "Polygon Pending" election row so electionService.ts's
// ELECTION_VISIBILITY_WINDOW evaluates FALSE for them (election_type != 'general' AND election_date >=
// CURRENT_DATE - 30 days) -- NEVER office_id NULL; office_id is ALWAYS the existing old-CD
// NATIONAL_LOWER office (D-01: races wire to the EXISTING old-numbered district rows regardless of
// severity). essentials.offices is NEVER touched (keeps the reps feed on the true old-map incumbent).
type Cand = { cd: number; name: string; party: string; inc?: boolean; vacate?: boolean };

const SEVERE_GEO_IDS = new Set([4704, 4705, 4706, 4708, 4709]);
const INC_EXT: Record<number, number> = {
  1: -47001, 2: -47002, 3: -47003, 4: -47004, 5: -47005, 6: -47006, 7: -47007, 8: -47008, 9: -47009,
};

const FIELD: Cand[] = [
  // TN-1: Diana Harshbarger renominated (NOT-SEVERE)
  { cd: 1, name: 'Diana Harshbarger', party: 'R', inc: true },
  { cd: 1, name: 'Kristi Burke', party: 'D' },
  { cd: 1, name: 'Hernan H. Garcia', party: 'D' },
  { cd: 1, name: 'David S. Kerr, Jr.', party: 'D' },
  { cd: 1, name: 'Joshua Ray Ashburn', party: 'IND' },
  { cd: 1, name: 'Richard G. Baker', party: 'IND' },
  { cd: 1, name: 'Chris Campbell', party: 'IND' },
  { cd: 1, name: 'Billy Cody', party: 'IND' },
  { cd: 1, name: 'Tyler Brice Mitchell McClain', party: 'IND' },
  // TN-2: Tim Burchett renominated (NOT-SEVERE)
  { cd: 2, name: 'Tim Burchett', party: 'R', inc: true },
  { cd: 2, name: 'Michaela Barnett', party: 'D' },
  { cd: 2, name: 'Bruce Fine', party: 'IND' },
  { cd: 2, name: 'Adam Heimerman', party: 'IND' },
  // TN-3: Charles J. "Chuck" Fleischmann renominated (NOT-SEVERE)
  { cd: 3, name: 'Charles J. "Chuck" Fleischmann', party: 'R', inc: true },
  { cd: 3, name: 'Anna Golladay', party: 'D' },
  { cd: 3, name: 'Bryan Martin', party: 'D' },
  { cd: 3, name: 'Dean Arnold', party: 'IND' },
  { cd: 3, name: 'Jean Howard-Hill', party: 'IND' },
  { cd: 3, name: 'Rodney Joe King', party: 'IND' },
  { cd: 3, name: 'Donnie Lynn Ownby', party: 'IND' },
  { cd: 3, name: 'Edward John Roland', party: 'IND' },
  // TN-4: Scott DesJarlais renominated (SEVERE -- gained a Davidson County slice, per 161-01 audit)
  { cd: 4, name: 'Scott DesJarlais', party: 'R', inc: true },
  { cd: 4, name: 'Thomas E. Davis', party: 'R' },
  { cd: 4, name: 'Joshua James', party: 'R' },
  { cd: 4, name: 'Harold "Rocky" Jones', party: 'R' },
  { cd: 4, name: 'Victoria Broderick', party: 'D' },
  { cd: 4, name: 'Mike Cortese', party: 'D' },
  { cd: 4, name: 'Cliff Huffman', party: 'D' },
  { cd: 4, name: 'Tim Lanier', party: 'D' },
  { cd: 4, name: 'Joyce E. Neal', party: 'D' },
  { cd: 4, name: 'Jacob Kristopher Anders', party: 'IND' },
  { cd: 4, name: 'Clay Faircloth', party: 'IND' },
  // TN-5: Andrew Ogles renominated (SEVERE -- loses both old anchors, Davidson + Williamson)
  { cd: 5, name: 'Andrew Ogles', party: 'R', inc: true },
  { cd: 5, name: 'Charlie Hatcher', party: 'R' },
  { cd: 5, name: 'Yolanda Cooper-Sutton', party: 'D' },
  { cd: 5, name: 'DeVante R. Hill', party: 'D' },
  { cd: 5, name: 'Rachel Hurley', party: 'D' },
  { cd: 5, name: 'Carrie Ann Iacomini', party: 'D' },
  { cd: 5, name: 'Chaz Molder', party: 'D' },
  { cd: 5, name: 'James A. Johnson', party: 'IND' },
  { cd: 5, name: 'Micheál (Me-Haul) O\'Leary', party: 'IND' },
  // TN-6: John W. Rose RETIRED -> REUSE-NO-ROW (SEVERE -- gains downtown Nashville, an anchor
  // entirely absent from the old, rural-only TN-6); full qualified field is all-new
  { cd: 6, name: 'John W. Rose', party: 'R', inc: true, vacate: true },
  { cd: 6, name: 'Natisha Brooks', party: 'R' },
  { cd: 6, name: 'Johnny Garrett', party: 'R' },
  { cd: 6, name: 'Jon Henry', party: 'R' },
  { cd: 6, name: 'Van Hilleary', party: 'R' },
  { cd: 6, name: 'Lore Bergman', party: 'D' },
  { cd: 6, name: 'Mike Croley', party: 'D' },
  { cd: 6, name: 'Christopher Martin Finley', party: 'D' },
  { cd: 6, name: 'Miriam Leibowitz', party: 'D' },
  { cd: 6, name: 'Chaney Mosley', party: 'D' },
  { cd: 6, name: 'Christopher B. Monday', party: 'IND' },
  { cd: 6, name: 'Angus Purdy', party: 'IND' },
  // TN-7: Matt Van Epps renominated (NOT-SEVERE -- single-county gain, near-zero swing)
  { cd: 7, name: 'Matt Van Epps', party: 'R', inc: true },
  { cd: 7, name: 'Darden Copeland', party: 'D' },
  { cd: 7, name: 'Vincent Dixie', party: 'D' },
  { cd: 7, name: 'Saletta Holloway', party: 'D' },
  { cd: 7, name: 'Joshua Warren Sales', party: 'D' },
  { cd: 7, name: 'Andrew J. Koontz', party: 'IND' },
  { cd: 7, name: 'Lowell Reynolds', party: 'IND' },
  // TN-8: David Kustoff renominated (SEVERE -- one of the three Memphis 5th/8th/9th-split districts)
  { cd: 8, name: 'David Kustoff', party: 'R', inc: true },
  { cd: 8, name: 'Dewey Gordon Bryan', party: 'D' },
  { cd: 8, name: 'Jordan D. Hinders', party: 'D' },
  { cd: 8, name: 'Heidi Kuhn', party: 'D' },
  { cd: 8, name: 'Leonard Perkins', party: 'D' },
  { cd: 8, name: 'Adam D. Austill', party: 'IND' },
  { cd: 8, name: 'Wendell "Wells" Blankenship', party: 'IND' },
  { cd: 8, name: 'Antonio Futch', party: 'IND' },
  { cd: 8, name: 'Pamela Jeanine "P." Moses', party: 'IND' },
  { cd: 8, name: 'Horace Taylor', party: 'IND' },
  { cd: 8, name: 'Henry J. Ward, III', party: 'IND' },
  // TN-9: Steve Cohen REDISTRICTED (withdrew) -> REUSE-NO-ROW (SEVERE -- dismantled Memphis seat,
  // full partisan flip); full qualified field is all-new
  { cd: 9, name: 'Steve Cohen', party: 'D', inc: true, vacate: true },
  { cd: 9, name: 'Charlotte Bergmann', party: 'R' },
  { cd: 9, name: 'Brent Taylor', party: 'R' },
  { cd: 9, name: 'Jeremy Thompson', party: 'R' },
  { cd: 9, name: 'Todd Warner', party: 'R' },
  { cd: 9, name: 'M. LaTroy A-Williams', party: 'D' },
  { cd: 9, name: 'London Lamar', party: 'D' },
  { cd: 9, name: 'Justin J. Pearson', party: 'D' },
  { cd: 9, name: 'Jim Torino', party: 'D' },
  { cd: 9, name: 'Dennis Clark', party: 'IND' },
  { cd: 9, name: 'Michelle Davis Head', party: 'IND' },
];

const SRC_MAJOR =
  'Wikipedia 2026 TN US House elections (qualified pre-primary field, per TN SOS certified candidate list ' +
  'May 29, 2026), cross-checked Ballotpedia';
const SRC_OTHER =
  'Declared independent (TN SOS certified candidate list / Wikipedia); provisional -- pre-primary field, ' +
  'cull >= 2026-08-07';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) {
  return "'" + s.replace(/'/g, "''") + "'";
}

const GENERAL_ELECTION = 'TN 2026 Statewide General';
const WITHHELD_ELECTION = 'TN 2026 Congressional Redistricting - Polygon Pending';

// ---- assign external_ids per district (seq in FIELD order, incumbents skipped) ----
// TN fips = 47; formula: -(47 * 10000 + cd * 100 + seq), seq starts at 1 per CD.
// Live collision re-check (Phase 161-06 Task 1, prod query 2026-07-03): 0 collisions confirmed
// against prod for the full -470100..-470999 band before authoring.
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
  const geoNum = 4700 + c.cd;
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
    const ext = -(47 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, geoNum, ext, decision: 'NEW', is_incumbent: false, source, severe, election });
  }
}

// ---- CSV (161-06-tn-reconciliation.csv) ----
mkdirSync('data/seed-tn-2026-house', { recursive: true });
const header =
  'cd,geo_id,full_name,party_from_field,decision,assign_external_id,is_incumbent,severity,election,source';
const csvLines = rows.map((r) =>
  [
    r.cd, r.geo, `"${r.name.replace(/"/g, '""')}"`, r.party, r.decision, r.ext, r.is_incumbent,
    r.severe ? 'SEVERE' : 'NOT-SEVERE', `"${r.election}"`, `"${r.source}"`,
  ].join(',')
);
writeFileSync('data/seed-tn-2026-house/161-06-tn-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration 1196: 2 elections + 9 severity-routed races ----
const severeGeoList = [...SEVERE_GEO_IDS].sort().map((g) => String(g));
const nonSevereGeoList = Array.from({ length: 9 }, (_, i) => 4701 + i)
  .filter((g) => !SEVERE_GEO_IDS.has(g))
  .map((g) => String(g));

const m1196 = `-- 1196_seed_tn_2026_house_elections_races.sql
-- Phase 161-06 Task 1: TN 2026 Statewide General election + a dedicated, deliberately-NON-GENERAL
-- "TN 2026 Congressional Redistricting - Polygon Pending" election, + 9 provisional U.S. House races
-- (severity-routed per the 161-01 correspondence audit). Field source: 160-field-table-p161.csv (TN
-- rows), cross-checked Wikipedia "2026 United States House of Representatives elections in Tennessee"
-- (per-district pages) + the TN SOS certified candidate list (May 29, 2026). Provisional pre-primary
-- field (FL-151 D-04 pattern), culled >= 2026-08-07 (day after TN's Aug-6 primary).
-- ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays NULL.
--
-- D-01b / SEVERE-DISTRICT WITHHOLDING (161-RESEARCH Pitfall 1): 5 of TN's 9 districts (geo_id
-- ${severeGeoList.join(', ')}) shifted so severely under the May 2026 mid-cycle redistricting that the
-- new-map candidate slate against the OLD-map polygon (essentials.districts, unchanged until Phase
-- 164.1) would actively mislead a voter. Their races are wired to the withheld "Polygon Pending"
-- election (election_type='special', election_date='2026-05-07', well over 30 days in the past) so
-- electionService.ts's ELECTION_VISIBILITY_WINDOW evaluates FALSE for them across all 3 query paths.
-- office_id is NEVER null for ANY TN race (severe or not) -- it is ALWAYS the district's EXISTING
-- old-CD NATIONAL_LOWER office (D-01). essentials.offices is NEVER touched by this migration -- the
-- reps feed continues to show the true old-map incumbent for every TN district, severe or not.
-- Non-severe districts (geo_id ${nonSevereGeoList.join(', ')}) wire normally to the general election.
BEGIN;

-- 2 elections (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${GENERAL_ELECTION}', '2026-11-03'::date, 'general', 'state', 'TN'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${GENERAL_ELECTION}');

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${WITHHELD_ELECTION}', '2026-05-07'::date, 'special', 'state', 'TN'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${WITHHELD_ELECTION}');

-- 4 NOT-SEVERE races on the EXISTING TN NATIONAL_LOWER US Rep offices, wired to the general election
-- (geo ${nonSevereGeoList.join(', ')})
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-07'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '47'
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
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-07 -- SEEDED-BUT-WITHHELD (D-01b): ' ||
       'new-map field vs. old-map polygon, see 161-tn-correspondence-audit.md'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '47'
  AND d.geo_id = ANY(ARRAY[${severeGeoList.map((g) => sqlStr(g)).join(', ')}])
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = '${WITHHELD_ELECTION}'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
`;
writeFileSync('migrations/1196_seed_tn_2026_house_elections_races.sql', m1196);

// ---- Migration 1197: 73 new politicians + race_candidates ----
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

// race_candidates joins by district geo_id directly (NOT by election name) -- each TN district has
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

const m1197 = `-- 1197_seed_tn_2026_house_candidates.sql
-- Phase 161-06 Task 1: ${newRows.length} new TN politicians + ${activeRows.length} active race_candidates
--   onto the 9 TN 2026 House races (4 general + 5 withheld "Polygon Pending", per 161-01 severity
--   routing). Reuse 7 renominated incumbents by external_id; TN-6 John W. Rose (-47006, RETIRED) and
--   TN-9 Steve Cohen (-47009, REDISTRICTED/withdrew) -> NO active row (open-seat convention, mirrors
--   AZ-1/AZ-5). race_candidates inserts join by district geo_id (not election name), so severe-district
--   candidates are wired identically regardless of the election-visibility substitution -- seeding is
--   complete for severe districts even though the race itself does not surface on /elections.
--   ANTIPARTISAN: party never stored; races untouched. Field: 160-field-table-p161.csv TN rows,
--   cross-checked Wikipedia per-district TN House pages + TN SOS certified candidate list.
BEGIN;

-- ${newRows.length} new challenger/open-seat/indep records (idempotent on external_id)
${polInserts}
-- ${activeRows.length} active race_candidates (7 incumbents reused + ${newRows.length} new; Rose/Cohen excluded)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1197_seed_tn_2026_house_candidates.sql', m1197);

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
for (let cd = 1; cd <= 9; cd++) {
  const geoNum = 4700 + cd;
  const severe = SEVERE_GEO_IDS.has(geoNum);
  const active = activeRows.filter((r) => r.cd === cd).length;
  console.log(`  TN-${cd} (geo ${geoNum}): ${active} active -> ${severe ? 'WITHHELD (Polygon Pending)' : 'GENERAL'}`);
}
console.log(`\nSeverity routing: SEVERE=[${severeGeoList.join(', ')}] -> ${WITHHELD_ELECTION}`);
console.log(`                  NOT-SEVERE=[${nonSevereGeoList.join(', ')}] -> ${GENERAL_ELECTION}`);
console.log('\nWrote: migrations/1196_..., migrations/1197_..., data/seed-tn-2026-house/161-06-tn-reconciliation.csv');
