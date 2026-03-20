# Requirements: Empowered Accounts v1.6

**Defined:** 2026-03-19
**Core Value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.

## v1.6 Requirements — Platform Consolidation

Merge all Empowered Vote backend services into ev-accounts as the single database, single Express API, and single auth system.

### Database Migration

- [ ] **CONS-01**: `essentials`, `staging`, `treasury`, `meetings`, `validation_quests`, `trivia` schemas created in ev-accounts Supabase project
- [ ] **CONS-02**: All 52 EV-Backend tables imported with data verified (row counts match source)
- [ ] **CONS-03**: RLS enabled on every migrated table (Go backend currently has none)
- [ ] **CONS-04**: GRANT permissions set per schema; Supabase auth service role and anon role correctly scoped

### Politician Deduplication

- [ ] **CONS-05**: `public.politician_id_bridge` mapping table created (essentials ID ↔ inform ID)
- [ ] **CONS-06**: `inform.politician_answers` and `inform.politician_context` migrated to reference `essentials.politicians` IDs
- [ ] **CONS-07**: `inform.politicians` dropped; `essentials.politicians` is single source of truth

### Express Endpoint Ports

- [ ] **CONS-08**: Treasury endpoints ported (~5 routes, read-only public data)
- [ ] **CONS-09**: Meetings endpoints ported (~8 routes, public read + admin write)
- [ ] **CONS-10**: Staging endpoints ported (~15 routes, review workflow, role-gated)
- [ ] **CONS-11**: Essentials core endpoints ported (~25 routes incl. PostGIS address→politician lookup using Census Geocoder)
- [ ] **CONS-12**: Missing Compass endpoints added (compare, verdicts, admin CRUD, batch politician answers)
- [ ] **CONS-13**: Compass `value` CHECK constraint updated 1–5 → 0.5–5.5

### Frontend Auth Updates

- [ ] **CONS-14**: CompassV2 — `credentials: "include"` replaced with `Authorization: Bearer`; API URL updated
- [ ] **CONS-15**: Essentials app — Bearer token auth; API URL updated
- [ ] **CONS-16**: Read & Rank — Bearer token auth; API URL updated
- [ ] **CONS-17**: Treasury Tracker — API URL updated (public data, no auth change needed)

### VQ + Trivia Consolidation

- [ ] **CONS-18**: `validation_quests` schema imported from VQ Supabase; DATABASE_URL updated on Render
- [ ] **CONS-19**: `trivia` schema imported; politician foreign keys updated to `essentials.politicians`

### Decommission & DNS

- [ ] **CONS-20**: Zero traffic verified on `api.empowered.vote` (Go server)
- [ ] **CONS-21**: EV-Backend scaled to zero; repo archived
- [ ] **CONS-22**: `api.empowered.vote` DNS cutover to ev-accounts Express server; CORS + frontend env vars updated

### Integration Documentation

- [ ] **CONS-23**: Updated integration doc for Chris Andrews' team — all ev-accounts changes documented (new endpoints, auth model, unified politician IDs, value range fix, new schema inventory)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Data import pipelines (Congress.gov, LegiScan, OpenStates) | Not ev-accounts' responsibility; data strategy uses VQ crowdsourcing + Claude-assisted manual builds |
| Google Maps geocoding | Chris Andrews investigating separately; Census Geocoder stays for now |
| Scoped roles system (ROLES-01) | Deferred to v1.7 — better built on unified platform |
| VR admin dashboard (VR-F01) | Deferred to v1.7 |
| User-to-user compass compare (COMP-05) | Deferred to v1.7 — benefits from unified politician IDs |
| Essentials XP provisioning (ESSENTIALS-PROV) | Deferred to v1.7 (env var only, no blocking risk) |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CONS-01 | Phase 34 | Complete |
| CONS-02 | Phase 34 | Complete |
| CONS-03 | Phase 34 | Complete |
| CONS-04 | Phase 34 | Complete |
| CONS-05 | Phase 35 | Pending |
| CONS-06 | Phase 35 | Pending |
| CONS-07 | Phase 35 | Pending |
| CONS-08 | Phase 36 | Pending |
| CONS-09 | Phase 36 | Pending |
| CONS-10 | Phase 37 | Pending |
| CONS-11 | Phase 38 | Pending |
| CONS-12 | Phase 39 | Pending |
| CONS-13 | Phase 39 | Pending |
| CONS-14 | Phase 40 | Pending |
| CONS-15 | Phase 40 | Pending |
| CONS-16 | Phase 40 | Pending |
| CONS-17 | Phase 40 | Pending |
| CONS-18 | Phase 41 | Pending |
| CONS-19 | Phase 41 | Pending |
| CONS-20 | Phase 42 | Pending |
| CONS-21 | Phase 42 | Pending |
| CONS-22 | Phase 42 | Pending |
| CONS-23 | Phase 43 | Pending |

**Coverage:**
- v1.6 requirements: 23 total
- Mapped to phases: 23
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-19*
*Last updated: 2026-03-19 after roadmap creation (phases 34–43 assigned)*
