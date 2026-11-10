#!/usr/bin/env node
// Controls for CC_0379. Small file, same discipline: plant one fault, assert it is PRESENT in
// the file that will run, dry-run it inside a transaction that rolls back, and require the
// named gate to be the one that fires.
//
// The gate this file exists for is the LAST one: three of the four Los Angeles city races are
// held back, and one of them is the mayoralty. A pass that quietly recorded it would look like
// progress.
//
// Usage: node controls379.mjs <path to CC_0379...sql> <path to dry-run-migration.mjs>
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execFileSync } from 'node:child_process';

const migration = path.resolve(process.argv[2]);
const dryRun = path.resolve(process.argv[3]);
const original = fs.readFileSync(migration, 'utf8');
const inject = (sql, stmts) => sql.replace(/^BEGIN;$/m, 'BEGIN;\n' + stmts + '\n');

const CONTROLS = [
  {
    name: 'A — a swapped candidacy uuid must be caught by the DATABASE row’s name',
    why: 'the name beside a uuid is never used to find the row',
    tamper: (s) => s
      .replace("'f7299480-14a2-47f3-86e4-7cde655e442d'::uuid, 'MARISSA ROY'", "'cd54abd9-b430-487b-9e73-e4970c5daa58'::uuid, 'MARISSA ROY'")
      .replace("'cd54abd9-b430-487b-9e73-e4970c5daa58'::uuid, 'JOHN MCKINNEY'", "'f7299480-14a2-47f3-86e4-7cde655e442d'::uuid, 'JOHN MCKINNEY'"),
    present: (s) => /cd54abd9-b430-487b-9e73-e4970c5daa58'::uuid, 'MARISSA ROY'/.test(s),
    expect: /a measured name does not match the row it is written against/,
  },
  {
    name: 'B — the bound must be the CAPPED safety multiple, not the raw one',
    why: 'three times this contest’s share is 147,087, which is more late ballots than exist in the county',
    tamper: (s) => s.replace('3, 131000, 131000)', '3, 131000, 147075)'),
    present: (s) => /3, 131000, 147075\)/.test(s),
    expect: /a bound does not follow from its own inputs/,
  },
  {
    name: 'C — an outcome flipped against the votes must be refused',
    why: 'a winner must out-poll every loser in the same race',
    tamper: (s) => s.replace("'MARISSA ROY', 673463, 1, 'won'", "'MARISSA ROY', 673463, 1, 'lost'")
      .replace("'JOHN MCKINNEY', 313281, 2, 'lost'", "'JOHN MCKINNEY', 313281, 2, 'won'"),
    present: (s) => /'MARISSA ROY', 673463, 1, 'lost'/.test(s),
    expect: /a loser out-polls a winner/,
  },
  {
    name: 'D — a margin inside the bound must be refused',
    why: 'the decisiveness claim is recomputed in the transaction',
    tamper: (s) => s.replace("'JOHN MCKINNEY', 313281, 2, 'lost'", "'JOHN MCKINNEY', 600000, 2, 'lost'"),
    present: (s) => /'JOHN MCKINNEY', 600000, 2, 'lost'/.test(s),
    expect: /is not decisive against its own bound/,
  },
  {
    name: 'E — a candidacy dropped from the race must be refused',
    why: 'a candidacy missing from the file is a winner that could be hidden',
    tamper: (s) => inject(s, "INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, candidate_status, is_incumbent, source)"
      + " VALUES ('7caf9b67-6529-471c-9d8d-3ab29aa1908a'::uuid, 'Planted Bycontrole', 'Planted', 'Bycontrole', 'active', false, 'planted by control E');"),
    present: (s) => /planted by control E/.test(s),
    expect: /the race is only partly measured/,
  },
  {
    name: 'F — a row already carrying a result must not be written over',
    why: 'this file records both prior values as NULL and may only write over NULL',
    tamper: (s) => inject(s, "UPDATE essentials.race_candidates SET result = 'lost', result_certainty = 'called',"
      + " result_source = 'planted by control F' WHERE id = 'cd54abd9-b430-487b-9e73-e4970c5daa58'::uuid;"),
    present: (s) => /planted by control F/.test(s),
    expect: /this file only writes over NULL and found a value/,
  },
  {
    name: 'G — A RESULT ON THE MAYORALTY MUST BE REFUSED',
    why: 'the sitting mayor is 94,921 behind with 131,000 ballots uncounted; that is a lead, not arithmetic',
    // ⚠ A FIRST DRAFT SELECTED "the Mayor row for Nithya Raman, LIMIT 1" AND THE GATE DID NOT
    //   FIRE — correctly. We hold TWO Los Angeles mayoral races: the June 2026 PRIMARY, with
    //   14 candidates and no swearing-in row, and the November general with two. The tamper
    //   landed on the primary, which this wave does not contain, so it never reached the gate
    //   it was written for and would have been read as the gate failing.
    //   ▶ A tamper must reach its target. Address the row by uuid.
    tamper: (s) => s.replace(/^-- ─── 4\. Post-verify ───$/m,
      "UPDATE essentials.race_candidates SET result = 'won', result_certainty = 'called',"
      + " result_source = 'planted by control G'"
      + " WHERE id = '43809e67-3447-4ffa-835e-12a567513e7c'::uuid;\n-- ─── 4. Post-verify ───"),
    present: (s) => /planted by control G/.test(s),
    expect: /a race this file holds back has acquired a result/,
  },
  {
    name: 'H — the occupancy drift baseline must be live, not decorative',
    why: 'creating an unseated office raises it, and this file asserts it did not move',
    tamper: (s) => inject(s, "INSERT INTO essentials.offices (title, chamber_id, district_id, is_vacant)"
      + " SELECT 'Planted by control H', o.chamber_id, o.district_id, false FROM essentials.offices o"
      + " JOIN essentials.races r ON r.office_id = o.id WHERE r.id = '7caf9b67-6529-471c-9d8d-3ab29aa1908a'::uuid;"),
    present: (s) => /Planted by control H/.test(s),
    expect: /baseline reads 239, not 238/,
  },
];

function run(file) {
  try {
    return { ok: true, out: execFileSync(process.execPath, [dryRun, file], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }) };
  } catch (e) {
    return { ok: false, out: (e.stdout || '') + (e.stderr || '') };
  }
}

const clean = run(migration);
if (!clean.ok) { console.error('the UNTAMPERED dry run failed — fix that first\n' + clean.out); process.exit(1); }
console.log('clean dry run: OK\n');

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'cc0379-controls-'));
let bad = 0;
for (const c of CONTROLS) {
  const sql = c.tamper(original);
  if (sql === original) { console.log(`  FAIL  ${c.name}\n        the tamper changed nothing`); bad++; continue; }
  const f = path.join(tmp, `tamper-${c.name[0]}.sql`);
  fs.writeFileSync(f, sql);
  if (!c.present(fs.readFileSync(f, 'utf8'))) { console.log(`  FAIL  ${c.name}\n        the tamper did not land`); bad++; continue; }
  const r = run(f);
  const fired = !r.ok && c.expect.test(r.out);
  console.log(`  ${fired ? 'ok  ' : 'FAIL'}  ${c.name}`);
  console.log(`          ${c.why}`);
  if (!fired) { bad++; console.log(r.out.split('\n').filter((l) => /ERROR|EXCEPTION|OK/.test(l)).slice(0, 5).map((l) => '          ' + l.trim()).join('\n')); }
}
fs.rmSync(tmp, { recursive: true, force: true });
console.log(`\n${CONTROLS.length - bad} of ${CONTROLS.length} controls fired.`);
process.exit(bad ? 1 : 0);
