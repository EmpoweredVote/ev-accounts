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

/** The JSON array of votes inside a statement's params, found by shape, not by position. */
const voteSet = (call: { params: unknown[] }): any[] =>
  JSON.parse(call.params.find((p) => typeof p === 'string' && p.startsWith('[{')) as string);

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
      if (/INTO essentials.legislative_roll_calls/.test(c.text)) {
        expect(c.text).toMatch(/ON CONFLICT \(city_scope, external_vote_id\)/);
      } else if (/INTO essentials.legislative_votes/.test(c.text)) {
        expect(c.text).toMatch(/ON CONFLICT \(politician_id, bill_id, session_id, external_vote_id\)/);
      } else if (/INSERT/i.test(c.text)) {
        throw new Error(`unexpected INSERT: ${c.text}`);
      }
    }
    expect(db.calls.some((c: any) => /legislative_votes/.test(c.text))).toBe(true);
  });

  it('records the vote document as the source of the confirmation', async () => {
    const db = recordingDb();
    await writeConfirmed(db, 'place:1', rc, ok, 'bill1', '2026-10-07', 'doc1');
    const votes = db.calls.find((c: any) => /INTO essentials.legislative_votes/.test(c.text));
    expect(votes.text).toMatch(/onboard-minutes/);
    expect(JSON.stringify(votes.params)).toContain('doc1');
    expect(voteSet(votes).map((v: any) => v.workedOut)).toEqual([false, true]);
  });
});

describe('writeConfirmed: replacing and promoting', () => {
  it('deletes votes on the roll call that are not in the new set', async () => {
    const db = recordingDb();
    await writeConfirmed(db, 'place:1', rc, ok, 'bill1', '2026-10-07', 'doc1');
    const del = db.calls.find((c: any) => /DELETE FROM essentials.legislative_votes/.test(c.text));
    expect(del).toBeTruthy();
    expect(del.text).toMatch(/roll_call_id = \$1/);
    expect(del.text).toMatch(/<> ALL\(\$2/);
    expect(del.params[0]).toBe('row1');
    expect(del.params[1]).toEqual(['p1', 'p2']);
  });

  it('clears every vote when the new set is empty', async () => {
    const db = recordingDb();
    await writeConfirmed(db, 'place:1', rc, { ...ok, votes: [] }, 'bill1', '2026-10-07', 'doc1');
    const del = db.calls.find((c: any) => /DELETE FROM essentials.legislative_votes/.test(c.text));
    expect(del.params[1]).toEqual([]);
  });

  // A roll call table that behaves like the unique key (city_scope, external_vote_id).
  function rollCallTable() {
    const rows = new Map<string, { state: string; bill: string }>();
    return {
      rows,
      async query(text: string, params: unknown[] = []) {
        if (/INTO essentials.legislative_roll_calls/.test(text)) {
          const key = `${params[0]}|${params[2]}`;
          const confirming = /'confirmed'/.test(text.split('VALUES')[1].split('ON CONFLICT')[0]);
          const have = rows.get(key);
          if (confirming) rows.set(key, { state: 'confirmed', bill: params[1] as string });
          else if (!have) rows.set(key, { state: 'pending_minutes', bill: params[1] as string });
          return { rows: [{ id: key }] };
        }
        return { rows: [{ id: 'x' }] };
      },
    } as any;
  }
  const finalItem: FeedItem = {
    feedId: 7, type: 'Resolution', number: '2026-09', itemNumber: 'Res 2026-09', title: 't', synopsis: null,
    status: 'Adopted', pageUrl: 'https://x/7',
    final: { date: '2026-10-07', outcome: 'passed', tally: { yes: 2, no: 1, abstain: 0 } },
  };

  it('promotes the pending Final passage row in place: no second row', async () => {
    const db = rollCallTable();
    await writeFeed(db, 'place:1', [finalItem]);
    expect(db.rows.size).toBe(1);
    await writeConfirmed(db, 'place:1', rc, ok, 'row1', '2026-10-07', 'doc1');
    expect(db.rows.size).toBe(1);
    expect([...db.rows.values()][0].state).toBe('confirmed');
    // a later feed read must not demote it
    await writeFeed(db, 'place:1', [finalItem]);
    expect([...db.rows.values()][0].state).toBe('confirmed');
  });

  it('an amendment roll call on the same bill leaves the pending row alone', async () => {
    const db = rollCallTable();
    await writeFeed(db, 'place:1', [finalItem]);
    await writeConfirmed(db, 'place:1', { ...rc, question: 'Amendment 03' }, ok, 'row1', '2026-10-07', 'doc1');
    expect(db.rows.size).toBe(2);
    expect([...db.rows.values()].map((r) => r.state).sort()).toEqual(['confirmed', 'pending_minutes']);
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
    expect(pending[0].text).toMatch(/IS DISTINCT FROM/);
  });
});

describe('recordException', () => {
  it('stores {} when there is no detail', async () => {
    const db = recordingDb();
    await recordException(db, 'place:1', 'run1', 'unknown_name', 'subj', undefined);
    expect(db.calls[0].params[4]).toBe('{}');
  });

  it('upserts on city, cause and subject and reopens only when detail changed', async () => {
    const db = recordingDb();
    await recordException(db, 'place:1', 'run1', 'minutes_disagree', 'subj', { a: 1 });
    const c = db.calls[0];
    expect(c.text).toMatch(/ON CONFLICT \(city_scope, cause, subject\)/);
    expect(c.text).toMatch(/IS DISTINCT FROM/);
    expect(c.params).toEqual(['place:1', 'run1', 'minutes_disagree', 'subj', '{"a":1}']);
  });

  it('dates an exception by opened_at: set on insert, reset only when a resolved row is reopened', async () => {
    const db = recordingDb();
    await recordException(db, 'place:1', 'run1', 'unknown_name', 'subj', { a: 1 });
    const t = db.calls[0].text;
    expect(t).toMatch(/\(id, city_scope, run_id, cause, subject, detail, opened_at\)/);
    expect(t).toMatch(/\$5::jsonb, now\(\)\)/);
    // Reopening a resolved row restarts its age; a still-open row keeps its date.
    expect(t).toMatch(/opened_at = CASE WHEN e\.detail IS DISTINCT FROM EXCLUDED\.detail AND e\.status = 'resolved'\s+THEN now\(\) ELSE e\.opened_at END/);
    expect(t).toMatch(/updated_at = now\(\)/);
  });

  it('accepts every known cause and rejects others', async () => {
    const db = recordingDb();
    for (const cause of EXCEPTION_CAUSES) await recordException(db, 'place:1', 'r', cause, 's', 'd');
    await expect(recordException(db, 'place:1', 'r', 'nope' as any, 's', 'd')).rejects.toThrow();
  });
});
