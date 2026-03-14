import { env } from './env.js';

// ---------------------------------------------------------------------------
// Error types
// ---------------------------------------------------------------------------

export type GeocodingErrorCode =
  | 'PO_BOX_REJECTED'    // PO Box detected before any HTTP call
  | 'ADDRESS_NOT_FOUND'  // Google returned zero results
  | 'LOW_CONFIDENCE'     // location_type is GEOMETRIC_CENTER or APPROXIMATE
  | 'GEOCODING_API_ERROR'; // HTTP error or unexpected Google response

export class GeocodingError extends Error {
  constructor(public readonly code: GeocodingErrorCode, message: string) {
    super(message);
    this.name = 'GeocodingError';
  }
}

// ---------------------------------------------------------------------------
// Internal types — Google Maps Geocoding API response shape
// ---------------------------------------------------------------------------

interface GoogleGeocodeResponse {
  status: string;
  results: Array<{
    geometry: {
      location: { lat: number; lng: number };
      location_type: string;
    };
  }>;
}

// ---------------------------------------------------------------------------
// PO Box detection
// Matches: "PO Box", "P.O. Box", "POB" — case-insensitive
// ---------------------------------------------------------------------------

const PO_BOX_PATTERN = /\bP\.?O\.?\s*Box\b|\bPOB\b/i;

// ---------------------------------------------------------------------------
// geocodeAddress
//
// Converts a residential address string to { lat, lng }.
//
// Privacy contract:
//   - lat/lng are raw floats consumed by the caller immediately.
//   - They must NEVER be logged, returned in API responses, or stored
//     anywhere except via the upsert_user_location RPC call.
//   - The address string is consumed here and discarded after this function
//     returns — do not return or store it.
// ---------------------------------------------------------------------------

export async function geocodeAddress(address: string): Promise<{ lat: number; lng: number }> {
  // 1. PO Box check — before any network call
  if (PO_BOX_PATTERN.test(address)) {
    throw new GeocodingError(
      'PO_BOX_REJECTED',
      'PO Box addresses cannot be used for location verification',
    );
  }

  // 2. Call Google Maps Geocoding API
  const url = new URL('https://maps.googleapis.com/maps/api/geocode/json');
  url.searchParams.set('address', address);
  url.searchParams.set('key', env.GOOGLE_MAPS_API_KEY);

  const response = await fetch(url.toString());
  if (!response.ok) {
    throw new GeocodingError(
      'GEOCODING_API_ERROR',
      `Geocoding API returned HTTP ${response.status}`,
    );
  }

  const data = (await response.json()) as GoogleGeocodeResponse;

  // 3. Zero results
  if (data.status === 'ZERO_RESULTS' || data.results.length === 0) {
    throw new GeocodingError(
      'ADDRESS_NOT_FOUND',
      "We couldn't find that address. Please double-check and try again.",
    );
  }

  // 4. Unexpected status (REQUEST_DENIED, INVALID_REQUEST, etc.)
  if (data.status !== 'OK') {
    throw new GeocodingError('GEOCODING_API_ERROR', `Geocoding API error: ${data.status}`);
  }

  const result = data.results[0];

  // 5. Confidence filter: only ROOFTOP or RANGE_INTERPOLATED
  const locationType = result.geometry.location_type;
  if (locationType !== 'ROOFTOP' && locationType !== 'RANGE_INTERPOLATED') {
    throw new GeocodingError(
      'LOW_CONFIDENCE',
      "We couldn't find that address. Please double-check and try again.",
    );
  }

  const { lat, lng } = result.geometry.location;
  return { lat, lng };
}
