import { describe, it, expect } from 'vitest';
import { confirmRow, earliestStatementDate } from './confirm.js';
import type { SeatContext } from './coderPrompt.js';
import type { Passage } from './coderLabel.js';

const seat: SeatContext = {
  politician_id: 'p', full_name: 'J. Stuart Adams', level: 'state', mode: 'seated', office_id: 'o', office_title: 'State Senator',
  jurisdiction_names: ['Utah'], term_start: '2021-01-01', start_precision: 'day', term_end: null, election_date: null,
};
const text = new Map([['s1', 'Utah Senate President J. Stuart Adams led the override; the bill requires students to compete on teams matching their sex at birth.']]);
const P = (over: Partial<Passage> = {}): Passage => ({
  snapshot_id: 's1', v1_attribution: 'own-act', v2_relevance: 'on-question', v3_class: 'record', v4_shape: 'chair-shaped',
  v5_time: 'in-term', date: '2022-03-25', instrument: 'H.B. 11', provision_quote: 'requires students to compete on teams matching their sex at birth', ...over,
});
const run = (over: Partial<Parameters<typeof confirmRow>[0]> = {}) =>
  confirmRow({ seat, restsOnPassages: [P()], snapshotText: text, rowServedRevisionId: 'r1', bundleServedRevisionId: 'r1', ...over });

describe('earliestStatementDate (ruling Q4 proxy)', () => {
  it('seated: current term start minus 548 days', () => expect(earliestStatementDate(seat)).toBe('2019-07-03'));
  it('candidate: election date minus 548 days', () =>
    expect(earliestStatementDate({ ...seat, mode: 'candidate', term_start: null, election_date: '2026-11-03' })).toBe('2025-05-04'));
  it('unknown start → null', () => expect(earliestStatementDate({ ...seat, term_start: null })).toBeNull());
});

describe('confirmRow (spec §1.6)', () => {
  it('passes a clean in-term record with its provision on the page', () => expect(run()).toEqual([]));
  it('flags a snapshot that names neither the jurisdiction nor the office (namesake guard)', () =>
    expect(run({ snapshotText: new Map([['s1', 'Adams led the override; the bill requires students to compete on teams matching their sex at birth.']]) }))
      .toContain('identity-not-in-snapshot'));
  it('flags a record dated before the current term', () => expect(run({ restsOnPassages: [P({ date: '2019-02-01' })] })).toContain('record-before-term'));
  it('flags imprecise term dates rather than guessing (§4.10)', () =>
    expect(run({ seat: { ...seat, start_precision: 'year' }, restsOnPassages: [P({ date: '2021-03-01' })] })).toContain('dates-imprecise'));
  it('flags a statement older than the cycle window', () =>
    expect(run({ restsOnPassages: [P({ v3_class: 'statement-answer', date: '2018-05-01', provision_quote: null })] })).toContain('statement-out-of-cycle'));
  it('flags undated evidence', () => expect(run({ restsOnPassages: [P({ date: null })] })).toContain('undated-evidence'));
  it('flags a vote without its provision text on the page (vote ladder)', () =>
    expect(run({ restsOnPassages: [P({ provision_quote: null })] })).toContain('provision-missing'));
  it('flags a served-revision mismatch', () => expect(run({ rowServedRevisionId: 'r0' })).toContain('revision-drift'));
});
