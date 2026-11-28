import { mkdirSync, mkdtempSync, unlinkSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import type { NameFile } from '../../src/lib/localRecord/names.js';
import type { CityConfig } from '../../src/lib/localRecord/refresh.js';
import {
  applyCorrections, applyOwnerChecks, applySponsorOwnerChecks, compareSponsors, compareWithInventory, drawSponsorSpotCheck, inventorySponsorSubjects, normaliseItemNumber, sponsorBlockers, type SponsorRowOut, drawSpotCheck, flagDuplicates, flagRepeatedFinals, idForSurname, parseInventoryId, runFirstLoad, withDownloadCache, type FirstLoadDeps,
  type InventoryItem, type OwnerCheck, type ReaderRollCall, validateOwnerChecks,
} from './first-load.js';
import type { FeedItem } from '../../src/lib/localRecord/types.js';

const fx = (f: string) => new URL(`./__fixtures__/${f}`, import.meta.url);
const ofx = (f: string) => new URL(`../../src/lib/localRecord/onboard/__fixtures__/${f}`, import.meta.url);
const invFull: { items: InventoryItem[] } = JSON.parse(readFileSync(fx('inventory-full.json'), 'utf8'));
const invDeep: { items: InventoryItem[] } = JSON.parse(readFileSync(fx('inventory-deep.json'), 'utf8'));
const roster = JSON.parse(readFileSync(fx('inventory-roster.json'), 'utf8'));
const legislation = JSON.parse(readFileSync(ofx('legislation-2026.json'), 'utf8'));
const meetings = JSON.parse(readFileSync(ofx('meetings-2026.json'), 'utf8'));
const memoPdf = new Uint8Array(readFileSync(ofx('minutes/2026-10-07.pdf')));
const memoText = readFileSync(ofx('minutes/2026-10-07.txt'), 'utf8');

/** Fill every sponsor spot-check verdict (the picks are checked by eye in a real run). */
const fillSponsorSpot = (out: string, verdict = 'match') => {
  const p = path.join(out, 'sponsor-spotcheck.json');
  const spot = JSON.parse(readFileSync(p, 'utf8'));
  spot.picks.forEach((x: any) => (x.verdict = verdict));
  writeFileSync(p, JSON.stringify(spot));
  return spot;
};

const SCOPE = 'place:1805860';
const DATE = '2026-10-07';
const NOW = new Date('2026-11-26T12:00:00Z');
const PEOPLE = [
  ['p-asare', 'Isak Nti Asare', 'Asare'], ['p-flaherty', 'Matt Flaherty', 'Flaherty'],
  ['p-piedmont-smith', 'Isabel Piedmont-Smith', 'Piedmont-Smith'], ['p-rollo', 'Dave Rollo', 'Rollo'],
  ['p-rosenbarger', 'Kate Rosenbarger', 'Rosenbarger'], ['p-ruff', 'Andy Ruff', 'Ruff'],
  ['p-stosberg', 'Hopi Stosberg', 'Stosberg'], ['p-daily', 'Courtney Daily', 'Daily'],
  ['p-zulich', 'Sydney Zulich', 'Zulich'],
];
const names = (nullId?: string): NameFile => ({
  city: SCOPE,
  members: PEOPLE.map(([id, full, short]) => ({
    politicianId: id === nullId ? null : id, onboardId: null, variants: [full, short],
  })),
});
const city: CityConfig = {
  scope: SCOPE, slug: 'bloomington-in', reader: 'onboard', base: 'https://bloomington.in.gov', committeeId: 1,
  chamberSlug: 'bloomington-common-council', seatPositionName: 'City Legislature', trust: { file: 'TRUST.md', sha256: 'x', date: '2026-11-25' }, enabled: false,
};

describe('parseInventoryId: suffix mapping', () => {
  const id = (s: string) => `place:1805860:2026-10-07:${s}`;
  it.each([
    ['Ord 2026-25', 'Final passage'],
    ['Ord 2026-25 (amendment 1)', 'Amendment 01'],
    ['Ord 2026-25 (amendment 01)', 'Amendment 01'],
    ['Ord 2026-25 (amendment 12)', 'Amendment 12'],
    ['Ord 2026-25 (amendment 001)', 'Amendment 01'],
    ['Res 2026-04 (veto override)', 'Veto override'],
  ])('%s -> %s', (raw, question) => {
    expect(parseInventoryId(id(raw))).toEqual({ date: DATE, itemNumber: raw.replace(/ \(.*/, ''), question });
  });
  it.each([
    'Ord 2026-25 (motion to read by title)',
    'Ord 2026-25 (reasonable condition 01)',
    'Ord 2026-25 (amendment to amendment 05)',
    'Ord 2023-23 (Vetoed)',
    '3',
  ])('skips %s', (raw) => {
    expect(parseInventoryId(id(raw))).toHaveProperty('skip');
  });
});

const rr = (over: Partial<ReaderRollCall> = {}): ReaderRollCall => ({
  index: 0, date: DATE, itemNumber: 'App Ord 2026-03', question: 'Final passage', status: 'confirmed', outcome: 'passed',
  tally: { yes: 7, no: 0, abstain: 0 }, sentence: 'The motion to adopt received a roll call vote.', documentUrl: 'u',
  votes: [
    ['p-asare', 'yea'], ['p-daily', 'yea'], ['p-flaherty', 'yea'], ['p-piedmont-smith', 'yea'], ['p-rollo', 'absent'],
    ['p-rosenbarger', 'absent'], ['p-ruff', 'yea'], ['p-stosberg', 'yea'], ['p-zulich', 'yea'],
  ].map(([politicianId, position]) => ({ politicianId, nameAsPrinted: politicianId, position, workedOut: true })) as any,
  ...over,
});

describe('compareWithInventory', () => {
  const item = invFull.items.find((i) => i.id.endsWith('App Ord 2026-03'))!;
  const cmp = (reader: ReaderRollCall[], items = [item]) => compareWithInventory(reader, items, roster, names());

  it('agrees when every member matches', () => {
    const r = cmp([rr()]);
    expect(r.items[0].status).toBe('agree');
    expect(r.exceptions).toEqual([]);
  });

  it('a differing member makes a differs row and an inventory_disagrees exception', () => {
    const v = rr();
    v.votes![0] = { ...v.votes![0], position: 'nay' };
    const r = cmp([v]);
    expect(r.items[0].status).toBe('differs');
    expect(r.members.filter((m) => m.status === 'differs').length).toBe(1);
    expect(r.exceptions).toHaveLength(1);
    expect(r.exceptions[0]).toMatchObject({ cause: 'inventory_disagrees', subject: `${DATE} App Ord 2026-03 Final passage` });
  });

  it('an inventory item the reader did not confirm is inventory only (an exception)', () => {
    const r = cmp([]);
    expect(r.items[0].status).toBe('inventory only');
    expect(r.exceptions[0].cause).toBe('inventory_disagrees');
  });

  it('a confirmed reader vote with no inventory row is reader only, and raises nothing', () => {
    const r = cmp([rr(), rr({ itemNumber: 'Ord 2026-99' })]);
    expect(r.readerOnly.map((x) => x.itemNumber)).toEqual(['Ord 2026-99']);
    expect(r.exceptions).toEqual([]);
  });

  it('procedural motions are skipped, not compared', () => {
    const motion = invDeep.items.find((i) => i.id.includes('(motion to read by title)'))!;
    const r = cmp([], [motion]);
    expect(r.items).toEqual([]);
    expect(r.skipped).toHaveLength(1);
    expect(r.exceptions).toEqual([]);
  });
});

describe('fix round 1', () => {
  const item = invFull.items.find((i) => i.id.endsWith('App Ord 2026-03'))!;
  const cmp = (reader: ReaderRollCall[], items: InventoryItem[]) => compareWithInventory(reader, items, roster, names());

  it('1: an absent reader-side member the inventory omits is not a disagreement', () => {
    const lean = { ...item, members: item.members!.filter((m) => m.name !== 'Rollo') };
    const r = cmp([rr()], [lean]);
    expect(r.items[0].status).toBe('agree');
    expect(r.exceptions).toEqual([]);
  });

  it('1: a recorded vote the inventory omits still counts', () => {
    const lean = { ...item, members: item.members!.filter((m) => m.name !== 'Asare') };
    expect(cmp([rr()], [lean]).items[0].status).toBe('differs');
  });

  it('2: an inventory item with no members is its own category, not agree', () => {
    const r = cmp([rr()], [{ ...item, members: [] }]);
    expect(r.items[0].status).toBe('no members to compare');
    expect(r.exceptions).toEqual([]);
  });

  it('3: a bare Smith never means Piedmont-Smith', () => {
    const withSmith: NameFile = {
      city: SCOPE,
      members: [...names().members, { politicianId: 'p-smith', onboardId: null, variants: ['Ron Smith', 'Smith'] }],
    };
    expect(idForSurname('Smith', '2021-03-03', roster, withSmith)).toBe('p-smith');
    expect(idForSurname('Smith', '2025-03-03', roster, withSmith)).toHaveProperty('error');
    expect(idForSurname('Smith', '2025-03-03', roster, names())).toHaveProperty('error');
    expect(idForSurname('Piedmont-Smith', '2025-03-03', roster, names())).toBe('p-piedmont-smith');
  });

  it('4: duplicate keys stay visible, become failed, and raise an exception', () => {
    const a = rr();
    const b = rr({ index: 5, tally: { yes: 6, no: 1, abstain: 0 } });
    const other = rr({ itemNumber: 'Ord 2026-99' });
    const r = flagDuplicates([a, b, other]);
    expect(r.reader).toHaveLength(3);
    expect(r.reader.filter((x) => x.status === 'failed')).toHaveLength(2);
    expect(r.reader.find((x) => x.itemNumber === 'Ord 2026-99')!.status).toBe('confirmed');
    expect(r.exceptions).toHaveLength(1);
    expect(r.exceptions[0].detail).toMatchObject({ kind: 'duplicate roll call' });
  });
});

describe('drawSpotCheck', () => {
  const pool = Array.from({ length: 80 }, (_, i) => rr({ itemNumber: `Ord 2026-${String(i).padStart(2, '0')}` }));
  const ids = (p: { itemNumber: string }[]) => p.map((x) => x.itemNumber);
  it('is reproducible from its seed, whatever the input order', () => {
    const a = drawSpotCheck(pool, 1234);
    expect(a).toHaveLength(30);
    expect(ids(drawSpotCheck([...pool].reverse(), 1234))).toEqual(ids(a));
    expect(ids(drawSpotCheck(pool, 1235))).not.toEqual(ids(a));
  });
  it('takes all of them when there are fewer than 30', () => {
    expect(drawSpotCheck(pool.slice(0, 7), 1)).toHaveLength(7);
  });
});

// ---- whole-run tests with stubs -------------------------------------------------------------------------------
function setup(opts: { inventory?: { items: InventoryItem[] }; staging?: boolean } = {}) {
  const root = mkdtempSync(path.join(tmpdir(), 'first-load-'));
  const inventory = path.join(root, 'inv');
  const out = path.join(root, 'out');
  mkdirSync(inventory, { recursive: true });
  const inv = opts.inventory ?? { items: [invDeep.items.find((i) => i.id.includes('(motion to read by title)'))!] };
  writeFileSync(path.join(inventory, 'full.json'), JSON.stringify(inv));
  writeFileSync(path.join(inventory, 'deep.json'), JSON.stringify({ items: [] }));
  writeFileSync(path.join(inventory, 'roster.json'), JSON.stringify(roster));
  if (opts.staging) {
    mkdirSync(path.join(inventory, 'store-staging/items'), { recursive: true });
    mkdirSync(path.join(inventory, 'store-staging/minutes'), { recursive: true });
    const it = inv.items.find((i) => i.text_store_path)!;
    writeFileSync(path.join(inventory, 'store-staging', it.text_store_path!), 'item text');
    writeFileSync(path.join(inventory, 'store-staging/minutes', `${it.date}.txt`), 'minutes text');
  }
  return { inventory, out };
}

const calls: { text: string }[] = [];
const uploads: string[] = [];
function deps(over: Partial<FirstLoadDeps> = {}, nameFile: NameFile = names()): FirstLoadDeps {
  calls.length = 0;
  uploads.length = 0;
  const db = {
    async query(text: string) {
      calls.push({ text });
      const rows = /SELECT id FROM essentials\.legislative_bills/.test(text) ? [{ id: 'bill1' }]
        : /SELECT id, superseded_by/.test(text) ? [] : [{ id: 'row1' }];
      return { rows, rowCount: rows.length };
    },
    release() {},
  };
  return {
    fetchJson: async (url) => {
      if (!/year=2026/.test(url)) return /legislation/.test(url) ? [] : {};
      return /legislation/.test(url) ? legislation : { [DATE]: { '18:30:00': [onlyMemo()] } };
    },
    fetchBytes: async () => memoPdf,
    pdfText: async () => memoText,
    loadCities: () => [city],
    loadNames: () => nameFile,
    connect: async () => db as any,
    storage: { upload: async (p: string) => { uploads.push(p); } },
    ...over,
  };
}
function onlyMemo() {
  const m = JSON.parse(JSON.stringify(meetings[DATE]['18:30:00'][0]));
  m.files = { Memorandum: m.files.Memorandum };
  return m;
}
const base = (s: { inventory: string; out: string }, extra: object = {}) =>
  ({ city: SCOPE, inventory: s.inventory, out: s.out, apply: false, now: NOW, ...extra });

describe('runFirstLoad: dry run', () => {
  it('writes the four files and makes no database or storage call', async () => {
    const s = setup({ inventory: invFull });
    const d = deps({
      connect: async () => { throw new Error('db touched'); },
      storage: { upload: async () => { throw new Error('storage touched'); } },
    });
    const r = await runFirstLoad(base(s, { seed: 7 }), d);
    for (const f of ['reader-output.json', 'compare.md', 'spotcheck.json', 'summary.md']) {
      expect(existsSync(path.join(s.out, f)), f).toBe(true);
    }
    expect(r.refused).toBeUndefined();
    const reader = JSON.parse(readFileSync(path.join(s.out, 'reader-output.json'), 'utf8'));
    expect(reader.rollCalls.some((x: any) => x.status === 'confirmed')).toBe(true);
    const spot = JSON.parse(readFileSync(path.join(s.out, 'spotcheck.json'), 'utf8'));
    expect(spot.seed).toBe(7);
    expect(spot.picks.every((p: any) => p.verdict === '' && p.quote)).toBe(true);
    const compare = readFileSync(path.join(s.out, 'compare.md'), 'utf8');
    expect(compare).toMatch(/Items: 18 compared\. Members: \d+ agree, 0 differ/);
    expect(readFileSync(path.join(s.out, 'summary.md'), 'utf8')).toMatch(/inventory_disagrees: 4/);
  });

  it('writes every exception it found to exceptions.json, matching the summary counts', async () => {
    const s = setup({ inventory: invFull });
    await runFirstLoad(base(s, { seed: 7 }), deps());
    const ex = JSON.parse(readFileSync(path.join(s.out, 'exceptions.json'), 'utf8'));
    expect(Array.isArray(ex.exceptions)).toBe(true);
    for (const e of ex.exceptions) expect(Object.keys(e).sort()).toEqual(['cause', 'detail', 'subject']);
    const summary = readFileSync(path.join(s.out, 'summary.md'), 'utf8');
    const counts: Record<string, number> = {};
    for (const e of ex.exceptions) counts[e.cause] = (counts[e.cause] ?? 0) + 1;
    for (const [cause, n] of Object.entries(counts)) expect(summary).toContain(`- ${cause}: ${n}`);
    expect(counts.inventory_disagrees).toBe(4);
  });

  it('keeps filled-in verdicts when the same draw is made again', async () => {
    const s = setup({ inventory: { items: [] } });
    await runFirstLoad(base(s, { seed: 7 }), deps());
    const p = path.join(s.out, 'spotcheck.json');
    const spot = JSON.parse(readFileSync(p, 'utf8'));
    spot.picks[0].verdict = 'match';
    writeFileSync(p, JSON.stringify(spot));
    await runFirstLoad(base(s), deps());
    const again = JSON.parse(readFileSync(p, 'utf8'));
    expect(again.seed).toBe(7);
    expect(again.picks[0].verdict).toBe('match');
  });
});

describe('withDownloadCache', () => {
  it('downloads each URL once and reuses the saved copy on the next run', async () => {
    const dir = path.join(mkdtempSync(path.join(tmpdir(), 'first-load-cache-')), 'cache');
    let bytesCalls = 0;
    let jsonCalls = 0;
    const raw = deps({
      fetchBytes: async (u) => { bytesCalls++; return new TextEncoder().encode(`pdf of ${u}`); },
      fetchJson: async (u) => { jsonCalls++; return { u }; },
    });
    const a = withDownloadCache(raw, dir);
    expect(new TextDecoder().decode(await a.fetchBytes('https://x/a.pdf'))).toBe('pdf of https://x/a.pdf');
    expect(await a.fetchJson('https://x/m?year=2021;format=json')).toEqual({ u: 'https://x/m?year=2021;format=json' });
    // A second wrapper over the same folder (a re-run) reads from disk.
    const b = withDownloadCache(raw, dir);
    expect(new TextDecoder().decode(await b.fetchBytes('https://x/a.pdf'))).toBe('pdf of https://x/a.pdf');
    expect(await b.fetchJson('https://x/m?year=2021;format=json')).toEqual({ u: 'https://x/m?year=2021;format=json' });
    await b.fetchBytes('https://x/b.pdf');
    expect(bytesCalls).toBe(2);
    expect(jsonCalls).toBe(1);
  });

  it('does not save a failed download', async () => {
    const dir = mkdtempSync(path.join(tmpdir(), 'first-load-cache-'));
    let n = 0;
    const raw = deps({ fetchBytes: async () => { n++; if (n === 1) throw new Error('GET failed: 503'); return new Uint8Array([1]); } });
    const c = withDownloadCache(raw, dir);
    await expect(c.fetchBytes('https://x/a.pdf')).rejects.toThrow(/503/);
    expect(await c.fetchBytes('https://x/a.pdf')).toEqual(new Uint8Array([1]));
    expect(n).toBe(2);
  });
});

describe('runFirstLoad: --apply', () => {
  const fill = (out: string, verdict: string) => {
    const p = path.join(out, 'spotcheck.json');
    const spot = JSON.parse(readFileSync(p, 'utf8'));
    spot.picks.forEach((x: any) => (x.verdict = verdict));
    writeFileSync(p, JSON.stringify(spot));
    fillSponsorSpot(out);
    return spot;
  };

  it('refuses when a politician id is still null, before reading anything', async () => {
    const s = setup();
    let fetched = 0;
    const d = deps({ fetchJson: async () => { fetched++; return []; } }, names('p-asare'));
    const r = await runFirstLoad(base(s, { apply: true }), d);
    expect(r.refused?.join(' ')).toMatch(/politicianId/);
    expect(fetched).toBe(0);
    expect(calls).toEqual([]);
  });

  it('refuses when there is no spotcheck.json from a dry run', async () => {
    const s = setup();
    const r = await runFirstLoad(base(s, { apply: true }), deps());
    expect(r.refused?.join(' ')).toMatch(/spotcheck/);
    expect(calls).toEqual([]);
  });

  it('refuses with one blank verdict and touches nothing', async () => {
    const s = setup();
    await runFirstLoad(base(s, { seed: 3 }), deps());
    const spot = fill(s.out, 'match');
    expect(spot.picks.length).toBeGreaterThan(1);
    spot.picks[0].verdict = '';
    writeFileSync(path.join(s.out, 'spotcheck.json'), JSON.stringify(spot));
    const r = await runFirstLoad(base(s, { apply: true }), deps());
    expect(r.refused?.join(' ')).toMatch(/verdict/);
    expect(calls).toEqual([]);
    expect(uploads).toEqual([]);
  });

  it('refuses while an inventory disagreement is open', async () => {
    const s = setup({ inventory: invFull });
    await runFirstLoad(base(s, { seed: 3 }), deps());
    fill(s.out, 'match');
    const r = await runFirstLoad(base(s, { apply: true }), deps());
    expect(r.refused?.join(' ')).toMatch(/inventory_disagrees/);
    expect(calls).toEqual([]);
  });

  it('refuses when a spot check did not match', async () => {
    const s = setup();
    await runFirstLoad(base(s, { seed: 3 }), deps());
    fill(s.out, 'differs');
    const r = await runFirstLoad(base(s, { apply: true }), deps());
    expect(r.refused?.join(' ')).toMatch(/spot_check_failed/);
    expect(calls).toEqual([]);
  });

  it('refuses when the reader now gives a picked vote different positions than the one that was checked', async () => {
    const s = setup();
    await runFirstLoad(base(s, { seed: 3 }), deps());
    const spot = fill(s.out, 'match');
    spot.picks[0].votesHash = 'something-else';
    writeFileSync(path.join(s.out, 'spotcheck.json'), JSON.stringify(spot));
    const r = await runFirstLoad(base(s, { apply: true }), deps());
    expect(r.refused?.join(' ')).toMatch(/votes changed/);
    expect(calls).toEqual([]);
  });

  it('a dry run drops a verdict whose votes changed', async () => {
    const s = setup();
    await runFirstLoad(base(s, { seed: 3 }), deps());
    const spot = fill(s.out, 'match');
    spot.picks[0].votesHash = 'stale';
    writeFileSync(path.join(s.out, 'spotcheck.json'), JSON.stringify(spot));
    await runFirstLoad(base(s), deps());
    const again = JSON.parse(readFileSync(path.join(s.out, 'spotcheck.json'), 'utf8'));
    expect(again.picks[0].verdict).toBe('');
    expect(again.picks[1].verdict).toBe('match');
  });

  it('writes the roll calls, then uploads the saved texts, when every gate is clear', async () => {
    const s = setup({ staging: true });
    await runFirstLoad(base(s, { seed: 3 }), deps());
    fill(s.out, 'match');
    const r = await runFirstLoad(base(s, { apply: true }), deps());
    expect(r.refused).toBeUndefined();
    expect(r.applied?.rollCallsConfirmed).toBeGreaterThan(0);
    expect(r.applied?.stagedItems).toBe(1);
    expect(r.applied?.stagedMinutes).toBe(1);
    const sql = calls.map((c) => c.text.trim());
    expect(sql[0]).toBe('BEGIN');
    expect(sql.at(-1)).toBe('COMMIT');
    expect(sql.some((t) => /INTO essentials\.legislative_votes/.test(t))).toBe(true);
    expect(uploads.some((u) => u.includes('/item_text/'))).toBe(true);
    expect(uploads.some((u) => u.includes('/minutes/'))).toBe(true);
    // The saved texts go first, so the real vote document stays the current copy of its URL.
    expect(uploads.findIndex((u) => u.includes('/memorandum/'))).toBeGreaterThan(uploads.findIndex((u) => u.includes('/minutes/')));
  });
});

describe('R8: minutes that print another meeting date (2025-03-05 holds the 2025-05-07 minutes)', () => {
  it('confirms nothing from them, logs an exception, and reads the meeting\'s memorandum instead', async () => {
    const s = setup({ inventory: invFull });
    const MINUTES_URL = 'https://bloomington.in.gov/onboard/meetingFiles/99001/download';
    const wrong = new Uint8Array([9, 9, 9]);
    const m = onlyMemo();
    m.files.Minutes = [{ id: 99001, type: 'Minutes', url: MINUTES_URL, updated: 'u', filename: '2025.05.07.RS.mins.pv.revised.signed.pdf' }];
    const d = deps({
      fetchJson: async (url) => {
        if (!/year=2026/.test(url)) return /legislation/.test(url) ? [] : {};
        return /legislation/.test(url) ? legislation : { [DATE]: { '18:30:00': [m] } };
      },
      fetchBytes: async (url) => (url === MINUTES_URL ? wrong : memoPdf),
      pdfText: async (b) => (b === wrong ? memoText.replace('Wednesday, October 07, 2026', 'Wednesday, May 07, 2025') : memoText),
    });
    await runFirstLoad(base(s, { seed: 7 }), d);
    const reader = JSON.parse(readFileSync(path.join(s.out, 'reader-output.json'), 'utf8'));
    expect(reader.rollCalls.length).toBeGreaterThan(0);
    expect(reader.rollCalls.every((r: any) => r.documentUrl !== MINUTES_URL)).toBe(true);
    const ex = JSON.parse(readFileSync(path.join(s.out, 'exceptions.json'), 'utf8')).exceptions;
    expect(ex).toContainEqual(expect.objectContaining({
      cause: 'unparsed_roll_call', subject: `${DATE} document 99001`,
      detail: expect.objectContaining({ printedDate: '2025-05-07' }),
    }));
  });
});

describe('R8: a document with no text (the scanned 2020-12-16 minutes, file 9806)', () => {
  it('is an exception, not a silent empty meeting', async () => {
    const s = setup({ inventory: invFull });
    await runFirstLoad(base(s, { seed: 7 }), deps({ pdfText: async () => '' }));
    const ex = JSON.parse(readFileSync(path.join(s.out, 'exceptions.json'), 'utf8')).exceptions;
    expect(ex).toContainEqual(expect.objectContaining({
      cause: 'unparsed_roll_call', subject: `${DATE} document 17565`,
      detail: expect.objectContaining({ kind: 'the document has no text (a scanned image)' }),
    }));
  });
});

describe('R11: two passed Final passages of one item on different dates', () => {
  it('the later one is held as an exception', () => {
    const mk = (date: string): ReaderRollCall => ({
      index: 0, date, itemNumber: 'Res 2024-04', question: 'Final passage', status: 'confirmed', outcome: 'passed',
      tally: { yes: 7, no: 0, abstain: 1 }, sentence: 's', documentUrl: 'u', votes: [],
    });
    const out = flagRepeatedFinals([mk('2024-03-27'), mk('2024-04-17')]);
    expect(out.reader.map((r) => r.status)).toEqual(['confirmed', 'failed']);
    expect(out.reader[1]).toMatchObject({ cause: 'outcome_conflict' });
    expect(out.exceptions).toHaveLength(1);
  });
});

describe('R10: inventory rows that are not votes on the item are skipped, not compared', () => {
  const row = (id: string, record_type: string, notes: string): InventoryItem =>
    ({ id, date: id.split(':')[2], item_no: id.split(':')[3], record_type, notes, members: [] } as InventoryItem);
  const inv = [
    row('place:1805860:2026-05-06:Ord 2026-08', 'OTHER', 'First reading; no vote on the item. Text read (legislation file 5956) against the Plan Commission table of changes.'),
    row('place:1805860:2026-05-06:Ord 2026-07', 'ACTION_ITEM_NAMED', 'Motion to postpone; not a vote on the item. A motion to reconsider was withdrawn.'),
    row('place:1805860:2026-02-18:Ord 2026-06', 'ACTION_ITEM_NAMED', 'FAILED. Procedural motion to introduce and read by title; not a vote on the rezoning itself.'),
    row('place:1805860:2026-06-03:Res 2026-09', 'ACTION_ITEM_NAMED', 'FAILED. Motion to introduce; procedural. The council had received the plan the day before.'),
    row('place:1805860:2026-09-02:Ord 2026-18', 'ACTION_ITEM_NAMED', 'Final passage as amended. The motion to introduce passed 8-1 (Piedmont-Smith).'),
  ];

  it('skips the first reading, the postponement and the two motions to introduce; compares the real vote', () => {
    const cmp = compareWithInventory([], inv, roster, names());
    expect(cmp.skipped.map((s) => s.id.split(':').slice(2).join(':'))).toEqual([
      '2026-05-06:Ord 2026-08', '2026-05-06:Ord 2026-07', '2026-02-18:Ord 2026-06', '2026-06-03:Res 2026-09',
    ]);
    expect(cmp.skipped.every((s) => /not a vote on the item/.test(s.reason))).toBe(true);
    expect(cmp.items.map((i) => [i.subject, i.status])).toEqual([['2026-09-02 Ord 2026-18 Final passage', 'inventory only']]);
  });
});

describe('inventory corrections (corrections.json)', () => {
  const ev = { url: 'https://bloomington.in.gov/onboard/meetingFiles/1/download', quote: 'received a roll call vote of Ayes: 8' };
  const row = (id: string, date: string, members: { name: string; vote: string }[] = []): InventoryItem =>
    ({ id, date, item_no: id.split(':')[3], members });
  const inv = [
    row('place:1805860:2023-04-10:App Ord 23-03', '2023-04-10'),
    row('place:1805860:2024-01-17:Res 2024-01', '2024-01-17'),
    row('place:1805860:2024-02-14:Res 2024-01', '2024-02-14'),
    row('place:1805860:2024-04-10:Res 2024-10', '2024-04-10', [{ name: 'Flaherty', vote: 'abstain' }, { name: 'Asare', vote: 'yes' }]),
  ];
  const file = (corrections: object[]) => ({ corrections: corrections.map((c) => ({ evidence: ev, added: '2026-11-26', ...c })) });

  it('moves a date, drops a duplicate and sets a member vote, without changing the input', () => {
    const before = JSON.stringify(inv);
    const r = applyCorrections(inv, file([
      { row: 'place:1805860:2023-04-10:App Ord 23-03', kind: 'date', corrected: { date: '2023-04-04' } },
      { row: 'place:1805860:2024-02-14:Res 2024-01', kind: 'duplicate_of', corrected: { keep: 'place:1805860:2024-01-17:Res 2024-01' } },
      { row: 'place:1805860:2024-04-10:Res 2024-10', kind: 'member_vote', corrected: { member: 'Flaherty', vote: 'no' } },
    ]));
    expect(r.inventory.map((i) => i.id)).toEqual([
      'place:1805860:2023-04-04:App Ord 23-03', 'place:1805860:2024-01-17:Res 2024-01', 'place:1805860:2024-04-10:Res 2024-10',
    ]);
    expect(r.inventory[0].date).toBe('2023-04-04');
    expect(r.inventory[2].members).toEqual([{ name: 'Flaherty', vote: 'no' }, { name: 'Asare', vote: 'yes' }]);
    expect(r.applied).toHaveLength(3);
    expect(JSON.stringify(inv)).toBe(before);
  });

  it('rejects a row id that is not in the inventory', () => {
    expect(() => applyCorrections(inv, file([{ row: 'place:1805860:2099-01-01:Res 99-01', kind: 'date', corrected: { date: '2099-01-02' } }])))
      .toThrow(/place:1805860:2099-01-01:Res 99-01 is not in the inventory/);
  });

  it('rejects a kept row that is missing, a member not on the row, a moved date that collides, an unknown kind, or missing evidence', () => {
    const bad: object[] = [
      { row: 'place:1805860:2024-02-14:Res 2024-01', kind: 'duplicate_of', corrected: { keep: 'place:1805860:2024-01-18:Res 2024-01' } },
      { row: 'place:1805860:2024-04-10:Res 2024-10', kind: 'member_vote', corrected: { member: 'Rollo', vote: 'no' } },
      { row: 'place:1805860:2024-02-14:Res 2024-01', kind: 'date', corrected: { date: '2024-01-17' } },
      { row: 'place:1805860:2024-02-14:Res 2024-01', kind: 'rename', corrected: {} },
    ];
    for (const c of bad) expect(() => applyCorrections(inv, file([c]))).toThrow();
    expect(() => applyCorrections(inv, { corrections: [{ row: inv[0].id, kind: 'date', corrected: { date: '2023-04-04' }, added: '2026-11-26' }] }))
      .toThrow(/evidence/);
  });
});

describe('runFirstLoad: corrections.json', () => {
  const correction = {
    row: 'place:1805860:2026-10-07:Ord 2026-28', kind: 'member_vote', corrected: { member: 'Asare', vote: 'no' },
    evidence: { url: 'https://bloomington.in.gov/onboard/meetingFiles/1/download', quote: 'Nays: 1 (Asare)' }, added: '2026-11-26',
  };

  it('applies the corrections before comparing and lists each one, with its evidence, in compare.md', async () => {
    const s = setup({ inventory: invFull });
    writeFileSync(path.join(s.inventory, 'corrections.json'), JSON.stringify({ corrections: [correction] }));
    await runFirstLoad(base(s, { seed: 7 }), deps());
    const compare = readFileSync(path.join(s.out, 'compare.md'), 'utf8');
    expect(compare).toContain('## Corrections applied from corrections.json (1)');
    expect(compare).toContain('place:1805860:2026-10-07:Ord 2026-28: member_vote Asare → no');
    expect(compare).toContain('https://bloomington.in.gov/onboard/meetingFiles/1/download');
    expect(compare).toContain('"Nays: 1 (Asare)"');
    expect(compare).toMatch(/2026-10-07 Ord 2026-28 Final passage: differs \(Asare: inventory no, reader yes\)/);
  });

  it('stops with a clear error when a row id is not in the inventory', async () => {
    const s = setup({ inventory: invFull });
    writeFileSync(path.join(s.inventory, 'corrections.json'), JSON.stringify({ corrections: [{ ...correction, row: 'place:1805860:2099-01-01:Res 99-01' }] }));
    await expect(runFirstLoad(base(s, { seed: 7 }), deps())).rejects.toThrow(/corrections\.json: place:1805860:2099-01-01:Res 99-01 is not in the inventory/);
  });

  it('without the file, compare.md has no corrections section', async () => {
    const s = setup({ inventory: invFull });
    await runFirstLoad(base(s, { seed: 7 }), deps());
    expect(readFileSync(path.join(s.out, 'compare.md'), 'utf8')).not.toContain('Corrections applied');
  });
});

// ---- owner checks (owner-checks.json) ------------------------------------------------------------------------------

describe('owner checks', () => {
  const OD = 'https://bloomington.in.gov/onboard/meetingFiles/9378/download';
  const ids = {
    Asare: 'p-asare', Daily: 'p-daily', Flaherty: 'p-flaherty', 'Piedmont-Smith': 'p-piedmont-smith', Rollo: 'p-rollo',
    Rosenbarger: 'p-rosenbarger', Ruff: 'p-ruff', Stosberg: 'p-stosberg', Zulich: 'p-zulich',
  };
  const mem = (votes: Record<string, string>, derived = true) =>
    Object.entries(votes).map(([name, vote]) => ({ name, vote, ...(derived ? { derived: true } : {}) }));
  const SEVEN_YES = { Asare: 'yes', Daily: 'yes', Flaherty: 'yes', 'Piedmont-Smith': 'yes', Ruff: 'yes', Stosberg: 'yes', Zulich: 'yes', Rollo: 'absent', Rosenbarger: 'absent' };
  const invRow = (item: string, over: Partial<InventoryItem> & { tally?: string | null } = {}): InventoryItem =>
    ({ id: `${SCOPE}:${DATE}:${item}`, date: DATE, item_no: item, tally: '7-0', members: mem(SEVEN_YES), ...over } as InventoryItem);
  const chk = (item: string, over: Partial<OwnerCheck> = {}): OwnerCheck => ({
    inventoryId: `${SCOPE}:${DATE}:${item}`, date: DATE, item, tally: '7-0', cause: 'unparsed_roll_call', ownerAnswer: 'yes', ownerNote: '',
    answeredAt: '2026-11-27T01:46:14.308Z', documents: [OD], ...over,
  });
  const feedItem = (itemNumber: string, outcome: 'passed' | 'failed' | 'vetoed' | null, date = DATE): FeedItem => ({
    feedId: 1, type: 'Ordinance', number: '2026-90', itemNumber, title: 't', synopsis: null, status: 's', pageUrl: 'p',
    final: outcome ? { date, outcome, tally: null } : null,
  });
  const run = (rows: InventoryItem[], checks: OwnerCheck[], reader: ReaderRollCall[] = [], items: FeedItem[] = []) => {
    const cmp = compareWithInventory(reader, rows, roster, names());
    return { cmp, res: applyOwnerChecks(cmp, validateOwnerChecks(rows, { checks }), roster, names(), items, rows, reader) };
  };

  it('verdict: matches follow-up or a plain yes confirms; feed_only, no and unsure hold', () => {
    const rows = ['Ord 2026-90', 'Ord 2026-91', 'Ord 2026-92', 'Ord 2026-93'].map((i) => invRow(i));
    const checks = [
      chk('Ord 2026-90'),
      chk('Ord 2026-91', { ownerAnswer: 'no', followUp: { result: 'matches', why: 'w', quote: 'q' } }),
      chk('Ord 2026-92', { followUp: { result: 'feed_only', why: 'w' } }),
      chk('Ord 2026-93', { ownerAnswer: 'unsure' }),
    ];
    const v = validateOwnerChecks(rows, { checks });
    expect(v.map((c) => c.verdict)).toEqual(['confirmed', 'confirmed', 'held', 'held']);
  });

  it('rejects an unknown inventory id, a bad answer, and a repeated id', () => {
    const rows = [invRow('Ord 2026-90')];
    expect(() => validateOwnerChecks(rows, { checks: [chk('Ord 2026-77')] })).toThrow(/owner-checks\.json: .*Ord 2026-77 is not in the inventory/);
    expect(() => validateOwnerChecks(rows, { checks: [chk('Ord 2026-90', { ownerAnswer: 'maybe' as any })] })).toThrow(/owner-checks\.json: .*answer/);
    expect(() => validateOwnerChecks(rows, { checks: [chk('Ord 2026-90'), chk('Ord 2026-90')] })).toThrow(/owner-checks\.json: .*twice/);
  });

  it('a confirmed check on an inventory-only row becomes an owner-checked roll call and its exception goes', () => {
    const { cmp, res } = run([invRow('Ord 2026-90')], [chk('Ord 2026-90')]);
    expect(cmp.exceptions).toHaveLength(1);
    expect(res.exceptions).toEqual([]);
    expect(res.ownerChecked).toHaveLength(1);
    const o = res.ownerChecked[0];
    expect(o).toMatchObject({
      date: DATE, itemNumber: 'Ord 2026-90', question: 'Final passage', outcome: 'passed',
      tally: { yes: 7, no: 0, abstain: 0 }, documentUrl: OD,
      sentence: `Checked by the owner on 2026-11-27 against ${OD}`,
    });
    const asare = o.votes.find((v) => v.politicianId === 'p-asare')!;
    expect(asare).toMatchObject({ position: 'yea', nameAsPrinted: 'Asare', workedOut: true });
    expect(o.votes.find((v) => v.politicianId === 'p-rollo')).toMatchObject({ position: 'absent' });
    expect(cmp.readerOnly).toEqual([]);
  });

  it('maps no, abstain and absent, and uses followUp.quote as the sentence; workedOut false when not derived', () => {
    const row = invRow('Ord 2026-90', {
      tally: '4-3', members: mem({ Asare: 'yes', Daily: 'yes', Flaherty: 'yes', 'Piedmont-Smith': 'yes', Ruff: 'no', Stosberg: 'no', Zulich: 'no', Rollo: 'abstain', Rosenbarger: 'absent' }, false),
    });
    const { res } = run([row], [chk('Ord 2026-90', { tally: '4-3', followUp: { result: 'matches', why: 'w', quote: 'Ayes: 4, Nays: 3' } })]);
    // 4 yes is not >= 5 and not < 3 no: outcome cannot be decided without the feed
    expect(res.ownerChecked).toEqual([]);
    expect(res.exceptions[0].detail).toMatchObject({ inventoryId: row.id });
    expect(JSON.stringify(res.exceptions[0].detail)).toMatch(/outcome/);
    const six = invRow('Ord 2026-91', {
      tally: '6-2', members: mem({ Asare: 'yes', Daily: 'yes', Flaherty: 'yes', 'Piedmont-Smith': 'yes', Ruff: 'yes', Stosberg: 'yes', Zulich: 'no', Rollo: 'no', Rosenbarger: 'absent' }, false),
    });
    const ok = run([six], [chk('Ord 2026-91', { tally: '6-2', followUp: { result: 'matches', why: 'w', quote: 'Ayes: 6, Nays: 2' } })]).res;
    const o = ok.ownerChecked[0];
    expect(o.sentence).toBe('Ayes: 6, Nays: 2');
    expect(o.tally).toEqual({ yes: 6, no: 2, abstain: 0 });
    expect(o.votes.every((v) => v.workedOut === false)).toBe(true);
    expect(o.votes.find((v) => v.politicianId === 'p-zulich')!.position).toBe('nay');
  });

  it('counts abstain from present votes', () => {
    const row = invRow('Ord 2026-90', { tally: '6-0', members: mem({ Asare: 'yes', Daily: 'yes', Flaherty: 'yes', 'Piedmont-Smith': 'yes', Ruff: 'yes', Stosberg: 'yes', Zulich: 'abstain', Rollo: 'absent', Rosenbarger: 'absent' }) });
    const o = run([row], [chk('Ord 2026-90', { tally: '6-0' })]).res.ownerChecked[0];
    expect(o.tally).toEqual({ yes: 6, no: 0, abstain: 1 });
    expect(o.votes.find((v) => v.politicianId === 'p-zulich')!.position).toBe('present');
  });

  it.each([
    ['printed tally disagrees with the counted votes', { tally: '8-0' }, /tally/],
    ['a member does not resolve to an id', { members: mem({ ...SEVEN_YES, Nobody: 'yes' }) }, /Nobody/],
    ['the inventory prints no tally', { tally: null }, /tally/],
  ])('not confirmed (blocking exception with the reason) when %s', (_why, over, re) => {
    const { res } = run([invRow('Ord 2026-90', over as any)], [chk('Ord 2026-90')]);
    expect(res.ownerChecked).toEqual([]);
    expect(res.exceptions).toHaveLength(1);
    expect(res.exceptions[0].cause).toBe('inventory_disagrees');
    const d = res.exceptions[0].detail as any;
    expect(d.ownerHeld).toBeUndefined();
    expect(String(d.ownerCheckFailed)).toMatch(re);
    expect(res.failed).toHaveLength(1);
  });

  it('outcome: the feed Final outcome wins; no feed Final uses yes>=5 and yes>no, or yes<no; else not confirmed', () => {
    const passedFeed = run([invRow('Ord 2026-90')], [chk('Ord 2026-90')], [], [feedItem('Ord 2026-90', 'passed')]).res;
    expect(passedFeed.ownerChecked[0].outcome).toBe('passed');
    const failTally = invRow('Ord 2026-91', { tally: '2-5', members: mem({ Asare: 'yes', Daily: 'yes', Flaherty: 'no', 'Piedmont-Smith': 'no', Ruff: 'no', Stosberg: 'no', Zulich: 'no', Rollo: 'absent', Rosenbarger: 'absent' }) });
    const failed = run([failTally], [chk('Ord 2026-91', { tally: '2-5' })]).res;
    expect(failed.ownerChecked[0].outcome).toBe('failed');
    const vetoed = run([invRow('Ord 2026-90')], [chk('Ord 2026-90')], [], [feedItem('Ord 2026-90', 'vetoed')]).res;
    expect(vetoed.ownerChecked).toEqual([]);
    // feed says failed but the votes pass: conflict, not confirmed
    const conflict = run([invRow('Ord 2026-90')], [chk('Ord 2026-90')], [], [feedItem('Ord 2026-90', 'failed')]).res;
    expect(conflict.ownerChecked).toEqual([]);
    // a feed Final on another date does not decide this vote; the tally rule does
    const other = run([invRow('Ord 2026-90')], [chk('Ord 2026-90')], [], [feedItem('Ord 2026-90', 'failed', '2026-10-21')]).res;
    expect(other.ownerChecked[0].outcome).toBe('passed');
  });

  it('a tie is failed, and a row with no members is held, not failed', () => {
    const tie = invRow('Ord 2026-90', { tally: '4-4', members: mem({ Asare: 'yes', Daily: 'yes', Flaherty: 'yes', 'Piedmont-Smith': 'yes', Ruff: 'no', Stosberg: 'no', Zulich: 'no', Rollo: 'no', Rosenbarger: 'absent' }) });
    expect(run([tie], [chk('Ord 2026-90', { tally: '4-4' })]).res.ownerChecked[0].outcome).toBe('failed');
    const { res } = run([invRow('Ord 2026-91', { members: [] })], [chk('Ord 2026-91')]);
    expect(res.ownerChecked).toEqual([]);
    expect(res.failed).toEqual([]);
    expect(res.held).toHaveLength(1);
    expect(res.exceptions[0].detail).toMatchObject({ ownerHeld: true, reason: 'the inventory lists no member votes, so there is nothing to load' });
  });

  describe('I1: keys the reader failed on purpose, and an item passes once', () => {
    const failedRc = (over: Partial<ReaderRollCall>) => rr({ itemNumber: 'Ord 2026-90', status: 'failed', ...over });
    const row = invRow('Ord 2026-90');
    it('a repeated Final (outcome_conflict) is held with the reader\'s own detail', () => {
      const detail = 'Ord 2026-90 already passed on 2026-09-01; a later "adopt" is not a second Final passage';
      const { res } = run([row], [chk('Ord 2026-90')], [failedRc({ cause: 'outcome_conflict', detail })]);
      expect(res.ownerChecked).toEqual([]);
      expect(res.failed).toEqual([]);
      expect(res.held).toEqual([{ subject: `${DATE} Ord 2026-90 Final passage`, reason: detail }]);
      expect(res.exceptions[0].detail).toMatchObject({ ownerHeld: true, reason: detail });
    });
    it('a duplicate key is held with the reader\'s own detail', () => {
      const detail = '2 roll calls in the vote document share this date, item and question';
      const { res } = run([row], [chk('Ord 2026-90')], [failedRc({ cause: 'unparsed_roll_call', detail })]);
      expect(res.ownerChecked).toEqual([]);
      expect(res.held[0].reason).toBe(detail);
    });
    it('other reader-failed causes still take the owner check', () => {
      const { res } = run([row], [chk('Ord 2026-90')], [failedRc({ cause: 'tally_mismatch', detail: 'x' })]);
      expect(res.ownerChecked).toHaveLength(1);
    });
    it('an owner Final passed is held when the item already passed on another date (reader-confirmed)', () => {
      const earlier = rr({ itemNumber: 'Ord 2026-90', date: '2026-09-01', outcome: 'passed' });
      const { res } = run([row], [chk('Ord 2026-90')], [earlier]);
      expect(res.ownerChecked).toEqual([]);
      expect(res.held[0].reason).toMatch(/already passed on 2026-09-01/);
    });
    it('between two owner rows the later date is held, the earlier confirmed', () => {
      const early = invRow('Ord 2026-90', { id: `${SCOPE}:2026-09-01:Ord 2026-90`, date: '2026-09-01' });
      const { res } = run([early, row], [chk('Ord 2026-90', { inventoryId: early.id, date: '2026-09-01' }), chk('Ord 2026-90')]);
      expect(res.ownerChecked.map((o) => o.date)).toEqual(['2026-09-01']);
      expect(res.held).toHaveLength(1);
      expect(res.held[0].reason).toMatch(/already passed on 2026-09-01/);
      expect(res.exceptions).toHaveLength(1);
    });
    it('a failed owner Final or an amendment does not count as a second passage', () => {
      const earlier = rr({ itemNumber: 'Ord 2026-90', date: '2026-09-01', outcome: 'passed' });
      const am = invRow('Ord 2026-90 (amendment 1)');
      expect(run([am], [chk('Ord 2026-90 (amendment 1)')], [earlier]).res.ownerChecked).toHaveLength(1);
    });
  });

  it('an amendment uses the tally rule only', () => {
    const row = invRow('Ord 2026-90 (amendment 1)');
    const o = run([row], [chk('Ord 2026-90 (amendment 1)')], [], [feedItem('Ord 2026-90', 'failed')]).res.ownerChecked[0];
    expect(o).toMatchObject({ question: 'Amendment 01', outcome: 'passed' });
  });

  it('held checks keep their exception, marked ownerHeld with the reason', () => {
    const rows = [invRow('Ord 2026-90')];
    const { res } = run(rows, [chk('Ord 2026-90', { followUp: { result: 'feed_only', why: 'No minutes posted yet' } })]);
    expect(res.ownerChecked).toEqual([]);
    expect(res.held).toHaveLength(1);
    expect(res.exceptions).toHaveLength(1);
    expect(res.exceptions[0].cause).toBe('inventory_disagrees');
    expect(res.exceptions[0].detail).toMatchObject({ kind: 'inventory only', ownerHeld: true });
    expect(JSON.stringify(res.exceptions[0].detail)).toContain('No minutes posted yet');
  });

  it('a check on a row the reader confirmed is ignored and listed as not needed', () => {
    const row = invFull.items.find((i) => i.id.endsWith('App Ord 2026-03'))!;
    const { res } = run([row], [chk('App Ord 2026-03', { inventoryId: row.id })], [rr()]);
    expect(res.ownerChecked).toEqual([]);
    expect(res.notNeeded).toEqual([row.id]);
    expect(res.exceptions).toEqual([]);
  });

  it('only rows with an owner check change; other exceptions stay as they were', () => {
    const rows = [invRow('Ord 2026-90'), invRow('Ord 2026-91')];
    const { cmp, res } = run(rows, [chk('Ord 2026-90')]);
    expect(res.exceptions).toEqual([cmp.exceptions[1]]);
  });
});

describe('runFirstLoad: owner-checks.json', () => {
  const MEMO_URL = 'https://bloomington.in.gov/onboard/meetingFiles/17565/download';
  const row: InventoryItem = {
    id: `${SCOPE}:${DATE}:Ord 2026-37`, date: DATE, item_no: 'Ord 2026-37', tally: '7-0',
    members: ['Asare', 'Daily', 'Flaherty', 'Piedmont-Smith', 'Ruff', 'Stosberg', 'Zulich'].map((name) => ({ name, vote: 'yes', derived: true }))
      .concat([{ name: 'Rollo', vote: 'absent', derived: true }, { name: 'Rosenbarger', vote: 'absent', derived: true }]),
  } as InventoryItem;
  const check = (over: object = {}) => ({
    inventoryId: row.id, date: DATE, item: 'Ord 2026-37', tally: '7-0', cause: 'unparsed_roll_call', ownerAnswer: 'yes', ownerNote: '',
    answeredAt: '2026-11-27T01:46:14.308Z', documents: [MEMO_URL], ...over,
  });
  const put = (s: { inventory: string }, checks: object[]) => writeFileSync(path.join(s.inventory, 'owner-checks.json'), JSON.stringify({ about: 'x', checked: 'y', checks }));
  const fillAll = (out: string) => {
    const p = path.join(out, 'spotcheck.json');
    const spot = JSON.parse(readFileSync(p, 'utf8'));
    spot.picks.forEach((x: any) => (x.verdict = 'match'));
    writeFileSync(p, JSON.stringify(spot));
    fillSponsorSpot(out);
  };

  it('without the file: no owner-checked.json and no owner lines', async () => {
    const s = setup({ inventory: { items: [row] } });
    await runFirstLoad(base(s, { seed: 7 }), deps());
    expect(existsSync(path.join(s.out, 'owner-checked.json'))).toBe(false);
    expect(readFileSync(path.join(s.out, 'summary.md'), 'utf8')).not.toContain('Owner-checked');
    expect(readFileSync(path.join(s.out, 'compare.md'), 'utf8')).not.toContain('Owner-checked');
  });

  it('stops with a clear error when a check id is not in the inventory', async () => {
    const s = setup({ inventory: { items: [row] } });
    put(s, [check({ inventoryId: `${SCOPE}:${DATE}:Ord 2026-77` })]);
    await expect(runFirstLoad(base(s, { seed: 7 }), deps())).rejects.toThrow(/owner-checks\.json: .*Ord 2026-77 is not in the inventory/);
  });

  it('writes owner-checked.json, reports it, and leaves the spot check and reader output unchanged', async () => {
    const s = setup({ inventory: { items: [row] } });
    await runFirstLoad(base(s, { seed: 7 }), deps());
    const spotBefore = readFileSync(path.join(s.out, 'spotcheck.json'), 'utf8');
    const readerBefore = readFileSync(path.join(s.out, 'reader-output.json'), 'utf8');
    put(s, [check()]);
    await runFirstLoad(base(s, { seed: 7 }), deps());
    expect(readFileSync(path.join(s.out, 'spotcheck.json'), 'utf8')).toBe(spotBefore);
    expect(readFileSync(path.join(s.out, 'reader-output.json'), 'utf8')).toBe(readerBefore);
    const oc = JSON.parse(readFileSync(path.join(s.out, 'owner-checked.json'), 'utf8'));
    expect(oc.ownerChecked).toHaveLength(1);
    expect(oc.ownerChecked[0]).toMatchObject({ itemNumber: 'Ord 2026-37', documentUrl: MEMO_URL });
    expect(readFileSync(path.join(s.out, 'summary.md'), 'utf8')).toContain('Owner-checked: 1 confirmed, 0 held, 0 not needed');
    const compare = readFileSync(path.join(s.out, 'compare.md'), 'utf8');
    expect(compare).toContain('## Owner-checked');
    expect(compare).toContain(`2026-10-07 Ord 2026-37 Final passage`);
    expect(compare).toContain(MEMO_URL);
    const ex = JSON.parse(readFileSync(path.join(s.out, 'exceptions.json'), 'utf8'));
    expect(ex.exceptions.filter((e: any) => e.cause === 'inventory_disagrees')).toEqual([]);
  });

  it('--apply refuses when owner-checked.json is missing or the owner rows changed since the dry run', async () => {
    const s = setup({ inventory: { items: [row] } });
    put(s, [check()]);
    await runFirstLoad(base(s, { seed: 3 }), deps());
    fillAll(s.out);
    const ocPath = path.join(s.out, 'owner-checked.json');
    const saved = readFileSync(ocPath, 'utf8');
    expect(JSON.parse(saved).hash).toMatch(/^[0-9a-f]{64}$/);
    // an answer flips: the owner rows differ from the ones reviewed
    put(s, [check({ ownerAnswer: 'unsure' })]);
    const changed = await runFirstLoad(base(s, { apply: true }), deps());
    expect(changed.refused?.join(' ')).toMatch(/owner-checked rows changed since the dry run: run a dry run again/);
    expect(calls).toEqual([]);
    put(s, [check()]);
    writeFileSync(ocPath, '{}');
    expect((await runFirstLoad(base(s, { apply: true }), deps())).refused?.join(' ')).toMatch(/owner-checked rows changed/);
    unlinkSync(ocPath);
    expect((await runFirstLoad(base(s, { apply: true }), deps())).refused?.join(' ')).toMatch(/owner-checked\.json is missing/);
    writeFileSync(ocPath, saved);
    expect((await runFirstLoad(base(s, { apply: true }), deps())).refused).toBeUndefined();
  });

  it('a held check does not block --apply but is still recorded as an open exception', async () => {
    const s = setup({ inventory: { items: [row] } });
    put(s, [check({ followUp: { result: 'feed_only', why: 'No minutes posted yet' } })]);
    await runFirstLoad(base(s, { seed: 3 }), deps());
    fillAll(s.out);
    const r = await runFirstLoad(base(s, { apply: true }), deps());
    expect(r.refused).toBeUndefined();
    const recorded = calls.filter((c) => /local_record_exceptions/.test(c.text));
    expect(recorded.length).toBeGreaterThan(0);
  });

  it('a check that failed its tally check still blocks --apply', async () => {
    const s = setup({ inventory: { items: [{ ...row, tally: '8-0' } as InventoryItem] } });
    put(s, [check()]);
    await runFirstLoad(base(s, { seed: 3 }), deps());
    fillAll(s.out);
    const r = await runFirstLoad(base(s, { apply: true }), deps());
    expect(r.refused?.join(' ')).toMatch(/inventory_disagrees/);
  });

  it('--apply writes the owner-checked roll call with source owner-check; no bill row is an unknown_item', async () => {
    const s = setup({ inventory: { items: [row] } });
    put(s, [check()]);
    await runFirstLoad(base(s, { seed: 3 }), deps());
    fillAll(s.out);
    const sources: unknown[] = [];
    const d = deps();
    const origQuery = (await d.connect!()).query;
    d.connect = async () => ({
      query: async (text: string, params?: unknown[]) => {
        if (/INTO essentials\.legislative_votes/.test(text)) sources.push(params?.[10]);
        return origQuery(text, params);
      },
      release() {},
    }) as any;
    const r = await runFirstLoad(base(s, { apply: true }), d);
    expect(r.refused).toBeUndefined();
    expect(r.applied?.rollCallsConfirmed).toBeGreaterThanOrEqual(2); // the reader's roll calls + the owner-checked one
    expect(sources).toContain('owner-check');
    expect(sources).toContain('onboard-minutes');

    const none = deps();
    const q = none.connect!;
    none.connect = async () => {
      const c: any = await q();
      return { ...c, query: async (text: string, p?: unknown[]) => (/SELECT id FROM essentials\.legislative_bills/.test(text) ? { rows: [], rowCount: 0 } : c.query(text, p)) };
    };
    const s2 = setup({ inventory: { items: [row] } });
    put(s2, [check()]);
    await runFirstLoad(base(s2, { seed: 3 }), deps());
    fillAll(s2.out);
    const r2 = await runFirstLoad(base(s2, { apply: true }), none);
    expect(r2.applied?.exceptions).toBeGreaterThan(0);
  });
});


// ---- sponsorships ----------------------------------------------------------------------------------------------------
describe('sponsors: inventory control', () => {
  const spons = (itemNumber: string, id: string, printed = 'Asare') => ({
    itemNumber, label: null, politicianId: id, role: 'sponsor' as const, nameAsPrinted: printed, sentence: 's', sourceKind: 'legislation_feed' as const,
    sourceDocumentId: null, sourceUrl: 'https://x/feed',
  });
  const nf = names();
  const inv = (id: string, sponsors: string[], date = '2026-10-07') => ({ id: `${SCOPE}:${date}:${id}`, date, sponsors });

  it('lists an inventory sponsor the reader missed as a blocker', () => {
    const cmp = compareSponsors([], [{ cause: 'sponsor_unresolved', subject: 'Ord 2026-25', detail: {} }], [inv('Ord 2026-25', ['Stosberg'])], roster, nf);
    expect(cmp.diffs).toHaveLength(1);
    expect(cmp.diffs[0]).toMatchObject({ group: 'missed', subject: 'Ord 2026-25', inventory: ['Stosberg'], reader: null, cause: 'sponsor_unresolved' });
    const blockers = sponsorBlockers(cmp);
    expect(blockers).toHaveLength(1);
    expect(blockers[0].cause).toBe('inventory_disagrees');
  });

  it('lists different members, and a reader-only subject without blocking', () => {
    const cmp = compareSponsors(
      [spons('Ord 2026-25', 'p-asare'), spons('Ord 2026-99', 'p-rollo', 'Rollo')], [], [inv('Ord 2026-25', ['Stosberg'])], roster, nf,
    );
    expect(cmp.diffs.map((d) => d.group).sort()).toEqual(['different', 'extra']);
    expect(sponsorBlockers(cmp)).toHaveLength(1);
  });

  it('brings "21-03" and "2021-03" to one form and counts the rows that agree only after that', () => {
    expect(normaliseItemNumber('Ord 21-03')).toBe('Ord 2021-03');
    expect(normaliseItemNumber('App Ord 22-01')).toBe('App Ord 2022-01');
    expect(normaliseItemNumber('Ord 2021-03')).toBe('Ord 2021-03');
    const cmp = compareSponsors([spons('Ord 2021-03', 'p-asare')], [], [inv('Ord 21-03', ['Asare'], '2026-02-17')], roster, nf);
    expect(cmp.diffs).toEqual([]);
    expect(cmp.agree).toBe(1);
    expect(cmp.agreeAfterNormalising).toBe(1);
    // A real difference stays a difference under either form.
    const real = compareSponsors([spons('Ord 2021-03', 'p-rollo', 'Rollo')], [], [inv('Ord 21-03', ['Asare'], '2026-02-17')], roster, nf);
    expect(real.diffs).toHaveLength(1);
    expect(real.diffs[0]).toMatchObject({ group: 'different', formDiffers: true });
    // Before the window: not compared.
    const early = compareSponsors([], [], [inv('Ord 20-30', ['Volan'], '2020-11-01')], roster, nf);
    expect(early.skippedBeforeWindow).toBe(1);
  });

  it('maps inventory ids to subjects, and says why a row has none', () => {
    expect(inventorySponsorSubjects(`${SCOPE}:2026-10-07:Ord 2026-25 (amendment 1)`)).toEqual({ subjects: ['Ord 2026-25 / Amendment 01'] });
    expect(inventorySponsorSubjects(`${SCOPE}:2026-04-22:Ord 2026-06 (reasonable conditions 8, 9, 10 and 12)`)).toEqual({
      subjects: ['Reasonable Condition 8', '9', '10', '12'].map((n) => `Ord 2026-06 / ${n.startsWith('R') ? n : `Reasonable Condition ${n}`}`),
    });
    expect(inventorySponsorSubjects(`${SCOPE}:2026-09-16:Ord 2026-20 (amendment 4, paragraph 4)`)).toHaveProperty('unmappable');
  });

  it('an owner sponsor check lets one difference through, and never touches vote checks', () => {
    const cmp = compareSponsors([], [], [inv('Ord 2026-25', ['Stosberg'])], roster, nf);
    const checks = [{
      about: 'sponsors' as const, inventoryId: `${SCOPE}:2026-10-07:Ord 2026-25`, date: '2026-10-07', item: 'Ord 2026-25', tally: '', cause: '',
      ownerAnswer: 'yes' as const, ownerNote: 'checked by eye', answeredAt: '2026-11-27T00:00:00Z', documents: [], verdict: 'confirmed' as const,
    }];
    const r = applySponsorOwnerChecks(sponsorBlockers(cmp), checks);
    expect(r.passed).toBe(1);
    expect((r.exceptions[0].detail as any).ownerHeld).toBe(true);
  });

  it('draws the same 30 spot-check picks for the same seed', () => {
    const pool: SponsorRowOut[] = Array.from({ length: 80 }, (_, i) => ({
      subject: `Ord 2026-${String(i).padStart(2, '0')}`, itemNumber: `Ord 2026-${i}`, label: null, politicianId: 'p-asare', role: 'sponsor', nameAsPrinted: 'Asare',
      sentence: `s${i}`, sourceKind: 'legislation_feed', documentUrl: 'https://x/feed',
    }));
    const a = drawSponsorSpotCheck(pool, 20261127);
    const b = drawSponsorSpotCheck([...pool].reverse(), 20261127);
    expect(a).toHaveLength(30);
    expect(b).toEqual(a);
    expect(drawSponsorSpotCheck(pool, 1)).not.toEqual(a);
  });
});

describe('runFirstLoad: sponsors', () => {
  const sp = (out: string, f: string) => JSON.parse(readFileSync(path.join(out, f), 'utf8'));

  it('a dry run writes the three sponsor files, picks carry a document URL, and the summary has the sponsor line', async () => {
    const s = setup();
    await runFirstLoad(base(s, { seed: 3, sponsorSeed: 11 }), deps());
    const rows = sp(s.out, 'sponsorships.json');
    expect(rows.hash).toMatch(/^[0-9a-f]{64}$/);
    expect(rows.sponsorships.length).toBeGreaterThan(0);
    const spot = sp(s.out, 'sponsor-spotcheck.json');
    expect(spot.seed).toBe(11);
    expect(spot.picks.length).toBeGreaterThan(0);
    for (const p of spot.picks) {
      expect(Object.keys(p).sort()).toEqual(['documentUrl', 'member', 'role', 'sentence', 'subject', 'verdict']);
      expect(p.documentUrl).toMatch(/^https:/);
      expect(p.verdict).toBe('');
    }
    expect(existsSync(path.join(s.out, 'sponsor-compare.md'))).toBe(true);
    expect(readFileSync(path.join(s.out, 'summary.md'), 'utf8')).toMatch(/Sponsorships: \d+ would be written .*held .*inventory differences/);
  });

  it('refuses --apply while a sponsor spot-check verdict is blank', async () => {
    const s = setup();
    await runFirstLoad(base(s, { seed: 3 }), deps());
    const fillAll = (out: string) => {
      const p = path.join(out, 'spotcheck.json');
      const spot = JSON.parse(readFileSync(p, 'utf8'));
      spot.picks.forEach((x: any) => (x.verdict = 'match'));
      writeFileSync(p, JSON.stringify(spot));
    };
    fillAll(s.out);
    const spot = fillSponsorSpot(s.out);
    spot.picks[0].verdict = '';
    writeFileSync(path.join(s.out, 'sponsor-spotcheck.json'), JSON.stringify(spot));
    const r = await runFirstLoad(base(s, { apply: true }), deps());
    expect(r.refused?.join(' ')).toMatch(/sponsor spot-check verdict\(s\) are blank/);
    expect(calls).toEqual([]);
  });

  it('refuses --apply when sponsorships.json changed after the dry run', async () => {
    const s = setup();
    await runFirstLoad(base(s, { seed: 3 }), deps());
    const p = path.join(s.out, 'spotcheck.json');
    const spot = JSON.parse(readFileSync(p, 'utf8'));
    spot.picks.forEach((x: any) => (x.verdict = 'match'));
    writeFileSync(p, JSON.stringify(spot));
    fillSponsorSpot(s.out);
    const f = path.join(s.out, 'sponsorships.json');
    const j = JSON.parse(readFileSync(f, 'utf8'));
    j.hash = '0'.repeat(64);
    writeFileSync(f, JSON.stringify(j));
    const r = await runFirstLoad(base(s, { apply: true }), deps());
    expect(r.refused?.join(' ')).toMatch(/sponsorships\.json changed since the dry run/);
    expect(calls).toEqual([]);
  });

  it('lists an inventory sponsor the reader missed in sponsor-compare.md and refuses --apply', async () => {
    const s = setup();
    const full = JSON.parse(readFileSync(path.join(s.inventory, 'full.json'), 'utf8'));
    full.items.push({ id: `${SCOPE}:${DATE}:Ord 2026-777`, date: DATE, item_no: 'Ord 2026-777', sponsors: ['Zulich'] });
    writeFileSync(path.join(s.inventory, 'full.json'), JSON.stringify(full));
    await runFirstLoad(base(s, { seed: 3 }), deps());
    expect(readFileSync(path.join(s.out, 'sponsor-compare.md'), 'utf8')).toMatch(/Missed by the reader \(1\)[\s\S]*Ord 2026-777.*inventory Zulich; reader not read/);
    const p = path.join(s.out, 'spotcheck.json');
    const spot = JSON.parse(readFileSync(p, 'utf8'));
    spot.picks.forEach((x: any) => (x.verdict = 'match'));
    writeFileSync(p, JSON.stringify(spot));
    fillSponsorSpot(s.out);
    const r = await runFirstLoad(base(s, { apply: true }), deps());
    expect(r.refused?.join(' ')).toMatch(/inventory_disagrees/);
  });

  /** A db stub that keeps every parameter list, to look at what the sponsor writes carry. */
  const capturingDeps = (inserts: any[][], exceptions: any[][]) => {
    const d = deps();
    const db = {
      async query(text: string, params?: any[]) {
        calls.push({ text });
        if (/INTO essentials\.legislative_sponsorships/.test(text)) inserts.push(params as any[]);
        if (/local_record_exceptions/.test(text) && /INSERT/.test(text)) exceptions.push(params as any[]);
        const rows = /SELECT id FROM essentials\.legislative_bills/.test(text) ? [{ id: 'bill1' }]
          : /SELECT id, superseded_by/.test(text) ? [] : /legislative_sponsorships/.test(text) ? [] : [{ id: 'row1' }];
        return { rows, rowCount: rows.length };
      },
      release() {},
    };
    return { ...d, connect: async () => db as any };
  };
  const clearGates = (out: string) => {
    const p = path.join(out, 'spotcheck.json');
    const spot = JSON.parse(readFileSync(p, 'utf8'));
    spot.picks.forEach((x: any) => (x.verdict = 'match'));
    writeFileSync(p, JSON.stringify(spot));
    fillSponsorSpot(out);
  };

  it('--apply ties every feed-read and document-read sponsor to a saved document (none written without one)', async () => {
    const s = setup();
    await runFirstLoad(base(s, { seed: 3 }), deps());
    clearGates(s.out);
    const inserts: any[][] = []; const exceptions: any[][] = [];
    const r = await runFirstLoad(base(s, { apply: true }), capturingDeps(inserts, exceptions));
    expect(r.refused).toBeUndefined();
    const resolved = sp(s.out, 'sponsorships.json').sponsorships;
    expect(resolved.some((x: any) => x.sourceKind === 'legislation_feed')).toBe(true);
    expect(inserts.length).toBe(resolved.length);
    expect(inserts.some((p) => p[7] === 'legislation_feed')).toBe(true);
    expect(inserts.every((p) => typeof p[8] === 'string' && p[8].length > 0)).toBe(true);
    expect(exceptions.some((p) => JSON.stringify(p).includes('no_document'))).toBe(false);
    expect(r.applied?.sponsorshipsWritten).toBe(resolved.length);
  });

  it('--apply with one about:"sponsors" owner check on the only difference: not refused, rows written equal the resolved rows', async () => {
    const s = setup();
    const full = JSON.parse(readFileSync(path.join(s.inventory, 'full.json'), 'utf8'));
    const id = `${SCOPE}:${DATE}:Ord 2026-777`;
    full.items.push({ id, date: DATE, item_no: 'Ord 2026-777', instrument: 'motion', sponsors: ['Zulich'] });
    writeFileSync(path.join(s.inventory, 'full.json'), JSON.stringify(full));
    writeFileSync(path.join(s.inventory, 'owner-checks.json'), JSON.stringify({ checks: [{
      about: 'sponsors', inventoryId: id, date: DATE, item: 'Ord 2026-777', tally: '', cause: 'inventory_disagrees', ownerAnswer: 'no',
      ownerNote: 'looked: no sponsor printed', answeredAt: '2026-11-27T00:00:00Z', documents: [],
    }] }));
    await runFirstLoad(base(s, { seed: 3 }), deps());
    const ex = sp(s.out, 'exceptions.json').exceptions.filter((e: any) => e.cause === 'inventory_disagrees');
    expect(ex.filter((e: any) => !/^sponsors/.test(e.detail.kind))).toEqual([]);
    expect(ex).toHaveLength(1);
    expect(ex[0].detail).toMatchObject({ ownerHeld: true, ownerAnswer: 'no', ownerNote: 'looked: no sponsor printed' });
    expect(ex[0].detail.reason).toContain('answer "no"');
    clearGates(s.out);
    const inserts: any[][] = []; const exceptions: any[][] = [];
    const r = await runFirstLoad(base(s, { apply: true }), capturingDeps(inserts, exceptions));
    expect(r.refused).toBeUndefined();
    expect(inserts.length).toBe(sp(s.out, 'sponsorships.json').sponsorships.length);
    expect(r.applied?.sponsorshipsWritten).toBe(inserts.length);
  });

  it('refuses (instead of throwing) when a sponsor spot-check verdict key was deleted', async () => {
    const s = setup();
    await runFirstLoad(base(s, { seed: 3 }), deps());
    clearGates(s.out);
    const f = path.join(s.out, 'sponsor-spotcheck.json');
    const spot = JSON.parse(readFileSync(f, 'utf8'));
    delete spot.picks[0].verdict;
    writeFileSync(f, JSON.stringify(spot));
    const r = await runFirstLoad(base(s, { apply: true }), deps());
    expect(r.refused?.join(' ')).toMatch(/blank/);
  });

  it('writes the sponsorships after the votes when every gate is clear', async () => {
    const s = setup();
    await runFirstLoad(base(s, { seed: 3 }), deps());
    const p = path.join(s.out, 'spotcheck.json');
    const spot = JSON.parse(readFileSync(p, 'utf8'));
    spot.picks.forEach((x: any) => (x.verdict = 'match'));
    writeFileSync(p, JSON.stringify(spot));
    fillSponsorSpot(s.out);
    const r = await runFirstLoad(base(s, { apply: true }), deps());
    expect(r.refused).toBeUndefined();
    const sql = calls.map((c) => c.text);
    const lastVote = sql.map((t, i) => (/INTO essentials\.legislative_votes/.test(t) ? i : -1)).filter((i) => i >= 0).pop() ?? -1;
    const firstSponsor = sql.findIndex((t) => /legislative_bills WHERE jurisdiction = \$1 AND number = \$2/.test(t));
    expect(lastVote).toBeGreaterThan(-1);
    expect(firstSponsor).toBeGreaterThan(lastVote);
  });
});
