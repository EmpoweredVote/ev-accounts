import { describe, it, expect } from 'vitest';
import { buildCoderReviewRow, coderDateToSql, publishableWindow, type SnapshotInfo } from './coderQueue.js';
import type { CoderRow, Passage } from './coderLabel.js';
import type { RowReport } from './codingReport.js';

const words = (n: number, w = 'filler') => Array.from({ length: n }, (_, i) => `${w}${i}`).join(' ');
const PAGE = `${words(20, 'pre')} The Act REQUIRES every landlord to cap annual rent increases at five percent. ${words(20, 'post')}`;
const passage = (over: Partial<Passage> = {}): Passage => ({
  snapshot_id: 's1', v1_attribution: 'own-act', v2_relevance: 'on-question', v3_class: 'record', v4_shape: 'chair-shaped',
  v5_time: 'in-term', date: '2024-03', instrument: 'HB 1', provision_quote: 'requires every landlord to cap annual rent increases',
  record_kind: 'sponsor', actor_quote: 'sponsored by', tally_quote: null, ...over,
});
const coderRow = (passages: Passage[]): CoderRow => ({
  politician_id: 'p', office_id: 'o', topic_id: 't', served_revision_id: 'r', passages, v6_value: 2, v6_blank_reason: null,
  rests_on: passages.map((p) => p.snapshot_id), reasoning: 'Sponsored HB 1.', needs_source: [], quotes: [],
});
const report = (over: Partial<RowReport> = {}): RowReport => ({
  key: 'p|o|t', topic_key: 'rent', outcome: { kind: 'unanimous-chair', value: 2, shared_sources: ['s1'] }, confirm: [],
  stratum: { level: 'state', evidence_class: 'record' }, shadow: 'would-publish-if-certified', shadow_reasons: [],
  seed: 'none', profiles: [], evidence_tier: 'single-source', ...over,
});
const snaps = new Map<string, SnapshotInfo>([['s1', { url: 'https://leg.example/hb1', source_kind: 'public-record', snapshot_text: PAGE }]]);
const build = (r: RowReport, rows = [passage()]) => buildCoderReviewRow({
  batchId: 'b', seasonId: 'season', codebookVersion: '0.4', seat: { politician_id: 'p', office_id: 'o', full_name: 'Jane Doe' },
  topic: { topic_id: 't', topic_key: 'rent', served_revision_id: 'r' }, report: r, consensusRow: coderRow(rows), snapshots: snaps,
});

describe('coderDateToSql', () => {
  it.each([
    ['2017', { date: '2017-01-01', precision: 'year' }],
    ['2024-03', { date: '2024-03-01', precision: 'month' }],
    ['2024-03-09', { date: '2024-03-09', precision: 'day' }],
  ])('%s', (d, want) => expect(coderDateToSql(d)).toEqual(want));
  it('null stays null', () => expect(coderDateToSql(null)).toBeNull());
});

describe('publishableWindow', () => {
  it('widens the span to 25 words of the page, in the page\'s own case', () => {
    const w = publishableWindow(PAGE, 'requires every landlord to cap annual rent increases')!;
    expect(w.split(' ')).toHaveLength(25);
    expect(w).toContain('REQUIRES every landlord to cap annual rent increases');
  });
  it('matches a span that stops before the page\'s punctuation', () =>
    expect(publishableWindow(`${words(30)} Rep. Robert Behning, Rep. Bruce Borders ${words(5)}`, 'Rep. Robert Behning')).toContain('Behning,'));
  it('null when the span is not on the page', () => expect(publishableWindow(PAGE, 'abolish rent control')).toBeNull());
  it('null when the page is shorter than the minimum', () => expect(publishableWindow('too short a page', 'short')).toBeNull());
});

describe('buildCoderReviewRow', () => {
  it('queues a unanimous chair with dated, publishable sources and the tier', () => {
    const r = build(report())!;
    expect(r.proposed_value).toBe(2);
    expect(r.consensus_value).toBe(2);
    expect(r.evidence_tier).toBe('single-source');
    expect(r.queue_reasons).toEqual(['stratum-uncertified']);
    expect(r.evidence_type).toBe('record');
    expect(r.evidence).toHaveLength(1);
    expect(r.evidence[0]).toMatchObject({ url: 'https://leg.example/hb1', date: '2024-03-01', date_precision: 'month' });
    expect(r.evidence[0].snippets[0].matched_span).toContain('REQUIRES every landlord');
    expect(r.verified_source_count).toBe(1);
  });
  it('keeps the report\'s review reasons and adds no stratum reason to a row that would review anyway', () =>
    expect(build(report({ shadow: 'would-review', shadow_reasons: ['statement-other'] }))!.queue_reasons).toEqual(['statement-other']));
  it('lists a source with no publishable window as unpublishable', () => {
    const r = build(report(), [passage({ provision_quote: 'not on the page at all', actor_quote: null })])!;
    expect(r.unpublishable).toEqual(['https://leg.example/hb1']);
    expect(r.verified_source_count).toBe(0);
  });
  it.each([
    [{ kind: 'unanimous-blank', reason: 'no-evidence' }],
    [{ kind: 'split', values: [2, 3, 2] }],
    [{ kind: 'needs-source', requests: ['x'] }],
  ] as const)('queues nothing for %o', (outcome) => expect(build(report({ outcome: outcome as RowReport['outcome'] }))).toBeNull());
});
