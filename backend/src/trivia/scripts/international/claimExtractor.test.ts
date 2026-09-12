import { describe, it, expect } from 'vitest';
import {
  pairwiseSharedEntities,
  clusterEntitySet,
  MIN_SHARED_TO_JOIN,
} from './claim-extractor.js';

/**
 * WHY THESE FUNCTIONS EXIST
 * -------------------------
 * `sharedEntities` used to be the intersection across ALL of a cluster's
 * articles, which measured empty on every cluster larger than two — that is,
 * on every running story. It is now the union of the overlaps that joined the
 * cluster's pairs. A leave-one-out drift simulation put the union at 0/18
 * below the 0.34 identity threshold, against 14/18 for the intersection.
 *
 * WHY THE JOIN BAR IS 3, AND WHY NORMALISATION COMES FIRST
 * --------------------------------------------------------
 * Measured on 73 live articles, 2026-09-12. At a 2-entity bar, transitive
 * union chained eight unrelated stories into one cluster — Ukraine's winter,
 * a Nigerian romance scam, the BRICS summit, and Australian aged care — and
 * that cluster is what produced the aged-care/oil-price mashup behind the
 * `wiran-1685` / `wiran-1688` duplicate.
 *
 *   norm  thr  clusters  singles  sizes          usable entities  thin(<2)
 *   off   2      6         46     10,8,3,2,2,2   15,11,6,2,5,1    1
 *   off   3      5         57     7,3,2,2,2      11,6,5,3,3       0
 *   on    3      5         56     7,3,3,2,2      16,8,7,6,3       0   <- chosen
 *   on    2      6         36     27,2,2,2,2,2   48,2,6,2,2,2     0
 *
 * THE TWO KNOBS ARE COUPLED. Normalising at a 2-entity bar is far WORSE than
 * today: more entities match, so chaining runs riot and 27 articles collapse
 * into a single cluster. Fixing the `yemen`/`yemen's` mismatch on its own
 * would have made clustering dramatically worse. Together they give the same
 * recall as raising the bar alone, with materially richer entity sets — which
 * is the headroom MIN_USABLE_ENTITIES needs.
 *
 * A 3-entity bar breaks weak links; it does not bound transitivity. If chains
 * of 3-entity overlaps show up later, the fix is requiring overlap with the
 * cluster as a whole, not climbing to 4 — that over-fragments (3 clusters).
 */
describe('clusterEntitySet', () => {
  it('folds a possessive so a story is not split from itself', () => {
    // compromise returns "yemen" from one article and "yemen's" from another.
    // Clustering compared raw strings, so these were different entities and
    // the join they should have carried never happened.
    const result = clusterEntitySet(['Yemen', "Yemen's"]);
    expect(result).toEqual(new Set(['yemen']));
  });

  it('strips trailing punctuation so "Iran," matches "Iran"', () => {
    expect(clusterEntitySet(['Iran,', 'Iran'])).toEqual(new Set(['iran']));
  });

  it('keeps genuinely distinct entities distinct', () => {
    const result = clusterEntitySet(['Yemen', 'Iran', 'Red Sea']);
    expect(result).toEqual(new Set(['yemen', 'iran', 'red sea']));
  });

  it('drops entities that normalise away to nothing', () => {
    expect(clusterEntitySet(['---', '  ', 'Iran'])).toEqual(new Set(['iran']));
  });
});

describe('MIN_SHARED_TO_JOIN', () => {
  it('is 3', () => {
    // Not a tautology: this constant is shared by the clustering join rule and
    // by pairwiseSharedEntities, and they MUST agree — a union built from
    // pairs the clustering would not have joined reports evidence the cluster
    // was not built on. Pinning it here makes a one-sided change fail loudly.
    expect(MIN_SHARED_TO_JOIN).toBe(3);
  });
});

describe('pairwiseSharedEntities', () => {
  const set = (...entities: string[]) => new Set(entities);

  it('keeps entities from a transitive chain where no entity is in every article', () => {
    // A-B join on {yemen, mokha, hodeidah}; B-C join on {aden, sanaa, taiz}.
    // A and C share nothing, so the all-articles intersection is empty — the
    // shape of the Mokha cluster that shipped a duplicate.
    const result = pairwiseSharedEntities([
      set('yemen', 'mokha', 'hodeidah'),
      set('yemen', 'mokha', 'hodeidah', 'aden', 'sanaa', 'taiz'),
      set('aden', 'sanaa', 'taiz'),
    ]);

    expect([...result].sort()).toEqual(
      ['aden', 'hodeidah', 'mokha', 'sanaa', 'taiz', 'yemen'],
    );
  });

  it('equals the intersection for a two-article cluster', () => {
    const result = pairwiseSharedEntities([
      set('norway', 'harald', 'oslo', 'monarchy'),
      set('norway', 'harald', 'bergen', 'monarchy'),
    ]);

    expect([...result].sort()).toEqual(['harald', 'monarchy', 'norway']);
  });

  it('ignores a pair sharing only two entities, which no longer justifies a join', () => {
    // This is the behaviour change. Two shared entities used to be enough, and
    // that is what chained eight unrelated stories together on live feeds.
    const result = pairwiseSharedEntities([
      set('russia', 'moscow', 'goethe'),
      set('russia', 'moscow', 'berlin'),
    ]);

    expect(result).toEqual([]);
  });

  it('excludes a weakly-overlapping pair while keeping a strong one in the same cluster', () => {
    // A-B share three; C shares only {russia, moscow} with each. C rides along
    // transitively, but contributes nothing, because two entities are not
    // evidence that it is the same story.
    const result = pairwiseSharedEntities([
      set('russia', 'moscow', 'goethe', 'institut'),
      set('russia', 'moscow', 'goethe', 'berlin'),
      set('russia', 'moscow', 'kaliningrad'),
    ]);

    expect([...result].sort()).toEqual(['goethe', 'moscow', 'russia']);
  });

  it('honours an explicit threshold over the default', () => {
    const sets = [set('a', 'b'), set('a', 'b')];
    expect(pairwiseSharedEntities(sets, 2)).toEqual(['a', 'b']);
    expect(pairwiseSharedEntities(sets, 3)).toEqual([]);
  });

  it('de-duplicates an entity shared by several pairs', () => {
    const result = pairwiseSharedEntities([
      set('gaza', 'israel', 'rafah'),
      set('gaza', 'israel', 'rafah'),
      set('gaza', 'israel', 'rafah'),
    ]);

    expect(result).toHaveLength(3);
  });

  it('returns nothing for a single article, which is not a cluster', () => {
    expect(pairwiseSharedEntities([set('yemen', 'mokha', 'aden')])).toEqual([]);
  });

  it('returns nothing for no articles', () => {
    expect(pairwiseSharedEntities([])).toEqual([]);
  });
});
