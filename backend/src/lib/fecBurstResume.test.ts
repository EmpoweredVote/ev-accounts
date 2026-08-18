import { vi, describe, it, expect, beforeEach } from 'vitest';

const poolQueryMock = vi.fn();
vi.mock('./db.js', () => ({ pool: { query: (...a: unknown[]) => poolQueryMock(...a) } }));

import { pendingFecSourcesSql, BURST_WINDOW_START_SQL } from './fecBurstResume.js';

beforeEach(() => poolQueryMock.mockReset());

describe('pending-source derivation for FEC burst resume', () => {
  it('anchors the window to the most recent 06:00 UTC burst, not to midnight', () => {
    // The burst starts at 06:00 UTC. Anchoring to midnight would treat a source that
    // ran during YESTERDAY's burst tail (which can spill past midnight local) as done
    // for today, and anchoring to "24h ago" would slide.
    expect(BURST_WINDOW_START_SQL).toMatch(/interval '6 hours'/);
    // and it must step BACK a day before the burst hour, or every pre-06:00 boot
    // would treat the whole previous day as pending and re-run all 662 sources.
    expect(BURST_WINDOW_START_SQL).toMatch(/interval '1 day'/);
  });

  it('counts a source as DONE only on a terminal success, never on running or failed', () => {
    // 🔴 The whole bug being fixed is that a killed process leaves rows in 'running'.
    // If 'running' counted as done, resume would skip exactly the source it should retry.
    expect(pendingFecSourcesSql).toMatch(/completed_with_warning/);
    expect(pendingFecSourcesSql).toMatch(/NOT EXISTS/i);
    expect(pendingFecSourcesSql).not.toMatch(/'running'/);
  });

  it('only considers confirmed fec_house / fec_senate sources', () => {
    expect(pendingFecSourcesSql).toMatch(/fec_house/);
    expect(pendingFecSourcesSql).toMatch(/fec_senate/);
    expect(pendingFecSourcesSql).toMatch(/research_status\s*=\s*'confirmed'/);
  });
});

describe('resumeFecBurstIfIncomplete', () => {
  it('does nothing when every source already succeeded in this burst window', async () => {
    vi.resetModules();
    const runFecForSources = vi.fn();
    vi.doMock('./campaignFinanceScheduler.js', () => ({
      runFecForSources,
      currentFecCycle: () => '2026',
      acquireLock: vi.fn().mockResolvedValue(true),
      releaseLock: vi.fn().mockResolvedValue(undefined),
      FEC_LOCK_KEY: 'k',
    }));
    poolQueryMock.mockResolvedValue({ rows: [], rowCount: 0 });

    const { resumeFecBurstIfIncomplete } = await import('./fecBurstResume.js');
    const r = await resumeFecBurstIfIncomplete();

    expect(r).toEqual({ status: 'complete', pending: 0, ran: 0 });
    expect(runFecForSources).not.toHaveBeenCalled();
  });

  it('runs ONLY the pending remainder, not the whole roster', async () => {
    vi.resetModules();
    const runFecForSources = vi.fn().mockResolvedValue(undefined);
    vi.doMock('./campaignFinanceScheduler.js', () => ({
      runFecForSources,
      currentFecCycle: () => '2026',
      acquireLock: vi.fn().mockResolvedValue(true),
      releaseLock: vi.fn().mockResolvedValue(undefined),
      FEC_LOCK_KEY: 'k',
    }));
    const pending = [{ id: 'a' }, { id: 'b' }, { id: 'c' }];
    poolQueryMock.mockResolvedValue({ rows: pending, rowCount: 3 });

    const { resumeFecBurstIfIncomplete } = await import('./fecBurstResume.js');
    const r = await resumeFecBurstIfIncomplete();

    expect(r).toEqual({ status: 'resumed', pending: 3, ran: 3 });
    expect(runFecForSources).toHaveBeenCalledTimes(1);
    expect(runFecForSources.mock.calls[0]![0]).toHaveLength(3);
  });

  it('yields to a burst already in flight rather than double-running it', async () => {
    vi.resetModules();
    const runFecForSources = vi.fn();
    vi.doMock('./campaignFinanceScheduler.js', () => ({
      runFecForSources,
      currentFecCycle: () => '2026',
      acquireLock: vi.fn().mockResolvedValue(false),  // 06:00 cron holds it
      releaseLock: vi.fn().mockResolvedValue(undefined),
      FEC_LOCK_KEY: 'k',
    }));
    poolQueryMock.mockResolvedValue({ rows: [{ id: 'a' }], rowCount: 1 });

    const { resumeFecBurstIfIncomplete } = await import('./fecBurstResume.js');
    const r = await resumeFecBurstIfIncomplete();

    expect(r.status).toBe('skipped_locked');
    expect(runFecForSources).not.toHaveBeenCalled();
  });
});
