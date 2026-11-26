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
const MONTH_NAME = '(?:January|February|March|April|May|June|July|August|September|October|November|December)';
/**
 * Page headers and footers: "Meeting Date: 06-10-26 p. 3", "p. 4 Meeting Date: 02-28-2024", "Meeting Date: June 10,
 * 2026", a bare "February 04, 2026", and "Docusign Envelope ID: …".
 */
const FOOTER = new RegExp(
  String.raw`^\s*(?:(?:p\.\s*\d+\s+)?Meeting Date:\s*(?:\d{2}-\d{2}-\d{2}(?:\d{2})?|${MONTH_NAME} \d{1,2}, \d{4})(?:\s+p\.\s*\d+)?|${MONTH_NAME} \d{1,2}, \d{4}|Docusign Envelope ID:.*)\s*$`,
);
/** A numbered agenda heading: "8.2. Resolution 2025-02", "7.4 Resolution 2026-18", or a lone "8.". */
const AGENDA_HEADING = /^\s*[1-9]\d?(?:\.\d+)*(?:\.?\s+[A-Z]|\.\s*$)/;

const ATTENDANCE_LABEL = /^\s*Council ?members (?:present|absent)[^:]*:$/i;

type Row = { blank: true } | { blank: false; body: string; margin: string };

/**
 * Split every printed line into body text and margin text. Blank lines are kept (they separate paragraphs);
 * footers are dropped; a line with only margin text (or a page number) has an empty body.
 */
function layoutRows(text: string): Row[] {
  const rows: Row[] = [];
  for (const raw of text.replace(/\u200b/g, '').replace(/\r\n?/g, '\n').split('\n')) {
    if (!raw.trim()) {
      rows.push({ blank: true });
      continue;
    }
    if (FOOTER.test(raw)) continue;
    // A numbered agenda heading right after a finished sentence starts a new paragraph, so it is not read as the end
    // of the vote sentence before it ("… Abstain: 0. 8.2. Resolution 2025-02").
    const prev = [...rows].reverse().find((r) => r.blank || r.body);
    if (AGENDA_HEADING.test(raw) && prev && !prev.blank && /[.!?)\]"”]$/.test(prev.body.trim())) rows.push({ blank: true });
    const lead = raw.length - raw.trimStart().length;
    if (lead >= MARGIN_COL) {
      rows.push({ blank: false, body: '', margin: raw.trim() });
      continue;
    }
    let body = raw;
    let margin = '';
    const gap = /(\S)( {3,})(?=\S)/g;
    let m: RegExpExecArray | null;
    while ((m = gap.exec(raw))) {
      const rightStart = m.index + 1 + m[2].length;
      // Memoranda align attendance names after a wide gap: "Councilmembers present via teleconference:    Matt …".
      if (ATTENDANCE_LABEL.test(raw.slice(0, m.index + 1))) continue;
      if (rightStart >= MARGIN_COL) {
        body = raw.slice(0, m.index + 1);
        margin = raw.slice(rightStart).trim();
        break;
      }
    }
    rows.push({ blank: false, body: body.replace(/\s+$/, ''), margin });
  }
  return rows;
}

/**
 * Remove the right margin column, margin-only lines and page footers. Lines that were blank stay blank (they
 * separate paragraphs); lines that held only margin text or a footer are removed, so they cannot split a sentence.
 */
export function stripMargin(text: string): string {
  return layoutRows(text)
    .filter((r) => r.blank || r.body)
    .map((r) => (r.blank ? '' : r.body))
    .join('\n');
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

/**
 * Paragraphs of the body text, each joined into one line, with the margin text printed between the same blank
 * lines (the paragraph's line span), joined the same way.
 */
function paragraphsWithMargin(text: string): { text: string; margin: string }[] {
  const out: { text: string; margin: string }[] = [];
  let body: string[] = [];
  let margin: string[] = [];
  const flush = () => {
    if (body.length) out.push({ text: joinLines(body), margin: joinLines(margin) });
    body = [];
    margin = [];
  };
  for (const r of layoutRows(text)) {
    if (r.blank) flush();
    else {
      if (r.body.trim()) body.push(r.body);
      if (r.margin) margin.push(r.margin);
    }
  }
  flush();
  return out;
}

/** Paragraphs of the body text (margin removed), each joined into one line. */
function paragraphs(text: string): string[] {
  return paragraphsWithMargin(text).map((p) => p.text);
}

const ABBREV = /(?:^|[\s(])(?:Cm|Mr|Ms|Mrs|Dr|St|Inc|No|Jr|Sr|Ave|Rd|vs|etc|[A-Z]|[a-z]\.[a-z])$/;

/** Split one paragraph into sentences. A lone "FAILED" / "PASSED" after a tally stays with its sentence. */
function splitSentences(para: string): string[] {
  // Memoranda label each line "MOTION:" or "ACTION:"; a label starts a sentence and is not part of it.
  const pieces = para.split(/\s+(?=(?:MOTION|ACTION):\s)/).map((x) => x.replace(/^(?:MOTION|ACTION):\s+/, ''));
  return pieces.length > 1 ? pieces.flatMap(splitSentences) : splitPlain(pieces[0]);
}

function splitPlain(para: string): string[] {
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

/** Words that look like a surname token in a parenthetical but are not a member's name. */
const NOT_NAMES = new Set([
  'none', 'all', 'unanimous', 'recused', 'remote', 'absent', 'present', 'zoom', 'abstain', 'abstained',
  'excused', 'vacant', 'online', 'offline',
]);

type Paren = { names: string[] } | { notes: { kind: MeetingNote['kind']; nameAsPrinted: string }[] };

/**
 * A parenthetical is a name list only when every comma-separated part is one surname-like token; it is a list of
 * notes only when every part is "<Name> (out of the room|left …|arrived …|returned …)". Anything else is not
 * understood (null).
 */
function readParen(body: string): Paren | null {
  const parts = body.split(',').map((p) => p.trim().replace(/^and /, ''));
  if (parts.some((p) => !p)) return null;
  if (parts.some((p) => NOT_NAMES.has(p.toLowerCase()))) return null;
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
    if ('names' in p) {
      // The printed names must account for the whole side; a different count is not understood.
      if (p.names.length !== tally[side]) return null;
      named.push({ side, names: p.names });
    }
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

const RC = String.raw`Reasonable Condition (\d{1,3})`;

/** Amendment and condition numbers as two zero-padded digits ("1", "01" and "001" are all "01"), so ids match. */
export const twoDigits = (n: string): string => String(Number(n)).padStart(2, '0');

const SUBJECTS: { re: RegExp; question: (m: RegExpExecArray) => string; item: (m: RegExpExecArray) => [string, string] }[] = [
  {
    re: new RegExp(`^to adopt Amendment (\\d{1,3})(?: \\(as revised\\))? to ${ITEM}(?: as amended)?$`),
    question: (m) => `Amendment ${twoDigits(m[1])}`,
    item: (m) => [m[2], m[3]],
  },
  {
    re: new RegExp(`^to adopt ${RC} to ${ITEM}$`),
    question: (m) => `Reasonable Condition ${twoDigits(m[1])}`,
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
 * Procedural motions are not part of the voting record. Each form is anchored to the start of the motion, so a
 * procedural word later in a motion never hides it: the brief's list (introduce, read by title, postpone, table,
 * call the question, agenda, withdraw, minutes) plus appointments to boards and commissions, which are not
 * legislation and have no item number.
 */
const PROCEDURAL: RegExp[] = [
  /^to (?:introduce|postpone|table|call the question|withdraw|appoint|make the following appointments?)\b/i,
  /^to (?:approve|amend|adopt) the (?:agenda|minutes)\b/i,
  /^that .+ be (?:introduced|read by title)\b/i,
];

/** A motion that names adoption and an item number must parse fully; it is never ignored. */
const ADOPT_WITH_ITEM = new RegExp(`\\badopt(?:ed)?\\b.*${ITEM}|${ITEM}.*\\badopt(?:ed)?\\b`);

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
  if (ADOPT_WITH_ITEM.test(t)) return { kind: 'unknown' };
  return PROCEDURAL.some((re) => re.test(t)) ? { kind: 'ignore' } : { kind: 'unknown' };
}

/**
 * Two-column minutes print a heading beside each vote: "Vote to adopt Amendment 01 to Ordinance 17-10 [10:23pm]".
 * Used only for a bare "The motion received…" with no moved sentence before it, and only when exactly one such
 * heading is printed within the paragraph's line span.
 */
const MARGIN_HEADING = new RegExp(
  `Vote to adopt (?:(Amendment|Reasonable Condition) (\\d{1,3}) to )?${ITEM}(?: as amended)?`,
  'g',
);

function subjectFromMargin(margin: string): { subject: Subject; heading: string } | null {
  const found = [...margin.matchAll(MARGIN_HEADING)];
  if (found.length !== 1) return null;
  const m = found[0];
  const question = m[1] ? `${m[1]} ${twoDigits(m[2])}` : 'Final passage';
  return { subject: { kind: 'vote', itemNumber: `${ITEM_PREFIX[m[3]]} ${m[4]}`, question }, heading: m[0] };
}

/** A sentence right after a vote saying that it overrode the veto. */
const OVERRODE = /\bthe vote overr?ode the (?:Mayor['’]s |mayoral )?veto\b/i;

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

/** "(Andy)" or "“Andy”" between a first and a last name. */
const NICKNAME = /(?<=^[A-Z][\w'’.-]* )[(“"][A-Z][a-z]+[)”"](?= [A-Z])/;

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
  const paren = /\s*\(([^()]*)\)\s*$/.exec(s.replace(NICKNAME, (x) => ' '.repeat(x.length)));
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
  // A nickname between first and last name ("Andrew (Andy) Ruff", "Andrew “Andy” Ruff") is part of the name.
  const bare = s.replace(NICKNAME, ' ');
  if (!s || /[()]/.test(bare)) {
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

  // Two-column minutes and memoranda: "Councilmembers present: A, B, …" / "Councilmembers absent: none". The block
  // ends at the end of the "absent" line (unless that line ends in a comma): what follows ("City staff …",
  // "Clerk's Note: …") is not attendance.
  const start = lines.findIndex((l) => /^\s*Council ?members present/i.test(l));
  if (start < 0) return out;
  const block: string[] = [];
  for (let i = start; i < lines.length && lines[i].trim(); i++) {
    block.push(lines[i]);
    if (/^\s*Council ?members absent/i.test(lines[i]) && !/,\s*$/.test(lines[i])) break;
  }
  const para = joinLines(block);
  const fields = [...para.matchAll(ATT_FIELD)];
  const parts: { raw: string; absent: boolean; zoom: boolean }[] = [];
  fields.forEach((f, k) => {
    const end = k + 1 < fields.length ? fields[k + 1].index : para.length;
    const value = para.slice(f.index + f[0].length, end);
    for (const raw of splitTopLevel(value)) parts.push({ raw, absent: f[1].toLowerCase() === 'absent', zoom: /via/i.test(f[0]) });
  });
  for (const p of mergeZoomToInPerson(parts)) readAttendee(p.raw, p.absent, out);
  return out;
}

const minutesOf = (t: string): number => {
  const m = /^(\d{1,2}):(\d{2})\s?([ap])/i.exec(t) as RegExpExecArray;
  return ((Number(m[1]) % 12) + (m[3].toLowerCase() === 'p' ? 12 : 0)) * 60 + Number(m[2]);
};

/**
 * One exact pattern lists a member twice: "Matt Flaherty (arrived in person at 6:44pm)" among those present and
 * "Matt Flaherty (left Zoom at 6:39pm)" among those on Zoom, the departure before the arrival. That is one member who
 * arrived in person: the Zoom entry is dropped and the in-person one reads as "arrived at 6:44pm". Any other repeat
 * stays, and the checks hold it.
 */
function mergeZoomToInPerson<T extends { raw: string; zoom: boolean }>(parts: T[]): T[] {
  const IN = new RegExp(`^\\s*(.+?) \\(arrived in person at (${TIME})\\)\\s*$`);
  const OUT = new RegExp(`^\\s*(.+?) \\(left Zoom at (${TIME})\\)\\s*$`);
  const drop = new Set<T>();
  const out = parts.map((p) => {
    const a = IN.exec(p.raw);
    if (!a || p.zoom) return p;
    const z = parts.find((q) => q.zoom && OUT.exec(q.raw)?.[1] === a[1]);
    const left = z ? OUT.exec(z.raw) : null;
    if (!z || !left || minutesOf(left[2]) > minutesOf(a[2])) return p;
    drop.add(z);
    return { ...p, raw: `${a[1]} (arrived at ${a[2]})` };
  });
  return out.filter((p) => !drop.has(p));
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

  for (const para of paragraphsWithMargin(text)) {
    const sentences = splitSentences(para.text);
    // A margin heading can name the subject of a bare vote only when the paragraph holds one roll-call sentence.
    const rollCallSentences = sentences.filter((x) => /roll call vote/i.test(x)).length;
    // True once the paragraph has shown an ignored motion (procedural, or a voice vote) and no later motion.
    let ignoredContext = false;
    // "Out of the room" notes from the sentence just before; placed only on a roll call recorded next.
    let awaiting: { note: MeetingNote; ignoredContext: boolean }[] = [];
    // recordedAt: placed on that roll call. 'drop': it belongs to an ignored motion. 'unplaced': it may belong to
    // a motion that follows. 'context': it goes with the motion before it.
    const settle = (recordedAt: number | null, how: 'drop' | 'unplaced' | 'context') => {
      for (const w of awaiting) {
        if (recordedAt !== null) notes.push({ ...w.note, at: recordedAt });
        else if (how === 'unplaced') notes.push({ ...w.note, at: null });
        else if (how === 'context' && !w.ignoredContext) notes.push({ ...w.note, at: null });
      }
      awaiting = [];
    };

    sentences.forEach((sentence, k) => {
      if (!/roll call vote/i.test(sentence)) {
        const moved = MOVED.exec(sentence);
        const movedIgnored = moved ? classifyMotion(moved[1]).kind === 'ignore' : false;
        const voice = /\bvoice vote\b/i.test(sentence);
        // A note followed by an ignored motion or a voice-vote result belongs to that motion: dropped with it. A
        // note followed by any other moved sentence may belong to that next motion: unplaced. Otherwise the note
        // goes with the motion before it (dropped if that one was ignored, unplaced if not).
        if (moved) settle(null, movedIgnored ? 'drop' : 'unplaced');
        else if (voice) settle(null, 'drop');
        else settle(null, 'context');
        if (moved) ignoredContext = movedIgnored;
        if (voice) ignoredContext = true;
        const n = readBodyNote(sentence);
        if (n?.kind === 'out_of_room') awaiting.push({ note: { ...n, at: null }, ignoredContext });
        else if (n) pending.push({ ...n, at: null });
        return;
      }
      const v = VOTE.exec(sentence);
      if (!v) {
        settle(null, 'context');
        unparsed.push(sentence);
        return;
      }
      // Subject: from the sentence itself ("The motion to adopt …"); for a bare "The motion received …", from the
      // moved sentence immediately before it in the same paragraph; failing that, from the one margin heading in
      // the paragraph's line span. Anything else is not understood.
      let subject: Subject;
      let full = sentence;
      if (v[2] !== undefined) subject = classifyMotion(`to ${v[2]}`);
      else {
        const prev = k > 0 ? MOVED.exec(sentences[k - 1]) : null;
        if (prev) {
          subject = classifyMotion(prev[1]);
          full = `${sentences[k - 1]} ${sentence}`;
        } else {
          const fromMargin = rollCallSentences === 1 ? subjectFromMargin(para.margin) : null;
          subject = fromMargin ? fromMargin.subject : { kind: 'unknown' };
          if (fromMargin) full = `${sentence} [margin: ${fromMargin.heading}]`;
        }
      }
      const index = rollCalls.length;
      const parsed = parseRollCallSentence(sentence, index);
      if (subject.kind === 'ignore') {
        // A procedural vote is not recorded. Arrivals and departures printed in it still matter for later votes;
        // "out of the room" applies to that vote only and is dropped with it.
        for (const n of parsed?.inlineNotes ?? []) if (n.kind !== 'out_of_room') pending.push({ ...n, at: null });
        settle(null, 'drop');
        ignoredContext = true;
        return;
      }
      ignoredContext = false;
      if (subject.kind === 'unknown' || !parsed) {
        settle(null, 'context');
        unparsed.push(full);
        return;
      }
      // "The motion to adopt X received … . <Name> noted that the vote overrode the veto …": the minutes say this
      // "adopt" was a veto override, and that it succeeded.
      if (subject.question === 'Final passage' && OVERRODE.test(sentences[k + 1] ?? '')) {
        subject = { ...subject, question: 'Veto override' };
        if (parsed.printedResult === null && parsed.tally.yes > parsed.tally.no) parsed.printedResult = 'passed';
      }
      const outcome = rollCallOutcome(parsed, subject.question);
      if (!outcome) {
        settle(null, 'context');
        unparsed.push(full);
        return;
      }
      place();
      settle(index, 'context');
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
    settle(null, 'context');
  }
  place(); // notes after the last roll call are placed at the end
  return { meetingDate, attendance, notes, rollCalls, unparsed };
}

// ---------------------------------------------------------------------------------------------------------------
// Printed meeting date
// ---------------------------------------------------------------------------------------------------------------

const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October',
  'November', 'December'];
const MONTH = `(${MONTHS.join('|')})`;
const DATE_MDY = new RegExp(`\\b${MONTH}\\s+(\\d{1,2}),?\\s+(\\d{4})\\b`);
const DATE_DMY = new RegExp(`\\b(\\d{1,2})\\s+${MONTH},?\\s+(\\d{4})\\b`);
const HEADER_LINES = 20;

/**
 * The meeting date printed in the document's header (its first 20 lines), as YYYY-MM-DD; null when none is printed.
 * The city has attached one meeting's minutes to another meeting (2025-03-05 holds the 2025-05-07 minutes), so a
 * document is read for a meeting only when this date is that meeting's date or absent.
 */
export function printedMeetingDate(text: string): string | null {
  const iso = (y: string, month: string, d: string) =>
    `${y}-${String(MONTHS.indexOf(month) + 1).padStart(2, '0')}-${d.padStart(2, '0')}`;
  for (const line of text.split('\n').slice(0, HEADER_LINES)) {
    const a = DATE_MDY.exec(line);
    const b = DATE_DMY.exec(line);
    if (a && (!b || a.index <= b.index)) return iso(a[3], a[1], a[2]);
    if (b) return iso(b[3], b[2], b[1]);
  }
  return null;
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
 * A run more than two character widths after the previous run's end is a new column (three spaces or more).
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
        const gap = r.x - end;
        const col = Math.round((r.x - minX) / cw);
        if (Math.abs(gap) < 0.5) line += r.str;
        // A gap of more than two character widths is a column gutter: at least three spaces, so the margin column
        // is kept apart even when wide body text has run past its estimated column.
        else if (line.length && gap > 2 * cw) line = line.padEnd(Math.max(col, line.length + 3)) + r.str;
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
