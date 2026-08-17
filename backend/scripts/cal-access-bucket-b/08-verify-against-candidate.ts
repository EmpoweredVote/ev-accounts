// 08-verify-against-candidate.ts
// Independently re-verifies every surviving KEEP and every unprovable PURGE against a FOURTH
// Cal-Access field nobody used until now: the candidate cross-reference.
//
//   /Campaign/Candidates/Detail.aspx?id=<committee filer id>  ->  "STRICKLAND, TONY (ID# 098241)"
//
// 🔑 THIS IS THE FIELD `confirm-cal-access.ts` SHOULD HAVE MATCHED ON. It names the candidate behind
// the committee outright, with their own stable candidate id, so identity needs no name-shape
// reasoning at all. Everything this project did -- last-token matching, given-name tests, office
// corroboration, historical names -- was working around the absence of this one lookup.
//
// Run from backend/:  npx tsx scripts/cal-access-bucket-b/08-verify-against-candidate.ts
//
// It is a CHECK, not a generator: it writes a report and exits non-zero on any contradiction.
import * as fs from 'fs';
import * as path from 'path';
import { namesThem, fold, givenName, DIMINUTIVES } from './03-classify-track-a';

const DIR = path.join(process.cwd(), 'data', 'cal-access-bucket-b');
const RAW = path.join(DIR, 'raw');
const CONTROL_ID = '1414018';
const CONTROL_CAND = 'NEWSOM, GAVIN';

const targets = JSON.parse(fs.readFileSync(path.join(DIR, '_verify-targets.json'), 'utf8'));

const cand: Record<string, { name: string; id: string }> = {};
let failures = 0;
for (const f of fs.readdirSync(RAW).filter(x => /^cand-batch-\d+\.json$/.test(x)).sort()) {
  let parsed: any = JSON.parse(fs.readFileSync(path.join(RAW, f), 'utf8'));
  if (typeof parsed === 'string') parsed = JSON.parse(parsed);
  const ctl = String(parsed[CONTROL_ID] ?? '');
  if (!ctl.startsWith(CONTROL_CAND)) {
    console.error(`🔴 ${f}: CONTROL FAILED -- got "${ctl}". Challenged, not empty.`);
    failures++; continue;
  }
  for (const [id, v] of Object.entries(parsed as Record<string, string>)) {
    if (!(id in targets)) continue;
    const s = String(v);
    if (s.startsWith('__')) { cand[id] = { name: '', id: '' }; continue; }
    const [nm, cid] = s.split(' |');
    cand[id] = { name: (nm || '').trim(), id: (cid || '').trim() };
  }
}

/** "SURNAME, GIVEN M." -> does it name our politician? */
function candidateNamesThem(candName: string, first: string, last: string): boolean {
  if (!candName) return false;
  const [surRaw, givRaw = ''] = candName.split(',');
  const sur = fold(surRaw.trim().toLowerCase());
  const giv = fold(givRaw.trim().toLowerCase()).split(/\s+/)[0] ?? '';
  const ourSur = fold(last.trim().toLowerCase());
  const ourGiv = givenName(first);
  if (!sur || sur !== ourSur) return false;
  if (!giv || !ourGiv) return false;
  if (giv === ourGiv) return true;
  if ((DIMINUTIVES[ourGiv] ?? []).some(d => d === giv)) return true;
  if ((DIMINUTIVES[giv] ?? []).some(d => d === ourGiv)) return true;
  // "MICHAEL A" vs "MIKE": fall back to the shared full-string test
  return namesThem(candName, first, last);
}

const buckets: Record<string, any[]> = {
  keep_confirmed: [], keep_contradicted: [], keep_norecord: [],
  purge_confirmed: [], purge_contradicted: [], purge_norecord: [],
};

for (const [filer, t] of Object.entries<any>(targets)) {
  const c = cand[filer];
  if (!c) { console.error(`🔴 ${filer} never fetched`); failures++; continue; }
  const isKeep = t.kind === 'keep';
  if (!c.name) { buckets[isKeep ? 'keep_norecord' : 'purge_norecord'].push({ filer, ...t, cand: '' }); continue; }
  const them = candidateNamesThem(c.name, t.first, t.last);
  const key = isKeep ? (them ? 'keep_confirmed' : 'keep_contradicted')
                     : (them ? 'purge_contradicted' : 'purge_confirmed');
  buckets[key].push({ filer, ...t, cand: c.name, cand_id: c.id });
}

const money = (rs: any[]) => rs.reduce((a, r) => a + (r.dollars || 0), 0).toFixed(2);
console.log(`KEEPS      confirmed ${buckets.keep_confirmed.length} ($${money(buckets.keep_confirmed)}) · CONTRADICTED ${buckets.keep_contradicted.length} ($${money(buckets.keep_contradicted)}) · no candidate record ${buckets.keep_norecord.length} ($${money(buckets.keep_norecord)})`);
console.log(`UNPROVABLE confirmed ${buckets.purge_confirmed.length} ($${money(buckets.purge_confirmed)}) · CONTRADICTED ${buckets.purge_contradicted.length} ($${money(buckets.purge_contradicted)}) · no candidate record ${buckets.purge_norecord.length} ($${money(buckets.purge_norecord)})`);

console.log(`\n🔴 KEEPS THE CANDIDATE RECORD CONTRADICTS -- someone else's money is on display:`);
for (const r of buckets.keep_contradicted.sort((a, b) => b.dollars - a.dollars)) {
  console.log(`  $${r.dollars.toFixed(2).padStart(11)}  ${r.pol}  <-  "${r.cmt}"  ==>  candidate is ${r.cand} (#${r.cand_id})`);
}
console.log(`\n🔴 UNPROVABLE PURGES THE CANDIDATE RECORD CONTRADICTS -- we deleted their real money:`);
for (const r of buckets.purge_contradicted.sort((a, b) => b.dollars - a.dollars)) {
  console.log(`  $${r.dollars.toFixed(2).padStart(11)}  ${r.pol}  <-  "${r.cmt}"  ==>  candidate is ${r.cand} (#${r.cand_id})`);
}
console.log(`\n✅ unprovable purges now AFFIRMATIVELY disproved:`);
for (const r of buckets.purge_confirmed.sort((a, b) => b.dollars - a.dollars).slice(0, 30)) {
  console.log(`  $${r.dollars.toFixed(2).padStart(11)}  ${r.pol}  <-  "${r.cmt}"  ==>  candidate is ${r.cand}`);
}

fs.writeFileSync(path.join(DIR, 'candidate-verification.json'), JSON.stringify(buckets, null, 2));
console.log(`\nwrote candidate-verification.json`);
if (failures) process.exit(1);
if (buckets.keep_contradicted.length || buckets.purge_contradicted.length) {
  console.error('\n🔴 CONTRADICTIONS FOUND — see above.');
  process.exit(2);
}
