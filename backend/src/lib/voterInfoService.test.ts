import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// Importing the real env.js would run its startup validation with no
// DATABASE_URL in a test environment — mock it per this codebase's convention.
vi.mock('./env.js', () => ({ env: { GOOGLE_CIVIC_API_KEY: 'test-key' } }));
// Geocoding only orders locations nearest-first; failing it keeps the API order.
vi.mock('./geocodingService.js', () => ({ geocodeAddress: vi.fn().mockRejectedValue(new Error('no geocoder')) }));

const ADDRESS = '1 City Hall Sq, Boston, MA 02201';

const ELECTIONS = {
  elections: [
    { id: '2000', name: 'VIP Test Election', electionDay: '2031-12-06', ocdDivisionId: 'ocd-division/country:us' },
    { id: '1001', name: 'Google Test Election (Future)', electionDay: '2033-06-06', ocdDivisionId: 'ocd-division/country:us' },
    { id: '9000', name: 'Louisiana Special', electionDay: '2026-10-25', ocdDivisionId: 'ocd-division/country:us/state:la' },
    { id: '8000', name: '2026 Primary', electionDay: '2026-03-03', ocdDivisionId: 'ocd-division/country:us' },
    { id: '12000', name: '2026 General Midterm Election', electionDay: '2026-11-03', ocdDivisionId: 'ocd-division/country:us' },
  ],
};

const ELECTION_UNKNOWN = {
  error: { code: 400, status: 'INVALID_ARGUMENT', message: 'Election unknown', errors: [{ reason: 'invalid', message: 'Election unknown' }] },
};

const NAMED_ELECTION = {
  election: { id: '12000', name: '2026 General Midterm Election', electionDay: '2026-11-03' },
  state: [{ electionAdministrationBody: { electionInfoUrl: 'https://www.sec.state.ma.us/divisions/elections/', ballotInfoUrl: 'https://www.sec.state.ma.us/wheredoivotema/' } }],
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}

type Route = (url: URL) => Response | undefined;

function stubFetch(route: Route) {
  const fetchMock = vi.fn(async (input: string) => {
    const res = route(new URL(input));
    if (!res) throw new Error(`unexpected fetch ${input}`);
    return res;
  });
  vi.stubGlobal('fetch', fetchMock);
  return fetchMock;
}

// A fresh module per test, so the cached election list never leaks between tests.
async function loadService() {
  vi.resetModules();
  return import('./voterInfoService.js');
}

function calledPaths(fetchMock: ReturnType<typeof stubFetch>): string[] {
  return fetchMock.mock.calls.map(([u]) => {
    const url = new URL(u as string);
    return url.pathname.split('/').pop() + (url.searchParams.get('electionId') ? `?electionId=${url.searchParams.get('electionId')}` : '');
  });
}

describe('getVoterInfo — "Election unknown" retries with the upcoming national election', () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(new Date('2026-10-22T15:00:00Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('names the election and returns the state links when Google cannot match the address', async () => {
    const fetchMock = stubFetch((url) => {
      if (url.pathname.endsWith('/elections')) return json(ELECTIONS);
      if (url.searchParams.get('electionId') === '12000') return json(NAMED_ELECTION);
      return json(ELECTION_UNKNOWN, 400);
    });
    const { getVoterInfo } = await loadService();

    const info = await getVoterInfo(ADDRESS);

    expect(info.status).toBe('ok');
    expect(info.electionName).toBe('2026 General Midterm Election');
    expect(info.electionDate).toBe('2026-11-03');
    expect(info.electionInfoUrl).toBe('https://www.sec.state.ma.us/divisions/elections/');
    expect(info.ballotInfoUrl).toBe('https://www.sec.state.ma.us/wheredoivotema/');
    expect(info.pollingLocations).toEqual([]);
    // Test elections, past elections and single-state elections are all passed over.
    expect(calledPaths(fetchMock)).toEqual(['voterinfo', 'elections', 'voterinfo?electionId=12000']);
  });

  it('does not retry a 400 that is not "Election unknown"', async () => {
    const fetchMock = stubFetch(() => json({ error: { code: 400, message: 'Failed to parse address' } }, 400));
    const { getVoterInfo } = await loadService();

    const info = await getVoterInfo(ADDRESS);

    expect(info.status).toBe('no_election');
    expect(calledPaths(fetchMock)).toEqual(['voterinfo']);
  });

  it('reports no_election when no national election is upcoming', async () => {
    vi.setSystemTime(new Date('2026-11-10T15:00:00Z'));
    const fetchMock = stubFetch((url) => (url.pathname.endsWith('/elections') ? json(ELECTIONS) : json(ELECTION_UNKNOWN, 400)));
    const { getVoterInfo } = await loadService();

    const info = await getVoterInfo(ADDRESS);

    expect(info.status).toBe('no_election');
    expect(calledPaths(fetchMock)).toEqual(['voterinfo', 'elections']);
  });

  it('reports no_election when the election list cannot be fetched', async () => {
    stubFetch((url) => (url.pathname.endsWith('/elections') ? json({}, 503) : json(ELECTION_UNKNOWN, 400)));
    const { getVoterInfo } = await loadService();

    expect((await getVoterInfo(ADDRESS)).status).toBe('no_election');
  });

  it('reports no_election when the retry also finds nothing', async () => {
    stubFetch((url) => (url.pathname.endsWith('/elections') ? json(ELECTIONS) : json(ELECTION_UNKNOWN, 400)));
    const { getVoterInfo } = await loadService();

    expect((await getVoterInfo(ADDRESS)).status).toBe('no_election');
  });

  it('fetches the election list once and reuses it', async () => {
    const fetchMock = stubFetch((url) => {
      if (url.pathname.endsWith('/elections')) return json(ELECTIONS);
      if (url.searchParams.get('electionId') === '12000') return json(NAMED_ELECTION);
      return json(ELECTION_UNKNOWN, 400);
    });
    const { getVoterInfo } = await loadService();

    await getVoterInfo(ADDRESS);
    await getVoterInfo(ADDRESS);

    expect(calledPaths(fetchMock).filter((p) => p === 'elections')).toHaveLength(1);
  });

  it('still answers directly when Google matches the address', async () => {
    const fetchMock = stubFetch(() => json(NAMED_ELECTION));
    const { getVoterInfo } = await loadService();

    const info = await getVoterInfo(ADDRESS);

    expect(info.status).toBe('ok');
    expect(calledPaths(fetchMock)).toEqual(['voterinfo']);
  });
});
