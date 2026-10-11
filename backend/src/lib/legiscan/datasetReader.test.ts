/**
 * datasetReader.test.ts — the reader must never materialise a whole session at once.
 *
 * 🔴 WHY THIS EXISTS. On 2026-10-11 the weekly `ev-jobs-legiscan` cron died with
 * `FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory`,
 * at ~254 MB, on the FIRST state it actually had to process: California. The old
 * `downloadDataset` parsed every bill and every roll call of a session into two Maps and
 * returned them, so peak memory was the whole session before a single row was written.
 * This is the same defect `ocpfAdapter` was fixed for on 2026-10-03 (a 109 MB body held
 * whole), and it was fixed there the same way: read a slice, write it, then read the next.
 *
 * ⚠ WHAT THESE TESTS CAN AND CANNOT PROVE. They pin the CONTRACT — that a read returns
 * only what was asked for, and that nothing is cached between reads. They cannot prove the
 * job now fits in 512 MiB; only a run against a real California dataset shows that. Do not
 * read a green suite here as evidence the cron is fixed.
 *
 * 🟢 The no-caching claim rests on adm-zip 0.6.1: for an archive that was READ rather than
 * built, `_centralHeader.changed` is false, so `getData()` re-inflates on every call and
 * never populates `uncompressedData`. `decompressCount` below is the control that keeps
 * that true — if a future adm-zip starts caching, the repeat-read test fails.
 */
import { describe, it, expect, vi } from 'vitest';
import AdmZip from 'adm-zip';

const queryMock = vi.hoisted(() => vi.fn(async () => ({ rows: [] })));
vi.mock('../db.js', () => ({ pool: { query: queryMock } }));
vi.mock('./client.js', () => ({ legiscanQuery: vi.fn() }));

import { readDatasetZip } from './importer.js';

/** A dataset shaped like LegiScan's: `<session>/bill/*.json`, `<session>/vote/*.json`. */
function buildZip(bills: number[], rollCalls: number[]): Buffer {
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
  it('indexes every bill and roll call without returning their contents', () => {
    const reader = readDatasetZip(buildZip([11, 22, 33], [7, 8]));
    expect(reader.billIds.sort((a, b) => a - b)).toEqual([11, 22, 33]);
    expect(reader.rollCallCount).toBe(2);
  });

  it('🔴 reads ONLY the bills asked for — the whole point of the fix', () => {
    const reader = readDatasetZip(buildZip([11, 22, 33, 44], [7]));
    const slice = reader.readBills([22, 44]);
    expect([...slice.keys()].sort((a, b) => a - b)).toEqual([22, 44]);
    expect(slice.size).toBe(2);
    expect(slice.get(22).bill_number).toBe('AB22');
  });

  it('resolves a roll call by id, and returns undefined for one that is absent', () => {
    const reader = readDatasetZip(buildZip([11], [7]));
    expect(reader.readRollCall(7).desc).toBe('Third reading');
    expect(reader.readRollCall(999)).toBeUndefined();
  });

  it('🟢 CONTROL: a repeat read re-inflates and does not accumulate a cache', () => {
    // If adm-zip ever starts caching decompressed entries, the lazy design silently
    // becomes the old eager one. Reading the same bill twice must produce equal values
    // that are NOT the same object — proof a fresh parse happened.
    const reader = readDatasetZip(buildZip([11, 22], [7]));
    const first = reader.readBills([11]).get(11);
    const second = reader.readBills([11]).get(11);
    expect(second).toEqual(first);
    expect(second).not.toBe(first);
  });

  it('skips entries that are not JSON, and entries that parse but carry no id', () => {
    const zip = new AdmZip();
    zip.addFile('CA/2025-2026/bill/1.json', Buffer.from(JSON.stringify({ bill: { bill_id: 1 } })));
    zip.addFile('CA/2025-2026/bill/broken.json', Buffer.from('{not json'));
    zip.addFile('CA/2025-2026/bill/noid.json', Buffer.from(JSON.stringify({ bill: { title: 'x' } })));
    zip.addFile('CA/2025-2026/readme.txt', Buffer.from('ignore me'));
    const reader = readDatasetZip(zip.toBuffer());
    expect(reader.billIds).toEqual([1]);
  });

  it('accepts a bill object stored unwrapped, as the old reader did', () => {
    const zip = new AdmZip();
    zip.addFile('CA/2025-2026/bill/5.json', Buffer.from(JSON.stringify({ bill_id: 5, title: 'bare' })));
    zip.addFile('CA/2025-2026/rollcall/9.json', Buffer.from(JSON.stringify({ roll_call_id: 9 })));
    const reader = readDatasetZip(zip.toBuffer());
    expect(reader.billIds).toEqual([5]);
    expect(reader.readBills([5]).get(5).title).toBe('bare');
    expect(reader.readRollCall(9).roll_call_id).toBe(9);
  });
});
