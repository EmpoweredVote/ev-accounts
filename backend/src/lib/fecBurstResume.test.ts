import { vi, describe, it, expect, beforeEach } from 'vitest';

const poolQueryMock = vi.fn();
vi.mock('./db.js', () => ({ pool: { query: (...a: unknown[]) => poolQueryMock(...a) } }));

import {
  pendingFecSourcesSql,
  BURST_WINDOW_START_SQL,
  FEC_LEAST_RECENTLY_TRIED_ORDER_SQL,
} from './fecBurstResume.js';

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

describe('least-recently-tried walk order', () => {
  it('orders by the last attempt of any outcome, oldest first, never-tried last', () => {
    // 🔴 2026-11-19..21: a fixed order let every cut-off run drop the SAME tail. Ordering by
    // last attempt makes today's tail tomorrow's head.
    expect(FEC_LEAST_RECENTLY_TRIED_ORDER_SQL).toMatch(/max\(prior\.started_at\)/);
    expect(FEC_LEAST_RECENTLY_TRIED_ORDER_SQL).toMatch(/\)\s*ASC NULLS LAST/);
    expect(FEC_LEAST_RECENTLY_TRIED_ORDER_SQL).toMatch(/adapter_name = 'fec'/);
  });

  it('counts a FAILED attempt as tried, so a source that times out does not lead again tomorrow', () => {
    // 🔴 2026-11-22: ordered by last SUCCESS, a source that hit the 10-minute per-source cap
    // stayed the stalest and led the next run too. 13 of that day's 20 failures had already
    // failed earlier in the week, and the run spent its first 2.5 hours on 16 sources.
    expect(FEC_LEAST_RECENTLY_TRIED_ORDER_SQL).not.toMatch(/status/);
  });

  it('judges recency over all history, not just this burst window', () => {
    // Scoping it to the window would make every source look never-tried each morning.
    expect(FEC_LEAST_RECENTLY_TRIED_ORDER_SQL).not.toMatch(/interval/);
  });

  it('keeps the resume pass in the same order as the burst it finishes', () => {
    expect(pendingFecSourcesSql).toContain(`ORDER BY ${FEC_LEAST_RECENTLY_TRIED_ORDER_SQL}`);
  });
});
