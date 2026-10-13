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
import { z } from 'zod';
import { optionalAuth } from '../middleware/auth.js';
import { listTopicJournal, listSeasonJournal } from '../lib/compassJournalService.js';

const UUID = z.string().uuid();

const router = Router();

router.get(
  '/topics/:topicId/journal',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    // 🔴 A NON-UUID USED TO REACH POSTGRES AND RAISE 22P02, which the catch
    // below turned into a 500. This route is public, anonymous and crawlable,
    // so any bot following a slug-shaped URL — /topics/childcare/journal — made
    // 500s and log noise out of an ordinary bad request.
    //
    // This repo also types req.params values as `string | string[]`, so the
    // narrowing is not optional either.
    const topicId = String(req.params.topicId);
    if (!UUID.safeParse(topicId).success) {
      res.status(400).json({ code: 'BAD_REQUEST', message: 'topic id must be a uuid' });
      return;
    }
    try {
      res.status(200).json(await listTopicJournal(topicId));
    } catch (err) {
      console.error('[GET /compass/topics/:topicId/journal] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  },
);

router.get('/journal', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  // `Number('')` is 0 and Number.isInteger(0) is true, so an empty ?season=
  // used to query for season zero instead of being refused.
  const raw = req.query.season;
  const season = typeof raw === 'string' && raw.trim() !== '' ? Number(raw) : NaN;
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
