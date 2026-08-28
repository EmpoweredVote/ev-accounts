/**
 * Staging routes — volunteer review workflow for staging entities.
 *
 * Purpose: Satisfies CONS-10 — Staging submission/review/approval served by ev-accounts.
 * The Go server is no longer the authoritative source for staging routes.
 *
 * Access control: ALL routes require auth + staging_reviewer OR admin role.
 * No public or unauthenticated access at any level.
 *
 * Subpath routes (/:id/review, /:id/lock, /:id/merge) are defined BEFORE /:id
 * to prevent Express from matching "review"/"lock"/"merge" as UUID params.
 */

import { Router } from 'express';
import type { Request, Response } from 'express';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.js';
import { requireStagingReviewer } from '../middleware/requireStagingReviewer.js';
import type { AuthenticatedRequest } from '../middleware/auth.js';
import {
  getPoliticians,
  getPoliticianById,
  createPolitician,
  updatePolitician,
  reviewPolitician,
  lockPolitician,
  unlockPolitician,
  mergePolitician,
  getStances,
  getStanceById,
  createStance,
  updateStance,
  reviewStance,
  lockStance,
  unlockStance,
  getPhotos,
  getPhotoById,
  createPhoto,
  reviewPhoto,
} from '../lib/stagingService.js';

const router = Router();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ALL staging routes require auth + staging_reviewer/admin — no exceptions
router.use(requireAuth as any, requireStagingReviewer as any);

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

function validateUuid(id: string, res: Response): boolean {
  if (!UUID_REGEX.test(id)) {
    res.status(400).json({ error: 'Invalid UUID format' });
    return false;
  }
  return true;
}

function handleServiceError(err: any, context: string, res: Response): void {
  if (err.httpStatus) {
    res.status(err.httpStatus).json({ error: err.message });
    return;
  }
  console.error(`[staging] ${context}:`, err);
  res.status(500).json({ error: 'Internal server error' });
}

// ---------------------------------------------------------------------------
// Politician routes
// ---------------------------------------------------------------------------

// GET /api/staging/politicians — list with optional ?status= filter
router.get('/politicians', async (req: Request, res: Response): Promise<void> => {
  const status = typeof req.query.status === 'string' ? req.query.status : undefined;
  try {
    const politicians = await getPoliticians(status ? { status } : undefined);
    res.status(200).json(politicians);
  } catch (err: any) {
    handleServiceError(err, 'GET /politicians', res);
  }
});

// POST /api/staging/politicians/:id/review — BEFORE /:id
router.post('/politicians/:id/review', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!validateUuid(id, res)) return;

  const schema = z.object({
    action: z.enum(['approve', 'reject']),
    comment: z.string().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body', details: parsed.error.issues });
    return;
  }

  const authReq = req as AuthenticatedRequest;
  try {
    const result = await reviewPolitician(id, parsed.data.action, authReq.userId, parsed.data.comment);
    res.status(200).json(result);
  } catch (err: any) {
    handleServiceError(err, `POST /politicians/${id}/review`, res);
  }
});

// POST /api/staging/politicians/:id/lock — BEFORE /:id
router.post('/politicians/:id/lock', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!validateUuid(id, res)) return;

  const authReq = req as AuthenticatedRequest;
  try {
    const result = await lockPolitician(id, authReq.userId);
    if (result.locked) {
      res.status(200).json({ locked: true });
    } else {
      res.status(409).json({ error: 'Lock already held', lockedBy: result.lockedBy, lockedAt: result.lockedAt });
    }
  } catch (err: any) {
    handleServiceError(err, `POST /politicians/${id}/lock`, res);
  }
});

// DELETE /api/staging/politicians/:id/lock — BEFORE /:id
router.delete('/politicians/:id/lock', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!validateUuid(id, res)) return;

  try {
    await unlockPolitician(id);
    res.status(204).send();
  } catch (err: any) {
    handleServiceError(err, `DELETE /politicians/${id}/lock`, res);
  }
});

// POST /api/staging/politicians/:id/merge — BEFORE /:id
router.post('/politicians/:id/merge', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!validateUuid(id, res)) return;

  const schema = z.object({
    targetId: z.string().regex(UUID_REGEX, 'targetId must be a valid UUID'),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body', details: parsed.error.issues });
    return;
  }

  const authReq = req as AuthenticatedRequest;
  try {
    const result = await mergePolitician(id, parsed.data.targetId, authReq.userId);
    res.status(200).json(result);
  } catch (err: any) {
    handleServiceError(err, `POST /politicians/${id}/merge`, res);
  }
});

// GET /api/staging/politicians/:id
router.get('/politicians/:id', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!validateUuid(id, res)) return;

  try {
    const politician = await getPoliticianById(id);
    if (!politician) {
      res.status(404).json({ error: 'Politician not found' });
      return;
    }
    res.status(200).json(politician);
  } catch (err: any) {
    handleServiceError(err, `GET /politicians/${id}`, res);
  }
});

// POST /api/staging/politicians — create new
router.post('/politicians', async (req: Request, res: Response): Promise<void> => {
  const schema = z.object({
    fullName: z.string().min(1),
    party: z.string().optional().nullable(),
    office: z.string().optional().nullable(),
    officeLevel: z.string().optional().nullable(),
    state: z.string().optional().nullable(),
    district: z.string().optional().nullable(),
    bioText: z.string().optional().nullable(),
    photoUrl: z.string().optional().nullable(),
    externalId: z.string().optional().nullable(),
    contacts: z.any().optional(),
    degrees: z.any().optional(),
    experiences: z.any().optional(),
    urls: z.any().optional(),
    images: z.any().optional(),
    addresses: z.any().optional(),
    validFrom: z.string().optional().nullable(),
    validTo: z.string().optional().nullable(),
    totalYearsInOffice: z.number().optional().nullable(),
    isAppointed: z.boolean().optional(),
    isVacant: z.boolean().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body', details: parsed.error.issues });
    return;
  }

  const authReq = req as AuthenticatedRequest;
  try {
    const result = await createPolitician(parsed.data, authReq.userId);
    res.status(201).json(result);
  } catch (err: any) {
    handleServiceError(err, 'POST /politicians', res);
  }
});

// PATCH /api/staging/politicians/:id — update pending
router.patch('/politicians/:id', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!validateUuid(id, res)) return;

  const schema = z.object({
    fullName: z.string().min(1).optional(),
    party: z.string().optional().nullable(),
    office: z.string().optional().nullable(),
    officeLevel: z.string().optional().nullable(),
    state: z.string().optional().nullable(),
    district: z.string().optional().nullable(),
    bioText: z.string().optional().nullable(),
    photoUrl: z.string().optional().nullable(),
    externalId: z.string().optional().nullable(),
    contacts: z.any().optional(),
    degrees: z.any().optional(),
    experiences: z.any().optional(),
    urls: z.any().optional(),
    images: z.any().optional(),
    addresses: z.any().optional(),
    validFrom: z.string().optional().nullable(),
    validTo: z.string().optional().nullable(),
    totalYearsInOffice: z.number().optional().nullable(),
    isAppointed: z.boolean().optional(),
    isVacant: z.boolean().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body', details: parsed.error.issues });
    return;
  }

  try {
    const result = await updatePolitician(id, parsed.data);
    res.status(200).json(result);
  } catch (err: any) {
    handleServiceError(err, `PATCH /politicians/${id}`, res);
  }
});

// ---------------------------------------------------------------------------
// Stance routes
// ---------------------------------------------------------------------------

// GET /api/staging/stances
router.get('/stances', async (req: Request, res: Response): Promise<void> => {
  const status = typeof req.query.status === 'string' ? req.query.status : undefined;
  try {
    const stances = await getStances(status ? { status } : undefined);
    res.status(200).json(stances);
  } catch (err: any) {
    handleServiceError(err, 'GET /stances', res);
  }
});

// POST /api/staging/stances/:id/review — BEFORE /:id
router.post('/stances/:id/review', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!validateUuid(id, res)) return;

  const schema = z.object({
    action: z.enum(['approve', 'reject']),
    comment: z.string().optional(),
    newValue: z.number().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body', details: parsed.error.issues });
    return;
  }

  const authReq = req as AuthenticatedRequest;
  try {
    const result = await reviewStance(id, parsed.data.action, authReq.userId, parsed.data.comment, parsed.data.newValue);
    res.status(200).json(result);
  } catch (err: any) {
    handleServiceError(err, `POST /stances/${id}/review`, res);
  }
});

// POST /api/staging/stances/:id/lock — BEFORE /:id
router.post('/stances/:id/lock', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!validateUuid(id, res)) return;

  const authReq = req as AuthenticatedRequest;
  try {
    const result = await lockStance(id, authReq.userId);
    if (result.locked) {
      res.status(200).json({ locked: true });
    } else {
      res.status(409).json({ error: 'Lock already held', lockedBy: result.lockedBy, lockedAt: result.lockedAt });
    }
  } catch (err: any) {
    handleServiceError(err, `POST /stances/${id}/lock`, res);
  }
});

// DELETE /api/staging/stances/:id/lock — BEFORE /:id
router.delete('/stances/:id/lock', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!validateUuid(id, res)) return;

  try {
    await unlockStance(id);
    res.status(204).send();
  } catch (err: any) {
    handleServiceError(err, `DELETE /stances/${id}/lock`, res);
  }
});

// GET /api/staging/stances/:id
router.get('/stances/:id', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!validateUuid(id, res)) return;

  try {
    const stance = await getStanceById(id);
    if (!stance) {
      res.status(404).json({ error: 'Stance not found' });
      return;
    }
    res.status(200).json(stance);
  } catch (err: any) {
    handleServiceError(err, `GET /stances/${id}`, res);
  }
});

// POST /api/staging/stances — create new
router.post('/stances', async (req: Request, res: Response): Promise<void> => {
  const schema = z.object({
    contextKey: z.string().min(1),
    politicianExternalId: z.string().optional().nullable(),
    politicianName: z.string().min(1),
    topicKey: z.string().min(1),
    topicId: z.string().optional().nullable(),
    value: z.number(),
    reasoning: z.string().optional().nullable(),
    sources: z.array(z.string()).optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body', details: parsed.error.issues });
    return;
  }

  const authReq = req as AuthenticatedRequest;
  try {
    const result = await createStance(parsed.data, authReq.userId);
    res.status(201).json(result);
  } catch (err: any) {
    handleServiceError(err, 'POST /stances', res);
  }
});

// PATCH /api/staging/stances/:id
router.patch('/stances/:id', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!validateUuid(id, res)) return;

  const schema = z.object({
    contextKey: z.string().min(1).optional(),
    politicianExternalId: z.string().optional().nullable(),
    politicianName: z.string().min(1).optional(),
    topicKey: z.string().min(1).optional(),
    topicId: z.string().optional().nullable(),
    value: z.number().optional(),
    reasoning: z.string().optional().nullable(),
    sources: z.array(z.string()).optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body', details: parsed.error.issues });
    return;
  }

  try {
    const result = await updateStance(id, parsed.data);
    res.status(200).json(result);
  } catch (err: any) {
    handleServiceError(err, `PATCH /stances/${id}`, res);
  }
});

// ---------------------------------------------------------------------------
// Building photo routes
// ---------------------------------------------------------------------------

// GET /api/staging/photos
router.get('/photos', async (req: Request, res: Response): Promise<void> => {
  const status = typeof req.query.status === 'string' ? req.query.status : undefined;
  try {
    const photos = await getPhotos(status ? { status } : undefined);
    res.status(200).json(photos);
  } catch (err: any) {
    handleServiceError(err, 'GET /photos', res);
  }
});

// POST /api/staging/photos/:id/review — BEFORE /:id
router.post('/photos/:id/review', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!validateUuid(id, res)) return;

  const schema = z.object({
    action: z.enum(['approve', 'reject']),
    comment: z.string().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body', details: parsed.error.issues });
    return;
  }

  const authReq = req as AuthenticatedRequest;
  try {
    const result = await reviewPhoto(id, parsed.data.action, authReq.userId, parsed.data.comment);
    res.status(200).json(result);
  } catch (err: any) {
    handleServiceError(err, `POST /photos/${id}/review`, res);
  }
});

// GET /api/staging/photos/:id
router.get('/photos/:id', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params as { id: string };
  if (!validateUuid(id, res)) return;

  try {
    const photo = await getPhotoById(id);
    if (!photo) {
      res.status(404).json({ error: 'Building photo not found' });
      return;
    }
    res.status(200).json(photo);
  } catch (err: any) {
    handleServiceError(err, `GET /photos/${id}`, res);
  }
});

// POST /api/staging/photos — create new
router.post('/photos', async (req: Request, res: Response): Promise<void> => {
  const schema = z.object({
    placeGeoid: z.string().min(1),
    placeName: z.string().min(1),
    state: z.string().optional().nullable(),
    url: z.string().url(),
    sourceUrl: z.string().optional().nullable(),
    license: z.string().min(1),
    attribution: z.string().min(1),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body', details: parsed.error.issues });
    return;
  }

  const authReq = req as AuthenticatedRequest;
  try {
    const result = await createPhoto(parsed.data, authReq.userId);
    res.status(201).json(result);
  } catch (err: any) {
    handleServiceError(err, 'POST /photos', res);
  }
});

// NOTE: No lock/unlock routes for photos — building_photos has no locked_by/locked_at columns

export default router;
