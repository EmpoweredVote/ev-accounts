-- CC_0504 — Idaho: seat the 7 state executive winners of 2026-11-03 for 2027-01-04.
--
-- Second of two. CC_0503 writes the date — one provision, one day, Idaho Const. Art. IV § 1 — and
-- this file writes the terms. **No people file**: all 7 winner rows already carry a politician_id,
-- all 7 rows are active, and none collides on either (full_name) or (first_name, last_name).
-- **No Ruling A**: every race is single-seat with one winner.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE PIN — CAPTURED BY REHEARSING `CC_0503 + A PROBE` IN ONE ROLLED-BACK TRANSACTION
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   7 winners · 7 offices · **7 re-elections · 0 handovers** · 7 predecessors (3 of them dated)
--   digest 7e5438e93d4509df73219059ba48b322 · term start 2027-01-04
--
-- Ruling B: all 7 rows were **called**, not certified, when this was written. Every term's
-- `source` carries `CC_0504`, so a reversed canvass is recovered with `source LIKE '%CC_0504%'`.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 IDAHO RETURNED ITS ENTIRE EXECUTIVE DEPARTMENT, AND THAT CHANGES WHAT CAN BE VERIFIED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **All seven winners are the sitting holder of the seat they won** — Brad Little (Governor),
-- Scott Bedke (Lieutenant Governor), Phil McGrane (Secretary of State), Brandon D. Woolf (State
-- Controller), Julie Ellsworth (Treasurer), Raúl Labrador (Attorney General) and Debbie
-- Critchfield (Superintendent of Public Instruction). **Not one seat changes hands.** That is a
-- first in this pass, and it has three consequences that are easy to get wrong:
--
-- 1. 🔴 **THE LIVE PROBE CANNOT BE READ BY THE NAME.** `PICKUP.md` step 9 says to pick an address
--    in a seat that CHANGES HANDS, because a re-election renders the same whether the file worked
--    or not. **In Idaho there is no such seat anywhere in the state.** The probe still
--    discriminates, but only on the DATE: before this file an Idaho address returns seven offices
--    with **no incoming holder at all**, and after it the same seven return
--    `incoming_holder_name` = the sitting holder with `incoming_on = 2027-01-04`. ▶ **Read
--    `incoming_on`, not `incoming_holder_name`** — and the probe must refuse to report if it finds
--    no incoming holder anywhere, because a uniform "no incoming" is a broken detector.
-- 2. 🟢 **`p_allow_reelection` IS TRUE ON ALL SEVEN.** That is what lets `seat_officeholder` close
--    each holder's own open term at 2027-01-03 and open the next at 2027-01-04, rather than
--    refusing to seat somebody into a seat they already hold. ⚠ **Two adjacent days are one
--    handover**: a reader expecting one continuous tenure will find two rows.
-- 3. 🔴 **P6'S HANDOVER ARM HAS NOTHING TO TEST, BY CONSTRUCTION.** The gate asserting that a
--    handover's predecessor is NOT the winner is live in this file and is unreachable in this
--    state, because there are no handovers. It is kept because the next wave copies this file —
--    recorded as **untestable here, not as a tested gate**.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 AND THE "NOBODY HOLDS TWO SEATS" ZERO HAS NO NATURAL FIXTURE IN THIS STATE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Measured 2026-11-24: **not one of the seven winners holds any office outside this wave** — no
-- chamber switcher, no cross-tier move, nothing. So `P8`'s zero is true and **nothing in Idaho's
-- own data can prove the gate would notice if it were false.**
--
-- 🔴 That is the opposite of the last two states and it is stated rather than glossed: Arizona had
--   six chamber switchers and Alabama had Tommy Tuberville moving from the U.S. Senate to the
--   Governorship, and in both the zero was paired with a positive count of real rows. **Here the
--   only available fixture is a PLANTED one**, and control C9 plants it — a second overlapping
--   term for one winner — and watches `P8` go red. ▶ **A planted fixture proves the gate fires; it
--   does not prove the gate is reading the rows a real double-holder would occupy.** Both halves
--   of that are recorded, because the honest claim is narrower than the green tick.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Seven predecessor rows, one per seat, every one with `term_end` NULL and `how_ended` NULL** —
-- and every one held by the winner, because every seat is a re-election. Each becomes
-- `term_end = 2027-01-03`, `how_ended = 'term_expired'`.
--
-- 🔴 `seat_officeholder` closes a predecessor with an unguarded
--   `UPDATE office_terms SET term_end = p_term_start - 1` and writes nothing to that row's
--   `source`, so the new terms are recoverable by slot and **the closures are not**. The seven
--   rows are captured in `cc0504_pre` and P6 asserts every one is open before anything is written.
--
-- 🟢🟢 **THREE OF THE SEVEN CARRY A `term_start`, AND TWO OF THOSE THREE ARE THE ONLY IN-DATA
--   EVIDENCE CC_0503'S RULE HAS.**
--
--     Brad Little        Governor                      2019-01-07  ✅ the first Monday of that Jan
--     Debbie Critchfield Superintendent                2023-01-02  ✅ the first Monday of that Jan
--     Brandon D. Woolf   State Controller              2012-10-15  🔴 OCTOBER — a mid-term
--                                                                  appointment, and ALSO A MONDAY
--
--   Those two agreeing rows were written by different migrations from different sources, which is
--   what makes them independent of each other. **Losing either would destroy the corroboration the
--   date rests on**, so assertion 6b asserts all three starts are unchanged. ⚠ And Woolf's row is
--   the trap `CC_0503`'s assertion 3d exists for: a check shaped "are these Mondays?" admits all
--   three and silently counts an appointment as evidence for an elected-term formula. **The
--   discriminating field is the month.** ⚠ The other four carry no `term_start` at all (the ADR
--   0002 phase-2 backfill, `start_precision = 'unknown'`), so this file writes four term *ends*
--   onto rows with no beginning — normal here, and stated so nobody reads it as damage.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHAT IS NOT SEATED, AND WHY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   **Idaho's legislature — 105 seeded offices with no 2026 result, whose day is SEVEN DAYS AWAY.**
--   Art. III § 3 elects senators and representatives *"for the term of two years, from and after
--   the first day of December next following the general election"*, so all 35 Senate and all 70
--   House seats were on this ballot as a matter of law. We hold every one of those 105 office rows,
--   each held and each carrying a dated term, and **zero 2026 race rows between them**. ⚠ Unlike
--   Alabama's 140 missing offices, **these exist and their day has not passed** — and unlike this
--   file's seven, **they do not take 2027-01-04**. P5 refuses to run if a legislative race has
--   appeared. 🔴 **Read the preposition before dating them**: "from and after the first day" is not
--   plainly "on the first day", and our 72 seeded December rows come from Ballotpedia's "assumed
--   office" rather than from the clause.
--
--   **Idaho's 9 county and 7 local offices**, which also carry no 2026 race. ⚠ `REGISTER.md`
--   records an expectation that Ada County is scheduled for 2027-01-11; measured here, Idaho holds
--   no row of any kind on that day.

BEGIN;

CREATE TEMP TABLE cc0504_pin ON COMMIT DROP AS
SELECT 7                                  AS expect_winners,
       7                                  AS expect_offices,
       7                                  AS expect_reelections,
       0                                  AS expect_new,
       7                                  AS expect_predecessors,
       3                                  AS expect_predecessors_dated,
       222                                AS expect_terms_on_the_day_before,
       '7e5438e93d4509df73219059ba48b322' AS expect_digest,
       DATE '2027-01-04'                  AS expect_term_start,
       DATE '2019-01-07'                  AS expect_little_start,
       DATE '2023-01-02'                  AS expect_critchfield_start,
       DATE '2012-10-15'                  AS expect_woolf_start;

-- 🟢 NO SIBLING EXPANSION: every race is single-seat, so a winner is keyed on the office that
--    carried their own race. P2 measures that rather than assuming it.
CREATE TEMP TABLE cc0504_sel ON COMMIT DROP AS
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
       w.winner_count                                    AS winner_count
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = o.id
                                                AND si.election_date = DATE '2026-11-03'
 WHERE lower(d.state) = 'id'
   AND d.district_type = 'STATE_EXEC'
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0504_pre ON COMMIT DROP AS
SELECT s.office_id, t.id AS term_id, t.politician_id, t.term_start, t.term_end, t.how_ended
  FROM cc0504_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0504_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-04')
                                                                                   AS terms_on_the_day,
       -- 🔴 The near misses, as TERMS. 2027-01-11 is IDAHO'S OWN session convening day and 193
       -- other seats' term start; 2026-12-01 is IDAHO'S OWN legislative term start.
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-11')
                                                                                   AS terms_jan11,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2026-12-01')
                                                                                   AS terms_dec1,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0504_pre)                                           AS predecessors,
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
  SELECT * INTO p FROM cc0504_pin;
  SELECT * INTO b FROM cc0504_before;

  -- P1 — ⚠ ASKED ABOVE EVERY COUNT. On a second run the seats have left office_pending_winner, so
  -- a count check fires first and blames the data for what is a repeat apply.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0504%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % office_terms row(s) already cite CC_0504. Applied before.', n;
  END IF;

  -- P2 — the shape of the wave, including the single-seat property this selection depends on.
  SELECT count(*) INTO n FROM cc0504_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P2: selection returned % winner rows, expected %.', n, p.expect_winners;
  END IF;
  SELECT count(DISTINCT office_id) INTO n FROM cc0504_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P2: % distinct offices, expected %.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n FROM cc0504_sel WHERE winner_count <> 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the 7 races carry more than one winner. 🔴 THIS SELECTION KEYS EVERY '
                    'WINNER ON THE RACE-CARRYING OFFICE, which is only correct while every race is '
                    'single-seat. Under Ruling A the extra winners belong in SIBLING offices, '
                    'post-verify 1 would not find their terms, and this file would abort AFTER '
                    'writing.', n;
  END IF;

  -- P3 — the pin. 🔴 THE COVERAGE COUNT FIRST: a NULL is_reelection renders the whole
  -- concatenation NULL and string_agg skips it, so the digest can cover fewer rows than the counts
  -- claim — and it is the holderless seats it drops.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0504_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: the digest expression evaluated to NULL on % of % row(s), so string_agg '
                    'would have skipped them and the digest below would cover fewer rows than '
                    'every count above claims. is_reelection is NULL on a seat with no current '
                    'holder — all 7 Idaho executive seats were held when this file was written, so '
                    'one has fallen vacant. Read it before seating over it.',
      p.expect_winners - n, p.expect_winners;
  END IF;
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0504_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P3: selection digest is %, expected %. Every count above passed, so the '
                    'membership is the same size and something inside it changed — a different '
                    'office, a different winner, or a seat that changed hands before the '
                    'handover.', d, p.expect_digest;
  END IF;
  -- 🔴🔴 SEVEN OF SEVEN ARE RE-ELECTIONS, AND THAT IS THE FACT THIS FILE'S VERIFICATION RESTS ON.
  -- If one becomes a handover, the live probe gains a readable name and this header is wrong about
  -- what it can see; if one stops being one, seat_officeholder refuses.
  SELECT count(*) INTO n FROM cc0504_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P3: % re-elections, expected % — Idaho returned its ENTIRE executive '
                    'department, so not one seat changes hands. Each is seated with '
                    'p_allow_reelection, which is what lets seat_officeholder close the holder''s '
                    'own open term rather than refusing.', n, p.expect_reelections;
  END IF;
  SELECT count(*) INTO n FROM cc0504_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P3: % handovers, expected % — there are none in this state.', n, p.expect_new;
  END IF;
  -- ⚠ AND THE NAMES, because a count is true of whoever is in the selection.
  SELECT count(*) INTO n
    FROM cc0504_sel
   WHERE (title = 'Governor'                             AND winner_name = 'Brad Little')
      OR (title = 'Lieutenant Governor'                  AND winner_name = 'Scott Bedke')
      OR (title = 'Secretary of State'                   AND winner_name = 'Phil McGrane')
      OR (title = 'State Controller'                     AND winner_name = 'Brandon D. Woolf')
      OR (title = 'Treasurer'                            AND winner_name = 'Julie Ellsworth')
      OR (title = 'Attorney General'                      AND winner_name = 'Raul Labrador')
      OR (title = 'Superintendent of Public Instruction' AND winner_name = 'Debbie Critchfield');
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: only % of the 7 (office, winner) pairs match the names this file was '
                    'written for. The digest moved or a name changed; read the selection before '
                    'seating it.', n;
  END IF;

  -- P4 — the date, READ from office_swearing_in and never typed here.
  SELECT count(*) INTO n FROM cc0504_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 7 seats have no swearing-in date, or one that is not %. CC_0503 '
                    'writes it; if this fires, that file has not run. ⚠ If the date reads '
                    '2027-01-11 somebody has given these offices IDAHO''S OWN SESSION CONVENING '
                    'DAY under Art. III § 8 — 193 live terms in Washington and Oregon — and if it '
                    'reads 2026-12-01 they have been given the LEGISLATURE''s day under Art. III '
                    '§ 3.', n, p.expect_term_start;
  END IF;
  SELECT count(*) INTO n FROM cc0504_sel
   WHERE basis IS DISTINCT FROM 'statute' AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % date(s) have a basis that is neither statute nor published. An estimate '
                    'may not seat anybody — a term start is a legal fact.', n;
  END IF;

  -- P5 — 🔴🔴 THE LEGISLATURE IS STILL UNRACED AND ITS DAY IS SEVEN DAYS OUT. Art. III § 3 gives
  -- all 105 seats a two-year term, so all 105 were on this ballot as a matter of law.
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.elections e  ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.offices o    ON o.id = r.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'id' AND dd.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % Idaho legislative 2026 race row(s) now exist, expected 0 when this file '
                    'was written — 35 Senate and 70 House seats that Art. III § 3 put on the 2026 '
                    'ballot and that we hold no result for. 🔴 THEY DO NOT TAKE THIS FILE''S DATE: '
                    'their terms run "from and after the first day of December next following the '
                    'general election". Read CC_0503''s header before seating them.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'id' AND dd.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 105 THEN
    RAISE EXCEPTION 'P5: Idaho holds % legislative office rows, expected 105 (35 Senate + 70 '
                    'House). Those seats exist, are held and are dated — unlike Alabama''s 140, '
                    'which do not exist at all — so the gap is a RESULTS gap.', n;
  END IF;

  -- P6 — not flagged is_vacant, and the predecessor pre-image, which is what this file overwrites.
  SELECT count(*) INTO n
    FROM cc0504_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % of the 7 offices are flagged is_vacant. A FUTURE-dated seating does not '
                    'clear a flag; that needs a companion file of the CC_0480 / CC_0486 kind, '
                    'applied on the handover day with a data interlock.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0504_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) captured, expected % — one per seat. A seat with '
                    'nobody in it is a fact to read, not to seat over.', n, p.expect_predecessors;
  END IF;
  SELECT count(*) INTO n FROM cc0504_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing, so this file would destroy '
                    'a date no file has written down.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0504_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a how_ended. seat_officeholder '
                    'COALESCEs that column, so an existing value survives.', n;
  END IF;
  -- 🟢🟢 THE THREE DATED PREDECESSORS, NAMED — TWO OF THEM ARE CC_0503'S ONLY IN-DATA EVIDENCE.
  SELECT count(*) INTO n FROM cc0504_pre WHERE term_start IS NOT NULL;
  IF n <> p.expect_predecessors_dated THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) carry a term_start, expected % — Brad Little''s %, '
                    'Debbie Critchfield''s % and Brandon D. Woolf''s %. The other four are the ADR '
                    '0002 phase-2 backfill with start_precision unknown.',
      n, p.expect_predecessors_dated, p.expect_little_start, p.expect_critchfield_start,
      p.expect_woolf_start;
  END IF;
  SELECT count(*) INTO n
    FROM cc0504_pre
   WHERE term_start IS NOT NULL
     AND term_start NOT IN (p.expect_little_start, p.expect_critchfield_start, p.expect_woolf_start);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % dated predecessor term(s) carry a start this file does not know. Two of '
                    'the three (% and %) ARE the first Monday of their own January and are the '
                    'ONLY corroboration Art. IV § 1 has inside our data; the third (%) is a '
                    'mid-term appointment in OCTOBER that is also a Monday, which is the trap '
                    'CC_0503''s assertion 3d exists for.',
      n, p.expect_little_start, p.expect_critchfield_start, p.expect_woolf_start;
  END IF;
  -- Every re-election's predecessor must be the winner. ⚠ THE COMPLEMENTARY ARM — that a
  -- handover's predecessor is NOT the winner — is live below and UNREACHABLE in this state,
  -- because Idaho has no handover. Recorded as untestable here, not as a tested gate.
  SELECT count(*) INTO n
    FROM cc0504_pre x JOIN cc0504_sel s ON s.office_id = x.office_id
   WHERE s.is_reelection AND x.politician_id IS DISTINCT FROM s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) marked as a re-election have a predecessor who is not the '
                    'winner. All seven are re-elections, so that is a handover nobody has read.', n;
  END IF;
  SELECT count(*) INTO n
    FROM cc0504_pre x JOIN cc0504_sel s ON s.office_id = x.office_id
   WHERE NOT s.is_reelection AND x.politician_id IS NOT DISTINCT FROM s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) marked as a handover have the winner as their own predecessor.', n;
  END IF;

  -- P7 — Ruling B: every row was called, not certified, when this was written.
  SELECT count(*) INTO n FROM cc0504_sel WHERE certainty IS DISTINCT FROM 'called';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % of the 7 results are no longer "called". If Idaho has certified since '
                    '2026-11-24 the terms this file writes should say "certified" instead — the '
                    'wording is what a reversed canvass is found by.', n;
  END IF;

  -- P8 — 🔴 NOBODY IN THIS WAVE ENDS UP HOLDING TWO SEATS ON THE HANDOVER DAY. ⚠ THIS ZERO HAS NO
  -- NATURAL FIXTURE IN IDAHO: not one of the seven winners holds any office outside this wave, so
  -- unlike Arizona's six switchers and Alabama's Tuberville there is nothing real to prove the
  -- gate would notice. Control C9 plants one and watches this fire.
  SELECT count(*) INTO n FROM (
    SELECT t.politician_id, count(DISTINCT t.office_id) AS seats
      FROM essentials.office_terms t
     WHERE t.politician_id IN (SELECT politician_id FROM cc0504_sel WHERE politician_id IS NOT NULL)
       AND (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
       AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start)
     GROUP BY 1) z WHERE seats > 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: % winner(s) already hold more than one office covering %. Seating them '
                    'would leave a named person in two seats at once on our pages. The fix is the '
                    'RESULT that is missing, never tidying the term rows.', n, p.expect_term_start;
  END IF;
  -- P8b — and the absence of a fixture is itself asserted, so that "no switcher" stays a
  -- measurement rather than becoming an assumption the next reader inherits.
  SELECT count(*) INTO n
    FROM cc0504_sel s
    JOIN essentials.office_terms t ON t.politician_id = s.politician_id
   WHERE t.office_id <> s.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8b: % term(s) outside this wave are held by one of its winners, expected 0 — '
                    'when this file was written Idaho had NO cross-body switcher at all, which is '
                    'why P8''s zero is backed only by a PLANTED control. A real one has appeared: '
                    'read it, and give P8 the positive count it has been missing.', n;
  END IF;

  -- P9 — 🔴 THE DAY'S BEFORE-IMAGE. Idaho is the FOURTH state on 2027-01-04 and two of the other
  -- three call their rule a first Monday too, so this is a delta and never a total.
  IF b.terms_on_the_day <> p.expect_terms_on_the_day_before THEN
    RAISE EXCEPTION 'P9: % term(s) already begin on %, expected % (Arizona 93, Wisconsin 121, '
                    'California 8). A fifth state has landed on this day — name its rule before '
                    'adding 7 to the pile.',
      b.terms_on_the_day, p.expect_term_start, p.expect_terms_on_the_day_before;
  END IF;
  IF b.terms_jan11 = 0 OR b.terms_dec1 = 0 THEN
    RAISE EXCEPTION 'P9: the near-miss days carry % and % terms. Both were populated when this '
                    'file was written — 2027-01-11 is IDAHO''S OWN session convening day and 193 '
                    'other seats'' term start, 2026-12-01 is IDAHO''S OWN legislative term start — '
                    'and they are read here so that "no Idaho executive landed on them" is a '
                    'discrimination rather than a statement about two empty days.',
      b.terms_jan11, b.terms_dec1;
  END IF;
END $$;

-- @incumbency-decision: gated — this file opens 7 Idaho terms on 2027-01-04 and closes each
--   holder's own term at 2027-01-03, so it restates who held those seats on every election day
--   the closed terms no longer cover. ⚠ ALL SEVEN ARE RE-ELECTIONS, so the winners and the
--   predecessors are the SAME seven people and the union below is seven, not fourteen — the
--   gate is thinner here than its name suggests, which the comment below states outright.
-- 🔴 THE INCUMBENCY GUARD'S SCOPE IS A UNION OF WINNERS AND PREDECESSORS. ⚠ In Idaho those two
--    sets are IDENTICAL, because every seat is a re-election — so the union is seven people, and
--    the gate is thinner here than its name suggests. Stated rather than left to be noticed.
CREATE TEMP TABLE cc0504_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0504_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0504_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0504_guarded);

DO $$
DECLARE s record; v_seated int := 0;
BEGIN
  FOR s IN SELECT * FROM cc0504_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => s.office_id,
      p_politician_id    => s.politician_id,
      p_term_start       => s.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran. Term begins '
                         || to_char(s.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in: "each of whom shall hold his '
                         || 'office for four years beginning on the first Monday in January next '
                         || 'after his election, commencing with those elected in the year 1946, '
                         || 'except as otherwise provided in this Constitution" (Idaho Const. Art. '
                         || 'IV, § 1). That exception was discharged by reading all 21 articles '
                         || 'and 227 sections: Art. III § 25''s oath binds legislators only and '
                         || 'the constitution has no executive oath clause, and Art. XXI § 13 is '
                         || 'the 1890 Schedule. RE-ELECTED INCUMBENT: the predecessor on this seat '
                         || 'is the winner, and their own term is closed at '
                         || to_char(s.term_start - 1, 'YYYY-MM-DD')
                         || ' — all seven Idaho executives were returned, so not one seat changes '
                         || 'hands and a reader must check the DATE rather than the name. 🔴 THIS '
                         || 'DAY IS NOT THE WHOLE STATE''S: Art. III § 3 commences a senator''s or '
                         || 'representative''s term "from and after the first day of December next '
                         || 'following the general election" and Art. III § 8 convenes the '
                         || 'legislature on the SECOND Monday of January; we hold all 105 '
                         || 'legislative offices and no 2026 result for any of them. CC_0504',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => s.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0504: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0504_guarded;
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
  SELECT * INTO b FROM cc0504_before;
  SELECT * INTO p FROM cc0504_pin;

  -- 1. Seven terms exist, on the offices this file selected, for the people it selected.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0504_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated term(s) on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. The read path answers for all seven. 🔴 THIS IS THE ONLY THING A VOTER'S PAGE WILL SHOW
  --    THAT IT DID NOT SHOW BEFORE, because every winner is the sitting holder — so the incoming
  --    DATE is the whole of the visible change.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0504_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seat(s).', n, p.expect_offices;
  END IF;

  -- 3. The day's delta, and every row on it belongs to a named state.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_offices THEN
    RAISE EXCEPTION '3: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE t.term_start = p.expect_term_start AND lower(dd.state) NOT IN ('id', 'az', 'wi', 'ca');
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % term(s) on % belong to a state other than Idaho, Arizona, Wisconsin or '
                    'California. A date shared by four states is a coincidence of calendars, never '
                    'a shared rule — name the new one before absorbing it.', n, p.expect_term_start;
  END IF;
  -- 3b. 🔴 AND NO IDAHO EXECUTIVE LANDED ON A NEAR MISS, two of which are Idaho's own days.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0504_sel s ON s.office_id = t.office_id
   WHERE t.term_start IN (DATE '2027-01-11', DATE '2027-01-01', DATE '2026-12-01',
                          DATE '2026-12-03');
  IF n <> 0 THEN
    RAISE EXCEPTION '3b: % Idaho executive term(s) start on a wrong day — 2027-01-11 (the SECOND '
                    'Monday, IDAHO''S OWN session convening day under Art. III § 8 and 193 live '
                    'terms in Washington and Oregon), 2027-01-01 (January 1st, Utah''s rule), '
                    '2026-12-01 (IDAHO''S OWN LEGISLATIVE term start under Art. III § 3) or '
                    '2026-12-03 (Idaho''s organizational session).', n;
  END IF;
  IF b.terms_jan11 <> (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-11')
     OR b.terms_dec1 <> (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2026-12-01')
  THEN
    RAISE EXCEPTION '3c: a near-miss day''s term count moved. 2027-01-11 was % and 2026-12-01 was '
                    '%. This file must not have touched either — the second is the day Idaho''s '
                    'own 105 legislative seats belong on.', b.terms_jan11, b.terms_dec1;
  END IF;

  -- 4. Nobody moved TODAY. A future-dated term must not change who holds a seat now. ⚠ IN A
  --    SEVEN-OF-SEVEN RE-ELECTION WAVE THIS IS THE GATE THAT EARNS ITS KEEP: the holder map is
  --    unchanged and the winner map is identical to it, so a file that wrote nothing at all would
  --    pass every "who holds this seat?" check. The DELTA above is what distinguishes them.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not move '
                    'a seat today.', b.holders_md5, m;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0504_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of the 7 seats still answer office_current_holder with the person '
                    'holding them today, expected %.', n, p.expect_offices;
  END IF;

  -- 6. Every predecessor closed on the day before the handover, and the three dated ones kept
  --    their starts. 🟢 TWO OF THOSE THREE ARE THE ONLY IN-DATA EVIDENCE CC_0503'S RULE HAS.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0504_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0504_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0504_pre x ON x.term_id = t.id
   WHERE t.term_start IS DISTINCT FROM x.term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '6b: % closed predecessor term(s) had their term_start moved. '
                    'seat_officeholder writes nothing to a closed row''s source, so a lost start '
                    'is unrecoverable — and Brad Little''s % and Debbie Critchfield''s % ARE the '
                    'first Monday of their own January and are the ONLY corroboration Art. IV § 1 '
                    'has inside our data.', n, p.expect_little_start, p.expect_critchfield_start;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0504_pre x ON x.term_id = t.id
   WHERE t.term_start IN (p.expect_little_start, p.expect_critchfield_start, p.expect_woolf_start);
  IF n <> p.expect_predecessors_dated THEN
    RAISE EXCEPTION '6c: % closed predecessor term(s) carry one of the three known starts, '
                    'expected %.', n, p.expect_predecessors_dated;
  END IF;

  -- 7. Nothing closed between today and the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0504_sel s ON s.office_id = t.office_id
   WHERE t.term_end IS NOT NULL
     AND t.term_end >= CURRENT_DATE AND t.term_end < p.expect_term_start - 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % term(s) closed between today and the day before the handover.', n;
  END IF;

  -- 8. No person or office was created or destroyed. 🟢 This wave has no people file, and it
  --    creates none of the 105 legislative seats or the 4 county gaps either.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %. This wave has no people file — all 7 '
                    'winners already existed.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %.', b.offices, n;
  END IF;

  -- 9. 🔴 NOBODY HOLDS TWO SEATS ON THE HANDOVER DAY, RE-ASKED AFTER THE WRITE. ⚠ Idaho has no
  --    natural fixture for this zero — no winner holds any office outside the wave — so it is
  --    backed by a PLANTED control (C9) and nothing else. Stated, not glossed.
  SELECT count(*) INTO n FROM (
    SELECT t.politician_id, count(DISTINCT t.office_id) AS seats
      FROM essentials.office_terms t
     WHERE t.politician_id IN (SELECT politician_id FROM cc0504_guarded)
       AND (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
       AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start)
     GROUP BY 1) z WHERE seats > 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % person/people now hold more than one office covering %.',
      n, p.expect_term_start;
  END IF;

  -- 10. Ruling B — every new term names the slot and says what it seated from.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0504_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start
     AND t.source LIKE '%CC_0504%' AND t.source LIKE '%called, not certified%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '10: % of % new terms cite CC_0504 and record that the result was called '
                    'rather than certified.', n, p.expect_offices;
  END IF;

  -- 11. All seven seats have left office_pending_winner, and Idaho has none left at all.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0504_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '11: % of the 7 seats still answer office_pending_winner.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'id' AND w.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '11b: % Idaho seat(s) still answer office_pending_winner for this election, '
                    'expected 0 — Idaho is complete after this wave. ⚠ That is a statement about '
                    'the seats we hold a RESULT for: the 105 legislative seats Art. III § 3 put on '
                    'this ballot carry no race row at all and are invisible to this count.', n;
  END IF;

  -- 12. No vacancy flag moved, and exactly 7 terms were added.
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

  -- 13. The drift baseline held, and the view did not move — every one of the 7 seats already had
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

  RAISE NOTICE 'CC_0504 OK: 7 Idaho state executives scheduled for % — and ALL SEVEN ARE '
               'RE-ELECTIONS, so not one seat changes hands. Brad Little, Scott Bedke, Phil '
               'McGrane, Brandon D. Woolf, Julie Ellsworth, Raul Labrador and Debbie Critchfield '
               'each close their own open term at % and open the next. 🔴 THAT MAKES THE INCOMING '
               'DATE THE WHOLE OF THE VISIBLE CHANGE: a live probe of an Idaho address must read '
               'incoming_on and NOT incoming_holder_name, because a re-election renders the same '
               'whether this file ran or not. The date was READ from office_swearing_in and never '
               'typed, and no seat landed on any of the four wrong days — 2027-01-11 (IDAHO''S OWN '
               'session convening day and 193 other seats'' term start), 2027-01-01, 2026-12-01 '
               '(IDAHO''S OWN LEGISLATIVE term start) or 2026-12-03. Idaho is the FOURTH state on '
               'this calendar day; % terms were already here. The three dated predecessor terms '
               'kept their starts — Little''s % and Critchfield''s % ARE the first Monday of their '
               'own January and are the ONLY corroboration Art. IV § 1 has in our data, while '
               'Woolf''s % is a mid-term appointment in OCTOBER that is also a Monday. ⚠ NOBODY '
               'HOLDS TWO SEATS, AND IDAHO HAS NO FIXTURE TO PROVE THAT GATE WOULD NOTICE: not one '
               'winner holds an office outside this wave, so the zero rests on a PLANTED control. '
               '🔴🔴 AND 105 LEGISLATIVE SEATS ARE STILL UNRACED, WITH THEIR OWN DAY SEVEN DAYS '
               'AWAY: Art. III § 3 gives every member two years "from and after the first day of '
               'December", we hold all 105 offices, and we hold no result for any of them. Drift '
               'baseline % held.',
    p.expect_term_start, p.expect_term_start - 1, b.terms_on_the_day, p.expect_little_start,
    p.expect_critchfield_start, p.expect_woolf_start, b.missing_unflagged;
END $$;

COMMIT;
