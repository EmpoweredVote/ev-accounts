import { Router } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import { getCandidateBySlug, getCandidateAnswers } from '../lib/candidateService.js';
import type { Request, Response } from 'express';

/**
 * Candidate routes — public profile and answer lookups.
 *
 * Architecture rules enforced here:
 *   - Service-role client is NOT used directly — architecture.test.ts bans it from routes/
 *   - All database access goes through lib/candidateService.ts
 *   - Both endpoints use optionalAuth — no authentication required for public candidate pages
 *
 * Route ordering: /:slug/answers BEFORE /:slug to prevent Express interpreting "answers"
 * as a slug value (both orderings work due to literal second segment, but explicit is cleaner).
 */

const router = Router();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ---------------------------------------------------------------------------
// GET /api/candidates/:slug/answers
// Auth: optional — works unauthenticated
// Returns a candidate's public compass answers for specified topics.
// Required query param: topics — comma-separated topic UUIDs
// Optional query param: inverted — comma-separated topic UUIDs to invert
// Returns 404 if slug does not exist; 422 if topics param is missing/invalid.
// ---------------------------------------------------------------------------

router.get('/:slug/answers', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const slug = req.params.slug as string;

    // Parse and validate topics query param
    const topicsParam = typeof req.query.topics === 'string' ? req.query.topics : '';
    const topicIds = topicsParam.split(',').map((s) => s.trim()).filter(Boolean);

    if (topicIds.length === 0) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: 'topics query parameter is required',
      });
      return;
    }

    // Validate each topicId is UUID format
    const invalidTopics = topicIds.filter((id) => !UUID_REGEX.test(id));
    if (invalidTopics.length > 0) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: `Invalid topic ID format: ${invalidTopics.join(', ')}`,
      });
      return;
    }

    // Parse inverted query param
    const invertedParam = typeof req.query.inverted === 'string' ? req.query.inverted : '';
    const invertedSet = new Set(
      invertedParam.split(',').map((s) => s.trim()).filter(Boolean)
    );

    const answers = await getCandidateAnswers(slug, topicIds, invertedSet);

    if (answers === null) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Candidate not found' });
      return;
    }

    res.status(200).json(answers);
  } catch (err) {
    console.error('[GET /candidates/:slug/answers] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/candidates/:slug
// Auth: optional — works unauthenticated
// Returns the full public candidate profile, including inactive (demoted) candidates.
// Inactive candidates return active: false with demoted_at timestamp.
// Returns 404 if the slug does not exist or belongs to a soft-deleted account.
// ---------------------------------------------------------------------------

router.get('/:slug', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const slug = req.params.slug as string;

    const candidate = await getCandidateBySlug(slug);

    if (candidate === null) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Candidate not found' });
      return;
    }

    res.status(200).json(candidate);
  } catch (err) {
    console.error('[GET /candidates/:slug] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
