#!/usr/bin/env node
// Positive controls for CC_0435, which DELETES six race rows. A delete raises the bar, so the
// two gates that matter most are "nobody is lost" and "everything that hung off the row arrived
// on the canonical one". Both are tampered here and both must go red.
//
// ⚠ ONE GATE WAS ALREADY WATCHED FIRING FOR REAL and is not re-tampered: the first draft of
// CC_0435 tried to LINK these races to their offices, and
// `races_election_office_party_uniq` refused it — which is how the duplicates were found at all.
// The database caught the wrong fix before any data moved.
//
// Usage (from backend/):  node data/transition-tracker/controls-cc0435.mjs <migration.sql>
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const SRC = process.argv[2]
  ?? 'C:/ev-accounts-tracker/backend/migrations/CC_0435_merge_duplicate_statewide_exec_races.sql';
const original = readFileSync(SRC, 'utf8');
const work = mkdtempSync(join(tmpdir(), 'cc0435-controls-'));

function tamper(name, find, replace) {
  if (!original.includes(find)) { console.error(`FATAL [${name}]: text not found:\n${find}`); process.exit(2); }
  const t = original.replace(find, replace);
  if (t === original) { console.error(`FATAL [${name}]: replacement was a no-op.`); process.exit(2); }
  const p = join(work, `${name}.sql`);
  writeFileSync(p, t);
  if (readFileSync(p, 'utf8') === original) { console.error(`FATAL [${name}]: tamper did not land.`); process.exit(2); }
  return p;
}
const run = p => {
  try { return { ok: true, out: execFileSync('node', ['scripts/dry-run-migration.mjs', p], { encoding: 'utf8' }) }; }
  catch (e) { return { ok: false, out: `${e.stdout ?? ''}${e.stderr ?? ''}` }; }
};

const AFTER_BEGIN = 'BEGIN;\n\nCREATE TEMP TABLE cc0435_dupes';
const MOVE_QUESTIONS = `UPDATE essentials.readrank_questions q
   SET race_id = d.canonical_race
  FROM cc0435_dupes d WHERE q.race_id = d.duplicate_race;`;

const CONTROLS = [
  {
    name: 'A-nobody-lost',
    gate: 'PREMISE — no candidate exists on a duplicate and not on its canonical race',
    // Put Tina Kotek on the MARYLAND governor duplicate. She is on Oregon's canonical race, not
    // Maryland's, so she would be destroyed by the delete. This is the defect the gate exists for.
    find: AFTER_BEGIN,
    replace: `BEGIN;

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, candidate_status)
VALUES ('8c67c58e-f3a7-4822-bbbf-eb426ac13f87'::uuid,
        '66c3bd97-94d1-4287-b1b8-86605a38cb97'::uuid, 'Tina Kotek', 'active');

CREATE TEMP TABLE cc0435_dupes`,
    expect: /exist on a duplicate and NOT on its canonical race/i,
  },
  {
    name: 'B-preservation',
    gate: 'POST-VERIFY — the ReadRank questions arrived on the canonical race',
    // 🔴 THE ONE THAT MATTERS. Drop the move, so the DELETE's cascade eats all 16 authored
    // questions. Every other gate still passes: six rows still go, no person is lost, the
    // winners are intact, and the blocked bucket still empties. Only a gate that counts what
    // SURVIVED can see it — a gate on the delete's own row count would read this as perfect.
    find: MOVE_QUESTIONS,
    replace: '-- (move removed by control B)',
    expect: /ReadRank question\(s\) were attached to the duplicates and 0 are on the canonical races/i,
  },
  {
    name: 'C-result-not-lost',
    gate: 'PREMISE — no duplicate candidacy carries a result or a photo',
    find: AFTER_BEGIN,
    // ⚠ `result` must carry a `result_source`: the schema's own
    //   `race_candidates_result_needs_source` check refuses the bare UPDATE, so the first
    //   version of this control died on a constraint instead of reaching the gate. A tamper that
    //   cannot be applied tests nothing.
    replace: `BEGIN;

UPDATE essentials.race_candidates
   SET result = 'won', result_source = 'control C tamper', result_certainty = 'called'
 WHERE race_id = 'b8f82dc8-4f6c-41da-904a-ec8cceb73321'::uuid;

CREATE TEMP TABLE cc0435_dupes`,
    expect: /duplicate candidacy\/ies carry a result or a photo/i,
  },
];

let failures = 0;
console.log(`CC_0435 controls — ${SRC}\n`);
const base = run(SRC);
console.log(`[baseline] untampered: ${base.ok ? 'GREEN' : 'RED'}`);
if (!base.ok) { console.error(base.out); process.exit(1); }

for (const c of CONTROLS) {
  const res = run(tamper(c.name, c.find, c.replace));
  const fired = !res.ok && c.expect.test(res.out);
  console.log(`\n[${c.name}]\n  gate   : ${c.gate}\n  result : ${fired ? 'RED (correct)' : res.ok ? 'GREEN — CONTROL FAILED' : 'RED, WRONG GATE'}`);
  if (fired) console.log(`  message: ${res.out.split('\n').find(l => c.expect.test(l))?.trim()}`);
  else { failures++; console.log(res.out.trim().split('\n').map(l => '  ' + l).join('\n')); }
}

console.log(`\n${failures === 0
  ? 'ALL CONTROLS FIRED ON THEIR OWN GATE.'
  : `${failures} CONTROL(S) DID NOT FIRE — do not trust this migration's green.`}`);
process.exit(failures === 0 ? 0 : 1);
