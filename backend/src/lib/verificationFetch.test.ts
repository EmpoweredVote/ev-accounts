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
