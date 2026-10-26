import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery, mockCreateUser, mockAutoName } = vi.hoisted(() => ({
  mockQuery: vi.fn(),
  mockCreateUser: vi.fn(),
  mockAutoName: vi.fn(),
}));

vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));
vi.mock('./env.js', () => ({ env: { WORKOS_API_KEY: 'sk_test' } }));
vi.mock('./supabase.js', () => ({ supabaseAdmin: { auth: { admin: { createUser: mockCreateUser } } } }));
vi.mock('./displayName.js', () => ({ generateUniqueAutoName: mockAutoName }));

import { provisionWorkosUser } from './workosProvisionService.js';

const NEW_ID = '11111111-1111-1111-1111-111111111111';

function stubWorkos(user: Record<string, unknown>) {
  vi.stubGlobal('fetch', vi.fn(async (_url: string, init?: { method?: string }) => {
    if (!init?.method) return new Response(JSON.stringify(user), { status: 200 });
    return new Response('{}', { status: 200 }); // PUT external_id
  }));
}

function displayNameWrites(): unknown[][] {
  return mockQuery.mock.calls.filter(([sql]) => /SET display_name/.test(String(sql)));
}

describe('provisionWorkosUser display name', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockQuery.mockResolvedValue({ rows: [] }); // no existing internal user; updates succeed
    mockCreateUser.mockResolvedValue({ data: { user: { id: NEW_ID } }, error: null });
    mockAutoName.mockResolvedValue('QuietHeron');
  });

  it('never copies the WorkOS first/last name into the public display name', async () => {
    stubWorkos({
      id: 'user_01', email: 'a@example.com', email_verified: true,
      first_name: 'Jane', last_name: 'Doe', external_id: null,
    });
    const res = await provisionWorkosUser('user_01');
    expect(res).toEqual({ ok: true, userId: NEW_ID, created: true });
    const writes = displayNameWrites();
    expect(writes).toHaveLength(1);
    expect(writes[0][1]).toEqual([NEW_ID, 'QuietHeron']);
    expect(JSON.stringify(mockQuery.mock.calls)).not.toMatch(/Jane|Doe/);
  });

  it('still mints a pseudonym when WorkOS has no name', async () => {
    stubWorkos({
      id: 'user_02', email: 'b@example.com', email_verified: true,
      first_name: null, last_name: null, external_id: null,
    });
    await provisionWorkosUser('user_02');
    expect(displayNameWrites()[0][1]).toEqual([NEW_ID, 'QuietHeron']);
  });
});
