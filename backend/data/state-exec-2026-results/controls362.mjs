// Controls on CC_0362. Each tamper asserted PRESENT, one fault each, a different gate each.
import fs from 'node:fs';
const [, , SP, SRC] = process.argv;
const base = fs.readFileSync(SRC, 'utf8');
const write = (name, text, checks) => {
  const out = `${SP}/${name}`;
  fs.writeFileSync(out, text);
  const back = fs.readFileSync(out, 'utf8');
  if (back.length < 9000) throw new Error(`${name}: TAMPER FILE TRUNCATED (${back.length} bytes)`);
  if (back === base) throw new Error(`${name}: TAMPER DID NOT CHANGE THE FILE`);
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${back.length} bytes)`);
};
const one = (needle, label) => {
  const n = base.split(needle).length - 1;
  if (n !== 1) throw new Error(`TAMPER TARGET "${label}" occurs ${n} times, not once`);
  return needle;
};

const L = {
  // Jennie Earl holds UT District 1 and this file pins her to it
  earl: one(`   'Jennie Earl',          'won',  'active',    '21931d93-28de-407f-adc9-ac3844a9e865'::uuid),`, 'the Jennie Earl pin'),
  // the seeded hyphenated name
  seed: one(`  ('Cathy Callow-Heusser', 'Cathy', 'Callow-Heusser',`, 'the Callow-Heusser seed'),
  // one of the six NULL rows being filled
  gipson: one(`  ('41e22561-3dbc-4d52-bdcc-a95bb5da6b8d'::uuid, 'CA Board of Equalization District 3',     'Mike Gipson',       'won',  'California'),`, 'the Mike Gipson row'),
  // the guarded UPDATE
  upd: one(` WHERE rc.id = c.rc_id\n   AND rc.result IS NULL;`, 'the UPDATE predicate'),
  // a District 4 office id, used to repoint District 1's race
  d1race: one(`  ('UT State Board of Education District 1', '6ca19238-7db3-4e28-afba-02ab742b8068'::uuid, '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea'::uuid, 'State Board of Education District 1'),`, 'the District 1 race row'),
};

// A — pin the District 1 seat-holder to District 4's office, which LeAnn Wood holds.
//     Target: the office_current_holder cross-check, in both directions.
write('u362A-wrong-seat.sql',
  base.replace(L.earl, `   'Jennie Earl',          'won',  'active',    '7f68edeb-7087-4e14-a02f-7c5ebcb20f7f'::uuid),`),
  [['pin not swapped', s => s.includes(`'Jennie Earl',          'won',  'active',    '7f68edeb-7087-4e14-a02f-7c5ebcb20f7f'::uuid)`)]]);

// B — corrupt the hyphenated split. Target: the exact-reconstruction gate.
//     🔴 This is the case CC_0360's weaker "ends with the surname" gate could not see:
//        "Cathy Callow-Heusser" ends with "Heusser" too, so containment would PASS it.
write('u362B-hyphen-split.sql',
  base.replace(L.seed, `  ('Cathy Callow-Heusser', 'Cathy', 'Heusser',`),
  [['surname not altered', s => s.includes(`'Cathy', 'Heusser',`)]]);

// C — REPLACE a pinned row with one that already holds a result (Florida's attorney general,
//     written by CC_0359), keeping the row count at six and the name agreeing with the row so
//     the two gates upstream both pass. Target: the overwrite gate.
//     ⚠ SHADOWED TWICE BEFORE THIS SHAPE. Adding a seventh row tripped the count gate; swapping
//       only the id tripped the name gate. A tamper has to leave every earlier gate satisfied
//       or it never reaches the one it is aimed at.
write('u362C-overwrites-a-result.sql',
  base.replace(L.gipson, `  ('001aae6e-ad0d-41da-9179-b65841259df0'::uuid, 'CA Board of Equalization District 3',     'James Uthmeier',    'won',  'California'),`),
  [['pin not repointed at a row that already has a result',
    s => s.includes(`('001aae6e-ad0d-41da-9179-b65841259df0'::uuid, 'CA Board of Equalization District 3',     'James Uthmeier',    'won',  'California'),`)
      && !s.includes(`'Mike Gipson',       'won',  'California'),`)]]);

// 🔴 NO CONTROL FOR THE BEFORE-IMAGE GATE, AND THE REASON IS THE FINDING:
//    in this file that gate is VACUOUS. `before_rows` holds every candidacy in the four races
//    being updated, and ALL SIX of them are pinned — there is no unpinned row for it to protect,
//    so no tamper can make it fire without first breaking a gate upstream of it. It is kept
//    because it costs nothing and goes live the moment a seventh candidacy appears in one of
//    those races, but it is NOT evidence here. The identical gate was proved to fire by
//    CC_0361's control G, on a race that did carry untouched rows.

// E — point District 1's new race at an office in another state entirely (Nevada's Secretary of
//     State). Target: the gate that every office is a Utah state-board seat with real geometry.
//     ⚠ This is the shape of the mistake that CREATED this file: a seat looked absent because a
//       query asked the wrong district_type. Here the file would claim the wrong type outright.
write('u362E-wrong-district-type.sql',
  base.replace(L.d1race, `  ('UT State Board of Education District 1', '3ff32b65-b1c3-45b0-8211-d3b72da1a4a7'::uuid, '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea'::uuid, 'State Board of Education District 1'),`),
  [['race not repointed', s => s.includes(`'UT State Board of Education District 1', '3ff32b65-b1c3-45b0-8211-d3b72da1a4a7'::uuid`)]]);
