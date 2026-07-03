import { parse } from 'csv-parse/sync';
import { readFileSync, writeFileSync, readdirSync } from 'fs';

const DIR = new URL('.', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const OUT = DIR + '_merged-az-2026-house.csv';

// Federal-24 topic set (live-DB-verified 2026-07-03; excludes 11 city-only + 8 judicial-* + data-centers)
const FEDERAL = new Set([
  'abortion','ai-regulation','campaign-finance','childcare','civil-rights','climate-change',
  'deportation','fossil-fuels','healthcare','homelessness','housing','immigration',
  'medicare/aid','misinformation','redistricting','religious-freedom','same-sex-marriage',
  'school-vouchers','social-security','tariffs','taxes','trans-athletes','ukraine-support','voting-rights',
]);

// The 32 new AZ external_ids from 161-02 (band -(4*10000+cd*100+seq)). Excludes all 9 incumbents (-4001..-4009).
const IN_SCOPE = new Set([
  -40101, -40102, -40103, -40104, -40105, -40106, -40107, -40108, -40109, -40110, // CD1 (10)
  -40201, -40202, -40203,                                                         // CD2 (3)
  -40301,                                                                          // CD3 (1)
  -40401, -40402, -40403, -40404, -40405,                                          // CD4 (5)
  -40501, -40502, -40503, -40504, -40505, -40506,                                  // CD5 (6)
  -40601, -40602, -40603,                                                          // CD6 (3)
  -40701,                                                                          // CD7 (1)
  -40801, -40802,                                                                  // CD8 (2)
  -40901,                                                                          // CD9 (1)
]);

const COLS = ['external_id','full_name','topic_key','value','reasoning','source_url_1','source_url_2','source_url_3','quote_text','quote_deidentified'];

function repair(raw: string): string {
  // Only collapse genuine quad+ quote artifacts (malformed). NEVER touch triple quotes —
  // `"""text"""` is VALID RFC-4180 for a literal-quoted field. csv-parse relax_quotes handles the rest.
  return raw.replace(/"""""+/g, '"""').replace(/""""/g, '"""');
}
function esc(v: string): string {
  const s = (v ?? '').toString();
  return /[",\n\r]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
}

const files = readdirSync(DIR).filter((f) => f.endsWith('.csv') && !f.startsWith('_'));
const problems: string[] = [];
const perCand: Record<string, number> = {};
const allRows: Record<string, string>[] = [];

for (const f of files.sort()) {
  let recs: any[];
  try {
    recs = parse(repair(readFileSync(DIR + '/' + f, 'utf8')), {
      columns: true, skip_empty_lines: true, relax_quotes: true, relax_column_count: true, trim: true,
    });
  } catch (e: any) { problems.push(`${f}: PARSE FAIL ${e.message}`); continue; }
  for (let i = 0; i < recs.length; i++) {
    const r = recs[i]; const where = `${f}#${i + 2}`;
    const ext = parseInt(r.external_id);
    if (!IN_SCOPE.has(ext)) { problems.push(`${where}: bad/out-of-scope external_id '${r.external_id}'`); continue; }
    if (!FEDERAL.has((r.topic_key || '').toLowerCase())) { problems.push(`${where}: bad topic_key '${r.topic_key}'`); continue; }
    const val = parseInt(r.value);
    if (!(val >= 1 && val <= 5)) { problems.push(`${where}: bad value '${r.value}'`); continue; }
    if (!(r.reasoning || '').trim()) { problems.push(`${where}: empty reasoning`); continue; }
    const srcs = [r.source_url_1, r.source_url_2, r.source_url_3].map((s) => (s || '').trim()).filter(Boolean);
    if (!srcs.some((s) => /^https?:\/\//i.test(s))) { problems.push(`${where}: no http source`); continue; }
    perCand[ext] = (perCand[ext] || 0) + 1;
    allRows.push(r);
  }
}

const lines = [COLS.join(',')];
for (const r of allRows) lines.push(COLS.map((c) => esc(r[c])).join(','));
writeFileSync(OUT, lines.join('\n') + '\n', 'utf8');

console.log(JSON.stringify({
  files: files.length,
  total_rows: allRows.length,
  per_candidate: Object.fromEntries(Object.entries(perCand).sort((a,b)=>Number(b[0])-Number(a[0]))),
  candidates_with_rows: Object.keys(perCand).length,
  in_scope_total: IN_SCOPE.size,
  problems: problems.length ? problems : 0,
  out: OUT,
}, null, 2));
