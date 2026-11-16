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
 * results agree, the vote is not a committee report, and every id maps to the name the page prints, in that
 * chamber. Anything else gives no line. Ohio's render and line:
 *
 *   Ohio House vote of 2024-06-12 (135th General Assembly), HB 327, 85-6.
 *   Question: Passed
 *   Yea (85): Cindy Abrams; …
 *   Ohio House vote of 2024-06-12 (135th General Assembly), HB 327 - Passed, 85-6: Cindy Abrams voted Yea.
 *
 * A member who did not vote is on no list in Ohio, so the render has no absent group and gives no finding.
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
  return formatOf(url)?.f.minGapMs ?? 0;
}

export function isStateRollCallUrl(url: string): boolean {
  return formatOf(url) !== null || parseOhioVoteUrl(url) !== null;
}

/**
 * The documents to fetch to read the vote an address names, in order: the cited page itself, and for a state
 * whose page holds many votes and no motion (Ohio), the data and member list that prove it. Null for any other
 * address.
 */
export function stateRollCallDocs(url: string): string[] | null {
  const oh = parseOhioVoteUrl(url);
  if (oh) return ohioDocs(oh);
  return formatOf(url) ? [url.trim()] : null;
}

/** The render of the vote an address names, from the bodies of stateRollCallDocs(url) in order; null when any check fails. */
export function readStateRollCallDocs(bodies: string[], url: string): string | null {
  const oh = parseOhioVoteUrl(url);
  if (oh) {
    try { const v = readOhio(bodies, oh); return v ? renderOhioVote(v) : null; } catch { return null; }
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

export function parseStateRollCallRender(text: string, url: string): StateRollCall | OhioVoteRecord | null {
  if (parseOhioVoteUrl(url)) return parseOhioRender(text, url);
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

export function parseStateRollCallLine(text: string): StateRollCallLine | OhioVoteLine | null {
  return parseUtahLine(text) ?? parseOhioLine(text);
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
export function verifyStateRollCallLine(line: string, url: string, text: string, lastName: string, fullName: string): SnippetVerdict {
  if (parseOhioVoteUrl(url)) return verifyOhioLine(line, url, text, lastName, fullName);
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
export function stateRollCallLinesFor(url: string, text: string, lastName: string, fullName: string): string[] {
  if (parseOhioVoteUrl(url)) return ohioLinesFor(url, text, lastName, fullName);
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
  const words = dropSuffix(fold(printed)).split(' ').filter(Boolean);
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
    if (whole.length) {
      if (whole.some((w) => given.some((g) => g.length > 1 && (g === w || getNameVariants(g).includes(w) || getNameVariants(w).includes(g))))) return true;
      continue;
    }
    if (given.some((g) => g[0] === printedGiven[0][0])) return true;
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
