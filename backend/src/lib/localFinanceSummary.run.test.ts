import { vi, describe, it, expect, beforeEach } from 'vitest';

// runNetfileIngestWithSummaries: the NetFile ingest, then both local finance_summary writers, CITY FIRST.
// A summary failure must not fail the ingest; an ingest failure must skip the summaries.

const calls: string[] = [];
let adapterFails = false;
let summaryFails = false;

vi.mock('./campaignFinanceScheduler.js', () => ({
  runAdapterForAll: vi.fn(async (name: string) => {
    calls.push(`ingest:${name}`);
    if (adapterFails) throw new Error('ingest boom');
  }),
}));

// The fake pool answers the candidate query by the source label it is asked for, and records the order.
vi.mock('./db.js', () => ({
  pool: {
    query: vi.fn(async (sql: string, params: unknown[] = []) => {
      if (sql.includes('FROM essentials.politicians p')) {
        calls.push(`summary:${params[1]}`);
        if (summaryFails) throw new Error('summary boom');
        return { rows: [] };
      }
      return { rows: [] };
    }),
  },
}));

import { runNetfileIngestWithSummaries, runLocalFinanceSummaries } from './localFinanceSummary.js';

beforeEach(() => {
  calls.length = 0;
  adapterFails = false;
  summaryFails = false;
});

describe('runNetfileIngestWithSummaries', () => {
  it('ingests NetFile, then writes the city summaries, then the county summaries', async () => {
    await runNetfileIngestWithSummaries();
    expect(calls).toEqual(['ingest:la_county_netfile', 'summary:LA_SOCRATA', 'summary:LA_COUNTY_NETFILE']);
  });

  it('a summary failure is logged and does not fail the ingest', async () => {
    summaryFails = true;
    const err = vi.spyOn(console, 'error').mockImplementation(() => {});
    await expect(runNetfileIngestWithSummaries()).resolves.toBeUndefined();
    expect(err).toHaveBeenCalled();
    err.mockRestore();
  });

  it('an ingest failure propagates and skips the summaries', async () => {
    adapterFails = true;
    await expect(runNetfileIngestWithSummaries()).rejects.toThrow('ingest boom');
    expect(calls).toEqual(['ingest:la_county_netfile']);
  });
});

describe('runLocalFinanceSummaries (the on-demand job)', () => {
  it('fails when the candidate read fails, so the job exits non-zero', async () => {
    summaryFails = true;
    await expect(runLocalFinanceSummaries()).rejects.toThrow('summary boom');
  });
});
