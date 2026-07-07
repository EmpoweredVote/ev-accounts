import { parse } from 'csv-parse/sync';
import { readFileSync, writeFileSync, readdirSync } from 'fs';

const DIR = new URL('.', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const OUT = DIR + '_merged-ma-2026-house.csv';

// Federal-24 topic set (live-DB-verified 2026-07-04; excludes 11 city-only + 8 judicial-* + data-centers)
const FEDERAL = new Set([
  'abortion','ai-regulation','campaign-finance','childcare','civil-rights','climate-change',
  'deportation','fossil-fuels','healthcare','homelessness','housing','immigration',
  'medicare/aid','misinformation','redistricting','religious-freedom','same-sex-marriage',
  'school-vouchers','social-security','tariffs','taxes','trans-athletes','ukraine-support','voting-rights',
]);

// The 18 new MA external_ids from 161-08 (band -(25*10000+cd*100+seq)). Excludes all 6
// incumbents (-2001..-2009 REUSE-ADD-ROW rows have no assign_external_id) and the
// ALREADY-WIRED-SKIP incumbents Clark (MA-5) and Pressley (MA-7). Moulton (MA-6) retired
// with no incumbent row (open seat) — all 7 MA-6 candidates below are new/in-scope.
const IN_SCOPE = new Set([
  -250101, -250102,                                                              // CD1 (2)
  -250301,                                                                        // CD3 (1)
  -250401, -250402,                                                               // CD4 (2)
  -250501, -250502,                                                               // CD5 (2)
  -250601, -250602, -250603, -250604, -250605, -250606, -250607,                  // CD6 (7, open seat)
  -250801, -250802,                                                               // CD8 (2)
  -250901, -250902,                                                               // CD9 (2)
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
