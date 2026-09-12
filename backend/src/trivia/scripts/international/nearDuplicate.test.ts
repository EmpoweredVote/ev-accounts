import { describe, it, expect } from 'vitest';
import {
  makeNearDuplicateCheck,
  NEAR_DUP_THRESHOLD,
  type SimilarityHit,
  type SimilarityProbe,
} from './nearDuplicate.js';

function probeReturning(hit: SimilarityHit | null): SimilarityProbe & { calls: unknown[] } {
  const p = {
    calls: [] as unknown[],
    async mostSimilar(text: string, collectionIds: readonly number[]) {
      p.calls.push({ text, collectionIds });
      return hit;
    },
  };
  return p;
}

describe('nearDuplicateCheck', () => {
  it('accepts text when the probe finds nothing', async () => {
    const check = makeNearDuplicateCheck(probeReturning(null));
    expect(await check('anything', [266])).toBeNull();
  });

  it('rejects a hit above the threshold', async () => {
    const check = makeNearDuplicateCheck(
      probeReturning({ externalId: 'wiran-1578', similarity: 0.81 }),
    );
    const result = await check('At what age did King Harald V of Norway die in 2026?', [266]);
    expect(result?.externalId).toBe('wiran-1578');
  });

  it('accepts a hit below the threshold', async () => {
    const check = makeNearDuplicateCheck(
      probeReturning({ externalId: 'wiran-1611', similarity: 0.22 }),
    );
    expect(await check('unrelated question text', [266])).toBeNull();
  });

  it('treats a hit exactly at the threshold as a duplicate', async () => {
    const check = makeNearDuplicateCheck(
      probeReturning({ externalId: 'x-1', similarity: NEAR_DUP_THRESHOLD }),
    );
    expect(await check('text', [266])).not.toBeNull();
  });

  it('honours an overridden threshold', async () => {
    const check = makeNearDuplicateCheck(
      probeReturning({ externalId: 'x-1', similarity: 0.6 }),
      0.9,
    );
    expect(await check('text', [266])).toBeNull();
  });

  it('probes every supplied collection id, not just one lane', async () => {
    const probe = probeReturning(null);
    const check = makeNearDuplicateCheck(probe);
    await check('text', [266, 267, 300, 301]);
    expect((probe.calls[0] as { collectionIds: number[] }).collectionIds).toEqual([266, 267, 300, 301]);
  });

  // Replaces 'probes back exactly the window'. Layer 2 is deliberately
  // unbounded in time: curated evergreen questions are the oldest rows in a
  // lane's collection and have no claim fingerprints, so an age bound would
  // hide the only questions Layer 2 alone can catch. Asserting the probe is
  // called with exactly two arguments is what pins that down — a
  // reintroduced window would show up here as a third.
  it('passes no time bound to the probe', async () => {
    const seen: unknown[][] = [];
    const probe: SimilarityProbe = {
      async mostSimilar(...args: unknown[]) {
        seen.push(args);
        return null;
      },
    };
    const check = makeNearDuplicateCheck(probe);
    await check('text', [266]);
    expect(seen[0]).toEqual(['text', [266]]);
  });

  it('defaults the threshold to 0.55', () => {
    expect(NEAR_DUP_THRESHOLD).toBe(0.55);
  });
});
