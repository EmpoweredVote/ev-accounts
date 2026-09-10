import { describe, it, expect } from 'vitest';
import {
  INTERNATIONAL_LANES,
  isDegenerate,
  partitionTargets,
  type LaneTarget,
} from './laneTargets.js';
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
