import { Router } from 'express';
import type { Request, Response } from 'express';
import { optionalAuth, requireAuth } from '../middleware/auth.js';
import type { AuthenticatedRequest } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import {
  getRepresentativesByAddress,
  getRepresentativesByJurisdiction,
  getGovernmentById,
  getChamberById,
  getDistrictById,
} from '../lib/essentialsService.js';
import { getElectionsByCoordinate } from '../lib/electionService.js';
import { pool } from '../lib/db.js';
import { GeocodingError } from '../lib/geocodingService.js';

/**
 * Essentials router — address-search and other top-level essentials routes.
 *
 * Mounted at /api/essentials in index.ts.
 * Note: /api/essentials/politicians and /api/essentials/candidates are
 * mounted separately in index.ts and take precedence over this router's
 * catch-all paths due to more-specific mount paths.
 */

const router = Router();

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

  if (isNaN(lat) || isNaN(lng)) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'lat and lng query parameters are required (numeric)' });
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
// quotes[].issue = compass_topic UUID (not topic_key slug)
// candidates[] = deduplicated active politicians who have quotes
// issues[] = deduplicated compass topics that have quotes
// ---------------------------------------------------------------------------

router.get('/quotes', async (_req: Request, res: Response): Promise<void> => {
  try {
    const { rows } = await pool.query(`
      SELECT
        q.id                    AS quote_id,
        q.quote_text,
        q.politician_id,
        q.source_url,
        q.source_name,
        p.full_name             AS politician_name,
        p.party                 AS politician_party,
        p.photo_origin_url      AS politician_photo,
        o.title                 AS office_title,
        ct.id                   AS topic_id,
        ct.short_title          AS topic_title,
        ct.question_text        AS topic_question
      FROM essentials.quotes q
      JOIN essentials.politicians p ON p.id = q.politician_id AND p.is_active = true
      LEFT JOIN essentials.offices o ON o.politician_id = p.id
      LEFT JOIN inform.compass_topics ct
        ON lower(replace(ct.short_title, ' ', '-')) = lower(q.topic_key)
        OR lower(ct.short_title) = lower(q.topic_key)
      ORDER BY p.full_name, q.topic_key
    `);

    // Build quotes array — only include quotes where the topic matched
    const quotes = rows
      .filter((r) => r.topic_id !== null)
      .map((r) => ({
        id: r.quote_id as string,
        text: r.quote_text as string,
        candidateId: r.politician_id as string,
        issue: r.topic_id as string,
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
    const issueMap = new Map<string, object>();
    for (const r of rows.filter((r) => r.topic_id !== null)) {
      if (!issueMap.has(r.topic_id as string)) {
        issueMap.set(r.topic_id as string, {
          id: r.topic_id,
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

// UUID validation regex — shared by entity routes
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

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

  // Fetch the user's home_address unconditionally — needed for both paths below.
  const { rows: profileRows } = await pool.query<{ home_address: string | null }>(
    `SELECT home_address FROM connect.connected_profiles WHERE user_id = $1`,
    [userId]
  ).catch(() => ({ rows: [] as { home_address: string | null }[] }));
  const homeAddress = profileRows[0]?.home_address ?? '';

  // --- Path 1: stored jurisdiction GEO IDs — fast direct lookup ---
  try {
    const { rows } = await pool.query<{
      congressional_geo_id: string | null;
      state_senate_geo_id: string | null;
      state_house_geo_id: string | null;
      county_geo_id: string | null;
      school_district_geo_id: string | null;
      jurisdiction_state: string | null;
      jurisdiction_city: string | null;
    }>(
      `SELECT congressional_geo_id, state_senate_geo_id, state_house_geo_id,
              county_geo_id, school_district_geo_id,
              jurisdiction_state, jurisdiction_city
       FROM connect.connected_profiles WHERE user_id = $1`,
      [userId]
    );
    const j = rows[0];
    if (j && (j.congressional_geo_id || j.state_senate_geo_id)) {
      const politicians = await getRepresentativesByJurisdiction({
        congressional: j.congressional_geo_id,
        state_senate: j.state_senate_geo_id,
        state_house: j.state_house_geo_id,
        county: j.county_geo_id,
        school_district: j.school_district_geo_id,
      });
      const dataStatus = politicians.length === 0 ? 'no-geofence-data' : 'fresh';
      res.setHeader('X-Data-Status', dataStatus);
      res.setHeader('X-Formatted-Address', homeAddress || [j.jurisdiction_city, j.jurisdiction_state].filter(Boolean).join(', '));
      res.status(200).json(politicians);
      return;
    }
  } catch {
    // fall through to address-based path
  }

  // --- Path 2: no encrypted coordinates — geocode home_address directly ---
  if (!homeAddress) {
    res.status(204).end();
    return;
  }

  try {
    const result = await getRepresentativesByAddress(homeAddress);
    const dataStatus = result.politicians.length === 0 ? 'no-geofence-data' : 'fresh';
    res.setHeader('X-Data-Status', dataStatus);
    res.setHeader('X-Formatted-Address', result.matchedAddress || homeAddress);
    res.status(200).json(result.politicians);
  } catch (err) {
    if (err instanceof GeocodingError) {
      // Address saved but can't geocode — return 204 so frontend falls back gracefully
      res.status(204).end();
      return;
    }
    console.error('[GET /essentials/representatives/me] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
