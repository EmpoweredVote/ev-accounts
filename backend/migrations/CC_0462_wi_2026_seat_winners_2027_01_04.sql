-- CC_0462 — Wisconsin's 121 2026 winners take office 2027-01-04: 99 Assembly, 17 Senate,
-- 5 statewide executives.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE FIRST STATE WAVE, AND THE ONLY ONE THAT NEEDED NO RESEARCH
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 1,286 state offices hold a 2026 winner and no scheduled term, across 73 (state, district_type)
-- bodies. Exactly 121 of them already carry a cited start date, and every one of those 121 is
-- Wisconsin — written by CC_0445. So this is the whole state in one file, and the rest of the
-- pass is 70 bodies whose dates nobody has sourced yet.
--
-- The body measures clean, which is why it goes first: 0 offices carrying more than one winner,
-- 0 winners without a politicians row, 0 flagged vacant, 0 already scheduled, 0 estimated dates.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 IS THE CITED DATE A TERM START, OR A SWEARING-IN? FOR WISCONSIN, BOTH — AND THAT IS A
--    FINDING ABOUT WISCONSIN, NOT A RULE FOR ANY OTHER STATE.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- A term start and a swearing-in are different events with different sources, and the design's
-- non-goal forbids rendering one as the other. States genuinely differ: some define the term as
-- beginning on a fixed calendar date with the oath taken afterwards, others define it as
-- beginning ON QUALIFICATION, which IS the oath. Wisconsin puts both on one day:
--
--   · Wis. Const. art. XIII § 1 — "The political year for this state shall commence on the first
--     Monday of January in each year", which is the calendar date the term begins.
--   · Wis. Stat. § 13.02(1) — the legislature convenes "in the capitol on the first Monday of
--     January in each odd-numbered year, at 2 p.m., to take the oath of office", which puts the
--     oath on that same day.
--
-- Terms: art. IV § 4 (Assembly, biennial), art. IV § 5 (Senate, 4 years, odd and even districts
-- alternating), art. V § 1 and art. VI § 1 (the executives, 4 years). All of this is recorded in
-- `essentials.office_swearing_in.authority` per office by CC_0445; this file reads the date from
-- there and never writes one of its own.
--
-- ▶ THE NEXT STATE GETS THIS QUESTION ASKED AGAIN, FROM ITS OWN LAW. Wisconsin settles
--   Wisconsin.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 IT SEATS NOBODY TODAY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- A term starting 2027-01-04 is not a current term; `office_current_holder` resolves by date
-- containment. Every sitting legislator holds their seat until that morning, and assertion 4
-- pins the entire current-holder map NATIONWIDE against its own pre-image — a change of even one
-- seat anywhere fails this migration. A losing incumbent still holds the seat exactly as a
-- retiring one does; each predecessor is closed at 2027-01-03, the day before, and not today.
--
-- 🔴 `p_allow_reelection` IS COMPUTED PER ROW, NOT PASSED TRUE EVERYWHERE. `seat_officeholder`
--    refuses by default when the person it is seating already holds the seat, and that refusal
--    is a real guard against a wrong winner or a wrong date. 90 of these 121 are the sitting
--    member returned; passing true for all 121 would switch the guard off for the 31 genuine
--    handovers, which are the rows it still has something to catch. P1's digest covers the flag,
--    so the file and the data cannot disagree about which is which.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SELECTION IS PINNED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   rows 121 · re-elections 90 · new holders 31
--   digest md5 = 6a4eed1b03987e20e215fa8436aed8dc   (captured 2026-11-21 against production)
--   called 121 · certified 0 on the day this was captured
--
-- Derived by `scripts/derive-seating-wave.mjs`, whose digest was compared against Postgres over
-- these same 99 Assembly rows and agreed, and whose comparison was watched failing on a 149-row
-- Maine selection before it was trusted.
--
-- 🔴 ALL 121 RESULTS ARE `called`, NOT `certified`. 1,943 of the 1,945 November winners are, so
--    waiting for certification means shipping nothing; CC_0453 accepted the same exposure for
--    427 House seats. Assertion 10 is what makes it recoverable: every term written here cites
--    CC_0462 in its `source`, so a reversed canvass is answered by a query rather than by
--    remembering which rows these were.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- @incumbency-decision: no-effect — every term row this writes or changes covers exactly the
-- election days it covered before, so no cached answer can move.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `race_candidates.is_incumbent` means "incumbent OF THE SEAT THIS RACE IS FOR, on the race's own
-- election date", it is cached, and nothing recomputes it. 🔴 THIS FILE MOVES NO BOUNDARY ACROSS
-- AN ELECTION DAY:
--
--   · every predecessor is closed at 2027-01-03, AFTER the 2026-11-03 election, so each still
--     covers that day exactly as it did;
--   · every new term STARTS 2027-01-04, so it covers no past election at all.

BEGIN;

-- ── What this file expects the world to look like ───────────────────────────────────────────
CREATE TEMP TABLE cc0462_pin ON COMMIT DROP AS
SELECT 121                                AS expect_rows,
       90                                 AS expect_reelections,
       31                                 AS expect_new,
       '6a4eed1b03987e20e215fa8436aed8dc' AS expect_digest,
       DATE '2027-01-04'                  AS expect_term_start;

-- ── The 121 seatings, derived rather than transcribed ───────────────────────────────────────
-- 🔴 THIS SELECTION IS `scripts/lib/seating-wave.mjs`'s WAVE_SELECTION_SQL, column for column.
CREATE TEMP TABLE cc0462_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       (win.value ->> 'id')::uuid                        AS politician_id,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id'))
                                                         AS is_reelection,
       si.swearing_in_date                               AS term_start,
       si.basis                                          AS basis,
       d.label                                           AS seat,
       (win.value ->> 'name')                            AS winner_name
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = o.id
                                                AND si.election_date = DATE '2026-11-03'
 WHERE lower(d.state) = 'wi'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC')
   AND w.election_date = DATE '2026-11-03';

-- ── The pre-image every assertion below is measured against ─────────────────────────────────
CREATE TEMP TABLE cc0462_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-04')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-'),
                              '|' ORDER BY office_id::text))
          FROM essentials.office_current_holder)                                   AS holders_md5,
       (SELECT count(*)
          FROM essentials.offices o
          JOIN essentials.districts d ON d.id = o.district_id
          JOIN essentials.office_next_term nx ON nx.office_id = o.id
         WHERE lower(d.state) = 'wi'
           AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC')
           AND nx.term_start = DATE '2027-01-04')                                  AS wi_on_the_day,
       -- 🔴 THE DRIFT BASELINE, CAPTURED HERE SO ASSERTION 12 READS A DELTA. Only the UNFLAGGED
       -- number is the baseline (238), and seating must not move it. It cannot: all 121 of these
       -- offices are currently held, so none of them is in that bucket. Asserted rather than
       -- assumed.
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged,
       (SELECT count(*) FROM cc0462_sel s
         WHERE EXISTS (SELECT 1 FROM essentials.office_terms t
                        WHERE t.office_id = s.office_id
                          AND (t.term_start IS NULL OR t.term_start <= s.term_start)
                          AND (t.term_end   IS NULL OR t.term_end   >= s.term_start)))
                                                                                   AS predecessors;

DO $$
DECLARE n bigint; d text; p record;
BEGIN
  SELECT * INTO p FROM cc0462_pin;

  -- P1 — the selection is exactly the set this file was written against.
  SELECT count(*) INTO n FROM cc0462_sel;
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION 'P1: selection returned % rows, expected %. The data moved under this file; '
                    're-derive the digest before applying.', n, p.expect_rows;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0462_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %. A winner, an office or a sitting '
                    'holder changed since this file was written.', d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0462_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected %. p_allow_reelection is computed from this '
                    'flag, so a disagreement disarms the helper on the wrong rows.',
                    n, p.expect_reelections;
  END IF;

  -- P2 — this file has not already been applied. (CC_0453's version of P2 is dead code against a
  -- selection drawn from office_pending_winner: a scheduled office has already left that view.
  -- See CC_0461's header for the control that established it.)
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0462%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0462. This migration has been '
                    'applied before. Applying it again would stack a second term on each seat.', n;
  END IF;

  -- P3 — one winner per office. Wisconsin has no multi-seat race, and this is what says so
  -- rather than assuming it: 71 state offices elsewhere carry two or three winners on one row,
  -- and those need the interchangeability ruling, not this file.
  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0462_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner. This wave cannot seat them.', n;
  END IF;

  -- P4 — the date is the table's, every office agrees on it, and it is not an estimate.
  SELECT count(*) INTO n FROM cc0462_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. The term '
                    'start is read from office_swearing_in and must not be guessed.',
                    n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0462_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published. An '
                    'estimated date may not seat anybody.', n;
  END IF;

  -- P5 — every winner is a real person we hold.
  SELECT count(*) INTO n FROM cc0462_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat.', n;
  END IF;

  -- P6 — 🔴 NO SEAT IN THIS WAVE IS FLAGGED VACANT. A future-dated seating must leave the flag
  -- alone, because the seat really is empty until that morning; but a flagged seat here would
  -- mean the wave is mixing a live vacancy into a routine handover, and `seat_officeholder` does
  -- not clear the flag either way. Wisconsin has none. Assert it rather than assume it.
  SELECT count(*) INTO n
    FROM cc0462_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) in this wave are flagged is_vacant. Decide what each one is '
                    'before seating it.', n;
  END IF;
END $$;

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0462_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in (Wis. Const. art. XIII §1 with '
                         || 'Wis. Stat. §13.02(1)). CC_0462',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0462: seat_officeholder called for % offices', v_seated;
END $$;

-- ── Post-verify ─────────────────────────────────────────────────────────────────────────────
-- ⚠ ORDERED SO THE NARROW CHECKS RUN FIRST, so a control aimed at a given assertion reaches it
--   instead of tripping a repo-wide count two gates earlier.
DO $$
DECLARE n bigint; m text; b record; p record;
BEGIN
  SELECT * INTO b FROM cc0462_before;
  SELECT * INTO p FROM cc0462_pin;

  -- 1. Exactly 121 new terms exist, one per selected office, on the day itself.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0462_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start, p.expect_rows;
  END IF;

  -- 2. office_next_term answers for all 121 — read through the view a voter's page uses.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0462_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_rows;
  END IF;

  -- 3. Wisconsin state-tier seats scheduled for that morning went up by exactly 121 — so a seat
  --    with no recorded winner was not swept in. A DELTA against this transaction's own
  --    pre-image, never a repo-wide total another session can move between sessions.
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_next_term nx ON nx.office_id = o.id
   WHERE lower(d.state) = 'wi'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC')
     AND nx.term_start = p.expect_term_start;
  IF n <> b.wi_on_the_day + p.expect_rows THEN
    RAISE EXCEPTION '3: Wisconsin seats scheduled for % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.wi_on_the_day, n, n - b.wi_on_the_day, p.expect_rows;
  END IF;

  -- 4. 🔴 NOBODY WAS UNSEATED TODAY, anywhere in the country.
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-'),
                        '|' ORDER BY office_id::text))
    INTO m FROM essentials.office_current_holder;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today.', b.holders_md5, m;
  END IF;

  -- 5. Each seat that HAD a term has it closed the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0462_sel s ON s.office_id = t.office_id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '5: % predecessor term(s) closed at %, expected % — the seats that had one.',
      n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 6. No term of these seats was closed between today and the handover, which would leave a gap
  --    with nobody in it.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0462_sel s ON s.office_id = t.office_id
   WHERE t.term_end IS NOT NULL
     AND t.term_end >= CURRENT_DATE AND t.term_end < p.expect_term_start - 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '6: % term(s) closed between today and the day before the handover.', n;
  END IF;

  -- 7. This file creates no people and no offices.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '7: politicians moved from % to %.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '7: offices moved from % to %.', b.offices, n;
  END IF;

  -- 8. Repo-wide, exactly 121 office_terms rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_rows THEN
    RAISE EXCEPTION '8: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_rows;
  END IF;

  -- 9. And repo-wide, exactly 121 more terms start on that day — no other state swept in.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_rows THEN
    RAISE EXCEPTION '9: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_rows;
  END IF;

  -- 10. Every new term cites this migration, so a reversed canvass is answered by a query.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0462_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0462%';
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION '10: % of % new terms cite CC_0462.', n, p.expect_rows;
  END IF;

  -- 11. 🔴 THE SEATS HAVE LEFT THE PENDING-WINNER VIEW. This is the one assertion that says the
  --     VOTER'S CARD changed: without it the migration can pass everything above and leave the
  --     page reading "declared winner" exactly as before.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0462_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '11: % seat(s) still answer office_pending_winner, so the card still reads '
                    'as a declared result rather than a dated handover.', n;
  END IF;

  -- 12. 🔴 THE 238 UNFLAGGED DRIFT BASELINE DID NOT MOVE. Read as a delta against this
  --     transaction's own pre-image, because the number moves under you between sessions and a
  --     literal 238 here would fail this file for somebody else's work.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '12: the unflagged offices_missing_terms count moved % -> %. Seating must '
                    'never raise the drift baseline.', b.missing_unflagged, n;
  END IF;

  RAISE NOTICE 'CC_0462 OK: % Wisconsin seats scheduled for % (% re-elected, % handovers), '
               '% predecessors closed at %, current holders untouched, drift baseline % held.',
    p.expect_rows, p.expect_term_start, p.expect_reelections, p.expect_new,
    b.predecessors, p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
