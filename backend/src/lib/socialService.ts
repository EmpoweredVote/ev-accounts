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

import { supabaseAdmin, adminRpc } from './supabase.js';

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
  const { data, error } = await supabaseAdmin
    .schema('connect')
    .from('social_relationships')
    .update({ status: 'accepted', updated_at: new Date().toISOString() })
    .eq('id', requestId)
    .eq('target_id', userId)
    .eq('connection_type', 'peer')
    .eq('status', 'pending')
    .select('id');

  if (error) throw new Error(error.message);

  if (!data || data.length === 0) {
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
  const { data, error } = await supabaseAdmin
    .schema('connect')
    .from('social_relationships')
    .update({ status: 'declined', updated_at: new Date().toISOString() })
    .eq('id', requestId)
    .eq('target_id', userId)
    .eq('connection_type', 'peer')
    .eq('status', 'pending')
    .select('id');

  if (error) throw new Error(error.message);

  if (!data || data.length === 0) {
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
 * Delegates to the block_user SECURITY DEFINER RPC which:
 * - If a peer relationship already exists (either direction), updates it to blocked
 *   with the blocker always recorded as actor_id.
 * - If no relationship exists, inserts a new blocked row.
 * - Removes any follow relationships between the two users (either direction).
 */
export async function blockUser(actorId: string, targetId: string): Promise<void> {
  const { error } = await adminRpc('block_user', {
    p_actor_id: actorId,
    p_target_id: targetId,
  });

  if (error) throw new Error(error.message);
}

// ---------------------------------------------------------------------------
// follow
// ---------------------------------------------------------------------------

/**
 * Follow an Empowered account.
 *
 * Delegates to follow_user RPC which validates:
 * 1. Target must be an active Empowered account
 * 2. No block exists between actor and target in either direction
 *
 * ON CONFLICT DO NOTHING makes follow idempotent — following twice is not an error.
 */
export async function follow(actorId: string, targetId: string): Promise<void> {
  const { error } = await adminRpc('follow_user', {
    p_actor_id: actorId,
    p_target_id: targetId,
  });

  if (error) {
    if (error.message === 'NOT_EMPOWERED') {
      throw Object.assign(new Error('Can only follow Empowered accounts'), {
        code: 'NOT_EMPOWERED',
      });
    }
    if (error.message === 'BLOCKED') {
      throw Object.assign(new Error('A block exists between these users'), { code: 'BLOCKED' });
    }
    throw new Error(error.message);
  }
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
  const { error } = await supabaseAdmin
    .schema('connect')
    .from('social_relationships')
    .delete()
    .eq('actor_id', actorId)
    .eq('target_id', targetId)
    .eq('connection_type', 'follow');

  if (error) throw new Error(error.message);
}

// ---------------------------------------------------------------------------
// getConnections
// ---------------------------------------------------------------------------

/**
 * Return the authenticated user's peer connections (pending and accepted).
 *
 * Excludes blocked and declined rows. Includes direction (inbound/outbound)
 * for pending requests so the client can show appropriate UI.
 *
 * Delegates to get_connections RPC which handles the CASE expressions and JOIN
 * with users_public.
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
  const { data, error } = await adminRpc('get_connections', {
    p_user_id: userId,
  });

  if (error) throw new Error(error.message);

  return ((data ?? []) as Array<{
    id: string;
    peer_id: string;
    display_name: string | null;
    status: string;
    direction: string;
    created_at: string;
  }>);
}

// ---------------------------------------------------------------------------
// getFollowing
// ---------------------------------------------------------------------------

/**
 * Return the list of Empowered accounts the user is following.
 *
 * Delegates to get_following RPC which handles the JOIN with users_public.
 */
export async function getFollowing(userId: string): Promise<
  Array<{
    id: string;
    target_id: string;
    display_name: string | null;
    created_at: string;
  }>
> {
  const { data, error } = await adminRpc('get_following', {
    p_user_id: userId,
  });

  if (error) throw new Error(error.message);

  return ((data ?? []) as Array<{
    id: string;
    target_id: string;
    display_name: string | null;
    created_at: string;
  }>);
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
  const { count, error } = await supabaseAdmin
    .schema('connect')
    .from('social_relationships')
    .select('*', { count: 'exact', head: true })
    .eq('target_id', userId)
    .eq('connection_type', 'follow');

  if (error) throw new Error(error.message);

  return count ?? 0;
}
