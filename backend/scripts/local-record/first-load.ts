/**
 * first-load.ts — read every vote document of a city since 2020-12-01, compare with the hand-built inventory, draw
 * spot checks, and (only with --apply) write to the database and storage.
 *
 *   npm run local-record:first-load --prefix backend -- --city place:1805860 --inventory <abs dir> --out <abs dir> [--seed N] [--sponsor-seed N] [--cache <abs dir>] [--apply]
 *
 * A dry run reads the city's public site and writes its files to --out (exceptions.json lists every exception with
 * its detail; sponsorships.json, sponsor-compare.md and sponsor-spotcheck.json cover council sponsors). It never opens a database or storage call. Exceptions found in a dry run live in the --out files only;
 * --apply is the one path that writes anything. --cache keeps each download on disk, keyed by URL, and reuses it.
 */
import 'dotenv/config';
import { appendFileSync, existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';
import { checkRollCall } from '../../src/lib/localRecord/checks.js';
import { normaliseName, type NameFile, type TermSpan } from '../../src/lib/localRecord/names.js';
import { parseMinutes, minutesTextFromPdf, twoDigits } from '../../src/lib/localRecord/onboard/minutes.js';
import { fetchJson, type VoteDocument } from '../../src/lib/localRecord/onboard/feed.js';
import {
  buildContext, documentProblem, documentSponsorFindings, fallbackDocument, feedSponsorFindings, fetchBytes, governingDocuments, makeStorage, parseCityConfigs,
  readFeeds, type CityConfig, type Connection, type RefreshDeps,
} from '../../src/lib/localRecord/refresh.js';
import { resolveSponsorships, sponsorSubject, type SponsorFinding, type Sponsorship } from '../../src/lib/localRecord/sponsorships.js';
import { externalVoteId, saveDocument, sha256Hex, type StorageLike } from '../../src/lib/localRecord/store.js';
import { recordException, writeConfirmed, writeFeed, writeSponsorships } from '../../src/lib/localRecord/write.js';
import type { ExceptionCause, FeedItem, MinutesParse, MinutesRollCall, PrintedTally, ResolvedVote } from '../../src/lib/localRecord/types.js';

export const WINDOW_START = '2020-12-01';
const SPOT_COUNT = 30;
const SPONSOR_SPOT_COUNT = 30;
/** Causes that stop --apply. */
export const BLOCKING_CAUSES: ExceptionCause[] = ['inventory_disagrees', 'control_failed', 'spot_check_failed'];

// ---- inventory -------------------------------------------------------------------------------------------------

export interface InventoryItem {
  id: string;
  date: string;
  item_no: string;
  instrument?: string;
  /** Printed tally, "8-1" (yes-no); null when none. */
  tally?: string | null;
  members?: { name: string; vote: string; derived?: boolean }[];
  url_item?: string;
  url_minutes?: string;
  text_store_path?: string;
  /** The inventory's record type; OTHER is a row with no vote on the item (a first reading, a withdrawal). */
  record_type?: string;
  notes?: string;
}
export interface InventoryRoster { members: { name: string; from: string; to: string | null }[] }

/**
 * `place:1805860:<date>:<item_no>[ (<suffix>)]` -> the minutes' own key, or why the item is not compared.
 * No suffix = Final passage; `amendment N` = `Amendment NN` (two zero-padded digits, as the parser prints it); `veto override` = `Veto override`.
 */
export function parseInventoryId(id: string): { date: string; itemNumber: string; question: string } | { skip: string } {
  const m = /^place:\d+:(\d{4}-\d{2}-\d{2}):([^()]*?)(?: \((.*)\))?$/.exec(id);
  if (!m) return { skip: 'id not understood' };
  const [, date, itemNumber, suffix] = m;
  if (!/^(Ord|Res|App Ord) /.test(itemNumber)) return { skip: 'not a numbered ordinance or resolution' };
  if (suffix === undefined) return { date, itemNumber, question: 'Final passage' };
  if (/^motion\b/i.test(suffix)) return { skip: 'procedural motion' };
  const am = /^amendment (\d+)$/i.exec(suffix);
  if (am) return { date, itemNumber, question: `Amendment ${twoDigits(am[1])}` };
  if (suffix.toLowerCase() === 'veto override') return { date, itemNumber, question: 'Veto override' };
  return { skip: `suffix "${suffix}" has no roll call in the minutes` };
}

// ---- inventory corrections ---------------------------------------------------------------------------------------

/**
 * `<inventory>/corrections.json`: owner-approved fixes to the frozen, hash-locked inventory files. They are applied in
 * memory before the comparison; deep.json and full.json are never edited.
 * - `date`: the row's vote is on another date; `corrected.date` replaces the date in the row and its id.
 * - `duplicate_of`: the row is a second copy of `corrected.keep`, which stays; the row is dropped.
 * - `member_vote`: the minutes govern; `corrected.member` (as the row prints it) gets `corrected.vote`.
 */
export interface InventoryCorrection {
  row: string;
  kind: 'date' | 'duplicate_of' | 'member_vote';
  corrected: { date?: string; keep?: string; member?: string; vote?: string };
  evidence: { url: string; quote: string };
  added: string;
  note?: string;
}
export interface CorrectionsFile { corrections: InventoryCorrection[] }

/** Apply the corrections to a copy of the inventory. Throws on anything it cannot apply exactly. */
export function applyCorrections(
  inventory: InventoryItem[], file: CorrectionsFile,
): { inventory: InventoryItem[]; applied: InventoryCorrection[] } {
  let rows: InventoryItem[] = inventory.map((i) => ({ ...i, members: i.members?.map((m) => ({ ...m })) }));
  const find = (id: string) => rows.find((r) => r.id === id);
  for (const c of file.corrections) {
    const fail = (why: string): never => { throw new Error(`corrections.json: ${why}`); };
    if (!c.evidence?.url || !c.evidence?.quote) fail(`${c.row}: an entry needs evidence (url and quote)`);
    const row = find(c.row) ?? fail(`${c.row} is not in the inventory`);
    if (c.kind === 'date') {
      const date = c.corrected.date ?? '';
      if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) fail(`${c.row}: corrected.date "${date}" is not a date`);
      const id = c.row.replace(/^(place:\d+:)\d{4}-\d{2}-\d{2}:/, `$1${date}:`);
      if (find(id)) fail(`${c.row}: moving it to ${date} collides with ${id}; use duplicate_of`);
      row.id = id;
      row.date = date;
    } else if (c.kind === 'duplicate_of') {
      const keep = c.corrected.keep ?? '';
      if (keep === c.row || !find(keep)) fail(`${c.row}: the kept row ${keep} is not in the inventory`);
      rows = rows.filter((r) => r !== row);
    } else if (c.kind === 'member_vote') {
      const hits = (row.members ?? []).filter((m) => m.name === c.corrected.member);
      if (hits.length !== 1 || !c.corrected.vote) fail(`${c.row}: member "${c.corrected.member}" is not on the row once, or no vote given`);
      hits[0].vote = c.corrected.vote!;
    } else {
      fail(`${c.row}: unknown kind "${(c as { kind: string }).kind}"`);
    }
  }
  return { inventory: rows, applied: file.corrections };
}

const describeCorrection = (c: InventoryCorrection) =>
  c.kind === 'date' ? `date → ${c.corrected.date}`
    : c.kind === 'duplicate_of' ? `duplicate of ${c.corrected.keep} (dropped)`
      : `member_vote ${c.corrected.member} → ${c.corrected.vote}`;

// ---- owner checks --------------------------------------------------------------------------------------------------

/**
 * `<inventory>/owner-checks.json`: the owner's own check, by eye against the city's documents, of inventory votes the
 * reader could not confirm. A confirmed check turns an `inventory only` row into an owner-checked roll call (written
 * with source `owner-check`). A held check keeps its exception, which stops blocking --apply but stays open.
 * Nothing here touches the reader's roll calls, the spot-check pool or reader-output.json.
 */
export interface OwnerCheck {
  /**
   * What the check is about; absent or 'votes' = the inventory row's vote (the original meaning). 'sponsors' = the
   * owner looked at the row's sponsors and lets the sponsor difference through. A sponsor check never writes a sponsorship.
   */
  about?: 'votes' | 'sponsors';
  inventoryId: string;
  date: string;
  item: string;
  tally: string;
  cause: string;
  ownerAnswer: 'yes' | 'no' | 'unsure';
  ownerNote: string;
  answeredAt: string;
  documents: string[];
  followUp?: { result: 'matches' | 'feed_only'; evidence?: string; quote?: string; why: string };
}
export interface OwnerChecksFile { checks: OwnerCheck[] }
export type CheckedOwnerCheck = OwnerCheck & { verdict: 'confirmed' | 'held' };

/** Confirmed when a follow-up matches, or the owner said yes and nothing contradicts it; held otherwise. */
export const ownerVerdict = (c: OwnerCheck): 'confirmed' | 'held' =>
  c.followUp ? (c.followUp.result === 'matches' ? 'confirmed' : 'held') : c.ownerAnswer === 'yes' ? 'confirmed' : 'held';

export function validateOwnerChecks(inventory: InventoryItem[], file: OwnerChecksFile): CheckedOwnerCheck[] {
  const fail = (why: string): never => { throw new Error(`owner-checks.json: ${why}`); };
  const known = new Set(inventory.map((i) => i.id));
  const seen = new Set<string>();
  return file.checks.map((c) => {
    if (!known.has(c.inventoryId)) fail(`${c.inventoryId} is not in the inventory`);
    if (!['yes', 'no', 'unsure'].includes(c.ownerAnswer)) fail(`${c.inventoryId}: answer "${c.ownerAnswer}" is not yes, no or unsure`);
    const key = `${c.inventoryId}|${c.about ?? 'votes'}`;
    if (seen.has(key)) fail(`${c.inventoryId} appears twice`);
    seen.add(key);
    return { ...c, verdict: ownerVerdict(c) };
  });
}

export interface OwnerCheckedRollCall {
  inventoryId: string;
  date: string;
  itemNumber: string;
  question: string;
  outcome: 'passed' | 'failed';
  tally: PrintedTally;
  /** The owner's own words from the follow-up, or a line saying who checked it, when, and against what. */
  sentence: string;
  documentUrl: string;
  votes: ResolvedVote[];
}
export interface OwnerResult {
  ownerChecked: OwnerCheckedRollCall[];
  held: { subject: string; reason: string }[];
  /** Confirmed by the owner, but failed the tally, name or outcome check: still a blocking exception. */
  failed: { subject: string; reason: string }[];
  /** Checks on rows the reader already covers (confirmed, differs) or that are not compared at all. */
  notNeeded: string[];
  /** cmp.exceptions with the owner's checks applied. */
  exceptions: FoundException[];
}

const POSITION_OF: Record<string, ResolvedVote['position']> = { yes: 'yea', no: 'nay', abstain: 'present', absent: 'absent' };

/** One confirmed check -> a roll call, or the reason it cannot be one. */
function buildOwnerChecked(
  inv: InventoryItem, check: OwnerCheck, p: { date: string; itemNumber: string; question: string },
  roster: InventoryRoster, names: NameFile, items: FeedItem[],
): OwnerCheckedRollCall | { reason: string; hold?: boolean } {
  const members = inv.members ?? [];
  if (!members.length) return { reason: 'the inventory lists no member votes, so there is nothing to load', hold: true };
  const documentUrl = check.documents?.[0];
  if (!documentUrl) return { reason: 'the owner check names no document' };
  const votes: ResolvedVote[] = [];
  const bad: string[] = [];
  for (const m of members) {
    const id = idForSurname(m.name, p.date, roster, names);
    const position = POSITION_OF[m.vote];
    if (typeof id !== 'string') { bad.push(id.error); continue; }
    if (!position) { bad.push(`"${m.name}" has vote "${m.vote}"`); continue; }
    votes.push({ politicianId: id, nameAsPrinted: m.name, position, workedOut: m.derived === true });
  }
  if (bad.length) return { reason: `a member could not be resolved: ${bad.join('; ')}` };
  if (new Set(votes.map((v) => v.politicianId)).size !== votes.length) return { reason: 'two inventory members resolve to the same person' };
  const count = (pos: string) => votes.filter((v) => v.position === pos).length;
  const tally: PrintedTally = { yes: count('yea'), no: count('nay'), abstain: count('present') };
  const printed = /^(\d+)-(\d+)/.exec(inv.tally ?? '');
  if (!printed) return { reason: `the inventory row prints no readable tally ("${inv.tally ?? ''}")` };
  if (Number(printed[1]) !== tally.yes || Number(printed[2]) !== tally.no) {
    return { reason: `the printed tally ${inv.tally} disagrees with the counted votes ${tally.yes}-${tally.no}` };
  }
  const feed = p.question === 'Final passage' ? items.find((i) => i.itemNumber === p.itemNumber)?.final : null;
  let outcome: 'passed' | 'failed';
  if (feed && feed.date === p.date) {
    if (feed.outcome === 'vetoed') return { reason: 'the feed lists this Final action as vetoed; the outcome is not decided here' };
    outcome = feed.outcome;
    if ((outcome === 'passed' && tally.yes <= tally.no) || (outcome === 'failed' && tally.yes > tally.no)) {
      return { reason: `the feed outcome (${outcome}) conflicts with the counted votes ${tally.yes}-${tally.no}` };
    }
  } else if (tally.yes >= 5 && tally.yes > tally.no) outcome = 'passed';
  else if (tally.yes <= tally.no) outcome = 'failed'; // a tie never passes a motion
  else return { reason: `the outcome cannot be told from the tally ${tally.yes}-${tally.no} and the feed has no Final action on ${p.date}` };
  const sentence = check.followUp?.quote?.trim() || `Checked by the owner on ${check.answeredAt.slice(0, 10)} against ${documentUrl}`;
  return { inventoryId: inv.id, date: p.date, itemNumber: p.itemNumber, question: p.question, outcome, tally, sentence, documentUrl, votes };
}

/**
 * Apply the owner's checks to the comparison. Only `inventory only` rows are touched: a confirmed check that passes
 * the tally, name and outcome checks becomes an owner-checked roll call and its exception goes; a held one keeps its
 * exception with `ownerHeld: true`; a confirmed one that fails a check keeps a blocking exception with the reason.
 */
export function applyOwnerChecks(
  cmp: Comparison, checks: CheckedOwnerCheck[], roster: InventoryRoster, names: NameFile, items: FeedItem[], inventory: InventoryItem[],
  reader: ReaderRollCall[] = [],
): OwnerResult {
  const res: OwnerResult = { ownerChecked: [], held: [], failed: [], notNeeded: [], exceptions: [] };
  checks = checks.filter((c) => (c.about ?? 'votes') === 'votes'); // sponsor checks are applied by applySponsorOwnerChecks
  const byId = new Map(checks.map((c) => [c.inventoryId, c]));
  const invById = new Map(inventory.map((i) => [i.id, i]));
  const open = new Set(cmp.exceptions
    .filter((e) => e.cause === 'inventory_disagrees' && (e.detail as { kind?: string }).kind === 'inventory only')
    .map((e) => (e.detail as { inventoryId: string }).inventoryId));
  for (const c of checks) if (!open.has(c.inventoryId)) res.notNeeded.push(c.inventoryId);

  // Keys the reader failed ON PURPOSE (a repeated Final, a duplicate key): the owner's check does not override them.
  const onPurpose = new Map<string, string>();
  for (const r of reader) {
    if (r.status !== 'failed' || !r.detail) continue;
    if (/already passed on /.test(r.detail) || /^\d+ roll calls in the vote document share this date/.test(r.detail)) onPurpose.set(keyOf(r), r.detail);
  }

  type Entry = { e: FoundException; d: Record<string, unknown>; built?: OwnerCheckedRollCall; hold?: string; fail?: string };
  const entries: (Entry | FoundException)[] = cmp.exceptions.map((e) => {
    const d = e.detail as { kind?: string; inventoryId?: string };
    const check = e.cause === 'inventory_disagrees' && d.kind === 'inventory only' ? byId.get(d.inventoryId as string) : undefined;
    if (!check) return e;
    const entry: Entry = { e, d: d as Record<string, unknown> };
    if (check.verdict === 'held') {
      entry.hold = check.followUp?.why || check.ownerNote || `owner answered "${check.ownerAnswer}"`;
      return entry;
    }
    const inv = invById.get(check.inventoryId) as InventoryItem;
    const p = parseInventoryId(inv.id);
    if ('skip' in p) { entry.fail = p.skip; return entry; }
    const built = buildOwnerChecked(inv, check, p, roster, names, items);
    if ('reason' in built) { if (built.hold) entry.hold = built.reason; else entry.fail = built.reason; return entry; }
    const purpose = onPurpose.get(keyOf(p));
    if (purpose) { entry.hold = purpose; return entry; }
    entry.built = built;
    return entry;
  });

  // An item passes once: an owner Final passage that passed is held when another passed Final of the item is on a
  // different date (a confirmed reader row, or an earlier owner row).
  const passed = new Map<string, Set<string>>();
  const note = (item: string, date: string) => passed.set(item, (passed.get(item) ?? new Set()).add(date));
  for (const r of reader) if (r.status === 'confirmed' && r.question === 'Final passage' && r.outcome === 'passed') note(r.itemNumber, r.date);
  const ownerFinals = entries.filter((x): x is Entry => 'e' in x && !!x.built && x.built.question === 'Final passage' && x.built.outcome === 'passed')
    .sort((a, b) => ((a.built as OwnerCheckedRollCall).date < (b.built as OwnerCheckedRollCall).date ? -1 : 1));
  for (const x of ownerFinals) {
    const o = x.built as OwnerCheckedRollCall;
    const other = [...(passed.get(o.itemNumber) ?? [])].filter((d) => d !== o.date).sort()[0];
    if (other) { x.hold = `${o.itemNumber} already passed on ${other}; a later vote is not a second Final passage`; x.built = undefined; }
    else note(o.itemNumber, o.date);
  }

  for (const x of entries) {
    if (!('e' in x)) { res.exceptions.push(x); continue; }
    const subject = x.e.subject;
    if (x.hold) {
      res.held.push({ subject, reason: x.hold });
      res.exceptions.push({ ...x.e, detail: { ...x.d, ownerHeld: true, reason: x.hold } });
    } else if (x.fail) {
      res.failed.push({ subject, reason: x.fail });
      res.exceptions.push({ ...x.e, detail: { ...x.d, ownerCheckFailed: x.fail } });
    } else if (x.built) res.ownerChecked.push(x.built);
  }
  return res;
}

/** A fingerprint of the owner-checked rows, so --apply writes the rows that were reviewed in the dry run. */
export const ownerHash = (rows: OwnerCheckedRollCall[]): string =>
  sha256Hex(new TextEncoder().encode(JSON.stringify([...rows].sort((a, b) => (a.inventoryId < b.inventoryId ? -1 : 1)))));

// ---- what the reader found ---------------------------------------------------------------------------------------

export interface ReaderRollCall {
  /** Position among the roll calls of its document. */
  index: number;
  date: string;
  itemNumber: string;
  question: string;
  status: 'confirmed' | 'failed';
  outcome: 'passed' | 'failed';
  tally: PrintedTally;
  /** Verbatim sentence from the vote document. */
  sentence: string;
  documentUrl: string;
  votes?: ResolvedVote[];
  feedDisagreement?: string | null;
  cause?: ExceptionCause;
  detail?: string;
}
export interface FoundException { cause: ExceptionCause; subject: string; detail: unknown }

const keyOf = (x: { date: string; itemNumber: string; question: string }) => `${x.date}|${x.itemNumber}|${x.question}`;
const subjectOf = (x: { date: string; itemNumber: string; question: string }) => `${x.date} ${x.itemNumber} ${x.question}`;

/**
 * Two roll calls with the same (date, item, question) cannot both be written. Both stay in the output as failed, with
 * one exception per key, so nothing is merged or dropped silently.
 */
export function flagDuplicates(reader: ReaderRollCall[]): { reader: ReaderRollCall[]; exceptions: FoundException[] } {
  const count = new Map<string, number>();
  for (const r of reader) count.set(keyOf(r), (count.get(keyOf(r)) ?? 0) + 1);
  const exceptions: FoundException[] = [];
  const out = reader.map((r) => {
    if ((count.get(keyOf(r)) ?? 0) < 2) return r;
    const detail = `${count.get(keyOf(r))} roll calls in the vote document share this date, item and question`;
    return { ...r, status: 'failed' as const, cause: 'unparsed_roll_call' as const, detail };
  });
  for (const [k, n] of count) {
    if (n < 2) continue;
    const r = reader.find((x) => keyOf(x) === k) as ReaderRollCall;
    exceptions.push({ cause: 'unparsed_roll_call', subject: subjectOf(r), detail: { kind: 'duplicate roll call', count: n, sentences: reader.filter((x) => keyOf(x) === k).map((x) => x.sentence) } });
  }
  return { reader: out, exceptions };
}

/**
 * An item passes once. When the reader confirms two passed Final passages of one item on different dates, the later
 * one (a veto override or re-vote the minutes word as "adopt") is held as an exception.
 */
export function flagRepeatedFinals(reader: ReaderRollCall[]): { reader: ReaderRollCall[]; exceptions: FoundException[] } {
  const first = new Map<string, string>();
  for (const r of reader) {
    if (r.status !== 'confirmed' || r.question !== 'Final passage' || r.outcome !== 'passed') continue;
    const d = first.get(r.itemNumber);
    if (!d || r.date < d) first.set(r.itemNumber, r.date);
  }
  const exceptions: FoundException[] = [];
  const out = reader.map((r) => {
    const d = first.get(r.itemNumber);
    if (r.status !== 'confirmed' || r.question !== 'Final passage' || r.outcome !== 'passed' || !d || r.date === d) return r;
    const detail = `${r.itemNumber} already passed on ${d}; a later "adopt" is not a second Final passage`;
    exceptions.push({ cause: 'outcome_conflict', subject: subjectOf(r), detail: { detail, url: r.documentUrl } });
    return { ...r, status: 'failed' as const, cause: 'outcome_conflict' as const, detail };
  });
  return { reader: out, exceptions };
}

// ---- comparison --------------------------------------------------------------------------------------------------

export interface ItemRow { subject: string; status: 'agree' | 'differs' | 'inventory only' | 'no members to compare'; detail?: string }
export interface MemberRow { subject: string; member: string; inventory: string; reader: string; status: 'agree' | 'differs' }
export interface Comparison {
  items: ItemRow[];
  members: MemberRow[];
  readerOnly: ReaderRollCall[];
  skipped: { id: string; reason: string }[];
  exceptions: FoundException[];
}

const lastToken = (s: string) => normaliseName(s).split(' ').pop() ?? '';

/** The politician an inventory surname means on a date: via the inventory roster, then the names file. */
export function idForSurname(surname: string, date: string, roster: InventoryRoster, names: NameFile): string | { error: string } {
  const sn = normaliseName(surname);
  const inTerm = (r: InventoryRoster['members'][number]) => r.from <= date && (r.to === null || date <= r.to);
  // The last word of the roster name must equal the surname: a bare "Smith" never means "Piedmont-Smith".
  const hits = roster.members.filter((r) => lastToken(r.name) === sn && inTerm(r));
  const people = [...new Set(hits.map((h) => h.name))];
  if (people.length !== 1) return { error: `"${surname}" matches ${people.length} roster members on ${date}` };
  const full = normaliseName(people[0]);
  const member = names.members.find((m) => m.politicianId !== null && m.variants.some((v) => normaliseName(v) === full));
  return member ? (member.politicianId as string) : { error: `"${people[0]}" has no politician id in the names file` };
}

/**
 * Inventory rows filed under the bare item id that are not votes on the item: record type OTHER (a first reading, a
 * withdrawal, "not introduced"), and procedural motions whose notes say so ("Motion to postpone; not a vote on the
 * item", "Procedural motion to introduce …"). They would otherwise be compared as the item's Final passage.
 */
const PROCEDURAL_NOTE = /\bnot a vote on the\b|\bno vote on the item\b|^(?:FAILED\.\s*)?(?:Procedural motion|Motion to (?:postpone|introduce|continue|send|table|refer)\b)/i;
export function notAVote(inv: InventoryItem): string | null {
  if (inv.record_type === 'OTHER') return 'not a vote on the item (inventory record type OTHER)';
  if (PROCEDURAL_NOTE.test(inv.notes ?? '')) return 'not a vote on the item (the inventory notes a procedural motion)';
  return null;
}

const sideOf = (position: string): string =>
  position === 'yea' ? 'yes' : position === 'nay' ? 'no' : position === 'present' ? 'abstain' : 'absent';

export function compareWithInventory(
  reader: ReaderRollCall[], inventory: InventoryItem[], roster: InventoryRoster, names: NameFile,
): Comparison {
  const out: Comparison = { items: [], members: [], readerOnly: [], skipped: [], exceptions: [] };
  const confirmed = new Map(reader.filter((r) => r.status === 'confirmed').map((r) => [keyOf(r), r]));
  const matched = new Set<string>();

  for (const inv of inventory) {
    const p = parseInventoryId(inv.id);
    if ('skip' in p) { out.skipped.push({ id: inv.id, reason: p.skip }); continue; }
    if (inv.instrument === 'motion') { out.skipped.push({ id: inv.id, reason: 'procedural motion' }); continue; }
    const notVote = notAVote(inv);
    if (notVote) { out.skipped.push({ id: inv.id, reason: notVote }); continue; }
    if (p.date < WINDOW_START) continue;
    const subject = subjectOf(p);
    const rc = confirmed.get(keyOf(p));
    if (!rc) {
      out.items.push({ subject, status: 'inventory only', detail: 'the reader has no confirmed roll call for this item' });
      out.exceptions.push({ cause: 'inventory_disagrees', subject, detail: { kind: 'inventory only', inventoryId: inv.id } });
      continue;
    }
    matched.add(keyOf(p));
    const byId = new Map((rc.votes ?? []).map((v) => [v.politicianId, sideOf(v.position)]));
    const problems: string[] = [];
    const seen = new Set<string>();
    for (const m of inv.members ?? []) {
      const id = idForSurname(m.name, p.date, roster, names);
      if (typeof id !== 'string') {
        out.members.push({ subject, member: m.name, inventory: m.vote, reader: '?', status: 'differs' });
        problems.push(id.error);
        continue;
      }
      seen.add(id);
      const theirs = byId.get(id) ?? 'none';
      const ok = theirs === m.vote;
      out.members.push({ subject, member: m.name, inventory: m.vote, reader: theirs, status: ok ? 'agree' : 'differs' });
      if (!ok) problems.push(`${m.name}: inventory ${m.vote}, reader ${theirs}`);
    }
    // A member the reader names and the inventory does not: only a recorded position counts.
    for (const [id, side] of byId) if (!seen.has(id) && side !== 'absent') problems.push(`${id}: reader ${side}, not in the inventory`);
    if (!inv.members?.length) {
      out.items.push({ subject, status: 'no members to compare', detail: `the reader found ${byId.size} member position(s)` });
    } else if (problems.length) {
      out.items.push({ subject, status: 'differs', detail: problems.join('; ') });
      out.exceptions.push({ cause: 'inventory_disagrees', subject, detail: { kind: 'differs', inventoryId: inv.id, problems } });
    } else {
      out.items.push({ subject, status: 'agree' });
    }
  }
  out.readerOnly = reader.filter((r) => r.status === 'confirmed' && !matched.has(keyOf(r)));
  return out;
}

// ---- spot check --------------------------------------------------------------------------------------------------

/** mulberry32: a small seeded generator. The same seed always gives the same stream. */
function prng(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Up to `n` of the given roll calls, chosen by the seed. Input order does not matter. */
export function drawSpotCheck(pool: ReaderRollCall[], seed: number, n = SPOT_COUNT): ReaderRollCall[] {
  const sorted = [...pool].sort((a, b) => (keyOf(a) < keyOf(b) ? -1 : keyOf(a) > keyOf(b) ? 1 : 0));
  const rand = prng(seed);
  for (let i = 0; i < Math.min(n, sorted.length); i++) {
    const j = i + Math.floor(rand() * (sorted.length - i));
    [sorted[i], sorted[j]] = [sorted[j], sorted[i]];
  }
  return sorted.slice(0, Math.min(n, sorted.length)).sort((a, b) => (keyOf(a) < keyOf(b) ? -1 : 1));
}

interface SpotCheckFile {
  seed: number;
  picks: { id: string; date: string; itemNumber: string; question: string; outcome: string; tally: PrintedTally;
    votes: { name: string; position: string }[]; /** Hash of what was checked: outcome, tally and every member's position. */ votesHash: string; quote: string; documentUrl: string; verdict: string }[];
}

const votesHash = (r: ReaderRollCall): string =>
  sha256Hex(new TextEncoder().encode(JSON.stringify([
    r.outcome, r.tally, (r.votes ?? []).map((v) => [v.politicianId, v.position]).sort(),
  ])));

const pickOf = (city: string, r: ReaderRollCall, verdict = ''): SpotCheckFile['picks'][number] => ({
  id: externalVoteId(city, r.date, r.itemNumber, r.question), date: r.date, itemNumber: r.itemNumber,
  question: r.question, outcome: r.outcome, tally: r.tally,
  votes: (r.votes ?? []).map((v) => ({ name: v.nameAsPrinted, position: v.position })),
  votesHash: votesHash(r), quote: r.sentence, documentUrl: r.documentUrl, verdict,
});

// ---- download cache ------------------------------------------------------------------------------------------------

/**
 * Wrap the two download functions with a folder cache keyed by the URL's hash: a URL already saved is read from disk,
 * so a re-run downloads nothing it has. A failed download is not saved.
 */
export function withDownloadCache<D extends Pick<FirstLoadDeps, 'fetchJson' | 'fetchBytes'>>(deps: D, dir: string): D {
  mkdirSync(dir, { recursive: true });
  const file = (url: string, ext: string) => path.join(dir, `${sha256Hex(new TextEncoder().encode(url))}.${ext}`);
  const index = path.join(dir, 'index.tsv');
  const note = (url: string, f: string) => appendFileSync(index, `${path.basename(f)}\t${url}\n`);
  return {
    ...deps,
    fetchBytes: async (url: string) => {
      const f = file(url, 'bin');
      if (existsSync(f)) return new Uint8Array(readFileSync(f));
      const bytes = await deps.fetchBytes(url);
      writeFileSync(f, bytes);
      note(url, f);
      return bytes;
    },
    fetchJson: async (url: string) => {
      const f = file(url, 'json');
      if (existsSync(f)) return JSON.parse(readFileSync(f, 'utf8'));
      const json = await deps.fetchJson(url);
      writeFileSync(f, JSON.stringify(json));
      note(url, f);
      return json;
    },
  };
}

// ---- reading the city --------------------------------------------------------------------------------------------

export interface FirstLoadDeps {
  fetchJson: RefreshDeps['fetchJson'];
  fetchBytes: RefreshDeps['fetchBytes'];
  pdfText: RefreshDeps['pdfText'];
  loadCities: RefreshDeps['loadCities'];
  loadNames: RefreshDeps['loadNames'];
  /** Used by --apply only. */
  connect?: () => Promise<Connection>;
  storage?: StorageLike;
}

interface Read {
  items: FeedItem[];
  /** Every vote document the feed lists (not only the ones read). */
  feedDocs: VoteDocument[];
  reader: ReaderRollCall[];
  documents: { doc: VoteDocument; bytes: Uint8Array }[];
  exceptions: FoundException[];
  warnings: string[];
  /** Sponsor sentences from the feed and every document read, each carrying the URL it can be opened at. */
  sponsorFindings: SponsorFinding[];
  /** Sentences that could not be tied to an item or a date. */
  sponsorProblems: FoundException[];
  /** The raw legislation feed of each year, saved by --apply as the source of feed-read sponsors. */
  feeds: { year: number; url: string; bytes: Uint8Array }[];
}

/** Council terms from the inventory roster, keyed to the names file's politician ids (no database in a dry run). */
export function termsFromRoster(roster: InventoryRoster, names: NameFile): { terms: TermSpan[]; unmatched: string[] } {
  const terms: TermSpan[] = [];
  const unmatched: string[] = [];
  for (const r of roster.members) {
    const full = normaliseName(r.name);
    const m = names.members.find((x) => x.variants.some((v) => normaliseName(v) === full));
    if (!m?.politicianId) { unmatched.push(r.name); continue; }
    terms.push({ politicianId: m.politicianId, start: r.from, end: r.to });
  }
  return { terms, unmatched };
}

async function readCity(city: CityConfig, names: NameFile, roster: InventoryRoster, now: Date, deps: FirstLoadDeps): Promise<Read> {
  const years = Array.from({ length: now.getUTCFullYear() - 2020 + 1 }, (_, i) => 2020 + i);
  const feed = await readFeeds(city, now, deps, years);
  // A Final before the window would sit pending forever: its minutes are not read.
  const items = feed.items.filter((i) => !i.final || i.final.date >= WINDOW_START);
  const today = now.toISOString().slice(0, 10);
  const docs = governingDocuments(feed.docs.filter((d) => d.meetingDate >= WINDOW_START && d.meetingDate <= today))
    .sort((a, b) => (a.meetingDate < b.meetingDate ? -1 : 1));
  const { terms, unmatched } = termsFromRoster(roster, names);
  const read: Read = { items, feedDocs: feed.docs, reader: [], documents: [], exceptions: [], warnings: [], sponsorFindings: [], sponsorProblems: [], feeds: feed.feeds };
  if (unmatched.length) read.warnings.push(`No politician id for roster members: ${[...new Set(unmatched)].join(', ')}.`);

  for (let di = 0; di < docs.length; di++) {
    const doc = docs[di];
    const d = doc.meetingDate;
    let parse: MinutesParse;
    let bytes: Uint8Array;
    let text: string;
    try {
      bytes = await deps.fetchBytes(doc.url);
      text = await deps.pdfText(bytes);
      parse = parseMinutes(text, d);
    } catch (e) {
      read.exceptions.push({ cause: 'unparsed_roll_call', subject: `${d} document ${doc.fileId}`, detail: { url: doc.url, error: (e as Error).message } });
      continue;
    }
    // Minutes with no text, or that print another meeting's date, are not read for this meeting; its Memorandum is
    // read instead.
    const problem = documentProblem(text, d);
    if (problem) {
      read.exceptions.push({ cause: 'unparsed_roll_call', subject: `${d} document ${doc.fileId}`, detail: { ...problem, url: doc.url } });
      const fb = fallbackDocument(doc, feed.docs);
      if (fb) {
        docs.splice(di, 1, fb);
        di--;
      }
      continue;
    }
    read.documents.push({ doc, bytes });
    const docSponsors = documentSponsorFindings(text, parse.rollCalls, doc, d, null);
    read.sponsorFindings.push(...docSponsors.findings);
    read.sponsorProblems.push(...docSponsors.problems);
    for (const s of parse.unparsed) read.exceptions.push({ cause: 'unparsed_roll_call', subject: `${d} ${s.slice(0, 60)}`, detail: { sentence: s } });
    const ctx = buildContext(names, terms, items, d);
    for (const rc of parse.rollCalls) {
      const res = checkRollCall(rc, parse, ctx);
      const row = {
        index: rc.index, date: d, itemNumber: rc.itemNumber, question: rc.question, outcome: rc.outcome, tally: rc.tally,
        sentence: rc.sentence, documentUrl: doc.url,
      };
      if (res.ok) read.reader.push({ ...row, status: 'confirmed', votes: res.votes, feedDisagreement: res.feedDisagreement });
      else {
        read.reader.push({ ...row, status: 'failed', cause: res.cause, detail: res.detail });
        read.exceptions.push({ cause: res.cause, subject: subjectOf(row), detail: { detail: res.detail, url: doc.url } });
      }
    }
  }
  const fromFeed = feedSponsorFindings(items, feed.itemYear, new Map(), new Map(feed.feeds.map((f) => [f.year, f.url])));
  read.sponsorFindings.push(...fromFeed.findings);
  read.sponsorProblems.push(...fromFeed.problems);
  const dup = flagDuplicates(read.reader);
  read.reader = dup.reader;
  // A duplicate's own check exceptions stay; the duplicate exception is added once per key.
  read.exceptions.push(...dup.exceptions);
  const again = flagRepeatedFinals(read.reader);
  read.reader = again.reader;
  read.exceptions.push(...again.exceptions);
  return read;
}

// ---- sponsorships --------------------------------------------------------------------------------------------------

/** Older documents and some feed years print "Ord 21-03" (the cached 2021 feed has "21-09"); newer ones print "Ord 2021-03". Both sides are brought to the four-digit form to compare. */
export const normaliseItemNumber = (s: string): string =>
  s.replace(/^(Ord|Res|App Ord) (\d{2})-(\d+)$/, (_m, t: string, y: string, n: string) => `${t} 20${y}-${n}`);
const normaliseSubject = (subject: string): string => {
  const [item, ...rest] = subject.split(' / ');
  return [normaliseItemNumber(item), ...rest].join(' / ');
};

/** One inventory row that names sponsors: its id, date and the surnames the hand reading recorded. */
export interface InventorySponsorRow { id: string; date: string; sponsors: string[] }

/**
 * The subject(s) an inventory row's id means, in the record's own form (`<item>` or `<item> / <label>`), or why it has
 * none. A row about a nested amendment, a paragraph, a withdrawal or a written commitment has no matching subject.
 */
export function inventorySponsorSubjects(id: string): { subjects: string[] } | { unmappable: string } {
  const m = /^place:\d+:(\d{4}-\d{2}-\d{2}):([^()]*?)(?: \((.*)\))?$/.exec(id);
  if (!m) return { unmappable: 'id not understood' };
  const [, , item, suffix] = m;
  if (suffix === undefined) return { subjects: [item] };
  const am = /^amendment (\d+)$/i.exec(suffix);
  if (am) return { subjects: [`${item} / Amendment ${twoDigits(am[1])}`] };
  const rc = /^reasonable condition (\d+)$/i.exec(suffix);
  if (rc) return { subjects: [`${item} / Reasonable Condition ${Number(rc[1])}`] };
  const many = /^reasonable conditions ([\d, and]+)$/i.exec(suffix);
  if (many) return { subjects: (many[1].match(/\d+/g) ?? []).map((n) => `${item} / Reasonable Condition ${Number(n)}`) };
  return { unmappable: `"${suffix}" is not an amendment or reasonable condition of its own` };
}

export interface SponsorDiff {
  group: 'missed' | 'different' | 'extra';
  subject: string;
  inventoryId: string | null;
  /** Surnames as the inventory records them. */
  inventory: string[];
  /** Names as printed in the source; null = not read. */
  reader: string[] | null;
  /** The reader's exception cause for this subject, when one was raised. */
  cause?: string;
  note?: string;
  /** The reader holds the subject under another item-number form than the inventory. */
  formDiffers?: boolean;
}
export interface SponsorComparison {
  rows: number;
  agree: number;
  /** Agreed only after the item numbers were brought to one form. */
  agreeAfterNormalising: number;
  diffs: SponsorDiff[];
  skippedBeforeWindow: number;
}

/** The inventory's sponsor rows against what the reader resolved. Roles are not compared: the inventory records names only. */
export function compareSponsors(
  sponsorships: Sponsorship[], problems: FoundException[], rows: InventorySponsorRow[], roster: InventoryRoster, names: NameFile,
): SponsorComparison {
  const reader = new Map<string, { raw: Set<string>; ids: Set<string>; printed: string[] }>();
  for (const sp of sponsorships) {
    const raw = sponsorSubject(sp.itemNumber, sp.label);
    const key = normaliseSubject(raw);
    const e = reader.get(key) ?? { raw: new Set<string>(), ids: new Set<string>(), printed: [] };
    e.raw.add(raw);
    e.ids.add(sp.politicianId);
    if (!e.printed.includes(sp.nameAsPrinted)) e.printed.push(sp.nameAsPrinted);
    reader.set(key, e);
  }
  const problemCauses = new Map<string, Set<string>>();
  for (const p of problems) {
    const key = normaliseSubject(p.subject);
    problemCauses.set(key, (problemCauses.get(key) ?? new Set()).add(p.cause));
  }
  /** Items whose document sentence had no provable item: tied to the meeting date and label only. */
  const noItem = (date: string, subject: string): string[] => {
    const label = subject.includes(' / ') ? subject.slice(subject.indexOf(' / ')) : null;
    if (!label) return [];
    return problems.filter((p) => p.subject.startsWith(`${date} document `) && p.subject.endsWith(label)).map((p) => p.cause);
  };
  const out: SponsorComparison = { rows: 0, agree: 0, agreeAfterNormalising: 0, diffs: [], skippedBeforeWindow: 0 };
  const seen = new Set<string>();
  for (const row of rows) {
    if (row.date < WINDOW_START) { out.skippedBeforeWindow++; continue; }
    out.rows++;
    const mapped = inventorySponsorSubjects(row.id);
    if ('unmappable' in mapped) {
      out.diffs.push({ group: 'missed', subject: row.id.replace(/^place:\d+:/, ''), inventoryId: row.id, inventory: row.sponsors, reader: null, note: `no matching subject form: ${mapped.unmappable}` });
      continue;
    }
    const ids: string[] = [];
    const unresolved: string[] = [];
    for (const sn of row.sponsors) {
      const id = idForSurname(sn, row.date, roster, names);
      if (typeof id === 'string') ids.push(id); else unresolved.push(`${sn} (${id.error})`);
    }
    for (const subject of mapped.subjects) {
      const key = normaliseSubject(subject);
      seen.add(key);
      const got = reader.get(key);
      const cause = [...(problemCauses.get(key) ?? []), ...(got ? [] : noItem(row.date, subject).map((c) => `${c} (a document sentence for this label on ${row.date} had no provable item)`))].join(', ') || undefined;
      if (!got) {
        out.diffs.push({ group: 'missed', subject, inventoryId: row.id, inventory: row.sponsors, reader: null, cause, ...(unresolved.length ? { note: `inventory name not resolved: ${unresolved.join('; ')}` } : {}) });
        continue;
      }
      const same = !unresolved.length && ids.length === got.ids.size && ids.every((i) => got.ids.has(i)) && new Set(ids).size === ids.length;
      if (same) {
        out.agree++;
        if (!got.raw.has(subject)) out.agreeAfterNormalising++;
      } else {
        out.diffs.push({
          group: 'different', subject, inventoryId: row.id, inventory: row.sponsors, reader: got.printed, cause,
          ...(unresolved.length ? { note: `inventory name not resolved: ${unresolved.join('; ')}` } : {}),
          ...(!got.raw.has(subject) ? { formDiffers: true } : {}),
        });
      }
    }
  }
  for (const [key, got] of reader) {
    if (seen.has(key)) continue;
    out.diffs.push({ group: 'extra', subject: [...got.raw][0], inventoryId: null, inventory: [], reader: got.printed });
  }
  return out;
}

const sponsorDiffException = (d: SponsorDiff): FoundException => ({
  cause: 'inventory_disagrees', subject: d.subject,
  detail: { kind: `sponsors ${d.group === 'missed' ? 'missed by reader' : 'different members'}`, inventoryId: d.inventoryId, inventory: d.inventory, reader: d.reader, cause: d.cause ?? null, note: d.note ?? null },
});

/** Inventory differences that stop --apply: missed and different. A row only the reader has is listed, not blocking. */
export function sponsorBlockers(cmp: SponsorComparison): FoundException[] {
  return cmp.diffs.filter((d) => d.group !== 'extra').map(sponsorDiffException);
}

/**
 * The owner's sponsor checks (`about: 'sponsors'` in owner-checks.json) let a difference through: it stays an open
 * exception marked `ownerHeld`, as a held vote check does. They never write a sponsorship.
 */
export function applySponsorOwnerChecks(excs: FoundException[], checks: CheckedOwnerCheck[]): { exceptions: FoundException[]; passed: number } {
  const byId = new Map(checks.filter((c) => c.about === 'sponsors').map((c) => [c.inventoryId, c]));
  let passed = 0;
  const exceptions = excs.map((e) => {
    const d = e.detail as { inventoryId?: string | null };
    const c = d.inventoryId ? byId.get(d.inventoryId) : undefined;
    if (!c) return e;
    passed++;
    return {
      ...e,
      detail: {
        ...(e.detail as object), ownerHeld: true, ownerAnswer: c.ownerAnswer, ownerNote: c.ownerNote || null,
        reason: `let through by the owner's sponsor check (answer "${c.ownerAnswer}")${c.ownerNote ? `: ${c.ownerNote}` : ''}`,
      },
    };
  });
  return { exceptions, passed };
}

export interface SponsorRowOut {
  subject: string; itemNumber: string; label: string | null; politicianId: string; role: string; nameAsPrinted: string;
  sentence: string; sourceKind: string; documentUrl: string;
}
const sponsorRowOut = (sp: Sponsorship): SponsorRowOut => ({
  subject: sponsorSubject(sp.itemNumber, sp.label), itemNumber: sp.itemNumber, label: sp.label, politicianId: sp.politicianId, role: sp.role,
  nameAsPrinted: sp.nameAsPrinted, sentence: sp.sentence, sourceKind: sp.sourceKind, documentUrl: sp.sourceUrl ?? '',
});
const sponsorKey = (r: { subject: string; politicianId: string; role: string }) => `${r.subject}|${r.politicianId}|${r.role}`;
export const sortedSponsorRows = (sps: Sponsorship[]): SponsorRowOut[] =>
  sps.map(sponsorRowOut).sort((a, b) => (sponsorKey(a) < sponsorKey(b) ? -1 : sponsorKey(a) > sponsorKey(b) ? 1 : 0));
/** A fingerprint of every resolved row, so --apply writes the rows that were reviewed in the dry run. */
export const sponsorHash = (sps: Sponsorship[]): string =>
  sha256Hex(new TextEncoder().encode(JSON.stringify(sortedSponsorRows(sps))));

export interface SponsorSpotCheckFile {
  seed: number;
  picks: { subject: string; member: string; role: string; sentence: string; documentUrl: string; verdict: string }[];
}

/** Up to `n` resolved rows, chosen by the seed. Input order does not matter. */
export function drawSponsorSpotCheck(pool: SponsorRowOut[], seed: number, n = SPONSOR_SPOT_COUNT): SponsorRowOut[] {
  const sorted = [...pool].sort((a, b) => (sponsorKey(a) < sponsorKey(b) ? -1 : sponsorKey(a) > sponsorKey(b) ? 1 : 0));
  const rand = prng(seed);
  const take = Math.min(n, sorted.length);
  for (let i = 0; i < take; i++) {
    const j = i + Math.floor(rand() * (sorted.length - i));
    [sorted[i], sorted[j]] = [sorted[j], sorted[i]];
  }
  return sorted.slice(0, take).sort((a, b) => (sponsorKey(a) < sponsorKey(b) ? -1 : 1));
}

const sponsorPick = (r: SponsorRowOut, verdict = ''): SponsorSpotCheckFile['picks'][number] => ({
  subject: r.subject, member: r.nameAsPrinted, role: r.role, sentence: r.sentence, documentUrl: r.documentUrl, verdict,
});
const sponsorPickKey = (p: SponsorSpotCheckFile['picks'][number]) => `${p.subject}|${p.member}|${p.role}|${p.sentence}|${p.documentUrl}`;

/** Everything about sponsors that stops --apply, besides the open inventory differences (BLOCKING_CAUSES covers those). */
function sponsorGateBlockers(
  prior: SponsorSpotCheckFile | null, fresh: SponsorSpotCheckFile, savedHash: string | null, hash: string,
): string[] {
  const out: string[] = [];
  if (!prior) return ['sponsor-spotcheck.json is missing: run a dry run and have the sponsor picks checked first.'];
  if (savedHash === null) out.push('sponsorships.json is missing: run a dry run and review the sponsorships first.');
  else if (savedHash !== hash) out.push('sponsorships.json changed since the dry run (the resolved sponsors are not the ones reviewed): run a dry run again.');
  const draw = (f: SponsorSpotCheckFile) => f.picks.map(sponsorPickKey).join('\n');
  if (prior.seed !== fresh.seed || draw(prior) !== draw(fresh)) out.push('sponsor-spotcheck.json does not match a fresh draw from its seed: run a dry run again.');
  const blank = prior.picks.filter((p) => !(p.verdict ?? '').trim()).length;
  if (blank) out.push(`${blank} sponsor spot-check verdict(s) are blank.`);
  const bad = prior.picks.filter((p) => (p.verdict ?? '').trim() && (p.verdict ?? '').trim() !== 'match').length;
  if (bad) out.push(`sponsor spot check: ${bad} verdict(s) are not "match".`);
  return out;
}

function sponsorCompareMd(cmp: SponsorComparison, passed: number): string {
  const line = (d: SponsorDiff) =>
    `- ${d.subject}${d.inventoryId ? ` [${d.inventoryId}]` : ''}: inventory ${d.inventory.length ? d.inventory.join(', ') : '(none)'}; reader ${d.reader ? d.reader.join(', ') : 'not read'}`
    + `${d.cause ? `; reader exception: ${d.cause}` : ''}${d.note ? `; ${d.note}` : ''}${d.formDiffers ? '; item-number form differs' : ''}`;
  const group = (g: SponsorDiff['group'], title: string, why: string) => {
    const xs = cmp.diffs.filter((d) => d.group === g);
    return [`## ${title} (${xs.length})`, '', why, '', ...(xs.length ? xs.map(line) : ['- none']), ''];
  };
  return [
    '# Sponsors: reader compared with the inventory', '',
    `Inventory rows with sponsors (full.json, on or after ${WINDOW_START}): ${cmp.rows}. Agree: ${cmp.agree}. Agree only after item numbers were brought to one form ("21-03" and "2021-03"): ${cmp.agreeAfterNormalising}. `
    + `Differences that block --apply: ${cmp.diffs.filter((d) => d.group !== 'extra').length}.`,
    ...(passed ? ['', `Owner sponsor checks that let a difference through: ${passed}.`] : []),
    '',
    'The inventory records surnames only, so people are compared, not roles.', '',
    ...group('missed', 'Missed by the reader', 'The inventory names sponsors; the reader produced none for this subject. Blocks --apply.'),
    ...group('different', 'Different members', 'The reader resolved sponsors for this subject, but not the same people. Blocks --apply.'),
    ...group('extra', 'Read but not in the inventory', 'The reader resolved sponsors the inventory has no row for. Listed for the owner; does not block.'),
  ].join('\n');
}

// ---- the run ------------------------------------------------------------------------------------------------------

export interface FirstLoadOptions {
  city: string; inventory: string; out: string; apply: boolean; seed?: number; sponsorSeed?: number; now?: Date;
}
export interface FirstLoadResult {
  refused?: string[];
  summaryPath?: string;
  applied?: { rollCallsConfirmed: number; votesWritten: number; sponsorshipsWritten: number; exceptions: number; stagedItems: number; stagedMinutes: number };
}

const readJson = (p: string) => JSON.parse(readFileSync(p, 'utf8'));
const countBy = (xs: FoundException[]) => {
  const c: Record<string, number> = {};
  for (const x of xs) c[x.cause] = (c[x.cause] ?? 0) + 1;
  return c;
};

interface SponsorSummary {
  rows: number; subjects: number; held: Record<string, number>; differences: number; agreeAfterNormalising: number;
  spotDrawn: number; spotFilled: number; seed: number;
}

function summaryMd(
  read: Read, cmp: Comparison, spot: SpotCheckFile, all: FoundException[], pending: number, owner: OwnerResult | null = null, sp: SponsorSummary | null = null,
): string {
  const conf = read.reader.filter((r) => r.status === 'confirmed');
  const votes = conf.reduce((n, r) => n + (r.votes?.length ?? 0), 0);
  const by = countBy(all);
  const lines = [
    '# First load summary', '',
    `- Roll calls that would go live: ${conf.length} (${votes} member votes)`,
    `- Pending outcomes (a feed Final with no confirmed roll call): ${pending}`,
    `- Roll calls that failed a check: ${read.reader.length - conf.length}`,
    `- Spot checks drawn: ${spot.picks.length} (seed ${spot.seed}); filled in: ${spot.picks.filter((p) => p.verdict).length}`,
    `- Inventory rows: no members to compare ${cmp.items.filter((i) => i.status === 'no members to compare').length}, agree ${cmp.items.filter((i) => i.status === 'agree').length}, differs ${cmp.items.filter((i) => i.status === 'differs').length}, inventory only ${cmp.items.filter((i) => i.status === 'inventory only').length}, reader only ${cmp.readerOnly.length}, skipped ${cmp.skipped.length}`,
    ...(owner ? [
      `- Owner-checked: ${owner.ownerChecked.length} confirmed, ${owner.held.length} held, ${owner.notNeeded.length} not needed`,
      `- Owner checks that failed the tally, name or outcome check (still blocking): ${owner.failed.length}`,
    ] : []),
    ...(sp ? [
      `- Sponsorships: ${sp.rows} would be written (${sp.subjects} subjects), ${Object.values(sp.held).reduce((a, b) => a + b, 0)} held (${Object.keys(sp.held).length ? Object.entries(sp.held).sort().map(([c, n]) => `${c} ${n}`).join(', ') : 'none'}), ${sp.differences} inventory differences (${sp.agreeAfterNormalising} agree only after item numbers were normalised)`,
      `- Sponsor spot checks drawn: ${sp.spotDrawn} (seed ${sp.seed}); filled in: ${sp.spotFilled}`,
    ] : []),
    '', '## Exceptions by cause', '',
    ...(Object.keys(by).length ? Object.entries(by).sort().map(([c, n]) => `- ${c}: ${n}`) : ['- none']),
    ...(read.warnings.length ? ['', '## Warnings', '', ...read.warnings.map((w) => `- ${w}`)] : []),
    '', 'Nothing was written to the database or storage.', '',
  ];
  return lines.join('\n');
}

function compareMd(cmp: Comparison, applied: InventoryCorrection[] = [], owner: OwnerResult | null = null, ownerSkipped: string[] = []): string {
  const bad = cmp.items.filter((i) => i.status !== 'agree');
  return [
    '# Reader compared with the inventory', '',
    ...(applied.length
      ? [
        `## Corrections applied from corrections.json (${applied.length})`, '',
        ...applied.map((c) => `- ${c.row}: ${describeCorrection(c)}. Evidence: ${c.evidence.url} "${c.evidence.quote}" (added ${c.added})`),
        '',
      ]
      : []),
    `Items: ${cmp.items.length} compared. Members: ${cmp.members.filter((m) => m.status === 'agree').length} agree, ${cmp.members.filter((m) => m.status === 'differs').length} differ.`, '',
    `No members to compare (inventory item lists no member votes): ${cmp.items.filter((i) => i.status === 'no members to compare').length}`, '',
    '## Differs / inventory only / no members to compare', '',
    ...(bad.length ? bad.map((i) => `- ${i.subject}: ${i.status}${i.detail ? ` (${i.detail})` : ''}`) : ['- none']),
    '', '## Reader only (no inventory row)', '',
    ...(cmp.readerOnly.length ? cmp.readerOnly.map((r) => `- ${subjectOf(r)}`) : ['- none']),
    '', '## Skipped inventory items', '',
    ...(cmp.skipped.length ? cmp.skipped.map((s) => `- ${s.id}: ${s.reason}`) : ['- none']), '',
    ...(owner ? [
      `## Owner-checked (${owner.ownerChecked.length}): confirmed by the owner against the city's documents, written with source owner-check`, '',
      ...(owner.ownerChecked.length ? owner.ownerChecked.map((o) => `- ${subjectOf(o)}: ${o.tally.yes}-${o.tally.no}-${o.tally.abstain}, ${o.outcome}, ${o.documentUrl}`) : ['- none']),
      '', `## Owner checks held (${owner.held.length}): stay open, do not block --apply`, '',
      ...(owner.held.length ? owner.held.map((h) => `- ${h.subject}: ${h.reason}`) : ['- none']),
      '', `## Owner checks that failed the tally, name or outcome check (${owner.failed.length}): still blocking`, '',
      ...(owner.failed.length ? owner.failed.map((h) => `- ${h.subject}: ${h.reason}`) : ['- none']),
      '', `## Owner check not needed (${owner.notNeeded.length}): the reader governs`, '',
      ...(owner.notNeeded.length ? owner.notNeeded.map((id) => `- ${id}`) : ['- none']),
      '', `## Owner-checked rows whose first document is not a vote document in the feed (${ownerSkipped.length}): --apply cannot save it`, '',
      ...(ownerSkipped.length ? ownerSkipped.map((x) => `- ${x}`) : ['- none']), '',
    ] : []),
  ].join('\n');
}

/** A held owner check: still an open exception, but it does not stop --apply. */
const isOwnerHeld = (f: FoundException): boolean =>
  f.cause === 'inventory_disagrees' && (f.detail as { ownerHeld?: unknown } | null)?.ownerHeld === true;

/** Everything that stops --apply. Empty means clear. */
function blockers(spot: SpotCheckFile | null, fresh: SpotCheckFile, found: FoundException[]): string[] {
  const out: string[] = [];
  if (!spot) return ['spotcheck.json is missing: run a dry run and have the 30 picks checked first.'];
  const draw = (f: SpotCheckFile) => f.picks.map((p) => p.id).join(',');
  if (spot.seed !== fresh.seed || draw(spot) !== draw(fresh)) {
    out.push('spotcheck.json does not match a fresh draw from its seed (the reader output changed): run a dry run again.');
  }
  const changed = spot.picks.filter((p) => fresh.picks.find((f) => f.id === p.id)?.votesHash !== p.votesHash).length;
  if (changed) out.push(`${changed} picked vote(s) changed since they were checked (votes changed): run a dry run again and re-check them.`);
  const blank = spot.picks.filter((p) => !(p.verdict ?? '').trim()).length;
  if (blank) out.push(`${blank} spot-check verdict(s) are blank.`);
  const bad = spot.picks.filter((p) => (p.verdict ?? '').trim() && (p.verdict ?? '').trim() !== 'match').length;
  if (bad) out.push(`spot_check_failed: ${bad} verdict(s) are not "match".`);
  for (const c of BLOCKING_CAUSES) {
    const n = found.filter((f) => f.cause === c && !isOwnerHeld(f)).length;
    if (n && c !== 'spot_check_failed') out.push(`${n} open exception(s) of cause ${c}.`);
  }
  return out;
}

export async function runFirstLoad(opts: FirstLoadOptions, deps: FirstLoadDeps): Promise<FirstLoadResult> {
  const now = opts.now ?? new Date();
  const city = deps.loadCities().find((c) => c.scope === opts.city);
  if (!city) throw new Error(`City ${opts.city} is not in cities.json`);
  const names = deps.loadNames(city);
  if (opts.apply) {
    const nulls = names.members.filter((m) => m.politicianId === null).length;
    if (nulls) return { refused: [`names.json still has ${nulls} member(s) with a null politicianId: apply the migrations and fill the ids first.`] };
  }

  const inv = [path.join(opts.inventory, 'deep.json'), path.join(opts.inventory, 'full.json')];
  const frozen: InventoryItem[] = inv.flatMap((f) => readJson(f).items as InventoryItem[]);
  const correctionsPath = path.join(opts.inventory, 'corrections.json');
  const { inventory, applied } = existsSync(correctionsPath)
    ? applyCorrections(frozen, readJson(correctionsPath) as CorrectionsFile)
    : { inventory: frozen, applied: [] as InventoryCorrection[] };
  const roster: InventoryRoster = readJson(path.join(opts.inventory, 'roster.json'));
  const ownerPath = path.join(opts.inventory, 'owner-checks.json');
  const ownerChecks = existsSync(ownerPath) ? validateOwnerChecks(inventory, readJson(ownerPath) as OwnerChecksFile) : null;
  const spotPath = path.join(opts.out, 'spotcheck.json');
  const prior: SpotCheckFile | null = existsSync(spotPath) ? readJson(spotPath) : null;
  if (opts.apply && !prior) return { refused: ['spotcheck.json is missing: run a dry run and have the 30 picks checked first.'] };
  const sponsorSpotPath = path.join(opts.out, 'sponsor-spotcheck.json');
  const sponsorsPath = path.join(opts.out, 'sponsorships.json');
  const priorSponsorSpot: SponsorSpotCheckFile | null = existsSync(sponsorSpotPath) ? readJson(sponsorSpotPath) : null;
  if (opts.apply && !priorSponsorSpot) return { refused: ['sponsor-spotcheck.json is missing: run a dry run and have the sponsor picks checked first.'] };
  // The inventory's sponsors are the control: full.json items with a non-empty sponsors list.
  const sponsorRows: InventorySponsorRow[] = (readJson(path.join(opts.inventory, 'full.json')).items as (InventoryItem & { sponsors?: string[] })[])
    .filter((i) => Array.isArray(i.sponsors) && i.sponsors.length > 0)
    .map((i) => ({ id: i.id, date: i.date, sponsors: i.sponsors as string[] }));

  const read = await readCity(city, names, roster, now, deps);
  const cmp = compareWithInventory(read.reader, inventory, roster, names);
  const seed = opts.apply ? (prior as SpotCheckFile).seed : opts.seed ?? prior?.seed ?? Math.floor(Math.random() * 2 ** 31);
  const fresh: SpotCheckFile = { seed, picks: drawSpotCheck(cmp.readerOnly, seed).map((r) => pickOf(city.scope, r)) };
  // A verdict stays only while the pick's votes are what was checked.
  const keep = new Map((prior?.seed === seed ? prior.picks : []).map((p) => [p.id, p]));
  const spot: SpotCheckFile = {
    seed,
    picks: fresh.picks.map((p) => ({ ...p, verdict: keep.get(p.id)?.votesHash === p.votesHash ? keep.get(p.id)?.verdict ?? '' : '' })),
  };
  const failedChecks: FoundException[] = spot.picks
    .filter((p) => (p.verdict ?? '').trim() && (p.verdict ?? '').trim() !== 'match')
    .map((p) => ({ cause: 'spot_check_failed', subject: `${p.date} ${p.itemNumber} ${p.question}`, detail: { verdict: p.verdict } }));
  const owner = ownerChecks ? applyOwnerChecks(cmp, ownerChecks, roster, names, read.items, inventory, read.reader) : null;
  // An owner-checked row is saved with a vote document: it must be one the feed lists.
  const feedUrls = new Set(read.feedDocs.map((d) => d.url));
  const ownerSkipped = (owner?.ownerChecked ?? []).filter((o) => !feedUrls.has(o.documentUrl)).map((o) => `${subjectOf(o)}: ${o.documentUrl}`);
  // Sponsors: resolve, compare with the inventory, draw the spot check.
  const { terms: sponsorTerms } = termsFromRoster(roster, names);
  const resolvedSponsors = resolveSponsorships(read.sponsorFindings, names, sponsorTerms);
  const sponsorProblems: FoundException[] = [
    ...read.sponsorProblems,
    ...resolvedSponsors.problems.map((p) => ({ cause: p.cause as ExceptionCause, subject: p.subject, detail: p.detail })),
  ];
  const sponsorCmp = compareSponsors(resolvedSponsors.sponsorships, sponsorProblems, sponsorRows, roster, names);
  const sponsorOwner = applySponsorOwnerChecks(sponsorBlockers(sponsorCmp), ownerChecks ?? []);
  const sponsorRowsOut = sortedSponsorRows(resolvedSponsors.sponsorships);
  const sponsorHashNow = sponsorHash(resolvedSponsors.sponsorships);
  const sponsorSeed = opts.apply ? (priorSponsorSpot as SponsorSpotCheckFile).seed : opts.sponsorSeed ?? priorSponsorSpot?.seed ?? Math.floor(Math.random() * 2 ** 31);
  const freshSponsorSpot: SponsorSpotCheckFile = { seed: sponsorSeed, picks: drawSponsorSpotCheck(sponsorRowsOut, sponsorSeed).map((r) => sponsorPick(r)) };
  const keepSponsor = new Map((priorSponsorSpot?.seed === sponsorSeed ? priorSponsorSpot.picks : []).map((p) => [sponsorPickKey(p), p.verdict]));
  const sponsorSpot: SponsorSpotCheckFile = { seed: sponsorSeed, picks: freshSponsorSpot.picks.map((p) => ({ ...p, verdict: keepSponsor.get(sponsorPickKey(p)) ?? '' })) };
  const sponsorHeld: Record<string, number> = {};
  for (const e of sponsorProblems) sponsorHeld[e.cause] = (sponsorHeld[e.cause] ?? 0) + 1;
  const sponsorSummary: SponsorSummary = {
    rows: sponsorRowsOut.length, subjects: new Set(sponsorRowsOut.map((r) => r.subject)).size, held: sponsorHeld,
    differences: sponsorCmp.diffs.filter((d) => d.group !== 'extra').length, agreeAfterNormalising: sponsorCmp.agreeAfterNormalising,
    spotDrawn: sponsorSpot.picks.length, spotFilled: sponsorSpot.picks.filter((p) => p.verdict).length, seed: sponsorSeed,
  };
  const all = [
    ...read.exceptions, ...(owner ? owner.exceptions : cmp.exceptions), ...failedChecks, ...sponsorProblems, ...sponsorOwner.exceptions,
  ];
  const confirmedKeys = new Set(read.reader.filter((r) => r.status === 'confirmed' && r.question === 'Final passage').map((r) => `${r.date}|${r.itemNumber}`));
  const pending = read.items.filter((i) => i.final && !confirmedKeys.has(`${i.final.date}|${i.itemNumber}`)).length;

  if (!opts.apply) {
    mkdirSync(opts.out, { recursive: true });
    writeFileSync(path.join(opts.out, 'reader-output.json'), JSON.stringify({ city: city.scope, from: WINDOW_START, rollCalls: read.reader }, null, 1));
    writeFileSync(path.join(opts.out, 'compare.md'), compareMd(cmp, applied, owner, ownerSkipped));
    if (owner) {
      writeFileSync(path.join(opts.out, 'owner-checked.json'), JSON.stringify({ city: city.scope, from: WINDOW_START, hash: ownerHash(owner.ownerChecked), ownerChecked: owner.ownerChecked }, null, 1));
    }
    writeFileSync(spotPath, JSON.stringify(spot, null, 1));
    writeFileSync(sponsorsPath, JSON.stringify({ city: city.scope, from: WINDOW_START, hash: sponsorHashNow, sponsorships: sponsorRowsOut }, null, 1));
    writeFileSync(path.join(opts.out, 'sponsor-compare.md'), sponsorCompareMd(sponsorCmp, sponsorOwner.passed));
    writeFileSync(sponsorSpotPath, JSON.stringify(sponsorSpot, null, 1));
    writeFileSync(path.join(opts.out, 'exceptions.json'), JSON.stringify({
      city: city.scope, from: WINDOW_START,
      exceptions: all.map((e) => ({ cause: e.cause, subject: e.subject, detail: e.detail })),
    }, null, 1));
    const summaryPath = path.join(opts.out, 'summary.md');
    writeFileSync(summaryPath, summaryMd(read, cmp, spot, all, pending, owner, sponsorSummary));
    return { summaryPath };
  }

  const refused = blockers(prior, fresh, all);
  refused.push(...sponsorGateBlockers(
    priorSponsorSpot, freshSponsorSpot,
    existsSync(sponsorsPath) ? ((readJson(sponsorsPath) as { hash?: string }).hash ?? null) : null, sponsorHashNow,
  ));
  if (owner) {
    const ocPath = path.join(opts.out, 'owner-checked.json');
    if (!existsSync(ocPath)) refused.push('owner-checked.json is missing: run a dry run again and review the owner-checked rows.');
    else if ((readJson(ocPath) as { hash?: string }).hash !== ownerHash(owner.ownerChecked)) {
      refused.push('owner-checked rows changed since the dry run: run a dry run again.');
    }
  }
  if (refused.length) return { refused };
  if (!deps.connect || !deps.storage) throw new Error('--apply needs a database connection and storage');
  const subjectsRead = new Set(read.sponsorFindings.map((f) => sponsorSubject(f.itemNumber, f.label)));
  for (const p of sponsorProblems) subjectsRead.delete(p.subject);
  return {
    applied: await applyAll(
      opts, city, read, owner?.ownerChecked ?? [], all, deps.connect, deps.storage, deps.fetchBytes, now,
      { sponsorships: resolvedSponsors.sponsorships, problems: sponsorProblems, subjectsRead },
    ),
  };
}

// ---- --apply ------------------------------------------------------------------------------------------------------

/** Saved texts from the inventory's store-staging folder: items/*.txt and minutes/<date>.txt. */
function stagedFiles(opts: FirstLoadOptions): { kind: 'item_text' | 'minutes'; url: string; bytes: Uint8Array }[] {
  const root = path.join(opts.inventory, 'store-staging');
  const items: InventoryItem[] = ['deep.json', 'full.json'].flatMap((f) => readJson(path.join(opts.inventory, f)).items);
  const out: { kind: 'item_text' | 'minutes'; url: string; bytes: Uint8Array }[] = [];
  const dir = (d: string) => (existsSync(path.join(root, d)) ? readdirSync(path.join(root, d)).filter((f) => f.endsWith('.txt')) : []);
  for (const f of dir('items')) {
    const it = items.find((i) => i.text_store_path === `items/${f}`);
    if (it?.url_item) out.push({ kind: 'item_text', url: it.url_item, bytes: readFileSync(path.join(root, 'items', f)) });
  }
  for (const f of dir('minutes')) {
    const date = f.replace(/\.txt$/, '');
    const it = items.find((i) => i.date === date && i.url_minutes);
    // Its own chain: the same URL plus a fragment, so the text never supersedes the PDF saved from that URL.
    if (it?.url_minutes) out.push({ kind: 'minutes', url: `${it.url_minutes}#inventory-text`, bytes: readFileSync(path.join(root, 'minutes', f)) });
  }
  return out;
}

/** The part of a parsed roll call that writeConfirmed reads. */
const rollCallOf = (r: ReaderRollCall): MinutesRollCall => ({
  index: r.index, itemNumber: r.itemNumber, question: r.question, tally: r.tally, named: [], inlineNotes: [],
  outcome: r.outcome, sentence: r.sentence,
});

async function applyAll(
  opts: FirstLoadOptions, city: CityConfig, read: Read, ownerChecked: OwnerCheckedRollCall[], found: FoundException[],
  connect: () => Promise<Connection>, storage: StorageLike, fetchBytesFn: FirstLoadDeps['fetchBytes'], now: Date,
  sponsors: { sponsorships: Sponsorship[]; problems: FoundException[]; subjectsRead: Set<string> },
): Promise<NonNullable<FirstLoadResult['applied']>> {
  const runId = `local-record-first-load-${now.toISOString()}`;
  const staged = stagedFiles(opts);
  const db = await connect();
  const done = { rollCallsConfirmed: 0, votesWritten: 0, sponsorshipsWritten: 0, exceptions: 0, stagedItems: 0, stagedMinutes: 0 };
  try {
    await db.query('BEGIN');
    // Saved texts have their own URL chain (see stagedFiles), so order does not matter.
    for (const s of staged) {
      await saveDocument(db, storage, { city: city.scope, kind: s.kind, url: s.url, cityFileId: null, bytes: s.bytes, contentType: 'text/plain' });
      if (s.kind === 'item_text') done.stagedItems++; else done.stagedMinutes++;
    }
    await writeFeed(db, city.scope, read.items);
    const docId = new Map<string, string>();
    for (const { doc, bytes } of read.documents) {
      const saved = await saveDocument(db, storage, { city: city.scope, kind: doc.kind, url: doc.url, cityFileId: String(doc.fileId), bytes });
      docId.set(doc.url, saved.id);
    }
    // Each feed year's raw JSON is the saved source of a feed-read sponsor.
    for (const f of read.feeds) {
      const saved = await saveDocument(db, storage, { city: city.scope, kind: 'legislation_feed', url: f.url, cityFileId: null, bytes: f.bytes });
      docId.set(f.url, saved.id);
    }
    const billFor = async (itemNumber: string) => {
      const item = read.items.find((i) => i.itemNumber === itemNumber);
      const bill = item
        ? await db.query(`SELECT id FROM essentials.legislative_bills WHERE external_id = $1 AND jurisdiction = $2`, [`onboard-${item.feedId}`, city.scope])
        : { rows: [] as any[] };
      return bill.rows.length ? (bill.rows[0].id as string) : null;
    };
    for (const r of read.reader.filter((x) => x.status === 'confirmed')) {
      const billId = await billFor(r.itemNumber);
      if (!billId) { found.push({ cause: 'unknown_item', subject: subjectOf(r), detail: { detail: `${r.itemNumber} has no bill row` } }); continue; }
      await writeConfirmed(
        db, city.scope, rollCallOf(r), { ok: true, votes: r.votes as ResolvedVote[], feedDisagreement: r.feedDisagreement ?? null },
        billId, r.date, docId.get(r.documentUrl) as string,
      );
      done.rollCallsConfirmed++;
      done.votesWritten += r.votes?.length ?? 0;
    }
    // Owner-checked roll calls go after the reader's. Their document may be one the reader skipped: save it first.
    for (const o of ownerChecked) {
      const billId = await billFor(o.itemNumber);
      if (!billId) { found.push({ cause: 'unknown_item', subject: subjectOf(o), detail: { detail: `${o.itemNumber} has no bill row`, inventoryId: o.inventoryId } }); continue; }
      let voteDoc = docId.get(o.documentUrl);
      if (!voteDoc) {
        const listed = read.feedDocs.find((d) => d.url === o.documentUrl);
        if (!listed) { found.push({ cause: 'unknown_item', subject: subjectOf(o), detail: { detail: `${o.documentUrl} is not a vote document in the feed`, inventoryId: o.inventoryId } }); continue; }
        const saved = await saveDocument(db, storage, { city: city.scope, kind: listed.kind, url: listed.url, cityFileId: String(listed.fileId), bytes: await fetchBytesFn(listed.url) });
        voteDoc = saved.id;
        docId.set(o.documentUrl, voteDoc);
      }
      await writeConfirmed(
        db, city.scope,
        { index: 0, itemNumber: o.itemNumber, question: o.question, tally: o.tally, named: [], inlineNotes: [], outcome: o.outcome, sentence: o.sentence },
        { ok: true, votes: o.votes, feedDisagreement: null }, billId, o.date, voteDoc, 'owner-check',
      );
      done.rollCallsConfirmed++;
      done.votesWritten += o.votes.length;
    }
    // Sponsorships go after the votes, tied to the saved document each sentence was read from.
    const withDocs = sponsors.sponsorships.map((sp) => ({ ...sp, sourceDocumentId: sp.sourceUrl ? docId.get(sp.sourceUrl) ?? null : null }));
    done.sponsorshipsWritten = (await writeSponsorships(db, city.scope, runId, withDocs, { subjectsRead: sponsors.subjectsRead })).written;
    for (const e of found) { await recordException(db, city.scope, runId, e.cause, e.subject, e.detail); done.exceptions++; }
    await db.query('COMMIT');
  } catch (e) {
    await db.query('ROLLBACK').catch(() => undefined);
    throw e;
  } finally {
    db.release();
  }
  return done;
}


// ---- command line ------------------------------------------------------------------------------------------------

async function productionDeps(apply: boolean): Promise<FirstLoadDeps> {
  const data = (p: string) => new URL(`../../data/local-record/${p}`, import.meta.url);
  const deps: FirstLoadDeps = {
    fetchJson, fetchBytes, pdfText: minutesTextFromPdf,
    loadCities: () => parseCityConfigs(JSON.parse(readFileSync(data('cities.json'), 'utf8'))),
    loadNames: (c) => JSON.parse(readFileSync(data(`${c.slug}/names.json`), 'utf8')),
  };
  if (!apply) return deps; // a dry run never imports the database or storage modules
  const { pool } = await import('../../src/lib/db.js');
  const { supabaseAdmin } = await import('../../src/lib/supabase.js');
  return {
    ...deps,
    connect: async () => {
      const c = await pool.connect();
      return { query: c.query.bind(c) as Connection['query'], release: () => c.release() };
    },
    storage: makeStorage(supabaseAdmin),
  };
}

async function main(): Promise<void> {
  const { values } = parseArgs({
    options: {
      city: { type: 'string' }, inventory: { type: 'string' }, out: { type: 'string' },
      seed: { type: 'string' }, 'sponsor-seed': { type: 'string' }, cache: { type: 'string' }, apply: { type: 'boolean', default: false },
    },
  });
  if (!values.city || !values.inventory || !values.out) throw new Error('Needs --city, --inventory <abs dir> and --out <abs dir>');
  for (const p of [values.inventory, values.out, ...(values.cache ? [values.cache] : [])]) {
    if (!path.isAbsolute(p)) throw new Error(`${p} must be an absolute path`);
  }
  const deps = await productionDeps(!!values.apply);
  const result = await runFirstLoad(
    { city: values.city, inventory: values.inventory, out: values.out, apply: !!values.apply, seed: values.seed ? Number(values.seed) : undefined,
      sponsorSeed: values['sponsor-seed'] ? Number(values['sponsor-seed']) : undefined },
    values.cache ? withDownloadCache(deps, values.cache) : deps,
  );
  if (result.refused) {
    console.error(`Refused:\n${result.refused.map((r) => `- ${r}`).join('\n')}`);
    process.exitCode = 1;
  } else if (result.applied) {
    console.info(`Applied: ${JSON.stringify(result.applied)}`);
  } else {
    console.info(`Dry run done. Nothing was written to the database or storage. See ${result.summaryPath}`);
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().then(() => process.exit()).catch((e) => { console.error(e); process.exit(1); });
}
