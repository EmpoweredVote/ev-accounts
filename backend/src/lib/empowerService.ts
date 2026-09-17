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

import { supabaseAdmin, adminRpc } from './supabase.js';
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
 *
 * DB checks are delegated to run_empower_preflight RPC. Slug generation and
 * caching remain in TypeScript (crypto.randomUUID is not available in PL/pgSQL).
 */
export async function runPreflight(userId: string, confirmedLegalName?: string): Promise<PreflightResult> {
  const { data, error } = await adminRpc('run_empower_preflight', {
    p_user_id: userId,
  });

  if (error) {
    if (error.message.includes('No connected profile')) {
      throw new Error('No connected profile found for user');
    }
    throw new Error(error.message);
  }

  const result = data as {
    eligible: boolean;
    failures?: PreflightFailure[];
    connected_profile?: {
      legal_name: string | null;
      candidate_role: string | null;
    };
    empowered_profile?: {
      is_active: boolean;
      demoted_at: string | null;
      demotion_reason: unknown;
      candidate_page_slug: string | null;
    } | null;
    compass_completeness?: { required: number; answered: number; percent: number; complete: boolean };
    demotion_context?: {
      previously_demoted: true;
      demoted_at: string;
      demotion_reason: unknown;
    };
    is_demoted?: boolean;
  };

  if (!result.eligible) {
    return {
      eligible: false,
      failures: result.failures ?? [],
      ...(result.demotion_context ? { demotion_context: result.demotion_context } : {}),
    };
  }

  // Eligible — reserve slug and build summary
  const connected = result.connected_profile!;
  const empowered = result.empowered_profile ?? null;
  const isDemoted = result.is_demoted ?? false;
  const compassCompleteness = result.compass_completeness!;

  let slugPreview: string;

  if (isDemoted && empowered?.candidate_page_slug) {
    // Re-empowerment: restore original slug
    slugPreview = empowered.candidate_page_slug;
    await cache.set(`slug_reservation:${userId}`, slugPreview, 3600);
  } else {
    // Fresh empowerment: generate a new slug from the confirmed name when given,
    // else the DB value (falls back across the id-vault cutover — see ADR).
    const nameForSlug = confirmedLegalName ?? connected.legal_name ?? '';
    slugPreview = await reserveSlug(userId, nameForSlug);
  }

  const successResult: PreflightSuccess = {
    eligible: true,
    summary: {
      legal_name: confirmedLegalName ?? connected.legal_name ?? '',
      compass_completeness: compassCompleteness,
      slug_preview: slugPreview,
    },
  };

  if (isDemoted && empowered?.candidate_page_slug) {
    successResult.demotion_context = {
      previously_demoted: true,
      demoted_at: empowered.demoted_at!,
      demotion_reason: empowered.demotion_reason,
      original_slug: empowered.candidate_page_slug,
    };
  }

  return successResult;
}

// ---------------------------------------------------------------------------
// recordConsent
// ---------------------------------------------------------------------------

/**
 * Insert a consent record into empower.consent_records via supabaseAdmin.
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
    [userId, consentedItems, ipAddress ?? null]
  );
}

// ---------------------------------------------------------------------------
// confirmEmpowerment
// ---------------------------------------------------------------------------

/**
 * Atomically empower the user by:
 * 1. Retrieving the cached reserved slug (throws PREFLIGHT_EXPIRED if missing)
 * 2. Fetching connected_profiles for RPC parameters
 * 3. Calling the execute_empowerment Postgres RPC
 * 4. Recording the consent items
 * 5. Clearing the slug reservation from cache
 *
 * The execute_empowerment RPC handles all DB writes atomically (empowered_profiles
 * upsert + compass visibility update). No chained JS awaits for multi-table writes.
 */
export async function confirmEmpowerment(
  userId: string,
  consentedItems: string[],
  confirmedLegalName?: string
): Promise<{ empowered_profile: Record<string, unknown> }> {
  // 1. Retrieve reserved slug — must have run preflight first
  const reservedSlug = await getReservedSlug(userId);
  if (!reservedSlug) {
    const err = new Error('Preflight slug reservation has expired. Please run preflight again.');
    (err as NodeJS.ErrnoException).code = 'PREFLIGHT_EXPIRED';
    throw err;
  }

  // 2. Fetch connected_profiles for the RPC parameters
  const { data: connectedData, error: connectedError } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .select('id,legal_name')
    .eq('user_id', userId)
    .single();

  if (connectedError) {
    if (connectedError.code === 'PGRST116') {
      throw new Error('No connected profile found for user');
    }
    throw new Error(connectedError.message);
  }

  const connectedProfile = connectedData as { id: string; legal_name: string | null };

  // 3. Call the execute_empowerment RPC — atomically creates/updates empowered_profiles
  //    and sets compass visibility to public
  const { data, error } = await supabaseAdmin
    .schema('empower')
    .rpc('execute_empowerment', {
      p_user_id: userId,
      p_legal_name: confirmedLegalName ?? connectedProfile.legal_name ?? '',
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
