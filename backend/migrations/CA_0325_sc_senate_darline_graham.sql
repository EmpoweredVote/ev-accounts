BEGIN;

-- =============================================================================
-- CA_0325: South Carolina's Class II U.S. Senate seat — Darline Graham, not Lindsey Graham (#1089)
-- =============================================================================
-- Found by the ev-qa federal check (2026-10-21, still failing 2026-10-26): senate.gov lists Darline
-- Graham for SC; we still seated Lindsey Graham, so browse/federal/officials and the SC address search
-- both showed him.
--
-- Facts and sources (read 2026-10-26):
--   * senate.gov, "Senators Who Died in Office" (senate.gov/senators/SenatorsDiedinOffice.htm):
--     "Graham, Lindsey (SC) 119/2 07/11/2026". His last day is 2026-07-11.
--   * senate.gov, "Appointed Senators (1913-Present)" (senate.gov/senators/AppointedSenators.htm):
--     "Darline Graham (R-SC)", appointed Jul 13, 2026, took oath Jul 14, 2026.
--   * Office of the Governor, 2026-07-13 (governor.sc.gov/news/2026-07/gov-mcmaster-appoints-darline-
--     graham-us-senate): she serves "until January 3, 2027", when the new Congress convenes.
--   * senate.gov member roster (senators_cfm.xml): Darline Graham, SC, Class II, bioguide G000608,
--     https://www.dgraham.senate.gov/. congress-legislators agrees (term 2026-07-14..2027-01-03,
--     how 'appointment'; Lindsey Graham G000359 ends 2026-07-11). api.congress.gov: G000359
--     currentMember false, deathYear 2026; G000608 currentMember true.
--
-- How the wrong row got its data: migration 1653 backfilled every senator from senators_cfm.xml
-- (fetched 2026-08-09) joined on last name + state. On that date the XML's SC "Graham" was already
-- Darline, so Lindsey's row received her bioguide_id (G000608), website and contact form. That is why
-- the API showed Lindsey Graham with dgraham.senate.gov. Step 1 undoes it.
--
-- Writes:
--   1. Lindsey Graham's row: bioguide_id back to his own (G000359); clear the dgraham.senate.gov
--      website and contact form (his own Senate site closed with his office). is_incumbent -> false.
--      is_active is left alone (2026-09-24 ruling: is_active is not an occupancy fact). His compass
--      answers, finance summary and photo are his and are untouched.
--   2. Close his term (backfill row 7097192d, start unknown) on 2026-07-11, how_ended 'died'.
--   3. Insert Darline Graham (is_incumbent true, is_appointed true, appointment_date 2026-07-13).
--      No party, by design. No photo: there is no unitedstates.github.io image for G000608 yet.
--   4. seat_officeholder(Class II seat, Darline, 2026-07-14, 'appointed'), then end that term on
--      2027-01-03 — the appointment ends there, whoever wins in November.
--   The seat was empty 2026-07-12..2026-07-13. That gap is left unwritten, not stored as a span.
--
-- ⚠ The seat is also on the 2026-11-03 ballot (race 29b5764f, 'U.S. Senate South Carolina'). That race
-- still lists Lindsey Graham as an active candidate; the SC Republican Party chose his replacement
-- nominee in a special primary (2026-08-11, runoff 2026-08-25). Updating that roster is NOT done here.
-- And from 2027-01-04 this seat has no holder until the winner is seated: offices_missing_terms will
-- show it, which is correct.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms WHERE id = '7097192d-8638-4b36-951e-cc498f05e65c'
                   AND office_id = 'af90499c-0219-4a7a-bd89-fb9ac20392ae'
                   AND politician_id = '20aa1064-bbe7-484c-b779-28d99e92e608') THEN
    RAISE EXCEPTION 'CA_0325: pre-flight — Lindsey Graham''s SC Class II term 7097192d is not where expected';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.office_terms WHERE office_id = 'af90499c-0219-4a7a-bd89-fb9ac20392ae'
               AND id <> '7097192d-8638-4b36-951e-cc498f05e65c'
               AND politician_id IS DISTINCT FROM 'a82fec1e-3b94-4f7f-8931-fafb9787def3') THEN
    RAISE EXCEPTION 'CA_0325: pre-flight — the SC Class II seat has another term; reconcile first';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE bioguide_id = 'G000608'
               AND id NOT IN ('20aa1064-bbe7-484c-b779-28d99e92e608', 'a82fec1e-3b94-4f7f-8931-fafb9787def3')) THEN
    RAISE EXCEPTION 'CA_0325: pre-flight — another row already carries bioguide G000608';
  END IF;
END $$;

-- 1. Undo 1653's write onto Lindsey Graham's row (only while it still carries Darline's data).
UPDATE essentials.politicians
   SET bioguide_id = 'G000359', urls = NULL, web_form_url = NULL
 WHERE id = '20aa1064-bbe7-484c-b779-28d99e92e608' AND bioguide_id = 'G000608';
UPDATE essentials.politicians SET is_incumbent = false
 WHERE id = '20aa1064-bbe7-484c-b779-28d99e92e608' AND is_incumbent;

-- 2. Close his term on the day he died.
UPDATE essentials.office_terms
   SET term_end = DATE '2026-07-11', how_ended = 'died',
       source = source || ' | term_end 2026-07-11, died in office (senate.gov/senators/SenatorsDiedinOffice.htm) (CA_0325)'
 WHERE id = '7097192d-8638-4b36-951e-cc498f05e65c' AND term_end IS NULL;

-- 3. Darline Graham.
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, alternate_names, bioguide_id, urls, web_form_url,
   is_appointed, appointment_date, is_active, is_incumbent, office_id, valid_to)
SELECT 'a82fec1e-3b94-4f7f-8931-fafb9787def3', 'Darline Graham', 'Darline', 'Graham', '{Darline Graham Nordone}',
       'G000608', '{https://www.dgraham.senate.gov/}', 'https://www.dgraham.senate.gov/',
       true, DATE '2026-07-13', true, true, 'af90499c-0219-4a7a-bd89-fb9ac20392ae', '2027-01-03'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = 'a82fec1e-3b94-4f7f-8931-fafb9787def3');

-- 4. Seat her from her oath, and end the appointment when the new Congress convenes.
SELECT essentials.seat_officeholder('af90499c-0219-4a7a-bd89-fb9ac20392ae'::uuid, 'a82fec1e-3b94-4f7f-8931-fafb9787def3'::uuid,
  DATE '2026-07-14',
  'senate.gov Appointed Senators: Darline Graham (R-SC) appointed 2026-07-13, oath 2026-07-14; Governor''s release 2026-07-13: serves until 2027-01-03; senators_cfm.xml lists her for SC Class II, bioguide G000608 (CA_0325)',
  'appointed', 'day');
UPDATE essentials.office_terms SET term_end = DATE '2027-01-03'
 WHERE office_id = 'af90499c-0219-4a7a-bd89-fb9ac20392ae' AND politician_id = 'a82fec1e-3b94-4f7f-8931-fafb9787def3'
   AND term_start = DATE '2026-07-14' AND term_end IS NULL;

DO $$
DECLARE v int;
BEGIN
  -- Lindsey Graham: term closed 2026-07-11, own bioguide, no Senate site, not an incumbent, no current seat.
  SELECT count(*) INTO v FROM essentials.office_terms
   WHERE id = '7097192d-8638-4b36-951e-cc498f05e65c' AND term_end = DATE '2026-07-11' AND how_ended = 'died';
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0325: Lindsey Graham''s term not closed as expected'; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = '20aa1064-bbe7-484c-b779-28d99e92e608'
                   AND bioguide_id = 'G000359' AND urls IS NULL AND web_form_url IS NULL AND NOT is_incumbent) THEN
    RAISE EXCEPTION 'CA_0325: Lindsey Graham''s row not repaired';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.office_current_holder WHERE politician_id = '20aa1064-bbe7-484c-b779-28d99e92e608') THEN
    RAISE EXCEPTION 'CA_0325: Lindsey Graham still holds a current seat';
  END IF;
  -- Darline Graham: the one current holder of the seat, appointed 2026-07-14..2027-01-03, one seat only.
  SELECT count(*) INTO v FROM essentials.office_current_holder
   WHERE office_id = 'af90499c-0219-4a7a-bd89-fb9ac20392ae' AND politician_id = 'a82fec1e-3b94-4f7f-8931-fafb9787def3'
     AND term_start = DATE '2026-07-14' AND term_end = DATE '2027-01-03' AND how_started = 'appointed';
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0325: Darline Graham is not the current SC Class II holder (found %)', v; END IF;
  SELECT count(*) INTO v FROM essentials.office_current_holder WHERE politician_id = 'a82fec1e-3b94-4f7f-8931-fafb9787def3';
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0325: Darline Graham holds % current seats, expected 1', v; END IF;
  SELECT count(*) INTO v FROM essentials.politicians WHERE bioguide_id = 'G000608';
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0325: % rows carry bioguide G000608, expected 1', v; END IF;
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE id = 'a82fec1e-3b94-4f7f-8931-fafb9787def3'
               AND (party IS NOT NULL OR NOT is_incumbent OR NOT is_active)) THEN
    RAISE EXCEPTION 'CA_0325: Darline Graham row flags wrong';
  END IF;
  -- The seat is not flagged vacant.
  IF EXISTS (SELECT 1 FROM essentials.offices WHERE id = 'af90499c-0219-4a7a-bd89-fb9ac20392ae' AND is_vacant) THEN
    RAISE EXCEPTION 'CA_0325: SC Class II seat flagged vacant';
  END IF;
  -- Tim Scott's Class III seat is untouched.
  SELECT count(*) INTO v FROM essentials.office_current_holder
   WHERE office_id = '760834c6-ee5c-4328-a71a-900669657ba4' AND politician_id = '675778b0-7e6f-45ef-96b2-7bcb5d7e0af7';
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0325: Tim Scott is no longer the Class III holder'; END IF;
END $$;

COMMIT;
