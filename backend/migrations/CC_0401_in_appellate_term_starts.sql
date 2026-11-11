-- CC_0401 — date the Indiana appellate judiciary from the two courts' own rosters.
--
-- 12 of the 327 tenures CC_0394 deliberately left undated are Indiana appellate judges. Their dates
-- are published, to the day, by the courts themselves. This migration writes those 12, and fixes
-- three rows that migration 1833 took from the same site's BIO PAGES instead of its ROSTERS.
--
-- Nothing is seated, nothing is vacated, no office or race row is created or changed. Only
-- office_terms.term_start, .start_precision and .source move, on 15 rows that already have holders.
--
-- ============================================================================================
-- 🔴 WHY THE EXISTING SNAPSHOT DATES COULD NEVER HAVE BEEN USED
-- ============================================================================================
-- All 324 BallotReady-sourced rows in CC_0394's excluded set carry politicians.valid_from. CC_0394
-- refused them on PROVENANCE ("BallotReady is not a source this repo uses") and noted that 319 of
-- the 324 are dated 01-01, so they carry no day. The appellate block shows they are also, separately,
-- WRONG — and not by a little. valid_from there is the start of the judge's current RETENTION term:
--
--   Melissa S. May      snapshot 2021-01-01   really 1998-04-09   off by 23 years
--   L. Mark Bailey      snapshot 2021-01-01   really 1998-01-30   off by 23 years
--   Mark S. Massa       snapshot 2025-01-01   really 2012-04-02   off by 12 years
--   Rudolph R. Pyle III snapshot 2025-01-01   really 2012-08-27   off by 12 years
--   Loretta H. Rush     snapshot 2025-01-01   really 2012-11-07   off by 12 years
--
-- Indiana appellate judges stand for retention in the first general election after they are seated
-- and every ten years after, and the resulting term begins the following January 1. That is exactly
-- what the snapshot holds. ▶ This is the SAME defect CC_0397 and CC_0398 undated 84 rows for — the
-- per-person column records a LATER term, not the tenure — reproduced here against a source that can
-- be checked, which is why it is written down. The remaining 312 excluded rows should be assumed to
-- have it too until each is sourced.
--
-- ============================================================================================
-- 🔴 THE BIO SAYS APPOINTED. THE ROSTER SAYS SEATED. ONLY THE SECOND IS A term_start.
-- ============================================================================================
-- Both courts publish a roster table giving each member's service date in brackets beside the name,
-- AND a per-judge biography page. They do not agree, because they are dates of different events:
--
--   Dana J. Kenworthy   bio: "Governor Eric Holcomb appointed her to the Court of Appeals in
--                            December 2022"
--                       roster: "January 16, 2023 -"
--   Mark S. Massa       bio: "appointed to the Indiana Supreme Court ... in March 2012"
--                       roster: "[April 2, 2012 -]"
--
-- Migration 1833 read the bios for three judges and the roster for the other five. So Kenworthy
-- carries 2022-12-01 — a month she was not yet on the court — and Mathias and Vaidik carry dates
-- coarsened to the year and the month the bio happened to state. This is CLAUDE.md's Ballotpedia
-- rule ("BALLOTPEDIA PUBLISHES BOTH APPOINTED AND ASSUMED OFFICE, AND ONLY THE SECOND IS A
-- term_start") turning up on a .gov source, where it is easier to trust the wrong column.
-- ▶ THE ROSTER IS THE AUTHORITY FOR THE DATE. The bio is the authority for the narrative.
--
-- ⚠ Kenworthy is the only one of the three that is WRONG rather than merely coarse. 2022-12-01 with
--   month precision asserts she sat on the Court of Appeals in December 2022; she did not. Mathias
--   ("2000") and Vaidik ("February 2000") are true statements that show a voter less than we know,
--   so they are sharpened, not corrected. The two cases are recorded separately in `kind` below.
--
-- ============================================================================================
-- 🔴 THE CHIEF JUSTICE OFFICE TAKES HER COURT SEAT'S DATE, NOT HER CHIEF JUSTICE DATE
-- ============================================================================================
-- Loretta Rush holds the office row titled "Indiana Supreme Court Chief Justice". Two dates could
-- fill it: she took the oath as the 108th Justice on 2012-11-07, and the Judicial Nominating
-- Commission named her Chief Justice in August 2014.
--
-- RULING APPLIED (user, 2026-11-11, CC_0399): "a rotating mayor's tenure means their COUNCIL
-- SERVICE. The office is a council seat whose holder currently chairs." The Chief Justice is one of
-- the five justices, selected by the Commission for a renewable five-year term — the same shape.
-- So this office is a court seat whose holder currently presides, and the tenure is her service on
-- the court: 2012-11-07. ⚠ It is also the better-sourced of the two: the roster gives the court seat
-- to the day, while her bio gives the chief justiceship only as "August 2014".
--
-- ============================================================================================
-- WHAT IT OVERWRITES  (there is no history table and no schema_migrations to replay from)
-- ============================================================================================
--   office_terms.term_start      NULL -> a date (12 rows), or the previous date (3 rows)
--   office_terms.start_precision 'unknown' -> 'day' (12), 'month'/'year' -> 'day' (3)
--   office_terms.source          APPENDED to, never replaced.
-- Every previous value is in the plan table below, and the pre-gate refuses to run if any row's
-- stored value is not the one recorded there.
--
-- NOT tagged '| unverified CC_0401' (CA_0171). That tag makes office_holders_as_of SKIP a term; these
-- are real tenures with real holders, published by the body itself.
--
-- Every target row has term_end IS NULL, so narrowing an unbounded range creates no overlap and
-- cannot trip office_terms_dates_sane.
--
-- Idempotent, and the first version of this file was NOT. The pre-gate asserted only the BEFORE
-- value, so the second run raised instead of doing nothing — fail-closed, which is safe, but not
-- what this header claimed. It now accepts a row that holds EITHER the recorded previous value OR
-- the value this migration writes, and refuses any third value. That keeps the real protection
-- (another session moved the row) and makes a re-run a no-op, which is how it was verified.
--
-- Sources, both read in a browser on 2026-11-11 (not WebFetch — it fabricates names and dates):
--   https://www.in.gov/courts/supreme/justices/   "Current Justices", service date beside each name
--   https://www.in.gov/courts/appeals/judges/     "Current Judges", by district, date beside each name
--
-- Applied to production 2026-11-11: 15 tenures updated, all 15 at day precision, incumbency guard
-- reported "15 person/people planned, 0 with a race row in the last year". All 20 Indiana appellate
-- seats now carry a day-precision date matching their court's roster. offices_missing_terms
-- unchanged at 294 / 56 / 238 (no office row is touched). `check:incumbency` then read 0 drift rows
-- and control-reconcile-incumbency.mjs passed. Re-running plans 15, updates 0 and still passes.

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- 1. The plan. One row per tenure, carrying the value it is replacing.
-- ---------------------------------------------------------------------------------------------
CREATE TEMP TABLE cc0401_plan (
  term_id        uuid PRIMARY KEY,
  politician_id  uuid,
  who            text NOT NULL,
  seat           text NOT NULL,
  was_start      date,
  was_prec       text NOT NULL,
  new_start      date NOT NULL,
  new_prec       text NOT NULL CHECK (new_prec = 'day'),
  kind           text NOT NULL CHECK (kind IN ('fill','correct','sharpen')),
  -- 🔴 Set only where the ROSTER itself prints the 1st as the day. The house convention writes a
  -- coarse date as the first of the period, so a date landing on the 1st is normally the signature
  -- of a placeholder — but a real 1st exists, and the pre-gate below refuses any unacknowledged one.
  -- Two rows need it, and this column is what makes them a judgement rather than an exception.
  first_is_real  boolean NOT NULL DEFAULT false,
  citation       text NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0401_plan
  (term_id, who, seat, was_start, was_prec, new_start, new_prec, kind, first_is_real, citation) VALUES
-- ── Supreme Court (5 fills) — in.gov/courts/supreme/justices/, "Current Justices" ────────────
 ('af7aadc7-f73a-4fb6-91a0-0fa9f6dce6e0','Loretta H Rush','Indiana Supreme Court Chief Justice',
  NULL,'unknown','2012-11-07','day','fill',false,
  'Court roster: "Chief Justice Loretta H. Rush (108) [November 7, 2012 -]". Her own bio confirms the month ("took the oath of office as Indiana''s 108th Supreme Court Justice in November 2012") and dates the chief justiceship separately ("named her Indiana''s first female Chief Justice in August 2014"), which this migration deliberately does not use — see the header.'),
 ('c4427fd7-77b8-4cf8-84b3-ca1cd251c28b','Mark S Massa','Indiana Supreme Court Justice',
  NULL,'unknown','2012-04-02','day','fill',false,
  'Court roster: "Justice Mark S. Massa (107) [April 2, 2012 -]". His bio gives only the APPOINTMENT ("appointed ... by Governor Mitch Daniels in March 2012"); the roster date is the seating.'),
 ('d615dc6e-5a92-46aa-9b67-5c3eaebe07d5','Geoffrey Slaughter','Indiana Supreme Court Justice',
  NULL,'unknown','2016-06-13','day','fill',false,
  'Court roster: "Justice Geoffrey G. Slaughter (109) [June 13, 2016 -]".'),
 ('c6352306-7df4-473a-99e5-d21349458b75','Christopher M Goff','Indiana Supreme Court Justice',
  NULL,'unknown','2017-07-24','day','fill',false,
  'Court roster: "Justice Christopher M. Goff (110) [July 24, 2017 -]".'),
 ('117f86a0-68f8-43ea-a1c5-d81c0d5f7187','Derek R Molter','Indiana Supreme Court Justice',
  NULL,'unknown','2022-09-01','day','fill',true,
  'Court roster: "Justice Derek R. Molter (111) [September 1, 2022 -]". He sat on the Court of Appeals before this; the Supreme Court roster dates his service on THIS court, which is the office this term row belongs to.'),
-- ── Court of Appeals (7 fills) — in.gov/courts/appeals/judges/, "Current Judges" ─────────────
 ('4f64bb38-3f0f-4518-b887-d0ee5c4d7519','L. M Bailey','Indiana Appeals Court Judge - District 1',
  NULL,'unknown','1998-01-30','day','fill',false,
  'Court roster, First District: "Judge L. Mark Bailey, Presiding Judge   January 30, 1998 -".'),
 ('39c01479-c133-42bd-9d7e-4c68941218cd','Peter R Foley','Indiana Appeals Court Judge - District 1',
  NULL,'unknown','2022-10-11','day','fill',false,
  'Court roster, First District: "Judge Peter R. Foley   October 11, 2022 -".'),
 ('ec4445ad-cc78-47ed-b3dd-23752b713cbf','Cale J Bradford','Indiana Appeals Court Judge - District 2',
  NULL,'unknown','2007-08-01','day','fill',true,
  'Court roster, Second District: "Judge Cale J. Bradford   August 1, 2007 -".'),
 ('664b7125-fbaf-4a35-a79a-f4691c81b2c0','Robert R Altice','Indiana Appeals Court Judge - District 2',
  NULL,'unknown','2015-09-02','day','fill',false,
  'Court roster, Second District: "Judge Robert R. Altice, Jr.   September 2, 2015 -".'),
 ('f4fb049e-c03f-42a0-a1d2-82c294a51f7c','Melissa S May','Indiana Appeals Court Judge - District 4',
  NULL,'unknown','1998-04-09','day','fill',false,
  'Court roster, Fourth District: "Judge Melissa S. May   April 9, 1998 -".'),
 ('66d2763a-fc2c-4ba3-9ef8-d21d73aa5013','Rudolph R Pyle','Indiana Appeals Court Judge - District 4',
  NULL,'unknown','2012-08-27','day','fill',false,
  'Court roster, Fourth District: "Judge Rudolph R. Pyle, III   August 27, 2012 -".'),
 ('6cd419e0-17cb-4d3c-ba8f-75992900aecd','Elaine B Brown','Indiana Appeals Court Judge - District 5',
  NULL,'unknown','2008-05-05','day','fill',false,
  'Court roster, Fifth District: "Judge Elaine B. Brown   May 5, 2008 -".'),
-- ── One correction and two sharpenings of migration 1833's rows ───────────────────────────────
 ('d394b345-7670-40bb-aced-e63320d07451','Dana J Kenworthy','Indiana Appeals Court Judge - District 2',
  '2022-12-01','month','2023-01-16','day','correct',false,
  '🔴 The stored 2022-12-01 is her APPOINTMENT month, taken from her bio ("Governor Eric Holcomb appointed her to the Court of Appeals in December 2022"). The court roster, Second District, gives her service as "January 16, 2023 -". Month precision on December 2022 asserts she sat on the court that month; she did not.'),
 ('c5e6ddab-c31e-43b4-b79c-f9122340bfe6','Paul D Mathias','Indiana Appeals Court Judge - District 3',
  '2000-01-01','year','2000-03-30','day','sharpen',false,
  'Stored 2000 (year precision) is true and coarse. Court roster, Third District: "Judge Paul D. Mathias,   March 30, 2000 -".'),
 ('e31b4ddc-2a84-4a6c-8598-e2320f347506','Nancy H Vaidik','Indiana Appeals Court Judge - District 5',
  '2000-02-01','month','2000-02-07','day','sharpen',false,
  'Stored February 2000 (month precision) is true and coarse. Court roster, Fifth District: "Judge Nancy H. Vaidik   February 7, 2000 -".');

UPDATE cc0401_plan p
   SET politician_id = ot.politician_id
  FROM essentials.office_terms ot
 WHERE ot.id = p.term_id;

-- ---------------------------------------------------------------------------------------------
-- 2. Refuse to write a plan that is not what this file describes.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM cc0401_plan;
  IF v_n <> 15 THEN
    RAISE EXCEPTION 'CC_0401 pre-gate: plan holds % row(s), expected 15', v_n;
  END IF;

  -- Every term row must exist, be held by somebody, and still be open-ended.
  SELECT count(*) INTO v_n
    FROM cc0401_plan p
    LEFT JOIN essentials.office_terms ot ON ot.id = p.term_id
   WHERE ot.id IS NULL OR ot.politician_id IS NULL OR ot.term_end IS NOT NULL;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0401 pre-gate: % plan row(s) name a term that is missing, unheld or closed', v_n;
  END IF;

  -- 🔴 Each row must hold EITHER the value this file records overwriting, or the value it writes.
  -- Anything else means another session moved the row since this header was written, and the right
  -- answer is to stop rather than silently clobber their work.
  -- ⚠ Both arms are needed. Asserting only the BEFORE value made the first re-run fail — the
  -- migration was fail-closed, not idempotent, and the header said otherwise. Asserting only that
  -- the row is "one of the two" is what makes a second run a genuine no-op while still refusing a
  -- third value.
  SELECT count(*) INTO v_n
    FROM cc0401_plan p
    JOIN essentials.office_terms ot ON ot.id = p.term_id
   WHERE NOT ((ot.term_start      IS NOT DISTINCT FROM p.was_start
               AND ot.start_precision IS NOT DISTINCT FROM p.was_prec)
           OR (ot.term_start      IS NOT DISTINCT FROM p.new_start
               AND ot.start_precision IS NOT DISTINCT FROM p.new_prec));
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0401 pre-gate: % row(s) hold neither the value this migration records '
      'overwriting nor the value it writes. Somebody else has moved them — re-read before running.', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM cc0401_plan p
    JOIN essentials.office_terms ot ON ot.id = p.term_id
   WHERE ot.term_start IS NOT DISTINCT FROM p.new_start
     AND ot.start_precision IS NOT DISTINCT FROM p.new_prec;
  IF v_n <> 0 THEN
    RAISE NOTICE 'CC_0401: % of 15 row(s) already hold the planned value (re-run)', v_n;
  END IF;

  -- The term row must belong to the person and seat named, so a mis-copied uuid cannot date a
  -- stranger. Names are compared exactly as essentials.politicians stores them.
  SELECT count(*) INTO v_n
    FROM cc0401_plan p
    JOIN essentials.office_terms ot ON ot.id = p.term_id
    JOIN essentials.politicians pol ON pol.id = ot.politician_id
    JOIN essentials.offices o ON o.id = ot.office_id
   WHERE pol.full_name <> p.who OR o.title <> p.seat;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0401 pre-gate: % plan row(s) name a person or seat the term does not carry', v_n;
  END IF;

  -- A date in the future, or one the holder cannot have served from, is a transcription slip.
  SELECT count(*) INTO v_n FROM cc0401_plan
   WHERE new_start > CURRENT_DATE OR new_start < DATE '1900-01-01';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0401 pre-gate: % row(s) carry an impossible date', v_n;
  END IF;

  -- 🔴 Every row is sourced to the day, so none may land on a shape that reads as a placeholder
  -- under the house convention (01-01 = year, day 1 = month) WITHOUT SAYING SO. This gate fired on
  -- the first dry run and the finding was real both ways: Cale Bradford (August 1, 2007) and Derek
  -- Molter (September 1, 2022) are genuine firsts that the roster prints as days, and the other
  -- thirteen are not. A blanket refusal would have been wrong; a blanket allowance would let a
  -- silently coarsened date through as a day. `first_is_real` is the acknowledgement, per row.
  SELECT count(*) INTO v_n FROM cc0401_plan
   WHERE extract(day from new_start) = 1 AND NOT first_is_real;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0401 pre-gate: % day-precision row(s) land on the 1st without first_is_real. '
      'Re-read the roster: is that the published day, or a coarse value in disguise?', v_n;
  END IF;

  -- …and the acknowledgement may not be handed out where it is not needed, or it becomes a habit.
  SELECT count(*) INTO v_n FROM cc0401_plan
   WHERE first_is_real AND extract(day from new_start) <> 1;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0401 pre-gate: % row(s) claim first_is_real but do not land on the 1st', v_n;
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- ▼▼ BLOCK A — before the first write to essentials.office_terms ▼▼

-- @incumbency-decision: gated — sets term_start on 15 held, open-ended Indiana appellate tenures (12 from NULL, 3 replacing an earlier value)

-- Snapshot what the cached column says, and what office_terms says, for every race row belonging to
-- a person this migration touches. `expected` is reconcile-incumbency.mjs's own SQL.
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
   AND rc.politician_id IN (SELECT politician_id FROM cc0401_plan);

-- 🔴 `o2` is the script's own alias and it is a trap: never write `o2.politician_id` near this block.
-- check:occupancy reads `o<digits>.politician_id` as the dropped essentials.offices column. Here o2
-- is only ever read for chamber_id, which is safe.

-- ▲▲ END OF BLOCK A ▲▲
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

-- ---------------------------------------------------------------------------------------------
-- 3. The write.
-- ---------------------------------------------------------------------------------------------
UPDATE essentials.office_terms ot
   SET term_start      = p.new_start,
       start_precision = p.new_prec,
       source          = CASE
         WHEN coalesce(btrim(ot.source), '') = '' THEN
           'term start from the court''s own roster (CC_0401)'
         ELSE ot.source || ' | term start from the court''s own roster (CC_0401)'
       END
  FROM cc0401_plan p
 WHERE ot.id = p.term_id
   AND (ot.term_start IS DISTINCT FROM p.new_start
        OR ot.start_precision IS DISTINCT FROM p.new_prec);

-- ---------------------------------------------------------------------------------------------
-- 4. Post-verify, on the END STATE rather than on the UPDATE's own row count.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_bad int;
  v_day int;
BEGIN
  SELECT count(*) INTO v_bad
    FROM cc0401_plan p
    JOIN essentials.office_terms ot ON ot.id = p.term_id
   WHERE ot.term_start IS DISTINCT FROM p.new_start
      OR ot.start_precision IS DISTINCT FROM p.new_prec;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0401 post-verify: % of 15 row(s) did not end on the planned value', v_bad;
  END IF;

  -- The provenance must be on every row, and must not have replaced what was there.
  SELECT count(*) INTO v_bad
    FROM cc0401_plan p
    JOIN essentials.office_terms ot ON ot.id = p.term_id
   WHERE ot.source NOT LIKE '%CC_0401%';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0401 post-verify: % row(s) carry no CC_0401 provenance', v_bad;
  END IF;

  -- Nothing was seated, closed or unseated: all 15 are still held and still open-ended.
  SELECT count(*) INTO v_bad
    FROM cc0401_plan p
    JOIN essentials.office_terms ot ON ot.id = p.term_id
   WHERE ot.politician_id IS NULL OR ot.term_end IS NOT NULL;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0401 post-verify: % row(s) are no longer a held, open-ended term', v_bad;
  END IF;

  -- 🔴 No appellate tenure in this block may be left showing a coarse date: that was the state
  -- this migration exists to end, and a silent partial would look like success.
  SELECT count(*) INTO v_day FROM cc0401_plan p
    JOIN essentials.office_terms ot ON ot.id = p.term_id
   WHERE ot.start_precision = 'day';
  RAISE NOTICE 'CC_0401: 15 Indiana appellate tenure(s) end at day precision (% checked)', v_day;
  IF v_day <> 15 THEN
    RAISE EXCEPTION 'CC_0401 post-verify: only % of 15 row(s) reached day precision', v_day;
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- ▼▼ BLOCK B — after the last write to essentials.office_terms ▼▼

DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM cc0401_plan;
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
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

COMMIT;
