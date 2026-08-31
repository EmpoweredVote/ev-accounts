-- CC_0024_lawrence_county_council_caucus_appointments.sql
-- Lawrence County, IN council: seat the two 2026 caucus appointees.
--   Council - District 4   Jeffrey Lytton -> Larry Arnold     from 2026-01-22
--   Council - At Large     (vacant)       -> Dustin Gabhart   from 2026-01-30
--
-- FOUND BY A HEADSHOT PASS on 2026-08-30, which read the county's own roster for a portrait and
-- found it disagreed with us. See .planning/todos/2026-08-30-headshot-check-found-two-stale-rosters.md.
-- That pass deliberately wrote NOTHING: the roster alone did not say whether Arnold had been
-- seated or was merely the coming primary winner, and closing Lytton's term needs a date. This
-- migration is the follow-up, after the evidence separated the two readings.
--
-- ---------------------------------------------------------------------------
-- 🔴 THE COUNTY PUBLISHES NO COUNCIL MINUTES, SO THE MINUTES CANNOT BE THE SOURCE.
-- The county's AgendaCenter holds County Council documents for 2024 and 2025 only -- one file in
-- total -- and none for 2026; the Archive Center is empty. Commissioners' agendas ARE posted for
-- all of 2026, so the gap is this body, not the site. Council meetings exist only as video on the
-- county's YouTube channel. Anyone re-checking this should not go looking for minutes.
--
-- WHAT THE EVIDENCE IS, IN ORDER OF WEIGHT:
--
-- 1. The vacancy and its cause, reported the day the caucus was called (WBIW, 2026-01-08,
--    https://www.wbiw.com/2026/01/08/gop-calls-caucus-to-fill-lawrence-county-council-seat-following-lytton-resignation/):
--      "The move follows the resignation of Councilman Jeff Lytton, who recently stepped down
--       from his District 4 seat. Lytton ... resigned his post after moving his primary residence
--       to a different council district, rendering him ineligible to represent District 4."
--      "Republican Party Chairman Chase Cummings will preside over the proceedings, which are set
--       for Thursday, Jan. 22, 2026, at 6:00 p.m."
--    The caucus was called to fill "the remainder of Lytton's term".
--
-- 2. The second caucus, for the at-large seat (WBIW, 2026-01-05,
--    https://www.wbiw.com/2026/01/05/lawrence-county-gop-calls-caucus-to-fill-council-vacancy-following-death-of-scott-smith/):
--      "the caucus, which is set to take place on Friday, Jan. 30, 2026. The individual selected
--       by the committee will serve the remainder of Smith's term."
--    Scott Smith's term is ALREADY closed correctly in our data: term_end 2025-12-28, how_ended
--    'died'. This migration only fills the seat he left.
--
-- 3. The county's own roster (https://lawrencecounty.in.gov/183/County-Council, read 2026-08-31)
--    names "Larry Arnold, District 4" and "Dustin Gabhart, At Large". The county's search index
--    dates that page's last change to 2026-02-10 -- after both caucuses.
--
-- 4. The Internet Archive brackets the change to that page, which is what kills the rival reading
--    that the county simply displayed the coming primary winner early:
--      2025-02-26  Jeff Lytton, District 4   |  Julie Blackwell-Chase, At Large
--      2026-01-05  Jeff Lytton, District 4   |  Scott Smith, At Large
--      today       Larry Arnold, District 4  |  Dustin Gabhart, At Large
--    Both names changed in one update, months BEFORE the 2026-05-05 primary. And the seat could
--    not have stayed with Lytton in any case: he resigned it.
--
-- ⚠ WHAT IS INFERRED, AND SHOULD BE SAID PLAINLY: no source reports who WON either caucus. The
-- roster names the two people, and under IC 3-13-11 a party caucus is the only route into either
-- seat between the vacancy and 2027-01-01. That is a sound inference, not a report. If the county
-- clerk is ever asked, ask for the two CAN-12 filings; they carry the result.
--
-- 🔴 LYTTON'S CLOSING DATE IS AN ARTIFACT, NOT A CLAIM. seat_officeholder closes the predecessor
-- the day before the successor starts, so Lytton's term_end lands on 2026-01-21. His actual last
-- day is an UNKNOWN DAY BEFORE 2026-01-08, when WBIW reported the resignation as already done,
-- and a real vacancy sat between the two. office_terms has start_precision but NO end_precision,
-- so there is nowhere in the row to record that the end date is approximate -- this comment is
-- the only place a later reader can find it. how_ended is set to 'resigned', which is the part we
-- do know and can state. The alternative -- writing a vacancy span -- needs a first vacant day we
-- do not have, and CLAUDE.md forbids inventing one.
--
-- Term starts are the CAUCUS dates, at day precision. An appointee qualifies by oath, which can
-- fall a day or two later and is not published; the caucus date is the documented one.
-- how_started is 'appointed' for both, which is what a caucus is.
--
-- 🔴 IDENTITY. Neither person exists in essentials.politicians: a search for '%larry arnold%' and
-- '%gabhart%' across the whole table returns nothing (checked 2026-08-31), so there is no row to
-- reuse and no homonym to collide with. They are created here in a fresh band derived from the
-- county FIPS, -18093NN, which is empty (-1809310..-1809301: 0 rows). Party is deliberately NULL
-- -- party lives on races.primary_party in this schema, never on the person.
--
-- Photos: neither has one. The county publishes no member photographs at all, so the photo
-- columns are left NULL rather than pointed at a page URL, which would read as coverage and hide
-- them from the backlog.
-- ---------------------------------------------------------------------------

BEGIN;

-- 1. Preconditions. Every id below was read from prod on 2026-08-31; if any has moved, the rest
--    of this migration would write into the wrong seats.
DO $$
DECLARE
  n int;
BEGIN
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.id = '7d6715f7-c1f3-43df-93c7-b543c633c518'
     AND o.title = 'Council - District 4'
     AND d.geo_id = '1809300004' AND d.state = 'IN'
     AND p.full_name = 'Jeffrey Lytton';
  IF n <> 1 THEN
    RAISE EXCEPTION 'precondition: District 4 is not the Lytton seat we measured (found %)', n;
  END IF;

  -- The at-large seat must be VACANT. office_current_holder LEFT JOINs from offices, so "no
  -- holder" is a NULL politician_id, never an absent row.
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.id = '5dcf1678-1996-448e-8933-39094ebe9326'
     AND o.title = 'Council - At Large'
     AND d.geo_id = '18093' AND d.state = 'IN'
     AND och.politician_id IS NULL;
  IF n <> 1 THEN
    RAISE EXCEPTION 'precondition: the at-large seat is not the vacant one we measured (found %)', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.office_id = '5dcf1678-1996-448e-8933-39094ebe9326'
     AND p.full_name = 'Scott Smith'
     AND t.term_end = DATE '2025-12-28' AND t.how_ended = 'died';
  IF n <> 1 THEN
    RAISE EXCEPTION 'precondition: Scott Smith closed at-large term is not as measured (found %)', n;
  END IF;

  -- No existing row may answer to either name, anywhere in the table. external_id is the identity
  -- rule, not the name -- but a surprise homonym means re-reading before inserting a new person.
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE full_name ILIKE '%larry%arnold%' OR full_name ILIKE '%gabhart%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'precondition: % existing politician row(s) match Arnold/Gabhart -- re-read identity before seeding', n;
  END IF;
END $$;

-- 2. The two appointees.
INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, is_active, is_incumbent,
        alternate_names, photo_custom_url_manual_override, bio_text_manual_override,
        full_name_manual_override)
SELECT v.ext, v.full_name, v.first_name, v.last_name, true, true, '{}', false, false, false
  FROM (VALUES (-1809301, 'Larry Arnold',   'Larry',  'Arnold'),
               (-1809302, 'Dustin Gabhart', 'Dustin', 'Gabhart')) AS v(ext, full_name, first_name, last_name)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.ext);

-- 3. Seat them. seat_officeholder is idempotent, and closes the predecessor's term for us.
SELECT essentials.seat_officeholder(
         '7d6715f7-c1f3-43df-93c7-b543c633c518',
         (SELECT id FROM essentials.politicians WHERE external_id = -1809301),
         DATE '2026-01-22',
         'Lawrence County GOP caucus 2026-01-22, called to fill the remainder of Jeff Lytton''s '
         'term after his resignation (WBIW 2026-01-08); appointee named on the county roster, '
         'https://lawrencecounty.in.gov/183/County-Council, read 2026-08-31 (CC_0024)',
         p_how_started     => 'appointed',
         p_start_precision => 'day',
         p_how_ended_prev  => 'resigned');

SELECT essentials.seat_officeholder(
         '5dcf1678-1996-448e-8933-39094ebe9326',
         (SELECT id FROM essentials.politicians WHERE external_id = -1809302),
         DATE '2026-01-30',
         'Lawrence County GOP caucus 2026-01-30, called to fill the remainder of Scott Smith''s '
         'term after his death 2025-12-28 (WBIW 2026-01-05); appointee named on the county '
         'roster, https://lawrencecounty.in.gov/183/County-Council, read 2026-08-31 (CC_0024)',
         p_how_started     => 'appointed',
         p_start_precision => 'day',
         p_how_ended_prev  => 'died');

-- 4. Post-verify.
DO $$
DECLARE
  n_wrong  int;
  n_seated int;
  v_end    date;
  v_how    text;
BEGIN
  -- The right person in each seat, read through the view the site reads.
  SELECT count(*) INTO n_wrong
    FROM (VALUES ('7d6715f7-c1f3-43df-93c7-b543c633c518'::uuid, 'Larry Arnold'),
                 ('5dcf1678-1996-448e-8933-39094ebe9326'::uuid, 'Dustin Gabhart')) AS want(office_id, who)
    LEFT JOIN essentials.office_current_holder och ON och.office_id = want.office_id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.full_name IS DISTINCT FROM want.who;
  IF n_wrong <> 0 THEN
    RAISE EXCEPTION '% Lawrence County council seat(s) hold the wrong person', n_wrong;
  END IF;

  -- Lytton must be CLOSED, and closed as a resignation -- not left open beside the new term.
  SELECT t.term_end, t.how_ended INTO v_end, v_how
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.office_id = '7d6715f7-c1f3-43df-93c7-b543c633c518'
     AND p.full_name = 'Jeffrey Lytton';
  IF v_end IS DISTINCT FROM DATE '2026-01-21' OR v_how IS DISTINCT FROM 'resigned' THEN
    RAISE EXCEPTION 'Lytton term did not close as expected (end %, how %)', v_end, v_how;
  END IF;

  -- Whole body: seven seats, every one of them seated. A bare count(*) would pass vacuously over
  -- a vacancy, because the view LEFT JOINs from offices -- so count the politician_id.
  SELECT count(och.politician_id) INTO n_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.title LIKE 'Council - %'
     AND d.state = 'IN' AND d.geo_id LIKE '18093%';
  IF n_seated <> 7 THEN
    RAISE EXCEPTION 'expected 7 seated Lawrence County council members, got %', n_seated;
  END IF;

  RAISE NOTICE 'OK: Lawrence County council fully seated; Arnold D4 from 2026-01-22, Gabhart at-large from 2026-01-30';
END $$;

COMMIT;
