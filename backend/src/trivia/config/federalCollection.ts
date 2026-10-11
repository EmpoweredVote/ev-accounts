/**
 * The default collection a CTC game falls back to, in one place.
 *
 * THE SLUG HERE WAS WRONG FOR AS LONG AS IT HAS EXISTED. It read 'federal-civics', and no
 * collection has ever had that slug: the row is `{ id: 1, slug: 'federal', name: 'US Civics' }`
 * (verified against production 2026-10-11, and `SELECT count(*) WHERE slug='federal-civics'`
 * returns 0). The literal was copied into five places, so it cost two different things:
 *
 *   1. `getFederalCollectionId()` looked up a slug that cannot match, so EVERY default session
 *      ran a query guaranteed to miss, warned, and returned the hardcoded id below. The miss
 *      path does not populate the cache, so the failing query never stopped repeating.
 *   2. Bobit progress written on a degraded path was keyed under a slug naming no collection,
 *      and could never be read back -- the exact split `progressKey()` exists to prevent.
 *
 * It survived because the fallback id happens to be right: Federal is seeded first, so id 1
 * IS `federal`. The feature worked by luck of seed order, which is why nothing ever failed
 * loudly enough to look at.
 *
 * One constant, imported everywhere, so the next rename cannot half-land.
 */
export const FEDERAL_SLUG = 'federal';

/**
 * Where `getFederalCollectionId()` lands when the lookup by slug finds nothing.
 *
 * A floor, not a routing decision, and deliberately NOT cached by its caller: a transient
 * database error must not pin a long-lived process to this id for the rest of its life.
 */
export const FEDERAL_COLLECTION_ID_FALLBACK = 1;
