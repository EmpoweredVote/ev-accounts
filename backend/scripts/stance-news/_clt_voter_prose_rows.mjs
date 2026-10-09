// Charlotte slice 1: two rows address the reviewer in voter-facing prose. Same rule as the MN
// slice (see `_voter_prose_rows.mjs`): `reasoning` publishes verbatim under "Why this position?",
// so strip the bookkeeping and KEEP the caveat. Both of these are real qualifications about the
// evidence — a voter is better off reading them than not.
//
// 🟢 Slices 1 and 2 are far cleaner than slice 3 on this: 2 of 7 scored rows, and only the word
// "reviewer", against 21 of 30 with correction logs and rule codes. Nothing else had to change.
import fs from 'node:fs';
import { parse } from 'csv-parse/sync';

const B = 'data/stance-research/2026-10-02-knight-clt-city';
const NAME = 'Dimple Ajmera';

const EDITS = [
  ['data-centers', [
    ['so a reviewer should weigh that difference.', 'so that difference is worth weighing.'],
  ]],
  ['climate-change', [
    ['Note the scope a reviewer should weigh: the 2030 target', 'One qualification about scope: the 2030 target'],
  ]],
];

const csv = parse(fs.readFileSync(B + '/research.csv'), { columns: true, skip_empty_lines: true });
const ev = parse(fs.readFileSync(B + '/evidence.csv'), { columns: true, skip_empty_lines: true });

const staged = [];
const bad = [];
for (const [topic, pairs] of EDITS) {
  const r = csv.find((x) => x.full_name === NAME && x.topic_key === topic);
  if (!r) { bad.push(`no row ${NAME}/${topic}`); continue; }
  let text = r.reasoning;
  const removed = [];
  for (const [oldS, newS] of pairs) {
    // A replacement that silently no-ops ships bookkeeping to a voter. Refuse instead.
    if (!text.includes(oldS)) { bad.push(`${topic}: source text not found — ${oldS.slice(0, 60)}…`); continue; }
    if (text.split(oldS).length > 2) { bad.push(`${topic}: source text occurs more than once`); continue; }
    text = text.replace(oldS, newS);
    removed.push(oldS);
  }
  staged.push({
    ...r,
    reasoning: text,
    editor_note: (r.editor_note ? r.editor_note + ' ' : '')
      + 'Reviewer bookkeeping moved out of the voter-facing reasoning on 2026-10-06, verbatim: ' + removed.join(' ⏎ '),
  });
}

for (const r of staged) {
  if (/\breviewer\b/i.test(r.reasoning)) bad.push(`${r.topic_key}: voter prose still says "reviewer"`);
  if (/[🔴⚠▶🟢✅]/u.test(r.reasoning)) bad.push(`${r.topic_key}: a glyph survives`);
  if (!/\bchair\b/i.test(r.reasoning)) bad.push(`${r.topic_key}: no longer names a chair`);
  const orig = csv.find((x) => x.full_name === NAME && x.topic_key === r.topic_key).reasoning;
  if (Math.abs(r.reasoning.length - orig.length) > 40) bad.push(`${r.topic_key}: length moved by more than 40 chars`);
  console.log(`${(NAME + '/' + r.topic_key).padEnd(40)} ${orig.length} -> ${r.reasoning.length}`);
}

// merge_rows deletes the evidence of any pair it replaces; the citations here do not change.
const evRows = staged.flatMap((r) => ev.filter((e) => e.full_name === NAME && e.topic_key === r.topic_key));
for (const r of staged) {
  for (const u of [r.source_url_1, r.source_url_2, r.source_url_3].filter(Boolean)) {
    if (!evRows.some((e) => e.topic_key === r.topic_key && e.source_url === u)) bad.push(`lost the snippet for ${u} on ${r.topic_key}`);
  }
}
if (bad.length) { console.error('REFUSED — nothing written:\n  ' + bad.join('\n  ')); process.exit(1); }

fs.writeFileSync(B + '/_rows/clt-voter-prose-rows.json', JSON.stringify(staged, null, 1));
fs.writeFileSync(B + '/_rows/clt-voter-prose-evidence.json', JSON.stringify(evRows, null, 1));
console.log(`staged ${staged.length} rows, ${evRows.length} evidence rows carried forward`);
