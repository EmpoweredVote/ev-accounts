/**
 * connectService — DB operations for the Connect enrollment flow.
 *
 * All functions use createUserClient (RLS-enforced) or supabaseAnon (public reads).
 * No service-role client — the owner-based RLS policies on verification_sessions
 * and connected_profiles cover all operations needed by the connect routes.
 *
 * Uses only createUserClient (RLS-enforced) and supabaseAnon (public reads).
 */

import { createUserClient, supabaseAnon } from './supabase.js';

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
  const db = createUserClient(accessToken);
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
  const db = createUserClient(accessToken);
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
  const db = createUserClient(accessToken);
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
  const db = createUserClient(accessToken);
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
  const db = createUserClient(accessToken);
  const { data, error } = await db
    .schema('connect')
    .from('verification_sessions')
    .upsert(
      {
        user_id: userId,
        step_reached: 'profile',
        invite_code_id: codeId,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'user_id' }
    )
    .select('id,step_reached,display_name_draft,legal_name_draft,region_draft,home_address_draft,invite_code_id')
    .single();

  if (error) throw error;
  return data as VerificationSession;
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
  const db = createUserClient(accessToken);
  const { data, error } = await db
    .schema('connect')
    .from('verification_sessions')
    .update({
      ...updates,
      updated_at: new Date().toISOString(),
    })
    .eq('user_id', userId)
    .select('id,step_reached,display_name_draft,legal_name_draft,region_draft,home_address_draft,invite_code_id')
    .single();

  if (error) throw error;
  return data as VerificationSession;
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
  const db = createUserClient(accessToken);
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
  const db = createUserClient(accessToken);
  const { error } = await db
    .schema('connect')
    .from('verification_sessions')
    .update({
      compass_import_draft: JSON.stringify(calibrations),
      updated_at: new Date().toISOString(),
    })
    .eq('user_id', userId);

  if (error) throw error;
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
