-- CC_0479 — California: schedule the six statewide executives and Board of Equalization
-- District 3 for the term that begins 2027-01-04.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Cal. Const. art. II, § 20: "Terms of elective offices provided for by this Constitution, other
-- than Members of the Legislature, commence on the Monday after January 1 following election."
-- The Monday after January 1, 2027 is the **4th**. CC_0477 recorded that date against all seven
-- offices; this file reads it and writes the terms.
--
-- 🔴 "THE MONDAY AFTER JANUARY 1" IS NOT "THE FIRST MONDAY OF JANUARY" — the two diverge by a
--    week whenever January 1 is a Monday, and `chambers.inauguration_rules` carries the wrong
--    one, uncited, for three of these offices. They agree for 2027. CC_0477's assertion 3c is
--    where that distinction is tested; this file reads the date CC_0477 wrote and never
--    recomputes it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SELECTION IS PINNED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   winners 7 · offices 7 · re-elections 3 · new holders 4 · predecessors 7
--   digest md5 = c682c1223e41b93bab52755f232eb5d5   (captured 2026-11-23 against production)
--   called 7 · certified 0 on the day this was captured (Ruling B)
--
--     Attorney General                    Rob Bonta          re-elected
--     Controller                          Malia M. Cohen     re-elected
--     Secretary of State                  Shirley N. Weber   re-elected
--     Governor                            Xavier Becerra     succeeds Gavin Newsom
--     Lieutenant Governor                 Fiona Ma           succeeds Eleni Kounalakis
--     Treasurer                           Eleni Kounalakis   succeeds Fiona Ma
--     Board of Equalization District 3    Mike A. Gipson     succeeds Antonio Vazquez
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 TWO OF THESE SEVEN ARE A STRAIGHT SWAP, AND EACH OF THOSE TWO PEOPLE IS BOTH A WINNER
--     AND A PREDECESSOR IN THIS SAME FILE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Fiona Ma is Treasurer today and wins Lieutenant Governor. Eleni Kounalakis is Lieutenant
-- Governor today and wins Treasurer. On 2027-01-04 they exchange offices.
--
-- `seat_officeholder` is called once per office and looks its predecessor up BY OFFICE, so the
-- exchange needs no ordering: seating Ma into Lieutenant Governor closes Kounalakis' term on
-- that office, and seating Kounalakis into Treasurer closes Ma's term on that one. Neither call
-- can see the other. ▶ Assertion 6 measures the result from the people's side rather than the
-- offices' — each of the two must end with exactly one term closing 2027-01-03 and exactly one
-- opening 2027-01-04, on DIFFERENT offices — because an exchange is the shape that produces a
-- person holding two seats at once if anything goes wrong, and no per-office count can see that.
--
-- ⚠ The incumbency guard's scope is a UNION of winners and predecessors for exactly this reason.
--   Ma and Kounalakis would each be counted twice by a plain concatenation, and more
--   importantly, a scope taken from the winners alone would not watch the terms being CLOSED.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ MIKE GIPSON IS OUT OF OFFICE FOR TWENTY-EIGHT DAYS, AND THAT IS CORRECT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- He holds Assembly District 65 today. CC_0478 closes that term on 2026-12-06, because
-- art. IV, § 2(a)(3) ends the Assembly term on the first Monday in December. This file opens his
-- Board of Equalization term on 2027-01-04, because art. II, § 20 starts it on the Monday after
-- January 1. Two clauses, two days, one person. The gap between them is California's calendar
-- and not a defect in either file — ▶ do not "fix" it by moving either date.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ THE BOARD OF EQUALIZATION SEAT IS `STATE_BOARD` AND ITS `chamber_id` IS NULL
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴 AN INNER JOIN TO `essentials.chambers` SILENTLY DROPS IT, and California then reads as 98
--    offices instead of 99 — which is how it was first mis-measured. This file does not join
--    chambers anywhere, and P1 counts the STATE_BOARD row separately so its absence is an error
--    rather than a smaller number.
--
-- Only District 3 of the four Board of Equalization seats is up; districts 1, 2 and 4 are
-- mid-term and CC_0477 left them undated. Assertion 9 asserts none of them was seated.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes each predecessor with an UNGUARDED
-- `UPDATE office_terms SET term_end = p_term_start - 1` and writes nothing to that row's
-- `source`. So the 7 new terms are recoverable by slot and the 7 CLOSURES are not.
--
--   🔴 ALL 7 PREDECESSOR TERMS CARRY `term_end = NULL` AND `how_ended = NULL`. Measured against
--      production 2026-11-23, not inferred. The full pre-image is captured into `cc0479_pre`,
--      P7 refuses unless every `term_end` in it is NULL, and assertion 5 counts the rows closed.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ WHAT THIS WAVE DOES NOT COVER
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- • **The 92 legislative seats** begin 2026-12-07 under art. IV, § 2(a)(3); CC_0478 seats them.
--   Assertion 8 asserts none of them was given this date.
-- • **Twelve appointed California state offices** — Auditor, Director of Industrial Relations,
--   five Public Utilities Commissioners, Secretary for Natural Resources, Secretary of
--   Agriculture and a legacy "Board of Equalization Member" row. Art. II, § 20 reaches ELECTIVE
--   offices only. Assertion 10 asserts none was touched.
-- • **Superintendent of Public Instruction and Commissioner of Insurance** were on the 2026
--   ballot and have no recorded result, so they are outside `office_pending_winner`. 🔴 Neither
--   takes this date if it is added later: the Superintendent has its own clause (art. IX, § 2)
--   and the Insurance Commissioner is STATUTORY, so art. II, § 20 — "provided for by this
--   Constitution" — does not reach it at all. Assertion 10 covers both.

BEGIN;

CREATE TEMP TABLE cc0479_pin ON COMMIT DROP AS
SELECT 7                                  AS expect_winners,
       7                                  AS expect_offices,
       3                                  AS expect_reelections,
       4                                  AS expect_new,
       7                                  AS expect_predecessors,
       'c682c1223e41b93bab52755f232eb5d5' AS expect_digest,
       DATE '2027-01-04'                  AS expect_term_start;

-- 🔴 `scripts/lib/seating-wave.mjs`'s WAVE_SELECTION_SQL, with the same one addition CC_0478
--    makes: `och.politician_id IS NOT NULL` keeps `is_reelection` a real boolean. No seat in
--    THIS wave is empty, so it changes nothing here — it is carried so the two California files
--    read alike and so a later edit to either cannot reintroduce the NULL.
CREATE TEMP TABLE cc0479_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       (win.value ->> 'id')::uuid                        AS politician_id,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id'))
                                                         AS is_reelection,
       si.swearing_in_date                               AS term_start,
       si.basis                                          AS basis,
       o.title                                           AS title,
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
   AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0479_pre ON COMMIT DROP AS
SELECT s.office_id, s.title, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0479_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0479_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-04')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0479_pre)                                           AS predecessors,
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
  SELECT * INTO p FROM cc0479_pin;

  -- P2 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE THE ROW COUNTS.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0479%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0479. Applied before.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0479_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: selection returned % winner rows, expected %. The data moved under '
                    'this file.', n, p.expect_winners;
  END IF;

  SELECT count(DISTINCT office_id) INTO n FROM cc0479_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P1: % offices, expected %.', n, p.expect_offices;
  END IF;

  -- 🔴 SIX EXECUTIVES AND ONE BOARD SEAT, COUNTED SEPARATELY. The Board of Equalization row has
  --    chamber_id = NULL and is the one an inner join to chambers drops; counting it on its own
  --    turns that disappearance into an error instead of a smaller number.
  SELECT count(*) INTO n FROM cc0479_sel WHERE district_type = 'STATE_EXEC';
  IF n <> 6 THEN
    RAISE EXCEPTION 'P1: % STATE_EXEC seats, expected 6.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0479_sel WHERE district_type = 'STATE_BOARD';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P1: % STATE_BOARD seats, expected 1 (Board of Equalization District 3).', n;
  END IF;

  SELECT count(*) INTO n FROM cc0479_sel
   WHERE title NOT IN ('Governor', 'Lieutenant Governor', 'Attorney General', 'Controller',
                       'Secretary of State', 'Treasurer', 'Board of Equalization District 3');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % seat(s) in this wave are not one of the seven this file names.', n;
  END IF;

  -- 🔴 The digest must cover every row it claims to; string_agg drops NULL input silently.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0479_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: the digest expression evaluated to NULL on % of % rows.',
      p.expect_winners - n, p.expect_winners;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0479_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %. The data moved under this file.',
      d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0479_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected % (Bonta, Cohen, Weber).',
      n, p.expect_reelections;
  END IF;

  SELECT count(*) INTO n FROM cc0479_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P1: % new holders, expected %.', n, p.expect_new;
  END IF;

  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0479_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner. None of these seven is a '
                    'multi-member seat, so this is Ruling A arriving where it was not expected '
                    '— stop and read the race.', n;
  END IF;

  -- P4 — 🔴 THE DATE IS READ, NEVER CARRIED. CC_0477 writes it.
  SELECT count(*) INTO n FROM cc0479_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. CC_0477 '
                    'writes it. ⚠ If one reads 2026-12-07 a legislative row has reached this '
                    'selection.', n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0479_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published. An '
                    'estimate may not seat anybody.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0479_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat.', n;
  END IF;

  -- P6 — nothing here is flagged vacant. All seven are held today, and a future seating would
  -- leave the flag alone regardless. (California's two flagged seats are legislative; CC_0478
  -- names them and CC_0480 clears them.)
  SELECT count(*) INTO n
    FROM cc0479_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % of these seven seats are flagged is_vacant. All seven are held '
                    'today, so a flag here is a fact nobody has read.', n;
  END IF;

  -- P7 — the pre-image is complete and every predecessor is open.
  SELECT count(*) INTO n FROM cc0479_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) captured, expected % (one per seat).',
      n, p.expect_predecessors;
  END IF;

  SELECT count(*) INTO n FROM cc0479_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing, so this file would '
                    'destroy a date it has not written down.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0479_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a how_ended. seat_officeholder '
                    'COALESCEs that column, so an existing value survives.', n;
  END IF;

  -- P8 — 🔴🔴 THE EXCHANGE IS THE ONE THIS FILE WAS WRITTEN ABOUT, NAMED ON BOTH SIDES. If the
  -- Lieutenant Governor's winner is not the Treasurer's current holder and vice versa, the
  -- header's account of this wave is wrong and assertion 6 would be measuring a swap that is
  -- not there.
  SELECT count(*) INTO n
    FROM cc0479_sel lg
    JOIN cc0479_sel tr ON tr.title = 'Treasurer'
   WHERE lg.title = 'Lieutenant Governor'
     AND lg.politician_id = tr.holder_before
     AND tr.politician_id = lg.holder_before
     AND lg.politician_id <> tr.politician_id;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P8: the Lieutenant Governor and Treasurer rows are not the straight '
                    'exchange this file documents (Fiona Ma and Eleni Kounalakis). Read both '
                    'races before seating either.';
  END IF;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK A — the incumbency guard, from migrations/_templates/office_terms_incumbency_guard.sql
-- ═════════════════════════════════════════════════════════════════════════════════════════════
--
-- @incumbency-decision: gated — this closes each predecessor at 2027-01-03, well after the
-- election, so every outgoing term still covers 2026-11-03 and the predicate's answer must not
-- move for anybody. The scope is a UNION of the seven winners and the seven people whose terms
-- are closed: Fiona Ma and Eleni Kounalakis are on both sides, and a scope taken from the
-- winners alone would not watch the terms being closed at all.
CREATE TEMP TABLE cc0479_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0479_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0479_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0479_guarded);

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0479_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in, "terms of elective offices '
                         || 'provided for by this Constitution, other than Members of the '
                         || 'Legislature, commence on the Monday after January 1 following '
                         || 'election" (Cal. Const. art. II, § 20'
                         || CASE r.district_type
                              WHEN 'STATE_BOARD'
                                THEN ', the only clause that dates this seat — art. XIII, § 17 '
                                     || 'names no commencement'
                              ELSE ', with art. V, §§ 2 and 11'
                            END
                         || '). '
                         || CASE WHEN r.is_reelection THEN 'Re-elected incumbent. '
                                 ELSE 'New holder; predecessor closed at 2027-01-03. ' END
                         || 'CC_0479',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0479: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0479_guarded;
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
  SELECT * INTO b FROM cc0479_before;
  SELECT * INTO p FROM cc0479_pin;

  -- 1. 7 new terms, one per seat, on the day itself, naming the winner.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0479_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. office_next_term answers for all 7 — the view a voter's page reads for a dated handover.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0479_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_offices;
  END IF;

  -- 3. 🔴 NOBODY WAS UNSEATED TODAY, ANYWHERE IN THE COUNTRY, and all seven seats still answer
  --    with the person holding them now. Gavin Newsom is still Governor.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '3: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today.', b.holders_md5, m;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0479_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '3: % of % seats still answer office_current_holder with the person holding '
                    'them today.', n, p.expect_offices;
  END IF;

  -- 4. Repo-wide, exactly 7 more terms start on that day — no other state swept in. ⚠ 122
  --    already did, Wisconsin's 121 among them (CC_0462), which is why this is a delta.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_offices THEN
    RAISE EXCEPTION '4: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;

  -- 5. Each predecessor named in the pre-image is closed the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0479_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '5: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0479_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 6. 🔴🔴 THE EXCHANGE, MEASURED FROM THE PEOPLE'S SIDE. Fiona Ma and Eleni Kounalakis each
  --    end with exactly one term closing 2027-01-03 and exactly one opening 2027-01-04, and the
  --    two offices differ. A per-office count cannot see a person left holding two seats at
  --    once, and an exchange is the shape that produces one.
  SELECT count(*) INTO n
    FROM (SELECT g.politician_id,
                 count(*) FILTER (WHERE t.term_end = p.expect_term_start - 1)   AS closing,
                 count(*) FILTER (WHERE t.term_start = p.expect_term_start)     AS opening,
                 count(DISTINCT t.office_id) FILTER (
                   WHERE t.term_end = p.expect_term_start - 1
                      OR t.term_start = p.expect_term_start)                    AS offices_touched
            FROM cc0479_sel w
            JOIN cc0479_pre g ON g.politician_id = w.politician_id
            JOIN essentials.office_terms t ON t.politician_id = g.politician_id
           GROUP BY g.politician_id) q
   WHERE q.closing = 1 AND q.opening = 1 AND q.offices_touched = 2;
  IF n <> 2 THEN
    RAISE EXCEPTION '6: % of the 2 exchanging officials end with exactly one term closing %, '
                    'one opening % and two distinct offices. An exchange that lands wrong '
                    'leaves somebody holding two seats at once, which no per-office count can '
                    'see.', n, p.expect_term_start - 1, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms a
    JOIN essentials.office_terms c ON c.politician_id = a.politician_id AND c.id <> a.id
    JOIN cc0479_sel s ON s.office_id = a.office_id
   WHERE a.term_start = p.expect_term_start
     AND c.office_id <> a.office_id
     AND (c.term_end IS NULL OR c.term_end >= p.expect_term_start)
     AND (c.term_start IS NULL OR c.term_start <= p.expect_term_start);
  IF n <> 0 THEN
    RAISE EXCEPTION '6: % of the people seated here would hold a second office on % as well.',
      n, p.expect_term_start;
  END IF;

  -- 7. This file creates no people and no offices, and moves no vacancy flag.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '7: politicians moved from % to %.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '7: offices moved from % to %.', b.offices, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '7: the repo-wide count of flagged-vacant offices moved % -> %.',
      b.vacant_all, n;
  END IF;

  -- 8. 🔴 THE 92 LEGISLATIVE SEATS WERE NOT GIVEN THIS DATE. They begin 2026-12-07 under
  --    art. IV, § 2(a)(3); CC_0478 seats them.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ca' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % California legislative seat(s) were given the statewide January date.',
      n;
  END IF;

  -- 9. 🔴 BOARD OF EQUALIZATION DISTRICTS 1, 2 AND 4 WERE NOT SEATED — they are mid-term.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ca' AND d.district_type = 'STATE_BOARD'
     AND t.term_start = p.expect_term_start
     AND o.title <> 'Board of Equalization District 3';
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % mid-term Board of Equalization seat(s) were seated.', n;
  END IF;

  -- 10. 🔴 THE APPOINTED OFFICES, THE SUPERINTENDENT AND THE INSURANCE COMMISSIONER WERE NOT
  --     TOUCHED. Art. II, § 20 reaches elective offices only, the Superintendent has its own
  --     clause (art. IX, § 2) and the Insurance Commissioner is statutory — so § 20 does not
  --     reach it at all.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ca' AND t.term_start = p.expect_term_start
     AND o.title IN ('Auditor', 'Director of Industrial Relations',
                     'Public Utilities Commissioner', 'Secretary for Natural Resources',
                     'Secretary of Agriculture', 'Board of Equalization Member',
                     'Superintendent of Public Instruction', 'Commissioner of Insurance');
  IF n <> 0 THEN
    RAISE EXCEPTION '10: % appointed or unresolved California office(s) were seated.', n;
  END IF;

  -- 11. Repo-wide, exactly 7 office_terms rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '11: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 12. Every new term cites this migration (Ruling B: recoverable by slot).
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0479_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0479%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '12: % of % new terms cite CC_0479.', n, p.expect_offices;
  END IF;

  -- 13. 🔴 THE SEATS HAVE LEFT THE PENDING-WINNER VIEW.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0479_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '13: % seat(s) still answer office_pending_winner.', n;
  END IF;

  -- 14. The 238 unflagged drift baseline did not move. 🔴 NEVER RAISE IT.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '14: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  RAISE NOTICE 'CC_0479 OK: 6 California statewide executives and Board of Equalization '
               'District 3 scheduled for % (% re-elections, % handovers), % predecessors '
               'closed at %, the Ma/Kounalakis exchange lands on two distinct offices with no '
               'overlap, nobody moved today, the 92 legislative seats and the 12 appointed '
               'offices untouched, drift baseline % held.',
    p.expect_term_start, p.expect_reelections, p.expect_new, b.predecessors,
    p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
