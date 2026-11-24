-- CC_0480 — California: clear `is_vacant` on Assembly District 3 and State Senate District 10,
-- on the day their winners take the seats.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 DO NOT APPLY THIS FILE BEFORE 2026-12-07. IT REFUSES, AND THE REFUSAL IS THE POINT.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- ⚠ THE GUARD IS NOT A CALENDAR CHECK — IT IS THE SAFETY PROPERTY ITSELF. P3 refuses unless each
--   of these two offices already has a term covering TODAY. That becomes true on 2026-12-07 on
--   its own, when CC_0478's terms begin, so this file is self-scheduling: it cannot run early
--   and it needs no diary entry to run on time. A date literal would have been a reminder; this
--   is an interlock.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHY THE FLAG IS NOT CLEARED IN THE SEATING MIGRATION
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--     Assembly District 3        James Gallagher resigned; his term closed 2026-06-09
--     State Senate District 10   Aisha Wahab resigned; her term closed 2026-09-01
--
-- Both seats are genuinely empty until 2026-12-07, so `is_vacant` is TRUE and CORRECT today —
-- it is not stale data. CC_0478 schedules Dom Belza and Scott Sakakihara for 2026-12-07 and
-- deliberately leaves the flag alone, because `seat_officeholder` writes `office_terms` and
-- never touches `essentials.offices`. From the morning of the 7th each seat would otherwise read
-- **held AND vacant at the same time**, which is what this file settles.
--
-- 🔴 CLEARING EARLY IS THE MISTAKE, AND IT FAILS UNDER SOMEBODY ELSE'S NAME. Each of these is
--    the only office in its district. Clear the flag while the seat is still empty and the
--    district reads
--
--        reachable = true AND offices > 0 AND active_holders = 0 AND vacant_offices = 0
--
--    which is verbatim `DEAD_GEOGRAPHY` in `scripts/check-address-reachability.mjs`. That gate
--    is MASTER-ONLY: it reads production data with master's code, after the merge, so it would
--    go red on the NEXT pull request and name an innocent author. The federal pair (TX-23,
--    FL-20) has exactly this shape and `CC_0455` clears them on 2027-01-03 for the same reason.
--
-- ▶ On 2026-12-07 `active_holders` becomes 1 for each district, so the dead-geography shape
--   cannot arise and clearing the flag is simply the truth catching up. Assertion 4 measures
--   that directly — it recomputes the gate's own predicate for both districts after the write.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Two rows in `essentials.offices`, one column:
--
--     Assembly District 3        is_vacant: true -> false
--     State Senate District 10   is_vacant: true -> false
--
-- Measured against production 2026-11-23, not inferred: both read TRUE. ⚠ `vacant_since` is NOT
-- touched. It records when the seat fell empty, which remains a true fact about the past, and
-- CLAUDE.md's rule is that a migration overwriting a value records what it overwrote — so this
-- file overwrites the one column it names and leaves the companion alone rather than quietly
-- blanking a date no other file holds.
--
-- P2 refuses if either flag is already false, so a second apply stops rather than reporting
-- success over rows it did not change.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ THE DRIFT BASELINE IS UNAFFECTED, AND THAT IS WORTH STATING RATHER THAN HOPING
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `essentials.offices_missing_terms` lists offices with NO `office_terms` row at all. Both of
-- these have had one since well before this pass (Gallagher's and Wahab's closed terms), so
-- neither is in the view before or after, and moving them from flagged to unflagged cannot move
-- the 238. Assertion 5 asserts both halves: the count is unchanged AND neither office is in the
-- view. 🔴 NEVER RAISE THAT BASELINE.

BEGIN;

CREATE TEMP TABLE cc0480_sel ON COMMIT DROP AS
SELECT o.id AS office_id, d.label AS seat, o.is_vacant, o.vacant_since,
       d.id AS district_id_self
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'ca'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND d.label IN ('Assembly District 3', 'State Senate District 10');

CREATE TEMP TABLE cc0480_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged;

DO $$
DECLARE n bigint; v_seat record;
BEGIN
  -- P1 — exactly the two offices this file names, one per district.
  SELECT count(*) INTO n FROM cc0480_sel;
  IF n <> 2 THEN
    RAISE EXCEPTION 'P1: % California office(s) match Assembly District 3 / State Senate '
                    'District 10, expected exactly 2 (one office per district — that is why '
                    'clearing the flag early reads as a dead district).', n;
  END IF;

  -- P2 — this file has not already been applied, and both flags are still set. 🔴 ASKED ABOVE
  -- P3: on a second run the flags are false and P3's holder check would PASS, so the operator
  -- would be shown a green file that changed nothing.
  SELECT count(*) INTO n FROM cc0480_sel WHERE NOT is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the 2 seats is already unflagged. Applied before, or somebody '
                    'else cleared it — read the row before writing over it.', n;
  END IF;

  -- P3 — 🔴🔴 THE INTERLOCK. Each seat must ALREADY be held today. Before 2026-12-07 it is not,
  -- and this file must refuse: clearing the flag while the seat is empty is the DEAD_GEOGRAPHY
  -- shape, and that gate fails on master, on somebody else's pull request.
  FOR v_seat IN SELECT * FROM cc0480_sel LOOP
    SELECT count(*) INTO n
      FROM essentials.office_terms t
     WHERE t.office_id = v_seat.office_id
       AND t.term_start IS NOT NULL AND t.term_start <= CURRENT_DATE
       AND (t.term_end IS NULL OR t.term_end >= CURRENT_DATE);
    IF n <> 1 THEN
      RAISE EXCEPTION 'P3: % has % term(s) covering today (%), expected exactly 1. 🔴 DO NOT '
                      'APPLY THIS FILE BEFORE 2026-12-07 — that is the day CC_0478''s terms '
                      'begin under Cal. Const. art. IV, § 2(a)(3). Clearing is_vacant while the '
                      'seat is empty makes the district read offices > 0, active_holders = 0, '
                      'vacant_offices = 0, which is DEAD_GEOGRAPHY in a master-only gate.',
        v_seat.seat, n, CURRENT_DATE;
    END IF;
  END LOOP;

  -- P4 — the term covering today is the one CC_0478 wrote. A seat filled by appointment in the
  -- meantime is a different fact and this file is not the place to absorb it.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0480_sel s ON s.office_id = t.office_id
   WHERE t.term_start = DATE '2026-12-07' AND t.source LIKE '%CC_0478%';
  IF n <> 2 THEN
    RAISE EXCEPTION 'P4: % of the 2 seats is held under a term CC_0478 wrote for 2026-12-07. '
                    'Something else filled this seat — read it.', n;
  END IF;
END $$;

UPDATE essentials.offices o
   SET is_vacant = false
  FROM cc0480_sel s
 WHERE o.id = s.office_id;

DO $$
DECLARE n bigint; b record; v_seat record;
BEGIN
  SELECT * INTO b FROM cc0480_before;

  -- 1. Both flags are down.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN cc0480_sel s ON s.office_id = o.id
   WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION '1: % of the 2 seats is still flagged is_vacant.', n;
  END IF;

  -- 2. Repo-wide, exactly two flags moved, and nothing else in offices changed count.
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all - 2 THEN
    RAISE EXCEPTION '2: flagged-vacant offices went % -> %, a delta of %, expected -2.',
      b.vacant_all, n, n - b.vacant_all;
  END IF;

  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '2: offices moved from % to %. This file changes one column on two rows.',
      b.offices, n;
  END IF;

  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all THEN
    RAISE EXCEPTION '2: office_terms moved from % to %. This file seats nobody — CC_0478 did.',
      b.terms_all, n;
  END IF;

  -- 3. ⚠ `vacant_since` was NOT blanked. It records when the seat fell empty, which stays true.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN cc0480_sel s ON s.office_id = o.id
   WHERE o.vacant_since IS DISTINCT FROM s.vacant_since;
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % of the 2 rows had vacant_since changed. This file clears one column.',
      n;
  END IF;

  -- 4. 🔴🔴 THE GATE'S OWN PREDICATE, RECOMPUTED FOR BOTH DISTRICTS. "offices > 0 AND
  --    active_holders = 0 AND vacant_offices = 0" is DEAD_GEOGRAPHY; after this file each
  --    district must have an active holder, so the shape cannot arise.
  FOR v_seat IN SELECT * FROM cc0480_sel LOOP
    SELECT count(*) INTO n
      FROM essentials.offices o
      JOIN essentials.office_terms t ON t.office_id = o.id
     WHERE o.district_id = v_seat.district_id_self
       AND t.term_start IS NOT NULL AND t.term_start <= CURRENT_DATE
       AND (t.term_end IS NULL OR t.term_end >= CURRENT_DATE);
    IF n < 1 THEN
      RAISE EXCEPTION '4: % has no active holder after this file, so its district now reads '
                      'DEAD_GEOGRAPHY — offices > 0, active_holders = 0, vacant_offices = 0. '
                      'That gate runs on master and fails on the next pull request.', v_seat.seat;
    END IF;
  END LOOP;

  -- 5. The 238 unflagged drift baseline did not move, and neither seat entered the view.
  --    offices_missing_terms lists offices with NO term at all; both of these have had one
  --    since Gallagher and Wahab, so unflagging them cannot add either. 🔴 NEVER RAISE IT.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '5: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN cc0480_sel s ON s.office_id = m.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % of the 2 seats is in offices_missing_terms, which should be '
                    'impossible — each has carried a term since its predecessor resigned.', n;
  END IF;

  -- 6. Both seats now read as held, by the people CC_0478 seated.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0480_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT NULL;
  IF n <> 2 THEN
    RAISE EXCEPTION '6: % of the 2 seats answers office_current_holder with a person.', n;
  END IF;

  RAISE NOTICE 'CC_0480 OK: is_vacant cleared on Assembly District 3 and State Senate District '
               '10 (true -> false on both; vacant_since left alone), on a day when both are '
               'held under CC_0478''s terms, so neither district can read DEAD_GEOGRAPHY; '
               'drift baseline % held.', b.missing_unflagged;
END $$;

COMMIT;
