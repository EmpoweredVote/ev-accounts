-- Migration 1796: Scott Smith (Lawrence County, Indiana) died 2025-12-28 and is still
--                 seated in the corpus as a current at-large councilman.
--
-- ============================================================================
-- HOW THIS WAS FOUND
-- ============================================================================
-- Verifying the "Scott Smith" name-collision group (one of the 12 blocked by
-- dedup-essentials-politicians.ts). The identity question came back CLEAN — the two rows
-- are genuinely two different men:
--
--   bcd556db-a139-4b87-8887-a1bad73726ea  Council Member Place 2, City of Murphy, TEXAS.
--       2 stances sourced to murphymonitor.com and smithformurphy.com. Alive, seated.
--   f5cce37f-425b-4494-acad-38bdf6136ba6  Council - At Large, LAWRENCE COUNTY, INDIANA.
--       0 stances, 0 finance sources.  <-- this row
--
-- Two different states, two jurisdiction-matched evidence sets, and two visibly different
-- men in the stored headshots. No merge is warranted and none is performed here.
--
-- But "is this the right person?" is only half of the group review. The other half is
-- whether each record is internally SOUND, and this one is not.
--
-- ============================================================================
-- THE DEFECT
-- ============================================================================
-- Scott Smith of Lawrence County DIED ON 2025-12-28. WBIW, 2026-01-05: "Lawrence County
-- GOP calls caucus to fill council vacancy following death of Scott Smith" — the caucus
-- was held 2026-01-30 at the Lawrence County 4-H Fairgrounds to pick someone to serve the
-- remainder of his term. His obituary (Day & Carter Mortuary, Bedford IN) records the same
-- death date and describes him as the sitting County Council At-Large member, the seat his
-- father Louie Smith had also held.
--
-- The county's own roster at lawrencecounty.in.gov/183/County-Council now lists the three
-- at-large members as Rick Butterfield, Julie Hewetson and Dustin Gabhart. Scott Smith is
-- not on it.
--
-- This corpus still carries him as is_active = true, is_incumbent = true, with an
-- open-ended term (term_end NULL) on office 5dcf1678 — nearly eight months after his death.
-- Occupancy reads as `term_end IS NULL AND is_incumbent`, and `p.is_active = true` gates
-- the politician listing outright (backend/src/routes/essentials.ts), so a dead man is
-- being served to voters as their sitting councilman.
--
-- ============================================================================
-- WHAT IS AND IS NOT DONE
-- ============================================================================
-- The term is CLOSED at the date of death with how_ended = 'died'. Note this is the FIRST
-- 'died' row in the corpus — the value is permitted by the office_terms CHECK constraint
-- but had never been used, so nothing else models a death yet.
--
-- ⚠ DUSTIN GABHART IS DELIBERATELY NOT SEEDED, following the precedent set for Misty
-- Wamhoff in migration 1794: vacating the seat is the honest state, and a half-formed
-- person row is worse than an acknowledged absence. The seat is left VACANT.
--   Note also that the identification of Gabhart as the successor to THIS PARTICULAR
--   at-large seat is an INFERENCE, not a sourced fact: Lawrence County has three separate
--   at-large office rows, this corpus already holds Butterfield and Hewetson on the other
--   two, and Gabhart is the remaining name on the county roster. Nobody has published
--   which of the three seats the caucus filled. Not a problem for a vacancy; it would be
--   a problem for a seed, which is exactly why the seed is left owed rather than guessed.
--
-- The person row is set is_active = false. He is deceased; he should not appear in the
-- politician listing as a Lawrence County official. His row, term and provenance are
-- retained, never deleted.
--
-- ⚠ NOT REPAIRED HERE — the Murphy TX Scott Smith's race_candidates row for the
-- "Murphy TX City General 2025" election (2025-05-03) still carries result NULL and
-- candidate_status 'active' fifteen months on, even though his own stance sources cite
-- murphymonitor's final totals and he holds the Place 2 seat. That belongs to the
-- election-resolve queue, not to this fix.
--
-- No answers are deleted or rewritten by this migration, so no @context-decision
-- declaration is required.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Close the at-large term at the date of death. This is what vacates the seat:
--    occupancy is `term_end IS NULL AND is_incumbent`.
-- ---------------------------------------------------------------------------
UPDATE essentials.office_terms
SET term_end  = DATE '2025-12-28',
    how_ended = 'died',
    source    = COALESCE(source, '')
              || ' | migration 1796: Scott Smith died 2025-12-28. WBIW 2026-01-05, '
              || '"Lawrence County GOP calls caucus to fill council vacancy following '
              || 'death of Scott Smith" — caucus held 2026-01-30 to serve the remainder '
              || 'of the term. The county roster at lawrencecounty.in.gov/183/County-Council '
              || 'now lists at-large members Rick Butterfield, Julie Hewetson and Dustin '
              || 'Gabhart; Smith is absent. Seat left VACANT — no successor seeded, because '
              || 'which of the three at-large seats the caucus filled is not published.'
WHERE politician_id = 'f5cce37f-425b-4494-acad-38bdf6136ba6'
  AND office_id     = '5dcf1678-1996-448e-8933-39094ebe9326'
  AND term_end IS NULL;

-- ---------------------------------------------------------------------------
-- 2. Retire the person row. `p.is_active = true` gates the politician listing, so
--    this is what stops a deceased man being served as a sitting official.
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians
SET is_active    = false,
    is_incumbent = false,
    notes = ARRAY['DECEASED 2025-12-28. Scott Smith, Lawrence County (Indiana) Council '
      || 'At-Large. WBIW reported his death on 2026-01-05 and the Lawrence County GOP held '
      || 'a caucus on 2026-01-30 to fill the remainder of his term; the county roster now '
      || 'lists Butterfield, Hewetson and Gabhart in the three at-large seats. Migration '
      || '1796 closed his term (how_ended = died) and retired this row. The seat is left '
      || 'VACANT — a successor seed is owed. NOT a duplicate: the other "Scott Smith" row '
      || 'bcd556db-a139-4b87-8887-a1bad73726ea is a different man, Council Member Place 2 '
      || 'for the City of Murphy, TEXAS, confirmed by jurisdiction-matched sources and by '
      || 'two visibly different headshots.']
WHERE id = 'f5cce37f-425b-4494-acad-38bdf6136ba6';

COMMIT;
