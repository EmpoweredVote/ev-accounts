-- CC_0471 — Hawaii: schedule the Governor and Lieutenant Governor for the term that begins at
-- noon on 2026-12-07.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THIS IS THE NEAREST FUTURE DEADLINE ANYWHERE IN THE STATE SEATING PASS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Haw. Const. art. V, § 1: "The term of office of the governor shall begin at NOON ON THE FIRST
-- MONDAY IN DECEMBER next following the governor's election". Art. V, § 2 elects the lieutenant
-- governor "at the same time, FOR THE SAME TERM and in the same manner as the governor", so one
-- clause carries both offices. The first Monday in December 2026 is 2026-12-07.
--
--   Governor              Josh Green        re-elected
--   Lieutenant Governor   Derek Kawakami    SUCCEEDS Sylvia Luke
--
-- ⚠ "AT NOON" IS NOT WRITTEN DOWN, BECAUSE IT CANNOT BE. `office_terms.term_start` is a DATE.
--   The column records the day a term begins; the hour is in the authority text on the
--   `office_swearing_in` row CC_0469 wrote, where it can be read rather than silently dropped.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 A FUTURE-DATED SEATING MUST NOT MOVE A SEAT TODAY, AND THIS ONE CONTAINS A HANDOVER
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes the predecessor at `term_start - 1` = 2026-12-06, which is still in
-- the future, so `office_current_holder` — whose predicate is "the term covering CURRENT_DATE" —
-- keeps answering SYLVIA LUKE for the Lieutenant Governor until the morning of the 7th, and Josh
-- Green for the Governor throughout. Assertion 4 pins the nationwide holder map unchanged and
-- assertion 5 names the two offices explicitly, because "the digest did not move" and "these two
-- seats answer with the right person today" are different claims and the second is the one a
-- voter sees.
--
-- ⚠ `is_vacant` IS LEFT ALONE, DELIBERATELY. Neither office is flagged (P6 asserts it), and for
--   a future seating the flag must not be touched even if it were: the seat really is held by
--   somebody else until that morning. This is the opposite of CC_0470, which seats a term that
--   has already begun.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SELECTION IS PINNED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   winners 2 · offices 2 · re-elections 1 · new holders 1
--   digest md5 = 8eaf0d3a4b755798f9e7af196bd51421   (captured 2026-11-23 against production)
--   called 2 · certified 0 on the day this was captured (Ruling B)
--
-- The date is read from `essentials.office_swearing_in`, written by CC_0469. P4 refuses unless
-- both agree on 2026-12-07 with a basis of statute or published.
--
-- 🔴 THE SELECTION IS NARROWED BY TITLE BECAUSE HAWAII IS TWO WAVES. The other three pending
--    `hi · STATE_EXEC` offices are OHA trustees whose terms began on 2026-11-03 — twenty days
--    ago, under a different instrument. `classifyWave` raises `date_disagrees` for exactly this
--    reason, and two dates in one file would seat half its rows on the wrong day.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes each predecessor with an unguarded
-- `UPDATE office_terms SET term_end = p_term_start - 1` and records nothing about the row it
-- overwrote. Both predecessors carry `term_end = NULL` and `how_ended = NULL`, measured against
-- production 2026-11-23:
--
--   Governor              term 6e7ad4da-db1f-4e55-a39d-338c821a8eec  Josh Green    start 2022-12-05
--   Lieutenant Governor   term fdc164da-f369-4fa7-ae17-8e316acbd3c1  Sylvia Luke   start NULL
--
-- 🟢 GOVERNOR GREEN'S RECORDED START IS ALSO THE CONTROL ON THE CLAUSE. 2022-12-05 is the first
--    Monday in December 2022 — the same formula, a different cycle, a row written from an
--    unrelated source. CC_0469 asserts that agreement; this file inherits it.
-- ⚠ SYLVIA LUKE'S TERM HAS NO START, so closing it writes an end onto a row with no beginning.
--   That is correct and is not this file's to fix: a tenure start is a different fact from a
--   term start.

BEGIN;

CREATE TEMP TABLE cc0471_pin ON COMMIT DROP AS
SELECT 2                                  AS expect_winners,
       2                                  AS expect_offices,
       1                                  AS expect_reelections,
       1                                  AS expect_new,
       '8eaf0d3a4b755798f9e7af196bd51421' AS expect_digest,
       DATE '2026-12-07'                  AS expect_term_start;
-- winners = offices here, so the two pins are equal. They are NOT in general.

-- 🔴 WAVE_SELECTION_SQL, column for column, NARROWED BY TITLE — Hawaii ships as two waves.
CREATE TEMP TABLE cc0471_sel ON COMMIT DROP AS
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
 WHERE lower(d.state) = 'hi'
   AND d.district_type = 'STATE_EXEC'
   AND o.title IN ('Governor', 'Lieutenant Governor')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0471_pre ON COMMIT DROP AS
SELECT s.office_id, s.title, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0471_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0471_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2026-12-07')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM cc0471_pre)                                           AS predecessors,
       (SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-'),
                              '|' ORDER BY office_id::text))
          FROM essentials.office_current_holder)                                   AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged;

DO $$
DECLARE n bigint; d text; p record;
BEGIN
  SELECT * INTO p FROM cc0471_pin;

  SELECT count(*) INTO n FROM cc0471_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: selection returned % winner rows, expected %. The data moved under '
                    'this file.', n, p.expect_winners;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0471_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %.', d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0471_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-election(s), expected %. One of these two has stopped being the '
                    'case this file was written for.', n, p.expect_reelections;
  END IF;

  -- P2 — this file has not already been applied. Above the rest on purpose: on a second run the
  -- two seats have left office_pending_winner, so P1 would report 0 rows and blame the data.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0471%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0471. Applied before.', n;
  END IF;

  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0471_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner.', n;
  END IF;

  -- P4 — 🔴 ONE DATE, AND IT IS DECEMBER'S. If an OHA row reached this selection it would bring
  --    2026-11-03 with it, and half this file would seat on the wrong day.
  SELECT count(*) INTO n FROM cc0471_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. CC_0469 '
                    'writes it, and Hawaii''s other pending body starts on 2026-11-03.',
      n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0471_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0471_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat.', n;
  END IF;

  -- P6 — 🔴 NEITHER OFFICE IS FLAGGED VACANT, AND A FUTURE SEATING MUST NOT CLEAR THE FLAG
  --    ANYWAY. Both seats are genuinely held until the morning of the 7th. This asserts there is
  --    nothing to decide rather than deciding it silently.
  SELECT count(*) INTO n
    FROM cc0471_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) are flagged is_vacant. A future-dated seating leaves the flag '
                    'alone, so a flag that is already wrong must be settled in its own file.', n;
  END IF;

  -- P7 — the pre-image is complete and both predecessors are open.
  SELECT count(*) INTO n FROM cc0471_pre;
  IF n <> 2 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) captured, expected 2 (one per seat).', n;
  END IF;

  SELECT count(*) INTO n FROM cc0471_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing.', n;
  END IF;

  -- P8 — the handover is the one this file names. The LG seat must currently answer with Sylvia
  -- Luke and must be won by Derek Kawakami; the Governor must be Josh Green on both sides.
  SELECT count(*) INTO n FROM cc0471_sel
   WHERE (title = 'Governor'
          AND politician_id = '76307cf7-47dd-4b0a-ac4b-ed218095bf47'
          AND holder_before = '76307cf7-47dd-4b0a-ac4b-ed218095bf47')
      OR (title = 'Lieutenant Governor'
          AND politician_id = 'e9c692d8-1fe8-41a0-bead-8bb40981874e'
          AND holder_before = 'bb3cfd1d-42a2-41c2-978d-c1d1734be93f');
  IF n <> 2 THEN
    RAISE EXCEPTION 'P8: only % of the 2 seats match the people this file was written about '
                    '(Green holding and re-elected; Kawakami succeeding Luke).', n;
  END IF;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK A — the incumbency guard, from migrations/_templates/office_terms_incumbency_guard.sql
-- ═════════════════════════════════════════════════════════════════════════════════════════════
--
-- @incumbency-decision: gated — this closes each predecessor term at 2026-12-06, which is AFTER
-- the election, so the outgoing term still covers 2026-11-03 and the predicate's answer must not
-- move for anybody. The scope covers both sides of the seating: the two winners and the two
-- people whose terms are closed, which here is three people, because Sylvia Luke is leaving.
CREATE TEMP TABLE cc0471_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0471_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0471_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0471_guarded);

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0471_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran; term begins at noon on '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in, "at noon on the first Monday in '
                         || 'December next following the governor''s election" (Haw. Const. '
                         || 'art. V §1; §2 gives the lieutenant governor the same term). The '
                         || 'hour is not representable in a DATE column and is recorded in the '
                         || 'office_swearing_in authority. '
                         || CASE WHEN r.is_reelection THEN 'Re-elected incumbent. '
                                 ELSE 'New holder; predecessor closed at 2026-12-06. ' END
                         || 'CC_0471',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0471: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0471_guarded;
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
  SELECT * INTO b FROM cc0471_before;
  SELECT * INTO p FROM cc0471_pin;

  -- 1. Two new terms, one per selected office, on the day itself, naming the winner.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0471_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start, p.expect_offices;
  END IF;

  -- 2. office_next_term answers for both — the view a voter's page reads for a dated handover.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0471_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_offices;
  END IF;

  -- 3. Repo-wide, exactly two more terms start on that day — no other state swept in.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_offices THEN
    RAISE EXCEPTION '3: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;

  -- 4. 🔴 NOBODY WAS UNSEATED TODAY, ANYWHERE IN THE COUNTRY. A future-dated term must not move
  --    a seat now, and this wave contains a real handover, so the assertion has something to
  --    catch: write 2026-11-03 here by mistake and Sylvia Luke leaves office this afternoon.
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-'),
                        '|' ORDER BY office_id::text))
    INTO m FROM essentials.office_current_holder;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today.', b.holders_md5, m;
  END IF;

  -- 5. 🔴 AND THE TWO SEATS THEMSELVES STILL ANSWER WITH TODAY'S HOLDERS, BY NAME. "The digest
  --    did not move" and "these two offices read correctly" are different claims, and the second
  --    is what a voter sees. Sylvia Luke is still Lieutenant Governor until the 7th.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0471_sel s ON s.office_id = och.office_id
   WHERE och.politician_id = s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of % seats still answer office_current_holder with the person holding '
                    'them today.', n, p.expect_offices;
  END IF;

  -- 6. Each predecessor named in the pre-image is closed the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0471_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0471_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 7. No term of these seats was closed between today and the handover, which would leave a
  --    fortnight with nobody in the office.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0471_sel s ON s.office_id = t.office_id
   WHERE t.term_end IS NOT NULL
     AND t.term_end >= CURRENT_DATE AND t.term_end < p.expect_term_start - 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % term(s) closed between today and the day before the handover.', n;
  END IF;

  -- 8. 🔴 HAWAII'S OTHER WAVE WAS NOT TOUCHED. The three OHA offices start on 2026-11-03 under a
  --    different instrument; if the title filter ever stopped excluding them this says so.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
   WHERE o.title LIKE 'Office of Hawaiian Affairs%' AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % OHA trustee(s) were given the December date. Their term began '
                    '2026-11-03 under HRS §13D-5.', n;
  END IF;

  -- 9. This file creates no people and no offices.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '9: politicians moved from % to %.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '9: offices moved from % to %.', b.offices, n;
  END IF;

  -- 10. Repo-wide, exactly two office_terms rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '10: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 11. Every new term cites this migration (Ruling B: recoverable by slot).
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0471_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0471%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '11: % of % new terms cite CC_0471.', n, p.expect_offices;
  END IF;

  -- 12. 🔴 THE SEATS HAVE LEFT THE PENDING-WINNER VIEW, so the card stops reading as a declared
  --     result and starts reading as a dated handover.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0471_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '12: % seat(s) still answer office_pending_winner.', n;
  END IF;

  -- 13. The 238 unflagged drift baseline did not move. 🔴 NEVER RAISE IT.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '13: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  RAISE NOTICE 'CC_0471 OK: Hawaii Governor and Lieutenant Governor scheduled for % (1 '
               're-election, 1 handover), % predecessors closed at %, nobody moved today, the '
               'OHA wave untouched, drift baseline % held.',
    p.expect_term_start, b.predecessors, p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
