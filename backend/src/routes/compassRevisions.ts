/**
 * compassRevisions — the review surface (ADR 0004 §7).
 *
 * Mounted at /api/compass/revisions.
 *
 * AUTHORISATION
 * Review routes: requireAuth + requireRole('compass_stance_editor'), matching
 * routes/compassContributor.ts.
 *
 * 🔴 EXACTLY ONE person holds that role today. public.user_roles has FOUR grant
 * rows for `Compass Stance Editor` but they all belong to a single user, so a
 * count of rows reads as four reviewers and is wrong. Until the role is granted
 * to the other reviewers, every route in this file is usable by one account.
 *
 * The history route is deliberately PUBLIC and unauthenticated. It is the reader-
 * facing record (ADR 0004 §9), and /api/compass/topics is already served
 * anonymously, so gating history behind a login would hide the transparency
 * surface from most of the audience it exists for. It returns only
 * published/superseded revisions — never drafts or rejects, which would
 * misrepresent refused wording as something we considered saying.
 *
 * WHY THERE IS NO POST /revisions HERE
 * Authoring is not a route. Migration 061 shipped a create-a-rewrite web form and
 * it was used zero times in four months, because the people who author compass
 * content work in SQL and generator scripts. Drafts are written by that tooling
 * calling inform.admin_propose_topic_revision. This file serves reviewers.
 * Adding an authoring form here would rebuild the thing that already failed.
 *
 * ERROR MAPPING
 * The RPCs raise named errors (NOT_APPROVED, RUNG_MAP_REQUIRED,
 * REPOINTING_NOT_IMPLEMENTED, ...). Those names are contract, so they are mapped
 * to 409/422 with the message passed through — a reviewer who clicks Publish on a
 * rung-moving change needs to read WHY, not "500 internal error".
 */

import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireRole } from '../middleware/requireRole.js';
import { logAdminAction } from '../lib/adminService.js';
import {
  listOpenRevisions,
  getRevisionForReview,
  getTopicRevisionHistory,
  approveRevision,
  rejectRevision,
  publishRevision,
} from '../lib/compassRevisionService.js';

const router = Router();

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const TOPIC_KEY_RE = /^[a-z0-9-/]{1,80}$/;

const REVIEWER = 'compass_stance_editor';

const rejectSchema = z.object({
  reason: z.string().trim().min(1, 'A reason is required').max(2000),
});

/**
 * RPC error names that are the caller's fault, not the server's. Anything not
 * listed is a genuine 500 — a silent catch-all here would turn a real bug into a
 * confusing 422 for a reviewer.
 */
const CLIENT_ERRORS: Record<string, number> = {
  NO_SUCH_TOPIC: 404,
  NOT_FOUND: 404,
  NOT_DRAFT: 409,
  NOT_OPEN: 409,
  NOT_APPROVED: 409,
  STALE_VERSION: 409,
  NO_CURRENT_REVISION: 409,
  REASON_REQUIRED: 422,
  BAD_CHANGE_CLASS: 422,
  BAD_LADDER: 422,
  RUNG_MAP_REQUIRED: 422,
  RUNG_MAP_NOT_NEEDED: 422,
  REPOINTING_NOT_IMPLEMENTED: 422,
};

function sendRpcError(res: Response, err: unknown, where: string): void {
  const message = err instanceof Error ? err.message : String(err);
  const code = message.split(':')[0]?.trim() ?? '';
  const status = CLIENT_ERRORS[code];

  if (status) {
    // Pass the RPC's own message through. It is written for a human reviewer —
    // REPOINTING_NOT_IMPLEMENTED explains what is missing and what to do instead.
    res.status(status).json({ code, message: message.replace(/^[A-Z_]+:\s*/, '') });
    return;
  }

  console.error(`[${where}] unexpected error:`, err);
  res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
}

// ---------------------------------------------------------------------------
// GET /api/compass/revisions/queue — open proposals awaiting review
// ---------------------------------------------------------------------------

router.get(
  '/queue',
  requireAuth,
  requireRole(REVIEWER),
  async (_req: Request, res: Response): Promise<void> => {
    try {
      res.json({ revisions: await listOpenRevisions() });
    } catch (err) {
      console.error('[GET /compass/revisions/queue] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/compass/revisions/:id — one proposal, paired against what is live
// ---------------------------------------------------------------------------

router.get(
  '/:id',
  requireAuth,
  requireRole(REVIEWER),
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_RE.test(id)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid revision id' });
      return;
    }
    try {
      const revision = await getRevisionForReview(id);
      if (!revision) {
        res.status(404).json({ code: 'NOT_FOUND', message: 'Revision not found' });
        return;
      }
      res.json(revision);
    } catch (err) {
      console.error('[GET /compass/revisions/:id] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// POST /api/compass/revisions/:id/approve
// ---------------------------------------------------------------------------
// Approval does NOT publish. A ladder change can be approved now and cut over at
// a chosen moment (ADR 0004 §7) — one click must not do both.

router.post(
  '/:id/approve',
  requireAuth,
  requireRole(REVIEWER),
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_RE.test(id)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid revision id' });
      return;
    }
    const actorId = (req as AuthenticatedRequest).userId;
    try {
      await approveRevision(id, actorId);
      await logAdminAction(actorId, 'compass:revision:approve', null, { revision_id: id });
      res.status(200).json({ ok: true });
    } catch (err) {
      sendRpcError(res, err, 'POST /compass/revisions/:id/approve');
    }
  }
);

// ---------------------------------------------------------------------------
// POST /api/compass/revisions/:id/reject
// ---------------------------------------------------------------------------

router.post(
  '/:id/reject',
  requireAuth,
  requireRole(REVIEWER),
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_RE.test(id)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid revision id' });
      return;
    }
    const parsed = rejectSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: parsed.error.issues[0]?.message ?? 'A reason is required',
      });
      return;
    }
    const actorId = (req as AuthenticatedRequest).userId;
    try {
      await rejectRevision(id, actorId, parsed.data.reason);
      await logAdminAction(actorId, 'compass:revision:reject', null, {
        revision_id: id,
        reason: parsed.data.reason,
      });
      res.status(200).json({ ok: true });
    } catch (err) {
      sendRpcError(res, err, 'POST /compass/revisions/:id/reject');
    }
  }
);

// ---------------------------------------------------------------------------
// POST /api/compass/revisions/:id/publish
// ---------------------------------------------------------------------------
// Flips is_current and supersedes the outgoing revision, atomically in the RPC.
// Touches no politician answers — that is the whole point of the identity split.

router.post(
  '/:id/publish',
  requireAuth,
  requireRole(REVIEWER),
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_RE.test(id)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid revision id' });
      return;
    }
    const actorId = (req as AuthenticatedRequest).userId;
    try {
      const result = await publishRevision(id, actorId);
      await logAdminAction(actorId, 'compass:revision:publish', null, {
        revision_id: id,
        ...result,
      });
      res.status(200).json(result);
    } catch (err) {
      sendRpcError(res, err, 'POST /compass/revisions/:id/publish');
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/compass/revisions/history/:topicKey — PUBLIC reader-facing record
// ---------------------------------------------------------------------------
// No auth by design: see the header. Published and superseded only.

router.get('/history/:topicKey', async (req: Request, res: Response): Promise<void> => {
  const topicKey = req.params.topicKey as string;
  if (!TOPIC_KEY_RE.test(topicKey)) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid topic key' });
    return;
  }
  try {
    const revisions = await getTopicRevisionHistory(topicKey);
    res.json({ topicKey, revisions });
  } catch (err) {
    console.error('[GET /compass/revisions/history/:topicKey] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
