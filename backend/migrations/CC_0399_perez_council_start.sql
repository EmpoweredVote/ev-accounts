-- CC_0399 — undate Jennifer Perez's Norwalk tenure start (the rotating-mayor ruling).
--
-- WHY. CC_0394 copied politicians.valid_from onto Perez's open "Mayor" tenure as 2017-03-07. That is
-- the day of her first Norwalk City Council election. CC_0397 and CC_0398 left the three rotating
-- mayors (Takahashi, Burbank; Kassakhian, Glendale; Perez, Norwalk) for a ruling, because in our data
-- "Mayor" is one of each city's five council offices and the stored start is the council start.
--
-- RULING (user, 2026-11-11): a rotating mayor's tenure means their COUNCIL SERVICE. The office is a
-- council seat whose holder currently chairs. So Takahashi (sworn 19 Dec 2022, stored Dec 2022) and
-- Kassakhian (oath 31 Mar 2020, stored 17 Mar 2020) stay as they are: right to the month, or two weeks
-- early, the same near-match CC_0397 left alone.
--
-- PEREZ IS THE ONE THAT CHANGES. She won on 7 Mar 2017 and the Norwalk Patriot reported her oath on
-- 12 Apr 2017 ("officially sworn in Tuesday evening"). A day-precision value on election day claims
-- she held the seat before she took the oath. The oath day is not sourced to the day, so she is
-- UNDATED (CC_0397's rule), not re-dated. She stays seated: a NULL start is open-ended.
--
-- NOT tagged '| unverified' (CA_0171). Previous value is in the plan below. Idempotent.
--
-- Applied to production 2026-11-11: 1 tenure undated. check:incumbency then read 0 drift rows,
-- control-reconcile-incumbency.mjs passed, and check:seating held.

BEGIN;

CREATE TEMP TABLE cc0399_plan (
  term_id     uuid PRIMARY KEY,
  who         text NOT NULL,
  seat        text NOT NULL,
  was_start   date NOT NULL,
  was_prec    text NOT NULL,
  new_start   date,
  new_prec    text NOT NULL,
  kind        text NOT NULL CHECK (kind IN ('reelected','too_early')),
  citation    text NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0399_plan VALUES
 ('ffb1fe58-a149-4cf0-941e-7080b90e8e97','Jennifer Perez','Norwalk Mayor','2017-03-07','day',NULL,'unknown','too_early','Stored 2017-03-07 is the day of her first council election; she was sworn in the following month ("Margarita Rios, Jennifer Perez and Tony Ayala were all officially sworn in Tuesday evening", Norwalk Patriot, 12 Apr 2017, https://thenorwalkpatriot.com/news/2017/4/12/perez-rios-and-ayala-sworn-into-office-vernola-selected-as-new-mayor). Rotating-mayor ruling 2026-11-11: this tenure means her council service, so it starts at that oath; the exact day is not sourced');

CREATE TEMP TABLE cc0399_race (
  race_candidate_id uuid PRIMARY KEY,
  term_id           uuid NOT NULL,
  who               text NOT NULL
) ON COMMIT DROP;

-- (no race rows: Perez has no race_candidates rows)

-- ---------------------------------------------------------------------------------------------
-- Pre-gate.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_bad int;
BEGIN
  IF (SELECT count(*) FROM cc0399_plan) <> 1 THEN
    RAISE EXCEPTION 'CC_0399 pre-gate: plan holds % rows, expected 1', (SELECT count(*) FROM cc0399_plan);
  END IF;

  -- Each row is an open tenure CC_0394 dated, held by the named person, still at the measured value
  -- (or already at the target, on a re-run).
  SELECT count(*) INTO v_bad
    FROM cc0399_plan pl
    LEFT JOIN essentials.office_terms ot ON ot.id = pl.term_id AND ot.term_end IS NULL
    LEFT JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE ot.id IS NULL
      OR p.full_name IS DISTINCT FROM pl.who
      OR ot.source NOT LIKE '%CC_0394: term_start%'
      OR NOT ( (ot.term_start = pl.was_start AND ot.start_precision = pl.was_prec)
            OR (ot.term_start IS NOT DISTINCT FROM pl.new_start AND ot.start_precision = pl.new_prec) );
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0399 pre-gate: % plan row(s) do not match the tenure they name', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
    FROM cc0399_plan
   WHERE (new_start IS NULL) <> (new_prec = 'unknown')
      OR (kind = 'reelected' AND new_start IS NOT NULL)
      OR (new_start IS NOT NULL AND new_start <= was_start)
      OR (new_prec = 'year'  AND to_char(new_start, 'MM-DD') <> '01-01')
      OR (new_prec = 'month' AND extract(day FROM new_start) <> 1);
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0399 pre-gate: % plan row(s) are internally inconsistent', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
    FROM cc0399_race r
    LEFT JOIN essentials.office_terms ot ON ot.id = r.term_id
    LEFT JOIN essentials.race_candidates rc ON rc.id = r.race_candidate_id
                                           AND rc.politician_id = ot.politician_id
   WHERE rc.id IS NULL;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0399 pre-gate: % race row(s) do not belong to the planned tenure', v_bad;
  END IF;
END $$;

-- Every person whose office_terms row this writes. No seating happens here and no predecessor term
-- is closed, so the plan's own holders are BOTH sides of every write.
CREATE TEMP TABLE cc0399_people ON COMMIT DROP AS
SELECT DISTINCT ot.politician_id
  FROM cc0399_plan pl JOIN essentials.office_terms ot ON ot.id = pl.term_id;

-- ▼▼ BLOCK A — PASTE BEFORE YOUR FIRST WRITE TO essentials.office_terms ▼▼

-- @incumbency-decision: gated — NULLs term_start on 1 CC_0394-dated open tenure (Jennifer Perez, Norwalk); no seating, no predecessor closed, no race rows

-- Snapshot what the cached column says, and what office_terms says, for every race row belonging to
-- a person this migration touches. `expected` is reconcile-incumbency.mjs's own SQL.
--
-- ⚠ KEEP THE `expected` EXPRESSION AND THE THREE WHERE CLAUSES CHARACTER-IDENTICAL TO THE SCRIPT
-- (backend/scripts/reconcile-incumbency.mjs, computeIncumbencyDrift). If they drift apart, this
-- passes while CI fails, which is worse than having no guard — you would then believe the question
-- had been asked.
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
   AND rc.politician_id IN (SELECT politician_id FROM cc0399_people);

-- 🔴 `o2` IS THE SCRIPT'S OWN ALIAS AND IT IS A TRAP. Never write `o2.politician_id` anywhere near
-- this block. `check:occupancy` reads `o<digits>.politician_id` as the dropped essentials.offices
-- column — that is the repo's offices alias convention — and CC_0394 turned the "static guards" job
-- red on exactly that. Here `o2` is only ever read for `chamber_id`, which is safe. Rename it to
-- something not starting with `o` if you need any other column off it.

-- ▲▲ END OF BLOCK A ▲▲

-- ---------------------------------------------------------------------------------------------
-- Write.
-- ---------------------------------------------------------------------------------------------
UPDATE essentials.office_terms ot
   SET term_start      = pl.new_start,
       start_precision = pl.new_prec,
       source          = ot.source || ' | CC_0399: '
                         || CASE WHEN pl.new_start IS NULL
                                 THEN CASE pl.kind WHEN 'reelected' THEN 'term start RETURNED TO UNDATED, because this person held the seat before the CC_0394 date (that date is a later term''s start). ' ELSE 'term start RETURNED TO UNDATED, because this person took the seat AFTER the CC_0394 date and no oath record gives the day. ' END
                                 ELSE 'term start moved to ' || to_char(pl.new_start, 'YYYY-MM-DD')
                                      || ' (' || pl.new_prec || ' precision); the CC_0394 date was before this person took the seat; the new date is the oath or term-start day in the source. ' END
                         || pl.citation || '.'
  FROM cc0399_plan pl
 WHERE ot.id = pl.term_id
   AND (ot.term_start IS DISTINCT FROM pl.new_start OR ot.start_precision IS DISTINCT FROM pl.new_prec);

UPDATE essentials.race_candidates rc
   SET is_incumbent = false
  FROM cc0399_race r
 WHERE rc.id = r.race_candidate_id
   AND rc.is_incumbent IS DISTINCT FROM false;

-- ▼▼ BLOCK B — PASTE AFTER YOUR LAST WRITE TO essentials.office_terms, BEFORE COMMIT ▼▼

DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM cc0399_people;
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;

  -- 🔴 AN EMPTY SCOPE PASSES EVERYTHING BELOW VACUOUSLY, AND IT HAS TWO OPPOSITE CAUSES. Either
  -- nobody you touched has run recently — the common, correct case — or your plan table is not the
  -- one the scope subquery reads, in which case this gate is switched off and looks identical.
  -- Counting the PLAN separately is what tells them apart: "4 planned, 0 with a race" is the first,
  -- "0 planned" is the second. Reading `incumbency_before` alone cannot distinguish them, which is
  -- how an earlier draft of this template reported a deliberately mis-pointed plan as fine.
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

-- ---------------------------------------------------------------------------------------------
-- Post-gate, on the end state.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_bad int;
BEGIN
  SELECT count(*) INTO v_bad
    FROM cc0399_plan pl JOIN essentials.office_terms ot ON ot.id = pl.term_id
   WHERE ot.term_start IS DISTINCT FROM pl.new_start
      OR ot.start_precision IS DISTINCT FROM pl.new_prec
      OR ot.source NOT LIKE '%CC_0394: term_start%'
      OR ot.source NOT LIKE '%CC_0399:%';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0399 gate: % tenure(s) do not carry the planned value with provenance intact', v_bad;
  END IF;

  -- Nobody is unseated: every planned holder still resolves as the current holder.
  SELECT count(*) INTO v_bad
    FROM cc0399_plan pl JOIN essentials.office_terms ot ON ot.id = pl.term_id
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                      WHERE och.office_id = ot.office_id AND och.politician_id = ot.politician_id);
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0399 gate: % officeholder(s) no longer resolve as current', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
    FROM cc0399_race r JOIN essentials.race_candidates rc ON rc.id = r.race_candidate_id
   WHERE rc.is_incumbent IS DISTINCT FROM false;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0399 gate: % race row(s) still marked incumbent', v_bad;
  END IF;
END $$;

COMMIT;
