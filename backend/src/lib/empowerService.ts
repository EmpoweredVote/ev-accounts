/**
 * empowerService — preflight, slug reservation, consent recording,
 * empowerment confirmation, and demotion execution.
 *
 * WHY THIS FILE EXISTS:
 * The architecture test enforces that no file in src/routes/ may reference
 * supabaseAdmin directly. Empowerment and demotion both require calling
 * SECURITY DEFINER RPC functions in the empower schema — operations that
 * must bypass RLS and use the service role key. Those calls live here in
 * src/lib/, not in src/routes/.
 *
 * SLUG RESERVATION:
 * Preflight reserves a slug in cache (1-hour TTL) so the confirm step can
 * pass the exact slug to the execute_empowerment RPC without re-generating.
 * For demoted users, the original slug is re-reserved (not a new one).
 *
 * ATOMICITY:
 * Empowerment and demotion state changes are entirely handled by Postgres
 * RPC functions (execute_empowerment, execute_demotion). No chained JS
 * awaits for multi-table writes.
 */

import { supabaseAdmin } from './supabase.js';
import { pool } from './db.js';
import { cache } from './cache.js';
import { getCompassCompleteness } from './compassService.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface PreflightFailure {
  code: string;
  message: string;
  [key: string]: unknown;
}

interface PreflightSuccess {
  eligible: true;
  summary: {
    legal_name: string;
    compass_completeness: { required: number; answered: number; percent: number; complete: boolean };
    slug_preview: string;
  };
  demotion_context?: {
    previously_demoted: true;
    demoted_at: string;
    demotion_reason: unknown;
    original_slug: string;
  };
}

interface PreflightFailed {
  eligible: false;
  failures: PreflightFailure[];
  demotion_context?: {
    previously_demoted: true;
    demoted_at: string;
    demotion_reason: unknown;
  };
}

type PreflightResult = PreflightSuccess | PreflightFailed;

// ---------------------------------------------------------------------------
// Slug generation (private)
// ---------------------------------------------------------------------------

/**
 * Generate a URL-safe slug from a legal name.
 *
 * Rules:
 * - Lowercase
 * - Non-alphanumeric runs replaced with a single hyphen
 * - Trailing hyphens stripped
 * - 4-char random alphanumeric suffix appended (e.g., "john-smith-a3b4")
 *
 * Mirrors the logic used in the execute_empowerment Postgres RPC so that
 * the slug preview shown to the user matches what the RPC will store.
 */
function generateSlug(legalName: string): string {
  const base = legalName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/-+$/, '');

  // 4-char alphanumeric suffix — same character set as the RPC's UUID-strip approach
  const suffix = globalThis.crypto
    .randomUUID()
    .replace(/-/g, '')
    .substring(0, 4);

  return `${base}-${suffix}`;
}

// ---------------------------------------------------------------------------
// reserveSlug
// ---------------------------------------------------------------------------

/**
 * Generate a new slug from the user's legal name and cache it for 1 hour.
 *
 * The cached slug is consumed by confirmEmpowerment so the RPC receives the
 * exact slug that was shown to the user in the preflight summary.
 */
export async function reserveSlug(userId: string, legalName: string): Promise<string> {
  const slug = generateSlug(legalName);
  await cache.set(`slug_reservation:${userId}`, slug, 3600);
  return slug;
}

// ---------------------------------------------------------------------------
// getReservedSlug
// ---------------------------------------------------------------------------

/**
 * Retrieve the slug currently reserved for a user, or null if expired/missing.
 */
export async function getReservedSlug(userId: string): Promise<string | null> {
  return cache.get<string>(`slug_reservation:${userId}`);
}

// ---------------------------------------------------------------------------
// runPreflight
// ---------------------------------------------------------------------------

/**
 * Validate all empowerment conditions for the user and return a structured
 * result with EVERY failure collected (not just the first one).
 *
 * On success: reserves a slug in cache and returns { eligible: true, summary }.
 * On failure: returns { eligible: false, failures: [...] }.
 *
 * Both paths include demotion_context if the user has a previously inactive
 * empowered_profiles row.
 */
export async function runPreflight(userId: string): Promise<PreflightResult> {
  const client = await pool.connect();
  try {
    // 1. Fetch connected_profiles for this user
    const { rows: connectedRows } = await client.query<{
      id: string;
      verification_status: string;
      legal_name: string | null;
      candidate_role: string | null;
    }>(
      'SELECT id, verification_status, legal_name, candidate_role FROM connect.connected_profiles WHERE user_id = $1',
      [userId]
    );

    if (connectedRows.length === 0) {
      // requireConnected middleware should have caught this — defense in depth
      throw new Error('No connected profile found for user');
    }

    const connected = connectedRows[0]!;

    // 2. Fetch existing empowered_profiles row (including demoted)
    const { rows: empoweredRows } = await client.query<{
      id: string;
      is_active: boolean;
      demoted_at: string | null;
      demotion_reason: unknown;
      candidate_page_slug: string | null;
    }>(
      'SELECT id, is_active, demoted_at, demotion_reason, candidate_page_slug FROM empower.empowered_profiles WHERE user_id = $1',
      [userId]
    );

    const existingEmpowered = empoweredRows[0] ?? null;

    // 3. Build demotion context if user has an inactive empowered_profiles row
    const isDemoted = existingEmpowered !== null && !existingEmpowered.is_active;

    const demotionContextBase = isDemoted
      ? {
          previously_demoted: true as const,
          demoted_at: existingEmpowered!.demoted_at!,
          demotion_reason: existingEmpowered!.demotion_reason,
        }
      : undefined;

    // 4. Collect ALL failures — do NOT short-circuit on first failure
    const failures: PreflightFailure[] = [];

    if (connected.verification_status !== 'verified') {
      failures.push({
        code: 'NOT_VERIFIED',
        message: 'Connected account must be verified',
      });
    }

    if (connected.candidate_role === null) {
      failures.push({
        code: 'ROLE_NOT_SET',
        message: 'Candidate role must be set before empowerment',
      });
    }

    if (connected.legal_name === null) {
      failures.push({
        code: 'LEGAL_NAME_MISSING',
        message: 'Legal name is required for empowerment',
      });
    }

    // Only check compass completeness if we have a role to scope it to
    let compassCompleteness: { required: number; answered: number; percent: number; complete: boolean } | null = null;

    if (connected.candidate_role !== null) {
      compassCompleteness = await getCompassCompleteness(userId, connected.candidate_role);
      if (!compassCompleteness.complete) {
        failures.push({
          code: 'CALIBRATION_INCOMPLETE',
          message: 'Compass calibration is not complete for your role',
          threshold: compassCompleteness.required,
          current: compassCompleteness.answered,
        });
      }
    }

    // 5. Return failures if any
    if (failures.length > 0) {
      return {
        eligible: false,
        failures,
        ...(demotionContextBase ? { demotion_context: demotionContextBase } : {}),
      };
    }

    // 6. Eligible — reserve slug and return summary
    // For demoted users with an existing slug, preserve the original slug
    let slugPreview: string;

    if (isDemoted && existingEmpowered!.candidate_page_slug) {
      // Re-empowerment: restore original slug
      slugPreview = existingEmpowered!.candidate_page_slug;
      await cache.set(`slug_reservation:${userId}`, slugPreview, 3600);
    } else {
      // Fresh empowerment: generate a new slug
      slugPreview = await reserveSlug(userId, connected.legal_name!);
    }

    const successResult: PreflightSuccess = {
      eligible: true,
      summary: {
        legal_name: connected.legal_name!,
        compass_completeness: compassCompleteness!,
        slug_preview: slugPreview,
      },
    };

    if (isDemoted && existingEmpowered!.candidate_page_slug) {
      successResult.demotion_context = {
        previously_demoted: true,
        demoted_at: existingEmpowered!.demoted_at!,
        demotion_reason: existingEmpowered!.demotion_reason,
        original_slug: existingEmpowered!.candidate_page_slug,
      };
    }

    return successResult;
  } finally {
    client.release();
  }
}

// ---------------------------------------------------------------------------
// recordConsent
// ---------------------------------------------------------------------------

/**
 * Insert a consent record into empower.consent_records via the pg pool.
 *
 * Written via service layer only — no INSERT/UPDATE/DELETE RLS policies
 * exist on consent_records (authenticated users can SELECT their own records).
 */
export async function recordConsent(
  userId: string,
  consentedItems: string[],
  ipAddress?: string
): Promise<void> {
  await pool.query(
    `INSERT INTO empower.consent_records (user_id, consented_items, ip_address)
     VALUES ($1, $2, $3)`,
    [userId, JSON.stringify(consentedItems), ipAddress ?? null]
  );
}

// ---------------------------------------------------------------------------
// confirmEmpowerment
// ---------------------------------------------------------------------------

/**
 * Atomically empower the user by:
 * 1. Retrieving the cached reserved slug (throws PREFLIGHT_EXPIRED if missing)
 * 2. Calling the execute_empowerment Postgres RPC
 * 3. Recording the consent items
 * 4. Clearing the slug reservation from cache
 *
 * The execute_empowerment RPC handles all DB writes atomically (empowered_profiles
 * upsert + compass visibility update). No chained JS awaits for multi-table writes.
 */
export async function confirmEmpowerment(
  userId: string,
  consentedItems: string[]
): Promise<{ empowered_profile: Record<string, unknown> }> {
  // 1. Retrieve reserved slug — must have run preflight first
  const reservedSlug = await getReservedSlug(userId);
  if (!reservedSlug) {
    const err = new Error('Preflight slug reservation has expired. Please run preflight again.');
    (err as NodeJS.ErrnoException).code = 'PREFLIGHT_EXPIRED';
    throw err;
  }

  // 2. Fetch connected_profiles for the RPC parameters
  const { rows: connectedRows } = await pool.query<{
    id: string;
    legal_name: string | null;
  }>(
    'SELECT id, legal_name FROM connect.connected_profiles WHERE user_id = $1',
    [userId]
  );

  if (connectedRows.length === 0) {
    throw new Error('No connected profile found for user');
  }

  const connectedProfile = connectedRows[0]!;

  // 3. Call the execute_empowerment RPC — atomically creates/updates empowered_profiles
  //    and sets compass visibility to public
  const { data, error } = await supabaseAdmin
    .schema('empower')
    .rpc('execute_empowerment', {
      p_user_id: userId,
      p_legal_name: connectedProfile.legal_name ?? '',
      p_connected_profile_id: connectedProfile.id,
      p_reserved_slug: reservedSlug,
    });

  if (error) {
    throw new Error(error.message);
  }

  // 4. Record consent items
  await recordConsent(userId, consentedItems);

  // 5. Clear the slug reservation
  await cache.del(`slug_reservation:${userId}`);

  return { empowered_profile: data as Record<string, unknown> };
}

// ---------------------------------------------------------------------------
// executeDemotion
// ---------------------------------------------------------------------------

/**
 * Atomically demote an empowered user by calling the execute_demotion RPC.
 *
 * The RPC sets is_active=false, records demoted_at and demotion_reason on
 * the empowered_profiles row, and sets all of the user's compass responses
 * to visibility=private.
 */
export async function executeDemotion(
  userId: string,
  demotionReason?: Record<string, unknown>
): Promise<void> {
  const { error } = await supabaseAdmin
    .schema('empower')
    .rpc('execute_demotion', {
      p_user_id: userId,
      p_demotion_reason: demotionReason ?? null,
    });

  if (error) {
    throw new Error(error.message);
  }
}
