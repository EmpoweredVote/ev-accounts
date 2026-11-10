// Six tampers on CC_0357. Each is asserted PRESENT in the file it writes, each plants
// ONE fault, and each is aimed at a DIFFERENT gate.
import fs from 'node:fs';
const [, , SP, SRC] = process.argv;
const base = fs.readFileSync(SRC, 'utf8');

const write = (name, text, checks) => {
  const out = `${SP}/${name}`;
  fs.writeFileSync(out, text);
  const back = fs.readFileSync(out, 'utf8');
  if (back.length < 20000) throw new Error(`${name}: TAMPER FILE TRUNCATED (${back.length} bytes)`);
  if (back === base) throw new Error(`${name}: TAMPER DID NOT CHANGE THE FILE`);
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${back.length} bytes)`);
};
const must = (hay, needle, label) => {
  if (!hay.includes(needle)) throw new Error(`TAMPER TARGET MISSING: ${label}`);
};

// A — transpose Colorado Governor's winner and loser. This is the real mistake: reading
//     ballot order instead of AP's winner flag. Target: the top-vote-getter cross-check.
{
  const won  = `  'CO Governor',                             'Phil Weiser',               '104361',  'won',    60.49),`;
  const lost = `  'CO Governor',                             'Victor Marx',               '174624',  'lost',   33.96),`;
  must(base, won, 'the CO Governor winner line'); must(base, lost, 'the CO Governor loser line');
  write('tA-winner-transposed.sql',
    base.replace(won,  `  'CO Governor',                             'Phil Weiser',               '104361',  'lost',   60.49),`)
        .replace(lost, `  'CO Governor',                             'Victor Marx',               '174624',  'won',    33.96),`),
    [['CO Gov win not moved to Marx', s => s.includes(`'Victor Marx',               '174624',  'won',`)],
     ['Weiser not moved to lost',     s => s.includes(`'Phil Weiser',               '104361',  'lost',`)]]);
}

// B — file California's Lieutenant Governor pin under the CA Governor race instead.
//     Target: the pre-gate that each pinned id exists IN THE RACE THIS FILE STATES.
{
  const needle = `('cb84de45-619a-4219-a117-9a33e9c2d0c8'::uuid, '81e2139a-0d56-4280-8a44-8cbeebeb9c7b'::uuid,`;
  must(base, needle, 'the Fiona Ma pin');
  write('tB-id-in-wrong-race.sql',
    base.replace(needle, `('cb84de45-619a-4219-a117-9a33e9c2d0c8'::uuid, 'bec5ef3b-095b-4d7d-9117-db81e407cb5e'::uuid,`),
    [['pin not refiled under CA Governor', s => s.includes(`('cb84de45-619a-4219-a117-9a33e9c2d0c8'::uuid, 'bec5ef3b-095b-4d7d-9117-db81e407cb5e'::uuid,`)]]);
}

// C — reach past the 53 and stamp rows this file says it does not touch.
//     Target: post-verify check 1, which diffs against the pre-write snapshot.
{
  const needle = `-- ─── Post-verify ───`;
  must(base, needle, 'the post-verify banner');
  const overreach = `UPDATE essentials.race_candidates SET result_recorded_at = now()
 WHERE id IN (SELECT b.id FROM before_rows b WHERE b.result = 'not_nominated' LIMIT 4);

`;
  write('tC-overreach.sql', base.replace(needle, overreach + needle),
    [['over-reaching UPDATE absent', s => s.includes(`WHERE b.result = 'not_nominated' LIMIT 4`)]]);
}

// D — write AP's spelling of a name instead of ours, the way a copy from the feed would.
//     Target: the pre-gate that a pinned id still NAMES the expected person.
//     NV Governor is the right place to plant it: it holds two people called Ford.
{
  const needle = `  'NV Governor',                             'Joe Lombardo',              '70779',   'lost',   44.22),`;
  must(base, needle, 'the Joe Lombardo pin');
  write('tD-ap-spelling.sql',
    base.replace(needle, `  'NV Governor',                             'Joseph Lombardo',           '70779',   'lost',   44.22),`),
    [['AP spelling not written in', s => s.includes(`'Joseph Lombardo',           '70779',`)]]);
}

// E — point one pin at a DIFFERENT candidacy in the same race, one whose prior result is
//     'not_nominated' rather than 'advanced' or NULL. Target: the overwrite gate, which
//     allows a pin to carry only NULL or the 11 recorded 'advanced' values.
//     ⚠ The name must travel with the id, or the NAME gate fires first and shadows this.
//       That is one fault — "this file targets the wrong candidacy" — not two.
{
  const idLine   = `('8e18026b-fbe1-4100-b8d3-ed7aa064fbaf'::uuid, '2fe605ce-d33b-41bc-8e8a-3621512501aa'::uuid,`;
  const nameLine = `  'AZ Attorney General',                     'Warren Petersen',           '101535',  'lost',   44.64),`;
  must(base, idLine, 'the Petersen pin id'); must(base, nameLine, 'the Petersen pin name');
  write('tE-prior-not-advanced.sql',
    base.replace(idLine, `('90f95a3d-55af-40a3-90a1-2a312763ec7d'::uuid, '2fe605ce-d33b-41bc-8e8a-3621512501aa'::uuid,`)
        .replace(nameLine, `  'AZ Attorney General',                     'Rodney Glassman',           '101535',  'lost',   44.64),`),
    [['pin not repointed at Glassman', s => s.includes(`('90f95a3d-55af-40a3-90a1-2a312763ec7d'::uuid, '2fe605ce`)],
     ['name did not travel with it',   s => s.includes(`'Rodney Glassman',           '101535',`)]]);
}

// F — swap one Colorado SoS pin for Alex Astley, the candidate this file deliberately
//     leaves undecided. Every count-based gate still passes: 53 pins, 18 races, 18
//     winners, 53 rows changed.
//     AIMED AT: the post-verify gate that NAMES the undecided rows.
//     ⚠ ACTUALLY FIRED: "1 of the 7 leave-alone rows was changed" — post-verify check 4,
//       which runs earlier. SHADOWED, and left that way on purpose, because this tamper
//       is the only thing that reaches check 4 at all: I had assumed check 4 was subsumed
//       by the snapshot diff, and it is not, because Astley IS pinned here so the diff
//       still counts exactly 53. So F tests check 4, and it is the honest label.
//     🔴 THE UNDECIDED-NAMES GATE IS UNREACHABLE BY TAMPER FROM HERE. Every NULL row in
//       the 18 races is either pinned or on the leave-alone list, so the only way to
//       change the undecided SET is to drop a pin — which trips the 53-pin count gate —
//       or to duplicate one, which the temp table's PRIMARY KEY rejects. It is held by
//       reading, not by a control. It has, however, already failed once for real: its
//       first version expected Astley alone, fired during the dry run, and NAMED Greg
//       Roeberg and Karrin Taylor Robson, which is how the expectation got corrected.
//       A gate that has failed on real data has better evidence behind it than a
//       synthetic tamper would give it.
{
  const idLine   = `('3ccdef2a-62f4-4aa2-a8cc-5a0089fde1f1'::uuid, '030fff92-9ffc-4d6b-9615-06477715e9a7'::uuid,`;
  const nameLine = `  'CO Secretary of State',                   'Celeste Landry',            '178824',  'lost',    0.64),`;
  must(base, idLine, 'the Celeste Landry pin id'); must(base, nameLine, 'the Celeste Landry pin name');
  write('tF-writes-the-undecided.sql',
    base.replace(idLine, `('4c3994f3-06f6-4344-985d-072419744789'::uuid, '030fff92-9ffc-4d6b-9615-06477715e9a7'::uuid,`)
        .replace(nameLine, `  'CO Secretary of State',                   'Alex Astley',               '178824',  'lost',    0.64),`),
    [['pin not repointed at Astley', s => s.includes(`('4c3994f3-06f6-4344-985d-072419744789'::uuid, '030fff92`)],
     ['name did not travel with it', s => s.includes(`'Alex Astley',               '178824',`)]]);
}
