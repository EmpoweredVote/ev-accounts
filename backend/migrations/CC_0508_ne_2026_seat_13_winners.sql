-- CC_0508 — Nebraska: seat 13 winners for 2027-01-07.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THIRTEEN OFFICES, FOUR BODIES, EIGHT CHAMBERS, ONE DAY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   chamber                      seats  leaving              →  arriving
--   Governor                       1    Jim Pillen           →  Jim Pillen          (re-elected)
--   Attorney General               1    Mike Hilgers         →  Mike Hilgers        (re-elected)
--   Auditor of Public Accounts     1    Mike Foley           →  Mike Foley          (re-elected)
--   Treasurer                      1    Joey Spellerberg     →  Joey Spellerberg    (re-elected)
--   Secretary of State             1    Bob Evnen            →  Scott Petersen
--   Board of Regents               3    Timothy Clare        →  Brent Comstock
--                                       Jack Stark           →  Elizabeth Butler
--                                       Joel Makovicka       →  Justin Solomon
--   Public Service Commission      1    Christian Mirch      →  Wendy DeBoer
--   State Board of Education       4    Kirk Penner          →  Angie Eberspacher
--                                       Sherry Jones         →  Sherry Jones        (re-elected)
--                                       Elizabeth Tegtmeier  →  Elizabeth Tegtmeier (re-elected)
--                                       Deborah Neary        →  Lou Ann Goding
--
-- **6 re-elections and 7 handovers, all `called` and none `certified`** (Ruling B). The date is
-- READ from `essentials.office_swearing_in`, written by `CC_0507`, and never typed here — a
-- literal agrees with itself however wrong it is.
--
-- 🟢 **NO PEOPLE FILE AND NO RULING A**, and both were swept for rather than read off a column:
-- all 13 winner rows already carry a `politician_id`, all 13 of those rows are active, every race
-- is single-seat with exactly one winner, and no office in the wave is flagged `is_vacant`.
-- Nebraska is the **fifth** state in this pass needing no people file, after Arizona, Alabama,
-- Idaho and New Mexico.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 ONE WINNER HAS A DUPLICATE PERSON ROW, AND IT COLLIDES ON BOTH KEYS AT ONCE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `essentials.politicians` holds **two active `Mike Foley` rows**:
--
--   `d36beee3-cf6d-4923-ad3f-82a472be8938`  holds Auditor of Public Accounts, 1 term,
--                                           sourced to Ballotpedia by `CC_0363`
--   `38277535-35fb-4e98-973e-8f00a43c4546`  **no source, no term, no seat at all**
--
-- 🟢 **THE WAVE POINTS AT THE RIGHT ONE.** The 2026 winner row and the current holder are both
-- `d36beee3…`, so the Auditor reads as a re-election correctly and no people file is needed. P4
-- asserts both halves — the winner is that id, and the orphan still holds nothing — so the wave
-- cannot quietly start pointing at the empty row.
--
-- ⚠ **It is the only name in the state that collides, and it collides on BOTH (full_name) AND
--   (first_name, last_name).** The database's duplicate-name trigger keys on the split pair, so a
--   name that matches on `full_name` while splitting differently is invisible to it — that was
--   swept for here and nothing else in Nebraska matched on either key. 🔴 **The orphan is a
--   separate cleanup and not this wave's job**, and it is written down here so the next reader
--   inherits it rather than rediscovering it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 "NOBODY HOLDS TWO SEATS" HAS NO NATURAL FIXTURE HERE — THIS IS IDAHO'S CASE, NOT NEW
--      MEXICO'S, AND SAYING SO IS PART OF THE WORK
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Measured 2026-11-24: **not one of the 13 winners holds a term on any office outside the one they
-- won.** No chamber switcher, no cross-tier move, nobody in the Stephanie Garcia Richard shape. So
-- `P8`'s zero is true and **nothing in Nebraska's data can show the gate would notice if it were
-- false.** Arizona had six switchers and Alabama had Tommy Tuberville; New Mexico had a real
-- fixture with both legs inside its wave; **Nebraska has nobody.**
--
-- ▶ **`P8b` asserts the ABSENCE itself**, so the next reader inherits a measurement rather than an
--   assumption, and the control suite **plants** one (`ne-2026.controls.mjs`).
-- 🔴 **A planted fixture proves the gate FIRES; it does not prove the gate reads the rows a real
--   double-holder would occupy.** That distinction is recorded rather than glossed.
-- ⚠ **And New Mexico's lesson is carried**: the planted term must go on a winner who **already
--   holds a seat**, or they end with exactly one, `P8` passes *honestly* and a later gate fires
--   instead. The six re-elected incumbents here are the only usable fixtures.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 NEBRASKA IS THE SECOND STATE ON 2027-01-07, SO EVERY COUNT HERE IS A DELTA
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **2 terms already begin on 2027-01-07**, both Massachusetts — the Governor and the Lieutenant
-- Governor (`CC_0484`). A gate asking "how many terms start on this day?" would read **15** after
-- this file and call it success. P11 pins the before-image, assertion 3 asserts the delta is
-- exactly 13, and every term on the day must belong to a **named** state.
--
-- ⚠ **AND THE TWO POPULATED NEAR MISSES ARE PINNED TOO**, because refusing a day only means
--   something when that day has rows on it:
--
--   2027-01-04  the FIRST MONDAY — **229 live terms** in Wisconsin, Arizona, California and Idaho
--   2027-01-06  🔴🔴 **200 live terms** — Massachusetts' 199 legislators and the Maine Governor —
--               and it is simultaneously what **MAINE'S RULE** gives (a sentence identical to
--               Nebraska's with Wednesday in place of Thursday) and the day **NEBRASKA'S OWN
--               LEGISLATURE** takes under Art. III-10 and § 32-122
--
-- 🔴 **The dangerous wrong answer for the DATE is not a near miss at all — it is the shorthand
--   "the first Thursday in January", which gives this file's own day in 2027.** `CC_0507`'s header
--   carries the whole argument and the evidence that separates them; this file inherits the date
--   by reading it, which is the only defence a seating file has against that class of error.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 ONE SEAT IN THIS WAVE IS AN UNEXPIRED REMAINDER, AND NOTHING IN A TERM ROW SAYS SO
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **University of Nebraska Regent, District 4** is not a regular election. `§ 32-510` puts that
-- district on the 1994 + six-year cycle, which 2026 is not on; it is here under `§ 32-573(2)(a)`,
-- because **Elizabeth O'Connor won it in 2024 and resigned** and Joel Makovicka was appointed on
-- 2026-02-03 to hold it *"until the first Thursday following the first Tuesday in January
-- following such general election"* — this file's day — *"and at such general election a member of
-- the Board of Regents shall be elected to serve THE UNEXPIRED TERM if any."*
--
-- 🟢 **`seat_officeholder` writes no `term_end`, so nothing this file writes is wrong.** 🔴 **But
-- Justin Solomon's term ends when O'Connor's would have, not six years from now**, and no column
-- records that. ▶ **It is written into that row's own `source`**, which is the only place a later
-- reader will look, and assertion 10c asserts it is there.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ TWO GAPS ARE PINNED RATHER THAN TIDIED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- - **THE LIEUTENANT GOVERNOR.** The office row exists, is held, and has no pending winner —
--   correctly, because `Art. IV-1` casts *"one vote … jointly for the candidates for Governor and
--   Lieutenant Governor"* and the winner is recorded against the Governor's race. **No wave reaches
--   the seat until a winner row names its holder.** 🔴 This is **Arizona's missing Lieutenant
--   Governor from the opposite side**: Arizona has a winner and no office row, Nebraska an office
--   row and no winner. Both are the results and seeding programme's, not seating's.
-- - **THE LEGISLATURE — 49 seats, absent entirely.** Nebraska holds zero `STATE_UPPER` and zero
--   `STATE_LOWER` office rows. ⚠ **Their day is 2027-01-06, NOT this one**, under § 32-122 read
--   with Art. III-10 — so unlike New Mexico's 70 they would not be absorbed into the day this wave
--   creates. They would be absorbed into Massachusetts' and Maine's 200 instead, which is no
--   better. `P10` refuses if one appears.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 WHAT CAN AND CANNOT BE VERIFIED FROM OUTSIDE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Seven of the thirteen seats change hands**, so step 9's live probe can be read by the incoming
-- NAME and not only by the date — unlike Idaho, where seven of seven were re-elections and a file
-- that wrote nothing at all would have passed every "who holds this seat?" check.
-- ⚠ **A statewide address reaches only the five executives plus whichever districted seats cover
--   it**, so the probe has to pick an address inside a district this wave actually touched.

BEGIN;

CREATE TEMP TABLE cc0508_pin ON COMMIT DROP AS
SELECT 13                                 AS expect_winners,
       13                                 AS expect_offices,
       6                                  AS expect_reelections,
       7                                  AS expect_new,
       13                                 AS expect_predecessors,
       1                                  AS expect_predecessors_dated,
       2                                  AS expect_terms_on_the_day_before,
       229                                AS expect_terms_first_monday_before,
       200                                AS expect_terms_wednesday_before,
       20                                 AS expect_guarded,
       'f255837483b655c569e6703bdcbae90d' AS expect_digest,
       DATE '2027-01-07'                  AS expect_term_start,
       DATE '2027-01-06'                  AS expect_wednesday,
       DATE '2027-01-04'                  AS expect_first_monday,
       DATE '2023-01-05'                  AS expect_pillen_start,
       'd36beee3-cf6d-4923-ad3f-82a472be8938'::uuid AS expect_foley_real,
       '38277535-35fb-4e98-973e-8f00a43c4546'::uuid AS expect_foley_orphan;

-- 🟢 NO SIBLING EXPANSION: every race is single-seat, so a winner is keyed on the office that
--    carried their own race. P2 measures that rather than assuming it.
CREATE TEMP TABLE cc0508_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       o.title                                           AS title,
       (win.value ->> 'id')::uuid                        AS politician_id,
       (win.value ->> 'name')                            AS winner_name,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id')) AS is_reelection,
       si.swearing_in_date                               AS term_start,
       si.basis                                          AS basis,
       si.rule_id                                        AS rule_id,
       och.politician_id                                 AS holder_before,
       w.certainty                                       AS certainty,
       w.winner_count                                    AS winner_count
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = o.id
                                                AND si.election_date = DATE '2026-11-03'
 WHERE lower(d.state) = 'ne'
   AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD', 'STATE_BOARD_EDUCATION')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0508_pre ON COMMIT DROP AS
SELECT s.office_id, t.id AS term_id, t.politician_id, t.term_start, t.term_end, t.how_ended
  FROM cc0508_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0508_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-07')
                                                                                   AS terms_on_the_day,
       -- 🔴 Both near misses as TERMS. 2027-01-04 is the first Monday; 2027-01-06 is where
       -- Maine's rule and Nebraska's own Legislature both land, beside 199 Massachusetts seats.
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-04')
                                                                                   AS terms_mon,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-06')
                                                                                   AS terms_wed,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0508_pre)                                           AS predecessors,
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
  SELECT * INTO p FROM cc0508_pin;
  SELECT * INTO b FROM cc0508_before;

  -- P1 — ⚠ ASKED ABOVE EVERY COUNT. On a second run the seats have left office_pending_winner, so
  -- a count check fires first and blames the data for what is a repeat apply.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0508%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % office_terms row(s) already cite CC_0508. Applied before.', n;
  END IF;

  -- P2 — the shape of the wave, including the single-seat property this selection depends on.
  SELECT count(*) INTO n FROM cc0508_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P2: selection returned % winner rows, expected %.', n, p.expect_winners;
  END IF;
  SELECT count(DISTINCT office_id) INTO n FROM cc0508_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P2: % distinct offices, expected %.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n FROM cc0508_sel WHERE winner_count <> 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the 13 races carry more than one winner. 🔴 THIS SELECTION KEYS '
                    'EVERY WINNER ON THE RACE-CARRYING OFFICE, which is only correct while every '
                    'race is single-seat. Under Ruling A the extra winners belong in SIBLING '
                    'offices, post-verify 1 would not find their terms, and this file would abort '
                    'AFTER writing.', n;
  END IF;
  -- 🔴 AND THE WAVE SPANS EIGHT CHAMBERS INSIDE THREE district_types. district_type is not a body:
  --    the STATE_BOARD tier holds the Board of Regents AND the Public Service Commission under two
  --    different constitutional articles, and the register's generated table shows them as one row.
  SELECT count(DISTINCT o.chamber_id) INTO n
    FROM cc0508_sel s JOIN essentials.offices o ON o.id = s.office_id;
  IF n <> 8 THEN
    RAISE EXCEPTION 'P2: the 13 seats span % chambers, expected 8 — five single-office executive '
                    'chambers plus the Board of Regents, the Public Service Commission and the '
                    'State Board of Education.', n;
  END IF;

  -- P3 — the pin. 🔴 THE COVERAGE COUNT FIRST: a NULL is_reelection renders the whole
  -- concatenation NULL and string_agg skips it, so the digest can cover fewer rows than the counts
  -- claim — and it is the holderless seats it drops. ⚠ IT CANNOT OCCUR IN NEBRASKA, because all 13
  -- seats are held and none is flagged vacant. The gate is here anyway: CC_0487 kept it in the
  -- same position and a control proved the two gates are complementary, not redundant.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0508_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: the digest expression evaluated to NULL on % of % row(s), so string_agg '
                    'would have skipped them and the digest below would cover fewer rows than '
                    'every count above claims. is_reelection is NULL on a seat with no current '
                    'holder — all 13 Nebraska seats were held when this file was written, so one '
                    'has fallen vacant. Read it before seating over it.',
      p.expect_winners - n, p.expect_winners;
  END IF;
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0508_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P3: selection digest is %, expected %. Every count above passed, so the '
                    'membership is the same size and something inside it changed — a different '
                    'office, a different winner, or a seat that changed hands before the '
                    'handover.', d, p.expect_digest;
  END IF;
  SELECT count(*) INTO n FROM cc0508_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P3: % re-elections, expected %.', n, p.expect_reelections;
  END IF;
  SELECT count(*) INTO n FROM cc0508_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P3: % handovers, expected % — seven Nebraska seats change hands, which is '
                    'what lets step 9''s live probe be read by the incoming NAME rather than only '
                    'by the date. Idaho had none and could be read only by the date.',
      n, p.expect_new;
  END IF;
  -- ⚠ AND THE NAMES, because a count is true of whoever is in the selection.
  SELECT count(*) INTO n
    FROM cc0508_sel
   WHERE (title = 'Governor'                                            AND winner_name = 'Jim Pillen')
      OR (title = 'Attorney General'                                    AND winner_name = 'Mike Hilgers')
      OR (title = 'Auditor of Public Accounts'                          AND winner_name = 'Mike Foley')
      OR (title = 'Treasurer'                                           AND winner_name = 'Joey Spellerberg')
      OR (title = 'Secretary of State'                                  AND winner_name = 'Scott Petersen')
      OR (title = 'Public Service Commissioner, District 2'             AND winner_name = 'Wendy DeBoer')
      OR (title = 'University of Nebraska Regent, District 1'           AND winner_name = 'Brent Comstock')
      OR (title = 'University of Nebraska Regent, District 2'           AND winner_name = 'Elizabeth Butler')
      OR (title = 'University of Nebraska Regent, District 4'           AND winner_name = 'Justin Solomon')
      OR (title = 'Nebraska State Board of Education Member, District 5' AND winner_name = 'Angie Eberspacher')
      OR (title = 'Nebraska State Board of Education Member, District 6' AND winner_name = 'Sherry Jones')
      OR (title = 'Nebraska State Board of Education Member, District 7' AND winner_name = 'Elizabeth Tegtmeier')
      OR (title = 'Nebraska State Board of Education Member, District 8' AND winner_name = 'Lou Ann Goding');
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: only % of the 13 (office, winner) pairs match the names this file was '
                    'written for. The digest moved or a name changed; read the selection before '
                    'seating it.', n;
  END IF;

  -- P4 — 🔴 THE DUPLICATE PERSON ROW, BOTH HALVES. Two active "Mike Foley" rows exist and they
  -- collide on (full_name) AND on (first_name, last_name), so neither key distinguishes them. The
  -- wave must point at the one that holds the seat, and the orphan must still hold nothing — a
  -- check on only one of those would pass while the wave seated the wrong row.
  SELECT count(*) INTO n
    FROM cc0508_sel
   WHERE title = 'Auditor of Public Accounts' AND politician_id = p.expect_foley_real;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P4: the Auditor of Public Accounts winner is not %, the sourced Mike Foley '
                    'row that holds the seat (% matching row(s)). 🔴 THERE ARE TWO ACTIVE "Mike '
                    'Foley" ROWS and they collide on BOTH keys, so the duplicate-name trigger '
                    'cannot see the difference either. The other is %, which has no source, no '
                    'term and no seat.', p.expect_foley_real, n, p.expect_foley_orphan;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms WHERE politician_id = p.expect_foley_orphan;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: the orphan Mike Foley row % now holds % term(s), expected 0. It had no '
                    'source, no term and no seat when this file was written, and it is a separate '
                    'cleanup rather than this wave''s job — but if something has seated it, the '
                    'two rows are no longer distinguishable by "which one holds the office".',
      p.expect_foley_orphan, n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.politicians p2
    JOIN cc0508_sel s ON s.politician_id = p2.id
   WHERE p2.is_active IS NOT TRUE;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 13 winners point at an INACTIVE politicians row. One row per '
                    'person, archived never deleted — seating an archived row puts a name on our '
                    'pages that nothing else reads.', n;
  END IF;

  -- P5 — 🔴🔴 THE ONE SEAT THAT IS AN UNEXPIRED REMAINDER. § 32-510 does not elect Regent District
  -- 4 in 2026; § 32-573(2)(a) does, because Elizabeth O'Connor resigned and Joel Makovicka was
  -- appointed to hold it until this file's day. Gated on the evidence staying where it is: the
  -- term row CC_0375 wrote is the only record of WHY that seat was on the ballot, and the only
  -- thing that stops Justin Solomon's term being read as a fresh six years.
  SELECT count(*) INTO n
    FROM cc0508_pre x
    JOIN cc0508_sel s  ON s.office_id = x.office_id
    JOIN essentials.office_terms t  ON t.id = x.term_id
    JOIN essentials.politicians  p2 ON p2.id = x.politician_id
   WHERE s.title = 'University of Nebraska Regent, District 4'
     AND p2.full_name = 'Joel Makovicka'
     AND t.source LIKE '%unexpired remainder%'
     AND t.source LIKE '%serves through 2027-01-07%';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P5: Regent District 4''s predecessor is not Joel Makovicka under CC_0375''s '
                    'appointment note (% matching row(s)). 🔴 THAT NOTE IS LOAD-BEARING TWICE: it '
                    'is why this seat is on a 2026 ballot that § 32-510 does not put it on, and '
                    'it is the only record that the term this file opens is an UNEXPIRED '
                    'REMAINDER of Elizabeth O''Connor''s 2024 term rather than a fresh six years.',
      n;
  END IF;

  -- P6 — not flagged is_vacant, and the predecessor pre-image, which is what this file overwrites.
  SELECT count(*) INTO n
    FROM cc0508_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % of the 13 offices are flagged is_vacant. A FUTURE-dated seating does '
                    'not clear a flag; that needs a companion file of the CC_0480 / CC_0486 kind, '
                    'applied on the handover day with a data interlock.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0508_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) captured, expected % — one per seat. A seat with '
                    'nobody in it is a fact to read, not to seat over.', n, p.expect_predecessors;
  END IF;
  SELECT count(*) INTO n FROM cc0508_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing, so this file would '
                    'destroy a date no file has written down.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0508_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a how_ended. seat_officeholder '
                    'COALESCEs that column, so an existing value survives.', n;
  END IF;
  -- 🟢🟢 THE ONE DATED PREDECESSOR, NAMED — IT IS CC_0507'S ONLY IN-DATA EVIDENCE.
  SELECT count(*) INTO n FROM cc0508_pre WHERE term_start IS NOT NULL;
  IF n <> p.expect_predecessors_dated THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) carry a term_start, expected % — Jim Pillen''s %. '
                    'The other twelve are the ADR 0002 phase-2 backfill and roster reads, all '
                    'with start_precision unknown.',
      n, p.expect_predecessors_dated, p.expect_pillen_start;
  END IF;
  SELECT count(*) INTO n
    FROM cc0508_pre WHERE term_start IS NOT NULL AND term_start <> p.expect_pillen_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % dated predecessor term(s) carry a start this file does not know. The '
                    'one it knows, Jim Pillen''s %, IS the first Thursday after the first Tuesday '
                    'of its own year and is the ONLY corroboration Art. XVII-5 has inside our '
                    'data — a corpus of one. ⚠ And it cannot separate this rule from the '
                    'shorthand "the first Thursday in January", which lands on the same day in '
                    '2023; only the Secretary of State''s 2024 canvass book does that.',
      n, p.expect_pillen_start;
  END IF;
  -- Every re-election's predecessor must be the winner, and every handover's must not be. 🟢 BOTH
  -- ARMS ARE REACHABLE HERE — six re-elections and seven handovers — unlike Idaho, where seven of
  -- seven were re-elections and the second arm was unreachable by construction.
  SELECT count(*) INTO n
    FROM cc0508_pre x JOIN cc0508_sel s ON s.office_id = x.office_id
   WHERE s.is_reelection AND x.politician_id IS DISTINCT FROM s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) marked as a re-election have a predecessor who is not the '
                    'winner — that is a handover nobody has read.', n;
  END IF;
  SELECT count(*) INTO n
    FROM cc0508_pre x JOIN cc0508_sel s ON s.office_id = x.office_id
   WHERE NOT s.is_reelection AND x.politician_id IS NOT DISTINCT FROM s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) marked as a handover have the winner as their own '
                    'predecessor.', n;
  END IF;

  -- P7 — the date, READ from office_swearing_in and never typed here. ⚠ AND THE RULE_ID TOO.
  SELECT count(*) INTO n FROM cc0508_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % of the 13 seats have no swearing-in date, or one that is not %. '
                    'CC_0507 writes it; if this fires, that file has not run. ⚠ If the date reads '
                    '2027-01-06 somebody has given these offices MAINE''S RULE or the '
                    'LEGISLATURE''S day — 200 live terms between Massachusetts and Maine — and if '
                    'it reads 2027-01-04 they have given them the first Monday, 229 live terms in '
                    'four states.', n, p.expect_term_start;
  END IF;
  SELECT count(*) INTO n FROM cc0508_sel
   WHERE rule_id IS DISTINCT FROM 'ne-const-art17-5-first-thursday-after-first-tuesday-january';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % seat(s) are dated under a rule this file does not know. All four '
                    'Nebraska bodies fall to ONE residual clause, so a second rule_id on this day '
                    'means a body has been dated from somewhere else — read it before seating.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0508_sel
   WHERE basis IS DISTINCT FROM 'statute' AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % date(s) have a basis that is neither statute nor published. An estimate '
                    'may not seat anybody — a term start is a legal fact.', n;
  END IF;

  -- P8 — 🔴 NOBODY IN THIS WAVE ENDS UP HOLDING TWO SEATS ON THE HANDOVER DAY. Asked BEFORE the
  -- write, when it is trivially true. The gate that matters is assertion 9, after the write.
  SELECT count(*) INTO n FROM (
    SELECT t.politician_id, count(DISTINCT t.office_id) AS seats
      FROM essentials.office_terms t
     WHERE t.politician_id IN (SELECT politician_id FROM cc0508_sel WHERE politician_id IS NOT NULL)
       AND (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
       AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start)
     GROUP BY 1) z WHERE seats > 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: % winner(s) already hold more than one office covering %. Seating them '
                    'would leave a named person in two seats at once on our pages. The fix is the '
                    'RESULT that is missing, never tidying the term rows.', n, p.expect_term_start;
  END IF;

  -- P8b — 🔴🔴 AND THE ABSENCE OF A FIXTURE IS ASSERTED, NOT ASSUMED. This is Idaho's case: not
  -- one of the 13 winners holds a term on any office outside the one they won, so P8's zero is
  -- VACUOUS and nothing in Nebraska's data can show the gate would notice if it were false.
  -- Arizona had six chamber switchers, Alabama had Tommy Tuberville, New Mexico had Stephanie
  -- Garcia Richard with both legs inside its wave. Nebraska has nobody, and the control suite
  -- PLANTS one — on a RE-ELECTED INCUMBENT, because P8 asks whether a winner holds MORE THAN ONE
  -- office and only somebody with a seat already can answer yes (New Mexico's C19 learned that by
  -- planting on a winner who held nothing, and P8 passed honestly while a later gate fired).
  SELECT count(*) INTO n
    FROM cc0508_sel s
    JOIN essentials.office_terms t ON t.politician_id = s.politician_id
   WHERE t.office_id <> s.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8b: % term(s) outside the office they won are held by one of this wave''s '
                    'winners, expected 0 when this file was written. 🟢 THAT IS GOOD NEWS FOR THE '
                    'CONTROLS AND MUST BE READ: Nebraska had no natural fixture for the "nobody '
                    'holds two seats" zero, so the suite plants one. A real one has appeared — '
                    'find out whether it is a chamber switcher whose vacated seat is INSIDE this '
                    'wave (Oregon''s Helfrich, which closes itself) or OUTSIDE it (Utah''s '
                    'Fiefia, where the vacated seat''s own result is missing). The difference is '
                    'a result, not a rule.', n;
  END IF;

  -- P9 — 🔴 THE LIEUTENANT GOVERNOR HAS AN OFFICE AND NO WINNER, AND THAT IS CORRECT. Art. IV-1
  -- casts one joint vote, so the winner is recorded against the Governor's race. Pinned so the gap
  -- stays legible rather than being read later as an unrecorded result.
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ne' AND o.title = 'Lieutenant Governor';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P9: Nebraska holds % Lieutenant Governor office row(s), expected 1.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o ON o.id = w.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ne' AND o.title = 'Lieutenant Governor';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P9: the Nebraska Lieutenant Governor now carries % pending winner(s), '
                    'expected 0. 🟢 THAT WOULD BE GOOD NEWS AND IT MAKES THIS WAVE LARGER: '
                    'Art. IV-1 elects the office jointly on the Governor''s ticket and the winner '
                    'has always been recorded against the Governor''s race, so nothing reached '
                    'the seat. CC_0507 dates five executives; extend it to six and re-derive the '
                    'pin. ⚠ This is ARIZONA''S MISSING LIEUTENANT GOVERNOR FROM THE OPPOSITE '
                    'SIDE — there the winner exists and the office row does not.', n;
  END IF;

  -- P10 — 🔴 THE LEGISLATURE IS ABSENT. ⚠ Its day is 2027-01-06, NOT this file's, so an arriving
  -- seat would not be absorbed into the day this wave creates the way New Mexico's 70 would have
  -- been. It would be absorbed into Massachusetts' and Maine's 200 instead.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ne' AND dd.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P10: Nebraska now holds % legislative office row(s), expected 0 when this '
                    'file was written — all 49 seats of the unicameral are absent from our data. '
                    '🔴 They are carved out of Art. XVII-5 by § 32-122 and take 2027-01-06 under '
                    'Art. III-10, so they need their own rule_id and their own file. Read '
                    'CC_0507''s header first.', n;
  END IF;

  -- P11 — 🔴 THE DAY'S BEFORE-IMAGE. Nebraska is the SECOND state on 2027-01-07, so this is a
  -- delta and never a total; and both populated near misses are pinned.
  IF b.terms_on_the_day <> p.expect_terms_on_the_day_before THEN
    RAISE EXCEPTION 'P11: % term(s) already begin on %, expected % (the Massachusetts Governor '
                    'and Lieutenant Governor, CC_0484). A third state has landed on this day — '
                    'name its rule before adding 13 to the pile.',
      b.terms_on_the_day, p.expect_term_start, p.expect_terms_on_the_day_before;
  END IF;
  IF b.terms_mon <> p.expect_terms_first_monday_before THEN
    RAISE EXCEPTION 'P11: % term(s) begin on % (THE FIRST MONDAY), expected %. It is read here so '
                    'that "no Nebraska seat landed on it" is a discrimination against a populated '
                    'day rather than a statement about an empty one.',
      b.terms_mon, p.expect_first_monday, p.expect_terms_first_monday_before;
  END IF;
  IF b.terms_wed <> p.expect_terms_wednesday_before THEN
    RAISE EXCEPTION 'P11: % term(s) begin on % , expected %. 🔴🔴 THAT DAY IS PINNED FOR TWO '
                    'REASONS AT ONCE: it is what MAINE''S RULE gives — this clause''s own '
                    'sentence with Wednesday in place of Thursday, carrying the Maine Governor '
                    'beside 199 Massachusetts legislators — and it is where NEBRASKA''S OWN '
                    'LEGISLATURE belongs under Art. III-10 and § 32-122.',
      b.terms_wed, p.expect_wednesday, p.expect_terms_wednesday_before;
  END IF;
END $$;

-- @incumbency-decision: gated — this file opens 13 Nebraska terms on 2027-01-07 and closes each
--   seat's predecessor at 2027-01-06, so it restates who held those seats on every election day
--   the closed terms no longer cover. The gate below is scoped to the UNION of the 13 winners and
--   their predecessors, which measured 20 people: six re-elections overlap and seven handovers do
--   not, so the union is larger than either side.
-- 🔴 THE INCUMBENCY GUARD'S SCOPE IS A UNION OF WINNERS AND PREDECESSORS, because no per-office
--    count can see somebody left holding two seats. ⚠ In Nebraska the two sets genuinely differ
--    (13 + 13 → 20), which is the case Idaho could not exercise — there the two sets were
--    identical because every seat was a re-election.
CREATE TEMP TABLE cc0508_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0508_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0508_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0508_guarded);

DO $$
DECLARE s record; v_seated int := 0;
BEGIN
  FOR s IN SELECT * FROM cc0508_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => s.office_id,
      p_politician_id    => s.politician_id,
      p_term_start       => s.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran. Term begins '
                         || to_char(s.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in. THE AUTHORITY IS ONE RESIDUAL '
                         || 'CLAUSE REACHING FOUR BODIES: Neb. Const. Art. XVII-5 — "UNLESS '
                         || 'OTHERWISE PROVIDED BY THIS CONSTITUTION OR BY LAW the terms of all '
                         || 'elected officers shall begin on the first Thursday after the first '
                         || 'Tuesday in January next succeeding their election" — with '
                         || '§ 32-572(1) pointing at it ("the fixed term shall end and the '
                         || 'successor … shall qualify on the day for taking office as provided '
                         || 'by law") and § 32-573 writing the same formula into statute for the '
                         || 'Board of Regents. The carve-out was discharged by a SWEEP of 234 '
                         || 'constitutional sections and all 488 of Chapter 32, each with a '
                         || 'positive control: the oath (Art. XV-1) binds "before they enter upon '
                         || 'their official duties", Art. XVII-4 is a HOLDOVER clause, and no '
                         || 'other provision names a day for any of these offices. 🔴 THE '
                         || 'DANGEROUS WRONG ANSWER IS THE SHORTHAND "the first Thursday in '
                         || 'January", which gives THIS SAME DAY in 2027 and January 2 in 2025, '
                         || 'where the Secretary of State''s canvass book says January 9 twelve '
                         || 'times — see CC_0507. '
                         || CASE WHEN s.is_reelection
                              THEN 'RE-ELECTED INCUMBENT: the predecessor on this seat is the '
                                   || 'winner, and their own term is closed at '
                              ELSE 'HANDOVER: the predecessor''s term is closed at ' END
                         || to_char(s.term_start - 1, 'YYYY-MM-DD')
                         || '. '
                         || CASE WHEN s.title = 'University of Nebraska Regent, District 4'
                              THEN '🔴🔴 THIS SEAT IS AN UNEXPIRED REMAINDER AND NOT A FRESH '
                                   || 'SIX-YEAR TERM. § 32-510 puts Regent District 4 on the 1994 '
                                   || 'six-year cycle, which 2026 is NOT on; it was on this '
                                   || 'ballot under § 32-573(2)(a), because Elizabeth O''Connor '
                                   || 'won it in 2024 and resigned and Joel Makovicka was '
                                   || 'appointed on 2026-02-03 to serve "until the first Thursday '
                                   || 'following the first Tuesday in January following such '
                                   || 'general election and at such general election a member of '
                                   || 'the Board of Regents shall be elected to serve THE '
                                   || 'UNEXPIRED TERM if any". So this term ends when '
                                   || 'O''Connor''s would have, around January 2031, NOT six '
                                   || 'years from now. seat_officeholder writes no term_end, so '
                                   || 'this source line is the only record of it. '
                              ELSE '' END
                         || '🔴 THIS DAY IS NOT THE WHOLE STATE''S RECORD: the LIEUTENANT '
                         || 'GOVERNOR has an office row and no winner, correctly, because '
                         || 'Art. IV-1 casts one joint vote with the Governor; and all 49 seats '
                         || 'of the unicameral are absent from our data, carved out of '
                         || 'Art. XVII-5 by § 32-122 and belonging on 2027-01-06 under '
                         || 'Art. III-10 — one day before this, where 200 Massachusetts and Maine '
                         || 'rows already sit. CC_0508',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => s.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0508: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0508_guarded;
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;
  IF v_planned = 0 THEN
    RAISE EXCEPTION 'incumbency guard: the plan table is EMPTY, so this gate asserted nothing. '
      'Point it at the politicians whose office_terms rows this migration writes.';
  END IF;
  -- ⚠ THE UNION IS LARGER THAN EITHER SIDE HERE, which is the property Idaho could not exercise.
  IF v_planned <> 20 THEN
    RAISE EXCEPTION 'incumbency guard: the guarded set is % people, expected 20 — the 13 winners '
      'plus the 7 predecessors they do not overlap with (six seats are re-elections, so the '
      'winner and the predecessor are the same person). If it has collapsed to 13 the guard''s '
      'scope is narrower than its name; if it is larger, somebody has moved between seats and '
      'P8b should have caught it.', v_planned;
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
                  coalesce(pol.full_name, '(unnamed)'), c.race_candidate_id, c.stored, c.expected),
           E'\n' ORDER BY coalesce(pol.full_name, ''))
           FILTER (WHERE NOT c.drifted_before AND c.drifted_after)
    INTO v_created, v_repaired, v_detail
    FROM cmp c
    LEFT JOIN essentials.politicians pol ON pol.id = c.politician_id;
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
  SELECT * INTO b FROM cc0508_before;
  SELECT * INTO p FROM cc0508_pin;

  -- 1. Thirteen terms exist, on the offices this file selected, for the people it selected.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0508_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated term(s) on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. The read path answers for all thirteen.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0508_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seat(s).', n, p.expect_offices;
  END IF;

  -- 3. The day's delta, and every term on it belongs to a named state.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_offices THEN
    RAISE EXCEPTION '3: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE t.term_start = p.expect_term_start AND lower(dd.state) NOT IN ('ne', 'ma');
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % term(s) on % belong to a state other than Nebraska or Massachusetts. A '
                    'date shared by two states is a coincidence of calendars, never a shared '
                    'rule — name the new one before absorbing it.', n, p.expect_term_start;
  END IF;
  -- 3b. 🔴 AND NO NEBRASKA SEAT LANDED ON EITHER POPULATED NEAR MISS.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0508_sel s ON s.office_id = t.office_id
   WHERE t.term_start IN (p.expect_first_monday, p.expect_wednesday, DATE '2027-01-05');
  IF n <> 0 THEN
    RAISE EXCEPTION '3b: % Nebraska term(s) start on a wrong day — % (the FIRST MONDAY, 229 live '
                    'terms in four states), % (where MAINE''S RULE and NEBRASKA''S OWN '
                    'LEGISLATURE both land, 200 live terms) or 2027-01-05 (the first Tuesday, '
                    'Nebraska''s historic canvass day, empty).',
      n, p.expect_first_monday, p.expect_wednesday;
  END IF;
  IF b.terms_mon <> (SELECT count(*) FROM essentials.office_terms
                      WHERE term_start = p.expect_first_monday) THEN
    RAISE EXCEPTION '3c: the first Monday''s term count moved from %. This file must not have '
                    'touched that day — it belongs to Wisconsin, Arizona, California and Idaho.',
      b.terms_mon;
  END IF;
  IF b.terms_wed <> (SELECT count(*) FROM essentials.office_terms
                      WHERE term_start = p.expect_wednesday) THEN
    RAISE EXCEPTION '3d: the % term count moved from %. This file must not have touched that day '
                    '— it belongs to Massachusetts and Maine, and it is where Nebraska''s own '
                    'Legislature would go if it existed.', p.expect_wednesday, b.terms_wed;
  END IF;

  -- 4. Nobody moved TODAY. A future-dated term must not change who holds a seat now.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today — Bob Evnen stays Secretary of State and Joel Makovicka '
                    'stays Regent for District 4 until 2027-01-06.', b.holders_md5, m;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0508_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of the 13 seats still answer office_current_holder with the person '
                    'holding them today, expected %.', n, p.expect_offices;
  END IF;

  -- 6. Every predecessor closed on the day before the handover, and the one dated row kept its
  --    start. 🟢 THAT ROW IS THE ONLY IN-DATA EVIDENCE CC_0507'S RULE HAS.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0508_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0508_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0508_pre x ON x.term_id = t.id
   WHERE t.term_start IS DISTINCT FROM x.term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '6b: % closed predecessor term(s) had their term_start moved. '
                    'seat_officeholder writes nothing to a closed row''s source, so a lost start '
                    'is unrecoverable — and Jim Pillen''s % is the ONLY corroboration '
                    'Art. XVII-5 has inside our data.', n, p.expect_pillen_start;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0508_pre x ON x.term_id = t.id
   WHERE t.term_start = p.expect_pillen_start;
  IF n <> p.expect_predecessors_dated THEN
    RAISE EXCEPTION '6c: % closed predecessor term(s) carry the one known start %, expected %.',
      n, p.expect_pillen_start, p.expect_predecessors_dated;
  END IF;
  -- 6d. 🔴 AND CC_0375'S APPOINTMENT NOTE SURVIVED THE CLOSURE. It is the only record of why
  --     Regent District 4 was on this ballot and that the term just opened is an unexpired
  --     remainder; seat_officeholder writes nothing to a closed row's source, so it should be
  --     untouched — and if it ever is touched, the evidence goes with it.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0508_pre x ON x.term_id = t.id
   WHERE t.source LIKE '%unexpired remainder%' AND t.source LIKE '%serves through 2027-01-07%';
  IF n <> 1 THEN
    RAISE EXCEPTION '6d: CC_0375''s Regent District 4 appointment note is no longer on the closed '
                    'predecessor term (% matching row(s)).', n;
  END IF;

  -- 7. Nothing closed between today and the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0508_sel s ON s.office_id = t.office_id
   WHERE t.term_end IS NOT NULL
     AND t.term_end >= CURRENT_DATE AND t.term_end < p.expect_term_start - 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % term(s) closed between today and the day before the handover.', n;
  END IF;

  -- 8. No person or office was created or destroyed. 🟢 This wave has no people file, and it
  --    creates neither the Lieutenant Governor's missing race nor the 49 absent legislative seats.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %. This wave has no people file — all 13 '
                    'winners already existed, which was swept for rather than read off the "no '
                    'record" column.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %.', b.offices, n;
  END IF;

  -- 9. 🔴🔴 NOBODY HOLDS TWO SEATS ON THE HANDOVER DAY, RE-ASKED AFTER THE WRITE — over the UNION
  --    of winners and predecessors, because no per-office count can see somebody left holding two.
  --    ⚠ THIS ZERO IS VACUOUS IN NEBRASKA AND P8b SAYS SO: no winner holds a term outside the seat
  --    they won, so there is no real fixture and the control suite plants one. Idaho's case.
  SELECT count(*) INTO n FROM (
    SELECT t.politician_id, count(DISTINCT t.office_id) AS seats
      FROM essentials.office_terms t
     WHERE t.politician_id IN (SELECT politician_id FROM cc0508_guarded)
       AND (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
       AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start)
     GROUP BY 1) z WHERE seats > 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % person/people now hold more than one office covering %. Nebraska had NO '
                    'natural double-holder before this file, so if one exists now this file '
                    'created it — read the seat, do not tidy the term rows.', n, p.expect_term_start;
  END IF;
  -- 9b. 🟢 AND THE SEVEN HANDOVERS ARE ASSERTED POSITIVELY, not only as the absence of a problem:
  --     each one's predecessor is CLOSED on the right day and the winner is OPEN on it. A count of
  --     zero double-holders is also true of somebody who was never seated at all.
  SELECT count(*) INTO n
    FROM cc0508_sel s
    JOIN cc0508_pre x ON x.office_id = s.office_id
    JOIN essentials.office_terms told ON told.id = x.term_id
    JOIN essentials.office_terms tnew ON tnew.office_id = s.office_id
                                     AND tnew.politician_id = s.politician_id
   WHERE NOT s.is_reelection
     AND told.term_end   = p.expect_term_start - 1
     AND tnew.term_start = p.expect_term_start;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION '9b: % of the % handovers read back as a clean pair — the predecessor''s term '
                    'ending on % and the winner''s beginning on %.',
      n, p.expect_new, p.expect_term_start - 1, p.expect_term_start;
  END IF;

  -- 10. Ruling B — every new term names the slot and says what it seated from.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0508_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start
     AND t.source LIKE '%CC_0508%' AND t.source LIKE '%called, not certified%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '10: % of % new terms cite CC_0508 and record that the result was called '
                    'rather than certified.', n, p.expect_offices;
  END IF;
  -- 10b. ⚠ AND THE RE-ELECTIONS AND HANDOVERS SAY WHICH THEY ARE, because the source line is what
  --      a reader reconstructing a reversed canvass has.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0508_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND s.is_reelection
     AND t.source LIKE '%RE-ELECTED INCUMBENT%';
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION '10b: % of % re-elected terms say so in their source.', n,
      p.expect_reelections;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0508_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND NOT s.is_reelection
     AND t.source LIKE '%HANDOVER%';
  IF n <> p.expect_new THEN
    RAISE EXCEPTION '10b: % of % handover terms say so in their source.', n, p.expect_new;
  END IF;
  -- 10c. 🔴🔴 AND THE ONE UNEXPIRED REMAINDER SAYS SO, ON EXACTLY ONE ROW. seat_officeholder
  --      writes no term_end, so a later reader computing six years from this start would give
  --      Justin Solomon two years that belong to nobody. The source line is the only record, and
  --      it must be on HIS row and on no other — a note that leaked onto all thirteen would make
  --      the whole wave look like a vacancy wave.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0508_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start
     AND t.source LIKE '%THIS SEAT IS AN UNEXPIRED REMAINDER%';
  IF n <> 1 THEN
    RAISE EXCEPTION '10c: % of the 13 new terms declare themselves an UNEXPIRED REMAINDER, '
                    'expected exactly 1 — Justin Solomon''s Regent District 4 seat, which '
                    '§ 32-510 does not elect in 2026 and § 32-573(2)(a) does, for the remainder '
                    'of Elizabeth O''Connor''s 2024 term. 🔴 With 0 the only record that his term '
                    'ends around 2031 rather than 2033 is gone; with more than 1 the note has '
                    'leaked onto a regular six-year or four-year seat.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0508_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start
     AND t.source LIKE '%THIS SEAT IS AN UNEXPIRED REMAINDER%'
     AND s.title = 'University of Nebraska Regent, District 4';
  IF n <> 1 THEN
    RAISE EXCEPTION '10c: the UNEXPIRED REMAINDER note is not on Regent District 4 (% matching '
                    'row(s)). It is on some other seat, which is worse than it being missing.', n;
  END IF;

  -- 11. All thirteen seats have left office_pending_winner, and Nebraska has none left at all.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0508_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '11: % of the 13 seats still answer office_pending_winner.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ne' AND w.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '11b: % Nebraska seat(s) still answer office_pending_winner for this '
                    'election, expected 0 — Nebraska is complete after this wave. ⚠ That is a '
                    'statement about the seats we hold a RESULT for: the Lieutenant Governor and '
                    'all 49 legislative seats are invisible to this count.', n;
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

  -- 13. The drift baseline held, and the view did not move — every one of the 13 seats already had
  --     a term, so none of them was ever in offices_missing_terms.
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

  RAISE NOTICE 'CC_0508 OK: 13 Nebraska offices scheduled for % — FOUR BODIES ACROSS THREE '
               'district_types AND EIGHT CHAMBERS, 6 re-elections and 7 handovers, all called. '
               'Scott Petersen takes the Secretaryship of State from Bob Evnen, Wendy DeBoer the '
               'Public Service Commission''s District 2 from Christian Mirch, and three Regents '
               'and two Board of Education members change too. The date was READ from '
               'office_swearing_in and never typed, and no seat landed on % (the FIRST MONDAY, % '
               'live terms in four states) or % (% live terms, where MAINE''S RULE — this '
               'clause''s own sentence with Wednesday in place of Thursday — and NEBRASKA''S OWN '
               'LEGISLATURE both land). Nebraska is the SECOND state on this calendar day; '
               'Massachusetts'' % terms were already here. 🔴🔴 ONE SEAT IS NOT WHAT IT LOOKS '
               'LIKE: Regent District 4 is a § 32-573(2)(a) VACANCY election for the unexpired '
               'remainder of Elizabeth O''Connor''s 2024 term, because § 32-510 puts that '
               'district on the 1994 six-year cycle and 2026 is not on it. Justin Solomon''s term '
               'therefore ends around 2031, not 2033, and nothing but that row''s own source says '
               'so. 🔴 THE "NOBODY HOLDS TWO SEATS" ZERO IS VACUOUS HERE — not one winner holds '
               'an office outside the one they won, so P8b asserts the ABSENCE and the control '
               'suite plants a fixture on a re-elected incumbent. ⚠ AND TWO GAPS ARE LEFT EXACTLY '
               'AS THEY WERE: the LIEUTENANT GOVERNOR has an office row and no winner, correctly, '
               'because Art. IV-1 elects it on the Governor''s ticket — Arizona''s missing '
               'Lieutenant Governor from the opposite side; and all 49 seats of the unicameral '
               'are absent from our data and belong on %, carved out of Art. XVII-5 by § 32-122. '
               'Drift baseline % held.',
    p.expect_term_start, p.expect_first_monday, b.terms_mon, p.expect_wednesday, b.terms_wed,
    b.terms_on_the_day, p.expect_wednesday, b.missing_unflagged;
END $$;

COMMIT;
