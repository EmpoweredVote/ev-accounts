/**
 * compassJournal — the public, reader-facing diary.
 *
 * Mounted on the /api/compass prefix alongside compassRouter.
 *
 * Public and unauthenticated by design, the same reasoning compassRevisions
 * gives for its history route: /api/compass/topics is already served
 * anonymously, so gating the transparency surface behind a login hides it from
 * most of the audience it exists for.
 *
 * ⚠ Focused Communities will call these same two routes when it wakes. Nothing
 * here may become Compass-specific.
 */
import { Router, type Request, type Response } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import { listTopicJournal, listSeasonJournal } from '../lib/compassJournalService.js';

const router = Router();

router.get(
  '/topics/:topicId/journal',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    try {
      // This repo types req.params values as `string | string[]`, so the id is
      // narrowed here rather than trusted. A route param can only ever be one
      // value for this path, but the service takes a string and must be handed one.
      res.status(200).json(await listTopicJournal(String(req.params.topicId)));
    } catch (err) {
      console.error('[GET /compass/topics/:topicId/journal] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  },
);

router.get('/journal', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const season = Number(req.query.season);
  if (!Number.isInteger(season)) {
    res.status(400).json({ code: 'BAD_REQUEST', message: 'season must be an integer' });
    return;
  }
  try {
    res.status(200).json(await listSeasonJournal(season));
  } catch (err) {
    console.error('[GET /compass/journal] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
