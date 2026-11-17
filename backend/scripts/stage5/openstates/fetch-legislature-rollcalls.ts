/**
 * fetch-legislature-rollcalls — read, from a legislature's own site, the floor roll calls an Open States dump
 * does not hold, for the bills named.
 *
 *   npx tsx scripts/stage5/openstates/fetch-legislature-rollcalls.ts <st> <session> <work dir> --bills "HB 133,SB 14"
 *   npx tsx scripts/stage5/openstates/fetch-legislature-rollcalls.ts <st> <session> <work dir> --bills-file bills.txt
 *
 * <session> is the Open States identifier of the session ("2025"). The bills are whatever the caller's scan found;
 * this tool knows no topic. It writes <work dir>/supplements/<ST>/<session>.json, which convert.py merges on its
 * next run. A second run adds to that file: a bill named again is read again and replaces its entry.
 *
 * Why (Utah, 2026-11 dump): the 2025 General Session has 959 bills and 0 roll calls in the dump, while the
 * sessions either side are full. The legislature publishes, for each bill, a data file that lists every vote with
 * its number, chamber and tally, and a page for each vote.
 *
 * Ohio's Votes page holds every vote of a bill and no motion, so there the roll call's "page" is three documents read
 * together by the verifier's reader: the Votes page, the bill's action list and the member list.
 *
 * Two documents are read for each roll call and must agree, or the roll call is REFUSED and listed:
 *   - the bill's data file: which votes the bill had, and each one's tally;
 *   - the roll call's own page, through the verifier's reader (stateRollCallEvidence.ts), which itself refuses a
 *     page whose member lists do not add up to its printed tally.
 * The page must name the same bill, and its tally must be the data file's.
 *
 * Every request waits the site's crawl delay. Bodies are kept under supplements/<ST>/raw/, so a second run asks the
 * site for nothing it already has (pass --refetch to ask again).
 *
 * A state is one entry in INDEX: where a bill's vote list is, and how to read it.
 */
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { decodeHtmlBytes, EMPOWERED_VOTE_UA } from '../../../src/lib/verificationFetch.js';
import { fetchWithHostTrust } from '../../../src/lib/adapters/hostTrust.js';
import { extractPdfText, looksLikePdfBytes } from '../../../src/lib/pdfText.js';
import { isStateRollCallUrl, readStateRollCallRecord, sdQuestionIsOnTheBill, SD_SESSIONS, stateRollCallDocs, stateRollCallMinGapMs, type StateRollCall } from '../../../src/lib/stateRollCallEvidence.js';

/** One floor roll call as a bill's vote list gives it. */
export interface IndexedVote { url: string; motion: string; tally: [number, number, number] }
/** motion: votes on a motion, not on the bill (Ohio motion_...: "Informally passed"), counted and not read. */
export interface BillIndex { floor: IndexedVote[]; committee: number; voice: number; motion?: number; motions?: string[]; committeeUrls?: string[] }
interface StateIndex {
  /** The least time between two requests to the site (its robots.txt Crawl-delay). */
  minGapMs: number;
  /** The address of the bill's vote list, or null when the session or bill is not one this site can name. */
  billUrl: (_session: string, _bill: string) => string | null;
  /** Read the vote list. Throws when the document is not the bill asked for. */
  read: (_body: string, _session: string, _bill: string) => BillIndex;
  /**
   * A site that names a bill's vote list by its own bill id (South Dakota): the session's bill list, read first, and
   * the vote-list address taken from it. Throws when the list does not hold the bill exactly once.
   */
  listUrl?: (_session: string) => string | null;
  billUrlFromList?: (_list: string, _session: string, _bill: string) => string;
}

const UT_BILL = /^([HS])\.?([A-Z])?\.?([A-Z])?\.?\s*0*(\d{1,4})$/i;
function utSession(session: string): string | null {
  if (/^\d{4}$/.test(session)) return `${session}GS`; // Open States calls the General Session by its year
  return /^\d{4}S\d{1,2}$/.test(session) ? session : null;
}
function utBill(bill: string): string | null {
  const m = UT_BILL.exec(bill.trim());
  return m ? `${[m[1], m[2], m[3]].filter(Boolean).join('').toUpperCase()}${m[4].padStart(4, '0')}` : null;
}

const OH_BILL = /^([HS])\.?\s*(B|R|J\.?\s*R|C\.?\s*R)\.?\s*0*([1-9]\d{0,3})$/i;
function ohBill(bill: string): string | null {
  const m = OH_BILL.exec(bill.trim());
  return m ? `${m[1]}${m[2].replace(/[.\s]/g, '')}${m[3]}`.toLowerCase() : null;
}

const SD_BILL = /^([HS](?:B|JR|CR|C|R))\s*0*([1-9]\d{0,4})$/i;
const SD_SESSION_ID = new Map(Object.entries(SD_SESSIONS).map(([id, name]) => [name, Number(id)]));

export const INDEX: Record<string, StateIndex> = {
  // sdlegislature.gov (read 2026-11-17). The site names a bill by its own id: /api/Bills/Session/Light/<SessionId> lists
  // the session's bills (BillId, BillType, BillNumberOnly), and /api/Bills/ActionLog/<BillId> lists every action. An
  // action with a Vote is a roll call: ActionCommittee.FullBody (House of Representatives, Senate) is the chamber's
  // floor vote, anything else a committee's. A floor vote on a motion (sdQuestionIsOnTheBill: to table, to defer to the
  // 41st day, ...) is not a vote on the bill. Each floor vote is cited on its own page, /Session/Vote/<VoteId>, and
  // read from /api/Votes/<VoteId> (stateRollCallEvidence.ts).
  SD: {
    minGapMs: 1_000, // robots.txt states no Crawl-delay: one a second is ours
    billUrl: () => null,
    listUrl(session) {
      const id = SD_SESSION_ID.get(session);
      return id ? `https://sdlegislature.gov/api/Bills/Session/Light/${id}` : null;
    },
    billUrlFromList(list, session, bill) {
      const m = SD_BILL.exec(bill.replace(/[\s.]+/g, ''));
      if (!m) throw new Error(`${bill} is not a South Dakota bill number`);
      const j = JSON.parse(list) as { BillId?: unknown; BillType?: unknown; BillNumberOnly?: unknown }[];
      if (!Array.isArray(j)) throw new Error(`the bill list of ${session} is not a list`);
      const hit = j.filter((b) => b.BillType === m[1].toUpperCase() && b.BillNumberOnly === Number(m[2]));
      if (hit.length !== 1 || typeof hit[0].BillId !== 'number') throw new Error(`the bill list of ${session} holds ${bill} ${hit.length} times`);
      return `https://sdlegislature.gov/api/Bills/ActionLog/${hit[0].BillId}`;
    },
    read(body, session, bill) {
      const j = JSON.parse(body) as { StatusText?: unknown; ActionCommittee?: { FullName?: unknown; FullBody?: unknown } | null; Vote?: Record<string, unknown> | null }[];
      if (!Array.isArray(j)) throw new Error(`the action log of ${session} ${bill} is not a list`);
      const out: BillIndex = { floor: [], committee: 0, voice: 0, motion: 0, motions: [], committeeUrls: [] };
      const seen = new Set<number>();
      for (const a of j) {
        const v = a.Vote;
        if (!v) continue;
        const id = v.VoteId;
        if (typeof id !== 'number' || !Number.isInteger(id)) throw new Error(`a vote the tool cannot read: ${JSON.stringify(a)}`);
        // the 2020 consent calendars appear twice in a bill's action log, as their bills appear twice in the vote: one vote
        if (seen.has(id)) continue;
        seen.add(id);
        const url = `https://sdlegislature.gov/Session/Vote/${id}`;
        const body_ = a.ActionCommittee?.FullName;
        if (a.ActionCommittee?.FullBody !== true || (body_ !== 'House of Representatives' && body_ !== 'Senate')) { out.committee++; out.committeeUrls!.push(url); continue; }
        const q = typeof a.StatusText === 'string' ? a.StatusText.trim() : '';
        if (!sdQuestionIsOnTheBill(q)) { out.motion!++; out.motions!.push(`${url} ${q}`); continue; }
        const n = (k: string): number => (typeof v[k] === 'number' ? v[k] as number : 0);
        out.floor.push({ url, motion: q, tally: [n('Yeas'), n('Nays'), n('Excused') + n('Absent') + n('NotVoting') + n('Present')] });
      }
      return out;
    },
  },
  // search-prod.lis.state.oh.us/api/v2/general_assembly_<GA>/legislation/<bill>/actions/ (read 2026-11-16): every
  // action of the bill, newest first; a vote carries yeas and nays (member ids), the chamber and the session day
  // (day153_h_20240612). A committee report (action_code crpt_...) is a committee's vote, and a vote on a motion (motion_...) is not a vote on the bill. Each floor vote is named on
  // the bill's Votes page at www.legislature.ohio.gov by its day, chamber and tally (stateRollCallEvidence.ts).
  OH: {
    minGapMs: 1_000, // no crawl delay stated (www.legislature.ohio.gov robots.txt allows all; search-prod has none): one a second is ours
    billUrl(session, bill) {
      const b = ohBill(bill);
      return /^1\d{2}$/.test(session) && b ? `https://search-prod.lis.state.oh.us/api/v2/general_assembly_${session}/legislation/${b}/actions/` : null;
    },
    read(body, session, bill) {
      const j = JSON.parse(body) as Record<string, unknown>[];
      if (!Array.isArray(j)) throw new Error(`the action list for ${session} ${bill} is not a list`);
      const out: BillIndex = { floor: [], committee: 0, voice: 0 };
      for (const a of j) {
        if (!Array.isArray(a.yeas) && !Array.isArray(a.nays)) continue;
        if (/^crpt_/.test(String(a.action_code ?? ''))) { out.committee++; continue; }
        // a vote on a motion ("Informally passed": the bill set aside) is not a vote on the bill (runner, 2026-11-16)
        if (/^motion_/.test(String(a.action_code ?? ''))) { out.motion = (out.motion ?? 0) + 1; continue; }
        const d = /_(\d{4})(\d{2})(\d{2})$/.exec(String(a.session_day ?? ''));
        const ch = a.chamber === 'House' || a.chamber === 'Senate' ? a.chamber : null;
        if (!d || !ch || !String(a.action ?? '').trim()) throw new Error(`a floor vote the tool cannot read: ${JSON.stringify({ ...a, yeas: undefined, nays: undefined })}`);
        const y = Array.isArray(a.yeas) ? a.yeas.length : 0;
        const n = Array.isArray(a.nays) ? a.nays.length : 0;
        out.floor.push({
          url: `https://www.legislature.ohio.gov/legislation/${session}/${ohBill(bill)}/votes#${d[1]}-${d[2]}-${d[3]}-${ch}-${y}-${n}`,
          motion: String(a.action).trim(),
          tally: [y, n, 0],
        });
      }
      return out;
    },
  },
  // le.utah.gov's bill page is filled in by a script from /data/<session>/<bill>.json (js/rexBill.js, read
  // 2026-11-15). An action with a voteID is a vote: actionClass "A" is a committee's (a mtgvotes.jsp page),
  // voiceVote "1" has a page that lists no member, and the rest are floor roll calls at DynaBill/svotes.jsp.
  UT: {
    minGapMs: 10_000, // robots.txt "Crawl-delay: 10"; faster draws 429
    billUrl(session, bill) {
      const s = utSession(session);
      const b = utBill(bill);
      return s && b ? `https://le.utah.gov/data/${s}/${b}.json` : null;
    },
    read(body, session, bill) {
      const j = JSON.parse(body) as { sessionID?: string; billNumber?: string; actionHistoryList?: Record<string, string>[] };
      if (j.sessionID !== utSession(session) || j.billNumber !== utBill(bill)) {
        throw new Error(`the data file is for ${j.sessionID} ${j.billNumber}, not ${session} ${bill}`);
      }
      if (!Array.isArray(j.actionHistoryList)) throw new Error('the data file has no action list');
      const out: BillIndex = { floor: [], committee: 0, voice: 0 };
      for (const a of j.actionHistoryList) {
        if (!a.voteID) continue;
        if (a.actionClass === 'A') { out.committee++; continue; }
        if (a.voiceVote === '1') { out.voice++; continue; }
        const t = /^\s*(\d+)\s*-\s*(\d+)\s*-\s*(\d+)\s*$/.exec(a.voteStr ?? '');
        if (!/^\d+$/.test(a.voteID) || !/^[HS]$/.test(a.voteHouse ?? '') || !t) {
          throw new Error(`a floor vote the tool cannot read: ${JSON.stringify(a)}`);
        }
        out.floor.push({
          url: `https://le.utah.gov/DynaBill/svotes.jsp?sessionid=${j.sessionID}&voteid=${a.voteID}&house=${a.voteHouse}`,
          motion: (a.description ?? '').trim(),
          tally: [Number(t[1]), Number(t[2]), Number(t[3])],
        });
      }
      return out;
    },
  },
};

// ── South Dakota sponsorships (runner, 2026-11-17: cite the introduced text) ─────────────────────────────────────
// The bill page (/Session/Bill/<id>) is a script shell, so a sponsorship is cited on the bill's introduced text, a
// PDF at mylrc.sdlegislature.gov/api/Documents/<DocumentId>.pdf, which prints "Introduced by: ...". The legislature's
// data lists the sponsors (/api/Bills/<BillId>: prime "P" or co-sponsor "C") and the texts (/api/Bills/Versions/<BillId>).
// 🔴 The 2018 and 2019 texts name every sponsor; 2020's name some; from 2021 a text names only the lead sponsor (2026
// SB 179: "Introduced by: Senator Hohn", of five sponsors). A sponsor the text does not name has no page a person can read, so it is recorded
// as not named and is not cited. Every name the text prints must be one member of that chamber in the session and one
// sponsor of the record, or the bill's sponsors are refused and none is cited: nothing is guessed.

export interface SdSponsor { name: string; label: string; chamber: 'H' | 'S'; type: 'P' | 'C'; on_text: boolean }
/** A bill's sponsors as the introduced text cites them, or why they were refused (the converter then cites none). */
export type SdSponsorship = { text: string; introduced_by: string; members: SdSponsor[] } | { refused: string };

/** The one "Introduced" version's PDF address, from /api/Bills/Versions/<BillId>. Throws unless there is exactly one. */
export function sdIntroducedText(body: string, bill: string): string {
  const j = JSON.parse(body) as { DocumentId?: unknown; BillVersion?: unknown }[];
  if (!Array.isArray(j)) throw new Error(`the version list of ${bill} is not a list`);
  const v = j.filter((x) => x.BillVersion === 'Introduced');
  if (v.length !== 1 || typeof v[0].DocumentId !== 'number' || !Number.isInteger(v[0].DocumentId)) throw new Error(`the version list of ${bill} holds ${v.length} introduced texts`);
  return `https://mylrc.sdlegislature.gov/api/Documents/${v[0].DocumentId}.pdf`;
}

/** The record's sponsors, from /api/Bills/<BillId>. Only name, label, chamber and kind are kept. */
export function sdRecordSponsors(body: string, billId: number, bill: string): Omit<SdSponsor, 'on_text'>[] {
  const j = JSON.parse(body) as { BillId?: unknown; BillSponsor?: unknown };
  if (!j || j.BillId !== billId || !Array.isArray(j.BillSponsor)) throw new Error(`the bill record of ${bill} is not bill ${billId}`);
  return (j.BillSponsor as { MemberType?: unknown; SponsorType?: unknown; Member?: { FirstName?: unknown; LastName?: unknown; UniqueName?: unknown } }[]).map((x) => {
    const m = x.Member;
    const ok = (v: unknown): v is string => typeof v === 'string' && v.trim() !== '';
    if (!m || !ok(m.FirstName) || !ok(m.LastName) || !ok(m.UniqueName) || (x.MemberType !== 'H' && x.MemberType !== 'S') || (x.SponsorType !== 'P' && x.SponsorType !== 'C')) {
      throw new Error(`a sponsor of ${bill} the tool cannot read`);
    }
    return { name: `${m.FirstName.trim()} ${m.LastName.trim()}`, label: m.UniqueName.trim(), chamber: x.MemberType, type: x.SponsorType };
  });
}

const sdKey = (s: string): string => s.toLowerCase().replace(/[^a-z()]/g, '');

/**
 * Whether a name as the text prints it is this record sponsor. The text and the record do not print a member the same
 * way: the text writes "Kolbeck" where the record's label is "Kolbeck (Jack)", "Otten (Ernie)" where it is "Otten",
 * and "Kevin Jensen" for "Jensen (Kevin)". So: the same label, or the same first and last name, or the same surname
 * with any given name the text adds agreeing with the record's (its first two letters). The caller still requires
 * exactly one sponsor in that chamber to match.
 */
export function sdSameMember(printed: string, r: { name: string; label: string }): boolean {
  if (sdKey(printed) === sdKey(r.label) || sdKey(printed) === sdKey(r.name)) return true;
  const m = /^(.*?)\s*\((.+)\)$/.exec(printed.trim());
  const [sur, given] = m ? [m[1], m[2]] : [printed, null];
  const recSur = r.label.replace(/\s*\(.*\)\s*$/, '');
  if (sdKey(sur) !== sdKey(recSur)) return false;
  return given === null || sdKey(r.name).startsWith(sdKey(given).slice(0, 2));
}

/**
 * The members the introduced text names, as (chamber, label), from the text the verifier reads (extractPdfText):
 * "Introduced by: Representatives Peterson (Sue), Bordeaux, ... and Rasmussen and Senators Langer, ...". Null when
 * the text has no such line. A committee ("at the request of the Committee on ...") is not a member.
 */
export function sdNamedOnText(text: string): { line: string; names: { chamber: 'H' | 'S'; label: string }[] } | null {
  const m = /Introduced by:\s*(.+?)(?=\s+(?:FOR AN ACT|Catchlines are not law|Underscores indicate|An Act|at the request of|A LEGISLATIVE COMMEMORATION|A (?:CONCURRENT |JOINT )?RESOLUTION)\b)/.exec(text);
  if (!m) return null;
  const line = m[1].trim();
  const names: { chamber: 'H' | 'S'; label: string }[] = [];
  const parts = line.split(/\b(Representatives?|Senators?)\b/).map((x) => x.trim());
  if (parts[0] !== '' && !/^(the )?committee\b/i.test(parts[0])) return { line, names: [] };
  for (let i = 1; i + 1 < parts.length; i += 2) {
    const chamber = parts[i].startsWith('Rep') ? 'H' : 'S';
    for (const raw of parts[i + 1].replace(/,?\s+and\s*$/, '').split(/,\s*(?:and\s+)?|\s+and\s+/)) {
      const label = raw.trim();
      if (label) names.push({ chamber, label });
    }
  }
  return { line, names };
}

/** The members of a session, as the legislature lists them (/api/SessionMembers/Session/<SessionId>): name, label and chamber only. */
export function sdSessionMembers(body: string, sessionId: number): { name: string; label: string; chamber: 'H' | 'S' }[] {
  const j = JSON.parse(body) as unknown;
  if (!Array.isArray(j) || j.length === 0) throw new Error(`the member list of session ${sessionId} is empty or unreadable`);
  return (j as { SessionId?: unknown; MemberType?: unknown; FirstName?: unknown; LastName?: unknown; UniqueName?: unknown }[]).map((m) => {
    const ok = (v: unknown): v is string => typeof v === 'string' && v.trim() !== '';
    if (m.SessionId !== sessionId || (m.MemberType !== 'H' && m.MemberType !== 'S') || !ok(m.FirstName) || !ok(m.LastName) || !ok(m.UniqueName)) {
      throw new Error(`a member of session ${sessionId} the tool cannot read`);
    }
    return { name: `${m.FirstName.trim()} ${m.LastName.trim()}`, label: m.UniqueName.trim(), chamber: m.MemberType };
  });
}

/**
 * Mark each record sponsor named on the text. A printed name must name exactly ONE member of that chamber in the
 * session (the member list, so a bare "Peterson" is refused when Kent and Sue Peterson both sit), and that member must
 * be exactly one sponsor of the record. Throws otherwise.
 */
export function sdSponsorsOnText(
  record: Omit<SdSponsor, 'on_text'>[], named: { chamber: 'H' | 'S'; label: string }[], members: { name: string; label: string; chamber: 'H' | 'S' }[], bill: string,
): SdSponsor[] {
  const hit = new Set<number>();
  for (const n of named) {
    const who = `${n.chamber === 'H' ? 'Representative' : 'Senator'} ${n.label}`;
    // the legislature's own label first: in 2018 "Sutton" is Maggie Sutton's label and "Sutton (Billie)" Billie's
    const exact = members.filter((x) => x.chamber === n.chamber && sdKey(x.label) === sdKey(n.label));
    const m = exact.length === 1 ? exact : members.filter((x) => x.chamber === n.chamber && sdSameMember(n.label, x));
    if (m.length !== 1) throw new Error(`the introduced text of ${bill} names ${who}, who is ${m.length} members of the session`);
    const i = record.flatMap((r, k) => (r.chamber === n.chamber && sdKey(r.label) === sdKey(m[0].label) && sdKey(r.name) === sdKey(m[0].name) ? [k] : []));
    if (i.length !== 1) throw new Error(`the introduced text of ${bill} names ${who}, who is ${i.length} sponsors of the record`);
    hit.add(i[0]);
  }
  return record.map((r, k) => ({ ...r, on_text: hit.has(k) }));
}

export interface SupplementRollCall {
  url: string; date: string; motion: string; question: string; chamber: 'H' | 'S';
  yea: number; nay: number; absent: number; passed: 0 | 1; groups: StateRollCall['groups'];
}

const norm = (b: string): string => b.replace(/[\s.]+/g, '').replace(/^([A-Z]+)0+(?=\d)/i, '$1').toUpperCase();

/**
 * One roll call for the supplement, or the reason it is refused. `passed` is the motion's own word when it has
 * one ("passed", "failed"), else whether the yeas outnumber the nays.
 */
export function buildRollCall(bill: string, v: IndexedVote, docs: string | string[], session?: string): SupplementRollCall | { refused: string } {
  if (!isStateRollCallUrl(v.url)) return { refused: 'no reader knows this address' };
  const r = readStateRollCallRecord(Array.isArray(docs) ? docs : [docs], v.url);
  if (!r) return { refused: 'the page did not read as a roll call' };
  // South Dakota's record names its session; it must be the session asked for
  if (session !== undefined && r.state === 'SD' && r.session !== session) return { refused: `the vote is of session ${r.session}, not ${session}` };
  // South Dakota votes a consent calendar as one roll call on several bills ("HB 1209, SB 55"): the bill must be one of them
  if (!r.bill.split(',').some((x) => norm(x) === norm(bill))) return { refused: `the page is for ${r.bill}, not ${bill}` };
  const got: [number, number, number] = [r.groups.Yea.length, r.groups.Nay.length, r.groups['Absent or not voting'].length];
  // South Dakota's action log counts Excused 0 on some votes whose own record lists excused members (2018 HB 1209,
  // House concurrence: 62-4, 4 excused on the record): the yeas and nays are compared there, and the record's list,
  // which its own counts check (stateRollCallEvidence.ts), is kept. The fetch counts each such vote.
  const compared = r.state === 'SD' ? 2 : 3;
  if (got.slice(0, compared).join() !== v.tally.slice(0, compared).join()) return { refused: `the page's tally ${got.join('-')} is not the bill file's ${v.tally.join('-')}` };
  const failed = /\b(fail(ed|s)?|defeated|rejected|refuse[sd]?)\b/i.test(v.motion);
  const passed = /\b(pass(ed|es)?|adopt(ed|s)?|concurs?|approved)\b/i.test(v.motion) && !failed ? 1 : failed ? 0 : got[0] > got[1] ? 1 : 0;
  return {
    url: v.url, date: r.date, motion: v.motion, question: r.question, chamber: r.chamber === 'House' ? 'H' : 'S',
    yea: got[0], nay: got[1], absent: got[2], passed, groups: r.groups,
  };
}

async function main(): Promise<void> {
  const argv = process.argv.slice(2);
  const flag = (n: string): string | undefined => { const i = argv.indexOf(n); return i >= 0 ? argv[i + 1] : undefined; };
  const [stArg, session, work] = argv;
  const ST = (stArg ?? '').toUpperCase();
  const idx = INDEX[ST];
  const listed = flag('--bills-file') ? readFileSync(flag('--bills-file')!, 'utf8').split(/\r?\n/) : (flag('--bills') ?? '').split(',');
  const bills = [...new Set(listed.map((b) => b.trim()).filter(Boolean))];
  if (!idx || !session || !work || !bills.length) {
    console.error(`usage: fetch-legislature-rollcalls.ts <st> <session> <work dir> --bills "HB 1,SB 2" | --bills-file <file>\nstates with a vote list: ${Object.keys(INDEX).join(', ')}`);
    process.exit(2);
  }
  const dir = path.join(work, 'supplements', ST);
  const raw = path.join(dir, 'raw');
  mkdirSync(raw, { recursive: true });
  const refetch = argv.includes('--refetch');

  let last = -Infinity;
  let asked = 0;
  /** A paced GET, kept on disk. A 429 or 503 is waited out twice, then it is an error: nothing is guessed. */
  async function get(url: string, gap: number): Promise<string> {
    const file = path.join(raw, createHash('sha256').update(url).digest('hex').slice(0, 24));
    if (!refetch && existsSync(file)) return readFileSync(file, 'utf8');
    for (let attempt = 0; ; attempt++) {
      const wait = last + gap - Date.now();
      if (wait > 0) await new Promise((r) => setTimeout(r, wait));
      last = Date.now();
      asked++;
      const res = await fetchWithHostTrust(url, { headers: { 'user-agent': EMPOWERED_VOTE_UA }, signal: AbortSignal.timeout(30_000) });
      if ((res.status === 429 || res.status === 503) && attempt < 2) { await new Promise((r) => setTimeout(r, 30_000)); continue; }
      if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
      // by the page's declared charset, as the verifier reads it
      const body = decodeHtmlBytes(new Uint8Array(await res.arrayBuffer()), res.headers.get('content-type') ?? '');
      writeFileSync(file, body);
      return body;
    }
  }

  /** A paced GET of a PDF, kept on disk as bytes; its text as the verifier reads it. */
  async function getPdfText(url: string, gap: number): Promise<string> {
    const file = path.join(raw, createHash('sha256').update(url).digest('hex').slice(0, 24));
    let bytes: Uint8Array;
    if (!refetch && existsSync(file)) bytes = new Uint8Array(readFileSync(file)); else {
      const wait = last + gap - Date.now();
      if (wait > 0) await new Promise((r) => setTimeout(r, wait));
      last = Date.now();
      asked++;
      const res = await fetchWithHostTrust(url, { headers: { 'user-agent': EMPOWERED_VOTE_UA }, signal: AbortSignal.timeout(30_000) });
      if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
      bytes = new Uint8Array(await res.arrayBuffer());
      writeFileSync(file, bytes);
    }
    if (!looksLikePdfBytes(bytes)) throw new Error(`${url} is not a PDF`);
    return extractPdfText(bytes);
  }

  const outFile = path.join(dir, `${session}.json`);
  const out = existsSync(outFile)
    ? JSON.parse(readFileSync(outFile, 'utf8')) as { bills: Record<string, SupplementRollCall[]>; checked: Record<string, unknown>; refused: Record<string, unknown>; sponsors?: Record<string, SdSponsorship> }
    : { bills: {}, checked: {}, refused: {} };
  const sponsorsOut = ((out as { sponsors?: Record<string, SdSponsorship> }).sponsors ??= {});
  let floor = 0;
  const refusedNow: string[] = [];
  for (const bill of bills) {
    let url = idx.billUrl(session, bill);
    if (!url && idx.listUrl && idx.billUrlFromList) {
      const list = idx.listUrl(session);
      if (list) url = idx.billUrlFromList(await get(list, idx.minGapMs), session, bill);
    }
    if (!url) throw new Error(`${ST} has no vote-list address for session ${session}, bill ${bill}`);
    const bi = idx.read(await get(url, idx.minGapMs), session, bill);
    const rcs: SupplementRollCall[] = [];
    const refused: { url: string; why: string }[] = [];
    const absentDiffers: string[] = [];
    for (const v of bi.floor) {
      const docs: string[] = [];
      for (const d of stateRollCallDocs(v.url) ?? [v.url]) docs.push(await get(d, Math.max(idx.minGapMs, stateRollCallMinGapMs(v.url))));
      const rc = buildRollCall(bill, v, docs, session);
      if ('refused' in rc) { refused.push({ url: v.url, why: rc.refused }); refusedNow.push(`${bill} ${v.url}: ${rc.refused}`); } else {
        rcs.push(rc);
        if (rc.absent !== v.tally[2]) absentDiffers.push(`${v.url} (vote list ${v.tally[2]}, record ${rc.absent})`);
      }
    }
    if (rcs.length) out.bills[bill] = rcs; else delete out.bills[bill];
    if (refused.length) out.refused[bill] = refused; else delete out.refused[bill];
    out.checked[bill] = { vote_list: url, floor: bi.floor.length, read: rcs.length, committee_not_read: bi.committee, voice_not_read: bi.voice, ...(bi.motion ? { motion_not_read: bi.motion } : {}),
      ...(bi.motions?.length ? { motions: bi.motions } : {}), ...(absentDiffers.length ? { absent_count_differs_from_vote_list: absentDiffers } : {}), ...(bi.committeeUrls?.length ? { committee_urls: bi.committeeUrls } : {}) };
    floor += rcs.length;
    if (ST === 'SD') {
      // the bill's sponsors and its introduced text (see sdSponsorsOnText); a fault refuses the sponsors, not the votes
      const billId = Number(/\/ActionLog\/(\d+)$/.exec(url)?.[1]);
      const sid = SD_SESSION_ID.get(session);
      try {
        if (sid === undefined) throw new Error(`session ${session} is not in SD_SESSIONS`);
        const record = sdRecordSponsors(await get(`https://sdlegislature.gov/api/Bills/${billId}`, idx.minGapMs), billId, bill);
        const text = sdIntroducedText(await get(`https://sdlegislature.gov/api/Bills/Versions/${billId}`, idx.minGapMs), bill);
        const named = sdNamedOnText(await getPdfText(text, idx.minGapMs));
        if (!named) throw new Error(`the introduced text of ${bill} has no "Introduced by:" line`);
        sponsorsOut[bill] = { text, introduced_by: named.line, members: sdSponsorsOnText(record, named.names, sdSessionMembers(await get(`https://sdlegislature.gov/api/SessionMembers/Session/${sid}`, idx.minGapMs), sid), bill) };
      } catch (e) {
        // kept as a refusal, so the converter drops the dump's sponsors of this bill rather than cite the script shell
        sponsorsOut[bill] = { refused: e instanceof Error ? e.message : String(e) };
        refusedNow.push(`${bill} sponsors: ${e instanceof Error ? e.message : e}`);
      }
    }
    console.log(`${bill}: ${rcs.length} of ${bi.floor.length} floor roll calls read (${bi.committee} committee${bi.motion ? `, ${bi.motion} motion` : ''} and ${bi.voice} voice votes not read)`);
  }
  writeFileSync(outFile, JSON.stringify({
    state: ST, session, source: `${new URL(idx.billUrl(session, bills[0]) ?? idx.listUrl?.(session) ?? '')!.host}: each bill's own vote list and each roll call's own page`,
    fetched_at: new Date().toISOString(), bills: out.bills, checked: out.checked, refused: out.refused, ...(Object.keys(sponsorsOut).length ? { sponsors: sponsorsOut } : {}),
  }, null, 1));
  console.log(`${bills.length} bills, ${floor} floor roll calls read, ${refusedNow.length} refused, ${asked} requests -> ${outFile}`);
  for (const r of refusedNow) console.log(`REFUSED ${r}`);
  if (refusedNow.length) process.exit(1);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((e) => { console.error(e instanceof Error ? e.message : e); process.exit(1); });
}
