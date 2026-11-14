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
  per_vote?: { rungs: (number | null)[]; note?: string };
}

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
  'sponsor-no-rung': 'no usable rung act, but sponsorships on file',
  'named-in-rulings': "the state's rulings name this person",
  'per-vote-note': 'a vote the rulings read differently from the bill table, and it could change the result',
  'other-office': 'the roster office is not a legislative seat, so the record may come from another office',
  'missing-bill': 'a finding names a bill the bill table or the store does not hold',
  'flagged-bill': 'an act on a bill whose flag the runner has not answered',
  'note-says-more': 'a record finding whose note says more than the plain facts, or an act the rule does not read',
  'other-jurisdiction': 'an act on a bill of another legislature',
  'blank-not-plain': 'no usable rung act, and not a plain No-votes-only record',
  'no-record': 'no record finding on file',
};

export interface Act { id: string; bill: string; act: string; date: string; rung: number | null; tally?: string }

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

function core(input: RuleInput, table: Readonly<Record<string, RuleBillRow>>): RuleResult {
  const lanes = new Set<Lane>();
  const sideOf = (r: number) => (input.sides[0].includes(r) ? 0 : input.sides[1].includes(r) ? 1 : undefined);
  const yes: Act[] = []; const nays: Act[] = [];
  let sponsorships = 0; let gatedYes = 0;
  const records = input.findings.filter((f) => f.kind === 'record');
  if (!records.length) return { lanes: ['no-record'] };
  if (!LEGISLATIVE_OFFICE.test(input.office)) lanes.add('other-office');
  if (input.named) lanes.add('named-in-rulings');
  for (const f of records) {
    if (!input.plainIds.has(f.id) || !f.act || !READ.has(f.act) || f.local_record || !f.instrument_id) { lanes.add('note-says-more'); continue; }
    const id = f.instrument_id;
    const row = table[id]; const bill = input.bill(id);
    if (!row || !bill?.inStore) { lanes.add('missing-bill'); continue; }
    if (!id.startsWith(input.billPrefix)) lanes.add('other-jurisdiction');
    if ((row.flag ?? '').trim()) lanes.add('flagged-bill');
    const isSponsor = SPONSOR.has(f.act);
    if (isSponsor) sponsorships++;
    const gate = isSponsor ? sponsorGate(bill) : f.gate ?? 'none';
    if (gate !== 'none') { if (YES.has(f.act)) gatedYes++; continue; }
    const act: Act = { id: f.id, bill: id, act: f.act, date: f.date, rung: row.rung, tally: tallyOf(f) };
    if (f.act === 'nay') nays.push(act);
    else if (YES.has(f.act) && row.rung !== null) {
      if (sideOf(row.rung) === undefined) lanes.add('missing-bill');
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
  } else if (sponsorships) lanes.add('sponsor-no-rung');
  else {
    const rungNays = nays.filter((n) => n.rung !== null && sideOf(n.rung) !== undefined);
    const sidesHit = new Set(rungNays.map((n) => sideOf(n.rung!)));
    if (rungNays.length && sidesHit.size === 1) {
      decision = { outcome: 'doesnt-fit', deciding: rungNays.sort(newest), sameSide: [], nays: nays.sort(newest), gatedYes, naySide: [...sidesHit][0] as 0 | 1 };
    } else lanes.add('blank-not-plain');
  }
  return { lanes: [...lanes], decision };
}

const same = (a: RuleResult, b: RuleResult) =>
  a.decision?.outcome === b.decision?.outcome && a.decision?.value === b.decision?.value && a.lanes.slice().sort().join() === b.lanes.slice().sort().join();

/**
 * The record-only result for one person: lanes (an Opus coder decides) or a decision (the script writes it).
 * A bill with a `per_vote` note is tried at each rung its votes may carry; when any of them changes the result
 * or opens a lane, the person goes to Opus.
 */
export function decideRecord(input: RuleInput): RuleResult {
  const base = core(input, input.table);
  const noted = [...new Set(input.findings.map((f) => f.instrument_id).filter((id): id is string => !!id && !!input.table[id]?.per_vote))];
  if (noted.length && noted.length <= 6) {
    const combos = noted.reduce<(number | null)[][]>((acc, id) => acc.flatMap((c) => input.table[id].per_vote!.rungs.map((r) => [...c, r])), [[]]);
    for (const combo of combos) {
      const t = { ...input.table };
      noted.forEach((id, i) => { t[id] = { ...t[id], rung: combo[i] }; });
      if (!same(core(input, t), base)) { base.lanes.push('per-vote-note'); break; }
    }
  } else if (noted.length) base.lanes.push('per-vote-note');
  if (base.lanes.length) return { lanes: [...new Set(base.lanes)] };
  return base;
}

// ---------- the code's words ----------

/** `CA-AB-1127-2025` → `AB 1127 (2025)`, as the coder brief asks; undefined for ids the gate may not read. */
export function billName(id: string): string | undefined {
  const m = /^[A-Z]{2}-([A-Z]+)-(\d+)-((?:19|20)\d{2})$/.exec(id);
  return m ? `${m[1]} ${Number(m[2])} (${m[3]})` : undefined;
}

const list = (names: string[], max = 4) => {
  const u = [...new Set(names)];
  return u.length > max ? `${u.slice(0, max).join(', ')} and ${u.length - max} more` : u.join(', ').replace(/, ([^,]*)$/, ' and $1');
};
const sentence = (s: string) => { const t = s.trim(); return /[.!?]$/.test(t) ? t : `${t}.`; };
const actWords = (a: Act) => (SPONSOR.has(a.act) ? 'Sponsored' : 'Voted Yes on');

export interface CodeWords { reasoning: string; open_note?: string; finding_ids: string[]; blank_class?: 'nay-only'; tags?: string[]; shows_side?: boolean }

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
  const bills = named(d.deciding);
  const rungs = [...new Set(d.deciding.map((a) => a.rung!))].sort();
  const texts = rungs.map((r) => rungText(r)?.replace(/\.$/, ''));
  if (!bills.length || texts.some((t) => !t)) return undefined;
  const what = texts.map((t) => `"${t}"`).join(' or ');
  const gated = d.gatedYes ? ` ${d.gatedYes} Yes ${d.gatedYes === 1 ? 'act' : 'acts'} on near-unanimous or multi-subject bills ${d.gatedYes === 1 ? 'is' : 'are'} not counted.` : '';
  return {
    reasoning: `The counted record holds No votes only, on ${list(bills)}: bills that would ${what}. A No shows a side but names no position, and no counted Yes act supports one.${gated}`,
    open_note: `Voted No on ${list(bills, 6)}, bills that would ${what}. That leans against those bills, but a No does not say which position the person holds, and the record has no counted Yes act on a bill that supports one.${gated}`,
    finding_ids: [...new Set(d.deciding.filter((a) => billName(a.bill)).slice(0, 8).map((a) => a.id))],
    blank_class: 'nay-only', tags: ['direction-only'], shows_side: true,
  };
}

/** Names from the roster that the state's rulings section mentions (full name, or surname as a whole word). */
export function namedInRulings(fullName: string, rulingsSection: string): boolean {
  const words = fullName.replace(/"[^"]*"/g, ' ').replace(/,.*$/, '').split(/\s+/).filter((w) => w && !/^(jr|sr|ii|iii|iv)\.?$/i.test(w));
  const last = words[words.length - 1];
  if (!last) return false;
  const esc = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return rulingsSection.includes(fullName) || new RegExp(`(?<![\\w-])${esc(last)}(?![\\w-])`).test(rulingsSection);
}

const BILL_ID = /(?<![\w-])[A-Z]{2}(?:-[A-Z0-9]+)+-\d{4}(?![\w-])/g;

/**
 * The part of the unit's rulings that `namedInRulings` should read. A ruling about what a BILL is ends with
 * "People: …", the list of everyone who holds an act on it. Once the bill table carries that ruling, the list
 * says nothing about the person: the script reads the same row a coder would. Tennessee's eleven such lists named
 * all 129 people with a record, so the script coded nobody (2026-11-14); without them it codes 94, each the same
 * as the Opus code. A list is dropped only when the text before it names at least one bill and EVERY bill it
 * names has an answered row in the table. Only the unit's own bills count (`billPrefix`): a ruling often cites
 * another state's bill as its precedent, and that bill is never in this table. Any other name stays: a ruling about a person, a list with no bill
 * before it, and a list beside a bill the table lacks or still flags.
 */
export function rulingsNameText(rulingsSection: string, table: Record<string, RuleBillRow>, billPrefix: string): string {
  return rulingsSection.split('\n').map((line) => {
    const at = line.indexOf(' People: ');
    if (at < 0) return line;
    const body = line.slice(0, at);
    const bills = (body.match(BILL_ID) ?? []).filter((b) => b.startsWith(billPrefix));
    const settled = bills.length > 0 && bills.every((b) => table[b] && !(table[b].flag ?? '').trim());
    return settled ? body : line;
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
