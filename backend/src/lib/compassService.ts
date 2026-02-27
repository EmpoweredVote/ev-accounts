import { pool } from './db.js';

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
 */
export async function promoteCompassImportDraft(userId: string): Promise<void> {
  const client = await pool.connect();
  try {
    const { rows } = await client.query<{ compass_import_draft: unknown }>(
      'SELECT compass_import_draft FROM connect.verification_sessions WHERE user_id = $1',
      [userId]
    );

    const draft = rows[0]?.compass_import_draft;
    if (!draft || !Array.isArray(draft) || draft.length === 0) return;

    await client.query('BEGIN');

    for (const cal of draft as Array<{ topic_id: string; stance_id: string; inverted?: boolean }>) {
      // Resolve stance_id → numeric value
      const { rows: stanceRows } = await client.query<{ value: number }>(
        'SELECT value FROM inform.compass_stances WHERE id = $1 AND topic_id = $2',
        [cal.stance_id, cal.topic_id]
      );

      if (stanceRows.length === 0) continue; // stance removed or topic changed — skip silently

      const value = stanceRows[0]!.value;

      // UPSERT — DO NOTHING if user has already manually calibrated this topic
      const upsertResult = await client.query(
        `INSERT INTO inform.compass_responses (user_id, topic_id, value, inverted)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (user_id, topic_id) DO NOTHING`,
        [userId, cal.topic_id, value, cal.inverted ?? false]
      );

      // Only create a history record when the INSERT actually wrote a row.
      // rowCount === 0 means a manual calibration already existed — no false
      // audit entry.
      if ((upsertResult.rowCount ?? 0) > 0) {
        await client.query(
          `INSERT INTO inform.compass_change_history (user_id, topic_id, old_value, new_value)
           VALUES ($1, $2, NULL, $3)`,
          [userId, cal.topic_id, value]
        );
      }
    }

    // Clear the draft after successful promotion so this is a one-time operation
    await client.query(
      'UPDATE connect.verification_sessions SET compass_import_draft = NULL, updated_at = now() WHERE user_id = $1',
      [userId]
    );

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[promoteCompassImportDraft] error — draft preserved for retry:', err);
    // Non-fatal: do NOT re-throw
  } finally {
    client.release();
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
  const client = await pool.connect();
  try {
    let topicRows: Array<{ id: string }>;

    if (roleScope) {
      // Scope to topics required for the given role
      const { rows } = await client.query<{ id: string }>(
        `SELECT ct.id
         FROM inform.compass_topics ct
         JOIN inform.compass_topic_roles ctr ON ctr.topic_id = ct.id
         WHERE ct.is_live = true
           AND ctr.role_scope = $1
           AND ctr.is_required = true`,
        [roleScope]
      );
      topicRows = rows;
    } else {
      // All live topics
      const { rows } = await client.query<{ id: string }>(
        'SELECT id FROM inform.compass_topics WHERE is_live = true'
      );
      topicRows = rows;
    }

    const required = topicRows.length;

    // Short-circuit: nothing to answer → immediately complete
    if (required === 0) {
      return { required: 0, answered: 0, percent: 100, complete: true };
    }

    const topicIds = topicRows.map(r => r.id);

    const { rows: countRows } = await client.query<{ count: string }>(
      'SELECT COUNT(*) AS count FROM inform.compass_responses WHERE user_id = $1 AND topic_id = ANY($2::uuid[])',
      [userId, topicIds]
    );

    const answered = parseInt(countRows[0]!.count, 10);
    const percent = Math.round((answered / required) * 100);
    const complete = answered >= required;

    return { required, answered, percent, complete };
  } finally {
    client.release();
  }
}
