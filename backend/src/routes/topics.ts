/**
 * Topic routes — cross-meeting topic pages for the on-the-record site.
 * Public reads (optionalAuth). topic_key validated before any DB work.
 */

import { Router } from 'express';
import type { Request, Response } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import { getTopics, getTopicByKey } from '../lib/topicsService.js';

const router = Router();
const KEY_REGEX = /^[a-z0-9][a-z0-9_-]{0,99}$/;

router.get('/', optionalAuth, async (_req: Request, res: Response): Promise<void> => {
  try {
    const result = await getTopics();
    res.status(200).json(result);
  } catch (err) {
    console.error('[GET /topics] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

router.get('/:key', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const key = req.params.key as string;
  if (!KEY_REGEX.test(key)) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid topic key' });
    return;
  }
  try {
    const topic = await getTopicByKey(key);
    if (!topic) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Topic not found' });
      return;
    }
    res.status(200).json(topic);
  } catch (err) {
    console.error('[GET /topics/:key] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
