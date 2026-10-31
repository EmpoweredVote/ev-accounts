-- CC_0300: seat Brenda Gonzalez Pacheco on the Cornelius, Oregon council seat that has been
-- flagged vacant since before anyone measured it.
--
-- WHAT THIS CLOSES. `CC_0298` triaged the 41 flagged-and-undated offices and found exactly one
-- that was "not vacant — a holder exists": the City of Cornelius lists FOUR councillors on its own
-- roster and this database held THREE. The fourth seat sat flagged `is_vacant` with no date and no
-- term, so address search returned an empty chair to a voter who in fact has a councillor.
-- Seating a person is a different act from dating a vacancy, so it was deliberately left out of
-- `CC_0298`. This is it.
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- THE SOURCES, AND WHAT EACH ONE IS GOOD FOR
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- 🔴 CLAUDE.md: "A SOURCE CAN BE AUTHORITATIVE FOR ONE FIELD AND STALE FOR ANOTHER." These are
-- split deliberately — one source for WHO, a different one for WHEN, and a third used only as a
-- control.
--
-- WHO HOLDS THE SEAT — the city's own council roster, read 2026-10-26:
--   https://www.corneliusor.gov/267/City-Council
--   Members: Jeffrey C. Dalin (Mayor) · Angeles Godinez Valencia (Council President) ·
--   Edgar Baker (Councilor) · Edén López (Councilor) · BRENDA GONZALEZ PACHECO (Councilor).
--   Three of those four councillors are already seated here. She is the missing one.
--
-- WHEN SHE TOOK OFFICE — the city's agenda for its own meeting, a primary record:
--   https://www.corneliusor.gov/AgendaCenter/ViewFile/Item/370?fileID=1744
--   "CITY COUNCIL MEETING AGENDA — Tuesday, September 8, 2026", item 4:
--       "4. OATH OF OFFICE
--          A. City Councilor Brenda Gonzalez Pacheco
--             Staff: Rachael Bateman, City Recorder"
--   Corroborated by her own directory page, which states the appointment independently:
--   https://www.corneliusor.gov/m/directory/employee?eid=37  ->  "Appointed: September 2026 to
--   December 2028". September 2026 had exactly one council meeting, the 8th.
--
-- 🟢 THE CONTROL — AN AGENDA IS A PLAN, NOT A RECORD, SO THE DATE WAS CHECKED AGAINST THE NEXT
-- MEETING. Minutes are only published through 2026-06-01, so the oath cannot be confirmed from
-- minutes. Instead: the NEXT council agenda, Monday 2026-10-05, has NO oath-of-office item at all
-- (https://www.corneliusor.gov/AgendaCenter/ViewFile/Item/375?fileID=1765). A scheduled oath that
-- had slipped would appear there. It does not, and she is on the roster today, so the 8 September
-- oath happened. That is why `start_precision` is 'day' and not 'month'.
--
-- ⚠ Residual uncertainty, stated rather than hidden: the oath is evidenced by a scheduling record
-- plus the absence of a re-scheduling, not by minutes. If Cornelius publishes its September 2026
-- minutes later and they disagree, this term's `term_start` is the thing to correct.
--
-- ⚠ Her appointment runs "to December 2028". That is NOT written as `term_end`: this repo keeps
-- current holders open-ended (10,258 open-ended terms against 38 with a future end date), and a
-- future `term_end` that turns out wrong silently drops a sitting official out of "current".
-- The scheduled expiry is recorded in the term's `source` text instead.
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- WHY THE OFFICE ALSO HAS TO BE UNFLAGGED BY HAND
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- 🔴 `essentials.seat_officeholder` DOES NOT CLEAR `is_vacant`. Read its body: it closes the
-- predecessor's term and inserts the new one, and never touches `essentials.offices`. Its mirror
-- `vacate_office` DOES sync the flag, which makes the asymmetry easy to assume away. Seating
-- someone and leaving the flag set would publish a seat that is both held and vacant — the exact
-- `is_vacant` trap CLAUDE.md describes, which emits a spurious all-NULL office row for the holder.
-- So this migration clears `is_vacant` and `vacant_since` explicitly, and the post-verify asserts
-- the office is held AND unflagged.
--
-- EXPECTED MOVEMENT, measured 2026-10-27 before running:
--   essentials.offices  is_vacant            65 -> 64   (one declared vacancy was never real)
--                       flagged and undated  25 -> 24
--   offices_missing_terms  total / flagged / unflagged
--                       295 / 57 / 238  ->  294 / 56 / 238
--   🟢 The unflagged BASELINE does not move. This office was in the FLAGGED bucket, so seating it
--   lowers the total and the flagged count and leaves the 238 drift baseline alone. CLAUDE.md:
--   lower these whenever a change shrinks them.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 1. Pre-flight.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; v_title text; v_vac boolean; v_since date; v_govt text;
BEGIN
  -- The seat, by id, with the identity it must have. A transposed uuid would otherwise seat her
  -- on somebody else's empty chair and every count below would still look right.
  SELECT o.title, o.is_vacant, o.vacant_since, g.name
    INTO v_title, v_vac, v_since, v_govt
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.id = 'fc77b67f-aabd-47a1-8f68-49d6edeab5e8';
  IF v_title IS NULL THEN
    RAISE EXCEPTION 'PRE-FLIGHT: target office does not exist';
  END IF;
  IF (v_govt, v_title, v_vac, v_since)
       IS DISTINCT FROM ('City of Cornelius, Oregon, US', 'Councilor', true, NULL::date) THEN
    RAISE EXCEPTION 'PRE-FLIGHT: target office is % / % / is_vacant=% / vacant_since=%, expected '
                    'City of Cornelius, Oregon, US / Councilor / true / NULL',
                    v_govt, v_title, v_vac, v_since;
  END IF;

  -- Never held by anyone. If a term appeared, somebody else seated this seat and the right move
  -- is to read their work, not to stack a second term on top of it.
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE office_id = 'fc77b67f-aabd-47a1-8f68-49d6edeab5e8';
  IF n <> 0 THEN
    RAISE EXCEPTION 'PRE-FLIGHT: target office already has % term row(s)', n;
  END IF;

  -- The council is 4 councillors + a mayor, and exactly 3 councillors are seated. This is the
  -- claim that makes "she is the missing fourth" true rather than a guess.
  SELECT count(*) INTO n
    FROM essentials.governments g
    JOIN essentials.chambers c ON c.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = c.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Cornelius, Oregon, US'
     AND o.title = 'Councilor'
     AND och.politician_id IS NOT NULL;
  IF n <> 3 THEN
    RAISE EXCEPTION 'PRE-FLIGHT: expected exactly 3 seated Cornelius councillors, found % — the '
                    'roster moved, re-read https://www.corneliusor.gov/267/City-Council', n;
  END IF;

  -- 🔴 THE DUPLICATE-PERSON SWEEP, DONE THE WAY THE GUARD CANNOT. The repo's guard keys on
  -- (first_name, last_name), so an identical full_name split differently is invisible to it, as
  -- are archived rows. Match on the whole name and on either half, active or not.
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE full_name ILIKE '%gonzalez pacheco%'
      OR (first_name ILIKE 'brenda%' AND (last_name ILIKE '%pacheco%' OR last_name ILIKE '%gonzalez%'));
  IF n <> 0 THEN
    RAISE EXCEPTION 'PRE-FLIGHT: % existing politician row(s) may already be this person — read '
                    'them before inserting a second (ONE ROW PER PERSON)', n;
  END IF;

  -- external_id is UNIQUE and a collision seats the wrong person silently. Cornelius uses a
  -- negative block derived from its place geo_id 4115550: the mayor is -4115551 and the three
  -- councillors are -4115552..-4115554, so -4115555 is the next in the block.
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -4115555) THEN
    RAISE EXCEPTION 'PRE-FLIGHT: external_id -4115555 is taken';
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 2. Snapshot, in this transaction, for a delta gate.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.offices WHERE is_vacant)                            AS vac_total,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NULL)   AS undated,
       (SELECT count(*) FROM essentials.office_terms)                                       AS terms_total,
       (SELECT count(*) FROM essentials.politicians)                                        AS people_total,
       (SELECT count(*) FROM essentials.offices_missing_terms)                              AS omt_total,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o ON o.id = m.office_id WHERE o.is_vacant)                AS omt_flagged,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant)            AS omt_unflagged,
       -- did_run keeps the delta gate honest on a re-run: once she is seated the expected
       -- movement is zero, not one.
       NOT EXISTS (SELECT 1 FROM essentials.office_terms
                    WHERE office_id = 'fc77b67f-aabd-47a1-8f68-49d6edeab5e8')               AS did_run;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 3. The person.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 `is_incumbent` IS NAMED EXPLICITLY. It defaults to false since CA_0188, and a seated person
-- inserted without it is HIDDEN from address search. check:occupancy fails an INSERT that omits it.
-- Name shape follows her seated colleague Angeles Godinez Valencia: the compound Spanish surname
-- is kept whole in last_name rather than split.
-- No photo: none has been sourced, and a blank beats a wrong or unlicensed link.
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, source)
VALUES
  (-4115555, 'Brenda Gonzalez Pacheco', 'Brenda', 'Gonzalez Pacheco', true, true,
   'CC_0300: City of Cornelius OR council roster (corneliusor.gov/267/City-Council) + oath of '
   || 'office on the city''s 2026-09-08 council agenda')
ON CONFLICT (external_id) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 4. The term, through the house helper.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
SELECT essentials.seat_officeholder(
         'fc77b67f-aabd-47a1-8f68-49d6edeab5e8',
         (SELECT id FROM essentials.politicians WHERE external_id = -4115555),
         DATE '2026-09-08',
         'City of Cornelius council agenda, Tuesday 2026-09-08, item 4 "OATH OF OFFICE: A. City '
         || 'Councilor Brenda Gonzalez Pacheco" '
         || '(corneliusor.gov/AgendaCenter/ViewFile/Item/370?fileID=1744). Appointed to fill a '
         || 'vacancy; her city directory entry gives the appointment as September 2026 to '
         || 'December 2028. The scheduled 2028 expiry is NOT written as term_end — see CC_0300.',
         'appointed',   -- how_started: she was appointed to a vacancy, not elected to it
         'day');        -- start_precision: the agenda names the day; see the control in the header

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 5. Clear the flag. seat_officeholder does not, and a held-and-vacant office is the is_vacant trap.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.offices
   SET is_vacant = false, vacant_since = NULL
 WHERE id = 'fc77b67f-aabd-47a1-8f68-49d6edeab5e8';

-- Keep the deprecated point-in-time snapshot consistent with her three colleagues, all of whom
-- carry it. ADR 0002 says do not READ this column in new code; leaving hers NULL when every peer
-- row is populated would be a difference nobody intended.
UPDATE essentials.politicians
   SET office_id = 'fc77b67f-aabd-47a1-8f68-49d6edeab5e8'
 WHERE external_id = -4115555;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 6. Post-verify.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE b record; n int; v record;
BEGIN
  SELECT * INTO b FROM _before;

  -- (a) She holds the seat, through the view the read path uses.
  SELECT p.full_name, p.is_active, p.is_incumbent, t.term_start, t.start_precision, t.how_started,
         t.term_end
    INTO v
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
    JOIN essentials.office_terms t ON t.office_id = och.office_id AND t.politician_id = p.id
   WHERE och.office_id = 'fc77b67f-aabd-47a1-8f68-49d6edeab5e8';
  IF v IS NULL THEN
    RAISE EXCEPTION 'POST-VERIFY: office_current_holder returns nobody for the Cornelius seat';
  END IF;
  IF (v.full_name, v.is_active, v.is_incumbent, v.term_start, v.start_precision, v.how_started,
      v.term_end)
       IS DISTINCT FROM ('Brenda Gonzalez Pacheco', true, true, DATE '2026-09-08', 'day',
                         'appointed', NULL::date) THEN
    RAISE EXCEPTION 'POST-VERIFY: holder row is % / active=% / incumbent=% / start=% / precision=% '
                    '/ how_started=% / term_end=%',
                    v.full_name, v.is_active, v.is_incumbent, v.term_start, v.start_precision,
                    v.how_started, v.term_end;
  END IF;

  -- (b) 🔴 HELD AND UNFLAGGED. seat_officeholder does not clear is_vacant; if step 5 is ever
  --     dropped this is the assertion that catches it.
  IF EXISTS (SELECT 1 FROM essentials.offices
              WHERE id = 'fc77b67f-aabd-47a1-8f68-49d6edeab5e8'
                AND (is_vacant OR vacant_since IS NOT NULL)) THEN
    RAISE EXCEPTION 'POST-VERIFY: the seat is held and still flagged vacant — the is_vacant trap';
  END IF;

  -- (c) Exactly one term on the seat, and exactly one row for her repo-wide.
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE office_id = 'fc77b67f-aabd-47a1-8f68-49d6edeab5e8';
  IF n <> 1 THEN RAISE EXCEPTION 'POST-VERIFY: % term rows on the seat, expected 1', n; END IF;

  SELECT count(*) INTO n FROM essentials.politicians
   WHERE full_name ILIKE '%gonzalez pacheco%'
      OR (first_name ILIKE 'brenda%' AND (last_name ILIKE '%pacheco%' OR last_name ILIKE '%gonzalez%'));
  IF n <> 1 THEN
    RAISE EXCEPTION 'POST-VERIFY: % rows match this person, expected exactly 1 (ONE ROW PER PERSON)', n;
  END IF;

  -- (d) The council is now four councillors, which is what the city publishes.
  SELECT count(*) INTO n
    FROM essentials.governments g
    JOIN essentials.chambers c ON c.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = c.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Cornelius, Oregon, US' AND o.title = 'Councilor'
     AND och.politician_id IS NOT NULL;
  IF n <> 4 THEN
    RAISE EXCEPTION 'POST-VERIFY: % seated Cornelius councillors, expected 4', n;
  END IF;

  -- (e) The deltas, captured in this transaction. One vacancy withdrawn, one term, one person.
  IF (b.vac_total - (SELECT count(*) FROM essentials.offices WHERE is_vacant))
       IS DISTINCT FROM (CASE WHEN b.did_run THEN 1 ELSE 0 END) THEN
    RAISE EXCEPTION 'POST-VERIFY: flagged-vacant total fell by %, expected %',
      b.vac_total - (SELECT count(*) FROM essentials.offices WHERE is_vacant),
      CASE WHEN b.did_run THEN 1 ELSE 0 END;
  END IF;
  IF ((SELECT count(*) FROM essentials.office_terms) - b.terms_total)
       IS DISTINCT FROM (CASE WHEN b.did_run THEN 1 ELSE 0 END) THEN
    RAISE EXCEPTION 'POST-VERIFY: office_terms rose by %, expected %',
      (SELECT count(*) FROM essentials.office_terms) - b.terms_total,
      CASE WHEN b.did_run THEN 1 ELSE 0 END;
  END IF;
  IF ((SELECT count(*) FROM essentials.politicians) - b.people_total)
       IS DISTINCT FROM (CASE WHEN b.did_run THEN 1 ELSE 0 END) THEN
    RAISE EXCEPTION 'POST-VERIFY: politicians rose by %, expected % — this migration adds ONE person',
      (SELECT count(*) FROM essentials.politicians) - b.people_total,
      CASE WHEN b.did_run THEN 1 ELSE 0 END;
  END IF;

  -- (f) 🔴 THE OCCUPANCY METRIC MOVES THE ONE HONEST WAY. The seat was in the FLAGGED bucket, so
  --     total and flagged each fall by one and the 238 unflagged DRIFT BASELINE does not move.
  --     Raising that baseline here would mean something else changed.
  IF ((b.omt_total - (SELECT count(*) FROM essentials.offices_missing_terms)),
      (b.omt_flagged - (SELECT count(*) FROM essentials.offices_missing_terms m
                          JOIN essentials.offices o ON o.id = m.office_id WHERE o.is_vacant)),
      ((SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant) - b.omt_unflagged))
     IS DISTINCT FROM (CASE WHEN b.did_run THEN 1 ELSE 0 END,
                       CASE WHEN b.did_run THEN 1 ELSE 0 END,
                       0) THEN
    RAISE EXCEPTION 'POST-VERIFY: offices_missing_terms moved wrongly from % / % / %',
      b.omt_total, b.omt_flagged, b.omt_unflagged;
  END IF;

  RAISE NOTICE 'CC_0300 OK: Cornelius councillor seated 2026-09-08; flagged-vacant % -> %; '
               'offices_missing_terms % / % / % -> % / % / %',
    b.vac_total, (SELECT count(*) FROM essentials.offices WHERE is_vacant),
    b.omt_total, b.omt_flagged, b.omt_unflagged,
    (SELECT count(*) FROM essentials.offices_missing_terms),
    (SELECT count(*) FROM essentials.offices_missing_terms m
       JOIN essentials.offices o ON o.id = m.office_id WHERE o.is_vacant),
    (SELECT count(*) FROM essentials.offices_missing_terms m
       JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant);
END $$;

COMMIT;
