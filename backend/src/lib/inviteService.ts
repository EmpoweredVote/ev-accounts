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
 * go through the service layer using either the pg pool (for atomic transactions)
 * or supabaseAdmin (for non-transactional reads). That exception lives here in
 * src/lib/, not in src/routes/. Route files import these named functions and
 * never touch supabaseAdmin or the pool directly.
 *
 * claimInviteCode uses pg pool + BEGIN/FOR UPDATE/COMMIT to ensure that two
 * concurrent claim requests for the same code cannot both succeed — the FOR
 * UPDATE row lock serializes them. supabaseAdmin is used only for the
 * non-transactional getMyInviteCodes read.
 */

import crypto from 'crypto';
import { pool } from './db.js';
import { supabaseAdmin } from './supabase.js';

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
 * Inserts `count` rows into connect.invite_codes via pg pool.
 * Includes retry logic: if a code collides on UNIQUE(code), regenerates
 * and retries up to 3 times per slot.
 *
 * Returns the generated code strings.
 */
export async function createInviteCodes(userId: string, count: number): Promise<string[]> {
  const client = await pool.connect();
  const generatedCodes: string[] = [];

  try {
    for (let i = 0; i < count; i++) {
      let inserted = false;
      let attempts = 0;

      while (!inserted && attempts < 3) {
        const code = generateInviteCode();
        attempts++;

        try {
          await client.query(
            `INSERT INTO connect.invite_codes (code, created_by, expires_at)
             VALUES ($1, $2, now() + interval '30 days')`,
            [code, userId],
          );
          generatedCodes.push(code);
          inserted = true;
        } catch (err: unknown) {
          // PostgreSQL unique violation code: 23505
          const pgErr = err as { code?: string };
          if (pgErr.code === '23505' && attempts < 3) {
            // Code collision — regenerate and retry
            continue;
          }
          throw err;
        }
      }

      if (!inserted) {
        throw new Error(`Failed to insert invite code after 3 collision retries (slot ${i})`);
      }
    }
  } finally {
    client.release();
  }

  return generatedCodes;
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
 * Atomically claim an invite code using a pg transaction with FOR UPDATE locking.
 *
 * The FOR UPDATE lock is intentionally blocking (not NOWAIT). If two concurrent
 * requests race to claim the same code, the second blocks until the first
 * commits, then reads is_claimed = true and returns CODE_ALREADY_CLAIMED.
 * This prevents double-claim without requiring application-level locking.
 *
 * Returns codeId on success — required by POST /api/connect/start (Plan 03)
 * to record the invite_code_id on the verification_session.
 *
 * Admin-created codes (created_by = NULL) succeed without inserting an
 * invite_chain row — there is no inviter to track.
 */
export async function claimInviteCode(code: string, claimantUserId: string): Promise<ClaimResult> {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Lock the row for the duration of this transaction
    const { rows } = await client.query<{
      id: string;
      created_by: string | null;
      is_claimed: boolean;
      expires_at: string | null;
    }>(
      `SELECT id, created_by, is_claimed, expires_at
         FROM connect.invite_codes
        WHERE code = $1
        FOR UPDATE`,
      [code],
    );

    if (rows.length === 0) {
      await client.query('ROLLBACK');
      return { success: false, error: 'INVALID_CODE' };
    }

    const row = rows[0]!;

    if (row.is_claimed) {
      await client.query('ROLLBACK');
      return { success: false, error: 'CODE_ALREADY_CLAIMED' };
    }

    if (row.expires_at !== null && new Date(row.expires_at) < new Date()) {
      await client.query('ROLLBACK');
      return { success: false, error: 'CODE_EXPIRED' };
    }

    if (row.created_by !== null && row.created_by === claimantUserId) {
      await client.query('ROLLBACK');
      return { success: false, error: 'SELF_INVITE_BLOCKED' };
    }

    // Mark the code as claimed
    await client.query(
      `UPDATE connect.invite_codes
          SET is_claimed  = true,
              claimed_by  = $1,
              claimed_at  = now(),
              updated_at  = now()
        WHERE id = $2`,
      [claimantUserId, row.id],
    );

    // Record invite chain only when there is a real inviter (user-created code)
    // Admin-created codes have created_by = NULL — invite_chains.inviter_id is NOT NULL
    if (row.created_by !== null) {
      await client.query(
        `INSERT INTO connect.invite_chains (inviter_id, invitee_id, invite_code_id)
         VALUES ($1, $2, $3)`,
        [row.created_by, claimantUserId, row.id],
      );
    }

    await client.query('COMMIT');

    return {
      success: true,
      inviterId: row.created_by,
      codeId: row.id,
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
