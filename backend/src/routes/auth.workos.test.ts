import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import cookieParser from 'cookie-parser';
import request from 'supertest';

// auth.ts imports db/supabase/authService at module scope — mock them so env
// validation does not process.exit in test (mirrors seasonsAdmin.test.ts).
// Also neuter the rate limiter: this file calls the limited endpoints >10 times,
// which would otherwise trip the 10/15-min limiter and 429 later assertions.
vi.mock('express-rate-limit', () => ({
  default: () => (_req: unknown, _res: unknown, next: () => void) => next(),
}));
vi.mock('../lib/db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, adminRpc: vi.fn() }));
vi.mock('../lib/env.js', () => ({
  env: { NODE_ENV: 'test', COOKIE_DOMAIN: '', AUTHKIT_PRIMARY: 'true', LOGIN_URL: 'https://login.empowered.vote' },
}));
vi.mock('../lib/authService.js', () => ({
  signUpWithEmail: vi.fn(), signInWithEmail: vi.fn(), signOutUser: vi.fn(), recordLogout: vi.fn(),
}));
vi.mock('../lib/emailService.js', () => ({ sendEmail: vi.fn() }));
vi.mock('../lib/enrollService.js', () => ({ completeOnboarding: vi.fn() }));
vi.mock('../lib/adminService.js', () => ({ insertAccessRequest: vi.fn() }));
vi.mock('../lib/workosProvisionService.js', () => ({ provisionWorkosUser: vi.fn(), signUpWorkosFirst: vi.fn() }));
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
  verifyWorkosAccessToken: vi.fn(),
}));

const { authSvc } = vi.hoisted(() => ({
  authSvc: {
    authenticateWithPassword: vi.fn(),
    authenticateWithEmailCode: vi.fn(),
    refreshWorkosSession: vi.fn(),
    sendWorkosPasswordReset: vi.fn(),
    confirmWorkosPasswordReset: vi.fn(),
  },
}));
vi.mock('../lib/workosAuthService.js', () => authSvc);

import authRouter from './auth.js';

const app = express();
app.use(express.json());
app.use(cookieParser());
app.use('/api/auth', authRouter);

beforeEach(() => { for (const fn of Object.values(authSvc)) fn.mockReset(); });

describe('POST /api/auth/workos/authenticate', () => {
  it('sets the ev_wos_session cookie and returns the access token on success', async () => {
    authSvc.authenticateWithPassword.mockResolvedValueOnce({
      status: 'authenticated', accessToken: 'at', refreshToken: 'rt',
    });
    const res = await request(app)
      .post('/api/auth/workos/authenticate')
      .send({ email: 'a@b.com', password: 'password1' });
    expect(res.status).toBe(200);
    expect(res.body.access_token).toBe('at');
    // res.headers['set-cookie'] types as `string` in @types/superagent even
    // though multiple Set-Cookie headers arrive as an array at runtime; the
    // typed overload of res.get('Set-Cookie') avoids the tsc mismatch.
    const cookies = (res.get('Set-Cookie') ?? []).join(';');
    expect(cookies).toContain('ev_wos_session=rt');
    expect(cookies).toContain('HttpOnly');
  });

  it('returns a pending status + pending cookie when verification is required', async () => {
    authSvc.authenticateWithPassword.mockResolvedValueOnce({
      status: 'email_verification_required', pendingToken: 'pat_1',
    });
    const res = await request(app)
      .post('/api/auth/workos/authenticate')
      .send({ email: 'a@b.com', password: 'password1' });
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'email_verification_required' });
    expect((res.get('Set-Cookie') ?? []).join(';')).toContain('ev_wos_pending=pat_1');
    expect(res.body.access_token).toBeUndefined();
  });

  it('returns 401 INVALID_CREDENTIALS on bad password (no field distinction)', async () => {
    authSvc.authenticateWithPassword.mockResolvedValueOnce({ status: 'invalid_credentials' });
    const res = await request(app)
      .post('/api/auth/workos/authenticate')
      .send({ email: 'a@b.com', password: 'wrongpassword' });
    expect(res.status).toBe(401);
    expect(res.body).toEqual({ code: 'INVALID_CREDENTIALS', message: 'Invalid email or password' });
  });

  it('rejects a malformed body with 422', async () => {
    const res = await request(app).post('/api/auth/workos/authenticate').send({ email: 'x' });
    expect(res.status).toBe(422);
  });
});

describe('POST /api/auth/workos/verify-email', () => {
  it('verifies the code from the pending cookie and starts a session', async () => {
    authSvc.authenticateWithEmailCode.mockResolvedValueOnce({
      status: 'authenticated', accessToken: 'at', refreshToken: 'rt',
    });
    const res = await request(app)
      .post('/api/auth/workos/verify-email')
      .set('Cookie', 'ev_wos_pending=pat_1')
      .send({ code: '123456' });
    expect(res.status).toBe(200);
    expect(res.body.access_token).toBe('at');
    expect(authSvc.authenticateWithEmailCode).toHaveBeenCalledWith('123456', 'pat_1');
    const cookies = (res.get('Set-Cookie') ?? []).join(';');
    expect(cookies).toContain('ev_wos_session=rt');
    expect(cookies).toContain('ev_wos_pending=;'); // cleared
  });

  it('400s when there is no pending cookie', async () => {
    const res = await request(app).post('/api/auth/workos/verify-email').send({ code: '123456' });
    expect(res.status).toBe(400);
    expect(res.body.code).toBe('NO_PENDING_AUTH');
  });

  it('401s on a wrong code', async () => {
    authSvc.authenticateWithEmailCode.mockResolvedValueOnce({ status: 'invalid_credentials' });
    const res = await request(app)
      .post('/api/auth/workos/verify-email')
      .set('Cookie', 'ev_wos_pending=pat_1')
      .send({ code: '000000' });
    expect(res.status).toBe(401);
    expect(res.body.code).toBe('INVALID_CODE');
  });
});

describe('GET /api/auth/session — WorkOS branch', () => {
  it('refreshes and rotates the ev_wos_session cookie when present', async () => {
    authSvc.refreshWorkosSession.mockResolvedValueOnce({
      status: 'authenticated', accessToken: 'at_new', refreshToken: 'rt_new',
    });
    const res = await request(app).get('/api/auth/session').set('Cookie', 'ev_wos_session=rt_old');
    expect(res.status).toBe(200);
    expect(res.body.access_token).toBe('at_new');
    expect(authSvc.refreshWorkosSession).toHaveBeenCalledWith('rt_old');
    expect((res.get('Set-Cookie') ?? []).join(';')).toContain('ev_wos_session=rt_new');
  });

  it('clears the cookie and 401s when the WorkOS refresh fails', async () => {
    authSvc.refreshWorkosSession.mockResolvedValueOnce({ status: 'error', code: 'WORKOS_ERROR' });
    const res = await request(app).get('/api/auth/session').set('Cookie', 'ev_wos_session=rt_dead');
    expect(res.status).toBe(401);
    expect((res.get('Set-Cookie') ?? []).join(';')).toContain('ev_wos_session=;');
  });

  it('401s with no cookie at all', async () => {
    const res = await request(app).get('/api/auth/session');
    expect(res.status).toBe(401);
  });
});

describe('WorkOS-aware logout + password reset (AUTHKIT_PRIMARY)', () => {
  it('logout clears both session cookies', async () => {
    const res = await request(app).post('/api/auth/logout').set('Cookie', 'ev_wos_session=rt');
    expect(res.status).toBe(200);
    const cookies = (res.get('Set-Cookie') ?? []).join(';');
    expect(cookies).toContain('ev_session=;');
    expect(cookies).toContain('ev_wos_session=;');
    expect(cookies).toContain('ev_wos_pending=;');
  });

  it('forgot-password routes to WorkOS and still always 200s', async () => {
    authSvc.sendWorkosPasswordReset.mockResolvedValueOnce({ ok: true });
    const res = await request(app).post('/api/auth/forgot-password').send({ email: 'a@b.com' });
    expect(res.status).toBe(200);
    expect(authSvc.sendWorkosPasswordReset).toHaveBeenCalledWith('a@b.com');
  });

  it('reset-password confirms through WorkOS', async () => {
    authSvc.confirmWorkosPasswordReset.mockResolvedValueOnce({ ok: true });
    const res = await request(app)
      .post('/api/auth/reset-password')
      .send({ token_hash: 'tok_1', password: 'newpassword1' });
    expect(res.status).toBe(200);
    expect(authSvc.confirmWorkosPasswordReset).toHaveBeenCalledWith('tok_1', 'newpassword1');
  });

  it('reset-password success clears the WorkOS session cookies (a reset revokes all sessions)', async () => {
    authSvc.confirmWorkosPasswordReset.mockResolvedValueOnce({ ok: true });
    const res = await request(app)
      .post('/api/auth/reset-password')
      .set('Cookie', ['ev_wos_session=rt', 'ev_wos_pending=pat_1'])
      .send({ token_hash: 'tok_1', password: 'newpassword1' });
    expect(res.status).toBe(200);
    const cookies = (res.get('Set-Cookie') ?? []).join(';');
    expect(cookies).toContain('ev_wos_session=;');
    expect(cookies).toContain('ev_wos_pending=;');
  });
});
