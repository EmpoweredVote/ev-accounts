# Requirements: Empowered Accounts v1.7

**Defined:** 2026-03-24
**Core Value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.

## v1.7 Requirements — Cross-App SSO

Log in once at any Empowered Vote app; remain authenticated across all apps for the session duration. All apps respect the Inform-baseline / Connected-enhanced pattern — SSO only surfaces a Connected experience if a session already exists; unauthenticated users always reach the public experience.

### Accounts API

- [x] **SSO-01**: Login sets an httpOnly `ev_session` cookie on `.empowered.vote` domain containing the Supabase refresh token (Secure, SameSite=Lax)
- [x] **SSO-02**: `GET /api/auth/session` — CORS-enabled for `*.empowered.vote`; reads `ev_session` cookie, exchanges refresh token for fresh access + refresh pair, returns tokens to caller; fails fast (no cookie = unauthenticated, not an error)
- [x] **SSO-03**: `POST /api/auth/logout` clears the `ev_session` cookie in addition to existing Supabase session revocation; signing out of any app signs out everywhere

### Profile Hub (app.empowered.vote)

- [ ] **SSO-04**: On load, if no local token exists, silently calls `GET /api/auth/session` before rendering as unauthenticated

### CTC (Civic Trivia Championships)

- [ ] **SSO-05**: On load, if no `ev_refresh_token` in localStorage, silently calls `GET /api/auth/session` before rendering as unauthenticated
- [ ] **SSO-06**: Logout calls `POST /api/auth/logout` to clear the shared cookie

### Essentials

- [ ] **SSO-07**: On load, if no local token exists, silently calls `GET /api/auth/session` before rendering as unauthenticated
- [ ] **SSO-08**: Logout calls `POST /api/auth/logout` to clear shared cookie

### Validation Quests

- [ ] **SSO-09**: On load, if Supabase has no active session, silently calls `GET /api/auth/session` and initializes session via `supabase.auth.setSession()` with returned tokens
- [ ] **SSO-10**: Logout calls `POST /api/auth/logout` to clear shared cookie in addition to `supabase.auth.signOut()`

### CompassV2

- [ ] **SSO-11**: On load, if no local token exists, silently calls `GET /api/auth/session` before rendering as unauthenticated
- [ ] **SSO-12**: Logout calls `POST /api/auth/logout` to clear shared cookie

### Compliance

- [ ] **SSO-13**: Privacy policy (or in-app disclosure on accounts.empowered.vote) documents the `ev_session` cookie on `.empowered.vote` as strictly necessary for authentication — no opt-in consent banner required under GDPR/CCPA

## Future Requirements (v1.8)

### Civic Identity & Roles (deferred from v1.6)

- **ROLES-01**: Scoped roles system — feature × geography permission model (CTC Dev, Quest Dev, Essentials Dev, Compass Dev + jurisdiction_geoid)
- **VR-F01**: VR admin dashboard — visualize Verification Rating distribution, holds, outliers
- **COMP-05**: User-to-user compass compare API
- **ESSENTIALS-PROV**: Essentials XP source provisioning

## Out of Scope

| Feature | Reason |
|---------|--------|
| Treasury Tracker SSO | Fully public data portal with no auth concept — SSO not applicable |
| Cookie consent banner | `ev_session` is strictly necessary for authentication — exempt from GDPR/CCPA opt-in |
| Single sign-out from Supabase dashboard session | Out-of-band auth management not in scope |
| SSO token caching in Redis | Alpha scale doesn't warrant it; stateless cookie exchange is sufficient |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SSO-01 | Phase 44 | Complete |
| SSO-02 | Phase 44 | Complete |
| SSO-03 | Phase 44 | Complete |
| SSO-04 | Phase 45 | Pending |
| SSO-05 | Phase 45 | Pending |
| SSO-06 | Phase 45 | Pending |
| SSO-07 | Phase 46 | Pending |
| SSO-08 | Phase 46 | Pending |
| SSO-09 | Phase 47 | Pending |
| SSO-10 | Phase 47 | Pending |
| SSO-11 | Phase 46 | Pending |
| SSO-12 | Phase 46 | Pending |
| SSO-13 | Phase 48 | Pending |

**Coverage:**
- v1.7 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-24*
*Last updated: 2026-03-24 after initial definition*
