// Correct TWO false claims in the rows of the three Saint Paul members who are not being
// re-researched: Bowie, Jost and Cheniqua Johnson. Usage: node _fix_stpaul_three.mjs [--apply]
//
// 1. MINNESOTA REFORMER was named as an outlet the sweep covered. It supplied zero articles to
//    every corpus in this slice (it refuses node fetch at the TLS layer; outlets.md has the
//    working). Their Reformer backfill has not run yet, so the honest statement is that the
//    outlet is NOT covered — the same rule outlets.md sets for MPR News and Racket.
//
// 2. 🔴 THE BIGGER ONE: each row claims every article naming the member was read. A truncated
//    corpus-key overwrote files before they could be read, so the claim was never true:
//       Bowie    32 named, 28 saved — overstated by 4
//       Jost     21 named, 16 saved — overstated by 5
//       Johnson  27 named, 20 saved — overstated by 7
//    ⚠ THIS DOCUMENTS THE LOSS, IT DOES NOT REPAIR IT. The repair is to read the recovered
//    articles, which is re-research. These three were deliberately excluded from that, so the
//    rows now state honestly what they rest on.
//
// 🔴 `reasoning` IS VOTER-FACING. "Were never saved by the sweep and could not be read" is a
// plain statement about evidentiary strength. The tooling detail stays in outlets.md.
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'csv-parse/sync';
import { stringify } from 'csv-stringify/sync';

const DIR = 'data/stance-research/2026-10-04-knight-mn-cities';
const APPLY = process.argv.includes('--apply');
const REFORMER_OLD = 'MinnPost and Sahan Journal (WordPress REST API) and Minnesota Reformer (site search)';
const REFORMER_NEW = 'MinnPost and Sahan Journal (WordPress REST API)';
const NOT_COVERED = ' Minnesota Reformer could not be searched and is not covered by this count.';

// Each entry: the exact clause to replace, and its replacement. Expected row count is asserted.
const FIX = {
  'Anika Bowie': { rows: 19, edits: [[
    'returned 33 unique articles, 32 of which name Anika Bowie as a phrase, and every passage quoting her directly beside a speech verb was read - 10 of them.',
    'returned 33 unique articles, 32 of which name Anika Bowie as a phrase. Four of those 32 were never saved by the sweep and could not be read, so this blank rests on the 28 that were, and every passage in them quoting her directly beside a speech verb was read - 10 of them.',
  ]] },
  'Saura Jost': { rows: 19, edits: [[
    'returned 21 unique articles, every one of which names Saura Jost as a phrase, and every passage quoting her directly beside a speech verb was read - 13 of them.',
    'returned 21 unique articles, every one of which names Saura Jost as a phrase. Five of them were never saved by the sweep and could not be read, so this blank rests on the 16 that were, and every passage in them quoting her directly beside a speech verb was read - 13 of them.',
  ]] },
  'Cheniqua Johnson': { rows: 19, edits: [
    [
      'returned 27 articles naming Cheniqua Johnson as a phrase.',
      'returned 27 articles naming Cheniqua Johnson as a phrase. Seven of them were never saved by the sweep and could not be read, so this blank rests on the 20 that were.',
    ],
    [
      'and every passage in the remaining 22 that quotes her beside a speech verb was read',
      'and every remaining saved article was read for passages that quote her beside a speech verb',
    ],
  ] },
};

const rPath = path.join(DIR, 'research.csv');
const rows = parse(fs.readFileSync(rPath), { columns: true, skip_empty_lines: true });

// 🔴 POSITIVE CONTROL FIRST, PER CLAUSE. A replacement that was never going to match reports a
// clean sweep for free, so every clause must be shown to match the expected number of rows before
// anything is written.
let fail = false;
for (const [name, spec] of Object.entries(FIX)) {
  const mine = rows.filter((r) => r.full_name === name);
  const ref = mine.filter((r) => (r.reasoning || '').includes(REFORMER_OLD)).length;
  console.log(`CONTROL ${name}: ${mine.length} rows | reformer clause in ${ref}`);
  if (ref !== spec.rows) { console.error(`  🔴 expected ${spec.rows}`); fail = true; }
  for (const [old] of spec.edits) {
    const n = mine.filter((r) => (r.reasoning || '').includes(old)).length;
    console.log(`     clause "${old.slice(0, 54)}…" matches ${n}`);
    if (n !== spec.rows) { console.error(`  🔴 expected ${spec.rows} — the clause text has drifted`); fail = true; }
  }
}
if (fail) { console.error('\n🔴 CONTROL FAILED — refusing to write.'); process.exit(2); }

const touched = [];
for (const r of rows) {
  const spec = FIX[r.full_name];
  if (!spec) continue;
  let t = r.reasoning || '';
  // Only the SEARCHED blanks carry the sweep description. The 16 scope blanks per member are
  // facts about Minnesota law, name no outlet, and must not be touched.
  if (!t.includes(REFORMER_OLD)) continue;
  for (const [old, neu] of spec.edits) t = t.replace(old, neu);
  t = t.replace(REFORMER_OLD, REFORMER_NEW);
  // All three carry the existing uncovered-outlet note; the Reformer note belongs beside it.
  if (t.includes('MPR News and Racket could not be searched')) {
    t = t.replace('MPR News and Racket could not be searched', `${NOT_COVERED.trim()} MPR News and Racket could not be searched`);
  } else {
    t += NOT_COVERED;
  }
  r.reasoning = t;
  touched.push(r);
}
console.log(`\nrewrote ${touched.length} row(s)`);

// 🔴 CLOSING CONTROLS, SCOPED TO THE ROWS ACTUALLY REWRITTEN. The first draft of these was wrong
// three different ways and reported 97/48/19 failures against correct edits: it counted members
// this script does not touch, counted scope-blank rows that legitimately name no outlet, and used
// a substring test that a replacement CONTAINING its own original always trips. A control that
// cries wolf is as useless as one that never fires — assert on the rewritten set only, and assert
// the NEW text is present rather than that the old text is absent.
const stillRef = touched.filter((r) => r.reasoning.includes(REFORMER_OLD)).length;
const notOnce = touched.filter((r) => r.reasoning.split('Minnesota Reformer').length - 1 !== 1).length;
const missingNew = touched.filter((r) => !FIX[r.full_name].edits.every(([, neu]) => r.reasoning.includes(neu))).length;
const untouchedOk = rows.filter((r) => FIX[r.full_name] && !touched.includes(r))
  .every((r) => !(r.reasoning || '').includes('Minnesota Reformer'));
console.log(`CLOSING CONTROL: rewritten rows keeping the old outlet clause = ${stillRef} (want 0)`);
console.log(`CLOSING CONTROL: rewritten rows not naming Reformer exactly once = ${notOnce} (want 0)`);
console.log(`CLOSING CONTROL: rewritten rows missing a replacement = ${missingNew} (want 0)`);
console.log(`CLOSING CONTROL: untouched rows of these three name no outlet = ${untouchedOk ? 'yes' : '🔴 NO'}`);
if (stillRef || notOnce || missingNew || !untouchedOk) { console.error('🔴 refusing to write'); process.exit(3); }

if (!APPLY) { console.log('\n(dry run — pass --apply to write research.csv)'); process.exit(0); }
const HEAD = ['full_name', 'topic_key', 'value', 'evidence_type', 'reasoning', 'source_url_1', 'source_url_2', 'source_url_3', 'quote_text', 'quote_deidentified', 'editor_note'];
fs.writeFileSync(rPath, stringify(rows, { header: true, columns: HEAD }));
console.log(`wrote ${rPath}`);
