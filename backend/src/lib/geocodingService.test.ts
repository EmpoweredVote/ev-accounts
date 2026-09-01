import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

// Mock the shared cache so no test touches Redis and each one starts cold. Uses
// vi.hoisted() because the vi.mock factory is hoisted above these declarations.
const { cacheGetMock, cacheSetMock } = vi.hoisted(() => ({
  cacheGetMock: vi.fn(),
  cacheSetMock: vi.fn(),
}));

vi.mock('./cache.js', () => ({
  cache: {
    get: (...args: unknown[]) => cacheGetMock(...args),
    set: (...args: unknown[]) => cacheSetMock(...args),
    del: vi.fn(),
  },
}));

import { geocodeAddress, GeocodingError } from './geocodingService.js';

// ---------------------------------------------------------------------------
// Response builders
// ---------------------------------------------------------------------------

function censusResponse(matches: unknown[]) {
  return {
    ok: true,
    status: 200,
    json: async () => ({ result: { addressMatches: matches } }),
  };
}

const CENSUS_MATCH = {
  matchedAddress: '2 LONG SHOALS RD, ARDEN, NC, 28704',
  coordinates: { x: -82.5401, y: 35.4712 },
  tigerLine: { tigerLineId: '1', side: 'L' },
  addressComponents: { zip: '28704', streetName: 'LONG SHOALS', city: 'ARDEN', state: 'NC' },
};

/** TIGERweb ZCTA extent response — the real 28704 envelope. */
function zctaResponse() {
  return {
    ok: true,
    status: 200,
    json: async () => ({
      extent: {
        xmin: -82.66251599990272,
        ymin: 35.41611400024333,
        xmax: -82.47586499968763,
        ymax: 35.50190800021025,
      },
    }),
  };
}

/** A National Address Database feature, shaped as the live service returns them. */
function nadFeature(
  street: string,
  overrides: { addNumber?: number; full?: string; x?: number; y?: number } = {},
) {
  return {
    attributes: {
      Add_Number: overrides.addNumber ?? 525,
      St_Name: street,
      StNam_Full: overrides.full ?? `${street} Lane`,
      Post_City: 'ARDEN',
      State: 'NC',
      Zip_Code: '28704',
    },
    geometry: { x: overrides.x ?? -82.57618574514215, y: overrides.y ?? 35.47262960921673 },
  };
}

function nadResponse(features: unknown[]) {
  return { ok: true, status: 200, json: async () => ({ features }) };
}

// The address that motivated the fallback, exactly as it was typed at signup —
// lowercase, no commas. Verified 2026-09-01: 0 Census matches, 1 NAD record.
const ARDEN = '525 citrine lane arden nc 28704';

function fetchMock() {
  return fetch as unknown as ReturnType<typeof vi.fn>;
}

function urlOf(call: number): string {
  return String(fetchMock().mock.calls[call]![0]);
}

/** A county GeocodeServer candidate, shaped as Buncombe's actually returns them. */
function locatorCandidate(
  overrides: {
    addrType?: string;
    addNum?: string;
    stName?: string;
    score?: number;
    x?: number;
    y?: number;
  } = {},
) {
  return {
    address: '525 CITRINE LN',
    score: overrides.score ?? 100,
    location: { x: overrides.x ?? -82.57618578271, y: overrides.y ?? 35.472629603687 },
    attributes: {
      Addr_type: overrides.addrType ?? 'PointAddress',
      AddNum: overrides.addNum ?? '525',
      StName: overrides.stName ?? 'CITRINE',
      StType: 'LN',
      Match_addr: '525 CITRINE LN',
      City: '',
      Region: '',
      Postal: '',
    },
  };
}

function locatorResponse(candidates: unknown[]) {
  return { ok: true, status: 200, json: async () => ({ candidates }) };
}

/**
 * Census miss -> county locator returns nothing -> ZCTA extent -> NAD features.
 * ZIP 28704 matches a registered locator, so that call always happens first.
 */
function stubFallback(features: unknown[]) {
  fetchMock()
    .mockResolvedValueOnce(censusResponse([]))
    .mockResolvedValueOnce(zctaResponse())
    .mockResolvedValueOnce(locatorResponse([]))
    .mockResolvedValueOnce(nadResponse(features));
}

/**
 * Census miss -> the locator returns `candidate` -> NAD holds nothing.
 *
 * For the tests that assert a locator answer is REFUSED. The NAD leg is stubbed
 * empty on purpose: rejecting the locator must fall through, so the only way the
 * call can end in ADDRESS_NOT_FOUND is if the locator's answer was genuinely
 * discarded rather than quietly accepted.
 */
function stubCensusThenLocator(candidate: unknown) {
  fetchMock()
    .mockResolvedValueOnce(censusResponse([]))
    .mockResolvedValueOnce(zctaResponse())
    .mockResolvedValueOnce(locatorResponse([candidate]))
    .mockResolvedValueOnce(nadResponse([]));
}

describe('geocodeAddress — National Address Database fallback on a Census miss', () => {
  beforeEach(() => {
    cacheGetMock.mockReset().mockResolvedValue(null);
    cacheSetMock.mockReset().mockResolvedValue(undefined);
    vi.stubGlobal('fetch', vi.fn());
    vi.spyOn(console, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it('returns the Census match and never calls the fallback when Census resolves', async () => {
    fetchMock().mockResolvedValueOnce(censusResponse([CENSUS_MATCH]));

    const result = await geocodeAddress('2 Long Shoals Rd, Arden, NC 28704');

    expect(result).toEqual({
      lat: 35.4712,
      lng: -82.5401,
      matchedAddress: '2 LONG SHOALS RD, ARDEN, NC, 28704',
      state: 'NC',
      city: 'ARDEN',
    });
    expect(fetchMock()).toHaveBeenCalledTimes(1);
    expect(urlOf(0)).toContain('geocoding.geo.census.gov');
  });

  it('falls back to the NAD on a Census miss and returns the authoritative point', async () => {
    stubFallback([nadFeature('CITRINE')]);

    const result = await geocodeAddress(ARDEN);

    expect(result).toEqual({
      lat: 35.47262960921673,
      lng: -82.57618574514215,
      matchedAddress: '525 CITRINE Lane, ARDEN, NC 28704',
      state: 'NC',
      city: 'ARDEN',
    });
    expect(fetchMock()).toHaveBeenCalledTimes(4);
    expect(urlOf(1)).toContain('tigerweb.geo.census.gov');
    expect(urlOf(2)).toContain('gis.buncombecounty.org');
    expect(urlOf(3)).toContain('National_Address_Database');
  });

  it('scopes the NAD query by house number, ZIP, and the ZIP envelope', async () => {
    stubFallback([nadFeature('CITRINE')]);

    await geocodeAddress(ARDEN);

    // The hosted NAD view rejects a purely attribute query, so the envelope is
    // load-bearing, not an optimisation.
    const nadUrl = decodeURIComponent(urlOf(3));
    expect(nadUrl).toContain('Add_Number=525');
    expect(nadUrl).toContain("Zip_Code='28704'");
    expect(nadUrl).toContain('esriGeometryEnvelope');
    expect(nadUrl).toContain('-82.66251599990272,35.41611400024333');
  });

  it('matches a multi-word street name', async () => {
    stubFallback([nadFeature('OLD SHOALS', { full: 'OLD SHOALS Lane' })]);

    await expect(geocodeAddress('525 old shoals lane arden nc 28704')).resolves.toMatchObject({
      matchedAddress: '525 OLD SHOALS Lane, ARDEN, NC 28704',
    });
  });

  it('caches a fallback hit so the second lookup costs nothing', async () => {
    stubFallback([nadFeature('CITRINE')]);

    await geocodeAddress(ARDEN);

    // Two writes: the ZIP envelope (long-lived) and the geocode itself (24h).
    const geocodeWrite = cacheSetMock.mock.calls.find(([k]) => String(k).startsWith('geocode:'));
    expect(geocodeWrite).toBeDefined();
    expect(geocodeWrite![1]).toMatchObject({ lat: 35.47262960921673, state: 'NC' });
    expect(geocodeWrite![2]).toBe(86400);
  });

  it('caches the ZIP envelope separately, since ZIP extents do not move', async () => {
    stubFallback([nadFeature('CITRINE')]);

    await geocodeAddress(ARDEN);

    const zctaWrite = cacheSetMock.mock.calls.find(([k]) => String(k) === 'zcta:v1:28704');
    expect(zctaWrite).toBeDefined();
    expect(zctaWrite![2]).toBe(60 * 60 * 24 * 30);
  });

  it('reuses a cached ZIP envelope instead of re-querying TIGERweb', async () => {
    cacheGetMock.mockImplementation(async (key: string) =>
      key === 'zcta:v1:28704'
        ? { xmin: -82.66, ymin: 35.41, xmax: -82.47, ymax: 35.5 }
        : null,
    );
    fetchMock()
      .mockResolvedValueOnce(censusResponse([]))
      .mockResolvedValueOnce(locatorResponse([]))
      .mockResolvedValueOnce(nadResponse([nadFeature('CITRINE')]));

    await expect(geocodeAddress(ARDEN)).resolves.toMatchObject({ state: 'NC' });

    // No TIGERweb call — the envelope came from cache.
    expect(fetchMock()).toHaveBeenCalledTimes(3);
    expect(urlOf(1)).toContain('gis.buncombecounty.org');
    expect(urlOf(2)).toContain('National_Address_Database');
  });

  // ---- County locators, tried before the national database -----------------
  // Measured from Render 2026-09-01: the county server answered in 421-644ms
  // across six samples while the NAD ranged 1143-16868ms and blew the budget
  // twice. Fast path first, national database only when it misses.

  it('answers from the county locator without ever reaching the NAD', async () => {
    fetchMock()
      .mockResolvedValueOnce(censusResponse([]))
      .mockResolvedValueOnce(zctaResponse())
      .mockResolvedValueOnce(locatorResponse([locatorCandidate()]));

    const result = await geocodeAddress(ARDEN);

    expect(result).toEqual({
      lat: 35.472629603687,
      lng: -82.57618578271,
      matchedAddress: '525 CITRINE LN, NC 28704',
      state: 'NC',
      // These servers return City empty; the Census path would have supplied it,
      // but the Census already failed, so there is nothing to lose here.
      city: '',
    });
    // Census, envelope, locator. The NAD is never reached.
    expect(fetchMock()).toHaveBeenCalledTimes(3);
    expect(urlOf(2)).toContain('gis.buncombecounty.org');
  });

  it('sends the raw address to the locator, which needs no parsing', async () => {
    fetchMock()
      .mockResolvedValueOnce(censusResponse([]))
      .mockResolvedValueOnce(zctaResponse())
      .mockResolvedValueOnce(locatorResponse([locatorCandidate()]));

    await geocodeAddress(ARDEN);

    // Read the param rather than string-matching the URL: URLSearchParams encodes
    // spaces as "+", which decodeURIComponent does not turn back into spaces.
    expect(new URL(urlOf(2)).searchParams.get('SingleLine')).toBe(ARDEN);
  });

  it('skips the locator for a ZIP outside its registered prefixes', async () => {
    // 20500 is Washington DC — no registered locator, so straight to the NAD.
    fetchMock()
      .mockResolvedValueOnce(censusResponse([]))
      .mockResolvedValueOnce(zctaResponse())
      .mockResolvedValueOnce(nadResponse([]));

    await expect(geocodeAddress('1600 pennsylvania ave nw washington dc 20500')).rejects.toMatchObject({
      code: 'ADDRESS_NOT_FOUND',
    });
    expect(fetchMock()).toHaveBeenCalledTimes(3);
    expect(urlOf(1)).toContain('tigerweb.geo.census.gov');
    expect(urlOf(2)).toContain('National_Address_Database');
  });

  it('falls through to the NAD when the locator has no candidates', async () => {
    stubFallback([nadFeature('CITRINE')]);

    await expect(geocodeAddress(ARDEN)).resolves.toMatchObject({ city: 'ARDEN' });
  });

  it('falls through to the NAD when the locator is slow or unreachable', async () => {
    fetchMock()
      .mockResolvedValueOnce(censusResponse([]))
      .mockResolvedValueOnce(zctaResponse())
      .mockRejectedValueOnce(new Error('locator down'))
      .mockResolvedValueOnce(nadResponse([nadFeature('CITRINE')]));

    await expect(geocodeAddress(ARDEN)).resolves.toMatchObject({ state: 'NC' });
  });

  // A locator answer is held to the same bar as a NAD answer. A fast wrong point
  // is still a wrong point, and resolves the wrong districts.

  it('rejects a locator match that is not a real parcel', async () => {
    // StreetAddress is interpolated along a segment — "somewhere on that street".
    stubCensusThenLocator(locatorCandidate({ addrType: 'StreetAddress' }));

    await expect(geocodeAddress(ARDEN)).rejects.toMatchObject({ code: 'ADDRESS_NOT_FOUND' });
  });

  it('rejects a locator match on a different house number', async () => {
    stubCensusThenLocator(locatorCandidate({ addNum: '527' }));

    await expect(geocodeAddress(ARDEN)).rejects.toMatchObject({ code: 'ADDRESS_NOT_FOUND' });
  });

  it('rejects a locator match on a street the user did not type', async () => {
    stubCensusThenLocator(locatorCandidate({ stName: 'SAPPHIRE' }));

    await expect(geocodeAddress(ARDEN)).rejects.toMatchObject({ code: 'ADDRESS_NOT_FOUND' });
  });

  it('ACCEPTS a structurally sound match despite a low ArcGIS score', async () => {
    // Regression guard. A score threshold looks reasonable and is wrong here:
    // measured against Buncombe on 2026-09-01, the same correct PointAddress
    // scores 100 for "525 Citrine Ln" but 72.31 for the full address a real
    // person types, because the server has no City/Region/Postal to match the
    // trailing tokens against. Gating on score disables the fast path for every
    // genuine signup while every mocked test still passes.
    fetchMock()
      .mockResolvedValueOnce(censusResponse([]))
      .mockResolvedValueOnce(zctaResponse())
      .mockResolvedValueOnce(locatorResponse([locatorCandidate({ score: 72.31 })]));

    await expect(geocodeAddress(ARDEN)).resolves.toMatchObject({
      lat: 35.472629603687,
      state: 'NC',
    });
  });

  it('rejects a locator match that lands outside the ZIP the user typed', async () => {
    // A shared street name across a county line. The structural checks all pass —
    // right house number, right street, real parcel — and only the envelope test
    // catches that this is the wrong county's copy of the street.
    stubCensusThenLocator(locatorCandidate({ x: -80.8431, y: 35.2271 })); // Charlotte

    await expect(geocodeAddress(ARDEN)).rejects.toMatchObject({ code: 'ADDRESS_NOT_FOUND' });
  });

  // ---- Refusing to guess ---------------------------------------------------
  // A wrong point resolves the wrong districts and then shows the wrong
  // representatives, with nothing reporting an error. Failing is better.

  it('rejects a house number that is not in the data rather than snapping to a neighbour', async () => {
    // The NAD holds 523 and 527; nobody lives at 525. No interpolation.
    stubFallback([]);

    await expect(geocodeAddress(ARDEN)).rejects.toMatchObject({ code: 'ADDRESS_NOT_FOUND' });
  });

  it('rejects when the returned street does not appear in what the user typed', async () => {
    stubFallback([nadFeature('SAPPHIRE', { full: 'SAPPHIRE Lane' })]);

    await expect(geocodeAddress(ARDEN)).rejects.toMatchObject({ code: 'ADDRESS_NOT_FOUND' });
  });

  it('refuses to choose when two different streets both match', async () => {
    stubFallback([nadFeature('CITRINE'), nadFeature('ARDEN', { full: 'ARDEN Lane' })]);

    await expect(geocodeAddress(ARDEN)).rejects.toMatchObject({ code: 'ADDRESS_NOT_FOUND' });
  });

  it('accepts duplicate rows on the same street, which are the same parcel', async () => {
    stubFallback([nadFeature('CITRINE'), nadFeature('CITRINE')]);

    await expect(geocodeAddress(ARDEN)).resolves.toMatchObject({ state: 'NC' });
  });

  it('does not let a short street name match inside a longer word', async () => {
    // "AR" must not match inside "arden". Whole-word only.
    stubFallback([nadFeature('AR', { full: 'AR Lane' })]);

    await expect(geocodeAddress(ARDEN)).rejects.toMatchObject({ code: 'ADDRESS_NOT_FOUND' });
  });

  // ---- Degradation --------------------------------------------------------

  it('skips the fallback when the address carries no ZIP to scope the query', async () => {
    fetchMock().mockResolvedValueOnce(censusResponse([]));

    await expect(geocodeAddress('525 Citrine Ln, Arden, NC')).rejects.toMatchObject({
      code: 'ADDRESS_NOT_FOUND',
    });
    expect(fetchMock()).toHaveBeenCalledTimes(1);
  });

  it('skips the fallback when the address has no leading house number', async () => {
    fetchMock().mockResolvedValueOnce(censusResponse([]));

    await expect(geocodeAddress('Citrine Ln, Arden, NC 28704')).rejects.toMatchObject({
      code: 'ADDRESS_NOT_FOUND',
    });
    expect(fetchMock()).toHaveBeenCalledTimes(1);
  });

  it('reports ADDRESS_NOT_FOUND, not GEOCODER_UNAVAILABLE, when only the fallback fails', async () => {
    // Census gave a definitive "no match". A broken fallback loses the extra coverage;
    // it does not make the primary answer unknown, so do not tell the user to retry.
    fetchMock()
      .mockResolvedValueOnce(censusResponse([]))
      .mockResolvedValueOnce(zctaResponse())
      .mockResolvedValueOnce(locatorResponse([]))
      .mockRejectedValueOnce(new Error('network down'));

    await expect(geocodeAddress(ARDEN)).rejects.toMatchObject({ code: 'ADDRESS_NOT_FOUND' });
  });

  it('survives an unknown ZIP with no envelope', async () => {
    fetchMock()
      .mockResolvedValueOnce(censusResponse([]))
      .mockResolvedValueOnce({ ok: true, status: 200, json: async () => ({}) });

    await expect(geocodeAddress(ARDEN)).rejects.toMatchObject({ code: 'ADDRESS_NOT_FOUND' });
  });

  it('survives an error payload from the NAD service', async () => {
    fetchMock()
      .mockResolvedValueOnce(censusResponse([]))
      .mockResolvedValueOnce(zctaResponse())
      .mockResolvedValueOnce(locatorResponse([]))
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({ error: { code: 400, message: 'Cannot perform query.' } }),
      });

    await expect(geocodeAddress(ARDEN)).rejects.toMatchObject({ code: 'ADDRESS_NOT_FOUND' });
  });

  it('does not put the address or coordinates into any warning', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {});
    fetchMock()
      .mockResolvedValueOnce(censusResponse([]))
      .mockResolvedValueOnce(zctaResponse())
      .mockResolvedValueOnce(locatorResponse([]))
      .mockRejectedValueOnce(new Error('network down'));

    await expect(geocodeAddress(ARDEN)).rejects.toThrow();

    const logged = warn.mock.calls.flat().map(String).join(' ');
    expect(logged).not.toContain('citrine');
    expect(logged).not.toContain('35.47');
  });

  // ---- Pre-existing behaviour that must not regress ------------------------

  it('still rejects a PO Box before any network call', async () => {
    await expect(geocodeAddress('P.O. Box 12, Arden, NC 28704')).rejects.toMatchObject({
      code: 'PO_BOX_REJECTED',
    });
    expect(fetchMock()).not.toHaveBeenCalled();
  });

  it('still returns a cache hit without calling any geocoder', async () => {
    cacheGetMock.mockResolvedValue({
      lat: 1, lng: 2, matchedAddress: 'CACHED', state: 'NC', city: 'Arden',
    });

    const result = await geocodeAddress(ARDEN);

    expect(result).toMatchObject({ lat: 1, lng: 2, matchedAddress: 'CACHED' });
    expect(fetchMock()).not.toHaveBeenCalled();
  });

  it('still surfaces GEOCODER_UNAVAILABLE when Census itself is down', async () => {
    fetchMock().mockResolvedValueOnce({ ok: false, status: 500, json: async () => ({}) });

    const err = await geocodeAddress(ARDEN).catch((e: unknown) => e);

    expect(err).toBeInstanceOf(GeocodingError);
    expect(err).toMatchObject({ code: 'GEOCODER_UNAVAILABLE' });
    // A Census outage is not a miss, so the fallback must not absorb it.
    expect(fetchMock()).toHaveBeenCalledTimes(1);
  });
});
