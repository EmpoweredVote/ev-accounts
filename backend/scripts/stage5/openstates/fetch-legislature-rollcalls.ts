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
import { parseStateRollCallUrl, readStateRollCallHtml, stateRollCallMinGapMs, type StateRollCall } from '../../../src/lib/stateRollCallEvidence.js';

/** One floor roll call as a bill's vote list gives it. */
export interface IndexedVote { url: string; motion: string; tally: [number, number, number] }
export interface BillIndex { floor: IndexedVote[]; committee: number; voice: number }
interface StateIndex {
  /** The least time between two requests to the site (its robots.txt Crawl-delay). */
  minGapMs: number;
  /** The address of the bill's vote list, or null when the session or bill is not one this site can name. */
  billUrl: (_session: string, _bill: string) => string | null;
  /** Read the vote list. Throws when the document is not the bill asked for. */
  read: (_body: string, _session: string, _bill: string) => BillIndex;
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

export const INDEX: Record<string, StateIndex> = {
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

export interface SupplementRollCall {
  url: string; date: string; motion: string; question: string; chamber: 'H' | 'S';
  yea: number; nay: number; absent: number; passed: 0 | 1; groups: StateRollCall['groups'];
}

const norm = (b: string): string => b.replace(/[\s.]+/g, '').replace(/^([A-Z]+)0+(?=\d)/i, '$1').toUpperCase();

/**
 * One roll call for the supplement, or the reason it is refused. `passed` is the motion's own word when it has
 * one ("passed", "failed"), else whether the yeas outnumber the nays.
 */
export function buildRollCall(bill: string, v: IndexedVote, html: string): SupplementRollCall | { refused: string } {
  const ref = parseStateRollCallUrl(v.url);
  if (!ref) return { refused: 'no reader knows this address' };
  const r = readStateRollCallHtml(html, v.url);
  if (!r) return { refused: 'the page did not read as a roll call' };
  if (norm(r.bill) !== norm(bill)) return { refused: `the page is for ${r.bill}, not ${bill}` };
  const got: [number, number, number] = [r.groups.Yea.length, r.groups.Nay.length, r.groups['Absent or not voting'].length];
  if (got.join() !== v.tally.join()) return { refused: `the page's tally ${got.join('-')} is not the bill file's ${v.tally.join('-')}` };
  const failed = /\b(fail(ed|s)?|defeated|rejected|refuse[sd]?)\b/i.test(v.motion);
  const passed = /\b(pass(ed|es)?|adopt(ed|s)?|concurs?|approved)\b/i.test(v.motion) && !failed ? 1 : failed ? 0 : got[0] > got[1] ? 1 : 0;
  return {
    url: v.url, date: r.date, motion: v.motion, question: r.question, chamber: ref.chamber === 'House' ? 'H' : 'S',
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
      const res = await fetch(url, { headers: { 'user-agent': EMPOWERED_VOTE_UA }, signal: AbortSignal.timeout(30_000) });
      if ((res.status === 429 || res.status === 503) && attempt < 2) { await new Promise((r) => setTimeout(r, 30_000)); continue; }
      if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
      // by the page's declared charset, as the verifier reads it
      const body = decodeHtmlBytes(new Uint8Array(await res.arrayBuffer()), res.headers.get('content-type') ?? '');
      writeFileSync(file, body);
      return body;
    }
  }

  const outFile = path.join(dir, `${session}.json`);
  const out = existsSync(outFile)
    ? JSON.parse(readFileSync(outFile, 'utf8')) as { bills: Record<string, SupplementRollCall[]>; checked: Record<string, unknown>; refused: Record<string, unknown> }
    : { bills: {}, checked: {}, refused: {} };
  let floor = 0;
  const refusedNow: string[] = [];
  for (const bill of bills) {
    const url = idx.billUrl(session, bill);
    if (!url) throw new Error(`${ST} has no vote-list address for session ${session}, bill ${bill}`);
    const bi = idx.read(await get(url, idx.minGapMs), session, bill);
    const rcs: SupplementRollCall[] = [];
    const refused: { url: string; why: string }[] = [];
    for (const v of bi.floor) {
      const rc = buildRollCall(bill, v, await get(v.url, Math.max(idx.minGapMs, stateRollCallMinGapMs(v.url))));
      if ('refused' in rc) { refused.push({ url: v.url, why: rc.refused }); refusedNow.push(`${bill} ${v.url}: ${rc.refused}`); } else rcs.push(rc);
    }
    if (rcs.length) out.bills[bill] = rcs; else delete out.bills[bill];
    if (refused.length) out.refused[bill] = refused; else delete out.refused[bill];
    out.checked[bill] = { vote_list: url, floor: bi.floor.length, read: rcs.length, committee_not_read: bi.committee, voice_not_read: bi.voice };
    floor += rcs.length;
    console.log(`${bill}: ${rcs.length} of ${bi.floor.length} floor roll calls read (${bi.committee} committee and ${bi.voice} voice votes not read)`);
  }
  writeFileSync(outFile, JSON.stringify({
    state: ST, session, source: `${new URL(idx.billUrl(session, bills[0])!).host}: each bill's own vote list and each roll call's own page`,
    fetched_at: new Date().toISOString(), bills: out.bills, checked: out.checked, refused: out.refused,
  }, null, 1));
  console.log(`${bills.length} bills, ${floor} floor roll calls read, ${refusedNow.length} refused, ${asked} requests -> ${outFile}`);
  for (const r of refusedNow) console.log(`REFUSED ${r}`);
  if (refusedNow.length) process.exit(1);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((e) => { console.error(e instanceof Error ? e.message : e); process.exit(1); });
}
