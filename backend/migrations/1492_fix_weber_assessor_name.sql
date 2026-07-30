-- 1492 — Weber County Assessor: correct a wrong occupant name
--
-- WHAT WAS WRONG
-- essentials.politicians held "Jared Preisler" as Weber County Assessor. The actual
-- assessor is JOHN E. ULIBARRI, who won the office outright in the 2024 general
-- election with 83,977 votes:
--   https://electionresults.utah.gov/results/public/api/elections/weber-county-ut/general11052024/data
--   ballotItems -> "COUNTY ASSESSOR" -> "REP JOHN E. ULIBARRI"
-- We were therefore publicly asserting that a named person holds a county office he
-- does not hold. That is the reason this is a migration and not a backlog note.
--
-- WHY A RENAME IS THE RIGHT FIX (and not a retire + reseat)
-- external_id -393635 sits in the UT county-roster band, and that loader derives
-- external_id from a hash of (county, ROLE) — not from the person. See
-- data/rosters/manual/_audit_notes.md -> "Scaffold Provenance": "a real name added on
-- day 1 keeps the same external_id as the same role re-filled on day 30." The row is a
-- role SLOT whose name was filled incorrectly, so correcting the name is the designed
-- path. Verified before writing this: the row carries 0 politician_images, 0
-- inform.politician_answers, 0 inform.politician_context, no photo_origin_url /
-- photo_custom_url, and a NULL last_stances_researched_at — so no headshot, stance or
-- research artifact was attributed to the wrong person and nothing else needs retiring.
--
-- occupancy (office_terms) is deliberately NOT touched. Ulibarri has held this seat
-- across the period in question, so the seat's single open-ended term is already
-- correct; only the name was wrong. term_start stays NULL (unknown precision, from the
-- ADR-0002 phase-2 backfill) rather than inventing the first-Monday-in-January date.
--
-- Name spelling is taken from the official ballot ("JOHN E. ULIBARRI"). Some secondary
-- rosters render it "John E. Ulibarri, II"; the suffix is not asserted here because the
-- official contest record does not carry it.
--
-- Found by the 2026-07-29 UT county seat audit (migrations/commits: see
-- data/coverage/README.md -> "The 7-officer template"). Idempotent.

BEGIN;

UPDATE essentials.politicians
   SET full_name = 'John E. Ulibarri'
 WHERE id = 'a45f2a74-38b5-4178-b379-af98b8c3af74'
   AND full_name = 'Jared Preisler';

-- ── post-verify gate ────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_name  text;
  v_count int;
  v_stray int;
BEGIN
  -- exactly one active holder of the Weber Assessor seat, and it must be Ulibarri
  SELECT count(*), min(p.full_name)
    INTO v_count, v_name
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices   o ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE p.is_active = true
     AND d.ocd_id = 'ocd-division/country:us/state:ut/county:weber'
     AND o.title ILIKE '%assessor%';

  IF v_count <> 1 THEN
    RAISE EXCEPTION '1492: expected exactly 1 active Weber Assessor holder, found %', v_count;
  END IF;

  IF v_name <> 'John E. Ulibarri' THEN
    RAISE EXCEPTION '1492: Weber Assessor is "%", expected "John E. Ulibarri"', v_name;
  END IF;

  -- the wrong name must not survive anywhere
  SELECT count(*) INTO v_stray
    FROM essentials.politicians WHERE full_name ILIKE '%preisler%';

  IF v_stray <> 0 THEN
    RAISE EXCEPTION '1492: % politician row(s) still named Preisler', v_stray;
  END IF;

  RAISE NOTICE '1492 OK — Weber Assessor = John E. Ulibarri (1 active holder, 0 stray rows)';
END $$;

COMMIT;
