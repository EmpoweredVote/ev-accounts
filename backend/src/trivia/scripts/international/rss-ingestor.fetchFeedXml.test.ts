import { describe, it, expect, vi, afterEach } from 'vitest';
import { fetchFeedXml } from './rss-ingestor.js';

afterEach(() => vi.unstubAllGlobals());

describe('fetchFeedXml', () => {
  it('sends the headers rss-parser sent, and returns the body', async () => {
    const fetchMock = vi.fn().mockResolvedValue(new Response('<rss/>', { status: 200 }));
    vi.stubGlobal('fetch', fetchMock);

    await expect(fetchFeedXml('https://example.org/feed')).resolves.toBe('<rss/>');

    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe('https://example.org/feed');
    expect(init.headers).toEqual({ 'User-Agent': 'rss-parser', Accept: 'application/rss+xml' });
    expect(init.redirect).toBe('follow');
    expect(init.signal).toBeInstanceOf(AbortSignal);
  });

  it('rejects a non-2xx status with the message rss-parser used', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response('gone', { status: 404 })));
    await expect(fetchFeedXml('https://example.org/feed')).rejects.toThrow('Status code 404');
  });
});
