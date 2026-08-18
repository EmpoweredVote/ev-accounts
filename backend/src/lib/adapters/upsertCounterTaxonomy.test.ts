import { vi, describe, it, expect, beforeEach } from 'vitest';
import type { SourceAdapter, NormalizeResult, UpsertResult } from './adapterInterface.js';
import type { PoliticianSource } from '../campaignFinanceService.js';

const poolQueryMock = vi.hoisted(() => vi.fn());
vi.mock('../db.js', () => ({ pool: { query: (...a: unknown[]) => poolQueryMock(...a) } }));
vi.mock('../campaignFinanceService.js', () => ({ refreshSummaryAggForSource: vi.fn() }));

import { runIngestion } from './runIngestion.js';

const ps = { id: 'ps-1', external_id: 'X' } as unknown as PoliticianSource;

function adapterWith(upsert: UpsertResult, totalParsed = 0): SourceAdapter {
  return {
    name: () => 'ocpf',
    fetch: async () => ({ records: [], totalExpected: 0, totalFetched: totalParsed }),
    normalize: async () =>
      ({ contributions: [], skipped: 0, totalParsed } as NormalizeResult),
    upsert: async () => upsert,
  };
}

/** Pull (status, notes, records_skipped) back out of the finalizing UPDATE. */
function recorded() {
  const call = poolQueryMock.mock.calls.find(
    (c) => typeof c[0] === 'string' && c[0].includes('UPDATE') && c[0].includes('records_skipped')
  );
  const params = (call?.[1] ?? []) as unknown[];
  return { notes: params[8] as string, recordsSkipped: params[5] as number };
}

beforeEach(() => {
  poolQueryMock.mockReset();
  poolQueryMock.mockResolvedValue({ rows: [{ id: '1' }], rowCount: 1 });
});

describe('upsert counter taxonomy — refreshed is not skipped', () => {
  // 🔴 ocpf and netfile rewrite amount / contribution_date / raw_record on conflict, so a
  // re-read REPAIRS rows. That mechanism corrected a $15.6M amount defect on 2026-08-18 —
  // and reported it as "89,557 skipped", the exact opposite of what it did.

  it('states refreshed rows in the notes rather than only as a skip count', async () => {
    await runIngestion(
      adapterWith({ inserted: 0, updated: 89_557, skipped: 0, unresolved: 0, errors: 0 }, 89_557),
      ps,
      'all'
    );

    const { notes } = recorded();
    expect(notes).toContain('refreshed 89557 existing row(s)');
  });

  it('keeps records_skipped continuous, so the historical column does not jump', async () => {
    // The column means "fetched but not inserted". A refreshed row still qualifies, so its
    // VALUE must not change — only its legibility. 5 refreshed + 2 dropped = 7.
    await runIngestion(
      adapterWith({ inserted: 10, updated: 5, skipped: 2, unresolved: 0, errors: 0 }, 17),
      ps,
      'all'
    );

    expect(recorded().recordsSkipped).toBe(7);
  });

  it('does NOT let refreshed rows trip the skip-threshold warning', async () => {
    // The 1% alarm measures normalizer DEFECTS. A run that refreshes 100% of its rows is a
    // healthy re-read; if `updated` fed that alarm, every repair run would warn.
    await runIngestion(
      adapterWith({ inserted: 0, updated: 1000, skipped: 0, unresolved: 0, errors: 0 }, 1000),
      ps,
      'all'
    );

    const { notes } = recorded();
    expect(notes).not.toContain('skip threshold exceeded');
  });

  it('says nothing about refreshes when there were none', async () => {
    await runIngestion(
      adapterWith({ inserted: 3, updated: 0, skipped: 0, unresolved: 0, errors: 0 }, 3),
      ps,
      'all'
    );

    expect(recorded().notes).not.toContain('refreshed');
  });
});
