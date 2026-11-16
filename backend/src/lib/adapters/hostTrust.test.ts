import { describe, it, expect, vi, afterEach } from 'vitest';
import { X509Certificate } from 'node:crypto';
import tls from 'node:tls';
import { extraTrustFor, fetchWithHostTrust } from './hostTrust.js';

describe('hostTrust — a missing middle certificate, for one host only', () => {
  it('adds the pinned certificate for www.legislature.ohio.gov on top of Node\'s own roots, and nothing for any other host', () => {
    const ca = extraTrustFor('www.legislature.ohio.gov');
    expect(ca).not.toBeNull();
    expect(ca!.slice(0, tls.rootCertificates.length)).toEqual([...tls.rootCertificates]);
    expect(ca).toHaveLength(tls.rootCertificates.length + 1);
    expect(extraTrustFor('legislature.ohio.gov')).toBeNull();
    expect(extraTrustFor('search-prod.lis.state.oh.us')).toBeNull();
    expect(extraTrustFor('www.legislature.ohio.gov.example.com')).toBeNull();
  });

  it('pins the certificate the runner approved, a CA that a root Node trusts has signed', () => {
    const pem = extraTrustFor('www.legislature.ohio.gov')!.at(-1)!;
    const c = new X509Certificate(pem);
    expect(c.fingerprint256).toBe('65:42:D1:76:BE:D5:0F:19:3C:0C:E2:97:AE:44:EC:D8:A0:A8:6B:EC:2E:DE:68:27:69:34:40:59:B4:E7:85:30');
    expect(c.subject).toContain('CN=Sectigo Public Server Authentication CA OV R36');
    expect(c.ca).toBe(true);
    const roots = tls.rootCertificates.map((p) => new X509Certificate(p));
    expect(roots.some((r) => c.checkIssued(r) && c.verify(r.publicKey))).toBe(true);
  });
});

describe('hostTrust — every other host', () => {
  afterEach(() => vi.unstubAllGlobals());
  it('is fetched with the global fetch, unchanged', async () => {
    const seen: string[] = [];
    vi.stubGlobal('fetch', async (u: string) => { seen.push(u); return new Response('ok'); });
    expect(await (await fetchWithHostTrust('https://search-prod.lis.state.oh.us/api/v2/x')).text()).toBe('ok');
    expect(await (await fetchWithHostTrust('https://le.utah.gov/robots.txt')).text()).toBe('ok');
    expect(seen).toEqual(['https://search-prod.lis.state.oh.us/api/v2/x', 'https://le.utah.gov/robots.txt']);
  });
});
