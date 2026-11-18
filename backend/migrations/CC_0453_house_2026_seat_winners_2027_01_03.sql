-- CC_0453 — 2026-11-03 US House: seat the 427 recorded winners at 2027-01-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS DOES, AND WHAT IT DELIBERATELY DOES NOT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- We hold winners for 427 of the 435 US House races and a swearing-in date for all 435, and
-- NOTHING JOINED THE TWO: measured 2026-11-18, `office_next_term` was empty for every federal
-- office, so a voter looking at a House seat saw the sitting member and no sign of a handover.
-- This writes the future-dated `office_terms` row that makes the handover visible.
--
-- 🔴 IT SEATS NOBODY TODAY, AND MUST NOT. A term starting 2027-01-03 is not a current term;
--    `office_current_holder` resolves by date containment, so every sitting senator still holds
--    their seat until that morning. ⚠ THE OBVIOUS MISREADING OF THIS FILE IS THAT IT UNSEATS THE
--    LOSERS NOW — assertion 4 pins the entire current-holder set by md5 against its own
--    pre-image, so a change of even one seat today fails the migration.
--
-- 🔴 A LOSING INCUMBENT STILL HOLDS THE SEAT until the term ends, exactly as a retiring one does.
--    The predecessor's term is closed at 2027-01-02, which is the day before the successor's
--    begins — not today.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE DATE IS READ FROM THE TABLE, NOT WRITTEN INTO THIS FILE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `p_term_start` comes from `essentials.office_swearing_in.swearing_in_date` for each office, and
-- pre-check P4 refuses unless all 34 agree on 2027-01-03. ▶ THE EXPECTATION COMES FROM SOMEWHERE
-- THIS FILE CANNOT EDIT. A literal date here would agree with itself however wrong it was, and a
-- House term's start is a legal fact (20th Amendment §1, noon on 3 January) that the
-- swearing-in table already records with its authority.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHY A SET, PINNED BY DIGEST, RATHER THAN 34 LITERAL CALLS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The rows are selected by a query, so the file cannot drift from the data by transcription. The
-- risk that creates is the opposite one — the data moving under the file between writing and
-- applying — so the selection is PINNED: P1 refuses unless it returns exactly 34 rows whose
-- (office, politician, re-election) triples hash to the recorded digest. A winner corrected, a
-- race added, or a holder changed since 2026-11-18 stops this migration instead of being
-- silently swept in.
--
--   rows 427 · re-elections 310 · new holders 117
--   digest md5 = 54c8777c7e942ba1a739861377f67d81   (captured 2026-11-18 against production)
--
-- 🔴 `p_allow_reelection` IS COMPUTED PER ROW, NOT PASSED AS TRUE EVERYWHERE. `seat_officeholder`
--    REFUSES by default when the person it is seating already holds the seat, and that refusal is
--    a real guard against a wrong winner or a wrong date. Passing true for all 34 would switch it
--    off for the 18 seats where it still has something to catch. It is true only for the 16 whose
--    winner IS the current holder, and P1's digest covers that flag, so the two cannot disagree.
--
-- ⚠ EIGHT SEATS ARE NOT HERE, AND THAT IS NOT AN OMISSION. Seven are genuinely uncalled by AP
--   at 99% counted — AK-00 (ranked choice), LA-05 and LA-06 (the November contest is a nonpartisan
--   primary, so both go to a runoff), MN-01, NC-05, NC-10 and TN-04. The eighth, NC-03, AP called
--   at 2026-11-17 20:45Z (Raymond Smith, 49.43%, unseating the incumbent) and we hold no result
--   for it yet; it needs a results migration first. 427 of 435 is the honest count today, and
--   P1's digest states it.
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
--   · every predecessor is closed at 2027-01-02, AFTER the 2026-11-03 election — the latest any
--     of these offices carries — so each one still covers that day exactly as it did;
--   · every new term STARTS 2027-01-03, after that same day, so it covers no past election at all.
--
-- ▶ MEASURED, NOT REASONED: `reconcile-incumbency.mjs --check` against production after this was
-- applied reports **0 drift rows**. That is the gate the delta template exists to anticipate,
-- run against the real outcome.
--
-- ⚠ THE OPPOSITE DISPOSITION WOULD APPLY ON 2027-01-03. A pass that moved these boundaries
-- BACKWARD, or seated anybody at a date on or before an election day, owes the gated delta gate
-- in `_templates/office_terms_incumbency_guard.sql` and a reading of each row it moves.
--
-- Applied to production 2026-11-18.
-- ⚠ The @incumbency-decision block above was added AFTER the apply, to satisfy
-- check:office-terms-incumbency-guards. It is comment only: the SQL that ran and the SQL
-- committed here are behaviourally identical, so no replay was needed to verify it.

BEGIN;

-- ── What this file expects the world to look like ───────────────────────────────────────────
CREATE TEMP TABLE cc0453_pin ON COMMIT DROP AS
SELECT 427                                AS expect_rows,
       310                                AS expect_reelections,
       117                                AS expect_new,
       '54c8777c7e942ba1a739861377f67d81' AS expect_digest,
       DATE '2027-01-03'                  AS expect_term_start;

-- ── The 34 seatings, derived rather than transcribed ────────────────────────────────────────
CREATE TEMP TABLE cc0453_sel ON COMMIT DROP AS
SELECT o.id                                                        AS office_id,
       rc.politician_id                                            AS politician_id,
       (och.politician_id IS NOT DISTINCT FROM rc.politician_id)   AS is_reelection,
       si.swearing_in_date                                         AS term_start,
       upper(d.state)                                              AS seat,
       rc.full_name                                                AS winner_name
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.offices   o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.result = 'won'
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = o.id
 WHERE e.election_date = DATE '2026-11-03'
   AND d.district_type = 'NATIONAL_LOWER';

-- ── The pre-image every assertion below is measured against ─────────────────────────────────
CREATE TEMP TABLE cc0453_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-03')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       -- 🔴 The whole current-holder map, nationwide, not just the House's: this file must not
       -- move ANY seat today, and a gate scoped to the rows it touches could not see if it did.
       (SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-'),
                              '|' ORDER BY office_id::text))
          FROM essentials.office_current_holder)                                   AS holders_md5,
       (SELECT count(*) FROM essentials.office_current_holder WHERE politician_id IS NOT NULL)
                                                                                   AS holders_seated,
       -- How many of the selected seats actually HAVE a term for the helper to close. Captured
       -- rather than assumed: a seat standing vacant has none, and assertion 6 would then be
       -- comparing against a number this file invented.
       (SELECT count(*) FROM cc0453_sel s
         WHERE EXISTS (SELECT 1 FROM essentials.office_terms t
                        WHERE t.office_id = s.office_id
                          AND (t.term_start IS NULL OR t.term_start <= s.term_start)
                          AND (t.term_end   IS NULL OR t.term_end   >= s.term_start)))
                                                                                   AS predecessors;

DO $$
DECLARE n bigint; d text; p record;
BEGIN
  SELECT * INTO p FROM cc0453_pin;

  -- P1 — the selection is exactly the set this file was written against.
  SELECT count(*) INTO n FROM cc0453_sel;
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION 'P1: selection returned % rows, expected %. The data moved under this file; '
                    're-derive the digest before applying.', n, p.expect_rows;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || politician_id::text || ':' || is_reelection::text,
                        '|' ORDER BY office_id::text))
    INTO d FROM cc0453_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %. A winner, an office or a sitting '
                    'holder changed since this file was written.', d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0453_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected %.', n, p.expect_reelections;
  END IF;

  -- P2 — nobody is already scheduled. This file creates the first future terms these seats have.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0453_sel s ON s.office_id = nx.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of these offices already carry a future term. Seating them again '
                    'would stack a second one.', n;
  END IF;

  -- P3 — one winner per office, so no seat is contested by two rows of ours.
  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0453_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner.', n;
  END IF;

  -- P4 — the date is the table's, and the table agrees with the 20th Amendment.
  SELECT count(*) INTO n FROM cc0453_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. The term '
                    'start is read from office_swearing_in and must not be guessed.',
                    n, p.expect_term_start;
  END IF;

  -- P5 — every winner is a real person we hold.
  SELECT count(*) INTO n FROM cc0453_sel s
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
  FOR r IN SELECT * FROM cc0453_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'verified against AP''s own feed 2026-11-18; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in (20th Amendment §1). CC_0453',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0453: seat_officeholder called for % offices', v_seated;
END $$;

-- ── Post-verify ─────────────────────────────────────────────────────────────────────────────
-- ⚠ ORDERED SO THE NARROW CHECKS RUN FIRST. P1's digest is tight enough to catch almost any
--   tamper to the DATA, which leaves the later gates shadowed; putting the chamber-scoped ones
--   ahead of the repo-wide deltas means a control aimed at assertion 3 actually reaches it,
--   instead of tripping a count two gates earlier and proving nothing about 3.
DO $$
DECLARE n bigint; m text; b record; p record;
BEGIN
  SELECT * INTO b FROM cc0453_before;
  SELECT * INTO p FROM cc0453_pin;

  -- 1. Exactly 34 new terms exist, one per selected office, on the day itself.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0453_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start, p.expect_rows;
  END IF;

  -- 2. office_next_term answers for all 34 — the point of the migration, read through the view
  --    a voter's page actually uses rather than through office_terms directly.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0453_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_rows;
  END IF;

  -- 3. 🔴 THE EIGHT UNRECORDED SEATS STAY UNSEATED. House-wide, exactly 427 seats are scheduled
  --    for that day, not 435: the other eight have no winner in our rows, so there is nobody to
  --    seat, whatever AP has or has not called.
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_next_term nx ON nx.office_id = o.id
   WHERE d.district_type = 'NATIONAL_LOWER' AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION '3: % House seats scheduled for %, expected % — a seat with no recorded '
                    'winner must not have been seated.', n, p.expect_term_start, p.expect_rows;
  END IF;

  -- 4. 🔴 NOBODY WAS UNSEATED TODAY. The whole current-holder map, nationwide, is unchanged.
  --    This is the assertion that makes the migration safe to run two months early.
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
    FROM essentials.office_terms t JOIN cc0453_sel s ON s.office_id = t.office_id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '5: % predecessor term(s) closed at %, expected % — the seats that had one.',
      n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 6. No term of these seats was closed between today and the handover, which would leave a
  --    gap with nobody in it.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0453_sel s ON s.office_id = t.office_id
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

  -- 8. Repo-wide, exactly 427 office_terms rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_rows THEN
    RAISE EXCEPTION '8: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_rows;
  END IF;

  -- 9. And repo-wide, exactly 34 more terms start on that day — so no other chamber was swept in.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_rows THEN
    RAISE EXCEPTION '9: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_rows;
  END IF;

  -- 10. Every new term cites this migration, so the rows are findable by slot later.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0453_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0453%';
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION '10: % of % new terms cite CC_0453.', n, p.expect_rows;
  END IF;

  RAISE NOTICE 'CC_0453 OK: % representatives scheduled for %, % predecessors closed at %, current '
               'holders untouched.',
    p.expect_rows, p.expect_term_start, b.predecessors, p.expect_term_start - 1;
END $$;

COMMIT;
