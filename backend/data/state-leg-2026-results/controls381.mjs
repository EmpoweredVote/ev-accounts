#!/usr/bin/env node
// Controls for CC_0381. Each plants a single fault, asserts the fault is PRESENT in the file
// that will actually run, dry-runs it against production inside a transaction that is rolled
// back, and requires the NAMED gate to be the one that fires.
//
// 🔴 A CONTROL THAT HAS ONLY EVER PASSED PROVES NOTHING. The point is to watch each gate go
//   red on a fault it is supposed to see, then green again without it.
// 🔴 A TAMPER MUST LEAVE EVERYTHING ELSE CORRECT, or it trips an EARLIER gate and tells you
//   the suite is alive and nothing about the guard under test. That has happened six times in
//   this programme; every tamper below is built to satisfy every gate before its own.
// 🔴 A TAMPER THAT DID NOT APPLY IS A CONTROL THAT PROVED NOTHING, AND IT LOOKS LIKE A PASS —
//   a sed that matched nothing once left a 0-byte migration that reported DRY RUN OK. Every
//   control therefore asserts its own fault is in the file before running it.
//
// Usage: node controls381.mjs <path to CC_0381...sql> <path to dry-run-migration.mjs>
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execFileSync } from 'node:child_process';

const migration = path.resolve(process.argv[2]);
const dryRun = path.resolve(process.argv[3]);
const original = fs.readFileSync(migration, 'utf8');

// statements injected straight after the file's BEGIN; part of the same rolled-back transaction
const inject = (sql, stmts) => sql.replace(/^BEGIN;$/m, 'BEGIN;\n' + stmts + '\n');

// The two rows of Wisconsin Assembly District 1 — one seat, two candidates, neither carrying a
// prior result, so a fault planted here reaches the gate it is aimed at.
const KITCHENS = "'aee1d165-f78a-4986-a8c5-b222b6f9950b'::uuid, 1, 'Joel Kitchens', 'Joel Kitchens', '20261103WI50174', '155928', 'GOP', 18292, 57.35, 'won', 'exact-full-name', NULL, true";
const PAPLHAM = "'0d3d9770-bf13-4050-aa91-41cbc9a3038e'::uuid, 1, 'Renee A. Paplham', 'Renee Paplham', '20261103WI50174', '164811', 'Dem', 13603, 42.65, 'lost', 'exact-first-last', NULL, false";

const CONTROLS = [
  {
    name: 'A — a TRANSPOSED WINNER must be caught by the vote counts',
    why: 'this is the only gate that can see it: every other check reads the outcome column beside the name, so a file that has swapped two outcomes agrees with itself',
    // swap ONLY the outcomes. Names, uuids, votes and percentages all stay with the right
    // person, so the race still has exactly one winner for its one seat and every earlier gate
    // passes. The votes are the independent fact that catches it.
    tamper: (s) => s
      .replace(KITCHENS, KITCHENS.replace("57.35, 'won'", "57.35, 'lost'"))
      .replace(PAPLHAM, PAPLHAM.replace("42.65, 'lost'", "42.65, 'won'")),
    present: (s) => /'Joel Kitchens', '20261103WI50174', '155928', 'GOP', 18292, 57.35, 'lost'/.test(s)
      && /'Renee Paplham', '20261103WI50174', '164811', 'Dem', 13603, 42.65, 'won'/.test(s),
    expect: /the rows marked won are not the top vote-getters/,
  },
  {
    name: 'B — a swapped candidacy uuid must be caught by the DATABASE row’s name',
    why: 'every row is addressed by uuid; the name beside it never finds it, so a mistyped id would move a win to another person in silence',
    // 🔴 Pointing one row at the OTHER row's id duplicates a primary key and dies on the INSERT,
    //   which proves nothing. SWAPPING the two ids keeps the key unique and keeps both ids
    //   inside the stated race, so the pin-exists and pin-in-race gates both pass and the only
    //   thing left wrong is which name sits beside which uuid.
    tamper: (s) => s
      .replace("'aee1d165-f78a-4986-a8c5-b222b6f9950b'::uuid, 1, 'Joel Kitchens'", "'TMP-ID'::uuid, 1, 'Joel Kitchens'")
      .replace("'0d3d9770-bf13-4050-aa91-41cbc9a3038e'::uuid, 1, 'Renee A. Paplham'", "'aee1d165-f78a-4986-a8c5-b222b6f9950b'::uuid, 1, 'Renee A. Paplham'")
      .replace("'TMP-ID'::uuid, 1, 'Joel Kitchens'", "'0d3d9770-bf13-4050-aa91-41cbc9a3038e'::uuid, 1, 'Joel Kitchens'"),
    present: (s) => /'0d3d9770-bf13-4050-aa91-41cbc9a3038e'::uuid, 1, 'Joel Kitchens'/.test(s)
      && /'aee1d165-f78a-4986-a8c5-b222b6f9950b'::uuid, 1, 'Renee A\. Paplham'/.test(s)
      && !/TMP-ID/.test(s),
    expect: /pinned rows do not carry the name this file states/,
  },
  {
    name: 'C — a row pinned into the wrong KIND of race must be refused',
    why: 'the pin is re-asserted against production, so a uuid from a congressional contest cannot be written as a legislative result',
    // 🔴 Swapping ONE row into another race leaves 404 races and trips the race COUNT first.
    //   Both rows of Wisconsin Assembly District 1 are therefore replaced by both rows of a real
    //   U.S. House race — correct uuids, correct names, one seat, one winner — so the counts,
    //   the pins, the names, the seats and the vote order are all still right and the only
    //   thing wrong is that this is a congressional district.
    tamper: (s) => s
      .replace("'b6480076-2b38-4567-aef3-255abfb331bd'::uuid, " + KITCHENS,
        "'00a7bf9a-96b5-4818-9ff3-3de3a4048068'::uuid, '3cfd4742-3385-452a-9c59-5937860f965c'::uuid, 1, 'Jared Huffman', 'Jared Huffman', '20261103WI50174', '155928', 'GOP', 18292, 57.35, 'won', 'exact-full-name', NULL, true")
      .replace("'b6480076-2b38-4567-aef3-255abfb331bd'::uuid, " + PAPLHAM,
        "'00a7bf9a-96b5-4818-9ff3-3de3a4048068'::uuid, '17757114-6256-4949-9ab9-69446a2f5d08'::uuid, 1, 'Robin Littau', 'Robin Littau', '20261103WI50174', '164811', 'Dem', 13603, 42.65, 'lost', 'exact-first-last', NULL, false"),
    present: (s) => /'Jared Huffman', 'Jared Huffman'/.test(s) && /'Robin Littau', 'Robin Littau'/.test(s)
      && !/b6480076-2b38-4567-aef3-255abfb331bd/.test(s),
    expect: /not in a 2026-11-03 state-legislative race/,
  },
  {
    name: 'D — more winners than the race has seats must be refused',
    why: 'the seat count comes from races.seats, never from the number 1 — Arizona’s House elects two members per district and 24 of these races carry two winners',
    // 🔴 Simply promoting a loser leaves 428 winners and trips the TOTAL first. One winner in a
    //   different race is demoted to keep the total at 427, so the only thing wrong is the
    //   distribution: Assembly 1 has two winners for one seat and Assembly 10 has none.
    tamper: (s) => s
      .replace(PAPLHAM, PAPLHAM.replace("42.65, 'lost'", "42.65, 'won'"))
      .replace("'Darrin Madison', '20261103WI50201'", "'Darrin Madison!', '20261103WI50201'")
      .replace(/('Darrin Madison!'[^\n]*?)89\.93, 'won'/, "$1" + "89.93, 'lost'")
      .replace("'Darrin Madison!'", "'Darrin Madison'"),
    present: (s) => /'Renee Paplham', '20261103WI50174', '164811', 'Dem', 13603, 42\.65, 'won'/.test(s)
      && /'Darrin Madison'[^\n]*89\.93, 'lost'/.test(s),
    expect: /winner count does not match races\.seats/,
  },
  {
    name: 'E — a prior value that has moved since the analysis must stop the file',
    why: 'an UPDATE is final and there is no history table, so the file must be refused if somebody has written to these rows since',
    // Quang H Nguyen's row really does carry 'advanced'; claiming it is NULL is the shape of a
    // stale analysis.
    tamper: (s) => s.replace("'Quang Nguyen', '20261103AZ3087', '101909', 'GOP', 65941, 37.08, 'won', 'holder', 'advanced'",
      "'Quang Nguyen', '20261103AZ3087', '101909', 'GOP', 65941, 37.08, 'won', 'holder', NULL"),
    present: (s) => /'Quang Nguyen', '20261103AZ3087', '101909', 'GOP', 65941, 37\.08, 'won', 'holder', NULL/.test(s),
    expect: /prior values have moved since this file was generated/,
  },
  {
    name: 'F — the incumbent basis must still agree with office_current_holder',
    why: '19 rows were matched across a spelling disagreement on that fact alone; if it has stopped being true the match has no basis left',
    // Sandy Zalecki is a real losing candidate in the same Arizona race and is NOT the seat
    // holder. Claiming the holder basis for her row is the shape of a bad match.
    tamper: (s) => s.replace("'Sandy Zalecki', '20261103AZ3087'", "'Sandy Zalecki!', '20261103AZ3087'")
      .replace(/('Sandy Zalecki!', '20261103AZ3087'[^\n]*?)'exact-full-name'/, "$1'holder'")
      .replace("'Sandy Zalecki!'", "'Sandy Zalecki'"),
    present: (s) => /'Sandy Zalecki'[^\n]*'holder'/.test(s),
    expect: /the incumbent basis|no longer the seat holder|does not flag them incumbent/,
  },
  {
    name: 'G — dropping the citation append must destroy a citation and be caught',
    why: '307 rows carry a real state citation that this file appends to; overwriting it would lose it for good',
    tamper: (s) => s.replace(/\s*\|\| CASE WHEN coalesce\(rc\.result_source, ''\) <> ''[\s\S]*?ELSE '' END,/,
      ', -- citation append removed by control G\n'),
    present: (s) => /citation append removed by control G/.test(s) && !/retained verbatim/.test(s.split('-- ─── 3. The write ───')[1].split('-- ─── 4.')[0]),
    expect: /prior citations were destroyed rather than appended|expected 307 preserved citations/,
  },
  {
    name: 'H — a missing row must be caught by the count',
    why: 'a generated file that silently loses rows would under-report the tier and nothing else would notice',
    tamper: (s) => s.replace('  (' + "'wi', 'Assembly District 1', 'Representative to the Assembly', 'b6480076-2b38-4567-aef3-255abfb331bd'::uuid, " + PAPLHAM + '),\n', ''),
    present: (s) => !/Renee A\. Paplham/.test(s),
    expect: /expected 809 measured candidacies/,
  },
  {
    name: 'I — the occupancy drift baseline must be live, not decorative',
    why: 'an office with no office_terms row lands unflagged in offices_missing_terms and takes the baseline 238 -> 239',
    tamper: (s) => inject(s, "INSERT INTO essentials.offices (title, chamber_id, district_id, is_vacant)"
      + " SELECT 'Planted by control I', o.chamber_id, o.district_id, false FROM essentials.offices o"
      + " JOIN essentials.races r ON r.office_id = o.id"
      + " WHERE r.id = 'b6480076-2b38-4567-aef3-255abfb331bd'::uuid;"),
    present: (s) => /Planted by control I/.test(s),
    expect: /occupancy drift baseline moved/,
  },
  {
    name: 'J — seating somebody must be refused: recording a result seats nobody',
    why: 'these members take office in January, so if this file moves an officeholder it has done something it does not claim to do',
    // close the sitting member's term inside the transaction, which changes who
    // office_current_holder resolves for that office
    tamper: (s) => s.replace(/^-- ─── 4\. Post-verify ───$/m,
      "UPDATE essentials.office_terms t SET term_end = DATE '2026-11-04'"
      + " FROM essentials.races r WHERE r.id = 'b6480076-2b38-4567-aef3-255abfb331bd'::uuid"
      + " AND t.office_id = r.office_id AND t.term_end IS NULL; -- planted by control J\n-- ─── 4. Post-verify ───"),
    present: (s) => /planted by control J/.test(s),
    expect: /the current officeholder changed/,
  },
  {
    name: 'K — a result written outside the pinned set must be caught',
    why: 'the only rows this file may decide are the 809 it names; anything else is a write nobody reviewed',
    // an uncalled race we deliberately hold back: give one of its rows a call
    tamper: (s) => s.replace(/^-- ─── 4\. Post-verify ───$/m,
      "UPDATE essentials.race_candidates rc SET result = 'won', result_certainty = 'called',"
      + " result_source = 'planted by control K' FROM essentials.races r, essentials.elections e,"
      + " essentials.offices o, essentials.districts d WHERE r.id = rc.race_id AND e.id = r.election_id"
      + " AND o.id = r.office_id AND d.id = o.district_id AND e.election_date = DATE '2026-11-03'"
      + " AND d.district_type IN ('STATE_LOWER','STATE_UPPER') AND rc.result IS NULL"
      + " AND rc.id NOT IN (SELECT rc_id FROM called);\n-- ─── 4. Post-verify ───"),
    present: (s) => /planted by control K/.test(s),
    expect: /state-legislative rows outside this file carry a call/,
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

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'cc0381-controls-'));
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
  if (!fired) {
    bad++;
    console.log(r.out.split('\n').filter((l) => /ERROR|error|EXCEPTION|OK/.test(l)).slice(0, 6).map((l) => '          ' + l.trim()).join('\n'));
  }
}
fs.rmSync(tmp, { recursive: true, force: true });
console.log('\n' + (CONTROLS.length - bad) + ' of ' + CONTROLS.length + ' controls fired.');
process.exit(bad ? 1 : 0);
