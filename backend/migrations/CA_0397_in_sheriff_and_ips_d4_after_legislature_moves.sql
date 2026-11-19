-- CA_0397 — the two local seats left behind by Indiana legislators who took office on 2026-11-04.
--
-- WHY. CA_0396 seats Kerry Forestal in Senate 31 and Allissa Impink in Senate 46 from 2026-11-04.
--   Our data also still had each of them holding a local seat, open-ended:
--     Forestal  Marion County Sheriff                          office ad15e649-a298-4333-9569-cdf72b48a0ee
--     Impink    Indianapolis Public School Board - District 4  office 763f6b8e-122a-4f30-bf20-4446e2a9e909
--   Both have left those seats. Without this file each appears twice in Essentials, once for a seat
--   they no longer hold. Kept in its own file because it is a different act from CA_0396 (one
--   migration per file).
--
-- MARION COUNTY SHERIFF — vacant from 2026-11-04.
--   "Kerry Forestal has resigned as Marion County Sheriff following his election victory to the
--   Indiana State Senate. ... Chief Deputy Reginald Roney has assumed interim duties as sheriff until
--   Williams takes office on January 1st, 2027." (Hot 100.9 / FOX 59, published 2026-11-04,
--   https://hot1009.com/4492514/forestal-resigns-as-marion-county-sheriff/, read 2026-11-18;
--   headline also at https://www.ibj.com/articles/forestal-resigns-as-marion-county-sheriff-after-state-senate-win).
--   ⚠ THE EXACT EFFECTIVE DAY IS NOT PUBLISHED. 2026-11-04 is used because it is the day his Senate
--   term began (Ind. Const. art. 4 §3), the article is dated that day, and the Indiana Constitution
--   bars holding two lucrative offices at once (art. 2 §9). So the sheriff's office was empty from
--   2026-11-04 at the latest; it cannot have been held into his Senate term.
--   The interim chief deputy is an acting officer, not a holder, so nobody is seated; the office is
--   flagged vacant with vacant_since 2026-11-04 (vacate_office does both). The sheriff elected on
--   2026-11-03 takes office 2027-01-01 and is NOT seated here — no race for this office exists in
--   our data.
--
-- IPS SCHOOL BOARD DISTRICT 4 — Impink out 2026-06-15, Chris Bultman in from 2026-07-28.
--   Impink "announced on Tuesday that she plans to resign from the school board effective June 15"
--   (Chalkbeat, 2026-05-19, https://www.chalkbeat.org/indiana/2026/05/19/impink-to-resign-from-ips-school-board/).
--   "effective June 15" is the first day she was NOT a commissioner, so vacate_office takes
--   2026-06-15 unadjusted and ends her term 2026-06-14.
--   The board voted 5-1 on 2026-06-25 to appoint Chris Bultman; "Bultman will be sworn in during the
--   school board's next agenda review meeting at 6 p.m. July 28 at 120 E. Walnut St." (Chalkbeat,
--   2026-06-26, https://www.chalkbeat.org/indiana/2026/06/26/indianapolis-public-schools-board-appoints-chris-bultman/).
--   ⚠ 2026-07-28 IS THE SCHEDULED OATH DATE, NOT A CONFIRMED ONE. No report of the oath itself was
--   found (searched 2026-11-18). The appointment date (06-25) is NOT used as the start: an
--   appointment precedes the tenure. If the IPS minutes for 2026-07-28 show otherwise, correct
--   Bultman's term_start. He serves until the member elected 2026-11-03 is sworn in, in January 2027.
--   Bultman is not in essentials.politicians (no row with surname Bultman, checked 2026-11-18), so
--   he is created.
--
-- 🔴 PRIOR VALUES (measured on production 2026-11-18). Both offices: is_vacant false, vacant_since
--   NULL. Both terms: term_start NULL, term_end NULL, start_precision 'unknown', how_ended NULL,
--   source 'backfill from essentials.offices.politician_id (ADR 0002 phase 2, migration 1459)'.
--   vacate_office appends to the source; it does not replace it. The IPS office ends this file
--   unflagged again (is_vacant false, vacant_since NULL) because Bultman holds it today.
--
-- NOT WRITTEN. No race or candidacy. The 2027 sheriff and the January IPS winner. Forestal's and
--   Impink's is_active (both stay true: they hold Senate seats from CA_0396).
--
-- ORDER. Apply after CA_0396. This file does not depend on it, but CA_0396's pre-gate names these
--   two offices as the only other seats its reused people may hold.
--
-- Idempotent: vacate_office and seat_officeholder are idempotent; the insert and flag write are
-- guarded. The pre-gate accepts the end state.

-- Applied to production 2026-11-18 with apply-migration-file.mjs, after CA_0396: 1 person inserted,
-- 2 terms closed, 1 opened. The live coordinate lookup at the Statehouse returned the Marion County
-- Sheriff seat as vacant and IPS District 4 held by Chris Bultman. check:incumbency read 0 drift rows.

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- Pre-gate.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_n int;
BEGIN
  -- Forestal holds the sheriff office open-ended (before) or through 2026-11-03 (re-run), and
  -- nobody else holds it after that.
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                   JOIN essentials.offices f ON f.id = t.office_id
                  WHERE t.office_id = 'ad15e649-a298-4333-9569-cdf72b48a0ee'
                    AND f.title = 'Sheriff'
                    AND t.politician_id = '71ee4905-3eac-4b8b-8890-322edcad7517'
                    AND (t.term_end IS NULL OR t.term_end = '2026-11-03')) THEN
    RAISE EXCEPTION 'CA_0397 pre-gate: Forestal''s Marion County Sheriff term is not in the expected state';
  END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms t
   WHERE t.office_id = 'ad15e649-a298-4333-9569-cdf72b48a0ee'
     AND t.politician_id IS DISTINCT FROM '71ee4905-3eac-4b8b-8890-322edcad7517'
     AND (t.term_end IS NULL OR t.term_end >= '2026-11-04');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0397 pre-gate: someone else already holds the sheriff office after 2026-11-03';
  END IF;

  -- Impink holds IPS District 4 open-ended (before) or through 2026-06-14 (re-run), and nobody but
  -- this file's Bultman holds it after that.
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                   JOIN essentials.offices f ON f.id = t.office_id
                  WHERE t.office_id = '763f6b8e-122a-4f30-bf20-4446e2a9e909'
                    AND f.title = 'Indianapolis Public School Board - District 4'
                    AND t.politician_id = '7c709450-21ee-41dd-9f45-08c860af7f5d'
                    AND (t.term_end IS NULL OR t.term_end = '2026-06-14')) THEN
    RAISE EXCEPTION 'CA_0397 pre-gate: Impink''s IPS District 4 term is not in the expected state';
  END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms t
   WHERE t.office_id = '763f6b8e-122a-4f30-bf20-4446e2a9e909'
     AND t.politician_id IS DISTINCT FROM '7c709450-21ee-41dd-9f45-08c860af7f5d'
     AND (t.term_end IS NULL OR t.term_end >= '2026-06-15')
     AND coalesce(t.source, '') NOT LIKE 'CA_0397:%';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0397 pre-gate: someone else already holds IPS District 4 after 2026-06-14';
  END IF;

  -- Bultman must not already exist under another source.
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE lower(p.last_name) = 'bultman' AND left(lower(p.first_name), 3) = 'chr'
     AND coalesce(p.source, '') NOT LIKE 'CA_0397 %';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0397 pre-gate: a Chris Bultman already exists — reuse that row instead';
  END IF;
END $$;

INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_appointed, source)
SELECT 'Chris Bultman', 'Chris', 'Bultman', true, true,
       'CA_0397 Indianapolis Public School Board District 4, appointed 2026-06-25 (https://www.chalkbeat.org/indiana/2026/06/26/indianapolis-public-schools-board-appoints-chris-bultman/, read 2026-11-18)'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p
                    WHERE p.last_name = 'Bultman' AND p.first_name = 'Chris'
                      AND p.source LIKE 'CA_0397 %');

CREATE TEMP TABLE ca0397_people ON COMMIT DROP AS
SELECT '71ee4905-3eac-4b8b-8890-322edcad7517'::uuid AS politician_id      -- Kerry Forestal
UNION SELECT '7c709450-21ee-41dd-9f45-08c860af7f5d'::uuid                 -- Allissa Impink
UNION SELECT p.id FROM essentials.politicians p
       WHERE p.last_name = 'Bultman' AND p.first_name = 'Chris' AND p.source LIKE 'CA_0397 %';

DO $$ BEGIN
  IF (SELECT count(*) FROM ca0397_people) <> 3 THEN
    RAISE EXCEPTION 'CA_0397: expected 3 people in scope, found %', (SELECT count(*) FROM ca0397_people);
  END IF;
END $$;

-- ▼▼ BLOCK A — PASTE BEFORE YOUR FIRST WRITE TO essentials.office_terms ▼▼

-- @incumbency-decision: gated — ends Forestal's sheriff term at 2026-11-03 and Impink's IPS term at 2026-06-14, seats Bultman on IPS District 4 from 2026-07-28; none of the three has a race row on these offices, and the gate checks any race row they have

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
   AND rc.politician_id IN (SELECT politician_id FROM ca0397_people);

-- 🔴 `o2` IS THE SCRIPT'S OWN ALIAS AND IT IS A TRAP. Never write `o2.politician_id` anywhere near
-- this block. `check:occupancy` reads `o<digits>.politician_id` as the dropped essentials.offices
-- column — that is the repo's offices alias convention — and CC_0394 turned the "static guards" job
-- red on exactly that. Here `o2` is only ever read for `chamber_id`, which is safe. Rename it to
-- something not starting with `o` if you need any other column off it.

-- ▲▲ END OF BLOCK A ▲▲

-- ---------------------------------------------------------------------------------------------
-- Writes.
-- ---------------------------------------------------------------------------------------------
-- Marion County Sheriff: Forestal's term ends 2026-11-03; the office is vacant from 2026-11-04.
SELECT essentials.vacate_office(
  'ad15e649-a298-4333-9569-cdf72b48a0ee', '2026-11-04',
  'CA_0397: Forestal resigned as Marion County Sheriff on winning Indiana Senate 31, whose term began 2026-11-04 (Ind. Const. art. 4 §3; two lucrative offices barred, art. 2 §9); exact effective day not published (https://hot1009.com/4492514/forestal-resigns-as-marion-county-sheriff/, 2026-11-04, read 2026-11-18). Chief Deputy Reginald Roney acting until the sheriff elected 2026-11-03 takes office 2027-01-01',
  'resigned');

-- IPS District 4: Impink's term ends 2026-06-14; vacant 2026-06-15 until Bultman's oath.
SELECT essentials.vacate_office(
  '763f6b8e-122a-4f30-bf20-4446e2a9e909', '2026-06-15',
  'CA_0397: Impink resigned "effective June 15" after winning the Democratic primary for Indiana Senate 46 (https://www.chalkbeat.org/indiana/2026/05/19/impink-to-resign-from-ips-school-board/, read 2026-11-18)',
  'resigned');

SELECT essentials.seat_officeholder(
  '763f6b8e-122a-4f30-bf20-4446e2a9e909',
  (SELECT p.id FROM essentials.politicians p
    WHERE p.last_name = 'Bultman' AND p.first_name = 'Chris' AND p.source LIKE 'CA_0397 %'),
  '2026-07-28',
  'CA_0397: appointed by the IPS board 5-1 on 2026-06-25 to serve until the member elected 2026-11-03 is sworn in; oath SCHEDULED for the 2026-07-28 agenda review meeting (https://www.chalkbeat.org/indiana/2026/06/26/indianapolis-public-schools-board-appoints-chris-bultman/, read 2026-11-18) — the oath itself was not confirmed',
  'appointed', 'day', 'resigned');

-- seat_officeholder does not clear the flag vacate_office set. Bultman holds the seat today.
UPDATE essentials.offices
   SET is_vacant = false, vacant_since = NULL
 WHERE id = '763f6b8e-122a-4f30-bf20-4446e2a9e909'
   AND (is_vacant OR vacant_since IS NOT NULL);

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
  SELECT count(*) INTO v_planned FROM ca0397_people;
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
DECLARE v_n int;
BEGIN
  -- Sheriff: Forestal closed 2026-11-03 'resigned'; nobody holds it today; flagged from 2026-11-04.
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                  WHERE t.office_id = 'ad15e649-a298-4333-9569-cdf72b48a0ee'
                    AND t.politician_id = '71ee4905-3eac-4b8b-8890-322edcad7517'
                    AND t.term_end = '2026-11-03' AND t.how_ended = 'resigned'
                    AND t.source LIKE '%CA_0397:%') THEN
    RAISE EXCEPTION 'CA_0397 gate: Forestal''s sheriff term not closed as described';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.office_current_holder och
              WHERE och.office_id = 'ad15e649-a298-4333-9569-cdf72b48a0ee' AND och.politician_id IS NOT NULL) THEN
    RAISE EXCEPTION 'CA_0397 gate: the sheriff office still resolves to a holder';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.offices
                  WHERE id = 'ad15e649-a298-4333-9569-cdf72b48a0ee'
                    AND is_vacant AND vacant_since = '2026-11-04') THEN
    RAISE EXCEPTION 'CA_0397 gate: the sheriff office is not flagged vacant from 2026-11-04';
  END IF;

  -- IPS District 4: Impink closed 2026-06-14 'resigned'; Bultman holds it today from 2026-07-28;
  -- not flagged.
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                  WHERE t.office_id = '763f6b8e-122a-4f30-bf20-4446e2a9e909'
                    AND t.politician_id = '7c709450-21ee-41dd-9f45-08c860af7f5d'
                    AND t.term_end = '2026-06-14' AND t.how_ended = 'resigned'
                    AND t.source LIKE '%CA_0397:%') THEN
    RAISE EXCEPTION 'CA_0397 gate: Impink''s IPS term not closed as described';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                   JOIN essentials.politicians p ON p.id = och.politician_id
                  WHERE och.office_id = '763f6b8e-122a-4f30-bf20-4446e2a9e909'
                    AND p.full_name = 'Chris Bultman' AND och.term_start = '2026-07-28'
                    AND och.how_started = 'appointed') THEN
    RAISE EXCEPTION 'CA_0397 gate: IPS District 4 does not resolve to Bultman from 2026-07-28';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.offices
              WHERE id = '763f6b8e-122a-4f30-bf20-4446e2a9e909' AND (is_vacant OR vacant_since IS NOT NULL)) THEN
    RAISE EXCEPTION 'CA_0397 gate: IPS District 4 is held and still flagged vacant';
  END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians WHERE source LIKE 'CA_0397 %';
  IF v_n <> 1 THEN RAISE EXCEPTION 'CA_0397 gate: % CA_0397 person rows (expected 1)', v_n; END IF;
END $$;

COMMIT;
