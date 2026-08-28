import { env } from './env.js';
import { geocodeAddress } from './geocodingService.js';

// ---------------------------------------------------------------------------
// Voter info service — proxies Google's Civic Information API `voterInfoQuery`.
//
// One address-keyed call returns in-person voting locations (vote centers,
// early-vote sites, ballot drop-off locations) plus official election-info /
// sample-ballot URLs, sourced from the Voting Information Project (VIP).
//
// Privacy/safety contract:
//   - The Google API key lives ONLY here (server-side). Never returned to the
//     client; the frontend hits our /api/essentials/voter-info proxy instead.
//   - Google Civic only returns location data when a live election exists for
//     the address (locations populate ~5-25 days before election day). When
//     nothing is live, we return a safe empty payload rather than throwing, so
//     the UI can degrade to official links.
//
// Docs: https://developers.google.com/civic-information/docs/v2/elections/voterInfoQuery
// ---------------------------------------------------------------------------

const CIVIC_ENDPOINT = 'https://www.googleapis.com/civicinfo/v2/voterinfo';
const REQUEST_TIMEOUT_MS = 6000;
const SOURCE_LABEL = 'Voting Information Project / Google Civic Information API';

// Normalized location shape consumed by the frontend.
export interface VoterLocation {
  name: string;
  address: string; // one-line formatted address
  hours: string | null;
  startDate: string | null; // early-vote / drop-off window start (ISO date)
  endDate: string | null;   // early-vote / drop-off window end (ISO date)
  lat: number | null;
  lng: number | null;
}

export interface VoterInfo {
  electionName: string | null;
  electionDate: string | null; // ISO date (YYYY-MM-DD)
  dropOffLocations: VoterLocation[];
  earlyVoteSites: VoterLocation[];
  pollingLocations: VoterLocation[];
  ballotInfoUrl: string | null;
  electionInfoUrl: string | null;
  votingLocationFinderUrl: string | null;
  source: string;
}

// ---------------------------------------------------------------------------
// Google Civic Information API response shapes (only fields we read)
// ---------------------------------------------------------------------------

interface CivicAddress {
  locationName?: string;
  line1?: string;
  line2?: string;
  line3?: string;
  city?: string;
  state?: string;
  zip?: string;
}

interface CivicLocation {
  address?: CivicAddress;
  name?: string;
  pollingHours?: string;
  startDate?: string;
  endDate?: string;
  latitude?: number;
  longitude?: number;
}

interface CivicVoterInfoResponse {
  election?: { name?: string; electionDay?: string };
  pollingLocations?: CivicLocation[];
  earlyVoteSites?: CivicLocation[];
  dropOffLocations?: CivicLocation[];
  state?: Array<{
    electionAdministrationBody?: {
      electionInfoUrl?: string;
      ballotInfoUrl?: string;
      votingLocationFinderUrl?: string;
    };
  }>;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function formatAddress(addr?: CivicAddress): string {
  if (!addr) return '';
  const street = [addr.line1, addr.line2, addr.line3].filter(Boolean).join(' ');
  const cityStateZip = [addr.city, addr.state].filter(Boolean).join(', ');
  return [street, cityStateZip, addr.zip].filter(Boolean).join(', ').trim();
}

function mapLocation(loc: CivicLocation): VoterLocation {
  return {
    name: loc.address?.locationName || loc.name || 'Voting location',
    address: formatAddress(loc.address),
    hours: loc.pollingHours?.trim() || null,
    startDate: loc.startDate || null,
    endDate: loc.endDate || null,
    lat: typeof loc.latitude === 'number' ? loc.latitude : null,
    lng: typeof loc.longitude === 'number' ? loc.longitude : null,
  };
}

// Haversine distance (km) — used to order locations nearest-first.
function distanceKm(a: { lat: number; lng: number }, b: { lat: number | null; lng: number | null }): number {
  if (b.lat == null || b.lng == null) return Number.POSITIVE_INFINITY;
  const R = 6371;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const s =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((a.lat * Math.PI) / 180) * Math.cos((b.lat * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(s));
}

// Sort a location list nearest-first relative to an origin (locations without
// coordinates fall to the end). Returns a new array.
function sortByDistance(locs: VoterLocation[], origin: { lat: number; lng: number } | null): VoterLocation[] {
  if (!origin || locs.length < 2) return locs;
  return [...locs].sort((a, b) => distanceKm(origin, a) - distanceKm(origin, b));
}

function emptyVoterInfo(): VoterInfo {
  return {
    electionName: null,
    electionDate: null,
    dropOffLocations: [],
    earlyVoteSites: [],
    pollingLocations: [],
    ballotInfoUrl: null,
    electionInfoUrl: null,
    votingLocationFinderUrl: null,
    source: SOURCE_LABEL,
  };
}

// ---------------------------------------------------------------------------
// getVoterInfo
//
// Returns normalized voter info for an address. Never throws on "no live
// election" or upstream errors — returns a safe empty payload so the route
// can always respond 200 and the UI can fall back to official links.
// ---------------------------------------------------------------------------

export async function getVoterInfo(address: string): Promise<VoterInfo> {
  // Reuse the shared Google Cloud key: prefer a dedicated GOOGLE_CIVIC_API_KEY,
  // else fall back to the Maps/Places key so we don't need a second Render var.
  // (The key's Google Cloud project must have the Civic Information API enabled,
  // and the key must not be HTTP-referrer-restricted — server-side calls send no
  // referrer; use an unrestricted or IP-restricted key.)
  const apiKey = env.GOOGLE_CIVIC_API_KEY || env.GOOGLE_MAPS_API_KEY;
  if (!apiKey) {
    console.warn('[voterInfo] No Google API key (GOOGLE_CIVIC_API_KEY / GOOGLE_MAPS_API_KEY) — returning empty payload');
    return emptyVoterInfo();
  }

  const url = new URL(CIVIC_ENDPOINT);
  url.searchParams.set('key', apiKey);
  url.searchParams.set('address', address);

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  let response: Response;
  try {
    response = await fetch(url.toString(), { signal: controller.signal });
  } catch {
    clearTimeout(timeout);
    console.error('[voterInfo] Civic API request failed (timeout/network)');
    return emptyVoterInfo();
  }
  clearTimeout(timeout);

  // 400 commonly means "no live election for this address" — expected off-cycle.
  // Any non-2xx: degrade gracefully to the empty payload.
  if (!response.ok) {
    if (response.status !== 400) {
      console.error(`[voterInfo] Civic API returned ${response.status}`);
    }
    return emptyVoterInfo();
  }

  let data: CivicVoterInfoResponse;
  try {
    data = (await response.json()) as CivicVoterInfoResponse;
  } catch {
    console.error('[voterInfo] Civic API returned unparseable JSON');
    return emptyVoterInfo();
  }

  const admin = data.state?.[0]?.electionAdministrationBody;

  // Order locations nearest-first so the UI can surface the closest few.
  // Best-effort: if geocoding the address fails (PO box, geocoder down), we keep
  // the API's order rather than failing the whole request.
  let origin: { lat: number; lng: number } | null;
  try {
    const g = await geocodeAddress(address);
    origin = { lat: g.lat, lng: g.lng };
  } catch {
    origin = null;
  }

  return {
    electionName: data.election?.name ?? null,
    electionDate: data.election?.electionDay ?? null,
    dropOffLocations: sortByDistance((data.dropOffLocations ?? []).map(mapLocation), origin),
    earlyVoteSites: sortByDistance((data.earlyVoteSites ?? []).map(mapLocation), origin),
    pollingLocations: sortByDistance((data.pollingLocations ?? []).map(mapLocation), origin),
    ballotInfoUrl: admin?.ballotInfoUrl ?? null,
    electionInfoUrl: admin?.electionInfoUrl ?? null,
    votingLocationFinderUrl: admin?.votingLocationFinderUrl ?? null,
    source: SOURCE_LABEL,
  };
}
