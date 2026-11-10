#!/usr/bin/env node
// Controls for CC_0380. The gates worth exercising here are the ones that make an AP call
// safe to take: that it lands on the GENERAL and not the June primary, that AP's winner is
// also the top vote-getter, and that AP's incumbent flag, our row and the view all agree.
//
// Usage: node controls380.mjs <path to CC_0380...sql> <path to dry-run-migration.mjs>
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
    name: 'A — a swapped uuid must be caught by the DATABASE row’s name',
    why: 'the name beside a uuid is never used to find the row',
    tamper: (s) => s
      .replace("'43809e67-3447-4ffa-835e-12a567513e7c'::uuid, '172807', 'Nithya Raman'", "'c7e1cbf9-2f5c-4ed1-b82a-056cf755650d'::uuid, '172807', 'Nithya Raman'")
      .replace("'c7e1cbf9-2f5c-4ed1-b82a-056cf755650d'::uuid, '50853',  'Karen Ruth Bass'", "'43809e67-3447-4ffa-835e-12a567513e7c'::uuid, '50853',  'Karen Ruth Bass'"),
    present: (s) => /c7e1cbf9-2f5c-4ed1-b82a-056cf755650d'::uuid, '172807', 'Nithya Raman'/.test(s),
    expect: /a measured name does not match the row it is written against/,
  },
  {
    name: 'B — THE JUNE PRIMARY MUST NOT PASS FOR THE NOVEMBER GENERAL',
    why: 'we hold two Los Angeles mayoral races, and a CC_0379 control already landed on the wrong one',
    // Nithya Raman's and Karen Bass's candidacies in the June 2026 primary
    tamper: (s) => s
      .replace("'43809e67-3447-4ffa-835e-12a567513e7c'::uuid, '172807', 'Nithya Raman'", "'4b01ee54-b812-4a67-9a0e-dfe973c6e3e3'::uuid, '172807', 'Nithya Raman'")
      .replace("'c7e1cbf9-2f5c-4ed1-b82a-056cf755650d'::uuid, '50853',  'Karen Ruth Bass'", "'c13cb353-780a-4cf4-97b5-d0556a09e7cd'::uuid, '50853',  'Karen Ruth Bass'"),
    present: (s) => /4b01ee54-b812-4a67-9a0e-dfe973c6e3e3/.test(s) && /c13cb353-780a-4cf4-97b5-d0556a09e7cd/.test(s),
    // the primary holds 14 candidates, so it trips the "only partly measured" gate first;
    // either refusal is correct and both say the same thing — this is not the general
    expect: /only partly measured|not the 2026-11-03 Los Angeles mayoral general/,
  },
  {
    name: 'C — AP’s winner must also be the top vote-getter',
    why: 'a call and a count are published separately; where both exist they must agree',
    tamper: (s) => s.replace("'Nithya Raman',    579501, 54.46, false, 'won'", "'Nithya Raman',    400000, 45.21, false, 'won'")
      .replace("'Karen Ruth Bass', 484580, 45.54, true,  'lost'", "'Karen Ruth Bass', 484580, 54.79, true,  'lost'"),
    present: (s) => /'Nithya Raman',    400000/.test(s),
    expect: /AP's winner is not the top vote-getter/,
  },
  {
    name: 'D — a percentage that does not follow from its own votes must be refused',
    why: 'two numbers copied from a feed can be copied from different rows of it',
    tamper: (s) => s.replace('579501, 54.46', '579501, 61.00'),
    present: (s) => /579501, 61\.00/.test(s),
    expect: /a percentage does not follow from the votes beside it/,
  },
  {
    name: 'E — AP’s incumbent flag disagreeing with ours must be refused',
    why: 'AP supplies this fact and so does the view; neither comes from this file',
    tamper: (s) => s.replace("'Nithya Raman',    579501, 54.46, false, 'won'", "'Nithya Raman',    579501, 54.46, true, 'won'"),
    present: (s) => /'Nithya Raman',    579501, 54\.46, true, 'won'/.test(s),
    expect: /the incumbent fact disagrees across AP, our row and the view/,
  },
  {
    name: 'F — the incumbent flag moving in the DATABASE must be caught by the view',
    why: 'a tampered file agrees with itself; only an outside fact can contradict it',
    tamper: (s) => inject(s, "UPDATE essentials.race_candidates SET is_incumbent = false WHERE id = 'c7e1cbf9-2f5c-4ed1-b82a-056cf755650d'::uuid;"
      + " UPDATE essentials.race_candidates SET is_incumbent = true WHERE id = '43809e67-3447-4ffa-835e-12a567513e7c'::uuid;"),
    present: (s) => /is_incumbent = true WHERE id = '43809e67/.test(s),
    expect: /the incumbent fact disagrees across AP, our row and the view/,
  },
  {
    name: 'G — a row already carrying a result must not be written over',
    why: 'this file records both prior values as NULL',
    tamper: (s) => inject(s, "UPDATE essentials.race_candidates SET result = 'lost', result_certainty = 'called',"
      + " result_source = 'planted by control G' WHERE id = 'c7e1cbf9-2f5c-4ed1-b82a-056cf755650d'::uuid;"),
    present: (s) => /planted by control G/.test(s),
    expect: /this file only writes over NULL and found a value/,
  },
  {
    name: 'H — a result on a council race must still be refused',
    why: 'AP carries no council contest, so the outstanding-ballot bound still governs those',
    // 🔴 THE REPLACEMENT IS A FUNCTION, NOT A STRING. In String.replace a "$$" in the
    //    replacement inserts ONE literal "$", so writing the post-verify's "DO $$" back as a
    //    string silently produced "DO $" — and the tamper failed on a Postgres syntax error
    //    instead of reaching its gate. A control that dies before its target proves nothing.
    tamper: (s) => s.replace(/^DO \$\$\nDECLARE n int; txt text; total int; flagged int; unflagged int;$/m,
      (m) => "UPDATE essentials.race_candidates SET result = 'won', result_certainty = 'called',"
        + " result_source = 'planted by control H' WHERE id IN ("
        + "  SELECT rc.id FROM essentials.race_candidates rc"
        + "    JOIN essentials.races r ON r.id = rc.race_id"
        + "    JOIN essentials.offices o ON o.id = r.office_id"
        + "    JOIN essentials.elections e ON e.id = r.election_id"
        + "    JOIN essentials.office_swearing_in s2 ON s2.office_id = o.id AND s2.election_date = e.election_date"
        + "   WHERE o.title = 'Council Member' AND s2.swearing_in_date = DATE '2026-12-14' LIMIT 1);\n" + m),
    present: (s) => /planted by control H/.test(s) && /DO \$\$/.test(s),
    expect: /a council race with no caller has acquired a result/,
  },
  {
    name: 'I — the sitting mayor must still hold the seat afterwards',
    why: 'recording a result is not seating anybody; Karen Bass is mayor until 2026-12-14',
    // ⚠ SHADOWED WHEN INJECTED AT BEGIN: ending her term before the pre-checks run trips the
    //   INCUMBENT cross-check first ("the seat is held by (nobody)"), which is a different
    //   gate and an equally correct refusal. To reach the post-verify's holder check the term
    //   has to end AFTER the pre-checks have passed, so the tamper goes in beside control H's.
    tamper: (s) => s.replace(/^DO \$\$\nDECLARE n int; txt text; total int; flagged int; unflagged int;$/m,
      (m) => "UPDATE essentials.office_terms SET term_end = DATE '2026-11-04'"
        + " WHERE office_id = 'b8c4bd9d-05ba-4751-b947-7a3d2645d3ef'::uuid AND term_end IS NULL;\n" + m),
    present: (s) => /term_end = DATE '2026-11-04'/.test(s) && /DO \$\$/.test(s),
    expect: /the sitting mayor is no longer the current holder/,
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

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'cc0380-controls-'));
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
