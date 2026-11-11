-- CC_0400 — bring the Indiana Utility Regulatory Commission up to date.
--
-- WHY. Our five IURC seats still showed the January 2026 board: Andy Zay as Chairman and David
-- Veleta as a commissioner. Both are gone, and the two people who replaced them were not in the
-- database at all. Found while settling CC_0397's follow-ups (PR #1388).
--
-- WHAT HAPPENED, from the commission's own pages and the Indiana Capital Chronicle (read in full):
--   2026-06-22  Anthony Swinger "named Chairman on June 22, 2026" (in.gov/iurc, Swinger's page).
--               Zay was demoted and "remains on the panel" (Capital Chronicle, 30 Jun 2026).
--   2026-06-26  Veleta's letter: "resign ... effective August 31, 2026, or sooner should my
--               replacement be ready to serve" (Capital Chronicle, 30 Jun 2026).
--   2026-08-03  "Zay was discharged from employment with the State of Indiana today, August 3, 2026"
--               (IURC spokesman, Capital Chronicle, 3 Aug 2026). A 22 Aug settlement ended his suit
--               for reinstatement.
--   2026-08-06  "Joshua Bain was appointed to the Commission on Aug. 6, 2026, by Governor Mike
--               Braun" (in.gov/iurc, Bain's page). He fills the seat Zay's firing left open.
--   2026-08-17  "Joby D. Jerrells was appointed to the Commission on Aug. 17, 2026" (in.gov/iurc).
--               "Jerrells ... will replace outgoing Commissioner David Veleta" (Capital Chronicle,
--               23 Jul 2026). His term expires Jan. 31, 2028, the end of Veleta's term.
-- The commission's page today lists Swinger (Chairman), Bain, Deig, Jerrells and Ziegner.
--
-- HOW IT IS MODELLED. Our IURC has one "Chairman" office and four "Utility Regulatory Commissioner"
-- offices. The chair is a designation, so the Chairman office follows it:
--   Chairman                 Zay 2026-01-12..2026-06-21  ->  Swinger from 2026-06-22
--   commissioner (Swinger's) Swinger ..2026-06-21  ->  Zay 2026-06-22..2026-08-03  ->  Bain from 2026-08-06
--   commissioner (Veleta's)  Veleta ..2026-08-16  ->  Jerrells from 2026-08-17
--   commissioner (Deig's), commissioner (Ziegner's)  unchanged
-- Zay's last day is 3 Aug (discharged "today"), so the seat is vacant 4-5 Aug; vacate_office is
-- given the first vacant day (CLAUDE.md: vacant_since is departure + 1), and the flag is cleared
-- when Bain is seated, because seat_officeholder does not clear it.
-- ⚠ Veleta's exact last day is not in a source I could read (a search summary said 14 Aug). His
-- letter makes it no later than his replacement's start, so his term closes the day before
-- Jerrells's appointment. That is an upper bound, not a sourced day.
--
-- politicians.is_incumbent: Zay and Veleta -> false (they hold no other seat in our data); Bain and
-- Jerrells are inserted with true. The deprecated politicians.office_id snapshot is not written.
--
-- Idempotent: the helpers are idempotent on (office, person, start); the inserts and flag writes are
-- guarded on the values they change.
--
-- Applied to production 2026-11-11: 2 people inserted, 5 tenure changes. check:incumbency then read
-- 0 drift rows, control-reconcile-incumbency.mjs passed, check:seating held, and
-- check:duplicate-people found no new pair.

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- Pre-gate: the board is still the state this was written against (or already the end state).
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_bad int;
BEGIN
  SELECT count(*) INTO v_bad FROM (VALUES
     ('b3edb01d-56b2-4f7f-8e70-5c15ba3f9e41'::uuid, 'Chairman'),
     ('0615d51c-b9d4-4688-8e12-8f6a0e8675c2'::uuid, 'Utility Regulatory Commissioner'),
     ('e7597e86-e8f9-49b6-a2c7-bc2f7efbec69'::uuid, 'Utility Regulatory Commissioner')) x(id, title)
   WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = x.id AND o.title = x.title
                        AND o.chamber_id = (SELECT chamber_id FROM essentials.offices
                                             WHERE id = 'b3edb01d-56b2-4f7f-8e70-5c15ba3f9e41'));
  IF v_bad <> 0 THEN RAISE EXCEPTION 'CC_0400 pre-gate: % IURC office(s) not found as expected', v_bad; END IF;

  SELECT count(*) INTO v_bad FROM (VALUES
     ('c9ec6da3-a13e-4dd7-911c-47d93d7f84bc'::uuid, 'Andy Zay'),
     ('3f39cb5b-31fe-4252-8614-54d5948c9630'::uuid, 'Anthony Swinger'),
     ('c2741c7b-d4a5-4b66-a406-2fa2a4d0bdcd'::uuid, 'David Veleta')) x(id, who)
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = x.id AND p.full_name = x.who);
  IF v_bad <> 0 THEN RAISE EXCEPTION 'CC_0400 pre-gate: % named person row(s) not found', v_bad; END IF;

  -- Nobody else already sits on the IURC under these names (no duplicate Bain / Jerrells).
  SELECT count(*) INTO v_bad FROM essentials.politicians
   WHERE (lower(last_name) = 'bain' AND lower(first_name) IN ('joshua','josh'))
      OR  lower(last_name) = 'jerrells';
  IF v_bad > 2 OR (v_bad > 0 AND EXISTS (SELECT 1 FROM essentials.politicians
                     WHERE ((lower(last_name) = 'bain' AND lower(first_name) IN ('joshua','josh'))
                            OR lower(last_name) = 'jerrells')
                       AND source NOT LIKE 'CC_0400 %')) THEN
    RAISE EXCEPTION 'CC_0400 pre-gate: a Bain or Jerrells row already exists from another source; reuse it instead of inserting';
  END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
-- The two new commissioners.
-- ---------------------------------------------------------------------------------------------
INSERT INTO essentials.politicians
  (full_name, first_name, last_name, is_active, is_incumbent, is_appointed, urls, source)
SELECT v.full_name, v.first_name, v.last_name, true, true, true, ARRAY[v.url], v.source
  FROM (VALUES
    ('Joshua Bain', 'Joshua', 'Bain',
     'https://www.in.gov/iurc/about-us/commission-chairman-and-commissioners/commissioner-joshua-bain',
     'CC_0400 IURC commissioner, appointed Aug. 6, 2026 by Gov. Braun (in.gov/iurc, read 2026-11-11)'),
    ('Joby D. Jerrells', 'Joby', 'Jerrells',
     'https://www.in.gov/iurc/about-us/commission-chairman-and-commissioners/commissioner-joby-jerrells',
     'CC_0400 IURC commissioner, appointed Aug. 17, 2026 by Gov. Braun (in.gov/iurc, read 2026-11-11)')
  ) v(full_name, first_name, last_name, url, source)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p
                    WHERE p.last_name = v.last_name AND p.first_name = v.first_name
                      AND p.source LIKE 'CC_0400 %');

CREATE TEMP TABLE cc0400_people ON COMMIT DROP AS
SELECT id AS politician_id FROM essentials.politicians
 WHERE id IN ('c9ec6da3-a13e-4dd7-911c-47d93d7f84bc','3f39cb5b-31fe-4252-8614-54d5948c9630',
              'c2741c7b-d4a5-4b66-a406-2fa2a4d0bdcd')
    OR (source LIKE 'CC_0400 %' AND last_name IN ('Bain','Jerrells'));

DO $$ BEGIN
  IF (SELECT count(*) FROM cc0400_people) <> 5 THEN
    RAISE EXCEPTION 'CC_0400: expected 5 people in scope, found %', (SELECT count(*) FROM cc0400_people);
  END IF;
END $$;

-- ▼▼ BLOCK A — PASTE BEFORE YOUR FIRST WRITE TO essentials.office_terms ▼▼

-- @incumbency-decision: gated — seats Swinger as Chairman, moves Zay to a commissioner seat then closes it (fired), closes Veleta (resigned), seats Bain and Jerrells; none of the five has a race row

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0400_people);

-- 🔴 `o2` IS THE SCRIPT'S OWN ALIAS AND IT IS A TRAP. Never write `o2.politician_id` anywhere near
-- this block. `check:occupancy` reads `o<digits>.politician_id` as the dropped essentials.offices
-- column — that is the repo's offices alias convention — and CC_0394 turned the "static guards" job
-- red on exactly that. Here `o2` is only ever read for `chamber_id`, which is safe. Rename it to
-- something not starting with `o` if you need any other column off it.

-- ▲▲ END OF BLOCK A ▲▲

-- ---------------------------------------------------------------------------------------------
-- Write, in date order.
-- ---------------------------------------------------------------------------------------------

-- 22 Jun 2026: Swinger takes the chair (closes Zay's Chairman term at 21 Jun).
SELECT essentials.seat_officeholder(
  'b3edb01d-56b2-4f7f-8e70-5c15ba3f9e41', '3f39cb5b-31fe-4252-8614-54d5948c9630', '2026-06-22',
  'CC_0400: "named Chairman on June 22, 2026" (https://www.in.gov/iurc/about-us/commission-chairman-and-commissioners/commissioner-anthony-swinger)',
  'appointed', 'day', 'removed');

-- 22 Jun 2026: Zay stays on the panel in the commissioner seat Swinger left (closes Swinger's at 21 Jun).
SELECT essentials.seat_officeholder(
  '0615d51c-b9d4-4688-8e12-8f6a0e8675c2', 'c9ec6da3-a13e-4dd7-911c-47d93d7f84bc', '2026-06-22',
  'CC_0400: removed as chairman 22 Jun 2026 and "remains on the panel" (https://indianacapitalchronicle.com/2026/06/30/utility-regulator-resigns-from-post-braun-looks-for-replacement/); the chair is a designation, so he continues as a commissioner in the seat Swinger left for the Chairman office',
  'succeeded', 'day', 'unknown');

-- 3 Aug 2026: Zay is fired. First vacant day is 4 Aug.
SELECT essentials.vacate_office(
  '0615d51c-b9d4-4688-8e12-8f6a0e8675c2', '2026-08-04',
  'CC_0400: "Zay was discharged from employment with the State of Indiana today, August 3, 2026" (https://indianacapitalchronicle.com/2026/08/03/zay-fired-from-utility-regulator-panel-weeks-after-aes-hike-demotion/)',
  'removed')
 WHERE EXISTS (SELECT 1 FROM essentials.office_terms t      -- only while Zay's term is still open:
                WHERE t.office_id = '0615d51c-b9d4-4688-8e12-8f6a0e8675c2'   -- on a re-run the helper
                  AND t.politician_id = 'c9ec6da3-a13e-4dd7-911c-47d93d7f84bc' -- would re-set the flag
                  AND t.term_end IS DISTINCT FROM '2026-08-03');

-- 6 Aug 2026: Bain fills that seat.
SELECT essentials.seat_officeholder(
  '0615d51c-b9d4-4688-8e12-8f6a0e8675c2',
  (SELECT id FROM essentials.politicians WHERE last_name = 'Bain' AND source LIKE 'CC_0400 %'), '2026-08-06',
  'CC_0400: "Joshua Bain was appointed to the Commission on Aug. 6, 2026, by Governor Mike Braun" (https://www.in.gov/iurc/about-us/commission-chairman-and-commissioners/commissioner-joshua-bain)',
  'appointed', 'day', 'removed');

UPDATE essentials.offices SET is_vacant = false, vacant_since = NULL
 WHERE id = '0615d51c-b9d4-4688-8e12-8f6a0e8675c2'
   AND (is_vacant IS DISTINCT FROM false OR vacant_since IS NOT NULL);

-- 17 Aug 2026: Jerrells replaces Veleta (closes Veleta's term at 16 Aug, an upper bound).
SELECT essentials.seat_officeholder(
  'e7597e86-e8f9-49b6-a2c7-bc2f7efbec69',
  (SELECT id FROM essentials.politicians WHERE last_name = 'Jerrells' AND source LIKE 'CC_0400 %'), '2026-08-17',
  'CC_0400: "Joby D. Jerrells was appointed to the Commission on Aug. 17, 2026" (https://www.in.gov/iurc/about-us/commission-chairman-and-commissioners/commissioner-joby-jerrells); "will replace outgoing Commissioner David Veleta" (https://indianacapitalchronicle.com/2026/07/23/braun-appoints-his-4th-new-member-to-indiana-utility-commission-since-december/)',
  'appointed', 'day', 'resigned');

-- Say on Veleta's closed term what its end date is.
UPDATE essentials.office_terms
   SET source = source || ' | CC_0400: resigned by letter of 26 Jun 2026, "effective August 31, 2026, or sooner should my replacement be ready to serve" (https://indianacapitalchronicle.com/2026/06/30/utility-regulator-resigns-from-post-braun-looks-for-replacement/); closed the day before his replacement Jerrells was appointed, an upper bound on his last day'
 WHERE id = 'b598cf5a-43aa-48ad-8650-8db0968f2769'
   AND source NOT LIKE '%CC_0400:%';

-- Zay's and Swinger's closed terms say why they closed.
UPDATE essentials.office_terms
   SET source = source || ' | CC_0400: removed as chairman; Swinger "named Chairman on June 22, 2026" (https://www.in.gov/iurc/about-us/commission-chairman-and-commissioners/commissioner-anthony-swinger)'
 WHERE id = '07a5bd65-cced-4dfb-9d8d-c57909b695a7' AND source NOT LIKE '%CC_0400:%';
UPDATE essentials.office_terms
   SET source = source || ' | CC_0400: moved to the Chairman office on 22 Jun 2026 (https://www.in.gov/iurc/about-us/commission-chairman-and-commissioners/commissioner-anthony-swinger)'
 WHERE id = '5437d020-ec10-40b7-afa3-845eab058408' AND source NOT LIKE '%CC_0400:%';

UPDATE essentials.politicians SET is_incumbent = false
 WHERE id IN ('c9ec6da3-a13e-4dd7-911c-47d93d7f84bc','c2741c7b-d4a5-4b66-a406-2fa2a4d0bdcd')
   AND is_incumbent IS DISTINCT FROM false;

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
  SELECT count(*) INTO v_planned FROM cc0400_people;
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
DECLARE v_got text; v_bad int;
BEGIN
  -- The board resolves to exactly the five the commission lists today, one per office.
  SELECT string_agg(o.title || ': ' || p.full_name, '; ' ORDER BY o.title, p.full_name) INTO v_got
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.chamber_id = (SELECT chamber_id FROM essentials.offices WHERE id = 'b3edb01d-56b2-4f7f-8e70-5c15ba3f9e41');
  IF v_got IS DISTINCT FROM 'Chairman: Anthony Swinger; Utility Regulatory Commissioner: Bob Deig; Utility Regulatory Commissioner: David Ziegner; Utility Regulatory Commissioner: Joby D. Jerrells; Utility Regulatory Commissioner: Joshua Bain' THEN
    RAISE EXCEPTION 'CC_0400 gate: IURC resolves to [%]', v_got;
  END IF;

  -- No IURC office is flagged vacant.
  SELECT count(*) INTO v_bad FROM essentials.offices
   WHERE chamber_id = (SELECT chamber_id FROM essentials.offices WHERE id = 'b3edb01d-56b2-4f7f-8e70-5c15ba3f9e41')
     AND (is_vacant OR vacant_since IS NOT NULL);
  IF v_bad <> 0 THEN RAISE EXCEPTION 'CC_0400 gate: % IURC office(s) still flagged vacant', v_bad; END IF;

  -- The closed spans are the ones the header describes.
  SELECT count(*) INTO v_bad FROM (VALUES
     ('b3edb01d-56b2-4f7f-8e70-5c15ba3f9e41'::uuid, 'c9ec6da3-a13e-4dd7-911c-47d93d7f84bc'::uuid, '2026-01-12'::date, '2026-06-21'::date),
     ('0615d51c-b9d4-4688-8e12-8f6a0e8675c2'::uuid, '3f39cb5b-31fe-4252-8614-54d5948c9630'::uuid, '2026-01-12'::date, '2026-06-21'::date),
     ('0615d51c-b9d4-4688-8e12-8f6a0e8675c2'::uuid, 'c9ec6da3-a13e-4dd7-911c-47d93d7f84bc'::uuid, '2026-06-22'::date, '2026-08-03'::date),
     ('e7597e86-e8f9-49b6-a2c7-bc2f7efbec69'::uuid, 'c2741c7b-d4a5-4b66-a406-2fa2a4d0bdcd'::uuid, '2022-09-14'::date, '2026-08-16'::date)
   ) x(office_id, politician_id, s, e)
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                      WHERE t.office_id = x.office_id AND t.politician_id = x.politician_id
                        AND t.term_start = x.s AND t.term_end = x.e);
  IF v_bad <> 0 THEN RAISE EXCEPTION 'CC_0400 gate: % expected closed span(s) missing', v_bad; END IF;

  -- Cached incumbency flags agree with the seats for all five people in scope.
  SELECT count(*) INTO v_bad
    FROM cc0400_people c JOIN essentials.politicians p ON p.id = c.politician_id
   WHERE p.is_incumbent IS DISTINCT FROM
         EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id);
  IF v_bad <> 0 THEN RAISE EXCEPTION 'CC_0400 gate: % person/people with is_incumbent out of step with their seats', v_bad; END IF;
END $$;

COMMIT;
