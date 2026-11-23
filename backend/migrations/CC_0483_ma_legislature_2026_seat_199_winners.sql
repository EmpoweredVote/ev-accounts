-- CC_0483 — Massachusetts House and Senate: schedule all 199 winners for the term that begins
-- 2027-01-06.
--
-- Mass. Const. Amend. Art. LXIV § 1, as appearing in Amend. Art. LXXXII: "The terms of senators
-- and representatives shall begin with the first Wednesday in January succeeding their election
-- …". The first Wednesday in January 2027 is the **6th**. CC_0481 recorded that date against all
-- 199 offices; this file reads it and writes the terms.
--
-- 🔴🔴 **THE OTHER FIVE MASSACHUSETTS SEATS DO NOT SHARE THIS DAY.** The same sentence-group puts
--     the Governor and Lieutenant Governor on **2027-01-07** and the Attorney General, Treasurer
--     and Auditor on **2027-01-20** — a fortnight later. `CC_0484` and `CC_0485` seat them.
--     Assertion 10 refuses if any of the five was given this date.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SELECTION IS PINNED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   winners 199 · offices 199 · re-elections 178 · new holders 21 · predecessors 197
--   digest md5 = ae5a242989f59dbc0249571223ec378e   (captured 2026-11-23 against production,
--                                                    AFTER CC_0481 and CC_0482, inside one
--                                                    rolled-back transaction)
--   called 199 · certified 0 on the day this was captured (Ruling B)
--
-- 🔴 **THAT DIGEST IS THE POST-CC_0482 ONE.** `office_pending_winner` renders a winner with no
--    person record as a NULL id, and 21 of these 199 had none until CC_0482 created 18 and linked
--    3. ▶ **IF P1 REPORTS A DIFFERENT DIGEST, CHECK WHETHER CC_0482 HAS BEEN APPLIED BEFORE
--    CONCLUDING THE DATA MOVED** — the two failures are indistinguishable from the message alone.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE SELECTION ADDS ONE CLAUSE TO `WAVE_SELECTION_SQL`, AND MASSACHUSETTS IS THE SECOND
--     STATE TO NEED IT — THE FIRST WHERE IT ONLY APPEARS *AFTER* THE PEOPLE FILE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `scripts/lib/seating-wave.mjs` computes `is_reelection` as
--
--     ((win.value ->> 'id') IS NOT NULL AND och.politician_id::text = (win.value ->> 'id'))
--
-- On a seat with no current holder `och.politician_id` is NULL, so the comparison is NULL and
-- `true AND NULL` is **NULL**. `'…' || NULL` is NULL and `string_agg` SKIPS NULL input — so the
-- published digest expression covers fewer rows than every count in P1 reports. California found
-- this (`CC_0478`); Massachusetts has the same two-seat shape.
--
-- ⚠ **BUT HERE IT IS INVISIBLE UNTIL THE PEOPLE FILE RUNS, WHICH IS WORSE.** The two flagged
--   seats — 1st Franklin and 17th Middlesex — are won by two of the 21 people CC_0482 creates.
--   BEFORE that file, the WINNER id is NULL too, the first conjunct is FALSE, and `false AND
--   NULL` is **FALSE**, not NULL. So the defect does not exist yet. Measured in one transaction
--   2026-11-23, after CC_0481 and CC_0482:
--
--     as published, is_reelection NULL on 2 rows   md5 = 2169c36f62827dbca2a510829595ab51  (197 rows)
--     with `AND och.politician_id IS NOT NULL`     md5 = ae5a242989f59dbc0249571223ec378e  (199 rows)
--
--   ▶ **A DIGEST CAPTURED BEFORE THE PEOPLE FILE WOULD HAVE BEEN RIGHT, AND WOULD HAVE BECOME
--   WRONG WHEN THAT FILE RAN.** Capture it after, and count what entered the aggregate: P1 does.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 TWO SEATS ARE FLAGGED `is_vacant`, THEY ARE FLAGGED CORRECTLY, AND THEY HAVE NO TERM AT ALL
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--     1st Franklin District      vacant_since 2026-01-20
--     17th Middlesex District    vacant_since 2026-03-19
--
-- ⚠ **THESE ARE NOT CALIFORNIA'S SHAPE.** California's two vacant seats each carried a CLOSED
--   term from the member who resigned. These two carry **no `office_terms` row whatsoever** —
--   they are in `essentials.offices_missing_terms` and always have been. So:
--
--   • the pre-image is **197, not 199**, and nothing of theirs is overwritten, because there is
--     nothing to overwrite. P7 asserts the count and names the two exceptions.
--   • this file writes their **first ever term**, which takes them OUT of
--     `offices_missing_terms`. They are flagged, so they were never in the unflagged 238 — the
--     baseline cannot move either way, and assertion 16 asserts both halves rather than one.
--
-- 🔴 **THE FLAG IS LEFT ALONE.** `seat_officeholder` writes `office_terms` and never touches
--    `essentials.offices`, so from 2027-01-06 each seat would read held AND vacant at once. Each
--    is the only office in its district, so clearing the flag while the seat is still empty makes
--    the district read `offices > 0 AND active_holders = 0 AND vacant_offices = 0` — verbatim
--    `DEAD_GEOGRAPHY` in a MASTER-ONLY gate, which fails on the next person's pull request.
--    ▶ **`CC_0486` clears both, on the handover day, and refuses to run before it.** P6 asserts
--    exactly these two are flagged and refuses a third; assertion 11 asserts both flags survive
--    this file.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 A FUTURE-DATED WAVE WITH 21 HANDOVERS, AND TWO PEOPLE MOVE CHAMBERS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes each predecessor at `term_start - 1` = **2027-01-05**, which is
-- exactly the day before the successors begin — and that is what the clause's own words
-- "…and until their successors are chosen and qualified" describe. Nothing to reconcile.
--
-- Two people are both a winner here and a predecessor here, on two different seats:
--
--   Kate Lipper-Garabedian   32nd Middlesex District (House) → Fifth Middlesex District (Senate)
--   Erika Uyterhoeven        27th Middlesex District (House) → Second Middlesex District (Senate)
--
-- The incumbency guard's scope is a UNION of the two sides for exactly that reason, and both
-- vacated seats are themselves in this wave, won by people CC_0482 created.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes each predecessor with an UNGUARDED
-- `UPDATE office_terms SET term_end = p_term_start - 1` and writes nothing to that row's
-- `source`. So the 199 new terms are recoverable by slot and the 197 CLOSURES are not.
--
--   🔴 ALL 197 PREDECESSOR TERMS CARRY `term_end = NULL` AND `how_ended = NULL`. Measured
--      against production 2026-11-23, not inferred. P7 refuses unless that holds, and assertion
--      6 counts the rows actually closed.
--
-- ⚠ MASSACHUSETTS' SITTING LEGISLATORS ARE AMONG THE UNDATED TENURES: not one Massachusetts
--   legislative term carries a `term_start` anywhere in this database, so closing them writes an
--   end onto rows with no beginning. That is correct and is not this file's to fix — a tenure
--   start is a different fact from a term start.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ WHAT THIS WAVE DOES NOT COVER
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- • **The five statewide executives**, on two later days — CC_0484 and CC_0485.
-- • **2nd Plymouth District** carries a 2026 race with no recorded result, so it is outside
--   `office_pending_winner` and outside this wave. John R. Gaskey holds it. Assertion 12.
-- • **The Secretary of the Commonwealth** likewise has no recorded 2026 result.

BEGIN;

CREATE TEMP TABLE cc0483_pin ON COMMIT DROP AS
SELECT 199                                AS expect_winners,
       199                                AS expect_offices,
       178                                AS expect_reelections,
       21                                 AS expect_new,
       197                                AS expect_predecessors,
       'ae5a242989f59dbc0249571223ec378e' AS expect_digest,
       DATE '2027-01-06'                  AS expect_term_start;
-- winners = offices here. predecessors is a THIRD number and differs from both: two of the 199
-- seats have no office_terms row at all.

-- 🔴 `WAVE_SELECTION_SQL` with ONE addition: `och.politician_id IS NOT NULL` closes the NULL a
--    holderless seat otherwise puts into `is_reelection`. See the header — without it the digest
--    covers 197 rows, not 199, and only AFTER CC_0482 has run.
CREATE TEMP TABLE cc0483_sel ON COMMIT DROP AS
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
 WHERE lower(d.state) = 'ma'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0483_pre ON COMMIT DROP AS
SELECT s.office_id, s.seat, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0483_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0483_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-06')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0483_pre)                                           AS predecessors,
       (SELECT md5(string_agg(och.office_id::text || ':'
                              || COALESCE(och.politician_id::text, '-'),
                              '|' ORDER BY och.office_id::text))
          FROM essentials.office_current_holder och)                               AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged,
       (SELECT count(*) FROM essentials.offices_missing_terms)                     AS missing_all;

DO $$
DECLARE n bigint; d text; p record;
BEGIN
  SELECT * INTO p FROM cc0483_pin;

  -- P2 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE THE ROW COUNTS.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0483%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0483. Applied before.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0483_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: selection returned % winner rows, expected %. The data moved under '
                    'this file.', n, p.expect_winners;
  END IF;

  SELECT count(DISTINCT office_id) INTO n FROM cc0483_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P1: % offices, expected %.', n, p.expect_offices;
  END IF;

  -- 🔴 THE DIGEST MUST COVER EVERY ROW IT CLAIMS TO. string_agg drops NULL input silently, so a
  --    digest over 199 rows and one over 197 of them look alike.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0483_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: the digest expression evaluated to NULL on % of % rows, so string_agg '
                    'would have skipped them. is_reelection is NULL on a seat with no current '
                    'holder once its winner HAS a person record — see this file''s header.',
      p.expect_winners - n, p.expect_winners;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0483_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %. ⚠ Before concluding the data moved, '
                    'check that CC_0482 has been applied — 21 of these winners had no person '
                    'record until it ran, and that changes this digest. If it reads '
                    '2169c36f62827dbca2a510829595ab51 the data has NOT moved: that is this same '
                    'selection with is_reelection left NULL on the two vacant seats, so only 197 '
                    'rows reached string_agg.', d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0483_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected %.', n, p.expect_reelections;
  END IF;

  SELECT count(*) INTO n FROM cc0483_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P1: % new holders, expected %. (Counted with NOT, which a NULL would fail '
                    'as well — 178 + 21 = 199 only if every row is a real boolean.)',
      n, p.expect_new;
  END IF;

  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0483_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner. Massachusetts has no '
                    'multi-member legislative district, so this is Ruling A arriving where it '
                    'was not expected — stop and read the race.', n;
  END IF;

  -- P4 — 🔴 THE DATE IS READ, NEVER CARRIED. CC_0481 writes it, and it writes THREE different
  --    days for Massachusetts. A literal here would agree with itself while quietly belonging to
  --    another group.
  SELECT count(*) INTO n FROM cc0483_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. CC_0481 '
                    'writes it. ⚠ If one reads 2027-01-07 or 2027-01-20 an executive row has '
                    'reached this selection.', n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0483_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published. An '
                    'estimate may not seat anybody.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0483_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat. CC_0482 creates 18 and '
                    'links 3.', n;
  END IF;

  -- P6 — 🔴 EXACTLY TWO SEATS ARE FLAGGED is_vacant, AND THEY ARE THESE TWO. Both are correctly
  -- flagged today and a FUTURE-dated seating must leave the flag alone; CC_0486 clears them on
  -- the day. A THIRD flagged seat is a fact nobody in this pass has read.
  SELECT count(*) INTO n
    FROM cc0483_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 2 THEN
    RAISE EXCEPTION 'P6: % seat(s) in this wave are flagged is_vacant, expected exactly 2.', n;
  END IF;

  SELECT count(*) INTO n
    FROM cc0483_sel s JOIN essentials.offices o ON o.id = s.office_id
   WHERE o.is_vacant AND s.seat NOT IN ('1st Franklin District', '17th Middlesex District');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % flagged seat(s) are not the two this file was written about '
                    '(1st Franklin District, 17th Middlesex District). Read the seat before '
                    'seating it.', n;
  END IF;

  -- P7 — 🔴 THE PRE-IMAGE IS 197, NOT 199, AND THE TWO MISSING ONES ARE NAMED. They have no
  -- office_terms row at all, so this file writes their first ever term and overwrites nothing.
  SELECT count(*) INTO n FROM cc0483_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) captured, expected % (one per held seat; the 2 '
                    'flagged seats have no office_terms row at all).', n, p.expect_predecessors;
  END IF;

  SELECT count(*) INTO n FROM cc0483_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing, so this file would '
                    'destroy a date it has not written down.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0483_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a how_ended. seat_officeholder '
                    'COALESCEs that column, so an existing value survives.', n;
  END IF;

  SELECT count(*) INTO n
    FROM cc0483_sel s
   WHERE NOT EXISTS (SELECT 1 FROM cc0483_pre x WHERE x.office_id = s.office_id)
     AND s.seat NOT IN ('1st Franklin District', '17th Middlesex District');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % seat(s) other than the two known-vacant ones have no predecessor '
                    'term. A seat with nobody in it is a fact to read, not to seat over.', n;
  END IF;

  -- P8 — 🔴 THE TWO FLAGGED SEATS REALLY DO HAVE NO TERM ROW, asserted rather than assumed. If
  -- one has acquired a term since this file was written, the pre-image count above is wrong in
  -- the direction that silently skips a closure.
  SELECT count(*) INTO n
    FROM cc0483_sel s
   WHERE s.seat IN ('1st Franklin District', '17th Middlesex District')
     AND EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = s.office_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: % of the two flagged seats now carries an office_terms row. When this '
                    'file was written neither did, and the pre-image count of 197 depends on '
                    'that.', n;
  END IF;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK A — the incumbency guard, from migrations/_templates/office_terms_incumbency_guard.sql
-- ═════════════════════════════════════════════════════════════════════════════════════════════
--
-- @incumbency-decision: gated — this closes each predecessor at 2027-01-05, well after the
-- election, so every outgoing term still covers 2026-11-03 and the predicate's answer must not
-- move for anybody. The scope covers both sides: the 199 winners and the people whose terms are
-- closed.
--
-- 🔴 MASSACHUSETTS MAKES THAT SCOPE DO REAL WORK. Kate Lipper-Garabedian and Erika Uyterhoeven
--    are each BOTH a winner here (a Senate seat) and a predecessor here (their House seat). The
--    UNION is what keeps each of them counted once.
CREATE TEMP TABLE cc0483_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0483_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0483_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0483_guarded);

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0483_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in, "the terms of senators and '
                         || 'representatives shall begin with the first Wednesday in January '
                         || 'succeeding their election" (Mass. Const. Amend. Art. LXIV § 1, as '
                         || 'appearing in Amend. Art. LXXXII). The oath (Part 2, Ch. VI, Art. I) '
                         || 'gates the discharge of the duties and is a separate, later event. '
                         || 'NOTE: Massachusetts'' statewide executives do NOT share this day — '
                         || 'the Governor and Lieutenant Governor begin 2027-01-07 and the '
                         || 'Attorney General, Treasurer and Auditor 2027-01-20. '
                         || CASE WHEN r.is_reelection THEN 'Re-elected incumbent. '
                                 WHEN r.holder_before IS NULL
                                   THEN 'Seat was vacant and carried no term row at all; this is '
                                        || 'its first. '
                                 ELSE 'New holder; predecessor closed at 2027-01-05. ' END
                         || 'CC_0483',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0483: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0483_guarded;
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
  SELECT * INTO b FROM cc0483_before;
  SELECT * INTO p FROM cc0483_pin;

  -- 1. 199 new terms, one per selected office, on the day itself, naming the winner.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0483_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. office_next_term answers for all 199 — the view a voter's page reads for a dated handover.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0483_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_offices;
  END IF;

  -- 3. Repo-wide, exactly 199 more terms start on that day — no other state swept in. ⚠ One
  --    already did: Maine's Governor (CC_0476), which is why this is a delta and not a total.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_offices THEN
    RAISE EXCEPTION '3: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;

  -- 4. 🔴 NOBODY WAS UNSEATED TODAY, ANYWHERE IN THE COUNTRY.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today.', b.holders_md5, m;
  END IF;

  -- 5. 🔴 AND ALL 199 SEATS STILL ANSWER WITH TODAY'S HOLDER — including the two that answer
  --    with NOBODY. ⚠ IS NOT DISTINCT FROM, not =: on the two vacant seats both sides are NULL
  --    and `=` would quietly drop them from the count.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0483_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of % seats still answer office_current_holder with the person holding '
                    'them today.', n, p.expect_offices;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0483_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NULL;
  IF n <> 2 THEN
    RAISE EXCEPTION '5: % of the 199 seats answer office_current_holder with nobody, expected 2 '
                    '(1st Franklin and 17th Middlesex are vacant until 2027-01-06).', n;
  END IF;

  -- 6. Each predecessor named in the pre-image is closed the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0483_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0483_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 7. No term of these seats was closed between today and the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0483_sel s ON s.office_id = t.office_id
   WHERE t.term_end IS NOT NULL
     AND t.term_end >= CURRENT_DATE AND t.term_end < p.expect_term_start - 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % term(s) closed between today and the day before the handover.', n;
  END IF;

  -- 8. This file creates no people and no offices. CC_0482 made the 18.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %.', b.offices, n;
  END IF;

  -- 9. 🔴 NOT ONE SEAT CARRIES A DAY FROM ANOTHER GROUP, OR THE 2027-01-13 MIDDLE WEDNESDAY.
  --    Massachusetts' three dates are 6th, 7th and 20th; the 13th is the Wednesday between, and
  --    "the third Wednesday" miscounted by one gives it.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0483_sel s ON s.office_id = t.office_id
   WHERE t.term_start IN (DATE '2027-01-07', DATE '2027-01-13', DATE '2027-01-20');
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % legislative seat(s) start on an executive day or on 2027-01-13.', n;
  END IF;

  -- 10. 🔴🔴 THE FIVE STATEWIDE EXECUTIVES WERE NOT SWEPT IN. Two begin 2027-01-07 and three
  --     2027-01-20; CC_0484 and CC_0485 seat them. Copying this date onto the Attorney General
  --     would put her in office two weeks early, and this is the gate that refuses it.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ma' AND d.district_type = 'STATE_EXEC'
     AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '10: % Massachusetts state executive(s) were given the legislature''s date.',
      n;
  END IF;

  -- 11. 🔴🔴 BOTH VACANCY FLAGS ARE STILL SET, AND NO OTHER OFFICE'S FLAG MOVED. CC_0486 clears
  --     them on 2027-01-06.
  SELECT count(*) INTO n
    FROM cc0483_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 2 THEN
    RAISE EXCEPTION '11: % seat(s) in this wave are still flagged is_vacant, expected 2. A '
                    'future-dated seating does not clear a flag — CC_0486 does, on the day.', n;
  END IF;

  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '11: the repo-wide count of flagged-vacant offices moved % -> %.',
      b.vacant_all, n;
  END IF;

  -- 12. 🔴 2nd PLYMOUTH DISTRICT WAS NOT SEATED. It carries a 2026 race with no recorded result.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ma' AND d.label = '2nd Plymouth District'
     AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '12: 2nd Plymouth District was seated, and it has no recorded 2026 result.';
  END IF;

  -- 13. Repo-wide, exactly 199 office_terms rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '13: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 14. Every new term cites this migration (Ruling B: recoverable by slot).
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0483_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0483%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '14: % of % new terms cite CC_0483.', n, p.expect_offices;
  END IF;

  -- 15. 🔴 THE SEATS HAVE LEFT THE PENDING-WINNER VIEW.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0483_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '15: % seat(s) still answer office_pending_winner.', n;
  END IF;

  -- 16. 🔴 THE DRIFT BASELINE DID NOT MOVE, AND THE TWO FLAGGED SEATS LEFT offices_missing_terms
  --     ALTOGETHER. They had no term row at all and now have one. They were flagged, so they were
  --     never in the UNFLAGGED count — both halves are asserted, because "the baseline held" and
  --     "the view shrank by exactly two" are different claims. 🔴 NEVER RAISE THE BASELINE.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '16: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> b.missing_all - 2 THEN
    RAISE EXCEPTION '16: offices_missing_terms went % -> %, a delta of %, expected -2 (1st '
                    'Franklin and 17th Middlesex gained their first ever term).',
      b.missing_all, n, n - b.missing_all;
  END IF;

  RAISE NOTICE 'CC_0483 OK: 199 Massachusetts legislators scheduled for % (% re-elections, % '
               'handovers), % predecessors closed at %, nobody moved today, 1st Franklin and '
               '17th Middlesex given their first ever term while still flagged vacant (CC_0486 '
               'clears them on the day), the 5 statewide executives untouched on their own two '
               'later days, drift baseline % held.',
    p.expect_term_start, p.expect_reelections, p.expect_new, b.predecessors,
    p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
