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
//
// ── 🔑 THE FILER PAGE CARRIES THREE FIELDS, NOT ONE (found 2026-08-16, Task 6) ────────────────────
// The first pass read only the SUMMARY INFORMATION name and concluded that 26 links were unprovable
// because that name has no given name in it. Two further fields on the same page settle many of them:
//   · (OFFICEHOLDER: ASSEMBLY DISTRICT 42) -- the seat the committee's officeholder actually holds
//   · HISTORICAL NAMES FOR THIS COMMITTEE  -- earlier registered names, which routinely DO carry the
//     given name Cal-Access later dropped
// Jacqui Irwin's "IRWIN FOR LIEUTENANT GOVERNOR 2030" is the worked example: no given name and an
// office she does not hold, so it read as a $60,380 guess -- while the same page says
// "OFFICEHOLDER: ASSEMBLY DISTRICT 42" and "IRWIN FOR LT. GOVERNOR 2030; JACQUI".
// `rich-batch-*.json` carries all three; `raw-batch-*.json` is the name-only first pass, kept as
// provenance. Rich batches win where both exist.
import * as fs from 'fs';
import * as path from 'path';

const DIR = path.join(process.cwd(), 'data', 'cal-access-bucket-b');
const RAW = path.join(DIR, 'raw');
const CONTROL_ID = '1414018';
const CONTROL_NAME = 'NEWSOM FOR CALIFORNIA GOVERNOR 2022';
const FETCHED_AT = '2026-08-16';

const worklist = JSON.parse(fs.readFileSync(path.join(DIR, 'money-worklist.json'), 'utf8'));
const wanted = new Set<string>(worklist.map((r: any) => String(r.filer_id)));

type Rec = { name: string; officeholder: string; historical: string[] };
const merged: Record<string, Rec> = {};
let failures = 0;

function loadBatches(prefix: string, rich: boolean) {
  const files = fs.readdirSync(RAW).filter(f => new RegExp(`^${prefix}-\\d+\\.json$`).test(f)).sort();
  for (const f of files) {
    let parsed: any = JSON.parse(fs.readFileSync(path.join(RAW, f), 'utf8'));
    if (typeof parsed === 'string') parsed = JSON.parse(parsed);

    const controlName = rich ? parsed[CONTROL_ID]?.name : parsed[CONTROL_ID];
    if (controlName !== CONTROL_NAME) {
      console.error(`🔴 ${f}: CONTROL FAILED -- got ${JSON.stringify(controlName)}. That batch was challenged, not empty. Re-fetch it.`);
      failures++;
      continue;
    }
    let n = 0;
    for (const [id, v] of Object.entries(parsed as Record<string, any>)) {
      if (!wanted.has(id)) continue; // drops the control, a Track A keep and not one of the 304
      const rec: Rec = rich
        ? { name: String(v.name ?? ''), officeholder: String(v.officeholder ?? ''), historical: Array.isArray(v.historical) ? v.historical : [] }
        : { name: String(v), officeholder: '', historical: [] };
      if (!rich && merged[id]) { n++; continue; }   // never let the name-only pass overwrite a rich one
      if (merged[id] && merged[id].name !== rec.name) {
        console.error(`🔴 ${id}: conflicting names "${merged[id].name}" vs "${rec.name}"`);
        failures++;
      }
      merged[id] = rec;
      n++;
    }
    console.log(`  ${f}: control OK, ${n} worklist ids`);
  }
}

loadBatches('rich-batch', true);
loadBatches('raw-batch', false);

const missing = [...wanted].filter(id => !(id in merged));
if (missing.length) {
  console.error(`\n🔴 ${missing.length} worklist filer id(s) never fetched: ${missing.join(', ')}`);
  failures++;
}

const out: Record<string, any> = {};
let ok = 0, notFound = 0, errored = 0, withOh = 0, withHist = 0;
for (const [id, rec] of Object.entries(merged)) {
  const base = { fetched_at: FETCHED_AT, officeholder: rec.officeholder, historical: rec.historical };
  if (rec.name.startsWith('__ERROR__')) { out[id] = { official_name: '', status: 'error', ...base }; errored++; }
  else if (rec.name.startsWith('__NOMATCH__')) { out[id] = { official_name: '', status: 'not-found', ...base }; notFound++; }
  else { out[id] = { official_name: rec.name, status: 'ok', ...base }; ok++; }
  if (rec.officeholder) withOh++;
  if (rec.historical.length) withHist++;
}

fs.writeFileSync(path.join(DIR, 'money-filer-records.json'), JSON.stringify(out, null, 2));
console.log(`\nwrote money-filer-records.json: ${Object.keys(out).length} records`);
console.log(`  ok ${ok} · not-found ${notFound} · error ${errored}`);
console.log(`  with an OFFICEHOLDER line: ${withOh} · with HISTORICAL names: ${withHist}`);
console.log(`  worklist filer ids: ${wanted.size}`);

if (failures) { console.error(`\n🔴 ${failures} problem(s). Do NOT classify on this.`); process.exit(1); }
