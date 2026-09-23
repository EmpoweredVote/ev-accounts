import { vi, describe, it, expect, beforeEach } from 'vitest';
import type { VerifiedRow } from './researchVerifier.js';

const mockQuery = vi.fn().mockResolvedValue({ rows: [] });
// A transaction client (pool.connect()): its own query mock, so a test can tell what ran inside
// the transaction from what ran on the pool. Default: every statement succeeds with rowCount 1.
const mockClientQuery = vi.fn().mockResolvedValue({ rows: [], rowCount: 1 });
const mockRelease = vi.fn();
const mockConnect = vi.fn(async () => ({ query: mockClientQuery, release: mockRelease }));
vi.mock('./db.js', () => ({
  pool: { query: mockQuery, connect: mockConnect },
}));

import { buildEvidenceRowsForInsert, buildReviewRowForInsert } from './researchEvidenceService.js';

const exampleRow: VerifiedRow = {
  stance: { full_name: 'Brad Sherman', politician_id: '', topic_key: 'healthcare', value: 2, reasoning: 'public option' },
  verifiedSources: [
    {
      url: 'https://a.example',
      snippets: [
        { snippet: 'snippet text one', snippet_index: 0, verdict: { verdict: 'verified', matchOffset: 100 } },
        { snippet: 'snippet text two', snippet_index: 1, verdict: { verdict: 'snippet_not_found' } },
      ],
    },
  ],
  failedSources: [],
};

describe('buildEvidenceRowsForInsert', () => {
  it('flattens verified-only snippets per source for DB insert', () => {
    const rows = buildEvidenceRowsForInsert({
      row: exampleRow,
      politicianId: '11111111-1111-1111-1111-111111111111',
      topicId: '22222222-2222-2222-2222-222222222222',
      batchId: '2026-04-30-test',
    });
    expect(rows).toEqual([
      {
        politician_id: '11111111-1111-1111-1111-111111111111',
        topic_id: '22222222-2222-2222-2222-222222222222',
        source_url: 'https://a.example',
        snippet: 'snippet text one',
        snippet_index: 0,
        batch_id: '2026-04-30-test',
      },
    ]);
  });
});

describe('buildReviewRowForInsert', () => {
  it('captures every snippet verdict in the evidence jsonb', () => {
    const review = buildReviewRowForInsert({
      row: exampleRow,
      politicianId: '11111111-1111-1111-1111-111111111111',
      topicId: '22222222-2222-2222-2222-222222222222',
      batchId: '2026-04-30-test',
      threshold: 2,
      reResearchAttempted: true,
    });
    expect(review.batch_id).toBe('2026-04-30-test');
    expect(review.politician_id).toBe('11111111-1111-1111-1111-111111111111');
    expect(review.topic_key).toBe('healthcare');
    expect(review.proposed_value).toBe(2);
    expect(review.threshold).toBe(2);
    expect(review.re_research_attempted).toBe(true);
    expect(review.verified_source_count).toBe(1);
    const ev = review.evidence as any[];
    expect(ev[0].url).toBe('https://a.example');
    expect(ev[0].snippets).toHaveLength(2);
    expect(ev[0].snippets[1].verdict).toBe('snippet_not_found');
  });

  it('uses unresolved_politician status when politicianId is null', () => {
    const review = buildReviewRowForInsert({
      row: exampleRow,
      politicianId: null,
      topicId: null,
      batchId: 'b',
      threshold: 2,
      reResearchAttempted: false,
    });
    expect(review.status).toBe('unresolved_politician');
    expect(review.full_name_raw).toBe('Brad Sherman');
  });
});

describe('accumulateEvidence', () => {
  beforeEach(() => mockQuery.mockClear());

  it('is exported as accumulateEvidence (replaceEvidence is gone)', async () => {
    const mod = await import('./researchEvidenceService.js');
    expect(typeof (mod as any).accumulateEvidence).toBe('function');
    expect((mod as any).replaceEvidence).toBeUndefined();
  });

  it('uses INSERT ON CONFLICT DO NOTHING — no DELETE', async () => {
    const { accumulateEvidence } = await import('./researchEvidenceService.js');
    await accumulateEvidence([{
      politician_id: '11111111-1111-1111-1111-111111111111',
      topic_id: '22222222-2222-2222-2222-222222222222',
      source_url: 'https://a.example',
      snippet: 'test snippet',
      snippet_index: 0,
      batch_id: 'test-batch',
    }]);
    const sqls = mockQuery.mock.calls.map((c: any[]) => String(c[0]).toUpperCase());
    expect(sqls.some(s => s.includes('ON CONFLICT') && s.includes('DO NOTHING'))).toBe(true);
    expect(sqls.some(s => s.startsWith('DELETE'))).toBe(false);
  });

  it('returns without querying when rows array is empty', async () => {
    const { accumulateEvidence } = await import('./researchEvidenceService.js');
    expect(await accumulateEvidence([])).toBe(0);
    expect(mockQuery).not.toHaveBeenCalled();
  });

  // I9 (partial): report what was really inserted — the season-less unique index drops a snippet
  // already stored for the pair, and that must not be counted as written.
  it('returns the number of rows actually inserted (sum of rowCount), not the number attempted', async () => {
    const { accumulateEvidence } = await import('./researchEvidenceService.js');
    const r = { politician_id: 'p', topic_id: 't', source_url: 'u', snippet: 's', snippet_index: 0, batch_id: 'b' };
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 1 }).mockResolvedValueOnce({ rows: [], rowCount: 0 });
    expect(await accumulateEvidence([r, { ...r, snippet_index: 1 }])).toBe(1);
  });

  it('writes on the caller\'s transaction client when given one, not on the pool', async () => {
    const { accumulateEvidence } = await import('./researchEvidenceService.js');
    const client = { query: vi.fn().mockResolvedValue({ rows: [], rowCount: 1 }) };
    const n = await accumulateEvidence([{ politician_id: 'p', topic_id: 't', source_url: 'u', snippet: 's', snippet_index: 0, batch_id: 'b' }], client);
    expect(n).toBe(1);
    expect(client.query).toHaveBeenCalledTimes(1);
    expect(mockQuery).not.toHaveBeenCalled();
  });
});

// I1: re-running a batch must never resurrect a row a person already decided.
describe('upsertReviewRow', () => {
  beforeEach(() => mockQuery.mockClear());
  const reviewInsert = {
    batch_id: 'b', politician_id: 'p', full_name_raw: 'Jane Doe', topic_id: 't', topic_key: 'healthcare',
    proposed_value: 2, proposed_reasoning: 'r', evidence: [], verified_source_count: 1, threshold: 1,
    status: 'pending' as const, re_research_attempted: false,
  };
  it('updates only rows still undecided — the ON CONFLICT DO UPDATE carries a status guard', async () => {
    const { upsertReviewRow } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 1 });
    await upsertReviewRow(reviewInsert);
    const sql = String(mockQuery.mock.calls[0][0]);
    const guard = /WHERE\s+inform\.stance_research_review\.status\s+IN\s*\(\s*'pending'\s*,\s*'unresolved_politician'\s*\)/;
    expect(sql).toMatch(guard);
    expect(sql.search(guard)).toBeGreaterThan(sql.indexOf('DO UPDATE'));
  });
  it('reports whether it wrote: false when the existing row was already decided', async () => {
    const { upsertReviewRow } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 1 }).mockResolvedValueOnce({ rows: [], rowCount: 0 });
    expect(await upsertReviewRow(reviewInsert)).toBe(true);
    expect(await upsertReviewRow(reviewInsert)).toBe(false);
  });
});

// I5: the reviewer sees what approving would replace — including an editor's blank.
describe('review reads carry the open-season current value', () => {
  beforeEach(() => mockQuery.mockClear());
  it('selects the pair\'s OPEN-season answer, marked as a site that counts blanks', async () => {
    const { getResearchReviewById, listPendingResearchReview } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [] }).mockResolvedValueOnce({ rows: [] });
    await getResearchReviewById('x');
    await listPendingResearchReview();
    for (const [sql] of mockQuery.mock.calls) {
      expect(String(sql)).toContain('@zero-scope: counts-blanks');
      expect(String(sql)).toMatch(/inform\.politician_answers[\s\S]*s\.status = 'open'/);
    }
  });
  it.each([
    ['3', 3], ['0', 0], [null, null],
  ])('maps current_value %j to currentValue %j (0 is a blank, not "none")', async (raw, want) => {
    const { getResearchReviewById } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'x', evidence: [], current_value: raw }] });
    expect((await getResearchReviewById('x'))?.currentValue).toBe(want);
  });
});

describe('writeVerifiedStance', () => {
  it('writes the answer then the context through the season-aware SQL, in param order', async () => {
    const { writeVerifiedStance } = await import('./researchEvidenceService.js');
    const { UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL } = await import('./seasonService.js');
    const before = mockQuery.mock.calls.length;
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 1 }).mockResolvedValueOnce({ rows: [], rowCount: 1 });
    await writeVerifiedStance({ politicianId: 'p', topicId: 't', value: 3, reasoning: 'r', sources: ['u'], editorId: 'e' });
    const calls = mockQuery.mock.calls.slice(before);
    expect(calls[0]).toEqual([UPSERT_ANSWER_SQL, ['p', 't', 3, 'e']]);
    expect(calls[1]).toEqual([UPSERT_CONTEXT_SQL, ['p', 't', 'r', ['u'], 'e']]);
  });
  it('refuses to report success when the open season wrote nothing', async () => {
    const { writeVerifiedStance } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });
    await expect(writeVerifiedStance({ politicianId: 'p', topicId: 't', value: 3, reasoning: 'r', sources: [], editorId: null }))
      .rejects.toThrow();
  });
  it('writes on the caller\'s transaction client when given one, not on the pool', async () => {
    const { writeVerifiedStance } = await import('./researchEvidenceService.js');
    const client = { query: vi.fn().mockResolvedValue({ rows: [], rowCount: 1 }) };
    const before = mockQuery.mock.calls.length;
    await writeVerifiedStance({ politicianId: 'p', topicId: 't', value: 3, reasoning: 'r', sources: ['u'], editorId: 'e' }, client);
    expect(client.query).toHaveBeenCalledTimes(2);
    expect(mockQuery.mock.calls.length).toBe(before);
  });
});

describe('resolveResearchReview — citations written on approval, not at queue time (R1)', () => {
  const reviewRow = {
    id: 'rev-1',
    batch_id: 'batch-1',
    politician_id: 'p1',
    full_name_raw: 'Jane Doe',
    topic_id: 't1',
    topic_key: 'healthcare',
    proposed_value: 3,
    proposed_reasoning: 'reasoning text',
    evidence: [
      {
        url: 'https://a.example',
        snippets: [
          { snippet_index: 0, snippet: 'verified snippet text', verdict: 'verified' },
          { snippet_index: 1, snippet: 'not found snippet text', verdict: 'snippet_not_found' },
        ],
      },
    ],
    verified_source_count: 1,
    threshold: 1,
    status: 'pending',
    re_research_attempted: false,
    created_at: '2026-01-01T00:00:00Z',
  };

  beforeEach(() => {
    mockQuery.mockClear(); mockClientQuery.mockClear(); mockConnect.mockClear(); mockRelease.mockClear();
  });

  // Adapted for I6: the read runs on the pool; every write runs on ONE transaction client,
  // between BEGIN and COMMIT. The assertions about what is written, and in what order, are the
  // same as before the transaction existed.
  it('inserts exactly one politician_context_evidence row, for the verified snippet only, after the answer and context writes', async () => {
    const { resolveResearchReview } = await import('./researchEvidenceService.js');
    const { UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL } = await import('./seasonService.js');
    mockQuery.mockResolvedValueOnce({ rows: [reviewRow] });     // getResearchReviewById (pool)
    // client: BEGIN, UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL, evidence insert, UPDATE, COMMIT — all
    // resolve with the default { rows: [], rowCount: 1 }.

    await resolveResearchReview('rev-1', 'editor-1');

    expect(mockQuery).toHaveBeenCalledTimes(1); // only the read is outside the transaction
    const calls = mockClientQuery.mock.calls;
    expect(calls).toHaveLength(6);
    expect(calls[0][0]).toBe('BEGIN');
    expect(calls[1][0]).toBe(UPSERT_ANSWER_SQL);
    expect(calls[2][0]).toBe(UPSERT_CONTEXT_SQL);
    expect(String(calls[4][0])).toContain("SET status = 'resolved'");
    expect(calls[5][0]).toBe('COMMIT');
    expect(mockRelease).toHaveBeenCalledTimes(1);

    const evidenceCalls = calls.filter((c) => String(c[0]).includes('politician_context_evidence'));
    expect(evidenceCalls).toHaveLength(1);
    expect(evidenceCalls[0][1]).toEqual(['p1', 't1', 'https://a.example', 'verified snippet text', 0, 'batch-1']);

    // The evidence write comes after both the answer and the context write.
    const evidenceCallIndex = calls.findIndex((c) => String(c[0]).includes('politician_context_evidence'));
    const contextCallIndex = calls.findIndex((c) => c[0] === UPSERT_CONTEXT_SQL);
    expect(evidenceCallIndex).toBeGreaterThan(contextCallIndex);
  });

  // I6: one transaction — a failed context write leaves no value, no citation, no status change.
  it('rolls back when the context write throws: no evidence insert, no status UPDATE, no COMMIT', async () => {
    const { resolveResearchReview } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [reviewRow] });
    mockClientQuery
      .mockResolvedValueOnce({ rows: [], rowCount: null })          // BEGIN
      .mockResolvedValueOnce({ rows: [], rowCount: 1 })             // UPSERT_ANSWER_SQL
      .mockRejectedValueOnce(new Error('context write failed'));    // UPSERT_CONTEXT_SQL

    await expect(resolveResearchReview('rev-1', 'editor-1')).rejects.toThrow('context write failed');

    const sqls = mockClientQuery.mock.calls.map((c) => String(c[0]));
    expect(sqls).toContain('ROLLBACK');
    expect(sqls).not.toContain('COMMIT');
    expect(sqls.some((s) => s.includes('politician_context_evidence'))).toBe(false);
    expect(sqls.some((s) => s.includes('UPDATE inform.stance_research_review'))).toBe(false);
    expect(mockQuery).toHaveBeenCalledTimes(1); // nothing was written on the pool either
    expect(mockRelease).toHaveBeenCalledTimes(1);
  });

  // I2: no approval without a citation.
  it('refuses (INCOMPLETE) a row with no machine-verified and no human-verified source, before writing', async () => {
    const { resolveResearchReview } = await import('./researchEvidenceService.js');
    const unverified = { ...reviewRow, evidence: [{ url: 'https://a.example', snippets: [
      { snippet_index: 0, snippet: 'not found snippet text', verdict: 'snippet_not_found' },
    ] }] };
    mockQuery.mockResolvedValueOnce({ rows: [unverified] });
    await expect(resolveResearchReview('rev-1', 'editor-1', [])).rejects.toMatchObject({
      code: 'INCOMPLETE',
      message: 'No verified or human-verified source — a stance cannot be published without a citation',
    });
    expect(mockConnect).not.toHaveBeenCalled();
  });
  it('accepts the same row when the reviewer ticked a source by hand', async () => {
    const { resolveResearchReview } = await import('./researchEvidenceService.js');
    const unverified = { ...reviewRow, evidence: [{ url: 'https://a.example', snippets: [
      { snippet_index: 0, snippet: 'not found snippet text', verdict: 'snippet_not_found' },
    ] }] };
    mockQuery.mockResolvedValueOnce({ rows: [unverified] });
    await resolveResearchReview('rev-1', 'editor-1', ['https://a.example']);
    expect(mockClientQuery.mock.calls.map((c) => String(c[0]))).toContain('COMMIT');
  });

  // M10: only a pending row can be approved.
  it.each(['resolved', 'rejected', 'superseded', 'unresolved_politician'])(
    'refuses (CONFLICT) a %s row, before writing', async (status) => {
      const { resolveResearchReview } = await import('./researchEvidenceService.js');
      mockQuery.mockResolvedValueOnce({ rows: [{ ...reviewRow, status }] });
      await expect(resolveResearchReview('rev-1', 'editor-1')).rejects.toMatchObject({ code: 'CONFLICT' });
      expect(mockConnect).not.toHaveBeenCalled();
    });
});
