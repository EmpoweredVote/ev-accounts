/**
 * office-tiers.mjs — how an officeholder maps to a COMPASS tier, in one place.
 *
 * WHY THIS EXISTS. Two vocabularies describe the same people and they are not
 * interchangeable:
 *
 *   federalCoverage.ts `TIER_CASE_SQL` → senate | house | governor | statewide |
 *     stateleg | candidate.  Answers "how well is this state's government
 *     covered", so it splits the federal tier into chambers and keeps
 *     challengers separate from seatholders.
 *
 *   compass_topic_roles.role_scope    → federal | state | local | judicial.
 *     Answers "does this topic display for this person", which is the only
 *     question a research batch needs.
 *
 * Nothing translated between them, so every caller that needed the second one
 * wrote its own CASE. That is how the same rules get re-derived slightly
 * differently each time, and two of the re-derivations are worth naming:
 *
 *   🔴 THE SENATOR TITLE SPLIT. Sitting U.S. senators carry TWO title formats —
 *      `Senator` (86 rows) and `U.S. Senate - <State>` (14). A filter that
 *      checks only the first finds 86 of 100 and says nothing about the other
 *      14. federalCoverage.ts has always handled both; ad-hoc cohort queries
 *      written against `title = 'Senator'` do not, and they look right.
 *
 *   ⚠ DC's TWO SHADOW SENATORS hold no seat in Congress. They sit at a /cd:
 *      district and their title contains "Senator", so a naive net catches them
 *      twice over. They are `state`, not `federal`.
 *
 * 🔑 THE RULES BELOW ARE federalCoverage.ts's, MAPPED — not a second opinion.
 * If TIER_CASE_SQL changes, change this with it. Where this one goes FURTHER,
 * it is because the compass asks about people that module's question does not:
 *
 *   · PRESIDENT AND VICE PRESIDENT sit at the bare country division
 *     (`ocd-division/country:us`). TIER_CASE_SQL returns NULL for them because
 *     a per-state coverage rollup has no row for them. They are `federal`.
 *   · DISTRICT AND TERRITORY divisions. TIER_CASE_SQL matches `state:[a-z]{2}`
 *     only; DC and the five territories also have bare-division officeholders
 *     (an AG, a governor) who are `state` for compass purposes.
 *   · JUDICIAL. That module has no judicial branch at all; `districts.is_judicial`
 *     decides it here, and it wins over everything else.
 *
 * Requires the aliases o = essentials.offices, d = essentials.districts.
 */

/** Bare state / district / territory division — a statewide seat of any kind. */
const BARE_STATE = "d.ocd_id ~ '^ocd-division/country:us/(state|district|territory):[a-z]{2}$'";

/**
 * A sitting U.S. senator, both title formats, challengers and shadows excluded.
 * Kept as its own export because it is the half that has actually been got
 * wrong, and a cohort query should be able to say what it means.
 */
export const SITTING_SENATOR_SQL =
  `(${BARE_STATE} AND (o.title = 'Senator' OR o.title ILIKE 'u.s. senate%'))`;

/**
 * Officeholder → compass role_scope. NULL when it cannot be established, which
 * is honest: about a quarter of the researched corpus has no district, and a
 * guess there would place people on topics that never display for them.
 *
 * Order matters, and mirrors TIER_CASE_SQL's reasoning:
 *   1. judicial wins outright — a judicial profile takes only judicial topics
 *   2. candidate placeholder offices resolve by the seat they contest
 *   3. shadow senators are caught before the generic /cd: federal branch
 */
export const COMPASS_TIER_SQL = `CASE
    WHEN d.is_judicial THEN 'judicial'
    WHEN o.title ILIKE '%shadow senator%' THEN 'state'
    WHEN o.title ILIKE 'candidate for%'
         AND (o.title ILIKE '%u.s. senate%' OR o.title ILIKE '%u.s. house%') THEN 'federal'
    WHEN d.ocd_id = 'ocd-division/country:us' THEN 'federal'
    WHEN d.ocd_id LIKE '%/cd:%' THEN 'federal'
    WHEN ${SITTING_SENATOR_SQL} THEN 'federal'
    WHEN ${BARE_STATE} THEN 'state'
    WHEN d.ocd_id LIKE '%/sldu:%' OR d.ocd_id LIKE '%/sldl:%' THEN 'state'
    WHEN d.ocd_id LIKE '%/county:%' OR d.ocd_id LIKE '%/place:%'
         OR d.ocd_id LIKE '%school%' THEN 'local'
  END`;

/**
 * The broad net: anything that could plausibly be a sitting senator.
 *
 * This is NOT used to select the cohort. It exists so `federal-cohort.mjs` can
 * subtract the canonical predicate from it and refuse silently on the
 * difference — the check that would have caught the `U.S. Senate - <State>`
 * format the day it appeared, instead of the next time someone counted.
 */
export const SENATOR_BROAD_NET_SQL = `(${BARE_STATE}
    AND o.title ILIKE '%senat%'
    AND o.title NOT ILIKE 'candidate for%'
    AND o.title NOT ILIKE '%shadow%')`;

/** The compass tiers, in the order compass_topic_roles uses them. */
export const COMPASS_TIERS = ['federal', 'state', 'local', 'judicial'];
