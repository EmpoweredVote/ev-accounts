#!/usr/bin/env node
// Tamper controls for CC_0421.
//
// Each control plants ONE fault, runs the migration against production inside a transaction that
// always rolls back, and requires the migration to STOP with the message naming the gate under
// test. Run V0 is the untampered file and must PASS, so a suite failing for an unrelated reason is
// visible at once.
//
// 🔴 Every replacement asserts its anchor matched and that the text changed. A tamper that did not
//    apply is a control that proved nothing and looks exactly like a pass.
//
// ⚠ This migration contains no DDL, so it runs under ev_api like any other. CC_0419 needed its
//   archive-table DDL guarded for that reason; nothing here does.
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';

const MIGRATION = process.argv[2] || path.resolve('migrations/CC_0421_az_town_races_to_the_primary.sql');
const DRY_RUN = path.resolve('scripts/dry-run-migration.mjs');
const original = readFileSync(MIGRATION, 'utf8');
const workdir = mkdtempSync(path.join(tmpdir(), 'cc0421-controls-'));

function swap(text, find, replace, { count = 1 } = {}) {
  const hits = text.split(find).length - 1;
  if (hits !== count) throw new Error(`anchor matched ${hits}x, expected ${count}: ${JSON.stringify(find.slice(0, 80))}`);
  const out = text.split(find).join(replace);
  if (out === text) throw new Error('tamper changed nothing');
  return out;
}

const SEATS_FIX = "UPDATE essentials.races SET seats = 2\n WHERE id = '31aad1c8-06af-4c8f-821c-21ad89795dc1' AND seats <> 2;";
const ST_PRIMARY_RACE = "'c7f1a6d2-5b84-4a3e-9d21-0e6f4b88c310'";

const CONTROLS = [
  { id: 'V0', what: 'the untampered file', expect: null, apply: (t) => t },
  {
    id: 'V1',
    what: 'the move gate: one of the five races is left behind on the general',
    expect: /4 of the 5 town races sit on the primary/,
    apply: (t) => swap(t, "'64eb9e2a-5169-4dde-9d64-badca5fcf174',\n                ", '', { count: 1 }),
  },
  {
    id: 'V2',
    what: "the seats gate: South Tucson's general keeps the 3 seats it never filled",
    expect: /South Tucson general seats reads 3, expected 2/,
    apply: (t) => swap(t, SEATS_FIX, '-- seats correction removed by a control'),
  },
  {
    id: 'V3',
    what: 'the row-count gate: one candidacy is dropped from the ballot',
    expect: /31 pima candidacies, expected 32/,
    apply: (t) => {
      const line = t.split('\n').find((l) => l.startsWith("  ('") && l.includes('Zeke Cook'));
      if (!line) throw new Error('could not find the Zeke Cook VALUES row');
      return swap(t, `${line}\n`, '');
    },
  },
  {
    id: 'V4',
    what: 'the result-mix gate: a losing candidate is recorded as having won',
    // Greg Johnsen lost the Marana mayoralty. Flipping him to won moves two counters at once,
    // which is what the gate compares.
    expect: /results read won=14 advanced=4 not_nominated=3 null=4/,
    apply: (t) => {
      const line = t.split('\n').find((l) => l.startsWith("  ('") && l.includes('Greg Johnsen'));
      if (!line) throw new Error('could not find the Greg Johnsen VALUES row');
      const tampered = line.replace("'lost'", "'won'").replace(/NULL\)/, "'called')");
      if (tampered === line) throw new Error('the Johnsen row did not change shape as expected');
      return swap(t, line, tampered);
    },
  },
  {
    id: 'V5',
    what: 'the citation gate: a vote count is written into a result_source',
    expect: /a result_source carries a vote count/,
    apply: (t) => {
      const line = t.split('\n').find((l) => l.startsWith("  ('") && l.includes('Jon Post'));
      if (!line) throw new Error('could not find the Jon Post VALUES row');
      // 🔴 replaceAll, NOT replace. The citation text appears TWICE in each row -- once as `source`
      //    and once as `result_source` -- and the gate reads result_source. A first version used
      //    String.replace, which changes only the first occurrence, so it tampered with `source`
      //    and left the column under test clean. The run passed, and a suite that only counted
      //    green would have recorded a working gate that had never been exercised.
      const tampered = line.replaceAll('A.R.S. 9-821.01(D),(F),(G)', 'A.R.S. 9-821.01; 7,620 votes');
      if (!/result_source/.test('ok') && tampered === line) throw new Error('the citation tamper did not change the row');
      return swap(t, line, tampered);
    },
  },
  {
    id: 'V6',
    what: "the empty-race gate: South Tucson's general ballot is not seeded",
    expect: /1 Arizona races on the 2026 general still carry no candidate/,
    // ⚠ NOT BY DELETING THOSE FOUR ROWS. That was the first attempt, and the row-count gate fired
    //   first (28 candidacies, expected 32), shadowing the gate under test; reaching it that way
    //   would have meant relaxing two earlier gates at once. Repointing the four November
    //   candidacies at the July race instead keeps the row count at 32 and the result mix
    //   unchanged, so exactly one thing differs: South Tucson's general race has no ballot.
    apply: (t) => {
      const lines = t.split('\n').filter((l) => l.startsWith("  ('") && l.includes('pima-2026-11-03-'));
      if (lines.length !== 4) throw new Error(`expected 4 general VALUES rows, found ${lines.length}`);
      let out = t;
      for (const l of lines) {
        if (!l.startsWith(`  ('31aad1c8-06af-4c8f-821c-21ad89795dc1'`)) throw new Error('a general VALUES row does not start with the general race id');
        // ⚠ NOT at South Tucson's own primary race either: race_candidates carries a unique
        //   (race_id, name) constraint, race_candidates_race_name_key_uniq, and all four of these
        //   people are already on that race, so the run died on a duplicate key instead of on the
        //   gate. Marana's council race shares no name with them.
        out = swap(out, l, l.replace("'31aad1c8-06af-4c8f-821c-21ad89795dc1'", "'be35d5c0-f689-43c3-b4ba-295e71984b5a'"));
      }
      return out;
    },
  },
  {
    id: 'V7',
    what: 'the drift baseline: an unrelated office loses its term row',
    // Not shadowed: every gate before this one is scoped to Arizona, and the office perturbed is an
    // Oregon senate seat, so nothing else can fire first.
    expect: /drift baseline reads 239, not 238/,
    apply: (t) => swap(t, 'UPDATE essentials.races\n   SET election_id', [
      'DELETE FROM essentials.office_terms ot',
      ' USING essentials.offices o, essentials.districts d',
      " WHERE ot.office_id = o.id AND o.district_id = d.id",
      "   AND lower(d.state) = 'or' AND d.district_type = 'STATE_UPPER'",
      "   AND (regexp_replace(d.ocd_id, '^.*sldu:', ''))::int = 22;",
      '',
      'UPDATE essentials.races\n   SET election_id',
    ].join('\n')),
  },
];

let failures = 0;
for (const c of CONTROLS) {
  const file = path.join(workdir, `${c.id}.sql`);
  let text;
  try { text = c.apply(original); }
  catch (e) { console.log(`${c.id} 🔴 TAMPER DID NOT APPLY — ${e.message}`); failures++; continue; }
  if (c.expect && text === original) { console.log(`${c.id} 🔴 TAMPER DID NOT APPLY — file unchanged`); failures++; continue; }
  writeFileSync(file, text);

  let stdout = '', failed = false;
  try { stdout = execFileSync(process.execPath, [DRY_RUN, file], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }); }
  catch (e) { failed = true; stdout = `${e.stdout || ''}${e.stderr || ''}`; }

  if (!c.expect) {
    const ok = !failed && /DRY RUN OK/.test(stdout);
    console.log(`${c.id} ${ok ? '🟢' : '🔴'} ${c.what} — ${ok ? 'passes, as it must' : 'DID NOT PASS'}`);
    if (!ok) { failures++; console.log(stdout.split('\n').slice(-10).join('\n')); }
    continue;
  }
  const ok = failed && c.expect.test(stdout);
  console.log(`${c.id} ${ok ? '🟢' : '🔴'} ${c.what}`);
  if (!ok) {
    failures++;
    console.log(`     expected a stop matching ${c.expect}; it ${failed ? 'stopped with something else' : 'PASSED'}`);
    console.log(stdout.split('\n').slice(-10).map((l) => `     ${l}`).join('\n'));
  }
}
console.log(`\n${CONTROLS.length - failures} of ${CONTROLS.length} controls behaved.`);
process.exit(failures ? 1 : 0);
