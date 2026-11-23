-- CC_0484 — Massachusetts: schedule the Governor and Lieutenant Governor for the term that
-- begins at noon on 2027-01-07.
--
-- Mass. Const. Amend. Art. LXIV § 1, as appearing in Amend. Art. LXXXII: "The terms of the
-- governor and lieutenant-governor shall begin AT NOON ON THE THURSDAY NEXT FOLLOWING THE FIRST
-- WEDNESDAY IN JANUARY succeeding their election." The first Wednesday in January 2027 is the
-- 6th, so the Thursday next following it is **2027-01-07**. CC_0481 recorded that date against
-- both offices; this file reads it and writes the terms.
--
-- 🔴🔴 **ONE DAY AFTER THE LEGISLATURE AND THIRTEEN DAYS BEFORE THE OTHER THREE EXECUTIVES.**
--     The same sentence-group names three days: legislators 2027-01-06 (`CC_0483`), these two
--     2027-01-07, and the Attorney General, Treasurer and Auditor 2027-01-20 (`CC_0485`).
--     Assertions 7 and 8 refuse if this file reached any of the other eight seats.
--
-- ⚠ **"AT NOON" IS IN THE CLAUSE AND NOT IN THE COLUMN.** `essentials.office_swearing_in` and
--   `essentials.office_terms` carry a date, not a time, so the hour lives in the `source` text.
--   Massachusetts is the second state in this pass to name an hour — Hawaii's `art. V` does the
--   same for its executives — and in both the day is what we record.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SELECTION IS PINNED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   winners 2 · offices 2 · re-elections 2 · new holders 0 · predecessors 2
--   digest md5 = 4589212d21100b14e01a0a6c9398322a   (captured 2026-11-23 against production,
--                                                    after CC_0481 and CC_0482)
--   called 2 · certified 0 on the day this was captured (Ruling B)
--
--     Governor              Maura Healey    re-elected
--     Lieutenant Governor   Kim Driscoll    re-elected
--
-- 🟢 **BOTH ARE RE-ELECTIONS, SO NOBODY IS UNSEATED AND NOBODY IS CREATED.** That makes this the
--    simplest wave in Massachusetts and the one where a wrong DATE would be hardest to notice:
--    the page would name the right person either way. ▶ The date is therefore the only thing
--    worth gating hard, and P4 and P8 are where it is gated.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢🟢 THE CONTROL IS EXACT, AND IT COMES FROM A PASS THAT NEVER READ THIS CLAUSE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `essentials.office_terms` already holds Maura Healey's current term starting **2023-01-05**,
-- backfilled by migration 1459 from `offices.politician_id`. The same clause, applied to the 2022
-- cycle, gives the Thursday next following the first Wednesday in January 2023 — the 4th — which
-- is **2023-01-05**. P8 computes that from the rule and checks it against her recorded row, so
-- the formula is measured against a date this file does not write.
--
-- ⚠ Kim Driscoll's row carries **no `term_start` at all** (`start_precision = 'unknown'`), as do
--   four of Massachusetts' six statewide executives. Only the Governor's is dated, which is why
--   the control rests on one row rather than two.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes each predecessor with an UNGUARDED
-- `UPDATE office_terms SET term_end = p_term_start - 1` and writes nothing to that row's
-- `source`. Both predecessors here are the SAME PEOPLE being re-elected, so each one's current
-- term is closed at **2027-01-06** and a new one opened the next day.
--
--   🔴 BOTH PREDECESSOR TERMS CARRY `term_end = NULL` AND `how_ended = NULL`. Measured against
--      production 2026-11-23. Healey's carries `term_start = 2023-01-05`; Driscoll's carries
--      NULL. P7 refuses unless both are open, and assertion 4 counts the rows closed.
--
-- ⚠ CLOSING A RE-ELECTED OFFICIAL'S TERM AND OPENING A NEW ONE IS THE INTENDED BEHAVIOUR, not a
--   handover: `p_allow_reelection => true` is what permits it, and without it `seat_officeholder`
--   refuses outright.

BEGIN;

CREATE TEMP TABLE cc0484_pin ON COMMIT DROP AS
SELECT 2                                  AS expect_winners,
       2                                  AS expect_offices,
       2                                  AS expect_reelections,
       0                                  AS expect_new,
       2                                  AS expect_predecessors,
       '4589212d21100b14e01a0a6c9398322a' AS expect_digest,
       DATE '2027-01-07'                  AS expect_term_start;

-- 🔴 `WAVE_SELECTION_SQL` with the same addition CC_0483 makes: `och.politician_id IS NOT NULL`
--    keeps `is_reelection` a real boolean. Neither of these two seats is empty, so it changes
--    nothing here — it is carried so the Massachusetts files read alike and a later edit cannot
--    reintroduce the NULL.
CREATE TEMP TABLE cc0484_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       (win.value ->> 'id')::uuid                        AS politician_id,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id IS NOT NULL
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
 WHERE lower(d.state) = 'ma'
   AND d.district_type = 'STATE_EXEC'
   AND o.title IN ('Governor', 'Lieutenant Governor')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0484_pre ON COMMIT DROP AS
SELECT s.office_id, s.title, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0484_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0484_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-07')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0484_pre)                                           AS predecessors,
       (SELECT md5(string_agg(och.office_id::text || ':'
                              || COALESCE(och.politician_id::text, '-'),
                              '|' ORDER BY och.office_id::text))
          FROM essentials.office_current_holder och)                               AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged;

DO $$
DECLARE n bigint; d text; p record; fw date;
BEGIN
  SELECT * INTO p FROM cc0484_pin;

  -- P2 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE THE ROW COUNTS.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0484%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0484. Applied before.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0484_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: selection returned % winner rows, expected %. The data moved under '
                    'this file.', n, p.expect_winners;
  END IF;

  SELECT count(DISTINCT office_id) INTO n FROM cc0484_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P1: % offices, expected %.', n, p.expect_offices;
  END IF;

  SELECT count(*) INTO n FROM cc0484_sel
   WHERE title NOT IN ('Governor', 'Lieutenant Governor');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % seat(s) in this wave are not the Governor or Lieutenant Governor.', n;
  END IF;

  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0484_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: the digest expression evaluated to NULL on % of % rows.',
      p.expect_winners - n, p.expect_winners;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0484_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %. The data moved under this file.',
      d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0484_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected % (Healey and Driscoll are both returning). '
                    'If this is lower, somebody is being unseated and this file''s header is '
                    'wrong about the wave.', n, p.expect_reelections;
  END IF;

  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0484_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner. Neither of these is a '
                    'multi-member seat.', n;
  END IF;

  -- P4 — 🔴🔴 THE DATE IS READ, NEVER CARRIED, AND MASSACHUSETTS HAS THREE OF THEM. A literal
  --    here would agree with itself while belonging to another group.
  SELECT count(*) INTO n FROM cc0484_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. CC_0481 '
                    'writes it. ⚠ If one reads 2027-01-06 a legislative row has reached this '
                    'selection; if 2027-01-20, a third-Wednesday officer has.',
      n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0484_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0484_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat.', n;
  END IF;

  -- P6 — neither seat is flagged vacant. Both are held today.
  SELECT count(*) INTO n
    FROM cc0484_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % of these two seats are flagged is_vacant. Both are held today, so a '
                    'flag here is a fact nobody has read.', n;
  END IF;

  -- P7 — the pre-image is complete and every predecessor is open.
  SELECT count(*) INTO n FROM cc0484_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) captured, expected % (one per seat).',
      n, p.expect_predecessors;
  END IF;

  SELECT count(*) INTO n FROM cc0484_pre WHERE term_end IS NOT NULL OR how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a term_end or a how_ended. '
                    'seat_officeholder overwrites the first without a guard and COALESCEs the '
                    'second, so this file would destroy or mask a value it has not written '
                    'down.', n;
  END IF;

  -- P8 — 🟢🟢 THE CLAUSE EVALUATED AS WRITTEN, FOR A CYCLE THIS FILE DOES NOT WRITE, AGAINST A
  --    TERM ALREADY IN THE DATABASE. The Thursday next following the first Wednesday in January
  --    2023 is 2023-01-05, and that is Maura Healey's recorded term_start — written by a pass
  --    that never read this clause.
  SELECT DATE '2027-01-01' + ((10 - EXTRACT(ISODOW FROM DATE '2027-01-01'))::int % 7) INTO fw;
  IF fw + 1 <> p.expect_term_start THEN
    RAISE EXCEPTION 'P8: the Thursday next following the first Wednesday in January 2027 '
                    'computes as %, not %.', fw + 1, p.expect_term_start;
  END IF;

  SELECT DATE '2023-01-01' + ((10 - EXTRACT(ISODOW FROM DATE '2023-01-01'))::int % 7) INTO fw;
  IF fw + 1 <> DATE '2023-01-05' THEN
    RAISE EXCEPTION 'P8: the same formula gives % for the 2022 cycle, but the Thursday next '
                    'following the first Wednesday in January 2023 was the 5th. The formula is '
                    'wrong.', fw + 1;
  END IF;

  SELECT count(*) INTO n
    FROM cc0484_pre x WHERE x.title = 'Governor' AND x.term_start = fw + 1;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P8: the Massachusetts Governor''s open term does not start %, which is what '
                    'this clause gives for the 2022 cycle. The clause that dates 2027-01-07 '
                    'should also explain the term already in the database, and it does not.',
      fw + 1;
  END IF;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK A — the incumbency guard, from migrations/_templates/office_terms_incumbency_guard.sql
-- ═════════════════════════════════════════════════════════════════════════════════════════════
--
-- @incumbency-decision: gated — this closes each predecessor at 2027-01-06, well after the
-- election, so both outgoing terms still cover 2026-11-03 and the predicate's answer must not
-- move. ⚠ Both people are on BOTH sides of this wave, since both are re-elected; the UNION keeps
-- each counted once.
CREATE TEMP TABLE cc0484_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0484_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0484_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0484_guarded);

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0484_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' AT NOON per essentials.office_swearing_in, "the terms of the '
                         || 'governor and lieutenant-governor shall begin at noon on the '
                         || 'Thursday next following the first Wednesday in January succeeding '
                         || 'their election" (Mass. Const. Amend. Art. LXIV § 1, as appearing in '
                         || 'Amend. Art. LXXXII). The hour is in the clause; this column carries '
                         || 'a date. NOTE: this is ONE DAY AFTER the legislature (2027-01-06) '
                         || 'and THIRTEEN DAYS BEFORE the Attorney General, Treasurer and '
                         || 'Auditor (2027-01-20) — one sentence-group, three days. '
                         || 'Re-elected incumbent; the previous term is closed at 2027-01-06. '
                         || 'CC_0484',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0484: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0484_guarded;
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
  SELECT * INTO b FROM cc0484_before;
  SELECT * INTO p FROM cc0484_pin;

  -- 1. Two new terms, on the day itself, naming the winners.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0484_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. office_next_term answers for both — the view a voter's page reads for a dated handover.
  --    ⚠ Worth asserting even though both are re-elections: the page must say the sitting
  --    governor continues ON A DATE, not that nothing happens.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0484_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_offices;
  END IF;

  -- 3. 🔴 NOBODY WAS UNSEATED TODAY, ANYWHERE, and both seats still answer with their holder.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '3: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today.', b.holders_md5, m;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0484_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '3: % of % seats still answer office_current_holder with today''s holder.',
      n, p.expect_offices;
  END IF;

  -- 4. Each predecessor named in the pre-image is closed the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0484_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '4: % predecessor term(s) closed at %, expected %.',
      n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 5. 🔴 EACH OFFICIAL NOW HOLDS EXACTLY ONE OPEN TERM ON THEIR OWN OFFICE. A re-election
  --    closes a term and opens another on the SAME seat, which is the one shape that can leave
  --    somebody holding two overlapping terms if the close did not land.
  SELECT count(*) INTO n
    FROM cc0484_sel s
   WHERE (SELECT count(*) FROM essentials.office_terms t
           WHERE t.office_id = s.office_id AND t.politician_id = s.politician_id
             AND t.term_end IS NULL) <> 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % of the two officials do not hold exactly one open term on their own '
                    'office. A re-election must close the old term, not run two at once.', n;
  END IF;

  -- 6. Repo-wide, exactly 2 more terms start that day and exactly 2 rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_offices THEN
    RAISE EXCEPTION '6: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;

  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '6: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 7. 🔴🔴 THE LEGISLATURE WAS NOT GIVEN THIS DATE. 199 seats begin 2027-01-06, one day
  --    earlier, under the same sentence-group; CC_0483 seats them.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ma' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % Massachusetts legislative seat(s) were given the governor''s date.', n;
  END IF;

  -- 8. 🔴🔴 AND NEITHER WERE THE THIRD-WEDNESDAY OFFICERS. The Attorney General, Treasurer and
  --    Auditor begin 2027-01-20 — thirteen days later — and the Secretary of the Commonwealth
  --    has no 2026 result at all.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ma' AND d.district_type = 'STATE_EXEC'
     AND o.title IN ('Attorney General', 'Treasurer and Receiver-General',
                     'Auditor of the Commonwealth', 'Secretary of the Commonwealth')
     AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % third-Wednesday officer(s) were given the governor''s date. They begin '
                    '2027-01-20.', n;
  END IF;

  -- 9. This file creates no people and no offices, and moves no vacancy flag.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '9: politicians moved from % to %.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '9: offices moved from % to %.', b.offices, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '9: the repo-wide count of flagged-vacant offices moved % -> %.',
      b.vacant_all, n;
  END IF;

  -- 10. Both new terms cite this migration (Ruling B: recoverable by slot).
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0484_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0484%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '10: % of % new terms cite CC_0484.', n, p.expect_offices;
  END IF;

  -- 11. The seats have left the pending-winner view.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0484_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '11: % seat(s) still answer office_pending_winner.', n;
  END IF;

  -- 12. The 238 unflagged drift baseline did not move. 🔴 NEVER RAISE IT.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '12: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  RAISE NOTICE 'CC_0484 OK: Massachusetts'' Governor and Lieutenant Governor scheduled for % at '
               'noon (both re-elections; their current terms close %), one day after the '
               'legislature and thirteen before the Attorney General, Treasurer and Auditor; '
               'the clause was controlled against Healey''s recorded 2023-01-05; nobody moved '
               'today, drift baseline % held.',
    p.expect_term_start, p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
