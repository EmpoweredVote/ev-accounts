-- CC_0521_fremont_d4_incoming_ying_min_li.sql
-- CC_0521: Fremont, CA City Council District 4 -- create Ying Min Li and seat her as the INCOMING holder from
-- 2026-12-08, so the seat shows Yang Shao now with Li as "Incoming on 2026-12-08" (office_next_term, CC_0341).
--
-- THE RESULT. Alameda County ROV, November 3, 2026 General Election, "Certified Final Results", last updated
-- 2026-11-25 (alamedacountyca.gov/rovresults/260/), "Member, City Council, District 4 - Fremont":
--   Ying Min Li 3,974 (40.90%) · Aziz Akbari 3,413 (35.12%) · Manisha Pathak 2,071 (21.31%) · Anurag Mishra 259 (2.67%).
--   Open seat: Yang Shao (D4 since 2018) was not on the ballot.
--
-- 🔴 THE DATE IS AN ESTIMATE, AND THE SITE SHOWS IT AS AN EXACT DAY. Operator decision 2026-11-27 (Chris
-- Cantrell): use 2026-12-08 now and correct it when the installation agenda is posted.
--   - The law bounds it, it does not fix it. Elections Code §10263(b) (consolidated election): the council
--     shall "declare the results and ... install the newly elected officers" no later than the next regularly
--     scheduled meeting following presentation of the 28-day canvass, or at a special meeting. Fremont
--     Municipal Code §2.05.110 sets a four-year term and names no start day; members serve until a
--     successor has qualified, so the oath decides the day. The county
--     certified on 2026-11-25, so the install is the Dec 1 or the Dec 8 meeting (or a special meeting).
--   - 2026-12-08 is the second Tuesday of December. Fremont installed its last two classes on the second
--     Tuesday too: 2022-12-13 (city bulletin) and 2024-12-10 (city roster start dates). A pattern, not a source.
--   - Chosen as the LATER of the two candidates on purpose: if the oath is actually Dec 1, Shao is shown one
--     week too long; Li is never shown as holder before she takes office.
--   - fremont.gov answers Akamai Access Denied to every automated read; its Granicus archive ends at
--     2026-09-22 and the new CivicClerk portal (fremont.portal.civicclerk.com) is a JS app whose API could not
--     be reached. ▶ FOLLOW-UP: when the agenda is readable, move the date with a new migration if it differs
--     (UPDATE both Li's term_start and Shao's term_end together; record the old values in that header).
--   start_precision = 'month' records that only the month is established. ⚠ The read path does not show
--   precision: voters see "Incoming on 2026-12-08".
--
-- THE PERSON. No essentials.politicians row matched '%ying%min%li%', 'yingmin%' or (first 'ying%', last 'li')
-- on 2026-11-27, so this creates one. Name as on the certified ballot ("Ying Min Li"); the campaign site
-- (yingminli.com, "Ying-Min Li for Fremont City Council 2026") hyphenates it -> alternate_names. external_id
-- -670016 continues the Fremont block (-670001 Salwan, -670010..-670015 council) and was unused. Party is
-- never stored. Pinned id d7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788 so a re-run inserts nothing.
--
-- THE PREDECESSOR. Yang Shao's term 8012a7d3-898f-45d5-96eb-8f5855ab88a9 on office
-- 58da0575-55c5-4721-8365-4514aa14aff4 was open-ended (term_start NULL, term_end NULL, precision 'unknown',
-- the ADR 0002 phase-2 backfill). seat_officeholder closes it at 2026-12-07 (how_ended 'term_expired').
-- 🔴 OVERWRITTEN VALUE: office_terms 8012a7d3-... term_end was NULL (how_ended NULL).
-- The office is not flagged is_vacant, so there is no flag to clear.
--
-- Not touched: Districts 2 and 3 (Campbell, Kimberlin) were re-elected -- same holder, no handover written.
BEGIN;

-- ─── 0. Preconditions ───
DO $$
DECLARE n int;
BEGIN
  -- the D4 seat is held today by Yang Shao, on an open-ended term, with nothing queued after it
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.id = '8012a7d3-898f-45d5-96eb-8f5855ab88a9' AND t.office_id = '58da0575-55c5-4721-8365-4514aa14aff4'
     AND p.full_name = 'Yang Shao' AND (t.term_end IS NULL OR t.term_end = DATE '2026-12-07');
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0521 precondition: Yang Shao''s D4 term is not in the expected state'; END IF;
  -- the external id is either unused or already ours (an external_id collision seats the wrong person)
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE external_id = -670016 AND id <> 'd7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788';
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0521 precondition: external_id -670016 belongs to someone else'; END IF;
  -- no second Ying Min Li has appeared since the header was written
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE (full_name ILIKE '%ying%min%li%' OR (first_name ILIKE 'ying%' AND last_name ILIKE 'li'))
     AND id <> 'd7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788';
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0521 precondition: another Ying Min Li row exists (%); reuse it instead', n; END IF;
END $$;

-- ─── 1. The person ───
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, alternate_names, is_active, source)
SELECT 'd7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788', -670016, 'Ying Min Li', 'Ying Min', 'Li', ARRAY['Ying-Min Li'], true,
       'Alameda County ROV certified results 2026-11-25 (alamedacountyca.gov/rovresults/260/), Member, City Council, District 4 - Fremont (CC_0521)'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = 'd7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788');

CREATE TEMP TABLE cc0521_plan ON COMMIT DROP AS
SELECT unnest(ARRAY['d7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788', '7db82a3d-5aa2-4150-996e-b170b50b47fe']::uuid[]) AS politician_id;

-- ▼▼ BLOCK A (backend/migrations/_templates/office_terms_incumbency_guard.sql) ▼▼
-- @incumbency-decision: gated — seats Ying Min Li on Fremont D4 from 2026-12-08 and closes Yang Shao's term at 2026-12-07
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
   AND rc.politician_id IN (SELECT politician_id FROM cc0521_plan);
-- ▲▲ END OF BLOCK A ▲▲

-- ─── 2. Seat (closes Shao at 2026-12-07; idempotent) ───
SELECT essentials.seat_officeholder(
  '58da0575-55c5-4721-8365-4514aa14aff4'::uuid,
  'd7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788'::uuid,
  DATE '2026-12-08',
  'Elected 2026-11-03, Alameda County ROV certified results 2026-11-25 (alamedacountyca.gov/rovresults/260/). '
  || 'START DATE ESTIMATED: Elections Code 10263(b) sets install at the next regular council meeting after the canvass '
  || 'is presented; 2026-12-08 is the second Tuesday, as in 2022 and 2024. Replace when the installation agenda is posted. (CC_0521)',
  'elected', 'month', 'term_expired', false);

-- ▼▼ BLOCK B ▼▼
DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM cc0521_plan;
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

-- ─── 3. Post-verify ───
DO $$
DECLARE n int; v_cur text; v_next text; v_on date;
BEGIN
  -- today the seat still reads Shao; the queued successor is Li on 2026-12-08 (asserted by NAME, not by count)
  SELECT p.full_name INTO v_cur FROM essentials.office_current_holder och JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE och.office_id = '58da0575-55c5-4721-8365-4514aa14aff4';
  SELECT p.full_name, ont.term_start INTO v_next, v_on FROM essentials.office_next_term ont JOIN essentials.politicians p ON p.id = ont.politician_id
   WHERE ont.office_id = '58da0575-55c5-4721-8365-4514aa14aff4';
  IF CURRENT_DATE < DATE '2026-12-08' THEN
    IF v_cur IS DISTINCT FROM 'Yang Shao' THEN RAISE EXCEPTION 'CC_0521: current D4 holder is %, expected Yang Shao until 2026-12-08', v_cur; END IF;
    IF v_next IS DISTINCT FROM 'Ying Min Li' OR v_on IS DISTINCT FROM DATE '2026-12-08' THEN
      RAISE EXCEPTION 'CC_0521: incoming D4 holder is % on %, expected Ying Min Li on 2026-12-08', v_next, v_on;
    END IF;
  ELSE
    IF v_cur IS DISTINCT FROM 'Ying Min Li' THEN RAISE EXCEPTION 'CC_0521: current D4 holder is %, expected Ying Min Li', v_cur; END IF;
  END IF;

  -- Shao's term ends the day before Li's starts, and Li's term is the only one after it
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE id = '8012a7d3-898f-45d5-96eb-8f5855ab88a9' AND term_end = DATE '2026-12-07';
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0521: Shao''s term was not closed at 2026-12-07'; END IF;
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE office_id = '58da0575-55c5-4721-8365-4514aa14aff4' AND term_start >= DATE '2026-12-08';
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0521: expected exactly one term from 2026-12-08 on D4, found %', n; END IF;

  -- Li holds nothing else (no namesake row was silently reused)
  SELECT count(*) INTO n FROM essentials.office_terms WHERE politician_id = 'd7f9fd1e-00dc-45b2-9e9d-a3ff6d7a7788';
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0521: Ying Min Li has % terms, expected 1', n; END IF;

  RAISE NOTICE 'CC_0521 OK: D4 current = %, incoming = % on %', v_cur, v_next, v_on;
END $$;

COMMIT;
