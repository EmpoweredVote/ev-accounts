// Controls on CC_0360 and CC_0361. Each tamper is asserted PRESENT in the file it writes, each
// plants ONE fault, each aims at a DIFFERENT gate.
//
// 🔴 A TAMPER THAT DID NOT APPLY IS A CONTROL THAT PROVED NOTHING, AND IT LOOKS LIKE A PASS.
//    Every target must occur EXACTLY ONCE in the original and every written file must carry a
//    marker for its fault. Guessed column padding is a silent miss — these strings were copied
//    out of the generated files, not typed from memory.
import fs from 'node:fs';
const [, , SP, SRC360, SRC361] = process.argv;
const b360 = fs.readFileSync(SRC360, 'utf8');
const b361 = fs.readFileSync(SRC361, 'utf8');

const mk = (base, min) => (name, text, checks) => {
  const out = `${SP}/${name}`;
  fs.writeFileSync(out, text);
  const back = fs.readFileSync(out, 'utf8');
  if (back.length < min) throw new Error(`${name}: TAMPER FILE TRUNCATED (${back.length} bytes)`);
  if (back === base) throw new Error(`${name}: TAMPER DID NOT CHANGE THE FILE`);
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${back.length} bytes)`);
};
const w360 = mk(b360, 20000), w361 = mk(b361, 8000);
const one = (base, needle, label) => {
  const n = base.split(needle).length - 1;
  if (n !== 1) throw new Error(`TAMPER TARGET "${label}" occurs ${n} times, not once`);
  return needle;
};

const L = {
  paWin:   one(b360, `   'PA Lieutenant Governor',                  'Austin Davis',                'won',   'active',    false, true , 'fc75d0fc-a205-43e2-ab13-80a1caecdff5'::uuid),`, 'PA Lt Gov winner'),
  alLose:  one(b360, `   'AL Treasurer',                            'Rosilyn Houston',             'lost',  'active',    false, false, NULL),`, 'AL Treasurer loser'),
  seedLine:one(b360, `  ('TX|Texas Comptroller|V. Alonzo Echavarria-Garza', 'V. Alonzo Echavarria-Garza', 'V. Alonzo', 'Echavarria-Garza',`, 'the Echavarria-Garza seed'),
  seedUrl: one(b360, `   'https://ballotpedia.org/V._Alonzo_Echavarria-Garza (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),`, 'that seed’s citation'),
  azWin:   one(b361, `   'AZ Commissioner',                         'Jonathon Hill',             'won',   'advanced'),`, 'an AZ Corporation Commission winner'),
  caPrior: one(b361, `   'CA Controller',                           'Malia M. Cohen',            'won',   NULL),`, 'CA Controller winner'),
  update:  one(b361, ` WHERE rc.id = c.rc_id\n   AND (rc.result IS NULL OR rc.result = 'advanced');`, 'the UPDATE predicate'),
};

// ── CC_0360 ──

// A — 🔴 THE TICKET TRAP ITSELF: take the ticket HEAD instead of the running mate, which is
//     exactly what reading Ballotpedia's table row gives you. Josh Shapiro ran for GOVERNOR of
//     Pennsylvania; this seats him as its lieutenant governor. His real politician id is used
//     so the pinned-name gate passes and only the ticket gate is left to catch it.
w360('u360A-ticket-head-taken.sql',
  b360.replace(L.paWin, `   'PA Lieutenant Governor',                  'Josh Shapiro',                'won',   'active',    false, true , 'c3956e15-01f6-46cf-95bd-edd43f0ae8f3'::uuid),`),
  [['the governor was not substituted', s => s.includes(`'Josh Shapiro',                'won',   'active',    false, true , 'c3956e15-01f6-46cf-95bd-edd43f0ae8f3'::uuid)`)]]);

// B — promote a loser so a race holds two winners. Target: the one-winner-per-race gate.
w360('u360B-two-winners.sql',
  b360.replace(L.alLose, `   'AL Treasurer',                            'Rosilyn Houston',             'won',   'active',    false, false, NULL),`),
  [['the loser was not promoted', s => s.includes(`'Rosilyn Houston',             'won',`)]]);

// C — corrupt a seeded split so the name no longer reconstructs. Target: the split gate.
w360('u360C-bad-split.sql',
  b360.replace(L.seedLine, `  ('TX|Texas Comptroller|V. Alonzo Echavarria-Garza', 'V. Alonzo Echavarria-Garza', 'V. Alonzo', 'Garza',`),
  [['surname not altered', s => s.includes(`'V. Alonzo', 'Garza',`)]]);

// D — cite a seed to an anchor inside ANOTHER person's article — which is literally what
//     Ballotpedia's "personal" link was for two of the running mates here. Target: the gate
//     that a source is a plain Ballotpedia page and not a fragment.
w360('u360D-anchored-citation.sql',
  b360.replace(L.seedUrl, `   'https://ballotpedia.org/Sarah_Eckhardt#Campaign_themes (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),`),
  [['citation not repointed', s => s.includes('https://ballotpedia.org/Sarah_Eckhardt#Campaign_themes')]]);

// ── CC_0361 ──

// E — demote one of Arizona's TWO winners. Target: the winners-equal-seats gate.
//     ⚠ A fixed "exactly one winner" check — correct everywhere else in this series — would
//       PASS this tampered file and FAIL the real one. That is why the gate reads races.seats.
w361('u361E-multiseat-one-winner.sql',
  b361.replace(L.azWin, `   'AZ Commissioner',                         'Jonathon Hill',             'lost',  'advanced'),`),
  [['winner not demoted', s => s.includes(`'Jonathon Hill',             'lost',  'advanced')`)]]);

// F — claim a prior value the row does not hold. Target: the overwrite gate, which must refuse
//     to replace anything whose previous value this file has not correctly written down.
w361('u361F-wrong-prior.sql',
  b361.replace(L.caPrior, `   'CA Controller',                           'Malia M. Cohen',            'won',   'advanced'),`),
  [['prior not altered', s => s.includes(`'Malia M. Cohen',            'won',   'advanced')`)]]);

// G — touch a row this file deliberately leaves alone, while leaving every pinned row correct.
//     Target: the post-verify that every UNPINNED row in these races is byte-identical to its
//     before-image. ⚠ No COUNT would show this — all 34 pinned rows still get exactly the
//     results the file promises, and the extra write lands on a row nothing else looks at.
//     ⚠ SHADOWED ON THE FIRST ATTEMPT: widening the UPDATE's WHERE to the whole race made the
//       FROM-join match several `calls` rows per target, so Postgres wrote an arbitrary one and
//       the PINNED rows came out wrong. It failed on "only 14 of the 34 pinned rows hold their
//       stated result" — a real refusal, of the gate before this one, which proves nothing
//       about this one. The fault has to leave the pinned rows intact to reach the gate it aims at.
// Katherine Haley lost Arizona's Treasurer PRIMARY and is 'not_nominated'. She never reached
// the general ballot, so writing 'lost' on her row would quietly claim she stood in it.
w361('u361G-untouched-row-written.sql',
  b361.replace(L.update, `${L.update}\n\nUPDATE essentials.race_candidates\n   SET result = 'lost'\n WHERE id = 'a2a04b10-385e-4c10-98f4-0dfc144839ed'::uuid;`),
  [['the extra UPDATE was not added', s => s.includes("WHERE id = 'a2a04b10-385e-4c10-98f4-0dfc144839ed'::uuid;")]]);
