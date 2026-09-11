import { describe, it, expect } from 'vitest';
import { makeClaimGuard, CLAIM_WINDOW_DAYS, type FingerprintRow, type FingerprintStore } from './claimGuard.js';
import type { ClaimKeys } from './claimFingerprint.js';
import type { Lane } from './lanes.js';

const NOW = new Date('2026-09-10T06:00:00Z');
const nowFn = () => NOW;

function daysAgo(n: number): Date {
  return new Date(NOW.getTime() - n * 24 * 60 * 60 * 1000);
}

function memoryStore(rows: FingerprintRow[] = []): FingerprintStore & { rows: FingerprintRow[] } {
  const store = {
    rows: [...rows],
    async findCandidates(keys: ClaimKeys, since: Date) {
      return store.rows.filter(
        r =>
          r.firstSeenAt >= since &&
          (r.topicKey === keys.topicKey || r.valueKey === keys.valueKey),
      );
    },
    async insert(row: FingerprintRow) {
      store.rows.push(row);
    },
  };
  return store;
}

const HARALD_ENTITIES = ['king harald', 'norway'];

function row(over: Partial<FingerprintRow> = {}): FingerprintRow {
  return {
    topicKey: 'king harald v|age at death',
    valueKey: '89',
    entities: [...HARALD_ENTITIES],
    lane: 'world' as Lane,
    questionExternalId: 'wiran-1578',
    firstSeenAt: daysAgo(4),
    ...over,
  };
}

describe('claimGuard.check — the entity rule', () => {
  it('returns new for an unseen claim', async () => {
    const guard = makeClaimGuard(memoryStore(), nowFn);
    const verdict = await guard.check({ topicKey: 'unseen|thing', valueKey: '1' }, ['alpha', 'beta']);
    expect(verdict.kind).toBe('new');
    expect(verdict.mode).toBe('entities');
    expect(verdict.overlaps).toEqual([]);
  });

  it('returns duplicate when the value matches and the entities overlap', async () => {
    const guard = makeClaimGuard(memoryStore([row()]), nowFn);
    const verdict = await guard.check(
      { topicKey: 'king harald v|age at death', valueKey: '89' },
      HARALD_ENTITIES,
    );
    expect(verdict.kind).toBe('duplicate');
    if (verdict.kind === 'duplicate') {
      expect(verdict.existing.questionExternalId).toBe('wiran-1578');
      expect(verdict.overlap).toBe(1);
      expect(verdict.mode).toBe('entities');
    }
  });

  // The regression that motivated the whole change. Both runs covered the
  // Houthi seizure of Mokha; the model re-authored subject, attribute AND
  // value units, so the old topicKey rule saw two unrelated claims and a
  // duplicate question shipped.
  it('Mokha: catches the cross-run duplicate the topicKey rule missed', async () => {
    const runOne = row({
      topicKey: 'houthi capture mokha port yemen|distance from bab al-mandab strait',
      valueKey: '75',
      entities: ['houthi', 'mokha', 'bab al-mandab', 'yemen'],
      questionExternalId: 'wiran-1667',
    });
    const guard = makeClaimGuard(memoryStore([runOne]), nowFn);

    // Run 2, 90 seconds later: different subject noun, an appended qualifier
    // in the attribute, and one entity swapped out of the cluster.
    const verdict = await guard.check(
      {
        topicKey: 'houthi seizure mokha port yemen|distance from bab al-mandab strait after capture',
        valueKey: '75',
      },
      ['houthi', 'mokha', 'bab al-mandab', 'red sea'],
    );

    expect(verdict.kind).toBe('duplicate');
    if (verdict.kind === 'duplicate') {
      expect(verdict.existing.questionExternalId).toBe('wiran-1667');
      // 3 shared of 5 in the union.
      expect(verdict.overlap).toBeCloseTo(0.6, 5);
    }
  });

  it('Harald: catches a cross-day duplicate when the cluster gained an entity', async () => {
    const guard = makeClaimGuard(
      memoryStore([row({ firstSeenAt: daysAgo(11), entities: ['king harald', 'norway'] })]),
      nowFn,
    );
    // 11 days on, the story has moved from the death to the funeral and the
    // cluster picked up Oslo. Set equality would have missed this.
    const verdict = await guard.check(
      { topicKey: 'king harald|age when he died', valueKey: '89' },
      ['king harald', 'norway', 'oslo'],
    );
    expect(verdict.kind).toBe('duplicate');
    if (verdict.kind === 'duplicate') {
      expect(verdict.overlap).toBeCloseTo(2 / 3, 5);
    }
  });

  it('Oct 7: two facts from one story with different values stay separate', async () => {
    const octEntities = ['hamas', 'israel', 'gaza'];
    const deaths = row({
      topicKey: '7 october 2023 hamas israel|number killed',
      valueKey: '1200',
      entities: octEntities,
      questionExternalId: 'wiran-1668',
    });
    const guard = makeClaimGuard(memoryStore([deaths]), nowFn);

    const verdict = await guard.check(
      { topicKey: '7 october 2023 hamas israel|number of hostages taken', valueKey: '251' },
      octEntities,
    );
    // Identical entities, different value: a different fact, and NOT a
    // contradiction either — both numbers are true.
    expect(verdict.kind).toBe('new');
    expect(verdict.overlaps).toEqual([]);
  });

  it('unrelated stories that happen to share a value stay separate', async () => {
    const guard = makeClaimGuard(
      memoryStore([
        row({
          topicKey: 'russia north korea tumen river road bridge|year opened',
          valueKey: '2026',
          entities: ['russia', 'north korea', 'tumen river'],
        }),
      ]),
      nowFn,
    );
    const verdict = await guard.check(
      { topicKey: 'uganda withdrawal invictus games|year announced', valueKey: '2026' },
      ['uganda', 'invictus games', 'king charles'],
    );
    expect(verdict.kind).toBe('new');
    // The value matched, so the near-miss IS logged — that is the point.
    expect(verdict.overlaps).toHaveLength(1);
    expect(verdict.overlaps[0].overlap).toBe(0);
    expect(verdict.overlaps[0].matched).toBe(false);
  });

  it('prefers duplicate over contradiction when both a matching and a differing value exist', async () => {
    const guard = makeClaimGuard(
      memoryStore([
        row({ valueKey: '89', questionExternalId: 'wiran-1578' }),
        row({ valueKey: '87', questionExternalId: 'wiran-9999' }),
      ]),
      nowFn,
    );
    const verdict = await guard.check(
      { topicKey: 'king harald v|age at death', valueKey: '89' },
      HARALD_ENTITIES,
    );
    expect(verdict.kind).toBe('duplicate');
  });

  it('ignores rows older than the window', async () => {
    const guard = makeClaimGuard(
      memoryStore([row({ firstSeenAt: daysAgo(CLAIM_WINDOW_DAYS + 1) })]),
      nowFn,
    );
    const verdict = await guard.check(
      { topicKey: 'king harald v|age at death', valueKey: '89' },
      HARALD_ENTITIES,
    );
    expect(verdict.kind).toBe('new');
  });

  it('counts a row exactly at the window edge as in-window', async () => {
    const guard = makeClaimGuard(
      memoryStore([row({ firstSeenAt: daysAgo(CLAIM_WINDOW_DAYS) })]),
      nowFn,
    );
    const verdict = await guard.check(
      { topicKey: 'king harald v|age at death', valueKey: '89' },
      HARALD_ENTITIES,
    );
    expect(verdict.kind).toBe('duplicate');
  });

  it('uses a 14-day window', () => {
    expect(CLAIM_WINDOW_DAYS).toBe(14);
  });
});

describe('claimGuard.check — contradiction (best-effort, prose-based)', () => {
  it('returns contradiction when the topic matches but the value differs', async () => {
    const guard = makeClaimGuard(
      memoryStore([
        row({
          topicKey: 'meta csam advertisements india|count',
          valueKey: '84',
          entities: ['meta', 'india'],
          questionExternalId: 'clima-1599',
        }),
      ]),
      nowFn,
    );
    const verdict = await guard.check(
      { topicKey: 'meta csam advertisements india|count', valueKey: '78' },
      ['meta', 'india'],
    );
    expect(verdict.kind).toBe('contradiction');
    if (verdict.kind === 'contradiction') {
      expect(verdict.existing.valueKey).toBe('84');
      expect(verdict.existing.questionExternalId).toBe('clima-1599');
    }
  });

  it('reports the newest of several differing values', async () => {
    const guard = makeClaimGuard(
      memoryStore([
        row({ topicKey: 'x|count', valueKey: '1', firstSeenAt: daysAgo(9), questionExternalId: 'old' }),
        row({ topicKey: 'x|count', valueKey: '2', firstSeenAt: daysAgo(2), questionExternalId: 'new' }),
      ]),
      nowFn,
    );
    const verdict = await guard.check({ topicKey: 'x|count', valueKey: '3' }, ['alpha', 'beta']);
    expect(verdict.kind).toBe('contradiction');
    if (verdict.kind === 'contradiction') {
      expect(verdict.existing.questionExternalId).toBe('new');
    }
  });
});

describe('claimGuard.check — the prose fallback', () => {
  it('falls back to topicKey equality when the cluster has no usable entities', async () => {
    const guard = makeClaimGuard(memoryStore([row({ entities: [] })]), nowFn);
    const verdict = await guard.check({ topicKey: 'king harald v|age at death', valueKey: '89' }, []);
    expect(verdict.kind).toBe('duplicate');
    expect(verdict.mode).toBe('topic-fallback');
  });

  it('falls back when the cluster has only one usable entity', async () => {
    const guard = makeClaimGuard(memoryStore([row()]), nowFn);
    // 'Norway' and 'norway' are the same entity, so this side has one.
    const verdict = await guard.check(
      { topicKey: 'king harald v|age at death', valueKey: '89' },
      ['Norway', 'norway '],
    );
    expect(verdict.mode).toBe('topic-fallback');
    expect(verdict.kind).toBe('duplicate');
  });

  it('in fallback, a drifted topicKey is NOT caught — the known weakness', async () => {
    const guard = makeClaimGuard(memoryStore([row({ entities: [] })]), nowFn);
    const verdict = await guard.check({ topicKey: 'harald|age when he died', valueKey: '89' }, []);
    expect(verdict.kind).toBe('new');
    expect(verdict.mode).toBe('topic-fallback');
  });

  it('compares a stored row with no entities on its topic key, even when the incoming claim has entities', async () => {
    // The migration window: rows written before the entities column existed
    // read back as []. Scoring them 0 would blind the guard to the whole
    // backlog for 14 days, so they are compared the old way.
    const guard = makeClaimGuard(memoryStore([row({ entities: [] })]), nowFn);
    const verdict = await guard.check(
      { topicKey: 'king harald v|age at death', valueKey: '89' },
      ['king harald', 'norway', 'oslo'],
    );
    expect(verdict.kind).toBe('duplicate');
    expect(verdict.mode).toBe('entities');
    expect(verdict.overlaps[0].basis).toBe('topic-fallback');
  });
});

describe('claimGuard.check — the entity rule never loses a prose catch', () => {
  it('still catches identical topicKey + valueKey when the entity sets have drifted apart', async () => {
    // Both rules are live as a disjunction, so the change cannot let through
    // a duplicate the old rule caught. Here the prose is identical and the
    // clusters share nothing — 0.0 overlap, and still a duplicate.
    const guard = makeClaimGuard(
      memoryStore([row({ entities: ['king harald', 'norway'] })]),
      nowFn,
    );
    const verdict = await guard.check(
      { topicKey: 'king harald v|age at death', valueKey: '89' },
      ['oslo cathedral', 'crown princess'],
    );
    expect(verdict.kind).toBe('duplicate');
    if (verdict.kind === 'duplicate') {
      expect(verdict.overlap).toBe(0);
      expect(verdict.mode).toBe('entities');
      expect(verdict.basis).toBe('topic-fallback');
    }
  });
});

describe('claimGuard.record', () => {
  it('persists a row that a later check finds as a duplicate', async () => {
    const store = memoryStore();
    const guard = makeClaimGuard(store, nowFn);
    await guard.record({ topicKey: 't|a', valueKey: 'v' }, ['Alpha', 'beta '], 'us', 'usnws-0001', 42);

    expect(store.rows).toHaveLength(1);
    expect(store.rows[0].lane).toBe('us');
    expect(store.rows[0].firstSeenAt).toEqual(NOW);
    // Normalised on the way in, so the stored set is directly comparable.
    expect(store.rows[0].entities).toEqual(['alpha', 'beta']);

    const verdict = await guard.check({ topicKey: 't|a', valueKey: 'v' }, ['alpha', 'beta']);
    expect(verdict.kind).toBe('duplicate');
  });

  it('records a drifted re-phrasing as a duplicate on the next check', async () => {
    const store = memoryStore();
    const guard = makeClaimGuard(store, nowFn);
    await guard.record(
      { topicKey: 'houthi capture mokha port yemen|distance from bab al-mandab strait', valueKey: '75' },
      ['houthi', 'mokha', 'bab al-mandab', 'yemen'],
      'iran',
      'wiran-1667',
      7,
    );

    const verdict = await guard.check(
      { topicKey: 'houthi seizure mokha port yemen|distance from bab al-mandab strait after capture', valueKey: '75' },
      ['houthi', 'mokha', 'bab al-mandab', 'red sea'],
    );
    expect(verdict.kind).toBe('duplicate');
  });
});
