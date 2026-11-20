import { describe, it, expect, vi, afterEach } from 'vitest';
import { commonsApi, CommonsBlockedError, USER_AGENT } from './commonsClient.js';

function stubFetch(responses: Array<{ status: number; body: string }>) {
  let i = 0;
  const spy = vi.fn(async () => {
    const r = responses[Math.min(i++, responses.length - 1)];
    return { status: r.status, ok: r.status >= 200 && r.status < 300, text: async () => r.body } as Response;
  });
  vi.stubGlobal('fetch', spy);
  return spy;
}
const JSON_OK = JSON.stringify({ query: { pages: [] } });

afterEach(() => { vi.unstubAllGlobals(); });

describe('commonsApi', () => {
  it('retries on 429 and succeeds', async () => {
    const f = stubFetch([{ status: 429, body: '' }, { status: 429, body: '' }, { status: 200, body: JSON_OK }]);
    await expect(commonsApi({ action: 'query' }, { backoffMs: 0 })).resolves.toEqual({ query: { pages: [] } });
    expect(f).toHaveBeenCalledTimes(3);
  });

  it('throws CommonsBlockedError when a 200 body is a WAF challenge, not JSON', async () => {
    stubFetch([{ status: 200, body: '<html><body>Checking your browser</body></html>' }]);
    await expect(commonsApi({ action: 'query' }, { backoffMs: 0 })).rejects.toBeInstanceOf(CommonsBlockedError);
  });

  it('gives up after 4 attempts and throws, never returning an empty result', async () => {
    const f = stubFetch([{ status: 503, body: '' }]);
    await expect(commonsApi({ action: 'query' }, { backoffMs: 0 })).rejects.toThrow();
    expect(f).toHaveBeenCalledTimes(4);
  });
});

describe('USER_AGENT', () => {
  it('names a client and a purpose', () => {
    expect(USER_AGENT).toMatch(/EmpoweredVote/);
  });
  it('carries no personal contact details', () => {
    expect(USER_AGENT).not.toMatch(/@/);
  });
});

describe('commonsApi — a 200 that parses but carries an error', () => {
  it('throws rather than returning an error object that reads downstream as "no files"', async () => {
    stubFetch([{ status: 200, body: JSON.stringify({ error: { code: 'ratelimited', info: 'slow down' } }) }]);
    await expect(commonsApi({ action: 'query' }, { backoffMs: 0 })).rejects.toThrow(/ratelimited/);
  });
});
