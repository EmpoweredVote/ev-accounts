import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  layoutLines,
  minutesSentences,
  parseMinutes,
  parseRollCallSentence,
  rollCallOutcome,
  stripMargin,
} from './minutes.js';

const load = (date: string): string =>
  readFileSync(new URL(`./__fixtures__/minutes/${date}.txt`, import.meta.url), 'utf8');

const rc = (p: ReturnType<typeof parseMinutes>, itemNumber: string, question: string) =>
  p.rollCalls.filter((r) => r.itemNumber === itemNumber && r.question === question);

describe('parseMinutes 2026-10-07 (single-column minutes)', () => {
  const p = parseMinutes(load('2026-10-07'), '2026-10-07');

  it('reads attendance with names as printed and marks Rollo and Rosenbarger absent', () => {
    expect(p.attendance).toHaveLength(9);
    expect(p.attendance[0]).toEqual({ nameAsPrinted: 'Isak Nti Asare', absent: false });
    expect(p.attendance.filter((a) => a.absent).map((a) => a.nameAsPrinted)).toEqual([
      'Dave Rollo',
      'Kate Rosenbarger',
    ]);
    expect(p.attendance.map((a) => a.nameAsPrinted)).not.toContain('Nicole Bolden');
  });

  it('Amendment 03 to App Ord 2026-02: 1-6, Ruff named, FAILED', () => {
    const [r] = rc(p, 'App Ord 2026-02', 'Amendment 03');
    expect(r.tally).toEqual({ yes: 1, no: 6, abstain: 0 });
    expect(r.named).toEqual([{ side: 'yes', names: ['Ruff'] }]);
    expect(r.outcome).toBe('failed');
  });

  it('Amendment 18 names the two nays and passes', () => {
    const [r] = rc(p, 'App Ord 2026-02', 'Amendment 18');
    expect(r.named).toEqual([{ side: 'no', names: ['Daily', 'Stosberg'] }]);
    expect(r.outcome).toBe('passed');
  });

  it('Amendment 16 fails on the count alone (no FAILED printed)', () => {
    const [r] = rc(p, 'App Ord 2026-02', 'Amendment 16');
    expect(r.tally).toEqual({ yes: 2, no: 5, abstain: 0 });
    expect(r.named).toEqual([{ side: 'yes', names: ['Asare', 'Flaherty'] }]);
    expect(r.outcome).toBe('failed');
  });

  it('tabled and withdrawn amendments produce no roll call', () => {
    expect(rc(p, 'App Ord 2026-02', 'Amendment 05')).toHaveLength(0);
    expect(rc(p, 'App Ord 2026-02', 'Amendment 06')).toHaveLength(0);
  });

  it('reads final passage votes and numbers roll calls in order', () => {
    expect(rc(p, 'App Ord 2026-03', 'Final passage')).toHaveLength(1);
    expect(rc(p, 'Ord 2026-25', 'Final passage')).toHaveLength(1);
    expect(rc(p, 'Ord 2026-28', 'Final passage')).toHaveLength(1);
    expect(p.rollCalls).toHaveLength(14);
    expect(p.rollCalls.map((r) => r.index)).toEqual(p.rollCalls.map((_, i) => i));
  });

  it('has nothing unparsed', () => {
    expect(p.unparsed).toEqual([]);
    expect(p.meetingDate).toBe('2026-10-07');
  });
});

describe('out-of-room parenthetical is not a name list', () => {
  // In 2021-05-19 this tally belongs to a motion to introduce and read Ordinance 17-10 by title, a procedural
  // motion the parser ignores, so the sentence is checked on its own and the full parse must not record it.
  const text = load('2021-05-19');
  const sentence = minutesSentences(text).find((s) => s.includes('Ayes: 8 (Sims out of the room)'))!;

  it('reads the parenthetical as an inline note', () => {
    const t = parseRollCallSentence(sentence, 4);
    expect(t).not.toBeNull();
    expect(t!.tally).toEqual({ yes: 8, no: 0, abstain: 0 });
    expect(t!.named.find((n) => n.side === 'yes')).toBeUndefined();
    expect(t!.inlineNotes).toEqual([{ kind: 'out_of_room', nameAsPrinted: 'Sims', at: 4 }]);
  });

  it('the procedural vote is neither a roll call nor unparsed, and its note does not leak', () => {
    const p = parseMinutes(text, '2021-05-19');
    expect(p.rollCalls.some((r) => r.sentence.includes('Sims out of the room'))).toBe(false);
    expect(p.unparsed.some((s) => s.includes('Sims out of the room'))).toBe(false);
    expect(p.notes.some((n) => n.nameAsPrinted === 'Sims')).toBe(false);
  });
});

describe('2021-04-07: (Volan out of the room) after the tally', () => {
  const text = load('2021-04-07');
  const sentence = minutesSentences(text).find((s) => s.includes('(Volan out of the room)'))!;

  it('becomes an inline note, not abstain names', () => {
    const t = parseRollCallSentence(sentence, 2)!;
    expect(t.tally).toEqual({ yes: 8, no: 0, abstain: 0 });
    expect(t.named).toEqual([]);
    expect(t.inlineNotes).toEqual([{ kind: 'out_of_room', nameAsPrinted: 'Volan', at: 2 }]);
  });

  it('unparsed holds only roll-call sentences; known items are read', () => {
    const p = parseMinutes(text, '2021-04-07');
    expect(p.unparsed.every((s) => /roll call vote/.test(s))).toBe(true);
    expect(p.rollCalls.map((r) => `${r.itemNumber}|${r.question}`)).toEqual(
      expect.arrayContaining(['Res 21-07|Final passage', 'Ord 21-11|Amendment 01', 'Ord 21-12|Final passage']),
    );
  });

  it('Reasonable Condition 08 to Ord 21-07 is a roll call with its own subject', () => {
    const p = parseMinutes(text, '2021-04-07');
    const [r] = rc(p, 'Ord 21-07', 'Reasonable Condition 08');
    expect(r.tally).toEqual({ yes: 2, no: 7, abstain: 0 });
    expect(r.named).toEqual([{ side: 'yes', names: ['Rosenbarger', 'Volan'] }]);
    expect(r.outcome).toBe('failed');
  });

  it('reads a bare vote from the one margin heading "Vote to adopt Reasonable Condition 03 to Ordinance 21-07"', () => {
    const p = parseMinutes(text, '2021-04-07');
    const [r] = rc(p, 'Ord 21-07', 'Reasonable Condition 03');
    expect(r.tally).toEqual({ yes: 9, no: 0, abstain: 0 });
    expect(r.outcome).toBe('passed');
    expect(r.sentence).toContain('Vote to adopt Reasonable Condition 03 to Ordinance 21-07');
    expect(rc(p, 'Ord 21-07', 'Reasonable Condition 01')).toHaveLength(1);
  });

  it('a margin heading without a number ("Reasonable Condition as amended") leaves the vote unparsed', () => {
    const p = parseMinutes(text, '2021-04-07');
    expect(p.unparsed.length).toBeGreaterThan(0);
  });
});

describe('margin column does not corrupt roll call', () => {
  const p = parseMinutes(load('2021-05-05'), '2021-05-05');

  it('Amendment 02 to Ord 21-23 parses 9-0-0 without the margin text', () => {
    const [r] = rc(p, 'Ord 21-23', 'Amendment 02');
    expect(r.tally).toEqual({ yes: 9, no: 0, abstain: 0 });
    expect(r.sentence).not.toContain('[10:38pm]');
    expect(r.sentence).not.toContain('Vote to adopt');
    expect(r.outcome).toBe('passed');
    expect(p.unparsed).toEqual([]);
  });

  it('reads the comma-separated attendance across wrapped lines', () => {
    expect(p.attendance.map((a) => a.nameAsPrinted)).toEqual([
      'Matt Flaherty',
      'Isabel Piedmont-Smith',
      'Dave Rollo',
      'Kate Rosenbarger',
      'Susan Sandberg',
      'Sue Sgambelluri',
      'Jim Sims',
      'Ron Smith',
      'Stephen Volan',
    ]);
    expect(p.attendance.every((a) => !a.absent)).toBe(true);
  });
});

describe('departure before vote excludes member (2022-05-04 arrival and out-of-room notes)', () => {
  const p = parseMinutes(load('2022-05-04'), '2022-05-04');

  it('keeps one attendance entry per person on a comma-separated line', () => {
    expect(p.attendance).toHaveLength(9);
    expect(p.attendance.slice(-3).map((a) => a.nameAsPrinted)).toEqual(['Jim Sims', 'Ron Smith', 'Stephen Volan']);
  });

  it("places Volan's arrival before the first roll call after it", () => {
    const n = p.notes.find((x) => x.kind === 'arrived' && x.nameAsPrinted === 'Stephen Volan');
    expect(n).toBeDefined();
    expect(p.rollCalls.length).toBeGreaterThan(0);
    expect(n!.at).toBe(p.rollCalls[0].index);
  });

  it('drops "Flaherty was out of the room." notes that belong to read-by-title (voice) motions', () => {
    expect(p.notes.filter((x) => x.kind === 'out_of_room')).toEqual([]);
    const ord2207 = rc(p, 'Ord 22-07', 'Final passage')[0];
    expect(ord2207.index).toBe(0);
    expect(ord2207.outcome).toBe('failed');
    expect(ord2207.tally).toEqual({ yes: 0, no: 9, abstain: 0 });
  });

  it('ignores the postpone vote and sends the "change in motion" vote to unparsed', () => {
    expect(p.rollCalls.some((r) => /postpone/.test(r.sentence))).toBe(false);
    expect(p.unparsed.some((s) => s.includes('change in motion'))).toBe(true);
    expect(rc(p, 'Res 22-09', 'Amendment 01')).toHaveLength(1);
  });
});

describe('subject from the motion sentence just before a bare "The motion received"', () => {
  const p = parseMinutes(load('2021-05-19'), '2021-05-19');

  it('reads Amendment 01 to Ord 17-10 from its single margin heading', () => {
    const [r] = rc(p, 'Ord 17-10', 'Amendment 01');
    expect(r.tally).toEqual({ yes: 9, no: 0, abstain: 0 });
    expect(r.outcome).toBe('passed');
    expect(r.sentence).toContain('Vote to adopt Amendment 01 to Ordinance 17-10');
  });

  it('does not read the abbreviated heading "Vote to adopt Am 01 to Ordinance 17-17"', () => {
    expect(rc(p, 'Ord 17-17', 'Amendment 01')).toHaveLength(1);
  });

  it('reads Res 21-16 from "Flaherty moved and it was seconded to adopt Resolution 21-16."', () => {
    const [r] = rc(p, 'Res 21-16', 'Final passage');
    expect(r.tally).toEqual({ yes: 6, no: 3, abstain: 0 });
    expect(r.named).toEqual([{ side: 'no', names: ['Piedmont-Smith', 'Rollo', 'Sandberg'] }]);
    expect(r.outcome).toBe('passed');
    expect(r.sentence).toContain('moved and it was seconded to adopt Resolution 21-16');
  });

  it('reads all eight annexation resolutions', () => {
    for (let n = 9; n <= 16; n++) expect(rc(p, `Res 21-${String(n).padStart(2, '0')}`, 'Final passage')).toHaveLength(1);
  });
});

describe('parseRollCallSentence rules', () => {
  const S = (tally: string) => `The motion to adopt Ordinance 24-01 received a roll call vote of ${tally}`;

  it('Ayes equal to Nays fails without FAILED', () => {
    expect(rollCallOutcome(parseRollCallSentence(S('Ayes: 4, Nays: 4, Abstain: 1.'), 0)!, 'Final passage')).toBe('failed');
  });

  it('FAILED wins over a majority', () => {
    expect(rollCallOutcome(parseRollCallSentence(S('Ayes: 5, Nays: 4, Abstain: 0. FAILED'), 0)!, 'Final passage')).toBe('failed');
  });

  it('PASSED printed against the count is not understood', () => {
    expect(rollCallOutcome(parseRollCallSentence(S('Ayes: 3, Nays: 4, Abstain: 0. PASSED'), 0)!, 'Final passage')).toBeNull();
  });

  it('a mixed parenthetical (names and a note) is not understood', () => {
    expect(parseRollCallSentence(S('Ayes: 7 (Rollo, Sims out of the room), Nays: 0, Abstain: 0.'), 0)).toBeNull();
  });

  it('a multi-word part is not a name list', () => {
    expect(parseRollCallSentence(S('Ayes: 1 (Council President), Nays: 6, Abstain: 0.'), 0)).toBeNull();
  });

  it('text after the tally is not understood', () => {
    expect(parseRollCallSentence(S('Ayes: 9, Nays: 0, as amended [8:27pm] Abstain: 0.'), 0)).toBeNull();
  });

  it('reads left and arrived inline notes', () => {
    const t = parseRollCallSentence(S('Ayes: 7, Nays: 0, Abstain: 0 (Ruff left at 9:40pm).'), 3)!;
    expect(t.inlineNotes).toEqual([{ kind: 'left', nameAsPrinted: 'Ruff', at: 3 }]);
  });
});

describe('veto overrides', () => {
  const doc = (tail: string) =>
    `1. Roll Call [6:30pm]\n\nCouncil Members:\nAna Example\n\n2. Legislation\n\nThe motion to override the veto of Ordinance 24-02 received a roll call vote of ${tail}\n`;

  it('with FAILED printed is a failed Veto override', () => {
    const p = parseMinutes(doc('Ayes: 5, Nays: 4, Abstain: 0. FAILED'), '2024-01-01');
    expect(p.rollCalls).toHaveLength(1);
    expect(p.rollCalls[0]).toMatchObject({ itemNumber: 'Ord 24-02', question: 'Veto override', outcome: 'failed' });
  });

  it('with no printed result goes to unparsed', () => {
    const p = parseMinutes(doc('Ayes: 7, Nays: 2, Abstain: 0.'), '2024-01-01');
    expect(p.rollCalls).toHaveLength(0);
    expect(p.unparsed).toHaveLength(1);
  });
});

describe('procedural and appointment votes are ignored', () => {
  it('ignores "read by title" and appointments (2021-04-07)', () => {
    const p = parseMinutes(load('2021-04-07'), '2021-04-07');
    expect(p.rollCalls.some((r) => /read by title|appoint/.test(r.sentence))).toBe(false);
    expect(p.unparsed.some((s) => /read by title|appoint/.test(s))).toBe(false);
  });
});

describe('stripMargin', () => {
  it('drops a right margin column and margin-only lines, keeps body text', () => {
    const body = 'The motion to adopt Amendment 02 to Ordinance 21-23 received a';
    const line = `${body}            Vote to adopt Amendment 02 to`;
    expect(stripMargin(`${line}\n${' '.repeat(74)}Ordinance 21-23 [10:38pm]\nnext`)).toBe(`${body}\nnext`);
  });

  it('keeps blank lines as paragraph breaks and drops page footers', () => {
    expect(stripMargin('a\n\np. 2 Meeting Date: 05-05-21\nb')).toBe('a\n\nb');
  });
});

describe('layoutLines (PDF text runs to layout text)', () => {
  it('places runs on lines by baseline, keeps columns apart and breaks paragraphs on a wide gap', () => {
    const items = [
      { page: 1, x: 72, y: 700, w: 60, str: 'First line' },
      { page: 1, x: 400, y: 700, w: 50, str: 'MARGIN' },
      { page: 1, x: 72, y: 686, w: 60, str: 'second line' },
      { page: 1, x: 72, y: 650, w: 60, str: 'New para' },
      { page: 1, x: 300, y: 300, w: 10, str: 'x', dir: 1 },
    ];
    const lines = layoutLines(items);
    expect(lines[0].startsWith('First line')).toBe(true);
    expect(lines[0]).toMatch(/First line\s{3,}MARGIN$/);
    expect(lines[1]).toBe('second line');
    expect(lines[2]).toBe('');
    expect(lines[3]).toBe('New para');
    expect(lines).toHaveLength(4);
  });
});

describe('attendance remarks', () => {
  const modern = (rows: string) =>
    `1. City Council roll call and welcome [6:30pm]\n\nCouncil Members:\n${rows}\n\nCity staff, officials, and guests present:\nPat Staff        Clerk\n\n2. Legislation\n\nThe motion to adopt Ordinance 2026-90 received a roll call vote of Ayes: 2, Nays: 0, Abstain: 0.\n`;

  it('joins a remark wrapped onto the next line; a departure has no position (at null)', () => {
    const p = parseMinutes(
      modern('Ana Example (arrived at 6:32pm,        At-Large\nleft at 9:33pm)\nBo Sample*        District 1'),
      '2026-01-01',
    );
    expect(p.attendance).toEqual([
      { nameAsPrinted: 'Ana Example', absent: false },
      { nameAsPrinted: 'Bo Sample', absent: false },
    ]);
    expect(p.notes).toEqual(
      expect.arrayContaining([
        { kind: 'left', nameAsPrinted: 'Ana Example', at: null },
        { kind: 'arrived', nameAsPrinted: 'Ana Example', at: 0 },
      ]),
    );
    expect(p.unparsed).toEqual([]);
  });

  it('sends a remark it does not understand to unparsed', () => {
    const p = parseMinutes(modern('Ana Example (offline at 8:19pm, online at 8:21pm)\nBo Sample'), '2026-01-01');
    expect(p.unparsed).toEqual(['Attendance: Ana Example (offline at 8:19pm, online at 8:21pm)']);
    expect(p.attendance.map((a) => a.nameAsPrinted)).toEqual(['Ana Example', 'Bo Sample']);
    expect(p.notes).toEqual([]);
  });

  it('two-column minutes: commas inside a remark do not split the entry', () => {
    const p = parseMinutes(
      'Councilmembers present: Ana Example, Bo Sample (offline at 8:19pm, online at 8:21pm)\nCouncilmembers absent: Cy Person\n',
      '2024-01-01',
    );
    expect(p.attendance).toEqual([
      { nameAsPrinted: 'Ana Example', absent: false },
      { nameAsPrinted: 'Bo Sample', absent: false },
      { nameAsPrinted: 'Cy Person', absent: true },
    ]);
    expect(p.unparsed).toEqual(['Attendance: Bo Sample (offline at 8:19pm, online at 8:21pm)']);
  });
});

const oneVote = (body: string) =>
  `1. Roll Call [6:30pm]\n\nCouncil Members:\nAna Example\n\n2. Legislation\n\n${body}\n`;

describe('procedural forms are anchored; adopt + item that does not fully parse is unparsed', () => {
  it('"to adopt Ordinance 21-07 as introduced" goes to unparsed, not ignored', () => {
    const p = parseMinutes(
      oneVote('The motion to adopt Ordinance 21-07 as introduced received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.'),
      '2021-01-01',
    );
    expect(p.rollCalls).toHaveLength(0);
    expect(p.unparsed).toHaveLength(1);
  });

  it('the same in the moved-sentence form', () => {
    const p = parseMinutes(
      oneVote('Ana moved and Bo seconded to adopt Ordinance 21-07 as introduced. The motion received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.'),
      '2021-01-01',
    );
    expect(p.unparsed).toHaveLength(1);
  });

  it('a margin leak inside an adopt motion goes to unparsed', () => {
    const p = parseMinutes(
      oneVote('The motion to adopt Resolution 22-09 as amended Vote to postpone Resolution 22-09 received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.'),
      '2022-01-01',
    );
    expect(p.unparsed).toHaveLength(1);
  });

  it('a postpone motion with a margin leak is still ignored', () => {
    const p = parseMinutes(
      oneVote('The motion to postpone discussion on Resolution 22-09 as amended Vote to postpone Resolution 22-09 received a roll call vote of Ayes: 3 (Ana, Bo, Cy), Nays: 6, Abstain: 0. FAILED.'),
      '2022-01-01',
    );
    expect(p.rollCalls).toHaveLength(0);
    expect(p.unparsed).toHaveLength(0);
  });

  it('a procedural word later in an unknown motion does not hide it', () => {
    const p = parseMinutes(
      oneVote('Ana moved and Bo seconded to hold a Special Session on the agenda item. The motion received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.'),
      '2022-01-01',
    );
    expect(p.unparsed).toHaveLength(1);
  });
});

describe('out-of-room notes in body text', () => {
  it('a note right before a recorded roll call in the same paragraph is placed on it', () => {
    const p = parseMinutes(
      oneVote('Ana Example was out of the room. The motion to adopt Ordinance 24-01 received a roll call vote of Ayes: 8, Nays: 0, Abstain: 0.'),
      '2024-01-01',
    );
    expect(p.notes).toEqual([{ kind: 'out_of_room', nameAsPrinted: 'Ana Example', at: 0 }]);
  });

  it('a note that cannot be tied to a motion has at = null', () => {
    const p = parseMinutes(
      oneVote('Ana Example was out of the room.\n\nThe motion to adopt Ordinance 24-01 received a roll call vote of Ayes: 8, Nays: 0, Abstain: 0.'),
      '2024-01-01',
    );
    expect(p.notes).toEqual([{ kind: 'out_of_room', nameAsPrinted: 'Ana Example', at: null }]);
  });
});

describe('parenthetical words that are not names, and name counts', () => {
  const S = (tally: string) => `The motion to adopt Ordinance 24-01 received a roll call vote of ${tally}`;
  it.each(['None', 'All', 'Unanimous', 'Recused', 'Remote'])('(%s) is not a voter name', (w) => {
    expect(parseRollCallSentence(S(`Ayes: 9, Nays: 0 (${w}), Abstain: 0.`), 0)).toBeNull();
  });

  it('a side whose printed names do not match its count is not understood', () => {
    expect(parseRollCallSentence(S('Ayes: 5, Nays: 4 (Ana, Bo, Cy), Abstain: 0.'), 0)).toBeNull();
  });
});

describe('fix round 2', () => {
  const margin = (body: string, heading: string) => `${body.padEnd(72)}${heading}`;

  it('one margin heading is not shared by two bare votes in the same paragraph', () => {
    const text = [
      margin('There was no council discussion.', 'Vote to adopt Amendment 01 to'),
      margin('The motion received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.', 'Ordinance 17-10 [10:23pm]'),
      'The motion received a roll call vote of Ayes: 8, Nays: 1 (Ana), Abstain: 0.',
      '',
    ].join('\n');
    const p = parseMinutes(text, '2021-01-01');
    expect(p.rollCalls).toHaveLength(0);
    expect(p.unparsed).toHaveLength(2);
  });

  it('the same heading with one bare vote is read', () => {
    const text = [
      margin('There was no council discussion.', 'Vote to adopt Amendment 01 to'),
      margin('The motion received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.', 'Ordinance 17-10 [10:23pm]'),
      '',
    ].join('\n');
    const p = parseMinutes(text, '2021-01-01');
    expect(p.rollCalls.map((r) => `${r.itemNumber}|${r.question}`)).toEqual(['Ord 17-10|Amendment 01']);
  });

  const notePara = (next: string) =>
    oneVote(
      `Ana moved and Bo seconded that Ordinance 24-01 be read by title and synopsis only. The motion was approved by voice vote. Ana Example was out of the room. ${next} The motion received a roll call vote of Ayes: 8, Nays: 0, Abstain: 0.`,
    );

  it('an out-of-room note after an ignored vote but before a new moved sentence is unplaced (at null)', () => {
    const p = parseMinutes(notePara('Bo moved and Cy seconded to adopt Ordinance 24-01.'), '2024-01-01');
    expect(p.rollCalls).toHaveLength(1);
    expect(p.notes).toEqual([{ kind: 'out_of_room', nameAsPrinted: 'Ana Example', at: null }]);
  });

  it('an out-of-room note followed by an ignored moved sentence is dropped', () => {
    const p = parseMinutes(notePara('Bo moved and Cy seconded to postpone Ordinance 24-01.'), '2024-01-01');
    expect(p.notes).toEqual([]);
  });

  it('an out-of-room note followed by a voice-vote result is dropped', () => {
    const p = parseMinutes(
      oneVote('Bo moved and Cy seconded to adopt Ordinance 24-01. Ana Example was out of the room. The motion was approved by voice vote.'),
      '2024-01-01',
    );
    expect(p.notes).toEqual([]);
  });
});
