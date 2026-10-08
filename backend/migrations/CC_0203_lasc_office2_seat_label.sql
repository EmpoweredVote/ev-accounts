-- CC_0203 — name one LA Superior Court SEAT after the seat, not after the judge sitting in it
--
-- WHY. The district behind Draper's office is labelled "LA County Superior Court - Robert S. Draper".
-- A district is a SEAT. Naming it after its occupant conflates the two things ADR 0002 exists to
-- separate, and it goes visibly wrong at a handover: from 2027-01-05 the page would read
-- "Tal K. Valbuena — LA County Superior Court - Robert S. Draper".
--
-- Found while preparing the Draper → Valbuena handover (CC_0201 / CC_0202).
--
-- THE SEAT'S REAL NAME IS IN OUR OWN DATA. The race for it is `LA Superior Court Office 2`
-- (essentials.races 8959c575-8b29-49eb-b109-97c17fd32f88), whose two race_candidates rows are
-- exactly Valbuena (result `won`) and Draper (is_incumbent, result `lost`). So this seat is
-- Office No. 2, and that label is true whoever holds it.
--
-- ⚠ THIS IS ONE OF 425. Measured 2026-10-08: 425 districts are labelled
-- "LA County Superior Court - <name>", and 365 of them still match their current holder's name
-- exactly — the naming came in with CA_0183, which seated 421 judges from the court's roster. Every
-- one of them has the same defect and the same failure mode at its next handover. This migration
-- fixes ONLY the seat that is about to turn over; the other 424 are recorded as backlog in
-- .planning/todos/2026-10-07-la-headshot-replenish.md rather than renamed blind, because most of
-- them have no office number in our data yet and a guessed number is worse than a stale name.
--
-- Safe at any date: this renames a seat, it does not touch occupancy.
--
-- Rollback:
--   UPDATE essentials.districts SET label = 'LA County Superior Court - Robert S. Draper'
--    WHERE id = '2354abf7-6dc2-45c1-918f-622241ba7b42';

BEGIN;

UPDATE essentials.districts
   SET label = 'LA County Superior Court - Office 2'
 WHERE id = '2354abf7-6dc2-45c1-918f-622241ba7b42'
   AND district_type = 'JUDICIAL'
   AND label IS DISTINCT FROM 'LA County Superior Court - Office 2';

DO $$
DECLARE
  v_label    text;
  v_office   uuid := '83969e0c-c530-4649-bf82-68e25eca0c85';
  v_holder   uuid;
  v_race     text;
  v_still    int;
BEGIN
  SELECT d.label INTO v_label
    FROM essentials.districts d WHERE d.id = '2354abf7-6dc2-45c1-918f-622241ba7b42';
  IF v_label IS DISTINCT FROM 'LA County Superior Court - Office 2' THEN
    RAISE EXCEPTION 'CC_0203: label is %, expected "LA County Superior Court - Office 2"',
      coalesce(v_label, '<null>');
  END IF;

  -- The office number is not invented: it is the name of the race these two contested.
  SELECT r.position_name INTO v_race
    FROM essentials.races r WHERE r.id = '8959c575-8b29-49eb-b109-97c17fd32f88';
  IF v_race IS DISTINCT FROM 'LA Superior Court Office 2' THEN
    RAISE EXCEPTION 'CC_0203: race 8959c575 is now named %, which no longer supports this label',
      coalesce(v_race, '<missing>');
  END IF;

  -- Renaming a seat must not move anybody into or out of it.
  SELECT politician_id INTO v_holder
    FROM essentials.office_current_holder WHERE office_id = v_office;
  IF v_holder IS DISTINCT FROM 'fa932212-a2cf-4fa1-97ab-c6619e3db610'::uuid THEN
    RAISE EXCEPTION 'CC_0203: the holder of % is now %, expected Draper — a rename must not change occupancy',
      v_office, coalesce(v_holder::text, '<vacant>');
  END IF;

  -- Report the size of what is NOT fixed here, so the number in the backlog stays honest.
  SELECT count(*) INTO v_still
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.district_type = 'JUDICIAL'
     AND d.label = 'LA County Superior Court - ' || p.full_name;

  RAISE NOTICE 'CC_0203: seat renamed to Office 2. % LA Superior Court seats are STILL named after '
               'their current holder — backlog, not drift.', v_still;
END $$;

COMMIT;
