-- CC_0475 — Maine House and Senate: schedule all 183 winners for the term that begins
-- 2026-12-01.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 EIGHT DAYS. THIS IS THE NEAREST DEADLINE IN THE STATE SEATING PASS.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Me. Const. art. IV, pt. First, § 2 gives representatives their office "2 years from the day
-- next preceding the first Wednesday in December following the general election", and pt. Second
-- § 1 gives senators "the same term as Representatives". The first Wednesday in December 2026 is
-- the **2nd**; the day next preceding it is **2026-12-01**. CC_0473 recorded that date against
-- all 183 offices; this file reads it and writes the terms.
--
-- 🔴 2026-12-02 IS THE NUMBER EVERY PUBLISHED ACCOUNT GIVES AND IT IS ONE DAY LATE. It is the
--    day the Legislature CONVENES (art. IV, pt. Third, § 1) and takes the oath. The Legislature's
--    own agenda for this cycle shows both days: "Tuesday, December 1st — Pre-Legislative
--    Conference for All Members"; "Wednesday, December 2nd — Convening of the 133rd Maine
--    Legislature, 10:00 AM". The members-elect are in Augusta on the day their terms begin and
--    are sworn the next morning. ▶ **P4 reads the date from `office_swearing_in` and refuses
--    anything but 2026-12-01; assertion 9 refuses if any row carries the convening date.**
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SELECTION IS PINNED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   winners 183 · offices 183 · re-elections 106 · new holders 77
--   digest md5 = 1d8cfe00b3000568de9bd211babf310b   (captured 2026-11-23 against production,
--                                                    AFTER CC_0474)
--   called 183 · certified 0 on the day this was captured (Ruling B)
--
-- 🔴 THAT DIGEST IS THE POST-CC_0474 ONE. `office_pending_winner` renders a winner with no person
--    record as a NULL id, and 77 of these 183 had none until CC_0474 created 59 people and linked
--    18 who already existed. ▶ **IF P1 REPORTS A DIFFERENT DIGEST, CHECK WHETHER CC_0474 HAS BEEN
--    APPLIED BEFORE CONCLUDING THE DATA MOVED** — the two failures are indistinguishable from the
--    error message alone.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THIS IS A FUTURE-DATED WAVE AND IT CONTAINS 77 HANDOVERS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes each predecessor at `term_start - 1` = **2026-11-30**, which is
-- still in the future, so `office_current_holder` — "the term covering CURRENT_DATE" — keeps
-- answering with today's member until the morning of the 1st. Assertion 4 pins the nationwide
-- holder map unchanged; assertion 5 asserts all 183 seats still answer with the person holding
-- them today. Those are different claims and the second is the one a voter sees.
--
-- ⚠ `is_vacant` IS LEFT ALONE. No Maine legislative seat in this wave is flagged (P6 asserts it),
--   and for a future seating the flag must not be touched anyway: the seat really is held by
--   somebody else until that morning.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes each predecessor with an UNGUARDED
-- `UPDATE office_terms SET term_end = p_term_start - 1` and writes nothing to that row's
-- `source`. So the 183 new terms are recoverable by slot and the 183 CLOSURES are not.
--
--   🔴 ALL 183 PREDECESSOR TERMS CARRY `term_end = NULL`. Measured against production
--      2026-11-23, not inferred. The full pre-image is captured into `cc0475_pre`, P7 refuses
--      unless every `term_end` in it is NULL, and assertion 6 counts the rows it closed.
--
-- ⚠ MAINE'S SITTING LEGISLATORS ARE AMONG THE UNDATED TENURES: most of these predecessor rows
--   have `term_start` NULL as well, so closing them writes an end onto a row with no beginning.
--   That is correct and is not this file's to fix — a tenure start is a different fact from a
--   term start.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ WHAT THIS WAVE DOES NOT COVER
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- • **The Governor** starts 2027-01-06 under art. V, pt. First, § 2 — a different clause and a
--   different day, so Maine ships as two waves and `CC_0476` is the other. The selection below
--   is narrowed to `STATE_LOWER` and `STATE_UPPER`; assertion 10 asserts the Governor was not
--   swept in.
-- • **Three seats with a race and no recorded result** — State House 86, State House 96 and
--   State Senate 18 — are outside `office_pending_winner` and outside this wave. The
--   Legislature's own orientation roster names their winners (Abigail Geer, Kerryl Clement,
--   Elizabeth Bosworth); recording a result is the results programme's act, not this one's.
-- • **Three tribal House seats** are seated by their nations under Joint Rules 206(3) and 316,
--   not at a general election, and carry no 2026 race. Assertion 11 asserts none was touched.

BEGIN;

CREATE TEMP TABLE cc0475_pin ON COMMIT DROP AS
SELECT 183                                AS expect_winners,
       183                                AS expect_offices,
       106                                AS expect_reelections,
       77                                 AS expect_new,
       '1d8cfe00b3000568de9bd211babf310b' AS expect_digest,
       DATE '2026-12-01'                  AS expect_term_start;
-- winners = offices here, so the two pins are equal. They are NOT in general.

-- 🔴 THIS SELECTION IS `scripts/lib/seating-wave.mjs`'s WAVE_SELECTION_SQL, column for column.
CREATE TEMP TABLE cc0475_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       (win.value ->> 'id')::uuid                        AS politician_id,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id'))
                                                         AS is_reelection,
       si.swearing_in_date                               AS term_start,
       si.basis                                          AS basis,
       d.label                                           AS seat,
       d.district_type                                   AS district_type,
       (win.value ->> 'name')                            AS winner_name,
       och.politician_id                                 AS holder_before
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = o.id
                                                AND si.election_date = DATE '2026-11-03'
 WHERE lower(d.state) = 'me'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0475_pre ON COMMIT DROP AS
SELECT s.office_id, s.seat, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0475_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0475_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2026-12-01')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM cc0475_pre)                                           AS predecessors,
       (SELECT md5(string_agg(och.office_id::text || ':'
                              || COALESCE(och.politician_id::text, '-'),
                              '|' ORDER BY och.office_id::text))
          FROM essentials.office_current_holder och)                               AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged;

DO $$
DECLARE n bigint; d text; p record;
BEGIN
  SELECT * INTO p FROM cc0475_pin;

  SELECT count(*) INTO n FROM cc0475_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: selection returned % winner rows, expected %. The data moved under '
                    'this file.', n, p.expect_winners;
  END IF;

  SELECT count(DISTINCT office_id) INTO n FROM cc0475_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P1: % offices, expected %.', n, p.expect_offices;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0475_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %. ⚠ Before concluding the data moved, '
                    'check that CC_0474 has been applied — 77 of these winners had no person '
                    'record until it ran, and that changes this digest.', d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0475_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected %.', n, p.expect_reelections;
  END IF;

  -- P2 — this file has not already been applied. Asked above the rest on purpose: on a second
  -- run the 183 have left office_pending_winner, so P1 would report 0 rows and tell the operator
  -- the data moved when what happened is that they ran it twice.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0475%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0475. Applied before.', n;
  END IF;

  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0475_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner. Maine has no multi-member '
                    'legislative district, so this is Ruling A arriving where it was not '
                    'expected — stop and read the race.', n;
  END IF;

  -- P4 — 🔴 THE DATE IS READ, NEVER CARRIED. A literal here would agree with itself however
  --    wrong it was, and the wrong answer for Maine is exactly one day away.
  SELECT count(*) INTO n FROM cc0475_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. CC_0473 '
                    'writes it.', n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0475_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0475_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat. CC_0474 creates 59 and '
                    'links 18.', n;
  END IF;

  -- P6 — nothing here is flagged vacant, and a FUTURE seating must not clear the flag anyway.
  SELECT count(*) INTO n
    FROM cc0475_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) are flagged is_vacant. A future-dated seating leaves the flag '
                    'alone, so a flag that is already wrong must be settled in its own file.', n;
  END IF;

  -- P7 — the pre-image is complete and every predecessor is open.
  SELECT count(*) INTO n FROM cc0475_pre;
  IF n <> 183 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) captured, expected 183 (one per seat).', n;
  END IF;

  SELECT count(*) INTO n FROM cc0475_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing, so this file would '
                    'destroy a date it has not written down.', n;
  END IF;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK A — the incumbency guard, from migrations/_templates/office_terms_incumbency_guard.sql
-- ═════════════════════════════════════════════════════════════════════════════════════════════
--
-- @incumbency-decision: gated — this closes each predecessor at 2026-11-30, which is AFTER the
-- election, so the outgoing term still covers 2026-11-03 and the predicate's answer must not
-- move for anybody. The scope covers both sides of the seating: the 183 winners and the people
-- whose terms are closed.
--
-- 🔴 MAINE MAKES THAT SCOPE DO REAL WORK. 18 of these winners are sitting members changing
--    chamber, so one person can be BOTH a winner here and a predecessor here, on two different
--    seats. The UNION is what keeps each of them counted once.
CREATE TEMP TABLE cc0475_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0475_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0475_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0475_guarded);

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0475_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in, "2 years from the day next '
                         || 'preceding the first Wednesday in December following the general '
                         || 'election" ('
                         || CASE r.district_type WHEN 'STATE_LOWER'
                              THEN 'Me. Const. art. IV, pt. First, §2'
                              ELSE 'Me. Const. art. IV, pt. Second, §1, taking the House''s term'
                            END
                         || '). NOTE: the Legislature CONVENES and takes the oath on 2026-12-02, '
                         || 'the first Wednesday — one day later. '
                         || CASE WHEN r.is_reelection THEN 'Re-elected incumbent. '
                                 ELSE 'New holder; predecessor closed at 2026-11-30. ' END
                         || 'CC_0475',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0475: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0475_guarded;
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
-- ⚠ ORDERED SO THE NARROW CHECKS RUN FIRST, so a control aimed at a given assertion reaches it
--   instead of tripping a repo-wide count two gates earlier.
DO $$
DECLARE n bigint; m text; b record; p record;
BEGIN
  SELECT * INTO b FROM cc0475_before;
  SELECT * INTO p FROM cc0475_pin;

  -- 1. 183 new terms, one per selected office, on the day itself, naming the winner.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0475_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start, p.expect_offices;
  END IF;

  -- 2. office_next_term answers for all 183 — the view a voter's page reads for a dated handover.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0475_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_offices;
  END IF;

  -- 3. Repo-wide, exactly 183 more terms start on that day — no other state swept in.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_offices THEN
    RAISE EXCEPTION '3: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;

  -- 4. 🔴 NOBODY WAS UNSEATED TODAY, ANYWHERE IN THE COUNTRY. A future-dated term must not move
  --    a seat now, and this wave contains 77 handovers, so the assertion has plenty to catch.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today.', b.holders_md5, m;
  END IF;

  -- 5. 🔴 AND ALL 183 SEATS STILL ANSWER WITH TODAY'S HOLDER. "The digest did not move" and
  --    "these seats read correctly" are different claims, and the second is what a voter sees.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0475_sel s ON s.office_id = och.office_id
   WHERE och.politician_id = s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of % seats still answer office_current_holder with the person holding '
                    'them today.', n, p.expect_offices;
  END IF;

  -- 6. Each predecessor named in the pre-image is closed the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0475_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0475_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 7. No term of these seats was closed between today and the handover, which would leave a
  --    gap with nobody in the seat.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0475_sel s ON s.office_id = t.office_id
   WHERE t.term_end IS NOT NULL
     AND t.term_end >= CURRENT_DATE AND t.term_end < p.expect_term_start - 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % term(s) closed between today and the day before the handover.', n;
  END IF;

  -- 8. This file creates no people and no offices. CC_0474 made the 59.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %.', b.offices, n;
  END IF;

  -- 9. 🔴🔴 NOT ONE SEAT CARRIES THE CONVENING DATE. 2026-12-02 is the number every published
  --    account gives and it is one day late. This is the single most likely way for Maine to be
  --    wrong, so it is asserted rather than assumed.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0475_sel s ON s.office_id = t.office_id
   WHERE t.term_start = DATE '2026-12-02';
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % seat(s) start 2026-12-02, the day the Legislature CONVENES. The term '
                    'begins the day next preceding it.', n;
  END IF;

  -- 10. 🔴 THE GOVERNOR WAS NOT SWEPT IN. A different clause and a different day; CC_0476.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me' AND d.district_type = 'STATE_EXEC'
     AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '10: % Maine state executive(s) were given the legislature''s date. The '
                    'Governor''s term begins 2027-01-06 under art. V, pt. First, § 2.', n;
  END IF;

  -- 11. 🔴 THE THREE TRIBAL HOUSE SEATS WERE NOT TOUCHED. They are seated by their nations, not
  --     at a general election, and they have no 2026 race — so they are outside the selection by
  --     construction. Asserting it is what makes that true rather than assumed.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
   WHERE o.title = 'Tribal Representative' AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '11: % tribal House seat(s) were seated by this wave.', n;
  END IF;

  -- 12. Repo-wide, exactly 183 office_terms rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '12: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 13. Every new term cites this migration (Ruling B: recoverable by slot).
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0475_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0475%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '13: % of % new terms cite CC_0475.', n, p.expect_offices;
  END IF;

  -- 14. 🔴 THE SEATS HAVE LEFT THE PENDING-WINNER VIEW, so the card stops reading as a declared
  --     result and starts reading as a dated handover.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0475_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '14: % seat(s) still answer office_pending_winner.', n;
  END IF;

  -- 15. The 238 unflagged drift baseline did not move. 🔴 NEVER RAISE IT.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '15: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  RAISE NOTICE 'CC_0475 OK: 183 Maine legislators scheduled for % (% re-elections, % handovers), '
               '% predecessors closed at %, nobody moved today, no seat carries the 12-02 '
               'convening date, the Governor and the 3 tribal seats untouched, drift baseline '
               '% held.',
    p.expect_term_start, p.expect_reelections, p.expect_new, b.predecessors,
    p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
