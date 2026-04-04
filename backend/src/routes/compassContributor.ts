/**
 * compassContributor — stance write endpoints for compass_stance_editor,
 * campaign_manager, and essentials_data_editor roles.
 *
 * WHY THIS FILE EXISTS:
 * Contributors (campaign managers and regional stance editors) need a way to
 * record politician stances without going through the admin panel. These routes
 * enforce jurisdiction and resource-level access control using the grant system
 * established in Phases 52–53.
 *
 * AUTHORIZATION FLOW:
 * 1. requireAuth — validates JWT, attaches req.userId
 * 2. requireRole(['compass_stance_editor', 'campaign_manager']) — OR check:
 *    user must hold at least one of these roles (any scope). Returns 401/403.
 * 3. Handler body — fine-grained check via getMatchingGrant: verifies the
 *    specific grant authorizes writes for THIS politician. Returns 403 if not.
 *
 * TRANSACTION PATTERN:
 * pool.connect() → BEGIN → operations → COMMIT in try, ROLLBACK in catch,
 * client.release() in finally. Matches vqService.ts exactly.
 *
 * AUDIT LOG:
 * Every stance write (single or bulk) produces a role_audit_log row with:
 * - role_grant_id = matchingGrant.id (user_roles row UUID, NOT role definition UUID)
 * - fields_changed text[] — only fields that actually changed
 * - snapshot_after jsonb — { topic_id, old_value, new_value, write_in_text_changed }
 */

import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireRole } from '../middleware/requireRole.js';
import { getCachedUserRoles } from '../lib/roleService.js';
import {
  getPoliticianJurisdiction,
  getMatchingGrant,
  getContributorPoliticians,
  writeStanceAuditLog,
} from '../lib/stanceService.js';
import { pool } from '../lib/db.js';
import type { Request, Response } from 'express';

const router = Router();

// ---------------------------------------------------------------------------
// UUID validation regex
// ---------------------------------------------------------------------------

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isUUID(s: string): boolean {
  return UUID_RE.test(s);
}

// ---------------------------------------------------------------------------
// Zod schemas
// ---------------------------------------------------------------------------

const singleStanceSchema = z.object({
  value: z.number().int().min(1).max(5),
  write_in_text: z.string().max(500).optional(),
});

const bulkStanceSchema = z.object({
  stances: z
    .array(
      z.object({
        topic_id: z.string().uuid(),
        value: z.number().int().min(1).max(5),
        write_in_text: z.string().max(500).optional(),
      })
    )
    .min(1)
    .max(100),
});

// ---------------------------------------------------------------------------
// GET /contributors/politicians — list politicians the caller can edit
// ---------------------------------------------------------------------------

router.get(
  '/contributors/politicians',
  requireAuth,
  requireRole(['compass_stance_editor', 'campaign_manager', 'essentials_data_editor']),
  async (req: Request, res: Response): Promise<void> => {
    const actorId = (req as AuthenticatedRequest).userId;

    // 1. Get all grants for this user
    const grants = await getCachedUserRoles(actorId);

    // 2. Filter to only compass contributor roles
    const contributorGrants = grants.filter((g) =>
      ['compass_stance_editor', 'campaign_manager', 'essentials_data_editor'].includes(g.slug)
    );

    // 3. Fetch politicians the caller is authorized to edit.
    //    getContributorPoliticians handles deduplication and empty grant lists.
    const politicians = await getContributorPoliticians(contributorGrants);

    // 4. Return flat array (empty array is a valid 200 response)
    res.status(200).json(politicians);
  }
);

// ---------------------------------------------------------------------------
// PUT /stances/:politicianId/:topicId — single stance write
// ---------------------------------------------------------------------------

router.put(
  '/stances/:politicianId/:topicId',
  requireAuth,
  requireRole(['compass_stance_editor', 'campaign_manager']),
  async (req: Request, res: Response): Promise<void> => {
    const politicianId = req.params['politicianId'] as string;
    const topicId = req.params['topicId'] as string;
    const actorId = (req as AuthenticatedRequest).userId;

    // 1. Validate path params are UUIDs
    if (!isUUID(politicianId) || !isUUID(topicId)) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: 'politicianId and topicId must be valid UUIDs',
      });
      return;
    }

    // 2. Parse and validate body
    const parsed = singleStanceSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: parsed.error.issues.map((i) => i.message).join('; '),
      });
      return;
    }
    const { value, write_in_text } = parsed.data;

    // 3. Get user's grants
    const grants = await getCachedUserRoles(actorId);

    // 4. Check politician existence (also retrieves jurisdiction for grant matching).
    // getPoliticianJurisdiction returns null for both "politician not found" and "no geoid
    // assigned" — so we need a separate existence check first.
    const existsResult = await pool.query<{ id: string }>(
      `SELECT id FROM essentials.politicians WHERE id = $1 LIMIT 1`,
      [politicianId]
    );
    if (existsResult.rows.length === 0) {
      res.status(404).json({
        code: 'NOT_FOUND',
        message: 'Politician not found',
      });
      return;
    }

    // Jurisdiction lookup: null = no geoid assigned → fail-open (console.warn in service)
    const resolvedGeoid = await getPoliticianJurisdiction(politicianId);

    // 5. Find matching grant
    const matchingGrant = getMatchingGrant(grants, politicianId, resolvedGeoid);
    if (!matchingGrant) {
      res.status(403).json({
        code: 'FORBIDDEN',
        message: 'You do not have permission to edit stances for this politician',
      });
      return;
    }

    // 6. Begin transaction
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // a. Fetch current value (for audit log diff)
      const prevResult = await client.query<{
        value: number;
        write_in_text: string | null;
      }>(
        `SELECT value, write_in_text
         FROM inform.politician_answers
         WHERE politician_id = $1 AND topic_id = $2`,
        [politicianId, topicId]
      );
      const prev = prevResult.rows[0] ?? null;

      // b. Verify topic exists and is live
      const topicResult = await client.query<{ id: string }>(
        `SELECT id FROM inform.compass_topics WHERE id = $1 AND is_live = true`,
        [topicId]
      );
      if (topicResult.rows.length === 0) {
        await client.query('ROLLBACK');
        res.status(404).json({
          code: 'NOT_FOUND',
          message: 'Topic not found or not live',
        });
        return;
      }

      // c. Upsert stance
      await client.query(
        `INSERT INTO inform.politician_answers (politician_id, topic_id, value, write_in_text)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (politician_id, topic_id)
         DO UPDATE SET value = EXCLUDED.value, write_in_text = EXCLUDED.write_in_text`,
        [politicianId, topicId, value, write_in_text ?? null]
      );

      // d. Write audit log (inside transaction)
      await writeStanceAuditLog(client, {
        actorId,
        targetUserId: actorId,
        roleGrantId: matchingGrant.id,
        featureScope: matchingGrant.feature_scope,
        jurisdictionGeoid: matchingGrant.jurisdiction_geoid,
        resourceId: matchingGrant.resource_id,
        topicId,
        oldValue: prev?.value ?? null,
        newValue: value,
        writeInTextChanged:
          (prev?.write_in_text ?? null) !== (write_in_text ?? null),
      });

      // e. Commit
      await client.query('COMMIT');

      res.status(200).json({
        politician_id: politicianId,
        topic_id: topicId,
        value,
        write_in_text: write_in_text ?? null,
      });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('[compassContributor] single stance write error:', err);
      res.status(500).json({
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred',
      });
    } finally {
      client.release();
    }
  }
);

// ---------------------------------------------------------------------------
// PUT /stances/:politicianId/bulk — batch stance write (all-or-nothing)
// ---------------------------------------------------------------------------

router.put(
  '/stances/:politicianId/bulk',
  requireAuth,
  requireRole(['compass_stance_editor', 'campaign_manager']),
  async (req: Request, res: Response): Promise<void> => {
    const politicianId = req.params['politicianId'] as string;
    const actorId = (req as AuthenticatedRequest).userId;

    // 1. Validate path param
    if (!isUUID(politicianId)) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: 'politicianId must be a valid UUID',
      });
      return;
    }

    // 2. Parse and validate body
    const parsed = bulkStanceSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: parsed.error.issues.map((i) => i.message).join('; '),
      });
      return;
    }
    const { stances } = parsed.data;

    // 3. Get user's grants
    const grants = await getCachedUserRoles(actorId);

    // 4. Check politician existence
    const existsResult = await pool.query<{ id: string }>(
      `SELECT id FROM essentials.politicians WHERE id = $1 LIMIT 1`,
      [politicianId]
    );
    if (existsResult.rows.length === 0) {
      res.status(404).json({
        code: 'NOT_FOUND',
        message: 'Politician not found',
      });
      return;
    }

    // 5. Get politician jurisdiction
    const politicianGeoid = await getPoliticianJurisdiction(politicianId);

    // 6. Find matching grant
    const matchingGrant = getMatchingGrant(grants, politicianId, politicianGeoid);
    if (!matchingGrant) {
      res.status(403).json({
        code: 'FORBIDDEN',
        message: 'You do not have permission to edit stances for this politician',
      });
      return;
    }

    const topicIds = stances.map((s) => s.topic_id);

    // 7. Begin transaction
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // a. Verify ALL topic_ids exist and are live in one query
      const topicCheckResult = await client.query<{ id: string }>(
        `SELECT id FROM inform.compass_topics WHERE id = ANY($1) AND is_live = true`,
        [topicIds]
      );
      const validTopicIds = new Set(topicCheckResult.rows.map((r) => r.id));
      const invalidTopicIds = topicIds.filter((id) => !validTopicIds.has(id));
      if (invalidTopicIds.length > 0) {
        await client.query('ROLLBACK');
        res.status(422).json({
          code: 'VALIDATION_ERROR',
          message: `Invalid or non-live topic IDs: ${invalidTopicIds.join(', ')}`,
        });
        return;
      }

      // b. Fetch ALL current values for diff computation
      const prevResult = await client.query<{
        topic_id: string;
        value: number;
        write_in_text: string | null;
      }>(
        `SELECT topic_id, value, write_in_text
         FROM inform.politician_answers
         WHERE politician_id = $1 AND topic_id = ANY($2)`,
        [politicianId, topicIds]
      );
      const prevMap = new Map(prevResult.rows.map((r) => [r.topic_id, r]));

      // c. Upsert each stance and write audit log
      let written = 0;
      for (const stance of stances) {
        const prev = prevMap.get(stance.topic_id) ?? null;
        const valueUnchanged = prev?.value === stance.value;
        const writeInTextUnchanged =
          (prev?.write_in_text ?? null) === (stance.write_in_text ?? null);

        // Skip if nothing changed
        if (valueUnchanged && writeInTextUnchanged) continue;

        // Upsert
        await client.query(
          `INSERT INTO inform.politician_answers (politician_id, topic_id, value, write_in_text)
           VALUES ($1, $2, $3, $4)
           ON CONFLICT (politician_id, topic_id)
           DO UPDATE SET value = EXCLUDED.value, write_in_text = EXCLUDED.write_in_text`,
          [politicianId, stance.topic_id, stance.value, stance.write_in_text ?? null]
        );

        // Audit log entry for this topic
        await writeStanceAuditLog(client, {
          actorId,
          targetUserId: actorId,
          roleGrantId: matchingGrant.id,
          featureScope: matchingGrant.feature_scope,
          jurisdictionGeoid: matchingGrant.jurisdiction_geoid,
          resourceId: matchingGrant.resource_id,
          topicId: stance.topic_id,
          oldValue: prev?.value ?? null,
          newValue: stance.value,
          writeInTextChanged: !writeInTextUnchanged,
        });

        written++;
      }

      await client.query('COMMIT');

      res.status(200).json({
        politician_id: politicianId,
        updated: written,
      });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('[compassContributor] bulk stance write error:', err);
      res.status(500).json({
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred',
      });
    } finally {
      client.release();
    }
  }
);

export default router;
