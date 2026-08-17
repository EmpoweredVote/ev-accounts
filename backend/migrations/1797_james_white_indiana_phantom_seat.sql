-- Migration 1797: James White (Indiana) never held a seat — remove the phantom
--                 "State Representative" term that presents a defeated 2022 candidate
--                 as a sitting Indiana legislator.
--
-- ============================================================================
-- HOW THIS WAS FOUND
-- ============================================================================
-- Verifying the "James White" name-collision group (one of the 12 blocked by
-- dedup-essentials-politicians.ts). The identity question came back CLEAN — two men:
--
--   cfa073a3-70af-4552-ae30-7c3236137cf0  Representative, State of MAINE. Republican.
--       20 stance sources, all legislature.maine.gov roll calls and LawMakerWeb summaries
--       plus ballotpedia.org/James_White_(Maine) and a Maine Right to Life roll call PDF.
--   ae4d08d2-71c8-4861-b418-8c981d78d13d  "State Representative", INDIANA.  <-- this row
--       0 stances, no photo. One finance source: source_system 'indiana', external_id
--       7737, committee "People For White", note "Auto-discovered from Indiana 2022
--       contribution data. Office type unknown — needs manual assignment."
--
-- Indiana Democrat vs Maine Republican, and the Ballotpedia URLs disambiguate by state in
-- the path — James_White_(Maine) vs James_White_(Indiana). Different people. No merge is
-- warranted and none is performed here.
--
-- ============================================================================
-- THE DEFECT
-- ============================================================================
-- 🔴 THE INDIANA JAMES WHITE NEVER HELD THE SEAT THIS CORPUS GIVES HIM.
--
-- Ballotpedia, James White (Indiana): "James White (Democratic Party) (also known as Jim)
-- ran for election to the Indiana House of Representatives to represent District 17. He
-- LOST in the general election on November 8, 2022." Born Coffeyville KS; BA Kansas 1993,
-- graduate degree Indiana University 1997, PhD Ball State 2014; education administrator.
-- The page is stamped "current at the end of the individual's last campaign" — 2022.
--
-- This row nonetheless carries is_incumbent = true and an OPEN-ENDED office_term
-- (term_start NULL, term_end NULL) on office 46d29713, titled "State Representative", IN.
-- Occupancy is `term_end IS NULL AND is_incumbent`, so the corpus asserts he is currently
-- serving in the Indiana House. He is not, and never has.
--
-- The finance source's own note records how this happened: the row was auto-discovered
-- from 2022 contribution data with "Office type unknown — needs manual assignment", and
-- somewhere downstream a State Representative seat was assigned to a losing candidate.
-- This is the [[socrata_surname_substring_mislinks]] failure shape in a different guise:
-- money data manufactured an officeholder.
--
-- ⚠ The office is chamber-less and government-less, which LOOKS diagnostic and is NOT:
-- 77,845 offices in this corpus have a NULL chamber_id. Orphan-ness is normal here. The
-- defect is that a man who lost an election holds a term, not that the office is orphaned.
-- Recording this so the next reader does not mistake orphan offices for a detector.
--
-- ============================================================================
-- WHAT IS AND IS NOT DONE
-- ============================================================================
-- The term is DELETED, not closed. Closing it with a term_end would assert that he served
-- and then stopped; he never served at all, and a closed term is a claim about history.
-- Office 46d29713 has exactly one term (this one) and zero races attached, so removing it
-- strands nothing.
--
-- is_incumbent is set false. He is not an incumbent by any reading.
--
-- ⚠ is_active is DELIBERATELY LEFT ALONE. He is a real person and a real 2022 candidate
-- with a real campaign committee; he is simply not an officeholder. `p.is_active = true`
-- gates the politician listing, and whether defeated candidates should remain listed is a
-- corpus-wide policy question, not something to settle silently inside a one-person fix.
-- The distinction from migration 1796 is deliberate: Scott Smith was retired because he is
-- DECEASED, which is a fact about the person, not a policy about candidacies.
--
-- The person row and its finance source are retained. The committee link "People For
-- White" is genuinely his and stays confirmed.
--
-- No answers are deleted or rewritten by this migration, so no @context-decision
-- declaration is required.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Remove the phantom seat. DELETE rather than close: he lost the 2022 general and
--    never served, so any term at all — even an ended one — is a false claim.
-- ---------------------------------------------------------------------------
DELETE FROM essentials.office_terms
WHERE politician_id = 'ae4d08d2-71c8-4861-b418-8c981d78d13d'
  AND office_id     = '46d29713-0136-43d2-b677-91a11c0996c9';

-- ---------------------------------------------------------------------------
-- 2. Clear the incumbency flag and record why.
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians
SET is_incumbent = false,
    notes = ARRAY['NOT AN OFFICEHOLDER. James White (Democratic Party, also known as Jim) '
      || 'ran for the Indiana House of Representatives in District 17 and LOST the general '
      || 'election on 2022-11-08 (Ballotpedia, James_White_(Indiana)). This row was '
      || 'auto-discovered from Indiana 2022 contribution data — committee "People For '
      || 'White", source_system indiana / 7737, whose own note reads "Office type unknown '
      || '— needs manual assignment" — and was subsequently given an open-ended '
      || '"State Representative" term on office 46d29713, making the corpus assert he was '
      || 'currently serving. Migration 1797 deleted that phantom term and cleared '
      || 'is_incumbent. is_active left unchanged: he is a genuine past candidate, and '
      || 'whether defeated candidates stay listed is a corpus-wide policy question. NOT a '
      || 'duplicate: the other "James White" row cfa073a3-70af-4552-ae30-7c3236137cf0 is a '
      || 'different man, a REPUBLICAN member of the MAINE House with 20 roll-call-sourced '
      || 'stance citations.']
WHERE id = 'ae4d08d2-71c8-4861-b418-8c981d78d13d';

COMMIT;
