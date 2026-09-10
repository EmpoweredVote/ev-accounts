import { describe, it, expect } from 'vitest';
import {
  makeNearDuplicateCheck,
  NEAR_DUP_THRESHOLD,
  NEAR_DUP_WINDOW_DAYS,
  type SimilarityHit,
  type SimilarityProbe,
} from './nearDuplicate.js';

const NOW = new Date('2026-09-10T06:00:00Z');

function probeReturning(hit: SimilarityHit | null): SimilarityProbe & { calls: unknown[] } {
  const p = {
    calls: [] as unknown[],
    async mostSimilar(text: string, collectionIds: readonly number[], since: Date) {
      p.calls.push({ text, collectionIds, since });
      return hit;
    },
  };
  return p;
}

describe('nearDuplicateCheck', () => {
  it('accepts text when the probe finds nothing', async () => {
    const check = makeNearDuplicateCheck(probeReturning(null), undefined, () => NOW);
    expect(await check('anything', [266])).toBeNull();
  });

  it('rejects a hit above the threshold', async () => {
    const check = makeNearDuplicateCheck(
      probeReturning({ externalId: 'wiran-1578', similarity: 0.81 }),
      undefined,
      () => NOW,
    );
    const result = await check('At what age did King Harald V of Norway die in 2026?', [266]);
    expect(result?.externalId).toBe('wiran-1578');
  });

  it('accepts a hit below the threshold', async () => {
    const check = makeNearDuplicateCheck(
      probeReturning({ externalId: 'wiran-1611', similarity: 0.22 }),
      undefined,
      () => NOW,
    );
    expect(await check('unrelated question text', [266])).toBeNull();
  });

  it('treats a hit exactly at the threshold as a duplicate', async () => {
    const check = makeNearDuplicateCheck(
      probeReturning({ externalId: 'x-1', similarity: NEAR_DUP_THRESHOLD }),
      undefined,
      () => NOW,
    );
    expect(await check('text', [266])).not.toBeNull();
  });

  it('honours an overridden threshold', async () => {
    const check = makeNearDuplicateCheck(
      probeReturning({ externalId: 'x-1', similarity: 0.6 }),
      0.9,
      () => NOW,
    );
    expect(await check('text', [266])).toBeNull();
  });

  it('probes every supplied collection id, not just one lane', async () => {
    const probe = probeReturning(null);
    const check = makeNearDuplicateCheck(probe, undefined, () => NOW);
    await check('text', [266, 267, 300, 301]);
    expect((probe.calls[0] as { collectionIds: number[] }).collectionIds).toEqual([266, 267, 300, 301]);
  });

  it('probes back exactly the window', async () => {
    const probe = probeReturning(null);
    const check = makeNearDuplicateCheck(probe, undefined, () => NOW);
    await check('text', [266]);
    const since = (probe.calls[0] as { since: Date }).since;
    const expected = new Date(NOW.getTime() - NEAR_DUP_WINDOW_DAYS * 24 * 60 * 60 * 1000);
    expect(since).toEqual(expected);
  });

  it('defaults the threshold to 0.55', () => {
    expect(NEAR_DUP_THRESHOLD).toBe(0.55);
  });
});
