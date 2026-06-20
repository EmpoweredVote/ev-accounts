import { parse } from 'csv-parse/sync';
import { readFileSync, writeFileSync, readdirSync } from 'fs';

const DIR = new URL('.', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const OUT = 'C:/EV-Accounts/backend/data/stance-research/2026-06-20-ne-house.csv';

const FEDERAL = new Set([
  'abortion','ai-regulation','campaign-finance','childcare','civil-rights','climate-change',
  'data-centers','deportation','fossil-fuels','healthcare','homelessness','housing','immigration',
  'medicare/aid','misinformation','redistricting','religious-freedom','same-sex-marriage',
  'school-vouchers','social-security','tariffs','taxes','trans-athletes','ukraine-support','voting-rights',
]);
const IN_SCOPE = new Set([-31001,-31002,-31003]);
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
const perRep: Record<string, number> = {};
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
    if (!IN_SCOPE.has(ext)) problems.push(`${where}: bad external_id '${r.external_id}'`);
    if (!FEDERAL.has((r.topic_key || '').toLowerCase())) problems.push(`${where}: bad topic_key '${r.topic_key}'`);
    const val = parseInt(r.value);
    if (!(val >= 1 && val <= 5)) problems.push(`${where}: bad value '${r.value}'`);
    if (!(r.reasoning || '').trim()) problems.push(`${where}: empty reasoning`);
    const srcs = [r.source_url_1, r.source_url_2, r.source_url_3].map((s) => (s || '').trim()).filter(Boolean);
    if (!srcs.some((s) => /^https?:\/\//i.test(s))) problems.push(`${where}: no http source`);
    perRep[ext] = (perRep[ext] || 0) + 1;
    allRows.push(r);
  }
}

const lines = [COLS.join(',')];
for (const r of allRows) lines.push(COLS.map((c) => esc(r[c])).join(','));
writeFileSync(OUT, lines.join('\n') + '\n', 'utf8');

console.log(JSON.stringify({
  files: files.length,
  total_rows: allRows.length,
  per_rep: Object.fromEntries(Object.entries(perRep).sort((a,b)=>Number(b[0])-Number(a[0]))),
  reps_with_rows: Object.keys(perRep).length,
  problems: problems.length ? problems : 0,
  out: OUT,
}, null, 2));
