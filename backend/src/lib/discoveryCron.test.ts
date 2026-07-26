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
import { isRetryable, withRetry, runDiscoverySweep } from './discoveryCron.js';

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
    rows: Array.from({ length: n }, (_, i) => ({ id: `j${i}`, jurisdiction_name: `Jurisdiction ${i}` })),
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
