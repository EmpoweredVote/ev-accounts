-- CC_0503 — Idaho: the start date for the 7 state executive offices won on 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE FIRST MONDAY IN JANUARY — 2027-01-04
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-04  Governor · Lieutenant Governor · Secretary of State · State Controller ·
--               Treasurer · Attorney General · Superintendent of Public
--               Instruction                                      (7)  Idaho Const. Art. IV, § 1
--
-- ONE provision, ONE day, ONE body — the shortest state in this pass. Sourced 2026-11-23 and
-- re-read 2026-11-24; the write-up is in backend/data/state-seating-2026/DATES.md § ID. This file
-- writes the dates and seats nobody: CC_0504 seats.
--
-- 🟢 **NO PEOPLE FILE AND NO RULING A.** All 7 winner rows already carry a politician_id, and all
--   7 races are single-seat with one winner. ⚠ **AND ALL SEVEN ARE RE-ELECTIONS** — Little,
--   Bedke, McGrane, Woolf, Ellsworth, Labrador, Critchfield — which is a first in this pass and has
--   a consequence for step 9: **a re-election renders the same whether this wave ran or not**, so
--   the live probe must read the DATE, never the name. CC_0504's header says how.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE AUTHORITY — ONE SENTENCE THAT DOES THREE JOBS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Idaho Const. Art. IV, § 1** — *Executive officers listed — Term of office — Place of
-- residence — Duties*:
--
--     "The executive department shall consist of a governor, lieutenant governor, secretary of
--      state, state controller, state treasurer, attorney general and superintendent of public
--      instruction, each of whom shall hold his office for four years BEGINNING ON THE FIRST
--      MONDAY IN JANUARY next after his election, commencing with those elected in the year 1946,
--      except as otherwise provided in this Constitution."
--
--   1. **It names exactly our seven offices, in our order, with no eighth and no omission.** Our
--      `Treasurer` is its `state treasurer`; everything else matches on the word. Checked first,
--      because Arkansas is the state where three provisions named three different memberships.
--   2. **It fixes the day by FORMULA, not by choice.** 🔴 That is the distinction Georgia turned
--      on: `O.C.G.A. § 45-12-2` lets the legislature *appoint* a day inside a week, so an agreeing
--      row there proves nothing. Idaho leaves nothing to appoint, so its agreeing rows count.
--   3. **It states the cycle, and the cycle checks out.** "Commencing with those elected in the
--      year 1946" — 2026 − 1946 = 80, divisible by four. 🟢 So the instrument that dates the body
--      also confirms **all seven were up in 2026**, which is this file's own count of 7.
--
-- The first Monday in January 2027 is **2027-01-04**: 2027-01-01 is a Friday. Computed in
-- assertion 3a, never typed.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 "EXCEPT AS OTHERWISE PROVIDED IN THIS CONSTITUTION" — DISCHARGING THAT CLAUSE WAS THE WORK
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- A residual that excepts itself is the Texas `§ 601.003(c)` shape and the Arkansas `Schedule
-- § 20` shape, and in both of those the exception is where the state got hard. ▶ So the whole
-- constitution was listed by section title — **21 articles, 227 sections** — and read for anything
-- that could give one of these seven a different start. **Two candidates existed. Both are dead.**
--
--   `Art. III § 25` *Oath of office* — binds **"the members of the legislature"** and nobody else,
--     and the oath it prescribes swears the taker to "the duties of senator (or representative)".
--     🔴 **The Idaho Constitution contains no oath provision for executive officers at all.**
--   `Art. XXI § 13` *Tenure of office* — "All officers elected **at said election** shall hold
--     their offices until the legislature shall provide by law … for the election of their
--     successors". 🔴 Art. XXI is Idaho's **Schedule**: § 5 continues the officers "now holding
--     their offices … in this territory", § 7 is "when Constitution takes effect", § 14 is
--     "convention of first legislature". Transitional, 1890.
--
-- 🟢 **The second is the Arkansas lesson firing one state later, and it fired correctly.**
--   Arkansas's `Schedule § 20` reads as a standing residual and is not one; Idaho's `Art. XXI § 13`
--   reads the same way and is not one either. **Both were caught by reading the sections AROUND
--   them rather than the section alone.** ▶ A state's "Schedule" is its commissioning clause until
--   its own neighbours say otherwise.
--
-- ⚠ **THE SWEEP THAT PROVED THIS HAD A BROKEN FIRST PASS, AND A PRE-SET CONTROL CAUGHT IT.** The
--   title extractor was off by one line: it printed `Art.I SECTION 1 :: SECTION 2` for every row
--   and a search for `TERM` across all 227 sections returned **nothing**. The control was set in
--   advance — *`Art.IV SECTION 1`'s title must contain "TERM OF OFFICE"*, because that one had
--   already been read by hand — and it failed, so the sweep was rebuilt rather than believed.
--   🔴 **A clean "no competing provision found" is exactly what a broken scanner returns**, and on
--   this state that answer was the whole deliverable.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢🟢 THE CONTROL — TWO AGREEING ROWS, AND A THIRD THAT LOOKS LIKE A CONTROL AND IS A TRAP
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Idaho holds three dated state-executive terms, written by different migrations from different
-- sources. Measured 2026-11-24:
--
--   office                        term_start    month   first Monday of that January   agrees?
--   Governor (Little)             2019-01-07      1     2019-01-07                     ✅
--   Superintendent (Critchfield)  2023-01-02      1     2023-01-02                     ✅
--   State Controller (Woolf)      2012-10-15     10     2012-01-02                     🔴 NO
--
-- 🔴🔴 **ALL THREE ARE MONDAYS.** A check shaped "are Idaho's executive term starts Mondays?"
--   passes on all three and proves nothing — and worse, it silently admits a **mid-term
--   appointment** as evidence for the elected-term formula. Woolf's row is honest about itself:
--   its own `source` note calls it *"a mid-term arrival rather than a first-Monday-in-January one,
--   so how_started is appointed"*. ▶ **THE DISCRIMINATING FIELD IS THE MONTH, NOT THE WEEKDAY.**
--   This is `CLAUDE.md`'s *a predicate reads the shape of a value, never what the value is*, on a
--   date — and the only reason it did not become a third agreeing control is that the row was read
--   instead of counted. Assertion 3d runs both tests and requires the weekday one to pass on all
--   three while the month one admits exactly two: **the weak control is watched passing, in the
--   file, beside the strong one.**
--
-- ⚠ **Two controls is not many**, and four of the seven offices carry no `office_terms` date at all
--   (Secretary of State, Treasurer, Attorney General, Lieutenant Governor — all the ADR 0002
--   phase-2 backfill with `start_precision = 'unknown'`). The two that exist were written by
--   different migrations from different sources, which is what makes them independent of each
--   other rather than one fact counted twice.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THREE OF THIS WAVE'S FOUR CANDIDATE DAYS ARE NAMED BY IDAHO'S OWN CONSTITUTION
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Measured 2026-11-24, before this file:
--
--   2026-12-01  🔴 **IDAHO'S OWN LEGISLATIVE TERM START** — Art. III § 3, below. 289 rows already
--               carry it (Maine's 183 and California's 106 locals), and Idaho's own 105
--               legislative seats belong on it.
--   2026-12-03  the first Thursday of December — **Idaho's ORGANIZATIONAL SESSION**, Art. III § 8.
--   2027-01-01  January 1st — **Utah's** rule, 50 live rows. Nothing in Idaho law names it.
--   2027-01-04  the FIRST Monday — Art. IV § 1, **this file**. 234 rows already here.
--   2027-01-11  the SECOND Monday — 🔴🔴 **IDAHO'S OWN REGULAR SESSION CONVENING DAY**, Art. III
--               § 8: *"commencing on the second Monday of January of each year"* — AND the term
--               start of 118 Washington seats (RCW 44.04.021) and 75 Oregon seats (Or. Const. Art.
--               IV § 4). **193 rows already on that day.**
--
-- 🔴 **So reaching one week past the right answer in Idaho produces this state's own convening
--   date, which 193 seats elsewhere already use as a TERM start.** That is verbatim Arizona
--   (CC_0497), whose Art. IV, Pt. 2 § 3 is also a second Monday — **the third state in this pass
--   where the term and the convening differ, and the second where the near miss is the convening.**
--   Assertion 3b computes all four days and refuses the three this file is not about.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 2027-01-04 IS ALREADY THREE STATES, SO EVERY COUNT HERE IS A DELTA
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **234 rows already carry 2027-01-04**, under seven rule_ids:
--
--   az  94   az-const-first-monday-january
--   wi 123   wi-legislature-first-monday (116), wi-state-exec-first-monday (5),
--            wi-county-sheriff-59-20-2-b (1), wi-county-clerk-circuit-59-20-2-bm (1)
--   ca  17   ca-const-art2-s20-monday-after-january-1 (7), ca-const-vi-16c (4),
--            ca-water-principal-act (6)
--
-- 🔴 **IDAHO IS THE FOURTH STATE ON THIS DAY, AND TWO OF THE OTHER THREE CALL THEIR RULE A FIRST
--   MONDAY TOO** — Wisconsin in its `rule_id` and Arizona in its name. A gate asking "how many
--   seats start on the first Monday of January 2027?" would read **241** after this file and call
--   it success. ▶ P6 pins the before-image at 234, assertion 4 asserts the delta is exactly 7, and
--   every row on the day must belong to a **NAMED** rule_id — so a fifth state is caught rather
--   than absorbed. Washington and Oregon paid for the absorbing version on 2027-01-11 and Arizona
--   on this very day.
--
-- ⚠ **AND CALIFORNIA'S RULE IS NOT THE SAME RULE EVEN THOUGH IT AGREES THIS CYCLE**: "the Monday
--   after January 1" is a week away from "the first Monday in January" whenever January 1 is a
--   Monday. It is a coincidence of calendars, not a shared rule.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE URGENT FINDING: IDAHO'S LEGISLATURE EXISTS, IS SEEDED, AND HAS NO 2026 RESULTS — AND
--      ITS TERMS BEGIN ON 2026-12-01, SEVEN DAYS FROM THIS FILE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Idaho Const. Art. III § 3** — *Term of office*, quoted in full because it is one sentence:
--
--     "The senators and representatives shall be elected for the term of two years, FROM AND AFTER
--      THE FIRST DAY OF DECEMBER next following the general election."
--
-- Measured 2026-11-24: Idaho holds **35 `STATE_UPPER` and 70 `STATE_LOWER` office rows, every one
-- held and every one carrying a dated term — and ZERO 2026 race rows between them.**
--
-- 🔴 **A TWO-YEAR TERM PUTS ALL 105 ON THE 2026 BALLOT AS A MATTER OF LAW**, so this is not a
--   staggered chamber hiding half a cycle: all 105 are *certainly* missing data. It is Utah's
--   third class — **no race row at all**, not an unrecorded result — at 105 seats.
--
-- 🔴🔴 **AND IT IS DIFFERENT FROM ALABAMA'S IN THE WAY THAT MATTERS.** `CC_0501` found 140 Alabama
--   legislative offices that **do not exist**, on a day that had **already passed**. Idaho's 105
--   offices **do** exist, are held, and their day is **2026-12-01 — seven days away.** Our own data
--   already records the rule at day precision across five cycles: 2012-12-01, 2014-12-01,
--   2018-12-01, 2020-12-01, **2022-12-01 (51 rows)** and **2024-12-01 (21 rows)**. So the rule is
--   corroborated and the results are the only thing missing. ▶ **RESULTS PROGRAMME, WITH A DATED
--   DEADLINE.** This file does not invent a race; P4 gates on the gap staying exactly as described.
--
-- ⚠ **READ THE PREPOSITION BEFORE WRITING THAT DATE.** § 3 says *"from and after the first day of
--   December"*, which is not plainly "on December 1st" — "after the first day" reads as the 2nd.
--   Our 72 seeded rows say December 1 and they come from **Ballotpedia's "assumed office"**, not
--   from this clause; `CC_0310`'s own source note calls 2024-12-01 "the constitutional term start
--   (Idaho Const. Art. III sec. 3)", which is an inference it did not cite. 🔴 **So the seeded day
--   may be one day early, and nothing in our data would show it** — this is Maine's preposition
--   trap (*"the day next preceding"*) in the opposite direction. ▶ **Whoever dates those 105 seats
--   must settle the preposition from a second document before writing it**, and must not take this
--   file's 2027-01-04 for any of them: the executives and the legislature are two bodies under two
--   articles with two different days.
--
-- ⚠ **Idaho's 9 COUNTY and 7 LOCAL offices also carry no 2026 race**, and REGISTER.md records an
--   expectation that **Ada County is scheduled for 2027-01-11**. Measured here: Idaho holds **no
--   `office_swearing_in` row and no `office_terms` row on 2027-01-11 at all**, so that expectation
--   is not yet backed by a single Idaho row. Recorded so a later gate is not written against it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SOURCE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   https://legislature.idaho.gov/statutesrules/idconst/ArtIV/Sect1/   Art. IV § 1 — the 7 and the day
--   https://legislature.idaho.gov/statutesrules/idconst/ArtIII/Sect3/  Art. III § 3 — the LEGISLATURE
--   https://legislature.idaho.gov/statutesrules/idconst/ArtIII/Sect8/  Art. III § 8 — the SESSIONS
--   https://legislature.idaho.gov/statutesrules/idconst/ArtIII/Sect25/ Art. III § 25 — the oath
--   https://legislature.idaho.gov/statutesrules/idconst/ArtXXI/Sect13/ Art. XXI § 13 — the Schedule
--
-- The Idaho Legislature's own publication of the Constitution of the State of Idaho, read
-- 2026-11-23 and Art. IV § 1, Art. III § 3 and Art. III § 8 re-read 2026-11-24.
--
-- 🟢 **`legislature.idaho.gov` SERVES THE WHOLE CONSTITUTION TO PLAIN `curl`** — no browser, no
--   headers beyond the ordinary set. Art. IV § 1 answers HTTP 200 at 81,059 bytes with the section
--   text in it, confirmed by a positive control: the body contains the phrase "first Monday in
--   January next after his election, commencing with those elected in the year 1946". After
--   Georgia, Arkansas and Alabama this is the first state in several where the law was simply
--   readable. ⚠ **The per-article index is `/Art<ROMAN>` with NO trailing slash** and carries the
--   section TITLES, which is what made a 227-section sweep 21 fetches instead of 227 — `CLAUDE.md`'s
--   *take a document's parts from its own table of contents*.
--
-- ⚠ **NO IDAHO CHAMBER CARRIES AN `inauguration_rules` ROW**, so there was no lead to check and
--   nothing to contradict. Recorded because the recipe says a rule row earns its way in by its own
--   citation — an absent row is cleaner than a bad one. (Alabama's cited a real section and
--   checked out; three California executives named no authority at all.)
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Term start or oath? — **TERM START**
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Art. IV § 1 says the officer "shall hold his office for four years **beginning on** the first
-- Monday in January" — a calendar date attaching to the office, with no qualification condition
-- anywhere in the sentence, and **no executive oath clause in the constitution to compete with
-- it** (Art. III § 25 binds legislators only). 🔴 **So Idaho is the opposite of Nevada**, where
-- Art. 5 § 2 runs the term "from the time of his installation" and NRS 282.010(4) makes
-- installation mean qualification — there the oath IS the term start. Here it is a separate event
-- and must not be rendered as one.
--
-- basis: `statute` for all 7 rows — constitutional, not statutory-by-delegation.
-- rule_id: `id-const-art4-s1-first-monday-january`.

BEGIN;

-- ── The selection: every office this wave will DATE. ──────────────────────────────────────────
--
-- 🟢 ONE PROVISION, SO ONE GROUP AND NO SIBLING EXPANSION. Art. IV § 1 names all seven offices in
--    one sentence, every race is single-seat, and each office is taken by its own row. The seven
--    titles are listed explicitly and P2 asserts the selection is the WHOLE pending set, because a
--    named list silently drops an eighth office and nothing errors.
CREATE TEMP TABLE cc0503_sel ON COMMIT DROP AS
SELECT o.id            AS office_id,
       o.title         AS title,
       d.district_type AS district_type
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'id'
   AND d.district_type = 'STATE_EXEC'
   AND w.election_date = DATE '2026-11-03'
   AND o.title IN ('Governor', 'Lieutenant Governor', 'Secretary of State', 'State Controller',
                   'Treasurer', 'Attorney General', 'Superintendent of Public Instruction');

CREATE TEMP TABLE cc0503_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in)                        AS rows_all,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'id' AND s.election_date = DATE '2026-11-03')      AS rows_id,
       -- 🔴🔴 IDAHO IS THE FOURTH STATE ON THIS DAY and two of the other three call their rule a
       -- first Monday too. The before-image is pinned so assertion 4 is a delta, never a total.
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-04')                               AS rows_jan4,
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-11')                               AS rows_jan11,
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-01')                               AS rows_jan1,
       (SELECT count(*) FROM essentials.office_pending_winner w
          JOIN essentials.offices o   ON o.id = w.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'id' AND w.election_date = DATE '2026-11-03'
           AND d.district_type <> 'STATE_EXEC')                                    AS pending_outside;

DO $$
DECLARE n bigint; b record;
BEGIN
  SELECT * INTO b FROM cc0503_before;

  -- P0 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE EVERY COUNT. It writes no
  -- term, so on a second run all 7 seats are still pending and every P1 check below would pass;
  -- the operator would be told the data moved when what happened is that they ran it twice.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0503_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P0: % of the 7 already carry a swearing-in row for this election. This file '
                    'would overwrite a date it has not recorded.', n;
  END IF;

  -- P1 — the body, and the constitution's own membership. 🟢 Art. IV § 1 names exactly seven
  -- offices, so "7" is the instrument's number and not ours.
  SELECT count(*) INTO n FROM cc0503_sel;
  IF n <> 7 THEN
    RAISE EXCEPTION 'P1: % Idaho executive seats are reachable from a 2026 race, expected 7 — the '
                    'exact membership Art. IV § 1 names (governor, lieutenant governor, secretary '
                    'of state, state controller, state treasurer, attorney general and '
                    'superintendent of public instruction). The data moved under this file.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'id' AND d.district_type = 'STATE_EXEC';
  IF n <> 7 THEN
    RAISE EXCEPTION 'P1: Idaho holds % STATE_EXEC office rows, expected 7. Art. IV § 1 lists the '
                    'executive department exhaustively, so an eighth row is a seat nobody has '
                    'sourced and a missing one is a seat nobody can seat.', n;
  END IF;

  -- P2 — ⚠ AND THE SELECTION IS THE WHOLE PENDING SET. The WHERE clause names seven titles
  -- explicitly, so an eighth pending executive would be silently dropped and nothing would error.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'id' AND w.election_date = DATE '2026-11-03'
     AND o.id NOT IN (SELECT office_id FROM cc0503_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % pending Idaho seat(s) did not reach this file''s selection. Art. IV § 1 '
                    'dates the seven it names and nothing else; a seat outside them is a body '
                    'nobody has sourced, not a row to add to the list.', n;
  END IF;
  IF b.pending_outside <> 0 THEN
    RAISE EXCEPTION 'P2: % Idaho pending seat(s) now sit outside STATE_EXEC, expected 0. 🔴 THEY DO '
                    'NOT TAKE THIS FILE''S DATE — the legislature''s terms begin under Art. III '
                    '§ 3 "from and after the first day of December", and the counties and cities '
                    'have their own rules. Read this file''s header before dating them.',
      b.pending_outside;
  END IF;

  -- P3 — every selected race is SINGLE-SEAT with exactly one winner, which is what makes "no
  -- Ruling A" a measurement rather than an assumption. ⚠ AND ALL SEVEN ARE RE-ELECTIONS, which is
  -- counted here so CC_0504's probe guidance rests on a number rather than on a recollection.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0503_sel c ON c.office_id = w.office_id
   WHERE w.election_date = DATE '2026-11-03'
     AND (w.winner_count <> 1 OR w.seats IS DISTINCT FROM 1);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % of the 7 races are not single-seat with exactly one winner. Ruling A '
                    'would then apply and the SIBLING offices receiving the extra winners would '
                    'need dating too — Maryland dated 178 offices against 114 races and Arizona '
                    '94 against 65 for exactly this reason.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN cc0503_sel c ON c.office_id = w.office_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = c.office_id
   WHERE w.election_date = DATE '2026-11-03'
     AND och.politician_id IS NOT NULL
     AND och.politician_id::text = (w.winners -> 0 ->> 'id');
  IF n <> 7 THEN
    RAISE EXCEPTION 'P3: % of the 7 winners are the sitting holder of the seat they won, expected '
                    '7 — Idaho returned its ENTIRE executive department. If this has fallen, a '
                    'seat changes hands and CC_0504''s header is wrong about what its live probe '
                    'can see.', n;
  END IF;

  -- P4 — 🔴🔴 THE LEGISLATURE: 105 SEEDED OFFICES, ZERO 2026 RACES, AND A DIFFERENT DAY SEVEN DAYS
  -- AWAY. Art. III § 3 elects senators and representatives "for the term of two years, from and
  -- after the first day of December next following the general election", so all 105 were on this
  -- ballot as a matter of law. Gated here so that a race arriving, or an office vanishing, stops
  -- this file rather than being absorbed into it.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'id' AND d.district_type = 'STATE_UPPER';
  IF n <> 35 THEN
    RAISE EXCEPTION 'P4: Idaho holds % Senate office rows, expected 35.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'id' AND d.district_type = 'STATE_LOWER';
  IF n <> 70 THEN
    RAISE EXCEPTION 'P4: Idaho holds % House office rows, expected 70.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'id' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % Idaho legislative 2026 race row(s) now exist, expected 0 when this file '
                    'was written. 🔴 THEY DO NOT TAKE THIS FILE''S DATE: Art. III § 3 commences a '
                    'senator''s or representative''s term "from and after the first day of '
                    'December next following the general election" — 2026-12-01 or 2026-12-02, '
                    'and the preposition is NOT settled. Read this file''s header before dating '
                    'them.', n;
  END IF;
  -- 🟢 AND THE RULE THOSE 105 SEATS WILL NEED IS ALREADY CORROBORATED IN OUR OWN DATA, which is
  -- what makes the gap a results gap rather than a sourcing one. 2022-12-01 and 2024-12-01 are the
  -- two most recent cycles.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'id' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER')
     AND t.term_start IN (DATE '2022-12-01', DATE '2024-12-01');
  IF n <> 72 THEN
    RAISE EXCEPTION 'P4: % Idaho legislative terms begin on 2022-12-01 or 2024-12-01, expected 72 '
                    '(51 + 21, measured 2026-11-24). Those rows are the corroboration for Art. III '
                    '§ 3 and the reason the 105-seat gap is a RESULTS gap rather than a sourcing '
                    'one. ⚠ They come from Ballotpedia''s "assumed office" and not from the '
                    'clause, so they do not settle whether the day is the 1st or the 2nd.', n;
  END IF;

  -- P5 — 🔴 THE DAY'S BEFORE-IMAGE, AND THE TWO NEAR MISSES THAT ARE LIVE ELSEWHERE.
  IF b.rows_jan4 <> 234 THEN
    RAISE EXCEPTION 'P5: % row(s) already carry 2027-01-04, expected 234 (Arizona 94 under '
                    'az-const-first-monday-january, Wisconsin 123 under four wi-* rules, '
                    'California 17 under three ca-* rules). Idaho is the FOURTH state on this day '
                    'and two of the other three call their rule a first Monday too — a fifth has '
                    'landed since this file was written, and its rule_id must be named before '
                    'adding 7 to the pile.', b.rows_jan4;
  END IF;
  IF b.rows_jan11 <> 193 OR b.rows_jan1 <> 50 THEN
    RAISE EXCEPTION 'P5: the near-miss days have moved — 2027-01-11 (the SECOND Monday, which is '
                    'IDAHO''S OWN regular session convening day under Art. III § 8) carries % '
                    'rows, expected 193 (Washington 118, Oregon 75), and 2027-01-01 (Utah''s rule) '
                    'carries %, expected 50. They are pinned because reaching one week past '
                    'Idaho''s answer produces this state''s own convening date, which 193 seats '
                    'elsewhere already use as a term start.', b.rows_jan11, b.rows_jan1;
  END IF;
  -- 🔴 And Idaho holds NOTHING on 2027-01-11 itself, although REGISTER.md records an expectation
  -- that Ada County is scheduled for it. Pinned so no later gate is written against a row that
  -- does not exist.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'id' AND s.swearing_in_date = DATE '2027-01-11';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % Idaho row(s) now carry 2027-01-11. REGISTER.md expects Ada County on '
                    'that day and no Idaho row backed it when this file was written; a row that '
                    'has appeared needs reading, because that day is also this state''s session '
                    'convening date and the term start of 193 seats elsewhere.', n;
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-04',
       'statute',
       'id-const-art4-s1-first-monday-january',
       'Idaho Const. Art. IV, § 1 — "The executive department shall consist of a governor, '
         || 'lieutenant governor, secretary of state, state controller, state treasurer, attorney '
         || 'general and superintendent of public instruction, each of whom shall hold his office '
         || 'for four years BEGINNING ON THE FIRST MONDAY IN JANUARY next after his election, '
         || 'commencing with those elected in the year 1946, except as otherwise provided in this '
         || 'Constitution." The first Monday in January 2027 is 2027-01-04, because 2027-01-01 is '
         || 'a Friday. 🟢 ONE SENTENCE DOES THREE JOBS: it names exactly these seven offices with '
         || 'no eighth and no omission; it fixes the day by FORMULA rather than by choice (unlike '
         || 'Georgia, where O.C.G.A. § 45-12-2 lets the legislature APPOINT a day inside a week, '
         || 'so an agreeing row proves nothing); and it states the cycle — 2026 − 1946 = 80, '
         || 'divisible by four — so the instrument that dates the body also confirms all seven '
         || 'were up in 2026. 🔴 "EXCEPT AS OTHERWISE PROVIDED IN THIS CONSTITUTION" WAS '
         || 'DISCHARGED BY READING THE WHOLE INSTRUMENT: 21 articles, 227 sections, listed by '
         || 'section title. Two candidates existed and both are dead — Art. III § 25 (Oath of '
         || 'office) binds "the members of the legislature" and nobody else, and the Idaho '
         || 'Constitution has NO executive oath clause at all; Art. XXI § 13 (Tenure of office) '
         || 'reads as a standing residual but Art. XXI is the 1890 SCHEDULE, whose neighbours are '
         || '"when Constitution takes effect" and "convention of first legislature". 🔴 TERM, NOT '
         || 'OATH: the clause says "beginning on" a calendar day with no qualification condition, '
         || 'and with no executive oath provision to compete with it — the opposite of Nevada, '
         || 'where Art. 5 § 2 runs the term from installation and NRS 282.010(4) makes '
         || 'installation mean qualification. 🔴 AND THIS DAY IS NOT THE WHOLE STATE''S: Art. III '
         || '§ 3 elects senators and representatives "for the term of two years, from and after '
         || 'the first day of December next following the general election", and Art. III § 8 '
         || 'convenes the legislature on the SECOND Monday of January — 2027-01-11, a week later, '
         || 'and the term start of 193 Washington and Oregon seats.',
       'https://legislature.idaho.gov/statutesrules/idconst/ArtIV/Sect1/ — the Idaho '
         || 'Legislature''s own publication of the Constitution of the State of Idaho, read '
         || '2026-11-23 and re-read 2026-11-24 at HTTP 200, 81,059 bytes, with a positive control: '
         || 'the body contains the phrase "first Monday in January next after his election, '
         || 'commencing with those elected in the year 1946". 🟢 THE SITE SERVES THE WHOLE '
         || 'CONSTITUTION TO PLAIN curl — no browser and no headers beyond the ordinary set, which '
         || 'after Georgia, Arkansas and Alabama made this the first readable state in several. '
         || '⚠ The per-article index is /Art<ROMAN> with NO trailing slash and carries the section '
         || 'TITLES, which is what made the 227-section sweep 21 fetches instead of 227. 🔴 THAT '
         || 'SWEEP''S FIRST PASS WAS BROKEN AND A PRE-SET CONTROL CAUGHT IT: the title extractor '
         || 'was off by one line, printed "Art.I SECTION 1 :: SECTION 2" for every row, and a '
         || 'search for TERM across all 227 sections returned NOTHING. The control — Art.IV '
         || 'SECTION 1''s title must contain "TERM OF OFFICE", because that one had been read by '
         || 'hand — failed, so the sweep was rebuilt rather than believed. A clean "no competing '
         || 'provision found" is exactly what a broken scanner returns. 🟢🟢 CORROBORATED BY TWO '
         || 'INDEPENDENT ROWS IN OUR OWN DATA, written by different migrations from different '
         || 'sources: Brad Little''s Governor term begins 2019-01-07 and Debbie Critchfield''s '
         || 'Superintendent term 2023-01-02, and each IS the first Monday of its own January. '
         || '🔴 A THIRD DATED ROW LOOKS LIKE A THIRD CONTROL AND IS A TRAP: Brandon D. Woolf''s '
         || 'State Controller term begins 2012-10-15, which is ALSO A MONDAY — so a check shaped '
         || '"are these Mondays?" passes on all three and silently admits a MID-TERM APPOINTMENT '
         || 'as evidence for the elected-term formula. THE DISCRIMINATING FIELD IS THE MONTH, NOT '
         || 'THE WEEKDAY. ⚠ NO IDAHO CHAMBER CARRIES AN inauguration_rules ROW, so there was no '
         || 'lead to check and nothing to contradict.',
       '🔴🔴 THREE OF THIS WAVE''S FOUR CANDIDATE DAYS ARE NAMED BY IDAHO''S OWN CONSTITUTION, AND '
         || 'TWO OF THEM ARE LIVE SOMEWHERE. 2026-12-01 is IDAHO''S OWN LEGISLATIVE TERM START '
         || '(Art. III § 3) and already carries 289 rows from Maine and California; 2026-12-03 is '
         || 'Idaho''s ORGANIZATIONAL SESSION (Art. III § 8); 2027-01-04 is the FIRST Monday and is '
         || 'this file; 2027-01-11 is the SECOND Monday — IDAHO''S OWN REGULAR SESSION CONVENING '
         || 'DAY under Art. III § 8 AND the term start of 118 Washington seats (RCW 44.04.021) and '
         || '75 Oregon seats. 2027-01-01, January 1st, is UTAH''s rule with 50 live rows and is '
         || 'named by nothing in Idaho. Reaching one week past the right answer here produces this '
         || 'state''s own convening date, which 193 seats elsewhere use as a TERM start — verbatim '
         || 'Arizona, whose Art. IV Pt. 2 § 3 is also a second Monday. '
         || '🔴🔴 IDAHO IS THE FOURTH STATE ON 2027-01-04 AND TWO OF THE OTHER THREE CALL THEIR '
         || 'RULE A FIRST MONDAY TOO. 234 rows were already here — Arizona 94, Wisconsin 123, '
         || 'California 17 — so a gate reading the total would see 241 and call it success. Every '
         || 'count about this day is a DELTA that names the other states'' rule_ids. ⚠ And '
         || 'California''s "Monday after January 1" is not the same rule even though it agrees this '
         || 'cycle: the two differ by a week whenever January 1 is a Monday. '
         || '🔴🔴 THE URGENT FINDING IS A BODY THIS FILE DOES NOT TOUCH. Idaho holds 35 Senate and '
         || '70 House office rows, every one held and every one carrying a dated term, and ZERO '
         || '2026 race rows between them. Art. III § 3 gives every member a TWO-YEAR term, so all '
         || '105 were on this ballot as a matter of law and all 105 are certainly missing data — '
         || 'Utah''s "no race row at all" class, at 105 seats. ⚠ UNLIKE ALABAMA''S 140 MISSING '
         || 'OFFICES, THESE EXIST AND THEIR DAY HAS NOT PASSED: Art. III § 3 commences them "from '
         || 'and after the first day of December", which is 2026-12-01 or 2026-12-02 — SEVEN DAYS '
         || 'AFTER THIS FILE WAS WRITTEN. Our own data corroborates the rule across five cycles '
         || '(72 rows on 2022-12-01 and 2024-12-01 alone), so the results are the only thing '
         || 'missing. ⚠ READ THE PREPOSITION: "from and after the first day" is not plainly "on '
         || 'the first day", our seeded rows say December 1 on Ballotpedia''s "assumed office" '
         || 'rather than on the clause, and nothing in our data would show the day being one '
         || 'early. This is Maine''s preposition trap in the opposite direction. '
         || '⚠ Idaho''s 9 COUNTY and 7 LOCAL offices also carry no 2026 race, and REGISTER.md '
         || 'records an expectation that Ada County is scheduled for 2027-01-11 — measured here, '
         || 'Idaho holds NO row of any kind on that day, so that expectation is not yet backed by '
         || 'a single Idaho row. '
         || '⚠ ALL SEVEN WINNERS ARE RE-ELECTIONS, which is a first in this pass and means a live '
         || 'probe of an Idaho address CANNOT be read by the incoming NAME — only by the incoming '
         || 'DATE. Written by CC_0503.'
  FROM cc0503_sel c;

DO $$
DECLARE n bigint; b record;
        jan1 date; first_mon date; second_mon date; dec1 date; dec_thu date;
        ctl record; c_month bigint := 0; c_weekday bigint := 0; c_rows bigint := 0;
        id_day    CONSTANT date := DATE '2027-01-04';  -- the first Monday, this file
        id_second CONSTANT date := DATE '2027-01-11';  -- Idaho's SESSION, and WA + OR terms
        id_jan1   CONSTANT date := DATE '2027-01-01';  -- Utah's rule
        id_dec1   CONSTANT date := DATE '2026-12-01';  -- Idaho's own LEGISLATIVE term start
BEGIN
  SELECT * INTO b FROM cc0503_before;

  -- 1. All 7 carry the one date.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0503_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = id_day;
  IF n <> 7 THEN
    RAISE EXCEPTION '1: % of 7 seats carry %.', n, id_day;
  END IF;

  -- 2. Exactly one distinct date was written. ⚠ One provision really does mean one date here —
  --    which is NOT the default: Massachusetts' Amend. Art. LXIV § 1 is a single sentence-group
  --    naming three days a fortnight apart.
  SELECT count(DISTINCT s.swearing_in_date) INTO n
    FROM essentials.office_swearing_in s JOIN cc0503_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 1 THEN
    RAISE EXCEPTION '2: % distinct swearing-in dates were written, expected exactly 1.', n;
  END IF;

  -- 3a. 🔴 THE CLAUSE EVALUATED AS WRITTEN — the day is COMPUTED and never typed. ISODOW: Mon = 1.
  jan1       := make_date(EXTRACT(YEAR FROM DATE '2026-11-03')::int + 1, 1, 1);
  first_mon  := jan1 + ((1 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);
  second_mon := first_mon + 7;
  dec1       := make_date(EXTRACT(YEAR FROM DATE '2026-11-03')::int, 12, 1);
  dec_thu    := dec1 + ((4 - EXTRACT(ISODOW FROM dec1)::int + 7) % 7);
  IF EXTRACT(ISODOW FROM first_mon)::int <> 1 THEN
    RAISE EXCEPTION '3a: % is not a Monday. Every comparison below proves nothing while this is '
                    'wrong.', first_mon;
  END IF;
  IF first_mon <> id_day THEN
    RAISE EXCEPTION '3a: the first Monday of January following 2026-11-03 computes as %, not %.',
      first_mon, id_day;
  END IF;
  -- 🟢 The clause's own cycle, checked: "commencing with those elected in the year 1946".
  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 1946) % 4 <> 0 THEN
    RAISE EXCEPTION '3a: 2026 is not on Art. IV § 1''s four-year cycle from 1946, so the clause '
                    'does not put these seven offices on this ballot at all.';
  END IF;

  -- 3b. 🔴🔴 THE THREE WRONG DAYS COMPUTED BESIDE THE RIGHT ONE, AND TWO ARE IDAHO'S OWN.
  IF second_mon <> id_second OR jan1 <> id_jan1 OR dec1 <> id_dec1 THEN
    RAISE EXCEPTION '3b: the near-miss arithmetic is broken — second Monday %, January 1st %, '
                    'December 1st %. Expected %, % and %.',
      second_mon, jan1, dec1, id_second, id_jan1, id_dec1;
  END IF;
  IF EXTRACT(ISODOW FROM dec_thu)::int <> 4 OR dec_thu <> DATE '2026-12-03' THEN
    RAISE EXCEPTION '3b: the first Thursday of December 2026 computes as % and is not 2026-12-03, '
                    'so Art. III § 8''s organizational-session day is mis-derived.', dec_thu;
  END IF;
  IF first_mon IN (second_mon, jan1, dec1, dec_thu) THEN
    RAISE EXCEPTION '3b: the candidate days are not distinct (% / % / % / % / %), so the '
                    'comparison below cannot discriminate.',
      first_mon, second_mon, jan1, dec1, dec_thu;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0503_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.swearing_in_date IN (second_mon, jan1, dec1, dec_thu);
  IF n <> 0 THEN
    RAISE EXCEPTION '3b: % Idaho executive seat(s) carry one of the three wrong days — % (the '
                    'SECOND Monday, which is IDAHO''S OWN regular session convening day under '
                    'Art. III § 8 and the term start of 193 Washington and Oregon seats), % '
                    '(January 1st, UTAH''s rule, 50 live rows), % (December 1st, IDAHO''S OWN '
                    'LEGISLATIVE term start under Art. III § 3) or % (the first Thursday of '
                    'December, Idaho''s organizational session).',
      n, second_mon, jan1, dec1, dec_thu;
  END IF;

  -- 3c. 🔴 AND NO IDAHO OFFICE OUTSIDE THIS SELECTION WAS DATED FOR THIS ELECTION, except the
  --     three federal rows the federal programme put on 2027-01-03.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'id' AND s.election_date = DATE '2026-11-03'
     AND s.office_id NOT IN (SELECT office_id FROM cc0503_sel)
     AND NOT (dd.district_type IN ('NATIONAL_LOWER', 'NATIONAL_UPPER')
              AND s.swearing_in_date = DATE '2027-01-03'
              AND s.rule_id = 'us-const-amend-xx-1');
  IF n <> 0 THEN
    RAISE EXCEPTION '3c: % Idaho row(s) for this election are neither one of this file''s 7 nor '
                    'one of the 3 federal rows (2 NATIONAL_LOWER + 1 NATIONAL_UPPER, 2027-01-03, '
                    'us-const-amend-xx-1).', n;
  END IF;

  -- 3d. 🔴🔴 THE RULE RUN OVER IDAHO'S OWN DATED TERMS — WITH THE WEAK CONTROL WATCHED PASSING
  --     BESIDE THE STRONG ONE. All three dated executive rows are MONDAYS, so a weekday test
  --     admits all three, and the third is a mid-term APPOINTMENT in OCTOBER. The month is the
  --     discriminating field; the weekday is the trap. Both are computed here, and the file
  --     requires the weak test to pass on 3 and the strong test on exactly 2 — if the weekday
  --     test ever stopped admitting all three, this control would have stopped demonstrating the
  --     trap it exists to record.
  FOR ctl IN
    SELECT t.term_start, o.title, p.full_name,
           make_date(EXTRACT(YEAR FROM t.term_start)::int, 1, 1)
             + ((1 - EXTRACT(ISODOW FROM make_date(EXTRACT(YEAR FROM t.term_start)::int, 1, 1))::int
                 + 7) % 7) AS first_monday_that_jan
      FROM essentials.office_terms t
      JOIN essentials.offices o    ON o.id = t.office_id
      JOIN essentials.districts dd ON dd.id = o.district_id
      LEFT JOIN essentials.politicians p ON p.id = t.politician_id
     WHERE lower(dd.state) = 'id' AND dd.district_type = 'STATE_EXEC'
       AND t.term_start IS NOT NULL AND t.start_precision = 'day'
     ORDER BY t.term_start
  LOOP
    c_rows := c_rows + 1;
    IF EXTRACT(ISODOW FROM ctl.term_start)::int = 1 THEN c_weekday := c_weekday + 1; END IF;
    IF ctl.term_start = ctl.first_monday_that_jan THEN c_month := c_month + 1; END IF;
    RAISE NOTICE '3d: % (%, %) — month %, first Monday of that January %; weekday test %, '
                 'first-Monday test %.',
      ctl.term_start, ctl.title, coalesce(ctl.full_name, '(unnamed)'),
      EXTRACT(MONTH FROM ctl.term_start)::int, ctl.first_monday_that_jan,
      CASE WHEN EXTRACT(ISODOW FROM ctl.term_start)::int = 1 THEN 'PASS' ELSE 'fail' END,
      CASE WHEN ctl.term_start = ctl.first_monday_that_jan THEN 'PASS' ELSE 'fail' END;
  END LOOP;
  IF c_rows <> 3 THEN
    RAISE EXCEPTION '3d: % dated Idaho executive term(s), expected 3 (Little 2019-01-07, '
                    'Critchfield 2023-01-02, Woolf 2012-10-15). This control has lost or gained a '
                    'fixture and proves nothing until it is re-read.', c_rows;
  END IF;
  IF c_weekday <> 3 THEN
    RAISE EXCEPTION '3d: the WEAK control no longer admits all three rows (% of 3 are Mondays). It '
                    'is kept precisely because it passes on a mid-term appointment — if it has '
                    'stopped doing so, this control no longer demonstrates the trap it records.',
      c_weekday;
  END IF;
  IF c_month <> 2 THEN
    RAISE EXCEPTION '3d: % of the 3 dated Idaho executive terms equal the first Monday of their '
                    'own January, expected exactly 2 — Brad Little''s 2019-01-07 and Debbie '
                    'Critchfield''s 2023-01-02. The third, Brandon D. Woolf''s 2012-10-15, is a '
                    'MID-TERM APPOINTMENT in OCTOBER and is a Monday, which is why the weekday '
                    'test above admits it and this one must not.', c_month;
  END IF;

  -- 3e. 🔴🔴 THE LEGISLATURE IS STILL UNRACED, AND ITS DAY IS STILL SEVEN DAYS OUT. Pinned after
  --     the write so the next reader finds this file's header rather than re-deriving Art. III § 3.
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'id' AND dd.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION '3e: % Idaho legislative 2026 race row(s) exist. All 105 seats were on the '
                    'ballot under Art. III § 3''s two-year term and none of them takes this '
                    'file''s date.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'id' AND dd.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION '3e: % Idaho legislative seat(s) now carry a swearing-in row. Art. III § 3 '
                    'gives them "the term of two years, from and after the first day of December '
                    'next following the general election" — 2026-12-01 or 2026-12-02, and the '
                    'PREPOSITION IS NOT SETTLED. Not this file''s 2027-01-04.', n;
  END IF;

  -- 4. 🔴 THE 2027-01-04 DELTA, NAMED. Idaho is the fourth state on this day.
  SELECT count(*) INTO n FROM essentials.office_swearing_in WHERE swearing_in_date = id_day;
  IF n <> b.rows_jan4 + 7 THEN
    RAISE EXCEPTION '4: rows on % went % -> %, a delta of %, expected 7.',
      id_day, b.rows_jan4, n, n - b.rows_jan4;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE s.swearing_in_date = id_day
     AND NOT (lower(dd.state) = 'id' AND s.rule_id = 'id-const-art4-s1-first-monday-january')
     AND s.rule_id NOT IN ('az-const-first-monday-january',
                           'wi-legislature-first-monday', 'wi-state-exec-first-monday',
                           'wi-county-sheriff-59-20-2-b', 'wi-county-clerk-circuit-59-20-2-bm',
                           'ca-const-art2-s20-monday-after-january-1', 'ca-const-vi-16c',
                           'ca-water-principal-act');
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % row(s) on % belong to a rule this file does not know. A date shared by '
                    'four states is a coincidence of calendars, never a shared rule — name the '
                    'new one before absorbing it.', n, id_day;
  END IF;

  -- 5. Idaho rows for this election moved by exactly 7.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'id' AND s.election_date = DATE '2026-11-03';
  IF n <> b.rows_id + 7 THEN
    RAISE EXCEPTION '5: Idaho rows for this election went % -> %, a delta of %, expected 7.',
      b.rows_id, n, n - b.rows_id;
  END IF;

  -- 6. Repo-wide, exactly 7 rows were added — no other state was swept in.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 7 THEN
    RAISE EXCEPTION '6: office_swearing_in went % -> %, a delta of %, expected 7.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 7. Every one of the 7 reads back as an Idaho row under this rule, with basis statute, citing
  --    Art. IV § 1. ⚠ ONE rule_id and ONE provision here, so unlike Alabama and Arizona there is
  --    no per-group authority split to count — but the citation is still asserted, because a
  --    citation can be right about the date and wrong about the law and no count can see it.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN cc0503_sel c            ON c.office_id = s.office_id
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE s.election_date = DATE '2026-11-03'
     AND lower(dd.state) = 'id'
     AND s.basis = 'statute'
     AND s.rule_id = 'id-const-art4-s1-first-monday-january'
     AND s.authority LIKE 'Idaho Const. Art. IV, § 1 %';
  IF n <> 7 THEN
    RAISE EXCEPTION '7: % of 7 rows read back as an Idaho row with basis statute under '
                    'id-const-art4-s1-first-monday-january citing Art. IV, § 1.', n;
  END IF;
  -- 7b. ⚠ AND NO ROW IS DATED ON A CLAUSE FOR A BODY IT DOES NOT BELONG TO. Art. III § 3 and § 8
  --     are quoted inside the authority as WARNINGS about the legislature; neither may be the
  --     citation a seat is dated ON.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0503_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.authority LIKE 'Idaho Const. Art. III%';
  IF n <> 0 THEN
    RAISE EXCEPTION '7b: % row(s) are dated ON Art. III. § 3 is the LEGISLATURE''s term (December) '
                    'and § 8 is the SESSIONS clause (the second Monday); neither dates any of '
                    'these seven offices.', n;
  END IF;

  -- 8. No term was written. CC_0504 seats.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0503_sel c ON c.office_id = t.office_id
   WHERE t.term_start = id_day;
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % term(s) were written. This file records dates and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0503 OK: 7 Idaho state executives dated % — THE FIRST MONDAY IN JANUARY, from '
               'ONE provision that does three jobs: Idaho Const. Art. IV § 1 names exactly these '
               'seven offices, fixes the day by formula rather than by choice, and states the '
               'cycle (2026 − 1946 = 80, divisible by four). Its "except as otherwise provided in '
               'this Constitution" was discharged by reading all 21 articles and 227 sections: two '
               'candidates existed and both are dead. The day was COMPUTED, and all three wrong '
               'days computed beside it — % (the SECOND Monday, IDAHO''S OWN session convening day '
               'under Art. III § 8 and the term start of 193 Washington and Oregon seats), % '
               '(January 1st, Utah''s rule) and % (December 1st, IDAHO''S OWN LEGISLATIVE term '
               'start under Art. III § 3). 🟢 The rule was run over Idaho''s own dated executive '
               'terms with the WEAK control watched passing beside the strong one: all 3 are '
               'Mondays and only 2 are the first Monday of their own January, the third being a '
               'mid-term appointment in OCTOBER. Idaho is the FOURTH state on this calendar day '
               '(234 rows were already here, Arizona 94, Wisconsin 123, California 17), so every '
               'count is a delta that names the other rules. 🔴🔴 AND THE URGENT FINDING IS A BODY '
               'THIS FILE DOES NOT TOUCH: Idaho holds 35 Senate and 70 House office rows, all '
               'held, all dated, and ZERO 2026 races — all 105 were on the ballot under Art. III '
               '§ 3''s two-year term, and their terms begin "from and after the first day of '
               'December", SEVEN DAYS from now. ⚠ The preposition is not settled and the seeded '
               'December 1 may be one day early.',
    id_day, id_second, id_jan1, id_dec1;
END $$;

COMMIT;
