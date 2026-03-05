import { Router, Response } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireVerified } from '../middleware/requireVerified.js';
import { requireConnected } from '../middleware/tierGuards.js';
import { createUserClient, adminRpc } from '../lib/supabase.js';

// All DB reads use createUserClient(req.accessToken) — RLS enforced.
// Architecture rule: service role key must never be used in route handlers.

const router = Router();

// ---------------------------------------------------------------------------
// GET /api/account/me
// Middleware: requireAuth only — reads are allowed for all authenticated users.
// Returns tier-appropriate profile. tolerance_rating is nested in
// connected_profile (not at root) — structural privacy enforcement.
// ---------------------------------------------------------------------------
router.get('/me', requireAuth, async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;

  try {
    const db = createUserClient(authReq.accessToken);

    // 1. Fetch email from Supabase Auth (source of truth for auth data)
    const {
      data: { user: authUser },
      error: authError,
    } = await db.auth.getUser();

    if (authError || !authUser) {
      res.status(401).json({
        code: 'AUTH_ERROR',
        message: 'Unable to verify identity',
      });
      return;
    }

    // 2. Fetch public.users record — base profile fields
    const { data: user, error: userError } = await db
      .from('users')
      .select('id, display_name, avatar_url, created_at, updated_at')
      .eq('id', authReq.userId)
      .single();

    if (userError || !user) {
      res.status(404).json({
        code: 'USER_NOT_FOUND',
        message: 'User record not found',
      });
      return;
    }

    // 3. Check Connected tier (child record presence — never a status flag)
    // NOTE: total_xp is the Phase 9 column; xp is the legacy column preserved through Phase 10.
    // We select xp (still in generated types) and use it as the total for calculate_level.
    const { data: connected } = await db
      .schema('connect')
      .from('connected_profiles')
      .select(
        'id, display_name, account_standing, verification_status, tolerance_rating, xp, gem_balance, completed_onboarding, created_at'
      )
      .eq('user_id', authReq.userId)
      .maybeSingle();

    // 4. Check Empowered tier (child record presence)
    const { data: empowered } = await db
      .schema('empower')
      .from('empowered_profiles')
      .select('id, legal_name, is_active, candidate_page_slug, empowered_at, demoted_at')
      .eq('user_id', authReq.userId)
      .maybeSingle();

    // 5. Determine tier from child record presence.
    // Demoted users have an empowered_profiles row with is_active = false —
    // they fall through to 'connected' tier. empowerment_status provides
    // the active/demoted distinction for the caller.
    const tier = (empowered && empowered.is_active) ? 'empowered' : connected ? 'connected' : 'inform';

    // 5a. Compute structured XP data for Connected users.
    // Uses the legacy xp column (total) + calculate_level RPC for level breakdown.
    // calculate_level is IMMUTABLE — safe to call via adminRpc.
    let xpData: { total: number; level: number; xp_in_level: number; xp_to_next_level: number } | undefined;
    if (connected) {
      const totalXp = connected.xp ?? 0;
      const { data: levelData } = await adminRpc('calculate_level', {
        p_total_xp: totalXp,
      });
      // calculate_level RETURNS TABLE — data is always an array
      const levelRow = Array.isArray(levelData) ? levelData[0] : levelData;
      xpData = {
        total: totalXp,
        level: levelRow?.current_level ?? 0,
        xp_in_level: levelRow?.xp_in_level ?? 0,
        xp_to_next_level: levelRow?.xp_to_next_level ?? 0,
      };
    }

    // 6. Build response from explicit whitelist — NEVER spread DB rows.
    // This is the canonical privacy enforcement pattern for this codebase.
    // empowerment_status: only included when an empowered_profiles row exists.
    //   'empowered' = active Empowered candidate
    //   'demoted'   = previously Empowered, now demoted back to Connected tier
    const empowerment_status = empowered
      ? (empowered.is_active ? 'empowered' : 'demoted')
      : undefined;

    const meResponse: Record<string, unknown> = {
      id: user.id,
      email: authUser.email,
      display_name: user.display_name,
      avatar_url: user.avatar_url,
      tier,
      ...(empowerment_status !== undefined && { empowerment_status }),
      account_standing: connected?.account_standing ?? 'active',
      created_at: user.created_at,
      updated_at: user.updated_at,
    };

    // Connected-tier fields: tolerance_rating is nested here (owner self-view only).
    // tolerance_rating is NEVER at root level — structural enforcement beyond RLS.
    // xp is a structured object (total, level, xp_in_level, xp_to_next_level) replacing
    // the legacy xp integer.
    if (connected) {
      meResponse.connected_profile = {
        display_name: connected.display_name,
        verification_status: connected.verification_status,
        tolerance_rating: connected.tolerance_rating,
        xp: xpData,
        gem_balance: connected.gem_balance,
        completed_onboarding: connected.completed_onboarding,
        created_at: connected.created_at,
      };
    }

    // Empowered-tier fields: legal_name is nested here (owner self-view only).
    // legal_name is NEVER at root level — structural enforcement beyond RLS.
    if (empowered) {
      meResponse.empowered_profile = {
        legal_name: empowered.legal_name,
        is_active: empowered.is_active,
        candidate_page_slug: empowered.candidate_page_slug,
        empowered_at: empowered.empowered_at,
        demoted_at: empowered.demoted_at,
      };
    }

    res.status(200).json(meResponse);
  } catch (err) {
    console.error('[GET /api/account/me] unexpected error:', err);
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    });
  }
});

// ---------------------------------------------------------------------------
// PATCH /api/account/me
// Middleware chain: requireAuth → requireVerified → requireConnected
//   requireAuth:      Validates JWT, sets req.userId and req.accessToken
//   requireVerified:  Blocks unverified-email users (read-only access decision)
//   requireConnected: Blocks Inform-tier users (AUTH-05: Connected+ only)
//
// Updates display_name and/or avatar_url. Unknown fields are stripped silently
// (Zod default .object() strips unknowns — do NOT use .strict()).
// Returns 200 with full updated profile (same shape as GET /me).
// ---------------------------------------------------------------------------

const PatchMeSchema = z.object({
  display_name: z.string().min(1).max(100).optional(),
  avatar_url: z.string().url().max(500).optional(),
});
// Note: No .strict() — Zod .object() strips unknown keys by default.
// This silently ignores non-editable fields (e.g., tolerance_rating) if sent.

router.patch(
  '/me',
  requireAuth,
  requireVerified,
  requireConnected,
  async (req, res: Response) => {
    const authReq = req as AuthenticatedRequest;

    try {
      // 1. Validate and strip body
      const result = PatchMeSchema.safeParse(req.body);

      if (!result.success) {
        const firstIssue = result.error.issues[0]?.message ?? 'Validation error';
        res.status(422).json({
          code: 'VALIDATION_ERROR',
          message: firstIssue,
        });
        return;
      }

      // 2. Require at least one valid field
      const hasFields =
        result.data.display_name !== undefined || result.data.avatar_url !== undefined;

      if (!hasFields) {
        res.status(422).json({
          code: 'VALIDATION_ERROR',
          message: 'No valid fields to update',
        });
        return;
      }

      const db = createUserClient(authReq.accessToken);
      const now = new Date().toISOString();

      // 3. Build update payload for public.users
      const updateFields: Record<string, unknown> = {};
      if (result.data.display_name !== undefined) {
        updateFields.display_name = result.data.display_name;
      }
      if (result.data.avatar_url !== undefined) {
        updateFields.avatar_url = result.data.avatar_url;
      }

      updateFields.updated_at = now;

      const { error: updateError } = await db
        .from('users')
        .update(updateFields)
        .eq('id', authReq.userId);

      if (updateError) {
        console.error('[PATCH /api/account/me] users update failed:', updateError);
        res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to update profile' });
        return;
      }

      // 4. Sync display_name to connected_profiles (non-fatal if it fails)
      // Both tables store display_name independently; Phase 2 keeps them in sync.
      // Future: Replace with an atomic RPC function when divergence is intentional.
      if (result.data.display_name !== undefined) {
        const { error: connectedError } = await db
          .schema('connect')
          .from('connected_profiles')
          .update({
            display_name: result.data.display_name,
            updated_at: now,
          })
          .eq('user_id', authReq.userId);

        if (connectedError) {
          console.error(
            '[PATCH /api/account/me] connected_profiles update failed:',
            connectedError
          );
          // Non-fatal: public.users was already updated. Log but continue.
        }
      }

      // 5. Re-fetch updated records to build authoritative response
      const { data: updatedUser, error: fetchError } = await db
        .from('users')
        .select('id, display_name, avatar_url, created_at, updated_at')
        .eq('id', authReq.userId)
        .single();

      if (fetchError || !updatedUser) {
        res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch updated profile' });
        return;
      }

      const { data: authUserData } = await db.auth.getUser();
      const { data: updatedConnected } = await db
        .schema('connect')
        .from('connected_profiles')
        .select(
          'id, display_name, account_standing, verification_status, tolerance_rating, xp, gem_balance, completed_onboarding, created_at'
        )
        .eq('user_id', authReq.userId)
        .maybeSingle();

      const { data: updatedEmpowered } = await db
        .schema('empower')
        .from('empowered_profiles')
        .select('id, legal_name, is_active, candidate_page_slug, empowered_at, demoted_at')
        .eq('user_id', authReq.userId)
        .maybeSingle();

      // Demoted users (is_active = false) fall through to 'connected' tier.
      // empowerment_status provides the active/demoted distinction for the caller.
      const tier = (updatedEmpowered && updatedEmpowered.is_active) ? 'empowered' : updatedConnected ? 'connected' : 'inform';

      // Compute structured XP data for Connected users (same as GET /me)
      let xpData: { total: number; level: number; xp_in_level: number; xp_to_next_level: number } | undefined;
      if (updatedConnected) {
        const totalXp = updatedConnected.xp ?? 0;
        const { data: levelData } = await adminRpc('calculate_level', {
          p_total_xp: totalXp,
        });
        const levelRow = Array.isArray(levelData) ? levelData[0] : levelData;
        xpData = {
          total: totalXp,
          level: levelRow?.current_level ?? 0,
          xp_in_level: levelRow?.xp_in_level ?? 0,
          xp_to_next_level: levelRow?.xp_to_next_level ?? 0,
        };
      }

      // 6. Build response from explicit whitelist (same pattern as GET /me)
      const updatedEmpowermentStatus = updatedEmpowered
        ? (updatedEmpowered.is_active ? 'empowered' : 'demoted')
        : undefined;

      const meResponse: Record<string, unknown> = {
        id: updatedUser.id,
        email: authUserData?.user?.email,
        display_name: updatedUser.display_name,
        avatar_url: updatedUser.avatar_url,
        tier,
        ...(updatedEmpowermentStatus !== undefined && { empowerment_status: updatedEmpowermentStatus }),
        account_standing: updatedConnected?.account_standing ?? 'active',
        created_at: updatedUser.created_at,
        updated_at: updatedUser.updated_at,
      };

      if (updatedConnected) {
        meResponse.connected_profile = {
          display_name: updatedConnected.display_name,
          verification_status: updatedConnected.verification_status,
          tolerance_rating: updatedConnected.tolerance_rating,
          xp: xpData,
          gem_balance: updatedConnected.gem_balance,
          completed_onboarding: updatedConnected.completed_onboarding,
          created_at: updatedConnected.created_at,
        };
      }

      if (updatedEmpowered) {
        meResponse.empowered_profile = {
          legal_name: updatedEmpowered.legal_name,
          is_active: updatedEmpowered.is_active,
          candidate_page_slug: updatedEmpowered.candidate_page_slug,
          empowered_at: updatedEmpowered.empowered_at,
          demoted_at: updatedEmpowered.demoted_at,
        };
      }

      res.status(200).json(meResponse);
    } catch (err) {
      console.error('[PATCH /api/account/me] unexpected error:', err);
      res.status(500).json({
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred',
      });
    }
  }
);

export default router;
