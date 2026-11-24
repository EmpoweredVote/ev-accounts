-- CC_0490 — Utah House and Senate: schedule all 50 winners for the term that begins 2027-01-01.
--
-- Utah Const. Art. VI, Sec. 3(2): "Their term of office shall be two years from the first day of
-- January next after their election." Sec. 4(2) says the same for senators with four years. The
-- first day of January next after 2026-11-03 is **2027-01-01**. CC_0489 recorded that date
-- against all 50 offices; this file reads it and writes the terms.
--
-- 🔴 **THE FIRST MONDAY IS THE WRONG ANSWER AND IT IS A LIVE ONE IN THIS STATE.** 2027-01-04 is
--    three days later, and Utah's Board of Education statute uses first Mondays for its own
--    transitional dates (2023-01-02, 2025-01-06). Assertion 9 refuses any seat on 2027-01-04 and
--    assertion 10 refuses a Board seat on this file's day.
--
-- ⚠ **2027-01-01 IS A FRIDAY AND A PUBLIC HOLIDAY.** The clause names a day of the calendar, not
--   a sitting day; Utah's general session convenes on the third Tuesday in January.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SELECTION IS PINNED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   winners 50 · offices 50 · re-elections 35 · new holders 15 · predecessors 50
--   digest md5 = d3693f7d6b2949607dd4c996e012a4d6   (captured 2026-11-23 against production,
--                                                    AFTER CC_0489)
--   called 50 · certified 0 on the day this was captured (Ruling B)
--
-- 🟢 **UTAH NEEDED NO PEOPLE FILE AND CANNOT PRODUCE THE `is_reelection` NULL.** All 50 winners
--    already carry a `politicians` row and all 119 Utah legislative and Board seats are held, so
--    both digests are the same string over the same 50 rows, measured side by side:
--
--      as published (no IS NOT NULL)            md5 = d3693f7d6b2949607dd4c996e012a4d6  (50 rows)
--      with `AND och.politician_id IS NOT NULL` md5 = d3693f7d6b2949607dd4c996e012a4d6  (50 rows)
--
--    ▶ **THE FIX AND THE COVERAGE GATE ARE CARRIED ANYWAY.** They catch opposite faults — the
--    digest gate sees a CHANGED value, the coverage gate sees a VANISHED row — and neither can
--    see the other's. "It cannot happen here" expires the moment a seat falls vacant.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 EVERY PREDECESSOR TERM IN THIS STATE IS UNDATED, SO THIS FILE WRITES 50 ENDS ONTO ROWS
--     WITH NO BEGINNING
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- All 119 Utah legislative and Board of Education terms carry `term_start = NULL` — measured
-- 2026-11-23, and asserted by P7. So `seat_officeholder` closing each predecessor at
-- `term_start - 1` = **2026-12-31** gives 50 rows that have an end and no start.
--
-- ⚠ **That is correct and is not this file's to fix.** A tenure start is a different fact from a
--   term start, and the repo-wide undated-tenure backlog is its own programme. 🔴 It also means
--   **Utah offers no control of its own**: nothing in our data corroborates or contradicts
--   2027-01-01, which CC_0489's assertion 3d records as an absence rather than leaving implied.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ WHAT THIS WAVE DOES NOT COVER — AND UTAH'S GAP IS MOSTLY MISSING **RACES**
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--     House   75 offices    42 seated here    2 race, blank result    31 WITH NO RACE ROW AT ALL
--     Senate  29 offices     8 seated here    1 race, blank result    20 WITH NO RACE ROW AT ALL
--     Board   15 offices     0 (refused)      2 race, blank result     7 with no race row
--
-- 🔴🔴 **UTAH ELECTS ITS WHOLE HOUSE EVERY TWO YEARS**, Art. VI Sec. 3(1), so all 75 House seats
--     were on the 2026 ballot as a matter of law and the 31 missing race rows are certainly
--     missing data rather than seats that were not up. ⚠ The Senate shortfall is real but cannot
--     be sized from the constitution alone: Sec. 4(3) requires "as nearly one-half as may be
--     practicable" — 14 or 15 of 29 — while leaving **which** half to statute, and that statute
--     is not in this database. ▶ Both belong to the results programme.
--
-- ⚠ **THE THREE BLANK-RESULT LEGISLATIVE SEATS ARE BLANK, NOT PROVISIONAL.** House District 48,
--   House District 61 and Senate District 11 carry candidate rows whose `result` is **NULL** with
--   no `result_source` at all — there is nothing here that could be misread as a call, unlike
--   Washington's four, which carried the August primary result. Assertion 12 refuses if one was
--   seated.
--
-- 🔴 **THE SIX BOARD OF EDUCATION SEATS ARE REFUSED AND CC_0489 LEFT THEM UNDATED.** P4 would
--    refuse them here anyway, because they have no `office_swearing_in` row at all.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THREE WINNERS KEEP ANOTHER OFFICE, AND ONE OF THE THREE IS THE SHARPEST CONSEQUENCE OF
--     THE MISSING RESULTS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--     Doug Fiefia     wins Senate District 18, holds **State House District 48**
--     Julie Jackson   wins House District 34,  holds Granite School District
--     Silvia Catten   wins Senate District 13, holds Millcreek City Council, District 1
--
-- 🔴 **HOUSE DISTRICT 48 IS ONE OF THE THREE SEATS WITH A BLANK RESULT.** Fiefia is vacating it,
--    two newcomers contested it, and our data records no winner — so unlike every other handover
--    in this pass, **the seat he leaves is not in this wave and gets no successor**. From
--    2027-01-01 our data will show him holding a Senate seat and a House seat at once.
--
-- ⚠ **THAT IS A VISIBLE CONSEQUENCE OF A RESULTS GAP, NOT A DEFECT THIS FILE INTRODUCES, AND IT
--   MUST NOT BE "TIDIED".** `seat_officeholder` closes the predecessor on the office being
--   SEATED and nothing else. Closing his House term would mean either inventing a successor or
--   asserting an end date from the constitution for a seat whose election we have not read — and
--   the same clause ends all 75 House terms on 2027-01-01, so doing it for one and not the other
--   74 would be arbitrary. ▶ **The fix is the House District 48 result, not an edit here.**
--   Assertion 11 asserts all three kept terms are still open afterwards.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes each predecessor with an UNGUARDED
-- `UPDATE office_terms SET term_end = p_term_start - 1` and writes nothing to that row's
-- `source`. So the 50 new terms are recoverable by slot and the 50 CLOSURES are not.
--
--   🔴 ALL 50 PREDECESSOR TERMS CARRY `term_end = NULL`, `how_ended = NULL` AND
--      `term_start = NULL`. Measured against production 2026-11-23, not inferred. P7 refuses
--      unless all three hold, and assertion 6 counts the rows actually closed.

BEGIN;

CREATE TEMP TABLE cc0490_pin ON COMMIT DROP AS
SELECT 50                                 AS expect_winners,
       50                                 AS expect_offices,
       35                                 AS expect_reelections,
       15                                 AS expect_new,
       50                                 AS expect_predecessors,
       'd3693f7d6b2949607dd4c996e012a4d6' AS expect_digest,
       DATE '2027-01-01'                  AS expect_term_start;
-- All three counts coincide at 50: one winner per office, every office held. 🔴 THEY ARE
-- SEPARATE CLAIMS AND ARE CHECKED SEPARATELY — in Massachusetts the predecessor count was 197
-- against 199 winners, and reading one number as the other is how that goes unnoticed.

-- 🔴 `WAVE_SELECTION_SQL` with ONE addition: `och.politician_id IS NOT NULL` closes the NULL a
--    holderless seat otherwise puts into `is_reelection`. Utah has no holderless seat today, so
--    it changes nothing today — see the header. It is here because the gate below has to be able
--    to tell.
CREATE TEMP TABLE cc0490_sel ON COMMIT DROP AS
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
 WHERE lower(d.state) = 'ut'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0490_pre ON COMMIT DROP AS
SELECT s.office_id, s.seat, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0490_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

-- The offices OUTSIDE this wave that a winner here still holds. Named so assertion 11 can prove
-- this file left them alone, rather than nobody noticing it had not.
CREATE TEMP TABLE cc0490_kept ON COMMIT DROP AS
SELECT t.id AS term_id, p.full_name, d.label AS seat, d.district_type
  FROM essentials.office_terms t
  JOIN essentials.offices o     ON o.id = t.office_id
  JOIN essentials.districts d   ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = t.politician_id
 WHERE t.politician_id IN (SELECT politician_id FROM cc0490_sel)
   AND NOT EXISTS (SELECT 1 FROM cc0490_sel s WHERE s.office_id = t.office_id)
   AND t.term_end IS NULL;

CREATE TEMP TABLE cc0490_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-01')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0490_pre)                                           AS predecessors,
       (SELECT count(*) FROM cc0490_kept)                                          AS kept,
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
  SELECT * INTO p FROM cc0490_pin;

  -- P2 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE THE ROW COUNTS. On a
  -- second run the seats have left office_pending_winner, so P1 would return 0 and report that
  -- the data moved — which is true of the view and false of the world.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0490%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0490. Applied before.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0490_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: selection returned % winner rows, expected %. The data moved under this '
                    'file. ⚠ Utah has THREE legislative seats that were on the 2026 ballot with '
                    'a blank result (House District 48, House District 61, Senate District 11); '
                    'if one has been recorded since, this wave is larger and the pin must be '
                    're-derived.', n, p.expect_winners;
  END IF;

  SELECT count(DISTINCT office_id) INTO n FROM cc0490_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P1: % offices, expected %.', n, p.expect_offices;
  END IF;

  -- 🔴 THE DIGEST MUST COVER EVERY ROW IT CLAIMS TO. string_agg drops NULL input silently, so a
  --    digest over 50 rows and one over 48 of them look alike.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0490_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: the digest expression evaluated to NULL on % of % rows, so string_agg '
                    'would have skipped them. is_reelection is NULL on a seat with no current '
                    'holder — when this file was written all 119 Utah legislative and Board '
                    'seats were held, so one has fallen vacant. Read it before seating over it.',
      p.expect_winners - n, p.expect_winners;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0490_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %. Every count above passed, so the '
                    'membership is the same size and something inside it changed — a winner '
                    'swapped, or a seat changed hands before the handover.', d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0490_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected %.', n, p.expect_reelections;
  END IF;

  SELECT count(*) INTO n FROM cc0490_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P1: % new holders, expected %. (Counted with NOT, which a NULL would fail '
                    'as well — 35 + 15 = 50 only if every row is a real boolean.)',
      n, p.expect_new;
  END IF;

  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0490_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner. Utah has no multi-member '
                    'legislative district, so this is Ruling A arriving where it was not '
                    'expected — stop and read the race.', n;
  END IF;

  -- P4 — 🔴 THE DATE IS READ, NEVER CARRIED. CC_0489 writes it, and it deliberately writes NO
  --    row for the six Board of Education seats, so one reaching this selection would fail here.
  SELECT count(*) INTO n FROM cc0490_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. CC_0489 '
                    'writes it. ⚠ If a date reads 2027-01-04 somebody has applied the FIRST '
                    'MONDAY rule, which is the Board of Education''s boundary and not the '
                    'legislature''s.', n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0490_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published. An '
                    'estimate may not seat anybody.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0490_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat. Utah needed no people file: '
                    'all 50 winners already had one when this was written.', n;
  END IF;

  -- P6 — 🔴 NOT ONE UTAH SEAT IN THIS WAVE IS FLAGGED is_vacant, ASSERTED RATHER THAN ASSUMED.
  SELECT count(*) INTO n
    FROM cc0490_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) in this wave are flagged is_vacant, expected 0. A future-'
                    'dated seating does not clear a flag, so this state would need a companion '
                    'file of the CC_0480 / CC_0486 kind and it has none.', n;
  END IF;

  -- P7 — 🔴 THE PRE-IMAGE IS ONE OPEN, UNDATED TERM PER SEAT. All three facts are asserted: an
  -- existing term_end would be destroyed unrecorded, an existing how_ended would SURVIVE the
  -- COALESCE, and a dated predecessor would mean Utah had acquired a control this file's
  -- companion asserts it does not have.
  SELECT count(*) INTO n FROM cc0490_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) captured, expected % (one per seat — every Utah '
                    'legislative seat was held when this file was written).',
      n, p.expect_predecessors;
  END IF;

  SELECT count(*) INTO n FROM cc0490_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing, so this file would '
                    'destroy a date it has not written down.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0490_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a how_ended. seat_officeholder '
                    'COALESCEs that column, so an existing value survives.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0490_pre WHERE term_start IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) now carry a term_start. When this file was '
                    'written all 50 were NULL — Utah offers no control of its own for that '
                    'reason, and CC_0489''s assertion 3d records the absence. If starts have '
                    'appeared, check 2027-01-01 against them before applying.', n;
  END IF;

  SELECT count(*) INTO n
    FROM cc0490_sel s
   WHERE NOT EXISTS (SELECT 1 FROM cc0490_pre x WHERE x.office_id = s.office_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % seat(s) have no predecessor term. A seat with nobody in it is a fact '
                    'to read, not to seat over.', n;
  END IF;

  -- P8 — 🔴 THE THREE OFFICES THIS FILE MUST LEAVE ALONE ARE THERE TO BE LEFT ALONE. If this
  -- count is not 3, the shape assertion 11 checks afterwards has changed and that assertion
  -- would pass vacuously.
  SELECT count(*) INTO n FROM cc0490_kept;
  IF n <> 3 THEN
    RAISE EXCEPTION 'P8: % open term(s) held by a winner on an office OUTSIDE this wave, '
                    'expected exactly 3 (Doug Fiefia on State House District 48, Julie Jackson '
                    'on Granite School District, Silvia Catten on Millcreek City Council '
                    'District 1). Read the extra one before seating.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0490_kept
   WHERE full_name NOT IN ('Doug Fiefia', 'Julie Jackson', 'Silvia Catten');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: % of the kept outside terms belong to somebody other than the three '
                    'this file was written about.', n;
  END IF;

  -- P9 — 🔴🔴 AND DOUG FIEFIA'S HOUSE SEAT IS STILL THE BLANK-RESULT ONE. He vacates House
  -- District 48 to take Senate District 18, and House District 48's own 2026 result is missing,
  -- so no successor exists to seat. If a winner HAS been recorded there, this file's account of
  -- why his House term stays open is out of date and P1 above should already have caught the
  -- larger wave — this names it explicitly.
  SELECT count(*) INTO n
    FROM cc0490_kept k
    JOIN essentials.districts d ON d.label = k.seat AND lower(d.state) = 'ut'
    JOIN essentials.offices o   ON o.district_id = d.id
   WHERE k.full_name = 'Doug Fiefia' AND k.seat = 'State House District 48'
     AND EXISTS (SELECT 1 FROM essentials.office_pending_winner w
                  WHERE w.office_id = o.id AND w.election_date = DATE '2026-11-03');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P9: State House District 48 now carries a 2026 winner. Doug Fiefia''s House '
                    'term was left open because no successor existed; re-read this file''s '
                    'header before applying it.';
  END IF;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK A — the incumbency guard, from migrations/_templates/office_terms_incumbency_guard.sql
-- ═════════════════════════════════════════════════════════════════════════════════════════════
--
-- @incumbency-decision: gated — this closes each predecessor at 2026-12-31, well after the
-- election, so every outgoing term still covers 2026-11-03 and the predicate's answer must not
-- move for anybody. The scope covers both sides: the 50 winners and the people whose terms are
-- closed.
--
-- ⚠ UTAH'S PREDECESSOR TERMS ARE ALL UNDATED, so the guard's `term_start IS NULL OR
--   term_start <= election_date` arm is satisfied by the NULL for every one of them, both before
--   and after. The closure moves `term_end` from NULL to 2026-12-31, which is still >= the
--   election date, so no answer moves. That is what this gate measures rather than assumes.
CREATE TEMP TABLE cc0490_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0490_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0490_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0490_guarded);

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0490_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in, "their term of office shall be '
                         || CASE WHEN r.district_type = 'STATE_LOWER' THEN 'two' ELSE 'four' END
                         || ' years from the first day of January next after their election" '
                         || '(Utah Const. Art. VI, Sec. '
                         || CASE WHEN r.district_type = 'STATE_LOWER' THEN '3(2)' ELSE '4(2)' END
                         || '). NOTE: the clause names a FIXED DAY of the calendar, not an '
                         || 'ordinal weekday — 2027-01-01 is a Friday and a public holiday and '
                         || 'is not rounded to the following Monday. The first Monday, '
                         || '2027-01-04, is the boundary Utah''s Board of Education statute '
                         || 'appears to use, and the Board''s six 2026 seats are REFUSED for '
                         || 'dating because 20A-14-103 names no commencement. '
                         || CASE WHEN r.is_reelection THEN 'Re-elected incumbent. '
                                 ELSE 'New holder; predecessor closed at 2026-12-31. ' END
                         || 'CC_0490',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0490: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0490_guarded;
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
  SELECT * INTO b FROM cc0490_before;
  SELECT * INTO p FROM cc0490_pin;

  -- 1. 50 new terms, one per selected office, on the day itself, naming the winner.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0490_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. office_next_term answers for all 50 — the view a voter's page reads for a dated handover.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0490_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_offices;
  END IF;

  -- 3. Repo-wide, exactly 50 more terms start on that day — no other state swept in. A DELTA,
  --    not a total.
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

  -- 5. 🔴 AND ALL 50 SEATS STILL ANSWER WITH TODAY'S HOLDER. ⚠ IS NOT DISTINCT FROM rather than
  --    `=` so a NULL on either side would be counted rather than silently dropped.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0490_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of % seats still answer office_current_holder with the person holding '
                    'them today.', n, p.expect_offices;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0490_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % of the 50 seats answer office_current_holder with nobody, expected 0 '
                    '— every Utah legislative seat is held today.', n;
  END IF;

  -- 6. Each predecessor named in the pre-image is closed the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0490_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0490_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 6b. ⚠ AND ALL 50 CLOSURES ARE STILL UNDATED AT THE START. This file writes an end onto a row
  --     with no beginning, 50 times, and that is the state Utah was in — recorded so the next
  --     reader does not take it for damage this file did.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0490_pre x ON x.term_id = t.id
   WHERE t.term_start IS NULL;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6b: % of % closed predecessor term(s) still have a NULL term_start, '
                    'expected all of them. Utah''s tenures are undated and this file does not '
                    'date them.', n, b.predecessors;
  END IF;

  -- 7. No term of these seats was closed between today and the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0490_sel s ON s.office_id = t.office_id
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

  -- 9. 🔴 NOT ONE SEAT STARTS ON THE FIRST MONDAY. 2027-01-04 is three days later and is the
  --    boundary the Board of Education's statute appears to use — a real day in the right month,
  --    reached by reading "first day" as "first Monday".
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0490_sel s ON s.office_id = t.office_id
   WHERE t.term_start = DATE '2027-01-04';
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % seat(s) start on 2027-01-04, the first MONDAY in January — the rule '
                    'Art. VI Secs. 3(2) and 4(2) do not state.', n;
  END IF;

  -- 10. 🔴🔴 NO UTAH BOARD OF EDUCATION SEAT WAS SEATED ON THIS DAY. 20A-14-103 names no
  --     commencement, its own transitional dates are first Mondays, and CC_0489 left all six
  --     undated on purpose.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ut' AND d.district_type = 'STATE_BOARD_EDUCATION'
     AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '10: % Utah Board of Education seat(s) were seated on the legislature''s '
                    'date. The Board''s commencement is not in statute and is REFUSED.', n;
  END IF;

  -- 11. 🔴 THE THREE KEPT TERMS ARE STILL OPEN — including Doug Fiefia's House District 48,
  --     which has no successor because its 2026 result is missing. Closing one would claim a
  --     resignation, or an end date, this pass has not read.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0490_kept k ON k.term_id = t.id
   WHERE t.term_end IS NULL;
  IF n <> b.kept THEN
    RAISE EXCEPTION '11: % of % term(s) held by a winner on an office outside this wave are '
                    'still open. This file closes the predecessor on the seat it seats and '
                    'nothing else.', n, b.kept;
  END IF;

  -- 12. 🔴 THE THREE BLANK-RESULT SEATS WERE NOT SEATED. Their candidate rows carry a NULL
  --     result and no result_source at all.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ut' AND t.term_start = p.expect_term_start
     AND (d.label, o.title) IN (
       ('State House District 48',  'State Representative District 48'),
       ('State House District 61',  'State Representative District 61'),
       ('State Senate District 11', 'State Senator District 11'));
  IF n <> 0 THEN
    RAISE EXCEPTION '12: % seat(s) with a blank 2026 result were seated.', n;
  END IF;

  -- 13. 🔴 NO UTAH OFFICE IS FLAGGED is_vacant AND THE REPO-WIDE COUNT DID NOT MOVE.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ut' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION '13: % Utah legislative office(s) are flagged is_vacant, expected 0.', n;
  END IF;

  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '13: the repo-wide count of flagged-vacant offices moved % -> %.',
      b.vacant_all, n;
  END IF;

  -- 14. Repo-wide, exactly 50 office_terms rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '14: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 15. Every new term cites this migration (Ruling B: recoverable by slot).
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0490_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0490%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '15: % of % new terms cite CC_0490.', n, p.expect_offices;
  END IF;

  -- 16. 🔴 THE SEATS HAVE LEFT THE PENDING-WINNER VIEW.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0490_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '16: % seat(s) still answer office_pending_winner.', n;
  END IF;

  -- 17. 🔴 THE DRIFT BASELINE DID NOT MOVE, AND NEITHER DID THE WHOLE VIEW. Every one of the 50
  --     seats already had a term row, so this file takes nothing OUT of offices_missing_terms.
  --     Both halves are asserted. 🔴 NEVER RAISE THE BASELINE.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '17: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> b.missing_all THEN
    RAISE EXCEPTION '17: offices_missing_terms went % -> %, expected no change — all 50 seats '
                    'already carried a term row.', b.missing_all, n;
  END IF;

  RAISE NOTICE 'CC_0490 OK: 50 Utah legislators scheduled for % (% re-elections, % handovers), '
               '% predecessors closed at % — every one of them an UNDATED tenure, which is the '
               'state Utah is in. Nobody moved today, no seat flagged vacant, the 6 Board of '
               'Education seats untouched (their commencement is refused), no seat on the first '
               'MONDAY 2027-01-04, the 3 blank-result seats left alone, and all 3 outside terms '
               'still open — including Doug Fiefia''s House District 48, which has no successor '
               'because its result is missing. Drift baseline % held.',
    p.expect_term_start, p.expect_reelections, p.expect_new, b.predecessors,
    p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
