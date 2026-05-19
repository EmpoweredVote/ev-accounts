/**
 * Council Files API routes
 *
 * Purpose: Public-facing bill detail endpoints for the LA Council Bill Detail
 * drawer in the Essentials frontend. All routes are public (optionalAuth).
 *
 * Routes:
 *   GET /api/council-files/:fileNumber
 *     - Returns enriched bill detail JSON (200) if cached in DB
 *     - Returns 202 ENRICHING if not cached, triggers background enrichment
 *     - Returns 422 INVALID_FILE_NUMBER on malformed CFN
 *
 *   GET /api/council-files/:fileNumber/votes
 *     - Returns full vote roster for a council file (name + vote)
 *     - Joins meetings.la_council_votes with essentials.politicians
 *
 * HTTP contract:
 *   200 — { council_file_number, title, movers[], second, introduced_date,
 *           last_changed_date, pdf_links[], cfms_url, granicus_clip_id,
 *           ai_summary, enriched_at, ai_summary_at, video_url }
 *   202 — { code: 'ENRICHING', message: '...' }  (poll again in 2s)
 *   422 — { code: 'INVALID_FILE_NUMBER', message: '...' }
 *   500 — { code: 'INTERNAL_ERROR', message: '...' }
 */

import { Router } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import type { Request, Response } from 'express';
import {
  getCouncilFileDetail,
  getVoteRoster,
  enrichCouncilFile,
} from '../lib/councilFilesService.js';

const router = Router();

// CFN validation: NN-NNNN or NN-NNNN-XX (suffixes can be S3, A2, T1, etc.)
const CFN_REGEX = /^\d{2}-\d{4}(-[A-Z0-9]+)?$/;

// ---------------------------------------------------------------------------
// GET /:fileNumber — enriched bill detail with on-demand enrichment fallback
// ---------------------------------------------------------------------------

router.get('/:fileNumber', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const cfn = req.params.fileNumber as string;

  if (!CFN_REGEX.test(cfn)) {
    res.status(422).json({
      code: 'INVALID_FILE_NUMBER',
      message: 'Council file number must match NN-NNNN or NN-NNNN-XX',
    });
    return;
  }

  try {
    const detail = await getCouncilFileDetail(cfn);

    if (!detail) {
      // Fire-and-forget: trigger enrichment in background; do NOT await.
      // Frontend should poll again in ~2s. Keeps response time <100ms.
      enrichCouncilFile(cfn).catch((err) =>
        console.error('[enrichCouncilFile bg]', cfn, err)
      );
      res.status(202).json({
        code: 'ENRICHING',
        message: 'Bill detail is being fetched. Poll again in 2s.',
      });
      return;
    }

    res.status(200).json(detail);
  } catch (err) {
    console.error('[GET /council-files/:fileNumber] error:', err);
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    });
  }
});

// ---------------------------------------------------------------------------
// GET /:fileNumber/votes — full vote roster for a council file
// ---------------------------------------------------------------------------

router.get(
  '/:fileNumber/votes',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const cfn = req.params.fileNumber as string;

    if (!CFN_REGEX.test(cfn)) {
      res.status(422).json({
        code: 'INVALID_FILE_NUMBER',
        message: 'Invalid file number',
      });
      return;
    }

    try {
      const roster = await getVoteRoster(cfn);
      res.status(200).json({ council_file_number: cfn, votes: roster });
    } catch (err) {
      console.error('[GET /council-files/:fileNumber/votes] error:', err);
      res.status(500).json({
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred',
      });
    }
  }
);

export default router;
