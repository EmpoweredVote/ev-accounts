import { describe, it, expect } from 'vitest';
import { checkStanceRow, checkBatch, toStanceRows, PARTY_NAMES,
  type ResearchRow, type BundleTopic, type BundlePolitician } from './stanceGate.js';

const SNIP = 'Representative Jane Doe voted yes on House Bill 1001 in 2025 because she believes every '
  + 'Hoosier family deserves affordable coverage and lower prescription costs at the pharmacy counter today';
const topic = (topic_key: string, scope: Partial<BundleTopic>): BundleTopic => ({
  topic_id: `id-${topic_key}`, topic_key, topic_revision_id: `rev-${topic_key}`, question_number: 1,
  title: topic_key, question_text: '?', stances: [1, 2, 3, 4, 5].map((value) => ({ value, text: `rung ${value}` })),
  applies_federal: true, applies_state: true, applies_local: true, applies_judicial: false, ...scope,
});
const HEALTH = topic('healthcare', { applies_local: false });
const RENT = topic('rent-regulation', { applies_federal: false, applies_state: false });
const JANE: BundlePolitician = { full_name: 'Jane Doe', politician_id: 'p1', level: 'state', race_id: 'r1' };
const good: ResearchRow = {
  full_name: 'Jane Doe', topic_key: 'healthcare', value: 2, evidence_type: 'record',
  reasoning: 'Voted YES on HB 1001 (2025), which expands the public option.', source_urls: ['https://a.gov/x'],
};
const ev = [{ full_name: 'Jane Doe', topic_key: 'healthcare', source_url: 'https://a.gov/x', snippet: SNIP, snippet_index: 0 }];
const ids = (row: ResearchRow, o: { topic?: BundleTopic | undefined; politician?: BundlePolitician | undefined; evidence?: typeof ev } = {}) =>
  checkStanceRow(row, {
    topic: 'topic' in o ? o.topic : HEALTH,
    politician: 'politician' in o ? o.politician : JANE,
    evidence: o.evidence ?? ev,
  }).map((f) => f.check_id).sort();

describe('checkStanceRow — clean rows', () => {
  it('passes a record row that names its instrument and backs its source with a snippet', () => {
    expect(ids(good)).toEqual([]);
  });
  it('sends a clean statement row to human review and flags nothing else', () => {
    expect(ids({ ...good, evidence_type: 'statement', reasoning: 'Said at the 2026 forum she backs a public option.' }))
      .toEqual(['statement-needs-review']);
  });
  it('does not gate an explicit insufficient-evidence row (value null)', () => {
    expect(ids({ ...good, value: null, source_urls: [] })).toEqual([]);
  });
});

describe('checkStanceRow — every planted defect is caught (positive controls)', () => {
  it.each([
    ['value-out-of-range', { value: 7 }],
    ['no-source', { source_urls: [] as string[] }],
    ['evidence-type-invalid', { evidence_type: 'vibes' }],
    ['record-no-instrument', { reasoning: 'She is a strong supporter of expanding coverage.' }],
    ['party-inference', { reasoning: 'Voted YES on HB 1001; as a Republican she follows the caucus.' }],
  ])('%s', (want, patch) => {
    expect(ids({ ...good, ...patch })).toContain(want);
  });
  it('source-without-snippet', () => {
    expect(ids({ ...good, source_urls: ['https://a.gov/x', 'https://b.gov/y'] })).toEqual(['source-without-snippet']);
  });
  it('snippet-too-short', () => {
    expect(ids(good, { evidence: [{ ...ev[0], snippet: 'Jane Doe voted yes on HB 1001.' }] })).toEqual(['snippet-too-short']);
  });
  it('topic-not-in-season', () => {
    expect(ids({ ...good, topic_key: 'no-such-topic' }, { topic: undefined })).toEqual(['topic-not-in-season']);
  });
  it('topic-out-of-scope', () => {
    expect(ids({ ...good, topic_key: 'rent-regulation' }, { topic: RENT, evidence: [] })).toContain('topic-out-of-scope');
  });
  it('level-unknown is a review signal, not a block', () => {
    const f = checkStanceRow(good, { topic: HEALTH, politician: { ...JANE, level: null }, evidence: ev });
    expect(f).toEqual([expect.objectContaining({ check_id: 'level-unknown', severity: 'medium' })]);
  });
  it('unknown-politician', () => {
    expect(ids(good, { politician: undefined })).toContain('unknown-politician');
  });
});

describe('refusals still refuse', () => {
  it('lower-case "democratic process" is not a party tell', () => {
    expect(PARTY_NAMES.test('protects the democratic process')).toBe(false);
    expect(ids({ ...good, reasoning: 'Voted YES on HB 1001 to protect the democratic process.' })).toEqual([]);
  });
});

describe('checkBatch / toStanceRows', () => {
  it('matches rows to topics, people and evidence by name (case-insensitive)', () => {
    const f = checkBatch([{ ...good, full_name: 'jane doe' }], [HEALTH], [JANE], ev);
    expect(f).toEqual([]);
  });
  it('carries the bundle politician_id into verifier rows', () => {
    expect(toStanceRows([good], [JANE])).toEqual([
      { full_name: 'Jane Doe', politician_id: 'p1', topic_key: 'healthcare', value: 2, reasoning: good.reasoning },
    ]);
  });
});
