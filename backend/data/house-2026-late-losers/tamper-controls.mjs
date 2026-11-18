// The fifteen controls behind the table in LOSERS.md §"The third branch", so they re-run rather
// than being believed. Each one plants ONE fault in an INPUT -- AP's ballot for A-J, our own rows
// for K and L -- and the matcher is then run on it and watched going red.
//
// 🔴 A TAMPER THAT DID NOT APPLY IS A CONTROL THAT PROVED NOTHING, AND IT LOOKS LIKE A PASS.
//    Every builder below throws unless the edit it meant to make is PRESENT in the file it
//    writes. On 2026-10-26 a `sed` that built a tamper failed on a quoting error, left a 0-byte
//    file, and the dry run reported OK on it -- an empty input passes every gate it does not
//    contain.
//
// 🔴 CHANGE ONE THING PER TAMPER. A tamper that trips three assertions at once says the suite is
//    alive but not which guard holds which claim.
//
//   node tamper-controls.mjs              # run all fifteen and print the verdict each one moves
//   node tamper-controls.mjs --only B     # one control, with the matcher's full output
//
// No database and no dependencies: both inputs are committed beside this file.

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const AP = path.join(HERE, 'ap-ballots-2026-11-17.json');
const OURS = path.join(HERE, 'before-values.json');
const MATCHER = path.join(HERE, 'match-losers.mjs');
const TMP = fs.mkdtempSync(path.join(os.tmpdir(), 'tamper-controls-'));

const only = (() => { const i = process.argv.indexOf('--only'); return i === -1 ? null : process.argv[i + 1]; })();

const raceIn = (ap, seat) => {
  const r = ap.races.find((x) => x.seat === seat);
  if (!r) throw new Error(`no race ${seat} in the AP capture`);
  return r;
};
const rowIn = (ours, nameFragment, want) => {
  const r = ours.rows.find((x) => (x.full_name ?? '').includes(nameFragment)
                                 && (want === undefined || x.is_incumbent === want));
  if (!r) throw new Error(`no row matching "${nameFragment}" (is_incumbent=${want}) in our rows`);
  return r;
};

// Each control declares which input it edits and what it expects to move.
const CONTROLS = {
  A:  { input: 'ap', expect: 'CA-04 -> incumbency_disputed',
        note: "CA-04's incumbent id only, name kept: the test is an ID test",
        edit: (ap) => { raceIn(ap, 'CA-04').ap_incumbent.candidate_id = '999999'; } },
  A2: { input: 'ap', expect: 'CA-23 -> incumbency_disputed',
        note: 'same, where the colliding name belongs to the WINNING line',
        edit: (ap) => { raceIn(ap, 'CA-23').ap_incumbent.candidate_id = '999999'; } },
  B:  { input: 'ap', expect: 'ME-02 -> incumbent_defeated',
        note: 'Golden actually on the ballot and losing: the world CC_0447 assumed',
        edit: (ap) => { raceIn(ap, 'ME-02').all_lines.push({ candidate_id: '66383', first: 'Jared',
                          last: 'Golden', votes: 1, pct: 0, winner: false, ballot_order: 9 }); } },
  C:  { input: 'ap', expect: 'CA-23 -> incumbent_defeated',
        note: "CA-23's win moved off the incumbent",
        edit: (ap) => { const r = raceIn(ap, 'CA-23');
                        r.all_lines.find((l) => l.candidate_id === '67998').winner = false;
                        r.all_lines.find((l) => l.candidate_id === '172565').winner = true; } },
  D:  { input: 'ap', expect: 'NC-07 -> no_incumbent_published, no claim',
        note: 'AP publishes no incumbent for the seat',
        edit: (ap) => { delete raceIn(ap, 'NC-07').ap_incumbent; } },
  E:  { input: 'ap', expect: 'CO-04 -> not_called, no claim',
        note: 'nobody has won it yet',
        edit: (ap) => { raceIn(ap, 'CO-04').all_lines.find((l) => l.winner).winner = false; } },
  F:  { input: 'ap', expect: 'CO-04 -> multiple_winner_lines, no claim',
        note: 'two winning lines',
        edit: (ap) => { raceIn(ap, 'CO-04').all_lines
                          .find((l) => l.candidate_id === '68897').winner = true; } },
  G:  { input: 'ap', expect: '0 race(s) examined -- the blank sheet',
        note: 'nothing to examine: read the COUNT, not the verdict',
        edit: (ap) => { ap.races = []; } },
  H:  { input: 'ap', expect: 'CA-23 -> paired_incumbents',
        note: 'a redistricting pairing: two incumbents, one of them on the losing line',
        edit: (ap) => { const r = raceIn(ap, 'CA-23');
                        r.ap_incumbent = [r.ap_incumbent,
                          { candidate_id: '172565', first: 'Tessa', last: 'Hodge' }]; } },
  I:  { input: 'ap', expect: 'ME-02 verdict SURVIVES the shape change',
        note: "the federal `incumbents: [{apCandidateID, name}]` spelling",
        edit: (ap) => { const r = raceIn(ap, 'ME-02');
                        r.incumbents = [{ apCandidateID: r.ap_incumbent.candidate_id,
                          name: `${r.ap_incumbent.first} ${r.ap_incumbent.last}` }];
                        delete r.ap_incumbent; } },
  I2: { input: 'ap', expect: 'CA-04 verdict SURVIVES the shape change',
        note: 'the same spelling reaching the DEFEATED branch, not only the absent one',
        edit: (ap) => { const r = raceIn(ap, 'CA-04');
                        r.incumbents = [{ apCandidateID: r.ap_incumbent.candidate_id,
                          name: `${r.ap_incumbent.first} ${r.ap_incumbent.last}` }];
                        delete r.ap_incumbent; } },
  I3: { input: 'ap', expect: 'CA-04 -> incumbent_not_on_ballot',
        note: "the array's id is COMPARED, not merely present -- the negative half of I and I2",
        edit: (ap) => { const r = raceIn(ap, 'CA-04');
                        r.incumbents = [{ apCandidateID: '999999', name: 'Nobody Atall' }];
                        delete r.ap_incumbent; } },
  J:  { input: 'ap', expect: 'ME-02 claim turns plural',
        note: 'two incumbents, both off the ballot',
        edit: (ap) => { const r = raceIn(ap, 'ME-02');
                        r.ap_incumbent = [r.ap_incumbent,
                          { candidate_id: '66384', first: 'Chellie', last: 'Pingree' }]; } },
  K:  { input: 'ours', expect: 'cross-check RED on ME-02',
        note: "our rows flag Dunlap as ME-02's incumbent, against AP's empty ballot",
        edit: (ours) => { rowIn(ours, 'Dunlap').is_incumbent = true; } },
  L:  { input: 'ours', expect: 'cross-check RED on CA-04',
        note: 'our rows stop flagging Thompson, whom AP puts on the ballot as the incumbent',
        edit: (ours) => { rowIn(ours, 'Thompson', true).is_incumbent = false; } },
};

const run = (letter) => {
  const c = CONTROLS[letter];
  const srcPath = c.input === 'ap' ? AP : OURS;
  const before = fs.readFileSync(srcPath, 'utf8');
  const doc = JSON.parse(before);
  c.edit(doc);
  const after = JSON.stringify(doc, null, 2) + '\n';
  if (after === before) throw new Error(`control ${letter}: TAMPER DID NOT APPLY -- file unchanged`);
  const dest = path.join(TMP, `${letter}-${c.input}.json`);
  fs.writeFileSync(dest, after);

  const out = execFileSync(process.execPath, [MATCHER,
    '--ap', c.input === 'ap' ? dest : AP,
    '--ours', c.input === 'ours' ? dest : OURS,
    '--out', TMP], { encoding: 'utf8' });
  return { out, bytes: `${before.length} -> ${after.length}` };
};

// The untampered run, so each control is reported as a DIFFERENCE from it rather than as a
// screenful that the reader has to compare by eye.
const baselineOut = execFileSync(process.execPath,
  [MATCHER, '--ap', AP, '--ours', OURS, '--out', TMP], { encoding: 'utf8' });
const seatLines = (out) => new Map(out.split('\n').map((l) => l.replace(/\s+$/, ''))
  .map((l) => [/^ {2}([A-Z]{2}-\d+)\s/.exec(l)?.[1], l]).filter(([k]) => k));
const BASELINE = { ap: seatLines(baselineOut), ours: seatLines(baselineOut) };
if (BASELINE.ap.size === 0) throw new Error('baseline run classified no seats -- nothing to compare against');
console.log(`baseline: ${BASELINE.ap.size} seat(s) classified, untampered`);

const letters = only ? [only] : Object.keys(CONTROLS);
let failed = 0;
for (const letter of letters) {
  if (!CONTROLS[letter]) { console.error(`unknown control ${letter}`); process.exit(2); }
  const c = CONTROLS[letter];
  try {
    const { out, bytes } = run(letter);
    if (only) { console.log(`control ${letter} (${c.input}, ${bytes}) -- ${c.note}\n`); console.log(out); continue; }
    console.log(`\n${letter.padEnd(3)} ${c.note}\n    expect: ${c.expect}`);
    const lines = out.split('\n').map((l) => l.replace(/\s+$/, ''));
    const base = BASELINE[c.input === 'ap' ? 'ap' : 'ours'];
    for (const l of lines) {
      const seat = /^ {2}([A-Z]{2}-\d+)\s/.exec(l);
      if (seat) {
        // Print a seat line only where this control CHANGED it, so the one thing that moved is
        // the one thing on screen. A control that moved nothing prints nothing here, and says so.
        if (base.get(seat[1]) !== l) console.log(`    MOVED ${l.trim()}`);
        continue;
      }
      if (/race\(s\) examined|🔴|disagreement\(s\)/.test(l)) console.log(`    ${l.trim()}`);
    }
  } catch (e) {
    failed += 1;
    console.log(`\n${letter.padEnd(3)} 🔴 CONTROL FAILED TO BUILD OR RUN: ${e.message}`);
  }
}
if (!only) console.log(`\n${letters.length} control(s) attempted, ${failed} failed to run.`);
process.exit(failed ? 1 : 0);
