# Requirements: Empowered Accounts — v1.1 XP & Progression

**Defined:** 2026-03-04
**Core Value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.

---

## v1.1 Requirements

### XP Ledger

- [ ] **XPLED-01**: `connect.xp_transactions` append-only table with columns: id, user_id, source (text), amount (int), metadata (jsonb), idempotency_key (text, unique), created_at
- [ ] **XPLED-02**: `total_xp` column on `connect.connected_profiles`, updated atomically on each XP award
- [ ] **XPLED-03**: `current_level` column on `connect.connected_profiles`, updated atomically on each XP award
- [ ] **XPLED-04**: RLS on xp_transactions: authenticated user reads own rows, no user writes, admin reads all
- [ ] **XPLED-05**: `award_xp` Postgres RPC: atomic INSERT to xp_transactions + UPDATE to connected_profiles (total_xp, current_level) in a single transaction

### Level Calculation

- [ ] **LEVEL-01**: SQL level calculation function using tiered thresholds — 2,000 XP × 3 levels, then 3,000 XP × 6 levels, then 4,000 XP × 20 levels, then 5,000 XP per level thereafter
- [ ] **LEVEL-02**: `xp_in_level` and `xp_to_next_level` computed on read and returned in API responses (enables progress bar rendering in feature repos)

### XP Award API

- [ ] **XPAPI-01**: `POST /api/xp/award` — server-to-server endpoint, validates `X-Service-Key` header against env secret, validates user_id (must be Connected+), source, and amount
- [ ] **XPAPI-02**: Source types enforced as known enum: `ctc_game`, `ctc_perfect_bonus`, `validation_quest` (schema extensible for future sources)
- [ ] **XPAPI-03**: Idempotency key required on every award — duplicate submissions with same key return 200 with the original transaction, no double-award
- [ ] **XPAPI-04**: `GET /account/me` response includes `xp` object: `{ total, level, xp_in_level, xp_to_next_level }`
- [ ] **XPAPI-05**: `GET /api/xp/:userId` — public unauthenticated endpoint returning `{ level, total_xp }` only (no full ledger)
- [ ] **XPAPI-06**: `GET /api/xp/me/history` — authenticated, returns own XP ledger entries: source, amount, metadata, created_at

### Admin Tool

- [ ] **XPADM-01**: XP summary displayed in account header view: total XP and current level
- [ ] **XPADM-02**: XP History tab on account detail page — full ledger view (source, amount, metadata, timestamp per entry)

---

## Future Requirements (not in v1.1 roadmap)

### XP Unlocks

- **UNLOCK-01**: Level gates for Validation Quest difficulty tiers (currently based on accuracy/submissions; XP level not yet wired)
- **UNLOCK-02**: Platform role grant on reaching a level threshold (future)
- **UNLOCK-03**: CTC ranked mode or advanced formats unlocked by level (future)

### Additional XP Sources

- **XPSRC-01**: XP from Symposium participation
- **XPSRC-02**: XP from Empowered Bills engagement
- **XPSRC-03**: XP from Awareness Exchange activity

---

## Out of Scope (v1.1)

| Feature | Reason |
|---------|--------|
| XP leaderboards | Not requested; could drive unhealthy competition at Alpha scale |
| Level-gated feature unlocks | Designed but not wired in this milestone — infrastructure ready |
| End-user frontend display | Feature repos (CTC, VQ, etc.) consume the API and render XP bar |
| XP decay or expiry | Not part of platform philosophy; XP is permanent civic record |
| VQ internal badge tier changes | VQ Novice→Legendary tiers stay in VQ design; this milestone only adds unified XP alongside them |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| XPLED-01 | Phase 9 | Pending |
| XPLED-02 | Phase 9 | Pending |
| XPLED-03 | Phase 9 | Pending |
| XPLED-04 | Phase 9 | Pending |
| XPLED-05 | Phase 9 | Pending |
| LEVEL-01 | Phase 9 | Pending |
| LEVEL-02 | Phase 9 | Pending |
| XPAPI-01 | Phase 10 | Pending |
| XPAPI-02 | Phase 10 | Pending |
| XPAPI-03 | Phase 10 | Pending |
| XPAPI-04 | Phase 10 | Pending |
| XPAPI-05 | Phase 10 | Pending |
| XPAPI-06 | Phase 10 | Pending |
| XPADM-01 | Phase 11 | Pending |
| XPADM-02 | Phase 11 | Pending |

**Coverage:**
- v1.1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-04*
*Last updated: 2026-03-04 after initial definition*
