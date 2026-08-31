/**
 * compassRevisions — the review surface (ADR 0004 §7).
 *
 * Mounted at /api/compass/revisions.
 *
 * AUTHORISATION
 * Review routes: requireAuth + requireCompassReviewer, which admits EITHER a
 * holder of `compass_stance_editor` OR a member of `public.admin_users`, and
 * records which in `reviewerCapacity`. Every mutation logs that capacity, so an
 * admin's approval is never mistaken for an editor's.
 *
 * 🔴 NOBODY holds the editor role today. `Compass Stance Editor` has four grant
 * rows and all four are revoked, so it has ZERO live holders. Admitting admins is
 * not a convenience here — without it this router is unreachable by every account
 * on the platform. `admin_users` holds two people, and they are the reviewers.
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
import {
  requireCompassReviewer,
  reviewerCapacity,
} from '../middleware/requireCompassReviewer.js';
import { logAdminAction } from '../lib/adminService.js';
import {
  listOpenRevisions,
  getRevisionForReview,
  getTopicRevisionHistory,
  getCurrentTopicContent,
  proposeRevision,
  approveRevision,
  rejectRevision,
  publishRevision,
} from '../lib/compassRevisionService.js';

const router = Router();

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const TOPIC_KEY_RE = /^[a-z0-9-/]{1,80}$/;

const rejectSchema = z.object({
  reason: z.string().trim().min(1, 'A reason is required').max(2000),
});

const proposeSchema = z.object({
  topic_key: z.string().regex(TOPIC_KEY_RE, 'Invalid topic key'),
  change_class: z.enum(['editorial', 'clarifying', 'substantive']),
  title: z.string().trim().min(1).max(200),
  short_title: z.string().trim().min(1).max(80).nullable(),
  question_text: z.string().trim().min(1).max(500),
  stances: z.array(z.object({
    value: z.number().int().min(1).max(5),
    text: z.string().trim().min(1).max(1000),
  })).length(5),
  rationale: z.string().trim().min(1).max(4000),
  public_note: z.string().trim().min(1).max(4000),
  review_ref: z.string().trim().min(1).max(500).nullable(),
  // Identity map when the ladder changed, null when it did not. The RPC and
  // is_valid_rung_map own the deeper validation; publish refuses moved rungs.
  rung_map: z.record(z.string(), z.union([z.number().int(), z.literal('invalidated')])).nullable(),
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
// GET /api/compass/revisions/current/:topicKey — the live wording, for the
// revision editor's "what it says now" column.
// ---------------------------------------------------------------------------

router.get(
  '/current/:topicKey',
  requireAuth,
  requireCompassReviewer,
  async (req: Request, res: Response): Promise<void> => {
    const topicKey = req.params.topicKey as string;
    if (!TOPIC_KEY_RE.test(topicKey)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid topic key' });
      return;
    }
    try {
      res.json(await getCurrentTopicContent(topicKey));
    } catch (err) {
      sendRpcError(res, err, 'GET /compass/revisions/current/:topicKey');
    }
  }
);

// ---------------------------------------------------------------------------
// POST /api/compass/revisions — file a proposal from the revision editor.
//
// This reverses the "authoring is not a route" decision recorded above, and
// the reversal is deliberate: that decision predates seasons. The 061-era form
// fed nothing, so nobody used it. This one feeds the review queue, and its
// output is what the season composer re-pins — the editor is the missing first
// step of a pipeline people now use daily. See docs/adr/0004 (§9) for the
// review workflow it submits into.
// ---------------------------------------------------------------------------

router.post(
  '/',
  requireAuth,
  requireCompassReviewer,
  async (req: Request, res: Response): Promise<void> => {
    const parsed = proposeSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: parsed.error.issues[0]?.message ?? 'Invalid body',
      });
      return;
    }
    const actorId = (req as AuthenticatedRequest).userId;
    const b = parsed.data;
    try {
      const out = await proposeRevision(
        {
          topicKey: b.topic_key,
          changeClass: b.change_class,
          title: b.title,
          shortTitle: b.short_title,
          questionText: b.question_text,
          stances: b.stances,
          rationale: b.rationale,
          publicNote: b.public_note,
          reviewRef: b.review_ref,
          rungMap: b.rung_map,
        },
        actorId
      );
      // Audit without masking: the proposal is already filed; a failed audit
      // insert must not report it as failed (a retry would file a duplicate).
      try {
        await logAdminAction(actorId, 'compass:revision:propose', null, {
          topic_key: b.topic_key,
          revision_id: out.revision_id,
          change_class: b.change_class,
          ladder_changed: b.rung_map !== null,
          capacity: reviewerCapacity(req),
        });
      } catch (auditErr) {
        console.error('[POST /compass/revisions] audit log failed:', auditErr);
      }
      res.status(201).json(out);
    } catch (err) {
      sendRpcError(res, err, 'POST /compass/revisions');
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/compass/revisions/queue — open proposals awaiting review
// ---------------------------------------------------------------------------

router.get(
  '/queue',
  requireAuth,
  requireCompassReviewer,
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
  requireCompassReviewer,
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
  requireCompassReviewer,
  async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id as string;
    if (!UUID_RE.test(id)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid revision id' });
      return;
    }
    const actorId = (req as AuthenticatedRequest).userId;
    try {
      await approveRevision(id, actorId);
      await logAdminAction(actorId, 'compass:revision:approve', null, {
        revision_id: id,
        capacity: reviewerCapacity(req),
      });
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
  requireCompassReviewer,
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
        capacity: reviewerCapacity(req),
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
  requireCompassReviewer,
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
        capacity: reviewerCapacity(req),
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
