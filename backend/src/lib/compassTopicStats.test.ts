import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery, mockGet, mockSet } = vi.hoisted(() => ({
  mockQuery: vi.fn(),
  mockGet: vi.fn(),
  mockSet: vi.fn(),
}));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));
vi.mock('./cache.js', () => ({ cache: { get: mockGet, set: mockSet, del: vi.fn() } }));
vi.mock('./supabase.js', () => ({
  supabaseAnon: {}, supabaseService: {}, adminRpc: vi.fn(), createUserClient: vi.fn(),
}));

import { getTopicAnswerStats, MIN_STATS_SAMPLE } from './compassService.js';

beforeEach(() => {
  mockQuery.mockReset();
  mockGet.mockReset().mockResolvedValue(null);
  mockSet.mockReset().mockResolvedValue(undefined);
});

const sql = () => mockQuery.mock.calls[0][0] as string;

/**
 * These guard the line a voter sees AFTER they pick an option. Every one of
 * them protects a claim the UI makes out loud to a user about real officials,
 * so the failure mode is not a broken page — it is a true-looking sentence that
 * is false.
 */
describe('getTopicAnswerStats — the counts behind the after-answer line', () => {
  it('counts only rungs 1–5, and filters before picking each persons latest row', () => {
    mockQuery.mockResolvedValue({ rows: [] });
    return getTopicAnswerStats().then(() => {
      const q = sql();
      expect(q).toContain('pa.value BETWEEN 1 AND 5');
      // 🔴 ORDER MATTERS. The WHERE has to sit inside `latest`, ahead of
      // DISTINCT ON — a value-0 row written after a real answer would otherwise
      // win the DISTINCT and drop that official out of their bucket. Asserting
      // the filter exists somewhere would pass on the broken arrangement.
      const latestStart = q.indexOf('latest AS (');
      const distinctOn = q.indexOf('DISTINCT ON (pa.politician_id');
      const filter = q.indexOf('pa.value BETWEEN 1 AND 5');
      expect(latestStart).toBeGreaterThan(-1);
      expect(filter).toBeGreaterThan(distinctOn);
      expect(q.indexOf('buckets AS (')).toBeGreaterThan(filter);
    });
  });

  it('dedupes a politician answered under two revisions of the same topic', () => {
    mockQuery.mockResolvedValue({ rows: [] });
    return getTopicAnswerStats().then(() => {
      expect(sql()).toContain('DISTINCT ON (pa.politician_id, pa.topic_id)');
    });
  });

  // The identity map is the overwhelming majority — 72 of the 74 revisions that
  // carry a rung_map at all. Testing for `IS NOT NULL` alone would exclude
  // nearly every revised topic and silently empty the feature.
  it('treats only a NON-identity rung_map as a moved ladder', () => {
    mockQuery.mockResolvedValue({ rows: [] });
    return getTopicAnswerStats().then(() => {
      const q = sql();
      expect(q).toContain('rung_map IS NOT NULL');
      expect(q).toContain(`rung_map <> '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb`);
    });
  });

  // 🔴 THE CLAIM THIS PROTECTS. byValue is what the client divides to say "you
  // are with N of M". On a topic whose ladder moved, the values in those
  // buckets do not all mean the same position, so there is no honest share to
  // state. Withholding the field makes the sentence impossible to build rather
  // than merely wrong.
  it('withholds byValue entirely when the ladder moved, but keeps the count', async () => {
    mockQuery.mockResolvedValue({
      rows: [
        { topic_id: 't-moved', total: 300, comparable: false, by_value: null },
        { topic_id: 't-ok', total: 120, comparable: true, by_value: { '1': 20, '5': 100 } },
      ],
    });
    const stats = await getTopicAnswerStats();

    const moved = stats.find(s => s.topicId === 't-moved')!;
    expect(moved.total).toBe(300);
    expect('byValue' in moved).toBe(false);

    expect(stats.find(s => s.topicId === 't-ok')!.byValue).toEqual({ '1': 20, '5': 100 });
  });

  // comparable=true with a by_value the database did not produce would publish
  // `byValue: null` and crash whatever divides by it.
  it('withholds byValue when comparable but the aggregate came back null', async () => {
    mockQuery.mockResolvedValue({
      rows: [{ topic_id: 't', total: 5, comparable: true, by_value: null }],
    });
    expect('byValue' in (await getTopicAnswerStats())[0]).toBe(false);
  });

  it('serves a cached payload without touching the database', async () => {
    mockGet.mockResolvedValue([{ topicId: 'cached', total: 7 }]);
    expect(await getTopicAnswerStats()).toEqual([{ topicId: 'cached', total: 7 }]);
    expect(mockQuery).not.toHaveBeenCalled();
  });

  it('caches what it computed, with a ttl', async () => {
    mockQuery.mockResolvedValue({ rows: [{ topic_id: 't', total: 1, comparable: true, by_value: {} }] });
    await getTopicAnswerStats();
    expect(mockSet).toHaveBeenCalledWith(expect.stringContaining('topic-answer-stats'), expect.any(Array), 3600);
  });

  // The floor is a product decision measured against the corpus: at 25 it is 43
  // of the 60 promoted topics that can show the line, and 11 of the remainder
  // have no official answers at all. Pinning it here means moving it is a
  // deliberate edit rather than a drift.
  it('publishes the sample floor it was measured at', () => {
    expect(MIN_STATS_SAMPLE).toBe(25);
  });
});
