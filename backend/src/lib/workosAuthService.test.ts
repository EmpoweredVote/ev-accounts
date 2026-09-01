import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';

vi.mock('./env.js', () => ({
  env: { WORKOS_CLIENT_ID: 'client_TEST', WORKOS_API_KEY: 'sk_test_123', LOGIN_URL: 'https://login.empowered.vote' },
}));
vi.mock('./emailService.js', () => ({ sendEmail: vi.fn() }));

import { authenticateWithPassword, authenticateWithEmailCode, refreshWorkosSession, sendWorkosPasswordReset, confirmWorkosPasswordReset } from './workosAuthService.js';
import { sendEmail } from './emailService.js';

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

  it('returns WORKOS_ERROR when fetch rejects with a network error', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockRejectedValueOnce(new Error('network down'));
    const out = await authenticateWithPassword('a@b.com', 'pw');
    expect(out).toEqual({ status: 'error', code: 'WORKOS_ERROR' });
  });
});

describe('authenticateWithEmailCode', () => {
  beforeEach(() => vi.stubGlobal('fetch', vi.fn()));
  afterEach(() => vi.unstubAllGlobals());

  it('sends the email-verification code grant with the pending token', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce(
      okJson({ access_token: 'at2', refresh_token: 'rt2' })
    );
    const out = await authenticateWithEmailCode('123456', 'pat_1');
    expect(out).toEqual({ status: 'authenticated', accessToken: 'at2', refreshToken: 'rt2' });
    const sent = JSON.parse((fetch as ReturnType<typeof vi.fn>).mock.calls[0][1].body);
    expect(sent).toMatchObject({
      grant_type: 'urn:workos:oauth:grant-type:email-verification:code',
      code: '123456',
      pending_authentication_token: 'pat_1',
    });
  });

  it('maps a wrong/expired code (invalid_one_time_code) to invalid_credentials, not an error', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce(
      errJson(400, { code: 'invalid_one_time_code', message: 'Invalid one-time code' })
    );
    const out = await authenticateWithEmailCode('000000', 'pat_1');
    expect(out).toEqual({ status: 'invalid_credentials' });
  });
});

describe('refreshWorkosSession', () => {
  beforeEach(() => vi.stubGlobal('fetch', vi.fn()));
  afterEach(() => vi.unstubAllGlobals());

  it('sends the refresh_token grant and returns rotated tokens', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce(
      okJson({ access_token: 'at3', refresh_token: 'rt3' })
    );
    const out = await refreshWorkosSession('rt_old');
    expect(out).toEqual({ status: 'authenticated', accessToken: 'at3', refreshToken: 'rt3' });
    const sent = JSON.parse((fetch as ReturnType<typeof vi.fn>).mock.calls[0][1].body);
    expect(sent).toMatchObject({ grant_type: 'refresh_token', refresh_token: 'rt_old' });
  });

  it('surfaces a failed refresh as an error, not a throw', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce(
      errJson(400, { code: 'invalid_grant' })
    );
    const out = await refreshWorkosSession('rt_dead');
    expect(out.status === 'invalid_credentials' || out.status === 'error').toBe(true);
  });
});

describe('password reset', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
    vi.mocked(sendEmail).mockClear();
  });
  afterEach(() => vi.unstubAllGlobals());

  it('sends the reset via the API key and emails OUR OWN login.empowered.vote link', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce(okJson({ id: 'pwr_1', password_reset_token: 'prt_1' }));
    const out = await sendWorkosPasswordReset('a@b.com');
    expect(out).toEqual({ ok: true });
    const [url, init] = (fetch as ReturnType<typeof vi.fn>).mock.calls[0];
    expect(url).toBe('https://api.workos.com/user_management/password_reset');
    expect((init as RequestInit).headers).toMatchObject({ Authorization: 'Bearer sk_test_123' });
    expect(JSON.parse((init as RequestInit).body as string)).toEqual({ email: 'a@b.com' });
    // We email our OWN link built from the returned token — never WorkOS's hosted URL.
    expect(sendEmail).toHaveBeenCalledTimes(1);
    const emailArg = (sendEmail as ReturnType<typeof vi.fn>).mock.calls[0][0];
    expect(emailArg.to).toBe('a@b.com');
    expect(emailArg.html).toContain('https://login.empowered.vote/reset-password?token_hash=prt_1');
  });

  it('confirms a reset with token + new password', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce(okJson({ user: { id: 'user_1' } }));
    const out = await confirmWorkosPasswordReset('tok_1', 'newpassword1');
    expect(out).toEqual({ ok: true });
    const [url, init] = (fetch as ReturnType<typeof vi.fn>).mock.calls[0];
    expect(url).toBe('https://api.workos.com/user_management/password_reset/confirm');
    expect(JSON.parse((init as RequestInit).body as string)).toEqual({
      token: 'tok_1',
      new_password: 'newpassword1',
    });
  });

  it('maps a bad/expired token to INVALID_TOKEN', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce(
      errJson(400, { code: 'password_reset_token_invalid' })
    );
    const out = await confirmWorkosPasswordReset('tok_bad', 'newpassword1');
    expect(out).toEqual({ ok: false, code: 'INVALID_TOKEN' });
  });

  it('treats a 404 (user not found) as success AND sends no email (no enumeration)', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce(errJson(404, { code: 'not_found' }));
    const out = await sendWorkosPasswordReset('nonexistent@b.com');
    expect(out).toEqual({ ok: true });
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it('maps a weak password error to WEAK_PASSWORD', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce(errJson(400, { code: 'invalid_password' }));
    const out = await confirmWorkosPasswordReset('tok_1', 'weak');
    expect(out).toEqual({ ok: false, code: 'WEAK_PASSWORD' });
  });

  it('returns WORKOS_ERROR when the reset-send fetch rejects', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockRejectedValueOnce(new Error('network down'));
    const out = await sendWorkosPasswordReset('a@b.com');
    expect(out).toEqual({ ok: false, code: 'WORKOS_ERROR' });
  });

  it('returns WORKOS_ERROR when the reset-confirm fetch rejects', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockRejectedValueOnce(new Error('network down'));
    const out = await confirmWorkosPasswordReset('tok_1', 'newpassword1');
    expect(out).toEqual({ ok: false, code: 'WORKOS_ERROR' });
  });
});
