#!/usr/bin/env node
// Controls for CC_0377. Each one plants a single fault, asserts the fault is PRESENT in the
// file that will actually run, dry-runs it against production inside a transaction that is
// rolled back, and requires the named gate to be the one that fires.
//
// 🔴 A TAMPER MUST LEAVE EVERYTHING ELSE CORRECT. Seven times in this programme a tamper
//   tripped an EARLIER gate than the one under test, which proves the suite is alive and
//   nothing about the guard you meant to exercise.
// 🔴 SOME GATES READ THE DATABASE, NOT THE FILE, so their tamper is an extra statement
//   injected after BEGIN. The dry run rolls back, so production never sees it.
//
// Usage: node controls377.mjs <path to CC_0377...sql> <path to dry-run-migration.mjs>
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execFileSync } from 'node:child_process';

const migration = path.resolve(process.argv[2]);
const dryRun = path.resolve(process.argv[3]);
const original = fs.readFileSync(migration, 'utf8');

// statements injected straight after the file's BEGIN; -- they are part of the same
// transaction the dry run rolls back
const inject = (sql, stmts) => sql.replace(/^BEGIN;$/m, 'BEGIN;\n' + stmts + '\n');

const CONTROLS = [
  {
    name: 'A — a swapped candidacy uuid must be caught by the DATABASE row’s name',
    why: 'every row is addressed by uuid and the name beside it is never used to find it',
    tamper: (s) => s
      .replace("'90fba149-a000-4bfd-95ec-ac1f514784e9'::uuid, 'THERESA LEE'", "'cc72fd2a-6595-45ef-969f-eb9ae65debf4'::uuid, 'THERESA LEE'")
      .replace("'cc72fd2a-6595-45ef-969f-eb9ae65debf4'::uuid, 'KENNY SHU'", "'90fba149-a000-4bfd-95ec-ac1f514784e9'::uuid, 'KENNY SHU'"),
    present: (s) => /cc72fd2a-6595-45ef-969f-eb9ae65debf4'::uuid, 'THERESA LEE'/.test(s)
      && /90fba149-a000-4bfd-95ec-ac1f514784e9'::uuid, 'KENNY SHU'/.test(s),
    expect: /a measured name does not match the row it is written against/,
  },
  {
    name: 'B — a margin that no longer clears its bound must be refused',
    why: 'the decisiveness claim is recomputed inside the transaction, not taken from a label',
    // Foothill Division 5: Razavian 2301 -> 2400 leaves a margin of 886 against a bound of 915.
    // Still second, still 'lost', still below the winner: only decisiveness changes.
    tamper: (s) => s.replace("'NOOSHA RAZAVIAN', 2301, 2, 'lost'", "'NOOSHA RAZAVIAN', 2400, 2, 'lost'"),
    present: (s) => /'NOOSHA RAZAVIAN', 2400, 2, 'lost'/.test(s),
    expect: /is not decisive against its own bound/,
  },
  {
    name: 'C — an outcome flipped against the votes must be refused',
    why: 'a winner must out-poll every loser in the same race',
    tamper: (s) => s
      .replace("'JOHN VRSALOVICH', 3379, 1, 'won'", "'JOHN VRSALOVICH', 3379, 1, 'lost'")
      .replace("'TOM MAJICH', 1934, 2, 'lost'", "'TOM MAJICH', 1934, 2, 'won'"),
    present: (s) => /'JOHN VRSALOVICH', 3379, 1, 'lost'/.test(s) && /'TOM MAJICH', 1934, 2, 'won'/.test(s),
    expect: /a loser out-polls a winner/,
  },
  {
    name: 'D — more winners than the race has seats must be refused',
    why: 'the seat count comes from races.seats and never from the number 1',
    tamper: (s) => s.replace("'ALEC HYELER', 1101, 4, 'lost'", "'ALEC HYELER', 1101, 4, 'won'"),
    present: (s) => /'ALEC HYELER', 1101, 4, 'won'/.test(s),
    expect: /records the wrong number of winners/,
  },
  {
    name: 'E — a bound that does not follow from its own inputs must be refused',
    why: 'a number typed beside an estimate is not a bound derived from it',
    tamper: (s) => s.replace("'a1fafd45-51ee-595b-9270-7df24563512e'::uuid,   992,   43, 3,   129)",
      "'a1fafd45-51ee-595b-9270-7df24563512e'::uuid,   992,   43, 3,    99)"),
    present: (s) => /992,   43, 3,    99\)/.test(s),
    expect: /a bound does not follow from its own inputs/,
  },
  {
    name: 'F — a race already carrying a result must not be written over',
    why: 'this file records every prior value as NULL and may only write over NULL',
    tamper: (s) => inject(s, "UPDATE essentials.race_candidates SET result = 'lost', result_certainty = 'called',"
      + " result_source = 'planted by control F' WHERE id = '2c9f901e-4a80-4098-bf37-226d074911ae'::uuid;"),
    present: (s) => /planted by control F/.test(s),
    expect: /this file only writes over NULL and found a value/,
  },
  {
    name: 'G — the incumbent flag moving under the file must be caught by the VIEW',
    why: 'CC_0358 compared it against the file’s own table and a tampered file agrees with itself',
    // move the flag off the sitting Foothill Division 2 director onto his challenger
    tamper: (s) => inject(s, "UPDATE essentials.race_candidates SET is_incumbent = false WHERE id = '3f7e3ada-73da-4d04-85a5-47b797081932'::uuid;\n"
      + "UPDATE essentials.race_candidates SET is_incumbent = true WHERE id = '3e6fc72f-0dab-4956-878b-e8ac5ed6d448'::uuid;"),
    present: (s) => /is_incumbent = true WHERE id = '3e6fc72f/.test(s),
    expect: /the incumbent flag disagrees with who holds the seat/,
  },
  {
    name: 'H — a race measured only in part must be refused',
    why: 'a candidacy missing from the file is a winner that could be hidden',
    // give Crescenta Valley a fifth candidacy in the database, so the file holds 4 of 5
    tamper: (s) => inject(s, "INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, candidate_status, is_incumbent, source)"
      + " VALUES ('27d5eab3-f128-5eee-b2a7-62a1732448d1'::uuid, 'Planted Bycontrolh', 'Planted', 'Bycontrolh', 'active', false, 'planted by control H');"),
    present: (s) => /planted by control H/.test(s),
    expect: /is only partly measured/,
  },
  {
    name: 'I — the occupancy drift baseline must be live, not decorative',
    why: 'creating an unseated office raises it, and this file asserts it did not move',
    // an office with no office_terms row lands in offices_missing_terms, unflagged
    tamper: (s) => inject(s, "INSERT INTO essentials.offices (title, chamber_id, district_id, is_vacant)"
      + " SELECT 'Planted by control I', o.chamber_id, o.district_id, false FROM essentials.offices o"
      + " WHERE o.id = '7d5d8326-6dfa-54ec-aae4-023a985c3560'::uuid;"),
    present: (s) => /Planted by control I/.test(s),
    expect: /baseline reads 239, not 238/,
  },
  {
    name: 'J — a result landing on one of the ten held-back races must be refused',
    why: 'those are the contests whose margin nobody has bounded',
    // Altadena Trustee Area 3 is held back; write a result to it after the file’s own UPDATE
    tamper: (s) => s.replace(/^-- ─── 4\. Post-verify ───$/m,
      "UPDATE essentials.race_candidates SET result = 'won', result_certainty = 'called',"
      + " result_source = 'planted by control J' WHERE id = '8073a4b0-8a3a-483d-a7c8-e2d1cfd833e4'::uuid;\n-- ─── 4. Post-verify ───"),
    present: (s) => /planted by control J/.test(s),
    expect: /a race this file holds back has acquired a result/,
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
if (!clean.ok) { console.error('the UNTAMPERED dry run failed — fix that before reading any control\n' + clean.out); process.exit(1); }
console.log('clean dry run: OK\n');

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'cc0377-controls-'));
let bad = 0;
for (const c of CONTROLS) {
  const sql = c.tamper(original);
  if (sql === original) { console.log(`  FAIL  ${c.name}\n        the tamper changed nothing`); bad++; continue; }
  const f = path.join(tmp, `tamper-${c.name[0]}.sql`);
  fs.writeFileSync(f, sql);
  // 🔴 assert the tamper is in the file that will run. A sed that matched nothing once left a
  //   0-byte migration and the dry run reported DRY RUN OK on it.
  if (!c.present(fs.readFileSync(f, 'utf8'))) { console.log(`  FAIL  ${c.name}\n        the tamper did not land — this control proved nothing`); bad++; continue; }
  const r = run(f);
  const fired = !r.ok && c.expect.test(r.out);
  console.log(`  ${fired ? 'ok  ' : 'FAIL'}  ${c.name}`);
  console.log(`          ${c.why}`);
  if (!fired) {
    bad++;
    console.log(r.out.split('\n').filter((l) => /ERROR|error|EXCEPTION|OK/.test(l)).slice(0, 6).map((l) => '          ' + l.trim()).join('\n'));
  }
}
fs.rmSync(tmp, { recursive: true, force: true });
console.log(`\n${CONTROLS.length - bad} of ${CONTROLS.length} controls fired.`);
process.exit(bad ? 1 : 0);
