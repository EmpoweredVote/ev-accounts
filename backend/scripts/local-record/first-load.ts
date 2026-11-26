/**
 * first-load.ts — read every vote document of a city since 2020-12-01, compare with the hand-built inventory, draw
 * spot checks, and (only with --apply) write to the database and storage.
 *
 *   npm run local-record:first-load --prefix backend -- --city place:1805860 --inventory <abs dir> --out <abs dir> [--seed N] [--apply]
 *
 * A dry run reads the city's public site and writes four files to --out. It never opens a database or storage call.
 * Exceptions found in a dry run live in the --out files only; --apply is the one path that writes anything.
 */
import 'dotenv/config';
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';
import { checkRollCall } from '../../src/lib/localRecord/checks.js';
import { normaliseName, type NameFile, type TermSpan } from '../../src/lib/localRecord/names.js';
import { parseMinutes, minutesTextFromPdf } from '../../src/lib/localRecord/onboard/minutes.js';
import { fetchJson, type VoteDocument } from '../../src/lib/localRecord/onboard/feed.js';
import {
  buildContext, fetchBytes, governingDocuments, makeStorage, readFeeds, type CityConfig, type Connection,
  type RefreshDeps,
} from '../../src/lib/localRecord/refresh.js';
import { externalVoteId, saveDocument, type StorageLike } from '../../src/lib/localRecord/store.js';
import { recordException, writeConfirmed, writeFeed } from '../../src/lib/localRecord/write.js';
import type { ExceptionCause, FeedItem, MinutesParse, MinutesRollCall, PrintedTally, ResolvedVote } from '../../src/lib/localRecord/types.js';

export const WINDOW_START = '2020-12-01';
const SPOT_COUNT = 30;
/** Causes that stop --apply. */
export const BLOCKING_CAUSES: ExceptionCause[] = ['inventory_disagrees', 'control_failed', 'spot_check_failed'];

// ---- inventory -------------------------------------------------------------------------------------------------

export interface InventoryItem {
  id: string;
  date: string;
  item_no: string;
  instrument?: string;
  members?: { name: string; vote: string }[];
  url_item?: string;
  url_minutes?: string;
  text_store_path?: string;
}
export interface InventoryRoster { members: { name: string; from: string; to: string | null }[] }

/**
 * `place:1805860:<date>:<item_no>[ (<suffix>)]` -> the minutes' own key, or why the item is not compared.
 * No suffix = Final passage; `amendment N` = `Amendment 0N`; `veto override` = `Veto override`.
 */
export function parseInventoryId(id: string): { date: string; itemNumber: string; question: string } | { skip: string } {
  const m = /^place:\d+:(\d{4}-\d{2}-\d{2}):([^()]*?)(?: \((.*)\))?$/.exec(id);
  if (!m) return { skip: 'id not understood' };
  const [, date, itemNumber, suffix] = m;
  if (!/^(Ord|Res|App Ord) /.test(itemNumber)) return { skip: 'not a numbered ordinance or resolution' };
  if (suffix === undefined) return { date, itemNumber, question: 'Final passage' };
  if (/^motion\b/i.test(suffix)) return { skip: 'procedural motion' };
  const am = /^amendment (\d+)$/i.exec(suffix);
  if (am) return { date, itemNumber, question: `Amendment ${am[1].padStart(2, '0')}` };
  if (suffix.toLowerCase() === 'veto override') return { date, itemNumber, question: 'Veto override' };
  return { skip: `suffix "${suffix}" has no roll call in the minutes` };
}

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

// ---- comparison --------------------------------------------------------------------------------------------------

export interface ItemRow { subject: string; status: 'agree' | 'differs' | 'inventory only'; detail?: string }
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
function idForSurname(surname: string, date: string, roster: InventoryRoster, names: NameFile): string | { error: string } {
  const sn = normaliseName(surname);
  const inTerm = (r: InventoryRoster['members'][number]) => r.from <= date && (r.to === null || date <= r.to);
  let hits = roster.members.filter((r) => lastToken(r.name) === sn && inTerm(r));
  if (!hits.length) hits = roster.members.filter((r) => new RegExp(`(^|[\\s-])${sn}$`).test(normaliseName(r.name)) && inTerm(r));
  const people = [...new Set(hits.map((h) => h.name))];
  if (people.length !== 1) return { error: `"${surname}" matches ${people.length} roster members on ${date}` };
  const full = normaliseName(people[0]);
  const member = names.members.find((m) => m.politicianId !== null && m.variants.some((v) => normaliseName(v) === full));
  return member ? (member.politicianId as string) : { error: `"${people[0]}" has no politician id in the names file` };
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
    for (const [id, side] of byId) if (!seen.has(id) && inv.members?.length) problems.push(`${id}: reader ${side}, not in the inventory`);
    if (problems.length) {
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
    votes: { name: string; position: string }[]; quote: string; documentUrl: string; verdict: string }[];
}

const pickOf = (city: string, r: ReaderRollCall, verdict = ''): SpotCheckFile['picks'][number] => ({
  id: externalVoteId(city, r.date, r.itemNumber, r.question), date: r.date, itemNumber: r.itemNumber,
  question: r.question, outcome: r.outcome, tally: r.tally,
  votes: (r.votes ?? []).map((v) => ({ name: v.nameAsPrinted, position: v.position })),
  quote: r.sentence, documentUrl: r.documentUrl, verdict,
});

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
  reader: ReaderRollCall[];
  documents: { doc: VoteDocument; bytes: Uint8Array }[];
  exceptions: FoundException[];
  warnings: string[];
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
  const read: Read = { items, reader: [], documents: [], exceptions: [], warnings: [] };
  if (unmatched.length) read.warnings.push(`No politician id for roster members: ${[...new Set(unmatched)].join(', ')}.`);

  for (const doc of docs) {
    const d = doc.meetingDate;
    let parse: MinutesParse;
    let bytes: Uint8Array;
    try {
      bytes = await deps.fetchBytes(doc.url);
      parse = parseMinutes(await deps.pdfText(bytes), d);
    } catch (e) {
      read.exceptions.push({ cause: 'unparsed_roll_call', subject: `${d} document ${doc.fileId}`, detail: { url: doc.url, error: (e as Error).message } });
      continue;
    }
    read.documents.push({ doc, bytes });
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
  return read;
}

// ---- the run ------------------------------------------------------------------------------------------------------

export interface FirstLoadOptions {
  city: string; inventory: string; out: string; apply: boolean; seed?: number; now?: Date;
}
export interface FirstLoadResult {
  refused?: string[];
  summaryPath?: string;
  applied?: { rollCallsConfirmed: number; votesWritten: number; exceptions: number; stagedItems: number; stagedMinutes: number };
}

const readJson = (p: string) => JSON.parse(readFileSync(p, 'utf8'));
const countBy = (xs: FoundException[]) => {
  const c: Record<string, number> = {};
  for (const x of xs) c[x.cause] = (c[x.cause] ?? 0) + 1;
  return c;
};

function summaryMd(read: Read, cmp: Comparison, spot: SpotCheckFile, all: FoundException[], pending: number): string {
  const conf = read.reader.filter((r) => r.status === 'confirmed');
  const votes = conf.reduce((n, r) => n + (r.votes?.length ?? 0), 0);
  const by = countBy(all);
  const lines = [
    '# First load summary', '',
    `- Roll calls that would go live: ${conf.length} (${votes} member votes)`,
    `- Pending outcomes (a feed Final with no confirmed roll call): ${pending}`,
    `- Roll calls that failed a check: ${read.reader.length - conf.length}`,
    `- Spot checks drawn: ${spot.picks.length} (seed ${spot.seed}); filled in: ${spot.picks.filter((p) => p.verdict).length}`,
    `- Inventory rows: agree ${cmp.items.filter((i) => i.status === 'agree').length}, differs ${cmp.items.filter((i) => i.status === 'differs').length}, inventory only ${cmp.items.filter((i) => i.status === 'inventory only').length}, reader only ${cmp.readerOnly.length}, skipped ${cmp.skipped.length}`,
    '', '## Exceptions by cause', '',
    ...(Object.keys(by).length ? Object.entries(by).sort().map(([c, n]) => `- ${c}: ${n}`) : ['- none']),
    ...(read.warnings.length ? ['', '## Warnings', '', ...read.warnings.map((w) => `- ${w}`)] : []),
    '', 'Nothing was written to the database or storage.', '',
  ];
  return lines.join('\n');
}

function compareMd(cmp: Comparison): string {
  const bad = cmp.items.filter((i) => i.status !== 'agree');
  return [
    '# Reader compared with the inventory', '',
    `Items: ${cmp.items.length} compared. Members: ${cmp.members.filter((m) => m.status === 'agree').length} agree, ${cmp.members.filter((m) => m.status === 'differs').length} differ.`, '',
    '## Differs / inventory only', '',
    ...(bad.length ? bad.map((i) => `- ${i.subject}: ${i.status}${i.detail ? ` (${i.detail})` : ''}`) : ['- none']),
    '', '## Reader only (no inventory row)', '',
    ...(cmp.readerOnly.length ? cmp.readerOnly.map((r) => `- ${subjectOf(r)}`) : ['- none']),
    '', '## Skipped inventory items', '',
    ...(cmp.skipped.length ? cmp.skipped.map((s) => `- ${s.id}: ${s.reason}`) : ['- none']), '',
  ].join('\n');
}

/** Everything that stops --apply. Empty means clear. */
function blockers(spot: SpotCheckFile | null, fresh: SpotCheckFile, found: FoundException[]): string[] {
  const out: string[] = [];
  if (!spot) return ['spotcheck.json is missing: run a dry run and have the 30 picks checked first.'];
  const draw = (f: SpotCheckFile) => f.picks.map((p) => p.id).join(',');
  if (spot.seed !== fresh.seed || draw(spot) !== draw(fresh)) {
    out.push('spotcheck.json does not match a fresh draw from its seed (the reader output changed): run a dry run again.');
  }
  const blank = spot.picks.filter((p) => !p.verdict.trim()).length;
  if (blank) out.push(`${blank} spot-check verdict(s) are blank.`);
  const bad = spot.picks.filter((p) => p.verdict.trim() && p.verdict.trim() !== 'match').length;
  if (bad) out.push(`spot_check_failed: ${bad} verdict(s) are not "match".`);
  for (const c of BLOCKING_CAUSES) {
    const n = found.filter((f) => f.cause === c).length;
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
  const inventory: InventoryItem[] = inv.flatMap((f) => readJson(f).items as InventoryItem[]);
  const roster: InventoryRoster = readJson(path.join(opts.inventory, 'roster.json'));
  const spotPath = path.join(opts.out, 'spotcheck.json');
  const prior: SpotCheckFile | null = existsSync(spotPath) ? readJson(spotPath) : null;
  if (opts.apply && !prior) return { refused: ['spotcheck.json is missing: run a dry run and have the 30 picks checked first.'] };

  const read = await readCity(city, names, roster, now, deps);
  const cmp = compareWithInventory(read.reader, inventory, roster, names);
  const seed = opts.apply ? (prior as SpotCheckFile).seed : opts.seed ?? prior?.seed ?? Math.floor(Math.random() * 2 ** 31);
  const fresh: SpotCheckFile = { seed, picks: drawSpotCheck(cmp.readerOnly, seed).map((r) => pickOf(city.scope, r)) };
  const keep = new Map((prior?.seed === seed ? prior.picks : []).map((p) => [p.id, p.verdict]));
  const spot: SpotCheckFile = { seed, picks: fresh.picks.map((p) => ({ ...p, verdict: keep.get(p.id) ?? '' })) };
  const failedChecks: FoundException[] = spot.picks
    .filter((p) => p.verdict.trim() && p.verdict.trim() !== 'match')
    .map((p) => ({ cause: 'spot_check_failed', subject: `${p.date} ${p.itemNumber} ${p.question}`, detail: { verdict: p.verdict } }));
  const all = [...read.exceptions, ...cmp.exceptions, ...failedChecks];
  const confirmedKeys = new Set(read.reader.filter((r) => r.status === 'confirmed' && r.question === 'Final passage').map((r) => `${r.date}|${r.itemNumber}`));
  const pending = read.items.filter((i) => i.final && !confirmedKeys.has(`${i.final.date}|${i.itemNumber}`)).length;

  if (!opts.apply) {
    mkdirSync(opts.out, { recursive: true });
    writeFileSync(path.join(opts.out, 'reader-output.json'), JSON.stringify({ city: city.scope, from: WINDOW_START, rollCalls: read.reader }, null, 1));
    writeFileSync(path.join(opts.out, 'compare.md'), compareMd(cmp));
    writeFileSync(spotPath, JSON.stringify(spot, null, 1));
    const summaryPath = path.join(opts.out, 'summary.md');
    writeFileSync(summaryPath, summaryMd(read, cmp, spot, all, pending));
    return { summaryPath };
  }

  const refused = blockers(prior, fresh, all);
  if (refused.length) return { refused };
  if (!deps.connect || !deps.storage) throw new Error('--apply needs a database connection and storage');
  return { applied: await applyAll(opts, city, read, all, deps.connect, deps.storage, now) };
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
    if (it?.url_minutes) out.push({ kind: 'minutes', url: it.url_minutes, bytes: readFileSync(path.join(root, 'minutes', f)) });
  }
  return out;
}

/** The part of a parsed roll call that writeConfirmed reads. */
const rollCallOf = (r: ReaderRollCall): MinutesRollCall => ({
  index: r.index, itemNumber: r.itemNumber, question: r.question, tally: r.tally, named: [], inlineNotes: [],
  outcome: r.outcome, sentence: r.sentence,
});

async function applyAll(
  opts: FirstLoadOptions, city: CityConfig, read: Read, found: FoundException[],
  connect: () => Promise<Connection>, storage: StorageLike, now: Date,
): Promise<NonNullable<FirstLoadResult['applied']>> {
  const runId = `local-record-first-load-${now.toISOString()}`;
  const staged = stagedFiles(opts);
  const db = await connect();
  const done = { rollCallsConfirmed: 0, votesWritten: 0, exceptions: 0, stagedItems: 0, stagedMinutes: 0 };
  try {
    await db.query('BEGIN');
    // Saved texts first: a text can share a URL with a vote document, and the real PDF saved after it stays current.
    for (const s of staged) {
      await saveDocument(db, storage, { city: city.scope, kind: s.kind, url: s.url, cityFileId: null, bytes: s.bytes });
      if (s.kind === 'item_text') done.stagedItems++; else done.stagedMinutes++;
    }
    await writeFeed(db, city.scope, read.items);
    const docId = new Map<string, string>();
    for (const { doc, bytes } of read.documents) {
      const saved = await saveDocument(db, storage, { city: city.scope, kind: doc.kind, url: doc.url, cityFileId: String(doc.fileId), bytes });
      docId.set(doc.url, saved.id);
    }
    for (const r of read.reader.filter((x) => x.status === 'confirmed')) {
      const item = read.items.find((i) => i.itemNumber === r.itemNumber);
      const bill = item
        ? await db.query(`SELECT id FROM essentials.legislative_bills WHERE external_id = $1 AND jurisdiction = $2`, [`onboard-${item.feedId}`, city.scope])
        : { rows: [] as any[] };
      if (!bill.rows.length) { found.push({ cause: 'unknown_item', subject: subjectOf(r), detail: { detail: `${r.itemNumber} has no bill row` } }); continue; }
      await writeConfirmed(
        db, city.scope, rollCallOf(r), { ok: true, votes: r.votes as ResolvedVote[], feedDisagreement: r.feedDisagreement ?? null },
        bill.rows[0].id, r.date, docId.get(r.documentUrl) as string,
      );
      done.rollCallsConfirmed++;
      done.votesWritten += r.votes?.length ?? 0;
    }
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
    loadCities: () => JSON.parse(readFileSync(data('cities.json'), 'utf8')),
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
      seed: { type: 'string' }, apply: { type: 'boolean', default: false },
    },
  });
  if (!values.city || !values.inventory || !values.out) throw new Error('Needs --city, --inventory <abs dir> and --out <abs dir>');
  for (const p of [values.inventory, values.out]) if (!path.isAbsolute(p)) throw new Error(`${p} must be an absolute path`);
  const result = await runFirstLoad(
    { city: values.city, inventory: values.inventory, out: values.out, apply: !!values.apply, seed: values.seed ? Number(values.seed) : undefined },
    await productionDeps(!!values.apply),
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
