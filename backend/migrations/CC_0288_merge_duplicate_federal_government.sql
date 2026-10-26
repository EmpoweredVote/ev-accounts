-- CC_0288_merge_duplicate_federal_government.sql
--
-- The United States Federal Government is TWO rows in `essentials.governments`, and has
-- been for long enough that two migrations already work around it. Merge them.
--
--   fd292119-3e3a-4bda-8853-ce1ee4807865  type 'federal'   state 'US'   1 chamber,  9 offices
--   0a6b51aa-00bb-4c15-b0f9-7f9da9150f47  type 'NATIONAL'  state ''    28 chambers, 615 offices
--
-- The split is not thematic. The 'federal' row holds exactly one chamber -- the U.S.
-- Supreme Court, and its nine justices. The 'NATIONAL' row holds everything else: the
-- President, the Vice President, the Cabinet, the House and the Senate. There is no
-- reading of "federal government" under which the Supreme Court is a different
-- government from the Presidency, so this is a duplicate, not a distinction.
--
-- 🔴 REPOINT BEFORE DELETING. `essentials.chambers.government_id` HAS NO FOREIGN KEY.
-- Deleting the 'federal' row first would not error and would not cascade -- it would
-- leave the Supreme Court chamber pointing at a government that no longer exists, and
-- every read that reaches a justice through `JOIN essentials.governments` would quietly
-- return nothing. The nine justices would disappear from Essentials with no failure
-- anywhere. `essentials.districts.government_id` is the only enforced reference to this
-- table, and it holds 0 rows for either federal row, so the FK cannot protect us here.
--
-- WHY THIS IS SAFE FOR THE READ PATH. Federal officials never reach a voter through
-- `governments.geo_id`. The landing-page chip query filters `WHERE g.geo_id = ANY($1)`,
-- and a national government has no TIGER geoid to carry; justices are served instead by
-- the supplemental query in `essentialsBrowseService.ts`, which keys on
-- `d.district_type IN ('NATIONAL_UPPER','STATE_EXEC','NATIONAL_EXEC','NATIONAL_JUDICIAL')`
-- through `essentials.districts`. So a NULL `geo_id` on the surviving row is correct and
-- is left alone -- this migration removes a duplicate, it does not invent a geoid.
--
-- NOTHING LIVE DISTINGUISHES THE TWO TYPE VALUES. The only code that reads them at all is
-- 1543_federal_scope_housing_criminal_justice.sql and 1545_state_scope_criminal_justice.sql,
-- and both already spell the test `upper(g.type) IN ('NATIONAL','FEDERAL')` -- they were
-- written around this duplicate. The browse query's `district_type` CASE lists neither
-- value, so both fall to its ELSE branch and the real answer comes from
-- `d.district_type`, which is 'NATIONAL_JUDICIAL' on all nine seats either way.
--
-- 'NATIONAL' survives because it is the row with 615 of the 624 offices, so merging into
-- it touches one chamber row instead of twenty-eight. Its `state` stays '' rather than
-- becoming 'US': no read filters this table by state, and a federal government is not in
-- a state. Flagged rather than changed.
--
-- Idempotent: the repoint is a guarded UPDATE and the DELETE is guarded on the row having
-- no remaining referents, so a second run is a no-op and the gate still passes.

BEGIN;

-- 1. Repoint the Supreme Court chamber onto the surviving row.
UPDATE essentials.chambers ch
   SET government_id = '0a6b51aa-00bb-4c15-b0f9-7f9da9150f47'
 WHERE ch.government_id = 'fd292119-3e3a-4bda-8853-ce1ee4807865'
   AND EXISTS (SELECT 1 FROM essentials.governments g
                WHERE g.id = '0a6b51aa-00bb-4c15-b0f9-7f9da9150f47');

-- 2. Delete the now-unreferenced duplicate. Both referencing columns are checked, the
--    unenforced one first -- that is the one that would fail silently.
DELETE FROM essentials.governments g
 WHERE g.id = 'fd292119-3e3a-4bda-8853-ce1ee4807865'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers   c WHERE c.government_id = g.id)
   AND NOT EXISTS (SELECT 1 FROM essentials.districts  d WHERE d.government_id = g.id);

-- 3. Post-verify.
DO $$
DECLARE
  v_fed_rows     int;
  v_orphan_ch    int;
  v_scotus_ch    int;
  v_justices     int;
  v_chambers     int;
  v_offices      int;
BEGIN
  SELECT count(*) INTO v_fed_rows
    FROM essentials.governments
   WHERE name = 'United States Federal Government';

  -- The failure this migration exists to prevent: a chamber whose government is gone.
  SELECT count(*) INTO v_orphan_ch
    FROM essentials.chambers c
   WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.id = c.government_id);

  SELECT count(*) INTO v_scotus_ch
    FROM essentials.chambers c
   WHERE c.government_id = '0a6b51aa-00bb-4c15-b0f9-7f9da9150f47'
     AND c.name = 'U.S. Supreme Court';

  SELECT count(*) INTO v_justices
    FROM essentials.chambers c
    JOIN essentials.offices o  ON o.chamber_id = c.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = '0a6b51aa-00bb-4c15-b0f9-7f9da9150f47'
     AND c.name = 'U.S. Supreme Court'
     AND och.politician_id IS NOT NULL;

  SELECT count(*) INTO v_chambers
    FROM essentials.chambers c
   WHERE c.government_id = '0a6b51aa-00bb-4c15-b0f9-7f9da9150f47';

  SELECT count(*) INTO v_offices
    FROM essentials.chambers c
    JOIN essentials.offices o ON o.chamber_id = c.id
   WHERE c.government_id = '0a6b51aa-00bb-4c15-b0f9-7f9da9150f47';

  IF v_fed_rows <> 1 THEN
    RAISE EXCEPTION 'CC_0288: expected exactly 1 federal government row, found %', v_fed_rows;
  END IF;
  IF v_orphan_ch > 0 THEN
    RAISE EXCEPTION 'CC_0288: % chamber(s) point at a government that does not exist', v_orphan_ch;
  END IF;
  IF v_scotus_ch <> 1 THEN
    RAISE EXCEPTION 'CC_0288: expected 1 U.S. Supreme Court chamber on the surviving row, found %', v_scotus_ch;
  END IF;
  IF v_justices <> 9 THEN
    RAISE EXCEPTION 'CC_0288: expected 9 seated justices after the repoint, found %', v_justices;
  END IF;
  IF v_chambers <> 29 THEN
    RAISE EXCEPTION 'CC_0288: expected 29 chambers on the merged row (28 + the Supreme Court), found %', v_chambers;
  END IF;
  IF v_offices <> 624 THEN
    RAISE EXCEPTION 'CC_0288: expected 624 offices on the merged row (615 + 9), found %', v_offices;
  END IF;

  RAISE NOTICE 'CC_0288: one federal government row, % chambers, % offices, % justices seated, 0 orphaned chambers',
    v_chambers, v_offices, v_justices;
END $$;

COMMIT;
