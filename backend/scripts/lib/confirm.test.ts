import { describe, it, expect } from 'vitest';
import { confirmRow, confirmRowDetailed, earliestStatementDate } from './confirm.js';
import { parseSourceProfile } from './sourceProfiles.js';
import type { SeatContext } from './coderPrompt.js';
import type { Passage } from './coderLabel.js';

const seat: SeatContext = {
  politician_id: 'p', full_name: 'J. Stuart Adams', level: 'state', mode: 'seated', office_id: 'o', office_title: 'State Senator',
  jurisdiction_names: ['Utah'], term_start: '2021-01-01', start_precision: 'day', term_end: null, election_date: null,
};
const text = new Map([['s1', 'H.B. 11. Utah Senate President J. Stuart Adams led the override; the bill requires students to compete on teams matching their sex at birth.']]);
const P = (over: Partial<Passage> = {}): Passage => ({
  snapshot_id: 's1', v1_attribution: 'own-act', v2_relevance: 'on-question', v3_class: 'record', v4_shape: 'chair-shaped',
  v5_time: 'in-term', date: '2022-03-25', instrument: 'H.B. 11', provision_quote: 'requires students to compete on teams matching their sex at birth',
  record_kind: 'other-act', actor_quote: 'J. Stuart Adams led the override', ...over,
});
const kinds = new Map([['s1', 'public-record']]);
const run = (over: Partial<Parameters<typeof confirmRow>[0]> = {}) =>
  confirmRow({ seat, restsOnPassages: [P()], snapshotText: text, sourceKind: kinds, rowServedRevisionId: 'r1', bundleServedRevisionId: 'r1', ...over });

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
  it('flags a snapshot with a different person (person-not-in-snapshot)', () =>
    expect(run({
      restsOnPassages: [P({ actor_quote: 'Jane Roe voted for the override' })],
      snapshotText: new Map([['s1', 'Utah State Senator Jane Roe voted for the override; the bill requires students to compete on teams matching their sex at birth.']]),
    })).toContain('person-not-in-snapshot'));
  it('flags a record dated before the current term', () => expect(run({ restsOnPassages: [P({ date: '2019-02-01' })] })).toContain('record-before-term'));
  it('flags imprecise term dates rather than guessing (§4.10)', () =>
    expect(run({ seat: { ...seat, start_precision: 'year' }, restsOnPassages: [P({ date: '2021-03-01' })] })).toContain('dates-imprecise'));
  it('flags a statement older than the cycle window', () =>
    expect(run({ restsOnPassages: [P({ v3_class: 'statement-answer', date: '2018-05-01', provision_quote: null })] })).toContain('statement-out-of-cycle'));
  it('flags undated evidence', () => expect(run({ restsOnPassages: [P({ date: null })] })).toContain('undated-evidence'));
  it('flags a vote without its provision text on the page (vote ladder)', () =>
    expect(run({ restsOnPassages: [P({ provision_quote: null })] })).toContain('provision-missing'));
  it('flags a served-revision mismatch', () => expect(run({ rowServedRevisionId: 'r0' })).toContain('revision-drift'));
  it('flags a record in candidate mode (record-not-this-office)', () =>
    expect(run({ seat: { ...seat, mode: 'candidate', term_start: null, election_date: '2026-11-03' } }))
      .toContain('record-not-this-office'));
  it('flags statement with imprecise seated term start (dates-imprecise for statement)', () =>
    expect(run({ seat: { ...seat, start_precision: 'year' }, restsOnPassages: [P({ v3_class: 'statement-answer', date: '2022-01-01', provision_quote: null })] }))
      .toContain('dates-imprecise'));
  it('passes a long snapshot with name only near the end (offset scan coverage)', () => {
    const longText = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '.repeat(11) + 'H.B. 11. Utah Senate President J. Stuart Adams led the override; the bill requires students to compete on teams matching their sex at birth.';
    expect(longText.length).toBeGreaterThan(650);
    expect(run({ snapshotText: new Map([['s1', longText]]) })).toEqual([]);
  });
  it('flags undated passage with no name (both undated-evidence and person-not-in-snapshot)', () =>
    expect(run({ snapshotText: new Map([['s1', 'Jane Roe voted for the bill.']]), restsOnPassages: [P({ date: null, provision_quote: null })] }))
      .toContain('undated-evidence')
      .and.toContain('person-not-in-snapshot'));
  // Final review item 1: a USPS code ('UT', 'IN') substring-matched almost every page.
  const noJurisdiction = new Map([['s1', 'J. Stuart Adams said but the bill requires students to compete on teams matching their sex at birth.']]);
  it.each([['UT'], ['Utah'], ['IN']])('flags identity when jurisdiction %s is not on the page as a word', (j) =>
    expect(run({ seat: { ...seat, jurisdiction_names: [j], office_title: 'State Senator' }, snapshotText: noJurisdiction }))
      .toContain('identity-not-in-snapshot'));
  it('does not match a jurisdiction inside a longer word (Utah vs Utahns)', () =>
    expect(run({ snapshotText: new Map([['s1', 'Utahns heard J. Stuart Adams: the bill requires students to compete on teams matching their sex at birth.']]) }))
      .toContain('identity-not-in-snapshot'));
  it('matches a jurisdiction on word boundaries', () =>
    expect(run({ snapshotText: new Map([['s1', 'In Utah, J. Stuart Adams led the override; the bill requires students to compete on teams matching their sex at birth.']]) }))
      .not.toContain('identity-not-in-snapshot'));
  // Final review item 3: spec 5.4 — a pointer is never evidence.
  it('flags a chair that rests on a pointer source', () =>
    expect(run({ sourceKind: new Map([['s1', 'pointer']]) })).toContain('rests-on-pointer'));
  it('flags a rests_on source with no known kind (fail closed)', () =>
    expect(run({ sourceKind: new Map() })).toContain('rests-on-pointer'));
  it('does not flag a news source as a pointer', () =>
    expect(run({ sourceKind: new Map([['s1', 'news']]) })).not.toContain('rests-on-pointer'));
});

describe('record groups (D1)', () => {
  const t2 = new Map([...text,
    // A roll call prints the member's initials after a common surname ('Adams J. S.'); a bare 'Adams'
    // is a namesake risk and fails closed (final review fix 2 — see the test below).
    ['vote', 'H.B. 11 (2022). Utah State Senate roll call. Ayes Count 21 Noes Count 8 Ayes Adams J. S., Bramble, Cullimore. Noes Riebe'],
    ['bill', 'H.B. 11 (2022). The bill requires students to compete on teams matching their sex at birth.']]);
  const vote = P({ snapshot_id: 'vote', instrument: 'H.B. 11 (2022)', record_kind: 'vote', provision_quote: null,
    actor_quote: 'Ayes Adams J. S., Bramble, Cullimore', tally_quote: 'Ayes Count 21 Noes Count 8' });
  const bill = P({ snapshot_id: 'bill', instrument: 'H.B. 11 (2022)', record_kind: 'vote', actor_quote: null, tally_quote: null,
    provision_quote: 'requires students to compete on teams matching their sex at birth', date: '2022-03-25' });
  const kinds = new Map([['vote', 'public-record'], ['bill', 'public-record']]);
  it('a vote page + bill text pair passes (no person/provision findings on the bill page)', () =>
    expect(run({ restsOnPassages: [vote, bill], snapshotText: t2, sourceKind: kinds })).toEqual([]));
  it('a bare common surname on the vote page is name-collision (namesake guard, fix 2)', () => {
    const bare = new Map([...t2, ['vote', 'H.B. 11 (2022). Utah State Senate roll call. Ayes Count 21 Noes Count 8 Ayes Adams, Bramble, Cullimore. Noes Riebe']]);
    expect(run({ restsOnPassages: [{ ...vote, actor_quote: 'Ayes Adams, Bramble, Cullimore' }, bill], snapshotText: bare, sourceKind: kinds }))
      .toEqual(['name-collision']);
  });
  it('a House roll call cannot stand for a Senator (chamber-not-evidenced, fix 2)', () => {
    const house = new Map([...t2, ['vote', 'H.B. 11 (2022). Utah House of Representatives roll call. Ayes Count 50 Noes Count 20 Ayes Adams J. S., Barlow. Noes Riebe. Utah']]);
    expect(run({ restsOnPassages: [{ ...vote, actor_quote: 'Ayes Adams J. S., Barlow', tally_quote: 'Ayes Count 50 Noes Count 20' }, bill], snapshotText: house, sourceKind: kinds }))
      .toEqual(['chamber-not-evidenced']);
  });
  it('the bill page alone is not a vote', () =>
    expect(run({ restsOnPassages: [bill], snapshotText: t2, sourceKind: kinds })).toEqual(expect.arrayContaining(['vote-not-evidenced'])));
  it('record-before-term uses the actor (vote) date, not the bill-text date', () =>
    expect(run({ restsOnPassages: [vote, { ...bill, date: '2019-01-01' }], snapshotText: t2, sourceKind: kinds })).not.toContain('record-before-term'));

  it('two record groups (two instruments) are judged separately: the group missing its vote page still fails, the valid group adds nothing extra', () => {
    const otherBill = P({ snapshot_id: 'other-bill', instrument: 'S.B. 22 (2022)', record_kind: 'vote',
      actor_quote: null, tally_quote: null, provision_quote: 'requires students to compete on teams matching their sex at birth', date: '2022-03-25' });
    const t3 = new Map([...t2, ['other-bill', 'S.B. 22 (2022). The bill requires students to compete on teams matching their sex at birth.']]);
    const k3 = new Map([...kinds, ['other-bill', 'public-record']]);
    const findings = run({ restsOnPassages: [vote, bill, otherBill], snapshotText: t3, sourceKind: k3 });
    // The S.B. 22 group has no vote page, so its own finding must appear.
    expect(findings).toEqual(expect.arrayContaining(['vote-not-evidenced']));
    // The H.B. 11 group (vote + bill) is valid on its own (per the test above) and must not
    // contribute any of its own possible findings just because it now shares the row with a bad group.
    expect(findings).not.toContain('tally-unreadable');
    expect(findings).not.toContain('near-unanimous-vote');
    expect(findings).not.toContain('instrument-mismatch');
  });
});

describe('source profiles in CONFIRM', () => {
  const profile = parseSourceProfile(`---
profile: test-votes
version: 3
scope: state:UT
body: legislature
match:
  url_prefixes: [https://le.utah.gov/votes/]
page_kind: vote
rules: { vote_block: aye-count, chamber: nearest-before, name_format: surname }
seat_titles: { Senator: upper }
controls:
  - { batch: b, snapshot: s1, person: J. Stuart Adams, office_title: Senator, instrument: H.B. 11 (2022), record_kind: vote, actor_quote: x, tally_quote: null, expect: pass }
---
`, 'test.md');
  const base = { seat, snapshotText: text, sourceKind: kinds, rowServedRevisionId: 'r1', bundleServedRevisionId: 'r1' };
  it('a record passage whose URL matches no profile → no-source-profile', () => {
    const f = confirmRow({ ...base, restsOnPassages: [P({})], snapshotUrl: new Map([['s1', 'https://elsewhere.gov/x']]), profiles: [profile] });
    expect(f).toContain('no-source-profile');
  });
  it('a record passage with no URL at all → no-source-profile (fail closed)', () =>
    expect(confirmRow({ ...base, restsOnPassages: [P({})], snapshotUrl: new Map(), profiles: [profile] })).toContain('no-source-profile'));
  it('a matched profile adds nothing and is reported as profile@version', () => {
    const r = confirmRowDetailed({ ...base, restsOnPassages: [P({})], snapshotUrl: new Map([['s1', 'https://le.utah.gov/votes/hb11']]), profiles: [profile] });
    expect(r.findings).not.toContain('no-source-profile');
    expect(r.profiles).toEqual(['test-votes@3']);
    expect(r.findings).toEqual(confirmRow({ ...base, restsOnPassages: [P({})] }));
  });
  it('without profiles, no lookup and no no-source-profile (other checks unchanged)', () =>
    expect(confirmRow({ ...base, restsOnPassages: [P({})] })).not.toContain('no-source-profile'));
});
