-- CC_0396 — settle the 7 incumbency drift rows that CC_0394 and CC_0395 surfaced.
--
-- WHY. Master CI has been red since 2026-11-11 07:26 UTC on `check:incumbency`
-- (reconcile-incumbency.mjs --check). It reads the live database, so the failure is data, not code.
-- CC_0394 put dates on 290 tenures, and for 7 people with a race in the last year that date now
-- falls AFTER the race's election day. The check then says "this person did not hold the seat on
-- election day" while race_candidates.is_incumbent still says they did. 6 rows after CC_0394, 7
-- after CC_0395 moved Allen's mayor from "May 2026" to 2026-05-26.
--
-- 🔴 THE 7 ARE NOT ONE KIND OF ERROR, AND --apply WOULD HAVE GOT 3 OF THEM WRONG.
--
-- The snapshot CC_0394 copied (politicians.valid_from) records the start of the person's CURRENT
-- TERM. For a newcomer, term start = tenure start, and the date is right. For someone RE-ELECTED,
-- it is the start of their second (or third) term, and writing it as the tenure start says they
-- were not in office before it — which is false, and is exactly what turned the check red.
--
--   A. Newcomer — the date is right, the race row is wrong.  race_candidates.is_incumbent -> false
--   B. Re-elected — the race row is right, the date is wrong. term_start -> NULL (undated)
--
-- `--apply` reads only the predicate, so it would have flipped all 7 race rows to false and
-- published three sitting officeholders as challengers of their own seats.
--
-- ============================================================================================
-- A. NEWCOMERS — race_candidates.is_incumbent true -> false (4 rows)
-- ============================================================================================
--   Chris Schulmeister  Allen TX Mayor            election 2026-05-02, sworn 2026-05-26.
--       CC_0395: the city's calendar notice and its own report of the 26 May meeting, "newly
--       elected Mayor Chris Schulmeister".
--   Shun Thomas         Plano TX Place 7          special 2026-01-31, sworn 2026-02-09.
--       CC_0395: Plano minutes list her as "COUNCIL MEMBER ELECT" at 4 PM and present at 7 PM.
--   J.T. Trevino        St. Paul TX Mayor         election 2026-05-02 (cancelled, unopposed).
--       Town Resolution 26-01-12-B, 12 Jan 2026, ordering this election, is signed by
--       "Kent Swaner, Mayor". Trevino did not hold the mayoralty on election day.
--   Kristen Bewley      St. Paul TX Place 4       SPECIAL election 2026-05-02 (cancelled, unopposed).
--       Town Secretary Scott L. Albert's Certification of Unopposed Candidates (Form 13-1, signed
--       4 Mar 2026) lists "Special Election — Town Council Place No. 4 — Kristen Bewley". A special
--       election fills a seat its winner does not hold.
--
-- Their CC_0394/CC_0395 start dates stand.
--
-- ============================================================================================
-- B. RE-ELECTED — office_terms.term_start -> NULL, start_precision -> 'unknown' (3 rows)
-- ============================================================================================
--   Jim Atchison        Van Alstyne TX Mayor      CC_0394 wrote 2026-05-03 (day).
--       Re-elected 2 May 2026 over Kevin Soucie (Grayson County official summary). The city's own
--       site says he was sworn in as mayor on 23 June 2020. 2026-05-03 is the day after the
--       election and a Sunday — the same shape as the wrong Allen date CC_0395 caught.
--       ⚠ NOT dated to 2020-06-23 here: that page was reached only through a search summary, not
--       read. Undated is true; a day nobody here read is not.
--   Robert Simmons      St. Paul TX Place 5       CC_0394 wrote 2026-06-01 (month).
--   Gregory Pierson     St. Paul TX Place 3       CC_0394 wrote 2026-06-01 (month).
--       The town's elected-officials page lists both with "Term expires June 2028", and Resolution
--       26-01-12-B orders Places 3 and 5 "for two-year terms" — so June 2026 is the start of the
--       TERM they were just returned to, not evidence of when either first took the seat.
--       Simmons was sitting before the election: he moved the 9 Mar 2026 motion that cancelled it.
--       ⚠ Pierson's prior service is NOT independently confirmed. Undating him restores the state
--       before CC_0394 and makes no new claim; his race row keeps the value it was imported with.
--
-- 🔴 NOT tagged '| unverified' (CA_0171) — that tag makes office_holders_as_of SKIP the term and
-- would delete a sitting officeholder from every historical query. Only the date is unknown, which
-- is what term_start NULL means.
--
-- ============================================================================================
-- THE OVERWRITE RECORD (there is no history table)
-- ============================================================================================
--   race_candidates.is_incumbent  true -> false            4 rows, ids below
--   office_terms.term_start       2026-05-03 / 2026-06-01 -> NULL   3 rows
--   office_terms.start_precision  day / month -> unknown   3 rows
--   office_terms.source           APPENDED to, never replaced
--
-- 🔴 FOLLOW-UP, NOT DONE HERE: the same mechanism can have mis-dated any re-elected officeholder
-- among CC_0394's 290 rows. The check only sees the ones with a race in the last year.
--
-- Idempotent: every write is guarded on the value it changes.
--
-- Applied to production 2026-11-11: 4 race rows -> false, 3 tenures undated. check:incumbency
-- then read 0 drift rows, and control-reconcile-incumbency.mjs passed.

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- A. Newcomers: race rows.
-- ---------------------------------------------------------------------------------------------
CREATE TEMP TABLE cc0396_race (
  race_candidate_id uuid PRIMARY KEY,
  politician_id     uuid NOT NULL,
  who               text NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0396_race VALUES
 ('5f49e3c4-3bbe-490a-af81-a9981f25eac8','698da6ca-eadd-46a0-8e27-94ae48d23279','Chris Schulmeister'),
 ('84fafa28-b4b6-4c59-bd3c-476d40e1f0f5','4272e5cb-40cf-42d9-a493-ae5ca04301bb','Shun Thomas'),
 ('8f063ab0-148d-4c56-9c2f-4366ccb6faba','8dd71c1c-dea7-4fd9-bc52-39d4002ff537','J.T. Trevino'),
 ('a05029b6-f101-4442-b7d4-2acec223bc44','008565fa-5704-4bba-aaf6-a5d94ee3a875','Kristen Bewley');

-- ---------------------------------------------------------------------------------------------
-- B. Re-elected: tenures to return to undated.
-- ---------------------------------------------------------------------------------------------
CREATE TEMP TABLE cc0396_term (
  office_id     uuid NOT NULL,
  politician_id uuid NOT NULL,
  who           text NOT NULL,
  was_start     date NOT NULL,
  citation      text NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0396_term VALUES
 ('36b21fe7-aba9-4e9b-a992-609b926b82a8','4e7bc81e-1b24-4113-a839-3d87a2637df1','Jim Atchison','2026-05-03',
  'Re-elected Van Alstyne mayor 2 May 2026 (Grayson County official summary); in office since 2020. The CC_0394 date was the day after the election, the start of his new term, not of his tenure'),
 ('ab82bfa0-2eca-4692-ae1e-7dacdd4e4405','4e17eda5-157c-42e4-832e-3a12d4b2069e','Robert Simmons','2026-06-01',
  'St. Paul TX Place 5, returned unopposed for a two-year term (Resolution 26-01-12-B; town page: term expires June 2028). June 2026 is the start of that term; he was already seated and moved the 9 Mar 2026 motion cancelling the election'),
 ('df365965-c49c-4a81-ab1a-1d18bb4c876b','4fd0877c-447d-4950-911d-d73b9b9b1ad1','Gregory Pierson','2026-06-01',
  'St. Paul TX Place 3, returned unopposed for a two-year term (Resolution 26-01-12-B; town page: term expires June 2028). June 2026 is the start of that term, not evidence of when he first took the seat');

-- ---------------------------------------------------------------------------------------------
-- Pre-gate: every id names the person it claims, and every row is still in the state measured.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_bad int;
BEGIN
  SELECT count(*) INTO v_bad
    FROM cc0396_race pl
    LEFT JOIN essentials.race_candidates rc ON rc.id = pl.race_candidate_id
                                           AND rc.politician_id = pl.politician_id
   WHERE rc.id IS NULL;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0396 pre-gate: % race row(s) do not match their politician', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
    FROM cc0396_term pl
   WHERE (SELECT count(*) FROM essentials.office_terms ot
           WHERE ot.office_id = pl.office_id AND ot.politician_id = pl.politician_id
             AND ot.term_end IS NULL) <> 1;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0396 pre-gate: % planned tenure(s) do not resolve to exactly one open term', v_bad;
  END IF;

  -- Only overwrite a date CC_0394 wrote, and only the value it wrote (or NULL on a re-run).
  SELECT count(*) INTO v_bad
    FROM cc0396_term pl
    JOIN essentials.office_terms ot
      ON ot.office_id = pl.office_id AND ot.politician_id = pl.politician_id AND ot.term_end IS NULL
   WHERE ot.source NOT LIKE '%CC_0394: term_start%'
      OR (ot.term_start IS NOT NULL AND ot.term_start <> pl.was_start);
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0396 pre-gate: % tenure(s) are not in the state CC_0394 left them', v_bad;
  END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
-- Write.
-- ---------------------------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET is_incumbent = false
  FROM cc0396_race pl
 WHERE rc.id = pl.race_candidate_id
   AND rc.is_incumbent IS DISTINCT FROM false;

UPDATE essentials.office_terms ot
   SET term_start      = NULL,
       start_precision = 'unknown',
       source          = ot.source || ' | CC_0396: term start RETURNED TO UNDATED. ' || pl.citation || '.'
  FROM cc0396_term pl
 WHERE ot.office_id = pl.office_id
   AND ot.politician_id = pl.politician_id
   AND ot.term_end IS NULL
   AND ot.term_start IS NOT NULL;

-- ---------------------------------------------------------------------------------------------
-- Post-gate, on the end state.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_bad int;
BEGIN
  SELECT count(*) INTO v_bad
    FROM cc0396_race pl JOIN essentials.race_candidates rc ON rc.id = pl.race_candidate_id
   WHERE rc.is_incumbent IS DISTINCT FROM false;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0396 gate: % race row(s) are still marked incumbent', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
    FROM cc0396_term pl
    JOIN essentials.office_terms ot
      ON ot.office_id = pl.office_id AND ot.politician_id = pl.politician_id AND ot.term_end IS NULL
   WHERE ot.term_start IS NOT NULL
      OR ot.start_precision <> 'unknown'
      OR ot.source NOT LIKE '%CC_0394: term_start%'
      OR ot.source NOT LIKE '%CC_0396:%';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0396 gate: % tenure(s) are not undated with provenance intact', v_bad;
  END IF;

  -- The officeholders are still officeholders: undating must not unseat anyone.
  SELECT count(*) INTO v_bad
    FROM cc0396_term pl
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                      WHERE och.office_id = pl.office_id AND och.politician_id = pl.politician_id);
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0396 gate: % undated officeholder(s) no longer resolve as current', v_bad;
  END IF;
END $$;

COMMIT;
