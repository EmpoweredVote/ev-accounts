-- Migration 1665: complete the 1664 sweep — the two relink rows whose politician no longer exists
--
-- Migration 1664 classified its worklist with
--     JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
-- and transparent_motivations.politician_sources has NO foreign key to
-- essentials.politicians. Two of the 128 rows point at politician ids that have since been
-- deleted, so the join silently dropped them and 1664 swept 126, not 128.
--
-- 🔑 An inner join used to build a cleanup worklist will silently shrink it wherever the
-- reference is dangling. Count the worklist against the unjoined population before trusting it.
--
--   25074afc-3c84-418b-bdc5-d859e9ae16d6  -> politician 6302513b (gone)
--       "Mazariegos for City Council 2026"      765 contributions, $141,648.79
--   74665e25-d936-4fbb-bfd1-f137e51ad058  -> politician 7f74014f (gone)
--       "Lewis for City Council District 9 2013"  0 contributions
--
-- Both were research_status='confirmed'. Neither can be a correct link to anybody — the
-- person they name does not exist in the corpus — so their ingested contributions are
-- attributed to nobody and are purged on the same terms as buckets A/B/C in 1664.
--
-- The source rows are KEPT and marked not_applicable rather than deleted, matching how
-- 1664 retired its wrong links: the row is the only record that the link was ever made.
--
-- ⚠ NOT ADDRESSED HERE — a wider defect this exposed. Orphaned politician_sources rows
-- (essentials_politician_id referencing a deleted politician) exist across four source
-- systems, carrying roughly 98,000 contributions in total:
--       fec_senate   11 rows   95,061 contributions
--       fec_house     2 rows    1,558
--       la_socrata    5 rows    1,364  (2 of them handled here)
--       cal_access   31 rows        6
-- Not voter-visible, since there is no politician to display them against, but it is dead
-- weight and the missing FK means nothing prevents more of it. Left for a scoped pass.

-- ⚠ The two source ids are written as LITERALS, not collected into a temp table.
-- The first attempt used `DELETE ... USING <temp table>` and hit a statement timeout: a
-- freshly created temp table carries no statistics, so the planner ignored
-- idx_transparent_motivations_contributions_politician_source_id and sequentially scanned
-- a very large contributions table. Literal ids let the index drive the delete. (The
-- aborted attempt rolled back cleanly — verified 765 contributions and status='confirmed'
-- still in place before re-running.)

BEGIN;

DELETE FROM transparent_motivations.contribution_summary_agg
WHERE politician_source_id IN ('25074afc-3c84-418b-bdc5-d859e9ae16d6',
                               '74665e25-d936-4fbb-bfd1-f137e51ad058');

DELETE FROM transparent_motivations.contributions
WHERE politician_source_id IN ('25074afc-3c84-418b-bdc5-d859e9ae16d6',
                               '74665e25-d936-4fbb-bfd1-f137e51ad058');

DELETE FROM transparent_motivations.ingestion_runs
WHERE politician_source_id IN ('25074afc-3c84-418b-bdc5-d859e9ae16d6',
                               '74665e25-d936-4fbb-bfd1-f137e51ad058');

UPDATE transparent_motivations.politician_sources
SET research_status = 'not_applicable',
    notes = coalesce(notes,'') || ' | sweep 1665: ORPHAN — essentials_politician_id'
            || ' references a politician that no longer exists, so this link cannot be'
            || ' correct for anyone. Contributions, aggregate and ingestion history purged.'
            || ' Missed by 1664 because its classification join dropped dangling references.',
    updated_at = now()
WHERE id IN ('25074afc-3c84-418b-bdc5-d859e9ae16d6',
             '74665e25-d936-4fbb-bfd1-f137e51ad058')
  AND research_status <> 'not_applicable';

COMMIT;
