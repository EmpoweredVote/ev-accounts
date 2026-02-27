/**
 * gemService — gem ledger operations (credit, debit, balance, transaction history).
 *
 * WHY THIS FILE EXISTS:
 * The architecture test enforces that no file in src/routes/ may reference
 * supabaseAdmin directly. Gem credit and debit operations both require calling
 * SECURITY DEFINER RPC functions in the connect schema — operations that must
 * bypass RLS and use the service role key. Those calls live here in src/lib/,
 * not in src/routes/.
 *
 * ATOMICITY:
 * creditGems and debitGems are entirely handled by Postgres RPC functions
 * (credit_gems, debit_gems). The RPCs maintain gem_balance_red/blue/yellow
 * on connected_profiles atomically with the ledger insert. No chained JS
 * awaits for multi-table writes.
 */

import { supabaseAdmin } from './supabase.js';
import { pool } from './db.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type GemType = 'red' | 'blue' | 'yellow';

// ---------------------------------------------------------------------------
// creditGems
// ---------------------------------------------------------------------------

/**
 * Credit gems to a user's account via the credit_gems SECURITY DEFINER RPC.
 *
 * Caller-agnostic: cron jobs, inline route handlers, and future event workers
 * all use this function.
 */
export async function creditGems(
  userId: string,
  gemType: GemType,
  amount: number,
  transactionType: string,
  sourceRef?: string
): Promise<void> {
  const { error } = await supabaseAdmin.schema('connect').rpc('credit_gems', {
    p_user_id: userId,
    p_gem_type: gemType,
    p_amount: amount,
    p_transaction_type: transactionType,
    p_source_ref: sourceRef ?? null,
  });

  if (error) {
    throw new Error(error.message);
  }
}

// ---------------------------------------------------------------------------
// debitGems
// ---------------------------------------------------------------------------

/**
 * Debit gems from a user's account via the debit_gems SECURITY DEFINER RPC.
 *
 * Throws INSUFFICIENT_BALANCE if the balance would go negative.
 */
export async function debitGems(
  userId: string,
  gemType: GemType,
  amount: number,
  transactionType: string,
  sourceRef?: string
): Promise<void> {
  const { error } = await supabaseAdmin.schema('connect').rpc('debit_gems', {
    p_user_id: userId,
    p_gem_type: gemType,
    p_amount: amount,
    p_transaction_type: transactionType,
    p_source_ref: sourceRef ?? null,
  });

  if (error) {
    if (error.message.includes('INSUFFICIENT_BALANCE')) {
      throw Object.assign(new Error('Insufficient gem balance'), { code: 'INSUFFICIENT_BALANCE' });
    }
    throw new Error(error.message);
  }
}

// ---------------------------------------------------------------------------
// getBalance
// ---------------------------------------------------------------------------

/**
 * Return the current gem balances for a user from connected_profiles.
 *
 * Uses pool (not supabaseAdmin) — server-side computation, same pattern as
 * compassService.ts getCompassCompleteness. The denormalized balance columns
 * are maintained atomically by the credit/debit RPCs.
 */
export async function getBalance(
  userId: string
): Promise<{ red: number; blue: number; yellow: number }> {
  const { rows } = await pool.query<{
    gem_balance_red: number;
    gem_balance_blue: number;
    gem_balance_yellow: number;
  }>(
    'SELECT gem_balance_red, gem_balance_blue, gem_balance_yellow FROM connect.connected_profiles WHERE user_id = $1',
    [userId]
  );

  if (rows.length === 0) {
    throw Object.assign(new Error('No connected profile found for user'), {
      code: 'PROFILE_NOT_FOUND',
    });
  }

  const row = rows[0]!;
  return {
    red: row.gem_balance_red,
    blue: row.gem_balance_blue,
    yellow: row.gem_balance_yellow,
  };
}

// ---------------------------------------------------------------------------
// getTransactionHistory
// ---------------------------------------------------------------------------

/**
 * Return paginated gem transaction history for a user.
 *
 * Supports optional filtering by gem_type and pagination via limit/offset.
 */
export async function getTransactionHistory(
  userId: string,
  options?: { limit?: number; offset?: number; gemType?: GemType }
): Promise<{ transactions: unknown[]; total: number }> {
  const limit = Math.min(options?.limit ?? 50, 100);
  const offset = options?.offset ?? 0;

  const params: unknown[] = [userId];
  let whereClause = 'WHERE user_id = $1';

  if (options?.gemType) {
    params.push(options.gemType);
    whereClause += ` AND gem_type = $${params.length}`;
  }

  // Main query
  params.push(limit, offset);
  const { rows: transactions } = await pool.query(
    `SELECT id, gem_type, amount, transaction_type, feature_context, reference_id, balance_after, created_at
     FROM connect.gem_transactions
     ${whereClause}
     ORDER BY created_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  // Count query (reuse params without limit/offset)
  const countParams = params.slice(0, params.length - 2);
  const { rows: countRows } = await pool.query(
    `SELECT COUNT(*)::int AS count FROM connect.gem_transactions ${whereClause}`,
    countParams
  );

  return {
    transactions,
    total: countRows[0]?.count ?? 0,
  };
}
