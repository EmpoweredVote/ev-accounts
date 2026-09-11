import type { ClaimKeys } from './claimFingerprint.js';
import type { Lane } from './lanes.js';
import {
  MIN_ENTITY_OVERLAP,
  entityOverlap,
  hasUsableEntities,
  normalizeEntities,
} from './claimIdentity.js';

/** How far back a claim counts as already covered. */
export const CLAIM_WINDOW_DAYS = 14;

export interface FingerprintRow {
  topicKey: string;
  valueKey: string;
  /**
   * The story's shared named entities, as recorded. Empty for rows written
   * before the entity column existed, and for rows recorded while the
   * fallback was in force — `check` treats both cases as "no entity data" and
   * compares those candidates on the topic key instead.
   */
  entities: string[];
  lane: Lane;
  questionExternalId: string | null;
  firstSeenAt: Date;
}

export interface FingerprintStore {
  /**
   * Candidate rows first seen at or after `since`: every row whose VALUE key
   * matches (the duplicate rule's candidate pool) or whose TOPIC key matches
   * (the contradiction rule's pool).
   *
   * One method rather than two because the two pools are needed on every
   * check and a single `WHERE topic_key = $1 OR value_key = $2` is one round
   * trip. It replaces the old `findByTopicKey`: duplicate detection is no
   * longer a keyed lookup but a comparison against candidates, so the topic
   * key alone can no longer fetch the right rows.
   */
  findCandidates(keys: ClaimKeys, since: Date): Promise<FingerprintRow[]>;
  insert(row: FingerprintRow & { generationJobId: number | null }): Promise<void>;
}

/**
 * Which of the two rules is in play.
 *
 * `entities` — the value-equality-plus-entity-overlap rule.
 * `topic-fallback` — the old prose rule: topic key AND value key equal.
 *
 * As a verdict's `mode` it says which rule the incoming claim's entity signal
 * ALLOWED; as an observation's `basis` it says which rule actually decided
 * that candidate.
 */
export type IdentityBasis = 'entities' | 'topic-fallback';

/**
 * One value-matched candidate and the overlap computed against it.
 *
 * Emitted for near-misses as well as matches, because the near-misses are
 * the only evidence available for tuning MIN_ENTITY_OVERLAP. `overlap` is
 * always the real computed number, even on a `topic-fallback` comparison
 * where it did not decide anything — a fallback row scoring 0.9 is exactly
 * the signal that the floor is set too high.
 */
export interface OverlapObservation {
  existing: FingerprintRow;
  overlap: number;
  /** Did this candidate count as the same fact? */
  matched: boolean;
  /** Which rule was applied to THIS candidate. */
  basis: IdentityBasis;
}

export type ClaimVerdict =
  | { kind: 'new'; mode: IdentityBasis; overlaps: OverlapObservation[] }
  | {
      kind: 'duplicate';
      existing: FingerprintRow;
      overlap: number;
      /** Which rule caught it — not the same as `mode`. */
      basis: IdentityBasis;
      mode: IdentityBasis;
      overlaps: OverlapObservation[];
    }
  | {
      kind: 'contradiction';
      existing: FingerprintRow;
      mode: IdentityBasis;
      overlaps: OverlapObservation[];
    };

export function makeClaimGuard(store: FingerprintStore, now: () => Date = () => new Date()) {
  function windowStart(): Date {
    return new Date(now().getTime() - CLAIM_WINDOW_DAYS * 24 * 60 * 60 * 1000);
  }

  return {
    /**
     * `entities` is the story cluster's `sharedEntities` — the entities
     * present in every article of the cluster. Read straight off the cluster
     * by the caller; it is a property of the story, not of the extracted
     * triple, which is why it is a separate argument rather than part of
     * `keys`.
     */
    async check(keys: ClaimKeys, entities: readonly string[] = []): Promise<ClaimVerdict> {
      const rows = await store.findCandidates(keys, windowStart());

      // Is there enough entity signal for the entity rule to decide anything?
      // An empty or single-entity cluster gives it nothing to work with — and
      // `sharedEntities` is the intersection across EVERY article in the
      // cluster, so a seven-article cluster can narrow to one entity or none.
      // Those claims fall back to the old prose rule: strictly worse at
      // catching re-phrasings, but it is the behaviour that shipped, and a
      // known-weak check beats calling every such claim new.
      const useEntities = hasUsableEntities(entities);
      const mode: IdentityBasis = useEntities ? 'entities' : 'topic-fallback';

      const valueMatches = rows.filter(r => r.valueKey === keys.valueKey);

      const overlaps: OverlapObservation[] = valueMatches.map(row => {
        // Computed for every candidate regardless of which rule decides, so
        // the log carries tuning data even where it did not decide.
        const overlap = entityOverlap(entities, row.entities);

        // The two routes to a duplicate are a DISJUNCTION, deliberately. The
        // entity rule exists to catch what the prose rule misses, so it is
        // added to the prose rule rather than substituted for it — this change
        // must not be able to let through a duplicate the old rule caught.
        //
        // That matters in two concrete cases. A stored row can lack entities
        // even when the incoming claim has them: every row written before the
        // migration does, and so does every row recorded while the fallback
        // was in force — scoring those 0 would blind the guard to the entire
        // pre-migration backlog for a full 14-day window. And the entity sets
        // for one story can drift apart far enough to miss the floor while
        // the prose stayed identical, which is a duplicate by any reading.
        const entityMatch =
          useEntities && hasUsableEntities(row.entities) && overlap >= MIN_ENTITY_OVERLAP;
        const topicMatch = row.topicKey === keys.topicKey;

        return {
          existing: row,
          overlap,
          matched: entityMatch || topicMatch,
          // Attribute the catch to the rule that made it. When both fire, the
          // entity rule gets the credit: it is the one being evaluated.
          basis: entityMatch ? 'entities' : 'topic-fallback',
        };
      });

      // A value match is a plain duplicate and takes priority: if we have
      // already published this exact answer for this story, that is the
      // relevant fact, regardless of what else the pool says about the topic.
      const hit = overlaps.find(o => o.matched);
      if (hit) {
        return {
          kind: 'duplicate',
          existing: hit.existing,
          overlap: hit.overlap,
          basis: hit.basis,
          mode,
          overlaps,
        };
      }

      // Same topic, different answer: two live answers to one question.
      //
      // HONEST LIMITATION: contradiction needs the *attribute concept*
      // ("number of people killed" is the same question as "death toll"),
      // and the only handle on that is the model prose this whole change
      // moved away from. So contradiction detection remains string equality
      // on `topicKey` and remains best-effort: it misses any contradiction
      // where the model re-phrased the attribute between runs, which is
      // exactly the drift the Mokha case demonstrated. That is not papered
      // over here because there is no honest fix available at this layer.
      //
      // It deliberately does NOT use the entity rule. Same entities plus a
      // different value is usually a different fact, not a contradiction —
      // Oct 7 deaths (1200) and Oct 7 hostages (251) share every entity and
      // are both true. Routing that pair through contradiction would suppress
      // legitimate second questions about every story in the pool.
      const topicMatches = rows.filter(
        r => r.topicKey === keys.topicKey && r.valueKey !== keys.valueKey,
      );
      if (topicMatches.length > 0) {
        const newest = topicMatches.reduce((n, r) => (r.firstSeenAt > n.firstSeenAt ? r : n));
        return { kind: 'contradiction', existing: newest, mode, overlaps };
      }

      return { kind: 'new', mode, overlaps };
    },

    async record(
      keys: ClaimKeys,
      entities: readonly string[],
      lane: Lane,
      questionExternalId: string | null,
      generationJobId: number | null,
    ): Promise<void> {
      await store.insert({
        topicKey: keys.topicKey,
        valueKey: keys.valueKey,
        // Normalised on the way in so the column holds comparable values and
        // a later read needs no cleanup pass to be correct.
        entities: normalizeEntities(entities),
        lane,
        questionExternalId,
        firstSeenAt: now(),
        generationJobId,
      });
    },
  };
}
