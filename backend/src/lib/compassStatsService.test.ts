import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { getStanceBreakdown } from './compassStatsService.js';

function mockRows(stanceRows: unknown[], countRows: unknown[], totalsRows: unknown[]) {
  mockQuery.mockImplementation(async (sql: string) => {
    if (sql.includes('inform.compass_stances')) return { rows: stanceRows };
    if (sql.includes('GROUP BY topic_id, value')) return { rows: countRows };
    return { rows: totalsRows };
  });
}

const topicA = { topic_id: 't1', title: 'Housing', short_title: 'Housing', is_live: true };
const stanceRowsA = [1, 2, 3, 4, 5].map((v) => ({
  ...topicA,
  stance_id: `t1-s${v}`,
  stance_value: v,
  stance_text: `Stance ${v}`,
}));

describe('getStanceBreakdown', () => {
  // Braced body on purpose: mockReset() returns the mock (a function), and a
  // function returned from beforeEach is invoked by vitest as teardown.
  beforeEach(() => {
    mockQuery.mockReset();
  });

  it('only counts non-deleted responses', async () => {
    mockRows(stanceRowsA, [], [{ responses: 0, users: 0 }]);
    await getStanceBreakdown();
    const sqls = mockQuery.mock.calls.map((c) => c[0] as string);
    // Soft delete: every aggregate over compass_responses must exclude deleted rows.
    for (const sql of sqls.filter((s) => s.includes('inform.compass_responses'))) {
      expect(sql).toContain('deleted_at IS NULL');
    }
  });

  it('carries the stance id through to each bucket', async () => {
    mockRows(stanceRowsA, [], [{ responses: 0, users: 0 }]);
    const out = await getStanceBreakdown();
    expect(out.topics[0].stances.map((s) => s.id)).toEqual([
      't1-s1',
      't1-s2',
      't1-s3',
      't1-s4',
      't1-s5',
    ]);
  });

  it('skips stance rows the LEFT JOIN left null', async () => {
    mockRows(
      [{ ...topicA, stance_id: null, stance_value: null, stance_text: null }],
      [],
      [{ responses: 0, users: 0 }]
    );
    const out = await getStanceBreakdown();
    expect(out.topics).toHaveLength(1);
    expect(out.topics[0].stances).toEqual([]);
  });

  it('maps integer values onto stance buckets and totals per topic', async () => {
    mockRows(
      stanceRowsA,
      [
        { topic_id: 't1', value: 1, n: 5, write_ins: 0 },
        { topic_id: 't1', value: 3, n: 2, write_ins: 0 },
      ],
      [{ responses: 7, users: 4 }]
    );
    const out = await getStanceBreakdown();
    expect(out.totals).toEqual({ responses: 7, users: 4 });
    const [t] = out.topics;
    expect(t.totalResponses).toBe(7);
    expect(t.stances.map((s) => s.count)).toEqual([5, 0, 2, 0, 0]);
    expect(t.betweens).toEqual([]);
  });

  it('routes half-step values to betweens instead of rounding into a stance', async () => {
    mockRows(
      stanceRowsA,
      [
        { topic_id: 't1', value: 2.5, n: 1, write_ins: 1 },
        { topic_id: 't1', value: 0.5, n: 2, write_ins: 2 },
        { topic_id: 't1', value: 2, n: 3, write_ins: 0 },
      ],
      [{ responses: 6, users: 3 }]
    );
    const out = await getStanceBreakdown();
    const [t] = out.topics;
    expect(t.betweens).toEqual([
      { value: 0.5, count: 2 },
      { value: 2.5, count: 1 },
    ]);
    expect(t.stances.find((s) => s.value === 2)?.count).toBe(3);
    expect(t.stances.find((s) => s.value === 3)?.count).toBe(0);
    expect(t.totalResponses).toBe(6);
    expect(t.writeInCount).toBe(3);
  });

  it('includes topics with no responses and sorts by response count desc', async () => {
    const topicB = { topic_id: 't2', title: 'Zoning', short_title: null, is_live: false };
    mockRows(
      [
        ...stanceRowsA,
        ...[1, 2, 3, 4, 5].map((v) => ({
          ...topicB,
          stance_id: `t2-s${v}`,
          stance_value: v,
          stance_text: `S${v}`,
        })),
      ],
      [{ topic_id: 't2', value: 4, n: 1, write_ins: 0 }],
      [{ responses: 1, users: 1 }]
    );
    const out = await getStanceBreakdown();
    expect(out.topics.map((t) => t.topicId)).toEqual(['t2', 't1']);
    expect(out.topics[1].totalResponses).toBe(0);
    expect(out.topics[1].stances).toHaveLength(5);
  });

  it('ignores counts for topics that no longer exist', async () => {
    mockRows(
      stanceRowsA,
      [{ topic_id: 'ghost', value: 2, n: 9, write_ins: 0 }],
      [{ responses: 9, users: 1 }]
    );
    const out = await getStanceBreakdown();
    expect(out.topics).toHaveLength(1);
    expect(out.topics[0].totalResponses).toBe(0);
  });
});
