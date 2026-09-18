/**
 * connectService — DB operations for the Connect enrollment flow.
 *
 * All functions use createUserClient (RLS-enforced) or supabaseAnon (public reads).
 * No service-role client — the owner-based RLS policies on verification_sessions
 * and connected_profiles cover all operations needed by the connect routes.
 *
 * Uses only createUserClient (RLS-enforced) and supabaseAnon (public reads).
 */

import { requestDb, supabaseAnon, adminRpc, supabaseAdmin } from './supabase.js';
import { pool } from './db.js';
import { saveSelectedTopics, validateTopicIds } from './compassService.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface VerificationSession {
  id: string;
  step_reached: string;
  display_name_draft: string | null;
  legal_name_draft: string | null;
  region_draft: string | null;
  home_address_draft: string | null;
  invite_code_id: string | null;
}

export interface CalibrationItem {
  topic_id: string;
  topic_version: number;
  stance_id: string;
  inverted: boolean;
}

// ---------------------------------------------------------------------------
// connected_profiles helpers
// ---------------------------------------------------------------------------

/**
 * hasConnectedProfile
 * Returns true if the user already has a connected_profiles row.
 */
export async function hasConnectedProfile(accessToken: string, userId: string): Promise<boolean> {
  const db = requestDb(accessToken);
  const { data, error } = await db
    .schema('connect')
    .from('connected_profiles')
    .select('id')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) throw error;
  return data !== null;
}

/**
 * getConnectedProfileVerificationStatus
 * Returns the verification_status of the user's connected_profiles row, or null if none.
 */
export async function getConnectedProfileVerificationStatus(
  accessToken: string,
  userId: string
): Promise<string | null> {
  const db = requestDb(accessToken);
  const { data, error } = await db
    .schema('connect')
    .from('connected_profiles')
    .select('verification_status')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) throw error;
  return data?.verification_status ?? null;
}

// ---------------------------------------------------------------------------
// verification_sessions helpers
// ---------------------------------------------------------------------------

/**
 * getVerificationSession
 * Fetches the user's active verification_session. Returns null if none.
 */
export async function getVerificationSession(
  accessToken: string,
  userId: string
): Promise<VerificationSession | null> {
  const db = requestDb(accessToken);
  const { data, error } = await db
    .schema('connect')
    .from('verification_sessions')
    .select('id,step_reached,display_name_draft,legal_name_draft,region_draft,home_address_draft,invite_code_id')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) throw error;
  return data as VerificationSession | null;
}

/**
 * getVerificationSessionStep
 * Lightweight fetch — returns only step_reached. Returns null if no session.
 */
export async function getVerificationSessionStep(
  accessToken: string,
  userId: string
): Promise<string | null> {
  const db = requestDb(accessToken);
  const { data, error } = await db
    .schema('connect')
    .from('verification_sessions')
    .select('step_reached')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) throw error;
  return data?.step_reached ?? null;
}

/**
 * upsertVerificationSession
 * Creates or resets a verification_session at step 'profile' with the claimed invite code.
 * ON CONFLICT (user_id) DO UPDATE handles the resume edge case.
 */
export async function upsertVerificationSession(
  accessToken: string,
  userId: string,
  codeId: string
): Promise<VerificationSession> {
  const { rows } = await pool.query<VerificationSession>(
    `INSERT INTO connect.verification_sessions
       (user_id, step_reached, invite_code_id, updated_at)
     VALUES ($1, 'profile', $2, now())
     ON CONFLICT (user_id) DO UPDATE SET
       step_reached = EXCLUDED.step_reached,
       invite_code_id = EXCLUDED.invite_code_id,
       updated_at = EXCLUDED.updated_at
     RETURNING id, step_reached, display_name_draft, legal_name_draft,
               region_draft, home_address_draft, invite_code_id`,
    [userId, codeId]
  );
  return rows[0];
}

/**
 * updateVerificationSession
 * Updates draft fields and step_reached for the user's verification_session.
 */
export async function updateVerificationSession(
  accessToken: string,
  userId: string,
  updates: {
    display_name_draft: string | null;
    legal_name_draft: string | null;
    region_draft: string | null;
    home_address_draft: string | null;
    step_reached: string;
  }
): Promise<VerificationSession> {
  const { rows } = await pool.query<VerificationSession>(
    `UPDATE connect.verification_sessions SET
       display_name_draft = $2,
       legal_name_draft   = $3,
       region_draft       = $4,
       home_address_draft = $5,
       step_reached       = $6,
       updated_at         = now()
     WHERE user_id = $1
     RETURNING id, step_reached, display_name_draft, legal_name_draft,
               region_draft, home_address_draft, invite_code_id`,
    [userId, updates.display_name_draft, updates.legal_name_draft,
     updates.region_draft, updates.home_address_draft, updates.step_reached]
  );
  if (rows.length === 0) throw new Error('Verification session not found');
  return rows[0];
}

/**
 * getVerificationSessionId
 * Returns the session's UUID, or null if no session exists.
 * Used to check session presence before saving a compass import draft.
 */
export async function getVerificationSessionId(
  accessToken: string,
  userId: string
): Promise<string | null> {
  const db = requestDb(accessToken);
  const { data, error } = await db
    .schema('connect')
    .from('verification_sessions')
    .select('id')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) throw error;
  return data?.id ?? null;
}

/**
 * saveCompassImportDraft
 * Stores the compass calibration JSON in verification_sessions.compass_import_draft.
 */
export async function saveCompassImportDraft(
  accessToken: string,
  userId: string,
  calibrations: CalibrationItem[]
): Promise<void> {
  await pool.query(
    `UPDATE connect.verification_sessions
     SET compass_import_draft = $2, updated_at = now()
     WHERE user_id = $1`,
    [userId, JSON.stringify(calibrations)]
  );
}

// ---------------------------------------------------------------------------
// Compass calibration direct import — uses adminRpc (SECURITY DEFINER)
// ---------------------------------------------------------------------------

export interface ImportCalibrationItem {
  topic_id: string;
  value: number;
  write_in_text?: string;
  inverted?: boolean;
}

/**
 * importCompassCalibrations
 * Atomically writes calibrations to inform.compass_responses via the
 * import_compass_calibrations SECURITY DEFINER RPC (migration 028).
 *
 * If selected_topics is provided with 3–8 valid IDs, the RPC also sets
 * completed_onboarding = true on the user's connected_profiles row, and
 * saveSelectedTopics is called after the RPC succeeds.
 */
export async function importCompassCalibrations(params: {
  userId: string;
  accessToken: string;
  calibrations: ImportCalibrationItem[];
  selectedTopics?: string[];
}): Promise<{ imported: number; onboarding_complete: boolean }> {
  const shouldCompleteOnboarding =
    Array.isArray(params.selectedTopics) &&
    params.selectedTopics.length >= 3 &&
    params.selectedTopics.length <= 8;

  // Validate selected topic IDs if provided
  if (params.selectedTopics && params.selectedTopics.length > 0) {
    const invalidIds = await validateTopicIds(params.selectedTopics);
    if (invalidIds.length > 0) {
      throw Object.assign(new Error('INVALID_TOPIC_IDS'), {
        code: 'INVALID_TOPIC_IDS',
        invalid_ids: invalidIds,
      });
    }
  }

  // Call the import_compass_calibrations SECURITY DEFINER RPC
  const { error } = await adminRpc('import_compass_calibrations', {
    p_user_id: params.userId,
    p_calibrations: JSON.stringify(params.calibrations),
    p_set_onboarding_complete: shouldCompleteOnboarding,
  });

  if (error) {
    if (error.message === 'INVALID_CALIBRATION') {
      throw Object.assign(new Error('INVALID_CALIBRATION'), { code: 'INVALID_CALIBRATION' });
    }
    throw new Error(error.message);
  }

  // Save selected topics if provided and valid
  if (params.selectedTopics && params.selectedTopics.length > 0) {
    await saveSelectedTopics(params.userId, params.selectedTopics);
  }

  return { imported: params.calibrations.length, onboarding_complete: shouldCompleteOnboarding };
}

// ---------------------------------------------------------------------------
// Compass version validation — public inform data, uses supabaseAnon
// ---------------------------------------------------------------------------

/**
 * validateCompassVersions
 * Compares each calibration's topic_version against live server versions.
 * Returns { valid, mismatched, ready_to_import }.
 */
export async function validateCompassVersions(calibrations: CalibrationItem[]): Promise<{
  valid: CalibrationItem[];
  mismatched: Array<{ topic_id: string; client_version: number; server_version: number | null }>;
  ready_to_import: boolean;
}> {
  const { data: liveTopics, error } = await supabaseAnon
    .schema('inform')
    .from('compass_topics')
    .select('id,version')
    .eq('is_live', true);

  if (error) throw error;

  const liveVersionMap = new Map<string, number>();
  for (const topic of liveTopics ?? []) {
    liveVersionMap.set(topic.id, topic.version);
  }

  const valid: CalibrationItem[] = [];
  const mismatched: Array<{ topic_id: string; client_version: number; server_version: number | null }> = [];

  for (const cal of calibrations) {
    const serverVersion = liveVersionMap.get(cal.topic_id) ?? null;
    if (serverVersion === null || cal.topic_version !== serverVersion) {
      mismatched.push({ topic_id: cal.topic_id, client_version: cal.topic_version, server_version: serverVersion });
    } else {
      valid.push(cal);
    }
  }

  return { valid, mismatched, ready_to_import: mismatched.length === 0 };
}

// ---------------------------------------------------------------------------
// Location consent helper — uses supabaseAdmin (service role)
// Route handlers must not import supabaseAdmin directly (architecture rule).
// This helper is the single permitted access point for location_consent reads
// from within the connected_profiles row via service role.
// ---------------------------------------------------------------------------

/**
 * getLocationConsent
 * Returns true if the user's connected_profiles row has location_consent = true.
 * Returns false if the row is missing or location_consent is false/null.
 * Uses supabaseAdmin (service role) — this is a trusted internal standing check,
 * not a data read that feeds a user-facing API response.
 */
export async function getLocationConsent(userId: string): Promise<boolean> {
  const { data, error } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .select('location_consent')
    .eq('user_id', userId)
    .maybeSingle();

  if (error || !data) return false;
  return data.location_consent === true;
}

export interface EnrollmentDrafts {
  legalName: string | null;
  homeAddress: string | null;
}

/**
 * getEnrollmentDrafts
 * Server-side trusted read of the transient identity drafts captured during
 * Connect enrollment (connect.verification_sessions.legal_name_draft /
 * home_address_draft). Used by POST /complete's seal-on-write path (spec §4.4)
 * to seal the real name and raw address into id_vault BEFORE complete_connect_flow
 * nulls both drafts. Returns nulls when there is no session for the user, or a
 * draft is unset.
 */
export async function getEnrollmentDrafts(userId: string): Promise<EnrollmentDrafts> {
  const { rows } = await pool.query<{ legal_name_draft: string | null; home_address_draft: string | null }>(
    `SELECT legal_name_draft, home_address_draft FROM connect.verification_sessions WHERE user_id = $1`,
    [userId]
  );
  return {
    legalName: rows[0]?.legal_name_draft ?? null,
    homeAddress: rows[0]?.home_address_draft ?? null,
  };
}
