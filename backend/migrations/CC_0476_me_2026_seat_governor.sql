-- CC_0476 — Maine: schedule Governor-elect Hannah Pingree for the term that begins 2027-01-06.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- MAINE'S SECOND WAVE. ONE SEAT, A DIFFERENT CLAUSE, A DIFFERENT DAY.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Me. Const. art. V, pt. First, § 2: the Governor "shall hold the office for 4 YEARS FROM THE
-- FIRST WEDNESDAY AFTER THE FIRST TUESDAY OF JANUARY next following the election and until the
-- successor to the Governor has been duly elected and qualified." The first Tuesday of January
-- 2027 is the 5th, so the first Wednesday after it is **2027-01-06**. CC_0473 recorded that
-- date; this file reads it.
--
-- 🔴 THE LEGISLATURE'S 183 SEATS START 2026-12-01, THIRTY-SIX DAYS EARLIER, UNDER art. IV. Two
--    dates in one `(state, district_type)` row is two waves — `classifyWave` raises
--    `date_disagrees` on Maine and is right to. CC_0475 is the other half. P4 refuses anything
--    but 2027-01-06 here, and CC_0475's assertion 10 refuses to give this office the
--    legislature's date.
--
-- 🔴 "THE FIRST WEDNESDAY AFTER THE FIRST TUESDAY OF JANUARY" IS NOT "THE FIRST WEDNESDAY OF
--    JANUARY". The two differ whenever 1 January is a Wednesday: the plain reading gives the
--    1st, this clause gives the 8th. They agree in 2027 by luck, and that is exactly the kind of
--    coincidence that hides a wrong rule for four years.
--
-- 🟢🟢 THE CONTROL IS EXACT AND COMES FROM A PASS THAT NEVER SAW THIS CLAUSE. The same formula
--    gives 2019-01-02 for the 2018 cycle, which is the term already recorded for Janet T. Mills
--    by `CA_0352` from maine.gov and nga.org. Asserted here as well as in CC_0473.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SELECTION IS PINNED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   winners 1 · offices 1 · re-elections 0 · new holders 1
--   digest md5 = cd39856d6906dee7c30d035a2c011f08   (captured 2026-11-23 against production)
--   called 1 · certified 0 on the day this was captured (Ruling B)
--
--   office     95700fc5-2800-4766-9005-38dc7237c455   Maine Governor
--   outgoing   baffe39e-4bf9-4956-9d59-92fe8d473fd8   Janet T. Mills
--   incoming   ac09c6dc-d7db-4bdb-9829-0e746c8ca665   Hannah Pingree
--
-- ⚠ THIS IS A HANDOVER AND NOT A CHOICE: art. V, pt. First, § 2 makes a Governor who has served
--   two consecutive popular elective four-year terms ineligible to succeed themselves, and Mills
--   has. ⚠ Rick Bennett, the sitting Senator for District 18, appears in this race with
--   `result = 'lost'` — which is why Senate District 18 is an open seat with no recorded winner.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴 ONE PREDECESSOR TERM, AND THE VALUE OVERWRITTEN IS `term_end = NULL`:
--
--      term c4132dc6-bcb0-40f1-b26d-47adc4012ede · Janet T. Mills · term_start 2019-01-02
--      term_end NULL → 2027-01-05
--
--    Measured against production 2026-11-23. `seat_officeholder` closes it with an unguarded
--    UPDATE and records nothing, so this header is the record; P7 refuses unless it is still
--    open when the file runs.
--
-- ⚠ `is_vacant` IS LEFT ALONE and nothing is flagged (P6). A FUTURE-dated seating must not touch
--   it: Janet Mills really is Governor until that morning, and assertions 4 and 5 say so.

BEGIN;

CREATE TEMP TABLE cc0476_pin ON COMMIT DROP AS
SELECT 1                                  AS expect_winners,
       1                                  AS expect_offices,
       0                                  AS expect_reelections,
       1                                  AS expect_new,
       'cd39856d6906dee7c30d035a2c011f08' AS expect_digest,
       DATE '2027-01-06'                  AS expect_term_start;

-- 🔴 WAVE_SELECTION_SQL, column for column, narrowed to STATE_EXEC — Maine ships as two waves.
CREATE TEMP TABLE cc0476_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       (win.value ->> 'id')::uuid                        AS politician_id,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id'))
                                                         AS is_reelection,
       si.swearing_in_date                               AS term_start,
       si.basis                                          AS basis,
       o.title                                           AS title,
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
   AND d.district_type = 'STATE_EXEC'
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0476_pre ON COMMIT DROP AS
SELECT s.office_id, t.id AS term_id, t.politician_id, t.term_start, t.term_end, t.how_ended
  FROM cc0476_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0476_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-06')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM cc0476_pre)                                           AS predecessors,
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
  SELECT * INTO p FROM cc0476_pin;

  SELECT count(*) INTO n FROM cc0476_sel;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P1: selection returned % winner rows, expected 1. Maine elects only the '
                    'Governor at a general election; the Secretary of State, Treasurer and '
                    'Attorney General are chosen by joint ballot of the Legislature.', n;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0476_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %.', d, p.expect_digest;
  END IF;

  -- P2 — this file has not already been applied.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0476%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0476. Applied before.', n;
  END IF;

  -- P3 — the handover is the one this file names, by id on both sides.
  SELECT count(*) INTO n FROM cc0476_sel
   WHERE office_id      = '95700fc5-2800-4766-9005-38dc7237c455'
     AND politician_id  = 'ac09c6dc-d7db-4bdb-9829-0e746c8ca665'
     AND holder_before  = 'baffe39e-4bf9-4956-9d59-92fe8d473fd8'
     AND NOT is_reelection;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P3: the Maine Governor row is not the handover this file was written about '
                    '(Hannah Pingree succeeding Janet T. Mills).';
  END IF;

  -- P4 — 🔴 ONE DATE, AND IT IS JANUARY'S. If a legislative row reached this selection it would
  --    bring 2026-12-01 with it.
  SELECT count(*) INTO n FROM cc0476_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: the office has no swearing-in date, or one that is not %. CC_0473 '
                    'writes it, and Maine''s legislature starts on 2026-12-01.',
      p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0476_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: the date''s basis is not statute or published.';
  END IF;

  SELECT count(*) INTO n FROM cc0476_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: the winner has no politician row to seat.';
  END IF;

  -- P6 — not flagged vacant, and a future seating would leave the flag alone regardless.
  SELECT count(*) INTO n
    FROM cc0476_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: the Governor''s office is flagged is_vacant. Janet Mills holds it until '
                    '2027-01-06; settle the flag in its own file.';
  END IF;

  -- P7 — the pre-image is the row the header names, and it is still open.
  SELECT count(*) INTO n FROM cc0476_pre
   WHERE term_id = 'c4132dc6-bcb0-40f1-b26d-47adc4012ede' AND term_end IS NULL
     AND term_start = DATE '2019-01-02';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P7: Janet Mills'' term is not the open 2019-01-02 row this file recorded. '
                    'seat_officeholder overwrites term_end without a guard and records nothing.';
  END IF;

  -- P8 — 🟢 THE CLAUSE, EVALUATED AS WRITTEN, FOR BOTH CYCLES. "The first Wednesday AFTER the
  --    first Tuesday of January" — not "the first Wednesday of January", a different rule that
  --    happens to agree in 2027.
  SELECT count(*) INTO n FROM (
    SELECT ft.d + (CASE WHEN EXTRACT(ISODOW FROM ft.d) = 2 THEN 1 ELSE 0 END) AS got, ft.want
      FROM (VALUES (DATE '2027-01-01', DATE '2027-01-06'), (DATE '2019-01-01', DATE '2019-01-02'))
             AS v(jan1, want),
           LATERAL (SELECT v.jan1 + ((9 - EXTRACT(ISODOW FROM v.jan1))::int % 7) AS d, v.want) ft
  ) q WHERE q.got <> q.want;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: the clause does not compute to 2027-01-06 and 2019-01-02.';
  END IF;

  SELECT count(*) INTO n FROM cc0476_pre WHERE term_start = DATE '2019-01-02';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P8: the formula gives 2019-01-02 for the 2018 cycle, but Maine''s Governor '
                    'does not carry a term starting that day. The clause that dates 2027-01-06 '
                    'should also explain the term already in the database.';
  END IF;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK A — the incumbency guard, from migrations/_templates/office_terms_incumbency_guard.sql
-- ═════════════════════════════════════════════════════════════════════════════════════════════
--
-- @incumbency-decision: gated — this closes Janet Mills' term at 2027-01-05, well after the
-- election, so her term still covers 2026-11-03 and the predicate's answer must not move. The
-- scope covers both sides: the winner and the outgoing Governor.
CREATE TEMP TABLE cc0476_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0476_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0476_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0476_guarded);

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM cc0476_sel LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in, "4 years from the first '
                         || 'Wednesday after the first Tuesday of January next following the '
                         || 'election" (Me. Const. art. V, pt. First, §2). The start is a '
                         || 'calendar formula; "until the successor has been duly elected and '
                         || 'qualified" bounds the END, so the oath is a separate event. New '
                         || 'holder; Janet T. Mills is term-limited and her term closes '
                         || '2027-01-05. CC_0476',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
  END LOOP;
  RAISE NOTICE 'CC_0476: seat_officeholder called for the Maine Governor';
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
  SELECT count(*) INTO v_planned FROM cc0476_guarded;
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
    SELECT b.race_candidate_id, b.politician_id, a.stored, a.expected,
           (b.stored IS DISTINCT FROM b.expected) AS drifted_before,
           (a.stored IS DISTINCT FROM a.expected) AS drifted_after
      FROM incumbency_before b JOIN after_state a USING (race_candidate_id)
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
  SELECT * INTO b FROM cc0476_before;
  SELECT * INTO p FROM cc0476_pin;

  -- 1. One new term, naming Hannah Pingree, on the day itself.
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE office_id = '95700fc5-2800-4766-9005-38dc7237c455'
     AND term_start = p.expect_term_start
     AND politician_id = 'ac09c6dc-d7db-4bdb-9829-0e746c8ca665';
  IF n <> 1 THEN
    RAISE EXCEPTION '1: the Governor''s new term is not Hannah Pingree on %.', p.expect_term_start;
  END IF;

  -- 2. office_next_term answers — the view a voter's page reads for a dated handover.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0476_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> 1 THEN
    RAISE EXCEPTION '2: office_next_term does not answer for the Governor.';
  END IF;

  -- 3. 🔴 JANET MILLS IS STILL GOVERNOR TODAY, and so is everybody else everywhere.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '3: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today.', b.holders_md5, m;
  END IF;

  SELECT count(*) INTO n FROM essentials.office_current_holder
   WHERE office_id = '95700fc5-2800-4766-9005-38dc7237c455'
     AND politician_id = 'baffe39e-4bf9-4956-9d59-92fe8d473fd8';
  IF n <> 1 THEN
    RAISE EXCEPTION '3: Maine''s Governor no longer answers as Janet T. Mills. She holds the '
                    'office until 2027-01-06.';
  END IF;

  -- 4. Her term is closed the day before the handover, and nowhere earlier.
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE id = 'c4132dc6-bcb0-40f1-b26d-47adc4012ede' AND term_end = p.expect_term_start - 1;
  IF n <> 1 THEN
    RAISE EXCEPTION '4: Janet Mills'' term is not closed at %.', p.expect_term_start - 1;
  END IF;

  -- 5. 🔴 THE LEGISLATURE WAS NOT GIVEN THE GOVERNOR'S DATE. 183 seats start 2026-12-01 under a
  --    different article; this file must not have reached them.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % Maine legislative seat(s) were given the Governor''s January date.', n;
  END IF;

  -- 6. This file creates no people.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '6: politicians moved from % to %.', b.politicians, n;
  END IF;

  -- 7. Repo-wide, exactly one office_terms row was added, and one more starts that day.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + 1 THEN
    RAISE EXCEPTION '7: office_terms went % -> %, expected a delta of 1.', b.terms_all, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + 1 THEN
    RAISE EXCEPTION '7: terms starting % went % -> %, expected a delta of 1.',
      p.expect_term_start, b.terms_on_the_day, n;
  END IF;

  -- 8. The new term cites this migration (Ruling B: recoverable by slot).
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE office_id = '95700fc5-2800-4766-9005-38dc7237c455'
     AND term_start = p.expect_term_start AND source LIKE '%CC_0476%';
  IF n <> 1 THEN
    RAISE EXCEPTION '8: the new term does not cite CC_0476.';
  END IF;

  -- 9. The seat has left the pending-winner view.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0476_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '9: the Governor still answers office_pending_winner.';
  END IF;

  -- 10. The 238 unflagged drift baseline did not move. 🔴 NEVER RAISE IT.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '10: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  RAISE NOTICE 'CC_0476 OK: Hannah Pingree scheduled for 2027-01-06; Janet T. Mills closed at '
               '2027-01-05 and still Governor today; the legislature''s 2026-12-01 wave '
               'untouched; drift baseline % held.', b.missing_unflagged;
END $$;

COMMIT;
