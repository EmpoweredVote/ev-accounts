import { parse } from 'csv-parse/sync';
import { stringify } from 'csv-stringify/sync';
import { readFileSync, writeFileSync, readdirSync } from 'fs';

// Repair + normalize every CSV in a stance-research dir:
//  - relax-parse (tolerate trailing-comma / column-count artifacts)
//  - keep ONLY the 10 canonical columns
//  - drop rows whose topic_key is NOT in the federal-24 set (e.g. stray data-centers)
//  - drop rows with invalid value (not 1-5) or empty source_url_1
//  - canonical RFC-4180 re-stringify
// Prints per-file: kept / dropped(bad) / dropped(non-fed) / unsourced-remaining.

const DIR = process.argv[2];
if (!DIR) { console.error('usage: _repair_batch.mts <dir>'); process.exit(1); }
const COLS = ['external_id','full_name','topic_key','value','reasoning','source_url_1','source_url_2','source_url_3','quote_text','quote_deidentified'];
const FED24 = new Set(['abortion','ai-regulation','campaign-finance','childcare','civil-rights','climate-change','deportation','fossil-fuels','healthcare','homelessness','housing','immigration','medicare/aid','misinformation','redistricting','religious-freedom','same-sex-marriage','school-vouchers','social-security','tariffs','taxes','trans-athletes','ukraine-support','voting-rights']);

let totKept = 0, totBad = 0, totNonFed = 0, totFiles = 0, totSkipFiles = 0;
for (const f of readdirSync(DIR).filter(x => x.endsWith('.csv'))) {
  const raw = readFileSync(DIR + '/' + f, 'utf8');
  let recs: any[];
  try { recs = parse(raw, { columns: true, skip_empty_lines: true, relax_column_count: true, relax_quotes: true }); }
  catch (e:any) { console.log(`  !! ${f} PARSE FAIL: ${e.message}`); continue; }
  const clean: any[] = [];
  let bad = 0, nonfed = 0;
  for (const r of recs) {
    const tk = (r.topic_key || '').trim().toLowerCase();
    if (!FED24.has(tk)) { nonfed++; continue; }
    const val = (r.value ?? '').toString().trim();
    if (!/^[1-5]$/.test(val)) { bad++; continue; }
    if (!(r.source_url_1 || '').trim()) { bad++; continue; }
    const o: any = {}; for (const c of COLS) o[c] = (r[c] ?? '').toString();
    o.topic_key = tk; o.value = val;
    clean.push(o);
  }
  writeFileSync(DIR + '/' + f, stringify(clean, { header: true, columns: COLS }));
  totKept += clean.length; totBad += bad; totNonFed += nonfed; totFiles++;
  if (clean.length === 0) totSkipFiles++;
  const flag = (bad || nonfed) ? `  (dropped ${bad} bad, ${nonfed} non-fed)` : '';
  console.log(`  ${f}: ${clean.length} rows${flag}${clean.length===0?'  [whole-record skip]':''}`);
}
console.log(`\nTOTAL: ${totFiles} files, ${totKept} rows kept, ${totBad} bad dropped, ${totNonFed} non-fed dropped, ${totSkipFiles} whole-record skips`);
