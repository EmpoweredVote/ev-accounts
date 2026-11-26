import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

/**
 * Route test for GET /api/essentials/politicians/:id/council-record.
 * The pool is mocked (no real database): each query is answered by what its SQL reads.
 */
const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));
vi.mock('./essentialsService.js', () => ({
  getPoliticiansFlatList: vi.fn(), getPoliticianById: vi.fn(), politicianExists: vi.fn(),
}));
vi.mock('./essentialsProfileService.js', () => ({
  getEndorsementsByPolitician: vi.fn(), getElectionsByPolitician: vi.fn(), getJudicialRecord: vi.fn(),
  getStancesByPolitician: vi.fn(), getLegalDonorFirms: vi.fn(),
}));
vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import router from '../routes/essentialsPoliticians.js';
import { getCouncilRecordByPolitician } from './essentialsLegislativeService.js';

const app = express();
app.use('/api/essentials/politicians', router);

const PID = '11111111-1111-4111-8111-111111111111';
const CITY = { scope: 'place:test', chamberSlug: 'test-council', seatPositionName: 'City Legislature' };
const TODAY = '2026-06-01';

type Data = { terms?: any[]; voted?: any[]; pending?: any[]; confirmed?: any[] };
function answer(d: Data) {
  mockQuery.mockImplementation(async (sql: string) => {
    if (sql.includes('office_terms')) return { rows: d.terms ?? [] };
    if (sql.includes('legislative_votes')) return { rows: d.voted ?? [] };
    if (sql.includes("state = 'confirmed'") && !sql.includes('legislative_votes')) return { rows: d.confirmed ?? [] };
    if (sql.includes("'pending_minutes'")) return { rows: d.pending ?? [] };
    throw new Error('unexpected query: ' + sql.slice(0, 60));
  });
}
const term = (title: string, start: string, end: string | null, slug = 'test-council', position = 'City Legislature') => ({
  title, slug, position, start, end,
});
const roll = (o: Record<string, unknown>) => ({
  roll_call_id: 'rc1', city_scope: 'place:test', question: 'Final passage', question_order: 0, outcome: 'passed',
  meeting_date: '2026-03-01', yes: 7, no: 1, abstain: 1, feed_disagreement: null,
  bill_id: 'b1', number: 'Ord 1', title: 'Title 1', url: 'https://x/1', status_label: 'Passed',
  position: 'yea', worked_out: false, source_kind: 'memorandum', minutes_url: 'https://x/memo1', ...o,
});

beforeEach(() => {
  mockQuery.mockReset();
});

describe('getCouncilRecordByPolitician', () => {
  it('groups votes by item, items newest first, votes by date then question order', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      voted: [
        roll({ roll_call_id: 'r1', bill_id: 'b1', meeting_date: '2026-02-01', question_order: 1, question: 'Q second' }),
        roll({ roll_call_id: 'r2', bill_id: 'b1', meeting_date: '2026-02-01', question_order: 0, question: 'Q first' }),
        roll({ roll_call_id: 'r3', bill_id: 'b2', number: 'Ord 2', meeting_date: '2026-04-01' }),
      ],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.total).toBe(2);
    expect(out.items.map((i) => i.number)).toEqual(['Ord 2', 'Ord 1']);
    expect(out.items[1].votes.map((v) => v.question)).toEqual(['Q first', 'Q second']);
  });

  it('carries source_kind and the public document url (fragment stripped in SQL, no private columns)', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      voted: [roll({ roll_call_id: 'r1', source_kind: 'minutes', minutes_url: 'https://x/min' })],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.items[0].votes[0]).toMatchObject({ source_kind: 'minutes', minutes_url: 'https://x/min' });
    const sql = mockQuery.mock.calls.map((c) => c[0] as string).find((s) => s.includes('legislative_votes'))!;
    expect(sql).toContain("split_part(sd.source_url, '#', 1)");
    expect(sql).not.toMatch(/storage_path|sha256/);
  });

  it('shows pending only for meetings inside a member term (date containment)', async () => {
    answer({
      terms: [term('Seat A', '2025-01-01', '2025-12-31')],
      pending: [
        roll({ roll_call_id: 'p1', bill_id: 'bIn', number: 'In', meeting_date: '2025-06-01' }),
        roll({ roll_call_id: 'p2', bill_id: 'bOut', number: 'Out', meeting_date: '2026-06-01' }),
        roll({ roll_call_id: 'p3', bill_id: 'bBefore', number: 'Before', meeting_date: '2024-06-01' }),
      ],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.items.map((i) => i.number)).toEqual(['In']);
    expect(out.items[0].pending).toEqual({ meeting_date: '2025-06-01', outcome: 'passed', yes: 7, no: 1, abstain: 1 });
    expect(out.items[0].votes).toEqual([]);
    expect(JSON.stringify(out)).not.toMatch(/name_as_printed/);
  });

  it('ignores a term on another office under the same chamber slug (the City Clerk is not a seat)', async () => {
    answer({
      terms: [term('City Clerk', '2020-01-01', null, 'test-council', 'City Clerk//Ward Officer')],
      pending: [roll({ roll_call_id: 'p1', bill_id: 'bP', number: 'P', meeting_date: '2025-06-01' })],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out).toEqual({ total: 0, items: [] });
    expect(mockQuery.mock.calls.some((c) => String(c[0]).includes("'pending_minutes'"))).toBe(false);
    const termCall = mockQuery.mock.calls.find((c) => String(c[0]).includes('office_terms'))!;
    expect(termCall[0]).toMatch(/o\.normalized_position_name/);
  });

  it('returns the empty shape for someone with no council terms or roll calls, and skips the pending query', async () => {
    answer({});
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out).toEqual({ total: 0, items: [] });
    expect(mockQuery.mock.calls.some((c) => String(c[0]).includes("'pending_minutes'"))).toBe(false);
  });

  it('seat_label is set only when the vote-date seat differs from the current seat', async () => {
    answer({
      terms: [term('Seat A', '2020-01-01', '2023-12-31'), term('Seat B', '2024-01-01', null)],
      voted: [
        roll({ roll_call_id: 'r1', bill_id: 'b1', meeting_date: '2022-05-01' }),
        roll({ roll_call_id: 'r2', bill_id: 'b2', meeting_date: '2025-05-01' }),
      ],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.items.find((i) => i.bill_id === 'b1')!.votes[0].seat_label).toBe('Seat A');
    expect(out.items.find((i) => i.bill_id === 'b2')!.votes[0].seat_label).toBeNull();
  });

  it('seat_label is null when there is no current seat', async () => {
    answer({
      terms: [term('Seat A', '2020-01-01', '2023-12-31')],
      voted: [roll({ meeting_date: '2022-05-01' })],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.items[0].votes[0].seat_label).toBeNull();
  });

  it('a member holding two offices yields one item set, not a doubled one', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null), term('Seat B', '2024-01-01', null)],
      voted: [roll({ roll_call_id: 'r1', meeting_date: '2025-05-01' })],
      pending: [roll({ roll_call_id: 'p1', bill_id: 'b9', number: 'Ord 9', meeting_date: '2025-06-01' })],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.total).toBe(2);
    expect(out.items.find((i) => i.bill_id === 'b1')!.votes).toHaveLength(1);
    expect(out.items.find((i) => i.bill_id === 'b9')!.pending).not.toBeNull();
    const termSql = mockQuery.mock.calls.map((c) => c[0] as string).find((s) => s.includes('office_terms'))!;
    expect(termSql).toContain('DISTINCT');
    expect(termSql).not.toMatch(/term_end IS NULL/i);
  });

  it('pages with limit and offset, total counts every item', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      voted: [1, 2, 3].map((n) => roll({ roll_call_id: `r${n}`, bill_id: `b${n}`, number: `Ord ${n}`, meeting_date: `2026-0${n}-01` })),
    });
    const out = await getCouncilRecordByPolitician(PID, 1, 1, { cities: [CITY], today: TODAY });
    expect(out.total).toBe(3);
    expect(out.items.map((i) => i.number)).toEqual(['Ord 2']);
  });
});

describe('GET /api/essentials/politicians/:id/council-record', () => {
  it('rejects a malformed id with 422', async () => {
    const res = await request(app).get('/api/essentials/politicians/not-a-uuid/council-record');
    expect(res.status).toBe(422);
  });

  it('returns the empty shape for a non-council id', async () => {
    answer({});
    const res = await request(app).get(`/api/essentials/politicians/${PID}/council-record`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ total: 0, items: [] });
  });

  it('clamps limit to 1-200 and defaults to 50', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      voted: Array.from({ length: 205 }, (_, n) => roll({ roll_call_id: `r${n}`, bill_id: `b${n}`, number: `Ord ${n}`, meeting_date: '2026-01-01' })),
    });
    // The route reads the real cities file; only the roll-call data decides the items here.
    const big = await request(app).get(`/api/essentials/politicians/${PID}/council-record?limit=9999`);
    expect(big.body.items).toHaveLength(200);
    expect(big.body.total).toBe(205);
    const zero = await request(app).get(`/api/essentials/politicians/${PID}/council-record?limit=0`);
    expect(zero.body.items).toHaveLength(1);
    const dflt = await request(app).get(`/api/essentials/politicians/${PID}/council-record`);
    expect(dflt.body.items).toHaveLength(50);
  });

  it('answers 500 on a database error', async () => {
    mockQuery.mockRejectedValue(new Error('boom'));
    const res = await request(app).get(`/api/essentials/politicians/${PID}/council-record`);
    expect(res.status).toBe(500);
  });
});

describe('fix round 2', () => {
  it('hides pending when a confirmed roll call exists for that bill and date even with no vote row for the member', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      pending: [roll({ roll_call_id: 'p1', bill_id: 'b1', meeting_date: '2026-03-01' })],
      confirmed: [{ city_scope: 'place:test', bill_id: 'b1', meeting_date: '2026-03-01' }],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out).toEqual({ total: 0, items: [] });
  });

  it('a confirmed roll call in another city scope does not hide the pending one', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      pending: [roll({ roll_call_id: 'p1', bill_id: 'b1', meeting_date: '2026-03-01' })],
      confirmed: [{ city_scope: 'place:other', bill_id: 'b1', meeting_date: '2026-03-01' }],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.items).toHaveLength(1);
  });

  it('negative offset starts at the first item', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      voted: [1, 2, 3].map((n) => roll({ roll_call_id: `r${n}`, bill_id: `b${n}`, number: `Ord ${n}`, meeting_date: `2026-0${n}-01` })),
    });
    const res = await request(app).get(`/api/essentials/politicians/${PID}/council-record?offset=-1&limit=2`);
    expect(res.body.items.map((i: any) => i.number)).toEqual(['Ord 3', 'Ord 2']);
  });
});

describe('fix round 1', () => {
  it('drops a pending roll call when a confirmed one exists for the same bill and meeting date', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      voted: [roll({ roll_call_id: 'r1', bill_id: 'b1', meeting_date: '2026-03-01' })],
      pending: [roll({ roll_call_id: 'p1', bill_id: 'b1', meeting_date: '2026-03-01' })],
      confirmed: [{ city_scope: 'place:test', bill_id: 'b1', meeting_date: '2026-03-01' }],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.items[0].pending).toBeNull();
    expect(out.items[0].votes).toHaveLength(1);
  });

  it('keeps a pending Final from a later meeting beside earlier confirmed votes', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      voted: [roll({ roll_call_id: 'r1', bill_id: 'b1', meeting_date: '2026-03-01', question: 'Amendment 01' })],
      pending: [roll({ roll_call_id: 'p1', bill_id: 'b1', meeting_date: '2026-04-01' })],
      confirmed: [{ city_scope: 'place:test', bill_id: 'b1', meeting_date: '2026-03-01', question: 'Amendment 01' }],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.items[0].pending?.meeting_date).toBe('2026-04-01');
    expect(out.items[0].votes).toHaveLength(1);
  });

  it('skips votes whose confirming document is missing or is item text', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      voted: [
        roll({ roll_call_id: 'r1', bill_id: 'b1', source_kind: null, minutes_url: null }),
        roll({ roll_call_id: 'r2', bill_id: 'b2', number: 'Ord 2', source_kind: 'item_text', minutes_url: 'https://x/t' }),
        roll({ roll_call_id: 'r3', bill_id: 'b3', number: 'Ord 3' }),
      ],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.items.map((i) => i.number)).toEqual(['Ord 3']);
  });

  it('treats a meeting on the term end date as inside the term', async () => {
    answer({
      terms: [term('Seat A', '2025-01-01', '2025-12-31')],
      pending: [roll({ roll_call_id: 'p1', meeting_date: '2025-12-31' })],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.items).toHaveLength(1);
  });

  it('route clamps a negative offset to 0 and limit above 200 or below 1', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      voted: Array.from({ length: 3 }, (_, n) => roll({ roll_call_id: `r${n}`, bill_id: `b${n}`, number: `Ord ${n}`, meeting_date: `2026-01-0${n + 1}` })),
    });
    const neg = await request(app).get(`/api/essentials/politicians/${PID}/council-record?offset=-5`);
    expect(neg.body.items).toHaveLength(3);
    const lo = await request(app).get(`/api/essentials/politicians/${PID}/council-record?limit=-3&offset=1`);
    expect(lo.body.items).toHaveLength(1);
    expect(lo.body.items[0].number).toBe('Ord 1');
  });
});

describe('existing routes are untouched', () => {
  it('/votes still reads only legislative_votes joined to bills, with no roll-call tables', async () => {
    const { getVotesByPolitician } = await import('./essentialsLegislativeService.js');
    mockQuery.mockResolvedValue({ rows: [] });
    await getVotesByPolitician(PID, 10);
    const sql = String(mockQuery.mock.calls[0][0]);
    expect(sql).not.toMatch(/roll_calls|source_documents/);
  });
});

describe('final review: a stale pending Final passage', () => {
  it('hides a pending Final passage when the bill has a confirmed Final passage on another date', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      voted: [roll({ roll_call_id: 'r1', bill_id: 'b1', meeting_date: '2026-03-01' })],
      pending: [roll({ roll_call_id: 'p1', bill_id: 'b1', meeting_date: '2026-03-15' })],
      confirmed: [{ city_scope: 'place:test', bill_id: 'b1', meeting_date: '2026-03-01', question: 'Final passage' }],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.items[0].pending).toBeNull();
    expect(out.items[0].votes).toHaveLength(1);
  });

  it('hides it even when the member has no vote row on the confirmed Final', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      pending: [roll({ roll_call_id: 'p1', bill_id: 'b1', meeting_date: '2026-03-15' })],
      confirmed: [{ city_scope: 'place:test', bill_id: 'b1', meeting_date: '2026-03-01', question: 'Final passage' }],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out).toEqual({ total: 0, items: [] });
  });

  it('a confirmed Final passage in another city scope does not hide it', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      pending: [roll({ roll_call_id: 'p1', bill_id: 'b1', meeting_date: '2026-03-15' })],
      confirmed: [{ city_scope: 'place:other', bill_id: 'b1', meeting_date: '2026-03-01', question: 'Final passage' }],
    });
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.items[0].pending?.meeting_date).toBe('2026-03-15');
  });

  it('the confirmed query reads the question', async () => {
    answer({
      terms: [term('Seat A', '2024-01-01', null)],
      pending: [roll({ roll_call_id: 'p1', bill_id: 'b1', meeting_date: '2026-03-15' })],
    });
    await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    const sql = mockQuery.mock.calls.map((c) => c[0] as string).find((s) => s.includes("state = 'confirmed'") && !s.includes('legislative_votes'))!;
    expect(sql).toMatch(/r\.question/);
  });
});
