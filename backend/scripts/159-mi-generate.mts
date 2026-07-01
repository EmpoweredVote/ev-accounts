import { writeFileSync, mkdirSync } from 'fs';

// ---- MI field (validated against 159-RESEARCH BOE table; MI-12 Downer live-confirmed) ----
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean; vacate?: boolean };
const INC_EXT: Record<number, number> = {1:-26001,2:-26002,3:-26003,4:-26004,5:-26005,6:-26006,7:-26007,8:-26008,9:-26009,10:-26010,11:-26011,12:-26012,13:-26013};

const FIELD: Cand[] = [
  { cd:1, name:'Jack Bergman', party:'R', role:'R', inc:true },
  { cd:1, name:'Callie Barr', party:'D', role:'D' },
  { cd:1, name:'Kyle Blomquist', party:'D', role:'D' },
  { cd:1, name:'Wayne Stiles', party:'D', role:'D' },
  { cd:1, name:'Matthew DenOtter', party:'R', role:'R' },
  { cd:1, name:'Justin Michal', party:'R', role:'R' },
  { cd:1, name:'Zebulon Featherly', party:'I', role:'I' },
  { cd:1, name:'Thomas Latza', party:'I', role:'I' },
  { cd:2, name:'John R. Moolenaar', party:'R', role:'R', inc:true },
  { cd:2, name:'Ben Ambrose', party:'D', role:'D' },
  { cd:2, name:'Jamie Hill', party:'D', role:'D' },
  { cd:2, name:'Clyde Welford', party:'D', role:'D' },
  { cd:3, name:'Hillary J. Scholten', party:'D', role:'D', inc:true },
  { cd:3, name:'Ryan Cushman', party:'R', role:'R' },
  { cd:3, name:'Terri DeBoer', party:'R', role:'R' },
  { cd:4, name:'Bill Huizenga', party:'R', role:'R', inc:true },
  { cd:4, name:'Diop Harris II', party:'D', role:'D' },
  { cd:4, name:'Sean McCann', party:'D', role:'D' },
  { cd:4, name:'Philip Tanis', party:'R', role:'R' },
  { cd:5, name:'Tim Walberg', party:'R', role:'R', inc:true },
  { cd:5, name:'Christian Vukasovich', party:'D', role:'D' },
  { cd:5, name:'James Bronke', party:'G', role:'G' },
  { cd:6, name:'Debbie Dingell', party:'D', role:'D', inc:true },
  { cd:6, name:'Heather Smiley', party:'R', role:'R' },
  { cd:6, name:'Clyde Shabazz', party:'G', role:'G' },
  { cd:7, name:'Tom Barrett', party:'R', role:'R', inc:true },
  { cd:7, name:'Bridget Brink', party:'D', role:'D' },
  { cd:7, name:'William Lawrence', party:'D', role:'D' },
  { cd:7, name:'Matt Maasdam', party:'D', role:'D' },
  { cd:7, name:'Muhammad Salman Rais', party:'D', role:'D' },
  { cd:7, name:'Alexandra Prieditis', party:'I', role:'I' },
  { cd:8, name:'Kristen McDonald Rivet', party:'D', role:'D', inc:true },
  { cd:8, name:'Amir Hassan', party:'R', role:'R' },
  { cd:8, name:'Al Lemmo', party:'R', role:'R' },
  { cd:8, name:'Thomas J. Smith', party:'R', role:'R' },
  { cd:9, name:'Lisa C. McClain', party:'R', role:'R', inc:true },
  { cd:9, name:'Ray Pooley', party:'D', role:'D' },
  { cd:9, name:'Jasen Cartwright', party:'I', role:'I' },
  { cd:9, name:'Fernando Valdez', party:'I', role:'I' },
  { cd:10, name:'John James', party:'R', role:'R', inc:true, vacate:true },
  { cd:10, name:'Eric Chung', party:'D', role:'D' },
  { cd:10, name:'Tim Greimel', party:'D', role:'D' },
  { cd:10, name:'Christina Bertrand Hines', party:'D', role:'D' },
  { cd:10, name:'Michael Bouchard', party:'R', role:'R' },
  { cd:10, name:'Steffan Demetropoulos', party:'R', role:'R' },
  { cd:10, name:'Justin Kirk', party:'R', role:'R' },
  { cd:10, name:'Robert Lulgjuraj', party:'R', role:'R' },
  { cd:11, name:'Haley M. Stevens', party:'D', role:'D', inc:true, vacate:true },
  { cd:11, name:'Stu Baker', party:'D', role:'D' },
  { cd:11, name:'Aisha Farooqi', party:'D', role:'D' },
  { cd:11, name:'Jeremy Moss', party:'D', role:'D' },
  { cd:11, name:'Michelle Mary Murphy', party:'D', role:'D' },
  { cd:11, name:'John Paul Torres', party:'D', role:'D' },
  { cd:11, name:'Don Ufford', party:'D', role:'D' },
  { cd:11, name:'Ethan Baker', party:'R', role:'R' },
  { cd:11, name:'Tony J. Prieto', party:'R', role:'R' },
  { cd:12, name:'Rashida Tlaib', party:'D', role:'D', inc:true },
  { cd:12, name:'Allen Downer', party:'D', role:'D' },
  { cd:12, name:'Shanelle Jackson', party:'D', role:'D' },
  { cd:12, name:'Byron H. Nolen', party:'D', role:'D' },
  { cd:12, name:'James D. Hooper', party:'R', role:'R' },
  { cd:13, name:'Shri Thanedar', party:'D', role:'D', inc:true },
  { cd:13, name:'John Goci', party:'D', role:'D' },
  { cd:13, name:'Donavan McKinney', party:'D', role:'D' },
  { cd:13, name:'Mary Waters', party:'D', role:'D' },
  { cd:13, name:'Martell D. Bivings', party:'R', role:'R' },
  { cd:13, name:'Raphiel King', party:'R', role:'R' },
  { cd:13, name:'T.P. Nykoriak', party:'R', role:'R' },
  { cd:13, name:'Maurice Morton', party:'I', role:'I' },
];

const SRC_MAJOR = 'MI BOE PRI-2026 candidate report (mi-boe.entellitrak.com)';
const SRC_OTHER = 'Declared indep/Green (politics1.com/mi.htm + Ballotpedia); provisional — MI filing deadline 2026-07-16';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- assign external_ids per district (seq in FIELD order, incumbents skipped) ----
const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; decision: string; is_incumbent: boolean; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '26' + String(c.cd).padStart(2, '0');
  const source = c.role === 'D' || c.role === 'R' ? SRC_MAJOR : SRC_OTHER;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: c.vacate ? 'REUSE-NO-ROW' : 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(26 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}

// ---- CSV ----
mkdirSync('data/seed-mi-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,source';
const csvLines = rows.map(r => [r.cd, r.geo, `"${r.name}"`, r.party, r.role, r.decision, r.ext, r.is_incumbent, `"${r.source}"`].join(','));
writeFileSync('data/seed-mi-2026-house/159-01-mi-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration 1146: election + 13 races ----
const m1146 = `-- 1146_seed_mi_2026_house_elections_races.sql
-- Phase 159-01 Task 1: MI 2026 Statewide General election + 13 provisional U.S. House races.
-- Field source: MI Bureau of Elections PRI-2026 report (mi-boe.entellitrak.com), cross-checked
--   Ballotpedia/Wikipedia (159-RESEARCH.md MI section). Provisional pre-primary field (FL-151 D-04),
--   culled >= 2026-08-05 in Phase 159-05. ANTIPARTISAN INVARIANT: party is NEVER stored on
--   race_candidates; races.primary_party stays NULL. MI-10/MI-11 are OPEN SEATS (James->Gov,
--   Stevens->Senate) but their district offices already exist -- NO office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'MI 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'MI'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'MI 2026 Statewide General');

-- 13 provisional races on the EXISTING MI NATIONAL_LOWER US Rep offices (geo 2601..2613)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '26'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'MI 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
`;
writeFileSync('migrations/1146_seed_mi_2026_house_elections_races.sql', m1146);

// ---- Migration 1147: 56 new politicians + race_candidates ----
const newRows = rows.filter(r => r.decision === 'NEW');
const activeRows = rows.filter(r => r.decision === 'NEW' || r.decision === 'REUSE'); // excludes REUSE-NO-ROW

let polInserts = '';
for (const r of newRows) {
  const { first, last } = nameParts(r.name);
  polInserts += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}

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
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}

const m1147 = `-- 1147_seed_mi_2026_house_candidates.sql
-- Phase 159-01 Task 2: ${newRows.length} new MI politicians + ${activeRows.length} active race_candidates
--   onto the 13 MI 2026 Statewide General races. Reuse 11 incumbents by external_id;
--   MI-10 John James (-26010) + MI-11 Haley Stevens (-26011) VACATE -> NO active row (open-seat
--   convention, mirrors NJ-12 Watson Coleman). ANTIPARTISAN: party never stored; races untouched.
--   Field: MI BOE PRI-2026 report; declared indep/Green provisional (MI filing deadline 2026-07-16).
BEGIN;

-- ${newRows.length} new challenger/open-seat/indep/Green records (idempotent on external_id)
${polInserts}
-- ${activeRows.length} active race_candidates (11 incumbents reused + ${newRows.length} new; James/Stevens excluded)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1147_seed_mi_2026_house_candidates.sql', m1147);

console.log(`CSV rows: ${rows.length} (active=${activeRows.length}, REUSE-NO-ROW=${rows.filter(r=>r.decision==='REUSE-NO-ROW').length})`);
console.log(`NEW records: ${newRows.length}`);
console.log(`external_id range: ${Math.min(...newRows.map(r=>r.ext))} .. ${Math.max(...newRows.map(r=>r.ext))}`);
const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district active counts:');
for (let cd=1; cd<=13; cd++) console.log(`  MI-${cd}: ${activeRows.filter(r=>r.cd===cd).length} active`);
console.log('\nWrote: migrations/1146_..., migrations/1147_..., data/seed-mi-2026-house/159-01-mi-reconciliation.csv');
