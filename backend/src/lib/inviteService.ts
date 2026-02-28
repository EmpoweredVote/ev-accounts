/**
 * inviteService — invite code generation and atomic claim operations.
 *
 * WHY THIS FILE EXISTS:
 * The project architecture test enforces that no file in src/routes/ may
 * reference supabaseAdmin directly. This is a security/clarity constraint:
 * routes should operate via RLS-enforced user clients, not bypass all policies
 * with the service role key.
 *
 * Invite operations are a legitimate exception because they require writes to
 * connect.invite_codes and connect.invite_chains — tables that have NO RLS
 * INSERT/UPDATE grants for authenticated users (by design). These writes must
 * go through the service layer using supabaseAdmin (for both transactional RPC
 * and non-transactional reads). That exception lives here in src/lib/, not in
 * src/routes/. Route files import these named functions and never touch
 * supabaseAdmin directly.
 *
 * claimInviteCode delegates to the claim_invite_code SECURITY DEFINER RPC
 * which uses FOR UPDATE locking to ensure two concurrent claim requests for
 * the same code cannot both succeed.
 *
 * createInviteCodes delegates to the create_invite_codes RPC which handles
 * collision retry server-side.
 */

import crypto from 'crypto';
import { supabaseAdmin, adminRpc } from './supabase.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface InviteCode {
  id: string;
  code: string;
  created_by: string | null;
  claimed_by: string | null;
  is_claimed: boolean;
  claimed_at: string | null;
  expires_at: string | null;
  created_at: string;
  updated_at: string;
}

export type ClaimResult =
  | { success: true; inviterId: string | null; codeId: string }
  | { success: false; error: 'INVALID_CODE' | 'CODE_ALREADY_CLAIMED' | 'CODE_EXPIRED' | 'SELF_INVITE_BLOCKED' };

// ---------------------------------------------------------------------------
// Charset — 32 characters: uppercase alpha (no O, I, L) + digits (no 0, 1)
// 256 / 32 = 8 exactly → no modulo bias
// ---------------------------------------------------------------------------

const CHARSET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

// ---------------------------------------------------------------------------
// generateInviteCode
// ---------------------------------------------------------------------------

/**
 * Generate an 8-character invite code in A3B7-XK29 format.
 * Uses crypto.randomBytes for cryptographically secure randomness.
 * The 32-character charset divides evenly into 256 (byte range),
 * so there is no modulo bias in character selection.
 */
export function generateInviteCode(): string {
  const bytes = crypto.randomBytes(16);
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += CHARSET[bytes[i]! % 32];
  }
  return `${code.slice(0, 4)}-${code.slice(4, 8)}`;
}

// ---------------------------------------------------------------------------
// createInviteCodes
// ---------------------------------------------------------------------------

/**
 * Batch-create invite codes for a user.
 * Delegates to the create_invite_codes SECURITY DEFINER RPC which handles
 * collision retry server-side (up to 3 attempts per slot).
 *
 * Returns the generated code strings.
 */
export async function createInviteCodes(userId: string, count: number): Promise<string[]> {
  const { data, error } = await adminRpc('create_invite_codes', {
    p_user_id: userId,
    p_count: count,
  });

  if (error) throw new Error(error.message);

  return ((data ?? []) as string[]);
}

// ---------------------------------------------------------------------------
// getMyInviteCodes
// ---------------------------------------------------------------------------

/**
 * Fetch all invite codes created by this user, ordered newest first.
 * Uses supabaseAdmin for a simple non-transactional read (no locking needed).
 */
export async function getMyInviteCodes(userId: string): Promise<InviteCode[]> {
  const { data, error } = await supabaseAdmin
    .schema('connect')
    .from('invite_codes')
    .select('*')
    .eq('created_by', userId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('[inviteService] getMyInviteCodes error:', error.message);
    throw new Error(`Failed to fetch invite codes: ${error.message}`);
  }

  return (data ?? []) as InviteCode[];
}

// ---------------------------------------------------------------------------
// claimInviteCode
// ---------------------------------------------------------------------------

/**
 * Atomically claim an invite code using the claim_invite_code SECURITY DEFINER RPC.
 *
 * The RPC uses FOR UPDATE locking to serialize concurrent claims on the same code.
 * If two concurrent requests race, the second blocks until the first commits,
 * then reads is_claimed = true and returns CODE_ALREADY_CLAIMED.
 * This prevents double-claim without requiring application-level locking.
 *
 * Returns codeId on success — required by POST /api/connect/start (Plan 03)
 * to record the invite_code_id on the verification_session.
 *
 * Admin-created codes (created_by = NULL) succeed without inserting an
 * invite_chain row — there is no inviter to track.
 */
export async function claimInviteCode(code: string, claimantUserId: string): Promise<ClaimResult> {
  const { data, error } = await adminRpc('claim_invite_code', {
    p_code: code,
    p_claimant_user_id: claimantUserId,
  });

  if (error) throw new Error(error.message);

  const result = data as {
    success: boolean;
    error?: string;
    inviter_id?: string | null;
    code_id?: string;
  };

  if (!result.success) {
    const errorCode = result.error as 'INVALID_CODE' | 'CODE_ALREADY_CLAIMED' | 'CODE_EXPIRED' | 'SELF_INVITE_BLOCKED';
    return { success: false, error: errorCode };
  }

  return {
    success: true,
    inviterId: result.inviter_id ?? null,
    codeId: result.code_id!,
  };
}
