import { describe, it, expect } from 'vitest';
import { buildEvidenceRowsForInsert, buildReviewRowForInsert } from './researchEvidenceService.js';
import type { VerifiedRow } from './researchVerifier.js';

const exampleRow: VerifiedRow = {
  stance: { full_name: 'Brad Sherman', external_id: '', topic_key: 'healthcare', value: 2, reasoning: 'public option' },
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
