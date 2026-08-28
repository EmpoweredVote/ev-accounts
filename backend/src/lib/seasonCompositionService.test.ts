import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

const { mockAdminRpc } = vi.hoisted(() => ({ mockAdminRpc: vi.fn() }));
vi.mock('./supabase.js', () => ({ adminRpc: mockAdminRpc }));

import {
  listSeasons,
  getComposition,
  createDraftSeason,
  openSeason,
} from './seasonCompositionService.js';

beforeEach(() => {
  mockQuery.mockReset();
  mockAdminRpc.mockReset();
});

const OPEN = {
  id: '11111111-1111-4111-8111-111111111111', number: 1, name: 'Season 1',
  status: 'open', opened_at: '2025-01-01', closed_at: null, public_note: 'n', question_count: '2',
};
const DRAFT = {
  id: '22222222-2222-4222-8222-222222222222', number: 2, name: 'Season 2',
  status: 'draft', opened_at: null, closed_at: null, public_note: 'n2', question_count: '1',
};

describe('listSeasons', () => {
  it('returns seasons with numeric question_count', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [OPEN, DRAFT], rowCount: 2 });
    const rows = await listSeasons();
    expect(rows[0].question_count).toBe(2);
    expect(rows[1].status).toBe('draft');
  });
});

describe('getComposition', () => {
  it('assembles topics with pins, ladders and distribution', async () => {
    const topicId = '33333333-3333-4333-8333-333333333333';
    const revA = '44444444-4444-4444-8444-444444444444'; // open pin
    const revB = '55555555-5555-4555-8555-555555555555'; // current + draft pin
    mockQuery
      // 1: seasons
      .mockResolvedValueOnce({ rows: [OPEN, DRAFT], rowCount: 2 })
      // 2: topic matrix
      .mockResolvedValueOnce({ rows: [{
        topic_id: topicId, topic_key: 'healthcare',
        current_revision_id: revB, current_revision: 2,
        current_title: 'Healthcare Access', current_short_title: 'Healthcare',
        current_question: 'Q v2',
        open_qn: 13, open_do: 13, open_pin_id: revA,
        open_pin_revision: 1, open_pin_title: 'Healthcare Access',
        open_pin_short_title: 'Healthcare', open_pin_question: 'Q v1',
        draft_qn: 13, draft_do: 13, draft_pin_id: revB,
        draft_pin_revision: 2, draft_pin_title: 'Healthcare Access',
        draft_pin_short_title: 'Healthcare', draft_pin_question: 'Q v2',
      }], rowCount: 1 })
      // 3: distribution (issued in the same Promise.all as the matrix)
      .mockResolvedValueOnce({ rows: [
        { topic_id: topicId, value: 1, n: 10 },
        { topic_id: topicId, value: 3, n: 5 },
      ], rowCount: 2 })
      // 4: ladders
      .mockResolvedValueOnce({ rows: [
        { topic_revision_id: revA, value: 1, text: 'old rung 1' },
        { topic_revision_id: revB, value: 1, text: 'new rung 1' },
      ], rowCount: 2 });

    const c = await getComposition();
    expect(c.open_season?.number).toBe(1);
    expect(c.draft_season?.number).toBe(2);
    const t = c.topics[0];
    expect(t.in_open?.pin.revision_id).toBe(revA);
    expect(t.in_open?.pin.ladder).toEqual([{ value: 1, text: 'old rung 1' }]);
    expect(t.in_draft?.pin.revision_id).toBe(revB);
    expect(t.current?.revision_id).toBe(revB);
    expect(t.distribution).toEqual({ 1: 10, 3: 5 });
    expect(t.answer_total).toBe(15);
  });

  it('still aggregates the distribution when no season is open (reads follow the person)', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [DRAFT], rowCount: 1 })
      .mockResolvedValueOnce({ rows: [], rowCount: 0 })
      .mockResolvedValueOnce({ rows: [], rowCount: 0 })
      .mockResolvedValueOnce({ rows: [], rowCount: 0 });
    const c = await getComposition();
    expect(c.open_season).toBeNull();
    expect(c.topics).toEqual([]);
    expect(mockQuery).toHaveBeenCalledTimes(4);
  });

  it('resolves each answer to its newest season, never the bare pair (ADR 0005 §1.2)', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [OPEN], rowCount: 1 })
      .mockResolvedValueOnce({ rows: [], rowCount: 0 })
      .mockResolvedValueOnce({ rows: [], rowCount: 0 })
      .mockResolvedValueOnce({ rows: [], rowCount: 0 });
    await getComposition();
    const distSql = mockQuery.mock.calls[2][0] as string;
    expect(distSql).toMatch(/DISTINCT ON \(a\.politician_id, a\.topic_id\)/);
    expect(distSql).toMatch(/ORDER BY a\.politician_id, a\.topic_id, s\.number DESC/);
  });
});

describe('mutations', () => {
  it('createDraftSeason calls the RPC in the inform schema and returns data', async () => {
    mockAdminRpc.mockResolvedValueOnce({
      data: { season_id: 's', number: 2, question_count: 44 }, error: null,
    });
    const out = await createDraftSeason('actor', 'Season 2', 'note', true);
    expect(mockAdminRpc).toHaveBeenCalledWith('admin_create_draft_season',
      { p_actor_id: 'actor', p_name: 'Season 2', p_public_note: 'note', p_carry_from_open: true },
      'inform');
    expect(out.question_count).toBe(44);
  });

  it('rethrows the RPC error message unchanged (route maps the prefix)', async () => {
    mockAdminRpc.mockResolvedValueOnce({
      data: null,
      error: { message: 'DRAFT_EXISTS: a draft season already exists — edit it or delete it first' },
    });
    await expect(createDraftSeason('a', 'n', 'p', true)).rejects.toThrow(/^DRAFT_EXISTS:/);
  });

  it('openSeason passes ids through', async () => {
    mockAdminRpc.mockResolvedValueOnce({
      data: { opened_season_id: 'x', closed_season_id: 'y', question_count: 44 }, error: null,
    });
    const out = await openSeason('x', 'actor');
    expect(mockAdminRpc).toHaveBeenCalledWith('admin_open_season',
      { p_season_id: 'x', p_actor_id: 'actor' }, 'inform');
    expect(out.closed_season_id).toBe('y');
  });
});
