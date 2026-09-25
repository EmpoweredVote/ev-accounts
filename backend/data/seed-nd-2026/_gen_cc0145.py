import io

src = io.open('data/seed-nd-2026/_gen_source.txt', encoding='utf-8').read()
ordinary = io.open('data/seed-nd-2026/_gen_people_ordinary.sql', encoding='utf-8').read()
namesake = io.open('data/seed-nd-2026/_gen_people_namesake.sql', encoding='utf-8').read()
terms = io.open('data/seed-nd-2026/_gen_terms.sql', encoding='utf-8').read()
S = src.replace("'", "''")

HEADER = r"""-- CC_0145_nd_legislative_assembly_incumbents.sql
-- Knight Foundation program, wave ND-2 (occupancy half). Slot RESERVED from the allocator.
-- Applies immediately after CC_0144, which created the two chambers and the 141 offices.
--
-- Seats all 141 members of the 69th North Dakota Legislative Assembly: 47 senators and 94
-- representatives. Creates 141 people and 141 terms. NO office is left vacant.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE ROSTER THAT LOOKS RIGHT HOLDS 148 MEMBERS, AND SEATING IT WOULD HAVE PUT SEVEN EXTRA
-- PEOPLE INTO 141 SEATS.
--
-- ndlegis.gov publishes THREE member lists for this assembly -- Regular Session, Jan 2026 Special
-- Session and Sep 2026 Special Session. The regular-session list is CUMULATIVE: it retains
-- everyone who held a seat at any point, so SEVEN districts list FOUR members. North Dakota's
-- House is legitimately TWO-per-district, so "four in a district" reads as 2x2 and survives a
-- shape check that would have caught it instantly in a single-member state.
-- ▶ The roster used here is the Sep 2026 Special Session's, convened 2026-09-02: exactly 141
--   members, 47 senators and 94 representatives, every district one senator and two
--   representatives.
--
-- 🟢 AND THE MEMBER PAGES WERE READ ANYWAY, ALL 141 OF THEM. MN-2's rule is that a roster list
-- page is not a change-check. Every member's own biography page was fetched and its <h1> asserted
-- to name that member; ZERO carry a departure marker on a 69th-Assembly row.
-- 🔴 THAT ZERO WAS CONTROLLED. A uniform answer is a broken detector until proved otherwise, so
-- the identical sweep was re-run over the 148-member cumulative roster: it found all SEVEN
-- departures and every one of them is dated to the day --
--   Liz Conmy (D11) deceased 2026-04-25 · Jared C. Hagert (D20) resigned 2026-02-09 ·
--   Cynthia Schreiber-Beck (D25) deceased 2025-05-18 · Jeremy L. Olson (D26) resigned 2025-05-05 ·
--   Josh Christy (D27) deceased 2025-02-18 · Emily O'Brien (D42) resigned 2025-08-19 ·
--   Josh Boschee (SD44) resigned 2026-08-04.
-- None of the seven is written by this migration. They are history, and the seat is held today by
-- the successor.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 NORTH DAKOTA DATES ITS ARRIVALS, WHICH MICHIGAN AND MINNESOTA COULD NOT.
--
-- EIGHT members carry an exact `Active <date>` line on the body's own page, and those eight terms
-- are written at DAY precision with how_started 'appointed':
--
--   Jamie Selzler      SD44  2026-08-05   Karen Grindberg   HD41  2024-12-01
--   Adam Goldwyn       HD11  2026-06-01   Dave Rustebakke   HD20  2026-04-21
--   Kathy Skroch       HD25  2025-09-10   Kelby Timmons     HD26  2025-05-29
--   TJ Brown           HD27  2025-03-10   Dustin McNally    HD42  2025-09-19
--
-- The mechanism is not inferred from the date: N.D.C.C. 16.1-13-10 fills a legislative vacancy by
-- appointment of the vacating legislator's district party committee, and two cases were confirmed
-- against contemporaneous reporting -- the District 44 Dem-NPL executive committee appointed
-- Selzler on 2026-08-04, and the District 41 Republican executive committee appointed Grindberg
-- to the remainder of Michelle Strinden's term after Strinden resigned to become lieutenant
-- governor.
-- ⚠ AND THE TWO SOURCES DISAGREE BY ONE DAY ON GRINDBERG, WHICH IS RECORDED RATHER THAN SMOOTHED.
-- The Legislative Branch says `Active December 1, 2024`; contemporaneous reporting says she was
-- SWORN IN on December 2, 2024, Strinden's resignation having taken effect December 1. The body's
-- own record is the one written here. "First sworn" and "active from" are different facts and this
-- is a case where they differ.
--
-- 🔴 THE OTHER 133 TERMS ARE OPEN-ENDED AT `unknown`, AND NOTHING IS GUESSED. This is deliberate
-- and it is NOT for want of a number:
--   * N.D. Const. art. IV s 7 says terms begin on the first day of December following the
--     election, so a date exists in the abstract -- but senators and representatives both serve
--     FOUR-year terms (art. IV s 4) and North Dakota staggers them, so whether a given member's
--     current term began 2022-12-01 or 2024-12-01 is not knowable from any source read here.
--   * A RE-ELECTION DOES NOT RESTART AN OCCUPANCY (the SC-3 rule), so even the correct term start
--     would be the wrong value for a member who has held the seat continuously since before it.
--   * The bio pages publish "Senate since 1987"-style lines, but that is a fact about service in
--     the CHAMBER, not about this SEAT -- and North Dakota redrew its map in 2021 and again by
--     court order effective 2024-01-08. Writing 1987-01-01 would assert tenure in a seat that did
--     not exist in that shape.
--   Those `since` years ARE captured, in backend/data/seed-nd-2026/nd-members.json, as evidence
--   for a later dating pass. This is the same disposition OH-2 and MN-2 reached, with more of the
--   reasoning available.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 TWO OFFICES SHARE ONE DISTRICT, SO (geo_id, district_type) IS NOT A KEY HERE. Every earlier
-- wave in this program could match a member to an office through the district alone. In North
-- Dakota 46 House districts hold TWO interchangeable offices, and the seats carry no position
-- number on any ballot, so there is no natural fact that says which member holds which row.
-- ▶ The assignment is therefore made deterministic rather than meaningful: offices are ranked by
--   their own id, members by full_name, and slot N is matched to slot N. Both keys are stable, so
--   a re-run reproduces the same pairing -- which is what makes this migration idempotent. The
--   pairing asserts nothing about the world, and nothing downstream may read meaning into it.
--
-- 🔴 A MEMBER'S OWN DISTRICT LABEL IS NOT THE ACCORDION HEADING IT SITS UNDER. Lisa Finley-DeVille
-- and Clayton Fegley both appear under the heading "District 4", and their own rows say 4A and 4B.
-- The heading is what the roster groups by; the member's label is what identifies the seat. Using
-- the heading would have tried to join both to a STATE_LOWER district '38004', which does not
-- exist -- a loud failure rather than a silent one, but only by luck of North Dakota having no
-- whole House District 4.
--
-- 🔴 ONE NAME COLLIDES WITH A DIFFERENT PERSON ALREADY IN PRODUCTION, AND THE GUARD IS LIFTED FOR
-- EXACTLY ONE ROW. `Dick Anderson`, Representative for North Dakota House District 6 (Republican,
-- farmer, UND, House since 2011), shares first_name/last_name with -4110005 `Dick Anderson`, who
-- SITS TODAY as an OREGON STATE SENATOR for OR SD-5. A person cannot hold an Oregon Senate seat
-- and a North Dakota House seat at once, so these are different people -- the same structural
-- evidence the GA roster trap needed, where 2 of 4 name hits were a Colorado senator and a Utah
-- treasurer.
-- ⚠ The sweep was run on the GUARD'S OWN KEY (first_name, last_name), which is OH-2's lesson, and
-- it was controlled: the same query reports 66 active `Johnson`s and 37 active `Anderson`s, so the
-- single hit is a true single and not an empty detector.
--
-- 🔴 PARTY IS NOT WRITTEN. The rosters carry it; party lives on races.primary_party.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded on a stable key. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The 140 people whose names collide with nobody ────────────────────────

CREATE TEMP TABLE nd_new_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO nd_new_people(external_id, full_name, first_name, last_name) VALUES
__ORDINARY__;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, '__SOURCE__', true, true
FROM nd_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The one namesake — guard lifted for this statement only ───────────────

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE nd_namesake_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO nd_namesake_people(external_id, full_name, first_name, last_name) VALUES
__NAMESAKE__;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, '__SOURCE__', true, true
FROM nd_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 3. The 141 terms ─────────────────────────────────────────────────────────
-- 🔴 Keyed on (geo_id, district_type, slot). '38020' is BOTH Senate District 20 and House
-- District 20, and 24 North Dakota counties also carry a geo_id inside the Senate range, so
-- geo_id alone is never the key. The slot is what resolves the two interchangeable House offices.

CREATE TEMP TABLE nd_terms(
  geo_id text, district_type text, external_id bigint,
  sort_key text, term_start date, start_precision text, how_started text
) ON COMMIT DROP;

INSERT INTO nd_terms(geo_id, district_type, external_id, sort_key, term_start, start_precision, how_started) VALUES
__TERMS__;

WITH office_slots AS (
  SELECT o.id AS office_id, d.geo_id, d.district_type::text AS dt,
         row_number() OVER (PARTITION BY o.district_id ORDER BY o.id) AS slot
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
),
member_slots AS (
  SELECT t.*, row_number() OVER (PARTITION BY t.geo_id, t.district_type ORDER BY t.sort_key) AS slot
  FROM nd_terms t
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT os.office_id, p.id, ms.term_start, NULL, ms.start_precision, ms.how_started, '__SOURCE__'
FROM member_slots ms
JOIN office_slots os
  ON os.geo_id = ms.geo_id AND os.dt = ms.district_type AND os.slot = ms.slot
JOIN essentials.politicians p ON p.external_id = ms.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = os.office_id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people    int;
  v_offices   int;
  v_terms     int;
  v_seated    int;
  v_dated     int;
  v_ended     int;
  v_unseated  int;
  v_two       int;
  v_gf        int;
  v_dup       int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2762400 AND -2762260;
  IF v_people <> 141 THEN
    RAISE EXCEPTION 'ND-2 occupancy: expected 141 people in the reserved band, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_offices <> 141 THEN
    RAISE EXCEPTION 'ND-2 occupancy: expected 141 ND legislative offices from CC_0144, got %', v_offices;
  END IF;

  SELECT count(*) INTO v_terms
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_terms <> 141 THEN
    RAISE EXCEPTION 'ND-2 occupancy: expected 141 terms, got %', v_terms;
  END IF;

  -- 🔴 Count och.politician_id, never rows: office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id rather than an absent row and count(*) passes vacuously.
  SELECT count(och.politician_id) INTO v_seated
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_seated <> 141 THEN
    RAISE EXCEPTION 'ND-2 occupancy: expected 141 seated ND legislative offices, got %', v_seated;
  END IF;

  -- Exactly the eight dated arrivals, and nothing else carries a date.
  SELECT count(*) FILTER (WHERE ot.term_start IS NOT NULL AND ot.start_precision = 'day'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_dated, v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_dated <> 8 THEN
    RAISE EXCEPTION 'ND-2 occupancy: expected exactly 8 day-precision ND terms (the published Active dates), got %', v_dated;
  END IF;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'ND-2 occupancy: % ND term(s) carry a term_end — a future end self-vacates a seat', v_ended;
  END IF;

  -- No office left unseated.
  SELECT count(*) INTO v_unseated
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
    AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);
  IF v_unseated <> 0 THEN
    RAISE EXCEPTION 'ND-2 occupancy: % ND legislative office(s) hold no term', v_unseated;
  END IF;

  -- 🔴 THE MULTI-MEMBER ASSERTION. Every whole House district must resolve to TWO DIFFERENT
  -- people; the subdistricts to one each. Two terms naming the SAME person would satisfy a count.
  SELECT count(*) INTO v_two
  FROM essentials.districts d
  WHERE lower(d.state) = 'nd' AND d.district_type::text = 'STATE_LOWER'
    AND d.geo_id NOT IN ('3804A', '3804B')
    AND (SELECT count(DISTINCT och.politician_id)
           FROM essentials.offices o
           JOIN essentials.office_current_holder och ON och.office_id = o.id
          WHERE o.district_id = d.id) <> 2;
  IF v_two <> 0 THEN
    RAISE EXCEPTION 'ND-2 occupancy: % whole House district(s) do not hold exactly 2 DISTINCT holders', v_two;
  END IF;

  -- 🔴 Nobody holds two North Dakota legislative seats. The exclusion constraint forbids two
  -- people on one office; it cannot see one person on two, which is the CLAUDE.md fan-out.
  SELECT count(*) INTO v_dup
  FROM (SELECT och.politician_id
          FROM essentials.office_current_holder och
          JOIN essentials.offices o ON o.id = och.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
           AND och.politician_id IS NOT NULL
         GROUP BY och.politician_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'ND-2 occupancy: % person/people hold more than one ND legislative seat', v_dup;
  END IF;

  -- 🟢 This slice's own jurisdiction: Grand Forks city spans four districts (17, 18, 42, 43), so
  -- a Grand Forks address must be able to reach 4 senators and 8 representatives.
  SELECT count(och.politician_id) INTO v_gf
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = 'nd'
    AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
    AND d.geo_id IN ('38017', '38018', '38042', '38043');
  IF v_gf <> 12 THEN
    RAISE EXCEPTION 'ND-2 occupancy: expected 12 seated offices across Grand Forks 4 districts (4 senators + 8 representatives), got %', v_gf;
  END IF;

  RAISE NOTICE 'ND-2 occupancy gate PASSED: 141 people, 141 offices, 141 terms, 141 seated, 8 dated, 0 ended, every whole House district holds 2 distinct members, nobody holds two seats, Grand Forks reaches 12.';
END $$;

COMMIT;
"""

sql = (HEADER
       .replace('__ORDINARY__', ordinary)
       .replace('__NAMESAKE__', namesake)
       .replace('__TERMS__', terms)
       .replace('__SOURCE__', S))
io.open('migrations/CC_0145_nd_legislative_assembly_incumbents.sql', 'w', encoding='utf-8', newline='\n').write(sql)
print('written', len(sql), 'chars')
