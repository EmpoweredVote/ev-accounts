import { vi, describe, it, expect, beforeEach } from 'vitest';

const poolQueryMock = vi.fn();
vi.mock('../db.js', () => ({ pool: { query: (...a: unknown[]) => poolQueryMock(...a) } }));

import { runIngestion } from './runIngestion.js';
import type { SourceAdapter, StreamingAdapter } from './adapterInterface.js';
import type { PoliticianSource } from '../campaignFinanceService.js';

const ps = { id: 'ps-1', external_id: 'X' } as unknown as PoliticianSource;

/** A streaming adapter that saves some rows and returns normally once the signal fires —
 *  the shape of fecAdapter's cooperative stop at a page boundary. */
function stopsOnAbort(controller: AbortController, saved: number): SourceAdapter & StreamingAdapter {
  return {
    name: () => 'fec',
    fetch: async () => ({ records: [], totalExpected: 0, totalFetched: 0 }),
    fetchStream: async (_ps, onBatch) => {
      await onBatch([{ sub_id: '1' }]);
      controller.abort(new Error('per-source timeout'));
      // FEC's count for the whole query; the run read 'saved' of it before the cut.
      return { records: [], totalExpected: Math.round(saved * 1.02), totalFetched: saved };
    },
    normalize: async () => ({ contributions: [], skipped: 0, totalParsed: 1 }),
    upsert: async () => ({ inserted: 1, updated: 0, skipped: 0, unresolved: 0, errors: 0 }),
  };
}

const statuses = () =>
  poolQueryMock.mock.calls
    .filter((c) => typeof c[0] === 'string' && c[0].includes('UPDATE'))
    .map((c) => (c[0] as string).includes("status       = 'failed'") ? 'failed' : (c[1] as unknown[])[2]);

beforeEach(() => {
  poolQueryMock.mockReset();
  poolQueryMock.mockResolvedValue({ rows: [{ id: '1' }] });
});

describe('a fetch cut off by its time limit is never recorded as a success', () => {
  it('marks the run failed even when the rows it read were >= 95% of FEC\'s count', async () => {
    // 🔴 2026-11-22: 37 FEC runs since 11-15 were stopped at the 10-minute limit and recorded as
    // completed / completed_with_warning. A success moves the load-date cursor, so every row the
    // cut-off run never reached was skipped by every later run.
    const controller = new AbortController();
    await expect(runIngestion(stopsOnAbort(controller, 14600), ps, '2026', controller.signal))
      .rejects.toThrow(/time limit/);
    expect(statuses()).toEqual(['failed']);
  });

  it('still records an unaborted run as completed', async () => {
    const controller = new AbortController();
    const adapter = stopsOnAbort(controller, 14600);
    adapter.fetchStream = async (_ps, onBatch) => {
      await onBatch([{ sub_id: '1' }]);
      return { records: [], totalExpected: 1, totalFetched: 1 };
    };
    await runIngestion(adapter, ps, '2026', controller.signal);
    expect(statuses()).toEqual(['completed']);
  });
});
