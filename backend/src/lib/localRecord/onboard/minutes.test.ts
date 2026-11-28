import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { presentAt } from '../checks';
import {
  layoutLines,
  minutesTextFromPdf,
  minutesSentences,
  parseMinutes,
  parseRollCallSentence,
  printedMeetingDate,
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

describe('real PDF round trip (2026-10-07 Memorandum)', () => {
  it('parses the PDF to the same result as the saved layout text', async () => {
    const bytes = new Uint8Array(readFileSync(new URL('./__fixtures__/minutes/2026-10-07.pdf', import.meta.url)));
    const fromPdf = parseMinutes(await minutesTextFromPdf(bytes), '2026-10-07');
    const fromTxt = parseMinutes(load('2026-10-07'), '2026-10-07');
    expect(fromPdf).toEqual(fromTxt);
  });
});

describe('final review: amendment and condition numbers are two zero-padded digits', () => {
  const q = (p: ReturnType<typeof parseMinutes>) => p.rollCalls.map((r) => `${r.itemNumber}|${r.question}`);
  const tally = 'received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.';

  it.each([
    ['Amendment 3', 'Amendment 03'],
    ['Amendment 003', 'Amendment 03'],
    ['Amendment 12', 'Amendment 12'],
    ['Reasonable Condition 4', 'Reasonable Condition 04'],
  ])('a moved "%s" reads as "%s"', (printed, question) => {
    const p = parseMinutes(oneVote(`The motion to adopt ${printed} to Ordinance 24-01 ${tally}`), '2024-01-01');
    expect(q(p)).toEqual([`Ord 24-01|${question}`]);
  });

  it('a margin heading "Amendment 1" reads as "Amendment 01"', () => {
    const margin = (body: string, heading: string) => `${body.padEnd(72)}${heading}`;
    const text = [
      margin('There was no council discussion.', 'Vote to adopt Amendment 1 to'),
      margin(`The motion ${tally}`, 'Ordinance 17-10 [10:23pm]'),
      '',
    ].join('\n');
    expect(q(parseMinutes(text, '2021-01-01'))).toEqual(['Ord 17-10|Amendment 01']);
  });
});

describe('R8: the meeting date printed in the document header', () => {
  it('reads "Wednesday, May 07, 2025" from the minutes attached to the 2025-03-05 meeting (file 15758)', () => {
    const head = [
      '                          Bloomington Common Council-Regular Session Minutes',
      '           Bloomington Council Chambers, City Hall, 401 N. Morton Street, Bloomington, Indiana',
      '                                     Wednesday, May 07, 2025, 6:30pm',
      '',
      '   CALL TO ORDER [6:31pm]',
    ].join('\n');
    expect(printedMeetingDate(head)).toBe('2025-05-07');
  });

  it('reads the first date of two-column minutes (2020-12-02, file 9378)', () => {
    const head = [
      'In Bloomington, Indiana on Wednesday, December 2, 2020 at         COMMON COUNCIL',
      '6:30pm, Council President Stephen Volan presided over a Regular   REGULAR SESSION',
      'Session of the Common Council. Per the Governor’s Executive       December 02, 2020',
    ].join('\n');
    expect(printedMeetingDate(head)).toBe('2020-12-02');
  });

  it('reads "Friday, 22 July, 2022" (memorandum 10620)', () => {
    expect(printedMeetingDate('                                       Friday, 22 July, 2022\n')).toBe('2022-07-22');
  });

  it('is null when the header prints no date (a scanned PDF has no text)', () => {
    expect(printedMeetingDate('')).toBeNull();
    expect(printedMeetingDate('MEMORANDUM\nCommon Council\n')).toBeNull();
  });
});

describe('R11: a vote the minutes say overrode the veto', () => {
  // 2024-04-17 minutes (file 13902), the two-column layout with the margin column kept apart.
  const text = [
    'Councilmembers present: Isak Nti Asare, Courtney Daily, Matt Flaherty,',
    'Isabel Piedmont-Smith, Dave Rollo, Kate Rosenbarger, Andy Ruff, Hopi Stosberg',
    'Councilmembers absent: Sydney Zulich',
    '',
    'The motion to adopt Resolution 2024-04 received a roll call vote of     Vote to adopt Resolution 2024-04',
    'Ayes: 7, Nays: 0, Abstain: 1 (Rosenbarger). Piedmont-Smith noted         [7:31pm]',
    'that the vote overrode the veto from Mayor Thomson.',
    '',
  ].join('\n');

  it('is a passed Veto override, not a second Final passage', () => {
    const p = parseMinutes(text, '2024-04-17');
    expect(p.rollCalls.map((r) => [r.itemNumber, r.question, r.outcome])).toEqual([['Res 2024-04', 'Veto override', 'passed']]);
    expect(p.unparsed).toEqual([]);
  });

  it('without that sentence it stays an "adopt" (Final passage), for the cross-meeting check to judge', () => {
    const p = parseMinutes(text.replace(' Piedmont-Smith noted', '').replace('that the vote overrode the veto from Mayor Thomson.', ''), '2024-04-17');
    expect(p.rollCalls.map((r) => r.question)).toEqual(['Final passage']);
  });
});

describe('R1: two-column layout keeps the margin column apart by the physical gap', () => {
  const runs = JSON.parse(readFileSync(new URL('./__fixtures__/minutes/2023-04-19-page3.runs.json', import.meta.url), 'utf8'));

  it('the margin heading beside "Ayes: 9, Nays:" is margin, not part of the vote sentence (2023-04-19, file 12969)', () => {
    const lines = layoutLines(runs);
    const line = lines.find((l) => l.includes('Ordinance 23-05 received a roll call vote of Ayes: 9, Nays:'))!;
    expect(line).toMatch(/Nays: {3,}Vote to adopt$/);
    expect(stripMargin(lines.join('\n'))).not.toMatch(/Nays: Vote to adopt/);
  });

  it('runs a normal word space apart still join with one space', () => {
    const line = layoutLines([
      { page: 1, x: 50, y: 700, w: 100, str: 'The motion received', dir: 0 },
      { page: 1, x: 152.5, y: 700, w: 60, str: 'a roll call', dir: 0 },
    ])[0];
    expect(line).toBe('The motion received a roll call');
  });
});

describe('R2: attendance', () => {
  const names = (p: ReturnType<typeof parseMinutes>) => p.attendance.map((a) => a.nameAsPrinted);

  it('ends at the "absent" line: "City staff…" after it is not a member (2023-01-25 memorandum 11346)', () => {
    const text = [
      'Councilmembers present:    Matt Flaherty, Isabel Piedmont-Smith, Dave Rollo, Kate Rosenbarger, Susan',
      'Sandberg, Sue Sgambelluri, Ron Smith, Stephen Volan (arrived at 6:33pm)',
      'Councilmembers present via Zoom:     Jim Sims',
      'Councilmembers absent:    none',
      'City staff, officials, and guests present: Stephen Lucas, Jackie Scanlan, Chris Cockerham, Beth Cate,',
      'Larry Allen, Mike Diekhoff, Jason Moore, Deb Kunce, Jeff Underwood, Bradley Bingham, Deputy Mayor',
      '',
    ].join('\n');
    const p = parseMinutes(text, '2023-01-25');
    expect(names(p)).toEqual(['Matt Flaherty', 'Isabel Piedmont-Smith', 'Dave Rollo', 'Kate Rosenbarger', 'Susan Sandberg',
      'Sue Sgambelluri', 'Ron Smith', 'Stephen Volan', 'Jim Sims']);
    expect(p.unparsed).toEqual([]);
  });

  it('ends at the "absent" line: a "Clerk’s Note" after it is not a member (2024-02-28 minutes)', () => {
    const text = [
      'Councilmembers present: Isak Nti Asare, Isabel Piedmont-Smith,       ROLL CALL [6:30pm]',
      'Dave Rollo, Kate Rosenbarger, Andy Ruff (arrived at 6:32pm), Hopi',
      'Stosberg, Sydney Zulich',
      'Councilmembers present via Zoom: Matt Flaherty (arrived 6:31pm)',
      'Councilmembers absent: none',
      'Clerk’s Note: There was a vacancy in District 5.',
      '',
    ].join('\n');
    expect(names(parseMinutes(text, '2024-02-28'))).toEqual(['Isak Nti Asare', 'Isabel Piedmont-Smith', 'Dave Rollo',
      'Kate Rosenbarger', 'Andy Ruff', 'Hopi Stosberg', 'Sydney Zulich', 'Matt Flaherty']);
  });

  it('a wide gap right after "present via teleconference:" is not the margin (2021-04-21, file 8761)', () => {
    const text = [
      'Councilmembers present via teleconference:    Matt Flaherty, Isabel Piedmont-Smith, Dave Rollo, Kate',
      'Rosenbarger, Susan Sandberg, Sue Sgambelluri, Jim Sims, Ron Smith, Stephen Volan',
      'Councilmembers absent:    none',
      'City staff and officials present: Alex Crowley, Devta Kidd, Eric Greulich, Heather Lacy, Jane Kupersmith,',
      '',
    ].join('\n');
    expect(names(parseMinutes(text, '2021-04-21'))).toHaveLength(9);
  });

  it('a nickname between first and last name is part of the name, not a remark (2024-01-17 minutes 13006)', () => {
    const text = [
      'Councilmembers present: Isak Nti Asare, Matt Flaherty, Isabel        ROLL CALL [6:30pm]',
      'Piedmont-Smith, Shruti Rana, Dave Rollo, Kate Rosenbarger,',
      'Andrew (Andy) Ruff, Hopi Stosberg, Sydney Zulich',
      'Councilmembers present via Zoom: none',
      'Councilmembers absent: none',
      '',
    ].join('\n');
    const p = parseMinutes(text, '2024-01-17');
    expect(names(p)).toContain('Andrew (Andy) Ruff');
    expect(p.unparsed).toEqual([]);
  });

  it('merges a member who left Zoom and arrived in person (2023-11-15 minutes 13374)', () => {
    const text = [
      'Councilmembers present: Matt Flaherty (arrived in person at 6:44pm),        ROLL CALL [6:37pm]',
      'Isabel Piedmont-Smith, Dave Rollo, Susan Sandberg, Sue Sgambelluri, Ron',
      'Smith, Stephen Volan',
      'Councilmembers present via Zoom: Matt Flaherty (left Zoom at 6:39pm),',
      'Jim Sims',
      'Councilmembers absent: Kate Rosenbarger',
      '',
    ].join('\n');
    const p = parseMinutes(text, '2023-11-15');
    expect(names(p).filter((n) => n === 'Matt Flaherty')).toHaveLength(1);
    expect(p.notes).toContainEqual({ kind: 'arrived', nameAsPrinted: 'Matt Flaherty', at: 0 });
    expect(p.unparsed).toEqual([]);
  });

  it('a member listed in person and on Zoom with no remarks stays listed twice (2024-09-04): the check holds it', () => {
    const text = [
      '           Councilmembers present: Isak Nti Asare, Courtney Daily, Matt          ROLL CALL [6:30pm]',
      '           Flaherty, Isabel Piedmont-Smith, Dave Rollo, Hopi Stosberg, Sydney',
      '           Zulich',
      '           Councilmembers present via Zoom: Matt Flaherty, Kate Rosenbarger',
      '           Councilmembers absent: Andrew (Andy) Ruff',
      '',
    ].join('\n');
    expect(names(parseMinutes(text, '2024-09-04')).filter((n) => n === 'Matt Flaherty')).toHaveLength(2);
  });
});

describe('R2: memoranda label each line "MOTION:" / "ACTION:" (2021-04-21, file 8761)', () => {
  const text = [
    'Councilmembers present via teleconference:    Matt Flaherty, Isabel Piedmont-Smith, Dave Rollo, Kate',
    'Rosenbarger, Susan Sandberg, Sue Sgambelluri, Jim Sims, Ron Smith, Stephen Volan',
    'Councilmembers absent:    none',
    '',
    'Resolution 21-08  – Accepting the City of Bloomington Climate Action Plan',
    'MOTION: Flaherty moved and it was seconded that Resolution 21-08 be read by title and synopsis only.',
    'ACTION:  The motion received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.',
    'MOTION: Flaherty moved and it was seconded to adopt Resolution 21-08.',
    'ACTION: The motion to adopt Resolution 21-08 received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.',
    'Ordinance 21-15   - To Amend Title 20 (Unified Development Ordinance) of the Bloomington Municipal',
    'Code – Re: Technical Corrections Set Forth in BMC 20.02, 20.04, 20.06, 20.07',
    'MOTION: Flaherty moved and it was seconded that Ordinance 21-15 be read by title and synopsis only.',
    'ACTION:  The motion received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.',
    'MOTION: Flaherty moved and it was seconded to adopt Ordinance 21-15.',
    'ACTION: The motion to adopt Ordinance 21-15 received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.',
    '',
  ].join('\n');

  it('reads each labelled line as its own sentence: two votes, the read-by-title motions ignored', () => {
    const p = parseMinutes(text, '2021-04-21');
    expect(p.rollCalls.map((r) => [r.itemNumber, r.question])).toEqual([['Res 21-08', 'Final passage'], ['Ord 21-15', 'Final passage']]);
    expect(p.unparsed).toEqual([]);
  });
});

describe('R4: page headers and agenda numbers are not part of a vote sentence', () => {
  const ATT = [
    'Councilmembers present: Isak Nti Asare, Courtney Daily, Matt Flaherty, Isabel Piedmont-Smith, Dave Rollo,',
    'Kate Rosenbarger, Andy Ruff, Hopi Stosberg, Sydney Zulich',
    'Councilmembers absent: none',
    '',
  ];
  const votes = (lines: string[], date: string) => parseMinutes([...ATT, ...lines].join('\n'), date);

  it('drops "Docusign Envelope ID" and "Meeting Date: June 10, 2026" headers (2026-06-10 minutes 17745)', () => {
    const p = votes([
      '                                                                                                      3',
      'Docusign Envelope ID: DAC49021-2E00-81DA-8338-981C6CA14F5D',
      '',
      '    Meeting Date: June 10, 2026',
      '    The motion to adopt Amendment 01 to Ordinance 2026-12 received a roll call vote of Ayes: 9, Nays: 0,',
      '    Abstain: 0.',
      '',
    ], '2026-06-10');
    expect(p.rollCalls.map((r) => [r.itemNumber, r.question])).toEqual([['Ord 2026-12', 'Amendment 01']]);
    expect(p.unparsed).toEqual([]);
  });

  it('drops a bare "February 04, 2026" page header (2026-02-04)', () => {
    const p = votes([
      ' Stosberg thanked her colleagues for their collaboration.',
      '                                                                                                   4',
      ' February 04, 2026',
      ' The motion to adopt Resolution 2026-03 received a roll call vote of Ayes: 8, Nays: 0, Abstain: 0.',
      '',
    ], '2026-02-04');
    expect(p.rollCalls.map((r) => r.itemNumber)).toEqual(['Res 2026-03']);
  });

  it('drops a "p. 4 Meeting Date: 02-28-2024" footer with a four-digit year', () => {
    const lines = minutesSentences(['The motions received a roll call vote of Ayes: 8, Nays: 0, Abstain: 0.', 'p. 4 Meeting Date: 02-28-2024', ''].join('\n'));
    expect(lines).toEqual(['The motions received a roll call vote of Ayes: 8, Nays: 0, Abstain: 0.']);
  });

  it('a numbered agenda heading on the next line starts a new paragraph (2025-02-19 minutes 15637)', () => {
    const p = votes([
      'The motion to adopt Ordinance 2025-05 as amended received a roll call vote of Ayes: 8, Nays: 0, Abstain: 0.',
      '8.2. Resolution 2025-02',
      'To Update the Established Interview Standing Committees',
      '',
    ], '2025-02-19');
    expect(p.rollCalls.map((r) => r.itemNumber)).toEqual(['Ord 2025-05']);
    expect(p.unparsed).toEqual([]);
  });

  it('a wrapped count after "Abstain:" is not a heading', () => {
    const s = minutesSentences(['The motion to adopt Ordinance 2025-33 as amended received a roll call vote of Ayes: 9, Nays: 0, Abstain:', '1.', ''].join('\n'));
    expect(s).toEqual(['The motion to adopt Ordinance 2025-33 as amended received a roll call vote of Ayes: 9, Nays: 0, Abstain: 1.']);
  });
});

describe('R6/R7: other wordings and amendment shapes, as printed', () => {
  const ATT = [
    'Councilmembers present: Matt Flaherty, Isabel Piedmont-Smith, Dave Rollo, Kate Rosenbarger, Susan Sandberg,',
    'Sue Sgambelluri, Jim Sims, Ron Smith, Stephen Volan',
    'Councilmembers absent: none',
    '',
  ];
  const one = (sentence: string, date = '2023-06-07') => {
    const p = parseMinutes([...ATT, sentence, ''].join('\n'), date);
    return { calls: p.rollCalls.map((r) => [r.itemNumber, r.question, r.outcome]), unparsed: p.unparsed };
  };

  it.each([
    // [sentence as printed (date), item, question, outcome]
    ['The motion that Resolution 23-09 be adopted received a roll call vote of Ayes: 8, Nays: 0, Abstain: 0.', 'Res 23-09', 'Final passage', 'passed'],
    ['The motion that Resolution 23-11 be adopted received a roll call vote of Ayes: 0, Nays: 7, Abstain: 0. FAILED', 'Res 23-11', 'Final passage', 'failed'],
    ['The vote to adopt Ordinance 23-21 received a roll call vote of Ayes: 8, Nays: 0, Abstain: 0.', 'Ord 23-21', 'Final passage', 'passed'],
    ['The vote to adopt Amendment 01 as amended to Ordinance 23-14 received a roll call vote of Ayes: 8, Nays: 1 (Sims), Abstain: 0.', 'Ord 23-14', 'Amendment 01', 'passed'],
    ['The motion to adopt Amendment 01 as amended to Resolution 22-20 received a roll call vote of Ayes: 8, Nays: 1 (Sandberg), Abstain: 0.', 'Res 22-20', 'Amendment 01', 'passed'],
    ['The motion to adopt Sub-amendment A to Amendment 01 to Resolution 22-20 received a roll call vote of Ayes: 6, Nays: 3 (Smith, Sims, Sandberg), Abstain: 0.', 'Res 22-20', 'Sub-amendment A to Amendment 01', 'passed'],
    ['The motion to adopt Amendment 01 to Amendment 03 to Ordinance 2025-20 received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.', 'Ord 2025-20', 'Amendment 01 to Amendment 03', 'passed'],
    ['The motion to adopt Amendment 01 to Ordinance 23-25 received a roll call vote: Ayes: 9, Nays: 0, Abstain: 0.', 'Ord 23-25', 'Amendment 01', 'passed'],
    ['The motion to adopt Amendment 01 to Ordinance 2025-03 was approved by a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.', 'Ord 2025-03', 'Amendment 01', 'passed'],
    ['Resolution 2026-06 was adopted by a roll call vote of Ayes: 7, Nays: 2 (Ruff, Stosberg), Abstain: 0.', 'Res 2026-06', 'Final passage', 'passed'],
    ['The motion to adopt RC 14 to Ordinance 2026-06 received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.', 'Ord 2026-06', 'Reasonable Condition 14', 'passed'],
    ['The motion to adopt Reasonable Condition 04 (revised) to Ordinance 2024-07 received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.', 'Ord 2024-07', 'Reasonable Condition 04', 'passed'],
  ])('%s', (sentence, item, question, outcome) => {
    const r = one(sentence);
    expect(r.unparsed).toEqual([]);
    expect(r.calls).toEqual([[item, question, outcome]]);
  });

  it('semicolons between the sides are read (2026-07-22): names still must match the counts', () => {
    const p = parseRollCallSentence('The motion to adopt Ordinance 2026-12 received a roll call vote: Ayes: 4 (Asare, Daily, Flaherty, Rosenbarger); Nays: 4 (Stosberg, Piedmont-Smith, Rollo, Ruff); Abstain: 0. FAILED', 0);
    expect(p?.tally).toEqual({ yes: 4, no: 4, abstain: 0 });
    expect(p?.printedResult).toBe('failed');
  });

  it('"Moved it was seconded by" is a moved sentence (2023-10-04, file 12579)', () => {
    const r = one('Rollo moved it was seconded by Piedmont-Smith to adopt Resolution 23-17. The motion received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.', '2023-10-04');
    expect(r.calls).toEqual([['Res 23-17', 'Final passage', 'passed']]);
  });

  it('"was approved" with a losing count is not understood', () => {
    const r = one('The motion to adopt Amendment 01 to Ordinance 2025-03 was approved by a roll call vote of Ayes: 3, Nays: 6, Abstain: 0.');
    expect(r.calls).toEqual([]);
    expect(r.unparsed).toHaveLength(1);
  });

  it('several conditions in one vote ("RCs 8, 9, 10, and 12") stay unparsed', () => {
    expect(one('The motion to adopt RCs 8, 9, 10, and 12 to Ordinance 2026-06 received a roll call vote of Ayes: 9, Nays: 0, Abstain: 0.').unparsed).toHaveLength(1);
  });
});

describe('R3: departure and out-of-room notes', () => {
  const unplacedOf = (p: ReturnType<typeof parseMinutes>) => p.notes.filter((n) => n.at === null);

  it('a note in parentheses after the tally belongs to that vote; the attendance copy is the same departure (2025-09-30, file 16314)', () => {
    const text = [
      '   1. ROLL CALL   (* indicates participation via Zoom) [6:31pm]',
      '',
      '   Members:',
      '   Isak Nti Asare                              At-Large',
      '   Courtney Daily                              District 5, Council Parliamentarian',
      '   Matt Flaherty (absent)                      At-Large',
      '   Isabel Piedmont-Smith                       District 1, Council Vice President',
      '   Dave Rollo                                  District 4',
      '   Kate Rosenbarger (left at 7:53pm)           District 2',
      '   Andy Ruff (absent)                          At-Large',
      '   Hopi Stosberg                               District 3, Council President',
      '   Sydney Zulich                               District 6',
      '',
      '   The motion to postpone Resolution 2025-18 received a roll call vote of Ayes: 6, Nays: 0, Abstain: 0.',
      '   (Rosenbarger left at 7:53pm)',
      '',
      'The motion to adopt Appropriation Ordinance 2025-09 received a roll call vote of Ayes: 6, Nays: 0, Abstain:',
      '0.',
      '',
    ].join('\n');
    const p = parseMinutes(text, '2025-09-30');
    expect(p.rollCalls.map((r) => r.itemNumber)).toEqual(['App Ord 2025-09']);
    expect(unplacedOf(p)).toEqual([]);
    expect(p.notes).toContainEqual(expect.objectContaining({ kind: 'left', nameAsPrinted: 'Rosenbarger', at: 0 }));
    expect(p.notes.filter((n) => n.kind === 'left')).toHaveLength(1);
  });

  it('reads "(Zulich left the meeting at 10:17pm)" after the period as that vote\'s inline note (2025-10-22, file 16388)', () => {
    const r = parseRollCallSentence('The motion to adopt Amendment 01 to Ordinance 2025-32 received a roll call vote of Ayes: 5, Nays: 3 (Rollo, Rosenbarger, Asare), Abstain: 0. (Zulich left the meeting at 10:17pm)', 3);
    expect(r?.inlineNotes).toEqual([{ kind: 'left', nameAsPrinted: 'Zulich', at: 3 }]);
  });

  it('keeps the departure printed in a vote whose subject is not understood (2026-09-02 memorandum 17403)', () => {
    const text = [
      ' 1.   Roll Call (*indicates participation via Zoom) [6:30pm]',
      '',
      '  Council Members:',
      '  Isak Nti Asare                     At-Large, Council President',
      '  Matt Flaherty* (left at 10:32pm)   At-Large',
      '  Dave Rollo                         District 4',
      '',
      '  Piedmont-Smith moved and Asare seconded to adopt Amendment 01 to Amendment 01.',
      '  The motion to adopt Amendment 01 to Amendment 01 received a roll call vote of Ayes: 8,',
      '  Nays: 0, Abstain: 0 (Flaherty left at 10:32pm).',
      '  The motion to adopt Ordinance 2026-18 as amended received a roll call vote of Ayes: 8,',
      '  Nays: 0, Abstain: 0.',
      '',
    ].join('\n');
    const p = parseMinutes(text, '2026-09-02');
    expect(p.unparsed).toHaveLength(1);
    expect(unplacedOf(p)).toEqual([]);
    expect(p.notes).toContainEqual(expect.objectContaining({ kind: 'left', nameAsPrinted: 'Flaherty', at: 0 }));
  });

  it('"(Rollo left the meeting)." after a voice vote is a body note (2024-05-15, file 14566)', () => {
    const text = [
      '  Council members present: Isak Nti Asare, Courtney Daily, Matt        ROLL CALL [6:30pm]',
      '  Flaherty, Isabel Piedmont-Smith, Kate Rosenbarger, Andy Ruff, Hopi',
      '  Stosberg, Sydney Zulich',
      '  Council members present via Zoom: Dave Rollo (left the meeting at',
      '  11:48pm)',
      '  Councilmembers absent: none',
      '',
      '     The motion to adopt Ordinance 2024-07 as amended received a roll     Vote to adopt Ordinance 2024-07',
      '     call vote of Ayes: 7, Nays: 2 (Rollo, Ruff), Abstain: 0.             [11:46pm]',
      '',
      '     Stosberg moved and Ruff seconded that Ordinance 2024-13 be           Ordinance 2024-13-To Amend',
      '     introduced and read by title and synopsis only. The motion was       Title 2 of the Bloomington',
      '     approved by a voice vote. (Rollo left the meeting). Bolden read the   Municipal Code Entitled',
      '     legislation by title and synopsis.                                   "Administration and Personnel"',
      '',
    ].join('\n');
    const p = parseMinutes(text, '2024-05-15');
    expect(unplacedOf(p)).toEqual([]);
    expect(p.notes.filter((n) => n.kind === 'left')).toEqual([{ kind: 'left', nameAsPrinted: 'Rollo', at: 1 }]);
  });

  it('"received a roll call vote Ayes:" (no "of") with "(Flaherty left at 9:33 pm)" places the attendance departure (2026-05-20, file 17657)', () => {
    const text = [
      '   1. Roll Call (*indicates participation via Zoom) [6:30pm]',
      '',
      '   Council Members:',
      '    Matt Flaherty (arrived at 6:32pm,   At-Large',
      '    left at 9:33pm)',
      '    Dave Rollo                         District 4',
      '',
      '   The motion to adopt Ordinance 2026-07 received a roll call vote Ayes: 7, Nays: 1 (Rosenbarger),',
      '   Abstain: 0. (Flaherty left at 9:33 pm)',
      '',
    ].join('\n');
    const p = parseMinutes(text, '2026-05-20');
    expect(p.rollCalls.map((r) => r.itemNumber)).toEqual(['Ord 2026-07']);
    expect(p.rollCalls[0].inlineNotes).toEqual([{ kind: 'left', nameAsPrinted: 'Flaherty', at: 0 }]);
    expect(unplacedOf(p)).toEqual([]);
    // The inline note covers that vote only; the attendance copy carries the departure to the votes after it.
    expect(p.notes).toContainEqual({ kind: 'left', nameAsPrinted: 'Matt Flaherty', at: 0 });
  });

  it('a placed departure is applied after the same member\'s earlier arrival (2026-05-20, file 17657)', () => {
    const text = [
      '   1. Roll Call (*indicates participation via Zoom) [6:30pm]',
      '',
      '   Council Members:',
      '    Matt Flaherty (arrived at 6:32pm,   At-Large',
      '    left at 9:33pm)',
      '    Dave Rollo                         District 4',
      '',
      '   The motion to adopt Resolution 2026-06 received a roll call vote of Ayes: 2, Nays: 0, Abstain: 0.',
      '',
      '   The motion to adopt Ordinance 2026-07 received a roll call vote Ayes: 1, Nays: 0, Abstain: 0. (Flaherty left at 9:33 pm)',
      '',
      '   The motion to adopt Ordinance 2026-08 received a roll call vote of Ayes: 1, Nays: 0, Abstain: 0.',
      '',
    ].join('\n');
    const p = parseMinutes(text, '2026-05-20');
    expect(p.rollCalls).toHaveLength(3);
    // The real checks match "Flaherty" to "Matt Flaherty" through names.json; here, by surname.
    const last = (x: string) => x.split(' ').pop();
    const at = (i: number) => presentAt(p, p.rollCalls[i], (a, b) => last(a) === last(b));
    expect(at(0)).toMatchObject({ present: ['Matt Flaherty', 'Dave Rollo'] });
    expect(at(1)).toMatchObject({ present: ['Dave Rollo'] });
    expect(at(2)).toMatchObject({ present: ['Dave Rollo'] });
  });

  describe('a timed departure in the attendance list is placed by the printed vote times (2021-06-16, file 11108)', () => {
    const head = [
      ' Councilmembers present via Zoom: Matt Flaherty, Isabel Piedmont-     ROLL CALL [6:32pm]',
      ' Smith (arrived at 6:46pm, left at 11:01pm), Dave Rollo, Kate',
      ' Rosenbarger, Susan Sandberg (arrived at 7:30pm), Sue Sgambelluri,',
      'Jim Sims, Ron Smith',
      ' Councilmembers absent: Stephen Volan',
      '',
    ];
    const body = (amendmentMargin: string) => [
      'The motion to adopt Ordinance 21-25 as amended received a roll       Vote to adopt Ordinance 21-25 as',
      'call vote of Ayes: 8, Nays: 0, Abstain: 0.                           amended [10:54pm]',
      'There were no council questions.                                     Council questions:',
      'The motion to adopt Amendment 01 to Ordinance 21-28 received a       Vote to adopt Amendment   O 1 to',
      `roll call vote of Ayes: 7, Nays: 0, Abstain: 0.                      ${amendmentMargin}`,
      'There were no council comments.                                      Council comments:',
      '',
      '  The motion to adopt Ordinance 21-28 as amended received a roll       Vote to adopt Ordinance 21-28 as',
      '  call vote of Ayes: 7, Nays: 0, Abstain: 0.                           amended [11:05pm]',
      '',
    ];
    it('between the votes printed at 10:54pm and 11:03pm', () => {
      const p = parseMinutes([...head, ...body('Ordinance 21-28 [11:03pm]')].join('\n'), '2021-06-16');
      expect(p.rollCalls.map((r) => `${r.itemNumber} ${r.question}`)).toEqual([
        'Ord 21-25 Final passage', 'Ord 21-28 Amendment 01', 'Ord 21-28 Final passage',
      ]);
      expect(unplacedOf(p)).toEqual([]);
      expect(p.notes).toContainEqual({ kind: 'left', nameAsPrinted: 'Isabel Piedmont-Smith', at: 1 });
    });
    it('stays unplaced when the next vote prints no time', () => {
      const p = parseMinutes([...head, ...body('Ordinance 21-28')].join('\n'), '2021-06-16');
      expect(unplacedOf(p)).toEqual([{ kind: 'left', nameAsPrinted: 'Isabel Piedmont-Smith', at: null }]);
    });
  });

  it('an attendance departure at another time than the body note stays unplaced', () => {
    const text = [
      '   1. ROLL CALL [6:31pm]',
      '',
      '   Members:',
      '   Kate Rosenbarger (left at 7:53pm)           District 2',
      '   Dave Rollo                                  District 4',
      '',
      '   The motion to adopt Resolution 2025-18 received a roll call vote of Ayes: 1, Nays: 0, Abstain: 0.',
      '   (Rosenbarger left at 8:10pm)',
      '',
    ].join('\n');
    expect(unplacedOf(parseMinutes(text, '2025-09-30'))).toHaveLength(1);
  });
});

describe('R5: a bare "The motion received" far from its motion (2025-02-19, file 15637)', () => {
  const att = [
    '   2. ROLL CALL (*Indicates participation via Zoom) [6:32pm]',
    '',
    '   Councilmembers present:',
    '   Isak Nti Asare                             At-Large',
    '   Dave Rollo                                 District 4',
    '',
  ];
  const item = (heading: string, motions: string[]) => [
    ...att,
    'The motion to adopt Ordinance 2025-05 as amended received a roll call vote of Ayes: 8, Nays: 0, Abstain: 0.',
    heading,
    'To Update the Established Interview Standing Committees',
    '',
    '   Daily moved and Piedmont-Smith seconded that Resolution 2025-02 be introduced and read by title and',
    '   synopsis only. The motion was approved by voice vote. Bolden read the legislation by title and synopsis.',
    ...motions,
    '   Stosberg passed the gavel to Piedmont-Smith and then Stosberg summarized the legislation.',
    '   There was no public comment.',
    '   The motion received a roll call vote of Ayes: 8, Nays: 0, Abstain: 0.',
    '   9. ADDITIONAL PUBLIC COMMENT [8:37pm]',
    '   Christopher Emge commented on the Plan Commission, developments, and land use.',
  ].join('\n');
  const adopt = '   Daily moved and Piedmont-Smith seconded to adopt Resolution 2025-02.';

  it('pairs with the one open motion in the agenda item, and says so', () => {
    const p = parseMinutes(item('8.2. Resolution 2025-02', [adopt]), '2025-02-19');
    const rc = p.rollCalls.find((r) => r.itemNumber === 'Res 2025-02');
    expect(rc).toMatchObject({ question: 'Final passage', tally: { yes: 8, no: 0, abstain: 0 }, subjectFromOpenMotion: true });
    expect(p.unparsed).toEqual([]);
  });

  it('two open motions: not paired', () => {
    const p = parseMinutes(item('8.2. Resolution 2025-02', [adopt, '   Rollo moved and Daily seconded to postpone Resolution 2025-02.']), '2025-02-19');
    expect(p.rollCalls.find((r) => r.itemNumber === 'Res 2025-02')).toBeUndefined();
    expect(p.unparsed).toHaveLength(1);
  });

  it('a heading that names another item: not paired', () => {
    const p = parseMinutes(item('8.2. Resolution 2025-03', [adopt]), '2025-02-19');
    expect(p.rollCalls.find((r) => r.itemNumber === 'Res 2025-02')).toBeUndefined();
    expect(p.unparsed).toHaveLength(1);
  });

  it('an open amendment: not paired', () => {
    const p = parseMinutes(item('8.2. Resolution 2025-02', ['   Daily moved and Piedmont-Smith seconded to adopt Amendment 01 to Resolution 2025-02.']), '2025-02-19');
    expect(p.rollCalls.find((r) => r.itemNumber === 'Res 2025-02')).toBeUndefined();
    expect(p.unparsed).toHaveLength(1);
  });

  it('a vote result between the motion and the bare vote: not paired', () => {
    const p = parseMinutes(item('8.2. Resolution 2025-02', [adopt, '   The motion to suspend the rules was approved by voice vote.']), '2025-02-19');
    expect(p.rollCalls.find((r) => r.itemNumber === 'Res 2025-02')).toBeUndefined();
  });
});

describe('review fixes', () => {
  const last = (x: string) => x.split(' ').pop();
  const same = (a: string, b: string) => last(a) === last(b);

  it('an arrival and a departure placed on the same vote: the arrival is applied first (17657, Ord 2026-07 as vote 0)', () => {
    const text = [
      '   1. Roll Call (*indicates participation via Zoom) [6:30pm]',
      '',
      '   Council Members:',
      '    Matt Flaherty (arrived at 6:32pm,   At-Large',
      '    left at 9:33pm)',
      '    Dave Rollo                         District 4',
      '',
      '   The motion to adopt Ordinance 2026-07 received a roll call vote Ayes: 1, Nays: 0, Abstain: 0. (Flaherty left at 9:33 pm)',
      '',
      '   The motion to adopt Ordinance 2026-08 received a roll call vote of Ayes: 1, Nays: 0, Abstain: 0.',
      '',
    ].join('\n');
    const p = parseMinutes(text, '2026-05-20');
    expect(presentAt(p, p.rollCalls[0], same)).toMatchObject({ present: ['Dave Rollo'] });
    expect(presentAt(p, p.rollCalls[1], same)).toMatchObject({ present: ['Dave Rollo'] });
  });

  const timed = (leftAt: string, times: [string, string]) => [
    'Councilmembers present: Matt Flaherty, Dave Rollo (left at ' + leftAt + ')',
    'Councilmembers absent: none',
    '',
    'The motion to adopt Ordinance 21-01 received a roll call vote of     Vote to adopt Ordinance 21-01',
    `Ayes: 2, Nays: 0, Abstain: 0.                                        [${times[0]}]`,
    '',
    'The motion to adopt Ordinance 21-02 received a roll call vote of     Vote to adopt Ordinance 21-02',
    `Ayes: 1, Nays: 0, Abstain: 0.                                        [${times[1]}]`,
    '',
  ].join('\n');
  const unplaced = (text: string) => parseMinutes(text, '2021-06-16').notes.filter((n) => n.at === null);

  it('vote times that cross midnight: a departure is not placed by time', () => {
    expect(unplaced(timed('12:10am', ['11:50pm', '12:20am']))).toHaveLength(1);
  });

  it('vote times that run backwards: a departure is not placed by time', () => {
    expect(unplaced(timed('9:10pm', ['9:50pm', '9:20pm']))).toHaveLength(1);
  });

  it('the same meeting before midnight is still placed', () => {
    expect(unplaced(timed('9:10pm', ['9:00pm', '9:20pm']))).toHaveLength(0);
  });

  describe('R5: other motion wordings count as open motions (15637)', () => {
    const text = (between: string) => [
      '8.2. Resolution 2025-02',
      '',
      '   Daily moved and Piedmont-Smith seconded to adopt Resolution 2025-02.',
      between,
      '   There was no public comment.',
      '   The motion received a roll call vote of Ayes: 8, Nays: 0, Abstain: 0.',
    ].join('\n');
    for (const between of ['   It was moved and seconded to suspend the rules.', '   Rollo made a motion to postpone Resolution 2025-02.']) {
      it(between.trim(), () => {
        const p = parseMinutes(text(between), '2025-02-19');
        expect(p.rollCalls).toEqual([]);
        expect(p.unparsed).toHaveLength(1);
      });
    }
  });
});
