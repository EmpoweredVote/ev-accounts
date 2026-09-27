import { describe, it, expect } from 'vitest';
import {
  fetchRawHtml,
  fetchRawHtmlViaHttp,
  fetchRawHtmlViaWayback,
  waybackRawCaptureUrl,
  htmlToText,
  RobotsDisallowedError,
  NotHtmlError,
  MIN_REAL_PAGE_CHARS,
  type RawHtmlPage,
} from './verificationFetch.js';

// A struck-through bill page: long enough to pass looksLikeRealPage once stripped.
const billHtml = (marker: string) =>
  '<html><body><p>' + (marker + ' Section 1. The fee is <strike>ten</strike> twenty dollars. ').repeat(20) + '</p></body></html>';
const live = (html: string): RawHtmlPage => ({ html, via: 'live', fetchedUrl: 'https://bills.example/HB1.htm' });
const archived = (html: string): RawHtmlPage => ({ html, via: 'wayback', fetchedUrl: 'https://web.archive.org/web/20260101000000id_/https://bills.example/HB1.htm' });
const URL_ = 'https://bills.example/HB1.htm';

describe('fetchRawHtml — the raw-HTML ladder', () => {
  it('returns the live HTML UNCONVERTED (markup intact) when the live page is real', async () => {
    let waybackCalls = 0;
    const page = await fetchRawHtml(URL_, {
      robotsAllows: async () => true,
      httpFetch: async () => live(billHtml('live')),
      wayback: async () => { waybackCalls++; return null; },
    });
    expect(page.via).toBe('live');
    expect(page.html).toContain('<strike>ten</strike>');
    expect(waybackCalls).toBe(0);
  });

  it('falls back to the Wayback raw capture when the live fetch fails', async () => {
    const page = await fetchRawHtml(URL_, {
      robotsAllows: async () => true,
      httpFetch: async () => { throw new Error('HTTP 403'); },
      wayback: async () => archived(billHtml('archived')),
    });
    expect(page.via).toBe('wayback');
    expect(page.html).toContain('<strike>ten</strike>');
  });

  it('falls back to Wayback when the live page is a challenge shell', async () => {
    const page = await fetchRawHtml(URL_, {
      robotsAllows: async () => true,
      httpFetch: async () => live('<html><body>Just a moment… checking your browser</body></html>'),
      wayback: async () => archived(billHtml('archived')),
    });
    expect(page.via).toBe('wayback');
  });

  it('never touches the live site when robots disallows, and serves the archive', async () => {
    let httpCalls = 0;
    const page = await fetchRawHtml(URL_, {
      robotsAllows: async () => false,
      httpFetch: async () => { httpCalls++; return live(billHtml('live')); },
      wayback: async () => archived(billHtml('archived')),
    });
    expect(page.via).toBe('wayback');
    expect(httpCalls).toBe(0);
  });

  it('throws RobotsDisallowedError when robots disallows and there is no archived copy', async () => {
    await expect(fetchRawHtml(URL_, {
      robotsAllows: async () => false,
      httpFetch: async () => live(billHtml('live')),
      wayback: async () => null,
    })).rejects.toBeInstanceOf(RobotsDisallowedError);
  });

  it('treats a robots refusal on the redirect target like a refusal on the URL', async () => {
    await expect(fetchRawHtml(URL_, {
      robotsAllows: async () => true,
      httpFetch: async () => ({ robotsDisallowed: true }),
      wayback: async () => null,
    })).rejects.toBeInstanceOf(RobotsDisallowedError);
  });

  it('stops on a non-HTML live page — an archived PDF is still a PDF', async () => {
    let waybackCalls = 0;
    await expect(fetchRawHtml(URL_, {
      robotsAllows: async () => true,
      httpFetch: async () => { throw new NotHtmlError(URL_, 'application/pdf'); },
      wayback: async () => { waybackCalls++; return archived(billHtml('archived')); },
    })).rejects.toBeInstanceOf(NotHtmlError);
    expect(waybackCalls).toBe(0);
  });

  it('names the live failure when every tier fails', async () => {
    await expect(fetchRawHtml(URL_, {
      robotsAllows: async () => true,
      httpFetch: async () => { throw new Error('HTTP 404'); },
      wayback: async () => null,
    })).rejects.toThrow('HTTP 404 (no archived copy)');
  });

  it('returns the longer thin page best-effort when neither tier is real', async () => {
    const page = await fetchRawHtml(URL_, {
      robotsAllows: async () => true,
      httpFetch: async () => live('<p>short</p>'),
      wayback: async () => archived('<p>a little longer text</p>'),
    });
    expect(page.via).toBe('wayback');
  });
});

describe('fetchRawHtmlViaHttp', () => {
  const res = (body: string, ctype: string, status = 200) =>
    new Response(body, { status, headers: { 'content-type': ctype } });

  it('returns the body unconverted for an HTML response', async () => {
    const out = await fetchRawHtmlViaHttp(URL_, { fetchImpl: async () => res(billHtml('x'), 'text/html; charset=utf-8'), robotsAllows: async () => true });
    expect(out).toMatchObject({ via: 'live' });
    expect((out as RawHtmlPage).html).toContain('<strike>');
  });

  it('throws NotHtmlError for a non-HTML body', async () => {
    await expect(fetchRawHtmlViaHttp(URL_, { fetchImpl: async () => res('%PDF-1.7', 'application/pdf'), robotsAllows: async () => true }))
      .rejects.toBeInstanceOf(NotHtmlError);
  });

  it('throws HTTP <status> on a non-2xx', async () => {
    await expect(fetchRawHtmlViaHttp(URL_, { fetchImpl: async () => res('', 'text/html', 503), robotsAllows: async () => true }))
      .rejects.toThrow('HTTP 503');
  });

  it("checks the redirect target origin's robots.txt before using its body", async () => {
    const redirected = res(billHtml('x'), 'text/html');
    Object.defineProperty(redirected, 'url', { value: 'https://other.example/HB1.htm' });
    const asked: string[] = [];
    const out = await fetchRawHtmlViaHttp(URL_, {
      fetchImpl: async () => redirected,
      robotsAllows: async (u) => { asked.push(u); return false; },
    });
    expect(out).toEqual({ robotsDisallowed: true });
    expect(asked).toEqual(['https://other.example/HB1.htm']);
  });
});

describe('waybackRawCaptureUrl', () => {
  it('rewrites a wrapped capture URL to its raw id_ form', () => {
    expect(waybackRawCaptureUrl('http://web.archive.org/web/20240101000000/https://bills.example/HB1.htm'))
      .toBe('https://web.archive.org/web/20240101000000id_/https://bills.example/HB1.htm');
  });
  it('replaces an existing modifier rather than stacking a second one', () => {
    expect(waybackRawCaptureUrl('https://web.archive.org/web/20240101000000if_/https://bills.example/HB1.htm'))
      .toBe('https://web.archive.org/web/20240101000000id_/https://bills.example/HB1.htm');
  });
  it('returns null for something that is not a capture URL', () => {
    expect(waybackRawCaptureUrl('https://bills.example/HB1.htm')).toBeNull();
  });
});

describe('fetchRawHtmlViaWayback — /available (as id_) first, CDX on miss', () => {
  const json = (v: unknown) => new Response(JSON.stringify(v), { status: 200, headers: { 'content-type': 'application/json' } });
  const html = (b: string) => new Response(b, { status: 200, headers: { 'content-type': 'text/html' } });
  const CDX_HEADER = ['urlkey', 'timestamp', 'original', 'mimetype', 'statuscode', 'digest', 'length'];

  it('fetches the /available capture in id_ form — never the wrapped copy with the archive toolbar', async () => {
    const wrapped = 'http://web.archive.org/web/20240101000000/' + URL_;
    const raw = 'https://web.archive.org/web/20240101000000id_/' + URL_;
    const requested: string[] = [];
    const page = await fetchRawHtmlViaWayback(URL_, {
      fetchImpl: async (u) => {
        requested.push(u);
        if (u.includes('/wayback/available')) return json({ archived_snapshots: { closest: { status: '200', url: wrapped } } });
        if (u === raw) return html(billHtml('archived'));
        if (u === wrapped) return html('<div id="wm-ipp">toolbar</div>' + billHtml('archived'));
        return new Response('unexpected', { status: 404 });
      },
    });
    expect(page).toMatchObject({ via: 'wayback', fetchedUrl: raw });
    expect(page!.html).toContain('<strike>ten</strike>');
    expect(requested).not.toContain(wrapped);
    expect(requested.some((u) => u.includes('/cdx/'))).toBe(false);
  });

  it('falls back to the newest CDX capture when /available misses', async () => {
    const raw = 'https://web.archive.org/web/20250202000000id_/' + URL_;
    const page = await fetchRawHtmlViaWayback(URL_, {
      fetchImpl: async (u) => {
        if (u.includes('/wayback/available')) return json({ archived_snapshots: {} });
        if (u.includes('/cdx/search/cdx')) {
          return json([CDX_HEADER,
            ['k', '20250202000000', URL_, 'text/html', '200', 'D2', '1'],
            ['k', '20230101000000', URL_, 'text/html', '200', 'D1', '1']]);
        }
        if (u === raw) return html(billHtml('cdx'));
        return new Response('unexpected', { status: 404 });
      },
    });
    expect(page).toMatchObject({ fetchedUrl: raw });
  });

  it('rejects a capture that is not HTML', async () => {
    const wrapped = 'http://web.archive.org/web/20240101000000/' + URL_;
    const page = await fetchRawHtmlViaWayback(URL_, {
      fetchImpl: async (u) => {
        if (u.includes('/wayback/available')) return json({ archived_snapshots: { closest: { status: '200', url: wrapped } } });
        if (u.includes('/cdx/search/cdx')) return json([CDX_HEADER]);
        return new Response('%PDF-1.7', { status: 200, headers: { 'content-type': 'application/pdf' } });
      },
    });
    expect(page).toBeNull();
  });

  it('the fixture page passes the real-page gate (positive control)', () => {
    expect(htmlToText(billHtml('x')).length).toBeGreaterThan(MIN_REAL_PAGE_CHARS);
  });
});
