// The weekly run: read a city's feeds, save and read its vote documents, confirm what passes the four checks,
// and log what does not. One database transaction per city; a dry run rolls it back.
import { readFileSync } from 'node:fs';
import { checkRollCall, type CheckContext } from './checks.js';
import type { NameFile, TermSpan } from './names.js';
import { fetchJson, fetchJsonWithBytes, listVoteDocuments, parseLegislationFeed, type VoteDocument } from './onboard/feed.js';
import { minutesTextFromPdf, parseMinutes, printedMeetingDate, stripMargin } from './onboard/minutes.js';
import { itemSponsorSentencesFromSynopsis, sponsorSentencesWithItems } from './onboard/sponsors.js';
import { resolveSponsorships, sponsorSubject, type SponsorFinding } from './sponsorships.js';
import { externalVoteId, saveDocument, sha256Hex, type Queryable, type StorageLike } from './store.js';
import { recordException, writeConfirmed, writeFeed, writeSponsorships } from './write.js';
import { EXCEPTION_CAUSES } from './types.js';
import type { CheckResult, CityScope, ExceptionCause, FeedItem, MinutesParse, ResolvedVote } from './types.js';

export interface CityConfig {
  scope: CityScope;
  slug: string;
  reader: string;
  base: string;
  /** chambers.slug of the council; its offices are read for terms. */
  chamberSlug: string;
  /** offices.normalized_position_name of the council's seats. The chamber also holds the clerk, who is no seat. */
  seatPositionName: string;
  committeeId: number;
  trust: { file: string; sha256: string; date: string };
  /** Flips to true only in the go-live PR. */
  enabled: boolean;
}

/** The cities file, checked: a city without seatPositionName would match no office (NULL), so it fails loudly. */
export function parseCityConfigs(raw: unknown): CityConfig[] {
  const list = raw as CityConfig[];
  for (const c of list) {
    if (typeof c.seatPositionName !== 'string' || c.seatPositionName === '') {
      throw new Error(`cities.json: city ${c.slug ?? c.scope} has no seatPositionName`);
    }
  }
  return list;
}

export interface RunSummary {
  runId: string;
  cities: {
    scope: string;
    pendingAdded: number;
    rollCallsConfirmed: number;
    votesWritten: number;
    sponsorshipsWritten: number;
    /** New exceptions recorded this run (one already logged with the same detail is not new). */
    exceptions: Record<ExceptionCause, number>;
  }[];
}

export interface Connection extends Queryable {
  release(): void;
}

/** Everything the run touches outside this module. Tests pass stubs; `productionDeps()` builds the real ones. */
export interface RefreshDeps {
  connect(): Promise<Connection>;
  storage: StorageLike & { download(path: string): Promise<Uint8Array> };
  fetchJson(url: string): Promise<unknown>;
  /** The legislation feed as served: parsed, and the exact bytes (saved as the source document). Optional; without it the parsed JSON is saved. */
  fetchFeed?(url: string): Promise<{ json: unknown; bytes: Uint8Array }>;
  fetchBytes(url: string): Promise<Uint8Array>;
  /** Layout text of a vote document's PDF. */
  pdfText(bytes: Uint8Array): Promise<string>;
  loadCities(): CityConfig[];
  /** The names file for a city (Task 9: backend/data/local-record/<slug>/names.json). */
  loadNames(city: CityConfig): NameFile;
  /** Council terms from office_terms, as spans. */
  loadTerms(db: Queryable, city: CityConfig): Promise<TermSpan[]>;
}

const BUCKET = 'local-record-sources';
const REFETCH_DAYS = 90;

const zeroCounts = (): Record<ExceptionCause, number> =>
  Object.fromEntries(EXCEPTION_CAUSES.map((c) => [c, 0])) as Record<ExceptionCause, number>;

const canon = (v: unknown): string =>
  JSON.stringify(v, (_k, x) =>
    x && typeof x === 'object' && !Array.isArray(x)
      ? Object.fromEntries(Object.entries(x as Record<string, unknown>).sort(([a], [b]) => (a < b ? -1 : 1)))
      : x,
  );

/** Production storage: the private bucket, uploads overwrite (paths are content-addressed). */
export function makeStorage(client: { storage: { from(bucket: string): any } }, bucket = BUCKET) {
  const b = () => client.storage.from(bucket);
  return {
    async upload(path: string, bytes: Uint8Array, contentType: string): Promise<void> {
      const { error } = await b().upload(path, bytes, { contentType, upsert: true });
      if (error) throw new Error(`Upload of ${path} failed: ${error.message ?? String(error)}`);
    },
    async download(path: string): Promise<Uint8Array> {
      const { data, error } = await b().download(path);
      if (error || !data) throw new Error(`Download of ${path} failed: ${error?.message ?? 'no data'}`);
      return new Uint8Array(await data.arrayBuffer());
    },
  };
}

const UA =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36';

export async function fetchBytes(url: string): Promise<Uint8Array> {
  const res = await fetch(url, { headers: { 'User-Agent': UA, 'Accept-Encoding': 'gzip' } });
  if (!res.ok) throw new Error(`GET ${url} failed: ${res.status}`);
  return new Uint8Array(await res.arrayBuffer());
}

/**
 * Council terms from office_terms, found by the council's chamber and its position name (the chamber also holds the City Clerk; the six district seats do not sit on the
 * place's own geo_id). Isolated here: the one query that reads who held a seat.
 */
export async function loadCouncilTerms(db: Queryable, city: CityConfig): Promise<TermSpan[]> {
  const r = await db.query(
    `SELECT ot.politician_id,
            to_char(ot.term_start, 'YYYY-MM-DD') AS start,
            to_char(ot.term_end, 'YYYY-MM-DD') AS "end"
     FROM essentials.office_terms ot
     JOIN essentials.offices o ON o.id = ot.office_id
     JOIN essentials.chambers ch ON ch.id = o.chamber_id
     WHERE ch.slug = $1 AND o.normalized_position_name = $2
       AND ot.term_start IS NOT NULL AND ot.politician_id IS NOT NULL`,
    [city.chamberSlug, city.seatPositionName],
  );
  return r.rows.map((x: any) => ({ politicianId: x.politician_id, start: x.start, end: x.end ?? null }));
}

export async function productionDeps(): Promise<RefreshDeps> {
  // Loaded here, not at the top, so importing this module (tests, the job registry) opens no connection.
  const { pool } = await import('../db.js');
  const { supabaseAdmin } = await import('../supabase.js');
  return {
    connect: async () => {
      const c = await pool.connect();
      return { query: c.query.bind(c) as Queryable['query'], release: () => c.release() };
    },
    storage: makeStorage(supabaseAdmin),
    fetchJson,
    fetchFeed: fetchJsonWithBytes,
    fetchBytes,
    pdfText: minutesTextFromPdf,
    loadCities: () =>
      parseCityConfigs(JSON.parse(readFileSync(new URL('../../../data/local-record/cities.json', import.meta.url), 'utf8'))),
    loadNames: (city) =>
      JSON.parse(readFileSync(new URL(`../../../data/local-record/${city.slug}/names.json`, import.meta.url), 'utf8')),
    loadTerms: loadCouncilTerms,
  };
}

interface StoredRollCall {
  xid: string;
  billId: string;
  state: string;
  outcome: string;
  yes: number | null;
  no: number | null;
  abstain: number | null;
  confirmedFrom: string | null;
  votes: { politicianId: string; position: string }[];
}

const STORED_SQL = `SELECT r.external_vote_id, r.bill_id, r.state, r.outcome, r.yes_count, r.no_count, r.abstain_count,
       r.confirmed_from,
       COALESCE(json_agg(json_build_object('politicianId', v.politician_id, 'position', v.position))
                FILTER (WHERE v.id IS NOT NULL), '[]'::json) AS votes
     FROM essentials.legislative_roll_calls r
     LEFT JOIN essentials.legislative_votes v ON v.roll_call_id = r.id
     WHERE r.city_scope = $1 AND `;

async function storedRollCalls(db: Queryable, where: string, params: unknown[]): Promise<Map<string, StoredRollCall>> {
  const r = await db.query(`${STORED_SQL}${where} GROUP BY r.id`, params);
  return new Map(
    r.rows.map((x: any) => [
      x.external_vote_id as string,
      {
        xid: x.external_vote_id, billId: x.bill_id, state: x.state, outcome: x.outcome, yes: x.yes_count,
        no: x.no_count, abstain: x.abstain_count, confirmedFrom: x.confirmed_from,
        votes: Array.isArray(x.votes) ? x.votes : JSON.parse(x.votes ?? '[]'),
      },
    ]),
  );
}

const fmtTally = (y: number | null, n: number | null, a: number | null) => `${y ?? '?'}-${n ?? '?'}-${a ?? '?'}`;

/** How a newly resolved roll call differs from what is stored. Empty when they match. */
function differences(
  stored: StoredRollCall,
  rc: { outcome: string; tally: { yes: number; no: number; abstain: number } },
  votes: ResolvedVote[],
): string[] {
  const out: string[] = [];
  if (stored.outcome !== rc.outcome) out.push(`outcome ${stored.outcome} -> ${rc.outcome}`);
  if (stored.yes !== rc.tally.yes || stored.no !== rc.tally.no || stored.abstain !== rc.tally.abstain) {
    out.push(`tally ${fmtTally(stored.yes, stored.no, stored.abstain)} -> ${fmtTally(rc.tally.yes, rc.tally.no, rc.tally.abstain)}`);
  }
  const before = new Map(stored.votes.map((v) => [v.politicianId, v.position]));
  const after = new Map(votes.map((v) => [v.politicianId, v.position as string]));
  for (const id of new Set([...before.keys(), ...after.keys()])) {
    if (before.get(id) !== after.get(id)) out.push(`${id}: ${before.get(id) ?? 'none'} -> ${after.get(id) ?? 'none'}`);
  }
  return out;
}

export function buildContext(names: NameFile, terms: TermSpan[], feedItems: FeedItem[], date: string): CheckContext {
  const seated = new Set(terms.filter((t) => t.start <= date && (t.end === null || date <= t.end)).map((t) => t.politicianId));
  return {
    names, terms, seatedCount: seated.size,
    feed: new Map(feedItems.map((i) => [i.itemNumber, i])),
    knownItems: new Set(feedItems.map((i) => i.itemNumber)),
  };
}

/** The session or committee a file covers, from the tag in its file name ("2021.05.05.RS.Web_Memo.pdf" -> RS). */
const sessionTag = (d: VoteDocument): string | null =>
  /(?:^|[._\s-])(RS|SS|OM|DS|COW|LUC)(?=[._\s-]|$)/i.exec(d.fileName ?? '')?.[1].toUpperCase() ?? null;
const COMMITTEE_TAGS = new Set(['COW', 'LUC']);
const isCommittee = (d: VoteDocument) => COMMITTEE_TAGS.has(sessionTag(d) ?? '');

/**
 * A meeting titled with two sessions ("Regular Session and Special Session") whose files each name one of them:
 * each session has its own vote document. File names are not trusted otherwise (they are often mislabelled).
 */
function splitsBySession(list: VoteDocument[]): boolean {
  const title = list[0]?.meetingTitle ?? '';
  return /Regular Session/i.test(title) && /Special Session/i.test(title)
    && list.every((d) => ['RS', 'SS'].includes(sessionTag(d) ?? ''));
}

const newest = (pool: VoteDocument[]) => pool.reduce((a, b) => (b.fileId > a.fileId ? b : a));

/**
 * The documents that govern a meeting: its Minutes if posted, else its Memorandum (the newest file of that kind).
 * A Committee of the Whole file never governs when the meeting has a session file. A meeting of two sessions is
 * governed per session.
 */
export function governingDocuments(docs: VoteDocument[]): VoteDocument[] {
  const byMeeting = new Map<number, VoteDocument[]>();
  for (const d of docs) byMeeting.set(d.meetingId, [...(byMeeting.get(d.meetingId) ?? []), d]);
  const out: VoteDocument[] = [];
  for (const list of byMeeting.values()) {
    const council = list.filter((d) => !isCommittee(d));
    const pool = council.length ? council : list;
    const groups = splitsBySession(pool)
      ? [...new Set(pool.map(sessionTag))].map((t) => pool.filter((d) => sessionTag(d) === t))
      : [pool];
    for (const g of groups) out.push(newest(g.some((d) => d.kind === 'minutes') ? g.filter((d) => d.kind === 'minutes') : g));
  }
  return out;
}

/**
 * What to read instead of Minutes that print another meeting's date: the newest Memorandum of the same meeting (and
 * session). Null for a Memorandum, or when the meeting has none.
 */
export function fallbackDocument(doc: VoteDocument, docs: VoteDocument[]): VoteDocument | null {
  if (doc.kind !== 'minutes') return null;
  const meeting = docs.filter((d) => d.meetingId === doc.meetingId);
  const split = splitsBySession(meeting.filter((d) => !isCommittee(d)));
  const pool = meeting.filter((d) => d.kind === 'memorandum' && !isCommittee(d) && (!split || sessionTag(d) === sessionTag(doc)));
  return pool.length ? newest(pool) : null;
}

/**
 * Why a document is not read for this meeting: it has no text (a scanned image), or it prints another meeting's
 * date. Null when it may be read.
 */
export function documentProblem(text: string, meetingDate: string): { kind: string; printedDate?: string } | null {
  if (!text.trim()) return { kind: 'the document has no text (a scanned image)' };
  const printed = printedMeetingDate(text);
  return printed && printed !== meetingDate ? { kind: 'the document prints another meeting date', printedDate: printed } : null;
}

interface CityRun {
  pendingAdded: number;
  rollCallsConfirmed: number;
  votesWritten: number;
  sponsorshipsWritten: number;
  exceptions: Record<ExceptionCause, number>;
  /** Set when the control re-parse disagreed: the city is rolled back and nothing else ran. */
  controlFailed: { subject: string; detail: unknown } | null;
}

/** A sponsor sentence that cannot be tied to an item or a date: raised as sponsor_unresolved, never written. */
export interface SponsorReadProblem { cause: 'sponsor_unresolved'; subject: string; detail: unknown }

/**
 * Sponsors named in one document's amendment and condition synopses, each tied to the item it was moved on.
 * A sentence with no provable item becomes a no_item problem. Shared by the weekly job and the first load.
 */
export function documentSponsorFindings(
  text: string, rollCalls: MinutesParse['rollCalls'], doc: Pick<VoteDocument, 'kind' | 'url' | 'fileId'>, date: string, savedId: string | null,
): { findings: SponsorFinding[]; problems: SponsorReadProblem[] } {
  const findings: SponsorFinding[] = [];
  const problems: SponsorReadProblem[] = [];
  for (const s of sponsorSentencesWithItems(stripMargin(text), rollCalls, text)) {
    if (!s.itemNumber) {
      problems.push({ cause: 'sponsor_unresolved', subject: `${date} document ${doc.fileId} / ${s.label ?? 'Council Sponsor'} ${sha256Hex(new TextEncoder().encode(s.sentence)).slice(0, 8)}`, detail: { reason: 'no_item', sentence: s.sentence, url: doc.url } });
      continue;
    }
    findings.push({ itemNumber: s.itemNumber, label: s.label, date, sourceKind: doc.kind, sourceDocumentId: savedId, sourceUrl: doc.url, found: s });
  }
  return { findings, problems };
}

/** Sponsors named in the feed's item synopses, seated on the item's first action date. A synopsis with no date is a no_date problem. */
export function feedSponsorFindings(
  items: FeedItem[], itemYear: Map<number, number>, feedDocumentId: Map<number, string>, feedUrl: Map<number, string> = new Map(),
): { findings: SponsorFinding[]; problems: SponsorReadProblem[] } {
  const findings: SponsorFinding[] = [];
  const problems: SponsorReadProblem[] = [];
  for (const it of items) {
    if (!it.synopsis) continue;
    const year = itemYear.get(it.feedId) ?? -1;
    for (const found of itemSponsorSentencesFromSynopsis(it.synopsis)) {
      if (!it.firstActionDate) {
        problems.push({ cause: 'sponsor_unresolved', subject: sponsorSubject(it.itemNumber, null), detail: { reason: 'no_date', sentence: found.sentence } });
        continue;
      }
      findings.push({
        itemNumber: it.itemNumber, label: null, date: it.firstActionDate, sourceKind: 'legislation_feed',
        sourceDocumentId: feedDocumentId.get(year) ?? null, sourceUrl: feedUrl.get(year) ?? null, found,
      });
    }
  }
  return { findings, problems };
}

/** The legislation and meetings feeds for this year and last, or for the given years (the first load reads them all). */
export async function readFeeds(
  city: CityConfig, now: Date, deps: Pick<RefreshDeps, 'fetchJson' | 'fetchFeed'>, years?: number[],
) {
  const year = now.getUTCFullYear();
  const items = new Map<number, FeedItem>();
  const docs = new Map<number, VoteDocument>();
  const feeds: { year: number; url: string; bytes: Uint8Array }[] = [];
  /** The feed year each item was read from. The year read last wins when an item is in two (by default that is last year). */
  const itemYear = new Map<number, number>();
  for (const y of years ?? [year, year - 1]) {
    const root = `${city.base}/onboard/committees/${city.committeeId}`;
    const url = `${root}/legislation?year=${y};format=json`;
    const got = deps.fetchFeed ? await deps.fetchFeed(url) : null;
    const json = got ? got.json : await deps.fetchJson(url);
    feeds.push({ year: y, url, bytes: got ? got.bytes : new TextEncoder().encode(JSON.stringify(json)) });
    for (const it of parseLegislationFeed(json, city.base)) {
      items.set(it.feedId, it);
      itemYear.set(it.feedId, y);
    }
    for (const d of listVoteDocuments(await deps.fetchJson(`${root}/meetings?year=${y};format=json`))) docs.set(d.fileId, d);
  }
  return { items: [...items.values()], docs: [...docs.values()], feeds, itemYear };
}

/** Re-parse one confirmed meeting from its saved copy and compare with the stored votes. */
async function control(
  db: Queryable, city: CityConfig, runId: string, deps: RefreshDeps, names: NameFile, terms: TermSpan[], items: FeedItem[],
): Promise<{ subject: string; detail: unknown } | null> {
  const cand = await db.query(
    `SELECT DISTINCT to_char(r.meeting_date, 'YYYY-MM-DD') AS meeting_date, d.id AS doc_id, d.storage_path
     FROM essentials.legislative_roll_calls r
     JOIN essentials.local_record_source_documents d ON d.id = r.confirmed_from
     WHERE r.city_scope = $1 AND r.state = 'confirmed'
     ORDER BY 1, 2`,
    [city.scope],
  );
  if (!cand.rows.length) return null;
  const pick = cand.rows[parseInt(sha256Hex(new TextEncoder().encode(runId)).slice(0, 8), 16) % cand.rows.length];
  const date: string = pick.meeting_date;
  const subject = `control ${date} ${pick.doc_id}`;
  const stored = await storedRollCalls(db, `r.confirmed_from = $2::uuid AND r.state = 'confirmed'`, [city.scope, pick.doc_id]);
  let parse: MinutesParse;
  try {
    parse = parseMinutes(await deps.pdfText(await deps.storage.download(pick.storage_path)), date);
  } catch (e) {
    // A saved copy that cannot be read or parsed is a failed control, not a failed run.
    return { subject, detail: { document: pick.doc_id, error: (e as Error).message } };
  }
  // Known items come from the city's bills, not the feed: the feed is read for two years only, and a confirmed
  // meeting can be older than that (the first load confirms back to 2020).
  const bills = await db.query(
    `SELECT DISTINCT number FROM essentials.legislative_bills WHERE jurisdiction = $1 AND number IS NOT NULL`,
    [city.scope],
  );
  const ctx = { ...buildContext(names, terms, items, date), knownItems: new Set<string>(bills.rows.map((b: any) => String(b.number))) };
  const problems: string[] = [];
  for (const s of stored.values()) {
    const rc = parse.rollCalls.find((r) => externalVoteId(city.scope, date, r.itemNumber, r.question) === s.xid);
    if (!rc) { problems.push(`${s.xid}: not found in the saved copy`); continue; }
    const res = checkRollCall(rc, parse, ctx);
    if (!res.ok) { problems.push(`${s.xid}: ${res.cause}: ${res.detail}`); continue; }
    for (const d of differences(s, rc, res.votes)) problems.push(`${s.xid}: ${d}`);
  }
  return problems.length ? { subject, detail: { document: pick.doc_id, problems } } : null;
}

async function runCity(
  db: Queryable, city: CityConfig, runId: string, now: Date, deps: RefreshDeps,
): Promise<CityRun> {
  const run: CityRun = {
    pendingAdded: 0, rollCallsConfirmed: 0, votesWritten: 0, sponsorshipsWritten: 0, exceptions: zeroCounts(), controlFailed: null,
  };
  /** Record an exception; count it only when it is new (not logged before with the same detail). */
  const raise = async (cause: ExceptionCause, subject: string, detail: unknown) => {
    const seen = await db.query(
      `SELECT detail FROM essentials.local_record_exceptions WHERE city_scope = $1 AND cause = $2 AND subject = $3`,
      [city.scope, cause, subject],
    );
    const known = seen.rows.length > 0 && canon(seen.rows[0].detail) === canon(detail ?? {});
    await recordException(db, city.scope, runId, cause, subject, detail);
    if (!known) run.exceptions[cause]++;
  };

  const { items, docs, feeds, itemYear } = await readFeeds(city, now, deps);
  const names = deps.loadNames(city);
  const terms = await deps.loadTerms(db, city);

  // Control first: a bad control means the reader or the names changed under us, so write nothing.
  run.controlFailed = await control(db, city, runId, deps, names, terms, items);
  if (run.controlFailed) return run;

  // Each feed year's raw JSON is kept as a source document: it is what a feed-read sponsor is proved from.
  const feedDocumentId = new Map<number, string>();
  for (const f of feeds) {
    const saved = await saveDocument(db, deps.storage, {
      city: city.scope, kind: 'legislation_feed', url: f.url, cityFileId: null,
      bytes: f.bytes,
    });
    feedDocumentId.set(f.year, saved.id);
  }
  /** Sponsor sentences read this run, from the feed and from every document read. */
  const findings: SponsorFinding[] = [];

  const count = async () =>
    Number((await db.query(
      `SELECT count(*)::int AS n FROM essentials.legislative_roll_calls WHERE city_scope = $1 AND state = 'pending_minutes'`,
      [city.scope],
    )).rows[0]?.n ?? 0);
  const before = await count();
  await writeFeed(db, city.scope, items);
  run.pendingAdded = (await count()) - before;

  const cutoff = new Date(now.getTime() - REFETCH_DAYS * 86_400_000).toISOString().slice(0, 10);
  const states = await db.query(
    `SELECT DISTINCT to_char(meeting_date, 'YYYY-MM-DD') AS d, state FROM essentials.legislative_roll_calls
     WHERE city_scope = $1 AND (state = 'pending_minutes' OR meeting_date >= $2::date)`,
    [city.scope, cutoff],
  );
  const pendingDates = new Set<string>(states.rows.filter((r: any) => r.state === 'pending_minutes').map((r: any) => r.d));
  const recentConfirmed = new Set<string>(states.rows.filter((r: any) => r.state === 'confirmed').map((r: any) => r.d));
  const known = new Set<string>(
    (await db.query(`SELECT DISTINCT source_url FROM essentials.local_record_source_documents WHERE city_scope = $1`, [city.scope]))
      .rows.map((r: any) => r.source_url),
  );

  // A replaced file stays blocked until a person resolves its file_changed exception: the new copy is current
  // after one run, so without this the next run would read and write it unreviewed.
  const blocked = (
    await db.query(
      `SELECT subject FROM essentials.local_record_exceptions WHERE city_scope = $1 AND cause = 'file_changed' AND status = 'open'`,
      [city.scope],
    )
  ).rows.map((r: any) => String(r.subject));

  const governing = governingDocuments(docs);
  const parsedByDate = new Map<string, MinutesParse[]>();
  /** Dates whose read documents were all formal Minutes (D14 recheck). */
  const minutesDates = new Map<string, string>();
  for (let gi = 0; gi < governing.length; gi++) {
    const doc = governing[gi];
    const d = doc.meetingDate;
    if (blocked.some((subj) => subj.startsWith(`${d} `))) continue;
    const isKnown = known.has(doc.url);
    // New files always; known files while the meeting still has pending votes (a fixed names file can now pass)
    // and for recent confirmed meetings (re-fetch to notice a replaced file).
    if (isKnown && !pendingDates.has(d) && !recentConfirmed.has(d)) continue;

    const bytes = await deps.fetchBytes(doc.url);
    const saved = await saveDocument(db, deps.storage, {
      city: city.scope, kind: doc.kind, url: doc.url, cityFileId: String(doc.fileId), bytes,
    });
    if (isKnown && saved.isNew) {
      await raise('file_changed', `${d} ${doc.url}`, { url: doc.url, kind: doc.kind, newSha256: saved.sha256 });
      continue;
    }
    if (isKnown && !pendingDates.has(d)) continue; // re-fetched, unchanged, nothing waiting

    let parse: MinutesParse;
    let text: string;
    try {
      text = await deps.pdfText(bytes);
      parse = parseMinutes(text, d);
    } catch (e) {
      await raise('unparsed_roll_call', `${d} document ${doc.fileId}`, { url: doc.url, error: (e as Error).message });
      continue;
    }
    // Minutes with no text, or that print another meeting's date, are not read for this date. The meeting's
    // Memorandum is read in their place.
    const problem = documentProblem(text, d);
    if (problem) {
      await raise('unparsed_roll_call', `${d} document ${doc.fileId}`, { ...problem, url: doc.url });
      const fb = fallbackDocument(doc, docs);
      if (fb) {
        governing.splice(gi, 1, fb);
        gi--;
      }
      continue;
    }
    parsedByDate.set(d, [...(parsedByDate.get(d) ?? []), parse]);
    if (doc.kind === 'minutes') minutesDates.set(d, saved.id);
    for (const s of parse.unparsed) {
      await raise('unparsed_roll_call', `${d} ${sha256Hex(new TextEncoder().encode(s)).slice(0, 12)}`, { sentence: s });
    }

    // Sponsors named in this document's amendment and condition synopses, each tied to the item it was moved on.
    const docSponsors = documentSponsorFindings(text, parse.rollCalls, doc, d, saved.id);
    for (const p of docSponsors.problems) await raise(p.cause, p.subject, p.detail);
    findings.push(...docSponsors.findings);

    const ctx = buildContext(names, terms, items, d);
    const stored = await storedRollCalls(db, `r.meeting_date = $2::date`, [city.scope, d]);
    for (const rc of parse.rollCalls) {
      const xid = externalVoteId(city.scope, d, rc.itemNumber, rc.question);
      const subject = `${d} ${rc.itemNumber} ${rc.question}`;
      const prior = stored.get(xid);
      if (prior?.state === 'confirmed' && prior.confirmedFrom === saved.id) continue;

      const res: CheckResult = checkRollCall(rc, parse, ctx);
      if (!res.ok) {
        // A failed check never replaces a confirmed vote: the stored version stays.
        await raise(res.cause, subject, { detail: res.detail, url: doc.url });
        continue;
      }
      const feedItem = items.find((i) => i.itemNumber === rc.itemNumber);
      const bill = feedItem
        ? await db.query(
            `SELECT id FROM essentials.legislative_bills WHERE external_id = $1 AND jurisdiction = $2`,
            [`onboard-${feedItem.feedId}`, city.scope],
          )
        : { rows: [] };
      if (!bill.rows.length) {
        await raise('unknown_item', subject, { detail: `${rc.itemNumber} has no bill row`, url: doc.url });
        continue;
      }
      await writeConfirmed(db, city.scope, rc, res, bill.rows[0].id, d, saved.id);
      run.rollCallsConfirmed++;
      run.votesWritten += res.votes.length;
      if (prior?.state === 'confirmed') {
        // Confirmed from another document (the Memorandum): this one governs, but say so when it differs.
        const diff = differences(prior, rc, res.votes);
        if (diff.length) {
          await raise('minutes_disagree', subject, { differences: diff, storedFrom: prior.confirmedFrom, newDocument: saved.id });
        }
      }
    }
  }

  // A feed Final the governing document does not hold. Only judged when every governing document of that date was read.
  for (const [d, parses] of parsedByDate) {
    const governingThatDate = governing.filter((g) => g.meetingDate === d).length;
    if (parses.length !== governingThatDate) continue;
    for (const it of items) {
      if (it.final?.date !== d) continue;
      const held = parses.some((p) => p.rollCalls.some((r) => r.itemNumber === it.itemNumber && r.question === 'Final passage'));
      if (!held) {
        await raise('feed_missing_final', `${d} ${it.itemNumber}`, { detail: `the feed has a Final on ${d}; the vote document has no roll call for it` });
      }
    }
  }

  // D14: once the Minutes of a date are read, a roll call on that date still confirmed from a Memorandum is one the
  // Minutes do not contain. Judged only when every governing document of the date is Minutes and all were read.
  for (const [d, parses] of parsedByDate) {
    const governingThatDate = governing.filter((g) => g.meetingDate === d);
    if (parses.length !== governingThatDate.length || !governingThatDate.every((g) => g.kind === 'minutes')) continue;
    const inMinutes = new Set(parses.flatMap((p) => p.rollCalls.map((r) => externalVoteId(city.scope, d, r.itemNumber, r.question))));
    const left = await db.query(
      `SELECT r.external_vote_id, r.question, b.number AS item_number, r.confirmed_from
       FROM essentials.legislative_roll_calls r
       JOIN essentials.legislative_bills b ON b.id = r.bill_id
       JOIN essentials.local_record_source_documents d ON d.id = r.confirmed_from
       WHERE r.city_scope = $1 AND r.meeting_date = $2::date AND r.state = 'confirmed' AND d.kind = 'memorandum'`,
      [city.scope, d],
    );
    for (const r of left.rows as any[]) {
      // One the Minutes do contain stays on the Memorandum only because its check failed; that cause is logged.
      if (inMinutes.has(r.external_vote_id)) continue;
      await raise('minutes_disagree', `${d} ${r.item_number} ${r.question}`, {
        differences: ['missing from the Minutes'], storedFrom: r.confirmed_from, newDocument: minutesDates.get(d) ?? null,
      });
    }
  }

  // A pending Final passage whose date differs from the confirmed Final passage of the same bill: the feed's Final
  // date and the vote document disagree, so the pending row is never promoted. A person must look.
  const stale = await db.query(
    `SELECT b.number, to_char(p.meeting_date, 'YYYY-MM-DD') AS pending_date,
            string_agg(DISTINCT to_char(c.meeting_date, 'YYYY-MM-DD'), ', ') AS confirmed_date
     FROM essentials.legislative_roll_calls p
     JOIN essentials.legislative_roll_calls c
       ON c.city_scope = p.city_scope AND c.bill_id = p.bill_id AND c.question = 'Final passage'
      AND c.state = 'confirmed' AND c.meeting_date <> p.meeting_date
     JOIN essentials.legislative_bills b ON b.id = p.bill_id
     WHERE p.city_scope = $1 AND p.state = 'pending_minutes' AND p.question = 'Final passage'
     GROUP BY b.number, p.meeting_date
     ORDER BY 1, 2`,
    [city.scope],
  );
  for (const r of stale.rows as any[]) {
    await raise('feed_missing_final', `${r.number} Final passage ${r.pending_date}`, {
      detail: `the feed has a Final on ${r.pending_date}; the confirmed Final passage is on ${r.confirmed_date}`,
      feedDate: r.pending_date, confirmedDate: r.confirmed_date,
    });
  }

  // Sponsors named in the feed's item synopses, seated on the item's first action date.
  const feedSponsors = feedSponsorFindings(items, itemYear, feedDocumentId);
  for (const p of feedSponsors.problems) await raise(p.cause, p.subject, p.detail);
  findings.push(...feedSponsors.findings);

  const { sponsorships, problems } = resolveSponsorships(findings, names, terms);
  for (const p of problems) await raise(p.cause, p.subject, p.detail);
  // A stored sponsor is flagged missing only for a subject read now, and not for one already raised above (its read is unknown).
  const raised = new Set(problems.map((p) => p.subject));
  const subjectsRead = new Set(findings.map((f) => sponsorSubject(f.itemNumber, f.label)).filter((x) => !raised.has(x)));
  // writeSponsorships records its own exceptions; count the ones that are new, as raise() does.
  const SPONSOR_CAUSES = ['sponsor_unresolved', 'sponsor_disagrees', 'unknown_item'];
  const openNow = async () => {
    const r = await db.query(
      `SELECT cause, subject, detail FROM essentials.local_record_exceptions WHERE city_scope = $1 AND cause = ANY($2::text[])`,
      [city.scope, SPONSOR_CAUSES],
    );
    return new Map<string, string>(
      (r.rows as any[]).map((x) => [`${x.cause}\u0000${x.subject}`, canon(x.detail)]),
    );
  };
  const beforeWrite = await openNow();
  run.sponsorshipsWritten = (await writeSponsorships(db, city.scope, runId, sponsorships, { subjectsRead })).written;
  for (const [key, detail] of await openNow()) {
    if (beforeWrite.get(key) !== detail) run.exceptions[key.split('\u0000')[0] as ExceptionCause]++;
  }
  return run;
}

export async function runLocalRecordRefresh(
  opts: { dryRun: boolean; now?: Date },
  deps?: RefreshDeps,
): Promise<RunSummary> {
  const real = deps ?? (await productionDeps());
  // A dry run writes nothing anywhere, the private bucket included; downloads still work.
  const d: RefreshDeps = opts.dryRun ? { ...real, storage: { ...real.storage, upload: async () => undefined, download: (p) => real.storage.download(p) } } : real;
  const now = opts.now ?? new Date();
  const runId = `local-record-${now.toISOString()}`;
  const summary: RunSummary = { runId, cities: [] };
  const failures: string[] = [];

  for (const city of d.loadCities()) {
    if (!city.enabled) continue;
    if (city.reader !== 'onboard') { failures.push(`${city.scope}: unknown reader "${city.reader}"`); continue; }
    let conn: Connection | undefined;
    try {
      conn = await d.connect();
      await conn.query('BEGIN');
      const run = await runCity(conn, city, runId, now, d);
      if (run.controlFailed) {
        await conn.query('ROLLBACK');
        // Always new: the rolled-back city wrote nothing, so a control failure must fail the job every time it happens.
        run.exceptions.control_failed++;
        if (!opts.dryRun) {
          // The exception must survive the rollback of the city's work.
          await conn.query('BEGIN');
          await recordException(conn, city.scope, runId, 'control_failed', run.controlFailed.subject, run.controlFailed.detail);
          await conn.query('COMMIT');
        }
      } else {
        await conn.query(opts.dryRun ? 'ROLLBACK' : 'COMMIT');
      }
      summary.cities.push({
        scope: city.scope, pendingAdded: run.pendingAdded, rollCallsConfirmed: run.rollCallsConfirmed,
        votesWritten: run.votesWritten, sponsorshipsWritten: run.sponsorshipsWritten, exceptions: run.exceptions,
      });
    } catch (e) {
      await conn?.query('ROLLBACK').catch(() => undefined);
      failures.push(`${city.scope}: ${(e as Error).message}`);
    } finally {
      conn?.release();
    }
  }
  if (failures.length) throw new Error(`local-record failed for ${failures.join('; ')}`);
  return summary;
}

/** The scheduled job: fails (non-zero exit) when the run recorded any new exception. */
export async function runLocalRecordJob(deps?: RefreshDeps): Promise<RunSummary> {
  const dryRun = ['1', 'true', 'yes'].includes((process.env.LOCAL_RECORD_DRY_RUN ?? '').toLowerCase());
  const summary = await runLocalRecordRefresh({ dryRun }, deps);
  const fresh = summary.cities.flatMap((c) =>
    Object.entries(c.exceptions).filter(([, n]) => n > 0).map(([cause, n]) => `${c.scope} ${cause} x${n}`),
  );
  console.info(`[local-record] ${JSON.stringify(summary)}${dryRun ? ' (dry run)' : ''}`);
  if (fresh.length) throw new Error(`local-record recorded new exceptions: ${fresh.join(', ')}`);
  return summary;
}
