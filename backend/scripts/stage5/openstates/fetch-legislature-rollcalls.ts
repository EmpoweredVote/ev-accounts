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
import https from 'node:https';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { decodeHtmlBytes, EMPOWERED_VOTE_UA } from '../../../src/lib/verificationFetch.js';
import { fetchWithHostTrust } from '../../../src/lib/adapters/hostTrust.js';
import { isPubinfoDoc, readPubinfoDoc } from '../../../src/lib/adapters/caPubinfo.js';
import { extractPdfItems, extractPdfText, looksLikePdfBytes } from '../../../src/lib/pdfText.js';
import { caBillDoc, californiaBillDoc, californiaBillId, californiaVoteUrl, caQuestionIsOnTheBill, explainCaliforniaVote, parseCaliforniaVoteUrl, oregonBillActionsUrl, oregonVoteUrl, orQuestionIsOnTheBill, orTally, OR_SESSIONS, nevadaVoteListUrl, nevadaVoteUrl, NV_SESSIONS, nvVoteList, explainNevadaVote, parseNevadaVoteUrl, explainOregonVote, parseOregonVoteUrl, coBillTag, explainColoradoVote, explainNorthDakotaVote, parseNorthDakotaVoteUrl, explainMinnesotaVote, parseMinnesotaVoteUrl, explainKansasVote, parseColoradoVoteUrl, explainMarylandVote, explainMississippiVote, isStateRollCallUrl, KS_ARCHIVE, KS_CURRENT, ksQuestionIsOnTheBill, MD_PAGE_YEARS, parseKansasVoteUrl, parseMarylandVoteUrl, msQuestionIsOnTheBill, parseMississippiVoteUrl, pdfBodyFor, readStateRollCallRecord, sdQuestionIsOnTheBill, SD_SESSIONS, stateRollCallDocs, stateRollCallMinGapMs, type StateRollCall } from '../../../src/lib/stateRollCallEvidence.js';

/** One floor roll call as a bill's vote list gives it. */
/** tally: null when the vote list prints none (Mississippi): the reader's own checks of the printed totals stand alone. */
export interface IndexedVote { url: string; motion: string; tally: [number, number, number] | null }
/** motion: votes on a motion, not on the bill (Ohio motion_...: "Informally passed"), counted and not read. */
/**
 * viaIndex: floor votes whose file the vote list does not link, each with the page that does (Maryland 2013: the bill
 * page prints the action and its tally, and links the day's floor proceedings, which link the vote file). The fetch
 * reads that page with the state's voteFromIndex and then reads the vote like a linked one, its tally compared.
 */
export interface BillIndex { floor: IndexedVote[]; committee: number; voice: number; motion?: number; motions?: string[]; committeeUrls?: string[]; viaIndex?: IndexedVoteVia[] }
export interface IndexedVoteVia { index: string; chamber: 'house' | 'senate'; motion: string; tally: [number, number, number] }
interface StateIndex {
  /** The least time between two requests to the site (its robots.txt Crawl-delay). */
  minGapMs: number;
  /** The address of the bill's vote list, or null when the session or bill is not one this site can name. */
  billUrl: (_session: string, _bill: string) => string | null;
  /** Read the vote list. Throws when the document is not the bill asked for. `more`: the bodies of follow(body), in order. */
  read: (_body: string, _session: string, _bill: string, _more?: string[]) => BillIndex;
  /**
   * Documents the vote list only links (Nevada: the Votes tab links one list per kind of vote), fetched after it and
   * handed to read() as `more`. Throws on a link it does not know.
   */
  follow?: (_body: string, _session: string, _bill: string) => string[];
  /**
   * A site that names a bill's vote list by its own bill id (South Dakota): the session's bill list, read first, and
   * the vote-list address taken from it. Throws when the list does not hold the bill exactly once.
   */
  listUrl?: (_session: string) => string | null;
  billUrlFromList?: (_list: string, _session: string, _bill: string) => string;
  /** The vote file's address for a viaIndex vote, read from its index page. Throws unless exactly one vote fits. */
  voteFromIndex?: (_body: string, _session: string, _bill: string, _v: IndexedVoteVia) => string;
  /** An address whose redirect is the answer (Minnesota's House page resolver): kept as "LOCATION <address>", not followed. */
  manualRedirect?: (_url: string) => boolean;
}

// ── California ─────────────────────────────────────────────────────────────────────────────────────────
const CA_BILL = /^(AB|SB|ACR|SCR|AJR|SJR|ACA|SCA|HR|SR)0*([1-9]\d{0,4})$/i;
/** Open States' session ("20252026", "20232024 Special Session 1") and bill ("AB 1127") -> PUBINFO's bill id. */
export function californiaBillIdOf(session: string, bill: string): string | null {
  const s = /^(20\d{2})(20\d{2})(?: Special Session ([1-9]))?$/.exec(session.trim());
  const m = CA_BILL.exec(bill.replace(/[\s.]+/g, ''));
  if (!s || !m || Number(s[2]) !== Number(s[1]) + 1 || Number(s[1]) % 2 !== 1) return null;
  return californiaBillId(`${s[1]}${s[2]}`, Number(s[3] ?? 0), m[1], Number(m[2]));
}

// ── Oregon ─────────────────────────────────────────────────────────────────────────────────────────────
const OR_BILL = /^(HB|SB|HJR|SJR|HCR|SCR|HJM|SJM|HM|SM|HR|SR)0*([1-9]\d{0,4})$/i;

// ── Nevada ────────────────────────────────────────────────────────────────────────────────────────────────
const NV_REL = 'https://www.leg.state.nv.us/App/NELIS/REL/';
const NV_BILL = /^((?:A|S)(?:B|R|JR|CR))\s*0*([1-9]\d{0,3})$/i;

/** The session's bill list (every bill and resolution, each linked by its key). */
export function nvListUrl(session: string): string | null {
  const s = NV_SESSIONS[session];
  return s ? `${NV_REL}${s}/HomeBill/BillsTab?selectedTab=List&Filters.PageSize=5000` : null;
}

/** The bill's Votes tab, by its key in the session's bill list. Throws unless the list holds the bill exactly once. */
export function nvBillUrlFromList(list: string, session: string, bill: string): string {
  const s = NV_SESSIONS[session];
  const b = NV_BILL.exec(bill.replace(/\s+/g, ' ').trim());
  if (!s || !b) throw new Error(`Nevada: no session ${session} or no bill ${bill}`);
  const tag = `${b[1].toUpperCase()}${b[2]}`;
  const hits = [...list.matchAll(new RegExp(`href="/App/NELIS/REL/${s}/Bill/(\\d+)/Overview">\\s*${tag}\\s*<`, 'g'))];
  if (hits.length !== 1) throw new Error(`Nevada ${s}: the bill list holds ${tag} ${hits.length} times`);
  return `${NV_REL}${s}/Bill/FillSelectedBillTab?selectedTab=Votes&billKey=${hits[0][1]}`;
}

const nvKeyOf = (url: string): number => Number(/[?&]billKey=(\d+)/.exec(url)?.[1]);

/** The Votes tab's lists: Final Passage (voteTypeId 3) is the only kind read; any other kind throws, to be looked at. */
export function nvFollow(tab: string, session: string, bill: string): string[] {
  const s = NV_SESSIONS[session];
  const links = [...tab.matchAll(/<a href="\/App\/NELIS\/REL\/([^/]+)\/Bill\/GetBillVotes\?billKey=(\d+)&amp;voteTypeId=(\d+)">([^<]*)<\/a>/g)];
  if ((tab.match(/GetBillVotes/g) ?? []).length !== links.length) throw new Error(`Nevada ${bill}: a vote list link the reader cannot read`);
  return links.map((l) => {
    if (l[1] !== s) throw new Error(`Nevada ${bill}: the Votes tab links session ${l[1]}, not ${s}`);
    if (l[3] !== '3' || l[4].trim() !== 'Final Passage') throw new Error(`Nevada ${bill}: a kind of vote the fetch does not know: ${l[3]} ${l[4].trim()}`);
    return nevadaVoteListUrl(s!, Number(l[2]));
  });
}

/** Every Final Passage roll call of the bill's vote list, cited as its member list (stateRollCallEvidence.ts). */
export function nvReadVotes(tab: string, session: string, bill: string, more: string[] = []): BillIndex {
  const s = NV_SESSIONS[session];
  const b = NV_BILL.exec(bill.replace(/\s+/g, ' ').trim());
  if (!s || !b) throw new Error(`Nevada: no session ${session} or no bill ${bill}`);
  // a bill never voted on: the tab prints "No Votes Recorded" and links nothing
  const none = /<div class="alert alert-info">\s*No Votes Recorded\s*<\/div>/.test(tab);
  if (none && !more.length && !/GetBillVotes/.test(tab)) return { floor: [], committee: 0, voice: 0 };
  if (none || !/<div id="vote-revisions">/.test(tab)) throw new Error(`Nevada ${bill}: not a Votes tab`);
  const floor: IndexedVote[] = [];
  for (const body of more) {
    for (const v of nvVoteList(body)) {
      const key = nvKeyOf(tab.replace(/&amp;/g, '&'));
      if (!key) throw new Error(`Nevada ${bill}: the Votes tab names no bill key`);
      floor.push({ url: nevadaVoteUrl(s, v.voteKey, key, `${b[1]}${b[2]}`),
        motion: `${v.chamber === 'House' ? 'Assembly' : 'Senate'} final passage (${v.version}) ${v.passed ? 'passed' : 'failed'}`,
        tally: [v.counts.Yea, v.counts.Nay, v.counts.Excused + v.counts['Not voting'] + v.counts.Absent] });
    }
  }
  return { floor, committee: 0, voice: 0 };
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

const MS_BILL = /^(HB|SB|HC|SC|HR|SR|SN|JR)\s*0*([1-9]\d{0,3})$/i;
const MS_SITE = 'https://billstatus.ls.state.ms.us/';

const MD_BILL = /^([HS][BJ])\s*0*([1-9]\d{0,3})$/i;
/** A Maryland bill-page action that is a vote on the bill (the reader checks the vote's own question again). */
// The Senate writes "Third Readings Passed" (2018 HB 1302). An action that is neither this nor MD_MOTION_ACTION stops the tool.
export const MD_FLOOR_ACTION = /^(?:Third Readings? Passed|Third Readings? Failed|Conference Committee Report Adopted|Veto Overridden|Overridden|Vetoed .*Override)/i;
/** A Maryland bill-page action that is a vote on something other than the bill: an amendment or a motion. */
// A chamber's vote to concur in the other's amendments ("Senate Concur - House Amendment {322711/3 (#17) Adopted (28-18)")
// and a committee report's adoption on second reading ("Favorable with Amendments Report Adopted (28-19)") are votes on
// an amendment or a report, not on the bill (2013 SB 281; after concurring, the Senate passed the bill on a separate
// Third Reading vote). Both are printed with a tally only on the 2013 bill page.
export const MD_MOTION_ACTION = /^(?:Floor Amendment\b|Motion\b|Special Order\b|Decision of the Chair\b|(?:Senate|House) Concur\b|(?:Un)?Favorable(?: with Amendments)? Report Adopted\b)/i; // an appeal of the chair's ruling: "Decision of the Chair upheld" (2020)
/**
 * Sessions whose bill page links no vote file (read 2026-11-18: 2013's page prints "Third Reading Passed with
 * Amendments (78-61)" as plain text, and a "Proceedings 61" link to the day's floor proceedings,
 * /mgawebsite/Search/FloorActions?file=%2Fpubs%2Flegislegal%2F2013RS-hse-proceed-61.htm&ys=2013rs, which links each
 * vote file after its action: "Third Reading Passed with Amendments <a href=/mgawebsite/Search/Legislation?target=
 * /2013rs/votes/house/0895.htm> (78-61)</a>"). Only the sessions read are listed.
 */
export const MD_LINKLESS_SESSIONS: readonly string[] = ['2013'];
const MD_PROCEEDINGS = /href="(\/mgawebsite\/Search\/FloorActions\?file=%2Fpubs%2Flegislegal%2F(20\d{2})RS-(hse|sen)-proceed-[0-9A-Z]+\.htm&(?:amp;)?ys=\2rs)"/gi;

/**
 * A 2013 floor proceedings page: the address of the one vote file of `bill` whose action text ends with the bill
 * page's motion and whose tally is the bill page's, in the chamber asked for. The page lists bills one after another,
 * each opened by its link (<a href=/mgawebsite/Legislation/Details/SB0281?ys=2013rs> SB 281); a vote belongs to the
 * bill whose link last precedes it. Throws unless exactly one vote fits.
 */
export function mdVoteFromProceedings(body: string, session: string, bill: string, v: IndexedVoteVia): string {
  const m = MD_BILL.exec(bill.replace(/[\s.]+/g, ''));
  if (!m) throw new Error(`not a Maryland bill: ${bill}`);
  const tag = `${m[1].toUpperCase()}${Number(m[2])}`;
  const marks = [...body.matchAll(/<a href=["']?\/mgawebsite\/Legislation\/Details\/([HS][BJ])0*(\d+)\?ys=(\d{4})rs["']?>/gi)];
  const hits = new Set<string>();
  for (const [i, mk] of marks.entries()) {
    if (`${mk[1].toUpperCase()}${Number(mk[2])}` !== tag || mk[3] !== session) continue;
    const seg = body.slice(mk.index! + mk[0].length, i + 1 < marks.length ? marks[i + 1].index : body.length);
    let from = 0;
    for (const a of seg.matchAll(/<a href=["']?\/mgawebsite\/Search\/Legislation\?target=\/(\d{4})rs\/votes\/(house|senate)\/(\d{4})\.htm["']?>\s*\((\d+)-(\d+)\)\s*<\/a>/gi)) {
      const before = mdTag(seg.slice(from, a.index));
      from = a.index! + a[0].length;
      if (a[1] !== session || a[2].toLowerCase() !== v.chamber || Number(a[4]) !== v.tally[0] || Number(a[5]) !== v.tally[1]) continue;
      if (!before.toLowerCase().endsWith(v.motion.toLowerCase())) continue;
      hits.add(`https://mgaleg.maryland.gov/${session}RS/votes/${v.chamber}/${a[3]}.htm#${tag}`);
    }
  }
  if (hits.size !== 1) throw new Error(`${hits.size} votes on the proceedings page fit ${bill} ${v.chamber} "${v.motion}" (${v.tally[0]}-${v.tally[1]}): ${v.index}`);
  return [...hits][0];
}
const mdTag = (s: string): string => s.replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim();

const KS_BILL = /^([HS](?:B|CR|R|JR))\s*0*([1-9]\d{0,4})$/i;
/** A Kansas history action that is a vote on something other than the bill: the Committee of the Whole, a motion. */
export const KS_MOTION_ACTION = /^(?:Committee of the Whole\b|Motion\b|Substitute motion\b|.*\bmotioned\b|Part \d+ was\b|Withdraw\b|Ruling of the chair\b|Point of order\b)/i;
const ksSite = (session: string): { archive: string } | { current: string } | null => {
  const a = Object.entries(KS_ARCHIVE).find(([, s]) => s === session);
  if (a) return { archive: a[0] };
  const c = Object.entries(KS_CURRENT).find(([, s]) => s === session);
  return c ? { current: c[0] } : null;
};

/**
 * One Kansas history row with a vote link: the address, the chamber, the action and its tally. The archive prints
 * "Yea: 91 Nay: 29" on the link; the current site "Yea 83, Nay 37, Absent 5" (a group of 0 is not printed).
 */
export function ksReadHistory(body: string, session: string, bill: string): BillIndex {
  const m = KS_BILL.exec(bill.replace(/[\s.]+/g, ''));
  const site = ksSite(session);
  if (!m || !site) throw new Error(`not a Kansas bill and session: ${bill} ${session}`);
  const tag = `${m[1].toUpperCase()}${Number(m[2])}`;
  const out: BillIndex = { floor: [], committee: 0, voice: 0, motion: 0, motions: [] };
  const seen = new Set<string>();
  const add = (url: string, chamber: string, action: string, yea: number, nay: number): void => {
    if (seen.has(url)) return;
    seen.add(url);
    const v = parseKansasVoteUrl(url);
    if (!v || v.session !== session || (v.chamber && v.chamber !== chamber)) throw new Error(`a vote the tool cannot read: ${chamber} ${action} ${url}`);
    if (!ksQuestionIsOnTheBill(action)) {
      if (!KS_MOTION_ACTION.test(action)) throw new Error(`a vote whose action the tool does not know: ${chamber} ${action}`);
      out.motion!++; out.motions!.push(`${url} ${chamber} ${action}`); return;
    }
    // yeas and nays only: the third figure is not printed alike in both layouts (-1), and is not compared (buildRollCall)
    out.floor.push({ url, motion: action, tally: [yea, nay, -1] });
  };
  if ('archive' in site) {
    // the archive's bill page: "<h1>HB 2476</h1>", and one table row per action, in tabs of ten, all on the page
    const h1 = [...body.matchAll(/<h1>\s*([^<]+?)\s*<\/h1>/g)].map((x) => x[1].replace(/\s+/g, ''));
    // a substitute keeps its number: "<h1>S Sub for HB 2278</h1>" (2017-2018), "H Sub for Sub for SB 53"
    if (!h1.some((x) => x.toUpperCase().replace(/^(?:[HS]SUBFOR|SUBFOR)+/, '') === tag)) throw new Error(`the bill page is not ${bill} of ${session}`);
    for (const row of body.matchAll(/<tr>([\s\S]*?)<\/tr>/g)) {
      if (!/vote_view/.test(row[1])) continue;
      const cells = [...row[1].matchAll(/<td\b[^>]*>([\s\S]*?)<\/td>/g)].map((x) => x[1]);
      const links = [...row[1].matchAll(/<a href="(\/[^"]*\/measures\/vote_view\/je_\d{14}_\d+\/)">\s*Yea: (\d+) Nay: (\d+)\s*<\/a>/g)];
      if (links.length !== 1 || (row[1].match(/vote_view/g) ?? []).length !== 1 || cells.length < 3) throw new Error(`a vote row the tool cannot read: ${ksTag(row[1]).slice(0, 200)}`);
      const action = ksTag(cells[2].replace(/<a href="[^"]*vote_view[\s\S]*$/, '')).replace(/;$/, '');
      add(`https://www.kslegislature.gov${links[0][1]}`, ksTag(cells[1]), action, Number(links[0][2]), Number(links[0][3]));
    }
    return out;
  }
  // the current site's history, votes only: every vote of the bill must be on this one page
  const shown = /Showing 1(?:&ndash;|–)(\d+) of (\d+) entries/.exec(body);
  const rows = [...body.matchAll(/<tr class="history-row[^"]*">([\s\S]*?)<\/tr>/g)];
  // a bill never voted on prints no table at all, only this line (2025-2026 HB 2104; 2023-2024 HCR 5020)
  if (!shown && !rows.length && /<p[^>]*>No votes recorded yet\.<\/p>/.test(body) && !/\/vote\/\?apn=/.test(body)) return out;
  if (!shown || shown[1] !== shown[2] || Number(shown[2]) !== rows.length) throw new Error(`the history of ${bill} does not show all its votes on one page`);
  for (const row of rows) {
    const chamber = /<span class="history-chamber[^"]*">(House|Senate)<\/span>/.exec(row[1]);
    const prim = /<td class="col-primary">([\s\S]*?)<\/td>/.exec(row[1]);
    const links = prim ? [...prim[1].matchAll(/<a href="(\/b20\d{2}_\d{2}\/vote\/\?apn=[^"]+\.odt)"[^>]*>\s*Yea (\d+), Nay (\d+)(?:, [A-Za-z ]+ \d+)*\s*<\/a>/g)] : [];
    if (!chamber || !prim || links.length !== 1 || (prim[1].match(/\/vote\//g) ?? []).length !== 1) throw new Error(`a vote row the tool cannot read: ${ksTag(row[1]).slice(0, 200)}`);
    const action = ksTag(prim[1].replace(/<a href="[^"]*\/vote\/[\s\S]*$/, '')).replace(/;$/, '');
    add(`https://www.kslegislature.gov${links[0][1].replace(/&amp;/g, '&')}`, chamber[1], action, Number(links[0][2]), Number(links[0][3]));
  }
  return out;
}
const ksTag = (s: string): string => s.replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim();

/**
 * A Colorado bill-page vote (calendar, motion) that is a vote on the bill: third reading of the bill, concurring in the
 * other chamber's amendments and the repassage that follows, and a conference committee report adopted and the
 * repassage that follows. The reader checks the vote page's own question again (coQuestionIsOnTheBill).
 */
export const CO_FLOOR_ACTION = /^(?:Third Reading\|BILL|(?:House|Senate) Amendments\|(?:CONCUR|REPASS)|Conference Committee Report\|(?:ADOPT|ADOPT CCR|REPASS)|(?:Veto|Governor's Veto)\|OVERRIDE)$/i;
/**
 * A Colorado bill-page vote on something other than the bill: a Committee of the Whole amendment or report, a third-reading
 * amendment, a motion to refer, lay over, reconsider, limit debate, not concur, adhere, or a conference report going
 * beyond the scope (BYD SCP) or to a second committee; and a miscellaneous roll call.
 */
export const CO_MOTION_ACTION = /^(?:Committee of the Whole\|.*|Third Reading\|(?:AMD|AMEND) \([A-Z]?\.\d{3}\)|Third Reading\|(?:RE)?REFER\b.*|Third Reading\|(?:PERM|LO)|(?:House|Senate) Amendments\|(?:NOT CONCUR APPT CC|NOT CNCR|ADHERE)|Conference Committee Report\|(?:ADHERE|NOT CONCUR APPT CC|BYD SCP|2nd COMM)|MISC\|.*|Miscellaneous\|.*)$/i;

/**
 * A Colorado bill page's votes (/bills/hb19-1177): two accordions, "House Votes (22)" and "Senate Votes (5)", each a table
 * of rows (date, calendar, motion, "38 AYE 25 NO 2 OTHER", a link to /bill_votes/<id>). Each vote is cited as the vote's
 * page with the bill after a #. Committee votes are in another section of the page and are counted, not read.
 */
export function coReadBillVotes(body: string, session: string, bill: string): BillIndex {
  const tag = coBillTag(session, bill);
  if (!tag) throw new Error(`not a Colorado bill of session ${session}: ${bill}`);
  // the page's title names the bill: <title id="page-title">HB19-1177 Extreme Risk Protection Orders | Colorado General Assembly</title>
  const head = /<title id="page-title">\s*([A-Z]+\d{2}B?-\d{3,4})\s/.exec(body);
  if (!head || head[1].toUpperCase() !== tag) throw new Error(`the bill page is not ${tag}: ${head?.[1]}`);
  const out: BillIndex = { floor: [], committee: 0, voice: 0, motion: 0, motions: [] };
  const i = body.indexOf('id="bill-activity-votes"');
  out.committee = (body.match(/href="\/committee_meeting_hearing_items\/\d+\/votes\/\d+"/g) ?? []).length;
  // a bill no chamber voted on (lost in committee: 2019 HB 1049) has no votes section and links no floor vote
  if (i < 0 && !/\/bill_votes\//.test(body)) return out;
  if (i < 0) throw new Error(`the page of ${tag} links a floor vote and has no votes section`);
  const j = body.indexOf('id="bill-activity-', i + 30);
  const seg = body.slice(i, j > 0 ? j : undefined);
  const parts = seg.split(/aria-label="(House|Senate) Votes \((\d+)\)"/);
  let listed = 0;
  for (let k = 1; k < parts.length; k += 3) {
    const chamber = parts[k];
    const n = Number(parts[k + 1]);
    const rows = [...parts[k + 2].matchAll(/<tr class='mb-0' role="row">([\s\S]*?)<\/tr>/g)];
    if (rows.length !== n) throw new Error(`${tag}: ${chamber} prints ${n} votes and lists ${rows.length}`);
    for (const row of rows) {
      const cal = coTag(/data-label="Calendar">\s*<span>([^<]*)<\/span>/.exec(row[1])?.[1] ?? '');
      const mot = coTag(/data-label="Motion">\s*<span>([^<]*)<\/span>/.exec(row[1])?.[1] ?? '');
      const yes = /bill-votes-count-yes[^>]*>(\d+)</.exec(row[1]);
      const no = /bill-votes-count-no[^>]*>(\d+)</.exec(row[1]);
      const other = /bill-votes-count-others[^>]*>(\d+)</.exec(row[1]);
      const links = [...row[1].matchAll(/href="https:\/\/leg\.colorado\.gov\/bill_votes\/(\d+)"/g)];
      if (!cal || !mot || !yes || !no || !other || links.length !== 1) throw new Error(`${tag}: a vote row the tool cannot read: ${coTag(row[1]).slice(0, 200)}`);
      const url = `https://leg.colorado.gov/bill_votes/${links[0][1]}#${tag}`;
      const action = `${cal}|${mot}`;
      listed++;
      if (CO_FLOOR_ACTION.test(action)) { out.floor.push({ url, motion: `${cal} - ${mot}`, tally: [Number(yes[1]), Number(no[1]), Number(other[1])] }); continue; }
      if (!CO_MOTION_ACTION.test(action)) throw new Error(`${tag}: a vote whose action the tool does not know: ${chamber} ${action} ${url}`);
      out.motion!++; out.motions!.push(`${url} ${chamber} ${cal} - ${mot}`);
    }
  }
  if (!/\(\d+\)"/.test(seg) && /bill_votes\//.test(seg)) throw new Error(`${tag}: votes the tool cannot place in a chamber`);
  if ((body.match(/\/bill_votes\/\d+/g) ?? []).length !== listed) throw new Error(`${tag}: a vote link outside the vote tables`);
  return out;
}
const coTag = (s: string): string => s.replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim();

/**
 * North Dakota's Assembly for an Open States session ("65" to "69", the regular sessions; a special session such as "67S1"
 * is not read): its number and the year it met. Null for anything else.
 */
export function ndAssembly(session: string): { assembly: number; year: number } | null {
  if (!/^(6[5-9]|7\d)$/.test(session)) return null;
  const assembly = Number(session);
  return { assembly, year: 2017 + 2 * (assembly - 65) };
}
const ND_BILL = /^([HS](?:B|CR|R|JR|MR|CMR))\s*0*([1-9]\d{3})$/i;

/**
 * A North Dakota bill page's actions (/assembly/65-2017/regular/bill-actions/ba1279.html): one table row per action, its
 * date, chamber and words, and a link into that day's journal ("../journals/hr-dailyjnl-61.pdf#Page1394"). A recorded
 * vote on the bill is "Second reading, passed, yeas 92 nays 0" (also "passed as amended", "failed to pass", "adopted",
 * "failed to adopt", ", Emergency clause carried"); it is cited as the journal page with the bill after a #. The same
 * words with no tally are a voice vote. A committee's report prints its tally bare ("Reported back, do pass, place on
 * calendar 12 0 1") and is counted. A vote on a division of the bill ("Division A passed") is counted as a motion. Any
 * other row with a tally or a vote panel stops the tool.
 */
export function ndReadBillActions(body: string, session: string, bill: string): BillIndex {
  const a = ndAssembly(session);
  const b = ND_BILL.exec(bill.replace(/\s+/g, ' ').trim());
  if (!a || !b) throw new Error(`not a North Dakota bill of a regular session: ${session} ${bill}`);
  const tag = `${b[1].toUpperCase()} ${b[2]}`;
  const head = /<title>([^<]*?) - Actions \| North Dakota Legislative Branch<\/title>/.exec(body);
  if (!head || head[1].trim() !== tag) throw new Error(`the bill page is not ${tag}: ${head?.[1]}`);
  // the page's own address, which the site prints with no slash after the host ("https://ndlegis.govassembly/65-2017/...")
  const self = /<link rel="canonical" href="https:\/\/ndlegis\.gov\/?assembly\/(\d{2})-(20\d{2})\/regular\/bill-actions\/ba(\d{4})\.html"/.exec(body);
  if (!self || Number(self[1]) !== a.assembly || Number(self[2]) !== a.year) throw new Error(`the page of ${tag} is not of the ${a.assembly}th Assembly`);
  if (Number(self[3]) !== Number(b[2])) throw new Error(`the bill page is not ${tag}: ba${self[3]}`);
  const tables = [...body.matchAll(/<table\b/g)].map((m) => m.index!);
  const t = tables.map((i) => body.slice(i, body.indexOf('</table>', i))).find((x) => /<th scope="col">Journal<\/th>/.test(x));
  if (!t) throw new Error(`the page of ${tag} has no action table`);
  const out: BillIndex = { floor: [], committee: 0, voice: 0, motion: 0, motions: [] };
  const rows = [...t.matchAll(/<tr>([\s\S]*?)<\/tr>/g)].map((m) => m[1]).filter((r) => /<td\b/.test(r));
  if (!rows.length) throw new Error(`the page of ${tag} lists no action`);
  for (const row of rows) {
    const cells = [...row.matchAll(/<td\b[^>]*>([\s\S]*?)<\/td>/g)].map((m) => ndTag(m[1]));
    const desc = cells[2] ?? '';
    const journals = [...row.matchAll(/href="\.\.\/journals\/((?:hr|sr)-dailyjnl-\d{2})\.pdf#Page(\d+)"/g)];
    const panel = /data-bs-target="#vote-modal-/.test(row);
    const tally = /\byeas (\d+) nays (\d+)\b/.exec(desc);
    if (/^Second reading, (?:passed|passed as amended|failed to pass|adopted|adopted as amended|failed to adopt)\b/.test(desc)) {
      if (!tally) { if (panel) throw new Error(`${tag}: a vote with a panel and no tally: ${desc}`); out.voice++; continue; }
      if (journals.length !== 1) throw new Error(`${tag}: a vote with ${journals.length} journal links: ${desc}`);
      const chamber = cells[1];
      if ((journals[0][1].startsWith('hr') ? 'House' : 'Senate') !== chamber) throw new Error(`${tag}: a ${chamber} vote linked to another chamber's journal: ${desc}`);
      out.floor.push({ url: `https://ndlegis.gov/assembly/${a.assembly}-${a.year}/regular/journals/${journals[0][1]}.pdf#Page${journals[0][2]}-${tag.replace(' ', '')}`,
        motion: desc, tally: [Number(tally[1]), Number(tally[2]), -1] });
      continue;
    }
    if (/^Reported back\b.* \d+ \d+ \d+$/.test(desc)) { out.committee++; continue; }
    if (/^Division [A-Z] (?:passed|failed|adopted)\b/.test(desc)) { out.motion!++; out.motions!.push(`${journals[0]?.[1] ?? ''}#Page${journals[0]?.[2] ?? ''} ${cells[1]} ${desc}`); continue; }
    if (tally || panel) throw new Error(`${tag}: a vote whose action the tool does not know: ${cells[1]} ${desc}`);
  }
  return out;
}
const ndTag = (s: string): string => s.replace(/<div class="modal[\s\S]*$/, '').replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim();

/**
 * Minnesota's Legislature for an Open States session: "2017-2018" (a regular session) or "2021s1" (a special session).
 * ls is the Legislature's number (90th = 2017-2018), year the year the Revisor files the bill under, ssn 0 for the
 * regular session. Null for anything before the 90th.
 */
export function mnLegislature(session: string): { ls: number; year: number; ssn: number } | null {
  const r = /^(20\d{2})-(20\d{2})$/.exec(session);
  if (r && Number(r[2]) === Number(r[1]) + 1 && Number(r[1]) >= 2017 && Number(r[1]) % 2 === 1) return { ls: 90 + (Number(r[1]) - 2017) / 2, year: Number(r[1]), ssn: 0 };
  const s = /^(20\d{2})s([1-9])$/.exec(session);
  if (s && Number(s[1]) >= 2017) { const y = Number(s[1]); return { ls: 90 + Math.floor((y - 2017) / 2), year: y, ssn: Number(s[2]) }; }
  return null;
}
const MN_BILL = /^([HS]F)\s*0*([1-9]\d{0,4})$/i;
const MN_ORDINAL_SESSION = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th'];

/**
 * A recorded vote on the bill in a Minnesota bill page's actions, by chamber: the passage or repassage of the bill
 * (MN_FLOOR_ACTION). A recorded vote on anything else (MN_MOTION_ACTION) is counted as a motion; the other chamber's vote
 * as the clerk reports it ("Senate adopted conference committee report, bill repassed" in the House's list) is counted as
 * the other chamber's. Any other row with a tally stops the tool.
 */
export const MN_FLOOR_ACTION: Record<'Senate' | 'House', RegExp> = {
  Senate: /^(?:Third reading(?: Passed| Failed| as amended)?|Senate adopted (?:CC|conference committee) report and repassed bill|Repassed(?: the bill)?|Bill was repassed(?: as amended(?: by Conference)?)?|Veto overridden?|Repassed, the objections of the Governor notwithstanding)$/i,
  House: /^(?:Bill was (?:passed|repassed|not passed)(?: as amended(?: by Conference| by Senate)?)?|Bill was (?:passed|repassed), the objections of the Governor notwithstanding)$/i,
};
export const MN_MOTION_ACTION = /^(?:Motion\b|Point of order\b|Amendment\b|Amended\b|Call of the (?:House|Senate)\b|Appeal\b|Ruling\b|Rule \d|Question divided\b|Senate concurred?\b|House concurred?\b|Concurred?\b|Laid on table\b|Lay on table\b|Taken from table\b|Reconsider\b|Speaker\b|Chair\b|Special Order: Amended\b|Final passage\b.*\bmotion\b)/i;
const MN_CC_ADOPTED = /^Senate adopted (?:CC|conference committee) report and repassed bill$/i;
export const MN_OTHER_CHAMBER: Record<'Senate' | 'House', RegExp> = { Senate: /^House\b/i, House: /^Senate\b/i };

/**
 * A Minnesota bill page on the Revisor's site (www.revisor.mn.gov/bills/93/2023/0/SF/2909/): each chamber's actions in a
 * table, each with its date, its words, a link to the journal page it is on ("gotopage?session=ls93&number=5105") and,
 * for a recorded vote, its tally ("vote: 34-33"). The journal page is named by the Legislature's page number, and only
 * the chamber's page resolver knows which day's file holds it, so each floor vote is a viaIndex vote: the resolver's
 * address, read by mnVoteFromResolver.
 */
export function mnReadBillActions(body: string, session: string, bill: string): BillIndex {
  const l = mnLegislature(session);
  const b = MN_BILL.exec(bill.replace(/\s+/g, ' ').trim());
  if (!l || !b) throw new Error(`not a Minnesota bill of the 90th Legislature or later: ${session} ${bill}`);
  const tag = `${b[1].toUpperCase()} ${b[2]}`;
  const head = /<title>\s*([HS]F \d+) Status in the (?:Senate|House) (?:for|-) ([\s\S]*?)\s*<\/title>/.exec(body);
  if (!head || head[1] !== tag) throw new Error(`the bill page is not ${tag}: ${head?.[1]}`);
  const years = `${2017 + 2 * (l.ls - 90)} - ${2018 + 2 * (l.ls - 90)}`;
  const nth = (n: number): string => `${n}${n % 100 >= 11 && n % 100 <= 13 ? 'th' : ['th', 'st', 'nd', 'rd'][n % 10] ?? 'th'}`;
  const want = l.ssn ? `${nth(l.ls)} Legislature, ${l.year} ${MN_ORDINAL_SESSION[l.ssn - 1]} Special Session` : `${nth(l.ls)} Legislature (${years})`;
  if (head[2].replace(/\s+/g, ' ') !== want) throw new Error(`the page of ${tag} is not of the ${want}: ${head[2].replace(/\s+/g, ' ')}`);
  const out: BillIndex = { floor: [], committee: 0, voice: 0, motion: 0, motions: [], viaIndex: [] };
  let other = 0;
  for (const chamber of ['Senate', 'House'] as const) {
    const m = new RegExp(`<h3>${chamber}</h3>\\s*<table class="actions table">([\\s\\S]*?)</table>`).exec(body);
    if (!m) continue;
    const rows = [...m[1].matchAll(/<tr>([\s\S]*?)<\/tr>/g)].map((x) => x[1]).map((row) => {
      const cells = [...row.matchAll(/<td\b[^>]*>([\s\S]*?)<\/td>/g)].map((x) => x[1]);
      return { row, date: mnTag(cells[0] ?? ''), words: cells.length < 2 ? '' : mnTag(cells[1].replace(/<div class="action_item[\s\S]*$/, '')),
        tally: /\bvote:\s*(?:<a\b[^>]*>)?\s*(\d+)-(\d+)\s*(?:<\/a>)?\s*<\/span>/.exec(row) };
    });
    for (const [i, { row, date, words, tally }] of rows.entries()) {
      if (!tally) continue;
      // The Senate adopts a conference committee's report by one roll call and repasses the bill by the next: the
      // Revisor writes the first as "Senate adopted CC report and repassed bill" and the second as "Third reading"
      // (2023 SF 2909, journal pages 7871 and 7872). When a "Third reading" with a tally follows on the same day, the
      // first is the report's adoption, a motion; alone, it is the repassage.
      if (MN_CC_ADOPTED.test(words) && rows.slice(i + 1).some((r) => r.tally && r.date === date && /^Third reading\b/i.test(r.words))) {
        out.motion!++; out.motions!.push(`${chamber} ${words} (the report's adoption; the repassage follows) ${tally[1]}-${tally[2]}`); continue;
      }
      if (MN_OTHER_CHAMBER[chamber].test(words) && !MN_FLOOR_ACTION[chamber].test(words)) { other++; out.motions!.push(`${chamber} list: the other chamber's vote ${words} ${tally[1]}-${tally[2]}`); continue; }
      // the page number may carry a leading space, written "+" ("number=+9706", 2025)
      const pages = [...row.matchAll(/href="https:\/\/www\.(mnsenate\.gov\/journals\/gotopage|house\.mn\.gov\/scripts\/gotopage\.pl)\?session=ls(\d+)&(?:amp;)?number=(?:\+|%20)*([0-9a-z]+)((?:&(?:amp;)?session_(?:year|number)=\d+)*)"/g)];
      if (MN_FLOOR_ACTION[chamber].test(words)) {
        if (pages.length !== 1) throw new Error(`${tag}: a vote with ${pages.length} journal links: ${chamber} ${words}`);
        const [, host, ls, number, extra] = pages[0];
        if ((host.startsWith('mnsenate') ? 'Senate' : 'House') !== chamber) throw new Error(`${tag}: a ${chamber} vote linked to another chamber's journal: ${words}`);
        if (Number(ls) !== l.ls) throw new Error(`${tag}: a vote linked to the journal of the ${ls}th Legislature: ${words}`);
        if (!/^\d+$/.test(number)) throw new Error(`${tag}: a vote linked to a journal page that is not a page number (${number}): ${words}`);
        const sy = /session_year=(\d+)/.exec(extra)?.[1];
        const sn = /session_number=(\d+)/.exec(extra)?.[1];
        if ((l.ssn ? `${l.year}/${l.ssn}` : '') !== (sy || sn ? `${sy}/${sn}` : '')) throw new Error(`${tag}: a vote linked to the journal of another session (${extra || 'the regular session'}): ${words}`);
        out.viaIndex!.push({ index: mnResolverUrl(chamber, l, Number(number)), chamber: chamber === 'House' ? 'house' : 'senate', motion: words, tally: [Number(tally[1]), Number(tally[2]), -1] });
        continue;
      }
      if (MN_MOTION_ACTION.test(words)) { out.motion!++; out.motions!.push(`${chamber} ${words} ${tally[1]}-${tally[2]}`); continue; }
      throw new Error(`${tag}: a vote whose action the tool does not know: ${chamber} ${words}`);
    }
  }
  if (other) out.motion! += other;
  return out;
}
const mnTag = (s: string): string => s.replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim();

/**
 * Each chamber's page resolver. The Senate's answers JSON naming the day's file
 * ({"filename":"20230414049","internal_page":139,"fileBiennium":"2023-2024"}); the House's answers a redirect to the
 * day's page with the page after a # (http://www.house.leg.state.mn.us/cco/journals/2023-24/J0425056.htm#7041), kept by
 * the fetch as "LOCATION <address>" (MN_MANUAL_REDIRECT).
 */
export function mnResolverUrl(chamber: 'Senate' | 'House', l: { ls: number; year: number; ssn: number }, page: number): string {
  if (chamber === 'Senate') return `https://www.mnsenate.gov/api/journal/gotopage?page=${page}&ls=${l.ls}${l.ssn ? `&session_year=${l.year}&session_num=${l.ssn}` : ''}`;
  return `https://www.house.mn.gov/scripts/gotopage.pl?session=ls${l.ls}&number=${page}${l.ssn ? `&session_year=${l.year}&session_number=${l.ssn}` : ''}`;
}
export const MN_MANUAL_REDIRECT = /^https:\/\/www\.house\.mn\.gov\/scripts\/gotopage\.pl\?/;

/** The vote's address from its page resolver's answer: the day's journal, with the page and the bill after a #. */
export function mnVoteFromResolver(body: string, session: string, bill: string, v: IndexedVoteVia): string {
  const l = mnLegislature(session);
  const b = MN_BILL.exec(bill.replace(/\s+/g, ' ').trim());
  const page = Number(/[?&](?:page|number)=(\d+)/.exec(v.index)?.[1]);
  if (!l || !b || !page) throw new Error(`not a Minnesota vote: ${session} ${bill} ${v.index}`);
  const tag = `${b[1].toUpperCase()}${b[2]}`;
  const y = 2017 + 2 * (l.ls - 90);
  if (v.chamber === 'senate') {
    let j: { filename?: unknown; fileBiennium?: unknown };
    try { j = JSON.parse(body); } catch { throw new Error(`the Senate's page resolver did not answer JSON for page ${page}`); }
    const f = String(j.filename ?? '');
    const m = /^(20\d{2})\d{4}\d{1,3}(?:_ss([1-9]))?$/.exec(f);
    if (!m || j.fileBiennium !== `${y}-${y + 1}` || (Number(m[1]) !== y && Number(m[1]) !== y + 1)) throw new Error(`the Senate's page resolver named ${f} of ${String(j.fileBiennium)} for page ${page}`);
    if (Number(m[2] ?? 0) !== l.ssn) throw new Error(`the Senate's page resolver named ${f}, not a journal of session ${session}, for page ${page}`);
    return `https://www.mnsenate.gov/journals/${y}-${y + 1}/${f}.pdf#Page${page}-${tag}`;
  }
  const m = /^LOCATION https?:\/\/www\.house\.(?:leg\.state\.mn\.us|mn\.gov)\/cco\/journals\/(20\d{2})-(\d{2})\/(J\d{4}\d{3})\.htm#(\d+)$/.exec(body.trim());
  if (!m || Number(m[1]) !== y || Number(m[2]) !== (y + 1) % 100 || Number(m[4]) !== page) throw new Error(`the House's page resolver did not name a journal of ${y}-${y + 1} for page ${page}: ${body.slice(0, 120)}`);
  return `https://www.house.mn.gov/cco/journals/${m[1]}-${m[2]}/${m[3]}.htm#Page${page}-${tag}`;
}

/**
 * A GET whose redirect is the answer, over HTTP/1.1, unfollowed. Node's fetch offers HTTP/2, and the Minnesota House's
 * page resolver (www.house.mn.gov/scripts/gotopage.pl, IIS) resets an HTTP/2 stream with HTTP_1_1_REQUIRED on some
 * pages (2023-2024, page 15202, 2026-11-19), which fetch reports only as "fetch failed".
 * Over HTTP/1.1 the same page ends its Location header with a bare newline, not CR LF, which Node's strict parser
 * refuses: the lenient parser reads it. Only the Location header is used.
 */
function headOverHttp1(url: string): Promise<Response> {
  return new Promise((resolve, reject) => {
    const req = https.get(url, { headers: { 'user-agent': EMPOWERED_VOTE_UA }, timeout: 60_000, insecureHTTPParser: true }, (res) => {
      res.resume();
      res.on('end', () => {
        const h = new Headers();
        for (const [k, v] of Object.entries(res.headers)) if (v !== undefined) h.set(k, Array.isArray(v) ? v.join(', ') : String(v));
        resolve(new Response(null, { status: res.statusCode ?? 0, headers: h }));
      });
    });
    req.on('timeout', () => req.destroy(new Error(`no answer in 60 s from ${url}`)));
    req.on('error', reject);
  });
}

export const INDEX: Record<string, StateIndex> = {
  // California: the Legislature's PUBINFO bulk download, kept on this machine by ca_pubinfo.py (CA_PUBINFO_DIR; read
  // 2026-11-20: open, no key, no robots.txt, no terms text). A bill's file lists every vote of the bill: floor votes
  // (AFLOOR, SFLOOR) with their motion, and committee votes (any other location), counted and not read. A floor vote whose
  // motion is not a vote on the bill (caQuestionIsOnTheBill) is counted as a motion. Each vote is cited on the bill's Votes
  // page on leginfo with the vote after a # (never fetched: robots.txt disallows it) and read from the same file
  // (stateRollCallEvidence.ts). A bill with no vote has no file.
  CA: {
    minGapMs: 0, // files on this machine
    billUrl(session, bill) {
      const id = californiaBillIdOf(session, bill);
      return id ? californiaBillDoc(id) : null;
    },
    read(body, session, bill) {
      const id = californiaBillIdOf(session, bill);
      if (!id) throw new Error(`California: no session ${session} or no bill ${bill}`);
      const out: BillIndex = { floor: [], committee: 0, voice: 0, motion: 0, motions: [] };
      if (body === CA_NO_VOTES) return out;
      const b = caBillDoc(body);
      if (b.bill_id !== id) throw new Error(`the vote file of ${id} is of ${b.bill_id}`);
      for (const v of [...b.summary].sort((x, y) => x.vote_date_time.localeCompare(y.vote_date_time) || Number(x.vote_date_seq) - Number(y.vote_date_seq))) {
        if (v.location_code !== 'AFLOOR' && v.location_code !== 'SFLOOR') { out.committee++; continue; }
        const text = (b.motions[v.motion_id] ?? '').replace(/\s+/g, ' ').trim();
        const url = californiaVoteUrl(id, v.vote_date_time, v.location_code, v.motion_id, v.vote_date_seq);
        if (!caQuestionIsOnTheBill(text)) { out.motion!++; out.motions!.push(`${url} ${text}`); continue; }
        const n = (x: string | null): number => (x !== null && /^\d+$/.test(x) ? Number(x) : -1);
        // No vote recorded: the member rows, as leginfo's page prints it (the summary's figure differs on 357 of 43,971
        // floor votes of 2015-2026; stateRollCallEvidence.ts readCalifornia)
        const nvr = b.detail.filter((d) => d.location_code === v.location_code && d.motion_id === v.motion_id && d.vote_date_seq === v.vote_date_seq
          && d.vote_date_time === v.vote_date_time && d.vote_code === 'ABS').length;
        out.floor.push({ url, motion: `${text}, ${v.vote_result === '(PASS)' ? 'passed' : v.vote_result === '(FAIL)' ? 'failed' : '?'}`, tally: [n(v.ayes), n(v.noes), nvr] });
      }
      return out;
    },
  },
  // api.oregonlegislature.gov, the Legislature's Open Data Service (read 2026-11-20; no robots.txt on it or on OLIS; its
  // Acceptable Use Agreement asks a client to use the service instead of scraping the website, and allows on-demand
  // queries). A bill's history actions (MeasureHistoryActions, filtered to the bill) carry each recorded floor vote with
  // VoteText, the tally ("Ayes, 35; Nays, 19--...; Excused, 6--..."); committee votes are a separate set and are not in it.
  // A recorded action that is not a vote on the bill (orQuestionIsOnTheBill: a motion to rerefer, to substitute the
  // minority report, ...) is counted, not read. Each vote is cited on its member list on OLIS and read from the service
  // (stateRollCallEvidence.ts). The Open States rows cite the bill's Overview page, which holds every vote of the bill.
  OR: {
    minGapMs: 1_000, // no robots.txt and no rate in the use agreement: one a second is ours
    billUrl(session, bill) {
      const s = OR_SESSIONS[session];
      const m = OR_BILL.exec(bill.replace(/[\s.]+/g, ''));
      return s && m ? oregonBillActionsUrl(s, m[1].toUpperCase(), Number(m[2])) : null;
    },
    read(body, session, bill) {
      const s = OR_SESSIONS[session];
      const m = OR_BILL.exec(bill.replace(/[\s.]+/g, ''));
      if (!s || !m) throw new Error(`Oregon: no session ${session} or no bill ${bill}`);
      const prefix = m[1].toUpperCase();
      const number = Number(m[2]);
      const j = JSON.parse(body) as { value?: Record<string, unknown>[]; 'odata.nextLink'?: unknown };
      if (!Array.isArray(j.value) || j['odata.nextLink']) throw new Error(`the history of ${s} ${bill} is not one list`);
      if (!j.value.length) throw new Error(`the history of ${s} ${bill} is empty`);
      const out: BillIndex = { floor: [], committee: 0, voice: 0, motion: 0, motions: [] };
      for (const a of j.value) {
        if (a.SessionKey !== s || a.MeasurePrefix !== prefix || a.MeasureNumber !== number) throw new Error(`a history action of another bill in the history of ${s} ${bill}`);
        const vt = typeof a.VoteText === 'string' ? a.VoteText.trim() : '';
        if (!vt) continue;
        const id = a.MeasureHistoryId;
        const text = typeof a.ActionText === 'string' ? a.ActionText.replace(/\s+/g, ' ').trim() : '';
        if (typeof id !== 'number' || !Number.isInteger(id) || (a.Chamber !== 'H' && a.Chamber !== 'S') || !text) throw new Error(`a vote the tool cannot read: ${JSON.stringify(a)}`);
        const url = oregonVoteUrl(s, id, prefix, number);
        if (!orQuestionIsOnTheBill(text)) { out.motion!++; out.motions!.push(`${url} ${text}`); continue; }
        const t = orTally(vt);
        const n = (k: Parameters<typeof t.get>[0]): number => t.get(k)?.n ?? 0;
        out.floor.push({ url, motion: text, tally: [n('Aye'), n('Nay'), n('Excused') + n('Excused for business') + n('Absent')] });
      }
      return out;
    },
  },
  // www.leg.state.nv.us, NELIS (read 2026-11-19; robots.txt disallows */Reports/*, never /App/NELIS/, no Crawl-delay). The
  // Open States dump holds no roll call for 2019 or 2021, and its 2017 vote addresses are /Session/79th2017/Reports/ pages
  // (404 on the archive host, and disallowed). NELIS holds every session from 2011: the session's bill list gives a bill's
  // key, its Votes tab links the Final Passage list (nvFollow), and each roll call is read from its member list with the
  // vote list and the bill's page (stateRollCallEvidence.ts).
  NV: {
    minGapMs: 1_000, // robots.txt states no Crawl-delay: one a second is ours
    billUrl: () => null,
    listUrl: nvListUrl,
    billUrlFromList: nvBillUrlFromList,
    follow: nvFollow,
    read: nvReadVotes,
  },
  // www.revisor.mn.gov (read 2026-11-19; robots.txt disallows nothing under /bills/, no Crawl-delay). The Open States dump
  // holds no roll call for 2020's special sessions, 2021-2022 or 2021's special session, and its vote addresses for
  // 2017-2020 are House pages that now answer 500. A bill's page lists each chamber's actions with the tally of each
  // recorded vote and a link to the journal page (mnReadBillActions); each chamber's page resolver names the day's file
  // (mnVoteFromResolver); each vote is read from the journal with the LRL member list (stateRollCallEvidence.ts).
  MN: {
    minGapMs: 1_000, // robots.txt states no Crawl-delay on any of the four hosts: one a second is ours
    billUrl(session, bill) {
      const l = mnLegislature(session);
      const b = MN_BILL.exec(bill.replace(/\s+/g, ' ').trim());
      return l && b ? `https://www.revisor.mn.gov/bills/${l.ls}/${l.year}/${l.ssn}/${b[1].toUpperCase()}/${b[2]}/` : null;
    },
    read: mnReadBillActions,
    voteFromIndex: mnVoteFromResolver,
    manualRedirect: (url) => MN_MANUAL_REDIRECT.test(url),
  },
  // ndlegis.gov (read 2026-11-19; robots.txt is Drupal's default and disallows nothing under /assembly/, no Crawl-delay).
  // The Open States dump holds no roll call for the 66th and 67th Assemblies (2019, 2021), and names members only by
  // family name. A bill's action page lists each action with a link into that day's journal (ndReadBillActions); each
  // vote is read from the journal page with the Assembly's member list (stateRollCallEvidence.ts).
  ND: {
    minGapMs: 1_000, // robots.txt states no Crawl-delay: one a second is ours
    billUrl(session, bill) {
      const a = ndAssembly(session);
      const b = ND_BILL.exec(bill.replace(/\s+/g, ' ').trim());
      return a && b ? `https://ndlegis.gov/assembly/${a.assembly}-${a.year}/regular/bill-actions/ba${b[2]}.html` : null;
    },
    read: ndReadBillActions,
  },
  // leg.colorado.gov (read 2026-11-18; robots.txt allows /bills/ and /bill_votes/, no Crawl-delay). The Open States rows'
  // vote addresses are the old site's (leg.colorado.gov/content/...), now 404 during the move; every session from 2017 is
  // on the new site. A bill's page, /bills/hb19-1177, lists each recorded vote of each chamber with its calendar, motion
  // and tally (CO_FLOOR_ACTION read; CO_MOTION_ACTION counted; anything else stops the tool). Each vote is cited on its
  // own page with the bill after a # and read with the session's member list (stateRollCallEvidence.ts).
  CO: {
    minGapMs: 1_000, // robots.txt states no Crawl-delay: one a second is ours
    billUrl(session, bill) {
      const tag = coBillTag(session, bill);
      return tag ? `https://leg.colorado.gov/bills/${tag.toLowerCase()}` : null;
    },
    read: coReadBillVotes,
  },
  // www.kslegislature.gov (read 2026-11-18; no robots.txt). 2017-2022 and the special sessions: the archive's bill page,
  // /li_2018/b2017_18/measures/HB2476/, lists every action, and a recorded vote as a link on its tally ("Conference
  // Committee Report was adopted; <a href="/li_2018/b2017_18/measures/vote_view/je_.../"> Yea: 91 Nay: 29</a>"). 2023
  // on: the bill's history, /b2023_24/bills/SB113/history/?filter=votes&per_page=50, lists every vote ("Yea 83, Nay 37,
  // Absent 5"). A Committee of the Whole vote or a motion (KS_MOTION_ACTION) is counted, not read; any other action
  // stops the tool. Kansas records no committee roll call on the bill page. Each vote is cited on its own page
  // (stateRollCallEvidence.ts).
  KS: {
    minGapMs: 1_000, // no robots.txt, so no Crawl-delay stated: one a second is ours
    billUrl(session, bill) {
      const m = KS_BILL.exec(bill.replace(/[\s.]+/g, ''));
      const site = ksSite(session);
      if (!m || !site) return null;
      const tag = `${m[1].toUpperCase()}${Number(m[2])}`;
      // the archive answers lower case for every session; upper case only up to 2017-2018 (2019-2020 /HB2036/ is a 404)
      return 'archive' in site ? `https://www.kslegislature.gov/${site.archive}/measures/${tag.toLowerCase()}/` : `https://www.kslegislature.gov/${site.current}/${/R$/.test(m[1].toUpperCase()) ? 'resolutions' : 'bills'}/${tag}/history/?filter=votes&per_page=50`;
    },
    read: ksReadHistory,
  },
  // mgaleg.maryland.gov (read 2026-11-18; no robots.txt). The Open States dump holds no roll call of the 2023 session.
  // A bill's page, /mgawebsite/Legislation/Details/<sb0001>?ys=2023RS, lists every action as a block (Chamber, Calendar
  // Date, Action), and a recorded vote as a link on its tally: "Third Reading Passed <a href=/2023RS/votes/senate/0370.pdf>
  // (31-16)</a>" (2017: /2017RS/votes/House/0501.htm). The page prints the history twice (two layouts): each vote is read once. A vote whose action is not
  // a vote on the bill (MD_FLOOR_ACTION: a floor amendment, the previous question, a special order) is counted, not
  // read; Maryland's committee votes are not on the bill page. The page prints yeas and nays only. Each vote is cited
  // on its PDF with the bill after a # and read with the chamber's committee pages (stateRollCallEvidence.ts).
  MD: {
    minGapMs: 1_000, // no robots.txt, so no Crawl-delay stated: one a second is ours
    billUrl(session, bill) {
      const m = MD_BILL.exec(bill.replace(/[\s.]+/g, ''));
      if (!m || !/^20\d{2}$/.test(session)) return null;
      return `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${m[1].toLowerCase()}${m[2].padStart(4, '0')}?ys=${session}RS`;
    },
    read(body, session, bill) {
      const m = MD_BILL.exec(bill.replace(/[\s.]+/g, ''))!;
      const tag = `${m[1].toUpperCase()}${Number(m[2])}`;
      // the page names its bill and session in its title: "Legislation - SB0001" ... "2023 Regular Session"
      const sel = /<select[^>]*id="valueSessions"[^>]*>\s*<option[^>]*>([^<]*)<\/option>/.exec(body)?.[1]?.trim();
      const named = /<title>\s*Legislation - ([HS][BJ])0*(\d+)\s*<\/title>/i.exec(body);
      if (sel !== `${session} Regular Session` || !named || `${named[1].toUpperCase()}${Number(named[2])}` !== tag) throw new Error(`the bill page is ${named?.[1]}${named?.[2]} of ${sel}, not ${bill} of ${session}`);
      const out: BillIndex = { floor: [], committee: 0, voice: 0, motion: 0, motions: [] };
      const seen = new Set<string>();
      const linkless = MD_LINKLESS_SESSIONS.includes(session);
      if (linkless) out.viaIndex = [];
      for (const blk of body.matchAll(/<dl class="row">([\s\S]*?)<\/dl>/g)) {
        const dd = new Map([...blk[1].matchAll(/<dt[^>]*>([\s\S]*?)<\/dt>\s*<dd[^>]*>([\s\S]*?)<\/dd>/g)].map((x) => [mdTag(x[1]), x[2]]));
        const action = dd.get('Action') ?? '';
        if (linkless) {
          // no vote file is linked: a tallied action is found through its Proceedings link (MD_LINKLESS_SESSIONS)
          if (/\/votes\//i.test(action)) throw new Error(`a vote link on a ${session} bill page, which links none: ${action.slice(0, 200)}`);
          const text = mdTag(action);
          const t = /\((\d+)-(\d+)\)\s*$/.exec(text);
          if (!t) continue;
          const chamber = mdTag(dd.get('Chamber') ?? '').toLowerCase();
          if (chamber !== 'house' && chamber !== 'senate') throw new Error(`a vote of no chamber: ${text}`);
          const key = `${chamber}|${mdTag(dd.get('Calendar Date') ?? '')}|${text}`;
          if (seen.has(key)) continue;
          seen.add(key);
          const procs = [...(dd.get('Proceedings') ?? '').matchAll(MD_PROCEEDINGS)].filter((p) => p[2] === session && (p[3] === 'hse') === (chamber === 'house'));
          if (procs.length !== 1) throw new Error(`a ${session} vote with ${procs.length} proceedings links of its chamber: ${chamber} ${text}`);
          const index = `https://mgaleg.maryland.gov${procs[0][1].replace(/&amp;/g, '&')}`;
          if (!MD_FLOOR_ACTION.test(text)) {
            if (!MD_MOTION_ACTION.test(text)) throw new Error(`a vote whose action the tool does not know: ${text}`);
            out.motion!++; out.motions!.push(`${index} ${chamber} ${text}`); continue;
          }
          out.viaIndex!.push({ index, chamber, motion: text.replace(/\s*\(\d+-\d+\)$/, ''), tally: [Number(t[1]), Number(t[2]), -1] });
          continue;
        }
        // 2018 onward writes the link with a space inside the quote: href=" /2018RS/votes/house/0390.pdf"
        const links = [...action.matchAll(/href="\s*\/(\d{4})RS\/votes\/(house|senate)\/(\d{4})\.(pdf|htm)"/gi)];
        // a vote link of any other shape must stop the tool, not read as "no vote"
        if ((action.match(/\/votes\//gi) ?? []).length !== links.length) throw new Error(`a vote link the tool cannot read: ${action.slice(0, 200)}`);
        if (!links.length) continue;
        const chamber = mdTag(dd.get('Chamber') ?? '');
        // a veto is overridden in the next session, on a vote filed under it: 2020 HB 4, /2021RS/votes/House/0042.pdf
        const next = links.length === 1 && links[0][1] === String(Number(session) + 1) && /^(?:Veto )?Overridden\b/i.test(mdTag(action));
        if (links.length !== 1 || (links[0][1] !== session && !next) || links[0][2].toLowerCase() !== chamber.toLowerCase()) throw new Error(`a vote the tool cannot read: ${chamber} ${mdTag(action)}`);
        // 2017's votes are pages (.htm), every later session's PDFs (MD_PAGE_YEARS); the reader takes only that form
        const year = links[0][1];
        if ((links[0][4].toLowerCase() === 'htm') !== MD_PAGE_YEARS.includes(Number(year))) throw new Error(`a vote of an unexpected form: ${links[0][0]}`);
        // the next session has its own bill of this number: name the bill's year (#2020-HB4)
        const url = `https://mgaleg.maryland.gov/${year}RS/votes/${chamber.toLowerCase()}/${links[0][3]}.${links[0][4].toLowerCase()}#${next ? `${session}-` : ''}${tag}`;
        if (seen.has(url)) continue;
        seen.add(url);
        const text = mdTag(action);
        const t = /\((\d+)-(\d+)\)\s*$/.exec(text);
        if (!t) throw new Error(`a vote with no tally: ${text}`);
        if (!MD_FLOOR_ACTION.test(text)) {
          if (!MD_MOTION_ACTION.test(text)) throw new Error(`a vote whose action the tool does not know: ${text}`);
          out.motion!++; out.motions!.push(`${url} ${text}`); continue;
        }
        // yeas and nays only: the third figure is not printed (-1), and is not compared (buildRollCall)
        out.floor.push({ url, motion: text.replace(/\s*\(\d+-\d+\)$/, ''), tally: [Number(t[1]), Number(t[2]), -1] });
      }
      return out;
    },
    voteFromIndex: mdVoteFromProceedings,
  },
  // billstatus.ls.state.ms.us (read 2026-11-17; no robots.txt). Each bill has a history, /<session>/pdf/history/<HB>/
  // <HB0001>.xml: one ACTION per step ("03/08 (H) Passed As Amended"), and an ACT_VOTE link to the vote's PDF when the
  // step was a recorded vote. Mississippi records no committee roll calls: every linked vote is a chamber's. A vote on
  // a motion (msQuestionIsOnTheBill: to reconsider, to table, ...) is not a vote on the bill. The history prints no
  // tally; the PDF's own totals are checked by the reader (stateRollCallEvidence.ts). Each vote is cited on its PDF
  // with the bill after a #.
  MS: {
    minGapMs: 1_000, // no robots.txt, so no Crawl-delay stated: one a second is ours
    billUrl(session, bill) {
      const m = MS_BILL.exec(bill.replace(/[\s.]+/g, ''));
      if (!m || !/^20\d{2}(?:[1-9]E)?$/.test(session)) return null;
      const t = m[1].toUpperCase();
      return `${MS_SITE}${session}/pdf/history/${t}/${t}${m[2].padStart(4, '0')}.xml`;
    },
    read(body, session, bill) {
      const m = MS_BILL.exec(bill.replace(/[\s.]+/g, ''))!;
      const short = /<SHORT_MSRID>\s*([^<]*?)\s*<\/SHORT_MSRID>/.exec(body)?.[1];
      const year = /<YEAR>\s*(\d{4})\s*<\/YEAR>/.exec(body)?.[1];
      if (short !== `${m[1].toUpperCase()} ${Number(m[2])}` || year !== session.slice(0, 4)) throw new Error(`the history is for ${short} of ${year}, not ${bill} of ${session}`);
      const out: BillIndex = { floor: [], committee: 0, voice: 0, motion: 0, motions: [] };
      for (const act of body.matchAll(/<ACTION>([\s\S]*?)<\/ACTION>/g)) {
        const votes = [...act[1].matchAll(/<ACT_VOTE>\s*([^<]*?)\s*<\/ACT_VOTE>/g)].map((x) => x[1]);
        if (!votes.length) continue;
        const desc = /<ACT_DESC>\s*([^<]*?)\s*<\/ACT_DESC>/.exec(act[1])?.[1] ?? '';
        const d = /^\d{2}\/\d{2} \((H|S)\) (.+)$/.exec(desc);
        if (!d || votes.length !== 1) throw new Error(`a vote the tool cannot read: ${desc} ${votes.join(' ')}`);
        const v = new RegExp(`^(?:\\.\\./)+${session}/pdf/votes/(house|senate)/(\\d{7})\\.pdf$`, 'i').exec(votes[0]);
        if (!v || (v[1].toLowerCase() === 'house') !== (d[1] === 'H')) throw new Error(`a vote link the tool cannot read: ${desc} ${votes[0]}`);
        const url = `${MS_SITE}${session}/pdf/votes/${v[1].toLowerCase()}/${v[2]}.pdf#${m[1].toUpperCase()}${Number(m[2])}`;
        if (!msQuestionIsOnTheBill(d[2])) { out.motion!++; out.motions!.push(`${url} ${d[2]}`); continue; }
        out.floor.push({ url, motion: d[2].trim(), tally: null });
      }
      return out;
    },
  },
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
  if (!r) {
    const ms = parseMississippiVoteUrl(v.url) ? explainMississippiVote(Array.isArray(docs) ? docs : [docs], v.url)
      : parseMarylandVoteUrl(v.url) ? explainMarylandVote(Array.isArray(docs) ? docs : [docs], v.url)
      : parseKansasVoteUrl(v.url) ? explainKansasVote(Array.isArray(docs) ? docs : [docs], v.url)
      : parseColoradoVoteUrl(v.url) ? explainColoradoVote(Array.isArray(docs) ? docs : [docs], v.url)
      : parseNorthDakotaVoteUrl(v.url) ? explainNorthDakotaVote(Array.isArray(docs) ? docs : [docs], v.url)
      : parseMinnesotaVoteUrl(v.url) ? explainMinnesotaVote(Array.isArray(docs) ? docs : [docs], v.url)
      : parseNevadaVoteUrl(v.url) ? explainNevadaVote(Array.isArray(docs) ? docs : [docs], v.url)
      : parseOregonVoteUrl(v.url) ? explainOregonVote(Array.isArray(docs) ? docs : [docs], v.url)
      : parseCaliforniaVoteUrl(v.url) ? explainCaliforniaVote(Array.isArray(docs) ? docs : [docs], v.url) : null;
    return { refused: ms && 'refused' in ms ? `the page did not read as a roll call: ${ms.refused}` : 'the page did not read as a roll call' };
  }
  // South Dakota's record names its session; it must be the session asked for
  if (session !== undefined && r.state === 'SD' && r.session !== session) return { refused: `the vote is of session ${r.session}, not ${session}` };
  // South Dakota votes a consent calendar as one roll call on several bills ("HB 1209, SB 55"): the bill must be one of them
  // Maryland names the previous session's vetoed bill "HB 4 of 2020"; its year is in the address (#2020-HB4), checked by the reader
  // Colorado prints the bill with its year ("HB26-1097"); the dump writes 2026's as "HB 1097"
  const want = r.state === 'CO' && session !== undefined ? (coBillTag(session, bill) ?? bill) : bill;
  if (!r.bill.split(',').some((x) => norm(x.replace(/ of 20\d{2}$/, '')) === norm(want))) return { refused: `the page is for ${r.bill}, not ${bill}` };
  const got: [number, number, number] = [r.groups.Yea.length, r.groups.Nay.length, r.groups['Absent or not voting'].length];
  // South Dakota's action log counts Excused 0 on some votes whose own record lists excused members (2018 HB 1209,
  // House concurrence: 62-4, 4 excused on the record): the yeas and nays are compared there, and the record's list,
  // which its own counts check (stateRollCallEvidence.ts), is kept. The fetch counts each such vote.
  // Maryland's bill page prints yeas and nays only.
  // Kansas's history prints yeas and nays (the archive) or leaves out a group of 0 (the current site).
  // North Dakota's bill page prints yeas and nays only.
  // Minnesota's bill page prints yeas and nays only, and its journals name no absent member.
  const compared = r.state === 'SD' || r.state === 'MD' || r.state === 'KS' || r.state === 'ND' || r.state === 'MN' ? 2 : 3;
  if (v.tally && got.slice(0, compared).join() !== v.tally.slice(0, compared).join()) return { refused: `the page's tally ${got.join('-')} is not the bill file's ${v.tally.join('-')}` };
  const failed = /\b(fail(ed|s)?|defeated|rejected|refuse[sd]?)\b/i.test(v.motion);
  const passed = /\b(pass(ed|es)?|adopt(ed|s)?|concurs?|approved)\b/i.test(v.motion) && !failed ? 1 : failed ? 0 : got[0] > got[1] ? 1 : 0;
  return {
    url: v.url, date: r.date, motion: v.motion, question: r.question, chamber: r.chamber === 'House' ? 'H' : 'S',
    yea: got[0], nay: got[1], absent: got[2], passed, groups: r.groups,
  };
}

/** The --also addresses of one bill that its vote list does not already hold, as votes to read without a tally. The key is the
 * bill with its spaces removed ("SB861"); an address the page lists as a floor vote or a motion is not read twice. */
export function alsoVotes(bill: string, bi: BillIndex, also: Record<string, string[]>): IndexedVote[] {
  const onPage = new Set([...bi.floor.map((v) => v.url), ...(bi.motions ?? []).map((m) => m.split(' ')[0])]);
  return [...new Set(also[bill.replace(/\s+/g, '').toUpperCase()] ?? [])].filter((u) => !onPage.has(u))
    .map((u) => ({ url: u, motion: 'a vote the bill page does not link', tally: null }));
}

/** A bill with no vote has no PUBINFO file: this stands for its empty vote list. */
const CA_NO_VOTES = '{"no votes": true}';

/** A local PUBINFO document. Throws when the copy is not on this machine; a bill's missing file is a bill with no vote. */
export function pubinfoBody(doc: string, dir: string | undefined = process.env.CA_PUBINFO_DIR): string {
  if (!dir) throw new Error('CA_PUBINFO_DIR is not set: run ca_pubinfo.py sync and index, then set it');
  const body = readPubinfoDoc(doc, dir);
  if (body !== null) return body;
  const year = /^pubinfo:(\d{4})\//.exec(doc)?.[1];
  if (/\/bills\//.test(doc) && year && existsSync(path.join(dir, year, 'MANIFEST.json'))) return CA_NO_VOTES;
  throw new Error(`${doc}: not in ${dir} (run ca_pubinfo.py sync <dir> ${year ?? '<year>'} and index)`);
}

async function main(): Promise<void> {
  const argv = process.argv.slice(2);
  const flag = (n: string): string | undefined => { const i = argv.indexOf(n); return i >= 0 ? argv[i + 1] : undefined; };
  const [stArg, session, work] = argv;
  const ST = (stArg ?? '').toUpperCase();
  const idx = INDEX[ST];
  const listed = flag('--bills-file') ? readFileSync(flag('--bills-file')!, 'utf8').split(/\r?\n/) : (flag('--bills') ?? '').split(',');
  const bills = [...new Set(listed.map((b) => b.trim()).filter(Boolean))];
  // --also <json>: { "SB861": ["<vote address>", ...] }, votes found elsewhere (the dump) that the bill's own vote list may
  // not link. Maryland's bill page leaves some out (2022 SB 861: the Senate's third reading after the House amended it,
  // vote 1377). Each is read like a linked vote, without a tally to compare; one the reader refuses (a motion) is counted.
  const also = flag('--also') ? JSON.parse(readFileSync(flag('--also')!, 'utf8')) as Record<string, string[]> : {};
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
    // California: a file on this machine (caPubinfo.ts), never a request
    if (isPubinfoDoc(url)) return pubinfoBody(url);
    const file = path.join(raw, createHash('sha256').update(url).digest('hex').slice(0, 24));
    if (!refetch && existsSync(file)) return readFileSync(file, 'utf8');
    for (let attempt = 0; ; attempt++) {
      const wait = last + gap - Date.now();
      if (wait > 0) await new Promise((r) => setTimeout(r, wait));
      last = Date.now();
      asked++;
      const manual = idx.manualRedirect?.(url) ?? false;
      let res: Response;
      try {
        res = manual ? await headOverHttp1(url) : await fetchWithHostTrust(url, { headers: { 'user-agent': EMPOWERED_VOTE_UA }, signal: AbortSignal.timeout(60_000) });
      } catch (e) {
        // Node's "fetch failed" names neither the address nor the cause: say both, and try twice more after a pause
        const why = `${e instanceof Error ? e.message : String(e)}${e instanceof Error && e.cause ? ` (${String((e.cause as Error).message ?? e.cause)})` : ''}`;
        if (attempt < 2) { console.error(`  ${why} for ${url}; again in 30 s`); await new Promise((r) => setTimeout(r, 30_000)); continue; }
        throw new Error(`${why} for ${url}`, { cause: e });
      }
      if ((res.status === 429 || res.status === 503) && attempt < 2) { await new Promise((r) => setTimeout(r, 30_000)); continue; }
      if (manual) {
        const loc = res.headers.get('location');
        if (res.status < 300 || res.status > 399 || !loc) throw new Error(`HTTP ${res.status} and no redirect for ${url}`);
        writeFileSync(file, `LOCATION ${loc}`);
        return `LOCATION ${loc}`;
      }
      if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
      const bytes = new Uint8Array(await res.arrayBuffer());
      // a PDF (Mississippi's and Maryland's votes) is kept as the verifier's reader reads it (pdfBodyFor); anything else by
      // the page's declared charset, as the verifier reads it
      const body = looksLikePdfBytes(bytes) ? pdfBodyFor(url, await extractPdfItems(bytes)) : decodeHtmlBytes(bytes, res.headers.get('content-type') ?? '');
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
    const first = await get(url, idx.minGapMs);
    const more: string[] = [];
    for (const u of idx.follow?.(first, session, bill) ?? []) more.push(await get(u, idx.minGapMs));
    const bi = idx.read(first, session, bill, more);
    // a vote the list does not link: its file from the index page that does, then read like a linked vote (tally compared)
    for (const v of bi.viaIndex ?? []) {
      if (!idx.voteFromIndex) throw new Error(`${ST} has votes on an index page and no reader for it`);
      const u = idx.voteFromIndex(await get(v.index, idx.minGapMs), session, bill, v);
      if (!bi.floor.some((f) => f.url === u)) bi.floor.push({ url: u, motion: v.motion, tally: v.tally });
    }
    const rcs: SupplementRollCall[] = [];
    const refused: { url: string; why: string }[] = [];
    const absentDiffers: string[] = [];
    const extra = alsoVotes(bill, bi, also);
    const alsoRefused: { url: string; why: string }[] = [];
    for (const v of [...bi.floor, ...extra]) {
      const isExtra = !bi.floor.includes(v);
      const docs: string[] = [];
      for (const d of stateRollCallDocs(v.url) ?? [v.url]) docs.push(await get(d, Math.max(idx.minGapMs, stateRollCallMinGapMs(v.url))));
      const rc = buildRollCall(bill, v, docs, session);
      if ('refused' in rc && isExtra) { alsoRefused.push({ url: v.url, why: rc.refused }); continue; }
      if ('refused' in rc) { refused.push({ url: v.url, why: rc.refused }); refusedNow.push(`${bill} ${v.url}: ${rc.refused}`); } else {
        rcs.push(rc);
        if (v.tally && v.tally[2] >= 0 && rc.absent !== v.tally[2]) absentDiffers.push(`${v.url} (vote list ${v.tally[2]}, record ${rc.absent})`);
      }
    }
    if (rcs.length) out.bills[bill] = rcs; else delete out.bills[bill];
    if (refused.length) out.refused[bill] = refused; else delete out.refused[bill];
    out.checked[bill] = { vote_list: url, floor: bi.floor.length, read: rcs.length, committee_not_read: bi.committee, voice_not_read: bi.voice, ...(bi.motion ? { motion_not_read: bi.motion } : {}),
      ...(bi.motions?.length ? { motions: bi.motions } : {}), ...(extra.length ? { not_on_the_vote_list: extra.length, not_on_the_vote_list_refused: alsoRefused } : {}), ...(absentDiffers.length ? { absent_count_differs_from_vote_list: absentDiffers } : {}), ...(bi.committeeUrls?.length ? { committee_urls: bi.committeeUrls } : {}),
      ...(bi.viaIndex?.length ? { vote_index_pages: [...new Set(bi.viaIndex.map((v) => v.index))] } : {}) };
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
