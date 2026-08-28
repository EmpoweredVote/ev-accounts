import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import {
  requireCompassReviewer,
  reviewerCapacity,
} from '../middleware/requireCompassReviewer.js';
import { logAdminAction } from '../lib/adminService.js';
import {
  listSeasons,
  getComposition,
  createDraftSeason,
  updateDraftSeason,
  deleteDraftSeason,
  addTopicToSeason,
  removeTopicFromSeason,
  repinTopic,
  openSeason,
} from '../lib/seasonCompositionService.js';

/**
 * Season composition (ADR 0005: "how a season is authored", national set only).
 * Reviewer-gated like compassRevisions — composing a season is the same
 * editorial act as publishing a revision, and records the same capacity.
 */
const router = Router();
router.use(requireAuth, requireCompassReviewer);

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const createSchema = z.object({
  name: z.string().trim().min(1).max(120),
  public_note: z.string().trim().min(1).max(4000),
  carry_from_open: z.boolean().default(true),
});
const updateSchema = z.object({
  name: z.string().trim().min(1).max(120).optional(),
  public_note: z.string().trim().min(1).max(4000).optional(),
}).refine((b) => b.name !== undefined || b.public_note !== undefined, {
  message: 'nothing to update',
});
const addTopicSchema = z.object({
  topic_id: z.string().regex(UUID_RE, 'Invalid topic id'),
});

/**
 * RPC error names that are the caller's fault, not the server's. Anything not
 * listed is a genuine 500 — a silent catch-all here would turn a real bug into
 * a confusing 4xx for a reviewer.
 */
const CLIENT_ERRORS: Record<string, number> = {
  NO_SUCH_SEASON: 404,
  NO_SUCH_TOPIC: 404,
  NOT_IN_SEASON: 404,
  NOT_DRAFT: 409,
  DRAFT_EXISTS: 409,
  ALREADY_IN_SEASON: 409,
  NO_OPEN_SEASON: 409,
  NO_CURRENT_REVISION: 409,
  EMPTY_SEASON: 409,
  SCAFFOLD_INDEXES_PRESENT: 409,
  PIN_IMMUTABLE: 409,
  NAME_REQUIRED: 422,
  NOTE_REQUIRED: 422,
};

function sendRpcError(res: Response, err: unknown, where: string): void {
  const message = err instanceof Error ? err.message : String(err);
  const code = message.split(':')[0]?.trim() ?? '';
  const status = CLIENT_ERRORS[code];
  if (status) {
    // Pass the RPC's own message through. It is written for a human —
    // SCAFFOLD_INDEXES_PRESENT names the rollout step that unblocks it.
    res.status(status).json({ code, message: message.replace(/^[A-Z_]+:\s*/, '') });
    return;
  }
  console.error(`[${where}] unexpected error:`, err);
  res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
}

function invalidId(res: Response, what: string): void {
  res.status(422).json({ code: 'VALIDATION_ERROR', message: `Invalid ${what}` });
}

router.get('/', async (_req: Request, res: Response): Promise<void> => {
  try {
    res.json({ seasons: await listSeasons() });
  } catch (err) {
    sendRpcError(res, err, 'GET /admin/seasons');
  }
});

router.get('/composition', async (_req: Request, res: Response): Promise<void> => {
  try {
    res.json(await getComposition());
  } catch (err) {
    sendRpcError(res, err, 'GET /admin/seasons/composition');
  }
});

router.post('/draft', async (req: Request, res: Response): Promise<void> => {
  const parsed = createSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: parsed.error.issues[0]?.message ?? 'Invalid body',
    });
    return;
  }
  const actorId = (req as AuthenticatedRequest).userId;
  try {
    const out = await createDraftSeason(
      actorId, parsed.data.name, parsed.data.public_note, parsed.data.carry_from_open);
    await logAdminAction(actorId, 'compass:season:create-draft', null, {
      season_id: out.season_id,
      number: out.number,
      question_count: out.question_count,
      carry_from_open: parsed.data.carry_from_open,
      capacity: reviewerCapacity(req),
    });
    res.status(201).json(out);
  } catch (err) {
    sendRpcError(res, err, 'POST /admin/seasons/draft');
  }
});

router.patch('/draft/:id', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_RE.test(id)) return invalidId(res, 'season id');
  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: parsed.error.issues[0]?.message ?? 'Invalid body',
    });
    return;
  }
  const actorId = (req as AuthenticatedRequest).userId;
  try {
    const out = await updateDraftSeason(
      id, actorId, parsed.data.name ?? null, parsed.data.public_note ?? null);
    await logAdminAction(actorId, 'compass:season:update-draft', null, {
      season_id: id,
      capacity: reviewerCapacity(req),
    });
    res.json(out);
  } catch (err) {
    sendRpcError(res, err, 'PATCH /admin/seasons/draft/:id');
  }
});

router.delete('/draft/:id', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_RE.test(id)) return invalidId(res, 'season id');
  const actorId = (req as AuthenticatedRequest).userId;
  try {
    const out = await deleteDraftSeason(id, actorId);
    await logAdminAction(actorId, 'compass:season:delete-draft', null, {
      season_id: id,
      question_count: out.question_count,
      capacity: reviewerCapacity(req),
    });
    res.json(out);
  } catch (err) {
    sendRpcError(res, err, 'DELETE /admin/seasons/draft/:id');
  }
});

router.post('/draft/:id/topics', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_RE.test(id)) return invalidId(res, 'season id');
  const parsed = addTopicSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: parsed.error.issues[0]?.message ?? 'Invalid body',
    });
    return;
  }
  const actorId = (req as AuthenticatedRequest).userId;
  try {
    const out = await addTopicToSeason(id, parsed.data.topic_id, actorId);
    await logAdminAction(actorId, 'compass:season:add-topic', null, {
      season_id: id,
      topic_id: parsed.data.topic_id,
      pinned_revision_id: out.topic_revision_id,
      capacity: reviewerCapacity(req),
    });
    res.status(201).json(out);
  } catch (err) {
    sendRpcError(res, err, 'POST /admin/seasons/draft/:id/topics');
  }
});

router.delete('/draft/:id/topics/:topicId', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  const topicId = req.params.topicId as string;
  if (!UUID_RE.test(id)) return invalidId(res, 'season id');
  if (!UUID_RE.test(topicId)) return invalidId(res, 'topic id');
  const actorId = (req as AuthenticatedRequest).userId;
  try {
    const out = await removeTopicFromSeason(id, topicId, actorId);
    await logAdminAction(actorId, 'compass:season:remove-topic', null, {
      season_id: id,
      topic_id: topicId,
      capacity: reviewerCapacity(req),
    });
    res.json(out);
  } catch (err) {
    sendRpcError(res, err, 'DELETE /admin/seasons/draft/:id/topics/:topicId');
  }
});

router.post('/draft/:id/topics/:topicId/repin', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  const topicId = req.params.topicId as string;
  if (!UUID_RE.test(id)) return invalidId(res, 'season id');
  if (!UUID_RE.test(topicId)) return invalidId(res, 'topic id');
  const actorId = (req as AuthenticatedRequest).userId;
  try {
    const out = await repinTopic(id, topicId, actorId);
    await logAdminAction(actorId, 'compass:season:repin-topic', null, {
      season_id: id,
      topic_id: topicId,
      repinned: out.repinned,
      from_revision_id: out.from_revision_id,
      to_revision_id: out.to_revision_id,
      capacity: reviewerCapacity(req),
    });
    res.json(out);
  } catch (err) {
    sendRpcError(res, err, 'POST /admin/seasons/draft/:id/topics/:topicId/repin');
  }
});

router.post('/draft/:id/open', async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  if (!UUID_RE.test(id)) return invalidId(res, 'season id');
  const actorId = (req as AuthenticatedRequest).userId;
  try {
    const out = await openSeason(id, actorId);
    await logAdminAction(actorId, 'compass:season:open', null, {
      opened_season_id: out.opened_season_id,
      closed_season_id: out.closed_season_id,
      question_count: out.question_count,
      capacity: reviewerCapacity(req),
    });
    res.json(out);
  } catch (err) {
    sendRpcError(res, err, 'POST /admin/seasons/draft/:id/open');
  }
});

export default router;
