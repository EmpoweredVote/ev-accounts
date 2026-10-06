import { describe, it, expect } from 'vitest';
import { evidenceTier, textsOverlap } from './evidenceTier.js';
import type { Passage } from './coderLabel.js';

const rec = (id: string, instrument: string, over: Partial<Passage> = {}): Passage => ({
  snapshot_id: id, v1_attribution: 'own-act', v2_relevance: 'on-question', v3_class: 'record',
  v4_shape: 'chair-shaped', v5_time: 'in-term', date: '2022-03-25', instrument, provision_quote: 'q',
  record_kind: 'vote', actor_quote: 'a', tally_quote: 'voted 21-8', ...over,
});
const stmt = (id: string, date: string | null, over: Partial<Passage> = {}): Passage => ({
  snapshot_id: id, v1_attribution: 'own-words', v2_relevance: 'on-question', v3_class: 'statement-answer',
  v4_shape: 'chair-shaped', v5_time: 'in-term', date, instrument: null, provision_quote: null, ...over,
});
const row = (passages: Passage[], v6_value: number | null = 4) =>
  ({ passages, rests_on: passages.map((p) => p.snapshot_id), v6_value });

describe('evidenceTier', () => {
  it('one source is single-source', () => expect(evidenceTier(row([rec('a', 'HB 11')])).tier).toBe('single-source'));
  it('a blank has no tier', () => expect(evidenceTier(row([rec('a', 'HB 11'), stmt('b', '2024-05-01')], null))).toEqual({ tier: null, sources: [] }));
  it('two different instruments corroborate', () =>
    expect(evidenceTier(row([rec('a', 'HB 11'), rec('b', 'SB 5')])).tier).toBe('corroborated'));
  it('vote page + bill text on one instrument are one source', () =>
    expect(evidenceTier(row([rec('a', 'H.B. 11 (2022)'), rec('b', 'HB 11 (2022)', { record_kind: 'sponsor' })])).tier).toBe('single-source'));
  it('a record and a statement on a different occasion corroborate', () =>
    expect(evidenceTier(row([rec('a', 'HB 11'), stmt('b', '2024-05-01')])).tier).toBe('corroborated'));
  it('two statements on two days corroborate', () =>
    expect(evidenceTier(row([stmt('a', '2024-05-01'), stmt('b', '2025-02-10', { v3_class: 'statement-other' })])).tier).toBe('corroborated'));
  it('two reports of one statement (same day) are one source', () =>
    expect(evidenceTier(row([stmt('a', '2024-05-01'), stmt('b', '2024-05-01', { v3_class: 'statement-other' })])).tier).toBe('single-source'));
  it('undated statements cannot show independence', () =>
    expect(evidenceTier(row([stmt('a', null), stmt('b', null)])).tier).toBe('single-source'));
  it('a coarse date joins the full date it contains', () =>
    expect(evidenceTier(row([stmt('a', '2024-05-01'), stmt('b', '2024-05')])).tier).toBe('single-source'));
  it('own explanation of a vote is the same act (owed ruling)', () =>
    expect(evidenceTier(row([rec('a', 'HB 11'), stmt('b', '2022-03-26', { instrument: 'H.B. 11' })])).tier).toBe('single-source'));
  it('a source that does not stand alone does not count (direction-only)', () =>
    expect(evidenceTier(row([rec('a', 'HB 11'), rec('b', 'SB 5', { v4_shape: 'direction-only' })])).tier).toBe('single-source'));
  it('a vote with no tally does not count', () =>
    expect(evidenceTier(row([rec('a', 'HB 11'), rec('b', 'SB 5', { tally_quote: null })])).tier).toBe('single-source'));
  it('only the shared sources count when a subset is passed', () =>
    expect(evidenceTier(row([rec('a', 'HB 11'), rec('b', 'SB 5')]), ['a']).tier).toBe('single-source'));
});

describe('evidenceTier — two statements on one day (ruling 2026-10-06)', () => {
  const DAY = '2024-05-01';
  const debate = 'Moderator asked about rent. I will cap annual rent increases at five percent for every tenant in the city.';
  const survey = 'Question 4, housing. My plan funds new public housing on city land and expands the voucher program next year.';
  const ctx = (kinds: Record<string, string>, texts: Record<string, string>) =>
    ({ sourceKind: new Map(Object.entries(kinds)), snapshotText: new Map(Object.entries(texts)) });
  const two = row([stmt('a', DAY), stmt('b', DAY)]);

  it('two first-party pages with different words are two occasions', () =>
    expect(evidenceTier(two, undefined, ctx({ a: 'transcript', b: 'own-site' }, { a: debate, b: survey })).tier).toBe('corroborated'));
  it('one page reprinting the other is one occasion (check 3)', () =>
    expect(evidenceTier(two, undefined, ctx({ a: 'transcript', b: 'own-site' }, { a: debate, b: `Full remarks: ${debate}` })).tier).toBe('single-source'));
  it('news that day adds no source (check 1)', () =>
    expect(evidenceTier(two, undefined, ctx({ a: 'own-site', b: 'news' }, { a: debate, b: survey })).tier).toBe('single-source'));
  it('a pointer adds no source (check 1)', () =>
    expect(evidenceTier(two, undefined, ctx({ a: 'own-site', b: 'pointer' }, { a: debate, b: survey })).tier).toBe('single-source'));
  it('unknown text cannot rule out overlap', () =>
    expect(evidenceTier(two, undefined, ctx({ a: 'transcript', b: 'own-site' }, { a: debate })).tier).toBe('single-source'));
  it('no source kinds: same-day statements collapse', () =>
    expect(evidenceTier(two).tier).toBe('single-source'));
  it('textsOverlap needs a shared run of 8 words', () => {
    expect(textsOverlap('one two three four five six', 'zero one two three four five six')).toBe(true);
    expect(textsOverlap('I support rent caps', 'I oppose new taxes')).toBe(false);
    expect(textsOverlap('a one two three four five six seven eight b', 'x one two three four five six seven eight y')).toBe(true);
  });
});
