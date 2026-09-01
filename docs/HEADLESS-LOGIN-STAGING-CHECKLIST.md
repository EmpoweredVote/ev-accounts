# Headless login — staging acceptance checklist

Run this before and during the first-origin enable of `VITE_EMBEDDED_AUTH`. It is the
human-gated verification the design and plan defer to a real environment.

- Design: [`docs/HEADLESS-LOGIN-DESIGN.md`](HEADLESS-LOGIN-DESIGN.md)
- Rollout + env: [`DEPLOY.md`](../DEPLOY.md) → "Headless embedded login"
- Flipping `VITE_EMBEDDED_AUTH=true` on any **production** frontend is STOP-AND-ASK.

## Part A — pre-flight (do these BEFORE flipping any flag)

| # | Check | How | Pass |
|---|---|---|---|
| A1 | `COOKIE_DOMAIN=.empowered.vote` on `ev-accounts-api` | Render → service → Environment | value is exactly `.empowered.vote` |
| A2 | WorkOS response shapes match our parser | `node backend/scripts/workos-headless-smoke.mjs` (staging key + test users in env) | no `✗ MISMATCH` lines; verified→tokens, unverified→`email_verification_required` + `pending_authentication_token`, wrong password→`invalid_credentials`/401 |
| A3 | Password-reset email link target | same script with `SMOKE_RESET_EMAIL`, then open the inbox | link is `login.empowered.vote/reset-password?token=…` (not a WorkOS-hosted URL) |
| A4 | Staging login origin (only if testing cross-app on staging) | set `VITE_LOGIN_ORIGIN` on the staging **app** build to the staging login hub | `app` staging redirects to the staging login, not prod |

If A2 shows a mismatch, fix the matcher in `backend/src/lib/workosAuthService.ts` and its unit
test, then re-run `npx vitest run src/lib/workosAuthService.test.ts` before proceeding.

## Part B — first origin: `login.empowered.vote` (admin build)

Enable `VITE_EMBEDDED_AUTH=true` on the admin build only, rebuild, deploy. Keep the hosted
redirect and `/login/classic` reachable. Then walk these with a test/founder account:

- [ ] **B1 — Existing user logs in.** Go to `/login`. You see OUR email/password form (no trip to `authkit.app`). Log in → land on `/profile`. In DevTools → Application → Cookies, confirm an httpOnly `ev_wos_session` cookie on `.empowered.vote`.
- [ ] **B2 — Autofill works.** The password manager offers a saved `empowered.vote` credential on the form (the whole point of this project).
- [ ] **B3 — New signup + verify in one sitting.** Sign up a fresh account → the page shows the 6-digit code step (no navigation away). Enter the emailed code → you are verified AND logged in, no separate sign-in.
- [ ] **B4 — Reload persists the session.** Hard-reload the tab → still logged in (cookie restore). Open a second tab on `login.empowered.vote` → logged in.
- [ ] **B5 — Multi-tab refresh (rotation race).** With two tabs open on the app, leave them idle long enough for a background `/api/auth/session` refresh in each (or force a 401). Neither tab gets logged out. (This is the refresh-token rotation item — if a spurious logout appears, capture it and stop.)
- [ ] **B6 — Password reset changes the WorkOS credential.** Use "forgot password", complete the reset from the emailed link on `login.empowered.vote/reset-password`, then log in with the NEW password. It works. (Note: a reset revokes existing WorkOS sessions.)
- [ ] **B7 — Wrong password.** A wrong password shows "Invalid email or password" — the same message a wrong email gives (no account enumeration).
- [ ] **B8 — Break-glass still classic.** `/login/classic` renders the classic Supabase form and logs in via `/api/auth/login` (not the WorkOS endpoint).
- [ ] **B9 — Logout ends the session.** Log out from the admin sidebar AND from the profile page. Reload → you are logged OUT (the `ev_wos_session` cookie is gone; no silent re-login).
- [ ] **B10 — Rate limit holds.** More than 10 failed logins in 15 minutes from one IP returns the rate-limit response.
- [ ] **B11 — MFA guard (only if MFA is enrolled for a test user).** An MFA-enrolled user sees "Multi-factor sign-in isn't available yet", not a dead code box. (MFA is out of scope; this only confirms it fails gracefully.)

Bake B1–B11 for the agreed window, watching Render logs for `401`/`5xx` on `/api/auth/workos/*`, `/api/auth/session`, and `/api/account/me`.

## Part C — second origin: `app.empowered.vote`

Enable `VITE_EMBEDDED_AUTH=true` on `empowered-vote-app`, rebuild, deploy.

- [ ] **C1 — Cross-app SSO.** Log in at `login.empowered.vote`, then visit `app.empowered.vote` → you are already logged in (shared `ev_wos_session` cookie). This is the SSO that the browser-SDK approach had given up.
- [ ] **C2 — App sign-in redirects to central login.** From a logged-out `app.empowered.vote/login`, sign-in goes to `login.empowered.vote/login?redirect=…` (our domain, not `authkit.app`), and returns you to the app logged in.

## Part D — third origin: validation-quests (separate repo)

- [ ] **D1** — Apply the same one-line redirect change + `VITE_EMBEDDED_AUTH` in `validation-quests-frontend`, then repeat C1/C2 for that origin.

## If anything fails

Turn `VITE_EMBEDDED_AUTH` back off on that origin (rebuild) — the hosted redirect and
`/login/classic` are the fallbacks and were never removed. Nothing else needs reverting.
