// Controls on CC_0373, CC_0374 and CC_0375. Each tamper is asserted PRESENT in the file before
// it is run, because a tamper that did not apply is a control that proved nothing and it looks
// exactly like a pass (CC_0370: a sed quoting error left a 0-byte file and the dry run reported
// "DRY RUN OK" on an empty migration).
// ⚠ Read the message each one produces, never the exit code.
import fs from 'node:fs';

const MIG = 'C:/ev-accounts-stateexec/backend/migrations';
const [, , OUTDIR] = process.argv;
if (!OUTDIR) throw new Error('usage: controls373.mjs <outdir>');
fs.mkdirSync(OUTDIR, { recursive: true });

const SRC = {
  psc: fs.readFileSync(`${MIG}/CC_0373_ne_public_service_commission.sql`, 'utf8'),
  sboe: fs.readFileSync(`${MIG}/CC_0374_ne_state_board_of_education.sql`, 'utf8'),
  regents: fs.readFileSync(`${MIG}/CC_0375_ne_board_of_regents.sql`, 'utf8'),
};

const make = (name, body, from, to, extra = []) => {
  const src = SRC[body];
  if (!src.includes(from)) throw new Error(`${name}: cannot find ${JSON.stringify(from.slice(0, 90))} in the ${body} migration`);
  if (src.split(from).length - 1 !== 1) throw new Error(`${name}: ${JSON.stringify(from.slice(0, 60))} is not unique`);
  const out = `${OUTDIR}/${name}.sql`;
  fs.writeFileSync(out, src.replace(from, to));
  const back = fs.readFileSync(out, 'utf8');
  if (!back.includes(to)) throw new Error(`${name}: TAMPER DID NOT APPLY`);
  if (back.includes(from)) throw new Error(`${name}: the original line is still there`);
  for (const [why, ok] of extra) if (!ok(back)) throw new Error(`${name}: ${why}`);
  if (Math.abs(back.length - src.length) > 4000) throw new Error(`${name}: the file changed size by too much to be this edit`);
  console.log(`${name}.sql: PRESENT (${back.length} bytes, was ${src.length})`);
};

// A — the seat table says someone else holds District 6. Target: the pre-gate that makes the
//     two independent statements of the roster agree before either is used.
make('t373A-sboe-seat-and-anchor-disagree', 'sboe',
  `  (6, 'Sherry Jones', true, true),`,
  `  (6, 'Grady Erickson', true, true),`);

// B — the anchor table claims Hall County for District 5 rather than District 6. Target: the
//     pre-gate that every anchor is a county the canvass assigns WHOLE to its own district.
//     ⚠ The county is changed, not the district number: the anchor table is keyed on the
//     district, so moving a district number would fail on the primary key and never reach the
//     gate under test. Otoe is a real whole county of District 2.
make('t373B-sboe-anchor-county-wrong-district', 'sboe',
  `  (6, 'Hall County', 'Sherry Jones'),`,
  `  (6, 'Otoe County', 'Sherry Jones'),`);

// C — 🔴 the anchor table names the wrong member, and ONLY the anchor table. The seat table is
//     untouched, so this is the CC_0369 control C shape: a gate that read the member's name out
//     of the thing it is checking would not notice.
make('t373C-sboe-anchor-names-wrong-member', 'sboe',
  `  (7, 'Lincoln County', 'Elizabeth Tegtmeier');`,
  `  (7, 'Lincoln County', 'Kirk Penner');`);

// D — drop an anchor for a district that has a whole county. Target: the pre-gate that every
//     district which CAN be anchored IS, so the anchored set cannot quietly shrink.
make('t373D-sboe-anchor-dropped', 'sboe',
  `  (3, 'Dodge County', 'Lisa Schonhoff'),\n`, ``,
  [['the anchor count assertion was not left alone', s => s.includes(`expected 5 anchors, found %`)]]);

// E — a race on a seat that was not on the ballot, and a ballot with no race. Target: the
//     pre-gate that keeps on_ballot_2026 and race_recorded from drifting apart.
//     🔴 THE ONE-LINE VERSION OF THIS CONTROL FIRED ON THE WRONG GATE. Setting District 2 to
//     (on_ballot false, race true) alone took the count of seats on the ballot to 0 and the
//     run stopped at "expected 1 seats on the ballot, found 0" — an earlier gate, so the gate
//     under test was never reached and the control proved nothing about it. Moving the ballot
//     flag to District 1 at the same time keeps both counts at 1 and lets the disagreement
//     gate be the one that fires. ▶ A control that fails is not the same as a control that
//     fails where you aimed it (CC_0370 control E).
make('t373E-psc-race-without-a-ballot', 'psc',
  `  (1, 'Dan Watermeier', false, false),\n  (2, 'Christian Mirch', true, true),`,
  `  (1, 'Dan Watermeier', true, false),\n  (2, 'Christian Mirch', false, true),`);

// F — 🔴 THE WINNER IS NOT THE LEADING CANDIDATE. A "won" flag and a vote count are two
//     separate facts and this file is the only place they are made to agree.
make('t373F-sboe-winner-is-not-the-leader', 'sboe',
  `  (8, 'Lou Ann Goding', 'won', 41772, false),\n  (8, 'Sherrye Hutcherson', 'lost', 40255, false)`,
  `  (8, 'Lou Ann Goding', 'lost', 41772, false),\n  (8, 'Sherrye Hutcherson', 'won', 40255, false)`);

// G — 🔴🔴 THE POINT-TO-MEMBER CHAIN. The chain joins a county's point through the geofence to
//     the district, the office and the holder. Point it at the wrong district_type and it can
//     no longer find the district at all, which is what a wrong office-to-district join looks
//     like from the outside (CC_0370 control D).
make('t373G-regents-chain-wrong-district-type', 'regents',
  `        JOIN essentials.districts dd ON dd.geo_id = gb.geo_id AND dd.mtfcc = gb.mtfcc\n         AND dd.district_type = 'STATE_BOARD'`,
  `        JOIN essentials.districts dd ON dd.geo_id = gb.geo_id AND dd.mtfcc = gb.mtfcc\n         AND dd.district_type = 'STATE_BOARD_EDUCATION'`);

// H — an office is left unseated. Target: the post-verify that every new office carries a term,
//     and behind it the 238 unflagged drift baseline.
make('t373H-psc-one-office-left-unseated', 'psc',
  `  FROM seat s JOIN made_office mo ON mo.d = s.d JOIN person pe ON pe.who = s.who;`,
  `  FROM seat s JOIN made_office mo ON mo.d = s.d JOIN person pe ON pe.who = s.who WHERE s.d <> 4;`);

// I — 🔴🔴 THE NEBRASKA HAZARD IN THE MIGRATION. The Public Service Commission and the Board of
//     Regents are BOTH STATE_BOARD districts in Nebraska. This copy drops the geo_id scoping
//     from the "does this body already exist" pre-gate, which is the form every earlier state
//     could safely use. Run it AFTER CC_0373 has been applied: it must refuse, naming five
//     districts that belong to the other body.
make('t373I-regents-pregate-not-scoped-by-prefix', 'regents',
  `   WHERE district_type = 'STATE_BOARD' AND lower(state) = 'ne' AND geo_id LIKE 'ocd-division/country:us/state:ne/regents:%';`,
  `   WHERE district_type = 'STATE_BOARD' AND lower(state) = 'ne';`);

console.log(`
Run each with scripts/dry-run-migration.mjs and READ THE MESSAGE:
  A  sboe     -> the anchor table and the seat table name different members
  B  sboe     -> an anchor county is not assigned whole to its district by the canvass
  C  sboe     -> the anchor table and the seat table name different members (anchor side)
  D  sboe     -> expected 5 anchors, found 4
  E  psc      -> a seat disagrees with itself about the ballot and the race
  F  sboe     -> the winner is not the leading candidate in: D8
  G  regents  -> an anchor county does not reach its member
  H  psc      -> 1 of the 5 offices have no term and would raise the drift metric
  I  regents  -> 5 Nebraska district(s) ... already exist   ⚠ ONLY AFTER CC_0373 IS APPLIED`);
