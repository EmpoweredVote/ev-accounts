-- CC_0470 — Hawaii Office of Hawaiian Affairs: seat the Maui and Oahu resident trustees, whose
-- terms began on election day, 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE TERM STARTED ON THE DAY OF THE ELECTION. THIS WAVE IS TWENTY DAYS LATE.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- HRS § 13D-5 begins a trustee's four-year term "beginning on the day of the general election at
-- which they are elected". CC_0469 recorded 2026-11-03 against all three pending OHA offices;
-- this file reads it and writes two terms.
--
--   Maui Resident Trustee   Carmen Hulu Lindsey   re-elected
--   Oahu Resident Trustee   Kalei Akaka           re-elected
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHY THIS FILE SEATS TWO OF THE BODY'S THREE PENDING OFFICES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The third is the At-large Trustee, and it is refused under Ruling A: THREE winners
-- (Brickwood Galuteria, Ikaika Anderson, Keoni Souza) sit on ONE office row against FOUR
-- at-large offices. Eligible offices ≠ winners, so the body is staggered, which seats are up is
-- not in our data, and nothing says which three of the four these are. Ten ways to choose, and
-- choosing would unseat a sitting trustee with two years left.
--
-- 🟢 AND THIS IS EXACTLY WHY RULING A IS SCOPED TO THE RACE'S OWN TITLE RATHER THAN THE
--    DISTRICT. All nine OHA offices share one district. A gate asserted over the district would
--    refuse these two single-seat, single-winner re-elections as well — people who need no
--    ruling at all. The selection below is scoped by title, and the At-large row falls out of it
--    structurally rather than by being named.
--
-- ▶ The At-large seats are unblocked by OHA's own published roster of trustees and term
--   expirations, which says which seat each winner takes. That is a separate file; the DATE is
--   not in doubt and is already recorded by CC_0469.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SELECTION IS PINNED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   winners 2 · offices 2 · re-elections 2 · new holders 0
--   digest md5 = 2ff0e8a0710790802abcadd8cbdf7d1e   (captured 2026-11-23 against production)
--   called 2 · certified 0 on the day this was captured (Ruling B)
--
-- The date is read from `essentials.office_swearing_in`, written by CC_0469 from HRS § 13D-5.
-- P4 refuses unless both agree on 2026-11-03 with a basis of statute or published.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes each predecessor with an unguarded
-- `UPDATE office_terms SET term_end = p_term_start - 1` and records nothing about the row it
-- overwrote. So:
--
--   🔴 BOTH PREDECESSOR TERMS CARRY `term_end = NULL`, `how_ended = NULL` AND `term_start = NULL`.
--      Measured against production 2026-11-23. The rows are
--        Maui  term 8c2840d0-6522-4dc6-b4cb-e9327517d073  Carmen Hulu Lindsey
--        Oahu  term dd43a6b3-0cb9-4277-816b-f2bd83fbe218  Kalei Akaka
--      and the full pre-image is captured into `cc0470_pre`, which P7 refuses unless every
--      `term_end` in it is NULL.
--
--   ⚠ BOTH PREDECESSORS NAME THE SAME PEOPLE AS THE NEW TERMS, because both are re-elections.
--     The term that closes at 2026-11-02 and the term that opens at 2026-11-03 are the same
--     person's, so `office_current_holder` answers identically before and after — which is what
--     assertion 4 pins.
--
--   ⚠ THEIR PRIOR TERMS WERE UNDATED, so closing them writes an end onto a row with no start.
--     That is correct and is not this file's to fix: those two rows are part of the long tail of
--     undated tenures, and a tenure start is a different fact from a term start.

BEGIN;

CREATE TEMP TABLE cc0470_pin ON COMMIT DROP AS
SELECT 2                                  AS expect_winners,
       2                                  AS expect_offices,
       2                                  AS expect_reelections,
       0                                  AS expect_new,
       '2ff0e8a0710790802abcadd8cbdf7d1e' AS expect_digest,
       DATE '2026-11-03'                  AS expect_term_start;
-- winners = offices here, so the two pins are equal. They are NOT in general.

-- 🔴 WAVE_SELECTION_SQL, column for column, NARROWED BY TITLE — see the Ruling A note above.
CREATE TEMP TABLE cc0470_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       (win.value ->> 'id')::uuid                        AS politician_id,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id'))
                                                         AS is_reelection,
       si.swearing_in_date                               AS term_start,
       si.basis                                          AS basis,
       o.title                                           AS title,
       (win.value ->> 'name')                            AS winner_name
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = o.id
                                                AND si.election_date = DATE '2026-11-03'
 WHERE lower(d.state) = 'hi'
   AND d.district_type = 'STATE_EXEC'
   AND o.title LIKE 'Office of Hawaiian Affairs%Resident Trustee'
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0470_pre ON COMMIT DROP AS
SELECT s.office_id, s.title, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0470_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0470_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM cc0470_pre)                                           AS predecessors,
       (SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-'),
                              '|' ORDER BY office_id::text))
          FROM essentials.office_current_holder)                                   AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged;

DO $$
DECLARE n bigint; d text; p record;
BEGIN
  SELECT * INTO p FROM cc0470_pin;

  SELECT count(*) INTO n FROM cc0470_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: selection returned % winner rows, expected %. The data moved under '
                    'this file.', n, p.expect_winners;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0470_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %.', d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0470_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected %. Assertion 4 pins the whole current-holder '
                    'map unchanged, which is only true while BOTH rows are re-elections.',
      n, p.expect_reelections;
  END IF;

  -- P2 — this file has not already been applied. Above P1's successors on purpose: on a second
  -- run the two seats have left office_pending_winner and P1 would report 0 rows, telling the
  -- operator the data moved when what happened is that they ran it twice.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0470%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0470. Applied before.', n;
  END IF;

  -- P3 — 🔴 THE AT-LARGE ROW IS NOT IN THIS SELECTION. The title filter is what excludes it, so
  --    this asserts the filter did its job rather than trusting the LIKE pattern. If the
  --    at-large office were ever retitled to end "Resident Trustee", three winners would arrive
  --    on one office and Ruling A would be run over silently.
  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0470_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner. The At-large row has three and '
                    'is refused under Ruling A — it must not be in this wave.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0470_sel WHERE title LIKE '%At-large%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % At-large row(s) reached this selection.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0470_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. CC_0469 '
                    'writes it.', n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0470_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0470_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat.', n;
  END IF;

  -- P6 — nothing here is flagged vacant, so this file has no flag to clear.
  SELECT count(*) INTO n
    FROM cc0470_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) are flagged is_vacant. A term that began twenty days ago '
                    'means the flag is wrong; decide each one before seating it.', n;
  END IF;

  -- P7 — the pre-image is complete and every predecessor is open.
  SELECT count(*) INTO n FROM cc0470_pre;
  IF n <> 2 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) captured, expected 2 (one per seat).', n;
  END IF;

  SELECT count(*) INTO n FROM cc0470_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing.', n;
  END IF;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK A — the incumbency guard, from migrations/_templates/office_terms_incumbency_guard.sql
-- ═════════════════════════════════════════════════════════════════════════════════════════════
--
-- @incumbency-decision: gated — this closes each predecessor term at 2026-11-02, which is the
-- day BEFORE the election, so the gate is asked properly rather than argued away.
--
-- 🔴 A TERM THAT BEGINS ON ELECTION DAY MOVES WHICH ROW COVERS THE ELECTION, AND THAT IS THE
--    PREDICATE `check:incumbency` READS. Every other wave in this pass closes its predecessor ON
--    or AFTER the election, so the OLD row still covers it and the guard is a formality. Here
--    the old row stops at 2026-11-02 and the NEW one starts on 2026-11-03 — so the answer is
--    unchanged only because both rows name the same person. The scope covers both sides of the
--    seating, which here is one set of people.
CREATE TEMP TABLE cc0470_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0470_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0470_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0470_guarded);

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0470_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in, "beginning on the day of the '
                         || 'general election at which they are elected" (HRS §13D-5) — the '
                         || 'election day itself. Re-elected trustee. CC_0470',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0470: seat_officeholder called for % offices', v_seated;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK B — the incumbency guard's comparison
-- ═════════════════════════════════════════════════════════════════════════════════════════════
DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM cc0470_guarded;
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;

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

-- ── Post-verify ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n bigint; m text; b record; p record;
BEGIN
  SELECT * INTO b FROM cc0470_before;
  SELECT * INTO p FROM cc0470_pin;

  -- 1. Two new terms, one per selected office, on the day itself, naming the winner.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0470_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start, p.expect_offices;
  END IF;

  -- 2. 🔴 NOT office_next_term — THIS TERM BEGAN TWENTY DAYS AGO. Both halves asserted: a seat
  --    that is wrongly ALSO scheduled would pass a current-holder check on its own.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0470_sel s ON s.office_id = nx.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '2: % of these seats appear in office_next_term, but their term began %.',
      n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0470_sel s ON s.office_id = och.office_id
   WHERE och.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_current_holder answers with the seated trustee for % of % seats.',
      n, p.expect_offices;
  END IF;

  -- 3. 🔴 NOBODY CHANGED SEATS, ANYWHERE — and here that is a real claim, not a formality. The
  --    old term stops the day BEFORE the election and the new one starts ON it, so the row that
  --    answers for today is a different row. The map is unchanged only because both rows name
  --    the same person. If either of these turned out not to be the sitting trustee, this fires.
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-'),
                        '|' ORDER BY office_id::text))
    INTO m FROM essentials.office_current_holder;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '3: the current-holder map changed (% -> %). Both of these are re-elections, '
                    'so seating them must not move a single seat.', b.holders_md5, m;
  END IF;

  -- 4. Each predecessor named in the pre-image is closed at 2026-11-02.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0470_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '4: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0470_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 5. 🔴 THE AT-LARGE OFFICE WAS NOT TOUCHED. It is refused under Ruling A and must still be
  --    waiting when this file is done; a wave that quietly seated it would read as success.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o ON o.id = w.office_id
   WHERE o.title = 'Office of Hawaiian Affairs At-large Trustee'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 1 THEN
    RAISE EXCEPTION '5: the OHA At-large office no longer answers office_pending_winner. It is '
                    'refused under Ruling A and this file must leave it exactly where it was.';
  END IF;

  -- 6. This file creates no people and no offices.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '6: politicians moved from % to %.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '6: offices moved from % to %.', b.offices, n;
  END IF;

  -- 7. Repo-wide, exactly two office_terms rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '7: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 8. Every new term cites this migration (Ruling B: recoverable by slot).
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0470_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0470%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '8: % of % new terms cite CC_0470.', n, p.expect_offices;
  END IF;

  -- 9. The two seats have left the pending-winner view.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0470_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % seat(s) still answer office_pending_winner.', n;
  END IF;

  -- 10. The 238 unflagged drift baseline did not move. 🔴 NEVER RAISE IT.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '10: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  RAISE NOTICE 'CC_0470 OK: 2 OHA resident trustees seated from % (both re-elections), % '
               'predecessors closed at %, nobody changed seats, the At-large row left refused, '
               'drift baseline % held.',
    p.expect_term_start, b.predecessors, p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
