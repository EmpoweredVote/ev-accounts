import { describe, it, expect, vi } from 'vitest';

const rpc = vi.hoisted(() => vi.fn());
vi.mock('./supabase.js', () => ({ adminRpc: rpc, supabaseAdmin: {} }));
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));

import { getAccountDetail } from './adminService.js';

describe('getAccountDetail — name stays vaulted', () => {
  it('strips legal_name from the nested connected_profile', async () => {
    rpc.mockImplementation((fn: string) =>
      fn === 'admin_get_account_detail'
        ? Promise.resolve({
            data: {
              user_id: 'u1',
              connected_profile: { legal_name: 'Ada Lovelace', tolerance_rating: 3 },
              empowered_profile: { legal_name: 'Ada Lovelace' },
            },
            error: null,
          })
        : Promise.resolve({ data: [], error: null })
    );
    const detail = (await getAccountDetail('u1')) as Record<string, any>;
    expect('legal_name' in (detail.connected_profile ?? {})).toBe(false);
    expect(detail.connected_profile.tolerance_rating).toBe(3);
    expect(detail.empowered_profile.legal_name).toBe('Ada Lovelace');
  });
});
