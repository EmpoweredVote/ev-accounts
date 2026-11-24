-- CC_0496 — Maryland: seat the 178 General Assembly winners of 2026-11-03 for 2027-01-13.
--
-- Third of three. CC_0494 writes the dates (178 offices, Md. Const. Art. III § 6, the second
-- Wednesday of January); CC_0495 links 60 winners to the person this database already held and
-- creates 25; this file writes the terms.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THIS IS THE FIRST RULING A WAVE, AND THE SELECTION IS BUILT ON THE **ASSIGNED** OFFICE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 38 of Maryland's 67 pending Delegate contests carry more than one winner — 131 winners across
-- 67 office rows — because a multi-seat race attaches ALL its winners to ONE office row, so the
-- winner-to-seat mapping is not in the data. REGISTER.md's **Ruling A** decides it:
--
--   • **The eligible set** is not "the district's offices" but the offices that could receive
--     THIS race's winners: same `district_id`, same `chamber_id`, same `title` as the race's own
--     office. Maryland's lettered subdistricts (19A, 19B) are separate districts and elect
--     separately, which is why the gate is per race.
--   • **A winner who already holds one of the eligible offices is seated into THAT office.**
--     148 of the 178 anchor this way.
--   • **The remaining winners fill the remaining eligible offices in `office_id` order**, in
--     ballot-name order — and only under the gate below.
--   • **The gate, per race:** every eligible office must share `seats`, `voting_powers` and
--     `representation_note`, none may carry a `description` that distinguishes it, **and the
--     count of eligible offices must EQUAL the number of winners.** P2 asserts all of it,
--     and it runs BEFORE the pin — see the note below.
--
-- 🔴 **THE EQUALITY CLAUSE IS THE WHOLE OF IT.** "At least" would admit a staggered body — one
--   where more seats exist than are up — and then "fill the remaining offices" would unseat
--   sitting members with years left. Maryland is not staggered (Art. III § 7 elects the whole
--   General Assembly every fourth year) and all 67 races pass equality exactly; the clause is
--   here because the next Ruling A state may not.
--
-- 🔴🔴 **RULING A RUNS AS `P2`, ABOVE THE PIN, AND THAT ORDER WAS CHOSEN BY A CONTROL THAT
--   COULD NOT GO RED.** It was written below the pin at first. Every tamper aimed at the
--   equality clause was caught two gates earlier by `P3`'s digest or its row counts, so the
--   clause that carries the real-world cost — *a named sitting official unseated in favour of
--   somebody who did not win their seat* — had no control of its own, and a suite in which 20
--   of 21 go red reads like a success. Ruling A asks whether this body is **assignable at all**,
--   which is a fact about the world; the pin asks whether the answer is **the one recorded on
--   2026-11-23**, which is a fact about this file. The first question comes first, and the
--   operator now gets the right diagnosis instead of "the digest moved". ▶ A gate no control
--   can reach is a gate nobody has tested, however many controls the file has.
--
-- 🔴 **`scripts/lib/seating-wave.mjs`'s `WAVE_SELECTION_SQL` KEYS EVERY WINNER ON THE
--   RACE-CARRYING OFFICE AND IS WRONG FOR THIS WAVE.** Post-verify 1 joins `office_terms` back
--   to the selection on `office_id`; with the published selection it would look for a term on an
--   office that was never written and abort **after** 178 seats had been seated. The selection
--   below is the corrected one — written once here, and pinned by the digest.
--
-- ⚠ **WHAT MAKES AN ARBITRARY FILL HONEST HERE, MEASURED.** Across all 141 Maryland Delegate
--   office rows: `seats` non-null 0, `description` non-null 0, `representation_note` non-null 0,
--   one distinct `voting_powers`, one distinct `title`. The sibling seats of a district carry no
--   separate public identity, so assigning a winner to one rather than another makes no claim a
--   voter could see as wrong. Only `title` and `chamber_id` discriminate anything; the other
--   three clauses are insurance against a future row, not checks that have ever fired.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE PIN — CAPTURED AFTER THE PEOPLE FILE, NOT BEFORE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   178 winners · 178 offices · 148 re-elections · 30 handovers · 178 predecessors
--   digest bfa801bd8293e0f0e8bea0b78f0934ba · term start 2027-01-13
--
-- 🔴🔴 **THE DIGEST WAS TAKEN BY REHEARSING `CC_0494 + CC_0495 + A PROBE` IN ONE ROLLED-BACK
--   TRANSACTION, BECAUSE IN MARYLAND THE ASSIGNMENT ITSELF MOVES WHEN THE PEOPLE FILE RUNS.**
--   Ruling A anchors a winner to the office they already hold — and 55 of the 178 could not
--   anchor before CC_0495, because their `race_candidates` row carried a NULL `politician_id`.
--   Before the people file this same selection anchors 93 winners and FILLS 85; after it, it
--   anchors 148 and fills 30, and the seat each of those 85 lands in can differ. A digest
--   captured from the pre-link world would have been internally consistent and would have
--   described a different seating. (Massachusetts found the narrower version of this: the
--   `is_reelection` NULL did not exist until `CC_0482` ran.)
--
-- 🔴 **AND THE COVERAGE GATE IS HERE EVEN THOUGH THE NULL CANNOT OCCUR.** `is_reelection` is
--   NULL — not false — on a seat with no current holder, because `office_current_holder` is LEFT
--   JOINed; `'…' || NULL` is NULL and `string_agg` SKIPS it, so the digest silently covers fewer
--   rows while every count still reads the full number. All 178 Maryland seats are held and all
--   178 winners have a person record, so the defect is unreachable here. P3 counts how many rows
--   the digest expression actually evaluated anyway: "it cannot happen here" expires the moment
--   a seat falls vacant, and a gate added only where the defect is already known is the gate
--   that will be missing the first time it matters.
--
-- Ruling B: all 178 rows were **called**, none certified, when this was written. Every term's
-- `source` carries `CC_0496` so a reversed canvass is recovered by slot rather than from memory.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ ONE PERSON WILL HOLD TWO SEATS FROM 2027-01-13, AND THAT IS THE MISSING RESULT SHOWING
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Nicholaus R. Kipke holds **Delegate District 31** and wins **Senate District 31**. District
-- 31's Delegate contest is one of the four this database holds no recorded result for (CC_0494's
-- header has all four, with the State Board's own margins), so nobody is seated there and
-- `seat_officeholder` — which closes the predecessor on the seat it SEATS and nothing else —
-- leaves his Delegate term open. P8/P9 assert exactly that shape and assertion 12 re-asserts it
-- afterwards. ▶ **Closing his House term here would mean inventing a successor.** The fix is the
-- result. Utah's Doug Fiefia (CC_0490) is the same case.
--
-- The other four chamber-switchers resolve themselves, as Oregon's Jeff Helfrich did: Tiffany
-- Alston (24), C. T. Wilson (28), Mark S. Chang (32) and Malcolm P. Ruff (41) each vacate a
-- Delegate seat this same wave fills, so their old term closes at 2027-01-12 because a successor
-- is seated into it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `essentials.seat_officeholder` closes each predecessor with an unguarded
-- `UPDATE office_terms SET term_end = p_term_start - 1` and writes nothing to that row's
-- `source`, so the new terms are recoverable by slot and **the closures are not**. The pre-image
-- is captured in `cc0496_pre` and asserted before the write:
--
--   **178 predecessor rows, one per seat. Every one has `term_end` NULL and `how_ended` NULL.
--   Exactly ONE carries a `term_start`** — Alexander M. Harlan, Subdistrict 42A, 2026-08-03, an
--   appointment. The other 177 are undated tenures. All 178 become `term_end = 2027-01-12`,
--   `how_ended = 'term_expired'`.
--
-- ⚠ The Maryland Manual says the sitting members "serve until January 13, 2027" while this file
--   writes 2027-01-12. One handover, two adjacent days: `seat_officeholder` closes at
--   `term_start - 1` everywhere in this programme. Not a disagreement with the Archives.

BEGIN;

CREATE TEMP TABLE cc0496_pin ON COMMIT DROP AS
SELECT 178                                AS expect_winners,
       178                                AS expect_offices,
       148                                AS expect_reelections,
       30                                 AS expect_new,
       178                                AS expect_predecessors,
       67                                 AS expect_lower_races,
       47                                 AS expect_upper_races,
       131                                AS expect_lower_seats,
       47                                 AS expect_upper_seats,
       'bfa801bd8293e0f0e8bea0b78f0934ba' AS expect_digest,
       DATE '2027-01-13'                  AS expect_term_start;

-- ── Ruling A, in four steps. ───────────────────────────────────────────────────────────────────
CREATE TEMP TABLE cc0496_race ON COMMIT DROP AS
SELECT w.office_id AS race_office_id, o.district_id, o.chamber_id, o.title,
       d.label AS seat, d.district_type, w.winners, w.winner_count, w.certainty
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'md'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND w.election_date = DATE '2026-11-03';

-- The eligible set: the offices that could receive THIS race's winners.
CREATE TEMP TABLE cc0496_elig ON COMMIT DROP AS
SELECT r.race_office_id, r.seat, o2.id AS office_id,
       o2.seats, o2.voting_powers, o2.representation_note, o2.description
  FROM cc0496_race r
  JOIN essentials.offices o2 ON o2.district_id = r.district_id
                            AND o2.chamber_id IS NOT DISTINCT FROM r.chamber_id
                            AND o2.title = r.title;

CREATE TEMP TABLE cc0496_win ON COMMIT DROP AS
SELECT r.race_office_id, r.seat, r.district_type,
       (w.value ->> 'id')::uuid AS politician_id,
       (w.value ->> 'name')     AS winner_name
  FROM cc0496_race r CROSS JOIN LATERAL jsonb_array_elements(r.winners) AS w(value);

-- A winner who already holds an eligible office is seated into THAT office.
CREATE TEMP TABLE cc0496_anchor ON COMMIT DROP AS
SELECT w.race_office_id, w.politician_id, w.winner_name, e.office_id
  FROM cc0496_win w
  JOIN cc0496_elig e ON e.race_office_id = w.race_office_id
  JOIN essentials.office_current_holder och ON och.office_id = e.office_id
 WHERE w.politician_id IS NOT NULL AND och.politician_id = w.politician_id;

-- The rest fill the rest, in ballot-name order into office_id order.
CREATE TEMP TABLE cc0496_assign ON COMMIT DROP AS
WITH rest_w AS (
  SELECT w.race_office_id, w.politician_id, w.winner_name,
         row_number() OVER (PARTITION BY w.race_office_id
                            ORDER BY w.winner_name, w.politician_id::text) AS rn
    FROM cc0496_win w
   WHERE NOT EXISTS (SELECT 1 FROM cc0496_anchor a
                      WHERE a.race_office_id = w.race_office_id
                        AND a.politician_id IS NOT DISTINCT FROM w.politician_id)
), rest_o AS (
  SELECT e.race_office_id, e.office_id,
         row_number() OVER (PARTITION BY e.race_office_id ORDER BY e.office_id::text) AS rn
    FROM cc0496_elig e
   WHERE NOT EXISTS (SELECT 1 FROM cc0496_anchor a WHERE a.office_id = e.office_id)
)
SELECT a.race_office_id, a.office_id, a.politician_id, a.winner_name, true AS anchored
  FROM cc0496_anchor a
UNION ALL
SELECT r.race_office_id, o.office_id, r.politician_id, r.winner_name, false
  FROM rest_w r JOIN rest_o o ON o.race_office_id = r.race_office_id AND o.rn = r.rn;

-- The selection, in CC_0493's shape but keyed on the ASSIGNED office.
CREATE TEMP TABLE cc0496_sel ON COMMIT DROP AS
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
       a.race_office_id                                  AS race_office_id,
       och.politician_id                                 AS holder_before
  FROM cc0496_assign a
  JOIN essentials.offices   o ON o.id = a.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = a.office_id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = a.office_id
                                                AND si.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0496_pre ON COMMIT DROP AS
SELECT s.office_id, s.seat, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0496_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0496_kept ON COMMIT DROP AS
SELECT t.id AS term_id, p.full_name, d.label AS seat, d.district_type
  FROM essentials.office_terms t
  JOIN essentials.offices o     ON o.id = t.office_id
  JOIN essentials.districts d   ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = t.politician_id
 WHERE t.politician_id IN (SELECT politician_id FROM cc0496_sel)
   AND NOT EXISTS (SELECT 1 FROM cc0496_sel s WHERE s.office_id = t.office_id)
   AND t.term_end IS NULL;

CREATE TEMP TABLE cc0496_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-13')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0496_pre)                                           AS predecessors,
       (SELECT count(*) FROM cc0496_kept)                                          AS kept,
       (SELECT md5(string_agg(och.office_id::text || ':'
                              || COALESCE(och.politician_id::text, '-'),
                              '|' ORDER BY och.office_id::text))
          FROM essentials.office_current_holder och)                               AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged,
       (SELECT count(*) FROM essentials.offices_missing_terms)                     AS missing_all;

DO $$
DECLARE n bigint; d text; p record; b record; txt text;
BEGIN
  SELECT * INTO p FROM cc0496_pin;
  SELECT * INTO b FROM cc0496_before;

  -- P1 — ⚠ ASKED ABOVE EVERY COUNT. On a second run the seats have left office_pending_winner,
  -- so a count check fires first and blames the data for what is a repeat apply.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0496%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % office_terms row(s) already cite CC_0496. Applied before.', n;
  END IF;

  -- P2 — RULING A, ASSERTED PER RACE, BEFORE THE PIN AND BEFORE ANY WRITE.
  -- ───────────────────────────────────────────────────────────────────────────────────────────
  -- (a) 🔴🔴 THE EQUALITY CLAUSE. Eligible offices = winners, for every race. "At least" is what
  --     admits a staggered body, where filling "the remaining offices" would unseat sitting
  --     members with years left to serve. Maryland is not staggered; the clause is the one that
  --     makes that a measurement rather than an assumption.
  SELECT string_agg(z.seat || ' (' || z.winners || ' winners, ' || z.eligible || ' eligible)',
                    '; ' ORDER BY z.seat)
    INTO txt
    FROM (SELECT r.seat,
                 (SELECT count(*) FROM cc0496_win w WHERE w.race_office_id = r.race_office_id)
                   AS winners,
                 (SELECT count(*) FROM cc0496_elig e WHERE e.race_office_id = r.race_office_id)
                   AS eligible
            FROM cc0496_race r) z
   WHERE z.winners <> z.eligible;
  IF txt IS NOT NULL THEN
    RAISE EXCEPTION 'P2a: Ruling A''s equality clause fails for: %. A body with more eligible '
                    'seats than winners is STAGGERED, and which seats are up is not in our data '
                    'at all — such a body is seated only by naming each winner''s office from '
                    'the body''s own published term table, cited in the migration.', txt;
  END IF;
  -- (b) the interchangeability clauses, per race. ⚠ Only title and chamber_id presently
  --     discriminate anything in Maryland (seats, description and representation_note are NULL
  --     on all 141 Delegate rows and voting_powers has one distinct value); these are insurance
  --     against a future row, not checks that have ever fired. Do not read them as four
  --     independent assurances.
  SELECT string_agg(DISTINCT e.seat, '; ') INTO txt
    FROM cc0496_elig e
   WHERE e.description IS NOT NULL;
  IF txt IS NOT NULL THEN
    RAISE EXCEPTION 'P2b: eligible offices in % carry a description. A seat that describes '
                    'itself differently from its siblings is not interchangeable with them, and '
                    'a fill would claim something a voter could see is wrong.', txt;
  END IF;
  SELECT string_agg(z.seat, '; ' ORDER BY z.seat) INTO txt
    FROM (SELECT e.seat
            FROM cc0496_elig e
           GROUP BY e.race_office_id, e.seat
          HAVING count(DISTINCT COALESCE(e.seats, -1)) > 1
              OR count(DISTINCT COALESCE(e.voting_powers::text, '')) > 1
              OR count(DISTINCT COALESCE(e.representation_note, '')) > 1) z;
  IF txt IS NOT NULL THEN
    RAISE EXCEPTION 'P2c: eligible offices differ in seats, voting_powers or '
                    'representation_note in: %.', txt;
  END IF;
  -- (c) the assignment is a bijection: every winner once, every assigned office once, and no
  --     office claimed by two races.
  SELECT count(*) INTO n FROM cc0496_assign;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P2d: the assignment produced % rows for % winners.', n, p.expect_winners;
  END IF;
  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0496_assign GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2d: % office(s) were assigned more than one winner.', n;
  END IF;
  SELECT count(*) INTO n FROM (
    SELECT politician_id FROM cc0496_assign GROUP BY politician_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2d: % winner(s) were assigned more than one seat.', n;
  END IF;
  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0496_elig GROUP BY office_id HAVING count(DISTINCT race_office_id) > 1
  ) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2d: % office(s) are eligible for more than one race. Maryland''s lettered '
                    'subdistricts elect separately and must not share an eligible set.', n;
  END IF;
  -- (d) 🔴 NOBODY IS SEATED OUTSIDE THE DISTRICT THAT ELECTED THEM. This is the claim a voter
  --     would see as wrong, and it is the one Ruling A could get wrong silently.
  SELECT count(*) INTO n
    FROM cc0496_assign a
    JOIN essentials.offices ao ON ao.id = a.office_id
    JOIN essentials.offices ro ON ro.id = a.race_office_id
   WHERE ao.district_id <> ro.district_id
      OR ao.title <> ro.title
      OR ao.chamber_id IS DISTINCT FROM ro.chamber_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2e: % winner(s) were assigned to an office outside the district, chamber '
                    'or title of the race that elected them.', n;
  END IF;
  -- (e) 🔴 THE 141-SEAT STRUCTURE. Art. III § 3 gives every legislative district three Delegates;
  --     a district holding four would let a fill claim a seat nobody elected.
  SELECT count(*) INTO n FROM (
    SELECT (regexp_match(d.label, '(\d+)'))[1]::int AS dnum, count(*) AS per
      FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_LOWER'
     GROUP BY 1) z WHERE per <> 3;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2f: % Maryland legislative district(s) do not hold exactly 3 Delegate '
                    'offices (Art. III § 3). Ruling A must not run over a district whose seat '
                    'count is wrong.', n;
  END IF;

  -- P3 — the pin.
  SELECT count(*) INTO n FROM cc0496_race WHERE district_type = 'STATE_LOWER';
  IF n <> p.expect_lower_races THEN
    RAISE EXCEPTION 'P3: % Delegate races are pending, expected %. ⚠ Four Maryland Delegate '
                    'contests carried no recorded winner when this file was written (Districts '
                    '4, 6, 31 and Subdistrict 34B); if one has arrived, this wave is larger.',
      n, p.expect_lower_races;
  END IF;
  SELECT count(*) INTO n FROM cc0496_race WHERE district_type = 'STATE_UPPER';
  IF n <> p.expect_upper_races THEN
    RAISE EXCEPTION 'P3: % Senate races are pending, expected % — the whole chamber.',
      n, p.expect_upper_races;
  END IF;
  SELECT count(*) INTO n FROM cc0496_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: selection returned % winner rows, expected %. The data moved under '
                    'this file.', n, p.expect_winners;
  END IF;
  SELECT count(DISTINCT office_id) INTO n FROM cc0496_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P3: % distinct offices, expected %. Under Ruling A the winners and the '
                    'offices are equal only because every race''s eligible set is exactly the '
                    'size of its winner list — if these differ, two winners have been assigned '
                    'the same seat.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n FROM cc0496_sel WHERE district_type = 'STATE_LOWER';
  IF n <> p.expect_lower_seats THEN
    RAISE EXCEPTION 'P3: % Delegate seats in the selection, expected % of 141.',
      n, p.expect_lower_seats;
  END IF;
  SELECT count(*) INTO n FROM cc0496_sel WHERE district_type = 'STATE_UPPER';
  IF n <> p.expect_upper_seats THEN
    RAISE EXCEPTION 'P3: % Senate seats in the selection, expected %.', n, p.expect_upper_seats;
  END IF;
  -- 🔴 HOW MANY ROWS THE DIGEST EXPRESSION ACTUALLY EVALUATED. A NULL is_reelection renders the
  -- whole concatenation NULL and string_agg skips it, so the digest can cover fewer rows than
  -- every count claims. Unreachable in Maryland and gated anyway.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0496_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: the digest expression evaluated to NULL on % of % rows, so string_agg '
                    'would have skipped them. is_reelection is NULL on a seat with no current '
                    'holder — when this file was written all 178 Maryland General Assembly '
                    'seats were held, so one has fallen vacant. Read it before seating over it.',
      p.expect_winners - n, p.expect_winners;
  END IF;
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0496_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P3: selection digest is %, expected %. Every count above passed, so the '
                    'membership is the same size and something inside it changed — a winner '
                    'swapped, a seat changed hands before the handover, or RULING A ASSIGNED '
                    'SOMEBODY DIFFERENTLY. ⚠ The last of those is the Maryland-specific one: '
                    'this digest was captured by rehearsing CC_0494 + CC_0495 + a probe in one '
                    'transaction, because 55 winners cannot anchor to the seat they hold until '
                    'CC_0495 links them. If CC_0495 has not run, the assignment is a different '
                    'one and so is this hash.', d, p.expect_digest;
  END IF;
  SELECT count(*) INTO n FROM cc0496_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P3: % re-elections, expected %.', n, p.expect_reelections;
  END IF;
  SELECT count(*) INTO n FROM cc0496_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P3: % new holders, expected %. (Counted with NOT, which a NULL would fail '
                    'as well — % + % = % only if every row is a real boolean.)',
      n, p.expect_new, p.expect_reelections, p.expect_new, p.expect_winners;
  END IF;

  -- 148 anchored, 30 filled. The anchored count must equal the re-election count, because
  -- anchoring IS holding the seat you won. ⚠ This is a PIN check, not a structural one — it
  -- compares Ruling A's output against a number captured on 2026-11-23 — so it sits here with
  -- the rest of the pin rather than in P2.
  SELECT count(*) INTO n FROM cc0496_assign WHERE anchored;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P3h: % winners anchored to a seat they already hold, expected % — the same '
                    'number as the re-elections, because anchoring is holding the seat you won. '
                    'If these two ever differ, one of them is measuring something else.',
      n, p.expect_reelections;
  END IF;

  -- P4 — the date, read from office_swearing_in and never typed here.
  SELECT count(*) INTO n FROM cc0496_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. CC_0494 '
                    'writes it, FOR ALL 178 OFFICES INCLUDING THE 64 THAT CARRY NO RACE — if '
                    'this fires for roughly 64 seats, a date file was written against the '
                    'race-carrying offices only. ⚠ If a date reads 2027-01-06 somebody has '
                    'applied the FIRST Wednesday; if it reads 2027-01-20, somebody has reached '
                    'for the GOVERNOR''s day under Art. II § 1.', n, p.expect_term_start;
  END IF;
  SELECT count(*) INTO n FROM cc0496_sel
   WHERE basis IS DISTINCT FROM 'statute' AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published. An '
                    'estimate may not seat anybody.', n;
  END IF;

  -- P5 — every winner has a person row. CC_0495 links 60 and creates 25.
  SELECT count(*) INTO n FROM cc0496_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat. CC_0495 links 60 and '
                    'creates 25; if this fires, it has not run.', n;
  END IF;

  -- P6 — no seat in this wave is flagged is_vacant. A future-dated seating does not clear a
  -- flag, so a flagged state needs a companion file of the CC_0480 / CC_0486 kind; Maryland has
  -- none and needs none.
  SELECT count(*) INTO n
    FROM cc0496_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) in this wave are flagged is_vacant, expected 0.', n;
  END IF;

  -- P7 — the predecessor pre-image, which is what this file overwrites.
  SELECT count(*) INTO n FROM cc0496_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) captured, expected % — one per seat. Every '
                    'Maryland General Assembly seat in this wave was held when this file was '
                    'written.', n, p.expect_predecessors;
  END IF;
  SELECT count(*) INTO n FROM cc0496_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing, so this file would '
                    'destroy a date it has not written down.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0496_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a how_ended. seat_officeholder '
                    'COALESCEs that column, so an existing value survives.', n;
  END IF;
  -- 🔴 EXACTLY ONE PREDECESSOR IS DATED, AND IT IS AN APPOINTMENT. The other 177 are undated
  -- tenures. If more have appeared, check 2027-01-13 against them before applying.
  SELECT count(*) INTO n FROM cc0496_pre WHERE term_start IS NOT NULL;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) carry a term_start, expected exactly 1 '
                    '(Alexander M. Harlan, Subdistrict 42A, appointed 2026-08-03).', n;
  END IF;
  SELECT count(*) INTO n FROM cc0496_pre
   WHERE term_start IS NOT NULL
     AND (seat <> 'State Legislative Subdistrict 42A' OR term_start <> DATE '2026-08-03');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: the one dated predecessor is not Harlan''s 2026-08-03 appointment on '
                    'Subdistrict 42A.';
  END IF;
  SELECT count(*) INTO n
    FROM cc0496_sel s
   WHERE NOT EXISTS (SELECT 1 FROM cc0496_pre x WHERE x.office_id = s.office_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % seat(s) have no predecessor term. A seat with nobody in it is a fact '
                    'to read, not to seat over.', n;
  END IF;

  -- P8 — 🔴 THE ONE TERM A WINNER HOLDS OUTSIDE THIS WAVE, NAMED.
  SELECT count(*) INTO n FROM cc0496_kept;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P8: % open term(s) held by a winner on an office OUTSIDE this wave, '
                    'expected exactly 1 (Nicholaus R. Kipke, Delegate District 31, which this '
                    'wave cannot fill because that contest has no recorded result). Read the '
                    'extra one before seating.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0496_kept
   WHERE full_name <> 'Nicholaus R. Kipke' OR seat <> 'State Legislative District 31';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: the kept outside term belongs to somebody other than Nicholaus R. '
                    'Kipke on Delegate District 31, which is the one this file was written '
                    'about.';
  END IF;

  -- P9 — 🔴 THE FIVE CHAMBER SWITCHERS, AND WHICH OF THEM RESOLVE THEMSELVES. Four vacate a
  -- Delegate seat this wave fills; Kipke's District 31 has no recorded result, so his does not.
  SELECT count(*) INTO n
    FROM cc0496_sel sd
    JOIN essentials.office_terms t ON t.politician_id = sd.politician_id AND t.term_end IS NULL
    JOIN essentials.offices o      ON o.id = t.office_id
    JOIN essentials.districts dhd  ON dhd.id = o.district_id
                                  AND dhd.district_type = 'STATE_LOWER'
                                  AND lower(dhd.state) = 'md'
   WHERE sd.district_type = 'STATE_UPPER';
  IF n <> 5 THEN
    RAISE EXCEPTION 'P9: % Senate winner(s) currently hold a Maryland Delegate seat, expected 5 '
                    '(Alston 24, Wilson 28, Kipke 31, Chang 32, Ruff 41). If this is fewer, a '
                    'link has gone; if more, somebody else is switching and the header does not '
                    'describe them.', n;
  END IF;
  SELECT count(*) INTO n
    FROM cc0496_sel sd
    JOIN essentials.office_terms t ON t.politician_id = sd.politician_id AND t.term_end IS NULL
    JOIN essentials.offices o      ON o.id = t.office_id
    JOIN essentials.districts dhd  ON dhd.id = o.district_id
                                  AND dhd.district_type = 'STATE_LOWER'
                                  AND lower(dhd.state) = 'md'
    JOIN cc0496_sel hd             ON hd.office_id = o.id
   WHERE sd.district_type = 'STATE_UPPER'
     AND hd.politician_id <> sd.politician_id;
  IF n <> 4 THEN
    RAISE EXCEPTION 'P9: % of the 5 switchers vacate a Delegate seat this wave fills with '
                    'somebody else, expected 4. The fifth is Nicholaus Kipke — District 31 is '
                    'one of the four contests with no recorded result, so he will hold a Senate '
                    'and a Delegate seat from 2027-01-13. That is a missing result showing, not '
                    'a defect to tidy here: closing his House term would mean inventing a '
                    'successor.', n;
  END IF;

  -- P10 — 🔴 THE 2027-01-13 DELTA. Maryland was alone on this calendar day; written as a delta
  -- because Washington and Oregon were not, and "nobody else is here" expires on its own.
  IF b.terms_on_the_day <> 0 THEN
    RAISE EXCEPTION 'P10: % term(s) already begin on 2027-01-13, expected 0. If a state has '
                    'landed on Maryland''s day, name its rule before adding 178 to the pile.',
      b.terms_on_the_day;
  END IF;

  -- P11 — Ruling B: every row was called, not certified, when this was written.
  SELECT count(*) INTO n
    FROM cc0496_sel s
    JOIN essentials.office_pending_winner w ON w.office_id = s.race_office_id
   WHERE w.certainty <> 'called';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P11: % seat(s) are no longer "called". If Maryland has certified since '
                    '2026-11-23, the terms this file writes should say "certified" instead.', n;
  END IF;
END $$;

CREATE TEMP TABLE cc0496_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0496_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0496_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0496_guarded);

DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0496_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran. Confirmed candidate by '
                         || 'candidate against the Maryland State Board of Elections'' own '
                         || 'unofficial results (read 2026-11-23, 178 of 178 agree). Term '
                         || 'begins ' || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in: "A member of the General '
                         || 'Assembly shall be elected … to serve for a term of four years '
                         || 'beginning on the second Wednesday of January following his '
                         || 'election" (Md. Const. Art. III, § 6). NOTE: § 6 is the TERM. Art. '
                         || 'III § 14 puts the General Assembly''s own MEETING on the same '
                         || 'second Wednesday, and it is a different fact; the Governor''s term '
                         || 'commences a week later, on the THIRD Wednesday (Art. II § 1). '
                         || CASE WHEN r.anchored THEN
                              'Seated into the seat this member already holds. '
                            ELSE
                              'RULING A: Maryland elects up to three Delegates from one '
                              || 'multi-seat contest and the winner-to-seat mapping is not in '
                              || 'the data, so this winner was assigned to a sibling office of '
                              || 'the same district, chamber and title — one that no other '
                              || 'winner of that race already holds. The sibling seats carry no '
                              || 'separate public identity (seats, description and '
                              || 'representation_note are NULL on all 141 Delegate rows, '
                              || 'voting_powers has one value), and the race''s eligible seats '
                              || 'exactly equal its winners. See REGISTER.md Ruling A. '
                            END
                         || CASE WHEN r.is_reelection THEN 'Re-elected incumbent. '
                                 ELSE 'New holder; predecessor closed at 2027-01-12. ' END
                         || 'CC_0496',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0496: seat_officeholder called for % offices', v_seated;
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
  SELECT count(*) INTO v_planned FROM cc0496_guarded;
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
DECLARE n bigint; m text; b record; p record; v_kipke_house date; v_kipke_senate date;
BEGIN
  SELECT * INTO b FROM cc0496_before;
  SELECT * INTO p FROM cc0496_pin;

  -- 1. 🔴 THE RULING A POST-VERIFY. This joins office_terms back to the selection on office_id
  --    — which is the ASSIGNED office. Built on the race-carrying office it would look for 64
  --    terms that were never written, and would do so AFTER the write.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0496_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. the read path answers for every seat.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0496_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_offices;
  END IF;

  -- 3. the day's delta, and nobody else on it.
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
     AND NOT (lower(d.state) = 'md' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER'));
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % term(s) on % are not Maryland General Assembly terms.',
      n, p.expect_term_start;
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
    FROM essentials.office_current_holder och JOIN cc0496_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of % seats still answer office_current_holder with the person holding '
                    'them today.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0496_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % of the 178 seats answer office_current_holder with nobody, expected 0.',
      n;
  END IF;

  -- 6. every predecessor named in the pre-image closed on the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0496_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0496_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;
  -- 🔴 AND THE ONE DATED PREDECESSOR KEPT ITS START. Harlan's appointment date is the only
  -- term_start among the 178 and this file must not have moved it.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0496_pre x ON x.term_id = t.id
   WHERE t.term_start IS NOT DISTINCT FROM x.term_start;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6b: % of % closed predecessor term(s) kept the term_start they had. 177 '
                    'were NULL and one was Harlan''s 2026-08-03 appointment; this file dates '
                    'nobody''s tenure.', n, b.predecessors;
  END IF;

  -- 7. nothing closed between today and the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0496_sel s ON s.office_id = t.office_id
   WHERE t.term_end IS NOT NULL
     AND t.term_end >= CURRENT_DATE AND t.term_end < p.expect_term_start - 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % term(s) closed between today and the day before the handover.', n;
  END IF;

  -- 8. no person or office was created or destroyed.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %.', b.offices, n;
  END IF;

  -- 9. nobody landed on either wrong Wednesday — the first, or the GOVERNOR's third.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0496_sel s ON s.office_id = t.office_id
   WHERE t.term_start IN (DATE '2027-01-06', DATE '2027-01-20');
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % seat(s) start on one of the two wrong Wednesdays (2027-01-06 the '
                    'first, 2027-01-20 the GOVERNOR''s under Art. II § 1).', n;
  END IF;

  -- 10. the three Maryland state executives were not seated and are still visibly pending.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_EXEC'
     AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '10: % Maryland state executive seat(s) were seated on the General '
                    'Assembly''s date. The Governor''s term commences a week later under Art. '
                    'II § 1 and is a separate wave; the Attorney General and the Comptroller '
                    'are refused.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_EXEC'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 3 THEN
    RAISE EXCEPTION '10b: % Maryland state executive seat(s) still answer office_pending_winner, '
                    'expected 3.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND t.term_start = p.expect_term_start
     AND d.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 0 THEN
    RAISE EXCEPTION '10c: % Maryland seat(s) outside the General Assembly were seated on this '
                    'day.', n;
  END IF;

  -- 11. 🔴 THE FOUR CHAMBER SWITCHES RESOLVED THEMSELVES, AND KIPKE'S DID NOT.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN cc0496_sel s           ON s.politician_id = t.politician_id
                               AND s.district_type = 'STATE_UPPER'
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_LOWER'
     AND t.term_end = p.expect_term_start - 1;
  IF n <> 4 THEN
    RAISE EXCEPTION '11: % of the 5 switchers had their Delegate term closed at %, expected 4.',
      n, p.expect_term_start - 1;
  END IF;
  SELECT t.term_end INTO v_kipke_house
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.politician_id = '0e0bdc53-b5a2-4292-aeb7-341a4c5bed08'
     AND lower(d.state) = 'md' AND d.label = 'State Legislative District 31'
     AND d.district_type = 'STATE_LOWER';
  SELECT t.term_start INTO v_kipke_senate
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.politician_id = '0e0bdc53-b5a2-4292-aeb7-341a4c5bed08'
     AND lower(d.state) = 'md' AND d.label = 'State Senate District 31'
     AND t.term_start = p.expect_term_start;
  IF v_kipke_house IS NOT NULL OR v_kipke_senate IS DISTINCT FROM p.expect_term_start THEN
    RAISE EXCEPTION '11: Nicholaus Kipke''s Delegate District 31 term ends % (expected NULL — '
                    'that contest has no recorded result, so nobody is seated there and '
                    'seat_officeholder closes nothing) and his Senate District 31 term begins % '
                    '(expected %). He is meant to hold both from the handover; the fix is the '
                    'result, not an edit here.',
                    v_kipke_house, v_kipke_senate, p.expect_term_start;
  END IF;

  -- 12. the one kept outside term is still open — this file closes the predecessor on the seat
  --     it seats and nothing else.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0496_kept k ON k.term_id = t.id
   WHERE t.term_end IS NULL;
  IF n <> b.kept THEN
    RAISE EXCEPTION '12: % of % term(s) held by a winner on an office outside this wave are '
                    'still open.', n, b.kept;
  END IF;

  -- 13. no vacancy flag moved.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION '13: % Maryland General Assembly office(s) are flagged is_vacant.', n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '13: the repo-wide count of flagged-vacant offices moved % -> %.',
      b.vacant_all, n;
  END IF;

  -- 14. exactly 178 terms were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '14: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 15. Ruling B — every new term names the slot and says what it seated from.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0496_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0496%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '15: % of % new terms cite CC_0496.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0496_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%called, not certified%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '15: % of % new terms record that the result was called rather than '
                    'certified.', n, p.expect_offices;
  END IF;
  -- 🔴 AND EVERY RULING A FILL SAYS SO IN ITS OWN SOURCE. 30 seats were assigned rather than
  -- anchored; a reader of one of those rows must be able to find out why without this file.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0496_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND NOT s.anchored
     AND t.source LIKE '%RULING A%';
  IF n <> p.expect_new THEN
    RAISE EXCEPTION '15: % of the % assigned (non-anchored) seats record Ruling A in their own '
                    'source, expected all of them. An arbitrary-but-honest assignment that does '
                    'not say it is one cannot be audited.', n, p.expect_new;
  END IF;

  -- 16. every seat has left office_pending_winner.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0496_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '16: % seat(s) still answer office_pending_winner.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND w.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '16: % Maryland General Assembly race(s) are still pending, expected 0 — '
                    'all 114 were in this wave.', n;
  END IF;

  -- 17. the drift baseline held, and the view did not move. All 178 seats already had a term.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '17: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> b.missing_all THEN
    RAISE EXCEPTION '17: offices_missing_terms went % -> %, expected no change — all 178 seats '
                    'already carried a term row.', b.missing_all, n;
  END IF;

  RAISE NOTICE 'CC_0496 OK: 178 Maryland General Assembly members scheduled for % (% '
               're-elections, % handovers), % predecessors closed at % — 177 of them undated '
               'tenures and one an appointment (Harlan, 42A, 2026-08-03), whose start this file '
               'left alone. THE FIRST RULING A WAVE: 30 winners were assigned to a sibling '
               'office of their own district because Maryland elects up to three Delegates from '
               'one multi-seat contest, every race''s eligible seats exactly equalled its '
               'winners, and each of those 30 terms says so in its own source. The selection is '
               'keyed on the ASSIGNED office, which is what lets assertion 1 find all 178. '
               'Nobody moved today, no seat is flagged vacant, nobody landed on the first '
               'Wednesday (2027-01-06) or the GOVERNOR''s third (2027-01-20). Four chamber '
               'switches resolved themselves; ⚠ Nicholaus Kipke keeps Delegate District 31 as '
               'well as Senate District 31, because that contest has no recorded result — the '
               'fix is the result. The three state executives were NOT seated and are still '
               'visibly pending. Drift baseline % held.',
    p.expect_term_start, p.expect_reelections, p.expect_new, b.predecessors,
    p.expect_term_start - 1, b.missing_unflagged;
END $$;

COMMIT;
