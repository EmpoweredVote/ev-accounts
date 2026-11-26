import { describe, expect, it } from 'vitest';
import { recordException, writeConfirmed, writeFeed } from './write.js';
import { EXCEPTION_CAUSES } from './types.js';
import type { FeedItem, MinutesRollCall } from './types.js';

function recordingDb() {
  const calls: { text: string; params: unknown[] }[] = [];
  return {
    calls,
    async query(text: string, params: unknown[] = []) {
      calls.push({ text, params });
      return { rows: [{ id: 'row1' }], rowCount: 1 };
    },
  } as any;
}

const rc: MinutesRollCall = {
  index: 2,
  itemNumber: 'Res 2026-09',
  question: 'Final passage',
  tally: { yes: 2, no: 1, abstain: 0 },
  named: [],
  inlineNotes: [],
  outcome: 'passed',
  sentence: 's',
};
const ok = {
  ok: true as const,
  feedDisagreement: null,
  votes: [
    { politicianId: 'p1', nameAsPrinted: 'A', position: 'yea' as const, workedOut: false },
    { politicianId: 'p2', nameAsPrinted: 'B', position: 'nay' as const, workedOut: true },
  ],
};

describe('writeConfirmed', () => {
  it('is idempotent: every INSERT carries ON CONFLICT', async () => {
    const db = recordingDb();
    await writeConfirmed(db, 'place:1', rc, ok, 'bill1', '2026-10-07', 'doc1');
    await writeConfirmed(db, 'place:1', rc, ok, 'bill1', '2026-10-07', 'doc1');
    const half = db.calls.length / 2;
    expect(half).toBeGreaterThan(0);
    expect(db.calls.slice(half).map((c: any) => c.text)).toEqual(db.calls.slice(0, half).map((c: any) => c.text));
    for (const c of db.calls.slice(half)) {
      if (/INSERT/i.test(c.text)) expect(c.text).toMatch(/ON CONFLICT/i);
    }
    expect(db.calls.some((c: any) => /legislative_votes/.test(c.text))).toBe(true);
  });

  it('records the vote document as the source of the confirmation', async () => {
    const db = recordingDb();
    await writeConfirmed(db, 'place:1', rc, ok, 'bill1', '2026-10-07', 'doc1');
    const votes = db.calls.find((c: any) => /INTO essentials.legislative_votes/.test(c.text));
    expect(votes.text).toMatch(/onboard-minutes/);
    expect(JSON.stringify(votes.params)).toContain('doc1');
    expect(JSON.parse(votes.params[9]).map((v: any) => v.workedOut)).toEqual([false, true]);
  });
});

describe('writeFeed', () => {
  const item = (over: Partial<FeedItem>): FeedItem => ({
    feedId: 7, type: 'Resolution', number: '2026-09', itemNumber: 'Res 2026-09', title: 't', synopsis: null,
    status: 'Adopted', final: null, pageUrl: 'https://x/7', ...over,
  });

  it('upserts sessions and bills, and a pending roll call only for finals', async () => {
    const db = recordingDb();
    const res = await writeFeed(db, 'place:1', [
      item({ feedId: 7, final: { date: '2026-01-02', outcome: 'passed', tally: { yes: 1, no: 0, abstain: 0 } } }),
      item({ feedId: 8, number: '2026-10', itemNumber: 'Res 2026-10' }),
    ]);
    expect(res).toEqual({ bills: 2, pending: 1 });
    expect(JSON.stringify(db.calls.map((c: any) => c.params))).toContain('onboard-2026');
    expect(JSON.stringify(db.calls.map((c: any) => c.params))).toContain('onboard-7');
    for (const c of db.calls) if (/INSERT/i.test(c.text)) expect(c.text).toMatch(/ON CONFLICT|WHERE NOT EXISTS/i);
    const pending = db.calls.filter((c: any) => /legislative_roll_calls/.test(c.text));
    expect(pending).toHaveLength(1);
    expect(pending[0].text).toMatch(/pending_minutes/);
    expect(pending[0].text).toMatch(/state = 'pending_minutes'/);
  });
});

describe('recordException', () => {
  it('upserts on city, cause and subject and reopens only when detail changed', async () => {
    const db = recordingDb();
    await recordException(db, 'place:1', 'run1', 'minutes_disagree', 'subj', { a: 1 });
    const c = db.calls[0];
    expect(c.text).toMatch(/ON CONFLICT \(city_scope, cause, subject\)/);
    expect(c.text).toMatch(/IS DISTINCT FROM/);
    expect(c.params).toEqual(['place:1', 'run1', 'minutes_disagree', 'subj', '{"a":1}']);
  });

  it('accepts every known cause and rejects others', async () => {
    const db = recordingDb();
    for (const cause of EXCEPTION_CAUSES) await recordException(db, 'place:1', 'r', cause, 's', 'd');
    await expect(recordException(db, 'place:1', 'r', 'nope' as any, 's', 'd')).rejects.toThrow();
  });
});
