-- CC_0488 — Washington House and Senate: schedule all 118 winners for the term that begins
-- 2027-01-11.
--
-- RCW 44.04.021: "The regular term of office of each senator and representative shall commence on
-- the second Monday in January following the date of election." The second Monday in January 2027
-- is the **11th**. CC_0487 recorded that date against all 118 offices; this file reads it and
-- writes the terms.
--
-- 🔴 **THE AUTHORITY IS A STATUTE, NOT THE CONSTITUTION, AND THE CONSTITUTION NAMES THE SAME DAY
--    FOR SOMEBODY ELSE.** Wash. Const. Art. III § 4 puts the STATE EXECUTIVES on the second
--    Monday in January; Art. II §§ 5–6 fix only the LENGTH of a legislative term and never its
--    start. So citing the constitution here would be right about the date and wrong about the
--    law. None of Washington's nine executives was on the 2026 ballot; assertion 10 refuses if
--    one has been given this date.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SELECTION IS PINNED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   winners 118 · offices 118 · re-elections 87 · new holders 31 · predecessors 118
--   digest md5 = 83c9bae9adba94f678c52cac878022c6   (captured 2026-11-23 against production,
--                                                    AFTER CC_0487)
--   called 118 · certified 0 on the day this was captured (Ruling B)
--
-- 🟢 **WASHINGTON HAS NO PEOPLE FILE, AND THAT IS WHY THIS PIN IS SIMPLE.** All 118 winners
--    already carry a `politicians` row and all 118 seats are held today, so the digest cannot
--    move the way Massachusetts' did. Measured, not assumed — see the next block.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE `is_reelection` NULL CANNOT OCCUR HERE, AND THE FIX AND ITS GATE ARE CARRIED ANYWAY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `scripts/lib/seating-wave.mjs` computes `is_reelection` as
--
--     ((win.value ->> 'id') IS NOT NULL AND och.politician_id::text = (win.value ->> 'id'))
--
-- On a seat with no current holder `och.politician_id` is NULL, so the comparison is NULL,
-- `true AND NULL` is NULL, `'…' || NULL` is NULL, and `string_agg` SKIPS it — the published
-- digest then covers fewer rows than every count in P1 reports. California found it (`CC_0478`);
-- Massachusetts showed it can appear only *after* a people file runs (`CC_0483`).
--
-- 🟢 **IN WASHINGTON IT CANNOT HAPPEN: ALL 147 LEGISLATIVE SEATS ARE HELD TODAY AND NO WINNER
--    LACKS A PERSON ROW.** Both digests were computed side by side against production on
--    2026-11-23 and are the same string over the same 118 rows:
--
--      as published (no IS NOT NULL)            md5 = 83c9bae9adba94f678c52cac878022c6  (118 rows)
--      with `AND och.politician_id IS NOT NULL` md5 = 83c9bae9adba94f678c52cac878022c6  (118 rows)
--
--    ▶ **THE FIX AND THE COVERAGE GATE ARE STILL IN THIS FILE.** A gate that is only added where
--      the defect is already known is a gate that will be missing the first time it matters, and
--      "it cannot happen here" is a measurement that expires the moment a seat falls vacant. P1
--      counts what actually entered the aggregate.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WASHINGTON'S EXISTING TERM ROWS ARE **TENURES**, NOT TERMS, AND THIS FILE CLOSES THEM
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- All 147 Washington legislative seats carry exactly one `office_terms` row and every one of them
-- is open. Their `term_start` is when that member first took the seat — 1999 for the longest —
-- not the start of the current biennium. So `seat_officeholder` closing a predecessor at
-- `term_start - 1` = **2027-01-10** writes an end onto a tenure that may span a quarter of a
-- century, and for the 87 re-elected members it closes their own tenure the day before their new
-- term opens.
--
-- ⚠ That is the same shape every state in this pass has produced and it is not this file's to
--   change. A tenure start is a different fact from a term start; the repo-wide backlog of
--   undated and tenure-dated rows is its own programme.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 EIGHT WINNERS ALREADY HOLD A DIFFERENT SEAT, AND TWO OF THE EIGHT KEEP THEIRS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Six move inside the legislature, and **every seat they vacate is itself in this wave**:
--
--     Alex Ybarra        House LD 13  → Senate LD 13
--     Chipalo Street     House LD 37  → Senate LD 37
--     Cindy Ryu          House LD 32  → Senate LD 32
--     Jeremie Dufault    House LD 15  → Senate LD 15
--     Sharlett Mena      House LD 29  → Senate LD 29
--     Nikki Torres       Senate LD 15 → Senate LD 8   ⚠ SENATE TO SENATE, not a chamber switch
--
-- ⚠ **Nikki Torres is a sitting senator winning a different Senate district**, and the seat she
--   leaves is the one Jeremie Dufault wins. Both ends of that chain are in this wave. A reader
--   who assumed "a mover is always a House member moving up" would mis-read this row.
--
-- The incumbency guard's scope is a UNION of the winners and the predecessors for exactly this
-- reason: each of the six is both, and the UNION is what keeps them counted once.
--
-- 🔴 **TWO WINNERS COME FROM CITY OFFICE AND THIS FILE DOES NOT TOUCH IT.**
--
--     Jessica Forsythe   Redmond Citywide (At-large) → House LD 48
--     Vanessa Kritzer    Redmond Citywide (At-large) → House LD 45
--
--   `seat_officeholder` closes the predecessor on the office being SEATED and nothing else, so
--   both Redmond council terms stay open. **That is correct and must not be "tidied".** Whether
--   either resigns from the council is a fact nobody in this pass has read, and ending a term we
--   have no evidence ended would be a claim about a real person. Assertion 11 asserts both
--   council terms are still open afterwards.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `seat_officeholder` closes each predecessor with an UNGUARDED
-- `UPDATE office_terms SET term_end = p_term_start - 1` and writes nothing to that row's
-- `source`. So the 118 new terms are recoverable by slot and the 118 CLOSURES are not.
--
--   🔴 ALL 118 PREDECESSOR TERMS CARRY `term_end = NULL` AND `how_ended = NULL`. Measured
--      against production 2026-11-23, not inferred. P7 refuses unless that holds, and assertion
--      6 counts the rows actually closed.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ WHAT THIS WAVE DOES NOT COVER
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- • **25 SENATE SEATS ARE MID-TERM** and have no 2026 race at all. The chamber is staggered.
--   🔴 **THIS IS NOT RULING A** — each pending Senate office carries exactly one winner; P3
--   refuses a second.
--
-- • **FOUR SEATS WERE ON THE BALLOT AND HAVE NO RECORDED WINNER** — House LD 12 (Pos. 1), LD 23
--   (Pos. 1), LD 25 (Pos. 2) and Senate LD 35. ⚠ **UNRECORDED, NOT UNDECIDED**: every candidate
--   row on all four still carries `result = 'advanced'`, the August top-two PRIMARY result. They
--   are outside `office_pending_winner` and outside this file; assertion 12 refuses if one was
--   seated.
--
-- • **NINE STATE EXECUTIVES**, none on the 2026 ballot. Assertion 10.
--
-- • **NO WASHINGTON STATE OFFICE IS FLAGGED `is_vacant`**, so this state needs no companion file
--   of the `CC_0480` / `CC_0486` kind. P6 and assertion 13 assert the zero rather than assuming
--   it — a flagged seat that appeared since this file was written is a fact to read, not to seat
--   over.

BEGIN;

CREATE TEMP TABLE cc0488_pin ON COMMIT DROP AS
SELECT 118                                AS expect_winners,
       118                                AS expect_offices,
       87                                 AS expect_reelections,
       31                                 AS expect_new,
       118                                AS expect_predecessors,
       '83c9bae9adba94f678c52cac878022c6' AS expect_digest,
       DATE '2027-01-11'                  AS expect_term_start;
-- All three counts coincide at 118 here: one winner per office, and every office held today.
-- 🔴 THEY ARE SEPARATE CLAIMS AND ARE CHECKED SEPARATELY — in Massachusetts the predecessor
--    count was 197 against 199 winners, and reading one number as the other is how that goes
--    unnoticed.

-- 🔴 `WAVE_SELECTION_SQL` with ONE addition: `och.politician_id IS NOT NULL` closes the NULL a
--    holderless seat otherwise puts into `is_reelection`. Washington has no holderless seat
--    today, so it changes nothing today — see the header for the measurement. It is here because
--    the gate below has to be able to tell.
CREATE TEMP TABLE cc0488_sel ON COMMIT DROP AS
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
 WHERE lower(d.state) = 'wa'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0488_pre ON COMMIT DROP AS
SELECT s.office_id, s.seat, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0488_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

-- The two Redmond council terms these winners keep. Named so assertion 11 can prove this file
-- left them alone, rather than nobody noticing it had not.
CREATE TEMP TABLE cc0488_kept ON COMMIT DROP AS
SELECT t.id AS term_id, p.full_name, d.label AS seat, t.term_end
  FROM essentials.office_terms t
  JOIN essentials.offices o    ON o.id = t.office_id
  JOIN essentials.districts d  ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = t.politician_id
 WHERE t.politician_id IN (SELECT politician_id FROM cc0488_sel)
   AND NOT EXISTS (SELECT 1 FROM cc0488_sel s WHERE s.office_id = t.office_id)
   AND t.term_end IS NULL;

CREATE TEMP TABLE cc0488_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-11')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0488_pre)                                           AS predecessors,
       (SELECT count(*) FROM cc0488_kept)                                          AS kept,
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
  SELECT * INTO p FROM cc0488_pin;

  -- P2 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE THE ROW COUNTS. On a
  -- second run the seats have left office_pending_winner, so P1 would return 0 and report that
  -- the data moved — which is true of the view and false of the world.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0488%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0488. Applied before.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0488_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: selection returned % winner rows, expected %. The data moved under '
                    'this file. ⚠ Washington has FOUR seats that were on the 2026 ballot with no '
                    'recorded winner (House LD 12 Pos. 1, LD 23 Pos. 1, LD 25 Pos. 2, Senate '
                    'LD 35); if one has been recorded since, this wave is larger and the pin '
                    'must be re-derived.', n, p.expect_winners;
  END IF;

  SELECT count(DISTINCT office_id) INTO n FROM cc0488_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P1: % offices, expected %.', n, p.expect_offices;
  END IF;

  -- 🔴 THE DIGEST MUST COVER EVERY ROW IT CLAIMS TO. string_agg drops NULL input silently, so a
  --    digest over 118 rows and one over 116 of them look alike. Washington has no holderless
  --    seat today and this gate is what would notice if one appeared.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0488_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: the digest expression evaluated to NULL on % of % rows, so string_agg '
                    'would have skipped them. is_reelection is NULL on a seat with no current '
                    'holder — when this file was written all 147 Washington legislative seats '
                    'were held, so one has fallen vacant. Read it before seating over it.',
      p.expect_winners - n, p.expect_winners;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0488_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %. Every count above passed, so the '
                    'membership is the same size and something inside it changed — a winner '
                    'swapped, or a seat changed hands before the handover.', d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0488_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected %.', n, p.expect_reelections;
  END IF;

  SELECT count(*) INTO n FROM cc0488_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P1: % new holders, expected %. (Counted with NOT, which a NULL would fail '
                    'as well — 87 + 31 = 118 only if every row is a real boolean.)',
      n, p.expect_new;
  END IF;

  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0488_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner. Washington has no multi-member '
                    'legislative district — its House runs two POSITIONS per district, which are '
                    'separate offices with separate races. A second winner on one office row is '
                    'Ruling A arriving where it was not expected; stop and read the race.', n;
  END IF;

  -- P4 — 🔴 THE DATE IS READ, NEVER CARRIED. CC_0487 writes it.
  SELECT count(*) INTO n FROM cc0488_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. CC_0487 '
                    'writes it.', n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0488_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published. An '
                    'estimate may not seat anybody.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0488_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat. Washington needed no people '
                    'file: all 118 winners already had one when this was written.', n;
  END IF;

  -- P6 — 🔴 NOT ONE WASHINGTON SEAT IN THIS WAVE IS FLAGGED is_vacant, ASSERTED RATHER THAN
  -- ASSUMED. If one has been flagged since, this state needs the companion file California and
  -- Massachusetts needed and does not have one.
  SELECT count(*) INTO n
    FROM cc0488_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) in this wave are flagged is_vacant, expected 0. A future-'
                    'dated seating does not clear a flag, so this state would need a companion '
                    'file of the CC_0480 / CC_0486 kind and it has none.', n;
  END IF;

  -- P7 — 🔴 THE PRE-IMAGE IS ONE OPEN TERM PER SEAT, AND NOTHING IS BEING OVERWRITTEN BLIND.
  SELECT count(*) INTO n FROM cc0488_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) captured, expected % (one per seat — every '
                    'Washington legislative seat was held when this file was written).',
      n, p.expect_predecessors;
  END IF;

  SELECT count(*) INTO n FROM cc0488_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing, so this file would '
                    'destroy a date it has not written down.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0488_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a how_ended. seat_officeholder '
                    'COALESCEs that column, so an existing value survives.', n;
  END IF;

  SELECT count(*) INTO n
    FROM cc0488_sel s
   WHERE NOT EXISTS (SELECT 1 FROM cc0488_pre x WHERE x.office_id = s.office_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % seat(s) have no predecessor term. A seat with nobody in it is a fact '
                    'to read, not to seat over.', n;
  END IF;

  -- P8 — 🔴 THE TWO REDMOND COUNCIL TERMS THIS FILE MUST LEAVE ALONE ARE THERE TO BE LEFT
  -- ALONE. Jessica Forsythe and Vanessa Kritzer each hold a Redmond Citywide (At-large) seat and
  -- win a House seat. If this count is not 2, the shape assertion 11 checks afterwards has
  -- changed and that assertion would pass vacuously.
  SELECT count(*) INTO n FROM cc0488_kept;
  IF n <> 2 THEN
    RAISE EXCEPTION 'P8: % open term(s) held by a winner on an office OUTSIDE this wave, '
                    'expected exactly 2 (Jessica Forsythe and Vanessa Kritzer on Redmond '
                    'Citywide (At-large)). Read the extra one before seating.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0488_kept
   WHERE full_name NOT IN ('Jessica Forsythe', 'Vanessa Kritzer');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: % of the kept outside terms belong to somebody other than the two this '
                    'file was written about.', n;
  END IF;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK A — the incumbency guard, from migrations/_templates/office_terms_incumbency_guard.sql
-- ═════════════════════════════════════════════════════════════════════════════════════════════
--
-- @incumbency-decision: gated — this closes each predecessor at 2027-01-10, well after the
-- election, so every outgoing term still covers 2026-11-03 and the predicate's answer must not
-- move for anybody. The scope covers both sides: the 118 winners and the people whose terms are
-- closed.
--
-- 🔴 WASHINGTON MAKES THAT SCOPE DO REAL WORK. Six people are each BOTH a winner here and a
--    predecessor here — five House members moving to the Senate, and Nikki Torres moving from
--    Senate LD 15 to Senate LD 8. The UNION is what keeps each of them counted once.
CREATE TEMP TABLE cc0488_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0488_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0488_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0488_guarded);

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0488_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran; term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in, "the regular term of office of '
                         || 'each senator and representative shall commence on the second Monday '
                         || 'in January following the date of election" (RCW 44.04.021). NOTE: '
                         || 'the authority is a STATUTE. Wash. Const. Art. II §§ 5-6 fix only '
                         || 'the length of a legislative term; Art. III § 4 names this same day '
                         || 'for the STATE EXECUTIVES, so citing the constitution here would be '
                         || 'right about the date and wrong about the law. '
                         || CASE WHEN r.is_reelection THEN 'Re-elected incumbent. '
                                 ELSE 'New holder; predecessor closed at 2027-01-10. ' END
                         || 'CC_0488',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0488: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0488_guarded;
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
  SELECT * INTO b FROM cc0488_before;
  SELECT * INTO p FROM cc0488_pin;

  -- 1. 118 new terms, one per selected office, on the day itself, naming the winner.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0488_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. office_next_term answers for all 118 — the view a voter's page reads for a dated handover.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0488_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_offices;
  END IF;

  -- 3. Repo-wide, exactly 118 more terms start on that day — no other state swept in. ⚠ A DELTA,
  --    not a total: Idaho's Ada County is scheduled to re-seat on this same 2027-01-11.
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

  -- 5. 🔴 AND ALL 118 SEATS STILL ANSWER WITH TODAY'S HOLDER. ⚠ IS NOT DISTINCT FROM rather than
  --    `=` so a NULL on either side would be counted rather than silently dropped — Washington
  --    has no vacant seat today, and this is the form that would still be right if it did.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0488_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of % seats still answer office_current_holder with the person holding '
                    'them today.', n, p.expect_offices;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0488_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % of the 118 seats answer office_current_holder with nobody, expected 0 '
                    '— every Washington legislative seat is held today.', n;
  END IF;

  -- 6. Each predecessor named in the pre-image is closed the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0488_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0488_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 7. No term of these seats was closed between today and the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0488_sel s ON s.office_id = t.office_id
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

  -- 9. Not one seat carries the FIRST Monday in January 2027 instead of the second. The two are
  --    one `+ 7` apart and both are real Mondays in the right month.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0488_sel s ON s.office_id = t.office_id
   WHERE t.term_start = DATE '2027-01-04';
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % seat(s) start on 2027-01-04, the FIRST Monday in January — the rule '
                    'RCW 44.04.021 does not state.', n;
  END IF;

  -- 10. 🔴🔴 NO WASHINGTON STATE EXECUTIVE WAS SEATED ON THIS DAY. Wash. Const. Art. III § 4
  --     gives them the same date from a different provision, and none was on the 2026 ballot.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'wa' AND d.district_type = 'STATE_EXEC'
     AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '10: % Washington state executive(s) were seated on the legislature''s date. '
                    'They share the day (Art. III § 4) and not the authority, and none was on '
                    'the 2026 ballot.', n;
  END IF;

  -- 11. 🔴 THE TWO REDMOND COUNCIL TERMS ARE STILL OPEN. Jessica Forsythe and Vanessa Kritzer
  --     each win a House seat while holding a city council seat that is not in this wave.
  --     Closing one would assert a resignation nobody in this pass has read.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0488_kept k ON k.term_id = t.id
   WHERE t.term_end IS NULL;
  IF n <> b.kept THEN
    RAISE EXCEPTION '11: % of % Redmond council term(s) held by a winner are still open. This '
                    'file closes the predecessor on the seat it seats and nothing else; ending '
                    'a council term would claim a resignation this pass has not read.',
      n, b.kept;
  END IF;

  -- 12. 🔴 THE FOUR SEATS WITH NO RECORDED WINNER WERE NOT SEATED. They carry a 2026 race whose
  --     candidates all still read 'advanced' — the August primary result, not November's.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'wa' AND t.term_start = p.expect_term_start
     AND (d.label, o.title) IN (
       ('Legislative (House) District 12',  'State Representative (Position 1)'),
       ('Legislative (House) District 23',  'State Representative (Position 1)'),
       ('Legislative (House) District 25',  'State Representative (Position 2)'),
       ('Legislative (Senate) District 35', 'State Senator'));
  IF n <> 0 THEN
    RAISE EXCEPTION '12: % seat(s) with no recorded 2026 winner were seated.', n;
  END IF;

  -- 13. 🔴 NO WASHINGTON OFFICE IS FLAGGED is_vacant AND THE REPO-WIDE COUNT DID NOT MOVE.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'wa' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION '13: % Washington legislative office(s) are flagged is_vacant, expected 0.',
      n;
  END IF;

  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '13: the repo-wide count of flagged-vacant offices moved % -> %.',
      b.vacant_all, n;
  END IF;

  -- 14. Repo-wide, exactly 118 office_terms rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '14: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 15. Every new term cites this migration (Ruling B: recoverable by slot).
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0488_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0488%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '15: % of % new terms cite CC_0488.', n, p.expect_offices;
  END IF;

  -- 16. 🔴 THE SEATS HAVE LEFT THE PENDING-WINNER VIEW.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0488_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '16: % seat(s) still answer office_pending_winner.', n;
  END IF;

  -- 17. 🔴 THE DRIFT BASELINE DID NOT MOVE, AND NEITHER DID THE WHOLE VIEW. Every one of the 118
  --     seats already had a term row, so unlike Massachusetts this file takes nothing OUT of
  --     offices_missing_terms. Both halves are asserted, because "the baseline held" and "the
  --     view did not move" are different claims. 🔴 NEVER RAISE THE BASELINE.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '17: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> b.missing_all THEN
    RAISE EXCEPTION '17: offices_missing_terms went % -> %, expected no change — all 118 seats '
                    'already carried a term row.', b.missing_all, n;
  END IF;

  RAISE NOTICE 'CC_0488 OK: 118 Washington legislators scheduled for % (% re-elections, % '
               'handovers), % predecessors closed at %, nobody moved today, no seat flagged '
               'vacant before or after, the 9 state executives untouched on a day their own '
               'constitution also names, the 4 seats with an unrecorded 2026 result left alone, '
               'both Redmond council terms still open, drift baseline % held.',
    p.expect_term_start, p.expect_reelections, p.expect_new, b.predecessors,
    p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
