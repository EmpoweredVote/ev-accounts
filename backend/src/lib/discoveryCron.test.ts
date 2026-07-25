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
vi.mock('./discoveryAgentRunner.js', () => ({
  checkAnthropicAvailability: checkAnthropicAvailabilityMock,
}));

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
