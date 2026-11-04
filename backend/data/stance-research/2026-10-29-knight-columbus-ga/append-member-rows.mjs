// Batch helper that wrote this ledger: appends one member's rows to research.csv and evidence.csv.
// Replaces only the (person, topic) pairs a run writes — never the person's other rows — per the
// one-row-per-pair rule in the research-stances skill. Refuses a name that is not in
// politicians.json, a snippet under 25 words, and a source URL with no snippet.
//   node append-member-rows.mjs "<full_name>" <rows.json> <snippets.json>
import fs from 'node:fs';
// This batch's worktree has no node_modules of its own, and ESM resolves a bare specifier from the
// SCRIPT's directory, not the cwd — so running this from the main checkout does not help. Resolve
// the bare name first (correct wherever deps are installed) and fall back to the main checkout's
// copy, naming it in the error if neither is there. Do NOT plant a node_modules junction here:
// `git worktree remove` deletes through one, and it has emptied the main checkout twice.
const MAIN_CHECKOUT = 'file:///C:/EV-Accounts/backend/node_modules/';
async function csvModule(pkg, esmPath) {
  try { return await import(`${pkg}/sync`); }
  catch { return await import(`${MAIN_CHECKOUT}${pkg}/${esmPath}`); }
}
const { parse } = await csvModule('csv-parse', 'dist/esm/sync.js');
const { stringify } = await csvModule('csv-stringify', 'dist/esm/sync.js');

const DIR = 'C:/ev-accounts-columbus/backend/data/stance-research/2026-10-29-knight-columbus-ga/';
const NAME = process.argv[2];
const rows = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
const snips = JSON.parse(fs.readFileSync(process.argv[4], 'utf8'));
if (!NAME) { console.error('usage: node _member-append.mjs "<full_name>" <rows.json> <snippets.json>'); process.exit(1); }

const research = parse(fs.readFileSync(DIR + 'research.csv'), { columns: true, skip_empty_lines: true });
const evidence = parse(fs.readFileSync(DIR + 'evidence.csv'), { columns: true, skip_empty_lines: true });

const people = JSON.parse(fs.readFileSync(DIR + 'politicians.json', 'utf8'));
if (!people.some(p => p.full_name === NAME)) { console.error('NOT IN politicians.json: ' + NAME); process.exit(1); }

const touched = new Set(rows.map(r => r.topic_key));
// Replace only the (person, topic) pairs this run writes — never the person's other rows.
const resKept = research.filter(r => !(r.full_name === NAME && touched.has(r.topic_key)));
const evKept = evidence.filter(r => !(r.full_name === NAME && touched.has(r.topic_key)));

for (const r of rows) {
  resKept.push({
    full_name: NAME, topic_key: r.topic_key, value: r.value, evidence_type: r.evidence_type,
    reasoning: r.reasoning,
    source_url_1: r.sources[0] || '', source_url_2: r.sources[1] || '', source_url_3: r.sources[2] || '',
    quote_text: '', quote_deidentified: '', editor_note: '',
  });
}

for (const r of rows) {
  const list = snips.filter(s => s.topic === r.topic_key);
  if (!list.length) { if (r.value === '' && r.sources.length === 0) { console.log(r.topic_key + ': 0 evidence row(s) (sourceless blank)'); continue; } console.error('NO SNIPPETS for ' + r.topic_key); process.exit(1); }
  const covered = new Set(list.map(s => s.url));
  for (const u of r.sources) if (!covered.has(u)) { console.error('SOURCE WITH NO SNIPPET: ' + r.topic_key + ' -> ' + u); process.exit(1); }
  let i = 0;
  for (const s of list) {
    if (!r.sources.includes(s.url)) { console.error('EVIDENCE URL NOT IN ROW SOURCES: ' + r.topic_key + ' -> ' + s.url); process.exit(1); }
    const words = s.snippet.trim().split(/\s+/).length;
    if (words < 25) { console.error('SNIPPET UNDER 25 WORDS (' + words + '): ' + r.topic_key); process.exit(1); }
    evKept.push({ full_name: NAME, topic_key: r.topic_key, source_url: s.url, snippet: s.snippet, snippet_index: String(++i) });
  }
  console.log(r.topic_key + ': ' + i + ' evidence row(s)');
}

fs.writeFileSync(DIR + 'research.csv', stringify(resKept, { header: true, columns: Object.keys(resKept[0]) }));
fs.writeFileSync(DIR + 'evidence.csv', stringify(evKept, { header: true, columns: ['full_name','topic_key','source_url','snippet','snippet_index'] }));
console.log('research.csv rows=' + resKept.length + '  evidence.csv rows=' + evKept.length);
