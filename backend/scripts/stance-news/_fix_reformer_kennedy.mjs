// Upgrade Janet Kennedy's Reformer coverage sentence. Usage: node _fix_reformer_kennedy.mjs [--apply]
//
// Her rows say "Minnesota Reformer could not be searched and is not covered by this count." That was
// true when written: the run was rate-limited and the closing control refused to record a zero.
// It has since been searched properly — controls passed at BOTH ends (10 links open, 10 at close),
// 5 candidates fetched, none naming her. So the honest sentence is now the one Randorf, Durrwachter
// and Nephew carry: searched, and it added nothing.
//
// ⚠ Reinert is deliberately NOT touched. His retry failed its opening control, so for him the
// sentence remains correct. A genuine zero and a throttled zero look identical in a log and mean
// opposite things; only the control tells them apart.
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'csv-parse/sync';
import { stringify } from 'csv-stringify/sync';

const DIR = 'data/stance-research/2026-10-04-knight-mn-cities';
const APPLY = process.argv.includes('--apply');
// Both Duluth retries have now run with controls passing at BOTH ends of the run:
//   Kennedy — 5 candidates fetched, 0 naming her.   Reinert — 126 fetched, 0 naming him.
// Reformer's total yield across all six Duluth members is one article, Forsman's. That is a
// measured finding about a statewide outlet's Duluth coverage, not an absence of effort.
const OLD = 'Minnesota Reformer could not be searched and is not covered by this count.';
const FIX = {
  'Janet Kennedy': 'Minnesota Reformer was searched separately and added no article naming her.',
  'Roger J. Reinert': 'Minnesota Reformer was searched separately and added no article naming him.',
};

const rPath = path.join(DIR, 'research.csv');
const rows = parse(fs.readFileSync(rPath), { columns: true, skip_empty_lines: true });

// Positive control first, per member: the sentence must be there, in the number expected.
let total = 0;
for (const who of Object.keys(FIX)) {
  const n = rows.filter((r) => r.full_name === who && (r.reasoning || '').includes(OLD)).length;
  console.log(`CONTROL ${who}: rows carrying the old sentence: ${n}`);
  total += n;
}
if (!total) { console.error('CONTROL FAILED: nothing matched. Wrong string, not a clean file.'); process.exit(2); }

let changed = 0;
for (const r of rows) {
  const neu = FIX[r.full_name];
  if (!neu) continue;
  if (!(r.reasoning || '').includes(OLD)) continue;
  r.reasoning = r.reasoning.replace(OLD, neu);
  changed++;
}
console.log(`rewrote ${changed} row(s)`);

const stillOld = rows.filter((r) => FIX[r.full_name] && (r.reasoning || '').includes(OLD)).length;
const gotNew = rows.filter((r) => FIX[r.full_name] && (r.reasoning || '').includes(FIX[r.full_name])).length;
const pronoun = rows.filter((r) => r.full_name === 'Roger J. Reinert' && /added no article naming her/.test(r.reasoning || '')).length;
console.log(`CLOSING: rows still carrying the old sentence = ${stillOld} (want 0)`);
// ⚠ `gotNew` counts rows ALREADY fixed in an earlier run as well as this one — Kennedy's 19 were
// applied before Reinert's retry finished — so comparing it to `changed` is wrong and this check
// failed against correct data. The invariants that actually matter: nothing keeps the old
// sentence, and no row carries the other member's pronoun.
console.log(`CLOSING: rows carrying their new sentence = ${gotNew} (this run changed ${changed}; the rest were already applied)`);
console.log(`CLOSING: Reinert rows wrongly saying "her" = ${pronoun} (want 0)`);
if (stillOld || gotNew < changed || pronoun) { console.error('refusing to write'); process.exit(3); }

if (!APPLY) { console.log('(dry run - pass --apply)'); process.exit(0); }
const HEAD = ['full_name', 'topic_key', 'value', 'evidence_type', 'reasoning', 'source_url_1', 'source_url_2', 'source_url_3', 'quote_text', 'quote_deidentified', 'editor_note'];
fs.writeFileSync(rPath, stringify(rows, { header: true, columns: HEAD }));
console.log(`wrote ${rPath}`);
