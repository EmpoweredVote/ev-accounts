/**
 * Essentials coordinate-lookup route — anonymous, stateless lat/lng ->
 * officials endpoint (Phase 213-02, RSLV-03).
 *
 * POST /api/essentials/coordinate-lookup
 *
 * Architecture rules enforced here:
 *   - Body-only transport (D-01): coordinates are read only from the JSON
 *     request body, NEVER from any URL query-string parameter — this keeps
 *     them out of Render/proxy access logs, which record the request line
 *     (method + path + query string) but not the POST body.
 *   - optionalAuth — public, unauthenticated endpoint; zero DB writes.
 *   - PRIVACY (Criterion 3 / D-06 / D-08): the submitted coordinate is never
 *     logged, never echoed in a response, and never carried in any
 *     analytics/telemetry event. The only thing ever passed to console.error
 *     is (err as Error).message.
 *   - Validation is delegated entirely to lib/coordinateValidation.ts's
 *     classifyCoordinate (Phase 213-01) — the exact OUTSIDE_US_BOUNDS /
 *     SWAPPED_COORDINATES / INVALID_COORDINATES taxonomy (D-07) is passed
 *     through verbatim as the 422 `code`.
 *   - On a valid US point, lib/essentialsService.ts's
 *     getRepresentativesByCoordinate (Phase 213-01) resolves officials via
 *     the same ST_Covers query getRepresentativesByAddress uses, with no
 *     Census geocode round-trip.
 *   - express-rate-limit (T-213-06): cheap abuse protection on this
 *     anonymous POST route, mirroring routes/events.ts's trackLimiter.
 */

import { Router } from 'express';
import type { Request, Response } from 'express';
import rateLimit, { ipKeyGenerator } from 'express-rate-limit';
import { createSharedRateLimitStore } from '../lib/rateLimitStore.js';
import { optionalAuth } from '../middleware/auth.js';
import { classifyCoordinate } from '../lib/coordinateValidation.js';
import { getRepresentativesByCoordinate } from '../lib/essentialsService.js';

const router = Router();

// T-213-06: modest abuse protection on an anonymous POST — mirrors
// events.ts's trackLimiter shape (windowMs/max/keyGenerator on req.ip).
const coordinateRateLimitStore = createSharedRateLimitStore('coord');
const coordinateLookupLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  keyGenerator: (req) => (req.ip ? ipKeyGenerator(req.ip) : 'unknown'),
  ...(coordinateRateLimitStore ? { store: coordinateRateLimitStore } : {}),
  standardHeaders: true,
  legacyHeaders: false,
});

// ---------------------------------------------------------------------------
// 422 message copy per rejection code (D-07). Messages never echo the
// submitted lat/lng values back to the caller.
// ---------------------------------------------------------------------------
const REJECTION_MESSAGES: Record<string, string> = {
  OUTSIDE_US_BOUNDS: 'The submitted coordinate falls outside the supported US bounding box.',
  SWAPPED_COORDINATES: 'The submitted coordinate appears to have latitude and longitude swapped.',
  INVALID_COORDINATES: 'lat and lng must both be finite numbers.',
};

// ---------------------------------------------------------------------------
// POST /api/essentials/coordinate-lookup
// Auth: optional — public, unauthenticated, zero DB writes.
// Body: { lat: number, lng: number } (JSON — NOT query string, D-01).
// ---------------------------------------------------------------------------
router.post('/', optionalAuth, coordinateLookupLimiter, async (req: Request, res: Response): Promise<void> => {
  try {
    const lat = Number(req.body?.lat);
    const lng = Number(req.body?.lng);

    const classification = classifyCoordinate(lat, lng);

    if (!classification.ok) {
      res.status(422).json({
        code: classification.code,
        message: REJECTION_MESSAGES[classification.code],
      });
      return;
    }

    const result = await getRepresentativesByCoordinate(lat, lng);
    res.status(200).json(result);
  } catch (err) {
    // PRIVACY: never log req.body, lat, or lng — only the error message.
    console.error('[POST /essentials/coordinate-lookup] error:', (err as Error).message);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
