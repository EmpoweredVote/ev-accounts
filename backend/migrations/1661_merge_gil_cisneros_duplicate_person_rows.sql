-- Migration 1661: merge the three Gil Cisneros person rows into the seated record
--
-- ============================================================================
-- THE THREE ROWS
-- ============================================================================
--   be2943b7-f634-42f4-8ab8-15db8138169f  CANONICAL  source='scraped'
--       Holds CA-31 (office e1e70721, term_start 2025-01-03), bioguide C001123,
--       party D, photo, finance_summary, race_candidate row. 13 compass stances.
--   d26d3a2f-c29d-4500-861d-afe19b283650  DUPLICATE  source='federal_2026_bulk_seed'
--       19 compass stances. Its only office_term sat on a phantom districtless
--       office and was removed by migration 1655, so it is now seatless.
--   65f08851-9336-4a38-a239-3f5bf3333095  DUPLICATE  source=NULL, already inactive
--       One name alias, one politician_id_bridge row.
--
-- All three were inserted in the same batch at the same microsecond. 65f08851's own
-- notes record the history: it arrived from inform-migration carrying the 19 stances
-- and no office, d26d3a2f arrived from federal_2026_bulk_seed with an office and no
-- stances, and migration 1572 moved the stances onto "the seated record" — which was
-- true then, but 1655 unseated d26d3a2f. The 19 stances have been stranded on a
-- seatless row ever since; the voter-visible profile is be2943b7.
--
-- ============================================================================
-- THE STANCE CONFLICT AND HOW IT WAS DECIDED (operator call, 2026-08-09)
-- ============================================================================
-- The two records disagreed about the same man. Of 12 shared topics, 6 carried
-- CONFLICTING values. Evidence quality is lopsided and systematic:
--
--                              CANON (13)   DUP (19)
--   cites ontheissues.org          13           0
--   ontheissues.org ONLY           12           0
--   cites primary .gov              0           9
--   written for current 1-5 scale   0           4
--   avg sources per stance       1.08        1.37
--
-- The canonical set is a single-aggregator scrape off one 2018 page; the duplicate's
-- is primary-sourced (cisneros.house.gov, votesmart, Brennan Center) and several
-- reasonings are written explicitly against the current scale. Operator chose: the
-- duplicate's evidence wins on all 12 shared topics. Six displayed values change —
-- Healthcare Access, Climate Change, Fossil Fuel Policy and Medicare/Medicaid 3.0->2.0,
-- Taxation and Public Spending and Voting Rights 1.0->2.0 — and the six that already
-- agreed keep their value but gain the better sources.
--
-- ⚠ Result is 20 stances, ONE of which is still ontheissues-only: "School Vouchers &
-- Public Education Funding" (1.0), the single canon-only topic the duplicate never
-- covered. It survives because dropping it would delete a stance rather than improve
-- it. NOT 0 ontheissues-only, as an earlier summary of this plan claimed.
--
-- ⚠ SCOPE NOTE: ontheissues-only sourcing is 1,434 rows across 285 politicians
-- corpus-wide. This migration does NOT set policy for that class — it resolves one
-- person where a better-sourced alternative already existed on a duplicate record.
-- The wider class belongs to the stance evidence-integrity audit.
--
-- ============================================================================
-- ALSO REPAIRED HERE
-- ============================================================================
-- * be2943b7 carries a WRONG-PERSON crosswalk row: la_socrata 1413741 "Eduardo
--   Cisneros for LAUSD 2019" — a different human, attached by relink-socrata-skipped.ts.
--   Marked not_applicable rather than deleted, so the bad link is excluded from
--   confirmed-only lookups but the audit trail survives.
-- * d26d3a2f holds fec_house H8CA39174 — Gil Cisneros's genuine PRIOR CA-39 committee
--   (he served CA-39 2019-2021 before winning CA-31 in 2024). Moved to the canonical
--   record and marked not_applicable/superseded, matching how Schiff's and Banks's
--   prior House ids are modelled.
-- * The orphan alias reads alias='Gil Cisneros' on a row named "Gilbert Cisneros".
--   After the merge the canonical record IS "Gil Cisneros", so that alias would be a
--   redundant self-reference. Repointed and flipped to 'Gilbert Cisneros' — the same
--   fact (these two name forms are one person) recorded in the correct direction.
--
-- Duplicate person rows are RETIRED, NOT DELETED — 65f08851's note is the only record
-- of how this tangle arose, and deleting rows would destroy that provenance.
--
-- inform.politician_context_evidence, degrees, experiences, identifiers, addresses,
-- committees, quest_verified_facts, empowered_profiles and la_council_votes were all
-- verified to hold ZERO rows for all three ids.
--
-- ⚠ APPLY AS `postgres`, NOT via the .env DATABASE_URL. Step 6 writes
-- public.politician_id_bridge, and the `ev_api` role that DATABASE_URL uses gets
-- "permission denied for table politician_id_bridge" on it. Applying with psql aborts the
-- whole transaction there and rolls back cleanly (verified: nothing was left half-applied).
-- Applied 2026-08-09 as postgres. Any migration touching public.* needs the same treatment.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Drop the losing (ontheissues-only) side of the 12 shared topics from the
--    canonical record, so the duplicate's rows can move without colliding with
--    PRIMARY KEY (politician_id, topic_id).
-- ---------------------------------------------------------------------------
DELETE FROM inform.politician_context
WHERE politician_id = 'be2943b7-f634-42f4-8ab8-15db8138169f'
  AND topic_id IN (SELECT topic_id FROM inform.politician_answers
                   WHERE politician_id = 'd26d3a2f-c29d-4500-861d-afe19b283650');

DELETE FROM inform.politician_answers
WHERE politician_id = 'be2943b7-f634-42f4-8ab8-15db8138169f'
  AND topic_id IN (SELECT topic_id FROM inform.politician_answers
                   WHERE politician_id = 'd26d3a2f-c29d-4500-861d-afe19b283650');

-- ---------------------------------------------------------------------------
-- 2. Move the duplicate's 19 stances + reasoning onto the seated record.
-- ---------------------------------------------------------------------------
UPDATE inform.politician_answers
SET politician_id = 'be2943b7-f634-42f4-8ab8-15db8138169f'
WHERE politician_id = 'd26d3a2f-c29d-4500-861d-afe19b283650';

UPDATE inform.politician_context
SET politician_id = 'be2943b7-f634-42f4-8ab8-15db8138169f'
WHERE politician_id = 'd26d3a2f-c29d-4500-861d-afe19b283650';

-- ---------------------------------------------------------------------------
-- 3. Preserve the prior CA-39 committee on the canonical record, superseded.
-- ---------------------------------------------------------------------------
UPDATE transparent_motivations.politician_sources
SET essentials_politician_id = 'be2943b7-f634-42f4-8ab8-15db8138169f',
    research_status = 'not_applicable',
    notes = COALESCE(notes,'') || ' | merge 1661: prior CA-39 committee (2019-2021),'
            || ' superseded by canonical FEC source H4CA31170; moved from duplicate row'
            || ' d26d3a2f-c29d-4500-861d-afe19b283650',
    updated_at = now()
WHERE essentials_politician_id = 'd26d3a2f-c29d-4500-861d-afe19b283650'
  AND external_id = 'H8CA39174';

-- ---------------------------------------------------------------------------
-- 4. Disarm the wrong-person la_socrata link (Eduardo Cisneros, LAUSD).
-- ---------------------------------------------------------------------------
UPDATE transparent_motivations.politician_sources
SET research_status = 'not_applicable',
    notes = COALESCE(notes,'') || ' | merge 1661: WRONG PERSON — committee belongs to'
            || ' Eduardo Cisneros (LAUSD school board), not Rep. Gil Cisneros (CA-31).'
            || ' Attached by relink-socrata-skipped.ts. Retained for audit, excluded'
            || ' from confirmed-only lookups.',
    updated_at = now()
WHERE essentials_politician_id = 'be2943b7-f634-42f4-8ab8-15db8138169f'
  AND source_system = 'la_socrata'
  AND external_id = '1413741';

-- ---------------------------------------------------------------------------
-- 5. Repoint the name alias, recorded in the correct direction.
-- ---------------------------------------------------------------------------
UPDATE essentials.politician_name_aliases
SET politician_id = 'be2943b7-f634-42f4-8ab8-15db8138169f',
    alias = 'Gilbert Cisneros'
WHERE id = 'befdb9f3-0538-477c-bbe9-1df37a006154';

-- ---------------------------------------------------------------------------
-- 6. Repoint the inform id bridge so inform 65f08851 resolves to the seated row.
--    PK is (essentials_id, inform_id); the canonical row has no bridge entry.
-- ---------------------------------------------------------------------------
UPDATE public.politician_id_bridge
SET essentials_id = 'be2943b7-f634-42f4-8ab8-15db8138169f'
WHERE essentials_id = '65f08851-9336-4a38-a239-3f5bf3333095'
  AND inform_id = '65f08851-9336-4a38-a239-3f5bf3333095';

-- ---------------------------------------------------------------------------
-- 7. Retire the two duplicate person rows (kept, not deleted).
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians
SET is_active = false,
    is_incumbent = false,
    notes = ARRAY['DUPLICATE of politician be2943b7-f634-42f4-8ab8-15db8138169f (Gil '
      || 'Cisneros, U.S. Representative CA-31). Arrived from federal_2026_bulk_seed in the '
      || 'same batch. Migration 1572 moved 19 compass stances here because this row then '
      || 'held an office; that office was a phantom districtless seat removed by migration '
      || '1655, stranding the stances. Migration 1661 moved all 19 to the seated record and '
      || 'retired this row.']
WHERE id = 'd26d3a2f-c29d-4500-861d-afe19b283650';

-- 65f08851's existing note points at d26d3a2f, which is itself now retired. Repoint it
-- at the surviving record so the provenance trail does not dead-end.
UPDATE essentials.politicians
SET notes = ARRAY['DUPLICATE of politician be2943b7-f634-42f4-8ab8-15db8138169f (Gil '
      || 'Cisneros, U.S. Representative CA-31). Arrived from inform-migration in the same '
      || 'batch carrying 19 compass stances and no office. Migration 1572 moved those '
      || 'stances to d26d3a2f (then seated); migration 1661 moved them on to the truly '
      || 'seated record be2943b7 and retired both duplicates. Superseded note, was: '
      || 'DUPLICATE of politician d26d3a2f-c29d-4500-861d-afe19b283650.']
WHERE id = '65f08851-9336-4a38-a239-3f5bf3333095';

COMMIT;
