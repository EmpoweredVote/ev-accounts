/**
 * actionAgendaEvidence — the clerk's-action-agenda lane of the research verifier.
 *
 * A county commission vote cannot pass the snippet-plus-name test. A clerk's action agenda names
 * each member exactly ONCE, in the attendance block at the top of the document, and then records
 * every item as a bare tally — `VOTE: 9-0.` — naming only the exceptions. The member's vote is
 * established by the document's STRUCTURE, not by anything sitting near the item.
 *
 * Measured on the Broward County Commission action agenda for 2022-10-25 (Ordinance No. 2022-41,
 * the living wage): the five sitting members who voted for it are 630, 3,579, 14,630, 14,772 and
 * 16,207 characters from the item. NONE is inside the 500-character window, so a real, enacted,
 * unanimous ordinance could not be cited for anyone. Every county that publishes action agendas
 * rather than narrative minutes has the same shape.
 *
 * So an action-agenda evidence row carries ONE canonical line:
 *
 *   Action agenda 2022-10-25, Ordinance No. 2022-41: Lamar P. Fisher was recorded Present and the vote was 7-0.
 *
 * The verifier fetches the document again and checks the line field by field: the date against the
 * URL, the name against the attendance block, the anchor against the item, and the tally against
 * that item's own VOTE clause. The checked line is what a voter reads.
 *
 * 🔑🔑 THE SAFETY INVARIANT, and the reason this lane is allowed to attribute a vote at all:
 * **everyone listed Present, minus those the item excepts, must equal the Yea count.** The
 * attendance block is parsed heuristically — a roster is a run of title-led names with no reliable
 * terminator once the page is normalized — so the parser is not trusted on its own. If it reads the
 * roster wrong in either direction the arithmetic stops reconciling and the row is REFUSED. A
 * misparse can therefore cost a true row; it can never invent a voter.
 *
 * ⚠ WHAT THIS LANE DELIBERATELY REFUSES:
 *   · a SPLIT vote — `VOTE: 8-1` says one member dissented but not, for the other eight, anything
 *     the tally alone can attribute. Only the NAMED dissenter is evidenced, and naming them is the
 *     ordinary proximity test's job, not this one's.
 *   · a member the item excepts ("was not present during the vote", "abstained from voting").
 *   · a member in the Absent block.
 *   · an item whose own VOTE clause cannot be found before the next numbered motion.
 */
import { normalizeText, lastNameOf, type SnippetVerdict } from './researchVerifier.js';

/** Legistar publishes the action agenda as a meeting's `EventMinutesFile`. The `_M_` segment marks
 *  it as the minutes document and `action_agenda` as this particular format; the plain `_A_`
 *  meeting agenda is published before the meeting and records no votes at all. */
const ACTION_AGENDA_URL =
  /^https?:\/\/[a-z0-9-]+\.legistar1\.com\/[a-z0-9-]+\/meetings\/(\d{4})\/(\d{1,2})\/[^/]*_m_[^/]*action_agenda\.pdf$/;

const LINE =
  /^Action agenda (\d{4})-(\d{2})-(\d{2}), (.+?): (.+?) was recorded Present and the vote was (\d{1,2})-(\d{1,2})\.$/;

/** The titles a clerk prints before a member's name. `vice-mayor` precedes `mayor` so the longer
 *  form wins the alternation and one entry is never counted twice. */
const TITLES = [
  'vice-mayor', 'vice mayor', 'vice-chair', 'vice chair', 'mayor', 'commissioner',
  'councilmember', 'council member', 'councilman', 'councilwoman', 'councilor',
  'alderman', 'alderwoman', 'alderperson', 'supervisor', 'trustee', 'selectman',
  'chairman', 'chairwoman', 'chair',
];
const TITLE_RUN = new RegExp(`\\b(?:${TITLES.join('|')})\\b`, 'g');

/** The ways an action agenda excuses a member from an otherwise unanimous tally. */
const EXCEPTION = new RegExp(
  `\\b(?:${TITLES.join('|')})\\s+([a-z][a-z.'-]*(?:\\s+[a-z][a-z.'-]*){0,3}?)\\s+`
  + '(?:was not present|were not present|was absent|abstained|did not vote|voted no|voted nay|recused)',
  'g',
);

/** A numbered motion starts the NEXT item; an item's own VOTE clause must come before it. */
const NEXT_ITEM = /\b\d{1,3}[a-z]?\.\s+motion\b/;

/** Longest run of a roster entry — a title plus up to four name tokens. Used to decide where the
 *  title-led run that forms the attendance block stops. */
const MAX_ROSTER_ENTRY_CHARS = 45;
/** How far past an item's anchor its own VOTE clause may sit. */
const MAX_ITEM_CHARS = 2500;
/** How much text after the tally can carry the exception sentences. */
const MAX_EXCEPTION_CHARS = 240;

export interface ActionAgendaLine {
  date: string;
  anchor: string;
  name: string;
  yeas: number;
  nays: number;
}

export function isActionAgendaUrl(url: string): boolean {
  return ACTION_AGENDA_URL.test(url.trim().toLowerCase());
}

export function formatActionAgendaLine(l: ActionAgendaLine): string {
  return `Action agenda ${l.date}, ${l.anchor}: ${l.name} was recorded Present and the vote was ${l.yeas}-${l.nays}.`;
}

export function parseActionAgendaLine(text: string): ActionAgendaLine | null {
  const m = LINE.exec(text.trim());
  if (!m) return null;
  return {
    date: `${m[1]}-${m[2]}-${m[3]}`,
    anchor: m[4].trim(),
    name: m[5].trim(),
    yeas: Number(m[6]),
    nays: Number(m[7]),
  };
}

/**
 * The attendance block: where it sits in the normalized page, and how many members it names.
 *
 * The roster is the run of title-led entries that begins after `present:`. Once the page is
 * normalized there are no line breaks to end it on, so the run ends at `absent:` where the clerk
 * prints one, and otherwise at the first gap too long to be a name. Callers must treat `count` as
 * untrusted and reconcile it against the tally — see the safety invariant above.
 */
function titleIndices(page: string, from: number, to: number): number[] {
  const re = new RegExp(TITLE_RUN.source, 'g');
  re.lastIndex = from;
  const out: number[] = [];
  for (let m = re.exec(page); m && m.index < to; m = re.exec(page)) out.push(m.index);
  return out;
}

/** Layout A — the label TRAILS its list: `… Mayor Michael Udine Present:`. */
function runEndingAt(page: string, end: number): { region: string; count: number } | null {
  const idx = titleIndices(page, 0, end);
  if (idx.length === 0) return null;
  // Nothing abuts the label, so the list is not in front of it.
  if (end - idx[idx.length - 1] > MAX_ROSTER_ENTRY_CHARS) return null;
  let first = idx.length - 1;
  while (first > 0 && idx[first] - idx[first - 1] <= MAX_ROSTER_ENTRY_CHARS) first -= 1;
  return { region: page.slice(idx[first], end), count: idx.length - first };
}

/** Layout B — the label LEADS its list: `Present: Mayor Michael Udine …`. */
function runStartingAt(page: string, start: number, hardEnd: number): { region: string; count: number } | null {
  const starts: number[] = [];
  for (const i of titleIndices(page, start, hardEnd)) {
    const previous = starts.length ? starts[starts.length - 1] : start;
    if (i - previous > MAX_ROSTER_ENTRY_CHARS) break;
    starts.push(i);
  }
  if (starts.length === 0) return null;
  const end = Math.min(hardEnd, starts[starts.length - 1] + MAX_ROSTER_ENTRY_CHARS);
  return { region: page.slice(start, end), count: starts.length };
}

function readRoster(page: string): { region: string; count: number } | null {
  const marker = page.indexOf('present:');
  if (marker === -1) return null;

  // 🔴 Which side of the label the names sit on depends on how the PDF's text runs were walked.
  // `pdftotext -layout` prints `Present: <names>`; the pipeline's own extractPdfText emits the
  // two-column attendance table as `<names> Present: <names> Absent:`. Prefer the run that ABUTS
  // the label — in the trailing layout the absentees sit after it and must not become the roster.
  const trailing = runEndingAt(page, marker);
  if (trailing) return trailing;

  const start = marker + 'present:'.length;
  const absent = page.indexOf('absent:', start);
  return runStartingAt(page, start, absent === -1 ? page.length : absent);
}

/** The sentences the clerk attaches to a tally to excuse members from it. */
function exceptionsAfter(page: string, from: number): string {
  let text = page.slice(from, from + MAX_EXCEPTION_CHARS);
  const next = NEXT_ITEM.exec(text);
  if (next) text = text.slice(0, next.index);
  return text;
}

export function verifyActionAgendaLine(
  snippet: string,
  url: string,
  pageText: string,
  lastName: string,
  _fullName: string,
): SnippetVerdict {
  const line = parseActionAgendaLine(snippet);
  if (!line) return { verdict: 'snippet_not_found' };

  const u = ACTION_AGENDA_URL.exec(url.trim().toLowerCase());
  if (!u) return { verdict: 'snippet_not_found' };
  // The meeting's own date is in its URL, so a line cannot be moved to another meeting's document.
  // ⚠ Legistar does NOT zero-pad the month (`/2024/9/`), so compare numerically, not as text.
  if (Number(u[1]) !== Number(line.date.slice(0, 4))
      || Number(u[2]) !== Number(line.date.slice(5, 7))) {
    return { verdict: 'snippet_not_found' };
  }

  // Identity: the name the clerk printed must be this politician's. Who the surname belongs to was
  // settled when the cohort was seated; this lane re-checks the record, not the identity.
  if (lastNameOf(normalizeText(line.name)) !== normalizeText(lastName)) {
    return { verdict: 'name_not_present' };
  }

  const page = normalizeText(pageText);
  const roster = readRoster(page);
  if (!roster) return { verdict: 'name_not_present' };

  const printed = normalizeText(line.name);
  const surname = normalizeText(lastName);
  if (!roster.region.includes(printed)) return { verdict: 'name_not_present' };

  const anchorIdx = page.indexOf(normalizeText(line.anchor));
  if (anchorIdx === -1) return { verdict: 'snippet_not_found' };

  const scope = page.slice(anchorIdx, anchorIdx + MAX_ITEM_CHARS);
  const tally = /vote:\s*(\d{1,2})\s*-\s*(\d{1,2})/.exec(scope);
  if (!tally) return { verdict: 'snippet_not_found' };
  // The VOTE clause must belong to THIS item, not to the next one down the page.
  const boundary = NEXT_ITEM.exec(scope.slice(0, tally.index));
  if (boundary) return { verdict: 'snippet_not_found' };

  const yeas = Number(tally[1]);
  const nays = Number(tally[2]);
  if (yeas !== line.yeas || nays !== line.nays) return { verdict: 'snippet_not_found' };
  // A split tally attributes nothing to the majority.
  if (nays !== 0 || yeas < 2) return { verdict: 'snippet_not_found' };

  const exceptions = exceptionsAfter(page, anchorIdx + tally.index + tally[0].length);
  if (exceptions.includes(surname)) return { verdict: 'name_not_present' };

  // Count only exceptions naming someone the roster lists: a member already in the Absent block is
  // routinely repeated at each item and must not be subtracted twice.
  let excepted = 0;
  EXCEPTION.lastIndex = 0;
  for (let m = EXCEPTION.exec(exceptions); m; m = EXCEPTION.exec(exceptions)) {
    const tokens = m[1].trim().split(' ');
    const excusedSurname = tokens[tokens.length - 1];
    if (roster.region.includes(excusedSurname)) excepted += 1;
  }

  if (roster.count - excepted !== yeas) return { verdict: 'snippet_not_found' };

  return { verdict: 'verified', matchOffset: anchorIdx };
}
