import { describe, it, expect } from 'vitest';
import { fetchMaRollCallText, renderMaRollCallBytes } from './maLegislatureAdapter.js';

const URL_135 = 'https://malegislature.gov/RollCall/193/HouseRollCall135.pdf';

describe('fetchMaRollCallText', () => {
  it('never fetches a URL that is not a House roll-call PDF', async () => {
    let called = false;
    const fetchImpl = async () => { called = true; return new Response('x'); };
    expect(await fetchMaRollCallText('https://malegislature.gov/Bills/193/H4885', { fetchImpl })).toBeNull();
    expect(called).toBe(false);
  });

  it('sends the given user-agent and returns null on an HTTP error', async () => {
    let ua = '';
    const fetchImpl = async (_u: string, init?: RequestInit) => {
      ua = (init?.headers as Record<string, string>)['user-agent'];
      return new Response('gone', { status: 404 });
    };
    expect(await fetchMaRollCallText(URL_135, { fetchImpl, userAgent: 'EmpoweredVoteBot/1.0' })).toBeNull();
    expect(ua).toBe('EmpoweredVoteBot/1.0');
  });

  it('returns null for a body that is not a PDF (an HTML error page served as 200)', async () => {
    const fetchImpl = async () => new Response('<html>Server error</html>', { status: 200 });
    expect(await fetchMaRollCallText(URL_135, { fetchImpl })).toBeNull();
  });

  it('returns null, never throws, when the network fails', async () => {
    const fetchImpl = async () => { throw new Error('ECONNRESET'); };
    expect(await fetchMaRollCallText(URL_135, { fetchImpl })).toBeNull();
  });
});

describe('renderMaRollCallBytes', () => {
  it('refuses bytes that are not a PDF', async () => {
    expect(await renderMaRollCallBytes(new TextEncoder().encode('not a pdf'), URL_135)).toBeNull();
  });
});
