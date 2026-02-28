import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin, adminRpc } from '../lib/supabase.js';
import { claimInviteCode } from '../lib/inviteService.js';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import type { Request, Response } from 'express';

/**
 * Connect flow routes — the single enrollment pipeline from Inform to Connected tier.
 *
 * Step state machine: invite -> profile -> review -> complete
 *
 * All DB writes use supabaseAdmin (HTTP/REST via PostgREST + RPC).
 * Transactional operations (complete flow) are delegated to SECURITY DEFINER
 * RPC functions.
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

  try {
    // 1. Check if user is already Connected
    const { data: connectedProfile, error: cpError } = await supabaseAdmin
      .schema('connect')
      .from('connected_profiles')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();

    if (cpError) throw cpError;

    if (connectedProfile) {
      res.status(409).json({
        code: 'ALREADY_CONNECTED',
        message: 'You already have a Connected profile',
      });
      return;
    }

    // 2. Check for an existing session
    const { data: existingSession, error: sessionError } = await supabaseAdmin
      .schema('connect')
      .from('verification_sessions')
      .select('id,step_reached,display_name_draft,legal_name_draft,region_draft,home_address_draft,invite_code_id')
      .eq('user_id', userId)
      .maybeSingle();

    if (sessionError) throw sessionError;

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
    const { data: upsertedSession, error: upsertError } = await supabaseAdmin
      .schema('connect')
      .from('verification_sessions')
      .upsert(
        {
          user_id: userId,
          step_reached: 'profile',
          invite_code_id: claimResult.codeId,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id' }
      )
      .select('id,step_reached,display_name_draft,legal_name_draft,region_draft,home_address_draft')
      .single();

    if (upsertError) throw upsertError;

    res.status(200).json({
      session_id: upsertedSession.id,
      step_reached: upsertedSession.step_reached,
      drafts: {
        display_name_draft: upsertedSession.display_name_draft,
        legal_name_draft: upsertedSession.legal_name_draft,
        region_draft: upsertedSession.region_draft,
        home_address_draft: upsertedSession.home_address_draft,
      },
    });
  } catch (err) {
    console.error('[connect/start] Unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
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

  try {
    // 1. Fetch current session
    const { data: session, error: sessionError } = await supabaseAdmin
      .schema('connect')
      .from('verification_sessions')
      .select('id,step_reached,display_name_draft,legal_name_draft,region_draft,home_address_draft')
      .eq('user_id', userId)
      .maybeSingle();

    if (sessionError) throw sessionError;

    if (!session) {
      res.status(404).json({ code: 'NO_SESSION', message: 'No active verification session' });
      return;
    }

    if (session.step_reached === 'complete') {
      res.status(409).json({
        code: 'ALREADY_COMPLETE',
        message: 'Your Connect flow is already complete',
      });
      return;
    }

    // 2. Compute merged values to determine if we can advance to 'review'
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

    // 3. Execute the UPDATE
    const { data: updated, error: updateError } = await supabaseAdmin
      .schema('connect')
      .from('verification_sessions')
      .update({
        display_name_draft: newDisplayName ?? null,
        legal_name_draft: newLegalName ?? null,
        region_draft: newRegion ?? null,
        home_address_draft: newHomeAddress ?? null,
        step_reached: newStepReached,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId)
      .select('id,step_reached,display_name_draft,legal_name_draft,region_draft,home_address_draft')
      .single();

    if (updateError) throw updateError;

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
  }
});

// ---------------------------------------------------------------------------
// POST /api/connect/complete
// ---------------------------------------------------------------------------

/**
 * Finalize the Connect flow and atomically create a connected_profiles record.
 *
 * Delegates to the complete_connect_flow SECURITY DEFINER RPC which handles:
 * - FOR UPDATE lock on verification_session
 * - Validation of step and required fields
 * - Idempotency check for existing connected_profiles
 * - Atomic INSERT of connected_profiles
 * - Advance session to 'complete'
 * - Sync display_name to public.users
 *
 * Response intentionally omits tolerance_rating and legal_name — privacy
 * enforcement at the serialization layer (not just RLS).
 */
router.post('/complete', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const { userId } = req as AuthenticatedRequest;

  try {
    const { data, error } = await adminRpc('complete_connect_flow', {
      p_user_id: userId,
    });

    if (error) {
      const msg = error.message;
      if (msg === 'NO_SESSION') {
        res.status(404).json({ code: 'NO_SESSION', message: 'No active verification session' });
        return;
      }
      if (msg === 'INCOMPLETE_SESSION') {
        res.status(400).json({
          code: 'INCOMPLETE_SESSION',
          message: 'Complete all required fields first',
        });
        return;
      }
      if (msg === 'MISSING_REQUIRED_FIELDS') {
        res.status(400).json({
          code: 'MISSING_REQUIRED_FIELDS',
          message: 'All required fields must be completed',
        });
        return;
      }
      if (msg === 'ALREADY_CONNECTED') {
        res.status(409).json({
          code: 'ALREADY_CONNECTED',
          message: 'You already have a Connected profile',
        });
        return;
      }
      throw new Error(msg);
    }

    const result = (data ?? {}) as { connected: boolean; verification_status: string; tier: string };
    res.status(201).json(result);
  } catch (err) {
    console.error('[connect/complete] Unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
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

  try {
    // Check connected_profiles first
    const { data: connectedProfile, error: cpError } = await supabaseAdmin
      .schema('connect')
      .from('connected_profiles')
      .select('verification_status')
      .eq('user_id', userId)
      .maybeSingle();

    if (cpError) throw cpError;

    if (connectedProfile) {
      res.status(200).json({ status: connectedProfile.verification_status });
      return;
    }

    // Check for active verification_session
    const { data: session, error: sessionError } = await supabaseAdmin
      .schema('connect')
      .from('verification_sessions')
      .select('step_reached')
      .eq('user_id', userId)
      .maybeSingle();

    if (sessionError) throw sessionError;

    if (session) {
      res.status(200).json({
        status: 'in_progress',
        step_reached: session.step_reached,
      });
      return;
    }

    res.status(200).json({ status: 'not_started' });
  } catch (err) {
    console.error('[connect/status] Unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
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

  try {
    // 1. Require an active verification session
    const { data: session, error: sessionError } = await supabaseAdmin
      .schema('connect')
      .from('verification_sessions')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();

    if (sessionError) throw sessionError;

    if (!session) {
      res.status(404).json({ code: 'NO_SESSION', message: 'No active verification session' });
      return;
    }

    if (!confirmed) {
      // Phase 1: Validate topic versions against live server versions
      const { data: liveTopics, error: topicsError } = await supabaseAdmin
        .schema('inform')
        .from('compass_topics')
        .select('id,version')
        .eq('is_live', true);

      if (topicsError) throw topicsError;

      const liveVersionMap = new Map<string, number>();
      for (const topic of liveTopics ?? []) {
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
    const { error: updateError } = await supabaseAdmin
      .schema('connect')
      .from('verification_sessions')
      .update({
        compass_import_draft: JSON.stringify(calibrations),
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId);

    if (updateError) throw updateError;

    res.status(200).json({ imported: true, count: calibrations.length });
  } catch (err) {
    console.error('[connect/compass-import] Unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
