-- 1863_ballot_truth_mayor_designation_titles.sql
-- Sahuarita + South Tucson (AZ): retitle council-appointed mayor/vice-mayor/acting-mayor offices
-- to the `Council Member (Designation)` form. 5 office rows, 2 chambers. No rows added or removed.
--
-- THE RULE THIS APPLIES: an office `title` records the seat AS THE BALLOT ELECTS IT. A rotating
-- designation is appended in parentheses; it never replaces the seat identity.
--
-- THE DISCRIMINATOR IS CHECKABLE, NOT A JUDGEMENT CALL: does a `Mayor - <place>` contest appear in
-- the county canvass? Verified against the Pima County 2026 Primary Election Official Canvass
-- (https://www.pima.gov/2865/Election-Results -> "2026 Primary Election - Canvass (PDF)"):
--   Marana       -> "Mayor - Town of Marana"        AND "Council Member - Town of Marana"
--   Oro Valley   -> "Mayor - Town of Oro Valley"    AND "Council Member - Town of Oro Valley"
--   Sahuarita    -> "Council Member - Town of Sahuarita"      ONLY  <-- no mayor on any ballot
--   South Tucson -> "Council Member - City of South Tucson"   ONLY  <-- no mayor on any ballot
-- So Marana/Oro Valley/Tucson keep their standalone `Mayor` rows (that IS how voters elect them) and
-- are deliberately NOT touched here. Sahuarita and South Tucson do not elect a mayor at all.
--
-- CORROBORATION for Sahuarita, Town of Sahuarita Rules of Procedure adopted 2024-12-09:
--   "The Town Council consists of a Mayor and six Council Members... The Council Members appoint the
--    Mayor every two years"; "Shortly after every Town General Election, the Council chooses a
--    Vice-Mayor". Selection is by roll call and needs >= 4 affirmative votes; if nobody reaches four
--    "the current Mayor will continue to serve". Both serve "at the pleasure of the Town Council".
-- South Tucson's own site is WAF-blocked (403 to both WebFetch and curl), so its designation
-- structure is established from the two facts we hold directly: the canvass carries no mayor contest,
-- and the DB holds 7 distinct people across the chamber's 7 seats. Seven seats, seven people, no
-- mayoral ballot line => Mayor / Vice Mayor / Acting Mayor are all designations on council seats.
--
-- WHY THIS MATTERS BEYOND TIDINESS: Sahuarita's next designation happens at the 2026-11-09 swearing-in
-- (Kara Egbert did not seek re-election and leaves the body; her seat went to Chelsea Hundal). Under
-- the old shape that title hand-off would have been written as a change of OFFICE, which reads as an
-- election result. Under this shape it is a change of DESIGNATION on a council seat, recorded with
-- office_terms.how_started = 'appointed' -- never 'elected'.
--
-- Seat counts are unchanged: the rows already partition the seats (7 = 7 in both chambers), so this
-- is a pure relabel. role_canonical is deliberately left alone -- it is populated on only 230 of
-- 84,464 offices and is inconsistently cased ('MAYOR' vs 'governor'), so it is not load-bearing yet.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.
-- "Applied" can only mean its data effects are live.

BEGIN;

-- ---------------------------------------------------------------------------
-- Pre-flight: the 5 targets must exist exactly as expected, in exactly 2 chambers.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE m1863_target ON COMMIT DROP AS
SELECT o.id, o.title, c.name_formal AS chamber
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
 WHERE c.name_formal IN ('Sahuarita Town Council', 'South Tucson City Council')
   AND o.title IN ('Mayor', 'Vice Mayor', 'Acting Mayor');

DO $$
DECLARE n int; sah int; sot int;
BEGIN
  SELECT count(*) INTO n FROM m1863_target;
  IF n <> 5 THEN
    RAISE EXCEPTION 'migration 1863: expected exactly 5 designation offices to retitle, found % -- someone has already moved them, or a chamber was reshaped', n;
  END IF;

  -- the relabel must not change how many seats each body has
  SELECT count(*) INTO sah FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal = 'Sahuarita Town Council';
  SELECT count(*) INTO sot FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal = 'South Tucson City Council';
  IF sah <> 7 OR sot <> 7 THEN
    RAISE EXCEPTION 'migration 1863: expected 7 seats in each chamber, found Sahuarita=% South Tucson=%', sah, sot;
  END IF;

  -- Guard the discriminator itself: if a mayor CONTEST ever appears for these towns, the rule no
  -- longer applies to them and this migration must be re-argued rather than re-run.
  -- NB test races.position_name, which names the contest as the county runs it -- NOT offices.title.
  -- A first cut of this guard tested the office title and fired on South Tucson, whose council race
  -- shell (position_name 'South Tucson City Council', seats 3, 0 candidates) happens to hang off the
  -- `Acting Mayor` office row. That is a wrong ATTACHMENT, not a mayoral contest, and it is exactly
  -- the confusion this migration removes. Left in place deliberately -- see the note at the bottom.
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal IN ('Sahuarita Town Council', 'South Tucson City Council')
     AND r.position_name ILIKE '%mayor%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1863: found % mayoral CONTEST(s) for Sahuarita/South Tucson -- the no-mayor-contest premise is broken', n;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- Relabel. Sahuarita + South Tucson only; Marana / Oro Valley / Tucson untouched.
-- ---------------------------------------------------------------------------
UPDATE essentials.offices o
   SET title = 'Council Member (' || o.title || ')'
  FROM m1863_target t
 WHERE o.id = t.id;

-- ---------------------------------------------------------------------------
-- Post-flight: exactly the 5 intended rows now carry the compound form, no bare
-- designation titles remain in these two chambers, and nothing else moved.
-- ---------------------------------------------------------------------------
DO $$
DECLARE compound int; bare int; elected_mayors int;
BEGIN
  SELECT count(*) INTO compound
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal IN ('Sahuarita Town Council', 'South Tucson City Council')
     AND o.title IN ('Council Member (Mayor)', 'Council Member (Vice Mayor)', 'Council Member (Acting Mayor)');
  IF compound <> 5 THEN
    RAISE EXCEPTION 'migration 1863: expected 5 compound-title offices after update, found %', compound;
  END IF;

  SELECT count(*) INTO bare
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal IN ('Sahuarita Town Council', 'South Tucson City Council')
     AND o.title IN ('Mayor', 'Vice Mayor', 'Acting Mayor');
  IF bare <> 0 THEN
    RAISE EXCEPTION 'migration 1863: % bare designation title(s) still present after update', bare;
  END IF;

  -- the directly-elected mayors must be exactly as they were
  SELECT count(*) INTO elected_mayors
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal IN ('Marana Town Council', 'Oro Valley Town Council', 'Tucson City Council')
     AND o.title = 'Mayor';
  IF elected_mayors <> 3 THEN
    RAISE EXCEPTION 'migration 1863: expected the 3 directly-elected AZ mayor offices to be untouched, found %', elected_mayors;
  END IF;
END $$;

COMMIT;

-- ---------------------------------------------------------------------------
-- OPEN, NOT FIXED HERE: South Tucson's Nov-2026 council race shell
-- (position_name 'South Tucson City Council', seats 3, 0 candidates) is attached to the office row
-- retitled above to `Council Member (Acting Mayor)`. Sahuarita's equivalent shell hangs off a plain
-- `Council Member` seat. For an at-large multi-seat contest the anchor office is somewhat arbitrary,
-- but the two towns should agree. Re-pointing it touches election data and has its own playbook, so
-- it is recorded rather than done. See project_phase_archive_owed.
