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
import {
  UPSERT_ANSWER_WITH_WRITE_IN_SQL, UPSERT_CONTEXT_SOURCES_SQL,
  OPEN_SEASON_ANSWER_SQL, DELETE_ANSWER_OPEN_SEASON_SQL, assertWritten,
  isSeasonWriteError, writableTopicIds,
} from '../lib/seasonService.js';

/**
 * Answer a caught write error.
 *
 * A season refusal is NOT an internal error — it means the editorial calendar is
 * not ready for this write, which an operator can fix. Serving it as a 500 with
 * "an unexpected error occurred" hides the one sentence that says what to do,
 * and hides it specifically from the person who could act on it.
 *
 * This is live right now, not hypothetical: season 1 is closed and no season is
 * open, so EVERY stance write on this router currently takes this path.
 *
 * 409, not 400 — the request is well formed and the caller did nothing wrong.
 * The server's state is what conflicts.
 */
function respondToWriteError(res: Response, err: unknown, context: string): void {
  if (isSeasonWriteError(err)) {
    console.warn(`[compassContributor] ${context} refused by the season gate:`, err.message);
    res.status(409).json({
      code: err.reason,
      message: err.message,
      topic_id: err.topicId,
    });
    return;
  }
  console.error(`[compassContributor] ${context} error:`, err);
  res.status(500).json({
    code: 'INTERNAL_ERROR',
    message: 'An unexpected error occurred',
  });
}

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
  // min(0), not min(1): 0 is a BLANK — the politician was researched and the
  // ladder moved out from under them, so no rung states what they hold. It is a
  // different fact from an absent row, which means "not researched". See
  // CLAUDE.md, "A blank is value = 0".
  value: z.number().int().min(0).max(5),
  write_in_text: z.string().max(500).optional(),
});

const bulkStanceSchema = z.object({
  stances: z
    .array(
      z.object({
        topic_id: z.string().uuid(),
        // min(0) — a blank. Note this is NOT clear_topic_ids below: clearing
        // DELETES the open-season row, so the read falls back to the previous
        // season's answer. Blanking says "no position now" and shadows it.
        value: z.number().int().min(0).max(5),
        write_in_text: z.string().max(500).optional(),
      })
    )
    .max(100)
    .default([]),
  clear_topic_ids: z.array(z.string().uuid()).max(100).default([]),
}).refine(
  (d) => d.stances.length > 0 || d.clear_topic_ids.length > 0,
  { message: 'Must provide at least one stance update or clear' }
);

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
// PUT /stances/:politicianId/bulk — batch stance write (all-or-nothing)
// MUST be registered before /stances/:politicianId/:topicId — otherwise
// Express captures "bulk" as :topicId and this route is never reached.
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
    const { stances, clear_topic_ids } = parsed.data;

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
    // Deduplicate clear_topic_ids and exclude any that are also being upserted
    const topicIdSet = new Set(topicIds);
    const clearIds = [...new Set(clear_topic_ids)].filter((id) => !topicIdSet.has(id));

    // 7. Begin transaction
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // a. Verify ALL upsert topic_ids may currently hold an answer.
      //
      // 🔴 THIS MUST ASK THE SAME QUESTION AS THE WRITE BELOW. It used to check
      // `is_live = true`, which is promotion state and not the write gate at all
      // — the upsert sources its INSERT from the open season's question set, and
      // politician_answers_pin_fkey enforces that in the schema. The two agreed
      // only by accident, because all 44 topics are both live and in season 1.
      // The moment a season drops a topic they diverge, and this check would wave
      // a write through to fail deeper down as an exception, past the point where
      // the caller can be told which topic was the problem.
      //
      // writableTopicIds() reads the upsert's own FROM clause. See seasonService.
      if (topicIds.length > 0) {
        const writable = await writableTopicIds(client, topicIds);
        const invalidTopicIds = topicIds.filter((id) => !writable.has(id));
        if (invalidTopicIds.length > 0) {
          await client.query('ROLLBACK');
          res.status(422).json({
            code: 'TOPIC_NOT_IN_SEASON',
            message:
              'These topics are not in the open season\'s question set, so there is no ' +
              `pinned ladder revision to record an answer against: ${invalidTopicIds.join(', ')}`,
            invalid_topic_ids: invalidTopicIds,
          });
          return;
        }
      }

      // b. Fetch current values for all affected topics (upserts + clears)
      const allTopicIds = [...topicIds, ...clearIds];
      const prevResult = await client.query<{
        topic_id: string;
        value: number;
        write_in_text: string | null;
      }>(
        // The OPEN season's rows, not the newest answered. The upsert below lands
        // in the open season, so "previous value" must mean that season's value —
        // diffing against season 1 while writing season 2 logs "3 -> 3" for what
        // is really a brand new row.
        `${OPEN_SEASON_ANSWER_SQL} AND a.topic_id = ANY($2)`,
        [politicianId, allTopicIds]
      );
      const prevMap = new Map(prevResult.rows.map((r) => [r.topic_id, r]));

      // c. Upsert each stance and write audit log
      let written = 0;
      for (const stance of stances) {
        const prev = prevMap.get(stance.topic_id) ?? null;
        const valueUnchanged = prev?.value === stance.value;
        const writeInTextUnchanged =
          (prev?.write_in_text ?? null) === (stance.write_in_text ?? null);

        if (valueUnchanged && writeInTextUnchanged) continue;

        const wrote = await client.query(UPSERT_ANSWER_WITH_WRITE_IN_SQL,
          [politicianId, stance.topic_id, stance.value, actorId, stance.write_in_text ?? null]
        );
        await assertWritten(wrote.rowCount ?? 0, stance.topic_id);

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

      // d. Delete cleared stances and audit each
      let cleared = 0;
      for (const topicId of clearIds) {
        const prev = prevMap.get(topicId) ?? null;
        if (!prev) continue; // Nothing to clear

        // Open season ONLY. Unconstrained this clears the answer in EVERY season,
        // destroying a closed season's record — the one thing seasons exist to
        // make impossible.
        await client.query(DELETE_ANSWER_OPEN_SEASON_SQL, [politicianId, topicId]);

        await writeStanceAuditLog(client, {
          actorId,
          targetUserId: actorId,
          roleGrantId: matchingGrant.id,
          featureScope: matchingGrant.feature_scope,
          jurisdictionGeoid: matchingGrant.jurisdiction_geoid,
          resourceId: matchingGrant.resource_id,
          topicId,
          oldValue: prev.value,
          newValue: null,
          writeInTextChanged: prev.write_in_text !== null,
        });

        cleared++;
      }

      await client.query('COMMIT');

      res.status(200).json({
        politician_id: politicianId,
        updated: written,
        cleared,
      });
    } catch (err) {
      await client.query('ROLLBACK');
      respondToWriteError(res, err, 'bulk stance write');
    } finally {
      client.release();
    }
  }
);

// ---------------------------------------------------------------------------
// PUT /stances/:politicianId/:topicId — single stance write
// Registered AFTER the bulk route so "bulk" isn't captured as :topicId.
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
        // Open season only — see the batch handler above for why not newest.
        `${OPEN_SEASON_ANSWER_SQL} AND a.topic_id = $2`,
        [politicianId, topicId]
      );
      const prev = prevResult.rows[0] ?? null;

      // b. Verify the topic may currently hold an answer — the same question the
      //    write asks. See the bulk handler above for why is_live was wrong here.
      const writable = await writableTopicIds(client, [topicId]);
      if (!writable.has(topicId)) {
        await client.query('ROLLBACK');
        // 422, not the 404 this used to return. The topic is not missing — it
        // exists and may well hold answers from an earlier season. What is
        // absent is this season's question about it, and "not found" sends the
        // caller looking for a deleted topic that is sitting right there.
        res.status(422).json({
          code: 'TOPIC_NOT_IN_SEASON',
          message:
            'This topic is not in the open season\'s question set, so there is no ' +
            'pinned ladder revision to record an answer against.',
          invalid_topic_ids: [topicId],
        });
        return;
      }

      // c. Upsert stance
      const wrote = await client.query(UPSERT_ANSWER_WITH_WRITE_IN_SQL,
        [politicianId, topicId, value, actorId, write_in_text ?? null]
      );
      await assertWritten(wrote.rowCount ?? 0, topicId);

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
      respondToWriteError(res, err, 'single stance write');
    } finally {
      client.release();
    }
  }
);

// ---------------------------------------------------------------------------
// PUT /compass/contributors/:politicianId/sources — save source URLs per topic
// Contributors only write sources; reasoning stays admin-controlled.
// ---------------------------------------------------------------------------

const sourcesSchema = z.object({
  sources: z
    .array(
      z.object({
        topic_id: z.string().uuid(),
        source_url: z.string().max(2048),
      })
    )
    .min(1)
    .max(100),
});

router.put(
  '/contributors/:politicianId/sources',
  requireAuth,
  requireRole(['compass_stance_editor', 'campaign_manager']),
  async (req: Request, res: Response): Promise<void> => {
    const politicianId = req.params['politicianId'] as string;
    const actorId = (req as AuthenticatedRequest).userId;

    if (!isUUID(politicianId)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'politicianId must be a valid UUID' });
      return;
    }

    const parsed = sourcesSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: parsed.error.issues.map((i) => i.message).join('; '),
      });
      return;
    }

    const grants = await getCachedUserRoles(actorId);

    const existsResult = await pool.query<{ id: string }>(
      `SELECT id FROM essentials.politicians WHERE id = $1 LIMIT 1`,
      [politicianId]
    );
    if (existsResult.rows.length === 0) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Politician not found' });
      return;
    }

    const politicianGeoid = await getPoliticianJurisdiction(politicianId);
    const matchingGrant = getMatchingGrant(grants, politicianId, politicianGeoid);
    if (!matchingGrant) {
      res.status(403).json({ code: 'FORBIDDEN', message: 'You do not have permission to edit this politician' });
      return;
    }

    try {
      // This handler had NO topic pre-flight — it relied entirely on
      // assertWritten firing mid-loop. That matters more here than on the other
      // two paths, because this loop has no transaction around it: a refusal on
      // the fourth source leaves the first three written and returns an error,
      // so the caller cannot tell what landed. Checking every topic up front
      // makes the common refusal happen before anything is written.
      //
      // ⚠ It does NOT make the loop atomic. A failure part-way through for any
      // other reason still leaves earlier rows written. That is pre-existing and
      // wants a transaction; this only removes the season gate as a cause.
      const requestedTopicIds = parsed.data.sources.map((s) => s.topic_id);
      const writable = await writableTopicIds(pool, requestedTopicIds);
      const notInSeason = requestedTopicIds.filter((id) => !writable.has(id));
      if (notInSeason.length > 0) {
        res.status(422).json({
          code: 'TOPIC_NOT_IN_SEASON',
          message:
            'These topics are not in the open season\'s question set, so there is no ' +
            `pinned ladder revision to record sources against: ${notInSeason.join(', ')}`,
          invalid_topic_ids: notInSeason,
        });
        return;
      }

      for (const { topic_id, source_url } of parsed.data.sources) {
        const sources = source_url.trim() ? [source_url.trim()] : [];
        // Sources only — this shape deliberately does NOT touch `reasoning`,
        // which is voter-facing and belongs to whoever wrote it.
        const wrote = await pool.query(UPSERT_CONTEXT_SOURCES_SQL,
          [politicianId, topic_id, sources, actorId]
        );
        await assertWritten(wrote.rowCount ?? 0, topic_id);
      }
      res.status(200).json({ updated: parsed.data.sources.length });
    } catch (err) {
      respondToWriteError(res, err, 'source write');
    }
  }
);

export default router;
