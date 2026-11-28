import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { checkRollCall, presentAt } from './checks.js';
import type { NameFile, TermSpan } from './names.js';
import { parseMinutes } from './onboard/minutes.js';
import type { FeedItem, MinutesParse, MinutesRollCall } from './types.js';

// Fixture ids stand in for politician ids. Names and term dates come from the
// Bloomington council roster (local-inventory/bloomington-in/roster.json).
const roster: { id: string; variants: string[]; spans: [string, string | null][] }[] = [
  { id: 'p-flaherty', variants: ['Matt Flaherty', 'Flaherty'], spans: [['2020-01-01', null]] },
  { id: 'p-sandberg', variants: ['Susan Sandberg', 'Sandberg'], spans: [['2020-01-01', '2023-12-31']] },
  { id: 'p-asare', variants: ['Isak Nti Asare', 'Asare'], spans: [['2024-01-02', null]] },
  { id: 'p-sims', variants: ['Jim Sims', 'Sims'], spans: [['2020-01-01', '2023-12-31']] },
  { id: 'p-ruff', variants: ['Andy Ruff', 'Ruff'], spans: [['2024-01-02', null]] },
  {
    id: 'p-rosenbarger',
    variants: ['Kate Rosenbarger', 'Rosenbarger'],
    spans: [['2020-01-01', '2023-12-31'], ['2024-01-02', null]],
  },
  {
    id: 'p-piedmont-smith',
    variants: ['Isabel Piedmont-Smith', 'Piedmont-Smith'],
    spans: [['2020-01-01', '2023-12-31'], ['2024-01-02', null]],
  },
  { id: 'p-sgambelluri', variants: ['Sue Sgambelluri', 'Sgambelluri'], spans: [['2020-01-01', '2023-12-31']] },
  { id: 'p-smith', variants: ['Ron Smith', 'Smith'], spans: [['2020-01-01', '2023-12-31']] },
  { id: 'p-stosberg', variants: ['Hopi Stosberg', 'Stosberg'], spans: [['2024-01-02', null]] },
  { id: 'p-rollo', variants: ['Dave Rollo', 'Rollo'], spans: [['2020-01-01', null]] },
  { id: 'p-rana', variants: ['Shruti Rana', 'Rana'], spans: [['2024-01-02', '2024-02-07']] },
  { id: 'p-daily', variants: ['Courtney Daily', 'Daily'], spans: [['2024-03-02', null]] },
  { id: 'p-volan', variants: ['Stephen Volan', 'Volan'], spans: [['2020-01-01', '2023-12-31']] },
  { id: 'p-zulich', variants: ['Sydney Zulich', 'Zulich'], spans: [['2024-01-02', null]] },
];

const names: NameFile = {
  city: 'place:1805860',
  members: roster.map((r) => ({ politicianId: r.id, onboardId: null, variants: r.variants })),
};
const terms: TermSpan[] = roster.flatMap((r) => r.spans.map(([start, end]) => ({ politicianId: r.id, start, end })));

function seatedOn(date: string): number {
  return new Set(terms.filter((t) => t.start <= date && (t.end === null || date <= t.end)).map((t) => t.politicianId))
    .size;
}

function load(date: string): MinutesParse {
  const text = readFileSync(new URL(`./onboard/__fixtures__/minutes/${date}.txt`, import.meta.url), 'utf8');
  return parseMinutes(text, date);
}

function rcOf(parse: MinutesParse, item: string, question: string): MinutesRollCall {
  const rc = parse.rollCalls.find((r) => r.itemNumber === item && r.question === question);
  if (!rc) throw new Error(`fixture has no ${item} ${question}`);
  return rc;
}

function ctx(parse: MinutesParse, extra: { feed?: Map<string, FeedItem>; knownItems?: Set<string> } = {}) {
  return {
    names,
    terms,
    seatedCount: seatedOn(parse.meetingDate),
    feed: extra.feed ?? new Map<string, FeedItem>(),
    knownItems: extra.knownItems ?? new Set(parse.rollCalls.map((r) => r.itemNumber)),
  };
}

function feedItem(itemNumber: string, final: FeedItem['final']): FeedItem {
  return {
    feedId: 1,
    type: 'Resolution',
    number: itemNumber,
    itemNumber,
    title: 't',
    synopsis: null,
    status: 's',
    final,
    firstActionDate: null,
    pageUrl: 'https://example.invalid/item',
  };
}

function positions(result: ReturnType<typeof checkRollCall>) {
  if (!result.ok) throw new Error(`expected ok, got ${result.cause}: ${result.detail}`);
  return Object.fromEntries(result.votes.map((v) => [v.politicianId, [v.position, v.workedOut]]));
}

describe('presentAt', () => {
  it('drops members marked absent', () => {
    const p = load('2026-10-07');
    const r = presentAt(p, rcOf(p, 'App Ord 2026-02', 'Amendment 03'));
    if ('error' in r) throw new Error(r.detail);
    expect(r.present).toHaveLength(7);
    expect(r.notPresent).toEqual([
      { name: 'Dave Rollo', kind: 'absent' },
      { name: 'Kate Rosenbarger', kind: 'absent' },
    ]);
  });

  it('a note with no place fails every roll call', () => {
    const p = load('2026-10-07');
    p.notes.push({ kind: 'left', nameAsPrinted: 'Ruff', at: null });
    expect(presentAt(p, p.rollCalls[0])).toMatchObject({ error: 'unplaced_note' });
  });

  it('a member with an arrival note is not present before it', () => {
    const p = load('2022-05-04');
    // Fixture: Volan arrives before event 0, so he is present at every roll call.
    const r0 = presentAt(p, p.rollCalls[0]);
    if ('error' in r0) throw new Error(r0.detail);
    expect(r0.present).toContain('Stephen Volan');
    // Moved to before roll call 1: he has not yet arrived at roll call 0.
    p.notes = [{ kind: 'arrived', nameAsPrinted: 'Stephen Volan', at: p.rollCalls[1].index }];
    const r = presentAt(p, p.rollCalls[0]);
    if ('error' in r) throw new Error(r.detail);
    expect(r.present).not.toContain('Stephen Volan');
    expect(r.notPresent).toEqual([{ name: 'Stephen Volan', kind: 'arrived' }]);
    const r1 = presentAt(p, p.rollCalls[1]);
    if ('error' in r1) throw new Error(r1.detail);
    expect(r1.present).toContain('Stephen Volan');
  });

  it('left removes for the rest of the meeting', () => {
    const p = load('2026-10-07');
    p.notes = [{ kind: 'left', nameAsPrinted: 'Andy Ruff', at: 3 }];
    const before = presentAt(p, p.rollCalls[2]);
    const after = presentAt(p, p.rollCalls[9]);
    if ('error' in before || 'error' in after) throw new Error('unexpected error');
    expect(before.present).toContain('Andy Ruff');
    expect(after.notPresent).toContainEqual({ name: 'Andy Ruff', kind: 'left' });
  });

  it('out of the room in the notes lasts only for the roll call it is placed on', () => {
    const p = load('2026-10-07');
    p.notes = [{ kind: 'out_of_room', nameAsPrinted: 'Andy Ruff', at: 3 }];
    const on = presentAt(p, p.rollCalls[3]);
    const next = presentAt(p, p.rollCalls[4]);
    if ('error' in on || 'error' in next) throw new Error('unexpected error');
    expect(on.notPresent).toContainEqual({ name: 'Andy Ruff', kind: 'out_of_room' });
    expect(next.present).toContain('Andy Ruff');
  });

  it('a returned note ends out of the room', () => {
    const p = load('2026-10-07');
    p.notes = [
      { kind: 'out_of_room', nameAsPrinted: 'Andy Ruff', at: 3 },
      { kind: 'returned', nameAsPrinted: 'Andy Ruff', at: 3 },
    ];
    const on = presentAt(p, p.rollCalls[3]);
    if ('error' in on) throw new Error(on.detail);
    expect(on.present).toContain('Andy Ruff');
  });

  it('a returned note for a member marked absent cannot be placed', () => {
    const p = load('2026-10-07');
    p.notes = [{ kind: 'returned', nameAsPrinted: 'Dave Rollo', at: 2 }];
    expect(presentAt(p, p.rollCalls[2])).toMatchObject({ error: 'unplaced_note' });
  });

  it('a returned note for a member not yet arrived cannot be placed', () => {
    const p = load('2022-05-04');
    p.notes = [
      { kind: 'returned', nameAsPrinted: 'Stephen Volan', at: 0 },
      { kind: 'arrived', nameAsPrinted: 'Stephen Volan', at: 1 },
    ];
    expect(presentAt(p, p.rollCalls[0])).toMatchObject({ error: 'unplaced_note' });
  });

  it('a note in both the meeting notes and the roll call is applied once', () => {
    const p = load('2026-10-07');
    const out = { kind: 'out_of_room' as const, nameAsPrinted: 'Andy Ruff', at: 3 };
    p.notes = [out, { kind: 'returned', nameAsPrinted: 'Andy Ruff', at: 3 }];
    p.rollCalls[3].inlineNotes = [{ ...out }];
    const r = presentAt(p, p.rollCalls[3]);
    if ('error' in r) throw new Error(r.detail);
    expect(r.present).toContain('Andy Ruff');
  });

  it('an inline out-of-room note applies to that roll call only', () => {
    const p = load('2026-10-07');
    p.rollCalls[3].inlineNotes = [{ kind: 'out_of_room', nameAsPrinted: 'Andy Ruff', at: 3 }];
    const on = presentAt(p, p.rollCalls[3]);
    const next = presentAt(p, p.rollCalls[4]);
    if ('error' in on || 'error' in next) throw new Error('unexpected error');
    expect(on.notPresent).toContainEqual({ name: 'Andy Ruff', kind: 'out_of_room' });
    expect(next.present).toContain('Andy Ruff');
  });
});

describe('checkRollCall', () => {
  it('2026-10-07 Amendment 03: Ruff named yes, six worked out no, two absent', () => {
    const p = load('2026-10-07');
    const result = checkRollCall(rcOf(p, 'App Ord 2026-02', 'Amendment 03'), p, ctx(p));
    expect(result).toMatchObject({ ok: true, feedDisagreement: null });
    expect(positions(result)).toEqual({
      'p-ruff': ['yea', false],
      'p-asare': ['nay', true],
      'p-daily': ['nay', true],
      'p-flaherty': ['nay', true],
      'p-piedmont-smith': ['nay', true],
      'p-stosberg': ['nay', true],
      'p-zulich': ['nay', true],
      'p-rollo': ['absent', false],
      'p-rosenbarger': ['absent', false],
    });
  });

  it('a unanimous roll call works out every present member', () => {
    const p = load('2026-10-07');
    const result = checkRollCall(rcOf(p, 'Ord 2026-28', 'Final passage'), p, ctx(p));
    const pos = positions(result);
    expect(Object.values(pos).filter(([x, w]) => x === 'yea' && w === true)).toHaveLength(7);
  });

  it('tally mismatch', () => {
    const p = load('2026-10-07');
    const rc = { ...rcOf(p, 'App Ord 2026-02', 'Amendment 03'), tally: { yes: 1, no: 5, abstain: 0 } };
    expect(checkRollCall(rc, p, ctx(p))).toMatchObject({ ok: false, cause: 'tally_mismatch' });
  });

  it('more named names than the count is a tally mismatch', () => {
    const p = load('2026-10-07');
    const base = rcOf(p, 'App Ord 2026-02', 'Amendment 03');
    const rc = { ...base, named: [{ side: 'yes' as const, names: ['Ruff', 'Daily'] }] };
    expect(checkRollCall(rc, p, ctx(p))).toMatchObject({ ok: false, cause: 'tally_mismatch' });
  });

  it('a named voter who is not present is a tally mismatch', () => {
    const p = load('2026-10-07');
    const base = rcOf(p, 'App Ord 2026-02', 'Amendment 03');
    const rc = { ...base, named: [{ side: 'yes' as const, names: ['Rollo'] }] };
    expect(checkRollCall(rc, p, ctx(p))).toMatchObject({ ok: false, cause: 'tally_mismatch' });
  });

  it('unnamed abstentions cannot be assigned', () => {
    const p = load('2026-10-07');
    const base = rcOf(p, 'App Ord 2026-02', 'Amendment 03');
    const rc = { ...base, tally: { yes: 1, no: 5, abstain: 1 } };
    expect(checkRollCall(rc, p, ctx(p))).toMatchObject({ ok: false, cause: 'tally_mismatch' });
  });

  it('two unnamed sides with votes cannot be assigned', () => {
    const p = load('2026-10-07');
    const base = rcOf(p, 'App Ord 2026-02', 'Amendment 03');
    const rc = { ...base, named: [] };
    expect(checkRollCall(rc, p, ctx(p))).toMatchObject({ ok: false, cause: 'tally_mismatch' });
  });

  it('counts that do not add to the seated council are a tally mismatch', () => {
    const p = load('2026-10-07');
    const rc = rcOf(p, 'App Ord 2026-02', 'Amendment 03');
    expect(checkRollCall(rc, p, { ...ctx(p), seatedCount: 10 })).toMatchObject({
      ok: false,
      cause: 'tally_mismatch',
    });
  });

  it('a member who left is not voting and is not counted present', () => {
    const p = load('2026-10-07');
    p.notes = [{ kind: 'left', nameAsPrinted: 'Zulich', at: 2 }];
    const base = rcOf(p, 'App Ord 2026-02', 'Amendment 03');
    const rc = { ...base, tally: { yes: 1, no: 5, abstain: 0 } };
    const pos = positions(checkRollCall(rc, p, ctx(p)));
    expect(pos['p-zulich']).toEqual(['not_voting', false]);
    expect(pos['p-daily']).toEqual(['nay', true]);
  });

  it('a member not yet arrived is not voting', () => {
    const p = load('2022-05-04');
    p.notes = [{ kind: 'arrived', nameAsPrinted: 'Stephen Volan', at: p.rollCalls[1].index }];
    const rc = { ...p.rollCalls[0], tally: { yes: 0, no: 8, abstain: 0 } };
    const pos = positions(checkRollCall(rc, p, ctx(p)));
    expect(pos['p-volan']).toEqual(['not_voting', false]);
    expect(pos['p-sims']).toEqual(['nay', true]);
  });

  it('a note naming an unknown member fails', () => {
    const p = load('2026-10-07');
    p.notes = [{ kind: 'left', nameAsPrinted: 'Nobody', at: 9 }];
    const rc = rcOf(p, 'App Ord 2026-02', 'Amendment 03');
    expect(checkRollCall(rc, p, ctx(p))).toMatchObject({ ok: false, cause: 'unknown_name' });
  });

  it('unplaced departure fails', () => {
    const p = load('2026-10-07');
    p.notes.push({ kind: 'left', nameAsPrinted: 'Ruff', at: null });
    const rc = rcOf(p, 'App Ord 2026-02', 'Amendment 03');
    expect(checkRollCall(rc, p, ctx(p))).toMatchObject({ ok: false, cause: 'unplaced_note' });
  });

  it('unknown item fails', () => {
    const p = load('2026-10-07');
    const rc = rcOf(p, 'App Ord 2026-02', 'Amendment 03');
    const known = new Set(p.rollCalls.map((r) => r.itemNumber).filter((i) => i !== 'App Ord 2026-02'));
    expect(checkRollCall(rc, p, ctx(p, { knownItems: known }))).toMatchObject({ ok: false, cause: 'unknown_item' });
  });

  it('an unknown printed name fails', () => {
    const p = load('2026-10-07');
    const base = rcOf(p, 'App Ord 2026-02', 'Amendment 03');
    const rc = { ...base, named: [{ side: 'yes' as const, names: ['Nobody'] }] };
    expect(checkRollCall(rc, p, ctx(p))).toMatchObject({ ok: false, cause: 'unknown_name' });
  });

  it('a name with no term on the date fails as not seated', () => {
    const p = load('2026-10-07');
    const base = rcOf(p, 'App Ord 2026-02', 'Amendment 03');
    const rc = { ...base, named: [{ side: 'yes' as const, names: ['Volan'] }] };
    expect(checkRollCall(rc, p, ctx(p))).toMatchObject({ ok: false, cause: 'not_seated' });
  });

  it('an attendance name that does not resolve fails', () => {
    const p = load('2026-10-07');
    p.attendance[0] = { nameAsPrinted: 'Nobody Known', absent: false };
    const rc = rcOf(p, 'App Ord 2026-02', 'Amendment 03');
    expect(checkRollCall(rc, p, ctx(p))).toMatchObject({ ok: false, cause: 'unknown_name' });
  });

  it('a reasonable condition is checked like an amendment, without the vote list', () => {
    const p = load('2021-04-07');
    const rc = rcOf(p, 'Ord 21-07', 'Reasonable Condition 08');
    const feed = new Map([['Ord 21-07', feedItem('Ord 21-07', { date: '2021-04-07', outcome: 'passed', tally: { yes: 9, no: 0, abstain: 0 } })]]);
    const pos = positions(checkRollCall(rc, p, ctx(p, { feed })));
    expect(pos['p-rosenbarger']).toEqual(['yea', false]);
    expect(pos['p-volan']).toEqual(['yea', false]);
    expect(pos['p-smith']).toEqual(['nay', true]);
  });

  it('feed counts differ, minutes win', () => {
    const p = load('2021-05-19');
    const rc = rcOf(p, 'Res 21-09', 'Final passage');
    const feed = new Map([['Res 21-09', feedItem('Res 21-09', { date: '2021-05-19', outcome: 'passed', tally: { yes: 8, no: 0, abstain: 0 } })]]);
    const result = checkRollCall(rc, p, ctx(p, { feed }));
    expect(result).toMatchObject({ ok: true, feedDisagreement: 'feed 8-0, minutes 9-0' });
  });

  it('feed outcome differs: outcome conflict', () => {
    const p = load('2021-05-19');
    const rc = rcOf(p, 'Res 21-09', 'Final passage');
    const feed = new Map([['Res 21-09', feedItem('Res 21-09', { date: '2021-05-19', outcome: 'failed', tally: { yes: 9, no: 0, abstain: 0 } })]]);
    expect(checkRollCall(rc, p, ctx(p, { feed }))).toMatchObject({ ok: false, cause: 'outcome_conflict' });
  });

  it('a vetoed final action agrees with a passed vote', () => {
    const p = load('2021-05-19');
    const rc = rcOf(p, 'Res 21-09', 'Final passage');
    const feed = new Map([['Res 21-09', feedItem('Res 21-09', { date: '2021-05-19', outcome: 'vetoed', tally: { yes: 9, no: 0, abstain: 0 } })]]);
    expect(checkRollCall(rc, p, ctx(p, { feed }))).toMatchObject({ ok: true, feedDisagreement: null });
  });

  it('a vetoed final action conflicts with a failed vote', () => {
    const p = load('2022-05-04');
    const rc = rcOf(p, 'Ord 22-07', 'Final passage');
    const feed = new Map([['Ord 22-07', feedItem('Ord 22-07', { date: '2022-05-04', outcome: 'vetoed', tally: { yes: 0, no: 9, abstain: 0 } })]]);
    expect(checkRollCall(rc, p, ctx(p, { feed }))).toMatchObject({ ok: false, cause: 'outcome_conflict' });
  });

  it('a feed final from another meeting is not compared', () => {
    const p = load('2021-05-19');
    const rc = rcOf(p, 'Res 21-09', 'Final passage');
    const conflict = new Map([['Res 21-09', feedItem('Res 21-09', { date: '2021-06-02', outcome: 'failed', tally: { yes: 3, no: 6, abstain: 0 } })]]);
    expect(checkRollCall(rc, p, ctx(p, { feed: conflict }))).toMatchObject({ ok: true, feedDisagreement: null });
    const counts = new Map([['Res 21-09', feedItem('Res 21-09', { date: '2021-06-02', outcome: 'passed', tally: { yes: 8, no: 0, abstain: 0 } })]]);
    expect(checkRollCall(rc, p, ctx(p, { feed: counts }))).toMatchObject({ ok: true, feedDisagreement: null });
  });

  it('feed final agrees: no disagreement', () => {
    const p = load('2021-05-19');
    const rc = rcOf(p, 'Res 21-16', 'Final passage');
    const feed = new Map([['Res 21-16', feedItem('Res 21-16', { date: '2021-05-19', outcome: 'passed', tally: { yes: 6, no: 3, abstain: 0 } })]]);
    const result = checkRollCall(rc, p, ctx(p, { feed }));
    expect(result).toMatchObject({ ok: true, feedDisagreement: null });
    expect(positions(result)['p-rollo']).toEqual(['nay', false]);
    expect(positions(result)['p-sims']).toEqual(['yea', true]);
  });

  it('feed final with unreadable counts: outcome only', () => {
    const p = load('2021-05-19');
    const rc = rcOf(p, 'Res 21-09', 'Final passage');
    const feed = new Map([['Res 21-09', feedItem('Res 21-09', { date: '2021-05-19', outcome: 'passed', tally: null })]]);
    expect(checkRollCall(rc, p, ctx(p, { feed }))).toMatchObject({ ok: true, feedDisagreement: null });
  });

  it('no feed final for the item: still ok', () => {
    const p = load('2021-05-19');
    const rc = rcOf(p, 'Res 21-09', 'Final passage');
    const feed = new Map([['Res 21-09', feedItem('Res 21-09', null)]]);
    expect(checkRollCall(rc, p, ctx(p, { feed }))).toMatchObject({ ok: true, feedDisagreement: null });
  });
});

describe('R11: an "adopt" of an item that already passed at an earlier meeting', () => {
  // 2024-05-01 minutes: Res 2024-08 passed on 2024-04-03 (the feed's Final), was vetoed, and came back.
  const text = [
    'Councilmembers present: Isak Nti Asare, Courtney Daily, Isabel',
    'Piedmont-Smith, Dave Rollo, Kate Rosenbarger, Andy Ruff, Hopi',
    'Stosberg, Sydney Zulich',
    'Councilmembers present via Zoom: Matt Flaherty',
    'Councilmembers absent: none',
    '',
    'The motion to adopt Resolution 2024-08 received a roll call vote of     Vote to adopt Resolution 2024-08',
    'Ayes: 9, Nays: 0, Abstain: 0.                                            [7:50pm]',
  ].join('\n');

  it('is held, not stored as a second Final passage', () => {
    const p = parseMinutes(text, '2024-05-01');
    const rc = rcOf(p, 'Res 2024-08', 'Final passage');
    const feed = new Map([['Res 2024-08', feedItem('Res 2024-08', { date: '2024-04-03', outcome: 'passed', tally: { yes: 9, no: 0, abstain: 0 } })]]);
    const res = checkRollCall(rc, p, ctx(p, { feed }));
    expect(res).toMatchObject({ ok: false, cause: 'outcome_conflict' });
    expect(res.ok ? '' : res.detail).toMatch(/already passed on 2024-04-03/);
  });

  it('a Final passage on the feed\'s own Final date is still read', () => {
    const p = parseMinutes(text, '2024-05-01');
    const rc = rcOf(p, 'Res 2024-08', 'Final passage');
    const feed = new Map([['Res 2024-08', feedItem('Res 2024-08', { date: '2024-05-01', outcome: 'passed', tally: { yes: 9, no: 0, abstain: 0 } })]]);
    expect(checkRollCall(rc, p, ctx(p, { feed }))).toMatchObject({ ok: true });
  });
});

describe('R5: a vote whose subject came from the open motion', () => {
  const text = [
    'Councilmembers present: Isak Nti Asare, Courtney Daily, Isabel',
    'Piedmont-Smith, Dave Rollo, Kate Rosenbarger, Andy Ruff, Hopi',
    'Stosberg, Sydney Zulich',
    'Councilmembers absent: Matt Flaherty',
    '',
    '8.2. Resolution 2025-02',
    '',
    'Daily moved and Piedmont-Smith seconded to adopt Resolution 2025-02.',
    '',
    'There was no public comment.',
    '',
    'The motion received a roll call vote of Ayes: 8, Nays: 0, Abstain: 0.',
  ].join('\n');
  const final = (date: string, yes: number) =>
    new Map([['Res 2025-02', feedItem('Res 2025-02', { date, outcome: 'passed', tally: { yes, no: 0, abstain: 0 } })]]);

  it('is read when the feed\'s Final action has this date and tally', () => {
    const p = parseMinutes(text, '2025-02-19');
    const rc = rcOf(p, 'Res 2025-02', 'Final passage');
    expect(checkRollCall(rc, p, ctx(p, { feed: final('2025-02-19', 8) }))).toMatchObject({ ok: true, feedDisagreement: null });
  });

  it('is held when the feed\'s Final action has another tally, another date, or none', () => {
    const p = parseMinutes(text, '2025-02-19');
    const rc = rcOf(p, 'Res 2025-02', 'Final passage');
    for (const feed of [final('2025-02-19', 7), final('2025-03-05', 8), new Map([['Res 2025-02', feedItem('Res 2025-02', null)]])]) {
      expect(checkRollCall(rc, p, ctx(p, { feed }))).toMatchObject({ ok: false, cause: 'unparsed_roll_call' });
    }
  });
});
