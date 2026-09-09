# Headless WorkOS MFA & passkeys — research & plan

Status: research complete, decisions locked (2026-09-02, grill session with Chris Andrews). Pre-implementation. **No code changed.**
Lineage: extends [`HEADLESS-LOGIN-DESIGN.md`](./HEADLESS-LOGIN-DESIGN.md) and ev-cto decision [`0002-workos-authkit-migration`](https://github.com/EmpoweredVote/ev-cto/blob/master/knowledge/decisions/0002-workos-authkit-migration.md).

## The question

Can we add (a) MFA and (b) passkeys to the **embedded** login at `login.empowered.vote` — the own-domain page that calls the WorkOS Authentication API directly — **without** the hosted AuthKit page and **without** the $99/mo custom-domain add-on?

## Answer up front

| Feature | Headless? | Cost | Verdict |
|---|---|---|---|
| **MFA (TOTP)** | **Yes — full flow, no hosted page** | **$0** (free ≤ 1M MAU) | **Build it.** |
| **MFA (SMS)** | Yes, but discouraged | telephony pass-through, unpriced | **Exclude.** |
| **Passkeys** | **No — hosted AuthKit UI only** | n/a | **Defer** (blocked on vendor). |

The prior note said MFA and passkeys were both deferred and that passkeys are hosted-only. **The passkey finding still holds. The MFA finding is now out of date** — WorkOS exposes the whole TOTP flow through the raw Authentication API, and our code already has most of the plumbing.

## Decisions locked (2026-09-02, Chris Andrews)

| # | Decision | Choice | Consequence |
|---|---|---|---|
| 1 | MFA enforcement | **Opt-in from a Security settings page** | User enrolls while already logged in. We never hit the hard "enroll-during-login" path. No lockout risk. |
| 2 | MFA factor | **TOTP only** | Free, phishing-resistant enough, no SMS cost, no SIM-swap risk. |
| 3 | Recovery | **Admin-assisted reset** | Support removes the factor; user logs in with password and re-enrolls. No backup-code build. |
| 4 | Passkeys | **Hard no on any hosted surface → defer** | We keep 100% own-domain. Passkeys wait for a headless WorkOS WebAuthn API. |

---

## Vendor research (verified 2026-09-02, current WorkOS docs)

### MFA — the headless flow exists and is first-class

- **Enroll a factor** (SDK `userManagement.enrollAuthFactor`): `POST /user_management/users/{user_id}/auth_factors`, `type: 'totp'`, optional `totp_issuer` / `totp_user`. Returns an `authentication_factor` (id, `totp.qr_code`, `totp.secret`, `totp.uri`) **and** an `authentication_challenge` (id).
- **Login step-up**: the password grant returns an `mfa_challenge` state carrying a `pending_authentication_token` **and** an `authentication_challenge_id`. WorkOS creates the challenge for you at login.
- **Verify the TOTP code** (SDK `userManagement.authenticateWithTotp`): `POST /user_management/authenticate`, `grant_type = urn:workos:oauth:grant-type:mfa-totp`, with `code`, `authentication_challenge_id`, and `pending_authentication_token`. Returns `access_token` + `refresh_token` — the same session shape as the password grant, same issuer/JWKS/`external_id` claim. **The five verifying backends need no change.**
- If a user is required to enroll but has none, the authenticate step returns `mfa_enrollment` instead. **Opt-in avoids this state entirely** (an opted-in user always has a factor, so login always yields `mfa_challenge`).

### Passkeys — hosted-UI only

Current docs, quoted: *"Passkey authentication is currently only available with the hosted UI in AuthKit."* There is **no** WebAuthn registration/authentication API. The pricing page lists passkeys as an AuthKit feature, but only through the hosted `*.authkit.app` page. A headless passkey build is **not possible today at any price**.

### Cost

- **TOTP MFA: free.** AuthKit is free ≤ 1M MAU and includes MFA. We have ~22 users. No plan gate.
- **SMS MFA: avoid.** WorkOS discourages SMS (SIM-swap / NIST deprecation) and publishes **no** per-message price — it is telephony pass-through billed by arrangement. TOTP is the correct and free choice.
- **Radar** (breach/bot/rate-limit) stays out: first 1,000 checks free, then $100/mo per 50K. Not needed for MFA.
- **Custom domain ($99/mo): not required for any of this.**

---

## Part 1 — MFA (TOTP), the build

### Current code state — mostly plumbed already

- `backend/src/lib/workosAuthService.ts` — `AuthOutcome` already has an `mfa_required` variant carrying `pendingToken` **and** `challengeId`; `callAuthenticate()` already maps WorkOS `mfa_enrollment` / `mfa_challenge` → `mfa_required`. ✅
- `backend/src/routes/auth.ts` — `POST /workos/authenticate` already handles `mfa_required`: it stashes the pending token in the `ev_wos_pending` cookie and returns `{ status: 'mfa_required' }`. ✅ **But it drops `challengeId`** (auth.ts ~line 491).
- `admin/src/pages/Login.tsx` — the embedded flow reaches `mfa_required` and dead-ends with *"Multi-factor sign-in isn't available yet"* (Login.tsx ~line 246). The email-code step is the exact UI template to copy.
- `ev_wos_pending` cookie + `wosPendingCookieOptions()` + the `verify-email` route are a working template for the MFA verify leg.

**The existing plumbing is the right shape.** `mfa_required` already carries both fields the verify grant needs; the pending-cookie pattern already exists; `verify-email` is a working sibling. Nothing needs a rework. This is a build-on.

### Two phases

#### Phase A — Enrollment (opt-in, user already authenticated) — *new*

1. `ProfilePage.tsx` gains a **Security** panel: "Set up two-factor authentication".
2. Frontend → **new** `POST /api/account/mfa/enroll` (behind `requireAuth`).
3. Backend → `enrollAuthFactor({ userId: <WorkOS user id>, type: 'totp', totpIssuer: 'Empowered Vote', totpUser: email })`. Returns QR + secret + a challenge id.
4. Backend returns the QR (and secret for manual entry) + the challenge id (echo, or a short-lived cookie).
5. User scans the QR in an authenticator app, types the 6-digit code.
6. Frontend → **new** `POST /api/account/mfa/enroll/verify { code, challenge_id }`.
7. Backend verifies the enrollment challenge (`code` + `authentication_challenge_id`). No pending token here — the user already holds a full session. On success the factor is active.
8. `GET /api/account/mfa` reports factor status; `DELETE /api/account/mfa` lets a user self-disable (recommend a password re-entry / step-up before disabling).

#### Phase B — Login step-up (opted-in user signs in) — *close 3 small gaps*

1. Our form → `POST /api/auth/workos/authenticate` (**exists**).
2. Password grant → WorkOS `mfa_challenge` → `callAuthenticate` already returns `mfa_required` with `pendingToken` + `challengeId` (**exists**).
3. **Gap 1:** the route must also carry `challengeId` to the client (return it, or add an `ev_wos_challenge` cookie alongside `ev_wos_pending`).
4. **Gap 2:** `Login.tsx` needs an MFA code state (copy the email-code step; different copy: "Enter the code from your authenticator app"). Replace the dead-end at ~line 246.
5. Frontend → **new** `POST /api/auth/workos/verify-mfa { code }` (reads pending + challenge from cookies).
6. **Gap 3:** **new** service fn `authenticateWithTotp(code, challengeId, pendingToken)` (grant `urn:workos:oauth:grant-type:mfa-totp`) + **new** route. On success: set `ev_wos_session`, clear the pending/challenge cookies, return `{ access_token }`. This mirrors `verify-email` almost exactly.

### 🔴 Gotcha to design around — WorkOS user id vs `external_id`

`enrollAuthFactor` needs the **WorkOS user id** (`sub`, `user_…`). But `requireAuth` attaches `req.userId` = the **internal** id (= `external_id` = the Supabase UUID), by design — the raw `sub` is read **only** inside `tokenIdentity.ts` (the "one mapping place", privacy property A). So the enroll route cannot call WorkOS management APIs from `req.userId` alone.

Cleanest fix that keeps the invariant: add a `tokenIdentity` helper (e.g. `workosUserId(payload)`) that returns the raw `sub` **only** for WorkOS tokens, used **solely** to address WorkOS management APIs — never as an internal identifier. Do **not** try to filter WorkOS `List Users` by `external_id` (not a supported filter). Decide this in planning; it is a small, contained addition, but it touches a guarded module, so name it explicitly.

### New surface, summarized

- Backend, authenticated (enrollment): `POST /api/account/mfa/enroll`, `POST /api/account/mfa/enroll/verify`, `GET /api/account/mfa`, `DELETE /api/account/mfa`.
- Backend, unauthenticated (login step-up): `POST /api/auth/workos/verify-mfa`; plus carry `challengeId` out of `/workos/authenticate`.
- Backend service: new fns wrapping `enrollAuthFactor`, the enrollment verify, list/remove factor, and `authenticateWithTotp`.
- Frontend: `Login.tsx` MFA code state; `ProfilePage.tsx` Security panel; new client methods in `admin/src/lib/workosAuth.ts`.
- Flag: reuse `VITE_EMBEDDED_AUTH` or add `VITE_MFA`; stage per origin like the login rollout, founder cohort first.
- Rate-limit: reuse `authLimiter` on `verify-mfa`; a separate limiter on `enroll`.

### Recovery runbook (admin-assisted)

- User loses their authenticator → support removes the factor (WorkOS dashboard: User → Authentication → remove factor, or our own admin action calling delete-factor).
- Because MFA is **opt-in, not forced**, removing the factor leaves password login working again — no lockout state. The user logs in and re-enrolls.
- Optional later: a small `/admin` "reset MFA for user X" button. Not needed to ship.

---

## Part 2 — Passkeys

### Finding — hosted-only, deferred

There is no headless WebAuthn API. A passkey build today requires a hosted `*.authkit.app` entry point.

### Why "hard no" on a minimal hosted entry

A passkeys-only redirect would put **some** logins back on `authkit.app` — the foreign-domain credential prompt and the broken `empowered.vote` autofill that this whole project removed. Even scoped to passkey users, it reintroduces exactly the problem the project exists to solve, and it splits the login surface across two domains. So passkeys are **blocked on vendor**: watch the WorkOS changelog for a headless WebAuthn API and revisit when it ships.

TOTP MFA (Part 1) is the interim substitute for the second-factor security passkeys would add. (TOTP is not phishing-resistant the way passkeys are, but it is the strongest option available headless.)

---

## Part 3 — Recommendation

### Feasible without $99?

- **MFA (TOTP): yes, fully, $0.** Recommended to build.
- **Passkeys: no** headless path at any price short of a hosted surface (a hard no). Deferred.

### Rough effort

- **Login step-up (Gaps 1–3):** small — high reuse of the `verify-email` pattern. ~half a session.
- **Enrollment + Security UI + the `tokenIdentity` helper + recovery runbook:** medium — one new service module, ~4 authenticated routes, one `ProfilePage` panel. ~1–2 sessions.
- **Total MFA: ~2–3 focused sessions** including a staging bake with a founder account.
- **Passkeys: 0** (deferred).

### Suggested sequence

1. **MFA first** — it is the only feasible item.
   - Build **enrollment** first (endpoints + Security UI + the `tokenIdentity` helper): you need a way to *get* a factor before a login challenge is testable.
   - Then the **login step-up** (close the 3 gaps).
   - Ship both behind one flag; stage per origin (`login` → `app` → VQ), founder cohort first, mirroring the embedded-login rollout.
2. **Passkeys** — park; watch the WorkOS changelog for headless WebAuthn.

### Plan / pricing gates

- **None** for TOTP MFA. Free ≤ 1M MAU (we have ~22 users).
- SMS excluded (unpriced, discouraged).
- Radar excluded. Custom domain **not** required.

---

## Open items to confirm in planning (not blockers)

- Exact **enrollment-verify** call and whether WorkOS requires a recent/step-up authentication to enroll. Confirm with one scripted call against staging. **Chris runs any script with his own key — this doc handles no credentials.**
- The **`tokenIdentity.workosUserId` helper** shape (returns `sub` for WorkOS tokens only, management-API use only).
- Carry `challengeId` out of `/workos/authenticate` — cookie (`ev_wos_challenge`) vs echo. Prefer cookie for posture; confirm single-use TTL.
- Confirm the **remove-factor** endpoint / SDK method name for the delete route and the admin reset.
- Rate-limit the new endpoints.

## What NOT to do

- Do **not** add SMS.
- Do **not** add any `authkit.app` hosted surface for passkeys.
- Do **not** force MFA — opt-in avoids enroll-during-login and lockout.
- Do **not** buy Radar or the custom domain.

## Acceptance / verification (against WorkOS staging = founder cohort)

- A logged-in user opens Security, scans the QR, enters the code, and MFA turns on — all on `empowered.vote`.
- That user logs out and back in: password → authenticator code → session, no trip to `authkit.app`.
- A user **without** MFA logs in exactly as today (no code step).
- Admin removes a user's factor; that user logs in with password alone and can re-enroll.
- The rate-limiter still trips; break-glass `/login/classic` unaffected.

## Sources

- [Authenticate reference — TOTP grant](https://workos.com/docs/reference/authkit/authentication/totp)
- [User Management MFA guide](https://workos.com/docs/user-management/mfa)
- [MFA API — enroll / challenge / verify](https://workos.com/blog/getting-started-with-the-workos-multi-factor-authentication-api)
- [AuthKit passkeys (hosted-only)](https://workos.com/docs/authkit/passkeys)
- [WorkOS pricing](https://workos.com/pricing)
- [WorkOS Node SDK — user authentication](https://mintlify.wiki/workos/workos-node/guides/user-authentication)
