// Controls on CC_0363. Each asserted PRESENT, one fault each, a different gate each.
import fs from 'node:fs';
const [, , SP, SRC] = process.argv;
const base = fs.readFileSync(SRC, 'utf8');
const write = (name, text, checks) => {
  const out = `${SP}/${name}`;
  fs.writeFileSync(out, text);
  const back = fs.readFileSync(out, 'utf8');
  if (back.length < 15000) throw new Error(`${name}: TAMPER FILE TRUNCATED (${back.length} bytes)`);
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
  // 🔴 the gate that makes creating offices safe at all
  terms: one(`INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)`, 'the office_terms insert'),
  // Alabama's Auditor — a seat we are creating
  alSeat: one(`  ('AL', 'Auditor', 'AL Auditor', 'Alabama',`, 'the AL Auditor seat row'),
  // the allowance for a deliberate same-name seed
  allowKing: one(`  ('John King')`, 'the John King allowance'),
  // a seeded split
  seedWaites: one(`'Keisha Sean Waites', 'Keisha Sean', 'Waites',`, 'the Keisha Sean Waites seed'),
};

// A — 🔴 DO NOT SEAT THE OFFICEHOLDERS. This is the whole reason the file writes terms: 25
//     offices with no office_terms row would take the unflagged drift baseline from 238 to 263
//     and hand the next person a red gate for drift nobody introduced.
//     Target: the "every new office is seated" gate AND the baseline assertion.
write('u363A-offices-left-unseated.sql',
  base.replace(L.terms, `-- TAMPER: the office_terms insert is disabled\nINSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)`)
      .replace(`SELECT hp.office_id, hp.pid, NULL, NULL, 'unknown', 'unknown', hp.src FROM holder_pin hp;`,
               `SELECT hp.office_id, hp.pid, NULL, NULL, 'unknown', 'unknown', hp.src FROM holder_pin hp WHERE false;`),
  [['the term insert was not disabled', s => s.includes('FROM holder_pin hp WHERE false;')]]);

// B — claim Alabama's FIPS is Alaska's. Target: the gate that the geo_id this file writes is
//     the one the state's existing districts already use. 🔴 geo_id is a LOOKUP KEY: a wrong
//     one is not a typo, it is an office no address can ever reach.
write('u363B-wrong-fips.sql',
  base.replace(L.alSeat, `  ('AL', 'Auditor', 'AL Auditor', 'Alabama',\n   '02',`).replace(/\n   '01',/, ''),
  [['FIPS not altered', s => /\('AL', 'Auditor', 'AL Auditor', 'Alabama',\s*\n\s*'02',/.test(s)]]);

// C — drop John King from the allowance. Target: the duplicate-name guard, which must then
//     refuse to create a second row carrying a name an active politician already has.
write('u363C-allowance-removed.sql',
  base.replace(L.allowKing, `  ('Not A Real Name At All')`),
  [['allowance not replaced', s => s.includes(`('Not A Real Name At All')`) && !s.includes(`  ('John King')`)]]);

// D — corrupt a compound surname. Target: the exact-reconstruction split gate. "Keisha Sean
//     Waites" would still END WITH "Waites", so the containment form CC_0360 shipped cannot
//     see a first-name corruption at all.
write('u363D-bad-split.sql',
  base.replace(L.seedWaites, `'Keisha Sean Waites', 'Keisha', 'Waites',`),
  [['split not altered', s => s.includes(`'Keisha Sean Waites', 'Keisha', 'Waites',`)]]);

// E — point Alabama's new office at an office title we already hold ("Treasurer"), which would
//     create a second Alabama Treasurer. Target: the gate that none of these 25 already exists
//     under ANY district type — the gate written because CC_0362's predecessor filtered on
//     STATE_EXEC and reported seats we DO hold as absent.
write('u363E-duplicates-an-office.sql',
  base.replace(L.alSeat, `  ('AL', 'Treasurer', 'AL Auditor', 'Alabama',`),
  [['office title not changed', s => s.includes(`('AL', 'Treasurer', 'AL Auditor', 'Alabama',`)]]);
