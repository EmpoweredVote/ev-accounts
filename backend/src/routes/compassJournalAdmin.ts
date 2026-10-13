/**
 * compassJournalAdmin — authoring the diary.
 *
 * Mounted at /api/admin/compass. requireAuth + requireAdmin, the gate every
 * /api/admin/compass/* route already uses.
 *
 * 🔴 author_id COMES FROM THE SESSION AND IS NEVER ACCEPTED FROM THE BODY. The
 * byline is derived from it, so a body-supplied author would let one admin sign
 * an entry in another's name.
 */
import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import {
  createEntry, updateEntry, publishEntry, deleteDraft, resolveDefaultSeasonId,
  assertSeasonWritable,
} from '../lib/compassJournalService.js';

const router = Router();
router.use(requireAuth as never, requireAdmin as never);

/**
 * ⚠ A NON-UUID ID USED TO REACH POSTGRES AND RAISE 22P02, which the catch below
 * turned into a 500. On the public read routes that is a crawlable 500 for any
 * bot following a slug-shaped URL; here it is the wrong status for a typo.
 * Returns the id, or null having already answered 400.
 */
const uuidParam = (res: Response, raw: unknown, what: string): string | null => {
  const v = String(raw);
  if (!z.string().uuid().safeParse(v).success) {
    res.status(400).json({ code: 'BAD_REQUEST', message: what + ' must be a uuid' });
    return null;
  }
  return v;
};

const CreateBody = z.object({
  kind: z.enum(['watching', 'changed']),
  title: z.string().trim().min(1).max(200).nullish(),
  body: z.string().trim().min(1),
  revisionId: z.string().uuid().nullish(),
  answersId: z.string().uuid().nullish(),
  attribution: z.enum(['none', 'handle', 'real']).default('handle'),
  seasonId: z.string().uuid().nullish(),
});

router.post('/topics/:topicId/journal', async (req: Request, res: Response): Promise<void> => {
  const parsed = CreateBody.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ code: 'BAD_REQUEST', message: parsed.error.issues[0].message });
    return;
  }
  const b = parsed.data;

  const topicId = uuidParam(res, req.params.topicId, 'topic id');
  if (!topicId) return;

  // Mirrors the watching_has_no_revision CHECK, so the caller gets 422 and a
  // sentence rather than a Postgres constraint name.
  if (b.kind === 'watching' && b.revisionId) {
    res.status(422).json({
      code: 'WATCHING_HAS_NO_REVISION',
      message: 'A watching entry describes a change that has not happened yet.',
    });
    return;
  }

  try {
    let seasonId: string;
    if (b.seasonId) {
      // Explicit beats implicit, but not the rule: see assertSeasonWritable.
      await assertSeasonWritable(b.seasonId);
      seasonId = b.seasonId;
    } else {
      seasonId = await resolveDefaultSeasonId();
    }
    const out = await createEntry({
      topicId,
      seasonId,
      kind: b.kind,
      title: b.title ?? null,
      body: b.body,
      revisionId: b.revisionId ?? null,
      answersId: b.answersId ?? null,
      attribution: b.attribution,
    }, (req as AuthenticatedRequest).userId);
    res.status(201).json(out);
  } catch (err) {
    const msg = err instanceof Error ? err.message : '';
    if (/^(NO_SEASON|SEASON_CLOSED|ANSWERS_WRONG_TOPIC|ANSWERS_IS_A_CHAIN|REVISION_WRONG_TOPIC)/.test(msg)) {
      res.status(409).json({ code: msg.split(':')[0], message: msg });
      return;
    }
    console.error('[POST /admin/compass/topics/:topicId/journal] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

const PatchBody = z.object({
  title: z.string().trim().min(1).max(200).nullish(),
  body: z.string().trim().min(1).optional(),
  attribution: z.enum(['none', 'handle', 'real']).optional(),
});

router.patch('/journal/:id', async (req: Request, res: Response): Promise<void> => {
  const parsed = PatchBody.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ code: 'BAD_REQUEST', message: parsed.error.issues[0].message });
    return;
  }
  const id = uuidParam(res, req.params.id, 'entry id');
  if (!id) return;
  try {
    const ok = await updateEntry(id, parsed.data);
    res.status(ok ? 200 : 404).json(ok ? { ok: true } : { code: 'NOT_FOUND', message: 'No such entry' });
  } catch (err) {
    console.error('[PATCH /admin/compass/journal/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

router.post('/journal/:id/publish', async (req: Request, res: Response): Promise<void> => {
  const id = uuidParam(res, req.params.id, 'entry id');
  if (!id) return;
  try {
    const ok = await publishEntry(id);
    res.status(ok ? 200 : 404).json(ok ? { ok: true } : { code: 'NOT_FOUND', message: 'No such entry' });
  } catch (err) {
    console.error('[POST /admin/compass/journal/:id/publish] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

router.delete('/journal/:id', async (req: Request, res: Response): Promise<void> => {
  const id = uuidParam(res, req.params.id, 'entry id');
  if (!id) return;
  try {
    const ok = await deleteDraft(id);
    res.status(ok ? 200 : 409).json(ok ? { ok: true } : {
      code: 'NOT_A_DRAFT',
      message: 'Only a draft can be deleted. A published entry is corrected in place.',
    });
  } catch (err) {
    console.error('[DELETE /admin/compass/journal/:id] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
