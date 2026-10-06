#!/usr/bin/env node
/**
 * gen-ms-legislature-migrations.mjs — Knight program, slice 16 (MS), wave MS-2.
 *
 * Generates the two MS-2 migrations from data/ms-legislature-roster.json:
 *   migrations/CC_0169_ms_legislature_structure.sql   (2 chambers + 174 offices)
 *   migrations/CC_0170_ms_legislature_incumbents.sql  (174 people + 174 terms)
 *
 * Reads nothing from the database and writes nothing to it. Deterministic: the same roster
 * produces byte-identical SQL, so the migrations can be regenerated and diffed rather than
 * hand-edited. 🔴 EDIT THIS SCRIPT, NEVER THE GENERATED SQL.
 *
 * ── 🔴 NAME SPLITTING IS A VOTER-FACING DECISION, NOT A STRING OPERATION ────────────────────
 * `politicians` carries full_name, first_name and last_name, and a UNIQUE-ish guard keys on the
 * PAIR (first_name, last_name) — so the split decides what the duplicate guard can see. MN-2
 * paid for this: `full_name` from the chamber and `first_name` from a different source wrote
 * "Steven Jacob" with first_name "Steve", and the guard keys on the pair, so the collision was
 * invisible until a different bug was fixed. ▶ A FIELD PAIR A CONSTRAINT READS MUST COME FROM
 * ONE SOURCE. Here all three come from the member page's own <DISP_NAME>.
 *
 * Handled explicitly, each because Mississippi actually publishes it:
 *   · generational suffixes — "Sam C. Mims, V", "Henry Zuber III", "Dennis DeBar, Jr."
 *   · quoted nicknames      — 'John Thomas "Trey" Lamar'
 *   · hyphenated surnames   — "Theresa Gillespie-Isom", "Angela Turner Ford" (two words, no hyphen)
 *   · a MISSING SPACE in the source — "Joel R.Carter, Jr." ⚠ This is a typo in the Legislature's
 *     own page. It is repaired, because the alternative is rendering "R.Carter" to a voter, and
 *     the repair is recorded here rather than done silently.
 *
 * ── 🔴 NO term_start IS INVENTED, AND ONE MEMBER PROVES WHY ─────────────────────────────────
 * Member pages carry <LEG_EXP><STRETCH>, e.g. "2016-present". For the seven members whose only
 * stretch is "2026-present" that is the body's own statement that their service began in 2026,
 * and it is written at `year` precision. For everyone else it is a CAREER, not a SEAT.
 * 🔴 CHRIS JOHNSON IS THE COUNTER-EXAMPLE AND HE IS IN THIS WAVE: his page reads "2020-present"
 * plus "House 2016-2019", but he moved from Senate District 45 to Senate District 44 in 2026,
 * so dating SD-44 from his stretch would assert he held that seat from 2020 — six years during
 * which John Polk actually held it. `office_terms` is a SEAT, not a career (MI-4's rule, where
 * two commissioners were dated to the year they CHANGED DISTRICT NUMBER).
 * ▶ So: 7 terms at `year` precision, 167 open-ended at `unknown`, and Johnson is explicitly
 *   among the unknowns with his reason recorded.
 *
 * Usage: node scripts/gen-ms-legislature-migrations.mjs [--names-only]
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROSTER = JSON.parse(fs.readFileSync(path.join(HERE, '..', 'data', 'ms-legislature-roster.json'), 'utf8'));
const MIG = path.join(HERE, '..', 'migrations');

const GOV_ID = '20507fd2-ccdd-4436-9093-63047da0196d'; // State of Mississippi — exactly one row, checked
const SLOT_STRUCT = 'CC_0169';
const SLOT_OCCUP = 'CC_0170';

/**
 * 🔴 THE external_id BAND IS THE ONE ACTUALLY USED, RE-CHECKED AGAINST PRODUCTION.
 * ND-2's rule: the first band reserved there held 14 rows because a DIFFERENT band had been
 * checked. Measured 2026-09-28: -2766400..-2766227 holds 0 rows, while -2766200..-2766000 holds 1.
 */
const EXT_BASE = -2766400;

const CHAMBER = {
  upper: { name: 'Mississippi State Senate', title: 'Senator', dtype: 'STATE_UPPER', count: 52 },
  lower: { name: 'Mississippi House of Representatives', title: 'Representative', dtype: 'STATE_LOWER', count: 122 },
};

const SUFFIX = /^(jr|sr|ii|iii|iv|v)\.?$/i;

/**
 * 🔴 FOUR INCOMING ROWS COLLIDE WITH AN EXISTING ACTIVE PERSON ON THE GUARD'S OWN KEY,
 * (lower(first_name), lower(last_name)), AND ALL FOUR ARE DIFFERENT PEOPLE. Measured against
 * production 2026-09-28, with a positive control: the same key finds 72 active Smiths, 70
 * Johnsons and 45 Williamses, so four hits is a measurement and not a broken sweep.
 * ▶ The guard is lifted for THESE ROWS ONLY, never for the migration — the MN-2 / PA-2 / OH-2
 *   pattern. Each entry has to say who the other person is.
 * ⚠ The Chris Johnson case is the one that had to be checked rather than assumed: the existing
 *   row carries no office and is_incumbent = false, which is exactly the shape of a candidate row
 *   this programme would normally REUSE (MI-2 seated four sitting legislators that way and then
 *   found them hidden because they inherited is_incumbent = false). It is not reusable here — the
 *   row is a LOUISIANA U.S. House District 6 candidate for the 2026 general.
 * ⚠ And "Richard Bennett" matched an existing row whose full_name reads "Rick Bennett": the guard
 *   keys on first_name/last_name, not on full_name, so a diminutive in one field and not the
 *   other is exactly what it sees. MN-2's Steve/Steven, again.
 */
const NAMESAKES = [
  { chamber: 'upper', district: 44, why: 'existing active "Chris Johnson" (external_id -220603) is a LOUISIANA U.S. House District 6 candidate in the LA 2026 Statewide General — no office, no term, one race_candidates row. Different person.' },
  { chamber: 'upper', district: 48, why: 'existing active "Mike Thompson" matches TWO other people — a CALIFORNIA U.S. Representative for Congressional District 4 and a KANSAS state senator for State Senate District 10. Different person from both.' },
  { chamber: 'lower', district: 94, why: 'existing active "Robert B Johnson" is an INDIANA state representative for House District 100. Different person.' },
  { chamber: 'lower', district: 120, why: 'existing active row has first_name "Richard", last_name "Bennett" and full_name "Rick Bennett" — a MAINE state senator for State Senate District 18. Different person, and the pair guard sees it while a full_name comparison would not.' },
];

/** Repairs recorded rather than done silently. Each names the district and what the page says. */
const SOURCE_TYPO_REPAIRS = [
  { chamber: 'upper', district: 49, from: 'Joel R.Carter, Jr.', to: 'Joel R. Carter, Jr.',
    why: 'the member page omits the space after the middle initial; rendering "R.Carter" to a voter is the alternative' },
];

/**
 * 🔴 A COMPOUND SURNAME IS DECIDED BY A SECOND PUBLISHER, NOT BY A LIST I WROTE.
 * Mississippi publishes "Angela Turner Ford", "Hester Jackson McCray", "Theresa Gillespie-Isom"
 * and "Beth Luther Waldo" in the same style, and only three of those four are compound surnames
 * — "Luther" is a middle name. A first version of this file hard-coded the second-to-last tokens
 * it had happened to see, and got Waldo wrong. ▶ Open States writes the surname HYPHENATED
 * ("Turner-Ford", "Jackson-McCray", "Gillespie-Isom") and writes Beth Waldo as "Waldo", so the
 * number of hyphen parts in ITS surname says how many trailing tokens the surname takes here.
 * ⚠ Where Open States has no row for the district (upper 34, lower 70, lower 77 — all simple
 * two-token names) this falls back to a single trailing token, and that fallback is stated.
 */
const OS_CSV = path.join(HERE, '..', 'data', 'seed-ms-2026', '_pages', 'openstates_ms.csv');
const osSurnameByDistrict = { upper: new Map(), lower: new Map() };
{
  const lines = fs.readFileSync(OS_CSV, 'utf8').split(/\r?\n/).filter(Boolean);
  const split = (l) => {
    const out = []; let cur = ''; let q2 = false;
    for (const ch of l) {
      if (ch === '"') q2 = !q2;
      else if (ch === ',' && !q2) { out.push(cur); cur = ''; }
      else cur += ch;
    }
    out.push(cur); return out;
  };
  const hdr = split(lines[0]);
  const iName = hdr.indexOf('name'); const iD = hdr.indexOf('current_district'); const iC = hdr.indexOf('current_chamber');
  for (const l of lines.slice(1)) {
    const c = split(l);
    if (!osSurnameByDistrict[c[iC]]) continue;
    const toks = c[iName].replace(/[.,]/g, ' ').split(/\s+/).filter((t) => t && !SUFFIX.test(t));
    osSurnameByDistrict[c[iC]].set(Number(c[iD]), toks[toks.length - 1] || '');
  }
}

function splitName(displayName, chamber, district) {
  let s = displayName.replace(/\s+/g, ' ').trim();
  // "R.Carter" -> "R. Carter": a period between two letters where the second is upper-case.
  s = s.replace(/([A-Za-z])\.([A-Z])/g, '$1. $2');
  const nickname = (s.match(/"([^"]+)"/) || [])[1] || null;
  const bare = s.replace(/"[^"]*"/g, ' ').replace(/\s+/g, ' ').trim();
  const commaSuffix = bare.match(/^(.*?),\s*((?:jr|sr|ii|iii|iv|v)\.?)$/i);
  const core = (commaSuffix ? commaSuffix[1] : bare).trim();
  const toks = core.split(' ').filter(Boolean);
  while (toks.length > 2 && SUFFIX.test(toks[toks.length - 1])) toks.pop();
  const first = toks[0];
  const osSurname = osSurnameByDistrict[chamber]?.get(district) || '';
  const parts = osSurname ? osSurname.split('-').filter(Boolean).length : 1;
  const lastCount = Math.min(Math.max(parts, 1), toks.length - 1);
  const last = toks.slice(toks.length - lastCount).join(' ');
  return { full: s, first, last, nickname, osSurname: osSurname || null };
}

const rows = [];
let ext = EXT_BASE;
for (const ch of ['upper', 'lower']) {
  for (const m of ROSTER.chambers[ch].members) {
    const repair = SOURCE_TYPO_REPAIRS.find((r) => r.chamber === ch && r.district === m.district);
    const display = repair ? repair.to : m.name;
    const n = splitName(display, ch, m.district);
    const arrived2026 = m.stretches.length === 1 && /^2026[-–]present$/i.test(m.stretches[0]);
    rows.push({
      chamber: ch, district: m.district, geoId: `28${String(m.district).padStart(3, '0')}`,
      dtype: CHAMBER[ch].dtype, title: CHAMBER[ch].title,
      externalId: ext, full: n.full, first: n.first, last: n.last,
      link: m.link, stretches: m.stretches,
      termStart: arrived2026 ? '2026-01-01' : null,
      precision: arrived2026 ? 'year' : 'unknown',
      mapSplit: !!m.mapMemberSplit,
      namesake: NAMESAKES.find((k) => k.chamber === ch && k.district === m.district) || null,
    });
    // 🔴 ASCENDING, so the band used is EXT_BASE .. EXT_BASE + 173 — THE BAND THAT WAS ACTUALLY
    // CHECKED. This first decremented, which meant the ids ran into -2766573 while the emptiness
    // check had been run on -2766400..-2766227: ND-2's rule ("re-check the band you actually
    // use") reproduced exactly, and caught by reading the generator's own printed range against
    // the gate's BETWEEN clause.
    ext += 1;
  }
}

if (process.argv.includes('--names-only')) {
  console.log(JSON.stringify(rows.map((r) => ({ d: `${r.chamber}-${r.district}`, full: r.full, first: r.first, last: r.last })), null, 1));
  process.exit(0);
}

const dated = rows.filter((r) => r.termStart);
console.log(`rows ${rows.length}  (upper ${rows.filter((r) => r.chamber === 'upper').length}, lower ${rows.filter((r) => r.chamber === 'lower').length})`);
console.log(`external_id band ACTUALLY USED: ${EXT_BASE} .. ${ext - 1}  (gate asserts BETWEEN ${EXT_BASE} AND ${EXT_BASE + rows.length - 1})`);
console.log(`dated at year precision: ${dated.length}  -> ${dated.map((d) => `${d.chamber[0]}${d.district} ${d.full}`).join(', ')}`);

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;

// ── the shared source sentence ──────────────────────────────────────────────────────────────
const SOURCE = [
  'Mississippi Legislature member pages, https://billstatus.ls.state.ms.us/members/ — each seat read from the member’s OWN page, whose <DISTRICT> element is the only place the Legislature publishes a seat number (the roster list documents carry names only). Read 2026-09-28.',
  'The list documents ss_membs.xml and hr_membs.xml were last modified 2025-07-01 and 2025-10-14, BOTH BEFORE the court-ordered special elections of 2025-11-04, so their membership and their vacancy markers are stale; eight seats were resolved from the members’ own pages instead, each requiring both that the list holder’s page predates the specials and that Open States names a different surname there and that person nowhere in the chamber.',
  '(MS-2)',
].join(' ');

// ── structure ───────────────────────────────────────────────────────────────────────────────
const struct = `-- ${SLOT_STRUCT}_ms_legislature_structure.sql
-- Knight Foundation program, wave MS-2 (structure half). Slot RESERVED from the allocator.
--
-- Mississippi has NO state legislative offices and NO legislative chambers today. Measured
-- 2026-09-28: production holds ONE Mississippi government row, 'State of Mississippi'
-- (${GOV_ID}, type STATE, state MS, geo_id 28), carrying 5 chambers and 5
-- offices -- Governor, Lieutenant Governor, Attorney General, Secretary of State, Treasurer --
-- all 5 seated, and NOTHING else. 0 of 122 House, 0 of 52 Senate.
--
-- MS-1 loaded the geography (52 STATE_UPPER + 122 STATE_LOWER), so this is a clean seed with
-- nothing to repair. It creates the two chambers and 174 offices. It creates NO people and NO
-- terms -- ${SLOT_OCCUP} does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 BOTH CHAMBERS ARE SINGLE-MEMBER, so unlike SD, ND, AZ and WA the polygon count IS the seat
-- count and "exactly one office per district" is the right shape. No subdistricts, no position
-- numbers, no block voting. The gate asserts one office per district in both chambers.
--
-- ⚠ THE COUNTS ARE MEASURED, NOT CONSTITUTIONAL. Miss. Const. art. 13 s 254 sets CEILINGS --
-- "The Senate shall consist of not more than fifty-two (52) Senators, and the House of
-- Representatives shall consist of not more than one hundred twenty-two (122) Representatives,
-- the number of members of each house to be determined by the Legislature" -- so 52 and 122 are
-- what the current apportionment chose, not a constant. Every apportionment since 1982 has used
-- the ceiling. Read the apportionment before changing these numbers.
--
-- 🔴 TERM LENGTH IS FOUR YEARS IN BOTH CHAMBERS. Members were elected at the general election of
-- November 2023 and the next regular legislative elections are November 2027 -- which is also
-- what art. 13 s 254 means by "Each apportionment shall be effective for the next regularly
-- scheduled elections of members of the Legislature", and what the three-judge court relied on
-- in Doc 318 (2026-09-11) when it recorded that "the Legislature's current composition will
-- remain unchanged until the 2027 election".
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE JOIN KEY IS (geo_id, district_type), NEVER geo_id ALONE, AND MISSISSIPPI IS THE WORST
-- CASE THE PROGRAM HAS MET AFTER PENNSYLVANIA. All three of these overlap:
--     STATE_UPPER  '28001'..'28052'
--     STATE_LOWER  '28001'..'28122'
--     COUNTY       '28001'..'28163'
-- So Senate District 47, House District 47 and HARRISON COUNTY -- this slice's own county -- are
-- ALL '28047'. Nothing below matches on a number or a label; the office insert joins districts by
-- district_type and state, and the gate asserts that no COUNTY district received a legislative
-- office. ⚠ Mississippi also holds 427 G6350 ZCTA rows, which Ohio's slice already recorded
-- colliding with a Summit County lookup.
--
-- 🟢 THE HOST GOVERNMENT IS NOT AMBIGUOUS, AND THAT WAS CHECKED. Production holds exactly ONE
-- 'State of Mississippi' row and exactly one government row with state = 'MS'. Indiana's 18
-- indistinguishable government rows do not recur here, and the gate asserts it.
--
-- 🔴🔴 THE MAP AND THE MEMBER HAVE COME APART IN FIFTEEN DISTRICTS, AND THAT IS RECORDED RATHER
-- THAN SMOOTHED OVER. MS-1 loaded the 2022 lines, because the Supreme Court vacated the judgment
-- approving the 2025 remedial plans on 2026-05-18, the Secretary of State reverted the State's
-- own SEMS to the 2022 lines on 2026-07-24, and the three-judge court held on 2026-09-11 that the
-- 2025 Joint Resolutions "are not operative". But the members seated by the 2025-11-04 specials
-- were elected under the 2025 lines. So in Senate 1, 2, 10, 11, 19, 34, 41, 42, 44, 45 and House
-- 16, 22, 36, 39, 41 the holder of district N may have been elected by a differently-shaped
-- district N. Those districts are named in each office's description.

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '${GOV_ID}', '${CHAMBER.lower.name}', '${CHAMBER.lower.name}', ${CHAMBER.lower.count}, '4'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '${GOV_ID}' AND name = '${CHAMBER.lower.name}');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '${GOV_ID}', '${CHAMBER.upper.name}', '${CHAMBER.upper.name}', ${CHAMBER.upper.count}, '4'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '${GOV_ID}' AND name = '${CHAMBER.upper.name}');

-- ─── 2. The 52 Senate offices, one per STATE_UPPER district ───────────────────

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, '${CHAMBER.upper.title}', 'MS', 1, false, 'full'
FROM essentials.districts d
JOIN essentials.chambers c
  ON c.government_id = '${GOV_ID}' AND c.name = '${CHAMBER.upper.name}'
WHERE lower(d.state) = 'ms'
  AND d.district_type::text = 'STATE_UPPER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id);

-- ─── 3. The 122 House offices, one per STATE_LOWER district ───────────────────

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, '${CHAMBER.lower.title}', 'MS', 1, false, 'full'
FROM essentials.districts d
JOIN essentials.chambers c
  ON c.government_id = '${GOV_ID}' AND c.name = '${CHAMBER.lower.name}'
WHERE lower(d.state) = 'ms'
  AND d.district_type::text = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov        int;
  v_ms_govs    int;
  v_house_ch   int;
  v_senate_ch  int;
  v_senate_off int;
  v_house_off  int;
  v_wrong      int;
  v_county_off int;
  v_vacant     int;
  v_titles     int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE id = '${GOV_ID}' AND name = 'State of Mississippi';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'MS-2 gate: expected exactly 1 State of Mississippi government row, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_ms_govs FROM essentials.governments WHERE state = 'MS';
  IF v_ms_govs <> 1 THEN
    RAISE EXCEPTION 'MS-2 gate: expected exactly 1 government row with state MS, found % — Indiana had 18 indistinguishable rows', v_ms_govs;
  END IF;

  SELECT count(*) INTO v_house_ch FROM essentials.chambers
   WHERE government_id = '${GOV_ID}' AND name = '${CHAMBER.lower.name}';
  SELECT count(*) INTO v_senate_ch FROM essentials.chambers
   WHERE government_id = '${GOV_ID}' AND name = '${CHAMBER.upper.name}';
  IF v_house_ch <> 1 OR v_senate_ch <> 1 THEN
    RAISE EXCEPTION 'MS-2 gate: expected 1 House chamber and 1 Senate chamber, found % and %', v_house_ch, v_senate_ch;
  END IF;

  SELECT count(*) INTO v_senate_off
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text = 'STATE_UPPER';
  SELECT count(*) INTO v_house_off
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text = 'STATE_LOWER';
  IF v_senate_off <> 52 THEN
    RAISE EXCEPTION 'MS-2 gate: expected 52 MS Senate offices, found %', v_senate_off;
  END IF;
  IF v_house_off <> 122 THEN
    RAISE EXCEPTION 'MS-2 gate: expected 122 MS House offices, found %', v_house_off;
  END IF;

  -- 🔴 Single-member, asserted PER DISTRICT rather than only in total. A total of 174 is also
  -- what 173 districts with one office and one district with two would give.
  SELECT count(*) INTO v_wrong
    FROM essentials.districts d
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 1;
  IF v_wrong <> 0 THEN
    RAISE EXCEPTION 'MS-2 gate: % MS legislative district(s) do not hold exactly 1 office — both chambers are single-member', v_wrong;
  END IF;

  SELECT count(*) INTO v_county_off
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text = 'COUNTY'
     AND o.title IN ('${CHAMBER.upper.title}', '${CHAMBER.lower.title}');
  IF v_county_off <> 0 THEN
    RAISE EXCEPTION 'MS-2 gate: % MS COUNTY district(s) received a legislative office — geo_id collision (Harrison County is 28047, Senate District 47 is also 28047)', v_county_off;
  END IF;

  SELECT count(*) INTO v_vacant
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND o.is_vacant IS true;
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'MS-2 gate: expected 0 vacant MS legislative offices, found %', v_vacant;
  END IF;

  SELECT count(DISTINCT o.title) INTO v_titles
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_titles <> 2 THEN
    RAISE EXCEPTION 'MS-2 gate: expected exactly 2 distinct legislative office titles, found % — Mississippi ballots carry no seat or position number', v_titles;
  END IF;

  RAISE NOTICE 'MS-2 structure gate PASSED: 52 Senate + 122 House = 174 offices, every district holds exactly 1, no COUNTY district received one, 0 vacant, 2 distinct titles.';
END $$;

COMMIT;
`;

// ── occupancy ───────────────────────────────────────────────────────────────────────────────
const clean = rows.filter((r) => !r.namesake);
const namesakes = rows.filter((r) => r.namesake);
const peopleValues = (rs) => rs.map((r) =>
  `  (${r.externalId}::bigint, ${q(r.full)}, ${q(r.first)}, ${q(r.last)})`).join(',\n');
const valuesPeople = peopleValues(clean);
const valuesNamesakes = peopleValues(namesakes);
const namesakeNotes = namesakes.map((r) =>
  `--   ${r.chamber === 'upper' ? 'Senate' : 'House '} ${String(r.district).padStart(3)}  ${r.full} — ${r.namesake.why}`).join('\n');

// 🔴 THE ROW SEPARATOR GOES BEFORE THE COMMENT, NOT AFTER IT. A first version appended the
// "-- map/member split" note with `.join(',\n')`, which puts the comma AFTER the comment — so
// the comment ate the separator and the INSERT died on "syntax error at or near (" at the
// SECOND row. Caught by the dry run, which is what a dry run is for.
const valuesTerms = rows.map((r, i) => {
  const ts = r.termStart ? `'${r.termStart}'::date` : 'NULL::date';
  const comma = i === rows.length - 1 ? '' : ',';
  const note = r.mapSplit ? '   -- map/member split: elected under the 2025 lines, seated on the 2022 polygon' : '';
  return `  (${q(r.geoId)}, ${q(r.dtype)}, ${r.externalId}::bigint, ${q(r.full)}, ${ts}, ${q(r.precision)})${comma}${note}`;
}).join('\n');

const occup = `-- ${SLOT_OCCUP}_ms_legislature_incumbents.sql
-- Knight Foundation program, wave MS-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied back to back with ${SLOT_STRUCT}, which creates the 2 chambers and the 174 offices.
--
-- Seats all 174 members of the Mississippi Legislature: 52 senators and 122 representatives.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE ROSTER CAME FROM THE MEMBER PAGES, NOT FROM THE LEGISLATURE'S OWN MEMBER LIST, AND
-- THAT IS THE INVERSE OF EVERY EARLIER WAVE. MN-2 and MI-2 both had a fresh-looking list that had
-- not noticed a departure. Mississippi's lists are the STALE documents and only Last-Modified
-- could say so:
--     ss_membs.xml  last modified 2025-07-01
--     hr_membs.xml  last modified 2025-10-14
-- Both PREDATE the court-ordered special elections of 2025-11-04, while individual member pages
-- are current to 2026-08-18. The Senate list therefore still declares "Vacancy - District 24" and
-- "Vacancy - District 26" -- both filled since -- and still carries John Polk, who retired.
-- ▶ A DOCUMENT'S CONTENT CANNOT TELL YOU ITS AGE; ASK THE SERVER. Justin Pope's page looks exactly
--   like a sitting member's (six committees, a capitol phone, "2026-present") because he IS one.
-- ⚠ AND A PAGE EXISTING IS NOT MEMBERSHIP: senate/polk.xml resolves HTTP 200 with full detail.
-- ⚠ AND STALENESS IS NOT DEPARTURE: 13 of 170 pages predate the specials and most are sitting
--   members in districts the remedy never touched. A page is only edited when something changes.
--
-- 🟢 EIGHT SEATS TURNED OVER SINCE THE LIST, EACH ESTABLISHED BY TWO INDEPENDENT HALVES --
-- the list holder's page predates the specials, AND Open States names a different surname in that
-- district and that person nowhere in the chamber -- after which the successor's own page had to
-- carry the expected <DISTRICT>:
--     Senate  2   David Parker            -> Theresa Gillespie-Isom
--     Senate 24   (list said VACANT)      -> Justin L. Pope
--     Senate 26   (list said VACANT)      -> Kamesha B. Mumford
--     Senate 42   Robin Robinson          -> Don Hartness
--     Senate 44   John A. Polk (retired)  -> Chris Johnson
--     Senate 45   (absent from the list)  -> Johnny L. DuPree
--     House  22   Jonathan Ray Lancaster  -> Justin Crosby
--     House  26   Orlando Paden           -> Otha Williams
-- 🟢 AND THE ARITHMETIC CLOSES WITHOUT SLACK, which is the real control: 52 and 122 exactly.
--
-- 🔴 A NICKNAME IS NOT A DIFFERENT PERSON, AND TWELVE OF THEM WOULD HAVE HIDDEN THESE EIGHT.
-- Open States writes the name people use and the Legislature writes the name on the roll:
-- Chuck/Charles Younger, Bubba/Joseph Tubb, Hank/Henry Zuber, Zack/Zachary Grady, Bubba/Lester
-- Carpenter, Jeff/Jeffrey Guice, Greg/Gregory Holloway, Sam/Samuel Creekmore. None is a prefix
-- rule -- "Bubba" is not short for "Lester" -- so only the SURNAME can carry that test. Every one
-- of the eight turnovers above is a surname change.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 SEVEN TERMS ARE DATED AT YEAR PRECISION AND 167 ARE OPEN-ENDED AT 'unknown'. No Mississippi
-- member page publishes an arrival DATE, and the oath date must not be computed. What the pages
-- do publish is <LEG_EXP><STRETCH>. For the seven members whose only stretch is "2026-present"
-- that is the body's own statement that their service began in 2026, written as 2026-01-01 at
-- 'year' precision. For everyone else a stretch is a CAREER, not a SEAT.
-- 🔴 CHRIS JOHNSON IS THE COUNTER-EXAMPLE AND HE IS IN THIS WAVE. His page reads "2020-present"
-- and "House 2016-2019", but he moved from Senate District 45 to Senate District 44 in 2026, so
-- dating SD-44 from his stretch would assert he held that seat from 2020 -- six years during which
-- John Polk actually held it. office_terms is a SEAT, not a career (MI-4, where two commissioners
-- were dated to the year they CHANGED DISTRICT NUMBER). He is written 'unknown', deliberately.
--
-- 🔴 EVERY politicians INSERT NAMES is_incumbent EXPLICITLY. It defaults to false since CA_0188,
-- and a seated person inserted without it is hidden from address search.
--
-- 🔴 PARTY IS NOT WRITTEN. The member pages carry <PARTY>; party lives on races.primary_party in
-- this schema, never on a person or an office.
--
-- 🔴 external_id BAND -2766400 .. -2766227 (174 ids). The band ACTUALLY USED was re-checked
-- against production on 2026-09-28 and holds 0 rows; the adjacent -2766200..-2766000 holds 1.
-- ND-2's rule: check the band you use, not a neighbouring one.

BEGIN;

-- ─── 1. The ${clean.length} people whose name collides with nobody ─────────────────────────────

CREATE TEMP TABLE ms_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO ms_people(external_id, full_name, first_name, last_name) VALUES
${valuesPeople};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, ${q(SOURCE)}, true, true
FROM ms_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The ${namesakes.length} namesakes — guard lifted for THESE STATEMENTS ONLY ──────────────────
-- 🔴 Measured against production 2026-09-28 on the guard's own key, lower(first_name) and
-- lower(last_name), active rows only, WITH A POSITIVE CONTROL: the same key returns 72 active
-- Smiths, 70 Johnsons and 45 Williamses, so these ${namesakes.length} hits are a measurement and not a broken
-- sweep. Every one is a DIFFERENT PERSON, checked individually:
${namesakeNotes}
-- ⚠ The Chris Johnson row is the one that had to be checked rather than assumed. It carries no
-- office and is_incumbent = false, which is exactly the shape of a candidate row this programme
-- normally REUSES — MI-2 seated four sitting legislators that way and then found them hidden
-- because they inherited is_incumbent = false. It is not reusable here.

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE ms_namesakes(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO ms_namesakes(external_id, full_name, first_name, last_name) VALUES
${valuesNamesakes};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, ${q(SOURCE)}, true, true
FROM ms_namesakes n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 3. The 174 terms ─────────────────────────────────────────────────────────

CREATE TEMP TABLE ms_terms(
  geo_id text, district_type text, external_id bigint,
  sort_key text, term_start date, start_precision text
) ON COMMIT DROP;

INSERT INTO ms_terms(geo_id, district_type, external_id, sort_key, term_start, start_precision) VALUES
${valuesTerms};

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, source)
SELECT o.id, p.id, t.term_start, t.start_precision, ${q(SOURCE)}
FROM ms_terms t
JOIN essentials.districts d ON d.geo_id = t.geo_id AND d.district_type::text = t.district_type AND lower(d.state) = 'ms'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms x WHERE x.office_id = o.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people   int;
  v_terms    int;
  v_seated   int;
  v_unseated int;
  v_dated    int;
  v_notinc   int;
  v_dupdist  int;
  v_johnson  int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE external_id BETWEEN ${EXT_BASE} AND ${EXT_BASE + rows.length - 1};
  IF v_people <> ${rows.length} THEN
    RAISE EXCEPTION 'MS-2 gate: expected ${rows.length} people in the external_id band, found %', v_people;
  END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_terms <> ${rows.length} THEN
    RAISE EXCEPTION 'MS-2 gate: expected ${rows.length} MS legislative terms, found %', v_terms;
  END IF;

  -- 🔴 COUNT och.politician_id, NOT rows. office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_seated <> ${rows.length} THEN
    RAISE EXCEPTION 'MS-2 gate: expected ${rows.length} seated MS legislative offices, found %', v_seated;
  END IF;

  SELECT count(*) INTO v_unseated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);
  IF v_unseated <> 0 THEN
    RAISE EXCEPTION 'MS-2 gate: % MS legislative office(s) carry no term — an office with no term row is INVISIBLE and nothing errors', v_unseated;
  END IF;

  SELECT count(*) INTO v_dated
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND ot.term_start IS NOT NULL;
  IF v_dated <> ${dated.length} THEN
    RAISE EXCEPTION 'MS-2 gate: expected exactly ${dated.length} dated MS legislative terms (the members whose only service stretch is "2026-present"), found %', v_dated;
  END IF;

  SELECT count(*) INTO v_notinc FROM essentials.politicians
   WHERE external_id BETWEEN ${EXT_BASE} AND ${EXT_BASE + rows.length - 1} AND is_incumbent IS DISTINCT FROM true;
  IF v_notinc <> 0 THEN
    RAISE EXCEPTION 'MS-2 gate: % newly seated MS legislator(s) are not flagged is_incumbent — they would be hidden from address search', v_notinc;
  END IF;

  -- 🔴 One holder per district, asserted per district. 174 in total is also what 173 correct
  -- districts plus one carrying two holders and one carrying none would give.
  SELECT count(*) INTO v_dupdist
    FROM essentials.districts d
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND (SELECT count(och.politician_id)
            FROM essentials.office_current_holder och
            JOIN essentials.offices o ON o.id = och.office_id
           WHERE o.district_id = d.id) <> 1;
  IF v_dupdist <> 0 THEN
    RAISE EXCEPTION 'MS-2 gate: % MS legislative district(s) do not resolve to exactly one holder', v_dupdist;
  END IF;

  -- 🔴 Chris Johnson must be UNDATED. His page says "2020-present" and he moved from SD-45 to
  -- SD-44 in 2026; dating this seat from his career would assert he held it while John Polk did.
  SELECT count(*) INTO v_johnson
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text = 'STATE_UPPER' AND d.geo_id = '28044'
     AND p.full_name = 'Chris Johnson' AND ot.term_start IS NULL AND ot.start_precision = 'unknown';
  IF v_johnson <> 1 THEN
    RAISE EXCEPTION 'MS-2 gate: Senate District 44 must be held by Chris Johnson with an UNDATED term (office_terms is a seat, not a career), found %', v_johnson;
  END IF;

  RAISE NOTICE 'MS-2 occupancy gate PASSED: ${rows.length} people, ${rows.length} terms, ${rows.length} seated, 0 unseated offices, ${dated.length} dated at year precision, every district exactly one holder, SD-44 undated.';
END $$;

COMMIT;
`;

fs.writeFileSync(path.join(MIG, `${SLOT_STRUCT}_ms_legislature_structure.sql`), struct);
fs.writeFileSync(path.join(MIG, `${SLOT_OCCUP}_ms_legislature_incumbents.sql`), occup);
console.log(`\nwrote ${SLOT_STRUCT}_ms_legislature_structure.sql and ${SLOT_OCCUP}_ms_legislature_incumbents.sql`);
