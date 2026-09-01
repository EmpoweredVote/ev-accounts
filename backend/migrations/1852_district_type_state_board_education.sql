-- 1852_district_type_state_board_education.sql
--
-- =============================================================================
-- 1852: Reclassify state boards of education to district_type STATE_BOARD_EDUCATION
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews.
--
-- WHAT THIS DOES
--   essentials.districts: reclassify the boards of education from the two legacy values to a
--   single dedicated type:
--       STATE_BOARD   (15 rows) -> STATE_BOARD_EDUCATION   -- Utah State Board of Education, districts 1-15
--       SCHOOL_BOARD  ( 9 rows) -> STATE_BOARD_EDUCATION   -- DC State Board of Education, wards 1-8 + at-large
--   Local school boards keep district_type = SCHOOL (unchanged, 167 districts / 380 officials).
--
-- WHY
--   The essentials app already ships expecting STATE_BOARD_EDUCATION — classify.js has
--   `EDUCATOR_DISTRICT_TYPES = {"SCHOOL","STATE_BOARD_EDUCATION"}`, groupHierarchy.js routes it
--   to a dedicated accordion, and zipResults.js labels it "state board of education members"
--   (Phase 133 SCHEMA-02, "SCHOOL_BOARD unified into STATE_BOARD_EDUCATION on 2026-08-31"). The
--   DB was never migrated to match, so it still carries the old STATE_BOARD / SCHOOL_BOARD values.
--   Isolating a dedicated education type (rather than the generic STATE_BOARD, which will later hold
--   non-education state boards) is the goal — per Chris, 2026-08-31.
--
--   It also makes the compass education lens correct: CA_0076 already set the education lens's
--   auto_district_types to {SCHOOL, STATE_BOARD_EDUCATION}; that value matches no district until now.
--
-- ⚠ SHIP THE BACKEND CODE CHANGE WITH THIS MIGRATION
--   backend/src/lib/geoIdGuard.ts and backend/src/lib/districtQueries.ts hard-code DC's board as
--   SCHOOL_BOARD in the address->district lookup (mtfcc G5220, migration 1485). Once DC's board is
--   STATE_BOARD_EDUCATION, those clauses must read STATE_BOARD_EDUCATION or DC SBOE members become
--   unreachable by address. Both files are updated in the same PR as this migration.
--
-- SCOPE CHECK (verified against prod 2026-08-31)
--   ALL 15 STATE_BOARD rows are Utah SBOE; ALL 9 SCHOOL_BOARD rows are DC SBOE — every one is a
--   board of education, so the blanket reclassification of these two values is correct and complete.
--   Other tables are unaffected: essentials.position_descriptions has no STATE_BOARD/SCHOOL_BOARD
--   rows; inform.politicians (2 stale rows) and staging.politicians hold none; inform.district_boundaries
--   uses a separate lowercase geo vocabulary ('school_district') with no STATE_BOARD value.
--
-- IDEMPOTENT: re-run updates 0 rows (no STATE_BOARD/SCHOOL_BOARD left). Verify gate asserts the end
--   state either way. To revert, restore the two prior values (Utah->STATE_BOARD, DC->SCHOOL_BOARD)
--   and revert the two backend files.
-- =============================================================================

BEGIN;

UPDATE essentials.districts
   SET district_type = 'STATE_BOARD_EDUCATION'
 WHERE district_type IN ('STATE_BOARD', 'SCHOOL_BOARD');

-- ── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_left int;
  v_edu  int;
BEGIN
  -- No legacy education-board values remain.
  SELECT count(*) INTO v_left FROM essentials.districts
   WHERE district_type IN ('STATE_BOARD', 'SCHOOL_BOARD');
  IF v_left <> 0 THEN
    RAISE EXCEPTION '1852: % districts still carry STATE_BOARD/SCHOOL_BOARD after reclassify', v_left;
  END IF;

  -- The education boards now carry the dedicated type (Utah 15 + DC 9 = at least 24).
  SELECT count(*) INTO v_edu FROM essentials.districts WHERE district_type = 'STATE_BOARD_EDUCATION';
  IF v_edu < 24 THEN
    RAISE EXCEPTION '1852: expected >= 24 STATE_BOARD_EDUCATION districts, found %', v_edu;
  END IF;

  RAISE NOTICE '1852 OK — % districts now STATE_BOARD_EDUCATION; 0 legacy STATE_BOARD/SCHOOL_BOARD remain. Deploy geoIdGuard.ts + districtQueries.ts with this.', v_edu;
END $$;

COMMIT;
