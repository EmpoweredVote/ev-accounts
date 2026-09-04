/**
 * profileService — profile data aggregation for public and owner profile views.
 *
 * All reads use supabaseAdmin (service role) because public profile endpoints
 * have no user JWT — unauthenticated callers cannot use the anon/user client
 * for cross-schema reads (connect, empower, inform).
 *
 * Sensitive fields (tolerance_rating, legal_name at root, email, location) are
 * NEVER included in the public profile shape. Owner-only fields are added only
 * by getOwnerProfile().
 *
 * Architecture: this file is on the supabaseAdmin allowlist in architecture.test.ts.
 */

import { supabaseAdmin, adminRpc } from './supabase.js';
import { pool } from './db.js';
import { getSelectedTopics } from './compassService.js';

// ---------------------------------------------------------------------------
// Internal types
// ---------------------------------------------------------------------------

interface PublicProfileBase {
  username: string;
  tier: 'inform' | 'connected' | 'empowered';
  level: number | null;
  total_xp: number | null;
  selected_topic_ids?: string[];
  empowered_profile?: Record<string, unknown>;
  compass_answers?: Record<string, unknown>[];
}

interface OwnerProfile extends PublicProfileBase {
  email: string;
  location_consent: boolean;
  gem_balances: {
    yellow: number;
    blue: number;
    red: number;
  };
}

// Internal extended shape used to pass gem/consent data from public fetch
interface InternalProfileData extends PublicProfileBase {
  _gem_balance_yellow: number;
  _gem_balance_blue: number;
  _gem_balance_red: number;
  _location_consent: boolean;
}

// ---------------------------------------------------------------------------
// UUID validation
// ---------------------------------------------------------------------------

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function isValidUuid(value: string): boolean {
  return UUID_REGEX.test(value);
}

// ---------------------------------------------------------------------------
// getPublicProfile
// ---------------------------------------------------------------------------

/**
 * Fetch and aggregate the public profile for a user.
 *
 * Returns tier-conditional shape:
 *   - Inform:   { username, tier, level: null, total_xp: null }
 *   - Connected: adds level, total_xp, selected_topic_ids
 *   - Empowered: adds empowered_profile (with politician fields if linked),
 *                compass_answers
 *
 * Excludes: gems, tolerance_rating, legal_name (at root), email, location_consent.
 */
export async function getPublicProfile(userId: string): Promise<PublicProfileBase | null> {
  const internal = await fetchInternalProfile(userId);
  if (!internal) return null;

  // Strip internal-only fields before returning public shape
  const {
    _gem_balance_yellow: _y,
    _gem_balance_blue: _b,
    _gem_balance_red: _r,
    _location_consent: _lc,
    ...publicShape
  } = internal;

  return publicShape;
}

// ---------------------------------------------------------------------------
// getOwnerProfile
// ---------------------------------------------------------------------------

/**
 * Fetch and aggregate the owner profile for a user (includes gem balances,
 * location_consent, and email in addition to the public profile shape).
 *
 * Only called from GET /api/account/profile/me — requireAuth middleware ensures
 * the caller is authenticated.
 */
export async function getOwnerProfile(userId: string, email: string): Promise<OwnerProfile | null> {
  const internal = await fetchInternalProfile(userId);
  if (!internal) return null;

  const {
    _gem_balance_yellow,
    _gem_balance_blue,
    _gem_balance_red,
    _location_consent,
    ...publicShape
  } = internal;

  return {
    ...publicShape,
    email,
    location_consent: _location_consent,
    gem_balances: {
      yellow: _gem_balance_yellow,
      blue: _gem_balance_blue,
      red: _gem_balance_red,
    },
  };
}

// ---------------------------------------------------------------------------
// fetchInternalProfile (private)
// ---------------------------------------------------------------------------

/**
 * Core profile aggregation — fetches all tier data and builds the full internal
 * shape including owner-only fields (gems, location_consent) so getOwnerProfile
 * can access them without a second round-trip.
 */
async function fetchInternalProfile(userId: string): Promise<InternalProfileData | null> {
  // Step 1: Fetch public.users row
  const { data: user, error: userError } = await supabaseAdmin
    .from('users')
    .select('id, display_name, created_at')
    .eq('id', userId)
    // public.users.deleted_at is the account-level truth — soft_delete_user sets
    // it alongside connected_profiles.deleted_at. Filtering only the profile row
    // below would still serve a deleted account as an Inform-tier profile,
    // display_name and all.
    .is('deleted_at', null)
    .maybeSingle();

  if (userError || !user) return null;

  // Step 2: Fetch connect.connected_profiles row
  const { data: connected, error: connectedError } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .select('user_id, display_name, total_xp, gem_balance_yellow, gem_balance_blue, gem_balance_red, location_consent')
    .eq('user_id', userId)
    // Matches the empowered_profiles read below, which has always filtered this.
    // A public profile served by id has no requireAuth in front of it, so the
    // deleted-account refusal has to happen here.
    .is('deleted_at', null)
    .maybeSingle();

  if (connectedError) {
    console.error('[profileService] error fetching connected_profiles:', connectedError);
  }

  // Step 3: Fetch empower.empowered_profiles row
  const { data: empowered, error: empoweredError } = await supabaseAdmin
    .schema('empower')
    .from('empowered_profiles')
    .select('user_id, legal_name, candidate_page_slug, is_active, empowered_at, demoted_at, politician_id')
    .eq('user_id', userId)
    .is('deleted_at', null)
    .maybeSingle();

  if (empoweredError) {
    console.error('[profileService] error fetching empowered_profiles:', empoweredError);
  }

  // Step 4: Derive tier
  const isEmpowered = empowered != null && empowered.is_active === true;
  const isConnected = connected != null;
  const tier: 'inform' | 'connected' | 'empowered' = isEmpowered
    ? 'empowered'
    : isConnected
      ? 'connected'
      : 'inform';

  // Step 5: Derive username
  const username: string =
    (isEmpowered && empowered?.candidate_page_slug) ||
    connected?.display_name ||
    user.display_name ||
    '';

  // Step 6: Compute level for Connected/Empowered
  let level: number | null = null;
  const total_xp: number | null = connected ? (connected.total_xp ?? 0) : null;

  if (isConnected && connected) {
    const { data: levelData } = await adminRpc('calculate_level', {
      p_total_xp: connected.total_xp ?? 0,
    });
    if (levelData != null) {
      const result = levelData as Record<string, unknown>;
      level = typeof result.level === 'number' ? result.level : null;
    }
  }

  // Step 7: Build base shape
  const base: Partial<InternalProfileData> = {
    username,
    tier,
    level,
    total_xp,
    // Internal owner-only fields
    _gem_balance_yellow: connected?.gem_balance_yellow ?? 0,
    _gem_balance_blue: connected?.gem_balance_blue ?? 0,
    _gem_balance_red: connected?.gem_balance_red ?? 0,
    _location_consent: connected?.location_consent === true,
  };

  // Step 8: Add Connected-and-above fields
  //
  // The compass now lives on inform.inform_profiles (migration 1850), so the
  // value is read from there rather than the Connected profile. WHO SEES IT is
  // deliberately unchanged: still Connected-and-above only. Every user has a
  // compass to expose now, but widening a public profile field is a product
  // decision, not a side effect of moving storage.
  if (isConnected) {
    base.selected_topic_ids = await getSelectedTopics(userId);
  }

  // Step 9: Add Empowered-specific fields
  if (isEmpowered && empowered) {
    // Fetch compass answers.
    //
    // compass_responses_effective (CC_0062) — this block is read-only output on
    // an Empowered profile payload, so suppression here withholds a stale value
    // and cannot cost the user anything on a later write.
    const { data: answers, error: answersError } = await supabaseAdmin
      .schema('inform')
      .from('compass_responses_effective')
      .select('topic_id, value, write_in_text, inverted, updated_at')
      .eq('user_id', userId)
      .is('deleted_at', null);

    if (answersError) {
      console.error('[profileService] error fetching compass_responses:', answersError);
    }

    base.compass_answers = (answers ?? []) as Record<string, unknown>[];

    // Build empowered_profile block
    const empoweredProfileBase: Record<string, unknown> = {
      legal_name: empowered.legal_name,
      candidate_page_slug: empowered.candidate_page_slug,
      is_active: empowered.is_active,
      empowered_at: empowered.empowered_at,
      demoted_at: empowered.demoted_at,
    };

    // Fetch politician record if politician_id is set
    // essentials schema is not PostgREST-exposed; must use pool.query() (Phase 35 pattern)
    if (empowered.politician_id != null) {
      const { rows: politicianRows } = await pool.query<Record<string, unknown>>(
        `SELECT id, first_name, last_name, preferred_name, full_name, photo_origin_url,
                is_active, is_incumbent, is_vacant, party, party_short_name, slug, bio_text
         FROM essentials.politicians
         WHERE id = $1`,
        [empowered.politician_id]
      ).catch((err: unknown) => {
        console.error('[profileService] error fetching politician:', err);
        return { rows: [] as Record<string, unknown>[] };
      });

      if (politicianRows.length > 0) {
        const politician = politicianRows[0];
        // Merge politician fields into empowered_profile block
        Object.assign(empoweredProfileBase, {
          politician_id: politician['id'],
          politician_first_name: politician['first_name'],
          politician_last_name: politician['last_name'],
          politician_preferred_name: politician['preferred_name'],
          politician_full_name: politician['full_name'],
          photo_origin_url: politician['photo_origin_url'],
          politician_is_active: politician['is_active'],
          is_incumbent: politician['is_incumbent'],
          is_vacant: politician['is_vacant'],
          party: politician['party'],
          party_short_name: politician['party_short_name'],
          slug: politician['slug'],
          bio_text: politician['bio_text'],
        });
      }
    }

    base.empowered_profile = empoweredProfileBase;
  }

  return base as InternalProfileData;
}
