-- CC_0514 — Texas: seat the 12 winners whose terms begin 2027-01-01.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE PIN — measured in production 2026-11-25, AFTER CC_0513 and with no people file between
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   winner rows        12          offices             12
--   re-elections        2          new holders         10
--   term start         2027-01-01  called / certified  12 / 0
--   digest             7dd2559835b91c53787ef7f3f5fa59cc
--
-- Group A of two. CC_0513 wrote all 14 dates; CC_0515 seats the Governor and Lieutenant Governor
-- on 2027-01-19. 🔴 **TEXAS SHIPS AS TWO SEATING WAVES BECAUSE ONE STATUTE NAMES TWO DAYS** —
-- Gov't Code § 601.003(a) dates these twelve and its own subsection (c) sends the other two to
-- Const. Art. IV §§ 4 and 16(a). `derive-seating-wave.mjs` refuses to pin a wave with two term
-- starts, correctly, which is why the split is in the files and not only in the prose.
--
-- 🟢 **NO PEOPLE FILE.** All 12 winners already carry an active `politicians` row and none
--   collides with another row on (full_name) or on (first_name, last_name) — swept across the
--   whole table. So unlike Massachusetts, the digest could be captured BEFORE any write without
--   the `is_reelection` NULL appearing later: there is no file here that creates a person.
--
-- 🟢 **NO RULING A.** All 12 races are single-seat with exactly one winner (`seats` = 1 and
--   `winner_count` = 1 on every row, asserted at P2), so each winner is keyed on the office that
--   carried their own race and there is no mapping to invent.
--
-- 🔴 **AND `is_reelection` IS NOT NULL ANYWHERE HERE, WHICH IS MEASURED RATHER THAN ASSUMED.**
--   California's defect is a NULL on a seat with no current holder: `och` is LEFT JOINed, so
--   `true AND NULL` is NULL, `'…' || NULL` is NULL, and `string_agg` SKIPS it — the digest then
--   covers fewer rows than the counts claim and it is the holderless seats it drops. **All 12
--   Texas offices are held**, so the expression evaluates on all 12; P3 counts how many rows it
--   actually evaluated rather than trusting that.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 TWELVE OF FOURTEEN SEATS CHANGE HANDS, AND THE RESULT IS THE BIGGEST CLAIM IN THIS FILE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Ten of this wave's twelve are handovers. Texas returned only **Tiffany Clark** (State Board of
-- Education District 13) and **Julie Pickren** (District 7). Every statewide executive on this
-- ballot changed hands, and so did five of the seven Board seats.
--
-- 🟢🟢 **THE RESULT WAS RE-READ FROM AP'S OWN FEED ON 2026-11-25 BEFORE ANY OF THIS WAS WRITTEN,
--   BECAUSE A CLEAN SWEEP IS THE SHAPE A BROKEN PIPELINE ALSO MAKES.** Seating these rows
--   unseats seven named, sitting Texas officials on our pages, which is the cost Ruling A exists
--   to guard against, reached from the results side instead. What was checked, and what each
--   check settled:
--
--   • **AP's national feed, re-fetched today** — `interactives.apelections.org/election-results/
--     data-live/2026-11-03/results/national/{metadata,progress}.json`, 645 races, 43 of them
--     Texas. For this wave's one AP-covered office it calls **Jon Rosenthal (Dem) 5,105,065 /
--     52.52%** over Bo French (GOP) 4,427,530 / 45.55%, called 2026-11-04T08:36:42Z — which is
--     our row exactly. (The other six Texas statewide calls are in CC_0515's header and in
--     DATES.md § TX.)
--   • **The feed is not uniformly one party**, which is what rules out the obvious parser
--     defect: Texas's 36 U.S. House races came back mixed, with most Republican holds and a
--     handful of Democratic gains.
--   • **Our own database is not uniformly one party either**: across every 2026 `STATE_EXEC`
--     winner nationally the split is 64 Democratic / 34 Republican / 81 with no party recorded.
--   • **AP's winner is a different `candidateID` from AP's own `incumbents[]` entry and the
--     surnames differ**, so the TX-22 twins detector returns nothing here.
--   • **Two independent pipelines recorded this state**: AP (`CC_0358`) for the Governor,
--     Lieutenant Governor and Attorney General, Ballotpedia (`CC_0360`, `CC_0364`, `CC_0369`)
--     for the rest. A row-pairing bug in one would not reproduce in the other.
--
--   🔴 **WHAT MADE IT WORTH CHECKING, AND WHY THE TELL WAS INNOCENT.** Every Democratic winner in
--     this state is a sitting Texas legislator we already held a record for, and every Republican
--     lost — a correlation that is exactly the shape of a winner flag landing on whichever
--     candidate the pipeline could match to an existing `politicians` row. The mundane cause is
--     candidate recruitment: Texas Democrats ran sitting legislators (Hinojosa, Goodwin, Johnson,
--     Eckhardt, Rosenthal), which is why we hold them. ▶ **The correlation is a prompt to look,
--     not a verdict** — and looking is what separated the two readings.
--
-- 🟢 **SO THE LIVE PROBE CAN BE READ BY THE NAME AGAIN.** Idaho and Connecticut were 100%
--   re-elections, which left step 9's probe readable only by the date and two gates unreachable
--   by construction. Here `P7`'s handover arm has ten rows to work on, and assertion 5 can check
--   that the *incoming* person is not yet the current holder.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THREE WINNERS WILL HOLD TWO SEATS FROM 2027-01-01, AND THE 181-SEAT RESULTS GAP IS WHY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   | winner          | takes                       | still holds          |
--   |-----------------|-----------------------------|----------------------|
--   | Nathan Johnson  | Texas Attorney General      | TX Senate District 16|
--   | Sarah Eckhardt  | Texas Comptroller           | TX Senate District 14|
--   | Jon Rosenthal   | Texas Railroad Commissioner | TX House District 135|
--
-- (CC_0515 adds two more of the same shape — Gina Hinojosa keeps TX House District 49 and Vikki
-- Goodwin TX House District 47 — so **Texas produces five in all, the most of any state in this
-- pass.** Utah produced three and Oregon one.)
--
-- ⚠ **THIS IS A VISIBLE CONSEQUENCE OF A RESULTS GAP, NOT A DEFECT THIS FILE INTRODUCES, AND IT
--   MUST NOT BE "TIDIED".** `seat_officeholder` closes the predecessor on the office being
--   *seated* and nothing else, which is the only way these files close anything. Texas holds 31
--   `STATE_UPPER` and 150 `STATE_LOWER` office rows and **zero legislative races of any year**, so
--   no later wave will seat a successor into the seats these three vacate and close them that
--   way. Closing their legislative terms here would mean either inventing a successor or
--   asserting an end date from a clause this file has not sourced — and all three of those terms
--   carry `term_start NULL`, so there is not even a tenure to reason from.
--
-- 🔴 **Utah is the precedent and Oregon is the contrast.** Doug Fiefia kept Utah House District
--   48 after taking a Senate seat because that seat's own 2026 result is missing; Oregon's
--   equivalent resolved itself because Oregon has no results gap and the vacated seat got a
--   successor in the same wave. ▶ **The difference is a result, not a rule.** The fix is the
--   Texas legislative results, not an edit here. 🟢 `P8b` gates on finding **exactly three** and
--   names them; assertion 9b asserts all three are still open afterwards.
--
-- ⚠ **Tex. Const. Art. III § 19 and the "resign to run" rules may well require these three to
--   leave the legislature**, and Art. IV § 16(b) makes the Lieutenant Governor President of the
--   Senate. This file takes no view: we hold no resignation, no effective date and no source for
--   one, and a term_end is a legal fact. **An unsourced closure is the thing this pass refuses.**
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- What this file overwrites, and the predecessor rows it is recorded against
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴 `seat_officeholder` does `UPDATE office_terms SET term_end = p_term_start - 1` on the
--    predecessor **with no `term_end IS NULL` guard**, and writes nothing to that row's `source`.
--    So the 12 new terms are recoverable by slot (`source LIKE '%CC_0514%'`) and **the 12 closures
--    are not** — undoing a declined winner means restoring a `term_end` no file recorded.
--    CLAUDE.md requires a migration that overwrites a value to record the value it overwrote, so:
--
--    **12 predecessor terms, measured 2026-11-25 — one per seat. ALL 12 carry `term_end = NULL`
--    and `how_ended = NULL`, and NONE of the 12 carries a `term_start` at all.** Each will be
--    closed at **2026-12-31** (`p_term_start - 1`) with `how_ended = 'term_expired'`. The
--    overwritten value is NULL in every case and the start values are NULL in every case, so
--    there is nothing recoverable to lose here — which is itself the finding, and P6 asserts all
--    four of those counts rather than stating them.
--
-- ⚠ **TEXAS'S EXISTING TERM ROWS CARRY NO START AT ALL** — not a tenure and not a term. Of every
--   Texas `office_terms` row across all four state tiers, exactly ONE has a non-null `term_start`:
--   the Governor's 2015-01-20, which belongs to CC_0515's wave, not this one. So this wave
--   overwrites no date anywhere and has no in-data date control of its own.
--
-- 🟢 **NO SEAT IS FLAGGED `is_vacant`, AND THAT IS NOT VACUOUS** — there are 12 offices and the
--   gate reads 0 of 12. A future-dated seating must leave the flag alone in any case (only a term
--   that has already begun clears one), so P6 would refuse rather than clear.
--
-- Ruling B: **12 of 12 rows were `called`, 0 `certified`,** when this ran. Every term's `source`
-- carries `CC_0514`, asserted in the post-verify, so a reversed canvass is recoverable by slot.

BEGIN;

CREATE TEMP TABLE cc0514_pin ON COMMIT DROP AS
SELECT 12                                 AS expect_winners,
       12                                 AS expect_offices,
       2                                  AS expect_reelections,
       10                                 AS expect_new,
       12                                 AS expect_predecessors,
       0                                  AS expect_predecessors_dated,
       3                                  AS expect_dual_seat,
       61                                 AS expect_terms_on_the_day_before,
       12                                 AS expect_called,
       '7dd2559835b91c53787ef7f3f5fa59cc' AS expect_digest,
       DATE '2027-01-01'                  AS expect_term_start,
       DATE '2026-12-31'                  AS expect_predecessor_end;

-- 🟢 NO SIBLING EXPANSION: every race is single-seat, so a winner is keyed on the office that
--    carried their own race. 🔴 AND THE GROUP IS § 601.003(c)'s OWN EXCLUSION LIST — the Governor
--    and Lieutenant Governor are excluded by the statute itself and belong to CC_0515.
-- 🔴 `is_reelection` TAKES BOTH ID CHECKS. Without `och.politician_id IS NOT NULL` the expression
--    is NULL on a holderless seat, the digest silently covers fewer rows than the counts claim,
--    and it is exactly the holderless seats it drops. All 12 are held here; P3 measures it.
CREATE TEMP TABLE cc0514_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       o.title                                           AS title,
       d.label                                           AS label,
       d.district_type                                   AS district_type,
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
   AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD_EDUCATION')
   AND w.election_date = DATE '2026-11-03'
   AND o.title NOT IN ('Texas Governor', 'Texas Lieutenant Governor');

-- 🔴 THE PREDECESSOR PRE-IMAGE. seat_officeholder closes these with an unguarded UPDATE and
--    records nothing in their source, so the only record of what they held is here.
CREATE TEMP TABLE cc0514_pre ON COMMIT DROP AS
SELECT s.office_id, t.id AS term_id, t.politician_id, t.term_start, t.term_end, t.how_ended
  FROM cc0514_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

-- 🔴🔴 THE THREE WINNERS WHO KEEP ANOTHER SEAT, captured by name so P8b and assertion 9b can
--    speak about them rather than about a count. Scoped to offices OUTSIDE this wave.
CREATE TEMP TABLE cc0514_dual ON COMMIT DROP AS
SELECT s.winner_name, s.title AS takes, t.id AS kept_term_id, t.office_id AS kept_office_id,
       d2.label AS keeps, t.term_start AS kept_start, t.term_end AS kept_end
  FROM cc0514_sel s
  JOIN essentials.office_terms t ON t.politician_id = s.politician_id
                                AND t.office_id <> s.office_id
  JOIN essentials.offices   o2 ON o2.id = t.office_id
  JOIN essentials.districts d2 ON d2.id = o2.district_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start)
   AND t.office_id NOT IN (SELECT office_id FROM cc0514_sel);

CREATE TEMP TABLE cc0514_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-01')
                                                                                   AS terms_on_the_day,
       -- 🔴 The near misses, AS TERMS. The first Monday is the day a careless reader reaches for
       -- by analogy with the four states already sitting there.
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-04')
                                                                                   AS terms_jan4,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-18')
                                                                                   AS terms_jan18,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-19')
                                                                                   AS terms_jan19,
       -- 🔴🔴 THE CLOSURE DAY IS SHARED TOO, AND THAT IS NOT OBVIOUS. 2026-12-31 is the day
       -- BEFORE 2027-01-01, so every state seating on that square closed its predecessors here:
       -- 68 terms already end on it (Utah's 50 and New Mexico's 11 among them) and NONE is Texas.
       -- A "nothing else ends on this day" assertion would therefore fire on 68 innocent rows —
       -- it did, in the first rehearsal of this file. Every count about this day is a DELTA.
       (SELECT count(*) FROM essentials.office_terms WHERE term_end = DATE '2026-12-31')
                                                                                   AS terms_ending_prev,
       (SELECT count(*) FROM essentials.office_terms t
          JOIN essentials.offices o   ON o.id = t.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE t.term_end = DATE '2026-12-31' AND lower(d.state) = 'tx')           AS terms_ending_prev_tx,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0514_pre)                                           AS predecessors,
       (SELECT count(*) FROM cc0514_dual)                                          AS dual_seat,
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
  SELECT * INTO p FROM cc0514_pin;
  SELECT * INTO b FROM cc0514_before;

  -- P1 — ⚠ ASKED ABOVE EVERY COUNT. On a second run the seats have left office_pending_winner, so
  --      a count check fires first and blames the data for what is a repeat apply.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0514%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % office_terms row(s) already cite CC_0514. Applied before.', n;
  END IF;

  -- P2 — the shape of the selection.
  SELECT count(*) INTO n FROM cc0514_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P2: selection returned % winner rows, expected %. ⚠ Group A is TWELVE — 5 '
                    'state executives and 7 State Board of Education seats. DATES.md § TX and '
                    'PICKUP.md both say "eleven" and both are wrong; if this reports 11 the '
                    'documents were right and CC_0513''s measurement was not.', n, p.expect_winners;
  END IF;
  SELECT count(DISTINCT office_id) INTO n FROM cc0514_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P2: % distinct offices, expected %.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n FROM cc0514_sel WHERE winner_count <> 1 OR COALESCE(seats, 1) <> 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the 12 races are not single-seat with exactly one winner. 🔴 THIS '
                    'SELECTION KEYS EVERY WINNER ON THE RACE-CARRYING OFFICE, so Ruling A''s '
                    'assignment to a sibling office would leave post-verify 1 unable to find the '
                    'term — after it had been written.', n;
  END IF;
  -- 🔴 The Governor and Lieutenant Governor must NOT be here. § 601.003(c) excludes them and
  --    CC_0515 seats them on a different day; one leaking in would be seated seven days early.
  SELECT count(*) INTO n
    FROM cc0514_sel WHERE title IN ('Texas Governor', 'Texas Lieutenant Governor');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % Group B office(s) reached this selection. Gov''t Code § 601.003(c) '
                    'excludes the governor and lieutenant governor BY NAME and Const. Art. IV '
                    '§§ 4 and 16(a) put them on 2027-01-19; seating them here would start their '
                    'terms eighteen days early.', n;
  END IF;

  -- P3 — 🔴🔴 THE DIGEST, AND THE COUNT OF ROWS IT ACTUALLY EVALUATED. A NULL is skipped by
  --      string_agg, so the digest can silently cover fewer rows than every count above claims.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text) INTO n
    FROM cc0514_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: the digest expression evaluated to NULL on % of % row(s), so string_agg '
                    'silently dropped them. Add och.politician_id IS NOT NULL to is_reelection.',
                    p.expect_winners - n, p.expect_winners;
  END IF;
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text)) INTO d
    FROM cc0514_sel;
  IF d <> p.expect_digest THEN
    RAISE EXCEPTION 'P3: selection digest is %, expected %. Every count above passed, so the '
                    'MEMBERSHIP moved without the size moving — a different winner, a different '
                    'office, or a re-election that became a handover. Re-derive before applying.',
                    d, p.expect_digest;
  END IF;
  SELECT count(*) INTO n FROM cc0514_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P3: % re-elections, expected % — only Tiffany Clark (Board District 13) and '
                    'Julie Pickren (Board District 7) hold the seat they just won. A re-election '
                    'is what switches p_allow_reelection on, which is what lets '
                    'seat_officeholder close the winner''s own predecessor term.',
                    n, p.expect_reelections;
  END IF;
  SELECT count(*) INTO n FROM cc0514_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P3: % handovers, expected % — ten seats change hands in this wave.',
                    n, p.expect_new;
  END IF;
  -- 🔴 THE PIN NAMES THE PEOPLE, NOT ONLY THE COUNTS. A digest proves the membership did not
  --    move; this proves the membership is the one a human read.
  SELECT count(*) INTO n
    FROM cc0514_sel s
   WHERE (s.label, s.winner_name) IN (
     VALUES ('Texas Attorney General',                     'Nathan Johnson'),
            ('Texas Comptroller',                          'Sarah Eckhardt'),
            ('Texas Land Commissioner',                    'Benjamin Flores'),
            ('Texas Agriculture Commissioner',             'Clayton Tucker'),
            ('Texas Railroad Commission',                  'Jon Rosenthal'),
            ('Texas State Board of Education District 2',  'Thomas Garcia'),
            ('Texas State Board of Education District 5',  'Allison Bush'),
            ('Texas State Board of Education District 6',  'Michelle Palmer'),
            ('Texas State Board of Education District 7',  'Julie Pickren'),
            ('Texas State Board of Education District 9',  'Kason Huddleston'),
            ('Texas State Board of Education District 13', 'Tiffany Clark'),
            ('Texas State Board of Education District 14', 'Mindy Bumgarner'));
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: only % of the 12 (office, winner) pairs match the names this file was '
                    'written against, expected %. The digest moved or a name was re-spelled.',
                    n, p.expect_winners;
  END IF;

  -- P4 — every seat carries CC_0513's date, and a basis that may seat somebody.
  SELECT count(*) INTO n
    FROM cc0514_sel WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 12 seats have no swearing-in date, or one that is not %. '
                    'CC_0513 must be applied first — it dates all 14.', n, p.expect_term_start;
  END IF;
  SELECT count(*) INTO n FROM cc0514_sel WHERE basis NOT IN ('statute', 'published');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % date(s) have a basis that is neither statute nor published. An '
                    'ESTIMATE MAY NOT SEAT ANYBODY — a term start is a legal fact.', n;
  END IF;
  -- 🔴 And it is THIS file's rule, not a day borrowed from somewhere else.
  SELECT count(*) INTO n FROM cc0514_sel WHERE rule_id <> 'tx-govt-code-601-003-january-1';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 12 seats are dated under a rule_id other than '
                    'tx-govt-code-601-003-january-1. These twelve are dated by Gov''t Code '
                    '§ 601.003(a) and nothing else.', n;
  END IF;

  -- P5 — 🔴🔴 THE 181 ABSENT LEGISLATIVE SEATS, ASKED BEFORE WRITING. § 601.003(c) names them, so
  --      this gate is the statute's own exclusion turned into a measurement.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 181 THEN
    RAISE EXCEPTION 'P5: Texas holds % legislative office rows, expected 181 (31 Senate + 150 '
                    'House). The absent body changed size, and P8b''s dual-seat argument rests '
                    'on those seats having no successor.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % Texas legislative race row(s) now exist, expected 0 of any year. If '
                    'those races have been seeded, the three dual-seat winners below may now '
                    'have successors and their seats can close properly — which changes this '
                    'file''s dual-seat argument. Re-read before applying.', n;
  END IF;

  -- P6 — the vacancy flags and the predecessor pre-image.
  SELECT count(*) INTO n
    FROM cc0514_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % of the 12 offices are flagged is_vacant. A FUTURE-dated seating does '
                    'not clear the flag — only a term that has already begun does — so a flagged '
                    'seat must be handled deliberately, not swept along.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0514_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) captured, expected % — one per seat. A seat with '
                    'two covering terms, or none, is not a seat this file can close cleanly.',
                    n, p.expect_predecessors;
  END IF;
  SELECT count(*) INTO n FROM cc0514_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a term_end. seat_officeholder''s '
                    'UPDATE has NO term_end IS NULL guard, so it would overwrite a real end date '
                    'and record nothing of what it replaced.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0514_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a how_ended.', n;
  END IF;
  -- ⚠ ALL TWELVE ARE UNDATED, which is unusual and is pinned rather than assumed: Texas's ONLY
  --   dated state term is the Governor's 2015-01-20, and that belongs to CC_0515.
  SELECT count(*) INTO n FROM cc0514_pre WHERE term_start IS NOT NULL;
  IF n <> p.expect_predecessors_dated THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) carry a term_start, expected % — every Texas term '
                    'row in these two bodies is undated, so this wave overwrites no date at all. '
                    'If one is now dated, record what it held before closing it.',
                    n, p.expect_predecessors_dated;
  END IF;
  -- The two re-elections must have the winner as their own predecessor; the ten handovers must not.
  SELECT count(*) INTO n
    FROM cc0514_sel s JOIN cc0514_pre r ON r.office_id = s.office_id
   WHERE s.is_reelection AND r.politician_id IS DISTINCT FROM s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) marked as a re-election have a predecessor who is not the '
                    'winner. p_allow_reelection would be switched on for a handover.', n;
  END IF;
  SELECT count(*) INTO n
    FROM cc0514_sel s JOIN cc0514_pre r ON r.office_id = s.office_id
   WHERE NOT s.is_reelection AND r.politician_id IS NOT DISTINCT FROM s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) marked as a handover have the winner as their own '
                    'predecessor. p_allow_reelection would be OFF for a re-election and '
                    'seat_officeholder would refuse.', n;
  END IF;

  -- P7 — Ruling B: the certainty is recorded, not assumed.
  SELECT count(*) INTO n FROM cc0514_sel WHERE certainty <> 'called';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % of the 12 results are no longer "called". If Texas has certified, the '
                    'header''s 12-of-12-called claim is stale and must be restated before this '
                    'runs.', n;
  END IF;

  -- P8 — nobody is about to hold two of THIS wave's offices.
  SELECT count(*) INTO n
    FROM (SELECT politician_id FROM cc0514_sel GROUP BY politician_id HAVING count(*) > 1) x;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: % winner(s) appear on more than one office in this wave.', n;
  END IF;

  -- P8b — 🔴🔴 THE THREE WHO KEEP A SEAT OUTSIDE THIS WAVE. Gated on exactly three and NAMED, so
  --       a fourth is caught rather than absorbed. ▶ Not tidied: see the header.
  SELECT count(*) INTO n FROM cc0514_dual;
  IF n <> p.expect_dual_seat THEN
    RAISE EXCEPTION 'P8b: % term(s) outside this wave are held by one of its winners, expected % '
                    '— Nathan Johnson (TX Senate District 16), Sarah Eckhardt (TX Senate District '
                    '14) and Jon Rosenthal (TX House District 135), each of whom will hold two '
                    'seats from %. Those three seats have NO 2026 result and no successor, so '
                    'nothing closes them; that is a consequence of Texas''s 181-seat legislative '
                    'results gap and this file does not tidy it. A fourth means a winner holds '
                    'something nobody has read.',
                    n, p.expect_dual_seat, p.expect_term_start;
  END IF;
  SELECT count(*) INTO n
    FROM cc0514_dual
   WHERE (winner_name, keeps) IN (VALUES ('Nathan Johnson', 'TX Senate District 16'),
                                         ('Sarah Eckhardt', 'TX Senate District 14'),
                                         ('Jon Rosenthal',  'TX House District 135'));
  IF n <> p.expect_dual_seat THEN
    RAISE EXCEPTION 'P8b: only % of the % dual-seat rows are the ones this file names, expected '
                    'all of them. A different person keeps a different seat — read the row.',
                    n, p.expect_dual_seat;
  END IF;

  -- P9 — 🔴🔴 2027-01-01 IS A SHARED DAY, SO EVERY COUNT ABOUT IT IS A DELTA NAMING THE OTHERS.
  IF b.terms_on_the_day <> p.expect_terms_on_the_day_before THEN
    RAISE EXCEPTION 'P9: % term(s) already begin on %, expected % (Utah 50 under '
                    'ut-const-art6-first-day-january, New Mexico 11 under two rule_ids). The '
                    'delta below is measured against this, so a third state arriving must move '
                    'this number rather than hide inside it.',
                    b.terms_on_the_day, p.expect_term_start, p.expect_terms_on_the_day_before;
  END IF;
  -- 🔴 The near misses as TERMS. ⚠ 2027-01-19 is Group B's day and must still be EMPTY here —
  --    CC_0515 has not run, and this file must not reach it.
  IF b.terms_jan4 <> 229 OR b.terms_jan18 <> 13 OR b.terms_jan19 <> 0 THEN
    RAISE EXCEPTION 'P9: a near-miss day moved — 2027-01-04 carries % term(s) (expected 229: '
                    'Wisconsin, Arizona, California, Idaho), 2027-01-18 % (expected 13: '
                    'Alabama), 2027-01-19 % (expected 0: Group B''s day, which CC_0515 fills). '
                    'These are the days a misread of § 601.003 or Art. IV § 4 lands on.',
                    b.terms_jan4, b.terms_jan18, b.terms_jan19;
  END IF;

  -- P10 — the drift baseline before, so assertion 10 can prove it did not move.
  IF b.missing_unflagged <> 238 THEN
    RAISE EXCEPTION 'P10: the unflagged drift baseline reads % before this file, expected 238. '
                    '🔴 NEVER RAISE THIS BASELINE — if it has moved, find out why before adding '
                    'to it.', b.missing_unflagged;
  END IF;
END $$;

-- 🔴 THE INCUMBENCY GUARD'S SCOPE IS A UNION OF WINNERS AND PREDECESSORS. ⚠ Here those two sets
--    are almost disjoint — only the two re-elected Board members are in both — so the union is 22
--    people, not 12. Stated rather than left to be noticed.
CREATE TEMP TABLE cc0514_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0514_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0514_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0514_guarded);

DO $$
DECLARE s record; v_seated int := 0;
BEGIN
  FOR s IN SELECT * FROM cc0514_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => s.office_id,
      p_politician_id    => s.politician_id,
      p_term_start       => s.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran. Term begins '
                         || to_char(s.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in: "The regular term of an elective '
                         || 'state, district, county, or precinct office begins on January 1 of '
                         || 'the year following the general election for state and county '
                         || 'officers" (Tex. Gov''t Code § 601.003(a)). TERM, NOT OATH, AND THE '
                         || 'STATUTE SAYS SO ITSELF: § 601.003(b) separately has the officer '
                         || 'qualify "on, or as soon as possible after, January 1", placing the '
                         || 'qualification AFTER the term start. The section carries NO ESCAPE '
                         || 'HATCH and neither does any of the ten sections of ch. 601 — the only '
                         || '"unless / except as / otherwise provided" phrases in the chapter are '
                         || 'in § 601.008 (payment of a claim) and § 601.009 (registered-voter '
                         || 'requirement), neither touching a commencement. Subsection (c) is '
                         || 'itself evidence the section governs this seat: it names the only '
                         || 'four offices it does not reach — governor, lieutenant governor, '
                         || 'state senator, state representative — and the first two of those are '
                         || 'seated on 2027-01-19 under Const. Art. IV §§ 4 and 16(a) by their own '
                         || 'file. (🔴 THAT FILE''S SLOT IS DELIBERATELY NOT NAMED IN THIS COLUMN: '
                         || 'Ruling B recovers a wave with source LIKE ''%<slot>%'', so naming a '
                         || 'sibling slot here would make these 12 rows answer to ITS query. It '
                         || 'did — the first chain rehearsal aborted at that file''s P1 with "12 '
                         || 'office_terms rows already cite" it. Cross-references belong in the '
                         || 'header, not in the data.) For the seven '
                         || 'State Board of Education seats, Tex. Educ. Code § 7.104(a) '
                         || 'corroborates the same boundary (eight members'' terms expiring on '
                         || 'January 1 of one odd-numbered year and SEVEN the next) and closes '
                         || 'the arithmetic: 7 of our 15 Board rows were pending, which is the '
                         || 'cohort § 7.104(a) describes. ⚠ DATES.md cites that as § 7.103, '
                         || 'which is ELIGIBILITY FOR MEMBERSHIP and names no date. '
                         || CASE WHEN s.is_reelection
                                 THEN 'RE-ELECTED INCUMBENT: the predecessor on this seat is the '
                                   || 'winner, and their own undated term is closed at '
                                   || to_char(s.term_start - 1, 'YYYY-MM-DD') || '. '
                                 ELSE 'HANDOVER: this seat changes hands. Ten of this wave''s '
                                   || 'twelve do, and the predecessor''s undated term is closed '
                                   || 'at ' || to_char(s.term_start - 1, 'YYYY-MM-DD') || '. '
                            END
                         || '🔴 THE RESULT WAS RE-READ FROM AP''S OWN FEED ON 2026-11-25 BEFORE '
                         || 'THIS WAS WRITTEN, because a statewide sweep is also the shape of a '
                         || 'broken winner flag: AP''s national file reproduces this state''s '
                         || 'calls, Texas''s 36 U.S. House races came back MIXED, and our own '
                         || '2026 STATE_EXEC winners nationally split 64 Democratic / 34 '
                         || 'Republican — so the sweep is a measurement and not an artefact. '
                         || '🔴 181 TEXAS LEGISLATIVE OFFICE ROWS CARRY ZERO RACES OF ANY YEAR, '
                         || 'and § 601.003(c) excludes those seats by name, so this day must not '
                         || 'leak onto them; they need their own rule_id when seeded. CC_0514',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => s.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0514: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0514_guarded;
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
  SELECT * INTO b FROM cc0514_before;
  SELECT * INTO p FROM cc0514_pin;

  -- 1. Twelve terms exist, on the offices this file selected, for the people it selected.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0514_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated term(s) on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. The read path answers for all twelve.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0514_sel s ON s.office_id = nx.office_id
   WHERE nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seat(s).', n, p.expect_offices;
  END IF;

  -- 3. 🔴🔴 THE DELTA ON A SHARED DAY, AND EVERY ROW ON IT MUST BELONG TO A NAMED RULE.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n - b.terms_on_the_day <> p.expect_offices THEN
    RAISE EXCEPTION '3: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_start = p.expect_term_start AND lower(d.state) NOT IN ('tx', 'ut', 'nm');
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % term(s) on % belong to a state other than Texas, Utah or New Mexico. '
                    'THREE states share this calendar day under unrelated instruments, so a '
                    'fourth must be caught rather than absorbed into the count.',
                    n, p.expect_term_start;
  END IF;
  -- 3b. No Texas term on this day outside this wave's twelve offices.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_start = p.expect_term_start AND lower(d.state) = 'tx'
     AND t.office_id NOT IN (SELECT office_id FROM cc0514_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION '3b: % Texas term(s) begin on % outside this wave''s twelve offices. The most '
                    'likely source is a sibling Railroad Commissioner row — the Commission is '
                    'STAGGERED and only one of its three seats was elected.', n, p.expect_term_start;
  END IF;
  -- 3c. 🔴 And none of the twelve landed on a wrong day.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0514_sel s ON s.office_id = t.office_id
   WHERE t.term_start IN (DATE '2027-01-04', DATE '2027-01-18', DATE '2027-01-19',
                          DATE '2027-01-12', DATE '2027-01-05');
  IF n <> 0 THEN
    RAISE EXCEPTION '3c: % of this wave''s term(s) start on a wrong day — the first Monday '
                    '2027-01-04 (229 terms: Wisconsin, Arizona, California, Idaho), the third '
                    'Monday 2027-01-18 (13: Alabama), Group B''s 2027-01-19, the convening day '
                    '2027-01-12 or the first Tuesday 2027-01-05.', n;
  END IF;
  -- 3d. The near-miss days did not move.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = DATE '2027-01-04';
  IF n <> b.terms_jan4 THEN
    RAISE EXCEPTION '3d: 2027-01-04 went % -> %, expected no change from this file.',
                    b.terms_jan4, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = DATE '2027-01-18';
  IF n <> b.terms_jan18 THEN
    RAISE EXCEPTION '3d: 2027-01-18 (Alabama) went % -> %, expected no change from this file.',
                    b.terms_jan18, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = DATE '2027-01-19';
  IF n <> 0 THEN
    RAISE EXCEPTION '3d: 2027-01-19 carries % term(s), expected 0 — that is Group B''s day and '
                    'CC_0515 fills it. This file must not have reached it.', n;
  END IF;

  -- 4. 🔴 A FUTURE-DATED TERM MUST NOT MOVE THE CURRENT-HOLDER MAP. Nationwide digest.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text)) INTO m
    FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not '
                    'change who holds a seat TODAY.', b.holders_md5, m;
  END IF;

  -- 5. 🟢 THE TEN HANDOVERS STILL ANSWER WITH THE OUTGOING PERSON, AND THIS GATE IS REACHABLE
  --    HERE WHERE IT WAS NOT IN IDAHO OR CONNECTICUT. Greg Abbott's appointees and the five
  --    outgoing Board members hold their seats until 2026-12-31.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0514_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of the 12 seats still answer office_current_holder with the person who '
                    'held them before this file, expected %.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0514_sel s ON s.office_id = och.office_id
   WHERE NOT s.is_reelection AND och.politician_id = s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % incoming winner(s) already answer as the CURRENT holder of a seat they '
                    'do not take until %. ⚠ This arm was unreachable in Idaho and Connecticut, '
                    'where every seat was a re-election; ten handovers make it real.',
                    n, p.expect_term_start;
  END IF;

  -- 6. The predecessors closed exactly where they were meant to, and nothing else moved.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0514_pre r ON r.term_id = t.id
   WHERE t.term_end = p.expect_predecessor_end AND t.how_ended = 'term_expired';
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at % with how_ended term_expired, expected % '
                    '— the exact rows named in the pre-image.',
                    n, p.expect_predecessor_end, p.expect_predecessors;
  END IF;
  -- 6b. 🔴 seat_officeholder writes nothing to a closed row's source, so a moved term_start would
  --     be unrecoverable. All twelve were NULL and must still be.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0514_pre r ON r.term_id = t.id
   WHERE t.term_start IS DISTINCT FROM r.term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '6b: % closed predecessor term(s) had their term_start moved. All twelve were '
                    'NULL before this file and nothing here writes a start to a predecessor.', n;
  END IF;
  -- 6c. 🔴🔴 NO TERM CLOSED ANYWHERE ELSE — AS A DELTA, BECAUSE THE CLOSURE DAY IS SHARED.
  --     2026-12-31 is the day before 2027-01-01, so Utah's and New Mexico's seatings closed their
  --     own predecessors on it: 68 terms already ended here and NONE was Texas. The first
  --     rehearsal of this file asserted a TOTAL of zero and fired on all 68 — a gate reporting
  --     real rows as a fault, which is the shared-square lesson reaching a column nobody thinks
  --     of as a date. Two arms now: the delta, and the Texas scope.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_end = p.expect_predecessor_end;
  IF n - b.terms_ending_prev <> p.expect_predecessors THEN
    RAISE EXCEPTION '6c: terms ending on % went % -> %, a delta of %, expected % — one closure per '
                    'seat this file filled. ⚠ That day is SHARED: % term(s) already ended on it '
                    'before this file (Utah and New Mexico closed their predecessors there), so '
                    'this is a delta and never a total.',
                    p.expect_predecessor_end, b.terms_ending_prev, n, n - b.terms_ending_prev,
                    p.expect_predecessors, b.terms_ending_prev;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_end = p.expect_predecessor_end AND lower(d.state) = 'tx'
     AND t.id NOT IN (SELECT term_id FROM cc0514_pre);
  IF n <> 0 THEN
    RAISE EXCEPTION '6c: % TEXAS term(s) outside the pre-image also end on %. Texas had % such '
                    'row(s) before this file, so every one on that day must be a predecessor '
                    'this file named. seat_officeholder closes only the predecessor of the seat '
                    'it fills; something else closed a term.',
                    n, p.expect_predecessor_end, b.terms_ending_prev_tx;
  END IF;

  -- 7. Every new term carries the slot, so Ruling B's recovery path works.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0514_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0514%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '7: % of % new term(s) carry CC_0514 in their source. A canvass reversal is '
                    'recovered with source LIKE ''%%CC_0514%%'', not from memory.',
                    n, p.expect_offices;
  END IF;

  -- 7b. 🔴🔴 AND THIS FILE'S ROWS MUST NOT ANSWER TO ANOTHER WAVE'S SLOT QUERY. Ruling B recovers
  --     a wave with `source LIKE '%<slot>%'`, so a sibling slot mentioned anywhere in this
  --     column makes these rows impersonate that wave. **This is not hypothetical**: the first
  --     chain rehearsal of these three files aborted at the next file's P1 reporting "12
  --     office_terms row(s) already cite CC_0515", because this file's narrative explained what
  --     that file does and named it. The prose was correct and the column was poisoned.
  --     ▶ A cross-reference belongs in the header, never in a recovery key.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0514_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start
     AND (t.source LIKE '%CC_0515%' OR t.source LIKE '%CC_0513%');
  IF n <> 0 THEN
    RAISE EXCEPTION '7b: % of this wave''s term(s) name ANOTHER migration''s slot in their '
                    'source. Ruling B recovers a wave with source LIKE ''%%<slot>%%'', so these '
                    'rows would be returned as that wave''s. Describe the sibling file in the '
                    'header instead of in the data.', n;
  END IF;

  -- 8. No person and no office was created or destroyed. This wave has no people file.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %. This wave has no people file — all 12 '
                    'winners already existed, were active, and collided with nobody on either '
                    'name key.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %.', b.offices, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '8: flagged-vacant offices moved from % to %. A FUTURE-dated seating does not '
                    'clear a vacancy flag.', b.vacant_all, n;
  END IF;

  -- 9. Nobody holds two of this wave's seats from the handover day.
  SELECT count(*) INTO n
    FROM (SELECT t.politician_id
            FROM essentials.office_terms t
           WHERE (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
             AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start)
             AND t.office_id IN (SELECT office_id FROM cc0514_sel)
           GROUP BY t.politician_id HAVING count(*) > 1) x;
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % person/people hold more than one of THIS wave''s offices covering %.',
                    n, p.expect_term_start;
  END IF;
  -- 9b. 🔴🔴 AND THE THREE DUAL-SEAT TERMS ARE STILL OPEN, WHICH IS THE CORRECT OUTCOME.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0514_dual x ON x.kept_term_id = t.id
   WHERE t.term_end IS NULL AND t.how_ended IS NULL;
  IF n <> p.expect_dual_seat THEN
    RAISE EXCEPTION '9b: % of the % legislative term(s) kept by a winner of this wave are still '
                    'open, expected all of them. Nathan Johnson, Sarah Eckhardt and Jon Rosenthal '
                    'each hold two seats from %, because the seats they leave have NO 2026 result '
                    'and therefore no successor to close them. 🔴 THAT IS NOT TIDIED HERE: '
                    'closing them would mean inventing a successor or asserting an end date from '
                    'a clause nobody sourced. The fix is the Texas legislative results.',
                    n, p.expect_dual_seat, p.expect_term_start;
  END IF;

  -- 10. 🔴 THE DRIFT BASELINE IS UNMOVED. NEVER RAISE IT.
  SELECT count(*) INTO n
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id
   WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '10: the unflagged drift baseline moved from % to %. 🔴 NEVER RAISE THIS '
                    'BASELINE — this file seats 12 offices that already had terms, so it must '
                    'not move at all.', b.missing_unflagged, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> b.missing_all THEN
    RAISE EXCEPTION '10: total drift moved from % to %.', b.missing_all, n;
  END IF;

  -- 11. The 181 absent legislative seats were not touched.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER')
     AND (t.term_start = p.expect_term_start OR t.source LIKE '%CC_0514%');
  IF n <> 0 THEN
    RAISE EXCEPTION '11: % Texas legislative term(s) now start on % or cite this file. Those 181 '
                    'seats are EXCLUDED from § 601.003 by subsection (c) and this file must not '
                    'have reached them.', n, p.expect_term_start;
  END IF;

  RAISE NOTICE 'CC_0514 OK — 12 Texas seats scheduled for %: % re-elections (Tiffany Clark, '
               'Board District 13; Julie Pickren, Board District 7) and % handovers, all % '
               'called. Predecessors: % terms closed at % with how_ended term_expired, ALL '
               'TWELVE previously undated and with a NULL term_end, so no date was overwritten '
               'anywhere. 🔴🔴 TEN SEATS CHANGE HANDS AND THE RESULT WAS RE-READ FROM AP''S OWN '
               'FEED ON 2026-11-25 BEFORE THIS WAS WRITTEN — a statewide sweep is also the shape '
               'of a winner flag landing on whichever candidate could be matched to an existing '
               'politicians row, and every Democratic winner here is a sitting Texas legislator '
               'we already held. What refuted it: AP reproduces the calls, Texas''s 36 U.S. House '
               'races came back MIXED, our 2026 STATE_EXEC winners nationally split 64 Democratic '
               '/ 34 Republican, and AP''s winner candidateID differs from AP''s own incumbent '
               'with no surname match. 🔴🔴 THREE WINNERS NOW HOLD TWO SEATS FROM % — Nathan '
               'Johnson (TX Senate District 16), Sarah Eckhardt (TX Senate District 14) and Jon '
               'Rosenthal (TX House District 135) — because Texas holds 181 legislative office '
               'rows and ZERO races of any year, so the seats they leave get no successor and '
               'nothing closes them. That is a visible consequence of a results gap, NOT a defect '
               'this file introduces, and assertion 9b asserts all three are still OPEN rather '
               'than tidying them; the fix is the Texas legislative results. CC_0515 adds two '
               'more of the same shape, making five in all — the most of any state in this pass. '
               '🟢 Texas is the THIRD state on % (Utah 50, New Mexico 11) and every row on the '
               'day was asserted to belong to one of those three states. The current-holder map '
               'is unchanged, the unflagged drift baseline is still %, and 2027-01-19 is still '
               'empty for CC_0515.',
               p.expect_term_start, p.expect_reelections, p.expect_new, p.expect_called,
               p.expect_predecessors, p.expect_predecessor_end, p.expect_term_start,
               p.expect_term_start, b.missing_unflagged;
END $$;

COMMIT;
