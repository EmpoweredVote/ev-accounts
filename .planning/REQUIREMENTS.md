# Requirements: Empowered Accounts v1.5

**Defined:** 2026-03-19
**Core Value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.

## v1.5 Requirements

### Referral UI

- [x] **REF-01**: Connected user at level ≥ 2 sees their referral code on the profile dashboard with a one-click copy button
- [x] **REF-02**: Connected user at level < 2 sees a locked referral card explaining the level 2 requirement
- [x] **REF-03**: Connected user whose invitee has not yet reached level 2 sees a "waiting" state on the referral card
- [x] **REF-04**: Referral card reflects the current state accurately on every profile load (backend `GET /api/referral` drives all three states)

### CompassV2 Integration Guide

- [x] **CDOC-01**: Guide covers the full auth flow — how CompassV2 redirects to `accounts.empowered.vote` for login/signup and receives the token back via hash fragment
- [x] **CDOC-02**: Guide documents all compass API endpoints with request/response shapes and auth requirements
- [x] **CDOC-03**: Guide explains tier-based access — what anonymous/Inform vs Connected users can do in compass
- [x] **CDOC-04**: Guide covers jurisdiction usage — how CompassV2 reads the `jurisdiction` block from `/api/account/me` to personalize the experience without asking for an address
- [x] **CDOC-05**: Guide articulates the three-pillar platform philosophy (Inform / Connected / Empowered) so CompassV2 implements the correct degraded vs enhanced experience
- [x] **CDOC-06**: Guide replaces `docs/COMPASS_CONTRACT.md` as the canonical CompassV2 reference

### Essentials Integration Guide

- [ ] **EDOC-01**: Guide covers the "never ask address again" principle with concrete implementation pattern: check `jurisdiction` on `/api/account/me` → non-null means Connected, use it silently; null means anonymous/Inform, show local address input
- [ ] **EDOC-02**: Guide documents the two-state UX pattern — anonymous/Inform (local address input, no persistence) vs Connected (jurisdiction from accounts, fully automatic)
- [ ] **EDOC-03**: Guide covers optional auth flow for Inform Pillar features — how to detect if a user is Connected without requiring it, and how to surface a "connect your account" prompt for jurisdiction persistence
- [ ] **EDOC-04**: Guide articulates the three-pillar platform philosophy with emphasis on Inform Pillar rules: accessible to everyone, no auth required, information flows one direction
- [ ] **EDOC-05**: Guide specifies all jurisdiction field names and their canonical string formats (with examples from prod data)
- [ ] **EDOC-06**: Guide covers the auth flow for when Essentials wants to offer Connected enhancements (XP, gem awards, persistence) as opt-in on top of the anonymous experience

## Future Requirements

### Deferred from previous milestones

- **COMP-05**: User-to-user compass compare — infrastructure in place, politician compare only in v1
- **CIVIC-02**: Gem reserve cap — deferred for Alpha
- **ROLES-01**: Scoped roles system — replace flat `is_admin` with feature-scoped permissions (Dev access, community admin, compass curator)
- **VR-F01**: VR admin dashboard — visualize Verification Rating data across users

## Out of Scope

| Feature | Reason |
|---------|--------|
| Roles/permissions system | v1.6 — architectural work that deserves its own milestone |
| User-to-user compass compare | Deferred since v1.0, not needed for partner integrations |
| VR admin dashboard | Deferred, not blocking any partner integration |
| Framer/production end-user frontend | Lives in feature repos, not accounts |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REF-01 | Phase 31 | Pending |
| REF-02 | Phase 31 | Pending |
| REF-03 | Phase 31 | Pending |
| REF-04 | Phase 31 | Pending |
| CDOC-01 | Phase 32 | Pending |
| CDOC-02 | Phase 32 | Pending |
| CDOC-03 | Phase 32 | Pending |
| CDOC-04 | Phase 32 | Pending |
| CDOC-05 | Phase 32 | Pending |
| CDOC-06 | Phase 32 | Pending |
| EDOC-01 | Phase 33 | Pending |
| EDOC-02 | Phase 33 | Pending |
| EDOC-03 | Phase 33 | Pending |
| EDOC-04 | Phase 33 | Pending |
| EDOC-05 | Phase 33 | Pending |
| EDOC-06 | Phase 33 | Pending |

**Coverage:**
- v1.5 requirements: 16 total
- Mapped to phases: 16 ✓
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-19*
*Last updated: 2026-03-19 after roadmap creation*
