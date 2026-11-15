#!/usr/bin/env node
// Tamper controls for CC_0419.
//
// A gate that has only ever passed proves nothing. Each control below plants ONE fault, runs the
// migration against production inside a transaction that always rolls back, and requires the
// migration to STOP with the message that names the gate under test. Run 0 is the untampered file
// and must PASS, so a suite that fails everything for an unrelated reason is visible immediately.
//
// 🔴 A TAMPER THAT DID NOT APPLY IS A CONTROL THAT PROVED NOTHING, AND IT LOOKS LIKE A PASS. Every
//    replacement below asserts its anchor was found and that the text actually changed; a miss
//    exits non-zero before anything runs.
//
// 🔴 EACH CONTROL CHANGES ONE THING, except where reaching a gate requires relaxing the gate in
//    front of it. Those are marked SHADOWED and say what they had to move; a tamper that trips an
//    earlier assertion tells you the suite is alive but not which guard holds which claim.
//
// ⚠ These run as ev_api, which holds no DDL on essentials. That is why the migration's archive-table
//   DDL is guarded on to_regclass: once the table exists the file runs end to end under the normal
//   role. Unguarded, every control here would die on a permission error instead of on its gate.
//
// Usage (from backend/, with the environment loaded):
//   node data/or-senate-off-cycle/controls.mjs
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';

const MIGRATION = process.argv[2]
  || path.resolve('migrations/CC_0419_or_senate_offcycle_races.sql');
const DRY_RUN = path.resolve('scripts/dry-run-migration.mjs');
const original = readFileSync(MIGRATION, 'utf8');
const workdir = mkdtempSync(path.join(tmpdir(), 'cc0419-controls-'));

// A replacement that must land. `count` is how many occurrences are expected, so a pattern that
// starts matching somewhere else fails loudly rather than tampering twice.
function swap(text, find, replace, { count = 1 } = {}) {
  const hits = text.split(find).length - 1;
  if (hits !== count) {
    throw new Error(`tamper anchor matched ${hits} time(s), expected ${count}: ${JSON.stringify(find.slice(0, 90))}`);
  }
  const out = text.split(find).join(replace);
  if (out === text) throw new Error(`tamper changed nothing: ${JSON.stringify(find.slice(0, 90))}`);
  return out;
}

const DELETE_STMT = 'DELETE FROM essentials.races r USING cc0419_target t WHERE r.id = t.race_id;';
const ARCHIVE_JOIN = '  JOIN cc0419_target t ON t.race_id = r.id\n ON CONFLICT (id) DO NOTHING;';
const TARGET_LIST = 'IN (1, 2, 5, 9, 12, 14, 18, 21, 22, 23, 25, 27, 28, 29, 30);';
const CHAMBER_GATE = `  IF v_offices <> 30 OR v_held <> 30 OR v_vacant <> 0 THEN`;

const CONTROLS = [
  {
    id: 'V0',
    what: 'the untampered file',
    expect: null,                                   // must PASS
    apply: (t) => t,
  },
  {
    id: 'V1',
    what: 'the candidate guard: a district that DID hold a 2026 election is put on the delete list',
    // District 17 carries two candidacies (Lisa Reynolds' seat). Swapping it IN for 30 keeps the
    // list at 15 entries, so the count gate in front cannot shadow this one.
    expect: /candidacies sit on races this migration would delete/,
    apply: (t) => swap(t, TARGET_LIST, 'IN (1, 2, 5, 9, 12, 14, 17, 18, 21, 22, 23, 25, 27, 28, 29);'),
  },
  {
    id: 'V2',
    what: 'the precondition count: the delete list is one district short',
    expect: /expected 15 off-cycle OR senate races, found 14/,
    apply: (t) => swap(t, TARGET_LIST, 'IN (1, 2, 5, 9, 12, 14, 18, 21, 22, 23, 25, 27, 28, 29);'),
  },
  {
    id: 'V3',
    what: 'the end-state set: the DELETE quietly skips one row',
    expect: /16 OR senate races remain for 2026-11-03/,
    apply: (t) => swap(t, DELETE_STMT,
      'DELETE FROM essentials.races r USING cc0419_target t WHERE r.id = t.race_id AND t.district <> 30;'),
  },
  {
    id: 'V4',
    what: 'the archive gate: the rows are deleted without being recorded',
    expect: /the archive holds 0 rows, not 15/,
    apply: (t) => swap(t, ARCHIVE_JOIN, '  JOIN cc0419_target t ON t.race_id = r.id AND false\n ON CONFLICT (id) DO NOTHING;'),
  },
  {
    id: 'V5',
    what: 'the dependents gate: something else points at one of these races',
    // discovered_sources.race_id is ON DELETE SET NULL -- it would be severed in silence, which is
    // the whole reason this gate counts it.
    expect: /these races are referenced elsewhere/,
    apply: (t) => swap(t, 'CREATE TEMP TABLE cc0419_target ON COMMIT DROP AS', [
      "INSERT INTO essentials.discovered_sources (source_key, url, discovered_via, race_id)",
      // ⚠ discovered_via is CHECK-constrained to watchlist/search/agent/hub. The first version of
      //    this control invented a value, and the run stopped on the check constraint instead of
      //    on the gate -- a control that failed correctly, for the wrong property, and would have
      //    been read as a pass by anyone who only looked at the exit code.
      "SELECT 'cc0419-control', 'https://example.invalid/cc0419-control', 'search', r.id",
      "  FROM essentials.races r",
      "  JOIN essentials.elections e ON e.id = r.election_id",
      "  JOIN essentials.offices o ON o.id = r.office_id",
      "  JOIN essentials.districts d ON d.id = o.district_id",
      " WHERE lower(d.state) = 'or' AND d.district_type = 'STATE_UPPER'",
      "   AND e.election_date = '2026-11-03'",
      "   AND (regexp_replace(d.ocd_id, '^.*sldu:', ''))::int = 22;",
      '',
      'CREATE TEMP TABLE cc0419_target ON COMMIT DROP AS',
    ].join('\n')),
  },
  {
    id: 'V6',
    what: 'the occupancy gate: a sitting Oregon senator loses their term row',
    // Deleting a race must never touch who holds the seat. This proves the gate can see it if it did.
    expect: /the Oregon Senate reads 30 offices \/ 29 held/,
    apply: (t) => swap(t, 'CREATE TEMP TABLE cc0419_target ON COMMIT DROP AS', [
      'DELETE FROM essentials.office_terms ot',
      ' USING essentials.offices o, essentials.districts d',
      " WHERE ot.office_id = o.id AND o.district_id = d.id",
      "   AND lower(d.state) = 'or' AND d.district_type = 'STATE_UPPER'",
      "   AND (regexp_replace(d.ocd_id, '^.*sldu:', ''))::int = 22;",
      '',
      'CREATE TEMP TABLE cc0419_target ON COMMIT DROP AS',
    ].join('\n')),
  },
  {
    id: 'V7',
    what: 'the drift baseline: an office loses its term and the 238 figure moves',
    // SHADOWED: the Oregon chamber gate (V6's gate) fires on the same fault first, because an
    // Oregon senate office with no term is both an unheld seat and a term-less office. The chamber
    // gate is therefore neutralised FOR THIS RUN ONLY, which is the only way to reach the baseline
    // behind it. Two changes, stated rather than hidden.
    shadowed: 'the Oregon chamber gate, neutralised for this run only',
    expect: /the unflagged offices_missing_terms baseline reads 239, not 238/,
    apply: (t) => {
      let out = swap(t, 'CREATE TEMP TABLE cc0419_target ON COMMIT DROP AS', [
        'DELETE FROM essentials.office_terms ot',
        ' USING essentials.offices o, essentials.districts d',
        " WHERE ot.office_id = o.id AND o.district_id = d.id",
        "   AND lower(d.state) = 'or' AND d.district_type = 'STATE_UPPER'",
        "   AND (regexp_replace(d.ocd_id, '^.*sldu:', ''))::int = 22;",
        '',
        'CREATE TEMP TABLE cc0419_target ON COMMIT DROP AS',
      ].join('\n'));
      out = swap(out, CHAMBER_GATE, '  IF false THEN');
      return out;
    },
  },
];

let failures = 0;
for (const c of CONTROLS) {
  const file = path.join(workdir, `${c.id}.sql`);
  let text;
  try {
    text = c.apply(original);
  } catch (e) {
    console.log(`${c.id} 🔴 TAMPER DID NOT APPLY — ${e.message}`);
    failures++;
    continue;
  }
  if (c.expect && text === original) {
    console.log(`${c.id} 🔴 TAMPER DID NOT APPLY — the file is unchanged`);
    failures++;
    continue;
  }
  writeFileSync(file, text);

  let stdout = '';
  let failed = false;
  try {
    stdout = execFileSync(process.execPath, [DRY_RUN, file], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  } catch (e) {
    failed = true;
    stdout = `${e.stdout || ''}${e.stderr || ''}`;
  }

  if (!c.expect) {
    const ok = !failed && /DRY RUN OK/.test(stdout);
    console.log(`${c.id} ${ok ? '🟢' : '🔴'} ${c.what} — ${ok ? 'passes, as it must' : 'DID NOT PASS'}`);
    if (!ok) { failures++; console.log(stdout.split('\n').slice(-12).join('\n')); }
    continue;
  }

  const matched = c.expect.test(stdout);
  const ok = failed && matched;
  const note = c.shadowed ? `  (shadowed — ${c.shadowed})` : '';
  console.log(`${c.id} ${ok ? '🟢' : '🔴'} ${c.what}${note}`);
  if (!ok) {
    failures++;
    console.log(`     expected the run to STOP with ${c.expect}; it ${failed ? 'stopped with something else' : 'PASSED'}`);
    console.log(stdout.split('\n').slice(-12).map((l) => `     ${l}`).join('\n'));
  }
}

console.log(`\n${CONTROLS.length - failures} of ${CONTROLS.length} controls behaved.`);
console.log('UNCONTROLLED HERE: the archive\'s RLS/grant gate, which cannot be tampered as ev_api');
console.log('  (granting anon needs table ownership) -- it is exercised separately through the');
console.log('  privileged connection, in a transaction that rolls back.');
process.exit(failures ? 1 : 0);
