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

import { supabaseAdmin, adminRpc } from './supabase.js';
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
    p_source_ref: sourceRef,
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
    p_source_ref: sourceRef,
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
 * Uses supabaseAdmin for a simple non-transactional read. The denormalized
 * balance columns are maintained atomically by the credit/debit RPCs.
 */
export async function getBalance(
  userId: string
): Promise<{ red: number; blue: number; yellow: number }> {
  const { data, error } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .select('gem_balance_red,gem_balance_blue,gem_balance_yellow')
    .eq('user_id', userId)
    .single();

  if (error) {
    if (error.code === 'PGRST116') {
      throw Object.assign(new Error('No connected profile found for user'), {
        code: 'PROFILE_NOT_FOUND',
      });
    }
    throw new Error(error.message);
  }

  const row = data as {
    gem_balance_red: number;
    gem_balance_blue: number;
    gem_balance_yellow: number;
  };

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

  let query = supabaseAdmin
    .schema('connect')
    .from('gem_transactions')
    .select(
      'id,gem_type,amount,transaction_type,feature_context,reference_id,balance_after,created_at',
      { count: 'exact' }
    )
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (options?.gemType) {
    query = query.eq('gem_type', options.gemType);
  }

  const { data, count, error } = await query;
  if (error) throw new Error(error.message);

  return { transactions: data ?? [], total: count ?? 0 };
}

// ---------------------------------------------------------------------------
// awardGems
// ---------------------------------------------------------------------------

export interface AwardGemsParams {
  userId: string;
  gemType: GemType;
  amount: number;
  idempotencyKey: string;
  transactionType?: string;
  sourceRef?: string;
}

export interface AwardGemsResult {
  gem_type: string;
  amount: number;
  new_balance: number;
  is_duplicate: boolean;
}

// ---------------------------------------------------------------------------
// awardInformYellowGem (private helper)
// ---------------------------------------------------------------------------

/**
 * Award yellow gems to an Inform-tier user via the inform.award_inform_yellow_gem RPC.
 * Called from awardGems() when the user has no connected_profiles row.
 */
async function awardInformYellowGem(params: AwardGemsParams): Promise<AwardGemsResult> {
  const { rows } = await pool.query<{
    gem_type: string;
    amount: number;
    balance_after: number;
    is_duplicate: boolean;
  }>(
    `SELECT gem_type, amount, balance_after, is_duplicate
     FROM inform.award_inform_yellow_gem(
       $1, $2, $3, $4, $5
     )`,
    [
      params.userId,
      params.amount,
      params.idempotencyKey,
      params.transactionType ?? 'service_award',
      params.sourceRef ?? null,
    ]
  );

  const row = rows[0];
  if (!row) {
    throw new Error('award_inform_yellow_gem returned no rows');
  }

  return {
    gem_type: row.gem_type,
    amount: row.amount,
    new_balance: row.balance_after,
    is_duplicate: row.is_duplicate,
  };
}

// ---------------------------------------------------------------------------
// awardGems
// ---------------------------------------------------------------------------

/**
 * Award gems to a user via the award_gems SECURITY DEFINER RPC.
 *
 * Idempotent: duplicate idempotency_key returns the original result with
 * is_duplicate = true and no second ledger row.
 *
 * Called exclusively by POST /api/gems/award (external service endpoint).
 * Internal/cron gem grants continue to use creditGems() → credit_gems RPC.
 *
 * Tier-aware: Inform-tier users (no connected_profiles row) are routed to
 * awardInformYellowGem(). Blue/red gem requests for Inform-tier users throw
 * INFORM_TIER_NO_BLUE_RED.
 *
 * Deleted accounts throw ACCOUNT_DELETED at any tier, for any gem type.
 */
export async function awardGems(params: AwardGemsParams): Promise<AwardGemsResult> {
  // Tier check: Inform-tier users (no connected_profiles row) go to inform-schema RPC.
  // Connected-tier users continue to the existing award_gems RPC.
  //
  // 🔴 DELETION IS ANSWERED SEPARATELY FROM TIER, AND MUST NOT BE FOLDED INTO THE
  // EXISTS. This is the tierGuards trap in a different costume: the EXISTS reads
  // ABSENCE as "Inform", so adding `AND deleted_at IS NULL` to it would make a
  // deleted Connected account look Inform and quietly award it a yellow gem
  // through the inform RPC. The right answer for a deleted account is to refuse,
  // so it is asked as its own question — and asked of public.users, because an
  // Inform-tier account has no connected_profiles row to carry a deleted_at.
  //
  // /gems/award is a service-key route naming an arbitrary user_id in the body,
  // so requireAuth's deleted-account refusal never runs in front of it.
  const { rows: tierRows } = await pool.query<{ is_deleted: boolean; is_connected: boolean }>(
    `SELECT
       EXISTS(
         SELECT 1 FROM public.users u
          WHERE u.id = $1 AND u.deleted_at IS NOT NULL
       ) AS is_deleted,
       EXISTS(
         SELECT 1 FROM connect.connected_profiles
          WHERE user_id = $1 AND deleted_at IS NULL
       ) AS is_connected`,
    [params.userId]
  );

  if (tierRows[0]?.is_deleted === true) {
    throw Object.assign(
      new Error('Account has been deleted'),
      { code: 'ACCOUNT_DELETED' }
    );
  }

  const isConnected = tierRows[0]?.is_connected === true;

  if (!isConnected) {
    if (params.gemType !== 'yellow') {
      throw Object.assign(
        new Error('Inform-tier users can only earn yellow gems'),
        { code: 'INFORM_TIER_NO_BLUE_RED' }
      );
    }
    return awardInformYellowGem(params);
  }

  const { data, error } = await adminRpc(
    'award_gems',
    {
      p_user_id: params.userId,
      p_gem_type: params.gemType,
      p_amount: params.amount,
      p_idempotency_key: params.idempotencyKey,
      p_transaction_type: params.transactionType ?? 'service_award',
      p_source_ref: params.sourceRef ?? null,
    },
    'connect'
  );

  if (error) {
    if (error.message?.includes('no connected_profiles row')) {
      throw Object.assign(new Error('User has no connected profile'), { code: 'NOT_CONNECTED' });
    }
    if (error.message?.includes('must be positive')) {
      throw Object.assign(new Error('Gem award amount must be positive'), { code: 'INVALID_AMOUNT' });
    }
    throw new Error(error.message);
  }

  // award_gems RETURNS TABLE — data is an array; take the first row
  const row = Array.isArray(data) ? data[0] : data;
  if (!row) {
    throw new Error('award_gems returned no rows');
  }

  return {
    gem_type: row.gem_type as string,
    amount: row.amount as number,
    new_balance: row.balance_after as number,
    is_duplicate: row.is_duplicate as boolean,
  };
}
