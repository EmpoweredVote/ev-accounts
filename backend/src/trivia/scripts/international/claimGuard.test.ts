import { describe, it, expect } from 'vitest';
import { makeClaimGuard, CLAIM_WINDOW_DAYS, type FingerprintRow, type FingerprintStore } from './claimGuard.js';
import type { Lane } from './lanes.js';

const NOW = new Date('2026-09-10T06:00:00Z');
const nowFn = () => NOW;

function daysAgo(n: number): Date {
  return new Date(NOW.getTime() - n * 24 * 60 * 60 * 1000);
}

function memoryStore(rows: FingerprintRow[] = []): FingerprintStore & { rows: FingerprintRow[] } {
  const store = {
    rows: [...rows],
    async findByTopicKey(topicKey: string, since: Date) {
      return store.rows.filter(r => r.topicKey === topicKey && r.firstSeenAt >= since);
    },
    async insert(row: FingerprintRow) {
      store.rows.push(row);
    },
  };
  return store;
}

function row(over: Partial<FingerprintRow> = {}): FingerprintRow {
  return {
    topicKey: 'king harald v|age at death',
    valueKey: '89',
    lane: 'world' as Lane,
    questionExternalId: 'wiran-1578',
    firstSeenAt: daysAgo(4),
    ...over,
  };
}

describe('claimGuard.check', () => {
  it('returns new for an unseen topic', async () => {
    const guard = makeClaimGuard(memoryStore(), nowFn);
    const verdict = await guard.check({ topicKey: 'unseen|thing', valueKey: '1' });
    expect(verdict.kind).toBe('new');
  });

  it('returns duplicate when topic and value both match', async () => {
    const guard = makeClaimGuard(memoryStore([row()]), nowFn);
    const verdict = await guard.check({ topicKey: 'king harald v|age at death', valueKey: '89' });
    expect(verdict.kind).toBe('duplicate');
    if (verdict.kind === 'duplicate') {
      expect(verdict.existing.questionExternalId).toBe('wiran-1578');
    }
  });

  it('returns contradiction when the topic matches but the value differs', async () => {
    const guard = makeClaimGuard(
      memoryStore([row({ topicKey: 'meta csam advertisements india|count', valueKey: '84', questionExternalId: 'clima-1599' })]),
      nowFn,
    );
    const verdict = await guard.check({ topicKey: 'meta csam advertisements india|count', valueKey: '78' });
    expect(verdict.kind).toBe('contradiction');
    if (verdict.kind === 'contradiction') {
      expect(verdict.existing.valueKey).toBe('84');
      expect(verdict.existing.questionExternalId).toBe('clima-1599');
    }
  });

  it('prefers duplicate over contradiction when both a matching and a differing value exist', async () => {
    const guard = makeClaimGuard(
      memoryStore([
        row({ valueKey: '89', questionExternalId: 'wiran-1578' }),
        row({ valueKey: '87', questionExternalId: 'wiran-9999' }),
      ]),
      nowFn,
    );
    const verdict = await guard.check({ topicKey: 'king harald v|age at death', valueKey: '89' });
    expect(verdict.kind).toBe('duplicate');
  });

  it('ignores rows older than the window', async () => {
    const guard = makeClaimGuard(memoryStore([row({ firstSeenAt: daysAgo(CLAIM_WINDOW_DAYS + 1) })]), nowFn);
    const verdict = await guard.check({ topicKey: 'king harald v|age at death', valueKey: '89' });
    expect(verdict.kind).toBe('new');
  });

  it('counts a row exactly at the window edge as in-window', async () => {
    const guard = makeClaimGuard(memoryStore([row({ firstSeenAt: daysAgo(CLAIM_WINDOW_DAYS) })]), nowFn);
    const verdict = await guard.check({ topicKey: 'king harald v|age at death', valueKey: '89' });
    expect(verdict.kind).toBe('duplicate');
  });

  it('does not treat a different topic with the same value as related', async () => {
    const guard = makeClaimGuard(
      memoryStore([row({ topicKey: 'russia north korea tumen river road bridge|year opened', valueKey: '2026' })]),
      nowFn,
    );
    const verdict = await guard.check({
      topicKey: 'uganda withdrawal invictus games|year announced',
      valueKey: '2026',
    });
    expect(verdict.kind).toBe('new');
  });

  it('uses a 14-day window', () => {
    expect(CLAIM_WINDOW_DAYS).toBe(14);
  });
});

describe('claimGuard.record', () => {
  it('persists a row that a later check finds as a duplicate', async () => {
    const store = memoryStore();
    const guard = makeClaimGuard(store, nowFn);
    await guard.record({ topicKey: 't|a', valueKey: 'v' }, 'us', 'usnws-0001', 42);

    expect(store.rows).toHaveLength(1);
    expect(store.rows[0].lane).toBe('us');
    expect(store.rows[0].firstSeenAt).toEqual(NOW);

    const verdict = await guard.check({ topicKey: 't|a', valueKey: 'v' });
    expect(verdict.kind).toBe('duplicate');
  });
});
