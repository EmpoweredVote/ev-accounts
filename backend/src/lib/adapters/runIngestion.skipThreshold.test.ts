import { vi, describe, it, expect, beforeEach } from 'vitest';

// Capture every UPDATE to ingestion_runs so the recorded status/notes can be asserted.
const poolQueryMock = vi.fn();
vi.mock('../db.js', () => ({ pool: { query: (...a: unknown[]) => poolQueryMock(...a) } }));

import { runIngestion } from './runIngestion.js';
import type { SourceAdapter, NormalizeResult } from './adapterInterface.js';
import type { PoliticianSource } from '../campaignFinanceService.js';

const ps = { id: 'ps-1', external_id: 'X' } as unknown as PoliticianSource;

/** Build an adapter whose normalize() returns exactly the counts under test. */
function adapterWith(name: string, n: Partial<NormalizeResult>): SourceAdapter {
  return {
    name: () => name,
    fetch: async () => ({ records: [], totalExpected: 0, totalFetched: 0 }),
    normalize: async () => ({ contributions: [], skipped: 0, totalParsed: 0, ...n }) as NormalizeResult,
    upsert: async () => ({ inserted: 0, skipped: 0, unresolved: 0, errors: 0 }),
  };
}

/** The final UPDATE carries (status, notes) — pull them back out. */
function recorded() {
  const call = poolQueryMock.mock.calls.find(
    (c) => typeof c[0] === 'string' && c[0].includes('UPDATE') && c[0].includes('status')
  );
  const params = (call?.[1] ?? []) as unknown[];
  return {
    status: params.find((p) => p === 'completed' || p === 'completed_with_warning') as string,
    notes: (params.find((p) => typeof p === 'string' && (p === '' || p.includes('skip') || p.includes('excluded') || p.includes('fetched'))) ?? '') as string,
  };
}

beforeEach(() => {
  poolQueryMock.mockReset();
  poolQueryMock.mockResolvedValue({ rows: [{ id: '1' }] });
});

describe('skip threshold separates DEFECTS from deliberate EXCLUSIONS', () => {
  it('does NOT warn when FEC excludes memo items, even at a 70% exclusion rate', async () => {
    // FEC's only "skip" is memo_code === 'X' — an intentional business rule, not a
    // defect. Measured over 60 days of prod runs the memo rate has a median of 42%
    // and a p95 of 70.6%, which produced 9,636 false warnings.
    await runIngestion(adapterWith('fec', { skipped: 0, excluded: 706, totalParsed: 1000 }), ps);

    const { status, notes } = recorded();
    expect(status).toBe('completed');
    expect(notes).not.toMatch(/skip threshold exceeded/);
  });

  it('STILL warns when FEC has a genuine normalize defect above 1%', async () => {
    // The point of splitting the counters is to restore the signal, not remove it.
    await runIngestion(adapterWith('fec', { skipped: 20, excluded: 700, totalParsed: 1000 }), ps);

    const { status, notes } = recorded();
    expect(status).toBe('completed_with_warning');
    expect(notes).toMatch(/skip threshold exceeded/);
  });

  it('preserves the Cal-Access 1% locked decision for real defects', async () => {
    // Cal-Access counts missing_required_field / amount_parse_error here. Unchanged.
    await runIngestion(adapterWith('cal_access', { skipped: 15, totalParsed: 1000 }), ps);

    const { status, notes } = recorded();
    expect(status).toBe('completed_with_warning');
    expect(notes).toMatch(/skip threshold exceeded: 15\/1000/);
  });

  it('does not warn below the 1% defect threshold', async () => {
    await runIngestion(adapterWith('cal_access', { skipped: 5, totalParsed: 1000 }), ps);
    expect(recorded().status).toBe('completed');
  });
});

// ---------------------------------------------------------------------------
// The defect itself lives in fecAdapter: it reports memo items via `skipped`,
// which is the field runIngestion treats as "data defects". The tests above only
// exercise runIngestion's arithmetic and pass either way — this one does not.
// ---------------------------------------------------------------------------
describe('fecAdapter reports memo items as EXCLUDED, not skipped', () => {
  it('puts memo_code=X rows in excluded and leaves skipped clean', async () => {
    const { createFecAdapter } = await import('./fecAdapter.js');
    const adapter = createFecAdapter('2026');

    const records = [
      { sub_id: '1', memo_code: 'X', contribution_receipt_amount: 10, contribution_receipt_date: '2026-01-01', committee_id: 'C1' },
      { sub_id: '2', memo_code: 'X', contribution_receipt_amount: 10, contribution_receipt_date: '2026-01-01', committee_id: 'C1' },
      { sub_id: '3', contribution_receipt_amount: 25, contribution_receipt_date: '2026-01-01', committee_id: 'C1' },
    ];

    const norm = await adapter.normalize(
      { records, totalExpected: 3, totalFetched: 3 },
      ps
    );

    expect(norm.totalParsed).toBe(3);
    expect(norm.contributions.length).toBe(1);
    // Memo items are a deliberate exclusion, NOT a defect.
    expect(norm.excluded).toBe(2);
    expect(norm.skipped).toBe(0);
  });
});
