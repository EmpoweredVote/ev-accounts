import { describe, it, expect } from 'vitest';
import {
  INTERNATIONAL_LANES,
  isDegenerate,
  isSystemicClusterFailure,
  partitionRejections,
  partitionTargets,
  type LaneTarget,
} from './laneTargets.js';
import type { Lane } from './lanes.js';
import { fingerprintClaim } from './claimFingerprint.js';

describe('isDegenerate', () => {
  it('rejects a fully blank triple ("|" with an empty value)', () => {
    expect(isDegenerate({ topicKey: '|', valueKey: '' })).toBe(true);
  });

  it('rejects a blank subject with a real attribute', () => {
    expect(isDegenerate({ topicKey: '|deaths', valueKey: '1287' })).toBe(true);
  });

  it('rejects a real subject with a blank attribute', () => {
    expect(isDegenerate({ topicKey: 'iran|', valueKey: '1287' })).toBe(true);
  });

  it('rejects a blank valueKey even when the topic key is well formed', () => {
    expect(isDegenerate({ topicKey: 'iran|death toll', valueKey: '' })).toBe(true);
  });

  it('accepts a well-formed key', () => {
    expect(isDegenerate({ topicKey: 'iran|death toll', valueKey: '1287' })).toBe(false);
  });

  it('treats a whitespace-only half as blank', () => {
    expect(isDegenerate({ topicKey: '   |deaths', valueKey: '12' })).toBe(true);
    expect(isDegenerate({ topicKey: 'iran|deaths', valueKey: '   ' })).toBe(true);
  });

  it('rejects a topic key with no separator at all', () => {
    expect(isDegenerate({ topicKey: 'iran', valueKey: '12' })).toBe(true);
  });

  // The regression that motivated splitting the halves: no field is blank,
  // but noise-word stripping empties one of them.
  it('rejects a claim whose subject is only noise words', () => {
    const keys = fingerprintClaim({
      subject: 'the people',
      attribute: 'death toll',
      value: '1287',
    });
    expect(keys.topicKey).toBe('|death toll');
    expect(isDegenerate(keys)).toBe(true);
  });

  it('rejects a claim whose attribute is only noise words', () => {
    const keys = fingerprintClaim({ subject: 'Iran', attribute: 'the', value: '1287' });
    expect(keys.topicKey).toBe('iran|');
    expect(isDegenerate(keys)).toBe(true);
  });

  it('accepts a normal claim end to end', () => {
    const keys = fingerprintClaim({
      subject: 'Iran',
      attribute: 'reported death toll',
      value: '1,287 people',
    });
    expect(isDegenerate(keys)).toBe(false);
  });
});

describe('partitionTargets', () => {
  const targets: readonly LaneTarget[] = [
    { lane: 'iran', collectionSlug: 'war-in-iran', prefix: 'wiran', volatility: 'fast' },
    { lane: 'world', collectionSlug: 'world-news', prefix: 'wnews', volatility: 'fast' },
    { lane: 'us', collectionSlug: 'us-news', prefix: 'usnws', volatility: 'fast' },
  ];

  it('serves every lane when all slugs resolved', () => {
    const { served, missing } = partitionTargets(
      targets,
      new Set(['war-in-iran', 'world-news', 'us-news']),
    );
    expect(served.map(t => t.lane)).toEqual(['iran', 'world', 'us']);
    expect(missing).toEqual([]);
  });

  it('serves nothing when no slug resolved', () => {
    const { served, missing } = partitionTargets(targets, new Set());
    expect(served).toEqual([]);
    expect(missing.map(t => t.lane)).toEqual(['iran', 'world', 'us']);
  });

  it('splits a partial resolution and keeps registry order', () => {
    const { served, missing } = partitionTargets(targets, new Set(['war-in-iran']));
    expect(served.map(t => t.lane)).toEqual(['iran']);
    expect(missing.map(t => t.collectionSlug)).toEqual(['world-news', 'us-news']);
  });

  it('ignores resolved slugs that no lane asked for', () => {
    const { served, missing } = partitionTargets(targets, new Set(['bloomington-in', 'us-news']));
    expect(served.map(t => t.lane)).toEqual(['us']);
    expect(missing.map(t => t.lane)).toEqual(['iran', 'world']);
  });

  it('returns two empty lists for an empty registry', () => {
    const { served, missing } = partitionTargets([], new Set(['war-in-iran']));
    expect(served).toEqual([]);
    expect(missing).toEqual([]);
  });

  it('returns the same LaneTarget objects, not copies', () => {
    const { served } = partitionTargets(targets, new Set(['us-news']));
    expect(served[0]).toBe(targets[2]);
  });
});

describe('INTERNATIONAL_LANES', () => {
  it('registers exactly one target per lane', () => {
    const lanes = INTERNATIONAL_LANES.map(t => t.lane);
    expect(new Set(lanes).size).toBe(lanes.length);
  });

  it('gives every lane a distinct collection slug and prefix', () => {
    expect(new Set(INTERNATIONAL_LANES.map(t => t.collectionSlug)).size)
      .toBe(INTERNATIONAL_LANES.length);
    expect(new Set(INTERNATIONAL_LANES.map(t => t.prefix)).size)
      .toBe(INTERNATIONAL_LANES.length);
  });
});

describe('partitionRejections', () => {
  const served = new Set<Lane>(['iran', 'us']);

  it('routes a rejection to its own lane only', () => {
    const r = { reason: 'duplicate-claim', lane: 'iran' };
    const p = partitionRejections([r], served);
    expect(p.forLane('iran')).toEqual([r]);
    expect(p.forLane('us')).toEqual([]);
    expect(p.unroutable).toEqual([]);
  });

  it('treats a rejection for an unserved lane as unroutable', () => {
    // `no-target` rejections exist BECAUSE the lane is unserved, so a
    // per-lane filter can never match them.
    const r = { reason: 'no-target', lane: 'climate' };
    const p = partitionRejections([r], served);
    expect(p.unroutable).toEqual([r]);
    expect(p.forLane('iran')).toEqual([]);
  });

  it('treats a rejection with lane: undefined as unroutable', () => {
    // A cluster that threw before its lane was resolved.
    const r = { reason: 'cluster-error', lane: undefined, error: 'boom' };
    const p = partitionRejections([r], served);
    expect(p.unroutable).toEqual([r]);
  });

  it('treats a rejection with no lane key at all as unroutable', () => {
    const r = { reason: 'cluster-error', error: 'boom' };
    const p = partitionRejections([r], served);
    expect(p.unroutable).toEqual([r]);
  });

  it('returns empty buckets for an empty input', () => {
    const p = partitionRejections([], served);
    expect(p.unroutable).toEqual([]);
    expect(p.forLane('iran')).toEqual([]);
  });

  it('returns an empty bucket for a served lane with no rejections', () => {
    const p = partitionRejections([{ reason: 'no-target', lane: 'world' }], served);
    expect(p.forLane('us')).toEqual([]);
  });

  // The actual invariant: nothing may be dropped, and nothing duplicated.
  it('places every rejection exactly once across unroutable and the lane buckets', () => {
    const all = [
      { reason: 'duplicate-claim', lane: 'iran', n: 0 },
      { reason: 'no-target', lane: 'climate', n: 1 },
      { reason: 'cluster-error', lane: undefined, n: 2 },
      { reason: 'contradiction', lane: 'us', n: 3 },
      { reason: 'near-duplicate', lane: 'iran', n: 4 },
      { reason: 'cluster-error', n: 5 },
      { reason: 'no-target', lane: 'world', n: 6 },
      { reason: 'degenerate-claim', lane: 'us', n: 7 },
    ];

    const p = partitionRejections(all, served);
    const placed = [
      ...p.unroutable,
      ...p.forLane('iran'),
      ...p.forLane('us'),
      ...p.forLane('climate'),
      ...p.forLane('world'),
    ];

    expect(placed).toHaveLength(all.length);
    // Identity, not deep equality: each input object appears once and only once.
    for (const r of all) {
      expect(placed.filter(x => x === r)).toHaveLength(1);
    }
  });

  it('preserves input order within each bucket', () => {
    const a = { reason: 'duplicate-claim', lane: 'iran', n: 0 };
    const b = { reason: 'no-target', lane: 'climate', n: 1 };
    const c = { reason: 'near-duplicate', lane: 'iran', n: 2 };
    const d = { reason: 'cluster-error', lane: undefined, n: 3 };

    const p = partitionRejections([a, b, c, d], served);
    expect(p.forLane('iran')).toEqual([a, c]);
    expect(p.unroutable).toEqual([b, d]);
  });

  it('routes nothing anywhere but unroutable when no lane is served', () => {
    const all = [
      { reason: 'duplicate-claim', lane: 'iran' },
      { reason: 'contradiction', lane: 'us' },
    ];
    const p = partitionRejections(all, new Set());
    expect(p.unroutable).toEqual(all);
    expect(p.forLane('iran')).toEqual([]);
  });
});

describe('isSystemicClusterFailure', () => {
  it('is not a failure when no cluster was attempted', () => {
    expect(isSystemicClusterFailure(0, 0)).toBe(false);
  });

  it('is not a failure when one throw sits among many legitimate rejections', () => {
    expect(isSystemicClusterFailure(21, 1)).toBe(false);
  });

  it('is a failure when every attempted cluster errored', () => {
    expect(isSystemicClusterFailure(8, 8)).toBe(true);
  });

  it('is a failure when errors exceed attempts (defensive: >= must hold)', () => {
    expect(isSystemicClusterFailure(8, 9)).toBe(true);
  });

  it('is not a failure one error short of systemic', () => {
    expect(isSystemicClusterFailure(8, 7)).toBe(false);
  });

  it('is a failure for a single attempted cluster that threw', () => {
    expect(isSystemicClusterFailure(1, 1)).toBe(true);
  });

  it('is not a failure with zero attempts even if errors are somehow nonzero', () => {
    expect(isSystemicClusterFailure(0, 3)).toBe(false);
  });
});
