import { vi, describe, it, expect, beforeEach } from 'vitest';

// Mock discoveryAgentRunner so the agent call resolves to zero candidates
// (the 173-01 OPS-03 change: runner returns [] instead of throwing when
// Anthropic is unavailable / a sweep finds nothing).
vi.mock('./discoveryAgentRunner.js', () => ({
  runDiscoveryAgent: vi.fn(),
}));

// Mock pool.query so we fully control the query sequence inside
// runDiscoveryForJurisdiction without touching a real database.
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));

// Mock outbound side effects (email + page pre-fetch) — neither is exercised
// on this path when ADMIN_EMAIL is unset and source_url is null.
vi.mock('./emailService.js', () => ({ sendEmail: vi.fn() }));
vi.mock('./fetchPageContent.js', () => ({ fetchPageContent: vi.fn() }));

import { pool } from './db.js';
import { sendEmail } from './emailService.js';
import { runDiscoveryAgent } from './discoveryAgentRunner.js';
import { runDiscoveryForJurisdiction } from './discoveryService.js';

describe('runDiscoveryForJurisdiction', () => {
  const DISCOVERY_JURISDICTION_ID = 'juris-1';
  const RUN_ID = 'run-1';

  beforeEach(() => {
    vi.mocked(pool.query).mockReset();
    vi.mocked(sendEmail).mockReset();
    vi.mocked(runDiscoveryAgent).mockReset();
    // Ensure the zero-candidate regression-alert / review-email branches
    // (both gated on ADMIN_EMAIL) are not exercised by this test.
    delete process.env.ADMIN_EMAIL;
  });

  it('zero candidates is not a failure', async () => {
    // OPS-03 caller contract: runDiscoveryAgent resolving to zero candidates
    // (the 173-01 regression-alert path, `stopReason: 'end_turn'`, no throw)
    // must surface as a `completed` run with candidatesFound: 0 — never `failed`.
    vi.mocked(runDiscoveryAgent).mockResolvedValueOnce({
      model: 'claude-sonnet-4-6',
      inputTokens: 0,
      outputTokens: 0,
      candidates: [],
      stopReason: 'end_turn',
    } as never);

    vi.mocked(pool.query)
      // 1. config-row load
      .mockResolvedValueOnce({
        rows: [
          {
            id: DISCOVERY_JURISDICTION_ID,
            jurisdiction_geoid: '0666000',
            jurisdiction_name: 'Test City',
            state: 'CA',
            election_date: new Date('2026-11-03T00:00:00Z'),
            source_url: null,
            allowed_domains: null,
          },
        ],
      } as never)
      // 2. known-races load — empty, so the existingCandidates + aliasRows
      //    queries are both skipped by the `knownRaces.length ? ... : []` guards
      .mockResolvedValueOnce({ rows: [] } as never)
      // 3. run-row INSERT ... RETURNING id
      .mockResolvedValueOnce({ rows: [{ id: RUN_ID }] } as never)
      // 4. the final completed UPDATE
      .mockResolvedValueOnce({ rows: [] } as never);

    const summary = await runDiscoveryForJurisdiction(DISCOVERY_JURISDICTION_ID, {
      triggeredBy: 'cron',
      autoUpsert: true,
      suppressRunEmail: true,
    });

    expect(summary.status).toBe('completed');
    expect(summary.candidatesFound).toBe(0);
    expect(summary.errorMessage).toBeNull();

    // Assert the discovery_runs row was finalized as 'completed' (not 'failed').
    const updateCall = vi
      .mocked(pool.query)
      .mock.calls.find(([sql]) => typeof sql === 'string' && sql.includes('UPDATE essentials.discovery_runs'));
    expect(updateCall).toBeDefined();
    expect(updateCall![0]).toContain(`status = 'completed'`);

    // No 'failed' UPDATE was ever issued.
    const failedCall = vi
      .mocked(pool.query)
      .mock.calls.find(([sql]) => typeof sql === 'string' && sql.includes(`status = 'failed'`));
    expect(failedCall).toBeUndefined();

    // The zero-candidate regression alert is gated on ADMIN_EMAIL being set;
    // with it unset, no email of any kind should fire (silent per RESEARCH Pattern 3).
    expect(sendEmail).not.toHaveBeenCalled();
  });
});
