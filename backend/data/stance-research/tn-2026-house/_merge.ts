import { parse } from 'csv-parse/sync';
import { readFileSync, writeFileSync, readdirSync } from 'fs';

const DIR = new URL('.', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const OUT = DIR + '_merged-tn-2026-house.csv';

// Federal-24 topic set (live-DB-verified 2026-07-03; excludes 11 city-only + 8 judicial-* + data-centers)
const FEDERAL = new Set([
  'abortion','ai-regulation','campaign-finance','childcare','civil-rights','climate-change',
  'deportation','fossil-fuels','healthcare','homelessness','housing','immigration',
  'medicare/aid','misinformation','redistricting','religious-freedom','same-sex-marriage',
  'school-vouchers','social-security','tariffs','taxes','trans-athletes','ukraine-support','voting-rights',
]);

// ALL 73 new TN external_ids from 161-06 (band -(47*10000+cd*100+seq)). Excludes all 9
// incumbents (-47001..-47009). This shared set covers BOTH TN stance plans (161-07 = CD1-5,
// 161-09 = CD6-9) so both validate against the same IN_SCOPE.
const IN_SCOPE = new Set([
  -470101, -470102, -470103, -470104, -470105, -470106, -470107, -470108,                     // CD1 (8)
  -470201, -470202, -470203,                                                                  // CD2 (3)
  -470301, -470302, -470303, -470304, -470305, -470306, -470307,                               // CD3 (7)
  -470401, -470402, -470403, -470404, -470405, -470406, -470407, -470408, -470409, -470410,    // CD4 (10)
  -470501, -470502, -470503, -470504, -470505, -470506, -470507, -470508,                      // CD5 (8)
  -470601, -470602, -470603, -470604, -470605, -470606, -470607, -470608, -470609, -470610, -470611, // CD6 (11)
  -470701, -470702, -470703, -470704, -470705, -470706,                                        // CD7 (6)
  -470801, -470802, -470803, -470804, -470805, -470806, -470807, -470808, -470809, -470810,    // CD8 (10)
  -470901, -470902, -470903, -470904, -470905, -470906, -470907, -470908, -470909, -470910,    // CD9 (10)
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
