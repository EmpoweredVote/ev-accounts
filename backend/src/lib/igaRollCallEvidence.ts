/**
 * igaRollCallEvidence — the Indiana roll-call lane of the research verifier.
 *
 * An Indiana General Assembly roll call is a PDF (iga.in.gov/pdf-documents/…/rollcalls/SB0010.340_H.pdf)
 * that prints each member by surname only, in four columns under YEA / NAY / EXCUSED / NOT VOTING.
 * The joined page text loses the columns, so no snippet can tie a name to a vote. The PDF prints no
 * party. Until 2026-11-02 the site served these files to a browser identity only, so Indiana votes
 * were cited through LegiScan; the official API (adapters/igaAdapter.ts) now hands them to us.
 *
 * The adapter reads the PDF's positioned text and RENDERS it in one fixed, party-free form:
 *
 *   Indiana House roll call 340 (2025): Bill Passed.
 *   SB 10 - Culp - 3rd Reading. Voter registration.
 *   Yea 66; Nay 26; Excused 5; Not Voting 3.
 *   Yea (66): Abbott; Aylesworth; … Nay (26): … Excused (5): … Not Voting (3): …
 *
 * A vote seat carries ONE canonical line built from that render:
 *
 *   Indiana House roll call 340 (2025), SB 10 - Culp - 3rd Reading: Culp voted Yea.
 *
 * The verifier fetches the render again and checks the line field by field: chamber, roll number and
 * session (also against the URL), the motion line, and the surname listed under that vote. The surname
 * must be the politician's own; an initial the clerk adds to tell two members apart ("Smith, H",
 * "Walker K") must fit their first name. "Mr. Speaker" names no one and never verifies.
 *
 * A render is refused (null) unless every group holds exactly the count its heading prints, and the
 * heading counts match the tally box. A misread column fails closed.
 */
import { normalizeText, type SnippetVerdict } from './researchVerifier.js';
import type { PdfTextItem } from './pdfText.js';

/** iga.in.gov/pdf-documents/<assembly>/<session>/<origin chamber>/<bills|resolutions>/<BILL>/rollcalls/<BILL>.<n>_<H|S>.pdf */
const ROLL_PDF =
  /^https:\/\/iga\.in\.gov\/pdf-documents\/\d+\/(\d{4}(?:ss\d)?)\/(?:house|senate)\/(?:bills|resolutions)\/[A-Z]{2}\d{4}\/rollcalls\/[A-Z]{2}\d{4}\.(\d+)_([HS])\.pdf$/i;

export const IGA_VOTES = ['Yea', 'Nay', 'Excused', 'Not Voting'] as const;
export type IgaVote = (typeof IGA_VOTES)[number];
type Chamber = 'House' | 'Senate';

export interface IgaRollCall {
  chamber: Chamber;
  rollNum: number;
  session: string;
  result: string;
  /** The first motion line ("SB 10 - Culp - 3rd Reading"); the line a voter reads. */
  motion: string;
  /** Any further motion lines, joined. */
  detail: string;
  groups: Record<IgaVote, string[]>;
}

export interface IgaRollCallLine {
  chamber: Chamber;
  rollNum: number;
  session: string;
  motion: string;
  name: string;
  vote: IgaVote;
}

export function parseIgaRollCallUrl(url: string): { session: string; rollNum: number; chamber: Chamber } | null {
  const m = ROLL_PDF.exec(url.trim());
  if (!m) return null;
  return { session: m[1].toLowerCase(), rollNum: Number(m[2]), chamber: m[3].toUpperCase() === 'H' ? 'House' : 'Senate' };
}

export function isIgaRollCallUrl(url: string): boolean {
  return parseIgaRollCallUrl(url) !== null;
}

// ── PDF layout → roll call ────────────────────────────────────────────────────────────────────────

/** Runs closer than this are one word printed in two sizes (the small-caps "Y" + "EA"). */
const JOIN_GAP = 1.5;
/** Runs farther apart than this sit in different columns. */
const COLUMN_GAP = 20;

interface Cell { x: number; text: string }

/** The bottom margin: the form's version footer ("v. 1.2") prints here, never a name. */
const FOOTER_Y = 30;

/** Group runs into printed lines (same page and baseline), then into cells split at column gaps. */
function layoutLines(items: PdfTextItem[]): Cell[][] {
  const rows = new Map<string, PdfTextItem[]>();
  for (const it of items) {
    if (it.y < FOOTER_Y) continue;
    const k = `${it.page}:${Math.round(it.y)}`;
    (rows.get(k) ?? rows.set(k, []).get(k)!).push(it);
  }
  const keys = [...rows.keys()].sort((a, b) => {
    const [pa, ya] = a.split(':').map(Number), [pb, yb] = b.split(':').map(Number);
    return pa - pb || yb - ya;
  });
  return keys.map((k) => {
    const runs = rows.get(k)!.sort((a, b) => a.x - b.x);
    const cells: Cell[] = [];
    let end = -Infinity;
    for (const r of runs) {
      const gap = r.x - end;
      const last = cells[cells.length - 1];
      if (!last || gap > COLUMN_GAP) cells.push({ x: r.x, text: r.str.trim() });
      else last.text += (gap < JOIN_GAP ? '' : ' ') + r.str.trim();
      end = r.x + r.w;
    }
    return cells;
  });
}

const HEADING = /^(YEA|NAY|EXCUSED|NOTVOTING)-(\d+)$/;
const HEADING_VOTE: Record<string, IgaVote> = { YEA: 'Yea', NAY: 'Nay', EXCUSED: 'Excused', NOTVOTING: 'Not Voting' };
const TALLY = /^(Yea|Nay|Excused|Not Voting)\s+(\d+)$/;

/** Read a roll-call PDF's positioned text. Null when it is not a roll call or any count disagrees. */
export function readIgaRollCall(items: PdfTextItem[], session: string): IgaRollCall | null {
  const lines = layoutLines(items);
  let chamber: Chamber | null = null;
  let rollNum = 0, result = '';
  const motion: string[] = [];
  const tally: Partial<Record<IgaVote, number>> = {};
  const heads: Partial<Record<IgaVote, number>> = {};
  const groups: Record<IgaVote, string[]> = { Yea: [], Nay: [], Excused: [], 'Not Voting': [] };
  let phase: 'top' | 'motion' | 'names' = 'top';
  let current: IgaVote | null = null;

  for (const cells of lines) {
    const whole = cells.map((c) => c.text).join(' ');
    if (phase === 'top') {
      if (!chamber && /^Indiana House of Representatives$/.test(whole)) chamber = 'House';
      else if (!chamber && /^Senate$/.test(whole)) chamber = 'Senate';
      const rc = /^Roll Call (\d+):\s*(.*)$/.exec(whole);
      if (rc) { rollNum = Number(rc[1]); result = rc[2].trim(); phase = 'motion'; }
      continue;
    }
    if (phase === 'motion') {
      if (/^Presiding:/.test(whole)) { phase = 'names'; continue; }
      // The tally box sits in the right-hand cells of the motion lines.
      const left: string[] = [];
      for (let i = 0; i < cells.length; i++) {
        const t = TALLY.exec(`${cells[i].text} ${cells[i + 1]?.text ?? ''}`.trim());
        if (t && /^\d+$/.test(cells[i + 1]?.text ?? '')) { tally[t[1] as IgaVote] = Number(t[2]); i++; continue; }
        const t1 = TALLY.exec(cells[i].text);
        if (t1) { tally[t1[1] as IgaVote] = Number(t1[2]); continue; }
        left.push(cells[i].text);
      }
      if (left.length) motion.push(left.join(' '));
      continue;
    }
    const h = HEADING.exec(whole.replace(/\s+/g, ''));
    if (h) { current = HEADING_VOTE[h[1]]; heads[current] = Number(h[2]); continue; }
    if (!current) continue;
    for (const c of cells) groups[current].push(c.text);
  }

  if (!chamber || !rollNum || !motion.length) return null;
  for (const v of IGA_VOTES) {
    const n = heads[v] ?? 0;
    if (groups[v].length !== n) return null;
    if (tally[v] !== undefined && tally[v] !== n) return null;
  }
  if (IGA_VOTES.some((v) => tally[v] === undefined)) return null;
  return { chamber, rollNum, session, result, motion: motion[0], detail: motion.slice(1).join(' '), groups };
}

// ── render ↔ parse ────────────────────────────────────────────────────────────────────────────────

const strip = (s: string): string => s.replace(/[.\s]+$/, '');

/** The fixed text the adapter hands the verifier. Party-free: the PDF prints none. */
export function renderIgaRollCall(r: IgaRollCall): string {
  const head = `Indiana ${r.chamber} roll call ${r.rollNum} (${r.session}): ${strip(r.result) || 'Roll call'}.`;
  const mot = `Motion: ${r.motion.trim()}` + (r.detail.trim() ? `\nDetail: ${r.detail.trim()}` : '');
  const counts = IGA_VOTES.map((v) => `${v} ${r.groups[v].length}`).join('; ') + '.';
  const lists = IGA_VOTES.map((v) => `${v} (${r.groups[v].length}): ${r.groups[v].join('; ')}${r.groups[v].length ? '.' : ''}`.trim()).join('\n');
  return [head, mot, counts, lists].join('\n');
}

const RENDER_HEAD = /^Indiana (House|Senate) roll call (\d+) \(([0-9a-z]+)\): .*$/m;
const RENDER_GROUP = /^(Yea|Nay|Excused|Not Voting) \((\d+)\):(.*)$/gm;

/** Read back a render. Null when the text is not one. */
export function parseIgaRollCallRender(text: string): Omit<IgaRollCall, 'result' | 'detail'> | null {
  const h = RENDER_HEAD.exec(text);
  if (!h) return null;
  const motion = /^Motion: (.*)$/m.exec(text)?.[1]?.trim();
  if (!motion) return null;
  const groups: Record<IgaVote, string[]> = { Yea: [], Nay: [], Excused: [], 'Not Voting': [] };
  for (const m of text.matchAll(RENDER_GROUP)) {
    const names = m[3].trim().replace(/\.$/, '');
    groups[m[1] as IgaVote] = names ? names.split('; ').map((s) => s.trim()) : [];
    if (groups[m[1] as IgaVote].length !== Number(m[2])) return null;
  }
  return { chamber: h[1] as Chamber, rollNum: Number(h[2]), session: h[3], motion, groups };
}

// ── the canonical line ────────────────────────────────────────────────────────────────────────────

const LINE = new RegExp(
  `^Indiana (House|Senate) roll call (\\d+) \\(([0-9a-z]+)\\), (.+): ([^:]+?) voted (${IGA_VOTES.join('|')})\\.$`,
);

export function formatIgaRollCallLine(l: IgaRollCallLine): string {
  return `Indiana ${l.chamber} roll call ${l.rollNum} (${l.session}), ${l.motion}: ${l.name} voted ${l.vote}.`;
}

export function parseIgaRollCallLine(text: string): IgaRollCallLine | null {
  const m = LINE.exec(text.trim());
  if (!m) return null;
  return { chamber: m[1] as Chamber, rollNum: Number(m[2]), session: m[3], motion: m[4].trim(), name: m[5].trim(), vote: m[6] as IgaVote };
}

/** "Smith, H" → [smith, h]; "Walker K" → [walker, k]; "Ford J.D." → [ford, jd]; "Dant Chesser" → [dant chesser, '']. */
function splitPrinted(printed: string): [string, string] {
  const p = normalizeText(printed);
  const comma = /^(.+?),\s*(.+)$/.exec(p);
  if (comma) return [comma[1].trim(), comma[2].replace(/\./g, '').trim()];
  const initial = /^(.+?)\s+((?:[a-z]\.?){1,2})$/.exec(p);
  if (initial) return [initial[1].trim(), initial[2].replace(/\./g, '')];
  return [p, ''];
}

/** Does the name the roll prints belong to this politician? */
export function printedNameFits(printed: string, lastName: string, fullName?: string): boolean {
  if (/^mr\.? speaker$|^madam speaker$/i.test(printed.trim())) return false;
  const [sur, given] = splitPrinted(printed);
  const last = normalizeText(lastName);
  const full = normalizeText(fullName ?? '').replace(/,/g, ' ').replace(/\s+(jr|sr|ii|iii|iv|v)\.?$/, '').trim();
  const compound = sur.includes(' ') && (full === sur || full.endsWith(` ${sur}`));
  if (sur !== last && !compound) return false;
  if (given) {
    // "J.D. Ford" is printed "Ford J.D.": compare initials without their dots.
    const first = (full.split(' ')[0] ?? '').replace(/\./g, '');
    if (!first || !(first === given || (given.length === 1 && first.startsWith(given)))) return false;
  }
  return true;
}

/**
 * Check a canonical line against the render fetched for `url`. `verified` (offset 0) when every field
 * matches; `name_not_present` when the record holds the vote for a name that is not this politician's;
 * otherwise `snippet_not_found`.
 */
export function verifyIgaRollCallLine(line: string, url: string, text: string, lastName: string, fullName?: string): SnippetVerdict {
  const u = parseIgaRollCallUrl(url);
  const l = parseIgaRollCallLine(line);
  const r = parseIgaRollCallRender(text);
  if (!u || !l || !r) return { verdict: 'snippet_not_found' };
  if (u.chamber !== l.chamber || u.rollNum !== l.rollNum || u.session !== l.session) return { verdict: 'snippet_not_found' };
  if (r.chamber !== l.chamber || r.rollNum !== l.rollNum || r.session !== l.session) return { verdict: 'snippet_not_found' };
  if (normalizeText(r.motion) !== normalizeText(l.motion)) return { verdict: 'snippet_not_found' };
  if (!r.groups[l.vote].some((n) => normalizeText(n) === normalizeText(l.name))) return { verdict: 'snippet_not_found' };
  if (!printedNameFits(l.name, lastName, fullName)) return { verdict: 'name_not_present' };
  return { verdict: 'verified', matchOffset: 0 };
}

/** Every canonical line the render holds for this politician (normally one; none when the name is absent or shared). */
export function igaRollCallLinesFor(url: string, text: string, lastName: string, fullName?: string): string[] {
  const r = parseIgaRollCallRender(text);
  const u = parseIgaRollCallUrl(url);
  if (!r || !u) return [];
  const out: string[] = [];
  for (const vote of IGA_VOTES) {
    for (const name of r.groups[vote]) {
      if (printedNameFits(name, lastName, fullName)) out.push(formatIgaRollCallLine({ chamber: r.chamber, rollNum: r.rollNum, session: r.session, motion: r.motion, name, vote }));
    }
  }
  return out;
}
