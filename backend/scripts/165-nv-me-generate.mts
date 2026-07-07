import { writeFileSync, mkdirSync } from 'fs';

// ---- NV + ME field (validated against 160-field-table-p165.csv + LIVE prod checks 2026-07-07) ----
// Phase 165-01: NV + ME CANDIDATES-ONLY reconciliation onto PRE-EXISTING races (Track 1).
//   NV 'NV 2026 Statewide General' (4 races) + ME '2026 Maine General Election' (2 races) already
//   live -> NO elections/races INSERT (the OR-164-03 reuse pattern). DECIDED fields, NOT PROVISIONAL.
//   NV: 5 new candidates + the Lynn Chapman NULL-pid FIX (race_candidates row 08dfb911 fix-not-
//   recreate; Chapman politician created at NV-2 seq 51 per D-04 since no live record exists).
//   ME: Ronald Russell (ME-1) + Matthew Dunlap (ME-2) — live scan 2026-07-07 found NO dormant pids
//   -> both create-new. Pingree/LePage existing rows were candidate_status='filed' -> normalized to
//   'active' (guarded UPDATE; is_incumbent untouched: Pingree true, LePage false).
//   D-04 seq floors (live-confirmed): NV-1 74 (top -320173), NV-2 51 (top -320250), NV-3 1 (empty),
//   NV-4 79 (top -320478); ME-1 3 (Collins/King -23010x), ME-2 3 (Pingree/Golden -23020x).
const EXISTING_RACE_ID: Record<string, string> = {
  'NV1': 'a5295941-38b1-4c7f-8edf-39097ad3fb0a',
  'NV2': '0c470cc0-5250-43f1-b7f7-57778cadacc6',
  'NV3': '79e7fb35-a73a-478c-847d-553e9ad11e7c',
  'NV4': '81eb1a27-b710-42c3-a27c-a2c0153c2820',
  'ME1': 'd92aa73a-17db-4ba1-bfaf-46640f66f8f5',
  'ME2': 'aa63d55d-80b8-42b9-9aa5-0713387f65fb',
};
const CHAPMAN_RC_ROW = '08dfb911-9ddc-4c0d-85a2-fb14884a9160'; // NV-2 NULL-pid row (fix-not-recreate)
const PINGREE_RC_ROW = 'a93b5364-f9bc-406b-b175-8c452dcaf276'; // ME-1 'filed' -> 'active'
const LEPAGE_RC_ROW  = 'c58647c9-1ac0-43a4-9682-c0c7198631b9'; // ME-2 'filed' -> 'active'

const SRC_NV = 'NV SoS 2026 general candidate list (decided; nvsos.gov/home/showpublisheddocument/20105)';
const SRC_ME = 'ME 2026 general field (decided; en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Maine; RCV general)';

type Cand = { key: string; name: string; party: string; ext: number; source: string };
// NEW records only (Chapman handled separately as fix). external_id = -(fips*10000+cd*100+seq).
const FIELD: Cand[] = [
  { key:'NV1', name:'Bobby Khan',      party:'No Political Party',   ext:-320174, source:SRC_NV },
  { key:'NV1', name:'Steven St John',  party:'No Political Party',   ext:-320175, source:SRC_NV },
  { key:'NV3', name:'Jon Kamerath',    party:'Independent American', ext:-320301, source:SRC_NV },
  { key:'NV4', name:'Russell Best',    party:'Independent American', ext:-320479, source:SRC_NV },
  { key:'NV4', name:'William Johnson', party:'No Political Party',   ext:-320480, source:SRC_NV },
  { key:'ME1', name:'Ronald Russell',  party:'Republican',           ext:-230103, source:SRC_ME },
  { key:'ME2', name:'Matthew Dunlap',  party:'Democratic',           ext:-230203, source:SRC_ME },
];
const CHAPMAN = { key:'NV2', name:'Lynn Chapman', party:'Independent American', ext:-320251, source:SRC_NV };

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- CSV reconciliation ----
mkdirSync('data/seed-nv-2026-house', { recursive: true });
const header = 'state,key,race_id,full_name,party_from_field,decision,assign_external_id,is_incumbent,source';
const csvLines: string[] = [];
for (const r of FIELD) csvLines.push([r.key.slice(0,2), r.key, EXISTING_RACE_ID[r.key], `"${r.name}"`, r.party, 'NEW', r.ext, false, `"${r.source}"`].join(','));
csvLines.push(['NV','NV2',EXISTING_RACE_ID.NV2,`"${CHAPMAN.name}"`,CHAPMAN.party,'FIX-NULL-PID (new politician + UPDATE rc 08dfb911)',CHAPMAN.ext,false,`"${CHAPMAN.source}"`].join(','));
csvLines.push(['ME','ME1',EXISTING_RACE_ID.ME1,'"Chellie Pingree"','','STATUS-NORMALIZE filed->active',-230201,true,`"${SRC_ME}"`].join(','));
csvLines.push(['ME','ME2',EXISTING_RACE_ID.ME2,'"Paul LePage"','','STATUS-NORMALIZE filed->active',-410014,false,`"${SRC_ME}"`].join(','));
writeFileSync('data/seed-nv-2026-house/165-01-nv-me-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- shared SQL builders ----
function polInsert(name: string, ext: number): string {
  const { first, last } = nameParts(name);
  return `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${ext}, ${sqlStr(name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${ext});
`;
}
function rcInsert(name: string, ext: number, raceId: string, source: string): string {
  const { first, last } = nameParts(name);
  return `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '${raceId}'::uuid, p.id, ${sqlStr(name)}, ${sqlStr(first)}, ${sqlStr(last)}, false, 'active', ${sqlStr(source)}
FROM essentials.politicians p
WHERE p.external_id = ${ext}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '${raceId}'::uuid AND rc.politician_id = p.id);
`;
}

// ---- Migration A (1250): NV candidates-only + Chapman fix ----
const nvNew = FIELD.filter(r => r.key.startsWith('NV'));
let nvSql = '';
for (const r of nvNew) nvSql += polInsert(r.name, r.ext);
nvSql += polInsert(CHAPMAN.name, CHAPMAN.ext);
for (const r of nvNew) nvSql += rcInsert(r.name, r.ext, EXISTING_RACE_ID[r.key], r.source);

const migA = `-- 1250_seed_nv_2026_house_candidates.sql
-- Phase 165-01: NV CANDIDATES-ONLY seed onto the 4 PRE-EXISTING NV U.S. House races
--   ('NV 2026 Statewide General'; NO elections/races INSERT — reuse existing race UUIDs).
--   5 new NV politicians (-320174/-320175/-320301/-320479/-320480, D-04 floors live-confirmed)
--   + 5 challenger race_candidates + the Lynn Chapman NULL-pid FIX: politician created at
--   -320251 (NV-2 seq 51; no live Chapman record 2026-07-07), then UPDATE of the existing
--   race_candidates row ${CHAPMAN_RC_ROW} — never a second Chapman row.
--   DECIDED field -> NOT PROVISIONAL. NOT EXISTS guards; sqlStr()-escaped. ANTIPARTISAN: party never stored.
BEGIN;

-- (a) 5 new NV politicians + Chapman (idempotent on external_id)
${nvSql}
-- (b) Chapman NULL-pid FIX (UPDATE existing row; no new race_candidates row)
UPDATE essentials.race_candidates
SET politician_id = (SELECT id FROM essentials.politicians WHERE external_id = ${CHAPMAN.ext})
WHERE id = '${CHAPMAN_RC_ROW}'::uuid
  AND politician_id IS NULL;

COMMIT;
`;
writeFileSync('migrations/1250_seed_nv_2026_house_candidates.sql', migA);

// ---- Migration B (1251): ME candidates-only + filed->active normalization ----
const meNew = FIELD.filter(r => r.key.startsWith('ME'));
let meSql = '';
for (const r of meNew) meSql += polInsert(r.name, r.ext);
for (const r of meNew) meSql += rcInsert(r.name, r.ext, EXISTING_RACE_ID[r.key], r.source);

const migB = `-- 1251_seed_me_2026_house_candidates.sql
-- Phase 165-01: ME CANDIDATES-ONLY seed onto the 2 PRE-EXISTING ME U.S. House races
--   ('2026 Maine General Election'; NO elections/races INSERT — reuse existing race UUIDs).
--   Ronald Russell (-230103, ME-1) + Matthew Dunlap (-230203, ME-2) — live scan 2026-07-07
--   found NO dormant pids -> both create-new. Pingree (${PINGREE_RC_ROW}) and
--   LePage (${LEPAGE_RC_ROW}) rows normalized 'filed'->'active' (is_incumbent untouched).
--   DECIDED field; ME generals are RCV. NOT EXISTS guards; sqlStr()-escaped. ANTIPARTISAN: party never stored.
BEGIN;

-- (a) 2 new ME politicians (idempotent on external_id)
${meSql}
-- (b) normalize the 2 pre-existing 'filed' rows to 'active' (idempotent; flags untouched)
UPDATE essentials.race_candidates SET candidate_status = 'active'
WHERE id IN ('${PINGREE_RC_ROW}'::uuid, '${LEPAGE_RC_ROW}'::uuid)
  AND candidate_status = 'filed';

COMMIT;
`;
writeFileSync('migrations/1251_seed_me_2026_house_candidates.sql', migB);

const all = [...FIELD, CHAPMAN];
const dupExt = all.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = all.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`new NV: ${nvNew.length}+Chapman fix; new ME: ${meNew.length}`);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}; dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('Wrote: migrations/1250_seed_nv_2026_house_candidates.sql, migrations/1251_seed_me_2026_house_candidates.sql, data/seed-nv-2026-house/165-01-nv-me-reconciliation.csv');
