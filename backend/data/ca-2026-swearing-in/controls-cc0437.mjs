#!/usr/bin/env node
// Positive controls for CC_0437.
//
// 🔴 THE GATE THAT CARRIES THIS MIGRATION'S WHOLE ARGUMENT is "every person is seated into the
// office they ALREADY HOLD". That property is the only reason these six at-large boards are
// determinate when the other four are not, so control A plants exactly its violation.
//
// ⚠ ONE PREMISE GATE HAS NO CONTROL AND THAT IS STATED RATHER THAN HIDDEN: "each office appears
// once". Reaching it needs two rows sharing an office, and two different people cannot both hold
// one office, so any such tamper trips the holds-the-office gate first. It is belt-and-braces
// behind a gate that IS tested, not an untested claim about the data.
//
// Usage (from backend/):  node data/ca-2026-swearing-in/controls-cc0437.mjs <migration.sql>
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const SRC = process.argv[2]
  ?? 'C:/ev-accounts-tracker/backend/migrations/CC_0437_la_atlarge_all_incumbent_boards_2026_12_11.sql';
const original = readFileSync(SRC, 'utf8');
const work = mkdtempSync(join(tmpdir(), 'cc0437-controls-'));

const rowRe = /^ {4}\('([0-9a-f-]{36})'::uuid, '([0-9a-f-]{36})'::uuid, .*\),?$/gm;
const rows = [...original.matchAll(rowRe)];
if (rows.length < 2) { console.error('FATAL: fewer than two VALUES rows.'); process.exit(2); }

function tamper(name, find, replace) {
  if (!original.includes(find)) { console.error(`FATAL [${name}]: text not found.`); process.exit(2); }
  const t = original.replace(find, replace);
  if (t === original) { console.error(`FATAL [${name}]: no-op replacement.`); process.exit(2); }
  const p = join(work, `${name}.sql`);
  writeFileSync(p, t);
  if (readFileSync(p, 'utf8') === original) { console.error(`FATAL [${name}]: tamper did not land.`); process.exit(2); }
  return p;
}
const run = p => {
  try { return { ok: true, out: execFileSync('node', ['scripts/dry-run-migration.mjs', p], { encoding: 'utf8' }) }; }
  catch (e) { return { ok: false, out: `${e.stdout ?? ''}${e.stderr ?? ''}` }; }
};

const CONTROLS = [
  {
    name: 'A-must-already-hold-the-seat',
    gate: 'PREMISE — every person is seated into the office they ALREADY HOLD',
    // 🔴 Give row 1's PERSON row 2's OFFICE. Both offices are real, both are on a board this file
    //    seats, and the row count stays 17 — so only the holds-the-seat test can see it. This is
    //    precisely the mistake the file exists to make impossible: choosing a seat for somebody.
    find: rows[0][0],
    replace: rows[0][0].replace(`'${rows[0][1]}'::uuid`, `'${rows[1][1]}'::uuid`),
    expect: /would seat somebody into an office they do NOT already hold/i,
  },
  {
    name: 'B-row-count',
    gate: 'PREMISE — the seatings table holds exactly the generated number of rows',
    find: `${rows[0][0]}\n`,
    replace: '',
    expect: /expected 17 seatings, found 16/i,
  },
  {
    name: 'C-newcomer-boards-untouched',
    gate: 'PREMISE — the four boards with a newcomer are still unseated',
    // Seat a Hawthorne filer at 2026-12-11 before the premise runs. Hawthorne is one of the four
    // this file refuses, so the gate must notice that somebody has started seating them.
    find: 'BEGIN;\n\nCREATE TEMP TABLE cc0437_seatings',
    replace: `BEGIN;

SELECT essentials.seat_officeholder(
  'f55cad21-3c07-4fd0-aeb6-e1b5cc4bec6b'::uuid,
  '54a7eed3-9757-56a8-a493-5cdd4f1370a6'::uuid,
  DATE '2026-12-11', 'control C tamper',
  p_how_started => 'appointed', p_allow_reelection => true);

CREATE TEMP TABLE cc0437_seatings`,
    expect: /filer\(s\) on the four newcomer boards already carry a 2026-12-11/i,
  },
];

let failures = 0;
console.log(`CC_0437 controls — ${SRC}\n`);
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
