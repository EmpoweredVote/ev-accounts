# Requirements: Empowered Accounts v1.4

**Defined:** 2026-03-15
**Core Value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.

## v1.4 Requirements

### PROFILE — Profile Hub UI

- [ ] **PROFILE-01**: Connected user sees their tier, level, XP, gem balances (yellow/blue/red), and Verification Rating on their profile page
- [ ] **PROFILE-02**: Connected user can submit their address via a form on the profile page (calls existing `POST /connect/set-location`)
- [ ] **PROFILE-03**: Profile page displays a feature hub with cards for all live Empowered Vote features (CTC, VQ, Essentials, Read & Rank, Treasury Tracker) — each with a short description and link
- [ ] **PROFILE-04**: Feature hub shows only live features; each card communicates "explore freely, connect to save"

### VR — Verification Rating

- [ ] **VR-01**: `connected_profiles` gains `verification_rating integer NOT NULL DEFAULT 60` and `vq_hold_until timestamptz`
- [ ] **VR-02**: `GET /api/account/me` returns `verification_rating` and `vq_hold_active: boolean` (derived from `vq_hold_until`)
- [ ] **VR-03**: Verification Rating of 90+ unlocks Red Gem Quests (returned as `red_gem_quests_unlocked: boolean` on `/me`)
- [ ] **VR-04**: Verification Rating reaching 0 sets `vq_hold_until = now() + interval '30 days'`; user cannot participate in VQ during hold
- [ ] **VR-05**: Admin can manually adjust a user's `verification_rating` and clear `vq_hold_until` via admin tool

### VQ — VQ Answer Confirmation Flow

- [ ] **VQ-01**: `POST /api/vq/confirm-stance` — service-key authenticated endpoint; accepts `{ politician_id, topic_id, confirmed_value, correct_user_ids[], incorrect_user_ids[], idempotency_key }`
- [ ] **VQ-02**: Correct answerers receive Red Gems (`gem_type = 'red'`) via existing `credit_gems` RPC; amount configurable per VQ service key
- [ ] **VQ-03**: Correct answerers' `verification_rating` incremented by 3 (max cap: 150)
- [ ] **VQ-04**: Incorrect answerers' `verification_rating` decremented by 10; if rating reaches 0, `vq_hold_until` set to 30 days from now
- [ ] **VQ-05**: Confirmed stance written to `inform.politician_answers` (upsert); stance becomes the authoritative value
- [ ] **VQ-06**: `POST /api/vq/confirm-stance` is idempotent — re-sending same `idempotency_key` returns original result without re-awarding gems or re-adjusting ratings

### INTEG — Integration Verification

- [ ] **INTEG-01**: CTC service key configured in production; `POST /api/xp/award` and `POST /api/gems/award` (yellow) verified live with real CTC game event
- [ ] **INTEG-02**: VQ service key configured in production; `POST /api/vq/confirm-stance` verified live with a test confirmation event
- [ ] **INTEG-03**: `docs/ONBOARDING-VQ.md` updated to document the new `/vq/confirm-stance` endpoint

## Future Requirements

### Post-v1.4 Profile

- **PROFILE-F01**: Feature hub cards surface saved user data from Read & Rank and Treasury Tracker (requires those apps to push data to accounts API)
- **PROFILE-F02**: Compass feature card added to hub once CompassV2 integration ships (v1.5)

### Post-v1.4 Verification

- **VR-F01**: Admin dashboard view showing Verification Rating distribution across user base
- **VR-F02**: Malice/apathy detection — users with repeated hold cycles flagged for human review

### Post-v1.4 Compass

- **COMP-05**: User-to-user compass compare (deferred from v1.0; infrastructure in place)
- **COMP-06**: Compass comparison data endpoint for Essentials overlay (v1.5)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Rendering compass overlay visuals | Essentials renders; accounts serves data only (v1.5) |
| Read & Rank / Treasury Tracker data persistence | Requires those apps to integrate with accounts API — future milestone |
| Gem reserve cap | Deferred per CIVIC-02 |
| User-to-user compass compare | v1.5 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PROFILE-01 | Phase 30 | Pending |
| PROFILE-02 | Phase 30 | Pending |
| PROFILE-03 | Phase 30 | Pending |
| PROFILE-04 | Phase 30 | Pending |
| VR-01 | Phase 27 | Pending |
| VR-02 | Phase 27 | Pending |
| VR-03 | Phase 27 | Pending |
| VR-04 | Phase 27 | Pending |
| VR-05 | Phase 29 | Pending |
| VQ-01 | Phase 28 | Pending |
| VQ-02 | Phase 28 | Pending |
| VQ-03 | Phase 28 | Pending |
| VQ-04 | Phase 28 | Pending |
| VQ-05 | Phase 28 | Pending |
| VQ-06 | Phase 28 | Pending |
| INTEG-01 | Phase 29 | Pending |
| INTEG-02 | Phase 29 | Pending |
| INTEG-03 | Phase 29 | Pending |

**Coverage:**
- v1.4 requirements: 18 total
- Mapped to phases: 18 ✓
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-15*
*Last updated: 2026-03-15 — traceability table filled after roadmap creation*
