import { describe, it, expect, vi } from 'vitest';

const rpc = vi.hoisted(() => vi.fn());
vi.mock('./supabase.js', () => ({ adminRpc: rpc, supabaseAdmin: {} }));
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));

import { getAccountDetail } from './adminService.js';

describe('getAccountDetail — name stays vaulted', () => {
  it('strips legal_name from the returned detail', async () => {
    rpc.mockImplementation((fn: string) =>
      fn === 'admin_get_account_detail'
        ? Promise.resolve({ data: { user_id: 'u1', legal_name: 'Ada Lovelace', tolerance_rating: 3 }, error: null })
        : Promise.resolve({ data: [], error: null })
    );
    const detail = await getAccountDetail('u1');
    expect('legal_name' in detail).toBe(false);
    expect(detail.tolerance_rating).toBe(3);
  });
});
