import { vi, describe, it, expect, beforeEach } from 'vitest';

const poolQueryMock = vi.fn();
vi.mock('./db.js', () => ({ pool: { query: (...a: unknown[]) => poolQueryMock(...a) } }));

import { reapStaleIngestionRuns } from './reapStaleIngestionRuns.js';

beforeEach(() => poolQueryMock.mockReset());

describe('reapStaleIngestionRuns', () => {
  it('only touches rows in running, and only those older than the threshold', async () => {
    poolQueryMock.mockResolvedValue({ rows: [], rowCount: 0 });
    await reapStaleIngestionRuns();

    const [sql, params] = poolQueryMock.mock.calls[0]!;
    // Must be scoped — a bare status filter would kill a run legitimately in flight
    // on a draining dyno during a deploy overlap.
    expect(sql).toMatch(/WHERE\s+status\s*=\s*'running'/);
    expect(sql).toMatch(/started_at\s*<\s*NOW\(\)\s*-/);
    expect(params).toEqual([3]);
  });

  it('writes a terminal status and a completed_at so the row stops looking in-flight', async () => {
    poolQueryMock.mockResolvedValue({ rows: [], rowCount: 0 });
    await reapStaleIngestionRuns();

    const [sql] = poolQueryMock.mock.calls[0]!;
    expect(sql).toMatch(/status\s*=\s*'failed'/);
    expect(sql).toMatch(/completed_at\s*=\s*NOW\(\)/);
    expect(sql).toMatch(/reaped/);
  });

  it('reports how many it closed', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ id: '1' }, { id: '2' }], rowCount: 2 });
    expect(await reapStaleIngestionRuns()).toEqual({ reaped: 2 });
  });

  it('is a no-op when nothing is stale', async () => {
    poolQueryMock.mockResolvedValue({ rows: [], rowCount: 0 });
    expect(await reapStaleIngestionRuns()).toEqual({ reaped: 0 });
  });

  it('honours INGESTION_STALE_AFTER_HOURS for the long-running backfill', async () => {
    vi.resetModules();
    process.env.INGESTION_STALE_AFTER_HOURS = '24';
    const mod = await import('./reapStaleIngestionRuns.js');
    poolQueryMock.mockResolvedValue({ rows: [], rowCount: 0 });
    await mod.reapStaleIngestionRuns();
    expect(poolQueryMock.mock.calls[0]![1]).toEqual([24]);
    delete process.env.INGESTION_STALE_AFTER_HOURS;
  });
});
