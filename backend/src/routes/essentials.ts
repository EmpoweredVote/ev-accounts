import { Router } from 'express';
import type { Request, Response } from 'express';
import { optionalAuth, requireAuth } from '../middleware/auth.js';
import type { AuthenticatedRequest } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import {
  getRepresentativesByAddress,
  getRepresentativesByJurisdiction,
  getLocalOfficialsByUserId,
  getGovernmentById,
  getChamberById,
  getDistrictById,
} from '../lib/essentialsService.js';
import type { JurisdictionGeoIds } from '../lib/essentialsService.js';
import { getElectionsByCoordinate, getElectionsByGeoIds, getCandidateById } from '../lib/electionService.js';
import type { GeoPair } from '../lib/geoIdGuard.js';
import { getVoterInfo } from '../lib/voterInfoService.js';
import { GeocodingError, geocodeAddress } from '../lib/geocodingService.js';
import { pool } from '../lib/db.js';
import { adminRpc } from '../lib/supabase.js';

/**
 * Build MTFCC-tagged (geo_id, mtfcc) pairs from a connected profile's typed
 * jurisdiction geo_id slots. Each slot has a known layer, so we attach the
 * matching MTFCC — this lets getElectionsByGeoIds apply MTFCC_DISTRICT_TYPE_GUARD
 * and avoid 5-digit GEOID collisions (e.g. a county_geo_id of "49021" must not
 * also match State Senate District 21). Empty slots are dropped downstream.
 */
function electionGeoPairsFromSlots(slots: {
  congressional_geo_id?: string | null;
  state_senate_geo_id?: string | null;
  state_house_geo_id?: string | null;
  county_geo_id?: string | null;
  school_district_geo_id?: string | null;
  city_council_geo_id?: string | null;
  municipality_geo_id?: string | null;
}): GeoPair[] {
  const slotMtfcc: Array<[string | null | undefined, string]> = [
    [slots.congressional_geo_id, 'G5200'],
    [slots.state_senate_geo_id, 'G5210'],
    [slots.state_house_geo_id, 'G5220'],
    [slots.county_geo_id, 'G4020'],
    [slots.school_district_geo_id, 'G5400'],
    [slots.city_council_geo_id, 'G4110'],
    [slots.municipality_geo_id, 'G4110'],
  ];
  return slotMtfcc
    .filter(([geoId]) => !!geoId)
    .map(([geoId, mtfcc]) => ({ geo_id: geoId as string, mtfcc }));
}

// D-11 (Phase 164.1 + 164.2): states whose 2026 congressional geometry is dual-mapped
// (G5200V26 rows) while cached congressional_geo_id still reflects the old map.
// 164.1: TN=47, MO=29, AL=01, LA=22, UT=49.  164.2: FL=12, CA=06, NC=37, OH=39, TX=48.
const REFRESHED_2026_FIPS = new Set(['47', '29', '01', '22', '49', '12', '06', '37', '39', '48']);

/**
 * D-11 read-only fallback: when a Connected user's congressional_geo_id sits in
 * a 2026-refresh state and coords are on file, re-resolve the congressional
 * district LIVE against the G5200V26 vintage via connect.resolve_congressional_2026
 * (SECURITY DEFINER, decrypts server-side, no cache mutation). Returns the NEW
 * district geo_id, or null to keep the cached value (not a refreshed state, no
 * coverage, no coords, or RPC error). Retired by the Jan-2027 promotion phase.
 */
async function resolveCongressional2026(
  userId: string,
  cachedGeoId: string | null | undefined,
  hasCoords: boolean
): Promise<string | null> {
  if (!hasCoords || !cachedGeoId || !REFRESHED_2026_FIPS.has(cachedGeoId.slice(0, 2))) {
    return null;
  }
  try {
    const { data, error } = await adminRpc('resolve_congressional_2026', { p_user_id: userId }, 'connect');
    if (error || typeof data !== 'string' || !data) return null;
    return data;
  } catch {
    return null;
  }
}

/**
 * Essentials router — address-search and other top-level essentials routes.
 *
 * Mounted at /api/essentials in index.ts.
 * Note: /api/essentials/politicians and /api/essentials/candidates are
 * mounted separately in index.ts and take precedence over this router's
 * catch-all paths due to more-specific mount paths.
 */

const router = Router();

// UUID validation regex — shared by entity routes
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ---------------------------------------------------------------------------
// GET /api/essentials/race-candidates/:id
// Auth: optional — public data (candidate profiles are public)
// Returns a single race candidate's detail including linked politician_id.
// Withdrawn candidates return 404.
//
// Error codes:
//   422 VALIDATION_ERROR  — invalid UUID format
//   404 NOT_FOUND         — candidate not found or withdrawn
//   500 INTERNAL_ERROR    — unexpected server error
// ---------------------------------------------------------------------------

router.get('/race-candidates/:id', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!UUID_RE.test(id)) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'id must be a valid UUID' });
    return;
  }

  try {
    const candidate = await getCandidateById(id);
    if (!candidate) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Candidate not found' });
      return;
    }
    res.json(candidate);
  } catch (err) {
    console.error('[GET /essentials/race-candidates/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch candidate data' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/elections?lat=X&lng=Y
// Auth: optional — public data (per D-13)
// Returns upcoming elections with races and candidates for a coordinate.
// Withdrawn candidates are excluded. Only future elections returned.
//
// Error codes:
//   422 VALIDATION_ERROR  — missing or non-numeric lat/lng parameters
//   500 INTERNAL_ERROR    — unexpected server error
// ---------------------------------------------------------------------------

router.get('/elections', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const lat = parseFloat(req.query.lat as string);
  const lng = parseFloat(req.query.lng as string);

  if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'lat must be in [-90, 90] and lng must be in [-180, 180]' });
    return;
  }

  try {
    const elections = await getElectionsByCoordinate(lat, lng);
    res.json({ elections });
  } catch (err) {
    console.error('[elections] error:', (err as Error).message);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch election data' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/elections-by-address?address=...
// Auth: optional — public data (same as /elections)
// Accepts a human-readable address, geocodes it internally, and returns
// upcoming elections with races and candidates. Keeps raw lat/lng server-side.
//
// Error codes:
//   422 VALIDATION_ERROR      — missing or empty address query parameter
//   503 GEOCODER_UNAVAILABLE  — Census Geocoder timeout or outage
//   500 INTERNAL_ERROR        — unexpected server error
// Note: ADDRESS_NOT_FOUND and PO_BOX_REJECTED return 200 { elections: [] }
// ---------------------------------------------------------------------------

router.get('/elections-by-address', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const address = typeof req.query.address === 'string' ? req.query.address.trim() : null;
  if (!address) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'address query parameter is required' });
    return;
  }

  try {
    const { lat, lng } = await geocodeAddress(address);
    const elections = await getElectionsByCoordinate(lat, lng);
    res.json({ elections });
  } catch (err) {
    if (err instanceof GeocodingError) {
      if (err.code === 'ADDRESS_NOT_FOUND' || err.code === 'PO_BOX_REJECTED') {
        res.json({ elections: [] });
        return;
      }
      if (err.code === 'GEOCODER_UNAVAILABLE') {
        res.status(503).json({ code: 'GEOCODER_UNAVAILABLE', message: 'Address lookup temporarily unavailable.' });
        return;
      }
    }
    console.error('[GET /essentials/elections-by-address] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch election data' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/voter-info?address=...
// Auth: optional — public data
// Proxies Google Civic voterInfoQuery (VIP) for in-person voting locations and
// official sample-ballot / election-info URLs keyed to the voter's address.
// Always returns 200 with a normalized payload; off-cycle/no-live-election and
// upstream errors degrade to a safe empty payload (the UI falls back to links).
//
// Error codes:
//   422 VALIDATION_ERROR  — missing or empty address query parameter
// ---------------------------------------------------------------------------

router.get('/voter-info', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const address = typeof req.query.address === 'string' ? req.query.address.trim() : null;
  if (!address) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'address query parameter is required' });
    return;
  }

  const voterInfo = await getVoterInfo(address);
  res.json(voterInfo);
});

// ---------------------------------------------------------------------------
// GET /api/essentials/address-search?address=...
// Auth: optional — works unauthenticated (public data)
// Returns politicians for the given address via Census Geocoder + PostGIS.
// data_level: 'inform' (unauthenticated) or 'connected' (authenticated).
//
// Error codes:
//   422 VALIDATION_ERROR      — missing address query parameter
//   422 ADDRESS_NOT_FOUND     — Census returned no match for the address
//   422 PO_BOX_REJECTED       — PO Box addresses not supported
//   503 GEOCODER_UNAVAILABLE  — Census outage, timeout, or network error
//   500 INTERNAL_ERROR        — unexpected server error
// ---------------------------------------------------------------------------

router.get('/address-search', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const address = typeof req.query.address === 'string' ? req.query.address.trim() : null;
  if (!address) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'address query parameter is required' });
    return;
  }

  const userId = (req as AuthenticatedRequest).userId;

  try {
    const result = await getRepresentativesByAddress(address);
    const data_level = userId ? 'connected' : 'inform';
    res.status(200).json({ ...result, data_level });
  } catch (err) {
    if (err instanceof GeocodingError) {
      if (err.code === 'ADDRESS_NOT_FOUND') {
        res.status(422).json({ code: 'ADDRESS_NOT_FOUND', message: err.message });
        return;
      }
      if (err.code === 'PO_BOX_REJECTED') {
        res.status(422).json({ code: 'PO_BOX_REJECTED', message: err.message });
        return;
      }
      if (err.code === 'GEOCODER_UNAVAILABLE') {
        res.status(503).json({ code: 'GEOCODER_UNAVAILABLE', message: 'Address lookup temporarily unavailable.' });
        return;
      }
    }
    console.error('[GET /essentials/address-search] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/quotes
// Auth: none — public endpoint (Read & Rank uses plain fetch, no Bearer token)
// Returns { quotes, candidates, issues } — the full dataset for the Read & Rank app.
//
// Optional query param: ?politician_id=<uuid>
//   When provided, returns only quotes for that politician (used by StanceAccordion
//   in the profile view). When absent, returns all quotes (Read & Rank behavior).
//
// quotes[].issue   = topic_key slug (matches compass topics)
// quotes[].candidateId = politician UUID
// candidates[]     = deduplicated active politicians who have quotes
// issues[]         = deduplicated compass topics that have quotes
// ---------------------------------------------------------------------------

router.get('/quotes', async (req: Request, res: Response): Promise<void> => {
  // Optional single-politician filter — used by StanceAccordion on profile pages
  const politicianIdParam = typeof req.query.politician_id === 'string'
    ? req.query.politician_id.trim()
    : null;

  if (politicianIdParam !== null && !UUID_RE.test(politicianIdParam)) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'politician_id must be a valid UUID' });
    return;
  }

  try {
    const queryParams: string[] = [];
    const whereClauses: string[] = ['p.is_active = true'];

    if (politicianIdParam) {
      queryParams.push(politicianIdParam);
      whereClauses.push(`q.politician_id = $${queryParams.length}`);
    }

    const whereSQL = whereClauses.join(' AND ');

    const { rows } = await pool.query(`
      SELECT
        q.id                    AS quote_id,
        q.quote_text,
        COALESCE(q.deidentified_text, q.quote_text) AS text,
        q.politician_id,
        q.source_url,
        q.source_name,
        p.full_name             AS politician_name,
        p.party                 AS politician_party,
        p.photo_origin_url      AS politician_photo,
        o.title                 AS office_title,
        ct.id                   AS topic_id,
        ct.topic_key            AS topic_key,
        ctc.short_title         AS topic_title,
        ctc.question_text       AS topic_question
      FROM essentials.quotes q
      JOIN essentials.politicians p ON p.id = q.politician_id AND ${whereSQL}
      LEFT JOIN LATERAL (
        -- ADR 0002 phase 5: offices.politician_id is gone; occupancy resolves via current_office_holders.
        SELECT o.title
        FROM essentials.current_office_holders coh
        JOIN essentials.offices o ON o.id = coh.office_id
        WHERE coh.politician_id = p.id
        ORDER BY o.id DESC
        LIMIT 1
      ) o ON true
      LEFT JOIN inform.compass_topics ct ON ct.topic_key = lower(q.topic_key) AND ct.is_live = true
      -- TEXT ONLY (ADR 0004). ct keeps the match and the is_live gate; ctc carries
      -- the current revision's wording, which CA_0012's freeze trigger means ct
      -- itself can no longer receive. Voter-facing, so stale text here is a
      -- content error rather than a cosmetic one.
      LEFT JOIN inform.compass_topics_current ctc ON ctc.id = ct.id
      ORDER BY p.full_name, q.topic_key
    `, queryParams);

    // Build quotes array — only include quotes where the topic matched
    const quotes = rows
      .filter((r) => r.topic_id !== null)
      .map((r) => ({
        id: r.quote_id as string,
        text: r.text as string,
        candidateId: r.politician_id as string,
        issue: r.topic_key as string,
        sourceUrl: r.source_url as string | null ?? undefined,
        sourceName: r.source_name as string | null ?? undefined,
      }));

    // Deduplicate candidates (politicians who appear in at least one matched quote)
    const candidateMap = new Map<string, object>();
    for (const r of rows.filter((r) => r.topic_id !== null)) {
      if (!candidateMap.has(r.politician_id as string)) {
        candidateMap.set(r.politician_id as string, {
          id: r.politician_id,
          name: r.politician_name ?? '',
          party: r.politician_party ?? '',
          office: r.office_title ?? '',
          photo: r.politician_photo ?? '',
          alignmentPercent: 0,
          issuesAligned: 0,
          totalIssues: 0,
        });
      }
    }
    const candidates = Array.from(candidateMap.values());

    // Deduplicate issues (topics that appear in at least one matched quote)
    // Key by topic_key (slug) to match quotes[].issue
    const issueMap = new Map<string, object>();
    for (const r of rows.filter((r) => r.topic_id !== null)) {
      const key = r.topic_key as string;
      if (key && !issueMap.has(key)) {
        issueMap.set(key, {
          id: key,
          title: r.topic_title ?? '',
          question: r.topic_question ?? '',
        });
      }
    }
    const issues = Array.from(issueMap.values());

    res.status(200).json({ quotes, candidates, issues });
  } catch (err) {
    console.error('[GET /essentials/quotes] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/cities/:geo_id/building-photo
// Returns building photo for a city by Census GEOID.
// Matches Go server /cities/{geo_id}/building-photo response shape.
// ---------------------------------------------------------------------------

router.get('/cities/:geo_id/building-photo', async (req: Request, res: Response): Promise<void> => {
  const geoId = req.params.geo_id as string;
  if (!geoId) {
    res.status(400).json({ code: 'VALIDATION_ERROR', message: 'Missing geo_id parameter' });
    return;
  }

  try {
    const { rows } = await pool.query(
      `SELECT place_geoid, url, license, attribution, source_url, fetched_at
       FROM essentials.building_photos
       WHERE place_geoid = $1`,
      [geoId]
    );

    if (rows.length === 0) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Building photo not found' });
      return;
    }

    const r = rows[0];
    res.status(200).json({
      place_geoid: r.place_geoid ?? '',
      url: r.url ?? '',
      license: r.license ?? '',
      attribution: r.attribution ?? '',
      source_url: r.source_url ?? '',
      fetched_at: r.fetched_at ?? null,
    });
  } catch (err) {
    console.error('[GET /essentials/cities/:geo_id/building-photo] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/governments/:id
// Auth: optional — public entity data
// Returns government details with nested chambers list.
// data_level: 'inform' (unauthenticated) or 'connected' (authenticated).
//
// Error codes:
//   422 VALIDATION_ERROR  — invalid UUID format
//   404 NOT_FOUND         — government not found
//   500 INTERNAL_ERROR    — unexpected server error
// ---------------------------------------------------------------------------

router.get('/governments/:id', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!UUID_RE.test(id)) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'id must be a valid UUID' });
    return;
  }

  const userId = (req as AuthenticatedRequest).userId;

  try {
    const government = await getGovernmentById(id);
    if (government === null) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Government not found' });
      return;
    }
    const data_level = userId ? 'connected' : 'inform';
    res.status(200).json({ ...government, data_level });
  } catch (err) {
    console.error('[GET /essentials/governments/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/chambers/:id
// Auth: optional — public entity data
// Returns chamber details with parent government context.
// data_level: 'inform' (unauthenticated) or 'connected' (authenticated).
//
// Error codes:
//   422 VALIDATION_ERROR  — invalid UUID format
//   404 NOT_FOUND         — chamber not found
//   500 INTERNAL_ERROR    — unexpected server error
// ---------------------------------------------------------------------------

router.get('/chambers/:id', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!UUID_RE.test(id)) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'id must be a valid UUID' });
    return;
  }

  const userId = (req as AuthenticatedRequest).userId;

  try {
    const chamber = await getChamberById(id);
    if (chamber === null) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Chamber not found' });
      return;
    }
    const data_level = userId ? 'connected' : 'inform';
    res.status(200).json({ ...chamber, data_level });
  } catch (err) {
    console.error('[GET /essentials/chambers/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/districts/:id
// Auth: optional — public entity data
// Returns district details with active politicians, chamber, and government.
// data_level: 'inform' (unauthenticated) or 'connected' (authenticated).
//
// Error codes:
//   422 VALIDATION_ERROR  — invalid UUID format
//   404 NOT_FOUND         — district not found
//   500 INTERNAL_ERROR    — unexpected server error
// ---------------------------------------------------------------------------

router.get('/districts/:id', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!UUID_RE.test(id)) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'id must be a valid UUID' });
    return;
  }

  const userId = (req as AuthenticatedRequest).userId;

  try {
    const district = await getDistrictById(id);
    if (district === null) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'District not found' });
      return;
    }
    const data_level = userId ? 'connected' : 'inform';
    res.status(200).json({ ...district, data_level });
  } catch (err) {
    console.error('[GET /essentials/districts/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/representatives/me
// Auth: required (Connected tier)
// Returns politicians for the authenticated user's stored jurisdiction.
// No geocoding — uses the GEOIDs from the user's saved location directly.
// Returns 204 if the user has no location on file (consent not granted or
// location never set). Returns 403 NOT_CONNECTED for Inform-tier users.
// ---------------------------------------------------------------------------

router.get('/representatives/me', requireAuth, requireConnected, async (req: Request, res: Response): Promise<void> => {
  const { userId } = req as AuthenticatedRequest;

  // Single query: fetch all location fields + has_coords flag in one round-trip.
  const { rows } = await pool.query<{
    congressional_geo_id: string | null;
    state_senate_geo_id: string | null;
    state_house_geo_id: string | null;
    county_geo_id: string | null;
    school_district_geo_id: string | null;
    jurisdiction_state: string | null;
    jurisdiction_city: string | null;
    has_coords: boolean;
  }>(
    `SELECT congressional_geo_id, state_senate_geo_id, state_house_geo_id,
             county_geo_id, school_district_geo_id,
             jurisdiction_state, jurisdiction_city,
             (encrypted_lat IS NOT NULL) AS has_coords
      FROM connect.connected_profiles WHERE user_id = $1`,
    [userId]
  ).catch(() => ({ rows: [] as any[] }));
  const j = rows[0];

  // --- Path 0: TIGER user_districts cache — fastest path (added in Phase 70) ---
  // Source: connect.user_districts populated by essentials.cache_user_districts on
  // every location write. Joins via (tiger_geoid, district_type) — BOTH required
  // because tiger_geoid is non-unique across SLDL/SLDU layers (e.g. assembly D20
  // and senate D20 both have tiger_geoid='06020').
  //
  // districtRows is hoisted to handler scope so Path 1.5 can read its length to
  // decide whether to fire opportunistic backfill (see Change B below).
  let districtRows: Array<{ layer: string; geoid: string }> = [];
  try {
    const result = await pool.query<{ layer: string; geoid: string }>(
      `SELECT layer, geoid FROM connect.user_districts WHERE user_id = $1`,
      [userId]
    );
    districtRows = result.rows;

    if (districtRows.length > 0) {
      const layerTypeMap: Record<string, string> = {
        ca_assembly:       'STATE_LOWER',
        ca_senate:         'STATE_UPPER',
        us_house:          'NATIONAL_LOWER',
        school_unified:    'SCHOOL_UNIFIED',     // Phase 71: forward-compat — no rows in essentials.districts yet
        school_elementary: 'SCHOOL_ELEMENTARY',  // Phase 71: forward-compat — same
        school_secondary:  'SCHOOL_SECONDARY',   // Phase 71: forward-compat — same
      };

      // Build OR conditions: (tiger_geoid = $N AND district_type = $N+1) per layer
      const params: string[] = [];
      const conditions: string[] = [];
      for (const row of districtRows) {
        const distType = layerTypeMap[row.layer];
        if (!distType) continue;
        params.push(row.geoid, distType);
        conditions.push(
          `(d.tiger_geoid = $${params.length - 1} AND d.district_type = $${params.length})`
        );
      }

      if (conditions.length > 0) {
        const { rows: geoRows } = await pool.query<{
          district_type: string;
          geo_id: string;
        }>(
          `SELECT d.district_type, d.geo_id
             FROM essentials.districts d
            WHERE ${conditions.join(' OR ')}`,
          params
        );

        const typeToField: Record<string, keyof JurisdictionGeoIds> = {
          NATIONAL_LOWER: 'congressional',
          STATE_UPPER:    'state_senate',
          STATE_LOWER:    'state_house',
        };
        const jurisdiction: JurisdictionGeoIds = {
          congressional:   null,
          state_senate:    null,
          state_house:     null,
          county:          null,
          school_district: null,
        };
        for (const r of geoRows) {
          const field = typeToField[r.district_type];
          if (field) jurisdiction[field] = r.geo_id;
        }

        if (jurisdiction.congressional || jurisdiction.state_senate) {
          const [politicians, localOfficials] = await Promise.all([
            getRepresentativesByJurisdiction(jurisdiction),
            getLocalOfficialsByUserId(userId),
          ]);

          const seenIds = new Set(politicians.map((p) => p.id));
          const uniqueLocals = localOfficials.filter((p) => !seenIds.has(p.id));
          const merged = [...politicians, ...uniqueLocals];

          const dataStatus = merged.length === 0 ? 'no-geofence-data' : 'fresh';
          res.setHeader('X-Data-Status', dataStatus);
          res.setHeader(
            'X-Formatted-Address',
            [j?.jurisdiction_city, j?.jurisdiction_state].filter(Boolean).join(', ')
          );
          res.status(200).json(merged);
          return;
        }
      }
    }
  } catch (err) {
    // Path 0 failure (PostGIS hiccup, missing geo_districts row, etc.) — fall
    // through to Path 1. Path 1 / 1.5 will handle the request. Log at warn level
    // so persistent failures show up in operator dashboards but don't pollute
    // info-level logs for every Inform-tier (no-cache) request.
    console.warn(
      '[representatives/me] Path 0 failed, falling to Path 1:',
      err instanceof Error ? err.message : String(err)
    );
  }

  // --- Path 1: stored jurisdiction GEO IDs — fast direct lookup ---
  if (j && (j.congressional_geo_id || j.state_senate_geo_id)) {
    try {
      const [politicians, localOfficials] = await Promise.all([
        getRepresentativesByJurisdiction({
          congressional: j.congressional_geo_id,
          state_senate: j.state_senate_geo_id,
          state_house: j.state_house_geo_id,
          county: j.county_geo_id,
          school_district: j.school_district_geo_id,
        }),
        getLocalOfficialsByUserId(userId),
      ]);

      // Merge local officials, deduplicating by politician ID
      const seenIds = new Set(politicians.map((p) => p.id));
      const uniqueLocals = localOfficials.filter((p) => !seenIds.has(p.id));
      const merged = [...politicians, ...uniqueLocals];

      const dataStatus = merged.length === 0 ? 'no-geofence-data' : 'fresh';
      res.setHeader('X-Data-Status', dataStatus);
      res.setHeader('X-Formatted-Address', [j.jurisdiction_city, j.jurisdiction_state].filter(Boolean).join(', '));
      res.status(200).json(merged);
      return;
    } catch {
      // fall through to Path 1.5
    }
  }

  // --- Path 1.5: encrypted coords present but geo_ids not yet stored (pre-Phase-49 users) ---
  if (j && j.has_coords && !j.congressional_geo_id && !j.state_senate_geo_id) {
    try {
      const { data: jData, error: jError } = await adminRpc('resolve_user_jurisdiction', {
        p_user_id: userId,
      }, 'connect');

      if (!jError && jData) {
        const jd = jData as Record<string, string | null>;

        // Fire-and-forget write-back of 10 resolvable columns
        void pool.query(
          `UPDATE connect.connected_profiles
           SET congressional_geo_id        = $2,
               congressional_district_name = $3,
               state_senate_geo_id         = $4,
               state_senate_district_name  = $5,
               state_house_geo_id          = $6,
               state_house_district_name   = $7,
               county_geo_id               = $8,
               county_name                 = $9,
               school_district_geo_id      = $10,
               school_district_name        = $11,
               updated_at                  = now()
           WHERE user_id = $1`,
          [userId, jd.congressional ?? null, jd.congressional_name ?? null,
           jd.state_senate ?? null, jd.state_senate_name ?? null,
           jd.state_house ?? null, jd.state_house_name ?? null,
           jd.county ?? null, jd.county_name ?? null,
           jd.school_district ?? null, jd.school_district_name ?? null]
        ).catch((e: Error) => console.error('[representatives/me] Path 1.5 write-back error:', e.message));

        // Only serve if at least one geo_id resolved — otherwise fall through to Path 2
        if (jd.congressional || jd.state_senate) {
          const [politicians, localOfficials] = await Promise.all([
            getRepresentativesByJurisdiction({
              congressional: jd.congressional,
              state_senate: jd.state_senate,
              state_house: jd.state_house,
              county: jd.county,
              school_district: jd.school_district,
            }),
            getLocalOfficialsByUserId(userId),
          ]);

          const seenIds = new Set(politicians.map((p) => p.id));
          const uniqueLocals = localOfficials.filter((p) => !seenIds.has(p.id));
          const merged = [...politicians, ...uniqueLocals];

          const dataStatus = merged.length === 0 ? 'no-geofence-data' : 'fresh';
          res.setHeader('X-Data-Status', dataStatus);
          res.setHeader('X-Formatted-Address', [j.jurisdiction_city, j.jurisdiction_state].filter(Boolean).join(', '));
          res.status(200).json(merged);

          // Opportunistic backfill (Phase 70): if this user had NO user_districts
          // rows when the request arrived, populate the cache now so their NEXT
          // call lands on Path 0. Fire-and-forget — response is already on the
          // wire; do NOT await. Errors are swallowed via .catch() — this is a
          // best-effort cache warm and must never affect this response.
          if (districtRows.length === 0) {
            void pool.query(
              `SELECT essentials.recache_user_districts_for_user($1)`,
              [userId]
            ).catch((e: Error) =>
              console.warn(
                '[representatives/me] Path 1.5 opportunistic backfill failed:',
                e.message
              )
            );
          }

          return;
        }
        // All-null from RPC (no boundary match) — fall through to 204
      }
    } catch {
      // RPC error — fall through to 204
    }
  }

  // No usable location data — coordinates not yet set or jurisdiction unresolvable
  res.status(204).end();
});

// ---------------------------------------------------------------------------
// GET /api/essentials/elections/me
// Auth: required (Connected tier)
// Returns upcoming elections for the authenticated user's stored location.
// Uses stored geo_ids for a direct district match — no geocoding, no coord
// decryption. Mirrors the fast path of representatives/me.
// Returns 204 if the user has no location on file.
// X-Formatted-Address: city-level label (jurisdiction_city + jurisdiction_state)
// ---------------------------------------------------------------------------

router.get('/elections/me', requireAuth, requireConnected, async (req: Request, res: Response): Promise<void> => {
  const { userId } = req as AuthenticatedRequest;

  const { rows } = await pool.query<{
    congressional_geo_id: string | null;
    state_senate_geo_id: string | null;
    state_house_geo_id: string | null;
    county_geo_id: string | null;
    school_district_geo_id: string | null;
    city_council_geo_id: string | null;
    municipality_geo_id: string | null;
    jurisdiction_state: string | null;
    jurisdiction_city: string | null;
    has_coords: boolean;
  }>(
    `SELECT congressional_geo_id, state_senate_geo_id, state_house_geo_id,
             county_geo_id, school_district_geo_id, city_council_geo_id,
             municipality_geo_id,
             jurisdiction_state, jurisdiction_city,
             (encrypted_lat IS NOT NULL) AS has_coords
      FROM connect.connected_profiles WHERE user_id = $1`,
    [userId]
  ).catch(() => ({ rows: [] as any[] }));
  const j = rows[0];

  // Path 1: stored geo_ids present — direct district match
  if (j && (j.congressional_geo_id || j.state_senate_geo_id || j.county_geo_id)) {
    try {
      // D-11: substitute the live G5200V26-resolved congressional geo_id when the
      // cached one is in a 2026-refresh state (read-only; cache stays untouched).
      // The pair keeps mtfcc 'G5200' — races key on geo_id + NATIONAL_LOWER guard.
      const corrected2026 = await resolveCongressional2026(userId, j.congressional_geo_id, j.has_coords);
      const elections = await getElectionsByGeoIds(
        electionGeoPairsFromSlots(
          corrected2026 ? { ...j, congressional_geo_id: corrected2026 } : j
        ),
        j.jurisdiction_state
      );
      res.setHeader('X-Formatted-Address', [j.jurisdiction_city, j.jurisdiction_state].filter(Boolean).join(', '));
      res.status(200).json({ elections });
      return;
    } catch {
      // fall through to Path 1.5
    }
  }

  // Path 1.5: encrypted coords present but geo_ids not yet stored (pre-Phase-49 users)
  if (j && j.has_coords && !j.congressional_geo_id && !j.state_senate_geo_id && !j.county_geo_id) {
    try {
      const { data: jData, error: jError } = await adminRpc('resolve_user_jurisdiction', {
        p_user_id: userId,
      }, 'connect');

      if (!jError && jData) {
        const jd = jData as Record<string, string | null>;

        // Fire-and-forget write-back of resolvable columns
        void pool.query(
          `UPDATE connect.connected_profiles
           SET congressional_geo_id        = $2,
               congressional_district_name = $3,
               state_senate_geo_id         = $4,
               state_senate_district_name  = $5,
               state_house_geo_id          = $6,
               state_house_district_name   = $7,
               county_geo_id               = $8,
               county_name                 = $9,
               school_district_geo_id      = $10,
               school_district_name        = $11,
               municipality_geo_id         = $12,
               updated_at                  = now()
           WHERE user_id = $1`,
          [userId, jd.congressional ?? null, jd.congressional_name ?? null,
           jd.state_senate ?? null, jd.state_senate_name ?? null,
           jd.state_house ?? null, jd.state_house_name ?? null,
           jd.county ?? null, jd.county_name ?? null,
           jd.school_district ?? null, jd.school_district_name ?? null,
           jd.municipality ?? null]
        ).catch((e: Error) => console.error('[elections/me] Path 1.5 write-back error:', e.message));

        if (jd.congressional || jd.state_senate || jd.county) {
          // D-11: resolve_user_jurisdiction is hardcoded to G5200, so its
          // congressional result is also pre-2026 — apply the same live
          // substitution (coords exist by definition on this path).
          const corrected2026 = await resolveCongressional2026(userId, jd.congressional, true);
          const elections = await getElectionsByGeoIds(
            electionGeoPairsFromSlots({
              congressional_geo_id: corrected2026 ?? jd.congressional,
              state_senate_geo_id: jd.state_senate,
              state_house_geo_id: jd.state_house,
              county_geo_id: jd.county,
              school_district_geo_id: jd.school_district,
              city_council_geo_id: jd.city_council,
              municipality_geo_id: jd.municipality,
            }),
            j.jurisdiction_state
          );
          res.setHeader('X-Formatted-Address', [j.jurisdiction_city, j.jurisdiction_state].filter(Boolean).join(', '));
          res.status(200).json({ elections });
          return;
        }
      }
    } catch {
      // fall through to 204
    }
  }

  res.status(204).end();
});

export default router;
