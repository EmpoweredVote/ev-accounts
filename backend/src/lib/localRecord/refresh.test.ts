import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { checkRollCall } from './checks.js';
import type { NameFile, TermSpan } from './names.js';
import { parseLegislationFeed } from './onboard/feed.js';
import { parseMinutes } from './onboard/minutes.js';
import { fallbackDocument, governingDocuments, parseCityConfigs, loadCouncilTerms, makeStorage, runLocalRecordJob, runLocalRecordRefresh, type CityConfig, type Connection, type RefreshDeps } from './refresh.js';
import { externalVoteId } from './store.js';

const fx = (f: string) => new URL(`./onboard/__fixtures__/${f}`, import.meta.url);
const legislation: any[] = JSON.parse(readFileSync(fx('legislation-2026.json'), 'utf8'));
const meetings = JSON.parse(readFileSync(fx('meetings-2026.json'), 'utf8'));
const memoPdf = new Uint8Array(readFileSync(fx('minutes/2026-10-07.pdf')));
const memoText = readFileSync(fx('minutes/2026-10-07.txt'), 'utf8');

const DATE = '2026-10-07';
const billNumbers = parseLegislationFeed(legislation, 'https://bloomington.in.gov').map((i) => i.itemNumber);
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
  chamberSlug: 'bloomington-common-council', seatPositionName: 'City Legislature',
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
    [/SELECT subject FROM essentials\.local_record_exceptions/, () => []],
    [/SELECT id FROM essentials\.legislative_bills/, () => [{ id: 'bill1' }]],
    [/SELECT id, superseded_by FROM essentials\.local_record_source_documents/, () => []],
    [/INSERT INTO essentials\.local_record_source_documents/, () => [{ id: 'doc-new' }]],
    // Item numbers of the city's bills (earlier runs wrote one per feed item).
    [/SELECT DISTINCT number FROM essentials\.legislative_bills/, () => billNumbers.map((number) => ({ number }))],
    // Confirmed roll calls still pointing at a Memorandum after the Minutes were read (D14).
    [/d\.kind = 'memorandum'/, () => []],
    // Bills with a pending Final passage and a confirmed Final passage on another date.
    [/p\.state = 'pending_minutes'/, () => []],
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

describe('parseCityConfigs', () => {
  it('returns entries that carry seatPositionName', () => {
    expect(parseCityConfigs([city()])).toEqual([city()]);
  });
  it('throws a clear error when a city lacks seatPositionName', () => {
    const { seatPositionName: _s, ...bad } = city();
    expect(() => parseCityConfigs([bad])).toThrow(/bloomington-in.*seatPositionName/);
  });
});

describe('loadCouncilTerms', () => {
  it('selects council offices by chamber slug, with the configured slug as a parameter', async () => {
    const db = stubDb([[/office_terms/, () => [{ politician_id: 'p1', start: '2024-01-02', end: null }]]]);
    const out = await loadCouncilTerms(db, city());
    const q = db.calls[0];
    expect(q.text).toMatch(/JOIN essentials\.chambers ch ON ch\.id = o\.chamber_id/);
    expect(q.text).toMatch(/ch\.slug = \$1/);
    expect(q.text).not.toMatch(/geo_id/);
    expect(q.params).toEqual(['bloomington-common-council', 'City Legislature']);
    expect(out).toEqual([{ politicianId: 'p1', start: '2024-01-02', end: null }]);
  });
  it('keeps the City Clerk out: only offices with the council position name are seats', async () => {
    const db = stubDb([[/office_terms/, () => []]]);
    await loadCouncilTerms(db, city());
    expect(db.calls[0].text).toMatch(/o\.normalized_position_name = \$2/);
  });
  it('never loads a vacancy span: only terms with a holder', async () => {
    const db = stubDb([[/office_terms/, () => []]]);
    await loadCouncilTerms(db, city());
    expect(db.calls[0].text).toMatch(/ot\.politician_id IS NOT NULL/);
  });
});

describe('fix round 1', () => {
  const known = (): Handler[] => [
    [/SELECT DISTINCT source_url/, () => [{ source_url: MEMO_URL }]],
    [/SELECT DISTINCT to_char\(meeting_date/, () => [{ d: DATE, state: 'pending_minutes' }]],
    [/SELECT id, superseded_by FROM essentials\.local_record_source_documents/, () => [{ id: 'doc-memo', superseded_by: null }]],
  ];

  it('a meeting with an open file_changed exception stays blocked on later runs: nothing fetched or written', async () => {
    const db = stubDb([
      [/SELECT subject FROM essentials\.local_record_exceptions/, () => [{ subject: `${DATE} ${MEMO_URL}` }]],
      ...known(),
    ]);
    let fetched = 0;
    const summary = await runLocalRecordRefresh({ dryRun: false, now: NOW }, deps(db, { fetchBytes: async () => { fetched++; return memoPdf; } }));
    expect(fetched).toBe(0);
    expect(summary.cities[0].rollCallsConfirmed).toBe(0);
    expect(sql(db, /INTO essentials\.legislative_votes/)).toHaveLength(0);
    expect(sql(db, /INTO essentials\.local_record_exceptions/)).toHaveLength(0);
  });

  const controlRows = (): Handler[] => [
    [/SELECT DISTINCT to_char\(r\.meeting_date.*local_record_source_documents d/s, () => [{ meeting_date: DATE, doc_id: 'doc-memo', storage_path: 'p.pdf' }]],
    [/FROM essentials\.legislative_roll_calls r\s+LEFT JOIN/, () => [storedRow('Ord 2026-28')]],
  ];
  const controlFailure = async (over: Partial<RefreshDeps>, expectIn: string) => {
    const db = stubDb(controlRows());
    const summary = await runLocalRecordRefresh({ dryRun: false, now: NOW }, deps(db, over));
    expect(summary.cities[0].exceptions.control_failed).toBe(1);
    expect(verbs(db)).toEqual(['BEGIN', 'ROLLBACK', 'BEGIN', 'COMMIT']);
    const exc = sql(db, /INTO essentials\.local_record_exceptions/)[0];
    expect(exc.params[2]).toBe('control_failed');
    expect(String(exc.params[4])).toContain(expectIn);
    expect(sql(db, /INTO essentials\.legislative_bills/)).toHaveLength(0);
  };
  it('a failed download of the saved copy is a control_failed, not a city error', async () => {
    const storage = { ...stubStorage(), async download(): Promise<Uint8Array> { throw new Error('bucket unreachable'); } };
    await controlFailure({ storage }, 'bucket unreachable');
  });
  it('a parser error in the control is a control_failed, not a city error', async () => {
    await controlFailure({ pdfText: async () => { throw new Error('parser exploded'); } }, 'parser exploded');
  });

  it('a failed connection fails that city alone; the others still run', async () => {
    const calm = stubDb();
    let n = 0;
    const d = deps(calm, {
      loadCities: () => [city(), city({ scope: 'place:2', slug: 'second-city' })],
      connect: async () => { if (n++ === 0) throw new Error('pool down'); return calm; },
    });
    await expect(runLocalRecordRefresh({ dryRun: false, now: NOW }, d)).rejects.toThrow(/place:1805860: pool down/);
    expect(verbs(calm)).toEqual(['BEGIN', 'COMMIT']);
  });

  it('a dry run saves nothing to storage; a real run does', async () => {
    const run = async (dryRun: boolean) => {
      const storage = stubStorage();
      await runLocalRecordRefresh({ dryRun, now: NOW }, deps(stubDb(), { storage }));
      return storage.uploads.length;
    };
    expect(await run(true)).toBe(0);
    expect(await run(false)).toBeGreaterThan(0);
  });
});

describe('final review fixes', () => {
  const exceptions = (db: ReturnType<typeof stubDb>, cause: string) =>
    sql(db, /INTO essentials\.local_record_exceptions/).filter((c) => c.params[2] === cause);

  it('F1: the control knows an item from the city\'s bills even when it is outside the two feed years', async () => {
    // The control meeting is confirmed; the feed (this year and last) no longer lists its items.
    const db = stubDb([
      [/SELECT DISTINCT to_char\(r\.meeting_date.*local_record_source_documents d/s, () => [{ meeting_date: DATE, doc_id: 'doc-memo', storage_path: 'p.pdf' }]],
      [/FROM essentials\.legislative_roll_calls r\s+LEFT JOIN/, () => [storedRow('Ord 2026-28')]],
    ]);
    const summary = await runLocalRecordRefresh({ dryRun: false, now: NOW }, deps(db, { feed: [], meetings: {} }));
    expect(summary.cities[0].exceptions.control_failed).toBe(0);
    expect(verbs(db)).toEqual(['BEGIN', 'COMMIT']);
    const q = sql(db, /SELECT DISTINCT number FROM essentials\.legislative_bills/);
    expect(q).toHaveLength(1);
    expect(q[0].params).toEqual(['place:1805860']);
  });

  it('F1: an item the city has no bill for still fails the control', async () => {
    const db = stubDb([
      [/SELECT DISTINCT to_char\(r\.meeting_date.*local_record_source_documents d/s, () => [{ meeting_date: DATE, doc_id: 'doc-memo', storage_path: 'p.pdf' }]],
      [/FROM essentials\.legislative_roll_calls r\s+LEFT JOIN/, () => [storedRow('Ord 2026-28')]],
      [/SELECT DISTINCT number FROM essentials\.legislative_bills/, () => []],
    ]);
    const summary = await runLocalRecordRefresh({ dryRun: false, now: NOW }, deps(db));
    expect(summary.cities[0].exceptions.control_failed).toBe(1);
    expect(String(sql(db, /INTO essentials\.local_record_exceptions/)[0].params[4])).toContain('unknown_item');
  });

  // The Minutes are the saved fixture text with the Ord 2026-28 roll call taken out.
  const ORD28 = 'Daily moved and Zulich seconded to adopt Ordinance 2026-28. The motion to adopt\nOrdinance 2026-28 as amended received a roll call vote of Ayes: 7, Nays: 0, Abstain: 0.\n';
  const withoutOrd28 = memoText.replace(ORD28, '');
  const stillOnMemo = () => {
    const { xid } = resolved('Ord 2026-28');
    return [{ external_vote_id: xid, item_number: 'Ord 2026-28', question: 'Final passage', confirmed_from: 'doc-memo' }];
  };
  const minutesHandlers = (left: any[]): Handler[] => [
    [/SELECT DISTINCT source_url/, () => [{ source_url: MEMO_URL }]],
    [/SELECT DISTINCT to_char\(meeting_date/, () => [{ d: DATE, state: 'confirmed' }]],
    [/FROM essentials\.legislative_roll_calls r\s+LEFT JOIN/, () => [storedRow('Ord 2026-28')]],
    [/INSERT INTO essentials\.local_record_source_documents/, () => [{ id: 'doc-minutes' }]],
    [/d\.kind = 'memorandum'/, () => left],
  ];

  it('F2a: a Memorandum-confirmed roll call the Minutes do not contain raises minutes_disagree', async () => {
    expect(withoutOrd28).not.toBe(memoText);
    const db = stubDb(minutesHandlers(stillOnMemo()));
    const summary = await runLocalRecordRefresh(
      { dryRun: false, now: NOW }, deps(db, { meetings: meetingsFeed(true), pdfText: async () => withoutOrd28 }),
    );
    const exc = exceptions(db, 'minutes_disagree');
    expect(exc).toHaveLength(1);
    expect(exc[0].params[3]).toBe(`${DATE} Ord 2026-28 Final passage`);
    expect(String(exc[0].params[4])).toContain('missing from the Minutes');
    expect(summary.cities[0].exceptions.minutes_disagree).toBe(1);
    const q = sql(db, /d\.kind = 'memorandum'/)[0];
    expect(q.params).toEqual(['place:1805860', DATE]);
  });

  it('F2a: a roll call the Minutes contain is not reported missing (even when its check failed)', async () => {
    const db = stubDb(minutesHandlers(stillOnMemo()));
    await runLocalRecordRefresh({ dryRun: false, now: NOW }, deps(db, { meetings: meetingsFeed(true) }));
    expect(exceptions(db, 'minutes_disagree')).toHaveLength(0);
  });

  it('F2a: a date still governed by a Memorandum is not checked for missing roll calls', async () => {
    const db = stubDb([
      [/d\.kind = 'memorandum'/, () => stillOnMemo()],
    ]);
    await runLocalRecordRefresh({ dryRun: false, now: NOW }, deps(db, { pdfText: async () => withoutOrd28 }));
    expect(exceptions(db, 'minutes_disagree')).toHaveLength(0);
  });

  it('F3: a pending Final passage beside a confirmed Final passage on another date raises feed_missing_final', async () => {
    const db = stubDb([
      [/p\.state = 'pending_minutes'/, () => [{ number: 'Ord 2026-28', pending_date: '2026-10-21', confirmed_date: DATE }]],
    ]);
    const summary = await runLocalRecordRefresh({ dryRun: false, now: NOW }, deps(db));
    const exc = exceptions(db, 'feed_missing_final');
    expect(exc).toHaveLength(1);
    expect(exc[0].params[3]).toBe('Ord 2026-28 Final passage 2026-10-21');
    expect(String(exc[0].params[4])).toContain('2026-10-21');
    expect(String(exc[0].params[4])).toContain(DATE);
    expect(summary.cities[0].exceptions.feed_missing_final).toBe(1);
    const q = sql(db, /p\.state = 'pending_minutes'/)[0];
    expect(q.text).toMatch(/c\.state = 'confirmed'/);
    expect(q.text).toMatch(/c\.meeting_date <> p\.meeting_date/);
    expect(q.text).toMatch(/question = 'Final passage'/);
    expect(q.params).toEqual(['place:1805860']);
  });
});

describe('R8: which document governs a meeting', () => {
  const doc = (meetingId: number, meetingDate: string, fileId: number, kind: 'minutes' | 'memorandum', fileName: string, meetingTitle: string) => ({
    meetingId, meetingDate, fileId, kind, fileName, meetingTitle,
    url: `https://bloomington.in.gov/onboard/meetingFiles/${fileId}/download`, updated: 'u',
  });

  it('a "Regular Session and Special Session" meeting is governed per session (2021-05-05, meeting 4704)', () => {
    const t = 'Common Council Regular Session and Special Session';
    const got = governingDocuments([
      doc(4704, '2021-05-05', 8769, 'memorandum', '2021.05.05.RS.Web_Memo.pdf', t),
      doc(4704, '2021-05-05', 8770, 'minutes', '2021.05.05.SS.min.signed.pdf', t),
    ]);
    expect(got.map((d) => d.fileId).sort()).toEqual([8769, 8770]);
  });

  it('a one-session meeting with mislabelled files is still one document (2022-12-14, meeting 5707)', () => {
    const t = 'Common Council Special Session';
    const got = governingDocuments([
      doc(5707, '2022-12-14', 11195, 'memorandum', '2022.12.14.SS_memo.pdf', t),
      doc(5707, '2022-12-14', 13776, 'minutes', '2022.12.14.RS.mins.pv.signed.pdf', t),
    ]);
    expect(got.map((d) => d.fileId)).toEqual([13776]);
  });

  it('a Committee of the Whole memo never governs over the session memo (2026-09-23, meeting 11967)', () => {
    const t = 'Common Council Special Session - Introduction of 2027 Budget Legislation';
    const got = governingDocuments([
      doc(11967, '2026-09-23', 17521, 'memorandum', '2026.09.23.SS.Memo.pdf', t),
      doc(11967, '2026-09-23', 17522, 'memorandum', '2026.09.23.COW.Memo.pdf', t),
    ]);
    expect(got.map((d) => d.fileId)).toEqual([17521]);
  });

  it('the fallback for minutes that print another date is the meeting\'s memorandum (2025-03-05: 15758 -> 14709)', () => {
    const t = 'Common Council Regular Session';
    const all = [
      doc(7095, '2025-03-05', 15758, 'minutes', '2025.05.07.RS.mins.pv.revised.signed.pdf', t),
      doc(7095, '2025-03-05', 14709, 'memorandum', '2025.03.05.RS_memo.pdf', t),
    ];
    expect(fallbackDocument(all[0], all)?.fileId).toBe(14709);
    expect(fallbackDocument(all[1], all)).toBeNull();
  });
});

describe('R8: a document that prints another meeting date is not read for this meeting', () => {
  it('raises an exception, confirms nothing from it, and reads the meeting\'s memorandum instead', async () => {
    const db = stubDb([
      [/INSERT INTO essentials\.local_record_source_documents/, (p) => [{ id: p[2] === MINUTES_URL ? 'doc-minutes' : 'doc-memo' }]],
    ]);
    const m = JSON.parse(JSON.stringify(meetings[DATE]['18:30:00'][0]));
    m.files = {
      Memorandum: m.files.Memorandum,
      Minutes: [{ id: 99001, meeting_id: m.id, type: 'Minutes', url: MINUTES_URL, updated: '2026-11-20 10:00:00', filename: 'x.pdf' }],
    };
    const wrongMinutes = new Uint8Array([1, 2, 3]);
    const d = deps(db, {
      meetings: { [DATE]: { '18:30:00': [m] } },
      fetchBytes: async (url: string) => (url === MINUTES_URL ? wrongMinutes : memoPdf),
      pdfText: async (b: Uint8Array) => (b === wrongMinutes ? memoText.replace('Wednesday, October 07, 2026', 'Wednesday, May 07, 2025') : memoText),
    });
    await runLocalRecordRefresh({ dryRun: false, now: NOW }, d);
    const ex = sql(db, /INSERT INTO essentials\.local_record_exceptions/).map((c) => c.params);
    expect(ex.some((p) => p[2] === 'unparsed_roll_call' && String(p[3]).startsWith(`${DATE} document 99001`))).toBe(true);
    const confirmed = sql(db, /'confirmed', \$12/).map((c) => c.params[11]);
    expect(confirmed.length).toBeGreaterThan(0);
    expect(new Set(confirmed)).toEqual(new Set(['doc-memo']));
  });
});
