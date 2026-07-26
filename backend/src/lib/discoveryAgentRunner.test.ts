import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

// Mock ./env.js with a mutable object so each test can toggle
// ANTHROPIC_API_KEY presence/absence.
const envMock = vi.hoisted(() => ({
  env: { ANTHROPIC_API_KEY: 'test-anthropic-key' as string | undefined },
}));
vi.mock('./env.js', () => envMock);

// Shared vi.fn() the tests drive for client.messages.create.
const createMock = vi.hoisted(() => vi.fn());

// Mock @anthropic-ai/sdk with an importOriginal-style factory that spreads
// the actual module (preserving the real APIError class hierarchy so both
// `err instanceof Anthropic.APIError` and `new Anthropic.APIError(...)`
// construction work), overriding only the default export with a subclass
// whose `messages.create` is the shared mock.
vi.mock('@anthropic-ai/sdk', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@anthropic-ai/sdk')>();

  class MockAnthropic {
    static APIError = actual.APIError;
    messages = { create: createMock };
    constructor(_opts: { apiKey: string }) {}
  }

  return {
    ...actual,
    default: MockAnthropic,
  };
});

import Anthropic from '@anthropic-ai/sdk';
import {
  runDiscoveryAgent,
  checkAnthropicAvailability,
  isAccountUnusableError,
} from './discoveryAgentRunner.js';

const BASE_INPUT = {
  jurisdictionName: 'Los Angeles',
  state: 'CA',
  electionDate: '2026-11-03',
};

function makeResponse(opts: {
  stop_reason: string | null;
  content: any[];
  model?: string;
}) {
  return {
    model: opts.model ?? 'claude-sonnet-4-6',
    stop_reason: opts.stop_reason,
    content: opts.content,
    usage: { input_tokens: 10, output_tokens: 5 },
  };
}

beforeEach(() => {
  createMock.mockReset();
  envMock.env.ANTHROPIC_API_KEY = 'test-anthropic-key';
});

describe('runDiscoveryAgent — OPS-03 no-report exit paths', () => {
  it('end_turn without report_candidates returns zero candidates (does not throw)', async () => {
    createMock.mockResolvedValueOnce(
      makeResponse({ stop_reason: 'end_turn', content: [{ type: 'text', text: 'Nothing found.' }] })
    );

    const result = await runDiscoveryAgent(BASE_INPUT);

    expect(result.candidates).toEqual([]);
    expect(result.stopReason).toBe('end_turn');
  });

  it('pause_turn followed by end_turn with no tool_use still returns zero candidates (does not throw)', async () => {
    createMock
      .mockResolvedValueOnce(
        makeResponse({
          stop_reason: 'pause_turn',
          content: [{ type: 'server_tool_use', name: 'web_search' }],
        })
      )
      .mockResolvedValueOnce(
        makeResponse({ stop_reason: 'end_turn', content: [{ type: 'text', text: 'Still nothing.' }] })
      );

    const result = await runDiscoveryAgent(BASE_INPUT);

    expect(result.candidates).toEqual([]);
    expect(result.stopReason).toBe('end_turn');
    expect(createMock).toHaveBeenCalledTimes(2);
  });
});

describe('checkAnthropicAvailability — OPS-01 canary helper', () => {
  it('missing key returns available:false reason:missing_key without calling the canary', async () => {
    envMock.env.ANTHROPIC_API_KEY = undefined;

    const result = await checkAnthropicAvailability();

    expect(result).toEqual({
      available: false,
      reason: 'missing_key',
      detail: expect.any(String),
    });
    expect(createMock).not.toHaveBeenCalled();
  });

  it.each([401, 402, 403])(
    'unusable credit — canary throwing an Anthropic.APIError with status %d returns available:false reason:unusable',
    async (status) => {
      const apiError = new Anthropic.APIError(
        status,
        { type: 'billing_error' },
        `${status} error from canary`,
        undefined,
        'billing_error' as any
      );
      createMock.mockRejectedValueOnce(apiError);

      const result = await checkAnthropicAvailability();

      expect(result.available).toBe(false);
      if (!result.available) {
        expect(result.reason).toBe('unusable');
        expect(result.detail).not.toContain('test-anthropic-key');
      }
    }
  );

  it('inconclusive canary — a 529 Anthropic.APIError re-throws rather than reporting unusable', async () => {
    const apiError = new Anthropic.APIError(
      529,
      { type: 'overloaded_error' },
      '529 overloaded',
      undefined,
      'overloaded_error' as any
    );
    createMock.mockRejectedValueOnce(apiError);

    await expect(checkAnthropicAvailability()).rejects.toBe(apiError);
  });

  it('inconclusive canary — a plain non-APIError network error re-throws rather than reporting unusable', async () => {
    const networkError = new Error('ECONNRESET');
    createMock.mockRejectedValueOnce(networkError);

    await expect(checkAnthropicAvailability()).rejects.toBe(networkError);
  });

  it('never includes the raw API key in the unusable detail string', async () => {
    const apiError = new Anthropic.APIError(
      402,
      { type: 'billing_error' },
      'Your credit balance is too low',
      undefined,
      'billing_error' as any
    );
    createMock.mockRejectedValueOnce(apiError);

    const result = await checkAnthropicAvailability();

    expect(result.available).toBe(false);
    if (!result.available) {
      expect(result.detail).not.toContain(envMock.env.ANTHROPIC_API_KEY as string);
      expect(result.detail).not.toContain('test-anthropic-key');
    }
  });
});

// ---------------------------------------------------------------------------
// isAccountUnusableError — conclusive account-level classification
//
// Regression cover for the 2026-07-26 sweep: credit exhaustion arrives as a
// generic `400 invalid_request_error`, NOT a 402, so a status-only allowlist of
// [401,402,403] let the sweep drain the account and email per jurisdiction.
// ---------------------------------------------------------------------------

// APIError.makeMessage IGNORES its `message` argument whenever `error` is truthy —
// it stringifies the body instead. So a realistic error must carry its text in the
// BODY, exactly as the wire response does. Passing text as `message` alongside a
// body silently drops it (which is what made the first draft of these tests pass
// vacuously).
function apiError(status: number, type: string, bodyMessage: string) {
  const body = { type: 'error', error: { type, message: bodyMessage } };
  return new Anthropic.APIError(status, body, undefined, undefined, type as any);
}

/** Status-only error with no body detail — for account-level statuses. */
function bareApiError(status: number, type: string) {
  return new Anthropic.APIError(status, { type }, undefined, undefined, type as any);
}

const CREDIT_TEXT =
  'Your credit balance is too low to access the Anthropic API. Please go to Plans & Billing to upgrade or purchase credits.';

describe('isAccountUnusableError', () => {
  it('THE REGRESSION: a 400 invalid_request_error carrying the credit-balance text is conclusive', () => {
    const err = apiError(400, 'invalid_request_error', CREDIT_TEXT);
    // Guard the fixture itself: the credit text must actually reach err.message,
    // mirroring the error_message rows stored in prod.
    expect(err.message).toContain('credit balance is too low');
    expect(isAccountUnusableError(err)).toBe(true);
  });

  it.each([401, 402, 403])('status %d is conclusive regardless of message', (status) => {
    expect(isAccountUnusableError(bareApiError(status, 'billing_error'))).toBe(true);
  });

  it('an ordinary 400 that is NOT about credit stays inconclusive (jurisdiction-specific bug)', () => {
    // Real prod example from the same sweep — must not trip the circuit breaker.
    const webSearch = apiError(
      400,
      'invalid_request_error',
      '`web_search` tool use is not supported by this model'
    );
    expect(isAccountUnusableError(webSearch)).toBe(false);
  });

  it.each([429, 500, 529])('transient status %d is not account-unusable', (status) => {
    expect(isAccountUnusableError(bareApiError(status, 'overloaded_error'))).toBe(false);
  });

  it('non-APIError values are never account-unusable', () => {
    expect(isAccountUnusableError(new Error('ECONNRESET'))).toBe(false);
    expect(isAccountUnusableError(new Error(CREDIT_TEXT))).toBe(false);
    expect(isAccountUnusableError(undefined)).toBe(false);
    expect(isAccountUnusableError('credit balance is too low')).toBe(false);
  });
});

describe('checkAnthropicAvailability — credit-exhaustion 400', () => {
  it('returns {available:false, reason:"unusable"} instead of re-throwing as inconclusive', async () => {
    createMock.mockRejectedValueOnce(apiError(400, 'invalid_request_error', CREDIT_TEXT));

    const result = await checkAnthropicAvailability();

    expect(result.available).toBe(false);
    if (!result.available) {
      expect(result.reason).toBe('unusable');
      expect(result.detail).toContain('credit balance is too low');
      expect(result.detail).not.toContain('test-anthropic-key');
    }
  });

  it('still re-throws a non-credit 400 so the sweep is not falsely skipped', async () => {
    const err = apiError(400, 'invalid_request_error', 'malformed tools array');
    createMock.mockRejectedValueOnce(err);

    await expect(checkAnthropicAvailability()).rejects.toBe(err);
  });
});
