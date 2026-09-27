import { describe, it, expect } from 'vitest';
import { profileDivergences } from './profileDivergence.js';
import { parseSourceProfile } from './sourceProfiles.js';
import type { CoderRow, Passage } from './coderLabel.js';

const profile = (chamber: string) => parseSourceProfile(`---
profile: test-votes
version: 2
scope: state:CA
body: legislature
match:
  url_prefixes: [https://votes.test/]
page_kind: vote
rules: { vote_block: aye-count, chamber: ${chamber}, name_format: surname }
seat_titles: { Senator: upper }
controls:
  - { batch: b, snapshot: x, person: Ana Wong, office_title: Senator, instrument: SB 9 (2024), record_kind: vote, actor_quote: x, tally_quote: null, expect: pass }
---
`, 'test.md');

// The generic rule reads the nearest chamber word before the actor ("Assembly"); word-before-floor
// reads the chamber of the floor that voted ("Senate"). So only the declared rule is right here.
const page = 'SB 9 (2024). Senate Floor Ayes 30 Noes 9 Assembly Concurrence Ayes Lee, Wong. The bill requires a thing.';
const P = (over: Partial<Passage> = {}): Passage => ({
  snapshot_id: 'v', v1_attribution: 'own-act', v2_relevance: 'on-question', v3_class: 'record', v4_shape: 'chair-shaped',
  v5_time: 'in-term', date: '2024-05-01', instrument: 'SB 9 (2024)', provision_quote: 'requires a thing',
  record_kind: 'vote', actor_quote: 'Lee, Wong', tally_quote: 'Ayes 30 Noes 9', ...over,
});
const row = (passages: Passage[], topic_id = 't1') => ({ topic_id, passages }) as unknown as CoderRow;
const base = { snapshotText: new Map([['v', page]]), snapshotUrl: new Map([['v', 'https://votes.test/sb9']]), fullName: 'Ana Wong', officeTitle: 'Senator' };

describe('profileDivergences', () => {
  it('records a real row where the declared rule and the generic rule disagree', () => {
    const d = profileDivergences({ ...base, validRows: new Map([[1, [row([P()])]]]), profiles: [profile('word-before-floor')] });
    expect(d).toEqual([{ slot: 1, topic_id: 't1', instrument: 'sb9(2024)', snapshots: [{ snapshot_id: 'v', url: 'https://votes.test/sb9', profile: 'test-votes@2' }],
      generic: ['chamber-not-evidenced'], profiled: [] }]);
  });
  it('records nothing when both rules agree', () =>
    expect(profileDivergences({ ...base, validRows: new Map([[1, [row([P()])]]]), profiles: [profile('nearest-before')] })).toEqual([]));
  it('skips a group with a page that has no profile (that is no-source-profile, not a divergence)', () =>
    expect(profileDivergences({ ...base, snapshotUrl: new Map([['v', 'https://elsewhere.test/x']]), validRows: new Map([[1, [row([P()])]]]),
      profiles: [profile('word-before-floor')] })).toEqual([]));
  it('ignores statement passages and checks every slot', () => {
    const d = profileDivergences({ ...base, validRows: new Map([[1, [row([P({ v3_class: 'statement-answer' })])]], [3, [row([P()], 't2')]]]),
      profiles: [profile('word-before-floor')] });
    expect(d.map((x) => [x.slot, x.topic_id])).toEqual([[3, 't2']]);
  });
  it('passes each snapshot\'s amendment_markup to the profiled run (a kept page is not amendment-markup-lost)', () => {
    const marked = parseSourceProfile(`---
profile: test-text
version: 1
scope: state:CA
body: legislature
match:
  url_prefixes: [https://votes.test/]
page_kind: vote
rules: { vote_block: aye-count, chamber: nearest-before, name_format: surname, amendment_text: marked }
seat_titles: { Senator: upper }
controls:
  - { batch: b, snapshot: x, person: Ana Wong, office_title: Senator, instrument: SB 9 (2024), record_kind: vote, actor_quote: x, tally_quote: null, expect: pass }
---
`, 'test.md');
    const amending = 'SB 9 (2024). Senate Floor Ayes 30 Noes 9 Ayes Lee, Wong. Section 1 is amended to read: The bill requires a thing.';
    const args = { ...base, snapshotText: new Map([['v', amending]]), validRows: new Map([[1, [row([P()])]]]), profiles: [marked] };
    expect(profileDivergences({ ...args, snapshotMarkup: new Map([['v', 'kept' as const]]) })).toEqual([]);
    expect(profileDivergences(args).map((x) => x.profiled)).toEqual([['amendment-markup-lost']]);
  });
});
