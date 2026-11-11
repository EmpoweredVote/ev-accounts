-- CC_0387_reno_washoe_roster.sql
-- Reno + Washoe County roster: seats the 13 people who hold office TODAY, and future-dates the
-- three winners who take office on 2026-11-13. Follows CC_0385 (Reno structure) and CC_0386
-- (Washoe structure), which deliberately seated nobody.
--
-- ═══ THE TRANSITION IS WRITTEN, NOT WAITED FOR ═══
--
-- Reno's general election was 2026-11-03. Three results are settled and one is not. Rather than
-- seat the outgoing roster now and come back on Friday, this migration writes BOTH sides and
-- lets the temporal model do the handover:
--
--   essentials.office_next_term  = office_terms rows with term_start > CURRENT_DATE
--   essentials.office_current_holder = the term covering today
--
-- CC_0341's own comment says it best: "the reason no flag has to be flipped on the day — the
-- same comparison that makes this row appear also makes it disappear, at midnight, with no
-- write." Until 2026-11-13 the sitting holder renders as current with the winner shown as
-- "Incoming on 2026-11-13"; on the day, both flip by themselves. NOTHING RUNS ON FRIDAY.
--
--   office                     today                  from 2026-11-13
--   Mayor                      Hillary Schieve        Kathleen "Kate" Marshall
--   Council Member, Ward 2     Naomi Duerr            Matthew Johnson
--   City Attorney              Karl S. Hall           Zelalem "Zee" Bogale
--
-- 🔴 WARD 4 IS NOT WRITTEN. On 2026-11-09 challenger Eduardo "Eddie" Gomez led incumbent Meghan
--    Ebert by 61 votes with signature curing closing that day and the canvass not until
--    2026-11-13. Ebert is seated because she holds the seat today; NO successor row is written,
--    because there is no answer yet. A guess here would be indistinguishable from a fact.
--
-- 🔴 THE FOUR MUNICIPAL COURT DEPARTMENTS ARE LEFT EMPTY, deliberately. The State of Nevada
--    Judicial Directory (AOC, rev. 2026-03-17) gives Dept 2 to Randall Soderquist and places
--    Shelly O'Neill at FALLON Municipal Court, while Ballotpedia puts O'Neill in Reno Dept 2.
--    Dept 1 is itself mid-election (Gianoli v Hubach, undecided). An aggregator contradicting
--    the state's own directory is not a basis for seating a judge.
--
-- ═══ CORRECTION, 2026-11-10 (made by CC_0389): THE DIRECTORY SAYS NO SUCH THING ════════════
--    The paragraph above is left standing because it is what this migration acted on, and the
--    four empty departments were its consequence. It is wrong on every point.
--
--    The document it names was read in full on 2026-11-10 — 22 pages, footer "Rev. March 17,
--    2026", the same revision cited above:
--    https://nvcourts.gov/__data/assets/pdf_file/0014/11282/Judicial_Directory_03.23.26.pdf
--    Its MUNICIPAL COURT JUDGES table has the columns
--    FIRST NAME · LAST NAME · COURT · APPOINTED/ELECTED · TOOK OFFICE · TERM EXPIRES, and reads:
--
--      Shelly O'Neill               Reno Municipal Court (Dept. 2)    11/08/2016  11/08/2016  01/02/2029
--      Justin Champagne             Reno Municipal Court (Dept. 3)    11/08/2022  01/03/2023  01/02/2029
--      Christopher Hazlett-Stevens  Reno Municipal Court (Dept. 4)    11/09/2021  11/13/2021  01/02/2029
--      Gene S. Drakulich            Reno Municipal Court (Dept. 1)    11/04/2014  01/05/2015  01/03/2027
--      Randall Soderquist           Elko Justice/Municipal Court (A)  01/04/2021  01/04/2021  01/07/2031
--      Michael R. Lister            Fallon Municipal Court            04/08/2005  04/15/2005  open-ended
--
--    Soderquist is in ELKO. Fallon's judge is LISTER. And the directory puts O'Neill in Reno
--    Dept 2 — exactly where Ballotpedia puts her.
--
-- 🔴 THERE WAS NEVER A CONFLICT. The two sources agree, and have agreed all along. The bench
--    was held empty for three weeks, and CC_0388 then wrote a voter-facing sentence announcing
--    a disagreement, over a contradiction that does not exist in the cited document.
--    ▶ A SOURCE YOU HAVE NOT OPENED IS NOT A SOURCE. Nothing here required new research to
--    correct — only reading the PDF that both headers already named.
--
--  ⚠ TWO TRAPS, EITHER OF WHICH EXPLAINS HOW THIS WAS MISREAD:
--    - nvcourts.gov answers HTTP 403 to curl even with a browser User-Agent. The PDF has to be
--      fetched in a real browser; a WAF rejection is not a missing document.
--    - A STALE 2017 COPY OF A SIMILARLY-NAMED DIRECTORY is served from prod.rccd.nv.gov and is
--      the first web-search hit. Its footer reads "Judicial Directory July 2017 (rev)" and it
--      lists municipal courts by ADDRESS AND FAX NUMBER ONLY — it names no municipal judge at
--      all. Reading that one and concluding anything about Reno Dept 2 is a different error
--      with the same shape. Check a directory's own revision line before citing it.
--
--  ▶ STILL UNUSED: the TOOK OFFICE column above is an authoritative term_start for the three
--    sitting judges, from the state's own AOC. CC_0389 seated them with start_precision
--    'unknown' because the COURT publishes no dates and this table had not been read. That is
--    now improvable — see CC_0389's header.
-- ═══════════════════════════════════════════════════════════════════════════════════════════
--
-- ⚠ WASHOE'S HANDOVER IS IN JANUARY, NOT FRIDAY. Districts 2, 3 and 5 were contested on
--   2026-11-03 but the winners are not sworn until January 2027, so all five sitting
--   commissioners remain correct and NO successor rows are written for them either. That is a
--   separate pass against a separate canvass.
--
-- ═══ SOURCES — every name from the body itself, none from a GIS attribute ═══
--
--  S1  City of Reno, AGENDA — Special Meeting, Reno City Council, Friday, November 13, 2026,
--      10:00 AM (reno.primegov.com compiled document 23350, read 2026-11-09). Its header names
--      the sitting council in full: "Hillary Schieve, Mayor / Ward 1 - Kathleen Taylor /
--      Ward 2 - Naomi Duerr / Ward 3 - Miguel Martinez / Ward 4 - Meghan Ebert /
--      Ward 5 - Devon Reese / Ward 6 - Brandi Anderson". The same agenda carries item B.4
--      "City Council and City Manager canvass of returns and declaration of results from the
--      November 3, 2026, City of Reno General Election" and item C "Oath of Office and Swearing
--      In of Newly Elected Officials" — which is the published authority for the handover date.
--  S2  reno.gov City Attorney's Office page, read 2026-11-09: "Reno City Attorney's Office —
--      City Attorney, Karl S. Hall".
--  S3  City Clerk's 2026 election page, read 2026-11-09 — the filing names used below:
--      "Kathleen Marshall" (press calls her Kate), "Matthew Johnson", "Zelalem Bogale",
--      "Eduardo Gomez", and the office wording "Council Member, Ward 2".
--  S4  washoecounty.gov/bcc/profile, read 2026-11-09, which publishes each commissioner's
--      district and CURRENT TERM range.
--
-- 🔴 NO BOUNDARY LAYER'S NAME COLUMN WAS READ FOR OCCUPANCY. Both the county's Reno-wards layer
--    and its commission layer carry an officeholder column and both happened to be correct on
--    the day; they are recorded in CC_0385/CC_0386 as corroboration only.
--
-- ═══ 🔴🔴 NAME COLLISIONS: TWO OF THESE SIXTEEN ALREADY EXIST AS SOMEBODY ELSE ═══
--
-- Pre-checked 2026-11-09 against active politicians by first+last:
--
--   "Kathleen Taylor"  → already an ACTIVE State of OREGON Senator (external_id -4110021)
--   "Matthew Johnson"  → already an ACTIVE Horry County, SOUTH CAROLINA Soil and Water
--                        Conservation District Commissioner
--
-- Both are DIFFERENT PEOPLE. This matters because the seeding idiom used by CC_0303 (Anchorage)
-- inserts `WHERE NOT EXISTS (same first+last AND is_active)` and then resolves politician_id by
-- that same predicate. Run here, it would have silently skipped creating Reno's Kathleen Taylor
-- and then bound RENO'S WARD 1 SEAT TO AN OREGON STATE SENATOR — no error, no duplicate, just a
-- wrong person on a seat. Anchorage got away with that idiom because it had zero collisions.
--
-- ✅ So this migration keys its people on first+last AND a source tag unique to it, never on
--    first+last alone. Re-running is idempotent; an unrelated namesake can never be adopted.
--
-- ⚠ CONSEQUENCE, STATED NOT HIDDEN: production will now hold two active "Kathleen Taylor" rows
--   and two active "Matthew Johnson" rows. That is correct — they are four people — and
--   `check:duplicate-people` is expected to surface two new candidate pairs for review, to be
--   marked different_people.
--
-- ═══ 🔴 DATES: THE SITTING THIRTEEN GET NONE, AND THAT IS DELIBERATE ═══
--
-- `office_terms.term_start` is the start of CONTINUOUS OCCUPANCY. A re-election does not open a
-- new row. Neither source publishes that:
--
--   · S1 publishes no dates at all for the council.
--   · S4 publishes a "Current Term" range per commissioner (Hill 01/06/25-01/01/29, Clark
--     01/06/23-01/04/27, Garcia 01/06/23-01/04/27, Andriola 01/06/25-01/01/29, Herman
--     01/06/23-01/04/27). Those are TERM starts, not occupancy starts. Alexis Hill was first
--     elected in 2020, so writing 2025-01-06 as her term_start would erase four years of
--     continuous service; Jeanne Herman has served since 2015. Miguel Martinez is the same
--     trap from the other side: he was APPOINTED in October 2022 to fill Oscar Delgado's
--     vacancy and then elected in 2024, so his occupancy began in 2022, not 2024.
--
-- So all thirteen sitting officials get `term_start => NULL, start_precision => 'unknown'`, with
-- the published term ranges recorded in `source` as a dating lead for a later pass. This is the
-- Anchorage rule (CC_0303) and the gate at the foot of this file refuses any of the thirteen
-- that carries a date.
--
-- 🟢 THE THREE INCOMING ARE DATED, because 2026-11-13 genuinely is the start of their occupancy:
--    none of the three has held the office before, and S1 publishes the meeting at which the
--    oath is administered. `start_precision => 'day'`, `how_started => 'elected'`.

BEGIN;

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_off int; v_seated int;
BEGIN
  SELECT count(*) INTO v_off
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name IN ('City of Reno, Nevada, US', 'Washoe County, Nevada, US');
  IF v_off <> 17 THEN
    RAISE EXCEPTION 'CC_0387 pre-flight: expected the 17 offices from CC_0385/CC_0386, found % — '
                    'run those first', v_off;
  END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name IN ('City of Reno, Nevada, US', 'Washoe County, Nevada, US');
  IF v_seated <> 0 THEN
    RAISE EXCEPTION 'CC_0387 pre-flight: % office_term row(s) already exist for Reno/Washoe. '
                    'This migration assumes an unseated tier; re-check before re-running.', v_seated;
  END IF;
END $$;

-- ── Roster ────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE rw_roster(
  gov_name    text NOT NULL,
  office_title text NOT NULL,
  full_name   text NOT NULL,
  first_name  text NOT NULL,
  last_name   text NOT NULL,
  preferred   text NOT NULL DEFAULT '',
  incoming_on date,                    -- NULL = holds the seat today
  source      text NOT NULL,
  office_id     uuid,
  politician_id uuid
) ON COMMIT DROP;

INSERT INTO rw_roster(gov_name, office_title, full_name, first_name, last_name, preferred, incoming_on, source) VALUES
  -- Reno, sitting
  ('City of Reno, Nevada, US','Mayor','Hillary Schieve','Hillary','Schieve','', NULL,
   'CC_0387 S1: City of Reno agenda, Special Meeting of the Reno City Council, 2026-11-13, header "Hillary Schieve, Mayor" (reno.primegov.com doc 23350), read 2026-11-09. Term-limited: ineligible for a fourth term. No occupancy start published; start_precision unknown.'),
  ('City of Reno, Nevada, US','Council Member, Ward 1','Kathleen Taylor','Kathleen','Taylor','', NULL,
   'CC_0387 S1: City of Reno agenda, Special Meeting 2026-11-13, header "Ward 1 - Kathleen Taylor", read 2026-11-09. Ran for Mayor in 2026 and lost; retains the Ward 1 seat, which was not up. NOT the active State of Oregon Senator of the same name.'),
  ('City of Reno, Nevada, US','Council Member, Ward 2','Naomi Duerr','Naomi','Duerr','', NULL,
   'CC_0387 S1: City of Reno agenda, Special Meeting 2026-11-13, header "Ward 2 - Naomi Duerr", read 2026-11-09. Succeeded by Matthew Johnson on 2026-11-13.'),
  ('City of Reno, Nevada, US','Council Member, Ward 3','Miguel Martinez','Miguel','Martinez','', NULL,
   'CC_0387 S1: City of Reno agenda, Special Meeting 2026-11-13, header "Ward 3 - Miguel Martinez", read 2026-11-09. Appointed October 2022 to fill Oscar Delgado''s vacancy, then elected 2024 — occupancy is continuous from 2022 and is NOT the 2024 election date; no exact appointment date sourced, so start_precision unknown.'),
  ('City of Reno, Nevada, US','Council Member, Ward 4','Meghan Ebert','Meghan','Ebert','', NULL,
   'CC_0387 S1: City of Reno agenda, Special Meeting 2026-11-13, header "Ward 4 - Meghan Ebert", read 2026-11-09. 🔴 Her 2026 re-election was UNDECIDED at the time of writing — Eduardo Gomez led by 61 votes, curing closed 2026-11-09, canvass 2026-11-13. She is seated because she holds the seat today; no successor row is written.'),
  ('City of Reno, Nevada, US','Council Member, Ward 5','Devon Reese','Devon','Reese','', NULL,
   'CC_0387 S1: City of Reno agenda, Special Meeting 2026-11-13, header "Ward 5 - Devon Reese", read 2026-11-09. Ran for Mayor in 2026 and lost; retains the Ward 5 seat, which was not up.'),
  ('City of Reno, Nevada, US','Council Member, Ward 6','Brandi Anderson','Brandi','Anderson','', NULL,
   'CC_0387 S1: City of Reno agenda, Special Meeting 2026-11-13, header "Ward 6 - Brandi Anderson", read 2026-11-09. First holder of Ward 6, created by Nevada AB36 (2017) and first elected in 2024.'),
  ('City of Reno, Nevada, US','City Attorney','Karl S. Hall','Karl','Hall','', NULL,
   'CC_0387 S2: reno.gov City Attorney''s Office page, read 2026-11-09: "Reno City Attorney''s Office — City Attorney, Karl S. Hall". Retiring; succeeded by Zelalem Bogale on 2026-11-13.'),

  -- Reno, incoming 2026-11-13
  ('City of Reno, Nevada, US','Mayor','Kathleen Marshall','Kathleen','Marshall','Kate', DATE '2026-11-13',
   'CC_0387 S3: City of Reno City Clerk 2026 election page candidate filing "Kathleen Marshall", read 2026-11-09; press and the candidate use "Kate Marshall". Won the 2026-11-03 general election for Mayor. Takes office at the Special Meeting of 2026-11-13 per S1 item C, "Oath of Office and Swearing In of Newly Elected Officials", and Reno City Charter s 5.100(3).'),
  ('City of Reno, Nevada, US','Council Member, Ward 2','Matthew Johnson','Matthew','Johnson','Matt', DATE '2026-11-13',
   'CC_0387 S3: City of Reno City Clerk 2026 election page candidate filing "Matthew Johnson", read 2026-11-09. Won Ward 2 at the 2026-11-03 general election. Takes office 2026-11-13 per S1 item C and Charter s 5.100(3). NOT the active Horry County, South Carolina Soil and Water Conservation District Commissioner of the same name.'),
  ('City of Reno, Nevada, US','City Attorney','Zelalem Bogale','Zelalem','Bogale','Zee', DATE '2026-11-13',
   'CC_0387 S3: City of Reno City Clerk 2026 election page candidate filing "Zelalem Bogale", read 2026-11-09; goes by "Zee". Unopposed for City Attorney at the 2026-11-03 general election. Takes office 2026-11-13 per S1 item C and Charter s 5.100(3).'),

  -- Washoe County, sitting. Handover for Districts 2/3/5 is JANUARY 2027, not 2026-11-13.
  ('Washoe County, Nevada, US','Commissioner, District 1','Alexis Hill','Alexis','Hill','', NULL,
   'CC_0387 S4: washoecounty.gov/bcc/profile, read 2026-11-09 — "Commissioner Alexis Hill (she/her/hers), District 1, Current Term: 01/06/25 - 01/01/29". That is a TERM start, not an occupancy start: she was first elected in 2020, so continuous occupancy predates it. start_precision unknown.'),
  ('Washoe County, Nevada, US','Commissioner, District 2','Michael Clark','Michael','Clark','', NULL,
   'CC_0387 S4: washoecounty.gov/bcc/profile, read 2026-11-09 — "Commissioner Michael Clark, District 2, Current Term: 01/06/23 - 01/04/27". Did not win renomination in 2026; successor sworn in January 2027, not written here.'),
  ('Washoe County, Nevada, US','Commissioner, District 3','Mariluz Garcia','Mariluz','Garcia','', NULL,
   'CC_0387 S4: washoecounty.gov/bcc/profile, read 2026-11-09 — "Vice Chair Mariluz Garcia, District 3, Current Term: 01/06/23 - 01/04/27". Vice Chair is a role the Board confers, not a seat.'),
  ('Washoe County, Nevada, US','Commissioner, District 4','Clara Andriola','Clara','Andriola','', NULL,
   'CC_0387 S4: washoecounty.gov/bcc/profile, read 2026-11-09 — "Chair Clara Andriola, District 4, Current Term: 01/06/25 - 01/01/29". Chair is a role the Board confers, not a seat. She first took the seat by appointment in 2023, so the published term start is not her occupancy start.'),
  ('Washoe County, Nevada, US','Commissioner, District 5','Jeanne Herman','Jeanne','Herman','', NULL,
   'CC_0387 S4: washoecounty.gov/bcc/profile, read 2026-11-09 — "Commissioner Jeanne Herman, District 5, Current Term: 01/06/23 - 01/04/27". Serving since 2015; did not seek re-election in 2026, successor sworn in January 2027, not written here.');

-- resolve offices
UPDATE rw_roster r SET office_id = o.id
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
 WHERE g.name = r.gov_name AND o.title = r.office_title;

DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM rw_roster WHERE office_id IS NULL;
  IF v <> 0 THEN
    RAISE EXCEPTION 'CC_0387: % roster row(s) did not resolve to an office', v;
  END IF;
END $$;

-- ── People ────────────────────────────────────────────────────────────────────
-- 🔴 KEYED ON first+last AND THIS MIGRATION'S OWN SOURCE TAG, never on first+last alone.
--    See the collision note in the header: two of these sixteen names already belong to
--    unrelated sitting officials elsewhere in the country.
--
-- 🔴 AND THE DATABASE ITSELF REFUSES THE INSERT UNTIL THAT IS DECLARED.
--    `essentials.politician_name_duplicate_guard()` raises DUPLICATE_POLITICIAN_NAME on any new
--    active row whose name matches an existing active one, precisely so a namesake cannot be
--    created by accident. It fired here on Matthew Johnson. Both collisions were checked
--    individually before this flag was set, and both are unambiguously different people:
--
--      Kathleen Taylor  external_id -4110021 — a SITTING State of OREGON Senator. Reno's
--                       Kathleen Taylor sits on the Reno City Council and ran for Mayor of Reno
--                       in 2026. Two different states, two seats held simultaneously.
--      Matthew Johnson  external_id -2745440 — a SITTING Soil and Water Conservation District
--                       Commissioner in HORRY COUNTY, SOUTH CAROLINA, with 0 quotes and 0 race
--                       edges. Reno's Matthew Johnson won Reno Ward 2 on 2026-11-03.
--
--    The guard's own text spells out the test — "If it is genuinely a DIFFERENT person (there
--    are three Mike Rogers and two Andrew Rices), say so and proceed". This is that statement.
--    The flag is SET LOCAL, so it lapses at COMMIT and cannot leak into another migration.
SET LOCAL essentials.allow_duplicate_name = 'on';
INSERT INTO essentials.politicians
  (full_name, first_name, last_name, preferred_name, is_active, is_incumbent, source)
SELECT r.full_name, r.first_name, r.last_name, r.preferred,
       true,
       r.incoming_on IS NULL,     -- a winner who has not been sworn in is not an incumbent
       r.source
  FROM rw_roster r
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
      AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
      AND p.source LIKE 'CC_0387 %');

UPDATE rw_roster r SET politician_id = p.id
  FROM essentials.politicians p
 WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
   AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
   AND p.source LIKE 'CC_0387 %';

DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM rw_roster WHERE politician_id IS NULL;
  IF v <> 0 THEN RAISE EXCEPTION 'CC_0387: % roster row(s) did not resolve to a person', v; END IF;
END $$;

-- ── Seat the sitting thirteen ─────────────────────────────────────────────────
-- Directly, not via seat_officeholder, because that helper requires a non-NULL term_start and
-- these occupancies have no published start. NULL + 'unknown' is the honest encoding.
INSERT INTO essentials.office_terms
  (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT r.office_id, r.politician_id, NULL, 'unknown', 'elected', r.source
  FROM rw_roster r
 WHERE r.incoming_on IS NULL;

-- ── Future-date the three winners ─────────────────────────────────────────────
-- seat_officeholder closes the predecessor's term at term_start - 1 (2026-11-12), so the
-- handover is already written and nothing has to run on the day.
DO $$
DECLARE r record; n int := 0;
BEGIN
  FOR r IN SELECT * FROM rw_roster WHERE incoming_on IS NOT NULL ORDER BY office_title LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id, r.politician_id, r.incoming_on, r.source,
      'elected',        -- how_started
      'day',            -- start_precision
      'term_expired'    -- how the predecessor's term ended
    );
    n := n + 1;
  END LOOP;
  IF n <> 3 THEN RAISE EXCEPTION 'CC_0387: expected 3 future seatings, got %', n; END IF;
END $$;

-- ── Record the swearing-in date against the three offices ─────────────────────
-- basis 'published': the CITY published the meeting at which the oath is administered. The
-- Charter alone would only give "the first meeting following the election", which is a rule and
-- not a date — that would be basis 'estimated', and estimated is explicitly NOT seatable.
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, authority, source, notes)
SELECT DISTINCT r.office_id, DATE '2026-11-03', DATE '2026-11-13', 'published',
       'City of Reno (City Clerk / City Council)',
       'City of Reno agenda, Special Meeting of the Reno City Council, Friday, November 13, 2026, 10:00 AM (reno.primegov.com compiled document 23350), read 2026-11-09: item B.4 "City Council and City Manager canvass of returns and declaration of results from the November 3, 2026, City of Reno General Election" and item C "Oath of Office and Swearing In of Newly Elected Officials".',
       'Reno City Charter s 5.100(3) provides that officers elected "shall qualify and enter upon the discharge of their respective duties at the first regular City Council meeting following their election". The Charter supplies the rule; this agenda supplies the date, which is why basis is published rather than statute. Note the meeting is a SPECIAL meeting, while s 5.100(3) says "regular" — the City''s own published agenda is taken as authoritative for when the oath is actually administered.'
  FROM rw_roster r
 WHERE r.incoming_on IS NOT NULL
   AND NOT EXISTS (
     SELECT 1 FROM essentials.office_swearing_in s
      WHERE s.office_id = r.office_id AND s.election_date = DATE '2026-11-03');

-- ── The thirteen held offices are no longer vacant ────────────────────────────
UPDATE essentials.offices o
   SET is_vacant = false
  FROM rw_roster r
 WHERE o.id = r.office_id AND r.incoming_on IS NULL;

-- ── Post-verify gate ──────────────────────────────────────────────────────────
DO $$
DECLARE
  v_people int; v_terms int; v_current int; v_future int; v_dated int;
  v_judges int; v_ward4 int; v_sw int; v_vacant int; v_oregon int; v_horry int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE source LIKE 'CC_0387 %';
  IF v_people <> 16 THEN RAISE EXCEPTION 'CC_0387 gate: expected 16 new people, found %', v_people; END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name IN ('City of Reno, Nevada, US','Washoe County, Nevada, US');
  IF v_terms <> 16 THEN RAISE EXCEPTION 'CC_0387 gate: expected 16 office_terms, found %', v_terms; END IF;

  -- 13 resolve as current TODAY, 3 as future
  SELECT count(*) INTO v_current
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name IN ('City of Reno, Nevada, US','Washoe County, Nevada, US')
     AND (t.term_start IS NULL OR t.term_start <= CURRENT_DATE)
     AND (t.term_end IS NULL OR t.term_end >= CURRENT_DATE);
  IF v_current <> 13 THEN
    RAISE EXCEPTION 'CC_0387 gate: expected 13 offices held TODAY, found %', v_current;
  END IF;

  SELECT count(*) INTO v_future
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Reno, Nevada, US' AND t.term_start > CURRENT_DATE;
  IF v_future <> 3 THEN
    RAISE EXCEPTION 'CC_0387 gate: expected 3 future-dated terms, found %', v_future;
  END IF;

  -- 🔴 the sitting thirteen must carry NO date
  SELECT count(*) INTO v_dated
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name IN ('City of Reno, Nevada, US','Washoe County, Nevada, US')
     AND t.term_start IS NOT NULL AND t.term_start <= CURRENT_DATE;
  IF v_dated <> 0 THEN
    RAISE EXCEPTION 'CC_0387 gate: % sitting term(s) carry a term_start. None is published; an '
                    'election or a current-term range is not an occupancy start.', v_dated;
  END IF;

  -- the court stays empty
  SELECT count(*) INTO v_judges
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name = 'Reno Municipal Court';
  IF v_judges <> 0 THEN
    RAISE EXCEPTION 'CC_0387 gate: % municipal judge(s) seated; the bench is unresolved', v_judges;
  END IF;

  -- Ward 4 must have NO successor waiting
  SELECT count(*) INTO v_ward4
    FROM essentials.office_next_term nt
    JOIN essentials.offices o ON o.id = nt.office_id
   WHERE o.title = 'Council Member, Ward 4';
  IF v_ward4 <> 0 THEN
    RAISE EXCEPTION 'CC_0387 gate: Ward 4 has a successor row, but that race was undecided';
  END IF;

  SELECT count(*) INTO v_sw FROM essentials.office_swearing_in s
    JOIN essentials.offices o ON o.id = s.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Reno, Nevada, US';
  IF v_sw <> 3 THEN RAISE EXCEPTION 'CC_0387 gate: expected 3 swearing-in rows, found %', v_sw; END IF;

  -- 🔴 the namesakes must be untouched: neither may have acquired a Reno/Washoe term
  SELECT count(*) INTO v_oregon FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE p.external_id = -4110021
     AND g.name IN ('City of Reno, Nevada, US','Washoe County, Nevada, US');
  IF v_oregon <> 0 THEN
    RAISE EXCEPTION 'CC_0387 gate: the Oregon State Senator Kathleen Taylor was seated on a '
                    'Reno/Washoe office — the namesake collision was not avoided';
  END IF;

  SELECT count(*) INTO v_horry FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE lower(p.first_name) = 'matthew' AND lower(p.last_name) = 'johnson'
     AND p.source NOT LIKE 'CC_0387 %'
     AND g.name IN ('City of Reno, Nevada, US','Washoe County, Nevada, US');
  IF v_horry <> 0 THEN
    RAISE EXCEPTION 'CC_0387 gate: a pre-existing Matthew Johnson was seated on a Reno office';
  END IF;

  RAISE NOTICE 'CC_0387 OK: 16 people · 13 seated today · 3 incoming 2026-11-13 · court empty · Ward 4 open.';
END $$;

COMMIT;
