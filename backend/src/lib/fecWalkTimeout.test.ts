import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// runFecForSources reaches the pool for zombie cleanup and the FEC adapter for work.
const poolQueryMock = vi.hoisted(() => vi.fn().mockResolvedValue({ rows: [], rowCount: 0 }));
const runIngestionMock = vi.hoisted(() => vi.fn());
const createFecAdapterMock = vi.hoisted(() => vi.fn((_cycle?: string) => ({ name: () => 'fec' })));

vi.mock('./env.js', () => ({ env: { DATABASE_URL: 'postgres://test' } }));
vi.mock('./db.js', () => ({ pool: { query: (...a: unknown[]) => poolQueryMock(...a) } }));
vi.mock('./adapters/runIngestion.js', () => ({
  runIngestion: (...a: unknown[]) => runIngestionMock(...a),
}));
vi.mock('./adapters/fecAdapter.js', () => ({
  createFecAdapter: (cycle: string) => createFecAdapterMock(cycle),
}));

const sources = [
  { id: 'src-hang', external_id: 'A' },
  { id: 'src-next', external_id: 'B' },
] as never[];

beforeEach(() => {
  vi.resetModules();
  poolQueryMock.mockClear().mockResolvedValue({ rows: [], rowCount: 0 });
  runIngestionMock.mockReset();
  process.env.FEC_PER_SOURCE_TIMEOUT_MS = '10000';
  vi.useFakeTimers();
});
afterEach(() => {
  vi.useRealTimers();
  delete process.env.FEC_PER_SOURCE_TIMEOUT_MS;
});

describe('runFecForSources — per-source timeout (2026-08-18 burst halt)', () => {
  // 🔴 A HANG IS NOT AN ERROR. The pre-fix loop caught per-source errors and continued,
  // which reads as robust — but on 2026-08-18 a source stopped producing output at
  // 06:23:43 and nothing threw, so the catch never ran and the remaining ~500 sources
  // never happened. The dyno stayed healthy the whole time.

  it('abandons a HUNG source and still walks the rest', async () => {
    runIngestionMock
      // First source never settles — exactly the observed failure.
      .mockImplementationOnce(() => new Promise(() => {}))
      .mockImplementationOnce(() => Promise.resolve());

    const { runFecForSources } = await import('./campaignFinanceScheduler.js');
    const walk = runFecForSources(sources, '2026');

    // Past the per-source ceiling plus the 3s inter-source delay.
    await vi.advanceTimersByTimeAsync(20000);
    await walk;

    // The critical assertion: the SECOND source ran despite the first hanging forever.
    expect(runIngestionMock).toHaveBeenCalledTimes(2);
  });

  it('passes an AbortSignal so the stall can actually be interrupted', async () => {
    runIngestionMock.mockResolvedValue(undefined);

    const { runFecForSources } = await import('./campaignFinanceScheduler.js');
    const walk = runFecForSources([sources[0]], '2026');
    await vi.advanceTimersByTimeAsync(100);
    await walk;

    // runIngestion(adapter, ps, cycle, signal) — the 4th arg must be a live signal, or the
    // abort cannot reach fetchStream or acquireFecSlot, which is where the stall happened.
    const signal = runIngestionMock.mock.calls[0][3];
    expect(signal).toBeInstanceOf(AbortSignal);
    expect(signal.aborted).toBe(false);
  });

  it('marks a timed-out run failed rather than leaving it wedged in running', async () => {
    runIngestionMock.mockImplementationOnce(() => new Promise(() => {}));

    const { runFecForSources } = await import('./campaignFinanceScheduler.js');
    const walk = runFecForSources([sources[0]], '2026');
    await vi.advanceTimersByTimeAsync(20000);
    await walk;

    const cleanup = poolQueryMock.mock.calls.find(
      (c) => typeof c[0] === 'string' && c[0].includes('ingestion_runs') && c[0].includes("'failed'")
    );
    expect(cleanup).toBeDefined();
    expect(cleanup![1]).toEqual(
      expect.arrayContaining([expect.stringMatching(/per-source timeout/), 'src-hang', '2026'])
    );
  });
});
