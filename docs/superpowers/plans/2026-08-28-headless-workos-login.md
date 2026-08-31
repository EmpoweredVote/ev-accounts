# Headless WorkOS Login Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the WorkOS login/verification UI off the hosted `authkit.app` page onto our own `login.empowered.vote`, by calling the WorkOS Authentication API server-side and owning the session in an httpOnly cookie.

**Architecture:** New backend endpoints proxy the WorkOS `authenticate` state machine (password grant → email-verification code grant → refresh grant) using `WORKOS_API_KEY` as the client secret, and store the WorkOS refresh token in a new httpOnly cookie `ev_wos_session` on `.empowered.vote`. `GET /api/auth/session` is taught a WorkOS branch, so every app's existing refresh path works unchanged. The frontend gains an embedded email/password form + on-page 6-digit code step, gated on a new `VITE_EMBEDDED_AUTH` flag; `app/` and validation-quests just redirect to `login.empowered.vote` instead of `authkit.app`.

**Tech Stack:** TypeScript, Express, `jose` (existing), Vitest + Supertest (backend tests), React + Vite (frontends). No new dependencies.

**Design source:** `docs/HEADLESS-LOGIN-DESIGN.md`. **Migration lineage:** ev-cto decision 0002.

## Global Constraints

- **Server-side only for the password/refresh grants.** They send `client_secret` (= `env.WORKOS_API_KEY`). This value must NEVER reach a browser bundle.
- **The one join-key reader stays `backend/src/lib/tokenIdentity.ts`.** Do not read `external_id` or interpret a token `sub` anywhere else. This plan does not touch token verification — headless tokens carry the same issuer/JWKS/`external_id` claim.
- **OWASP enumeration:** wrong email and wrong password both return `{ code: 'INVALID_CREDENTIALS', message: 'Invalid email or password' }`. Never distinguish. `forgot-password` always returns 200.
- **Cookies:** `httpOnly: true`, `secure` in production, `sameSite: 'lax'`, `domain: env.COOKIE_DOMAIN || undefined`, `path: '/'`. Reuse the existing `evSessionCookieOptions()` shape.
- **Flag-gated, reversible.** Nothing changes default behaviour until `VITE_EMBEDDED_AUTH === 'true'` (frontend) / the endpoints are called. `AUTHKIT_PRIMARY` (already live) gates whether the credential is in WorkOS.
- **Do not deploy to production or flip a production flag without explicit approval** (STOP-AND-ASK — same rule as the migration).
- **Test runner:** from `backend/`, `npm test` runs `vitest run`. Single file: `npx vitest run src/lib/workosAuthService.test.ts`.
- **Migrations:** none. This plan writes no SQL.

---

## File Structure

**Backend (`backend/`)**
- Create: `src/lib/workosAuthService.ts` — the ONLY place that calls the WorkOS Authentication API for the headless login flow (`authenticate` password/refresh/email-code grants, `password_reset` send/confirm). Mirrors the existing `src/lib/workosProvisionService.ts` (raw `fetch`, discriminated-union returns).
- Create: `src/lib/workosAuthService.test.ts` — unit tests (mocked `fetch`).
- Modify: `src/routes/auth.ts` — add `POST /workos/authenticate`, `POST /workos/verify-email`; extend `GET /session`, `POST /logout`, `POST /forgot-password`, `POST /reset-password`.
- Create: `src/routes/auth.workos.test.ts` — route tests (Supertest + mocked service).

**Frontend — admin (`admin/`, serves `login.empowered.vote` + `accounts.empowered.vote`)**
- Modify: `src/lib/workosAuth.ts` — add `embeddedAuthEnabled`, `loginWithPassword`, `verifyEmailCode`.
- Modify: `src/pages/Login.tsx` — embedded form + code step under the flag.
- Modify: `src/pages/Signup.tsx` and `src/pages/InformSignup.tsx` — auto-advance to the code step after 201.
- Modify: `src/lib/api.ts` — 401 refresh prefers `/api/auth/session` when embedded.
- Modify: `src/App.tsx` — bootstrap restores via `/api/auth/session` when embedded.

**Frontend — app (`app/`, serves `app.empowered.vote`)**
- Modify: `src/lib/workosAuth.ts` and `src/pages/LoginPage.tsx` — redirect to `login.empowered.vote` under the flag.

**Separate repo (fast-follow):** `empowered-validation-quests` frontend — same redirect change.

**Interface shared by all backend tasks — `workosAuthService.ts` public contract** (Tasks 1–3 build it; Tasks 4–7 consume it):

```ts
export type AuthOutcome =
  | { status: 'authenticated'; accessToken: string; refreshToken: string }
  | { status: 'email_verification_required'; pendingToken: string }
  | { status: 'mfa_required'; pendingToken: string; challengeId: string | null }
  | { status: 'invalid_credentials' }
  | { status: 'error'; code: 'NOT_CONFIGURED' | 'WORKOS_ERROR' };

export type ResetOutcome =
  | { ok: true }
  | { ok: false; code: 'NOT_CONFIGURED' | 'INVALID_TOKEN' | 'WEAK_PASSWORD' | 'WORKOS_ERROR' };

export function authenticateWithPassword(
  email: string, password: string,
  ctx?: { ipAddress?: string; userAgent?: string }
): Promise<AuthOutcome>;
export function authenticateWithEmailCode(code: string, pendingToken: string): Promise<AuthOutcome>;
export function refreshWorkosSession(refreshToken: string): Promise<AuthOutcome>;
export function sendWorkosPasswordReset(email: string): Promise<ResetOutcome>;
export function confirmWorkosPasswordReset(token: string, newPassword: string): Promise<ResetOutcome>;
```

---

### Task 1: WorkOS auth service — password grant + response mapping

**Files:**
- Create: `backend/src/lib/workosAuthService.ts`
- Test: `backend/src/lib/workosAuthService.test.ts`

**Interfaces:**
- Consumes: `env.WORKOS_CLIENT_ID`, `env.WORKOS_API_KEY` (as `client_secret`).
- Produces: `authenticateWithPassword`, and the internal `callAuthenticate` mapping that Tasks 2 relies on. `AuthOutcome` type (see Global contract).

- [ ] **Step 1: Write the failing test**

```ts
// backend/src/lib/workosAuthService.test.ts
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run src/lib/workosAuthService.test.ts`
Expected: FAIL — `Cannot find module './workosAuthService.js'`.

- [ ] **Step 3: Write minimal implementation**

```ts
// backend/src/lib/workosAuthService.ts
/**
 * workosAuthService — the one place that drives the WorkOS Authentication API
 * for the HEADLESS login flow (decision 0002 headless-login project). The
 * password and refresh grants send client_secret (= WORKOS_API_KEY) in the body,
 * so this MUST run server-side. Mirrors workosProvisionService's raw-fetch,
 * discriminated-union style.
 */
import { env } from './env.js';

const WORKOS_API = 'https://api.workos.com';
const AUTH_URL = `${WORKOS_API}/user_management/authenticate`;

export type AuthOutcome =
  | { status: 'authenticated'; accessToken: string; refreshToken: string }
  | { status: 'email_verification_required'; pendingToken: string }
  | { status: 'mfa_required'; pendingToken: string; challengeId: string | null }
  | { status: 'invalid_credentials' }
  | { status: 'error'; code: 'NOT_CONFIGURED' | 'WORKOS_ERROR' };

type Grant = Record<string, string | undefined>;

// Field names on WorkOS pending/error bodies are read defensively: WorkOS uses
// `code` on error bodies, but we also accept `error` so a field rename cannot
// silently turn a pending state into a 500. Confirmed shapes: Task 12 (staging).
async function callAuthenticate(grant: Grant): Promise<AuthOutcome> {
  if (!env.WORKOS_CLIENT_ID || !env.WORKOS_API_KEY) {
    return { status: 'error', code: 'NOT_CONFIGURED' };
  }
  const body = { client_id: env.WORKOS_CLIENT_ID, client_secret: env.WORKOS_API_KEY, ...grant };
  const res = await fetch(AUTH_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  const parsed = (await res.json().catch(() => ({}))) as Record<string, unknown>;

  if (res.ok && typeof parsed.access_token === 'string' && typeof parsed.refresh_token === 'string') {
    return { status: 'authenticated', accessToken: parsed.access_token, refreshToken: parsed.refresh_token };
  }

  const disc = (parsed.code ?? parsed.error) as string | undefined;
  const pendingToken = parsed.pending_authentication_token as string | undefined;

  if (disc === 'email_verification_required' && pendingToken) {
    return { status: 'email_verification_required', pendingToken };
  }
  if ((disc === 'mfa_enrollment' || disc === 'mfa_challenge') && pendingToken) {
    return {
      status: 'mfa_required',
      pendingToken,
      challengeId: (parsed.authentication_challenge_id as string | undefined) ?? null,
    };
  }
  if (disc === 'invalid_credentials' || disc === 'password_incorrect' || res.status === 401) {
    return { status: 'invalid_credentials' };
  }

  console.error('[workosAuth] authenticate failed:', res.status, JSON.stringify(parsed));
  return { status: 'error', code: 'WORKOS_ERROR' };
}

export function authenticateWithPassword(
  email: string,
  password: string,
  ctx?: { ipAddress?: string; userAgent?: string }
): Promise<AuthOutcome> {
  return callAuthenticate({
    grant_type: 'password',
    email,
    password,
    ip_address: ctx?.ipAddress,
    user_agent: ctx?.userAgent,
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && npx vitest run src/lib/workosAuthService.test.ts`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add backend/src/lib/workosAuthService.ts backend/src/lib/workosAuthService.test.ts
git commit -m "feat(auth): WorkOS headless auth service — password grant"
```

---

### Task 2: WorkOS auth service — email-code grant + refresh grant

**Files:**
- Modify: `backend/src/lib/workosAuthService.ts`
- Test: `backend/src/lib/workosAuthService.test.ts`

**Interfaces:**
- Consumes: internal `callAuthenticate` from Task 1.
- Produces: `authenticateWithEmailCode(code, pendingToken)`, `refreshWorkosSession(refreshToken)` — both return `AuthOutcome`. Tasks 5 and 6 consume these.

- [ ] **Step 1: Write the failing test** (append to the existing describe block file)

```ts
// append to backend/src/lib/workosAuthService.test.ts
import { authenticateWithEmailCode, refreshWorkosSession } from './workosAuthService.js';

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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run src/lib/workosAuthService.test.ts`
Expected: FAIL — `authenticateWithEmailCode`/`refreshWorkosSession` are not exported.

- [ ] **Step 3: Write minimal implementation** (append to `workosAuthService.ts`)

```ts
export function authenticateWithEmailCode(code: string, pendingToken: string): Promise<AuthOutcome> {
  return callAuthenticate({
    grant_type: 'urn:workos:oauth:grant-type:email-verification:code',
    code,
    pending_authentication_token: pendingToken,
  });
}

export function refreshWorkosSession(refreshToken: string): Promise<AuthOutcome> {
  return callAuthenticate({ grant_type: 'refresh_token', refresh_token: refreshToken });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && npx vitest run src/lib/workosAuthService.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lib/workosAuthService.ts backend/src/lib/workosAuthService.test.ts
git commit -m "feat(auth): WorkOS headless auth service — email-code + refresh grants"
```

---

### Task 3: WorkOS auth service — password reset send + confirm

**Files:**
- Modify: `backend/src/lib/workosAuthService.ts`
- Test: `backend/src/lib/workosAuthService.test.ts`

**Interfaces:**
- Consumes: `env.WORKOS_API_KEY` (Bearer header — these are Management API endpoints, NOT the authenticate grant).
- Produces: `sendWorkosPasswordReset(email)`, `confirmWorkosPasswordReset(token, newPassword)` → `ResetOutcome`. Task 7 consumes these.

- [ ] **Step 1: Write the failing test** (append)

```ts
import { sendWorkosPasswordReset, confirmWorkosPasswordReset } from './workosAuthService.js';

describe('password reset', () => {
  beforeEach(() => vi.stubGlobal('fetch', vi.fn()));
  afterEach(() => vi.unstubAllGlobals());

  it('sends a reset using the API key in the Authorization header', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce(okJson({ id: 'pwr_1' }));
    const out = await sendWorkosPasswordReset('a@b.com');
    expect(out).toEqual({ ok: true });
    const [url, init] = (fetch as ReturnType<typeof vi.fn>).mock.calls[0];
    expect(url).toBe('https://api.workos.com/user_management/password_reset');
    expect((init as RequestInit).headers).toMatchObject({ Authorization: 'Bearer sk_test_123' });
    expect(JSON.parse((init as RequestInit).body as string)).toEqual({ email: 'a@b.com' });
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
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run src/lib/workosAuthService.test.ts`
Expected: FAIL — functions not exported.

- [ ] **Step 3: Write minimal implementation** (append)

```ts
export type ResetOutcome =
  | { ok: true }
  | { ok: false; code: 'NOT_CONFIGURED' | 'INVALID_TOKEN' | 'WEAK_PASSWORD' | 'WORKOS_ERROR' };

function apiKeyHeaders() {
  return { Authorization: `Bearer ${env.WORKOS_API_KEY}`, 'Content-Type': 'application/json' };
}

export async function sendWorkosPasswordReset(email: string): Promise<ResetOutcome> {
  if (!env.WORKOS_API_KEY) return { ok: false, code: 'NOT_CONFIGURED' };
  const res = await fetch(`${WORKOS_API}/user_management/password_reset`, {
    method: 'POST',
    headers: apiKeyHeaders(),
    body: JSON.stringify({ email }),
  });
  // A 404 (no such user) is expected and must NOT leak — the caller always 200s.
  if (!res.ok && res.status !== 404) {
    console.error('[workosAuth] password_reset send failed:', res.status, await res.text());
    return { ok: false, code: 'WORKOS_ERROR' };
  }
  return { ok: true };
}

export async function confirmWorkosPasswordReset(token: string, newPassword: string): Promise<ResetOutcome> {
  if (!env.WORKOS_API_KEY) return { ok: false, code: 'NOT_CONFIGURED' };
  const res = await fetch(`${WORKOS_API}/user_management/password_reset/confirm`, {
    method: 'POST',
    headers: apiKeyHeaders(),
    body: JSON.stringify({ token, new_password: newPassword }),
  });
  if (res.ok) return { ok: true };
  const body = (await res.json().catch(() => ({}))) as Record<string, unknown>;
  const disc = (body.code ?? body.error) as string | undefined;
  if (disc && /token|expired|invalid/i.test(disc)) return { ok: false, code: 'INVALID_TOKEN' };
  if (disc && /password/i.test(disc)) return { ok: false, code: 'WEAK_PASSWORD' };
  console.error('[workosAuth] password_reset confirm failed:', res.status, JSON.stringify(body));
  return { ok: false, code: 'WORKOS_ERROR' };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && npx vitest run src/lib/workosAuthService.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lib/workosAuthService.ts backend/src/lib/workosAuthService.test.ts
git commit -m "feat(auth): WorkOS headless auth service — password reset send/confirm"
```

---

### Task 4: Route — POST /api/auth/workos/authenticate

**Files:**
- Modify: `backend/src/routes/auth.ts` (add cookie-name constants near `evSessionCookieOptions`; add the handler after the existing `/login` handler)
- Test: `backend/src/routes/auth.workos.test.ts`

**Interfaces:**
- Consumes: `authenticateWithPassword` (Task 1).
- Produces: `POST /api/auth/workos/authenticate` `{ email, password }` → `200 { access_token }` (+ sets `ev_wos_session`), or `200 { status: 'email_verification_required' | 'mfa_required' }` (+ sets `ev_wos_pending`), or `401 { code: 'INVALID_CREDENTIALS' }`. The cookie names `ev_wos_session` / `ev_wos_pending` are produced here and consumed by Tasks 5–7.

- [ ] **Step 1: Write the failing test**

```ts
// backend/src/routes/auth.workos.test.ts
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
    const cookies = res.headers['set-cookie'].join(';');
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
    expect(res.headers['set-cookie'].join(';')).toContain('ev_wos_pending=pat_1');
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run src/routes/auth.workos.test.ts`
Expected: FAIL — route returns 404 (handler not added). If `cookie-parser` is not resolvable, note it is already a dependency (the app uses `req.cookies` in `/session`); confirm with `node -e "require.resolve('cookie-parser')"` from `backend/`.

- [ ] **Step 3: Write minimal implementation**

Add near the top of `auth.ts`, under `evSessionCookieOptions()`:

```ts
const WOS_SESSION_COOKIE = 'ev_wos_session';
const WOS_PENDING_COOKIE = 'ev_wos_pending';

// The pending token is single-use and short-lived; hold it server-side in an
// httpOnly cookie so it never touches browser JS (posture: no auth material in
// JS storage).
function wosPendingCookieOptions() {
  return { ...evSessionCookieOptions(), maxAge: 15 * 60 * 1000 }; // 15 minutes
}
function setWosSession(res: Response, refreshToken: string) {
  res.cookie(WOS_SESSION_COOKIE, refreshToken, {
    ...evSessionCookieOptions(),
    maxAge: 30 * 24 * 60 * 60 * 1000,
  });
}
```

Add the import at the top of `auth.ts`:

```ts
import {
  authenticateWithPassword,
  authenticateWithEmailCode,
  refreshWorkosSession,
  sendWorkosPasswordReset,
  confirmWorkosPasswordReset,
} from '../lib/workosAuthService.js';
```

Add the handler after the `/login` handler:

```ts
/**
 * POST /api/auth/workos/authenticate
 *
 * Headless WorkOS login (decision 0002 headless-login project). Runs the WorkOS
 * password grant SERVER-SIDE (it needs client_secret), stores the WorkOS refresh
 * token in the ev_wos_session httpOnly cookie, and returns the access token.
 * Pending states (email verification, MFA) stash the pending token in the
 * ev_wos_pending cookie and report a status for the UI to resolve on the next call.
 */
router.post('/workos/authenticate', authLimiter, async (req: Request, res: Response): Promise<void> => {
  const parsed = authBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: parsed.error.issues[0]?.message ?? 'Invalid request body' });
    return;
  }
  const { email, password } = parsed.data;
  const outcome = await authenticateWithPassword(email, password, {
    ipAddress: req.ip,
    userAgent: req.headers['user-agent'],
  });

  switch (outcome.status) {
    case 'authenticated':
      setWosSession(res, outcome.refreshToken);
      res.status(200).json({ access_token: outcome.accessToken });
      return;
    case 'email_verification_required':
    case 'mfa_required':
      res.cookie(WOS_PENDING_COOKIE, outcome.pendingToken, wosPendingCookieOptions());
      res.status(200).json({ status: outcome.status });
      return;
    case 'invalid_credentials':
      res.status(401).json({ code: 'INVALID_CREDENTIALS', message: 'Invalid email or password' });
      return;
    default:
      res.status(outcome.code === 'NOT_CONFIGURED' ? 503 : 502).json({
        code: outcome.code, message: 'Sign-in is temporarily unavailable',
      });
      return;
  }
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && npx vitest run src/routes/auth.workos.test.ts`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add backend/src/routes/auth.ts backend/src/routes/auth.workos.test.ts
git commit -m "feat(auth): POST /api/auth/workos/authenticate (headless password login)"
```

---

### Task 5: Route — POST /api/auth/workos/verify-email

**Files:**
- Modify: `backend/src/routes/auth.ts`
- Test: `backend/src/routes/auth.workos.test.ts`

**Interfaces:**
- Consumes: `authenticateWithEmailCode` (Task 2); the `ev_wos_pending` cookie (Task 4).
- Produces: `POST /api/auth/workos/verify-email` `{ code }` → `200 { access_token }` (+ `ev_wos_session`, clears `ev_wos_pending`), `400 { code: 'NO_PENDING_AUTH' }`, or `401 { code: 'INVALID_CODE' }`.

- [ ] **Step 1: Write the failing test** (append to `auth.workos.test.ts`)

```ts
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
    const cookies = res.headers['set-cookie'].join(';');
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run src/routes/auth.workos.test.ts`
Expected: FAIL — the three new tests 404/500.

- [ ] **Step 3: Write minimal implementation** (add handler to `auth.ts`)

```ts
const verifyEmailSchema = z.object({ code: z.string().min(4).max(10) });

/**
 * POST /api/auth/workos/verify-email
 *
 * Second leg of the on-page verification flow: the pending token lives in the
 * ev_wos_pending httpOnly cookie (set by /workos/authenticate). We exchange the
 * emailed code for a session, then clear the pending cookie.
 */
router.post('/workos/verify-email', authLimiter, async (req: Request, res: Response): Promise<void> => {
  const parsed = verifyEmailSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'A verification code is required' });
    return;
  }
  const pendingToken = req.cookies?.[WOS_PENDING_COOKIE];
  if (!pendingToken) {
    res.status(400).json({ code: 'NO_PENDING_AUTH', message: 'Start sign-in again to get a new code' });
    return;
  }

  const outcome = await authenticateWithEmailCode(parsed.data.code, pendingToken);
  if (outcome.status === 'authenticated') {
    res.clearCookie(WOS_PENDING_COOKIE, evSessionCookieOptions());
    setWosSession(res, outcome.refreshToken);
    res.status(200).json({ access_token: outcome.accessToken });
    return;
  }
  if (outcome.status === 'invalid_credentials') {
    res.status(401).json({ code: 'INVALID_CODE', message: 'That code is incorrect or expired' });
    return;
  }
  res.status(502).json({ code: 'WORKOS_ERROR', message: 'Verification is temporarily unavailable' });
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && npx vitest run src/routes/auth.workos.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/src/routes/auth.ts backend/src/routes/auth.workos.test.ts
git commit -m "feat(auth): POST /api/auth/workos/verify-email (on-page code step)"
```

---

### Task 6: Route — GET /api/auth/session WorkOS branch

**Files:**
- Modify: `backend/src/routes/auth.ts` (the existing `/session` handler)
- Test: `backend/src/routes/auth.workos.test.ts`

**Interfaces:**
- Consumes: `refreshWorkosSession` (Task 2); the `ev_wos_session` cookie (Task 4).
- Produces: `GET /api/auth/session` now returns `{ access_token }` for a WorkOS cookie (rotating `ev_wos_session`), falling back to today's Supabase path.

- [ ] **Step 1: Write the failing test** (append)

```ts
describe('GET /api/auth/session — WorkOS branch', () => {
  it('refreshes and rotates the ev_wos_session cookie when present', async () => {
    authSvc.refreshWorkosSession.mockResolvedValueOnce({
      status: 'authenticated', accessToken: 'at_new', refreshToken: 'rt_new',
    });
    const res = await request(app).get('/api/auth/session').set('Cookie', 'ev_wos_session=rt_old');
    expect(res.status).toBe(200);
    expect(res.body.access_token).toBe('at_new');
    expect(authSvc.refreshWorkosSession).toHaveBeenCalledWith('rt_old');
    expect(res.headers['set-cookie'].join(';')).toContain('ev_wos_session=rt_new');
  });

  it('clears the cookie and 401s when the WorkOS refresh fails', async () => {
    authSvc.refreshWorkosSession.mockResolvedValueOnce({ status: 'error', code: 'WORKOS_ERROR' });
    const res = await request(app).get('/api/auth/session').set('Cookie', 'ev_wos_session=rt_dead');
    expect(res.status).toBe(401);
    expect(res.headers['set-cookie'].join(';')).toContain('ev_wos_session=;');
  });

  it('401s with no cookie at all', async () => {
    const res = await request(app).get('/api/auth/session');
    expect(res.status).toBe(401);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run src/routes/auth.workos.test.ts`
Expected: FAIL — the WorkOS branch does not exist; a WorkOS cookie currently falls into the Supabase path and 401s without touching `refreshWorkosSession`.

- [ ] **Step 3: Write minimal implementation**

At the very top of the existing `router.get('/session', ...)` handler, before it reads `ev_session`, insert:

```ts
  // WorkOS session takes precedence — a headless login stores its refresh token
  // in ev_wos_session (decision 0002 headless-login). Refresh through WorkOS and
  // rotate the cookie (WorkOS rotates refresh tokens like Supabase).
  const wosRefresh = req.cookies?.[WOS_SESSION_COOKIE];
  if (wosRefresh) {
    const outcome = await refreshWorkosSession(wosRefresh);
    if (outcome.status === 'authenticated') {
      setWosSession(res, outcome.refreshToken);
      res.status(200).json({ access_token: outcome.accessToken });
      return;
    }
    res.clearCookie(WOS_SESSION_COOKIE, evSessionCookieOptions());
    res.status(401).end();
    return;
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && npx vitest run src/routes/auth.workos.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/src/routes/auth.ts backend/src/routes/auth.workos.test.ts
git commit -m "feat(auth): GET /api/auth/session handles the WorkOS refresh cookie"
```

---

### Task 7: Route — logout clears WorkOS cookies; password reset moves to WorkOS

**Files:**
- Modify: `backend/src/routes/auth.ts` (`/logout`, `/forgot-password`, `/reset-password`)
- Test: `backend/src/routes/auth.workos.test.ts`

**Interfaces:**
- Consumes: `sendWorkosPasswordReset`, `confirmWorkosPasswordReset` (Task 3).
- Produces: no new routes — behaviour changes gated on `env.AUTHKIT_PRIMARY === 'true'`.

- [ ] **Step 1: Write the failing test** (append)

```ts
describe('WorkOS-aware logout + password reset (AUTHKIT_PRIMARY)', () => {
  it('logout clears both session cookies', async () => {
    const res = await request(app).post('/api/auth/logout').set('Cookie', 'ev_wos_session=rt');
    expect(res.status).toBe(200);
    const cookies = res.headers['set-cookie'].join(';');
    expect(cookies).toContain('ev_session=;');
    expect(cookies).toContain('ev_wos_session=;');
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
});
```

Note: the reset endpoint keeps its existing body field name `token_hash` (the frontend already sends it); we pass its value to WorkOS as the reset `token`.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run src/routes/auth.workos.test.ts`
Expected: FAIL — logout does not clear `ev_wos_session`; forgot/reset still call Supabase (the mocked `supabaseAdmin` has no such methods, so the reset test throws/500s).

- [ ] **Step 3: Write minimal implementation**

In the `/logout` pre-auth cookie-clear middleware, add the WorkOS cookies:

```ts
  (req: Request, res: Response, next: NextFunction) => {
    res.clearCookie('ev_session', evSessionCookieOptions());
    res.clearCookie(WOS_SESSION_COOKIE, evSessionCookieOptions());
    res.clearCookie(WOS_PENDING_COOKIE, evSessionCookieOptions());
    next();
  },
```

In `/forgot-password`, branch at the top of the `try`:

```ts
  try {
    if (env.AUTHKIT_PRIMARY === 'true') {
      await sendWorkosPasswordReset(parsed.data.email);
    } else {
      await supabaseAdmin.auth.resetPasswordForEmail(parsed.data.email, {
        redirectTo: `${env.LOGIN_URL}/reset-password`,
      });
    }
  } catch (err) {
```

In `/reset-password`, branch before the Supabase `verifyOtp`:

```ts
  const { token_hash, password } = parsed.data;

  if (env.AUTHKIT_PRIMARY === 'true') {
    const outcome = await confirmWorkosPasswordReset(token_hash, password);
    if (outcome.ok) {
      res.status(200).json({ message: 'Password updated successfully' });
      return;
    }
    if (outcome.code === 'WEAK_PASSWORD') {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Password is too weak' });
      return;
    }
    res.status(422).json({ code: 'INVALID_RESET_TOKEN', message: 'Reset link is invalid or has expired' });
    return;
  }
  // (existing Supabase recovery path unchanged below)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && npx vitest run src/routes/auth.workos.test.ts && npm test`
Expected: the new file PASSES; the full suite stays green (no regression in `auth`-adjacent tests).

- [ ] **Step 5: Commit**

```bash
git add backend/src/routes/auth.ts backend/src/routes/auth.workos.test.ts
git commit -m "feat(auth): logout clears WorkOS cookies; password reset via WorkOS under AUTHKIT_PRIMARY"
```

---

### Task 8: Frontend (admin) — embedded login form + code step

**Files:**
- Modify: `admin/src/lib/workosAuth.ts`
- Modify: `admin/src/pages/Login.tsx`

**Interfaces:**
- Consumes: `POST /api/auth/workos/authenticate`, `POST /api/auth/workos/verify-email` (Tasks 4–5).
- Produces: `embeddedAuthEnabled: boolean`, `loginWithPassword(email, password)`, `verifyEmailCode(code)`.

Frontend note: these apps have no standing unit-test harness (see the migration retro — verification is done in the browser/staging). So Tasks 8–11 are **build + browser-verify**, not TDD. Verify against the WorkOS **staging** environment (prod frontends point there = founder cohort).

- [ ] **Step 1: Add the embedded helpers to `admin/src/lib/workosAuth.ts`**

```ts
// VITE_EMBEDDED_AUTH turns on our own headless form instead of the hosted
// AuthKit redirect. Requires VITE_WORKOS_CLIENT_ID (workosEnabled) so we never
// lock everyone out of a build that has no WorkOS at all.
export const embeddedAuthEnabled =
  workosEnabled && import.meta.env.VITE_EMBEDDED_AUTH === 'true';

type EmbeddedResult =
  | { status: 'authenticated'; token: string }
  | { status: 'email_verification_required' }
  | { status: 'mfa_required' };

export async function loginWithPassword(email: string, password: string): Promise<EmbeddedResult> {
  const res = await fetch(`${API_BASE}/auth/workos/authenticate`, {
    method: 'POST',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  const body = await res.json().catch(() => ({}));
  if (res.status === 401) throw new Error(body.message || 'Invalid email or password');
  if (!res.ok) throw new Error(body.message || 'Sign-in failed');
  if (body.access_token) {
    markWorkosSession();
    return { status: 'authenticated', token: body.access_token };
  }
  return { status: body.status };
}

export async function verifyEmailCode(code: string): Promise<string> {
  const res = await fetch(`${API_BASE}/auth/workos/verify-email`, {
    method: 'POST',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ code }),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(body.message || 'Verification failed');
  markWorkosSession();
  return body.access_token as string;
}
```

- [ ] **Step 2: Render the embedded flow in `admin/src/pages/Login.tsx`**

Import the new helpers and add a small state machine. When `embeddedAuthEnabled`, the form's submit calls `loginWithPassword`; a returned pending status switches the card to a code-entry sub-view whose submit calls `verifyEmailCode`, then `finishLogin`. Keep the existing hosted-redirect path for when `embeddedAuthEnabled` is false.

```tsx
// new state
const [codeStep, setCodeStep] = useState(false);
const [code, setCode] = useState('');

async function handleEmbeddedSubmit(e: FormEvent) {
  e.preventDefault();
  setError(null); setIsSubmitting(true);
  try {
    const result = await loginWithPassword(email, password);
    if (result.status === 'authenticated') {
      await finishLogin(result.token, validRedirect, email);
    } else {
      setCodeStep(true); // email_verification_required or mfa_required
    }
  } catch (err) {
    setError(err instanceof Error ? err.message : 'Sign-in failed');
  } finally { setIsSubmitting(false); }
}

async function handleCodeSubmit(e: FormEvent) {
  e.preventDefault();
  setError(null); setIsSubmitting(true);
  try {
    const token = await verifyEmailCode(code);
    await finishLogin(token, validRedirect, email);
  } catch (err) {
    setError(err instanceof Error ? err.message : 'Verification failed');
  } finally { setIsSubmitting(false); }
}
```

Wire the existing email/password `<form>` to `handleEmbeddedSubmit` when `embeddedAuthEnabled` (keep `handleSubmit` for the classic break-glass form). Render, when `codeStep`, a single 6-digit `<input inputMode="numeric" autoComplete="one-time-code">` bound to `code` with a "Verify" button calling `handleCodeSubmit`. Keep the `autoComplete="email"` / `"current-password"` attributes already on the inputs — they are what make our-domain autofill work.

- [ ] **Step 3: Build**

Run: `cd admin && npm run build`
Expected: type-checks and builds with no errors.

- [ ] **Step 4: Browser-verify against staging**

Run the admin dev server (`.claude/launch.json` entry or `npm run dev` in `admin/`) with `VITE_WORKOS_CLIENT_ID=<staging client id>` and `VITE_EMBEDDED_AUTH=true`, backend pointed at staging WorkOS. Then:
- Load `/login`: the embedded email/password form renders (no redirect to `authkit.app`).
- Log in as a verified staging user → lands on `/profile`; check `read_network_requests` shows `POST /api/auth/workos/authenticate` `200` and a `Set-Cookie: ev_wos_session`.
- Confirm the browser password manager offers a saved `empowered.vote` credential on the field (the whole point).

- [ ] **Step 5: Commit**

```bash
git add admin/src/lib/workosAuth.ts admin/src/pages/Login.tsx
git commit -m "feat(auth): embedded WorkOS login form + on-page code step (admin, flag-gated)"
```

---

### Task 9: Frontend (admin) — signup auto-advances to the code step

**Files:**
- Modify: `admin/src/pages/Signup.tsx`
- Modify: `admin/src/pages/InformSignup.tsx`

**Interfaces:**
- Consumes: `loginWithPassword`, `verifyEmailCode`, `embeddedAuthEnabled` (Task 8).

- [ ] **Step 1: After a 201 from `/api/auth/signup`, auto-advance when embedded**

In each signup page's submit handler, on success, when `embeddedAuthEnabled`, immediately call `loginWithPassword(email, password)`. Because the new account's email is unverified, it returns `email_verification_required`; render the same 6-digit code input as Task 8 and call `verifyEmailCode(code)` → `finishLogin`. When not embedded, keep the existing "check your email, then sign in" message.

```tsx
// inside the signup success branch:
if (embeddedAuthEnabled) {
  await loginWithPassword(email, password); // returns email_verification_required
  setCodeStep(true); // reuse the same code-entry UI as Login
} else {
  setDone(true); // existing "check your email" confirmation
}
```

- [ ] **Step 2: Build**

Run: `cd admin && npm run build`
Expected: builds clean.

- [ ] **Step 3: Browser-verify against staging**

- Sign up a brand-new staging user via `/signup/inform`.
- Confirm the page advances to the code field (no navigation to `authkit.app`).
- Retrieve the code (staging inbox, or WorkOS dashboard email-verification object) and enter it → the user lands logged in on `/profile` in one sitting.
- `read_network_requests`: `POST /api/auth/signup 201`, then `POST /api/auth/workos/authenticate` (pending), then `POST /api/auth/workos/verify-email 200`.

- [ ] **Step 4: Commit**

```bash
git add admin/src/pages/Signup.tsx admin/src/pages/InformSignup.tsx
git commit -m "feat(auth): auto-advance signup into on-page verification (admin, flag-gated)"
```

---

### Task 10: Frontend (admin) — bootstrap + 401 refresh via the session cookie

**Files:**
- Modify: `admin/src/lib/api.ts`
- Modify: `admin/src/App.tsx`

**Interfaces:**
- Consumes: `GET /api/auth/session` (Task 6, WorkOS branch); `embeddedAuthEnabled` (Task 8).

- [ ] **Step 1: Prefer `/api/auth/session` in the 401 refresh path when embedded**

In `api.ts` `refreshAccessToken`, when `embeddedAuthEnabled`, take the `/api/auth/session` branch (the cookie now carries the WorkOS session) instead of the `authkit-js` SDK branch:

```ts
  refreshPromise = (workosEnabled && hasWorkosSession() && !embeddedAuthEnabled
    ? refreshWorkosToken().then((token) => {
        if (token) useAuthStore.setState({ accessToken: token });
        return token;
      })
    : fetch(`${API_BASE}/auth/session`, { credentials: 'include' })
        .then(async (res) => {
          if (!res.ok) return null;
          const data = (await res.json()) as { access_token: string };
          useAuthStore.setState({ accessToken: data.access_token });
          return data.access_token;
        })
  ).finally(() => { refreshPromise = null; });
```

Import `embeddedAuthEnabled` from `./workosAuth`.

- [ ] **Step 2: Restore the session on bootstrap via the cookie when embedded**

In `App.tsx`, when there is no `admin_token` in `sessionStorage` and `embeddedAuthEnabled`, call `apiFetch('/account/me')` directly (its own 401 path will hit `/api/auth/session`, which reads the `ev_wos_session` cookie). Replace the `hasWorkosSession()` SDK branch for the embedded case:

```ts
    } else if (embeddedAuthEnabled) {
      // Cookie-backed WorkOS session: let apiFetch's 401 path pull a token from
      // /api/auth/session (which reads ev_wos_session). No SDK, no localStorage hint.
      hydrateFromMe('').catch(() => { clearAuth(); });
    } else if (workosEnabled && hasWorkosSession()) {
      // (existing SDK restore path, unchanged, for the non-embedded rollout window)
```

Note: `hydrateFromMe('')` starts with no token; `apiFetch('/account/me')` sends no `Authorization`, gets 401, refreshes via `/api/auth/session`, and retries. Confirm `apiFetch` already retries after refresh (it does — Task references `admin/src/lib/api.ts`).

- [ ] **Step 3: Build + browser-verify**

Run: `cd admin && npm run build`. Then in the browser (staging, embedded flag on):
- Log in, then hard-reload the tab → still logged in (no re-login), proving cookie restore.
- Open a second tab on `login.empowered.vote` → logged in.
- Let the access token expire (or force a 401) → a background `GET /api/auth/session 200` rotates `ev_wos_session` and the request retries.

- [ ] **Step 4: Commit**

```bash
git add admin/src/lib/api.ts admin/src/App.tsx
git commit -m "feat(auth): cookie-backed WorkOS session restore + refresh (admin, flag-gated)"
```

---

### Task 11: Frontend (app) — redirect to central login under the flag

**Files:**
- Modify: `app/src/lib/workosAuth.ts`
- Modify: `app/src/pages/LoginPage.tsx`

**Interfaces:**
- Consumes: the central embedded form at `login.empowered.vote` (Tasks 8–10) and the shared `ev_wos_session` cookie on `.empowered.vote`.

- [ ] **Step 1: Add `embeddedAuthEnabled` to `app/src/lib/workosAuth.ts`** (identical to admin's Task-8 Step-1 definition — copy it; these two files are kept in sync by policy):

```ts
export const embeddedAuthEnabled =
  workosEnabled && import.meta.env.VITE_EMBEDDED_AUTH === 'true';
```

- [ ] **Step 2: Redirect app sign-in to the central login when embedded**

In `LoginPage.tsx`, when `embeddedAuthEnabled`, the WorkOS sign-in action (and the auto-forward) navigate to our own login page instead of calling the hosted SDK:

```ts
const LOGIN_ORIGIN = 'https://login.empowered.vote';
async function handleWorkosSignIn() {
  if (embeddedAuthEnabled) {
    const back = redirectUrl ?? window.location.origin;
    window.location.href = `${LOGIN_ORIGIN}/login?redirect=${encodeURIComponent(back)}`;
    return;
  }
  // (existing hosted SDK path unchanged)
}
```

Apply the same guard in the `autoForwarding` effect so AuthKit-only mode forwards to our login page rather than `authkit.app`. After central login, the shared cookie + the existing `?redirect=` handoff return the user logged in.

- [ ] **Step 3: Build + browser-verify**

Run: `cd app && npm run build`. In the browser (staging, embedded flag on both admin and app):
- Visit `app.empowered.vote/login` → it redirects to `login.empowered.vote/login?redirect=…` (our domain, not `authkit.app`).
- Complete login there → bounced back to `app.` **logged in** (shared `ev_wos_session`). This is the cross-app SSO win.

- [ ] **Step 4: Commit**

```bash
git add app/src/lib/workosAuth.ts app/src/pages/LoginPage.tsx
git commit -m "feat(auth): app redirects sign-in to central login under VITE_EMBEDDED_AUTH"
```

---

### Task 12: Rollout wiring, staging verification, and docs

**Files:**
- Modify: `DEPLOY.md` (the authoritative ev-accounts copy) — document `VITE_EMBEDDED_AUTH`, the two new cookies, and the new endpoints in the per-service matrix.
- Reference: `docs/HEADLESS-LOGIN-DESIGN.md` (acceptance checks).

This task is ops + verification; it makes no code change beyond docs, and it ends the plan with the whole flow proven on staging.

- [ ] **Step 1: Confirm the pending/error response shapes against real WorkOS staging**

Using a staging fixture user, exercise `POST /api/auth/workos/authenticate` for: (a) a verified user (expect `authenticated`), (b) an unverified user (expect `email_verification_required` + a code email), (c) a wrong password (expect `invalid_credentials`). Read the raw WorkOS bodies from the backend logs and confirm the discriminator field is `code` with the values assumed in `callAuthenticate`. If a field name differs (e.g. `error` vs `code`, or `mfa_challenge` naming), adjust the matcher in `workosAuthService.ts` and its unit test, then re-run `npx vitest run src/lib/workosAuthService.test.ts`.

- [ ] **Step 2: Confirm the password-reset email link target**

Trigger `POST /api/auth/forgot-password` (AUTHKIT_PRIMARY on, staging) and confirm the emailed reset link lands on `login.empowered.vote/reset-password?token=…`. If WorkOS sends its own hosted URL, either set the reset redirect in the WorkOS dashboard or switch to WorkOS Custom Emails to control the link. Record the outcome in `DEPLOY.md`.

- [ ] **Step 3: Confirm `COOKIE_DOMAIN` is `.empowered.vote` in prod**

Check the ev-accounts-api Render env (`COOKIE_DOMAIN`). Cross-app SSO (Task 11) depends on the cookie being shared across subdomains. Note it in `DEPLOY.md`; do not change prod env without approval.

- [ ] **Step 4: Run the full acceptance checklist on staging**

Walk every check in `docs/HEADLESS-LOGIN-DESIGN.md` → "Acceptance / verification": existing-user login with no `authkit.app` trip; new-user signup+verify+login in one sitting; reload/new-tab session restore; cross-app SSO; password reset changes the WorkOS credential and the next login works; `/login/classic` break-glass still renders; the rate-limiter still trips at 11 attempts/15 min.

- [ ] **Step 5: Document + commit; STOP AND ASK before any production flag flip**

Update `DEPLOY.md`. Commit:

```bash
git add DEPLOY.md
git commit -m "docs(auth): document headless-login rollout, cookies, and VITE_EMBEDDED_AUTH"
```

Then present the staging results and request approval before setting `VITE_EMBEDDED_AUTH=true` on any production frontend. Roll out one origin at a time: `login.empowered.vote` (admin) → `app.empowered.vote` (app) → validation-quests (separate repo, same redirect change). Keep the hosted redirect and `/login/classic` as fallbacks through the bake.

---

## Out of scope (documented in the design; do NOT build here)

- MFA UI (TOTP/SMS) — the endpoints already pass the `mfa_required` status through (Task 4); enabling it later is a frontend-only add.
- Passkeys (hosted-UI only — would require keeping a hosted entry).
- The free HIBP breached-password check.
- Phase 4 (Supabase third-party auth, `auth.uid()` RLS rewrite, removing the `requestDb` service-role seam).
- Retiring `/login/classic` and Supabase Auth.
- validation-quests code change (fast-follow — a one-line redirect target change, mirroring Task 11).

## Self-review notes

- **Spec coverage:** login (T4, T8), session ownership/refresh (T6, T10), on-page verification (T5, T8, T9), password reset → WorkOS (T3, T7), flag + staged rollout (T8–T12), form-once + app/VQ redirect (T11, T12). All six design decisions map to tasks.
- **Type consistency:** `AuthOutcome`/`ResetOutcome` defined once (Global contract), produced by T1–T3, consumed unchanged by T4–T7. Cookie names `ev_wos_session` / `ev_wos_pending` introduced in T4, reused verbatim in T5–T7 and T10–T11.
- **Assumptions flagged for staging (T12):** exact WorkOS pending-body field names; reset-email link target; `COOKIE_DOMAIN`. The service parses defensively so a field-name surprise degrades to a logged `WORKOS_ERROR`, never a wrong success.
