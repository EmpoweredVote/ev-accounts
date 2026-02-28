import { Router } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import { getCandidatesByZip } from '../lib/candidateService.js';
import type { Request, Response } from 'express';

/**
 * Essentials candidates routes — ZIP-based candidate discovery for Essentials frontend.
 *
 * Architecture rules enforced here:
 *   - Service-role client is NOT used directly — architecture.test.ts bans it from routes/
 *   - All database access goes through lib/candidateService.ts
 *   - optionalAuth — no authentication required for public candidate discovery
 *
 * CRITICAL: Only ACTIVE candidates are returned. Inactive (demoted) candidates
 * are excluded from local discovery — getCandidatesByZip enforces is_active = true.
 * A valid ZIP with no active candidates returns 200 with an empty array (NOT 404).
 */

const router = Router();

const ZIP_REGEX = /^\d{5}(-\d{4})?$/;

// ---------------------------------------------------------------------------
// GET /api/essentials/candidates/:zip
// Auth: optional — works unauthenticated
// Returns all active candidates representing the given ZIP code.
// Validates ZIP format (5-digit or ZIP+4). Normalizes to 5-digit before lookup.
// Returns 200 with empty array [] when valid ZIP has no matching candidates.
// Returns 422 for invalid ZIP format.
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

    // Normalize to 5-digit ZIP for consistent cache keys and DB lookups
    const normalizedZip = zip.slice(0, 5);

    const candidates = await getCandidatesByZip(normalizedZip);

    res.status(200).json(candidates);
  } catch (err) {
    console.error('[GET /essentials/candidates/:zip] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
