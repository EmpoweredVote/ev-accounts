/**
 * maRollCallEvidence — the Massachusetts House roll-call lane of the research verifier.
 *
 * A Massachusetts House roll call is a one-page PDF (malegislature.gov/RollCall/193/HouseRollCall135.pdf)
 * that prints a grid of members, each as a vote mark and a SURNAME only:
 *
 *   Y   Diggs       Y   Kerans      Y   Ryan        N   Smola
 *
 * A label carries an initial when the clerk must tell two members apart ("Moran M.", "Ramos, A.").
 * The joined page text interleaves four columns of marks and surnames, so no snippet can tie a full
 * name to a vote, and the verifier answered every such source `name_not_present`. LegiScan has no record
 * of some of these roll calls at all. The PDF prints no party, and nothing here adds one.
 *
 * The verifier's fetch (adapters/maLegislatureAdapter.ts) reads the PDF's positioned text and RENDERS
 * it in one fixed form:
 *
 *   Massachusetts House roll call 135 (193rd General Court), 2024-07-18.
 *   Question: H.4885 - On acceptance of the report
 *   Yea 124; Nay 33; Not Voting 2; Present 0.
 *   Yea (124): Mr. Speaker; Moran M.; … Nay (33): … Not Voting (2): … Present (0):
 *   Recorded after the vote: Farley-Bouvier.
 *
 * A vote seat carries ONE canonical line built from that render:
 *
 *   Massachusetts House roll call 135 (193rd General Court), H.4885 - On acceptance of the report: Kilcoyne voted Yea.
 *
 * The verifier fetches the render again and checks the line field by field: roll number and General
 * Court (also against the URL), the question, and the label listed under that vote. The label must fit
 * the politician: their surname, and their first initial when the clerk printed one. A bare surname
 * that the same roll call prints for two members (one bare, one with an initial, or both bare) names
 * neither of them and never verifies. "Mr. Speaker" names no one and never verifies.
 *
 * A read is refused (null) unless every printed label carries exactly one mark and the mark counts
 * equal the tally the PDF prints. A misread grid fails closed.
 */
import { normalizeText, type SnippetVerdict } from './researchVerifier.js';
import type { PdfTextItem } from './pdfText.js';
import { printedNameFits } from './igaRollCallEvidence.js';

/** https://malegislature.gov/RollCall/<General Court>/HouseRollCall<n>.pdf */
const ROLL_PDF = /^https:\/\/(?:www\.)?malegislature\.gov\/RollCall\/(\d{3})\/HouseRollCall(\d+)\.pdf$/i;

export const MA_VOTES = ['Yea', 'Nay', 'Not Voting', 'Present'] as const;
export type MaVote = (typeof MA_VOTES)[number];
const MARK_VOTE: Record<string, MaVote> = { Y: 'Yea', N: 'Nay', X: 'Not Voting', P: 'Present' };

export interface MaRollCall {
  rollNum: number;
  /** "193" — from the URL; the PDF does not print it. */
  court: string;
  /** "H.4885" (or "S.2572" for a Senate bill voted in the House). */
  bill: string;
  /** "On acceptance of the report". */
  question: string;
  /** ISO date when printed, else ''. */
  date: string;
  tally: { yeas: number; nays: number; notVoting: number };
  groups: Record<MaVote, string[]>;
  /** Labels the PDF marks "*" (=AFTER VOTE). */
  afterVote: string[];
}

export interface MaRollCallLine {
  rollNum: number;
  court: string;
  bill: string;
  question: string;
  name: string;
  vote: MaVote;
}

export function parseMaRollCallUrl(url: string): { court: string; rollNum: number } | null {
  const m = ROLL_PDF.exec(url.trim());
  if (!m) return null;
  return { court: m[1], rollNum: Number(m[2]) };
}

export function isMaRollCallUrl(url: string): boolean {
  return parseMaRollCallUrl(url) !== null;
}

/** 193 → "193rd", 191 → "191st", 111 → "111th". */
export function ordinal(n: string | number): string {
  const v = Number(n);
  const t = v % 100;
  if (t >= 11 && t <= 13) return `${v}th`;
  return `${v}${({ 1: 'st', 2: 'nd', 3: 'rd' } as Record<number, string>)[v % 10] ?? 'th'}`;
}

// ── PDF layout → roll call ────────────────────────────────────────────────────────────────────────

/** A mark prints ~1.6pt below its label's baseline; anything within this is one printed row. */
const ROW_DY = 4;
/** Runs closer than this are one label ("Moran" + "M.", "Fluker" + "Oakley", "Farley-Bouvier" + "*"). */
const WORD_GAP = 20;
/** A mark sits this far or less to the left of the label it belongs to (measured: 20–42pt). */
const MARK_REACH = 60;

interface Run { x: number; y: number; w: number; str: string }

function rowsOf(items: PdfTextItem[]): Run[][] {
  const sorted = items
    .filter((i) => i.str.trim())
    .sort((a, b) => a.page - b.page || b.y - a.y || a.x - b.x);
  const rows: { page: number; y: number; runs: Run[] }[] = [];
  for (const it of sorted) {
    const last = rows[rows.length - 1];
    if (last && last.page === it.page && Math.abs(last.y - it.y) <= ROW_DY) last.runs.push(it);
    else rows.push({ page: it.page, y: it.y, runs: [it] });
  }
  return rows.map((r) => r.runs.sort((a, b) => a.x - b.x));
}

const isMark = (s: string): boolean => /^[YNXP]$/.test(s.trim());

/** "--Jones--" → "Jones": the clerk sets a few labels between dashes; the dashes are not part of a name. */
const cleanLabel = (s: string): string => s.replace(/\s+/g, ' ').replace(/^-+\s*/, '').replace(/\s*-+$/, '').trim();

const TALLY = /^No\.\s*(\d+)\s+(\d+)\s+YEAS\s+(\d+)\s+NAYS\s+(\d+)\s+N\/V$/i;
const QUESTION = /^([HS])\.\s*(\d+)\s+(.+)$/;
const DATE = /\b(\d{2})\/(\d{2})\/(\d{4})\b/;

/** Read a House roll-call PDF's positioned text. Null when it is not one or any count disagrees. */
export function readMaRollCall(items: PdfTextItem[], court: string): MaRollCall | null {
  let house = false;
  let bill = '', question = '', date = '';
  let tally: MaRollCall['tally'] | null = null;
  let rollNum = 0;
  const groups: Record<MaVote, string[]> = { Yea: [], Nay: [], 'Not Voting': [], Present: [] };
  const afterVote: string[] = [];
  let phase: 'top' | 'grid' | 'done' = 'top';

  for (const runs of rowsOf(items)) {
    const whole = runs.map((r) => r.str.trim()).join(' ').replace(/\s+/g, ' ');
    if (phase === 'done') continue;
    if (phase === 'top') {
      if (/^MASSACHUSETTS HOUSE OF REPRESENTATIVES$/i.test(whole)) { house = true; continue; }
      const q = QUESTION.exec(whole);
      if (q && !bill) { bill = `${q[1]}.${q[2]}`; question = q[3].trim(); continue; }
      if (/^Yea and Nay\b/i.test(whole)) {
        const d = DATE.exec(whole);
        if (d) date = `${d[3]}-${d[1]}-${d[2]}`;
        continue;
      }
      const t = TALLY.exec(whole);
      if (t) { rollNum = Number(t[1]); tally = { yeas: Number(t[2]), nays: Number(t[3]), notVoting: Number(t[4]) }; phase = 'grid'; }
      continue;
    }
    // The legend line ("*=AFTER VOTE  P=PRESENT  X=NOT VOTING") ends the grid.
    if (/=AFTER VOTE|=NOT VOTING|=PRESENT/i.test(whole)) { phase = 'done'; continue; }

    // A grid row: [mark] label [mark] label …
    let pending: Run | null = null;
    let cell: { mark: Run; text: string; end: number } | null = null;
    const close = () => {
      if (!cell) return true;
      let label = cell.text;
      const after = /\s*\*$/.test(label);
      label = cleanLabel(label.replace(/\s*\*$/, ''));
      if (!label) return false;
      groups[MARK_VOTE[cell.mark.str.trim()]].push(label);
      if (after) afterVote.push(label);
      cell = null;
      return true;
    };
    for (const r of runs) {
      if (isMark(r.str)) {
        if (!close() || pending) return null; // two marks with no label between them
        pending = r;
        continue;
      }
      if (cell && r.x - cell.end < WORD_GAP) { cell.text += ` ${r.str.trim()}`; cell.end = r.x + r.w; continue; }
      if (!close()) return null;
      // A label with no mark of its own, or a mark too far away, is a misread: fail closed.
      if (!pending || r.x - pending.x > MARK_REACH || r.x <= pending.x) return null;
      cell = { mark: pending, text: r.str.trim(), end: r.x + r.w };
      pending = null;
    }
    if (!close() || pending) return null;
  }

  if (!house || !rollNum || !tally || !bill || !question) return null;
  if (groups.Yea.length !== tally.yeas || groups.Nay.length !== tally.nays) return null;
  if (groups['Not Voting'].length + groups.Present.length !== tally.notVoting) return null;
  return { rollNum, court, bill, question, date, tally, groups, afterVote };
}

// ── render ↔ parse ────────────────────────────────────────────────────────────────────────────────

/** The fixed text the adapter hands the verifier. It prints no party: the PDF prints none. */
export function renderMaRollCall(r: MaRollCall): string {
  const head = `Massachusetts House roll call ${r.rollNum} (${ordinal(r.court)} General Court)${r.date ? `, ${r.date}` : ''}.`;
  const q = `Question: ${r.bill} - ${r.question}`;
  const counts = MA_VOTES.map((v) => `${v} ${r.groups[v].length}`).join('; ') + '.';
  const lists = MA_VOTES.map((v) => `${v} (${r.groups[v].length}): ${r.groups[v].join('; ')}${r.groups[v].length ? '.' : ''}`.trim()).join('\n');
  const after = r.afterVote.length ? `\nRecorded after the vote: ${r.afterVote.join('; ')}.` : '';
  return [head, q, counts, lists].join('\n') + after;
}

const RENDER_HEAD = /^Massachusetts House roll call (\d+) \((\d+)(?:st|nd|rd|th) General Court\)(?:, (\d{4}-\d{2}-\d{2}))?\.$/m;
const RENDER_Q = /^Question: ([HS]\.\d+) - (.+)$/m;
const RENDER_GROUP = /^(Yea|Nay|Not Voting|Present) \((\d+)\):(.*)$/gm;

/** Read back a render. Null when the text is not one. */
export function parseMaRollCallRender(text: string): Omit<MaRollCall, 'tally' | 'afterVote'> | null {
  const h = RENDER_HEAD.exec(text);
  const q = RENDER_Q.exec(text);
  if (!h || !q) return null;
  const groups: Record<MaVote, string[]> = { Yea: [], Nay: [], 'Not Voting': [], Present: [] };
  let seen = 0;
  for (const m of text.matchAll(RENDER_GROUP)) {
    const names = m[3].trim().replace(/\.$/, '');
    const list = names ? names.split('; ').map((s) => s.trim()) : [];
    if (list.length !== Number(m[2])) return null;
    groups[m[1] as MaVote] = list;
    seen++;
  }
  if (seen !== MA_VOTES.length) return null;
  return { rollNum: Number(h[1]), court: h[2], date: h[3] ?? '', bill: q[1], question: q[2].trim(), groups };
}

// ── the canonical line ────────────────────────────────────────────────────────────────────────────

const LINE = new RegExp(
  `^Massachusetts House roll call (\\d+) \\((\\d+)(?:st|nd|rd|th) General Court\\), ([HS]\\.\\d+) - (.+): ([^:]+?) voted (${MA_VOTES.join('|')})\\.$`,
);

export function formatMaRollCallLine(l: MaRollCallLine): string {
  return `Massachusetts House roll call ${l.rollNum} (${ordinal(l.court)} General Court), ${l.bill} - ${l.question}: ${l.name} voted ${l.vote}.`;
}

export function parseMaRollCallLine(text: string): MaRollCallLine | null {
  const m = LINE.exec(text.trim());
  if (!m) return null;
  if (ordinal(m[2]) !== /\((\d+(?:st|nd|rd|th))/.exec(text)![1]) return null;
  return { rollNum: Number(m[1]), court: m[2], bill: m[3], question: m[4].trim(), name: m[5].trim(), vote: m[6] as MaVote };
}

/** The surname of a printed label, and whether the clerk added an initial: "Moran M." → [moran, true]. */
export function labelSurname(label: string): [string, boolean] {
  const p = normalizeText(label);
  const comma = /^(.+?),\s*\S+$/.exec(p);
  if (comma) return [comma[1].trim(), true];
  const initial = /^(.+?)\s+(?:[a-z]\.?){1,2}$/.exec(p);
  if (initial && /\.$|^\S+\s+[a-z]$/.test(p)) return [initial[1].trim(), true];
  return [p, false];
}

/**
 * Does `label`, as printed in this roll call, name this politician? Their surname (and first initial
 * when printed) must fit, and a bare surname must be the only label in the roll call with that surname.
 */
export function maLabelFits(label: string, allLabels: string[], lastName: string, fullName?: string): boolean {
  if (!printedNameFits(label, lastName, fullName)) return false;
  const [sur, hasInitial] = labelSurname(label);
  if (hasInitial) return true;
  return allLabels.filter((l) => labelSurname(l)[0] === sur).length === 1;
}

const allOf = (g: Record<MaVote, string[]>): string[] => MA_VOTES.flatMap((v) => g[v]);

/**
 * Check a canonical line against the render fetched for `url`. `verified` (offset 0) when every field
 * matches; `name_not_present` when the record holds the vote for a label that is not this politician's
 * (or that two members share); otherwise `snippet_not_found`.
 */
export function verifyMaRollCallLine(line: string, url: string, text: string, lastName: string, fullName?: string): SnippetVerdict {
  const u = parseMaRollCallUrl(url);
  const l = parseMaRollCallLine(line);
  const r = parseMaRollCallRender(text);
  if (!u || !l || !r) return { verdict: 'snippet_not_found' };
  if (u.court !== l.court || u.rollNum !== l.rollNum) return { verdict: 'snippet_not_found' };
  if (r.court !== l.court || r.rollNum !== l.rollNum) return { verdict: 'snippet_not_found' };
  if (r.bill !== l.bill || normalizeText(r.question) !== normalizeText(l.question)) return { verdict: 'snippet_not_found' };
  if (!r.groups[l.vote].some((n) => normalizeText(n) === normalizeText(l.name))) return { verdict: 'snippet_not_found' };
  if (!maLabelFits(l.name, allOf(r.groups), lastName, fullName)) return { verdict: 'name_not_present' };
  return { verdict: 'verified', matchOffset: 0 };
}

/** Every canonical line the render holds for this politician (normally one; none when the label is absent or shared). */
export function maRollCallLinesFor(url: string, text: string, lastName: string, fullName?: string): string[] {
  const r = parseMaRollCallRender(text);
  const u = parseMaRollCallUrl(url);
  if (!r || !u || r.court !== u.court || r.rollNum !== u.rollNum) return [];
  const all = allOf(r.groups);
  const out: string[] = [];
  for (const vote of MA_VOTES) {
    for (const name of r.groups[vote]) {
      if (maLabelFits(name, all, lastName, fullName)) {
        out.push(formatMaRollCallLine({ rollNum: r.rollNum, court: r.court, bill: r.bill, question: r.question, name, vote }));
      }
    }
  }
  return out;
}
