/**
 * donorCoverage.ts — "does this politician have any recorded contribution", as ONE definition.
 *
 * WHY THIS IS A CORRELATED EXISTS AND MUST STAY ONE
 *
 * Both map surfaces (coverageMapService.statsByJurisdiction, electionsMapService.racesForStateDate)
 * previously answered this with an UNCORRELATED derived table:
 *
 *     LEFT JOIN (SELECT DISTINCT ps.essentials_politician_id AS politician_id
 *                  FROM transparent_motivations.politician_sources ps
 *                  JOIN transparent_motivations.contributions c ON c.politician_source_id = ps.id
 *               ) don ON don.politician_id = p.id
 *
 * Nothing in that subquery references the outer query, so Postgres builds the whole DISTINCT set
 * before it can join — and `transparent_motivations.contributions` is ~27,000,000 rows / 30 GB.
 * The scan therefore ran once PER STATE on every cold-cache dashboard load. Measured on Indiana
 * alone: the full statsByJurisdiction query took 123,300 ms, and /api/admin/coverage/map?level=state
 * returned HTTP 500 after 30 s on a statement timeout. Isolating the aggregates showed this join was
 * the entire cost — the photo and stance FILTERs were 50-66 ms.
 *
 * As a correlated EXISTS the same question probes only the politicians actually in scope, using
 * indexes that already existed (politician_sources.essentials_politician_id and
 * contributions.politician_source_id). Same Indiana query: 196 ms. No schema change was needed;
 * this was never a missing index, it was the query shape.
 *
 * 🔴 DO NOT "simplify" this back into a JOIN over a DISTINCT set, and do not hoist it into a CTE —
 * a CTE is an optimisation fence, which reintroduces the same full scan.
 *
 * 🔴 DELIBERATELY NO `research_status` FILTER. The per-politician queries in campaignFinanceService
 * all add `AND ps.research_status = 'confirmed'`, but the coverage subquery never did, and this is a
 * performance fix, not a semantics change. Verified byte-identical per-jurisdiction output against
 * the old shape on dc / me / in before adoption. If the confirmed-only rule is wanted here, that is
 * a separate, deliberate decision about what the dashboard means.
 *
 * `p` must be the alias bound to essentials.politicians.
 */
export const HAS_ANY_CONTRIBUTION_SQL = `EXISTS (
    SELECT 1
      FROM transparent_motivations.politician_sources ps
     WHERE ps.essentials_politician_id = p.id
       AND EXISTS (SELECT 1
                     FROM transparent_motivations.contributions c
                    WHERE c.politician_source_id = ps.id)
  )`;
