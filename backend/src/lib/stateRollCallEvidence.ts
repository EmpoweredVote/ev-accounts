/**
 * stateRollCallEvidence — the legislature's-own-roll-call-page lane of the research verifier.
 *
 * Why (gun-policy Stage 5, 2026-11-15): a state run can read its bills, sponsors and roll calls from Open
 * States data instead of LegiScan (scripts/stage5/openstates/). Open States hands out its own ids, so such a
 * roll call has no legiscan.com page and the LegiScan lane cannot cite it. What Open States does carry is the
 * address of the legislature's own roll-call page. This lane cites that page and reads the vote from it:
 * Open States is only the index that says where to look.
 *
 * A roll-call page lists each member under a heading, as a surname and initials ("Snider, C.", "Maloy, A.
 * Cory"). The joined page text runs the names together ("Maloy, A. Cory Mauga, V."), so no snippet can tie
 * a name to a vote, and no rule can tell where one name ends. The verifier's fetch
 * (adapters/stateRollCallAdapter.ts) therefore reads the page's own markup, one table cell per member, and
 * RENDERS it in one fixed form that prints no party:
 *
 *   Utah House roll call 100 (2025GS), 2025-01-30.
 *   Question: HB 237 - 3rd Reading Final Passage
 *   Yea 71; Nay 0; Absent or not voting 4.
 *   Yea (71): Abbott, N.; Acton, C.K.; …
 *   Nay (0):
 *   Absent or not voting (4): Bolinder, B.; …
 *
 * A vote seat carries ONE canonical line built from that render:
 *
 *   Utah House roll call 100 (2025GS), HB 237 - 3rd Reading Final Passage (2025-01-30): Snider, C. voted Yea.
 *
 * The verifier fetches the render again and checks the line field by field: state, chamber, roll-call number
 * and session (also against the URL), the bill and question, the date, and the label listed under that vote.
 * The label must fit the politician: their surname, and a given name or initial the page prints. A label is
 * refused when a second label of the same roll call also fits them.
 *
 * A page is refused (null) unless every group holds exactly the count its heading prints and those counts
 * equal the tally the page prints twice. A misread page fails closed.
 *
 * Ohio (2026-11-16) needs three documents for one vote, and its address names the vote after a #:
 * www.legislature.ohio.gov/legislation/135/hb327/votes#2024-06-12-House-85-6 (session day, chamber, tally).
 * The bill's Votes page lists every roll call of the bill and each member's full name, but no motion; the
 * action list (search-prod.lis.state.oh.us/api/v2/general_assembly_<N>/legislation/<bill>/actions/) holds
 * the motion, the session day and member ids; the Assembly's member list maps an id to a name and chamber. A
 * vote is read only when exactly one page row and one action-list vote fit the day, chamber and tally, the
 * results agree, the vote is not a committee report or a vote on a motion, and every id maps to the name the page prints, in that
 * chamber. Anything else gives no line. Ohio's render and line:
 *
 *   Ohio House vote of 2024-06-12 (135th General Assembly), HB 327, 85-6.
 *   Question: Passed
 *   Yea (85): Cindy Abrams; …
 *   Ohio House vote of 2024-06-12 (135th General Assembly), HB 327 - Passed, 85-6: Cindy Abrams voted Yea.
 *
 * A member who did not vote is on no list in Ohio, so the render has no absent group and gives no finding.
 *
 * South Dakota (2026-11-17) cites the vote's own page, sdlegislature.gov/Session/Vote/<id>, which is a script shell
 * with no vote in it, and reads one document, the vote's data at sdlegislature.gov/api/Votes/<id> (runner's standing
 * answer: cite a page a person can open, verify from the data). A vote is read only when it is a chamber's floor vote
 * on a question that is a vote on the bill (sdQuestionIsOnTheBill), in a session we know, and every count equals the
 * members listed. A consent calendar is one vote on several bills, and its render and line name them all. A member who
 * did not vote is listed as the record lists them (Excused, Absent, Not voting, Present, Suspended):
 *
 *   South Dakota House vote 84688 (2026), SB 179, 2026-03-05.
 *   Question: Do Pass
 *   Yea 42; Nay 25; Excused 3; Absent 0; Not voting 0; Present 0; Suspended 0.
 *   Yea (42): Bobbi Andera; …
 *   South Dakota House vote 84688 (2026), SB 179 - Do Pass (2026-03-05): Will Mortenson voted Yea.
 *
 * One entry of FORMATS per legislature page layout. Adding a state is adding an entry and its fixture; nothing
 * here knows a topic.
 */
import { parseHTML } from 'linkedom';
import { normalizeText, type SnippetVerdict } from './researchVerifier.js';
import { getNameVariants } from './legiscan/helpers.js';

export const STATE_VOTES = ['Yea', 'Nay', 'Absent or not voting'] as const;
export type StateVote = (typeof STATE_VOTES)[number];
type Chamber = 'House' | 'Senate';

export interface StateRollCallRef { state: string; stateName: string; chamber: Chamber; session: string; rollNum: number }

export interface StateRollCall extends StateRollCallRef {
  /** "HB 237" */
  bill: string;
  /** "3rd Reading Final Passage" */
  question: string;
  /** ISO day */
  date: string;
  groups: Record<StateVote, string[]>;
}

export interface StateRollCallLine extends StateRollCallRef {
  bill: string;
  question: string;
  date: string;
  name: string;
  vote: StateVote;
}

interface Format {
  state: string;
  stateName: string;
  /** The wait the site's robots.txt asks of a crawler between two requests (its Crawl-delay), in ms. */
  minGapMs: number;
  ref(url: string): Omit<StateRollCallRef, 'state' | 'stateName'> | null;
  read(html: string, ref: StateRollCallRef): StateRollCall | null;
}

const squash = (s: string): string => s.replace(/\s+/g, ' ').trim();

/**
 * A printed label as [surname, given part]: "Snider, C." and "Maloy, A. Cory" by the comma; "Strong M.A." (Utah
 * prints a few members with no comma, 2019) by its closing initials. Null for anything else: a bare word is not
 * a member label.
 */
function splitLabel(printed: string): [string, string] | null {
  const p = squash(printed);
  const comma = /^([^,]+),\s*(\S.*)$/.exec(p);
  if (comma) return [comma[1].trim(), comma[2].trim()];
  const initials = /^(.+?)\s+((?:[A-Z]\.\s?)+)$/.exec(p);
  return initials ? [initials[1].trim(), initials[2].trim()] : null;
}

// ── Utah: le.utah.gov/DynaBill/svotes.jsp?sessionid=2025GS&voteid=100&house=H ─────────────────────────
// The page prints, in order: a bold header ("HB0237 Substitute 1 - - Passed 71 - 0 - 4, 1/30/2025 11:50 AM"),
// one <center> per line of the calendar entry (bill, title, sponsors, committee action, reading, motion, and
// last the tally "Yeas 71 Nays 0 N/V 4"), then three headings ("Yeas - 71", "Nays - 0", "Absent or not
// voting - 4"), each followed by a table with one member per cell.

const UT_URL = /^https:\/\/le\.utah\.gov\/DynaBill\/svotes\.jsp\?sessionid=(\d{4}[A-Za-z0-9]{1,3})&voteid=(\d+)&house=([HS])$/;
const UT_HEADER = /^([HS][A-Z]{0,3})0*(\d+)\b.*?(\d+)\s*-\s*(\d+)\s*-\s*(\d+)\s*,\s*(\d{1,2})\/(\d{1,2})\/(\d{4})\b/;
const UT_TALLY = /^(?:Yeas|Ayes)\s+(\d+)\s+Nays\s+(\d+)\s+(?:N\/V|Abs)\s+(\d+)\b/i;
const UT_HEADING = /^(Yeas|Nays|Absent or not voting)\s*-\s*(\d+)$/i;
const UT_QUESTION_START = /\bReading\b|\bCalendar\b|\bConcur|\bConference\b|\bVeto\b|\bOverride\b/i;
const UT_GROUP: Record<string, StateVote> = { yeas: 'Yea', nays: 'Nay', 'absent or not voting': 'Absent or not voting' };

function readUtah(html: string, ref: StateRollCallRef): StateRollCall | null {
  const { document } = parseHTML(html);
  const header = squash(document.querySelector('b')?.textContent ?? '');
  const h = UT_HEADER.exec(header);
  if (!h) return null;
  const bill = `${h[1]} ${Number(h[2])}`;
  const tally = [Number(h[3]), Number(h[4]), Number(h[5])];
  const date = `${h[8]}-${h[6].padStart(2, '0')}-${h[7].padStart(2, '0')}`;

  // The calendar lines: leaf <center> elements up to and including the tally line.
  const lines: string[] = [];
  let tallyLine: RegExpExecArray | null = null;
  for (const c of document.querySelectorAll('center')) {
    if (c.querySelector('center, table, font')) continue;
    const t = squash(c.textContent ?? '');
    tallyLine = UT_TALLY.exec(t);
    if (tallyLine) break;
    if (t) lines.push(t);
  }
  if (!tallyLine || tallyLine.slice(1, 4).map(Number).join() !== tally.join()) return null;
  // The first line repeats the bill, behind the substitute number when there is one ("1HB 237").
  const first = /^\d*([HS][A-Z]{0,3})\s*0*(\d+)$/.exec(lines[0] ?? '');
  if (!first || `${first[1]} ${Number(first[2])}` !== bill) return null;
  let at = lines.findIndex((l, i) => i >= 2 && UT_QUESTION_START.test(l));
  if (at < 0) at = lines.length - 1;
  const question = lines.slice(at).join(' ');
  if (at < 2 || !question) return null;

  // Each heading, then the cells of the first table after it.
  const groups: Record<StateVote, string[]> = { Yea: [], Nay: [], 'Absent or not voting': [] };
  const seen = new Set<StateVote>();
  let open: { vote: StateVote; want: number } | null = null;
  const close = (): boolean => !open || groups[open.vote].length === open.want;
  for (const el of document.querySelectorAll('font, td')) {
    if (el.tagName === 'FONT') {
      const m = UT_HEADING.exec(squash(el.textContent ?? ''));
      if (!m || el.closest('td')) continue;
      if (!close()) return null;
      const vote = UT_GROUP[m[1].toLowerCase()];
      if (seen.has(vote)) return null;
      seen.add(vote);
      open = { vote, want: Number(m[2]) };
      continue;
    }
    const label = squash(el.textContent ?? '');
    if (!label) continue;
    if (!open) return null; // a member cell before any heading
    // A member link names the chamber it belongs to: it must be the chamber the address names.
    const house = /leglookup\.asp\?house=([HS])\b/.exec(el.querySelector('a')?.getAttribute('href') ?? '')?.[1];
    if (house && (house === 'H' ? 'House' : 'Senate') !== ref.chamber) return null;
    if (!splitLabel(label) || /;/.test(label)) return null; // every label is a surname and a given part
    groups[open.vote].push(label);
  }
  if (!close() || seen.size !== STATE_VOTES.length) return null;
  if (STATE_VOTES.map((v) => groups[v].length).join() !== tally.join()) return null;
  return { ...ref, bill, question, date, groups };
}

const FORMATS: Format[] = [
  {
    state: 'UT',
    stateName: 'Utah',
    // le.utah.gov/robots.txt: "Crawl-delay: 10" for every agent (read 2026-11-15). Faster than that, the site
    // answers 429 Too Many Requests, and a page that cannot be read verifies no vote.
    minGapMs: 10_000,
    ref(url) {
      const m = UT_URL.exec(url);
      return m ? { session: m[1], rollNum: Number(m[2]), chamber: m[3] === 'H' ? 'House' : 'Senate' } : null;
    },
    read: readUtah,
  },
];

// ── Ohio: one page per BILL, checked against the legislature's own data ──────────────────────────────
// www.legislature.ohio.gov/legislation/<GA>/<bill>/votes lists every recorded vote of the bill (committee and
// floor), newest first: the session day, the chamber, the result ("Passed", "Failed", "Favorable Passage"), the
// counts ("Yeas: 85", "Nays: 6"), and under a Breakdown each member by full name with a party letter. It does not
// print the motion: a passage, a concurrence and a veto override all read "Passed". The bill's action list at
// search-prod.lis.state.oh.us (/api/v2/general_assembly_<GA>/legislation/<bill>/actions/) holds the same votes
// with the motion, the session day and member ids ("rep_abrams_cindy_1"); the General Assembly's member list there
// (/legislators/) names each id. Neither lists an absent member: a member who did not vote is on no list, so
// absence gives no line (runner, 2026-11-16).
//
// One address holds many votes, so the citation names the vote in its fragment: the session day, the chamber and
// the tally (runner, 2026-11-16: cite the readable page, verify from it AND the data):
//   https://www.legislature.ohio.gov/legislation/135/hb327/votes#2024-06-12-House-85-6
// The vote is read only when the page and the data each hold exactly one vote of that day, chamber and tally, the
// data says it is not a committee report, both give the same result, and every member id under Yeas and under Nays
// is, by the member list, the name the page prints there, of the chamber that voted. Anything else is null.

export type OhioVote = 'Yea' | 'Nay';
const OH_VOTES: readonly OhioVote[] = ['Yea', 'Nay'];
export interface OhioVoteRef { state: 'OH'; stateName: 'Ohio'; chamber: Chamber; session: string; billCode: string; date: string; yea: number; nay: number }
export interface OhioVoteRecord extends Omit<OhioVoteRef, 'billCode'> { bill: string; question: string; groups: Record<OhioVote, string[]> }
export interface OhioVoteLine extends Omit<OhioVoteRecord, 'groups'> { name: string; vote: OhioVote }

const OH_URL = /^https:\/\/www\.legislature\.ohio\.gov\/legislation\/(1[3-9]\d)\/((?:hb|sb|hjr|sjr|hcr|scr|hr|sr)[1-9]\d{0,3})\/votes#(\d{4}-\d{2}-\d{2})-(House|Senate)-(\d{1,3})-(\d{1,3})$/;
const OH_DATA = 'https://search-prod.lis.state.oh.us/api/v2/general_assembly_';
const OH_KIND: Record<string, string> = {
  hb: 'House Bill', sb: 'Senate Bill', hjr: 'House Joint Resolution', sjr: 'Senate Joint Resolution',
  hcr: 'House Concurrent Resolution', scr: 'Senate Concurrent Resolution', hr: 'House Resolution', sr: 'Senate Resolution',
};
/** The site's own wait is not stated (no robots.txt on either host, 2026-11-16); one request a second is ours. */
const OH_GAP_MS = 1_000;
const ordinal = (n: number): string => `${n}${n % 100 >= 11 && n % 100 <= 13 ? 'th' : ['th', 'st', 'nd', 'rd'][n % 10] ?? 'th'}`;
const ohBill = (code: string): string => code.replace(/^([a-z]+)(\d+)$/, (_m, l: string, n: string) => `${l.toUpperCase()} ${n}`);

export function parseOhioVoteUrl(url: string): OhioVoteRef | null {
  const m = OH_URL.exec(url.trim());
  if (!m) return null;
  const [y, mo, d] = m[3].split('-').map(Number);
  const day = new Date(Date.UTC(y, mo - 1, d));
  if (day.getUTCFullYear() !== y || day.getUTCMonth() !== mo - 1 || day.getUTCDate() !== d) return null;
  return { state: 'OH', stateName: 'Ohio', session: m[1], billCode: m[2], date: m[3], chamber: m[4] as Chamber, yea: Number(m[5]), nay: Number(m[6]) };
}

function ohioDocs(r: OhioVoteRef): string[] {
  return [
    `https://www.legislature.ohio.gov/legislation/${r.session}/${r.billCode}/votes`,
    `${OH_DATA}${r.session}/legislation/${r.billCode}/actions/`,
    `${OH_DATA}${r.session}/legislators/`,
  ];
}

interface OhPageRow { date: string; chamber: string; result: string; yea: number; nay: number; groups: Record<OhioVote, string[]> }

/** A printed member: the party letter the page prints after the name is dropped ("Cindy Abrams (R)"). */
const ohName = (printed: string): string => squash(printed).replace(/\s*\([A-Z]{1,3}\)$/, '');

function readOhioPage(html: string, r: OhioVoteRef): OhPageRow[] | null {
  const { document } = parseHTML(html);
  // "House Bill 327 Votes | 135th General Assembly | Ohio Legislature"
  const title = /^(.+?) (\d+) Votes \| (\d+)(?:st|nd|rd|th) General Assembly\b/.exec(squash(document.querySelector('title')?.textContent ?? ''));
  const kind = /^([a-z]+)(\d+)$/.exec(r.billCode);
  if (!title || !kind || title[1] !== OH_KIND[kind[1]] || title[2] !== kind[2] || title[3] !== r.session) return null;
  const table = document.querySelector('table.legislation-votes-table');
  if (!table) return null;
  const out: OhPageRow[] = [];
  for (const tr of table.querySelectorAll('tr')) {
    if (tr.closest('table') !== table) continue; // a breakdown table's own rows
    const th = tr.querySelector('th.date-cell');
    if (!th) continue;
    const dm = /^(\d{1,2})-(\d{1,2})-(\d{4})$/.exec(squash(th.textContent ?? ''));
    const chamber = squash(tr.querySelector('td.chamber-cell')?.textContent ?? '');
    const result = squash(tr.querySelector('td.result-cell')?.textContent ?? '');
    const counts = [...tr.querySelectorAll('span.vote-count-column')].map((x) => squash(x.textContent ?? ''));
    const yc = counts.map((c) => /^Yeas: (\d+)$/.exec(c)).find(Boolean);
    const nc = counts.map((c) => /^Nays: (\d+)$/.exec(c)).find(Boolean);
    if (!dm || !chamber || !result || !yc || !nc || counts.length !== 2) return null; // a row that does not read: refuse the page
    const groups: Record<OhioVote, string[]> = { Yea: [], Nay: [] };
    const seen = new Set<OhioVote>();
    for (const h3 of tr.querySelectorAll('.vote-breakdown h3')) {
      const vote = ({ Yeas: 'Yea', Nays: 'Nay' } as Record<string, OhioVote>)[squash(h3.textContent ?? '')];
      if (!vote || seen.has(vote)) return null;
      seen.add(vote);
      const list = h3.parentElement?.querySelector('table');
      if (!list) return null;
      // One member per cell: plain text through 2024, a link to the member's page for sitting members from 2025.
      for (const td of list.querySelectorAll('td')) {
        const name = ohName(td.textContent ?? '');
        if (name) groups[vote].push(name);
      }
    }
    const row = { date: `${dm[3]}-${dm[1].padStart(2, '0')}-${dm[2].padStart(2, '0')}`, chamber, result, yea: Number(yc[1]), nay: Number(nc[1]), groups };
    // every printed count is the names under it (a group of none may print no heading)
    if (groups.Yea.length !== row.yea || groups.Nay.length !== row.nay) return null;
    out.push(row);
  }
  return out;
}

interface OhAction { chamber?: string; session_day?: string; action_code?: string; action?: string; result?: string; yeas?: unknown; nays?: unknown }
interface OhMember { lpid?: string; displayname?: string; chamber?: string }

const sameNames = (a: string[], b: string[]): boolean => {
  const k = (x: string[]) => x.map((n) => normalizeText(n)).sort().join('\n');
  return a.length === b.length && k(a) === k(b);
};

function readOhio(bodies: string[], r: OhioVoteRef): OhioVoteRecord | null {
  if (bodies.length !== 3) return null;
  const rows = readOhioPage(bodies[0], r);
  let actions: OhAction[];
  let members: OhMember[];
  try { actions = JSON.parse(bodies[1]); members = JSON.parse(bodies[2]); } catch { return null; }
  if (!rows || !Array.isArray(actions) || !Array.isArray(members)) return null;
  const want = (x: { date: string; chamber: string; yea: number; nay: number }) =>
    x.date === r.date && x.chamber === r.chamber && x.yea === r.yea && x.nay === r.nay;
  const pageHits = rows.filter(want);
  const votes = actions.filter((a) => Array.isArray(a.yeas) || Array.isArray(a.nays)).map((a) => {
    const d = /_(\d{4})(\d{2})(\d{2})$/.exec(a.session_day ?? '');
    const yeas = Array.isArray(a.yeas) ? a.yeas : [];
    const nays = Array.isArray(a.nays) ? a.nays : [];
    return { a, yeas, nays, date: d ? `${d[1]}-${d[2]}-${d[3]}` : '', chamber: a.chamber ?? '', yea: yeas.length, nay: nays.length };
  });
  const dataHits = votes.filter(want);
  if (pageHits.length !== 1 || dataHits.length !== 1) return null;
  const [page] = pageHits;
  const [data] = dataHits;
  // A committee report ("crpt_301 Reported - Substitute") is a committee's vote: never read (runner, 2026-11-16).
  // A conference report is the chamber's floor vote (confer_712, confer_713).
  if (/^crpt_/.test(data.a.action_code ?? '')) return null;
  // A vote on a motion ("motion_920 Informally passed": the bill set aside for the day) is not a vote on the
  // bill: never read (runner, 2026-11-16).
  if (/^motion_/.test(data.a.action_code ?? '')) return null;
  if (!data.a.result || squash(data.a.result) !== page.result) return null;
  const question = squash(data.a.action ?? '');
  if (!question || /\n/.test(question)) return null;
  const byId = new Map<string, OhMember>();
  for (const m of members) {
    if (!m || typeof m.lpid !== 'string') return null;
    if (byId.has(m.lpid)) return null;
    byId.set(m.lpid, m);
  }
  const prefix = r.chamber === 'House' ? 'rep_' : 'sen_';
  const names = (ids: unknown[]): string[] | null => {
    const out: string[] = [];
    for (const id of ids) {
      const m = typeof id === 'string' ? byId.get(id) : undefined;
      const name = squash(m?.displayname ?? '');
      if (!m || !name || !(id as string).startsWith(prefix) || (m.chamber && m.chamber !== r.chamber)) return null;
      out.push(name);
    }
    return out;
  };
  const yea = names(data.yeas);
  const nay = names(data.nays);
  if (!yea || !nay || !sameNames(yea, page.groups.Yea) || !sameNames(nay, page.groups.Nay)) return null;
  const all = [...page.groups.Yea, ...page.groups.Nay].map((n) => normalizeText(n));
  if (new Set(all).size !== all.length || all.some((n) => /;/.test(n))) return null; // one name, one vote
  const { billCode: _b, ...ref } = r;
  return { ...ref, bill: ohBill(r.billCode), question, groups: { Yea: page.groups.Yea, Nay: page.groups.Nay } };
}

export function renderOhioVote(v: OhioVoteRecord): string {
  return [
    `Ohio ${v.chamber} vote of ${v.date} (${ordinal(Number(v.session))} General Assembly), ${v.bill}, ${v.yea}-${v.nay}.`,
    `Question: ${v.question}`,
    ...OH_VOTES.map((k) => `${k} (${v.groups[k].length}): ${v.groups[k].join('; ')}`.trim()),
  ].join('\n');
}

const OH_RENDER_HEAD = /^Ohio (House|Senate) vote of (\d{4}-\d{2}-\d{2}) \((\d+)(?:st|nd|rd|th) General Assembly\), ([A-Z]+ \d+), (\d+)-(\d+)\.$/;

function parseOhioRender(text: string, url: string): OhioVoteRecord | null {
  const r = parseOhioVoteUrl(url);
  const rows = text.split('\n');
  const h = OH_RENDER_HEAD.exec(rows[0] ?? '');
  const q = /^Question: (.+)$/.exec(rows[1] ?? '');
  if (!r || !h || !q || rows.length !== 2 + OH_VOTES.length) return null;
  if (h[1] !== r.chamber || h[2] !== r.date || h[3] !== r.session || h[4] !== ohBill(r.billCode) || Number(h[5]) !== r.yea || Number(h[6]) !== r.nay) return null;
  const groups = {} as Record<OhioVote, string[]>;
  for (const [i, v] of OH_VOTES.entries()) {
    const m = new RegExp(`^${v} \\((\\d+)\\):(.*)$`).exec(rows[2 + i]);
    if (!m) return null;
    groups[v] = m[2].split(';').map((x) => x.trim()).filter(Boolean);
    if (groups[v].length !== Number(m[1])) return null;
  }
  if (groups.Yea.length !== r.yea || groups.Nay.length !== r.nay) return null;
  const { billCode: _b, ...ref } = r;
  return { ...ref, bill: h[4], question: q[1], groups };
}

const OH_LINE = /^Ohio (House|Senate) vote of (\d{4}-\d{2}-\d{2}) \((\d+)(?:st|nd|rd|th) General Assembly\), ([A-Z]+ \d+) - (.+), (\d+)-(\d+): (.+?) voted (Yea|Nay)\.$/;

export function formatOhioVoteLine(l: OhioVoteLine): string {
  return `Ohio ${l.chamber} vote of ${l.date} (${ordinal(Number(l.session))} General Assembly), ${l.bill} - ${l.question}, ${l.yea}-${l.nay}: ${l.name} voted ${l.vote}.`;
}

function parseOhioLine(text: string): OhioVoteLine | null {
  const m = OH_LINE.exec(text.trim());
  if (!m) return null;
  return { state: 'OH', stateName: 'Ohio', chamber: m[1] as Chamber, date: m[2], session: m[3], bill: m[4], question: m[5],
    yea: Number(m[6]), nay: Number(m[7]), name: m[8].trim(), vote: m[9] as OhioVote };
}

// ── South Dakota: the vote's own page is a script shell; the vote is read from the legislature's data ─────────
// sdlegislature.gov/Session/Vote/<id> is the page a person opens for one roll call. It is filled in by a script, and
// the HTML holds no vote (read 2026-11-17). The same record is sdlegislature.gov/api/Votes/<id> (JSON): the bill, the
// action it was taken on (StatusText, the day, and the body: "House of Representatives", "Senate", or a committee),
// the counts (Yeas, Nays, Excused, Absent, NotVoting, Present) and each member (FirstName, LastName, UniqueName,
// SessionMemberId) with the vote (Vote1: "Yea", "Nay", "Excused", ...). The citation is the vote's own page; the
// verifier reads the data (runner's standing answer, 2026-11-16: cite a page a person can open, verify from the data).
//
// A vote is read only when it is the floor vote of a chamber (a committee's vote is never read), on a question that
// is a vote on the bill (sdQuestionIsOnTheBill: a motion to table, to defer to the 41st day, to reconsider or to
// place on the calendar is not), the session is one we know, and every group holds exactly the count printed for it.
// A member who did not vote is listed as the record lists them (Excused, Absent, Not voting): never as a Yea or a Nay.

export const SD_VOTES = ['Yea', 'Nay', 'Excused', 'Absent', 'Not voting', 'Present', 'Suspended'] as const;
export type SdVote = (typeof SD_VOTES)[number];
/** Vote1 as the data prints it, and the count field that must equal the members under it. */
const SD_VOTE_OF: Record<string, SdVote> = { Yea: 'Yea', Nay: 'Nay', Excused: 'Excused', Absent: 'Absent', 'Not Voting': 'Not voting', NotVoting: 'Not voting', Present: 'Present', Suspended: 'Suspended' };
/**
 * The count the data prints for each group. A suspended member (2023: one senator, suspended by the Senate, is
 * listed "Suspended" on its votes) has no count of their own: that group is checked by the total instead.
 */
const SD_COUNT: Record<SdVote, string | null> = { Yea: 'Yeas', Nay: 'Nays', Excused: 'Excused', Absent: 'Absent', 'Not voting': 'NotVoting', Present: 'Present', Suspended: null };
/**
 * The legislature's SessionId -> the session's name in Open States (and in our dataset folders). From /api/Sessions,
 * read 2026-11-17. The two 2021 special sessions are told apart by their votes' days: 2021r voted on 2021-11-08 (the
 * First Special Session, 65), 2021i on 2021-11-09 (the Second, 66). A session not listed here gives no vote: add it.
 */
export const SD_SESSIONS: Readonly<Record<number, string>> = {
  27: '2017', 33: '2017s', 32: '2018', 37: '2018s', 36: '2019', 43: '2020', 62: '2020s', 44: '2021', 65: '2021r', 66: '2021i',
  64: '2022', 68: '2023', 69: '2024', 70: '2025', 173: '2025s', 71: '2026',
};
const SD_CHAMBER: Record<string, Chamber> = { 'House of Representatives': 'House', Senate: 'Senate' };
const SD_SIZE: Record<Chamber, number> = { House: 70, Senate: 35 };
const SD_URL = /^https:\/\/sdlegislature\.gov\/Session\/Vote\/([1-9]\d{0,6})$/;
const SD_DATA = 'https://sdlegislature.gov/api/Votes/';
/** sdlegislature.gov's robots.txt states no Crawl-delay (2026-11-17); one request a second is ours. */
const SD_GAP_MS = 1_000;

/**
 * Is a South Dakota action (its StatusText) a vote on the bill? A motion is not (runner, 2026-11-16): to table, to defer
 * to the 41st legislative day (the session has 40), to reconsider ("Reconsidered"), to place a bill on the calendar
 * ("Placed on calendar pursuant to JR 6F-6", the smoke-out), to recall it from committee ("Recalled from committee
 * (Rule 7-7)"), to lay on the table, or to amend. A concurrence, passed or failed, is a vote on the bill. Only the questions listed are read; any other wording gives no line until it is
 * added here, so a new kind of motion can never be read as a vote on the bill.
 */
export function sdQuestionIsOnTheBill(statusText: string): boolean {
  const q = squash(statusText);
  return /^(Do Pass|Do Pass Amended|Passed|Failed|Failed to pass|Do Pass Failed|Adopt Resolution|Resolution adopted|Resolution Failed|Concurred in Resolution|Adopt Resolution as amended|Concurred in Resolution as Amended|Concurred in amendments|Do not concur|Refused to concur|Failed to concur|Failed to concur, appoint Conference Committee|Conference Committee Report adopted|Conference committee report adopted|Veto override|Veto override failed|Veto sustained|Failed to override veto|Override the Governor's veto|Concurred in Governor's specific recommendations|Governor's Specific Recommendations accepted)$/i.test(q);
}

export interface SdVoteRef { state: 'SD'; stateName: 'South Dakota'; voteId: number }
export interface SdVoteRecord extends SdVoteRef {
  chamber: Chamber; session: string; bill: string; question: string; date: string;
  /** "FirstName LastName", the line's label */
  groups: Record<SdVote, string[]>;
  /** the same members by the data's UniqueName ("Greenfield (Lana)"), the label Open States stores */
  unique: Record<SdVote, string[]>;
}
export interface SdVoteLine extends Omit<SdVoteRecord, 'groups' | 'unique'> { name: string; vote: SdVote }

export function parseSouthDakotaVoteUrl(url: string): SdVoteRef | null {
  const m = SD_URL.exec(url.trim());
  return m ? { state: 'SD', stateName: 'South Dakota', voteId: Number(m[1]) } : null;
}

interface SdData {
  VoteId?: unknown; SessionId?: unknown; Bill?: unknown; RollCalls?: unknown;
  actionLog?: { ActionDate?: unknown; FullName?: unknown; StatusText?: unknown } | null;
  [count: string]: unknown;
}
interface SdMember { FirstName?: unknown; LastName?: unknown; UniqueName?: unknown; SessionMemberId?: unknown; Vote1?: unknown }

function readSouthDakota(bodies: string[], r: SdVoteRef): SdVoteRecord | null {
  if (bodies.length !== 1) return null;
  let d: SdData;
  try { d = JSON.parse(bodies[0]); } catch { return null; }
  if (!d || typeof d !== 'object' || d.VoteId !== r.voteId) return null;
  const session = typeof d.SessionId === 'number' ? SD_SESSIONS[d.SessionId] : undefined;
  if (!session) return null;
  const a = d.actionLog;
  const chamber = typeof a?.FullName === 'string' ? SD_CHAMBER[a.FullName] : undefined;
  if (!a || !chamber) return null; // a committee's vote, or an action the reader cannot place
  const question = typeof a.StatusText === 'string' ? squash(a.StatusText) : '';
  if (!question || !sdQuestionIsOnTheBill(question)) return null;
  const day = typeof a.ActionDate === 'string' ? /^(\d{4}-\d{2}-\d{2})T/.exec(a.ActionDate)?.[1] : undefined;
  if (!day) return null;
  // One roll call can carry several bills: the consent calendar is voted as one (2018 HB 1209 and SB 55, vote 25955).
  if (!Array.isArray(d.Bill) || !d.Bill.length) return null;
  // The 2020 consent calendars list each bill twice, under the same BillId: one bill. One number under two ids is refused.
  const billIds = new Map<string, unknown>();
  for (const b of d.Bill as { BillId?: unknown; BillType?: unknown; BillNumber?: unknown }[]) {
    if (typeof b?.BillType !== 'string' || !/^[HS][A-Z]{0,3}$/.test(b.BillType) || typeof b.BillNumber !== 'number' || !Number.isInteger(b.BillNumber)) return null;
    const k = `${b.BillType} ${b.BillNumber}`;
    if (typeof b.BillId !== 'number' || (billIds.has(k) && billIds.get(k) !== b.BillId)) return null;
    billIds.set(k, b.BillId);
  }
  const bills = [...billIds.keys()];
  if (!Array.isArray(d.RollCalls)) return null;
  const groups = Object.fromEntries(SD_VOTES.map((v) => [v, [] as string[]])) as Record<SdVote, string[]>;
  const unique = Object.fromEntries(SD_VOTES.map((v) => [v, [] as string[]])) as Record<SdVote, string[]>;
  const seenId = new Set<number>();
  const seenName = new Set<string>();
  const seenUnique = new Set<string>();
  for (const m of d.RollCalls as SdMember[]) {
    const vote = typeof m?.Vote1 === 'string' ? SD_VOTE_OF[m.Vote1] : undefined;
    const first = typeof m?.FirstName === 'string' ? squash(m.FirstName) : '';
    const last = typeof m?.LastName === 'string' ? squash(m.LastName) : '';
    const uniq = typeof m?.UniqueName === 'string' ? squash(m.UniqueName) : '';
    if (!vote || !first || !last || !uniq || typeof m.SessionMemberId !== 'number') return null;
    const name = `${first} ${last}`;
    if (/;/.test(name) || /;/.test(uniq)) return null;
    // one member, one vote
    if (seenId.has(m.SessionMemberId) || seenName.has(normalizeText(name)) || seenUnique.has(normalizeText(uniq))) return null;
    seenId.add(m.SessionMemberId); seenName.add(normalizeText(name)); seenUnique.add(normalizeText(uniq));
    groups[vote].push(name);
    unique[vote].push(uniq);
  }
  // every printed count is the members under it, and the chamber holds them all
  for (const v of SD_VOTES) {
    const key = SD_COUNT[v];
    if (key === null) continue;
    const n = d[key];
    if ((n ?? 0) !== groups[v].length || (n !== undefined && n !== null && typeof n !== 'number')) return null;
  }
  if (!groups.Yea.length && !groups.Nay.length) return null;
  if (seenId.size > SD_SIZE[chamber]) return null;
  return { ...r, chamber, session, bill: bills.join(', '), question, date: day, groups, unique };
}

const SD_SAID: Record<SdVote, string> = { Yea: 'voted Yea', Nay: 'voted Nay', Excused: 'was excused', Absent: 'was absent', 'Not voting': 'did not vote', Present: 'voted present', Suspended: 'was suspended' };

export function renderSouthDakotaVote(v: SdVoteRecord): string {
  return [
    `South Dakota ${v.chamber} vote ${v.voteId} (${v.session}), ${v.bill}, ${v.date}.`,
    `Question: ${v.question}`,
    SD_VOTES.map((k) => `${k} ${v.groups[k].length}`).join('; ') + '.',
    ...SD_VOTES.map((k) => `${k} (${v.groups[k].length}): ${v.groups[k].join('; ')}`.trim()),
  ].join('\n');
}

const SD_RENDER_HEAD = /^South Dakota (House|Senate) vote (\d+) \((\d{4}[a-z]?)\), ([A-Z]+ \d+(?:, [A-Z]+ \d+)*), (\d{4}-\d{2}-\d{2})\.$/;

function parseSouthDakotaRender(text: string, url: string): Omit<SdVoteRecord, 'unique'> | null {
  const r = parseSouthDakotaVoteUrl(url);
  const rows = text.split('\n');
  const h = SD_RENDER_HEAD.exec(rows[0] ?? '');
  const q = /^Question: (.+)$/.exec(rows[1] ?? '');
  if (!r || !h || !q || rows.length !== 3 + SD_VOTES.length || Number(h[2]) !== r.voteId) return null;
  const groups = {} as Record<SdVote, string[]>;
  for (const [i, v] of SD_VOTES.entries()) {
    const m = new RegExp(`^${v} \\((\\d+)\\):(.*)$`).exec(rows[3 + i]);
    if (!m) return null;
    groups[v] = m[2].split(';').map((x) => x.trim()).filter(Boolean);
    if (groups[v].length !== Number(m[1])) return null;
  }
  if (rows[2] !== SD_VOTES.map((v) => `${v} ${groups[v].length}`).join('; ') + '.') return null;
  return { ...r, chamber: h[1] as Chamber, session: h[3], bill: h[4], date: h[5], question: q[1], groups };
}

const SD_LINE = /^South Dakota (House|Senate) vote (\d+) \((\d{4}[a-z]?)\), ([A-Z]+ \d+(?:, [A-Z]+ \d+)*) - (.+) \((\d{4}-\d{2}-\d{2})\): (.+?) (voted Yea|voted Nay|was excused|was absent|did not vote|voted present|was suspended)\.$/;

export function formatSouthDakotaVoteLine(l: SdVoteLine): string {
  return `South Dakota ${l.chamber} vote ${l.voteId} (${l.session}), ${l.bill} - ${l.question} (${l.date}): ${l.name} ${SD_SAID[l.vote]}.`;
}

function parseSouthDakotaLine(text: string): SdVoteLine | null {
  const m = SD_LINE.exec(text.trim());
  const vote = m ? SD_VOTES.find((v) => SD_SAID[v] === m[8]) : undefined;
  if (!m || !vote) return null;
  return { state: 'SD', stateName: 'South Dakota', chamber: m[1] as Chamber, voteId: Number(m[2]), session: m[3], bill: m[4],
    question: m[5], date: m[6], name: m[7].trim(), vote };
}

function verifySouthDakotaLine(line: string, url: string, text: string, lastName: string, fullName: string): SnippetVerdict {
  const l = parseSouthDakotaLine(line);
  const r = parseSouthDakotaRender(text, url);
  if (!l || !r) return { verdict: 'snippet_not_found' };
  // a consent calendar's roll call names every bill it carried ("HB 1209, SB 55"), and so does its line
  if (l.voteId !== r.voteId || l.chamber !== r.chamber || l.session !== r.session || l.bill !== r.bill || l.date !== r.date) return { verdict: 'snippet_not_found' };
  if (normalizeText(l.question) !== normalizeText(r.question)) return { verdict: 'snippet_not_found' };
  if (!r.groups[l.vote].some((n) => sameLabel(n, l.name))) return { verdict: 'snippet_not_found' };
  const fits = SD_VOTES.flatMap((v) => r.groups[v]).filter((n) => fullNameLabelFits(n, lastName, fullName));
  if (fits.length !== 1 || !sameLabel(fits[0], l.name)) return { verdict: 'name_not_present' };
  return { verdict: 'verified', matchOffset: 0 };
}

function southDakotaLinesFor(url: string, text: string, lastName: string, fullName: string): string[] {
  const r = parseSouthDakotaRender(text, url);
  if (!r) return [];
  const out: string[] = [];
  for (const vote of SD_VOTES) {
    for (const name of r.groups[vote]) {
      if (fullNameLabelFits(name, lastName, fullName)) out.push(formatSouthDakotaVoteLine({ ...r, name, vote }));
    }
  }
  return out.length === 1 ? out : [];
}

/** The vote an address names, read from the legislature's data (the bodies of stateRollCallDocs). Null when any check fails. */
export function readSouthDakotaVote(bodies: string[], url: string): SdVoteRecord | null {
  const r = parseSouthDakotaVoteUrl(url);
  if (!r) return null;
  try { return readSouthDakota(bodies, r); } catch { return null; }
}

// ── Mississippi: one PDF per vote, read with the bill's history and the session's member list ─────────────────────
// billstatus.ls.state.ms.us/<session>/pdf/votes/<house|senate>/<NNNNNNN>.pdf is the vote, one PDF a person can open
// (read 2026-11-17; the site has no robots.txt). It prints the chamber, the session, the bills voted on in prose ("S.
// B. No. 2987, S. B. No. 2957 and S. B. No. 2959 passed by the following vote:"; one vote can carry several bills),
// and each group as a comma list of the labels members are known by in the chamber: "Yeas--Aguirre, Arnold, Bell
// (65th), Bell (21st), ... Mr. Speaker. Total--114." A label is a surname, with initials and the member's district
// when two members share it ("Jackson G. (15th)"). It prints no date and no member's full name.
//
// So one vote is read from three documents, and the address names the bill after a #:
//   billstatus.ls.state.ms.us/2018/pdf/votes/house/0660005.pdf#SB2987
// 1. the PDF: chamber, session, the bills named, the groups, each group's printed total;
// 2. the bill's history, /<session>/pdf/history/<SB>/<SB2987>.xml: the one action that links this PDF gives the day
//    ("03/08 (H) Passed As Amended"), the chamber, and the question, which must be a vote on the bill
//    (msQuestionIsOnTheBill); a motion to reconsider, to table, ... is not;
// 3. the session's member list for that chamber, /<session>/pdf/<h|s>_auth.xml: each member's full name and the key
//    the label stands for (house_authors/bell_(65th).xml, creekmore_iv.xml). It is the list of the session's AUTHORS,
//    so a member who wrote no bill that session is not on it (2023: Perry Bailey, "Bailey (23rd)");
// 4. the legislature's current member list, /members/<hr|ss>_membs.xml, which prints the term it covers ("2024-2027")
//    and the Speaker. It is read for a label the session's list does not hold, and only for a session inside that
//    term (2024 prints "Butler-Washington" and lists her as butler-washinton).
// A label neither list holds is printed as the PDF prints it: the vote still reads, and that member gets no line,
// because a bare label fits no politician's full name. Two lists that disagree, or a member listed twice, refuse the
// vote. "Mr. Speaker" is the Speaker of the House, who is not printed by name (MS_SPEAKER).
// A member who did not vote is listed as the PDF lists them: "Absent or those not voting" (one group), "Voting
// Present" (or "Present"), or paired ("Senator Simmons W. (13th), who would have voted yea on H. B. No. 1083,
// announced a pair with Senator Barnett, who would have voted nay."). None of these is a Yea or a Nay, and none seats
// anyone.
//
//   Mississippi House vote 0660005 (2018), SB 2987, 2018-03-08.
//   Question: Passed As Amended
//   Yea 114; Nay 0; Absent or not voting 6; Present 0.
//   Yea (114): Shane Aguirre; …
//   Mississippi House vote 0660005 (2018), SB 2987 - Passed As Amended (2018-03-08): Shane Aguirre voted Yea.

/** A PDF handed to a reader as text: the marker, then one line per printed line (runs of one baseline, left to right). */
export const PDF_LINES_MARK = '%PDF-LINES';

/**
 * A PDF's text runs as lines a reader can parse: runs of one page on one baseline (within 2 units), left to right,
 * pages and lines in reading order. A PDF stores positioned runs, not rows; pairing by position is what keeps a
 * label on its own line (root CLAUDE.md, "PDF text has no rows").
 */
export function pdfLinesBody(items: { page: number; x: number; y: number; str: string }[]): string {
  const sorted = [...items].filter((i) => i.str.trim()).sort((a, b) => a.page - b.page || b.y - a.y || a.x - b.x);
  const lines: { page: number; y: number; runs: { x: number; s: string }[] }[] = [];
  for (const i of sorted) {
    const last = lines[lines.length - 1];
    if (last && last.page === i.page && Math.abs(last.y - i.y) <= 2) last.runs.push({ x: i.x, s: i.str });
    else lines.push({ page: i.page, y: i.y, runs: [{ x: i.x, s: i.str }] });
  }
  return [PDF_LINES_MARK, ...lines.map((l) => squash(l.runs.sort((a, b) => a.x - b.x).map((r) => r.s).join(' ')))].join('\n');
}

export const MS_VOTES = ['Yea', 'Nay', 'Absent or not voting', 'Present', 'Paired'] as const;
export type MsVote = (typeof MS_VOTES)[number];
/** Each heading the PDFs print, and the group it is. A heading not listed refuses the vote. */
const MS_HEADING: [RegExp, MsVote][] = [
  [/^Yeas$/i, 'Yea'],
  [/^Nays$/i, 'Nay'],
  [/^Absent (?:or|and) those not voting$/i, 'Absent or not voting'],
  [/^(?:Voting )?Present$/i, 'Present'],
];
const MS_URL = /^https:\/\/billstatus\.ls\.state\.ms\.us\/(20\d{2}(?:[1-9]E)?)\/pdf\/votes\/(house|senate)\/(\d{7})\.pdf#([HS][A-Z]{1,2})([1-9]\d{0,3})$/;
const MS_SITE = 'https://billstatus.ls.state.ms.us/';
/** No robots.txt (404, 2026-11-17), so no Crawl-delay is stated: one request a second is ours. */
const MS_GAP_MS = 1_000;
const MS_SIZE: Record<Chamber, number> = { House: 122, Senate: 52 };
/**
 * Who "Mr. Speaker" is, by the session's year: the member-list key of the Speaker of the House. The PDFs never print
 * the Speaker's name. Philip Gunn was Speaker from 2012 until the term that began in January 2024; Jason White from
 * then (the House member list for 2024-2027, members/hr_membs.xml, names him as Speaker; read 2026-11-17). A session
 * not covered gives no vote that prints "Mr. Speaker". The key must be exactly one member of that session's list.
 */
export const MS_SPEAKER: readonly { from: number; to: number; key: string }[] = [
  { from: 2012, to: 2023, key: 'gunn' },
  { from: 2024, to: 2027, key: 'white' },
];

/**
 * Is a Mississippi history action (the words after the chamber: "Passed As Amended") a vote on the bill? A motion is
 * not (runner, 2026-11-16): to reconsider, to table, to suspend the rules, to recall, to refer. Only the questions
 * listed are read; any other wording gives no line until it is added here.
 */
export function msQuestionIsOnTheBill(q: string): boolean {
  return /^(Passed|Passed As Amended|Failed|Adopted|Adopted As Amended|Failed To Adopt|Concurred in Amend From (House|Senate)|Concurred in Amendment From (House|Senate)|Decline to Concur\/Invite Conf|Conference Report Adopted|Conference Report Failed|Veto Overridden|Veto Sustained|Failed to Override Veto|Passed Notwithstanding Veto)$/i.test(squash(q));
}

export interface MsVoteRef { state: 'MS'; stateName: 'Mississippi'; chamber: Chamber; session: string; voteNo: string; billType: string; billNum: number }
export interface MsVoteRecord extends MsVoteRef { bill: string; question: string; date: string; groups: Record<MsVote, string[]> }
export interface MsVoteLine extends Omit<MsVoteRecord, 'groups' | 'billType' | 'billNum'> { name: string; vote: MsVote }

export function parseMississippiVoteUrl(url: string): MsVoteRef | null {
  const m = MS_URL.exec(url.trim());
  if (!m) return null;
  return { state: 'MS', stateName: 'Mississippi', chamber: m[2] === 'house' ? 'House' : 'Senate', session: m[1], voteNo: m[3], billType: m[4], billNum: Number(m[5]) };
}

function mississippiDocs(r: MsVoteRef): string[] {
  const t = r.billType;
  return [
    `${MS_SITE}${r.session}/pdf/votes/${r.chamber.toLowerCase()}/${r.voteNo}.pdf`,
    `${MS_SITE}${r.session}/pdf/history/${t}/${t}${String(r.billNum).padStart(4, '0')}.xml`,
    `${MS_SITE}${r.session}/pdf/${r.chamber === 'House' ? 'h' : 's'}_auth.xml`,
    `${MS_SITE}members/${r.chamber === 'House' ? 'hr' : 'ss'}_membs.xml`,
  ];
}

const xmlText = (s: string): string => squash(s.replace(/<!\[CDATA\[|\]\]>/g, '').replace(/&amp;/g, '&').replace(/&apos;/g, "'").replace(/&quot;/g, '"').replace(/&lt;/g, '<').replace(/&gt;/g, '>'));
const xmlAll = (xml: string, tag: string): string[] => [...xml.matchAll(new RegExp(`<${tag}>([\\s\\S]*?)</${tag}>`, 'g'))].map((m) => xmlText(m[1]));
/** The bills a PDF's prose names, as the history names them: "S. C. R. No. 640" -> "SC 640", "H. B. No. 1466" -> "HB 1466". */
function msBillsNamed(prose: string): string[] {
  return [...prose.matchAll(/\b([HS])\.\s*((?:[A-Z]\.\s*){1,2})No\.\s*(\d{1,4})\b/g)].map((m) => {
    const t = (m[1] + m[2].replace(/[.\s]/g, '')).replace(/CR$/, 'C');
    return `${t} ${Number(m[3])}`;
  });
}

/**
 * A member list: key (the link's file name, "bell_(65th)") -> full name(s). The session's author list links into
 * house_authors/ or senate_authors/, the current member list into house/ or senate/.
 */
function msMembers(xml: string, chamber: Chamber, current: boolean): Map<string, string[]> | null {
  const folder = `${chamber === 'House' ? 'house' : 'senate'}${current ? '' : '_authors'}`;
  const out = new Map<string, string[]>();
  for (const m of xml.matchAll(/<M(\d+)_NAME>([^<]*)<\/M\1_NAME>\s*<M\1_LINK>([^<]*)<\/M\1_LINK>/g)) {
    // [^<]* and the shared number: an empty <M5_NAME></M5_NAME> with no link must not run on into the next member.
    const name = xmlText(m[2]);
    const link = /^([a-z_]+)\/(.+)\.xml$/i.exec(xmlText(m[3]));
    if (!name || !link) return null;
    if (link[1].toLowerCase() !== folder) return null;
    const key = link[2].toLowerCase();
    out.set(key, [...(out.get(key) ?? []), name]);
  }
  return out.size ? out : null;
}

/** "Jackson G. (15th)" -> key "jackson_(15th)" and initials ["g"]; "Gillespie Isom" -> "gillespie isom"; null for no label. */
function msLabelKey(label: string): { key: string; initials: string[] } | null {
  const m = /^([A-Za-z][A-Za-z'\- ]*?[A-Za-z])((?:\s+[A-Z]\.)*)(?:\s+\((\d{1,3})(?:st|nd|rd|th)\))?$/.exec(squash(label));
  if (!m) return null;
  const sur = m[1].toLowerCase().replace(/ /g, '_');
  return { key: m[3] ? `${sur}_(${m[3]}${ordinal(Number(m[3])).slice(String(Number(m[3])).length)})` : sur, initials: (m[2].match(/[A-Z]/g) ?? []).map((c) => c.toLowerCase()) };
}

/** The vote, or why it was refused (the first check that failed). */
function readMississippi(bodies: string[], r: MsVoteRef): MsVoteRecord | { refused: string } {
  const fail = (refused: string): { refused: string } => ({ refused });
  if (bodies.length !== 4 || !bodies[0].startsWith(PDF_LINES_MARK + '\n')) return fail("not three documents, or the first is not a PDF");
  const year = Number(r.session.slice(0, 4));
  // 1. the PDF
  const lines = bodies[0].split('\n').slice(1);
  if (lines[0] !== (r.chamber === 'House' ? 'Mississippi House of Representatives' : 'Mississippi State Senate')) return fail("the PDF does not name this chamber");
  const sess = /^(\d{4}) (Regular|First Extraordinary|Second Extraordinary|Third Extraordinary) Session$/.exec(lines[1] ?? '');
  if (!sess || Number(sess[1]) !== year || (sess[2] === 'Regular') !== /^\d{4}$/.test(r.session)) return fail("the PDF does not name this session");
  const end = lines.indexOf('DISCLAIMER');
  if (end < 0) return fail("the PDF has no disclaimer to end on");
  // a line ending in a hyphen runs on without a space ("Total--" / "51.", "Williams-" / "Barnes")
  const text = lines.slice(2, end).reduce((acc, l) => (acc === '' ? l : acc.endsWith('-') ? acc + l : `${acc} ${l}`), '');
  const first = text.search(/\bYeas--/);
  if (first < 0) return fail("the PDF has no Yeas");
  const prose = text.slice(0, first);
  const bill = `${r.billType} ${r.billNum}`;
  if (!msBillsNamed(prose).includes(bill)) return fail("the PDF does not name the bill");
  const groups = Object.fromEntries(MS_VOTES.map((v) => [v, [] as string[]])) as Record<MsVote, string[]>;
  const labels = Object.fromEntries(MS_VOTES.map((v) => [v, [] as string[]])) as Record<MsVote, string[]>;
  const seenGroup = new Set<MsVote>();
  // "Heading--names. Total--N." or "Heading--None." (the Senate prints "Absent and those not voting----None."); then
  // "Vacancies--N." is a count of empty seats, not members
  let rest = text.slice(first);
  const pairs: { yea: string; nay: string }[] = [];
  while (rest) {
    // counts that name no member: empty seats, and the votes a three-fifths bill needed
    const count = /^(?:Vacancies|Necessary for Passage)--(\d+)\.\s*/.exec(rest);
    if (count) { rest = rest.slice(count[0].length); continue; }
    // a pair: two members who did not vote, each saying how they would have
    const pair = /^(Senator|Representative) (.+?), who would have voted (yea|nay) on [^,]+, announced a pair with (?:Senator|Representative) (.+?), who would have voted (yea|nay)\.\s*/.exec(rest);
    if (pair) {
      if ((pair[1] === 'Senator') !== (r.chamber === 'Senate') || pair[3] === pair[5]) return fail(`a pair the reader cannot read: ${pair[0]}`);
      pairs.push(pair[3] === 'yea' ? { yea: pair[2], nay: pair[4] } : { yea: pair[4], nay: pair[2] });
      rest = rest.slice(pair[0].length);
      continue;
    }
    if (pairs.length) return fail(`text after a pair the reader does not know: ${rest.slice(0, 60)}`);
    const h = /^([A-Za-z][A-Za-z ]*?)-{2,4}/.exec(rest);
    if (!h) return fail(`a heading the reader does not know: ${rest.slice(0, 60)}`);
    const g = MS_HEADING.find(([re]) => re.test(h[1].trim()))?.[1];
    if (!g || seenGroup.has(g)) return fail(`a heading the reader does not know, or one printed twice: ${h[1]}`);
    seenGroup.add(g);
    rest = rest.slice(h[0].length);
    const none = /^None\.\s*/.exec(rest);
    if (none) { rest = rest.slice(none[0].length); continue; }
    const body = /^(.+?)\.\s*Total--\s*(\d+)\.\s*/.exec(rest);
    if (!body) return fail(`a group whose names do not end in a printed total: ${rest.slice(0, 60)}`);
    const names = body[1].split(/,\s*/).map(squash);
    if (names.length !== Number(body[2]) || names.some((n) => !n)) return fail(`the ${g} group lists ${names.length} names and prints a total of ${body[2]}`);
    labels[g] = names;
    rest = rest.slice(body[0].length);
  }
  if (!seenGroup.has('Yea') || !seenGroup.has('Nay')) return fail('no Yeas or no Nays heading');
  for (const p of pairs) labels.Paired.push(p.yea, p.nay);
  // 2. the bill's history: the one action that links this PDF
  const h = bodies[1];
  if (xmlAll(h, 'SHORT_MSRID')[0] !== bill || Number(xmlAll(h, 'YEAR')[0]) !== year) return fail('the history is not this bill of this session');
  const pdfPath = `/${r.session}/pdf/votes/${r.chamber.toLowerCase()}/${r.voteNo}.pdf`;
  const acts = [...h.matchAll(/<ACTION>([\s\S]*?)<\/ACTION>/g)].map((m) => ({ desc: xmlAll(m[1], 'ACT_DESC')[0] ?? '', votes: xmlAll(m[1], 'ACT_VOTE') }))
    .filter((a) => a.votes.some((v) => v.replace(/^(\.\.\/)+/, '/').toLowerCase() === pdfPath.toLowerCase()));
  if (acts.length !== 1) return fail(`the history links this vote ${acts.length} times`);
  const a = /^(\d{2})\/(\d{2}) \((H|S)\) (.+)$/.exec(acts[0].desc);
  if (!a || (a[3] === 'H') !== (r.chamber === 'House')) return fail('the history action is not of this chamber');
  const question = squash(a[4]);
  if (!msQuestionIsOnTheBill(question)) return fail(`the history action is not a vote on the bill: ${question}`);
  const date = `${year}-${a[1]}-${a[2]}`;
  if (Number.isNaN(Date.parse(`${date}T00:00:00Z`))) return fail('the history action has no real date');
  // 3 and 4. the member lists
  const session = msMembers(bodies[2], r.chamber, false);
  if (!session) return fail("the session's member list cannot be read");
  const current = msMembers(bodies[3], r.chamber, true);
  const term = /<TERM>\s*(\d{4})-(\d{4})\s*<\/TERM>/.exec(bodies[3]);
  if (!current || !term) return fail('the current member list cannot be read');
  const inTerm = year >= Number(term[1]) && year <= Number(term[2]);
  const chair = /<CHAIR_LINK>\s*house\/([^<]+?)\.xml\s*<\/CHAIR_LINK>/i.exec(bodies[3])?.[1].toLowerCase();
  const lookup = (key: string): string[] | undefined => session.get(key) ?? (inTerm ? current.get(key) : undefined);
  const used = new Set<string>();
  const printed = new Set(MS_VOTES.flatMap((v) => labels[v]).map((l) => msLabelKey(l)?.key).filter(Boolean));
  for (const v of MS_VOTES) {
    for (const label of labels[v]) {
      let key: string;
      if (/^Mr\.? Speaker$/i.test(label)) {
        if (r.chamber !== 'House') return fail('Mr. Speaker outside the House');
        const sp = MS_SPEAKER.find((x) => year >= x.from && year <= x.to);
        if (!sp || printed.has(sp.key) || (inTerm && chair !== sp.key)) return fail('no Speaker for this session, the Speaker printed by name too, or not the Speaker the current list names');
        key = sp.key;
      } else {
        const k = msLabelKey(label);
        if (!k) return fail(`a label the reader cannot read: ${label}`);
        key = k.key;
        const name = lookup(key);
        // a label's initials must be the first letters of the member's given names
        if (name && name.length === 1 && k.initials.length) {
          const given = fold(name[0]).split(' ').slice(0, -1).map((w) => w[0]);
          if (!k.initials.every((i) => given.includes(i))) return fail(`the label ${label} has initials that are not ${name[0]}'s`);
        }
      }
      if (used.has(key)) return fail(`the label ${label} (${key}) is listed twice`);
      used.add(key);
      const name = lookup(key);
      if (name && name.length > 1) return fail(`the label ${label} (${key}) is ${name.length} members of the list`);
      // a label neither list holds is kept as printed: it fits no full name, so that member gets no line
      groups[v].push(name ? squash(name[0]) : label);
    }
  }
  if (used.size > MS_SIZE[r.chamber]) return fail("more members than the chamber has");
  return { ...r, bill, question, date, groups };
}

const MS_SAID: Record<MsVote, string> = { Yea: 'voted Yea', Nay: 'voted Nay', 'Absent or not voting': 'was absent or did not vote', Present: 'voted present', Paired: 'was paired' };

export function renderMississippiVote(v: MsVoteRecord): string {
  return [
    `Mississippi ${v.chamber} vote ${v.voteNo} (${v.session}), ${v.bill}, ${v.date}.`,
    `Question: ${v.question}`,
    MS_VOTES.map((k) => `${k} ${v.groups[k].length}`).join('; ') + '.',
    ...MS_VOTES.map((k) => `${k} (${v.groups[k].length}): ${v.groups[k].join('; ')}`.trim()),
  ].join('\n');
}

const MS_RENDER_HEAD = /^Mississippi (House|Senate) vote (\d{7}) \((20\d{2}(?:[1-9]E)?)\), ([A-Z]{2,3} \d+), (\d{4}-\d{2}-\d{2})\.$/;

function parseMississippiRender(text: string, url: string): Omit<MsVoteRecord, 'billType' | 'billNum'> | null {
  const r = parseMississippiVoteUrl(url);
  const rows = text.split('\n');
  const h = MS_RENDER_HEAD.exec(rows[0] ?? '');
  const q = /^Question: (.+)$/.exec(rows[1] ?? '');
  if (!r || !h || !q || rows.length !== 3 + MS_VOTES.length) return null;
  if (h[1] !== r.chamber || h[2] !== r.voteNo || h[3] !== r.session || h[4] !== `${r.billType} ${r.billNum}`) return null;
  const groups = {} as Record<MsVote, string[]>;
  for (const [i, v] of MS_VOTES.entries()) {
    const m = new RegExp(`^${v} \\((\\d+)\\):(.*)$`).exec(rows[3 + i]);
    if (!m) return null;
    groups[v] = m[2].split(';').map((x) => x.trim()).filter(Boolean);
    if (groups[v].length !== Number(m[1])) return null;
  }
  if (rows[2] !== MS_VOTES.map((v) => `${v} ${groups[v].length}`).join('; ') + '.') return null;
  return { state: 'MS', stateName: 'Mississippi', chamber: r.chamber, session: r.session, voteNo: r.voteNo, bill: h[4], date: h[5], question: q[1], groups };
}

const MS_LINE = /^Mississippi (House|Senate) vote (\d{7}) \((20\d{2}(?:[1-9]E)?)\), ([A-Z]{2,3} \d+) - (.+) \((\d{4}-\d{2}-\d{2})\): (.+?) (voted Yea|voted Nay|was absent or did not vote|voted present|was paired)\.$/;

export function formatMississippiVoteLine(l: MsVoteLine): string {
  return `Mississippi ${l.chamber} vote ${l.voteNo} (${l.session}), ${l.bill} - ${l.question} (${l.date}): ${l.name} ${MS_SAID[l.vote]}.`;
}

function parseMississippiLine(text: string): MsVoteLine | null {
  const m = MS_LINE.exec(text.trim());
  const vote = m ? MS_VOTES.find((v) => MS_SAID[v] === m[8]) : undefined;
  if (!m || !vote) return null;
  return { state: 'MS', stateName: 'Mississippi', chamber: m[1] as Chamber, voteNo: m[2], session: m[3], bill: m[4], question: m[5], date: m[6], name: m[7].trim(), vote };
}

function verifyMississippiLine(line: string, url: string, text: string, lastName: string, fullName: string): SnippetVerdict {
  const l = parseMississippiLine(line);
  const r = parseMississippiRender(text, url);
  if (!l || !r) return { verdict: 'snippet_not_found' };
  if (l.voteNo !== r.voteNo || l.chamber !== r.chamber || l.session !== r.session || l.bill !== r.bill || l.date !== r.date) return { verdict: 'snippet_not_found' };
  if (normalizeText(l.question) !== normalizeText(r.question)) return { verdict: 'snippet_not_found' };
  if (!r.groups[l.vote].some((n) => sameLabel(n, l.name))) return { verdict: 'snippet_not_found' };
  const fits = MS_VOTES.flatMap((v) => r.groups[v]).filter((n) => fullNameLabelFits(n, lastName, fullName));
  if (fits.length !== 1 || !sameLabel(fits[0], l.name)) return { verdict: 'name_not_present' };
  return { verdict: 'verified', matchOffset: 0 };
}

function mississippiLinesFor(url: string, text: string, lastName: string, fullName: string): string[] {
  const r = parseMississippiRender(text, url);
  if (!r) return [];
  const out: string[] = [];
  for (const vote of MS_VOTES) {
    for (const name of r.groups[vote]) {
      if (fullNameLabelFits(name, lastName, fullName)) out.push(formatMississippiVoteLine({ ...r, name, vote }));
    }
  }
  return out.length === 1 ? out : [];
}

/** The vote an address names, read from its three documents (stateRollCallDocs order). Null when any check fails. */
export function readMississippiVote(bodies: string[], url: string): MsVoteRecord | null {
  const v = explainMississippiVote(bodies, url);
  return 'refused' in v ? null : v;
}

/** As readMississippiVote, with the reason a vote is refused: for the fetch tool's report and the tests. */
export function explainMississippiVote(bodies: string[], url: string): MsVoteRecord | { refused: string } {
  const r = parseMississippiVoteUrl(url);
  if (!r) return { refused: 'not a Mississippi vote address' };
  try { return readMississippi(bodies, r); } catch (e) { return { refused: `the reader failed: ${e instanceof Error ? e.message : e}` }; }
}

// ── Maryland: one PDF (2018 on) or page (2013, 2017) per vote, read with the session's committee member lists ───────
// mgaleg.maryland.gov/<year>RS/votes/<house|senate>/<NNNN>.pdf is the vote (2018 on); 2013's and 2017's votes are
// pages, /2017RS/votes/<house|senate>/<NNNN>.htm, one table cell per printed item (MD_PAGE_YEARS). The site has no robots.txt (404, 2026-11-18).
// Both print the same items: "SEQ NO. 1104", "Calendar Date: Apr 8, 2026 12:36 (PM)" (the day of the vote), the
// chamber ("Maryland House of Delegates", "Senate of Maryland"), "2026 Regular Session", the bill ("SB 128"; a consent
// calendar lists several), the calendar line, sponsor, committee, title, the question ("On Third Reading", with a
// separate "(Emerg)"), the tally ("132 Yeas 0 Nays 6 Not Voting 0 Excused 3 Absent"; 2017 prints "0 Excused (Absent)
// 0 Absent"), then five headings, each followed by its members: "Voting Yea - 132", "Voting Nay - 0", "Not Voting -
// 6", "Excused from Voting - 0", "Excused (Absent) - 3". A member is printed by surname, with initials when two share
// it ("Johnson, A."), and a star when the member changed their vote ("Cluster*"). The presiding officer is printed by
// office ("Speaker", "Mr. President", "Speaker Busch"), and not reliably: 2022RS house vote 1322 prints "Speaker"
// voting Yea while the Speaker, Adrienne Jones, is listed as absent. So an office label is kept as printed and gives
// no line.
//
// A PDF prints one run per member, four or five to a row; joining a row's runs with spaces cannot tell "White Holland"
// (one member) from "White" and "Holland". The reader is therefore handed the runs themselves, one row per line and
// the runs separated by a tab (pdfCellsBody). Some PDFs are printed sideways (the 2019 consent calendars); the rows
// are taken along the text's own direction.
//
// The PDF prints no member's full name. The session's member list is the union of the chamber's standing committees,
// /mgawebsite/Committees/Details?cmte=<code>&ys=<year>RS (the Members index ignores the session): each lists its
// members as "Surname, Given M., Jr." with the member's key. A label is the one member of that chamber's lists whose
// surname it prints and whose given names its initials start; when several fit, a member another label of the same
// vote already names is taken out. A label no member fits, or more than one, is kept as printed and gives no line.
//
// So one vote is read from the vote and its chamber's committee pages, and the address names the bill after a #:
//   mgaleg.maryland.gov/2026RS/votes/house/1104.pdf#SB128
// A vote is read only when the number, chamber, session and bill are the address's, the question is a vote on the
// bill (mdQuestionIsOnTheBill), each group lists the count its heading prints, and the headings' counts are the
// tally's, in order:
//
//   Maryland House vote 1104 (2026RS), SB 128, 2026-04-08.
//   Question: On Third Reading
//   Yea 132; Nay 0; Not voting 6; Excused 0; Absent 3.
//   Yea (132): Gabriel Acevero; …
//   Maryland House vote 1104 (2026RS), SB 128 - On Third Reading (2026-04-08): Gabriel Acevero voted Yea.

/** A PDF handed to a reader as its runs: the marker, then one line per printed row, the row's runs separated by a tab. */
export const PDF_CELLS_MARK = '%PDF-CELLS';

/**
 * A PDF's text runs as rows of cells: runs of one page on one baseline (within 2 units) are a row, in reading order
 * along the text's own direction (a page printed sideways is read sideways). Each run stays a cell of its own.
 */
export function pdfCellsBody(items: { page: number; x: number; y: number; str: string; dir?: number }[]): string {
  const placed = items.filter((i) => i.str.trim()).map((i) => {
    const q = ((i.dir ?? 0) % 4 + 4) % 4;
    const [c, s] = [[1, 0], [0, 1], [-1, 0], [0, -1]][q];
    // u runs along the text, v across it (larger v is nearer the top of the page as read)
    return { page: i.page, u: i.x * c + i.y * s, v: -i.x * s + i.y * c, str: squash(i.str) };
  }).sort((a, b) => a.page - b.page || b.v - a.v || a.u - b.u);
  const rows: { page: number; v: number; cells: { u: number; s: string }[] }[] = [];
  for (const i of placed) {
    const last = rows[rows.length - 1];
    if (last && last.page === i.page && Math.abs(last.v - i.v) <= 2) last.cells.push({ u: i.u, s: i.str });
    else rows.push({ page: i.page, v: i.v, cells: [{ u: i.u, s: i.str }] });
  }
  return [PDF_CELLS_MARK, ...rows.map((r) => r.cells.sort((a, b) => a.u - b.u).map((c) => c.s).join('\t'))].join('\n');
}

export const MD_VOTES = ['Yea', 'Nay', 'Not voting', 'Excused', 'Absent'] as const;
export type MdVote = (typeof MD_VOTES)[number];
/** The five headings, in the order the record prints them; any other order or wording refuses the vote. */
const MD_HEADING: [RegExp, MdVote][] = [
  [/^Voting Yea - (\d+)$/, 'Yea'],
  [/^Voting Nay - (\d+)$/, 'Nay'],
  [/^Not Voting - (\d+)$/, 'Not voting'],
  [/^Excused from Voting - (\d+)$/, 'Excused'],
  [/^Excused \(Absent\) - (\d+)$/, 'Absent'],
];
const MD_TALLY = /^(\d+) Yeas (\d+) Nays (\d+) Not Voting (\d+) Excused(?: \(Absent\))? (\d+) Absent$/;
// A veto is overridden in the NEXT session, on a vote filed under that session ("SPECIAL ORDER CALENDAR - 2020 VETOED
// HOUSE BILL"), and that session has its own bill of the same number: the address names the bill's year, #2020-HB4.
const MD_URL = /^https:\/\/mgaleg\.maryland\.gov\/(20\d{2})RS\/votes\/(house|senate)\/(\d{4})\.(pdf|htm)#(?:(20\d{2})-)?([HS][BJ])([1-9]\d{0,3})$/;
const MD_SITE = 'https://mgaleg.maryland.gov/';
/** No robots.txt (404, 2026-11-18), so no Crawl-delay is stated: one request a second is ours. */
const MD_GAP_MS = 1_000;
const MD_SIZE: Record<Chamber, number> = { House: 141, Senate: 47 };
/**
 * The sessions whose votes are pages (.htm), one table cell per printed item; every session from 2018 is a PDF. Only
 * the sessions read and checked are listed: 2017, and 2013 (2013 SB 281, House vote 895, read 2026-11-18 for the
 * md-02 batch; its page prints the same items as 2017's, with "Legislative Date" and "Presiding" lines the reader
 * does not need). 2014-2016 are not read: add a year here only after reading one of its votes with a control.
 */
export const MD_PAGE_YEARS: readonly number[] = [2013, 2017];
const MD_MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
/** The presiding officer, printed by office: kept as printed, so it gives no line. */
const MD_OFFICE = /^(?:Mr\.|Madam) (?:Speaker|President)$|^Speaker(?: [\p{L}'-]+)?$|^President(?: [\p{L}'-]+)?$/u;
/** A member label: a surname of one or more words, initials after a comma, a star for a changed vote. */
const MD_LABEL = /^([\p{L}][\p{L}'’ -]*[\p{L}])(?:,\s*((?:[\p{L}]\.\s?){1,3}))?\*?$/u;

/**
 * The chamber's standing committees in a session, whose member lists together are the chamber's members. The House
 * Environment and Transportation committee was Environment (env) through 2018; Health and Government Operations (hgo)
 * became Health (hlt) and Government (gvc) in 2026; the Senate's Education committee was ehe through 2022 and eee
 * from 2023 (each read 2026-11-18).
 */
export function mdCommittees(chamber: Chamber, year: number): string[] {
  if (chamber === 'House') return ['app', 'ecm', year <= 2018 ? 'env' : 'ent', 'jud', 'w%26m', 'hru', ...(year <= 2025 ? ['hgo'] : ['hlt', 'gvc'])];
  return ['b%26t', year <= 2022 ? 'ehe' : 'eee', 'fin', 'jpr', 'sru', 'exn'];
}

/**
 * Is a Maryland question (the line above the tally, its parenthesised notes left out) a vote on the bill? A motion
 * is not (runner, 2026-11-16): to suspend the rules, to recommit, to special order, to limit debate, the previous
 * question, an amendment, a second-reading report. Only the questions listed are read; any other wording gives no
 * line until it is added here. A consent calendar on third reading prints no question; its calendar line says what
 * it is (mdConsentQuestion).
 */
export function mdQuestionIsOnTheBill(q: string): boolean {
  const s = squash(q.replace(/\([^)]*\)/g, ' ')).replace(/\.$/, '');
  return /^(?:On )?Third Reading(?: (?:and|for) Final Passage)?$|^Bill is on Third Reading for Final Passage$|^Shall the bill pass notwithstanding the objections? of the Chief Executive\?$|^Veto Override$|^Conference Committee Report - Adoption$|^Third Reading Consent Calendar$/i.test(s);
}

export interface MdVoteRef { state: 'MD'; stateName: 'Maryland'; chamber: Chamber; session: string; seq: number; ext: 'pdf' | 'htm'; billType: string; billNum: number; billYear?: number }
export interface MdVoteRecord extends Omit<MdVoteRef, 'ext' | 'billType' | 'billNum' | 'billYear'> { bill: string; question: string; date: string; groups: Record<MdVote, string[]> }
export interface MdVoteLine extends Omit<MdVoteRecord, 'groups'> { name: string; vote: MdVote }

export function parseMarylandVoteUrl(url: string): MdVoteRef | null {
  const m = MD_URL.exec(url.trim());
  if (!m) return null;
  const year = Number(m[1]);
  // 2013's and 2017's votes are pages, every later session's PDFs (MD_PAGE_YEARS)
  if ((m[4] === 'htm') !== MD_PAGE_YEARS.includes(year)) return null;
  // a bill of another session is only the previous session's vetoed bill
  if (m[5] && Number(m[5]) !== year - 1) return null;
  return { state: 'MD', stateName: 'Maryland', chamber: m[2] === 'house' ? 'House' : 'Senate', session: `${m[1]}RS`, seq: Number(m[3]), ext: m[4] as 'pdf' | 'htm', billType: m[6], billNum: Number(m[7]), ...(m[5] ? { billYear: Number(m[5]) } : {}) };
}

/** The bill as a line names it: "HB 4", or "HB 4 of 2020" for the previous session's vetoed bill. */
function mdBillName(r: MdVoteRef): string {
  return `${r.billType} ${r.billNum}${r.billYear ? ` of ${r.billYear}` : ''}`;
}

function marylandDocs(r: MdVoteRef): string[] {
  const year = r.session.slice(0, 4);
  return [
    `${MD_SITE}${r.session}/votes/${r.chamber.toLowerCase()}/${String(r.seq).padStart(4, '0')}.${r.ext}`,
    ...mdCommittees(r.chamber, Number(year)).map((c) => `${MD_SITE}mgawebsite/Committees/Details?cmte=${c}&ys=${r.session}`),
  ];
}

const htmlText = (s: string): string => squash(s.replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&#(\d+);/g, (_m, n: string) => String.fromCodePoint(Number(n)))
  .replace(/&#x([0-9a-f]+);/gi, (_m, n: string) => String.fromCodePoint(parseInt(n, 16))).replace(/&quot;/g, '"').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&'));

/** The vote's printed items as rows of cells: a PDF's rows (pdfCellsBody), or a 2013 or 2017 page's table cells, one row each. */
function mdRows(body: string, ext: 'pdf' | 'htm'): string[][] | null {
  if (ext === 'pdf') {
    if (!body.startsWith(PDF_CELLS_MARK + '\n')) return null;
    return body.split('\n').slice(1).map((l) => l.split('\t').map(squash).filter(Boolean)).filter((r) => r.length);
  }
  if (body.startsWith('%PDF')) return null;
  return [...body.matchAll(/<td\b[^>]*>([\s\S]*?)<\/td>/gi)].map((m) => [htmlText(m[1])]).filter((r) => r[0]);
}

/** A committee page's members: key -> "Surname, Given M., Jr.". Null when the page is not that session's, or lists none. */
function mdCommitteeMembers(html: string, session: string): Map<string, string> | null {
  const sel = /<select[^>]*id="valueSessions"[^>]*>\s*<option[^>]*>([^<]*)<\/option>\s*<\/select>/.exec(html);
  if (!sel || squash(sel[1]) !== `${session.slice(0, 4)} Regular Session`) return null;
  const start = html.indexOf('id="divMembership"');
  if (start < 0) return null;
  const next = html.indexOf('role="tabpanel"', start + 40);
  const block = html.slice(start, next > 0 ? next : html.length);
  const out = new Map<string, string>();
  for (const m of block.matchAll(/<a href="\/mgawebsite\/Members\/Details\/([^"?]+)">([^<]+)<\/a>/g)) {
    const key = decodeURIComponent(m[1]).toLowerCase();
    const name = htmlText(m[2]);
    if (out.has(key) && out.get(key) !== name) throw new Error(`the key ${key} names both ${out.get(key)} and ${name}`);
    out.set(key, name);
  }
  return out.size ? out : null;
}

/** "Smith, William C., Jr." -> surname "smith", given ["william", "c"], full "William C. Smith Jr."; null for any other shape. */
function mdMember(listed: string): { sur: string; given: string[]; full: string } | null {
  const m = /^([^,]+),\s*([^,]+?)(?:,\s*(Jr\.?|Sr\.?|II|III|IV|V))?$/.exec(squash(listed));
  if (!m) return null;
  return { sur: fold(m[1]), given: fold(m[2].replace(/["“][^"”]*["”]/g, ' ')).split(' ').filter(Boolean), full: squash(`${m[2]} ${m[1]}${m[3] ? ` ${m[3]}` : ''}`) };
}

/** The vote, or why it was refused (the first check that failed). */
function readMaryland(bodies: string[], r: MdVoteRef): MdVoteRecord | { refused: string } {
  const fail = (refused: string): { refused: string } => ({ refused });
  const committees = mdCommittees(r.chamber, Number(r.session.slice(0, 4)));
  if (bodies.length !== 1 + committees.length) return fail('not the vote and its committee pages');
  const rows = mdRows(bodies[0], r.ext);
  if (!rows) return fail(`the vote is not a ${r.ext === 'pdf' ? 'PDF' : 'page'}`);
  const year = Number(r.session.slice(0, 4));
  // the header: everything before the first heading
  const first = rows.findIndex((row) => MD_HEADING[0][0].test(row.join(' ')));
  if (first < 0) return fail('the vote has no Voting Yea heading');
  const head = rows.slice(0, first);
  const cells = head.flat();
  // the chamber and session may run across rows ("General Assembly of Maryland 2022 Regular" / "Session")
  const headText = ` ${squash(cells.join(' '))} `;
  const seq = cells.map((c) => /^SEQ NO\. (\d+)$/.exec(c)).filter(Boolean);
  if (seq.length !== 1 || Number(seq[0]![1]) !== r.seq) return fail('the vote does not print this number');
  if (!headText.includes(r.chamber === 'House' ? ' Maryland House of Delegates ' : ' Senate of Maryland ')) return fail('the vote does not name this chamber');
  if (headText.includes(r.chamber === 'House' ? ' Senate of Maryland ' : ' Maryland House of Delegates ')) return fail('the vote names the other chamber');
  // the 2024 Senate's votes print "2024 Regular Sessions"
  if (!new RegExp(` ${year} Regular Sessions? `).test(headText)) return fail('the vote does not name this session');
  const cal = cells.map((c) => /^Calendar Date: ([A-Z][a-z]{2}) (\d{1,2}), (\d{4})\b/.exec(c)).filter(Boolean);
  const month = cal.length === 1 ? MD_MONTHS.indexOf(cal[0]![1]) : -1;
  if (month < 0 || Number(cal[0]![3]) !== year) return fail('the vote has no calendar date in its session year');
  const date = `${year}-${String(month + 1).padStart(2, '0')}-${cal[0]![2].padStart(2, '0')}`;
  if (Number.isNaN(Date.parse(`${date}T00:00:00Z`)) || new Date(`${date}T00:00:00Z`).getUTCDate() !== Number(cal[0]![2])) return fail('the calendar date is not a real day');
  // the bills: a cell that is a bill, or a bill and its sponsor ("SB 907 - Senator Middleton")
  // the 2021 Senate's override calendar prints the sponsor without the dash: "HB 4 Delegate Atterbeary"
  const billOf = (c: string): string | null => { const b = /^([HS][BJ]) 0*([1-9]\d{0,3})(?: - .+| (?:Delegates?|Senators?|Del\.|Sen\.) .+)?$/.exec(c); return b ? `${b[1]} ${Number(b[2])}` : null; };
  const bills = cells.map(billOf).filter((b): b is string => b !== null);
  if (!bills.includes(`${r.billType} ${r.billNum}`)) return fail('the vote does not name the bill');
  // the previous session's vetoed bills: "SPECIAL ORDER CALENDAR - 2020 VETOED HOUSE BILL". Such a file must be cited
  // with the bill's year, and a bill's year only on such a file.
  const vetoed = [...headText.matchAll(/ (20\d{2}) VETOED (HOUSE|SENATE) BILLS? /gi)];
  if (vetoed.length > 1) return fail('the vote names more than one session\'s vetoed bills');
  if (r.billYear === undefined ? vetoed.length : !vetoed.length || Number(vetoed[0][1]) !== r.billYear || vetoed[0][2].toUpperCase() !== (r.billType[0] === 'H' ? 'HOUSE' : 'SENATE'))
    return fail(r.billYear === undefined ? 'the vote is on a vetoed bill of another session: cite it with the bill\'s year' : 'the vote does not print this bill\'s session as vetoed');
  const bill = mdBillName(r);
  // the tally, and the question on the rows above it (a long question runs onto a second row)
  const tallyAt = rows.findIndex((row) => MD_TALLY.test(row.join(' ')));
  if (tallyAt < 0 || tallyAt >= first || rows.findIndex((row, i) => i > tallyAt && MD_TALLY.test(row.join(' '))) >= 0) return fail('the vote prints no tally, or more than one');
  const tally = MD_TALLY.exec(rows[tallyAt].join(' '))!.slice(1).map(Number);
  const said = (row: string[]): string => squash(row.filter((c) => !/^\(.*\)$/.test(c)).join(' '));
  let question = '';
  const above = rows.slice(0, tallyAt);
  for (const n of [1, 2]) {
    const q = squash(above.slice(-n).map(said).join(' '));
    if (q && mdQuestionIsOnTheBill(q)) { question = q; break; }
  }
  if (!question) {
    // a consent calendar prints no question: its calendar line ("Third Reading (HB) Calendar No.7", "Consent Calendar
    // No. 9") above its list of bills
    const last = above[above.length - 1] ?? [];
    const joined = squash(above.map((row) => row.join(' ')).join(' '));
    if (last.length && last.every((c) => billOf(c) !== null) && /\bThird Reading \((?:HB|SB)\) Calendar No\.\s*\d+ Consent Calendar No\.\s*\d+\b/.test(joined)) question = 'Third Reading Consent Calendar';
    else return fail(`the question is not a vote on the bill: ${said(above[above.length - 1] ?? [])}`);
  }
  // the previous session's bill is voted on only to override its veto
  if (r.billYear !== undefined && !/notwithstanding|veto override/i.test(question)) return fail(`the question is not a veto override: ${question}`);
  // the groups
  const labels = Object.fromEntries(MD_VOTES.map((v) => [v, [] as string[]])) as Record<MdVote, string[]>;
  let g = -1;
  const counts: number[] = [];
  for (const row of rows.slice(first)) {
    const joined = row.join(' ');
    // a copy's stamp: "- COPY -" over the page, "(COPY)" under the last list (2018 Senate 1326)
    if (/^(?:- COPY -|\(COPY\))$/.test(joined)) continue;
    // the footer ends the lists: "* Indicates Vote Change", "(COPY- * indicates vote change)", "COPY - * Indicates Vote Change" (2019 House 758)
    if (/^\(?(?:COPY ?- )?\* ?Indicates Vote Change\)?$/i.test(joined)) break;
    const h = MD_HEADING[g + 1] ? MD_HEADING[g + 1][0].exec(joined) : null;
    if (h) { g++; counts.push(Number(h[1])); continue; }
    if (g < 0) return fail('names before the first heading');
    for (const c of row) {
      if (!MD_LABEL.test(c) && !MD_OFFICE.test(c)) return fail(`a cell the reader cannot read: ${c}`);
      labels[MD_VOTES[g]].push(c.replace(/\*$/, ''));
    }
  }
  if (g !== MD_VOTES.length - 1) return fail('the vote does not print the five headings in order');
  for (const [i, v] of MD_VOTES.entries()) {
    if (labels[v].length !== counts[i]) return fail(`the ${v} group lists ${labels[v].length} names and prints ${counts[i]}`);
    if (counts[i] !== tally[i]) return fail(`the ${v} heading prints ${counts[i]} and the tally ${tally[i]}`);
  }
  const all = MD_VOTES.flatMap((v) => labels[v]);
  if (all.length > MD_SIZE[r.chamber]) return fail('more members than the chamber has');
  if (new Set(all.map(fold)).size !== all.length) return fail('a label is printed twice');
  // the members: every committee page of the chamber, for this session
  const members = new Map<string, { sur: string; given: string[]; full: string }>();
  for (const [i, html] of bodies.slice(1).entries()) {
    let list: Map<string, string> | null;
    try { list = mdCommitteeMembers(html, r.session); } catch (e) { return fail(String(e instanceof Error ? e.message : e)); }
    if (!list) return fail(`the committee page ${committees[i]} is not this session's, or lists no members`);
    for (const [key, listed] of list) {
      const m = mdMember(listed);
      if (!m) return fail(`a member the reader cannot read: ${listed}`);
      if (members.has(key) && members.get(key)!.full !== m.full) return fail(`the key ${key} names both ${members.get(key)!.full} and ${m.full}`);
      members.set(key, m);
    }
  }
  // each label: the members whose surname it prints and whose given names its initials start
  const fits = new Map<string, string[]>();
  for (const label of all) {
    const l = MD_OFFICE.test(label) ? null : MD_LABEL.exec(label);
    if (!l) { fits.set(label, []); continue; }
    const sur = fold(l[1]);
    const initials = (l[2] ?? '').replace(/\s/g, '').split('.').filter(Boolean).map((x) => fold(x));
    fits.set(label, [...members].filter(([, m]) => m.sur === sur && initials.every((x, k) => m.given[k]?.[0] === x)).map(([key]) => key));
  }
  // a member another label already names is not this label's (two Davises: "Davis, D.E." and "Davis")
  const taken = new Map<string, string>();
  for (let changed = true; changed;) {
    changed = false;
    for (const [label, keys] of fits) {
      if (taken.has(label)) continue;
      const left = keys.filter((k) => ![...taken].some(([other, key]) => other !== label && key === k));
      if (left.length === 1) { taken.set(label, left[0]); changed = true; }
    }
  }
  if (new Set(taken.values()).size !== taken.size) return fail('two labels name one member');
  const groups = Object.fromEntries(MD_VOTES.map((v) => [v, labels[v].map((l) => (taken.has(l) ? members.get(taken.get(l)!)!.full : l))])) as Record<MdVote, string[]>;
  return { state: 'MD', stateName: 'Maryland', chamber: r.chamber, session: r.session, seq: r.seq, bill, question, date, groups };
}

const MD_SAID: Record<MdVote, string> = { Yea: 'voted Yea', Nay: 'voted Nay', 'Not voting': 'did not vote', Excused: 'was excused from voting', Absent: 'was absent' };

export function renderMarylandVote(v: MdVoteRecord): string {
  return [
    `Maryland ${v.chamber} vote ${v.seq} (${v.session}), ${v.bill}, ${v.date}.`,
    `Question: ${v.question}`,
    MD_VOTES.map((k) => `${k} ${v.groups[k].length}`).join('; ') + '.',
    ...MD_VOTES.map((k) => `${k} (${v.groups[k].length}): ${v.groups[k].join('; ')}`.trim()),
  ].join('\n');
}

const MD_RENDER_HEAD = /^Maryland (House|Senate) vote (\d+) \((20\d{2}RS)\), ([HS][BJ] \d+(?: of 20\d{2})?), (\d{4}-\d{2}-\d{2})\.$/;

function parseMarylandRender(text: string, url: string): MdVoteRecord | null {
  const r = parseMarylandVoteUrl(url);
  const rows = text.split('\n');
  const h = MD_RENDER_HEAD.exec(rows[0] ?? '');
  const q = /^Question: (.+)$/.exec(rows[1] ?? '');
  if (!r || !h || !q || rows.length !== 3 + MD_VOTES.length) return null;
  if (h[1] !== r.chamber || Number(h[2]) !== r.seq || h[3] !== r.session || h[4] !== mdBillName(r)) return null;
  const groups = {} as Record<MdVote, string[]>;
  for (const [i, v] of MD_VOTES.entries()) {
    const m = new RegExp(`^${v} \\((\\d+)\\):(.*)$`).exec(rows[3 + i]);
    if (!m) return null;
    groups[v] = m[2].split(';').map((s) => s.trim()).filter(Boolean);
    if (groups[v].length !== Number(m[1])) return null;
  }
  if (rows[2] !== MD_VOTES.map((v) => `${v} ${groups[v].length}`).join('; ') + '.') return null;
  return { state: 'MD', stateName: 'Maryland', chamber: r.chamber, session: r.session, seq: r.seq, bill: h[4], date: h[5], question: q[1], groups };
}

const MD_LINE = /^Maryland (House|Senate) vote (\d+) \((20\d{2}RS)\), ([HS][BJ] \d+(?: of 20\d{2})?) - (.+) \((\d{4}-\d{2}-\d{2})\): (.+?) (voted Yea|voted Nay|did not vote|was excused from voting|was absent)\.$/;

export function formatMarylandVoteLine(l: MdVoteLine): string {
  return `Maryland ${l.chamber} vote ${l.seq} (${l.session}), ${l.bill} - ${l.question} (${l.date}): ${l.name} ${MD_SAID[l.vote]}.`;
}

function parseMarylandLine(text: string): MdVoteLine | null {
  const m = MD_LINE.exec(text.trim());
  const vote = m ? MD_VOTES.find((v) => MD_SAID[v] === m[8]) : undefined;
  if (!m || !vote) return null;
  return { state: 'MD', stateName: 'Maryland', chamber: m[1] as Chamber, seq: Number(m[2]), session: m[3], bill: m[4], question: m[5], date: m[6], name: m[7].trim(), vote };
}

function verifyMarylandLine(line: string, url: string, text: string, lastName: string, fullName: string): SnippetVerdict {
  const l = parseMarylandLine(line);
  const r = parseMarylandRender(text, url);
  if (!l || !r) return { verdict: 'snippet_not_found' };
  if (l.seq !== r.seq || l.chamber !== r.chamber || l.session !== r.session || l.bill !== r.bill || l.date !== r.date) return { verdict: 'snippet_not_found' };
  if (normalizeText(l.question) !== normalizeText(r.question)) return { verdict: 'snippet_not_found' };
  if (!r.groups[l.vote].some((n) => sameLabel(n, l.name))) return { verdict: 'snippet_not_found' };
  const fits = MD_VOTES.flatMap((v) => r.groups[v]).filter((n) => fullNameLabelFits(n, lastName, fullName));
  if (fits.length !== 1 || !sameLabel(fits[0], l.name)) return { verdict: 'name_not_present' };
  return { verdict: 'verified', matchOffset: 0 };
}

function marylandLinesFor(url: string, text: string, lastName: string, fullName: string): string[] {
  const r = parseMarylandRender(text, url);
  if (!r) return [];
  const out: string[] = [];
  for (const vote of MD_VOTES) {
    for (const name of r.groups[vote]) {
      if (fullNameLabelFits(name, lastName, fullName)) out.push(formatMarylandVoteLine({ ...r, name, vote }));
    }
  }
  return out.length === 1 ? out : [];
}

/** The vote an address names, read from its documents (stateRollCallDocs order). Null when any check fails. */
export function readMarylandVote(bodies: string[], url: string): MdVoteRecord | null {
  const v = explainMarylandVote(bodies, url);
  return 'refused' in v ? null : v;
}

/** As readMarylandVote, with the reason a vote is refused: for the fetch tool's report and the tests. */
export function explainMarylandVote(bodies: string[], url: string): MdVoteRecord | { refused: string } {
  const r = parseMarylandVoteUrl(url);
  if (!r) return { refused: 'not a Maryland vote address' };
  try { return readMaryland(bodies, r); } catch (e) { return { refused: `the reader failed: ${e instanceof Error ? e.message : e}` }; }
}

// ── Kansas: one page per vote, in two layouts; each member is linked to the session's own member id ───────────────────
// www.kslegislature.gov has no robots.txt (404, 2026-11-18). Two layouts, by biennium:
//
// 2017-2022 and the 2020 and 2021 special sessions are an archive, li_<YYYY>/b<biennium>/measures/vote_view/je_<stamp>/
// (li_2018/b2017_18, li_2020/b2019_20, li_2022/b2021_22, li_2020s/b2020s, li_2021s/b2021s). The Open States rows carry
// the old host's address, www.kslegislature.org/li/b2017_18/measures/vote_view/je_.../, which now redirects to a 404:
// the same vote is the archive address (convert.py ks_vote_page). The page prints the bill (<h2><a href=".../measures/
// HB2476/">HB 2476</a></h2>), one heading "House - Final Action - Passed as amended; - 02/15/2018" (chamber, question,
// day), then five headings, each followed by its members: "Yea - (107):", "Nay - (15):", "Present but not Voting -
// (0):" (the Senate: "Present and Passing"), "Absent and Not Voting - (2):", "Not Voting - (0):". Each member is a link
// to the member's page in that session, /li_2018/b2017_18/members/rep_alcala_john_1/, whose text is the surname
// ("Alcala, "; "L. Ruiz, " when two share it).
//
// 2023-2024 and 2025-2026 are the current site, b<biennium>/vote/?apn=b<biennium>/year<1|2>/<house|senate>/
// legislative_days/day<NNN>_<YYYYMMDD>/vote_records/<file>.odt (an HTML page, despite the .odt). It prints "House Roll
// Call", the question ("Final Action - Passed as amended;"), the day, the bill (twice: the crumbs and the hero), the
// tally twice ("Yea 74, Nay 49, Absent 2, Not Voting 0, Present 0" and one chip per group), and one list item per
// member, data-status yea | nay | present | absent, linked to /b2025_26/legislators/rep_anderson_avery_1/ with the text
// "Rep. Anderson". The 2023-24 rows of the dump carry the old je_ address, which leads nowhere: those votes are read
// from each bill's history (fetch-legislature-rollcalls.ts) and the dump's copies are not placed.
//
// Neither layout prints a member's given name. The member id does: rep_<surname words>_<given words>_<n>. A member is
// rendered as the given words that follow the surname words the page prints, then the surname as printed: "Blake
// Carpenter" (rep_carpenter_blake_1, "B. Carpenter"), "Wanda Brownlee Paige" (rep_paige_wanda_1), "Jo Ella Hoye"
// (rep_hoye_jo_ella_1), "Kristen O'Shea" (sen_oshea_kristen_1). A member whose id does not open with a surname word
// the page prints, or leaves no given word, or whose printed initial is not the given name's, is kept as printed and
// gives no line (a bare surname fits no one).
//
//   Kansas House vote je_20180215112754_700284 (2017-2018), HB 2476, 2018-02-15.
//   Question: Final Action - Passed as amended
//   Yea 107; Nay 15; Present 0; Absent 2; Not voting 0.
//   Yea (107): John Alcala; …
//   Kansas House vote je_20180215112754_700284 (2017-2018), HB 2476 - Final Action - Passed as amended (2018-02-15): John Alcala voted Yea.
//
// A vote is read only when the question is a vote on the bill (ksQuestionIsOnTheBill), each group lists the count its
// heading prints (and on the current site, the count both tallies print), and the page's chamber, day and session are
// the address's.

export const KS_VOTES = ['Yea', 'Nay', 'Present', 'Absent', 'Not voting'] as const;
export type KsVote = (typeof KS_VOTES)[number];
const KS_SITE = 'https://www.kslegislature.gov/';
/** No robots.txt (404, 2026-11-18), so no Crawl-delay is stated: one request a second is ours. */
const KS_GAP_MS = 1_000;
const KS_SIZE: Record<Chamber, number> = { House: 125, Senate: 40 };
/** The archive's sessions: path prefix -> the Open States session. */
export const KS_ARCHIVE: Readonly<Record<string, string>> = {
  'li_2018/b2017_18': '2017-2018', 'li_2020/b2019_20': '2019-2020', 'li_2020s/b2020s': '2020S1', 'li_2022/b2021_22': '2021-2022', 'li_2021s/b2021s': '2021S1',
};
/** The current site's sessions: biennium -> the Open States session. */
export const KS_CURRENT: Readonly<Record<string, string>> = { b2023_24: '2023-2024', b2025_26: '2025-2026' };
const KS_ARCHIVE_URL = /^https:\/\/www\.kslegislature\.gov\/(li_20\d{2}s?\/b20\d{2}(?:_\d{2}|s))\/measures\/vote_view\/(je_(\d{4})(\d{2})(\d{2})\d{6}_\d+)\/$/;
const KS_CURRENT_URL = /^https:\/\/www\.kslegislature\.gov\/(b20\d{2}_\d{2})\/vote\/\?apn=\1\/year[12]\/(house|senate)\/legislative_days\/day\d{3}_(\d{4})(\d{2})(\d{2})\/vote_records\/([A-Za-z0-9_]+)\.odt$/;
const KS_MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

/**
 * Is a Kansas question a vote on the bill? Final action (emergency, on a substitute, any outcome), a conference
 * committee report (adopted or not), concurring in the other chamber's amendments (Kansas then sends the bill on; no
 * other vote follows, as in Utah), a veto override (line item too), and the consent calendar. A Committee of the Whole
 * vote (an amendment, a motion, its own recommendation) and every other motion is not (runner, 2026-11-16).
 */
export function ksQuestionIsOnTheBill(q: string): boolean {
  const s = squash(q).replace(/[;.\s]+$/, '');
  return /^(?:Emergency )?Final Action\b|^Conference Committee Report (?:was )?(?:not )?adopted\b|^Adopt CCR$|^Concurred with amendments\b|^Concur$|^Motion to override (?:line item )?veto (?:prevailed|failed)\b|^Override$|^Consent Calendar Passed$/i.test(s);
}

export interface KsVoteRef { state: 'KS'; stateName: 'Kansas'; session: string; voteId: string; chamber: Chamber | null; day: string; layout: 'archive' | 'current'; prefix: string }
export interface KsVoteRecord { state: 'KS'; stateName: 'Kansas'; chamber: Chamber; session: string; voteId: string; bill: string; question: string; date: string; groups: Record<KsVote, string[]> }
export interface KsVoteLine extends Omit<KsVoteRecord, 'groups'> { name: string; vote: KsVote }

export function parseKansasVoteUrl(url: string): KsVoteRef | null {
  const u = url.trim();
  const a = KS_ARCHIVE_URL.exec(u);
  if (a) {
    const session = KS_ARCHIVE[a[1]];
    return session ? { state: 'KS', stateName: 'Kansas', session, voteId: a[2], chamber: null, day: `${a[3]}-${a[4]}-${a[5]}`, layout: 'archive', prefix: a[1] } : null;
  }
  const c = KS_CURRENT_URL.exec(u);
  if (c) {
    const session = KS_CURRENT[c[1]];
    return session ? { state: 'KS', stateName: 'Kansas', session, voteId: c[6], chamber: c[2] === 'house' ? 'House' : 'Senate', day: `${c[3]}-${c[4]}-${c[5]}`, layout: 'current', prefix: c[1] } : null;
  }
  return null;
}

/** "HB2476" or "HB 2476" -> "HB 2476"; null for anything else. */
function ksBill(s: string): string | null {
  const m = /^([HS](?:B|CR|R|JR))\s*0*([1-9]\d{0,4})$/i.exec(squash(s));
  return m ? `${m[1].toUpperCase()} ${Number(m[2])}` : null;
}

const ksWords = (s: string): string[] => fold(s.replace(/['’]/g, '')).split(' ').filter(Boolean);

/**
 * A member as rendered: the given words of the member id after the surname words the page prints, then the surname as
 * printed. The label as printed (no line) when the id does not fit the label. Throws on an id that is not a member id.
 */
export function ksMemberName(label: string, id: string, chamber: Chamber): string {
  const m = /^(rep|sen)_([a-z]+(?:_[a-z]+)*)_(\d+)$/.exec(id);
  if (!m) throw new Error(`not a member id: ${id}`);
  if ((m[1] === 'rep') !== (chamber === 'House')) throw new Error(`a ${m[1] === 'rep' ? 'House' : 'Senate'} member on a ${chamber} vote: ${id}`);
  const printed = squash(label.replace(/^(?:Rep|Sen)\.\s+/, '').replace(/,\s*$/, ''));
  // an initial tells two members of one family name apart, before it ("A. Smith") or, in 2019-2020, after ("Carpenter, W.")
  const before = /^([A-Z])\.\s+(.+)$/.exec(printed);
  const after = /^(.+?),\s*([A-Z])\.$/.exec(printed);
  const init = before ? [before[0], before[1], before[2]] : after ? [after[0], after[2], after[1]] : null;
  const surname = init ? init[2] : printed;
  const surWords = new Set(ksWords(surname).flatMap((w) => [w, w.replace(/-/g, '')]).concat([fold(surname).replace(/[\s'’-]/g, '')]));
  const tokens = m[2].split('_');
  let k = 0;
  while (k < tokens.length && surWords.has(tokens[k])) k++;
  // A member who changed her family name keeps the id she was first seated under: 2023-2024 prints "Blew" for
  // rep_arnberger_tory_1 and "Lee" for rep_leehahn_tatum_1. When the id is one family word and one given word, the
  // given word is the id's second, and the family name is the one the page prints ("Tory Blew").
  if (!k && tokens.length === 2 && !init && /^[A-Za-z][A-Za-z'’-]*$/.test(surname)) return `${tokens[1][0].toUpperCase()}${tokens[1].slice(1)} ${surname}`;
  const given = tokens.slice(k);
  if (!k || !given.length) return printed;
  if (init && given[0][0] !== init[1].toLowerCase()) return printed;
  return `${given.map((g) => g[0].toUpperCase() + g.slice(1)).join(' ')} ${surname}`;
}

/** The vote, or why it was refused (the first check that failed). */
function readKansas(bodies: string[], r: KsVoteRef): KsVoteRecord | { refused: string } {
  const fail = (refused: string): { refused: string } => ({ refused });
  if (bodies.length !== 1) return fail('not one vote page');
  const html = bodies[0];
  const labels = Object.fromEntries(KS_VOTES.map((v) => [v, [] as [string, string][]])) as Record<KsVote, [string, string][]>;
  let chamber: Chamber;
  let bill: string;
  let question: string;
  let date: string;
  const memberPath = r.layout === 'archive' ? `/${r.prefix}/members/` : `/${r.prefix}/legislators/`;
  const memberLink = new RegExp(`^${memberPath.replace(/\//g, '\\/')}((?:rep|sen)_[a-z_]+_\\d+)\\/$`);
  if (r.layout === 'archive') {
    // the bill is a link to its page (<a href="/li_2018/b2017_18/measures/HB2476/">HB 2476</a>), or, in the special
    // sessions, plain text (<h2>HB2016</h2>)
    const bills = [...html.matchAll(/<h2>\s*(?:<a href="\/([^"]+)\/measures\/([A-Za-z]+\d+)\/">[^<]*<\/a>|([A-Z]+\d+))\s*<\/h2>/g)];
    if (bills.length !== 1 || (bills[0][1] !== undefined && bills[0][1] !== r.prefix)) return fail('the page does not name one bill of this session');
    const b = ksBill(bills[0][2] ?? bills[0][3]);
    if (!b) return fail(`a bill the reader cannot read: ${bills[0][2] ?? bills[0][3]}`);
    bill = b;
    const h3 = [...html.matchAll(/<h3>([\s\S]*?)<\/h3>/g)].map((x) => htmlText(x[1]));
    const head = h3.map((x) => /^(House|Senate) - (.+?) - (\d{2})\/(\d{2})\/(\d{4})$/.exec(x)).filter(Boolean);
    if (head.length !== 1) return fail('the page has no one heading of chamber, question and day');
    chamber = head[0]![1] as Chamber;
    question = squash(head[0]![2]).replace(/;$/, '');
    date = `${head[0]![5]}-${head[0]![3]}-${head[0]![4]}`;
    if (date !== r.day) return fail(`the page's day ${date} is not the address's ${r.day}`);
    const headings: [RegExp, KsVote][] = [
      [/^Yea - \((\d+)\):$/, 'Yea'], [/^Nay - \((\d+)\):$/, 'Nay'], [/^Present (?:and Passing|but not Voting) - \((\d+)\):$/, 'Present'],
      [/^Absent and Not Voting - \((\d+)\):$/, 'Absent'], [/^Not Voting - \((\d+)\):$/, 'Not voting'],
    ];
    const parts = html.split(/<h3>/);
    let g = 0;
    for (const part of parts.slice(1)) {
      const end = part.indexOf('</h3>');
      const heading = htmlText(part.slice(0, end));
      if (!/ - \(\d+\):$/.test(heading)) continue;
      if (g >= headings.length) return fail(`a sixth group: ${heading}`);
      const h = headings[g][0].exec(heading);
      if (!h) return fail(`the groups are not in the order the reader knows: ${heading}`);
      // the group's members run to the next heading or the end of the content
      const body = part.slice(end + 5).split(/<\/?div\b|<!--/)[0];
      const links = [...body.matchAll(/<a href="([^"]*)">([^<]*)<\/a>/g)];
      if (body.replace(/<a href="[^"]*">[^<]*<\/a>/g, '').trim()) return fail(`the ${headings[g][1]} group holds something that is not a member`);
      for (const l of links) {
        const id = memberLink.exec(l[1]);
        if (!id) return fail(`a member link the reader cannot read: ${l[1]}`);
        labels[headings[g][1]].push([htmlText(l[2]), id[1]]);
      }
      if (labels[headings[g][1]].length !== Number(h[1])) return fail(`the ${headings[g][1]} group lists ${labels[headings[g][1]].length} members and prints ${h[1]}`);
      g++;
    }
    if (g !== headings.length) return fail('the page does not print the five groups');
  } else {
    const kicker = [...html.matchAll(/<span class="list-kicker">([^<]*)<\/span>/g)].map((x) => squash(x[1]));
    if (kicker.length !== 1 || kicker[0] !== `${r.chamber} Roll Call`) return fail('the page does not name the address\'s chamber');
    chamber = r.chamber!;
    const sub = [...html.matchAll(/<p class="list-hero-sub">([^<]*)<\/p>/g)];
    if (sub.length !== 1) return fail('the page prints no one question');
    question = htmlText(sub[0][1]).replace(/;$/, '');
    const crumbs = [...html.matchAll(/<li class="breadcrumbs-item"><a href="\/([^/"]+)\/bills\/([A-Za-z]+\d+)\/">([^<]*)<\/a>/g)];
    const hero = [...html.matchAll(/gavel<\/span>\s*<a href="\/([^/"]+)\/bills\/([A-Za-z]+\d+)\/">([^<]*)<\/a>/g)];
    if (crumbs.length !== 1 || hero.length !== 1 || crumbs[0][1] !== r.prefix || hero[0][1] !== r.prefix || crumbs[0][2] !== hero[0][2]) return fail('the page does not name one bill of this session');
    const b = ksBill(crumbs[0][2]);
    if (!b || ksBill(crumbs[0][3]) !== b || ksBill(hero[0][3]) !== b) return fail(`a bill the reader cannot read: ${crumbs[0][2]}`);
    bill = b;
    const days = [...html.matchAll(/event<\/span>\s*([A-Z][a-z]+) (\d{1,2}), (\d{4})\s*<\/span>/g)];
    const month = days.length === 1 ? KS_MONTHS.indexOf(days[0][1]) : -1;
    if (month < 0) return fail('the page prints no one day');
    date = `${days[0][3]}-${String(month + 1).padStart(2, '0')}-${days[0][2].padStart(2, '0')}`;
    // a late sitting runs past midnight: 2026 Senate vote_407_HB2535, legislative day 54 (2026-04-10), voted 2026-04-11
    const gap = (Date.parse(`${date}T00:00:00Z`) - Date.parse(`${r.day}T00:00:00Z`)) / 86_400_000;
    if (gap !== 0 && gap !== 1) return fail(`the page's day ${date} is not the address's legislative day ${r.day}`);
    const bar = [...html.matchAll(/aria-label="Yea (\d+), Nay (\d+), Absent (\d+), Not Voting (\d+), Present (\d+)"/g)];
    if (bar.length !== 1) return fail('the page prints no tally');
    const tally: Record<KsVote, number> = { Yea: Number(bar[0][1]), Nay: Number(bar[0][2]), Absent: Number(bar[0][3]), 'Not voting': Number(bar[0][4]), Present: Number(bar[0][5]) };
    const STATUS: Record<string, KsVote> = { yea: 'Yea', nay: 'Nay', present: 'Present', absent: 'Absent', not_voting: 'Not voting', 'not-voting': 'Not voting', notvoting: 'Not voting' };
    const chips = new Map<KsVote, number>();
    for (const c of html.matchAll(/class="tally-chip tally-([a-z_-]+)[^"]*" data-vote-filter="[^"]*">([^<]*)<\/button>/g)) {
      if (c[1] === 'all') continue;
      const v = STATUS[c[1]];
      const n = /(\d+)\s*$/.exec(c[2]);
      if (!v || !n || chips.has(v)) return fail(`a tally chip the reader cannot read: ${c[1]}`);
      chips.set(v, Number(n[1]));
    }
    for (const v of KS_VOTES) if ((chips.get(v) ?? 0) !== tally[v]) return fail(`the two tallies disagree on ${v}`);
    const grid = html.indexOf('id="vote-list"');
    const gridEnd = html.indexOf('</ul>', grid);
    if (grid < 0 || gridEnd < 0) return fail('the page has no member list');
    const items = [...html.slice(grid, gridEnd).matchAll(/<li class="vote-member[^"]*"\s+data-status="([^"]*)"[\s\S]*?<span class="vote-member-name"><a href="([^"]*)">([^<]*)<\/a><\/span>[\s\S]*?<\/li>/g)];
    if ((html.slice(grid, gridEnd).match(/<li\b/g) ?? []).length !== items.length) return fail('a member item the reader cannot read');
    for (const it of items) {
      const v = STATUS[it[1]];
      const id = memberLink.exec(it[2]);
      if (!v || !id) return fail(`a member the reader cannot read: ${it[1]} ${it[2]}`);
      labels[v].push([htmlText(it[3]), id[1]]);
    }
    for (const v of KS_VOTES) if (labels[v].length !== tally[v]) return fail(`the ${v} group lists ${labels[v].length} members and prints ${tally[v]}`);
  }
  if (!ksQuestionIsOnTheBill(question)) return fail(`the question is not a vote on the bill: ${question}`);
  const all = KS_VOTES.flatMap((v) => labels[v]);
  if (all.length > KS_SIZE[chamber]) return fail('more members than the chamber has');
  if (new Set(all.map(([, id]) => id)).size !== all.length) return fail('a member is listed twice');
  let groups: Record<KsVote, string[]>;
  try {
    groups = Object.fromEntries(KS_VOTES.map((v) => [v, labels[v].map(([l, id]) => ksMemberName(l, id, chamber))])) as Record<KsVote, string[]>;
  } catch (e) { return fail(e instanceof Error ? e.message : String(e)); }
  const names = KS_VOTES.flatMap((v) => groups[v]).map(fold);
  if (new Set(names).size !== names.length) return fail('two members render as one name');
  return { state: 'KS', stateName: 'Kansas', chamber, session: r.session, voteId: r.voteId, bill, question, date, groups };
}

const KS_SAID: Record<KsVote, string> = { Yea: 'voted Yea', Nay: 'voted Nay', Present: 'was present and did not vote', Absent: 'was absent', 'Not voting': 'did not vote' };

export function renderKansasVote(v: KsVoteRecord): string {
  return [
    `Kansas ${v.chamber} vote ${v.voteId} (${v.session}), ${v.bill}, ${v.date}.`,
    `Question: ${v.question}`,
    KS_VOTES.map((k) => `${k} ${v.groups[k].length}`).join('; ') + '.',
    ...KS_VOTES.map((k) => `${k} (${v.groups[k].length}): ${v.groups[k].join('; ')}`.trim()),
  ].join('\n');
}

const KS_RENDER_HEAD = /^Kansas (House|Senate) vote ([A-Za-z0-9_]+) \((20\d{2}(?:-20\d{2}|S1))\), ([HS](?:B|CR|R|JR) \d+), (\d{4}-\d{2}-\d{2})\.$/;

function parseKansasRender(text: string, url: string): KsVoteRecord | null {
  const r = parseKansasVoteUrl(url);
  const rows = text.split('\n');
  const h = KS_RENDER_HEAD.exec(rows[0] ?? '');
  const q = /^Question: (.+)$/.exec(rows[1] ?? '');
  if (!r || !h || !q || rows.length !== 3 + KS_VOTES.length) return null;
  if (h[2] !== r.voteId || h[3] !== r.session || (r.chamber && h[1] !== r.chamber)) return null;
  const groups = {} as Record<KsVote, string[]>;
  for (const [i, v] of KS_VOTES.entries()) {
    const m = new RegExp(`^${v} \\((\\d+)\\):(.*)$`).exec(rows[3 + i]);
    if (!m) return null;
    groups[v] = m[2].split(';').map((s) => s.trim()).filter(Boolean);
    if (groups[v].length !== Number(m[1])) return null;
  }
  if (rows[2] !== KS_VOTES.map((v) => `${v} ${groups[v].length}`).join('; ') + '.') return null;
  return { state: 'KS', stateName: 'Kansas', chamber: h[1] as Chamber, session: r.session, voteId: r.voteId, bill: h[4], date: h[5], question: q[1], groups };
}

const KS_LINE = /^Kansas (House|Senate) vote ([A-Za-z0-9_]+) \((20\d{2}(?:-20\d{2}|S1))\), ([HS](?:B|CR|R|JR) \d+) - (.+) \((\d{4}-\d{2}-\d{2})\): (.+?) (voted Yea|voted Nay|was present and did not vote|was absent|did not vote)\.$/;

export function formatKansasVoteLine(l: KsVoteLine): string {
  return `Kansas ${l.chamber} vote ${l.voteId} (${l.session}), ${l.bill} - ${l.question} (${l.date}): ${l.name} ${KS_SAID[l.vote]}.`;
}

function parseKansasLine(text: string): KsVoteLine | null {
  const m = KS_LINE.exec(text.trim());
  const vote = m ? KS_VOTES.find((v) => KS_SAID[v] === m[8]) : undefined;
  if (!m || !vote) return null;
  return { state: 'KS', stateName: 'Kansas', chamber: m[1] as Chamber, voteId: m[2], session: m[3], bill: m[4], question: m[5], date: m[6], name: m[7].trim(), vote };
}

function verifyKansasLine(line: string, url: string, text: string, lastName: string, fullName: string): SnippetVerdict {
  const l = parseKansasLine(line);
  const r = parseKansasRender(text, url);
  if (!l || !r) return { verdict: 'snippet_not_found' };
  if (l.voteId !== r.voteId || l.chamber !== r.chamber || l.session !== r.session || l.bill !== r.bill || l.date !== r.date) return { verdict: 'snippet_not_found' };
  if (normalizeText(l.question) !== normalizeText(r.question)) return { verdict: 'snippet_not_found' };
  if (!r.groups[l.vote].some((n) => sameLabel(n, l.name))) return { verdict: 'snippet_not_found' };
  const fits = KS_VOTES.flatMap((v) => r.groups[v]).filter((n) => fullNameLabelFits(n, lastName, fullName));
  if (fits.length !== 1 || !sameLabel(fits[0], l.name)) return { verdict: 'name_not_present' };
  return { verdict: 'verified', matchOffset: 0 };
}

function kansasLinesFor(url: string, text: string, lastName: string, fullName: string): string[] {
  const r = parseKansasRender(text, url);
  if (!r) return [];
  const out: string[] = [];
  for (const vote of KS_VOTES) {
    for (const name of r.groups[vote]) {
      if (fullNameLabelFits(name, lastName, fullName)) out.push(formatKansasVoteLine({ ...r, name, vote }));
    }
  }
  return out.length === 1 ? out : [];
}

/** The vote an address names, read from its page. Null when any check fails. */
export function readKansasVote(bodies: string[], url: string): KsVoteRecord | null {
  const v = explainKansasVote(bodies, url);
  return 'refused' in v ? null : v;
}

/** As readKansasVote, with the reason a vote is refused: for the fetch tool's report and the tests. */
export function explainKansasVote(bodies: string[], url: string): KsVoteRecord | { refused: string } {
  const r = parseKansasVoteUrl(url);
  if (!r) return { refused: 'not a Kansas vote address' };
  try { return readKansas(bodies, r); } catch (e) { return { refused: `the reader failed: ${e instanceof Error ? e.message : e}` }; }
}

// ── Colorado: one page per vote, read with the session's member list ─────────────────────────────────────────────────
// leg.colorado.gov (robots.txt read 2026-11-18: allows /bill_votes/ and /legislators, no Crawl-delay). The Open States rows
// carry addresses on the old site (leg.colorado.gov/content/hb19-1166vote5b8aea, and 2017's committee summaries), which
// now answer 404 ("We are currently migrating legacy session data"). Every session from 2017 is on the new site: a bill's
// page, /bills/hb19-1177, lists each recorded vote with its calendar, motion and tally, linking the vote's own page,
// /bill_votes/16466. That page prints "Floor Vote", the bill ("HB19-1177"), its title, the chamber ("Senate"), one summary
// row (calendar "Third reading", motion "Bill", "03/28/2019 02:41:38 PM"), the count of each kind (Yes, No, Absent,
// Excused, and Vacant for an empty seat, printed as a row "District 57") and one row per member, printed by surname only:
// "Bacon", "Garcia Sander", "Valdez A." where two share one, "President" for the Senate's presiding officer (2019).
//
// The page names no session, so the address names the bill after a #: https://leg.colorado.gov/bill_votes/16466#HB19-1177
// (the bill's year and letter are the session: HB20B-1001 is the 2020 extraordinary session, 2020B). A bare surname fits
// no one, so the reader also reads the session's member list, /legislators?sess=2019a, which prints every member of that
// session as "Valdez, Alex" with a link to the member's page (/legislators/alex-valdez), and its leadership tiles
// ("President of the Senate", linked the same way). A printed label is rendered as the one member of the list whose family
// name it is (or, when none, the last word of whose two-word family name it is: "Kennedy" for "deGruy Kennedy, Chris") and
// whose given name starts with the initial it prints, if any; "President" and "Speaker" as the one member
// the leadership tiles title "President of the Senate" or "Speaker of the House". A label no member fits, or two fit, is
// kept as printed and gives no line (the list holds both chambers and prints no chamber of the session).
//
//   Colorado Senate vote 16461 (2019A), HB19-1177, 2019-03-28.
//   Question: Third reading - Bill
//   Yes 18; No 17; Absent 0; Excused 0.
//   Yes (18): Jeff Bridges; …
//   Colorado Senate vote 16461 (2019A), HB19-1177 - Third reading - Bill (2019-03-28): Jeff Bridges voted Yes.
//
// A vote is read only when the question is a vote on the bill (coQuestionIsOnTheBill), the page names the address's bill,
// each kind lists the count printed for it, the total is not more than the chamber's seats, and no member is listed twice.

export const CO_VOTES = ['Yes', 'No', 'Absent', 'Excused'] as const;
export type CoVote = (typeof CO_VOTES)[number];
const CO_SITE = 'https://leg.colorado.gov/';
/** robots.txt states no Crawl-delay (2026-11-18): one request a second is ours. */
const CO_GAP_MS = 1_000;
const CO_SIZE: Record<Chamber, number> = { House: 65, Senate: 35 };
const CO_URL = /^https:\/\/leg\.colorado\.gov\/bill_votes\/([1-9]\d{0,6})#((?:H|S)(?:B|R|JR|CR|JM|M|CM))(\d{2})(B?)-(\d{3,4})$/;

/**
 * Is a Colorado vote a vote on the bill? Third reading, concurring in the other chamber's amendments, the repassage that
 * follows, a conference committee report and its repassage, and a veto override. A Committee of the Whole vote (an
 * amendment, a report) and every other motion is not (runner, 2026-11-16). The question is "<calendar> - <motion>".
 */
export function coQuestionIsOnTheBill(q: string): boolean {
  const s = squash(q).toLowerCase();
  return /^third reading - (?:bill|resolution|memorial)$/.test(s)
    || /^(?:house|senate) amendments - (?:concur|repass)$/.test(s)
    || /^conference committee(?: report)? - (?:adopt(?: ccr)?|repass|adopt report)$/.test(s)
    || /^(?:veto|governor's veto|consideration of governor's veto) - (?:override|over-ride)$/.test(s);
}

/**
 * A bill as the legislature prints it on a vote page, for a session: "HB19-1177", "SB26-124", "HB20B-1013". The dump writes
 * a bill "HB 19-1177" to 2025A and "HB 1097" or "SB 2" from 2025B on. House numbers are four digits, Senate three. Null for a
 * bill whose year or letter is not the session's.
 */
export function coBillTag(session: string, bill: string): string | null {
  const s = /^20(\d{2})([AB])$/.exec(session);
  const m = /^((?:H|S)(?:B|R|JR|CR|JM|M|CM))\s*(?:(\d{2})(B?)-)?0*([1-9]\d{0,3})$/i.exec(bill.replace(/[\s.]+/g, ''));
  if (!s || !m) return null;
  if (m[2] !== undefined && (m[2] !== s[1] || (m[3] ? 'B' : 'A') !== s[2])) return null;
  const kind = m[1].toUpperCase();
  return `${kind}${s[1]}${s[2] === 'B' ? 'B' : ''}-${m[4].padStart(kind.startsWith('H') ? 4 : 3, '0')}`;
}

export interface CoVoteRef { state: 'CO'; stateName: 'Colorado'; session: string; voteId: number; bill: string }
export interface CoVoteRecord { state: 'CO'; stateName: 'Colorado'; chamber: Chamber; session: string; voteId: number; bill: string; question: string; date: string; groups: Record<CoVote, string[]> }
export interface CoVoteLine extends Omit<CoVoteRecord, 'groups'> { name: string; vote: CoVote }

export function parseColoradoVoteUrl(url: string): CoVoteRef | null {
  const m = CO_URL.exec(url.trim());
  if (!m) return null;
  return { state: 'CO', stateName: 'Colorado', session: `20${m[3]}${m[4] ? 'B' : 'A'}`, voteId: Number(m[1]), bill: `${m[2]}${m[3]}${m[4]}-${m[5]}` };
}

/** The session's member list: /legislators?sess=2019a. */
export function coMemberListUrl(session: string): string {
  return `${CO_SITE}legislators?sess=${session.toLowerCase()}`;
}

function coloradoDocs(r: CoVoteRef): string[] {
  return [`${CO_SITE}bill_votes/${r.voteId}`, coMemberListUrl(r.session)];
}

export interface CoMember { slug: string; family: string; given: string; full: string }

/** The member list's rows ("Valdez, Alex" linked /legislators/alex-valdez) and leadership tiles. Null when it reads as no list. */
export function coMembers(html: string): { members: CoMember[]; leaders: Map<string, string[]> } | null {
  const members: CoMember[] = [];
  for (const m of html.matchAll(/<th scope="row" data-label="Name"[^>]*>\s*<span>\s*<a [^>]*href="\/legislators\/([a-z0-9-]+)">([^<]*)<\/a>/g)) {
    const printed = htmlText(m[2]);
    const c = /^([^,]+),\s*(.+)$/.exec(printed);
    if (!c) return null;
    members.push({ slug: m[1], family: c[1].trim(), given: c[2].trim(), full: `${c[2].trim()} ${c[1].trim()}` });
  }
  const rows = (html.match(/data-label="Name"/g) ?? []).length;
  if (!members.length || rows !== members.length) return null;
  const leaders = new Map<string, string[]>();
  for (const t of html.matchAll(/<a href="\/legislators\/([a-z0-9-]+)">\s*<div class='leg-member-tile[\s\S]*?<p>\s*([^<]*?)\s*<\/p>\s*<p class='leg-member-name'>/g)) {
    const title = squash(t[2]);
    leaders.set(title, [...(leaders.get(title) ?? []), t[1]]);
  }
  return { members, leaders };
}

const coKey = (s: string): string => fold(s).replace(/[\s'’-]/g, '');

/** A printed label as the one member it names (full name), or the label as printed when none or several fit. */
export function coMemberName(label: string, list: { members: CoMember[]; leaders: Map<string, string[]> }): string {
  const printed = squash(label);
  const office = { President: 'President of the Senate', Speaker: 'Speaker of the House' }[printed];
  if (office) {
    const slugs = list.leaders.get(office) ?? [];
    const hit = slugs.length === 1 ? list.members.filter((m) => m.slug === slugs[0]) : [];
    return hit.length === 1 ? hit[0].full : printed;
  }
  const init = /^(.+?)\s+([A-Z])\.$/.exec(printed);
  const family = init ? init[1] : printed;
  const given = (m: CoMember): boolean => !init || fold(m.given).startsWith(init[2].toLowerCase());
  const fits = list.members.filter((m) => coKey(m.family) === coKey(family) && given(m));
  if (fits.length) return fits.length === 1 ? fits[0].full : printed;
  // the page prints the last word of a two-word family name: "Kennedy" for "deGruy Kennedy, Chris" (2019)
  const tail = list.members.filter((m) => fold(m.family).split(' ').length > 1 && fold(m.family).endsWith(` ${fold(family)}`) && given(m));
  return tail.length === 1 ? tail[0].full : printed;
}

/** The vote, or why it was refused (the first check that failed). */
function readColorado(bodies: string[], r: CoVoteRef): CoVoteRecord | { refused: string } {
  const fail = (refused: string): { refused: string } => ({ refused });
  if (bodies.length !== 2) return fail('not a vote page and a member list');
  const [html, listHtml] = bodies;
  const tag = [...html.matchAll(/<h1>\s*Floor Vote\s*<\/h1>\s*<div class='tag-heading-white'>\s*([^<]*?)\s*<\/div>/g)];
  if (tag.length !== 1) return fail('the page is not one floor vote');
  if (squash(tag[0][1]).toUpperCase() !== r.bill) return fail(`the page is for ${squash(tag[0][1])}, not ${r.bill}`);
  const ch = [...html.matchAll(/<h3><span class="icon"><i class="fa-solid fa-landmark-dome"[^>]*><\/i><\/span>\s*(House|Senate)\s*<\/h3>/g)];
  if (ch.length !== 1) return fail('the page names no one chamber');
  const chamber = ch[0][1] as Chamber;
  const cal = [...html.matchAll(/<td data-label="Calendar">\s*<span>([^<]*)<\/span>/g)];
  const mot = [...html.matchAll(/<td data-label="Motion">\s*<span>([^<]*)<\/span>/g)];
  const on = [...html.matchAll(/<td class="text-right" data-label="Voted on">\s*<span>(\d{2})\/(\d{2})\/(\d{4}) \d{2}:\d{2}:\d{2} [AP]M<\/span>/g)];
  if (cal.length !== 1 || mot.length !== 1 || on.length !== 1) return fail('the page prints no one summary row');
  const question = `${htmlText(cal[0][1])} - ${htmlText(mot[0][1])}`;
  const date = `${on[0][3]}-${on[0][1]}-${on[0][2]}`;
  if (!coQuestionIsOnTheBill(question)) return fail(`the question is not a vote on the bill: ${question}`);
  const counts = new Map<string, number>();
  for (const c of html.matchAll(/<div class="count-tag ([A-Za-z]+)">\s*(\d+)\s*<\/div>/g)) {
    if (counts.has(c[1])) return fail(`the count of ${c[1]} is printed twice`);
    counts.set(c[1], Number(c[2]));
  }
  for (const k of counts.keys()) if (!(CO_VOTES as readonly string[]).includes(k) && k !== 'Vacant') return fail(`a kind of vote the reader does not know: ${k}`);
  if (!counts.has('Yes') || !counts.has('No')) return fail('the page prints no tally');
  const heading = [...html.matchAll(/<h3 class="text-center">Votes by (House|Senate) member<\/h3>/g)];
  if (heading.length !== 1 || heading[0][1] !== chamber) return fail('the member list is not the chamber\'s');
  const table = html.slice(heading[0].index!, html.indexOf('</table>', heading[0].index!));
  const rows = [...table.matchAll(/<tr role="row">\s*<td>([^<]*)<\/td>\s*<td class="text-right">\s*<span class="icon vote-icon ([A-Za-z]+)">[\s\S]*?<span class="vote-tag ([A-Za-z]+)">\s*([A-Za-z]+)\s*<\/span>\s*<\/td>\s*<\/tr>/g)];
  if ((table.match(/<tr\b/g) ?? []).length !== rows.length) return fail('a member row the reader cannot read');
  const labels = Object.fromEntries(CO_VOTES.map((v) => [v, [] as string[]])) as Record<CoVote, string[]>;
  let vacant = 0;
  for (const row of rows) {
    const kind = row[3];
    if (row[2] !== kind || row[4] !== kind) return fail(`a member row that disagrees with itself: ${row[1]}`);
    if (kind === 'Vacant') {
      if (!/^District \d{1,2}$/.test(squash(row[1]))) return fail(`a vacant row that names no district: ${row[1]}`);
      vacant++; continue;
    }
    if (!(CO_VOTES as readonly string[]).includes(kind)) return fail(`a kind of vote the reader does not know: ${kind}`);
    labels[kind as CoVote].push(htmlText(row[1]));
  }
  if (vacant !== (counts.get('Vacant') ?? 0)) return fail(`${vacant} vacant rows and ${counts.get('Vacant') ?? 0} printed`);
  const list = coMembers(listHtml);
  if (!list) return fail('the member list did not read');
  // From 2021 the Senate page lists its presiding officer twice, by surname and again as "President", and counts one vote
  // (2026 SB 124, vote 29317: 36 rows, Yes printed 25 and listed 26, "Coleman" and "President" both Yes). The office row
  // is dropped when it is the same member, under the same vote, as a surname row; under another vote the page is refused.
  for (const office of ['President', 'Speaker']) {
    const at = CO_VOTES.filter((v) => labels[v].includes(office));
    if (!at.length) continue;
    const who = coMemberName(office, list);
    const twin = CO_VOTES.filter((v) => labels[v].some((l) => l !== office && who !== office && coMemberName(l, list) === who));
    if (!twin.length) continue;
    if (at.length !== 1 || twin.length !== 1 || at[0] !== twin[0]) return fail(`the ${office.toLowerCase()} is listed twice under different votes`);
    labels[at[0]].splice(labels[at[0]].indexOf(office), 1);
  }
  for (const v of CO_VOTES) if (labels[v].length !== (counts.get(v) ?? 0)) return fail(`the ${v} group lists ${labels[v].length} members and prints ${counts.get(v) ?? 0}`);
  const all = CO_VOTES.flatMap((v) => labels[v]);
  if (all.length + vacant > CO_SIZE[chamber]) return fail('more members than the chamber has');
  if (new Set(all.map(coKey)).size !== all.length) return fail('a member is listed twice');
  const groups = Object.fromEntries(CO_VOTES.map((v) => [v, labels[v].map((l) => coMemberName(l, list))])) as Record<CoVote, string[]>;
  const names = CO_VOTES.flatMap((v) => groups[v]).map(coKey);
  if (new Set(names).size !== names.length) return fail('two members render as one name');
  return { state: 'CO', stateName: 'Colorado', chamber, session: r.session, voteId: r.voteId, bill: r.bill, question, date, groups };
}

const CO_SAID: Record<CoVote, string> = { Yes: 'voted Yes', No: 'voted No', Absent: 'was absent', Excused: 'was excused' };

export function renderColoradoVote(v: CoVoteRecord): string {
  return [
    `Colorado ${v.chamber} vote ${v.voteId} (${v.session}), ${v.bill}, ${v.date}.`,
    `Question: ${v.question}`,
    CO_VOTES.map((k) => `${k} ${v.groups[k].length}`).join('; ') + '.',
    ...CO_VOTES.map((k) => `${k} (${v.groups[k].length}): ${v.groups[k].join('; ')}`.trim()),
  ].join('\n');
}

const CO_RENDER_HEAD = /^Colorado (House|Senate) vote (\d+) \((20\d{2}[AB])\), ([A-Z]+\d{2}B?-\d{3,4}), (\d{4}-\d{2}-\d{2})\.$/;

function parseColoradoRender(text: string, url: string): CoVoteRecord | null {
  const r = parseColoradoVoteUrl(url);
  const rows = text.split('\n');
  const h = CO_RENDER_HEAD.exec(rows[0] ?? '');
  const q = /^Question: (.+)$/.exec(rows[1] ?? '');
  if (!r || !h || !q || rows.length !== 3 + CO_VOTES.length) return null;
  if (Number(h[2]) !== r.voteId || h[3] !== r.session || h[4] !== r.bill) return null;
  const groups = {} as Record<CoVote, string[]>;
  for (const [i, v] of CO_VOTES.entries()) {
    const m = new RegExp(`^${v} \\((\\d+)\\):(.*)$`).exec(rows[3 + i]);
    if (!m) return null;
    groups[v] = m[2].split(';').map((s) => s.trim()).filter(Boolean);
    if (groups[v].length !== Number(m[1])) return null;
  }
  if (rows[2] !== CO_VOTES.map((v) => `${v} ${groups[v].length}`).join('; ') + '.') return null;
  return { state: 'CO', stateName: 'Colorado', chamber: h[1] as Chamber, session: r.session, voteId: r.voteId, bill: r.bill, date: h[5], question: q[1], groups };
}

const CO_LINE = /^Colorado (House|Senate) vote (\d+) \((20\d{2}[AB])\), ([A-Z]+\d{2}B?-\d{3,4}) - (.+) \((\d{4}-\d{2}-\d{2})\): (.+?) (voted Yes|voted No|was absent|was excused)\.$/;

export function formatColoradoVoteLine(l: CoVoteLine): string {
  return `Colorado ${l.chamber} vote ${l.voteId} (${l.session}), ${l.bill} - ${l.question} (${l.date}): ${l.name} ${CO_SAID[l.vote]}.`;
}

function parseColoradoLine(text: string): CoVoteLine | null {
  const m = CO_LINE.exec(text.trim());
  const vote = m ? CO_VOTES.find((v) => CO_SAID[v] === m[8]) : undefined;
  if (!m || !vote) return null;
  return { state: 'CO', stateName: 'Colorado', chamber: m[1] as Chamber, voteId: Number(m[2]), session: m[3], bill: m[4], question: m[5], date: m[6], name: m[7].trim(), vote };
}

function verifyColoradoLine(line: string, url: string, text: string, lastName: string, fullName: string): SnippetVerdict {
  const l = parseColoradoLine(line);
  const r = parseColoradoRender(text, url);
  if (!l || !r) return { verdict: 'snippet_not_found' };
  if (l.voteId !== r.voteId || l.chamber !== r.chamber || l.session !== r.session || l.bill !== r.bill || l.date !== r.date) return { verdict: 'snippet_not_found' };
  if (normalizeText(l.question) !== normalizeText(r.question)) return { verdict: 'snippet_not_found' };
  if (!r.groups[l.vote].some((n) => sameLabel(n, l.name))) return { verdict: 'snippet_not_found' };
  const fits = CO_VOTES.flatMap((v) => r.groups[v]).filter((n) => fullNameLabelFits(n, lastName, fullName));
  if (fits.length !== 1 || !sameLabel(fits[0], l.name)) return { verdict: 'name_not_present' };
  return { verdict: 'verified', matchOffset: 0 };
}

function coloradoLinesFor(url: string, text: string, lastName: string, fullName: string): string[] {
  const r = parseColoradoRender(text, url);
  if (!r) return [];
  const out: string[] = [];
  for (const vote of CO_VOTES) {
    for (const name of r.groups[vote]) {
      if (fullNameLabelFits(name, lastName, fullName)) out.push(formatColoradoVoteLine({ ...r, name, vote }));
    }
  }
  return out.length === 1 ? out : [];
}

/** The vote an address names, read from its page and the session's member list. Null when any check fails. */
export function readColoradoVote(bodies: string[], url: string): CoVoteRecord | null {
  const v = explainColoradoVote(bodies, url);
  return 'refused' in v ? null : v;
}

/** As readColoradoVote, with the reason a vote is refused: for the fetch tool's report and the tests. */
export function explainColoradoVote(bodies: string[], url: string): CoVoteRecord | { refused: string } {
  const r = parseColoradoVoteUrl(url);
  if (!r) return { refused: 'not a Colorado vote address' };
  try { return readColorado(bodies, r); } catch (e) { return { refused: `the reader failed: ${e instanceof Error ? e.message : e}` }; }
}

// ── North Dakota: the chamber's daily journal (a PDF), read with the Assembly's member list ──────────────────────────
// ndlegis.gov (robots.txt read 2026-11-19: a Drupal default that disallows /core/, /admin/, /search/ and the like, not
// /assembly/; no Crawl-delay). A bill's page, /assembly/65-2017/regular/bill-actions/ba1001.html, lists every action with
// a link into that day's journal ("Second reading, passed, yeas 91 nays 0" -> ../journals/hr-dailyjnl-35.pdf#Page797).
// From 2023 the page also prints each member's vote in a hidden panel; for 2017 to 2021 the journal is the only place
// the names are printed, and Open States holds no roll call at all for 2019 and 2021. So every year is read from the
// journal, which prints every recorded vote the same way from 2017 to 2025:
//
//   SECOND READING OF HOUSE BILL
//   HB 1017: A BILL for an Act to provide an appropriation for defraying the expenses of the
//   game and fish department.
//   ROLL CALL
//   The question being on the final passage of the amended bill, which has been read, and has
//   committee recommendation of DO PASS, the roll was called and there were 82 YEAS,
//   9 NAYS, 0 EXCUSED, 3 ABSENT AND NOT VOTING.
//   YEAS: Anderson, B.; Anderson, D.; ...; Speaker Bellew
//   NAYS: Becker, Rick C.; Brabandt; ...
//   ABSENT AND NOT VOTING: Blum; Boschee; Kreidt
//   Engrossed HB 1017 passed.
//
// From 2025 the last count reads "N ABSENT OR EXCUSED AND NOT VOTING" with a heading of that name. A group of 0 has no
// heading. Every page starts "Page 798" and a running head ("798 JOURNAL OF THE HOUSE 35th DAY", or "35th DAY
// WEDNESDAY, FEBRUARY 22, 2017 787"), which can fall inside a question; both are dropped. A member is printed by family
// name, with a given name or initial when two share it ("Johnson, D.", "Becker, Rich S."), and the Speaker with the
// office ("Speaker Bellew").
//
// One daily journal holds many votes, so the address names the vote after a #: the journal page the bill's page links,
// and the bill. https://ndlegis.gov/assembly/69-2025/regular/journals/hr-dailyjnl-34.pdf#Page820-HB1326 (2025 HB 1326
// failed on page 811 and passed on page 820 of one day's journal: the page tells them apart). The journal names no
// member in full, so the reader also reads the Assembly's member list, /assembly/69-2025/regular/members/members-by-district,
// which names every member who sat in that Assembly, with the chamber ("Representative", "Senator"). A label is the one
// member of that chamber whose name ends in the label's family name (one, two or three words: "Roers Jones") and whose
// given names hold each name or initial the label prints. When several fit, a member another label of the same vote
// fits alone is taken out ("Jones" and "Roers Jones"). A label no member fits, or more than one, is kept as printed and
// gives no line.
//
// A vote is read only when the journal is this chamber's journal of that day, of this Assembly; the roll call follows
// the bill's own heading; the question is a vote on the bill (ndQuestionIsOnTheBill); the address's page lies between
// the heading and the last name; each group lists the count the question prints for it; and the line after the last
// group names the bill and its result. Excused and absent members are one group ("Absent or excused"):
//
//   North Dakota House vote of 2017-02-22, journal page 797 (65th Legislative Assembly), HB 1017.
//   Question: Final passage of the amended bill
//   Yea 82; Nay 9; Absent or excused 3.
//   Yea (82): Bert Anderson; …
//   North Dakota House vote of 2017-02-22, journal page 797 (65th Legislative Assembly), HB 1017 - Final passage of the amended bill: Bert Anderson voted Yea.

export const ND_VOTES = ['Yea', 'Nay', 'Absent or excused'] as const;
export type NdVote = (typeof ND_VOTES)[number];
const ND_SITE = 'https://ndlegis.gov/';
/** robots.txt states no Crawl-delay (2026-11-19): one request a second is ours. */
const ND_GAP_MS = 1_000;
const ND_SIZE: Record<Chamber, number> = { House: 94, Senate: 47 };
const ND_URL = /^https:\/\/ndlegis\.gov\/assembly\/(\d{2})-(20\d{2})\/regular\/journals\/(hr|sr)-dailyjnl-(\d{2})\.pdf#Page([1-9]\d{0,4})-([HS][A-Z]{1,3})([1-9]\d{3})$/;
const ND_ORDINAL: Readonly<Record<number, string>> = { 65: 'Sixty-fifth', 66: 'Sixty-sixth', 67: 'Sixty-seventh', 68: 'Sixty-eighth', 69: 'Sixty-ninth', 70: 'Seventieth', 71: 'Seventy-first' };
const ND_HEADING: Readonly<Record<string, NdVote>> = { YEAS: 'Yea', NAYS: 'Nay', EXCUSED: 'Absent or excused', 'ABSENT AND NOT VOTING': 'Absent or excused', 'ABSENT OR EXCUSED AND NOT VOTING': 'Absent or excused' };

/**
 * Is a North Dakota journal question a vote on the bill? Final passage of a bill (amended, reengrossed, or enrolled over
 * the Governor's veto, and a bill whose divisions were voted first) and final adoption of a resolution. The adoption of
 * a division or of amendments, a motion to reconsider, and a confirmation are not (runner, 2026-11-16). The question is
 * the journal's words after "The question being", up to ", which" or ", the roll" or ". The roll".
 */
export function ndQuestionIsOnTheBill(q: string): boolean {
  return /^on the final (?:passage of the (?:amended |reengrossed |enrolled )?bill(?:, over the Governor's veto)?|adoption of the (?:amended )?resolution)$/i.test(squash(q));
}

export interface NdVoteRef { state: 'ND'; stateName: 'North Dakota'; chamber: Chamber; assembly: number; year: number; day: number; page: number; billType: string; billNum: number }
export interface NdVoteRecord { state: 'ND'; stateName: 'North Dakota'; chamber: Chamber; session: string; page: number; bill: string; question: string; date: string; groups: Record<NdVote, string[]> }
export interface NdVoteLine extends Omit<NdVoteRecord, 'groups'> { name: string; vote: NdVote }

export function parseNorthDakotaVoteUrl(url: string): NdVoteRef | null {
  const m = ND_URL.exec(url.trim());
  if (!m) return null;
  const assembly = Number(m[1]);
  const year = Number(m[2]);
  // the Assembly meets in odd years: the 65th in 2017, the 69th in 2025
  if (year !== 2017 + 2 * (assembly - 65) || !ND_ORDINAL[assembly]) return null;
  return { state: 'ND', stateName: 'North Dakota', chamber: m[3] === 'hr' ? 'House' : 'Senate', assembly, year, day: Number(m[4]), page: Number(m[5]), billType: m[6], billNum: Number(m[7]) };
}

/** The Assembly's member list: /assembly/69-2025/regular/members/members-by-district. */
export function ndMemberListUrl(assembly: number, year: number): string {
  return `${ND_SITE}assembly/${assembly}-${year}/regular/members/members-by-district`;
}

function northDakotaDocs(r: NdVoteRef): string[] {
  return [`${ND_SITE}assembly/${r.assembly}-${r.year}/regular/journals/${r.chamber === 'House' ? 'hr' : 'sr'}-dailyjnl-${String(r.day).padStart(2, '0')}.pdf`, ndMemberListUrl(r.assembly, r.year)];
}

export interface NdMember { slug: string; chamber: Chamber; name: string }

/** The member list's members (linked /biography/<slug>, "Representative" or "Senator", the name). Null when it reads as no list. */
export function ndMembers(html: string): NdMember[] | null {
  const out: NdMember[] = [];
  for (const m of html.matchAll(/<a href="\/biography\/([a-z0-9-]+)">([\s\S]*?)<\/a>/g)) {
    const ch = /member-chamber">\s*([^<]*?)\s*</.exec(m[2])?.[1];
    const name = /member-name">\s*([^<]*?)\s*</.exec(m[2])?.[1];
    if (!ch && !name) continue; // a link that is not a member tile
    if ((ch !== 'Representative' && ch !== 'Senator') || !name) return null;
    out.push({ slug: m[1], chamber: ch === 'Senator' ? 'Senate' : 'House', name: htmlText(name) });
  }
  const tiles = (html.match(/class="strong member-name"/g) ?? []).length;
  return out.length && tiles === out.length ? out : null;
}

const ndKey = (s: string): string => fold(s).replace(/[\s']/g, '');

/** The members of the chamber a label fits: family name, then each printed given name or initial. */
function ndFits(label: string, members: NdMember[]): NdMember[] {
  const m = /^([^,]+?)(?:,\s*(.+))?$/.exec(squash(label));
  if (!m) return [];
  const family = ndKey(m[1]);
  const printed = (m[2] ?? '').replace(/\./g, '. ').split(/\s+/).filter(Boolean);
  return members.filter((x) => {
    const words = dropSuffix(fold(x.name)).split(' ');
    for (let k = 1; k <= 3 && k < words.length; k++) {
      if (ndKey(words.slice(-k).join(' ')) !== family) continue;
      const given = words.slice(0, -k);
      // a whole given name must be one of theirs; then an initial beside it may be a middle name the list leaves out
      // ("Becker, Rick C." is the list's "Rick Becker", beside "Rich S. Becker"); initials alone must each start one
      const whole = printed.filter((p) => !/^[A-Z]\.$/.test(p));
      if (whole.length) return whole.every((p) => given.includes(fold(p)));
      return printed.every((p) => given.some((g) => g[0] === p[0].toLowerCase()));
    }
    return false;
  });
}

/**
 * The members whose hyphenated family name starts with the label's family name: the journal printed "Unruh" in 2019 for
 * the member the list names "Jessica Unruh-Bell". Tried only when no member fits outright.
 */
function ndFitsHyphenated(label: string, members: NdMember[]): NdMember[] {
  const m = /^([^,]+?)(?:,\s*(.+))?$/.exec(squash(label));
  if (!m || m[2]) return [];
  const family = ndKey(m[1]);
  return members.filter((x) => {
    const last = /\s(\S+)-\S+$/.exec(x.name.replace(/,\s*(?:Jr|Sr|II|III|IV)\.?$/, ''));
    return last !== null && ndKey(last[1]) === family;
  });
}

/** Each printed label as the one member it names (full name), or as printed when none or several fit. */
export function ndMemberNames(labels: string[], members: NdMember[]): string[] {
  const fits = labels.map((l) => { const f = ndFits(l, members); return f.length ? f : ndFitsHyphenated(l, members); });
  return labels.map((l, i) => {
    let f = fits[i];
    if (f.length > 1) {
      // a member another label of the vote fits alone is not this one ("Jones" beside "Roers Jones")
      const taken = new Set(fits.flatMap((g, j) => (j !== i && g.length === 1 ? [g[0].slug] : [])));
      f = f.filter((x) => !taken.has(x.slug));
    }
    return f.length === 1 ? f[0].name : l;
  });
}

const ND_MONTHS = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];

/** The vote, or why it was refused (the first check that failed). */
function readNorthDakota(bodies: string[], r: NdVoteRef): NdVoteRecord | { refused: string } {
  const fail = (refused: string): { refused: string } => ({ refused });
  if (bodies.length !== 2 || !bodies[0].startsWith(PDF_LINES_MARK + '\n')) return fail('not a journal PDF and a member list');
  const CH = r.chamber === 'House' ? 'HOUSE' : 'SENATE';
  const raw = bodies[0].split('\n').slice(1);
  if (!raw.includes(`JOURNAL OF THE ${CH}`)) return fail(`the PDF is not the journal of the ${r.chamber}`);
  if (!raw.includes(`${ND_ORDINAL[r.assembly]} Legislative Assembly`)) return fail(`the journal is not of the ${ordinal(r.assembly)} Legislative Assembly`);
  // the running heads: the day and its date on every odd page, the chamber and day on every even page
  const dates = new Set<string>();
  const lines: { page: number; text: string }[] = [];
  // The running head sets the page. Most pages also begin with a bare "Page 798" line, and some (a journal's last page)
  // do not, so that line is dropped only where the head that follows it prints the same number.
  let page = 0;
  for (const [n, l] of raw.entries()) {
    const p = /^Page (\d+)$/.exec(l);
    if (p && new RegExp(`^(?:${p[1]} JOURNAL OF THE |\\d+(?:st|nd|rd|th) DAY .* ${p[1]}$)`).test(raw[n + 1] ?? '')) continue;
    const odd = /^(\d+)(?:st|nd|rd|th) DAY [A-Z]+, ([A-Z]+) (\d{1,2}), (\d{4}) (\d+)$/.exec(l);
    if (odd) {
      if (Number(odd[1]) !== r.day || Number(odd[5]) <= page) return fail(`a running head that is not day ${r.day}, after page ${page}: ${l}`);
      page = Number(odd[5]);
      const mo = ND_MONTHS.indexOf(odd[2]);
      if (mo < 0) return fail(`a running head with no month: ${l}`);
      dates.add(`${odd[4]}-${String(mo + 1).padStart(2, '0')}-${odd[3].padStart(2, '0')}`);
      continue;
    }
    const even = /^(\d+) JOURNAL OF THE (HOUSE|SENATE) (\d+)(?:st|nd|rd|th) DAY$/.exec(l);
    if (even) {
      if (even[2] !== CH || Number(even[3]) !== r.day || Number(even[1]) <= page) return fail(`a running head that is not the ${r.chamber}'s day ${r.day}, after page ${page}: ${l}`);
      page = Number(even[1]);
      continue;
    }
    if (!page) continue; // nothing comes before the first page's number
    lines.push({ page, text: l });
  }
  if (dates.size !== 1) return fail(`the journal prints ${dates.size} dates`);
  const date = [...dates][0];
  if (Number(date.slice(0, 4)) !== r.year) return fail(`the journal is of ${date.slice(0, 4)}, not ${r.year}`);
  const bill = `${r.billType} ${r.billNum}`;
  const heading = new RegExp(`^${r.billType} ${r.billNum}: `);
  const found: NdVoteRecord[] = [];
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].text !== 'ROLL CALL') continue;
    // the bill whose heading this roll call follows: the nearest heading since the last separator
    let head = -1;
    for (let k = i - 1; k >= 0 && !/^\*+$/.test(lines[k].text); k--) {
      if (/^[HS][A-Z]{1,3} \d{4}: /.test(lines[k].text)) { head = k; break; }
    }
    if (head < 0 || !heading.test(lines[head].text)) continue;
    // the question runs to the first group heading
    let j = i + 1;
    let qtext = '';
    while (j < lines.length && !/^[A-Z ]+: /.test(lines[j].text)) { qtext = qtext ? `${qtext} ${lines[j].text}` : lines[j].text; j++; }
    const qm = /^The question being (.+?)(?:, which (?:has|have) been read\b.*?)?(?:, the roll|\. The roll) +was called and there were (\d+) YEAS, (\d+) NAYS, (?:(\d+) EXCUSED, (\d+) ABSENT AND NOT VOTING|(\d+) ABSENT OR EXCUSED AND NOT VOTING)\.$/.exec(squash(qtext));
    if (!qm) continue; // not a question the reader knows; a vote on the bill must read, or it is refused below
    const q = squash(qm[1]);
    if (!ndQuestionIsOnTheBill(q)) continue;
    const want: Record<NdVote, number> = { Yea: Number(qm[2]), Nay: Number(qm[3]), 'Absent or excused': qm[6] !== undefined ? Number(qm[6]) : Number(qm[4]) + Number(qm[5]) };
    const printedCount: Record<string, number> = { YEAS: Number(qm[2]), NAYS: Number(qm[3]), ...(qm[6] !== undefined ? { 'ABSENT OR EXCUSED AND NOT VOTING': Number(qm[6]) } : { EXCUSED: Number(qm[4]), 'ABSENT AND NOT VOTING': Number(qm[5]) }) };
    const labels = Object.fromEntries(ND_VOTES.map((v) => [v, [] as string[]])) as Record<NdVote, string[]>;
    const seen = new Set<string>();
    let bad = '';
    // each group: a heading, then labels separated by "; " over lines, to the next heading or the line that is not a name:
    // the result ("Engrossed HB 1017 passed."), a separator, or a title in capitals. A name can break over a line with no
    // semicolon ("Roers" / "Jones", "Speaker" / "Bellew"); a line ending in a hyphen runs on with no space
    // ("Schreiber-" / "Beck"). The group must then hold the count the question prints for its heading.
    while (j < lines.length) {
      const h = /^([A-Z][A-Z ]*[A-Z]): (.*)$/.exec(lines[j].text);
      if (!h) break;
      const g = ND_HEADING[h[1]];
      if (!g || seen.has(h[1]) || !(h[1] in printedCount)) { bad = `a group heading the reader does not know, or one printed twice: ${h[1]}`; break; }
      seen.add(h[1]);
      let text = h[2];
      j++;
      const isName = (l: string): boolean => !/^[A-Z][A-Z ]*[A-Z]: /.test(l) && !/\b[HS][A-Z]{1,3} \d{4}\b/.test(l) && !/^\*+$/.test(l) && !/^[A-Z]{2,}[A-Z .,']*$/.test(l);
      // a line ending in a comma, a semicolon or a hyphen always runs on ("Speaker Johnson," / "D.")
      while (j < lines.length && (/[,;-]$/.test(text) || isName(lines[j].text))) {
        text = text.endsWith('-') ? text + lines[j].text : `${text} ${lines[j].text}`;
        j++;
      }
      const got = text.split(';').map(squash);
      if (got.length !== printedCount[h[1]]) { bad = `the ${h[1]} group lists ${got.length} members and the question prints ${printedCount[h[1]]}`; break; }
      labels[g].push(...got);
    }
    if (bad) return fail(bad);
    const end = lines[j]?.text ?? '';
    if (lines[j - 1].page < r.page || lines[head].page > r.page) continue; // another vote of this bill on this day
    for (const v of ND_VOTES) {
      if (labels[v].some((l) => !l)) return fail(`an empty label in the ${v} group`);
      if (labels[v].length !== want[v]) return fail(`the ${v} group lists ${labels[v].length} members and the question prints ${want[v]}`);
    }
    // the line after the last group: "Engrossed HB 1017 passed.", "HB 1326 failed.", "HCR 3021 was declared adopted ..."
    const named = [...end.matchAll(/\b([HS][A-Z]{1,3}) (\d{4})\b/g)].map((x) => `${x[1]} ${Number(x[2])}`);
    if (named.length !== 1 || named[0] !== bill || !/\b(passed|failed|adopted|lost)\b/.test(end)) return fail(`the roll call does not end on the bill's result: ${end}`);
    const all = ND_VOTES.flatMap((v) => labels[v]);
    if (all.length > ND_SIZE[r.chamber]) return fail('more members than the chamber has');
    if (new Set(all.map(ndKey)).size !== all.length) return fail('a member is listed twice');
    found.push({ state: 'ND', stateName: 'North Dakota', chamber: r.chamber, session: `${ordinal(r.assembly)} Legislative Assembly`, page: r.page, bill,
      question: q.replace(/^on the final/, 'Final'), date, groups: labels });
  }
  if (found.length !== 1) return fail(`the journal holds ${found.length} roll calls on ${bill} that read as a vote on the bill and take in page ${r.page}`);
  const list = ndMembers(bodies[1]);
  if (!list) return fail('the member list did not read');
  const members = list.filter((m) => m.chamber === r.chamber);
  // "Speaker Bellew" is the Speaker, printed with the office; the office is dropped to name the member
  const strip = (l: string): string => (r.chamber === 'House' ? l.replace(/^Speaker\s+/, '') : l);
  const labels = ND_VOTES.flatMap((v) => found[0].groups[v].map(strip));
  const names = ndMemberNames(labels, members);
  let k = 0;
  const groups = Object.fromEntries(ND_VOTES.map((v) => [v, found[0].groups[v].map(() => names[k++])])) as Record<NdVote, string[]>;
  const keys = ND_VOTES.flatMap((v) => groups[v]).map(ndKey);
  if (new Set(keys).size !== keys.length) return fail('two members render as one name');
  return { ...found[0], groups };
}

const ND_SAID: Record<NdVote, string> = { Yea: 'voted Yea', Nay: 'voted Nay', 'Absent or excused': 'was absent or excused and did not vote' };

export function renderNorthDakotaVote(v: NdVoteRecord): string {
  return [
    `North Dakota ${v.chamber} vote of ${v.date}, journal page ${v.page} (${v.session}), ${v.bill}.`,
    `Question: ${v.question}`,
    ND_VOTES.map((k) => `${k} ${v.groups[k].length}`).join('; ') + '.',
    ...ND_VOTES.map((k) => `${k} (${v.groups[k].length}): ${v.groups[k].join('; ')}`.trim()),
  ].join('\n');
}

const ND_RENDER_HEAD = /^North Dakota (House|Senate) vote of (\d{4}-\d{2}-\d{2}), journal page (\d+) \((\d+(?:st|nd|rd|th) Legislative Assembly)\), ([HS][A-Z]{1,3} \d{4})\.$/;

function parseNorthDakotaRender(text: string, url: string): NdVoteRecord | null {
  const r = parseNorthDakotaVoteUrl(url);
  const rows = text.split('\n');
  const h = ND_RENDER_HEAD.exec(rows[0] ?? '');
  const q = /^Question: (.+)$/.exec(rows[1] ?? '');
  if (!r || !h || !q || rows.length !== 3 + ND_VOTES.length) return null;
  if (h[1] !== r.chamber || Number(h[3]) !== r.page || h[4] !== `${ordinal(r.assembly)} Legislative Assembly` || h[5] !== `${r.billType} ${r.billNum}`) return null;
  const groups = {} as Record<NdVote, string[]>;
  for (const [i, v] of ND_VOTES.entries()) {
    const m = new RegExp(`^${v} \\((\\d+)\\):(.*)$`).exec(rows[3 + i]);
    if (!m) return null;
    groups[v] = m[2].split(';').map((s) => s.trim()).filter(Boolean);
    if (groups[v].length !== Number(m[1])) return null;
  }
  if (rows[2] !== ND_VOTES.map((v) => `${v} ${groups[v].length}`).join('; ') + '.') return null;
  return { state: 'ND', stateName: 'North Dakota', chamber: r.chamber, session: h[4], page: r.page, bill: h[5], question: q[1], date: h[2], groups };
}

const ND_LINE = /^North Dakota (House|Senate) vote of (\d{4}-\d{2}-\d{2}), journal page (\d+) \((\d+(?:st|nd|rd|th) Legislative Assembly)\), ([HS][A-Z]{1,3} \d{4}) - (.+?): (.+?) (voted Yea|voted Nay|was absent or excused and did not vote)\.$/;

export function formatNorthDakotaVoteLine(l: NdVoteLine): string {
  return `North Dakota ${l.chamber} vote of ${l.date}, journal page ${l.page} (${l.session}), ${l.bill} - ${l.question}: ${l.name} ${ND_SAID[l.vote]}.`;
}

function parseNorthDakotaLine(text: string): NdVoteLine | null {
  const m = ND_LINE.exec(text.trim());
  const vote = m ? ND_VOTES.find((v) => ND_SAID[v] === m[8]) : undefined;
  if (!m || !vote) return null;
  return { state: 'ND', stateName: 'North Dakota', chamber: m[1] as Chamber, date: m[2], page: Number(m[3]), session: m[4], bill: m[5], question: m[6], name: m[7].trim(), vote };
}

function verifyNorthDakotaLine(line: string, url: string, text: string, lastName: string, fullName: string): SnippetVerdict {
  const l = parseNorthDakotaLine(line);
  const r = parseNorthDakotaRender(text, url);
  if (!l || !r) return { verdict: 'snippet_not_found' };
  if (l.page !== r.page || l.chamber !== r.chamber || l.session !== r.session || l.bill !== r.bill || l.date !== r.date) return { verdict: 'snippet_not_found' };
  if (normalizeText(l.question) !== normalizeText(r.question)) return { verdict: 'snippet_not_found' };
  if (!r.groups[l.vote].some((n) => sameLabel(n, l.name))) return { verdict: 'snippet_not_found' };
  const fits = ND_VOTES.flatMap((v) => r.groups[v]).filter((n) => fullNameLabelFits(n, lastName, fullName));
  if (fits.length !== 1 || !sameLabel(fits[0], l.name)) return { verdict: 'name_not_present' };
  return { verdict: 'verified', matchOffset: 0 };
}

function northDakotaLinesFor(url: string, text: string, lastName: string, fullName: string): string[] {
  const r = parseNorthDakotaRender(text, url);
  if (!r) return [];
  const out: string[] = [];
  for (const vote of ND_VOTES) {
    for (const name of r.groups[vote]) {
      if (fullNameLabelFits(name, lastName, fullName)) out.push(formatNorthDakotaVoteLine({ ...r, name, vote }));
    }
  }
  return out.length === 1 ? out : [];
}

/** The vote an address names, read from the day's journal and the Assembly's member list. Null when any check fails. */
export function readNorthDakotaVote(bodies: string[], url: string): NdVoteRecord | null {
  const v = explainNorthDakotaVote(bodies, url);
  return 'refused' in v ? null : v;
}

/** As readNorthDakotaVote, with the reason a vote is refused: for the fetch tool's report and the tests. */
export function explainNorthDakotaVote(bodies: string[], url: string): NdVoteRecord | { refused: string } {
  const r = parseNorthDakotaVoteUrl(url);
  if (!r) return { refused: 'not a North Dakota vote address' };
  try { return readNorthDakota(bodies, r); } catch (e) { return { refused: `the reader failed: ${e instanceof Error ? e.message : e}` }; }
}

// ── Minnesota: each chamber's daily journal, read with the Legislative Reference Library's member list ─────────────────
// Read 2026-11-19. robots.txt: www.house.mn.gov disallows /Fiscal2/ only; www.mnsenate.gov has none (404);
// www.lrl.mn.gov disallows /legdb/ltrsearch.aspx and a few others, not /legdb/results. None states a Crawl-delay.
//
// Minnesota publishes no per-vote page a reader can use: the House's own vote pages for 2017-2020 answer 500, and the
// newer /Votes/Details page says "Please see the Journal of the House for official recorded roll call votes". Every
// floor vote is printed in the chamber's daily journal, every year the same way, and the Revisor's bill status page
// (www.revisor.mn.gov/bills/93/2023/0/SF/2909/) links each action with its tally ("Third reading Passed ... vote: 34-33")
// to the journal page it is on (fetch-legislature-rollcalls.ts, INDEX.MN).
//
// The House journal is one HTML page per day, www.house.mn.gov/cco/journals/2023-24/J0425056.htm (month, day, session
// day), written by Word in windows-1252. Each page of the printed journal begins with an anchor and a banner,
// `<a name=7013></a><center><b>Journal of the House - 56th Day - Tuesday, April 25, 2023 - Top of Page 7013</b></center>`;
// a vote reads, one paragraph per line and one member per paragraph:
//
//   S. F. No. 2934, A bill for an act relating to ...
//   The bill was read for the third time, as amended, and placed upon its final passage.
//   The question was taken on the passage of the bill and the roll was called. There were 70 yeas and 60 nays as follows:
//   Those who voted in the affirmative were:
//   Acomb / Agbaje / ... / Hansen, R. / Hanson, J. / ... / Spk. Hortman
//   Those who voted in the negative were:
//   Altendorf / Anderson, P. E. / Anderson, P. H. / ...
//   The bill was passed, as amended, and its title agreed to.
//
// The Senate journal is one PDF per day, www.mnsenate.gov/journals/2023-2024/20230414049.pdf (date, session day; a
// special session's file ends "_ss1"), read as cells (pdfCellsBody: the names stand in a grid of five columns, and a
// name can be two words, "Oumou Verbeten"). Odd pages carry the head "49TH DAY]  FRIDAY, APRIL 14, 2023  5105", even
// pages "5106  JOURNAL OF THE SENATE  [49TH DAY". A vote reads:
//
//   S.F. No. 2909 was read the third time, as amended, and placed on its final passage.
//   The question was taken on the passage of the bill, as amended.
//   The roll was called, and there were yeas 34 and nays 33, as follows:
//   Those who voted in the affirmative were:
//   Boldon  Frentz  Kupec  Mohamed  Putnam ...
//   Pursuant to Rule 40, Senator Kunesh cast the affirmative vote on behalf of the following Senators:   (2020-2023)
//   Dibble, Dziedzic, Fateh, Hawj, Pha, Port, Putnam, and Rest.
//   Those who voted in the negative were:
//   ...
//   So the bill, as amended, was passed and its title was agreed to.
//
// Neither journal names a member who did not vote, so the render holds Yea and Nay only and an absent member has no
// finding (as Ohio). The address names the vote after a #, the printed journal page and the bill:
// .../J0425056.htm#Page7013-SF2934 and .../20230414049.pdf#Page5105-SF2909.
//
// Both journals print a family name, with initials when two members share it ("Hansen, R.", "Anderson, P. E.", "Lee, K."),
// and the Speaker with the office ("Spk. Hortman"). The reader names each member from the Legislative Reference Library's
// list of everyone who sat in that chamber in that Legislature (www.lrl.mn.gov/legdb/results?search=session&gender=all
// &sess=93&body=house: "Anderson, Paul H.", "Pelowski, Jr., Gene P.", each with an LRL id). A label is the one member
// whose family name is the label's and whose given names hold its initials; a member whose list name lacks a middle
// name may still fit a printed second initial, but a member whose list name fits every initial is taken first. When
// several fit, a member another label of the vote fits alone is taken out. A label no member fits, or several, is kept
// as printed and gives no line. MN_LABEL_ALIASES names the few members the journal prints by a legal name the list
// does not give (the alias names an LRL id, and holds only if that id is on the list).
//
// A vote is read only when the question is the passage or repassage of the bill (mnQuestionIsOnTheBill), the bill read
// is the address's bill, the address's page lies between the reading and the last name, each group lists the count the
// tally prints, every page head is this chamber's and this day's, and the line after the last group is the bill's result.
//
//   Minnesota Senate vote of 2023-04-14, journal page 5105 (93rd Legislature), SF 2909.
//   Question: Passage of the bill
//   Yea 34; Nay 33.
//   Yea (34): Liz Boldon; …
//   Minnesota Senate vote of 2023-04-14, journal page 5105 (93rd Legislature), SF 2909 - Passage of the bill: Liz Boldon voted Yea.

export const MN_VOTES = ['Yea', 'Nay'] as const;
export type MnVote = (typeof MN_VOTES)[number];
/** robots.txt states no Crawl-delay on any of the three hosts (2026-11-19): one request a second is ours. */
const MN_GAP_MS = 1_000;
const MN_SIZE: Record<Chamber, number> = { House: 134, Senate: 67 };
const MN_HOUSE_URL = /^https:\/\/www\.house\.mn\.gov\/cco\/journals\/(20\d{2})-(\d{2})\/J(\d{2})(\d{2})(\d{3})\.htm#Page([1-9]\d{0,4})-([HS]F)([1-9]\d{0,4})$/;
const MN_SENATE_URL = /^https:\/\/www\.mnsenate\.gov\/journals\/(20\d{2})-(20\d{2})\/(20\d{2})(\d{2})(\d{2})(\d{1,3})(?:_ss([1-9]))?\.pdf#Page([1-9]\d{0,4})-([HS]F)([1-9]\d{0,4})$/;
const MN_LEGISLATURE_WORD = ['NINETIETH', 'NINETY-FIRST', 'NINETY-SECOND', 'NINETY-THIRD', 'NINETY-FOURTH', 'NINETY-FIFTH'];
const MN_ORDINAL_WORD = ['FIRST', 'SECOND', 'THIRD', 'FOURTH', 'FIFTH', 'SIXTH', 'SEVENTH', 'EIGHTH', 'NINTH', 'TENTH'];
const MN_MONTHS = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];

/**
 * Members the journal prints by a legal name the LRL list does not give, keyed "<Legislature>|<chamber>|<label>", each
 * naming an LRL id. Checked by hand against the member's LRL record, which gives the legal name.
 */
export const MN_LABEL_ALIASES: Readonly<Record<string, number>> = {
  // LRL 15466: "Former Name: Kunesh-Podein"; LRL 15494: "Former Name: Neu". The 91st House list prints their present
  // names, "Kunesh, Mary K." and "Neu Brindley, Anne E"; the 2020 journal prints the former ones (HF 8, HF 9)
  '91|House|Kunesh-Podein': 15466,
  '91|House|Neu': 15494,
  // LRL 15409: "Former Name: O'Neill"; the list prints her present name, "Rarick, Marion"
  '90|House|O\'Neill': 15409,
  '91|House|O\'Neill': 15409,
  '92|House|O\'Neill': 15409,
  '93|House|O\'Neill': 15409,
  // LRL 15576: "Her name is Kaozouapa Elizabeth Lee, but she goes by Liz"; the list prints "Lee, Liz"
  '93|House|Lee, K.': 15576,
  '94|House|Lee, K.': 15576,
};

/**
 * Is a Minnesota journal question a vote on the bill? The passage of the bill (as amended, or of a Senate or House file
 * in the other chamber), its repassage after a conference committee or the other chamber's amendments, and passage
 * over the Governor's veto. A vote on an amendment, a motion, a point of order, or concurrence alone is not (runner,
 * 2026-11-16). The question is the journal's words after "The question was taken on the".
 */
export function mnQuestionIsOnTheBill(q: string): boolean {
  return /^(?:re)?passage of the bill(?:, as amended(?: by (?:the )?(?:Conference(?: Committee)?|the (?:House|Senate)))?)?$/i.test(squash(q))
    || /^Shall (?:H|S)\. ?F\. No\. \d+ (?:be repassed|pass|be passed),? the objections of the Governor notwithstanding\?$/i.test(squash(q));
}

export interface MnVoteRef { state: 'MN'; stateName: 'Minnesota'; chamber: Chamber; legislature: number; file: string; page: number; billType: string; billNum: number; special: number }
export interface MnVoteRecord { state: 'MN'; stateName: 'Minnesota'; chamber: Chamber; session: string; page: number; bill: string; question: string; date: string; groups: Record<MnVote, string[]> }
export interface MnVoteLine extends Omit<MnVoteRecord, 'groups'> { name: string; vote: MnVote }

export function parseMinnesotaVoteUrl(url: string): MnVoteRef | null {
  const u = url.trim();
  const h = MN_HOUSE_URL.exec(u);
  if (h) {
    const y = Number(h[1]);
    if (y % 2 !== 1 || y < 2017 || Number(h[2]) !== (y + 1) % 100) return null;
    return { state: 'MN', stateName: 'Minnesota', chamber: 'House', legislature: 90 + (y - 2017) / 2, file: `${h[1]}-${h[2]}/J${h[3]}${h[4]}${h[5]}`,
      page: Number(h[6]), billType: h[7], billNum: Number(h[8]), special: 0 };
  }
  const s = MN_SENATE_URL.exec(u);
  if (s) {
    const y = Number(s[1]);
    const fy = Number(s[3]);
    if (y % 2 !== 1 || y < 2017 || Number(s[2]) !== y + 1 || (fy !== y && fy !== y + 1)) return null;
    return { state: 'MN', stateName: 'Minnesota', chamber: 'Senate', legislature: 90 + (y - 2017) / 2, file: `${s[1]}-${s[2]}/${s[3]}${s[4]}${s[5]}${s[6]}${s[7] ? `_ss${s[7]}` : ''}`,
      page: Number(s[8]), billType: s[9], billNum: Number(s[10]), special: s[7] ? Number(s[7]) : 0 };
  }
  return null;
}

/** The LRL list of everyone who sat in that chamber in that Legislature. */
export function mnMemberListUrl(legislature: number, chamber: Chamber): string {
  return `https://www.lrl.mn.gov/legdb/results?search=session&gender=all&sess=${legislature}&body=${chamber === 'House' ? 'house' : 'senate'}`;
}

function minnesotaDocs(r: MnVoteRef): string[] {
  const doc = r.chamber === 'House' ? `https://www.house.mn.gov/cco/journals/${r.file}.htm` : `https://www.mnsenate.gov/journals/${r.file}.pdf`;
  return [doc, mnMemberListUrl(r.legislature, r.chamber)];
}

/** given: the list's given names in order; known: the names the member is also known by ("Patti, Pat"). */
export interface MnMember { id: number; family: string; given: string[]; known: string[]; name: string }

/**
 * The LRL list's members: "Anderson, Paul H.", "Pelowski, Jr., Gene P.", "Quam, II, Duane", each with its LRL id and the
 * names it is also known by (` - "Patti, Pat"`). Null unless the list says it is this Legislature's and this chamber's and
 * holds the number of records it says it matched.
 */
export function mnMembers(html: string, legislature: number, chamber: Chamber): MnMember[] | null {
  const head = /(\d+) records? matched session search for:\s*<b>\s*(?:<br\s*\/?>)?\s*Session = (\d+)(?:st|nd|rd|th) \(\d{4}-\d{4}\)\s*<br\s*\/?>\s*Body = (House|Senate)\s*<\/b>/.exec(html);
  if (!head || Number(head[2]) !== legislature || head[3] !== chamber) return null;
  const out: MnMember[] = [];
  for (const m of html.matchAll(/href="fulldetail\.aspx\?ID=(\d+)">([^<]*)<\/a>\s*<span id="[^"]*Label_othername">([^<]*)<\/span>/g)) {
    const parts = htmlText(m[2]).split(',').map((p) => p.trim()).filter(Boolean);
    const family = parts[0];
    const rest = parts.slice(1).filter((p) => !/^(?:Jr|Sr|II|III|IV)\.?$/i.test(p));
    const suffix = parts.slice(1).find((p) => /^(?:Jr|Sr|II|III|IV)\.?$/i.test(p));
    if (!family || rest.length !== 1) return null;
    const own = rest[0].split(/\s+/);
    const other = htmlText(m[3].replace(/&#34;/g, '"')).replace(/^-\s*/, '').replace(/"/g, '').split(',').map((x) => x.trim()).filter(Boolean);
    out.push({ id: Number(m[1]), family, given: own, known: other, name: `${rest[0]} ${family}${suffix ? ` ${suffix}` : ''}` });
  }
  return out.length && out.length === Number(head[1]) ? out : null;
}

const mnKey = (s: string): string => fold(s).replace(/[\s']/g, '');

/** The members a label fits: [strict, lenient]. Strict: every printed initial starts the given name in its place. */
function mnFits(label: string, members: MnMember[]): [MnMember[], MnMember[]] {
  const m = /^([^,]+?)(?:,\s*(.+))?$/.exec(squash(label));
  if (!m) return [[], []];
  const fam = mnKey(m[1]);
  const printed = (m[2] ?? '').replace(/\./g, '. ').split(/\s+/).filter(Boolean).map((p) => fold(p));
  const same = members.filter((x) => mnKey(x.family) === fam);
  if (!printed.length) return [same, same];
  // the first initial may start the first given name or a name the member is also known by; each later one starts the
  // given name in its place (strict), or there is no given name in its place on the list (lenient)
  const firstFits = (x: MnMember, p: string): boolean => [x.given[0], ...x.known].some((g) => g && fold(g)[0] === p[0]);
  const laterFits = (x: MnMember, p: string, i: number, lenient: boolean): boolean =>
    x.given[i] === undefined ? lenient : fold(x.given[i])[0] === p[0];
  const strict = same.filter((x) => printed.every((p, i) => (i === 0 ? firstFits(x, p) : laterFits(x, p, i, false))));
  const lenient = same.filter((x) => printed.every((p, i) => (i === 0 ? firstFits(x, p) : laterFits(x, p, i, true))));
  return [strict, lenient];
}

/** Each printed label as the one member it names (full name), or as printed when none or several fit. */
export function mnMemberNames(labels: string[], members: MnMember[], aliasKey?: (label: string) => number | undefined): string[] {
  const fits = labels.map((l) => {
    const alias = aliasKey?.(l);
    if (alias !== undefined) return members.filter((x) => x.id === alias);
    const [strict, lenient] = mnFits(l, members);
    if (strict.length === 1) return strict;
    return lenient;
  });
  return labels.map((l, i) => {
    let f = fits[i];
    if (f.length > 1) {
      const taken = new Set(fits.flatMap((g, j) => (j !== i && g.length === 1 ? [g[0].id] : [])));
      f = f.filter((x) => !taken.has(x.id));
    }
    return f.length === 1 ? f[0].name : l;
  });
}

const mnOrdinalLegislature = (n: number): string => `${ordinal(n)} Legislature`;

/** The House journal's text as lines, each with the printed page it is on; and the dates and days its page banners print. */
function mnHouseLines(html: string): { lines: { page: number; text: string }[]; dates: Set<string>; days: Set<number>; bad?: string } {
  // 2026 writes "<a name = 6145>" and "Journal Of the House -  63rd -Thursday, April 23, 2026 - Top of Page 6145" (J0423063)
  const BANNER = /<a\s+name\s*=\s*"?(\d+)"?\s*>\s*<\/a>\s*<center>\s*<b>\s*Journal of the House\s+-\s+(\d+)(?:st|nd|rd|th)(?:\s+Day)?\s*-\s*[A-Za-z]+,\s+([A-Za-z]+)\s+(\d{1,2}),\s+(\d{4})\s+-\s+Top of Page\s+(\d+)\s*<\/b>\s*<\/center>/gi;
  const dates = new Set<string>();
  const days = new Set<number>();
  let bad: string | undefined;
  // Word wraps the source inside a paragraph: a line break in the source is a space, and only the markup ends a line
  const marked = html.replace(/<style[\s\S]*?<\/style>/gi, '').replace(/\r?\n/g, ' ').replace(BANNER, (_m, anchor: string, day: string, mon: string, dd: string, yyyy: string, page: string) => {
    if (anchor !== page) bad ??= `a page banner whose anchor ${anchor} is not its page ${page}`;
    const mo = MN_MONTHS.indexOf(mon.toUpperCase());
    if (mo < 0) bad ??= `a page banner with no month: ${mon}`;
    dates.add(`${yyyy}-${String(mo + 1).padStart(2, '0')}-${dd.padStart(2, '0')}`);
    days.add(Number(day));
    return `\n@@PAGE ${page}@@\n`;
  });
  const text = marked.replace(/<\/p>|<br[^>]*>|<\/div>|<\/h\d>|<\/center>/gi, '\n').replace(/<[^>]+>/g, '');
  const lines: { page: number; text: string }[] = [];
  let page = 0;
  for (const raw of text.split('\n')) {
    const p = /^@@PAGE (\d+)@@$/.exec(raw.trim());
    if (p) {
      if (Number(p[1]) <= page) bad ??= `page ${p[1]} after page ${page}`;
      page = Number(p[1]);
      continue;
    }
    const t = squash(htmlText(raw).replace(/ /g, ' '));
    if (!t || !page) continue;
    lines.push({ page, text: t });
  }
  return { lines, dates, days, bad };
}

const MN_NAME = /^(?:Spk\.\s+)?[\p{L}][\p{L}'’ -]*[\p{L}](?:,\s*(?:[\p{L}]\.\s?){1,3})?$/u;

/** The vote, or why it was refused (the first check that failed). */
function readMinnesotaHouse(bodies: string[], r: MnVoteRef): MnVoteRecord | { refused: string } {
  const fail = (refused: string): { refused: string } => ({ refused });
  const { lines, dates, days, bad } = mnHouseLines(bodies[0]);
  if (bad) return fail(bad);
  if (!lines.length) return fail('the page is not a House journal: no page banner');
  if (dates.size !== 1 || days.size !== 1) return fail(`the journal's page banners print ${dates.size} dates and ${days.size} days`);
  const date = [...dates][0];
  const day = [...days][0];
  if (Number(r.file.slice(-3)) !== day || r.file.slice(-7, -3) !== date.slice(5, 7) + date.slice(8, 10)) return fail(`the journal is day ${day} of ${date}, not the file ${r.file}`);
  const y = Number(date.slice(0, 4));
  if (y !== 2017 + 2 * (r.legislature - 90) && y !== 2018 + 2 * (r.legislature - 90)) return fail(`the journal is of ${y}, not of the ${mnOrdinalLegislature(r.legislature)}`);
  // the day's heading names the session: "STATE OF MINNESOTA / NINETY-THIRD SESSION - 2023", or "FOURTH SPECIAL SESSION -
  // 2020" (a special session's days share the biennium's folder and number their days from one)
  const sh = lines.slice(0, 12).map((l) => /^([A-Z-]+)(?: (SPECIAL))? SESSION - (\d{4})$/.exec(l.text)).find(Boolean);
  if (!sh || Number(sh[3]) !== y) return fail('the journal does not open with its session heading');
  let special = 0;
  if (sh[2]) {
    special = MN_ORDINAL_WORD.indexOf(sh[1]) + 1;
    if (!special) return fail(`a special session the reader cannot number: ${sh[1]}`);
  } else if (sh[1] !== MN_LEGISLATURE_WORD[r.legislature - 90]) return fail(`the journal is of the ${sh[1]} session, not the ${mnOrdinalLegislature(r.legislature)}`);
  const bill = `${r.billType} ${r.billNum}`;
  const billDots = `${r.billType[0]}. F. No. ${r.billNum}`;
  const found: MnVoteRecord[] = [];
  for (let i = 0; i < lines.length; i++) {
    const qm = /^The (?:question was taken on the|vote was taken on the question) (.+?),? and the roll was called\.\s*There were (\d+) yeas and (\d+) nays as follows:$/.exec(lines[i].text);
    if (!qm) continue;
    const q = squash(qm[1].replace(/^"|"$/g, '').replace(/^question "/, ''));
    if (!mnQuestionIsOnTheBill(q)) continue;
    // the bill: the nearest paragraph before this roll call that opens with a bill number, with a third reading between
    let head = -1;
    let read = -1;
    for (let k = i - 1; k >= 0; k--) {
      if (read < 0 && /\bwas read for the third time\b/.test(lines[k].text)) read = k;
      if (/^[HS]\. F\. No\. \d+\b/.test(lines[k].text)) { head = k; break; }
    }
    if (head < 0 || read < 0) continue;
    if (!lines[head].text.startsWith(billDots) || /^\d/.test(lines[head].text.slice(billDots.length))) continue;
    const want: Record<MnVote, number> = { Yea: Number(qm[2]), Nay: Number(qm[3]) };
    const groups: Record<MnVote, string[]> = { Yea: [], Nay: [] };
    let j = i + 1;
    let badGroup = '';
    for (const [v, heading] of [['Yea', 'Those who voted in the affirmative were:'], ['Nay', 'Those who voted in the negative were:']] as const) {
      if (lines[j]?.text !== heading) { if (want[v] === 0) continue; badGroup = `no "${heading}" after the ${v === 'Yea' ? 'question' : 'yeas'}`; break; }
      j++;
      while (j < lines.length && MN_NAME.test(lines[j].text) && !/^(?:The|So) /.test(lines[j].text)) { groups[v].push(lines[j].text); j++; }
    }
    if (badGroup) return fail(badGroup);
    const end = lines[j]?.text ?? '';
    if (lines[j - 1].page < r.page || lines[read].page > r.page) continue; // another vote of this bill on this day
    for (const v of MN_VOTES) if (groups[v].length !== want[v]) return fail(`the ${v} group lists ${groups[v].length} members and the tally prints ${want[v]}`);
    if (!/^The bill was (?:not )?(?:re)?passed\b|^The bill, as amended[^,]*, was (?:not )?(?:re)?passed\b|^So the bill\b|^(?:H|S)\. F\. No\. \d+, as amended[^,]*, was (?:not )?(?:re)?passed\b|^The bill was (?:not )?passed, the objections\b/.test(end)) return fail(`the roll call does not end on the bill's result: ${end}`);
    const all = MN_VOTES.flatMap((v) => groups[v]);
    if (all.length > MN_SIZE.House) return fail('more members than the chamber has');
    if (new Set(all.map(mnKey)).size !== all.length) return fail('a member is listed twice');
    found.push({ state: 'MN', stateName: 'Minnesota', chamber: 'House', session: mnSession({ ...r, special }), page: r.page, bill, question: q.charAt(0).toUpperCase() + q.slice(1), date, groups });
  }
  if (found.length !== 1) return fail(`the journal holds ${found.length} roll calls on ${bill} that read as a vote on the bill and take in page ${r.page}`);
  return found[0];
}

const mnSession = (r: Pick<MnVoteRef, 'legislature' | 'special'>): string => `${mnOrdinalLegislature(r.legislature)}${r.special ? `, ${MN_ORDINAL_WORD[r.special - 1].charAt(0)}${MN_ORDINAL_WORD[r.special - 1].slice(1).toLowerCase()} Special Session` : ''}`;

/** The vote, or why it was refused (the first check that failed). */
function readMinnesotaSenate(bodies: string[], r: MnVoteRef): MnVoteRecord | { refused: string } {
  const fail = (refused: string): { refused: string } => ({ refused });
  if (!bodies[0].startsWith(PDF_CELLS_MARK + '\n')) return fail('not a journal PDF read as cells');
  const raw = bodies[0].split('\n').slice(1).map((l) => l.replace(/​/g, '').split('\t').map(squash).filter(Boolean)).filter((c) => c.length);
  if (!raw.some((c) => /^\d+ JOURNAL OF THE SENATE \[\d+(?:ST|ND|RD|TH) DAY$/.test(c.join(' ')) || c.join(' ') === 'JOURNAL OF THE SENATE')) return fail('the PDF is not the journal of the Senate');
  const dates = new Set<string>();
  const days = new Set<string>();
  const lines: { page: number; cells: string[]; text: string }[] = [];
  let page = 0;
  for (const c of raw) {
    const t = c.join(' ');
    const odd = /^(\d+)(?:ST|ND|RD|TH) DAY\] [A-Z]+, ([A-Z]+) (\d{1,2}), (\d{4}) (\d+)$/.exec(t);
    const even = /^(\d+) JOURNAL OF THE SENATE \[(\d+)(?:ST|ND|RD|TH) DAY$/.exec(t);
    if (odd) {
      const mo = MN_MONTHS.indexOf(odd[2]);
      if (mo < 0 || Number(odd[5]) <= page) return fail(`a running head out of order: ${t}`);
      dates.add(`${odd[4]}-${String(mo + 1).padStart(2, '0')}-${odd[3].padStart(2, '0')}`);
      days.add(odd[1]);
      page = Number(odd[5]);
      continue;
    }
    if (even) {
      if (Number(even[1]) <= page) return fail(`a running head out of order: ${t}`);
      days.add(even[2]);
      page = Number(even[1]);
      continue;
    }
    if (!page) continue; // the first page's masthead
    lines.push({ page, cells: c, text: t });
  }
  if (dates.size !== 1 || days.size !== 1) return fail(`the journal's running heads print ${dates.size} dates and ${days.size} days`);
  const date = [...dates][0];
  const file = r.file.split('/')[1];
  if (!file.startsWith(date.replace(/-/g, '')) || Number(file.slice(8).replace(/_ss\d$/, '')) !== Number([...days][0])) return fail(`the journal is day ${[...days][0]} of ${date}, not the file ${file}`);
  const bill = `${r.billType} ${r.billNum}`;
  const found: MnVoteRecord[] = [];
  for (let i = 0; i < lines.length; i++) {
    const tm = /^The roll was called, and there were yeas (\d+) and nays (\d+), as follows:$/.exec(lines[i].text);
    if (!tm) continue;
    // the reading and the question: the lines since the one that opens with a bill read the third time, at most eight back
    let start = -1;
    for (let k = i - 1; k >= Math.max(0, i - 8); k--) if (/^[HS]\.F\. No\. \d+ was read the third time\b/.test(lines[k].text)) { start = k; break; }
    if (start < 0) continue;
    // "read the third time, as amended, and placed" (2023) or "read the third time and placed" (2026, HF 4075)
    // a call of the Senate between the reading and the question is set aside (2026 SF 4067, page 9706)
    const prose = lines.slice(start, i).map((l) => l.text).join(' ')
      .replace(/ CALL OF THE SENATE Senator [\p{L}'’. -]+ imposed a call of the Senate for the balance of the proceedings on [HS]\.F\. No\. \d+\. The Sergeant at Arms was instructed to bring in the absent members\.(?= )/u, '');
    const pm = /^([HS])\.F\. No\. (\d+) was read the third time[^.]*?,? and placed on its (?:final passage|repassage)(?:, the objections of the Governor notwithstanding)?\. The question was taken on the (.+?)\.?$/.exec(prose)
      ?? /^([HS])\.F\. No\. (\d+) was read the third time[^.]*?\. The question being, "?(Shall .+?\?)"?$/.exec(prose);
    if (!pm) continue;
    const q = squash(pm[3]);
    if (!mnQuestionIsOnTheBill(q)) continue;
    if (`${pm[1]}F ${Number(pm[2])}` !== bill) continue;
    const want: Record<MnVote, number> = { Yea: Number(tm[1]), Nay: Number(tm[2]) };
    const groups: Record<MnVote, string[]> = { Yea: [], Nay: [] };
    let j = i + 1;
    let badGroup = '';
    for (const [v, heading] of [['Yea', 'Those who voted in the affirmative were:'], ['Nay', 'Those who voted in the negative were:']] as const) {
      if (lines[j]?.text !== heading) { if (want[v] === 0) continue; badGroup = `no "${heading}" after the ${v === 'Yea' ? 'tally' : 'yeas'}`; break; }
      j++;
      while (j < lines.length) {
        const l = lines[j];
        // a vote cast on behalf of members (Rule 40, 2020-2023): the sentence, then the names it lists, ending with "."
        if (/^Pursuant to Rule 40\b/.test(l.text)) {
          j++;
          while (j < lines.length && !/\.$/.test(lines[j - 1].text) && lines[j].cells.length === 1) j++;
          continue;
        }
        if (!l.cells.every((c) => MN_NAME.test(c)) || /^(?:Those|So|The) /.test(l.text)) break;
        groups[v].push(...l.cells);
        j++;
      }
    }
    if (badGroup) return fail(badGroup);
    const end = lines[j]?.text ?? '';
    if (lines[j - 1].page < r.page || lines[start].page > r.page) continue; // another vote of this bill on this day
    for (const v of MN_VOTES) if (groups[v].length !== want[v]) return fail(`the ${v} group lists ${groups[v].length} members and the tally prints ${want[v]}`);
    if (!/^So the bill\b.*\b(?:passed|repassed|failed|lost)\b/.test(end)) return fail(`the roll call does not end on the bill's result: ${end}`);
    const all = MN_VOTES.flatMap((v) => groups[v]);
    if (all.length > MN_SIZE.Senate) return fail('more members than the chamber has');
    if (new Set(all.map(mnKey)).size !== all.length) return fail('a member is listed twice');
    found.push({ state: 'MN', stateName: 'Minnesota', chamber: 'Senate', session: mnSession(r), page: r.page, bill, question: q.charAt(0).toUpperCase() + q.slice(1), date, groups });
  }
  if (found.length !== 1) return fail(`the journal holds ${found.length} roll calls on ${bill} that read as a vote on the bill and take in page ${r.page}`);
  return found[0];
}

function readMinnesota(bodies: string[], r: MnVoteRef): MnVoteRecord | { refused: string } {
  if (bodies.length !== 2) return { refused: 'not a journal and a member list' };
  const v = r.chamber === 'House' ? readMinnesotaHouse(bodies, r) : readMinnesotaSenate(bodies, r);
  if ('refused' in v) return v;
  const members = mnMembers(bodies[1], r.legislature, r.chamber);
  if (!members) return { refused: 'the member list did not read' };
  const strip = (l: string): string => l.replace(/^Spk\.\s+/, '');
  const labels = MN_VOTES.flatMap((k) => v.groups[k].map(strip));
  const names = mnMemberNames(labels, members, (l) => MN_LABEL_ALIASES[`${r.legislature}|${r.chamber}|${l}`]);
  let k = 0;
  const groups = Object.fromEntries(MN_VOTES.map((x) => [x, v.groups[x].map(() => names[k++])])) as Record<MnVote, string[]>;
  const keys = MN_VOTES.flatMap((x) => groups[x]).map(mnKey);
  if (new Set(keys).size !== keys.length) return { refused: 'two members render as one name' };
  return { ...v, groups };
}

const MN_SAID: Record<MnVote, string> = { Yea: 'voted Yea', Nay: 'voted Nay' };

export function renderMinnesotaVote(v: MnVoteRecord): string {
  return [
    `Minnesota ${v.chamber} vote of ${v.date}, journal page ${v.page} (${v.session}), ${v.bill}.`,
    `Question: ${v.question}`,
    MN_VOTES.map((k) => `${k} ${v.groups[k].length}`).join('; ') + '.',
    ...MN_VOTES.map((k) => `${k} (${v.groups[k].length}): ${v.groups[k].join('; ')}`.trim()),
  ].join('\n');
}

const MN_RENDER_HEAD = /^Minnesota (House|Senate) vote of (\d{4}-\d{2}-\d{2}), journal page (\d+) \((\d+(?:st|nd|rd|th) Legislature(?:, [A-Z][a-z]+ Special Session)?)\), ([HS]F \d+)\.$/;

function parseMinnesotaRender(text: string, url: string): MnVoteRecord | null {
  const r = parseMinnesotaVoteUrl(url);
  const rows = text.split('\n');
  const h = MN_RENDER_HEAD.exec(rows[0] ?? '');
  const q = /^Question: (.+)$/.exec(rows[1] ?? '');
  if (!r || !h || !q || rows.length !== 3 + MN_VOTES.length) return null;
  // a House address does not say whether the day was a special session's (the journal does): either label of its Legislature
  const sessionOk = r.chamber === 'House' ? h[4] === mnSession(r) || h[4].startsWith(`${mnSession(r)}, `) : h[4] === mnSession(r);
  if (h[1] !== r.chamber || Number(h[3]) !== r.page || !sessionOk || h[5] !== `${r.billType} ${r.billNum}`) return null;
  const groups = {} as Record<MnVote, string[]>;
  for (const [i, v] of MN_VOTES.entries()) {
    const m = new RegExp(`^${v} \\((\\d+)\\):(.*)$`).exec(rows[3 + i]);
    if (!m) return null;
    groups[v] = m[2].split(';').map((s) => s.trim()).filter(Boolean);
    if (groups[v].length !== Number(m[1])) return null;
  }
  if (rows[2] !== MN_VOTES.map((v) => `${v} ${groups[v].length}`).join('; ') + '.') return null;
  return { state: 'MN', stateName: 'Minnesota', chamber: r.chamber, session: h[4], page: r.page, bill: h[5], question: q[1], date: h[2], groups };
}

const MN_LINE = /^Minnesota (House|Senate) vote of (\d{4}-\d{2}-\d{2}), journal page (\d+) \((\d+(?:st|nd|rd|th) Legislature(?:, [A-Z][a-z]+ Special Session)?)\), ([HS]F \d+) - (.+?): (.+?) (voted Yea|voted Nay)\.$/;

export function formatMinnesotaVoteLine(l: MnVoteLine): string {
  return `Minnesota ${l.chamber} vote of ${l.date}, journal page ${l.page} (${l.session}), ${l.bill} - ${l.question}: ${l.name} ${MN_SAID[l.vote]}.`;
}

function parseMinnesotaLine(text: string): MnVoteLine | null {
  const m = MN_LINE.exec(text.trim());
  const vote = m ? MN_VOTES.find((v) => MN_SAID[v] === m[8]) : undefined;
  if (!m || !vote) return null;
  return { state: 'MN', stateName: 'Minnesota', chamber: m[1] as Chamber, date: m[2], page: Number(m[3]), session: m[4], bill: m[5], question: m[6], name: m[7].trim(), vote };
}

function verifyMinnesotaLine(line: string, url: string, text: string, lastName: string, fullName: string): SnippetVerdict {
  const l = parseMinnesotaLine(line);
  const r = parseMinnesotaRender(text, url);
  if (!l || !r) return { verdict: 'snippet_not_found' };
  if (l.page !== r.page || l.chamber !== r.chamber || l.session !== r.session || l.bill !== r.bill || l.date !== r.date) return { verdict: 'snippet_not_found' };
  if (normalizeText(l.question) !== normalizeText(r.question)) return { verdict: 'snippet_not_found' };
  if (!r.groups[l.vote].some((n) => sameLabel(n, l.name))) return { verdict: 'snippet_not_found' };
  const fits = MN_VOTES.flatMap((v) => r.groups[v]).filter((n) => fullNameLabelFits(n, lastName, fullName));
  if (fits.length !== 1 || !sameLabel(fits[0], l.name)) return { verdict: 'name_not_present' };
  return { verdict: 'verified', matchOffset: 0 };
}

function minnesotaLinesFor(url: string, text: string, lastName: string, fullName: string): string[] {
  const r = parseMinnesotaRender(text, url);
  if (!r) return [];
  const out: string[] = [];
  for (const vote of MN_VOTES) {
    for (const name of r.groups[vote]) {
      if (fullNameLabelFits(name, lastName, fullName)) out.push(formatMinnesotaVoteLine({ ...r, name, vote }));
    }
  }
  return out.length === 1 ? out : [];
}

/** The vote an address names, read from the day's journal and the LRL member list. Null when any check fails. */
export function readMinnesotaVote(bodies: string[], url: string): MnVoteRecord | null {
  const v = explainMinnesotaVote(bodies, url);
  return 'refused' in v ? null : v;
}

/** As readMinnesotaVote, with the reason a vote is refused: for the fetch tool's report and the tests. */
export function explainMinnesotaVote(bodies: string[], url: string): MnVoteRecord | { refused: string } {
  const r = parseMinnesotaVoteUrl(url);
  if (!r) return { refused: 'not a Minnesota vote address' };
  try { return readMinnesota(bodies, r); } catch (e) { return { refused: `the reader failed: ${e instanceof Error ? e.message : e}` }; }
}

/** How a fetched PDF reaches its reader: Maryland's and Minnesota's as cells (pdfCellsBody), every other state's as lines (pdfLinesBody). */
export function pdfBodyFor(url: string, items: { page: number; x: number; y: number; str: string; dir?: number }[]): string {
  return /^https:\/\/mgaleg\.maryland\.gov\/20\d{2}RS\/votes\/|^https:\/\/www\.mnsenate\.gov\/journals\//i.test(url.trim()) ? pdfCellsBody(items) : pdfLinesBody(items);
}

function formatOf(url: string): { f: Format; ref: StateRollCallRef } | null {
  for (const f of FORMATS) {
    const r = f.ref(url.trim());
    if (r) return { f, ref: { state: f.state, stateName: f.stateName, ...r } };
  }
  return null;
}

export function parseStateRollCallUrl(url: string): StateRollCallRef | null {
  return formatOf(url)?.ref ?? null;
}

/** The wait to leave between two fetches of this site's roll-call pages; 0 for any other address. */
export function stateRollCallMinGapMs(url: string): number {
  if (parseOhioVoteUrl(url)) return OH_GAP_MS;
  if (parseSouthDakotaVoteUrl(url)) return SD_GAP_MS;
  if (parseMississippiVoteUrl(url)) return MS_GAP_MS;
  if (parseMarylandVoteUrl(url)) return MD_GAP_MS;
  if (parseKansasVoteUrl(url)) return KS_GAP_MS;
  if (parseColoradoVoteUrl(url)) return CO_GAP_MS;
  if (parseNorthDakotaVoteUrl(url)) return ND_GAP_MS;
  if (parseMinnesotaVoteUrl(url)) return MN_GAP_MS;
  return formatOf(url)?.f.minGapMs ?? 0;
}

export function isStateRollCallUrl(url: string): boolean {
  return formatOf(url) !== null || parseOhioVoteUrl(url) !== null || parseSouthDakotaVoteUrl(url) !== null || parseMississippiVoteUrl(url) !== null || parseMarylandVoteUrl(url) !== null || parseKansasVoteUrl(url) !== null || parseColoradoVoteUrl(url) !== null || parseNorthDakotaVoteUrl(url) !== null || parseMinnesotaVoteUrl(url) !== null;
}

/**
 * The documents to fetch to read the vote an address names, in order: the cited page itself, and for a state
 * whose page holds many votes and no motion (Ohio), the data and member list that prove it. Null for any other
 * address.
 */
export function stateRollCallDocs(url: string): string[] | null {
  const oh = parseOhioVoteUrl(url);
  if (oh) return ohioDocs(oh);
  const sd = parseSouthDakotaVoteUrl(url);
  if (sd) return [`${SD_DATA}${sd.voteId}`];
  const ms = parseMississippiVoteUrl(url);
  if (ms) return mississippiDocs(ms);
  const md = parseMarylandVoteUrl(url);
  if (md) return marylandDocs(md);
  if (parseKansasVoteUrl(url)) return [url.trim()];
  const co = parseColoradoVoteUrl(url);
  if (co) return coloradoDocs(co);
  const nd = parseNorthDakotaVoteUrl(url);
  if (nd) return northDakotaDocs(nd);
  const mn = parseMinnesotaVoteUrl(url);
  if (mn) return minnesotaDocs(mn);
  return formatOf(url) ? [url.trim()] : null;
}

/** The render of the vote an address names, from the bodies of stateRollCallDocs(url) in order; null when any check fails. */
export function readStateRollCallDocs(bodies: string[], url: string): string | null {
  const oh = parseOhioVoteUrl(url);
  if (oh) {
    try { const v = readOhio(bodies, oh); return v ? renderOhioVote(v) : null; } catch { return null; }
  }
  if (parseSouthDakotaVoteUrl(url)) {
    const v = readSouthDakotaVote(bodies, url);
    return v ? renderSouthDakotaVote(v) : null;
  }
  if (parseMississippiVoteUrl(url)) {
    const v = readMississippiVote(bodies, url);
    return v ? renderMississippiVote(v) : null;
  }
  if (parseMarylandVoteUrl(url)) {
    const v = readMarylandVote(bodies, url);
    return v ? renderMarylandVote(v) : null;
  }
  if (parseKansasVoteUrl(url)) {
    const v = readKansasVote(bodies, url);
    return v ? renderKansasVote(v) : null;
  }
  if (parseColoradoVoteUrl(url)) {
    const v = readColoradoVote(bodies, url);
    return v ? renderColoradoVote(v) : null;
  }
  if (parseNorthDakotaVoteUrl(url)) {
    const v = readNorthDakotaVote(bodies, url);
    return v ? renderNorthDakotaVote(v) : null;
  }
  if (parseMinnesotaVoteUrl(url)) {
    const v = readMinnesotaVote(bodies, url);
    return v ? renderMinnesotaVote(v) : null;
  }
  if (bodies.length !== 1) return null;
  const r = readStateRollCallHtml(bodies[0], url);
  return r ? renderStateRollCall(r) : null;
}

/**
 * The vote an address names, in the supplement's shape (fetch-legislature-rollcalls.ts): bill, question, day, chamber
 * and members under Yea, Nay and absent. Ohio lists no absent member, so its absent group is empty.
 */
export function readStateRollCallRecord(bodies: string[], url: string): StateRollCall | null {
  const oh = parseOhioVoteUrl(url);
  if (oh) {
    let v: OhioVoteRecord | null;
    try { v = readOhio(bodies, oh); } catch { return null; }
    return v ? { state: v.state, stateName: v.stateName, chamber: v.chamber, session: v.session, rollNum: 0, bill: v.bill, question: v.question,
      date: v.date, groups: { Yea: v.groups.Yea, Nay: v.groups.Nay, 'Absent or not voting': [] } } : null;
  }
  if (parseSouthDakotaVoteUrl(url)) {
    // South Dakota: members by the data's UniqueName, the label Open States stores for them, so convert.py links a
    // member read here the way it links the same member in the dump. Excused, absent and not voting are one group here.
    const v = readSouthDakotaVote(bodies, url);
    return v ? { state: v.state, stateName: v.stateName, chamber: v.chamber, session: v.session, rollNum: v.voteId, bill: v.bill, question: v.question,
      date: v.date, groups: { Yea: v.unique.Yea, Nay: v.unique.Nay, 'Absent or not voting': [...v.unique.Excused, ...v.unique.Absent, ...v.unique['Not voting'], ...v.unique.Present, ...v.unique.Suspended] } } : null;
  }
  if (parseMississippiVoteUrl(url)) {
    // Mississippi: members by their full names from the session's member list. Absent and present are one group here.
    const v = readMississippiVote(bodies, url);
    return v ? { state: v.state, stateName: v.stateName, chamber: v.chamber, session: v.session, rollNum: Number(v.voteNo), bill: v.bill, question: v.question,
      date: v.date, groups: { Yea: v.groups.Yea, Nay: v.groups.Nay, 'Absent or not voting': [...v.groups['Absent or not voting'], ...v.groups.Present, ...v.groups.Paired] } } : null;
  }
  if (parseMarylandVoteUrl(url)) {
    // Maryland: members by their full names from the committee lists (a label no member fits, as printed). Not voting,
    // excused and absent are one group here.
    const v = readMarylandVote(bodies, url);
    return v ? { state: v.state, stateName: v.stateName, chamber: v.chamber, session: v.session, rollNum: v.seq, bill: v.bill, question: v.question,
      date: v.date, groups: { Yea: v.groups.Yea, Nay: v.groups.Nay, 'Absent or not voting': [...v.groups['Not voting'], ...v.groups.Excused, ...v.groups.Absent] } } : null;
  }
  if (parseKansasVoteUrl(url)) {
    // Kansas: members by the names rendered from their member ids (a member whose id does not fit, as printed). Present,
    // absent and not voting are one group here.
    const v = readKansasVote(bodies, url);
    return v ? { state: v.state, stateName: v.stateName, chamber: v.chamber, session: v.session, rollNum: 0, bill: v.bill, question: v.question,
      date: v.date, groups: { Yea: v.groups.Yea, Nay: v.groups.Nay, 'Absent or not voting': [...v.groups.Present, ...v.groups.Absent, ...v.groups['Not voting']] } } : null;
  }
  if (parseColoradoVoteUrl(url)) {
    // Colorado: members by their full names from the session's member list (a label no member fits, as printed). Absent
    // and excused are one group here.
    const v = readColoradoVote(bodies, url);
    return v ? { state: v.state, stateName: v.stateName, chamber: v.chamber, session: v.session, rollNum: v.voteId, bill: v.bill, question: v.question,
      date: v.date, groups: { Yea: v.groups.Yes, Nay: v.groups.No, 'Absent or not voting': [...v.groups.Absent, ...v.groups.Excused] } } : null;
  }
  if (parseNorthDakotaVoteUrl(url)) {
    // North Dakota: members by their full names from the Assembly's member list (a label no member fits, as printed); the
    // roll-call number is the journal page
    const v = readNorthDakotaVote(bodies, url);
    return v ? { state: v.state, stateName: v.stateName, chamber: v.chamber, session: v.session, rollNum: v.page, bill: v.bill, question: v.question,
      date: v.date, groups: { Yea: v.groups.Yea, Nay: v.groups.Nay, 'Absent or not voting': v.groups['Absent or excused'] } } : null;
  }
  if (parseMinnesotaVoteUrl(url)) {
    // Minnesota: members by their full names from the LRL member list (a label no member fits, or several, as printed);
    // the roll-call number is the journal page. The journals name no absent member, so the absent group is empty.
    const v = readMinnesotaVote(bodies, url);
    return v ? { state: v.state, stateName: v.stateName, chamber: v.chamber, session: v.session, rollNum: v.page, bill: v.bill, question: v.question,
      date: v.date, groups: { Yea: v.groups.Yea, Nay: v.groups.Nay, 'Absent or not voting': [] } } : null;
  }
  return bodies.length === 1 ? readStateRollCallHtml(bodies[0], url) : null;
}

/** Read a roll-call page's markup. Null when the address is not a roll-call page we know, or any count disagrees. */
export function readStateRollCallHtml(html: string, url: string): StateRollCall | null {
  const hit = formatOf(url);
  if (!hit) return null;
  try { return hit.f.read(html, hit.ref); } catch { return null; }
}

// ── render ↔ parse ────────────────────────────────────────────────────────────────────────────────

/** The fixed text the adapter hands the verifier. It prints no party: the page prints none. */
export function renderStateRollCall(r: StateRollCall): string {
  return [
    `${r.stateName} ${r.chamber} roll call ${r.rollNum} (${r.session}), ${r.date}.`,
    `Question: ${r.bill} - ${r.question}`,
    STATE_VOTES.map((v) => `${v} ${r.groups[v].length}`).join('; ') + '.',
    ...STATE_VOTES.map((v) => `${v} (${r.groups[v].length}): ${r.groups[v].join('; ')}`.trim()),
  ].join('\n');
}

const RENDER_HEAD = /^(.+) (House|Senate) roll call (\d+) \(([A-Za-z0-9]+)\), (\d{4}-\d{2}-\d{2})\.$/;

export function parseStateRollCallRender(text: string, url: string): StateRollCall | OhioVoteRecord | Omit<SdVoteRecord, 'unique'> | Omit<MsVoteRecord, 'billType' | 'billNum'> | MdVoteRecord | KsVoteRecord | CoVoteRecord | NdVoteRecord | MnVoteRecord | null {
  if (parseMinnesotaVoteUrl(url)) return parseMinnesotaRender(text, url);
  if (parseMarylandVoteUrl(url)) return parseMarylandRender(text, url);
  if (parseNorthDakotaVoteUrl(url)) return parseNorthDakotaRender(text, url);
  if (parseColoradoVoteUrl(url)) return parseColoradoRender(text, url);
  if (parseKansasVoteUrl(url)) return parseKansasRender(text, url);
  if (parseOhioVoteUrl(url)) return parseOhioRender(text, url);
  if (parseSouthDakotaVoteUrl(url)) return parseSouthDakotaRender(text, url);
  if (parseMississippiVoteUrl(url)) return parseMississippiRender(text, url);
  return parseUtahRender(text, url);
}

function parseUtahRender(text: string, url: string): StateRollCall | null {
  const ref = parseStateRollCallUrl(url);
  const rows = text.split('\n');
  const h = RENDER_HEAD.exec(rows[0] ?? '');
  const q = /^Question: (\S+ \d+) - (.+)$/.exec(rows[1] ?? '');
  if (!ref || !h || !q || rows.length !== 3 + STATE_VOTES.length) return null;
  if (h[1] !== ref.stateName || h[2] !== ref.chamber || Number(h[3]) !== ref.rollNum || h[4] !== ref.session) return null;
  const groups = {} as Record<StateVote, string[]>;
  for (const [i, v] of STATE_VOTES.entries()) {
    const m = new RegExp(`^${v} \\((\\d+)\\):(.*)$`).exec(rows[3 + i]);
    if (!m) return null;
    groups[v] = m[2].split(';').map((s) => s.trim()).filter(Boolean);
    if (groups[v].length !== Number(m[1])) return null;
  }
  if (rows[2] !== STATE_VOTES.map((v) => `${v} ${groups[v].length}`).join('; ') + '.') return null;
  return { ...ref, bill: q[1], question: q[2], date: h[5], groups };
}

const LINE = /^(.+) (House|Senate) roll call (\d+) \(([A-Za-z0-9]+)\), (\S+ \d+) - (.+) \((\d{4}-\d{2}-\d{2})\): (.+?) (voted Yea|voted Nay|was absent or not voting)\.$/;
const SAID: Record<StateVote, string> = { Yea: 'voted Yea', Nay: 'voted Nay', 'Absent or not voting': 'was absent or not voting' };

export function formatStateRollCallLine(l: StateRollCallLine): string {
  return `${l.stateName} ${l.chamber} roll call ${l.rollNum} (${l.session}), ${l.bill} - ${l.question} (${l.date}): ${l.name} ${SAID[l.vote]}.`;
}

export function parseStateRollCallLine(text: string): StateRollCallLine | OhioVoteLine | SdVoteLine | MsVoteLine | MdVoteLine | KsVoteLine | CoVoteLine | NdVoteLine | MnVoteLine | null {
  return parseUtahLine(text) ?? parseOhioLine(text) ?? parseSouthDakotaLine(text) ?? parseMississippiLine(text) ?? parseMarylandLine(text) ?? parseKansasLine(text) ?? parseColoradoLine(text) ?? parseNorthDakotaLine(text) ?? parseMinnesotaLine(text);
}

function parseUtahLine(text: string): StateRollCallLine | null {
  const m = LINE.exec(text.trim());
  if (!m) return null;
  const f = FORMATS.find((x) => x.stateName === m[1]);
  const vote = STATE_VOTES.find((v) => SAID[v] === m[9]);
  if (!f || !vote) return null;
  return { state: f.state, stateName: m[1], chamber: m[2] as Chamber, rollNum: Number(m[3]), session: m[4], bill: m[5],
    question: m[6], date: m[7], name: m[8].trim(), vote };
}

// ── whose label is it ─────────────────────────────────────────────────────────────────────────────

const fold = (s: string): string => normalizeText(s).replace(/[-.,]/g, ' ').replace(/\s+/g, ' ').trim();
/**
 * A generational suffix closes a whole name ("Ryan D. Wilcox, Jr."). It is dropped there and nowhere else: a
 * printed initial can be the same letters ("Mauga, V.", "Peterson, V."), and dropping it loses the member.
 * Utah pilot, 2026-11-15: both of those members got no line on any of their 110 votes.
 */
const dropSuffix = (folded: string): string => folded.replace(/ (jr|sr|ii|iii|iv|v)$/, '');

/**
 * Does the label a roll call prints ("Snider, C.", "Maloy, A. Cory", "Adams, J. Stuart") belong to this
 * politician? The surname must be theirs. Then one of: a whole given name the page prints is one of theirs
 * (or a nickname of it), or the page's first initial is the first letter of a given name of theirs.
 */
export function stateLabelFits(printed: string, lastName: string, fullName: string): boolean {
  const m = splitLabel(printed);
  if (!m) return false;
  const sur = fold(m[0]);
  const last = fold(lastName);
  const quoted = [...fullName.matchAll(/["“]([^"”]+)["”]/g)].map((x) => fold(x[1])).filter(Boolean);
  const full = dropSuffix(fold(fullName.replace(/["“][^"”]*["”]/g, ' ')));
  if (!sur || (sur !== last && !(full === sur || full.endsWith(` ${sur}`)))) return false;
  const given = [...(full.endsWith(` ${sur}`) ? full.slice(0, -sur.length - 1) : full).split(' '), ...quoted].filter(Boolean);
  // "C.K." is two initials; "J. Stuart" an initial and a name.
  const printedGiven = m[1].replace(/\./g, ' ').split(/\s+/).map(fold).filter(Boolean);
  if (!given.length || !printedGiven.length) return false;
  const whole = printedGiven.filter((w) => w.length > 1);
  if (whole.some((w) => given.some((g) => g.length > 1 && (g === w || getNameVariants(g).includes(w) || getNameVariants(w).includes(g))))) return true;
  // A whole name the page prints that is none of theirs names someone else ("Maloy, A. Cory" is not Angela Maloy).
  if (whole.length) return false;
  return given.some((g) => g[0] === printedGiven[0][0]);
}

const sameLabel = (a: string, b: string): boolean => normalizeText(a) === normalizeText(b);

/**
 * Check a canonical line against the render fetched for `url`. `verified` (offset 0) when every field
 * matches; `name_not_present` when the page holds the vote under a label that is not this politician's, or
 * that a second label of the roll call also fits; otherwise `snippet_not_found`.
 */
/** Another full name a person is published under (a former or married name), with its surname. */
export interface OtherName { fullName: string; lastName: string }

/**
 * {@link verifyOneName} under the person's own name, then under each other name they are published under
 * (`essentials.politicians.alternate_names`). A roll call prints the name a member held on the day: Maryland's 2023
 * votes print "White" for the member the roster calls White Holland, and her vote got no line (md-01, 2026-11-18).
 * Another name is tried only when the person's own name is not on the page, and it must pass the same test: exactly
 * one label of the roll call fits it.
 */
export function verifyStateRollCallLine(line: string, url: string, text: string, lastName: string, fullName: string, otherNames: readonly OtherName[] = []): SnippetVerdict {
  const first = verifyOneName(line, url, text, lastName, fullName);
  if (first.verdict !== 'name_not_present') return first;
  for (const o of otherNames) {
    const v = verifyOneName(line, url, text, o.lastName, o.fullName);
    if (v.verdict === 'verified') return v;
  }
  return first;
}

function verifyOneName(line: string, url: string, text: string, lastName: string, fullName: string): SnippetVerdict {
  if (parseOhioVoteUrl(url)) return verifyOhioLine(line, url, text, lastName, fullName);
  if (parseSouthDakotaVoteUrl(url)) return verifySouthDakotaLine(line, url, text, lastName, fullName);
  if (parseMississippiVoteUrl(url)) return verifyMississippiLine(line, url, text, lastName, fullName);
  if (parseMarylandVoteUrl(url)) return verifyMarylandLine(line, url, text, lastName, fullName);
  if (parseKansasVoteUrl(url)) return verifyKansasLine(line, url, text, lastName, fullName);
  if (parseColoradoVoteUrl(url)) return verifyColoradoLine(line, url, text, lastName, fullName);
  if (parseNorthDakotaVoteUrl(url)) return verifyNorthDakotaLine(line, url, text, lastName, fullName);
  if (parseMinnesotaVoteUrl(url)) return verifyMinnesotaLine(line, url, text, lastName, fullName);
  const l = parseUtahLine(line);
  const r = parseUtahRender(text, url);
  if (!l || !r) return { verdict: 'snippet_not_found' };
  if (l.state !== r.state || l.chamber !== r.chamber || l.rollNum !== r.rollNum || l.session !== r.session) return { verdict: 'snippet_not_found' };
  if (l.bill !== r.bill || l.date !== r.date || normalizeText(l.question) !== normalizeText(r.question)) return { verdict: 'snippet_not_found' };
  if (!r.groups[l.vote].some((n) => sameLabel(n, l.name))) return { verdict: 'snippet_not_found' };
  const fits = STATE_VOTES.flatMap((v) => r.groups[v]).filter((n) => stateLabelFits(n, lastName, fullName));
  if (fits.length !== 1 || !sameLabel(fits[0], l.name)) return { verdict: 'name_not_present' };
  return { verdict: 'verified', matchOffset: 0 };
}

/** The canonical line the render holds for this politician: one, or none when no label or several fit. */
export function stateRollCallLinesFor(url: string, text: string, lastName: string, fullName: string, otherNames: readonly OtherName[] = []): string[] {
  const own = linesForOneName(url, text, lastName, fullName);
  if (own.length || !otherNames.length) return own;
  // no label fits the person's own name: the names they are also published under, and only when they agree on one line
  const other = new Set(otherNames.flatMap((o) => linesForOneName(url, text, o.lastName, o.fullName)));
  return other.size === 1 ? [...other] : [];
}

function linesForOneName(url: string, text: string, lastName: string, fullName: string): string[] {
  if (parseOhioVoteUrl(url)) return ohioLinesFor(url, text, lastName, fullName);
  if (parseSouthDakotaVoteUrl(url)) return southDakotaLinesFor(url, text, lastName, fullName);
  if (parseMississippiVoteUrl(url)) return mississippiLinesFor(url, text, lastName, fullName);
  if (parseMarylandVoteUrl(url)) return marylandLinesFor(url, text, lastName, fullName);
  if (parseKansasVoteUrl(url)) return kansasLinesFor(url, text, lastName, fullName);
  if (parseColoradoVoteUrl(url)) return coloradoLinesFor(url, text, lastName, fullName);
  if (parseNorthDakotaVoteUrl(url)) return northDakotaLinesFor(url, text, lastName, fullName);
  if (parseMinnesotaVoteUrl(url)) return minnesotaLinesFor(url, text, lastName, fullName);
  const r = parseUtahRender(text, url);
  if (!r) return [];
  const out: string[] = [];
  for (const vote of STATE_VOTES) {
    for (const name of r.groups[vote]) {
      if (stateLabelFits(name, lastName, fullName)) out.push(formatStateRollCallLine({ ...r, name, vote }));
    }
  }
  return out.length === 1 ? out : [];
}

// ── Ohio: whose name is it, and the line ──────────────────────────────────────────────────────────────

/**
 * Does a full printed name ("Cindy Abrams", "P. Scott Lipps", "Joseph A. Miller, III", "Monica Robb Blasdel") belong
 * to this politician? It must end with their surname (their last name, or the last word of their full name). Then
 * a whole given name the page prints before it is one of theirs (or a nickname of it); or, when the page prints
 * only initials there, the first is the first letter of a given name of theirs. A whole name the page prints
 * that is none of theirs names someone else ("Kevin D. Miller" is not Melanie Miller).
 */
export function fullNameLabelFits(printed: string, lastName: string, fullName: string): boolean {
  // A nickname in quotes is not a given name, on either side: Mississippi's 2026 list prints 'W.I. "Doc" Harris'
  // for "W. I. Harris". Out of the printed words, it may still match a given name or the person's own nickname.
  const printedQuoted = [...printed.matchAll(/["“]([^"”]+)["”]/g)].map((x) => fold(x[1])).filter(Boolean);
  const words = dropSuffix(fold(printed.replace(/["“][^"”]*["”]/g, ' '))).split(' ').filter(Boolean);
  const quoted = [...fullName.matchAll(/["“]([^"”]+)["”]/g)].map((x) => fold(x[1])).filter(Boolean);
  const full = dropSuffix(fold(fullName.replace(/["“][^"”]*["”]/g, ' '))).split(' ').filter(Boolean);
  const surnames = [...new Set([dropSuffix(fold(lastName)), full[full.length - 1] ?? ''].filter(Boolean))];
  for (const sur of surnames) {
    const sw = sur.split(' ');
    if (words.length <= sw.length || words.slice(-sw.length).join(' ') !== sur) continue;
    const printedGiven = words.slice(0, -sw.length);
    const fs = full.length > sw.length && full.slice(-sw.length).join(' ') === sur ? full.slice(0, -sw.length) : full.slice(0, -1);
    const given = [...fs, ...quoted].filter(Boolean);
    if (!given.length) continue;
    const whole = printedGiven.filter((w) => w.length > 1);
    const fits = (w: string) => given.some((g) => g.length > 1 && (g === w || getNameVariants(g).includes(w) || getNameVariants(w).includes(g)));
    if (printedQuoted.some(fits)) return true;
    if (whole.length) {
      if (whole.some(fits)) return true;
      continue;
    }
    if (printedGiven.length && given.some((g) => g[0] === printedGiven[0][0])) return true;
  }
  return false;
}

function verifyOhioLine(line: string, url: string, text: string, lastName: string, fullName: string): SnippetVerdict {
  const l = parseOhioLine(line);
  const r = parseOhioRender(text, url);
  if (!l || !r) return { verdict: 'snippet_not_found' };
  if (l.chamber !== r.chamber || l.date !== r.date || l.session !== r.session || l.bill !== r.bill || l.yea !== r.yea || l.nay !== r.nay) return { verdict: 'snippet_not_found' };
  if (normalizeText(l.question) !== normalizeText(r.question)) return { verdict: 'snippet_not_found' };
  if (!r.groups[l.vote].some((n) => sameLabel(n, l.name))) return { verdict: 'snippet_not_found' };
  const fits = OH_VOTES.flatMap((v) => r.groups[v]).filter((n) => fullNameLabelFits(n, lastName, fullName));
  if (fits.length !== 1 || !sameLabel(fits[0], l.name)) return { verdict: 'name_not_present' };
  return { verdict: 'verified', matchOffset: 0 };
}

function ohioLinesFor(url: string, text: string, lastName: string, fullName: string): string[] {
  const r = parseOhioRender(text, url);
  if (!r) return [];
  const out: string[] = [];
  for (const vote of OH_VOTES) {
    for (const name of r.groups[vote]) {
      if (fullNameLabelFits(name, lastName, fullName)) out.push(formatOhioVoteLine({ ...r, name, vote }));
    }
  }
  return out.length === 1 ? out : [];
}
