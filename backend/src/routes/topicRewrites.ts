/**
 * topicRewrites.ts — admin-gated routes for the topic rewrite workflow.
 *
 * Mounted at /api/admin/topic-rewrites. Every route is admin-only via
 * requireAuth + requireAdmin applied at router level. Mutations are logged
 * via logAdminAction (ADMN-05).
 */

import { Router } from 'express';
import { z } from 'zod';
import type { Request } from 'express';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { logAdminAction } from '../lib/adminService.js';
import {
  createTopicRewrite,
  submitRewriteForFramingReview,
  approveRewriteFraming,
  upsertStanceProposal,
  approveStanceProposal,
  rejectStanceProposal,
  markRewritePublishReady,
  publishTopicRewrite,
  listRewrites,
  getRewriteDetail,
} from '../lib/topicRewriteService.js';

const router = Router();

// eslint-disable-next-line @typescript-eslint/no-explicit-any
router.use(requireAuth as any, requireAdmin as any);

const actorId = (req: Request): string => (req as AuthenticatedRequest).userId!;

// ---------------------------------------------------------------------------
// LIST / DETAIL
// ---------------------------------------------------------------------------

router.get('/', async (_req, res, next) => {
  try {
    res.json({ rewrites: await listRewrites() });
  } catch (err) {
    next(err);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const detail = await getRewriteDetail(req.params.id);
    if (!detail) {
      res.status(404).json({ error: 'NOT_FOUND' });
      return;
    }
    res.json(detail);
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// CREATE
// ---------------------------------------------------------------------------

const CreateBody = z.object({
  topic_key: z.string().min(1),
  new_title: z.string().min(1),
  new_short_title: z.string().min(1),
  new_question_text: z.string().min(1),
  new_stances: z
    .array(
      z.object({
        value: z.number().int().min(1).max(5),
        text: z.string().min(1),
      }),
    )
    .length(5),
  notes: z.string().optional(),
});

router.post('/', async (req, res, next) => {
  try {
    const body = CreateBody.parse(req.body);
    const rewriteId = await createTopicRewrite({
      topicKey: body.topic_key,
      actorId: actorId(req),
      newTitle: body.new_title,
      newShortTitle: body.new_short_title,
      newQuestionText: body.new_question_text,
      newStances: body.new_stances,
      notes: body.notes,
    });
    await logAdminAction(actorId(req), 'topic_rewrite.create', null, {
      rewriteId,
      topic_key: body.topic_key,
    });
    res.status(201).json({ rewrite_id: rewriteId });
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// STATE TRANSITIONS
// ---------------------------------------------------------------------------

router.post('/:id/submit-framing', async (req, res, next) => {
  try {
    await submitRewriteForFramingReview(req.params.id);
    await logAdminAction(actorId(req), 'topic_rewrite.submit_framing', null, {
      rewriteId: req.params.id,
    });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

router.post('/:id/approve-framing', async (req, res, next) => {
  try {
    const seeded = await approveRewriteFraming(req.params.id, actorId(req));
    await logAdminAction(actorId(req), 'topic_rewrite.approve_framing', null, {
      rewriteId: req.params.id,
      seeded,
    });
    res.json({ ok: true, seeded_proposals: seeded });
  } catch (err) {
    next(err);
  }
});

router.post('/:id/mark-publish-ready', async (req, res, next) => {
  try {
    await markRewritePublishReady(req.params.id);
    await logAdminAction(actorId(req), 'topic_rewrite.mark_publish_ready', null, {
      rewriteId: req.params.id,
    });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

router.post('/:id/publish', async (req, res, next) => {
  try {
    const result = await publishTopicRewrite(req.params.id, actorId(req));
    await logAdminAction(actorId(req), 'topic_rewrite.publish', null, {
      rewriteId: req.params.id,
      ...result,
    });
    res.json({ ok: true, ...result });
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// STANCE PROPOSALS
// ---------------------------------------------------------------------------

const UpsertProposalBody = z.object({
  proposed_value: z.number().min(1).max(5).nullable(),
  proposed_reasoning: z.string().nullable(),
  proposed_sources: z.array(z.string()).default([]),
});

router.put('/:id/proposals/:politicianId', async (req, res, next) => {
  try {
    const body = UpsertProposalBody.parse(req.body);
    await upsertStanceProposal({
      rewriteId: req.params.id,
      politicianId: req.params.politicianId,
      proposedValue: body.proposed_value,
      proposedReasoning: body.proposed_reasoning,
      proposedSources: body.proposed_sources,
    });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

const DecideBody = z.object({ reviewer_notes: z.string().nullable().optional() });

router.post(
  '/:id/proposals/:politicianId/approve',
  async (req, res, next) => {
    try {
      const { reviewer_notes } = DecideBody.parse(req.body);
      await approveStanceProposal(
        req.params.id,
        req.params.politicianId,
        actorId(req),
        reviewer_notes ?? null,
      );
      await logAdminAction(actorId(req), 'topic_rewrite.approve_proposal', null, {
        rewriteId: req.params.id,
        politicianId: req.params.politicianId,
      });
      res.json({ ok: true });
    } catch (err) {
      next(err);
    }
  },
);

router.post(
  '/:id/proposals/:politicianId/reject',
  async (req, res, next) => {
    try {
      const { reviewer_notes } = DecideBody.parse(req.body);
      await rejectStanceProposal(
        req.params.id,
        req.params.politicianId,
        actorId(req),
        reviewer_notes ?? null,
      );
      await logAdminAction(actorId(req), 'topic_rewrite.reject_proposal', null, {
        rewriteId: req.params.id,
        politicianId: req.params.politicianId,
      });
      res.json({ ok: true });
    } catch (err) {
      next(err);
    }
  },
);

export default router;
