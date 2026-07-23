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
import { runDiscoveryAgent, checkAnthropicAvailability } from './discoveryAgentRunner.js';

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
