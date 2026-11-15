#!/usr/bin/env node
// Tamper controls for CC_0423. One fault each, always rolled back; V0 must pass.
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';

const MIGRATION = process.argv[2] || path.resolve('migrations/CC_0423_or_local_ballots.sql');
const DRY_RUN = path.resolve('scripts/dry-run-migration.mjs');
const original = readFileSync(MIGRATION, 'utf8');
const workdir = mkdtempSync(path.join(tmpdir(), 'cc0423-controls-'));
const lineFor = (t, who) => {
  const l = t.split('\n').find((x) => x.startsWith("  ('") && x.includes(`'${who}'`));
  if (!l) throw new Error(`no VALUES row for ${who}`);
  return l;
};
function swap(text, find, replace, { count = 1 } = {}) {
  const hits = text.split(find).length - 1;
  if (hits !== count) throw new Error(`anchor matched ${hits}x, expected ${count}`);
  const out = text.split(find).join(replace);
  if (out === text) throw new Error('tamper changed nothing');
  return out;
}

const FAIRVIEW_MAYOR_RACE = 'ebcee8b9-4ff2-48c7-afcd-f035e1c9031c';
const FAIRVIEW_P4_RACE = 'e7f7ee0d-6806-4919-b5fa-a7ead87ca40f';

const CONTROLS = [
  { id: 'V0', what: 'the untampered file', expect: null, apply: (t) => t },
  {
    id: 'V1', what: 'the row-count gate: one candidacy is dropped from a ballot',
    expect: /101 Oregon candidacies, expected 102/,
    apply: (t) => swap(t, `${lineFor(t, 'Dan Miller')}\n`, ''),
  },
  {
    id: 'V2', what: 'the result-mix gate: an uncalled contest is given a winner',
    // Travis Stovall leads the Gresham mayoralty, which nobody has called. Recording him as having
    // won is the exact mistake this migration exists to avoid.
    expect: /won=19 lost=26 null=57/,
    apply: (t) => {
      const l = lineFor(t, 'Travis Stovall');
      return swap(t, l, l.replace(/NULL, NULL, NULL\)/, "'won', 'a source', 'called')"));
    },
  },
  {
    id: 'V3', what: 'the result-mix gate: a sitting member is recorded as a challenger',
    expect: /incumbent=24, expected 102\/|won=18 lost=26 null=58 incumbent=24/,
    apply: (t) => {
      const l = lineFor(t, 'Janine Gladfelter');
      return swap(t, l, l.replace(', true, ', ', false, '));
    },
  },
  {
    id: 'V4', what: 'the citation gate: a vote count is written into a result_source',
    expect: /a result_source carries a vote count/,
    apply: (t) => {
      const l = lineFor(t, 'Keith A Kudrna');
      // replaceAll: the citation text appears twice in a row, as `source` and as `result_source`,
      // and the gate reads the second. CC_0421's first attempt tampered only the first and passed.
      return swap(t, l, l.replaceAll('lowest named winner', 'lowest named winner; 2,466 votes'));
    },
  },
  {
    id: 'V5', what: 'the empty-race gate: one race is left without a ballot',
    // Repointed rather than deleted, so the row count and the result mix are untouched and exactly
    // one thing differs. Deleting would have tripped the count gate first.
    expect: /3 empty Oregon races of which 2 are Wood Village/,
    apply: (t) => {
      const l = lineFor(t, 'Keith A Kudrna');
      return swap(t, l, l.replace(FAIRVIEW_MAYOR_RACE, FAIRVIEW_P4_RACE));
    },
  },
  {
    id: 'V6', what: 'the drift baseline: an unrelated office loses its term row',
    expect: /drift baseline reads 239, not 238/,
    apply: (t) => swap(t, 'INSERT INTO essentials.race_candidates', [
      'DELETE FROM essentials.office_terms ot',
      ' USING essentials.offices o, essentials.districts d',
      " WHERE ot.office_id = o.id AND o.district_id = d.id",
      "   AND lower(d.state) = 'or' AND d.district_type = 'STATE_UPPER'",
      "   AND (regexp_replace(d.ocd_id, '^.*sldu:', ''))::int = 22;",
      '',
      'INSERT INTO essentials.race_candidates',
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
    if (!ok) { failures++; console.log(stdout.split('\n').slice(-8).join('\n')); }
    continue;
  }
  const ok = failed && c.expect.test(stdout);
  console.log(`${c.id} ${ok ? '🟢' : '🔴'} ${c.what}`);
  if (!ok) { failures++; console.log(`     expected ${c.expect}; it ${failed ? 'stopped otherwise' : 'PASSED'}`); console.log(stdout.split('\n').slice(-8).map((l) => `     ${l}`).join('\n')); }
}
console.log(`\n${CONTROLS.length - failures} of ${CONTROLS.length} controls behaved.`);
process.exit(failures ? 1 : 0);
