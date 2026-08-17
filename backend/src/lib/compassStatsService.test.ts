import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { getStanceBreakdown } from './compassStatsService.js';

interface MockData {
  stanceRows?: unknown[];
  userCounts?: unknown[];
  politicianCounts?: unknown[];
  userTotals?: unknown[];
  politicianTotals?: unknown[];
}

function mockRows(data: MockData) {
  mockQuery.mockImplementation(async (sql: string) => {
    if (sql.includes('inform.compass_stances')) return { rows: data.stanceRows ?? [] };
    const grouped = sql.includes('GROUP BY topic_id, value');
    if (sql.includes('inform.compass_responses')) {
      return { rows: (grouped ? data.userCounts : data.userTotals) ?? [] };
    }
    if (sql.includes('inform.politician_answers')) {
      return { rows: (grouped ? data.politicianCounts : data.politicianTotals) ?? [] };
    }
    return { rows: [] };
  });
}

const topicA = { topic_id: 't1', title: 'Housing', short_title: 'Housing', is_live: true };
const stanceRowsA = [1, 2, 3, 4, 5].map((v) => ({
  ...topicA,
  stance_id: `st${v}`,
  stance_value: v,
  stance_text: `Stance ${v}`,
}));

describe('getStanceBreakdown', () => {
  // Braced body on purpose: mockReset() returns the mock (a function), and a
  // function returned from beforeEach is invoked by vitest as teardown.
  beforeEach(() => {
    mockQuery.mockReset();
  });

  it('filters soft-deleted rows for users but not politicians (no such column)', async () => {
    mockRows({ stanceRows: stanceRowsA });
    await getStanceBreakdown();
    const sqls = mockQuery.mock.calls.map((c) => c[0] as string);
    for (const sql of sqls.filter((s) => s.includes('inform.compass_responses'))) {
      expect(sql).toContain('deleted_at IS NULL');
    }
    // politician_answers has no deleted_at — referencing it would throw at runtime.
    for (const sql of sqls.filter((s) => s.includes('inform.politician_answers'))) {
      expect(sql).not.toContain('deleted_at');
    }
  });

  it('maps both cohorts onto stance buckets and totals per topic', async () => {
    mockRows({
      stanceRows: stanceRowsA,
      userCounts: [
        { topic_id: 't1', value: 1, n: 5, write_ins: 0 },
        { topic_id: 't1', value: 3, n: 2, write_ins: 0 },
      ],
      politicianCounts: [
        { topic_id: 't1', value: 1, n: 100, write_ins: 3 },
        { topic_id: 't1', value: 5, n: 40, write_ins: 0 },
      ],
      userTotals: [{ responses: 7, respondents: 4 }],
      politicianTotals: [{ responses: 140, respondents: 90 }],
    });
    const out = await getStanceBreakdown();
    expect(out.totals).toEqual({
      userResponses: 7,
      users: 4,
      politicianAnswers: 140,
      politicians: 90,
    });
    const [t] = out.topics;
    expect(t.userResponses).toBe(7);
    expect(t.politicianAnswers).toBe(140);
    expect(t.politicianWriteIns).toBe(3);
    expect(t.stances.map((s) => s.users)).toEqual([5, 0, 2, 0, 0]);
    expect(t.stances.map((s) => s.politicians)).toEqual([100, 0, 0, 0, 40]);
    expect(t.betweens).toEqual([]);
  });

  it('routes half-step values to betweens instead of rounding into a stance', async () => {
    mockRows({
      stanceRows: stanceRowsA,
      userCounts: [
        { topic_id: 't1', value: 2.5, n: 1, write_ins: 1 },
        { topic_id: 't1', value: 0.5, n: 2, write_ins: 2 },
        { topic_id: 't1', value: 2, n: 3, write_ins: 0 },
      ],
      userTotals: [{ responses: 6, respondents: 3 }],
    });
    const out = await getStanceBreakdown();
    const [t] = out.topics;
    expect(t.betweens).toEqual([
      { value: 0.5, users: 2, politicians: 0 },
      { value: 2.5, users: 1, politicians: 0 },
    ]);
    expect(t.stances.find((s) => s.value === 2)?.users).toBe(3);
    expect(t.stances.find((s) => s.value === 3)?.users).toBe(0);
    expect(t.userResponses).toBe(6);
    expect(t.userWriteIns).toBe(3);
  });

  it('includes topics with no responses and sorts by combined count desc', async () => {
    const topicB = { topic_id: 't2', title: 'Zoning', short_title: null, is_live: false };
    mockRows({
      stanceRows: [
        ...stanceRowsA,
        ...[1, 2, 3, 4, 5].map((v) => ({
          ...topicB,
          stance_id: `zt${v}`,
          stance_value: v,
          stance_text: `S${v}`,
        })),
      ],
      politicianCounts: [{ topic_id: 't2', value: 4, n: 1, write_ins: 0 }],
      politicianTotals: [{ responses: 1, respondents: 1 }],
    });
    const out = await getStanceBreakdown();
    expect(out.topics.map((t) => t.topicId)).toEqual(['t2', 't1']);
    expect(out.topics[1].userResponses).toBe(0);
    expect(out.topics[1].politicianAnswers).toBe(0);
    expect(out.topics[1].stances).toHaveLength(5);
  });

  it('ignores counts for topics that no longer exist', async () => {
    mockRows({
      stanceRows: stanceRowsA,
      userCounts: [{ topic_id: 'ghost', value: 2, n: 9, write_ins: 0 }],
      politicianCounts: [{ topic_id: 'ghost', value: 3, n: 12, write_ins: 0 }],
      userTotals: [{ responses: 9, respondents: 1 }],
      politicianTotals: [{ responses: 12, respondents: 12 }],
    });
    const out = await getStanceBreakdown();
    expect(out.topics).toHaveLength(1);
    expect(out.topics[0].userResponses).toBe(0);
    expect(out.topics[0].politicianAnswers).toBe(0);
  });
});
