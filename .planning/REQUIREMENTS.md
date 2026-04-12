# Requirements: Empowered Vote — v2026.4.3 Indiana Primary Election Readiness Audit

**Defined:** 2026-04-11
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v1 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Data Audit

- [ ] **AUDIT-01**: Audit script reports race coverage — count of DB races vs full Monroe County May 5 ballot
- [ ] **AUDIT-02**: Audit script reports candidate coverage — linked vs unlinked candidates per race
- [ ] **AUDIT-03**: Audit script reports stance data completeness — candidates with/without compass stances
- [ ] **AUDIT-04**: Audit script reports quote coverage — candidates with/without Read & Rank quotes
- [ ] **AUDIT-05**: Audit script reports headshot coverage — CDN photo vs local photo vs no photo per candidate
- [ ] **AUDIT-06**: Audit script reports profile completeness — bio, contacts, education, experience for linked politicians
- [ ] **AUDIT-07**: Full ballot baseline built from Indiana SoS + Monroe County Clerk + local press sources
- [ ] **AUDIT-08**: Geofence resolution test confirms a Bloomington address resolves to expected districts and races

### Competitive Benchmarking

- [ ] **BENCH-01**: Live spot-check completed on BallotReady with a Monroe County address — races shown, candidate data depth documented
- [ ] **BENCH-02**: Live spot-check completed on Vote411 with same address — races, Q&A coverage documented
- [ ] **BENCH-03**: Live spot-check completed on VoteSmart with same address — candidate coverage documented
- [ ] **BENCH-04**: Live spot-check completed on Ballotpedia with same address — race/candidate coverage documented
- [ ] **BENCH-05**: Feature comparison matrix produced — EV vs 4 competitors across ~15 dimensions
- [ ] **BENCH-06**: Coverage depth comparison — per-competitor race count, candidate data fields, stance/quote availability for Monroe County

### UX Gap Analysis

- [ ] **UX-01**: Voter journey documented for Essentials — search Monroe County address, review each screen, log gaps
- [ ] **UX-02**: Voter journey documented for Compass — evaluate experience for a Monroe County voter, stance data availability
- [ ] **UX-03**: Voter journey documented for Read & Rank — quote availability, candidate filtering for Monroe County
- [ ] **UX-04**: Treasury relevance assessment — is budget data useful in election context for Monroe County?

### Gap Report

- [ ] **GAP-01**: Tiered gap report produced with Tier 1 (before primary) vs Tier 2 (future) classification
- [ ] **GAP-02**: Gap report separates data gaps, feature gaps, and intentional omissions (antipartisan)
- [ ] **GAP-03**: Execution backlog produced — prioritized phases for filling Tier 1 gaps in a follow-on milestone

## Future Requirements

Deferred to follow-on milestone (v2026.4.4 or later), pending gap report findings.

### Data Import (Tier 1 — before primary)

- **IMPORT-01**: All missing May 5 Monroe County races imported (county, township, judicial, federal, state)
- **IMPORT-02**: All known candidates imported with minimum data (name, office, race)
- **IMPORT-03**: Compass stances for top contested races (US House D-9, IN House D-61)
- **IMPORT-04**: Sourced quotes for contested federal/state candidates

### UX Fixes (Tier 1 — before primary)

- **UXFIX-01**: Office descriptions ("What does this office do?") for ~20 office types
- **UXFIX-02**: Indiana party primary explainer copy on Election Central
- **UXFIX-03**: Completeness caveat with official ballot link on Election Central

### Infrastructure (Tier 2 — future)

- **INFRA-01**: Township geofence import for Monroe County's 11 townships
- **INFRA-02**: Side-by-side candidate comparison UI (post-data-import)
- **INFRA-03**: Save/print ballot feature

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Party affiliation display | Antipartisan by design — intentional omission |
| Interest group ratings | Embeds partisan framing |
| AI-generated candidate summaries | Hallucination risk for local candidates |
| Endorsement tracking | Heavily partisan signal for local races |
| MCCSC school board races for May 5 | Filing opens May 19 — November races only (Indiana SB 177) |
| Statewide Indiana race coverage | Focus on Monroe County specifically |
| Stance research for township candidates | Insufficient public record; defer to post-primary |
| Budget-to-official linking | High complexity, future milestone |
| Precinct-level ballot personalization | Requires precinct geofences not yet imported |
| Execution of any gap fixes | This milestone is audit-only; execution is follow-on |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUDIT-01 | — | Pending |
| AUDIT-02 | — | Pending |
| AUDIT-03 | — | Pending |
| AUDIT-04 | — | Pending |
| AUDIT-05 | — | Pending |
| AUDIT-06 | — | Pending |
| AUDIT-07 | — | Pending |
| AUDIT-08 | — | Pending |
| BENCH-01 | — | Pending |
| BENCH-02 | — | Pending |
| BENCH-03 | — | Pending |
| BENCH-04 | — | Pending |
| BENCH-05 | — | Pending |
| BENCH-06 | — | Pending |
| UX-01 | — | Pending |
| UX-02 | — | Pending |
| UX-03 | — | Pending |
| UX-04 | — | Pending |
| GAP-01 | — | Pending |
| GAP-02 | — | Pending |
| GAP-03 | — | Pending |

**Coverage:**
- v1 requirements: 21 total
- Mapped to phases: 0
- Unmapped: 21

---
*Requirements defined: 2026-04-11*
*Last updated: 2026-04-11 after initial definition*
