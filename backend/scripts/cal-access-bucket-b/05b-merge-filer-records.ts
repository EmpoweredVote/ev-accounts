// 05b-merge-filer-records.ts
// Merges the raw browser_evaluate batch results into money-filer-records.json, ASSERTING the control
// in every batch rather than assuming the fetch worked.
//
// Plan: docs/superpowers/plans/2026-08-16-cal-access-bucket-b.md (Task 5, step 3)
// Run from backend/:  npx tsx scripts/cal-access-bucket-b/05b-merge-filer-records.ts
//
// ⚠ WHY THE CONTROL IS CHECKED PER BATCH, NOT ONCE
// Incapsula returns an EMPTY BODY with a 200 when it challenges, so a blocked batch yields
// `__NOMATCH__len=0` for every id -- which is indistinguishable from "these committees do not exist"
// unless a filer KNOWN to exist is in the same batch. 1414018 (NEWSOM FOR CALIFORNIA GOVERNOR 2022)
// rides along in each batch for exactly that reason. A batch whose control fails is not evidence.
import * as fs from 'fs';
import * as path from 'path';

const DIR = path.join(process.cwd(), 'data', 'cal-access-bucket-b');
const RAW = path.join(DIR, 'raw');
const CONTROL_ID = '1414018';
const CONTROL_NAME = 'NEWSOM FOR CALIFORNIA GOVERNOR 2022';
const FETCHED_AT = '2026-08-16';

const worklist = JSON.parse(fs.readFileSync(path.join(DIR, 'money-worklist.json'), 'utf8'));
const wanted = new Set<string>(worklist.map((r: any) => String(r.filer_id)));

const files = fs.readdirSync(RAW).filter(f => /^raw-batch-\d+\.json$/.test(f)).sort();
if (files.length === 0) { console.error('ERROR: no raw batch files'); process.exit(1); }

const merged: Record<string, string> = {};
let failures = 0;

for (const f of files) {
  const text = fs.readFileSync(path.join(RAW, f), 'utf8');
  // browser_evaluate wrote a JSON *string* for the batches that used the filename option; batch 00
  // was captured inline as a plain object. Accept both.
  let parsed: any = JSON.parse(text);
  if (typeof parsed === 'string') parsed = JSON.parse(parsed);

  const control = parsed[CONTROL_ID];
  if (control !== CONTROL_NAME) {
    console.error(`🔴 ${f}: CONTROL FAILED -- got ${JSON.stringify(control)}. This batch was challenged, not empty. Re-fetch it.`);
    failures++;
    continue;
  }
  let n = 0;
  for (const [id, name] of Object.entries(parsed as Record<string, string>)) {
    if (!wanted.has(id)) continue; // drops the control, which is a Track A keep and not in the 304
    if (merged[id] && merged[id] !== name) {
      console.error(`🔴 ${id}: conflicting names "${merged[id]}" vs "${name}"`);
      failures++;
    }
    merged[id] = name;
    n++;
  }
  console.log(`  ${f}: control OK, ${n} worklist ids`);
}

const missing = [...wanted].filter(id => !(id in merged));
if (missing.length) {
  console.error(`\n🔴 ${missing.length} worklist filer id(s) never fetched: ${missing.join(', ')}`);
  failures++;
}

const out: Record<string, { official_name: string; fetched_at: string; status: string }> = {};
let ok = 0, notFound = 0, errored = 0;
for (const [id, name] of Object.entries(merged)) {
  if (name.startsWith('__ERROR__')) { out[id] = { official_name: '', fetched_at: FETCHED_AT, status: 'error' }; errored++; }
  else if (name.startsWith('__NOMATCH__')) { out[id] = { official_name: '', fetched_at: FETCHED_AT, status: 'not-found' }; notFound++; }
  else { out[id] = { official_name: name, fetched_at: FETCHED_AT, status: 'ok' }; ok++; }
}

fs.writeFileSync(path.join(DIR, 'money-filer-records.json'), JSON.stringify(out, null, 2));
console.log(`\nwrote money-filer-records.json: ${Object.keys(out).length} records`);
console.log(`  ok ${ok} · not-found ${notFound} · error ${errored}`);
console.log(`  worklist filer ids: ${wanted.size}`);

if (failures) { console.error(`\n🔴 ${failures} problem(s). Do NOT classify on this.`); process.exit(1); }
