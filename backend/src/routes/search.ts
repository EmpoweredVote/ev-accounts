/**
 * Search routes — full-text search across published meeting transcripts.
 *
 * Public read only (optionalAuth). Called cross-origin by the on-the-record
 * static site's browser (origin must be in the CORS_ORIGIN allowlist).
 *
 * Architecture rules (same as meetings.ts / people.ts):
 *   - All DB access via searchService (pool.query)
 *   - All params validated before any DB work
 */

import { Router } from 'express';
import type { Request, Response } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import { searchSegments } from '../lib/searchService.js';

const router = Router();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_QUERY_LENGTH = 200;
// Caps the OFFSET an unauthenticated caller can force (page * 25 rows).
const MAX_PAGE = 400;

// GET /api/search?q=affordable+housing&city=Bloomington&speaker=11111111-1111-1111-1111-111111111111&page=1
router.get('/', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const q = typeof req.query.q === 'string' ? req.query.q.trim() : '';
  if (q.length === 0 || q.length > MAX_QUERY_LENGTH) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: `q is required and must be at most ${MAX_QUERY_LENGTH} characters`,
    });
    return;
  }

  let page = 1;
  if (req.query.page !== undefined) {
    const parsed = Number(req.query.page);
    if (!Number.isInteger(parsed) || parsed < 1 || parsed > MAX_PAGE) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: `page must be a positive integer at most ${MAX_PAGE}`,
      });
      return;
    }
    page = parsed;
  }

  let speaker: string | undefined;
  if (req.query.speaker !== undefined) {
    if (typeof req.query.speaker !== 'string' || !UUID_REGEX.test(req.query.speaker)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'speaker must be a valid politician id' });
      return;
    }
    speaker = req.query.speaker;
  }

  let city: string | undefined;
  if (typeof req.query.city === 'string' && req.query.city.length > 0) {
    city = req.query.city;
  }

  try {
    const response = await searchSegments({ q, city, speaker, page });
    res.status(200).json(response);
  } catch (err) {
    console.error('[GET /search] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
