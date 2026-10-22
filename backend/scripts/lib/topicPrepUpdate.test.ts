import { describe, it, expect } from 'vitest';
import { storyName, statusLabel, formatUpdate, type TopicPrepState } from './topicPrepUpdate.js';

const base: TopicPrepState = {
  topicKey: 'school-vouchers',
  stage: '2',
  path: 'source',
  seatRateBefore: 0.4,
  seatRateAfter: 0.75,
  blockedOn: 'nothing',
  nextStep: 'Run the source sweep for the remaining jurisdictions',
  owed: ['Ruling on the Q3 scope', 'Two source pages'],
  disputesOpen: 2,
  expertQueue: 3,
  revisionId: 'rev-123',
  researchFolder: 'research/s3/school-vouchers',
};

describe('storyName', () => {
  it('uses the em dash form', () => expect(storyName('school-vouchers')).toBe('S3 topic prep — school-vouchers'));
});

describe('statusLabel', () => {
  it('done is Done', () => expect(statusLabel({ ...base, stage: 'done' })).toBe('Done'));
  it('a blocker is Blocked', () => expect(statusLabel({ ...base, blockedOn: 'ruling' })).toBe('Blocked'));
  it('parked is Blocked', () => expect(statusLabel({ ...base, stage: 'parked' })).toBe('Blocked'));
  it('otherwise In Progress', () => expect(statusLabel(base)).toBe('In Progress'));
  it('done wins over a leftover blocker', () => expect(statusLabel({ ...base, stage: 'done', blockedOn: 'ruling' })).toBe('Done'));
});

describe('formatUpdate', () => {
  it('renders a full state in the fixed line order', () => {
    expect(formatUpdate(base)).toBe(
      [
        'Stage: 2',
        'Path: source',
        'Seat rate: 40% → 75%',
        'Blocked on: nothing',
        'Next: Run the source sweep for the remaining jurisdictions',
        'Owed:',
        '- Ruling on the Q3 scope',
        '- Two source pages',
        'Disputes open: 2',
        'Expert queue: 3',
        'Revision: rev-123',
        'Folder: research/s3/school-vouchers',
      ].join('\n'),
    );
  });
  it('renders 0.75 and null as "75% → —"', () =>
    expect(formatUpdate({ ...base, seatRateBefore: 0.75, seatRateAfter: null })).toContain('Seat rate: 75% → —'));
  it('renders an empty owed list as "Owed: none"', () => expect(formatUpdate({ ...base, owed: [] })).toContain('Owed: none'));
  it('never prints undefined, even with optional fields absent', () => {
    const out = formatUpdate({ ...base, path: undefined, seatRateBefore: undefined, seatRateAfter: undefined, revisionId: undefined });
    expect(out).not.toContain('undefined');
    expect(out).toContain('Seat rate: — → —');
    expect(out).toContain('Path: —');
    expect(out).toContain('Revision: —');
  });
  it('is plain text with no Markdown table', () => expect(formatUpdate(base)).not.toContain('|'));
});
