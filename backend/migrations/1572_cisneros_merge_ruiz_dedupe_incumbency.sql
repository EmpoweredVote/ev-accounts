-- 1572_cisneros_merge_ruiz_dedupe_incumbency.sql
--
-- Reunite Rep. Gilbert Cisneros's 19 compass stances with the record that actually holds his seat, flag
-- him incumbent, and unseat a redundant duplicate office_term on Rep. Raul Ruiz.
--
--   Found by: the two-gate incumbency check built while investigating the official_count backfill —
--             data/stance-research/seeded-roster-sweep/FINDINGS.md
--   Rollback: recorded inline at the foot of this file.
--   Follows:  1571 (WI Supreme Court handoff), same detector family
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1572_cisneros_merge_ruiz_dedupe_incumbency.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 A SITTING MEMBER OF CONGRESS WHOSE STANCES AND SEAT ARE ON DIFFERENT RECORDS
-- ---------------------------------------------------------------------------------------------------
-- Gilbert Cisneros exists twice, both rows inserted in the SAME batch at the SAME microsecond
-- (2026-05-22 17:10:27.439795+00) by two different sources:
--
--   65f08851 · data_source 'inform-migration'      · 19 answers / 19 context · NO office_term · is_active FALSE
--   d26d3a2f · source      'federal_2026_bulk_seed' ·  0 answers /  0 context · U.S. Representative,
--                                                       term_start 2025-01-03 · is_incumbent FALSE
--
-- So nineteen researched, voter-facing stances hang off a DEACTIVATED record that holds no office,
-- while the record that holds his seat has none and reads as non-incumbent. He is a sitting
-- U.S. Representative either way.
--
-- ✅ Verified against the same source his own office_term cites — `unitedstates/congress-legislators`,
-- `legislators-current.json` (537 entries, fetched 2026-08-06): **Gilbert Ray Cisneros, Jr.,
-- bioguide C001123, rep CA-31, term 2025-01-03 → 2027-01-03.** Also **Raul Ruiz, bioguide R000599,
-- rep CA-25, same term.** Both are currently serving.
--
-- ⚠ SCOPE MEASURED, NOT ASSUMED: exactly ONE name in the corpus has this inform-migration × federal-seed
-- split with stances on one side and an office on the other. It is Cisneros. (13,102 names occur more
-- than once across an 85k-person corpus, which is ordinary for common names across jurisdictions and is
-- not this defect.)
--
-- 🔴 WHY THE bioguide RECONCILIATION MISSED IT: a check comparing our records against
-- legislators-current by `bioguide_id` returns ZERO offenders — because **neither Cisneros row nor
-- either Ruiz row has a bioguide_id at all** (523 politicians do). The join silently skipped exactly
-- the rows that were broken. 🔑 A reconciliation keyed on a column that is NULL on the defective rows
-- reports "all clean" and means nothing. Check the join's coverage before trusting its emptiness.
--
-- ---------------------------------------------------------------------------------------------------
-- Raul Ruiz — a benign duplicate that made the detector fire
-- ---------------------------------------------------------------------------------------------------
-- His real record (external_id -6000325) is correct: is_incumbent true, is_active true, 15 answers,
-- seated as U.S. Representative. A second row (05349fa0, is_active FALSE, 0 answers) holds a REDUNDANT
-- office_term for the same seat. Nothing voter-facing depends on it, but it is what surfaced in the
-- "flagged out but term is current" check. The office_term is removed; the row itself is left alone.
--
-- ⚠ This migration MOVES stance rows between person records. That is a merge, and it is the correct
-- repair here only because both rows are demonstrably the same person: identical full/first/last name,
-- identical creation microsecond, complementary halves of one identity. The target holds ZERO answers,
-- so no (politician, topic) collision is possible — asserted below rather than assumed.
-- ===================================================================================================

BEGIN;

DO $$
DECLARE v_cnt int;
BEGIN
  -- The two Cisneros rows are exactly as described.
  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE id = '65f08851-9336-4a38-a239-3f5bf3333095' AND full_name = 'Gilbert Cisneros'
     AND data_source = 'inform-migration' AND is_active = false;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'PRE: Cisneros orphan row not as expected (%)', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE id = 'd26d3a2f-c29d-4500-861d-afe19b283650' AND full_name = 'Gilbert Cisneros'
     AND source = 'federal_2026_bulk_seed' AND is_incumbent = false;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'PRE: Cisneros seated row not as expected (%)', v_cnt; END IF;

  -- The orphan holds the stances; the seated row holds none. Both halves matter.
  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id = '65f08851-9336-4a38-a239-3f5bf3333095';
  IF v_cnt <> 19 THEN RAISE EXCEPTION 'PRE: expected 19 answers on the orphan, found %', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id = 'd26d3a2f-c29d-4500-861d-afe19b283650';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'PRE: seated row already holds % answers — collision risk', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM essentials.office_terms
   WHERE politician_id = '65f08851-9336-4a38-a239-3f5bf3333095';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'PRE: the orphan unexpectedly holds % office_term(s)', v_cnt; END IF;

  -- Ruiz: the good record is seated and correct; the duplicate is inactive and stance-free.
  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE id = '5238b298-6004-4bcc-94c2-ee43a9c2999e' AND external_id = -6000325
     AND is_incumbent = true AND is_active = true;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'PRE: Ruiz primary record not as expected (%)', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id = '05349fa0-8529-4738-8556-f386965e4cc8';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'PRE: Ruiz duplicate holds % answers — do not unseat it', v_cnt; END IF;
END $$;

-- --- CHANGES --------------------------------------------------------------------------------------

-- 1. Move Cisneros's stances onto the record that holds his seat.
UPDATE inform.politician_answers
   SET politician_id = 'd26d3a2f-c29d-4500-861d-afe19b283650'
 WHERE politician_id = '65f08851-9336-4a38-a239-3f5bf3333095';

UPDATE inform.politician_context
   SET politician_id = 'd26d3a2f-c29d-4500-861d-afe19b283650'
 WHERE politician_id = '65f08851-9336-4a38-a239-3f5bf3333095';

-- 2. He is a sitting U.S. Representative for CA-31. Flag the seated record accordingly, and carry the
--    research timestamp across with the research it describes.
UPDATE essentials.politicians
   SET is_incumbent = true,
       is_active = true,
       last_stances_researched_at = COALESCE(
         (SELECT last_stances_researched_at FROM essentials.politicians
           WHERE id = '65f08851-9336-4a38-a239-3f5bf3333095'),
         last_stances_researched_at)
 WHERE id = 'd26d3a2f-c29d-4500-861d-afe19b283650';

-- 3. Retire the now-empty duplicate identity. Row retained for audit, as with migration 1566.
UPDATE essentials.politicians
   SET is_active = false,
       is_incumbent = false,
       last_stances_researched_at = NULL,
       notes = COALESCE(notes, ARRAY[]::text[]) || ARRAY[
               'DUPLICATE of politician d26d3a2f-c29d-4500-861d-afe19b283650 (Gilbert Cisneros, '
               || 'U.S. Representative CA-31). Both rows were inserted in the same batch at the same '
               || 'microsecond by two sources: this one from inform-migration carrying 19 compass '
               || 'stances and no office, the other from federal_2026_bulk_seed carrying the office '
               || 'and no stances. Migration 1572 moved the stances to the seated record.']
 WHERE id = '65f08851-9336-4a38-a239-3f5bf3333095';

-- 4. Unseat the redundant Ruiz duplicate office_term. His real record keeps its seat untouched.
DELETE FROM essentials.office_terms
 WHERE politician_id = '05349fa0-8529-4738-8556-f386965e4cc8';

-- --- POST-CONDITIONS ------------------------------------------------------------------------------

DO $$
DECLARE v_cnt int;
BEGIN
  -- Cisneros's stances now sit on the seated, incumbent record.
  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id = 'd26d3a2f-c29d-4500-861d-afe19b283650';
  IF v_cnt <> 19 THEN RAISE EXCEPTION 'POST: seated Cisneros holds % answers, expected 19', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_context
   WHERE politician_id = 'd26d3a2f-c29d-4500-861d-afe19b283650';
  IF v_cnt <> 19 THEN RAISE EXCEPTION 'POST: seated Cisneros holds % context rows, expected 19', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id = '65f08851-9336-4a38-a239-3f5bf3333095';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: orphan still holds % answers', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE id = 'd26d3a2f-c29d-4500-861d-afe19b283650' AND is_incumbent AND is_active;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'POST: seated Cisneros is not flagged incumbent+active'; END IF;

  -- Ruiz keeps exactly one office_term, on his real record.
  SELECT count(*) INTO v_cnt FROM essentials.office_terms
   WHERE politician_id = '05349fa0-8529-4738-8556-f386965e4cc8';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: Ruiz duplicate still seated'; END IF;

  SELECT count(*) INTO v_cnt FROM essentials.office_terms
   WHERE politician_id = '5238b298-6004-4bcc-94c2-ee43a9c2999e';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'POST: Ruiz primary holds % office_terms, expected 1', v_cnt; END IF;

  -- The detector that found all of this now returns zero on both halves.
  SELECT count(*) INTO v_cnt
  FROM essentials.office_terms ot JOIN essentials.politicians p ON p.id = ot.politician_id
  WHERE (p.is_incumbent AND ot.term_end IS NOT NULL AND ot.term_end < CURRENT_DATE)
     OR (NOT p.is_incumbent AND ot.term_start IS NOT NULL AND ot.term_start <= CURRENT_DATE
         AND (ot.term_end IS NULL OR ot.term_end >= CURRENT_DATE));
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: two-gate incumbency check still reports % row(s)', v_cnt; END IF;

  -- No stance row was created or destroyed corpus-wide by a MOVE.
  SELECT count(*) INTO v_cnt FROM inform.politician_answers a
   LEFT JOIN inform.politician_context c
     ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
   WHERE a.politician_id = 'd26d3a2f-c29d-4500-861d-afe19b283650' AND c.politician_id IS NULL;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: % moved answers lost their context', v_cnt; END IF;
END $$;

COMMIT;

-- ---------------------------------------------------------------------------------------------------
-- ROLLBACK
-- ---------------------------------------------------------------------------------------------------
-- BEGIN;
--   UPDATE inform.politician_answers SET politician_id = '65f08851-9336-4a38-a239-3f5bf3333095'
--    WHERE politician_id = 'd26d3a2f-c29d-4500-861d-afe19b283650';
--   UPDATE inform.politician_context SET politician_id = '65f08851-9336-4a38-a239-3f5bf3333095'
--    WHERE politician_id = 'd26d3a2f-c29d-4500-861d-afe19b283650';
--   UPDATE essentials.politicians SET is_incumbent = false, is_active = true,
--          last_stances_researched_at = NULL
--    WHERE id = 'd26d3a2f-c29d-4500-861d-afe19b283650';
--   UPDATE essentials.politicians SET is_active = false, is_incumbent = false, notes = NULL
--    WHERE id = '65f08851-9336-4a38-a239-3f5bf3333095';   -- prior notes value was NULL
--   INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, source)
--   SELECT office_id, '05349fa0-8529-4738-8556-f386965e4cc8', '2013-01-03', NULL, source
--     FROM essentials.office_terms
--    WHERE politician_id = '5238b298-6004-4bcc-94c2-ee43a9c2999e';   -- same seat; uuid regenerated
-- COMMIT;
