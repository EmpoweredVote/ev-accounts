-- CC_0515 — Texas: seat the Governor and the Lieutenant Governor, whose terms begin 2027-01-19.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE PIN — measured in production 2026-11-25
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   winner rows         2          offices              2
--   re-elections        0          new holders          2
--   term start         2027-01-19  called / certified   2 / 0
--   digest             355b7b2d1b2df865eca429b18dfee649
--
--   2027-01-19  Gina Hinojosa  → Texas Governor             (replaces Greg Abbott)
--   2027-01-19  Vikki Goodwin  → Texas Lieutenant Governor  (replaces Dan Patrick)
--
-- Group B of two. CC_0513 dated all 14; CC_0514 seated the twelve on 2027-01-01. 🔴 **THE SPLIT
-- IS ONE STATUTE'S OWN EXCLUSION LIST**: Gov't Code § 601.003(c) says in its own words that the
-- section "does not apply to the office of governor, lieutenant governor, state senator, or state
-- representative", which is what sends these two to the constitution.
--
-- 🔴🔴 **AND THE TWO OFFICES REACH THIS DAY BY DIFFERENT INSTRUMENTS, WHICH IS WHY THEY CARRY
--   DIFFERENT `rule_id`s.** Art. IV § 4 installs the **Governor** — its heading is literally
--   "INSTALLATION OF GOVERNOR" and the Lieutenant Governor appears nowhere in it. Art. IV § 16(a)
--   is what carries the Lieutenant Governor: that officer is "chosen at every election for
--   Governor by the same voters, in the same manner, **continue in office for the same time**".
--   `DATES.md` § TX puts both offices on "Art. IV § 4 + Gov't Code § 301.001"; read, that citation
--   is about somebody else for one of the two. **CC_0513 is where that was corrected** and P4
--   here asserts the corrected rule_ids rather than trusting them.
--
-- 🟢 **NO PEOPLE FILE AND NO RULING A.** Both winners carry an active `politicians` row, neither
--   collides with another row on (full_name) or (first_name, last_name), and both races are
--   single-seat with exactly one winner.
--
-- 🔴 **BOTH ARE HANDOVERS. NEITHER IS A RE-ELECTION.** Greg Abbott and Dan Patrick each lost the
--   seat they hold. So `p_allow_reelection` is FALSE on both calls, and assertion 5 can check that
--   the incoming person is not yet the current holder.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢🟢 THE RESULT, RE-READ FROM AP'S OWN FEED ON 2026-11-25 BEFORE THIS WAS WRITTEN
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- This file unseats a three-term Governor and a three-term Lieutenant Governor on our pages, so
-- the result was checked against the primary source rather than taken from our own rows. From
-- `interactives.apelections.org/election-results/data-live/2026-11-03/results/national/
-- {metadata,progress}.json`, re-fetched 2026-11-25 (645 races, 43 of them Texas):
--
--   • **Governor** `20261103TX45901`, raceCallStatus **Called**, isCertified false —
--     **Gina Hinojosa (Dem) 5,232,690 / 52.82%**, called 2026-11-04T04:17:30.287Z;
--     Greg Abbott (GOP) 4,525,990 / 45.69%; Pat Dixon (Lib) 148,140 / 1.50%.
--   • **Lieutenant Governor** `20261103TX45902`, **Called** — **Vikki Goodwin (Dem) 5,085,428 /
--     51.73%**, called 2026-11-04T08:00:09.624Z; Dan Patrick (GOP) 4,486,096 / 45.64%;
--     Anthony Cristo (Lib) 170,509; Kevin McCormick (Grn) 88,076.
--
-- Both match our rows exactly, by name and by office.
--
-- 🔴 **WHY IT WAS WORTH THE CHECK.** Every statewide Texas winner in 2026 is a Democrat and every
--   one of them is a sitting Texas legislator we already held a `politicians` row for — which is
--   precisely the shape of a winner flag landing on whichever candidate a pipeline could MATCH
--   rather than on the candidate who won. Four things separate the two readings, and all four
--   point the same way:
--
--   1. **AP's own feed reproduces the calls**, re-fetched today and read as JSON, not summarised.
--   2. **AP's winner is a different `candidateID` from AP's own `incumbents[]` entry** (152027 vs
--      41404 for Governor) **and the surnames differ**, so the TX-22 Nehls-twins detector returns
--      nothing.
--   3. **The feed is not uniformly one party.** Texas's 36 U.S. House races came back mixed —
--      mostly Republican holds, with Democratic gains in TX-15 and TX-09 — and the four statewide
--      margins cluster tightly at 51.7–52.8% to 45.6–45.9%, which is the signature of a real
--      uniform swing rather than of mispaired rows.
--   4. **Two independent pipelines recorded this state**: AP (`CC_0358`) for these two offices
--      and the Attorney General, Ballotpedia (`CC_0360`, `CC_0364`, `CC_0369`) for the rest.
--
--   ⚠ The mundane cause of the correlation is candidate recruitment: Texas Democrats ran sitting
--   legislators, which is why we already held them. ▶ **The correlation was a prompt to look, not
--   a verdict.** It is written down because the next state with a sweep will produce it again.
--
-- 🟢 **AP also explains why the Attorney General's seat was open**: `20261103TX46643`, U.S.
--   Senate — **James Talarico (Dem) 55.09%** over **Ken Paxton (GOP) 42.99%**. Paxton, our
--   current holder of the Texas Attorney General office, ran for the Senate and lost. CC_0514
--   seats his successor on 2027-01-01.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 TWO MORE WINNERS WILL HOLD TWO SEATS, MAKING FIVE IN TEXAS — THE MOST IN THIS PASS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   | winner         | takes                     | still holds           |
--   |----------------|---------------------------|-----------------------|
--   | Gina Hinojosa  | Texas Governor            | TX House District 49  |
--   | Vikki Goodwin  | Texas Lieutenant Governor | TX House District 47  |
--
-- (CC_0514 recorded the other three: Nathan Johnson, Sarah Eckhardt and Jon Rosenthal. Utah
-- produced three of this shape and Oregon one; **Texas produces five**.)
--
-- ⚠ **THE CAUSE IS THE SAME AND IT IS NOT A DEFECT THIS FILE INTRODUCES.** `seat_officeholder`
--   closes the predecessor on the office being *seated* and nothing else. Texas holds 150
--   `STATE_LOWER` office rows and **zero legislative races of any year**, so House Districts 49
--   and 47 get no successor in any wave and nothing closes those terms. Both carry
--   `term_start NULL`, so there is not even a tenure to reason from. ▶ **The fix is the Texas
--   legislative results, not an edit here**, and `P8b` gates on finding exactly two while
--   assertion 9b asserts both are still open afterwards.
--
-- ⚠ Art. IV § 16(b) makes the Lieutenant Governor President of the Senate and Art. III § 19 bears
--   on a legislator taking another state office, and § 17(b) expressly contemplates "a member of
--   the Legislature" serving as Lieutenant Governor. **This file takes no view**: we hold no
--   resignation and no effective date for one, and a `term_end` is a legal fact.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- What this file overwrites — AND HERE ONE PREDECESSOR CARRIES A REAL DATE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴 `seat_officeholder` does `UPDATE office_terms SET term_end = p_term_start - 1` on the
--    predecessor **with no `term_end IS NULL` guard**, and writes nothing to that row's `source`.
--    The two new terms are recoverable by slot; the two closures are not. So, measured 2026-11-25:
--
--    **2 predecessor terms, one per seat. Both carry `term_end = NULL` and `how_ended = NULL`.
--    ONE OF THE TWO CARRIES A REAL `term_start`: the Texas Governor's `2015-01-20` (Greg Abbott).
--    The Lieutenant Governor's is NULL.** Both will be closed at **2027-01-18**
--    (`p_term_start - 1`) with `how_ended = 'term_expired'`. The overwritten `term_end` is NULL in
--    both cases; **the 2015-01-20 start is the one value in this whole Texas wave that a closure
--    could destroy**, so 6b asserts it is unmoved and 6c asserts it by its literal value.
--
-- 🟢🟢 **AND THAT SAME ROW IS THIS STATE'S ONLY IN-DATA DATE CONTROL.** It is the only Texas
--    `office_terms` row with a non-null `term_start` anywhere across all four state tiers. The
--    84th Legislature convened 2015-01-13 (the second Tuesday under Gov't Code § 301.001) and the
--    first Tuesday after that is **2015-01-20** — the clause reproduces the row exactly, and all
--    four separable rival readings miss it (the convening day 2015-01-13, the first Monday
--    2015-01-05, the third Monday 2015-01-19, the first Tuesday 2015-01-06). ▶ **So the row this
--    file closes is the row that justifies the day it closes it on.** P9b re-derives the clause
--    against 2015 before any write, and 6c proves the closure did not damage it.
--
-- ⚠ **"The third Tuesday in January" is NOT a refuted rival** — it is the same rule restated, in
--   every January, which CC_0513's assertion 3c proves over all 39 odd years 1975–2051. Press
--   accounts of this election state the rule both ways and both are right.
--
-- 🟢 **NEITHER SEAT IS FLAGGED `is_vacant`,** and a future-dated seating would not clear a flag
--   in any case.
--
-- Ruling B: **2 of 2 rows were `called`, 0 `certified`,** when this ran, and both terms' `source`
-- carries `CC_0515`.

BEGIN;

CREATE TEMP TABLE cc0515_pin ON COMMIT DROP AS
SELECT 2                                  AS expect_winners,
       2                                  AS expect_offices,
       0                                  AS expect_reelections,
       2                                  AS expect_new,
       2                                  AS expect_predecessors,
       1                                  AS expect_predecessors_dated,
       2                                  AS expect_dual_seat,
       0                                  AS expect_terms_on_the_day_before,
       2                                  AS expect_called,
       73                                 AS expect_terms_jan1,
       '355b7b2d1b2df865eca429b18dfee649' AS expect_digest,
       DATE '2027-01-19'                  AS expect_term_start,
       DATE '2027-01-18'                  AS expect_predecessor_end,
       DATE '2015-01-20'                  AS expect_abbott_start,
       DATE '2027-01-12'                  AS expect_convening_day;

-- 🟢 NO SIBLING EXPANSION: both races are single-seat and each winner is keyed on the office that
--    carried their own race. 🔴 The group is § 601.003(c)'s own exclusion list, taken by title
--    because the statute names these two offices by title — and P2 asserts the selection is
--    exactly those two and that no other Texas seat is still pending.
CREATE TEMP TABLE cc0515_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       o.title                                           AS title,
       d.label                                           AS label,
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
       w.winner_count                                    AS winner_count,
       w.seats                                           AS seats
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = o.id
                                                AND si.election_date = DATE '2026-11-03'
 WHERE lower(d.state) = 'tx'
   AND d.district_type = 'STATE_EXEC'
   AND w.election_date = DATE '2026-11-03'
   AND o.title IN ('Texas Governor', 'Texas Lieutenant Governor');

-- 🔴 THE PREDECESSOR PRE-IMAGE. One of these two rows carries the only dated state term in Texas.
CREATE TEMP TABLE cc0515_pre ON COMMIT DROP AS
SELECT s.office_id, s.title, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0515_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

-- 🔴🔴 THE TWO WINNERS WHO KEEP A HOUSE SEAT, captured by name.
CREATE TEMP TABLE cc0515_dual ON COMMIT DROP AS
SELECT s.winner_name, s.title AS takes, t.id AS kept_term_id, t.office_id AS kept_office_id,
       d2.label AS keeps, t.term_start AS kept_start, t.term_end AS kept_end
  FROM cc0515_sel s
  JOIN essentials.office_terms t ON t.politician_id = s.politician_id
                                AND t.office_id <> s.office_id
  JOIN essentials.offices   o2 ON o2.id = t.office_id
  JOIN essentials.districts d2 ON d2.id = o2.district_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start)
   AND t.office_id NOT IN (SELECT office_id FROM cc0515_sel);

CREATE TEMP TABLE cc0515_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-19')
                                                                                   AS terms_on_the_day,
       -- ⚠ 2027-01-01 now carries CC_0514's twelve on top of Utah's 50 and New Mexico's 11.
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-01')
                                                                                   AS terms_jan1,
       -- 🔴 The near misses, AS TERMS. The third Monday is ALABAMA's live day.
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-18')
                                                                                   AS terms_jan18,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-04')
                                                                                   AS terms_jan4,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-12')
                                                                                   AS terms_jan12,
       -- 🔴 THE CLOSURE DAY, PINNED AS A DELTA. ⚠ 2027-01-18 is empty of term_ends today, so a
       -- total would pass here — but CC_0514 rehearsed with a TOTAL on its own closure day
       -- (2026-12-31) and fired on 68 innocent rows, because that day is shared by every state
       -- seating on 2027-01-01. The same will become true here the moment another state installs
       -- on 2027-01-19, so this is a delta from the start rather than after it breaks.
       (SELECT count(*) FROM essentials.office_terms WHERE term_end = DATE '2027-01-18')
                                                                                   AS terms_ending_prev,
       (SELECT count(*) FROM essentials.office_terms t
          JOIN essentials.offices o   ON o.id = t.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE t.term_end = DATE '2027-01-18' AND lower(d.state) = 'tx')           AS terms_ending_prev_tx,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0515_pre)                                           AS predecessors,
       (SELECT count(*) FROM cc0515_dual)                                          AS dual_seat,
       (SELECT md5(string_agg(och.office_id::text || ':'
                              || COALESCE(och.politician_id::text, '-'),
                              '|' ORDER BY och.office_id::text))
          FROM essentials.office_current_holder och)                               AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged,
       (SELECT count(*) FROM essentials.offices_missing_terms)                     AS missing_all;

DO $$
DECLARE n bigint; d text; p record; b record; v_abbott date; v_conv date; v_inst date;
BEGIN
  SELECT * INTO p FROM cc0515_pin;
  SELECT * INTO b FROM cc0515_before;

  -- P1 — ⚠ ASKED ABOVE EVERY COUNT.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0515%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % office_terms row(s) already cite CC_0515. Applied before.', n;
  END IF;

  -- P2 — 🔴🔴 A TWO-OFFICE WAVE IS WHERE A COUNT GATE PASSES VACUOUSLY, so the selection is
  --      checked by SIZE, by TITLE and against the whole pending set.
  SELECT count(*) INTO n FROM cc0515_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P2: selection returned % winner rows, expected %.', n, p.expect_winners;
  END IF;
  SELECT count(DISTINCT office_id) INTO n FROM cc0515_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P2: % distinct offices, expected %.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM cc0515_sel WHERE title IN ('Texas Governor', 'Texas Lieutenant Governor');
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P2: % of the selected offices are the Governor or the Lieutenant Governor, '
                    'expected %. Those are the only two of § 601.003(c)''s four excluded offices '
                    'that we hold a 2026 result for.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n FROM cc0515_sel WHERE winner_count <> 1 OR COALESCE(seats, 1) <> 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the 2 races are not single-seat with exactly one winner.', n;
  END IF;
  -- 🔴 CC_0514 must already have run: no Texas seat may be left pending except these two.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx' AND w.election_date = DATE '2026-11-03'
     AND o.id NOT IN (SELECT office_id FROM cc0515_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % Texas seat(s) are still pending besides these two. CC_0514 seats the '
                    'twelve on 2027-01-01 and must be applied FIRST — if it has not been, this '
                    'file is running out of order.', n;
  END IF;

  -- P3 — the digest, and the count of rows the expression actually evaluated.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text) INTO n
    FROM cc0515_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: the digest expression evaluated to NULL on % of % row(s), so string_agg '
                    'silently dropped them.', p.expect_winners - n, p.expect_winners;
  END IF;
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text)) INTO d
    FROM cc0515_sel;
  IF d <> p.expect_digest THEN
    RAISE EXCEPTION 'P3: selection digest is %, expected %. The membership moved without the size '
                    'moving.', d, p.expect_digest;
  END IF;
  SELECT count(*) INTO n FROM cc0515_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P3: % re-elections, expected % — Greg Abbott and Dan Patrick each LOST the '
                    'seat they hold, so p_allow_reelection is false on both calls.',
                    n, p.expect_reelections;
  END IF;
  -- 🔴 THE PIN NAMES THE PEOPLE. On a two-row wave this is most of the gate's value.
  SELECT count(*) INTO n
    FROM cc0515_sel s
   WHERE (s.title, s.winner_name) IN (VALUES ('Texas Governor',            'Gina Hinojosa'),
                                             ('Texas Lieutenant Governor', 'Vikki Goodwin'));
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: only % of the 2 (office, winner) pairs match the names this file was '
                    'written against. AP called this race for Gina Hinojosa (52.82%%) and Vikki '
                    'Goodwin (51.73%%) and those calls were re-read on 2026-11-25.', n;
  END IF;
  -- 🔴 AND THE OUTGOING PAIR IS NAMED TOO. This file unseats two named, sitting officials.
  SELECT count(*) INTO n
    FROM cc0515_sel s JOIN essentials.politicians pol ON pol.id = s.holder_before
   WHERE (s.title, pol.full_name) IN (VALUES ('Texas Governor',            'Greg Abbott'),
                                             ('Texas Lieutenant Governor', 'Dan Patrick'));
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P3: only % of the 2 seats are currently held by the person this file expects '
                    'to close out — Greg Abbott and Dan Patrick. Read the rows before seating '
                    'anybody over them.', n;
  END IF;

  -- P4 — 🔴🔴 THE TWO rule_ids, ASSERTED SEPARATELY. This is the only mechanical trace the
  --      Art. IV § 4 / § 16(a) distinction leaves: the DATE is right either way, so no count,
  --      digest or view can tell a correct citation from a wrong one.
  SELECT count(*) INTO n
    FROM cc0515_sel WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 2 seats have no swearing-in date, or one that is not %. '
                    'CC_0513 must be applied first.', n, p.expect_term_start;
  END IF;
  SELECT count(*) INTO n FROM cc0515_sel WHERE basis NOT IN ('statute', 'published');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % date(s) have a basis that is neither statute nor published. AN '
                    'ESTIMATE MAY NOT SEAT ANYBODY.', n;
  END IF;
  SELECT count(*) INTO n
    FROM cc0515_sel
   WHERE rule_id <> CASE title WHEN 'Texas Governor' THEN 'tx-const-art4-s4-installation'
                               ELSE 'tx-const-art4-s16a-same-time-as-governor' END;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 2 seats carry the wrong rule_id for their own instrument. '
                    'Art. IV § 4 installs the GOVERNOR and names the Lieutenant Governor '
                    'NOWHERE; § 601.003(c) excludes that office too, so Art. IV § 16(a) '
                    '("continue in office for the same time") is the only instrument that dates '
                    'it. A citation can be right about the date and wrong about the law, and '
                    'this is the only gate that sees it.', n;
  END IF;

  -- P5 — the 181 absent legislative seats, asked before writing.
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % Texas legislative race row(s) now exist, expected 0 of any year. If '
                    'they have been seeded, House Districts 49 and 47 may now have successors '
                    'and P8b''s dual-seat argument has changed. Re-read before applying.', n;
  END IF;

  -- P6 — vacancy flags and the predecessor pre-image.
  SELECT count(*) INTO n
    FROM cc0515_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % of the 2 offices are flagged is_vacant.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0515_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) captured, expected % — one per seat.',
                    n, p.expect_predecessors;
  END IF;
  SELECT count(*) INTO n FROM cc0515_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a term_end. seat_officeholder''s '
                    'UPDATE has NO term_end IS NULL guard and records nothing of what it '
                    'replaced.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0515_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a how_ended.', n;
  END IF;
  -- 🔴🔴 EXACTLY ONE OF THE TWO IS DATED, AND IT IS THE ONE VALUE IN THIS WHOLE TEXAS WAVE THAT A
  --      CLOSURE COULD DESTROY.
  SELECT count(*) INTO n FROM cc0515_pre WHERE term_start IS NOT NULL;
  IF n <> p.expect_predecessors_dated THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) carry a term_start, expected % — Greg Abbott''s %, '
                    'which is the ONLY dated state term in Texas and also this state''s only '
                    'in-data date control. The Lieutenant Governor''s is NULL.',
                    n, p.expect_predecessors_dated, p.expect_abbott_start;
  END IF;
  SELECT term_start INTO v_abbott
    FROM cc0515_pre WHERE title = 'Texas Governor';
  IF v_abbott IS DISTINCT FROM p.expect_abbott_start THEN
    RAISE EXCEPTION 'P6: the Texas Governor''s predecessor term starts %, expected %. That row is '
                    'the control this file''s own date is justified by; if it has moved, '
                    'P9b below is testing against something else.', v_abbott, p.expect_abbott_start;
  END IF;
  -- Both are handovers: neither predecessor may be the winner.
  SELECT count(*) INTO n
    FROM cc0515_sel s JOIN cc0515_pre r ON r.office_id = s.office_id
   WHERE r.politician_id IS NOT DISTINCT FROM s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) have the winner as their own predecessor, expected 0 — both '
                    'are handovers, so p_allow_reelection is false and seat_officeholder would '
                    'refuse.', n;
  END IF;

  -- P7 — Ruling B.
  SELECT count(*) INTO n FROM cc0515_sel WHERE certainty <> 'called';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % of the 2 results are no longer "called".', n;
  END IF;

  -- P8 — nobody holds both of this wave's offices.
  SELECT count(*) INTO n
    FROM (SELECT politician_id FROM cc0515_sel GROUP BY politician_id HAVING count(*) > 1) x;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: % winner(s) appear on more than one office in this wave. ⚠ Art. IV § 3a '
                    'contemplates one person holding both only when the Governor-elect cannot '
                    'take office, which is not this case.', n;
  END IF;

  -- P8b — 🔴🔴 THE TWO WHO KEEP A HOUSE SEAT. Gated on exactly two and NAMED.
  SELECT count(*) INTO n FROM cc0515_dual;
  IF n <> p.expect_dual_seat THEN
    RAISE EXCEPTION 'P8b: % term(s) outside this wave are held by one of its winners, expected % '
                    '— Gina Hinojosa (TX House District 49) and Vikki Goodwin (TX House District '
                    '47), each of whom will hold two seats from %. Those seats have NO 2026 '
                    'result and no successor, so nothing closes them; that is Texas''s 181-seat '
                    'legislative results gap showing through, and this file does not tidy it.',
                    n, p.expect_dual_seat, p.expect_term_start;
  END IF;
  SELECT count(*) INTO n
    FROM cc0515_dual
   WHERE (winner_name, keeps) IN (VALUES ('Gina Hinojosa', 'TX House District 49'),
                                         ('Vikki Goodwin', 'TX House District 47'));
  IF n <> p.expect_dual_seat THEN
    RAISE EXCEPTION 'P8b: only % of the % dual-seat rows are the ones this file names.',
                    n, p.expect_dual_seat;
  END IF;

  -- P9 — ⚠ 2027-01-19 IS EMPTY BEFORE THIS FILE, SO A "NO STRANGERS THERE" GATE DISCRIMINATES
  --      NOTHING. That is said rather than dressed up as a measurement. What DOES discriminate is
  --      the near-miss days, which are live, and the 2015 re-derivation at P9b.
  IF b.terms_on_the_day <> p.expect_terms_on_the_day_before THEN
    RAISE EXCEPTION 'P9: % term(s) already begin on %, expected % — Texas is the FIRST state on '
                    'this calendar day. If another state has arrived, assertion 3 must name its '
                    'rule instead of asserting the day is Texas''s alone.',
                    b.terms_on_the_day, p.expect_term_start, p.expect_terms_on_the_day_before;
  END IF;
  IF b.terms_jan1 <> p.expect_terms_jan1 THEN
    RAISE EXCEPTION 'P9: 2027-01-01 carries % term(s), expected % — Utah 50, New Mexico 11, and '
                    'CC_0514''s twelve. If this reads 61, CC_0514 HAS NOT BEEN APPLIED and this '
                    'file is running out of order.', b.terms_jan1, p.expect_terms_jan1;
  END IF;
  IF b.terms_jan18 <> 13 OR b.terms_jan4 <> 229 OR b.terms_jan12 <> 0 THEN
    RAISE EXCEPTION 'P9: a near-miss day moved — the third Monday 2027-01-18 carries % term(s) '
                    '(expected 13: ALABAMA), the first Monday 2027-01-04 % (expected 229), the '
                    'convening day 2027-01-12 % (expected 0). A Monday misreading of Art. IV § 4 '
                    'lands this Governor inside Alabama''s cluster.',
                    b.terms_jan18, b.terms_jan4, b.terms_jan12;
  END IF;

  -- P9b — 🟢🟢 THE CLAUSE RE-DERIVED AGAINST THE 2015 CYCLE, BEFORE ANY WRITE. The row this file
  --       is about to CLOSE is the row that justifies the day it closes it on, so the derivation
  --       is run while that row is still intact.
  v_conv := (make_date(2015, 1, 1)
             + ((2 - EXTRACT(ISODOW FROM make_date(2015, 1, 1))::int + 7) % 7)) + 7;
  v_inst := (v_conv + 1) + ((2 - EXTRACT(ISODOW FROM (v_conv + 1))::int + 7) % 7);
  IF v_conv <> DATE '2015-01-13' THEN
    RAISE EXCEPTION 'P9b: the second Tuesday of January 2015 computes as %, not 2015-01-13 — the '
                    'day the 84th Legislature convened under Gov''t Code § 301.001.', v_conv;
  END IF;
  IF v_inst <> p.expect_abbott_start THEN
    RAISE EXCEPTION 'P9b: Art. IV § 4 applied to the 2015 cycle computes as %, not the % our own '
                    'office_terms row carries. The clause no longer reproduces the only in-data '
                    'control this state has, so the 2027 date it produces is unsupported.',
                    v_inst, p.expect_abbott_start;
  END IF;
  -- 🔴 AND THE FOUR RIVALS MISS THAT ROW, which is where they actually die.
  IF (make_date(2015,1,1) + ((1 - EXTRACT(ISODOW FROM make_date(2015,1,1))::int + 7) % 7))
       = p.expect_abbott_start
     OR ((make_date(2015,1,1) + ((1 - EXTRACT(ISODOW FROM make_date(2015,1,1))::int + 7) % 7)) + 14)
       = p.expect_abbott_start
     OR (make_date(2015,1,1) + ((2 - EXTRACT(ISODOW FROM make_date(2015,1,1))::int + 7) % 7))
       = p.expect_abbott_start
     OR v_conv = p.expect_abbott_start THEN
    RAISE EXCEPTION 'P9b: one of the four rival readings also reproduces Greg Abbott''s %, so the '
                    'single in-data control no longer separates Art. IV § 4 from it. Find a '
                    'second cycle before relying on this date. (The 2023 House Journal is the '
                    'one this file already cites.)', p.expect_abbott_start;
  END IF;
  -- The 2027 arithmetic itself.
  IF ((make_date(2027,1,1) + ((2 - EXTRACT(ISODOW FROM make_date(2027,1,1))::int + 7) % 7)) + 7)
       <> p.expect_convening_day THEN
    RAISE EXCEPTION 'P9b: the second Tuesday of January 2027 computes as %, not %.',
                    ((make_date(2027,1,1) + ((2 - EXTRACT(ISODOW FROM make_date(2027,1,1))::int + 7) % 7)) + 7),
                    p.expect_convening_day;
  END IF;

  -- P10 — the drift baseline before.
  IF b.missing_unflagged <> 238 THEN
    RAISE EXCEPTION 'P10: the unflagged drift baseline reads % before this file, expected 238. '
                    '🔴 NEVER RAISE THIS BASELINE.', b.missing_unflagged;
  END IF;
END $$;

-- @incumbency-decision: gated — this file opens 2 Texas terms on 2027-01-19 and closes Greg
--   Abbott's and Dan Patrick's own terms at 2027-01-18, so it restates who held those two seats on
--   every election day the closed terms no longer cover. 🔴 BOTH ARE HANDOVERS AND NEITHER WINNER
--   IS A SITTING HOLDER, so this is the live case rather than the thin one: Abbott's term carries a
--   real 2015-01-20 start and closing it is the write most likely to move an incumbency answer in
--   the whole Texas wave.
-- 🔴 THE INCUMBENCY GUARD'S SCOPE IS A UNION OF WINNERS AND PREDECESSORS. ⚠ Here the two sets are
--    DISJOINT — both seats change hands — so the union is four people: Hinojosa, Goodwin, Abbott
--    and Patrick. Stated rather than left to be noticed.
CREATE TEMP TABLE cc0515_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0515_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0515_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0515_guarded);

DO $$
DECLARE s record; v_seated int := 0;
BEGIN
  FOR s IN SELECT * FROM cc0515_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => s.office_id,
      p_politician_id    => s.politician_id,
      p_term_start       => s.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran. Term begins '
                         || to_char(s.term_start, 'YYYY-MM-DD') || ' per '
                         || 'essentials.office_swearing_in: '
                         || CASE WHEN s.title = 'Texas Governor'
                                 THEN '"The Governor elected at the general election in 1974, and '
                                   || 'thereafter, shall be installed on the FIRST TUESDAY AFTER '
                                   || 'THE ORGANIZATION OF THE LEGISLATURE, or as soon thereafter '
                                   || 'as practicable, and shall hold his office for the term of '
                                   || 'four years" (Tex. Const. Art. IV, § 4). '
                                 ELSE '"There shall also be a Lieutenant Governor, who shall be '
                                   || 'chosen at every election for Governor by the same voters, '
                                   || 'in the same manner, CONTINUE IN OFFICE FOR THE SAME TIME, '
                                   || 'and possess the same qualifications" (Tex. Const. Art. IV, '
                                   || '§ 16(a)), which ties this term to the Governor''s under '
                                   || 'Art. IV § 4. 🔴 ART. IV § 4 DOES NOT NAME THIS OFFICE and '
                                   || 'must not be cited as its authority; Gov''t Code '
                                   || '§ 601.003(c) excludes it too, so § 16(a) is the only '
                                   || 'instrument. Corroborated by Art. IV § 3a, which has a '
                                   || 'Lieutenant-Governor-elect succeeding to the Governorship '
                                   || '"forfeit the office of Lieutenant Governor" at the canvass '
                                   || '— possible only if the office is his at that moment. '
                            END
                         || 'Art. III § 5(a) leaves the convening to statute and Gov''t Code '
                         || '§ 301.001 fixes it at "12 noon on the second Tuesday in January of '
                         || 'each odd-numbered year" — 2027-01-12 — so the first Tuesday after it '
                         || 'is 2027-01-19; §§ 301.002-301.004, in a subchapter titled "INITIAL '
                         || 'MEETING AND ORGANIZATION", put the organization at that meeting. '
                         || 'TERM = INSTALLATION here, which is why Gov''t Code § 601.003 (the '
                         || 'January 1 rule that dates the other twelve) excludes these offices '
                         || 'by name in its subsection (c). ⚠ "or as soon thereafter as '
                         || 'practicable" is a softener, not a second rule, and was not reached '
                         || 'in any cycle checked. CONTROLS: our own office_terms carries the '
                         || 'Texas Governor''s term starting 2015-01-20 — the ONLY dated state '
                         || 'term in Texas — and the 84th Legislature convened 2015-01-13, so the '
                         || 'clause reproduces that row exactly while all four separable rivals '
                         || 'miss it (the convening day, the first Monday, the third Monday, the '
                         || 'first Tuesday). SECOND CYCLE, FROM A DOCUMENT: the Journal of the '
                         || 'House, 88th Legislature, 4th Day, Tuesday January 17 2023, records '
                         || 'the "INAUGURATION OF THE GOVERNOR AND LIEUTENANT GOVERNOR (The House '
                         || 'of Representatives and the Senate in Joint Session)" with both '
                         || 'officers taking the constitutional oath that day — one day, one '
                         || 'session, both offices. ⚠ "The third Tuesday in January" is NOT a '
                         || 'refuted rival but the same rule restated, identical in every '
                         || 'January. HANDOVER: this seat changes hands and the predecessor''s '
                         || 'term is closed at ' || to_char(s.term_start - 1, 'YYYY-MM-DD')
                         || '. 🔴 THE RESULT WAS RE-READ FROM AP''S OWN FEED ON 2026-11-25 BEFORE '
                         || 'THIS WAS WRITTEN, because a statewide sweep is also the shape of a '
                         || 'misassigned winner flag: AP called the Governor for Gina Hinojosa '
                         || '(5,232,690 / 52.82%) and the Lieutenant Governor for Vikki Goodwin '
                         || '(5,085,428 / 51.73%), AP''s winner candidateID differs from AP''s '
                         || 'own incumbent with no surname match, Texas''s 36 U.S. House races '
                         || 'came back MIXED, and our 2026 STATE_EXEC winners nationally split 64 '
                         || 'Democratic / 34 Republican. 🔴 THIS WINNER KEEPS A TEXAS HOUSE SEAT '
                         || 'that has no 2026 result and therefore no successor, so nothing '
                         || 'closes it; that is the 181-seat legislative results gap showing '
                         || 'through and it is NOT tidied here. CC_0515',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => s.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0515: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0515_guarded;
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
  SELECT * INTO b FROM cc0515_before;
  SELECT * INTO p FROM cc0515_pin;

  -- 1. Two terms exist, on the right offices, for the right people.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0515_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated term(s) on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. The read path answers for both.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0515_sel s ON s.office_id = nx.office_id
   WHERE nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seat(s).', n, p.expect_offices;
  END IF;

  -- 3. The delta on the day, and Texas is the only state there. ⚠ THAT CLAIM IS CHEAP BECAUSE THE
  --    DAY WAS EMPTY — it is asserted so a later state is caught, not offered as evidence now.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n - b.terms_on_the_day <> p.expect_offices THEN
    RAISE EXCEPTION '3: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_start = p.expect_term_start AND lower(d.state) <> 'tx';
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % term(s) on % belong to a state other than Texas. Texas was the FIRST '
                    'state on this calendar day, so a second one arriving must be named rather '
                    'than absorbed.', n, p.expect_term_start;
  END IF;
  -- 3b. And no Texas term on the day outside these two offices.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_start = p.expect_term_start AND lower(d.state) = 'tx'
     AND t.office_id NOT IN (SELECT office_id FROM cc0515_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION '3b: % Texas term(s) begin on % outside the Governor and Lieutenant Governor.',
                    n, p.expect_term_start;
  END IF;
  -- 3c. Neither landed on a wrong day, and CC_0514's square is untouched.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0515_sel s ON s.office_id = t.office_id
   WHERE t.term_start IN (DATE '2027-01-18', DATE '2027-01-04', DATE '2027-01-12',
                          DATE '2027-01-05', DATE '2027-01-01');
  IF n <> 0 THEN
    RAISE EXCEPTION '3c: % of this wave''s term(s) start on a wrong day — the third Monday '
                    '2027-01-18 (13 terms: ALABAMA), the first Monday 2027-01-04 (229), the '
                    'convening day 2027-01-12, the first Tuesday 2027-01-05, or Group A''s '
                    '2027-01-01.', n;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = DATE '2027-01-01';
  IF n <> b.terms_jan1 THEN
    RAISE EXCEPTION '3d: 2027-01-01 went % -> %, expected no change — CC_0514 owns that square '
                    'and this file must not touch it.', b.terms_jan1, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = DATE '2027-01-18';
  IF n <> b.terms_jan18 THEN
    RAISE EXCEPTION '3d: 2027-01-18 (Alabama) went % -> %, expected no change.', b.terms_jan18, n;
  END IF;

  -- 4. 🔴 A FUTURE-DATED TERM MUST NOT MOVE THE CURRENT-HOLDER MAP.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text)) INTO m
    FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not '
                    'change who holds a seat TODAY — Greg Abbott is Governor until 2027-01-18.',
                    b.holders_md5, m;
  END IF;

  -- 5. 🟢 BOTH SEATS STILL ANSWER WITH THE OUTGOING OFFICER, AND THE INCOMING ONE DOES NOT.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0515_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of the 2 seats still answer office_current_holder with the person who '
                    'held them before this file, expected % — Greg Abbott and Dan Patrick.',
                    n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0515_sel s ON s.office_id = och.office_id
   WHERE och.politician_id = s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % incoming winner(s) already answer as the CURRENT holder of a seat they '
                    'do not take until %.', n, p.expect_term_start;
  END IF;

  -- 6. The two predecessors closed exactly where they were meant to.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0515_pre r ON r.term_id = t.id
   WHERE t.term_end = p.expect_predecessor_end AND t.how_ended = 'term_expired';
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at % with how_ended term_expired, expected %.',
                    n, p.expect_predecessor_end, p.expect_predecessors;
  END IF;
  -- 6b. 🔴🔴 THE ONE VALUE A CLOSURE COULD HAVE DESTROYED. seat_officeholder writes nothing to a
  --     closed row's source, so a moved term_start would be unrecoverable — and this row is also
  --     the only in-data control this state has.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0515_pre r ON r.term_id = t.id
   WHERE t.term_start IS DISTINCT FROM r.term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '6b: % closed predecessor term(s) had their term_start moved. Greg Abbott''s '
                    '% is the only dated state term in Texas AND this wave''s only in-data '
                    'control; losing it loses the evidence for the date this file just wrote.',
                    n, p.expect_abbott_start;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0515_pre r ON r.term_id = t.id
   WHERE t.term_start = p.expect_abbott_start;
  IF n <> p.expect_predecessors_dated THEN
    RAISE EXCEPTION '6c: % closed predecessor term(s) carry the one known start %, expected %.',
                    n, p.expect_abbott_start, p.expect_predecessors_dated;
  END IF;
  -- 6d. 🔴 NO TERM CLOSED ANYWHERE ELSE — AS A DELTA. ⚠ 2027-01-18 carried no term_end at all
  --     before this file, so the Texas arm below is nearly vacuous TODAY and is written as a
  --     delta anyway: CC_0514's equivalent assertion was a total on 2026-12-31 and fired on 68
  --     innocent rows, because the day before a shared term start is itself a shared day.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_end = p.expect_predecessor_end;
  IF n - b.terms_ending_prev <> p.expect_predecessors THEN
    RAISE EXCEPTION '6d: terms ending on % went % -> %, a delta of %, expected % — one closure '
                    'per seat. ⚠ % term(s) already ended on that day before this file; if that '
                    'is no longer 0, another state now installs on 2027-01-19 and assertion 3 '
                    'must name its rule.',
                    p.expect_predecessor_end, b.terms_ending_prev, n, n - b.terms_ending_prev,
                    p.expect_predecessors, b.terms_ending_prev;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_end = p.expect_predecessor_end AND lower(d.state) = 'tx'
     AND t.id NOT IN (SELECT term_id FROM cc0515_pre);
  IF n <> 0 THEN
    RAISE EXCEPTION '6d: % TEXAS term(s) outside the pre-image also end on %.',
                    n, p.expect_predecessor_end;
  END IF;

  -- 7. Both new terms carry the slot.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0515_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0515%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '7: % of % new term(s) carry CC_0515 in their source.', n, p.expect_offices;
  END IF;

  -- 7b. 🔴🔴 THIS FILE'S ROWS MUST NOT ANSWER TO ANOTHER WAVE'S SLOT QUERY — the mirror of the
  --     defect the first chain rehearsal found in CC_0514, whose narrative named THIS file and so
  --     made its twelve rows answer to this file's own P1.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0515_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start
     AND (t.source LIKE '%CC_0514%' OR t.source LIKE '%CC_0513%');
  IF n <> 0 THEN
    RAISE EXCEPTION '7b: % of this wave''s term(s) name ANOTHER migration''s slot in their '
                    'source. Ruling B recovers a wave with source LIKE ''%%<slot>%%''.', n;
  END IF;

  -- 8. No person and no office created or destroyed.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %. This wave has no people file.',
                    b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %. ⚠ Arizona''s wave found a state that elected a '
                    'Lieutenant Governor we hold no office row for; Texas holds both rows, so '
                    'nothing here needs creating.', b.offices, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '8: flagged-vacant offices moved from % to %.', b.vacant_all, n;
  END IF;

  -- 9. Nobody holds both of this wave's seats from the handover day.
  SELECT count(*) INTO n
    FROM (SELECT t.politician_id
            FROM essentials.office_terms t
           WHERE (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
             AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start)
             AND t.office_id IN (SELECT office_id FROM cc0515_sel)
           GROUP BY t.politician_id HAVING count(*) > 1) x;
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % person/people hold both of this wave''s offices covering %.',
                    n, p.expect_term_start;
  END IF;
  -- 9b. 🔴🔴 AND BOTH KEPT HOUSE TERMS ARE STILL OPEN, WHICH IS THE CORRECT OUTCOME.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0515_dual x ON x.kept_term_id = t.id
   WHERE t.term_end IS NULL AND t.how_ended IS NULL;
  IF n <> p.expect_dual_seat THEN
    RAISE EXCEPTION '9b: % of the % Texas House term(s) kept by a winner of this wave are still '
                    'open, expected both. Gina Hinojosa keeps District 49 and Vikki Goodwin '
                    'District 47 from %, because those seats have NO 2026 result and therefore no '
                    'successor to close them. 🔴 NOT TIDIED HERE: closing them would mean '
                    'inventing a successor or asserting an end date nobody sourced. With '
                    'CC_0514''s three, TEXAS PRODUCES FIVE of this shape — the most in this pass.',
                    n, p.expect_dual_seat, p.expect_term_start;
  END IF;

  -- 10. 🔴 THE DRIFT BASELINE IS UNMOVED. NEVER RAISE IT.
  SELECT count(*) INTO n
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id
   WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '10: the unflagged drift baseline moved from % to %. 🔴 NEVER RAISE THIS '
                    'BASELINE.', b.missing_unflagged, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> b.missing_all THEN
    RAISE EXCEPTION '10: total drift moved from % to %.', b.missing_all, n;
  END IF;

  -- 11. 🟢 TEXAS HAS NO PENDING STATE SEAT LEFT. This is the wave that empties the register row.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx' AND w.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '11: % Texas seat(s) are still pending after both waves, expected 0. Both '
                    'register rows (TX STATE_EXEC and TX STATE_BOARD_EDUCATION) should leave the '
                    'queue together.', n;
  END IF;

  RAISE NOTICE 'CC_0515 OK — the Texas Governor and Lieutenant Governor scheduled for %: Gina '
               'Hinojosa over Greg Abbott and Vikki Goodwin over Dan Patrick, both handovers, '
               'both called. Predecessors: % terms closed at % with how_ended term_expired; ONE '
               'of them carried a real start — Greg Abbott''s %, the only dated state term in '
               'Texas and this state''s only in-data date control — and 6b/6c prove it survived '
               'the closure intact. 🔴🔴 THE TWO OFFICES CARRY DIFFERENT rule_ids BECAUSE THEY '
               'REACH THIS DAY BY DIFFERENT INSTRUMENTS: Art. IV § 4 installs the GOVERNOR and '
               'names the Lieutenant Governor nowhere, so § 16(a) ("continue in office for the '
               'same time") carries that office, corroborated by § 3a''s forfeiture clause and '
               'settled by the 2023 House Journal''s joint session. DATES.md cited § 4 for both. '
               '🟢🟢 THE CLAUSE WAS RE-DERIVED AGAINST THE 2015 CYCLE BEFORE ANY WRITE and '
               'reproduces Abbott''s % exactly, while all four separable rivals miss it; the '
               'third Tuesday is NOT among them because it is the same rule restated. ⚠ 2027-01-19 '
               'was EMPTY before this file, so "no strangers there" proves nothing and is not '
               'offered as proof; the live near-miss is the third Monday 2027-01-18, which '
               'carries ALABAMA''s 13. 🔴🔴 THE RESULT WAS RE-READ FROM AP''S OWN FEED ON '
               '2026-11-25 before this was written, because a 7-0 statewide sweep is also the '
               'shape of a winner flag landing on whichever candidate could be matched to an '
               'existing politicians row — and every Democratic winner here is a sitting Texas '
               'legislator we already held. AP reproduces both calls, its winner candidateID '
               'differs from its own incumbent with no surname match, Texas''s 36 U.S. House '
               'races came back MIXED, and our 2026 STATE_EXEC winners nationally split 64 '
               'Democratic / 34 Republican. 🔴 Hinojosa keeps TX House District 49 and Goodwin '
               'District 47 — with CC_0514''s three, FIVE Texas winners now hold two seats, the '
               'most of any state in this pass — because 181 Texas legislative offices carry ZERO '
               'races of any year. Assertion 9b asserts all of them stay OPEN; the fix is the '
               'legislative results, not an edit here. 🟢 Texas now has 0 pending state seats and '
               'both register rows leave the queue; the drift baseline is still %.',
               p.expect_term_start, p.expect_predecessors, p.expect_predecessor_end,
               p.expect_abbott_start, p.expect_abbott_start, b.missing_unflagged;
END $$;

COMMIT;
