import { readFileSync } from 'node:fs';
import { describe, it, expect } from 'vitest';
import {
  htmlToText,
  extractArticleText,
  looksLikeRealPage,
  MIN_REAL_PAGE_CHARS,
  MIN_ARTICLE_CHARS,
  parseRobotsForAgent,
  isPathAllowed,
  createVerificationFetchSession,
  fetchViaWayback,
  RobotsDisallowedError,
} from './verificationFetch.js';
import { EMPOWERED_VOTE_UA_TOKEN } from './fetchPageContent.js';

const boilerplateFixture = readFileSync(
  new URL('./fixtures/article-with-boilerplate.html', import.meta.url),
  'utf8',
);

describe('htmlToText', () => {
  it('strips tags and collapses whitespace', () => {
    expect(htmlToText('<p>Hello   <b>world</b></p>')).toBe('Hello world');
  });

  it('drops script and style content entirely', () => {
    const html = '<style>.a{color:red}</style><p>Visible</p><script>var x = 1 < 2;</script>';
    expect(htmlToText(html)).toBe('Visible');
  });

  it('drops HTML comments', () => {
    expect(htmlToText('<!-- hidden -->Shown')).toBe('Shown');
  });

  it('decodes common HTML entities', () => {
    expect(htmlToText('<p>a &amp; b &nbsp;&quot;c&quot;</p>')).toBe('a & b "c"');
  });

  it('keeps text that spans inline tags contiguous (space-separated)', () => {
    expect(htmlToText('<b>SB 79</b> would erode local control')).toBe('SB 79 would erode local control');
  });
});

describe('extractArticleText (Readability)', () => {
  const article = extractArticleText(boilerplateFixture, 'https://chronicle.example/levy');

  it('keeps the real article body', () => {
    expect(article).toContain('voted 5 to 2 on Tuesday to approve a new library funding levy');
    expect(article).toContain('This levy keeps our branches open');
    expect(article.length).toBeGreaterThan(MIN_ARTICLE_CHARS);
  });

  it('drops navigation links', () => {
    expect(article).not.toContain('Subscribe now');
    expect(article).not.toContain('Sign in');
  });

  it('drops the cookie / consent banner', () => {
    expect(article.toLowerCase()).not.toContain('cookie');
    expect(article.toLowerCase()).not.toContain('accept all cookies');
  });

  it('drops footer, related-stories and inline scripts', () => {
    expect(article.toLowerCase()).not.toContain('all rights reserved');
    expect(article).not.toContain('Ten things to do this weekend');
    expect(article).not.toContain('dataLayer');
  });

  it('falls back to htmlToText when Readability finds too little text', () => {
    const thin = '<html><body><p>Just a stub.</p></body></html>';
    // Readability cannot reach MIN_ARTICLE_CHARS here, so we get the legacy result.
    expect(extractArticleText(thin, 'https://x.example/p')).toBe(htmlToText(thin));
  });

  it('falls back to htmlToText for non-article (PDF) URLs, boilerplate and all', () => {
    const asPdf = extractArticleText(boilerplateFixture, 'https://chronicle.example/levy.pdf');
    expect(asPdf).toBe(htmlToText(boilerplateFixture));
    // Proof it took the legacy path: legacy keeps the nav text Readability strips.
    expect(asPdf).toContain('Subscribe now');
  });
});

describe('looksLikeRealPage', () => {
  const real = 'x'.repeat(MIN_REAL_PAGE_CHARS + 100);

  it('rejects empty / short pages', () => {
    expect(looksLikeRealPage('')).toBe(false);
    expect(looksLikeRealPage('too short')).toBe(false);
  });

  it('accepts a substantial page with no challenge markers', () => {
    expect(looksLikeRealPage(real)).toBe(true);
  });

  it('rejects a short Cloudflare-style challenge interstitial', () => {
    const challenge = 'Just a moment... Checking your browser before accessing the site. Please enable JavaScript and cookies to continue.';
    expect(looksLikeRealPage(challenge)).toBe(false);
  });

  it('does NOT reject a long real article that merely mentions "enable javascript"', () => {
    const article = 'The council debated zoning reform. '.repeat(80) + ' (To comment, please enable javascript.)';
    expect(article.length).toBeGreaterThan(2000);
    expect(looksLikeRealPage(article)).toBe(true);
  });
});

describe('robots.txt parsing', () => {
  const allowed = (txt: string, path: string) =>
    isPathAllowed(parseRobotsForAgent(txt, EMPOWERED_VOTE_UA_TOKEN), path);

  it('allows everything when there are no rules', () => {
    expect(allowed('', '/anything')).toBe(true);
    expect(allowed('Sitemap: https://x/y.xml', '/anything')).toBe(true);
  });

  it('honours a Disallow that names our bot', () => {
    const txt = 'User-agent: EmpoweredVoteBot\nDisallow: /private';
    expect(allowed(txt, '/private/page')).toBe(false);
    expect(allowed(txt, '/public/page')).toBe(true);
  });

  it('matches our bot case-insensitively and by prefix token', () => {
    expect(allowed('User-agent: empoweredvotebot\nDisallow: /x', '/x')).toBe(false);
    expect(allowed('User-agent: EmpoweredVote\nDisallow: /x', '/x')).toBe(false);
  });

  it('falls back to the * group when no specific group matches', () => {
    const txt = 'User-agent: Googlebot\nDisallow: /\n\nUser-agent: *\nDisallow: /admin';
    expect(allowed(txt, '/admin/x')).toBe(false);
    expect(allowed(txt, '/articles/x')).toBe(true);
  });

  it('prefers the specific group over * (even a permissive specific group)', () => {
    const txt = 'User-agent: *\nDisallow: /\n\nUser-agent: EmpoweredVoteBot\nDisallow:';
    expect(allowed(txt, '/anything')).toBe(true);
  });

  it('longest match wins, and Allow beats Disallow on an equal-length tie', () => {
    const txt = 'User-agent: *\nDisallow: /news\nAllow: /news/local';
    expect(allowed(txt, '/news/national')).toBe(false); // only /news matches
    expect(allowed(txt, '/news/local/story')).toBe(true); // longer Allow wins
    const tie = 'User-agent: *\nDisallow: /a\nAllow: /a';
    expect(allowed(tie, '/a/b')).toBe(true); // equal length → Allow wins
  });

  it('supports the * wildcard and $ end-anchor', () => {
    expect(allowed('User-agent: *\nDisallow: /*.pdf$', '/docs/report.pdf')).toBe(false);
    expect(allowed('User-agent: *\nDisallow: /*.pdf$', '/docs/report.pdf?x=1')).toBe(true);
    expect(allowed('User-agent: *\nDisallow: /a/*/z', '/a/b/z')).toBe(false);
  });
});

describe('createVerificationFetchSession — robots gate', () => {
  it('skips the live tiers and returns robots_disallowed when disallowed and no snapshot', async () => {
    let httpCalls = 0;
    const session = createVerificationFetchSession({
      robotsAllows: async () => false,
      httpFetch: async () => {
        httpCalls++;
        return 'x'.repeat(MIN_REAL_PAGE_CHARS + 100);
      },
      wayback: async () => null, // no archived snapshot
    });

    await expect(session.fetch('https://blocked.example/story')).rejects.toBeInstanceOf(
      RobotsDisallowedError,
    );
    // The live tier must never run for a disallowed path.
    expect(httpCalls).toBe(0);
  });

  it('serves the archived snapshot when disallowed but Wayback has a copy', async () => {
    let httpCalls = 0;
    const archived = 'The council voted 5-2 to approve the levy. '.repeat(20);
    const session = createVerificationFetchSession({
      robotsAllows: async () => false,
      httpFetch: async () => {
        httpCalls++;
        return 'live';
      },
      wayback: async () => archived,
    });

    expect(await session.fetch('https://blocked.example/story')).toBe(archived);
    expect(httpCalls).toBe(0); // still never touched the live site
  });

  it('runs the normal ladder when robots allows', async () => {
    let httpCalls = 0;
    const real = 'y'.repeat(MIN_REAL_PAGE_CHARS + 100);
    const session = createVerificationFetchSession({
      robotsAllows: async () => true,
      httpFetch: async () => {
        httpCalls++;
        return real;
      },
      wayback: async () => null,
    });

    expect(await session.fetch('https://ok.example/story')).toBe(real);
    expect(httpCalls).toBe(1);
  });
});

describe('ladder is browser-free (tier 1 → Wayback)', () => {
  it('reaches Wayback after a tier-1 miss, with no browser rung in between', async () => {
    let httpCalls = 0;
    let waybackCalls = 0;
    const archived = 'The council approved the levy on Tuesday. '.repeat(30);
    // Note: no `render`/browser dep is provided — and none exists on the deps type.
    const session = createVerificationFetchSession({
      robotsAllows: async () => true,
      httpFetch: async () => {
        httpCalls++;
        return 'too short'; // not a real page → must escalate
      },
      wayback: async () => {
        waybackCalls++;
        return archived;
      },
    });

    expect(await session.fetch('https://ok.example/x')).toBe(archived);
    expect(httpCalls).toBe(1);
    expect(waybackCalls).toBe(1);
    // close() must remain callable (a no-op now) for existing callers.
    await expect(session.close()).resolves.toBeUndefined();
  });

  it('the ladder source references no browser (no Playwright / Chromium / renderPage)', () => {
    const src = readFileSync(new URL('./verificationFetch.ts', import.meta.url), 'utf8');
    expect(src).not.toMatch(/playwright/i);
    expect(src).not.toMatch(/chromium/i);
    expect(src).not.toMatch(/renderPage/);
  });
});

describe('fetchViaWayback — /available first, CDX on miss', () => {
  // A minimal fake `fetch` that records requested URLs and answers from a router.
  // Injecting it proves the ORDER (/available first) and that CDX builds the id_
  // raw-snapshot URL as the second chance — without touching the live network.
  function makeFetch(router: (url: string) => Response) {
    const requested: string[] = [];
    const fetchImpl = async (input: string): Promise<Response> => {
      requested.push(String(input));
      return router(String(input));
    };
    return { fetchImpl, requested };
  }

  const CDX_HEADER = ['urlkey', 'timestamp', 'original', 'mimetype', 'statuscode', 'digest', 'length'];
  const cdxRow = (timestamp: string, original: string) =>
    ['gov,example)/x', timestamp, original, 'text/html', '200', 'DIGEST' + timestamp, '1000'];
  const json = (value: unknown) =>
    new Response(JSON.stringify(value), { status: 200, headers: { 'content-type': 'application/json' } });
  const html = (body: string) =>
    new Response(body, { status: 200, headers: { 'content-type': 'text/html' } });
  // Long enough to pass looksLikeRealPage (≥ MIN_REAL_PAGE_CHARS, no challenge markers).
  const realPage = (marker: string) => (marker + ' — the board approved the measure on Tuesday. ').repeat(20);

  it('uses the /available snapshot and does NOT query CDX when /available has a real copy', async () => {
    const url = 'https://www.example-news.test/story';
    const availSnap = 'http://web.archive.org/web/20240101000000/https://www.example-news.test/story';
    const archived = realPage('via the available endpoint');
    const { fetchImpl, requested } = makeFetch((u) => {
      if (u.includes('/wayback/available')) {
        return json({ archived_snapshots: { closest: { status: '200', available: true, url: availSnap, timestamp: '20240101000000' } } });
      }
      if (u === availSnap) return html('<p>' + archived + '</p>');
      // CDX could answer, but it must never be reached when /available is real:
      if (u.includes('/cdx/search/cdx')) return json([CDX_HEADER, cdxRow('20250101000000', url)]);
      return new Response('unexpected: ' + u, { status: 404 });
    });

    const text = await fetchViaWayback(url, { fetchImpl });

    expect(text).toContain('via the available endpoint');
    // /available produced a real page, so the (slower) CDX index is never queried:
    expect(requested.some((u) => u.includes('/cdx/search/cdx'))).toBe(false);
  });

  it('falls back to CDX and fetches the id_ raw snapshot of the newest 200 capture when /available misses', async () => {
    const original = 'https://www.example-news.test/article';
    const article = realPage('recovered by CDX');
    const idUrl = 'https://web.archive.org/web/20240202000000id_/' + original;
    const { fetchImpl, requested } = makeFetch((url) => {
      if (url.includes('/wayback/available')) return json({ archived_snapshots: {} }); // /available miss
      if (url.includes('/cdx/search/cdx')) {
        // Header + two rows, deliberately NOT newest-last, to prove the newest
        // (max-timestamp) row is the one that gets fetched.
        return json([CDX_HEADER, cdxRow('20240202000000', original), cdxRow('20230101000000', original)]);
      }
      if (url === idUrl) return html('<article><p>' + article + '</p></article>');
      return new Response('unexpected: ' + url, { status: 404 });
    });

    const text = await fetchViaWayback(original, { fetchImpl });

    expect(text).toContain('recovered by CDX');
    // It tried /available first, then built the id_ URL from the NEWEST capture:
    expect(requested.some((u) => u.includes('/wayback/available'))).toBe(true);
    expect(requested).toContain(idUrl);
  });

  it('gives CDX its second chance when /available returns a non-real page (challenge/thin)', async () => {
    // /available returns a snapshot that extracts to a short challenge shell —
    // it fails looksLikeRealPage, so CDX must still be tried.
    const original = 'https://www.example-news.test/blocked';
    const availSnap = 'http://web.archive.org/web/20200101000000/' + original;
    const idUrl = 'https://web.archive.org/web/20230303000000id_/' + original;
    const good = realPage('the real archived article');
    const { fetchImpl, requested } = makeFetch((u) => {
      if (u.includes('/wayback/available')) {
        return json({ archived_snapshots: { closest: { status: '200', available: true, url: availSnap, timestamp: '20200101000000' } } });
      }
      if (u === availSnap) return html('<p>Just a moment... checking your browser.</p>'); // thin challenge
      if (u.includes('/cdx/search/cdx')) return json([CDX_HEADER, cdxRow('20230303000000', original)]);
      if (u === idUrl) return html('<article><p>' + good + '</p></article>');
      return new Response('unexpected: ' + u, { status: 404 });
    });

    const text = await fetchViaWayback(original, { fetchImpl });

    expect(text).toContain('the real archived article');
    expect(requested).toContain(idUrl);
  });

  it('still recovers via CDX when the /available request itself errors', async () => {
    const original = 'https://www.example-news.test/story2';
    const article = realPage('recovered despite an /available outage');
    const idUrl = 'https://web.archive.org/web/20210202000000id_/' + original;
    const { fetchImpl } = makeFetch((u) => {
      if (u.includes('/wayback/available')) throw new Error('available 503');
      if (u.includes('/cdx/search/cdx')) return json([CDX_HEADER, cdxRow('20210202000000', original)]);
      if (u === idUrl) return html('<p>' + article + '</p>');
      return new Response('unexpected: ' + u, { status: 404 });
    });

    expect(await fetchViaWayback(original, { fetchImpl })).toContain('recovered despite an /available outage');
  });

  it('returns null when neither /available nor CDX has a usable snapshot', async () => {
    const url = 'https://www.example-news.test/missing';
    const { fetchImpl } = makeFetch((u) => {
      if (u.includes('/wayback/available')) return json({ archived_snapshots: {} }); // no closest
      if (u.includes('/cdx/search/cdx')) return json([CDX_HEADER]); // no captures
      return new Response('unexpected: ' + u, { status: 404 });
    });

    expect(await fetchViaWayback(url, { fetchImpl })).toBeNull();
  });
});

describe('createVerificationFetchSession — congress.gov adapter tier', () => {
  const longPage = 'Affordable Childcare Act. ' + 'grant program expands access to affordable childcare for working families. '.repeat(20);

  it('returns the congress adapter result ahead of tier 1', async () => {
    let httpCalled = false;
    const session = createVerificationFetchSession({
      congressAdapter: async () => longPage,
      robotsAllows: async () => true,
      httpFetch: async () => { httpCalled = true; return 'tier1'; },
      wayback: async () => null,
    });
    const out = await session.fetch('https://www.congress.gov/bill/119th-congress/house-bill/1234');
    expect(out).toBe(longPage);
    expect(httpCalled).toBe(false);
  });

  it('falls through to the ladder when the adapter returns null', async () => {
    let httpCalled = false;
    const session = createVerificationFetchSession({
      congressAdapter: async () => null,
      robotsAllows: async () => true,
      httpFetch: async () => { httpCalled = true; return longPage; },
      wayback: async () => null,
    });
    const out = await session.fetch('https://www.congress.gov/bill/119th-congress/house-bill/1234');
    expect(out).toBe(longPage);
    expect(httpCalled).toBe(true);
  });
});
