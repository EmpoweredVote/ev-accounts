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
// Implementation: US Census Geocoder (free, no API key required)
// Replaced Google Maps Geocoding API in Phase 38.
// ---------------------------------------------------------------------------

export async function geocodeAddress(address: string): Promise<{ lat: number; lng: number; matchedAddress: string }> {
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
  const cached = await cache.get<{ lat: number; lng: number; matchedAddress?: string }>(cacheKey);
  if (cached) {
    return { lat: cached.lat, lng: cached.lng, matchedAddress: cached.matchedAddress ?? '' };
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

  // 7. Empty addressMatches = no match for this address
  const matches = data?.result?.addressMatches;
  if (!matches || matches.length === 0) {
    throw new GeocodingError(
      'ADDRESS_NOT_FOUND',
      "We couldn't find that address. Please double-check and try again.",
    );
  }

  // 8. Extract coordinates
  // CRITICAL: Census uses x=longitude, y=latitude (opposite of common lat/lng convention)
  // PostGIS ST_MakePoint also takes (longitude, latitude) = (x, y) — same order
  const lng = matches[0].coordinates.x; // longitude
  const lat = matches[0].coordinates.y; // latitude

  // 9. Cache successful result for 24 hours (86400 seconds)
  await cache.set(cacheKey, { lat, lng, matchedAddress: matches[0].matchedAddress }, 86400);

  return { lat, lng, matchedAddress: matches[0].matchedAddress };
}
