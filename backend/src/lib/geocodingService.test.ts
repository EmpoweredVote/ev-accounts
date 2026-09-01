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

/** Census miss -> ZCTA extent -> NAD features. The full happy path, in order. */
function stubFallback(features: unknown[]) {
  fetchMock()
    .mockResolvedValueOnce(censusResponse([]))
    .mockResolvedValueOnce(zctaResponse())
    .mockResolvedValueOnce(nadResponse(features));
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
    expect(fetchMock()).toHaveBeenCalledTimes(3);
    expect(urlOf(1)).toContain('tigerweb.geo.census.gov');
    expect(urlOf(2)).toContain('National_Address_Database');
  });

  it('scopes the NAD query by house number, ZIP, and the ZIP envelope', async () => {
    stubFallback([nadFeature('CITRINE')]);

    await geocodeAddress(ARDEN);

    // The hosted NAD view rejects a purely attribute query, so the envelope is
    // load-bearing, not an optimisation.
    const nadUrl = decodeURIComponent(urlOf(2));
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
      .mockResolvedValueOnce(nadResponse([nadFeature('CITRINE')]));

    await expect(geocodeAddress(ARDEN)).resolves.toMatchObject({ state: 'NC' });

    expect(fetchMock()).toHaveBeenCalledTimes(2);
    expect(urlOf(1)).toContain('National_Address_Database');
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
