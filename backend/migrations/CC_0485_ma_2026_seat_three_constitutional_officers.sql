-- CC_0485 — Massachusetts: schedule the Attorney General, the Treasurer and Receiver-General
-- and the Auditor of the Commonwealth for the term that begins 2027-01-20.
--
-- Mass. Const. Amend. Art. LXIV § 1, as appearing in Amend. Art. LXXXII: "The terms of the
-- secretary, treasurer and receiver-general, attorney general, and auditor shall begin with THE
-- THIRD WEDNESDAY IN JANUARY succeeding their election." Wednesdays in January 2027 are the 6th,
-- 13th and 20th, so the third is **2027-01-20**. CC_0481 recorded that date against all three
-- offices; this file reads it and writes the terms.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THIS IS THE LAST AND MOST ISOLATED OF MASSACHUSETTS' THREE DATES — FOURTEEN DAYS AFTER
--     THE LEGISLATURE AND THIRTEEN AFTER THE GOVERNOR
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-06  House and Senate (199)                       CC_0483
--   2027-01-07  Governor and Lieutenant Governor (2), noon   CC_0484
--   2027-01-20  these three                                  this file
--
-- One sentence-group, three days. **A file that copied the legislature's date onto these three
-- would put the Attorney General in office two weeks early.** That is the whole hazard of this
-- state, and P4 plus assertions 7 and 8 are where it is refused.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SELECTION IS PINNED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   winners 3 · offices 3 · re-elections 3 · new holders 0 · predecessors 3
--   digest md5 = ef9afb5c1a20039c3b3cd7c461ec8ce4   (captured 2026-11-23 against production,
--                                                    after CC_0481 and CC_0482)
--   called 3 · certified 0 on the day this was captured (Ruling B)
--
--     Attorney General                  Andrea Joy Campbell    re-elected
--     Treasurer and Receiver-General    Deborah B. Goldberg    re-elected
--     Auditor of the Commonwealth       Diana DiZoglio         re-elected
--
-- ⚠ **THE BALLOT NAME AND THE PERSON RECORD DISAGREE ON ONE OF THE THREE AND IT IS NOT A
--   PROBLEM.** `race_candidates` carries the Treasurer as "Deb Goldberg"; the politician row
--   reads "Deborah B. Goldberg". The row is already linked by id — the selection matches on
--   `politician_id`, never on the name — so the display difference changes nothing here. ▶ It is
--   recorded because the opposite case, a name that matches and a person that does not, is the
--   one this pass keeps paying for.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ THIS DATE HAS THE WEAKEST CORROBORATION OF THE THREE, AND THAT IS SAID PLAINLY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴 **OUR OWN DATA CANNOT CHECK IT.** Not one of these three offices carries a `term_start` at
--    all — all three predecessor rows have `start_precision = 'unknown'` — and no Massachusetts
--    legislative term is dated either. The Governor is the only Massachusetts office with a
--    recorded start, and it belongs to the OTHER executive group.
--
-- What the date rests on:
--
--   1. 🟢 **The clause's own words**, evaluated as written in SQL from the same anchor the other
--      two dates use. P8 computes the first Wednesday in January 2027 and takes it plus 14, and
--      checks the anchor itself against the 2022 cycle, where the House Journal and Healey's
--      recorded term both pin it. **So the ANCHOR is well controlled even though this OFFSET is
--      not.**
--   2. ⚠ **A news dateline, not a document.** Andrea Campbell was sworn as Attorney General, and
--      William Galvin and Deborah Goldberg for their own offices, on 2023-01-18 — the third
--      Wednesday of that January — widely datelined (Boston Globe, WGBH, Boston.com, all
--      2023-01-18). It is corroboration that the clause is applied as written. **It is not a
--      document and it is recorded as the weaker thing it is.**
--
-- ▶ If this date is ever found wrong, the rows are recoverable by slot: every term this file
--   writes cites `CC_0485`.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ THE SECRETARY OF THE COMMONWEALTH BELONGS TO THIS GROUP IN LAW AND IS NOT IN THIS FILE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The clause names four officers — "the secretary, treasurer and receiver-general, attorney
-- general, and auditor" — and this file seats three. William Francis Galvin holds the fourth and
-- **no 2026 winner is recorded against it**, so it is outside `office_pending_winner`: a results
-- gap, not a dating one.
--
-- 🔴 **UNLIKE CALIFORNIA'S INSURANCE COMMISSIONER, THIS OFFICE WOULD TAKE THIS FILE'S DATE.**
--    California's was statutory, so its constitution's general clause did not reach it at all.
--    Massachusetts' constitution names the secretary explicitly. ▶ When the result is recorded,
--    2027-01-20 is its date and CC_0481's row covers it. Assertion 8 asserts this file did not
--    seat it anyway.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- All three are re-elections, so each one's current term is closed at **2027-01-19** and a new
-- one opened the next day. `seat_officeholder` does that with an UNGUARDED
-- `UPDATE office_terms SET term_end = p_term_start - 1` and records nothing in that row.
--
--   🔴 ALL THREE PREDECESSOR TERMS CARRY `term_start = NULL`, `term_end = NULL` AND
--      `how_ended = NULL`. Measured against production 2026-11-23, not inferred. So this file
--      writes an END onto a row with no beginning, three times. That is correct and is not this
--      file's to fix — a tenure start is a different fact from a term start, and Massachusetts'
--      executives are among the undated tenures.

BEGIN;

CREATE TEMP TABLE cc0485_pin ON COMMIT DROP AS
SELECT 3                                  AS expect_winners,
       3                                  AS expect_offices,
       3                                  AS expect_reelections,
       0                                  AS expect_new,
       3                                  AS expect_predecessors,
       'ef9afb5c1a20039c3b3cd7c461ec8ce4' AS expect_digest,
       DATE '2027-01-20'                  AS expect_term_start;

CREATE TEMP TABLE cc0485_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       (win.value ->> 'id')::uuid                        AS politician_id,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id'))
                                                         AS is_reelection,
       si.swearing_in_date                               AS term_start,
       si.basis                                          AS basis,
       o.title                                           AS title,
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
   AND d.district_type = 'STATE_EXEC'
   AND o.title IN ('Attorney General', 'Treasurer and Receiver-General',
                   'Auditor of the Commonwealth')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0485_pre ON COMMIT DROP AS
SELECT s.office_id, s.title, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0485_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0485_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-20')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0485_pre)                                           AS predecessors,
       (SELECT md5(string_agg(och.office_id::text || ':'
                              || COALESCE(och.politician_id::text, '-'),
                              '|' ORDER BY och.office_id::text))
          FROM essentials.office_current_holder och)                               AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged;

DO $$
DECLARE n bigint; d text; p record; fw date;
BEGIN
  SELECT * INTO p FROM cc0485_pin;

  -- P2 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE THE ROW COUNTS.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0485%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0485. Applied before.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0485_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: selection returned % winner rows, expected %. The data moved under '
                    'this file.', n, p.expect_winners;
  END IF;

  SELECT count(DISTINCT office_id) INTO n FROM cc0485_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P1: % offices, expected %.', n, p.expect_offices;
  END IF;

  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0485_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: the digest expression evaluated to NULL on % of % rows.',
      p.expect_winners - n, p.expect_winners;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0485_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %. The data moved under this file.',
      d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0485_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected % (Campbell, Goldberg and DiZoglio are all '
                    'returning). If this is lower, somebody is being unseated and this file''s '
                    'header is wrong about the wave.', n, p.expect_reelections;
  END IF;

  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0485_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner. None of these three is a '
                    'multi-member seat.', n;
  END IF;

  -- P4 — 🔴🔴 THE DATE IS READ, NEVER CARRIED, AND THIS IS THE GROUP A COPIED LITERAL WOULD PUT
  --    TWO WEEKS EARLY.
  SELECT count(*) INTO n FROM cc0485_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. CC_0481 '
                    'writes it. ⚠ If one reads 2027-01-06 this file has picked up the '
                    'legislature''s date — fourteen days early — and if 2027-01-07, the '
                    'governor''s.', n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0485_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0485_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat.', n;
  END IF;

  -- P6 — none of the three is flagged vacant. All three are held today.
  SELECT count(*) INTO n
    FROM cc0485_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % of these three seats are flagged is_vacant. All three are held today.',
      n;
  END IF;

  -- P7 — the pre-image is complete and every predecessor is open.
  SELECT count(*) INTO n FROM cc0485_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) captured, expected % (one per seat).',
      n, p.expect_predecessors;
  END IF;

  SELECT count(*) INTO n FROM cc0485_pre WHERE term_end IS NOT NULL OR how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a term_end or a how_ended.', n;
  END IF;

  -- ⚠ P7b — ALL THREE PREDECESSORS HAVE NO term_start, asserted so the header's account of what
  --    this file writes an END onto stays true. If one has acquired a start, read it: somebody
  --    has dated a Massachusetts executive tenure since this file was written.
  SELECT count(*) INTO n FROM cc0485_pre WHERE term_start IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) now carry a term_start. When this file was '
                    'written none of the three did.', n;
  END IF;

  -- P8 — 🟢 THE ANCHOR EVALUATED AS WRITTEN, AND CHECKED FOR A CYCLE THIS FILE DOES NOT WRITE.
  --    The offset (+14) has no corroboration in our own data; the ANCHOR does, through the
  --    Governor's recorded 2023-01-05, which is that anchor plus one.
  SELECT DATE '2027-01-01' + ((10 - EXTRACT(ISODOW FROM DATE '2027-01-01'))::int % 7) INTO fw;
  IF fw + 14 <> p.expect_term_start THEN
    RAISE EXCEPTION 'P8: the third Wednesday in January 2027 computes as %, not %.',
      fw + 14, p.expect_term_start;
  END IF;
  IF fw + 7 = p.expect_term_start THEN
    RAISE EXCEPTION 'P8: the formula produced the SECOND Wednesday. "Third" is the anchor plus '
                    '14, not plus 7.';
  END IF;

  SELECT DATE '2023-01-01' + ((10 - EXTRACT(ISODOW FROM DATE '2023-01-01'))::int % 7) INTO fw;
  IF fw <> DATE '2023-01-04' OR fw + 14 <> DATE '2023-01-18' THEN
    RAISE EXCEPTION 'P8: for the 2022 cycle the anchor computes as % and the third Wednesday as '
                    '%, expected 2023-01-04 and 2023-01-18 — the day the House Journal says the '
                    '193rd General Court convened, and the day Campbell, Galvin and Goldberg '
                    'were sworn.', fw, fw + 14;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ma' AND o.title = 'Governor' AND t.term_start = fw + 1;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P8: the Massachusetts Governor carries % term(s) starting %, expected 1. '
                    'That row is the only check our own data can make on the anchor all three '
                    'of this state''s dates are built from.', n, fw + 1;
  END IF;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK A — the incumbency guard, from migrations/_templates/office_terms_incumbency_guard.sql
-- ═════════════════════════════════════════════════════════════════════════════════════════════
--
-- @incumbency-decision: gated — this closes each predecessor at 2027-01-19, well after the
-- election, so all three outgoing terms still cover 2026-11-03 and the predicate's answer must
-- not move. All three people are on both sides of this wave; the UNION keeps each counted once.
CREATE TEMP TABLE cc0485_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0485_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0485_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0485_guarded);

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0485_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in, "the terms of the secretary, '
                         || 'treasurer and receiver-general, attorney general, and auditor shall '
                         || 'begin with the third Wednesday in January succeeding their '
                         || 'election" (Mass. Const. Amend. Art. LXIV § 1, as appearing in '
                         || 'Amend. Art. LXXXII). NOTE: this is FOURTEEN DAYS after the '
                         || 'legislature (2027-01-06) and THIRTEEN after the Governor '
                         || '(2027-01-07) — one sentence-group, three days. ⚠ This date has the '
                         || 'weakest corroboration of the three: no Massachusetts office in this '
                         || 'group carries a recorded term_start, so it rests on the clause plus '
                         || 'the 2023-01-18 swearing-in datelines for Campbell, Galvin and '
                         || 'Goldberg, which are news reports and not a document. The anchor it '
                         || 'is computed from IS controlled, through the Governor''s recorded '
                         || '2023-01-05. Re-elected incumbent; the previous term is closed at '
                         || '2027-01-19. CC_0485',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0485: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0485_guarded;
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
  SELECT * INTO b FROM cc0485_before;
  SELECT * INTO p FROM cc0485_pin;

  -- 1. Three new terms, on the day itself, naming the winners.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0485_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. office_next_term answers for all three.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0485_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_offices;
  END IF;

  -- 3. 🔴 NOBODY WAS UNSEATED TODAY, ANYWHERE, and all three still answer with their holder.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '3: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today.', b.holders_md5, m;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0485_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '3: % of % seats still answer office_current_holder with today''s holder.',
      n, p.expect_offices;
  END IF;

  -- 4. Each predecessor named in the pre-image is closed the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0485_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '4: % predecessor term(s) closed at %, expected %.',
      n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 5. 🔴 EACH OFFICIAL NOW HOLDS EXACTLY ONE OPEN TERM ON THEIR OWN OFFICE. A re-election
  --    closes a term and opens another on the SAME seat; that is the shape that leaves somebody
  --    with two overlapping terms if the close did not land.
  SELECT count(*) INTO n
    FROM cc0485_sel s
   WHERE (SELECT count(*) FROM essentials.office_terms t
           WHERE t.office_id = s.office_id AND t.politician_id = s.politician_id
             AND t.term_end IS NULL) <> 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % of the three officials do not hold exactly one open term on their own '
                    'office.', n;
  END IF;

  -- 6. Repo-wide, exactly 3 more terms start that day and exactly 3 rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_offices THEN
    RAISE EXCEPTION '6: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;

  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '6: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 7. 🔴🔴 NEITHER THE LEGISLATURE NOR THE GOVERNOR WAS GIVEN THIS DATE. 199 seats begin
  --    2027-01-06 and two begin 2027-01-07; this file is fourteen and thirteen days after them.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ma' AND t.term_start = p.expect_term_start
     AND (d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
          OR o.title IN ('Governor', 'Lieutenant Governor'));
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % Massachusetts legislative or gubernatorial seat(s) were given the '
                    'third-Wednesday date.', n;
  END IF;

  -- 8. 🔴 THE SECRETARY OF THE COMMONWEALTH WAS NOT SEATED. The clause names it and this file
  --    does not reach it: no 2026 winner is recorded for that office. When one is, 2027-01-20 is
  --    its date — the row CC_0481 wrote is only for the three with results.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ma' AND o.title = 'Secretary of the Commonwealth'
     AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '8: the Secretary of the Commonwealth was seated, and no 2026 result is '
                    'recorded for that office.';
  END IF;

  -- 9. ⚠ AND IT STILL ANSWERS WITH WILLIAM FRANCIS GALVIN. "We did not seat it" and "it reads
  --    correctly" are different claims.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och
    JOIN essentials.offices o   ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ma' AND o.title = 'Secretary of the Commonwealth'
     AND och.politician_id IS NOT NULL;
  IF n <> 1 THEN
    RAISE EXCEPTION '9: the Secretary of the Commonwealth does not answer with a holder.';
  END IF;

  -- 10. This file creates no people and no offices, and moves no vacancy flag.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '10: politicians moved from % to %.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '10: offices moved from % to %.', b.offices, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '10: the repo-wide count of flagged-vacant offices moved % -> %.',
      b.vacant_all, n;
  END IF;

  -- 11. All three new terms cite this migration (Ruling B: recoverable by slot). ⚠ This matters
  --     more here than anywhere else in Massachusetts: it is the date with the weakest
  --     corroboration, so it is the one most likely to need undoing.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0485_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0485%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '11: % of % new terms cite CC_0485.', n, p.expect_offices;
  END IF;

  -- 12. The seats have left the pending-winner view.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0485_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '12: % seat(s) still answer office_pending_winner.', n;
  END IF;

  -- 13. The 238 unflagged drift baseline did not move. 🔴 NEVER RAISE IT.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '13: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  RAISE NOTICE 'CC_0485 OK: Massachusetts'' Attorney General, Treasurer and Receiver-General and '
               'Auditor scheduled for % (all three re-elections; their current terms close %), '
               'fourteen days after the legislature and thirteen after the Governor. The anchor '
               'was controlled against Healey''s recorded 2023-01-05; the +14 offset rests on '
               'the clause and a news dateline, which is written into every row. The Secretary '
               'of the Commonwealth was not seated and still answers with its holder. Drift '
               'baseline % held.',
    p.expect_term_start, p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
