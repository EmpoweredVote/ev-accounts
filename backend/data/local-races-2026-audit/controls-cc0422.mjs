#!/usr/bin/env node
// Tamper controls for CC_0422.
//
// One fault per control, run against production inside a transaction that always rolls back, each
// required to STOP with the message naming its gate. V0 is the untampered file and must PASS.
//
// 🔴 Every replacement asserts its anchor matched and that the text changed: a tamper that did not
//    apply proves nothing and looks exactly like a pass.
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';

const MIGRATION = process.argv[2] || path.resolve('migrations/CC_0422_or_multiseat_council_races.sql');
const DRY_RUN = path.resolve('scripts/dry-run-migration.mjs');
const original = readFileSync(MIGRATION, 'utf8');
const workdir = mkdtempSync(path.join(tmpdir(), 'cc0422-controls-'));

function swap(text, find, replace, { count = 1 } = {}) {
  const hits = text.split(find).length - 1;
  if (hits !== count) throw new Error(`anchor matched ${hits}x, expected ${count}: ${JSON.stringify(find.slice(0, 80))}`);
  const out = text.split(find).join(replace);
  if (out === text) throw new Error('tamper changed nothing');
  return out;
}

// Fairview's Position 5 race: a numbered council seat on the SAME 2026-11-03 Oregon ballot that is
// its own single-seat contest, in a city none of these seven contests touches. It is the right
// decoy, because a pattern-matched "%Seat%" rule would have swept it up for real.
const FAIRVIEW_POS5 = "'cba78b59-0450-46e3-8e76-90f7c82d5878'::uuid";
const A_SURPLUS = "'d9b1ab18-cffd-4b42-830a-8c52a194cec1'::uuid";          // Forest Grove Seat C
const ARCHIVE_JOIN = '  FROM essentials.races r JOIN cc0422_surplus s ON s.id = r.id\n ON CONFLICT (id) DO NOTHING;';
const COLLAPSE = ' WHERE r.id = k.id AND (r.position_name <> k.new_name OR r.seats <> 3);';

const CONTROLS = [
  { id: 'V0', what: 'the untampered file', expect: null, apply: (t) => t },
  {
    id: 'V1',
    what: "the district gate: a surplus id is swapped for another city's seat race",
    // Swapped IN, not added: a 15th id would trip the count gate first and shadow this one.
    expect: /surplus race\(s\) sit on a district no kept race shares/,
    apply: (t) => swap(t, A_SURPLUS, FAIRVIEW_POS5),
  },
  {
    id: 'V2',
    what: 'the count gate: the surplus list is one row short',
    expect: /found 13 surplus races and 7 to keep/,
    // ⚠ The ids sit inside a VALUES list, so each is wrapped in its own parentheses; an anchor of
    //   ", <uuid>" matches nothing. The tamper asserts its anchor, so the miss was reported as a
    //   control that did not apply rather than passing as a green run.
    apply: (t) => swap(t, `, (${A_SURPLUS})`, ''),
  },
  {
    id: 'V3',
    what: 'the collapse gate: one contest is left on its old name and seat count',
    expect: /6 of the 7 contests read as one race with seats = 3/,
    apply: (t) => swap(t, COLLAPSE, " WHERE r.id = k.id AND r.id <> '115c8ccb-aa65-4b7d-b323-3d86e8efbd93'\n   AND (r.position_name <> k.new_name OR r.seats <> 3);"),
  },
  {
    id: 'V4',
    what: 'the archive gate: the rows are deleted without being recorded',
    expect: /the archive holds 0 rows, not 14/,
    apply: (t) => swap(t, ARCHIVE_JOIN, '  FROM essentials.races r JOIN cc0422_surplus s ON s.id = r.id AND false\n ON CONFLICT (id) DO NOTHING;'),
  },
  {
    id: 'V5',
    what: 'the candidacy guard: somebody has already seeded a ballot against the three-row shape',
    expect: /candidacies sit on the surplus race rows/,
    apply: (t) => swap(t, 'CREATE TEMP TABLE cc0422_surplus ON COMMIT DROP AS', [
      "INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, candidate_status)",
      "VALUES ('d9b1ab18-cffd-4b42-830a-8c52a194cec1', 'CC0422 Control', 'CC0422', 'Control', 'active');",
      '',
      'CREATE TEMP TABLE cc0422_surplus ON COMMIT DROP AS',
    ].join('\n')),
  },
  {
    id: 'V6',
    what: 'the occupancy gate: one of the 21 council offices loses its holder',
    expect: /council offices read 21 present \/ 20 held/,
    apply: (t) => swap(t, 'CREATE TEMP TABLE cc0422_surplus ON COMMIT DROP AS', [
      'DELETE FROM essentials.office_terms',
      " WHERE office_id = (SELECT office_id FROM essentials.races WHERE id = 'd9b1ab18-cffd-4b42-830a-8c52a194cec1');",
      '',
      'CREATE TEMP TABLE cc0422_surplus ON COMMIT DROP AS',
    ].join('\n')),
  },
  {
    id: 'V7',
    what: 'the drift baseline: an unrelated office loses its term row',
    // Not shadowed: the occupancy gate above counts only the 21 council offices, and this perturbs
    // an Oregon SENATE office, which none of the earlier gates looks at.
    expect: /drift baseline reads 239, not 238/,
    apply: (t) => swap(t, 'CREATE TEMP TABLE cc0422_surplus ON COMMIT DROP AS', [
      'DELETE FROM essentials.office_terms ot',
      ' USING essentials.offices o, essentials.districts d',
      " WHERE ot.office_id = o.id AND o.district_id = d.id",
      "   AND lower(d.state) = 'or' AND d.district_type = 'STATE_UPPER'",
      "   AND (regexp_replace(d.ocd_id, '^.*sldu:', ''))::int = 22;",
      '',
      'CREATE TEMP TABLE cc0422_surplus ON COMMIT DROP AS',
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
console.log("UNCONTROLLED HERE: the archive's RLS/grant gate, which cannot be tampered as ev_api;");
console.log('  it is exercised through the privileged connection in a transaction that rolls back.');
process.exit(failures ? 1 : 0);
