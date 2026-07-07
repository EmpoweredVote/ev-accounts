import { writeFileSync, mkdirSync } from 'fs';

// ---- AL field (validated against 160-field-table-p163.csv AL rows; source = Wikipedia
//      2026 US House elections in Alabama, per-district sections) ----
// Phase 163-04 Task 2: AL end-to-end seed (7 districts, 21 new records). AL is a SPLIT state:
//   - AL-3/4/5 (0103/0104/0105): primaries DECIDED -> plain general description (NO PROVISIONAL).
//   - AL-1/2/6/7 (0101/0102/0106/0107): LATE-primary (Aug-11 SCOTUS-ordered special primary) ->
//     seed the full qualified field, PROVISIONAL, cull >= 2026-08-12.
//   Primary-timing (PROVISIONAL prefix) and severity (withheld election) are INDEPENDENT axes.
//
// SEVERE-DISTRICT WITHHOLDING (D-01b / 163-01 AL correspondence audit): the audit scored
//   "Severe geo_id list: 0102" -- ONLY AL-2 shifted enough (loses its entire majority-Black
//   Mobile-area constituency; BVAP 48.7%->39.9%) that showing the new-map slate against the OLD-map
//   polygon (essentials.districts, unchanged until Phase 164.1) would mislead a voter. AL-2's race is
//   wired to a dedicated NON-GENERAL, past-dated "Polygon Pending" election so electionService.ts's
//   ELECTION_VISIBILITY_WINDOW evaluates FALSE for it. AL-1/6/7 required the Aug-11 special primary
//   (a procedural trigger -- any line move forces a redo) but scored NOT-SEVERE (anchors preserved),
//   so they surface normally (PROVISIONAL general). office_id is NEVER null; essentials.offices is
//   NEVER touched (keeps the reps feed on the true old-map incumbent).
type Cand = { cd: number; name: string; party: string; inc?: boolean; vacate?: boolean };

const SEVERE_GEO_IDS = new Set([102]);          // from 163-al-correspondence-audit.md "Severe geo_id list: 0102"
const LATE_PRIMARY_GEO_IDS = new Set([101, 102, 106, 107]); // AL-1/2/6/7 Aug-11 special primary
const INC_EXT: Record<number, number> = { 1: -1001, 2: -1002, 3: -1003, 4: -1004, 5: -1005, 6: -1006, 7: -1007 };

const FIELD: Cand[] = [
  // AL-1 (0101): Barry Moore RETIRED (running for Senate) -> REUSE-NO-ROW; open seat, 5 new (late-primary)
  { cd: 1, name: 'Barry Moore', party: 'R', inc: true, vacate: true },
  { cd: 1, name: 'Lucas Burger', party: 'R' },
  { cd: 1, name: 'Jerry Carl', party: 'R' },
  { cd: 1, name: 'John Mills', party: 'R' },
  { cd: 1, name: 'Austin Sidwell', party: 'R' },
  { cd: 1, name: 'Clyde Jones', party: 'D' },
  // AL-2 (0102): Shomari Figures renominated (D, reuse -1002); SEVERE + late-primary; 6 new R (special primary)
  { cd: 2, name: 'Shomari Figures', party: 'D', inc: true },
  { cd: 2, name: 'Hampton Harris', party: 'R' },
  { cd: 2, name: 'Christian Horn', party: 'R' },
  { cd: 2, name: 'Rhett Marques', party: 'R' },
  { cd: 2, name: 'David Matthews', party: 'R' },
  { cd: 2, name: 'Joshua McKee', party: 'R' },
  { cd: 2, name: 'James Richardson', party: 'R' },
  // AL-3 (0103): Mike Rogers renominated (decided)
  { cd: 3, name: 'Mike Rogers', party: 'R', inc: true },
  { cd: 3, name: 'Lee McInnis', party: 'D' },
  // AL-4 (0104): Robert Aderholt renominated (decided)
  { cd: 4, name: 'Robert Aderholt', party: 'R', inc: true },
  { cd: 4, name: 'Amanda Pusczek', party: 'D' },
  // AL-5 (0105): Dale Strong renominated (decided)
  { cd: 5, name: 'Dale Strong', party: 'R', inc: true },
  { cd: 5, name: 'Andrew Sneed', party: 'D' },
  // AL-6 (0106): Gary Palmer renominated (late-primary); 5 new
  { cd: 6, name: 'Gary Palmer', party: 'R', inc: true },
  { cd: 6, name: 'Case Dixon', party: 'R' },
  { cd: 6, name: 'Jacob Bouma-Sims', party: 'D' },
  { cd: 6, name: 'Ashtyn Kennedy', party: 'D' },
  { cd: 6, name: 'Maurice Mercer', party: 'D' },
  { cd: 6, name: 'Keith Pilkington', party: 'D' },
  // AL-7 (0107): Terri Sewell renominated (late-primary); 2 new
  { cd: 7, name: 'Terri Sewell', party: 'D', inc: true },
  { cd: 7, name: 'Ammie Akin', party: 'R' },
  { cd: 7, name: 'David Perry', party: 'R' },
];

const SRC_MAJOR =
  '160-field-table-p163.csv (AL rows), sourced from Wikipedia 2026 US House elections in Alabama; ' +
  'AL-1/2/6/7 provisional pre-primary field (Aug-11 SCOTUS-ordered special primary), cull >= 2026-08-12; ' +
  'AL-3/4/5 decided general field';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

const GENERAL_ELECTION = 'AL 2026 Statewide General';
const WITHHELD_ELECTION = 'AL 2026 Congressional Redistricting - Polygon Pending';
// SCOTUS stay reinstating the 2023 map, 2026-06-02 -- validated >30 days before execution (2026-07-05)
// so ELECTION_VISIBILITY_WINDOW (special_visible) evaluates FALSE.
const WITHHELD_DATE = '2026-06-02';

// ---- assign external_ids per district (seq in FIELD order, incumbents skipped) ----
// AL fips = 01; formula: -(1 * 10000 + cd * 100 + seq), seq starts at 1 per CD.
// Live collision re-check (163-04 Task 1, prod 2026-07-05): 0 collisions in -10799..-10101;
// -10000 Sarah McBride (DE) is out-of-band and untouched. Incumbents reuse -1001..-1007.
const seqByCd: Record<number, number> = {};
type Row = Cand & {
  geo: string; geoNum: number; ext: number; decision: string; is_incumbent: boolean;
  source: string; severe: boolean; late: boolean; election: string;
};
const rows: Row[] = [];
for (const c of FIELD) {
  const geoNum = 100 + c.cd;
  const geo = String(geoNum).padStart(4, '0');
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
    const ext = -(1 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, geoNum, ext, decision: 'NEW', is_incumbent: false, source, severe, late, election });
  }
}

// ---- CSV (163-04-al-reconciliation.csv) ----
mkdirSync('data/seed-al-2026-house', { recursive: true });
const notes = '# AL split state. Severe (withheld) geo_ids per 163-al-correspondence-audit.md: 0102 (AL-2 only). ' +
  'Late-primary (PROVISIONAL) districts: AL-1/2/6/7 (Aug-11 special primary, cull >= 2026-08-12). ' +
  'Withheld election date 2026-06-02 (SCOTUS stay), validated invisible (>30d past) at execution 2026-07-05. ' +
  'SCOTUS stay confirmed operative by 163-01 audit re-verification (2026-07-05).';
const header = 'cd,geo_id,full_name,party_from_field,decision,assign_external_id,is_incumbent,primary_timing,severity,election,source';
const csvLines = rows.map((r) =>
  [
    r.cd, r.geo, `"${r.name.replace(/"/g, '""')}"`, r.party, r.decision, r.ext, r.is_incumbent,
    r.late ? 'LATE-PRIMARY' : 'DECIDED', r.severe ? 'SEVERE' : 'NOT-SEVERE', `"${r.election}"`, `"${r.source}"`,
  ].join(',')
);
writeFileSync('data/seed-al-2026-house/163-04-al-reconciliation.csv', [notes, header, ...csvLines].join('\n') + '\n');

// ---- Migration 1226: 2 elections + 7 severity-routed races (per-district descriptions) ----
function raceDesc(late: boolean, severe: boolean): string {
  const base = late
    ? 'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-12'
    : 'Confirmed nominees (AL primary decided)';
  const withheldNote = severe
    ? ' -- SEEDED-BUT-WITHHELD (D-01b): new-map field vs. old-map polygon, see 163-al-correspondence-audit.md'
    : '';
  return base + withheldNote;
}

// one race INSERT per district (7), each explicitly naming its election + geo + description,
// so the mixed (late-primary x severity) matrix is expressed without branching in SQL.
let raceInserts = '';
for (let cd = 1; cd <= 7; cd++) {
  const geoNum = 100 + cd;
  const geo = String(geoNum).padStart(4, '0');
  const severe = SEVERE_GEO_IDS.has(geoNum);
  const late = LATE_PRIMARY_GEO_IDS.has(geoNum);
  const election = severe ? WITHHELD_ELECTION : GENERAL_ELECTION;
  raceInserts += `INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, ${sqlStr(raceDesc(late, severe))}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = ${sqlStr(election)}
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
`;
}

const m1226 = `-- 1226_seed_al_2026_house_elections_races.sql
-- Phase 163-04 Task 2: AL 2026 Statewide General election + a dedicated NON-GENERAL
-- "AL 2026 Congressional Redistricting - Polygon Pending" election, + 7 severity-routed U.S. House
-- races. Field source: 160-field-table-p163.csv (AL rows), Wikipedia 2026 US House elections in Alabama.
-- ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays NULL.
--
-- SPLIT-STATE PRIMARY TIMING: AL-1/2/6/7 are late-primary (Aug-11 SCOTUS-ordered special primary) ->
-- PROVISIONAL descriptions, cull >= 2026-08-12; AL-3/4/5 decided -> plain general descriptions.
--
-- D-01b SEVERE-DISTRICT WITHHOLDING: per 163-al-correspondence-audit.md ("Severe geo_id list: 0102"),
-- ONLY AL-2 (0102) shifted severely under the SCOTUS-stayed 2023 map; its race is wired to the withheld
-- "Polygon Pending" election (election_type='special', election_date='${WITHHELD_DATE}' = the SCOTUS
-- stay date, >30 days past at execution) so electionService.ts's ELECTION_VISIBILITY_WINDOW evaluates
-- FALSE for it. office_id is NEVER null for ANY AL race (severe or not) -- it is ALWAYS the district's
-- EXISTING NATIONAL_LOWER office (D-01). essentials.offices is NEVER touched by this migration -- the
-- reps feed continues to show the true incumbent for every AL district. AL-1/6/7 required the special
-- primary but scored NOT-SEVERE (anchors preserved) so they surface normally (PROVISIONAL general).
-- 164.1 un-withholds AL-2 on polygon refresh.
BEGIN;

-- 2 elections (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${GENERAL_ELECTION}', '2026-11-03'::date, 'general', 'state', 'AL'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${GENERAL_ELECTION}');

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${WITHHELD_ELECTION}', '${WITHHELD_DATE}'::date, 'special', 'state', 'AL'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${WITHHELD_ELECTION}');

-- 7 severity-routed races (6 general + 1 withheld AL-2); office_id ALWAYS the existing old-CD office
${raceInserts}
COMMIT;
`;
writeFileSync('migrations/1226_seed_al_2026_house_elections_races.sql', m1226);

// ---- Migration 1227: 21 new politicians + race_candidates ----
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

// race_candidates joins by district geo_id (NOT election name) -- each AL district has exactly one
// race regardless of which election it is wired to, so this single block reaches severe + non-severe.
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

const m1227 = `-- 1227_seed_al_2026_house_candidates.sql
-- Phase 163-04 Task 2: ${newRows.length} new AL politicians + ${activeRows.length} active race_candidates
--   onto the 7 AL 2026 House races (6 general + 1 withheld "Polygon Pending" AL-2, per 163-01 routing).
--   Reuse 6 renominated incumbents by external_id; AL-1 Barry Moore (-1001, retired->Senate) -> NO
--   active row (open-seat convention, mirrors WI-7/CO-1/SC-1/SC-5). race_candidates inserts join by
--   district geo_id (not election name), so AL-2's severe-district candidates are wired identically
--   regardless of the election-visibility substitution -- seeding is complete for AL-2 even though its
--   race does not surface on /elections. ANTIPARTISAN: party never stored; offices untouched.
--   Field: 160-field-table-p163.csv AL rows, Wikipedia 2026 US House elections in Alabama.
BEGIN;

-- ${newRows.length} new challenger/open-seat records (idempotent on external_id)
${polInserts}
-- ${activeRows.length} active race_candidates (6 incumbents reused + ${newRows.length} new; Moore excluded)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1227_seed_al_2026_house_candidates.sql', m1227);

console.log(`CSV rows: ${rows.length} (active=${activeRows.length}, REUSE-NO-ROW=${rows.filter((r) => r.decision === 'REUSE-NO-ROW').length})`);
console.log(`NEW records: ${newRows.length}`);
console.log(`external_id range: ${Math.min(...newRows.map((r) => r.ext))} .. ${Math.max(...newRows.map((r) => r.ext))}`);
const dupExt = newRows.map((r) => r.ext).filter((v, i, a) => a.indexOf(v) !== i);
const dupName = rows.map((r) => r.name.toLowerCase()).filter((v, i, a) => a.indexOf(v) !== i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district active counts (severity + timing):');
for (let cd = 1; cd <= 7; cd++) {
  const geoNum = 100 + cd;
  const severe = SEVERE_GEO_IDS.has(geoNum);
  const late = LATE_PRIMARY_GEO_IDS.has(geoNum);
  const active = activeRows.filter((r) => r.cd === cd).length;
  const nu = newRows.filter((r) => r.cd === cd).length;
  console.log(`  AL-${cd} (geo ${String(geoNum).padStart(4, '0')}): ${active} active (${nu} new) -> ${severe ? 'WITHHELD' : 'GENERAL'} / ${late ? 'PROVISIONAL' : 'decided'}`);
}
console.log(`\nSeverity routing: SEVERE=[0102] -> ${WITHHELD_ELECTION}`);
console.log('\nWrote: migrations/1226_..., migrations/1227_..., data/seed-al-2026-house/163-04-al-reconciliation.csv');
