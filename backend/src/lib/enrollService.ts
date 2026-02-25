/**
 * enrollService — email normalization and Tolerance Rating adjustment.
 *
 * WHY THIS FILE EXISTS:
 * The project architecture test enforces that no file in src/routes/ may
 * reference supabaseAdmin directly. TR adjustment requires calling a
 * SECURITY DEFINER RPC function in the connect schema — an operation that
 * must bypass RLS and use the service role key. That call lives here in
 * src/lib/, not in src/routes/.
 *
 * normalizeEmail is a pure utility (no DB calls) that strips plus-addressing
 * so that user+tag@gmail.com and user@gmail.com are treated as the same
 * identity. This is used at signup to prevent duplicate account creation via
 * Gmail subaddressing.
 *
 * adjustInviterToleranceRating calls the connect.adjust_inviter_tolerance_rating
 * RPC function, which decrements the inviter's TR by 0.10 (floor 0.00) and
 * auto-suspends at 0. The function is FIRE-AND-FORGET from the caller's
 * perspective: errors are logged but not re-thrown, so a TR adjustment failure
 * never blocks the enrollment operation that triggered it.
 */

import { supabaseAdmin } from './supabase.js';

// ---------------------------------------------------------------------------
// normalizeEmail
// ---------------------------------------------------------------------------

/**
 * Normalize an email address for uniqueness comparison:
 * - Lowercase and trim whitespace
 * - Strip plus-addressing (user+tag@example.com → user@example.com)
 *
 * This prevents duplicate accounts via Gmail-style subaddressing tricks.
 */
export function normalizeEmail(email: string): string {
  const [local, domain] = email.toLowerCase().trim().split('@') as [string, string];
  return `${local.split('+')[0]}@${domain}`;
}

// ---------------------------------------------------------------------------
// adjustInviterToleranceRating
// ---------------------------------------------------------------------------

/**
 * Call the connect.adjust_inviter_tolerance_rating Postgres RPC function.
 *
 * This is triggered when an invitee is sanctioned. The RPC:
 * - Looks up the inviter via invite_chains
 * - Decrements their tolerance_rating by 0.10 (floor = 0.00)
 * - Auto-suspends their connected profile if TR reaches 0.00
 * - Inserts a notification_events record to inform the inviter
 *
 * Errors are logged but not re-thrown. TR adjustment failure must not
 * block the sanction operation that triggered this call.
 */
export async function adjustInviterToleranceRating(inviteeId: string): Promise<void> {
  const { error } = await supabaseAdmin
    .schema('connect')
    .rpc('adjust_inviter_tolerance_rating', { p_invitee_id: inviteeId });

  if (error) {
    console.error(
      '[enrollService] adjustInviterToleranceRating failed for invitee',
      inviteeId,
      ':',
      error.message,
    );
    // Intentionally not throwing — caller must not be blocked by TR adjustment failure
  }
}
