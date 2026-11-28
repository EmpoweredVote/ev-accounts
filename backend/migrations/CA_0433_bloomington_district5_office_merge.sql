-- Migration CA_0433_bloomington_district5_office_merge: merge Bloomington's duplicate District 5 council office
--
-- 🔴 RUN THIS BEFORE CA_0434_bloomington_council_people_and_terms.sql. That file finds the council's seats by
--   chamber slug plus position name and stops unless it finds exactly 9; with this duplicate present it finds 10.
--
-- WHY: Bloomington's District 5 council seat exists as TWO office rows in one district, so the term history is split:
--
--   | office                                  | title                                      | term                              |
--   | --------------------------------------- | ------------------------------------------ | --------------------------------- |
--   | RETIRE 48d59066-51aa-4fca-9e92-edecfaeb4388 | Bloomington City Common Council - District 5 | Shruti Rana, start NULL, end 2024-02-07 |
--   | KEEP   c59ebfa0-e6a2-4e9c-ba1c-db97f79c58d1 | City Common Council - District 5             | Courtney Daily, 2024-03-01 (month precision), open |
--
--   Both sit in district cd647e3c-e2d6-40a0-b8db-b9dfbe6f597d (geo_id 180586000005). KEEP is the row the other
--   council seats' titles match and the one the sitting member holds. RETIRE carries 0 races, 0 office_swearing_in
--   and 0 rows in inform.stance_coder_labels / stance_gold_labels / stance_research_review (measured on the live
--   database, 2026-11-26, read-only). Both rows have is_vacant false; this file leaves that flag alone.
--
-- WHAT: move Rana's closed term onto KEEP, repoint Rana's politicians.office_id snapshot to KEEP, delete RETIRE.
--
-- 🔴 MERGING TWO OFFICE ROWS IS NOT DELETING ONE (backend/migrations/CLAUDE.md; modelled on
--   CC_0296_merge_duplicate_indiana_comptroller_office.sql). office_terms.office_id is ON DELETE CASCADE, so deleting
--   RETIRE first would eat Rana's term. politicians.office_id has NO foreign key, so the delete would leave Rana's
--   snapshot pointing at nothing. The order is therefore: move the term, repoint the snapshot, then delete.
--   The other FKs into essentials.offices (races; stance_gold_labels and stance_research_review SET NULL;
--   stance_coder_labels and office_swearing_in CASCADE) are all gated to 0 rows on RETIRE in the pre-flight.
--
-- WHAT IT CHANGES FOR A VOTER: nothing visible. RETIRE held no current holder (Rana's term ended 2024-02-07), so it
--   was never in office_current_holder with a holder. After the merge, District 5 has one office with both terms.
--
-- OCCUPANCY: neither office is flagged vacant and KEEP stays seated, so the three offices_missing_terms numbers do
--   not move. Not gated here; no term is created or removed, one is moved.
--
-- OVERWRITTEN VALUES: office_terms.office_id on Rana's term (48d59066-... -> c59ebfa0-...), and
--   politicians.office_id on Rana's row (48d59066-... -> c59ebfa0-...). Nothing else is overwritten.
--
-- Slot: CA_0433, reserved 2026-11-26 through the steward allocator. Apply it BEFORE
--   CA_0434_bloomington_council_people_and_terms.sql. Not applied by this commit.
--   Idempotent: if RETIRE is already gone, it checks that KEEP holds both terms and stops.

BEGIN;

-- @incumbency-decision: no-effect — moves one closed term (Rana, ends 2024-02-07) between two offices of the same district. RETIRE has 0 races, and the incumbency predicate only looks at elections from the last year, which a term that ended in 2024 cannot cover.

-- ─── PRE-FLIGHT ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_retire   CONSTANT uuid := '48d59066-51aa-4fca-9e92-edecfaeb4388';
  v_keep     CONSTANT uuid := 'c59ebfa0-e6a2-4e9c-ba1c-db97f79c58d1';
  v_district CONSTANT uuid := 'cd647e3c-e2d6-40a0-b8db-b9dfbe6f597d';
  v_rana     CONSTANT uuid := '57470eda-1734-4543-ae2a-893b8bcc0a86';
  v_daily    CONSTANT uuid := '43fd01ea-c039-4b26-87aa-49cddcb54835';
  v_n        int;
  v_txt      text;
BEGIN
  -- Idempotent: RETIRE already gone means the merge ran. KEEP must hold both terms; then stop.
  IF NOT EXISTS (SELECT 1 FROM essentials.offices WHERE id = v_retire) THEN
    SELECT count(*) INTO v_n FROM essentials.office_terms
     WHERE office_id = v_keep AND politician_id IN (v_rana, v_daily);
    IF v_n <> 2 THEN
      RAISE EXCEPTION 'CA_0433 d5 pre-flight: the retired office is gone but the kept office % holds % of the 2 terms (Rana, Daily) - the merge half-ran', v_keep, v_n;
    END IF;
    RAISE NOTICE 'CA_0433 d5: already applied - nothing to do.';
    RETURN;
  END IF;

  -- Both rows exist, with the exact titles, in the same district.
  SELECT string_agg(o.id::text || ' | ' || o.title || ' | ' || o.district_id::text, ' ;; ' ORDER BY o.title)
    INTO v_txt
    FROM essentials.offices o WHERE o.id IN (v_retire, v_keep);
  IF v_txt IS DISTINCT FROM
       v_retire::text || ' | Bloomington City Common Council - District 5 | ' || v_district::text || ' ;; '
    || v_keep::text   || ' | City Common Council - District 5 | '             || v_district::text THEN
    RAISE EXCEPTION 'CA_0433 d5 pre-flight: the two District 5 rows are not the shape measured. Got: %', v_txt;
  END IF;

  -- RETIRE: exactly one term, Rana's, undated start, ending 2024-02-07.
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE office_id = v_retire;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0433 d5 pre-flight: expected exactly 1 term on the retired office, found %', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms
   WHERE office_id = v_retire AND politician_id = v_rana
     AND term_start IS NULL AND term_end = DATE '2024-02-07';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0433 d5 pre-flight: the retired office''s one term is not Shruti Rana, start NULL, end 2024-02-07';
  END IF;

  -- KEEP: exactly one term, Daily's, still open.
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE office_id = v_keep;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0433 d5 pre-flight: expected exactly 1 term on the kept office, found %', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms
   WHERE office_id = v_keep AND politician_id = v_daily AND term_end IS NULL;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0433 d5 pre-flight: the kept office''s one term is not an open term held by Courtney Daily';
  END IF;

  -- 🔴 Nothing may hang off RETIRE that the delete would drop or null. Two FKs SET NULL (silent), two CASCADE.
  SELECT count(*) INTO v_n FROM essentials.races WHERE office_id = v_retire;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0433 d5 pre-flight: the retired office carries % race(s) - deleting it would orphan an election', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.office_swearing_in WHERE office_id = v_retire;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0433 d5 pre-flight: % office_swearing_in row(s) on the retired office would cascade away', v_n;
  END IF;
  SELECT (SELECT count(*) FROM inform.stance_coder_labels    WHERE office_id = v_retire)
       + (SELECT count(*) FROM inform.stance_gold_labels     WHERE office_id = v_retire)
       + (SELECT count(*) FROM inform.stance_research_review WHERE office_id = v_retire)
    INTO v_n;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0433 d5 pre-flight: % stance row(s) reference the retired office - repoint them first', v_n;
  END IF;

  -- The snapshot column has no FK: nothing but Rana may point at RETIRE.
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE office_id = v_retire AND id <> v_rana;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0433 d5 pre-flight: % politician(s) other than Rana have office_id on the retired office', v_n;
  END IF;
END $$;

-- ─── THE MERGE ───────────────────────────────────────────────────────────────────────────────────

-- 1. Move Rana's term onto KEEP. This is the whole merge; the rest is tidying. Guarded, so a re-run moves nothing.
UPDATE essentials.office_terms
   SET office_id = 'c59ebfa0-e6a2-4e9c-ba1c-db97f79c58d1'
 WHERE office_id = '48d59066-51aa-4fca-9e92-edecfaeb4388';

-- 2. Repoint the deprecated snapshot. NO FOREIGN KEY GUARDS THIS (see the header).
UPDATE essentials.politicians
   SET office_id = 'c59ebfa0-e6a2-4e9c-ba1c-db97f79c58d1'
 WHERE office_id = '48d59066-51aa-4fca-9e92-edecfaeb4388';

-- 3. Retire the duplicate. Its term has moved, so the ON DELETE CASCADE takes nothing.
DELETE FROM essentials.offices
 WHERE id = '48d59066-51aa-4fca-9e92-edecfaeb4388';

-- ─── POST-VERIFY ─────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_retire CONSTANT uuid := '48d59066-51aa-4fca-9e92-edecfaeb4388';
  v_keep   CONSTANT uuid := 'c59ebfa0-e6a2-4e9c-ba1c-db97f79c58d1';
  v_rana   CONSTANT uuid := '57470eda-1734-4543-ae2a-893b8bcc0a86';
  v_daily  CONSTANT uuid := '43fd01ea-c039-4b26-87aa-49cddcb54835';
  v_n      int;
BEGIN
  IF EXISTS (SELECT 1 FROM essentials.offices WHERE id = v_retire) THEN
    RAISE EXCEPTION 'CA_0433 d5: the duplicate office still exists';
  END IF;

  -- Nothing still points at the deleted id (the snapshot column has no FK, so ask it directly).
  SELECT (SELECT count(*) FROM essentials.office_terms WHERE office_id = v_retire)
       + (SELECT count(*) FROM essentials.races        WHERE office_id = v_retire)
       + (SELECT count(*) FROM essentials.politicians  WHERE office_id = v_retire)
    INTO v_n;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0433 d5: % reference(s) still point at the deleted office', v_n;
  END IF;

  -- KEEP holds Rana's closed term and Daily's term, and those two do not overlap. NOT a total count: the
  -- people-and-terms file later adds more terms to this office, and a re-run of this file must still pass.
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms
                  WHERE office_id = v_keep AND politician_id = v_rana AND term_end = DATE '2024-02-07') THEN
    RAISE EXCEPTION 'CA_0433 d5: Rana''s closed term is not on the kept office';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms
                  WHERE office_id = v_keep AND politician_id = v_daily AND term_end IS NULL) THEN
    RAISE EXCEPTION 'CA_0433 d5: Daily''s open term is not on the kept office';
  END IF;
  SELECT count(*) INTO v_n
    FROM essentials.office_terms a JOIN essentials.office_terms b ON a.office_id = b.office_id AND a.id < b.id
   WHERE a.office_id = v_keep AND a.politician_id IN (v_rana, v_daily) AND b.politician_id IN (v_rana, v_daily)
     AND daterange(coalesce(a.term_start, '-infinity'), coalesce(a.term_end, 'infinity'), '[]')
      && daterange(coalesce(b.term_start, '-infinity'), coalesce(b.term_end, 'infinity'), '[]');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0433 d5: the two terms on the kept office overlap';
  END IF;

  -- The snapshot points at the surviving office.
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = v_rana AND office_id = v_keep) THEN
    RAISE EXCEPTION 'CA_0433 d5: Rana''s politicians.office_id snapshot was not repointed to the kept office';
  END IF;

  -- 10 offices remain under the chamber slug: 9 council seats and the City Clerk.
  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.chambers ch ON ch.id = o.chamber_id
   WHERE ch.slug = 'bloomington-common-council';
  IF v_n <> 10 THEN
    RAISE EXCEPTION 'CA_0433 d5: expected 10 offices under chamber slug bloomington-common-council, found %', v_n;
  END IF;
  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.chambers ch ON ch.id = o.chamber_id
   WHERE ch.slug = 'bloomington-common-council' AND o.normalized_position_name = 'City Legislature';
  IF v_n <> 9 THEN
    RAISE EXCEPTION 'CA_0433 d5: expected 9 City Legislature offices under the slug, found %', v_n;
  END IF;

  RAISE NOTICE 'CA_0433 d5 OK: District 5 merged onto %; 10 offices under the slug, 9 City Legislature', v_keep;
END $$;

COMMIT;
