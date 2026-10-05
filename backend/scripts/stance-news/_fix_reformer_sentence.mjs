// Correct the Minnesota Reformer coverage claim in the six Duluth members' rows.
// Usage: node _fix_reformer_sentence.mjs [--apply]
//
// Every Duluth row says the sweep covered "MinnPost, Sahan Journal and Minnesota Reformer".
// Reformer supplied ZERO articles to every corpus in this slice, because it refuses node's fetch
// at the TLS layer while accepting curl — the 403 was swallowed and the outlet looked searched.
// (Full working: outlets.md.) The sentence was false for 109 Duluth rows.
//
// 🔴 `reasoning` IS VOTER-FACING. The replacement says what was and was not covered, in plain
// words. The TLS explanation stays in outlets.md and in the commit message, where it belongs.
//
// Reformer has since been swept over curl. Four members completed; Reinert and Kennedy were
// rate-limited (HTTP 429) and their closing control refused to record a zero, so for those two the
// honest sentence is that the outlet is NOT covered — the same rule outlets.md sets for MPR News
// and Racket. Re-run this after their backfill lands to upgrade those two.
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'csv-parse/sync';
import { stringify } from 'csv-stringify/sync';

const DIR = 'data/stance-research/2026-10-04-knight-mn-cities';
const APPLY = process.argv.includes('--apply');

const OLD = 'together with MinnPost, Sahan Journal and Minnesota Reformer,';
const NEW = 'together with MinnPost and Sahan Journal,';
const ANCHOR = /(returned [\d,]+ unique articles\. )/;

// What Reformer actually contributed, measured by sweep_reformer.mjs (curl) on 2026-10-05.
const REFORMER = {
  'Roz Randorf':       'Minnesota Reformer was searched separately and added no article naming her. ',
  'Wendy Durrwachter': 'Minnesota Reformer was searched separately and added no article naming her. ',
  'Arik Forsman':      'Minnesota Reformer was searched separately and added one article naming him. ',
  'Lynn Marie Nephew': 'Minnesota Reformer was searched separately and added no article naming her. ',
  'Roger J. Reinert':  'Minnesota Reformer could not be searched and is not covered by this count. ',
  'Janet Kennedy':     'Minnesota Reformer could not be searched and is not covered by this count. ',
};

const rPath = path.join(DIR, 'research.csv');
const rows = parse(fs.readFileSync(rPath), { columns: true, skip_empty_lines: true });

// 🔴 POSITIVE CONTROL FIRST: the string must actually be there, in the number expected, or the
// "0 remaining" result afterwards means nothing. A detector that was never going to match returns
// a clean sweep for free.
const before = rows.filter((r) => REFORMER[r.full_name] && (r.reasoning || '').includes(OLD));
console.log(`CONTROL: rows carrying the old clause = ${before.length}`);
const byName = {};
for (const r of before) byName[r.full_name] = (byName[r.full_name] || 0) + 1;
for (const [k, v] of Object.entries(byName)) console.log(`   ${k.padEnd(20)} ${v}`);
if (!before.length) { console.error('🔴 CONTROL FAILED: the clause matched nothing. Wrong string — not a clean file.'); process.exit(2); }

let changed = 0, noAnchor = [];
for (const r of rows) {
  const add = REFORMER[r.full_name];
  if (!add) continue;
  const t = r.reasoning || '';
  if (!t.includes(OLD)) continue;
  let next = t.replace(OLD, NEW);
  if (ANCHOR.test(next)) next = next.replace(ANCHOR, `$1${add}`);
  else { noAnchor.push(`${r.full_name}/${r.topic_key}`); next = next.replace(NEW, `${NEW} ${add.trim()}`); }
  r.reasoning = next;
  changed++;
}
console.log(`\nrewrote ${changed} row(s)`);
if (noAnchor.length) console.log(`⚠ ${noAnchor.length} row(s) lacked the "returned N unique articles." anchor; sentence appended after the outlet list instead:\n   ${noAnchor.slice(0, 5).join(', ')}${noAnchor.length > 5 ? ' …' : ''}`);

// Closing controls: the false clause must be gone, and the new sentence must be present exactly
// once per rewritten row.
const stillOld = rows.filter((r) => (r.reasoning || '').includes(OLD)).length;
const dupes = rows.filter((r) => REFORMER[r.full_name] && (r.reasoning || '').split('Minnesota Reformer').length - 1 > 1);
console.log(`CLOSING CONTROL: rows still carrying the old clause = ${stillOld} (want 0)`);
console.log(`CLOSING CONTROL: rows naming Reformer more than once = ${dupes.length} (want 0)`);
if (stillOld || dupes.length) { console.error('🔴 refusing to write'); process.exit(3); }

if (!APPLY) { console.log('\n(dry run — pass --apply to write research.csv)'); process.exit(0); }
const HEAD = ['full_name', 'topic_key', 'value', 'evidence_type', 'reasoning', 'source_url_1', 'source_url_2', 'source_url_3', 'quote_text', 'quote_deidentified', 'editor_note'];
fs.writeFileSync(rPath, stringify(rows, { header: true, columns: HEAD }));
console.log(`wrote ${rPath}`);
