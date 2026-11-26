import { mkdirSync, mkdtempSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import type { NameFile } from '../../src/lib/localRecord/names.js';
import type { CityConfig } from '../../src/lib/localRecord/refresh.js';
import {
  compareWithInventory, drawSpotCheck, flagDuplicates, idForSurname, parseInventoryId, runFirstLoad, withDownloadCache, type FirstLoadDeps,
  type InventoryItem, type ReaderRollCall,
} from './first-load.js';

const fx = (f: string) => new URL(`./__fixtures__/${f}`, import.meta.url);
const ofx = (f: string) => new URL(`../../src/lib/localRecord/onboard/__fixtures__/${f}`, import.meta.url);
const invFull: { items: InventoryItem[] } = JSON.parse(readFileSync(fx('inventory-full.json'), 'utf8'));
const invDeep: { items: InventoryItem[] } = JSON.parse(readFileSync(fx('inventory-deep.json'), 'utf8'));
const roster = JSON.parse(readFileSync(fx('inventory-roster.json'), 'utf8'));
const legislation = JSON.parse(readFileSync(ofx('legislation-2026.json'), 'utf8'));
const meetings = JSON.parse(readFileSync(ofx('meetings-2026.json'), 'utf8'));
const memoPdf = new Uint8Array(readFileSync(ofx('minutes/2026-10-07.pdf')));
const memoText = readFileSync(ofx('minutes/2026-10-07.txt'), 'utf8');

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
