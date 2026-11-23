-- CC_0467 — Nevada Assembly and Senate: seat all 52 winners, whose terms began 2026-11-04.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THIS WAVE IS NINETEEN DAYS LATE, AND THIRTEEN SEATS CHANGE HANDS THE MOMENT IT COMMITS.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Nev. Const. art. 4 §§ 3(1) and 4(1) begin a legislator's term "from the day next after their
-- election" — 2026-11-04. CC_0465 recorded that date against all 52 offices; this file reads it
-- and writes the terms. `office_current_holder` recomputes from them on commit, so 13 Nevada
-- districts stop naming their predecessor and start naming the member who actually holds the
-- seat today.
--
-- ⚠ THIS IS THE SECOND PAST-DATED WAVE IN THE PASS AND THE FIRST ONE THAT MOVES ANYBODY.
--   CC_0464 (Indiana, three seats) could assert that the nationwide current-holder map did not
--   change at all, because all three of its rows were re-elections — the term that closed and
--   the term that opened named the same person. 🔴 THAT ASSERTION CANNOT BE COPIED HERE AND
--   COPYING IT WOULD HAVE BEEN THE DEFECT: 13 of these 52 are handovers, so the map MUST move,
--   and it must move by EXACTLY THIRTEEN SEATS. Assertion 4 below measures the delta instead of
--   pinning the digest, and names every seat that moved when it does not.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SELECTION IS PINNED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   winners 52 · offices 52 · re-elections 39 · new holders 13
--   digest md5 = 0f36fd795e0edf36a798b23e3e25bbcf   (captured 2026-11-23 against production)
--   called 52 · certified 0 on the day this was captured (Ruling B)
--
-- 🔴 THAT DIGEST IS THE POST-CC_0466 ONE. Before CC_0466 links the thirteen unheld winners the
--    same selection digests to `105c6c7d4b55da5c6d8bf93eb024c3e8`, because `office_pending_winner`
--    renders a winner with no person record as a NULL id. ▶ IF P1 REPORTS THAT VALUE, CC_0466
--    HAS NOT BEEN APPLIED — that is not the data moving, it is the files running out of order,
--    and the two failures look identical from the error message alone. The ids CC_0466 writes
--    are fixed literals in that file precisely so this pin could be computed before it ran.
--
-- The date is read from `essentials.office_swearing_in`, written by CC_0465. P4 refuses unless
-- all 52 agree on 2026-11-04 with a basis of statute or published. A literal date here would
-- agree with itself however wrong it was.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES, AND THE VALUE IT IS OVERWRITING
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `essentials.seat_officeholder` closes each predecessor with an UNGUARDED
-- `UPDATE office_terms SET term_end = p_term_start - 1`, and writes nothing to that row's
-- `source`. So the 52 new terms are recoverable by slot and the 52 CLOSURES are not — undoing
-- one would mean restoring a `term_end` that no file recorded. `CLAUDE.md` requires a migration
-- that overwrites a value to record it, so:
--
--   🔴 ALL 52 PREDECESSOR TERMS CARRY `term_end = NULL` AND `how_ended = NULL`, and all 52 also
--      carry `term_start = NULL`. Measured against production 2026-11-23, and NOT inferred the
--      way REGISTER.md had to infer it for the first four waves. The full pre-image
--      (office_id, term_id, politician_id, term_start, term_end, how_ended) is captured into
--      `cc0467_pre` below, P7 refuses unless every `term_end` in it is NULL, and the post-verify
--      prints the count it closed.
--
--   ⚠ `term_end` IS INCLUSIVE, so a predecessor closed at 2026-11-03 still COVERS 2026-11-03 and
--     each outgoing member still held the seat on the day of the election. That is the reasoning
--     the incumbency guard below is asked to measure.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ TWO NEVADA SEATS ARE WRONG ON OUR PAGES AND THIS FILE CANNOT REACH EITHER
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   • ASSEMBLY DISTRICT 22 — we show Melissa R. Hardy; the Legislature shows Shenea Booth. The
--     2026 race EXISTS in our data with both candidates present and `result` NULL on both, so no
--     winner was ever recorded. 🔴 AN OFFICE WITH A RACE AND NO RESULT IS EXACTLY AS INVISIBLE
--     TO `office_pending_winner` AS AN OFFICE WITH NO RACE, which is why this reads as "41 of 42
--     Assembly seats were up" rather than as a defect.
--   • STATE SENATE DISTRICT 6 — we show Nicole J. Cannizzaro; the Legislature shows the seat
--     VACANT. SD6 carried no 2026 race at all, so it is correctly outside this wave.
--
-- Each needs its own file and its own sourcing. Neither is smuggled in here.

BEGIN;

CREATE TEMP TABLE cc0467_pin ON COMMIT DROP AS
SELECT 52                                 AS expect_winners,
       52                                 AS expect_offices,
       39                                 AS expect_reelections,
       13                                 AS expect_new,
       '0f36fd795e0edf36a798b23e3e25bbcf' AS expect_digest,
       DATE '2026-11-04'                  AS expect_term_start;
-- winners = offices here, so the two pins are equal. They are NOT in general.

-- 🔴 THIS SELECTION IS `scripts/lib/seating-wave.mjs`'s WAVE_SELECTION_SQL, column for column.
CREATE TEMP TABLE cc0467_sel ON COMMIT DROP AS
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
 WHERE lower(d.state) = 'nv'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND w.election_date = DATE '2026-11-03';

-- 🔴 THE PRE-IMAGE OF EVERY TERM THIS FILE WILL CLOSE. seat_officeholder records nothing about
-- the row it overwrites, so this table IS the record. Keep it in the header's shape: office,
-- term, who, and the three columns the helper touches or depends on.
CREATE TEMP TABLE cc0467_pre ON COMMIT DROP AS
SELECT s.office_id, s.seat, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0467_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0467_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2026-11-04')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM cc0467_pre)                                           AS predecessors,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged,
       -- 🔴 THE WHOLE-REPO HOLDER MAP, MINUS THE 52 SEATS THIS FILE TOUCHES. CC_0464 could pin
       -- the map whole because nobody changed seats; 13 people change seats here, so pinning it
       -- whole would fire every time and say nothing. Excluding exactly the 52 keeps the
       -- assertion's real job — proving no OTHER seat moved — and hands the 52 to assertion 4,
       -- which counts them.
       (SELECT md5(string_agg(och.office_id::text || ':'
                              || COALESCE(och.politician_id::text, '-'),
                              '|' ORDER BY och.office_id::text))
          FROM essentials.office_current_holder och
         WHERE och.office_id NOT IN (SELECT office_id FROM cc0467_sel))            AS holders_elsewhere_md5;

DO $$
DECLARE n bigint; d text; p record;
BEGIN
  SELECT * INTO p FROM cc0467_pin;

  SELECT count(*) INTO n FROM cc0467_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: selection returned % winner rows, expected %. The data moved under '
                    'this file.', n, p.expect_winners;
  END IF;

  SELECT count(DISTINCT office_id) INTO n FROM cc0467_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P1: % offices, expected %.', n, p.expect_offices;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0467_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    IF d = '105c6c7d4b55da5c6d8bf93eb024c3e8' THEN
      RAISE EXCEPTION 'P1: the selection digest is the PRE-CC_0466 value. The thirteen unheld '
                      'winners have no politician row yet, so this is the files running out of '
                      'order, not the data moving. Apply CC_0466 first.';
    END IF;
    RAISE EXCEPTION 'P1: selection digest is %, expected %.', d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0467_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected %. The split between re-elections and '
                    'handovers is what assertion 4 counts, so this changes what this file does.',
      n, p.expect_reelections;
  END IF;

  -- P2 — this file has not already been applied. Asked ABOVE P3 and the rest on purpose: on a
  -- second run the 52 have left office_pending_winner, so P1 would report 0 rows and tell the
  -- operator the data moved, when what happened is that they ran it twice. (Measured on
  -- CC_0461 and CC_0462, which both carry this check too late to fire.)
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0467%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0467. Applied before.', n;
  END IF;

  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0467_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner. Nevada has no multi-seat '
                    'legislative district, so this is Ruling A arriving where it was not '
                    'expected — stop and read the race.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0467_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. CC_0465 '
                    'writes it.', n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0467_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published. An '
                    'estimate may not seat anybody.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0467_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat. CC_0466 creates twelve and '
                    'links one.', n;
  END IF;

  -- P6 — nothing here is flagged vacant, so this file has no flag to clear. A term that has
  -- already begun is the one case where clearing would be correct, and asserting there is
  -- nothing to clear is cheaper than clearing nothing and hoping.
  SELECT count(*) INTO n
    FROM cc0467_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) are flagged is_vacant. A term that began nineteen days ago '
                    'means the flag is wrong; decide each one before seating it.', n;
  END IF;

  -- P7 — 🔴 THE PRE-IMAGE IS COMPLETE AND SAYS WHAT THE HEADER SAYS. One predecessor per seat,
  --    and every one of them open. If a predecessor were already closed, this file would
  --    overwrite a real date with 2026-11-03 and no record of the old one would survive.
  SELECT count(*) INTO n FROM cc0467_pre;
  IF n <> 52 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) captured, expected 52 (one per seat).', n;
  END IF;

  SELECT count(*) INTO n FROM cc0467_pre WHERE term_end IS NOT NULL;
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
-- @incumbency-decision: gated — this closes each predecessor term at 2026-11-03, which IS the
-- election day, so the gate is asked properly rather than argued away.
--
-- 🔴 THE SCOPE COVERS BOTH SIDES OF THE SEATING, AND HERE THAT IS TWO DIFFERENT SETS OF PEOPLE.
-- CC_0464's plan table listed only the people it seated, which was sound there because all
-- three of its rows were re-elections and the two sides were the same person. 13 of these are
-- handovers, so the OUTGOING members are added as well: they are the ones whose `is_incumbent`
-- could be made to contradict `office_terms` by a closure.
CREATE TEMP TABLE cc0467_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0467_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0467_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0467_guarded);

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0467_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in, "from the day next after their '
                         || 'election" ('
                         || CASE r.district_type WHEN 'STATE_LOWER'
                              THEN 'Nev. Const. art. 4 §3(1)' ELSE 'Nev. Const. art. 4 §4(1)' END
                         || '). '
                         || CASE WHEN r.is_reelection THEN 'Re-elected incumbent. '
                                 ELSE 'New holder; predecessor closed at 2026-11-03. ' END
                         || 'CC_0467',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0467: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0467_guarded;
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
DECLARE n bigint; m text; b record; p record; v_detail text;
BEGIN
  SELECT * INTO b FROM cc0467_before;
  SELECT * INTO p FROM cc0467_pin;

  -- 1. 52 new terms, one per selected office, on the day itself, naming the winner.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0467_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start, p.expect_offices;
  END IF;

  -- 2. 🔴 NOT office_next_term — THIS TERM STARTED NINETEEN DAYS AGO. The view is
  --    `term_start > CURRENT_DATE`, so these seats must NOT appear in it, and must answer
  --    office_current_holder instead. Both halves are asserted: checking only the second would
  --    pass for a seat that is also wrongly scheduled.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0467_sel s ON s.office_id = nx.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '2: % of these seats appear in office_next_term, but their term began % — '
                    'a term that has started is not a pending one.', n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0467_sel s ON s.office_id = och.office_id
   WHERE och.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_current_holder answers with the seated member for % of % seats.',
      n, p.expect_offices;
  END IF;

  -- 3. Nevada legislative terms starting that day went up by exactly 52, read as a delta
  --    against this transaction's own pre-image.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nv' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND t.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '3: % Nevada legislative terms start %, expected %.',
      n, p.expect_term_start, p.expect_offices;
  END IF;

  -- 4. 🔴🔴 EXACTLY THIRTEEN SEATS CHANGED HANDS, AND THEY ARE THE THIRTEEN THIS FILE SAID
  --    WOULD. This is CC_0464's assertion 4 rewritten for a wave that MOVES people: there the
  --    whole-repo holder digest had to be unchanged, because all three rows were re-elections.
  --    Copying that here would fire on a correct run and teach nothing. The delta is counted
  --    against the selection's own `holder_before`, and every disagreement is named.
  SELECT count(*), string_agg(format('    %s: was %s, now %s', s.seat,
                                     coalesce(s.holder_before::text, '(vacant)'),
                                     coalesce(och.politician_id::text, '(vacant)')), E'\n')
    INTO n, v_detail
    FROM cc0467_sel s
    LEFT JOIN essentials.office_current_holder och ON och.office_id = s.office_id
   WHERE och.politician_id IS DISTINCT FROM s.holder_before;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION E'4: % seat(s) changed holder, expected %.\n%',
      n, p.expect_new, coalesce(v_detail, '    (none)');
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0467_sel s ON s.office_id = och.office_id
   WHERE s.is_reelection AND och.politician_id IS DISTINCT FROM s.holder_before;
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % RE-ELECTED member(s) changed holder. A re-election must leave the seat '
                    'answering with the same person.', n;
  END IF;

  -- 5. 🔴 AND NOT ONE SEAT MOVED ANYWHERE ELSE IN THE REPO. The 52 are excluded from this
  --    digest, so it has nothing to do with Nevada and everything to do with the 13 handovers
  --    not having reached past them.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och
   WHERE och.office_id NOT IN (SELECT office_id FROM cc0467_sel);
  IF m IS DISTINCT FROM b.holders_elsewhere_md5 THEN
    RAISE EXCEPTION '5: the current-holder map moved OUTSIDE the 52 seats this file touches '
                    '(% -> %).', b.holders_elsewhere_md5, m;
  END IF;

  -- 6. Every predecessor captured in the pre-image is closed at 2026-11-03 — the election day
  --    itself, which it still covers, because term_end is inclusive.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0467_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0467_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 7. This file creates no people and no offices. CC_0466 made the twelve.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '7: politicians moved from % to %.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '7: offices moved from % to %.', b.offices, n;
  END IF;

  -- 8. Repo-wide, exactly 52 office_terms rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '8: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 9. Every new term cites this migration, so a reversed canvass is recoverable by slot
  --    (Ruling B) rather than from memory.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0467_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0467%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '9: % of % new terms cite CC_0467.', n, p.expect_offices;
  END IF;

  -- 10. The seats have left the pending-winner view, so the card stops reading as a declared
  --     result waiting for a date.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0467_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '10: % seat(s) still answer office_pending_winner.', n;
  END IF;

  -- 11. The 238 unflagged drift baseline did not move. 🔴 NEVER RAISE IT.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '11: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  RAISE NOTICE 'CC_0467 OK: 52 Nevada legislators seated from % (% re-elections, % handovers), '
               '% predecessors closed at %, no seat moved outside the 52, drift baseline % held.',
    p.expect_term_start, p.expect_reelections, p.expect_new, b.predecessors,
    p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
