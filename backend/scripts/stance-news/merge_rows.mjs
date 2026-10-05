// Merge staged rows for ONE politician into a batch's research.csv and evidence.csv.
// Usage: node merge_rows.mjs <batch-dir> <rows.json> [evidence.json]
//
// Why a script: STEP 2 item 4 of the research-stances skill requires exactly one row per
// (full_name, topic_key) — a re-research REPLACES the pair's rows, never appends. Two rows
// cross-verify each other's snippets, so stance-gate flags both `duplicate-row` and the verifier
// exits 2. Doing that by hand over 35 topics is how a duplicate gets in.
//
// It also refuses to write a row whose topic_key is not in the batch's topics.json, which is the
// other way a hand-written row fails late (`topic-out-of-scope` vs a typo are different problems
// and the gate cannot tell you which).
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'csv-parse/sync';
import { stringify } from 'csv-stringify/sync';

const [dir, rowsFile, evFile] = process.argv.slice(2);
if (!dir || !rowsFile) { console.error('usage: merge_rows.mjs <batch-dir> <rows.json> [evidence.json]'); process.exit(1); }

const RHEAD = ['full_name', 'topic_key', 'value', 'evidence_type', 'reasoning', 'source_url_1', 'source_url_2', 'source_url_3', 'quote_text', 'quote_deidentified', 'editor_note'];
const EHEAD = ['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index'];

const readCsv = (f) => fs.existsSync(f) ? parse(fs.readFileSync(f), { columns: true, skip_empty_lines: true }) : [];
const rPath = path.join(dir, 'research.csv');
const ePath = path.join(dir, 'evidence.csv');

const topics = JSON.parse(fs.readFileSync(path.join(dir, 'topics.json'), 'utf8'));
const validKeys = new Set((Array.isArray(topics) ? topics : Object.values(topics)).map((t) => t.topic_key));
const people = JSON.parse(fs.readFileSync(path.join(dir, 'politicians.json'), 'utf8'));
const validNames = new Set((Array.isArray(people) ? people : Object.values(people)).map((p) => p.full_name));

const newRows = JSON.parse(fs.readFileSync(rowsFile, 'utf8'));
const newEv = evFile && fs.existsSync(evFile) ? JSON.parse(fs.readFileSync(evFile, 'utf8')) : [];

const bad = [];
for (const r of newRows) {
  if (!validNames.has(r.full_name)) bad.push(`unknown full_name "${r.full_name}" — politicians.json spelling is required`);
  if (!validKeys.has(r.topic_key)) bad.push(`unknown topic_key "${r.topic_key}" for ${r.full_name}`);
  if (r.value && !r.evidence_type) bad.push(`${r.full_name}/${r.topic_key}: scored row with no evidence_type`);
  if (r.value && !String(r.reasoning || '').trim()) bad.push(`${r.full_name}/${r.topic_key}: scored row with empty reasoning`);
}
// Every evidence URL must be one of that row's own source_url_1..3 (gate: evidence-url-not-cited).
const byPair = new Map(newRows.map((r) => [`${r.full_name}\u0000${r.topic_key}`, r]));
for (const e of newEv) {
  const r = byPair.get(`${e.full_name}\u0000${e.topic_key}`);
  if (!r) { bad.push(`evidence for ${e.full_name}/${e.topic_key} has no matching research row`); continue; }
  const cited = [r.source_url_1, r.source_url_2, r.source_url_3].filter(Boolean);
  if (!cited.includes(e.source_url)) bad.push(`${e.full_name}/${e.topic_key}: evidence URL not cited on the row — ${e.source_url}`);
  const words = String(e.snippet || '').trim().split(/\s+/).length;
  if (words < 25) bad.push(`${e.full_name}/${e.topic_key}: snippet is ${words} words, minimum is 25`);
}
if (bad.length) { console.error('REFUSED — nothing written:\n  ' + bad.join('\n  ')); process.exit(1); }

const pairs = new Set(newRows.map((r) => `${r.full_name}\u0000${r.topic_key}`));
const keptR = readCsv(rPath).filter((r) => !pairs.has(`${r.full_name}\u0000${r.topic_key}`));
const keptE = readCsv(ePath).filter((r) => !pairs.has(`${r.full_name}\u0000${r.topic_key}`));
const outR = [...keptR, ...newRows.map((r) => Object.fromEntries(RHEAD.map((h) => [h, r[h] ?? ''])))];
const outE = [...keptE, ...newEv.map((r) => Object.fromEntries(EHEAD.map((h) => [h, r[h] ?? ''])))];

fs.writeFileSync(rPath, stringify(outR, { header: true, columns: RHEAD }));
fs.writeFileSync(ePath, stringify(outE, { header: true, columns: EHEAD }));
console.log(`research.csv: ${keptR.length} kept + ${newRows.length} written = ${outR.length}`);
console.log(`evidence.csv: ${keptE.length} kept + ${newEv.length} written = ${outE.length}`);
const scored = newRows.filter((r) => String(r.value).trim()).length;
console.log(`replaced ${pairs.size} pair(s); ${scored} scored, ${newRows.length - scored} blank`);
