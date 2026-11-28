import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

/** Council sponsorships on the council-record and council-sponsorships routes. The pool is mocked. */
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
import { getCouncilRecordByPolitician, getCouncilSponsorshipsByPolitician, amendmentKey } from './essentialsLegislativeService.js';

const app = express();
app.use('/api/essentials/politicians', router);

const PID = '11111111-1111-4111-8111-111111111111';
const OTHER = '22222222-2222-4222-8222-222222222222';
const CITY = { scope: 'place:test', chamberSlug: 'test-council', seatPositionName: 'City Legislature' };
const TODAY = '2026-06-01';

const spon = (o: Record<string, unknown>) => ({
  bill_id: 'b1', amendment_label: null, politician_id: PID, role: 'sponsor', name: 'Ann Member', ...o,
});
const vote = (o: Record<string, unknown>) => ({
  roll_call_id: 'rc1', city_scope: 'place:test', question: 'Final passage', question_order: 0, outcome: 'passed',
  meeting_date: '2026-03-01', yes: 7, no: 1, abstain: 1, feed_disagreement: null,
  bill_id: 'b1', number: 'Ord 1', title: 'Title 1', url: 'https://x/1', status_label: 'Passed',
  position: 'yea', worked_out: false, source_kind: 'memorandum', minutes_url: 'https://x/memo1', ...o,
});

/** council-record: terms + voted rolls + the sponsorship rows (or an error for that query). */
function recordData(voted: any[], sponsorRows: any[] | Error) {
  mockQuery.mockImplementation(async (sql: string) => {
    if (sql.includes('legislative_sponsorships')) {
      if (sponsorRows instanceof Error) throw sponsorRows;
      return { rows: sponsorRows };
    }
    if (sql.includes('office_terms')) {
      return { rows: [{ title: 'Seat A', slug: 'test-council', position: 'City Legislature', start: '2024-01-01', end: null }] };
    }
    if (sql.includes('legislative_votes')) return { rows: voted };
    return { rows: [] };
  });
}

const undefinedTable = Object.assign(new Error('relation does not exist'), { code: '42P01' });

beforeEach(() => {
  mockQuery.mockReset();
});

describe('council-record sponsors', () => {
  it('council-record items carry their sponsors', async () => {
    recordData([vote({})], [
      spon({}),
      spon({ politician_id: OTHER, role: 'cosponsor', name: 'Bo Member' }),
      spon({ amendment_label: 'Amendment 01', politician_id: OTHER, name: 'Bo Member' }),
    ]);
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.items[0].sponsors).toEqual([
      { politician_id: PID, name: 'Ann Member', role: 'sponsor' },
      { politician_id: OTHER, name: 'Bo Member', role: 'cosponsor' },
    ]);
    expect(JSON.stringify(out)).not.toMatch(/party/i);
  });

  it("an amendment vote carries that amendment's sponsors", async () => {
    recordData(
      [
        vote({ roll_call_id: 'r1', question: 'Amendment 01', question_order: 1 }),
        vote({ roll_call_id: 'r2', question: 'Reasonable Condition 04', question_order: 2 }),
        vote({ roll_call_id: 'r3', question: 'Final passage', question_order: 3 }),
      ],
      [
        spon({ amendment_label: 'Amendment 01', politician_id: OTHER, name: 'Bo Member' }),
        // Unpadded sponsorship label matches the padded stored question.
        spon({ amendment_label: 'Reasonable Condition 4', name: 'Ann Member' }),
      ],
    );
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    const byQ = Object.fromEntries(out.items[0].votes.map((v) => [v.question, v.sponsors]));
    expect(byQ['Amendment 01']).toEqual([{ politician_id: OTHER, name: 'Bo Member', role: 'sponsor' }]);
    expect(byQ['Reasonable Condition 04']).toEqual([{ politician_id: PID, name: 'Ann Member', role: 'sponsor' }]);
    expect(byQ['Final passage']).toEqual([]);
    expect(out.items[0].sponsors).toEqual([]);
  });

  it('items with no sponsor have an empty sponsors list', async () => {
    recordData([vote({})], []);
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.items[0].sponsors).toEqual([]);
    expect(out.items[0].votes[0].sponsors).toEqual([]);
  });

  it('reads all sponsors of the page in one query', async () => {
    recordData([vote({}), vote({ roll_call_id: 'r9', bill_id: 'b2', number: 'Ord 2' })], []);
    await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    const sponsorCalls = mockQuery.mock.calls.filter((c) => (c[0] as string).includes('legislative_sponsorships'));
    expect(sponsorCalls).toHaveLength(1);
    expect(new Set(sponsorCalls[0][1][0])).toEqual(new Set(['b1', 'b2']));
  });

  it('a missing sponsorships table (42P01) gives empty sponsors, not an error', async () => {
    recordData([vote({})], undefinedTable);
    const out = await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY });
    expect(out.items[0].sponsors).toEqual([]);
    expect(out.items[0].votes[0].sponsors).toEqual([]);
  });

  it('any other sponsorships error propagates', async () => {
    recordData([vote({})], new Error('boom'));
    await expect(getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY })).rejects.toThrow('boom');
  });
});

describe('amendmentKey', () => {
  it('ignores zero padding and returns null for other questions', () => {
    expect(amendmentKey('Amendment 01')).toBe('Amendment 1');
    expect(amendmentKey('Reasonable Condition 04')).toBe('Reasonable Condition 4');
    expect(amendmentKey('Reasonable Condition 16')).toBe('Reasonable Condition 16');
    expect(amendmentKey('Final passage')).toBeNull();
    expect(amendmentKey('Sub-amendment A to Amendment 01')).toBeNull();
    expect(amendmentKey(null)).toBeNull();
  });
});

type Sdata = { own?: any[] | Error; rolls?: any[]; others?: any[] };
function sponsorshipsData(d: Sdata) {
  mockQuery.mockImplementation(async (sql: string) => {
    if (sql.includes('local_record_source_documents')) {
      if (d.own instanceof Error) throw d.own;
      return { rows: d.own ?? [] };
    }
    if (sql.includes('legislative_roll_calls')) return { rows: d.rolls ?? [] };
    if (sql.includes('legislative_sponsorships')) return { rows: d.others ?? [] };
    throw new Error('unexpected query: ' + sql.slice(0, 60));
  });
}
const own = (o: Record<string, unknown>) => ({
  bill_id: 'b1', amendment_label: null, role: 'sponsor', sentence: 'Ann Member sponsored it.',
  document_url: 'https://city/doc', number: 'Ord 1', title: 'Title 1', url: 'https://city/1', status_label: '', ...o,
});
const rc = (o: Record<string, unknown>) => ({
  bill_id: 'b1', question: 'Final passage', outcome: 'passed', state: 'confirmed', meeting_date: '2026-03-01', ...o,
});

describe('getCouncilSponsorshipsByPolitician', () => {
  it('lists a withdrawn item with status Withdrawn', async () => {
    sponsorshipsData({ own: [own({ status_label: 'Withdrawn' })] });
    const out = await getCouncilSponsorshipsByPolitician(PID);
    expect(out.total).toBe(1);
    expect(out.items[0].status).toBe('Withdrawn');
  });

  it('an amendment with no roll call has status "No recorded vote"', async () => {
    sponsorshipsData({ own: [own({ amendment_label: 'Amendment 02', status_label: 'Passed' })] });
    const out = await getCouncilSponsorshipsByPolitician(PID);
    expect(out.items[0].status).toBe('No recorded vote');
  });

  it('status order: own amendment outcome, then Final outcome, then feed status', async () => {
    sponsorshipsData({
      own: [
        own({ amendment_label: 'Amendment 01' }),
        own({ amendment_label: 'Reasonable Condition 4' }),
        own({ amendment_label: 'Amendment 03', status_label: 'Pending' }),
      ],
      rolls: [
        rc({ question: 'Amendment 01', outcome: 'failed' }),
        rc({ question: 'Reasonable Condition 04', outcome: 'passed' }),
        rc({ question: 'Final passage', outcome: 'vetoed' }),
      ],
    });
    const out = await getCouncilSponsorshipsByPolitician(PID);
    const st = Object.fromEntries(out.items.map((i) => [i.amendment_label, i.status]));
    expect(st['Amendment 01']).toBe('failed');
    expect(st['Reasonable Condition 4']).toBe('passed');
    expect(st['Amendment 03']).toBe('vetoed');
  });

  it('uses only confirmed roll calls: a question whose only roll call is pending_minutes is "Pending"', async () => {
    sponsorshipsData({
      own: [own({ amendment_label: 'Amendment 01' }), own({ bill_id: 'b2', amendment_label: null, status_label: 'Passed' })],
      rolls: [
        rc({ question: 'Amendment 01', outcome: 'passed', state: 'pending_minutes', meeting_date: '2026-04-01' }),
        rc({ question: 'Amendment 01', outcome: 'failed', state: 'confirmed', meeting_date: '2026-03-01' }),
        rc({ bill_id: 'b2', question: 'Final passage', outcome: 'passed', state: 'pending_minutes' }),
      ],
    });
    const out = await getCouncilSponsorshipsByPolitician(PID);
    const st = Object.fromEntries(out.items.map((i) => [i.bill_id, i.status]));
    expect(st.b1).toBe('failed'); // the confirmed one, not the newer pending one
    expect(st.b2).toBe('Pending');
  });

  it('uses the feed status only when there is no roll call at all', async () => {
    sponsorshipsData({ own: [own({ status_label: 'Pending' })] });
    expect((await getCouncilSponsorshipsByPolitician(PID)).items[0].status).toBe('Pending');
  });

  it('sorts newest first by the latest meeting date and pages', async () => {
    sponsorshipsData({
      own: [own({ bill_id: 'b1', number: 'Ord 1' }), own({ bill_id: 'b2', number: 'Ord 2' }), own({ bill_id: 'b3', number: 'Ord 3' })],
      rolls: [
        rc({ bill_id: 'b1', meeting_date: '2026-01-01' }),
        rc({ bill_id: 'b2', meeting_date: '2026-05-01' }),
        rc({ bill_id: 'b2', meeting_date: '2026-02-01', question: 'Amendment 01' }),
      ],
    });
    const out = await getCouncilSponsorshipsByPolitician(PID, 2, 0);
    expect(out.total).toBe(3);
    expect(out.items.map((i) => i.number)).toEqual(['Ord 2', 'Ord 1']);
    expect((await getCouncilSponsorshipsByPolitician(PID, 2, 2)).items.map((i) => i.number)).toEqual(['Ord 3']);
  });

  it('co_sponsors are the other members on the same bill and amendment', async () => {
    sponsorshipsData({
      own: [own({ amendment_label: 'Amendment 01', role: 'sponsor' })],
      others: [
        spon({ amendment_label: 'Amendment 01', politician_id: PID }),
        spon({ amendment_label: 'Amendment 01', politician_id: OTHER, role: 'cosponsor', name: 'Bo Member' }),
        spon({ amendment_label: 'Amendment 02', politician_id: '33333333-3333-4333-8333-333333333333', name: 'Cy Member' }),
        spon({ amendment_label: null, politician_id: '44444444-4444-4444-8444-444444444444', name: 'Di Member' }),
      ],
    });
    const out = await getCouncilSponsorshipsByPolitician(PID);
    expect(out.items[0].co_sponsors).toEqual([{ politician_id: OTHER, name: 'Bo Member', role: 'cosponsor' }]);
    expect(JSON.stringify(out)).not.toMatch(/party/i);
  });

  it('never returns the storage path', async () => {
    sponsorshipsData({ own: [own({})] });
    const out = await getCouncilSponsorshipsByPolitician(PID);
    expect(out.items[0].document_url).toBe('https://city/doc');
    expect(JSON.stringify(out)).not.toMatch(/storage/);
    const sql = mockQuery.mock.calls.map((c) => c[0] as string).join('\n');
    expect(sql).not.toMatch(/storage_path|sha256/);
  });

  it('ignores legislative_bills.sponsor_id', async () => {
    sponsorshipsData({ own: [own({})] });
    await getCouncilSponsorshipsByPolitician(PID);
    await getCouncilRecordByPolitician(PID, 50, 0, { cities: [CITY], today: TODAY }).catch(() => {});
    const sql = mockQuery.mock.calls.map((c) => c[0] as string).join('\n');
    expect(sql).not.toMatch(/sponsor_id|legislative_bill_cosponsors/);
  });

  it('a missing sponsorships table (42P01) gives total 0', async () => {
    sponsorshipsData({ own: undefinedTable });
    expect(await getCouncilSponsorshipsByPolitician(PID)).toEqual({ total: 0, items: [] });
  });

  it('any other error propagates', async () => {
    sponsorshipsData({ own: new Error('boom') });
    await expect(getCouncilSponsorshipsByPolitician(PID)).rejects.toThrow('boom');
  });
});

describe('GET /api/essentials/politicians/:id/council-sponsorships', () => {
  it('rejects a malformed id with 422', async () => {
    const res = await request(app).get('/api/essentials/politicians/not-a-uuid/council-sponsorships');
    expect(res.status).toBe(422);
  });

  it('returns the list and the empty shape', async () => {
    sponsorshipsData({ own: [own({})] });
    const res = await request(app).get(`/api/essentials/politicians/${PID}/council-sponsorships?limit=9999&offset=-4`);
    expect(res.status).toBe(200);
    expect(res.body.items[0]).toMatchObject({ bill_id: 'b1', role: 'sponsor', co_sponsors: [], status: 'No recorded vote' });
    sponsorshipsData({ own: [] });
    const none = await request(app).get(`/api/essentials/politicians/${PID}/council-sponsorships`);
    expect(none.body).toEqual({ total: 0, items: [] });
  });

  it('answers 500 on a database error', async () => {
    mockQuery.mockRejectedValue(new Error('boom'));
    const res = await request(app).get(`/api/essentials/politicians/${PID}/council-sponsorships`);
    expect(res.status).toBe(500);
  });
});
