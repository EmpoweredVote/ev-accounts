-- CC_0502 — Alabama: seat the 13 winners of 2026-11-03 for 2027-01-18.
--
-- Second of two. CC_0501 writes the dates — one day from three provisions, Ala. Const. 2022
-- § 116, Code of Ala. § 37-1-3(c)(1) and § 16-3-1 — and this file writes the terms. **There is
-- no people file**: all 13 winner rows already carry a politician_id, every one of those rows is
-- active, and none collides on either (full_name) or (first_name, last_name). Arizona was the
-- first state in this pass to need none; Alabama is the second.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE PIN — CAPTURED BY REHEARSING `CC_0501 + A PROBE` IN ONE ROLLED-BACK TRANSACTION
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   13 winners · 13 offices · 4 re-elections · 9 handovers · 13 predecessors
--   digest 51c8f15718bd72841a93f281e11b1a21 · term start 2027-01-18
--
-- 🟢 **WINNERS = OFFICES HERE, BECAUSE EVERY RACE IS SINGLE-SEAT.** They are equal only while
--   every office has one winner, which CC_0501's P3 measured rather than assumed. So **no Ruling
--   A**: each winner is seated into the office that carried their own race, and the selection
--   needs no sibling expansion. (Maryland's CC_0496 wrote 178 terms against 114 races and
--   Arizona's CC_0498 93 against 65.)
--
-- 🟢 **AND THE DIGEST COVERS ALL 13 ROWS.** `is_reelection` is NULL — not false — on a seat with
--   no current holder, because `office_current_holder` is LEFT JOINed; `'…' || NULL` is NULL and
--   `string_agg` SKIPS it, so the digest can silently cover fewer rows than every count claims.
--   All 13 Alabama seats are held, so it cannot happen here — and P3 counts the evaluated rows
--   anyway, because "it cannot happen here" expires the moment a seat falls vacant. 🟢 It is also
--   why `derive-seating-wave.mjs` and this file agree on the digest: with no NULL there is
--   nothing for the JS and the SQL to render differently.
--
-- Ruling B: **all 13 rows were `called`, not certified**, when this was written. Every term's
-- `source` carries `CC_0502`, so a reversed canvass is recovered with `source LIKE '%CC_0502%'`
-- rather than from memory.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE WAVE — 4 RE-ELECTIONS AND 9 HANDOVERS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   RE-ELECTED (p_allow_reelection => true, each closing their own open term at 2027-01-17)
--     Auditor                                 Andrew Sorrell
--     Treasurer                               Young Boozer
--     State Board of Education, District 2     Tracie West
--     State Board of Education, District 4     Yvette Richardson
--
--   HANDOVERS
--     Governor                                 Kay Ivey            -> Tommy Tuberville
--     Lieutenant Governor                      Will Ainsworth      -> John Wahl
--     Attorney General                         Steve Marshall      -> Katherine Robertson
--     Secretary of State                       Wes Allen           -> Caroleene Dobson
--     Commissioner of Agriculture and Industries  Rick Pate        -> Corey Hill
--     Public Service Commissioner, Place 1     Jeremy H. Oden      -> Matt Gentry
--     Public Service Commissioner, Place 2     Chris V. Beeker III -> Jim Zeigler
--     State Board of Education, District 6     Marie Manning       -> Cathi Bradford
--     State Board of Education, District 8     Wayne Reynolds      -> Emily Jones
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 A SITTING U.S. SENATOR BECOMES GOVERNOR, AND THAT IS WHAT MAKES THE "TWO SEATS" ZERO REAL
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Tommy Tuberville holds Alabama's U.S. Senate seat and won the Governorship.** This is the
-- shape that has cost this programme twice — Maryland's Nicholaus Kipke and Utah's Doug Fiefia,
-- each left holding two seats because a result was missing — and here it is correct and already
-- settled:
--
--   Senator (NATIONAL_UPPER)   2021-01-03 -> **2027-01-02**, `how_ended = 'term_expired'`
--   Governor (STATE_EXEC)      **2027-01-18** -> open, written by this file
--
-- 🟢 **HIS SENATE TERM WAS ALREADY CLOSED BY THE FEDERAL PROGRAMME, SIXTEEN DAYS BEFORE THIS
--   FILE'S DAY.** So on 2027-01-18 he holds exactly one seat, and the fifteen days between
--   2027-01-03 and 2027-01-17 in which he holds none are correct: he leaves the Senate when the
--   20th Amendment says he does and becomes Governor when § 116 says he does. ⚠ **A GAP BETWEEN
--   TWO OFFICES IS NOT A DEFECT** — California's Mike Gipson has a 28-day one for the same
--   reason.
--
-- 🔴 **AND THIS IS WHY P8's ZERO IS NOT VACUOUS.** "Nobody ends up holding two seats" is a zero,
--   and a zero needs a positive control. P9 finds Tuberville by MEASUREMENT — the one person in
--   this wave who holds an office outside it — names the two dates, and asserts his Senate term
--   closes strictly before the handover. If the federal programme had not closed it, P8 would see
--   a man holding a Senate seat and a Governorship on the same day, which is the Kipke shape.
--   (Arizona's CC_0498 did this with six chamber switchers; Alabama has exactly one, and it
--   crosses from the federal tier rather than between two state chambers.)
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Thirteen predecessor rows, one per seat, every one with `term_end` NULL and `how_ended`
-- NULL.** Each becomes `term_end = 2027-01-17`, `how_ended = 'term_expired'`.
--
-- 🔴 `seat_officeholder` does `UPDATE office_terms SET term_end = p_term_start - 1` on the
--   predecessor **with no `term_end IS NULL` guard** and writes nothing to that row's `source`.
--   So the new terms are recoverable by slot and **the closures are not** — undoing a declined
--   winner means restoring a `term_end` no file recorded. The thirteen rows are captured in
--   `cc0502_pre` and P6 asserts every one is open before anything is written.
--
-- ⚠ **TWELVE OF THE THIRTEEN PREDECESSOR TERMS CARRY `term_start IS NULL`** (`start_precision =
--   'unknown'`), which is normal for the ADR 0002 phase-2 backfill. The one exception is **Kay
--   Ivey's Governor term, `term_start` 2017-04-10**.
--
-- 🔴 **THAT DATE IS NOT CORROBORATION FOR § 116 AND MUST NOT BE READ AS ANY.** It is her
--   ACCESSION on Governor Bentley's resignation — a mid-term succession, not a cycle start — so
--   unlike Maryland (where CC_0500's predecessor row was the only in-data evidence for Art. II
--   § 1, and the third Wednesday of January 2023 is indeed the 18th), Alabama's single dated term
--   says nothing about the rule at all. Assertion 6b asserts it did not move anyway, because
--   `seat_officeholder` writes nothing to a closed row's `source` and a lost accession date is
--   unrecoverable.
--
-- ⚠ **AND IT IS WHY THIS STATE HAS NO IN-DATA DATE CONTROL.** 17 of Alabama's 18 state terms have
--   no `term_start`, so CC_0501 could not run its rule over a past cycle the way Arizona (80
--   terms across three cycles) and Washington (seven biennia) did. CC_0501's control is the
--   Legislature's own arithmetic instead — § 37-1-3(b)(2) writes "initial terms beginning
--   January 18, 2027" in words — plus the 2019 cycle, where the rule and its "third Monday"
--   look-alike come apart. **An unavailable check is a finding, and it is recorded in both
--   files.**
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHAT IS NOT SEATED, AND WHY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   **The Alabama legislature — 140 seats that do not exist as office rows.** Ala. Const. § 46(a)
--   elects every senator and representative "in the year nineteen hundred and six, and in every
--   fourth year thereafter" (1906 + 30x4 = 2026) and commences their terms "on the day after the
--   general election" — **2026-11-04, already past**. We hold ZERO STATE_UPPER and ZERO
--   STATE_LOWER Alabama office rows, so nothing errors and no count sees them. It is a SEEDING
--   job and it must not borrow this file's day: 2026-11-04 already carries 92 terms elsewhere
--   (Nevada's 52 under Nev. Const. art. 4 §§ 3, 4 among them), so a legislature dated to
--   2027-01-18 would be absorbed into this wave's day rather than standing out. P10 refuses to
--   run if such an office has appeared.
--
--   **State Board of Education Districts 1, 3, 5 and 7** carry no 2026 race row at all, which is
--   consistent with a four-year staggered board. ⚠ § 16-3-1 delegates the staggering to the
--   board itself ("as designated by the board") and names no district, and we hold no Alabama
--   race before 2026, so neither the law nor our data can prove the 4-of-8 split. It is pinned as
--   a measurement in both files and argued in neither.
--
--   **The Public Service Commission President**, whose next election is November 2028 under
--   § 37-1-3(a)(2), and the **four commissioners the Governor appoints** under § 37-1-3(b)(2)
--   "to serve initial terms beginning January 18, 2027" — this file's own day. The appointees are
--   not election winners, so no 2026 wave reaches them; on 2027-01-18 the commission will have
--   seven members and we will model three. P11 pins that.

BEGIN;

CREATE TEMP TABLE cc0502_pin ON COMMIT DROP AS
SELECT 13                                 AS expect_winners,
       13                                 AS expect_offices,
       4                                  AS expect_reelections,
       9                                  AS expect_new,
       13                                 AS expect_predecessors,
       1                                  AS expect_predecessors_dated,
       0                                  AS expect_terms_on_the_day_before,
       '51c8f15718bd72841a93f281e11b1a21' AS expect_digest,
       DATE '2027-01-18'                  AS expect_term_start,
       DATE '2017-04-10'                  AS expect_ivey_accession,
       DATE '2027-01-02'                  AS expect_tuberville_senate_end;

-- 🟢 NO SIBLING EXPANSION: every race here is single-seat, so a winner is keyed on the office
--    that carried their own race. CC_0501's P3 measured that; this file's P2 measures it again,
--    because a selection built this way is silently wrong for a multi-seat body.
CREATE TEMP TABLE cc0502_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       o.title                                           AS title,
       (win.value ->> 'id')::uuid                        AS politician_id,
       (win.value ->> 'name')                            AS winner_name,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id')) AS is_reelection,
       si.swearing_in_date                               AS term_start,
       si.basis                                          AS basis,
       och.politician_id                                 AS holder_before,
       w.certainty                                       AS certainty,
       w.winner_count                                    AS winner_count,
       d.district_type                                   AS district_type
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = o.id
                                                AND si.election_date = DATE '2026-11-03'
 WHERE lower(d.state) = 'al'
   AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD_EDUCATION')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0502_pre ON COMMIT DROP AS
SELECT s.office_id, t.id AS term_id, t.politician_id, t.term_start, t.term_end, t.how_ended
  FROM cc0502_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0502_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-18')
                                                                                   AS terms_on_the_day,
       -- 🔴 The two near-miss Mondays, as TERMS this time. Both are crowded: reaching one or two
       -- Mondays short of Alabama's answer lands on another body's real term start.
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-04')
                                                                                   AS terms_jan4,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-11')
                                                                                   AS terms_jan11,
       -- ⚠ And the day § 46(a) gives the legislature we do not hold, which is ALSO already live.
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2026-11-04')
                                                                                   AS terms_nov4,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0502_pre)                                           AS predecessors,
       (SELECT md5(string_agg(och.office_id::text || ':'
                              || COALESCE(och.politician_id::text, '-'),
                              '|' ORDER BY och.office_id::text))
          FROM essentials.office_current_holder och)                               AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged,
       (SELECT count(*) FROM essentials.offices_missing_terms)                     AS missing_all;

DO $$
DECLARE n bigint; d text; p record; b record; v_sen_end date; v_sen_start date;
BEGIN
  SELECT * INTO p FROM cc0502_pin;
  SELECT * INTO b FROM cc0502_before;

  -- P1 — ⚠ ASKED ABOVE EVERY COUNT. On a second run the seats have left office_pending_winner,
  -- so a count check fires first and blames the data for what is a repeat apply.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0502%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % office_terms row(s) already cite CC_0502. Applied before.', n;
  END IF;

  -- P2 — the shape of the wave, including the single-seat property this selection depends on.
  SELECT count(*) INTO n FROM cc0502_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P2: selection returned % winner rows, expected %.', n, p.expect_winners;
  END IF;
  SELECT count(DISTINCT office_id) INTO n FROM cc0502_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P2: % distinct offices, expected %.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n FROM cc0502_sel WHERE winner_count <> 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the 13 races carry more than one winner. 🔴 THIS SELECTION KEYS '
                    'EVERY WINNER ON THE RACE-CARRYING OFFICE, which is only correct while every '
                    'race is single-seat. Under Ruling A the extra winners belong in SIBLING '
                    'offices, post-verify 1 would not find their terms, and this file would '
                    'abort AFTER writing — see REGISTER.md and CC_0496 / CC_0498.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0502_sel WHERE district_type = 'STATE_EXEC';
  IF n <> 9 THEN
    RAISE EXCEPTION 'P2: % state executive seats in the wave, expected 9 (the seven § 116 '
                    'officers plus Public Service Commissioner Places 1 and 2).', n;
  END IF;
  SELECT count(*) INTO n FROM cc0502_sel WHERE district_type = 'STATE_BOARD_EDUCATION';
  IF n <> 4 THEN
    RAISE EXCEPTION 'P2: % State Board of Education seats in the wave, expected 4.', n;
  END IF;

  -- P3 — the pin. 🔴 THE COVERAGE COUNT FIRST: a NULL is_reelection renders the whole
  -- concatenation NULL and string_agg skips it, so the digest can cover fewer rows than the
  -- counts claim — and it is the holderless seats it drops.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0502_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: the digest expression evaluated to NULL on % of % row(s), so string_agg '
                    'would have skipped them and the digest below would cover fewer rows than '
                    'every count above claims. is_reelection is NULL on a seat with no current '
                    'holder — all 13 Alabama seats were held when this file was written, so one '
                    'has fallen vacant. Read it before seating over it.',
      p.expect_winners - n, p.expect_winners;
  END IF;
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0502_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P3: selection digest is %, expected %. Every count above passed, so the '
                    'membership is the same size and something inside it changed — a different '
                    'office, a different winner, or a seat that changed hands before the '
                    'handover.', d, p.expect_digest;
  END IF;
  SELECT count(*) INTO n FROM cc0502_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P3: % re-elections, expected % (Andrew Sorrell as Auditor, Young Boozer as '
                    'Treasurer, Tracie West in board District 2 and Yvette Richardson in '
                    'District 4). Each is seated with p_allow_reelection, which is what lets '
                    'seat_officeholder close their own open term rather than refusing.',
      n, p.expect_reelections;
  END IF;
  SELECT count(*) INTO n FROM cc0502_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P3: % handovers, expected %.', n, p.expect_new;
  END IF;
  -- ⚠ AND THE NAMES, because a count is true of whoever is in the selection. This file writes a
  -- claim about thirteen named people holding thirteen named offices.
  SELECT count(*) INTO n
    FROM cc0502_sel
   WHERE (title = 'Governor'                                   AND winner_name = 'Tommy Tuberville')
      OR (title = 'Lieutenant Governor'                        AND winner_name = 'John Wahl')
      OR (title = 'Attorney General'                           AND winner_name = 'Katherine Robertson')
      OR (title = 'Auditor'                                    AND winner_name = 'Andrew Sorrell')
      OR (title = 'Secretary of State'                         AND winner_name = 'Caroleene Dobson')
      OR (title = 'Treasurer'                                  AND winner_name = 'Young Boozer')
      OR (title = 'Commissioner of Agriculture and Industries' AND winner_name = 'Corey Hill')
      OR (title = 'Public Service Commissioner, Place 1'       AND winner_name = 'Matt Gentry')
      OR (title = 'Public Service Commissioner, Place 2'       AND winner_name = 'Jim Zeigler')
      OR (title = 'State Board of Education Member, District 2' AND winner_name = 'Tracie West')
      OR (title = 'State Board of Education Member, District 4' AND winner_name = 'Yvette Richardson')
      OR (title = 'State Board of Education Member, District 6' AND winner_name = 'Cathi Bradford')
      OR (title = 'State Board of Education Member, District 8' AND winner_name = 'Emily Jones');
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: only % of the 13 (office, winner) pairs match the names this file was '
                    'written for. The digest moved or a name changed; read the selection before '
                    'seating it.', n;
  END IF;

  -- P4 — the date, READ from office_swearing_in and never typed here. 🔴 A literal agrees with
  -- itself however wrong it is.
  SELECT count(*) INTO n FROM cc0502_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 13 seats have no swearing-in date, or one that is not %. '
                    'CC_0501 writes it; if this fires, that file has not run. ⚠ If the date '
                    'reads 2027-01-04 or 2027-01-11 somebody has given Alabama the FIRST or '
                    'SECOND Monday — 222 and 193 live terms respectively, in five other states — '
                    'instead of the first Monday AFTER THE SECOND TUESDAY.',
      n, p.expect_term_start;
  END IF;
  SELECT count(*) INTO n FROM cc0502_sel
   WHERE basis IS DISTINCT FROM 'statute' AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % date(s) have a basis that is neither statute nor published. An '
                    'estimate may not seat anybody — a term start is a legal fact.', n;
  END IF;

  -- P5 — every winner has a person row. 🟢 There is no people file, so this gate is the whole of
  -- the check rather than a restatement of one.
  SELECT count(*) INTO n FROM cc0502_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat. Nobody can be seated who '
                    'does not exist, and this wave was written on the measurement that all 13 '
                    'already existed.', n;
  END IF;

  -- P6 — not flagged is_vacant, and the predecessor pre-image, which is what this file
  -- overwrites. seat_officeholder closes a predecessor with NO term_end IS NULL guard and
  -- records nothing in that row's source.
  SELECT count(*) INTO n
    FROM cc0502_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % of the 13 offices are flagged is_vacant. A FUTURE-dated seating does '
                    'not clear a flag; that needs a companion file of the CC_0480 / CC_0486 kind, '
                    'applied on the handover day with a data interlock. Clearing it early makes '
                    'the district read DEAD_GEOGRAPHY in a master-only gate.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0502_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) captured, expected % — one per seat. A seat with '
                    'nobody in it is a fact to read, not to seat over, and the count would be '
                    'SMALLER than the seat count if one were empty.', n, p.expect_predecessors;
  END IF;
  SELECT count(*) INTO n FROM cc0502_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing, so this file would '
                    'destroy a date no file has written down.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0502_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a how_ended. seat_officeholder '
                    'COALESCEs that column, so an existing value survives.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0502_pre WHERE term_start IS NOT NULL;
  IF n <> p.expect_predecessors_dated THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) carry a term_start, expected % — Kay Ivey''s '
                    'Governor term of %. The other twelve are the ADR 0002 phase-2 backfill with '
                    'start_precision = unknown. ⚠ Alabama''s one dated term is an ACCESSION (on '
                    'Governor Bentley''s resignation), not a cycle start, so it is NOT '
                    'corroboration for § 116 — unlike Maryland, where the predecessor''s '
                    '2023-01-18 was the only in-data evidence for Art. II § 1.',
      n, p.expect_predecessors_dated, p.expect_ivey_accession;
  END IF;
  SELECT count(*) INTO n
    FROM cc0502_pre WHERE term_start IS NOT NULL AND term_start <> p.expect_ivey_accession;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: the one dated predecessor term does not start %. Read it before '
                    'overwriting its term_end — seat_officeholder writes nothing to a closed '
                    'row''s source, so an accession date lost here is unrecoverable.',
      p.expect_ivey_accession;
  END IF;
  -- Each re-election's predecessor must be the winner, and each handover's must not be.
  SELECT count(*) INTO n
    FROM cc0502_pre x JOIN cc0502_sel s ON s.office_id = x.office_id
   WHERE s.is_reelection AND x.politician_id IS DISTINCT FROM s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) marked as a re-election have a predecessor who is not the '
                    'winner. That is a handover nobody has read.', n;
  END IF;
  SELECT count(*) INTO n
    FROM cc0502_pre x JOIN cc0502_sel s ON s.office_id = x.office_id
   WHERE NOT s.is_reelection AND x.politician_id IS NOT DISTINCT FROM s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) marked as a handover have the winner as their own '
                    'predecessor. p_allow_reelection would then be FALSE for a re-election and '
                    'seat_officeholder would refuse.', n;
  END IF;

  -- P7 — Ruling B: every row was called, not certified, when this was written.
  SELECT count(*) INTO n FROM cc0502_sel WHERE certainty IS DISTINCT FROM 'called';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % of the 13 results are no longer "called". If Alabama has certified '
                    'since 2026-11-24 the terms this file writes should say "certified" '
                    'instead — the wording is what a reversed canvass is found by.', n;
  END IF;

  -- P8 — 🔴 NOBODY IN THIS WAVE ENDS UP HOLDING TWO SEATS ON THE HANDOVER DAY. Measured over the
  -- UNION of winners and predecessors, because no per-office count can see somebody left holding
  -- two. (Maryland's Kipke and Utah's Fiefia are the two this programme has met.)
  SELECT count(*) INTO n FROM (
    SELECT t.politician_id, count(DISTINCT t.office_id) AS seats
      FROM essentials.office_terms t
     WHERE t.politician_id IN (SELECT politician_id FROM cc0502_sel WHERE politician_id IS NOT NULL)
       AND (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
       AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start)
     GROUP BY 1) z WHERE seats > 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: % winner(s) already hold more than one office covering %. Seating them '
                    'would leave a named person in two seats at once on our pages. The fix is '
                    'the RESULT that is missing, never tidying the term rows.',
      n, p.expect_term_start;
  END IF;

  -- P9 — 🔴🔴 THE POSITIVE CONTROL FOR P8's ZERO, FOUND BY MEASUREMENT. A zero proves nothing
  -- without a fixture, and this wave has exactly one: Tommy Tuberville holds Alabama's U.S.
  -- Senate seat and won the Governorship. His Senate term must already be closed, and closed
  -- STRICTLY BEFORE the handover, or P8 would be looking at a man holding two seats.
  SELECT count(*) INTO n
    FROM cc0502_sel s
    JOIN essentials.office_terms t ON t.politician_id = s.politician_id
   WHERE t.office_id <> s.office_id
     AND t.office_id NOT IN (SELECT office_id FROM cc0502_sel);
  IF n <> 1 THEN
    RAISE EXCEPTION 'P9: % term(s) outside this wave are held by one of its winners, expected '
                    'exactly 1 — Tommy Tuberville''s U.S. Senate term. ⚠ THIS IS P8''S ONLY '
                    'POSITIVE FIXTURE. If it is 0 the zero above is vacuous; if it is more than '
                    '1, a second cross-body switcher has appeared and needs reading.', n;
  END IF;
  SELECT t.term_start, t.term_end INTO v_sen_start, v_sen_end
    FROM cc0502_sel s
    JOIN essentials.office_terms t ON t.politician_id = s.politician_id
    JOIN essentials.offices o      ON o.id = t.office_id
    JOIN essentials.districts dd   ON dd.id = o.district_id
   WHERE s.title = 'Governor' AND dd.district_type = 'NATIONAL_UPPER';
  IF v_sen_end IS NULL OR v_sen_end >= p.expect_term_start THEN
    RAISE EXCEPTION 'P9: the Governor-elect''s U.S. Senate term ends % and the Governorship '
                    'begins % — it must close STRICTLY BEFORE the handover. The federal '
                    'programme closed it at % under the 20th Amendment; if it has reopened, '
                    'seating him here puts one man in a Senate seat and a Governorship on the '
                    'same day, which is Maryland''s Kipke shape.',
      v_sen_end, p.expect_term_start, p.expect_tuberville_senate_end;
  END IF;
  IF v_sen_end <> p.expect_tuberville_senate_end THEN
    RAISE EXCEPTION 'P9: the Governor-elect''s Senate term closes % and not %. ⚠ The fifteen days '
                    'between its close and this file''s day are CORRECT and not a defect — he '
                    'leaves the Senate when the 20th Amendment says and takes office when § 116 '
                    'says. But the date itself is the federal programme''s and must not have '
                    'moved.', v_sen_end, p.expect_tuberville_senate_end;
  END IF;

  -- P10 — 🔴🔴 THE ALABAMA LEGISLATURE IS STILL ABSENT, AND IT MUST NOT INHERIT THIS DAY.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'al' AND dd.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P10: % Alabama legislative office row(s) now exist, expected 0 when this '
                    'file was written — 35 Senate and 105 House seats that § 46(a) put on the '
                    '2026 ballot as a matter of law and that we do not hold. 🔴 THEIR TERMS BEGAN '
                    '2026-11-04, "the day after the general election", not on this file''s day. '
                    'Read CC_0501''s header before seating them.', n;
  END IF;

  -- P11 — the Public Service Commission's three rows and the board's 4/4 split, restated here so
  -- the seating file refuses on the same facts the dates file did.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'al' AND o.title LIKE 'Public Service Commission%';
  IF n <> 3 THEN
    RAISE EXCEPTION 'P11: Alabama holds % Public Service Commission office row(s), expected 3. ⚠ '
                    'On this very day § 37-1-3(b)(2) seats four gubernatorial APPOINTEES "to '
                    'serve initial terms beginning January 18, 2027" and the commission becomes '
                    'seven. They are not election winners and this wave does not reach them.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'al' AND dd.district_type = 'STATE_BOARD_EDUCATION'
     AND o.id NOT IN (SELECT office_id FROM cc0502_sel);
  IF n <> 4 THEN
    RAISE EXCEPTION 'P11: % board seat(s) are outside this wave, expected 4 (Districts 1, 3, 5, '
                    '7, which carry no 2026 race). ⚠ Neither § 16-3-1 ("as designated by the '
                    'board") nor our own data can prove that split, so it is pinned and not '
                    'argued.', n;
  END IF;

  -- P12 — 🔴 THE DAY'S BEFORE-IMAGE. Alabama is the first state on 2027-01-18, so this is zero
  -- and assertion 3 is a delta from zero — but both near-miss Mondays are crowded, which is what
  -- makes a wrong day here look like a right one.
  IF b.terms_on_the_day <> p.expect_terms_on_the_day_before THEN
    RAISE EXCEPTION 'P12: % term(s) already begin on %, expected % — Alabama is the FIRST state '
                    'in this pass on that day. Another state has landed on it; name its rule '
                    'before adding 13 to the pile.',
      b.terms_on_the_day, p.expect_term_start, p.expect_terms_on_the_day_before;
  END IF;
  IF b.terms_jan4 = 0 OR b.terms_jan11 = 0 THEN
    RAISE EXCEPTION 'P12: the near-miss days carry % and % terms. Both were populated (222 on '
                    '2027-01-04 and 193 on 2027-01-11) when this file was written, and they are '
                    'read here so that "no Alabama seat landed on them" is a discrimination '
                    'rather than a statement about two empty days.', b.terms_jan4, b.terms_jan11;
  END IF;
END $$;

-- @incumbency-decision: gated — this file opens 13 Alabama terms on 2027-01-18 and closes each
--   seat's predecessor at 2027-01-17, so it restates who held those seats on every election day
--   the closed terms no longer cover. The gate below is scoped to the UNION of the 13 winners
--   and their predecessors. ⚠ Tommy Tuberville is a sitting U.S. SENATOR winning the
--   Governorship, so the union reaches across tiers and his Senate race rows are in scope.
-- 🔴 THE INCUMBENCY GUARD'S SCOPE IS A UNION OF WINNERS AND PREDECESSORS. A per-office count
--    cannot see somebody left holding two seats, and a handover changes the incumbency answer for
--    BOTH people in it.
CREATE TEMP TABLE cc0502_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0502_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0502_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0502_guarded);

DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0502_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran. Term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in: the FIRST MONDAY AFTER THE '
                         || 'SECOND TUESDAY IN JANUARY next after the election, under Ala. '
                         || 'Const. 2022 § 116 (the seven state executives), Code of Ala. '
                         || '§ 37-1-3(c)(1) (Public Service Commissioner Places 1 and 2, whose '
                         || 'terms are SIX years because they were elected after June 1, 2026) '
                         || 'or § 16-3-1 (the State Board of Education). The second Tuesday in '
                         || 'January 2027 is the 12th, and § 37-1-3(b)(2) writes this cycle''s '
                         || 'answer out in words — "initial terms beginning January 18, 2027". '
                         || '⚠ "THE THIRD MONDAY" IS NOT A SHORTHAND FOR THIS RULE: it agrees in '
                         || '2027 and not in 2019, when the rule gave 2019-01-14 and the third '
                         || 'Monday 2019-01-21. 🔴 AND THIS DAY IS NOT THE WHOLE STATE''S: § 46(a) '
                         || 'commences a senator''s or representative''s term on the day after '
                         || 'the general election — 2026-11-04 — and we hold no Alabama '
                         || 'legislative office row at all. CC_0502',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0502: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0502_guarded;
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
  SELECT * INTO b FROM cc0502_before;
  SELECT * INTO p FROM cc0502_pin;

  -- 1. Thirteen terms exist, on the offices this file selected, for the people it selected.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0502_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated term(s) on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. The read path answers for all thirteen.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0502_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seat(s).', n, p.expect_offices;
  END IF;

  -- 3. 🔴 THE DAY'S DELTA, AND EVERY ROW ON IT IS ALABAMA'S. It starts from zero, which is a fact
  --    about today and not a property of the day.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_offices THEN
    RAISE EXCEPTION '3: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_start = p.expect_term_start AND lower(d.state) <> 'al';
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % term(s) on % belong to a state other than Alabama. A date shared by '
                    'several states is a coincidence of calendars, never a shared rule.',
      n, p.expect_term_start;
  END IF;
  -- 3b. 🔴 AND NOBODY LANDED ON EITHER NEAR-MISS MONDAY, which are 222 and 193 live terms in five
  --     other states — the whole reason a wrong day here would read as a right one.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0502_sel s ON s.office_id = t.office_id
   WHERE t.term_start IN (DATE '2027-01-04', DATE '2027-01-11', DATE '2027-01-12');
  IF n <> 0 THEN
    RAISE EXCEPTION '3b: % Alabama term(s) start on 2027-01-04 (the FIRST Monday, 222 live terms '
                    'in Arizona, Wisconsin and California), 2027-01-11 (the SECOND Monday, 193 '
                    'in Washington and Oregon) or 2027-01-12 (the second TUESDAY, the anchor '
                    'this rule counts FROM and never the answer).', n;
  END IF;
  IF b.terms_jan4 <> (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-04')
     OR b.terms_jan11 <> (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-11')
     OR b.terms_nov4 <> (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2026-11-04')
  THEN
    RAISE EXCEPTION '3c: a near-miss day''s term count moved. 2027-01-04 was %, 2027-01-11 was % '
                    'and 2026-11-04 — the day § 46(a) gives the Alabama legislature we do not '
                    'hold — was %. This file must not have touched any of them.',
      b.terms_jan4, b.terms_jan11, b.terms_nov4;
  END IF;

  -- 4. Nobody moved TODAY. A future-dated term must not change who holds a seat now.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today.', b.holders_md5, m;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0502_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of the 13 seats still answer office_current_holder with the person '
                    'holding them today, expected %.', n, p.expect_offices;
  END IF;

  -- 6. Every predecessor closed on the day before the handover, and the dated one kept its start.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0502_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0502_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0502_pre x ON x.term_id = t.id
   WHERE t.term_start IS DISTINCT FROM x.term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '6b: % closed predecessor term(s) had their term_start moved. '
                    'seat_officeholder writes nothing to a closed row''s source, so a lost start '
                    'is unrecoverable — and Alabama''s only dated one is Kay Ivey''s % '
                    'accession.', n, p.expect_ivey_accession;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0502_pre x ON x.term_id = t.id
   WHERE t.term_start = p.expect_ivey_accession;
  IF n <> p.expect_predecessors_dated THEN
    RAISE EXCEPTION '6c: % closed predecessor term(s) start %, expected %.',
      n, p.expect_ivey_accession, p.expect_predecessors_dated;
  END IF;

  -- 7. Nothing closed between today and the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0502_sel s ON s.office_id = t.office_id
   WHERE t.term_end IS NOT NULL
     AND t.term_end >= CURRENT_DATE AND t.term_end < p.expect_term_start - 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % term(s) closed between today and the day before the handover.', n;
  END IF;

  -- 8. No person or office was created or destroyed. 🟢 This wave has no people file at all.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %. This wave has no people file — all 13 '
                    'winners already existed.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %. Neither the 140 missing legislative seats nor '
                    'the four Public Service Commission appointees are created here.',
      b.offices, n;
  END IF;

  -- 9. 🔴 NOBODY HOLDS TWO SEATS ON THE HANDOVER DAY, RE-ASKED AFTER THE WRITE — and the one
  --    cross-body switcher is still a switcher rather than a double-holder.
  SELECT count(*) INTO n FROM (
    SELECT t.politician_id, count(DISTINCT t.office_id) AS seats
      FROM essentials.office_terms t
     WHERE t.politician_id IN (SELECT politician_id FROM cc0502_guarded)
       AND (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
       AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start)
     GROUP BY 1) z WHERE seats > 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % person/people now hold more than one office covering %. The Governor-'
                    'elect''s U.S. Senate term closes % under the 20th Amendment, sixteen days '
                    'before this day, and the fifteen-day gap that leaves is correct — a gap '
                    'between two offices is not a defect.',
      n, p.expect_term_start, p.expect_tuberville_senate_end;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE dd.district_type = 'NATIONAL_UPPER' AND lower(dd.state) = 'al'
     AND t.term_end = p.expect_tuberville_senate_end;
  IF n <> 1 THEN
    RAISE EXCEPTION '9b: the Governor-elect''s U.S. Senate term no longer closes %. It is the '
                    'only positive fixture assertion 9''s zero has, and this file must not have '
                    'touched it.', p.expect_tuberville_senate_end;
  END IF;

  -- 10. Ruling B — every new term names the slot and says what it seated from.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0502_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start
     AND t.source LIKE '%CC_0502%' AND t.source LIKE '%called, not certified%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '10: % of % new terms cite CC_0502 and record that the result was called '
                    'rather than certified. That wording is how a reversed canvass is found.',
      n, p.expect_offices;
  END IF;

  -- 11. All thirteen seats have left office_pending_winner, and Alabama has none left at all.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0502_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '11: % of the 13 seats still answer office_pending_winner.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'al' AND w.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '11b: % Alabama seat(s) still answer office_pending_winner for this election, '
                    'expected 0 — Alabama is complete after this wave. ⚠ That is a statement '
                    'about the offices we HOLD: the 140 legislative seats § 46(a) put on this '
                    'ballot do not exist as office rows and are invisible to this count.', n;
  END IF;

  -- 12. No vacancy flag moved, and exactly 13 terms were added.
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '12: the repo-wide count of flagged-vacant offices moved % -> %.',
      b.vacant_all, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '12b: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 13. The drift baseline held, and the view did not move — every one of the 13 seats already
  --     had a term, so none of them was ever in offices_missing_terms.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '13: the unflagged offices_missing_terms count moved % -> %. NEVER RAISE THE '
                    'BASELINE TO CLEAR THIS.', b.missing_unflagged, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> b.missing_all THEN
    RAISE EXCEPTION '13b: offices_missing_terms went % -> %, expected no change.',
      b.missing_all, n;
  END IF;

  RAISE NOTICE 'CC_0502 OK: 13 Alabama seats scheduled for % — 4 re-elections (Andrew Sorrell, '
               'Young Boozer, Tracie West, Yvette Richardson) and 9 handovers, every result '
               'CALLED and not certified, each term citing CC_0502. The date was READ from '
               'office_swearing_in and never typed: the first Monday after the second Tuesday in '
               'January, under Ala. Const. § 116, Code of Ala. § 37-1-3(c)(1) and § 16-3-1. '
               'Alabama is the FIRST state in this pass on this day and no seat landed on either '
               'near-miss Monday, which carry % and % live terms elsewhere. 🔴 A SITTING U.S. '
               'SENATOR BECOMES GOVERNOR: Tommy Tuberville''s Senate term was already closed at % '
               'by the federal programme, so he holds exactly one seat on the handover day and '
               'the fifteen-day gap before it is correct — and he is the single positive fixture '
               'that makes "nobody holds two seats" a measurement rather than a vacuous zero. '
               'Nobody moved today, no vacancy flag moved, no person or office was created, and '
               'the predecessor rows kept their starts — including Kay Ivey''s % accession, which '
               'is Alabama''s ONLY dated state term and is NOT evidence for § 116. 🔴🔴 ALABAMA '
               'NOW HAS NO PENDING STATE SEAT, which is a statement about the offices we hold: '
               '§ 46(a) put 35 Senate and 105 House seats on this ballot, their terms began '
               '2026-11-04, and we hold no Alabama legislative office row at all. Drift baseline '
               '% held.',
    p.expect_term_start, b.terms_jan4, b.terms_jan11, p.expect_tuberville_senate_end,
    p.expect_ivey_accession, b.missing_unflagged;
END $$;

COMMIT;
