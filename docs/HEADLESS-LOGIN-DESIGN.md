# Headless WorkOS login — design & plan

Status: design agreed (2026-08-28, grill session with Chris Andrews). Pre-implementation.
Lineage: extends ev-cto decision [`0002-workos-authkit-migration`](https://github.com/EmpoweredVote/ev-cto/blob/master/knowledge/decisions/0002-workos-authkit-migration.md).

## The problem

Existing users still log in on WorkOS's **hosted** AuthKit page at
`operatic-dune-11.authkit.app`. That page lives on a foreign domain. Two costs:

1. Password-manager autofill for `empowered.vote` does not fire on `authkit.app`.
2. A credential prompt on a foreign domain reads as phishing on a civic-trust platform.

The clean vendor fix is WorkOS's custom-domain add-on at $99/mo. We are unfunded, so
that is out. Hosting our **own** login UI is free (the `authenticate` API is in the
same free tier ≤ 1M MAU) and puts the credential prompt back on `empowered.vote`.

## What is already done (this narrows the project)

- **Signup is already headless.** Under `AUTHKIT_PRIMARY=true`, our own `/signup`
  form posts to `POST /api/auth/signup`, which calls `signUpWorkosFirst()`
  (`backend/src/lib/workosProvisionService.ts`). That creates the WorkOS user with
  the password server-side, makes the Supabase shadow row, writes `external_id`, and
  sends the WorkOS verification email. The user never touches the hosted page to sign up.
- **Token verification needs no change.** Headless tokens carry the **same** issuer,
  JWKS, and `external_id` JWT-template claim as hosted tokens. The five token-verifying
  backends (ev-accounts, empowered-validation-quests, focused-communities,
  civic-trivia, empowered-listening) are unaffected.

## What remains on the hosted page or on Supabase

- **Login.** For existing users the frontend calls `startWorkosSignIn()` →
  `client.signIn()`, which **redirects to `authkit.app`**
  (`admin/src/lib/workosAuth.ts`, `app/src/pages/LoginPage.tsx`). This is the thing to replace.
- **Email verification completion.** Sent at signup, but *completed* at the hosted
  sign-in (the user types the code there on first sign-in).
- **Password reset.** Still runs through **Supabase** (`backend/src/routes/auth.ts`),
  but under `AUTHKIT_PRIMARY` the real credential lives in **WorkOS**, so a reset today
  does not change the password the user logs in with. Latent bug.
- **Session refresh.** For WorkOS users the `authkit-js` SDK owns the refresh token in
  browser storage. Headless means we take that over.

## Vendor research result (2026-08-28)

- **No login/signup widget exists.** WorkOS Widgets are post-login only (profile, org
  switcher). The only headless path is the raw Authentication API — a first-class,
  supported, free mode. "Raw API vs widget" is therefore not a real choice.
- **The password grant requires `client_secret`** → it must run server-side.
- Email-verification-by-code, password reset, and MFA (TOTP **and** SMS) are all on the
  raw API, resolved through the `authenticate` step-up state machine
  (`pending_authentication_token`).
- **Passkeys are hosted-UI only** and cannot be built headless.
- **Radar** (bot detection, breached-password checks, progressive rate-limiting) is a
  separate **paid** add-on, automatic only on the hosted page.

---

## Decisions

| # | Decision | Choice |
|---|---|---|
| 1 | Launch scope | **Login core only** — headless login, our session/refresh ownership, on-page email verification, and the WorkOS password-reset fix. MFA and passkeys deferred. |
| 2 | Session owner | **Our backend, httpOnly cookie.** Server-side `authenticate`; WorkOS refresh token in an httpOnly cookie on `.empowered.vote`; refreshed at `/api/auth/session`. No tokens in JS storage. |
| 3 | Email verification UX | **On-page code, auto-advance.** After signup the same page shows a 6-digit code field; entering it verifies *and* logs the user in, in one sitting, on our domain. |
| 4 | Abuse / breach protection | **Rate-limit only, skip Radar.** Keep our `express-rate-limit`. Do not pay for Radar (it contradicts the unfunded rationale). Free HaveIBeenPwned breached-password check is an optional later add. |
| 5 | Rollout | **New `VITE_EMBEDDED_AUTH` flag, staged per origin.** Dark-deploy → staging (founder cohort) → prod, one origin at a time (login → app → VQ). Keep the hosted redirect and `/login/classic` as fallbacks through the bake. |
| 6 | Form location | **Build once at `login.empowered.vote`; `app/` and VQ redirect there.** Shared cookie + the existing redirect handoff return users logged in. VQ becomes a one-line redirect change. |

Rationale for the linchpin (2 → everything): to keep the refresh token in an httpOnly
cookie, the password grant must run server-side, which forces "our own form calling our
own backend" over any browser widget. It also **restores cross-app SSO for WorkOS
users**, which the browser-SDK approach gave up (feature sites inherit the shared cookie).

---

## Target architecture

All headless login goes through the **ev-accounts hub**, because `WORKOS_API_KEY` lives
only there. Other apps redirect to `login.empowered.vote` (the admin build) and inherit
the shared session cookie.

### Login (existing verified user)

1. Our form (`login.empowered.vote`) → `POST /api/auth/workos/authenticate` `{email, password}`.
2. Backend → WorkOS `POST /user_management/authenticate`, `grant_type=password`
   (`client_id` + `client_secret` + `email` + `password`, plus `ip_address` / `user_agent`).
3. On success: set httpOnly cookie `ev_wos_session = refresh_token`
   (`.empowered.vote`, `secure`, `sameSite=lax`, 30-day max-age); return `{ access_token }`.
4. Frontend runs the existing `finishLogin` (hydrate `/account/me`, honour validated redirect).

### Signup + verification (new user, auto-advance)

1. `/signup` form → `POST /api/auth/signup` (unchanged; `signUpWorkosFirst` sends the code email).
2. On `201`, the frontend immediately calls `POST /api/auth/workos/authenticate` with the
   same credentials. Because the email is unverified, WorkOS returns
   `email_verification_required` + a `pending_authentication_token`.
3. The page shows a 6-digit code field → `POST /api/auth/workos/verify-email`
   `{ code, pending_token }` → backend calls `authenticate`,
   `grant_type=urn:workos:oauth:grant-type:email-verification:code`.
4. On success: set the cookie, return `{ access_token }`. Signup, verification, and first
   login complete in one sitting on our domain.

### Session refresh

- `GET /api/auth/session` gains a WorkOS branch: if `ev_wos_session` is present, call
  WorkOS `authenticate`, `grant_type=refresh_token`, **rotate** the cookie with the new
  refresh token, return `{ access_token }`. Else fall back to today's Supabase path
  (`ev_session`). The two issuers are told apart by **which cookie exists** — the
  `hasWorkosSession()` localStorage hint is dropped (server-authoritative).
- `api.ts` 401 path and `App.tsx` bootstrap both collapse onto the existing
  `/api/auth/session` call. The WorkOS-specific SDK branch is removed.

### Password reset (moved to WorkOS)

- `POST /api/auth/forgot-password` → WorkOS `POST /user_management/password_reset`
  `{ email }` (keeps the OWASP always-200 response).
- `POST /api/auth/reset-password` → WorkOS `POST /user_management/password_reset/confirm`
  `{ token, new_password }`. Note: a WorkOS reset **revokes all active sessions** — clear
  our cookies accordingly. Gated on the same embedded/AuthKit-primary switch.

### Other apps (`app/`, validation-quests)

- Under `VITE_EMBEDDED_AUTH`, each app's "sign in" **redirects to
  `login.empowered.vote/login?redirect=<self>`** instead of `authkit.app`. After login,
  the shared cookie + the existing token handoff return the user logged in. No CORS
  needed. VQ is a one-line target change.

### Forward-compat (cheap, no launch cost)

`POST /api/auth/workos/authenticate` passes through **all** WorkOS pending states,
including the MFA challenge (`authentication_challenge` / `mfa-totp` grant). We render
only the email-verification step now; enabling MFA later becomes a frontend-only add.

---

## Backend changes (ev-accounts)

- New: `POST /api/auth/workos/authenticate`, `POST /api/auth/workos/verify-email`.
- Change: `GET /api/auth/session` (WorkOS cookie branch), `POST /api/auth/logout`
  (clear `ev_wos_session` too), `POST /api/auth/forgot-password` + `/reset-password`
  (WorkOS endpoints under the flag).
- New env: none required beyond what exists (`WORKOS_API_KEY`, `WORKOS_CLIENT_ID`,
  `COOKIE_DOMAIN`). A `WORKOS_CLIENT_SECRET` alias may be clearer than reusing
  `WORKOS_API_KEY` for the grant — decide in planning.
- Reuse `authLimiter` (10 / 15 min per IP) on the new endpoints.
- OWASP: wrong email and wrong password both return `INVALID_CREDENTIALS`.

## Frontend changes

- `admin/` (= `login.empowered.vote`): embedded email+password form + code-entry step,
  gated on `VITE_EMBEDDED_AUTH`. `autocomplete="email"` / `"current-password"` (already present).
- `app/` + VQ: redirect their WorkOS sign-in to `login.empowered.vote`.
- Remove `authkit-js` from the primary path; keep it only for the hosted-redirect
  fallback until the bake completes, then delete.

## Flags

| Flag | Where | Meaning |
|---|---|---|
| `AUTHKIT_PRIMARY=true` | backend | signup creates the credential in WorkOS (already live). |
| `VITE_WORKOS_CLIENT_ID` | frontends | WorkOS path compiled in (already live). |
| `VITE_AUTHKIT_ONLY` | frontends | hides the classic Supabase form; today it auto-forwards to the hosted page. |
| `VITE_EMBEDDED_AUTH` (**new**) | frontends | render our embedded form instead of the hosted auto-forward. |
| `/login/classic` | route | break-glass classic Supabase form; unchanged, retired in Phase 4. |

---

## What we keep vs lose

- **Keep:** our `express-rate-limit`; the dual-issuer verification; the `external_id`
  join; `/login/classic` break-glass; the invite-code Connected signup path.
- **Gain:** cross-app SSO for WorkOS users (shared cookie); autofill on our domain; no
  foreign-domain prompt; $0.
- **Lose vs a funded hosted setup:** Radar's automatic bot/breach/rate-limit — but we
  almost certainly do not run Radar today, so this removes an *option*, not an active
  protection. Breached-password is the one worth replacing later (free HIBP).

## Out of scope / later

- **MFA (TOTP + SMS).** Headless-capable; the endpoint is built forward-compatible. Later.
- **Passkeys.** Hosted-UI only. ⚠ A fully headless login removes passkeys **permanently**
  unless we keep a hosted entry for passkey users. Decide deliberately if/when wanted.
- **HIBP breached-password check.** Free, optional, fast-follow.
- **Phase 4 RLS work** — configure Supabase third-party auth, rewrite `auth.uid()`
  policies, remove the `requestDb()` service-role seam. Separate and larger. Headless does
  not change token issuance, so the seam is unaffected either way; but the longer two
  issuers coexist, the longer one runs without RLS.
- **Email branding.** Verification/reset emails send from a WorkOS-managed sender unless
  we buy the custom domain (defeats the purpose) or use WorkOS Custom Emails via webhooks. Later.
- **Retire `/login/classic` + Supabase Auth.** After full cutover.

## Open implementation details to verify in planning

- Where the WorkOS **password-reset email link** points — confirm it targets
  `login.empowered.vote/reset-password?token=…`, or use Custom Emails to control it.
- `pending_authentication_token` handling — echo to the client vs a short-lived httpOnly
  cookie. Prefer the cookie for posture; confirm single-use TTL.
- `COOKIE_DOMAIN` is set to `.empowered.vote` in prod (required for cross-app SSO).
- `sameSite=lax` behaviour across subdomains for the redirect handoff.
- Confirm the new endpoints run in the service that holds `WORKOS_API_KEY` (they do —
  ev-accounts backend).

## Acceptance / verification (against WorkOS staging = founder cohort)

- Existing user logs in with no trip to `authkit.app`.
- New user signs up, enters the emailed code on-page, lands logged in — one sitting.
- Session survives reload and a new tab via the cookie; no token in JS storage.
- Cross-app SSO: log in at `login.empowered.vote`, then reach `app.` / Essentials logged in.
- Password reset changes the **WorkOS** credential; the next login works.
- Break-glass `/login/classic` still works; the rate-limiter still trips.
- Note: decision 0002's "new user signs up with MFA" stays **UNTESTED** — MFA is deferred.

## Risks

- **Two credentials for migrated users** (WorkOS import + stale Supabase). Reset changes
  WorkOS only; Supabase stays reachable only via `/login/classic`. Consistent with the
  transition posture.
- **SSO depends on `COOKIE_DOMAIN` + `sameSite`.** Verify before relying on it.
- **Pending token expiry** if the user is slow to read the email — provide a resend.
- **WorkOS outage** (us-east-1) blocks new logins, as today; existing sessions survive
  because verification is local (JWKS).
