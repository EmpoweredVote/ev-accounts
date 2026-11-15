#!/usr/bin/env node
// Positive controls for CC_0434. Each plants ONE fault and requires the migration to RAISE with
// the message that gate owns. A gate with no control of its own is untested however many
// controls the file has, so each entry names the gate it must fire on.
//
// ⚠ TWO OF THIS MIGRATION'S GATES WERE ALREADY WATCHED FIRING FOR REAL during development and
// are not re-tampered here:
//   · `seat_officeholder`'s own re-election guard refused the first run outright — most of these
//     people already hold the seat, which is what an uncontested filing usually means.
//   · The "already the CURRENT holder" gate fired on 9 rows and was WRONG to: `term_start IS
//     NULL` is an earlier term, and a NULL never satisfies `< DATE`. The members were right and
//     the comparison was not. That is recorded because a control that has only ever passed
//     proves nothing, and this one proved the opposite of what it claimed.
//
// Usage (from backend/):  node data/ca-2026-swearing-in/controls-cc0434.mjs <migration.sql>
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const SRC = process.argv[2]
  ?? 'C:/ev-accounts-tracker/backend/migrations/CC_0434_la_school_boards_appointed_in_lieu_2026_12_11.sql';
const original = readFileSync(SRC, 'utf8');
const work = mkdtempSync(join(tmpdir(), 'cc0434-controls-'));

// The VALUES rows of the seatings table — the handles every tamper below needs.
const rowRe = /^ {4}\('([0-9a-f-]{36})'::uuid, '[0-9a-f-]{36}'::uuid, .*\),?$/gm;
const rows = [...original.matchAll(rowRe)];
if (rows.length < 2) { console.error('FATAL: could not find two seatings VALUES rows.'); process.exit(2); }
const firstRow = [rows[0][0]];
const firstOffice = rows[0][1];
const secondRowText = rows[1][0];
const secondOffice = rows[1][1];

function tamper(name, find, replace) {
  if (!original.includes(find)) { console.error(`FATAL [${name}]: text not found.`); process.exit(2); }
  const t = original.replace(find, replace);
  if (t === original) { console.error(`FATAL [${name}]: replacement was a no-op.`); process.exit(2); }
  const p = join(work, `${name}.sql`);
  writeFileSync(p, t);
  const back = readFileSync(p, 'utf8');
  if (back === original) { console.error(`FATAL [${name}]: tamper did not land on disk.`); process.exit(2); }
  return p;
}

const run = p => {
  try { return { ok: true, out: execFileSync('node', ['scripts/dry-run-migration.mjs', p], { encoding: 'utf8' }) }; }
  catch (e) { return { ok: false, out: `${e.stdout ?? ''}${e.stderr ?? ''}` }; }
};

const CONTROLS = [
  {
    name: 'A-row-count',
    gate: 'PREMISE — the seatings table holds exactly the generated number of rows',
    find: firstRow[0],
    replace: '',                                   // drop one seating entirely
    expect: /expected 85 seatings, found 84/i,
  },
  {
    name: 'B-cohort',
    gate: 'PREMISE — every office is in the 2026-12-11 cohort',
    // Repoint ONE seating at a real office outside the cohort (Blue Ridge TX Place 5, CC_0433).
    // ⚠ The row COUNT must stay at 85 or the earlier gate fires first and this one is never
    //   reached — gates run in order, and an earlier gate firing looks like success.
    find: `'${firstOffice}'::uuid`,
    replace: "'79ad986b-8e55-4ea1-8970-7c5b4b83f5ba'::uuid",
    expect: /are not in the 2026-12-11 cohort/i,
  },
  {
    name: 'C-duplicate-office',
    gate: 'PREMISE — one office appears once (an at-large board must not slip through)',
    // Give the SECOND row the FIRST row's office. Still 85 rows, still all in the cohort, so
    // both earlier gates pass and only the duplicate test can see it. The first version of this
    // control appended a row instead and was caught by the row-count gate, proving nothing.
    find: secondRowText,
    replace: secondRowText.replace(`'${secondOffice}'::uuid`, `'${firstOffice}'::uuid`),
    expect: /appear more than once/i,
  },
];

let failures = 0;
console.log(`CC_0434 controls — ${SRC}\n`);
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
