/**
 * federalVotesPlan.ts — where each seated federal vote is cited (STAGE5 step 7, federal unit).
 *
 * Each seated vote finding is paired with the one essentials.legislative_votes roll call that is its store vote
 * (same Congress, bill, date, totals within one; `matchRollCall`). The person's table position is then checked
 * against the seated act, and the citation comes from the table, never from a name:
 *
 *   House  (totals above 150): the Clerk XML, https://clerk.house.gov/evs/<year>/roll<NNN>.xml, from `RC# <n>`.
 *   Senate (115th Congress on): the LegiScan roll call, https://legiscan.com/US/rollcall/<bill>/id/<id>, from the
 *          table's `legiscan-<id>`; the pair goes to scripts/legiscan-evidence-lines.ts.
 *
 * A vote with no single roll call, a motion that names another roll number or tally, a person with no bioguide id
 * or no table position, a Senate roll call before the 115th Congress: held in `unmapped` with the reason. A table act that differs from the seated act (a
 * `not_voting` against a seated yea included) is a disagreement and is not cited. Pure: no database, no network.
 */
import { instrumentBill, matchRollCall, tableAct, type TableRollCall } from '../lib/federalTableVotes.js';
import type { Vote } from '../lib/sourceStore.js';
import { legiscanBillNumber } from '../../src/lib/senateRollCall.js';

export type SeatedVote = {
  politician_id: string;
  full_name: string;
  last_name: string;
  bioguide: string | null;
  topic_key: string;
  instrument_id: string;
  date: string;
  motion: string;
  act: string;
  yes: number;
  no: number;
  cited_url: string;
};
/** `bill_number` and `rc` are the matched table roll call's: the Clerk XML must show both (houseRollCallIsFor). */
export type HouseCite = SeatedVote & { url: string; bill_number: string; rc: number };
/** The `pairs.csv` columns of legiscan-evidence-lines.ts, plus what `legiscan/needs.json` records of the vote. */
export type SenatePair = {
  full_name: string;
  last_name: string;
  topic_key: string;
  source_url: string;
  official: string;
  act: string;
  instrument_id: string;
};
export type Unmapped = Pick<SeatedVote, 'politician_id' | 'full_name' | 'instrument_id' | 'date' | 'motion' | 'act' | 'cited_url'> & {
  reason: string;
};

/**
 * The store vote a finding points to, as the pre-fill finds one (stage5Prefill.ts findVote): the vote with this
 * date and exactly this motion (two such: the one whose body the note names); else, for a motion written in free
 * text, the one store vote of that date, when it is a roll call. Null when none or several fit: hold, never pick.
 * The table match and the Clerk line still cross-check the act.
 */
export function findStoreVote(votes: Vote[], f: { date: string; motion: string; note?: string }): Vote | null {
  const sameDate = votes.filter((v) => v.date === f.date);
  const exact = sameDate.filter((v) => v.kind === 'roll-call' && v.motion === f.motion);
  if (exact.length === 1) return exact[0];
  if (exact.length > 1) {
    const byBody = exact.filter((v) => String(f.note ?? '').startsWith(`${v.body}, `));
    return byBody.length === 1 ? byBody[0] : null;
  }
  return sameDate.length === 1 && sameDate[0].kind === 'roll-call' ? sameDate[0] : null;
}

/**
 * A finding's motion may be free text that names its roll call ("House roll call 102; passed 220-208"): the store
 * vote was then found by date alone (findStoreVote). Every roll number ("roll call 102", "roll #102") and tally
 * ("220-208") it names must be the table roll call's own, else the reason to hold. An amendment number or a date
 * is not read as either. Null when the motion names neither, or both agree.
 */
export function motionClaimMismatch(motion: string, roll: Pick<TableRollCall, 'rc' | 'yes' | 'no'>): string | null {
  for (const m of motion.matchAll(/\broll(?:\s+call)?(?:\s+vote)?\s*(?:no\.|number|#)?\s*(\d{1,4})\b/gi)) {
    if (Number(m[1]) !== roll.rc) return `motion names roll call ${Number(m[1])}; the table roll call is ${roll.rc ?? 'unnumbered'}`;
  }
  for (const m of motion.matchAll(/(?<![\d.\-–])(\d{1,3})\s*[-–]\s*(\d{1,3})(?![\d\-–])/g)) {
    if (Number(m[1]) !== roll.yes || Number(m[2]) !== roll.no) return `motion names tally ${m[1]}-${m[2]}; the table roll call is ${roll.yes}-${roll.no}`;
  }
  return null;
}

/** A roll call with more than this many yes and no votes is a House roll call. */
const HOUSE_MIN_TOTAL = 150;
/** The first Congress whose Senate roll calls LegiScan holds. */
const FIRST_SENATE_CONGRESS = 115;

export function planCitations(
  seated: SeatedVote[],
  rolls: TableRollCall[],
): {
  house: HouseCite[]; senate: SenatePair[]; senateVotes: SeatedVote[]; unmapped: Unmapped[];
  crosscheck: { agree: number; disagree: Unmapped[] };
} {
  const house: HouseCite[] = [];
  const senate: SenatePair[] = [];
  const senateVotes: SeatedVote[] = [];
  const unmapped: Unmapped[] = [];
  const crosscheck = { agree: 0, disagree: [] as Unmapped[] };
  const held = (s: SeatedVote, reason: string): Unmapped => ({
    politician_id: s.politician_id, full_name: s.full_name, instrument_id: s.instrument_id, date: s.date,
    motion: s.motion, act: s.act, cited_url: s.cited_url, reason,
  });

  for (const s of seated) {
    const hold = (reason: string) => unmapped.push(held(s, reason));
    if (!s.bioguide) { hold('no bioguide id (the table links federal votes by bioguide only)'); continue; }
    const bill = instrumentBill(s.instrument_id);
    if (!bill) { hold('table: not a bill id'); continue; }
    const match = matchRollCall(s, bill, rolls);
    if (match.kind === 'none') { hold('table: no roll call'); continue; }
    if (match.kind === 'many') { hold(`table: ${match.candidates.length} roll calls fit (${match.candidates.join(', ')})`); continue; }
    const roll = match.roll;
    const claim = motionClaimMismatch(s.motion, roll);
    if (claim) { hold(claim); continue; }
    const position = roll.positions.get(s.politician_id);
    if (position === undefined) { hold(`table: no table position on ${roll.external_vote_id}`); continue; }
    const act = tableAct(position);
    if (act !== s.act) {
      crosscheck.disagree.push(held(s, `table ${roll.external_vote_id}: ${position}, seated: ${s.act}`));
      continue;
    }
    crosscheck.agree++;

    if (roll.yes + roll.no > HOUSE_MIN_TOTAL) {
      if (roll.rc === null) { hold(`house roll call with no roll number in the table (${roll.external_vote_id})`); continue; }
      const url = `https://clerk.house.gov/evs/${roll.date.slice(0, 4)}/roll${String(roll.rc).padStart(3, '0')}.xml`;
      house.push({ ...s, url, bill_number: roll.bill_number, rc: roll.rc });
      continue;
    }
    if (Number(roll.congress) < FIRST_SENATE_CONGRESS) { hold(`senate roll call before the 115th Congress (${roll.congress}th)`); continue; }
    const id = /^legiscan-(\d+)$/.exec(roll.external_vote_id)?.[1];
    if (!id) { hold(`senate roll call whose table id is not a LegiScan id (${roll.external_vote_id})`); continue; }
    // The table prints 'HJRES 44'; LegiScan names it HJR44 (S → SB, HR → HB, …).
    const lsBill = legiscanBillNumber(roll.bill_number.replace(/\s+/g, ''));
    if (!lsBill) { hold(`senate roll call on a bill with no LegiScan bill number (${roll.bill_number})`); continue; }
    const source_url = `https://legiscan.com/US/rollcall/${lsBill}/id/${id}`;
    senateVotes.push(s);
    if (senate.some((p) => p.full_name === s.full_name && p.source_url === source_url && p.official === s.cited_url)) continue;
    senate.push({
      full_name: s.full_name, last_name: s.last_name, topic_key: s.topic_key, source_url,
      official: s.cited_url, act: s.act, instrument_id: s.instrument_id,
    });
  }
  return { house, senate, senateVotes, unmapped, crosscheck };
}

/**
 * One record finding of a seated person on a page their row cites: a vote or an authorship, of any instrument.
 * `lined`: a House roll-call line now cites it. `senate`: a LegiScan pair carries it, for legiscan_merge.py.
 */
export type PageAct = { full_name: string; page: string; act: string; instrument_id: string; lined: boolean; senate: boolean };
export type NeedsEntry = { url: string; official: string; act: string; instrument: string };

/** One seated vote, whatever happens to it: politician, instrument, date, motion, act and cited page. */
export const voteKey = (v: Pick<Unmapped, 'politician_id' | 'instrument_id' | 'date' | 'motion' | 'act' | 'cited_url'>): string =>
  [v.politician_id, v.instrument_id, v.date, v.motion, v.act, v.cited_url].join('\u0000');

/**
 * Mark each record act on a cited page. `key` is the voteKey of a seated US- vote, null for any other act.
 * Both marks are positive: `lined` only for a key with a cited House line, `senate` only for a key whose vote
 * became a LegiScan pair (`planCitations(...).senateVotes`). Everything else, held at any stage, is open.
 */
export function markActs(
  onPage: Array<Omit<PageAct, 'lined' | 'senate'> & { key: string | null }>,
  linedKeys: Set<string>,
  senateKeys: Set<string>,
): PageAct[] {
  return onPage.map(({ key, ...a }) => ({ ...a, lined: key !== null && linedKeys.has(key), senate: key !== null && senateKeys.has(key) }));
}

/**
 * What happens to each cited page once the House lines are in.
 *   No Senate pair on it: uncite it when every act on it is lined and evidence.csv holds no other snippet for it
 *     (`snippets` keys are `${full_name}\u0000${page}`), the rule of iga-votes.ts.
 *   A Senate pair on it: legiscan_merge.py decides, and it uncites once every needs.json entry for the page has a
 *     LegiScan line. So each act there with no line (and another snippet) adds a BLOCKING entry whose url is the
 *     page itself: it holds no /rollcall/ and never gets a line, so the merge keeps the page. Each is warned too.
 *     A cited page that is itself a LegiScan roll call cannot block that way (the merge would read it as a vote
 *     line), so that person-page is held instead: the caller writes no Senate pair for it.
 */
export function pageDecisions(
  acts: PageAct[],
  snippets: Set<string>,
): {
  uncite: Array<{ full_name: string; page: string }>; blocking: Array<{ full_name: string; entry: NeedsEntry }>;
  warn: Array<{ full_name: string; page: string; why: string }>; hold: Array<{ full_name: string; page: string; why: string }>;
} {
  const byPage = new Map<string, PageAct[]>();
  for (const a of acts) {
    const k = `${a.full_name}\u0000${a.page}`;
    byPage.set(k, [...(byPage.get(k) ?? []), a]);
  }
  const out = { uncite: [] as Array<{ full_name: string; page: string }>, blocking: [] as Array<{ full_name: string; entry: NeedsEntry }>, warn: [] as Array<{ full_name: string; page: string; why: string }>, hold: [] as Array<{ full_name: string; page: string; why: string }> };
  for (const [k, list] of byPage) {
    const { full_name, page } = list[0];
    const open = list.filter((a) => !a.lined && !a.senate);
    const other = snippets.has(k);
    if (!list.some((a) => a.senate)) {
      if (!open.length && !other) out.uncite.push({ full_name, page });
      continue;
    }
    if (!open.length && !other) continue;
    if (/\/rollcall\//.test(page)) {
      out.hold.push({ full_name, page, why: 'cited page is a LegiScan roll call holding an act with no line; no Senate pair written for it' });
      continue;
    }
    for (const a of open) {
      const entry = { url: page, official: page, act: a.act, instrument: a.instrument_id };
      if (!out.blocking.some((b) => b.full_name === full_name && JSON.stringify(b.entry) === JSON.stringify(entry))) out.blocking.push({ full_name, entry });
    }
    if (other) out.blocking.push({ full_name, entry: { url: page, official: page, act: 'other snippet', instrument: '' } });
    out.warn.push({ full_name, page, why: open.length ? `${open.length} act(s) on it have no line` : 'it holds another snippet' });
  }
  return out;
}
