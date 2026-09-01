import { cache } from './cache.js';

// ---------------------------------------------------------------------------
// Error types
// ---------------------------------------------------------------------------

export type GeocodingErrorCode =
  | 'PO_BOX_REJECTED'     // PO Box detected before any HTTP call
  | 'ADDRESS_NOT_FOUND'   // Census Geocoder returned zero address matches
  | 'GEOCODER_UNAVAILABLE'; // Timeout, HTTP error, or unexpected Census response

export class GeocodingError extends Error {
  constructor(public readonly code: GeocodingErrorCode, message: string) {
    super(message);
    this.name = 'GeocodingError';
  }
}

// ---------------------------------------------------------------------------
// Internal types — US Census Geocoder API response shape
// https://geocoding.geo.census.gov/geocoder/locations/onelineaddress
// ---------------------------------------------------------------------------

interface CensusGeocodeResponse {
  result: {
    input: {
      address: { address: string };
      benchmark: { benchmarkName: string };
    };
    addressMatches: Array<{
      matchedAddress: string;
      coordinates: {
        x: number;  // longitude
        y: number;  // latitude
      };
      tigerLine: { tigerLineId: string; side: string };
      addressComponents: {
        zip: string;
        streetName: string;
        city: string;
        state: string;
        [key: string]: string;
      };
    }>;
  };
}

export interface GeocodeResult {
  lat: number;
  lng: number;
  matchedAddress: string;
  state: string;
  city: string;
}

// ---------------------------------------------------------------------------
// Fallback source — USDOT National Address Database (FREE, no API key)
//
// The NAD is the federal aggregation of the address points that states, counties
// and tribes assign for E-911. That makes it the ORIGINAL authority: a county
// assigns an address the day a house is platted, and TIGER absorbs it years later.
// The record that unblocked this work reads AddAuth = "State of North Carolina".
//
// Two endpoints, both free and both unauthenticated:
//   NAD  — the address points themselves, attribute-queried.
//   ZCTA — TIGERweb ZIP Code Tabulation Areas, used only for a bounding box.
//
// The ZCTA call is not decoration. The NAD hosted view REJECTS a purely attribute
// query ("Unable to perform query"), so every request must carry a spatial filter.
// A ZIP the user already typed is the cheapest scope available, and ZIP extents
// never move, so they cache for a month.
// ---------------------------------------------------------------------------

const NAD_QUERY_URL =
  'https://services.arcgis.com/xOi1kZaI0eWDREZv/ArcGIS/rest/services/' +
  'Address_Points_from_National_Address_Database_view/FeatureServer/0/query';

// Layer 11 is the CURRENT ZCTA layer. Layers 1/4/7 in the same service are the
// frozen "2020 Census" vintages — do not swap one in without re-checking BASENAME.
const ZCTA_QUERY_URL =
  'https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/' +
  'PUMA_TAD_TAZ_UGA_ZCTA/MapServer/11/query';

const ZCTA_CACHE_TTL_SECONDS = 60 * 60 * 24 * 30; // a month; ZIP extents do not move

interface Extent {
  xmin: number;
  ymin: number;
  xmax: number;
  ymax: number;
}

interface NadFeature {
  attributes: {
    Add_Number?: number | null;
    St_Name?: string | null;
    StNam_Full?: string | null;
    Post_City?: string | null;
    State?: string | null;
    Zip_Code?: string | null;
  };
  geometry?: { x: number; y: number } | null;
}

// ---------------------------------------------------------------------------
// Jurisdiction locators — county-operated ArcGIS GeocodeServers
//
// WHY THESE COME FIRST. The national services are reachable from Render but
// erratic. Measured 2026-09-01 from the production box, six paced samples each,
// all asking where 525 Citrine Ln, Arden NC is:
//
//   NAD (services.arcgis.com)      1143 · 1945 · 2533 · 4830 · 16029 · 16868 ms
//   NC OneMap (statewide ArcGIS)   2955 · 4636 · 4649 · 5452 · 16122 · 1 error
//   Buncombe County GeocodeServer   421 ·  524 ·  581 ·  587 ·   603 ·   644 ms
//
// Two of six NAD samples blew the whole fallback budget, and the statewide
// service was no better — both are large multi-tenant hosted ArcGIS instances,
// which is the trait that predicts the tail, not the operator. A county server
// serving one county is a different class of thing: six samples spanning 223ms.
//
// So where a county publishes a locator, ask it first. It is faster, it is the
// same authority that assigns the address in the first place, and it accepts a
// single-line string, so none of the NAD's parsing applies.
//
// ADDING ONE. This mirrors how the Knight program already onboards a
// jurisdiction — the same counties that publish boundary layers for
// `essentials.geofence_boundaries` usually publish a GeocodeServer beside them.
// Confirm `findAddressCandidates` returns `Addr_type: "PointAddress"` with a
// populated `AddNum` and `StName`, then add a row.
//
// `zipPrefixes` is a cheap pre-filter, not a coverage claim. It is deliberately
// generous — 287/288 pulls in neighbouring counties — because a locator asked
// about an address it does not hold returns zero candidates, which costs one
// sub-second call and falls through to the NAD. A prefix that is too narrow
// silently loses the fast path; one that is too wide costs milliseconds.
// ---------------------------------------------------------------------------

interface JurisdictionLocator {
  name: string;
  /** Two-letter state, supplied from here because these servers return no region. */
  state: string;
  zipPrefixes: string[];
  url: string;
}

const JURISDICTION_LOCATORS: JurisdictionLocator[] = [
  {
    name: 'Buncombe County, NC',
    state: 'NC',
    zipPrefixes: ['287', '288'],
    url: 'https://gis.buncombecounty.org/arcgis/rest/services/AddressSearch2/GeocodeServer/findAddressCandidates',
  },
];

/** Slice of the fallback budget a locator may use. Max observed is 644ms. */
const LOCATOR_BUDGET_MS = 3000;

/**
 * NOTE ON `score`: it is deliberately NOT used as a gate.
 *
 * ArcGIS scores how much of the input it matched, and these county servers return
 * City, Region and Postal as empty strings — they hold one county and do not index
 * place names. So every token past the street is unmatchable and drags the score
 * down. Measured against Buncombe on 2026-09-01, all four returning the SAME
 * correct PointAddress for 525 Citrine Ln:
 *
 *     "525 Citrine Ln"                    score 100
 *     "525 citrine lane"                  score 100
 *     "525 citrine lane arden nc 28704"   score  72.31
 *     "525 Citrine Ln, Arden, NC 28704"   score  70
 *
 * A threshold tuned on the first two rejects every real signup, which types the
 * last two. The score measures how much of the string the server recognised, not
 * whether the answer is right, so the gates below are structural instead: the
 * exact house number, the street name appearing in what the user typed, a real
 * parcel type, and the point landing inside the ZIP they gave.
 */

interface LocatorCandidate {
  address?: string;
  score?: number;
  location?: { x: number; y: number } | null;
  attributes?: {
    Addr_type?: string;
    AddNum?: string;
    StName?: string;
    Match_addr?: string;
  };
}

// ---------------------------------------------------------------------------
// PO Box detection
// Matches: "PO Box", "P.O. Box", "POB" — case-insensitive
// ---------------------------------------------------------------------------

const PO_BOX_PATTERN = /\bP\.?O\.?\s*Box\b|\bPOB\b/i;

// ---------------------------------------------------------------------------
// geocodeAddress
//
// Converts a US residential address string to { lat, lng }.
//
// Privacy contract:
//   - lat/lng are raw floats consumed by the caller immediately.
//   - They must NEVER be logged, returned in API responses, or stored
//     anywhere except via the upsert_user_location RPC call.
//   - The address string is consumed here and discarded after this function
//     returns — do not return or store it.
//
// Implementation: US Census Geocoder (free, no API key required), with the USDOT
// National Address Database as a fallback on a zero-match. Both are free and
// unauthenticated; Phase 38's move off paid geocoding stands — see geocodeViaFallback.
// ---------------------------------------------------------------------------

/**
 * Whole-fallback time budget, shared across BOTH of its calls.
 *
 * Not a per-call timeout, deliberately. The fallback makes up to two sequential
 * requests, so per-call timeouts multiply into the worst case and the person watching
 * the button pays the sum. One deadline bounds the entire second opinion instead:
 * Census (5s) + this = the true ceiling on set-location.
 *
 * WHY IT IS THIS BIG. The NAD hosted view is reliable but has a punishing tail.
 * Measured 2026-09-01 over 10 paced requests with a 30s ceiling and no early abort:
 *
 *     min 469ms · p50 1817ms · p90 12857ms · max 12857ms · 0 outright failures
 *
 * Nothing ever failed — slow requests simply took a long time. So a retry is the
 * wrong instrument (it re-queues behind the same slow service, and an earlier
 * 3s-timeout-plus-retry experiment still lost 4 of 10), and a small timeout fails
 * exactly the cold, uncached lookups this fallback exists to serve. 12s covers most
 * of that distribution; the slowest few percent still fail closed to ADDRESS_NOT_FOUND,
 * where a retry by the user usually lands on a fast response — and by then the ZIP
 * envelope is cached, so the retry is a single call.
 *
 * This tail is the strongest argument for eventually self-hosting the NAD extract:
 * the same lookup against local PostGIS is a millisecond, with no third party in the
 * request path at all.
 */
const FALLBACK_BUDGET_MS = 12000;

/** Identify ourselves to these public government services rather than arriving blank. */
const FALLBACK_USER_AGENT = 'EmpoweredVote/1.0 (+https://empowered.vote)';

/**
 * One GET returning JSON, bounded by whatever is left of the fallback budget.
 *
 * `source` names which upstream this was, and it is not decoration. The fallback
 * makes two calls to two unrelated operators, and when this said only "fallback
 * source unavailable" a production failure could not be attributed to either one
 * without a redeploy. Keep the label distinct.
 */
async function fetchJson<T>(url: URL, remainingMs: number, source: string): Promise<T | null> {
  if (remainingMs <= 0) {
    console.warn(`[geocoding] ${source}: no budget left before request`);
    return null;
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), remainingMs);
  const started = Date.now();
  try {
    const response = await fetch(url.toString(), {
      signal: controller.signal,
      headers: { 'User-Agent': FALLBACK_USER_AGENT, Accept: 'application/json' },
    });
    if (!response.ok) {
      console.warn(`[geocoding] ${source}: HTTP ${response.status} after ${Date.now() - started}ms`);
      return null;
    }
    return (await response.json()) as T;
  } catch (err: unknown) {
    // AbortError = out of budget; anything else = network failure. Neither is fatal.
    const reason = (err as { name?: string })?.name === 'AbortError' ? 'timed out' : 'network error';
    console.warn(`[geocoding] ${source}: ${reason} after ${Date.now() - started}ms (budget ${remainingMs}ms)`);
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

/**
 * Reduce to lowercase words so a street name can be compared to raw user input.
 * Everything that is not a letter or digit becomes a single space, which is what
 * makes the whole-word test below safe without escaping: after this runs, no regex
 * metacharacter can survive in either operand.
 */
function normalizeForMatch(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
}

/** True when `needle` appears in `haystack` as a complete word sequence. */
function containsWholeWords(haystack: string, needle: string): boolean {
  if (!needle) return false;
  return new RegExp(`(?:^| )${needle}(?:$| )`).test(haystack);
}

/**
 * Pull the two things the NAD needs out of a free-text address: the house number
 * and the ZIP. Deliberately does NOT try to find where the street name ends —
 * "525 citrine lane arden nc 28704" has no commas, and any rule for splitting
 * street from city is wrong for some real address. The street is matched later,
 * against candidates the NAD itself returns, which sidesteps the problem entirely.
 */
function parseHouseNumberAndZip(address: string): { houseNumber: number; zip: string } | null {
  const house = /^\s*(\d{1,7})\b/.exec(address);
  const zip = /\b(\d{5})(?:-\d{4})?\s*$/.exec(address.trim());
  if (!house?.[1] || !zip?.[1]) return null;
  return { houseNumber: Number(house[1]), zip: zip[1] };
}

/**
 * Ask a county's own GeocodeServer where an address is.
 *
 * Returns null for anything short of an exact rooftop hit, because the point of
 * trying a locator first is speed, not a second opinion of lower quality. The
 * checks are the same ones the NAD path makes, read off this server's fields:
 *
 *   - `Addr_type` must be `PointAddress` — a real parcel. StreetAddress and the
 *     interpolated types are exactly the "somewhere on that street" answer that
 *     resolves the wrong districts.
 *   - `AddNum` must equal the house number the user typed. No snapping.
 *   - `StName` must appear in the input as a whole word, so a server that
 *     matched a different street cannot pass.
 *   - the returned point must fall inside the ZIP's own envelope.
 *
 * That last check is what makes a generous `zipPrefixes` safe. A locator holds one
 * county but the prefix spans several, so asking Buncombe about an address in a
 * neighbouring county is expected. Usually it returns zero candidates — verified
 * with a street that does not exist there — but a street name shared across the
 * county line would otherwise return Buncombe's copy of it and seat the person in
 * the wrong county. Requiring the point to land in the ZIP they actually typed
 * closes that hole, and the envelope is already fetched for the NAD and cached for
 * a month, so it costs nothing extra.
 *
 * `score` is not a gate — see the note above LOCATOR_BUDGET_MS.
 */
async function geocodeViaLocator(
  locator: JurisdictionLocator,
  address: string,
  houseNumber: number,
  zip: string,
  extent: Extent,
  remainingMs: number,
): Promise<GeocodeResult | null> {
  const url = new URL(locator.url);
  url.searchParams.set('SingleLine', address);
  url.searchParams.set('outSR', '4326');
  url.searchParams.set('outFields', '*');
  url.searchParams.set('f', 'json');

  const data = await fetchJson<{ candidates?: LocatorCandidate[] }>(
    url,
    Math.min(remainingMs, LOCATOR_BUDGET_MS),
    `locator:${locator.name}`,
  );

  const best = data?.candidates?.[0];
  if (!best) return null;

  const a = best.attributes ?? {};
  if (a.Addr_type !== 'PointAddress') return null;
  if (String(a.AddNum ?? '') !== String(houseNumber)) return null;

  const street = normalizeForMatch(a.StName ?? '');
  if (!street || !containsWholeWords(normalizeForMatch(address), street)) return null;

  const point = best.location;
  if (!point || typeof point.x !== 'number' || typeof point.y !== 'number') return null;

  // The point must be in the ZIP the user typed, not merely somewhere this county
  // holds. Without this a street name shared across the county line seats them in
  // the wrong county entirely.
  const inZip =
    point.x >= extent.xmin && point.x <= extent.xmax &&
    point.y >= extent.ymin && point.y <= extent.ymax;
  if (!inZip) {
    console.warn(`[geocoding] locator:${locator.name}: match fell outside the ZIP envelope`);
    return null;
  }

  return {
    lat: point.y,
    lng: point.x,
    matchedAddress: [a.Match_addr ?? best.address ?? '', `${locator.state} ${zip}`.trim()]
      .filter(Boolean)
      .join(', '),
    state: locator.state,
    // These servers return City/Region/Postal as empty strings, so there is no
    // city to report. That is not a regression: this path runs only after the
    // Census already failed, where the alternative is no location at all.
    city: '',
  };
}

/** Bounding box of a ZIP Code Tabulation Area. Cached — ZIP extents do not move. */
async function getZipExtent(zip: string, remainingMs: number): Promise<Extent | null> {
  const cacheKey = `zcta:v1:${zip}`;
  const cached = await cache.get<Extent>(cacheKey);
  if (cached) return cached;

  const url = new URL(ZCTA_QUERY_URL);
  url.searchParams.set('where', `BASENAME='${zip}'`);
  url.searchParams.set('returnExtentOnly', 'true');
  url.searchParams.set('outSR', '4326');
  url.searchParams.set('f', 'json');

  const data = await fetchJson<{ extent?: Extent }>(url, remainingMs, 'ZCTA');
  const extent = data?.extent;
  if (
    !extent ||
    typeof extent.xmin !== 'number' ||
    typeof extent.ymin !== 'number' ||
    typeof extent.xmax !== 'number' ||
    typeof extent.ymax !== 'number'
  ) {
    return null;
  }

  await cache.set(cacheKey, extent, ZCTA_CACHE_TTL_SECONDS);
  return extent;
}

/**
 * Second-chance geocode through the USDOT National Address Database.
 *
 * WHY THIS EXISTS. The Census Geocoder reads TIGER's address-range files, and TIGER
 * lags new construction by years. A house on a street platted after the last refresh
 * returns zero matches — not "close", zero — while every neighbouring street resolves.
 * Measured 2026-09-01 on a real signup: `525 Citrine Ln, Arden, NC 28704` missed on
 * all three Census benchmarks (Current, Census2020, ACS2025) and in OpenStreetMap,
 * yet a bbox query on TIGER's own local-roads layer returned dense coverage all around
 * it. The NAD has it, attributed to the State of North Carolina. Before this fallback
 * that person could not enter Civic Spaces at all, because set-location gates the
 * entire Connect pillar.
 *
 * HOW THE MATCH IS MADE, and why it is done in this order:
 *   1. Parse out the house number and ZIP only.
 *   2. ZIP -> ZCTA bounding box, because the NAD view refuses a non-spatial query.
 *   3. Ask the NAD for EVERY address point with that house number in that ZIP.
 *   4. Keep the candidates whose own street name appears in what the user typed.
 *
 * Step 4 is the trick. Splitting "525 citrine lane arden nc 28704" into street and
 * city needs a rule that is wrong for some real address, so instead the NAD supplies
 * the street names and each is tested against the input. Multi-word names ("OLD
 * SHOALS") work unchanged, and the test is whole-word, so "AR" cannot match inside
 * "arden".
 *
 * PRECISION. The house number must match EXACTLY. There is no interpolation and no
 * snapping to a neighbouring number: NAD points are rooftop, so a match is a real
 * parcel or there is no match. Two candidates on different streets is an ambiguity,
 * not a coin toss — it returns null. Seating someone on a guess resolves the WRONG
 * districts and then shows them the wrong representatives, with nothing reporting an
 * error. Same reasoning as the D-04/RSLV-04 boundary that keeps the one-line
 * geocoder street-address-only (see locationSearchService.test.ts).
 *
 * SHAPE OF THE CONTRACT.
 *  - Runs ONLY after Census returns zero matches, so the free primary stays the
 *    default and this adds no latency to a normal lookup.
 *  - Returns `null` for every failure — unparseable input, no ZIP, unknown ZIP, no
 *    candidate, ambiguity, HTTP error, timeout. The caller turns that back into the
 *    same ADDRESS_NOT_FOUND it threw before this existed, so a broken or unreachable
 *    fallback degrades to exactly the old behaviour, never to a new failure mode.
 *  - A Census OUTAGE never reaches here. That is GEOCODER_UNAVAILABLE, thrown
 *    upstream; only a definitive zero-match deserves a second opinion.
 *  - No API key, no account, no billing. That is the point: Phase 38 left Google for
 *    cost, and this keeps that decision intact.
 *
 * COVERAGE CAVEAT. The NAD is a compilation of what states and counties submit, and
 * participation is uneven — strong in some states, partial in others. It is a net
 * gain over TIGER everywhere and a complete answer nowhere. Expect to re-check it as
 * new states are onboarded.
 *
 * PRIVACY. Same contract as the caller: the address is consumed and discarded, and
 * neither it nor the coordinates may reach a log line. The warnings here carry an
 * HTTP status or a candidate count and nothing else — keep it that way.
 */
async function geocodeViaFallback(address: string): Promise<GeocodeResult | null> {
  const parsed = parseHouseNumberAndZip(address);
  // No leading house number or no trailing ZIP means there is nothing to scope
  // either source with. That is a skip, not an error — the caller says NOT_FOUND.
  if (!parsed) return null;

  // One deadline for the whole second opinion, so sequential calls cannot
  // multiply into a wait the person watching the button actually feels.
  const deadline = Date.now() + FALLBACK_BUDGET_MS;

  // 1. The ZIP envelope, first, because BOTH sources need it — the locator to
  //    confirm its answer is in the right ZIP, the NAD because its hosted view
  //    refuses a non-spatial query. It caches for a month and measured 344-428ms
  //    from Render, so on any repeat ZIP this leg is free.
  const extent = await getZipExtent(parsed.zip, deadline - Date.now());
  if (!extent) return null;

  // 2. A county that publishes its own locator answers in well under a second and
  //    is the authority that assigned the address. Try it before the national
  //    service. A miss costs one sub-second call and falls through.
  const locators = JURISDICTION_LOCATORS.filter((l) =>
    l.zipPrefixes.some((prefix) => parsed.zip.startsWith(prefix)),
  );
  for (const locator of locators) {
    const hit = await geocodeViaLocator(
      locator,
      address,
      parsed.houseNumber,
      parsed.zip,
      extent,
      deadline - Date.now(),
    );
    if (hit) return hit;
  }

  // 3. No registered locator held this address. Fall through to the national
  //    database, tail and all — it is still better than failing outright.

  const url = new URL(NAD_QUERY_URL);
  url.searchParams.set('where', `Add_Number=${parsed.houseNumber} AND Zip_Code='${parsed.zip}'`);
  url.searchParams.set('geometry', `${extent.xmin},${extent.ymin},${extent.xmax},${extent.ymax}`);
  url.searchParams.set('geometryType', 'esriGeometryEnvelope');
  url.searchParams.set('inSR', '4326');
  url.searchParams.set('spatialRel', 'esriSpatialRelIntersects');
  url.searchParams.set('outFields', 'Add_Number,St_Name,StNam_Full,Post_City,State,Zip_Code');
  url.searchParams.set('returnGeometry', 'true');
  url.searchParams.set('outSR', '4326');
  url.searchParams.set('f', 'json');

  const data = await fetchJson<{ features?: NadFeature[]; error?: unknown }>(url, deadline - Date.now(), 'NAD');
  const features = data?.features;
  if (!features?.length) return null;

  const haystack = normalizeForMatch(address);
  const matches = features.filter((f) => {
    const street = normalizeForMatch(f.attributes?.St_Name ?? '');
    return street !== '' && containsWholeWords(haystack, street);
  });

  if (matches.length === 0) return null;

  // More than one street matched — the input is genuinely ambiguous against the
  // authoritative data, so refuse rather than pick. Identical street names are not
  // ambiguous (unit-level rows sit on the same parcel); take the first of those.
  const distinctStreets = new Set(
    matches.map((f) => normalizeForMatch(f.attributes?.St_Name ?? '')),
  );
  if (distinctStreets.size > 1) {
    console.warn(`[geocoding] fallback found ${distinctStreets.size} candidate streets — refusing to guess`);
    return null;
  }

  const best = matches[0]!;
  const point = best.geometry;
  if (!point || typeof point.x !== 'number' || typeof point.y !== 'number') return null;

  const a = best.attributes;
  const streetFull = a?.StNam_Full ?? a?.St_Name ?? '';
  const city = a?.Post_City ?? '';
  const state = a?.State ?? '';
  const zip = a?.Zip_Code ?? '';

  return {
    lat: point.y,
    lng: point.x,
    // Rebuilt from the authoritative record, not echoed from user input, so the
    // stored label matches what the address authority actually publishes.
    matchedAddress: [`${a?.Add_Number ?? ''} ${streetFull}`.trim(), city, `${state} ${zip}`.trim()]
      .filter(Boolean)
      .join(', '),
    state,
    city,
  };
}

export async function geocodeAddress(address: string): Promise<GeocodeResult> {
  // 1. PO Box check — before any network call
  if (PO_BOX_PATTERN.test(address)) {
    throw new GeocodingError(
      'PO_BOX_REJECTED',
      'PO Box addresses cannot be used for location verification',
    );
  }

  // 2. Normalize address for cache key
  const cacheKey = `geocode:v1:${address.toLowerCase().trim().replace(/\s+/g, ' ')}`;

  // 3. Redis cache check — return immediately on hit (24hr TTL)
  const cached = await cache.get<{ lat: number; lng: number; matchedAddress?: string; state?: string; city?: string }>(cacheKey);
  if (cached) {
    return { lat: cached.lat, lng: cached.lng, matchedAddress: cached.matchedAddress ?? '', state: cached.state ?? '', city: cached.city ?? '' };
  }

  // 4. Build Census Geocoder URL
  // Endpoint: /geocoder/locations/onelineaddress
  // benchmark=Public_AR_Current = standard benchmark for current addresses
  // Returns addressMatches[] — empty array means ADDRESS_NOT_FOUND
  const url = new URL('https://geocoding.geo.census.gov/geocoder/locations/onelineaddress');
  url.searchParams.set('address', address);
  url.searchParams.set('benchmark', 'Public_AR_Current');
  url.searchParams.set('format', 'json');

  // 5. 5-second timeout via AbortController
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);

  let response: Response;
  try {
    response = await fetch(url.toString(), { signal: controller.signal });
  } catch (err: unknown) {
    clearTimeout(timeout);
    // AbortError = timeout; other errors = network failure
    throw new GeocodingError('GEOCODER_UNAVAILABLE', 'Address lookup temporarily unavailable.');
  }
  clearTimeout(timeout);

  // 6. Non-2xx response = geocoder error
  if (!response.ok) {
    throw new GeocodingError('GEOCODER_UNAVAILABLE', 'Address lookup temporarily unavailable.');
  }

  let data: CensusGeocodeResponse;
  try {
    data = (await response.json()) as CensusGeocodeResponse;
  } catch {
    throw new GeocodingError('GEOCODER_UNAVAILABLE', 'Address lookup temporarily unavailable.');
  }

  // 7. Empty addressMatches = Census has no record of this address. Give it a second
  //    chance through the NAD before failing — TIGER's blind spot is new construction,
  //    and a real resident of a new street is exactly who we must not turn away.
  //    geocodeViaFallback returns null for every failure, so this stays a hard
  //    ADDRESS_NOT_FOUND whenever the fallback is absent, broken, or imprecise.
  const matches = data?.result?.addressMatches;
  if (!matches || matches.length === 0) {
    const fallback = await geocodeViaFallback(address);
    if (fallback) {
      await cache.set(cacheKey, fallback, 86400);
      return fallback;
    }
    throw new GeocodingError(
      'ADDRESS_NOT_FOUND',
      "We couldn't find that address. Please double-check and try again.",
    );
  }

  // 8. Extract coordinates and state abbreviation
  // CRITICAL: Census uses x=longitude, y=latitude (opposite of common lat/lng convention)
  // PostGIS ST_MakePoint also takes (longitude, latitude) = (x, y) — same order
  const lng = matches[0].coordinates.x; // longitude
  const lat = matches[0].coordinates.y; // latitude
  const state = matches[0].addressComponents.state ?? ''; // 2-letter abbreviation e.g. "IN"
  const city = matches[0].addressComponents.city ?? '';

  // 9. Cache successful result for 24 hours (86400 seconds)
  await cache.set(cacheKey, { lat, lng, matchedAddress: matches[0].matchedAddress, state, city }, 86400);

  return { lat, lng, matchedAddress: matches[0].matchedAddress, state, city };
}
