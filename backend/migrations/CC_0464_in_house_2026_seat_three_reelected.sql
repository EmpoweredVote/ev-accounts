-- CC_0464 — Indiana House districts 46, 60 and 61: seat the three re-elected members whose term
-- began 2026-11-04.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHY THESE THREE WERE LEFT BEHIND
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 24 Indiana House offices already carry a term starting 2026-11-04, written by CA_0374 and
-- CA_0396. All 24 are HANDOVERS. These three are not:
--
--   District 46   Bob Heaton
--   District 60   Peggy Mayfield
--   District 61   Matt Pierce
--
-- Each winner is the sitting member, and `essentials.seat_officeholder` REFUSES by default when
-- the person it is seating already holds the seat. That refusal is the guard against a wrong
-- winner or a wrong date, and the earlier passes did not switch it off — so the three fell out
-- and have sat with a recorded winner and no term for their new term ever since.
--
-- 🔴 `p_allow_reelection` IS STILL COMPUTED PER ROW, NOT HARD-CODED TRUE. All three happen to be
--    re-elections, so all three values are true — but the flag comes from the selection, and
--    P1's digest covers it. If one of these ceased to be a re-election between writing and
--    applying, the digest changes and this file refuses rather than quietly switching the guard
--    off for a handover.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE ONE WAVE IN THIS PASS WHOSE TERM HAS ALREADY STARTED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Ind. Const. art. 4 § 3 begins the term "from the day next after their general election", so
-- 2026-11-04 — seventeen days ago. Every other wave schedules somebody for a future morning;
-- this one writes a term that is already running, and `office_current_holder` recomputes from it
-- the moment this commits.
--
-- ⚠ AND YET ASSERTION 4 STILL PINS THE NATIONWIDE CURRENT-HOLDER MAP UNCHANGED, which is not
--   what you would expect of a past-dated seating. It holds because all three are re-elections:
--   the predecessor term closing at 2026-11-03 and the new term opening at 2026-11-04 name THE
--   SAME PERSON, so the map answers identically before and after. A past-dated seating of a
--   HANDOVER would move it, and this assertion would have to be rewritten for that wave. It is
--   kept here precisely because it still has something to catch: if any of the three turned out
--   not to be the sitting member, the map would move and this file would stop.
--
-- ⚠ NOTHING IS UNFLAGGED HERE. `seat_officeholder` does not touch `is_vacant`, and for a FUTURE
--   seating the flag must be left alone because the seat really is empty until that morning. A
--   term that has already begun is the one case where clearing it would be right — and P6 below
--   asserts there is nothing to clear, so this file does not need to.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SELECTION IS PINNED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   rows 3 · re-elections 3 · new holders 0
--   digest md5 = 4678bef1a5bc464b64cd6cbd933249fa   (captured 2026-11-21 against production)
--   called 3 · certified 0 on the day this was captured
--
-- The date is read from `essentials.office_swearing_in`, written by CC_0463 from Ind. Const.
-- art. 4 § 3. P4 refuses unless all three agree on 2026-11-04 with a basis of statute or
-- published. A literal date here would agree with itself however wrong it was.

BEGIN;

CREATE TEMP TABLE cc0464_pin ON COMMIT DROP AS
SELECT 3                                  AS expect_rows,
       3                                  AS expect_reelections,
       0                                  AS expect_new,
       '4678bef1a5bc464b64cd6cbd933249fa' AS expect_digest,
       DATE '2026-11-04'                  AS expect_term_start;

-- 🔴 THIS SELECTION IS `scripts/lib/seating-wave.mjs`'s WAVE_SELECTION_SQL, column for column.
CREATE TEMP TABLE cc0464_sel ON COMMIT DROP AS
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
 WHERE lower(d.state) = 'in'
   AND d.district_type = 'STATE_LOWER'
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0464_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2026-11-04')
                                                                                   AS terms_on_the_day,
       -- Indiana House only. 24 such terms already exist (CA_0374, CA_0396), so assertion 3
       -- must read a DELTA against this transaction's own pre-image rather than a literal.
       (SELECT count(*)
          FROM essentials.office_terms t
          JOIN essentials.offices o   ON o.id = t.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'in' AND d.district_type = 'STATE_LOWER'
           AND t.term_start = DATE '2026-11-04')                                   AS terms_on_the_day_in,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-'),
                              '|' ORDER BY office_id::text))
          FROM essentials.office_current_holder)                                   AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged,
       (SELECT count(*) FROM cc0464_sel s
         WHERE EXISTS (SELECT 1 FROM essentials.office_terms t
                        WHERE t.office_id = s.office_id
                          AND (t.term_start IS NULL OR t.term_start <= s.term_start)
                          AND (t.term_end   IS NULL OR t.term_end   >= s.term_start)))
                                                                                   AS predecessors;

DO $$
DECLARE n bigint; d text; p record;
BEGIN
  SELECT * INTO p FROM cc0464_pin;

  SELECT count(*) INTO n FROM cc0464_sel;
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION 'P1: selection returned % rows, expected %. The data moved under this file.',
      n, p.expect_rows;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0464_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %.', d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0464_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected %. One of these is no longer the sitting '
                    'member, which changes what this file is doing.', n, p.expect_reelections;
  END IF;

  -- P2 — this file has not already been applied. (CC_0453's version is dead code against a
  -- selection drawn from office_pending_winner; see CC_0461's header for the control.)
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0464%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0464. Applied before.', n;
  END IF;

  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0464_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0464_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %.',
      n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0464_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0464_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat.', n;
  END IF;

  -- P6 — nothing here is flagged vacant, so this file has no flag to clear. A past-dated seating
  -- is the one case where clearing would be correct, and asserting there is nothing to clear is
  -- cheaper than clearing nothing and hoping.
  SELECT count(*) INTO n
    FROM cc0464_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) are flagged is_vacant. A term that has already begun means '
                    'the flag is wrong; decide each one before seating it.', n;
  END IF;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK A — the incumbency guard, from migrations/_templates/office_terms_incumbency_guard.sql
-- ═════════════════════════════════════════════════════════════════════════════════════════════
--
-- @incumbency-decision: gated — this closes each predecessor term at 2026-11-03, which IS the
-- election day, so the gate is asked properly rather than argued away.
--
-- ⚠ THE SCOPE COVERS BOTH SIDES OF THE SEATING, which here is one set of people: the predecessor
-- `seat_officeholder` closes and the member it opens a term for are THE SAME PERSON on all three
-- rows, because all three are re-elections. On a handover wave this plan table would need the
-- outgoing member too.
--
-- ⚠ `term_end` IS INCLUSIVE, so a predecessor closed at 2026-11-03 still COVERS 2026-11-03 and
-- each member still held the seat on the day they were elected. That is the reasoning; the gate
-- is what measures it.
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
   AND rc.politician_id IN (SELECT politician_id FROM cc0464_sel);

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0464_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in, "from the day next after their '
                         || 'general election" (Ind. Const. art. 4 §3). Re-elected incumbent. '
                         || 'CC_0464',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0464: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0464_sel;
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
  SELECT * INTO b FROM cc0464_before;
  SELECT * INTO p FROM cc0464_pin;

  -- 1. Three new terms, one per selected office, on the day itself.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0464_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start, p.expect_rows;
  END IF;

  -- 2. 🔴 NOT office_next_term — THIS TERM HAS ALREADY STARTED. The view is
  --    `term_start > CURRENT_DATE`, so a wave whose date is in the past must NOT appear in it,
  --    and the seats must answer office_current_holder instead. Both halves are asserted,
  --    because checking only the second would pass for a seat that is also wrongly scheduled.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0464_sel s ON s.office_id = nx.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '2: % of these seats appear in office_next_term, but their term began % — '
                    'a term that has started is not a pending one.', n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0464_sel s ON s.office_id = och.office_id
   WHERE och.politician_id = s.politician_id;
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION '2: office_current_holder answers with the seated member for % of % seats.',
      n, p.expect_rows;
  END IF;

  -- 3. Indiana House seats starting that day went up by exactly 3 — read as a delta against this
  --    transaction's own pre-image, not against the 24 that were already there.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'in' AND d.district_type = 'STATE_LOWER'
     AND t.term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day_in + p.expect_rows THEN
    RAISE EXCEPTION '3: Indiana House terms starting % went % -> %, expected a delta of %.',
      p.expect_term_start, b.terms_on_the_day_in, n, p.expect_rows;
  END IF;

  -- 4. 🔴 NOBODY CHANGED SEATS, ANYWHERE. Unusual for a past-dated seating and it holds only
  --    because all three are re-elections: the term that closes and the term that opens name the
  --    same person, so the map answers identically. If one of them were not the sitting member
  --    this would fire, which is why it is kept rather than relaxed.
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-'),
                        '|' ORDER BY office_id::text))
    INTO m FROM essentials.office_current_holder;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). All three of these are '
                    're-elections, so seating them must not move a single seat.',
                    b.holders_md5, m;
  END IF;

  -- 5. Each predecessor term is closed at 2026-11-03 — the election day itself, which it still
  --    covers, because term_end is inclusive.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0464_sel s ON s.office_id = t.office_id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '5: % predecessor term(s) closed at %, expected %.',
      n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 6. This file creates no people and no offices.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '6: politicians moved from % to %.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '6: offices moved from % to %.', b.offices, n;
  END IF;

  -- 7. Repo-wide, exactly three office_terms rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_rows THEN
    RAISE EXCEPTION '7: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_rows;
  END IF;

  -- 8. Every new term cites this migration.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0464_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0464%';
  IF n <> p.expect_rows THEN
    RAISE EXCEPTION '8: % of % new terms cite CC_0464.', n, p.expect_rows;
  END IF;

  -- 9. 🔴 THE SEATS HAVE LEFT THE PENDING-WINNER VIEW, so the card stops reading as a declared
  --    result. For these three that line was also FALSE in a second way: the display would have
  --    called them "declared re-elected, date of the new term not yet confirmed" when the date
  --    was confirmed, was in our own database for 24 of their colleagues, and was seventeen days
  --    ago. CC_0460 suppressed the line; this makes it true.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0464_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % seat(s) still answer office_pending_winner.', n;
  END IF;

  -- 10. The 238 unflagged drift baseline did not move.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '10: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  RAISE NOTICE 'CC_0464 OK: 3 Indiana House members seated from % (all re-elections), % '
               'predecessors closed at %, nobody changed seats, drift baseline % held.',
    p.expect_term_start, b.predecessors, p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
