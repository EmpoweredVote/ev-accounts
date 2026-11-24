-- CC_0500 — Maryland: seat the Governor won on 2026-11-03 for 2027-01-20.
--
-- Second of two. CC_0499 writes the date (one office, Md. Const. Art. II § 1, the third Wednesday
-- of January); this file writes the term. One office, one winner, and he is the sitting Governor.
--
-- This completes Maryland's legislative-plus-Governor programme: CC_0494 / CC_0495 / CC_0496
-- dated and seated the 178 General Assembly seats for 2027-01-13, and those three files refused
-- every state executive on purpose. **The Attorney General and the Comptroller stay refused**, so
-- `MD STATE_EXEC` remains in the register's queue at 2 offices after this.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE PIN — CAPTURED BY REHEARSING `CC_0499 + A PROBE` IN ONE ROLLED-BACK TRANSACTION
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   1 winner · 1 office · 1 re-election · 0 handovers · 1 predecessor
--   digest 3554f97db5b96d13c26b50f56f46a405 · term start 2027-01-20
--
-- ⚠ **A ONE-ROW SELECTION STILL GETS THE WHOLE GATE SET, AND THE REASON IS NOT SYMMETRY.** The
--   digest, the coverage count and the predecessor pre-image each answer a different question
--   that a count of 1 cannot: *which* office, held by *whom*, and *what this file overwrites*.
--   A file that only asserted "one row" would pass while seating the wrong person into the
--   wrong seat.
--
-- 🔴 **AND THE COVERAGE GATE IS HERE EVEN THOUGH THE NULL CANNOT OCCUR.** `is_reelection` is NULL
--   — not false — on a seat with no current holder, because `office_current_holder` is LEFT
--   JOINed; `'…' || NULL` is NULL and `string_agg` SKIPS it, so the digest can silently cover
--   fewer rows than every count claims. With one row that would empty the digest entirely. The
--   Governor's seat is held, so it cannot happen — and P3 counts the evaluated rows anyway,
--   because "it cannot happen here" expires the moment a seat falls vacant.
--
-- Ruling B: the row was **called**, not certified, when this was written. The term's `source`
-- carries `CC_0500` so a reversed canvass is recovered by slot rather than from memory.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THIS IS A RE-ELECTION, AND THE PREDECESSOR IS THE WINNER
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Wes Moore holds the office and won it.** `essentials.seat_officeholder` is called with
-- `p_allow_reelection => true`, which is what lets it close his own 2023-01-18 term at 2027-01-19
-- and open a new one at 2027-01-20 rather than refusing to seat a person into a seat they
-- already hold.
--
-- ⚠ **TWO ADJACENT DAYS ARE ONE HANDOVER.** `seat_officeholder` closes a predecessor at
--   `term_start - 1` throughout this programme. A reader who expects one continuous tenure will
--   find two rows; that is the model, not a gap in his service.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **One predecessor row: Wes Moore's own open Governor term, `term_start` 2023-01-18, `term_end`
-- NULL, `how_ended` NULL.** It becomes `term_end = 2027-01-19`, `how_ended = 'term_expired'`.
--
-- 🔴 **THAT 2023-01-18 IS THE ONLY CORROBORATION CC_0499's DATE HAS INSIDE OUR OWN DATA** — it
--   was backfilled by migration 1459 from `msa.maryland.gov` and never derived from Art. II § 1,
--   and the third Wednesday of January 2023 is the 18th. `seat_officeholder` writes nothing to a
--   closed row's `source`, so post-verify 6b asserts the start did not move: losing it would
--   destroy the evidence for the rule this wave is written on.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE LIEUTENANT GOVERNOR IS NOT SEATED, AND ITS TERM IS THIS SAME DAY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Art. II § 1B: *"a vote cast for the candidate for Governor shall also be cast for Lieutenant
-- Governor jointly listed on the ballot with him, and the election of Governor … also shall
-- constitute the election **for the same term** … of the Lieutenant Governor."* So the office was
-- on the 2026 ballot as a matter of law and its term begins on 2027-01-20.
--
-- **Measured 2026-11-24: the office row exists, is held by Aruna Miller, and carries no pending
-- winner and NO 2026 race row at all.** That is Utah's third class — "no race row", not an
-- unrecorded result — and it is the mirror of Arizona's missing Lieutenant Governor in CC_0497,
-- where the office itself does not exist. ▶ Nobody can be seated who was never recorded as
-- winning, so this file leaves Aruna Miller in place with no incoming holder, which is what a
-- voter will correctly see. P7 gates on the gap staying exactly as described. **The fix is the
-- result.**

BEGIN;

CREATE TEMP TABLE cc0500_pin ON COMMIT DROP AS
SELECT 1                                  AS expect_winners,
       1                                  AS expect_offices,
       1                                  AS expect_reelections,
       0                                  AS expect_new,
       1                                  AS expect_predecessors,
       3                                  AS expect_terms_on_the_day_before,
       '3554f97db5b96d13c26b50f56f46a405' AS expect_digest,
       DATE '2027-01-20'                  AS expect_term_start,
       DATE '2023-01-18'                  AS expect_predecessor_start;

CREATE TEMP TABLE cc0500_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       (win.value ->> 'id')::uuid                        AS politician_id,
       (win.value ->> 'name')                            AS winner_name,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id')) AS is_reelection,
       si.swearing_in_date                               AS term_start,
       si.basis                                          AS basis,
       och.politician_id                                 AS holder_before,
       w.certainty                                       AS certainty
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = o.id
                                                AND si.election_date = DATE '2026-11-03'
 WHERE lower(d.state) = 'md'
   AND d.district_type = 'STATE_EXEC'
   AND o.title = 'Governor'
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0500_pre ON COMMIT DROP AS
SELECT s.office_id, t.id AS term_id, t.politician_id, t.term_start, t.term_end, t.how_ended
  FROM cc0500_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0500_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-20')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0500_pre)                                           AS predecessors,
       (SELECT md5(string_agg(och.office_id::text || ':'
                              || COALESCE(och.politician_id::text, '-'),
                              '|' ORDER BY och.office_id::text))
          FROM essentials.office_current_holder och)                               AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged,
       (SELECT count(*) FROM essentials.offices_missing_terms)                     AS missing_all;

DO $$
DECLARE n bigint; d text; p record; b record;
BEGIN
  SELECT * INTO p FROM cc0500_pin;
  SELECT * INTO b FROM cc0500_before;

  -- P1 — ⚠ ASKED ABOVE EVERY COUNT. On a second run the seat has left office_pending_winner, so
  -- a count check fires first and blames the data for what is a repeat apply.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0500%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % office_terms row(s) already cite CC_0500. Applied before.', n;
  END IF;

  -- P2 — the shape of the wave.
  SELECT count(*) INTO n FROM cc0500_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P2: selection returned % winner rows, expected %. The Governor is a '
                    'single-seat, single-winner race; more than one means the data moved.',
      n, p.expect_winners;
  END IF;
  SELECT count(DISTINCT office_id) INTO n FROM cc0500_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P2: % distinct offices, expected %.', n, p.expect_offices;
  END IF;

  -- P3 — the pin. 🔴 THE COVERAGE COUNT FIRST: a NULL is_reelection renders the whole
  -- concatenation NULL and string_agg skips it, which with one row would empty the digest.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0500_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: the digest expression evaluated to NULL on % of % row(s), so string_agg '
                    'would have skipped them. is_reelection is NULL on a seat with no current '
                    'holder — the Maryland Governor''s seat was held when this file was written, '
                    'so it has fallen vacant. Read it before seating over it.',
      p.expect_winners - n, p.expect_winners;
  END IF;
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0500_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P3: selection digest is %, expected %. Every count above passed, so the '
                    'membership is the same size and something inside it changed — a different '
                    'office, a different winner, or a seat that changed hands before the '
                    'handover.', d, p.expect_digest;
  END IF;
  SELECT count(*) INTO n FROM cc0500_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P3: % re-elections, expected % — Wes Moore holds the office and won it, '
                    'which is what lets seat_officeholder be called with p_allow_reelection.',
      n, p.expect_reelections;
  END IF;
  SELECT count(*) INTO n FROM cc0500_sel WHERE winner_name = 'Wes Moore';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P3: the recorded winner is not Wes Moore. ⚠ A count of 1 passes whoever it '
                    'is; the name is checked because this file writes a claim about one named '
                    'person holding one named office.';
  END IF;

  -- P4 — the date, read from office_swearing_in and never typed here.
  SELECT count(*) INTO n FROM cc0500_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: the Governor has no swearing-in date, or one that is not %. CC_0499 '
                    'writes it; if this fires, that file has not run. ⚠ If the date reads '
                    '2027-01-13 somebody has given the Governor the GENERAL ASSEMBLY''s day '
                    'under Art. III § 6 — which is live on 178 rows and is this wave''s near '
                    'miss.', p.expect_term_start;
  END IF;
  SELECT count(*) INTO n FROM cc0500_sel
   WHERE basis IS DISTINCT FROM 'statute' AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: the date''s basis is neither statute nor published. An estimate may not '
                    'seat anybody.';
  END IF;

  -- P5 — the winner has a person row.
  SELECT count(*) INTO n FROM cc0500_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: the winner has no politician row to seat.';
  END IF;

  -- P6 — not flagged is_vacant, and the predecessor pre-image, which is what this file
  -- overwrites. 🔴 ITS term_start IS THE ONLY CORROBORATION CC_0499'S DATE HAS IN OUR OWN DATA.
  SELECT count(*) INTO n
    FROM cc0500_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: the Governor''s office is flagged is_vacant. A future-dated seating does '
                    'not clear a flag; that needs a companion file of the CC_0480 / CC_0486 kind.';
  END IF;
  SELECT count(*) INTO n FROM cc0500_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) captured, expected %. A seat with nobody in it is '
                    'a fact to read, not to seat over.', n, p.expect_predecessors;
  END IF;
  SELECT count(*) INTO n FROM cc0500_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: the predecessor term already carries a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing, so this file would '
                    'destroy a date it has not written down.';
  END IF;
  SELECT count(*) INTO n FROM cc0500_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: the predecessor term already carries a how_ended. seat_officeholder '
                    'COALESCEs that column, so an existing value survives.';
  END IF;
  SELECT count(*) INTO n FROM cc0500_pre WHERE term_start IS DISTINCT FROM p.expect_predecessor_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: the predecessor term does not start %. That row is Wes Moore''s own '
                    'term, backfilled by migration 1459 from msa.maryland.gov and never derived '
                    'from Art. II § 1 — and the third Wednesday of January 2023 IS the 18th. It '
                    'is the ONLY corroboration CC_0499''s date has inside our own data.',
      p.expect_predecessor_start;
  END IF;
  SELECT count(*) INTO n
    FROM cc0500_pre x JOIN cc0500_sel s ON s.office_id = x.office_id
   WHERE x.politician_id IS DISTINCT FROM s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: the predecessor is not the winner. This file was written for a '
                    'RE-ELECTION — Wes Moore closing his own term and opening the next — so a '
                    'different predecessor means a handover nobody has read.';
  END IF;

  -- P7 — 🔴🔴 THE LIEUTENANT GOVERNOR, WHOSE TERM IS THIS SAME DAY AND WHOSE ELECTION WE DO NOT
  -- HOLD. Art. II § 1B makes the Governor's election "the election for the same term" of the
  -- Lieutenant Governor, so the office was on the ballot as a matter of law. Gated here so a
  -- race arriving stops this wave rather than being absorbed into a one-office file.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND o.title = 'Lieutenant Governor'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: the Maryland Lieutenant Governor now carries a pending winner. Its term '
                    'begins on the SAME DAY as the Governor''s under Art. II § 1B, so this wave '
                    'is larger than one office and both files need re-reading.';
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och
    JOIN essentials.offices o   ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND o.title = 'Lieutenant Governor'
     AND och.politician_id IS NOT NULL;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P7: the Maryland Lieutenant Governor is not held by exactly one person '
                    '(% found). It was held by Aruna Miller when this file was written, and '
                    'this file deliberately leaves it alone — nobody can be seated who was '
                    'never recorded as winning.', n;
  END IF;

  -- P8 — the Attorney General and the Comptroller stay pending and undated.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_EXEC'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 3 THEN
    RAISE EXCEPTION 'P8: % Maryland state executive seats are pending, expected 3 (Governor, '
                    'Attorney General, Comptroller).', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_EXEC'
     AND s.election_date = DATE '2026-11-03'
     AND o.title IN ('Attorney General', 'Comptroller');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: % Maryland Attorney General / Comptroller row(s) now carry a date. Both '
                    'are REFUSED — no clause names a day for either, and Art. XVII § 4''s '
                    'residual rule commences their terms AT THE ELECTION, which overlaps the '
                    'predecessor and office_terms forbids. Each needs a published qualification '
                    'date; read the authority before seating on it.', n;
  END IF;

  -- P9 — 🔴 THE 2027-01-20 DELTA. Maryland is the SECOND state on this day: three Massachusetts
  -- constitutional officers were already seated here by CC_0485.
  IF b.terms_on_the_day <> p.expect_terms_on_the_day_before THEN
    RAISE EXCEPTION 'P9: % term(s) already begin on %, expected % (Massachusetts'' Attorney '
                    'General, Auditor of the Commonwealth and Treasurer and Receiver-General). '
                    'A third state has landed on Maryland''s day — name its rule before adding '
                    'to the pile.',
      b.terms_on_the_day, p.expect_term_start, p.expect_terms_on_the_day_before;
  END IF;

  -- P10 — Ruling B: the row was called, not certified, when this was written.
  SELECT count(*) INTO n FROM cc0500_sel WHERE certainty <> 'called';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P10: the Governor''s result is no longer "called". If Maryland has certified '
                    'since 2026-11-24, the term this file writes should say "certified" instead.';
  END IF;
END $$;

CREATE TEMP TABLE cc0500_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0500_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0500_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0500_guarded);

DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0500_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran. Term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in: "The executive power of the '
                         || 'State shall be vested in a Governor, whose term of office shall '
                         || 'commence on the third Wednesday of January next ensuing his '
                         || 'election" (Md. Const. Art. II, § 1). NOTE: § 1 is the TERM. Art. II '
                         || '§ 3 names the same day for the QUALIFICATION and then lets it slip '
                         || '— "or as soon thereafter as may be practicable" — and the GENERAL '
                         || 'ASSEMBLY''s own terms begin a week earlier, on the SECOND Wednesday '
                         || '(Art. III § 6, written by CC_0494 for 178 seats). Re-elected '
                         || 'incumbent: the predecessor on this seat is the winner, and his own '
                         || 'term of 2023-01-18 is closed at 2027-01-19. ⚠ The LIEUTENANT '
                         || 'GOVERNOR''s term begins on this same day under Art. II § 1B, which '
                         || 'makes the election of a Governor "the election for the same term" '
                         || 'of the Lieutenant Governor — and we hold no winner and no 2026 race '
                         || 'row for that office at all, so it is NOT seated here. CC_0500',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0500: seat_officeholder called for % office', v_seated;
END $$;

DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM cc0500_guarded;
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

DO $$
DECLARE n bigint; m text; b record; p record;
BEGIN
  SELECT * INTO b FROM cc0500_before;
  SELECT * INTO p FROM cc0500_pin;

  -- 1. the term exists, on the office this file selected, for the person it selected.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0500_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated term(s) on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. the read path answers.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0500_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seat(s).', n, p.expect_offices;
  END IF;

  -- 3. the day's delta, and every row on it belongs to a named state.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_offices THEN
    RAISE EXCEPTION '3: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_start = p.expect_term_start AND lower(d.state) NOT IN ('md', 'ma');
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % term(s) on % belong to a state other than Maryland or Massachusetts. '
                    'A date shared by several states is a coincidence of calendars, never a '
                    'shared rule.', n, p.expect_term_start;
  END IF;

  -- 4. nobody moved TODAY. A future-dated term must not change who holds a seat now.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today.', b.holders_md5, m;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0500_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: the Governor''s seat no longer answers office_current_holder with the '
                    'person holding it today.';
  END IF;

  -- 6. the predecessor closed on the day before the handover, and kept its start.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0500_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact row named in '
                    'cc0500_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0500_pre x ON x.term_id = t.id
   WHERE t.term_start IS NOT DISTINCT FROM x.term_start
     AND t.term_start = p.expect_predecessor_start;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6b: the closed predecessor term no longer starts %. That date is the ONLY '
                    'corroboration CC_0499''s rule has inside our own data — migration 1459, '
                    'backfilled from msa.maryland.gov and never derived from Art. II § 1 — and '
                    'this file dates nobody''s tenure.', p.expect_predecessor_start;
  END IF;

  -- 7. nothing closed between today and the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0500_sel s ON s.office_id = t.office_id
   WHERE t.term_end IS NOT NULL
     AND t.term_end >= CURRENT_DATE AND t.term_end < p.expect_term_start - 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % term(s) closed between today and the day before the handover.', n;
  END IF;

  -- 8. no person or office was created or destroyed. ⚠ The Lieutenant Governor is NOT created or
  --    seated here: the office already exists, it is held, and we hold no winner for it.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %. This wave has no people file.',
      b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %.', b.offices, n;
  END IF;

  -- 9. 🔴 NOBODY LANDED ON THE GENERAL ASSEMBLY'S DAY. 2027-01-13 is the SECOND Wednesday, is
  --    this file's near miss, and is live on 178 Maryland rows written by CC_0494.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0500_sel s ON s.office_id = t.office_id
   WHERE t.term_start IN (DATE '2027-01-13', DATE '2027-01-27');
  IF n <> 0 THEN
    RAISE EXCEPTION '9: the Governor''s term starts on one of the two wrong Wednesdays — '
                    '2027-01-13 (the SECOND, the whole General Assembly''s real day under Art. '
                    'III § 6) or 2027-01-27 (the fourth, which no Maryland clause names).';
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND t.term_start = DATE '2027-01-13';
  IF n <> 178 THEN
    RAISE EXCEPTION '9b: % Maryland General Assembly terms begin 2027-01-13, expected 178. This '
                    'file must not have moved CC_0496''s wave, and the two days must stay a week '
                    'apart.', n;
  END IF;

  -- 10. the other two executives were not seated and are still visibly pending; the Lieutenant
  --     Governor was not touched.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_EXEC'
     AND t.term_start = p.expect_term_start
     AND o.title <> 'Governor';
  IF n <> 0 THEN
    RAISE EXCEPTION '10: % Maryland executive seat(s) other than the Governor were seated on '
                    'this day. The Attorney General and the Comptroller are REFUSED; the '
                    'LIEUTENANT GOVERNOR''s term IS this same day under Art. II § 1B and we hold '
                    'no winner for it, so it must stay empty of an incoming holder.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_EXEC'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 2 THEN
    RAISE EXCEPTION '10b: % Maryland state executive seat(s) still answer office_pending_winner, '
                    'expected 2 — the Attorney General and the Comptroller, both refused and '
                    'both visible.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx
    JOIN essentials.offices o   ON o.id = nx.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND o.title = 'Lieutenant Governor';
  IF n <> 0 THEN
    RAISE EXCEPTION '10c: the Maryland Lieutenant Governor now has an incoming holder. Nobody '
                    'can be seated who was never recorded as winning — we hold no 2026 race row '
                    'for that office at all.';
  END IF;

  -- 11. no vacancy flag moved.
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '11: the repo-wide count of flagged-vacant offices moved % -> %.',
      b.vacant_all, n;
  END IF;

  -- 12. exactly one term was added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '12: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 13. Ruling B — the new term names the slot and says what it seated from.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0500_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start
     AND t.source LIKE '%CC_0500%' AND t.source LIKE '%called, not certified%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '13: the new term does not cite CC_0500 and record that the result was '
                    'called rather than certified.';
  END IF;

  -- 14. the seat has left office_pending_winner.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0500_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '14: the Governor''s seat still answers office_pending_winner.';
  END IF;

  -- 15. the drift baseline held, and the view did not move — the seat already had a term.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '15: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> b.missing_all THEN
    RAISE EXCEPTION '15: offices_missing_terms went % -> %, expected no change.',
      b.missing_all, n;
  END IF;

  RAISE NOTICE 'CC_0500 OK: the Maryland Governor scheduled for % — Wes Moore, a RE-ELECTION, so '
               'the predecessor on this seat is the winner and his own term of % is closed at '
               '%. That start date is the only corroboration Art. II § 1 has inside our own '
               'data and this file left it untouched. Nobody moved today, the seat is not '
               'flagged vacant, and nobody landed on 2027-01-13 — the SECOND Wednesday, which is '
               'the whole General Assembly''s real day and is still carrying its 178 terms a '
               'week earlier. Maryland is the SECOND state on this calendar day; Massachusetts'' '
               'three constitutional officers were already here. The ATTORNEY GENERAL and the '
               'COMPTROLLER were NOT seated and are still visibly pending — no clause names a '
               'day for either. ⚠ The LIEUTENANT GOVERNOR''s term begins on this same day under '
               'Art. II § 1B and it has NO incoming holder, because we hold no winner and no '
               '2026 race row for that office at all: the fix is the result. Drift baseline % '
               'held.',
    p.expect_term_start, p.expect_predecessor_start, p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
