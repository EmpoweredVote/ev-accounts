/**
 * accountMeService — the canonical builder for the GET /api/account/me composite.
 *
 * Extracted from routes/account.ts (engine consolidation, Phase 4) so it is a SINGLE
 * source of truth: the /api/account/me route calls it, and the folded Validation Quests
 * code (feed / submissions) calls it in-process instead of looping back over HTTP. Both
 * therefore see byte-identical output — the jurisdiction shape in particular feeds VQ's
 * quest filtering, so a divergent replica would surface the wrong quests.
 *
 * Reads use requestDb(accessToken) — RLS for Supabase sessions, service-role + explicit
 * userId scoping for WorkOS sessions (see lib/supabase.ts requestDb). Service-role-only
 * reads (inform schema, calculate_level, isUserAdmin) go through their existing helpers.
 *
 * Throws typed errors the caller maps to HTTP status:
 *   AUTH_ERROR     — identity could not be verified (401)
 *   USER_NOT_FOUND — no public.users row (404)
 * Any other error propagates (the /me route maps it to 500).
 */
import { requestDb, adminRpc } from './supabase.js';
import { getRequestAuthUser } from './authService.js';
import { pool } from './db.js';
import { isUserAdmin } from './adminService.js';
import { firstNonBlank, deterministicAutoName } from './displayName.js';

export async function getAccountMe(
  accessToken: string,
  userId: string
): Promise<Record<string, unknown>> {
  const db = requestDb(accessToken);

  // 1. Fetch email from Supabase Auth (source of truth for auth data)
  const { user: authUser, error: authError } = await getRequestAuthUser(accessToken, userId);
  if (authError || !authUser) {
    throw Object.assign(new Error('Unable to verify identity'), { code: 'AUTH_ERROR' });
  }

  // 2. Fetch public.users record — base profile fields
  const { data: user, error: userError } = await db
    .from('users')
    .select('id, display_name, avatar_url, created_at, updated_at')
    .eq('id', userId)
    .single();
  if (userError || !user) {
    throw Object.assign(new Error('User record not found'), { code: 'USER_NOT_FOUND' });
  }

  // 3. Connected tier (child record presence — never a status flag)
  const { data: connected } = await db
    .schema('connect')
    .from('connected_profiles')
    .select(
      'id, display_name, account_standing, verification_status, tolerance_rating, total_xp, gem_balance_yellow, gem_balance_blue, gem_balance_red, completed_onboarding, location_consent, verification_rating, vq_hold_until, created_at'
    )
    .eq('user_id', userId)
    .maybeSingle();

  // 4. Empowered tier (child record presence)
  const { data: empowered } = await db
    .schema('empower')
    .from('empowered_profiles')
    .select('id, legal_name, is_active, candidate_page_slug, empowered_at, demoted_at')
    .eq('user_id', userId)
    .maybeSingle();

  // 4b. Admin flag (PK lookup via service role). Fails closed.
  const isAdmin = await isUserAdmin(userId);

  // 4c. inform_profile — inform schema is NOT in PostgREST exposed schemas, use pool.query().
  let informProfileData: { yellow_gem_balance: number; last_essentials_location: unknown } | null = null;
  try {
    const { rows: informRows } = await pool.query<{
      yellow_gem_balance: number;
      last_essentials_location: unknown;
    }>(
      `SELECT yellow_gem_balance, last_essentials_location
       FROM inform.inform_profiles
       WHERE user_id = $1`,
      [userId]
    );
    const informRow = informRows[0];
    if (informRow) {
      informProfileData = {
        yellow_gem_balance: informRow.yellow_gem_balance ?? 0,
        last_essentials_location: informRow.last_essentials_location ?? null,
      };
    }
  } catch (informErr) {
    console.error('[getAccountMe] inform_profile read error:', informErr);
  }

  // 5. Tier from child record presence. Demoted (empowered row, is_active=false) → connected.
  const tier = (empowered && empowered.is_active) ? 'empowered' : connected ? 'connected' : 'inform';

  // 5a. Structured XP for Connected users (legacy total + calculate_level RPC).
  let xpData: { total: number; level: number; xp_in_level: number; xp_to_next_level: number } | undefined;
  if (connected) {
    const totalXp = connected.total_xp ?? 0;
    const { data: levelData } = await adminRpc('calculate_level', { p_total_xp: totalXp }, 'connect');
    const levelRow = Array.isArray(levelData) ? levelData[0] : levelData;
    xpData = {
      total: totalXp,
      level: levelRow?.level ?? 0,
      xp_in_level: levelRow?.xp_in_level ?? 0,
      xp_to_next_level: levelRow?.xp_to_next_level ?? 0,
    };
  }

  // 5b. Stored jurisdiction columns for Connected users with location_consent. Graceful.
  let jurisdictionData: Record<string, unknown> | null = null;
  if (connected?.location_consent) {
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
        [userId]
      );
      const j = rows[0];
      if (j && (j.congressional_geo_id || j.state_senate_geo_id)) {
        jurisdictionData = {
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
          // 🔴 Census FIPS geoids — deliberately NOT named `state`/`city` (already taken
          // by the USPS code and place name above). Civic Spaces keys a slice on the geoid.
          state_geoid: j.state_geo_id,
          city_geoid: j.city_geo_id,
          nation_geoid: j.nation_geo_id,
        };
      }
    } catch (jErr) {
      console.error('[getAccountMe] jurisdiction read error:', jErr);
    }
  }

  // 6. Build response from an explicit whitelist — NEVER spread DB rows.
  const empowerment_status = empowered
    ? (empowered.is_active ? 'empowered' : 'demoted')
    : undefined;

  const vqHoldActive = connected?.vq_hold_until
    ? new Date(connected.vq_hold_until) > new Date()
    : false;
  const redGemQuestsUnlocked = (connected?.verification_rating ?? 60) >= 90;

  const meResponse: Record<string, unknown> = {
    id: user.id,
    email: authUser.email,
    // Never null/empty (watchlist #70): base name → Connected pseudonym → deterministic
    // pseudonym. The row already selects connected.display_name above. This is what surfaces
    // a chosen pseudonym stranded in connect when the base name was left null.
    display_name:
      firstNonBlank(
        user.display_name as string | null | undefined,
        connected?.display_name as string | null | undefined,
      ) ?? deterministicAutoName(user.id as string),
    avatar_url: user.avatar_url,
    tier,
    is_admin: isAdmin,
    completed_onboarding: connected?.completed_onboarding ?? false,
    location_consent: connected?.location_consent ?? false,
    verification_rating: connected?.verification_rating ?? 60,
    vq_hold_active: vqHoldActive,
    red_gem_quests_unlocked: redGemQuestsUnlocked,
    ...(empowerment_status !== undefined && { empowerment_status }),
    account_standing: connected?.account_standing ?? 'active',
    jurisdiction: jurisdictionData,
    inform_profile: informProfileData,
    created_at: user.created_at,
    updated_at: user.updated_at,
  };

  if (connected) {
    meResponse.connected_profile = {
      display_name: connected.display_name,
      verification_status: connected.verification_status,
      tolerance_rating: connected.tolerance_rating,
      xp: xpData,
      gems: {
        yellow: connected.gem_balance_yellow ?? 0,
        blue: connected.gem_balance_blue ?? 0,
        red: connected.gem_balance_red ?? 0,
      },
      completed_onboarding: connected.completed_onboarding,
      verification_rating: connected.verification_rating,
      vq_hold_active: vqHoldActive,
      vq_hold_until: connected.vq_hold_until,
      created_at: connected.created_at,
    };
    meResponse.gems = {
      yellow: connected.gem_balance_yellow ?? 0,
      blue: connected.gem_balance_blue ?? 0,
      red: connected.gem_balance_red ?? 0,
    };
  }

  if (empowered) {
    meResponse.empowered_profile = {
      legal_name: empowered.legal_name,
      is_active: empowered.is_active,
      candidate_page_slug: empowered.candidate_page_slug,
      empowered_at: empowered.empowered_at,
      demoted_at: empowered.demoted_at,
    };
  }

  return meResponse;
}
