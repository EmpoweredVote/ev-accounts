// Minutes parser for the Bloomington Common Council voting record.
//
// Turns approved council minutes (as layout text, one printed line per line) into attendance, meeting notes and
// roll calls. A wrong parse would put a wrong vote next to a real person's name, so every rule here is strict:
// a roll-call sentence that does not match exactly goes to `unparsed`, and nothing is guessed.
import { extractPdfItems, type PdfTextItem } from '../../pdfText.js';
import type { AttendanceEntry, MeetingNote, MinutesParse, MinutesRollCall, PrintedTally, Side } from '../types.js';

// ---------------------------------------------------------------------------------------------------------------
// Layout: margin column, footers, paragraphs, sentences
// ---------------------------------------------------------------------------------------------------------------

/**
 * Minutes from 2020–2022 print a right margin column (headings such as "Vote to adopt Amendment 02 to
 * Ordinance 21-23 [10:38pm]") on the same text lines as the body. Text that starts at or right of this column,
 * after a run of 3+ spaces, is margin. Body lines in those minutes end before column ~72; margin text starts at
 * column 60 or later. Single-column minutes only reach this column with staff titles and page numbers.
 */
const MARGIN_COL = 45;
const FOOTER = /^\s*(?:p\.\s*\d+\s+)?Meeting Date:\s*\d{2}-\d{2}-\d{2}(?:\s+p\.\s*\d+)?\s*$/;

/**
 * Remove the right margin column, margin-only lines and page footers. Lines that were blank stay blank (they
 * separate paragraphs); lines that held only margin text or a footer are removed, so they cannot split a sentence.
 */
export function stripMargin(text: string): string {
  const out: string[] = [];
  for (const raw of text.replace(/\u200b/g, '').replace(/\r\n?/g, '\n').split('\n')) {
    if (!raw.trim()) {
      out.push('');
      continue;
    }
    if (FOOTER.test(raw)) continue;
    const lead = raw.length - raw.trimStart().length;
    if (lead >= MARGIN_COL) continue; // margin-only line, or a page number
    let line = raw;
    const gap = /(\S)( {3,})(?=\S)/g;
    let m: RegExpExecArray | null;
    while ((m = gap.exec(raw))) {
      const rightStart = m.index + 1 + m[2].length;
      if (rightStart >= MARGIN_COL) {
        line = raw.slice(0, m.index + 1);
        break;
      }
    }
    out.push(line.replace(/\s+$/, ''));
  }
  return out.join('\n');
}

/** Join wrapped lines: a line ending in a hyphen after a letter or digit joins with no space ("Piedmont-" "Smith"). */
function joinLines(lines: string[]): string {
  let s = '';
  for (const l of lines.map((x) => x.trim())) {
    if (!l) continue;
    if (!s) s = l;
    else if (/[A-Za-z0-9]-$/.test(s)) s += l;
    else s += ' ' + l;
  }
  return s.replace(/\s+/g, ' ').trim();
}

/** Paragraphs of the body text (margin removed), each joined into one line. */
function paragraphs(text: string): string[] {
  const paras: string[] = [];
  let cur: string[] = [];
  for (const line of stripMargin(text).split('\n')) {
    if (line.trim()) cur.push(line);
    else if (cur.length) {
      paras.push(joinLines(cur));
      cur = [];
    }
  }
  if (cur.length) paras.push(joinLines(cur));
  return paras;
}

const ABBREV = /(?:^|[\s(])(?:Cm|Mr|Ms|Mrs|Dr|St|Inc|No|Jr|Sr|Ave|Rd|vs|etc|[A-Z]|[a-z]\.[a-z])$/;

/** Split one paragraph into sentences. A lone "FAILED" / "PASSED" after a tally stays with its sentence. */
function splitSentences(para: string): string[] {
  const out: string[] = [];
  let start = 0;
  const re = /[.!?]["”’)]?(?=\s+[A-Z(“"])/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(para))) {
    const before = para.slice(start, m.index);
    if (m[0] === '.' && ABBREV.test(before)) continue;
    out.push(para.slice(start, m.index + m[0].length).trim());
    start = m.index + m[0].length;
  }
  const rest = para.slice(start).trim();
  if (rest) out.push(rest);
  const merged: string[] = [];
  for (const s of out) {
    if (/^(?:FAILED|PASSED)\.?$/i.test(s) && merged.length) merged[merged.length - 1] += ' ' + s;
    else merged.push(s);
  }
  return merged;
}

/** Every sentence of the body text, in order (paragraph boundaries are not kept). */
export function minutesSentences(text: string): string[] {
  return paragraphs(text).flatMap(splitSentences);
}

// ---------------------------------------------------------------------------------------------------------------
// Roll-call sentences
// ---------------------------------------------------------------------------------------------------------------

const NAME_TOKEN = String.raw`[A-Z][A-Za-z'’]+(?:-[A-Z][A-Za-z'’]+)?`;
const SURNAME = new RegExp(`^${NAME_TOKEN}$`);
const NOTE_NAME = String.raw`(?:${NAME_TOKEN})(?: ${NAME_TOKEN}){0,2}`;
const TIME = String.raw`\d{1,2}:\d{2}\s?(?:[ap]\.?m\.?)?`;

/** "<Name> out of the room" | "<Name> left …" | "<Name> arrived …" | "<Name> returned …" inside a parenthetical. */
const INLINE_NOTE = new RegExp(`^(${NOTE_NAME}) (out of the room|left\\b.*|arrived\\b.*|returned\\b.*)$`);

function noteKind(phrase: string): MeetingNote['kind'] {
  if (phrase.startsWith('out of the room')) return 'out_of_room';
  if (phrase.startsWith('left')) return 'left';
  if (phrase.startsWith('arrived')) return 'arrived';
  return 'returned';
}

type Paren = { names: string[] } | { notes: { kind: MeetingNote['kind']; nameAsPrinted: string }[] };

/**
 * A parenthetical is a name list only when every comma-separated part is one surname-like token; it is a list of
 * notes only when every part is "<Name> (out of the room|left …|arrived …|returned …)". Anything else is not
 * understood (null).
 */
function readParen(body: string): Paren | null {
  const parts = body.split(',').map((p) => p.trim().replace(/^and /, ''));
  if (parts.some((p) => !p)) return null;
  if (parts.every((p) => SURNAME.test(p))) return { names: parts };
  const notes: { kind: MeetingNote['kind']; nameAsPrinted: string }[] = [];
  for (const p of parts) {
    const m = INLINE_NOTE.exec(p);
    if (!m) return null;
    notes.push({ kind: noteKind(m[2]), nameAsPrinted: m[1] });
  }
  return { notes };
}

const PAREN = String.raw`(?:\s*\(([^()]*)\))?`;
const TALLY = new RegExp(
  String.raw`^Ayes:\s*(\d+)${PAREN},\s*Nays:\s*(\d+)${PAREN},\s*Abstain:\s*(\d+)${PAREN}\s*(?:\.\s*)?(FAILED|PASSED)?\s*\.?$`,
  'i',
);

export interface ParsedTally {
  tally: PrintedTally;
  named: { side: Side; names: string[] }[];
  inlineNotes: MeetingNote[];
  /** 'FAILED' / 'PASSED' as printed, lower-cased; null when the sentence prints no result. */
  printedResult: 'failed' | 'passed' | null;
}

/** Read the part after "received a roll call vote of". Null when it does not match exactly. */
function readTally(tail: string, at: number): ParsedTally | null {
  const m = TALLY.exec(tail.trim());
  if (!m) return null;
  const tally: PrintedTally = { yes: Number(m[1]), no: Number(m[3]), abstain: Number(m[5]) };
  const named: { side: Side; names: string[] }[] = [];
  const inlineNotes: MeetingNote[] = [];
  const sides: [Side, string | undefined][] = [
    ['yes', m[2]],
    ['no', m[4]],
    ['abstain', m[6]],
  ];
  for (const [side, body] of sides) {
    if (body === undefined) continue;
    const p = readParen(body);
    if (!p) return null;
    if ('names' in p) named.push({ side, names: p.names });
    else for (const n of p.notes) inlineNotes.push({ ...n, at });
  }
  const printedResult = m[7] ? (m[7].toLowerCase() as 'failed' | 'passed') : null;
  return { tally, named, inlineNotes, printedResult };
}

const ITEM = String.raw`(Appropriation Ordinance|Ordinance|Resolution) (\d{2,4}-\d{1,3})`;
const ITEM_PREFIX: Record<string, string> = {
  'Appropriation Ordinance': 'App Ord',
  Ordinance: 'Ord',
  Resolution: 'Res',
};

type Subject = { kind: 'vote'; itemNumber: string; question: string } | { kind: 'ignore' } | { kind: 'unknown' };

const SUBJECTS: { re: RegExp; question: (m: RegExpExecArray) => string; item: (m: RegExpExecArray) => [string, string] }[] = [
  {
    re: new RegExp(`^to adopt Amendment (\\d{1,3})(?: \\(as revised\\))? to ${ITEM}(?: as amended)?$`),
    question: (m) => `Amendment ${m[1]}`,
    item: (m) => [m[2], m[3]],
  },
  {
    re: new RegExp(`^to adopt ${ITEM}(?: as amended)?$`),
    question: () => 'Final passage',
    item: (m) => [m[1], m[2]],
  },
  {
    re: new RegExp(`^that ${ITEM}(?: as amended)? be adopted$`),
    question: () => 'Final passage',
    item: (m) => [m[1], m[2]],
  },
  {
    re: new RegExp(`^to override the (?:Mayor['’]s |mayoral )?veto (?:of|on) ${ITEM}$`),
    question: () => 'Veto override',
    item: (m) => [m[1], m[2]],
  },
];

/**
 * Procedural motions are not part of the voting record. The brief's list (introduce, read by title, postpone,
 * table, call the question, agenda, withdraw, minutes) plus appointments to boards and commissions, which are
 * not legislation and have no item number.
 */
const PROCEDURAL =
  /\b(?:introduc\w*|read by title|postpon\w*|table|tabled|call the question|agenda|withdraw\w*|minutes|appoint\w*)\b/i;

/** Classify a motion: "to adopt Ordinance 21-23", "that Ordinance 22-07 be adopted", "to override the veto of …". */
function classifyMotion(motion: string): Subject {
  const t = motion.trim().replace(/\.$/, '');
  for (const s of SUBJECTS) {
    const m = s.re.exec(t);
    if (m) {
      const [type, num] = s.item(m);
      return { kind: 'vote', itemNumber: `${ITEM_PREFIX[type]} ${num}`, question: s.question(m) };
    }
  }
  return PROCEDURAL.test(t) ? { kind: 'ignore' } : { kind: 'unknown' };
}

const MOVED = /^(?:[A-Z][\w.'’-]*\s){0,3}?[A-Z][\w'’-]* moved(?: and (?:it was|[A-Z][\w'’-]*(?: [A-Z][\w'’-]*)?) seconded)? (.+)$/;
const VOTE = /^(The motion(?: to (.+?))?) received a roll call vote of (.+)$/;

/**
 * Read one roll-call sentence's tally, names and inline notes. Returns null when the tally part does not match
 * exactly. The subject is not read here.
 */
export function parseRollCallSentence(sentence: string, index: number): ParsedTally | null {
  const at = sentence.indexOf('received a roll call vote of ');
  if (at < 0) return null;
  return readTally(sentence.slice(at + 'received a roll call vote of '.length), index);
}

/** FAILED printed → failed; PASSED printed needs Ayes > Nays; a veto override needs a printed result; else Ayes > Nays. */
export function rollCallOutcome(p: ParsedTally, question: string): 'passed' | 'failed' | null {
  if (p.printedResult === 'failed') return 'failed';
  if (p.printedResult === 'passed') return p.tally.yes > p.tally.no ? 'passed' : null;
  if (question === 'Veto override') return null; // a veto override needs a printed result
  return p.tally.yes > p.tally.no ? 'passed' : 'failed';
}

// ---------------------------------------------------------------------------------------------------------------
// Attendance
// ---------------------------------------------------------------------------------------------------------------

const ATT_FIELD = /Council ?members (present|absent)(?: via [^:]+)?:/gi;
const ATT_REMARK = new RegExp(`^(arrived|left)(?: the meeting)?(?: at)? (${TIME})$`, 'i');

interface Attendance {
  attendance: AttendanceEntry[];
  /** Arrivals, placed before the first roll call by parseMinutes. */
  arrivals: MeetingNote[];
  /** Departures printed in attendance: they carry no position among the votes, so `at` is null. */
  unplaced: MeetingNote[];
  /** Attendance entries whose remark is not understood (e.g. "offline at 8:19pm, online at 8:21pm"). */
  unclear: string[];
}

/** Split on commas that are not inside parentheses. */
function splitTopLevel(s: string): string[] {
  const out: string[] = [];
  let depth = 0;
  let cur = '';
  for (const ch of s) {
    if (ch === '(') depth++;
    if (ch === ')') depth = Math.max(0, depth - 1);
    if (ch === ',' && depth === 0) {
      out.push(cur);
      cur = '';
    } else cur += ch;
  }
  out.push(cur);
  return out;
}

/**
 * One attendance entry: "Dave Rollo (absent)", "Stephen Volan (arrived 6:31pm)", "Matt Flaherty*". The remark in
 * parentheses must be "absent" or "arrived|left [the meeting] [at] <time>" parts; anything else sends the entry to
 * `unclear` (the name is still listed, with no notes).
 */
function readAttendee(raw: string, absent: boolean, out: Attendance): void {
  let s = raw.trim().replace(/^and /, '').replace(/\.$/, '').trim();
  if (!s || /^none$/i.test(s)) return;
  let isAbsent = absent;
  const notes: { kind: 'arrived' | 'left' }[] = [];
  const paren = /\s*\(([^()]*)\)\s*$/.exec(s);
  if (paren) {
    s = s.slice(0, paren.index).trim();
    for (const part of paren[1].split(',').map((p) => p.trim())) {
      if (/^absent$/i.test(part)) isAbsent = true;
      else {
        const m = ATT_REMARK.exec(part);
        if (!m) {
          // Keep the name (the member is listed) but no notes from a remark only partly understood.
          out.unclear.push(raw.trim());
          notes.length = 0;
          break;
        }
        notes.push({ kind: m[1].toLowerCase() as 'arrived' | 'left' });
      }
    }
  }
  s = s.replace(/\s*\*$/, '').trim();
  if (!s || /[()]/.test(s)) {
    out.unclear.push(raw.trim());
    return;
  }
  out.attendance.push({ nameAsPrinted: s, absent: isAbsent });
  for (const n of notes) {
    if (n.kind === 'arrived') out.arrivals.push({ kind: 'arrived', nameAsPrinted: s, at: null });
    else out.unplaced.push({ kind: 'left', nameAsPrinted: s, at: null });
  }
}

const NUMBERED = /^\s*\d+\.\s*\S/;
const MEMBERS_SUBHEAD = /^\s*(?:Council ?Members|Members|Council ?members present)\s*:\s*$/i;

function readAttendance(text: string): Attendance {
  const out: Attendance = { attendance: [], arrivals: [], unplaced: [], unclear: [] };

  // Single-column minutes: a numbered heading naming the roll call ("1. Roll Call", "1. City Council roll call
  // and welcome"), a "Council Members:" subheading, then one member per line until a blank line or subheading.
  const lines = stripMargin(text).split('\n');
  const head = lines.findIndex((l) => NUMBERED.test(l) && /\broll call\b/i.test(l));
  if (head >= 0) {
    let i = head + 1;
    while (i < lines.length && !MEMBERS_SUBHEAD.test(lines[i]) && !NUMBERED.test(lines[i])) i++;
    if (i < lines.length && MEMBERS_SUBHEAD.test(lines[i])) {
      const entries: string[] = [];
      for (i++; i < lines.length; i++) {
        const l = lines[i].trim();
        if (!l) {
          if (entries.length) break;
          continue;
        }
        if (/:$/.test(l) || NUMBERED.test(l)) break;
        const left = l.split(/\s{2,}/)[0];
        const last = entries.length - 1;
        // A remark in parentheses can wrap onto the next line: "Matt Flaherty (arrived at 6:32pm," "left at 9:33pm)".
        if (last >= 0 && (entries[last].match(/\(/g) ?? []).length > (entries[last].match(/\)/g) ?? []).length) {
          entries[last] += ' ' + left;
        } else entries.push(left);
      }
      for (const e of entries) readAttendee(e, false, out);
      return out;
    }
  }

  // Two-column minutes (2020–2022): "Councilmembers present: A, B, …" / "Councilmembers absent: none".
  const para = paragraphs(text).find((p) => /^Council ?members present/i.test(p));
  if (!para) return out;
  const fields = [...para.matchAll(ATT_FIELD)];
  fields.forEach((f, k) => {
    const end = k + 1 < fields.length ? fields[k + 1].index : para.length;
    const value = para.slice(f.index + f[0].length, end);
    for (const part of splitTopLevel(value)) readAttendee(part, f[1].toLowerCase() === 'absent', out);
  });
  return out;
}

// ---------------------------------------------------------------------------------------------------------------
// Body notes
// ---------------------------------------------------------------------------------------------------------------

const TITLE = String.raw`(?:(?:Council President|Council Vice President|Councilmember|Council Member|Cm\.) )?`;
const BODY_NOTE = new RegExp(
  `^${TITLE}(${NOTE_NAME}) (was out of the room|left the (?:meeting|room)(?: at ${TIME})?|returned(?: to the (?:meeting|room))?(?: at ${TIME})?|arrived(?: at)? ${TIME})(?: \\[${TIME}\\])?\\.?$`,
);

function readBodyNote(sentence: string): { kind: MeetingNote['kind']; nameAsPrinted: string } | null {
  const m = BODY_NOTE.exec(sentence);
  if (!m) return null;
  const phrase = m[2];
  const kind: MeetingNote['kind'] = phrase.startsWith('was out')
    ? 'out_of_room'
    : phrase.startsWith('left')
      ? 'left'
      : phrase.startsWith('arrived')
        ? 'arrived'
        : 'returned';
  return { kind, nameAsPrinted: m[1] };
}

// ---------------------------------------------------------------------------------------------------------------
// The parser
// ---------------------------------------------------------------------------------------------------------------

/** Read one set of approved minutes (layout text). */
export function parseMinutes(text: string, meetingDate: string): MinutesParse {
  const att = readAttendance(text);
  const attendance = att.attendance;
  const rollCalls: MinutesRollCall[] = [];
  // Attendance remarks the parser does not understand may change who was in the room for a vote: they go to
  // unparsed so the meeting is held for a person.
  const unparsed: string[] = att.unclear.map((e) => `Attendance: ${e}`);
  const notes: MeetingNote[] = [...att.unplaced];
  // Notes waiting for the next roll call; `at` is filled in when one is recorded (or at the end).
  const pending: MeetingNote[] = [...att.arrivals];
  const place = () => {
    for (const n of pending) notes.push({ ...n, at: rollCalls.length });
    pending.length = 0;
  };

  for (const para of paragraphs(text)) {
    const sentences = splitSentences(para);
    sentences.forEach((sentence, k) => {
      if (!/roll call vote/i.test(sentence)) {
        const n = readBodyNote(sentence);
        if (n) pending.push({ ...n, at: null });
        return;
      }
      const v = VOTE.exec(sentence);
      if (!v) {
        unparsed.push(sentence);
        return;
      }
      // Subject: from the sentence itself ("The motion to adopt …"), or, for a bare "The motion received …",
      // from the motion sentence immediately before it in the same paragraph. Anything else is not understood.
      let subject: Subject;
      let full = sentence;
      if (v[2] !== undefined) subject = classifyMotion(`to ${v[2]}`);
      else {
        const prev = k > 0 ? MOVED.exec(sentences[k - 1]) : null;
        subject = prev ? classifyMotion(prev[1]) : { kind: 'unknown' };
        if (prev) full = `${sentences[k - 1]} ${sentence}`;
      }
      const index = rollCalls.length;
      const parsed = parseRollCallSentence(sentence, index);
      if (subject.kind === 'ignore') {
        // A procedural vote is not recorded. Arrivals and departures printed in it still matter for later votes;
        // "out of the room" applies to that vote only and is dropped with it.
        for (const n of parsed?.inlineNotes ?? []) if (n.kind !== 'out_of_room') pending.push({ ...n, at: null });
        return;
      }
      if (subject.kind === 'unknown' || !parsed) {
        unparsed.push(full);
        return;
      }
      const outcome = rollCallOutcome(parsed, subject.question);
      if (!outcome) {
        unparsed.push(full);
        return;
      }
      place();
      rollCalls.push({
        index,
        itemNumber: subject.itemNumber,
        question: subject.question,
        tally: parsed.tally,
        named: parsed.named,
        inlineNotes: parsed.inlineNotes,
        outcome,
        sentence: full,
      });
    });
  }
  place(); // notes after the last roll call are placed at the end
  return { meetingDate, attendance, notes, rollCalls, unparsed };
}

// ---------------------------------------------------------------------------------------------------------------
// PDF to layout text
// ---------------------------------------------------------------------------------------------------------------

const median = (xs: number[]): number => {
  if (!xs.length) return 0;
  const s = [...xs].sort((a, b) => a - b);
  return s[Math.floor((s.length - 1) / 2)];
};

/**
 * Rebuild layout text (one printed line per line, columns kept apart by spaces) from positioned PDF text runs.
 * Sideways runs are dropped. A vertical gap wider than 1.6 line spacings starts a new paragraph (blank line).
 */
export function layoutLines(items: PdfTextItem[]): string[] {
  const flat = items.filter((i) => (i.dir ?? 0) === 0 && i.str.trim());
  if (!flat.length) return [];
  const cw = median(flat.filter((i) => i.str.length >= 3).map((i) => i.w / i.str.length)) || 5;
  const minX = Math.min(...flat.map((i) => i.x));
  const out: string[] = [];
  const pages = [...new Set(flat.map((i) => i.page))].sort((a, b) => a - b);
  for (const page of pages) {
    const rows: { y: number; runs: PdfTextItem[] }[] = [];
    for (const it of flat.filter((i) => i.page === page).sort((a, b) => b.y - a.y || a.x - b.x)) {
      const row = rows.find((r) => Math.abs(r.y - it.y) < 2);
      if (row) row.runs.push(it);
      else rows.push({ y: it.y, runs: [it] });
    }
    rows.sort((a, b) => b.y - a.y);
    const spacing = median(rows.slice(1).map((r, k) => rows[k].y - r.y).filter((d) => d > 0)) || 12;
    rows.forEach((row, k) => {
      if (k > 0 && rows[k - 1].y - row.y > spacing * 1.6) out.push('');
      let line = '';
      let end = -Infinity;
      for (const r of row.runs.sort((a, b) => a.x - b.x)) {
        const touching = Math.abs(r.x - end) < 0.5;
        const col = Math.round((r.x - minX) / cw);
        if (touching) line += r.str;
        else line = line.padEnd(Math.max(col, line.length ? line.length + 1 : 0)) + r.str;
        end = r.x + r.w;
      }
      out.push(line.replace(/\s+$/, ''));
    });
  }
  return out;
}

/**
 * Text of a minutes PDF in the layout the parser reads. `extractPdfText` collapses each page to one line, which
 * loses the attendance lines, paragraphs and the margin column, so this rebuilds lines from the positioned runs
 * (`extractPdfItems`); `stripMargin` then drops the right margin column of two-column minutes.
 */
export async function minutesTextFromPdf(bytes: Uint8Array): Promise<string> {
  return layoutLines(await extractPdfItems(bytes)).join('\n');
}
