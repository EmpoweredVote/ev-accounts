import { adminRpc } from './supabase.js';

/**
 * promoteCompassImportDraft
 *
 * Lazy promotion: moves Phase 3 calibration data stored in
 * connect.verification_sessions.compass_import_draft into the live
 * inform.compass_responses table.
 *
 * Called on the first GET /compass/answers for a user. If the draft is
 * already NULL (already promoted or never set), the function exits
 * immediately without touching the database.
 *
 * Non-fatal: if any error occurs the transaction is rolled back, the draft
 * is preserved (so the next GET /answers will retry), and the error is
 * logged but NOT re-thrown. Callers should never surface this failure to
 * the end user.
 *
 * ON CONFLICT (user_id, topic_id) DO NOTHING ensures manual calibrations
 * already saved by the user are never overwritten by an imported draft.
 *
 * Delegates to the promote_compass_import_draft SECURITY DEFINER RPC which
 * handles the transactional multi-step promotion atomically.
 */
export async function promoteCompassImportDraft(userId: string): Promise<void> {
  const { error } = await adminRpc('promote_compass_import_draft', {
    p_user_id: userId,
  });

  if (error) {
    // Non-fatal — log but do not re-throw. Draft is preserved for retry.
    console.error('[promoteCompassImportDraft] error — draft preserved for retry:', error.message);
  }
}

/**
 * getCompassCompleteness
 *
 * Calculates how many live compass topics a user has answered, optionally
 * filtered by the topics required for a specific role scope.
 *
 * When roleScope is provided, only topics with a matching compass_topic_roles
 * row where is_required=true are counted as "required". All other live topics
 * are ignored for that scope.
 *
 * Returns { required, answered, percent, complete }:
 *   - required: total topics the user should answer (0 when none)
 *   - answered:  topics for which the user has a compass_responses row
 *   - percent:   Math.round((answered / required) * 100); 100 when required === 0
 *   - complete:  true when answered >= required
 */
export async function getCompassCompleteness(
  userId: string,
  roleScope?: string
): Promise<{ required: number; answered: number; percent: number; complete: boolean }> {
  const { data, error } = await adminRpc('get_compass_completeness', {
    p_user_id: userId,
    p_role_scope: roleScope ?? null,
  });

  if (error) throw new Error(error.message);

  const result = data as { required: number; answered: number; percent: number; complete: boolean };
  return result;
}
