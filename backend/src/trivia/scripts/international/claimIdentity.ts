/**
 * Cross-run claim identity: when are two claims the same *fact*?
 *
 * WHY THIS EXISTS
 * ---------------
 * Deduplication used to be string equality on model prose. `extractClaim`
 * asks Claude for a (subject, attribute, value) triple, `fingerprintClaim`
 * normalises it into `topicKey = "subject|attribute"`, and a topicKey +
 * valueKey match meant duplicate.
 *
 * A live acceptance test ran the pipeline twice, 90 seconds apart, on
 * identical feeds. The same story came back re-authored:
 *
 *   run 1  mokha port yemen|distance from bab al-mandab strait               = 75km
 *   run 2  mokha port yemen|distance from bab al-mandab strait after capture = 75
 *
 * Three independent drifts in one claim: a synonym in the subject
 * (capture/seizure), an appended qualifier in the attribute ("after
 * capture"), and the unit dropped from the value. Any one of them breaks
 * string equality, and a duplicate question shipped.
 *
 * The trigram backstop cannot rescue this either. Measured on the real
 * questions: a pair of *genuinely different* facts scored 0.5086 (they share
 * the boilerplate "7 October 2023 Hamas-led attacks on Israel" while asking
 * about deaths vs hostages) while the *true duplicate* scored 0.4468.
 * Lexical overlap tracks same-STORY, not same-FACT, so no threshold on it
 * separates the two.
 *
 * THE RULE
 * --------
 * From the measured data: the normalised value is the strong discriminator,
 * and named entities only need to scope it to the same story.
 *
 *   Mokha distance, two runs 90s apart   75   vs 75    duplicate
 *   King Harald's age, 11 days apart     89   vs 89    duplicate
 *   Oct 7 deaths vs hostages, one story  1200 vs 251   different facts
 *
 * So: a claim is a duplicate when its normalised value equals a recent
 * claim's value AND their entity sets overlap sufficiently.
 *
 * Deliberately NOT set equality on the entities. Cluster membership shifts as
 * a story develops — articles about a death one week, the funeral the next,
 * sharing {harald, norway} but differing on {oslo} — so identity has to
 * tolerate a moving set. Jaccard overlap with a floor does; equality does
 * not.
 *
 * Values do stay exact. `normalizeValue` in claimFingerprint.ts already
 * absorbs the drift that matters there (units, thousands separators,
 * approximation hedges: "75km" and "75" both become "75"), so a residual
 * difference in the value is a real difference in the fact.
 */

/**
 * The overlap a value match must clear to count as the same story.
 *
 * STARTING VALUE, NOT A MEASURED ONE. Chosen so that a pair of three-entity
 * sets sharing two entities (Jaccard 0.5) passes and a pair of four-entity
 * sets sharing two (0.333) does not — roughly "two of three shared entities
 * is the same story". There are no real cross-day entity measurements to tune
 * it against yet, which is why run-pipeline.ts logs the computed overlap on
 * every value match, pass and near-miss alike, under the `[DedupOverlap]`
 * tag. A week of real runs produces the distribution needed to set this
 * properly; until then, treat the number as a hypothesis.
 */
export const MIN_ENTITY_OVERLAP = 0.34;

/**
 * How many distinct entities a side needs before the entity rule is allowed
 * to decide anything.
 *
 * With one entity the Jaccard score is dominated by set size rather than by
 * agreement — {yemen} against {yemen, houthi, mokha} scores 0.333 and would
 * fail, while {yemen} against {yemen} scores 1.0 and would match any two
 * unrelated Yemen facts that happened to share a value. Below this floor the
 * caller falls back to the old prose rule instead; see `hasUsableEntities`.
 */
export const MIN_USABLE_ENTITIES = 2;

/**
 * Normalise one entity: fold accents, lowercase, strip possessives and
 * punctuation, collapse whitespace.
 *
 * DO NOT assume compromise's output is clean — measured, not assumed. Running
 * the extractor's own `extractEntities` over four paraphrases of the Mokha
 * story returned, verbatim:
 *
 *   "red sea coast."   "mandab strait."   "yemen's"   "bab al-mandab."
 *
 * Trailing sentence punctuation and a possessive apostrophe. `clusterArticles`
 * only lowercases and trims, so "red sea" and "red sea coast." are different
 * strings to a set, and every one of those is a shared entity silently scored
 * as unshared. Overlap is a ratio of set sizes, so that does not merely lose a
 * match — it biases every score downward.
 *
 * The rules deliberately mirror `baseNormalize` in claimFingerprint.ts, which
 * solved the same problem for subjects and values. They are duplicated rather
 * than shared because that function is private to a module this change is not
 * permitted to touch; if the two ever need to diverge, they can.
 *
 * Dots are deleted rather than spaced so abbreviations close up: "u.s."
 * becomes "us", not "u s". Hyphens survive, because "bab al-mandab" is one
 * entity.
 */
function normalizeEntity(raw: string): string {
  return raw
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    // possessive 's first, so "yemen's" collides with "yemen"
    .replace(/[’']s\b/g, '')
    .replace(/[’']/g, '')
    .replace(/\./g, '')
    .replace(/[^a-z0-9 -]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    // a hyphen left dangling at either end after the above is noise
    .replace(/^-+|-+$/g, '')
    .trim();
}

/**
 * Normalise, drop blanks, de-duplicate.
 *
 * This is a public boundary and must not depend on its caller having cleaned
 * anything — persisted rows, hand-written fixtures and future callers all
 * arrive here. De-duplication is part of normalisation, not a nicety: the set
 * size is the denominator of the overlap score, so ['norway', 'Norway'] must
 * count once or every score computed against it is wrong.
 *
 * No minimum length is applied. The extractor's own 3-character floor is its
 * business; silently discarding short entities here would make "usable"
 * disagree with what a reader sees in the column.
 */
export function normalizeEntities(raw: readonly string[]): string[] {
  const seen = new Set<string>();
  for (const entity of raw) {
    const normalized = normalizeEntity(entity);
    if (normalized.length > 0) seen.add(normalized);
  }
  return [...seen];
}

/**
 * Jaccard overlap of two entity sets, 0..1: shared / (union).
 *
 * An empty set on either side yields 0 rather than a division by zero or a
 * vacuous 1 — no entities means no evidence of a shared story, and the
 * correct response to no evidence is not to claim a match.
 */
export function entityOverlap(a: readonly string[], b: readonly string[]): number {
  const left = new Set(normalizeEntities(a));
  const right = new Set(normalizeEntities(b));
  if (left.size === 0 || right.size === 0) return 0;

  let shared = 0;
  for (const entity of left) {
    if (right.has(entity)) shared++;
  }

  // Inclusion-exclusion: |A ∪ B| = |A| + |B| − |A ∩ B|. Both sets are
  // non-empty here, so the union is non-empty and the division is safe.
  return shared / (left.size + right.size - shared);
}

/**
 * Does this side carry enough entity signal for the entity rule to be
 * trusted? If not, the caller must fall back to the prose rule rather than
 * declare everything new — see MIN_USABLE_ENTITIES.
 */
export function hasUsableEntities(entities: readonly string[]): boolean {
  return normalizeEntities(entities).length >= MIN_USABLE_ENTITIES;
}

/**
 * Duplicate iff the normalised values are equal AND the entity sets overlap
 * enough to be the same story.
 *
 * A blank value never matches anything. `isDegenerate` rejects blank-valued
 * claims upstream, but this is a pure predicate that has to be right on its
 * own: two claims whose values both normalised away are not evidence of the
 * same fact, they are evidence of two failed extractions.
 *
 * This function does NOT apply the usable-entity floor. It answers exactly
 * the question it is named for, and returns false when the entities are too
 * thin to support a match. Choosing the fallback when that happens is the
 * caller's decision, because only the caller knows what the fallback is —
 * claimGuard.check owns it.
 */
export function isSameFact(
  a: { valueKey: string; entities: readonly string[] },
  b: { valueKey: string; entities: readonly string[] },
  minOverlap: number = MIN_ENTITY_OVERLAP,
): boolean {
  const valueA = a.valueKey.trim();
  const valueB = b.valueKey.trim();
  if (valueA === '' || valueA !== valueB) return false;

  return entityOverlap(a.entities, b.entities) >= minOverlap;
}
