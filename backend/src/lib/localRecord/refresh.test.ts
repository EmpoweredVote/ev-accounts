import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { checkRollCall } from './checks.js';
import type { NameFile, TermSpan } from './names.js';
import { parseLegislationFeed } from './onboard/feed.js';
import { parseMinutes } from './onboard/minutes.js';
import { makeStorage, runLocalRecordJob, runLocalRecordRefresh, type CityConfig, type Connection, type RefreshDeps } from './refresh.js';
import { externalVoteId } from './store.js';

const fx = (f: string) => new URL(`./onboard/__fixtures__/${f}`, import.meta.url);
const legislation: any[] = JSON.parse(readFileSync(fx('legislation-2026.json'), 'utf8'));
const meetings = JSON.parse(readFileSync(fx('meetings-2026.json'), 'utf8'));
const memoPdf = new Uint8Array(readFileSync(fx('minutes/2026-10-07.pdf')));
const memoText = readFileSync(fx('minutes/2026-10-07.txt'), 'utf8');

const DATE = '2026-10-07';
const MEMO_URL = 'https://bloomington.in.gov/onboard/meetingFiles/17565/download';
const MINUTES_URL = 'https://bloomington.in.gov/onboard/meetingFiles/99001/download';
const NOW = new Date('2026-11-26T12:00:00Z');

// Fixture ids stand in for politician ids. Names are the ones printed in the 2026-10-07 fixture.
const roster = [
  ['p-asare', 'Isak Nti Asare', 'Asare'], ['p-flaherty', 'Matt Flaherty', 'Flaherty'],
  ['p-piedmont-smith', 'Isabel Piedmont-Smith', 'Piedmont-Smith'], ['p-rollo', 'Dave Rollo', 'Rollo'],
  ['p-rosenbarger', 'Kate Rosenbarger', 'Rosenbarger'], ['p-ruff', 'Andy Ruff', 'Ruff'],
  ['p-stosberg', 'Hopi Stosberg', 'Stosberg'], ['p-daily', 'Courtney Daily', 'Daily'],
  ['p-zulich', 'Sydney Zulich', 'Zulich'],
];
const namesFor = (skip?: string): NameFile => ({
  city: 'place:1805860',
  members: roster.filter(([id]) => id !== skip).map(([id, full, short]) => ({ politicianId: id, onboardId: null, variants: [full, short] })),
});
const terms: TermSpan[] = roster.map(([id]) => ({ politicianId: id, start: '2024-01-02', end: null }));

const city = (over: Partial<CityConfig> = {}): CityConfig => ({
  scope: 'place:1805860', slug: 'bloomington-in', reader: 'onboard', base: 'https://bloomington.in.gov', committeeId: 1,
  trust: { file: 'TRUST.md', sha256: 'x', date: '2026-11-25' }, enabled: true, ...over,
});

/** Meetings feed holding only the 2026-10-07 meeting; optionally with a Minutes file added next to the Memorandum. */
function meetingsFeed(withMinutes: boolean) {
  const m = JSON.parse(JSON.stringify(meetings[DATE]['18:30:00'][0]));
  m.files = { Memorandum: m.files.Memorandum };
  if (withMinutes) {
    m.files.Minutes = [{ id: 99001, meeting_id: m.id, type: 'Minutes', url: MINUTES_URL, updated: '2026-11-20 10:00:00' }];
  }
  return { [DATE]: { '18:30:00': [m] } };
}

type Handler = [RegExp, (params: unknown[]) => any[]];

function stubDb(handlers: Handler[] = []) {
  const calls: { text: string; params: unknown[] }[] = [];
  const base: Handler[] = [
    [/SELECT count\(\*\)/, () => [{ n: 0 }]],
    [/SELECT DISTINCT to_char\(r\.meeting_date.*local_record_source_documents d/s, () => []],
    [/SELECT DISTINCT to_char\(meeting_date/, () => []],
    [/SELECT DISTINCT source_url/, () => []],
    [/FROM essentials\.legislative_roll_calls r\s+LEFT JOIN/, () => []],
    [/SELECT detail FROM essentials\.local_record_exceptions/, () => []],
    [/SELECT id FROM essentials\.legislative_bills/, () => [{ id: 'bill1' }]],
    [/SELECT id, superseded_by FROM essentials\.local_record_source_documents/, () => []],
    [/INSERT INTO essentials\.local_record_source_documents/, () => [{ id: 'doc-new' }]],
  ];
  const all = [...handlers, ...base];
  const db = {
    calls,
    async query(text: string, params: unknown[] = []) {
      calls.push({ text, params });
      const h = all.find(([re]) => re.test(text));
      const rows = h ? h[1](params) : [{ id: 'row1' }];
      return { rows, rowCount: rows.length };
    },
    release() {},
  };
  return db as typeof db & Connection;
}

const stubStorage = () => {
  const uploads: string[] = [];
  return { uploads, async upload(p: string) { uploads.push(p); }, async download() { return memoPdf; } };
};

function deps(db: ReturnType<typeof stubDb>, over: Partial<RefreshDeps> & { feed?: any[]; meetings?: unknown; bytes?: Uint8Array } = {}) {
  const urls: string[] = [];
  const d: RefreshDeps = {
    connect: async () => db,
    storage: stubStorage(),
    fetchJson: async (url) => {
      urls.push(url);
      if (/year=2025/.test(url)) return [];
      return /legislation/.test(url) ? (over.feed ?? legislation) : (over.meetings ?? meetingsFeed(false));
    },
    fetchBytes: async () => over.bytes ?? memoPdf,
    pdfText: async () => memoText,
    loadCities: () => [city()],
    loadNames: () => namesFor(),
    loadTerms: async () => terms,
    ...over,
  };
  return Object.assign(d, { urls });
}

const sql = (db: ReturnType<typeof stubDb>, re: RegExp) => db.calls.filter((c) => re.test(c.text));
const verbs = (db: ReturnType<typeof stubDb>) => db.calls.map((c) => c.text.trim()).filter((t) => /^(BEGIN|COMMIT|ROLLBACK)$/.test(t));

/** What the checks resolve for one roll call of the fixture: the shape a stored (Memorandum) row would have. */
function resolved(item: string, question = 'Final passage') {
  const feed = parseLegislationFeed(legislation, 'https://bloomington.in.gov');
  const parse = parseMinutes(memoText, DATE);
  const rc = parse.rollCalls.find((r) => r.itemNumber === item && r.question === question)!;
  const res = checkRollCall(rc, parse, {
    names: namesFor(), terms, seatedCount: 9, feed: new Map(feed.map((i) => [i.itemNumber, i])),
    knownItems: new Set(feed.map((i) => i.itemNumber)),
  });
  if (!res.ok) throw new Error(`fixture roll call did not pass: ${res.detail}`);
  return { rc, res, xid: externalVoteId('place:1805860', DATE, item, question) };
}

const storedRow = (item: string, over: Record<string, unknown> = {}, votes?: { politicianId: string; position: string }[]) => {
  const { rc, res, xid } = resolved(item);
  return {
    external_vote_id: xid, bill_id: 'bill1', state: 'confirmed', outcome: rc.outcome, yes_count: rc.tally.yes,
    no_count: rc.tally.no, abstain_count: rc.tally.abstain, confirmed_from: 'doc-memo',
    votes: votes ?? res.votes.map((v) => ({ politicianId: v.politicianId, position: v.position })), ...over,
  };
};

describe('runLocalRecordRefresh', () => {
  it('happy path: writes the feed and confirms roll calls from the Memorandum', async () => {
    const db = stubDb();
    const d = deps(db);
    const summary = await runLocalRecordRefresh({ dryRun: false, now: NOW }, d);
    expect(d.urls).toContain('https://bloomington.in.gov/onboard/committees/1/legislation?year=2026;format=json');
    expect(d.urls).toContain('https://bloomington.in.gov/onboard/committees/1/legislation?year=2025;format=json');
    expect(sql(db, /INTO essentials\.legislative_bills/).length).toBe(legislation.length);
    expect(sql(db, /INTO essentials\.legislative_roll_calls/).length).toBeGreaterThan(legislation.length);
    expect(sql(db, /INTO essentials\.legislative_votes/).length).toBeGreaterThan(0);
    expect(summary.cities).toHaveLength(1);
    expect(summary.cities[0].rollCallsConfirmed).toBeGreaterThan(0);
    expect(summary.cities[0].votesWritten).toBeGreaterThan(0);
    expect(summary.cities[0].exceptions.control_failed).toBe(0);
    expect(verbs(db)).toEqual(['BEGIN', 'COMMIT']);
    expect(sql(db, /INTO essentials\.local_record_source_documents/)[0].params).toContain('memorandum');
  });

  it('skips a disabled city', async () => {
    const db = stubDb();
    let connected = 0;
    const d = deps(db, { loadCities: () => [city({ enabled: false })], connect: async () => { connected++; return db; } });
    const summary = await runLocalRecordRefresh({ dryRun: false, now: NOW }, d);
    expect(summary.cities).toEqual([]);
    expect(connected).toBe(0);
    expect(d.urls).toEqual([]);
  });

  it('a dry run rolls the city back and never commits', async () => {
    const db = stubDb();
    await runLocalRecordRefresh({ dryRun: true, now: NOW }, deps(db));
    expect(verbs(db)).toEqual(['BEGIN', 'ROLLBACK']);
  });

  it('replaced minutes raise file_changed and write nothing', async () => {
    const db = stubDb([
      [/SELECT DISTINCT source_url/, () => [{ source_url: MEMO_URL }]],
      [/SELECT DISTINCT to_char\(meeting_date/, () => [{ d: DATE, state: 'confirmed' }]],
    ]);
    const d = deps(db, { bytes: new Uint8Array([1, 2, 3]) });
    const summary = await runLocalRecordRefresh({ dryRun: false, now: NOW }, d);
    expect(summary.cities[0].exceptions.file_changed).toBe(1);
    expect(summary.cities[0].rollCallsConfirmed).toBe(0);
    expect(sql(db, /INTO essentials\.legislative_votes/)).toHaveLength(0);
    const exc = sql(db, /INTO essentials\.local_record_exceptions/);
    expect(exc[0].params[2]).toBe('file_changed');
  });

  it('an unchanged known file is fetched again but not read again when nothing waits', async () => {
    const db = stubDb([
      [/SELECT DISTINCT source_url/, () => [{ source_url: MEMO_URL }]],
      [/SELECT DISTINCT to_char\(meeting_date/, () => [{ d: DATE, state: 'confirmed' }]],
      [/SELECT id, superseded_by FROM essentials\.local_record_source_documents/, () => [{ id: 'doc-memo', superseded_by: null }]],
    ]);
    const summary = await runLocalRecordRefresh({ dryRun: false, now: NOW }, deps(db));
    expect(summary.cities[0].rollCallsConfirmed).toBe(0);
    expect(Object.values(summary.cities[0].exceptions).every((n) => n === 0)).toBe(true);
  });

  it('feed final missing from posted minutes raises feed_missing_final', async () => {
    // A real item whose Final was on another date: move its Final onto the meeting date.
    const moved = JSON.parse(JSON.stringify(legislation));
    const held = new Set(parseMinutes(memoText, DATE).rollCalls.map((r) => r.itemNumber));
    const target = parseLegislationFeed(moved, 'x').find((i) => i.final && i.final.date !== DATE && !held.has(i.itemNumber))!;
    moved.find((i: any) => i.id === target.feedId).actions.find((a: any) => a.name === 'Final').date = DATE;

    const db = stubDb();
    const summary = await runLocalRecordRefresh({ dryRun: false, now: NOW }, deps(db, { feed: moved }));
    expect(summary.cities[0].exceptions.feed_missing_final).toBe(1);
    const exc = sql(db, /INTO essentials\.local_record_exceptions/).find((c) => c.params[2] === 'feed_missing_final')!;
    expect(exc.params[3]).toBe(`${DATE} ${target.itemNumber}`);
  });

  it('control mismatch rolls the city back, records control_failed after the rollback, and goes on to other cities', async () => {
    const { xid } = resolved('Ord 2026-28');
    const wrong = storedRow('Ord 2026-28', {}, [{ politicianId: 'p-asare', position: 'nay' }]);
    const db = stubDb([
      [/SELECT DISTINCT to_char\(r\.meeting_date.*local_record_source_documents d/s, () => [{ meeting_date: DATE, doc_id: 'doc-memo', storage_path: 'p.pdf' }]],
      [/FROM essentials\.legislative_roll_calls r\s+LEFT JOIN/, () => [wrong]],
    ]);
    const second = city({ scope: 'place:2', slug: 'second-city' });
    let n = 0;
    const calm = stubDb();
    const d = deps(db, { loadCities: () => [city(), second], connect: async () => (n++ === 0 ? db : calm) });
    const summary = await runLocalRecordRefresh({ dryRun: false, now: NOW }, d);
    expect(xid).toContain('ord-2026-28');
    expect(summary.cities[0].exceptions.control_failed).toBe(1);
    expect(sql(db, /INTO essentials\.legislative_bills/)).toHaveLength(0); // nothing written before the check
    expect(verbs(db)).toEqual(['BEGIN', 'ROLLBACK', 'BEGIN', 'COMMIT']);
    const order = db.calls.map((c) => c.text.trim());
    const exc = db.calls.findIndex((c) => /INTO essentials\.local_record_exceptions/.test(c.text));
    expect(exc).toBeGreaterThan(order.indexOf('ROLLBACK'));
    expect(db.calls[exc].params[2]).toBe('control_failed');
    expect(summary.cities).toHaveLength(2);
    expect(verbs(calm)).toEqual(['BEGIN', 'COMMIT']);
  });
});

describe('Minutes recheck of a Memorandum-confirmed meeting (D14)', () => {
  const recheckHandlers = (stored: any[]): Handler[] => [
    // The Memorandum is saved and confirmed; the Minutes file is new.
    [/SELECT DISTINCT source_url/, () => [{ source_url: MEMO_URL }]],
    [/SELECT DISTINCT to_char\(meeting_date/, () => [{ d: DATE, state: 'confirmed' }]],
    [/FROM essentials\.legislative_roll_calls r\s+LEFT JOIN/, () => stored],
    [/INSERT INTO essentials\.local_record_source_documents/, () => [{ id: 'doc-minutes' }]],
  ];
  const run = (db: ReturnType<typeof stubDb>, over: Partial<RefreshDeps> = {}) =>
    runLocalRecordRefresh({ dryRun: false, now: NOW }, deps(db, { meetings: meetingsFeed(true), ...over }));
  const exceptions = (db: ReturnType<typeof stubDb>, cause: string) =>
    sql(db, /INTO essentials\.local_record_exceptions/).filter((c) => c.params[2] === cause);
  const repointed = (db: ReturnType<typeof stubDb>, xid: string) =>
    sql(db, /INTO essentials\.legislative_roll_calls/).find((c) => c.params[2] === xid && c.params.includes('doc-minutes'));

  it('matching Minutes re-point the rows to the Minutes document and record nothing', async () => {
    const db = stubDb(recheckHandlers([storedRow('Ord 2026-28')]));
    const summary = await run(db);
    expect(repointed(db, resolved('Ord 2026-28').xid)).toBeTruthy();
    expect(exceptions(db, 'minutes_disagree')).toHaveLength(0);
    expect(summary.cities[0].exceptions.minutes_disagree).toBe(0);
  });

  it('Minutes that differ are written (they govern) and minutes_disagree records the differences', async () => {
    const db = stubDb(recheckHandlers([storedRow('Ord 2026-28', {}, [{ politicianId: 'p-asare', position: 'nay' }])]));
    const summary = await run(db);
    expect(repointed(db, resolved('Ord 2026-28').xid)).toBeTruthy();
    const exc = exceptions(db, 'minutes_disagree');
    expect(exc).toHaveLength(1);
    expect(exc[0].params[3]).toBe(`${DATE} Ord 2026-28 Final passage`);
    expect(String(exc[0].params[4])).toContain('p-asare: nay -> yea');
    expect(summary.cities[0].exceptions.minutes_disagree).toBe(1);
    await expect(runLocalRecordJob(deps(stubDb(recheckHandlers([storedRow('Ord 2026-28', {}, [])])), { meetings: meetingsFeed(true) })))
      .rejects.toThrow(/minutes_disagree/);
  });

  it('a Minutes roll call that fails a check keeps the stored version and records the check cause', async () => {
    const db = stubDb(recheckHandlers([storedRow('Ord 2026-28')]));
    const summary = await run(db, { loadNames: () => namesFor('p-asare') });
    expect(repointed(db, resolved('Ord 2026-28').xid)).toBeUndefined();
    expect(exceptions(db, 'unknown_name').length).toBeGreaterThan(0);
    expect(exceptions(db, 'minutes_disagree')).toHaveLength(0);
    expect(summary.cities[0].exceptions.unknown_name).toBeGreaterThan(0);
  });
});

describe('runLocalRecordJob', () => {
  it('does not fail on an exception already logged with the same detail', async () => {
    const moved = JSON.parse(JSON.stringify(legislation));
    const held = new Set(parseMinutes(memoText, DATE).rollCalls.map((r) => r.itemNumber));
    const target = parseLegislationFeed(moved, 'x').find((i) => i.final && i.final.date !== DATE && !held.has(i.itemNumber))!;
    moved.find((i: any) => i.id === target.feedId).actions.find((a: any) => a.name === 'Final').date = DATE;
    const detail = { detail: `the feed has a Final on ${DATE}; the vote document has no roll call for it` };
    const db = stubDb([[/SELECT detail FROM essentials\.local_record_exceptions/, () => [{ detail }]]]);
    const summary = await runLocalRecordJob(deps(db, { feed: moved }));
    expect(summary.cities[0].exceptions.feed_missing_final).toBe(0);
  });

  it('fails when a new exception was recorded', async () => {
    const db = stubDb([[/SELECT DISTINCT source_url/, () => [{ source_url: MEMO_URL }]],
      [/SELECT DISTINCT to_char\(meeting_date/, () => [{ d: DATE, state: 'confirmed' }]]]);
    await expect(runLocalRecordJob(deps(db, { bytes: new Uint8Array([9]) }))).rejects.toThrow(/file_changed/);
  });
});

describe('makeStorage (production adapter)', () => {
  it('uploads with upsert: true so a repeated upload of the same bytes does not fail', async () => {
    const seen: any[] = [];
    const client = { storage: { from: (b: string) => ({ upload: async (...a: any[]) => { seen.push([b, ...a]); return { error: null }; } }) } };
    await makeStorage(client).upload('place-1/minutes/abc.pdf', new Uint8Array([1]), 'application/pdf');
    expect(seen[0][0]).toBe('local-record-sources');
    expect(seen[0][1]).toBe('place-1/minutes/abc.pdf');
    expect(seen[0][3]).toEqual({ contentType: 'application/pdf', upsert: true });
  });

  it('throws when the upload reports an error', async () => {
    const client = { storage: { from: () => ({ upload: async () => ({ error: { message: 'nope' } }) }) } };
    await expect(makeStorage(client).upload('p', new Uint8Array(), 'application/pdf')).rejects.toThrow(/nope/);
  });
});
