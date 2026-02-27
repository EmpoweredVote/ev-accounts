/**
 * socialService — peer connection state machine, follow/unfollow, and social queries.
 *
 * WHY THIS FILE EXISTS:
 * The architecture test enforces that no file in src/routes/ may reference
 * supabaseAdmin directly. sendPeerRequest calls the create_peer_request
 * SECURITY DEFINER RPC in the connect schema, which requires the service role
 * key to bypass RLS. That call lives here in src/lib/, not in src/routes/.
 *
 * PEER CONNECTION STATE MACHINE:
 * pending → accepted (by target)
 * pending → declined (by target) — re-sendable: RPC deletes old row + inserts new pending
 * pending|accepted|declined → blocked (by either party, always recorded as actor_id=blocker)
 * Blocked state also removes any follow relationship between the two users.
 *
 * FOLLOW RULES:
 * - Only Empowered accounts can be followed (Connected → Empowered, no approval needed)
 * - Connected users cannot follow Connected users — must use peer connection flow
 * - Follow is idempotent (ON CONFLICT DO NOTHING)
 * - Unfollow is idempotent (no error if not following)
 */

import { supabaseAdmin } from './supabase.js';
import { pool } from './db.js';

// ---------------------------------------------------------------------------
// sendPeerRequest
// ---------------------------------------------------------------------------

/**
 * Send a peer connection request from actorId to targetId.
 *
 * Delegates to the create_peer_request SECURITY DEFINER RPC which enforces:
 * - Self-request rejection
 * - Bidirectional block check (cannot request if either party has blocked the other)
 * - Duplicate prevention (cannot send if already connected or pending request exists)
 * - Declined re-send (deletes old declined row and inserts new pending row)
 */
export async function sendPeerRequest(
  actorId: string,
  targetId: string
): Promise<{ id: string; status: string }> {
  const { data, error } = await supabaseAdmin
    .schema('connect')
    .rpc('create_peer_request', { p_actor_id: actorId, p_target_id: targetId });

  if (error) {
    const msg = error.message ?? '';
    if (msg.includes('SELF_REQUEST')) {
      throw Object.assign(new Error('Cannot send a peer request to yourself'), {
        code: 'SELF_REQUEST',
      });
    }
    if (msg.includes('BLOCKED')) {
      throw Object.assign(new Error('A block exists between these users'), { code: 'BLOCKED' });
    }
    if (msg.includes('ALREADY_CONNECTED')) {
      throw Object.assign(new Error('Users are already connected'), {
        code: 'ALREADY_CONNECTED',
      });
    }
    if (msg.includes('PENDING')) {
      throw Object.assign(new Error('A pending request already exists'), { code: 'PENDING' });
    }
    throw new Error(msg || 'Failed to send peer request');
  }

  const row = data as { id: string; status: string };
  return { id: row.id, status: row.status };
}

// ---------------------------------------------------------------------------
// acceptPeerRequest
// ---------------------------------------------------------------------------

/**
 * Accept a pending peer request.
 *
 * Only the target (addressee) can accept. WHERE includes target_id = userId
 * to enforce this ownership check at the DB layer.
 */
export async function acceptPeerRequest(requestId: string, userId: string): Promise<void> {
  const result = await pool.query(
    `UPDATE connect.social_relationships
     SET status = 'accepted', updated_at = now()
     WHERE id = $1
       AND target_id = $2
       AND connection_type = 'peer'
       AND status = 'pending'`,
    [requestId, userId]
  );

  if (result.rowCount === 0) {
    throw Object.assign(
      new Error('Request not found, not addressed to this user, or not pending'),
      { code: 'REQUEST_NOT_FOUND' }
    );
  }
}

// ---------------------------------------------------------------------------
// declinePeerRequest
// ---------------------------------------------------------------------------

/**
 * Decline a pending peer request.
 *
 * Only the target (addressee) can decline. Declined requests are re-sendable:
 * the create_peer_request RPC deletes the declined row and inserts a new pending
 * row when the actor tries again.
 */
export async function declinePeerRequest(requestId: string, userId: string): Promise<void> {
  const result = await pool.query(
    `UPDATE connect.social_relationships
     SET status = 'declined', updated_at = now()
     WHERE id = $1
       AND target_id = $2
       AND connection_type = 'peer'
       AND status = 'pending'`,
    [requestId, userId]
  );

  if (result.rowCount === 0) {
    throw Object.assign(
      new Error('Request not found, not addressed to this user, or not pending'),
      { code: 'REQUEST_NOT_FOUND' }
    );
  }
}

// ---------------------------------------------------------------------------
// blockUser
// ---------------------------------------------------------------------------

/**
 * Block another user.
 *
 * If a peer relationship already exists (in either direction), it is updated
 * to blocked with the blocker always recorded as actor_id. If no relationship
 * exists, a new blocked row is inserted. Any follow relationships between the
 * two users (in either direction) are also removed.
 */
export async function blockUser(actorId: string, targetId: string): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Check if any peer relationship exists between the two users (either direction)
    const { rows: existingRows } = await client.query<{ id: string; status: string }>(
      `SELECT id, status FROM connect.social_relationships
       WHERE connection_type = 'peer'
         AND ((actor_id = $1 AND target_id = $2) OR (actor_id = $2 AND target_id = $1))
       LIMIT 1`,
      [actorId, targetId]
    );

    if (existingRows.length > 0) {
      // Update existing relationship — blocker becomes actor_id
      await client.query(
        `UPDATE connect.social_relationships
         SET status = 'blocked', actor_id = $1, target_id = $2, updated_at = now()
         WHERE id = $3 AND connection_type = 'peer'`,
        [actorId, targetId, existingRows[0]!.id]
      );
    } else {
      // Insert a new blocked row
      await client.query(
        `INSERT INTO connect.social_relationships (actor_id, target_id, connection_type, status)
         VALUES ($1, $2, 'peer', 'blocked')
         ON CONFLICT (actor_id, target_id, connection_type) DO UPDATE SET status = 'blocked', updated_at = now()`,
        [actorId, targetId]
      );
    }

    // Remove any follow relationships between the two users (either direction)
    await client.query(
      `DELETE FROM connect.social_relationships
       WHERE connection_type = 'follow'
         AND ((actor_id = $1 AND target_id = $2) OR (actor_id = $2 AND target_id = $1))`,
      [actorId, targetId]
    );

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// ---------------------------------------------------------------------------
// follow
// ---------------------------------------------------------------------------

/**
 * Follow an Empowered account.
 *
 * Validates:
 * 1. Target must be an active Empowered account (Connected users cannot be followed)
 * 2. No block exists between actor and target in either direction
 *
 * ON CONFLICT DO NOTHING makes follow idempotent — following twice is not an error.
 */
export async function follow(actorId: string, targetId: string): Promise<void> {
  // 1. Validate the target is an Empowered account
  const { rows: empRows } = await pool.query(
    'SELECT id FROM empower.empowered_profiles WHERE user_id = $1 AND is_active = true',
    [targetId]
  );

  if (empRows.length === 0) {
    throw Object.assign(new Error('Can only follow Empowered accounts'), {
      code: 'NOT_EMPOWERED',
    });
  }

  // 2. Check for blocks in either direction
  const { rows: blockRows } = await pool.query(
    `SELECT 1 FROM connect.social_relationships
     WHERE connection_type = 'peer' AND status = 'blocked'
       AND ((actor_id = $1 AND target_id = $2) OR (actor_id = $2 AND target_id = $1))`,
    [actorId, targetId]
  );

  if (blockRows.length > 0) {
    throw Object.assign(new Error('A block exists between these users'), { code: 'BLOCKED' });
  }

  // 3. Insert follow row (idempotent)
  await pool.query(
    `INSERT INTO connect.social_relationships (actor_id, target_id, connection_type)
     VALUES ($1, $2, 'follow')
     ON CONFLICT (actor_id, target_id, connection_type) DO NOTHING`,
    [actorId, targetId]
  );
}

// ---------------------------------------------------------------------------
// unfollow
// ---------------------------------------------------------------------------

/**
 * Unfollow a previously followed account.
 *
 * Idempotent — no error if the user is not currently following.
 */
export async function unfollow(actorId: string, targetId: string): Promise<void> {
  await pool.query(
    `DELETE FROM connect.social_relationships
     WHERE actor_id = $1 AND target_id = $2 AND connection_type = 'follow'`,
    [actorId, targetId]
  );
}

// ---------------------------------------------------------------------------
// getConnections
// ---------------------------------------------------------------------------

/**
 * Return the authenticated user's peer connections (pending and accepted).
 *
 * Excludes blocked and declined rows. Includes direction (inbound/outbound)
 * for pending requests so the client can show appropriate UI.
 */
export async function getConnections(userId: string): Promise<
  Array<{
    id: string;
    peer_id: string;
    display_name: string | null;
    status: string;
    direction: string;
    created_at: string;
  }>
> {
  const { rows } = await pool.query(
    `SELECT
       sr.id,
       CASE WHEN sr.actor_id = $1 THEN sr.target_id ELSE sr.actor_id END AS peer_id,
       up.display_name,
       sr.status,
       CASE WHEN sr.actor_id = $1 THEN 'outbound' ELSE 'inbound' END AS direction,
       sr.created_at
     FROM connect.social_relationships sr
     JOIN public.users_public up
       ON up.id = CASE WHEN sr.actor_id = $1 THEN sr.target_id ELSE sr.actor_id END
     WHERE sr.connection_type = 'peer'
       AND (sr.actor_id = $1 OR sr.target_id = $1)
       AND sr.status IN ('pending', 'accepted')
     ORDER BY sr.updated_at DESC`,
    [userId]
  );
  return rows;
}

// ---------------------------------------------------------------------------
// getFollowing
// ---------------------------------------------------------------------------

/**
 * Return the list of Empowered accounts the user is following.
 */
export async function getFollowing(userId: string): Promise<
  Array<{
    id: string;
    target_id: string;
    display_name: string | null;
    created_at: string;
  }>
> {
  const { rows } = await pool.query(
    `SELECT sr.id, sr.target_id, up.display_name, sr.created_at
     FROM connect.social_relationships sr
     JOIN public.users_public up ON up.id = sr.target_id
     WHERE sr.actor_id = $1 AND sr.connection_type = 'follow'
     ORDER BY sr.created_at DESC`,
    [userId]
  );
  return rows;
}

// ---------------------------------------------------------------------------
// getFollowerCount
// ---------------------------------------------------------------------------

/**
 * Return the follower count for a user.
 *
 * Public for Empowered users — the route handler validates the target is
 * Empowered before calling this function.
 */
export async function getFollowerCount(userId: string): Promise<number> {
  const { rows } = await pool.query(
    `SELECT COUNT(*)::int AS count
     FROM connect.social_relationships
     WHERE target_id = $1 AND connection_type = 'follow'`,
    [userId]
  );
  return rows[0]?.count ?? 0;
}
