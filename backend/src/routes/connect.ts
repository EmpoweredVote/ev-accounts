import { Router } from 'express';
import { z } from 'zod';
import { adminRpc } from '../lib/supabase.js';
import { claimInviteCode } from '../lib/inviteService.js';
import {
  hasConnectedProfile,
  getConnectedProfileVerificationStatus,
  getVerificationSession,
  getVerificationSessionStep,
  getVerificationSessionId,
  upsertVerificationSession,
  updateVerificationSession,
  validateCompassVersions,
  saveCompassImportDraft,
  importCompassCalibrations,
  getLocationConsent,
  type CalibrationItem,
} from '../lib/connectService.js';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { requireConnected } from '../middleware/tierGuards.js';
import { geocodeAddress, GeocodingError } from '../lib/geocodingService.js';
import { pool } from '../lib/db.js';
import { resolvedDistrictCount } from '../lib/jurisdictionPayload.js';
import { isVaultEnabled, upsertSeal } from '../lib/idVault.js';
import type { Request, Response } from 'express';

/**
 * Connect flow routes — the single enrollment pipeline from Inform to Connected tier.
 *
 * Step state machine: invite -> profile -> review -> complete
 *
 * DB operations are delegated to connectService (createUserClient, RLS-enforced).
 * Transactional operations (complete flow) are delegated to SECURITY DEFINER RPC.
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

const setLocationBodySchema = z.object({
  address: z.string().min(1).max(500),
  force: z.boolean().optional().default(false),
});

const compassImportBodySchema = z.object({
  calibrations: z.array(
    z.object({
      topic_id: z.string().uuid(),
      topic_version: z.number().int().positive(),
      stance_id: z.string().uuid().optional(),
      value: z.number().int().min(1).max(5).optional(),
      inverted: z.boolean().optional().default(false),
    })
  ),
  selected_topics: z.array(z.string().uuid()).min(0).max(8).optional(),
  confirmed: z.boolean().optional().default(false),
  user_id: z.string().uuid().optional(),
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Seal the raw street address into the vault when enabled. Coords stay under
 *  the existing single key (spec D5); this only adds the sealed raw address. */
export async function sealAddressIfEnabled(userId: string, rawAddress: string): Promise<void> {
  if (isVaultEnabled()) {
    await upsertSeal(userId, { address: rawAddress });
  }
}

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
  const parsed = startBodySchema.safeParse(req.body);
  if (!parsed.success) {
    const firstIssue = parsed.error.issues[0];
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: firstIssue?.message ?? 'Invalid request body',
    });
    return;
  }

  const { userId, accessToken } = req as AuthenticatedRequest;

  try {
    // 1. Check if user is already Connected
    if (await hasConnectedProfile(accessToken, userId)) {
      res.status(409).json({ code: 'ALREADY_CONNECTED', message: 'You already have a Connected profile' });
      return;
    }

    // 2. Check for an existing session — resume if beyond 'invite' step
    const existingSession = await getVerificationSession(accessToken, userId);
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
    const upsertedSession = await upsertVerificationSession(accessToken, userId, claimResult.codeId);

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
  const { userId, accessToken } = req as AuthenticatedRequest;

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
    const session = await getVerificationSession(accessToken, userId);

    if (!session) {
      res.status(404).json({ code: 'NO_SESSION', message: 'No active verification session' });
      return;
    }

    if (session.step_reached === 'complete') {
      res.status(409).json({ code: 'ALREADY_COMPLETE', message: 'Your Connect flow is already complete' });
      return;
    }

    // 2. Merge incoming values with current drafts
    const newDisplayName = display_name !== undefined ? display_name : session.display_name_draft;
    const newLegalName = legal_name !== undefined ? legal_name : session.legal_name_draft;
    const newRegion = location !== undefined ? location : session.region_draft;
    const newHomeAddress = home_address !== undefined ? home_address : session.home_address_draft;

    const allRequiredPresent =
      newDisplayName != null && newLegalName != null && newRegion != null && newHomeAddress != null;

    const newStepReached = step === 'review' && allRequiredPresent ? 'review' : 'profile';

    // 3. Execute the UPDATE
    const updated = await updateVerificationSession(accessToken, userId, {
      display_name_draft: newDisplayName ?? null,
      legal_name_draft: newLegalName ?? null,
      region_draft: newRegion ?? null,
      home_address_draft: newHomeAddress ?? null,
      step_reached: newStepReached,
    });

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
  const { userId, accessToken } = req as AuthenticatedRequest;

  try {
    const verificationStatus = await getConnectedProfileVerificationStatus(accessToken, userId);
    if (verificationStatus !== null) {
      res.status(200).json({ status: verificationStatus });
      return;
    }

    const stepReached = await getVerificationSessionStep(accessToken, userId);
    if (stepReached !== null) {
      res.status(200).json({ status: 'in_progress', step_reached: stepReached });
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
 * Phase 2 (confirmed: true) — Write:
 *   Direct import path: calibrations include numeric value fields.
 *     Calls importCompassCalibrations RPC. Optionally commits selected_topics
 *     and marks onboarding complete when 3–8 topic IDs are provided.
 *   Legacy path: calibrations have stance_id only (no value field).
 *     Requires active verification session. Saves draft for lazy promotion.
 *
 * Admin path: if user_id is provided in the body, requireAdmin is enforced
 * and the import is performed on behalf of the specified user.
 */
router.post('/compass-import', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const { userId, accessToken } = req as AuthenticatedRequest;

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
    if (!confirmed) {
      // Phase 1: Validate topic versions against live server versions
      // Only validate calibrations that have topic_version (legacy path)
      const legacyCals = calibrations.filter(c => c.stance_id !== undefined) as CalibrationItem[];
      const result = await validateCompassVersions(legacyCals);
      res.status(200).json(result);
      return;
    }

    // Phase 2: confirmed = true
    // Admin path: if user_id provided in body, check admin permission
    if (parsed.data.user_id) {
      await new Promise<void>((resolve, reject) => {
        requireAdmin(req, res, (err?: unknown) => {
          if (err) reject(err); else resolve();
        });
      }).catch(() => {});
      if (res.headersSent) return;
    }

    const targetUserId = parsed.data.user_id ?? userId;
    const calibrationsWithValue = calibrations.filter(c => c.value !== undefined);

    if (calibrationsWithValue.length > 0) {
      // New direct import path — calibrations include numeric values
      const importItems = calibrationsWithValue.map(c => ({
        topic_id: c.topic_id,
        value: c.value!,
        inverted: c.inverted ?? false,
      }));

      try {
        const result = await importCompassCalibrations({
          userId: targetUserId,
          accessToken,
          calibrations: importItems,
          selectedTopics: parsed.data.selected_topics,
        });
        res.status(200).json({
          imported: true,
          count: result.imported,
          onboarding_complete: result.onboarding_complete,
        });
      } catch (importErr: unknown) {
        const e = importErr as { code?: string; message?: string; invalid_ids?: string[] };
        if (e.code === 'INVALID_CALIBRATION') {
          res.status(400).json({
            code: 'INVALID_CALIBRATION',
            message: 'One or more calibrations failed validation — nothing was saved',
          });
          return;
        }
        if (e.code === 'INVALID_TOPIC_IDS') {
          res.status(422).json({
            code: 'INVALID_TOPIC_IDS',
            message: 'Invalid selected topic IDs',
            invalid_ids: e.invalid_ids,
          });
          return;
        }
        // The selected topics could not be validated because no season is open.
        // A server-state problem, not a bad import — 503 so the caller knows to
        // retry rather than to go and fix their payload.
        //
        // ⚠ This gates only `selectedTopics`. The CALIBRATIONS themselves are
        // validated by validateCompassVersions, which reads the content view and
        // stays permissive on purpose: an imported calibration may legitimately
        // name a topic we no longer ask. Do not fold that one into the season.
        if (e.code === 'NO_PROMOTED_TOPICS') {
          res.status(503).json({
            code: 'NO_PROMOTED_TOPICS',
            message: 'Compass topics are unavailable right now — no season is open.',
          });
          return;
        }
        throw importErr;
      }
    } else {
      // Legacy path: save draft for lazy promotion
      // Require an active verification session for legacy path
      const sessionId = await getVerificationSessionId(accessToken, userId);
      if (!sessionId) {
        res.status(404).json({ code: 'NO_SESSION', message: 'No active verification session' });
        return;
      }
      const legacyCals = calibrations as CalibrationItem[];
      await saveCompassImportDraft(accessToken, userId, legacyCals);
      res.status(200).json({ imported: true, count: calibrations.length });
    }
  } catch (err) {
    console.error('[connect/compass-import] Unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/connect/set-location
// ---------------------------------------------------------------------------

router.post('/set-location', requireAuth, requireConnected, async (req: Request, res: Response): Promise<void> => {
  const { userId } = req as AuthenticatedRequest;

  const parsed = setLocationBodySchema.safeParse(req.body);
  if (!parsed.success) {
    const firstIssue = parsed.error.issues[0];
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: firstIssue?.message ?? 'Invalid request body',
    });
    return;
  }

  const { address, force } = parsed.data;

  // Guard: require explicit force:true to overwrite existing coordinates.
  // Prevents silent location corruption from automated clients (e.g. search auto-save).
  if (!force) {
    try {
      const { rows } = await pool.query<{ has_coords: boolean }>(
        `SELECT (encrypted_lat IS NOT NULL) AS has_coords
         FROM connect.connected_profiles WHERE user_id = $1`,
        [userId]
      );
      if (rows[0]?.has_coords) {
        res.status(409).json({
          code: 'LOCATION_ALREADY_SET',
          message: 'Location is already set. Pass force:true to overwrite.',
        });
        return;
      }
    } catch (err) {
      console.error('[connect/set-location] coords check error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      return;
    }
  }

  let lat: number;
  let lng: number;
  let state: string;
  let city: string;

  try {
    const coords = await geocodeAddress(address);
    lat = coords.lat;
    lng = coords.lng;
    state = coords.state;
    city = coords.city;
  } catch (err) {
    if (err instanceof GeocodingError) {
      if (err.code === 'PO_BOX_REJECTED') {
        res.status(422).json({ code: 'PO_BOX_REJECTED', message: err.message });
        return;
      }
      if (err.code === 'ADDRESS_NOT_FOUND') {
        res.status(422).json({ code: 'ADDRESS_NOT_FOUND', message: err.message });
        return;
      }
      if (err.code === 'GEOCODER_UNAVAILABLE') {
        res.status(503).json({ code: 'GEOCODER_UNAVAILABLE', message: 'Address lookup temporarily unavailable.' });
        return;
      }
      console.error('[connect/set-location] Geocoding error:', err.message);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      return;
    }
    throw err;
  }

  // Check before upsert — determines if this is the user's first-ever location set.
  const hadPriorLocation = await getLocationConsent(userId);

  try {
    const { error: upsertError } = await adminRpc('upsert_user_location', {
      p_user_id: userId,
      p_lat: lat,
      p_lng: lng,
    }, 'connect');

    if (upsertError) {
      console.error('[connect/set-location] upsert_user_location error:', upsertError.message);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      return;
    }

    // Seal the raw address (public key only — no ceremony). Non-fatal: a seal
    // failure must not block district resolution the site needs to place them.
    try {
      await sealAddressIfEnabled(userId, address);
    } catch (sealErr) {
      console.error('[connect/set-location] id_vault seal failed (non-fatal):', sealErr);
    }

    const { data: jurisdictionData, error: jurisdictionError } = await adminRpc('resolve_user_jurisdiction', {
      p_user_id: userId,
    }, 'connect');

    if (jurisdictionError) {
      // Non-fatal: address is outside covered districts — return nulls and continue.
      console.warn('[connect/set-location] resolve_user_jurisdiction returned no match:', jurisdictionError.message);
    }

    // Write jurisdiction GEO IDs + names + state + city to connected_profiles
    const jData = (jurisdictionData ?? {}) as Record<string, string | null>;

    // ⚠ WRITING NULLS HERE IS CORRECT, AND THAT IS WHY IT NEEDED A WARNING.
    // The address just CHANGED, so any stored districts belong to the old point and are
    // definitively wrong — keeping them would show this person the representatives for
    // where they used to live. So this write must proceed, nulls included. It is the
    // opposite case to districtStalenessService, where the point did not move and an
    // unresolved answer means "could not resolve" (see lib/jurisdictionPayload.ts).
    //
    // What was missing is any signal. resolve_user_jurisdiction aggregates with no GROUP BY,
    // so an unresolved point returns one all-NULL row and raises NO error — the branch above
    // never fires. A broken geo_id / mtfcc / district_type join therefore handed every new
    // user an empty jurisdiction, silently, and the response body looked like a valid answer.
    if (resolvedDistrictCount(jData) === 0) {
      console.warn(
        `[connect/set-location] UNRESOLVED — resolve_user_jurisdiction placed user ${userId} ` +
          `in no district at all for a geocoded address (${city}, ${state}). Writing the ` +
          `empty jurisdiction, because the previous one was for a different address. If this ` +
          `fires for addresses that should be covered, suspect the RPC's join, not the address.`
      );
    }
    try {
      await pool.query(
        `UPDATE connect.connected_profiles
         SET congressional_geo_id = $2,
             congressional_district_name = $3,
             state_senate_geo_id = $4,
             state_senate_district_name = $5,
             state_house_geo_id = $6,
             state_house_district_name = $7,
             county_geo_id = $8,
             county_name = $9,
             school_district_geo_id = $10,
             school_district_name = $11,
             jurisdiction_state = $12,
             jurisdiction_city = $13,
             city_council_geo_id = $14,
             city_council_district_name = $15,
             municipality_geo_id = $16,
             city_geo_id = $17,
             state_geo_id = $18,
             nation_geo_id = $19,
             updated_at = now()
         WHERE user_id = $1`,
        [
          userId,
          jData.congressional ?? null,
          jData.congressional_name ?? null,
          jData.state_senate ?? null,
          jData.state_senate_name ?? null,
          jData.state_house ?? null,
          jData.state_house_name ?? null,
          jData.county ?? null,
          jData.county_name ?? null,
          jData.school_district ?? null,
          jData.school_district_name ?? null,
          state,
          city,
          jData.city_council ?? null,
          jData.city_council_name ?? null,
          jData.municipality ?? null,
          // Place geoids. NOT the same as jurisdiction_state / jurisdiction_city above:
          // those are the geocoder's USPS code and place NAME ('NC', 'ASHEVILLE'), these
          // are Census FIPS ('37', '3702140'). Civic Spaces keys a slice on the geoid;
          // it cannot key one on a name.
          jData.city ?? null,
          jData.state ?? null,
          jData.nation ?? null,
        ]
      );
    } catch (e) {
      console.error('[set-location] jurisdiction write error:', e);
    }

    // District cache (fail-open): never block location save on PostGIS error.
    // essentials.cache_user_districts is in the essentials schema, which is NOT in
    // PostgREST's exposed schema list — MUST use pool.query, not adminRpc.
    try {
      await pool.query(
        `SELECT essentials.cache_user_districts($1, $2, $3)`,
        [userId, lat, lng]
      );
    } catch (cacheErr) {
      console.error('[connect/set-location] district cache failed (non-fatal):', cacheErr);
    }

    const j = jData;

    res.status(200).json({
      location_consent: true,
      first_location: !hadPriorLocation,
      jurisdiction: {
        congressional_district: j.congressional ?? null,
        congressional_district_name: j.congressional_name ?? null,
        state_senate_district: j.state_senate ?? null,
        state_senate_district_name: j.state_senate_name ?? null,
        state_house_district: j.state_house ?? null,
        state_house_district_name: j.state_house_name ?? null,
        county: j.county ?? null,
        county_name: j.county_name ?? null,
        school_district: j.school_district ?? null,
        school_district_name: j.school_district_name ?? null,
        state: state,
        city: city,
        city_council_district: j.city_council ?? null,
        city_council_district_name: j.city_council_name ?? null,
      },
    });
  } catch (err) {
    console.error('[connect/set-location] Unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
