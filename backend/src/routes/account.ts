import { Router, Response } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireVerified } from '../middleware/requireVerified.js';
import { requireConnected, requireInform } from '../middleware/tierGuards.js';
import { requestDb, adminRpc } from '../lib/supabase.js';
import { getRequestAuthUser } from '../lib/authService.js';
import { pool } from '../lib/db.js';
import { geocodeAddress, GeocodingError } from '../lib/geocodingService.js';
import { getLocationConsent } from '../lib/connectService.js';
import { isUserAdmin } from '../lib/adminService.js';
import { getAccountMe } from '../lib/accountMeService.js';

// All DB reads use requestDb(req.accessToken) — RLS enforced for Supabase
// sessions; service-role + explicit userId scoping for WorkOS sessions during
// the decision-0002 transition (see lib/supabase.ts requestDb).
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
    // The whole /me composite lives in getAccountMe so the folded VQ code can build the
    // identical object in-process (see lib/accountMeService.ts). Same reads, same shape.
    const meResponse = await getAccountMe(authReq.accessToken, authReq.userId);
    res.status(200).json(meResponse);
  } catch (err) {
    const code = (err as { code?: string }).code;
    if (code === 'AUTH_ERROR') {
      res.status(401).json({ code: 'AUTH_ERROR', message: 'Unable to verify identity' });
      return;
    }
    if (code === 'USER_NOT_FOUND') {
      res.status(404).json({ code: 'USER_NOT_FOUND', message: 'User record not found' });
      return;
    }
    console.error('[GET /api/account/me] unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/account/me/jurisdiction
// Returns 403 if location_consent is false/null; returns jurisdiction JSON if true
// ---------------------------------------------------------------------------

router.get('/me/jurisdiction', requireAuth, requireConnected, async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;

  try {
    const hasConsent = await getLocationConsent(authReq.userId);

    if (!hasConsent) {
      res.status(403).json({
        code: 'LOCATION_CONSENT_REQUIRED',
        error: 'Location must be set before jurisdiction can be retrieved',
      });
      return;
    }

    // Read stored jurisdiction columns instead of calling RPC
    const { rows } = await pool.query<{
      congressional_geo_id: string | null;
      congressional_district_name: string | null;
      state_senate_geo_id: string | null;
      state_senate_district_name: string | null;
      state_house_geo_id: string | null;
      state_house_district_name: string | null;
      county_geo_id: string | null;
      county_name: string | null;
      school_district_geo_id: string | null;
      school_district_name: string | null;
      jurisdiction_state: string | null;
      jurisdiction_city: string | null;
      city_geo_id: string | null;
      state_geo_id: string | null;
      nation_geo_id: string | null;
      city_council_geo_id: string | null;
      city_council_district_name: string | null;
    }>(
      `SELECT congressional_geo_id, congressional_district_name,
              state_senate_geo_id, state_senate_district_name,
              state_house_geo_id, state_house_district_name,
              county_geo_id, county_name,
              school_district_geo_id, school_district_name,
              jurisdiction_state, jurisdiction_city,
              city_council_geo_id, city_council_district_name,
              city_geo_id, state_geo_id, nation_geo_id
       FROM connect.connected_profiles WHERE user_id = $1`,
      [authReq.userId]
    );
    const j = rows[0];

    res.status(200).json({
      jurisdiction: {
        congressional_district: j?.congressional_geo_id ?? null,
        congressional_district_name: j?.congressional_district_name ?? null,
        state_senate_district: j?.state_senate_geo_id ?? null,
        state_senate_district_name: j?.state_senate_district_name ?? null,
        state_house_district: j?.state_house_geo_id ?? null,
        state_house_district_name: j?.state_house_district_name ?? null,
        county: j?.county_geo_id ?? null,
        county_name: j?.county_name ?? null,
        school_district: j?.school_district_geo_id ?? null,
        school_district_name: j?.school_district_name ?? null,
        state: j?.jurisdiction_state ?? null,
        city: j?.jurisdiction_city ?? null,
        city_council_district: j?.city_council_geo_id ?? null,
        city_council_district_name: j?.city_council_district_name ?? null,
        // See the note on the same three keys in GET /me: geoids, not the geocoded
        // state code and city name that `state` and `city` already carry.
        state_geoid: j?.state_geo_id ?? null,
        city_geoid: j?.city_geo_id ?? null,
        nation_geoid: j?.nation_geo_id ?? null,
      },
    });
  } catch (err) {
    console.error('[GET /api/account/me/jurisdiction] Unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/account/me/activity
// Returns the last 20 XP transactions for the authenticated Connected user.
// Reads connect.xp_transactions directly via pool.query (PostgREST does not
// expose the connect schema). Inform-tier callers receive 403 from
// requireConnected before any DB work runs.
// ---------------------------------------------------------------------------
router.get('/me/activity', requireAuth, requireConnected, async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;

  try {
    const { rows } = await pool.query<{ source: string; amount: number; created_at: string }>(
      `SELECT source, amount, created_at
       FROM connect.xp_transactions
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 20`,
      [authReq.userId]
    );

    const activity = rows.map((row) => ({
      source: row.source,
      amount: row.amount,
      description: row.source,
      created_at: row.created_at,
    }));

    res.status(200).json({ activity });
  } catch (err) {
    console.error('[GET /api/account/me/activity] Unexpected error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
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

      const db = requestDb(authReq.accessToken);
      const now = new Date().toISOString();

      // 3. Build update payload for public.users
      // Typed concretely rather than as Record<string, unknown>: postgrest-js
      // guards .update() with RejectExcessProperties, which cannot prove an
      // open index signature has no excess columns.
      const updateFields: {
        display_name?: string;
        avatar_url?: string;
        updated_at?: string;
      } = {};
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
      if (result.data.display_name !== undefined) {
        await pool.query(
          `UPDATE connect.connected_profiles
           SET display_name = $2, updated_at = now()
           WHERE user_id = $1`,
          [authReq.userId, result.data.display_name]
        ).catch((err: unknown) => {
          console.error('[PATCH /api/account/me] connected_profiles sync failed:', err);
          // Non-fatal: public.users was already updated.
        });
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

      const { user: updatedAuthUser } = await getRequestAuthUser(authReq.accessToken, authReq.userId);
      const { data: updatedConnected } = await db
        .schema('connect')
        .from('connected_profiles')
        .select(
          'id, display_name, account_standing, verification_status, tolerance_rating, total_xp, gem_balance_yellow, gem_balance_blue, gem_balance_red, completed_onboarding, location_consent, verification_rating, vq_hold_until, created_at'
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

      // Check admin flag (same as GET /me — fails closed on error).
      const isAdmin = await isUserAdmin(authReq.userId);

      // Compute structured XP data for Connected users (same as GET /me)
      let xpData: { total: number; level: number; xp_in_level: number; xp_to_next_level: number } | undefined;
      if (updatedConnected) {
        const totalXp = updatedConnected.total_xp ?? 0;
        const { data: levelData } = await adminRpc('calculate_level', {
          p_total_xp: totalXp,
        }, 'connect');
        const levelRow = Array.isArray(levelData) ? levelData[0] : levelData;
        xpData = {
          total: totalXp,
          level: levelRow?.level ?? 0,
          xp_in_level: levelRow?.xp_in_level ?? 0,
          xp_to_next_level: levelRow?.xp_to_next_level ?? 0,
        };
      }

      // Read stored jurisdiction columns for Connected users with location_consent (same as GET /me).
      // Graceful degradation: if read fails, jurisdiction is null — do not fail /me.
      let updatedJurisdictionData: Record<string, unknown> | null = null;
      if (updatedConnected?.location_consent) {
        try {
          const { rows } = await pool.query<{
            congressional_geo_id: string | null;
            congressional_district_name: string | null;
            state_senate_geo_id: string | null;
            state_senate_district_name: string | null;
            state_house_geo_id: string | null;
            state_house_district_name: string | null;
            county_geo_id: string | null;
            county_name: string | null;
            school_district_geo_id: string | null;
            school_district_name: string | null;
            jurisdiction_state: string | null;
            jurisdiction_city: string | null;
            city_council_geo_id: string | null;
            city_council_district_name: string | null;
            city_geo_id: string | null;
            state_geo_id: string | null;
            nation_geo_id: string | null;
          }>(
            `SELECT congressional_geo_id, congressional_district_name,
                    state_senate_geo_id, state_senate_district_name,
                    state_house_geo_id, state_house_district_name,
                    county_geo_id, county_name,
                    school_district_geo_id, school_district_name,
                    jurisdiction_state, jurisdiction_city,
                    city_council_geo_id, city_council_district_name,
                    city_geo_id, state_geo_id, nation_geo_id
             FROM connect.connected_profiles WHERE user_id = $1`,
            [authReq.userId]
          );
          const j = rows[0];
          if (j && (j.congressional_geo_id || j.state_senate_geo_id)) {
            updatedJurisdictionData = {
              congressional_district: j.congressional_geo_id,
              congressional_district_name: j.congressional_district_name,
              state_senate_district: j.state_senate_geo_id,
              state_senate_district_name: j.state_senate_district_name,
              state_house_district: j.state_house_geo_id,
              state_house_district_name: j.state_house_district_name,
              county: j.county_geo_id,
              county_name: j.county_name,
              school_district: j.school_district_geo_id,
              school_district_name: j.school_district_name,
              state: j.jurisdiction_state,
              city: j.jurisdiction_city,
              city_council_district: j.city_council_geo_id,
              city_council_district_name: j.city_council_district_name,
              // Geoids, not the geocoded `state` / `city` pair above. See GET /me.
              state_geoid: j.state_geo_id,
              city_geoid: j.city_geo_id,
              nation_geoid: j.nation_geo_id,
            };
          }
        } catch (jErr) {
          console.error('[PATCH /api/account/me] jurisdiction read error:', jErr);
        }
      }

      // 6. Build response from explicit whitelist (same pattern as GET /me)
      const updatedEmpowermentStatus = updatedEmpowered
        ? (updatedEmpowered.is_active ? 'empowered' : 'demoted')
        : undefined;

      // Derived booleans for Verification Rating state (same as GET /me).
      const updatedVqHoldActive = updatedConnected?.vq_hold_until
        ? new Date(updatedConnected.vq_hold_until) > new Date()
        : false;
      const updatedRedGemQuestsUnlocked = (updatedConnected?.verification_rating ?? 60) >= 90;

      const meResponse: Record<string, unknown> = {
        id: updatedUser.id,
        email: updatedAuthUser?.email,
        display_name: updatedUser.display_name,
        avatar_url: updatedUser.avatar_url,
        tier,
        is_admin: isAdmin,
        completed_onboarding: updatedConnected?.completed_onboarding ?? false,
        location_consent: updatedConnected?.location_consent ?? false,
        verification_rating: updatedConnected?.verification_rating ?? 60,
        vq_hold_active: updatedVqHoldActive,
        red_gem_quests_unlocked: updatedRedGemQuestsUnlocked,
        ...(updatedEmpowermentStatus !== undefined && { empowerment_status: updatedEmpowermentStatus }),
        account_standing: updatedConnected?.account_standing ?? 'active',
        jurisdiction: updatedJurisdictionData,
        created_at: updatedUser.created_at,
        updated_at: updatedUser.updated_at,
      };

      // completed_onboarding is also present at root for CompassV2 compatibility.
      if (updatedConnected) {
        meResponse.connected_profile = {
          display_name: updatedConnected.display_name,
          verification_status: updatedConnected.verification_status,
          tolerance_rating: updatedConnected.tolerance_rating,
          xp: xpData,
          gems: {
            yellow: updatedConnected.gem_balance_yellow ?? 0,
            blue: updatedConnected.gem_balance_blue ?? 0,
            red: updatedConnected.gem_balance_red ?? 0,
          },
          completed_onboarding: updatedConnected.completed_onboarding,
          verification_rating: updatedConnected.verification_rating,
          vq_hold_active: updatedVqHoldActive,
          vq_hold_until: updatedConnected.vq_hold_until,
          created_at: updatedConnected.created_at,
        };
        meResponse.gems = {
          yellow: updatedConnected.gem_balance_yellow ?? 0,
          blue: updatedConnected.gem_balance_blue ?? 0,
          red: updatedConnected.gem_balance_red ?? 0,
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

// ---------------------------------------------------------------------------
// PATCH /api/account/location-hint
// Middleware: requireAuth + requireInform (Connected users → 403)
//
// Stores a location hint JSON in inform_profiles.last_essentials_location.
// Uses INSERT ON CONFLICT upsert — defensive against missing inform_profiles row.
// ---------------------------------------------------------------------------

const LocationHintBodySchema = z.object({
  location: z.unknown().refine((v) => v !== undefined && v !== null, {
    message: 'location is required',
  }),
});

router.patch('/location-hint', requireAuth, requireInform, async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;

  const parsed = LocationHintBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      error: 'VALIDATION_ERROR',
      issues: parsed.error.issues,
    });
    return;
  }

  const { location } = parsed.data;

  try {
    await pool.query(
      `INSERT INTO inform.inform_profiles (user_id, last_essentials_location)
       VALUES ($1, $2::jsonb)
       ON CONFLICT (user_id) DO UPDATE
         SET last_essentials_location = EXCLUDED.last_essentials_location`,
      [authReq.userId, JSON.stringify(location)]
    );

    // District cache (fail-open): extract lat/lng from opaque JSONB payload, then cache.
    // location is z.unknown() — Essentials frontend passes { lat, lng, ... } objects,
    // but the schema is not enforced. Defensive type narrowing.
    const loc = location as Record<string, unknown> | null;
    const hintLat = loc && typeof loc.lat === 'number' ? loc.lat : null;
    const hintLng = loc && typeof loc.lng === 'number' ? loc.lng : null;

    if (hintLat !== null && hintLng !== null) {
      try {
        await pool.query(
          `SELECT essentials.cache_user_districts($1, $2, $3)`,
          [authReq.userId, hintLat, hintLng]
        );
      } catch (cacheErr) {
        console.warn('[location-hint] district cache failed (non-fatal):', cacheErr);
      }
    } else {
      console.warn('[location-hint] no lat/lng in payload — skipping district cache');
    }

    res.status(200).json({ ok: true });
  } catch (err) {
    console.error('[PATCH /api/account/location-hint] error:', err);
    res.status(500).json({ error: 'INTERNAL_ERROR' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/account/districts
// Auth: requireAuth (both Inform and Connected tiers — Essentials is foundational)
//
// Returns the user's cached TIGER districts grouped by layer.
// Source of truth: connect.user_districts (populated by essentials.cache_user_districts).
// Joins to essentials.geo_districts on (layer, geoid) for the human-readable name.
// Returns 204 No Content when the user has no cached districts (no location set yet,
// or location resolved to zero matches — e.g. out-of-CA users).
// ---------------------------------------------------------------------------

router.get('/districts', requireAuth, async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;

  try {
    const { rows } = await pool.query<{
      layer: string;
      geoid: string;
      district_num: string;
      name: string | null;
    }>(
      `SELECT ud.layer, ud.geoid, ud.district_num, gd.name
       FROM connect.user_districts ud
       LEFT JOIN essentials.geo_districts gd
         ON gd.layer = ud.layer AND gd.geoid = ud.geoid
       WHERE ud.user_id = $1`,
      [authReq.userId]
    );

    if (rows.length === 0) {
      res.status(204).end();
      return;
    }

    const byLayer: Record<string, { district_number: string; name: string | null; tiger_geoid: string }> =
      Object.fromEntries(
        rows.map((r) => [
          r.layer,
          { district_number: r.district_num, name: r.name ?? null, tiger_geoid: r.geoid },
        ])
      );

    res.status(200).json({
      ca_assembly: byLayer['ca_assembly'] ?? null,
      ca_senate:   byLayer['ca_senate']   ?? null,
      us_house:    byLayer['us_house']    ?? null,
    });
  } catch (err) {
    console.error('[GET /api/account/districts] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/account/school-district
// Auth: requireAuth (both Inform and Connected tiers)
//
// Returns the user's cached school districts grouped by school layer.
// Source of truth: connect.user_districts filtered to layer IN
// (school_unified, school_elementary, school_secondary).
// Joins to essentials.geo_districts on (layer, geoid) for the human-readable
// name. Returns 204 No Content when the user has no school-layer rows
// (out-of-CA users, location not yet set, or coordinate didn't fall inside
// any school district polygon).
//
// Phase 71: separate from GET /districts because the legislative endpoint
// shape is intentionally stable (ca_assembly, ca_senate, us_house only).
// School district display is surfaced on the profile Location tab via this
// dedicated endpoint.
// ---------------------------------------------------------------------------

router.get('/school-district', requireAuth, async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;

  try {
    const { rows } = await pool.query<{
      layer: string;
      geoid: string;
      name: string | null;
    }>(
      `SELECT ud.layer, ud.geoid, gd.name
       FROM connect.user_districts ud
       LEFT JOIN essentials.geo_districts gd
         ON gd.layer = ud.layer AND gd.geoid = ud.geoid
       WHERE ud.user_id = $1
         AND ud.layer IN ('school_unified', 'school_elementary', 'school_secondary')`,
      [authReq.userId]
    );

    if (rows.length === 0) {
      res.status(204).end();
      return;
    }

    const byLayer: Record<string, { name: string | null; geoid: string }> =
      Object.fromEntries(
        rows.map((r) => [r.layer, { name: r.name ?? null, geoid: r.geoid }])
      );

    res.status(200).json({
      school_unified:    byLayer['school_unified']    ?? null,
      school_elementary: byLayer['school_elementary'] ?? null,
      school_secondary:  byLayer['school_secondary']  ?? null,
    });
  } catch (err) {
    console.error('[GET /api/account/school-district] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/account/set-location
// Auth: requireAuth + requireInform (Connected users get 403 — they use
//       POST /api/connect/set-location instead, which has tier-specific writes
//       to connected_profiles).
//
// Inform-tier equivalent of POST /api/connect/set-location: accepts an address
// string from the Accounts app, geocodes it server-side, stores the result as
// JSONB on inform.inform_profiles.last_essentials_location, and caches the
// user's TIGER districts.
//
// Security decision (Phase 70): the response body is exactly { ok: true }.
// Address, lat/lng, and matchedAddress NEVER appear in the response — address
// data stays server-side. This mirrors the Connected endpoint decision.
// ---------------------------------------------------------------------------

const SetLocationBodySchema = z.object({
  address: z.string().min(1),
});

router.post('/set-location', requireAuth, requireInform, async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;

  const parsed = SetLocationBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      error: 'VALIDATION_ERROR',
      issues: parsed.error.issues,
    });
    return;
  }

  const { address } = parsed.data;

  // 1) Geocode. GeocodingError.code maps directly to HTTP status.
  let lat: number;
  let lng: number;
  let city: string;
  let state: string;
  let matchedAddress: string;

  try {
    const coords = await geocodeAddress(address);
    lat = coords.lat;
    lng = coords.lng;
    city = coords.city;
    state = coords.state;
    matchedAddress = coords.matchedAddress;
  } catch (err) {
    if (err instanceof GeocodingError) {
      // Per planning spec: ADDRESS_NOT_FOUND -> 400, GEOCODER_UNAVAILABLE -> 503.
      // Note: GeocodingErrorCode also includes 'PO_BOX_REJECTED' (see
      // backend/src/lib/geocodingService.ts) — treat it as a 400 input error too.
      if (err.code === 'ADDRESS_NOT_FOUND' || err.code === 'PO_BOX_REJECTED') {
        res.status(400).json({ code: err.code, message: err.message });
        return;
      }
      if (err.code === 'GEOCODER_UNAVAILABLE') {
        res.status(503).json({
          code: 'GEOCODER_UNAVAILABLE',
          message: 'Address lookup temporarily unavailable.',
        });
        return;
      }
      // Defensive: unknown future GeocodingError code falls through to 500.
      console.error('[POST /api/account/set-location] unknown geocoding error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      return;
    }
    // Non-GeocodingError thrown from geocodeAddress — let outer catch handle it.
    throw err;
  }

  // 2) Persist the geocoded result as JSONB on inform_profiles, then cache
  //    districts (fail-open). Wrap both in an outer try/catch so any unexpected
  //    DB error returns 500 with the standard envelope.
  try {
    const location = { lat, lng, city, state, matchedAddress };

    await pool.query(
      `INSERT INTO inform.inform_profiles (user_id, last_essentials_location)
       VALUES ($1, $2::jsonb)
       ON CONFLICT (user_id) DO UPDATE
         SET last_essentials_location = EXCLUDED.last_essentials_location`,
      [authReq.userId, JSON.stringify(location)]
    );

    // District cache (fail-open): never block the location save on a PostGIS error.
    // essentials.cache_user_districts is in the essentials schema, which is NOT
    // in PostgREST's exposed schema list — MUST use pool.query, not adminRpc.
    try {
      await pool.query(
        `SELECT essentials.cache_user_districts($1, $2, $3)`,
        [authReq.userId, lat, lng]
      );
    } catch (cacheErr) {
      console.error('[POST /api/account/set-location] district cache failed (non-fatal):', cacheErr);
    }

    // Security: response body is { ok: true } only — no address/lat/lng echo.
    res.status(200).json({ ok: true });
  } catch (err) {
    console.error('[POST /api/account/set-location] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
