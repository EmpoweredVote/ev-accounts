-- CC_0317_alaska_legislature_occupancy.sql
-- Alaska Legislature — occupancy: 60 people and 60 office_terms, the whole 34th Legislature.
-- Structure is CC_0316 and must run first. Portraits are CC_0318.
--
-- Roster, sources, source defects and the per-member term_start reasoning:
--   backend/data/seed-ak-legislature-2026/ROSTERS.md
-- The VALUES block below is generated, not hand-typed:
--   node data/seed-ak-legislature-2026/gen-migration-values.mjs
--
-- ═══ 🔴 EVERY SEAT IN THIS FILE IS CORRECT TODAY AND HAS A KNOWN EXPIRY ═══
--
-- All 40 House seats and 10 of the 20 Senate seats were on the 2026-11-03 ballot, four days after
-- this roster was read. Nothing here goes stale on election night: AS 24.05.080 starts the new
-- terms on the THIRD TUESDAY IN JANUARY following the election, so these 60 rows stay correct
-- until **2027-01-19** and the winners are seated then, by a `seat_officeholder` pass against the
-- certified results. That is 81 days of validity, not 4.
-- ▶ The follow-up, with what to re-read, is the ▶ Open items section of ROSTERS.md.
--
-- 🔴 THE TERM-START RULE IS NOT THE ONE THE CONSTITUTION PRINTS. Alaska Const. Art. II sec. 3 says
--    terms begin "on the fourth Monday of the January following election UNLESS OTHERWISE PROVIDED
--    BY LAW" — and AS 24.05.080 so provides. The operative rule is the third Tuesday in January.
--    ⚠ Ballotpedia's own Article II page carries an editor's note describing an OLDER split rule
--      (second Monday after a presidential year, third Monday after a gubernatorial year). That
--      note is stale and its own data contradicts it: the three distinct January arrival dates in
--      this roster are 2015-01-20, 2023-01-17 and 2025-01-21, and all three are the THIRD TUESDAY,
--      across both a presidential-year and a gubernatorial-year cycle. The rule is uniform.
--      Corroborated a third way: Ballotpedia's member pages say "current term ends on
--      January 19, 2027", which is the third Tuesday of January 2027.
--
-- ═══ term_start IS CONTINUOUS OCCUPANCY, NOT THE CURRENT TERM ═══
--
-- Ballotpedia's "Date assumed office" is used because it carries the EARLIER arrival for someone
-- who has been re-elected, which is what `office_terms` wants. 51 of 60 are a third-Tuesday
-- January; the other 9 are arrivals mid-term or long ago.
--
-- 🔴 A SOURCE CAN PUBLISH TWO DATES FOR ONE PERSON AND ONLY ONE OF THEM IS THIS COLUMN.
--    Ballotpedia gives Cathy Tilton an infobox "Appointed November 26, 2025" AND a roster
--    "Date assumed office" of November 29, 2025. Those are different events three days apart —
--    being appointed, and taking the seat. `term_start` is when the seat was HELD, so the roster
--    date is used and the appointment date is written nowhere. Same for Rauscher (26th/29th
--    November) and for St. Clair and Nelson (24th/30th December). ⚠ This is the same class of
--    error as reading a vacancy's "date of vacancy" as the first empty day — read what the date
--    is a date OF.
--
-- ⚠ TWO SENATORS HAVE A YEAR AND NO DAY. Lyman Hoffman (District S) assumed office "in 2003" and
--   Donny Olson (District T) "in 2001" — that is all either source publishes. Both are written
--   `start_precision => 'year'` at YYYY-01-01. NO DATE IS INVENTED.
--
-- ═══ how_started WAS READ, NOT INFERRED FROM THE DATE ═══
--
--   appointed (4)  Tilton, Rauscher, St. Clair, Nelson — each carries an explicit "Appointed
--                  <date>" line in their Ballotpedia infobox.
--   unknown   (1)  Neal Foster arrived 2009-11-16, mid-term and on no election day, and his
--                  infobox carries NO appointment line. The mechanism is not published, so it is
--                  recorded as unknown rather than guessed at.
--   elected  (55)  everyone else.
--
-- 🟢 THE FOUR APPOINTMENTS FORM A CHAIN, AND IT CHECKS OUT GEOGRAPHICALLY. Tilton (House 26) and
--    Rauscher (House 29) were appointed to the Senate on 2025-11-26; St. Clair and Nelson were
--    then appointed to the House seats they had left, on 2025-12-24. Ballotpedia names St. Clair's
--    predecessor as Tilton and Nelson's as Rauscher. And the pairing agrees: Senate M is House
--    25+26 (Tilton's old seat), Senate O is House 29+30 (Rauscher's). Four independent facts that
--    would all have to be wrong together.
--
-- ═══ PARTY IS NOT WRITTEN ═══
--
-- `politicians.party` stays NULL for all 60 — party lives on `races.primary_party`. The gate below
-- asserts no Alaska legislator carries one. ⚠ Alaska makes this especially worth holding to: its
-- general election is ranked-choice after an open top-four primary, both chambers are run by
-- BIPARTISAN COALITIONS, and the two sources disagree on the labels anyway (the Legislature prints
-- "Not Affiliated" and "Independent" where Ballotpedia prints "Nonpartisan" and "Undeclared" —
-- which are two distinct registration categories in Alaska, not synonyms).
--
-- ═══ NAMES ═══
--
-- The Legislature's own roster is canonical; the Ballotpedia rendering goes in `alternate_names`
-- where the two differ, which is 9 of 60. All 9 are formal-vs-common for the SAME person — same
-- district, same surname in every case (Chuck/Charles Kopp, Andy/Andrew Josephson, Mike/Glenn
-- Prax, Rebecca/Becky Schwanke, Cathy/Catherine Giessel, Donny/Donald Olson, Robert Myers/Myers
-- Jr., and the two members whose published name carries an Alaska Native middle name, Robyn
-- Niayuq Frier and Nellie Unangiq Jimmie, which the aggregator drops and we keep).
-- ⚠ Donny Olson's Ballotpedia page is at /Donald_Olson; /Donny_Olson is a real 404. The
--   alternate name is what makes him findable.
--
-- ═══ 🔴 NO NAME COLLIDES, AND THAT WAS MEASURED, NOT ASSUMED ═══
--
-- Checked against production on 2026-10-30 three ways, each with a positive control that matched
-- known rows before the real query was trusted: zero exact `full_name` matches, and zero exact
-- (first_name, last_name) matches — which is how the duplicate-name guard actually keys. So the
-- two-pass `essentials.allow_duplicate_name` dance that CC_0310 needed for Idaho is NOT needed
-- here, and no carve-out is opened.
-- ⚠ THE NEAR MISSES ARE REAL AND ARE ALL DIFFERENT PEOPLE — 16 production rows share a surname
--   and a first initial with an Alaska legislator: prod's Janelle Bynum is Oregon's congresswoman,
--   Adam Gray is California's, Dusty Johnson is South Dakota's, Richard Myers is not Robert. This
--   is the "Mike Lee failure" shape. The pre-flight below re-asserts the absence at run time, so
--   if production gains a colliding row between now and the apply this migration STOPS instead of
--   silently seating the wrong person or silently skipping a seat.

BEGIN;

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_off int; v_terms int; v_collide int; v_names text;
BEGIN
  SELECT count(*) INTO v_off
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ak' AND d.district_type IN ('STATE_UPPER','STATE_LOWER');
  IF v_off <> 60 THEN
    RAISE EXCEPTION 'CC_0317 pre-flight: expected 60 Alaska legislative offices, found % — run '
                    'CC_0316 (structure) first', v_off;
  END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o   ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ak' AND d.district_type IN ('STATE_UPPER','STATE_LOWER');
  IF v_terms <> 0 THEN
    RAISE EXCEPTION 'CC_0317 pre-flight: % Alaska legislative office_terms row(s) already exist — '
                    'this migration seats a greenfield chamber and is not a re-seeder', v_terms;
  END IF;

  -- 🔴 The duplicate-name guard keys on (first_name, last_name). Re-assert the measured absence.
  SELECT count(*), string_agg(DISTINCT p.full_name, ', ') INTO v_collide, v_names
    FROM essentials.politicians p
   WHERE (lower(p.first_name), lower(p.last_name)) IN (
     (lower('Chuck'),'kopp'),(lower('Bryce'),'edgmon'),(lower('DeLena'),'johnson'),
     (lower('Jamie'),'allard'),(lower('Jeremy'),'bynum'),(lower('Ashley'),'carrick'),
     (lower('Mia'),'costello'),(lower('Julie'),'coulombe'),(lower('Maxine'),'dibert'),
     (lower('Ted'),'eischeid'),(lower('Bill'),'elam'),(lower('Zack'),'fields'),
     (lower('Neal'),'foster'),(lower('Robyn Niayuq'),'frier'),(lower('Alyse'),'galvin'),
     (lower('Andrew'),'gray'),(lower('Carolyn'),'hall'),(lower('Sara'),'hannan'),
     (lower('Rebecca'),'himschoot'),(lower('Ky'),'holland'),(lower('Nellie Unangiq'),'jimmie'),
     (lower('Andy'),'josephson'),(lower('Kevin'),'mccabe'),(lower('Donna'),'mears'),
     (lower('Genevieve'),'mina'),(lower('Elexie'),'moore'),(lower('David'),'nelson'),
     (lower('Garret'),'nelson'),(lower('Mike'),'prax'),(lower('Justin'),'ruffridge'),
     (lower('Dan'),'saddler'),(lower('Calvin'),'schrage'),(lower('Rebecca'),'schwanke'),
     (lower('Steve'),lower('St. Clair')),(lower('Will'),'stapp'),(lower('Andi'),'story'),
     (lower('Louise'),'stutes'),(lower('Frank'),'tomaszewski'),(lower('Jubilee'),'underwood'),
     (lower('Sarah'),'vance'),(lower('Cathy'),'giessel'),(lower('Gary'),'stevens'),
     (lower('Mike'),'cronk'),(lower('Jesse'),'bjorkman'),(lower('Matt'),'claman'),
     (lower('Forrest'),'dunbar'),(lower('Elvi'),'gray-jackson'),(lower('Lyman'),'hoffman'),
     (lower('James'),'kaufman'),(lower('Scott'),'kawasaki'),(lower('Jesse'),'kiehl'),
     (lower('Kelly'),'merrick'),(lower('Robert'),'myers'),(lower('Donny'),'olson'),
     (lower('George'),'rauscher'),(lower('Bert'),'stedman'),(lower('Cathy'),'tilton'),
     (lower('Loki'),'tobin'),(lower('Bill'),'wielechowski'),(lower('Robert'),'yundt')
   );
  IF v_collide <> 0 THEN
    RAISE EXCEPTION 'CC_0317 pre-flight: % production politician row(s) already carry an Alaska '
                    'legislator''s exact (first_name, last_name): %. Measured zero on 2026-10-30. '
                    'A name-keyed insert would now either seat the WRONG person or silently skip a '
                    'seat — the Mike Lee failure. Resolve the identity before re-running.',
                    v_collide, v_names;
  END IF;

  RAISE NOTICE 'CC_0317 pre-flight OK: 60 offices present, 0 existing terms, 0 name collisions.';
END $$;

-- ── The 60 people and their seatings ──────────────────────────────────────────
-- 🔴 `is_incumbent` IS SET EXPLICITLY ON EVERY ROW. It defaults to false since CA_0188, and a
--    seated person inserted without it is HIDDEN from address search. All 60 hold the seat today.
-- `party` is deliberately omitted (stays NULL) — see the header.
WITH src(chamber, district_code, full_name, first_name, last_name, alternate_names,
         term_start, start_precision, how_started, member_code, home_city) AS (VALUES
-- @generated-by data/seed-ak-legislature-2026/gen-migration-values.mjs from roster-final.json
    ('House', '10', 'Chuck Kopp', 'Chuck', 'Kopp', ARRAY['Charles Kopp']::text[], '2025-01-21'::date, 'day', 'elected', 'kop', 'Anchorage'),
    ('House', '37', 'Bryce Edgmon', 'Bryce', 'Edgmon', '{}'::text[], '2015-01-20'::date, 'day', 'elected', 'edg', 'Dillingham'),
    ('House', '25', 'DeLena Johnson', 'DeLena', 'Johnson', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'jhs', 'Palmer'),
    ('House', '23', 'Jamie Allard', 'Jamie', 'Allard', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'alr', 'Eagle River'),
    ('House', '1', 'Jeremy Bynum', 'Jeremy', 'Bynum', '{}'::text[], '2025-01-21'::date, 'day', 'elected', 'byn', 'Ketchikan'),
    ('House', '35', 'Ashley Carrick', 'Ashley', 'Carrick', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'cai', 'Fairbanks'),
    ('House', '15', 'Mia Costello', 'Mia', 'Costello', '{}'::text[], '2025-01-21'::date, 'day', 'elected', 'cos', 'Anchorage'),
    ('House', '11', 'Julie Coulombe', 'Julie', 'Coulombe', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'cou', 'Anchorage'),
    ('House', '31', 'Maxine Dibert', 'Maxine', 'Dibert', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'dib', 'Fairbanks'),
    ('House', '22', 'Ted Eischeid', 'Ted', 'Eischeid', '{}'::text[], '2025-01-21'::date, 'day', 'elected', 'eis', 'Anchorage'),
    ('House', '8', 'Bill Elam', 'Bill', 'Elam', '{}'::text[], '2025-01-21'::date, 'day', 'elected', 'ela', 'Nikiski'),
    ('House', '17', 'Zack Fields', 'Zack', 'Fields', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'fie', 'Anchorage'),
    ('House', '39', 'Neal Foster', 'Neal', 'Foster', '{}'::text[], '2009-11-16'::date, 'day', 'unknown', 'fon', 'Nome'),
    ('House', '40', 'Robyn Niayuq Frier', 'Robyn Niayuq', 'Frier', ARRAY['Robyn Frier']::text[], '2025-01-21'::date, 'day', 'elected', 'frb', 'Utqiagvik'),
    ('House', '14', 'Alyse Galvin', 'Alyse', 'Galvin', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'gal', 'Anchorage'),
    ('House', '20', 'Andrew Gray', 'Andrew', 'Gray', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'gry', 'Anchorage'),
    ('House', '16', 'Carolyn Hall', 'Carolyn', 'Hall', '{}'::text[], '2025-01-21'::date, 'day', 'elected', 'hll', 'Anchorage'),
    ('House', '4', 'Sara Hannan', 'Sara', 'Hannan', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'hnn', 'Juneau'),
    ('House', '2', 'Rebecca Himschoot', 'Rebecca', 'Himschoot', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'hms', 'Sitka'),
    ('House', '9', 'Ky Holland', 'Ky', 'Holland', '{}'::text[], '2025-01-21'::date, 'day', 'elected', 'hla', 'Anchorage'),
    ('House', '38', 'Nellie Unangiq Jimmie', 'Nellie Unangiq', 'Jimmie', ARRAY['Nellie Jimmie']::text[], '2025-01-21'::date, 'day', 'elected', 'jim', 'Toksook Bay'),
    ('House', '13', 'Andy Josephson', 'Andy', 'Josephson', ARRAY['Andrew Josephson']::text[], '2023-01-17'::date, 'day', 'elected', 'jos', 'Anchorage'),
    ('House', '30', 'Kevin McCabe', 'Kevin', 'McCabe', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'mca', 'Big Lake'),
    ('House', '21', 'Donna Mears', 'Donna', 'Mears', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'mea', 'Anchorage'),
    ('House', '19', 'Genevieve Mina', 'Genevieve', 'Mina', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'mna', 'Anchorage'),
    ('House', '28', 'Elexie Moore', 'Elexie', 'Moore', '{}'::text[], '2025-01-21'::date, 'day', 'elected', 'moo', 'Wasilla'),
    ('House', '18', 'David Nelson', 'David', 'Nelson', '{}'::text[], '2025-01-21'::date, 'day', 'elected', 'ned', 'Anchorage'),
    ('House', '29', 'Garret Nelson', 'Garret', 'Nelson', '{}'::text[], '2025-12-30'::date, 'day', 'appointed', 'neg', 'Sutton'),
    ('House', '33', 'Mike Prax', 'Mike', 'Prax', ARRAY['Glenn Prax']::text[], '2023-01-17'::date, 'day', 'elected', 'pra', 'North Pole'),
    ('House', '7', 'Justin Ruffridge', 'Justin', 'Ruffridge', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'ruf', 'Soldotna'),
    ('House', '24', 'Dan Saddler', 'Dan', 'Saddler', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'sad', 'Eagle River'),
    ('House', '12', 'Calvin Schrage', 'Calvin', 'Schrage', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'scg', 'Anchorage'),
    ('House', '36', 'Rebecca Schwanke', 'Rebecca', 'Schwanke', ARRAY['Becky Schwanke']::text[], '2025-01-21'::date, 'day', 'elected', 'scw', 'Glennallen'),
    ('House', '26', 'Steve St. Clair', 'Steve', 'St. Clair', '{}'::text[], '2025-12-30'::date, 'day', 'appointed', 'stc', 'Wasilla'),
    ('House', '32', 'Will Stapp', 'Will', 'Stapp', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'spp', 'Fairbanks'),
    ('House', '3', 'Andi Story', 'Andi', 'Story', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'sto', 'Juneau'),
    ('House', '5', 'Louise Stutes', 'Louise', 'Stutes', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'sts', 'Kodiak'),
    ('House', '34', 'Frank Tomaszewski', 'Frank', 'Tomaszewski', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'tmz', 'Fairbanks'),
    ('House', '27', 'Jubilee Underwood', 'Jubilee', 'Underwood', '{}'::text[], '2025-01-21'::date, 'day', 'elected', 'und', 'Wasilla'),
    ('House', '6', 'Sarah Vance', 'Sarah', 'Vance', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'van', 'Homer'),
    ('Senate', 'E', 'Cathy Giessel', 'Cathy', 'Giessel', ARRAY['Catherine Giessel']::text[], '2023-01-17'::date, 'day', 'elected', 'gie', 'Anchorage'),
    ('Senate', 'C', 'Gary Stevens', 'Gary', 'Stevens', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'stg', 'Kodiak'),
    ('Senate', 'R', 'Mike Cronk', 'Mike', 'Cronk', '{}'::text[], '2025-01-21'::date, 'day', 'elected', 'crn', 'Tok/Northway'),
    ('Senate', 'D', 'Jesse Bjorkman', 'Jesse', 'Bjorkman', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'bjk', 'Nikiski'),
    ('Senate', 'H', 'Matt Claman', 'Matt', 'Claman', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'cla', 'Anchorage'),
    ('Senate', 'J', 'Forrest Dunbar', 'Forrest', 'Dunbar', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'dnb', 'Anchorage'),
    ('Senate', 'G', 'Elvi Gray-Jackson', 'Elvi', 'Gray-Jackson', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'gra', 'Anchorage'),
    ('Senate', 'S', 'Lyman Hoffman', 'Lyman', 'Hoffman', '{}'::text[], '2003-01-01'::date, 'year', 'elected', 'hof', 'Bethel'),
    ('Senate', 'F', 'James Kaufman', 'James', 'Kaufman', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'kau', 'Anchorage'),
    ('Senate', 'P', 'Scott Kawasaki', 'Scott', 'Kawasaki', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'kaw', 'Fairbanks'),
    ('Senate', 'B', 'Jesse Kiehl', 'Jesse', 'Kiehl', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'kie', 'Juneau'),
    ('Senate', 'L', 'Kelly Merrick', 'Kelly', 'Merrick', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'mrr', 'Eagle River'),
    ('Senate', 'Q', 'Robert Myers', 'Robert', 'Myers', ARRAY['Robert Myers Jr.']::text[], '2023-01-17'::date, 'day', 'elected', 'mye', 'North Pole'),
    ('Senate', 'T', 'Donny Olson', 'Donny', 'Olson', ARRAY['Donald Olson']::text[], '2001-01-01'::date, 'year', 'elected', 'ols', 'Golovin'),
    ('Senate', 'O', 'George Rauscher', 'George', 'Rauscher', '{}'::text[], '2025-11-29'::date, 'day', 'appointed', 'rac', 'Sutton'),
    ('Senate', 'A', 'Bert Stedman', 'Bert', 'Stedman', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'smn', 'Sitka'),
    ('Senate', 'M', 'Cathy Tilton', 'Cathy', 'Tilton', '{}'::text[], '2025-11-29'::date, 'day', 'appointed', 'ttn', 'Wasilla'),
    ('Senate', 'I', 'Loki Tobin', 'Loki', 'Tobin', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'tob', 'Anchorage'),
    ('Senate', 'K', 'Bill Wielechowski', 'Bill', 'Wielechowski', '{}'::text[], '2023-01-17'::date, 'day', 'elected', 'wie', 'Anchorage'),
    ('Senate', 'N', 'Robert Yundt', 'Robert', 'Yundt', '{}'::text[], '2025-01-21'::date, 'day', 'elected', 'yun', 'Wasilla')
),
ins AS (
  INSERT INTO essentials.politicians
    (full_name, first_name, last_name, alternate_names, is_active, is_incumbent,
     term_date_precision, source)
  SELECT s.full_name, s.first_name, s.last_name, s.alternate_names, true, true,
         s.start_precision,
         'akleg.gov ' || lower(s.chamber) || '.php member roster for the 34th Alaska Legislature, '
         || 'read 2026-10-30 (CC_0317): ' || s.full_name || ', District ' || s.district_code
         || ', member code ' || s.member_code || ', home city ' || coalesce(s.home_city, 'not published')
         || '. Seat and name independently confirmed against ballotpedia.org/Alaska_'
         || CASE WHEN s.chamber = 'Senate' THEN 'State_Senate' ELSE 'House_of_Representatives' END
         || ' officeholder table, which also supplies the date assumed office ('
         || to_char(s.term_start, 'YYYY-MM-DD') || ', precision ' || s.start_precision
         || ', how_started ' || s.how_started || ').'
    FROM src s
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.politicians p
      WHERE lower(p.first_name) = lower(s.first_name)
        AND lower(p.last_name)  = lower(s.last_name)
   )
  RETURNING id, first_name, last_name
)
SELECT essentials.seat_officeholder(
         o.id,
         ins.id,
         s.term_start,
         'akleg.gov ' || lower(s.chamber) || '.php roster for the 34th Alaska Legislature + '
         || 'ballotpedia.org officeholder table, both read 2026-10-30 (CC_0317). Term start is '
         || 'the DATE ASSUMED OFFICE, not the date of appointment where those differ.',
         s.how_started,
         s.start_precision
       )
  FROM src s
  JOIN ins ON lower(ins.first_name) = lower(s.first_name)
          AND lower(ins.last_name)  = lower(s.last_name)
  JOIN essentials.districts d
    ON lower(d.state) = 'ak'
   AND d.district_type = CASE WHEN s.chamber = 'Senate' THEN 'STATE_UPPER' ELSE 'STATE_LOWER' END
   AND d.mtfcc = CASE WHEN s.chamber = 'Senate' THEN 'G5210' ELSE 'G5220' END
   AND d.geo_id = CASE WHEN s.chamber = 'Senate' THEN '0200' || s.district_code
                       ELSE '02' || lpad(s.district_code, 3, '0') END
  JOIN essentials.offices o ON o.district_id = d.id;

-- ── Post-verify gate ──────────────────────────────────────────────────────────
DO $$
DECLARE
  v_people int; v_terms int; v_sen int; v_hou int; v_party int; v_notinc int;
  v_unseated int; v_openended int; v_prec int; v_how text; v_vacflag int; v_fanout int;
BEGIN
  SELECT count(*) INTO v_people
    FROM essentials.politicians p
   WHERE p.source LIKE '%CC_0317%';
  IF v_people <> 60 THEN
    RAISE EXCEPTION 'CC_0317 post-verify: expected 60 new Alaska legislators, found %', v_people;
  END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o   ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ak' AND d.district_type IN ('STATE_UPPER','STATE_LOWER');
  IF v_terms <> 60 THEN
    RAISE EXCEPTION 'CC_0317 post-verify: expected 60 Alaska legislative office_terms rows, found %', v_terms;
  END IF;

  -- 🔴 THE ONE THAT MATTERS: every seat resolves to exactly one CURRENT holder through the view.
  -- An office with no term row is invisible and nothing errors — that is the failure CI cannot catch.
  SELECT count(*) INTO v_sen
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'ak' AND d.district_type = 'STATE_UPPER'
     AND och.politician_id IS NOT NULL;
  IF v_sen <> 20 THEN
    RAISE EXCEPTION 'CC_0317 post-verify: % of 20 Alaska Senate seats resolve to a current holder. '
                    '⚠ office_current_holder LEFT JOINs from offices, so an unseated office comes '
                    'back as a NULL politician_id and a bare count(*) would pass vacuously — this '
                    'counts och.politician_id.', v_sen;
  END IF;

  SELECT count(*) INTO v_hou
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'ak' AND d.district_type = 'STATE_LOWER'
     AND och.politician_id IS NOT NULL;
  IF v_hou <> 40 THEN
    RAISE EXCEPTION 'CC_0317 post-verify: % of 40 Alaska House seats resolve to a current holder', v_hou;
  END IF;

  -- No Alaska legislative office left unseated.
  SELECT count(*) INTO v_unseated
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o   ON o.id = m.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ak' AND d.district_type IN ('STATE_UPPER','STATE_LOWER');
  IF v_unseated <> 0 THEN
    RAISE EXCEPTION 'CC_0317 post-verify: % Alaska legislative office(s) are in '
                    'essentials.offices_missing_terms. The unflagged baseline must not move.', v_unseated;
  END IF;

  -- 🔴 Seating does NOT clear is_vacant, and nothing here set it. Assert held-AND-vacant is zero.
  SELECT count(*) INTO v_vacflag
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ak' AND d.district_type IN ('STATE_UPPER','STATE_LOWER') AND o.is_vacant;
  IF v_vacflag <> 0 THEN
    RAISE EXCEPTION 'CC_0317 post-verify: % Alaska legislative office(s) are held AND flagged '
                    'vacant. seat_officeholder does not clear the flag — clear it explicitly.', v_vacflag;
  END IF;

  -- Antipartisan: party lives on races.primary_party, never on the person.
  SELECT count(*) INTO v_party
    FROM essentials.politicians p WHERE p.source LIKE '%CC_0317%' AND p.party IS NOT NULL;
  IF v_party <> 0 THEN
    RAISE EXCEPTION 'CC_0317 post-verify: % Alaska legislator(s) carry a party. Party belongs on '
                    'races.primary_party.', v_party;
  END IF;

  -- is_incumbent defaults to false; a seated person without it is hidden from address search.
  SELECT count(*) INTO v_notinc
    FROM essentials.politicians p
   WHERE p.source LIKE '%CC_0317%' AND (p.is_incumbent IS NOT TRUE OR p.is_active IS NOT TRUE);
  IF v_notinc <> 0 THEN
    RAISE EXCEPTION 'CC_0317 post-verify: % Alaska legislator(s) are not active incumbents and '
                    'would be hidden from address search.', v_notinc;
  END IF;

  -- Every term open-ended: a future term_end makes a seat silently self-vacate.
  SELECT count(*) INTO v_openended
    FROM essentials.office_terms ot
    JOIN essentials.offices o   ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ak' AND d.district_type IN ('STATE_UPPER','STATE_LOWER')
     AND ot.term_end IS NOT NULL;
  IF v_openended <> 0 THEN
    RAISE EXCEPTION 'CC_0317 post-verify: % Alaska legislative term(s) carry a term_end. These are '
                    'sitting members; the 2027-01-19 turnover is a later seat_officeholder pass.', v_openended;
  END IF;

  -- The two year-precision rows are expected and are exactly two.
  SELECT count(*) INTO v_prec
    FROM essentials.office_terms ot
    JOIN essentials.offices o   ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ak' AND d.district_type IN ('STATE_UPPER','STATE_LOWER')
     AND ot.start_precision = 'year';
  IF v_prec <> 2 THEN
    RAISE EXCEPTION 'CC_0317 post-verify: expected exactly 2 year-precision terms (Hoffman 2003, '
                    'Olson 2001 — the only two the sources date to a year alone), found %', v_prec;
  END IF;

  -- how_started distribution, asserted as the shape that was actually read.
  SELECT string_agg(k || '=' || n, ' ' ORDER BY k) INTO v_how FROM (
    SELECT ot.how_started AS k, count(*)::text AS n
      FROM essentials.office_terms ot
      JOIN essentials.offices o   ON o.id = ot.office_id
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'ak' AND d.district_type IN ('STATE_UPPER','STATE_LOWER')
     GROUP BY ot.how_started
  ) x;
  IF v_how <> 'appointed=4 elected=55 unknown=1' THEN
    RAISE EXCEPTION 'CC_0317 post-verify: how_started distribution is "%", expected '
                    '"appointed=4 elected=55 unknown=1" — 4 read from Ballotpedia infoboxes, '
                    'Neal Foster unpublished, the rest elected.', v_how;
  END IF;

  -- 🔴 THE POLITICIAN-ROOTED DIRECTION FANS OUT. One person must hold exactly one Alaska seat.
  SELECT count(*) INTO v_fanout FROM (
    SELECT och.politician_id
      FROM essentials.office_current_holder och
      JOIN essentials.offices o   ON o.id = och.office_id
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'ak' AND d.district_type IN ('STATE_UPPER','STATE_LOWER')
       AND och.politician_id IS NOT NULL
     GROUP BY och.politician_id HAVING count(*) > 1
  ) y;
  IF v_fanout <> 0 THEN
    RAISE EXCEPTION 'CC_0317 post-verify: % person/people hold more than one Alaska legislative '
                    'seat. Nobody may sit in both chambers.', v_fanout;
  END IF;

  RAISE NOTICE 'CC_0317 OK: 60 legislators seated — 20 Senate + 40 House, every seat resolving to '
               'exactly one current holder, no party written, all open-ended, 2 year-precision, '
               'how_started %. ▶ These rows are correct until 2027-01-19.', v_how;
END $$;

COMMIT;
