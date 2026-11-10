#!/usr/bin/env node
// Controls for CC_0378. Same discipline as controls377.mjs: plant one fault, assert it is
// PRESENT in the file that will actually run, dry-run it inside a transaction that rolls
// back, and require the named gate to be the one that fires.
//
// CC_0378 adds three gates CC_0377 did not have, and those are what this file is mostly for:
//   - a RELAXED name key, for the two Inglewood rows where the county prints a middle name
//   - a proof that the relaxation stays one-to-one inside a race
//   - an allowance for the one candidate the county's ballot does not carry, with a staleness
//     gate on the allowance itself
//
// Usage: node controls378.mjs <path to CC_0378...sql> <path to dry-run-migration.mjs>
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
    why: 'the name beside a uuid is never used to find the row, so only the database can contradict it',
    tamper: (s) => s
      .replace("'5b75d9c5-576d-459e-b721-6fd8db0366e1'::uuid, 'SOO YOO'", "'f27b9cdc-8aaa-4608-bb49-4bc731160cd5'::uuid, 'SOO YOO'")
      .replace("'f27b9cdc-8aaa-4608-bb49-4bc731160cd5'::uuid, 'AL BARLEVY'", "'5b75d9c5-576d-459e-b721-6fd8db0366e1'::uuid, 'AL BARLEVY'"),
    present: (s) => /f27b9cdc-8aaa-4608-bb49-4bc731160cd5'::uuid, 'SOO YOO'/.test(s)
      && /5b75d9c5-576d-459e-b721-6fd8db0366e1'::uuid, 'AL BARLEVY'/.test(s),
    expect: /a measured name does not match the row it is written against/,
  },
  {
    name: 'B — the relaxed name key must not be allowed to collapse two people in one race',
    why: 'dropping the middle name is what lets Inglewood match, and it is also how one candidate’s votes could land on another',
    // make two candidates in one race differ only by a middle name
    tamper: (s) => inject(s, "UPDATE essentials.race_candidates SET full_name = 'Soo Middle Yoo'"
      + " WHERE id = 'f27b9cdc-8aaa-4608-bb49-4bc731160cd5'::uuid;")
      .replace("'f27b9cdc-8aaa-4608-bb49-4bc731160cd5'::uuid, 'AL BARLEVY'", "'f27b9cdc-8aaa-4608-bb49-4bc731160cd5'::uuid, 'SOO MIDDLE YOO'"),
    present: (s) => /SOO MIDDLE YOO/.test(s) && /Soo Middle Yoo/.test(s),
    expect: /two candidates in one race share a relaxed name key/,
  },
  {
    name: 'C — the relaxed key must still be proved to relax at all',
    why: 'a key that silently stopped joining the two spellings would send both Inglewood races to gate A',
    tamper: (s) => s.replace(
      "IF pg_temp.shortkey('CHERYL SHAW WILLIAMS') <> pg_temp.shortkey('Cheryl Williams') THEN",
      "IF pg_temp.shortkey('CHERYL SHAW WILLIAMS') = pg_temp.shortkey('Cheryl Williams') THEN"),
    present: (s) => /shortkey\('CHERYL SHAW WILLIAMS'\) = pg_temp\.shortkey/.test(s),
    expect: /the relaxed name key does not join the two spellings it exists for/,
  },
  {
    name: 'D — a margin that no longer clears its bound must be refused',
    why: 'the decisiveness claim is recomputed in the transaction, not taken from a label',
    tamper: (s) => s.replace("'AL BARLEVY', 1992, 2, 'lost'", "'AL BARLEVY', 2700, 2, 'lost'"),
    present: (s) => /'AL BARLEVY', 2700, 2, 'lost'/.test(s),
    expect: /is not decisive against its own bound/,
  },
  {
    name: 'E — an outcome flipped against the votes must be refused',
    why: 'a winner must out-poll every loser in the same race',
    tamper: (s) => s.replace("'SOO YOO', 3373, 1, 'won'", "'SOO YOO', 3373, 1, 'lost'")
      .replace("'AL BARLEVY', 1992, 2, 'lost'", "'AL BARLEVY', 1992, 2, 'won'"),
    present: (s) => /'SOO YOO', 3373, 1, 'lost'/.test(s) && /'AL BARLEVY', 1992, 2, 'won'/.test(s),
    expect: /a loser out-polls a winner/,
  },
  {
    name: 'F — a candidacy dropped from a measured race must be refused',
    why: 'a candidacy missing from the file is a winner that could be hidden',
    tamper: (s) => inject(s, "INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, candidate_status, is_incumbent, source)"
      + " VALUES ('270cd1c6-014b-4969-9b83-24e2911e3e33'::uuid, 'Planted Bycontrolf', 'Planted', 'Bycontrolf', 'active', false, 'planted by control F');"),
    present: (s) => /planted by control F/.test(s),
    expect: /is only partly measured/,
  },
  {
    name: 'G — the not-on-the-ballot allowance must go stale loudly',
    why: 'an exemption that has stopped applying is an exemption with nothing behind it',
    // 🟢 THIS GATE ALREADY FIRED IN ANGER. The first draft of CC_0378 listed all four
    //    candidates the county ballot omits, and three of them sit in races the file never
    //    measures — so three quarters of its own allowance was an exemption for nothing.
    //    The tamper reproduces that: name somebody who IS measured.
    tamper: (s) => s.replace("unnest(ARRAY['Tomas Ursua'])", "unnest(ARRAY['Tomas Ursua', 'Soo Yoo'])"),
    present: (s) => /unnest\(ARRAY\['Tomas Ursua', 'Soo Yoo'\]\)/.test(s),
    expect: /a named not-on-the-ballot exception no longer applies and must be re-read: Soo Yoo/,
  },
  {
    name: 'H — a race already carrying a result must not be written over',
    why: 'this file records every prior value as NULL and may only write over NULL',
    tamper: (s) => inject(s, "UPDATE essentials.race_candidates SET result = 'lost', result_certainty = 'called',"
      + " result_source = 'planted by control H' WHERE id = 'f27b9cdc-8aaa-4608-bb49-4bc731160cd5'::uuid;"),
    present: (s) => /planted by control H/.test(s),
    expect: /this file only writes over NULL and found a value/,
  },
  {
    name: 'I — a result landing on one of the 96 CANCELLED races must be refused',
    why: 'those elections were never held; a result there asserts a contest that did not happen',
    // Azusa Unified Trustee Area 3 is on the county's cancelled list
    tamper: (s) => s.replace(/^-- ─── 4\. Post-verify ───$/m,
      "UPDATE essentials.race_candidates SET result = 'won', result_certainty = 'called',"
      + " result_source = 'planted by control I' WHERE id IN ("
      + "  SELECT rc.id FROM essentials.race_candidates rc"
      + "    JOIN essentials.races r ON r.id = rc.race_id"
      + "    JOIN essentials.offices o ON o.id = r.office_id"
      + "    JOIN essentials.districts d ON d.id = o.district_id"
      + "   WHERE d.label = 'Azusa Unified School Board - Trustee Area 3' LIMIT 1);\n-- ─── 4. Post-verify ───"),
    present: (s) => /planted by control I/.test(s),
    expect: /a race this file holds back has acquired a result/,
  },
  {
    name: 'J — the occupancy drift baseline must be live, not decorative',
    why: 'creating an unseated office raises it, and this file asserts it did not move',
    tamper: (s) => inject(s, "INSERT INTO essentials.offices (title, chamber_id, district_id, is_vacant)"
      + " SELECT 'Planted by control J', o.chamber_id, o.district_id, false FROM essentials.offices o"
      + " JOIN essentials.races r ON r.office_id = o.id"
      + " WHERE r.id = '270cd1c6-014b-4969-9b83-24e2911e3e33'::uuid;"),
    present: (s) => /Planted by control J/.test(s),
    expect: /baseline reads 239, not 238/,
  },
  {
    name: 'K — the incumbent flag moving under the file must be caught by the VIEW',
    why: 'CC_0358 compared it against the file’s own table and a tampered file agrees with itself',
    tamper: (s) => inject(s, "UPDATE essentials.race_candidates rc SET is_incumbent = NOT rc.is_incumbent"
      + " FROM essentials.races r JOIN essentials.office_current_holder och ON och.office_id = r.office_id"
      + " WHERE rc.race_id = r.id AND r.seats = 1 AND rc.politician_id = och.politician_id"
      + "   AND r.id IN (SELECT DISTINCT race_id FROM essentials.race_candidates WHERE id = '5b75d9c5-576d-459e-b721-6fd8db0366e1'::uuid);"),
    present: (s) => /is_incumbent = NOT rc\.is_incumbent/.test(s),
    expect: /the incumbent flag disagrees with who holds the seat/,
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

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'cc0378-controls-'));
let bad = 0;
let ran = 0;
for (const c of CONTROLS) {
  if (c.skip) { console.log(`  --    ${c.name}\n          SKIPPED: ${c.why}`); continue; }
  ran++;
  const sql = c.tamper(original);
  if (sql === original) { console.log(`  FAIL  ${c.name}\n        the tamper changed nothing`); bad++; continue; }
  const f = path.join(tmp, `tamper-${c.name[0]}.sql`);
  fs.writeFileSync(f, sql);
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
console.log(`\n${ran - bad} of ${ran} controls fired.`);
process.exit(bad ? 1 : 0);
