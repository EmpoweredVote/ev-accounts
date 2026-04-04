/**
 * essentialsEditor — PATCH endpoint for essentials_data_editor role holders.
 *
 * WHY THIS FILE EXISTS:
 * Essentials Data Editors need to update politician bio fields (bio, preferred_name,
 * photo_origin_url) within their assigned jurisdiction. This route enforces:
 *   1. Restricted field validation — structural fields cannot be written via this endpoint
 *   2. Jurisdiction-based authorization via getEditorMatchingGrant (fail-CLOSED)
 *   3. No-op detection — unchanged values do not generate audit log entries
 *   4. Atomic UPDATE + audit log within a single transaction
 *
 * CRITICAL FIELD NAME MAPPINGS:
 *   API field "bio"             -> DB column "bio_text"       (NOT "bio" — column does not exist)
 *   API field "photo_origin_url"-> DB column "photo_custom_url" (override column; COALESCE prefers
 *                                  it over photo_origin_url in reads; reads return "photo_url")
 *   "office_title"              -> NOT writable in Phase 56 (lives in essentials.offices, deferred)
 *
 * AUTHORIZATION FLOW:
 * 1. requireAuth — validates JWT, attaches req.userId
 * 2. requireRole('essentials_data_editor') — user must hold this role (any scope)
 * 3. Handler body — fine-grained check via getEditorMatchingGrant: verifies the
 *    specific grant authorizes edits for THIS politician's jurisdiction. Returns 403 if not.
 *
 * TRANSACTION PATTERN:
 * pool.connect() → BEGIN → UPDATE → writeEssentialsAuditLog → COMMIT in try,
 * ROLLBACK in catch, client.release() in finally. Matches compassContributor.ts.
 */

import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireRole } from '../middleware/requireRole.js';
import { getCachedUserRoles } from '../lib/roleService.js';
import {
  getEditorMatchingGrant,
  writeEssentialsAuditLog,
} from '../lib/stanceService.js';
import { pool } from '../lib/db.js';
import type { Request, Response } from 'express';

const router = Router();

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/** Fields that cannot be written via this endpoint — return 422 if present in body. */
const RESTRICTED_FIELDS = ['district_type', 'district_id', 'is_active', 'is_candidate', 'is_vacant'];

// ---------------------------------------------------------------------------
// UUID validation
// ---------------------------------------------------------------------------

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isUUID(s: string): boolean {
  return UUID_RE.test(s);
}

// ---------------------------------------------------------------------------
// Zod schema
// ---------------------------------------------------------------------------

const patchPoliticianSchema = z
  .object({
    bio: z.string().max(10000).optional(),
    photo_origin_url: z
      .string()
      .url()
      .max(2048)
      .optional()
      .or(z.literal('').transform(() => null as string | null)),
    preferred_name: z
      .string()
      .max(200)
      .optional()
      .or(z.literal('').transform(() => null as string | null)),
  })
  .refine((data) => Object.values(data).some((v) => v !== undefined), {
    message: 'At least one field must be provided',
  });

// ---------------------------------------------------------------------------
// DB row types
// ---------------------------------------------------------------------------

interface PoliticianExistenceRow {
  id: string;
  home_jurisdiction_geoid: string | null;
}

interface PoliticianCurrentRow {
  bio_text: string | null;
  preferred_name: string | null;
  photo_custom_url: string | null;
}

interface PoliticianUpdatedRow {
  id: string;
  full_name: string | null;
  first_name: string | null;
  last_name: string | null;
  preferred_name: string | null;
  bio_text: string | null;
  photo_custom_url: string | null;
  photo_url: string | null;
}

// ---------------------------------------------------------------------------
// PATCH /:id — update politician bio fields
// ---------------------------------------------------------------------------

router.patch(
  '/:id',
  requireAuth,
  requireRole('essentials_data_editor'),
  async (req: Request, res: Response): Promise<void> => {
    const politicianId = req.params['id'] as string;
    const actorId = (req as AuthenticatedRequest).userId;

    // 1. Validate :id is UUID format
    if (!isUUID(politicianId)) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: 'id must be a valid UUID',
      });
      return;
    }

    // 2. Check for restricted fields in req.body BEFORE zod parse
    const bodyKeys = Object.keys(req.body || {});
    const offendingFields = bodyKeys.filter((k) => RESTRICTED_FIELDS.includes(k));
    if (offendingFields.length > 0) {
      res.status(422).json({
        code: 'RESTRICTED_FIELDS',
        message: `The following fields cannot be modified via this endpoint: ${offendingFields.join(', ')}`,
        fields: offendingFields,
      });
      return;
    }

    // 3. Parse and validate body with zod
    const parsed = patchPoliticianSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: parsed.error.issues.map((i) => i.message).join('; '),
      });
      return;
    }
    const body = parsed.data;

    // 4. Get grants for this user
    const grants = await getCachedUserRoles(actorId);

    // 5. Fetch politician existence + jurisdiction
    const existsResult = await pool.query<PoliticianExistenceRow>(
      `SELECT id, home_jurisdiction_geoid
       FROM essentials.politicians
       WHERE id = $1
       LIMIT 1`,
      [politicianId]
    );
    if (existsResult.rows.length === 0) {
      res.status(404).json({
        code: 'NOT_FOUND',
        message: 'Politician not found',
      });
      return;
    }
    const politicianGeoid = existsResult.rows[0]!.home_jurisdiction_geoid;

    // 6. Find matching grant — fail-CLOSED (403 if null)
    const matchingGrant = getEditorMatchingGrant(grants, politicianGeoid);
    if (!matchingGrant) {
      res.status(403).json({
        code: 'FORBIDDEN',
        message: 'You do not have permission to edit this politician',
      });
      return;
    }

    // 7. Fetch current values for no-op detection
    //    API field "bio" -> DB column "bio_text"
    //    API field "photo_origin_url" -> DB column "photo_custom_url"
    const currentResult = await pool.query<PoliticianCurrentRow>(
      `SELECT bio_text, preferred_name, photo_custom_url
       FROM essentials.politicians
       WHERE id = $1`,
      [politicianId]
    );
    const cur = currentResult.rows[0]!;

    // Build changed map — only fields provided in the request that differ from DB
    const changed: Record<string, { old: unknown; new: unknown }> = {};

    if (body.bio !== undefined && body.bio !== cur.bio_text) {
      changed['bio'] = { old: cur.bio_text, new: body.bio };
    }
    if (body.photo_origin_url !== undefined && body.photo_origin_url !== cur.photo_custom_url) {
      changed['photo_origin_url'] = { old: cur.photo_custom_url, new: body.photo_origin_url };
    }
    if (body.preferred_name !== undefined && body.preferred_name !== cur.preferred_name) {
      changed['preferred_name'] = { old: cur.preferred_name, new: body.preferred_name };
    }

    // 8. No-op — return current record without writing audit log
    if (Object.keys(changed).length === 0) {
      res.status(200).json({
        id: politicianId,
        full_name: null,     // not in current fetch — re-fetch to keep response consistent
        first_name: null,
        last_name: null,
        preferred_name: cur.preferred_name,
        bio: cur.bio_text,
        photo_url: cur.photo_custom_url,
      });
      return;
    }

    // 9. Transaction: UPDATE changed columns + audit log
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Build dynamic UPDATE — only SET columns that actually changed
      const setClauses: string[] = [];
      const values: unknown[] = [];
      let paramIdx = 1;

      if ('bio' in changed) {
        setClauses.push(`bio_text = $${paramIdx++}`);
        values.push((changed['bio']!).new);
      }
      if ('photo_origin_url' in changed) {
        setClauses.push(`photo_custom_url = $${paramIdx++}`);
        values.push((changed['photo_origin_url']!).new);
      }
      if ('preferred_name' in changed) {
        setClauses.push(`preferred_name = $${paramIdx++}`);
        values.push((changed['preferred_name']!).new);
      }

      // Append politician id as last param
      values.push(politicianId);
      const idParam = paramIdx;

      const updateResult = await client.query<PoliticianUpdatedRow>(
        `UPDATE essentials.politicians
         SET ${setClauses.join(', ')}
         WHERE id = $${idParam}
         RETURNING
           id,
           full_name,
           first_name,
           last_name,
           preferred_name,
           bio_text,
           photo_custom_url,
           COALESCE(photo_custom_url, photo_origin_url, '') AS photo_url`,
        values
      );

      const updated = updateResult.rows[0]!;

      // Write audit log inside the transaction
      await writeEssentialsAuditLog(client, {
        actorId,
        roleGrantId: matchingGrant.id,
        featureScope: matchingGrant.feature_scope,
        jurisdictionGeoid: matchingGrant.jurisdiction_geoid,
        resourceId: matchingGrant.resource_id,
        politicianId,
        fieldsChanged: Object.keys(changed),
        changes: changed,
      });

      await client.query('COMMIT');

      // Respond with API field names (not DB column names)
      res.status(200).json({
        id: updated.id,
        full_name: updated.full_name,
        first_name: updated.first_name,
        last_name: updated.last_name,
        preferred_name: updated.preferred_name,
        bio: updated.bio_text,
        photo_url: updated.photo_url,
      });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('[essentialsEditor] PATCH politician error:', err);
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
