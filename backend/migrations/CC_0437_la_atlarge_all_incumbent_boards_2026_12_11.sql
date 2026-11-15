-- CC_0437 — the six at-large school boards where every filer already sits.
--
-- `CC_0434` seated 85 LA County school board members appointed in lieu of election and refused
-- 29 candidacies across TEN at-large boards, because an at-large board is five office rows all
-- titled `Board Member`, all seated, with the race pointing at ONE of them and carrying
-- `seats = 3`. Three people cannot enter one office, and nothing in the title says which three
-- of the five seats are up.
--
-- 🟢 FOR SIX OF THOSE TEN THE QUESTION DOES NOT ARISE, AND THAT IS THE WHOLE ARGUMENT OF THIS
-- FILE. Every filer on these six boards ALREADY SITS on it, so each returns to the seat they
-- already hold. No seat is chosen, so no claim is made about who replaced whom:
--
--   El Monte City School Board             3 of 3 seats
--   El Rancho Unified School Board         3 of 3 seats
--   El Segundo Unified School Board        3 of 3 seats
--   Rosemead School Board                  3 of 3 seats
--   Walnut Valley Unified School Board     3 of 3 seats
--   West Covina Unified School Board       2 of 2 seats
--
-- 🔴 THE OTHER FOUR ARE STILL REFUSED, AND DELIBERATELY: Hawthorne (2 of 3 filers sit), Hermosa
-- Beach City (1 of 3), Manhattan Beach (2 of 3) and San Marino (2 of 3). Placing a NEWCOMER into
-- one of five indistinguishable seats is an assertion about which member they succeeded, and
-- nothing in the record supports one choice over another. Those wait for each board's own
-- organisational minutes.
--
-- 🔴🔴 AND THE RULE THAT LOOKS RIGHT IS WRONG — "SEAT THE MEMBERS WITH THE OLDEST `term_start`".
-- Five of these six split cleanly, filers on 2022-12-01 and non-filers on 2024-12-01. **El Monte
-- City does not.** Cesar Peralta carries 2024-12-01, the SAME DATE as Jennifer Cobian and David
-- Siegrist, who are not up — because his is an unexpired term. His own term source records it:
-- LA County RR/CC candidate list 4324, "Unexpired term ending December 11, 2026". ▶ The date does
-- not discriminate; the SOURCE does. Nothing in this file reads the date, which is exactly why
-- it is safe — the mapping is "the seat this person already holds", not "the seat that looks due".
--
-- ── WHY THEY ARE SEATED WITHOUT A RESULT ────────────────────────────────────────────────────
-- Identical to CC_0434: these elections were CANCELLED under Elec. Code 10515 and Educ. Code 5328
-- seats those who filed as if elected, so there is no vote to wait for. All six boards appear on
-- LA County RR/CC's FINAL LIST OF CANCELED ELECTIONS, revised 8/25/2026.
--
-- ⚠ Terms start 2026-12-11 and are written in advance at day precision, so the view flips by
-- itself on the day (the Reno pattern, CC_0387). It flips at UTC midnight = 16:00 Pacific on 12-10.
--
-- 🔴 AND THE `is_vacant` MISTAKE OF CC_0434 IS NOT REPEATED. That file cleared the flag on every
-- office it touched, which was wrong for six seats whose only term was in the future; they were
-- empty today and `check:reachability` fired a new DEAD_GEOGRAPHY bucket (CC_0436 restored them).
-- Here EVERY office is currently held by the very person being re-seated, so none is flagged and
-- none needs clearing. This file touches `essentials.offices` not at all, and asserts that.
--
-- @incumbency-decision: gated — this inserts an `essentials.office_terms` row per seat and
-- `seat_officeholder` closes each predecessor, so it writes dates on both sides of 17 seatings.
-- ⚠ Here the predecessor and the successor are the SAME PERSON on every row.
--
-- Dry run: node backend/scripts/dry-run-migration.mjs backend/migrations/CC_0437_la_atlarge_all_incumbent_boards_2026_12_11.sql

BEGIN;

CREATE TEMP TABLE cc0437_seatings ON COMMIT DROP AS
SELECT * FROM (VALUES
    ('e9994d5a-8b43-48e4-96f6-0643116b41c2'::uuid, '254e533d-d131-5b34-9027-99a81f545b88'::uuid, 'Cesar Peralta', 'El Monte City School Board'),
    ('655e9d0a-99e4-43ae-89ef-1a81f0e13fb3'::uuid, 'e169f9e9-8f81-52f6-94e1-ecf5f08ebeeb'::uuid, 'Elizabeth "Beth" Rivas', 'El Monte City School Board'),
    ('28cb63a8-3dda-4e9b-a0ea-bbaeecd9930b'::uuid, '2da3e36f-45e0-5591-a5ae-ea1dce87c5d0'::uuid, 'Lisette Mendez Garcia', 'El Monte City School Board'),
    ('e008fc2c-e56f-4e88-b67d-1fc83317264e'::uuid, 'ed4e27bb-b4c0-400b-9c99-c3c696c44d67'::uuid, 'Esther Mejia', 'El Rancho Unified School Board'),
    ('49cf4fcd-edd1-42d0-ba41-520f33b70189'::uuid, 'b85eeb90-e183-4ad4-ab05-663f3de31ba0'::uuid, 'Hector LaFarga Jr.', 'El Rancho Unified School Board'),
    ('2dff60c3-71be-434a-93c0-b8b60b4dda42'::uuid, 'a45c73fc-6bb1-4642-b5b4-56da17b21fc1'::uuid, 'John Contreras', 'El Rancho Unified School Board'),
    ('48a5ac58-cb33-4a7b-9839-e3f86b6e583a'::uuid, 'ec2a615b-7f6e-4e14-9fc2-2dfa8f0501c5'::uuid, 'Frank C. Glynn', 'El Segundo Unified School Board'),
    ('390f56be-9ba2-4246-956c-48a5e08d76a0'::uuid, '4ecc7d76-22da-44a6-b2b9-bd029046368d'::uuid, 'Meredith J. Beachly', 'El Segundo Unified School Board'),
    ('98464401-cad8-452f-9203-8c295fd8663c'::uuid, 'b261afca-4cb9-4a59-9521-704307bf69d4'::uuid, 'Tracey I. Miller-Zarneke', 'El Segundo Unified School Board'),
    ('7527f0d7-7e62-55eb-9b97-fa61bfc3b98b'::uuid, 'dee8de05-2cab-50ca-aecb-0d66360676fd'::uuid, 'Diane Benitez', 'Rosemead School Board'),
    ('85f26636-6fd0-4a35-85dc-423218301b4d'::uuid, 'a5a53805-85fe-5b01-8990-dcaab536afde'::uuid, 'John Quintanilla', 'Rosemead School Board'),
    ('2519c262-33a0-491c-9501-d7febd5bf6c6'::uuid, '1a89b575-d545-5ded-ba93-ffbd439eaab4'::uuid, 'Nancy Armenta', 'Rosemead School Board'),
    ('28a7545e-1972-49a5-8c48-176360e6e8ed'::uuid, '31472d29-6c13-42fa-b6a9-1cf53b71e824'::uuid, 'Cynthia M. Ruiz', 'Walnut Valley Unified School Board'),
    ('27b9bef7-54d1-41a0-8b9d-2d282f17165b'::uuid, '442cb09c-c590-4eb8-9718-00967d719e52'::uuid, 'Helen M. Hall', 'Walnut Valley Unified School Board'),
    ('75dfd15b-f566-425f-a8e2-7a70703773fc'::uuid, 'be0686f9-51e1-45b4-a1dd-518e898492c5'::uuid, 'Yi "Tony" Torng', 'Walnut Valley Unified School Board'),
    ('10047a98-d090-4183-8bff-8a1bee926b0f'::uuid, 'b8aa42f2-6bce-4531-a7c2-1b2398cf6ed1'::uuid, 'Eileen Miranda Jimenez', 'West Covina Unified School Board'),
    ('0b2ed3ff-b492-4063-829c-3f61c132197a'::uuid, '6e76b0be-ac38-4ad7-8473-ed468196d1c6'::uuid, 'Rose Lopez', 'West Covina Unified School Board')
) AS t(office_id, politician_id, full_name, board);

CREATE TEMP TABLE cc0437_plan ON COMMIT DROP AS
SELECT politician_id FROM cc0437_seatings
UNION
SELECT och.politician_id FROM essentials.office_current_holder och
  JOIN cc0437_seatings s ON s.office_id = och.office_id
 WHERE och.politician_id IS NOT NULL;

-- ── Premise ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_bad int;
BEGIN
  SELECT count(*) INTO v_n FROM cc0437_seatings;
  IF v_n <> 17 THEN
    RAISE EXCEPTION 'CC_0437: expected 17 seatings, found %.', v_n;
  END IF;

  -- 🔴🔴 THE SAFETY PROPERTY OF THIS WHOLE FILE, ASSERTED RATHER THAN TRUSTED: every person is
  -- seated into the office THEY ALREADY HOLD. If that is not true of even one row, the file is
  -- choosing a seat for somebody, which is the thing it exists to avoid.
  SELECT count(*) INTO v_bad
    FROM cc0437_seatings s
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                      WHERE och.office_id = s.office_id
                        AND och.politician_id = s.politician_id);
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0437: % row(s) would seat somebody into an office they do NOT already '
      'hold. This file may only RE-seat sitting members.', v_bad;
  END IF;

  -- Each office once.
  SELECT count(*) INTO v_bad FROM (
    SELECT office_id FROM cc0437_seatings GROUP BY office_id HAVING count(*) > 1) x;
  IF v_bad > 0 THEN RAISE EXCEPTION 'CC_0437: % office(s) appear twice.', v_bad; END IF;

  -- Every office must be in the 2026-12-11 cohort's chambers and carry no 12-11 term yet.
  SELECT count(*) INTO v_bad
    FROM cc0437_seatings s
    JOIN essentials.office_terms ot ON ot.office_id = s.office_id
   WHERE ot.term_start = DATE '2026-12-11';
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0437: % office(s) already carry a 2026-12-11 term.', v_bad;
  END IF;

  -- 🔴 The four boards with a newcomer must still be untouched going in — they are the control
  -- that this file is not treating all ten at-large boards as one class.
  SELECT count(*) INTO v_bad
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
    JOIN essentials.office_terms ot ON ot.politician_id = rc.politician_id
                                   AND ot.term_start = DATE '2026-12-11'
   WHERE r.position_name IN ('Hawthorne School Board','Hermosa Beach City School Board',
                             'Manhattan Beach Unified School Board','San Marino Unified School Board');
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0437: % filer(s) on the four newcomer boards already carry a 2026-12-11 '
      'term. Those boards are deliberately not seated; read the header.', v_bad;
  END IF;
END $$;

-- @incumbency-decision: gated — see the header.
CREATE TEMP TABLE incumbency_before ON COMMIT DROP AS
SELECT rc.id              AS race_candidate_id,
       rc.politician_id,
       rc.is_incumbent    AS stored,
       EXISTS (SELECT 1 FROM essentials.office_terms t
                 JOIN essentials.offices o2 ON o2.id = t.office_id
                WHERE t.politician_id = rc.politician_id
                  AND (t.office_id = r.office_id
                       OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                  AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                  AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
              )            AS expected
  FROM essentials.race_candidates rc
  JOIN essentials.races     r  ON r.id  = rc.race_id
  JOIN essentials.offices   ro ON ro.id = r.office_id
  JOIN essentials.elections e  ON e.id  = r.election_id
 WHERE e.election_date >= CURRENT_DATE - INTERVAL '1 year'
   AND rc.politician_id IS NOT NULL
   AND rc.politician_id IN (SELECT politician_id FROM cc0437_plan);

CREATE TEMP TABLE cc0437_drift_before ON COMMIT DROP AS
SELECT count(*) FILTER (WHERE NOT o.is_vacant) AS unflagged
  FROM essentials.offices_missing_terms m
  JOIN essentials.offices o ON o.id = m.office_id;

-- ── Change ───────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM cc0437_seatings ORDER BY board, full_name LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id,
      r.politician_id,
      DATE '2026-12-11',
      'CC_0437: appointed in lieu of election (Elec. Code 10515; seated as if elected, Educ. Code '
      '5328). LA County RR/CC, FINAL LIST OF CANCELED ELECTIONS, November 3, 2026 General '
      'Election, revised 8/25/2026. At-large board; this member returns to the seat they already '
      'hold. Term commences 2026-12-11 per Educ. Code 5017.',
      p_how_started => 'appointed',
      -- Every row here is by definition a re-election: the person already holds this seat.
      p_allow_reelection => true);
  END LOOP;
END $$;

-- 🔴 NO `is_vacant` WRITE. Every office here is held today by the person being re-seated, so
-- none is flagged and clearing would be a no-op at best. CC_0434's blanket clear was the defect
-- CC_0436 had to undo; this file does not repeat the shape.

-- ── Post-verify ──────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_seated int; v_closed int; v_before int; v_after int; v_flagged int;
BEGIN
  SELECT count(*) INTO v_seated
    FROM cc0437_seatings s
    JOIN essentials.office_terms ot ON ot.office_id = s.office_id
                                   AND ot.politician_id = s.politician_id
                                   AND ot.term_start = DATE '2026-12-11';
  IF v_seated <> 17 THEN
    RAISE EXCEPTION 'CC_0437: expected 17 terms starting 2026-12-11; found %.', v_seated;
  END IF;

  -- Each predecessor term closes the day before, and the predecessor is the same person.
  SELECT count(*) INTO v_closed
    FROM cc0437_seatings s
    JOIN essentials.office_terms ot ON ot.office_id = s.office_id
                                   AND ot.politician_id = s.politician_id
                                   AND ot.term_end = DATE '2026-12-10';
  IF v_closed <> 17 THEN
    RAISE EXCEPTION 'CC_0437: expected 17 predecessor terms closed at 2026-12-10 for the SAME '
      'person; found %.', v_closed;
  END IF;

  -- 🔴 NOBODY MOVED SEATS AND NOBODY LOST ONE. Each of these offices must still resolve the same
  -- holder today, because the new term has not begun.
  IF EXISTS (SELECT 1 FROM cc0437_seatings s
               LEFT JOIN essentials.office_current_holder och ON och.office_id = s.office_id
              WHERE och.politician_id IS DISTINCT FROM s.politician_id) THEN
    RAISE EXCEPTION 'CC_0437: an office changed hands today. These terms start 2026-12-11.';
  END IF;

  -- 🔴 And no office acquired a vacancy flag — the CC_0434/CC_0436 lesson, asserted.
  SELECT count(*) INTO v_flagged
    FROM cc0437_seatings s JOIN essentials.offices o ON o.id = s.office_id
   WHERE o.is_vacant;
  IF v_flagged > 0 THEN
    RAISE EXCEPTION 'CC_0437: % office(s) here are flagged vacant while held.', v_flagged;
  END IF;

  SELECT unflagged INTO v_before FROM cc0437_drift_before;
  SELECT count(*) FILTER (WHERE NOT o.is_vacant) INTO v_after
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  RAISE NOTICE 'CC_0437: unflagged occupancy drift % -> %', v_before, v_after;
  IF v_after <> v_before THEN
    RAISE EXCEPTION 'CC_0437: unflagged drift moved % -> %. Every office here already had a term, '
      'so it must not move at all.', v_before, v_after;
  END IF;
END $$;


DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM cc0437_plan;   -- ⚠ REPLACE with your plan table
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;

  -- 🔴 AN EMPTY SCOPE PASSES EVERYTHING BELOW VACUOUSLY, AND IT HAS TWO OPPOSITE CAUSES. Either
  -- nobody you touched has run recently — the common, correct case — or your plan table is not the
  -- one the scope subquery reads, in which case this gate is switched off and looks identical.
  -- Counting the PLAN separately is what tells them apart: "4 planned, 0 with a race" is the first,
  -- "0 planned" is the second. Reading `incumbency_before` alone cannot distinguish them, which is
  -- how an earlier draft of this template reported a deliberately mis-pointed plan as fine.
  IF v_planned = 0 THEN
    RAISE EXCEPTION 'incumbency guard: the plan table is EMPTY, so this gate asserted nothing. '
      'Point it at the politicians whose office_terms rows this migration writes.';
  END IF;
  RAISE NOTICE 'incumbency guard: % person/people planned, % with a race row in the last year (% row(s))',
    v_planned, v_people, v_scoped;

  WITH after_state AS (
    SELECT rc.id              AS race_candidate_id,
           rc.is_incumbent    AS stored,
           EXISTS (SELECT 1 FROM essentials.office_terms t
                     JOIN essentials.offices o2 ON o2.id = t.office_id
                    WHERE t.politician_id = rc.politician_id
                      AND (t.office_id = r.office_id
                           OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                      AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                      AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
                  )            AS expected
      FROM essentials.race_candidates rc
      JOIN essentials.races     r  ON r.id  = rc.race_id
      JOIN essentials.offices   ro ON ro.id = r.office_id
      JOIN essentials.elections e  ON e.id  = r.election_id
     WHERE rc.id IN (SELECT race_candidate_id FROM incumbency_before)
  ),
  cmp AS (
    SELECT b.race_candidate_id,
           b.politician_id,
           a.stored,
           a.expected,
           (b.stored IS DISTINCT FROM b.expected) AS drifted_before,
           (a.stored IS DISTINCT FROM a.expected) AS drifted_after
      FROM incumbency_before b
      JOIN after_state a USING (race_candidate_id)
  )
  SELECT count(*) FILTER (WHERE NOT c.drifted_before AND c.drifted_after),
         count(*) FILTER (WHERE c.drifted_before AND NOT c.drifted_after),
         string_agg(
           format('    %s — race_candidate %s says is_incumbent=%s, office_terms now say %s',
                  coalesce(p.full_name, '(unnamed)'), c.race_candidate_id, c.stored, c.expected),
           E'\n' ORDER BY coalesce(p.full_name, ''))
           FILTER (WHERE NOT c.drifted_before AND c.drifted_after)
    INTO v_created, v_repaired, v_detail
    FROM cmp c
    LEFT JOIN essentials.politicians p ON p.id = c.politician_id;

  IF v_repaired > 0 THEN
    RAISE NOTICE 'incumbency guard: % race row(s) that drifted BEFORE this migration now agree with office_terms', v_repaired;
  END IF;

  IF v_created > 0 THEN
    RAISE EXCEPTION E'incumbency guard: % race row(s) agreed with essentials.office_terms before this migration and contradict it now.\n%\n\nThis is what `check:incumbency` will say on the NEXT push to master, under somebody else''s name. Settle it here.\n  • Newcomer — the date is right and the race row is wrong. Set race_candidates.is_incumbent = false IN THIS MIGRATION.\n  • Re-elected — the race row is right and the DATE is wrong: you have written their latest term''s start as the start of their whole tenure. Leave term_start NULL, or write the real first term.\nThe two look identical from the predicate. Read the person. See CC_0396''s header for the worked split of seven such rows.',
      v_created, coalesce(v_detail, '    (no detail)');
  END IF;
END $$;

COMMIT;
