-- Migration CA_PENDING_bloomington_council_people_and_terms: Bloomington Common Council members 2020 to now, with dates
--
-- WHY: the council voting record (Task 9 of the council-record plan) reads members' votes from minutes back to
--   2020. It resolves each printed name to a person by meeting date, using essentials.office_terms rows on offices
--   whose chamber slug is 'bloomington-common-council' AND whose position name is 'City Legislature' AND whose
--   term_start is NOT NULL (refresh.ts, loadCouncilTerms). The chamber slug is shared with the City Clerk office,
--   which is no council seat, so every selection below also requires normalized_position_name = 'City Legislature'. Today the nine current members' terms are undated (the 1459 backfill shape), and the five
--   people who left the council at the end of 2023 are not in the database at all. So no name resolves.
--
-- WHAT, 17 terms, one per row of the council-record inventory's roster.json (spans copied exactly):
--   - 9 current members: their EXISTING current term gets its term_start (NULL, or a start that is not day
--     precision, -> the roster date).
--   - Shruti Rana: her EXISTING District V term (term_end 2024-02-07, written by 1824) gets its term_start.
--   - 7 closed terms are INSERTED: Sandberg, Sims, Sgambelluri, Smith, Volan (new people, below), and the earlier
--     seats of two current members: Rosenbarger (District I 2020-2023) and Piedmont-Smith (District V 2020-2023).
--   - 5 new politicians, full names as the city's OnBoard seat pages print them: Susan Sandberg, Jim Sims,
--     Sue Sgambelluri, Ron Smith, Stephen Volan. is_active = false. No photos (a later find-headshots pass).
--   Shruti Rana is NOT created: she already exists (1802 / 1824 name her, external_id 450800) and is reused.
--
-- 🔴 RUN CA_PENDING_bloomington_district5_office_merge.sql BEFORE THIS FILE. District 5 has two office rows
--   (Rana's and Daily's), so the pre-flight below stops at "expected 9 offices" until the duplicate is merged.
--
-- COURTNEY DAILY'S START DATE (C-5, current term). The stored 2024-03-01 has start_precision 'month' and no real
--   source: its own source text says it came from an old snapshot (CC_0394) and was never established. It is
--   month-precision and unsourced, so this file REPLACES it with the roster's 2024-03-02 (day precision), and
--   records the old value and precision in the term's source. The rule: a current term whose start is not day
--   precision is treated like an undated one. A differing start with day precision still stops the file.
--   🟡 A second source file gives 2024-03-27 for her. That conflict is UNRESOLVED and is the owner's to confirm;
--   this file writes the roster's date and does not settle it.
--
-- SOURCES: every span is the roster.json row, which is read from the seat's OnBoard page,
--   https://bloomington.in.gov/onboard/seats/<id> (C-7 245, C-8 246, C-9 247, C-1 249, C-2 250, C-3 251, C-4 252,
--   C-5 253, C-6 254), saved 2026-11-25 in the inventory (store-staging/jurisdictions/onboard-seat-<id>.txt).
--   Each term's `source` names its seat page.
--
-- 🔴 SPANS ARE THE ROSTER'S, NOT A WHOLE TENURE. roster.json starts in 2020 because the voting record starts there.
--   Dave Rollo (C-4 since at least 2008), Andy Ruff (C-7 2008-2019) and Isabel Piedmont-Smith (C-5 2016-2019)
--   served earlier, per the same seat pages. Writing 2020-01-01 as Rollo's term_start says nothing about before
--   2020 that any reader uses today, but it is not his first day. Earlier terms are out of scope here.
--
-- HOW SEATS ARE FOUND, with no hard-coded ids: each seat is "the council office its current member holds today"
--   (office_current_holder, matched on the surname at the end of full_name). The pre-flight requires exactly 9
--   council offices and 9 distinct anchors, so a duplicate office or a second same-surname holder stops it.
--
-- OVERWRITTEN VALUES (the rule: record what an UPDATE replaces):
--   - office_terms.term_start on 10 existing rows: the old value is NULL, except Daily's, which is 2024-03-01 at
--     month precision (see above). The pre-flight refuses any other value that has day precision, and each UPDATE
--     is guarded on term_start IS NULL OR start_precision <> 'day', so only those two kinds can be overwritten.
--     Each row's source records "start was <old start or NULL>, precision '<old>'".
--   - office_terms.start_precision on the same rows: the old value is written into that row's own `source`, which
--     is extended (never replaced): "<old source> | CA_PENDING bcc: dated ... (start was <old start or NULL>, precision '<old>')" on the 9 current terms (Rana's closed term keeps the older "start_precision was" text).
--
-- NOT DONE HERE:
--   - legislative_politician_id_map rows (id_type 'onboard'): the saved seat pages carry seat ids only, no OnBoard
--     person id. Blocked until a person id is confirmed.
--   - The 2024-02-08 to 2024-03-01 District V gap (Rana resigned, Daily seated 2024-03-02) is NOT written as a
--     vacancy span. The roster gives no row for it, and an unwritten span reads as "no holder", which is true.
--
-- WHY NOT essentials.seat_officeholder: it finds the term covering the new start date and closes it the day before.
--   The current members' terms are undated (open on both ends), so seating any 2020-2023 predecessor through it would
--   close the CURRENT holder's term in 2019. It also cannot write an end date, and every new term here is closed.
--   1464's header allows plain INSERTs into office_terms, so the closed terms are inserted directly, after the
--   current terms are dated, and the exclusion constraint still refuses any overlap.
--
-- 🔴 BEFORE APPLYING: reserve a CA slot, rename this file, and replace EVERY "CA_PENDING" below with that slot
--   IN ONE PASS (sed -i 's/CA_PENDING/CA_NNNN/g'). The text goes into office_terms.source and politicians.source, and
--   the idempotency guards match 'CA_PENDING bcc:%' — a partial replace makes a re-run create duplicate people.
--   check:office-terms-guards skips a file without a numbered slot, so it only checks this one after the rename.
-- Slot: named CA_PENDING until a CA number is reserved. Not applied by this commit. Idempotent.

BEGIN;

-- ─── Plan ──────────────────────────────────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE bcc_seat (seat_code text PRIMARY KEY, seat_url text NOT NULL, anchor_key text NOT NULL,
                            anchor_like text NOT NULL) ON COMMIT DROP;
INSERT INTO bcc_seat VALUES
  ('C-7', 'https://bloomington.in.gov/onboard/seats/245', 'flaherty',       '% flaherty'),
  ('C-8', 'https://bloomington.in.gov/onboard/seats/246', 'asare',          '% asare'),
  ('C-9', 'https://bloomington.in.gov/onboard/seats/247', 'ruff',           '% ruff'),
  ('C-1', 'https://bloomington.in.gov/onboard/seats/249', 'piedmont-smith', '% piedmont%smith'),
  ('C-2', 'https://bloomington.in.gov/onboard/seats/250', 'rosenbarger',    '% rosenbarger'),
  ('C-3', 'https://bloomington.in.gov/onboard/seats/251', 'stosberg',       '% stosberg'),
  ('C-4', 'https://bloomington.in.gov/onboard/seats/252', 'rollo',          '% rollo'),
  ('C-5', 'https://bloomington.in.gov/onboard/seats/253', 'daily',          '% daily'),
  ('C-6', 'https://bloomington.in.gov/onboard/seats/254', 'zulich',         '% zulich');

-- kind: 'date_current' = date the member's existing current term; 'date_rana' = date Rana's existing closed term;
--       'insert' = write a new closed term.
CREATE TEMP TABLE bcc_plan (key text NOT NULL, full_name text NOT NULL, seat_code text NOT NULL REFERENCES bcc_seat,
                            term_start date NOT NULL, term_end date, kind text NOT NULL) ON COMMIT DROP;
INSERT INTO bcc_plan VALUES
  ('flaherty',       'Matt Flaherty',         'C-7', '2020-01-01', NULL,         'date_current'),
  ('sandberg',       'Susan Sandberg',        'C-8', '2020-01-01', '2023-12-31', 'insert'),
  ('asare',          'Isak Nti Asare',        'C-8', '2024-01-02', NULL,         'date_current'),
  ('sims',           'Jim Sims',              'C-9', '2020-01-01', '2023-12-31', 'insert'),
  ('ruff',           'Andy Ruff',             'C-9', '2024-01-02', NULL,         'date_current'),
  ('rosenbarger',    'Kate Rosenbarger',      'C-1', '2020-01-01', '2023-12-31', 'insert'),
  ('piedmont-smith', 'Isabel Piedmont-Smith', 'C-1', '2024-01-02', NULL,         'date_current'),
  ('sgambelluri',    'Sue Sgambelluri',       'C-2', '2020-01-01', '2023-12-31', 'insert'),
  ('rosenbarger',    'Kate Rosenbarger',      'C-2', '2024-01-02', NULL,         'date_current'),
  ('smith',          'Ron Smith',             'C-3', '2020-01-01', '2023-12-31', 'insert'),
  ('stosberg',       'Hopi Stosberg',         'C-3', '2024-01-02', NULL,         'date_current'),
  ('rollo',          'Dave Rollo',            'C-4', '2020-01-01', NULL,         'date_current'),
  ('piedmont-smith', 'Isabel Piedmont-Smith', 'C-5', '2020-01-01', '2023-12-31', 'insert'),
  ('rana',           'Shruti Rana',           'C-5', '2024-01-02', '2024-02-07', 'date_rana'),
  ('daily',          'Courtney Daily',        'C-5', '2024-03-02', NULL,         'date_current'),
  ('volan',          'Stephen Volan',         'C-6', '2020-01-01', '2023-12-31', 'insert'),
  ('zulich',         'Sydney Zulich',         'C-6', '2024-01-02', NULL,         'date_current');

CREATE TEMP TABLE bcc_new_person (key text PRIMARY KEY, full_name text NOT NULL, first_name text NOT NULL,
                                  last_name text NOT NULL, alternate_names text[] NOT NULL, seat_url text NOT NULL)
  ON COMMIT DROP;
INSERT INTO bcc_new_person VALUES
  ('sandberg',    'Susan Sandberg',  'Susan',   'Sandberg',    '{}',              'https://bloomington.in.gov/onboard/seats/246'),
  ('sims',        'Jim Sims',        'Jim',     'Sims',        '{}',              'https://bloomington.in.gov/onboard/seats/247'),
  ('sgambelluri', 'Sue Sgambelluri', 'Sue',     'Sgambelluri', '{}',              'https://bloomington.in.gov/onboard/seats/250'),
  ('smith',       'Ron Smith',       'Ron',     'Smith',       '{}',              'https://bloomington.in.gov/onboard/seats/251'),
  -- "Steve Volan" is printed in council minutes and vote sheets 2020-2023 (inventory store-staging/minutes).
  ('volan',       'Stephen Volan',   'Stephen', 'Volan',       '{"Steve Volan"}', 'https://bloomington.in.gov/onboard/seats/254');

-- The council's offices, and each seat's anchor: the office its current member holds today.
CREATE TEMP TABLE bcc_office ON COMMIT DROP AS
SELECT ofc.id AS office_id, ch.government_id
  FROM essentials.offices ofc
  JOIN essentials.chambers ch ON ch.id = ofc.chamber_id
 WHERE ch.slug = 'bloomington-common-council'
   AND ofc.normalized_position_name = 'City Legislature';  -- the chamber slug also holds the City Clerk, who is no seat

CREATE TEMP TABLE bcc_anchor ON COMMIT DROP AS
SELECT s.seat_code, s.anchor_key AS key, och.office_id, och.politician_id, p.full_name
  FROM bcc_seat s
  JOIN essentials.office_current_holder och ON och.office_id IN (SELECT office_id FROM bcc_office)
  JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE lower(p.full_name) LIKE s.anchor_like;

-- ─── 0. Pre-flight ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v int; v_detail text;
BEGIN
  SELECT count(*) INTO v FROM bcc_office;
  IF v <> 9 THEN
    RAISE EXCEPTION 'CA_PENDING pre-flight: found % City Legislature offices under chamber slug bloomington-common-council, '
      'expected 9 (one per seat). More than 9 most likely means a duplicate seat office, for example a second '
      'District V row. %', v, 'See backend/migrations/CLAUDE.md, "MERGING TWO OFFICE ROWS IS NOT DELETING ONE" (move the term, then delete the duplicate), before re-running.';
  END IF;

  SELECT count(*), string_agg(seat_code || ' ' || full_name, ', ' ORDER BY seat_code) INTO v, v_detail FROM bcc_anchor;
  IF v <> 9 OR (SELECT count(DISTINCT key) FROM bcc_anchor) <> 9 OR (SELECT count(DISTINCT office_id) FROM bcc_anchor) <> 9
     OR (SELECT count(DISTINCT politician_id) FROM bcc_anchor) <> 9 THEN
    RAISE EXCEPTION 'CA_PENDING pre-flight: expected 9 seats, each held today by its one roster member on its own '
      'office under this chamber slug; found % match(es): %. A missing member (for example Daily) most likely holds '
      'a duplicate seat office outside the slug. %', v, coalesce(v_detail, '(none)'),
      'See backend/migrations/CLAUDE.md, "MERGING TWO OFFICE ROWS IS NOT DELETING ONE" (move the term, then delete the duplicate), before re-running.';
  END IF;

  -- Each anchor's current term must be undated (the 1459 shape), carry a coarser-than-day start (replaceable: Daily's
  -- unsourced month-precision 2024-03-01), or already carry the roster date (a re-run). Only a DAY-precision start
  -- that differs from the roster is a conflict.
  SELECT count(*), string_agg(format('%s %s term_start=%s', a.seat_code, a.full_name, ot.term_start), '; ')
    INTO v, v_detail
    FROM bcc_anchor a
    JOIN bcc_plan pl ON pl.key = a.key AND pl.seat_code = a.seat_code AND pl.kind = 'date_current'
    JOIN essentials.office_terms ot ON ot.office_id = a.office_id AND ot.politician_id = a.politician_id
         AND (ot.term_start IS NULL OR ot.term_start <= CURRENT_DATE)
         AND (ot.term_end   IS NULL OR ot.term_end   >= CURRENT_DATE)
   WHERE ot.term_start IS NOT NULL AND ot.term_start <> pl.term_start
     AND ot.start_precision = 'day';
  IF v <> 0 THEN
    RAISE EXCEPTION 'CA_PENDING pre-flight: % current term(s) already carry a different start date, which this '
      'migration will not overwrite (day-precision start): %', v, v_detail;
  END IF;

  -- Shruti Rana: exactly one row by that name holds a council term, it is on District V (Daily's office), and it
  -- is the 1824 row: ends 2024-02-07, start undated or already the roster date.
  SELECT count(DISTINCT p.id) INTO v
    FROM essentials.politicians p
    JOIN essentials.office_terms ot ON ot.politician_id = p.id
   WHERE lower(p.full_name) = 'shruti rana' AND ot.office_id IN (SELECT office_id FROM bcc_office);
  IF v <> 1 THEN
    RAISE EXCEPTION 'CA_PENDING pre-flight: found % people named Shruti Rana holding a term on a council office, '
      'expected 1. Zero most likely means her term sits on an office outside this chamber slug (a duplicate '
      'District V row). %', v, 'See backend/migrations/CLAUDE.md, "MERGING TWO OFFICE ROWS IS NOT DELETING ONE" (move the term, then delete the duplicate), before re-running.';
  END IF;
  SELECT count(*) INTO v
    FROM essentials.politicians p
    JOIN essentials.office_terms ot ON ot.politician_id = p.id
   WHERE lower(p.full_name) = 'shruti rana'
     AND ot.office_id = (SELECT office_id FROM bcc_anchor WHERE key = 'daily')
     AND ot.term_end = DATE '2024-02-07'
     AND (ot.term_start IS NULL OR ot.term_start = DATE '2024-01-02');
  IF v <> 1 THEN
    SELECT string_agg(format('office %s [%s..%s]', ot.office_id, ot.term_start, ot.term_end), '; ') INTO v_detail
      FROM essentials.politicians p JOIN essentials.office_terms ot ON ot.politician_id = p.id
     WHERE lower(p.full_name) = 'shruti rana';
    RAISE EXCEPTION 'CA_PENDING pre-flight: Shruti Rana''s term is not on the office Courtney Daily holds today '
      '(office %), or it does not end 2024-02-07 with start NULL or 2024-01-02. Her terms found: %. If her term '
      'and Daily''s sit on two different District V office rows, those rows are duplicates. %',
      (SELECT office_id FROM bcc_anchor WHERE key = 'daily'), coalesce(v_detail, '(none)'),
      'See backend/migrations/CLAUDE.md, "MERGING TWO OFFICE ROWS IS NOT DELETING ONE" (move the term, then delete the duplicate), before re-running.';
  END IF;

  -- No term on these 9 offices that this migration does not know about. An undated one would collide with every
  -- closed term inserted below; a dated one may be real, and a person should look at it first.
  SELECT count(*), string_agg(format('%s [%s..%s] %s', coalesce(p.full_name, '(vacant)'), ot.term_start, ot.term_end,
                                     left(ot.source, 60)), '; ')
    INTO v, v_detail
    FROM essentials.office_terms ot
    LEFT JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE ot.office_id IN (SELECT office_id FROM bcc_office)
     AND NOT EXISTS (SELECT 1 FROM bcc_anchor a WHERE a.office_id = ot.office_id AND a.politician_id = ot.politician_id)
     AND NOT (lower(coalesce(p.full_name, '')) = 'shruti rana' AND ot.term_end = DATE '2024-02-07')
     AND ot.source NOT LIKE 'CA_PENDING bcc:%';
  IF v <> 0 THEN
    RAISE EXCEPTION 'CA_PENDING pre-flight: % unexpected term(s) on the council offices: %', v, v_detail;
  END IF;

  -- Namesakes. A person already tied to an office or a race in Bloomington's government, whose SURNAME matches a new
  -- person (in last_name, at the end of full_name, or in any alternate_names entry), must be reused, not duplicated.
  -- Surname, not full name, so a shortened first name ("Jim"/"James", "Sue"/"Susan", "Steve"/"Stephen") is still
  -- caught. lower() on the stored columns only: there is no unaccent on prod, and these five surnames carry no accents.
  -- Rana is not in bcc_new_person; she is reused by the Rana gates above.
  SELECT count(DISTINCT p.id),
         string_agg(DISTINCT format('%s -> existing %s "%s" (last_name %s, alternate_names %s)',
                                    n.full_name, p.id, p.full_name, p.last_name, p.alternate_names), '; ')
    INTO v, v_detail
    FROM bcc_new_person n
    JOIN essentials.politicians p
      ON lower(coalesce(p.last_name, '')) = lower(n.last_name)
      OR lower(p.full_name) LIKE '% ' || lower(n.last_name)
      OR EXISTS (SELECT 1 FROM unnest(coalesce(p.alternate_names, '{}'::text[])) alt
                  WHERE lower(alt) LIKE '% ' || lower(n.last_name) OR lower(alt) = lower(n.last_name))
   WHERE coalesce(p.source, '') NOT LIKE 'CA_PENDING bcc:%'
     AND (EXISTS (SELECT 1 FROM essentials.office_terms ot
                    JOIN essentials.offices ofc ON ofc.id = ot.office_id
                    JOIN essentials.chambers ch ON ch.id = ofc.chamber_id
                   WHERE ot.politician_id = p.id
                     AND ch.government_id IN (SELECT government_id FROM bcc_office))
       OR EXISTS (SELECT 1 FROM essentials.race_candidates rc
                    JOIN essentials.races r ON r.id = rc.race_id
                    JOIN essentials.offices ofc ON ofc.id = r.office_id
                    JOIN essentials.chambers ch ON ch.id = ofc.chamber_id
                   WHERE rc.politician_id = p.id
                     AND ch.government_id IN (SELECT government_id FROM bcc_office)));
  IF v <> 0 THEN
    RAISE EXCEPTION 'CA_PENDING pre-flight: % existing person row(s) in Bloomington''s government share a surname '
      'with a person this migration would create. If one is the same person, reuse that row (take it out of '
      'bcc_new_person and add it to bcc_people by id); if not, note why here. Found: %', v, v_detail;
  END IF;
  SELECT count(*), string_agg(DISTINCT p.full_name, ', ') INTO v, v_detail
    FROM bcc_new_person n JOIN essentials.politicians p ON lower(p.full_name) = lower(n.full_name)
   WHERE coalesce(p.source, '') NOT LIKE 'CA_PENDING bcc:%';
  IF v <> 0 THEN
    RAISE NOTICE 'CA_PENDING: % same-name row(s) elsewhere (not Bloomington), not reused: %', v, v_detail;
  END IF;
END $$;

-- ─── 1. Five new people ───────────────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.politicians (full_name, first_name, last_name, alternate_names, is_active, source)
SELECT n.full_name, n.first_name, n.last_name, n.alternate_names, false,
       'CA_PENDING bcc: former Bloomington Common Council member, named on ' || n.seat_url
         || ' (city OnBoard seat page, saved 2026-11-25)'
  FROM bcc_new_person n
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p
                    WHERE p.full_name = n.full_name AND p.source LIKE 'CA_PENDING bcc:%');

-- Everyone whose office_terms rows this migration writes: 9 current members, Rana, the 5 new people.
CREATE TEMP TABLE bcc_people ON COMMIT DROP AS
SELECT a.key, a.politician_id FROM bcc_anchor a
UNION
SELECT 'rana', p.id FROM essentials.politicians p
 WHERE lower(p.full_name) = 'shruti rana'
   AND EXISTS (SELECT 1 FROM essentials.office_terms ot
                WHERE ot.politician_id = p.id AND ot.office_id IN (SELECT office_id FROM bcc_office))
UNION
SELECT n.key, p.id FROM bcc_new_person n
  JOIN essentials.politicians p ON p.full_name = n.full_name AND p.source LIKE 'CA_PENDING bcc:%';

DO $$ BEGIN
  IF (SELECT count(*) FROM bcc_people) <> 15 OR (SELECT count(DISTINCT key) FROM bcc_people) <> 15
     OR (SELECT count(DISTINCT politician_id) FROM bcc_people) <> 15 THEN
    RAISE EXCEPTION 'CA_PENDING: expected 15 distinct people in scope, found % rows', (SELECT count(*) FROM bcc_people);
  END IF;
END $$;

-- ▼▼ BLOCK A — PASTE BEFORE YOUR FIRST WRITE TO essentials.office_terms ▼▼

-- @incumbency-decision: gated — dates the 9 current members' undated terms (and replaces Daily's month-precision start) and Rana's, and inserts 7 closed 2020-2023 terms on the 9 council seats; the gate checks every race row these 15 people have

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
   AND rc.politician_id IN (SELECT politician_id FROM bcc_people);

-- ▲▲ END OF BLOCK A ▲▲

-- ─── 2. Date the existing terms (old term_start NULL; old start_precision kept in source) ──────────────────────
UPDATE essentials.office_terms ot
   SET term_start      = pl.term_start,
       start_precision = 'day',
       source          = ot.source || ' | CA_PENDING bcc: dated ' || pl.term_start || ' per ' || s.seat_url
                         || ' (city OnBoard seat page, saved 2026-11-25); start was '
                         || coalesce(ot.term_start::text, 'NULL') || ', precision ''' || ot.start_precision || ''''
  FROM bcc_plan pl
  JOIN bcc_seat s    ON s.seat_code = pl.seat_code
  JOIN bcc_anchor a  ON a.seat_code = pl.seat_code AND a.key = pl.key
 WHERE pl.kind = 'date_current'
   AND ot.office_id = a.office_id
   AND ot.politician_id = a.politician_id
   AND (ot.term_start IS NULL OR ot.start_precision <> 'day')
   AND (ot.term_end IS NULL OR ot.term_end >= CURRENT_DATE);

UPDATE essentials.office_terms ot
   SET term_start      = pl.term_start,
       start_precision = 'day',
       source          = ot.source || ' | CA_PENDING bcc: dated ' || pl.term_start || ' per ' || s.seat_url
                         || ' (city OnBoard seat page, saved 2026-11-25); start_precision was '''
                         || ot.start_precision || ''''
  FROM bcc_plan pl
  JOIN bcc_seat s     ON s.seat_code = pl.seat_code
  JOIN bcc_anchor a   ON a.seat_code = pl.seat_code
  JOIN bcc_people pp  ON pp.key = pl.key
 WHERE pl.kind = 'date_rana'
   AND ot.office_id = a.office_id
   AND ot.politician_id = pp.politician_id
   AND ot.term_end = pl.term_end
   AND ot.term_start IS NULL;

-- ─── 3. Seven closed terms ───────────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.office_terms
  (office_id, politician_id, term_start, term_end, start_precision, how_started, how_ended, source)
SELECT a.office_id, pp.politician_id, pl.term_start, pl.term_end, 'day', 'elected', 'term_expired',
       'CA_PENDING bcc: ' || pl.full_name || ', seat ' || pl.seat_code || ', ' || pl.term_start || ' to '
         || pl.term_end || ' per ' || s.seat_url || ' (city OnBoard seat page, saved 2026-11-25)'
  FROM bcc_plan pl
  JOIN bcc_seat s    ON s.seat_code = pl.seat_code
  JOIN bcc_anchor a  ON a.seat_code = pl.seat_code
  JOIN bcc_people pp ON pp.key = pl.key
 WHERE pl.kind = 'insert'
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot
                    WHERE ot.office_id = a.office_id AND ot.politician_id = pp.politician_id
                      AND ot.term_start = pl.term_start);

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
  SELECT count(*) INTO v_planned FROM bcc_people;
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

-- ─── 4. Post-verify ──────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v int; v_active int;
BEGIN
  -- Every roster row is now exactly one dated term on its seat.
  SELECT count(*) INTO v
    FROM bcc_plan pl
    JOIN bcc_anchor a  ON a.seat_code = pl.seat_code
    JOIN bcc_people pp ON pp.key = pl.key
   WHERE (SELECT count(*) FROM essentials.office_terms ot
           WHERE ot.office_id = a.office_id AND ot.politician_id = pp.politician_id
             AND ot.term_start = pl.term_start AND ot.term_end IS NOT DISTINCT FROM pl.term_end) = 1;
  IF v <> 17 THEN
    RAISE EXCEPTION 'CA_PENDING: % of 17 roster spans are on the council offices as planned', v;
  END IF;

  -- What the council-record reader loads (refresh.ts loadCouncilTerms): dated terms under the chamber slug.
  SELECT count(*) INTO v
    FROM essentials.office_terms ot
    JOIN essentials.offices ofc ON ofc.id = ot.office_id
    JOIN essentials.chambers ch ON ch.id = ofc.chamber_id
   WHERE ch.slug = 'bloomington-common-council' AND ofc.normalized_position_name = 'City Legislature'
     AND ot.term_start IS NOT NULL;
  IF v <> 17 THEN
    RAISE EXCEPTION 'CA_PENDING: the reader would load % dated council terms, expected 17', v;
  END IF;
  SELECT count(*) INTO v FROM essentials.office_terms ot
   WHERE ot.office_id IN (SELECT office_id FROM bcc_office) AND ot.term_start IS NULL;
  IF v <> 0 THEN
    RAISE EXCEPTION 'CA_PENDING: % undated term(s) remain on the council offices', v;
  END IF;

  -- The same nine people hold the same nine seats today.
  SELECT count(*) INTO v
    FROM bcc_anchor a JOIN essentials.office_current_holder och
      ON och.office_id = a.office_id AND och.politician_id = a.politician_id;
  IF v <> 9 THEN
    RAISE EXCEPTION 'CA_PENDING: % of 9 seats still show their current member', v;
  END IF;

  -- New people are former members: inactive, and five of them.
  SELECT count(*), count(*) FILTER (WHERE p.is_active) INTO v, v_active
    FROM essentials.politicians p WHERE p.source LIKE 'CA_PENDING bcc:%';
  IF v <> 5 OR v_active <> 0 THEN
    RAISE EXCEPTION 'CA_PENDING: % new people (want 5), % active (want 0)', v, v_active;
  END IF;

  RAISE NOTICE 'CA_PENDING OK: 17 dated council terms (10 dated in place, 7 inserted), 5 new people, 9 seats unchanged';
END $$;

COMMIT;
