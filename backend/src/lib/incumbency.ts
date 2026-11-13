/**
 * incumbency.ts — the single definition of "this person holds an office today".
 *
 * WHY THIS IS NOT `politicians.is_incumbent`
 *
 * That column was a CACHED COPY of what `essentials.office_terms` already says, and nothing
 * recomputed it when the calendar moved. `office_terms` is self-executing: a future-dated term
 * starts resolving as current on its own date, with no trigger and no deploy. The cached flag did
 * not follow. So every seeded handover broke on its own date — the departing holder stayed an
 * "incumbent" with no seat, and the arriving one was HIDDEN FROM ADDRESS SEARCH by the four
 * `is_incumbent = true` filters that used to sit on every reps query. Reno, 2026-11-13: a new
 * mayor, city attorney and Ward 2 council member, all invisible until someone ran the
 * reconciler by hand, and master CI red on whoever pushed next.
 *
 * Reads now derive incumbency from the dates, so a handover needs nothing on the day. The column
 * still exists and is still written (staging, admin), but NO READ PATH may use it. Measured
 * 2026-11-13 before switching: the derived value agreed with the column for every ACTIVE
 * politician (0 of ~14,400 differ); the only disagreements were 110 INACTIVE people the column
 * still called incumbents — former officeholders the dates correctly say are not.
 *
 * WHAT COUNTS AS HOLDING AN OFFICE
 *
 * A current tenure (`essentials.current_office_holders`: term started, not yet ended) on any
 * office whose title is not a 'Candidate for …' placeholder. Those placeholder offices
 * (migration 196) exist for compass/stance reachability only; counting them would publish 22
 * Senate CANDIDATES as sitting senators (CC_0342).
 *
 * ⚠ NOT THE ELECTIONS FLAG. `race_candidates.is_incumbent` is a different fact — "held THIS
 * race's seat on THIS race's election day" — and is untouched by this module.
 *
 * ⚠ PERFORMANCE. Correlated EXISTS against `current_office_holders` (the base view over
 * `office_terms`, served by `office_terms_politician_idx`): ~0.1 ms for a handful of people,
 * ~110 ms across every active politician. Do NOT write it against `office_current_holder`
 * (singular): that view is rooted on `offices` with a LEFT JOIN, the predicate cannot be pushed
 * into it, and the same count ran past three minutes.
 */

/**
 * SQL boolean: does the politician row aliased `alias` hold a real office today?
 * NULL-safe in the useful direction: on a LEFT-JOINed vacant seat (`alias.id` NULL) it is false.
 */
export function isIncumbentSql(alias = 'p'): string {
  return `EXISTS (
      SELECT 1
        FROM essentials.current_office_holders coh_inc
        JOIN essentials.offices o_inc ON o_inc.id = coh_inc.office_id
       WHERE coh_inc.politician_id = ${alias}.id
         AND COALESCE(o_inc.title, '') NOT ILIKE 'Candidate for%'
    )`;
}

/** Ready-made SELECT-list item for the usual `p` alias. */
export const IS_INCUMBENT_SELECT_SQL = `${isIncumbentSql('p')} AS is_incumbent`;
