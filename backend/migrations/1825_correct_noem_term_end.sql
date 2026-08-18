-- 1825_correct_noem_term_end.sql
--
-- Correct Kristi Noem's Secretary of Homeland Security term_end from 2026-03-31 to 2026-03-23.
-- Idempotent (guarded on the exact pre-change value; a re-run touches 0 rows).
--
-- CORRECTS: 1824_close_stale_office_terms.sql, which closed this term at 2026-03-31. That file
--   is left as-authored — it records what was actually applied — and this migration is the
--   correction, in the same style as 1092 correcting 1091.
--
-- WHY 2026-03-31 WAS WRONG: it is the date most press coverage gives as Noem's "last day", but
--   that is her formal departure from the department, not the day the OFFICE changed hands.
--   The office is what office_terms models.
--
-- THE ACTUAL SEQUENCE:
--   2026-03-05  Trump announces the firing. Widely reported as the day she "was fired", and it
--               is a real event — but she remained Secretary afterwards.
--   2026-03-09  Sen. Markwayne Mullin formally nominated.
--   2026-03-24  Mullin confirmed and sworn in by AG Pam Bondi. Noem ceases to be Secretary.
--   2026-03-31  Noem's last day at the department; she later becomes Special Envoy for the
--               Shield of the Americas, a different office not modelled here.
--
--   The decisive evidence against both 2026-03-05 and 2026-03-31 is that there was NO ACTING
--   SECRETARY between Noem and Mullin. The official officeholder list runs Noem
--   "January 25, 2025 – March 24, 2026" straight into Mullin "March 24, 2026 – Incumbent". Had
--   she stopped holding the office on the 5th, there would be a 19-day vacancy with a named
--   acting secretary; there is none. Deputy Secretary Troy Edgar never acted in the role.
--
-- WHY 2026-03-23 AND NOT 2026-03-24: term_end is INCLUSIVE in this schema — the
--   office_current_holder view tests term_end >= CURRENT_DATE, and office_terms_no_overlap is an
--   EXCLUDE on daterange(term_start, term_end, '[]'), closed at both ends. Mullin genuinely held
--   the office ON 2026-03-24, so that date belongs to HIS term. Closing Noem at 2026-03-24 would
--   make the two ranges collide on that single day and the EXCLUDE constraint would reject
--   Mullin the moment anyone tried to seat him. 2026-03-23 is her last full day in office and
--   leaves the successor seatable at his true start date with no further edits.
--
-- Sources: en.wikipedia.org/wiki/United_States_Secretary_of_Homeland_Security (officeholder
--   table, no acting secretary between the two); en.wikipedia.org/wiki/Markwayne_Mullin (sworn
--   in 2026-03-24 by AG Bondi; "succeeded Kristi Noem, who was fired ... on March 5, 2026");
--   npr.org/2026/03/24/nx-s1-5757989/markwayne-mullin-confirmed-as-the-next-secretary-of-
--   homeland-security
--
-- NOT USER-VISIBLE: both the old and new dates are in the past, so office_current_holder
--   excluded her before this change and excludes her after. Noem is is_active = false, so the
--   public "who represents me" feed (essentialsService.ts :774/:840) excluded the seat either
--   way. This change exists to make the record correct and to unblock seating Mullin.

BEGIN;

DO $$
DECLARE
  v_term_id uuid;
  v_office_id uuid;
  v_current date;
  n int;
BEGIN
  -- Resolve by external_id (stable; UUIDs are environment-specific).
  SELECT t.id, t.office_id, t.term_end
    INTO v_term_id, v_office_id, v_current
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.external_id = 642537;

  IF v_term_id IS NULL THEN
    RAISE EXCEPTION 'Kristi Noem (external_id 642537) has no office_terms row';
  END IF;

  -- Pre-flight: the office must still hold exactly one term row. If Mullin has been seated in
  -- the meantime, the overlap picture has changed and this edit must be reconsidered by hand.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE office_id = v_office_id;
  IF n <> 1 THEN
    RAISE EXCEPTION 'DHS Secretary office holds % term rows, expected exactly 1 — a successor '
                    'term may already exist; review the overlap before re-dating this row', n;
  END IF;

  -- Pre-flight: only proceed from the exact value 1824 wrote, or from the target value.
  IF v_current NOT IN (DATE '2026-03-31', DATE '2026-03-23') THEN
    RAISE EXCEPTION 'unexpected term_end % on Noem''s row — expected 2026-03-31 (from 1824) '
                    'or 2026-03-23 (already corrected); refusing to overwrite', v_current;
  END IF;

  UPDATE essentials.office_terms
     SET term_end = DATE '2026-03-23',
         source   = source || ' | term_end corrected 2026-03-31 -> 2026-03-23 by migration 1825 '
                    || 'on 2026-08-17 (office transferred when Mullin was sworn in 2026-03-24; '
                    || '2026-03-31 was her departure from the department, not the handover)'
   WHERE id = v_term_id
     AND term_end = DATE '2026-03-31';
END $$;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.external_id = 642537
     AND t.term_end = DATE '2026-03-23'
     AND t.how_ended = 'removed';
  IF n <> 1 THEN
    RAISE EXCEPTION 'Noem term row did not land on 2026-03-23 / removed (matched % rows)', n;
  END IF;

  -- She must still not resolve as a current holder.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.external_id = 642537;
  IF n <> 0 THEN
    RAISE EXCEPTION 'Noem still reports as a current office holder';
  END IF;

  -- The successor's true start date must now be insertable. Proven, not assumed: attempt the
  -- real insert inside a savepoint and roll it back, so a future overlap regression fails HERE.
  BEGIN
    INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, source)
    SELECT t.office_id, NULL, DATE '2026-03-24', NULL, 'overlap probe (migration 1825, rolled back)'
      FROM essentials.office_terms t
      JOIN essentials.politicians p ON p.id = t.politician_id
     WHERE p.external_id = 642537;
    RAISE EXCEPTION 'probe_ok';
  EXCEPTION
    WHEN exclusion_violation THEN
      RAISE EXCEPTION 'a successor term starting 2026-03-24 would still be rejected by '
                      'office_terms_no_overlap — Noem''s term_end is not early enough';
    WHEN raise_exception THEN
      IF SQLERRM <> 'probe_ok' THEN RAISE; END IF;
  END;

  -- The inactive-officeholder diagnostic stays at 2 (Crockett, Fleming).
  SELECT count(*) INTO n
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
   WHERE p.is_active = false AND COALESCE(o.title, '') <> '';
  IF n <> 2 THEN
    RAISE EXCEPTION 'expected 2 inactive-officeholder rows, found %', n;
  END IF;

  RAISE NOTICE 'Noem term_end corrected to 2026-03-23 (removed); still not a current holder; '
               'a successor term starting 2026-03-24 is now insertable; diagnostic still 2.';
END $$;

COMMIT;
