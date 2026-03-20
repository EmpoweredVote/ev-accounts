import { Router } from 'express';
import type { Request, Response } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import type { AuthenticatedRequest } from '../middleware/auth.js';
import {
  getRepresentativesByAddress,
  getGovernmentById,
  getChamberById,
  getDistrictById,
} from '../lib/essentialsService.js';
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

export default router;
