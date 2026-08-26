import { describe, it, expect } from 'vitest';
import { validateRedirectUrl, getAppNameFromRedirect } from './redirect';

/**
 * These cases mirror the hand-check list in
 * ev-cto/tasks/2026-08-26-app-redirect-allowlist.md.
 *
 * The same function is duplicated at app/src/lib/redirect.ts, where the leaked
 * value would be the member's access token. app has no test runner, so that
 * copy is covered by hand in the dev server — keep the two files identical.
 */
describe('validateRedirectUrl', () => {
  describe('accepts', () => {
    it('an https subdomain of empowered.vote', () => {
      expect(validateRedirectUrl('https://essentials.empowered.vote')).toBe(
        'https://essentials.empowered.vote'
      );
    });

    it('the https apex domain', () => {
      expect(validateRedirectUrl('https://empowered.vote/')).toBe('https://empowered.vote/');
    });

    it('a deep subdomain', () => {
      expect(validateRedirectUrl('https://a.b.empowered.vote/path?q=1')).toBe(
        'https://a.b.empowered.vote/path?q=1'
      );
    });

    it('an uppercase hostname, which the URL parser normalises', () => {
      expect(validateRedirectUrl('https://APP.EMPOWERED.VOTE/')).toBe('https://APP.EMPOWERED.VOTE/');
    });
  });

  describe('rejects', () => {
    it('an unrelated https host', () => {
      expect(validateRedirectUrl('https://example.com')).toBeNull();
    });

    it('http on a trusted host — protocol downgrade', () => {
      expect(validateRedirectUrl('http://app.empowered.vote')).toBeNull();
    });

    it('a lookalike host that only starts with the trusted name', () => {
      // The case a hostname check written with `includes`/`startsWith` lets through.
      expect(validateRedirectUrl('https://empowered.vote.example.com')).toBeNull();
    });

    it('a userinfo trick that puts the trusted name before the @', () => {
      expect(validateRedirectUrl('https://empowered.vote@example.com')).toBeNull();
    });

    it('a suffix trick with no dot separator', () => {
      expect(validateRedirectUrl('https://notempowered.vote')).toBeNull();
    });

    it('the javascript: scheme', () => {
      expect(validateRedirectUrl('javascript:alert(1)')).toBeNull();
    });

    it('a data: URL', () => {
      expect(validateRedirectUrl('data:text/html,<script>alert(1)</script>')).toBeNull();
    });

    it('a protocol-relative URL', () => {
      expect(validateRedirectUrl('//example.com')).toBeNull();
    });

    it('a relative path', () => {
      expect(validateRedirectUrl('/dashboard')).toBeNull();
    });

    it('a malformed value', () => {
      expect(validateRedirectUrl('https://')).toBeNull();
    });

    it('an empty string', () => {
      expect(validateRedirectUrl('')).toBeNull();
    });

    it('null and undefined — the no-parameter case', () => {
      expect(validateRedirectUrl(null)).toBeNull();
      expect(validateRedirectUrl(undefined)).toBeNull();
    });
  });
});

describe('getAppNameFromRedirect', () => {
  it('names a subdomain', () => {
    expect(getAppNameFromRedirect('https://essentials.empowered.vote')).toBe('Essentials');
  });

  it('falls back for the apex domain', () => {
    expect(getAppNameFromRedirect('https://empowered.vote')).toBe('Empowered Vote');
  });

  it('falls back for a malformed URL', () => {
    expect(getAppNameFromRedirect('not a url')).toBe('Empowered Vote');
  });
});
