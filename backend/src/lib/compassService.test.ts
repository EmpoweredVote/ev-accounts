import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));
vi.mock('./supabase.js', () => ({
  supabaseAnon: {},
  supabaseService: {},
  adminRpc: vi.fn(),
}));

import { getPromotedTopics } from './compassService.js';

beforeEach(() => mockQuery.mockReset());

const row = (id: string, key: string) => ({
  id, topic_key: key, title: 'T', short_title: 'T', question_text: 'Q?',
  version: 1, fc_community_slug: null, judicial_role: null,
  is_live: true, office_scope: null,
});

// Promotion moved off `is_live` and onto the open season's question set
// (ADR 0004 §12 as corrected, ADR 0005 §4.2). These guard the two properties of
// that move that nothing else would catch.
describe('getPromotedTopics — promotion comes from the open season', () => {
  it('reads compass_topics_promoted, not compass_topics WHERE is_live', async () => {
    mockQuery.mockResolvedValue({ rows: [row('t1', 'a'), row('t2', 'b')] });
    await getPromotedTopics();

    const sql = mockQuery.mock.calls[0][0] as string;
    expect(sql).toContain('inform.compass_topics_promoted');
    // is_live may still be SELECTED (it stays in the response contract), but it
    // must no longer be the FILTER — that is the whole point of the repoint.
    expect(sql).not.toMatch(/WHERE[\s\S]*is_live\s*=\s*true/);
  });

  // 🔴 The failure this exists to prevent. Zero promoted topics is what "no
  // season is open" looks like — a state that really happened for a day in
  // August 2026. Returning [] renders an empty compass to every voter and
  // reports success. A view cannot raise on an empty result, so the caller must.
  it('THROWS on an empty promoted set rather than returning []', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await expect(getPromotedTopics()).rejects.toThrow(/no promoted compass topics/);
  });

  it('names the season tables in the error, so the fix is findable', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await expect(getPromotedTopics()).rejects.toThrow(/inform\.seasons/);
    await expect(getPromotedTopics()).rejects.toThrow(/season_questions/);
  });

  // created_at holds only 28 distinct values across 44 topics, and two
  // timestamps cover 10 and 8 rows. Without a tiebreaker those 18 come back in
  // whatever order the plan emits, so the compass can reorder between requests.
  it('orders by a deterministic key, not created_at alone', async () => {
    mockQuery.mockResolvedValue({ rows: [row('t1', 'a')] });
    await getPromotedTopics();

    const sql = mockQuery.mock.calls[0][0] as string;
    expect(sql).toMatch(/ORDER BY[\s\S]*created_at\s*,\s*p\.topic_key/);
  });

  it('passes the promoted rows through unchanged', async () => {
    mockQuery.mockResolvedValue({ rows: [row('t1', 'a'), row('t2', 'b')] });
    const topics = await getPromotedTopics();

    expect(topics.map(t => t.id)).toEqual(['t1', 't2']);
    // Still in the response contract even though neither is in the view.
    expect(topics[0]).toHaveProperty('is_live');
    expect(topics[0]).toHaveProperty('office_scope');
  });
});
