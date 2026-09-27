import { describe, it, expect, vi, afterEach } from 'vitest';
import { robotsAllows, clearRobotsCache, KNOWN_DISALLOW_HOSTS } from './verificationFetch.js';

// Ruling 2026-09-27 (Chris Andrews): fail CLOSED for a site known to disallow automated fetching when
// its robots.txt cannot be read; every other site keeps the fail-open rule (decision 0003).
describe('robotsAllows — known-disallow hosts fail closed', () => {
  afterEach(() => { vi.unstubAllGlobals(); clearRobotsCache(); });
  const stub = (impl: () => Promise<Response>) => vi.stubGlobal('fetch', vi.fn(impl));

  it('lists the two sites whose robots.txt disallows everything', () => {
    expect(KNOWN_DISALLOW_HOSTS.has('leginfo.legislature.ca.gov')).toBe(true);
    expect(KNOWN_DISALLOW_HOSTS.has('apps.azleg.gov')).toBe(true);
  });
  it('a known-disallow host whose robots.txt times out is NOT allowed', async () => {
    stub(() => Promise.reject(new Error('timeout')));
    expect(await robotsAllows('https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=1')).toBe(false);
  });
  it('a known-disallow host whose robots.txt answers 403 is NOT allowed', async () => {
    stub(() => Promise.resolve(new Response('forbidden', { status: 403 })));
    expect(await robotsAllows('https://apps.azleg.gov/BillStatus/BillOverview')).toBe(false);
  });
  it('any other host still fails open', async () => {
    stub(() => Promise.reject(new Error('timeout')));
    expect(await robotsAllows('https://le.utah.gov/~2021/bills/hbillenr/HB0017.htm')).toBe(true);
  });
  it('a known-disallow host whose robots.txt loads is judged by its rules', async () => {
    stub(() => Promise.resolve(new Response('User-agent: *\nDisallow: /private/\n', { status: 200 })));
    expect(await robotsAllows('https://leginfo.legislature.ca.gov/faces/x')).toBe(true);
    expect(await robotsAllows('https://leginfo.legislature.ca.gov/private/x')).toBe(false);
  });
});
