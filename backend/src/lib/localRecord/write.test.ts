import { describe, expect, it } from 'vitest';
import { recordException, writeConfirmed, writeFeed, writeSponsorships } from './write.js';
import type { Sponsorship } from './sponsorships.js';
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
    expect(votes.params).toContain('onboard-minutes');
    expect(JSON.stringify(votes.params)).toContain('doc1');
    expect(voteSet(votes).map((v: any) => v.workedOut)).toEqual([false, true]);
  });
});

describe('writeConfirmed: source', () => {
  it('writes the given source on the vote rows; the default is onboard-minutes', async () => {
    const db = recordingDb();
    await writeConfirmed(db, 'place:1', rc, ok, 'bill1', '2026-10-07', 'doc1', 'owner-check');
    const votes = db.calls.find((c: any) => /INTO essentials.legislative_votes/.test(c.text));
    expect(votes.params).toContain('owner-check');
    expect(votes.params).not.toContain('onboard-minutes');
  });
});

describe('writeConfirmed: source on conflict', () => {
  it('a later confirmation replaces the source, so minutes take over from an owner check', async () => {
    const db = recordingDb();
    await writeConfirmed(db, 'place:1', rc, ok, 'bill1', '2026-10-07', 'doc1');
    const votes = db.calls.find((c: any) => /INTO essentials.legislative_votes/.test(c.text));
    expect(votes.text).toMatch(/DO UPDATE SET[\s\S]*source = EXCLUDED\.source/);
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
    status: 'Adopted', firstActionDate: null, pageUrl: 'https://x/7',
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
    status: 'Adopted', final: null, firstActionDate: null, pageUrl: 'https://x/7', ...over,
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

describe('writeSponsorships', () => {
  const sp = (over: Partial<Sponsorship> = {}): Sponsorship => ({
    itemNumber: 'Ord 2025-41',
    label: null,
    politicianId: 'p1',
    role: 'sponsor',
    nameAsPrinted: 'Smith',
    sentence: 'Sponsored by Smith.',
    sourceKind: 'legislation_feed',
    sourceDocumentId: 'doc1',
    ...over,
  });

  /** Routes by statement: bill lookup, stored-sponsor read, everything else answers with one row. */
  /** `stored` entries are "p1" (role sponsor) or "p1:cosponsor"; `held` are subjects with an open sponsor_disagrees. */
  function sponsorDb(opts: { bills?: Record<string, string>; stored?: Record<string, string[]>; dupes?: string[]; held?: string[] } = {}) {
    const bills = opts.bills ?? { 'Ord 2025-41': 'bill1' };
    const dupes = opts.dupes ?? [];
    const stored = opts.stored ?? {};
    const held = opts.held ?? [];
    const calls: { text: string; params: unknown[] }[] = [];
    return {
      calls,
      async query(text: string, params: unknown[] = []) {
        calls.push({ text, params });
        if (/FROM essentials.legislative_bills/.test(text)) {
          if (dupes.includes(params[1] as string)) return { rows: [{ id: 'a' }, { id: 'b' }], rowCount: 2 };
          const id = bills[params[1] as string];
          return { rows: id ? [{ id }] : [], rowCount: id ? 1 : 0 };
        }
        if (/FROM essentials.legislative_sponsorships/.test(text)) {
          const rows = (stored[params[0] as string] ?? []).map((x) => {
            const [politician_id, role = 'sponsor'] = x.split(':');
            return { politician_id, role };
          });
          return { rows, rowCount: rows.length };
        }
        if (/SELECT subject FROM essentials.local_record_exceptions/.test(text)) {
          return { rows: held.map((subject) => ({ subject })), rowCount: held.length };
        }
        return { rows: [{ id: 'row1' }], rowCount: 1 };
      },
    } as any;
  }
  const upserts = (db: any) => db.calls.filter((c: any) => /INSERT INTO essentials.legislative_sponsorships/.test(c.text));
  const exceptions = (db: any) =>
    db.calls.filter((c: any) => /INSERT INTO essentials.local_record_exceptions/.test(c.text)).map((c: any) => ({ cause: c.params[2], subject: c.params[3], detail: JSON.parse(c.params[4]) }));

  it('inserts one row per member and amendment', async () => {
    const db = sponsorDb();
    const rows = [
      sp(),
      sp({ politicianId: 'p2', role: 'cosponsor', nameAsPrinted: 'Jones' }),
      sp({ label: 'Amendment 01', politicianId: 'p2', role: 'sponsor' }),
    ];
    const r = await writeSponsorships(db, 'place:1', 'run1', rows, { subjectsRead: new Set() });
    expect(r).toEqual({ written: 3, unknownItems: 0, dropped: 0 });
    expect(upserts(db)).toHaveLength(3);
    expect(upserts(db).map((c: any) => c.params)).toContainEqual(
      expect.arrayContaining(['place:1', 'bill1', 'Amendment 01', 'p2', 'sponsor', 'doc1']),
    );
  });

  it('upserts the same row twice without a duplicate', async () => {
    const db = sponsorDb();
    await writeSponsorships(db, 'place:1', 'run1', [sp()], { subjectsRead: new Set() });
    await writeSponsorships(db, 'place:1', 'run1', [sp()], { subjectsRead: new Set() });
    const u = upserts(db);
    expect(u).toHaveLength(2);
    expect(u[0].text).toBe(u[1].text);
    expect(u[0].text).toMatch(/ON CONFLICT \(bill_id, coalesce\(amendment_label, ''\), politician_id\) DO UPDATE/);
    expect(u[0].text).toMatch(/updated_at = now\(\)/);
    expect(u[0].text).toMatch(/sentence = EXCLUDED\.sentence/);
  });

  it('raises unknown_item when the bill is not stored', async () => {
    const db = sponsorDb({ bills: {} });
    const r = await writeSponsorships(db, 'place:1', 'run1', [sp(), sp({ politicianId: 'p2' })], { subjectsRead: new Set() });
    expect(r).toEqual({ written: 0, unknownItems: 1, dropped: 2 });
    expect(upserts(db)).toHaveLength(0);
    expect(exceptions(db)).toEqual([expect.objectContaining({ cause: 'unknown_item', subject: 'Ord 2025-41' })]);
  });

  const disagrees = (stored: string[], read: string[]) => ({
    cause: 'sponsor_disagrees', subject: 'Ord 2025-41', detail: expect.objectContaining({ reason: 'stored_differs', stored, read }),
  });

  it('a member missing from what was read: raises sponsor_disagrees with both sets and writes nothing', async () => {
    const db = sponsorDb({ stored: { bill1: ['p1', 'p9'] } });
    const r = await writeSponsorships(db, 'place:1', 'run1', [sp()], { subjectsRead: new Set(['Ord 2025-41']) });
    expect(r).toEqual({ written: 0, unknownItems: 0, dropped: 1 });
    expect(upserts(db)).toHaveLength(0);
    expect(exceptions(db)).toEqual([disagrees(['p1:sponsor', 'p9:sponsor'], ['p1:sponsor'])]);
  });

  it('a member added by what was read: raises sponsor_disagrees and never adds them beside the stored one', async () => {
    const db = sponsorDb({ stored: { bill1: ['p9'] } });
    const r = await writeSponsorships(db, 'place:1', 'run1', [sp()], { subjectsRead: new Set(['Ord 2025-41']) });
    expect(r.written).toBe(0);
    expect(upserts(db)).toHaveLength(0);
    expect(exceptions(db)).toEqual([disagrees(['p9:sponsor'], ['p1:sponsor'])]);
  });

  it('a role changed (sponsor stored, cosponsor read): raises sponsor_disagrees and keeps the stored role', async () => {
    const db = sponsorDb({ stored: { bill1: ['p1'] } });
    const r = await writeSponsorships(db, 'place:1', 'run1', [sp({ role: 'cosponsor' })], { subjectsRead: new Set(['Ord 2025-41']) });
    expect(r.written).toBe(0);
    expect(upserts(db)).toHaveLength(0);
    expect(exceptions(db)).toEqual([disagrees(['p1:sponsor'], ['p1:cosponsor'])]);
  });

  it('the same members in the same roles: upserts (refreshes sentence and document) and raises nothing', async () => {
    const db = sponsorDb({ stored: { bill1: ['p1', 'p2:cosponsor'] } });
    const r = await writeSponsorships(
      db, 'place:1', 'run1', [sp(), sp({ politicianId: 'p2', role: 'cosponsor', nameAsPrinted: 'Jones' })],
      { subjectsRead: new Set(['Ord 2025-41']) },
    );
    expect(r).toEqual({ written: 2, unknownItems: 0, dropped: 0 });
    expect(exceptions(db)).toEqual([]);
  });

  it('compares stored rows even for a subject not in subjectsRead when it has rows to write', async () => {
    const db = sponsorDb({ stored: { bill1: ['p9'] } });
    await writeSponsorships(db, 'place:1', 'run1', [sp()], { subjectsRead: new Set() });
    expect(upserts(db)).toHaveLength(0);
    expect(exceptions(db)).toEqual([disagrees(['p9:sponsor'], ['p1:sponsor'])]);
  });

  it('does not compare a stored subject that was neither read nor written', async () => {
    const db = sponsorDb({ bills: { 'Ord 2025-41': 'bill1', 'Ord 2025-42': 'bill2' }, stored: { bill2: ['p9'] } });
    await writeSponsorships(db, 'place:1', 'run1', [sp()], { subjectsRead: new Set(['Ord 2025-41']) });
    expect(exceptions(db)).toEqual([]);
    expect(db.calls.some((c: any) => /legislative_sponsorships/.test(c.text) && c.params[0] === 'bill2')).toBe(false);
  });

  it('never writes a subject with an open sponsor_disagrees exception', async () => {
    const db = sponsorDb({ held: ['Ord 2025-41'] });
    const r = await writeSponsorships(
      db, 'place:1', 'run1', [sp(), sp({ label: 'Amendment 01', politicianId: 'p2' })],
      { subjectsRead: new Set(['Ord 2025-41', 'Ord 2025-41 / Amendment 01']) },
    );
    expect(r).toEqual({ written: 1, unknownItems: 0, dropped: 1 });
    expect(upserts(db).map((c: any) => c.params[2])).toEqual(['Amendment 01']);
    expect(exceptions(db)).toEqual([]);
    const q = db.calls.find((c: any) => /SELECT subject FROM essentials.local_record_exceptions/.test(c.text));
    expect(q.text).toMatch(/cause = 'sponsor_disagrees' AND status = 'open'/);
  });

  it('never issues a DELETE', async () => {
    const db = sponsorDb({ stored: { bill1: ['p1', 'p9'] } });
    await writeSponsorships(db, 'place:1', 'run1', [sp()], { subjectsRead: new Set(['Ord 2025-41']) });
    expect(db.calls.some((c: any) => /\bDELETE\b/i.test(c.text))).toBe(false);
  });

  it('writes no row without a saved document and raises sponsor_unresolved', async () => {
    const db = sponsorDb();
    const r = await writeSponsorships(db, 'place:1', 'run1', [sp({ sourceDocumentId: null })], { subjectsRead: new Set() });
    expect(r).toEqual({ written: 0, unknownItems: 0, dropped: 1 });
    expect(upserts(db)).toHaveLength(0);
    expect(exceptions(db)).toEqual([
      expect.objectContaining({ cause: 'sponsor_unresolved', subject: 'Ord 2025-41', detail: expect.objectContaining({ reason: 'no_document' }) }),
    ]);
  });

  it('raises sponsor_disagrees and writes neither row when one person appears twice for a subject', async () => {
    const db = sponsorDb();
    const r = await writeSponsorships(
      db, 'place:1', 'run1',
      [sp(), sp({ role: 'cosponsor' }), sp({ politicianId: 'p2', nameAsPrinted: 'Jones' })],
      { subjectsRead: new Set() },
    );
    expect(r).toEqual({ written: 1, unknownItems: 0, dropped: 2 });
    expect(upserts(db)).toHaveLength(1);
    expect(upserts(db)[0].params).toContain('p2');
    expect(exceptions(db)).toEqual([expect.objectContaining({ cause: 'sponsor_disagrees', subject: 'Ord 2025-41' })]);
    expect(exceptions(db)[0].detail.people).toEqual([
      { politicianId: 'p1', roles: ['sponsor', 'cosponsor'], sentences: ['Sponsored by Smith.', 'Sponsored by Smith.'] },
    ]);
  });

  it('looks the bill up by source and refuses when two bills share a number', async () => {
    const db = sponsorDb({ dupes: ['Ord 2025-41'] });
    const r = await writeSponsorships(db, 'place:1', 'run1', [sp(), sp({ politicianId: 'p2' })], { subjectsRead: new Set() });
    expect(r).toEqual({ written: 0, unknownItems: 1, dropped: 2 });
    expect(upserts(db)).toHaveLength(0);
    const lookup = db.calls.find((c: any) => /FROM essentials.legislative_bills/.test(c.text));
    expect(lookup.text).toMatch(/source = 'onboard'/);
    expect(lookup.text).toMatch(/LIMIT 2/);
    expect(exceptions(db)).toEqual([
      { cause: 'unknown_item', subject: 'Ord 2025-41', detail: { reason: 'ambiguous_bill', number: 'Ord 2025-41' } },
    ]);
  });

  it('uses the amendment subject form', async () => {
    const db = sponsorDb({ bills: { 'Ord 2025-41': 'bill1' } });
    await writeSponsorships(db, 'place:1', 'run1', [sp({ label: 'Amendment 01', sourceDocumentId: null })], { subjectsRead: new Set() });
    expect(exceptions(db)[0].subject).toBe('Ord 2025-41 / Amendment 01');
  });
});
