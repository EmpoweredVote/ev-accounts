import { Router } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import { getRepresentativesByAddress, getPoliticiansFlatList, getOfficialsByZip } from '../lib/essentialsService.js';
import type { Request, Response } from 'express';

/**
 * Essentials candidates routes — location-based officeholder discovery.
 *
 * Architecture rules enforced here:
 *   - Service-role client is NOT used directly — architecture.test.ts bans it from routes/
 *   - All database access goes through src/lib/
 *   - optionalAuth — no authentication required for public discovery
 *
 * TWO KINDS OF LOCATION, and the difference is the point of the ZIP route:
 *   POST /search  — a full street address geocodes to a POINT, which falls on
 *                   exactly one side of every district line. Precise.
 *   GET  /:zip    — a ZIP is an AREA, which straddles district lines. It
 *                   legitimately returns several holders of the SAME office,
 *                   each with the share of the ZIP their district covers.
 *
 * Both resolve through essentialsService, which admits active holders and vacant
 * seats and excludes challenger placeholder offices.
 */

const router = Router();

const ZIP_REGEX = /^\d{5}(-\d{4})?$/;

// ---------------------------------------------------------------------------
// GET /api/essentials/candidates/search-by-name?q=...
// Auth: optional — public endpoint, public data
// Returns up to 20 politicians matching q on full_name/first_name/last_name (ILIKE).
// Requires q >= 2 characters; returns 422 for shorter queries.
// IMPORTANT: Must be registered BEFORE GET /:zip or the ZIP wildcard swallows it.
// ---------------------------------------------------------------------------

router.get('/search-by-name', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const qRaw = (req.query.q ?? '') as string;
    const q = typeof qRaw === 'string' ? qRaw.trim() : '';

    if (q.length < 2) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: 'q must be at least 2 characters',
      });
      return;
    }

    // Cap at 20 results — this is a typeahead, not pagination.
    // Pass true for includeCandidates so challengers appear alongside incumbents.
    const results = await getPoliticiansFlatList(true, { q, limit: 20 });
    res.setHeader('Cache-Control', 'public, max-age=30');
    res.status(200).json(results);
  } catch (err) {
    console.error('[GET /essentials/candidates/search-by-name] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/candidates/:zip
// Auth: optional — works unauthenticated
//
// Every official who serves ANY PART of the ZIP. A ZIP is an area, not a point,
// so this legitimately returns several holders of the same office — where a ZIP
// spans two state house districts, both members are returned, because the ZIP
// cannot say which side of the line the visitor lives on.
//
// Each politician carries `share`: the fraction of the ZIP their district
// covers. Statewide offices carry share: null (a state contains the whole ZIP).
//
// NOTHING IS FILTERED BY SHARE. Collapsing slivers is presentation, applied by
// the client: a server-side cutoff would drop a real answer (measured — a >=10%
// cutoff removes Bloomington from 47401) and a resident of that slice still has
// a real council member.
//
// 422 — malformed ZIP (not 5-digit or ZIP+4)
// 404 — well-formed but no such ZCTA polygon, i.e. not a real ZIP
// 200 — resolved; `politicians` may be empty for a real ZIP we cover no offices in
// ---------------------------------------------------------------------------

router.get('/:zip', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const zip = req.params.zip as string;

    // Validate ZIP format — 5-digit or ZIP+4
    if (!ZIP_REGEX.test(zip)) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: 'Invalid ZIP code format',
      });
      return;
    }

    // Normalize to 5-digit — ZCTAs are 5-digit, and this keeps cache keys
    // single-valued so '46220' and '46220-1234' cannot occupy two entries.
    const normalizedZip = zip.slice(0, 5);

    const result = await getOfficialsByZip(normalizedZip);

    if (result === null) {
      res.status(404).json({ code: 'ZIP_NOT_FOUND', message: 'No such ZIP code' });
      return;
    }

    res.setHeader('X-Data-Status', result.politicians.length === 0 ? 'no-geofence-data' : 'fresh');
    res.setHeader('Cache-Control', 'public, max-age=300');
    res.status(200).json({
      zip: result.zip,
      states: result.states,
      county: result.county,
      politicians: result.politicians,
      ambiguity: result.ambiguity,
    });
  } catch (err) {
    console.error('[GET /essentials/candidates/:zip] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/essentials/candidates/search
// Auth: optional — works unauthenticated
// Body: { query: string } — a full address string (not a ZIP code)
// Geocodes the address via Census Geocoder, returns representatives for that location.
// ZIP codes should use GET /:zip instead; this endpoint handles full address strings.
// ---------------------------------------------------------------------------

router.post('/search', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { query, includeChallengers } = req.body as { query?: string; includeChallengers?: boolean };

    if (!query || typeof query !== 'string' || !query.trim()) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'query is required' });
      return;
    }

    const result = await getRepresentativesByAddress(query.trim(), { includeChallengers: !!includeChallengers });
    const dataStatus = result.politicians.length === 0 ? 'no-geofence-data' : 'fresh';
    res.setHeader('X-Data-Status', dataStatus);
    res.setHeader('X-Formatted-Address', result.matchedAddress);
    // SCHEMA-03 (Phase 132 D-06): wrap response so tribal_land block reaches the frontend.
    // Backward-compatible — clients that previously read the bare politicians array can now
    // read response.politicians instead. tribal_land is always present (on_reservation:false
    // for non-tribal addresses) so consumers do not need to null-check.
    res.status(200).json({
      politicians: result.politicians,
      tribal_land: result.tribal_land ?? { on_reservation: false },
      locality: result.locality ?? { incorporated: null, place_name: null, county_name: null },
      county: result.county ?? null,
      jurisdiction: result.jurisdictionGeoIds,
    });
  } catch (err: unknown) {
    const code = (err as { code?: string }).code;
    if (code === 'ADDRESS_NOT_FOUND' || code === 'PO_BOX_REJECTED') {
      res.status(422).json({ code, message: (err as Error).message });
      return;
    }
    if (code === 'GEOCODER_UNAVAILABLE') {
      res.status(503).json({ code, message: (err as Error).message });
      return;
    }
    console.error('[POST /essentials/candidates/search] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
