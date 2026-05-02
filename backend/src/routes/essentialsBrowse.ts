/**
 * Browse-by-location routes for essentials.
 *
 * Provides cascading location selection (State → County/City → Politicians)
 * without requiring geocoding. Uses PostGIS area intersection to find all
 * politicians whose districts overlap with a selected area.
 */

import { Router } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import {
  getStatesWithData,
  getAreasForState,
  getPoliticiansByArea,
  getPoliticiansByGovernmentList,
  getOverlappingGeoIdsForArea,
} from '../lib/essentialsBrowseService.js';
import { getElectionsByGeoIds, getElectionsByGovernmentGeoIds } from '../lib/electionService.js';
import type { Request, Response } from 'express';

const router = Router();

// ---------------------------------------------------------------------------
// GET /api/essentials/browse/states
// Returns states that have politician data.
// ---------------------------------------------------------------------------

router.get('/states', optionalAuth, async (_req: Request, res: Response): Promise<void> => {
  try {
    const states = await getStatesWithData();
    res.status(200).json(states);
  } catch (err) {
    console.error('[GET /essentials/browse/states] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/essentials/browse/states/:state/areas
// Returns browsable areas (counties, cities, townships) for a state.
// :state is the 2-letter abbreviation (e.g., "IN", "CA").
// ---------------------------------------------------------------------------

router.get('/states/:state/areas', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const state = (req.params.state as string).toUpperCase();
    if (!/^[A-Z]{2}$/.test(state)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'State must be a 2-letter abbreviation' });
      return;
    }
    const areas = await getAreasForState(state);
    res.status(200).json(areas);
  } catch (err) {
    console.error('[GET /essentials/browse/states/:state/areas] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/essentials/browse/by-area
// Find all politicians whose districts overlap with a given area.
// Body: { geo_id: string, mtfcc: string }
// Uses bidirectional PostGIS intersection (same logic as Go backend).
// ---------------------------------------------------------------------------

router.post('/by-area', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { geo_id, mtfcc } = req.body as { geo_id?: string; mtfcc?: string };

    if (!geo_id || typeof geo_id !== 'string' || !geo_id.trim()) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'geo_id is required' });
      return;
    }
    if (!mtfcc || typeof mtfcc !== 'string' || !mtfcc.trim()) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'mtfcc is required' });
      return;
    }

    const politicians = await getPoliticiansByArea(geo_id.trim(), mtfcc.trim());

    const dataStatus = politicians.length === 0 ? 'no-geofence-data' : 'fresh';
    res.setHeader('X-Data-Status', dataStatus);
    res.status(200).json(politicians);
  } catch (err) {
    console.error('[POST /essentials/browse/by-area] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/essentials/browse/elections-by-area
// Find upcoming elections + races + candidates for an area, using the same
// PostGIS area intersection that powers /by-area (no geocoding required).
// Body: { geo_id: string, mtfcc: string }
// Returns: { elections: ElectionResult[] }
// Header: X-Data-Status = 'no-geofence-data' | 'fresh'
// ---------------------------------------------------------------------------

router.post('/elections-by-area', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { geo_id, mtfcc } = req.body as { geo_id?: string; mtfcc?: string };

    if (!geo_id || typeof geo_id !== 'string' || !geo_id.trim()) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'geo_id is required' });
      return;
    }
    if (!mtfcc || typeof mtfcc !== 'string' || !mtfcc.trim()) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'mtfcc is required' });
      return;
    }

    const { geoIds, stateAbbrev } = await getOverlappingGeoIdsForArea(geo_id.trim(), mtfcc.trim());

    const dataStatus = geoIds.length === 0 ? 'no-geofence-data' : 'fresh';
    res.setHeader('X-Data-Status', dataStatus);

    const elections = await getElectionsByGeoIds(geoIds, stateAbbrev);
    res.status(200).json({ elections });
  } catch (err) {
    console.error('[POST /essentials/browse/elections-by-area] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch election data' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/essentials/browse/by-government-list
// Find all politicians for an explicit list of government geo_ids.
// Bypasses geofence/district infrastructure — for jurisdictions whose city
// boundaries haven't been loaded into geofence_boundaries.
// Body: { government_geo_ids: string[] }
// ---------------------------------------------------------------------------

router.post('/by-government-list', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { government_geo_ids } = req.body as { government_geo_ids?: unknown };

    if (!Array.isArray(government_geo_ids) || government_geo_ids.length === 0) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'government_geo_ids must be a non-empty array' });
      return;
    }
    const ids = (government_geo_ids as unknown[]).filter((id): id is string => typeof id === 'string' && id.trim().length > 0);
    if (ids.length === 0) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'government_geo_ids must contain valid strings' });
      return;
    }

    const politicians = await getPoliticiansByGovernmentList(ids);
    res.status(200).json(politicians);
  } catch (err) {
    console.error('[POST /essentials/browse/by-government-list] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/essentials/browse/elections-by-government-list
// Find upcoming elections + races + candidates for an explicit list of governments.
// Mirrors /by-government-list but returns election data instead of politicians.
// Body: { government_geo_ids: string[] }
// Returns: { elections: ElectionResult[] }
// ---------------------------------------------------------------------------

router.post('/elections-by-government-list', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { government_geo_ids } = req.body as { government_geo_ids?: unknown };

    if (!Array.isArray(government_geo_ids) || government_geo_ids.length === 0) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'government_geo_ids must be a non-empty array' });
      return;
    }
    const ids = (government_geo_ids as unknown[]).filter((id): id is string => typeof id === 'string' && id.trim().length > 0);
    if (ids.length === 0) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'government_geo_ids must contain valid strings' });
      return;
    }

    const elections = await getElectionsByGovernmentGeoIds(ids);
    res.status(200).json({ elections });
  } catch (err) {
    console.error('[POST /essentials/browse/elections-by-government-list] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch election data' });
  }
});

export default router;
