import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// Importing the real env.js would run its startup validation with no
// DATABASE_URL in a test environment — mock it per this codebase's convention.
vi.mock('./env.js', () => ({ env: { GOOGLE_CIVIC_API_KEY: 'test-key' } }));
// Geocoding only orders locations nearest-first; failing it keeps the API order.
vi.mock('./geocodingService.js', () => ({ geocodeAddress: vi.fn().mockRejectedValue(new Error('no geocoder')) }));
// The county fallback reads the database; by default no county list covers the address.
vi.mock('./localVotingLocations.js', () => ({ lookupLocalVotingLocations: vi.fn().mockResolvedValue(null) }));

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

// ---------------------------------------------------------------------------
// County fallback (CA_0320): Google first, the county's list fills only the gaps.
// ---------------------------------------------------------------------------

const MONROE_ADDRESS = '323 E 6th St, Bloomington, IN 47408';
const ORIGIN = { lat: 39.1683, lng: -86.5306 };

const LOCAL_SET = {
  id: 1,
  countyName: 'Monroe County',
  electionName: '2026 General Election',
  electionDate: '2026-11-03',
  sourceLabel: 'Monroe County Election Board — Official 2026 Poll Site Locations',
  sourceUrl: 'https://www.in.gov/counties/monroe/Departments/clerk-of-court/voter-registration/',
  lastChecked: '2026-10-22',
  lookupUrl: 'https://indianavoters.in.gov/',
};
const ELECTION_CENTRAL = {
  id: 8, kind: 'election_day' as const, name: 'Election Central', address: '501 N Morton St, Bloomington, IN 47404',
  lat: 39.17041, lng: -86.53693, hours: 'Tue, Nov 3: 6 am - 6 pm', startDate: null, endDate: null, precinctCodes: ['BLOOMINGTON 19'],
};
const EARLY = {
  id: 29, kind: 'early_vote' as const, name: 'Election Central (Monroe County Government Center)',
  address: '501 N Morton St, Suite 101, Bloomington, IN 47404', lat: 39.17041, lng: -86.53693,
  hours: 'Mon-Fri through Oct 30: 8 am - 6 pm', startDate: '2026-10-06', endDate: '2026-11-02', precinctCodes: [],
};
const local = (over: Record<string, unknown> = {}) => ({
  set: LOCAL_SET, precinctCode: 'BLOOMINGTON 19', electionDaySite: ELECTION_CENTRAL, nearBoundary: false, earlyVoteSites: [EARLY], ...over,
});

const GOOGLE_HIT = {
  ...NAMED_ELECTION,
  pollingLocations: [{ address: { locationName: 'ELECTION CENTRAL', line1: '501 N MORTON STREET', city: 'BLOOMINGTON', state: 'IN', zip: '47404' }, pollingHours: 'Tue, Nov 3: 6 am - 6 pm', latitude: 39.1708, longitude: -86.5374 }],
  earlyVoteSites: [{ address: { locationName: 'ELECTION OPERATIONS EV', line1: '501 N MORTON STREET', city: 'BLOOMINGTON', state: 'IN', zip: '47404' }, latitude: 39.1708, longitude: -86.5374 }],
};

describe('getVoterInfo — county fallback fills only what Google left empty', () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(new Date('2026-10-22T15:00:00Z'));
  });
  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  async function setup(google: () => Response, localResult: unknown) {
    stubFetch((url) => (url.pathname.endsWith('/elections') ? json(ELECTIONS) : google()));
    const svc = await loadService();
    const geo = await import('./geocodingService.js');
    vi.mocked(geo.geocodeAddress).mockResolvedValue({ ...ORIGIN, matchedAddress: '', state: 'IN', city: 'Bloomington' });
    const loc = await import('./localVotingLocations.js');
    vi.mocked(loc.lookupLocalVotingLocations).mockResolvedValue(localResult as never);
    return { svc, lookup: vi.mocked(loc.lookupLocalVotingLocations) };
  }

  it('shows the county site and early voting when Google returns no locations', async () => {
    const { svc } = await setup(() => json(NAMED_ELECTION), local());
    const info = await svc.getVoterInfo(MONROE_ADDRESS);

    expect(info.pollingLocations).toHaveLength(1);
    expect(info.pollingLocations[0]).toMatchObject({ name: 'Election Central', source: 'county' });
    expect(info.earlyVoteSites[0]).toMatchObject({ startDate: '2026-10-06', endDate: '2026-11-02', source: 'county' });
    expect(info.localSource).toEqual({ label: LOCAL_SET.sourceLabel, url: LOCAL_SET.sourceUrl, lastChecked: '2026-10-22' });
    expect(info.pollingNotice).toBeNull();
    // Google's own election name wins over the county set's.
    expect(info.electionName).toBe('2026 General Midterm Election');
  });

  it('leaves Google untouched when Google answered, and labels nothing as county data', async () => {
    const { svc } = await setup(() => json(GOOGLE_HIT), local());
    const info = await svc.getVoterInfo(MONROE_ADDRESS);

    expect(info.pollingLocations.map((l) => [l.name, l.source])).toEqual([['ELECTION CENTRAL', 'vip']]);
    expect(info.earlyVoteSites.map((l) => l.source)).toEqual(['vip']);
    expect(info.localSource).toBeNull();
  });

  it('near a precinct line: no Election Day site, a notice, and still the early-voting site', async () => {
    const { svc } = await setup(() => json(NAMED_ELECTION), local({ electionDaySite: null, nearBoundary: true }));
    const info = await svc.getVoterInfo(MONROE_ADDRESS);

    expect(info.pollingLocations).toEqual([]);
    expect(info.pollingNotice).toBe('near_precinct_boundary');
    expect(info.earlyVoteSites).toHaveLength(1);
    expect(info.votingLocationFinderUrl).toBe('https://indianavoters.in.gov/');
  });

  it('fills the election name and lookup link when Google is unreachable', async () => {
    const { svc } = await setup(() => json({ error: { status: 'PERMISSION_DENIED' } }, 403), local());
    const info = await svc.getVoterInfo(MONROE_ADDRESS);

    expect(info.status).toBe('unavailable'); // the alarm still sounds
    expect(info.electionName).toBe('2026 General Election');
    expect(info.electionDate).toBe('2026-11-03');
    expect(info.pollingLocations[0].source).toBe('county');
  });

  it('keeps Google\'s answer when the county lookup throws', async () => {
    const { svc, lookup } = await setup(() => json(NAMED_ELECTION), null);
    lookup.mockRejectedValue(new Error('db down'));
    const err = vi.spyOn(console, 'error').mockImplementation(() => {});
    const info = await svc.getVoterInfo(MONROE_ADDRESS);

    expect(info.status).toBe('ok');
    expect(info.pollingLocations).toEqual([]);
    expect(info.localSource).toBeNull();
    err.mockRestore();
  });

  it('outside any county list: unchanged', async () => {
    const { svc } = await setup(() => json(NAMED_ELECTION), null);
    const info = await svc.getVoterInfo(ADDRESS);

    expect(info.pollingLocations).toEqual([]);
    expect(info.localSource).toBeNull();
    expect(info.pollingNotice).toBeNull();
  });
});
