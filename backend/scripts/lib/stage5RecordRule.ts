/**
 * stage5RecordRule.ts — Stage 5 record-only pass by rule (round three, adjustment 1; approved 2026-11-13).
 *
 * The state's bill table already holds the judgment: the rung a Yes on each bill supports, read once by Opus
 * and, where flagged, answered by the runner. Applying that table to one person's votes is arithmetic, so a
 * script does it for the PLAIN cases and hands every other person to an Opus coder. It never decides a case it
 * was not shown to get right.
 *
 * Replay (2026-11-13, against the Opus record-only codes): California 85 of 101 people decided here, 85 agree;
 * Missouri 114 of 127, 114 agree. All 7 disagreements of the bare rule fall in a lane below (5 licence-rule
 * records, 1 superseded Yes, 1 person the rulings name).
 *
 * "Plain" is `isPlainRecord` (stage5CoderInputs.ts): the note is only the pre-fill's fixed sentence. Until 2026-11-14
 * it was "the finding collapsed to a line", which one roll call stored under two motion wordings fails. Replay with
 * the fixed test, against the blind Opus record codes: South Carolina 98 of 168 decided here (was 9), 99 of 99 agree;
 * Kentucky 33 of 140 (was 9), 32 of 32 agree; Tennessee 94 and Washington 83, both unchanged.
 *
 * `decideRecord` returns either a decision (a seat at the furthest rung, or a No-votes-only blank) or the
 * LANES that send the person to Opus. Any lane wins over a decision. Pure: no files, no clock.
 */
import type { CoderFinding } from './stage5CoderInputs.js';
import { SCRIPT_CODER } from './stage5Code.js';

export { SCRIPT_CODER };

export interface RuleBillRow {
  rung: number | null;
  deciding_words?: string;
  why?: string;
  flag?: string;
  /**
   * Set when a ruling reads some vote on this bill differently from the row (a vote taken on an earlier text):
   * the rungs any one vote on it may carry. An act on such a bill goes to Opus whenever one of these rungs
   * would change the person's result.
   */
  per_vote?: { rungs: (number | null)[]; note?: string; votes?: PerVoteRung[] };
}

/**
 * One floor vote on a bill, with the rung a Yes on THAT vote supports (runner, 2026-11-19: "one rung per vote").
 * A vote finding that fits exactly one entry (its date and chamber, and its tally when the entry gives one) is read
 * at that rung, by the script. Any other act on the bill (a vote that fits no entry or two, a sponsorship) is read as
 * before: tried at each rung of `rungs`, and sent to Opus when one of them would change the result.
 * Kansas, 2026-11-18: three bills whose chambers voted on different texts sent 20 people to Opus.
 */
export interface PerVoteRung { date: string; chamber: 'House' | 'Senate'; tally?: string; rung: number | null }

/** What the rule needs to know about a bill beyond its table row. */
export interface RuleBill {
  /** In the store, with a file. A record on a bill with no file seats no one (standing coder rule). */
  inStore: boolean;
  /** `multi` when the season's single-subject verdict says so: a sponsorship then shows a direction only. */
  multi: boolean;
  /** Yes and No counts of every floor vote on file. */
  tallies: { yes: number; no: number }[];
}

export interface RuleInput {
  findings: CoderFinding[];
  /** Ids of the record findings whose note is only the pre-fill's fixed sentence (`collapseBatch`). */
  plainIds: ReadonlySet<string>;
  table: Readonly<Record<string, RuleBillRow>>;
  bill: (id: string) => RuleBill | undefined;
  /** The rungs of each side of the ladder, e.g. [[1, 2, 3], [4, 5]]. The furthest rung is the outer one. */
  sides: readonly [readonly number[], readonly number[]];
  /** Store-id prefix of the unit's own bills (`CA-`); an act on any other bill is a record from elsewhere. */
  billPrefix: string;
  /** The roster office title; a seat outside a legislature cannot be judged on a legislative record here. */
  office: string;
  /** True when the state's rulings name this person. */
  named: boolean;
}

export type Lane =
  | 'both-sides' | 'later-no' | 'sponsor-no-rung' | 'named-in-rulings' | 'per-vote-note' | 'other-office'
  | 'missing-bill' | 'flagged-bill' | 'note-says-more' | 'other-jurisdiction' | 'blank-not-plain' | 'no-record';

export const LANE_WORDS: Record<Lane, string> = {
  'both-sides': 'Yes acts on both sides of the ladder (the licence rule or a two-sided record: a judgment)',
  'later-no': 'a later No on a bill at the same rung as the seat (a later vote may replace the Yes)',
  'sponsor-no-rung': 'no usable rung act, sponsorships on file, and No votes on both sides of the ladder',
  'named-in-rulings': "the state's rulings name this person",
  'per-vote-note': 'a vote the rulings read differently from the bill table, and it could change the result',
  'other-office': 'the roster office is not a legislative seat, so the record may come from another office',
  'missing-bill': 'a finding names a bill the bill table or the store does not hold',
  'flagged-bill': 'an act on a bill whose flag the runner has not answered',
  'note-says-more': 'a record finding whose note says more than the plain facts, or an act the rule does not read',
  'other-jurisdiction': 'an act on a bill of another legislature',
  'blank-not-plain': 'no usable rung act, and not a plain blank: No votes on both sides of the ladder, or no Yes or No vote at all',
  'no-record': 'no record finding on file',
};

export interface Act { id: string; bill: string; act: string; date: string; rung: number | null; tally?: string; gate?: string }

export interface Decision {
  outcome: 'seated' | 'doesnt-fit';
  value?: number;
  /** Seat: the usable Yes acts at the seat rung, newest first. Blank: the counted No votes on rung bills. */
  deciding: Act[];
  /** Usable Yes acts on the same side at other rungs. */
  sameSide: Act[];
  /** Counted No votes (a seat's reasoning names them as direction only). */
  nays: Act[];
  gatedYes: number;
  /** Blank only: the rungs of the bills voted against. */
  naySide?: 0 | 1;
  /**
   * Blank only: every sponsorship on file, none of which is a usable rung act (the bill has no rung, or the
   * sponsorship is gated). With counted No votes on one side the blank is still No-votes-only; with none it is a
   * sponsorships-only blank (`sponsorOnly`).
   */
  sponsored?: Act[];
  sponsorOnly?: boolean;
  /**
   * Blank only (ruling 2026-11-18): the record holds Yes or No votes, and none of them counts: each is on a bill the
   * table gives no rung, or is gated. No sponsorship, no counted No. These are those votes.
   */
  uncounted?: Act[];
}

export interface RuleResult { lanes: Lane[]; decision?: Decision }

const YES = new Set(['yea', 'sponsor', 'author', 'signed']);
const SPONSOR = new Set(['sponsor', 'author', 'signed']);
const READ = new Set([...YES, 'nay', 'abstain', 'absent', 'present', 'recused']);
/** Seats whose holder votes on bills. Anything else (an auditor, an attorney general) goes to Opus. */
export const LEGISLATIVE_OFFICE = /senat|represent|assembl|delegate|legislat/i;

/** A sponsorship is gated like the vote when every floor vote on file is near-unanimous (10% No or less). */
export function sponsorGate(b: RuleBill): 'multi-subject' | 'near-unanimous' | 'none' {
  if (b.multi) return 'multi-subject';
  const counted = b.tallies.filter((t) => t.yes + t.no > 0);
  return counted.length && counted.every((t) => t.no <= 0.1 * (t.yes + t.no)) ? 'near-unanimous' : 'none';
}

const tallyOf = (f: CoderFinding) => /\(tally ([^)]*)\)/.exec(f.note)?.[1];
/** "KS House, Final Action, 2018-02-02: yea (tally 76–44)" -> House: the chamber the pre-fill's sentence opens with. */
const chamberOf = (f: CoderFinding) => /^\S+ (House|Senate),/.exec(f.note)?.[1];
const tallyKey = (t?: string) => (t ?? '').replace(/[^0-9]+/g, '-').replace(/^-|-$/g, '');

/** The entry of `per_vote.votes` a vote finding fits, when it fits exactly one. */
export function perVoteEntry(f: CoderFinding, row: RuleBillRow): PerVoteRung | undefined {
  if (f.act !== 'yea' && f.act !== 'nay') return undefined;
  const chamber = chamberOf(f);
  const fits = (row.per_vote?.votes ?? []).filter((v) => v.date === f.date && v.chamber === chamber && (!v.tally || tallyKey(v.tally) === tallyKey(tallyOf(f))));
  return fits.length === 1 ? fits[0] : undefined;
}

/** `tryRung`: a bill -> the rung to try for its acts that no `per_vote.votes` entry settles. */
function core(input: RuleInput, tryRung: ReadonlyMap<string, number | null> = new Map()): RuleResult {
  const table = input.table;
  const lanes = new Set<Lane>();
  const sideOf = (r: number) => (input.sides[0].includes(r) ? 0 : input.sides[1].includes(r) ? 1 : undefined);
  const yes: Act[] = []; const nays: Act[] = [];
  let sponsorships = 0; let gatedYes = 0; const sponsored: Act[] = []; const uncounted: Act[] = [];
  const records = input.findings.filter((f) => f.kind === 'record');
  if (!records.length) return { lanes: ['no-record'] };
  if (!LEGISLATIVE_OFFICE.test(input.office)) lanes.add('other-office');
  if (input.named) lanes.add('named-in-rulings');
  for (const f of records) {
    if (!input.plainIds.has(f.id) || !f.act || !READ.has(f.act) || f.local_record || !f.instrument_id) { lanes.add('note-says-more'); continue; }
    const id = f.instrument_id;
    const row = table[id]; const bill = input.bill(id);
    if (!row || !bill?.inStore) { lanes.add('missing-bill'); continue; }
    const exact = perVoteEntry(f, row);
    const rung = exact ? exact.rung : tryRung.has(id) ? tryRung.get(id)! : row.rung;
    // The script words a seat with the row's own deciding words, which decide the ROW's rung. A vote read at another
    // rung needs its own words: Opus.
    if (exact && exact.rung !== null && exact.rung !== row.rung) lanes.add('per-vote-note');
    if (!id.startsWith(input.billPrefix)) lanes.add('other-jurisdiction');
    if ((row.flag ?? '').trim()) lanes.add('flagged-bill');
    const isSponsor = SPONSOR.has(f.act);
    if (isSponsor) sponsorships++;
    const gate = isSponsor ? sponsorGate(bill) : f.gate ?? 'none';
    if (isSponsor) sponsored.push({ id: f.id, bill: id, act: f.act, date: f.date, rung, gate });
    const isVote = f.act === 'yea' || f.act === 'nay';
    if (isVote && (gate !== 'none' || rung === null)) uncounted.push({ id: f.id, bill: id, act: f.act, date: f.date, rung, gate });
    if (gate !== 'none') { if (YES.has(f.act)) gatedYes++; continue; }
    const act: Act = { id: f.id, bill: id, act: f.act, date: f.date, rung, tally: tallyOf(f) };
    if (f.act === 'nay') nays.push(act);
    else if (YES.has(f.act) && rung !== null) {
      if (sideOf(rung) === undefined) lanes.add('missing-bill');
      else yes.push(act);
    }
  }
  const s0 = yes.filter((a) => sideOf(a.rung!) === 0); const s1 = yes.filter((a) => sideOf(a.rung!) === 1);
  const newest = (a: Act, b: Act) => (a.date < b.date ? 1 : a.date > b.date ? -1 : 0);
  let decision: Decision | undefined;
  if (s0.length && s1.length) lanes.add('both-sides');
  else if (yes.length) {
    const side = s0.length ? 0 : 1;
    const value = side === 0 ? Math.min(...s0.map((a) => a.rung!)) : Math.max(...s1.map((a) => a.rung!));
    const deciding = yes.filter((a) => a.rung === value).sort(newest);
    // A No on a bill at the seat's rung, later than every Yes there, may replace the Yes (Missouri, transit carry).
    if (nays.some((n) => n.rung === value && n.date > deciding[0].date)) lanes.add('later-no');
    decision = { outcome: 'seated', value, deciding, sameSide: yes.filter((a) => a.rung !== value).sort(newest), nays: nays.sort(newest), gatedYes };
  } else {
    // No usable Yes act. A sponsorship here is on a bill the table gives no rung, or it is gated: it supports no
    // position, so it cannot change the result (ruling 2026-11-16; replay: 86 of 86 such people were coded
    // doesn't-fit by a blind Opus coder, across UT, WA, FL, KY, SC, CA and MO). The script writes the blank when
    // the rest of the record is plain: No votes on one side, or nothing else at all.
    const rungNays = nays.filter((n) => n.rung !== null && sideOf(n.rung) !== undefined);
    const sidesHit = new Set(rungNays.map((n) => sideOf(n.rung!)));
    const extra = sponsored.length ? { sponsored: sponsored.sort(newest) } : {};
    if (rungNays.length && sidesHit.size === 1) {
      decision = { outcome: 'doesnt-fit', deciding: rungNays.sort(newest), sameSide: [], nays: nays.sort(newest), gatedYes, naySide: [...sidesHit][0] as 0 | 1, ...extra };
    } else if (sponsorships && !rungNays.length) {
      decision = { outcome: 'doesnt-fit', deciding: [], sameSide: [], nays: nays.sort(newest), gatedYes, ...extra, sponsorOnly: true };
    } else if (!sponsorships && !rungNays.length && uncounted.length) {
      // Votes on file, none of which counts, and nothing else (ruling 2026-11-18; replay: 67 of 67 such people were
      // coded doesn't-fit by a blind Opus coder, across SD, MS, OH, UT, WA, FL, KY, SC and CA).
      decision = { outcome: 'doesnt-fit', deciding: [], sameSide: [], nays: nays.sort(newest), gatedYes, uncounted: uncounted.sort(newest) };
    } else lanes.add(sponsorships ? 'sponsor-no-rung' : 'blank-not-plain');
  }
  return { lanes: [...lanes], decision };
}

const same = (a: RuleResult, b: RuleResult) =>
  a.decision?.outcome === b.decision?.outcome && a.decision?.value === b.decision?.value && a.lanes.slice().sort().join() === b.lanes.slice().sort().join();

/**
 * The record-only result for one person: lanes (an Opus coder decides) or a decision (the script writes it).
 * A vote that fits one entry of a bill's `per_vote.votes` is read at that entry's rung. Any other act on a bill with
 * a `per_vote` note is tried at each rung its votes may carry; when any of them changes the result or opens a lane,
 * the person goes to Opus.
 */
export function decideRecord(input: RuleInput): RuleResult {
  const base = core(input);
  const open = (f: CoderFinding) => !!f.instrument_id && !!input.table[f.instrument_id]?.per_vote && !perVoteEntry(f, input.table[f.instrument_id]);
  const noted = [...new Set(input.findings.filter((f) => f.kind === 'record' && open(f)).map((f) => f.instrument_id!))];
  if (noted.length && noted.length <= 6) {
    const combos = noted.reduce<(number | null)[][]>((acc, id) => acc.flatMap((c) => input.table[id].per_vote!.rungs.map((r) => [...c, r])), [[]]);
    for (const combo of combos) {
      if (!same(core(input, new Map(noted.map((id, i) => [id, combo[i]]))), base)) { base.lanes.push('per-vote-note'); break; }
    }
  } else if (noted.length) base.lanes.push('per-vote-note');
  if (base.lanes.length) return { lanes: [...new Set(base.lanes)] };
  return base;
}

// ---------- the code's words ----------

/** `CA-AB-1127-2025` → `AB 1127 (2025)`, as the coder brief asks; undefined for ids the gate may not read.
 *  An older Colorado id keeps the year in the number (`CO-SB25-003-2025` → `SB 3 (2025)`); the gate reads it the same way (storeIdToken). */
export function billName(id: string): string | undefined {
  const m = /^[A-Z]{2}-([A-Z]+)(?:\d{2})?-(\d+)-((?:19|20)\d{2})$/.exec(id);
  return m ? `${m[1]} ${Number(m[2])} (${m[3]})` : undefined;
}

const list = (names: string[], max = 4) => {
  const u = [...new Set(names)];
  return u.length > max ? `${u.slice(0, max).join(', ')} and ${u.length - max} more` : u.join(', ').replace(/, ([^,]*)$/, ' and $1');
};
const sentence = (s: string) => { const t = s.trim(); return /[.!?]$/.test(t) ? t : `${t}.`; };
const actWords = (a: Act) => (SPONSOR.has(a.act) ? 'Sponsored' : 'Voted Yes on');

export interface CodeWords { reasoning: string; open_note?: string; finding_ids: string[]; blank_class?: 'nay-only' | 'wording' | 'gate'; tags?: string[]; shows_side?: boolean }

/**
 * The reasoning (and, for a blank, the open note) for a decision, written from the bill table's deciding words
 * and the ladder's own rung texts. Returns undefined when the deciding bill cannot be named or quoted: the
 * caller then sends the person to Opus instead of writing weaker text. `withWhy` false leaves the table's `why`
 * out (the caller retries that way when a check refuses the first text).
 */
export function wordsFor(d: Decision, table: Readonly<Record<string, RuleBillRow>>, rungText: (rung: number) => string | undefined, withWhy = true): CodeWords | undefined {
  const named = (as: Act[]) => as.map((a) => billName(a.bill)).filter((n): n is string => !!n);
  if (d.outcome === 'seated') {
    const top = d.deciding.find((a) => billName(a.bill) && (table[a.bill].deciding_words ?? '').trim());
    const text = rungText(d.value!)?.replace(/\.$/, '');
    if (!top || !text) return undefined;
    const row = table[top.bill];
    const cited = [top, ...d.deciding.filter((a) => a !== top && billName(a.bill)).slice(0, 2)];
    const parts = [
      `${actWords(top)} ${billName(top.bill)}${top.act === 'yea' ? ` on ${top.date}${top.tally ? ` (${top.tally})` : ''}` : ''}. The bill says "${row.deciding_words!.trim()}".`,
    ];
    if (withWhy && row.why?.trim()) parts.push(sentence(row.why));
    parts.push(`That meets "${text}", and it is the furthest counted act in the record.`);
    const alsoTop = named(d.deciding.filter((a) => a.bill !== top.bill));
    if (alsoTop.length) parts.push(`Other counted Yes acts at the same position: ${list(alsoTop)}.`);
    const below = named(d.sameSide).filter((n) => n !== billName(top.bill));
    if (below.length) parts.push(`Counted Yes acts on the same side that go less far: ${list(below)}.`);
    const no = named(d.nays);
    if (no.length) parts.push(`No votes (${list(no)}) show a direction only and do not change this.`);
    if (d.gatedYes) parts.push(`${d.gatedYes} Yes ${d.gatedYes === 1 ? 'act' : 'acts'} on near-unanimous or multi-subject bills ${d.gatedYes === 1 ? 'is' : 'are'} not counted.`);
    return { reasoning: parts.join(' '), finding_ids: [...new Set(cited.map((a) => a.id))] };
  }
  // What the sponsorships on file are, and why none of them counts: said in both kinds of blank.
  const sp = (d.sponsored ?? []).filter((a) => billName(a.bill));
  const noRung = sp.filter((a) => a.gate === 'none'); const gatedSp = sp.filter((a) => a.gate !== 'none');
  const spWords = [
    noRung.length ? `the bill table gives ${list(named(noRung))} no position on the ladder` : '',
    gatedSp.length ? `${list(named(gatedSp))} ${new Set(gatedSp.map((a) => a.bill)).size === 1 ? 'is a near-unanimous or multi-subject bill' : 'are near-unanimous or multi-subject bills'}, which a sponsorship does not count on` : '',
  ].filter(Boolean).join(', and ');
  if (d.sponsorOnly) {
    if (!sp.length || (d.sponsored ?? []).length !== sp.length) return undefined;
    const first = noRung.find((a) => (table[a.bill].why ?? '').trim());
    const why = withWhy && first ? ` On ${billName(first.bill)}: ${sentence(table[first.bill].why!)}` : '';
    const gated = d.gatedYes > gatedSp.length ? ` ${d.gatedYes - gatedSp.length} Yes ${d.gatedYes - gatedSp.length === 1 ? 'vote' : 'votes'} on near-unanimous or multi-subject bills ${d.gatedYes - gatedSp.length === 1 ? 'is' : 'are'} not counted.` : '';
    return {
      reasoning: `The counted record holds no Yes act on a bill with a position on the ladder, and no No vote on one. Sponsored ${list(named(sp))}: ${spWords}.${why}${gated}`,
      open_note: `Sponsored ${list(named(sp), 6)}. None of these supports a position: ${spWords}. The record has no counted vote on a bill that would.${gated}`,
      finding_ids: [...new Set(sp.slice(0, 8).map((a) => a.id))],
      blank_class: 'wording',
    };
  }
  if (d.uncounted?.length && !d.deciding.length) {
    const un = d.uncounted.filter((a) => billName(a.bill));
    if (!un.length || un.length !== d.uncounted.length) return undefined;
    const gatedV = un.filter((a) => a.gate !== 'none'); const noRungV = un.filter((a) => a.gate === 'none');
    const firstWhy = noRungV.find((a) => (table[a.bill].why ?? '').trim());
    const why = withWhy && firstWhy ? ` On ${billName(firstWhy.bill)}: ${sentence(table[firstWhy.bill].why!)}` : '';
    const parts = [
      noRungV.length ? `the bill table gives ${list(named(noRungV))} no position on the ladder` : '',
      gatedV.length ? `${list(named(gatedV))} ${new Set(gatedV.map((a) => a.bill)).size === 1 ? 'is a near-unanimous or multi-subject bill' : 'are near-unanimous or multi-subject bills'}, where a vote is not counted` : '',
    ].filter(Boolean).join(', and ');
    return {
      reasoning: `The record holds votes, and none of them counts toward a position. Voted on ${list(named(un))}: ${parts}.${why} There is no sponsorship, and no vote on a bill that would show a position.`,
      open_note: `Voted on ${list(named(un), 6)}. None of these votes supports a position: ${parts}. The record has no sponsorship and no counted vote on a bill with a position on the ladder.`,
      finding_ids: [...new Set(un.slice(0, 8).map((a) => a.id))],
      blank_class: noRungV.length ? 'wording' : 'gate',
    };
  }
  const also = sp.length ? ` Also sponsored ${list(named(sp))}: ${spWords}.` : '';
  const bills = named(d.deciding);
  const rungs = [...new Set(d.deciding.map((a) => a.rung!))].sort();
  const texts = rungs.map((r) => rungText(r)?.replace(/\.$/, ''));
  if (!bills.length || texts.some((t) => !t)) return undefined;
  const what = texts.map((t) => `"${t}"`).join(' or ');
  const gated = d.gatedYes ? ` ${d.gatedYes} Yes ${d.gatedYes === 1 ? 'act' : 'acts'} on near-unanimous or multi-subject bills ${d.gatedYes === 1 ? 'is' : 'are'} not counted.` : '';
  return {
    reasoning: `The counted record holds No votes only, on ${list(bills)}: bills that would ${what}. A No shows a side but names no position, and no counted Yes act supports one.${gated}${also}`,
    open_note: `Voted No on ${list(bills, 6)}, bills that would ${what}. That leans against those bills, but a No does not say which position the person holds, and the record has no counted Yes act on a bill that supports one.${gated}${also}`,
    finding_ids: [...new Set(d.deciding.filter((a) => billName(a.bill)).slice(0, 8).map((a) => a.id))],
    blank_class: 'nay-only', tags: ['direction-only'], shows_side: true,
  };
}

const bareName = (fullName: string) => fullName.replace(/"[^"]*"/g, ' ').replace(/,.*$/, '').split(/\s+/).filter((w) => w && !/^(jr|sr|ii|iii|iv)\.?$/i.test(w));

/**
 * Names from the roster that the state's rulings section mentions (full name, or surname as a whole word).
 * `sameSurname`: the full names of the OTHER roster people who share this surname. A surname that is only the end of
 * one of their names ("Cecil Thomas") does not name this person (Jim Thomas). Ohio, 2026-11-16: 5 of the 10 people
 * held by a name were held by a namesake's. A bare surname, or one after any other word, still names everyone who
 * carries it.
 */
export function namedInRulings(fullName: string, rulingsSection: string, sameSurname: readonly string[] = []): boolean {
  const words = bareName(fullName);
  const last = words[words.length - 1];
  if (!last) return false;
  if (rulingsSection.includes(fullName)) return true;
  const esc = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const others = sameSurname.map((n) => bareName(n).join(' ')).filter((n) => n && n !== words.join(' '));
  for (const m of rulingsSection.matchAll(new RegExp(`(?<![\\w-])${esc(last)}(?![\\w-])`, 'g'))) {
    const upTo = rulingsSection.slice(0, m.index! + last.length);
    if (!others.some((o) => upTo.endsWith(o))) return true;
  }
  return false;
}

const BILL_ID = /(?<![\w-])[A-Z]{2}(?:-[A-Z0-9]+)+-\d{4}(?![\w-])/g;

/**
 * The part of the unit's rulings that `namedInRulings` should read. A ruling about what a BILL is ends with
 * "People: …", the list of everyone who holds an act on it. Once the bill table carries that ruling, the list
 * says nothing about the person: the script reads the same row a coder would. Tennessee's eleven such lists named
 * all 129 people with a record, so the script coded nobody (2026-11-14); without them it codes 94, each the same
 * as the Opus code. From 2026-11-16 the same holds for a name anywhere in such a line ("UT-HB-180-2026 (sponsor
 * Andrew Stoddard) is rung 3"): Utah's stop-1 answers named 14 people that way. Replay over UT, FL, KY, SC, TN and
 * CA: 85 people held only by a name, and the script's code is the blind Opus code for all 85. These forms are
 * dropped only when the line names at least one bill and EVERY bill it names has an answered row in the table; a
 * name outside them is the ruling's subject and still holds the person. Only the unit's own bills count (`billPrefix`): a ruling often cites
 * another state's bill as its precedent, and that bill is never in this table. Any other name stays: a ruling about a person, a list with no bill
 * before it, and a list beside a bill the table lacks or still flags.
 */
export function rulingsNameText(rulingsSection: string, table: Record<string, RuleBillRow>, billPrefix: string): string {
  return rulingsSection.split('\n').map((line) => {
    const at = line.indexOf(' People: ');
    const body = at < 0 ? line : line.slice(0, at);
    const bills = (body.match(BILL_ID) ?? []).filter((b) => b.startsWith(billPrefix));
    const settled = bills.length > 0 && bills.every((b) => table[b] && !(table[b].flag ?? '').trim());
    if (!settled) return line;
    // The line says what its bills are, and the table carries that. Three forms only say who holds an act on the
    // bill, and are dropped: the People list, a bracket with no bill in it ("(sponsor Ann Able)", "(Ann Able, Bob
    // Both)"), and a "Sponsors: …" list, which runs to the end of the line (a name holds a full stop: "Keven J.
    // Stratton"). A name anywhere else is the ruling's subject and stays
    // ("Ann Able (XX-HB-2-2025) keeps a rung 2 sponsorship").
    return body.replace(/\(([^()]*)\)/g, (m, inner: string) => (BILL_ID.test(inner) ? (BILL_ID.lastIndex = 0, m) : '')).replace(/\b(?:Co-?)?[Ss]ponsors?: .*$/, '');
  }).join('\n');
}

/** The `## … {state:xx}` or `{federal}` sections of the rulings digest: the unit's own notes. */
export function unitSections(md: string, unit: string): string {
  const tag = unit === 'federal' ? 'federal' : unit.replace(/^state:/, '');
  const out: string[] = [];
  let on = false;
  for (const line of md.split('\n')) {
    if (/^#{1,6}\s/.test(line)) {
      const m = /\{([^}]+)\}/.exec(line);
      const scope = (m?.[1] ?? 'all').toLowerCase();
      on = unit === 'federal' ? scope === 'federal' : new RegExp(`^state:(?:[a-z]{2}\\s*,\\s*)*${tag}(?:\\s*,|$)`).test(scope);
    }
    if (on) out.push(line);
  }
  return out.join('\n');
}

/** A seeded sample for the standing check: `n` ids, half from `prefer` when it has that many (FNV-1a order). */
export function seededSample(ids: readonly string[], n: number, seed: string, prefer: ReadonlySet<string> = new Set()): string[] {
  const h = (s: string) => { let x = 2166136261; for (const c of `${seed}|${s}`) { x ^= c.charCodeAt(0); x = Math.imul(x, 16777619) >>> 0; } return x; };
  const order = [...ids].sort((a, b) => h(a) - h(b) || a.localeCompare(b));
  const first = order.filter((p) => prefer.has(p)).slice(0, Math.ceil(n / 2));
  const rest = order.filter((p) => !first.includes(p)).slice(0, n - first.length);
  return [...first, ...rest].sort();
}

/**
 * The standing check: each check person's blind Opus code against the script's. A difference in outcome or rung
 * is listed; any entry stops the release of every script code. A check person with no Opus code, or whose "Opus"
 * code is itself a script code, is a difference too: an unrun or unblind check must never pass.
 */
export function standingCheckDifferences(
  checkIds: readonly string[],
  script: (pid: string) => { outcome: string; value?: number } | undefined,
  opus: (pid: string) => { outcome: string; value?: number; coded_by?: string } | undefined,
): string[] {
  const lab = (c: { outcome: string; value?: number }) => `${c.outcome}${c.value === undefined ? '' : ` ${c.value}`}`;
  const out: string[] = [];
  for (const pid of checkIds) {
    const s = script(pid); const o = opus(pid);
    if (!s) out.push(`${pid}: no script code in the holding folder`);
    else if (!o) out.push(`${pid}: no Opus code yet`);
    else if (o.coded_by === SCRIPT_CODER) out.push(`${pid}: the comparison code is a script code, not a blind Opus code`);
    else if (o.outcome !== s.outcome || o.value !== s.value) out.push(`${pid}: script ${lab(s)} | Opus ${lab(o)}`);
  }
  return out;
}
