import { describe, it, expect } from 'vitest';
import { htmlToText, looksLikeRealPage, MIN_REAL_PAGE_CHARS } from './verificationFetch.js';

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
