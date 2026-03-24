# SSO Cross-App Smoke Test

**Audience:** Chris (ops)
**Last updated:** 2026-03-24
**Purpose:** Manual browser-based checklist verifying that SSO works end-to-end across all five Empowered Vote apps in production. Reusable for regression testing after auth changes.

---

## Overview

| Test | Flow | What It Verifies |
|------|------|-----------------|
| SSO-01 | Session Inheritance | Login once at accounts, all five apps inherit session |
| SSO-02 | Single Logout | Logout from one app clears session across all apps |
| SSO-03 | Graceful Degradation | No session present = Inform-baseline UI, no errors |

**Environment:** Production only
**Prerequisites:**
- A Connected-tier test account on accounts.empowered.vote
- A modern browser (Chrome, Firefox, or Safari)
- All cookies cleared for *.empowered.vote before starting

---

## Run Metadata

| Field | Value |
|-------|-------|
| **Run date** | |
| **Browser + version** | |
| **Environment** | Production |
| **Tester** | |
| **Overall result** | |

---

## SSO-01: Session Inheritance (Happy Path)

**Scenario:** Login at accounts.empowered.vote, then visit each app — each should show authenticated state without re-prompting for login.

### Steps

- [ ] **1.1** Clear all cookies for `*.empowered.vote`
- [ ] **1.2** Navigate to `https://accounts.empowered.vote/login`
- [ ] **1.3** Log in with test account credentials
- [ ] **1.4** Confirm login succeeds (redirected to Profile Hub or expected destination)
- [ ] **1.5** Open `https://app.empowered.vote` (Profile Hub) in the same browser — confirm authenticated state (user name/profile visible, no login prompt)
- [ ] **1.6** Open `https://ctc.empowered.vote` (CTC) — confirm authenticated state (game loads with user context, no login redirect)
- [ ] **1.7** Open `https://essentials.empowered.vote` (Essentials) — confirm authenticated state (user-specific content visible, no login redirect)
- [ ] **1.8** Open `https://compass.empowered.vote` (CompassV2) — confirm authenticated state (compass loads with user answers, no login redirect)
- [ ] **1.9** Open `https://quests.empowered.vote` (Validation Quests) — confirm authenticated state (quests load with user progress, no login redirect)

**Result:** [ PASS / FAIL ]
**Notes:**

---

## SSO-02: Single Logout

**Scenario:** Logout from a child app (not accounts) — all apps should show unauthenticated state on next visit.

### Steps

- [ ] **2.1** Starting from authenticated state (SSO-01 complete)
- [ ] **2.2** On `https://ctc.empowered.vote`, trigger logout (use the app's logout button/menu)
- [ ] **2.3** Confirm CTC shows unauthenticated state (login prompt or public landing)
- [ ] **2.4** Visit `https://accounts.empowered.vote` — confirm unauthenticated (login page shown)
- [ ] **2.5** Visit `https://app.empowered.vote` — confirm unauthenticated (redirected to login or public view)
- [ ] **2.6** Visit `https://essentials.empowered.vote` — confirm unauthenticated (Inform-baseline UI)
- [ ] **2.7** Visit `https://compass.empowered.vote` — confirm unauthenticated (Inform-baseline UI)
- [ ] **2.8** Visit `https://quests.empowered.vote` — confirm unauthenticated (Inform-baseline UI)
- [ ] **2.9** Open browser DevTools → Application → Cookies → `.empowered.vote` — confirm `ev_session` cookie is absent

**Result:** [ PASS / FAIL ]
**Notes:**

---

## SSO-03: Graceful Degradation (No Session)

**Scenario:** With no session present, visit each app — no broken pages, no redirect loops, Inform-baseline UI renders cleanly.

### Steps

- [ ] **3.1** Clear all cookies for `*.empowered.vote` (fresh browser state)
- [ ] **3.2** Visit `https://accounts.empowered.vote` — confirm login page renders cleanly
- [ ] **3.3** Visit `https://app.empowered.vote` — confirm no error page, no redirect loop (login redirect or public landing is acceptable)
- [ ] **3.4** Visit `https://ctc.empowered.vote` — confirm game loads in unauthenticated/public mode (no crash, no infinite redirect)
- [ ] **3.5** Visit `https://essentials.empowered.vote` — confirm Inform-baseline UI renders (public content visible)
- [ ] **3.6** Visit `https://compass.empowered.vote` — confirm Inform-baseline UI renders (public content visible)
- [ ] **3.7** Visit `https://quests.empowered.vote` — confirm Inform-baseline UI renders (public content visible)

**Result:** [ PASS / FAIL ]
**Notes:**

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| App shows login prompt despite ev_session present | App not calling GET /api/auth/session with `credentials: 'include'` | Check fetch options in app's SSO init code |
| Logout from one app doesn't clear others | POST /api/auth/logout not clearing .empowered.vote cookie | Check cookie domain and path in logout handler |
| Redirect loop on any app | App's auth guard redirecting to accounts, which redirects back | Check redirect URL validation in accounts login flow |
| ev_session cookie still present after logout | Cookie set on wrong domain or path mismatch | Inspect Set-Cookie header in logout response |
| App crashes with no session | App code assumes session always exists (missing null check) | Check app's auth initialization for graceful fallback |

---

## Failure Protocol

If any test fails:
1. Document the failure inline in the Notes field for that test
2. Continue running remaining tests (don't stop)
3. After completing all tests, create a targeted fix task for each failure
4. Phase 48 stays incomplete until a clean re-run passes all three tests
