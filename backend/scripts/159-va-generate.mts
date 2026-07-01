import { writeFileSync, mkdirSync } from 'fs';
import { pool } from '../src/lib/db.js';

// VA incumbent -> CORRECT external_id (verified via office-linkage + GovTrack/Wikipedia).
// NOTE: DB office links for VA-5/6/9 are rotated (pre-existing bug); we wire the TRUE incumbent
// per district by their real external_id: VA-5 McGuire=-5102009, VA-6 Cline=-5102005, VA-9 Griffith=-5102006.
const INC_EXT: Record<number, number> = {
  1:-5102001, 2:-5102002, 3:-5102003, 4:-5102004, 5:-5102009, 6:-5102005,
  7:-5102007, 8:-5102008, 9:-5102006, 10:-5102010, 11:-5102011,
};
const INC_NAME: Record<number, string> = {
  1:'Rob Wittman', 2:'Jen Kiggans', 3:'Bobby Scott', 4:'Jennifer McClellan', 5:'John McGuire',
  6:'Ben Cline', 7:'Eugene Vindman', 8:'Don Beyer', 9:'Morgan Griffith', 10:'Suhas Subramanyam', 11:'James Walkinshaw',
};

type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean };
const FIELD: Cand[] = [
  // VA-1 Wittman(R) inc; R uncontested; 7 D
  { cd:1, name:'Rob Wittman', party:'R', role:'R', inc:true },
  { cd:1, name:'Salaam Bhatti', party:'D', role:'D' },
  { cd:1, name:'Elizabeth Beggs', party:'D', role:'D' },
  { cd:1, name:'Tim Cywinski', party:'D', role:'D' },
  { cd:1, name:'Jason Knapp', party:'D', role:'D' },
  { cd:1, name:'Ericka Kopp', party:'D', role:'D' },
  { cd:1, name:'Shannon Taylor', party:'D', role:'D' },
  { cd:1, name:'Mel Tull', party:'D', role:'D' },
  // VA-2 Kiggans(R) inc; 4 D; 2 indep
  { cd:2, name:'Jen Kiggans', party:'R', role:'R', inc:true },
  { cd:2, name:'Elaine Luria', party:'D', role:'D' },
  { cd:2, name:'Nila Devanath', party:'D', role:'D' },
  { cd:2, name:'Bill Fleming', party:'D', role:'D' },
  { cd:2, name:'Patrick Mosolf', party:'D', role:'D' },
  { cd:2, name:'Makiba Gaines', party:'I', role:'I' },
  { cd:2, name:'Bishop Staten', party:'I', role:'I' },
  // VA-3 Scott(D) inc; 1 R; 1 indep
  { cd:3, name:'Bobby Scott', party:'D', role:'D', inc:true },
  { cd:3, name:'Edwin Rivera', party:'R', role:'R' },
  { cd:3, name:'James "Zeb" Taylor', party:'I', role:'I' },
  // VA-4 McClellan(D) inc; no R filed; 2 indep
  { cd:4, name:'Jennifer McClellan', party:'D', role:'D', inc:true },
  { cd:4, name:'Andre Kersey', party:'I', role:'I' },
  { cd:4, name:'Jason Brown II', party:'I', role:'I' },
  // VA-5 McGuire(R) inc; 3 D; 2 R; 1 indep
  { cd:5, name:'John McGuire', party:'R', role:'R', inc:true },
  { cd:5, name:'Tom Perriello', party:'D', role:'D' },
  { cd:5, name:'Suzanne Krzyzanowski', party:'D', role:'D' },
  { cd:5, name:'Robert Tracinski', party:'D', role:'D' },
  { cd:5, name:'Melanie Lucero', party:'R', role:'R' },
  { cd:5, name:'Bob Good', party:'R', role:'R' },
  { cd:5, name:'Chris Register', party:'I', role:'I' },
  // VA-6 Cline(R) inc; 1 D
  { cd:6, name:'Ben Cline', party:'R', role:'R', inc:true },
  { cd:6, name:'Beth Macy', party:'D', role:'D' },
  // VA-7 Vindman(D) inc; 3 R; 1 indep
  { cd:7, name:'Eugene Vindman', party:'D', role:'D', inc:true },
  { cd:7, name:'Philip Harding', party:'R', role:'R' },
  { cd:7, name:'Doug Ollivant', party:'R', role:'R' },
  { cd:7, name:'Ricky Smithers', party:'R', role:'R' },
  { cd:7, name:'Randall Terry', party:'I', role:'I' },
  // VA-8 Beyer(D) inc; 4 D; 1 R
  { cd:8, name:'Don Beyer', party:'D', role:'D', inc:true },
  { cd:8, name:'Lorena Bruner', party:'D', role:'D' },
  { cd:8, name:'Michael Duffin', party:'D', role:'D' },
  { cd:8, name:'Adam Dunigan', party:'D', role:'D' },
  { cd:8, name:'Mo Seifeldein', party:'D', role:'D' },
  { cd:8, name:'Tony Sabio', party:'R', role:'R' },
  // VA-9 Griffith(R) inc; 4 D; 1 R; 1 indep
  { cd:9, name:'Morgan Griffith', party:'R', role:'R', inc:true },
  { cd:9, name:'Douglas Crockett', party:'D', role:'D' },
  { cd:9, name:'Brandi Hall', party:'D', role:'D' },
  { cd:9, name:'Adam Murphy', party:'D', role:'D' },
  { cd:9, name:'Joy Powers', party:'D', role:'D' },
  { cd:9, name:'Brandon Cook', party:'R', role:'R' },
  { cd:9, name:'Michael Jackson', party:'I', role:'I' },
  // VA-10 Subramanyam(D) inc; 3 R (Wong withdrew)
  { cd:10, name:'Suhas Subramanyam', party:'D', role:'D', inc:true },
  { cd:10, name:'Dave Beckwith', party:'R', role:'R' },
  { cd:10, name:'Julie Perry', party:'R', role:'R' },
  { cd:10, name:'Anthony Suttles', party:'R', role:'R' },
  // VA-11 Walkinshaw(D) inc REUSE -5102011; 3 D; 2 R
  { cd:11, name:'James Walkinshaw', party:'D', role:'D', inc:true },
  { cd:11, name:'Bree Fram', party:'D', role:'D' },
  { cd:11, name:'Stella Pekarsky', party:'D', role:'D' },
  { cd:11, name:'Amy Roma', party:'D', role:'D' },
  { cd:11, name:'Nathan Headrick', party:'R', role:'R' },
  { cd:11, name:'Michael Van Meter', party:'R', role:'R' },
];

const SRC_MAJOR = 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP';
const SRC_OTHER = 'Declared indep/3rd-party (Wikipedia/politics1); provisional — VA filing deadline 2026-08-04';

function nameParts(n: string) { const p = n.trim().split(/\s+/); return { first: p[0], last: p.slice(1).join(' ') }; }
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }
function csvCell(s: string) { return '"' + s.replace(/"/g, '""') + '"'; }
function lastName(n: string) { const p = n.replace(/ (II|III|Jr\.?|Sr\.?)$/,'').trim().split(/\s+/); return p[p.length-1]; }
function firstName(n: string) { return n.trim().split(/\s+/)[0]; }
const COMMITTEE_RE = /\b(FOR|CAMPAIGN|COMMITTEE|FRIENDS|ELECT|SPONSORED|SUPPORTING|PAC)\b/i;

async function dedup(newCands: Cand[]) {
  console.log('=== VA dedup: potential existing real-politician matches ===');
  let hits = 0;
  for (const c of newCands) {
    const ln = lastName(c.name).toLowerCase(), fn = firstName(c.name).toLowerCase();
    const q = await pool.query(
      `SELECT p.external_id, p.full_name, p.is_active, d.geo_id, d.state
       FROM essentials.politicians p
       LEFT JOIN essentials.offices o ON o.politician_id=p.id
       LEFT JOIN essentials.districts d ON d.id=o.district_id
       WHERE p.full_name ILIKE $1 AND p.full_name ILIKE $2
         AND (p.external_id IS NOT NULL OR o.id IS NOT NULL)
         AND NOT (p.full_name ~ '[A-Z]{4,}')`,
      [`%${fn}%`, `%${ln}%`]
    );
    const pl = q.rows.filter(r=>{ const w=String(r.full_name).toLowerCase().replace(/[.,"]/g,'').split(/\s+/); return w.includes(ln)&&w.includes(fn)&&!COMMITTEE_RE.test(r.full_name); });
    if (pl.length) { hits++; console.log(`  VA-${c.cd} "${c.name}" (${c.party}) →`); pl.forEach(r=>console.log(`       ext=${r.external_id} "${r.full_name}" active=${r.is_active} geo=${r.geo_id||'-'} st=${r.state||'-'}`)); }
  }
  if (!hits) console.log('  (none — all new VA candidates have zero real-politician matches → all NEW)');
  return hits;
}

async function main() {
  const RACE_ID: Record<number,string> = {
    1:'65dd3477-4828-43de-adb5-9b621d08b43e',2:'73a46730-61f8-4e35-90d7-20c11016865e',3:'ae5bfa0e-f5da-4fd1-bf69-d07db17a48ee',
    4:'a48dfb93-6c36-40b0-8f92-c28c6159c9f9',5:'6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe',6:'807d0f7c-6bb7-4810-b120-ec241eadef42',
    7:'b9e08170-8918-4bf6-a57c-f0ba5f4dabde',8:'df4895e9-81e6-4392-ab40-18105ddacf7c',9:'da51cdee-de79-4186-baab-033308f251fe',
    10:'3fccc125-a310-4624-aff6-05f8b54bf7cd',11:'bb9b6411-ef5f-4c1a-bab0-046adf472d4e',
  };

  // Non-incumbent candidates who ALREADY have a politician record (dedup) -> REUSE, do NOT create.
  // Stella Pekarsky = existing "Stella G. Pekarsky" VA state senator (-5110036), running for VA-11 US House.
  const REUSE_OVERRIDE: Record<string, number> = { 'Stella Pekarsky': -5110036 };

  const newCands = FIELD.filter(c=>!c.inc && !(c.name in REUSE_OVERRIDE));
  const hits = await dedup(newCands);

  // assign external_ids
  const seqByCd: Record<number,number> = {};
  type Row = Cand & { geo:string; ext:number; decision:string; is_incumbent:boolean; source:string; race_id:string };
  const rows: Row[] = [];
  for (const c of FIELD) {
    const geo = '51' + String(c.cd).padStart(2,'0');
    const source = (c.role==='D'||c.role==='R') ? SRC_MAJOR : SRC_OTHER;
    if (c.inc) rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision:'REUSE', is_incumbent:true, source, race_id: RACE_ID[c.cd] });
    else if (c.name in REUSE_OVERRIDE) rows.push({ ...c, geo, ext: REUSE_OVERRIDE[c.name], decision:'REUSE', is_incumbent:false, source, race_id: RACE_ID[c.cd] });
    else { seqByCd[c.cd]=(seqByCd[c.cd]||0)+1; const ext=-(51*10000+c.cd*100+seqByCd[c.cd]); rows.push({ ...c, geo, ext, decision:'NEW', is_incumbent:false, source, race_id: RACE_ID[c.cd] }); }
  }

  const newRows = rows.filter(r=>r.decision==='NEW');
  const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
  const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
  console.log(`\nfield=${FIELD.length} inc=${FIELD.filter(c=>c.inc).length} new=${newRows.length} active=${rows.length}`);
  console.log(`ext range: ${Math.min(...newRows.map(r=>r.ext))}..${Math.max(...newRows.map(r=>r.ext))}`);
  console.log(`dup ext: ${dupExt.length?dupExt:'none'} | dup name: ${dupName.length?dupName:'none'}`);
  for (let cd=1;cd<=11;cd++) console.log(`  VA-${cd}: ${rows.filter(r=>r.cd===cd).length} active (inc ext ${INC_EXT[cd]})`);

  if (hits>0) { console.log('\n*** DEDUP HITS FOUND — review before generating. Files NOT written. ***'); await pool.end(); return; }

  // CSV
  mkdirSync('data/seed-va-2026-house',{recursive:true});
  const header='cd,geo_id,race_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,source';
  const csv=[header,...rows.map(r=>[r.cd,r.geo,r.race_id,csvCell(r.name),r.party,r.role,r.decision,r.ext,r.is_incumbent,csvCell(r.source)].join(','))].join('\n')+'\n';
  writeFileSync('data/seed-va-2026-house/159-03-va-reconciliation.csv',csv);

  // Migration 1148
  let polIns='';
  for (const r of newRows){ const {first,last}=nameParts(r.name); polIns+=`INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`; }
  let rcIns='';
  for (const r of rows){ const {first,last}=nameParts(r.name); rcIns+=`INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT ${sqlStr(r.race_id)}::uuid, p.id, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, ${r.is_incumbent}, 'active', ${sqlStr(r.source)}
FROM essentials.politicians p
WHERE p.external_id = ${r.ext}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = ${sqlStr(r.race_id)}::uuid AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`; }

  const m=`-- 1148_seed_va_2026_house_candidates.sql
-- Phase 159-03: ${newRows.length} new VA politicians + ${rows.length} active race_candidates onto the
--   11 EXISTING VA U.S. House races (2026 Virginia General Election; races NOT created here).
-- Field: Wikipedia 2026 VA US House (raw) + Ballotpedia Aug-4 primary pages, cross-checked
--   vademocrats/VPAP/politics1. Withdrawn candidates excluded; declared indep/3rd-party seeded
--   PROVISIONAL (VA filing deadline 2026-08-04) -> reconciled in Phase 159-05.
-- ANTIPARTISAN: party never stored on race_candidates; races.primary_party untouched.
-- INCUMBENT REUSE (all 11), incl. Walkinshaw -5102011 (single record, NOT duplicated). NOTE: the
--   VA-5/6/9 incumbent records carry rotated external_ids vs district (pre-existing DB office-link
--   bug) — we wire the TRUE incumbent per district: VA-5 McGuire(-5102009), VA-6 Cline(-5102005),
--   VA-9 Griffith(-5102006). Office-link rotation flagged as a separate carry-forward.
BEGIN;

-- Add PROVISIONAL marker to the 11 existing VA races (description-only; office_id/election_id untouched)
UPDATE essentials.races r
SET description = 'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05'
WHERE r.id IN (${Object.values(RACE_ID).map(id=>`'${id}'::uuid`).join(',')})
  AND (r.description IS NULL OR r.description NOT LIKE 'PROVISIONAL:%');

-- ${newRows.length} new challenger/indep records (idempotent on external_id)
${polIns}
-- ${rows.length} active race_candidates onto existing VA races (11 incumbents reused + ${newRows.length} new)
${rcIns}
COMMIT;
`;
  writeFileSync('migrations/1148_seed_va_2026_house_candidates.sql',m);
  console.log('\nWrote migrations/1148_..., data/seed-va-2026-house/159-03-va-reconciliation.csv');
  await pool.end();
}
main().catch(e=>{console.error(e);process.exit(1)});
