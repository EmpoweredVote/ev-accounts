// Five tampers on CC_0358. Each asserted PRESENT in the file it writes, each planting ONE
// fault, each aimed at a DIFFERENT gate. This file CREATES rows rather than updating them,
// so the faults that matter differ from CC_0357's: a duplicated person, a duplicated race,
// a transposed winner, a candidate who resolves to nobody, and a mis-set incumbency flag.
import fs from 'node:fs';
const [, , SP, SRC] = process.argv;
const base = fs.readFileSync(SRC, 'utf8');

const write = (name, text, checks) => {
  const out = `${SP}/${name}`;
  fs.writeFileSync(out, text);
  const back = fs.readFileSync(out, 'utf8');
  if (back.length < 12000) throw new Error(`${name}: TAMPER FILE TRUNCATED (${back.length} bytes)`);
  if (back === base) throw new Error(`${name}: TAMPER DID NOT CHANGE THE FILE`);
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${back.length} bytes)`);
};
const must = (needle, label) => { if (!base.includes(needle)) throw new Error(`TAMPER TARGET MISSING: ${label}`); };

const L = {
  abbott:   `   'Texas Governor',              'Greg Abbott',       '41404',   'lost',   45.69, true),`,
  hinojosa: `   'Texas Governor',              'Gina Hinojosa',     '152027',  'won',    52.82, false),`,
  patrick:  `   'Texas Lieutenant Governor',   'Dan Patrick',       '64382',   'lost',   45.64, true),`,
  goodwin:  `   'Texas Lieutenant Governor',   'Vikki Goodwin',     '153028',  'won',    51.73, false),`,
  johnson:  `   'Texas Attorney General',      'Nathan Johnson',    '152897',  'won',    52.37, false),`,
  seedPat:  `  ('Pat',       'Dixon',       'Pat Dixon'),`,
  raceGov:  `  ('20261103TX45901', 'd660034d-4215-47b0-bb59-3e1616fab09d'::uuid, 'Texas Governor'),`,
};
for (const [k, v] of Object.entries(L)) must(v, k);

// A — transpose the Texas Governor winner and loser. Target: the top-vote-getter gate.
write('uA-winner-transposed.sql',
  base.replace(L.hinojosa, `   'Texas Governor',              'Gina Hinojosa',     '152027',  'lost',   52.82, false),`)
      .replace(L.abbott,   `   'Texas Governor',              'Greg Abbott',       '41404',   'won',    45.69, true),`),
  [['win not moved to Abbott',    s => s.includes(`'Greg Abbott',       '41404',   'won',`)],
   ['Hinojosa not moved to lost', s => s.includes(`'Gina Hinojosa',     '152027',  'lost',`)]]);

// B — seed a person who already exists. Target: the pre-gate that refuses to create a
//     duplicate human. Dan Patrick is already in the database and already in this race.
write('uB-duplicate-person.sql',
  base.replace(L.seedPat, `  ('Dan',       'Patrick',     'Dan Patrick'),`),
  [['duplicate person not seeded', s => s.includes(`('Dan',       'Patrick',     'Dan Patrick'),`)],
   ['Pat Dixon still seeded',      s => !s.includes(L.seedPat)]]);

// C — point a race at an office that ALREADY carries a 2026-11-03 race: Nevada's Secretary
//     of State, from CC_0357's tier. Target: the pre-gate that refuses to duplicate a race.
//     ⚠ FIRST ATTEMPT WAS SHADOWED: I used Nevada's Governor RACE id where an OFFICE id
//       belongs, so it tripped the earlier "target offices exist" gate — a real refusal,
//       but a test of that gate, not of the duplicate-race one. The id must be a real
//       office that already holds a race on this date.
write('uC-race-already-exists.sql',
  base.replace(L.raceGov, `  ('20261103TX45901', '3ff32b65-b1c3-45b0-8211-d3b72da1a4a7'::uuid, 'Texas Governor'),`),
  [['race not repointed', s => s.includes(`('20261103TX45901', '3ff32b65-b1c3-45b0-8211-d3b72da1a4a7'::uuid,`)]]);

// D — name a candidate who matches no politician row, the way copying AP's spelling would.
//     Target: the gate that every named candidate resolves to EXACTLY ONE person.
write('uD-resolves-to-nobody.sql',
  base.replace(L.johnson, `   'Texas Attorney General',      'Nathan M. Johnson', '152897',  'won',    52.37, false),`),
  [['name not altered', s => s.includes(`'Nathan M. Johnson', '152897',`)]]);

// E — move the sitting-incumbent flag from the loser to the winner. Target: the post-verify
//     gate that checks is_incumbent against AP's own flag ROW BY ROW.
//     ⚠ A COUNT of incumbents would NOT catch this: one true becomes another true and the
//       total is unchanged. That is why the gate compares per row.
write('uE-incumbency-swapped.sql',
  base.replace(L.patrick, `   'Texas Lieutenant Governor',   'Dan Patrick',       '64382',   'lost',   45.64, false),`)
      .replace(L.goodwin, `   'Texas Lieutenant Governor',   'Vikki Goodwin',     '153028',  'won',    51.73, true),`),
  [['Patrick still incumbent',    s => s.includes(`'Dan Patrick',       '64382',   'lost',   45.64, false)`)],
   ['Goodwin not made incumbent', s => s.includes(`'Vikki Goodwin',     '153028',  'won',    51.73, true)`)]]);
