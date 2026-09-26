import { describe, it, expect } from 'vitest';
import { buildCodingReport, weakestClass } from './codingReport.js';
import { CODEBOOK_VERSION, type CoderRow, type Passage } from './coderLabel.js';
import type { SeatContext, PromptTopic } from './coderPrompt.js';
import type { S1Lead } from './s1Leads.js';

const seat: SeatContext = { politician_id: 'p1', full_name: 'J. Stuart Adams', level: 'state', mode: 'seated', office_id: 'o1', office_title: 'State Senator',
  jurisdiction_names: ['Utah'], term_start: '2021-01-01', start_precision: 'day', term_end: null, election_date: null };
const topics: PromptTopic[] = ['t1', 't2'].map((id) => ({ topic_id: id, topic_key: `k-${id}`, served_revision_id: 'r1', question_text: 'Q', stances: [], annexMd: null }));
const snapshotText = new Map([['s1', 'H.B. 11. Utah Senate President J. Stuart Adams: the bill requires students to compete on teams matching their sex at birth.']]);
const P: Passage = { snapshot_id: 's1', v1_attribution: 'own-act', v2_relevance: 'on-question', v3_class: 'record', v4_shape: 'chair-shaped',
  v5_time: 'in-term', date: '2022-03-25', instrument: 'H.B. 11', provision_quote: 'requires students to compete on teams matching their sex at birth',
  record_kind: 'other-act', actor_quote: 'J. Stuart Adams' };
const row = (topic_id: string, v: number | null): CoderRow => ({ politician_id: 'p1', office_id: 'o1', topic_id, served_revision_id: 'r1',
  passages: [P], v6_value: v, v6_blank_reason: v === null ? 'no-evidence' : null, rests_on: v === null ? [] : ['s1'], reasoning: 'r', needs_source: [], quotes: [] });
const file = (slot: number, rows: CoderRow[]) => ({ codebook_version: CODEBOOK_VERSION, coder_slot: slot, rows });
const context = { batch_id: 'b', seat, topics };
const sourceKind = new Map([['s1', 'public-record']]);

describe('weakestClass', () => {
  it('takes the weakest class present (spec section 3.2)', () => {
    expect(weakestClass([P, { ...P, v3_class: 'statement-answer' }])).toBe('statement-answer');
    expect(weakestClass([P])).toBe('record');
  });
});

describe('buildCodingReport', () => {
  it('reports a unanimous, confirmed row as would-publish-if-certified, and a split as would-review', () => {
    const files = new Map<number, unknown>([
      [1, file(1, [row('t1', 4), row('t2', 2)])],
      [2, file(2, [row('t1', 4), row('t2', 3)])],
      [3, file(3, [row('t1', 4), row('t2', 2)])],
    ]);
    const r = buildCodingReport({ context, files, snapshotText, sourceKind });
    const t1 = r.rows.find((x) => x.topic_key === 'k-t1')!;
    const t2 = r.rows.find((x) => x.topic_key === 'k-t2')!;
    expect(t1.shadow).toBe('would-publish-if-certified');
    expect(t1.stratum).toEqual({ level: 'state', evidence_class: 'record' });
    expect(t2.shadow).toBe('would-review');
    expect(t2.shadow_reasons).toContain('coder-split');
    expect(r.m1.units).toBe(2);
    expect(r.m1.alpha).toBeLessThan(1);
  });
  it('treats a missing coder file as coder-missing for every row', () => {
    const files = new Map<number, unknown>([[1, file(1, [row('t1', 4), row('t2', 4)])], [2, file(2, [row('t1', 4), row('t2', 4)])]]);
    const r = buildCodingReport({ context, files, snapshotText, sourceKind });
    expect(r.rows.every((x) => x.shadow_reasons.includes('coder-missing'))).toBe(true);
  });
  it('never marks a statement-other row publishable (ruling Q2)', () => {
    const so = { ...row('t1', 4), passages: [{ ...P, v3_class: 'statement-other' as const, provision_quote: null }] };
    const files = new Map<number, unknown>([1, 2, 3].map((s) => [s, file(s, [so, row('t2', null)])]));
    const t1 = buildCodingReport({ context, files, snapshotText, sourceKind }).rows.find((x) => x.topic_key === 'k-t1')!;
    expect(t1.shadow).toBe('would-review');
    expect(t1.shadow_reasons).toContain('statement-other');
  });
  it('collects needs-source requests', () => {
    const ns = { ...row('t1', null), needs_source: ['Clerk roll call, H.R. 28'] };
    const files = new Map<number, unknown>([1, 2, 3].map((s) => [s, file(s, [ns, row('t2', null)])]));
    expect(buildCodingReport({ context, files, snapshotText, sourceKind }).needsSource).toEqual([{ key: 'p1|o1|t1', requests: ['Clerk roll call, H.R. 28'] }]);
  });
  it('treats a prose (non-JSON) coder file as coder-missing for every row', () => {
    const files = new Map<number, unknown>([
      [1, file(1, [row('t1', 4), row('t2', 4)])],
      [2, file(2, [row('t1', 4), row('t2', 4)])],
      [3, 'Sorry, I cannot complete this request right now.'],
    ]);
    const r = buildCodingReport({ context, files, snapshotText, sourceKind });
    expect(r.rows.every((x) => x.shadow_reasons.includes('coder-missing'))).toBe(true);
  });
  it('keeps the first occurrence when a coder file has a duplicate row key', () => {
    const files = new Map<number, unknown>([
      [1, file(1, [row('t1', 4), row('t1', 1), row('t2', 4)])],
      [2, file(2, [row('t1', 4), row('t2', 4)])],
      [3, file(3, [row('t1', 4), row('t2', 4)])],
    ]);
    const r = buildCodingReport({ context, files, snapshotText, sourceKind });
    const t1 = r.rows.find((x) => x.topic_key === 'k-t1')!;
    expect(t1.shadow).toBe('would-publish-if-certified');
  });
  // Final review item 3.
  const unanimous = () => new Map<number, unknown>([1, 2, 3].map((s) => [s, file(s, [row('t1', 4), row('t2', null)])]));
  it('sends a chair resting only on news to review (news-only-basis)', () => {
    const t1 = buildCodingReport({ context, files: unanimous(), snapshotText, sourceKind: new Map([['s1', 'news']]) }).rows.find((x) => x.topic_key === 'k-t1')!;
    expect(t1.shadow).toBe('would-review');
    expect(t1.shadow_reasons).toContain('news-only-basis');
  });
  it('sends a chair resting on a pointer to review (rests-on-pointer)', () => {
    const t1 = buildCodingReport({ context, files: unanimous(), snapshotText, sourceKind: new Map([['s1', 'pointer']]) }).rows.find((x) => x.topic_key === 'k-t1')!;
    expect(t1.confirm).toContain('rests-on-pointer');
    expect(t1.shadow).toBe('would-review');
  });
  it('carries an information-only seed flag from s1Leads, never touching shadow/shadow_reasons', () => {
    const files = new Map<number, unknown>([
      [1, file(1, [row('t1', 4), row('t2', 2)])],
      [2, file(2, [row('t1', 4), row('t2', 3)])],
      [3, file(3, [row('t1', 4), row('t2', 2)])],
    ]);
    const s1Leads: S1Lead[] = [{ topic_id: 't1', topic_key: 'k-t1', season_number: 1, value: 4, pin_revision_id: 'r0', reasoning: 'r', sources: [], seed: 'stale' }];
    const withLeads = buildCodingReport({ context, files, snapshotText, sourceKind, s1Leads });
    const withoutLeads = buildCodingReport({ context, files, snapshotText, sourceKind });
    const t1 = withLeads.rows.find((x) => x.topic_key === 'k-t1')!;
    const t2 = withLeads.rows.find((x) => x.topic_key === 'k-t2')!;
    expect(t1.seed).toBe('stale');
    expect(t2.seed).toBe('none');
    for (const key of ['t1', 't2']) {
      const a = withLeads.rows.find((x) => x.topic_key === `k-${key}`)!;
      const b = withoutLeads.rows.find((x) => x.topic_key === `k-${key}`)!;
      expect(a.shadow).toEqual(b.shadow);
      expect(a.shadow_reasons).toEqual(b.shadow_reasons);
    }
  });
});

// Final review fix 1 (ruling 2026-09-26, "Per group"): the D1 pair from confirm.test.ts, submitted as
// a coder file by three identical coders, must pass the validator AND CONFIRM end to end.
describe('D1 pair end to end (validator + CONFIRM)', () => {
  const st = new Map([
    ['vote', 'H.B. 11 (2022). Utah State Senate roll call. Ayes Count 21 Noes Count 8 Ayes Adams J. S., Bramble, Cullimore. Noes Riebe'],
    ['bill', 'H.B. 11 (2022). The bill requires students to compete on teams matching their sex at birth.'],
  ]);
  const kinds = new Map([['vote', 'public-record'], ['bill', 'public-record']]);
  const vote: Passage = { ...P, snapshot_id: 'vote', instrument: 'H.B. 11 (2022)', record_kind: 'vote', provision_quote: null,
    actor_quote: 'Ayes Adams J. S., Bramble, Cullimore', tally_quote: 'Ayes Count 21 Noes Count 8' };
  const bill: Passage = { ...P, snapshot_id: 'bill', instrument: 'H.B. 11 (2022)', record_kind: 'vote', actor_quote: null, tally_quote: null,
    provision_quote: 'requires students to compete on teams matching their sex at birth' };
  const d1 = (topic_id: string): CoderRow => ({ ...row(topic_id, 4), passages: [vote, bill], rests_on: ['vote', 'bill'] });
  const blank = (topic_id: string): CoderRow => ({ ...row(topic_id, null), passages: [] });
  it('yields no validator errors and no CONFIRM findings for the row', () => {
    const files = new Map<number, unknown>([1, 2, 3].map((s) => [s, file(s, [d1('t1'), blank('t2')])]));
    const r = buildCodingReport({ context, files, snapshotText: st, sourceKind: kinds });
    expect(r.validity).toEqual([1, 2, 3].map((slot) => ({ slot, fileErrors: [], rowErrors: 0 })));
    const t1 = r.rows.find((x) => x.topic_key === 'k-t1')!;
    expect(t1.outcome.kind).toBe('unanimous-chair');
    expect(t1.confirm).toEqual([]);
    expect(t1.shadow).toBe('would-publish-if-certified');
  });
  it('a record passage with no matching source profile fails closed as no-source-profile', () => {
    const files = new Map<number, unknown>([1, 2, 3].map((s) => [s, file(s, [d1('t1'), blank('t2')])]));
    const snapshotUrl = new Map([['vote', 'https://nowhere.test/vote'], ['bill', 'https://nowhere.test/bill']]);
    const withProfiles = buildCodingReport({ context, files, snapshotText: st, sourceKind: kinds, snapshotUrl, profiles: [] });
    const t1 = withProfiles.rows.find((x) => x.topic_key === 'k-t1')!;
    expect(t1.confirm).toContain('no-source-profile');
    expect(t1.shadow).toBe('would-review');
    expect(t1.profiles).toEqual([]);
    expect(withProfiles.noProfileHosts).toEqual({ 'nowhere.test': 1 });

    const withoutProfiles = buildCodingReport({ context, files, snapshotText: st, sourceKind: kinds });
    const t1b = withoutProfiles.rows.find((x) => x.topic_key === 'k-t1')!;
    expect(t1b.profiles).toEqual([]);
    expect(withoutProfiles.noProfileHosts).toEqual({});
  });
});

