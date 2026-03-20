import { Router } from 'express';
import type { Request, Response } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import type { AuthenticatedRequest } from '../middleware/auth.js';
import { getRepresentativesByAddress } from '../lib/essentialsService.js';
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

export default router;
