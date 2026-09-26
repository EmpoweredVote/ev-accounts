#!/usr/bin/env node
/**
 * gen-mi-legislature-migrations.mjs — Knight program, wave MI-2.
 *
 * Generates the two MI-2 migrations from data/mi-legislature-roster.json:
 *   migrations/CC_0138_mi_legislature_structure.sql   — 2 chambers + 148 offices
 *   migrations/CC_0139_mi_legislature_incumbents.sql  — 144 people + 148 terms
 * Both slots were RESERVED from the allocator before either file was named.
 * Reads nothing from the database and writes nothing to it.
 *
 * 🔴 THE JOIN KEY IS (geo_id, district_type), NEVER geo_id ALONE. TIGER writes Michigan's
 * legislative GEOIDs as state FIPS + district code, so Senate District 31 is '26031' and House
 * District 71 is '26071' — and Michigan's 83 COUNTY districts occupy '26001'..'26165'. All 38
 * Senate geo_ids are also a county's. Wayne County, this slice's own jurisdiction, is '26163',
 * outside the legislative range, but that is luck and not a reason to relax the key.
 *
 * 🔴 FOUR PEOPLE ARE REUSED, NOT CREATED, AND THAT IS THE GUARD'S OWN "NORMAL CASE".
 * Each already exists because they are a sitting Michigan legislator who won a 2026 federal
 * primary, so production already holds them as a CANDIDATE. Creating a second row would split
 * their quotes and race edges away from the person a voter sees.
 *
 * 🔴 TWO MORE COLLIDE WITH A DIFFERENT PERSON IN ANOTHER JURISDICTION and need the guard lifted
 * for their statement only — the GA/OH trap again, and both were found by sweeping the GUARD'S
 * OWN KEY (lower(first_name), lower(last_name)) against ACTIVE rows, controlled at 68 Smiths.
 *
 * 🔴 NO term_start IS INVENTED and no term_end is written. See the migration headers.
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROSTER = path.join(HERE, '..', 'data', 'mi-legislature-roster.json');
const MIG = path.join(HERE, '..', 'migrations');

const GOV = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f'; // the single 'State of Michigan' row
const BAND_START = -2770001; // measured free: 0 rows in -2770200..-2770001 on 2026-09-24

const CHAMBERS = {
  lower: { name: 'Michigan House of Representatives', title: 'Representative', count: 110, term: '2', type: 'STATE_LOWER' },
  upper: { name: 'Michigan Senate', title: 'Senator', count: 38, term: '4', type: 'STATE_UPPER' },
};

// Sitting Michigan legislators production ALREADY HOLDS, as 2026 federal candidates.
// Each verified individually: the candidacy is documented and the state seat matches.
const REUSE = {
  'lower-11': { external_id: -261302, why: 'Donavan McKinney, HD-11, won the Democratic primary for MI-13 on 2026-08-05 (defeating Rep. Shri Thanedar); production holds him as that candidate.' },
  'upper-19': { external_id: -260402, why: 'Sean McCann, SD-19, term-limited in the Senate, won the Democratic primary for MI-04 on 2026-08-04; production holds him as that candidate.' },
  'upper-7': { external_id: -261103, why: 'Jeremy Moss, SD-7, won the Democratic primary for MI-11 on 2026-08-04; production holds him as that candidate.' },
  'upper-8': { external_id: -400123, why: 'Mallory McMorrow, SD-8, is a 2026 U.S. Senate candidate; production holds her on the office literally titled "Candidate for U.S. Senate — Michigan".' },
};

// Same name as an ACTIVE row that is a DIFFERENT PERSON. A person cannot hold both seats.
const NAMESAKES = {
  'lower-68': { collides_with: -2745026, why: 'David Martin, HD-68 (Davison, Michigan), collides with -2745026 "David Martin", who SITS TODAY as a SOUTH CAROLINA state Representative for SC HD-26 (seated by the SC-2 wave).' },
  'lower-83': { collides_with: -2507000008, why: 'John Fitzgerald, HD-83 (Wyoming, Michigan), collides with -2507000008 "John FitzGerald", who SITS TODAY as a BOSTON, MASSACHUSETTS city councillor for district 3. Note the differing capitalisation — the guard lowercases, so it caught what an exact match would not.' },
};

const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8'));
const seats = roster.seats.slice().sort((a, b) => (a.chamber === b.chamber ? a.district - b.district : a.chamber < b.chamber ? -1 : 1));

if (seats.length !== 148) throw new Error(`roster holds ${seats.length} seats, expected 148`);
for (const [ch, def] of Object.entries(CHAMBERS)) {
  const n = seats.filter((s) => s.chamber === ch).length;
  if (n !== def.count) throw new Error(`${ch}: roster holds ${n}, the constitution fixes ${def.count}`);
}

const key = (s) => `${s.chamber}-${s.district}`;
const newPeople = seats.filter((s) => !REUSE[key(s)]);
if (newPeople.length !== 148 - Object.keys(REUSE).length) throw new Error('reuse arithmetic is wrong');
newPeople.forEach((s, i) => { s.external_id = BAND_START - i; });
for (const s of seats) if (REUSE[key(s)]) s.external_id = REUSE[key(s)].external_id;

const q = (v) => (v === null || v === undefined ? 'NULL' : `$$${v}$$`);
const SOURCE =
  'Michigan Legislature combined legislator list, https://legislature.mi.gov/Legislature/Legislators; ' +
  'reconciled against the Michigan Senate\'s own list, https://senate.michigan.gov/senators/all-senators/, ' +
  'the Michigan House list, https://house.mi.gov/AllRepresentatives, and Open States, ' +
  'https://data.openstates.org/people/current/mi.csv; change-checked against 147 individual member pages ' +
  '(HD-4 publishes none), every one of which names its own member in its own title; read 2026-09-24 (MI-2)';

// ── CC_0138 — structure ─────────────────────────────────────────────────────
const officeRows = seats
  .map((s) => `  (${q(s.geo_id)}, ${q(CHAMBERS[s.chamber].type)}, ${q(CHAMBERS[s.chamber].name)}, ${q(CHAMBERS[s.chamber].title)})`)
  .join(',\n');

const structure = `-- CC_0138_mi_legislature_structure.sql
-- Knight Foundation program, wave MI-2 (structure half). Slot RESERVED from the allocator.
--
-- Michigan has NO state legislative offices and NO legislative chambers today: production holds
-- 4 Michigan state offices in total, all statewide executives (Governor, Lieutenant Governor,
-- Secretary of State, Attorney General), plus 13 U.S. House and 2 U.S. Senate seats on the
-- federal government row.
-- ⚠ AND FOUR MORE ROWS UNDER 'U.S. Senate' ARE CANDIDATE OFFICES, NOT SENATORS — Michigan shows
-- 6 rows on that chamber for a 2-senator state. The extra four are titled
-- 'Candidate for U.S. Senate — Michigan'. This is the Sherrod Brown trap from OH-2, recurring.
-- Nothing here counts them.
--
-- MI-1 loaded the geography (110 STATE_LOWER + 38 STATE_UPPER, vintage PROVEN SEPARATELY PER
-- CHAMBER against the State of Michigan's own layers), so this migration is a clean seed with
-- nothing to repair. It:
--
--   1. creates the two chambers;
--   2. creates 148 offices, one per district MI-1 loaded.
--
-- Creates NO people and NO terms -- CC_0139 does that, and the two are applied back to back.
--
-- 🔴 THE JOIN KEY IS (geo_id, district_type), NEVER geo_id ALONE. Senate District 31 is '26031'
-- and House District 71 is '26071', while Michigan's 83 COUNTY districts occupy '26001'..'26165'.
-- All 38 Senate geo_ids are also a county's. Wayne County -- Detroit's parent and this slice's
-- own jurisdiction -- is '26163', outside the legislative range, but that is luck, not a reason
-- to match on a number. The gate below asserts no county district took a legislative office.
--
-- 🟢 THE HOST GOVERNMENT IS NOT AMBIGUOUS, AND THAT WAS CHECKED. Production holds exactly ONE
-- 'State of Michigan' row, ${GOV} (type STATE, state MI, geo_id 26).
-- Indiana's 18 indistinguishable government rows do NOT recur here, and the gate asserts it.
--
-- 🟢 THERE ARE NO VACANCIES. All 148 seats are filled -- unlike OH-2 (two vacant) and MN-2 (one).
-- That was not assumed from a count: the House's own roster lists only 109 of 110 districts, and
-- 58 R + 51 D = 109 looks exactly like a one-seat vacancy.
-- 🔴🔴 IT IS NOT A VACANCY, AND SEATING IT AS ONE WOULD HAVE DELETED A SITTING MEMBER FROM EVERY
-- ADDRESS IN HER DISTRICT. house.mi.gov/AllRepresentatives is the UNION OF THE TWO CAUCUS
-- WEBSITES -- every row links to gophouse.org or housedems.com. Karen Whitsett (HD-4, Detroit)
-- announced in March 2026 that she was leaving the Democratic Party and would not seek
-- re-election; she holds the seat until the term ends 2026-12-31. Belonging to neither caucus,
-- she has no row to render. The Legislature's OWN list, which is not a caucus list, carries her,
-- and so does Open States.
-- ▶ AN ABSENCE ON A CHAMBER'S OWN ROSTER IS NOT A VACANCY. Ask what the roster is ASSEMBLED FROM.
--
-- 🔴 PARTY IS NOT WRITTEN. All four sources carry it; party lives on races.primary_party.
-- ⚠ Open States still lists Whitsett as a Democrat six months after she left the party, which is
-- one more reason not to read party from a roster.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────
-- term_length: Mich. Const. art. IV, s 3 -- Representatives two years, Senators four.
-- official_count: 110 and 38, fixed by Mich. Const. art. IV, s 2 and s 3, and equal to the
-- polygon counts MI-1 loaded because Michigan is single-member in both chambers.

${Object.values(CHAMBERS)
  .map(
    (c) => `INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '${GOV}', ${q(c.name)}, ${q(c.name)}, ${c.count}, ${q(c.term)}
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '${GOV}' AND name = ${q(c.name)});`
  )
  .join('\n\n')}

-- ─── 2. The 148 offices, one per district MI-1 loaded ─────────────────────────
-- Guarded on district_id: Michigan has no legislative office at all today, so this inserts 148
-- on a first run and 0 on any re-run. Every row is is_vacant false -- Michigan has no vacancy.

CREATE TEMP TABLE mi_offices(geo_id text, district_type text, chamber_name text, title text) ON COMMIT DROP;

INSERT INTO mi_offices(geo_id, district_type, chamber_name, title) VALUES
${officeRows};

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, m.title, 'MI', 1, false, 'full'
FROM mi_offices m
JOIN essentials.districts d
  ON d.geo_id = m.geo_id AND d.district_type::text = m.district_type AND lower(d.state) = 'mi'
JOIN essentials.chambers c
  ON c.government_id = '${GOV}' AND c.name = m.chamber_name
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id);

-- ─── post-verify gate ─────────────────────────────────────────────────────────
DO $gate$
DECLARE
  v_gov      integer;
  v_chambers integer;
  v_lower    integer;
  v_upper    integer;
  v_vacant   integer;
  v_county   integer;
  v_nulldist integer;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE name = 'State of Michigan' AND type = 'STATE';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'MI-2 gate 1: expected exactly 1 "State of Michigan" government row, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_chambers FROM essentials.chambers
   WHERE government_id = '${GOV}'
     AND name IN (${Object.values(CHAMBERS).map((c) => q(c.name)).join(', ')});
  IF v_chambers <> 2 THEN
    RAISE EXCEPTION 'MI-2 gate 2: expected 2 legislative chambers, found %', v_chambers;
  END IF;

  SELECT count(*) FILTER (WHERE d.district_type::text = 'STATE_LOWER'),
         count(*) FILTER (WHERE d.district_type::text = 'STATE_UPPER'),
         count(*) FILTER (WHERE o.is_vacant)
    INTO v_lower, v_upper, v_vacant
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = '${GOV}'
     AND c.name IN (${Object.values(CHAMBERS).map((c) => q(c.name)).join(', ')});

  IF v_lower <> 110 OR v_upper <> 38 THEN
    RAISE EXCEPTION 'MI-2 gate 3: expected 110 House and 38 Senate offices, found % and %', v_lower, v_upper;
  END IF;
  -- Michigan has no vacancy. If a later wave creates one this gate must be revisited, not relaxed.
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'MI-2 gate 4: expected 0 vacant offices, found %', v_vacant;
  END IF;

  -- The (geo_id, district_type) key: no COUNTY district may have taken a legislative office.
  SELECT count(*) INTO v_county
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = '${GOV}'
     AND c.name IN (${Object.values(CHAMBERS).map((c) => q(c.name)).join(', ')})
     AND d.mtfcc NOT IN ('G5210', 'G5220');
  IF v_county <> 0 THEN
    RAISE EXCEPTION 'MI-2 gate 5: % legislative office(s) landed on a non-legislative district — the geo_id/county collision', v_county;
  END IF;

  SELECT count(*) INTO v_nulldist
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = '${GOV}'
     AND c.name IN (${Object.values(CHAMBERS).map((c) => q(c.name)).join(', ')})
     AND o.district_id IS NULL;
  IF v_nulldist <> 0 THEN
    RAISE EXCEPTION 'MI-2 gate 6: % legislative office(s) have no district — unreachable by address', v_nulldist;
  END IF;

  RAISE NOTICE 'CC_0138 OK: 2 chambers, 110 House + 38 Senate offices, 0 vacant, 0 on a county district.';
END
$gate$;

COMMIT;
`;

// ── CC_0139 — occupancy ─────────────────────────────────────────────────────
const plain = newPeople.filter((s) => !NAMESAKES[key(s)]);
const namesakes = newPeople.filter((s) => NAMESAKES[key(s)]);
const peopleRows = (list) =>
  list.map((s) => `  (${s.external_id}, ${q(s.full_name)}, ${q(s.first_name)}, ${q(s.last_name)})`).join(',\n');
const termRows = seats
  .map((s) => `  (${q(s.geo_id)}, ${q(CHAMBERS[s.chamber].type)}, ${s.external_id}::bigint)`)
  .join(',\n');

const occupancy = `-- CC_0139_mi_legislature_incumbents.sql
-- Knight Foundation program, wave MI-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0138, which creates the chambers and the 148 offices.
--
-- Seats all 148 Michigan legislative offices:
--    ${plain.length} people created under the live name guard, external_id band ${BAND_START} .. ${BAND_START - newPeople.length + 1}
--    ${namesakes.length} people created with the guard scoped off -- genuine namesakes in other jurisdictions
--    ${Object.keys(REUSE).length} people REUSED, not created -- production already holds them
--    0 offices left unseated. MICHIGAN HAS NO VACANCY.
--
-- 🔴🔴 FOUR PEOPLE ARE REUSED, AND THIS IS THE GUARD'S OWN "NORMAL CASE", NOT AN EXCEPTION.
-- Each is a sitting Michigan legislator who won a 2026 FEDERAL primary, so production already
-- carries them as a candidate. A second row would split their quotes and race edges away from
-- the person a voter sees. The duplicate guard says this in its own error text: "A sitting
-- officeholder running for a different seat is the normal case, not a different person."
${Object.entries(REUSE).map(([k, v]) => `--   · ${k} -> ${v.external_id}: ${v.why}`).join('\n')}
--
-- 🔴🔴 AND TWO SHARE A NAME WITH A DIFFERENT PERSON IN ANOTHER JURISDICTION. The sweep was run
-- on the GUARD'S OWN KEY -- lower(btrim(first_name)), lower(btrim(last_name)) against ACTIVE
-- rows, which is exactly what essentials.politician_name_duplicate_guard compares -- and
-- controlled at 68 active rows sharing the surname 'Smith', so a zero would have been visible
-- as blindness rather than read as agreement. It returned exactly six, and the six split four
-- reuse / two distinct:
${Object.entries(NAMESAKES).map(([k, v]) => `--   · ${k}: ${v.why}`).join('\n')}
-- A person cannot simultaneously sit in another state's legislature, or on a Boston city
-- council, and in the Michigan House. This is the GA roster trap (2 of 4 name hits were a
-- Colorado senator and a Utah treasurer) and OH-2's Tom Young, recurring for a third time.
-- The override is scoped to that one statement and switched back off immediately, so the other
-- ${plain.length} rows were inserted with the guard LIVE.
--
-- 🔴 EVERY TERM IS OPEN-ENDED AT 'unknown' PRECISION, AND NOTHING IS GUESSED. No Michigan member
-- page publishes a service-start date; the pages carry biography, not tenure. Mich. Const.
-- art. IV, s 5 fixes commencement at noon on January 1st following election, but that governs a
-- member who ARRIVED AT A GENERAL ELECTION and says nothing about anyone who arrived by
-- appointment or special election mid-term. Writing 2025-01-01 for all 148 would be the San Jose
-- D8/D10 error at scale: a rule true of most rows, applied to rows it does not govern.
-- This is the GA-2 / IN-2 / MN-2 / OH-2 pattern. essentials.seat_officeholder() is NOT used: it
-- refuses a NULL term_start by design.
-- ▶ Dating these 148 arrivals is a recorded debt, not a thing to invent here.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate -- and every
-- House term here in fact expires 2026-12-31, which is exactly why writing it would be wrong.
--
-- 🔴 THE ROSTER WAS CHANGE-CHECKED PAGE BY PAGE, NOT TAKEN FROM A LIST. 147 of 148 member pages
-- were fetched and each one names its own member in its own <title>/<h1>; HD-4 publishes no page
-- at all and is documented below. A list page is not a change-check (MN-2: house.mn.gov listed a
-- member three months after he resigned).
-- ⚠ HD-4's link is the reason status codes are not the test: legislature.mi.gov still points
-- Karen Whitsett at housedems.com/whitsett, which REDIRECTS TO THE CAUCUS HOME PAGE and answers
-- HTTP 200 with an <h1> of "Michigan House Democrats". A dead member link that returns 200.
-- ⚠ HD-101's link (house.mi.gov/repdetail/repJosephFox) returns 404; the Republican caucus page
-- titled "Joseph Fox Posts" names him and District 101. A stale link is a fact about a link.
--
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).

BEGIN;

-- ─── 1. The ${plain.length} members with no active namesake ────────────────────────────────────

CREATE TEMP TABLE mi_new_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO mi_new_people(external_id, full_name, first_name, last_name) VALUES
${peopleRows(plain)};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       ${q(SOURCE + ' (CC_0139, MI-2)')},
       true, true
FROM mi_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. ${namesakes.length} members who share a name with a DIFFERENT person — guard lifted ──────

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE mi_namesake_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO mi_namesake_people(external_id, full_name, first_name, last_name) VALUES
${peopleRows(namesakes)};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       ${q(SOURCE + ' (CC_0139, MI-2)')},
       true, true
FROM mi_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 2b. The ${Object.keys(REUSE).length} reused rows are INCUMBENTS NOW ──────────────────────────────────
--
-- 🔴🔴 THE REACHABILITY GATE CAUGHT THIS AND NOTHING ELSE WOULD HAVE. All four reused rows were
-- created as CANDIDATES and therefore carry is_incumbent = false. The reps feed that address
-- search serves requires
--     (is_active OR is_vacant) AND coalesce(is_incumbent, true) AND title NOT ILIKE 'Candidate for%'
-- so seating them left FOUR DISTRICTS -- HD-11, SD-7, SD-8 and SD-19 -- with a correctly seated
-- member whom no resident could ever surface. Every count in this migration was right: 148
-- offices, 148 terms, 148 seated. The person was simply invisible.
-- ▶ REUSING A ROW MEANS INHERITING EVERY FLAG IT WAS CREATED WITH. A candidate row is not a
--   blank person; it carries a claim about what that person IS, and seating them changes it.
-- ⚠ coalesce(is_incumbent, true) means a NULL passes and only an explicit FALSE hides. The 144
--   rows created above set is_incumbent = true outright, which is why only the reused four were
--   affected — a difference invisible in any count of offices, terms or holders.
--
-- Guarded on the current value, so a re-run updates 0 rows.

UPDATE essentials.politicians
   SET is_incumbent = true
 WHERE external_id IN (${Object.values(REUSE).map((r) => r.external_id).join(', ')})
   AND is_incumbent IS DISTINCT FROM true;

-- ─── 3. The 148 terms ─────────────────────────────────────────────────────────
-- Keyed on (geo_id, district_type), never geo_id alone: '26031' is Senate District 31 AND a
-- Michigan county. The ${Object.keys(REUSE).length} reused external_ids below are NOT in the MI-2 band -- they are the
-- existing rows named in the header.

CREATE TEMP TABLE mi_terms(geo_id text, district_type text, external_id bigint) ON COMMIT DROP;

INSERT INTO mi_terms(geo_id, district_type, external_id) VALUES
${termRows};

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown',
       ${q(SOURCE + ' (CC_0139, MI-2)')}
FROM mi_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type::text = t.district_type AND lower(d.state) = 'mi'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.chambers c
  ON c.id = o.chamber_id AND c.government_id = '${GOV}'
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── post-verify gate ─────────────────────────────────────────────────────────
DO $gate$
DECLARE
  v_terms   integer;
  v_people  integer;
  v_seated  integer;
  v_dated   integer;
  v_ended   integer;
  v_two     integer;
  v_reused  integer;
  v_hidden  integer;
BEGIN
  SELECT count(*) INTO v_terms
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = '${GOV}'
     AND c.name IN (${Object.values(CHAMBERS).map((c) => q(c.name)).join(', ')});
  IF v_terms <> 148 THEN
    RAISE EXCEPTION 'MI-2 gate 1: expected 148 terms, found %', v_terms;
  END IF;

  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN ${BAND_START - newPeople.length + 1} AND ${BAND_START};
  IF v_people <> ${newPeople.length} THEN
    RAISE EXCEPTION 'MI-2 gate 2: expected ${newPeople.length} new people in the MI-2 band, found %', v_people;
  END IF;

  -- 🔴 COUNT och.politician_id, NOT och.*: office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL holder rather than an absent row and count(*) passes vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = '${GOV}'
     AND c.name IN (${Object.values(CHAMBERS).map((c) => q(c.name)).join(', ')});
  IF v_seated <> 148 THEN
    RAISE EXCEPTION 'MI-2 gate 3: expected 148 seated offices, found %', v_seated;
  END IF;

  SELECT count(*) FILTER (WHERE t.term_start IS NOT NULL OR t.start_precision <> 'unknown'),
         count(*) FILTER (WHERE t.term_end IS NOT NULL)
    INTO v_dated, v_ended
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = '${GOV}'
     AND c.name IN (${Object.values(CHAMBERS).map((c) => q(c.name)).join(', ')});
  IF v_dated <> 0 THEN
    RAISE EXCEPTION 'MI-2 gate 4: % term(s) carry an invented start date or precision', v_dated;
  END IF;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'MI-2 gate 5: % term(s) carry a term_end — a future end silently self-vacates the seat', v_ended;
  END IF;

  -- The exclusion constraint forbids two people on one office. It CANNOT see one person on two,
  -- which is the direction that matters when four rows are reused.
  SELECT count(*) INTO v_two FROM (
    SELECT t.politician_id
      FROM essentials.office_terms t
      JOIN essentials.offices o ON o.id = t.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.government_id = '${GOV}'
       AND c.name IN (${Object.values(CHAMBERS).map((c) => q(c.name)).join(', ')})
     GROUP BY t.politician_id HAVING count(*) > 1) x;
  IF v_two <> 0 THEN
    RAISE EXCEPTION 'MI-2 gate 6: % person(s) hold two Michigan legislative seats', v_two;
  END IF;

  -- The four reused rows must be the ones named in the header, seated on the named seats.
  SELECT count(*) INTO v_reused
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = '${GOV}'
     AND p.external_id IN (${Object.values(REUSE).map((r) => r.external_id).join(', ')});
  IF v_reused <> ${Object.keys(REUSE).length} THEN
    RAISE EXCEPTION 'MI-2 gate 7: expected ${Object.keys(REUSE).length} reused people seated, found %', v_reused;
  END IF;

  -- Gate 8: every seated Michigan legislator must survive the REPS FEED predicate, not merely
  -- exist. This is the one the reachability gate had to teach us; it belongs in the migration.
  SELECT count(*) INTO v_hidden
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = '${GOV}'
     AND c.name IN (${Object.values(CHAMBERS).map((c) => q(c.name)).join(', ')})
     AND NOT ((p.is_active = true OR o.is_vacant = true)
              AND coalesce(p.is_incumbent, true) = true
              AND coalesce(o.title, '') NOT ILIKE 'Candidate for%');
  IF v_hidden <> 0 THEN
    RAISE EXCEPTION 'MI-2 gate 8: % seated legislator(s) are hidden from the reps feed — seated but unreachable by any resident', v_hidden;
  END IF;

  RAISE NOTICE 'CC_0139 OK: 148 terms, 148 seated, 0 dated, 0 ended, 0 hidden from the reps feed, ${newPeople.length} new people, ${Object.keys(REUSE).length} reused.';
END
$gate$;

COMMIT;
`;

fs.mkdirSync(MIG, { recursive: true });
fs.writeFileSync(path.join(MIG, 'CC_0138_mi_legislature_structure.sql'), structure);
fs.writeFileSync(path.join(MIG, 'CC_0139_mi_legislature_incumbents.sql'), occupancy);
console.log(`wrote CC_0138 (2 chambers, 148 offices) and CC_0139 (${plain.length} + ${namesakes.length} created, ${Object.keys(REUSE).length} reused, 148 terms)`);
console.log(`external_id band used: ${BAND_START} .. ${BAND_START - newPeople.length + 1}`);
