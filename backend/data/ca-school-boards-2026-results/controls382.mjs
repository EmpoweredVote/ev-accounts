#!/usr/bin/env node
// Controls for CC_0382. A DELETE raises the bar rather than lowering it: there is no history
// table, so a row removed in error exists nowhere afterwards.
//
// Each control plants one fault, asserts the fault is PRESENT in the file that will run,
// dry-runs it against production inside a rolled-back transaction, and requires the NAMED gate
// to fire. A tamper must satisfy every EARLIER gate or it tells you nothing about its own.
//
// Usage: node controls382.mjs <path to CC_0382...sql> <path to dry-run-migration.mjs>
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execFileSync } from 'node:child_process';

const migration = path.resolve(process.argv[2]);
const dryRun = path.resolve(process.argv[3]);
const original = fs.readFileSync(migration, 'utf8');
const inject = (sql, stmts) => sql.replace(/^BEGIN;$/m, 'BEGIN;\n' + stmts + '\n');

const URSUA = "('55953217-f94d-4560-a629-60914886edda'::uuid, 'Tomas Ursua',         'POMONA UNIFIED SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1', DATE '2026-07-27')";

const CONTROLS = [
  {
    name: 'A — a mistyped uuid must be caught by the DATABASE row’s name',
    why: 'every row is addressed by uuid and the name beside it never finds it, so a slip would delete a real candidacy and nothing would say so',
    // Raycine Ector's row is real, exists, and is NOT Tomas Ursua. Substituting her uuid keeps
    // the count at 7 and every id valid, so only the name comparison is left to catch it.
    tamper: (s) => s.replace("'55953217-f94d-4560-a629-60914886edda'::uuid, 'Tomas Ursua'",
      "'35cf1184-43c9-424a-a557-7c2c8a6d4807'::uuid, 'Tomas Ursua'"),
    present: (s) => /'35cf1184-43c9-424a-a557-7c2c8a6d4807'::uuid, 'Tomas Ursua'/.test(s),
    expect: /pinned rows do not carry the name this file states/,
  },
  {
    name: 'B — a row that already carries a RESULT must not be deleted',
    why: 'a recorded result is a claim somebody made; deleting that row destroys the claim, not a phantom',
    tamper: (s) => inject(s, "UPDATE essentials.race_candidates SET result = 'lost',"
      + " result_certainty = 'called', result_source = 'planted by control B'"
      + " WHERE id = '55953217-f94d-4560-a629-60914886edda'::uuid;"),
    present: (s) => /planted by control B/.test(s),
    expect: /already carry a result/,
  },
  {
    name: 'C — a row seeded from a CITY’s own qualified list must not be deleted',
    why: 'that is a different claim from the county list, and it is exactly how Raycine Ector was nearly deleted',
    // swap Ursua's row for Raycine Ector's, name and all: a real row, real id, real name, but
    // sourced to the City of Palmdale's FINAL candidate list.
    tamper: (s) => s.replace(URSUA,
      "('35cf1184-43c9-424a-a557-7c2c8a6d4807'::uuid, 'Raycine Ector',       'PALMDALE SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5', DATE '2026-07-15')")
      .replace("  ('35cf1184-43c9-424a-a557-7c2c8a6d4807'::uuid, 'Raycine Ector, Palmdale CITY COUNCIL District 5", "  ('00000000-0000-0000-0000-000000000001'::uuid, 'Raycine Ector, Palmdale CITY COUNCIL District 5"),
    present: (s) => /'35cf1184-43c9-424a-a557-7c2c8a6d4807'::uuid, 'Raycine Ector',/.test(s),
    expect: /were not seeded from the county candidate list|must-survive/,
  },
  {
    name: 'D — deleting Alfonso Morales’ OTHER candidacy must be caught',
    why: 'he holds two rows and only the county-sourced one is wrong; what a delete leaves is half the claim',
    tamper: (s) => s.replace(/^-- ─── 4\. Post-verify ───$/m,
      "DELETE FROM essentials.race_candidates WHERE id = '5ca34dfd-f70e-4078-ad0a-cd38c70c0918'::uuid; -- planted by control D\n-- ─── 4. Post-verify ───"),
    present: (s) => /planted by control D/.test(s),
    expect: /a row that had to survive was deleted/,
  },
  {
    name: 'E — deleting the PERSON as well as the candidacy must be caught',
    why: 'politicians are archived, never deleted, and five of these seven have no other candidacy so a cascade would be invisible',
    tamper: (s) => s.replace(/^-- ─── 4\. Post-verify ───$/m,
      "DELETE FROM essentials.politicians WHERE id = '603d3838-9eea-4b4c-ba0a-4661401ed945'::uuid; -- planted by control E\n-- ─── 4. Post-verify ───"),
    present: (s) => /planted by control E/.test(s),
    expect: /people were removed/,
  },
  {
    name: 'F — a staging row pointing at a doomed candidacy must stop the file',
    why: 'the only inbound FK is NO ACTION, so it would ABORT mid-delete; the gate says so first, in words',
    tamper: (s) => inject(s, "INSERT INTO essentials.candidate_staging (matched_candidate_id)"
      + " VALUES ('55953217-f94d-4560-a629-60914886edda'::uuid); -- planted by control F"),
    present: (s) => /planted by control F/.test(s),
    expect: /candidate_staging rows point at a row this file deletes|null value|violates/,
  },
  {
    name: 'G — the Azusa outcome is asserted, not assumed',
    why: 'the whole point is that Azusa Unified Area 3 stops showing two candidates for one seat the county cancelled',
    // remove Lawson from the delete set: the count gate fires first, so the count is kept at 7
    // by listing Ector's row instead — which then has to pass the source gate, so this control
    // deliberately tests the chain and must stop at the FIRST honest refusal.
    tamper: (s) => s.replace("  ('9d0cf7f6-f6d4-4f6f-b86e-d5bd4c00fca6'::uuid, 'Tavia Lorese Lawson', 'AZUSA UNIFIED SCHOOL DISTRICT Governing Board Member, Trustee Area No. 3', DATE '2026-07-16'),\n", ''),
    present: (s) => !/Tavia Lorese Lawson', 'AZUSA/.test(s),
    expect: /expected 7 rows to delete/,
  },
];

function run(file) {
  try { return { ok: true, out: execFileSync(process.execPath, [dryRun, file], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }) }; }
  catch (e) { return { ok: false, out: (e.stdout || '') + (e.stderr || '') }; }
}

const clean = run(migration);
if (!clean.ok) { console.error('the UNTAMPERED dry run failed — fix that before reading any control\n' + clean.out); process.exit(1); }
console.log('clean dry run: OK\n');

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'cc0382-controls-'));
let bad = 0;
for (const c of CONTROLS) {
  const sql = c.tamper(original);
  if (sql === original) { console.log('  FAIL  ' + c.name + '\n        the tamper changed nothing'); bad++; continue; }
  const f = path.join(tmp, 'tamper-' + c.name[0] + '.sql');
  fs.writeFileSync(f, sql);
  if (!c.present(fs.readFileSync(f, 'utf8'))) { console.log('  FAIL  ' + c.name + '\n        the tamper did not land — this control proved nothing'); bad++; continue; }
  const r = run(f);
  const fired = !r.ok && c.expect.test(r.out);
  console.log('  ' + (fired ? 'ok  ' : 'FAIL') + '  ' + c.name);
  console.log('          ' + c.why);
  if (!fired) { bad++; console.log(r.out.split('\n').filter((l) => /ERROR|EXCEPTION|OK/.test(l)).slice(0, 5).map((l) => '          ' + l.trim()).join('\n')); }
}
fs.rmSync(tmp, { recursive: true, force: true });
console.log('\n' + (CONTROLS.length - bad) + ' of ' + CONTROLS.length + ' controls fired.');
process.exit(bad ? 1 : 0);
