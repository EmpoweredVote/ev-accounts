import { vi, describe, it, expect, beforeEach } from 'vitest';
import type { VerifiedRow } from './researchVerifier.js';

const mockQuery = vi.fn().mockResolvedValue({ rows: [] });
vi.mock('./db.js', () => ({
  pool: { query: mockQuery },
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
    await accumulateEvidence([]);
    expect(mockQuery).not.toHaveBeenCalled();
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
});
