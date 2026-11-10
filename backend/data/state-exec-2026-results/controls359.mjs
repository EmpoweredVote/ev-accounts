// Seven tampers on CC_0359. Each is asserted PRESENT in the file it writes, each plants ONE
// fault, each aims at a DIFFERENT gate.
//
// 🔴 A TAMPER THAT DID NOT APPLY IS A CONTROL THAT PROVED NOTHING, AND IT LOOKS LIKE A PASS.
//    A sed quoting error once left a 0-byte file and dry-run-migration reported DRY RUN OK on
//    it — an empty migration passes every gate it does not contain. So every target is required
//    to occur EXACTLY ONCE in the original (a guessed column padding is a silent miss: this
//    suite refused to build three times before the strings were copied out of the real file),
//    and every written file must differ from the original and carry a marker for its fault.
import fs from 'node:fs';
const [, , SP, SRC] = process.argv;
const base = fs.readFileSync(SRC, 'utf8');

const write = (name, text, checks) => {
  const out = `${SP}/${name}`;
  fs.writeFileSync(out, text);
  const back = fs.readFileSync(out, 'utf8');
  if (back.length < 100000) throw new Error(`${name}: TAMPER FILE TRUNCATED (${back.length} bytes)`);
  if (back === base) throw new Error(`${name}: TAMPER DID NOT CHANGE THE FILE`);
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${back.length} bytes)`);
};
const one = (needle, label) => {
  const n = base.split(needle).length - 1;
  if (n !== 1) throw new Error(`TAMPER TARGET "${label}" occurs ${n} times in the file, not once`);
  return needle;
};

const L = {
  tuberville:    one(`   'AL Governor',                 'Tommy Tuberville',            'Thomas Tuberville',       '68308',   'won',    52.06, false, false, '7affca4e-db2b-4f7e-b009-9acc6b493139'::uuid),`, 'AL Gov winner'),
  jones:         one(`   'AL Governor',                 'Doug Jones',                  'Doug Jones',              '3610',    'lost',   47.94, false, false, NULL),`, 'AL Gov loser'),
  alGovRace:     one(`  ('20261103AL1019', 'AL', '8f62b37c-e344-4a24-be98-8c9617ad8f2c'::uuid, '4dc3b465-4921-410c-a3b1-b05bac5004e7'::uuid, 'Governor'),`, 'AL Gov race row'),
  allowJones:    one(`  ('Doug Jones'),\n`, 'allowance: Doug Jones'),
  seedRobertson: one(`  ('AL|Attorney General|171298', 'Katherine Robertson', 'Katherine', 'Robertson',\n`, 'seed Katherine Robertson'),
  vtWinner:      one(`   'VT Lieutenant Governor',      'Molly Gray',                  'Molly Gray',              '71177',   'won',    62.72, false, false, NULL),`, 'VT Lt Gov winner'),
  vtIncumbent:   one(`   'VT Lieutenant Governor',      'John Rodgers',                'John Rodgers',            '147924',  'lost',   37.05, true , false, 'aa4040bf-4468-460e-8cb4-5a1e2a53c34f'::uuid),`, 'VT Lt Gov sitting incumbent'),
};

// A — transpose a winner and a loser. Target: the top-vote-getter gate.
write('u359A-winner-transposed.sql',
  base.replace(L.tuberville, L.tuberville.replace(`'won',    52.06`, `'lost',   52.06`))
      .replace(L.jones,      L.jones     .replace(`'lost',   47.94`, `'won',    47.94`)),
  [['Tuberville not moved to lost', s => s.includes(`'68308',   'lost',   52.06`)],
   ['Jones not moved to won',       s => s.includes(`'3610',    'won',    47.94`)]]);

// B — create a second race on a seat that ALREADY carries a 2026-11-03 one: Nevada's Secretary
//     of State, from CC_0357's tier. Target: the gate that refuses to duplicate a race.
//     ⚠ SHADOWED ON THE FIRST ATTEMPT, AND THE FAILURE LOOKED LIKE A PASS OF THE RIGHT GATE.
//       Swapping only the office id left the row saying "AL" while pointing at a Nevada office,
//       so it tripped the EARLIER "an office is not where this file says" gate — a real refusal
//       of a different gate, which proves nothing about this one. CC_0358's control C went the
//       same way. The row must be made internally CONSISTENT (Nevada office, Nevada label,
//       Nevada election) so that every upstream gate passes and only the duplicate-race gate
//       is left to catch it.
write('u359B-race-already-exists.sql',
  base.replace(L.alGovRace, `  ('20261103AL1019', 'NV', '3ff32b65-b1c3-45b0-8211-d3b72da1a4a7'::uuid, 'f6a18c04-7e7a-4c74-a32f-a7d50f7e50ae'::uuid, 'Secretary of State'),`),
  [['race not repointed at the NV seat', s => s.includes(`('20261103AL1019', 'NV', '3ff32b65-b1c3-45b0-8211-d3b72da1a4a7'::uuid, 'f6a18c04-7e7a-4c74-a32f-a7d50f7e50ae'::uuid, 'Secretary of State'),`)]]);

// C — move the sitting incumbent's flag from the loser to the winner, in Vermont's Lieutenant
//     Governor race. Target: the cross-check against essentials.office_current_holder.
//     🔴 THIS IS THE GATE CC_0358's CONTROLS FOUND MISSING. A count of incumbents cannot catch
//       it — one true moves to another row and the total is unchanged — and a check against the
//       file's own table cannot either, because a tampered file agrees with itself.
write('u359C-incumbency-swapped.sql',
  base.replace(L.vtIncumbent, L.vtIncumbent.replace(`37.05, true , false,`, `37.05, false, false,`))
      .replace(L.vtWinner,    L.vtWinner   .replace(`62.72, false, false,`, `62.72, true , false,`)),
  [['the incumbent was not un-flagged', s => s.includes(`'147924',  'lost',   37.05, false, false,`)],
   ['the winner was not flagged',       s => s.includes(`'71177',   'won',    62.72, true , false,`)]]);

// D — swap a pinned uuid for a DIFFERENT real, active politician: give Alabama's governor-elect
//     the row belonging to Marsha Blackburn. Target: the gate that a pinned uuid is the person
//     the file names. Nothing else here can see it — the INSERT takes the name from that row,
//     so the result would be written under the wrong person without a murmur.
write('u359D-pinned-uuid-swapped.sql',
  base.replace(L.tuberville, L.tuberville.replace(`'7affca4e-db2b-4f7e-b009-9acc6b493139'::uuid`, `'808ab926-365f-4b8a-a42e-628f11ecc48e'::uuid`)),
  [['uuid not swapped', s => s.includes(`'Thomas Tuberville',       '68308',   'won',    52.06, false, false, '808ab926-365f-4b8a-a42e-628f11ecc48e'::uuid)`)]]);

// E — drop Doug Jones from the allowance. Target: the duplicate-name guard, which must then
//     refuse to create a second row carrying a name an active politician already holds.
write('u359E-allowance-removed.sql',
  base.replace(L.allowJones, `  ('Not A Real Name At All'),\n`),
  [['allowance not replaced', s => s.includes(`  ('Not A Real Name At All'),`) && !s.includes(`  ('Doug Jones'),\n`)]]);

// F — corrupt a seeded person's SPLIT, leaving their full name intact. Target: the gate that a
//     seeded name agrees with its own first_name/last_name columns.
//     🔴 THIS TAMPER PASSED ON ITS FIRST RUN — "Robertson-Changed" was written to the last_name
//       column with no complaint, because nothing compared the three name columns at all. The
//       gate was added because of this control. It matters because first_name and last_name are
//       what the repo's duplicate guard keys on, so a wrong split hides that person from it.
write('u359F-seed-surname-altered.sql',
  base.replace(L.seedRobertson, `  ('AL|Attorney General|171298', 'Katherine Robertson', 'Katherine', 'Robertson-Changed',\n`),
  [['seed surname not altered', s => s.includes(`'Katherine', 'Robertson-Changed',`)]]);

// G — point Alabama's Governor race at Arkansas's election row. Target: the gate that each
//     election row is the 2026-11-03 general OF THAT STATE. A race filed under another state's
//     election is invisible to every per-state count and breaks nothing a reader would notice.
write('u359G-election-wrong-state.sql',
  base.replace(L.alGovRace, L.alGovRace.replace(`'4dc3b465-4921-410c-a3b1-b05bac5004e7'::uuid`, `'b333dbd5-2b94-4dc7-8929-9743dc237191'::uuid`)),
  [['election not repointed', s => s.includes(`'b333dbd5-2b94-4dc7-8929-9743dc237191'::uuid, 'Governor'),`)]]);
