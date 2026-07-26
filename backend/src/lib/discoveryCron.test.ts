import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

// Mock ./env.js — discoveryCron.ts does not read it directly today, but kept
// mocked per this codebase's convention (see discoveryAgentRunner.test.ts)
// so nothing here can leak real environment config into these tests.
vi.mock('./env.js', () => ({ env: { ANTHROPIC_API_KEY: 'test-anthropic-key' } }));

// Mock @anthropic-ai/sdk with the same importOriginal-spreading factory as
// 173-01's discoveryAgentRunner.test.ts — preserves the real APIError class
// hierarchy so both `err instanceof Anthropic.APIError` and
// `new Anthropic.APIError(...)` construction work.
vi.mock('@anthropic-ai/sdk', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@anthropic-ai/sdk')>();
  return { ...actual };
});

// checkAnthropicAvailability is a vi.fn() the OPS-01 sweep tests drive
// directly (mockResolvedValueOnce({available:false,...}) / mockRejectedValueOnce(err)).
const checkAnthropicAvailabilityMock = vi.hoisted(() => vi.fn());
// Spread the real module so the OPS-05 circuit-breaker tests exercise the REAL
// isAccountUnusableError classifier; only the canary is stubbed.
vi.mock('./discoveryAgentRunner.js', async (importOriginal) => {
  const actual = await importOriginal<typeof import('./discoveryAgentRunner.js')>();
  return { ...actual, checkAnthropicAvailability: checkAnthropicAvailabilityMock };
});

const runDiscoveryForJurisdictionMock = vi.hoisted(() => vi.fn());
vi.mock('./discoveryService.js', () => ({
  runDiscoveryForJurisdiction: runDiscoveryForJurisdictionMock,
}));

const sendEmailMock = vi.hoisted(() => vi.fn());
vi.mock('./emailService.js', () => ({ sendEmail: sendEmailMock }));

const poolQueryMock = vi.hoisted(() => vi.fn());
vi.mock('./db.js', () => ({ pool: { query: poolQueryMock } }));

import Anthropic from '@anthropic-ai/sdk';
import {
  isRetryable,
  withRetry,
  runDiscoverySweep,
  leadingEmptyStreak,
  shouldSkipForBackoff,
} from './discoveryCron.js';

function makeAPIError(status: number, type: string, message: string): InstanceType<typeof Anthropic.APIError> {
  return new Anthropic.APIError(status, { type }, message, undefined, type as any);
}

beforeEach(() => {
  checkAnthropicAvailabilityMock.mockReset();
  runDiscoveryForJurisdictionMock.mockReset();
  sendEmailMock.mockReset();
  poolQueryMock.mockReset();
  process.env.ADMIN_EMAIL = 'admin@example.com';
});

// ---------------------------------------------------------------------------
// OPS-02 — typed retry classification
// ---------------------------------------------------------------------------

describe('isRetryable — OPS-02 typed classification', () => {
  it.each([401, 402, 403])(
    'non-retryable — isRetryable returns false for Anthropic.APIError status %d',
    (status) => {
      const err = makeAPIError(status, 'billing_error', `${status} error from canary`);
      expect(isRetryable(err)).toBe(false);
    }
  );

  it('non-retryable — isRetryable returns false for other 4xx (400/404/422)', () => {
    expect(isRetryable(makeAPIError(400, 'invalid_request_error', '400 bad request'))).toBe(false);
    expect(isRetryable(makeAPIError(404, 'not_found_error', '404 not found'))).toBe(false);
    expect(isRetryable(makeAPIError(422, 'unprocessable_entity', '422 unprocessable'))).toBe(false);
  });

  it.each([429, 500, 529])(
    'retryable — isRetryable returns true for status %d',
    (status) => {
      const err = makeAPIError(status, 'overloaded_error', `${status} error`);
      expect(isRetryable(err)).toBe(true);
    }
  );

  it('retryable — falls back to the network regex for non-APIError errors (ECONNRESET true, unrelated plain error false)', () => {
    expect(isRetryable(new Error('ECONNRESET'))).toBe(true);
    expect(isRetryable(new Error('some unrelated plain error'))).toBe(false);
  });
});

describe('withRetry does not multiply — OPS-02', () => {
  it('calls fn exactly once when the first attempt throws a 402 Anthropic.APIError, and rethrows', async () => {
    const apiError = makeAPIError(402, 'billing_error', '402 billing_error: credit balance too low');
    const fn = vi.fn().mockRejectedValue(apiError);

    await expect(withRetry(fn, 'test-label')).rejects.toBe(apiError);
    expect(fn).toHaveBeenCalledTimes(1);
  });
});

// ---------------------------------------------------------------------------
// OPS-01 — sweep pre-flight gate
// ---------------------------------------------------------------------------

describe('runDiscoverySweep — OPS-01 preflight gate', () => {
  it('missing key — sends sendEmail exactly once and never runs the jurisdiction pool.query', async () => {
    checkAnthropicAvailabilityMock.mockResolvedValueOnce({
      available: false,
      reason: 'missing_key',
      detail: 'ANTHROPIC_API_KEY is not configured.',
    });

    await runDiscoverySweep();

    expect(sendEmailMock).toHaveBeenCalledTimes(1);
    expect(poolQueryMock).not.toHaveBeenCalled();
    expect(runDiscoveryForJurisdictionMock).not.toHaveBeenCalled();
  });

  it('unusable credit — sends sendEmail exactly once, never runs the jurisdiction query, and never calls runDiscoveryForJurisdiction', async () => {
    checkAnthropicAvailabilityMock.mockResolvedValueOnce({
      available: false,
      reason: 'unusable',
      detail: '402 billing_error: Your credit balance is too low',
    });

    await runDiscoverySweep();

    expect(sendEmailMock).toHaveBeenCalledTimes(1);
    expect(poolQueryMock).not.toHaveBeenCalled();
    expect(runDiscoveryForJurisdictionMock).not.toHaveBeenCalled();
  });

  it('inconclusive canary — proceeds (does run the jurisdiction pool.query)', async () => {
    const apiError = makeAPIError(529, 'overloaded_error', '529 overloaded');
    checkAnthropicAvailabilityMock.mockRejectedValueOnce(apiError);
    poolQueryMock.mockResolvedValueOnce({ rows: [] });

    await runDiscoverySweep();

    expect(poolQueryMock).toHaveBeenCalledTimes(1);
    expect(sendEmailMock).not.toHaveBeenCalled();
  });
});

// ---------------------------------------------------------------------------
// OPS-05 — mid-sweep circuit breaker
//
// The 2026-07-26 sweep: 46 jurisdictions in horizon, canary passed, 25 completed,
// then credit ran out and the remaining 21 each ran, each failed, and each sent
// its own "Discovery run failed" email. The breaker must stop at the first
// conclusive account-level failure and report once.
// ---------------------------------------------------------------------------

// APIError.makeMessage ignores its `message` arg whenever `error` is truthy, so a
// realistic error must carry its text in the BODY — same shape as the wire response
// and as the error_message rows in prod.
function makeBodyError(status: number, type: string, bodyMessage: string) {
  const body = { type: 'error', error: { type, message: bodyMessage } };
  return new Anthropic.APIError(status, body, undefined, undefined, type as any);
}

const CREDIT_TEXT = 'Your credit balance is too low to access the Anthropic API.';

const creditError = () => makeBodyError(400, 'invalid_request_error', CREDIT_TEXT);

function okSummary(runId: string) {
  return {
    runId,
    jurisdictionId: runId,
    candidatesFound: 0,
    candidatesStaged: 0,
    uncertainStaged: 0,
    matchedStaged: 0,
    officialStaged: 0,
    autoUpserted: 0,
    withdrawalsStaged: 0,
    status: 'completed' as const,
    errorMessage: null,
  };
}

/** Queue N jurisdictions on the horizon query. */
function queueJurisdictions(n: number) {
  poolQueryMock.mockResolvedValueOnce({
    rows: Array.from({ length: n }, (_, i) => ({
      id: `j${i}`,
      jurisdiction_name: `Jurisdiction ${i}`,
      // Well inside the filing window, so OPS-06 backoff never applies and these
      // tests exercise the circuit breaker in isolation.
      days_until_election: 30,
      found_series: null,
      days_since_last_run: null,
    })),
  });
}

describe('runDiscoverySweep — OPS-05 mid-sweep circuit breaker', () => {
  beforeEach(() => {
    checkAnthropicAvailabilityMock.mockResolvedValue({ available: true });
  });

  it('stops at the first credit-exhaustion 400 and never attempts the remaining jurisdictions', async () => {
    queueJurisdictions(5);
    runDiscoveryForJurisdictionMock
      .mockResolvedValueOnce(okSummary('j0'))
      .mockResolvedValueOnce(okSummary('j1'))
      .mockRejectedValueOnce(creditError());

    await runDiscoverySweep();

    // 2 successes + the failing 3rd = 3. Jurisdictions 4 and 5 never run.
    expect(runDiscoveryForJurisdictionMock).toHaveBeenCalledTimes(3);
  });

  it('sends exactly ONE email, subject marks it ABORTED and names the skipped count', async () => {
    queueJurisdictions(5);
    runDiscoveryForJurisdictionMock
      .mockResolvedValueOnce(okSummary('j0'))
      .mockRejectedValueOnce(creditError());

    await runDiscoverySweep();

    expect(sendEmailMock).toHaveBeenCalledTimes(1);
    const { subject, html } = sendEmailMock.mock.calls[0][0];
    expect(subject).toContain('ABORTED');
    expect(subject).toContain('3 jurisdiction(s) skipped');
    expect(html).toContain('Anthropic account unusable');
    // The three untouched jurisdictions are named so the operator can re-run them.
    expect(html).toContain('Jurisdiction 2, Jurisdiction 3, Jurisdiction 4');
  });

  it('does NOT trip on a non-credit 400 — a jurisdiction-specific bug must not halt the sweep', async () => {
    queueJurisdictions(4);
    runDiscoveryForJurisdictionMock
      .mockRejectedValueOnce(
        makeBodyError(400, 'invalid_request_error', '`web_search` tool use is not supported')
      )
      .mockResolvedValueOnce(okSummary('j1'))
      .mockResolvedValueOnce(okSummary('j2'))
      .mockResolvedValueOnce(okSummary('j3'));

    await runDiscoverySweep();

    expect(runDiscoveryForJurisdictionMock).toHaveBeenCalledTimes(4);
    const { subject } = sendEmailMock.mock.calls[0][0];
    expect(subject).not.toContain('ABORTED');
  });

  it('does NOT trip on a transient 529 — the sweep continues past a retry-exhausted jurisdiction', async () => {
    queueJurisdictions(3);
    runDiscoveryForJurisdictionMock
      .mockRejectedValue(makeAPIError(529, 'overloaded_error', '529 overloaded'))
      .mockResolvedValueOnce(okSummary('j0'));

    await runDiscoverySweep();

    // 529 IS retryable, so the raw call count includes OPS-02 backoff attempts.
    // What matters is that every jurisdiction was still reached and nothing aborted.
    const attempted = new Set(runDiscoveryForJurisdictionMock.mock.calls.map((c) => c[0]));
    expect(attempted).toEqual(new Set(['j0', 'j1', 'j2']));
    expect(sendEmailMock.mock.calls[0][0].subject).not.toContain('ABORTED');
  });

  it('a clean sweep still reports "complete", not aborted', async () => {
    queueJurisdictions(2);
    runDiscoveryForJurisdictionMock
      .mockResolvedValueOnce({ ...okSummary('j0'), uncertainStaged: 2 })
      .mockResolvedValueOnce(okSummary('j1'));

    await runDiscoverySweep();

    expect(sendEmailMock).toHaveBeenCalledTimes(1);
    expect(sendEmailMock.mock.calls[0][0].subject).toContain('complete');
  });
});

// ---------------------------------------------------------------------------
// OPS-06 — per-jurisdiction backoff
//
// Sized from prod (2026-04..07): 161 of 296 completed runs found nothing, and the
// empties concentrate in specific jurisdictions (Richardson 8 runs/0 found, Plano
// 7/0, Blue Ridge 6/0) rather than in a far-out date band. Crucially, 77 completed
// runs DID find candidates while >90 days out — Frisco/Princeton/Nevada first hit
// at 170 days — so backoff must key on observed emptiness, never on date alone.
// ---------------------------------------------------------------------------

describe('leadingEmptyStreak', () => {
  it('counts consecutive zeros from the newest run', () => {
    expect(leadingEmptyStreak([0, 0, 0])).toBe(3);
    expect(leadingEmptyStreak([0, 0])).toBe(2);
  });

  it('a single hit anywhere in the streak resets it — one candidate re-arms weekly scanning', () => {
    expect(leadingEmptyStreak([3, 0, 0])).toBe(0);
    expect(leadingEmptyStreak([0, 5, 0])).toBe(1);
  });

  it('treats a jurisdiction with no completed runs as zero streak (never skipped)', () => {
    expect(leadingEmptyStreak(null)).toBe(0);
    expect(leadingEmptyStreak(undefined)).toBe(0);
    expect(leadingEmptyStreak([])).toBe(0);
  });
});

describe('shouldSkipForBackoff', () => {
  it('skips a proven-empty jurisdiction that is far out and recently probed', () => {
    expect(
      shouldSkipForBackoff({ daysUntilElection: 170, emptyStreak: 3, daysSinceLastRun: 7 })
    ).toBe(true);
  });

  it('NEVER skips inside the filing window, however long the empty streak', () => {
    expect(
      shouldSkipForBackoff({ daysUntilElection: 90, emptyStreak: 99, daysSinceLastRun: 1 })
    ).toBe(false);
    expect(
      shouldSkipForBackoff({ daysUntilElection: 14, emptyStreak: 99, daysSinceLastRun: 1 })
    ).toBe(false);
  });

  it('THE COVERAGE GUARD: does not skip a far-out jurisdiction that is still finding candidates', () => {
    // Frisco at 170 days out with hits — the case a horizon cut would have destroyed.
    expect(
      shouldSkipForBackoff({ daysUntilElection: 170, emptyStreak: 0, daysSinceLastRun: 7 })
    ).toBe(false);
  });

  it('does not skip on partial evidence (streak below threshold)', () => {
    expect(
      shouldSkipForBackoff({ daysUntilElection: 170, emptyStreak: 2, daysSinceLastRun: 7 })
    ).toBe(false);
  });

  it('never skips a brand-new jurisdiction that has never run', () => {
    expect(
      shouldSkipForBackoff({ daysUntilElection: 170, emptyStreak: 0, daysSinceLastRun: null })
    ).toBe(false);
  });

  it('probes rather than staying dark once the probe interval elapses', () => {
    expect(
      shouldSkipForBackoff({ daysUntilElection: 170, emptyStreak: 3, daysSinceLastRun: 27 })
    ).toBe(true);
    expect(
      shouldSkipForBackoff({ daysUntilElection: 170, emptyStreak: 3, daysSinceLastRun: 28 })
    ).toBe(false);
  });
});

describe('runDiscoverySweep — OPS-06 integration', () => {
  beforeEach(() => {
    checkAnthropicAvailabilityMock.mockResolvedValue({ available: true });
  });

  /** Mirrors the real prod mix: one dead jurisdiction, one far-out producer, one near-term. */
  function queueMixedHorizon() {
    poolQueryMock.mockResolvedValueOnce({
      rows: [
        // Richardson: 8 runs, 0 found, 170 days out, probed 7 days ago -> SKIP
        { id: 'richardson', jurisdiction_name: 'Richardson', days_until_election: 170, found_series: [0, 0, 0], days_since_last_run: 7 },
        // Frisco: far out but producing -> SCAN
        { id: 'frisco', jurisdiction_name: 'Frisco', days_until_election: 170, found_series: [19, 0, 0], days_since_last_run: 7 },
        // Blue Ridge: empty but inside the filing window -> SCAN
        { id: 'blueridge', jurisdiction_name: 'Blue Ridge', days_until_election: 60, found_series: [0, 0, 0], days_since_last_run: 7 },
        // Josephine: empty, far out, but overdue for a probe -> SCAN
        { id: 'josephine', jurisdiction_name: 'Josephine', days_until_election: 170, found_series: [0, 0, 0], days_since_last_run: 30 },
      ],
    });
  }

  it('scans only the jurisdictions that warrant it and never calls the agent for backed-off ones', async () => {
    queueMixedHorizon();
    runDiscoveryForJurisdictionMock.mockImplementation(async (id: string) => okSummary(id));

    await runDiscoverySweep();

    const scanned = runDiscoveryForJurisdictionMock.mock.calls.map((c) => c[0]);
    expect(scanned).toEqual(['frisco', 'blueridge', 'josephine']);
  });

  it('reports the backed-off jurisdiction in the summary email when the email is sent anyway', async () => {
    queueMixedHorizon();
    runDiscoveryForJurisdictionMock.mockImplementation(async (id: string) => ({
      ...okSummary(id),
      uncertainStaged: 1,
    }));

    await runDiscoverySweep();

    expect(sendEmailMock).toHaveBeenCalledTimes(1);
    const { html } = sendEmailMock.mock.calls[0][0];
    expect(html).toContain('Not scanned — backoff (1)');
    expect(html).toContain('Richardson');
  });

  it('backoff alone does NOT generate an email on an otherwise-quiet week', async () => {
    poolQueryMock.mockResolvedValueOnce({
      rows: [
        { id: 'richardson', jurisdiction_name: 'Richardson', days_until_election: 170, found_series: [0, 0, 0], days_since_last_run: 7 },
      ],
    });

    await runDiscoverySweep();

    expect(runDiscoveryForJurisdictionMock).not.toHaveBeenCalled();
    expect(sendEmailMock).not.toHaveBeenCalled();
  });
});
