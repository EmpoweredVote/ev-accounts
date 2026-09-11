import { describe, it, expect } from 'vitest';
import { pairwiseSharedEntities } from './claim-extractor.js';

/**
 * WHY THIS FUNCTION EXISTS
 * -----------------------
 * `sharedEntities` used to be the intersection across ALL of a cluster's
 * articles. For a 2-article cluster that is tautological — the union-find join
 * rule already requires 2+ shared entities — but for larger clusters nothing
 * survives. Measured on a live fetch of 72 articles into 9 clusters:
 *
 *   [0 entities]  9 articles   Goethe-Institut closing in Russia
 *   [0 entities]  5 articles   Houthis seize Mokha port          <- motivating case
 *   [1 entities]  4 articles   Trump implores Republicans
 *   [2-5]         2 articles   every remaining cluster
 *
 * Perfect separation by cluster size: the entity rule could only ever fire
 * where it was guaranteed to, and was blind precisely on running stories —
 * the population that produces cross-run duplicates.
 *
 * A leave-one-out drift simulation over clusters of 3+ articles then compared
 * the candidates. Jaccard(full cluster, cluster minus one article):
 *
 *   intersection    14/18 below the 0.34 threshold, 17/18 unusable
 *   pairwise union   0/18 below,                     0/18 unusable
 *   quorum (n/2)     2/18 below,                     0/18 unusable
 *
 * Quorum fails on the 5-article cluster (min 0.250) because its bar is
 * ceil(n/2): losing one article moves the bar and rewrites the set. The
 * pairwise union has no size-dependent bar.
 */
describe('pairwiseSharedEntities', () => {
  const set = (...entities: string[]) => new Set(entities);

  it('keeps entities from a transitive chain where no entity is in every article', () => {
    // A-B join on {yemen, mokha}; B-C join on {aden, sanaa}; A and C share
    // nothing. The all-articles intersection is empty — this is the shape of
    // the 5-article Mokha cluster that shipped a duplicate.
    const result = pairwiseSharedEntities([
      set('yemen', 'mokha'),
      set('yemen', 'mokha', 'aden', 'sanaa'),
      set('aden', 'sanaa'),
    ]);

    expect([...result].sort()).toEqual(['aden', 'mokha', 'sanaa', 'yemen']);
  });

  it('equals the intersection for a two-article cluster', () => {
    // The join rule guarantees 2+ shared for a pair, so this is the case the
    // old behaviour already handled. It must not regress.
    const result = pairwiseSharedEntities([
      set('norway', 'harald', 'oslo'),
      set('norway', 'harald', 'bergen'),
    ]);

    expect([...result].sort()).toEqual(['harald', 'norway']);
  });

  it('ignores a pair that shares too little to have joined on it', () => {
    // A-B join on {russia, moscow}. C sits in the cluster transitively but
    // shares only {russia} with each — one entity never justified a join, so
    // it is not evidence, and nothing new enters from those pairs.
    const result = pairwiseSharedEntities([
      set('russia', 'moscow', 'goethe'),
      set('russia', 'moscow', 'berlin'),
      set('russia', 'kaliningrad'),
    ]);

    expect([...result].sort()).toEqual(['moscow', 'russia']);
  });

  it('de-duplicates an entity shared by several pairs', () => {
    const result = pairwiseSharedEntities([
      set('gaza', 'israel'),
      set('gaza', 'israel'),
      set('gaza', 'israel'),
    ]);

    expect(result).toHaveLength(2);
  });

  it('returns nothing for a single article, which is not a cluster', () => {
    expect(pairwiseSharedEntities([set('yemen', 'mokha')])).toEqual([]);
  });

  it('returns nothing for no articles', () => {
    expect(pairwiseSharedEntities([])).toEqual([]);
  });
});
