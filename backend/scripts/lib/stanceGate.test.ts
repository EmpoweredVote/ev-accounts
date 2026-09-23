import { describe, it, expect } from 'vitest';
import { checkStanceRow, checkBatch, toStanceRows, PARTY_NAMES, GATE_CHECK_IDS,
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

  // I4: build-stance-topic-bundle dedupes politicians.json by id, not by name — two distinct
  // people can share a full_name in one bundle, and neither polByName (last-match-wins) nor a
  // per-row politician_id can tell them apart.
  const JANE2: BundlePolitician = { full_name: 'Jane Doe', politician_id: 'p2', level: 'state', race_id: 'r2' };
  it('flags a name shared by two bundle politicians as ambiguous-politician (high)', () => {
    const f = checkBatch([good], [HEALTH], [JANE, JANE2], ev);
    expect(f).toEqual([
      expect.objectContaining({
        full_name: 'Jane Doe', topic_key: 'healthcare', check_id: 'ambiguous-politician', severity: 'high',
      }),
    ]);
  });
  it('writes politician_id \'\' for an ambiguous name, even though one namesake would otherwise match', () => {
    expect(toStanceRows([good], [JANE, JANE2])).toEqual([
      { full_name: 'Jane Doe', politician_id: '', topic_key: 'healthcare', value: 2, reasoning: good.reasoning },
    ]);
  });

  // L3: one person listed twice in politicians.json (same id — e.g. given by --race and by
  // --politician) is one person, not two namesakes.
  it('does not call one person listed twice (same politician_id) ambiguous', () => {
    expect(checkBatch([good], [HEALTH], [JANE, { ...JANE, race_id: null }], ev)).toEqual([]);
    expect(toStanceRows([good], [JANE, { ...JANE, race_id: null }])[0].politician_id).toBe('p1');
  });
});

// I3: one normalizer (normName / normTopic / stanceKey from researchVerifier) for gate and verifier.
describe('checkBatch / toStanceRows — shared normalizer', () => {
  it('matches a trailing-space, odd-case name and topic to the bundle and to its evidence', () => {
    const row = { ...good, full_name: 'jane  doe ', topic_key: 'Healthcare' };
    expect(checkBatch([row], [HEALTH], [JANE], [{ ...ev[0], full_name: 'Jane Doe ' }])).toEqual([]);
  });
  it('writes the bundle politician\'s canonical full_name into stances rows', () => {
    expect(toStanceRows([{ ...good, full_name: 'jane doe ' }], [JANE])).toEqual([
      { full_name: 'Jane Doe', politician_id: 'p1', topic_key: 'healthcare', value: 2, reasoning: good.reasoning },
    ]);
  });
  it('keeps the row\'s own spelling when it matched no bundle politician', () => {
    expect(toStanceRows([{ ...good, full_name: 'Someone Else' }], [JANE])[0]).toMatchObject({ full_name: 'Someone Else', politician_id: '' });
  });
});

// C1: two research rows proposing a value for one (person, topic) pair.
describe('checkBatch — duplicate-row', () => {
  it('flags BOTH rows of a duplicated pair high, even when the spellings differ only in case/space', () => {
    const f = checkBatch([good, { ...good, full_name: 'jane doe ', value: 3 }], [HEALTH], [JANE], ev);
    expect(f).toEqual([
      expect.objectContaining({ full_name: 'Jane Doe', topic_key: 'healthcare', check_id: 'duplicate-row', severity: 'high' }),
      expect.objectContaining({ full_name: 'jane doe ', topic_key: 'healthcare', check_id: 'duplicate-row', severity: 'high' }),
    ]);
  });
  it('does not count a value=null row (insufficient evidence) as a second proposal', () => {
    expect(checkBatch([good, { ...good, value: null, source_urls: [] }], [HEALTH], [JANE], ev)).toEqual([]);
  });
  it('does not flag the same person on two different topics', () => {
    const rent = { ...good, topic_key: 'housing' };
    const f = checkBatch([good, rent], [HEALTH, topic('housing', {})], [JANE],
      [...ev, { ...ev[0], topic_key: 'housing' }]);
    expect(f.map((x) => x.check_id)).not.toContain('duplicate-row');
  });
});

describe('GATE_CHECK_IDS', () => {
  it('lists every check the gate emits, including duplicate-row', () => {
    expect(GATE_CHECK_IDS).toContain('duplicate-row');
    expect(new Set(GATE_CHECK_IDS).size).toBe(GATE_CHECK_IDS.length);
  });
});
