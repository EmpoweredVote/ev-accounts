-- CC_0412 — Santa Cruz County, Supervisor 4th District: seat Tony Nuñez at the STATUTORY
--            2027-01-04 and close Felipe Hernandez the day before, `defeated`.
--
-- This is the authorized successor to CC_0405's post-condition, which asserts that this seat
-- holds Felipe Hernandez BY NAME so that seating a successor early would fail the migration
-- rather than ship. That guard did its job. It was written on 2026-11-11, when the handover
-- date looked like an unknown "January 2027"; the date turns out to be fixed by statute, and
-- the operator authorized this seating on 2026-11-13 knowing that. ⚠ A REPLAY of CC_0405
-- after this file would now find two term rows on this office and its `SELECT ... INTO` would
-- read whichever came first. Migrations are not replayed here, but say so rather than leave it.
--
-- ── WHY A FUTURE DATE IS SAFE, AND WHY IT IS BETTER THAN WAITING ───────────────────────────
-- Occupancy is decided by DATES, not by a flag. `essentials.current_office_holders` filters
--     (term_start IS NULL OR term_start <= CURRENT_DATE)
-- AND (term_end   IS NULL OR term_end   >= CURRENT_DATE)
-- so after this migration, and until 2027-01-03 inclusive, the seat still resolves to
-- Hernandez — his term_end is 2027-01-03 and Nuñez's term_start is in the future. At midnight
-- on 2027-01-04 the seat flips to Nuñez with no further migration, no cron and nobody
-- remembering. That is the same shape as the reserved CC_0340 (US Senate winners at
-- 2027-01-03). The post-conditions below assert BOTH sides of that boundary explicitly.
--
-- 🔑 THERE IS NO SECOND GATE TO SET ANY MORE. The old advice for a departure was "set term_end
-- AND clear politicians.is_incumbent", because an incumbents-only flat list filtered that
-- column with no occupancy join. **`politicians.is_incumbent` NO LONGER EXISTS — CA_0378
-- dropped it**, and no service reads a per-person incumbency flag today (checked). So the date
-- is the whole of it, which is precisely what makes a future-dated row honest: there is no
-- boolean that would have to be wrong on one side of the boundary.
--
-- ── THE DATE, AND WHERE IT COMES FROM ──────────────────────────────────────────────────────
-- California Government Code § 24200, CURRENT text (updated 2026-01-01... see note), reads:
--
--   "Except as otherwise provided, all elective county officers shall be elected at the
--    election specified pursuant to Section 1300 of the Elections Code and take office at
--    12 o'clock noon on the first Monday after the January 1 succeeding their election."
--
-- ⚠ Read the CURRENT text, not an older mirror: § 24200 was amended by AB 759 effective
-- 2023-01-01, and the pre-2023 wording is what most search results surface. The text above is
-- the post-amendment version (verified 2026-11-13).
-- ⚠ "Except as otherwise provided" is doing real work: a CHARTER county could provide its own
-- date. **Santa Cruz County is a GENERAL LAW county**, so § 24200 controls unmodified.
-- Elected 2026-06-02 → the January 1 succeeding that election is 2027-01-01, a Friday → the
-- first Monday after it is **2027-01-04**. `start_precision` is therefore 'day', not 'month'.
-- (The statute says noon; `office_terms` is day-grained, so the row says the day.)
--
-- ── THE RESULT, FROM THE CERTIFIED CANVASS ─────────────────────────────────────────────────
-- Santa Cruz County, California Primary Election June 2, 2026, **-Official Results-**, as of
-- 6/26/2026 2:00 PM. Supervisor, 4th District (Vote for 1):
--
--     Tony Nuñez          3,944   50.07%
--     Felipe Hernandez    2,429   30.84%
--     Elias Gonzales      1,450   18.41%
--     Write-in               54
--                         ─────
--     Total               7,877      (2,429 + 3,944 + 1,450 + 54 = 7,877 — reconciles exactly)
--
-- A majority of 7,877 is 3,939, so Nuñez cleared the outright-win line with FIVE votes to
-- spare and no November runoff was held for this seat. That is why a June primary result
-- seats a supervisor at all, and it is why this is a `defeated` close rather than
-- `term_expired`: the sitting supervisor was on that ballot and lost it.
--
-- 🔑 THE COUNTY HAS ARCHIVED THE JUNE PAGE AWAY. `votescount.santacruzcountyca.gov` now lists
-- only the November 2026 general under "Past elections", and the live results endpoint serves
-- the November contest. The certified June canvass was read through the Wayback Machine
-- (snapshot 20260713063215 of the county's own results endpoint), which is the page that says
-- "-Official Results-". An EARLIER snapshot (20260619233830) still says "-Unofficial Results-"
-- and carries different numbers — 3,939 / 2,423 / 1,447. Do not cite that one: it is a
-- mid-canvass count that happens to look almost identical.
-- ⚠ The ballot name carries a TILDE: the county renders it `Tony Nu&#241;ez` = "Tony Nuñez".
-- Every existing database row spelling it "NUNEZ" is a CAMPAIGN COMMITTEE, not the person.
--
-- ── WHY A PERSON ROW HAS TO BE CREATED ─────────────────────────────────────────────────────
-- Tony Nuñez does not exist in `essentials.politicians`. The only matches are
-- campaign-finance committees — `NUNEZ FOR COUNTY SUPERVISOR 2026; TONY` — which are
-- `is_active = false`, hold no office and belong to no government. ~77,000 of ~85,000 rows in
-- that table are committees, so a name LIKE over it finds one almost every time; the insert
-- below is guarded on `source LIKE 'CC_0412 %'` and the post-conditions assert that exactly
-- one NON-committee person carries the name.
--
-- @incumbency-decision: gated — closes Hernandez's term at 2027-01-03 and opens Nuñez's at
-- 2027-01-04 on Supervisor, 4th District; the gate below is in this migration.
--
-- 🔑 WHAT THE GATE WILL SAY, AND WHY THAT IS NOT A VACUOUS PASS. This office has ZERO races
-- and ZERO race_candidates rows in the database (measured 2026-11-13), so the guard will
-- report "2 person/people planned, 0 with a race row in the last year". That is the template's
-- FIRST case — nobody touched has run recently — and it is distinguishable from a
-- mis-pointed plan only because the PLAN count is 2 rather than 0. It is emphatically NOT a
-- `no-effect`: "there are probably no recent races" is the guess this gate exists to replace
-- with a number.
--
-- Applied as `postgres` over the supabase-local MCP (the only role that can CREATE), verified
-- on row counts, never on the absence of an error.

BEGIN;

-- ── The plan: every politician whose office_terms rows this migration writes. BOTH SIDES of
-- the seating — the arriving supervisor AND the predecessor whose term seat_officeholder
-- closes for us.
CREATE TEMP TABLE nunez_plan (politician_id uuid, role text) ON COMMIT DROP;

-- The person row for the incoming supervisor, created only if this migration has not already
-- created it. Name form from the county's certified canvass, tilde included.
INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, source)
SELECT 'Tony Nuñez', 'Tony', 'Nuñez', true,
       'CC_0412 Santa Cruz County certified canvass, California Primary Election June 2, 2026, Supervisor 4th District'
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p WHERE p.source LIKE 'CC_0412 %');

INSERT INTO nunez_plan (politician_id, role)
SELECT p.id, 'successor' FROM essentials.politicians p WHERE p.source LIKE 'CC_0412 %';

INSERT INTO nunez_plan (politician_id, role)
SELECT t.politician_id, 'predecessor'
  FROM essentials.office_terms t
 WHERE t.office_id = 'b452f44b-5fea-4015-9fe5-f79b963cc0e4'
   AND t.politician_id IS NOT NULL;

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM nunez_plan;
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CC_0412 pre: expected exactly 2 planned people (predecessor + successor), got %', v_n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM nunez_plan WHERE role = 'successor') THEN
    RAISE EXCEPTION 'CC_0412 pre: no successor row — the person insert did not take';
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- ▼▼ BLOCK A — incumbency guard, snapshot BEFORE the write ▼▼
-- `expected` and the three WHERE clauses are character-identical to
-- backend/scripts/reconcile-incumbency.mjs (computeIncumbencyDrift). Do not "tidy" them.
-- `o2` is the script's own alias and is read ONLY for chamber_id — `check:occupancy` reads
-- `o<digits>.politician_id` as the dropped offices column and would turn static guards red.
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
   AND rc.politician_id IN (SELECT politician_id FROM nunez_plan);
-- ▲▲ END OF BLOCK A ▲▲
-- ═══════════════════════════════════════════════════════════════════════════════════════════

-- The seating itself. seat_officeholder closes the covering term at p_term_start - 1 and sets
-- its how_ended via COALESCE, so Hernandez's currently-NULL how_ended becomes 'defeated'.
-- p_allow_reelection stays false: a different person is arriving, and if the office somehow
-- already held Nuñez this must RAISE rather than quietly open a second term.
DO $$
DECLARE v_new uuid;
BEGIN
  SELECT essentials.seat_officeholder(
           'b452f44b-5fea-4015-9fe5-f79b963cc0e4'::uuid,
           (SELECT politician_id FROM nunez_plan WHERE role = 'successor'),
           DATE '2027-01-04',
           'Santa Cruz County certified canvass, California Primary Election June 2, 2026 '
           '(-Official Results- 6/26/2026): Tony Nuñez 3,944 of 7,877 (50.07%), elected '
           'outright. Term start per Cal. Gov. Code 24200 — noon on the first Monday after '
           'the January 1 succeeding the election.',
           'elected',
           'day',
           'defeated',
           false)
    INTO v_new;
  IF v_new IS NULL THEN
    RAISE EXCEPTION 'CC_0412: seat_officeholder returned NULL';
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- ▼▼ BLOCK B — incumbency guard, compare AFTER the write ▼▼
DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM nunez_plan;
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
-- ▲▲ END OF BLOCK B ▲▲
-- ═══════════════════════════════════════════════════════════════════════════════════════════

-- ── POST-CONDITIONS. Both sides of the 2027-01-04 boundary, asserted separately, because the
-- whole claim of this migration is that the seat is Hernandez's today and Nuñez's in January.
DO $$
DECLARE
  v_rows     int;
  v_today    text;
  v_jan      text;
  v_prev_end date;
  v_prev_how text;
  v_new_st   date;
  v_prec     text;
  v_how      text;
  v_people   int;
BEGIN
  SELECT count(*) INTO v_rows FROM essentials.office_terms
   WHERE office_id = 'b452f44b-5fea-4015-9fe5-f79b963cc0e4';
  IF v_rows <> 2 THEN
    RAISE EXCEPTION 'CC_0412 post: Supervisor 4th District has % term row(s), expected 2', v_rows;
  END IF;

  -- TODAY the seat is still the sitting supervisor's.
  SELECT p.full_name INTO v_today
    FROM essentials.office_terms t JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.office_id = 'b452f44b-5fea-4015-9fe5-f79b963cc0e4'
     AND (t.term_start IS NULL OR t.term_start <= CURRENT_DATE)
     AND (t.term_end   IS NULL OR t.term_end   >= CURRENT_DATE);
  IF v_today IS DISTINCT FROM 'Felipe Hernandez' THEN
    RAISE EXCEPTION 'CC_0412 post: the seat resolves to "%" TODAY, expected the sitting '
                    'supervisor Felipe Hernandez — a future-dated successor must not displace '
                    'him before 2027-01-04', coalesce(v_today, '(nobody)');
  END IF;

  -- ON 2027-01-04 it is the successor's, and nobody else's.
  SELECT p.full_name INTO v_jan
    FROM essentials.office_terms t JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.office_id = 'b452f44b-5fea-4015-9fe5-f79b963cc0e4'
     AND (t.term_start IS NULL OR t.term_start <= DATE '2027-01-04')
     AND (t.term_end   IS NULL OR t.term_end   >= DATE '2027-01-04');
  IF v_jan IS DISTINCT FROM 'Tony Nuñez' THEN
    RAISE EXCEPTION 'CC_0412 post: on 2027-01-04 the seat resolves to "%", expected Tony Nuñez',
                    coalesce(v_jan, '(nobody)');
  END IF;

  SELECT t.term_end, t.how_ended INTO v_prev_end, v_prev_how
    FROM essentials.office_terms t JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.office_id = 'b452f44b-5fea-4015-9fe5-f79b963cc0e4' AND p.full_name = 'Felipe Hernandez';
  IF v_prev_end IS DISTINCT FROM DATE '2027-01-03' THEN
    RAISE EXCEPTION 'CC_0412 post: predecessor term_end is %, expected 2027-01-03 (day-adjacent: '
                    'office_terms_no_overlap uses INCLUSIVE bounds, so a same-day handover is '
                    'rejected)', v_prev_end;
  END IF;
  IF v_prev_how IS DISTINCT FROM 'defeated' THEN
    RAISE EXCEPTION 'CC_0412 post: predecessor how_ended is "%", expected "defeated" — he was on '
                    'the June ballot and lost it', coalesce(v_prev_how, '(null)');
  END IF;

  SELECT t.term_start, t.start_precision, t.how_started INTO v_new_st, v_prec, v_how
    FROM essentials.office_terms t JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.office_id = 'b452f44b-5fea-4015-9fe5-f79b963cc0e4' AND p.full_name = 'Tony Nuñez';
  IF v_new_st IS DISTINCT FROM DATE '2027-01-04' THEN
    RAISE EXCEPTION 'CC_0412 post: successor term_start is %, expected the statutory 2027-01-04', v_new_st;
  END IF;
  IF v_prec IS DISTINCT FROM 'day' THEN
    RAISE EXCEPTION 'CC_0412 post: successor start_precision is "%", expected "day" — the statute '
                    'fixes the day, so imprecision would be invented', v_prec;
  END IF;
  IF v_how IS DISTINCT FROM 'elected' THEN
    RAISE EXCEPTION 'CC_0412 post: successor how_started is "%", expected "elected"', v_how;
  END IF;

  -- Exactly one NON-COMMITTEE person carries the name. The committees stay as they are.
  SELECT count(*) INTO v_people FROM essentials.politicians p
   WHERE p.full_name = 'Tony Nuñez';
  IF v_people <> 1 THEN
    RAISE EXCEPTION 'CC_0412 post: % row(s) named "Tony Nuñez", expected exactly 1 — the rest of '
                    'that name space is campaign committees and must stay that way', v_people;
  END IF;
END $$;

COMMIT;
