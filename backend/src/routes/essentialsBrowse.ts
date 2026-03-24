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
} from '../lib/essentialsBrowseService.js';
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

export default router;
