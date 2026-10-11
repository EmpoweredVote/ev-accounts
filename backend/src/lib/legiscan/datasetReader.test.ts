/**
 * datasetReader.test.ts — the reader must never materialise a whole session at once, and the
 * INDEX PASS must not materialise one entry at a time either.
 *
 * 🔴 WHY THIS EXISTS, AND WHY IT GREW A SECOND TIME.
 *
 * 2026-10-11 14:01 — the weekly cron died with `Reached heap limit` at ~254 MB. The old
 * `downloadDataset` parsed every bill and roll call of a session into two Maps and RETAINED
 * them. PR #989 made reads lazy, and the control below ("reads ONLY the bills asked for")
 * pinned that.
 *
 * 2026-10-11 19:45 — with `--max-old-space-size=400` it died AGAIN, at 365 MB, with
 * `Ineffective mark-compacts near heap limit`. The bisect logging showed it reached
 * `zip decoded, 27.5 MiB` and never reached `indexed`: it was dying in the INDEX PASS, which
 * PR #989 itself had written.
 *
 * ▶ REMOVING RETENTION WAS NOT ENOUGH. The index pass still inflated every entry, turned it
 * into a string and `JSON.parse`d it — to read ONE INTEGER. 27.5 MiB compressed is ~250-300 MB
 * inflated, and allocating that back to back in a synchronous loop exhausts the heap whether or
 * not anything is kept.
 *
 * 🔴 THE FIRST CONTROL COULD NOT HAVE CAUGHT THIS. It asserted that a repeat read re-parses —
 * a fact about RETENTION. The defect was in ALLOCATION, on the first read, and no test looked
 * at it. The control that closes that gap is `indexStats.bytesScanned`, which must stay
 * proportional to the NUMBER of entries and never to their SIZE.
 *
 * ⚠ WHAT THESE TESTS STILL CANNOT PROVE: that the job fits in 512 MiB. Only a real California
 * run shows that. Two fixes have now looked right here and failed in production.
 */
import { describe, it, expect, vi } from 'vitest';
import AdmZip from 'adm-zip';

const queryMock = vi.hoisted(() => vi.fn(async () => ({ rows: [] })));
vi.mock('../db.js', () => ({ pool: { query: queryMock } }));
vi.mock('./client.js', () => ({ legiscanQuery: vi.fn() }));

import { readDatasetZip, INDEX_PREFIX_BYTES } from './importer.js';

/** A dataset shaped like LegiScan's: `<session>/bill/*.json`, `<session>/vote/*.json`. */
function buildZip(bills: number[], rollCalls: number[], padBytes = 0): Buffer {
  const zip = new AdmZip();
  for (const id of bills) {
    zip.addFile(
      `CA/2025-2026/bill/${id}.json`,
      Buffer.from(JSON.stringify({
        bill: {
          bill_id: id,
          bill_number: `AB${id}`,
          title: `Bill ${id}`,
          status: 1,
          votes: rollCalls.length ? [{ roll_call_id: rollCalls[0] }] : [],
          // Stands in for the body LegiScan actually ships: history, sponsors, texts.
          padding: 'x'.repeat(padBytes),
        },
      })),
    );
  }
  for (const id of rollCalls) {
    zip.addFile(
      `CA/2025-2026/vote/${id}.json`,
      Buffer.from(JSON.stringify({
        roll_call: { roll_call_id: id, desc: 'Third reading', passed: 1, yea: 40, nay: 10, votes: [] },
      })),
    );
  }
  return zip.toBuffer();
}

describe('readDatasetZip', () => {
  it('indexes every bill and roll call without returning their contents', async () => {
    const reader = await readDatasetZip(buildZip([11, 22, 33], [7, 8]));
    expect(reader.billIds.sort((a, b) => a - b)).toEqual([11, 22, 33]);
    expect(reader.rollCallCount).toBe(2);
  });

  it('🔴 reads ONLY the bills asked for', async () => {
    const reader = await readDatasetZip(buildZip([11, 22, 33, 44], [7]));
    const slice = reader.readBills([22, 44]);
    expect([...slice.keys()].sort((a, b) => a - b)).toEqual([22, 44]);
    expect(slice.get(22).bill_number).toBe('AB22');
  });

  it('resolves a roll call by id, and returns undefined for one that is absent', async () => {
    const reader = await readDatasetZip(buildZip([11], [7]));
    expect(reader.readRollCall(7).desc).toBe('Third reading');
    expect(reader.readRollCall(999)).toBeUndefined();
  });

  it('🟢 CONTROL (retention): a repeat read re-inflates and does not accumulate a cache', async () => {
    const reader = await readDatasetZip(buildZip([11, 22], [7]));
    const first = reader.readBills([11]).get(11);
    const second = reader.readBills([11]).get(11);
    expect(second).toEqual(first);
    expect(second).not.toBe(first);
  });

  it('🔴🔴 CONTROL (allocation): the index pass reads a BOUNDED PREFIX, not whole entries', async () => {
    // This is the control the 19:45 failure proved was missing. Twenty bills of ~60 KB each is
    // ~1.2 MB of JSON; indexing them must touch only a few KB apiece. An implementation that
    // parses each entry to read its id scans the lot, and fails here.
    const PAD = 60_000;
    const ids = Array.from({ length: 20 }, (_, i) => i + 1);
    const reader = await readDatasetZip(buildZip(ids, [], PAD));

    expect(reader.billIds.sort((a, b) => a - b)).toEqual(ids);
    expect(reader.indexStats.entries).toBe(20);
    expect(reader.indexStats.fullParseFallbacks).toBe(0);
    // The ceiling is a function of the entry COUNT alone.
    expect(reader.indexStats.bytesScanned).toBeLessThanOrEqual(20 * INDEX_PREFIX_BYTES);
    // And emphatically not of their SIZE.
    expect(reader.indexStats.bytesScanned).toBeLessThan(20 * PAD * 0.2);
  });

  it('falls back to a full parse when the id is past the prefix, and COUNTS it', async () => {
    // A silent fallback would reintroduce the defect one file at a time, so it is counted.
    const zip = new AdmZip();
    zip.addFile(
      'CA/2025-2026/bill/late.json',
      Buffer.from(JSON.stringify({ bill: { padding: 'x'.repeat(INDEX_PREFIX_BYTES * 2), bill_id: 99 } })),
    );
    const reader = await readDatasetZip(zip.toBuffer());
    expect(reader.billIds).toEqual([99]);          // correctness is not sacrificed
    expect(reader.indexStats.fullParseFallbacks).toBe(1); // but the cost is visible
  });

  it('skips entries that are not JSON, and entries that carry no id', async () => {
    const zip = new AdmZip();
    zip.addFile('CA/2025-2026/bill/1.json', Buffer.from(JSON.stringify({ bill: { bill_id: 1 } })));
    zip.addFile('CA/2025-2026/bill/broken.json', Buffer.from('{not json'));
    zip.addFile('CA/2025-2026/bill/noid.json', Buffer.from(JSON.stringify({ bill: { title: 'x' } })));
    zip.addFile('CA/2025-2026/readme.txt', Buffer.from('ignore me'));
    const reader = await readDatasetZip(zip.toBuffer());
    expect(reader.billIds).toEqual([1]);
  });

  it('accepts a bill object stored unwrapped, as the original reader did', async () => {
    const zip = new AdmZip();
    zip.addFile('CA/2025-2026/bill/5.json', Buffer.from(JSON.stringify({ bill_id: 5, title: 'bare' })));
    zip.addFile('CA/2025-2026/rollcall/9.json', Buffer.from(JSON.stringify({ roll_call_id: 9 })));
    const reader = await readDatasetZip(zip.toBuffer());
    expect(reader.billIds).toEqual([5]);
    expect(reader.readBills([5]).get(5).title).toBe('bare');
    expect(reader.readRollCall(9).roll_call_id).toBe(9);
  });

  it('indexes a dataset larger than one yield window', async () => {
    // Crosses INDEX_YIELD_EVERY (200) so the await path is exercised, not just the fast path.
    const ids = Array.from({ length: 450 }, (_, i) => i + 1);
    const reader = await readDatasetZip(buildZip(ids, []));
    expect(reader.billIds.length).toBe(450);
    expect(reader.indexStats.fullParseFallbacks).toBe(0);
  });
});
