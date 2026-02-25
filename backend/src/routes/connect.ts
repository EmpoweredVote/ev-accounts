import { Router } from 'express';
import { z } from 'zod';
import { pool } from '../lib/db.js';
import { claimInviteCode } from '../lib/inviteService.js';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import type { Request, Response } from 'express';

/**
 * Connect flow routes — the single enrollment pipeline from Inform to Connected tier.
 *
 * Step state machine: invite -> profile -> review -> complete
 *
 * All DB writes use the pg pool directly (never via Supabase JS client in this file).
 * This satisfies the architecture constraint enforced by architecture.test.ts.
 *
 * POST /start          — Claim invite code, create or resume verification_session
 * PATCH /step          — Update draft profile fields, advance step when complete
 * POST /complete       — Atomic transaction: create connected_profiles record
 * GET /status          — Check current verification stage
 * POST /compass-import — Two-phase: validate topic versions, then store draft
 */

const router = Router();

// ---------------------------------------------------------------------------
// Validation schemas
// ---------------------------------------------------------------------------

const startBodySchema = z.object({
  code: z.string().min(9).max(9),
});

const stepBodySchema = z.object({
  step: z.enum(['profile', 'review']),
  display_name: z.string().min(1).max(100).optional(),
  legal_name: z.string().min(1).max(200).optional(),
  location: z.string().min(1).max(200).optional(),
  home_address: z.string().min(1).max(500).optional(),
});

const compassImportBodySchema = z.object({
  calibrations: z.array(
    z.object({
      topic_id: z.string().uuid(),
      topic_version: z.number().int().positive(),
      stance_id: z.string().uuid(),
      inverted: z.boolean().optional().default(false),
    })
  ),
  confirmed: z.boolean().optional().default(false),
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Map ClaimResult error codes to HTTP status codes and error payloads.
 * Mirrors the mapping in invites.ts claim route for consistency.
 */
function sendClaimError(
  res: Response,
  error: 'INVALID_CODE' | 'CODE_ALREADY_CLAIMED' | 'CODE_EXPIRED' | 'SELF_INVITE_BLOCKED'
): void {
  switch (error) {
    case 'INVALID_CODE':
      res.status(404).json({ code: 'INVALID_CODE', message: 'Invite code not found' });
      break;
    case 'CODE_ALREADY_CLAIMED':
      res
        .status(409)
        .json({ code: 'CODE_ALREADY_CLAIMED', message: 'This invite code has already been used' });
      break;
    case 'CODE_EXPIRED':
      res.status(410).json({ code: 'CODE_EXPIRED', message: 'This invite code has expired' });
      break;
    case 'SELF_INVITE_BLOCKED':
      res
        .status(403)
        .json({ code: 'SELF_INVITE_BLOCKED', message: 'You cannot claim your own invite code' });
      break;
  }
}

// ---------------------------------------------------------------------------
// POST /api/connect/start
// ---------------------------------------------------------------------------

/**
 * Begin or resume the Connect verification flow.
 *
 * Flow:
 * 1. If user already has a connected_profiles row → 409 ALREADY_CONNECTED
 * 2. If user has a verification_session at a step beyond 'invite' → resume (200)
 * 3. Otherwise: claim the provided invite code and UPSERT a verification_session
 *    at step 'profile' with the claimed code's ID recorded.
 *
 * The UPSERT handles the edge case where a user starts the flow, abandons
 * at step 'invite' (session exists but step never advanced), then tries again.
 * ON CONFLICT (user_id) DO UPDATE resets the session cleanly.
 */
router.post('/start', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const { userId } = req as AuthenticatedRequest;

  const parsed = startBodySchema.safeParse(req.body);
  if (!parsed.success) {
    const firstIssue = parsed.error.issues[0];
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: firstIssue?.message ?? 'Invalid request body',
    });
    return;
  }

  const client = await pool.connect();
  try {
    // 1. Check if user is already Connected
    const { rows: connectedRows } = await client.query<{ id: string }>(
      'SELECT id FROM connect.connected_profiles WHERE user_id = $1',
      [userId]
    );
    if (connectedRows.length > 0) {
      res.status(409).json({
        code: 'ALREADY_CONNECTED',
        message: 'You already have a Connected profile',
      });
      return;
    }

    // 2. Check for an existing session
    const { rows: sessionRows } = await client.query<{
      id: string;
      step_reached: string;
      display_name_draft: string | null;
      legal_name_draft: string | null;
      region_draft: string | null;
      home_address_draft: string | null;
      invite_code_id: string | null;
    }>(
      `SELECT id, step_reached, display_name_draft, legal_name_draft, region_draft, home_address_draft, invite_code_id
         FROM connect.verification_sessions
        WHERE user_id = $1`,
      [userId]
    );

    const existingSession = sessionRows[0] ?? null;

    // If session exists and has progressed beyond 'invite', resume
    if (existingSession && existingSession.step_reached !== 'invite') {
      res.status(200).json({
        session_id: existingSession.id,
        step_reached: existingSession.step_reached,
        drafts: {
          display_name_draft: existingSession.display_name_draft,
          legal_name_draft: existingSession.legal_name_draft,
          region_draft: existingSession.region_draft,
          home_address_draft: existingSession.home_address_draft,
        },
      });
      return;
    }

    // 3. Claim the invite code
    const normalizedCode = parsed.data.code.toUpperCase().trim();
    let claimResult;
    try {
      claimResult = await claimInviteCode(normalizedCode, userId);
    } catch (err) {
      console.error('[connect/start] Unexpected error during code claim:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      return;
    }

    if (!claimResult.success) {
      sendClaimError(res, claimResult.error);
      return;
    }

    // 4. UPSERT verification_session at step 'profile' with the claimed code ID
    const { rows: upsertRows } = await client.query<{
      id: string;
      step_reached: string;
      display_name_draft: string | null;
      legal_name_draft: string | null;
      region_draft: string | null;
      home_address_draft: string | null;
    }>(
      `INSERT INTO connect.verification_sessions (user_id, step_reached, invite_code_id, updated_at)
       VALUES ($1, 'profile', $2, now())
       ON CONFLICT (user_id) DO UPDATE
         SET step_reached    = 'profile',
             invite_code_id  = $2,
             updated_at      = now()
       RETURNING id, step_reached, display_name_draft, legal_name_draft, region_draft, home_address_draft`,
      [userId, claimResult.codeId]
    );

    const session = upsertRows[0]!;
    res.status(200).json({
      session_id: session.id,
      step_reached: session.step_reached,
      drafts: {
        display_name_draft: session.display_name_draft,
        legal_name_draft: session.legal_name_draft,
        region_draft: session.region_draft,
        home_address_draft: session.home_address_draft,
      },
    });
  } catch (err) {
    console.error('[connect/start] Unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  } finally {
    client.release();
  }
});

// ---------------------------------------------------------------------------
// PATCH /api/connect/step
// ---------------------------------------------------------------------------

/**
 * Update draft profile fields for the current verification step.
 *
 * Accepts whichever fields the user has filled in so far.
 * If the caller sets step='review' AND all 4 required fields are non-null
 * after the update, step_reached advances to 'review'.
 * If step='profile', step_reached stays at 'profile' (still filling fields).
 *
 * The field mapping: `location` in the request body → `region_draft` in the DB.
 * This preserves the internal schema name while exposing a friendlier API name.
 */
router.patch('/step', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const { userId } = req as AuthenticatedRequest;

  const parsed = stepBodySchema.safeParse(req.body);
  if (!parsed.success) {
    const firstIssue = parsed.error.issues[0];
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: firstIssue?.message ?? 'Invalid request body',
    });
    return;
  }

  const { step, display_name, legal_name, location, home_address } = parsed.data;

  const client = await pool.connect();
  try {
    // 1. Fetch current session
    const { rows: sessionRows } = await client.query<{
      id: string;
      step_reached: string;
      display_name_draft: string | null;
      legal_name_draft: string | null;
      region_draft: string | null;
      home_address_draft: string | null;
    }>(
      `SELECT id, step_reached, display_name_draft, legal_name_draft, region_draft, home_address_draft
         FROM connect.verification_sessions
        WHERE user_id = $1`,
      [userId]
    );

    if (sessionRows.length === 0) {
      res.status(404).json({ code: 'NO_SESSION', message: 'No active verification session' });
      return;
    }

    const session = sessionRows[0]!;

    if (session.step_reached === 'complete') {
      res.status(409).json({
        code: 'ALREADY_COMPLETE',
        message: 'Your Connect flow is already complete',
      });
      return;
    }

    // 2. Build SET clauses — only update fields that were provided
    // Compute merged values to determine if we can advance to 'review'
    const newDisplayName =
      display_name !== undefined ? display_name : session.display_name_draft;
    const newLegalName = legal_name !== undefined ? legal_name : session.legal_name_draft;
    const newRegion = location !== undefined ? location : session.region_draft;
    const newHomeAddress =
      home_address !== undefined ? home_address : session.home_address_draft;

    // Determine new step_reached
    const allRequiredPresent =
      newDisplayName !== null &&
      newDisplayName !== undefined &&
      newLegalName !== null &&
      newLegalName !== undefined &&
      newRegion !== null &&
      newRegion !== undefined &&
      newHomeAddress !== null &&
      newHomeAddress !== undefined;

    const newStepReached = step === 'review' && allRequiredPresent ? 'review' : 'profile';

    // 3. Execute the UPDATE with explicit SET clauses
    const { rows: updatedRows } = await client.query<{
      id: string;
      step_reached: string;
      display_name_draft: string | null;
      legal_name_draft: string | null;
      region_draft: string | null;
      home_address_draft: string | null;
    }>(
      `UPDATE connect.verification_sessions
          SET display_name_draft = $1,
              legal_name_draft   = $2,
              region_draft       = $3,
              home_address_draft = $4,
              step_reached       = $5,
              updated_at         = now()
        WHERE user_id = $6
        RETURNING id, step_reached, display_name_draft, legal_name_draft, region_draft, home_address_draft`,
      [newDisplayName ?? null, newLegalName ?? null, newRegion ?? null, newHomeAddress ?? null, newStepReached, userId]
    );

    const updated = updatedRows[0]!;
    res.status(200).json({
      session_id: updated.id,
      step_reached: updated.step_reached,
      drafts: {
        display_name_draft: updated.display_name_draft,
        legal_name_draft: updated.legal_name_draft,
        region_draft: updated.region_draft,
        home_address_draft: updated.home_address_draft,
      },
    });
  } catch (err) {
    console.error('[connect/step] Unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  } finally {
    client.release();
  }
});

// ---------------------------------------------------------------------------
// POST /api/connect/complete
// ---------------------------------------------------------------------------

/**
 * Finalize the Connect flow and atomically create a connected_profiles record.
 *
 * All operations run in a single pg transaction with a FOR UPDATE lock on the
 * verification_session row. This prevents concurrent complete attempts from
 * creating duplicate connected_profiles rows.
 *
 * Idempotency: if connected_profiles already exists for this user, returns 409
 * rather than erroring — the caller can treat the second attempt as a no-op.
 *
 * Response intentionally omits tolerance_rating and legal_name — privacy
 * enforcement at the serialization layer (not just RLS).
 */
router.post('/complete', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const { userId } = req as AuthenticatedRequest;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Lock the verification_session row for this transaction
    const { rows: sessionRows } = await client.query<{
      id: string;
      step_reached: string;
      display_name_draft: string | null;
      legal_name_draft: string | null;
      region_draft: string | null;
      home_address_draft: string | null;
    }>(
      `SELECT id, step_reached, display_name_draft, legal_name_draft, region_draft, home_address_draft
         FROM connect.verification_sessions
        WHERE user_id = $1
          FOR UPDATE`,
      [userId]
    );

    if (sessionRows.length === 0) {
      await client.query('ROLLBACK');
      res.status(404).json({ code: 'NO_SESSION', message: 'No active verification session' });
      return;
    }

    const session = sessionRows[0]!;

    // 2. Validate that the session is in the 'review' step
    if (session.step_reached !== 'review') {
      await client.query('ROLLBACK');
      res.status(400).json({
        code: 'INCOMPLETE_SESSION',
        message: 'Complete all required fields first',
      });
      return;
    }

    // 3. Validate all 4 required draft fields are present
    if (
      session.display_name_draft === null ||
      session.legal_name_draft === null ||
      session.region_draft === null ||
      session.home_address_draft === null
    ) {
      await client.query('ROLLBACK');
      res.status(400).json({
        code: 'MISSING_REQUIRED_FIELDS',
        message: 'All required fields must be completed',
      });
      return;
    }

    // 4. Idempotency check — prevent duplicate connected_profiles creation
    const { rows: existingConnected } = await client.query<{ id: string }>(
      'SELECT id FROM connect.connected_profiles WHERE user_id = $1',
      [userId]
    );
    if (existingConnected.length > 0) {
      await client.query('ROLLBACK');
      res.status(409).json({
        code: 'ALREADY_CONNECTED',
        message: 'You already have a Connected profile',
      });
      return;
    }

    // 5. Create the connected_profiles record
    await client.query(
      `INSERT INTO connect.connected_profiles
         (user_id, display_name, legal_name, home_address, account_standing, verification_status, tolerance_rating, verified_region)
       VALUES ($1, $2, $3, $4, 'active', 'verified', 10.00, $5)`,
      [
        userId,
        session.display_name_draft,
        session.legal_name_draft,
        session.home_address_draft,
        session.region_draft,
      ]
    );

    // 6. Advance verification_session to 'complete'
    await client.query(
      `UPDATE connect.verification_sessions
          SET step_reached = 'complete', updated_at = now()
        WHERE user_id = $1`,
      [userId]
    );

    // 7. Sync display_name to public.users
    await client.query(
      `UPDATE public.users
          SET display_name = $1, updated_at = now()
        WHERE id = $2`,
      [session.display_name_draft, userId]
    );

    await client.query('COMMIT');

    // Response: whitelist only — tolerance_rating and legal_name intentionally omitted
    res.status(201).json({
      connected: true,
      verification_status: 'verified',
      tier: 'connected',
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[connect/complete] Unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  } finally {
    client.release();
  }
});

// ---------------------------------------------------------------------------
// GET /api/connect/status
// ---------------------------------------------------------------------------

/**
 * Check the user's current verification stage.
 *
 * Returns one of:
 * - { status: 'not_started' }                                  — no session, no profile
 * - { status: 'in_progress', step_reached: 'profile'|... }     — session active
 * - { status: 'verified' | 'pending' | 'suspended' }           — connected_profiles exists
 */
router.get('/status', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const { userId } = req as AuthenticatedRequest;
  const client = await pool.connect();

  try {
    // Check connected_profiles first
    const { rows: connectedRows } = await client.query<{ verification_status: string }>(
      'SELECT verification_status FROM connect.connected_profiles WHERE user_id = $1',
      [userId]
    );

    if (connectedRows.length > 0) {
      res.status(200).json({ status: connectedRows[0]!.verification_status });
      return;
    }

    // Check for active verification_session
    const { rows: sessionRows } = await client.query<{ step_reached: string }>(
      'SELECT step_reached FROM connect.verification_sessions WHERE user_id = $1',
      [userId]
    );

    if (sessionRows.length > 0) {
      res.status(200).json({
        status: 'in_progress',
        step_reached: sessionRows[0]!.step_reached,
      });
      return;
    }

    res.status(200).json({ status: 'not_started' });
  } catch (err) {
    console.error('[connect/status] Unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  } finally {
    client.release();
  }
});

// ---------------------------------------------------------------------------
// POST /api/connect/compass-import
// ---------------------------------------------------------------------------

/**
 * Two-phase compass calibration import.
 *
 * Phase 1 (confirmed: false) — Validation:
 *   Compare each calibration's topic_version against live server versions.
 *   Returns { valid, mismatched, ready_to_import } so the client can prompt
 *   the user to re-take any mismatched topics before confirming.
 *
 * Phase 2 (confirmed: true) — Save:
 *   Store calibrations JSON in verification_sessions.compass_import_draft.
 *   The actual write to inform.compass_responses is deferred to Phase 4
 *   (Compass Routes) — this plan stores the draft only.
 */
router.post('/compass-import', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const { userId } = req as AuthenticatedRequest;

  const parsed = compassImportBodySchema.safeParse(req.body);
  if (!parsed.success) {
    const firstIssue = parsed.error.issues[0];
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: firstIssue?.message ?? 'Invalid request body',
    });
    return;
  }

  const { calibrations, confirmed } = parsed.data;
  const client = await pool.connect();

  try {
    // 1. Require an active verification session
    const { rows: sessionRows } = await client.query<{ id: string }>(
      'SELECT id FROM connect.verification_sessions WHERE user_id = $1',
      [userId]
    );

    if (sessionRows.length === 0) {
      res.status(404).json({ code: 'NO_SESSION', message: 'No active verification session' });
      return;
    }

    if (!confirmed) {
      // Phase 1: Validate topic versions against live server versions
      const { rows: liveTopics } = await client.query<{ id: string; version: number }>(
        'SELECT id, version FROM inform.compass_topics WHERE is_active = true'
      );

      const liveVersionMap = new Map<string, number>();
      for (const topic of liveTopics) {
        liveVersionMap.set(topic.id, topic.version);
      }

      const valid: typeof calibrations = [];
      const mismatched: Array<{
        topic_id: string;
        client_version: number;
        server_version: number | null;
      }> = [];

      for (const cal of calibrations) {
        const serverVersion = liveVersionMap.get(cal.topic_id) ?? null;
        if (serverVersion === null || cal.topic_version !== serverVersion) {
          mismatched.push({
            topic_id: cal.topic_id,
            client_version: cal.topic_version,
            server_version: serverVersion,
          });
        } else {
          valid.push(cal);
        }
      }

      res.status(200).json({
        valid,
        mismatched,
        ready_to_import: mismatched.length === 0,
      });
      return;
    }

    // Phase 2: Save calibrations as draft in verification_sessions
    await client.query(
      `UPDATE connect.verification_sessions
          SET compass_import_draft = $1, updated_at = now()
        WHERE user_id = $2`,
      [JSON.stringify(calibrations), userId]
    );

    res.status(200).json({ imported: true, count: calibrations.length });
  } catch (err) {
    console.error('[connect/compass-import] Unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  } finally {
    client.release();
  }
});

export default router;
