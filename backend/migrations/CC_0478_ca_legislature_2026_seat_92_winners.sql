-- CC_0478 — California Assembly and Senate: schedule all 92 winners for the term that begins
-- 2026-12-07.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 FOURTEEN DAYS. THIS IS THE SECOND DECEMBER DEADLINE IN THE STATE SEATING PASS.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Cal. Const. art. IV, § 2(a)(3): "The terms of a Senator or a Member of the Assembly shall
-- commence on the first Monday in December next following her or his election." The first Monday
-- in December 2026 is the **7th**. CC_0477 recorded that date against all 92 offices; this file
-- reads it and writes the terms.
--
-- ⚠ California is a SAME-DAY state — art. IV, § 3(a) convenes the Legislature at noon on the
--   same Monday — so the Maine trap (term 12-01, convening 12-02) has no California equivalent
--   and there is no second date to confuse this one with. ▶ P4 still READS the date from
--   `office_swearing_in` rather than carrying a literal. A literal agrees with itself however
--   wrong it is, and that is not a property of Maine.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SELECTION IS PINNED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   winners 92 · offices 92 · re-elections 68 · new holders 24
--   digest md5 = 3c5becfefe95c6450eb4548f3cc036ec   (captured 2026-11-23 against production)
--   called 92 · certified 0 on the day this was captured (Ruling B)
--
-- 🟢 NO PEOPLE FILE PRECEDES THIS ONE. All 92 winners already have a `politicians` row, so
--    unlike Maine (`CC_0474` created 59 and linked 18) this digest does not move under a
--    predecessor migration. If P1 reports a different digest, the data really has moved.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE SELECTION DOES NOT COPY `WAVE_SELECTION_SQL` VERBATIM, AND THE ONE WORD IT ADDS IS
--     LOad-BEARING
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `scripts/lib/seating-wave.mjs` computes `is_reelection` as
--
--     ((win.value ->> 'id') IS NOT NULL AND och.politician_id::text = (win.value ->> 'id'))
--
-- 🔴 ON A SEAT WITH NO CURRENT HOLDER THAT EXPRESSION IS **NULL**, NOT FALSE. `och` is LEFT
--    JOINed, so a vacant seat gives `och.politician_id = NULL`, the comparison is NULL, and
--    `true AND NULL` is NULL. California is the first state in this pass to reach that branch:
--    Assembly District 3 and State Senate District 10 are both vacant.
--
-- 🔴🔴 AND A NULL THERE SILENTLY SHRINKS THE DIGEST. `'…' || NULL::text` is NULL, and
--     `string_agg` SKIPS NULL input — so the in-SQL digest expression the library publishes
--     would have been computed over **90 of the 92 rows**, dropping exactly the two seats whose
--     identity is least certain, while every count in P1 still read 92. Measured 2026-11-23:
--
--       as published, is_reelection NULL on 2 rows   md5 = 8f11f4f3c18a8026fefca528e922629d  (90 rows)
--       with the NULL closed to false                md5 = 3c5becfefe95c6450eb4548f3cc036ec  (92 rows)
--
--     The second is also what `derive-seating-wave.mjs` prints, because its JS digest renders a
--     NULL boolean as 'false'. ▶ **The SQL digest and the script's digest disagree for exactly
--     this shape of row**, and they agreed on every earlier state in this pass only because no
--     earlier state had a holderless seat. The selection below adds
--     `och.politician_id IS NOT NULL` so the column is a real boolean, the digest covers all 92
--     rows, and the two agree again. 🔴 THE NEXT STATE WITH A VACANT SEAT MUST DO THE SAME.
--
-- ⚠ It is not only the digest. `p_allow_reelection => r.is_reelection` would pass NULL into
--   `seat_officeholder`, whose guard reads `NOT p_allow_reelection` — NULL is not TRUE, so the
--   re-election refusal would be skipped rather than enforced. It does not fire on these two
--   seats (both have no term covering 2026-12-07, so the guard is never reached), but it is one
--   data shape away from mattering.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 TWO SEATS ARE FLAGGED `is_vacant`, THEY ARE FLAGGED CORRECTLY, AND THIS FILE LEAVES THE
--     FLAG ALONE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--     Assembly District 3        James Gallagher resigned, term closed 2026-06-09
--     State Senate District 10   Aisha Wahab resigned, term closed 2026-09-01
--
-- Both really are empty today, so `is_vacant` is not stale — it is the truth until 2026-12-07.
-- `seat_officeholder` writes `office_terms` and never touches `essentials.offices`, so from the
-- morning of the 7th each of these will read **held AND vacant at the same time**. That is what
-- has to be settled, and the question is WHEN.
--
-- 🔴 CLEARING THE FLAG IN THIS FILE WOULD BE WRONG, AND IT WOULD FAIL ON SOMEBODY ELSE'S PR.
--    Each of these is the only office in its district. Clear the flag today and the district
--    reads `offices > 0 AND active_holders = 0 AND vacant_offices = 0` — verbatim
--    `DEAD_GEOGRAPHY` in a MASTER-ONLY gate, which reads production data with master's code and
--    therefore fails on the NEXT merge, under an innocent author's name. The federal pair
--    (TX-23, FL-20) has the same shape and `CC_0455` clears them on 2027-01-03.
--
-- ▶ **`CC_0480` clears both flags, and it is dated for 2026-12-07 — the day the terms begin, not
--   before.** On that day `active_holders` becomes 1 and the dead-geography shape cannot arise.
--   P6 below asserts that these two and ONLY these two are flagged; assertion 11 asserts both
--   flags are still set when this file finishes.
--
-- ⚠ P6 IS NOT CC_0475's P6. Maine's refused if ANY seat was flagged, which is the right default
--   and the wrong rule here: it would refuse a file whose data is correct. This one names the
--   two it expects and refuses a third.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THIS IS A FUTURE-DATED WAVE WITH 24 HANDOVERS, AND FIVE PEOPLE MOVE SEATS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes each predecessor at `term_start - 1` = **2026-12-06**, still in the
-- future, so `office_current_holder` — "the term covering CURRENT_DATE" — keeps answering with
-- today's member until the morning of the 7th. Assertion 4 pins the nationwide holder map
-- unchanged; assertion 5 asserts all 92 seats still answer with whoever holds them today,
-- INCLUDING the two that answer with nobody. Those are different claims and the second is the
-- one a voter sees.
--
-- Three people in this wave are both a winner here and a predecessor here, on two different
-- seats, so the incumbency guard's scope is a UNION of the two sides:
--
--   Esmeralda Z. Soria   Assembly District 27 → State Senate District 14
--   Damon Connolly       Assembly District 12 → State Senate District 2
--   Mike A. Gipson       Assembly District 65 → Board of Equalization District 3  (CC_0479)
--
-- ⚠ GIPSON LEAVES OFFICE FOR TWENTY-EIGHT DAYS AND THAT IS CORRECT. His Assembly term closes
--   2026-12-06 under art. IV, § 2(a)(3) and his Board of Equalization term does not begin until
--   2027-01-04 under art. II, § 20. Two clauses, two days, one person, and the gap between them
--   is California's calendar rather than a defect in either file. Do not "fix" it by moving
--   either date.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes each predecessor with an UNGUARDED
-- `UPDATE office_terms SET term_end = p_term_start - 1` and writes nothing to that row's
-- `source`. So the 92 new terms are recoverable by slot and the CLOSURES are not.
--
--   🔴 90 PREDECESSOR TERMS ARE CLOSED, NOT 92, AND ALL 90 CARRY `term_end = NULL` AND
--      `how_ended = NULL` TODAY. Measured against production 2026-11-23, not inferred. The two
--      missing are the vacant seats: their last terms are already closed (2026-06-09 and
--      2026-09-01) and fall outside the pre-image predicate, so nothing of theirs is
--      overwritten. The full pre-image is captured into `cc0478_pre`, P7 refuses unless every
--      `term_end` in it is NULL, and assertion 6 counts the rows actually closed.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ WHAT THIS WAVE DOES NOT COVER
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- • **The six statewide executives and Board of Equalization District 3** begin 2027-01-04 under
--   art. II, § 20 — a different clause and a different day, so California ships as two waves and
--   `CC_0479` is the other. Assertion 10 asserts none of the seven was given this date.
-- • **Five Assembly districts** carry no recorded 2026 result and are outside
--   `office_pending_winner`, exactly as invisible as having no race. That is the results
--   programme's work.
-- • **Two California school board seats** carry a 2026-11-03 race and belong to the 2026-12-11
--   wave. Assertion 12 asserts neither was seated by this file.

BEGIN;

CREATE TEMP TABLE cc0478_pin ON COMMIT DROP AS
SELECT 92                                 AS expect_winners,
       92                                 AS expect_offices,
       68                                 AS expect_reelections,
       24                                 AS expect_new,
       90                                 AS expect_predecessors,
       '3c5becfefe95c6450eb4548f3cc036ec' AS expect_digest,
       DATE '2026-12-07'                  AS expect_term_start;
-- winners = offices here, so the two pins are equal. They are NOT in general.
-- predecessors (90) is a THIRD number and differs from both: two of the 92 seats are empty.

-- 🔴 `scripts/lib/seating-wave.mjs`'s WAVE_SELECTION_SQL, with ONE addition:
--    `och.politician_id IS NOT NULL` closes the NULL that a holderless seat otherwise puts into
--    `is_reelection`. See the header — without it the digest silently covers 90 rows, not 92.
CREATE TEMP TABLE cc0478_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       (win.value ->> 'id')::uuid                        AS politician_id,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id IS NOT NULL
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
 WHERE lower(d.state) = 'ca'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0478_pre ON COMMIT DROP AS
SELECT s.office_id, s.seat, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0478_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0478_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2026-12-07')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0478_pre)                                           AS predecessors,
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
  SELECT * INTO p FROM cc0478_pin;

  -- P2 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE THE ROW COUNTS. On a
  -- second run the 92 have left office_pending_winner, so P1 would report 0 rows and blame the
  -- data for what is really a second apply.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0478%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0478. Applied before.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0478_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: selection returned % winner rows, expected %. The data moved under '
                    'this file.', n, p.expect_winners;
  END IF;

  SELECT count(DISTINCT office_id) INTO n FROM cc0478_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P1: % offices, expected %.', n, p.expect_offices;
  END IF;

  -- 🔴 THE DIGEST MUST COVER EVERY ROW IT CLAIMS TO. string_agg drops a NULL input silently, so
  --    a digest over 92 rows and a digest over 90 of them look alike. Count what went in.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0478_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: the digest expression evaluated to NULL on % of % rows, so string_agg '
                    'would have skipped them. is_reelection is NULL on a seat with no current '
                    'holder unless the selection closes it — see this file''s header.',
      p.expect_winners - n, p.expect_winners;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0478_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %. ⚠ If it reads '
                    '8f11f4f3c18a8026fefca528e922629d the data has NOT moved — that is this '
                    'same selection with is_reelection left NULL on the two vacant seats, so '
                    'only 90 rows reached string_agg.', d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0478_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected %.', n, p.expect_reelections;
  END IF;

  SELECT count(*) INTO n FROM cc0478_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P1: % new holders, expected %. (Counted with NOT, which a NULL would fail '
                    'as well — 68 + 24 = 92 only if every row is a real boolean.)',
      n, p.expect_new;
  END IF;

  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0478_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner. California has no multi-member '
                    'legislative district, so this is Ruling A arriving where it was not '
                    'expected — stop and read the race.', n;
  END IF;

  -- P4 — 🔴 THE DATE IS READ, NEVER CARRIED. CC_0477 writes it.
  SELECT count(*) INTO n FROM cc0478_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. CC_0477 '
                    'writes it.', n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0478_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published. An '
                    'estimate may not seat anybody.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0478_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat. California needed no '
                    'people file, so this should be impossible.', n;
  END IF;

  -- P6 — 🔴 EXACTLY TWO SEATS ARE FLAGGED is_vacant, AND THEY ARE THESE TWO. Both are correctly
  -- flagged today (Gallagher and Wahab resigned mid-term) and a FUTURE-dated seating must leave
  -- the flag alone — CC_0480 clears them on the day the terms begin. A THIRD flagged seat is a
  -- fact nobody in this pass has read, so this file refuses rather than absorbing it.
  SELECT count(*) INTO n
    FROM cc0478_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 2 THEN
    RAISE EXCEPTION 'P6: % seat(s) in this wave are flagged is_vacant, expected exactly 2.', n;
  END IF;

  SELECT count(*) INTO n
    FROM cc0478_sel s JOIN essentials.offices o ON o.id = s.office_id
   WHERE o.is_vacant
     AND s.seat NOT IN ('Assembly District 3', 'State Senate District 10');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % flagged seat(s) are not the two this file was written about '
                    '(Assembly District 3, State Senate District 10). Read the seat before '
                    'seating it.', n;
  END IF;

  -- P7 — the pre-image is complete and every predecessor is open. 🔴 90, NOT 92: the two vacant
  -- seats have no term covering the handover, so nothing of theirs is overwritten.
  SELECT count(*) INTO n FROM cc0478_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) captured, expected % (one per held seat; the 2 '
                    'vacant seats have none).', n, p.expect_predecessors;
  END IF;

  SELECT count(*) INTO n FROM cc0478_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing, so this file would '
                    'destroy a date it has not written down.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0478_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a how_ended. seat_officeholder '
                    'COALESCEs that column, so an existing value survives and this file''s '
                    'header would be wrong about what it overwrote.', n;
  END IF;

  SELECT count(*) INTO n
    FROM cc0478_sel s
   WHERE NOT EXISTS (SELECT 1 FROM cc0478_pre x WHERE x.office_id = s.office_id)
     AND s.seat NOT IN ('Assembly District 3', 'State Senate District 10');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % seat(s) other than the two known-vacant ones have no predecessor '
                    'term. A seat with nobody in it is a fact to read, not to seat over.', n;
  END IF;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK A — the incumbency guard, from migrations/_templates/office_terms_incumbency_guard.sql
-- ═════════════════════════════════════════════════════════════════════════════════════════════
--
-- @incumbency-decision: gated — this closes each predecessor at 2026-12-06, which is AFTER the
-- election, so every outgoing term still covers 2026-11-03 and the predicate's answer must not
-- move for anybody. The scope covers both sides of the seating: the 92 winners and the people
-- whose terms are closed.
--
-- 🔴 CALIFORNIA MAKES THAT SCOPE DO REAL WORK. Esmeralda Z. Soria and Damon Connolly are each
--    BOTH a winner here (a Senate seat) and a predecessor here (their Assembly seat), and
--    Mike A. Gipson is a predecessor here whose next seat is in CC_0479. The UNION is what keeps
--    each of them counted once.
CREATE TEMP TABLE cc0478_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0478_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0478_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0478_guarded);

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0478_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in, "the first Monday in December '
                         || 'next following her or his election" (Cal. Const. art. IV, '
                         || '§ 2(a)(3)); the Legislature convenes at noon the same day '
                         || '(art. IV, § 3(a)). '
                         || CASE WHEN r.is_reelection THEN 'Re-elected incumbent. '
                                 WHEN r.holder_before IS NULL
                                   THEN 'Seat was vacant; no predecessor term to close. '
                                 ELSE 'New holder; predecessor closed at 2026-12-06. ' END
                         || 'CC_0478',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0478: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0478_guarded;
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
  SELECT * INTO b FROM cc0478_before;
  SELECT * INTO p FROM cc0478_pin;

  -- 1. 92 new terms, one per selected office, on the day itself, naming the winner.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0478_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. office_next_term answers for all 92 — the view a voter's page reads for a dated handover.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0478_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_offices;
  END IF;

  -- 3. Repo-wide, exactly 92 more terms start on that day — no other state swept in. ⚠ Two
  --    already did: Hawaii's Governor and Lieutenant Governor (CC_0471), which is why this is a
  --    delta and not a total.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_offices THEN
    RAISE EXCEPTION '3: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;

  -- 4. 🔴 NOBODY WAS UNSEATED TODAY, ANYWHERE IN THE COUNTRY. A future-dated term must not move
  --    a seat now, and this wave contains 24 handovers, so the assertion has plenty to catch.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today.', b.holders_md5, m;
  END IF;

  -- 5. 🔴 AND ALL 92 SEATS STILL ANSWER WITH TODAY'S HOLDER — including the two that answer
  --    with NOBODY. "The digest did not move" and "these seats read correctly" are different
  --    claims, and the second is what a voter sees. ⚠ IS NOT DISTINCT FROM, not =: on the two
  --    vacant seats both sides are NULL and `=` would quietly drop them from the count.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0478_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of % seats still answer office_current_holder with the person holding '
                    'them today.', n, p.expect_offices;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0478_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NULL;
  IF n <> 2 THEN
    RAISE EXCEPTION '5: % of the 92 seats answer office_current_holder with nobody, expected 2 '
                    '(Assembly District 3 and State Senate District 10 are vacant until '
                    '2026-12-07).', n;
  END IF;

  -- 6. Each predecessor named in the pre-image is closed the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0478_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0478_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 7. No term of these seats was closed between today and the handover, which would leave a
  --    gap with nobody in the seat.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0478_sel s ON s.office_id = t.office_id
   WHERE t.term_end IS NOT NULL
     AND t.term_end >= CURRENT_DATE AND t.term_end < p.expect_term_start - 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % term(s) closed between today and the day before the handover.', n;
  END IF;

  -- 8. This file creates no people and no offices.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %.', b.offices, n;
  END IF;

  -- 9. 🔴 NOT ONE SEAT STARTS ON A DAY THAT IS NOT THE FIRST MONDAY IN DECEMBER. California's
  --    plausible wrong answers are the second Monday (12-14) and the Maine shape, a convening
  --    date one day off (12-08). Neither may appear.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0478_sel s ON s.office_id = t.office_id
   WHERE t.term_start IN (DATE '2026-12-08', DATE '2026-12-14', DATE '2026-12-01');
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % seat(s) start on a day that is not the first Monday in December.', n;
  END IF;

  -- 10. 🔴 THE SEVEN STATEWIDE SEATS WERE NOT SWEPT IN. A different clause (art. II, § 20) and a
  --     different day; CC_0479 seats them on 2027-01-04.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ca' AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD')
     AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '10: % California statewide seat(s) were given the legislature''s date. '
                    'They begin 2027-01-04 under art. II, § 20.', n;
  END IF;

  -- 11. 🔴🔴 BOTH VACANCY FLAGS ARE STILL SET, AND NO OTHER OFFICE'S FLAG MOVED. Clearing them
  --     here would read as DEAD_GEOGRAPHY in a master-only gate and fail on somebody else's PR.
  --     CC_0480 clears them on 2026-12-07.
  SELECT count(*) INTO n
    FROM cc0478_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 2 THEN
    RAISE EXCEPTION '11: % seat(s) in this wave are still flagged is_vacant, expected 2. A '
                    'future-dated seating does not clear a flag — CC_0480 does, on the day.', n;
  END IF;

  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '11: the repo-wide count of flagged-vacant offices moved % -> %.',
      b.vacant_all, n;
  END IF;

  -- 12. 🔴 NO CALIFORNIA SEAT OUTSIDE THIS WAVE WAS SEATED, including the two school board seats
  --     that carry a 2026-11-03 race and belong to the 2026-12-11 wave.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ca' AND t.term_start = p.expect_term_start
     AND d.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 0 THEN
    RAISE EXCEPTION '12: % non-legislative California seat(s) were seated by this wave.', n;
  END IF;

  -- 13. Repo-wide, exactly 92 office_terms rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '13: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 14. Every new term cites this migration (Ruling B: recoverable by slot).
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0478_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0478%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '14: % of % new terms cite CC_0478.', n, p.expect_offices;
  END IF;

  -- 15. 🔴 THE SEATS HAVE LEFT THE PENDING-WINNER VIEW, so the card stops reading as a declared
  --     result and starts reading as a dated handover.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0478_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '15: % seat(s) still answer office_pending_winner.', n;
  END IF;

  -- 16. The 238 unflagged drift baseline did not move. 🔴 NEVER RAISE IT.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '16: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  RAISE NOTICE 'CC_0478 OK: 92 California legislators scheduled for % (% re-elections, % '
               'handovers), % predecessors closed at %, nobody moved today, Assembly District 3 '
               'and State Senate District 10 seated while still flagged vacant (CC_0480 clears '
               'them on the day), the 7 statewide seats untouched, drift baseline % held.',
    p.expect_term_start, p.expect_reelections, p.expect_new, b.predecessors,
    p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
