-- CC_0498 — Arizona: seat the 93 winners of 2026-11-03 for 2027-01-04.
--
-- Second of two. CC_0497 writes the dates (94 offices, the first Monday in January, from three
-- separate provisions); this file writes the terms. **There is no people file**: all 96 Arizona
-- winner rows already carry a politician_id, measured 2026-11-24 before anything was written.
-- Nevada needed 1 of 13, Maine 18 of 77, Maryland 25 of 85 — Arizona needs none, and that was
-- swept for rather than read off the register's "no record" column, which counts race rows.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THIS IS THE SECOND RULING A WAVE, AND THE SELECTION IS BUILT ON THE **ASSIGNED** OFFICE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Every one of Arizona's 29 pending House contests carries two winners** — 58 winners across
-- 29 office rows, a higher proportion than Maryland's 38 of 67 — because a multi-seat race
-- attaches ALL its winners to ONE office row, so the winner-to-seat mapping is not in the data.
-- REGISTER.md's **Ruling A** decides it:
--
--   • **The eligible set** is not "the district's offices" but the offices that could receive
--     THIS race's winners: same `district_id`, same `chamber_id`, same `title` as the race's own
--     office. A Senate district row and a House district row are separate rows in this schema,
--     each holding only its own chamber's offices.
--   • **A winner who already holds one of the eligible offices is seated into THAT office.**
--     54 of the 93 anchor this way.
--   • **The remaining winners fill the remaining eligible offices in `office_id` order**, in
--     ballot-name order — and only under the gate below. 24 of the 39 handovers are such fills;
--     the other 15 are single-seat races that need no ruling at all.
--   • **The gate, per race:** every eligible office must share `seats`, `voting_powers` and
--     `representation_note`, none may carry a `description` that distinguishes it, **and the
--     count of eligible offices must EQUAL the number of winners.** P2 asserts all of it, and
--     it runs ABOVE the pin — see below.
--
-- 🔴🔴 **ARIZONA IS THE STATE THE EQUALITY CLAUSE WAS WRITTEN FOR, AND THE BODY IT REFUSES IS
--   IN THIS VERY SELECTION'S REACH.** The Corporation Commission has five office rows, one
--   district, all titled `Commissioner`, `seats` / `description` / `representation_note` NULL on
--   every one and one distinct `voting_powers` — so every interchangeability clause PASSES. The
--   2026 race carries two winners, **Clara Pratte and Jonathon Hill, neither of whom holds any
--   of the five**. Under the superseded "at least" clause 5 ≥ 2 passed, nothing anchored, and
--   the rule fell through to "fill the remaining eligible offices" where all five were
--   remaining. **There are ten ways to choose two of five and one of them is right** — two
--   sitting commissioners with two to six years left would have been closed out on our pages
--   while the two actually leaving stayed. ▶ It is excluded from this file's selection, and
--   **P2g measures the refusal rather than asserting it by name**: it computes the eligible
--   count and the winner count for the excluded race and refuses to proceed unless they still
--   disagree. A refusal that is only a comment is a refusal nobody can check.
--
-- 🔴 **`scripts/lib/seating-wave.mjs`'s `WAVE_SELECTION_SQL` KEYS EVERY WINNER ON THE
--   RACE-CARRYING OFFICE AND IS WRONG FOR THIS WAVE.** Post-verify 1 joins `office_terms` back
--   to the selection on `office_id`; with the published selection it would look for 29 terms
--   that were never written, and would do so **after** the write.
--
-- ⚠ **WHAT MAKES AN ARBITRARY FILL HONEST HERE, MEASURED.** Across all 60 Arizona House office
--   rows: `seats` non-null 0, `description` non-null 0, `representation_note` non-null 0, one
--   distinct `voting_powers`, one distinct `title`. The two seats of a district carry no
--   separate public identity, so assigning a winner to one rather than the other makes no claim
--   a voter could see as wrong. Only `title` and `chamber_id` discriminate anything; the other
--   three clauses are insurance against a future row, not checks that have ever fired.
--
-- 🟢 **AND THE STRUCTURE WAS CHECKED AGAINST THE CONSTITUTION, NOT AGAINST ITSELF.** Art. IV,
--   Pt. 2, § 1(1): "The senate shall be composed of one member elected from each of the thirty
--   legislative districts … The house of representatives shall be composed of two members
--   elected from each of the thirty legislative districts." 30 + 60 = 90, and our office rows
--   hold exactly that. A district holding three House offices would let a fill claim a seat
--   nobody elected, so that count is part of the gate (P2f).
--
-- 🔴🔴 **RULING A RUNS AS `P2`, ABOVE THE PIN.** Maryland's suite proved why: written below the
--   pin, every tamper aimed at the equality clause is caught two gates earlier by the digest or
--   the row counts, so the clause that carries the real-world cost — *a named sitting official
--   unseated in favour of somebody who did not win their seat* — has no control of its own.
--   Ruling A asks whether the body is **assignable at all**, which is a fact about the world;
--   the pin asks whether the answer is **the one recorded on 2026-11-24**, which is a fact about
--   this file. The first question comes first.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE PIN — CAPTURED BY REHEARSING `CC_0497 + A PROBE` IN ONE ROLLED-BACK TRANSACTION
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   93 winners · 93 offices · 54 re-elections · 39 handovers · 24 of them Ruling A fills
--   93 predecessors · digest 61951fdaf20febcf9e49b49caafc8185 · term start 2027-01-04
--
-- 🔴 **THE PIN WAS NOT TAKEN FROM `derive-seating-wave.mjs`.** That script keys every winner on
--   the race-carrying office, so for a Ruling A wave it digests a different selection from the
--   one this file writes. The digest above comes from a probe that rebuilds this file's own
--   assignment, run inside a transaction that had already applied CC_0497 and was then rolled
--   back. Maryland needed that order because its people file moved the assignment; Arizona has
--   no people file, but the dates file still has to exist before P4 can read a date.
--
-- 🔴 **AND THE COVERAGE GATE IS HERE EVEN THOUGH THE NULL CANNOT OCCUR.** `is_reelection` is
--   NULL — not false — on a seat with no current holder, because `office_current_holder` is LEFT
--   JOINed; `'…' || NULL` is NULL and `string_agg` SKIPS it, so the digest silently covers fewer
--   rows while every count still reads the full number. **All 93 Arizona seats are held and all
--   93 winners have a person record**, so the defect is unreachable here. P3 counts how many
--   rows the digest expression actually evaluated anyway: "it cannot happen here" expires the
--   moment a seat falls vacant, and a gate added only where the defect is already known is the
--   gate that will be missing the first time it matters. Washington's CC_0488 set this
--   precedent, and a control there proved the two gates are **complementary, not redundant**.
--
-- Ruling B: all 93 rows were **called**, none certified, when this was written. Every term's
-- `source` carries `CC_0498` so a reversed canvass is recovered by slot rather than from memory.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ A CORRECTION TO CC_0496's TEMPLATE: "RULING A" GOES ON A FILL, NOT ON EVERY HANDOVER
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Maryland wrote the Ruling A paragraph into the `source` of every **non-anchored** seat, which
-- included single-seat Senate handovers that no ruling touched. The claim was harmless there and
-- is still a claim about how a row was decided. Here the paragraph is written only where the
-- race carried more than one winner AND the winner did not anchor — **24 rows** — and post-verify
-- 15 counts exactly those. The other 15 handovers are ordinary single-seat successions.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 SIX MEMBERS CHANGE CHAMBER AND EVERY ONE OF THEM RESOLVES ITSELF
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   David Gowan        Senate 19 → House 19      Sally Ann Gonzales  Senate 20 → House 20
--   Gail Griffin       House 19  → Senate 19     Alma Hernandez      House 20  → Senate 20
--   Patty Contreras    House 12  → Senate 12     Leo Biasiucci       House 30  → Senate 30
--
-- ⚠ **DISTRICTS 19 AND 20 ARE STRAIGHT EXCHANGES** — Gowan and Griffin swap, Gonzales and
--   Hernandez swap — which is California's Ma/Kounalakis shape (CC_0478). The incumbency guard's
--   scope is a UNION of winners and predecessors for exactly this reason: no per-office count
--   can see somebody left holding two seats.
--
-- 🟢 **NOBODY IS LEFT HOLDING TWO SEATS.** Every seat the six vacate is inside this wave and is
--   filled by somebody else, so `seat_officeholder` closes each old term at 2027-01-03. That is
--   the opposite of Maryland's Nicholaus Kipke and Utah's Doug Fiefia, each of whom keeps a
--   second seat because the contest for it has no recorded result. ⚠ **A ZERO HERE IS A UNIFORM
--   ANSWER AND NEEDS A POSITIVE CONTROL**, so P9 does not merely assert "0 kept": it counts the
--   six switchers, asserts each one's currently-held office IS in this selection, and only then
--   reads the zero as a finding. A detector that has never found anything has not been shown to
--   work.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 TWO ARIZONA SEATS ARE NOT IN THIS WAVE AND THAT IS A MISSING RESULT, NOT A REFUSAL
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- State House District 27's two seats carry a 2026 race, three candidates — Deborah Howard, Lisa
-- Fink, Tony Rivero — and no `won` row. All three carry `result = 'advanced'`, which is the
-- **August top-two primary** result seeded by CA_0282 from the Secretary of State's own primary
-- canvass. Art. IV, Pt. 2, § 21 gives every member a two-year term and § 1(1) elects two
-- Representatives from each of the thirty districts, so all 60 House seats were on this ballot
-- as a matter of law and those two are **certainly missing data**. ▶ Unrecorded here, not
-- undecided there; it belongs to the results programme. CC_0497 left them undated and this file
-- leaves their sitting members in place with an open term, which is correct.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 AND TWO EXECUTIVE SEATS ARE REFUSED, FOR TWO DIFFERENT REASONS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   State Mine Inspector    REFUSED ON THE DATE. Art. XIX is published in TWO conflicting 1992
--                           versions (Proposition 101's four-year term, Proposition 107's
--                           two-year term) and NEITHER names a commencement day; A.R.S. holds
--                           only § 38-295's holdover provision. CC_0497 wrote it no date, so
--                           P4 would abort on it. Winner: Brian Matlock, over Les Presmyk.
--   Corporation Commission  REFUSED ON RULING A. Dated by CC_0497 under Art. XV § 1(B) and still
--                           not seatable: 2 winners against 5 eligible offices. Winners: Clara
--                           Pratte and Jonathon Hill.
--
-- 🔴 **A DATE AND A SEAT ARE SEPARATE QUESTIONS AND THESE TWO OFFICES SPLIT THEM BOTH WAYS.**
--   One has a seating and no date; the other has a date and no seating. P2g computes both
--   refusals instead of naming them.
--
-- ⚠ Arizona also elected a **Lieutenant Governor** under Art. V § 1(C), on the Governor's
--   ticket, taking office on this same day — and we hold **no office row and no candidate row**
--   for it. CC_0497's assertion 3e pins that absence. Creating the office is an occupancy act
--   and must be done together with a seating; it is not done here.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `essentials.seat_officeholder` closes each predecessor with an unguarded
-- `UPDATE office_terms SET term_end = p_term_start - 1` and writes nothing to that row's
-- `source`, so the new terms are recoverable by slot and **the closures are not**. The pre-image
-- is captured in `cc0498_pre` and asserted before the write:
--
--   **93 predecessor rows, one per seat. Every one has `term_end` NULL and `how_ended` NULL.
--   89 of the 93 carry a `term_start`** — Arizona is unlike Maryland here, where 177 of 178 were
--   undated tenures: these are real first-Monday dates from the ADR 0002 phase-2 backfill, which
--   is also what CC_0497's assertion 3d uses as its control. The other 4 are NULL. All 93 become
--   `term_end = 2027-01-03`, `how_ended = 'term_expired'`, and post-verify 6b asserts that not
--   one of the 89 start dates moved.
--
-- ⚠ 2027-01-03 is also the day Arizona's nine U.S. Representatives take office under the
--   Twentieth Amendment. One is a term start and the other is a term end; they are different
--   facts on the same calendar square, and no count in this file mixes them.

BEGIN;

CREATE TEMP TABLE cc0498_pin ON COMMIT DROP AS
SELECT 93                                 AS expect_winners,
       93                                 AS expect_offices,
       54                                 AS expect_reelections,
       39                                 AS expect_new,
       24                                 AS expect_ruling_a_fills,
       93                                 AS expect_predecessors,
       89                                 AS expect_dated_predecessors,
       29                                 AS expect_lower_races,
       30                                 AS expect_upper_races,
       5                                  AS expect_exec_races,
       58                                 AS expect_lower_seats,
       30                                 AS expect_upper_seats,
       5                                  AS expect_exec_seats,
       6                                  AS expect_switchers,
       129                                AS expect_terms_on_the_day_before,
       '61951fdaf20febcf9e49b49caafc8185' AS expect_digest,
       DATE '2027-01-04'                  AS expect_term_start;

-- ── Ruling A, in four steps. ──────────────────────────────────────────────────────────────────
--
-- 🔴 THE TWO REFUSED RACES ARE EXCLUDED HERE AND MEASURED IN P2g. Excluding them silently would
--    make the refusal a comment; P2g recomputes each one's reason from the data and aborts if it
--    has stopped being true.
CREATE TEMP TABLE cc0498_race ON COMMIT DROP AS
SELECT w.office_id AS race_office_id, o.district_id, o.chamber_id, o.title,
       d.label AS seat, d.district_type, w.winners, w.winner_count, w.certainty
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'az'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC')
   AND w.election_date = DATE '2026-11-03'
   AND o.title NOT IN ('Commissioner', 'State Mine Inspector');

-- Every Arizona state race, including the two this file refuses — so the refusals are counted
-- rather than assumed away.
CREATE TEMP TABLE cc0498_refused ON COMMIT DROP AS
SELECT w.office_id AS race_office_id, o.id AS office_id, o.district_id, o.chamber_id, o.title,
       d.label AS seat, jsonb_array_length(w.winners) AS n_winners,
       (SELECT count(*) FROM essentials.offices e
         WHERE e.district_id = o.district_id
           AND e.chamber_id IS NOT DISTINCT FROM o.chamber_id
           AND e.title = o.title)                                   AS n_eligible,
       (SELECT count(*) FROM essentials.office_swearing_in si
         WHERE si.office_id = o.id AND si.election_date = DATE '2026-11-03') AS n_dates
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'az'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC')
   AND w.election_date = DATE '2026-11-03'
   AND o.title IN ('Commissioner', 'State Mine Inspector');

-- The eligible set: the offices that could receive THIS race's winners.
CREATE TEMP TABLE cc0498_elig ON COMMIT DROP AS
SELECT r.race_office_id, r.seat, o2.id AS office_id,
       o2.seats, o2.voting_powers, o2.representation_note, o2.description
  FROM cc0498_race r
  JOIN essentials.offices o2 ON o2.district_id = r.district_id
                            AND o2.chamber_id IS NOT DISTINCT FROM r.chamber_id
                            AND o2.title = r.title;

CREATE TEMP TABLE cc0498_win ON COMMIT DROP AS
SELECT r.race_office_id, r.seat, r.district_type, r.winner_count,
       (w.value ->> 'id')::uuid AS politician_id,
       (w.value ->> 'name')     AS winner_name
  FROM cc0498_race r CROSS JOIN LATERAL jsonb_array_elements(r.winners) AS w(value);

-- A winner who already holds an eligible office is seated into THAT office.
CREATE TEMP TABLE cc0498_anchor ON COMMIT DROP AS
SELECT w.race_office_id, w.politician_id, w.winner_name, e.office_id
  FROM cc0498_win w
  JOIN cc0498_elig e ON e.race_office_id = w.race_office_id
  JOIN essentials.office_current_holder och ON och.office_id = e.office_id
 WHERE w.politician_id IS NOT NULL AND och.politician_id = w.politician_id;

-- The rest fill the rest, in ballot-name order into office_id order.
CREATE TEMP TABLE cc0498_assign ON COMMIT DROP AS
WITH rest_w AS (
  SELECT w.race_office_id, w.politician_id, w.winner_name, w.winner_count,
         row_number() OVER (PARTITION BY w.race_office_id
                            ORDER BY w.winner_name, w.politician_id::text) AS rn
    FROM cc0498_win w
   WHERE NOT EXISTS (SELECT 1 FROM cc0498_anchor a
                      WHERE a.race_office_id = w.race_office_id
                        AND a.politician_id IS NOT DISTINCT FROM w.politician_id)
), rest_o AS (
  SELECT e.race_office_id, e.office_id,
         row_number() OVER (PARTITION BY e.race_office_id ORDER BY e.office_id::text) AS rn
    FROM cc0498_elig e
   WHERE NOT EXISTS (SELECT 1 FROM cc0498_anchor a WHERE a.office_id = e.office_id)
)
SELECT a.race_office_id, a.office_id, a.politician_id, a.winner_name, true AS anchored,
       (SELECT w2.winner_count FROM cc0498_win w2
         WHERE w2.race_office_id = a.race_office_id LIMIT 1) AS winner_count
  FROM cc0498_anchor a
UNION ALL
SELECT r.race_office_id, o.office_id, r.politician_id, r.winner_name, false, r.winner_count
  FROM rest_w r JOIN rest_o o ON o.race_office_id = r.race_office_id AND o.rn = r.rn;

-- The selection, keyed on the ASSIGNED office.
CREATE TEMP TABLE cc0498_sel ON COMMIT DROP AS
SELECT a.office_id                                       AS office_id,
       a.politician_id                                   AS politician_id,
       (a.politician_id IS NOT NULL
         AND och.politician_id IS NOT NULL
         AND och.politician_id = a.politician_id)         AS is_reelection,
       si.swearing_in_date                               AS term_start,
       si.basis                                          AS basis,
       d.label                                           AS seat,
       d.district_type                                   AS district_type,
       a.winner_name                                     AS winner_name,
       a.anchored                                        AS anchored,
       -- 🔴 A RULING A FILL IS A NON-ANCHORED WINNER OF A MULTI-SEAT RACE. A single-seat
       -- handover is an ordinary succession and must not claim the ruling decided it.
       (NOT a.anchored AND a.winner_count > 1)           AS ruling_a_fill,
       a.race_office_id                                  AS race_office_id,
       och.politician_id                                 AS holder_before
  FROM cc0498_assign a
  JOIN essentials.offices   o ON o.id = a.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = a.office_id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = a.office_id
                                                AND si.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0498_pre ON COMMIT DROP AS
SELECT s.office_id, s.seat, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0498_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

-- Open terms a winner holds on an office this wave does NOT seat. Arizona expects none, and a
-- zero from a detector that has never found anything is not a finding — P9 pairs it with the
-- positive count of switchers whose seat IS in the wave.
CREATE TEMP TABLE cc0498_kept ON COMMIT DROP AS
SELECT t.id AS term_id, p.full_name, d.label AS seat, d.district_type
  FROM essentials.office_terms t
  JOIN essentials.offices o     ON o.id = t.office_id
  JOIN essentials.districts d   ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = t.politician_id
 WHERE t.politician_id IN (SELECT politician_id FROM cc0498_sel)
   AND NOT EXISTS (SELECT 1 FROM cc0498_sel s WHERE s.office_id = t.office_id)
   AND t.term_end IS NULL;

-- The six chamber switchers: a winner in one chamber who holds a seat in the other today.
CREATE TEMP TABLE cc0498_switch ON COMMIT DROP AS
SELECT s.politician_id, s.winner_name, s.seat AS wins, s.district_type AS wins_type,
       d2.label AS holds, d2.district_type AS holds_type, o2.id AS held_office_id,
       EXISTS (SELECT 1 FROM cc0498_sel z WHERE z.office_id = o2.id) AS held_seat_is_in_this_wave
  FROM cc0498_sel s
  JOIN essentials.office_current_holder och ON och.politician_id = s.politician_id
  JOIN essentials.offices   o2 ON o2.id = och.office_id
  JOIN essentials.districts d2 ON d2.id = o2.district_id
 WHERE lower(d2.state) = 'az'
   AND d2.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND s.district_type  IN ('STATE_LOWER', 'STATE_UPPER')
   AND d2.district_type <> s.district_type;

CREATE TEMP TABLE cc0498_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-04')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0498_pre)                                           AS predecessors,
       (SELECT count(*) FROM cc0498_kept)                                          AS kept,
       (SELECT md5(string_agg(och.office_id::text || ':'
                              || COALESCE(och.politician_id::text, '-'),
                              '|' ORDER BY och.office_id::text))
          FROM essentials.office_current_holder och)                               AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged,
       (SELECT count(*) FROM essentials.offices_missing_terms)                     AS missing_all;

DO $$
DECLARE n bigint; d text; p record; b record; txt text; r record;
BEGIN
  SELECT * INTO p FROM cc0498_pin;
  SELECT * INTO b FROM cc0498_before;

  -- P1 — ⚠ ASKED ABOVE EVERY COUNT. On a second run the seats have left office_pending_winner,
  -- so a count check fires first and blames the data for what is a repeat apply.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0498%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % office_terms row(s) already cite CC_0498. Applied before.', n;
  END IF;

  -- P2 — RULING A, ASSERTED PER RACE, BEFORE THE PIN AND BEFORE ANY WRITE.
  -- ───────────────────────────────────────────────────────────────────────────────────────────
  -- (a) 🔴🔴 THE EQUALITY CLAUSE. Eligible offices = winners, for every race. "At least" is what
  --     admits a staggered body, where filling "the remaining offices" would unseat sitting
  --     members with years left to serve. Arizona's Corporation Commission IS such a body and is
  --     the worked counter-example in Ruling A itself — it is excluded from this selection and
  --     its refusal is recomputed in P2g.
  SELECT string_agg(z.seat || ' (' || z.winners || ' winners, ' || z.eligible || ' eligible)',
                    '; ' ORDER BY z.seat)
    INTO txt
    FROM (SELECT r2.seat,
                 (SELECT count(*) FROM cc0498_win w WHERE w.race_office_id = r2.race_office_id)
                   AS winners,
                 (SELECT count(*) FROM cc0498_elig e WHERE e.race_office_id = r2.race_office_id)
                   AS eligible
            FROM cc0498_race r2) z
   WHERE z.winners <> z.eligible;
  IF txt IS NOT NULL THEN
    RAISE EXCEPTION 'P2a: Ruling A''s equality clause fails for: %. A body with more eligible '
                    'seats than winners is STAGGERED, and which seats are up is not in our data '
                    'at all — such a body is seated only by naming each winner''s office from '
                    'the body''s own published term table, cited in the migration.', txt;
  END IF;
  -- (b) the interchangeability clauses, per race. ⚠ Only title and chamber_id presently
  --     discriminate anything in Arizona (seats, description and representation_note are NULL on
  --     all 60 House rows and voting_powers has one distinct value); these are insurance against
  --     a future row, not checks that have ever fired. Do not read them as four independent
  --     assurances.
  SELECT string_agg(DISTINCT e.seat, '; ') INTO txt
    FROM cc0498_elig e WHERE e.description IS NOT NULL;
  IF txt IS NOT NULL THEN
    RAISE EXCEPTION 'P2b: eligible offices in % carry a description. A seat that describes '
                    'itself differently from its siblings is not interchangeable with them, and '
                    'a fill would claim something a voter could see is wrong.', txt;
  END IF;
  SELECT string_agg(z.seat, '; ' ORDER BY z.seat) INTO txt
    FROM (SELECT e.seat
            FROM cc0498_elig e
           GROUP BY e.race_office_id, e.seat
          HAVING count(DISTINCT COALESCE(e.seats, -1)) > 1
              OR count(DISTINCT COALESCE(e.voting_powers::text, '')) > 1
              OR count(DISTINCT COALESCE(e.representation_note, '')) > 1) z;
  IF txt IS NOT NULL THEN
    RAISE EXCEPTION 'P2c: eligible offices differ in seats, voting_powers or '
                    'representation_note in: %.', txt;
  END IF;
  -- (d) the assignment is a bijection: every winner once, every assigned office once, and no
  --     office claimed by two races.
  SELECT count(*) INTO n FROM cc0498_assign;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P2d: the assignment produced % rows for % winners.', n, p.expect_winners;
  END IF;
  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0498_assign GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2d: % office(s) were assigned more than one winner.', n;
  END IF;
  SELECT count(*) INTO n FROM (
    SELECT politician_id FROM cc0498_assign GROUP BY politician_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2d: % winner(s) were assigned more than one seat. ⚠ Districts 19 and 20 '
                    'are straight exchanges between the chambers, so a winner holding two '
                    'Arizona seats at once is a live shape here — but each of them wins exactly '
                    'one.', n;
  END IF;
  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0498_elig GROUP BY office_id HAVING count(DISTINCT race_office_id) > 1
  ) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2d: % office(s) are eligible for more than one race.', n;
  END IF;
  -- (e) 🔴 NOBODY IS SEATED OUTSIDE THE DISTRICT THAT ELECTED THEM. This is the claim a voter
  --     would see as wrong, and it is the one Ruling A could get wrong silently.
  SELECT count(*) INTO n
    FROM cc0498_assign a
    JOIN essentials.offices ao ON ao.id = a.office_id
    JOIN essentials.offices ro ON ro.id = a.race_office_id
   WHERE ao.district_id <> ro.district_id
      OR ao.title <> ro.title
      OR ao.chamber_id IS DISTINCT FROM ro.chamber_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2e: % winner(s) were assigned to an office outside the district, chamber '
                    'or title of the race that elected them.', n;
  END IF;
  -- (f) 🟢 THE 30-DISTRICT STRUCTURE, FROM THE CONSTITUTION AND NOT FROM OUR OWN ROWS. Art. IV,
  --     Pt. 2, § 1(1) gives every district one Senator and two Representatives; a district
  --     holding three House offices would let a fill claim a seat nobody elected.
  SELECT count(*) INTO n FROM (
    SELECT o.district_id, count(*) AS per
      FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'az' AND d.district_type = 'STATE_LOWER'
     GROUP BY 1) z WHERE per <> 2;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2f: % Arizona legislative district(s) do not hold exactly 2 House offices '
                    '(Art. IV, Pt. 2, § 1(1)). Ruling A must not run over a district whose seat '
                    'count is wrong.', n;
  END IF;
  SELECT count(*) INTO n FROM (
    SELECT o.district_id, count(*) AS per
      FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'az' AND d.district_type = 'STATE_UPPER'
     GROUP BY 1) z WHERE per <> 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2f: % Arizona legislative district(s) do not hold exactly 1 Senate '
                    'office.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 90 THEN
    RAISE EXCEPTION 'P2f: Arizona holds % legislative office rows, expected 90 — thirty '
                    'districts with one Senator and two Representatives each (Art. IV, Pt. 2, '
                    '§ 1(1)).', n;
  END IF;

  -- (g) 🔴🔴 THE TWO REFUSALS, RECOMPUTED RATHER THAN NAMED. A refusal that is only a comment
  --     in a header is a refusal nobody can check, and both of these are claims about real
  --     people's seats.
  SELECT count(*) INTO n FROM cc0498_refused;
  IF n <> 2 THEN
    RAISE EXCEPTION 'P2g: % Arizona state race(s) are excluded from this wave, expected 2 (the '
                    'Corporation Commission and the State Mine Inspector). If this has moved, '
                    'read what changed before seating anything.', n;
  END IF;
  FOR r IN SELECT * FROM cc0498_refused ORDER BY title LOOP
    RAISE NOTICE 'P2g: REFUSED — % (%): % winner(s), % eligible office(s), % date row(s).',
      r.title, r.seat, r.n_winners, r.n_eligible, r.n_dates;
  END LOOP;
  -- The Corporation Commission: dated, and refused because 5 <> 2.
  SELECT count(*) INTO n FROM cc0498_refused
   WHERE title = 'Commissioner' AND n_eligible = 5 AND n_winners = 2 AND n_dates = 1;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P2g: the Corporation Commission race no longer reads as "5 eligible '
                    'offices, 2 winners, 1 date row". Ruling A refuses it BECAUSE those two '
                    'numbers disagree — the body is staggered and which seats are up is not in '
                    'our data. If they now agree, the body may be seatable and this exclusion '
                    'must be re-argued, not quietly kept.';
  END IF;
  -- The State Mine Inspector: seatable in principle, refused because it has no date at all.
  SELECT count(*) INTO n FROM cc0498_refused
   WHERE title = 'State Mine Inspector' AND n_eligible = 1 AND n_winners = 1 AND n_dates = 0;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P2g: the State Mine Inspector race no longer reads as "1 eligible office, '
                    '1 winner, 0 date rows". It is refused ON THE DATE, not on Ruling A: Art. '
                    'XIX is published in two conflicting 1992 versions and neither names a '
                    'commencement day. If a date row has appeared, read its authority before '
                    'seating — the inference that it follows the first Monday like every other '
                    'Arizona office is written down in CC_0497 and deliberately not written in.';
  END IF;

  -- P3 — the pin.
  SELECT count(*) INTO n FROM cc0498_race WHERE district_type = 'STATE_LOWER';
  IF n <> p.expect_lower_races THEN
    RAISE EXCEPTION 'P3: % House races are pending, expected %. ⚠ State House District 27 '
                    'carried no recorded winner when this file was written; if it has arrived, '
                    'this wave is larger.', n, p.expect_lower_races;
  END IF;
  SELECT count(*) INTO n FROM cc0498_race WHERE district_type = 'STATE_UPPER';
  IF n <> p.expect_upper_races THEN
    RAISE EXCEPTION 'P3: % Senate races are pending, expected % — the whole chamber. Arizona''s '
                    'Senate is not staggered, unlike Washington''s and Oregon''s.',
      n, p.expect_upper_races;
  END IF;
  SELECT count(*) INTO n FROM cc0498_race WHERE district_type = 'STATE_EXEC';
  IF n <> p.expect_exec_races THEN
    RAISE EXCEPTION 'P3: % state executive races in this wave, expected 5 (Governor, Secretary '
                    'of State, Attorney General, Treasurer, Superintendent of Public '
                    'Instruction). The Corporation Commission and the State Mine Inspector are '
                    'refused and counted in P2g.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0498_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: selection returned % winner rows, expected %. The data moved under '
                    'this file.', n, p.expect_winners;
  END IF;
  SELECT count(DISTINCT office_id) INTO n FROM cc0498_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P3: % distinct offices, expected %. Under Ruling A the winners and the '
                    'offices are equal only because every race''s eligible set is exactly the '
                    'size of its winner list — if these differ, two winners have been assigned '
                    'the same seat.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n FROM cc0498_sel WHERE district_type = 'STATE_LOWER';
  IF n <> p.expect_lower_seats THEN
    RAISE EXCEPTION 'P3: % House seats in the selection, expected % of 60.',
      n, p.expect_lower_seats;
  END IF;
  SELECT count(*) INTO n FROM cc0498_sel WHERE district_type = 'STATE_UPPER';
  IF n <> p.expect_upper_seats THEN
    RAISE EXCEPTION 'P3: % Senate seats in the selection, expected %.', n, p.expect_upper_seats;
  END IF;
  SELECT count(*) INTO n FROM cc0498_sel WHERE district_type = 'STATE_EXEC';
  IF n <> p.expect_exec_seats THEN
    RAISE EXCEPTION 'P3: % state executive seats in the selection, expected %.',
      n, p.expect_exec_seats;
  END IF;
  -- 🔴 HOW MANY ROWS THE DIGEST EXPRESSION ACTUALLY EVALUATED. A NULL is_reelection renders the
  -- whole concatenation NULL and string_agg skips it, so the digest can cover fewer rows than
  -- every count claims. Unreachable in Arizona and gated anyway.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0498_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: the digest expression evaluated to NULL on % of % rows, so string_agg '
                    'would have skipped them. is_reelection is NULL on a seat with no current '
                    'holder — when this file was written all 93 Arizona seats were held, so one '
                    'has fallen vacant. Read it before seating over it.',
      p.expect_winners - n, p.expect_winners;
  END IF;
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0498_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P3: selection digest is %, expected %. Every count above passed, so the '
                    'membership is the same size and something inside it changed — a winner '
                    'swapped, a seat changed hands before the handover, or RULING A ASSIGNED '
                    'SOMEBODY DIFFERENTLY. ⚠ This digest was captured by rehearsing CC_0497 + a '
                    'probe in one rolled-back transaction and it is NOT the one '
                    'derive-seating-wave.mjs prints: that script keys every winner on the '
                    'race-carrying office, which is the wrong selection for a Ruling A wave.',
      d, p.expect_digest;
  END IF;
  SELECT count(*) INTO n FROM cc0498_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P3: % re-elections, expected %.', n, p.expect_reelections;
  END IF;
  SELECT count(*) INTO n FROM cc0498_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P3: % new holders, expected %. (Counted with NOT, which a NULL would fail '
                    'as well — % + % = % only if every row is a real boolean.)',
      n, p.expect_new, p.expect_reelections, p.expect_new, p.expect_winners;
  END IF;
  -- 54 anchored, 39 filled, and only 24 of those 39 are Ruling A fills. ⚠ This is a PIN check —
  -- it compares Ruling A's output against numbers captured on 2026-11-24 — so it sits here with
  -- the rest of the pin rather than in P2.
  SELECT count(*) INTO n FROM cc0498_assign WHERE anchored;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P3h: % winners anchored to a seat they already hold, expected % — the same '
                    'number as the re-elections, because anchoring is holding the seat you won. '
                    'If these two ever differ, one of them is measuring something else.',
      n, p.expect_reelections;
  END IF;
  SELECT count(*) INTO n FROM cc0498_sel WHERE ruling_a_fill;
  IF n <> p.expect_ruling_a_fills THEN
    RAISE EXCEPTION 'P3h: % Ruling A fills, expected % — a non-anchored winner of a MULTI-seat '
                    'race. The other % handovers are single-seat successions that no ruling '
                    'decided, and they must not say Ruling A in their source.',
      n, p.expect_ruling_a_fills, p.expect_new - p.expect_ruling_a_fills;
  END IF;
  SELECT count(*) INTO n FROM cc0498_sel WHERE ruling_a_fill AND district_type <> 'STATE_LOWER';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3h: % Ruling A fill(s) sit outside the House. Arizona''s only multi-seat '
                    'races in this wave are its 29 House contests; the Corporation Commission '
                    'is the other and it is refused.', n;
  END IF;

  -- P4 — the date, read from office_swearing_in and never typed here.
  SELECT count(*) INTO n FROM cc0498_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. CC_0497 '
                    'writes it, FOR ALL 94 OFFICES INCLUDING THE 29 THAT CARRY NO RACE — if '
                    'this fires for roughly 29 seats, a date file was written against the '
                    'race-carrying offices only. ⚠ If a date reads 2027-01-11 somebody has '
                    'reached for the SESSION convening day under Art. IV, Pt. 2, § 3, which is '
                    'also the day 193 Washington and Oregon seats begin; if it reads '
                    '2027-01-01, somebody has applied UTAH''s rule.', n, p.expect_term_start;
  END IF;
  SELECT count(*) INTO n FROM cc0498_sel
   WHERE basis IS DISTINCT FROM 'statute' AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published. An '
                    'estimate may not seat anybody.', n;
  END IF;

  -- P5 — every winner has a person row. Arizona needed no people file; this is what makes that
  -- a measurement rather than an assumption.
  SELECT count(*) INTO n FROM cc0498_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat. Arizona ships with no '
                    'people file because all 96 winner rows already carried a politician_id on '
                    '2026-11-24; if this fires, that is no longer true and a people file is '
                    'owed BEFORE this one.', n;
  END IF;

  -- P6 — no seat in this wave is flagged is_vacant. A future-dated seating does not clear a
  -- flag, so a flagged seat needs a companion file of the CC_0480 / CC_0486 kind; Arizona has
  -- none and needs none.
  SELECT count(*) INTO n
    FROM cc0498_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) in this wave are flagged is_vacant, expected 0.', n;
  END IF;

  -- P7 — the predecessor pre-image, which is what this file overwrites.
  SELECT count(*) INTO n FROM cc0498_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) captured, expected % — one per seat. Every '
                    'Arizona seat in this wave was held when this file was written.',
      n, p.expect_predecessors;
  END IF;
  SELECT count(*) INTO n FROM cc0498_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing, so this file would '
                    'destroy a date it has not written down.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0498_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a how_ended. seat_officeholder '
                    'COALESCEs that column, so an existing value survives.', n;
  END IF;
  -- 🔴 89 OF THE 93 PREDECESSORS ARE DATED, WHICH IS THE OPPOSITE OF MARYLAND. Those dates are
  -- the ADR 0002 backfill's real first Mondays — the same rows CC_0497's assertion 3d uses as
  -- its control — so this file must close them without moving a single start.
  SELECT count(*) INTO n FROM cc0498_pre WHERE term_start IS NOT NULL;
  IF n <> p.expect_dated_predecessors THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) carry a term_start, expected % of %. These are '
                    'Arizona''s backfilled first-Monday dates; post-verify 6b asserts not one '
                    'of them moved.', n, p.expect_dated_predecessors, p.expect_predecessors;
  END IF;
  SELECT count(*) INTO n FROM cc0498_pre WHERE term_start > p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) start AFTER the handover day. Closing one at '
                    '% - 1 would write a term that ends before it begins.', n,
      p.expect_term_start;
  END IF;
  SELECT count(*) INTO n
    FROM cc0498_sel s
   WHERE NOT EXISTS (SELECT 1 FROM cc0498_pre x WHERE x.office_id = s.office_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % seat(s) have no predecessor term. A seat with nobody in it is a fact '
                    'to read, not to seat over.', n;
  END IF;

  -- P8 — 🟢 NOBODY IS LEFT HOLDING TWO SEATS, AND THE ZERO IS PAIRED WITH A POSITIVE COUNT.
  -- A detector that has never found anything has not been shown to work: Maryland's found
  -- Kipke, Utah's found Fiefia. Here it must find nothing AND the reason must be visible.
  SELECT count(*) INTO n FROM cc0498_kept;
  IF n <> 0 THEN
    SELECT string_agg(k.full_name || ' — ' || k.seat, '; ' ORDER BY k.full_name)
      INTO txt FROM cc0498_kept k;
    RAISE EXCEPTION 'P8: % open term(s) held by a winner on an office OUTSIDE this wave: %. '
                    'Arizona expects none — every seat the six chamber switchers vacate is '
                    'inside this wave. A new one means a seat this wave cannot fill, as '
                    'Maryland''s District 31 could not fill Nicholaus Kipke''s. Read it: the '
                    'fix is usually the missing RESULT, never an edit here.', n, txt;
  END IF;

  -- P9 — 🔴 THE SIX CHAMBER SWITCHERS, AND THE POSITIVE CONTROL FOR P8's ZERO.
  SELECT count(*) INTO n FROM cc0498_switch;
  IF n <> p.expect_switchers THEN
    RAISE EXCEPTION 'P9: % winner(s) hold a seat in the other Arizona chamber, expected % '
                    '(Gowan and Griffin exchange District 19; Gonzales and Hernandez exchange '
                    'District 20; Contreras House 12 -> Senate 12; Biasiucci House 30 -> '
                    'Senate 30). If this is fewer, a link has gone; if more, somebody else is '
                    'switching and the header does not describe them.', n, p.expect_switchers;
  END IF;
  SELECT count(*) INTO n FROM cc0498_switch WHERE NOT held_seat_is_in_this_wave;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P9: % of the six switchers hold a seat this wave does NOT fill, so their '
                    'old term would stay open and they would hold two seats from %. P8''s zero '
                    'only means something while this one is zero too.', n, p.expect_term_start;
  END IF;
  FOR r IN SELECT * FROM cc0498_switch ORDER BY winner_name LOOP
    RAISE NOTICE 'P9: % holds % and wins % — the seat they vacate is in this wave: %.',
      r.winner_name, r.holds, r.wins, r.held_seat_is_in_this_wave;
  END LOOP;

  -- P10 — 🔴🔴 THE 2027-01-04 DELTA. Arizona is the THIRD state on this calendar day: 129 terms
  -- are already here (Wisconsin 121, California 8) and Wisconsin's rule is ALSO a first Monday,
  -- so a gate reading the total would see 222 and call it success.
  IF b.terms_on_the_day <> p.expect_terms_on_the_day_before THEN
    RAISE EXCEPTION 'P10: % term(s) already begin on %, expected % (Wisconsin 121 under its '
                    'first-Monday rule, California 8 under Art. II § 20). A state has landed on '
                    'Arizona''s day — name its rule before adding 93 to the pile.',
      b.terms_on_the_day, p.expect_term_start, p.expect_terms_on_the_day_before;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE t.term_start = p.expect_term_start AND lower(dd.state) NOT IN ('wi', 'ca');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P10: % term(s) on % belong to a state other than Wisconsin or California. '
                    'A date shared by several states is a coincidence of calendars, never a '
                    'shared rule.', n, p.expect_term_start;
  END IF;

  -- P11 — Ruling B: every row was called, not certified, when this was written.
  SELECT count(*) INTO n
    FROM cc0498_sel s
    JOIN essentials.office_pending_winner w ON w.office_id = s.race_office_id
   WHERE w.certainty <> 'called';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P11: % seat(s) are no longer "called". If Arizona has certified since '
                    '2026-11-24, the terms this file writes should say "certified" instead.', n;
  END IF;
END $$;

-- @incumbency-decision: gated — this file opens 93 Arizona terms on 2027-01-04 and closes each
--   seat's predecessor at 2027-01-03, so it restates who held those seats on every election day
--   the closed terms no longer cover. The gate below is scoped to the UNION of the winners and
--   their predecessors. ⚠ Six members change chamber and two pairs simply SWAP, so a winner here
--   is frequently also somebody else's predecessor — which is exactly why the scope is a union
--   and not the winner set.
CREATE TEMP TABLE cc0498_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0498_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0498_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0498_guarded);

DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0498_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran. Term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in. ARIZONA STATES ITS RULE AS AN '
                         || 'ANCHOR YEAR PLUS A TERM LENGTH, NEVER AS A RECURRING FORMULA: '
                         || CASE WHEN r.district_type = 'STATE_EXEC' THEN
                              'Ariz. Const. Art. V, § 1(A), "each of whom shall hold office for '
                              || 'four years beginning on the first Monday of January, 1971 next '
                              || 'after the regular general election in 1970" (1971 + 14x4 = '
                              || '2027). '
                            ELSE
                              'Ariz. Const. Art. IV, Pt. 2, § 21, "The members of the first '
                              || 'legislature shall hold office until the first Monday in '
                              || 'January, 1913. The terms of office of the members of '
                              || 'succeeding legislatures shall be two years" (1913 + 57x2 = '
                              || '2027). NOTE: § 21 is the TERM. Art. IV, Pt. 2, § 3 commences '
                              || 'the SESSION on the second Monday — 2027-01-11, a week later, '
                              || 'and the day 193 Washington and Oregon seats take office under '
                              || 'unrelated rules. '
                            END
                         || CASE WHEN r.ruling_a_fill THEN
                              'RULING A: Arizona elects two Representatives from each district '
                              || 'in one multi-seat contest and the winner-to-seat mapping is '
                              || 'not in the data, so this winner was assigned to a sibling '
                              || 'office of the same district, chamber and title — one that no '
                              || 'other winner of that race already holds. The two seats of a '
                              || 'district carry no separate public identity (seats, description '
                              || 'and representation_note are NULL on all 60 House rows, '
                              || 'voting_powers has one value), and the race''s eligible seats '
                              || 'exactly equal its winners. See REGISTER.md Ruling A. '
                            WHEN r.anchored THEN
                              'Seated into the seat this member already holds. '
                            ELSE
                              'Single-seat race; no Ruling A assignment was involved. '
                            END
                         || CASE WHEN r.is_reelection THEN 'Re-elected incumbent. '
                                 ELSE 'New holder; predecessor closed at 2027-01-03. ' END
                         || 'CC_0498',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0498: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0498_guarded;
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
  SELECT * INTO b FROM cc0498_before;
  SELECT * INTO p FROM cc0498_pin;

  -- 1. 🔴 THE RULING A POST-VERIFY. This joins office_terms back to the selection on office_id
  --    — which is the ASSIGNED office. Built on the race-carrying office it would look for 29
  --    terms that were never written, and would do so AFTER the write.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0498_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. the read path answers for every seat.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0498_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_offices;
  END IF;

  -- 3. the day's delta, and every row on it belongs to a named state.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_offices THEN
    RAISE EXCEPTION '3: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_start = p.expect_term_start
     AND NOT (lower(d.state) = 'az'
              AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC'))
     AND lower(d.state) NOT IN ('wi', 'ca');
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % term(s) on % are neither this wave''s nor one of the Wisconsin and '
                    'California rows that were already there.', n, p.expect_term_start;
  END IF;

  -- 4. nobody moved TODAY. A future-dated term must not change who holds a seat now.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today.', b.holders_md5, m;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0498_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of % seats still answer office_current_holder with the person holding '
                    'them today.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0498_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % of the 93 seats answer office_current_holder with nobody, expected 0.',
      n;
  END IF;

  -- 6. every predecessor named in the pre-image closed on the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0498_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0498_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;
  -- 🔴 AND ALL 89 DATED PREDECESSORS KEPT THEIR START. Those are Arizona's backfilled first
  -- Mondays, which CC_0497's own date control reads; moving one would corrupt the evidence for
  -- the rule this wave is written on.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0498_pre x ON x.term_id = t.id
   WHERE t.term_start IS NOT DISTINCT FROM x.term_start;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6b: % of % closed predecessor term(s) kept the term_start they had, of '
                    'which % were dated. This file dates nobody''s tenure.',
      n, b.predecessors, p.expect_dated_predecessors;
  END IF;

  -- 7. nothing closed between today and the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0498_sel s ON s.office_id = t.office_id
   WHERE t.term_end IS NOT NULL
     AND t.term_end >= CURRENT_DATE AND t.term_end < p.expect_term_start - 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % term(s) closed between today and the day before the handover.', n;
  END IF;

  -- 8. no person or office was created or destroyed. ⚠ Arizona's missing Lieutenant Governor is
  --    NOT created here: it has no candidate row to seat, and an office with no term is
  --    invisible while an office created without a holder raises the drift baseline.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %. This wave has no people file.',
      b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %.', b.offices, n;
  END IF;

  -- 9. nobody landed on either wrong day — Utah's January 1st, or the second Monday that is
  --    Arizona's own SESSION convening day and 193 other seats' term start.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0498_sel s ON s.office_id = t.office_id
   WHERE t.term_start IN (DATE '2027-01-01', DATE '2027-01-11');
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % seat(s) start on one of the two wrong days (2027-01-01, UTAH''s rule; '
                    '2027-01-11, the SESSION convening day under Art. IV, Pt. 2, § 3 and the '
                    'term start of 118 Washington and 75 Oregon seats).', n;
  END IF;

  -- 10. the two refused executives were not seated and are still visibly pending, and the two
  --     unrecorded House seats were not touched.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND o.title IN ('Commissioner', 'State Mine Inspector')
     AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '10: % Corporation Commission or State Mine Inspector seat(s) were seated. '
                    'The Commission is refused by Ruling A (2 winners, 5 eligible offices) and '
                    'the Mine Inspector has no cited start date at all.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND d.district_type = 'STATE_EXEC'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 2 THEN
    RAISE EXCEPTION '10b: % Arizona state executive seat(s) still answer office_pending_winner, '
                    'expected 2 — the Corporation Commission and the State Mine Inspector, '
                    'both refused and both visible.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND t.term_start = p.expect_term_start
     AND d.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC');
  IF n <> 0 THEN
    RAISE EXCEPTION '10c: % Arizona seat(s) below the state tier were seated on this day.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND d.label = 'State House District 27'
     AND t.term_end IS NOT NULL AND t.term_end >= CURRENT_DATE;
  IF n <> 0 THEN
    RAISE EXCEPTION '10d: % State House District 27 term(s) were closed. That contest has no '
                    'recorded winner — all three candidates carry the AUGUST primary''s '
                    '''advanced'' — so nobody is seated there and nobody may be unseated there '
                    'either. The fix is the result.', n;
  END IF;

  -- 11. 🟢 ALL SIX CHAMBER SWITCHES RESOLVED THEMSELVES — the positive form of P8's zero.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0498_switch sw ON sw.held_office_id = t.office_id
                                                       AND sw.politician_id = t.politician_id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> p.expect_switchers THEN
    RAISE EXCEPTION '11: % of the % switchers had their old term closed at %, expected all of '
                    'them. Arizona has no Kipke and no Fiefia: every seat the six vacate is '
                    'inside this wave.', n, p.expect_switchers, p.expect_term_start - 1;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0498_kept k ON k.term_id = t.id
   WHERE t.term_end IS NULL;
  IF n <> b.kept THEN
    RAISE EXCEPTION '12: % of % term(s) held by a winner on an office outside this wave are '
                    'still open.', n, b.kept;
  END IF;

  -- 13. no vacancy flag moved.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC')
     AND o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION '13: % Arizona state office(s) are flagged is_vacant.', n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '13: the repo-wide count of flagged-vacant offices moved % -> %.',
      b.vacant_all, n;
  END IF;

  -- 14. exactly 93 terms were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '14: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 15. Ruling B — every new term names the slot and says what it seated from; and every Ruling
  --     A fill says so in its own source, while no single-seat handover claims it did.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0498_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0498%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '15: % of % new terms cite CC_0498.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0498_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%called, not certified%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '15: % of % new terms record that the result was called rather than '
                    'certified.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0498_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%RULING A%';
  IF n <> p.expect_ruling_a_fills THEN
    RAISE EXCEPTION '15: % new term(s) record RULING A in their own source, expected exactly % '
                    '— the non-anchored winners of a MULTI-seat race. An arbitrary-but-honest '
                    'assignment that does not say it is one cannot be audited; and a '
                    'single-seat succession that CLAIMS a ruling decided it is the same defect '
                    'pointing the other way.', n, p.expect_ruling_a_fills;
  END IF;

  -- 16. every seat has left office_pending_winner.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0498_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '16: % seat(s) still answer office_pending_winner.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'az' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND w.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '16: % Arizona legislative race(s) are still pending, expected 0 — all 59 '
                    'were in this wave.', n;
  END IF;

  -- 17. the drift baseline held, and the view did not move. All 93 seats already had a term.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '17: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> b.missing_all THEN
    RAISE EXCEPTION '17: offices_missing_terms went % -> %, expected no change — all 93 seats '
                    'already carried a term row.', b.missing_all, n;
  END IF;

  RAISE NOTICE 'CC_0498 OK: 93 Arizona office-holders scheduled for % (% re-elections, % '
               'handovers, % of them RULING A fills), % predecessors closed at % — 89 of them '
               'carrying a real backfilled first-Monday start that this file left untouched. '
               'THE SECOND RULING A WAVE: every one of the 29 pending House contests carries '
               'two winners, so 24 were assigned to a sibling office of their own district and '
               'each of those terms says so in its own source, while the 15 single-seat '
               'handovers say they are nothing of the kind. The selection is keyed on the '
               'ASSIGNED office, which is what lets assertion 1 find all 93. Six members change '
               'chamber — Districts 19 and 20 are straight EXCHANGES — and every seat they '
               'vacate is inside this wave, so nobody is left holding two. Nobody moved today, '
               'no seat is flagged vacant, nobody landed on 2027-01-01 (Utah''s rule) or '
               '2027-01-11 (Arizona''s own SESSION day, and 193 Washington and Oregon seats). '
               'TWO EXECUTIVE SEATS WERE REFUSED and are still visibly pending, for two '
               'different reasons measured in P2g: the Corporation Commission has a date and no '
               'seating (2 winners, 5 eligible offices — Ruling A''s worked counter-example), '
               'the State Mine Inspector has a seating and no date (Art. XIX is published in '
               'two conflicting 1992 versions, neither naming a day). State House District 27''s '
               'two seats were left alone — unrecorded, not undecided. Drift baseline % held.',
    p.expect_term_start, p.expect_reelections, p.expect_new, p.expect_ruling_a_fills,
    b.predecessors, p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
