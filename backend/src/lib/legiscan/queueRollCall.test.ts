import { describe, it, expect, vi } from 'vitest';

// importer.ts imports the pool; the roll-call queueing never touches it.
const queryMock = vi.hoisted(() => vi.fn(async () => ({ rows: [] })));
vi.mock('../db.js', () => ({ pool: { query: queryMock } }));
vi.mock('./client.js', () => ({ legiscanQuery: vi.fn() }));

import { queueRollCall, VoteBuffer, MAX_ROWS_PER_STATEMENT } from './importer.js';

const rc = {
  roll_call_id: 77, date: '2026-02-26', desc: 'Third reading', passed: 1, yea: 50, nay: 20,
  votes: [
    { people_id: 1, vote_text: 'Yea' },
    { people_id: 2, vote_text: 'Nay' },
    { people_id: 3, vote_text: 'Yea' }, // not one of ours
  ],
};

describe('queueRollCall', () => {
  it('queues only legislators we have a bridge for', () => {
    const buffer = new VoteBuffer();
    const bridge = new Map([[1, 'pol-1'], [2, 'pol-2']]);
    expect(queueRollCall(rc, 'bill-1', 'sess-1', bridge, buffer, false)).toBe(2);
    expect(buffer.full).toBe(false);
  });
  it('counts but does not queue in a dry run', async () => {
    const buffer = new VoteBuffer(1);
    const bridge = new Map([[1, 'pol-1']]);
    expect(queueRollCall(rc, 'bill-1', 'sess-1', bridge, buffer, true)).toBe(1);
    expect(buffer.full).toBe(false);
  });
  it('does not queue the same vote twice', () => {
    const buffer = new VoteBuffer(2);
    const bridge = new Map([[1, 'pol-1']]);
    queueRollCall(rc, 'bill-1', 'sess-1', bridge, buffer, false);
    queueRollCall(rc, 'bill-1', 'sess-1', bridge, buffer, false);
    expect(buffer.full).toBe(false); // still one row
  });
});

describe('VoteBuffer.flush', () => {
  it('never sends more than 65,535 values in one statement', async () => {
    queryMock.mockClear();
    const buffer = new VoteBuffer();
    const many = Array.from({ length: 12_000 }, (_, i) => [
      `pol-${i}`, 'bill-1', 'sess-1', 'legiscan-1', 'q', 'yea', '2026-01-01', 'passed', 1, 0,
    ] as never);
    buffer.add(many);
    await buffer.flush();
    expect(queryMock).toHaveBeenCalledTimes(Math.ceil(12_000 / MAX_ROWS_PER_STATEMENT));
    for (const call of queryMock.mock.calls) {
      expect((call as unknown as [string, unknown[]])[1].length).toBeLessThanOrEqual(65_535);
    }
    expect(buffer.written).toBe(12_000);
  });
});
