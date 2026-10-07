import { describe, it, expect, vi } from 'vitest';

// importer.ts imports the pool; the roll-call queueing never touches it.
vi.mock('../db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('./client.js', () => ({ legiscanQuery: vi.fn() }));

import { queueRollCall, VoteBuffer } from './importer.js';

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
