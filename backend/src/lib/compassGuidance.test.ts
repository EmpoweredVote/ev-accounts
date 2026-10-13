import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));
vi.mock('./cache.js', () => ({ cache: { get: vi.fn(), set: vi.fn(), del: vi.fn() } }));
vi.mock('./supabase.js', () => ({
  supabaseAnon: {}, supabaseService: {}, adminRpc: vi.fn(), createUserClient: vi.fn(),
}));

import { getPromotedTopics } from './compassService.js';
import { servedRevisionLateral } from './seasonService.js';

beforeEach(() => mockQuery.mockReset());

/**
 * `guidance` (CC_0231) is the line under the question. It breaks SILENTLY — a
 * missing column in a SELECT costs you a blank line on sixty questions and no
 * error anywhere — so the plumbing is pinned rather than trusted.
 */
describe('guidance reaches the topic payload', () => {
  // 🔴 THE TRAP THIS CATCHES. servedRevisionLateral SELECTs an explicit column
  // list. Adding `guidance` to compass_topic_revisions does not put it in
  // scope for `eff`, so `eff.guidance` in getPromotedTopics would fail — or,
  // worse on a future refactor, quietly resolve to something else.
  it('the served-revision lateral exposes guidance to its alias', () => {
    expect(servedRevisionLateral('p.season_revision_id', 'eff')).toContain('e.guidance');
  });

  it('getPromotedTopics reads guidance from the SERVED revision, not the topic row', async () => {
    mockQuery.mockResolvedValue({
      rows: [{ id: 't1', topic_key: 'a', title: 'T', short_title: 'T', question_text: 'Q?',
               version: 1, effective_revision_id: 'r1', guidance: 'Whether X, or Y.',
               fc_community_slug: null, judicial_role: null, is_live: true, office_scope: null }],
    });
    const topics = await getPromotedTopics();
    const sql = mockQuery.mock.calls[0][0] as string;

    // It must come off `eff`. Reading it from `t` (compass_topics) would be the
    // one piece of question wording that ignored the season's pin, so a season
    // serving v3's text would serve v5's gloss beside it — ADR 0006 Option Y.
    expect(sql).toMatch(/eff\.guidance/);
    expect(sql).not.toMatch(/\bt\.guidance/);
    expect(topics[0].guidance).toBe('Whether X, or Y.');
  });

  // An editor's deliberate blank and an unset column should look identical to
  // the client, so the UI has one absent case to handle instead of three.
  it('normalises an empty or whitespace-only guidance to NULL', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await getPromotedTopics().catch(() => { /* empty set throws by design */ });
    expect(mockQuery.mock.calls[0][0]).toContain(`NULLIF(btrim(eff.guidance), '')`);
  });
});
