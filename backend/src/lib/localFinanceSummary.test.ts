import { describe, it, expect, vi } from 'vitest';

vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));
// The ingest wrapper's import; loading the real scheduler validates the whole env and exits.
vi.mock('./campaignFinanceScheduler.js', () => ({ runAdapterForAll: vi.fn() }));

import { planLocalSummary } from './localFinanceSummary.js';

const OWN = { gross: 1500, refunded: 250, refundCount: 2 };

describe('planLocalSummary', () => {
  it('writes gross as raised and refunds apart — never a "total_spent"', () => {
    const plan = planLocalSummary(null, OWN, 'LA_SOCRATA');
    expect(plan).toEqual({
      action: 'write', changed: true,
      summary: { total_raised: 1500, total_refunded: 250, refund_count: 2, top_donors: [], cycle: 'all', source: 'LA_SOCRATA' },
    });
  });

  it('replaces an old-shape summary of its own source (net / total_spent) and reports it changed', () => {
    const old = { source: 'LA_SOCRATA', cycle: 'all', top_donors: [], total_raised: 1500, total_spent: 250 };
    const plan = planLocalSummary(old, OWN, 'LA_SOCRATA');
    expect(plan.action).toBe('write');
    expect(plan.action === 'write' && plan.changed).toBe(true);
  });

  it('reports unchanged when the stored summary already matches, whatever its key order', () => {
    const stored = { cycle: 'all', source: 'LA_SOCRATA', top_donors: [], refund_count: 2, total_raised: 1500, total_refunded: 250 };
    const plan = planLocalSummary(stored, OWN, 'LA_SOCRATA');
    expect(plan.action === 'write' && plan.changed).toBe(false);
  });

  it('clears its own summary once the person has no own money left (links disputed later)', () => {
    const stale = { source: 'LA_SOCRATA', total_raised: 900, total_spent: 0, top_donors: [], cycle: 'all' };
    expect(planLocalSummary(stale, { gross: 0, refunded: 0, refundCount: 0 }, 'LA_SOCRATA')).toEqual({ action: 'clear' });
  });

  it('a refunds-only person gets no summary (raised would be $0)', () => {
    expect(planLocalSummary(null, { gross: 0, refunded: 338.76, refundCount: 2 }, 'LA_SOCRATA')).toEqual({ action: 'nothing' });
  });

  it('never overwrites or clears a summary from another source', () => {
    const fec = { source: 'FEC', total_raised: 5, top_donors: [], cycle: '2026' };
    expect(planLocalSummary(fec, OWN, 'LA_SOCRATA')).toEqual({ action: 'keep-other-source', otherSource: 'FEC' });
    expect(planLocalSummary(fec, { gross: 0, refunded: 0, refundCount: 0 }, 'LA_SOCRATA').action).toBe('keep-other-source');
  });
});
