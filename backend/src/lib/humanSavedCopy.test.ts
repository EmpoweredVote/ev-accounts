import { describe, it, expect } from 'vitest';
import { markHumanSaved, sha256Hex } from './humanSavedCopy.js';
import { verifyEvidence, createPageFetcher, type StanceRow, type EvidenceRow } from './researchVerifier.js';
import { buildReviewRowForInsert } from './researchEvidenceService.js';

const QUOTE = 'California families deserve a governor who will cut red tape, lower the cost of housing, and put students first in every classroom, because our schools are failing the children who need them most';
const COPY = `Policies. Steve Hilton on education. ${QUOTE}. Paid for by the campaign.`;
const SPA = '<html><div id="root"></div></html>';
const URL_ = 'https://hilton.example/policies/education';
const stance: StanceRow = { full_name: 'Steve Hilton', politician_id: 'p', topic_key: 'education', value: 2, reasoning: 'r', source_urls: [URL_] };
const ev: EvidenceRow = { full_name: 'Steve Hilton', topic_key: 'education', source_url: URL_, snippet: QUOTE, snippet_index: 1 };
const names = { 'Steve Hilton': { fullName: 'Steve Hilton', lastName: 'Hilton', aliases: [] } } as any;
const verify = () => verifyEvidence({ stanceRows: [stance], evidenceRows: [ev], fetcher: createPageFetcher(async () => SPA), threshold: 1, politicianNames: names });

describe('markHumanSaved', () => {
  it('POSITIVE CONTROL: finds a known snippet in the saved copy', () => {
    const m = markHumanSaved({ rawSha256: sha256Hex(COPY), text: COPY }, [ev]);
    expect(m).toEqual({ sha256: sha256Hex(COPY), snippets_found: [1], snippets_total: 1 });
  });
  it('does not find a snippet the copy lacks', () => {
    expect(markHumanSaved({ rawSha256: 'x', text: 'nothing relevant here at all' }, [ev]).snippets_found).toEqual([]);
  });
});

describe('a saved copy is never machine verification', () => {
  it('the same quote still FAILS verifyEvidence against the SPA shell, whatever copy exists', async () => {
    const out = await verify();
    expect(out.pushable).toHaveLength(0);
    expect(out.needsReResearch[0].verifiedSources).toHaveLength(0);
    // the marker is reviewer information only: it lands on the evidence jsonb, beside the failed source
    const row = out.needsReResearch[0];
    row.failedSources[0].humanSaved = markHumanSaved({ rawSha256: 'h', text: COPY }, [ev]);
    expect(row.verifiedSources).toHaveLength(0);
    const queued = buildReviewRowForInsert({ row, politicianId: 'p', topicId: 't', batchId: 'b', threshold: 1, reResearchAttempted: false });
    const entry = (queued.evidence as any[])[0];
    expect(entry.human_saved).toEqual({ sha256: 'h', snippets_found: [1], snippets_total: 1 });
    expect(entry.snippets[0].verdict).toBe('snippet_not_found');
    expect(entry.snippets[0].matched_span).toBeUndefined();
  });
});
