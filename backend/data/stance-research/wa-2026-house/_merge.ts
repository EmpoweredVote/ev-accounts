import { parse } from 'csv-parse/sync';
import { readFileSync, writeFileSync, readdirSync } from 'fs';

const DIR = new URL('.', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const OUT = DIR + '_merged-wa-2026-house.csv';

// Federal-24 topic set (live-DB-verified 2026-07-03; excludes 11 city-only + 8 judicial-* + data-centers)
const FEDERAL = new Set([
  'abortion','ai-regulation','campaign-finance','childcare','civil-rights','climate-change',
  'deportation','fossil-fuels','healthcare','homelessness','housing','immigration',
  'medicare/aid','misinformation','redistricting','religious-freedom','same-sex-marriage',
  'school-vouchers','social-security','tariffs','taxes','trans-athletes','ukraine-support','voting-rights',
]);

// The ~60 new WA external_ids from 161-04 (band -(53*10000+cd*100+seq)). Excludes all 10 incumbents (-53001..-53010).
const IN_SCOPE = new Set([
  -530101, -530102, -530103, -530104, -530105, -530106,                                  // CD1 (6)
  -530201, -530202, -530203,                                                              // CD2 (3)
  -530301, -530302, -530303, -530304, -530305, -530306, -530307, -530308,                 // CD3 (8)
  -530401, -530402, -530403, -530404, -530405, -530406, -530407, -530408, -530409, -530410, -530411, // CD4 (11)
  -530501, -530502, -530503, -530504, -530505, -530506, -530507, -530508, -530509, -530510, -530511, // CD5 (11)
  -530601, -530602, -530603, -530604,                                                     // CD6 (4)
  -530701, -530702, -530703,                                                              // CD7 (3)
  -530801, -530802, -530803, -530804, -530805,                                            // CD8 (5)
  -530901, -530902, -530903, -530904,                                                     // CD9 (4)
  -531001, -531002, -531003, -531004, -531005,                                            // CD10 (5)
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
