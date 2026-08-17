import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// Mock the shared pool so importing ocpfAdapter.ts (which reaches ../db.js at module
// scope) doesn't trigger env.ts's startup validation in a test environment with no
// real DATABASE_URL. Mirrors fecAdapter.test.ts.
const poolQueryMock = vi.fn();
vi.mock('../db.js', () => ({ pool: { query: (...args: unknown[]) => poolQueryMock(...args) } }));

import { createOcpfAdapter } from './ocpfAdapter.js';
import type { PoliticianSource } from '../campaignFinanceService.js';

const PAGE_SIZE = 250;

function source(externalId = '12008'): PoliticianSource {
  return { id: 'src-1', external_id: externalId } as unknown as PoliticianSource;
}

/**
 * Reproduces the OCPF API's ACTUAL behaviour, confirmed live against
 * api.ocpf.us on 2026-08-17:
 *
 *   pageNumber is IGNORED. Pages 1, 2, 3, 50, 298, 500 and 1000 all returned the
 *   identical 250 records (same first ids 518289, 518326). pageSize IS honoured —
 *   pageSize=10 returns 10, pageSize=1000 returns the cycle's true total of 289.
 *
 * So a full first page is NOT evidence that another page exists, and the old
 * `items.length < PAGE_SIZE` exit condition could never fire for any committee
 * with >= 250 receipts in the window.
 */
function mockOcpfIgnoringPageNumber(total: number) {
  return vi.fn(async (url: string) => {
    const size = Number(new URL(url).searchParams.get('pageSize') ?? PAGE_SIZE);
    // pageNumber deliberately not read — the real API ignores it.
    const n = Math.min(size, total);
    const items = Array.from({ length: n }, (_, i) => ({ id: 518289 + i, amount: 1 }));
    return { status: 200, json: async () => ({ summary: null, items }) } as unknown as Response;
  });
}

describe('ocpfAdapter pagination', () => {
  beforeEach(() => vi.stubGlobal('fetch', vi.fn()));
  afterEach(() => vi.unstubAllGlobals());

  it('terminates and returns each record ONCE when the window holds more than one page', async () => {
    // 289 = the real 2005-Q2 total for cpf 12008. Above PAGE_SIZE, so this is
    // exactly the shape that used to loop forever.
    const fetchMock = mockOcpfIgnoringPageNumber(289);
    vi.stubGlobal('fetch', fetchMock);

    const result = await createOcpfAdapter(2005, undefined, 2).fetch(source());

    // Before the fix this never returned — the loop appended the same 250 rows
    // ~300 times until the external 180s timeout aborted it.
    expect(result.records.length).toBe(289);

    // And every record must be distinct: the old loop's output was 300 copies.
    const ids = new Set(result.records.map((r) => (r as { id: number }).id));
    expect(ids.size).toBe(289);
  });

  it('issues ONE request per window, not one per phantom page', async () => {
    const fetchMock = mockOcpfIgnoringPageNumber(289);
    vi.stubGlobal('fetch', fetchMock);

    await createOcpfAdapter(2005, undefined, 2).fetch(source());

    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('still returns everything for a window smaller than one page', async () => {
    const fetchMock = mockOcpfIgnoringPageNumber(42);
    vi.stubGlobal('fetch', fetchMock);

    const result = await createOcpfAdapter(2005, undefined, 2).fetch(source());

    expect(result.records.length).toBe(42);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('handles the largest real committee (cpf 15710, 89,557 records) in one request', async () => {
    const fetchMock = mockOcpfIgnoringPageNumber(89_557);
    vi.stubGlobal('fetch', fetchMock);

    const result = await createOcpfAdapter().fetch(source('15710'));

    expect(result.records.length).toBe(89_557);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('throws rather than silently truncating if the response fills the requested pageSize', async () => {
    // If OCPF ever caps pageSize, items.length === requested size is the ONLY
    // signal available (there is no total count — `summary` is null). Silently
    // returning a truncated set would undercount a filer's receipts, so this must
    // fail loudly instead.
    const fetchMock = vi.fn(async (url: string) => {
      const size = Number(new URL(url).searchParams.get('pageSize') ?? PAGE_SIZE);
      const items = Array.from({ length: size }, (_, i) => ({ id: i, amount: 1 }));
      return { status: 200, json: async () => ({ summary: null, items }) } as unknown as Response;
    });
    vi.stubGlobal('fetch', fetchMock);

    await expect(createOcpfAdapter().fetch(source())).rejects.toThrow(/truncat|cap/i);
  });
});
