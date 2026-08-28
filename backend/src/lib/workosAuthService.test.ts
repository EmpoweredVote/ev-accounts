import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

vi.mock('./env.js', () => ({
  env: { WORKOS_CLIENT_ID: 'client_TEST', WORKOS_API_KEY: 'sk_test_123' },
}));

import { authenticateWithPassword } from './workosAuthService.js';

function okJson(body: unknown) {
  return { ok: true, status: 200, json: async () => body, text: async () => JSON.stringify(body) };
}
function errJson(status: number, body: unknown) {
  return { ok: false, status, json: async () => body, text: async () => JSON.stringify(body) };
}

describe('authenticateWithPassword', () => {
  beforeEach(() => vi.stubGlobal('fetch', vi.fn()));
  afterEach(() => vi.unstubAllGlobals());

  it('sends the password grant with client credentials and returns tokens', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce(
      okJson({ access_token: 'at', refresh_token: 'rt', user: { id: 'user_1' } })
    );
    const out = await authenticateWithPassword('a@b.com', 'pw', { ipAddress: '1.2.3.4' });
    expect(out).toEqual({ status: 'authenticated', accessToken: 'at', refreshToken: 'rt' });

    const [url, init] = (fetch as ReturnType<typeof vi.fn>).mock.calls[0];
    expect(url).toBe('https://api.workos.com/user_management/authenticate');
    const sent = JSON.parse((init as RequestInit).body as string);
    expect(sent).toMatchObject({
      client_id: 'client_TEST',
      client_secret: 'sk_test_123',
      grant_type: 'password',
      email: 'a@b.com',
      password: 'pw',
      ip_address: '1.2.3.4',
    });
  });

  it('maps email_verification_required to a pending outcome', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce(
      errJson(422, { code: 'email_verification_required', pending_authentication_token: 'pat_1' })
    );
    const out = await authenticateWithPassword('a@b.com', 'pw');
    expect(out).toEqual({ status: 'email_verification_required', pendingToken: 'pat_1' });
  });

  it('maps invalid credentials without leaking which field was wrong', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce(
      errJson(401, { code: 'invalid_credentials' })
    );
    const out = await authenticateWithPassword('a@b.com', 'wrong');
    expect(out).toEqual({ status: 'invalid_credentials' });
  });

  it('returns NOT_CONFIGURED when the API key is absent', async () => {
    vi.resetModules();
    vi.doMock('./env.js', () => ({ env: { WORKOS_CLIENT_ID: 'client_TEST' } }));
    const { authenticateWithPassword: fn } = await import('./workosAuthService.js');
    const out = await fn('a@b.com', 'pw');
    expect(out).toEqual({ status: 'error', code: 'NOT_CONFIGURED' });
    vi.doUnmock('./env.js');
  });
});
