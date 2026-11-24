-- CC_0461 — the two federal seats CC_0453 named and could not seat: Alaska's Senate seat and
-- NC-03, both at 2027-01-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHY THESE TWO WERE LEFT OUT, AND WHY THEY CAN BE SEATED NOW
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- CC_0453 seated 427 of 435 House seats on 2026-11-18 and listed the eight it could not. Its
-- header is explicit about NC-03: AP called it 2026-11-17 20:45Z and "we hold no result for it
-- yet; it needs a results migration first". CC_0454 wrote that result, and the Alaska Senate's,
-- after CC_0453 had run. So both seats have carried a recorded winner and no scheduled term ever
-- since — visible to a voter as "declared winner" on a seat whose start date is a constitutional
-- fact we already hold.
--
--   Alaska, Senator          Mary Peltola        (ranked choice)
--   NC, Congressional 3      Raymond Smith Jr.   (unseats the incumbent)
--
-- ⚠ NEITHER IS A RE-ELECTION. Both are handovers, so `p_allow_reelection` is false for both and
--   the helper's guard against a wrong winner or a wrong date stays armed on every row here.
--
-- 🔴 IT SEATS NOBODY TODAY, AND MUST NOT. A term starting 2027-01-03 is not a current term;
--    `office_current_holder` resolves by date containment, so both sitting members hold their
--    seats until that morning. Assertion 4 pins the entire current-holder map, nationwide,
--    against its own pre-image: a change of even one seat today fails this migration.
--
-- 🔴 A LOSING INCUMBENT STILL HOLDS THE SEAT until the term ends, exactly as a retiring one
--    does. Each predecessor's term is closed at 2027-01-02 — the day before the successor's
--    begins — and not today.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE DATE IS READ FROM THE TABLE, NOT WRITTEN INTO THIS FILE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `p_term_start` comes from `essentials.office_swearing_in.swearing_in_date` for each office, and
-- P4 refuses unless both agree on 2027-01-03 AND carry a basis of 'statute' or 'published'. Both
-- rows were written by CC_0348 citing U.S. Const. amend. XX § 1. ▶ THE EXPECTATION COMES FROM
-- SOMEWHERE THIS FILE CANNOT EDIT. A literal date here would agree with itself however wrong it
-- was.
--
-- 🔴 P4 ALSO REFUSES `basis = 'estimated'`. The table's CHECK permits that value; this pass does
--    not let one seat anybody. An estimate is a guess and a term start is a legal fact.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHY A SET, PINNED BY DIGEST, RATHER THAN TWO LITERAL CALLS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The rows are selected by query, so this file cannot drift from the data by transcription. The
-- risk that creates is the opposite one — the data moving under the file between writing and
-- applying — so the selection is PINNED. The four values below were derived by
-- `scripts/derive-seating-wave.mjs`, which computes in JS the exact string `string_agg` computes
-- in SQL; the two were compared against production over 99 unrelated rows and agreed, and the
-- comparison was watched failing on a 149-row selection before it was trusted.
--
--   rows 2 · re-elections 0 · new holders 2
--   digest md5 = 12671b064ca6454c415fc410db2698ba   (captured 2026-11-21 against production)
--   called 2 · certified 0 on the day this was captured
--
-- 🔴 BOTH RESULTS ARE `called`, NOT `certified` — 1,943 of the 1,945 November winners are. This
--    is the same exposure CC_0453 accepted for 427 House seats, and the reason assertion 10
--    exists: every term this writes cites CC_0461 in its `source`, so if a canvass reverses one
--    the rows are findable by slot rather than by memory.
--
-- 🔴 THE DIGEST'S SORT KEY IS (office, politician) AND A MISSING WINNER RENDERS AS '-'.
--    CC_0453 sorted on the office alone, which is safe only because its P3 guaranteed one winner
--    per office. That holds here too, but the expression is kept identical to the one every
--    state wave will use, where it does NOT hold: 71 state offices carry two or three winners on
--    one row. See scripts/lib/seating-wave.mjs for why each detail is load-bearing.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- @incumbency-decision: no-effect — every term row this writes or changes covers exactly the
-- election days it covered before, so no cached answer can move.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `race_candidates.is_incumbent` means "incumbent OF THE SEAT THIS RACE IS FOR, on the race's own
-- election date", it is cached, and nothing recomputes it — so moving a term boundary across an
-- election day silently restates who held that seat on it. 🔴 THIS FILE MOVES NO BOUNDARY ACROSS
-- ONE, and the claim is checkable in two numbers rather than asserted:
--
--   · each predecessor is closed at 2027-01-02, AFTER the 2026-11-03 election — the latest any
--     of these offices carries — so each one still covers that day exactly as it did;
--   · each new term STARTS 2027-01-03, after that same day, so it covers no past election.

BEGIN;

-- ── What this file expects the world to look like ───────────────────────────────────────────
CREATE TEMP TABLE cc0461_pin ON COMMIT DROP AS
SELECT 2                                  AS expect_rows,
       0                                  AS expect_reelections,
       2                                  AS expect_new,
       '12671b064ca6454c415fc410db2698ba' AS expect_digest,
       DATE '2027-01-03'                  AS expect_term_start;

-- ── The two seatings, derived rather than transcribed ───────────────────────────────────────
-- 🔴 THIS SELECTION IS `scripts/lib/seating-wave.mjs`'s WAVE_SELECTION_SQL, column for column.
--    If the two ever differ the digest cannot match and P1 refuses every wave, reporting that
--    the data moved when what moved was this file.
CREATE TEMP TABLE cc0461_sel ON COMMIT DROP AS
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
 WHERE d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_LOWER')
   AND w.election_date = DATE '2026-11-03';

-- ── The pre-image every assertion below is measured against ─────────────────────────────────
CREATE TEMP TABLE cc0461_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-03')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       -- 🔴 The whole current-holder map, nationwide, not just these two seats': this file must
       -- not move ANY seat today, and a gate scoped to the rows it touches could not see if it
       -- did.
       (SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-'),
                              '|' ORDER BY office_id::text))
          FROM essentials.office_current_holder)                                   AS holders_md5,
       -- Federal seats already scheduled for that morning, so assertion 3 can read a DELTA
       -- rather than a repo-wide total somebody else can move between sessions.
       (SELECT count(*)
          FROM essentials.offices o
          JOIN essentials.districts d ON d.id = o.district_id
          JOIN essentials.office_next_term nx ON nx.office_id = o.id
         WHERE d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_LOWER')
           AND nx.term_start = DATE '2027-01-03')                                  AS federal_on_the_day,
       -- How many of the selected seats actually HAVE a term for the helper to close. Captured
       -- rather than assumed: a seat standing vacant has none, and assertion 5 would then be
       -- comparing against a number this file invented.
       (SELECT count(*) FROM cc0461_sel s
         WHERE EXISTS (SELECT 1 FROM essentials.office_terms t
                        WHERE t.office_id = s.office_id
                          AND (t.term_start IS NULL OR t.term_start <= s.term_start)
                          AND (t.term_end   IS NULL OR t.term_end   >= s.term_start)))
                                                                                   AS predecessors;

DO $$
DECLARE n bigint; d text; p record;
BEGIN
  SELECT * INTO p FROM cc0461_pin;

  -- P1 — the selection is exactly the set this file was written against.
  SELECT count(*) INTO n FROM cc0461_sel;
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION 'P1: selection returned % rows, expected %. The data moved under this file; '
                    're-derive the digest before applying.', n, p.expect_rows;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0461_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %. A winner, an office or a sitting '
                    'holder changed since this file was written.', d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0461_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected %.', n, p.expect_reelections;
  END IF;

  -- P2 — this file has not already been applied.
  --
  -- 🔴 NOT CC_0453's P2, AND THE DIFFERENCE WAS FOUND BY WATCHING ITS CONTROL. CC_0453 selected
  --    from `races` and asked whether any selected office already carried an `office_next_term`
  --    row. Written against THIS selection that question is dead code: the rows come from
  --    `essentials.office_pending_winner`, and CC_0460 already excludes from that view every
  --    office carrying a term dated on or after the election. A seat that is already scheduled
  --    has therefore left the selection, and the join can only ever return 0. Measured: the
  --    control seated Alaska at 2027-01-03, confirmed the term was present, and CC_0453's P2
  --    still returned 0. By this repo's own standard a gate that cannot be watched failing is
  --    not a gate — it is CC_0341's tautology in a new place.
  --
  --    What is live instead: P1's row count fires on a re-run, because the selection returns 0
  --    rows rather than 2. This gate is the one that says WHY in words, so the next person is
  --    not told the data moved under a file when what happened is that they ran it twice.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0461%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0461. This migration has been '
                    'applied before. Applying it again would stack a second term on each seat.', n;
  END IF;

  -- P3 — one winner per office, so no seat is contested by two rows of ours.
  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0461_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner.', n;
  END IF;

  -- P4 — the date is the table's, it agrees with the 20th Amendment, and it is not an estimate.
  SELECT count(*) INTO n FROM cc0461_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. The term '
                    'start is read from office_swearing_in and must not be guessed.',
                    n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0461_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published. An '
                    'estimated date may not seat anybody.', n;
  END IF;

  -- P5 — every winner is a real person we hold.
  SELECT count(*) INTO n FROM cc0461_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat.', n;
  END IF;
END $$;

-- ── The write ───────────────────────────────────────────────────────────────────────────────
-- `seat_officeholder` is the house helper and does the two-step: it closes the predecessor's
-- open-ended term at term_start - 1 and opens the successor's. Hand-rolling that is how a
-- predecessor ends up with an infinite range overlapping the new one.
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0461_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates by '
                         || 'CC_0454 and called, not certified, when this ran; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in (20th Amendment §1). CC_0461',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0461: seat_officeholder called for % offices', v_seated;
END $$;

-- ── Post-verify ─────────────────────────────────────────────────────────────────────────────
-- ⚠ ORDERED SO THE NARROW CHECKS RUN FIRST. P1's digest is tight enough to catch almost any
--   tamper to the DATA, which leaves the later gates shadowed; putting the seat-scoped ones
--   ahead of the repo-wide deltas means a control aimed at a given assertion actually reaches it
--   instead of tripping a count two gates earlier and proving nothing about the one it meant.
DO $$
DECLARE n bigint; m text; b record; p record;
BEGIN
  SELECT * INTO b FROM cc0461_before;
  SELECT * INTO p FROM cc0461_pin;

  -- 1. Exactly two new terms exist, one per selected office, on the day itself.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0461_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start, p.expect_rows;
  END IF;

  -- 2. office_next_term answers for both — the point of the migration, read through the view a
  --    voter's page actually uses rather than through office_terms directly.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0461_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_rows;
  END IF;

  -- 3. 🔴 THE SIX STILL-UNCALLED SEATS STAY UNSEATED. Read as a DELTA against this transaction's
  --    own pre-image, not against a repo-wide total: CC_0453 wrote a literal 427, and another
  --    session seating a federal seat between then and now would have failed this file for
  --    something it did not do.
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_next_term nx ON nx.office_id = o.id
   WHERE d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_LOWER')
     AND nx.term_start = p.expect_term_start;
  IF n <> b.federal_on_the_day + p.expect_rows THEN
    RAISE EXCEPTION '3: federal seats scheduled for % went % -> %, a delta of %, expected % — a '
                    'seat with no recorded winner must not have been seated.',
      p.expect_term_start, b.federal_on_the_day, n, n - b.federal_on_the_day, p.expect_rows;
  END IF;

  -- 4. 🔴 NOBODY WAS UNSEATED TODAY. The whole current-holder map, nationwide, is unchanged.
  --    This is the assertion that makes the migration safe to run six weeks early.
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-'),
                        '|' ORDER BY office_id::text))
    INTO m FROM essentials.office_current_holder;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today.', b.holders_md5, m;
  END IF;

  -- 5. Each seat that HAD a term has it closed the day before the handover — not earlier, and
  --    not today. The count comes from the pre-image, so a vacant seat is not miscounted.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0461_sel s ON s.office_id = t.office_id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '5: % predecessor term(s) closed at %, expected % — the seats that had one.',
      n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 6. No term of these seats was closed between today and the handover, which would leave a gap
  --    with nobody in it.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0461_sel s ON s.office_id = t.office_id
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

  -- 8. Repo-wide, exactly two office_terms rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_rows THEN
    RAISE EXCEPTION '8: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_rows;
  END IF;

  -- 9. And repo-wide, exactly two more terms start on that day — so no other chamber was swept
  --    in alongside.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_rows THEN
    RAISE EXCEPTION '9: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_rows;
  END IF;

  -- 10. 🔴 EVERY NEW TERM CITES THIS MIGRATION. Both results were `called`, so a canvass can
  --     still reverse one; `source LIKE '%CC_0461%'` is how the exact set is recovered when it
  --     does, rather than by remembering which rows these were.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0461_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0461%';
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION '10: % of % new terms cite CC_0461.', n, p.expect_rows;
  END IF;

  -- 11. The seats have left the pending-winner view, which is what a voter's card reads from.
  --     Without this the migration can pass every gate above and leave the page unchanged.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0461_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '11: % seat(s) still answer office_pending_winner, so the card still reads '
                    'as a declared result rather than a dated handover.', n;
  END IF;

  RAISE NOTICE 'CC_0461 OK: % federal seats scheduled for %, % predecessors closed at %, current '
               'holders untouched.',
    p.expect_rows, p.expect_term_start, b.predecessors, p.expect_term_start - 1;
END $$;

COMMIT;
